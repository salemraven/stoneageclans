# Reverse Herding Core Fix Deep Dive

## The Fundamental Problem

Reverse herding happens because of a **fundamental timing mismatch** between:
1. **When herding succeeds** (NPC becomes herded)
2. **When the caveman's movement target is updated** (to lead to claim)
3. **When the steering agent actually applies movement** (physics update)

## The Root Cause: Frame Timing & Movement Momentum

### Current Flow (PROBLEMATIC):

```
Frame N-1:
- Caveman moving toward NPC (away from claim)
- Steering agent target = NPC position
- Movement calculated: toward NPC
- Velocity/momentum: toward NPC

Frame N:
- Herding succeeds (_try_herd_chance succeeds)
- is_herded_by_us = true
- herding_succeeded_this_frame = true
- Leading logic runs: steering_agent.set_target_position(claim_position)
- BUT: Movement from Frame N-1 is still being applied!
- Caveman moves AWAY from claim (using old velocity/momentum)

Frame N+1:
- Leading logic runs again
- Steering agent target = claim_position (set correctly)
- Movement calculated: toward claim
- Caveman moves TOWARD claim (finally correct)
```

### Why This Happens:

The steering agent system works on **physics ticks**, not on frame boundaries. When we call `set_target_position()`, it doesn't immediately change the movement direction - it changes the **target** for the **next** physics update.

**The caveman has momentum/velocity** from the previous frame's movement (toward the NPC), and that momentum continues to move the caveman **away from the claim** for one frame, even though we've set the target to the claim.

## Evidence from Logs

All 3 reverse herding cases showed:
1. Herding succeeds at distance X from claim (2652px, 2815px, 3829px)
2. **Next frame**: Distance increases (+159px, +220px, +118px)
3. Safety check detects and corrects it

This confirms: The caveman is using old velocity/momentum from the previous frame's movement toward the NPC, before the new target takes effect.

## The Core Problem: Movement System Architecture

### Current Architecture:
```
State.update() runs
  → Sets steering_agent.target_position
  → Returns
  → Steering agent calculates movement (physics update)
  → Movement applied
  → Position updated
```

**Problem**: The steering agent calculates movement **AFTER** state.update() returns, using the **current velocity/momentum** from the previous frame.

### What We Need:
The steering agent should **immediately** update direction when target changes, not wait for next physics update.

## Core Fixes (Ordered by Fundamental Impact)

### Fix 1: Clear Velocity/Momentum When Herding Succeeds (CORE FIX)

**The most fundamental fix**: When herding succeeds, **immediately clear the caveman's velocity/momentum** so the steering agent starts fresh.

```gdscript
if now_herded and now_herder == npc:
    # Successfully herded! Update flag
    is_herded_by_us = true
    herding_succeeded_this_frame = true
    
    # CORE FIX: Clear velocity/momentum to prevent reverse herding
    # This ensures the steering agent starts fresh, not using old momentum
    if npc.has_method("velocity"):
        npc.velocity = Vector2.ZERO  # Stop all momentum
    elif "velocity" in npc:
        npc.set("velocity", Vector2.ZERO)
    
    # THEN redirect to claim
    var land_claim_for_redirect = _get_land_claim(clan_name)
    if land_claim_for_redirect and npc.steering_agent:
        npc.steering_agent.set_target_position(land_claim_for_redirect.global_position)
```

**Why this works**: By clearing velocity, we prevent the steering agent from using old momentum from movement toward the NPC. The steering agent will calculate new movement from scratch toward the claim.

**Fundamental Impact**: HIGH - Addresses root cause directly

### Fix 2: Force Immediate Steering Agent Update (If Possible)

**If steering agent supports it**: Force an immediate update when target changes.

```gdscript
if land_claim_for_redirect and npc.steering_agent:
    npc.steering_agent.set_target_position(land_claim_for_redirect.global_position)
    
    # If steering agent supports immediate update, force it
    if npc.steering_agent.has_method("update") or npc.steering_agent.has_method("force_update"):
        var delta = get_physics_process_delta_time()
        if delta > 0:
            npc.steering_agent.update(delta)  # Force immediate recalculation
```

**Why this works**: Forces the steering agent to recalculate movement immediately, not waiting for next physics update.

**Fundamental Impact**: MEDIUM - Works if steering agent supports it

