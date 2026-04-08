#!/bin/bash

# Analysis script for Test 2: Herding Competition
# Analyzes herded NPCs and deposited items per caveman

LOG_FILE="Tests/test2_herding_competition.log"

if [ ! -f "$LOG_FILE" ]; then
    echo "Error: Log file not found: $LOG_FILE"
    echo "Please run Test 2 first: ./Tests/TEST2_HERDING_COMPETITION.sh"
    exit 1
fi

echo "=========================================="
echo "Test 2 Analysis: Herding Competition"
echo "=========================================="
echo ""

# Get all cavemen from deposits
echo "=== CAVEMEN PARTICIPANTS ==="
echo ""
CAVEMEN=$(grep "✅ DEPOSIT SUCCESS" "$LOG_FILE" 2>/dev/null | grep -o "[A-Z]* deposited" | sed 's/ deposited//' | sort -u)
if [ -z "$CAVEMEN" ]; then
    echo "No cavemen found in deposits. Checking land claims..."
    CAVEMEN=$(grep "placed land claim\|clan_name" "$LOG_FILE" 2>/dev/null | grep -o "[A-Z]*" | head -10 | sort -u)
fi

if [ -z "$CAVEMEN" ]; then
    echo "  No cavemen found"
    exit 1
fi

echo "Cavemen: $CAVEMEN"
echo ""

# For each caveman, analyze deposits and herding
echo "=== INDIVIDUAL STATISTICS ==="
echo ""

for NPC in $CAVEMEN; do
    echo "--- $NPC ---"
    
    # Get clan name
    CLAN=$(grep "$NPC.*clan_name\|$NPC.*clan" "$LOG_FILE" 2>/dev/null | head -1 | grep -o "clan_name='[^']*'" | sed "s/clan_name='//;s/'//" | head -1)
    if [ -z "$CLAN" ]; then
        CLAN=$(grep "$NPC.*deposited" "$LOG_FILE" 2>/dev/null | head -1 | grep -o "clan=[^ ]*" | sed "s/clan=//" | head -1)
    fi
    
    if [ -n "$CLAN" ]; then
        echo "  Clan: $CLAN"
    fi
    
    # Count deposits
    DEPOSITS=$(grep "✅ DEPOSIT SUCCESS.*$NPC" "$LOG_FILE" 2>/dev/null | wc -l | tr -d ' ')
    echo "  Deposits: $DEPOSITS"
    
    # Count items deposited (from deposit success messages)
    ITEMS=$(grep "✅ DEPOSIT SUCCESS.*$NPC" "$LOG_FILE" 2>/dev/null | grep -o "deposited [0-9]*" | awk '{sum+=$2} END {print sum+0}')
    echo "  Items deposited: ${ITEMS:-0}"
    
    # Count herded NPCs (NPCs that joined this clan)
    if [ -n "$CLAN" ]; then
        HERDED=$(grep "joined.*clan\|clan_name.*$CLAN" "$LOG_FILE" 2>/dev/null | grep -c "$CLAN" || echo "0")
        echo "  NPCs in clan: $HERDED"
    else
        echo "  NPCs in clan: 0 (clan name not found)"
    fi
    
    # Count herd_wildnpc state entries
    HERD_ATTEMPTS=$(grep "FSM TRANSITION TO HERD_WILDNPC.*$NPC\|herd_wildnpc.*$NPC" "$LOG_FILE" 2>/dev/null | wc -l | tr -d ' ')
    echo "  Herding attempts: $HERD_ATTEMPTS"
    
    echo ""
done

# Overall statistics
echo "=== OVERALL STATISTICS ==="
echo ""
echo "Total deposits: $(grep -c "✅ DEPOSIT SUCCESS" "$LOG_FILE" 2>/dev/null || echo "0")"
echo "Total gathers: $(grep -c "✅ GATHER:" "$LOG_FILE" 2>/dev/null || echo "0")"
echo "Total herd_wildnpc entries: $(grep -c "FSM TRANSITION TO HERD_WILDNPC" "$LOG_FILE" 2>/dev/null || echo "0")"
echo "Total NPCs that joined clans: $(grep -c "joined.*clan\|clan_name.*set" "$LOG_FILE" 2>/dev/null || echo "0")"
echo ""

# Winner determination
echo "=== WINNER DETERMINATION ==="
echo ""
echo "Top depositors:"
grep "✅ DEPOSIT SUCCESS" "$LOG_FILE" 2>/dev/null | grep -o "[A-Z]* deposited" | sed 's/ deposited//' | sort | uniq -c | sort -rn | head -5
echo ""


