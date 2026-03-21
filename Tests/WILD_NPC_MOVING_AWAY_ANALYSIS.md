# Wild NPC Moving Away From Leader - Deep Dive Analysis
**Generated:** January 11, 2026
**Issue:** Why is the wild NPC moving away from the leader when it should be following?

## The Real Problem

**If the caveman is leading toward the claim:**
- Distance from claim should DECREASE
- But if max distance is being exceeded, distance is INCREASING
- This means something is wrong with the movement

**The user's question:** Why is the wild NPC moving away from the leader?

## Analysis of Follower Movement Code

Looking at `herd_state.gd`, there are 3 movement paths:

### 1. Too Close (<50px) - Backs Up (MOVES AWAY)
**Lines 126-135:**
```gdscript
if distance_to_herder < distance_min:
    # Too close (<50px) - back up to ideal distance VERY SLOWLY
    var direction: Vector2 = (npc.global_position - herder_pos).normalized()
    target = herder_pos + direction * target_distance
    backing_up = true
    speed_multiplier = 0.15  # Very slow (15% of normal)
```

**This makes the follower move AWAY from the herder!**
- Direction: `(follower_pos - herder_pos)` = AWAY from herder
- Target: `herder_pos + direction * target_distance` = Position AWAY from herder
- **This is intentional (spacing), but causes the follower to move AWAY**

### 2. Too Far (>300px) - Moves Toward
**Lines 136-140:**
```gdscript
elif distance_to_herder > distance_max:
    target = herder_pos  # Move directly to herder
    speed_multiplier = 1.25
```

**This makes the follower move TOWARD the herder.**

### 3. Good Distance (50-300px) - Maintains Distance
**Lines 141-172:**
```gdscript
else:
    # Good distance - maintain ideal distance
    var direction_to_herder: Vector2 = (herder_pos - npc.global_position).normalized()
    var drift_direction: Vector2 = direction_to_herder.rotated(drift_angle)
    target = herder_pos - drift_direction * target_distance
```

**This should make the follower move TOWARD the herder (maintaining distance).**

## The Problem: "Too Close" Path Moves Away

**The "too close" path (lines 126-135) makes the follower move AWAY from the herder!**

This is intentional for spacing, but it means:
- If follower is too close (<50px), it backs up (moves AWAY)
- Even at slow speed (0.15x), this is still movement AWAY from the herder
- If the caveman is leading toward the claim, and the follower backs up, the follower moves AWAY from both the herder AND the claim

## Questions to Answer

1. **When does the follower get "too close" (<50px)?**
   - Is this happening frequently?
   - Is this causing the follower to move away from the claim?

2. **What happens when the follower backs up?**
   - The follower moves AWAY from the herder
   - If the herder is leading toward the claim, the follower moves AWAY from the claim
   - Does this cause the distance from claim to increase?

3. **Is the "too close" path the cause of the problem?**
   - The follower backs up (moves away)
   - Even at slow speed, this is still movement away
   - Could this be causing the distance from claim to increase?

4. **What if the follower keeps getting "too close" repeatedly?**
   - Follower backs up → moves away
   - Herder continues leading → follower catches up
   - Follower gets too close again → backs up again
   - This creates a cycle where the follower keeps backing up

## The Real Root Cause (Hypothesis)

**Hypothesis: The "too close" path is causing the follower to move away from the claim**

**Scenario:**
1. Caveman leads toward claim (distance from claim decreases)
2. Follower follows (moves toward caveman/claim)
3. Follower gets too close (<50px) to caveman
4. Follower backs up (moves AWAY from caveman)
5. But caveman is still leading toward claim
6. Follower's backing up causes it to move AWAY from claim
7. Distance from claim INCREASES (because follower moved away)
8. Caveman's distance to claim also increases (because follower moved away, caveman might wait or follow)

**OR:**
1. Caveman leads toward claim
2. Follower follows
3. Follower gets too close repeatedly
4. Follower keeps backing up (moving away)
5. This creates a yo-yo pattern:
   - Follower follows → gets too close → backs up (moves away)
   - Follower catches up → gets too close again → backs up again
6. This oscillation prevents progress toward claim
7. Caveman's distance from claim increases because progress is slow/oscillating

## Next Steps

1. **Check if the "too close" path is being triggered frequently**
   - Look for patterns where follower distance is <50px
   - Check if this coincides with distance from claim increasing

2. **Check if backing up is causing the problem**
   - When follower backs up, does distance from claim increase?
   - Is the backing up preventing progress toward claim?

3. **Consider alternative approaches for "too close" path**
   - Instead of backing up, maybe just stop moving?
   - Or reduce speed but don't change direction?
   - Or use a smaller backing up distance?

4. **Check if there's a feedback loop**
   - Does the "too close" path create a cycle?
   - Follower backs up → catches up → backs up again?
