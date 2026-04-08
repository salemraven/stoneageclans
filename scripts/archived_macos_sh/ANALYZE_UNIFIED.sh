#!/bin/bash
# Unified analyzer: clansmen efficiency and success (search, herding, gather, deposit).
# Usage: ./Tests/ANALYZE_UNIFIED.sh <LOG_DIR>
# Reads: game_console.log, npc_activity_tracker.log, npc_metrics.log, playtest_session.jsonl
# Writes: unified_report.md, unified_result.env

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
PLAYTEST_JSONL="$LOG_DIR/playtest_session.jsonl"
REPORT_MD="$LOG_DIR/unified_report.md"
RESULT_ENV="$LOG_DIR/unified_result.env"

echo "=========================================="
echo "Unified Test: Clansmen Efficiency"
echo "=========================================="
echo "Log directory: $LOG_DIR"
echo ""

# --- Activity log: gather, deposit ---
GATHER_COUNT=0
DEPOSIT_COUNT=0
STATE_CHANGES=0
if [ -f "$ACTIVITY_LOG" ]; then
    GATHER_COUNT=$(grep -cE ' gather: ' "$ACTIVITY_LOG" 2>/dev/null || true)
    DEPOSIT_COUNT=$(grep -cE ' deposit: ' "$ACTIVITY_LOG" 2>/dev/null || true)
    STATE_CHANGES=$(grep -c 'state_change' "$ACTIVITY_LOG" 2>/dev/null || true)
fi
CONSOLE_GATHER=0
CONSOLE_DEPOSIT=0
if [ -f "$CONSOLE_LOG" ]; then
    CONSOLE_GATHER=$(grep -cE 'GATHER:|GATHER_TASK:' "$CONSOLE_LOG" 2>/dev/null || true)
    CONSOLE_DEPOSIT=$(grep -cE 'AUTO-DEPOSIT:.*deposited|Competition:.*deposited' "$CONSOLE_LOG" 2>/dev/null || true)
fi
[ "$GATHER_COUNT" -eq 0 ] && GATHER_COUNT=$CONSOLE_GATHER
[ "$DEPOSIT_COUNT" -eq 0 ] && DEPOSIT_COUNT=$CONSOLE_DEPOSIT

# --- Console: land claims, ClanBrain ---
LAND_CLAIMS_PLACED=0
CLANBRAIN_INITS=0
if [ -f "$CONSOLE_LOG" ]; then
    LAND_CLAIMS_PLACED=$(grep -cE 'Land claim placed|placed claim|Created land claim|Spawned Caveman:.*with land claim|Boost:.*woman.*baby' "$CONSOLE_LOG" 2>/dev/null || true)
    CLANBRAIN_INITS=$(grep -c 'ClanBrain initialized for clan' "$CONSOLE_LOG" 2>/dev/null || true)
fi

# --- Metrics: state distribution ---
WANDER_END=0
GATHER_END=0
DEPOSIT_END=0
HERD_END=0
HERD_WILDNPC_END=0
DEFEND_END=0
IDLE_END=0
TOTAL_NPCS_END=0
if [ -f "$METRICS_CSV" ]; then
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
fi

# --- Playtest JSONL: efficiency events ---
HERD_JOINED_COUNT=0
HERD_WILDNPC_ENTER_COUNT=0
MILESTONE_PLACED_COUNT=0
BABY_SPAWNED_COUNT=0
BABY_GREW_COUNT=0
COMBAT_STARTED=0
COMBAT_ENDED=0
if [ -f "$PLAYTEST_JSONL" ]; then
    HERD_JOINED_COUNT=$(grep -c '"evt":"npc_joined_clan"' "$PLAYTEST_JSONL" 2>/dev/null || true)
    HERD_WILDNPC_ENTER_COUNT=$(grep -c '"evt":"herd_wildnpc_enter"' "$PLAYTEST_JSONL" 2>/dev/null || true)
    MILESTONE_PLACED_COUNT=$(grep -c '"evt":"milestone_building_placed"' "$PLAYTEST_JSONL" 2>/dev/null || true)
    BABY_SPAWNED_COUNT=$(grep -c '"evt":"baby_spawned"' "$PLAYTEST_JSONL" 2>/dev/null || true)
    BABY_GREW_COUNT=$(grep -c '"evt":"baby_grew_to_clansman"' "$PLAYTEST_JSONL" 2>/dev/null || true)
    COMBAT_STARTED=$(grep -c '"evt":"combat_started"' "$PLAYTEST_JSONL" 2>/dev/null || true)
    COMBAT_ENDED=$(grep -c '"evt":"combat_ended"' "$PLAYTEST_JSONL" 2>/dev/null || true)
fi

