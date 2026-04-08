#!/bin/bash

# Test 3: NPC Inventory Crash Debug
# Runs the game with debug logging to diagnose inventory crash

# Define paths
GODOT_PATH="/Applications/Godot.app/Contents/MacOS/Godot"
PROJECT_PATH="/Users/macbook/Desktop/stoneageclans"
LOG_FILE="$PROJECT_PATH/Tests/test3_inventory_crash.log"
DURATION=180 # 3 minutes in seconds

echo "=========================================="
echo "Test 3: NPC Inventory Crash Debug"
echo "=========================================="
echo "Log file: $LOG_FILE"
echo "Duration: $DURATION seconds (3 minutes)"
echo ""
echo "Instructions:"
echo "1. Game will start in debug mode"
echo "2. Click on a caveman NPC to open inventory"
echo "3. Watch console for detailed logging"
echo "4. If crash occurs, check log file for last messages"
echo ""
echo "Starting game..."
echo ""

# Run Godot in debug mode and redirect output to log file
# Use 'timeout' for Linux/macOS or manual stop
if command -v timeout &> /dev/null
then
    timeout $DURATION "$GODOT_PATH" --path "$PROJECT_PATH" --debug --verbose > "$LOG_FILE" 2>&1
    EXIT_CODE=$?
else
    echo "Warning: 'timeout' command not found. Please stop the game manually after $DURATION seconds."
    "$GODOT_PATH" --path "$PROJECT_PATH" --debug --verbose > "$LOG_FILE" 2>&1 &
    GODOT_PID=$!
    sleep $DURATION
    kill $GODOT_PID 2>/dev/null
    EXIT_CODE=$?
fi

echo ""
echo "=========================================="
echo "Test 3 finished!"
echo "=========================================="
echo ""
echo "Analyzing log file: $LOG_FILE"
echo ""

# Show last 100 lines of log
echo "Last 100 lines of log:"
tail -n 100 "$LOG_FILE"

echo ""
echo "Searching for errors..."
grep -i "ERROR\|CRITICAL\|CRASH\|EXCEPTION" "$LOG_FILE" | tail -n 20 || echo "No critical errors found."

echo ""
echo "Searching for NPC inventory operations..."
grep -E "NPC_INVENTORY_UI|INVENTORY_UI|setup_with_npc|show_at_npc_position" "$LOG_FILE" | tail -n 50 || echo "No inventory operations found."

echo ""
echo "Full log available at: $LOG_FILE"
echo ""
echo "=========================================="
echo "Checking Console Logger Output"
echo "=========================================="
echo ""
CONSOLE_LOG_PATH="$HOME/.local/share/godot/app_userdata/StoneAgeClans/console_output.log"
if [ -f "$CONSOLE_LOG_PATH" ]; then
    echo "✅ Console logger file found: $CONSOLE_LOG_PATH"
    echo ""
    echo "Last 50 lines from console_output.log:"
    tail -n 50 "$CONSOLE_LOG_PATH"
    echo ""
    echo "Searching for errors in console_output.log..."
    grep -i "ERROR\|CRASH\|EXCEPTION" "$CONSOLE_LOG_PATH" | tail -n 20 || echo "No critical errors found in console_output.log"
else
    echo "⚠️ Console logger file not found: $CONSOLE_LOG_PATH"
    echo "   (This is normal if ConsoleLogger wasn't used or game didn't run)"
fi
echo ""
echo "=========================================="
echo "Next steps:"
echo "=========================================="
echo "1. Review the log file for crash location: $LOG_FILE"
echo "2. Check console logger output: $CONSOLE_LOG_PATH"
echo "3. Check last log message before crash in both files"
echo "4. Look for error messages in both sources"
echo "5. Create analysis report: Tests/TEST3_INVENTORY_CRASH_ANALYSIS.md"

exit $EXIT_CODE
