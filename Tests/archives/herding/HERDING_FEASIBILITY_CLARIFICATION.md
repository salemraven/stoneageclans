# Herding Feasibility - Clarification

## Why "Herding Feasibility" Was Wrong

You're absolutely right to question this. Let me explain why "Herding Feasibility" was a **red herring**.

---

## The Facts

### 1. Wild NPCs WILL Follow
When herded, wild NPCs:
- Follow at 50-300px distance
- Catch up directly if >300px away (`herd_state.gd` line 132-134)
- Only break herd if >600px away
- Move at the same base speed as cavemen (320px/s)

### 2. Caveman DOES Slow Down
The caveman already has slow-down logic:
```gdscript
# Line 353-356 in herd_wildnpc_state.gd
elif woman_distance > max_distance:  # >300px
    # Too far - slow down so follower can catch up
    npc.steering_agent.speed_multiplier = speed_multiplier * 0.7
```

So if the follower is >300px behind, the caveman slows to 70% speed.

### 3. Distance Doesn't Matter
If a target is 2000px from the claim:
- ✅ Can be herded (within 300px range)
- ✅ Will follow (follow distance 50-300px, catch up if >300px)
- ✅ Caveman will slow down (0.7x speed when follower >300px)
- ✅ Will reach claim (both moving toward it)

**So ANY target can theoretically be herded and brought back, regardless of distance from claim.**

---

## The REAL Problem

The issue isn't "feasibility" - it's that **herding never happens in the first place**.

### Current Flow (BROKEN):
```
1. Caveman detects target 1500px from claim
2. Caveman approaches and leads to claim
3. While leading, target is >300px behind
4. Herding only attempted when ≤300px (line 379)
5. Target never gets within 300px, so herding never happens
6. Caveman reaches claim center, target still 1000px away
7. Timeout triggers
```

### Why Herding Never Happens:
```gdscript
# Line 379: Herding only happens here
elif woman_distance <= herding_range:  # ≤300px
    target_woman._try_herd_chance(npc)

# Line 475: When target is >300px, caveman approaches/intercepts
# BUT NO HERDING ATTEMPT HAPPENS HERE
else:
    # Approach/intercept logic
    # Herding never attempted!
```

---

## The Correct Fix

**Not "feasibility"** - just **"herd during approach"**:

```gdscript
# When approaching target (>300px), STILL try to herd if within extended range (600px)
if woman_distance <= 600.0:  # Extended range
    if target_woman.has_method("_try_herd_chance"):
        target_woman._try_herd_chance(npc)  # Try to herd during approach
```

This way:
1. Caveman approaches target
2. **Herding attempted while approaching** (when within 600px)
3. If herding succeeds, target follows
4. Caveman slows down if follower >300px (already implemented)
5. Both reach claim together

---

## Why "Feasibility" Was Wrong

I incorrectly assumed that:
- ❌ Targets >1000px from claim are "too far" to herd
- ❌ We should filter them out before selection
- ❌ They're "not feasible" to bring back

**But the reality is:**
- ✅ Any target CAN be herded (if within 300px)
- ✅ Any target WILL follow (if herded)
- ✅ Distance doesn't matter (caveman slows down, both move to claim)
- ✅ The only issue is: **herding isn't happening because attempts only occur at ≤300px**

---

## Corrected Root Cause

**NOT:** "Targets are too far from claim to be feasible"
**BUT:** "Herding attempts only happen at ≤300px, but caveman leads to claim while target is >300px away, so herding never happens"

---

## Summary

You're 100% correct:
- Wild NPCs **will** follow the caveman back to the land claim
- The caveman **does** slow down to match NPC speed while herding
- Distance from claim **doesn't matter** - any target can be herded and brought back
- The only issue is: **herding attempts need to happen during approach, not just when close**

**The fix:** Extend herding range to 600px and attempt herding while approaching, not just when within 300px.

---

**Analysis Date:** 2026-01-10  
**Status:** Concept corrected - "Feasibility" was a red herring, real issue is herding range limitation
