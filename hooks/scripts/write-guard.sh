#!/usr/bin/env bash
# write-guard.sh - PreToolUse hook that blocks writes to protected paths and
# writes whose content looks like a real credential.
#
# Event:  PreToolUse, matcher "Write|Edit|MultiEdit|NotebookEdit"
# Input:  JSON on stdin; .tool_input.file_path plus .tool_input.content,
#         .tool_input.new_string or .tool_input.edits[].new_string
# Output: a PreToolUse permissionDecision, or nothing at all
#
# The credential patterns deliberately require a literal-looking value. Matching
# the bare word "password" would block this very file, every .env.example and
# most security documentation.

set -euo pipefail

HOOK_NAME="write-guard"
# shellcheck source=hooks/scripts/lib/hook-common.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib/hook-common.sh"

hook_init

TOOL_NAME="$(hook_field '.tool_name')"

case "$TOOL_NAME" in
  Write | Edit | MultiEdit | NotebookEdit) ;;
  *) hook_pass ;;
esac

FILE_PATH="$(hook_field '.tool_input.file_path')"
if [ -z "$FILE_PATH" ]; then
  hook_deny "write-guard: the $TOOL_NAME event carried no file_path, so it could not be inspected. Blocking (fail-closed)."
fi

# Content lives under a different key per tool. Collect whatever is there.
CONTENT="$(printf '%s' "$HOOK_INPUT" | jq -r '
  [ .tool_input.content?,
    .tool_input.new_string?,
    .tool_input.new_source?,
    (.tool_input.edits? // [] | .[]?.new_string?)
  ] | map(select(. != null)) | join("\n")
' 2>/dev/null)" || CONTENT=""

# --- protected paths ----------------------------------------------------------
PROTECTED_PATTERNS=(
  '^/etc/'
  '^/(usr|bin|sbin|boot|sys|proc|dev)/'
  '^/System/'
  '^/Library/LaunchDaemons/'
  '(^|/)\.ssh/'
  '(^|/)\.gnupg/'
  '(^|/)\.aws/(credentials|config)$'
  '(^|/)\.docker/config\.json$'
  '(^|/)\.netrc$'
  '(^|/)\.npmrc$'
  '(^|/)\.pypirc$'
  '(^|/)\.git/config$'
  '(^|/)\.env(\.[[:alnum:]]+)?$'
  '\.(pem|key|p12|pfx|jks|keystore)$'
  '(^|/)id_(rsa|dsa|ecdsa|ed25519)$'
)

# .env.example and friends are templates, not secrets.
if ! [[ "$FILE_PATH" =~ \.(example|sample|template|dist)$ ]]; then
  if hook_matches_any "$FILE_PATH" "${PROTECTED_PATTERNS[@]}"; then
    hook_deny "write-guard: '$FILE_PATH' is a protected path (matched /${HOOK_MATCHED_PATTERN}/). Edit it yourself if you really mean to."
  fi
fi

# --- binary artefacts ---------------------------------------------------------
if [[ "$FILE_PATH" =~ \.(exe|dll|so|dylib|o|a|bin|iso|dmg|elf|pyc|class)$ ]]; then
  hook_deny "write-guard: refusing to write the binary artefact '$FILE_PATH'. Build it from source instead."
fi

# --- credential-shaped content ------------------------------------------------
# Skip when there is nothing to inspect (an Edit that only deletes, say).
if [ -n "$CONTENT" ]; then
  # High-confidence literal tokens: these shapes are never placeholders.
  TOKEN_PATTERNS=(
    'AKIA[0-9A-Z]{16}'
    'gh[pousr]_[A-Za-z0-9]{36,}'
    'github_pat_[A-Za-z0-9_]{60,}'
    'sk-ant-[A-Za-z0-9_-]{20,}'
    'sk-[A-Za-z0-9]{32,}'
    'xox[baprs]-[A-Za-z0-9-]{10,}'
    'AIza[0-9A-Za-z_-]{35}'
    '-----BEGIN[[:space:]]+([A-Z]+[[:space:]]+)?PRIVATE[[:space:]]+KEY-----'
    'eyJ[A-Za-z0-9_-]{10,}\.eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}'
  )
  if hook_matches_any "$CONTENT" "${TOKEN_PATTERNS[@]}"; then
    hook_deny "write-guard: the content of '$FILE_PATH' contains what looks like a live credential (matched /${HOOK_MATCHED_PATTERN}/). Move it to an environment variable."
  fi

  # Assignments with a literal value. Placeholders and indirection are excluded
  # below so that examples and real code keep working.
  #
  # Matched against a lowercased copy: bash regexes are case-sensitive, and the
  # real-world spelling is DB_PASSWORD or API_KEY far more often than not.
  CONTENT_LC="$(printf '%s' "$CONTENT" | tr '[:upper:]' '[:lower:]')"
  ASSIGN_RE='(password|passwd|secret|api[_-]?key|apikey|access[_-]?token|auth[_-]?token|client[_-]?secret)[[:alnum:]_]*[[:space:]]*[:=][[:space:]]*.?["'"'"']([^"'"'"']{8,})["'"'"']'
  if [[ "$CONTENT_LC" =~ $ASSIGN_RE ]]; then
    VALUE="${BASH_REMATCH[2]}"
    PLACEHOLDER_RE='(^\$|^\{\{|\$\{|os\.getenv|process\.env|getenv|^your[-_]|^my[-_]|^test|^dummy|^sample|^example|^changeme|^xxx|^\.\.\.|^<|^placeholder|^redacted|^\*+$)'
    if ! [[ "$VALUE" =~ $PLACEHOLDER_RE ]]; then
      hook_deny "write-guard: '$FILE_PATH' assigns a literal credential value. Read it from the environment instead of hardcoding it."
    fi
  fi
fi

hook_pass
