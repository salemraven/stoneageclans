#!/bin/bash
# Single entry point for StoneAgeClans testing.
# Usage:
#   ./Tests/run.sh smoke              # Quick sanity: 15s run, check logs exist
#   ./Tests/run.sh ai-clan [SEC]      # One AI clan run (default 120s), analyze
#   ./Tests/run.sh unified [SEC]      # Unified test: efficiency (search, herding, gather, deposit), default 240s
#   ./Tests/run.sh automate [SEC] [N] [--apply-fixes]  # Loop until pass or N runs
#
# Optional: copy Tests/config.env.example to Tests/config.env and set GODOT_PATH, etc.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

# Load config if present (GODOT_PATH, DEFAULT_DURATION, RESULTS_DIR)
if [ -f "$SCRIPT_DIR/config.env" ]; then
    # shellcheck source=/dev/null
    source "$SCRIPT_DIR/config.env"
fi

RESULTS_BASE="${RESULTS_DIR:-results}"
# Resolve to absolute if relative (relative to Tests/)
if [[ "$RESULTS_BASE" != /* ]]; then
    RESULTS_BASE="$SCRIPT_DIR/$RESULTS_BASE"
fi
mkdir -p "$RESULTS_BASE"

export GODOT_PATH="${GODOT_PATH:-/Applications/Godot.app/Contents/MacOS/Godot}"
DEFAULT_DURATION="${DEFAULT_DURATION:-120}"

cmd="${1:-}"
shift || true

case "$cmd" in
    smoke)
        TS=$(date +%Y%m%d_%H%M%S)
        LOG_DIR="$RESULTS_BASE/smoke_$TS"
        mkdir -p "$LOG_DIR"
        echo "========================================="
        echo "Smoke test (15s)"
        echo "========================================="
        echo "Output: $LOG_DIR"
        if [ ! -f "$GODOT_PATH" ]; then
            echo "Error: Godot not found at $GODOT_PATH. Set GODOT_PATH in Tests/config.env"
            exit 1
        fi
        "$SCRIPT_DIR/RUN_AI_CLAN_TEST.sh" 15 "$LOG_DIR"
        if [ -f "$LOG_DIR/npc_activity_tracker.log" ] || [ -f "$LOG_DIR/game_console.log" ]; then
            echo ""
            echo "PASS: Logs produced."
            exit 0
        else
            echo ""
            echo "FAIL: No expected logs in $LOG_DIR"
            exit 1
        fi
        ;;
    ai-clan)
        DURATION="${1:-$DEFAULT_DURATION}"
        TS=$(date +%Y%m%d_%H%M%S)
        LOG_DIR="$RESULTS_BASE/ai_clan_$TS"
        mkdir -p "$LOG_DIR"
        echo "========================================="
        echo "AI clan test (${DURATION}s)"
        echo "========================================="
        echo "Output: $LOG_DIR"
        if [ ! -f "$GODOT_PATH" ]; then
            echo "Error: Godot not found at $GODOT_PATH. Set GODOT_PATH in Tests/config.env"
            exit 1
        fi
        export GODOT_PATH
        "$SCRIPT_DIR/RUN_AI_CLAN_TEST.sh" "$DURATION" "$LOG_DIR"
        exit $?
        ;;
    unified)
        DURATION="${1:-240}"
        TS=$(date +%Y%m%d_%H%M%S)
        LOG_DIR="$RESULTS_BASE/unified_$TS"
        mkdir -p "$LOG_DIR"
        echo "========================================="
        echo "Unified test (${DURATION}s) — clansmen efficiency"
        echo "========================================="
        echo "Output: $LOG_DIR"
        if [ ! -f "$GODOT_PATH" ]; then
            echo "Error: Godot not found at $GODOT_PATH. Set GODOT_PATH in Tests/config.env"
            exit 1
        fi
        export GODOT_PATH
        "$SCRIPT_DIR/RUN_AI_CLAN_TEST.sh" "$DURATION" "$LOG_DIR"
        RUN_EXIT=$?
        "$SCRIPT_DIR/ANALYZE_UNIFIED.sh" "$LOG_DIR"
        UNIFIED_EXIT=$?
        [ "$UNIFIED_EXIT" -eq 0 ] && exit 0 || exit 1
        ;;
    automate)
        DURATION="${1:-$DEFAULT_DURATION}"
        MAX_ITER="${2:-5}"
        TS=$(date +%Y%m%d_%H%M%S)
        OUT_BASE="$RESULTS_BASE/automate_$TS"
        mkdir -p "$OUT_BASE"
        echo "========================================="
        echo "Automated AI clan test"
        echo "  Duration: ${DURATION}s | Max iterations: $MAX_ITER"
        echo "  Output base: $OUT_BASE"
        echo "========================================="
        if [ ! -f "$GODOT_PATH" ]; then
            echo "Error: Godot not found at $GODOT_PATH. Set GODOT_PATH in Tests/config.env"
            exit 1
        fi
        export GODOT_PATH
        "$SCRIPT_DIR/AUTOMATE_AI_CLAN_TEST.sh" "$DURATION" "$MAX_ITER" "$OUT_BASE" "$@"
        exit $?
        ;;
    analyze)
        LOG_DIR="${1:-.}"
        if [ ! -d "$LOG_DIR" ]; then
            echo "Usage: $0 analyze <LOG_DIR>"
            exit 1
        fi
        "$SCRIPT_DIR/ANALYZE_NPC_EFFICIENCY.sh" "$LOG_DIR"
        exit $?
        ;;
    analyze-unified)
        LOG_DIR="${1:-.}"
        if [ ! -d "$LOG_DIR" ]; then
            echo "Usage: $0 analyze-unified <LOG_DIR>"
            exit 1
        fi
        "$SCRIPT_DIR/ANALYZE_UNIFIED.sh" "$LOG_DIR"
        exit $?
        ;;
    "")
        echo "Usage: $0 <smoke|ai-clan|unified|automate|analyze|analyze-unified> [options]"
        echo ""
        echo "  smoke              Run 15s, check that logs are produced (sanity check)."
        echo "  ai-clan [SEC]       One headless run (default ${DEFAULT_DURATION}s), then analyze."
        echo "  unified [SEC]       Unified test: clansmen efficiency (default 240s), then unified analyzer."
        echo "  automate [SEC] [N] [--apply-fixes]  Up to N runs; optional auto-fix loop."
        echo "  analyze <DIR>        Re-analyze with NPC efficiency analyzer."
        echo "  analyze-unified <DIR>  Re-analyze with unified (efficiency) analyzer."
        echo ""
        echo "Config: copy Tests/config.env.example to Tests/config.env to set GODOT_PATH, RESULTS_DIR."
        exit 0
        ;;
    *)
        echo "Unknown command: $cmd"
        echo "Use: smoke | ai-clan | unified | automate | analyze | analyze-unified"
        exit 1
        ;;
esac
