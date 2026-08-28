#!/usr/bin/env bash
# Headless Dynamic Baby Cap regression tests.
# Usage (repo root): bash tools/run_baby_cap_test.sh

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

GODOT="${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}"
if [[ ! -x "$GODOT" ]]; then
	echo "ERROR: Godot not found at $GODOT — set GODOT=/path/to/Godot" >&2
	exit 1
fi

export SKIP_SINGLE_INSTANCE=1

echo ">>> Baby Cap headless tests (test_baby_cap.gd)"
"$GODOT" --path "$ROOT" --headless --script res://tools/test_baby_cap.gd 2>&1
