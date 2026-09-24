#!/bin/bash
# stop.sh - SessionStop hook for git summary on exit
# Generates final context snapshot and cleanup

set -euo pipefail

LOG_DIR="${LOG_DIR:-./.claude/logs}"
mkdir -p "$LOG_DIR"

TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)
SESSION_LOG="$LOG_DIR/session.log"
SUMMARY_LOG="$LOG_DIR/summary.log"

# Output result as JSON
output_result() {
  local summary_file="$1"
  local git_changed="$2"
  local commits_made="$3"

  cat <<EOF
{
  "timestamp": "$TIMESTAMP",
  "session_end": true,
  "summary_file": "$summary_file",
  "git_changed": $git_changed,
  "commits_made": $commits_made,
  "logs": {
    "session": "$SESSION_LOG",
    "summary": "$SUMMARY_LOG"
  }
}
EOF
}

# Generate git summary if in repo
generate_git_summary() {
  if [ ! -d ".git" ]; then
    return 0
  fi

  echo ""
  echo "=== GIT SUMMARY ==="
  echo "Repository: $(basename $(git rev-parse --show-toplevel))"
  echo "Current Branch: $(git rev-parse --abbrev-ref HEAD)"
  echo ""

  # Check for uncommitted changes
  local uncommitted=$(git status --porcelain | wc -l)

  if [ "$uncommitted" -gt 0 ]; then
    echo "Uncommitted Changes: $uncommitted"
    echo ""
    echo "Files Changed:"
    git status --porcelain | head -20 | sed 's/^/ /'

    if [ "$uncommitted" -gt 20 ]; then
      echo " ... and $((uncommitted - 20)) more files"
    fi
    echo ""
  else
    echo "All changes committed."
    echo ""
  fi

  # Check recent commits
  local recent=$(git log --oneline -5)

  if [ -n "$recent" ]; then
    echo "Recent Commits:"
    echo "$recent" | sed 's/^/ /'
    echo ""
  fi

  # Check for untracked files
  local untracked=$(git ls-files --others --exclude-standard | wc -l)

  if [ "$untracked" -gt 0 ]; then
    echo "Untracked Files: $untracked"
  fi
}

# Generate file statistics
generate_file_stats() {
  echo ""
  echo "=== FILE STATISTICS ==="

  # Count Python files modified
  local py_files=$(find . -name "*.py" -type f ! -path "./.git/*" ! -path "./.venv/*" ! -path "./venv/*" ! -path "./node_modules/*" 2>/dev/null | wc -l)
  echo "Python files: $py_files"

  # Count JS/TS files
  local js_files=$(find . -name "*.js" -o -name "*.ts" -o -name "*.tsx" -o -name "*.jsx" | grep -v ".git" | grep -v "node_modules" | wc -l)
  echo "JS/TS files: $js_files"

  # Count test files
  local test_files=$(find . -name "*test*.py" -o -name "*test*.js" -o -name "*spec*.js" | grep -v ".git" | grep -v "node_modules" | wc -l)
  echo "Test files: $test_files"

  # Total lines of code
  if command -v cloc &> /dev/null; then
    echo ""
    echo "Code Statistics (via cloc):"
    cloc . --quiet --exclude-dir=.git,node_modules,.venv,venv | tail -5 | sed 's/^/ /'
  fi
}

# Generate performance summary
generate_perf_summary() {
  echo ""
  echo "=== SESSION PERFORMANCE ==="

  # Check log files for timing information
  if [ -f "$LOG_DIR/failures.jsonl" ]; then
    local failure_count=$(wc -l < "$LOG_DIR/failures.jsonl")
    echo "Tool failures: $failure_count"
  fi

  # Check if there are bash logs with timing
  if [ -f "$LOG_DIR/bash-guard.log" ]; then
    local bash_commands=$(grep -c "ALLOW" "$LOG_DIR/bash-guard.log" || echo "0")
    echo "Bash commands executed: $bash_commands"
  fi

  # Check write operations
  if [ -f "$LOG_DIR/write-format.log" ]; then
    local formatted_files=$(grep -c "FORMAT" "$LOG_DIR/write-format.log" || echo "0")
    echo "Files formatted: $formatted_files"
  fi
}

