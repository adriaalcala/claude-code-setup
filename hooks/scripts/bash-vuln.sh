#!/usr/bin/env bash
# bash-vuln.sh - PostToolUse hook that reports dependency advisories after an install.
#
# Event:  PostToolUse, matcher "Bash"
# Input:  JSON on stdin; .tool_input.command and .cwd
# Output: hookSpecificOutput.additionalContext when advisories are found, so
#         Claude sees the result and can act on it. Silent otherwise.
#
# PostToolUse cannot block - the install already happened - so this reports
# rather than denies. The audit is a network call, bounded by BASH_VULN_TIMEOUT
# (default 20s); give the hook at least that much timeout in settings.json.

set -euo pipefail

HOOK_NAME="bash-vuln"
# shellcheck source=hooks/scripts/lib/hook-common.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib/hook-common.sh"

hook_init_soft

[ "$(hook_field '.tool_name')" = "Bash" ] || exit 0

COMMAND="$(hook_field '.tool_input.command')"
[ -n "$COMMAND" ] || exit 0

INSTALL_RE='(npm[[:space:]]+(install|i|add)|yarn[[:space:]]+add|pnpm[[:space:]]+(add|install)|pip3?[[:space:]]+install|uv[[:space:]]+(add|sync))'
[[ "$COMMAND" =~ $INSTALL_RE ]] || exit 0

CWD="$(hook_field '.cwd')"
[ -n "$CWD" ] && [ -d "$CWD" ] && cd "$CWD"

TIMEOUT="${BASH_VULN_TIMEOUT:-20}"
run_bounded() {
  if command -v timeout >/dev/null 2>&1; then
    timeout "$TIMEOUT" "$@"
  elif command -v gtimeout >/dev/null 2>&1; then
    gtimeout "$TIMEOUT" "$@"
  else
    "$@"
  fi
}

REPORT=""

if [[ "$COMMAND" =~ (npm|yarn|pnpm) ]] && [ -f package.json ] && command -v npm >/dev/null 2>&1; then
  AUDIT="$(run_bounded npm audit --json 2>/dev/null)" || AUDIT=""
  if [ -n "$AUDIT" ]; then
    SUMMARY="$(printf '%s' "$AUDIT" | jq -r '
      .metadata.vulnerabilities as $v
      | [($v.critical // 0), ($v.high // 0), ($v.moderate // 0)] as $c
      | if ($c[0] + $c[1]) > 0
        then "npm audit: \($c[0]) critical, \($c[1]) high, \($c[2]) moderate"
        else empty end' 2>/dev/null)" || SUMMARY=""
    [ -n "$SUMMARY" ] && REPORT="$SUMMARY"
  fi
fi

if [ -z "$REPORT" ] && [[ "$COMMAND" =~ (pip|uv) ]] && command -v pip-audit >/dev/null 2>&1; then
  if ! run_bounded pip-audit --progress-spinner off >/dev/null 2>&1; then
    REPORT="pip-audit reports known advisories in the current environment"
  fi
fi

if [ -n "$REPORT" ]; then
  hook_log "VULN" "$REPORT"
  hook_context "PostToolUse" "Dependency advisory check after the install: $REPORT. Run the audit tool directly for the per-package detail before continuing."
fi

exit 0