### Fix 3: Set Target Before Movement Calculation (Architecture Fix)

**If we control the update order**: Ensure target is set BEFORE movement calculation.

**Current order** (problematic):
```
1. State.update() → set_target_position()
2. Physics update → calculate movement (uses old velocity)
3. Apply movement
```

**Ideal order**:
```
1. State.update() → set_target_position() + clear velocity
2. Physics update → calculate movement (starts fresh)
3. Apply movement
```

**Fundamental Impact**: HIGH - But requires architecture changes

### Fix 4: Pre-emptive Target Setting (Current Fix - WORKING)

**What we currently do**: Set target immediately when herding succeeds, before leading logic runs.

```gdscript
if now_herded and now_herder == npc:
    # Set target immediately (before leading logic runs)
    var land_claim_for_redirect = _get_land_claim(clan_name)
    if land_claim_for_redirect and npc.steering_agent:
        npc.steering_agent.set_target_position(land_claim_for_redirect.global_position)
    
    # Leading logic runs later and sets it again (redundant but ensures correctness)
```

**Why this works**: Gives steering agent maximum time to update before next frame.

**Fundamental Impact**: MEDIUM - Works around the issue, doesn't fix root cause

## Recommended Core Fix

**Combine Fix 1 + Fix 4**: Clear velocity AND set target immediately.

This addresses both:
1. **Root cause**: Clears momentum that causes reverse movement
2. **Timing**: Sets target early so steering agent has time to update

## Implementation

```gdscript
if now_herded and now_herder == npc:
    # Successfully herded! Update flag
    is_herded_by_us = true
    herding_succeeded_this_frame = true
    just_herded_now = true
    npc.set_meta("herding_succeeded_this_frame", true)
    
    # CORE FIX #1: Clear velocity/momentum to prevent reverse herding
    # This stops the caveman from using old momentum from movement toward NPC
    if npc.has_method("velocity"):
        npc.velocity = Vector2.ZERO  # Stop all momentum immediately
    elif "velocity" in npc:
        npc.set("velocity", Vector2.ZERO)
    # If neither works, try accessing through CharacterBody2D
    elif npc is CharacterBody2D:
        var body: CharacterBody2D = npc as CharacterBody2D
        body.velocity = Vector2.ZERO
    
    # CORE FIX #2: Set target immediately (before leading logic runs)
    var land_claim_for_redirect = _get_land_claim(clan_name)
    if land_claim_for_redirect and npc.steering_agent:
        npc.steering_agent.set_target_position(land_claim_for_redirect.global_position)
        print("🔀 HERD_WILDNPC: %s immediately redirected to claim after herding %s (cleared momentum, preventing reverse herding)" % [
            npc.npc_name, target_woman.get("npc_name") if target_woman else "unknown"
        ])
    
    print("✅ HERD_SUCCESS: %s successfully herded %s while approaching (distance: %.1fpx)" % [
        npc.npc_name, target_woman.get("npc_name") if target_woman else "unknown", woman_distance
    ])
```

This **core fix** addresses the fundamental issue: **momentum carryover** from movement toward the NPC.

## Why This Is The Core Fix

The root cause is **velocity carryover** in the steering agent's `_seek()` calculation:

**The Problem:**
```gdscript
# In steering_agent.gd _seek() (line 308):
var steer: Vector2 = desired - npc.velocity
```

When herding succeeds:
1. `desired` = direction toward claim (correct)
2. `npc.velocity` = old velocity toward NPC (wrong - away from claim)
3. `steer = desired - npc.velocity` = wrong direction (still toward NPC)
4. Result: Caveman moves away from claim for 1 frame (reverse herding)

**The Solution:**
By clearing `npc.velocity`:
1. `npc.velocity = Vector2.ZERO` (cleared)
2. `steer = desired - Vector2.ZERO` = correct direction (toward claim)
3. Result: Caveman moves toward claim immediately (no reverse herding)

This is the **fundamental fix** that addresses the core issue: **velocity carryover in steering calculation**.

## Implementation Status

✅ **CORE FIX IMPLEMENTED** in `herd_wildnpc_state.gd`:
- Clears `npc.velocity` when herding succeeds
- Sets target to claim immediately
- Prevents velocity carryover from causing reverse herding

This fix addresses the root cause at the steering agent level.
