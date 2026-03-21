# "Too Close" Path Analysis - Is This The Main Issue?
**Generated:** January 11, 2026
**User Question:** Is "Too Close" path the main issue causing yo-yo behavior?

## Current "Too Close" Behavior

**Location:** `scripts/npc/states/herd_state.gd` lines 125-132
**Trigger:** `distance_to_herder < distance_min` (follower < 50px from herder)

```gdscript
if distance_to_herder < distance_min:
    # Too close (<50px) - back up to ideal distance
    var direction: Vector2 = (npc.global_position - herder_pos).normalized()
    if direction == Vector2.ZERO:
        var angle: float = randf() * TAU
        direction = Vector2(cos(angle), sin(angle))
    target = herder_pos + direction * target_distance
```

**What Happens:**
1. Follower is < 50px from herder (too close)
2. Direction calculated: `(npc.global_position - herder_pos)` = direction AWAY from herder
3. Target placed: `herder_pos + direction * target_distance` = target BEHIND herder (away from herder)
4. Follower moves AWAY from herder (backing up)

## The Yo-Yo Cycle (Hypothesis)

**If this is the main issue, here's the cycle:**

1. **Follower gets close** (< 50px) → triggers "too close" path
2. **Follower backs up** → moves away from herder (to ideal distance ~100px)
3. **Caveman sees follower moving away** → may follow (reverse herding)
4. **Caveman catches up** → follower is close again (< 50px)
5. **Follower backs up again** → cycle repeats

**Result:** Yo-yo behavior - follower backs up, caveman follows, follower backs up, repeat

## Why This Could Be The Main Issue

### 1. Direct Cause-Effect Cycle
- **Follower moves away** → **Caveman follows** → **Follower moves away** → repeat
- This is a direct feedback loop
- No complex math errors needed - just simple behavior triggering each other

### 2. Happens Frequently
- Follower wants to maintain ideal distance (50-150px)
- But follower speed (1.25x) might be faster than caveman speed (1.25x when leading)
- If speeds are equal, follower may overshoot and get too close
- Then backs up → triggers reverse herding

### 3. Matches User Observation
- User sees "yo-yo" behavior
- Follower alternates between moving toward and away from herder
- "Too close" path is the ONLY path that intentionally moves follower AWAY from herder
- This matches the pattern

### 4. Simple Fix
- If follower never moves away, reverse herding can't occur
- Don't back up when too close - just slow down or stop
- Or back up very slowly (won't trigger reverse herding)

## Comparison to Other Issues

### "Good Distance" Path Math Error
- **Issue:** Target calculation might place target behind herder
- **But:** Has validation that should catch it (threshold 0.5 = 60°)
- **Likelihood:** Medium - validation should prevent it

### "Continue Last Target" Path
- **Issue:** Uses old target without validation
- **But:** Only uses old target for 0.3s (target update interval)
- **Likelihood:** Low - short duration, should be caught quickly

### "Too Close" Path
- **Issue:** Intentionally moves follower AWAY from herder
- **But:** This is by design (backing up when too close)
- **Likelihood:** HIGH - happens every time follower gets too close
- **Impact:** Direct cause of reverse herding cycle

## Conclusion

**YES - "Too Close" path is likely the MAIN issue because:**

1. ✅ **Direct feedback loop:** Follower backs up → Caveman follows → Follower backs up
2. ✅ **Happens frequently:** Every time follower gets < 50px from herder
3. ✅ **Matches pattern:** User sees yo-yo (alternating toward/away)
4. ✅ **Simple cause:** Only path that intentionally moves follower away
5. ✅ **Easy to test:** Disable backing up, see if yo-yo stops

**The "Good Distance" path math error is probably secondary:**
- Validation should catch most cases
- Even if it doesn't, it's less frequent than "too close" path

## Recommended Fix

**Option 1: Don't Back Up - Just Slow Down**
- When too close, don't move away
- Just reduce speed or stop
- Let herder move forward (follower stays close but doesn't back up)

**Option 2: Back Up Very Slowly**
- When too close, back up VERY slowly (0.25x speed)
- Won't trigger reverse herding (slow movement)
- Still allows some backing up for spacing

**Option 3: Don't Back Up If Herder Is Moving Forward**
- Check if herder is moving toward claim
- If herder is moving, don't back up (let herder move forward)
- Only back up if herder is stationary

**Option 4: Increase "Too Close" Threshold**
- Increase `distance_min` from 50px to 75px or 100px
- Reduces frequency of backing up
- Follower stays closer (less need to back up)

## Recommendation

**Try Option 1 first (Don't Back Up - Just Slow Down):**
- Simplest fix
- Prevents reverse herding completely (follower never moves away)
- Still allows spacing (follower just slows down when too close)

**If that doesn't work, try Option 2 (Back Up Very Slowly):**
- Allows some backing up (better spacing)
- Slow movement won't trigger reverse herding
