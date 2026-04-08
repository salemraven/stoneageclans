#!/bin/bash
# Automated AI clan test loop: run test → analyze → optionally apply fixes → re-run until pass or max iterations.
# Usage: ./Tests/AUTOMATE_AI_CLAN_TEST.sh [DURATION_SEC] [MAX_ITER] [OUTPUT_BASE] [--apply-fixes]
#   DURATION_SEC  Default 120 (2 min per run for quicker iteration)
#   MAX_ITER      Default 5
#   OUTPUT_BASE   Optional; dir for iter_1, iter_2, ... (default: script dir with ai_clan_auto_N)
#   --apply-fixes When issues found, apply one predefined fix per iteration and re-run (logic/priority only, no game limits)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

DURATION=120
MAX_ITER=5
OUTPUT_BASE=""
APPLY_FIXES=""
NUM_ARG=0
while [[ $# -gt 0 ]]; do
    case "$1" in
        --apply-fixes) APPLY_FIXES=1; shift ;;
        [0-9]*)
            NUM_ARG=$((NUM_ARG + 1))
            if [ "$NUM_ARG" -eq 1 ]; then DURATION=$1; elif [ "$NUM_ARG" -eq 2 ]; then MAX_ITER=$1; fi
            shift ;;
        *)
            # If we have two numeric args and this looks like a path, treat as OUTPUT_BASE
            if [ "$NUM_ARG" -eq 2 ] && [[ "$1" == */* ]]; then
                OUTPUT_BASE="$1"
                shift
            else
                shift
            fi
            ;;
    esac
done

apply_fix() {
    local name="$1"
    local file="$PROJECT_ROOT/$2"
    local old="$3"
    local new="$4"
    if [ ! -f "$file" ]; then return 1; fi
    if grep -qF "$old" "$file" 2>/dev/null; then
        # Escape for sed: . * [ ] \ ^ $ in pattern; & \ in replacement
        local old_esc new_esc
        old_esc=$(printf '%s' "$old" | sed 's/\\/\\\\/g; s/\./\\./g; s/\*/\\*/g; s/\[/\\[/g; s/\]/\\]/g; s/\^/\\^/g; s/\$/\\$/g')
        new_esc=$(printf '%s' "$new" | sed 's/\\/\\\\/g; s/&/\\&/g')
        if sed --version 2>/dev/null | grep -q GNU; then
            sed -i "s|$old_esc|$new_esc|" "$file"
        else
            sed -i.bak "s|$old_esc|$new_esc|" "$file"
            rm -f "$file.bak" 2>/dev/null
        fi
        echo "  [FIX] Applied: $name"
        return 0
    fi
    return 1
}

echo "========================================="
echo "Automated AI Clan Test"
echo "========================================="
echo "Duration per run: ${DURATION}s | Max iterations: $MAX_ITER | Apply fixes: ${APPLY_FIXES:-no}"
echo ""

for iter in $(seq 1 "$MAX_ITER"); do
    if [ -n "$OUTPUT_BASE" ]; then
        LOG_DIR="$OUTPUT_BASE/iter_$iter"
    else
        LOG_DIR="$SCRIPT_DIR/ai_clan_auto_$iter"
    fi
    mkdir -p "$LOG_DIR"
    echo "--- Iteration $iter ---"
    echo "Running test ($DURATION s)..."
    if ! "$SCRIPT_DIR/RUN_AI_CLAN_TEST.sh" "$DURATION" "$LOG_DIR" > "$LOG_DIR/run.log" 2>&1; then
        echo "  Run script had an error; check $LOG_DIR/run.log"
    fi
    if [ ! -f "$LOG_DIR/analysis_result.env" ]; then
        echo "  No analysis result; analyzer may have failed. Check $LOG_DIR"
        continue
    fi
    # shellcheck source=/dev/null
    source "$LOG_DIR/analysis_result.env"
    echo "  Gathers: $GATHER_COUNT | Deposits: $DEPOSIT_COUNT | Issues: $ISSUES"
    if [ "${ISSUES:-1}" -eq 0 ]; then
        echo ""
        echo "========================================="
        echo "PASS (iteration $iter). No issues."
        echo "========================================="
        exit 0
    fi
    if [ -z "$APPLY_FIXES" ]; then
        echo "  Issues found. Re-run with --apply-fixes to auto-apply fixes."
        continue
    fi
    APPLIED=0
    if [ "${LOW_GATHER:-0}" -eq 1 ]; then
        if apply_fix "boost gather priority" "scripts/config/npc_config.gd" \
            "priority_gather_other: float = 3.0" "priority_gather_other: float = 4.0"; then
            APPLIED=1
        fi
    fi
    if [ "$APPLIED" -eq 0 ] && [ "${LOW_DEPOSIT:-0}" -eq 1 ]; then
        if apply_fix "widen deposit range (50→60)" "scripts/npc/npc_base.gd" \
            "const DEPOSIT_DISTANCE: float = 50.0" "const DEPOSIT_DISTANCE: float = 60.0"; then
            APPLIED=1
        elif apply_fix "widen deposit range (60→70)" "scripts/npc/npc_base.gd" \
            "const DEPOSIT_DISTANCE: float = 60.0" "const DEPOSIT_DISTANCE: float = 70.0"; then
            APPLIED=1
        elif apply_fix "widen deposit range (70→100)" "scripts/npc/npc_base.gd" \
            "const DEPOSIT_DISTANCE: float = 70.0" "const DEPOSIT_DISTANCE: float = 100.0"; then
            APPLIED=1
        elif apply_fix "wander deposit range match (50→100)" "scripts/npc/states/wander_state.gd" \
            "const DEPOSIT_RANGE: float = 50.0" "const DEPOSIT_RANGE: float = 100.0"; then
            APPLIED=1
        fi
    fi
    if [ "$APPLIED" -eq 0 ] && [ "${HIGH_WANDER:-0}" -eq 1 ]; then
        if apply_fix "lower wander priority (cavemen)" "scripts/npc/states/wander_state.gd" \
            "return 0.5  # Lower than gather/deposit" "return 0.4  # Lower than gather/deposit"; then
            APPLIED=1
        fi
    fi
    if [ "$APPLIED" -eq 0 ] && [ "${NO_CLAIMS:-0}" -eq 1 ]; then
        if apply_fix "faster build cooldown" "scripts/npc/states/build_state.gd" \
            "var build_cooldown: float = 6.0  # Faster placement" "var build_cooldown: float = 4.0  # Faster placement"; then
            APPLIED=1
        fi
    fi
    if [ "$APPLIED" -eq 0 ]; then
        echo "  No more fixes to apply for current issues."
        echo ""
        echo "========================================="
        echo "STOP (iteration $iter). Issues remain; no fix applied."
        echo "========================================="
        exit 1
    fi
    echo ""
done

echo "========================================="
echo "MAX ITERATIONS ($MAX_ITER) reached."
echo "========================================="
exit 1
