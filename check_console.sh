#!/bin/bash
# Quick console checker - shows recent relevant messages

LOG_FILE="game_console.log"

if [ ! -f "$LOG_FILE" ]; then
    echo "⚠️  Log file not found: $LOG_FILE"
    echo "Run the game first with: godot . > game_console.log 2>&1 &"
    exit 1
fi

echo "📊 Recent Console Activity (last 50 relevant lines):"
echo "=========================================="
echo ""

# Show recent relevant messages
tail -100 "$LOG_FILE" 2>/dev/null | grep -E "GATHER|DEPOSIT|WANDER|CLAN_NAME|Missing tool|No gather target|placed land claim|competition|ERROR|CRITICAL|RESOURCE FIND|GATHER CAN_ENTER|GATHER STATE|WANDER RESET" | tail -50

echo ""
echo "=========================================="
echo "📈 Summary:"
echo "  Total log lines: $(wc -l < "$LOG_FILE" 2>/dev/null || echo 0)"
echo "  Last updated: $(stat -f "%Sm" "$LOG_FILE" 2>/dev/null || stat -c "%y" "$LOG_FILE" 2>/dev/null || echo "unknown")"
echo ""
echo "Run './monitor_console.sh' for real-time monitoring"

