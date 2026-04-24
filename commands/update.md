---
description: Update claude-watchdog CLI to the latest release
---

# Update claude-watchdog CLI

## Steps

1. **Current version** — `bash ~/bin/claude-watchdog.sh --version 2>/dev/null || echo "not installed"`.
   If not installed, redirect user to `/bananabay-watchdog:install`.

2. **Latest version** — `curl -fsSL https://api.github.com/repos/BananaBay69/claude-code-watchdog/releases/latest | sed -n 's/.*"tag_name": *"v\?\([^"]*\)".*/\1/p' | head -1`

3. **Confirm** — show installed vs latest. If same, stop ("already at latest"). Otherwise ask user "Update v<installed> → v<latest>?"

4. **Install** (installer is idempotent and reloads launchd):

   ```bash
   curl -fsSL https://raw.githubusercontent.com/BananaBay69/claude-code-watchdog/main/install.sh | bash
   ```

5. **Verify new version** — `bash ~/bin/claude-watchdog.sh --version`. Report success with old → new.
