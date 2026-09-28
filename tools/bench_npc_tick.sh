#!/usr/bin/env bash
# Benchmark GDScript cost per NPC per physics tick, using the 4-clan eval arena.
#
# Usage (from project root):
#   bash tools/bench_npc_tick.sh [label] [seconds]
#   BENCH_AGAINST=user://lag_profile_....jsonl bash tools/bench_npc_tick.sh after 180
#
# Stash only the file under test when A/B-ing:
#   git stash push -- scripts/npc/npc_base.gd

set -euo pipefail

LABEL="${1:-unlabeled}"
SECONDS_TOTAL="${2:-180}"
WARMUP="${BENCH_WARMUP:-45}"
GODOT="${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}"

if [ ! -x "$GODOT" ] && ! command -v "$GODOT" >/dev/null 2>&1; then
  echo "Godot not found at '$GODOT'. Set GODOT=/path/to/godot" >&2
  exit 1
fi

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

export SKIP_SINGLE_INSTANCE=1
export BENCH_LABEL="$LABEL"
export BENCH_WARMUP="$WARMUP"
export BENCH_SECONDS="$SECONDS_TOTAL"
export BENCH_GIT_SHA
BENCH_GIT_SHA="$(git rev-parse --short HEAD 2>/dev/null || true)"

LOG="/tmp/bench_npc_tick_${LABEL}.log"
echo "== capture: label=$LABEL seconds=$SECONDS_TOTAL warmup=$WARMUP =="
"$GODOT" --path . --headless --eval-ai-arena --godmode --lag-profile \
  --session-quit-after "$SECONDS_TOTAL" > "$LOG" 2>&1 || true

if grep -q "SCRIPT ERROR" "$LOG"; then
  if grep "SCRIPT ERROR" "$LOG" | grep -vq "occupation_system.gd"; then
    echo "!! SCRIPT ERROR during capture (not the known occupation_system leak) — see $LOG" >&2
    exit 1
  fi
  echo "!! known occupation_system SCRIPT ERROR present (counted, not fatal until that sweep)"
fi

echo "== analyze =="
"$GODOT" --path . --headless -s res://tools/bench_npc_tick.gd 2>&1 \
  | sed -n '/=== BENCH_NPC_TICK RESULT ===/,/BENCH_NPC_TICK: ok/p'
echo "== analyze done =="
