#!/bin/bash
# bash-guard.sh - PreToolUse hook to block dangerous commands
# Fail-closed: defaults to DENY on any error

set -euo pipefail

# Log directory
LOG_DIR="${LOG_DIR:-./.claude/logs}"
mkdir -p "$LOG_DIR"

TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)
LOG_FILE="$LOG_DIR/bash-guard.log"

# Input from Claude Code
COMMAND="${1:-}"
CONTEXT="${2:-}"

# Output result as JSON
output_result() {
  local allowed="$1"
  local reason="$2"

  cat <<EOF
{
  "allowed": $allowed,
  "reason": "$reason",
  "timestamp": "$TIMESTAMP",
  "command_preview": "${COMMAND:0:100}"
}
EOF
}

# Dangerous commands - ALWAYS DENY
DANGEROUS_PATTERNS=(
  '^rm\s+-rf\s+/'
  '^rm\s+-rf\s+\*'
  '^dd\s+if=/dev/zero'
  '^mkfs'
  '^fsck'
  '^fdisk'
  '^parted\s'
  '^kpartx'
  '^dmsetup'
  '^lvm\s'
  '^cryptsetup\s'
  '^halt'
  '^poweroff'
  '^reboot'
  '^shutdown'
  '^init\s+0'
  '^telinit\s+0'
  '^systemctl\s+poweroff'
  '^systemctl\s+reboot'
  '^systemctl\s+halt'
  '^chmod\s+777\s+/'
  '^chown\s+\*:\*'
  'rm.*\$HOME'
  'rm.*~'
  '>\s*/etc/passwd'
  '>\s*/etc/shadow'
  '>\s*/.bashrc'
  '>\s*/.bash_profile'
  'wget.*malware'
  'curl.*\|\s*bash'
  '&&\s*sudo\s+rm'
  '&&\s*rm\s+-rf'
  ';\s*sudo\s+rm'
  ';\s*rm\s+-rf'
)

# Check for dangerous patterns
for pattern in "${DANGEROUS_PATTERNS[@]}"; do
  if [[ "$COMMAND" =~ $pattern ]]; then
    echo "$TIMESTAMP DENY: $COMMAND (matched pattern: $pattern)" >> "$LOG_FILE"
    output_result "false" "Dangerous command blocked: pattern detected"
    exit 0
  fi
done

# ALLOW list - commands that are always safe
ALLOW_PATTERNS=(
  '^echo\s'
  '^printf\s'
  '^pwd'
  '^ls'
  '^cd\s'
  '^cat\s'
  '^head\s'
  '^tail\s'
  '^grep'
  '^sed\s'
  '^awk\s'
  '^sort'
  '^uniq'
  '^wc\s'
  '^find\s'
  '^tree'
  '^du\s'
  '^df'
  '^date'
  '^whoami'
  '^hostname'
  '^env'
  '^which\s'
  '^man\s'
  '^curl\s'
  '^wget\s'
  '^git\s'
  '^npm\s'
  '^python\s'
  '^pip\s'
  '^node\s'
  '^npx\s'
  '^yarn\s'
  '^docker\s'
  '^docker-compose\s'
  '^composer\s'
  '^bundle\s'
  '^go\s'
  '^cargo\s'
  '^rustc\s'
  '^gcc\s'
  '^make'
  '^cmake'
  '^gcc\s'
  '^clang'
  '^java\s'
  '^javac'
  '^mvn\s'
  '^gradle\s'
  '^sqlplus'
  '^psql'
  '^mysql'
  '^mongosh'
  '^redis-cli'
  '^sqlite3'
  '^ollama'
  '^curl.*ollama'
)

# Check if command is in allow list
for pattern in "${ALLOW_PATTERNS[@]}"; do
  if [[ "$COMMAND" =~ $pattern ]]; then
    echo "$TIMESTAMP ALLOW: $COMMAND (matched allow pattern: $pattern)" >> "$LOG_FILE"
    output_result "true" "Safe command allowed"
    exit 0
  fi
done

