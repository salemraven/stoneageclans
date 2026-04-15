#!/usr/bin/env bash
# Early-game reliability gate: chains smoke + territory integration + ChunkUtils invariants + ClanBrain JSONL checks.
# Usage (repo root): bash tools/run_earlygame_verify.sh
# Env: GODOT=/path/to/Godot (default: macOS app), SKIP_CLAN_BRAIN_TEST=1 to skip the longer Main session (~15s).

set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

GODOT="${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}"
if [[ ! -x "$GODOT" ]]; then
	echo "ERROR: Godot not found at $GODOT — set GODOT=/path/to/Godot" >&2
	exit 1
fi

export SKIP_SINGLE_INSTANCE=1

STAMP="$(date +%Y%m%d_%H%M%S)"
SUMMARY_LOG="Tests/logs/earlygame_verify_${STAMP}.log"
mkdir -p Tests/logs

{
	echo "=============================================="
	echo "earlygame_verify ${STAMP}"
	echo "repo: ${ROOT}"
	echo "godot: ${GODOT}"
	echo "=============================================="

	echo ""
	echo ">>> [1/4] instrumented playtest (Main smoke, ~4s)"
	bash "$ROOT/tools/run_instrumented_playtest.sh"

	echo ""
	echo ">>> [2/4] ChunkUtils invariants (headless script)"
	"$GODOT" --path "$ROOT" --headless --script res://tools/chunk_utils_verify.gd 2>&1

	echo ""
	echo ">>> [3/4] territory brain integration + JSONL field checks"
	bash "$ROOT/tools/run_territory_brain_integration_verify.sh"

	if [[ "${SKIP_CLAN_BRAIN_TEST:-}" == "1" ]]; then
		echo ""
		echo ">>> [4/4] ClanBrain JSONL validation — SKIPPED (SKIP_CLAN_BRAIN_TEST=1)"
	else
		echo ""
		echo ">>> [4/4] ClanBrain JSONL validation (~15s Main + capture)"
		bash "$ROOT/tools/run_clan_brain_test.sh"
	fi

	echo ""
	echo "=============================================="
	echo "earlygame_verify OK — ${STAMP}"
	echo "=============================================="
} 2>&1 | tee "$SUMMARY_LOG"

echo ""
echo "Summary log: $ROOT/$SUMMARY_LOG"
