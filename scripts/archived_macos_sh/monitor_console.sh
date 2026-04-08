#!/bin/bash
# Console Monitor Script for Stone Age Clans
# Monitors game console output in real-time

LOG_FILE="game_console.log"
FILTER_PATTERN="GATHER|DEPOSIT|WANDER|BUILD|CLAN_NAME|Missing tool|No gather target|placed land claim|competition|ERROR|CRITICAL|RESOURCE FIND|GATHER CAN_ENTER|GATHER STATE|WANDER RESET|placed claim"

echo "🔍 Monitoring game console output..."
echo "📁 Log file: $LOG_FILE"
echo "🔎 Filtering for: $FILTER_PATTERN"
echo ""
echo "Press Ctrl+C to stop monitoring"
echo "=========================================="
echo ""

if [ ! -f "$LOG_FILE" ]; then
    echo "⚠️  Log file not found. Waiting for it to be created..."
    while [ ! -f "$LOG_FILE" ]; do
        sleep 1
    done
    echo "✅ Log file created, starting monitoring..."
    echo ""
fi

# Monitor with filtering
tail -f "$LOG_FILE" 2>/dev/null | grep --line-buffered -E "$FILTER_PATTERN" || {
    echo "No matching output yet. Showing all output:"
    tail -f "$LOG_FILE" 2>/dev/null
}
