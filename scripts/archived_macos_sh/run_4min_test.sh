#!/bin/bash
# Run 4-min productivity test with live data monitoring
# Game auto-quits at 240s. Data: Tests/playtest_session.jsonl
#
# Usage: ./run_4min_test.sh

set -e
cd "$(dirname "$0")"
LOG_DIR="${GODOT_TEST_LOG_DIR:-$PWD/Tests}"
mkdir -p "$LOG_DIR"
export GODOT_TEST_LOG_DIR="$LOG_DIR"
LOG_FILE="$LOG_DIR/playtest_session.jsonl"

GODOT="${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}"
if [ ! -x "$GODOT" ]; then
  echo "Godot not found at $GODOT"
  exit 1
fi

echo "=== 4-min Productivity Test ==="
echo "Data: $LOG_FILE"
echo "Game will auto-quit at 240s. Play normally (place claim, gather, herd)."
echo ""

# Clear previous run
rm -f "$LOG_FILE"

# Start Godot in background (-- before user args so get_cmdline_user_args() sees them)
"$GODOT" --path . -- --playtest-4min &
GODOT_PID=$!

# Wait for log to appear
for i in $(seq 1 30); do
  [ -f "$LOG_FILE" ] && break
  sleep 0.5
done

if [ ! -f "$LOG_FILE" ]; then
  echo "Log not created after 15s. Game may have failed to start."
  kill $GODOT_PID 2>/dev/null || true
  exit 1
fi

echo "Monitoring snapshots (state_counts, herders, fps)..."
echo "---"

# Tail log in background; when Godot exits (240s), we stop
(
  tail -f "$LOG_FILE" 2>/dev/null | while read -r line; do
    if echo "$line" | grep -q '"evt":"snapshot"'; then
      t=$(echo "$line" | grep -o '"t":[0-9.]*' | cut -d: -f2)
      fps=$(echo "$line" | grep -o '"fps":[0-9]*' | cut -d: -f2)
      herd=$(echo "$line" | grep -o '"in_herd_wildnpc":[0-9]*' | cut -d: -f2)
      states=$(echo "$line" | grep -o '"state_counts":{[^}]*}' | sed 's/"state_counts"://')
      printf "[%5.1fs] fps=%s herders=%s states=%s\n" "$t" "$fps" "$herd" "$states"
    elif echo "$line" | grep -q '"evt":"session_start"'; then
      echo "Session started"
    elif echo "$line" | grep -q '"evt":"test_run_ended_2min"'; then
      echo "--- Test ended (240s) ---"
    fi
  done
) &
TAIL_PID=$!

# Wait for Godot to exit (auto-quit at 240s)
wait $GODOT_PID 2>/dev/null || true
kill $TAIL_PID 2>/dev/null || true
echo ""
echo "Done. Full data: $LOG_FILE"
