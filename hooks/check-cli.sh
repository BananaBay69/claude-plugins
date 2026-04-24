#!/bin/bash
# bananabay-watchdog — SessionStart hook.
# Verifies claude-watchdog CLI is installed and up-to-date.
# Auto-installs if absent; prints update hint if outdated.
# Always exits 0.
#
# Env overrides (testing only):
#   BANANABAY_WATCHDOG_INSTALL_URL — override install.sh URL
#   BANANABAY_WATCHDOG_RELEASE_URL — override GitHub release API URL

set +e

INSTALL_URL="${BANANABAY_WATCHDOG_INSTALL_URL:-https://raw.githubusercontent.com/BananaBay69/claude-code-watchdog/main/install.sh}"
RELEASE_URL="${BANANABAY_WATCHDOG_RELEASE_URL:-https://api.github.com/repos/BananaBay69/claude-code-watchdog/releases/latest}"

# Portable timeout: use `timeout` (GNU coreutils), `gtimeout` (Homebrew),
# or fall back to `perl -e alarm` (universally available on macOS).
# Last resort: run the command directly (rare; we prefer not to hang).
_run_with_timeout() {
    local secs="$1"; shift
    if command -v timeout >/dev/null 2>&1; then
        timeout "$secs" "$@"
    elif command -v gtimeout >/dev/null 2>&1; then
        gtimeout "$secs" "$@"
    elif command -v perl >/dev/null 2>&1; then
        perl -e 'alarm shift; exec @ARGV' "$secs" "$@"
    else
        "$@"
    fi
}

CLI=""
for p in "$HOME/bin/claude-watchdog.sh" /usr/local/bin/claude-watchdog.sh "$HOME/.local/bin/claude-watchdog.sh"; do
    if [ -x "$p" ]; then CLI="$p"; break; fi
done

if [ -z "$CLI" ]; then
    echo "⚠️  claude-watchdog CLI not found — installing automatically..." >&2
    # pipefail so that a curl failure (empty stdin to bash) is not masked
    # by bash's own exit 0 on empty input.
    set -o pipefail
    if curl -fsSL --max-time 30 "$INSTALL_URL" 2>/dev/null | bash -s -- 2>&1 >&2; then
        echo "✅ claude-watchdog installed" >&2
    else
        echo "❌ Auto-install failed. Run /bananabay-watchdog:install manually." >&2
    fi
    set +o pipefail
    exit 0
fi

INSTALLED=$(_run_with_timeout 2 "$CLI" --version 2>/dev/null | awk '{print $NF}' | head -1)
LATEST=$(_run_with_timeout 2 curl -fsSL --max-time 2 "$RELEASE_URL" 2>/dev/null \
    | sed -n 's/.*"tag_name": *"v\{0,1\}\([^"]*\)".*/\1/p' \
    | head -1)

if [ -z "$INSTALLED" ]; then
    echo "⚠️  claude-watchdog found but --version failed" >&2
elif [ -z "$LATEST" ]; then
    echo "✓ claude-watchdog v$INSTALLED (couldn't check for updates — continuing)" >&2
elif [ "$INSTALLED" = "$LATEST" ]; then
    echo "✓ claude-watchdog v$INSTALLED (latest)" >&2
else
    echo "⬆️  claude-watchdog v$INSTALLED → v$LATEST available. Run /bananabay-watchdog:update" >&2
fi

exit 0
