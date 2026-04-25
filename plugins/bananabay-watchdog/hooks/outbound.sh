#!/bin/bash
# bananabay-watchdog — outbound hook.
# Fires on PostToolUse matching mcp__telegram__reply (and any other channel
# reply tool added by future configurations). Writes the v1 outbound format
# ("1 <unix_ts>\n") atomically to $WATCHDOG_OUTBOUND_FILE.
#
# Must exit 0 always — hook failure MUST NOT block Claude Code.

set +e

[ -f "$HOME/.claude/watchdog/config.env" ] && . "$HOME/.claude/watchdog/config.env"
F="${WATCHDOG_OUTBOUND_FILE:-$HOME/.claude/watchdog/outbound}"

mkdir -p "$(dirname "$F")" 2>/dev/null

TMP="$F.tmp"
printf '1 %d\n' "$(date +%s)" > "$TMP" 2>/dev/null && mv -f "$TMP" "$F" 2>/dev/null

exit 0
