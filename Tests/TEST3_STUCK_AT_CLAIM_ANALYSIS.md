# Test 3 - Stuck at Land Claim Analysis

## Problem Identified 🔴

**Caveman QABE led Sheep 1664 to land claim but got stuck there because sheep never entered herd state**

### Evidence

**QABE's journey with Sheep 1664:**
```
📍 HERD_WILDNPC: QABE at (1254.7, 687.9), target=Sheep 1664, distance_to_claim=869.3/400.0
📍 HERD_WILDNPC: QABE at (1171.7, 672.5), target=Sheep 1664, distance_to_claim=953.7/400.0
📍 HERD_WILDNPC: QABE at (1267.1, 688.4), target=Sheep 1664, distance_to_claim=857.0/400.0
📍 HERD_WILDNPC: QABE at (1502.7, 728.5), target=Sheep 1664, distance_to_claim=618.0/400.0
📍 HERD_WILDNPC: QABE at (1620.5, 748.5), target=Sheep 1664, distance_to_claim=498.5/400.0
📍 HERD_WILDNPC: QABE at (1742.2, 769.1), target=Sheep 1664, distance_to_claim=375.1/400.0
📍 HERD_WILDNPC: QABE at (1863.8, 789.9), target=Sheep 1664, distance_to_claim=251.7/400.0
📍 HERD_WILDNPC: QABE at (1981.5, 809.9), target=Sheep 1664, distance_to_claim=132.4/400.0
📍 HERD_WILDNPC: QABE at (2099.0, 829.8), target=Sheep 1664, distance_to_claim=13.2/400.0
📍 HERD_WILDNPC: QABE at (2112.9, 832.2), target=Sheep 1664, distance_to_claim=0.9/400.0
📍 HERD_WILDNPC: QABE at (2112.1, 832.0), target=Sheep 1664, distance_to_claim=0.1/400.0, velocity=0.0
[STUCK - many more entries at same position]
```

**Sheep 1664's state:**
- Sheep 1664 was in **wander** state the entire time (never entered herd state)
- Sheep 1664 never "started following" QABE
- Sheep 1664 never joined the clan (because it was never herded)

**Analysis:**
- ✅ **Reverse herding FIXED!** - QABE successfully led sheep to land claim (869px → 0.1px)
- ❌ **NEW BUG:** Sheep never entered herd state even though QABE tracked it to land claim
- ❌ **Stuck behavior:** QABE stayed at land claim center waiting for sheep that never followed

---

## Root Cause

### Problem: Sheep Never Entered Herd State

**Why:**
1. `_try_herd_chance()` is only called when `woman_distance <= herding_range` (300px)
2. When QABE reached land claim (0.1px from center), he might have been far from Sheep 1664
3. If Sheep 1664 was >300px away from QABE at that point, `_try_herd_chance()` was never called
4. Or `_try_herd_chance()` was called but chance rolls failed repeatedly
5. QABE got stuck at claim center, thinking target is still valid

**Code Location:**
```gdscript
# Line 346-349 in herd_wildnpc_state.gd
elif woman_distance <= herding_range:
    # Within range - roll chance to herd (rerolls every frame)
    if target_woman.has_method("_try_herd_chance"):
        target_woman._try_herd_chance(npc)
```

**Issue:**
- If target is >300px away from caveman, herding chance is never rolled
- When caveman reaches land claim center, target might be far behind
- Caveman waits forever for target that never becomes herded

---

## Fix Required

### Solution 1: Increase Herding Range Check or Allow Herding When Near Claim

When caveman is at land claim center (<50px), allow herding even if target is farther away (up to 600px):

```gdscript
# Allow herding when at claim center, even if target is farther
var distance_to_claim_center: float = land_claim.global_position.distance_to(npc.global_position) if land_claim else 999999.0
var effective_herding_range: float = herding_range

# If we're near claim center, extend range to catch up targets
if land_claim and distance_to_claim_center < 50.0:
    effective_herding_range = herding_range * 2.0  # 600px when at claim center

if woman_distance <= effective_herding_range:
    # Within range - roll chance to herd
    if target_woman.has_method("_try_herd_chance"):
        target_woman._try_herd_chance(npc)
```

### Solution 2: Exit State When Target Not Herded After Reaching Claim

If caveman reaches claim center and target is not herded, exit state after timeout:

```gdscript
# In update(), check if we're at claim center and target not herded
if land_claim:
    var distance_to_claim: float = npc.global_position.distance_to(land_claim.global_position)
    var target_is_herded = target_woman.get("is_herded") if target_woman else false
    var target_herder = target_woman.get("herder") if target_woman else null
    var is_herded_by_us: bool = target_is_herded and target_herder == npc
    
    # If at claim center but target not herded by us, wait max 3 seconds then exit
    if distance_to_claim < 50.0 and not is_herded_by_us:
        if not has_meta("waiting_at_claim_start_time"):
            set_meta("waiting_at_claim_start_time", Time.get_time_dict_from_system()["seconds"])
        else:
            var wait_time: float = Time.get_time_dict_from_system()["seconds"] - get_meta("waiting_at_claim_start_time")
            if wait_time > 3.0:
                # Waited 3 seconds, target not herded - exit state
                return  # Will trigger target validation and exit
```

---

## Expected Results After Fix

1. **Targets herded at claim center:** Even if 300-600px away
2. **No stuck behavior:** Caveman exits state if target doesn't herd within 3 seconds
3. **More successful herds:** Targets that are following behind can still be herded
4. **Better efficiency:** Caveman doesn't waste time waiting for unresponsive targets

---

**Analysis Date:** 2026-01-10  
**Status:** Reverse herding fixed, but new issue with targets not herding at claim center
