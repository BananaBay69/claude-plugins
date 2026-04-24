# Changelog

## v0.1.0 — unreleased

### Added
- SessionStart hook (`check-cli.sh`) that auto-installs the CLI when missing and version-checks it when present.
- UserPromptSubmit + Stop hooks (`heartbeat.sh`) that write the v1 heartbeat format atomically, honouring the sidecar `config.env` for custom paths.
- Four slash commands: `install`, `status`, `update`, `uninstall`.
- CI: shellcheck + smoke tests.
