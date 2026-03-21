# Why Sheep 2029 Is Not Following - Root Cause Analysis
**Generated:** January 11, 2026
**Issue:** NONO targets Sheep 2029 but the sheep never gets herded

## The Problem

**NONO keeps targeting Sheep 2029, but the sheep never enters herd state and starts following.**

From console data:
- Line 5203: NONO at (1023.2, -1461.8), target=Sheep 2029, distance_to_claim=1938.9/400.0
- Line 5274: **⚠️ HERD_WILDNPC: NONO intercept would take us too far (901.7px) - leading to claim instead**
- Line 5275: MAX_DISTANCE_EXCEEDED: NONO is 2002.4px from claim
- NONO exits state, cycle repeats

## Root Cause

**The "intercept would take us too far" check is preventing NONO from actually attempting to herd the sheep!**

Looking at the code (lines 562-578 in `herd_wildnpc_state.gd`):

```gdscript
# Check if intercept position would keep us within distance limits
var intercept_position: Vector2 = _calculate_intercept_position(target_woman, land_claim, woman_distance)
if land_claim:
    var intercept_distance_to_claim: float = intercept_position.distance_to(land_claim.global_position)
    if intercept_distance_to_claim > 900.0:  # 900px safety margin
        # Intercept would take us too far - lead to claim instead
        npc.steering_agent.set_target_position(land_claim.global_position)
        print("⚠️ HERD_WILDNPC: %s intercept would take us too far (%.1fpx) - leading to claim instead" % [
            npc.npc_name, intercept_distance_to_claim
        ])
    else:
        # Intercept is safe - use it
        npc.steering_agent.set_target_position(intercept_position)
```

**What's happening:**
1. NONO targets Sheep 2029
2. NONO calculates intercept position (where to go to catch the sheep)
3. Intercept position would be >900px from claim
4. **Instead of intercepting, NONO leads to claim instead**
5. NONO moves toward claim (NOT toward the sheep)
6. NONO never gets within 300px herding range of the sheep
7. Herding attempt never happens (`_try_herd_chance` is only called within 300px)
8. Sheep stays in wander state (never herded)
9. NONO hits max distance limit (2000px)
10. NONO exits state
11. Cycle repeats

## Why This Breaks Herding

**The herding logic requires the caveman to be within 300px of the sheep to attempt herding:**

From `herd_wildnpc_state.gd` line 423:
```gdscript
if not is_herded_by_us and woman_distance <= extended_herding_range:  # 300px
    # Within extended range - attempt herding while approaching
    if target_woman.has_method("_try_herd_chance"):
        target_woman._try_herd_chance(npc)
```

And `_try_herd_chance` in `npc_base.gd` line 1014:
```gdscript
var max_range: float = 150.0  # Max herding range (150px - must get close to "capture")
if distance > max_range:
    return false  # Too far away
```

**But when NONO "leads to claim instead":**
- NONO sets target to claim position (NOT intercept position)
- NONO moves toward claim (away from the sheep)
- NONO never gets within 300px of the sheep
- Herding attempt never happens
- Sheep never gets herded

## The Logic Problem

**The safety check (900px limit) is preventing herding attempts!**

The check says: "If intercept would take us too far from claim, don't intercept - lead to claim instead"

But this means:
- NONO never approaches the sheep
- NONO never gets close enough to attempt herding
- The sheep never gets herded
- NONO keeps targeting the same sheep but never herding it

## The Solution

**When the intercept would take us too far, we should STILL attempt to approach the sheep (maybe with a different strategy), not abandon the intercept entirely.**

Options:
1. **Still approach the sheep, but with a different path** (e.g., approach from claim side)
2. **Don't apply the 900px limit if the target is not yet herded** (allow approaching)
3. **Use a larger limit** (e.g., 1500px instead of 900px)
4. **Skip the intercept check for targets that are not yet herded**

The key insight: **We can't herd a sheep if we never approach it!** The safety check is preventing the approach, which prevents herding.
