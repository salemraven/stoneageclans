#!/usr/bin/env bash
# Long headless AI food / growth test — release bootstrap (~1 meal), regen + slaughter enabled.
#
# Usage (repo root):
#   bash tools/run_ai_food_long_test.sh
#   SESSION_MINUTES=15 bash tools/run_ai_food_long_test.sh
#
# Uses release food bootstrap (NOT --ai-dev-food-bootstrap). Session quickstart uses dev bootstrap separately.
# Env:
#   SESSION_MINUTES              — default 10 (wall-clock)
#   NEARBY_CLANS                 — default 3
#   SESSION_AI_CLAN_TOUR_AWAY_SEC — default: SESSION_MINUTES*60 - 30 (visit overhead)
#   OUT_DIR                      — optional log bundle dir
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

MINUTES="${SESSION_MINUTES:-10}"
SEC=$((MINUTES * 60))
# Tour visits ~6s × NEARBY_CLANS; keep player far for the rest of the session.
NEARBY="${NEARBY_CLANS:-3}"
VISIT_OVERHEAD=$((6 * NEARBY + 10))
AWAY_SEC="${SESSION_AI_CLAN_TOUR_AWAY_SEC:-$((SEC - VISIT_OVERHEAD))}"
if [[ "$AWAY_SEC" -lt 120 ]]; then
	AWAY_SEC=120
fi

STAMP="$(date +%Y%m%d_%H%M%S)"
BUNDLE="${OUT_DIR:-$ROOT/Tests/logs/ai_food_long_${STAMP}}"
mkdir -p "$BUNDLE"

export SKIP_SINGLE_INSTANCE=1
export SESSION_MINUTES="$MINUTES"
export SESSION_QUIT_AFTER_SEC="$SEC"
export SESSION_AI_CLAN_TOUR=1
export SESSION_AI_CLAN_TOUR_AWAY_SEC="$AWAY_SEC"
export SESSION_AI_CLAN_TOUR_STAY_AWAY=1
export NEARBY_CLANS="$NEARBY"
export TRUNCATE_SESSION_LOG=1
export ANALYZE=0
export SESSION_LOG_OUT="$BUNDLE/console.log"
export SESSION_GAME_LOG_OUT="$BUNDLE/game_logs.txt"

echo "=== AI food long test ==="
echo "Duration: ${MINUTES} min (${SEC}s wall)"
echo "Nearby AI clans: ${NEARBY}"
echo "Off-screen away: ${AWAY_SEC}s (~$((AWAY_SEC / 30)) settlement ticks at 30s interval)"
echo "Output: $BUNDLE"
echo ""

bash "$ROOT/run_session_instrument.sh" -- --headless

JSONL="$(ls "$HOME/Library/Application Support/Godot/app_userdata/StoneAgeClans"/playtest_*.jsonl 2>/dev/null | sort -r | head -1 || true)"
if [[ "$(uname -s)" != "Darwin" ]]; then
	JSONL="$(ls "${HOME}/.local/share/godot/app_userdata/StoneAgeClans"/playtest_*.jsonl 2>/dev/null | sort -r | head -1 || true)"
fi
if [[ -n "$JSONL" && -f "$JSONL" ]]; then
	cp "$JSONL" "$BUNDLE/playtest_session.jsonl"
	JSONL="$BUNDLE/playtest_session.jsonl"
fi

echo ""
echo ">>> AI clans summary"
bash "$ROOT/tools/summarize_ai_clans_playtest.sh" "${JSONL:-}" || true

echo ""
echo ">>> Starvation analysis"
if [[ -f "$JSONL" ]]; then
	python3 "$ROOT/tools/analyze_ai_food_starvation.py" "$JSONL" | tee "$BUNDLE/starvation_report.txt"
else
	echo "No JSONL captured."
fi

echo ""
echo "=== Done ==="
echo "Bundle: $BUNDLE"
