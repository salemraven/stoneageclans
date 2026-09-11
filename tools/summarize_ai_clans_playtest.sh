#!/usr/bin/env bash
# AI-clan focused report from playtest JSONL (excludes player TEST quickstart clan by default).
# Usage:
#   ./tools/summarize_ai_clans_playtest.sh
#   ./tools/summarize_ai_clans_playtest.sh path/to/playtest_*.jsonl
#   INCLUDE_TEST=1 ./tools/summarize_ai_clans_playtest.sh   # include TEST clan too
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
INCLUDE_TEST="${INCLUDE_TEST:-0}"

if [[ "$(uname -s)" == "Darwin" ]]; then
	USER_DATA="${HOME}/Library/Application Support/Godot/app_userdata/StoneAgeClans"
else
	USER_DATA="${HOME}/.local/share/godot/app_userdata/StoneAgeClans"
fi

JSONL="${1:-}"
if [[ -z "$JSONL" ]]; then
	JSONL="$(ls "$USER_DATA"/playtest_*.jsonl 2>/dev/null | sort -r | head -1 || true)"
fi
if [[ -z "$JSONL" || ! -f "$JSONL" ]]; then
	echo "No playtest JSONL found. Run session instrument first."
	exit 1
fi

echo "=== AI clans playtest report ==="
echo "File: $JSONL"
echo ""

python3 - "$JSONL" "$INCLUDE_TEST" <<'PY'
import json, sys, math
from collections import Counter, defaultdict

path, include_test = sys.argv[1], sys.argv[2] == "1"
PLAYER_CLAN = "TEST"

spawn_events = []
nearby_complete = None
by_clan = defaultdict(lambda: {
    "events": Counter(),
    "timeline": [],
    "spawn": None,
    "last_pop": None,
    "last_dormant": None,
    "members_last": [],
    "dormant_count": 0,
    "wake_count": 0,
    "tick_count": 0,
    "births": 0,
    "baby_grew": 0,
    "food_deltas": [],
    "workforce_modes": Counter(),
    "last_food_buffer": None,
})

settlement_evts = {
    "settlement_claim_dormant", "settlement_claim_wake",
    "settlement_roster_snapshot", "settlement_roster_detail",
    "settlement_tick_started", "settlement_tick_completed",
    "settlement_tick_food_delta",
    "settlement_pregnancy_started", "settlement_pregnancy_cancelled",
    "settlement_birth", "settlement_birth_blocked", "settlement_baby_grew",
    "settlement_husband_reassigned", "chunk_npc_spawned",
}

with open(path, encoding="utf-8") as f:
    for line in f:
        line = line.strip()
        if not line:
            continue
        try:
            obj = json.loads(line)
        except json.JSONDecodeError:
            continue
        evt = obj.get("evt", "")
        clan = str(obj.get("clan", "")).upper()

        if evt == "session_nearby_clan_spawned":
            spawn_events.append(obj)
            c = str(obj.get("clan", "")).upper()
            by_clan[c]["spawn"] = obj
            continue
        if evt == "session_nearby_clans_complete":
            nearby_complete = obj
            continue

        if evt not in settlement_evts and evt != "chunk_npc_spawned":
            continue
        if not clan:
            continue
        if not include_test and clan == PLAYER_CLAN:
            continue
        # Skip chunk spawns that aren't session nearby unless they have a clan
        if evt == "chunk_npc_spawned" and obj.get("source") not in ("session_nearby_clan", "chunk_seeded_clan"):
            continue

        st = by_clan[clan]
        st["events"][evt] += 1
        t = float(obj.get("t", 0.0))
        st["timeline"].append((t, evt, obj))

        if evt == "settlement_claim_dormant":
            st["dormant_count"] += 1
            st["last_dormant"] = True
            st["last_pop"] = obj.get("pop")
        elif evt == "settlement_claim_wake":
            st["wake_count"] += 1
            st["last_dormant"] = False
            st["last_pop"] = obj.get("pop")
        elif evt == "settlement_roster_snapshot":
            st["last_pop"] = obj.get("pop")
            st["last_dormant"] = obj.get("dormant")
        elif evt == "settlement_roster_detail":
            st["members_last"] = obj.get("members", [])
            st["last_dormant"] = obj.get("dormant")
        elif evt == "settlement_tick_started":
            st["tick_count"] += 1
        elif evt == "settlement_tick_food_delta":
            st["food_deltas"].append({
                "t": t,
                "food_before": obj.get("food_before", 0),
                "food_after": obj.get("food_after", 0),
                "food_delta": obj.get("food_delta", 0),
                "gathered_count": obj.get("gathered_count", 0),
                "consumed_count": obj.get("consumed_count", 0),
                "food_days_buffer": obj.get("food_days_buffer"),
                "workforce_mode": obj.get("workforce_mode"),
            })
            wm = str(obj.get("workforce_mode", ""))
            if wm:
                st["workforce_modes"][wm] += 1
            if obj.get("food_days_buffer") is not None:
                st["last_food_buffer"] = obj.get("food_days_buffer")
        elif evt == "settlement_birth":
            st["births"] += 1
        elif evt == "settlement_baby_grew":
            st["baby_grew"] += 1

