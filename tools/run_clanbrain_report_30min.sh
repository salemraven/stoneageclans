#!/usr/bin/env bash
# 30-min NPC-only ClanBrain capture + markdown report (party-hunt-debug deer + hunt traces).
# Usage (repo root): bash tools/run_clanbrain_report_30min.sh

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
LOG_DIR="$ROOT/Tests/logs/clanbrain_report_30min_${STAMP}"
mkdir -p "$LOG_DIR"
CONSOLE_LOG="$LOG_DIR/console.log"
JSONL="$LOG_DIR/playtest_session.jsonl"
REPORT="$LOG_DIR/clanbrain_report.md"

export SKIP_SINGLE_INSTANCE=1

SEED="${PLAYTEST_WORLD_SEED:-424242}"
echo "ClanBrain 30-min report → $LOG_DIR"
echo "Seed: $SEED | headless npc-only + party-hunt-debug"
echo "Started: $(date)"

"$GODOT" --path "$ROOT" --headless \
	--playtest-capture \
	--playtest-log-dir "$LOG_DIR" \
	--playtest-world-seed "$SEED" \
	--npc-only-world \
	--party-hunt-debug \
	--playtest-30min \
	2>&1 | tee "$CONSOLE_LOG"

echo ""
echo ">>> Generating report..."
python3 "$ROOT/scripts/logging/clanbrain_report.py" "$JSONL" -o "$REPORT"

echo ""
echo "=== Done ==="
echo "Finished: $(date)"
echo "Report:  $REPORT"
echo "JSONL:   $JSONL"
echo "Console: $CONSOLE_LOG"
echo ""
head -n 60 "$REPORT"
