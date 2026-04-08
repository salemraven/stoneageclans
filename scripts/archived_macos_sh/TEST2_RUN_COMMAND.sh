#!/bin/bash

# Test 2: Performance Testing (Clean Mode)
# Runs the game for 5 minutes with minimal debug overhead to test performance

cd /Users/macbook/Desktop/stoneageclans

echo "Starting Test 2: Performance Testing (Clean Mode)"
echo "Duration: 5 minutes (300 seconds)"
echo "Output: Tests/test2_performance.log"
echo ""
echo "Press Ctrl+C to stop early"
echo ""

# Run Godot with minimal logging (no --debug flag for cleaner performance)
/Applications/Godot.app/Contents/MacOS/Godot --path . > Tests/test2_performance.log 2>&1 &
GODOT_PID=$!

echo "Game started (PID: $GODOT_PID)"
echo "Waiting 300 seconds (5 minutes)..."
echo ""

# Wait for 5 minutes
sleep 300

echo ""
echo "Test 2 complete!"
echo "Stopping game..."

# Try to gracefully stop the game
kill $GODOT_PID 2>/dev/null

# Wait a moment for cleanup
sleep 2

# Force kill if still running
kill -9 $GODOT_PID 2>/dev/null

echo ""
echo "Test 2 finished!"
echo "Check Tests/test2_performance.log for results"
echo ""
echo "Quick analysis:"
echo "  - Check for crashes: grep -i 'error\|crash\|fatal' Tests/test2_performance.log"
echo "  - Check frame times: grep -i 'frame\|fps\|delta' Tests/test2_performance.log"
echo "  - Check memory: grep -i 'memory\|mb\|kb' Tests/test2_performance.log"


