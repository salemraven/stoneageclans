#!/bin/bash
# NPC Efficiency Test Runner
# Runs the game with full logging and tracking enabled
# Collects comprehensive data on NPC activities and efficiency

# Get script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

# Default test duration (5 minutes)
DURATION=${1:-300}
if [[ "$1" == "--duration" ]]; then
    DURATION=$2
fi

# Generate test ID
TEST_ID=$(date +%Y%m%d_%H%M%S)
LOG_DIR="$SCRIPT_DIR/test_npc_efficiency_$TEST_ID"
mkdir -p "$LOG_DIR"

echo "========================================="
echo "NPC Efficiency Test Run"
echo "========================================="
echo "Test ID: $TEST_ID"
echo "Duration: $DURATION seconds ($(($DURATION / 60)) minutes)"
echo "Log Directory: $LOG_DIR"
echo ""

# Find Godot executable
GODOT_PATH="/Applications/Godot.app/Contents/MacOS/Godot"
if [ ! -f "$GODOT_PATH" ]; then
    echo "Error: Godot not found at $GODOT_PATH"
    echo "Please update GODOT_PATH in the script"
    exit 1
fi

echo "Starting Godot with full debug logging..."
echo ""

# Run Godot with debug flags
# --headless: Run without window (for automated testing)
# --debug: Enable debug mode
# --verbose: Verbose console output
# Redirect all output to log files
"$GODOT_PATH" --path . --headless --debug --verbose > "$LOG_DIR/game_console.log" 2>&1 &
GODOT_PID=$!

echo "Godot started with PID: $GODOT_PID"
echo "Running test for $DURATION seconds..."
echo ""

# Wait for specified duration
sleep $DURATION

echo ""
echo "Test duration complete. Stopping Godot..."
kill $GODOT_PID 2>/dev/null
pkill -f "godot.*stoneageclans" 2>/dev/null

# Wait a bit for Godot to shut down and flush logs
sleep 3

echo "Godot stopped."
echo ""

# Copy log files from user:// directory
echo "Collecting log files..."
# Try macOS path first, then Linux path
USER_DATA_DIR="$HOME/Library/Application Support/Godot/app_userdata/StoneAgeClans"
if [ ! -d "$USER_DATA_DIR" ]; then
    USER_DATA_DIR="$HOME/.local/share/godot/app_userdata/stoneageclans"
fi
if [ -d "$USER_DATA_DIR" ]; then
    # Copy activity tracker logs
    if [ -f "$USER_DATA_DIR/npc_activity_tracker.log" ]; then
        cp "$USER_DATA_DIR/npc_activity_tracker.log" "$LOG_DIR/npc_activity_tracker.log"
        echo "  ✓ Copied npc_activity_tracker.log"
    fi
    
    if [ -f "$USER_DATA_DIR/npc_metrics.log" ]; then
        cp "$USER_DATA_DIR/npc_metrics.log" "$LOG_DIR/npc_metrics.csv"
        echo "  ✓ Copied npc_metrics.log"
    fi
    
    # Copy other logs
    if [ -f "$USER_DATA_DIR/minigame_logs.txt" ]; then
        cp "$USER_DATA_DIR/minigame_logs.txt" "$LOG_DIR/minigame_logs.txt"
        echo "  ✓ Copied minigame_logs.txt"
    fi
    
    if [ -f "$USER_DATA_DIR/game_logs.txt" ]; then
        cp "$USER_DATA_DIR/game_logs.txt" "$LOG_DIR/game_logs.txt"
        echo "  ✓ Copied game_logs.txt"
    fi
    
    if [ -f "$USER_DATA_DIR/console_output.log" ]; then
        cp "$USER_DATA_DIR/console_output.log" "$LOG_DIR/console_output.log"
        echo "  ✓ Copied console_output.log"
    fi
else
    echo "  ⚠ User data directory not found: $USER_DATA_DIR"
fi

echo ""
echo "Running analysis..."

# Run analysis script if it exists
if [ -f "$SCRIPT_DIR/ANALYZE_NPC_EFFICIENCY.sh" ]; then
    "$SCRIPT_DIR/ANALYZE_NPC_EFFICIENCY.sh" "$LOG_DIR"
else
    echo "  ⚠ Analysis script not found, skipping analysis"
fi

echo ""
echo "========================================="
echo "Test Complete!"
echo "========================================="
echo "Log files saved to: $LOG_DIR"
echo ""
echo "Key files:"
echo "  - game_console.log: Full console output"
echo "  - npc_activity_tracker.log: Detailed NPC activity log"
echo "  - npc_metrics.csv: NPC metrics in CSV format"
echo ""
echo "Run analysis with:"
echo "  ./Tests/ANALYZE_NPC_EFFICIENCY.sh $LOG_DIR"