# --- Duration (approx) ---
DURATION_MIN=5
if [ -f "$ACTIVITY_LOG" ]; then
    FIRST_TS=$(grep -oE '\[[0-9]{2}:[0-9]{2}:[0-9]{2}\]' "$ACTIVITY_LOG" 2>/dev/null | head -1)
    LAST_TS=$(grep -oE '\[[0-9]{2}:[0-9]{2}:[0-9]{2}\]' "$ACTIVITY_LOG" 2>/dev/null | tail -1)
fi
[ "$DURATION_MIN" -lt 1 ] && DURATION_MIN=1
GATHER_PER_MIN=0
DEPOSIT_PER_MIN=0
[ "$DURATION_MIN" -gt 0 ] && GATHER_PER_MIN=$((GATHER_COUNT / DURATION_MIN))
[ "$DURATION_MIN" -gt 0 ] && DEPOSIT_PER_MIN=$((DEPOSIT_COUNT / DURATION_MIN))

# --- Pass/fail ---
SPAWN_OK=0
[ "$LAND_CLAIMS_PLACED" -ge 1 ] && [ "$CLANBRAIN_INITS" -ge 1 ] && SPAWN_OK=1
GATHER_OK=0
[ "$GATHER_COUNT" -ge 1 ] && GATHER_OK=1
DEPOSIT_OK=0
[ "$DEPOSIT_COUNT" -ge 1 ] && DEPOSIT_OK=1
SEARCH_ACTIVITY_OK=0
[ "$HERD_WILDNPC_ENTER_COUNT" -ge 1 ] || [ "$HERD_WILDNPC_END" -ge 1 ] && SEARCH_ACTIVITY_OK=1
HERD_SUCCESS_OK=0
[ "$HERD_JOINED_COUNT" -ge 1 ] && HERD_SUCCESS_OK=1
COMBAT_OK=1
[ "$COMBAT_STARTED" -gt 0 ] && [ "$COMBAT_ENDED" -lt "$COMBAT_STARTED" ] && COMBAT_OK=0
EFFICIENCY_PASS=0
[ "$SPAWN_OK" -eq 1 ] && [ "$GATHER_OK" -eq 1 ] && [ "$DEPOSIT_OK" -eq 1 ] && [ "$SEARCH_ACTIVITY_OK" -eq 1 ] && EFFICIENCY_PASS=1
CRASH_OR_ERROR=0
if [ -f "$CONSOLE_LOG" ]; then
    if grep -qE 'SCRIPT ERROR|FATAL ERROR|Assertion failed' "$CONSOLE_LOG" 2>/dev/null; then
        CRASH_OR_ERROR=1
        EFFICIENCY_PASS=0
    fi
fi
[ "$CRASH_OR_ERROR" -eq 1 ] && EFFICIENCY_PASS=0

# --- Report: efficiency summary first ---
echo "--- EFFICIENCY SUMMARY ---"
echo "  Herding success (NPCs joined clan): $HERD_JOINED_COUNT"
echo "  Search activity (herd_wildnpc enter): $HERD_WILDNPC_ENTER_COUNT"
echo "  Gathers (total): $GATHER_COUNT  (per min: $GATHER_PER_MIN)"
echo "  Deposits (total): $DEPOSIT_COUNT  (per min: $DEPOSIT_PER_MIN)"
echo ""
echo "  Spawn OK (claims + ClanBrain): $SPAWN_OK"
echo "  Gather OK: $GATHER_OK  Deposit OK: $DEPOSIT_OK"
echo "  Search activity OK: $SEARCH_ACTIVITY_OK  Herd success OK: $HERD_SUCCESS_OK"
echo "  Combat OK (no dangling): $COMBAT_OK"
echo "  EFFICIENCY_PASS: $EFFICIENCY_PASS"
echo ""

echo "--- SUPPORTING METRICS ---"
echo "  Land claims: $LAND_CLAIMS_PLACED  ClanBrain inits: $CLANBRAIN_INITS"
echo "  Milestone buildings placed: $MILESTONE_PLACED_COUNT"
echo "  Babies spawned: $BABY_SPAWNED_COUNT  Babies grew to clansman: $BABY_GREW_COUNT"
echo "  State distribution (last snapshot): wander=$WANDER_END gather=$GATHER_END deposit=$DEPOSIT_END herd=$HERD_END herd_wildnpc=$HERD_WILDNPC_END defend=$DEFEND_END idle=$IDLE_END"
echo ""

echo "--- RED FLAGS ---"
ISSUES=0
[ "$GATHER_COUNT" -eq 0 ] && echo "  Zero gathers" && ISSUES=$((ISSUES+1))
[ "$DEPOSIT_COUNT" -eq 0 ] && echo "  Zero deposits" && ISSUES=$((ISSUES+1))
[ "$SPAWN_OK" -eq 0 ] && echo "  Spawn failed (no claims or ClanBrain)" && ISSUES=$((ISSUES+1))
[ "$SEARCH_ACTIVITY_OK" -eq 0 ] && echo "  No search activity (herd_wildnpc)" && ISSUES=$((ISSUES+1))
[ "$COMBAT_OK" -eq 0 ] && echo "  Dangling combat (started > ended)" && ISSUES=$((ISSUES+1))
[ "$CRASH_OR_ERROR" -eq 1 ] && echo "  Script error or crash in console" && ISSUES=$((ISSUES+1))
[ "$ISSUES" -eq 0 ] && echo "  None"
echo ""

