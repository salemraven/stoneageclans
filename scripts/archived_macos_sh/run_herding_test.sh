#!/bin/bash
# Run herding test for N seconds, capture log, print summary
# Usage: ./Tests/run_herding_test.sh [duration_sec] [log_name]
# Example: ./Tests/run_herding_test.sh 120 test_phase1.log

cd "$(dirname "$0")/.."
DURATION=${1:-120}
LOG_NAME=${2:-"Tests/herding_test_$(date +%Y%m%d_%H%M%S).log"}
LOG_PATH="$LOG_NAME"

echo "=========================================="
echo "Herding Test - Duration: ${DURATION}s"
echo "=========================================="
echo "Log: $LOG_PATH"
echo ""

/Applications/Godot.app/Contents/MacOS/Godot --path . --verbose 2>&1 | tee "$LOG_PATH" &
GODOT_PID=$!
echo "Godot PID: $GODOT_PID"
sleep "$DURATION"
kill $GODOT_PID 2>/dev/null || true
wait $GODOT_PID 2>/dev/null || true

echo ""
echo "=========================================="
echo "Summary"
echo "=========================================="
echo "  Herding deliveries: $(grep -c "Competition:.*herded" "$LOG_PATH" 2>/dev/null || echo "0")"
echo "  NPCs joined clan: $(grep -c "joined clan" "$LOG_PATH" 2>/dev/null || echo "0")"
echo "  Resist events: $(grep -c "Resist:" "$LOG_PATH" 2>/dev/null || echo "0")"
echo "  herd_wildnpc enter: $(grep -c "Action started: herd_wildnpc" "$LOG_PATH" 2>/dev/null || echo "0")"
echo "  Deposit events: $(grep -c "📊 Competition:.*deposited" "$LOG_PATH" 2>/dev/null || echo "0")"
if grep -q "GATHERING WINNER\|HERDING WINNER" "$LOG_PATH" 2>/dev/null; then
  echo ""
  grep "GATHERING WINNER\|HERDING WINNER" "$LOG_PATH"
fi
echo ""