# Prefer session_nearby spawns as canonical list
nearby_names = [str(s.get("clan", "")).upper() for s in spawn_events]
all_clans = sorted(set(list(by_clan.keys()) + nearby_names))
all_clans = [c for c in all_clans if c and (include_test or c != PLAYER_CLAN)]

if nearby_complete:
    print("--- Nearby clan ring (session quickstart) ---")
    print(f"  count={nearby_complete.get('count')} radius_px={nearby_complete.get('ring_radius_px')} player=({nearby_complete.get('player_x')}, {nearby_complete.get('player_y')})")
    print("")

if spawn_events:
    print("--- Spawned AI clans ---")
    for s in sorted(spawn_events, key=lambda x: x.get("ring_index", 0)):
        c = s.get("clan", "?")
        dist = math.hypot(float(s.get("claim_x", 0)), float(s.get("claim_y", 0)))
        angle_deg = math.degrees(math.atan2(float(s.get("claim_y", 0)), float(s.get("claim_x", 0))))
        print(f"  [{s.get('ring_index')}] {c}  leader={s.get('leader')}  claim=({s.get('claim_x')}, {s.get('claim_y')})  ~{dist:.0f}px from player  bearing={angle_deg:.0f}°")
    print("")

if not all_clans:
    print("No AI clan events found (walk to nearby claims or check --session-nearby-clans).")
    sys.exit(0)

