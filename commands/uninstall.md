---
description: Uninstall claude-watchdog CLI (plugin must be removed separately via /plugin remove)
---

# Uninstall claude-watchdog CLI

## Steps

1. **Warn** — supervisor will stop running after uninstall. Log files are preserved. Confirm with user before proceeding.

2. **Run uninstaller**:

   ```bash
   curl -fsSL https://raw.githubusercontent.com/BananaBay69/claude-code-watchdog/main/uninstall.sh | bash
   ```

3. **Verify**:
   - `launchctl list | grep claude-watchdog` — expect no output
   - `ls ~/bin/claude-watchdog.sh 2>/dev/null` — expect no output
   - `ls ~/.claude/watchdog/config.env 2>/dev/null` — expect no output (v0.1.1+)

4. **Remind** — plugin itself is still installed. To fully remove, user should also run `/plugin remove bananabay-watchdog` in Claude Code.

## Errors

- `launchctl unload` failure is non-fatal; uninstaller already handles it (`|| true`).
