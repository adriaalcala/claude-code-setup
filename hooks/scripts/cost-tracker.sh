#!/usr/bin/env bash
# cost-tracker.sh - PostToolUse hook that appends tool usage to a CSV.
#
# Event:  PostToolUse (any matcher)
# Input:  JSON on stdin; .tool_name, .tool_input, .tool_output, .session_id
# Output: nothing. Rows land in the CSV for later analysis.
#
# Run `cost-tracker.sh summary` by hand to read the CSV back.

set -euo pipefail

HOOK_NAME="cost-tracker"
# shellcheck source=hooks/scripts/lib/hook-common.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib/hook-common.sh"

CSV_FILE="${COST_TRACKER_CSV:-$(hook_log_dir)/cost-tracker.csv}"

if [ "${1:-}" = "summary" ]; then
  [ -f "$CSV_FILE" ] || { echo "No data at $CSV_FILE"; exit 0; }
  echo "=== Tool usage ==="
  awk -F',' 'NR>1 {print $3}' "$CSV_FILE" | sort | uniq -c | sort -rn
  echo
  echo "=== Estimated tokens ==="
  awk -F',' 'NR>1 {sum += $4} END {printf "%.0f\n", sum}' "$CSV_FILE"
  exit 0
fi

hook_init_soft

TOOL_NAME="$(hook_field '.tool_name')"
SESSION_ID="$(hook_field '.session_id')"
[ -n "$TOOL_NAME" ] || exit 0
[ -n "$SESSION_ID" ] || SESSION_ID="unknown"

# Characters in and out, as a stand-in for tokens. Roughly 4 chars per token.
IN_CHARS="$(printf '%s' "$HOOK_INPUT" | jq -r '.tool_input | tostring | length' 2>/dev/null)" || IN_CHARS=0
OUT_CHARS="$(printf '%s' "$HOOK_INPUT" | jq -r '.tool_output // "" | tostring | length' 2>/dev/null)" || OUT_CHARS=0
TOTAL_CHARS=$((IN_CHARS + OUT_CHARS))
EST_TOKENS=$((TOTAL_CHARS / 4))

mkdir -p "$(dirname "$CSV_FILE")" 2>/dev/null || exit 0
if [ ! -f "$CSV_FILE" ]; then
  echo "timestamp,session_id,tool_name,estimated_tokens,input_chars,output_chars" >"$CSV_FILE"
fi

printf '%s,%s,%s,%s,%s,%s\n' \
  "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$SESSION_ID" "$TOOL_NAME" \
  "$EST_TOKENS" "$IN_CHARS" "$OUT_CHARS" >>"$CSV_FILE" 2>/dev/null || true

exit 0
