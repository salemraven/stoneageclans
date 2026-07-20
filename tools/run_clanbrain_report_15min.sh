#!/usr/bin/env bash
# 15-min NPC-only capture — long enough for hunt eval / food buffer drain (no party-hunt-debug cheats).
# Usage (repo root): bash tools/run_clanbrain_report_15min.sh
#
# Env:
#   PLAYTEST_WORLD_SEED  — default 424242
#   PARTY_HUNT_DEBUG=1   — also pass --party-hunt-debug (seed deer at claims; not default)

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
LOG_DIR="$ROOT/Tests/logs/clanbrain_report_15min_${STAMP}"
mkdir -p "$LOG_DIR"
CONSOLE_LOG="$LOG_DIR/console.log"
JSONL="$LOG_DIR/playtest_session.jsonl"
REPORT="$LOG_DIR/clanbrain_report.md"

export SKIP_SINGLE_INSTANCE=1

SEED="${PLAYTEST_WORLD_SEED:-424242}"
GODOT_FLAGS=(
	--playtest-capture
	--playtest-log-dir "$LOG_DIR"
	--playtest-world-seed "$SEED"
	--npc-only-world
	--playtest-15min
)
if [[ "${PARTY_HUNT_DEBUG:-}" == "1" ]]; then
	GODOT_FLAGS+=(--party-hunt-debug)
	echo "NOTE: PARTY_HUNT_DEBUG=1 — seeded deer at claims (not pure wild spawn)"
fi

echo "ClanBrain 15-min hunt observation → $LOG_DIR"
echo "Seed: $SEED | headless npc-only | auto-quit 900s"

"$GODOT" --path "$ROOT" --headless -- "${GODOT_FLAGS[@]}" \
	2>&1 | tee "$CONSOLE_LOG"

echo ""
echo ">>> Hunt signal counts..."
python3 - <<'PY' "$JSONL"
import json, sys
path = sys.argv[1]
counts = {}
with open(path, encoding="utf-8") as f:
    for line in f:
        line = line.strip()
        if not line:
            continue
        try:
            row = json.loads(line)
        except json.JSONDecodeError:
            continue
        evt = row.get("evt", "")
        if evt in ("hunt_started", "hunt_joined", "hunt_phase_changed", "hunt_completed", "hunt_aborted"):
            counts[evt] = counts.get(evt, 0) + 1
        if evt == "npc_fsm_transition" and row.get("to_state") == "hunt":
            counts["fsm_hunt_enter"] = counts.get("fsm_hunt_enter", 0) + 1
max_t = 0.0
with open(path, encoding="utf-8") as f:
    for line in f:
        try:
            max_t = max(max_t, float(json.loads(line).get("t", 0)))
        except Exception:
            pass
print(f"  session max t: {max_t:.1f}s")
for k in sorted(counts):
    print(f"  {k}: {counts[k]}")
if counts.get("hunt_started", 0) == 0:
    print("  >>> NO hunt_started events in this run")
else:
    print("  >>> Hunts triggered")
PY

echo ""
echo ">>> Generating markdown report..."
python3 "$ROOT/scripts/logging/clanbrain_report.py" "$JSONL" -o "$REPORT"

echo ""
echo ">>> JSONL analysis (hunt + ClanBrain)..."
python3 "$ROOT/scripts/logging/analyze_playtest.py" \
	--strict-clanbrain \
	--strict-npc-sim \
	--require-npc-only-session \
	--min-npc-session-sec 880 \
	--min-clanbrain-eval-events 60 \
	--min-npc-hunt-brain 0 \
	"$JSONL" || true

echo ""
echo "=== Done ==="
echo "Report:  $REPORT"
echo "JSONL:   $JSONL"
echo "Console: $CONSOLE_LOG"
echo ""
grep -A 20 "### Hunt lifecycle" "$REPORT" || head -n 50 "$REPORT"
