# Reverse Herding Root Cause Analysis

## Problem Statement
Reverse herding is detected **15 times** immediately after NPCs join the clan. The pattern:
- Caveman at claim center (0-200px)
- **Next frame**: Caveman moves away (900-1400px)
- Safety check detects and corrects it

## Code Flow Analysis

### Frame N: NPC Joins Clan
1. `herd_state.gd` `_check_clan_joining()` executes:
   - Sets `npc.clan_name = claim_clan` (line 214)
   - Sets `npc.is_herded = false` (line 228)
   - Sets `npc.herder = null` (line 229)
   - NPC exits herd state → enters wander/idle state

2. **Same frame** - `herd_wildnpc_state.gd` `update()` executes:
   - Line 130-131: Update herded NPCs list
   - Line 134: `_is_valid_target()` checks if target has `clan_name`
   - Line 135-150: If target has `clan_name`:
     - Clears `target_woman = null`
     - Calls `fsm.change_state("wander")`
     - **RETURNS** (exits update function)

### Frame N+1: Next Update Cycle
**CRITICAL ISSUE**: The leading logic **ran BEFORE** the target validity check!

Looking at the code structure:

```gdscript
func update(delta: float):
    # ... early checks ...
    
    # Line 134: Check target validity
    var target_valid: bool = _is_valid_target(target_woman, clan_name, current_time)
    if not target_valid:
        # Clear target and return - but leading logic already ran!
        return
    
    # Line 288: Move toward target
    if target_woman and ...:
        # Line 396-406: Determine if should_lead
        if herding_succeeded_this_frame or is_herded_by_us:
            should_lead = true
        
        # Line 407-436: Leading logic runs
        if should_lead:
            # SAFETY CHECK runs here (line 418-431)
            # But target was already cleared in previous check!
```

**Wait - that's not right.** If we return at line 150, the leading logic shouldn't run. Let me re-check...

Actually, I see the issue now. The leading logic **does NOT run** if target is invalid because we return early. But the safety check is detecting reverse herding **in the next frame** when the state hasn't changed yet.

## Root Cause Identified

### Issue 1: State Change Delay
When `fsm.change_state("wander")` is called on line 148, the state change **doesn't happen immediately**. The current `update()` completes, and the state change happens at the **start of the next frame**.

So:
- **Frame N**: Target joins clan, `fsm.change_state("wander")` called, `return` exits update
- **Frame N+1**: State is still `herd_wildnpc` (state change pending), `update()` runs again
- **Frame N+1**: `target_woman` is still set (local variable), but NPC has clan_name
- **Frame N+1**: Leading logic runs with invalid target
- **Frame N+1**: Safety check detects reverse herding

