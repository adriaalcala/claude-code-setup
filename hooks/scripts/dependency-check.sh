#!/bin/bash
set -euo pipefail

# Pre-tool-use hook: Check for security vulnerabilities in new dependencies
# Purpose: Audit pip/npm packages before installation
# Output: JSON with {allowed: bool, warnings: [...]}

LOG_DIR="${LOG_DIR:-.}"
LOG_FILE="${LOG_DIR}/dependency-check.log"

# Parse command to detect dependency install
COMMAND="${1:-}"
ALLOWED=true
WARNINGS=()

# Detect pip install
if [[ "$COMMAND" =~ ^pip[[:space:]]+install ]]; then
    PACKAGE=$(echo "$COMMAND" | sed 's/pip install //' | awk '{print $1}')
    
    # Check if pip-audit is available
    if command -v pip-audit &> /dev/null; then
        # Run audit on specific package (if already installed)
        if pip show "$PACKAGE" > /dev/null 2>&1; then
            AUDIT_OUTPUT=$(pip-audit --desc 2>&1 || true)
            if echo "$AUDIT_OUTPUT" | grep -q "FOUND"; then
                WARNINGS+=("pip-audit: vulnerabilities found in dependencies")
            fi
        fi
    else
        WARNINGS+=("pip-audit not installed - skipping vulnerability check")
    fi
    
    # Log
    {
        echo "$(date -u +'%Y-%m-%dT%H:%M:%SZ') - pip install $PACKAGE - ALLOWED"
    } >> "$LOG_FILE" 2>/dev/null || true
fi

# Detect npm install
if [[ "$COMMAND" =~ ^npm[[:space:]]+install|^npm[[:space:]]+add ]] || \
   [[ "$COMMAND" =~ ^yarn[[:space:]]+add ]]; then
    
    TOOL="npm"
    [[ "$COMMAND" =~ ^yarn ]] && TOOL="yarn"
    PACKAGE=$(echo "$COMMAND" | sed 's/.* //' | awk '{print $1}')
    
    # Check if npm audit is available
    if command -v npm &> /dev/null; then
        # Run npm audit if package.json exists
        if [[ -f "package.json" ]]; then
            AUDIT_OUTPUT=$(npm audit 2>&1 || true)
            if echo "$AUDIT_OUTPUT" | grep -qi "vulnerabilities"; then
                WARNINGS+=("npm audit: vulnerabilities found in dependencies")
            fi
        fi
    else
        WARNINGS+=("npm audit not available - skipping vulnerability check")
    fi
    
    # Log
    {
        echo "$(date -u +'%Y-%m-%dT%H:%M:%SZ') - $TOOL install $PACKAGE - ALLOWED (with warnings)"
    } >> "$LOG_FILE" 2>/dev/null || true
fi

# Detect cargo add (Rust)
if [[ "$COMMAND" =~ ^cargo[[:space:]]+add ]]; then
    PACKAGE=$(echo "$COMMAND" | sed 's/cargo add //' | awk '{print $1}')
    
    # Note: cargo-audit would be checked here if configured
    WARNINGS+=("Rust dependency: $PACKAGE - ensure version compatibility")
    
    {
        echo "$(date -u +'%Y-%m-%dT%H:%M:%SZ') - cargo add $PACKAGE - ALLOWED"
    } >> "$LOG_FILE" 2>/dev/null || true
fi

# Always allow installation (fail-open), but warn
ALLOWED=true

# Output JSON
cat <<EOF
{
  "allowed": true,
  "reason": "Dependency installation allowed - check warnings",
  "warnings": [$(
    for warning in "${WARNINGS[@]}"; do
        printf '"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'%s'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"', "$warning"
    done | paste -sd',' -
  )],
  "action": "continue with install and review warnings",
  "log_file": "$LOG_FILE"
}
EOF

exit 0
