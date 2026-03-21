#!/bin/bash
# AI Clan Test Runner
# Runs the game headless, collects NPC activity and console logs for analysis.
# Usage: ./Tests/RUN_AI_CLAN_TEST.sh [DURATION_SEC] [OUTPUT_DIR]
#   DURATION_SEC  Default 300 (5 min)
#   OUTPUT_DIR    Optional; default is Tests/ai_clan_test_<timestamp>

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

DURATION=${1:-300}
if [[ "$1" == "--duration" ]]; then
    DURATION=$2
    shift 2
fi

TEST_ID=$(date +%Y%m%d_%H%M%S)
# Second arg = optional output dir (first arg = duration)
if [[ -n "$2" && -d "$(dirname "$2")" ]]; then
    LOG_DIR="$2"
else
    LOG_DIR="$SCRIPT_DIR/ai_clan_test_$TEST_ID"
fi
mkdir -p "$LOG_DIR"

echo "========================================="
echo "AI Clan Test Run"
echo "========================================="
echo "Test ID: $TEST_ID"
echo "Duration: $DURATION seconds ($((DURATION / 60)) minutes)"
echo "Log Directory: $LOG_DIR"
echo ""

GODOT_PATH="${GODOT_PATH:-/Applications/Godot.app/Contents/MacOS/Godot}"
if [ ! -f "$GODOT_PATH" ]; then
    echo "Error: Godot not found at $GODOT_PATH"
    echo "Set GODOT_PATH in Tests/config.env or in the environment"
    exit 1
fi

echo "Starting Godot (headless, debug, verbose, playtest-capture)..."
# So NPCActivityTracker writes directly into LOG_DIR; pass env on same line so child definitely gets it
# --playtest-capture: enables instrumentation for herd_wildnpc, combat, etc.
GODOT_TEST_LOG_DIR="$LOG_DIR" "$GODOT_PATH" --path . --headless --debug --verbose --playtest-capture > "$LOG_DIR/game_console.log" 2>&1 &
GODOT_PID=$!
echo "Godot PID: $GODOT_PID"
echo "Running for $DURATION seconds..."
echo ""

sleep $DURATION

echo "Stopping Godot..."
kill $GODOT_PID 2>/dev/null
pkill -f "godot.*stoneageclans" 2>/dev/null
sleep 3
echo "Godot stopped."
echo ""

echo "Collecting log files..."
USER_DATA_DIR="$HOME/Library/Application Support/Godot/app_userdata/StoneAgeClans"
if [ ! -d "$USER_DATA_DIR" ]; then
    USER_DATA_DIR="$HOME/.local/share/godot/app_userdata/stoneageclans"
fi
if [ -d "$USER_DATA_DIR" ]; then
    # NPC logs: Godot writes directly to LOG_DIR when GODOT_TEST_LOG_DIR is set. Do NOT overwrite
    # with stale user data — only copy from user data when destination is missing (e.g. Godot crashed before write).
    for f in npc_activity_tracker.log npc_metrics.log; do
        if [ -f "$LOG_DIR/$f" ]; then
            echo "  ✓ $f (from test run)"
        elif [ -f "$USER_DATA_DIR/$f" ]; then
            cp "$USER_DATA_DIR/$f" "$LOG_DIR/$f"
            echo "  ✓ $f (from user data)"
        fi
    done
    if [ ! -f "$LOG_DIR/npc_metrics.csv" ] && [ -f "$USER_DATA_DIR/npc_metrics.log" ]; then
        cp "$USER_DATA_DIR/npc_metrics.log" "$LOG_DIR/npc_metrics.csv" && echo "  ✓ npc_metrics.csv (from user data)"
    elif [ -f "$LOG_DIR/npc_metrics.log" ]; then
        cp "$LOG_DIR/npc_metrics.log" "$LOG_DIR/npc_metrics.csv" 2>/dev/null && echo "  ✓ npc_metrics.csv (from test run)"
    fi
    for f in minigame_logs.txt game_logs.txt console_output.log; do
        if [ -f "$USER_DATA_DIR/$f" ]; then
            cp "$USER_DATA_DIR/$f" "$LOG_DIR/$f"
            echo "  ✓ $f"
        fi
    done
    # Playtest instrumentation: when GODOT_TEST_LOG_DIR is set, Godot writes directly to LOG_DIR/playtest_session.jsonl
    if [ -f "$LOG_DIR/playtest_session.jsonl" ]; then
        echo "  ✓ playtest_session.jsonl (from test run)"
    else
        LATEST_PLAYTEST=""
        LATEST_MTIME=0
        for f in "$USER_DATA_DIR"/playtest_*.jsonl; do
            if [ -f "$f" ]; then
                MTIME=$(stat -f %m "$f" 2>/dev/null || stat -c %Y "$f" 2>/dev/null)
                if [ -n "$MTIME" ] && [ "$MTIME" -gt "$LATEST_MTIME" ]; then
                    LATEST_MTIME=$MTIME
                    LATEST_PLAYTEST=$f
                fi
            fi
        done
        if [ -n "$LATEST_PLAYTEST" ]; then
            cp "$LATEST_PLAYTEST" "$LOG_DIR/playtest_session.jsonl"
            echo "  ✓ playtest_session.jsonl (from $(basename "$LATEST_PLAYTEST"))"
        fi
    fi
else
    echo "  ⚠ User data dir not found: $USER_DATA_DIR"
fi

echo ""
echo "Running playtest reporter (instrumentation summary)..."
if [ -f "$LOG_DIR/playtest_session.jsonl" ]; then
    "$GODOT_PATH" --path . --headless -s scripts/logging/playtest_reporter.gd "$LOG_DIR/playtest_session.jsonl" > "$LOG_DIR/playtest_report.txt" 2>&1
    echo "  ✓ playtest_report.txt"
else
    echo "  ⚠ No playtest_session.jsonl (instrumentation may not have run)"
fi

echo ""
echo "Running analysis..."
if [ -f "$SCRIPT_DIR/ANALYZE_NPC_EFFICIENCY.sh" ]; then
    "$SCRIPT_DIR/ANALYZE_NPC_EFFICIENCY.sh" "$LOG_DIR"
elif [ -f "$SCRIPT_DIR/ANALYZE_AI_CLAN.sh" ]; then
    "$SCRIPT_DIR/ANALYZE_AI_CLAN.sh" "$LOG_DIR"
else
    echo "  ⚠ No analysis script found. Run manually:"
    echo "    ./Tests/ANALYZE_NPC_EFFICIENCY.sh $LOG_DIR"
fi

echo ""
echo "========================================="
echo "Test complete. Logs: $LOG_DIR"
echo "========================================="
