#!/bin/bash

# Script to run Godot and capture all logs to a file
# Usage: ./run_with_logs.sh

LOG_FILE="game_logs_$(date +%Y%m%d_%H%M%S).txt"

echo "Starting Godot and logging to: $LOG_FILE"
echo "Press Ctrl+C to stop and view logs"
echo ""

# Run Godot and capture all output (stdout and stderr)
/Applications/Godot.app/Contents/MacOS/Godot --path . 2>&1 | tee "$LOG_FILE"

echo ""
echo "Logs saved to: $LOG_FILE"
echo "You can now share this file or copy its contents"

