#!/bin/bash
# Test 1 - Caveman Behavior Analysis (2 Minutes)
# This script runs Godot with all debug logging enabled to collect caveman NPC data

# Get the directory where this script is located, then go to project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

echo "=== Starting Test 1 - Caveman Behavior Analysis ==="
echo "Duration: 2 minutes"
echo "Log file: Tests/test1_caveman_data.log"
echo "Focus: Land claim placement, gathering, and depositing cycle"
echo ""

# Run Godot with debug flags and enable logging via command line
# --debug: Enables debug mode
# --verbose: Verbose output
# --enable-logging: Custom flag to enable logging (if supported)
/Applications/Godot.app/Contents/MacOS/Godot --path . --headless --debug --verbose > Tests/test1_caveman_data.log 2>&1 &
GODOT_PID=$!

echo "Godot started with PID: $GODOT_PID"
echo "Running for 120 seconds..."
echo ""

# Wait 2 minutes (120 seconds)
sleep 120

echo ""
echo "=== Test Complete - Stopping Godot ==="
kill $GODOT_PID 2>/dev/null
pkill -f "godot.*stoneageclans" 2>/dev/null
sleep 2

echo "Test finished. Analyzing results..."
echo ""
echo "=== Test 1 Analysis - Caveman NPC Behavior ==="
echo ""
echo "LAND CLAIM PLACEMENT:"
grep -i "land.*claim.*placed\|build_land_claim.*complete" Tests/test1_caveman_data.log | wc -l | xargs echo "  Total placements:"
grep -i "build_land_claim.*complete" Tests/test1_caveman_data.log | head -5
echo ""
echo "GATHERING EVENTS:"
grep -i "gather.*complete\|NPC.*gathered" Tests/test1_caveman_data.log | wc -l | xargs echo "  Total gathers:"
grep -i "NPC.*gathered" Tests/test1_caveman_data.log | head -5
echo ""
echo "DEPOSITING EVENTS:"
grep -i "auto-deposit\|deposit.*complete\|deposited.*items" Tests/test1_caveman_data.log | wc -l | xargs echo "  Total deposits:"
grep -i "auto-deposited\|deposit.*complete" Tests/test1_caveman_data.log | head -5
echo ""
echo "STATE CHANGES:"
grep -i "state.*change\|entered.*state\|exited.*state" Tests/test1_caveman_data.log | wc -l | xargs echo "  Total state changes:"
echo ""
echo "CAVEMAN ACTIVITY SUMMARY:"
grep -i "Caveman.*\|caveman.*" Tests/test1_caveman_data.log | grep -i "gather\|deposit\|build" | wc -l | xargs echo "  Total caveman actions:"
echo ""
echo "Full log saved to: Tests/test1_caveman_data.log"