# Generate context snapshot
generate_context_snapshot() {
  echo ""
  echo "=== CONTEXT SNAPSHOT ==="

  # Check Ollama status
  if curl -s http://127.0.0.1:11434/api/tags > /dev/null 2>&1; then
    local models=$(curl -s http://127.0.0.1:11434/api/tags | jq '.models[].name' 2>/dev/null | wc -l)
    echo "Ollama models available: $models"
  else
    echo "Ollama: offline"
  fi

  # Check Curator status
  if curl -s http://127.0.0.1:5555/health > /dev/null 2>&1; then
    local indexed=$(curl -s http://127.0.0.1:5555/projects 2>/dev/null | jq '.projects | length' || echo "0")
    echo "Indexed projects: $indexed"
  else
    echo "Context Curator: offline"
  fi

  # Check ChromaDB
  if curl -s http://127.0.0.1:8000/api/v1/heartbeat > /dev/null 2>&1; then
    echo "ChromaDB: online"
  else
    echo "ChromaDB: offline"
  fi
}

# Generate recommendations
generate_recommendations() {
  echo ""
  echo "=== RECOMMENDATIONS ==="

  local recommendations=0

  # Check for uncommitted changes
  if [ -d ".git" ]; then
    local uncommitted=$(git status --porcelain | wc -l)
    if [ "$uncommitted" -gt 0 ]; then
      echo "- Review and commit $uncommitted pending changes"
      recommendations=$((recommendations + 1))
    fi
  fi

  # Check for failing tests
  if [ -f "pytest.ini" ] || [ -f "setup.cfg" ] || [ -d "tests" ]; then
    if ! python -m pytest --collect-only > /dev/null 2>&1; then
      echo "- Run test suite to verify changes"
      recommendations=$((recommendations + 1))
    fi
  fi

  # Check for linting issues
  if [ -f "pyproject.toml" ] || [ -f ".ruff.toml" ] || [ -f "setup.cfg" ]; then
    if ! command -v ruff &> /dev/null; then
      echo "- Install ruff for Python linting (pip install ruff)"
      recommendations=$((recommendations + 1))
    fi
  fi

  # Check for security issues
  if [ -f "$LOG_DIR/failures.jsonl" ]; then
    if grep -q "connection_error\|timeout" "$LOG_DIR/failures.jsonl" 2>/dev/null; then
      echo "- Review service connectivity issues in logs"
      recommendations=$((recommendations + 1))
    fi
  fi

  if [ "$recommendations" -eq 0 ]; then
    echo "No critical recommendations at this time."
  fi
}

# Main execution
main() {
  # Start session stop log
  {
    echo "$TIMESTAMP - Session Stop"
    echo "=================="
    echo ""

    # Generate all sections
    generate_git_summary
    generate_file_stats
    generate_perf_summary
    generate_context_snapshot
    generate_recommendations

    echo ""
    echo "Session ended: $TIMESTAMP"
  } | tee -a "$SUMMARY_LOG"

  # Also log to session.log
  echo "[$TIMESTAMP] SessionStop" >> "$SESSION_LOG"

  # Count git changes and commits
  local git_changed=0
  local commits_made=0

  if [ -d ".git" ]; then
    git_changed=$(git status --porcelain | wc -l)

    # Count commits since session start (rough estimate)
    local session_start=$(grep "SessionStart" "$SESSION_LOG" | tail -1 | cut -d' ' -f2)
    if [ -n "$session_start" ]; then
      commits_made=$(git log --oneline --since="$session_start" 2>/dev/null | wc -l || echo "0")
    fi
  fi

  output_result "$SUMMARY_LOG" "$git_changed" "$commits_made"
}

main