# HIGH-RISK operations - DENY unless explicitly whitelisted
RISKY_PATTERNS=(
  'sudo\s'
  'su\s+'
  'chmod\s+[0-7]{3,4}\s+/'
  'chown\s'
  'useradd'
  'userdel'
  'usermod'
  'passwd\s'
  'groupadd'
  'groupdel'
  'curl.*-X.*POST'
  'curl.*-X.*DELETE'
  'curl.*-X.*PUT'
  'wget.*--spider'
  'kill\s+-9'
  'killall\s'
  'pkill\s'
  'systemctl\s+start'
  'systemctl\s+stop'
  'systemctl\s+restart'
  'service\s'
  'init\.d'
  'apt-get\s+install'
  'apt-get\s+remove'
  'yum\s+install'
  'yum\s+remove'
  'brew\s+install'
  'brew\s+uninstall'
  'pip\s+install'
  'npm\s+install\s+-g'
  'docker\s+run.*-it'
  'docker\s+exec'
  'docker\s+ps'
  'docker\s+stop'
  'docker\s+rm'
  'eval\s+'
  'exec\s+'
  'source\s+/.*\.sh'
  '>\s*/dev/sda'
  'dd\s+'
)

for pattern in "${RISKY_PATTERNS[@]}"; do
  if [[ "$COMMAND" =~ $pattern ]]; then
    echo "$TIMESTAMP RISKY: $COMMAND (matched risky pattern: $pattern)" >> "$LOG_FILE"
    output_result "false" "High-risk command blocked: requires explicit allowance"
    exit 0
  fi
done

# SUSPICIOUS patterns - DENY by default
SUSPICIOUS_PATTERNS=(
  '\$\(.*\$\('
  '`.*`'
  '>\s*&'
  '>&\s*2'
  '>.*2>&1'
  'nc\s+'
  'ncat\s+'
  'netcat'
  'socat\s+'
  'telnet\s+'
  'ssh\s+'
  'scp\s+'
  'sftp\s+'
  'tar\s+.*--restore-times'
  'tar\s+.*--mode='
  'unzip\s+-o'
  'rar\s+x'
  '|.*base64'
  '|.*rot13'
  'xxd\s+'
  'od\s+-A\s+x'
  'hexdump'
)

for pattern in "${SUSPICIOUS_PATTERNS[@]}"; do
  if [[ "$COMMAND" =~ $pattern ]]; then
    echo "$TIMESTAMP SUSPICIOUS: $COMMAND (matched suspicious pattern: $pattern)" >> "$LOG_FILE"
    output_result "false" "Suspicious command blocked: possible obfuscation or redirection"
    exit 0
  fi
done

# Commands with pipes and redirection - ALLOW if safe
if [[ "$COMMAND" =~ \| ]] || [[ "$COMMAND" =~ '>' ]]; then
  # Redirection check: ensure not redirecting to system files
  if [[ "$COMMAND" =~ '>.*(/etc/|/sys/|/proc/|/dev/|/boot/|/root/)' ]]; then
    echo "$TIMESTAMP DENY: $COMMAND (redirection to system directory)" >> "$LOG_FILE"
    output_result "false" "Redirection to protected directory blocked"
    exit 0
  fi

  # Allow if all parts are safe
  IFS='|' read -ra PARTS <<< "$COMMAND"
  for PART in "${PARTS[@]}"; do
    PART="${PART// /}"
    PART="${PART%% *}"  # Get first word
    if [[ "$PART" =~ ^(curl|wget|grep|sed|awk|sort|uniq|head|tail|wc|jq|python|node) ]]; then
      continue
    else
      echo "$TIMESTAMP SUSPICIOUS_PIPE: $COMMAND (unsafe part: $PART)" >> "$LOG_FILE"
      output_result "false" "Suspicious pipe detected: unsafe component"
      exit 0
    fi
  done

  echo "$TIMESTAMP ALLOW_PIPED: $COMMAND" >> "$LOG_FILE"
  output_result "true" "Piped command allowed (all components safe)"
  exit 0
fi

# Default: DENY (fail-closed)
echo "$TIMESTAMP DENY_DEFAULT: $COMMAND (no matching rule)" >> "$LOG_FILE"
output_result "false" "Command not explicitly allowed"
exit 0
