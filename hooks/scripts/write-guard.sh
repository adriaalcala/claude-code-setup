#!/bin/bash
# write-guard.sh - PreToolUse hook to block protected file writes
# Detects secrets and prevents writing to system files

set -euo pipefail

LOG_DIR="${LOG_DIR:-./.claude/logs}"
mkdir -p "$LOG_DIR"

TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)
LOG_FILE="$LOG_DIR/write-guard.log"

# Input from Claude Code
FILE_PATH="${1:-}"
CONTENT="${2:-}"
OPERATION="${3:-write}"

# Output result as JSON
output_result() {
  local allowed="$1"
  local reason="$2"
  local risk_level="${3:-low}"

  cat <<EOF
{
  "allowed": $allowed,
  "reason": "$reason",
  "risk_level": "$risk_level",
  "timestamp": "$TIMESTAMP",
  "file": "$FILE_PATH",
  "operation": "$OPERATION"
}
EOF
}

# Protected system files - ALWAYS DENY writes
PROTECTED_FILES=(
  "/etc/passwd"
  "/etc/shadow"
  "/etc/group"
  "/etc/gshadow"
  "/etc/sudoers"
  "/etc/sudoers.d/"
  "/.ssh/"
  "/.gnupg/"
  "/root/"
  "/root/.bashrc"
  "/root/.bash_profile"
  "/root/.ssh/"
  "/.aws/credentials"
  "/.aws/config"
  "/.docker/config.json"
  "/var/lib/chromadb/"
  "/var/lib/ollama/"
  "/var/log/auth.log"
  "/var/log/syslog"
  "/boot/"
  "/sys/"
  "/proc/"
  "/dev/"
  "/usr/bin/"
  "/usr/sbin/"
  "/usr/local/bin/"
  "/usr/local/sbin/"
  "/etc/cron"
  "/etc/crontab"
  "/.env"
  "/.env.local"
  "/.env.production"
  "/.git/config"
  "/.gitconfig"
)

# Check protected files
for protected in "${PROTECTED_FILES[@]}"; do
  if [[ "$FILE_PATH" == "$protected"* ]]; then
    echo "$TIMESTAMP DENY: $OPERATION $FILE_PATH (protected file)" >> "$LOG_FILE"
    output_result "false" "Protected system file cannot be modified" "critical"
    exit 0
  fi
done

# Secret patterns - DETECT and BLOCK
SECRET_PATTERNS=(
  'PRIVATE KEY'
  'private_key'
  'private key'
  'BEGIN RSA PRIVATE KEY'
  'BEGIN DSA PRIVATE KEY'
  'BEGIN OPENSSH PRIVATE KEY'
  'BEGIN ENCRYPTED PRIVATE KEY'
  'password.*[=:]'
  'passwd.*[=:]'
  'secret.*[=:]'
  'api_key'
  'apikey'
  'api-key'
  'access_token'
  'accesstoken'
  'refresh_token'
  'refreshtoken'
  'oauth_token'
  'client_secret'
  'client_id.*secret'
  'aws_access_key'
  'aws_secret'
  'AKIA[0-9A-Z]\{16\}'  # AWS key pattern
  'ghp_[0-9A-Za-z]\{36\}'  # GitHub PAT pattern
  'github.*token'
  'database_password'
  'db_password'
  'db_url.*password'
  'DATABRICK_HOST'
  'DATABRICK_TOKEN'
  'OPENAI_API_KEY'
  'ANTHROPIC_API_KEY'
  'REPLICATE_API_KEY'
  'STRIPE_API_KEY'
  'STRIPE_SECRET_KEY'
  'mongodb.*password'
  'mysql.*password'
  'postgres.*password'
  'redis.*password'
)

for pattern in "${SECRET_PATTERNS[@]}"; do
  if [[ "$CONTENT" =~ $pattern ]]; then
    echo "$TIMESTAMP DENY: $OPERATION $FILE_PATH (contains secrets: $pattern)" >> "$LOG_FILE"
    output_result "false" "Content contains sensitive credentials or secrets" "critical"
    exit 0
  fi
done

# Suspicious binary patterns - BLOCK
if [[ "$CONTENT" =~ $'\x00' ]]; then
  echo "$TIMESTAMP DENY: $OPERATION $FILE_PATH (binary content)" >> "$LOG_FILE"
  output_result "false" "Cannot write binary content" "high"
  exit 0
