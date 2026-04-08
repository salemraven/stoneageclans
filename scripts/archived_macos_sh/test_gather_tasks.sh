#!/bin/bash

# Test script for gather task system
# Runs game with debug logging and monitors logs

GODOT_PATH="/Applications/Godot.app/Contents/MacOS/Godot"
PROJECT_PATH="/Users/macbook/Desktop/stoneageclans"
LOG_FILE="$HOME/Library/Application Support/Godot/app_userdata/StoneAgeClans/game_logs.txt"

echo "=== Gather Task System Test ==="
echo "Godot: $GODOT_PATH"
echo "Project: $PROJECT_PATH"
echo "Log file: $LOG_FILE"
echo ""

# Create log directory if it doesn't exist
mkdir -p "$(dirname "$LOG_FILE")"

# Clear previous log
if [ -f "$LOG_FILE" ]; then
    echo "Clearing previous log file..."
    > "$LOG_FILE"
fi

echo "Starting game with debug logging..."
echo "Press Ctrl+C to stop"
echo ""

# Run game in background with debug flags
"$GODOT_PATH" --path "$PROJECT_PATH" --debug --log-console --verbose > /tmp/godot_output.log 2>&1 &
GODOT_PID=$!

echo "Game started (PID: $GODOT_PID)"
echo "Monitoring logs..."
echo ""

# Wait a moment for game to start
sleep 2

# Monitor log file (tail -f equivalent)
if [ -f "$LOG_FILE" ]; then
    tail -f "$LOG_FILE" | grep -E "(GATHER|gather|Gather|TASK|Task|CLANSMAN|clansman|NPC|npc|RESOURCE|resource|INVENTORY|inventory)" --color=always
else
    echo "Log file not found yet. Showing console output:"
    tail -f /tmp/godot_output.log
fi

# Cleanup on exit
trap "kill $GODOT_PID 2>/dev/null" EXIT
