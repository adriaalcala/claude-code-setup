#!/bin/bash
# bash-vuln.sh - Vulnerability detection after npm install
# Checks for known security issues in dependencies

set -euo pipefail

LOG_DIR="${LOG_DIR:-./.claude/logs}"
mkdir -p "$LOG_DIR"

TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)
LOG_FILE="$LOG_DIR/vuln.log"

# Input from Claude Code
OPERATION="${1:-npm-install}"  # npm-install, pip-install, bundler, cargo, etc.

# Output result as JSON
output_result() {
  local vulnerabilities="$1"
  local severity="${2:-info}"
  local requires_action="${3:-false}"

  cat <<EOF
{
  "timestamp": "$TIMESTAMP",
  "operation": "$OPERATION",
  "vulnerabilities_found": $vulnerabilities,
  "severity": "$severity",
  "requires_action": $requires_action,
  "log_file": "$LOG_FILE"
}
EOF
}

# NPM vulnerability check
check_npm_vulns() {
  if [ ! -f "package.json" ]; then
    return 0
  fi

  if ! command -v npm &> /dev/null; then
    return 0
  fi

  # Run npm audit and capture results
  AUDIT_OUTPUT=$(npm audit --json 2>/dev/null || echo '{}')

  # Parse vulnerabilities
  CRITICAL=$(echo "$AUDIT_OUTPUT" | jq '.metadata.vulnerabilities.critical // 0')
  HIGH=$(echo "$AUDIT_OUTPUT" | jq '.metadata.vulnerabilities.high // 0')
  MODERATE=$(echo "$AUDIT_OUTPUT" | jq '.metadata.vulnerabilities.moderate // 0')
  LOW=$(echo "$AUDIT_OUTPUT" | jq '.metadata.vulnerabilities.low // 0')

  TOTAL=$((CRITICAL + HIGH + MODERATE + LOW))

  if [ "$CRITICAL" -gt 0 ]; then
    echo "$TIMESTAMP CRITICAL NPM VULNERABILITIES: $CRITICAL critical, $HIGH high, $MODERATE moderate, $LOW low" >> "$LOG_FILE"
    return 2
  elif [ "$HIGH" -gt 0 ]; then
    echo "$TIMESTAMP HIGH NPM VULNERABILITIES: $HIGH high, $MODERATE moderate, $LOW low" >> "$LOG_FILE"
    return 1
  elif [ "$MODERATE" -gt 0 ]; then
    echo "$TIMESTAMP MODERATE NPM VULNERABILITIES: $MODERATE moderate, $LOW low" >> "$LOG_FILE"
    return 0
  else
    echo "$TIMESTAMP NPM audit passed: $TOTAL vulnerabilities" >> "$LOG_FILE"
    return 0
  fi

  echo "$TOTAL"
}

# Python pip vulnerability check
check_pip_vulns() {
  if [ ! -f "requirements.txt" ] && [ ! -f "setup.py" ] && [ ! -f "pyproject.toml" ]; then
    return 0
  fi

  if ! command -v pip &> /dev/null; then
    return 0
  fi

  # Check if safety is installed
  if ! command -v safety &> /dev/null; then
    echo "$TIMESTAMP SKIPPED: pip safety not installed" >> "$LOG_FILE"
    return 0
  fi

  # Run safety check
  SAFETY_OUTPUT=$(safety check --json 2>/dev/null || echo '[]')

  TOTAL=$(echo "$SAFETY_OUTPUT" | jq 'length')

  # Check for critical packages
  CRITICAL=$(echo "$SAFETY_OUTPUT" | jq '[.[] | select(.cve != null)] | length')

  if [ "$CRITICAL" -gt 0 ]; then
    echo "$TIMESTAMP CRITICAL PYTHON VULNERABILITIES: $CRITICAL CVEs found" >> "$LOG_FILE"
    return 2
  elif [ "$TOTAL" -gt 0 ]; then
    echo "$TIMESTAMP PYTHON VULNERABILITIES: $TOTAL vulnerabilities found" >> "$LOG_FILE"
    return 1
  else
    echo "$TIMESTAMP Python safety check passed" >> "$LOG_FILE"
    return 0
  fi

  echo "$TOTAL"
}

# Ruby bundler vulnerability check
check_bundler_vulns() {
  if [ ! -f "Gemfile" ] && [ ! -f "Gemfile.lock" ]; then
    return 0
  fi

  if ! command -v bundler &> /dev/null && ! command -v bundle &> /dev/null; then
    return 0
  fi

  # Check if bundler-audit is installed
  if ! command -v bundle-audit &> /dev/null; then
    echo "$TIMESTAMP SKIPPED: bundler-audit not installed" >> "$LOG_FILE"
    return 0
  fi

  # Run bundler audit
  AUDIT_OUTPUT=$(bundle-audit check --json 2>/dev/null || echo '{"vulnerabilities": []}')

  TOTAL=$(echo "$AUDIT_OUTPUT" | jq '.vulnerabilities | length')

  if [ "$TOTAL" -gt 0 ]; then
    echo "$TIMESTAMP RUBY VULNERABILITIES: $TOTAL vulnerabilities found" >> "$LOG_FILE"
    return 1
  else
    echo "$TIMESTAMP Bundler audit passed" >> "$LOG_FILE"
    return 0
  fi

  echo "$TOTAL"
}

