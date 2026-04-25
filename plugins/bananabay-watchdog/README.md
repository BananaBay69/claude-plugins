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

## Outbound state file (v0.2.0+)

The plugin writes `$WATCHDOG_OUTBOUND_FILE` (default `~/.claude/watchdog/outbound`) on every PostToolUse for `mcp__telegram__reply`. Format mirrors heartbeat:

```
1 1745700000
```

(Schema version `1`, single space, unix epoch.)

claude-watchdog v0.1.7+ uses this as the outbound signal for silent-loop detection. If you don't run claude-watchdog, the file is harmless (one tiny file, atomic writes).

To disable: not currently configurable; the hook overhead is negligible (one `printf` + `mv`).

## License

MIT
