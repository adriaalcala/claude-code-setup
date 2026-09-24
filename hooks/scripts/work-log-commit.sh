#!/usr/bin/env bash
# Work Log - Auto-register git commits
# Triggers on PostToolUse for Bash commands
# Only logs if the command was a successful git commit

set -euo pipefail

LOG_DIR="$HOME/.claude/work-log"
TODAY=$(date +%Y-%m-%d)
LOG_FILE="$LOG_DIR/$TODAY.json"

# Read tool input from stdin (JSON with tool_input)
INPUT=$(cat)

# Extract the command that was executed
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)

# Only proceed if this was a git commit command
if [[ ! "$COMMAND" =~ ^git\ commit ]]; then
    exit 0
fi

# Check if we're in a git repo and the commit succeeded
if ! git rev-parse --is-inside-work-tree &>/dev/null; then
    exit 0
fi

# Get the last commit info
COMMIT_HASH=$(git log -1 --pretty=format:'%h' 2>/dev/null) || exit 0
COMMIT_MSG=$(git log -1 --pretty=format:'%s' 2>/dev/null) || exit 0
COMMIT_DATE=$(git log -1 --pretty=format:'%aI' 2>/dev/null) || exit 0
PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0
PROJECT_NAME=$(basename "$PROJECT_ROOT")

# Get files changed in this commit
FILES_CHANGED=$(git diff-tree --no-commit-id --name-only -r HEAD 2>/dev/null | jq -R -s 'split("\n") | map(select(length > 0))') || FILES_CHANGED="[]"

# Detect tags from commit message
TAGS="[]"
if [[ "$COMMIT_MSG" =~ ^feat ]]; then
    TAGS='["feature"]'
elif [[ "$COMMIT_MSG" =~ ^fix ]]; then
    TAGS='["bugfix"]'
elif [[ "$COMMIT_MSG" =~ ^docs ]]; then
    TAGS='["documentation"]'
elif [[ "$COMMIT_MSG" =~ ^test ]]; then
    TAGS='["testing"]'
elif [[ "$COMMIT_MSG" =~ ^refactor ]]; then
    TAGS='["refactor"]'
elif [[ "$COMMIT_MSG" =~ ^chore ]]; then
    TAGS='["chore"]'
fi

# Create log directory if needed
mkdir -p "$LOG_DIR"

# Create or load existing log file
if [[ -f "$LOG_FILE" ]]; then
    EXISTING=$(cat "$LOG_FILE")
else
    EXISTING='{"entries":[]}'
fi

# Create the new entry
TIMESTAMP=$(date -Iseconds)
NEW_ENTRY=$(jq -n \
    --arg ts "$TIMESTAMP" \
    --arg proj "$PROJECT_ROOT" \
    --arg projName "$PROJECT_NAME" \
    --arg desc "$COMMIT_MSG" \
    --arg hash "$COMMIT_HASH" \
    --arg msg "$COMMIT_MSG" \
    --argjson files "$FILES_CHANGED" \
    --argjson tags "$TAGS" \
    '{
        timestamp: $ts,
        type: "commit",
        project: $proj,
        project_name: $projName,
        description: $desc,
        files: $files,
        commit: {
            hash: $hash,
            message: $msg
        },
        tags: $tags
    }')

# Append to log file
echo "$EXISTING" | jq --argjson entry "$NEW_ENTRY" '.entries += [$entry]' > "$LOG_FILE"

# Silent success - no output to avoid interfering with Claude
exit 0