print("--- Per-clan settlement sim ---")
for clan in all_clans:
    st = by_clan[clan]
    print(f"\n  ▶ {clan}")
    if st["spawn"]:
        sp = st["spawn"]
        print(f"     spawn: leader={sp.get('leader')} claim=({sp.get('claim_x')}, {sp.get('claim_y')})")
    elif st["events"].get("chunk_npc_spawned"):
        print("     spawn: chunk_npc_spawned (no session_nearby_clan_spawned row)")
    pop = st["last_pop"]
    dorm = st["last_dormant"]
    print(f"     last pop={pop} dormant={dorm}  dormant×{st['dormant_count']} wake×{st['wake_count']} off-screen ticks×{st['tick_count']}")
    print(f"     off-screen births×{st['births']} baby_grew×{st['baby_grew']}")
    if st["food_deltas"]:
        deltas = [d["food_delta"] for d in st["food_deltas"]]
        avg_delta = sum(deltas) / len(deltas)
        non_neg = sum(1 for d in deltas if d >= 0)
        pct_non_neg = 100.0 * non_neg / len(deltas)
        buffers = [d["food_days_buffer"] for d in st["food_deltas"] if d.get("food_days_buffer") is not None]
        buf_str = f" last_buffer={buffers[-1]:.2f}d" if buffers else ""
        wm = dict(st["workforce_modes"])
        print(f"     food: ticks={len(deltas)} avg_delta={avg_delta:+.1f} non_neg={pct_non_neg:.0f}%{buf_str} modes={wm}")
        if avg_delta < 0:
            print("     ⚠ negative food trend — may need gather yield tuning")
        elif st["last_food_buffer"] is not None and float(st["last_food_buffer"]) < 0.5:
            print("     ⚠ food buffer below 0.5d target")
    elif st["tick_count"] > 0:
        print("     food: (no settlement_tick_food_delta rows — re-run with updated build)")
    if st["members_last"]:
        names = [f"{m.get('name')}({m.get('type')})" for m in st["members_last"][:8]]
        extra = len(st["members_last"]) - len(names)
        tail = f" +{extra} more" if extra > 0 else ""
        print(f"     roster: {', '.join(names)}{tail}")
    elif pop == 1:
        print("     roster: leader only (no women/huts — off-screen births unlikely)")

    key_evts = [e for e in st["timeline"] if e[1] in (
        "settlement_claim_dormant", "settlement_claim_wake",
        "settlement_tick_started", "settlement_birth", "settlement_baby_grew",
        "settlement_husband_reassigned",
    )]
    if key_evts:
        print("     key events:")
        for t, evt, obj in sorted(key_evts):
            bits = [f"t={t:.1f}", evt]
            for k in ("pop", "pop_before", "pop_after", "dormant", "mother", "baby", "woman", "new_father"):
                if k in obj and obj[k] not in (None, ""):
                    bits.append(f"{k}={obj[k]}")
            print("       " + " ".join(bits))

# Other AI clans from worldgen (not session ring)
session_set = {c.upper() for c in nearby_names}
extra = [c for c in all_clans if c not in session_set]
if extra:
    print("\n--- Other AI clans in log (chunk/worldgen, not session ring) ---")
    for c in extra:
        st = by_clan[c]
        print(f"  {c}: pop={st['last_pop']} dormant={st['last_dormant']} ticks×{st['tick_count']}")

print("\n--- Hints ---")
any_tick = any(by_clan[c]["tick_count"] > 0 for c in all_clans)
any_dormant = any(by_clan[c]["dormant_count"] > 0 for c in all_clans)
any_wake = any(by_clan[c]["wake_count"] > 0 for c in all_clans)
if spawn_events and not any_dormant:
    print("  Walk ~1500px to a nearby claim, then leave — need settlement_claim_dormant for off-screen ticks.")
elif any_dormant and not any_tick:
    print("  Clans went dormant but no off-screen tick yet — stay away 30s+ (settlement_tick_interval).")
elif any_tick:
    print("  Off-screen ticks ran. Leaders-only clans won't birth without women in roster.")
    any_negative = False
    any_low_buffer = False
    for c in all_clans:
        st = by_clan[c]
        if not st["food_deltas"]:
            continue
        deltas = [d["food_delta"] for d in st["food_deltas"]]
        if sum(deltas) / len(deltas) < 0:
            any_negative = True
        if st["last_food_buffer"] is not None and float(st["last_food_buffer"]) < 0.5:
            any_low_buffer = True
    if any_negative:
        print("  ⚠ Some clans lost food on average — consider raising gather_yield_per_population (berries/grain).")
    if any_low_buffer:
        print("  ⚠ Some clans below 0.5d food buffer — check gather_regen_per_sim_day / gather_yield or dev bootstrap.")
    if not any_negative and not any_low_buffer and any(st["food_deltas"] for st in (by_clan[c] for c in all_clans)):
        print("  ✓ Food balance looks stable (non-negative ticks, buffer ≥ 0.5d where logged).")
if any_wake:
    print("  ✓ At least one AI claim woke when you returned.")
print("\n=== End ===")
PY