# --- Write unified_result.env ---
{
    echo "HERD_JOINED_COUNT=$HERD_JOINED_COUNT"
    echo "HERD_WILDNPC_ENTER_COUNT=$HERD_WILDNPC_ENTER_COUNT"
    echo "GATHER_COUNT=$GATHER_COUNT"
    echo "DEPOSIT_COUNT=$DEPOSIT_COUNT"
    echo "GATHER_PER_MIN=$GATHER_PER_MIN"
    echo "DEPOSIT_PER_MIN=$DEPOSIT_PER_MIN"
    echo "SPAWN_OK=$SPAWN_OK"
    echo "GATHER_OK=$GATHER_OK"
    echo "DEPOSIT_OK=$DEPOSIT_OK"
    echo "SEARCH_ACTIVITY_OK=$SEARCH_ACTIVITY_OK"
    echo "HERD_SUCCESS_OK=$HERD_SUCCESS_OK"
    echo "COMBAT_OK=$COMBAT_OK"
    echo "EFFICIENCY_PASS=$EFFICIENCY_PASS"
    echo "LAND_CLAIMS_PLACED=$LAND_CLAIMS_PLACED"
    echo "CLANBRAIN_INITS=$CLANBRAIN_INITS"
    echo "MILESTONE_PLACED_COUNT=$MILESTONE_PLACED_COUNT"
    echo "BABY_SPAWNED_COUNT=$BABY_SPAWNED_COUNT"
    echo "BABY_GREW_COUNT=$BABY_GREW_COUNT"
    echo "DURATION_MIN=$DURATION_MIN"
    echo "ISSUES=$ISSUES"
} > "$RESULT_ENV" 2>/dev/null
echo "Result env: $RESULT_ENV"

# --- Write unified_report.md ---
{
    echo "# Unified Test Report: Clansmen Efficiency"
    echo ""
    echo "**Log dir:** \`$LOG_DIR\`"
    echo ""
    echo "## Efficiency summary"
    echo "- **Herding success** (NPCs joined clan): $HERD_JOINED_COUNT"
    echo "- **Search activity** (herd_wildnpc enter): $HERD_WILDNPC_ENTER_COUNT"
    echo "- **Gathers:** $GATHER_COUNT (per min: $GATHER_PER_MIN)"
    echo "- **Deposits:** $DEPOSIT_COUNT (per min: $DEPOSIT_PER_MIN)"
    echo ""
    echo "## Pass/fail"
    echo "- Spawn OK: $SPAWN_OK  |  Gather OK: $GATHER_OK  |  Deposit OK: $DEPOSIT_OK"
    echo "- Search activity OK: $SEARCH_ACTIVITY_OK  |  Herd success OK: $HERD_SUCCESS_OK"
    echo "- Combat OK: $COMBAT_OK  |  **EFFICIENCY_PASS: $EFFICIENCY_PASS**"
    echo ""
    echo "## Supporting metrics"
    echo "- Land claims: $LAND_CLAIMS_PLACED  |  ClanBrain inits: $CLANBRAIN_INITS"
    echo "- Milestone buildings: $MILESTONE_PLACED_COUNT  |  Babies spawned: $BABY_SPAWNED_COUNT  |  Babies grew: $BABY_GREW_COUNT"
    echo "- State distribution (last): wander=$WANDER_END gather=$GATHER_END deposit=$DEPOSIT_END herd=$HERD_END herd_wildnpc=$HERD_WILDNPC_END defend=$DEFEND_END idle=$IDLE_END"
    echo ""
    echo "## Red flags"
    [ "$ISSUES" -eq 0 ] && echo "- None"
    [ "$GATHER_COUNT" -eq 0 ] && echo "- Zero gathers"
    [ "$DEPOSIT_COUNT" -eq 0 ] && echo "- Zero deposits"
    [ "$SPAWN_OK" -eq 0 ] && echo "- Spawn failed"
    [ "$SEARCH_ACTIVITY_OK" -eq 0 ] && echo "- No search activity"
    [ "$COMBAT_OK" -eq 0 ] && echo "- Dangling combat"
    [ "$CRASH_OR_ERROR" -eq 1 ] && echo "- Crash or script error"
} > "$REPORT_MD" 2>/dev/null
echo "Report: $REPORT_MD"
echo ""
echo "=========================================="
echo "Unified analysis complete."
echo "=========================================="

[ "$EFFICIENCY_PASS" -eq 1 ] && exit 0 || exit 1
