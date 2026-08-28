#!/usr/bin/env bash
# Headless spawn-flow regression after legacy minigame removal.
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
LOG="Tests/logs/spawn_flow_${STAMP}.log"
export SKIP_SINGLE_INSTANCE=1

{
	echo ">>> test_spawn_flow.gd (--playtest-world-seed 424242 --playtest-capture)"
	"$GODOT" --path "$ROOT" --headless -s res://tools/test_spawn_flow.gd \
		-- --playtest-world-seed 424242 --playtest-capture 2>&1
} 2>&1 | tee "$LOG"

echo "Log: $ROOT/$LOG"
