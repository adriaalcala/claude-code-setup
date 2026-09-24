#!/usr/bin/env bash
# write-format.sh - PostToolUse hook that formats a file right after it is written.
#
# Event:  PostToolUse, matcher "Write|Edit|MultiEdit"
# Input:  JSON on stdin; .tool_input.file_path
# Output: nothing on success. PostToolUse cannot block, so failures are logged
#         and reported as additionalContext rather than as an error exit.

set -euo pipefail

HOOK_NAME="write-format"
# shellcheck source=hooks/scripts/lib/hook-common.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib/hook-common.sh"

hook_init_soft

FILE_PATH="$(hook_field '.tool_input.file_path')"
[ -n "$FILE_PATH" ] && [ -f "$FILE_PATH" ] || exit 0

have() { command -v "$1" >/dev/null 2>&1; }

EXT="${FILE_PATH##*.}"
# Extension-less scripts are identified by their shebang.
if [ "$EXT" = "$FILE_PATH" ] && head -1 "$FILE_PATH" 2>/dev/null | grep -q '^#!.*\(ba\)\?sh'; then
  EXT="sh"
fi

FORMATTER=""
case "$EXT" in
  py)
    if have ruff; then
      ruff format "$FILE_PATH" >/dev/null 2>&1 && FORMATTER="ruff"
      ruff check --fix-only "$FILE_PATH" >/dev/null 2>&1 || true
    elif have black; then
      black --quiet "$FILE_PATH" >/dev/null 2>&1 && FORMATTER="black"
    fi
    ;;
  js | jsx | ts | tsx | mjs | cjs | json | css | scss | html | md | yml | yaml)
    if have prettier; then
      prettier --write "$FILE_PATH" >/dev/null 2>&1 && FORMATTER="prettier"
    elif have npx; then
      npx --no-install prettier --write "$FILE_PATH" >/dev/null 2>&1 && FORMATTER="prettier"
    fi
    ;;
  rs) have rustfmt && rustfmt "$FILE_PATH" >/dev/null 2>&1 && FORMATTER="rustfmt" ;;
  go) have gofmt && gofmt -w "$FILE_PATH" >/dev/null 2>&1 && FORMATTER="gofmt" ;;
  sh | bash) have shfmt && shfmt -w "$FILE_PATH" >/dev/null 2>&1 && FORMATTER="shfmt" ;;
  *) ;;
esac

if [ -n "$FORMATTER" ]; then
  hook_log "FORMAT" "$FILE_PATH ($FORMATTER)"
else
  hook_log "SKIP" "$FILE_PATH (no formatter for .$EXT)"
fi

exit 0
