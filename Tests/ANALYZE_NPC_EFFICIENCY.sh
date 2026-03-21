#!/bin/bash
# Analyze NPC / AI clan efficiency from a test run directory.
# Usage: ./Tests/ANALYZE_NPC_EFFICIENCY.sh <LOG_DIR>
# Reads: npc_activity_tracker.log, npc_metrics.csv (or npc_metrics.log), game_console.log

LOG_DIR="${1:-.}"
if [ ! -d "$LOG_DIR" ]; then
    echo "Error: Directory not found: $LOG_DIR"
    echo "Usage: $0 <LOG_DIR>"
    exit 1
fi

ACTIVITY_LOG="$LOG_DIR/npc_activity_tracker.log"
METRICS_CSV="$LOG_DIR/npc_metrics.csv"
[ ! -f "$METRICS_CSV" ] && METRICS_CSV="$LOG_DIR/npc_metrics.log"
CONSOLE_LOG="$LOG_DIR/game_console.log"
REPORT_MD="$LOG_DIR/analysis_report.md"

echo "=========================================="
echo "AI Clan / NPC Efficiency Analysis"
echo "=========================================="
echo "Log directory: $LOG_DIR"
echo ""

# --- Activity log ---
GATHER_COUNT=0
DEPOSIT_COUNT=0
STATE_CHANGES=0
if [ -f "$ACTIVITY_LOG" ]; then
    # Lines like "[HH:MM:SS] [Name] gather: {...}" or "deposit: {...}"
    GATHER_COUNT=$(grep -cE ' gather: ' "$ACTIVITY_LOG" 2>/dev/null || true)
    DEPOSIT_COUNT=$(grep -cE ' deposit: ' "$ACTIVITY_LOG" 2>/dev/null || true)
    STATE_CHANGES=$(grep -c 'state_change' "$ACTIVITY_LOG" 2>/dev/null || true)
    # Final summary section
    if grep -q "FINAL SUMMARY" "$ACTIVITY_LOG" 2>/dev/null; then
        echo "--- Activity log final summary ---"
        sed -n '/=== FINAL SUMMARY ===/,/^$/p' "$ACTIVITY_LOG" 2>/dev/null | head -40
        echo ""
    fi
else
    echo "  ⚠ npc_activity_tracker.log not found"
fi

# --- Console log (backup for deposits/gathers and competition) ---
CONSOLE_GATHER=0
CONSOLE_DEPOSIT=0
LAND_CLAIMS_PLACED=0
INVENTORY_FULL=0
CANNOT_ENTER_GATHER=0
if [ -f "$CONSOLE_LOG" ]; then
    CONSOLE_GATHER=$(grep -cE 'GATHER:|GATHER_TASK:' "$CONSOLE_LOG" 2>/dev/null || true)
    CONSOLE_DEPOSIT=$(grep -cE 'AUTO-DEPOSIT:.*deposited|Competition:.*deposited' "$CONSOLE_LOG" 2>/dev/null || true)
    # Count land claims: placed via build_state OR spawned with caveman (main spawn-with-claim flow)
    LAND_CLAIMS_PLACED=$(grep -cE 'Land claim placed|placed claim|Created land claim|Spawned Caveman:.*with land claim' "$CONSOLE_LOG" 2>/dev/null || true)
    INVENTORY_FULL=$(grep -c 'inventory is FULL\|inventory became full' "$CONSOLE_LOG" 2>/dev/null || true)
    CANNOT_ENTER_GATHER=$(grep -c 'cannot enter gather\|cannot enter gather' "$CONSOLE_LOG" 2>/dev/null || true)
fi

# Use best available counts
[ "$GATHER_COUNT" -eq 0 ] && GATHER_COUNT=$CONSOLE_GATHER
[ "$DEPOSIT_COUNT" -eq 0 ] && DEPOSIT_COUNT=$CONSOLE_DEPOSIT

