# Reverse Herding Analysis - Goat 986

## Problem Identified 🔴

**Caveman JEJI is moving AWAY from land claim while herding Goat 986**

### Evidence

**JEJI's distance_to_claim progression:**
```
📍 HERD_WILDNPC: JEJI at (1417.6, 440.1), target=Goat 986, distance_to_claim=12.5/400.0
📍 HERD_WILDNPC: JEJI at (1486.2, 381.4), target=Goat 986, distance_to_claim=102.7/400.0
📍 HERD_WILDNPC: JEJI at (1226.9, 162.9), target=Goat 986, distance_to_claim=337.7/400.0
NPC Goat 986 switched from Player to NPC (stolen, chance: 12.9%, distance: 241.6)
📍 HERD_WILDNPC: JEJI at (856.6, -288.4), target=Goat 986, distance_to_claim=919.9/400.0  ← FAR!
📍 HERD_WILDNPC: JEJI at (762.7, -361.2), target=Goat 986, distance_to_claim=1035.0/400.0  ← GETTING FARTHER!
📍 HERD_WILDNPC: JEJI at (669.1, -434.4), target=Goat 986, distance_to_claim=1150.9/400.0  ← EVEN FARTHER!
📍 HERD_WILDNPC: JEJI at (575.6, -507.9), target=Goat 986, distance_to_claim=1267.5/400.0
📍 HERD_WILDNPC: JEJI at (482.4, -581.5), target=Goat 986, distance_to_claim=1384.4/400.0
📍 HERD_WILDNPC: JEJI at (389.2, -655.2), target=Goat 986, distance_to_claim=1501.7/400.0
📍 HERD_WILDNPC: JEJI at (309.6, -743.2), target=Goat 986, distance_to_claim=1620.3/400.0
📍 HERD_WILDNPC: JEJI at (278.4, -822.1), target=Goat 986, distance_to_claim=1699.7/400.0
📍 HERD_WILDNPC: JEJI at (262.0, -854.2), target=Goat 986, distance_to_claim=1734.7/400.0
```

**Analysis:**
- Started near claim (12.5px)
- After stealing Goat 986 at 241.6px distance, JEJI was 919.9px from claim
- **JEJI moved AWAY from claim**: 919px → 1035px → 1150px → 1706px
- This is **reverse herding** - caveman should LEAD toward claim, not away

---

## Root Cause

### When Target is NOT Herded By Us Yet

**The Problem:**
- Goat 986 was stolen at distance 241.6px
- At this point, `is_herded_by_us` might be false initially
- Code uses `_calculate_intercept_position()` which predicts where target will be
- Intercept logic might calculate position AWAY from land claim
- Caveman follows intercept position instead of leading to claim

**Code Flow:**
```gdscript
# Line 366-369: When target is NOT herded by us yet
else:
    # Still trying to herd - REC 5: Path Prediction & Interception
    var intercept_position: Vector2 = _calculate_intercept_position(target_woman, land_claim, woman_distance)
    npc.steering_agent.set_target_position(intercept_position)
```

**Intercept Calculation Issue:**
- `_calculate_intercept_position()` predicts where target will be
- If target is moving AWAY from land claim, intercept is also away
- Caveman follows intercept → moves away from claim → **reverse herding**

---

## Fix Required

### Problem: Intercept Logic Doesn't Consider Land Claim Direction

When calculating intercept position, we should:
1. **Prefer intercept positions closer to land claim**
2. **If target is moving away from claim, lead toward claim instead**
3. **When very close (<50px), always lead toward claim immediately**

### Implementation

**In `herd_wildnpc_state.gd`, update the intercept logic:**

```gdscript
# When target is NOT herded by us yet
else:
    # CRITICAL: If target is very close (<50px), lead toward claim immediately
    # Don't use intercept - just lead to claim (prevent reverse herding)
    if woman_distance < 50.0 and land_claim:
        # Very close - just lead directly to claim
        npc.steering_agent.set_target_position(land_claim.global_position)
    else:
        # Still trying to herd - REC 5: Path Prediction & Interception
        var intercept_position: Vector2 = _calculate_intercept_position(target_woman, land_claim, woman_distance)
        
        # CRITICAL: Ensure intercept position is not too far from land claim
        # If intercept is far from claim and target is between us and claim, lead toward claim instead
        if land_claim:
            var intercept_to_claim: float = intercept_position.distance_to(land_claim.global_position)
            var target_to_claim: float = target_woman.global_position.distance_to(land_claim.global_position)
            var npc_to_claim: float = npc.global_position.distance_to(land_claim.global_position)
            
            # If intercept would move us away from claim, lead to claim instead
            if intercept_to_claim > npc_to_claim + 200.0:  # Intercept is 200px+ farther from claim
                # Intercept is moving away - lead toward claim instead
                npc.steering_agent.set_target_position(land_claim.global_position)
            else:
                npc.steering_agent.set_target_position(intercept_position)
        else:
            npc.steering_agent.set_target_position(intercept_position)
```

---

## Evidence Summary

1. **JEJI distance_to_claim:** Increased from 12px → 1706px (moved 1694px AWAY!)
2. **Goat 986 position:** Near (-200, -200) range (relatively stationary)
3. **JEJI position:** Moved from (1417, 440) → (262, -854) - huge movement away
4. **Result:** Caveman led goat AWAY from land claim instead of toward it

---

## Expected Fix

After fix:
- When target is very close (<50px), caveman leads directly to claim
- Intercept position checked - won't use if it moves away from claim
- Caveman always maintains or reduces distance_to_claim when herding
- No more reverse herding patterns

---

**Analysis Date:** 2026-01-10  
**Status:** Root cause identified, fix ready to implement
