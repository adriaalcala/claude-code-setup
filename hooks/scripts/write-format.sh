#!/bin/bash
# write-format.sh - PostToolUse hook to auto-format files after writes
# Applies ruff/prettier/black based on file type

set -euo pipefail

LOG_DIR="${LOG_DIR:-./.claude/logs}"
mkdir -p "$LOG_DIR"

TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)
LOG_FILE="$LOG_DIR/write-format.log"

# Input from Claude Code
FILE_PATH="${1:-}"

# Output result as JSON
output_result() {
  local formatted="$1"
  local formatter="$2"
  local status="${3:-success}"

  cat <<EOF
{
  "formatted": $formatted,
  "formatter": "$formatter",
  "status": "$status",
  "timestamp": "$TIMESTAMP",
  "file": "$FILE_PATH"
}
EOF
}

# Check if file exists
if [ ! -f "$FILE_PATH" ]; then
  output_result "false" "none" "file_not_found"
  exit 0
fi

# Get file extension
FILE_EXT="${FILE_PATH##*.}"
FILE_NAME=$(basename "$FILE_PATH")

# Check for shebang (shell scripts)
if head -1 "$FILE_PATH" | grep -q '^#!/'; then
  FILE_EXT="sh"
fi

# Format based on file type

# Python files
if [[ "$FILE_EXT" == "py" ]]; then
  # Try ruff first (modern, fast)
  if command -v ruff &> /dev/null; then
    if ruff format "$FILE_PATH" 2>&1 | grep -q "reformatted"; then
      echo "$TIMESTAMP FORMAT: $FILE_PATH (ruff)" >> "$LOG_FILE"
      output_result "true" "ruff" "success"
      exit 0
    elif ruff check --fix "$FILE_PATH" 2>&1 > /dev/null; then
      echo "$TIMESTAMP LINT_FIX: $FILE_PATH (ruff)" >> "$LOG_FILE"
      output_result "true" "ruff" "success"
      exit 0
    fi
  fi

  # Fall back to black
  if command -v black &> /dev/null; then
    if black "$FILE_PATH" --quiet 2>&1; then
      echo "$TIMESTAMP FORMAT: $FILE_PATH (black)" >> "$LOG_FILE"
      output_result "true" "black" "success"
      exit 0
    fi
  fi

  # Fall back to autopep8
  if command -v autopep8 &> /dev/null; then
    autopep8 --in-place --aggressive --aggressive "$FILE_PATH"
    echo "$TIMESTAMP FORMAT: $FILE_PATH (autopep8)" >> "$LOG_FILE"
    output_result "true" "autopep8" "success"
    exit 0
  fi

  echo "$TIMESTAMP NO_FORMATTER: $FILE_PATH (no Python formatter available)" >> "$LOG_FILE"
  output_result "false" "none" "no_formatter"
  exit 0
fi

# TypeScript/JavaScript files
if [[ "$FILE_EXT" == "ts" ]] || [[ "$FILE_EXT" == "tsx" ]] || [[ "$FILE_EXT" == "js" ]] || [[ "$FILE_EXT" == "jsx" ]]; then
  # Try prettier
  if command -v prettier &> /dev/null; then
    if prettier --write "$FILE_PATH" 2>&1 > /dev/null; then
      echo "$TIMESTAMP FORMAT: $FILE_PATH (prettier)" >> "$LOG_FILE"
      output_result "true" "prettier" "success"
      exit 0
    fi
  fi

  # Try eslint
  if command -v eslint &> /dev/null; then
    if eslint --fix "$FILE_PATH" 2>&1 > /dev/null; then
      echo "$TIMESTAMP LINT_FIX: $FILE_PATH (eslint)" >> "$LOG_FILE"
      output_result "true" "eslint" "success"
      exit 0
    fi
  fi

  echo "$TIMESTAMP NO_FORMATTER: $FILE_PATH (no JS/TS formatter available)" >> "$LOG_FILE"
  output_result "false" "none" "no_formatter"
  exit 0
fi

# Shell scripts
if [[ "$FILE_EXT" == "sh" ]] || [[ "$FILE_EXT" == "bash" ]]; then
  # Try shfmt
  if command -v shfmt &> /dev/null; then
    if shfmt -i 2 -w "$FILE_PATH" 2>&1 > /dev/null; then
      echo "$TIMESTAMP FORMAT: $FILE_PATH (shfmt)" >> "$LOG_FILE"
      output_result "true" "shfmt" "success"
      exit 0
    fi
  fi

  echo "$TIMESTAMP NO_FORMATTER: $FILE_PATH (no shell formatter available)" >> "$LOG_FILE"
  output_result "false" "none" "no_formatter"
  exit 0
fi

# JSON files
if [[ "$FILE_EXT" == "json" ]]; then
  # Try jq
  if command -v jq &> /dev/null; then
    if jq . "$FILE_PATH" > "$FILE_PATH.tmp" 2>&1; then
      mv "$FILE_PATH.tmp" "$FILE_PATH"
      echo "$TIMESTAMP FORMAT: $FILE_PATH (jq)" >> "$LOG_FILE"
      output_result "true" "jq" "success"
      exit 0
    fi
  fi

  # Try prettier
  if command -v prettier &> /dev/null; then
    if prettier --write "$FILE_PATH" 2>&1 > /dev/null; then
      echo "$TIMESTAMP FORMAT: $FILE_PATH (prettier)" >> "$LOG_FILE"
      output_result "true" "prettier" "success"
      exit 0
    fi
  fi

  # Try Python json module
  if command -v python3 &> /dev/null; then
    python3 -c "
