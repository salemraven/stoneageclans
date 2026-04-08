#!/bin/bash
# Quick script to check latest logs - used by AI assistant
LOG_FILE="$HOME/Library/Application Support/Godot/app_userdata/StoneAgeClans/game_logs.txt"
ERROR_LOG="$HOME/Library/Application Support/Godot/app_userdata/StoneAgeClans/error_logs.txt"
GODOT_LOG="$HOME/Library/Application Support/Godot/app_userdata/StoneAgeClans/logs/godot.log"

# Also check for Godot's standard output/error logs
GODOT_STDERR="$HOME/Library/Logs/Godot/godot_stderr.log"
GODOT_STDOUT="$HOME/Library/Logs/Godot/godot_stdout.log"

echo "=== Error Logs (error_logs.txt) ==="
if [ -f "$ERROR_LOG" ]; then
    tail -50 "$ERROR_LOG"
else
    echo "No error log file found at: $ERROR_LOG"
fi

echo ""
echo "=== Game Logs (game_logs.txt) ==="
if [ -f "$LOG_FILE" ]; then
    tail -50 "$LOG_FILE"
    echo ""
    echo "=== Errors/Warnings in Game Logs ==="
    grep -i "ERROR\|CRASH\|WARNING\|FAILED" "$LOG_FILE" | tail -20
else
    echo "No game log file found at: $LOG_FILE"
fi

echo ""
echo "=== Godot Engine Log (Parse Errors & Script Errors) ==="
if [ -f "$GODOT_LOG" ]; then
    echo "Recent errors:"
    tail -200 "$GODOT_LOG" | grep -E "ERROR|SCRIPT ERROR|CRASH|WARNING|Failed|Parse error|Could not resolve|not declared" | tail -50
    echo ""
    echo "Full recent log (last 50 lines):"
    tail -50 "$GODOT_LOG"
else
    echo "No Godot log file found at: $GODOT_LOG"
    # Try to find latest log file
    LATEST_LOG=$(ls -t ~/Library/Application\ Support/Godot/app_userdata/StoneAgeClans/logs/*.log 2>/dev/null | head -1)
    if [ -n "$LATEST_LOG" ]; then
        echo "Found latest log: $LATEST_LOG"
        tail -200 "$LATEST_LOG" | grep -E "ERROR|SCRIPT ERROR|CRASH|WARNING|Failed|Parse error|Could not resolve|not declared" | tail -50
    fi
fi

echo ""
echo "=== Godot Standard Error (stderr) ==="
if [ -f "$GODOT_STDERR" ]; then
    tail -50 "$GODOT_STDERR" | grep -E "ERROR|CRASH|WARNING|Failed|Parse|Exception" | tail -30
else
    echo "No stderr log found at: $GODOT_STDERR"
fi

echo ""
echo "=== Recent Script Parse Errors ==="
# Check for parse errors in project directory
find . -name "*.gd" -exec grep -l "Parse error\|Failed to load script" {} \; 2>/dev/null | head -10

