#!/usr/bin/env bash
# run-tests.sh - Feed recorded Claude Code hook events to the hooks and assert
# on the exit code and the decision they emit.
#
# Usage: tests/hooks/run-tests.sh [-v]
#
# Each case asserts two things:
#   exit code    - 0 (decision or no-op) or 2 (fail-closed block)
#   decision     - deny | ask | allow | none, read back out of stdout
#
# Fixtures carry a __CWD__ placeholder. The runner substitutes a throwaway git
# repository so the git-aware hooks have real state to inspect, which keeps the
# results the same on a laptop and in CI.

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
HOOKS="$REPO_ROOT/hooks/scripts"
FIXTURES="$REPO_ROOT/tests/hooks/fixtures"
VERBOSE="${1:-}"

PASS=0
FAIL=0
FAILURES=()

command -v jq >/dev/null 2>&1 || { echo "jq is required to run these tests"; exit 1; }

# --- sandbox ------------------------------------------------------------------
SANDBOX="$(mktemp -d)"
export CLAUDE_HOOK_LOG_DIR="$SANDBOX/logs"
export WORK_LOG_DIR="$SANDBOX/work-log"
export COST_TRACKER_CSV="$SANDBOX/cost.csv"
# shellcheck disable=SC2317,SC2329  # invoked through the EXIT trap below
cleanup() { rm -rf "$SANDBOX"; }
trap cleanup EXIT

git init -q "$SANDBOX/repo"
(
  cd "$SANDBOX/repo" || exit 1
  git config user.email "test@example.com"
  git config user.name "Test"
  git symbolic-ref HEAD refs/heads/main
  mkdir -p src
  echo "x = 1" >src/utils.py
  git add -A
  git commit -q -m "initial"
) >/dev/null 2>&1
REPO="$SANDBOX/repo"

# --- helpers ------------------------------------------------------------------

# event <fixture> - print the fixture with __CWD__ resolved.
event() {
  sed "s|__CWD__|$REPO|g" "$FIXTURES/$1"
}

# decision_of <stdout> - deny | ask | allow | none
decision_of() {
  local out="$1"
  [ -z "$out" ] && { printf 'none'; return; }
  local d
  d="$(printf '%s' "$out" | jq -r '.hookSpecificOutput.permissionDecision // empty' 2>/dev/null)"
  [ -n "$d" ] && { printf '%s' "$d"; return; }
  printf 'none'
}

# check <name> <hook> <fixture> <expected_exit> <expected_decision> [env assignments...]
check() {
  local name="$1" hook="$2" fixture="$3" want_exit="$4" want_decision="$5"
  shift 5

  if [ ! -f "$FIXTURES/$fixture" ]; then
    FAIL=$((FAIL + 1))
    FAILURES+=("$name")
    printf '  \033[31mFAIL\033[0m  %-46s missing fixture: %s\n' "$name" "$fixture"
    printf '        is it tracked? git check-ignore -v tests/hooks/fixtures/%s\n' "$fixture"
    return
  fi

  local out rc got_decision
  if [ "$#" -gt 0 ]; then
    out="$(event "$fixture" | env "$@" bash "$HOOKS/$hook" 2>"$SANDBOX/stderr")"
  else
    out="$(event "$fixture" | bash "$HOOKS/$hook" 2>"$SANDBOX/stderr")"
  fi
  rc=$?
  got_decision="$(decision_of "$out")"

  if [ "$rc" = "$want_exit" ] && [ "$got_decision" = "$want_decision" ]; then
    PASS=$((PASS + 1))
    printf '  \033[32mPASS\033[0m  %-46s exit=%s decision=%s\n' "$name" "$rc" "$got_decision"
    if [ "$VERBOSE" = "-v" ] && [ -n "$out" ]; then
      printf '        %s\n' "$(printf '%s' "$out" | jq -c . 2>/dev/null || printf '%s' "$out")"
    fi
  else
    FAIL=$((FAIL + 1))
    FAILURES+=("$name")
    printf '  \033[31mFAIL\033[0m  %-46s expected exit=%s decision=%s, got exit=%s decision=%s\n' \
      "$name" "$want_exit" "$want_decision" "$rc" "$got_decision"
    [ -s "$SANDBOX/stderr" ] && printf '        stderr: %s\n' "$(head -2 "$SANDBOX/stderr")"
    [ -n "$out" ] && printf '        stdout: %s\n' "$(printf '%s' "$out" | head -c 300)"
  fi
}

