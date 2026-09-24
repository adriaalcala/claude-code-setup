#!/usr/bin/env bash
# bash-guard.sh - PreToolUse hook that blocks destructive shell commands.
#
# Event:  PreToolUse, matcher "Bash"
# Input:  JSON on stdin, .tool_input.command holds the command
# Output: a PreToolUse permissionDecision, or nothing at all
#
# Policy, in order:
#   1. Destructive patterns       -> deny
#   2. High-impact patterns       -> ask (user confirms in the dialog)
#   3. BASH_GUARD_STRICT=1        -> deny anything not on the allow list
#   4. Otherwise                  -> no decision, normal permission flow applies
#
# Strict mode reproduces a deny-by-default allow list. It is off by default
# because it denies ordinary commands such as mkdir, cp and mv.

set -euo pipefail

HOOK_NAME="bash-guard"
# shellcheck source=hooks/scripts/lib/hook-common.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib/hook-common.sh"

hook_init

TOOL_NAME="$(hook_field '.tool_name')"
COMMAND="$(hook_field '.tool_input.command')"

# Only Bash-like tools carry a command. Anything else is none of our business.
case "$TOOL_NAME" in
  Bash | PowerShell) ;;
  *) hook_pass ;;
esac

# A Bash call with no command means the event did not look the way we expect.
if [ -z "$COMMAND" ]; then
  hook_deny "bash-guard: the Bash event carried no command, so it could not be inspected. Blocking (fail-closed)."
fi

# --- 1. destructive: always deny --------------------------------------------
# shellcheck disable=SC2016  # these are regexes; $HOME is matched literally
DESTRUCTIVE_PATTERNS=(
  'rm[[:space:]]+(-[[:alnum:]]*[[:space:]]+)*-?[[:alnum:]]*[rR][[:alnum:]]*[[:space:]]+/[[:space:]]*$'
  'rm([[:space:]]+-[[:alnum:]-]+)*[[:space:]]+-[[:alnum:]-]*[rR][[:alnum:]-]*([[:space:]]+-[[:alnum:]-]+)*[[:space:]]+(/|\*|~|\$HOME)([[:space:]]|$)'
  'rm([[:space:]]+-[[:alnum:]-]+)*[[:space:]]+--no-preserve-root'
  'dd[[:space:]]+.*of=/dev/(sd|nvme|disk|hd)'
  'dd[[:space:]]+if=/dev/(zero|random|urandom)[[:space:]]+of=/'
  '(^|[^[:alnum:]_-])mkfs(\.[[:alnum:]]+)?([^[:alnum:]_-]|$)'
  '(^|[^[:alnum:]_-])(fdisk|parted|dmsetup|cryptsetup)([^[:alnum:]_-]|$)'
  '(^|[;&|][[:space:]]*)[[:space:]]*(sudo[[:space:]]+)?(shutdown|reboot|poweroff|halt)([[:space:]]|$)'
  'systemctl[[:space:]]+(poweroff|reboot|halt)'
  'chmod[[:space:]]+(-[[:alnum:]]+[[:space:]]+)*777[[:space:]]+/[[:space:]]*$'
  'chown[[:space:]]+(-[[:alnum:]]+[[:space:]]+)*[^[:space:]]+[[:space:]]+/[[:space:]]*$'
  '>[[:space:]]*/etc/(passwd|shadow|sudoers)'
  '\|[[:space:]]*(sudo[[:space:]]+(-[^[:space:]]+[[:space:]]+)*)?(ba|z|k|da)?sh([[:space:]]|$)'
  '(^|[^[:alnum:]_-])(ba|z|k|da)?sh[[:space:]]+<\('
  ':\(\)[[:space:]]*\{.*\|.*&.*\};:'
  'git[[:space:]]+push[[:space:]]+.*--force(-with-lease)?[[:space:]]+[^[:space:]]+[[:space:]]+(main|master)([^[:alnum:]_/-]|$)'
  '(^|[;&|][[:space:]]*)[[:space:]]*history[[:space:]]+-c([[:space:]]|$)'
)

