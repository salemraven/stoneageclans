#!/usr/bin/env bash
# Ultimate NPC & ClanBrain gate (bible/Ultimate_npc_clanbrain_test.md):
# Smoke + territory/brain integration + ClanBrain capture + analyze_playtest --strict-clanbrain
# + NPC-only ~120s Main (--npc-only-world) + analyze (--strict-clanbrain --strict-npc-sim).
#
# Usage (repo root): bash tools/run_ultimate_npc_clanbrain_test.sh
#
# Env:
#   GODOT                      — optional path to Godot
#   ULTIMATE_LONG_2MIN=1       — append 2‑min instrumented Main + herd strict (adds ~2 min wall time).
#                               Passes ANALYZER_EXTRA_ARGS to include --strict-clanbrain there too.
#   ULTIMATE_ECONOMY_5MIN=1    — append 5‑min NPC-only economy stress test (hunger/eat/starvation gate).
#   ULTIMATE_PRODUCTION_STRICT=1 — with ULTIMATE_ECONOMY_5MIN=1, also require work_request_completed + production_work FSM
#   SKIP_ULTIMATE_2MIN=1       — omit long step even if defaulted elsewhere (explicit skip)
#   SKIP_NPC_ONLY_2MIN=1       — skip ~120s NPC-only Main + analyze (--npc-only-world proof)
#
# Analyzer env for the ClanBrain JSONL step:
#   ULTIMATE_MIN_CLAN_BRAIN_EVALS   — default 1 (require ≥N clan_brain_eval)
#   ULTIMATE_MIN_QUOTA_UPDATES      — default 0 (optional; set 1 to insist on quotas in short Main)

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

mkdir -p Tests/logs
STAMP="$(date +%Y%m%d_%H%M%S)"
BUNDLE="$ROOT/Tests/logs/ultimate_npc_cb_${STAMP}"
mkdir -p "$BUNDLE"

SUMMARY="$BUNDLE/summary.log"
MIN_EVAL="${ULTIMATE_MIN_CLAN_BRAIN_EVALS:-1}"
MIN_QUOTA="${ULTIMATE_MIN_QUOTA_UPDATES:-0}"

exec > >(tee -a "$SUMMARY") 2>&1

echo "=============================================="
echo "ultimate_npc_clanbrain_test ${STAMP}"
echo "bundle: ${BUNDLE}"
echo "repo: ${ROOT}"
echo "=============================================="

bash "$ROOT/tools/run_instrumented_playtest.sh"

bash "$ROOT/tools/run_territory_brain_integration_verify.sh"

echo ""
echo ">>> Nomad Mode headless tests (campfire relocation invariants)"
bash "$ROOT/tools/run_nomad_mode_test.sh"

echo ""
echo ">>> ClanBrain capture into bundle (same JSONL analyzed below)"
export CLAN_BRAIN_LOG_DIR="$BUNDLE/clan_brain_main"
mkdir -p "$CLAN_BRAIN_LOG_DIR"
bash "$ROOT/tools/run_clan_brain_test.sh"

JSONL="$BUNDLE/clan_brain_main/playtest_session.jsonl"
if [[ ! -f "$JSONL" ]]; then
	echo "FAIL: missing $JSONL"
	exit 1
fi

AN_CMD=(
	python3 "$ROOT/scripts/logging/analyze_playtest.py"
	"--strict-clanbrain"
	"--min-clanbrain-eval-events" "$MIN_EVAL"
)
if [[ "$MIN_QUOTA" =~ ^[0-9]+$ ]] && [[ "${MIN_QUOTA}" -gt 0 ]]; then
	AN_CMD+=("--min-clanbrain-quota-updates" "$MIN_QUOTA")
fi
echo ""
echo ">>> ${AN_CMD[*]} $JSONL"
"${AN_CMD[@]}" "$JSONL"
ANA_EC=$?

FINAL_EC="${ANA_EC}"

if [[ "${SKIP_NPC_ONLY_2MIN:-}" != "1" ]]; then
	NPC_OUT="$BUNDLE/npc_only_2min"
	mkdir -p "$NPC_OUT"
	echo ""
	echo ">>> NPC-only world (~120s): bash tools/run_playtest_npc_only_2min_analyze.sh (OUT_DIR)"
	export OUT_DIR="$NPC_OUT"
	export ANALYZER_EXTRA_ARGS=""
	bash "$ROOT/tools/run_playtest_npc_only_2min_analyze.sh"
	NPC_EC=$?
	if [[ "${FINAL_EC}" -eq 0 ]] && [[ "${NPC_EC}" -ne 0 ]]; then
		FINAL_EC="${NPC_EC}"
	fi
else
	echo ""
	echo ">>> NPC-only world step SKIPPED (SKIP_NPC_ONLY_2MIN=1)"
fi

if [[ "${SKIP_ULTIMATE_2MIN:-}" == "1" ]]; then
	echo ""
	echo ">>> Long 2-min playtest — SKIPPED (SKIP_ULTIMATE_2MIN=1)"
	exit "$FINAL_EC"
fi

if [[ "${ULTIMATE_LONG_2MIN:-}" != "1" ]]; then
	echo ""
	echo "(Set ULTIMATE_LONG_2MIN=1 to add ~2-min herd-heavy Main + --strict --strict-clanbrain)"
	exit "${FINAL_EC}"
fi

OUT_LONG="$BUNDLE/playtest_2min"
mkdir -p "$OUT_LONG"
echo ""
echo ">>> Long step: bash tools/run_playtest_2min_analyze.sh (OUT_DIR)"
export OUT_DIR="$OUT_LONG"
export ANALYZER_EXTRA_ARGS="--strict-clanbrain"
bash "$ROOT/tools/run_playtest_2min_analyze.sh"
LONG_EC=$?
if [[ "${FINAL_EC}" -ne 0 ]] || [[ "${LONG_EC}" -ne 0 ]]; then
	FINAL_EC=1
fi

if [[ "${ULTIMATE_ECONOMY_5MIN:-}" == "1" ]]; then
	ECON_OUT="$BUNDLE/npc_only_5min_economy"
	mkdir -p "$ECON_OUT"
	echo ""
	echo ">>> 5-min NPC-only economy stress test: bash tools/run_playtest_npc_only_5min_economy.sh"
	export OUT_DIR="$ECON_OUT"
	if [[ "${ULTIMATE_PRODUCTION_STRICT:-}" == "1" ]]; then
		export PRODUCTION_STRICT=1
	fi
	bash "$ROOT/tools/run_playtest_npc_only_5min_economy.sh"
	ECON_EC=$?
	if [[ "${FINAL_EC}" -eq 0 ]] && [[ "${ECON_EC}" -ne 0 ]]; then
		FINAL_EC="${ECON_EC}"
	fi
else
	echo ""
	echo "(Set ULTIMATE_ECONOMY_5MIN=1 to add ~5-min economy stress test: hunger/eat loop + no starvation)"
fi

echo ""
echo "Ultimate NPC / ClanBrain bundle: ${BUNDLE} (exit=${FINAL_EC})"
exit "${FINAL_EC}"
