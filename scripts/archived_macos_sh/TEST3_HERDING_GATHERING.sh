#!/bin/bash

# Test 3: Herding and Gathering Monitoring
# Runs the game for 3 minutes and monitors both herding and gathering systems

GODOT_PATH="/Applications/Godot.app/Contents/MacOS/Godot"
PROJECT_PATH="/Users/macbook/Desktop/stoneageclans"
LOG_FILE="$PROJECT_PATH/Tests/test3_herding_gathering.log"
DURATION=180 # 3 minutes in seconds

echo "=========================================="
echo "Test 3: Herding and Gathering Monitoring"
echo "=========================================="
echo "Log file: $LOG_FILE"
echo "Duration: $DURATION seconds (3 minutes)"
echo ""
echo "Monitoring:"
echo "- Herding: Cavemen herding wild NPCs, following behavior, clan joining"
echo "- Gathering: Resource collection, inventory management, deposits"
echo ""
echo "Starting game..."
echo ""

# Run Godot in background
"$GODOT_PATH" --path "$PROJECT_PATH" --debug --verbose > "$LOG_FILE" 2>&1 &
GODOT_PID=$!

# Wait for duration
echo "Test running... (PID: $GODOT_PID)"
echo "Monitoring for $DURATION seconds..."
echo ""

# Countdown timer
for i in {180..1}; do
    printf "\rTime remaining: %3d seconds" $i
    sleep 1
done
echo ""

# Kill the game
kill $GODOT_PID 2>/dev/null
wait $GODOT_PID 2>/dev/null

echo ""
echo "=========================================="
echo "Test 3 finished!"
echo "=========================================="
echo ""
echo "Analyzing herding and gathering behavior..."
echo ""

# === HERDING ANALYSIS ===
echo "=========================================="
echo "HERDING SYSTEM ANALYSIS"
echo "=========================================="
echo ""

echo "=== Herding State Entries ==="
HERD_ENTRIES=$(grep -i "herd_wildnpc\|HERD_WILDNPC\|entered.*herd" "$LOG_FILE" | wc -l | tr -d ' ')
echo "Total herd state entries: $HERD_ENTRIES"
grep -i "herd_wildnpc\|HERD_WILDNPC\|entered.*herd" "$LOG_FILE" | tail -n 20 || echo "No herd state entries found"
echo ""

echo "=== Wild NPC Following Events ==="
FOLLOWING_EVENTS=$(grep -i "started following\|switched to\|following\|is_herded.*true" "$LOG_FILE" | wc -l | tr -d ' ')
echo "Total following events: $FOLLOWING_EVENTS"
grep -i "started following\|switched to\|following\|is_herded.*true" "$LOG_FILE" | tail -n 20 || echo "No following events found"
echo ""

echo "=== Herd Mentality Calculations ==="
HERD_MENTALITY=$(grep -i "herd.*mentality\|attraction\|roll.*result" "$LOG_FILE" | wc -l | tr -d ' ')
echo "Total herd mentality events: $HERD_MENTALITY"
grep -i "herd.*mentality\|attraction\|roll.*result" "$LOG_FILE" | tail -n 20 || echo "No herd mentality events found"
echo ""

echo "=== Clan Joining Events ==="
CLAN_JOINS=$(grep -i "joined.*clan\|clan_name.*set\|inside.*land.*claim\|clan.*assigned" "$LOG_FILE" | wc -l | tr -d ' ')
echo "Total clan joining events: $CLAN_JOINS"
grep -i "joined.*clan\|clan_name.*set\|inside.*land.*claim\|clan.*assigned" "$LOG_FILE" | tail -n 20 || echo "No clan joining events found"
echo ""

echo "=== Herding Action Starts ==="
grep -i "ACTION_START.*herd\|herd.*started\|herding.*target" "$LOG_FILE" | tail -n 15 || echo "No herding action starts found"
echo ""

echo "=== Herding Action Completions ==="
grep -i "ACTION_COMPLETE.*herd\|herd.*complete\|herding.*success" "$LOG_FILE" | tail -n 15 || echo "No herding action completions found"
echo ""

# === GATHERING ANALYSIS ===
echo "=========================================="
echo "GATHERING SYSTEM ANALYSIS"
echo "=========================================="
echo ""

echo "=== Gather State Entries ==="
GATHER_ENTRIES=$(grep -i "gather.*state\|entered.*gather\|GATHER_STATE" "$LOG_FILE" | wc -l | tr -d ' ')
echo "Total gather state entries: $GATHER_ENTRIES"
grep -i "gather.*state\|entered.*gather\|GATHER_STATE" "$LOG_FILE" | tail -n 20 || echo "No gather state entries found"
echo ""

echo "=== Resource Collection Events ==="
COLLECTIONS=$(grep -i "collected\|gathered\|✅.*GATHER\|resource.*collected" "$LOG_FILE" | wc -l | tr -d ' ')
echo "Total collection events: $COLLECTIONS"
grep -i "collected\|gathered\|✅.*GATHER\|resource.*collected" "$LOG_FILE" | tail -n 20 || echo "No collection events found"
echo ""

