#!/bin/bash

# Monitor logs script - shows gather task system logs in real-time
# Run this in a separate terminal while game is running

LOG_FILE="$HOME/Library/Application Support/Godot/app_userdata/StoneAgeClans/game_logs.txt"

echo "=== Monitoring Gather Task System Logs ==="
echo "Log file: $LOG_FILE"
echo "Press Ctrl+C to stop"
echo ""

if [ ! -f "$LOG_FILE" ]; then
    echo "Log file not found. Waiting for game to start..."
    while [ ! -f "$LOG_FILE" ]; do
        sleep 1
    done
    echo "Log file found! Starting monitor..."
    echo ""
fi

# Tail the log file and filter for relevant gather task messages
tail -f "$LOG_FILE" | grep -E "(GATHER|gather|Gather|TASK|Task|CLANSMAN|clansman|NPC|npc|RESOURCE|resource|INVENTORY|inventory|MOVEMENT|movement|LOGIC|logic)" --color=always
