#!/bin/bash

# Test 2: Verify Gather/Deposit Improvements
# Runs the game for 5 minutes to verify the distance-based threshold fix

cd /Users/macbook/Desktop/stoneageclans

echo "=========================================="
echo "Test 2: Verify Gather/Deposit Improvements"
echo "=========================================="
echo ""
echo "This test will run for 5 minutes (300 seconds)"
echo "Monitoring gather/deposit efficiency improvements..."
echo ""
echo "Improvements to verify:"
echo "  - Distance-based threshold fix (deposit at 80% when far)"
echo "  - Gather/deposit cycle efficiency"
echo "  - Overall system performance"
echo ""
echo "Starting test..."
echo ""

# Run Godot with verbose logging to capture gather/deposit activity
/Applications/Godot.app/Contents/MacOS/Godot --path . --verbose > Tests/test2_improvements_verification.log 2>&1 &
GODOT_PID=$!

# Wait for 5 minutes (300 seconds)
echo "Test running... (PID: $GODOT_PID)"
echo "Press Ctrl+C to stop early, or wait 5 minutes"
echo ""

# Countdown timer
for i in {300..1}; do
    printf "\rTime remaining: %3d seconds" $i
    sleep 1
done
echo ""

# Stop the game
echo ""
echo "Stopping test..."
kill $GODOT_PID 2>/dev/null
wait $GODOT_PID 2>/dev/null

echo ""
echo "=========================================="
echo "Test Complete!"
echo "=========================================="
echo ""
echo "Log file: Tests/test2_improvements_verification.log"
echo ""
echo "Quick Analysis:"
echo "  Successful gathers: $(grep -c "✅ GATHER:" Tests/test2_improvements_verification.log 2>/dev/null || echo "0")"
echo "  Successful deposits: $(grep -c "✅ DEPOSIT SUCCESS:" Tests/test2_improvements_verification.log 2>/dev/null || echo "0")"
echo "  Deposit cycles: $(grep -c "📍 DEPOSIT.*entered land claim" Tests/test2_improvements_verification.log 2>/dev/null || echo "0")"
echo ""
echo "Next steps:"
echo "  1. Review the log file for detailed metrics"
echo "  2. Compare with Test 3 results"
echo "  3. Verify distance-based threshold is working"
echo ""


