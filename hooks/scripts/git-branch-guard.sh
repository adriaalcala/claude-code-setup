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

command -v git >/dev/null 2>&1 || hook_pass "git not installed"

CWD="$(hook_field '.cwd')"
read -r -a PROTECTED <<<"${GIT_PROTECTED_BRANCHES:-^main$ ^master$ ^develop$ ^release/}"

# Each segment of a compound command is inspected on its own, so that a push
# hidden behind && is seen and `git log --grep=push` is not mistaken for one.
while IFS= read -r SEGMENT; do
  [ -n "$SEGMENT" ] || continue
  hook_git_parse "$SEGMENT" || continue

  case "$HOOK_GIT_SUBCOMMAND" in
    commit | push) ;;
    *) continue ;;
  esac

  # `git -C <path>` runs against a different repository than .cwd.
  REPO_DIR="${HOOK_GIT_DIR:-$CWD}"
  [ -n "$REPO_DIR" ] && [ -d "$REPO_DIR" ] || REPO_DIR="$CWD"
  [ -n "$REPO_DIR" ] && [ -d "$REPO_DIR" ] && cd "$REPO_DIR"

  git rev-parse --is-inside-work-tree >/dev/null 2>&1 || continue

  # Which branch does this land on?
  TARGET=""
  if [ "$HOOK_GIT_SUBCOMMAND" = "push" ]; then
    # `git push <remote> <refspec>` - the second positional argument.
    POSITIONAL=0
    for ARG in $HOOK_GIT_REST; do
      case "$ARG" in
        -*) continue ;;
      esac
      POSITIONAL=$((POSITIONAL + 1))
      if [ "$POSITIONAL" -eq 2 ]; then
        TARGET="${ARG##*:}" # src:dst -> dst
        TARGET="${TARGET#refs/heads/}"
        break
      fi
    done
  fi

  if [ -z "$TARGET" ]; then
    TARGET="$(git branch --show-current 2>/dev/null)" || TARGET=""
  fi

  if [ -z "$TARGET" ]; then
    # Detached HEAD, or a refspec we could not read. Ambiguity blocks.
    hook_deny "git-branch-guard: could not determine the branch '$HOOK_GIT_SUBCOMMAND' targets. Blocking (fail-closed). Set GIT_BRANCH_GUARD=off to bypass."
  fi

  if hook_matches_any "$TARGET" "${PROTECTED[@]}"; then
    hook_deny "git-branch-guard: '$TARGET' is a protected branch. Create a feature branch first (git switch -c feature/your-change), or set GIT_BRANCH_GUARD=off for this repository."
  fi
done <<<"$(hook_command_segments "$COMMAND")"

hook_pass "no segment targets a protected branch"
