#!/bin/bash

# Quick analysis script for Test 3 gather/deposit efficiency results

LOG_FILE="Tests/test3_gather_deposit_efficiency.log"

if [ ! -f "$LOG_FILE" ]; then
    echo "Error: Log file not found: $LOG_FILE"
    echo "Please run Test 3 first: ./Tests/TEST3_RUN_GATHER_DEPOSIT.sh"
    exit 1
fi

echo "=========================================="
echo "Gather & Deposit Efficiency Analysis"
echo "=========================================="
echo ""

# Gather Metrics
GATHER_COUNT=$(grep -c "✅ GATHER:" "$LOG_FILE" 2>/dev/null || echo "0")
SEARCH_COUNT=$(grep -c "🔍 SEARCH MODE:" "$LOG_FILE" 2>/dev/null || echo "0")
GATHER_BLOCKS=$(grep -c "❌ GATHER CAN_ENTER:" "$LOG_FILE" 2>/dev/null || echo "0")
GATHER_STOP=$(grep -c "🛑 GATHER STOP:" "$LOG_FILE" 2>/dev/null || echo "0")

echo "GATHER METRICS:"
echo "  ✅ Successful gathers: $GATHER_COUNT"
echo "  🔍 Search mode activations: $SEARCH_COUNT"
echo "  ❌ Gather blocks: $GATHER_BLOCKS"
echo "  🛑 Gather stops (threshold reached): $GATHER_STOP"
if [ "$GATHER_COUNT" -gt 0 ]; then
    SEARCH_RATIO=$(echo "scale=1; $SEARCH_COUNT * 100 / ($GATHER_COUNT + $SEARCH_COUNT)" | bc 2>/dev/null || echo "0")
    echo "  📊 Search mode ratio: ${SEARCH_RATIO}%"
fi
echo ""

# Deposit Metrics
DEPOSIT_COUNT=$(grep -c "✅ DEPOSIT SUCCESS:" "$LOG_FILE" 2>/dev/null || echo "0")
DEPOSIT_BLOCKS=$(grep -c "❌ DEPOSIT CAN_ENTER:" "$LOG_FILE" 2>/dev/null || echo "0")
DEPOSIT_ENTRIES=$(grep -c "📍 DEPOSIT:" "$LOG_FILE" 2>/dev/null || echo "0")

echo "DEPOSIT METRICS:"
echo "  ✅ Successful deposits: $DEPOSIT_COUNT"
echo "  ❌ Deposit blocks: $DEPOSIT_BLOCKS"
echo "  📍 Deposit state entries: $DEPOSIT_ENTRIES"

# Check for single-item deposits
SINGLE_ITEM_DEPOSITS=$(grep "DEPOSIT:" "$LOG_FILE" | grep -c "with 1 items" 2>/dev/null || echo "0")
if [ "$SINGLE_ITEM_DEPOSITS" -gt 0 ]; then
    echo "  ⚠️  Single-item deposits: $SINGLE_ITEM_DEPOSITS (should be 0)"
else
    echo "  ✅ No single-item deposits (good!)"
fi
echo ""

# Efficiency Metrics
TRANSITIONS=$(grep -c "FSM TRANSITION" "$LOG_FILE" 2>/dev/null || echo "0")
GATHER_TRANSITIONS=$(grep -c "FSM TRANSITION TO GATHER" "$LOG_FILE" 2>/dev/null || echo "0")
DEPOSIT_TRANSITIONS=$(grep -c "FSM TRANSITION TO DEPOSIT" "$LOG_FILE" 2>/dev/null || echo "0")

echo "EFFICIENCY METRICS:"
echo "  🔄 Total state transitions: $TRANSITIONS"
echo "  🔄 Gather transitions: $GATHER_TRANSITIONS"
echo "  🔄 Deposit transitions: $DEPOSIT_TRANSITIONS"
echo ""

# Competition Results
echo "COMPETITION RESULTS (Total Items Deposited):"
grep "deposited.*items" "$LOG_FILE" | tail -10 | while read line; do
    echo "  $line"
done
echo ""

# Calculate per-minute rates (assuming 5 minute test)
echo "PER-MINUTE RATES (assuming 5-minute test):"
if [ "$GATHER_COUNT" -gt 0 ]; then
    GATHER_PER_MIN=$(echo "scale=1; $GATHER_COUNT / 5" | bc 2>/dev/null || echo "0")
    echo "  📈 Gathers per minute: $GATHER_PER_MIN"
fi
if [ "$DEPOSIT_COUNT" -gt 0 ]; then
    DEPOSIT_PER_MIN=$(echo "scale=1; $DEPOSIT_COUNT / 5" | bc 2>/dev/null || echo "0")
    echo "  📈 Deposits per minute: $DEPOSIT_PER_MIN"
fi
if [ "$GATHER_COUNT" -gt 0 ] && [ "$DEPOSIT_COUNT" -gt 0 ]; then
    CYCLES_PER_MIN=$(echo "scale=1; $DEPOSIT_COUNT / 5" | bc 2>/dev/null || echo "0")
    echo "  📈 Complete cycles per minute: $CYCLES_PER_MIN"
fi
echo ""

# Efficiency Assessment
echo "EFFICIENCY ASSESSMENT:"
if [ "$GATHER_COUNT" -lt 15 ]; then
    echo "  ⚠️  Low gather rate (< 3 per minute)"
else
    echo "  ✅ Good gather rate (≥ 3 per minute)"
fi

if [ "$DEPOSIT_COUNT" -lt 2 ]; then
    echo "  ⚠️  Low deposit rate (< 0.4 per minute)"
else
    echo "  ✅ Good deposit rate (≥ 0.4 per minute)"
fi

if [ "$SINGLE_ITEM_DEPOSITS" -gt 0 ]; then
    echo "  ⚠️  Single-item deposits detected (threshold not working)"
else
    echo "  ✅ No single-item deposits (threshold working)"
fi

if [ "$SEARCH_COUNT" -gt "$GATHER_COUNT" ]; then
    echo "  ⚠️  High search mode ratio (> 50%)"
else
    echo "  ✅ Low search mode ratio (< 50%)"
fi
echo ""

echo "=========================================="
echo "Analysis Complete"
echo "=========================================="
echo ""
echo "For detailed analysis, review: $LOG_FILE"
echo "Create analysis report: Tests/TEST3_GATHER_DEPOSIT_EFFICIENCY_ANALYSIS.md"
echo ""


