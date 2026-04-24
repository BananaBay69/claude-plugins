---
description: Show claude-watchdog CLI status, recent log, and heartbeat freshness
---

# claude-watchdog status

Report current watchdog state to the user.

## Steps

1. **CLI version** — `bash ~/bin/claude-watchdog.sh --version 2>/dev/null || echo "not installed"`

2. **launchd agent** — `launchctl list | grep claude-watchdog || echo "agent not loaded"`

3. **Recent log** — `tail -30 ~/.claude/watchdog/logs/claude-watchdog.log 2>/dev/null || echo "no log"`

4. **Heartbeat freshness** — read the heartbeat file the plugin configured:
   ```bash
   [ -f ~/.claude/watchdog/config.env ] && . ~/.claude/watchdog/config.env
   F="${WATCHDOG_HEARTBEAT_FILE:-$HOME/.claude/watchdog/heartbeat}"
   if [ -f "$F" ]; then
       LINE=$(cat "$F")
       TS=$(echo "$LINE" | awk '{print $2}')
       AGE=$(($(date +%s) - TS))
       echo "$F age=${AGE}s content='$LINE'"
   else
       echo "heartbeat file not found: $F"
   fi
   ```

5. **Last restart** — `grep "ACTION: Restart complete" ~/.claude/watchdog/logs/claude-watchdog.log 2>/dev/null | tail -1 || echo "no recorded restarts"`

## Report format

Render a 4-row table: Version | Agent status | Heartbeat age | Last restart.
Follow with the tail of the log in a code block.
