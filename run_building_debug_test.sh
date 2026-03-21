#!/bin/bash
# Run Godot for building-debug test; logs go to .cursor/debug.log
# Monitor with: tail -f .cursor/debug.log

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Clear debug log before run
DEBUG_LOG=".cursor/debug.log"
rm -f "$DEBUG_LOG"
echo "Cleared $DEBUG_LOG"

# Find Godot
GODOT_PATH="${GODOT_PATH:-/Applications/Godot.app/Contents/MacOS/Godot}"
if [ ! -f "$GODOT_PATH" ]; then
  GODOT_PATH="$HOME/Applications/Godot.app/Contents/MacOS/Godot"
fi
if [ ! -f "$GODOT_PATH" ]; then
  echo "Error: Godot not found. Set GODOT_PATH or install Godot."
  exit 1
fi

echo "Starting Godot (--headless --debug). Logs: $DEBUG_LOG"
echo "Run in another terminal: tail -f $DEBUG_LOG"
echo ""

# Run with display - user must place claim, Farm, Dairy, and herd a goat in
# (Headless has 0 cavemen; only player can herd, so we need the window)
echo "Game will open. Place claim, Farm, Dairy, herd a goat into claim. Run 2 min."
"$GODOT_PATH" --path . --debug > /tmp/godot_building_debug.log 2>&1 &
GODOT_PID=$!
echo "Godot PID: $GODOT_PID (run 120s)"
sleep 120
kill $GODOT_PID 2>/dev/null || true
wait $GODOT_PID 2>/dev/null || true
echo "Godot stopped."

echo ""
echo "=== Debug log ($DEBUG_LOG) ==="
if [ -f "$DEBUG_LOG" ]; then
  wc -l "$DEBUG_LOG"
  echo ""
  echo "--- Sample entries ---"
  head -20 "$DEBUG_LOG"
else
  echo "No debug log created."
fi
