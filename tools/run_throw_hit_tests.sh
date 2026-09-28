#!/usr/bin/env bash
# Headless throw-hit geometry lock-in.
# Usage (repo root): bash tools/run_throw_hit_tests.sh

set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GODOT="${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}"
export SKIP_SINGLE_INSTANCE=1
cd "$ROOT"

echo "=== Throw hit resolver test ==="
set +e
log="$("$GODOT" --path "$ROOT" --headless -s res://tools/test_throw_hit.gd 2>&1)"
status=$?
set -e
echo "$log"
if [[ $status -ne 0 ]] || ! grep -q "TEST_THROW_HIT: all checks passed" <<<"$log"; then
	echo "Throw hit test FAILED"
	exit 1
fi
echo "Throw hit pipeline: OK"
