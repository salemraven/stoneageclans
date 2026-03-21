#!/bin/bash

# Test 3: Herding System Verification
# Runs the game for 3 minutes to verify herding behavior matches the guides

GODOT_PATH="/Applications/Godot.app/Contents/MacOS/Godot"
PROJECT_PATH="/Users/macbook/Desktop/stoneageclans"
LOG_FILE="$PROJECT_PATH/Tests/test3_herding_system.log"
DURATION=180 # 3 minutes in seconds

echo "=========================================="
echo "Test 3: Herding System Verification"
echo "=========================================="
echo "Log file: $LOG_FILE"
echo "Duration: $DURATION seconds (3 minutes)"
echo ""
echo "Testing herding system behavior:"
echo "- Cavemen with land claims can herd wild NPCs"
echo "- Wild NPCs follow cavemen when within 150px"
echo "- NPCs join clan when inside land claim radius"
echo "- Competition between cavemen for wild NPCs"
echo ""
echo "Starting game..."
echo ""

# Clear old log file
> "$LOG_FILE"

# Run Godot in background
"$GODOT_PATH" --path "$PROJECT_PATH" --debug --verbose > "$LOG_FILE" 2>&1 &
GODOT_PID=$!

echo "Godot process started with PID: $GODOT_PID"
echo "Monitoring for crashes..."

# Crash detection variables
STARTUP_TIMEOUT=15  # Wait 15 seconds for startup
CHECK_INTERVAL=5    # Check every 5 seconds
ELAPSED=0
STARTUP_COMPLETE=false
CRASH_DETECTED=false

# Wait for initial startup (game should initialize within 15 seconds)
while [ $ELAPSED -lt $STARTUP_TIMEOUT ]; do
    sleep 1
    ELAPSED=$((ELAPSED + 1))
    
    # Check if process is still running
    if ! kill -0 $GODOT_PID 2>/dev/null; then
        echo ""
        echo "❌ CRASH DETECTED: Game process died during startup (after ${ELAPSED}s)"
        CRASH_DETECTED=true
        break
    fi
    
    # Check log for startup indicators
    if grep -qi "Console Logger Started\|NPC.*initialized\|Spawning" "$LOG_FILE" 2>/dev/null; then
        STARTUP_COMPLETE=true
        echo "✅ Game startup detected (${ELAPSED}s)"
        break
    fi
done

# If startup didn't complete, check for crash
if [ "$STARTUP_COMPLETE" = false ] && [ "$CRASH_DETECTED" = false ]; then
    if ! kill -0 $GODOT_PID 2>/dev/null; then
        echo ""
        echo "❌ CRASH DETECTED: Game process died before startup completed"
        CRASH_DETECTED=true
    else
        # Check for crash indicators in log
        if grep -qi "SCRIPT ERROR\|FATAL\|Segmentation fault\|Abort trap\|Assertion failed" "$LOG_FILE" 2>/dev/null; then
            echo ""
            echo "❌ CRASH DETECTED: Error found in log during startup"
            CRASH_DETECTED=true
            kill $GODOT_PID 2>/dev/null
        fi
    fi
fi

# If crash detected, show error and exit
if [ "$CRASH_DETECTED" = true ]; then
    echo ""
    echo "=========================================="
    echo "❌ TEST FAILED: Game crashed on startup"
    echo "=========================================="
    echo ""
    echo "Last 50 lines of log:"
    echo "---"
    tail -n 50 "$LOG_FILE"
    echo "---"
    echo ""
    echo "Common crash indicators found:"
    grep -i "ERROR\|CRITICAL\|EXCEPTION\|FATAL\|Invalid\|Null\|crash" "$LOG_FILE" | tail -n 20 || echo "None"
    echo ""
    exit 1
fi

# Main monitoring loop - run for duration or until crash
ELAPSED=0
while [ $ELAPSED -lt $DURATION ]; do
    sleep $CHECK_INTERVAL
    ELAPSED=$((ELAPSED + CHECK_INTERVAL))
    
    # Check if process is still running
    if ! kill -0 $GODOT_PID 2>/dev/null; then
        echo ""
        echo "❌ CRASH DETECTED: Game process died during test (after ${ELAPSED}s)"
        CRASH_DETECTED=true
        break
    fi
    
    # Check log for critical crash indicators (process-dying errors)
    if grep -qi "Invalid.*Nil.*global_position\|FATAL\|Segmentation fault\|Abort trap\|Assertion failed" "$LOG_FILE" 2>/dev/null; then
        # Check if process is still alive - if error occurred and process died, it's a crash
        sleep 1  # Brief pause to see if process dies
        if ! kill -0 $GODOT_PID 2>/dev/null; then
            echo ""
            echo "❌ CRASH DETECTED: Game process died after critical error"
            CRASH_DETECTED=true
            break
        fi
    fi
    
    # Progress indicator
    if [ $((ELAPSED % 30)) -eq 0 ]; then
        echo "  ⏱️  Test running... ${ELAPSED}s / ${DURATION}s"
    fi
