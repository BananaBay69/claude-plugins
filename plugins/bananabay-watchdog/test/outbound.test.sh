#!/bin/bash
# Unit test: outbound.sh writes valid v1 schema atomically.
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOK="$SCRIPT_DIR/../hooks/outbound.sh"

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

OUTBOUND_FILE="$TMPDIR/outbound"

# Run hook with explicit env (no config.env present)
HOME="$TMPDIR/fake-home" WATCHDOG_OUTBOUND_FILE="$OUTBOUND_FILE" bash "$HOOK"

# Assert file exists
[ -f "$OUTBOUND_FILE" ] || { echo "FAIL: outbound file not created"; exit 1; }

# Assert schema "1 <numeric_ts>"
content=$(cat "$OUTBOUND_FILE")
if ! [[ "$content" =~ ^1\ [0-9]+$ ]]; then
    echo "FAIL: bad schema, got: $content"
    exit 1
fi

# Assert ts within last 5 seconds
ts=$(echo "$content" | awk '{print $2}')
now=$(date +%s)
diff=$(( now - ts ))
if [ "$diff" -lt 0 ] || [ "$diff" -gt 5 ]; then
    echo "FAIL: ts off by ${diff}s"
    exit 1
fi

# Assert no .tmp leftover (atomic write succeeded)
[ ! -f "$OUTBOUND_FILE.tmp" ] || { echo "FAIL: .tmp leftover"; exit 1; }

echo "PASS: outbound.sh writes v1 schema atomically with current timestamp"
