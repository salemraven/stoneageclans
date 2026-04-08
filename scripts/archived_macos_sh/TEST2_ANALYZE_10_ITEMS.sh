#!/bin/bash

# Analysis script for Test 2: Land Claim 10 Items Gathering Time
# Analyzes the log file to determine how long it took to gather 10 of each item

LOG_FILE="Tests/test2_land_claim_10_items.log"

if [ ! -f "$LOG_FILE" ]; then
    echo "Error: Log file not found: $LOG_FILE"
    echo "Please run Test 2 first: ./Tests/TEST2_LAND_CLAIM_10_ITEMS.sh"
    exit 1
fi

echo "=========================================="
echo "Test 2 Analysis: Land Claim 10 Items Time"
echo "=========================================="
echo ""

# Find first deposit for each NPC
echo "NPCs with deposits:"
grep "DEPOSIT SUCCESS" "$LOG_FILE" | grep -o "[A-Z]* (.*) deposited" | sed 's/ (.*//' | sort -u
echo ""

# For each NPC, track when they reach 10 of each item
echo "Analyzing each NPC's progress..."
echo ""

# Get all unique NPC names that deposited
NPCS=$(grep "DEPOSIT SUCCESS" "$LOG_FILE" | grep -o "[A-Z]* (" | sed 's/ (//' | sort -u)

for NPC in $NPCS; do
    echo "=== $NPC ==="
    
    # Extract all deposits for this NPC
    NPC_DEPOSITS=$(grep "DEPOSIT SUCCESS.*$NPC" "$LOG_FILE")
    
    if [ -z "$NPC_DEPOSITS" ]; then
        echo "  No deposits found"
        continue
    fi
    
    # Track when each resource type reaches 10
    BERRIES_10=$(echo "$NPC_DEPOSITS" | grep "Berries" | grep "now has 1[0-9] Berries\|now has [1-9][0-9] Berries" | head -1)
    WOOD_10=$(echo "$NPC_DEPOSITS" | grep "Wood" | grep "now has 1[0-9] Wood\|now has [1-9][0-9] Wood" | head -1)
    STONE_10=$(echo "$NPC_DEPOSITS" | grep "Stone" | grep "now has 1[0-9] Stone\|now has [1-9][0-9] Stone" | head -1)
    FIBER_10=$(echo "$NPC_DEPOSITS" | grep "Fiber" | grep "now has 1[0-9] Fiber\|now has [1-9][0-9] Fiber" | head -1)
    GRAIN_10=$(echo "$NPC_DEPOSITS" | grep "Grain" | grep "now has 1[0-9] Grain\|now has [1-9][0-9] Grain" | head -1)
    
    # Get latest counts
    LATEST_BERRIES=$(echo "$NPC_DEPOSITS" | grep "Berries" | tail -1 | grep -o "now has [0-9]* Berries" | grep -o "[0-9]*" || echo "0")
    LATEST_WOOD=$(echo "$NPC_DEPOSITS" | grep "Wood" | tail -1 | grep -o "now has [0-9]* Wood" | grep -o "[0-9]*" || echo "0")
    LATEST_STONE=$(echo "$NPC_DEPOSITS" | grep "Stone" | tail -1 | grep -o "now has [0-9]* Stone" | grep -o "[0-9]*" || echo "0")
    LATEST_FIBER=$(echo "$NPC_DEPOSITS" | grep "Fiber" | tail -1 | grep -o "now has [0-9]* Fiber" | grep -o "[0-9]*" || echo "0")
    LATEST_GRAIN=$(echo "$NPC_DEPOSITS" | grep "Grain" | tail -1 | grep -o "now has [0-9]* Grain" | grep -o "[0-9]*" || echo "0")
    
    echo "  Current inventory:"
    echo "    Berries: $LATEST_BERRIES/10"
    echo "    Wood: $LATEST_WOOD/10"
    echo "    Stone: $LATEST_STONE/10"
    echo "    Fiber: $LATEST_FIBER/10"
    echo "    Grain: $LATEST_GRAIN/10"
    echo ""
    
    # Check if all reached 10
    if [ "$LATEST_BERRIES" -ge 10 ] && [ "$LATEST_WOOD" -ge 10 ] && [ "$LATEST_STONE" -ge 10 ] && [ "$LATEST_FIBER" -ge 10 ] && [ "$LATEST_GRAIN" -ge 10 ]; then
        echo "  ✅ COMPLETE! All items reached 10!"
        
        # Find timestamps for when each reached 10
        if [ -n "$BERRIES_10" ]; then
            echo "    Berries reached 10: Found in log"
        fi
        if [ -n "$WOOD_10" ]; then
            echo "    Wood reached 10: Found in log"
        fi
        if [ -n "$STONE_10" ]; then
            echo "    Stone reached 10: Found in log"
        fi
        if [ -n "$FIBER_10" ]; then
            echo "    Fiber reached 10: Found in log"
        fi
        if [ -n "$GRAIN_10" ]; then
            echo "    Grain reached 10: Found in log"
        fi
    else
        echo "  ⏳ In progress..."
    fi
    echo ""
done

# Overall statistics
echo "=========================================="
echo "Overall Statistics"
echo "=========================================="
echo ""
echo "Total deposits: $(grep -c "DEPOSIT SUCCESS" "$LOG_FILE")"
echo "Total gathers: $(grep -c "✅ GATHER:" "$LOG_FILE")"
echo ""
echo "NPCs that deposited:"
grep "DEPOSIT SUCCESS" "$LOG_FILE" | grep -o "[A-Z]* (" | sed 's/ (//' | sort | uniq -c | sort -rn
echo ""


