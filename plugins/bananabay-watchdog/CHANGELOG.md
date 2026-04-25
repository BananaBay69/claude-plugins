# Changelog

## v0.2.0 (2026-04-26)

### Added
- `PostToolUse` hook on `mcp__telegram__reply` writing outbound timestamp to `$WATCHDOG_OUTBOUND_FILE` (default `~/.claude/watchdog/outbound`). Consumed by claude-watchdog v0.1.7+ silent-loop detection.
- `hooks/outbound.sh` script and `test/outbound.test.sh` unit test.

### Notes
- Backward-compatible: existing `UserPromptSubmit` / `Stop` heartbeat behavior unchanged.
- Outbound contract documented in README.md.

## v0.1.1 — 2026-04-25

### Fixed
- `/bananabay-watchdog:status` heartbeat-age math (#1). Multi-line bash block
  was split across separate `Bash()` invocations by the runtime, leaving `TS`
  unset when arithmetic ran. Result: AGE printed as the full unix epoch
  (~1.77 billion seconds). Rewrote as a single semicolon-joined line so all
  vars share scope. Also clarified that stale heartbeat during idle is
  expected and watchdog v0.1.5+ does not restart on stale-alone.

### Compatibility
- Plugin v0.1.0 installs are functional but show wrong AGE in `/status`. No
  action required; next `/plugin update` picks up the fix.
- Minimum CLI version unchanged: **v0.1.3** (or v0.1.5+ recommended for the
  idle-not-restart behavior described in `status.md`).

## v0.1.0 — 2026-04-24

Minimum CLI version: **v0.1.3** (earlier versions either lack the sidecar
config path or have the `curl | bash` install bug).

### Added
- SessionStart hook (`check-cli.sh`) that auto-installs the CLI when missing and version-checks it when present.
- UserPromptSubmit + Stop hooks (`heartbeat.sh`) that write the v1 heartbeat format atomically, honouring the sidecar `config.env` for custom paths.
- Four slash commands: `install`, `status`, `update`, `uninstall`.
- CI: shellcheck + smoke tests.
