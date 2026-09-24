#!/usr/bin/env bash
# posttooluse-failure.sh - PostToolUseFailure hook that records tool failures.
#
# Event:  PostToolUseFailure
# Input:  JSON on stdin. The error field is read defensively across a few
#         plausible keys, because the payload for this event is less pinned
#         down than PreToolUse/PostToolUse.
# Output: nothing. Exit 2 is not honoured on this event, so it always exits 0.
#
# Home directories and credential-shaped strings are redacted before anything
# reaches disk: a failure log is exactly the kind of file that leaks by accident.

set -euo pipefail

HOOK_NAME="posttooluse-failure"
# shellcheck source=hooks/scripts/lib/hook-common.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib/hook-common.sh"

hook_init_soft

TOOL_NAME="$(hook_field '.tool_name')"
[ -n "$TOOL_NAME" ] || TOOL_NAME="unknown"

ERROR="$(printf '%s' "$HOOK_INPUT" | jq -r '
  [ .tool_error?, .error?, .tool_output?, .result? ]
  | map(select(. != null)) | map(tostring) | first // ""
' 2>/dev/null)" || ERROR=""

redact() {
  sed -E \
    -e 's|/Users/[^/ ]+|/Users/[USER]|g' \
    -e 's|/home/[^/ ]+|/home/[USER]|g' \
    -e 's/(api[_-]?key|token|secret|password)([[:space:]]*[=:][[:space:]]*)[^[:space:]"'"'"']+/\1\2[REDACTED]/gI' \
    -e 's/(AKIA[0-9A-Z]{16})/[REDACTED-AWS-KEY]/g' \
    -e 's/(gh[pousr]_[A-Za-z0-9]{20,})/[REDACTED-GH-TOKEN]/g' \
    -e 's/(sk-[A-Za-z0-9-]{20,})/[REDACTED-API-KEY]/g'
}

CLEAN_ERROR="$(printf '%s' "$ERROR" | head -c 2000 | redact)"

LOG_DIR="$(hook_log_dir)"
mkdir -p "$LOG_DIR" 2>/dev/null || exit 0
FAILURE_JSON="$LOG_DIR/failures.jsonl"

# Rotate at 10 MB so the log cannot grow without bound.
if [ -f "$FAILURE_JSON" ]; then
  SIZE="$(stat -f%z "$FAILURE_JSON" 2>/dev/null || stat -c%s "$FAILURE_JSON" 2>/dev/null || echo 0)"
  if [ "$SIZE" -gt $((10 * 1024 * 1024)) ]; then
    mv "$FAILURE_JSON" "$FAILURE_JSON.1" 2>/dev/null || true
  fi
fi

jq -n -c \
  --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  --arg tool "$TOOL_NAME" \
  --arg session "$(hook_field '.session_id')" \
  --arg err "$CLEAN_ERROR" \
  '{timestamp:$ts, tool:$tool, session_id:$session, error:$err}' \
  >>"$FAILURE_JSON" 2>/dev/null || true

hook_log "FAILURE" "$TOOL_NAME"
exit 0
