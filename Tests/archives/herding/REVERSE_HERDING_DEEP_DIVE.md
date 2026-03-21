# Reverse Herding Deep Dive Analysis

## Summary
All 3 reverse herding detections occur **immediately after successfully herding** an NPC, when the caveman is already far from the claim.

## Pattern Analysis

### All 3 Cases Follow Same Pattern:

**Case 1:**
```
✅ HERD_SUCCESS: TOAX successfully herded Woman 1 (distance: 66.9px)
⚠️ REVERSE_HERDING_DETECTED: TOAX moving away from claim (2652.9px -> 2812.4px, +159.6px)
```

**Case 2:**
```
✅ HERD_SUCCESS: TOAX successfully herded Woman 1 (distance: 28.5px)
⚠️ REVERSE_HERDING_DETECTED: TOAX moving away from claim (2815.5px -> 3035.5px, +220.0px)
```

**Case 3:**
```
✅ HERD_SUCCESS: TOAX successfully herded Woman 1 (distance: 28.6px)
⚠️ REVERSE_HERDING_DETECTED: TOAX moving away from claim (3829.5px -> 3947.7px, +118.1px)
```

## Critical Observation

**All reverse herding happens when:**
1. Caveman is already **far from claim** (2652px, 2815px, 3829px)
2. Caveman successfully herds NPC (steals from Player)
3. **Next frame**: Caveman moves AWAY from claim (+159px, +220px, +118px)
4. Safety check detects and corrects it

## Root Cause: Frame Timing Issue

The issue is a **1-frame delay** between:
1. Successfully herding (`herding_succeeded_this_frame = true`)
2. Leading logic executing (`should_lead = true`)
3. Steering agent actually updating movement

### Current Code Flow:

```gdscript
# Frame N: Herding attempt succeeds
if not is_herded_by_us and woman_distance <= extended_herding_range:
    target_woman._try_herd_chance(npc)
    if now_herded and now_herder == npc:
        is_herded_by_us = true
        herding_succeeded_this_frame = true
        npc.set_meta("herding_succeeded_this_frame", true)  # Persist across frames
        
# Frame N: Leading logic should run
if herding_succeeded_this_frame:
    should_lead = true
    
if should_lead:
    if land_claim:
        npc.steering_agent.set_target_position(claim_position)  # Set target to claim
        # But steering agent might have already calculated next frame's movement!
```

### The Problem:

1. **Frame N**: Herding succeeds, `herding_succeeded_this_frame = true`
2. **Frame N**: Leading logic runs, sets `steering_agent.target_position = claim_position`
3. **Frame N**: BUT steering agent's `_physics_process()` or movement update might run AFTER this
4. **Frame N+1**: Steering agent uses the OLD target (toward NPC) from Frame N-1 for movement
5. **Frame N+1**: Caveman moves AWAY from claim (reverse herding)
6. **Frame N+1**: Leading logic runs again, corrects it

**OR:**

1. **Frame N**: Herding succeeds, movement already calculated toward NPC
2. **Frame N**: Leading logic sets new target to claim
3. **Frame N+1**: Movement applies from Frame N (toward NPC), THEN new target takes effect
4. **Frame N+1**: Caveman moves AWAY from claim for 1 frame

## Why This Happens Far From Claim

The caveman is already **far from claim** (2652-3829px) when herding succeeds because:
- Target is far from claim (being chased by Player)
- Caveman steals the target from Player
- Caveman needs to immediately reverse direction toward claim
- But momentum/velocity from previous frame causes 1-frame movement away

## Solutions

### Solution 1: Clear Steering Agent State When Herding Succeeds

**Immediately clear steering agent's target/velocity when herding succeeds:**

```gdscript
if now_herded and now_herder == npc:
    # Successfully herded! Update flag
    is_herded_by_us = true
    herding_succeeded_this_frame = true
    npc.set_meta("herding_succeeded_this_frame", true)
    
    # IMMEDIATELY set target to claim (don't wait for leading logic)
    var land_claim = _get_land_claim(clan_name)
    if land_claim and npc.steering_agent:
        npc.steering_agent.set_target_position(land_claim.global_position)
        # Clear any velocity/momentum to prevent 1-frame delay
        if npc.has_method("velocity"):
            npc.velocity = Vector2.ZERO  # Stop momentum
```

