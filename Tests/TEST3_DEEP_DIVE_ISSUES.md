# Test 3 Deep Dive - Critical Issues Found

## Summary
- **Total herding successes**: 3 (very low - only 2 NPCs joined clan)
- **Reverse herding warnings**: 36 instances
- **Deposit failures**: 27 instances (false positives likely)
- **Caveman extreme distances**: VOOL went up to 1128px away from claim (2.8x claim radius!)
- **State durations**: Many NPCs stuck in states for 5-12+ seconds

---

## 🐛 Critical Bug #1: Caveman Tracking Invalid Targets Far from Claim

### Problem
VOOL tracked **Sheep 980** that was previously herded by the Player. After the Player lost Sheep 980 (at 600.5px break distance), VOOL continued tracking it and went **1128px away from claim center** (almost 3x the 400px radius!).

### Evidence
```
📍 HERD_WILDNPC: VOOL at (388.1, 393.2), target=Sheep 980, distance_to_claim=1128.3/400.0
📍 HERD_WILDNPC: VOOL at (149.6, 612.8), target=Sheep 980, distance_to_claim=805.3/400.0
```

### Root Cause
1. Sheep 980 lost herder Player at exactly 600.5px (break distance threshold)
2. VOOL was already tracking Sheep 980 while it was herded by Player
3. When Player lost Sheep 980, VOOL's target validation didn't immediately recognize it as available
4. Target validation allows tracking targets up to 2000px from claim - this is too far!

### Impact
- Caveman wastes time chasing unreachable targets
- Caveman goes dangerously far from claim (could get lost/stuck)
- Very low herding efficiency

### Fix Required
1. **Reduce max target distance from claim**: Change from 2000px to 800px (2x claim radius)
2. **Invalidate target when it loses herder**: When a target loses its previous herder, immediately make it available for herding
3. **Add safety check**: If caveman goes >1000px from claim, invalidate current target and return to claim

---

## 🐛 Critical Bug #2: Target Validation Not Handling "Lost Herder" Case

### Problem
When Sheep 980 lost the Player as herder, VOOL continued treating it as "herded by someone else" or the target validation didn't properly update.

### Evidence
```
NPC Sheep 980 lost herder Player (outside perception range: 600.5 >= 600.0)
[VOOL continues tracking Sheep 980 for many frames after this]
```

### Root Cause
The `_is_valid_target()` function checks if target is herded, but doesn't handle the case where:
- Target was herded by someone else
- Target's herder is now null (lost herder)
- Target should be immediately available for herding

### Fix Required
In `_is_valid_target()`, add check:
```gdscript
# If target lost its herder (is_herded=false but was herded before), it's now available
if not target_is_herded and target_herder == null:
    # Target is available - valid if within range
    return distance <= active_detection_range
```

---

## 🐛 Critical Bug #3: Reverse Herding Still Occurring

### Problem
VOOL followed Sheep 980 from 154px to 805px away from claim, then back down. Clear reverse herding pattern.

### Evidence
```
📍 HERD_WILDNPC: VOOL at (-233.0, 1185.7), target=Sheep 980, distance_to_claim=154.0/400.0
📍 HERD_WILDNPC: VOOL at (149.6, 612.8), target=Sheep 980, distance_to_claim=805.3/400.0
⚠️ HERD_WILDNPC: VOOL target Sheep 980 rapidly moving away from claim (136.1px/s) - leading to claim instead
```

### Root Cause
1. Target is not herded by us (it's herded by Player or just lost herder)
2. Movement-away check only triggers when caveman is <500px from claim
3. When caveman is >500px from claim, movement-away check doesn't run
4. Caveman follows target further away before the check triggers

### Fix Required
1. **Always check movement direction**: Remove the `<500px` condition for movement-away check
2. **Invalidate immediately**: If target is moving away rapidly (>100px/s) and caveman is already far from claim (>600px), invalidate target immediately

---

## 🐛 Critical Bug #4: Deposit Warning False Positives Persist

### Problem
27 deposit warnings still appearing, even after fix. The check for "all remaining items are food" might not be working correctly.

### Evidence
```
⚠️ AUTO-DEPOSIT: VOOL has 1 items but deposited 0 (remaining: 2 slots) - check if deposit failed
```

### Root Cause
The food check logic might be:
1. Not detecting food correctly
2. Counting items incorrectly
3. The warning is printed before the food check completes

### Fix Required
Review deposit logic more carefully:
1. Add debug logging to see what items remain
2. Verify `ResourceData.is_food()` is working correctly
3. Ensure food check happens before warning is printed

---

## 🐛 Issue #5: NPCs Stuck in States for Long Periods

### Problem
Many NPCs spending 5-12+ seconds in wander/idle states, suggesting they're stuck or not transitioning properly.

### Evidence
```
⏱️ STATE_DURATION: Sheep 877 in wander for 12.8s (LONG - potentially stuck!)
⏱️ STATE_DURATION: VOOL in wander for 10.9s (LONG - potentially stuck!)
⏱️ STATE_DURATION: Woman 5 in wander for 10.4s (LONG - potentially stuck!)
```

### Root Cause
1. Wild NPCs in wander state might be avoiding land claims, causing them to wander in circles
2. No nearby targets for state transitions
3. FSM evaluation might be too slow

### Impact
- NPCs not behaving naturally
- Reduced herding opportunities (NPCs stuck in one place)

---

## 🐛 Issue #6: Very Low Herding Success Rate

### Problem
Only 3 herding successes total, only 2 NPCs joined clan. Very low efficiency.

### Root Causes
1. Caveman tracking invalid targets (Bug #1, #2)
2. Reverse herding wasting time (Bug #3)
3. Targets moving away before herding can succeed
4. Herding range might be too small (150px)

### Fix Required
1. Fix all above bugs first
2. Consider increasing herding range during approach (already 300px, but might need more)
3. Improve target selection to prefer closer, non-moving targets

---

## 🐛 Issue #7: Target Blacklisting Might Be Too Aggressive

### Problem
After timeout, targets are blacklisted for 60 seconds. This might prevent herding valid targets that were just temporarily unreachable.

### Evidence
No direct evidence, but with only 3 successes, blacklisting might be preventing valid attempts.

### Fix Required
1. Reduce blacklist duration from 60s to 30s
2. Clear blacklist when target becomes valid (e.g., loses herder, moves closer)
3. Add logging when targets are blacklisted/unblacklisted

---

## Recommendations Priority

### 🔴 Critical (Fix Immediately)
1. **Fix Bug #1**: Reduce max target distance from claim (2000px → 800px)
2. **Fix Bug #2**: Handle "lost herder" case in target validation
3. **Fix Bug #3**: Always check movement direction (remove <500px condition)

### 🟡 High Priority
4. Fix Bug #4: Deposit warning false positives
5. Fix Issue #6: Improve herding success rate

### 🟢 Medium Priority
6. Fix Issue #5: NPCs stuck in states
7. Review Issue #7: Target blacklisting aggressiveness

---

## Next Steps
1. Implement fixes for Critical bugs
2. Run Test 3 again with enhanced logging
3. Monitor:
   - Maximum distance caveman goes from claim
   - Herding success rate
   - Reverse herding occurrences
   - Target validation accuracy
