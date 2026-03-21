# Reverse Herding - Final Analysis

## Problem

After successfully herding Goat 974, PIAG's distance to claim keeps INCREASING:
- 889px → 914px → 954px → ... → 5956px
- This is clear reverse herding - caveman is moving AWAY from claim after herding

## Root Cause Analysis

### Current Code Flow

1. **Herding Attempt (line 355-371)**:
   - `_try_herd_chance()` is called
   - If successful, `is_herded_by_us = true` is set (line 364)
   - But this is LOCAL to the `if woman_distance <= extended_herding_range` block

2. **State Re-evaluation (line 373-376)**:
   - `target_is_herded` and `target_herder` are re-checked
   - `is_herded_by_us` is RECALCULATED: `is_herded_by_us = target_is_herded and target_herder == npc`
   - This OVERWRITES the local assignment from line 364

3. **Leading Logic (line 384-409)**:
   - Checks: `if is_herded_by_us and verify_herded and verify_herder == npc:`
   - Should set target to `land_claim.global_position`
   - Should SKIP intercept logic (ends with line 409)

4. **Intercept Logic (line 410-447)**:
   - Only executes if `is_herded_by_us` is FALSE
   - BUT: If leading logic doesn't execute, this runs!

### The Issue

The leading logic SHOULD work, but something is preventing it. Possible reasons:

1. **Race Condition**: `is_herded_by_us` might be false when checked (line 384), even though herding just succeeded
2. **Verification Failing**: `verify_herded` or `verify_herder` might be failing
3. **Code Not Reaching Leading Logic**: The intercept logic might be executing BEFORE the leading logic check

Wait - looking at the code structure:
- Line 384: `if is_herded_by_us and verify_herded and verify_herder == npc:`
- Line 409: `}` (ends the leading block)
- Line 410: `else:` (intercept logic)

So the leading logic and intercept logic are mutually exclusive. If `is_herded_by_us` is true, leading logic executes. If false, intercept logic executes.

### The Real Problem

After herding succeeds at line 364, the code continues to line 373-376 which RE-SETS `is_herded_by_us`. If the target's state hasn't propagated yet, `target_is_herded` might still be false, causing `is_herded_by_us` to become false again!

Then at line 384, `is_herded_by_us` is false, so leading logic doesn't execute, and intercept logic (line 410) runs instead.

### Solution

**CRITICAL FIX**: After successfully herding (line 364), we need to FORCE the leading logic to execute, or skip the state re-evaluation that might reset `is_herded_by_us`.

Options:
1. **Immediate Return/Early Exit**: After successful herding (line 364), skip to leading logic immediately
2. **Force Leading Logic**: After successful herding, set a flag that forces leading logic
3. **Skip Re-evaluation**: Don't re-evaluate `is_herded_by_us` if we just successfully herded

Best approach: **After successful herding, immediately check if target is herded and if so, force leading logic execution, skipping intercept logic entirely.**

## Final Solution

After line 371 (successful herding), we should:
1. Re-check target state immediately
2. If confirmed herded, FORCE leading logic execution
3. Skip all intercept/approach logic

Actually, simpler: After successful herding, we can just RETURN from the "not yet herded" block, which will cause the next frame to enter the leading logic.

But wait - the code structure doesn't allow returning from there. The leading logic is in the SAME function, not a separate block.

**BEST FIX**: After successful herding (line 364-371), immediately re-check and if confirmed, jump directly to leading logic by using a flag or restructuring the code.

Actually, simplest: **After line 371, add: `continue` or restructure to use early exit pattern.**

But this is `update()`, not a loop, so we can't `continue`.

**FINAL SOLUTION**: After successful herding detection (line 362-371), we need to ensure the leading logic executes. The safest way is to **re-check target state immediately after herding attempt, and if herded, skip the intercept logic entirely by restructuring the code flow.**

Or: **Add a return/early exit after successful herding that forces next frame to use leading logic.**

Actually wait - Godot's state machine runs `update()` every frame. So we can't return early - the next frame will just call `update()` again.

**ACTUAL FINAL SOLUTION**: The leading logic check at line 384 should work, but we need to ensure `is_herded_by_us` is correctly set. The issue is that line 376 might reset it.

**SIMPLEST FIX**: Don't reset `is_herded_by_us` if we just successfully herded in this frame. Add a check: if we just set `is_herded_by_us = true` at line 364, keep it true and skip the recalculation at line 376.

Or: **Remove the recalculation at line 376 - it's redundant and causes the race condition.**

Actually, line 376 is needed because herding might happen outside this function (stealing, etc.). So we can't remove it.

**BEST FIX**: After line 364 (successful herding), don't allow line 376 to overwrite `is_herded_by_us` if it was just set to true. Use a flag: `var just_herded = false` set at line 364, then at line 376: `if not just_herded: is_herded_by_us = ...`

Or simpler: **After successful herding (line 364), immediately re-check target state and if confirmed, skip the recalculation at line 376.**

**FINAL FINAL SOLUTION**: 

After line 371, add:
```gdscript
# If we just successfully herded, confirm target state is updated
if is_herded_by_us:
    target_is_herded = target_woman.get("is_herded") if target_woman else false
    target_herder = target_woman.get("herder") if target_woman else null
    # Re-confirm to ensure state propagated
    is_herded_by_us = target_is_herded and target_herder == npc
```

This ensures the state is confirmed immediately after herding.

But actually, this is what line 373-376 already does! So the issue must be something else.

**WAIT - I see it now!**

Line 373-376 happens AFTER the herding attempt (line 355-371), but BEFORE the leading logic check (line 384). So if herding succeeds at line 364, but by the time we reach line 373, `target_is_herded` is still false (state hasn't propagated), then line 376 sets `is_herded_by_us = false`, and leading logic doesn't execute.

**THE FIX**: After successful herding (line 364), we need to FORCE `is_herded_by_us = true` and NOT allow line 376 to overwrite it. Use a flag to prevent recalculation:

```gdscript
var herding_succeeded_this_frame = false
if now_herded and now_herder == npc:
    is_herded_by_us = true
    herding_succeeded_this_frame = true
    # ... rest of code

# Later at line 373-376:
if not herding_succeeded_this_frame:
    target_is_herded = target_woman.get("is_herded") if target_woman else false
    target_herder = target_woman.get("herder") if target_woman else null
    is_herded_by_us = target_is_herded and target_herder == npc
```

This ensures that if we just successfully herded, we keep `is_herded_by_us = true` and don't let the recalculation overwrite it.
