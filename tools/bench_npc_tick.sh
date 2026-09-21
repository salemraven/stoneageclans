#!/usr/bin/env bash
# Benchmark GDScript cost per NPC per physics tick, using the 4-clan eval arena.
#
# Reports microseconds per NPC per tick instead of FPS. Frame rate in this scenario
# swings with crowd size, fight outcomes and vsync, so a single run cannot tell two
# code versions apart. Dividing script time by tick count cancels population out.
#
# Usage (from project root):
#   bash tools/bench_npc_tick.sh [label] [seconds]
#
# To compare versions, stash ONLY the file under test:
#   bash tools/bench_npc_tick.sh after
#   git stash push -- scripts/npc/npc_base.gd
#   bash tools/bench_npc_tick.sh before
#   git stash pop
# Never a bare `git stash` here — it reverts every other uncommitted file in the repo
# and the arena silently spawns no fighters, which invalidates the run.

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

echo "== capture: label=$LABEL seconds=$SECONDS_TOTAL warmup=$WARMUP =="
"$GODOT" --path . --headless --eval-ai-arena --godmode --lag-profile \
  --session-quit-after "$SECONDS_TOTAL" > "/tmp/bench_npc_tick_${LABEL}.log" 2>&1 || true

if grep -q "SCRIPT ERROR" "/tmp/bench_npc_tick_${LABEL}.log"; then
  echo "!! SCRIPT ERROR during capture — see /tmp/bench_npc_tick_${LABEL}.log" >&2
fi

echo "== analyze =="
BENCH_LABEL="$LABEL" BENCH_WARMUP="$WARMUP" \
  "$GODOT" --path . --headless -s res://tools/bench_npc_tick.gd 2>&1 \
  | sed -n '/=== BENCH_NPC_TICK RESULT ===/,/BENCH_NPC_TICK: ok/p'
