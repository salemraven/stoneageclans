#!/usr/bin/env bash
# AI-only Main capture: hidden player hub at origin + ~120s productivity JSONL (--npc-only-world).
# Does NOT enable herd --strict by default (herding may be sparse without an avatar driving overlap).
#
# Usage (repo root): bash tools/run_playtest_npc_only_2min_analyze.sh
# Env:
#   GODOT                          — optional Godot binary
#   OUT_DIR                        — log dir (default Tests/logs/playtest_npc_only_2min_<stamp>)
#   SKIP_SINGLE_INSTANCE=1         — set by script
#   ANALYZER_EXTRA_ARGS            — extra analyze_playtest.py flags (space-separated)
#   ULTIMATE_MIN_CLAN_BRAIN_EVALS  — passed as --min-clanbrain-eval-events (default 1)
#   ULTIMATE_MIN_QUOTA_UPDATES     — if >0, adds --min-clanbrain-quota-updates
#   ULTIMATE_NPC_SIM_MIN_GATHER         — default 8
#   ULTIMATE_NPC_SIM_MIN_HUNT_WORLD     — default 1 (--min-npc-hunt-world)
#   ULTIMATE_NPC_SIM_MIN_HUNT_BRAIN     — default 1 (--min-npc-hunt-brain)
#   ULTIMATE_NPC_SIM_MIN_GROWTH_UNIQUE   — default 1 (deduped baby keys)
#   MIN_NPC_SESSION_SEC_FOR_ANALYZE     — default 90 (--min-npc-session-sec)
#   PLAYTEST_WORLD_SEED                 — default 88442201; set "random" to omit --playtest-world-seed

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
OUT="${OUT_DIR:-$ROOT/Tests/logs/playtest_npc_only_2min_${STAMP}}"
mkdir -p "$OUT"

echo ">>> NPC-only world: playtest 2min + capture -> $OUT"
GODOT_USER=(--npc-only-world --playtest-2min --playtest-capture --playtest-log-dir "$OUT")
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

MIN_EVAL="${ULTIMATE_MIN_CLAN_BRAIN_EVALS:-1}"
MIN_QUOTA="${ULTIMATE_MIN_QUOTA_UPDATES:-0}"
MIN_GATHER="${ULTIMATE_NPC_SIM_MIN_GATHER:-8}"
MIN_HUNT_WORLD="${ULTIMATE_NPC_SIM_MIN_HUNT_WORLD:-1}"
MIN_HUNT_BRAIN="${ULTIMATE_NPC_SIM_MIN_HUNT_BRAIN:-1}"
MIN_GROW_UNIQUE="${ULTIMATE_NPC_SIM_MIN_GROWTH_UNIQUE:-1}"
MIN_NPC_SESS="${MIN_NPC_SESSION_SEC_FOR_ANALYZE:-90}"

AN_CMD=(
	python3 "$ROOT/scripts/logging/analyze_playtest.py"
	"--strict-clanbrain"
	"--min-clanbrain-eval-events" "$MIN_EVAL"
	"--strict-npc-sim"
	"--require-npc-only-session"
	"--min-npc-gather-fsm" "$MIN_GATHER"
	"--min-npc-hunt-world" "$MIN_HUNT_WORLD"
	"--min-npc-hunt-brain" "$MIN_HUNT_BRAIN"
	"--min-npc-growth-unique" "$MIN_GROW_UNIQUE"
	"--min-npc-session-sec" "$MIN_NPC_SESS"
)
if [[ "$MIN_QUOTA" =~ ^[0-9]+$ ]] && [[ "${MIN_QUOTA}" -gt 0 ]]; then
	AN_CMD+=("--min-clanbrain-quota-updates" "$MIN_QUOTA")
fi
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
