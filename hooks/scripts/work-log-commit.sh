#!/usr/bin/env bash
# work-log-commit.sh - PostToolUse hook that records successful git commits.
#
# Event:  PostToolUse, matcher "Bash"
# Input:  JSON on stdin; .tool_input.command and .cwd
# Output: nothing. The entry lands in ~/.claude/work-log/<date>.json.

set -euo pipefail

HOOK_NAME="work-log-commit"
# shellcheck source=hooks/scripts/lib/hook-common.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib/hook-common.sh"

hook_init_soft

[ "$(hook_field '.tool_name')" = "Bash" ] || exit 0

COMMAND="$(hook_field '.tool_input.command')"
[[ "$COMMAND" =~ git[[:space:]]+(-[^[:space:]]+[[:space:]]+)*commit([[:space:]]|$) ]] || exit 0

CWD="$(hook_field '.cwd')"
[ -n "$CWD" ] && [ -d "$CWD" ] && cd "$CWD"

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0

COMMIT_HASH="$(git log -1 --pretty=format:'%h' 2>/dev/null)" || exit 0
COMMIT_MSG="$(git log -1 --pretty=format:'%s' 2>/dev/null)" || exit 0
PROJECT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || exit 0
PROJECT_NAME="$(basename "$PROJECT_ROOT")"
BRANCH="$(git branch --show-current 2>/dev/null)" || BRANCH=""

FILES_CHANGED="$(git diff-tree --no-commit-id --name-only -r HEAD 2>/dev/null \
  | jq -R -s 'split("\n") | map(select(length > 0))')" || FILES_CHANGED="[]"

case "$COMMIT_MSG" in
  feat*) TAGS='["feature"]' ;;
  fix*) TAGS='["bugfix"]' ;;
  docs*) TAGS='["documentation"]' ;;
  refactor*) TAGS='["refactor"]' ;;
  test*) TAGS='["testing"]' ;;
  chore*) TAGS='["chore"]' ;;
  *) TAGS='[]' ;;
esac

LOG_DIR="${WORK_LOG_DIR:-$HOME/.claude/work-log}"
mkdir -p "$LOG_DIR" 2>/dev/null || exit 0
LOG_FILE="$LOG_DIR/$(date +%Y-%m-%d).json"

[ -f "$LOG_FILE" ] || printf '{"entries":[]}\n' >"$LOG_FILE"
EXISTING="$(jq -e . "$LOG_FILE" 2>/dev/null)" || EXISTING='{"entries":[]}'

ENTRY="$(jq -n \
  --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  --arg proj "$PROJECT_ROOT" \
  --arg projName "$PROJECT_NAME" \
  --arg branch "$BRANCH" \
  --arg hash "$COMMIT_HASH" \
  --arg msg "$COMMIT_MSG" \
  --argjson files "$FILES_CHANGED" \
  --argjson tags "$TAGS" \
  '{timestamp:$ts, type:"commit", project:$proj, project_name:$projName,
    branch:$branch, description:$msg, files:$files,
    commit:{hash:$hash, message:$msg}, tags:$tags}')"

printf '%s' "$EXISTING" | jq --argjson entry "$ENTRY" '.entries += [$entry]' >"$LOG_FILE.tmp" \
  && mv "$LOG_FILE.tmp" "$LOG_FILE"

hook_log "LOGGED" "$COMMIT_HASH $COMMIT_MSG"
exit 0
