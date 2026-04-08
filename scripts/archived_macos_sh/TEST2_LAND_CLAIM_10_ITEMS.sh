#!/bin/bash

# Test 2: Measure Time to Gather 10 of Each Item in Land Claim
# This test monitors how long it takes for a caveman to gather 10 of each resource type
# (BERRIES, WOOD, STONE, FIBER, GRAIN) in their land claim building inventory

cd /Users/macbook/Desktop/stoneageclans

echo "=========================================="
echo "Test 2: Land Claim 10 Items Gathering Time"
echo "=========================================="
echo ""
echo "This test will run until a caveman has gathered:"
echo "  - 10 Berries"
echo "  - 10 Wood"
echo "  - 10 Stone"
echo "  - 10 Fiber"
echo "  - 10 Grain"
echo ""
echo "in their land claim building inventory."
echo ""
echo "Starting test..."
echo ""

# Run Godot with verbose logging to capture deposit activity
/Applications/Godot.app/Contents/MacOS/Godot --path . --verbose > Tests/test2_land_claim_10_items.log 2>&1 &
GODOT_PID=$!

echo "Test running... (PID: $GODOT_PID)"
echo "Monitoring land claim inventory levels..."
echo ""
echo "The test will run until completion or timeout (10 minutes max)"
echo ""

# Monitor the log file for land claim inventory reaching 10 of each type
START_TIME=$(date +%s)
TIMEOUT=600  # 10 minutes max
CHECK_INTERVAL=5  # Check every 5 seconds

while true; do
    # Check if process is still running
    if ! ps -p $GODOT_PID > /dev/null 2>&1; then
        echo "Game process ended."
        break
    fi
    
    # Check elapsed time
    ELAPSED=$(($(date +%s) - $START_TIME))
    if [ $ELAPSED -ge $TIMEOUT ]; then
        echo "Timeout reached (10 minutes)."
        kill $GODOT_PID 2>/dev/null
        break
    fi
    
    # Check log for land claim inventory levels
    # Look for deposit success messages and count items per type
    if [ -f "Tests/test2_land_claim_10_items.log" ]; then
        # Extract latest inventory counts from deposit success messages
        BERRIES=$(grep "DEPOSIT SUCCESS.*Berries" Tests/test2_land_claim_10_items.log | tail -1 | grep -o "now has [0-9]* Berries" | grep -o "[0-9]*" || echo "0")
        WOOD=$(grep "DEPOSIT SUCCESS.*Wood" Tests/test2_land_claim_10_items.log | tail -1 | grep -o "now has [0-9]* Wood" | grep -o "[0-9]*" || echo "0")
        STONE=$(grep "DEPOSIT SUCCESS.*Stone" Tests/test2_land_claim_10_items.log | tail -1 | grep -o "now has [0-9]* Stone" | grep -o "[0-9]*" || echo "0")
        FIBER=$(grep "DEPOSIT SUCCESS.*Fiber" Tests/test2_land_claim_10_items.log | tail -1 | grep -o "now has [0-9]* Fiber" | grep -o "[0-9]*" || echo "0")
        GRAIN=$(grep "DEPOSIT SUCCESS.*Grain" Tests/test2_land_claim_10_items.log | tail -1 | grep -o "now has [0-9]* Grain" | grep -o "[0-9]*" || echo "0")
        
        # Display progress
        printf "\r[%02d:%02d] Progress: Berries=%2s Wood=%2s Stone=%2s Fiber=%2s Grain=%2s" \
            $((ELAPSED/60)) $((ELAPSED%60)) \
            "${BERRIES:-0}" "${WOOD:-0}" "${STONE:-0}" "${FIBER:-0}" "${GRAIN:-0}"
        
        # Check if all reached 10
        if [ "${BERRIES:-0}" -ge 10 ] && [ "${WOOD:-0}" -ge 10 ] && [ "${STONE:-0}" -ge 10 ] && [ "${FIBER:-0}" -ge 10 ] && [ "${GRAIN:-0}" -ge 10 ]; then
            echo ""
            echo ""
            echo "✅ SUCCESS! All items reached 10!"
            echo "Time taken: $((ELAPSED/60)) minutes $((ELAPSED%60)) seconds"
            kill $GODOT_PID 2>/dev/null
            break
        fi
    fi
    
    sleep $CHECK_INTERVAL
done

# Wait for process to end
wait $GODOT_PID 2>/dev/null

echo ""
echo "=========================================="
echo "Test Complete!"
echo "=========================================="
echo ""
echo "Log file: Tests/test2_land_claim_10_items.log"
echo ""
echo "Final Results:"
echo "  Berries: ${BERRIES:-0}/10"
echo "  Wood: ${WOOD:-0}/10"
echo "  Stone: ${STONE:-0}/10"
echo "  Fiber: ${FIBER:-0}/10"
echo "  Grain: ${GRAIN:-0}/10"
echo ""
echo "Time taken: $((ELAPSED/60)) minutes $((ELAPSED%60)) seconds"
echo ""
echo "Next steps:"
echo "  1. Review the log file for detailed activity"
echo "  2. Analyze gather/deposit efficiency"
echo "  3. Check which NPC completed the goal"
echo ""


