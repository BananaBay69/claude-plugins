# bananabay-watchdog Plugin — Design Spec

Status: draft
Date: 2026-04-24
Tracks: [BananaBay69/claude-code-watchdog#3](https://github.com/BananaBay69/claude-code-watchdog/issues/3)
Depends on: CLI v0.1.1 (sidecar config, see §Prerequisites)

## 1. Problem

`claude-code-watchdog` v0.1.0 (shipped Phase 1, #2) ships a heartbeat-aware detection path but no writer. The CLI falls back to pane-grep heuristics, which false-positive whenever rate-limit strings legitimately appear in conversation content.

We need a Claude Code plugin that emits the heartbeat file on every `UserPromptSubmit` and `Stop` event, so the CLI has a precise in-runtime liveness signal.

## 2. Goals

- Emit heartbeat on every `UserPromptSubmit` and `Stop` event per the v1 protocol already frozen in CLI v0.1.0 (`README § Heartbeat protocol (v1)`).
- Auto-install the CLI when the plugin is added, so a single `/plugin install` command bootstraps both layers.
- Ship four slash commands (`install`, `status`, `update`, `uninstall`) covering the full lifecycle.
- Stand up a new marketplace under `BananaBay69/claude-plugins` so the plugin is installable via `/plugin install`.

## 3. Non-goals

- Running the supervisor itself. That stays in the CLI — failure-domain separation required by #1.
- Rewriting the CLI in a typed language.
- Windows / Linux support (the CLI is macOS-only).
- Competing with `install.sh`. The plugin's install command is a convenience wrapper that curls+execs the existing installer.

## 4. Prerequisites — CLI v0.1.1 sidecar config

### Why

Users who run `install.sh --heartbeat-file /custom/path` get `WATCHDOG_HEARTBEAT_FILE` injected into the launchd plist's `EnvironmentVariables` block. That env is scoped to launchd-spawned processes only; Claude Code's shell does not inherit it. The plugin's `heartbeat.sh` therefore cannot discover the custom path.

### Fix

The CLI's `install.sh` writes a sidecar file at install time:

```bash
# install.sh (v0.1.1 patch)
cat > "$HOME/.claude/watchdog/config.env" <<EOF
WATCHDOG_HEARTBEAT_FILE=$HEARTBEAT_FILE
EOF
```

The plugin's `heartbeat.sh` sources it:

```bash
[ -f "$HOME/.claude/watchdog/config.env" ] && . "$HOME/.claude/watchdog/config.env"
F="${WATCHDOG_HEARTBEAT_FILE:-$HOME/.claude/watchdog/heartbeat}"
```

### Order of work

1. Land CLI v0.1.1 patch (sidecar config write in `install.sh` + `uninstall.sh` removal).
2. Then build plugin v0.1.0, which requires v0.1.1 for custom-path support.

If a user is on CLI v0.1.0 when installing the plugin, `config.env` won't exist and `heartbeat.sh` falls back to the default path silently. This breaks only the custom-path scenario; default-path installs work regardless of CLI version. The plugin does not enforce a minimum CLI version — `check-cli.sh` prompts `/bananabay-watchdog:update` if a newer CLI is available, which naturally brings pre-v0.1.1 users forward.

## 5. Architecture

### Three-layer separation

```
Marketplace repo          Plugin repo                    CLI repo (existing)
BananaBay69/              BananaBay69/                   BananaBay69/
claude-plugins            claude-code-watchdog-plugin    claude-code-watchdog
└─ marketplace.json  →    └─ .claude-plugin/      ←→     └─ install.sh
                             hooks/                         claude-watchdog.sh
                             commands/                      com.openclaw.*.plist
                                                            ~/.claude/watchdog/
                                                              config.env (v0.1.1+)
                                                              heartbeat
                                                              logs/
```

Plugin never touches the CLI's files directly. It shells out to `install.sh` / `uninstall.sh` via `curl | bash` or local exec.

### Failure-domain guarantees

- Plugin failures never block Claude Code: every hook `exit 0`, errors to stderr only.
- Plugin absence never breaks CLI: CLI's heartbeat reader already handles missing / unparseable files by logging `WARN` and falling back to grep.
- CLI absence never breaks plugin hooks: `heartbeat.sh` writes to disk unconditionally; the file is simply orphan until CLI is installed.

## 6. Plugin repo layout

```
claude-code-watchdog-plugin/
├── .claude-plugin/
│   └── plugin.json
├── hooks/
│   ├── hooks.json
│   ├── check-cli.sh         # SessionStart
│   └── heartbeat.sh         # UserPromptSubmit + Stop
├── commands/
│   ├── install.md           # /bananabay-watchdog:install
│   ├── status.md            # /bananabay-watchdog:status
│   ├── update.md            # /bananabay-watchdog:update
│   └── uninstall.md         # /bananabay-watchdog:uninstall
├── test/
│   └── smoke.sh             # CI: shellcheck + dry-run install
├── .github/
│   └── workflows/
│       └── ci.yml           # shellcheck + smoke on PR
├── README.md
├── LICENSE                  # MIT, matching CLI repo
├── CHANGELOG.md
└── docs/superpowers/specs/
    └── 2026-04-24-bananabay-watchdog-plugin-design.md  (this file)
```

### `.claude-plugin/plugin.json`

```json
{
  "name": "bananabay-watchdog",
  "version": "0.1.0",
  "description": "Claude Code plugin that writes liveness heartbeats for claude-code-watchdog",
  "author": { "name": "BananaBay69" },
  "license": "MIT",
  "keywords": ["watchdog", "supervision", "heartbeat", "launchd", "macos"]
}
```

## 7. Marketplace repo layout

```
claude-plugins/
├── marketplace.json
└── README.md
```

### `marketplace.json`

```json
{
  "name": "bananabay-plugins",
  "owner": "BananaBay69",
  "plugins": [
    {
      "name": "bananabay-watchdog",
      "source": {
        "source": "git",
        "url": "https://github.com/BananaBay69/claude-code-watchdog-plugin.git"
      }
    }
  ]
}
```

Users install via:

```
/plugin marketplace add BananaBay69/claude-plugins
/plugin install bananabay-watchdog@bananabay-plugins
```

## 8. Hooks

### `hooks/hooks.json`

```json
{
  "hooks": {
    "SessionStart": [
      { "hooks": [ { "type": "command", "command": "${CLAUDE_PLUGIN_ROOT}/hooks/check-cli.sh" } ] }
    ],
    "UserPromptSubmit": [
      { "hooks": [ { "type": "command", "command": "${CLAUDE_PLUGIN_ROOT}/hooks/heartbeat.sh" } ] }
    ],
    "Stop": [
      { "hooks": [ { "type": "command", "command": "${CLAUDE_PLUGIN_ROOT}/hooks/heartbeat.sh" } ] }
    ]
  }
}
```

### `hooks/check-cli.sh` (SessionStart)

Responsibilities:

1. Locate `claude-watchdog.sh` in standard install paths (`~/bin/`, `/usr/local/bin/`, `$HOME/.local/bin/`).
2. If missing: `curl -fsSL <install-url> | bash -s --`. Log one status line on success/failure.
3. If present: compare `$CLI --version` to `https://api.github.com/repos/BananaBay69/claude-code-watchdog/releases/latest`. Print `✓ claude-watchdog vX.Y.Z (latest)` or `⬆️ ... update available — run /bananabay-watchdog:update`.
4. Wrap version check in `timeout 2`; offline or rate-limited runs print `(couldn't check for updates — continuing)` and succeed.
5. Always `exit 0`.

Pseudocode:

```bash
#!/bin/bash
set +e

CLI=""
for p in "$HOME/bin/claude-watchdog.sh" /usr/local/bin/claude-watchdog.sh "$HOME/.local/bin/claude-watchdog.sh"; do
  [ -x "$p" ] && CLI="$p" && break
done

INSTALL_URL="https://raw.githubusercontent.com/BananaBay69/claude-code-watchdog/main/install.sh"

if [ -z "$CLI" ]; then
  echo "⚠️  claude-watchdog CLI not found — installing..." >&2
  if curl -fsSL "$INSTALL_URL" | bash -s -- 2>&1; then
    echo "✅ claude-watchdog installed" >&2
  else
    echo "❌ Auto-install failed. Run /bananabay-watchdog:install manually." >&2
  fi
  exit 0
fi

INSTALLED=$(timeout 2 "$CLI" --version 2>/dev/null | awk '{print $NF}')
LATEST=$(timeout 2 curl -fsSL "https://api.github.com/repos/BananaBay69/claude-code-watchdog/releases/latest" 2>/dev/null | sed -n 's/.*"tag_name": *"v\{0,1\}\([^"]*\)".*/\1/p' | head -1)

if [ -z "$LATEST" ]; then
  echo "✓ claude-watchdog v$INSTALLED (couldn't check for updates — continuing)" >&2
elif [ "$INSTALLED" = "$LATEST" ]; then
  echo "✓ claude-watchdog v$INSTALLED (latest)" >&2
else
  echo "⬆️  claude-watchdog v$INSTALLED → v$LATEST available. Run /bananabay-watchdog:update" >&2
fi

exit 0
```

### `hooks/heartbeat.sh` (UserPromptSubmit + Stop)

```bash
#!/bin/bash
set +e

[ -f "$HOME/.claude/watchdog/config.env" ] && . "$HOME/.claude/watchdog/config.env"
F="${WATCHDOG_HEARTBEAT_FILE:-$HOME/.claude/watchdog/heartbeat}"

mkdir -p "$(dirname "$F")" 2>/dev/null
printf '1 %d\n' "$(date +%s)" > "$F.tmp" 2>/dev/null && mv -f "$F.tmp" "$F" 2>/dev/null

exit 0
```

Design constraints:

- **Fast**: target < 10 ms. No network, no fork beyond `date`, no grep.
- **Atomic**: write-then-rename. Reader never observes partial content.
- **Silent**: no stdout, any failure → exit 0.
- **Env-aware**: honours `WATCHDOG_HEARTBEAT_FILE` via sidecar config.

## 9. Slash commands

Claude Code slash commands are markdown prompts, not scripts. Each command is a `.md` file telling Claude what bash to run and how to report results.

| Command | File | Behavior |
|---|---|---|
| `/bananabay-watchdog:install` | `commands/install.md` | Confirm intent → `curl -fsSL install.sh \| bash` → verify `~/bin/claude-watchdog.sh --version` → verify `launchctl list \| grep claude-watchdog` → report. |
| `/bananabay-watchdog:status` | `commands/status.md` | `tail -30 $LOG_FILE` + `launchctl list \| grep claude-watchdog` + last-restart-age + current heartbeat age. |
| `/bananabay-watchdog:update` | `commands/update.md` | Compare versions → `curl \| bash install.sh` (idempotent, reloads launchd) → report new version. |
| `/bananabay-watchdog:uninstall` | `commands/uninstall.md` | Warn user supervisor will stop → `curl -fsSL uninstall.sh \| bash` → verify plist unloaded + script deleted. |

Each markdown file includes:

- Preconditions (e.g. install requires CLI not-installed or update-needed)
- Exact bash command(s) with comments
- Success criteria (command output patterns to confirm)
- Failure handling (e.g. curl fails → fall back to instructing user to clone + run locally)

## 10. Error handling

### Principle

Hook scripts never block Claude Code. Every script ends `exit 0`; errors to stderr.

### Specific branches

| Scenario | Component | Handling |
|---|---|---|
| curl fails (offline / GH 502) on install | `check-cli.sh` | stderr warn + `exit 0`; user can retry via slash command |
| GitHub API rate limit on version check | `check-cli.sh` | print `(couldn't check for updates)`, show installed version only |
| `install.sh` fails (e.g. launchctl bootstrap error) | `check-cli.sh` | bubble `install.sh` stderr; `|| true` after pipe |
| Disk full / I/O error writing heartbeat | `heartbeat.sh` | silent `exit 0`; CLI will log `WARN: heartbeat stale` next cycle |
| Custom heartbeat path with pre-v0.1.1 CLI | `heartbeat.sh` | writes default path (silent); `check-cli.sh` prints one-time warning if no `config.env` but CLI installed |
| Concurrent Claude Code instances writing heartbeat | `heartbeat.sh` | atomic rename — last writer wins, CLI only reads timestamp |
| Plugin uninstalled via `/plugin remove` without running `/bananabay-watchdog:uninstall` first | n/a | CLI keeps running until user runs uninstall command; README notes the order |

## 11. Testing

### Automated (CI)

- `shellcheck hooks/*.sh` — style and correctness
- `test/smoke.sh` — dry-run install on an Ubuntu runner (skip launchd steps); asserts heartbeat file format

### Manual checklist (every release)

| # | Scenario | Expected |
|---|---|---|
| 1 | Fresh Mac, no CLI | SessionStart auto-installs; `launchctl list` shows agent; heartbeat fresh after first prompt |
| 2 | CLI already at latest | Prints `✓ vX.Y.Z (latest)` only |
| 3 | CLI older than latest | Prints upgrade hint; `/update` lands latest version |
| 4 | Offline (airplane mode) | No crash; prints `(couldn't check for updates)` |
| 5 | CLI installed with `--heartbeat-file /tmp/hb` | Plugin writes to `/tmp/hb`; sidecar config discovered |
| 6 | `/uninstall` run | agent gone, script deleted, heartbeat file stops updating |
| 7 | Two Claude Code instances open | Both write heartbeat without corruption (atomic rename) |

## 12. Rollout

1. **CLI v0.1.1** — PR to `BananaBay69/claude-code-watchdog` adding sidecar config write to `install.sh` and removal to `uninstall.sh`. Tag + release.
2. **Plugin repo scaffolding** — init `BananaBay69/claude-code-watchdog-plugin` with all files per §6; do not tag yet.
3. **Marketplace repo** — init `BananaBay69/claude-plugins` with `marketplace.json` and README.
4. **Local test** — push both repos (plugin + marketplace) as private, `/plugin marketplace add BananaBay69/claude-plugins`, `/plugin install bananabay-watchdog@bananabay-plugins`, run checklist items 1–7. If Claude Code supports local git URLs, a bare local clone can be used instead to iterate without pushing intermediate commits.
5. **Tag plugin v0.1.0**, push marketplace.
6. **Dogfood on Mac Mini** — `/bananabay-watchdog:uninstall` the current launchd setup → reinstall via plugin → observe 24–48 h.
7. **Close #3**, open follow-ups for v0.2.0 features as discovered.

## 13. Open questions (deferred)

- `/bananabay-watchdog:status` scope beyond §9's four items: should it also surface restart count over last 24 h, highlight most recent `WARN` line, or parse heartbeat file content? — deferring to implementation; §9 defines the MVP.
- Should the plugin support a diagnostic subcommand that dumps effective config (plist env, sidecar env, current heartbeat contents) into one place for bug reports? — v0.2.0 candidate.
- Is there value in a Linux build of the CLI to pair with the plugin? — out of scope for v0.1.0; the plugin is macOS-only per the CLI.

## 14. Appendix — contract references

- Heartbeat protocol v1: [CLI README § Heartbeat protocol (v1)](https://github.com/BananaBay69/claude-code-watchdog/blob/main/README.md#heartbeat-protocol-v1)
- CLI v0.1.0 release: https://github.com/BananaBay69/claude-code-watchdog/releases/tag/v0.1.0
- Issue tracking this plugin: https://github.com/BananaBay69/claude-code-watchdog/issues/3
- Reference plugin pattern (auto-install): `~/.claude/plugins/cache/psychquant-claude-plugins/che-ical-mcp/1.7.0/hooks/check-mcp.sh`
