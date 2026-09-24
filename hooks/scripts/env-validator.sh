#!/bin/bash
set -euo pipefail

# SessionStart hook: Validate local environment at startup
# Purpose: Check Ollama, required models, and dependencies
# Output: JSON with validation results and warnings

LOG_DIR="${LOG_DIR:-.}"
LOG_FILE="${LOG_DIR}/env-validation.log"

# Initialize results
VALID=true
WARNINGS=()
ERRORS=()

# Log startup
{
    echo "=== Environment Validation Started ==="
    echo "Time: $(date -u +'%Y-%m-%dT%H:%M:%SZ')"
    echo ""
} >> "$LOG_FILE" 2>/dev/null || true

# 1. Check OLLAMA_HOST is set
if [[ -z "${OLLAMA_HOST:-}" ]]; then
    OLLAMA_HOST="http://localhost:11434"
    WARNINGS+=("OLLAMA_HOST not set, using default: $OLLAMA_HOST")
else
    echo "OLLAMA_HOST detected: $OLLAMA_HOST" >> "$LOG_FILE" 2>/dev/null || true
fi

# 2. Check if Ollama is running
if curl -s "$OLLAMA_HOST/api/tags" > /dev/null 2>&1; then
    echo "Ollama service: RUNNING" >> "$LOG_FILE" 2>/dev/null || true
else
    WARNINGS+=("Ollama service not responding at $OLLAMA_HOST")
    VALID=false
fi

# 3. Check for qwen3-coder model
if curl -s "$OLLAMA_HOST/api/tags" | grep -q "qwen3-coder" 2>/dev/null; then
    echo "qwen3-coder model: INSTALLED" >> "$LOG_FILE" 2>/dev/null || true
else
    WARNINGS+=("qwen3-coder model not found. Install with: ollama pull qwen3-coder")
fi

# 4. Check for nomic-embed-text model
if curl -s "$OLLAMA_HOST/api/tags" | grep -q "nomic-embed-text" 2>/dev/null; then
    echo "nomic-embed-text model: INSTALLED" >> "$LOG_FILE" 2>/dev/null || true
else
    WARNINGS+=("nomic-embed-text model not found. Install with: ollama pull nomic-embed-text")
fi

# 5. Check Python version
if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version 2>&1)
    echo "Python: $PYTHON_VERSION" >> "$LOG_FILE" 2>/dev/null || true
else
    WARNINGS+=("Python3 not found in PATH")
fi

# 6. Check uv is available
if command -v uv &> /dev/null; then
    UV_VERSION=$(uv --version 2>&1)
    echo "uv: $UV_VERSION" >> "$LOG_FILE" 2>/dev/null || true
else
    WARNINGS+=("uv package manager not found - install for Python projects")
fi

# 7. Check git
if command -v git &> /dev/null; then
    GIT_VERSION=$(git --version 2>&1)
    echo "git: $GIT_VERSION" >> "$LOG_FILE" 2>/dev/null || true
else
    WARNINGS+=("git not found")
fi

# 8. Check disk space
DISK_USAGE=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')
if [[ $DISK_USAGE -gt 80 ]]; then
    WARNINGS+=("Disk usage high: ${DISK_USAGE}% (>80%)")
fi
echo "Disk usage: ${DISK_USAGE}%" >> "$LOG_FILE" 2>/dev/null || true

# 9. Check available RAM
if command -v free &> /dev/null; then
    RAM_FREE=$(free -h | awk 'NR==2 {print $7}')
    echo "RAM available: $RAM_FREE" >> "$LOG_FILE" 2>/dev/null || true
fi

# 10. Check if context-curator MCP is available (optional)
if [[ -n "${CONTEXT_CURATOR_HOST:-}" ]]; then
    if curl -s "$CONTEXT_CURATOR_HOST" > /dev/null 2>&1; then
        echo "Context Curator MCP: RUNNING" >> "$LOG_FILE" 2>/dev/null || true
    else
        WARNINGS+=("Context Curator MCP configured but not responding")
    fi
fi

# Log summary
{
    echo ""
    echo "=== Validation Summary ==="
    echo "Warnings: ${#WARNINGS[@]}"
    echo "Errors: ${#ERRORS[@]}"
    echo "Valid: $VALID"
    echo ""
} >> "$LOG_FILE" 2>/dev/null || true

# Build JSON output
JSON_WARNINGS="["
for i in "${!WARNINGS[@]}"; do
    JSON_WARNINGS+="\"${WARNINGS[$i]}\""
    if (( i < ${#WARNINGS[@]} - 1 )); then
        JSON_WARNINGS+=","
    fi
done
JSON_WARNINGS+="]"

JSON_ERRORS="["
for i in "${!ERRORS[@]}"; do
    JSON_ERRORS+="\"${ERRORS[$i]}\""
    if (( i < ${#ERRORS[@]} - 1 )); then
        JSON_ERRORS+=","
    fi
done
JSON_ERRORS+="]"

# Output JSON (never blocks, always continues)
cat <<EOF
{
  "valid": $([[ "$VALID" == true ]] && echo "true" || echo "false"),
  "timestamp": "$(date -u +'%Y-%m-%dT%H:%M:%SZ')",
  "checks": {
    "ollama_host": "${OLLAMA_HOST:-unknown}",
    "ollama_running": $(curl -s "$OLLAMA_HOST/api/tags" > /dev/null 2>&1 && echo "true" || echo "false"),
    "qwen3_coder_available": $(curl -s "$OLLAMA_HOST/api/tags" 2>/dev/null | grep -q "qwen3-coder" && echo "true" || echo "false"),
    "python3_available": $(command -v python3 > /dev/null && echo "true" || echo "false"),
    "git_available": $(command -v git > /dev/null && echo "true" || echo "false"),
    "disk_usage_percent": $DISK_USAGE
  },
  "warning_count": ${#WARNINGS[@]},
  "warnings": $JSON_WARNINGS,
  "error_count": ${#ERRORS[@]},
  "errors": $JSON_ERRORS,
  "action": "warnings do not block startup - continue normally",
  "log_file": "$LOG_FILE"
}
EOF

exit 0
