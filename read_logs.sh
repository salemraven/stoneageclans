#!/bin/bash
# Script to read and monitor game logs
# Usage: ./read_logs.sh [--tail] [--errors] [--clear]

LOG_FILE="$HOME/.local/share/godot/app_userdata/StoneAgeClans/game_logs.txt"

# Create log file if it doesn't exist
mkdir -p "$(dirname "$LOG_FILE")"
touch "$LOG_FILE"

case "$1" in
    --tail)
        echo "Monitoring logs (Ctrl+C to stop)..."
        tail -f "$LOG_FILE"
        ;;
    --errors)
        echo "Showing errors only:"
        grep -i "ERROR\|CRASH\|WARNING" "$LOG_FILE" | tail -20
        ;;
    --clear)
        echo "Clearing log file..."
        > "$LOG_FILE"
        echo "Log cleared."
        ;;
    --last)
        echo "Last 50 lines:"
        tail -50 "$LOG_FILE"
        ;;
    *)
        echo "Game Logs:"
        echo "=========="
        if [ -f "$LOG_FILE" ]; then
            tail -100 "$LOG_FILE"
        else
            echo "No log file found at: $LOG_FILE"
        fi
        echo ""
        echo "Usage:"
        echo "  ./read_logs.sh          - Show last 100 lines"
        echo "  ./read_logs.sh --tail   - Monitor logs in real-time"
        echo "  ./read_logs.sh --errors - Show only errors/warnings"
        echo "  ./read_logs.sh --last   - Show last 50 lines"
        echo "  ./read_logs.sh --clear  - Clear log file"
        ;;
esac

