#!/usr/bin/env bash
# Headless Nomad Mode regression (campfire wood burn, panic, ABANDON flow helpers).
# Usage (repo root): bash tools/run_nomad_mode_test.sh
# See: bible/camp_relocation.md, tools/test_nomad_mode.gd

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

GODOT="${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}"
if [[ ! -x "$GODOT" ]]; then
	echo "ERROR: Godot not found at $GODOT — set GODOT=/path/to/Godot" >&2
	exit 1
fi

export SKIP_SINGLE_INSTANCE=1

echo ">>> Nomad Mode headless tests (test_nomad_mode.gd)"
"$GODOT" --path "$ROOT" --headless --script res://tools/test_nomad_mode.gd 2>&1
