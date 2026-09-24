#!/usr/bin/env bash
# git-branch-guard.sh - PreToolUse hook that stops commits and pushes landing
# directly on a protected branch.
#
# Event:  PreToolUse, matcher "Bash"
# Input:  JSON on stdin; .tool_input.command and .cwd
# Output: a PreToolUse permissionDecision, or nothing at all
#
# Protected branches default to main, master, develop and release/*. Override
# with GIT_PROTECTED_BRANCHES, a space-separated list of ERE patterns:
#
#   export GIT_PROTECTED_BRANCHES='^main$ ^release/'
#
# Set GIT_BRANCH_GUARD=off to disable it for a repository where trunk-based
# commits are the norm - this repository included.

set -euo pipefail

HOOK_NAME="git-branch-guard"
# shellcheck source=hooks/scripts/lib/hook-common.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib/hook-common.sh"

hook_init

[ "${GIT_BRANCH_GUARD:-on}" = "off" ] && hook_pass

TOOL_NAME="$(hook_field '.tool_name')"
[ "$TOOL_NAME" = "Bash" ] || hook_pass

COMMAND="$(hook_field '.tool_input.command')"
[ -n "$COMMAND" ] || hook_pass

# Only commits and pushes are interesting.
if ! [[ "$COMMAND" =~ git[[:space:]]+(-[^[:space:]]+[[:space:]]+)*(commit|push)([[:space:]]|$) ]]; then
  hook_pass
fi

CWD="$(hook_field '.cwd')"
[ -n "$CWD" ] && [ -d "$CWD" ] && cd "$CWD"

command -v git >/dev/null 2>&1 || hook_pass "git not installed"
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || hook_pass "not a git repository"

# Which branch does this command actually land on?
TARGET=""
if [[ "$COMMAND" =~ git[[:space:]]+(-[^[:space:]]+[[:space:]]+)*push([[:space:]]|$) ]]; then
  # `git push <remote> <refspec>` - take the refspec's destination if present.
  REFSPEC="$(printf '%s' "$COMMAND" \
    | sed -n 's/.*git[[:space:]][[:space:]]*\(-[^[:space:]]*[[:space:]][[:space:]]*\)*push[[:space:]][[:space:]]*//p' \
    | tr ' ' '\n' | grep -v '^-' | sed -n '2p')" || REFSPEC=""
  if [ -n "$REFSPEC" ]; then
    TARGET="${REFSPEC##*:}"      # src:dst -> dst
    TARGET="${TARGET#refs/heads/}"
  fi
fi

if [ -z "$TARGET" ]; then
  TARGET="$(git branch --show-current 2>/dev/null)" || TARGET=""
fi

if [ -z "$TARGET" ]; then
  # Detached HEAD, or a refspec we could not read. Ambiguity blocks.
  hook_deny "git-branch-guard: could not determine the branch this command targets. Blocking (fail-closed). Set GIT_BRANCH_GUARD=off to bypass."
fi

read -r -a PROTECTED <<<"${GIT_PROTECTED_BRANCHES:-^main$ ^master$ ^develop$ ^release/}"

if hook_matches_any "$TARGET" "${PROTECTED[@]}"; then
  hook_deny "git-branch-guard: '$TARGET' is a protected branch. Create a feature branch first (git switch -c feature/your-change), or set GIT_BRANCH_GUARD=off for this repository."
fi

hook_pass "target branch '$TARGET' is not protected"
