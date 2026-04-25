---
description: Show claude-watchdog CLI status, recent log, and heartbeat freshness
---

# claude-watchdog status

Report current watchdog state to the user.

## Steps

1. **CLI version** — `bash ~/bin/claude-watchdog.sh --version 2>/dev/null || echo "not installed"`

2. **launchd agent** — `launchctl list | grep claude-watchdog || echo "agent not loaded"`

3. **Recent log** — `tail -30 ~/.claude/watchdog/logs/claude-watchdog.log 2>/dev/null || echo "no log"`

4. **Heartbeat freshness** — run as a single Bash invocation. The previous
   multi-line version was split into separate Bash calls by the agent runtime,
   so `TS` was unset when arithmetic ran and `AGE` printed as the full unix
   epoch. Keep this on one logical line (semicolons, not newlines):

   ```bash
   [ -f ~/.claude/watchdog/config.env ] && . ~/.claude/watchdog/config.env; F="${WATCHDOG_HEARTBEAT_FILE:-$HOME/.claude/watchdog/heartbeat}"; if [ -f "$F" ]; then read -r SCHEMA TS REST < "$F"; AGE=$(( $(date +%s) - TS )); echo "$F age=${AGE}s content='$SCHEMA $TS'"; else echo "heartbeat file not found: $F"; fi
   ```

   Heartbeat older than `WATCHDOG_HEARTBEAT_STALE_SECONDS` (default 600s) is
   `stale`; when the bot is idle this is normal and v0.1.5+ does not restart
   on stale-alone.

5. **Last restart** — `grep "ACTION: Restart complete" ~/.claude/watchdog/logs/claude-watchdog.log 2>/dev/null | tail -1 || echo "no recorded restarts"`

## Report format

Render a 4-row table: Version | Agent status | Heartbeat age | Last restart.
Follow with the tail of the log in a code block.
