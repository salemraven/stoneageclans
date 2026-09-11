#!/usr/bin/env bash
# Summarize Phase 7 / reproduction events from playtest JSONL.
# Usage:
#   ./tools/summarize_phase7_playtest.sh                    # newest playtest_*.jsonl (macOS user data)
#   ./tools/summarize_phase7_playtest.sh path/to/file.jsonl
#   CLAN=TEST ./tools/summarize_phase7_playtest.sh          # filter one clan
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CLAN_FILTER="${CLAN:-}"

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
	echo "No playtest JSONL found."
	echo "Run with: --session-quickstart --session-instrument (or --playtest-capture)"
	echo "Usage: $0 [path/to/playtest_*.jsonl]"
	exit 1
fi

echo "=== Phase 7 playtest summary ==="
echo "File: $JSONL"
if [[ -n "$CLAN_FILTER" ]]; then
	echo "Clan filter: $CLAN_FILTER"
fi
echo ""

python3 - "$JSONL" "$CLAN_FILTER" <<'PY'
import json, sys
from collections import Counter

path, clan_filter = sys.argv[1], sys.argv[2].upper()
watch = {
    "phase7_playtest_briefing",
    "baby_pregnancy_started",
    "baby_spawned",
    "baby_pregnancy_cancelled",
    "baby_grew_to_clansman",
    "settlement_claim_dormant",
    "settlement_claim_wake",
    "settlement_roster_snapshot",
    "settlement_roster_detail",
    "settlement_tick_started",
    "settlement_tick_completed",
    "settlement_pregnancy_started",
    "settlement_pregnancy_cancelled",
    "settlement_birth",
    "settlement_birth_blocked",
    "settlement_baby_grew",
    "settlement_husband_reassigned",
}

rows = []
counts = Counter()
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
        if evt not in watch:
            continue
        c = str(obj.get("clan", "")).upper()
        if clan_filter and c and c != clan_filter:
            continue
        rows.append(obj)
        counts[evt] += 1

if not rows:
    print("No Phase 7 events in this file" + (f" for clan {clan_filter}" if clan_filter else "") + ".")
    print("Make sure you used --session-instrument + --session-quickstart or --playtest-capture.")
    sys.exit(0)

print("--- Event counts ---")
for evt in sorted(counts.keys()):
    print(f"  {evt}: {counts[evt]}")

brief = [r for r in rows if r.get("evt") == "phase7_playtest_briefing"]
if brief:
    b = brief[0]
    print("\n--- Test guide (from log) ---")
    for step in b.get("steps", []):
        print(f"  • {step}")
    print(f"  pregnancy_sec={b.get('pregnancy_sec')} tick_interval_sec={b.get('tick_interval_sec')}")

print("\n--- Timeline (t = seconds since session start) ---")
for obj in rows:
    t = obj.get("t", 0.0)
    evt = obj.get("evt", "?")
    bits = [f"t={t:.2f}", evt]
    for k in ("clan", "npc", "mother", "baby", "father", "pop", "pop_before", "pop_after", "reason", "dormant", "source", "woman", "old_father", "new_father"):
        if k in obj and obj[k] not in (None, ""):
            bits.append(f"{k}={obj[k]}")
    if evt == "settlement_roster_detail" and "members" in obj:
        bits.append(f"members={len(obj['members'])}")
    print("  " + " ".join(bits))

print("\n--- Pass / fail hints ---")
has_dormant = counts.get("settlement_claim_dormant", 0) > 0
has_tick = counts.get("settlement_tick_started", 0) > 0
has_off_birth = counts.get("settlement_birth", 0) > 0
has_off_grow = counts.get("settlement_baby_grew", 0) > 0
has_on_birth = counts.get("baby_spawned", 0) > 0
has_wake = counts.get("settlement_claim_wake", 0) > 0
cancelled = counts.get("settlement_pregnancy_cancelled", 0) + counts.get("baby_pregnancy_cancelled", 0)

if has_on_birth:
    print("  ✓ On-screen birth(s) logged (baby_spawned)")
else:
    print("  ? No on-screen birth yet — stay at claim ~10s or check Living Hut")

if has_dormant:
    print("  ✓ Claim went dormant (you left the area)")
else:
    print("  ✗ No settlement_claim_dormant — walk farther from TEST claim")

if has_tick:
    print("  ✓ Off-screen settlement tick ran")
else:
    print("  ✗ No settlement_tick_started — wait 30–60s while away from claim")

if has_off_birth or has_off_grow:
    print("  ✓ Off-screen population change (settlement_birth or settlement_baby_grew)")
elif has_tick:
    print("  ? Ticks ran but no off-screen birth/growth — roster may lack pregnant women or food")

if has_wake:
    print("  ✓ Claim woke when you returned")

if cancelled:
    print(f"  ⚠ Pregnancy cancelled {cancelled} time(s) — check food buffer")

print("\n=== End ===")
PY
