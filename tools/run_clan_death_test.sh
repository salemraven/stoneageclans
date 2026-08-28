#!/usr/bin/env bash
# Headless Clan Death → MutationStore regression tests.
# Usage (repo root): bash tools/run_clan_death_test.sh

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

GODOT="${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}"
if [[ ! -x "$GODOT" ]]; then
	echo "ERROR: Godot not found at $GODOT — set GODOT=/path/to/Godot" >&2
	exit 1
fi

export SKIP_SINGLE_INSTANCE=1

echo ">>> Clan Death MutationStore headless tests (test_clan_death_mutation.gd)"
"$GODOT" --path "$ROOT" --headless --script res://tools/test_clan_death_mutation.gd 2>&1
