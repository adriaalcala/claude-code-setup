#!/usr/bin/env bash
# stop.sh - Stop hook that writes a session summary to disk.
#
# Event:  Stop
# Input:  JSON on stdin; .cwd, .session_id, .last_assistant_message
# Output: nothing. Stop treats plain stdout as text, not as context, so the
#         summary is written to the log directory instead of printed.
#
# Note on exit codes: on Stop, exit 2 prevents Claude from stopping and keeps
# the conversation going. That is never what a summary hook wants, so this
# script always exits 0.

set -euo pipefail

HOOK_NAME="stop"
# shellcheck source=hooks/scripts/lib/hook-common.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib/hook-common.sh"

hook_init_soft

CWD="$(hook_field '.cwd')"
SESSION_ID="$(hook_field '.session_id')"
[ -n "$CWD" ] && [ -d "$CWD" ] && cd "$CWD"

SUMMARY_FILE="$(hook_log_dir)/summary.log"
mkdir -p "$(dirname "$SUMMARY_FILE")" 2>/dev/null || exit 0

{
  printf '=== %s session %s ===\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "${SESSION_ID:-unknown}"
  printf 'cwd: %s\n' "$PWD"

  if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    printf 'branch: %s\n' "$(git branch --show-current 2>/dev/null || echo 'detached')"
    CHANGES="$(git status --porcelain 2>/dev/null)"
    if [ -n "$CHANGES" ]; then
      printf 'uncommitted:\n%s\n' "$CHANGES"
    else
      printf 'uncommitted: none\n'
    fi
    printf 'commits today: %s\n' \
      "$(git log --since=midnight --oneline 2>/dev/null | wc -l | tr -d ' ')"
  fi

  if curl -sf --max-time 1 "${OLLAMA_HOST:-http://127.0.0.1:11434}/api/tags" >/dev/null 2>&1; then
    printf 'ollama: up\n'
  else
    printf 'ollama: down\n'
  fi
  printf '\n'
} >>"$SUMMARY_FILE" 2>/dev/null || true

hook_log "SUMMARY" "written to $SUMMARY_FILE"
exit 0
