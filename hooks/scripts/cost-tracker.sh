#!/bin/bash
set -euo pipefail

# Post-tool-use hook: Track estimated token usage for API costs
# Purpose: Log tool usage and estimate cloud API costs
# Usage: cost-tracker.sh [summary]
# Output: JSON with tracking info

LOG_DIR="${LOG_DIR:-.}"
CSV_FILE="${LOG_DIR}/cost-tracker.csv"
SESSION_ID="${SESSION_ID:-$(uuidgen 2>/dev/null || echo "unknown")}"

# Initialize CSV if doesn't exist
if [[ ! -f "$CSV_FILE" ]]; then
    echo "timestamp,session_id,tool_name,estimated_tokens,cost_usd,input_length_chars" > "$CSV_FILE"
fi

# Function: estimate tokens from input length (rough approximation)
estimate_tokens() {
    local char_count=$1
    # Rough estimate: 1 token ~= 4 chars on average
    echo $((char_count / 4))
}

# Function: estimate cost
estimate_cost() {
    local tokens=$1
    # GPT-4 pricing: ~$0.03 per 1000 tokens (input)
    # Rough estimate: 0.00003 USD per token
    echo "scale=6; $tokens * 0.00003" | bc
}

# Check if summary mode
if [[ "${1:-}" == "summary" ]]; then
    echo "=== Cost Tracking Summary ==="
    
    # Count by tool
    echo "Tools used:"
    awk -F',' 'NR > 1 {print $3}' "$CSV_FILE" | sort | uniq -c | sort -rn
    
    # Total tokens
    echo ""
    echo "Total tokens:"
    awk -F',' 'NR > 1 {sum += $4} END {printf "%.0f\n", sum}' "$CSV_FILE"
    
    # Total estimated cost
    echo ""
    echo "Total estimated cost (USD):"
    awk -F',' 'NR > 1 {sum += $5} END {printf "$%.2f\n", sum}' "$CSV_FILE"
    
    # By tool cost
    echo ""
    echo "Cost by tool:"
    awk -F',' 'NR > 1 {tools[$3] += $5} END {for (tool in tools) printf "%s: $%.2f\n", tool, tools[tool]}' "$CSV_FILE" | sort -t'$' -k2 -rn
    
    # Output JSON summary
    TOTAL_TOKENS=$(awk -F',' 'NR > 1 {sum += $4} END {printf "%.0f\n", sum}' "$CSV_FILE")
    TOTAL_COST=$(awk -F',' 'NR > 1 {sum += $5} END {printf "%.6f\n", sum}' "$CSV_FILE")
    
    cat <<EOF
{
  "mode": "summary",
  "session_id": "$SESSION_ID",
  "total_tokens": $TOTAL_TOKENS,
  "total_cost_usd": $TOTAL_COST,
  "unique_tools": $(awk -F',' 'NR > 1 {print $3}' "$CSV_FILE" | sort -u | wc -l)
}
EOF
    exit 0
fi

# Normal logging mode: parse from stdin or environment
TOOL_NAME="${TOOL_NAME:-unknown}"
INPUT_LENGTH="${INPUT_LENGTH:-0}"

ESTIMATED_TOKENS=$(estimate_tokens "$INPUT_LENGTH")
ESTIMATED_COST=$(estimate_cost "$ESTIMATED_TOKENS")

# Append to CSV
{
    echo "$(date -u +'%Y-%m-%dT%H:%M:%SZ'),$SESSION_ID,$TOOL_NAME,$ESTIMATED_TOKENS,$ESTIMATED_COST,$INPUT_LENGTH"
} >> "$CSV_FILE" 2>/dev/null || true

# Output JSON
cat <<EOF
{
  "mode": "track",
  "timestamp": "$(date -u +'%Y-%m-%dT%H:%M:%SZ')",
  "session_id": "$SESSION_ID",
  "tool_name": "$TOOL_NAME",
  "input_chars": $INPUT_LENGTH,
  "estimated_tokens": $ESTIMATED_TOKENS,
  "estimated_cost_usd": $ESTIMATED_COST,
  "log_file": "$CSV_FILE"
}
EOF

exit 0
