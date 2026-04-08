#!/bin/bash

# Test 2: Herding Competition & Deposit Race
# This test runs for 3 minutes and tracks:
# 1. Number of herded NPCs in each caveman's land claim
# 2. Number of items deposited by each caveman
# Winner is determined by combined score or individual metrics

cd /Users/macbook/Desktop/stoneageclans

echo "=========================================="
echo "Test 2: Herding Competition & Deposit Race"
echo "=========================================="
echo ""
echo "Duration: 3 minutes"
echo "Metrics:"
echo "  - Herded NPCs in land claim (women, sheep, goats)"
echo "  - Items deposited to land claim"
echo ""
echo "Starting test..."
echo ""

# Run Godot with verbose logging
/Applications/Godot.app/Contents/MacOS/Godot --path . --verbose > Tests/test2_herding_competition.log 2>&1 &
GODOT_PID=$!

echo "Test running... (PID: $GODOT_PID)"
echo "Duration: 3 minutes (180 seconds)"
echo ""

# Wait for 3 minutes
START_TIME=$(date +%s)
DURATION=180  # 3 minutes
CHECK_INTERVAL=10  # Check every 10 seconds

while true; do
    # Check if process is still running
    if ! ps -p $GODOT_PID > /dev/null 2>&1; then
        echo "Game process ended early."
        break
    fi
    
    # Check elapsed time
    ELAPSED=$(($(date +%s) - $START_TIME))
    if [ $ELAPSED -ge $DURATION ]; then
        echo "Time's up! (3 minutes)"
        kill $GODOT_PID 2>/dev/null
        break
    fi
    
    # Show countdown
    REMAINING=$((DURATION - ELAPSED))
    MINUTES=$((REMAINING / 60))
    SECONDS=$((REMAINING % 60))
    printf "\r[%02d:%02d remaining] Test in progress..." $MINUTES $SECONDS
    
    sleep $CHECK_INTERVAL
done

# Wait for process to end
wait $GODOT_PID 2>/dev/null

echo ""
echo ""
echo "=========================================="
echo "Test Complete! Analyzing results..."
echo "=========================================="
echo ""

# Analyze results
if [ -f "Tests/test2_herding_competition.log" ]; then
    echo "Log file: Tests/test2_herding_competition.log"
    echo "Total lines: $(wc -l < Tests/test2_herding_competition.log)"
    echo ""
    
    echo "=== DEPOSIT LEADERBOARD ==="
    echo ""
    # Extract competition leaderboard if available
    if grep -q "COMPETITION LEADERBOARD" Tests/test2_herding_competition.log; then
        grep "COMPETITION LEADERBOARD" Tests/test2_herding_competition.log | tail -1
        echo ""
        grep "WINNER:" Tests/test2_herding_competition.log | tail -1
        echo ""
    else
        echo "No competition leaderboard found. Counting deposits manually..."
        echo ""
        echo "Deposits by NPC:"
        grep "✅ DEPOSIT SUCCESS" Tests/test2_herding_competition.log 2>/dev/null | grep -o "[A-Z]* deposited" | sed 's/ deposited//' | sort | uniq -c | sort -rn || echo "  No deposits found"
        echo ""
    fi
    
    echo "=== HERDING STATISTICS ==="
    echo ""
    echo "Herding activity:"
    echo "  herd_wildnpc state entries: $(grep -c "STATE_ENTRY:.*entered herd_wildnpc\|entered herd_wildnpc" Tests/test2_herding_competition.log 2>/dev/null || echo "0")"
    echo "  Deliveries (target joined clan): $(grep -c "delivery complete, cooldown" Tests/test2_herding_competition.log 2>/dev/null || echo "0")"
    echo "  NPCs joined clans (log lines): $(grep -c "joined.*clan\|clan_name.*set" Tests/test2_herding_competition.log 2>/dev/null || echo "0")"
    echo ""
    
    echo "=== DETAILED ANALYSIS ==="
    echo "Run: ./Tests/TEST2_ANALYZE_HERDING.sh"
    echo ""
else
    echo "⚠️ Log file not found!"
fi

echo "Test complete!"


