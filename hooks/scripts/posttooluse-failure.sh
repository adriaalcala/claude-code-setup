#!/bin/bash
# posttooluse-failure.sh - Log tool failures with rotation
# Captures error context for debugging and analysis

set -euo pipefail

LOG_DIR="${LOG_DIR:-./.claude/logs}"
mkdir -p "$LOG_DIR"

TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)
FAILURE_LOG="$LOG_DIR/failures.log"
FAILURE_JSON="$LOG_DIR/failures.jsonl"

# Max log size: 50MB
MAX_LOG_SIZE=$((50 * 1024 * 1024))

# Input from Claude Code
TOOL_NAME="${1:-unknown}"
TOOL_INPUT="${2:-}"
ERROR_MESSAGE="${3:-}"
ERROR_CODE="${4:-1}"
DURATION_MS="${5:-0}"

# Output result as JSON
output_result() {
  local logged="$1"

  cat <<EOF
{
  "logged": $logged,
  "timestamp": "$TIMESTAMP",
  "log_file": "$FAILURE_JSON",
  "tool": "$TOOL_NAME"
}
EOF
}

# Rotate logs if too large
rotate_logs() {
  local log_file="$1"

  if [ -f "$log_file" ]; then
    local size=$(stat -f%z "$log_file" 2>/dev/null || stat -c%s "$log_file" 2>/dev/null || echo "0")

    if [ "$size" -gt "$MAX_LOG_SIZE" ]; then
      local backup="${log_file}.$(date +%Y%m%d-%H%M%S)"
      mv "$log_file" "$backup"
      gzip "$backup" 2>/dev/null || true
      echo "$TIMESTAMP Rotated log file (size: $size bytes)" >> "$FAILURE_LOG"
    fi
  fi
}

# Sanitize input (remove secrets)
sanitize_input() {
  local input="$1"

  # Remove common secrets
  input=$(echo "$input" | sed 's/api[_-]?key[=:]\s*[^\s]*/api_key=[REDACTED]/gi')
  input=$(echo "$input" | sed 's/password[=:]\s*[^\s]*/password=[REDACTED]/gi')
  input=$(echo "$input" | sed 's/token[=:]\s*[^\s]*/token=[REDACTED]/gi')
  input=$(echo "$input" | sed 's/secret[=:]\s*[^\s]*/secret=[REDACTED]/gi')
  input=$(echo "$input" | sed 's/authorization[=:]\s*Bearer\s*[^\s]*/authorization=[REDACTED]/gi')
  input=$(echo "$input" | sed 's/aws_access_key[=:]\s*[^\s]*/aws_access_key=[REDACTED]/gi')
  input=$(echo "$input" | sed 's/aws_secret_key[=:]\s*[^\s]*/aws_secret_key=[REDACTED]/gi')

  echo "$input"
}

# Sanitize error message
sanitize_error() {
  local error="$1"

  # Remove file paths that might contain sensitive info
  error=$(echo "$error" | sed 's|/home/[^/]*/|/home/[USER]/|g')
  error=$(echo "$error" | sed 's|/Users/[^/]*/|/Users/[USER]/|g')

  # Remove IP addresses
  error=$(echo "$error" | sed 's/[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}/[IP]/g')

  # Remove emails
  error=$(echo "$error" | sed 's/[a-zA-Z0-9._%+-]*@[a-zA-Z0-9.-]*/[EMAIL]/g')

  echo "$error"
}

# Classify failure type
classify_failure() {
  local tool="$1"
  local error="$2"

  if [[ "$error" =~ "timeout" ]]; then
    echo "timeout"
  elif [[ "$error" =~ "connection refused" ]] || [[ "$error" =~ "cannot connect" ]]; then
    echo "connection_error"
  elif [[ "$error" =~ "permission denied" ]] || [[ "$error" =~ "access denied" ]]; then
    echo "permission_error"
  elif [[ "$error" =~ "not found" ]] || [[ "$error" =~ "no such" ]]; then
    echo "not_found"
  elif [[ "$error" =~ "invalid\|bad\|malformed" ]]; then
    echo "invalid_input"
  elif [[ "$error" =~ "out of memory\|oom" ]]; then
    echo "out_of_memory"
  elif [[ "$error" =~ "disk space\|no space" ]]; then
    echo "disk_full"
  elif [[ "$tool" =~ "Bash" ]]; then
    echo "bash_execution"
  elif [[ "$tool" =~ "Read|Write" ]]; then
    echo "file_operation"
  elif [[ "$tool" =~ "Grep|Search" ]]; then
    echo "search_operation"
  else
    echo "unknown"
  fi
}

# Get system state for debugging
get_system_state() {
  local state="{}"

  # Get memory usage
  if command -v free &> /dev/null; then
    local mem=$(free -h 2>/dev/null | awk '/^Mem:/ {print $3 "/" $2}')
    state=$(echo "$state" | jq --arg mem "$mem" '.memory = $mem')
  fi

  # Get disk usage
  if command -v df &> /dev/null; then
    local disk=$(df -h / 2>/dev/null | awk 'NR==2 {print $3 "/" $2}')
    state=$(echo "$state" | jq --arg disk "$disk" '.disk = $disk')
  fi

  # Get CPU load
  if [ -f /proc/loadavg ]; then
    local load=$(cat /proc/loadavg | awk '{print $1}')
    state=$(echo "$state" | jq --arg load "$load" '.load = $load')
  fi

  echo "$state"
}

# Main logging
main() {
  # Rotate logs if needed
  rotate_logs "$FAILURE_LOG"
  rotate_logs "$FAILURE_JSON"

  # Sanitize sensitive data
  CLEAN_INPUT=$(sanitize_input "$TOOL_INPUT")
  CLEAN_ERROR=$(sanitize_error "$ERROR_MESSAGE")

  # Classify failure
  FAILURE_TYPE=$(classify_failure "$TOOL_NAME" "$CLEAN_ERROR")

  # Get system state
  SYSTEM_STATE=$(get_system_state)

  # Create JSON log entry
  JSON_ENTRY=$(cat <<EOF
{
  "timestamp": "$TIMESTAMP",
  "tool": "$TOOL_NAME",
  "type": "$FAILURE_TYPE",
  "error_code": $ERROR_CODE,
  "duration_ms": $DURATION_MS,
  "message": "$(echo "$CLEAN_ERROR" | head -c 500 | jq -Rs .)",
  "input_preview": "$(echo "$CLEAN_INPUT" | head -c 200 | jq -Rs .)",
  "system": $SYSTEM_STATE
}
EOF
)

  # Append to JSONL file
  echo "$JSON_ENTRY" >> "$FAILURE_JSON"

  # Also append to text log
  cat >> "$FAILURE_LOG" << EOF
[$TIMESTAMP] FAILURE: $TOOL_NAME ($FAILURE_TYPE)
  Error Code: $ERROR_CODE
  Duration: ${DURATION_MS}ms
  Message: $CLEAN_ERROR
  Input: $CLEAN_INPUT
---
EOF

  output_result "true"
}

main
