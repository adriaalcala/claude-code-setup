#!/usr/bin/env bash
# session-start.sh - SessionStart hook that seeds the session with project and
# local-stack context.
#
# Event:  SessionStart
# Input:  JSON on stdin; .cwd and .startup_reason
# Output: hookSpecificOutput.additionalContext - text Claude sees before the
#         first turn. SessionStart cannot block, so every failure degrades to
#         a silent exit.

set -euo pipefail

HOOK_NAME="session-start"
# shellcheck source=hooks/scripts/lib/hook-common.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib/hook-common.sh"

hook_init_soft

CWD="$(hook_field '.cwd')"
REASON="$(hook_field '.startup_reason')"
[ -n "$CWD" ] && [ -d "$CWD" ] && cd "$CWD"

lines=()

# --- project -----------------------------------------------------------------
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  ROOT="$(git rev-parse --show-toplevel 2>/dev/null)"
  BRANCH="$(git branch --show-current 2>/dev/null)"
  DIRTY="$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')"
  lines+=("Project: $(basename "$ROOT") (git)")
  lines+=("Branch: ${BRANCH:-detached HEAD}, $DIRTY uncommitted change(s)")
  LAST="$(git log -1 --pretty=format:'%h %s' 2>/dev/null)" || LAST=""
  [ -n "$LAST" ] && lines+=("Last commit: $LAST")
elif [ -f package.json ]; then
  lines+=("Project: $(jq -r '.name // "unnamed"' package.json 2>/dev/null) (node)")
elif [ -f pyproject.toml ] || [ -f setup.py ]; then
  lines+=("Project: $(basename "$PWD") (python)")
elif [ -f go.mod ]; then
  lines+=("Project: $(head -1 go.mod | awk '{print $2}') (go)")
else
  lines+=("Project: $(basename "$PWD") (no manifest detected)")
fi

# --- local AI stack -----------------------------------------------------------
probe() { # probe <label> <url>
  if curl -sf --max-time 1 "$2" >/dev/null 2>&1; then
    printf '%s: up' "$1"
  else
    printf '%s: down' "$1"
  fi
}

SERVICES="$(probe "Ollama" "${OLLAMA_HOST:-http://127.0.0.1:11434}/api/tags"), \
$(probe "Curator" "${CURATOR_URL:-http://127.0.0.1:5555}/health"), \
$(probe "ChromaDB" "${CHROMADB_URL:-http://127.0.0.1:8000}/api/v1/heartbeat")"
lines+=("Local stack: $SERVICES")

[ -n "$REASON" ] && lines+=("Session start reason: $REASON")

CONTEXT="$(printf '%s\n' "${lines[@]}")"
hook_log "CONTEXT" "$(printf '%s' "$CONTEXT" | tr '\n' '; ')"
hook_context "SessionStart" "$CONTEXT"
