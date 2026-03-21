# Herding System Deep Dive Report - Why Herding is Still Broken

## Executive Summary

**Test Duration:** 180 seconds  
**Caveman:** QABE  
**Status:** 🔴 **CRITICAL FAILURE - Herding System Non-Functional**

### Key Findings:
- **Only 1 herd_wildnpc state entry** in 180 seconds
- **0 NPCs joined clan** (0% success rate)
- **2 herding attempts total** (both by Player, not AI caveman)
- **Caveman stuck at land claim** for 98% of time
- **Target never herded** despite being tracked for entire session

---

## Issue #1: Caveman Only Entered herd_wildnpc Once

### Evidence
```
🔄 STATE_ENTRY: QABE entered gather (from wander)
⏱️ STATE_EXIT: QABE exited gather after 0.0s
🔄 STATE_ENTRY: QABE entered herd_wildnpc (from gather)
[QABE stays in herd_wildnpc for entire rest of test]
[Never exits, never re-enters]
```

### Root Cause Analysis

**State Priority Issue:**
- `gather_state` priority: 7.0-8.0
- `herd_wildnpc_state` priority: 10.6
- Caveman exits gather immediately (0.0s) and enters herd_wildnpc
- But once in herd_wildnpc, **never exits** even when stuck

**Why Caveman Never Exits:**
1. Target (Sheep 1664) is always "valid" according to `_is_valid_target()`
2. Even though target never herds, validation doesn't fail
3. No timeout mechanism when target fails to herd
4. Caveman stays in state forever

### Impact: **CRITICAL**
- Caveman spends 100% of time in herd_wildnpc state
- Never searches for other targets
- Never switches to other productive activities

---

## Issue #2: Target Never Enters Herd State

### Evidence
```
📍 HERD_WILDNPC: QABE at (2112.1, 832.0), target=Sheep 1664, distance_to_claim=0.1/400.0
[Sheep 1664 positions show it's in wander state, never herd state]
[No log entries: "Sheep 1664 started following" or "entered herd"]
```

### Root Cause Analysis

**Herding Chance Roll Requirements:**
- `_try_herd_chance()` is only called when `woman_distance <= herding_range` (300px)
- Code location: Line 346 in `herd_wildnpc_state.gd`

**What Happened:**
1. QABE tracked Sheep 1664 to land claim (869px → 0.1px from claim)
2. When QABE reached claim center (0.1px), **sheep was likely >300px away**
3. Distance check: `woman_distance <= herding_range` failed
4. `_try_herd_chance()` was **never called**
5. Sheep stayed in wander state forever

**Distance Calculation Issue:**
- `woman_distance` = distance from QABE to Sheep 1664
- QABE at claim center: (2112.1, 832.0)
- Sheep 1664 at: (~600-650 range based on logs)
- Distance: **~1500px** (far beyond 300px herding range)

### Impact: **CRITICAL**
- Target never becomes herded
- Caveman waits forever at claim center
- No progress made

---

## Issue #3: No Herding Range Extension at Claim Center

### Problem
When caveman reaches land claim center (<50px), target is often >300px away. Current code:
- Only calls `_try_herd_chance()` if `woman_distance <= 300px`
- No extension of range when at claim center
- Caveman can't herd targets that are following behind

### Missing Logic
**Should have:**
```gdscript
# Extend herding range when at claim center
if land_claim and npc.global_position.distance_to(land_claim.global_position) < 50.0:
    effective_herding_range = herding_range * 2.0  # 600px
else:
    effective_herding_range = herding_range  # 300px

if woman_distance <= effective_herding_range:
    target_woman._try_herd_chance(npc)
```

**Current code:** Uses fixed 300px range always

### Impact: **HIGH**
- Targets that trail behind can never be herded
- Caveman stuck waiting at claim center

---

## Issue #4: No Timeout When Target Fails to Herd

### Problem
Caveman waits indefinitely at claim center for target that never herds.

**Missing Logic:**
- No timeout check when target doesn't herd after reaching claim
- No exit condition when target stays un-herded for >3 seconds
- `_is_valid_target()` always returns true (target is valid, just not herded)

### Impact: **CRITICAL**
- Caveman stuck forever waiting
- No recovery mechanism

