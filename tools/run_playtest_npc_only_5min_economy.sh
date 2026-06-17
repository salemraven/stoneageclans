#!/usr/bin/env bash
# 5-min NPC-only economy stress test: proves hunger/eat loop + no starvation deaths.
# Uses --playtest-5min (300s) + --npc-only-world + --strict-economy analysis.
#
# Usage (repo root): bash tools/run_playtest_npc_only_5min_economy.sh
# Env:
#   GODOT                          — optional Godot binary
#   OUT_DIR                        — log dir (default Tests/logs/playtest_npc_only_5min_<stamp>)
#   PLAYTEST_WORLD_SEED            — default 88442201; set "random" to omit --playtest-world-seed
#   MAX_STARVATION_DEATHS          — default 0 (no starvation allowed)
#   MIN_EAT_EVENTS                 — default 10 (NPCs must eat during 5 min)
#   ANALYZER_EXTRA_ARGS            — extra analyze_playtest.py flags

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
OUT="${OUT_DIR:-$ROOT/Tests/logs/playtest_npc_only_5min_${STAMP}}"
mkdir -p "$OUT"

echo ">>> NPC-only world: 5-min economy stress test -> $OUT"
GODOT_USER=(--npc-only-world --playtest-5min --playtest-capture --playtest-log-dir "$OUT")
if [[ "${PLAYTEST_WORLD_SEED:-}" != "random" ]]; then
	GODOT_USER+=(--playtest-world-seed "${PLAYTEST_WORLD_SEED:-88442201}")
fi
"$GODOT" --path "$ROOT" --headless -- "${GODOT_USER[@]}" \
	>"$OUT/godot.log" 2>&1
EC=$?
echo "EXIT:$EC" >>"$OUT/godot.log"
if [[ "$EC" -ne 0 ]]; then
	echo "ERROR: Godot exited $EC" >&2
	exit "$EC"
fi
git rev-parse HEAD >"$OUT/commit.txt" 2>/dev/null || true

JSONL="$OUT/playtest_session.jsonl"
if [[ ! -f "$JSONL" ]]; then
	echo "ERROR: missing $JSONL" >&2
	exit 1
fi

MAX_STARVE="${MAX_STARVATION_DEATHS:-0}"
MIN_EAT="${MIN_EAT_EVENTS:-10}"

PROD_ARGS=(
	"--strict-production"
	"--min-production-allocation-eval" "${MIN_PRODUCTION_ALLOC_EVAL:-1}"
)
if [[ "${ULTIMATE_PRODUCTION_STRICT:-}" == "1" ]] || [[ "${PRODUCTION_STRICT:-}" == "1" ]]; then
	PROD_ARGS+=(
		"--min-work-request-completed" "${MIN_WORK_REQUEST_COMPLETED:-1}"
		"--min-production-work-fsm" "${MIN_PRODUCTION_WORK_FSM:-1}"
	)
fi

AN_CMD=(
	python3 "$ROOT/scripts/logging/analyze_playtest.py"
	"--strict-clanbrain"
	"--min-clanbrain-eval-events" "1"
	"--strict-npc-sim"
	"--require-npc-only-session"
	"--min-npc-gather-fsm" "15"
	"--min-npc-hunt-world" "1"
	"--min-npc-hunt-brain" "1"
	"--min-npc-growth-unique" "1"
	"--min-npc-session-sec" "280"
	"--strict-economy"
	"--max-starvation-deaths" "$MAX_STARVE"
	"--min-eat-events" "$MIN_EAT"
	"${PROD_ARGS[@]}"
)
EXTRA=()
if [[ -n "${ANALYZER_EXTRA_ARGS:-}" ]]; then
	read -r -a EXTRA <<<"${ANALYZER_EXTRA_ARGS}"
fi
echo ">>> ${AN_CMD[*]} ${ANALYZER_EXTRA_ARGS:-} $JSONL"
if [[ "${#EXTRA[@]}" -eq 0 ]]; then
	"${AN_CMD[@]}" "$JSONL"
else
	"${AN_CMD[@]}" "${EXTRA[@]}" "$JSONL"
fi
AN_EC=$?

echo "Artifacts: $OUT"
exit "$AN_EC"
