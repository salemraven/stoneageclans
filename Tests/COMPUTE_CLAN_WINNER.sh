#!/bin/bash
# Parse game_console.log for items deposited per clan and herd NPCs (joined clan) per clan.
# Output per-clan totals and winner (combined score: items + HERD_WEIGHT * herd_npcs).
# Usage: ./Tests/COMPUTE_CLAN_WINNER.sh <LOG_DIR>
# Writes: <LOG_DIR>/winner.txt
# Portable (macOS and Linux).

LOG_DIR="${1:-.}"
CONSOLE="$LOG_DIR/game_console.log"
OUT="$LOG_DIR/winner.txt"
HERD_WEIGHT="${HERD_WEIGHT:-5}"

if [ ! -f "$CONSOLE" ]; then
    echo "Error: $CONSOLE not found" >&2
    exit 1
fi

# Items: "Competition: NPC (CLAN) deposited N" or "AUTO-DEPOSIT: ... land claim 'CLAN'"
# Output tab-sep: I	clan	n (clan may have spaces)
grep -E 'Competition:.*\(.*\) deposited [0-9]+|AUTO-DEPOSIT:.*deposited [0-9]+ items.*land claim' "$CONSOLE" 2>/dev/null | while read -r line; do
    if echo "$line" | grep -qE 'Competition:.*\(.*\) deposited [0-9]+'; then
        clan=$(echo "$line" | sed -n 's/.*(\([^)]*\)) deposited [0-9]*.*/\1/p')
        n=$(echo "$line" | sed -n 's/.*deposited \([0-9]*\).*/\1/p')
        [ -n "$clan" ] && [ -n "$n" ] && printf "I\t%s\t%s\n" "$clan" "$n"
    elif echo "$line" | grep -q "AUTO-DEPOSIT:.*land claim '"; then
        clan=$(echo "$line" | sed -n "s/.*land claim '\([^']*\)'.*/\1/p")
        n=$(echo "$line" | sed -n 's/.*deposited \([0-9]*\) items.*/\1/p')
        [ -n "$clan" ] && [ -n "$n" ] && printf "I\t%s\t%s\n" "$clan" "$n"
    fi
done > "$LOG_DIR/items.tmp"

# Herds: "joined clan 'X'" -> tab-sep H	clan	count
grep "joined clan '" "$CONSOLE" 2>/dev/null | sed "s/.*joined clan '\\([^']*\\)'.*/\1/" | sort | uniq -c | while read count rest; do
    clan="$rest"
    [ -n "$clan" ] && printf "H\t%s\t%s\n" "$clan" "$count"
done > "$LOG_DIR/herds.tmp"

# Aggregate (tab-sep input: I/H, clan, number)
awk -F'\t' -v w="$HERD_WEIGHT" '
    $1=="I" { items[$2] += $3; next }
    $1=="H" { herds[$2] = $3; next }
    END {
        for (c in items) all[c] = 1
        for (c in herds) all[c] = 1
        best = -1
        for (c in all) {
            i = items[c] + 0
            h = herds[c] + 0
            s = i + w * h
            print c "\t" i "\t" h "\t" s
            if (s > best) { best = s; wn = c; wi = i; wh = h }
        }
        if (wn != "") print "WINNER\t" wn "\t" wi "\t" wh "\t" best
    }
' "$LOG_DIR/items.tmp" "$LOG_DIR/herds.tmp" > "$LOG_DIR/clan_agg.tmp"

# Build winner.txt (clan_agg is tab-sep: clan items herds score, or WINNER clan items herds score)
{
    echo "=== Clan totals (items + herd NPCs) ==="
    echo "HERD_WEIGHT=$HERD_WEIGHT (score = items + ${HERD_WEIGHT} * herd_npcs)"
    echo ""
    winner=""
    witems=""
    wherds=""
    wscore=""
    while IFS=$'\t' read -r a b c d e; do
        if [ "$a" = "WINNER" ]; then
            winner="$b"
            witems="$c"
            wherds="$d"
            wscore="$e"
            continue
        fi
        echo "Clan: $a | items: $b | herd_npcs: $c | score: $d"
    done < "$LOG_DIR/clan_agg.tmp"
    echo ""
    echo "=== WINNER ==="
    if [ -n "$winner" ]; then
        echo "Clan: $winner"
        echo "Items deposited: $witems"
        echo "Herd NPCs delivered: $wherds"
        echo "Combined score: $wscore"
    else
        winner_clan=""
        winner_score=-1
        winner_items=0
        winner_herds=0
        while IFS=$'\t' read -r clan items herds score rest; do
            [ "$clan" = "WINNER" ] && continue
            num=$(echo "$score" | tr -dc '0-9')
            [ -z "$num" ] && num=0
            if [ "$num" -gt "$winner_score" ] 2>/dev/null; then
                winner_score=$num
                winner_clan=$clan
                winner_items=$items
                winner_herds=$herds
            fi
        done < "$LOG_DIR/clan_agg.tmp"
        if [ -n "$winner_clan" ]; then
            echo "Clan: $winner_clan"
            echo "Items deposited: $winner_items"
            echo "Herd NPCs delivered: $winner_herds"
            echo "Combined score: $winner_score"
        else
            echo "No clans with deposits or herd joins."
        fi
    fi
} | tee "$OUT"

rm -f "$LOG_DIR/clan_agg.tmp" "$LOG_DIR/items.tmp" "$LOG_DIR/herds.tmp" 2>/dev/null
exit 0
