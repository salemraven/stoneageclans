#!/usr/bin/env bash
# 10-minute NPC-only observer session: no visible player, WASD/arrows pan camera, scroll zoom.
# AI clans + party-hunt debug (deer at claims, faster hunts). Auto-quits at 600s.
#
# Usage (repo root):
#   bash tools/run_observer_10min.sh

set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
mkdir -p Tests/logs

GODOT="${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}"
if [[ ! -x "$GODOT" ]]; then
	echo "ERROR: Godot not found at $GODOT — set GODOT=/path/to/Godot" >&2
	exit 1
fi

STAMP="$(date +%Y%m%d_%H%M%S)"
LOG_DIR="$ROOT/Tests/logs/observer_10min_${STAMP}"
mkdir -p "$LOG_DIR"

export SKIP_SINGLE_INSTANCE=1

echo "Observer 10-min session → $LOG_DIR"
echo "Controls: WASD / arrows = pan camera | scroll / +/- = zoom | auto-quit at 600s"
echo ""

exec "$GODOT" --path "$ROOT" \
	--playtest-capture \
	--playtest-log-dir "$LOG_DIR" \
	--npc-only-world \
	--party-hunt-debug \
	--playtest-10min \
	2>&1 | tee "$LOG_DIR/console.log"
