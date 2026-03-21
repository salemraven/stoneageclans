# Test 3 Deep Dive Analysis - Reverse Herding & Teleportation

## Summary

At the end of the test, **Sheep 1111** was experiencing reverse herding (caveman following the sheep) and then teleported when the herder distance became 4954.7px (massive, suggesting teleportation).

## Critical Issues Found

### 1. **Reverse Herding Issue**

**Problem:** The caveman in `herd_wildnpc` state is following the sheep instead of leading it.

**Location:** `scripts/npc/states/herd_wildnpc_state.gd` lines 170-180

**Root Cause:**
- When the caveman is trying to herd (not yet herded), the code approaches the sheep's **current position** (lines 172-174, 178-180)
- When the sheep moves away (naturally in wander mode), the caveman follows it to the new position
- This creates a chase where both move in the same direction, increasing distance

**Evidence from logs:**
```
NPC Sheep 1111 switched from NPC to Player (stolen, chance: 10.0%, distance: 273.2)
NPC Sheep 1111 switched from Player to NPC (stolen, chance: 32.5%, distance: 27.3)
NPC Sheep 1111 lost herder NPC (outside perception range: 4954.7 >= 600.0)
```

The rapid back-and-forth stealing suggests the caveman and sheep were moving together, causing distance to increase.

**Code Issue:**
```gdscript
# Lines 172-174: Still trying to herd
var direction_to_woman: Vector2 = (target_woman.global_position - npc.global_position).normalized()
var approach_position: Vector2 = target_woman.global_position - direction_to_woman * 50.0
npc.steering_agent.set_target_position(approach_position)
```

The caveman approaches the sheep's **current** position. If the sheep moves, the caveman follows.

### 2. **Teleportation Issue**

**Problem:** Sheep 1111's herder became 4954.7px away, indicating a teleport or massive position jump.

**Possible Causes:**

#### A. World Boundary Clamping (Line 807 in npc_base.gd)
```gdscript
# scripts/npc/npc_base.gd:807
global_position = clamped_pos
```

If the herder (NPC/caveman) went past the world boundary (2000px from spawn), it would be clamped back to the boundary, causing a sudden position change.

#### B. Invalid Herder Reference
The 4954.7px distance suggests the herder reference might be pointing to:
- A deleted/invalid NPC (but `is_instance_valid()` check should catch this)
- An NPC that was teleported elsewhere
- A position calculation error

#### C. Distance Calculation Error
The distance is calculated from `npc.herder.global_position` - if the herder's position is invalid or wrong, this would produce a huge distance.

**Evidence:**
- Last known position of Sheep 1111 before teleport: around (760-787, 152-195)
- Distance to herder: 4954.7px (should be < 600px)
- After losing herder, Sheep 1111 disappears from position logs (may have been teleported or despawned)

### 3. **Why Reverse Herding Happens**

The logic flow:
1. Caveman enters `herd_wildnpc` state
2. Finds wild NPC (sheep) within detection range
3. Approaches sheep's **current position**
4. Sheep is wandering and moves away
5. Caveman updates target to sheep's **new position**
6. This creates a chase loop where caveman follows sheep

**The fix should be:** 
- When approaching (not yet herded), predict the sheep's movement OR
- Move to intercept the sheep, not directly toward it OR  
- Move ahead of the sheep in the direction it's going

### 4. **Why Teleportation Happened**

Most likely cause: **World boundary clamping** on the herder (NPC/caveman).

Sequence:
1. Caveman follows sheep (reverse herding)
2. They both move away from spawn
3. Caveman reaches world boundary (2000px from spawn)
4. `_apply_world_boundary()` clamps caveman position back (line 807)
5. Caveman position suddenly changes by ~3000-4000px
6. Sheep calculates distance to herder: 4954.7px
7. Herd breaks due to distance > 600px

**Alternative theory:** The caveman's position reference became invalid, causing distance calculation to use wrong coordinates.

## Fixes Applied

### Fix 1: Prevent Reverse Herding ✅
**File:** `scripts/npc/states/herd_wildnpc_state.gd`

**Change:** When approaching a wild NPC (not yet herded), the caveman now approaches from the **land claim direction** instead of chasing the sheep's current position.

**Logic:**
- Calculate approach direction as a mix of: direction to sheep + direction to land claim
- This biases movement toward the land claim, preventing the caveman from chasing if the sheep moves away
- When the sheep moves, the caveman maintains position relative to land claim, not sheep

**Result:** Caveman will lead sheep toward land claim instead of following it.

### Fix 2: Fix Teleportation ✅
**File:** `scripts/npc/npc_base.gd`

**Changes:**
1. **Cavemen are NOT restricted by world boundary** (line 783-786) - they can travel far to herd
2. **Wild NPCs being herded are NOT restricted** (line 255-262) - they can travel with their herder
3. **Smooth movement instead of instant teleport** (line 802-815) - uses steering agent or lerp instead of direct position assignment

**Result:** No more sudden teleportations when NPCs reach boundaries.

### Fix 3: Teleportation Detection ✅
**File:** `scripts/npc/states/herd_state.gd`

**Change:** Added validation for huge distances (>5000px) that detects teleportation/position errors and breaks the herd gracefully.

**Result:** Invalid herd relationships break cleanly instead of causing weird behavior.

## Root Causes Identified

### Reverse Herding Root Cause:
The caveman was approaching the sheep's **current position** every frame. When the sheep moved (wander mode), the caveman updated its target to the sheep's **new position**, creating a chase loop.

### Teleportation Root Cause:
1. World boundary clamping (line 807) was using instant position assignment: `global_position = clamped_pos`
2. When the herder (NPC/caveman) reached 2000px from spawn, it was instantly teleported back
3. This caused the distance to jump from ~600px to 4954.7px
4. The herd broke due to distance > 600px

## Next Steps

1. ✅ Fix reverse herding logic - APPROACH FROM LAND CLAIM DIRECTION
2. ✅ Fix teleportation - REMOVE BOUNDARY RESTRICTIONS FOR CAVEMEN AND HERDED NPCs
3. ✅ Add teleportation detection - BREAK HERD ON HUGE DISTANCES
4. ⏳ Run test again to verify fixes work
