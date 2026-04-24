#!/bin/bash
# bananabay-watchdog — heartbeat hook.
# Fires on UserPromptSubmit and Stop. Writes the v1 heartbeat format
# ("1 <unix_ts>\n") atomically to $WATCHDOG_HEARTBEAT_FILE.
#
# Must exit 0 always — hook failure MUST NOT block Claude Code.

set +e

[ -f "$HOME/.claude/watchdog/config.env" ] && . "$HOME/.claude/watchdog/config.env"
F="${WATCHDOG_HEARTBEAT_FILE:-$HOME/.claude/watchdog/heartbeat}"

mkdir -p "$(dirname "$F")" 2>/dev/null

TMP="$F.tmp"
printf '1 %d\n' "$(date +%s)" > "$TMP" 2>/dev/null && mv -f "$TMP" "$F" 2>/dev/null

exit 0