### Issue 2: Distance Tracking Meta Not Cleared
The safety check uses meta `"last_distance_to_claim_leading"` to track previous distance. When target joins clan:
- Meta is NOT cleared (only cleared in leading logic, which doesn't run if target invalid)
- Next frame, meta still has old distance (0-200px)
- Caveman moves to search for new target (900-1400px away)
- Safety check compares: old distance (0-200px) vs new distance (900-1400px)
- Detects huge increase → triggers reverse herding warning

### Issue 3: Steering Target Not Cleared
When target joins clan and we return early:
- `steering_agent.set_target_position()` is NOT called to clear/stop movement
- Steering agent continues with previous target from last frame
- Caveman continues moving toward old target position

## Evidence from Logs

```
NPC Sheep 1551 joined clan QI DOHU
🔵 HERD_WILDNPC: PINE target Sheep 1551 joined clan 'QI DOHU' - clearing target immediately
⚠️ REVERSE_HERDING_DETECTED: PINE moving away from claim (0.2px -> 967.3px, +967.1px)
```

Pattern:
1. NPC joins clan
2. Target cleared immediately
3. **Next frame**: Reverse herding detected with huge distance jump (0.2px → 967px)

This confirms the issue: Caveman was at claim center (0.2px), then immediately moves far away (967px) in the next frame.

## Root Causes Summary

1. **State change delay**: `fsm.change_state()` doesn't take effect until next frame
2. **Distance tracking meta not cleared**: Meta persists across frames, causing false positives
3. **Steering target not cleared**: Caveman continues moving with old target
4. **Search logic triggers**: After target cleared, caveman searches for new target outside claim

## Proposed Fixes

### Fix 1: Clear Distance Tracking Meta When Target Joins Clan
When target joins clan, immediately clear the meta:
```gdscript
if target_clan_check != "":
    target_woman = null
    target_lost_time = 0.0
    # Clear distance tracking meta to prevent false positives
    if npc.has_meta("last_distance_to_claim_leading"):
        npc.remove_meta("last_distance_to_claim_leading")
    # ... rest of code
```

### Fix 2: Clear Steering Target When Target Joins Clan
Stop movement immediately when target joins:
```gdscript
if target_clan_check != "":
    # Clear steering target to stop movement
    if npc.steering_agent:
        npc.steering_agent.set_target_position(npc.global_position)  # Stop in place
    # ... rest of code
```

### Fix 3: Don't Run Leading Logic with Invalid Target
Add early return check before leading logic:
```gdscript
# Check target validity BEFORE leading logic
if not target_woman or not is_instance_valid(target_woman):
    return  # Don't run leading logic if no valid target
```

Actually, this is already handled by the early return at line 150. The issue is the state change delay.

### Fix 4: Exclude Search Phase from Safety Check
The safety check should NOT trigger when caveman is searching (no target):
```gdscript
# In leading logic safety check
if should_lead and target_woman:  # Only check if we have a target
    # ... safety check code ...
```

But wait, `should_lead` is only true if `target_woman` exists and is herded, so this should already be covered.

## Most Likely Root Cause

**The safety check is running AFTER the target joins the clan, but the meta still has the old distance stored.**

Looking at the code flow more carefully:

1. **Frame N-1**: Caveman is leading (distance = 0.2px), meta stores this
2. **Frame N**: NPC joins clan
   - `_is_valid_target()` detects NPC has `clan_name`
   - Clears `target_woman = null`
   - Calls `fsm.change_state("wander")`
   - **RETURNS** (exits update function) - Leading logic DOES NOT run
3. **Frame N**: State is still `herd_wildnpc` (state change is delayed)
4. **Frame N+1**: State change to `wander` happens
5. **Frame N+1**: But wait... if state changed to wander, `herd_wildnpc.update()` shouldn't run

**Wait, I think I misunderstood.** Let me check the actual logs again...

Looking at the logs:
```
NPC Sheep 1551 joined clan QI DOHU
🔵 HERD_WILDNPC: PINE target Sheep 1551 joined clan 'QI DOHU' - clearing target immediately
🔄 STATE_ENTRY: PINE entered wander (from herd_wildnpc)
⚠️ REVERSE_HERDING_DETECTED: PINE moving away from claim (0.2px -> 967.3px, +967.1px)
```

So the state change DOES happen immediately (same frame or next frame). But the reverse herding is detected AFTER the state change.

**This means the safety check is running AFTER the state changed, but while the caveman is still in the `herd_wildnpc` state?**

No wait, that doesn't make sense. If state changed to wander, `herd_wildnpc.update()` shouldn't run.

**Actually, I think the issue is different:**

The meta `"last_distance_to_claim_leading"` is NOT cleared when the target joins the clan. So:

1. **Frame N-1**: Leading at 0.2px, meta = 0.2px
2. **Frame N**: NPC joins clan, target cleared, state changes to wander
3. **Frame N+1**: Caveman enters `herd_wildnpc` state again (searches for new target)
4. **Frame N+1**: Caveman moves far from claim (967px) to search
5. **Frame N+2**: Caveman is leading again (new target), leading logic runs
6. **Frame N+2**: Safety check compares: meta (0.2px from old target) vs current (967px)
7. **Frame N+2**: Detects huge increase → triggers false positive

**The meta persists across different herding sessions!**

## Root Cause Confirmed

**The distance tracking meta (`"last_distance_to_claim_leading"`) is NOT cleared when:**
1. Target joins clan
2. Target is cleared
3. State exits
4. New herding session starts

This causes the safety check to compare distances from DIFFERENT herding sessions, triggering false positives.

## Recommended Fix

**Clear distance tracking meta when:**
1. Target joins clan (line 144)
2. State exits (line 72 in `exit()`)
3. Target is cleared for any reason

```gdscript
# In update() when target joins clan (line 144):
if target_clan_check != "":
    target_woman = null
    target_lost_time = 0.0
    # Clear distance tracking meta to prevent false positives in next herding session
    if npc.has_meta("last_distance_to_claim_leading"):
        npc.remove_meta("last_distance_to_claim_leading")
    # ... rest of code

# In exit() (line 72):
func exit() -> void:
    target_woman = null
    herded_npcs.clear()
    target_lost_time = 0.0
    # Clear distance tracking meta when exiting state
    if npc and npc.has_meta("last_distance_to_claim_leading"):
        npc.remove_meta("last_distance_to_claim_leading")
    # ... rest of code
```

This ensures the meta is cleared between herding sessions, preventing false positives.
