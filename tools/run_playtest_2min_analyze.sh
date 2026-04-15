#!/usr/bin/env bash
# NPC capture: Main headless with --playtest-2min + --playtest-capture, then analyze_playtest.py --strict.
# Do NOT pass --quit-after with --playtest-2min — engine quit-after can end the run before the 120s playtest timer (short JSONL).
# Usage (repo root): bash tools/run_playtest_2min_analyze.sh
# Env: GODOT, OUT_DIR optional (default Tests/logs/playtest_2min_analyze_<stamp>)

set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

GODOT="${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}"
if [[ ! -x "$GODOT" ]]; then
	echo "ERROR: Godot not found at $GODOT" >&2
	exit 1
fi

export SKIP_SINGLE_INSTANCE=1

STAMP="$(date +%Y%m%d_%H%M%S)"
OUT="${OUT_DIR:-$ROOT/Tests/logs/playtest_2min_analyze_${STAMP}}"
mkdir -p "$OUT"

echo ">>> playtest 2min + capture -> $OUT"
"$GODOT" --path "$ROOT" --headless -- --playtest-2min --playtest-capture --playtest-log-dir "$OUT" >"$OUT/godot.log" 2>&1
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

echo ">>> analyze_playtest.py --strict"
python3 "$ROOT/scripts/logging/analyze_playtest.py" --strict "$JSONL"
AN_EC=$?

NULL_TREE="$(grep -c 'Parameter "data.tree" is null' "$OUT/godot.log" 2>/dev/null || echo 0)"
NULL_TREE="${NULL_TREE//$'\n'/}"
if [[ "${NULL_TREE:-0}" -gt 0 ]]; then
	echo "WARN: godot.log has data.tree null errors: $NULL_TREE (investigate building/NPC teardown)" >&2
fi

echo "Artifacts: $OUT"
exit "$AN_EC"
