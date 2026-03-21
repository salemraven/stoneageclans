#!/bin/bash
# Test 1 - Caveman Priority and Logic Flow Analysis (2 Minutes)
# Focus: State transitions, priority evaluations, herding, gathering, depositing

cd /Users/macbook/Desktop/stoneageclans

echo "=========================================="
echo "Test 1 - Caveman Priority Analysis"
echo "Duration: 2 minutes (120 seconds)"
echo "Focus: Logic flow, priorities, herding, gathering, depositing"
echo "=========================================="
echo ""

# Clean up any previous log files
rm -f test1_caveman_priority.log
rm -f user://minigame_logs.txt 2>/dev/null

echo "Starting Godot with debug logging enabled..."
echo "Log file: test1_caveman_priority.log"
echo "MinigameLogger: user://minigame_logs.txt"
echo ""

# Run Godot with --debug and --verbose flags
# This enables all logging via DebugConfig
/Applications/Godot.app/Contents/MacOS/Godot --path . --debug --verbose > test1_caveman_priority.log 2>&1 &
GODOT_PID=$!

echo "Godot started (PID: $GODOT_PID)"
echo "Running for 120 seconds..."
echo "Press Ctrl+C to stop early"
echo ""

# Wait 2 minutes (120 seconds)
sleep 120

echo ""
echo "=========================================="
echo "Test Complete - Stopping Godot"
echo "=========================================="
kill $GODOT_PID 2>/dev/null
pkill -f "godot.*stoneageclans" 2>/dev/null
sleep 1

echo ""
echo "=== Quick Analysis ==="
if [ -f test1_caveman_priority.log ]; then
    echo "Log file size: $(wc -l < test1_caveman_priority.log) lines"
    echo ""
    echo "State changes:"
    grep -c "STATE_CHANGE\|State changed" test1_caveman_priority.log 2>/dev/null || echo "0"
    echo "Priority evaluations:"
    grep -c "PRIORITY_EVAL\|Priority eval" test1_caveman_priority.log 2>/dev/null || echo "0"
    echo "Herding events:"
    grep -c "herd\|HERD" test1_caveman_priority.log 2>/dev/null || echo "0"
    echo "Gathering events:"
    grep -c "gather\|GATHER" test1_caveman_priority.log 2>/dev/null || echo "0"
    echo "Depositing events:"
    grep -c "deposit\|DEPOSIT" test1_caveman_priority.log 2>/dev/null || echo "0"
    echo "Build events:"
    grep -c "build\|BUILD\|land_claim" test1_caveman_priority.log 2>/dev/null || echo "0"
    echo ""
    echo "Check test1_caveman_priority.log for full details"
    echo "Check user://minigame_logs.txt for MinigameLogger output"
else
    echo "ERROR: Log file not found!"
fi

echo ""
echo "Test finished!"
