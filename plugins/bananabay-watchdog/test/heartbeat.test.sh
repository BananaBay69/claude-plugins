#!/bin/bash
# Smoke test: heartbeat.sh writes a v1-format line atomically.
set -euo pipefail

SCRIPT="$(cd "$(dirname "$0")/.." && pwd)/hooks/heartbeat.sh"
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

# Test 1: default path
HOME="$TMPDIR" bash "$SCRIPT"
HB="$TMPDIR/.claude/watchdog/heartbeat"
[ -f "$HB" ] || { echo "FAIL: heartbeat not written to default path ($HB)"; exit 1; }

LINE=$(cat "$HB")
echo "$LINE" | grep -qE '^1 [0-9]+$' || { echo "FAIL: content '$LINE' does not match '1 <epoch>'"; exit 1; }

# Test 2: custom path via sidecar config
CUSTOM="$TMPDIR/custom/hb"
mkdir -p "$TMPDIR/.claude/watchdog"
echo "WATCHDOG_HEARTBEAT_FILE=$CUSTOM" > "$TMPDIR/.claude/watchdog/config.env"
HOME="$TMPDIR" bash "$SCRIPT"
[ -f "$CUSTOM" ] || { echo "FAIL: heartbeat not written to custom path ($CUSTOM)"; exit 1; }

# Test 3: no .tmp file left behind
[ -f "$HB.tmp" ] && { echo "FAIL: $HB.tmp leaked"; exit 1; }
[ -f "$CUSTOM.tmp" ] && { echo "FAIL: $CUSTOM.tmp leaked"; exit 1; }

echo "heartbeat.sh smoke test: OK"
