# Herding Test Run Analysis (post parse-error fix)

## Summary

**Herding is working.** The script fix (removed stray `p` in `herd_wildnpc_state.gd`) allowed the state to load. Cavemen do enter `herd_wildnpc`, find wild women, herd them to the claim, and deliveries complete.

## Data from last run

| Metric | Value |
|--------|--------|
| **NPCs joined clans** | 23 (from "joined clan" / "delivery complete" style logs) |
| **Successful deliveries** | 12 (explicit "target X joined clan 'Y' - delivery complete") |
| **herd_wildnpc entries** | Multiple (ZIBA, LOXA, QIRO, XOSA, REIS, XOFA, RUIM, SIVI, MANE, etc.) |
| **"Herd state entries" in script** | 0 ← **wrong**: test grep pattern doesn’t match log format |

## Issues found

### 1. Test script grep (fixed)

- **Problem:** `TEST2_HERDING_COMPETITION.sh` greps for `FSM TRANSITION TO HERD_WILDNPC` or `FSM TRANSITION TO HERD`. The FSM only prints that style for **gather**, not for herd/herd_wildnpc. Entries are logged as `STATE_ENTRY: X entered herd_wildnpc (from Y)`.
- **Fix:** Use a pattern that exists, e.g. `STATE_ENTRY.*herd_wildnpc` or `entered herd_wildnpc` or count `delivery complete`.

### 2. no_land_claim gate

- Cavemen **cannot** enter `herd_wildnpc` until they have a land claim (`clan_name` set).
- Log: `cannot enter herd_wildnpc (no_land_claim) reason_detail=caveman_must_have_land_claim_first clan_name_val=empty`.
- So for the first ~10+ seconds (place-claim cooldown), herd_wildnpc is blocked. This is by design.

### 3. Rapid-move / far-from-claim

- Some chases fail with: `target LOTA rapidly moving away (101px/s) and caveman far from claim (909px) - starting grace timer`.
- Same caveman (e.g. QIRO) can hit this repeatedly → chase abandoned or thrashing. May be worth tuning `rapid_move_timeout` or max distance-from-claim for pursuit.

### 4. "Potentially stuck" warning

- Log: `ZIBA in herd_wildnpc for 5.3s (LONG - potentially stuck!)`. Delivery completed right after (SOOH joined clan). Likely a false positive or threshold too low for a valid ~5s chase.

### 5. Game process ended early

- Run stopped around 2:30 instead of full 3 minutes. Check for crash/quit (end of log or Godot stderr).

## Recommendations

1. **Done:** Fix test script herd-stats to use `STATE_ENTRY.*herd_wildnpc` or `delivery complete` so "Herd state entries" reflects reality.
2. **Optional:** Add an FSM print for transition-to-herd_wildnpc (like gather) for easier grepping.
3. **Optional:** Tune rapid-move / max-distance-from-claim in `herd_wildnpc_state.gd` if chases are abandoned too often.
4. **Optional:** Investigate why the game process exits before 3 minutes.
