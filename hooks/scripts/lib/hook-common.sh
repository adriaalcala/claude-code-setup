#!/usr/bin/env bash
# hook-common.sh - Shared helpers for Claude Code hooks.
#
# Claude Code delivers a JSON event on stdin and interprets the hook's exit code
# plus stdout. See https://code.claude.com/docs/en/hooks
#
#   exit 0  -> stdout is parsed as a JSON decision object, or as plain text
#              (plain text becomes context only on SessionStart, UserPromptSubmit,
#              UserPromptExpansion and PostModelSwitch).
#   exit 2  -> blocking error. stderr is surfaced to Claude. Honoured by
#              PreToolUse, UserPromptSubmit, UserPromptExpansion and Stop;
#              ignored by PostToolUse, PostToolUseFailure and SessionStart.
#   other   -> non-blocking error. The action proceeds.
#
# Fail-closed design: hook_init blocks with exit 2 when jq is missing or the
# event cannot be parsed, so a broken hook denies rather than silently allowing.
# Hooks on events that cannot block (PostToolUse, SessionStart) must call
# hook_init_soft instead, which degrades to a silent no-op.

set -euo pipefail

HOOK_INPUT=""
HOOK_NAME="${HOOK_NAME:-$(basename "${0%.sh}")}"

# --- logging -----------------------------------------------------------------
# Logging must never break a hook, so every failure is swallowed.

hook_log_dir() {
  printf '%s' "${CLAUDE_HOOK_LOG_DIR:-${LOG_DIR:-.claude/logs}}"
}

hook_log() {
  local level="$1" message="$2" dir
  dir="$(hook_log_dir)"
  mkdir -p "$dir" 2>/dev/null || return 0
  printf '%s %s %s: %s\n' \
    "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$HOOK_NAME" "$level" "$message" \
    >>"$dir/$HOOK_NAME.log" 2>/dev/null || true
}

# --- input -------------------------------------------------------------------

# hook_fatal blocks without needing jq: the reason goes to stderr and exit 2
# tells Claude Code to stop the action.
hook_fatal() {
  local reason="$1"
  hook_log "FATAL" "$reason"
  printf '%s\n' "$reason" >&2
  exit 2
}

# hook_init reads and validates the event. Use on blocking events.
hook_init() {
  if ! command -v jq >/dev/null 2>&1; then
    hook_fatal "$HOOK_NAME: jq is not installed, so the event cannot be inspected. Blocking (fail-closed). Install jq or remove this hook from settings.json."
  fi
  HOOK_INPUT="$(cat)"
  if [ -z "$HOOK_INPUT" ]; then
    hook_fatal "$HOOK_NAME: empty hook event on stdin. Blocking (fail-closed)."
  fi
  if ! printf '%s' "$HOOK_INPUT" | jq -e . >/dev/null 2>&1; then
    hook_fatal "$HOOK_NAME: hook event on stdin is not valid JSON. Blocking (fail-closed)."
  fi
}

# hook_init_soft is the same, but exits 0 on failure. Use on events where exit 2
# is ignored anyway and blocking is not possible (PostToolUse, SessionStart, Stop
# side-effect hooks), so a missing jq degrades to a no-op instead of noise.
hook_init_soft() {
  command -v jq >/dev/null 2>&1 || { hook_log "SKIP" "jq not installed"; exit 0; }
  HOOK_INPUT="$(cat)"
  [ -n "$HOOK_INPUT" ] || { hook_log "SKIP" "empty event"; exit 0; }
  printf '%s' "$HOOK_INPUT" | jq -e . >/dev/null 2>&1 \
    || { hook_log "SKIP" "event is not valid JSON"; exit 0; }
}

# hook_field '.tool_input.command' -> value, or empty string when absent.
hook_field() {
  local path="$1" out
  out="$(printf '%s' "$HOOK_INPUT" | jq -r "${path} // empty" 2>/dev/null)" || out=""
  printf '%s' "$out"
}

# --- PreToolUse decisions ----------------------------------------------------
# permissionDecision is one of allow | deny | ask.
#   deny  - tool call is blocked, reason shown to Claude
#   ask   - user gets the permission dialog
#   allow - bypasses the permission prompt entirely; use sparingly
# Emitting nothing (hook_pass) leaves the normal permission flow untouched,
# which is what settings.json permissions are for.

hook_decision() {
  local decision="$1" reason="$2"
  jq -n --arg d "$decision" --arg r "$reason" \
    '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:$d,permissionDecisionReason:$r}}'
  exit 0
}

hook_deny() { hook_log "DENY" "$1"; hook_decision "deny" "$1"; }
hook_ask() { hook_log "ASK" "$1"; hook_decision "ask" "$1"; }
hook_allow() { hook_log "ALLOW" "$1"; hook_decision "allow" "$1"; }

# hook_pass emits no decision: the tool call follows the normal permission flow.
# The note argument is optional and is only written to the log.
# shellcheck disable=SC2120  # callers legitimately pass no argument
hook_pass() {
  [ "$#" -eq 0 ] || hook_log "PASS" "$1"
  exit 0
}

# --- context output ----------------------------------------------------------
# additionalContext is text Claude sees. Valid on PostToolUse and SessionStart.

hook_context() {
  local event="$1" context="$2"
  jq -n --arg e "$event" --arg c "$context" \
    '{hookSpecificOutput:{hookEventName:$e,additionalContext:$c}}'
  exit 0
}

# --- helpers -----------------------------------------------------------------

# On a match, the pattern that matched is left here for the caller's message.
# shellcheck disable=SC2034  # read by the scripts that source this file
HOOK_MATCHED_PATTERN=""

# hook_matches_any <subject> <pattern>... - POSIX ERE, case-sensitive.
#
# Note on portability: bash [[ =~ ]] compiles POSIX ERE through the platform's
# regcomp. \s, \d and \b are GNU extensions and silently fail to match on
# macOS and other BSD libc systems. Every pattern list in this repository uses
# [[:space:]], [[:digit:]] and explicit boundaries instead. The test suite
# covers this: a pattern that quietly stops matching is a guard that quietly
# stops guarding.
hook_matches_any() {
  local subject="$1" pattern
  shift
  for pattern in "$@"; do
    if [[ "$subject" =~ $pattern ]]; then
      # shellcheck disable=SC2034  # read by the scripts that source this file
      HOOK_MATCHED_PATTERN="$pattern"
      return 0
    fi
  done
  return 1
}