**Pros:**
- Immediate correction, no frame delay
- Prevents momentum carryover

**Cons:**
- Might cause sudden direction change (but that's what we want!)
- Need to check if `velocity` is accessible

### Solution 2: Check Steering Agent Update Order

**Ensure steering agent target is set BEFORE movement calculation:**

The issue might be that `steering_agent.set_target_position()` is called, but the steering agent's internal movement calculation happens in `_physics_process()` which might run AFTER our `update()`.

**Check if we need to call steering agent update explicitly:**

```gdscript
if should_lead:
    if land_claim:
        npc.steering_agent.set_target_position(claim_position)
        # Force steering agent to update immediately if possible
        if npc.steering_agent.has_method("update"):
            npc.steering_agent.update(get_physics_process_delta_time())
```

**Pros:**
- Ensures target is set before movement
- Doesn't rely on frame timing

**Cons:**
- Might cause double updates
- Need to check steering agent API

### Solution 3: Store Last Movement Direction

**Track if caveman was moving away from claim and immediately correct:**

```gdscript
# At start of leading logic
if should_lead and land_claim:
    var claim_position: Vector2 = land_claim.global_position
    var current_distance: float = npc.global_position.distance_to(claim_position)
    
    # Check if we just successfully herded (frame transition)
    if herding_succeeded_this_frame:
        # Check if moving away from claim
        var direction_to_claim = (claim_position - npc.global_position).normalized()
        var current_velocity = npc.velocity if "velocity" in npc else Vector2.ZERO
        
        if current_velocity.dot(direction_to_claim) < 0:  # Moving away
            # Immediately stop and redirect
            npc.velocity = Vector2.ZERO
            npc.steering_agent.set_target_position(claim_position)
```

**Pros:**
- Handles the specific case (herding success → reverse movement)
- Works with steering agent system

**Cons:**
- Requires velocity access
- Might need to handle differently for different movement systems

### Solution 4: Two-Stage Target Setting (Current + Next Frame)

**Set target IMMEDIATELY when herding succeeds, then again in leading logic:**

```gdscript
# When herding succeeds
if now_herded and now_herder == npc:
    is_herded_by_us = true
    herding_succeeded_this_frame = true
    npc.set_meta("herding_succeeded_this_frame", true)
    
    # IMMEDIATELY redirect to claim (don't wait for next frame)
    var land_claim = _get_land_claim(clan_name)
    if land_claim and npc.steering_agent:
        npc.steering_agent.set_target_position(land_claim.global_position)

# Later in leading logic (redundant but ensures it's set)
if should_lead:
    if land_claim:
        npc.steering_agent.set_target_position(claim_position)  # Ensure it's set
```

**Pros:**
- Simple, immediate fix
- Works with existing code structure
- No need to access velocity

**Cons:**
- Redundant (but harmless)

## Recommended Solution

**Combine Solution 1 + Solution 4**: Immediately redirect to claim when herding succeeds, then ensure it's set again in leading logic.

This ensures:
1. Target is set immediately when herding succeeds (no frame delay)
2. Leading logic continues to work normally
3. No reliance on velocity or steering agent internals

## Implementation

The fix should be in the herding success block (around line 365-375):

```gdscript
if now_herded and now_herder == npc:
    # Successfully herded! Update flag and continue to leading logic
    is_herded_by_us = true
    herding_succeeded_this_frame = true
    just_herded_now = true
    # Persist across frames - clear on next frame after leading logic executes
    npc.set_meta("herding_succeeded_this_frame", true)
    
    # IMMEDIATELY redirect to claim (prevent 1-frame delay)
    var land_claim_for_redirect = _get_land_claim(clan_name)
    if land_claim_for_redirect and npc.steering_agent:
        npc.steering_agent.set_target_position(land_claim_for_redirect.global_position)
        print("🔀 HERD_WILDNPC: %s immediately redirected to claim after herding %s" % [
            npc.npc_name, target_woman.get("npc_name") if target_woman else "unknown"
        ])
    
    print("✅ HERD_SUCCESS: %s successfully herded %s while approaching (distance: %.1fpx)" % [
        npc.npc_name, target_woman.get("npc_name") if target_woman else "unknown", woman_distance
    ])
```

This should prevent the 1-frame reverse herding movement.
