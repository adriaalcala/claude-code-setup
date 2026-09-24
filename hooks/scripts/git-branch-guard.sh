#!/bin/bash
set -euo pipefail

# Pre-tool-use hook: Detect and prevent pushes to protected branches
# Purpose: Prevent accidental commits/pushes to main, master, develop, release/*
# Output: JSON with {allowed: bool, reason: "..."}

LOG_DIR="${LOG_DIR:-.}"

# Get current branch
CURRENT_BRANCH=$(git branch --show-current 2>/dev/null || echo "")

# Protected branches pattern
PROTECTED_PATTERNS=(
    "^main$"
    "^master$"
    "^develop$"
    "^release/.*$"
)

# Allowed patterns (these are safe to work on)
ALLOWED_PATTERNS=(
    "^feature/.*"
    "^fix/.*"
    "^hotfix/.*"
    "^refactor/.*"
    "^docs/.*"
    "^test/.*"
    "^wip/.*"
)

ALLOWED=true
REASON="Branch is allowed"

# Check if current branch is protected
for pattern in "${PROTECTED_PATTERNS[@]}"; do
    if [[ "$CURRENT_BRANCH" =~ $pattern ]]; then
        ALLOWED=false
        REASON="Protected branch: $CURRENT_BRANCH. Use feature/*, fix/*, hotfix/*, etc."
        break
    fi
done

# Check if branch matches allowed patterns (override protection check)
for pattern in "${ALLOWED_PATTERNS[@]}"; do
    if [[ "$CURRENT_BRANCH" =~ $pattern ]]; then
        ALLOWED=true
        REASON="Branch '$CURRENT_BRANCH' is allowed for development"
        break
    fi
done

# Log to file
LOG_FILE="${LOG_DIR}/git-branch-guard.log"
{
    echo "$(date -u +'%Y-%m-%dT%H:%M:%SZ') - Branch: $CURRENT_BRANCH, Allowed: $ALLOWED"
} >> "$LOG_FILE" 2>/dev/null || true

# Output JSON
cat <<EOF
{
  "allowed": $([[ "$ALLOWED" == true ]] && echo "true" || echo "false"),
  "reason": "$REASON",
  "branch": "$CURRENT_BRANCH",
  "timestamp": "$(date -u +'%Y-%m-%dT%H:%M:%SZ')"
}
EOF

# Exit with success (hook doesn't block, only warns)
exit 0