import json
import sys
try:
  with open('$FILE_PATH', 'r') as f:
    data = json.load(f)
  with open('$FILE_PATH', 'w') as f:
    json.dump(data, f, indent=2)
except Exception as e:
  sys.exit(1)
" 2>&1 && {
      echo "$TIMESTAMP FORMAT: $FILE_PATH (python-json)" >> "$LOG_FILE"
      output_result "true" "python-json" "success"
      exit 0
    }
  fi

  echo "$TIMESTAMP NO_FORMATTER: $FILE_PATH (no JSON formatter available)" >> "$LOG_FILE"
  output_result "false" "none" "no_formatter"
  exit 0
fi

# YAML files
if [[ "$FILE_EXT" == "yaml" ]] || [[ "$FILE_EXT" == "yml" ]]; then
  # Try yamlfmt
  if command -v yamlfmt &> /dev/null; then
    if yamlfmt -w "$FILE_PATH" 2>&1 > /dev/null; then
      echo "$TIMESTAMP FORMAT: $FILE_PATH (yamlfmt)" >> "$LOG_FILE"
      output_result "true" "yamlfmt" "success"
      exit 0
    fi
  fi

  echo "$TIMESTAMP NO_FORMATTER: $FILE_PATH (no YAML formatter available)" >> "$LOG_FILE"
  output_result "false" "none" "no_formatter"
  exit 0
fi

# Markdown files
if [[ "$FILE_EXT" == "md" ]]; then
  # Try prettier
  if command -v prettier &> /dev/null; then
    if prettier --write "$FILE_PATH" 2>&1 > /dev/null; then
      echo "$TIMESTAMP FORMAT: $FILE_PATH (prettier)" >> "$LOG_FILE"
      output_result "true" "prettier" "success"
      exit 0
    fi
  fi

  echo "$TIMESTAMP NO_FORMATTER: $FILE_PATH (no Markdown formatter available)" >> "$LOG_FILE"
  output_result "false" "none" "no_formatter"
  exit 0
fi

# HTML files
if [[ "$FILE_EXT" == "html" ]]; then
  # Try prettier
  if command -v prettier &> /dev/null; then
    if prettier --write "$FILE_PATH" 2>&1 > /dev/null; then
      echo "$TIMESTAMP FORMAT: $FILE_PATH (prettier)" >> "$LOG_FILE"
      output_result "true" "prettier" "success"
      exit 0
    fi
  fi

  echo "$TIMESTAMP NO_FORMATTER: $FILE_PATH (no HTML formatter available)" >> "$LOG_FILE"
  output_result "false" "none" "no_formatter"
  exit 0
fi

# CSS/SCSS/LESS files
if [[ "$FILE_EXT" == "css" ]] || [[ "$FILE_EXT" == "scss" ]] || [[ "$FILE_EXT" == "less" ]]; then
  # Try prettier
  if command -v prettier &> /dev/null; then
    if prettier --write "$FILE_PATH" 2>&1 > /dev/null; then
      echo "$TIMESTAMP FORMAT: $FILE_PATH (prettier)" >> "$LOG_FILE"
      output_result "true" "prettier" "success"
      exit 0
    fi
  fi

  echo "$TIMESTAMP NO_FORMATTER: $FILE_PATH (no CSS formatter available)" >> "$LOG_FILE"
  output_result "false" "none" "no_formatter"
  exit 0
fi

# Go files
if [[ "$FILE_EXT" == "go" ]]; then
  # Try gofmt
  if command -v gofmt &> /dev/null; then
    if gofmt -w "$FILE_PATH" 2>&1 > /dev/null; then
      echo "$TIMESTAMP FORMAT: $FILE_PATH (gofmt)" >> "$LOG_FILE"
      output_result "true" "gofmt" "success"
      exit 0
    fi
  fi

  echo "$TIMESTAMP NO_FORMATTER: $FILE_PATH (no Go formatter available)" >> "$LOG_FILE"
  output_result "false" "none" "no_formatter"
  exit 0
fi

# Rust files
if [[ "$FILE_EXT" == "rs" ]]; then
  # Try rustfmt
  if command -v rustfmt &> /dev/null; then
    if rustfmt "$FILE_PATH" 2>&1 > /dev/null; then
      echo "$TIMESTAMP FORMAT: $FILE_PATH (rustfmt)" >> "$LOG_FILE"
      output_result "true" "rustfmt" "success"
      exit 0
    fi
  fi

  echo "$TIMESTAMP NO_FORMATTER: $FILE_PATH (no Rust formatter available)" >> "$LOG_FILE"
  output_result "false" "none" "no_formatter"
  exit 0
fi

# Unsupported file type
echo "$TIMESTAMP UNSUPPORTED: $FILE_PATH (extension: $FILE_EXT)" >> "$LOG_FILE"
output_result "false" "none" "unsupported_type"
exit 0
