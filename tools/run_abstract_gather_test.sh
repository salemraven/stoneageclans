#!/usr/bin/env bash
# Headless abstract gather unit checks (Phase 3).
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
LOG="Tests/logs/abstract_gather_${STAMP}.log"
export SKIP_SINGLE_INSTANCE=1

{
    echo ">>> test_abstract_gather.gd"
    "$GODOT" --path "$ROOT" --headless -s res://tools/test_abstract_gather.gd \
        -- --playtest-capture --playtest-world-seed 424242 2>&1
} 2>&1 | tee "$LOG"

echo "Log: $ROOT/$LOG"
