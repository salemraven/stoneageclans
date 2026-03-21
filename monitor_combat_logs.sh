#!/bin/bash

# Monitor combat logs in real-time
# Shows combat events, errors, and key metrics

LOG_DIR="/Users/macbook/Desktop/stoneageclans/Tests"
LATEST_LOG=$(find "$LOG_DIR" -name "test3_combat_*.log" -type f -mmin -5 | sort -r | head -1)

if [ -z "$LATEST_LOG" ]; then
    echo "No recent combat log found. Waiting for test to start..."
    # Wait for log file
    while [ -z "$LATEST_LOG" ]; do
        sleep 2
        LATEST_LOG=$(find "$LOG_DIR" -name "test3_combat_*.log" -type f -mmin -5 | sort -r | head -1)
    done
fi

echo "Monitoring: $LATEST_LOG"
echo "=========================================="
echo ""

# Monitor in real-time
tail -f "$LATEST_LOG" 2>/dev/null | grep --line-buffered -E "🔵 COMBAT|🎯 COMBAT|⏰ SCHEDULER|❌|💥 COMBAT|🎨 ANIMATION|🔄 COMBAT|⚠️ COMBAT" | while read line; do
    echo "$(date +%H:%M:%S) $line"
done
