# Test 3 Post-Fixes Deep Analysis

## Test Results Summary

**Duration:** 180 seconds (3 minutes)  
**Caveman:** DIYO  
**Date:** 2026-01-10

---

## Key Metrics

### Herding Performance
- ✅ **2 herding attempts started** (down from 7 in previous test, but more consistent)
- ✅ **1 NPC successfully joined clan** (Sheep 1754)
- ✅ **0 herds broken** (improved from 1 broken in previous test)
- ⚠️ **AI caveman: 1/2 herdings, Player: 1/2 herdings**

### State Analysis - **FIXES WORKING!** ✅
- **Position logging in herd_wildnpc:** ✅ WORKING - 60+ position logs visible
- **DIYO entered `herd_wildnpc`:** 1 time (at start)
- **DIYO stayed in `herd_wildnpc`:** Entire test duration (never exited)
- **Target found immediately:** Sheep 1754
- **Successful herd:** Sheep 1754 joined clan

---

## Critical Issues Identified

### 🔴 **Issue #1: Caveman Stuck in herd_wildnpc After Target Joins Clan**

**Problem:**
- DIYO successfully herded Sheep 1754 to land claim
- Sheep 1754 joined clan at distance_to_claim ~1.0px
- **DIYO never exited herd_wildnpc state** after sheep joined
- DIYO kept tracking the same sheep (now in clan) for entire test
- Never searched for new targets

**Evidence:**
- 60+ HERD_WILDNPC position logs all show `target=Sheep 1754`
- No STATE_EXIT for DIYO from herd_wildnpc
- DIYO oscillating around land claim edge (distance_to_claim: 200-400px)
- Sheep 1754 already joined clan but DIYO still tracking it

**Root Cause:**
- `_is_valid_target()` in `herd_wildnpc_state.gd` checks if target joined a clan
- But this check might not be running frequently enough, or target isn't being invalidated
- After sheep joins clan, DIYO should exit state and search for new targets

**Impact:**
- DIYO wasted entire test (180s) tracking a sheep that already joined clan
- Only 1 NPC herded instead of potentially 4-6 NPCs

---

### 🟡 **Issue #2: Oscillating Behavior Near Land Claim Edge**

**Problem:**
- After sheep joined, DIYO oscillated around land claim edge
- Distance to claim: 200-400px (back and forth)
- Low velocity movements (6-40px/s) suggesting confusion
- Never moved away to search for new targets

**Evidence:**
```
📍 HERD_WILDNPC: DIYO at (703.5, -538.7), target=Sheep 1754, distance_to_claim=212.8/400.0, velocity=30.3
📍 HERD_WILDNPC: DIYO at (701.7, -535.3), target=Sheep 1754, distance_to_claim=213.0/400.0, velocity=40.9
📍 HERD_WILDNPC: DIYO at (701.8, -535.4), target=Sheep 1754, distance_to_claim=213.0/400.0, velocity=7.6
📍 HERD_WILDNPC: DIYO at (701.4, -534.5), target=Sheep 1754, distance_to_claim=213.0/400.0, velocity=40.8
```

**Root Cause:**
- Target validation (`_is_valid_target()`) might not detect that sheep joined clan
- Or it detects but doesn't clear target properly
- Caveman keeps trying to lead a sheep that's already in clan

---

### 🟡 **Issue #3: No Re-Targeting After Success**

**Problem:**
- After successfully herding one NPC, caveman should:
  1. Exit herd_wildnpc state
  2. Re-enter immediately if more targets available
  3. Search for next wild NPC

- Currently: Stays in state forever tracking the same (now-claimed) NPC

**Impact:**
- Low efficiency: 1 NPC per 180s instead of 4-6 NPCs

---

### 🟡 **Issue #4: Target Invalidation Not Working**

**Problem:**
- `_is_valid_target()` should detect when target joins a clan
- Lines 318-327 in `herd_wildnpc_state.gd` check for target_clan != ""
- But DIYO keeps tracking Sheep 1754 even after it joined clan

**Possible Causes:**
1. Check not running frequently enough
2. Check logic is wrong (target_clan might be empty string initially)
3. Target not being cleared after invalidation
4. Grace period or other logic preventing invalidation

---

## Positive Findings ✅

### 1. Position Logging Works!
- Can now see exactly what caveman is doing in herd_wildnpc state
- 60+ position logs show full movement pattern
- Debugging is now possible

