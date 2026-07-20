#!/usr/bin/env bash
# Early-game reliability gate: instrumented playtest + ChunkUtils + territory integration + Nomad Mode + repro harness + ClanBrain JSONL.
# Usage (repo root): bash tools/run_earlygame_verify.sh
# Env: GODOT=/path/to/Godot (default: macOS app)
#      SKIP_CLAN_BRAIN_TEST=1 — skip step 6 (~15s Main + JSONL)
#      SKIP_REPRO_HARNESS=1 — skip step 5 (Player designated-father / two-birth regression, ~12–15s)
#      SKIP_PRODUCTION_CHAIN_TEST=1 — skip step 7 (~2–3 min isolated bread/leather + milestone harness)

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
	echo ">>> [1/7] instrumented playtest (Main smoke, ~4s)"
	bash "$ROOT/tools/run_instrumented_playtest.sh"

	echo ""
	echo ">>> [2/7] ChunkUtils invariants (headless script)"
	"$GODOT" --path "$ROOT" --headless --script res://tools/chunk_utils_verify.gd 2>&1

	echo ""
	echo ">>> [3/7] territory brain integration + JSONL field checks"
	bash "$ROOT/tools/run_territory_brain_integration_verify.sh"

	echo ""
	echo ">>> [4/7] Nomad Mode headless tests (campfire wood burn, panic, march rules)"
	bash "$ROOT/tools/run_nomad_mode_test.sh"

	if [[ "${SKIP_REPRO_HARNESS:-}" == "1" ]]; then
		echo ""
		echo ">>> [5/7] reproduction harness (Player + 2 births) — SKIPPED (SKIP_REPRO_HARNESS=1)"
	else
		echo ""
		echo ">>> [5/7] reproduction harness (headless --repro-harness, ~12–15s)"
		bash "$ROOT/tools/run_repro_harness.sh"
	fi

	if [[ "${SKIP_CLAN_BRAIN_TEST:-}" == "1" ]]; then
		echo ""
		echo ">>> [6/7] ClanBrain JSONL validation — SKIPPED (SKIP_CLAN_BRAIN_TEST=1)"
	else
		echo ""
		echo ">>> [6/7] ClanBrain JSONL validation (~15s Main + capture)"
		bash "$ROOT/tools/run_clan_brain_test.sh"
	fi

	if [[ "${SKIP_PRODUCTION_CHAIN_TEST:-}" == "1" ]]; then
		echo ""
		echo ">>> [7/7] production + milestone chain harness — SKIPPED (SKIP_PRODUCTION_CHAIN_TEST=1)"
	else
		echo ""
		echo ">>> [7/7] production + milestone chain harness (~2–3 min, real WorkRequests + build FSM)"
		bash "$ROOT/tools/run_production_chain_tests.sh"
	fi

	echo ""
	echo "=============================================="
	echo "earlygame_verify OK — ${STAMP}"
	echo "=============================================="
} 2>&1 | tee "$SUMMARY_LOG"

echo ""
echo "Summary log: $ROOT/$SUMMARY_LOG"
