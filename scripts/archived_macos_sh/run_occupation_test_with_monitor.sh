#!/bin/bash
# Occupation test with live log monitor
# Runs the game with --occupation-diag and tails the log in real time.
#
# Usage:
#   ./Tests/run_occupation_test_with_monitor.sh         # Normal run
#   ./Tests/run_occupation_test_with_monitor.sh --force # Clear stuck lock and run
#
# Play in the game window while watching the log. Press Ctrl+C to stop both.

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TESTS_DIR="$SCRIPT_DIR"
LOG_PATTERN="$TESTS_DIR/occupation_diag_*.log"
GAME_CONSOLE_LOG="$TESTS_DIR/game_console.log"

cd "$PROJECT_ROOT"

# --force: clear lock and run anyway
FORCE=0
[ "$1" = "--force" ] && FORCE=1

# Ensure only one game instance - use lock dir (atomic)
LOCK_DIR="$TESTS_DIR/.stoneageclans_playtest.lock"
LOCK_PID_FILE="$LOCK_DIR/pid"
if [ -d "$LOCK_DIR" ]; then
  # Stale lock? Only remove if stored PID is dead (or no pid file). --force only clears stale locks.
  REMOVE=1
  if [ -f "$LOCK_PID_FILE" ]; then
    OLD_PID=$(cat "$LOCK_PID_FILE" 2>/dev/null)
    if [ -n "$OLD_PID" ] && kill -0 "$OLD_PID" 2>/dev/null; then
      REMOVE=0  # Game actually running - never override, even with --force
    fi
  fi
  if [ "$REMOVE" = 1 ]; then
    [ "$FORCE" = 1 ] && echo "Force: clearing stale lock..."
    rm -rf "$LOCK_DIR" 2>/dev/null || true
  fi
fi
if ! mkdir "$LOCK_DIR" 2>/dev/null; then
  echo "Error: StoneAgeClans playtest is already running."
  echo "Close the existing game window first. (--force only clears stale locks, not running instances.)"
  exit 1
fi

GODOT="${GODOT:-$(command -v godot 2>/dev/null || echo /Applications/Godot.app/Contents/MacOS/Godot)}"
if [ ! -x "$GODOT" ]; then
  GODOT="/Applications/Godot.app/Contents/MacOS/Godot"
fi

echo "=== Occupation Test with Live Monitor ==="
echo "Project: $PROJECT_ROOT"
echo ""
echo "Starting game... (Godot output -> $GAME_CONSOLE_LOG)"
echo "This terminal will show occupation events only."
echo "Press Ctrl+C to stop."
echo ""

# Start Godot in background; redirect stdout/stderr so terminal stays clean
"$GODOT" --path . --occupation-diag >> "$GAME_CONSOLE_LOG" 2>&1 &
GODOT_PID=$!
echo $GODOT_PID > "$LOCK_PID_FILE" 2>/dev/null || true

# Give game time to create new log (must be long enough for Godot to load)
sleep 4

# Newest log by mtime = current session (game creates it on load)
LOG_FILE=$(ls -t $LOG_PATTERN 2>/dev/null | head -1)
if [ -n "$LOG_FILE" ] && [ -f "$LOG_FILE" ]; then
  echo "Monitoring: $(basename "$LOG_FILE")"
  echo "---"
fi

if [ -z "$LOG_FILE" ] || [ ! -f "$LOG_FILE" ]; then
  echo "Warning: No new log yet. Tailing newest when it appears..."
  LOG_FILE=$(ls -t $LOG_PATTERN 2>/dev/null | head -1)
fi

# Cleanup on exit
cleanup() {
  echo ""
  echo "Stopping game..."
  kill $GODOT_PID 2>/dev/null || true
  rm -rf "$LOCK_DIR" 2>/dev/null || true
  exit 0
}
trap cleanup SIGINT SIGTERM

# Tail the log (or wait and tail when it appears)
if [ -n "$LOG_FILE" ] && [ -f "$LOG_FILE" ]; then
  tail -f "$LOG_FILE"
else
  while true; do
    LOG_FILE=$(ls -t $LOG_PATTERN 2>/dev/null | head -1)
    if [ -n "$LOG_FILE" ] && [ -f "$LOG_FILE" ]; then
      echo "Monitoring: $(basename "$LOG_FILE")"
      echo "---"
      tail -f "$LOG_FILE"
      break
    fi
    sleep 0.5
  done
fi
