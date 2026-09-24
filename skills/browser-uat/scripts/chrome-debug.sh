#!/bin/bash
# chrome-debug.sh — Launch Chrome with a specific profile and debugging port
#
# Usage: chrome-debug <profile-name> [port]
#
# Examples:
#   chrome-debug work           # Launch work profile on port 9222
#   chrome-debug personal 9223  # Launch personal profile on port 9223
#   chrome-debug --list         # List available profiles
#
# Profiles are defined in: ~/.claude/skills/browser-uat/configs/profiles.json

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/../configs/profiles.json"
CHROME_PATH="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
CHROME_DATA_BASE="$HOME/Library/Application Support/Google/Chrome"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Check dependencies
if ! command -v jq &>/dev/null; then
    echo -e "${RED}Error:${NC} jq is required. Install with: brew install jq"
    exit 1
fi

if [ ! -f "$CONFIG_FILE" ]; then
    echo -e "${RED}Error:${NC} Config file not found: $CONFIG_FILE"
    exit 1
fi

if [ ! -f "$CHROME_PATH" ]; then
    echo -e "${RED}Error:${NC} Google Chrome not found at: $CHROME_PATH"
    exit 1
fi

# List profiles
if [ "${1:-}" = "--list" ] || [ "${1:-}" = "-l" ]; then
    echo "Available profiles:"
    jq -r 'to_entries[] | "  \(.key) — port \(.value.port) — \(.value.description // .value.baseUrl)"' "$CONFIG_FILE"
    exit 0
fi

# Get profile name
PROFILE_NAME="${1:-}"
if [ -z "$PROFILE_NAME" ]; then
    echo "Usage: chrome-debug <profile-name> [port]"
    echo ""
    echo "Available profiles:"
    jq -r 'to_entries[] | "  \(.key) — port \(.value.port) — \(.value.description // .value.baseUrl)"' "$CONFIG_FILE"
    exit 1
fi

# Read profile config
PROFILE_DATA=$(jq -r --arg p "$PROFILE_NAME" '.[$p] // empty' "$CONFIG_FILE")
if [ -z "$PROFILE_DATA" ]; then
    echo -e "${RED}Error:${NC} Profile '$PROFILE_NAME' not found in $CONFIG_FILE"
    echo ""
    echo "Available profiles:"
    jq -r 'to_entries[] | "  \(.key)"' "$CONFIG_FILE"
    exit 1
fi

DATA_DIR=$(echo "$PROFILE_DATA" | jq -r '.dataDir')
DEFAULT_PORT=$(echo "$PROFILE_DATA" | jq -r '.port')
DEBUG_PORT="${2:-$DEFAULT_PORT}"

FULL_DATA_DIR="$CHROME_DATA_BASE/$DATA_DIR"

# Verify profile directory exists
if [ ! -d "$FULL_DATA_DIR" ]; then
    echo -e "${YELLOW}Warning:${NC} Chrome profile directory not found: $FULL_DATA_DIR"
    echo ""
    echo "Available Chrome profiles:"
    ls -1 "$CHROME_DATA_BASE" | grep -E "^(Default|Profile)" | while read -r d; do
        echo "  $d"
    done
    echo ""
    echo "Update dataDir in $CONFIG_FILE to match one of these."
    exit 1
fi

# Check if port is already in use
if lsof -ti:"$DEBUG_PORT" &>/dev/null; then
    echo -e "${YELLOW}Port $DEBUG_PORT already in use.${NC}"
    echo ""
    # Check if it's Chrome
    if lsof -ti:"$DEBUG_PORT" | xargs ps -p 2>/dev/null | grep -q "Chrome"; then
        echo -e "${GREEN}Chrome is already running on port $DEBUG_PORT.${NC}"
        echo "CDP URL: http://localhost:$DEBUG_PORT"
    else
        echo "Another process is using this port. Kill it or use a different port."
        lsof -i:"$DEBUG_PORT" | head -5
    fi
    exit 0
fi

# Launch Chrome
echo -e "Launching Chrome profile ${GREEN}$PROFILE_NAME${NC} on port ${GREEN}$DEBUG_PORT${NC}..."

"$CHROME_PATH" \
    --user-data-dir="$FULL_DATA_DIR" \
    --remote-debugging-port="$DEBUG_PORT" \
    --no-first-run \
    --no-default-browser-check \
    &>/dev/null &

CHROME_PID=$!

# Wait for Chrome to start
sleep 2

if kill -0 "$CHROME_PID" 2>/dev/null; then
    echo -e "${GREEN}Chrome launched successfully${NC}"
    echo ""
    echo "  Profile:  $PROFILE_NAME ($DATA_DIR)"
    echo "  CDP URL:  http://localhost:$DEBUG_PORT"
    echo "  PID:      $CHROME_PID"
    echo ""
    echo "To verify: node ~/.claude/skills/browser-uat/scripts/check-connection.js $DEBUG_PORT"
else
    echo -e "${RED}Chrome failed to start.${NC}"
    echo "Try launching Chrome manually and check for errors."
    exit 1
fi
