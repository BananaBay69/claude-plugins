---
description: Install claude-watchdog CLI on this machine
---

# Install claude-watchdog CLI

The user wants to install (or reinstall) the claude-code-watchdog CLI.

## Steps

1. **Precheck** — run `bash ~/bin/claude-watchdog.sh --version 2>/dev/null || echo "not installed"`.
   - If it prints a version, confirm with the user: "CLI is already installed at v<X>. Reinstall anyway?" Proceed only on yes.

2. **Install** — run:

   ```bash
   curl -fsSL https://raw.githubusercontent.com/BananaBay69/claude-code-watchdog/main/install.sh | bash
   ```

3. **Verify**:
   - `bash ~/bin/claude-watchdog.sh --version` — expect non-empty
   - `launchctl list | grep claude-watchdog` — expect a line with status 0
   - `cat ~/.claude/watchdog/config.env` — expect `WATCHDOG_HEARTBEAT_FILE=` line (v0.1.1+)

4. **Report** a table with installed version, plist status, and heartbeat path. If any verification fails, include the failing command's output and suggest running `/bananabay-watchdog:status` for more detail.

## Errors

- `curl` fails → network issue or GitHub outage. Report and suggest manual clone + `bash install.sh`.
- Missing `launchctl` output → launchd agent didn't bootstrap. Suggest `launchctl bootstrap gui/$UID ~/Library/LaunchAgents/com.openclaw.claude-watchdog.plist`.