if hook_matches_any "$COMMAND" "${DESTRUCTIVE_PATTERNS[@]}"; then
  hook_deny "bash-guard: destructive command blocked (matched /${HOOK_MATCHED_PATTERN}/). If this is genuinely intended, run it yourself outside Claude Code."
fi

# --- 2. high impact: ask ------------------------------------------------------
# These are legitimate often enough that denying them outright is wrong, but
# they change the machine or reach the network, so the user should see them.
HIGH_IMPACT_PATTERNS=(
  '(^|[;&|][[:space:]]*)sudo[[:space:]]'
  '(^|[;&|][[:space:]]*)(su|doas|pkexec)[[:space:]]'
  '(^|[^[:alnum:]_-])(useradd|userdel|usermod|groupadd|groupdel|passwd)[[:space:]]'
  'systemctl[[:space:]]+(start|stop|restart|enable|disable)'
  '(^|[^[:alnum:]_-])(launchctl|service)[[:space:]]'
  '(apt|apt-get|yum|dnf|pacman)[[:space:]]+(install|remove|purge)'
  'brew[[:space:]]+(install|uninstall|remove)'
  'npm[[:space:]]+install[[:space:]]+(-g|--global)'
  '(^|[^[:alnum:]_-])(kill|killall|pkill)[[:space:]]+(-9|-KILL)'
  'docker[[:space:]]+(system[[:space:]]+prune|volume[[:space:]]+rm|rm[[:space:]]+-f)'
  '(^|[;&|][[:space:]]*)[[:space:]]*(nc|ncat|netcat|socat|telnet)[[:space:]]'
  'crontab[[:space:]]+-'
  '(^|[^[:alnum:]_-])chmod[[:space:]]+(-[[:alnum:]]+[[:space:]]+)*777([^[:digit:]]|$)'
  '(^|[^[:alnum:]_-])git[[:space:]]+(reset[[:space:]]+--hard|clean[[:space:]]+-[[:alnum:]]*[fd])'
  '(^|[^[:alnum:]_-])git[[:space:]]+push[[:space:]]+.*--force'
  '>[[:space:]]*/dev/(sd|nvme|disk)'
)

if hook_matches_any "$COMMAND" "${HIGH_IMPACT_PATTERNS[@]}"; then
  hook_ask "bash-guard: high-impact command (matched /${HOOK_MATCHED_PATTERN}/). Review it before allowing."
fi

# --- 3. optional strict mode -------------------------------------------------
if [ "${BASH_GUARD_STRICT:-0}" = "1" ]; then
  ALLOW_PATTERNS=(
    '^[[:space:]]*(echo|printf|pwd|ls|cd|cat|head|tail|less|file|stat)[[:space:]]*'
    '^[[:space:]]*(grep|rg|sed|awk|sort|uniq|wc|cut|tr|jq|yq)[[:space:]]*'
    '^[[:space:]]*(find|tree|du|df|date|whoami|hostname|env|which|type)[[:space:]]*'
    '^[[:space:]]*(mkdir|touch|cp|mv|ln|diff|tar|zip|unzip)[[:space:]]'
    '^[[:space:]]*git[[:space:]]'
    '^[[:space:]]*(npm|pnpm|yarn|npx|node)[[:space:]]'
    '^[[:space:]]*(python|python3|pip|pip3|uv|ruff|mypy|pytest|pyright)[[:space:]]'
    '^[[:space:]]*(cargo|rustc|go|make|cmake|gcc|clang|java|javac|mvn|gradle)[[:space:]]'
    '^[[:space:]]*(docker|docker-compose|kubectl)[[:space:]]'
    '^[[:space:]]*(ollama|curator)[[:space:]]*'
    '^[[:space:]]*(curl|wget|http|httpie)[[:space:]]'
    '^[[:space:]]*(psql|mysql|sqlite3|mongosh|redis-cli)[[:space:]]'
  )
  if ! hook_matches_any "$COMMAND" "${ALLOW_PATTERNS[@]}"; then
    hook_deny "bash-guard: strict mode is on and this command is not on the allow list. Unset BASH_GUARD_STRICT to fall back to the normal permission flow."
  fi
fi

# --- 4. no opinion ------------------------------------------------------------
hook_pass