# --- Metrics CSV: state distribution from last rows ---
WANDER_END=0
GATHER_END=0
DEPOSIT_END=0
HERD_END=0
HERD_WILDNPC_END=0
DEFEND_END=0
IDLE_END=0
TOTAL_NPCS_END=0
if [ -f "$METRICS_CSV" ]; then
    # Skip header and "NPC Metrics" header lines; last 100 data rows
    LAST_ROWS=$(grep -E '^[0-9]+\.[0-9]+,' "$METRICS_CSV" 2>/dev/null | tail -100)
    if [ -n "$LAST_ROWS" ]; then
        TOTAL_NPCS_END=$(echo "$LAST_ROWS" | wc -l | tr -d ' ')
        WANDER_END=$(echo "$LAST_ROWS" | cut -d',' -f5 | grep -c 'wander' || true)
        GATHER_END=$(echo "$LAST_ROWS" | cut -d',' -f5 | grep -c 'gather' || true)
        DEPOSIT_END=$(echo "$LAST_ROWS" | cut -d',' -f5 | grep -c 'deposit' || true)
        HERD_END=$(echo "$LAST_ROWS" | cut -d',' -f5 | grep -c '^herd$' || true)
        HERD_WILDNPC_END=$(echo "$LAST_ROWS" | cut -d',' -f5 | grep -c 'herd_wildnpc' || true)
        DEFEND_END=$(echo "$LAST_ROWS" | cut -d',' -f5 | grep -c 'defend' || true)
        IDLE_END=$(echo "$LAST_ROWS" | cut -d',' -f5 | grep -c 'idle' || true)
    fi
else
    echo "  ⚠ npc_metrics.csv / npc_metrics.log not found"
fi

# --- Test duration (from activity log or assume 300) ---
DURATION_MIN=5
if [ -f "$ACTIVITY_LOG" ]; then
    FIRST_TS=$(grep -oE '\[[0-9]{2}:[0-9]{2}:[0-9]{2}\]' "$ACTIVITY_LOG" 2>/dev/null | head -1)
    LAST_TS=$(grep -oE '\[[0-9]{2}:[0-9]{2}:[0-9]{2}\]' "$ACTIVITY_LOG" 2>/dev/null | tail -1)
    if [ -n "$FIRST_TS" ] && [ -n "$LAST_TS" ]; then
        # Approximate minutes from first to last log
        DURATION_MIN=5
    fi
fi

# --- Report ---
echo "--- METRICS ---"
echo "Gathers (total):     $GATHER_COUNT"
echo "Deposits (total):    $DEPOSIT_COUNT"
echo "State changes:       $STATE_CHANGES"
echo "Land claims placed:  $LAND_CLAIMS_PLACED"
echo ""
echo "State distribution (from last metrics snapshot, n=$TOTAL_NPCS_END):"
echo "  wander:      $WANDER_END"
echo "  gather:      $GATHER_END"
echo "  deposit:     $DEPOSIT_END"
echo "  herd:        $HERD_END"
echo "  herd_wildnpc: $HERD_WILDNPC_END"
echo "  defend:      $DEFEND_END"
echo "  idle:         $IDLE_END"
echo ""

if [ "$DURATION_MIN" -gt 0 ]; then
    GATHER_PER_MIN=$((GATHER_COUNT / DURATION_MIN))
    DEPOSIT_PER_MIN=$((DEPOSIT_COUNT / DURATION_MIN))
    echo "Per-minute (approx, ${DURATION_MIN} min):"
    echo "  Gathers/min:  $GATHER_PER_MIN"
    echo "  Deposits/min: $DEPOSIT_PER_MIN"
    echo ""
fi

echo "--- RED FLAGS ---"
ISSUES=0
if [ "$GATHER_COUNT" -lt 5 ]; then
    echo "  ⚠ Low gather count ($GATHER_COUNT) — check gather_state can_enter, find_target, resource proximity"
    ISSUES=$((ISSUES+1))
fi
if [ "$DEPOSIT_COUNT" -lt 1 ]; then
    echo "  ⚠ Low deposit count ($DEPOSIT_COUNT) — check _check_and_deposit_items, deposit range, wander moving_to_deposit"
    ISSUES=$((ISSUES+1))
fi
if [ "$LAND_CLAIMS_PLACED" -eq 0 ] && [ "$DURATION_MIN" -ge 3 ]; then
    echo "  ⚠ No land claims placed — check build_state can_enter, caveman 8-item gather flow"
    ISSUES=$((ISSUES+1))
fi
if [ "$INVENTORY_FULL" -gt 10 ]; then
    echo "  ⚠ Many 'land claim inventory FULL' ($INVENTORY_FULL) — claim storage or deposit loop"
    ISSUES=$((ISSUES+1))
fi
if [ "$TOTAL_NPCS_END" -gt 0 ]; then
    WANDER_PCT=$((WANDER_END * 100 / TOTAL_NPCS_END))
    if [ "$WANDER_PCT" -gt 70 ]; then
        echo "  ⚠ High wander proportion ($WANDER_PCT%%) — FSM priority or can_enter for gather/deposit/herd"
        ISSUES=$((ISSUES+1))
    fi