fi

# Blocked file extensions
BLOCKED_EXTENSIONS=(
  ".exe"
  ".dll"
  ".so"
  ".dylib"
  ".pyc"
  ".o"
  ".a"
  ".bin"
  ".iso"
  ".dmg"
  ".elf"
  ".com"
)

for ext in "${BLOCKED_EXTENSIONS[@]}"; do
  if [[ "$FILE_PATH" == *"$ext" ]]; then
    echo "$TIMESTAMP DENY: $OPERATION $FILE_PATH (blocked extension)" >> "$LOG_FILE"
    output_result "false" "Binary file extension not allowed" "high"
    exit 0
  fi
done

# Dangerous shell scripts
if [[ "$FILE_PATH" == *.sh ]] || [[ "$FILE_PATH" == *.bash ]]; then
  # Check for dangerous patterns in shell scripts
  if [[ "$CONTENT" =~ rm\ -rf\ / ]] || \
     [[ "$CONTENT" =~ dd\ if=/dev/zero ]] || \
     [[ "$CONTENT" =~ mkfs ]] || \
     [[ "$CONTENT" =~ shutdown|reboot|poweroff ]]; then
    echo "$TIMESTAMP DENY: $OPERATION $FILE_PATH (dangerous shell script)" >> "$LOG_FILE"
    output_result "false" "Shell script contains dangerous commands" "critical"
    exit 0
  fi
fi

# Size check - prevent huge file writes
MAX_FILE_SIZE=$((100 * 1024 * 1024))  # 100 MB
CONTENT_SIZE=${#CONTENT}

if [ "$CONTENT_SIZE" -gt "$MAX_FILE_SIZE" ]; then
  echo "$TIMESTAMP DENY: $OPERATION $FILE_PATH (content too large: $CONTENT_SIZE bytes)" >> "$LOG_FILE"
  output_result "false" "Content exceeds maximum file size (100 MB)" "high"
  exit 0
fi

# Path traversal check
if [[ "$FILE_PATH" == *"/../"* ]] || [[ "$FILE_PATH" == *./* ]]; then
  echo "$TIMESTAMP SUSPICIOUS: $OPERATION $FILE_PATH (path traversal pattern)" >> "$LOG_FILE"
  output_result "false" "Path traversal pattern detected" "high"
  exit 0
fi

# Check for absolute paths (generally safer)
if [[ "$FILE_PATH" == /* ]]; then
  # Writing to root-level absolute paths needs caution
  if [[ "$FILE_PATH" != /tmp/* ]] && \
     [[ "$FILE_PATH" != /home/* ]] && \
     [[ "$FILE_PATH" != /var/tmp/* ]] && \
     [[ "$FILE_PATH" != /sessions/* ]] && \
     [[ "$FILE_PATH" != */.claude/* ]]; then
    echo "$TIMESTAMP DENY: $OPERATION $FILE_PATH (absolute path outside safe dirs)" >> "$LOG_FILE"
    output_result "false" "Absolute paths outside safe directories not allowed" "high"
    exit 0
  fi
fi

# Safe operations - ALLOW
if [[ "$OPERATION" == "write" ]] || [[ "$OPERATION" == "edit" ]] || [[ "$OPERATION" == "create" ]]; then
  # Check if file is in a safe directory
  SAFE_DIRS=(
    "./"
    "./src/"
    "./tests/"
    "./docs/"
    "./.claude/"
    "/tmp/"
    "/sessions/"
  )

  ALLOWED=0
  for safe_dir in "${SAFE_DIRS[@]}"; do
    if [[ "$FILE_PATH" == "$safe_dir"* ]] || [[ "$FILE_PATH" == *"$safe_dir"* ]]; then
      ALLOWED=1
      break
    fi
  done

  if [ $ALLOWED -eq 1 ]; then
    echo "$TIMESTAMP ALLOW: $OPERATION $FILE_PATH (safe directory)" >> "$LOG_FILE"
    output_result "true" "File write allowed in safe directory" "low"
    exit 0
  fi
fi

# Default: DENY (fail-closed)
echo "$TIMESTAMP DENY_DEFAULT: $OPERATION $FILE_PATH (not in safe location)" >> "$LOG_FILE"
output_result "false" "File write not allowed: path not in safe directory" "medium"
exit 0
