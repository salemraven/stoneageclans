#!/bin/bash

# Test 3: Gather & Deposit Efficiency Test
# This script runs the game for 5 minutes and captures all gather/deposit activity

cd /Users/macbook/Desktop/stoneageclans

echo "=========================================="
echo "Test 3: Gather & Deposit Efficiency Test"
echo "=========================================="
echo ""
echo "This test will run for 5 minutes (300 seconds)"
echo "Monitoring gather and deposit efficiency..."
echo ""
echo "Starting test..."
echo ""

# Run Godot with full debug output
/Applications/Godot.app/Contents/MacOS/Godot --path . --debug --verbose > Tests/test3_gather_deposit_efficiency.log 2>&1 &
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
echo "Log file: Tests/test3_gather_deposit_efficiency.log"
echo ""
echo "Quick Analysis:"
echo "  Successful gathers: $(grep -c "✅ GATHER:" Tests/test3_gather_deposit_efficiency.log 2>/dev/null || echo "0")"
echo "  Successful deposits: $(grep -c "✅ DEPOSIT SUCCESS:" Tests/test3_gather_deposit_efficiency.log 2>/dev/null || echo "0")"
echo "  Search mode activations: $(grep -c "🔍 SEARCH MODE:" Tests/test3_gather_deposit_efficiency.log 2>/dev/null || echo "0")"
echo ""
echo "Next steps:"
echo "  1. Review the log file for detailed metrics"
echo "  2. Run: ./Tests/TEST3_ANALYZE.sh for quick analysis"
echo "  3. Create analysis report: Tests/TEST3_GATHER_DEPOSIT_EFFICIENCY_ANALYSIS.md"
echo ""


