# Changelog

## v0.1.1 (2026-04-26)

### Fixed
- **Hard rule 3 fall-through gate** ([#18](https://github.com/BananaBay69/invite-friend/issues/18)) — SKILL previously ran `~/bin/invite-cli check-reply` on every non-self DM/group message but had no explicit "if `has_pending_invite=false` → release control to other handlers" branch. Result: any session loading the SKILL would silently consume every message and never reply (claude-connect#1, occurred for 30+ minutes on Mr.Coconut on 2026-04-25). Added explicit hard rule 3-fall-through near the top of SKILL.md, and strengthened wording in the Reply Hook section + Step 完整 flow to point back to the gate.

### Notes
- Backward-compatible — same trigger condition, same `~/bin/invite-cli` interface, same state files. Only the SKILL prose has changed (adds an explicit terminating gate that was previously implied by prose).
- Was hot-patched on Mac mini cache 2026-04-26 00:14 (claude-connect#2, now closed). This release upstreams the patch so future plugin updates retain the fix.
- Bug detection capability shipped at [BananaBay69/claude-code-watchdog#15](https://github.com/BananaBay69/claude-code-watchdog/issues/15) (v0.1.7 silent-loop alert).

## v0.1.0 (2026-04-25)

- Initial Claude-driven invite-friend plugin migrated from Openclaw Bot (GPT-5.4) to Claude Code. Same `~/bin/invite-cli` and state files at `~/.openclaw/...`.
