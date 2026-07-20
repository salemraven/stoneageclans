#!/usr/bin/env bash
# 5-min NPC-only ClanBrain capture + markdown report + strict JSONL gates (clansmen instruments).
# Usage (repo root): bash tools/run_clanbrain_report_5min.sh

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
LOG_DIR="$ROOT/Tests/logs/clanbrain_report_5min_${STAMP}"
mkdir -p "$LOG_DIR"
CONSOLE_LOG="$LOG_DIR/console.log"
JSONL="$LOG_DIR/playtest_session.jsonl"
REPORT="$LOG_DIR/clanbrain_report.md"
ANALYSIS="$LOG_DIR/analyze_playtest.txt"

export SKIP_SINGLE_INSTANCE=1

SEED="${PLAYTEST_WORLD_SEED:-424242}"
MIN_EVAL="${MIN_CLANBRAIN_EVALS:-20}"
MIN_GREW="${MIN_CLANSMEN_GREW:-1}"
MIN_GATHER="${MIN_CLANSMEN_GATHER:-3}"
MIN_DEPOSIT="${MIN_CLANSMEN_DEPOSIT:-2}"
MIN_SNAPS="${MIN_CLANSMEN_PRODUCTIVITY_SNAPSHOTS:-8}"

echo "ClanBrain 5-min report → $LOG_DIR"
echo "Seed: $SEED | headless npc-only + party-hunt-debug + clansmen JSONL instruments"

"$GODOT" --path "$ROOT" --headless \
	--playtest-capture \
	--playtest-log-dir "$LOG_DIR" \
	--playtest-world-seed "$SEED" \
	--npc-only-world \
	--party-hunt-debug \
	--playtest-5min \
	2>&1 | tee "$CONSOLE_LOG"

echo ""
echo ">>> Generating markdown report..."
python3 "$ROOT/scripts/logging/clanbrain_report.py" "$JSONL" -o "$REPORT"

echo ""
echo ">>> JSONL strict analysis (ClanBrain + clansmen coverage)..."
python3 "$ROOT/scripts/logging/analyze_playtest.py" \
	--strict-clanbrain \
	--strict-npc-sim \
	--require-npc-only-session \
	--min-npc-session-sec 280 \
	--min-clanbrain-eval-events "$MIN_EVAL" \
	--min-clansmen-grew "$MIN_GREW" \
	--min-clansmen-gather "$MIN_GATHER" \
	--min-clansmen-deposit "$MIN_DEPOSIT" \
	--min-clansmen-productivity-snapshots "$MIN_SNAPS" \
	"$JSONL" | tee "$ANALYSIS"

echo ""
echo "=== Done ==="
echo "Report:   $REPORT"
echo "Analysis: $ANALYSIS"
echo "JSONL:    $JSONL"
echo "Console:  $CONSOLE_LOG"
echo ""
head -n 80 "$REPORT"
