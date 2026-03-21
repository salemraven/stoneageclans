# NONO Reverse Herding and Yo-Yo Behavior Analysis
**Generated:** January 11, 2026
**Issue:** NONO is reverse herding and yo-yo'ing at the end of the test

## User Report
- NONO is reverse herding and yo-yo'ing at the END of the test
- NONO is herding (has a sheep)
- Need to look at NONO's movement and the sheep movement
- Identify reverse herding and yo-yo behavior patterns

## What to Look For

### Reverse Herding Pattern
- Caveman follows the sheep (instead of leading)
- Caveman moves toward sheep when sheep moves away
- Caveman's target position is behind the sheep

### Yo-Yo Pattern
- Caveman and sheep alternate moving toward and away from each other
- They oscillate back and forth
- Neither makes progress toward the claim
- Pattern repeats continuously

## Analysis Needed

From the logs, I need to identify:
1. **When NONO is in herd_wildnpc state with a target**
2. **NONO's position changes over time**
3. **Target sheep's position changes over time**
4. **Direction of movement (toward or away from each other)**
5. **Velocity patterns (oscillating speeds)**

## Key Observations from Console (Early Herding Attempt)

Line 774: NONO at (-366.8, -118.3), target=Sheep 1527
Line 813: NONO at (-462.3, -87.1), target=Sheep 1527
Line 851: NONO at (-522.0, 8.7), target=Sheep 1527
Line 863: NONO at (-592.1, 109.1), target=Sheep 1527
Line 865: Sheep 1527 started following NONO
Line 883: ⚠️ FOLLOWER_MOVEMENT_FIXED: Sheep 1527 target was behind herder

**Position Analysis:**
- NONO moving: (-366.8, -118.3) → (-462.3, -87.1) → (-522.0, 8.7) → (-592.1, 109.1)
- NONO is moving AWAY from claim center (increasing distance)
- NONO's distance_to_claim: 19.7 → 88.4 → 194.2 → 315.4

## Questions to Answer

1. **At the end of the test, is NONO actually herding a sheep?**
   - Is NONO in herd_wildnpc state?
   - Does NONO have a target?
   - Is the sheep in herd state (following NONO)?

2. **What are the position patterns?**
   - Is NONO moving toward or away from the sheep?
   - Is the sheep moving toward or away from NONO?
   - Are they oscillating (yo-yo pattern)?

3. **What causes the reverse herding?**
   - Is NONO following the sheep instead of leading?
   - Is NONO's target position behind the sheep?
   - Is the sheep moving away, causing NONO to chase?

4. **What causes the yo-yo behavior?**
   - Are they alternating direction?
   - Is there a feedback loop?
   - Is the "too close" path triggering reverse herding?

## Next Steps

1. **Extract NONO's position sequence** when herding at the end of the test
2. **Extract target sheep's position sequence** when being herded
3. **Calculate distance between NONO and sheep** over time
4. **Identify direction of movement** (toward or away)
5. **Look for oscillation patterns** (yo-yo behavior)