# check_event_name <name> <hook> <fixture> <expected hookEventName>
check_event_name() {
  local name="$1" hook="$2" fixture="$3" want="$4"
  if [ ! -f "$FIXTURES/$fixture" ]; then
    FAIL=$((FAIL + 1))
    FAILURES+=("$name")
    printf '  \033[31mFAIL\033[0m  %-46s missing fixture: %s\n' "$name" "$fixture"
    return
  fi
  local out rc got
  out="$(event "$fixture" | bash "$HOOKS/$hook" 2>/dev/null)"
  rc=$?
  got="$(printf '%s' "$out" | jq -r '.hookSpecificOutput.hookEventName // empty' 2>/dev/null)"
  if [ "$rc" = "0" ] && [ "$got" = "$want" ]; then
    PASS=$((PASS + 1))
    printf '  \033[32mPASS\033[0m  %-46s hookEventName=%s\n' "$name" "$got"
  else
    FAIL=$((FAIL + 1))
    FAILURES+=("$name")
    printf '  \033[31mFAIL\033[0m  %-46s expected hookEventName=%s, got exit=%s name=%s\n' \
      "$name" "$want" "$rc" "${got:-<none>}"
  fi
}

echo "Hook contract tests"
echo "sandbox: $SANDBOX"
echo

echo "bash-guard (PreToolUse / Bash)"
check "destructive rm -rf / is denied"      bash-guard.sh bash-dangerous-rm.json  0 deny
check "curl piped into sh is denied"        bash-guard.sh bash-curl-pipe-sh.json  0 deny
check "rm with separated -r -f is denied"   bash-guard.sh bash-rm-split-flags.json 0 deny
check "base64 decoded into bash is denied"  bash-guard.sh bash-base64-pipe-shell.json 0 deny
check "piping into grep sh is not a shell"  bash-guard.sh bash-pipe-grep-sh.json  0 none
check "sudo apt-get install asks"           bash-guard.sh bash-sudo-install.json  0 ask 
check "ordinary ls passes through"          bash-guard.sh bash-safe-ls.json       0 none
check "unlisted command passes by default"  bash-guard.sh bash-unlisted-command.json 0 none
check "strict mode denies unlisted command" bash-guard.sh bash-unlisted-command.json 0 deny BASH_GUARD_STRICT=1
check "strict mode still allows git"        bash-guard.sh git-status.json           0 none BASH_GUARD_STRICT=1
check "malformed event blocks fail-closed"  bash-guard.sh malformed.json          2 none
echo

echo "write-guard (PreToolUse / Write|Edit)"
check "literal AWS key is denied"           write-guard.sh write-secret-file.json          0 deny
check "hardcoded password is denied"        write-guard.sh write-hardcoded-password.json   0 deny
check "write to /etc is denied"             write-guard.sh write-protected-path.json       0 deny
check "ordinary source file passes"         write-guard.sh write-normal-source.json        0 none
check ".env.example passes"                 write-guard.sh write-env-example.json          0 none
check "os.getenv indirection passes"        write-guard.sh write-env-from-environment.json 0 none
check "Bash event is not our business"      write-guard.sh bash-safe-ls.json               0 none
check "malformed event blocks fail-closed"  write-guard.sh malformed.json                  2 none
echo

echo "git-branch-guard (PreToolUse / Bash)"
check "push to main is denied"              git-branch-guard.sh git-push-main.json    0 deny
check "push to feature branch passes"       git-branch-guard.sh git-push-feature.json 0 none
check "git -C elsewhere push main denied"   git-branch-guard.sh git-push-main-dash-c.json 0 deny
check "push chained after && is denied"     git-branch-guard.sh git-chained-push-main.json 0 deny
check "git status is not a push"            git-branch-guard.sh git-status.json       0 none
check "git log --grep=push is not a push"   git-branch-guard.sh git-log-mentions-push.json 0 none
check "GIT_BRANCH_GUARD=off bypasses"       git-branch-guard.sh git-push-main.json    0 none GIT_BRANCH_GUARD=off
check "malformed event blocks fail-closed"  git-branch-guard.sh malformed.json        2 none
echo

echo "dependency-check (PreToolUse / Bash)"
check "install from a URL asks"             dependency-check.sh dep-install-from-url.json 0 ask
check "ordinary uv add passes"              dependency-check.sh dep-install-normal.json   0 none
check "non-install command passes"          dependency-check.sh bash-safe-ls.json         0 none
check "malformed event blocks fail-closed"  dependency-check.sh malformed.json            2 none
echo

echo "PostToolUse / SessionStart / Stop (cannot block: never exit 2)"
check "write-format exits clean"            write-format.sh posttooluse-write.json 0 none
check "write-format survives malformed"     write-format.sh malformed.json         0 none
check "cost-tracker exits clean"            cost-tracker.sh posttooluse-write.json 0 none
check "work-log ignores non-commit"         work-log-commit.sh posttooluse-write.json 0 none
check "stop hook exits clean"               stop.sh stop.json                      0 none
check "stop hook survives malformed"        stop.sh malformed.json                 0 none
check_event_name "session-start emits SessionStart context" session-start.sh sessionstart.json SessionStart
echo

echo "─────────────────────────────────────────────"
printf 'passed: %d   failed: %d\n' "$PASS" "$FAIL"
if [ "$FAIL" -gt 0 ]; then
  printf 'failing cases:\n'
  printf '  - %s\n' "${FAILURES[@]}"
  exit 1
fi
exit 0