fi
LOW_GATHER=0
LOW_DEPOSIT=0
NO_CLAIMS=0
HIGH_WANDER=0
[ "$GATHER_COUNT" -lt 5 ] && LOW_GATHER=1
[ "$DEPOSIT_COUNT" -lt 1 ] && LOW_DEPOSIT=1
[ "$LAND_CLAIMS_PLACED" -eq 0 ] && [ "$DURATION_MIN" -ge 3 ] && NO_CLAIMS=1
[ "$INVENTORY_FULL" -gt 10 ] && INVENTORY_FULL_FLAG=1
if [ "$TOTAL_NPCS_END" -gt 0 ]; then
    WANDER_PCT=$((WANDER_END * 100 / TOTAL_NPCS_END))
    [ "$WANDER_PCT" -gt 70 ] && HIGH_WANDER=1
fi

if [ "$ISSUES" -eq 0 ]; then
    echo "  None detected."
fi
echo ""

# Machine-parseable result for automation
RESULT_FILE="$LOG_DIR/analysis_result.env"
{
    echo "GATHER_COUNT=$GATHER_COUNT"
    echo "DEPOSIT_COUNT=$DEPOSIT_COUNT"
    echo "STATE_CHANGES=$STATE_CHANGES"
    echo "LAND_CLAIMS_PLACED=$LAND_CLAIMS_PLACED"
    echo "ISSUES=$ISSUES"
    echo "LOW_GATHER=$LOW_GATHER"
    echo "LOW_DEPOSIT=$LOW_DEPOSIT"
    echo "NO_CLAIMS=$NO_CLAIMS"
    echo "HIGH_WANDER=$HIGH_WANDER"
    echo "INVENTORY_FULL=$INVENTORY_FULL"
    echo "WANDER_END=$WANDER_END"
    echo "TOTAL_NPCS_END=$TOTAL_NPCS_END"
    echo "DURATION_MIN=$DURATION_MIN"
} > "$RESULT_FILE" 2>/dev/null

echo "--- SUGGESTED AREAS ---"
if [ "$GATHER_COUNT" -lt 5 ]; then
    echo "  • gather_state.gd: can_enter(), _find_target(), priority vs wander"
fi
if [ "$DEPOSIT_COUNT" -lt 1 ]; then
    echo "  • npc_base.gd: _check_and_deposit_items(), DEPOSIT_DISTANCE, moving_to_deposit in wander_state"
fi
if [ "$LAND_CLAIMS_PLACED" -eq 0 ]; then
    echo "  • build_state.gd: can_enter() cooldown/spacing, caveman gathering 8 items"
fi
if [ "$WANDER_END" -gt 0 ] && [ "$TOTAL_NPCS_END" -gt 0 ] && [ $((WANDER_END * 100 / TOTAL_NPCS_END)) -gt 60 ]; then
    echo "  • fsm.gd: state priorities; herd_wildnpc_state/gather_state can_enter"
fi
echo ""

echo "=========================================="
echo "Analysis complete."
echo "=========================================="

# Write markdown report
{
    echo "# AI Clan Test Analysis Report"
    echo ""
    echo "**Log dir:** \`$LOG_DIR\`"
    echo ""
    echo "## Metrics"
    echo "- Gathers: $GATHER_COUNT"
    echo "- Deposits: $DEPOSIT_COUNT"
    echo "- State changes: $STATE_CHANGES"
    echo "- Land claims placed: $LAND_CLAIMS_PLACED"
    echo "- Issues detected: $ISSUES"
    echo ""
    echo "## State distribution (last snapshot)"
    echo "- wander: $WANDER_END | gather: $GATHER_END | deposit: $DEPOSIT_END | herd: $HERD_END | herd_wildnpc: $HERD_WILDNPC_END | defend: $DEFEND_END | idle: $IDLE_END"
    echo ""
    echo "## Red flags"
    [ "$GATHER_COUNT" -lt 5 ] && echo "- Low gather count"
    [ "$DEPOSIT_COUNT" -lt 1 ] && echo "- Low deposit count"
    [ "$LAND_CLAIMS_PLACED" -eq 0 ] && echo "- No land claims placed"
    [ "$INVENTORY_FULL" -gt 10 ] && echo "- Many inventory FULL messages"
    [ "$ISSUES" -eq 0 ] && echo "- None"
} > "$REPORT_MD" 2>/dev/null && echo "Report written to $REPORT_MD"

[ "$ISSUES" -eq 0 ] && exit 0 || exit 1