echo "=== Inventory Operations ==="
INVENTORY_OPS=$(grep -i "INVENTORY\|inventory.*operation\|inventory.*full\|inventory.*add" "$LOG_FILE" | wc -l | tr -d ' ')
echo "Total inventory operations: $INVENTORY_OPS"
grep -i "INVENTORY\|inventory.*operation\|inventory.*full\|inventory.*add" "$LOG_FILE" | tail -n 20 || echo "No inventory operations found"
echo ""

echo "=== Deposit State Entries ==="
DEPOSIT_ENTRIES=$(grep -i "deposit.*state\|entered.*deposit\|DEPOSIT_STATE" "$LOG_FILE" | wc -l | tr -d ' ')
echo "Total deposit state entries: $DEPOSIT_ENTRIES"
grep -i "deposit.*state\|entered.*deposit\|DEPOSIT_STATE" "$LOG_FILE" | tail -n 20 || echo "No deposit state entries found"
echo ""

echo "=== Deposit Success Events ==="
DEPOSIT_SUCCESS=$(grep -i "✅.*DEPOSIT\|deposit.*success\|deposited.*successfully" "$LOG_FILE" | wc -l | tr -d ' ')
echo "Total successful deposits: $DEPOSIT_SUCCESS"
grep -i "✅.*DEPOSIT\|deposit.*success\|deposited.*successfully" "$LOG_FILE" | tail -n 20 || echo "No successful deposits found"
echo ""

echo "=== Deposit Failures ==="
DEPOSIT_FAILURES=$(grep -i "deposit.*fail\|deposit.*error\|could.*not.*deposit" "$LOG_FILE" | wc -l | tr -d ' ')
echo "Total deposit failures: $DEPOSIT_FAILURES"
grep -i "deposit.*fail\|deposit.*error\|could.*not.*deposit" "$LOG_FILE" | tail -n 20 || echo "No deposit failures found"
echo ""

echo "=== Search Mode Activations ==="
SEARCH_MODE=$(grep -i "🔍.*SEARCH\|search.*mode\|looking.*for.*resource" "$LOG_FILE" | wc -l | tr -d ' ')
echo "Total search mode activations: $SEARCH_MODE"
grep -i "🔍.*SEARCH\|search.*mode\|looking.*for.*resource" "$LOG_FILE" | tail -n 15 || echo "No search mode activations found"
echo ""

# === STATE TRANSITIONS ===
echo "=========================================="
echo "STATE TRANSITION ANALYSIS"
echo "=========================================="
echo ""

echo "=== State Changes (Herding Related) ==="
grep -i "STATE_CHANGE.*herd\|to.*herd\|from.*herd" "$LOG_FILE" | tail -n 15 || echo "No herding state changes found"
echo ""

echo "=== State Changes (Gathering Related) ==="
grep -i "STATE_CHANGE.*gather\|STATE_CHANGE.*deposit\|to.*gather\|to.*deposit" "$LOG_FILE" | tail -n 15 || echo "No gathering state changes found"
echo ""

# === ERRORS AND WARNINGS ===
echo "=========================================="
echo "ERRORS AND WARNINGS"
echo "=========================================="
echo ""

ERRORS=$(grep -i "ERROR\|CRITICAL\|EXCEPTION\|FATAL" "$LOG_FILE" | wc -l | tr -d ' ')
echo "Total errors: $ERRORS"
if [ "$ERRORS" -gt 0 ]; then
    grep -i "ERROR\|CRITICAL\|EXCEPTION\|FATAL" "$LOG_FILE" | tail -n 30
else
    echo "No critical errors found"
fi
echo ""

WARNINGS=$(grep -i "WARNING\|WARN" "$LOG_FILE" | wc -l | tr -d ' ')
echo "Total warnings: $WARNINGS"
if [ "$WARNINGS" -gt 0 ]; then
    grep -i "WARNING\|WARN" "$LOG_FILE" | tail -n 20
else
    echo "No warnings found"
fi
echo ""

# === SUMMARY ===
echo "=========================================="
echo "QUICK SUMMARY"
echo "=========================================="
echo ""
echo "Herding:"
echo "  - Herd state entries: $HERD_ENTRIES"
echo "  - Following events: $FOLLOWING_EVENTS"
echo "  - Herd mentality events: $HERD_MENTALITY"
echo "  - Clan joins: $CLAN_JOINS"
echo ""
echo "Gathering:"
echo "  - Gather state entries: $GATHER_ENTRIES"
echo "  - Collections: $COLLECTIONS"
echo "  - Inventory operations: $INVENTORY_OPS"
echo "  - Deposit entries: $DEPOSIT_ENTRIES"
echo "  - Successful deposits: $DEPOSIT_SUCCESS"
echo "  - Deposit failures: $DEPOSIT_FAILURES"
echo "  - Search mode activations: $SEARCH_MODE"
echo ""
echo "System Health:"
echo "  - Errors: $ERRORS"
echo "  - Warnings: $WARNINGS"
echo ""

echo "=========================================="
echo "Full log available at: $LOG_FILE"
echo "=========================================="
echo ""
echo "Next steps:"
echo "  1. Review the detailed log file: $LOG_FILE"
echo "  2. Create analysis report: Tests/TEST3_HERDING_GATHERING_ANALYSIS.md"
echo "  3. Check for patterns in herding and gathering behavior"
echo ""
