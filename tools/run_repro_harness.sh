#!/usr/bin/env bash
# Headless reproduction harness: isolated land claim + woman + Living Hut + Player as father.
# Exits 0 after 2 births (validates Player designated-father eligibility).
# Usage (repo root): SKIP_SINGLE_INSTANCE=1 bash tools/run_repro_harness.sh
# Env: GODOT=/path/to/Godot (default: macOS app path)

set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

GODOT="${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}"
if [[ ! -x "$GODOT" ]]; then
	echo "ERROR: Godot not found at $GODOT — set GODOT=" >&2
	exit 1
fi

export SKIP_SINGLE_INSTANCE=1

STAMP="$(date +%Y%m%d_%H%M%S)"
LOG="Tests/logs/repro_harness_${STAMP}.log"
mkdir -p Tests/logs

echo "Running repro harness → $LOG"
set +e
"$GODOT" --path "$ROOT" --headless -- --repro-harness 2>&1 | tee "$LOG"
EC=${PIPESTATUS[0]}
set -e
echo "exit_code=$EC"
exit "$EC"