done

# Kill the game if still running
if kill -0 $GODOT_PID 2>/dev/null; then
    echo ""
    echo "Stopping game process..."
    kill $GODOT_PID 2>/dev/null
    wait $GODOT_PID 2>/dev/null
else
    echo ""
    echo "Game process already terminated"
fi

# Check final status
if [ "$CRASH_DETECTED" = true ]; then
    echo ""
    echo "=========================================="
    echo "❌ TEST FAILED: Game crashed during test"
    echo "=========================================="
    echo ""
    echo "Crash occurred after ${ELAPSED} seconds"
    echo ""
    echo "Last 100 lines of log:"
    echo "---"
    tail -n 100 "$LOG_FILE"
    echo "---"
    echo ""
    echo "Error summary:"
    grep -i "ERROR\|CRITICAL\|EXCEPTION\|FATAL\|Invalid.*Nil\|Null\|crash" "$LOG_FILE" | tail -n 30 || echo "None found"
    echo ""
    exit 1
fi

echo ""
echo "=========================================="
echo "Test 3 finished!"
echo "=========================================="
echo ""
echo "🔍 ENHANCED MOVEMENT & HERDING ANALYSIS"
echo "=========================================="
echo ""

# Extract all NPC positions and create movement tracking
echo "=== 📊 NPC Position & Movement Tracking ==="
echo ""

# Find all unique NPCs that were active
echo "Active NPCs tracked:"
grep -o "📍 POSITION: [^ ]*" "$LOG_FILE" | sed 's/📍 POSITION: //' | sort -u | head -20

echo ""
echo "=== 🐑 Herding Activity Summary ==="
echo ""

# Count herding events
HERDING_STARTED=$(grep -c "started following" "$LOG_FILE" || echo "0")
HERDING_SWITCHED=$(grep -c "switched from\|switched to" "$LOG_FILE" || echo "0")
HERDING_BROKEN=$(grep -c "lost herder\|herd_broken" "$LOG_FILE" || echo "0")
CLAN_JOINED=$(grep -c "joined.*clan" "$LOG_FILE" || echo "0")

echo "Herding Started: $HERDING_STARTED"
echo "Herder Switched: $HERDING_SWITCHED"
echo "Herding Broken: $HERDING_BROKEN"
echo "Clan Joined: $CLAN_JOINED"
echo ""

# Analyze caveman herd_wildnpc state entries
echo "=== 👨 Caveman Herding Behavior ==="
CAVEMAN_HERD_STATES=$(grep -c "entered herd_wildnpc" "$LOG_FILE" || echo "0")
echo "Cavemen entered herd_wildnpc state: $CAVEMAN_HERD_STATES times"
if [ "$CAVEMAN_HERD_STATES" -eq "0" ]; then
    echo "⚠️  WARNING: Cavemen never entered herd_wildnpc state!"
    echo ""
    echo "Reasons why cavemen might not herd:"
    grep "herd_wildnpc.*false\|no_women_in_range\|no_land_claim\|inventory_full" "$LOG_FILE" | tail -n 10
fi
echo ""

# Track specific herding sequences
echo "=== 🔄 Complete Herding Sequences ==="
echo ""
echo "Sequences where NPCs were successfully herded:"
grep -B 2 -A 5 "started following" "$LOG_FILE" | grep -E "started following|entered herd|joined.*clan|lost herder" | head -n 30

echo ""
echo "=== 📍 Position Jump Detection (Teleportation) ==="
# This would require comparing sequential positions - for now just flag huge distances
echo "Large distance events detected:"
grep -E "outside.*range.*[0-9]{4,}|lost herder.*[0-9]{4,}" "$LOG_FILE" | tail -n 10 || echo "No large jumps detected"

echo ""
echo "=== 🐑 Individual NPC Herding Behavior ==="
echo ""

