#!/bin/bash
# Playtest prep - verify environment and print run commands
# Usage: ./playtest_prep.sh

set -e
cd "$(dirname "$0")"

GODOT="${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}"
LOG_DIR="${GODOT_TEST_LOG_DIR:-$PWD/Tests}"

echo "=== Playtest Prep ==="
echo ""

# 1. Godot check
if [ ! -x "$GODOT" ]; then
  echo "❌ Godot not found at $GODOT"
  echo "   Set GODOT env var or install Godot"
  exit 1
fi
echo "✓ Godot: $GODOT"

# 2. Quick load test (headless)
echo "✓ Verifying game loads..."
OUT=$("$GODOT" --path . --headless --quit 2>&1) || true
# Ignore engine exit leaks (RID, resources at exit) - common with --quit
if echo "$OUT" | grep -qE "Parse error|SCRIPT ERROR|CRITICAL"; then
  echo "❌ Game reported critical errors on load"
  echo "$OUT" | grep -E "Parse error|SCRIPT ERROR|CRITICAL" | head -5
  exit 1
fi
echo "✓ Game loads OK"
echo ""

# 3. Print run commands
echo "--- Run Commands ---"
echo "  Normal play:       ./run_playtest.sh"
echo "  2-min capture:    ./run_2min_test.sh"
echo "  4-min capture:    ./run_4min_test.sh"
echo "  Agro/combat:      godot --path . -- --agro-combat-test"
echo "  Raid test:        godot --path . -- --raid-test"
echo ""
echo "  Reporter:         godot --path . -s scripts/logging/playtest_reporter.gd [path_to.jsonl]"
echo "  Data dir:         $LOG_DIR (2min/4min) or user:// (agro/raid)"
echo ""
echo "  Early game focus: campfire, travois, clansmen carry travois, NPC death drops travois"
echo ""
