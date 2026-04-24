# bananabay-watchdog

Claude Code plugin that emits heartbeat signals for [`claude-code-watchdog`](https://github.com/BananaBay69/claude-code-watchdog) — the macOS out-of-band supervisor.

## What it does

Writes a heartbeat file on every `UserPromptSubmit` and `Stop` event. The watchdog CLI reads this file to distinguish "Claude is actively working" from "Claude is stuck on a modal dialog", replacing the noisier pane-grep heuristic.

Also ships four slash commands covering the full CLI lifecycle.

## Install

```
/plugin marketplace add BananaBay69/claude-plugins
/plugin install bananabay-watchdog@bananabay-plugins
```

The plugin auto-installs the CLI on first SessionStart if it's not already on the system. No manual steps required for the default install.

## Slash commands

| Command | Effect |
|---|---|
| `/bananabay-watchdog:install` | Install (or reinstall) the CLI |
| `/bananabay-watchdog:status` | Report CLI version, launchd status, heartbeat freshness, last restart |
| `/bananabay-watchdog:update` | Upgrade the CLI to the latest release |
| `/bananabay-watchdog:uninstall` | Remove the CLI (plugin itself removed via `/plugin remove`) |

## Requirements

- macOS (launchd)
- `claude-watchdog` CLI v0.1.1 or later for custom `--heartbeat-file` paths to work. v0.1.0 is supported for default-path installs.

## Contract

Heartbeat format v1 — a single line:

```
1 <unix_timestamp>
```

Written atomically (tmp + mv). Full spec: [CLI README § Heartbeat protocol (v1)](https://github.com/BananaBay69/claude-code-watchdog/blob/main/README.md#heartbeat-protocol-v1).

## Development

```bash
shellcheck --severity=warning hooks/*.sh test/*.sh
bash test/heartbeat.test.sh
bash test/check-cli.test.sh
```

## License

MIT
