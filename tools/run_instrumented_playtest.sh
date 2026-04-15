#!/usr/bin/env bash
# Headless smoke: boot Main briefly + log stdout/stderr to Tests/logs/.
# Usage: from repo root: bash tools/run_instrumented_playtest.sh

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
LOG="Tests/logs/instrumented_playtest_${STAMP}.log"

export SKIP_SINGLE_INSTANCE=1

{
	echo "=============================================="
	echo "instrumented_playtest ${STAMP}"
	echo "repo: ${ROOT}"
	echo "godot: ${GODOT}"
	echo ">>> Main.tscn headless --quit-after 4"
	echo "=============================================="
	"$GODOT" --path "$ROOT" --headless --quit-after 4 2>&1
	echo ""
	echo "=============================================="
	echo "done: ${LOG}"
	echo "=============================================="
} 2>&1 | tee "$LOG"

echo ""
echo "Log written: $ROOT/$LOG"