---

## Issue #5: Target Validation Too Permissive

### Current Validation (`_is_valid_target()`):
```gdscript
func _is_valid_target(target: Node2D, clan_name: String, current_time: float) -> bool:
    # Checks: target exists, is valid, is wild, outside claim
    # BUT: Never checks if target is actually herded by us
    # Returns true even if target never herds
```

### Problem
- Returns `true` for targets that are:
  - Valid and wild ✅
  - Outside claim ✅
  - But **never actually herded** ❌

### Missing Check
Should also check:
- If at claim center AND target not herded for >3 seconds → invalidate
- If target distance >5000px → invalidate (already added, but might need tuning)

### Impact: **HIGH**
- Caveman never exits herd_wildnpc state
- Target remains "valid" forever

---

## Issue #6: Reverse Herding Fix Too Aggressive?

### Observation
- Reverse herding fix worked (distance decreased 869px → 0.1px) ✅
- But might have caused caveman to reach claim center before target

### Hypothesis
- Intercept validation (200px threshold) might be too strict
- When intercept is rejected, caveman leads directly to claim
- Caveman reaches claim before target can catch up
- Target is now >300px away and can never herd

### Impact: **MEDIUM**
- Fix works for preventing reverse herding
- But creates new problem of caveman arriving too early

---

## Issue #7: Only Player Herding, Not AI

### Evidence
```
Herding Started: 2
- NPC Woman 4 started following Player
- NPC Woman 1 started following Player

No entries: "started following NPC QABE" or "started following NPC"
```

### Root Cause
- QABE never successfully called `_try_herd_chance()` on any target
- Only Player character successfully herded NPCs
- AI caveman herding completely non-functional

### Impact: **CRITICAL**
- AI herding system broken
- Only manual player herding works

---

## Issue #8: State Machine Not Re-Evaluating

### Problem
- QABE enters herd_wildnpc once
- Never exits
- FSM never re-evaluates to switch states

### Possible Causes
1. Target always "valid" → state never exits
2. No timeout/exit conditions met
3. FSM evaluation might not be triggering properly

### Impact: **HIGH**
- Caveman stuck in non-productive state
- System doesn't recover

---

## Issue #9: Gather State Still Taking Precedence

### Evidence
```
🔄 STATE_ENTRY: QABE entered gather (from wander)
⏱️ STATE_EXIT: QABE exited gather after 0.0s
🔄 STATE_ENTRY: QABE entered herd_wildnpc (from gather)
```

### Observation
- QABE entered gather state first
- Even though priority is lower (7.0-8.0 vs 10.6)
- Suggests gather state `can_enter()` returned true before herd_wildnpc was evaluated

### Impact: **LOW-MEDIUM**
- Minor delay, but not critical
- Gather exited immediately (0.0s)

---

## Issue #10: No Logging of Herding Attempts

### Missing Information
- No logs showing `_try_herd_chance()` being called by QABE
- No logs showing chance roll results
- No logs showing why herding failed
- Makes debugging very difficult

### Needed Logging
```gdscript
# When calling _try_herd_chance
print("🔵 HERD_ATTEMPT: %s trying to herd %s (distance: %.1fpx, range: %.1fpx)" % [
    npc.npc_name, target.get("npc_name"), woman_distance, effective_herding_range
])

# In _try_herd_chance
print("🎲 HERD_CHANCE: %s rolled %.1f%% (need %.1f%%, distance: %.1fpx)" % [
    target.npc_name, chance * 100, roll_threshold * 100, distance
])
```

### Impact: **MEDIUM**
- Hard to diagnose why herding fails
- No visibility into system behavior

---

## Summary of Critical Issues

| # | Issue | Severity | Impact |
|---|-------|----------|--------|
| 1 | Caveman only enters herd_wildnpc once | 🔴 CRITICAL | 0% herding activity |
| 2 | Target never enters herd state | 🔴 CRITICAL | 0% success rate |
| 3 | No herding range extension at claim center | 🔴 CRITICAL | Targets can't be herded |
| 4 | No timeout when target fails to herd | 🔴 CRITICAL | Caveman stuck forever |
| 5 | Target validation too permissive | 🔴 HIGH | Never exits state |
| 6 | Reverse herding fix too aggressive | 🟡 MEDIUM | Caveman arrives too early |
| 7 | Only player herding works, not AI | 🔴 CRITICAL | AI system broken |
| 8 | State machine not re-evaluating | 🔴 HIGH | No recovery |
| 9 | Gather state taking precedence | 🟡 LOW | Minor delay |
| 10 | No logging of herding attempts | 🟡 MEDIUM | Hard to debug |

