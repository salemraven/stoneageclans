#!/usr/bin/env bash
# Headless 4-clan valley + JSONL, then summarize.
# Usage: SECS=300 bash tools/run_eval_behavior.sh
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
GODOT="${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}"
SECS="${SECS:-120}"
STAMP="$(date +%Y%m%d_%H%M%S)"
OUT="${OUT_DIR:-$ROOT/Tests/logs/eval_behavior_${SECS}s_${STAMP}}"
mkdir -p "$OUT"
export SKIP_SINGLE_INSTANCE=1
echo ">>> eval behavior ${SECS}s -> $OUT"
"$GODOT" --path "$ROOT" --headless --skip-single-instance \
  --eval-ai-arena --godmode --playtest-capture \
  --eval-behavior-sec "$SECS" --session-quit-after "$SECS" \
  --playtest-log-dir "$OUT" \
  >"$OUT/godot.log" 2>&1 || true
echo "EXIT recorded in $OUT/godot.log"
JSONL="$OUT/playtest_session.jsonl"
if [[ ! -f "$JSONL" ]]; then
  echo "ERROR: missing $JSONL"
  tail -40 "$OUT/godot.log" || true
  exit 1
fi
python3 "$ROOT/tools/summarize_eval_behavior.py" "$JSONL"
echo "Artifacts: $OUT"
