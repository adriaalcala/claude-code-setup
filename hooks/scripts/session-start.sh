#!/bin/bash
# session-start.sh - SessionStart hook for local dev machine
# Detects project, checks services, initializes context

set -euo pipefail

LOG_DIR="${LOG_DIR:-./.claude/logs}"
mkdir -p "$LOG_DIR"

TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)

# Detect current project
detect_project() {
  local cwd="$PWD"

  # Check for git repo
  if [ -d ".git" ]; then
    local project_name=$(basename "$(git rev-parse --show-toplevel)")
    local branch=$(git rev-parse --abbrev-ref HEAD)
    local commit=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")

    echo "{
  \"type\": \"git\",
  \"name\": \"$project_name\",
  \"root\": \"$(git rev-parse --show-toplevel)\",
  \"branch\": \"$branch\",
  \"commit\": \"$commit\"
}"
    return 0
  fi

  # Check for package.json (Node project)
  if [ -f "package.json" ]; then
    local name=$(jq -r '.name' package.json 2>/dev/null || echo "unknown")
    echo "{
  \"type\": \"node\",
  \"name\": \"$name\",
  \"root\": \"$cwd\"
}"
    return 0
  fi

  # Check for setup.py (Python project)
  if [ -f "setup.py" ] || [ -f "pyproject.toml" ]; then
    local name=$(basename "$cwd")
    echo "{
  \"type\": \"python\",
  \"name\": \"$name\",
  \"root\": \"$cwd\"
}"
    return 0
  fi

  # Check for go.mod (Go project)
  if [ -f "go.mod" ]; then
    local name=$(head -1 go.mod | awk '{print $2}')
    echo "{
  \"type\": \"go\",
  \"name\": \"$name\",
  \"root\": \"$cwd\"
}"
    return 0
  fi

  # Check for Cargo.toml (Rust project)
  if [ -f "Cargo.toml" ]; then
    local name=$(grep -m1 '^name' Cargo.toml | cut -d'"' -f2)
    echo "{
  \"type\": \"rust\",
  \"name\": \"$name\",
  \"root\": \"$cwd\"
}"
    return 0
  fi

  # Default: generic project
  echo "{
  \"type\": \"generic\",
  \"name\": \"$(basename $cwd)\",
  \"root\": \"$cwd\"
}"
}

# Check Ollama status and models
check_ollama() {
  local ollama_url="http://127.0.0.1:11434"

  # Check if Ollama is running
  if ! curl -s "$ollama_url/api/tags" > /dev/null 2>&1; then
    echo "{
  \"status\": \"offline\",
  \"message\": \"Ollama is not running\"
}"
    return 1
  fi

  # Get loaded models
  local models=$(curl -s "$ollama_url/api/tags" | jq '.models[].name' 2>/dev/null | tr '\n' ',' | sed 's/,$//')

  echo "{
  \"status\": \"online\",
  \"url\": \"$ollama_url\",
  \"models\": [$models]
}"
}

# Check Context Curator API health
check_curator() {
  local curator_url="http://127.0.0.1:5555"

  # Check if Curator API is running
  if ! curl -s "$curator_url/health" > /dev/null 2>&1; then
    echo "{
  \"status\": \"offline\",
  \"message\": \"Context Curator API is not running\"
}"
    return 1
  fi

  # Get project count and indexing status
  local projects=$(curl -s "$curator_url/projects" 2>/dev/null | jq '.projects | length' || echo "0")
  local total_chunks=$(curl -s "$curator_url/projects" 2>/dev/null | jq '[.projects[].chunk_count] | add' || echo "0")

  echo "{
  \"status\": \"online\",
  \"url\": \"$curator_url\",
  \"indexed_projects\": $projects,
  \"total_chunks\": $total_chunks
}"
}

# Check ChromaDB health
check_chromadb() {
  local chromadb_url="http://127.0.0.1:8000"

  # Check heartbeat
  if ! curl -s "$chromadb_url/api/v1/heartbeat" > /dev/null 2>&1; then
    echo "{
  \"status\": \"offline\",
  \"message\": \"ChromaDB is not running\"
}"
    return 1
  fi

  # Get collection count
  local collections=$(curl -s "$chromadb_url/api/v1/collections" 2>/dev/null | jq 'length' || echo "0")

  echo "{
  \"status\": \"online\",
  \"url\": \"$chromadb_url\",
  \"collections\": $collections
}"
}

# Check sync agents
check_sync_agents() {
  local curator_url="http://127.0.0.1:5555"

  # Get connected agents
  local agents=$(curl -s "$curator_url/agents" 2>/dev/null | jq '.agents // [] | length' || echo "0")

  echo "{
  \"connected_agents\": $agents
}"
}

# Gather system information
get_system_info() {
  local cpu=$(nproc 2>/dev/null || echo "unknown")
  local memory=$(free -h 2>/dev/null | awk '/^Mem:/ {print $2}' || echo "unknown")
  local disk=$(df -h / 2>/dev/null | awk 'NR==2 {print $2}' || echo "unknown")
  local hostname=$(hostname 2>/dev/null || echo "unknown")

  echo "{
  \"hostname\": \"$hostname\",
  \"cpu_cores\": $cpu,
  \"memory\": \"$memory\",
  \"disk_total\": \"$disk\",
  \"os\": \"$(uname -s)\",
  \"kernel\": \"$(uname -r)\"
}"
}

# Check git status if in repo
get_git_status() {
  if [ -d ".git" ]; then
    local status=$(git status --porcelain | wc -l)
    local commits_ahead=$(git rev-list --count @{u}..HEAD 2>/dev/null || echo "0")

    echo "{
  \"has_changes\": $((status > 0)),
  \"uncommitted_count\": $status,
  \"commits_ahead\": $commits_ahead
}"
  else
    echo "{
  \"has_changes\": false,
  \"uncommitted_count\": 0
}"
  fi
}

# Main output
echo "{"
echo "  \"timestamp\": \"$TIMESTAMP\","
echo "  \"session_type\": \"local-dev-server\","
echo ""

# Project detection
echo "  \"project\": $(detect_project),"
echo ""

# System information
echo "  \"system\": $(get_system_info),"
echo ""

# Service status
echo "  \"services\": {"
echo "    \"ollama\": $(check_ollama),"
echo "    \"curator\": $(check_curator),"
echo "    \"chromadb\": $(check_chromadb),"
echo "    \"sync_agents\": $(check_sync_agents)"
echo "  },"
echo ""

# Version information
echo "  \"versions\": {"
echo "    \"ollama\": \"$(ollama -v 2>/dev/null | head -1 || echo 'unknown')\""
echo "  },"
echo ""

# Git status if applicable
echo "  \"git\": $(get_git_status),"
echo ""

# Log entry
echo "  \"log_file\": \"$LOG_DIR/session.log\""
echo "}"

# Log to file
cat >> "$LOG_DIR/session.log" <<EOF
[SessionStart] $TIMESTAMP
Project: $(detect_project | jq -r '.name')
Ollama: $(check_ollama | jq -r '.status')
Curator: $(check_curator | jq -r '.status')
ChromaDB: $(check_chromadb | jq -r '.status')
---
EOF
