#!/usr/bin/env bash
# Headless settlement pregnancy/birth/growth checks (Phase 7).
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
LOG="Tests/logs/settlement_pregnancy_${STAMP}.log"
export SKIP_SINGLE_INSTANCE=1

{
	echo ">>> test_settlement_pregnancy.gd"
	"$GODOT" --path "$ROOT" --headless -s res://tools/test_settlement_pregnancy.gd \
		-- --playtest-capture --playtest-world-seed 424242 2>&1
} 2>&1 | tee "$LOG"

echo "Log: $ROOT/$LOG"
