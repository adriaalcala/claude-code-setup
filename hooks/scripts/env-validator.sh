#!/usr/bin/env bash
# env-validator.sh - SessionStart hook that checks the local toolchain.
#
# Event:  SessionStart
# Input:  JSON on stdin
# Output: hookSpecificOutput.additionalContext listing anything missing, so
#         Claude knows up front which tools it cannot rely on. Silent when the
#         environment is complete.

set -euo pipefail

HOOK_NAME="env-validator"
# shellcheck source=hooks/scripts/lib/hook-common.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib/hook-common.sh"

hook_init_soft

problems=()

# --- required binaries --------------------------------------------------------
for bin in jq git curl; do
  command -v "$bin" >/dev/null 2>&1 || problems+=("missing required tool: $bin")
done

# --- Ollama and its models ----------------------------------------------------
OLLAMA_URL="${OLLAMA_HOST:-http://127.0.0.1:11434}"
if curl -sf --max-time 2 "$OLLAMA_URL/api/tags" >/dev/null 2>&1; then
  TAGS="$(curl -sf --max-time 2 "$OLLAMA_URL/api/tags" 2>/dev/null)" || TAGS=""
  for model in ${REQUIRED_OLLAMA_MODELS:-qwen3-coder nomic-embed-text}; do
    if ! printf '%s' "$TAGS" | jq -e --arg m "$model" \
      '.models[]?.name | select(startswith($m))' >/dev/null 2>&1; then
      problems+=("Ollama model not pulled: $model (run: ollama pull $model)")
    fi
  done
else
  problems+=("Ollama is not reachable at $OLLAMA_URL - local verification will fall back to cloud APIs")
fi

# --- optional toolchain -------------------------------------------------------
for bin in uv ruff pytest; do
  command -v "$bin" >/dev/null 2>&1 || problems+=("optional tool not on PATH: $bin")
done

if [ "${#problems[@]}" -eq 0 ]; then
  hook_log "OK" "environment complete"
  exit 0
fi

hook_log "WARN" "${#problems[@]} issue(s)"
hook_context "SessionStart" "Environment check found ${#problems[@]} issue(s):
$(printf -- '- %s\n' "${problems[@]}")"