# Track each herdable NPC's behavior
for npc_type in "Sheep" "Goat" "Woman"; do
    echo "--- $npc_type Herding Events ---"
    grep -i "$npc_type.*started following\|$npc_type.*switched\|$npc_type.*lost herder\|$npc_type.*joined.*clan" "$LOG_FILE" | tail -n 15
    echo ""
done

echo "=== 🎯 Caveman Position vs Wild NPC Detection ==="
echo ""
echo "Caveman positions when detecting wild NPCs:"
grep -B 3 "wild_herdable_npc_in_range\|can_enter.*herd_wildnpc.*true" "$LOG_FILE" | grep "POSITION.*caveman\|POSITION.*NPC.*caveman" | tail -n 10 || echo "No detection events found"

echo ""
echo "=== 🔍 Reverse Herding Detection ==="
echo ""
echo "Checking for reverse herding patterns (caveman following sheep):"
# Look for patterns where caveman is in herd_wildnpc and sheep position is ahead
# This is complex to detect from logs alone, so we'll flag suspicious patterns
REVERSE_SUSPICIOUS=$(grep -c "switched.*NPC\|lost herder.*495[0-9]" "$LOG_FILE" || echo "0")
if [ "$REVERSE_SUSPICIOUS" -gt "0" ]; then
    echo "⚠️  Potential reverse herding detected - found $REVERSE_SUSPICIOUS suspicious patterns"
    grep "switched.*NPC\|lost herder.*495" "$LOG_FILE" | tail -n 5
else
    echo "✅ No obvious reverse herding patterns detected"
fi

echo ""
echo "=== 📈 Movement Velocity Analysis ==="
echo ""
echo "High velocity movements (potential issues):"
# Extract velocities > 200 (unusually fast)
grep "POSITION.*velocity=[2-9][0-9][0-9]\|velocity=[1-9][0-9][0-9][0-9]" "$LOG_FILE" | tail -n 20 || echo "No high velocity movements detected"

echo ""
echo "=== 🚫 State Change Issues ==="
echo ""
echo "Rapid state changes (potential stuck behavior):"
grep -E "STATE_EXIT.*after [0-2]\.[0-9]s|STATE_DURATION.*LONG" "$LOG_FILE" | tail -n 15 || echo "No rapid state changes detected"

echo ""
echo "=== 🎯 Target Tracking ==="
echo ""
echo "Caveman target updates (herd_wildnpc state):"
grep -i "target_woman\|find_woman_to_herd\|wild.*herdable.*in_range" "$LOG_FILE" | tail -n 20 || echo "No target tracking found"

echo ""
echo "=== 📊 Distance Analysis ==="
echo ""
echo "Herd distance events:"
echo "Distances when herding started:"
grep "started following.*distance:" "$LOG_FILE" | sed 's/.*distance: \([0-9.]*\).*/\1/' | sort -n | head -5
echo "..."
grep "started following.*distance:" "$LOG_FILE" | sed 's/.*distance: \([0-9.]*\).*/\1/' | sort -n | tail -5

echo ""
echo "Distances when herding broke:"
grep "lost herder\|outside.*range" "$LOG_FILE" | sed 's/.*range: \([0-9.]*\).*/\1/; s/.*> \([0-9.]*\).*/\1/' | grep -E "^[0-9]" | sort -n | head -10

echo ""
echo "=== 🔄 Herding State Transitions ==="
echo ""
echo "Complete state transition sequences:"
grep -E "STATE_ENTRY.*herd|STATE_EXIT.*herd|entered herd|exited.*herd" "$LOG_FILE" | tail -n 30

echo ""
echo "=== ❌ Errors & Issues ==="
ERROR_COUNT=$(grep -ci "error\|critical\|exception\|fatal\|invalid\|null" "$LOG_FILE" || echo "0")
echo "Total errors/warnings found: $ERROR_COUNT"
if [ "$ERROR_COUNT" -gt "0" ]; then
    echo ""
    echo "Recent errors:"
    grep -i "ERROR\|CRITICAL\|EXCEPTION\|FATAL\|Invalid\|Null" "$LOG_FILE" | tail -n 20
fi

echo ""
echo "=== 📍 Complete Position Timeline (Last 50 entries) ==="
echo ""
tail -n 500 "$LOG_FILE" | grep "POSITION:" | tail -n 50

echo ""
echo "=========================================="
echo "📋 Full log available at: $LOG_FILE"
echo "=========================================="
echo ""
echo "Next: Review detailed analysis above for herding issues"

