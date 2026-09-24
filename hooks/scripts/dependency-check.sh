#!/usr/bin/env bash
# dependency-check.sh - PreToolUse hook that surfaces risky dependency installs.
#
# Event:  PreToolUse, matcher "Bash"
# Input:  JSON on stdin; .tool_input.command and .cwd
# Output: a PreToolUse permissionDecision, or nothing at all
#
# This hook runs inside the tool-call latency budget, so it does no network I/O
# by default: it pattern-matches the install command for the supply-chain
# vectors that actually matter and asks the user to confirm those.
#
# Set DEPENDENCY_CHECK_AUDIT=1 to additionally run `npm audit` / `pip-audit`
# before an install. That is a network call taking seconds, so raise the hook's
# timeout in settings.json to at least 30 if you turn it on.

set -euo pipefail

HOOK_NAME="dependency-check"
# shellcheck source=hooks/scripts/lib/hook-common.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib/hook-common.sh"

hook_init

TOOL_NAME="$(hook_field '.tool_name')"
[ "$TOOL_NAME" = "Bash" ] || hook_pass

COMMAND="$(hook_field '.tool_input.command')"
[ -n "$COMMAND" ] || hook_pass

INSTALL_RE='(^|[;&|][[:space:]]*)[[:space:]]*(npm[[:space:]]+(install|i|add)|yarn[[:space:]]+add|pnpm[[:space:]]+(add|install)|pip3?[[:space:]]+install|uv[[:space:]]+(add|pip[[:space:]]+install)|cargo[[:space:]]+(add|install)|gem[[:space:]]+install|go[[:space:]]+install)([[:space:]]|$)'
if ! [[ "$COMMAND" =~ $INSTALL_RE ]]; then
  hook_pass
fi

# --- supply-chain vectors worth a confirmation -------------------------------
RISKY_PATTERNS=(
  # Installing straight from a URL or VCS ref bypasses the registry entirely.
  '(install|add)[[:space:]]+[^[:space:]]*(https?://|git\+|git@|ssh://)'
  '(install|add)[[:space:]]+[^[:space:]]*\.(tar\.gz|tgz|zip|whl)([[:space:]]|$)'
  # Redirecting the registry is how a typosquat gets served as the real thing.
  '--(index-url|extra-index-url|registry|repo)[[:space:]=]'
  '--trusted-host[[:space:]=]'
  # Global installs escape the project sandbox.
  'npm[[:space:]]+(install|i)[[:space:]]+.*(-g|--global)'
  'pip3?[[:space:]]+install[[:space:]]+.*--user'
  # Pre-release and unpinned-from-anywhere installs.
  '--pre([[:space:]]|$)'
  'npm[[:space:]]+install[[:space:]]+.*@(next|canary|beta|latest)([[:space:]]|$)'
  # Local paths can point outside the repository.
  '(install|add)[[:space:]]+(file:|link:|portal:)'
)

if hook_matches_any "$COMMAND" "${RISKY_PATTERNS[@]}"; then
  hook_ask "dependency-check: this install bypasses the normal registry path (matched /${HOOK_MATCHED_PATTERN}/). Confirm the source is the one you expect."
fi

# --- optional audit ----------------------------------------------------------
if [ "${DEPENDENCY_CHECK_AUDIT:-0}" = "1" ]; then
  CWD="$(hook_field '.cwd')"
  [ -n "$CWD" ] && [ -d "$CWD" ] && cd "$CWD"

  FINDINGS=""
  if [[ "$COMMAND" =~ (npm|yarn|pnpm) ]] && [ -f package.json ] && command -v npm >/dev/null 2>&1; then
    COUNT="$(npm audit --json 2>/dev/null \
      | jq -r '[.metadata.vulnerabilities.high // 0, .metadata.vulnerabilities.critical // 0] | add' 2>/dev/null)" || COUNT=""
    [ -n "$COUNT" ] && [ "$COUNT" != "0" ] && FINDINGS="npm audit reports $COUNT high or critical advisories in the current tree"
  elif [[ "$COMMAND" =~ (pip|uv) ]] && command -v pip-audit >/dev/null 2>&1; then
    if ! pip-audit --strict --progress-spinner off >/dev/null 2>&1; then
      FINDINGS="pip-audit reports known advisories in the current environment"
    fi
  fi

  if [ -n "$FINDINGS" ]; then
    hook_ask "dependency-check: $FINDINGS. Installing more packages on top is probably not what you want yet."
  fi
fi

hook_pass "install command carries no known risk marker"