### 2. Extended Timeout Works!
- No premature exits after 5 seconds
- Caveman stayed in state for full duration (10s timeout not reached because target was found)

### 3. Target Detection Works!
- DIYO found Sheep 1754 immediately
- Successfully approached and herded it
- Sheep joined clan successfully

### 4. Movement Logic Works!
- DIYO moved from 925px to 1px from land claim
- Successfully led sheep to clan

---

## Detailed Analysis

### DIYO's Journey

1. **Entry:** Entered herd_wildnpc from gather
2. **Target Found:** Immediately found Sheep 1754
3. **Approach:** Moved from distance_to_claim=925.8px → 1.0px (successful)
4. **Success:** Sheep 1754 joined clan at distance ~1px
5. **Stuck:** Continued tracking Sheep 1754 (now in clan) for remainder of test
6. **Oscillation:** Moved back and forth at land claim edge (200-400px)
7. **No Exit:** Never exited state, never searched for new targets

### Position Distribution

Based on 60+ position logs:
- **Near land claim (<300px):** Most positions
- **At edge (300-400px):** Many positions (oscillating)
- **Far (>400px):** Few positions (only during initial approach)

This confirms DIYO is stuck oscillating near the edge after sheep joined.

---

## Recommendations

### Priority 1: Fix Target Invalidation After Clan Join 🔴 CRITICAL

**Problem:** Caveman doesn't detect when target joins clan

**Fix:** 
1. In `_is_valid_target()`, check if target's `clan_name` is set
2. If target joined clan, immediately invalidate and clear target
3. Force state re-evaluation

**Implementation:**
```gdscript
# In _is_valid_target() - already has this check but might not be working
var target_clan: String = target.get("clan_name") if target else ""
if target_clan != "":
    # NPC joined a clan - invalidate immediately
    target_woman = null  # Clear target
    return false
```

**Also add in `update()`:**
```gdscript
# After checking target validity, if invalid and target joined clan, exit state immediately
if not target_valid and target_woman:
    var target_clan_check = target_woman.get("clan_name") if target_woman else ""
    if target_clan_check != "":
        # Target joined clan - exit immediately to search for new targets
        if fsm:
            fsm.change_state("wander")
            # Force immediate re-evaluation
            fsm.evaluation_timer = 0.0
        return
```

### Priority 2: Force Target Clear on Clan Join 🟡 HIGH

**Problem:** Target isn't cleared when it becomes invalid

**Fix:**
- When `_is_valid_target()` returns false and reason is "joined_clan", clear target immediately
- Don't wait for grace period

### Priority 3: Add Immediate Re-Entry After Success 🟡 MEDIUM

**Problem:** After exiting herd_wildnpc (target joined), caveman goes to wander but might not re-enter quickly

**Fix:**
- When exiting because target joined clan, force immediate FSM re-evaluation
- Ensure `can_enter()` is checked right away

---

## Code Changes Needed

### herd_wildnpc_state.gd

1. **In `update()` method:**
   - After `_is_valid_target()` check, if target joined clan, exit immediately
   - Clear target and force state change

2. **In `_is_valid_target()` method:**
   - Ensure clan check works correctly
   - Log when target joins clan

3. **In `exit()` method:**
   - Already has force re-evaluation (good!)

---

## Expected Improvements

After fixes:
1. **Target invalidation:** Works immediately when target joins clan
2. **State exit:** Caveman exits herd_wildnpc when target joins
3. **Re-targeting:** Caveman immediately searches for new targets
4. **Efficiency:** 1 NPC per 180s → 4-6 NPCs per 180s (4-6x improvement)

---

## Comparison: Before vs After Fixes

| Metric | Before Fixes | After Fixes | Status |
|--------|--------------|-------------|--------|
| Position logging | ❌ None | ✅ 60+ logs | **FIXED** |
| State visibility | ❌ Unknown | ✅ Fully visible | **FIXED** |
| Timeout (5s→10s) | ❌ 5s | ✅ 10s (works) | **FIXED** |
| FSM interval | ❌ 0.5s | ✅ 0.1s | **FIXED** |
| Target invalidation | ❌ Not working | ❌ Still broken | **NEEDS FIX** |
| Re-targeting | ❌ Never happens | ❌ Still broken | **NEEDS FIX** |

---

**Analysis Date:** 2026-01-10  
**Test Log:** `/Users/macbook/Desktop/stoneageclans/Tests/test3_herding_system.log`

**Next Steps:** Fix target invalidation and re-targeting logic.
