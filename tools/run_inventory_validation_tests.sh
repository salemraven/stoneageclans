#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GODOT="${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}"
export SKIP_SINGLE_INSTANCE=1
export SKIP_RUNTIME_FAULT_SINK=1
cd "$ROOT"
echo "Running inventory validation tests..."
test_log="$(mktemp)"
set +e
"$GODOT" --path "$ROOT" --headless -s res://tools/test_inventory_validation.gd 2>&1 | tee "$test_log"
test_status=$?
set -e
if ! grep -q "TEST_INVENTORY_VALIDATION: all 13 checks passed" "$test_log"; then
  echo "Inventory validation tests FAILED (exit $test_status)"
  rm -f "$test_log"
  exit 1
fi
rm -f "$test_log"
echo "Running Main.tscn smoke boot..."
"$GODOT" --path "$ROOT" --headless --quit-after 4 res://scenes/Main.tscn >/dev/null
echo "Inventory validation pipeline: OK"