# Rust cargo vulnerability check
check_cargo_vulns() {
  if [ ! -f "Cargo.toml" ]; then
    return 0
  fi

  if ! command -v cargo &> /dev/null; then
    return 0
  fi

  # Check if cargo-audit is installed
  if ! command -v cargo-audit &> /dev/null; then
    echo "$TIMESTAMP SKIPPED: cargo-audit not installed" >> "$LOG_FILE"
    return 0
  fi

  # Run cargo audit
  AUDIT_OUTPUT=$(cargo audit --json 2>/dev/null || echo '{"vulnerabilities": []}')

  # Parse vulnerabilities
  TOTAL=$(echo "$AUDIT_OUTPUT" | jq '.vulnerabilities | length')

  if [ "$TOTAL" -gt 0 ]; then
    echo "$TIMESTAMP RUST VULNERABILITIES: $TOTAL vulnerabilities found" >> "$LOG_FILE"
    return 1
  else
    echo "$TIMESTAMP Cargo audit passed" >> "$LOG_FILE"
    return 0
  fi

  echo "$TOTAL"
}

# Go module vulnerability check
check_go_vulns() {
  if [ ! -f "go.mod" ]; then
    return 0
  fi

  if ! command -v go &> /dev/null; then
    return 0
  fi

  # Check if govulncheck is installed
  if ! command -v govulncheck &> /dev/null; then
    echo "$TIMESTAMP SKIPPED: govulncheck not installed" >> "$LOG_FILE"
    return 0
  fi

  # Run govulncheck
  VULN_OUTPUT=$(govulncheck ./... 2>&1 || echo "")

  if echo "$VULN_OUTPUT" | grep -q "found.*vulnerabilities"; then
    TOTAL=$(echo "$VULN_OUTPUT" | grep -c "vulnerability" || echo "1")
    echo "$TIMESTAMP GO VULNERABILITIES: $TOTAL vulnerabilities found" >> "$LOG_FILE"
    return 1
  else
    echo "$TIMESTAMP Go vulnerability check passed" >> "$LOG_FILE"
    return 0
  fi

  echo "0"
}

# Check for hardcoded secrets
check_hardcoded_secrets() {
  # Try using truffleHog if available
  if command -v truffleHog &> /dev/null; then
    SECRETS=$(truffleHog filesystem . --json 2>/dev/null | jq 'select(.verified == true)' | wc -l)

    if [ "$SECRETS" -gt 0 ]; then
      echo "$TIMESTAMP HARDCODED SECRETS: $SECRETS potential secrets found" >> "$LOG_FILE"
      return 2
    fi
  fi

  # Try using detect-secrets
  if command -v detect-secrets &> /dev/null; then
    SECRETS=$(detect-secrets scan . 2>/dev/null | jq '.results | length')

    if [ "$SECRETS" -gt 0 ]; then
      echo "$TIMESTAMP HARDCODED SECRETS: $SECRETS potential secrets found" >> "$LOG_FILE"
      return 2
    fi
  fi

  return 0
}

# Check for outdated packages
check_outdated() {
  # Only warn, don't block
  if [ -f "package.json" ] && command -v npm &> /dev/null; then
    OUTDATED=$(npm outdated --json 2>/dev/null | jq 'keys | length' || echo "0")
    if [ "$OUTDATED" -gt 0 ]; then
      echo "$TIMESTAMP WARNING: $OUTDATED npm packages are outdated" >> "$LOG_FILE"
    fi
  fi

  if [ -f "Gemfile" ] && command -v bundle &> /dev/null; then
    OUTDATED=$(bundle outdated --parseable 2>/dev/null | wc -l || echo "0")
    if [ "$OUTDATED" -gt 0 ]; then
      echo "$TIMESTAMP WARNING: $OUTDATED Ruby gems are outdated" >> "$LOG_FILE"
    fi
  fi

  return 0
}

# Main vulnerability check logic
main() {
  VULN_COUNT=0
  MAX_SEVERITY="info"
  ACTION_REQUIRED="false"

  echo "$TIMESTAMP Starting vulnerability check for operation: $OPERATION" >> "$LOG_FILE"

  # Check based on operation type
  case "$OPERATION" in
    npm-install)
      if check_npm_vulns; then
        VULN_COUNT=$?
      fi
      ;;
    pip-install)
      if check_pip_vulns; then
        VULN_COUNT=$?
      fi
      ;;
    bundler)
      if check_bundler_vulns; then
        VULN_COUNT=$?
      fi
      ;;
    cargo)
      if check_cargo_vulns; then
        VULN_COUNT=$?
      fi
      ;;
    go)
      if check_go_vulns; then
        VULN_COUNT=$?
      fi
      ;;
    *)
      # Run all checks
      check_npm_vulns 2>/dev/null || VULN_COUNT=$?
      check_pip_vulns 2>/dev/null || VULN_COUNT=$?
      check_bundler_vulns 2>/dev/null || VULN_COUNT=$?
      check_cargo_vulns 2>/dev/null || VULN_COUNT=$?
      check_go_vulns 2>/dev/null || VULN_COUNT=$?
      ;;
  esac

  # Check for hardcoded secrets
  check_hardcoded_secrets && {
    MAX_SEVERITY="critical"
    ACTION_REQUIRED="true"
  } || true

  # Check for outdated packages
  check_outdated

  # Determine severity based on return codes
  if [ "$VULN_COUNT" -ge 2 ]; then
    MAX_SEVERITY="critical"
    ACTION_REQUIRED="true"
  elif [ "$VULN_COUNT" -ge 1 ]; then
    MAX_SEVERITY="high"
    ACTION_REQUIRED="true"
  fi

  output_result "$VULN_COUNT" "$MAX_SEVERITY" "$ACTION_REQUIRED"

  # Return exit code based on severity
  if [ "$ACTION_REQUIRED" = "true" ]; then
    echo "$TIMESTAMP Vulnerability check completed with issues" >> "$LOG_FILE"
    exit 1
  else
    echo "$TIMESTAMP Vulnerability check completed successfully" >> "$LOG_FILE"
    exit 0
  fi
}

main
