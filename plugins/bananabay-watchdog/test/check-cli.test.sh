#!/bin/bash
# Smoke test: check-cli.sh never exits non-zero and emits stderr status
# lines appropriate to environment.
set -euo pipefail

SCRIPT="$(cd "$(dirname "$0")/.." && pwd)/hooks/check-cli.sh"
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

# Test 1: CLI absent — script must not fail; should emit install attempt.
# We short-circuit curl by setting override env vars to a non-routable URL.
EXITCODE=0
HOME="$TMPDIR" BANANABAY_WATCHDOG_INSTALL_URL="http://127.0.0.1:1/install.sh" \
  BANANABAY_WATCHDOG_RELEASE_URL="http://127.0.0.1:1/latest" \
  bash "$SCRIPT" 2>"$TMPDIR/err" || EXITCODE=$?
[ "$EXITCODE" = "0" ] || { echo "FAIL: exit code $EXITCODE (must be 0)"; cat "$TMPDIR/err"; exit 1; }
grep -q "claude-watchdog CLI not found" "$TMPDIR/err" || {
  echo "FAIL: missing 'not found' message"; cat "$TMPDIR/err"; exit 1; }
# With an unreachable install URL, auto-install must report failure, not success.
grep -q "Auto-install failed" "$TMPDIR/err" || {
  echo "FAIL: unreachable URL should have produced 'Auto-install failed'"; cat "$TMPDIR/err"; exit 1; }
grep -q "claude-watchdog installed" "$TMPDIR/err" && {
  echo "FAIL: reported 'installed' when curl was against unreachable URL"; cat "$TMPDIR/err"; exit 1; } || true

# Test 2: CLI present — stub a fake binary and confirm version line
FAKE_CLI_DIR="$TMPDIR/bin"
mkdir -p "$FAKE_CLI_DIR"
cat > "$FAKE_CLI_DIR/claude-watchdog.sh" <<'FAKE'
#!/bin/bash
[ "$1" = "--version" ] && { echo "0.1.1"; exit 0; }
echo "fake" >&2; exit 0
FAKE
chmod +x "$FAKE_CLI_DIR/claude-watchdog.sh"

EXITCODE=0
HOME="$TMPDIR" BANANABAY_WATCHDOG_RELEASE_URL="http://127.0.0.1:1/latest" \
  bash "$SCRIPT" 2>"$TMPDIR/err2" || EXITCODE=$?
[ "$EXITCODE" = "0" ] || { echo "FAIL: exit $EXITCODE with CLI present"; cat "$TMPDIR/err2"; exit 1; }
grep -q "claude-watchdog v0.1.1" "$TMPDIR/err2" || {
  echo "FAIL: missing version line"; cat "$TMPDIR/err2"; exit 1; }

echo "check-cli.sh smoke test: OK"
