#!/usr/bin/env bash
# Run Main with party/hunt FSM instrumentation (console + JSONL).
# No gameplay cheats: AI clans start solo; hunts/deer use normal world rules.
# Usage (repo root):
#   bash tools/run_party_hunt_debug.sh
#   bash tools/run_party_hunt_debug.sh 2min
#   bash tools/run_party_hunt_debug.sh 4min

set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
mkdir -p Tests/logs

GODOT="${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}"
if [[ ! -x "$GODOT" ]]; then
	echo "ERROR: Godot not found at $GODOT — set GODOT=/path/to/Godot" >&2
	exit 1
fi

PLAYTEST_FLAG="--playtest-5min"
DURATION_LABEL="5 min (300s)"
case "${1:-5min}" in
	2min|--playtest-2min) PLAYTEST_FLAG="--playtest-2min"; DURATION_LABEL="2 min (120s)" ;;
	4min|--playtest-4min) PLAYTEST_FLAG="--playtest-4min"; DURATION_LABEL="4 min (240s)" ;;
	5min|--playtest-5min|"") PLAYTEST_FLAG="--playtest-5min"; DURATION_LABEL="5 min (300s)" ;;
	*) echo "Usage: $0 [2min|4min|5min]" >&2; exit 1 ;;
esac

STAMP="$(date +%Y%m%d_%H%M%S)"
LOG_DIR="$ROOT/Tests/logs/party_hunt_${STAMP}"
mkdir -p "$LOG_DIR"
CONSOLE_LOG="$LOG_DIR/console.log"

export SKIP_SINGLE_INSTANCE=1

echo "Party/hunt debug session → $LOG_DIR"
echo "Duration: ${DURATION_LABEL} | grep console for: PARTY/HUNT"

"$GODOT" --path "$ROOT" \
	--playtest-capture \
	--playtest-log-dir "$LOG_DIR" \
	--npc-only-world \
	--party-hunt-debug \
	"$PLAYTEST_FLAG" \
	2>&1 | tee "$CONSOLE_LOG"

JSONL="$LOG_DIR/playtest_session.jsonl"
echo ""
echo "=== Party/hunt summary ==="
if [[ -f "$JSONL" ]]; then
	echo "--- JSONL events ---"
	grep -E '"evt":"party_|"evt":"party_group_scan"|"evt":"hunt_' "$JSONL" 2>/dev/null | tail -n 30 || true
fi
echo "--- Console highlights ---"
grep -E 'PARTY/HUNT (FORMED|DISBAND|STUCK|HUNT PHASE|FSM.*party|FSM.*hunt)' "$CONSOLE_LOG" 2>/dev/null | tail -n 40 || true
echo ""
echo "JSONL: $JSONL"
echo "Console: $CONSOLE_LOG"