---

## Root Cause Chain

1. **Caveman enters herd_wildnpc** → Targets Sheep 1664
2. **Caveman leads to claim** → Reverse herding fix works (distance decreases)
3. **Caveman reaches claim center** → Target is now >300px away
4. **Herding range check fails** → `_try_herd_chance()` never called
5. **Target validation always true** → Caveman never exits state
6. **No timeout mechanism** → Caveman stuck forever
7. **No range extension** → Target can never be herded
8. **Result: 0% herding success, caveman stuck**

---

## Recommended Fixes (Priority Order)

### Priority 1: EXTEND HERDING RANGE AT CLAIM CENTER
```gdscript
# In herd_wildnpc_state.gd update()
var effective_herding_range: float = herding_range
var distance_to_claim_center: float = 999999.0

if land_claim:
    distance_to_claim_center = npc.global_position.distance_to(land_claim.global_position)
    # Extend range when at claim center to catch trailing targets
    if distance_to_claim_center < 50.0:
        effective_herding_range = herding_range * 2.0  # 600px

if woman_distance <= effective_herding_range:
    if target_woman.has_method("_try_herd_chance"):
        target_woman._try_herd_chance(npc)
```

### Priority 2: ADD TIMEOUT WHEN TARGET FAILS TO HERD
```gdscript
# Track time when target doesn't herd at claim center
if land_claim and distance_to_claim_center < 50.0:
    var target_is_herded = target_woman.get("is_herded") if target_woman else false
    var target_herder = target_woman.get("herder") if target_woman else null
    var is_herded_by_us: bool = target_is_herded and target_herder == npc
    
    if not is_herded_by_us:
        if not npc.has_meta("waiting_at_claim_start_time"):
            npc.set_meta("waiting_at_claim_start_time", Time.get_time_dict_from_system()["seconds"])
        else:
            var wait_time: float = Time.get_time_dict_from_system()["seconds"] - npc.get_meta("waiting_at_claim_start_time")
            if wait_time > 3.0:
                # Timeout - target not herded after 3 seconds, invalidate
                return  # Exit state
```

### Priority 3: IMPROVE TARGET VALIDATION
```gdscript
# In _is_valid_target(), add check:
if land_claim:
    var distance_to_claim: float = npc.global_position.distance_to(land_claim.global_position)
    if distance_to_claim < 50.0:
        # At claim center - check if target is actually herded
        var target_is_herded = target.get("is_herded") if target else false
        var target_herder = target.get("herder") if target else null
        if not target_is_herded or target_herder != npc:
            # Check timeout
            if npc.has_meta("waiting_at_claim_start_time"):
                var wait_time: float = Time.get_time_dict_from_system()["seconds"] - npc.get_meta("waiting_at_claim_start_time")
                if wait_time > 3.0:
                    return false  # Invalidate target
```

### Priority 4: ADD COMPREHENSIVE LOGGING
```gdscript
# Log herding attempts
print("🔵 HERD_ATTEMPT: %s trying to herd %s (distance: %.1fpx, effective_range: %.1fpx)" % [
    npc.npc_name, target_woman.get("npc_name") if target_woman else "unknown",
    woman_distance, effective_herding_range
])
```

---

## Expected Results After Fixes

1. **Herding range extended** → Targets within 600px can be herded at claim center
2. **Timeout mechanism** → Caveman exits after 3 seconds if target doesn't herd
3. **Better validation** → Targets invalidated when they fail to herd
4. **More herding attempts** → Caveman can try multiple targets
5. **Higher success rate** → NPCs actually join clan
6. **System recovery** → Caveman doesn't get stuck forever

---

**Report Date:** 2026-01-10  
**Status:** 🔴 **SYSTEM BROKEN - Multiple Critical Issues Identified**
