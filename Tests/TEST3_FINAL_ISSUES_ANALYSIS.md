# Test 3 Final Issues Analysis

## Test Results Summary

**Duration:** 180 seconds (3 minutes)  
**Caveman:** FURI  
**Date:** 2026-01-10  
**Status:** 🟢 **MAJOR SUCCESS - But Issues Remain**

---

## 🎉 Major Successes

### ✅ 6 NPCs Joined Clan!
- **Sheep 1461** - Herded and joined clan "ZU HELA"
- **Goat 1363** - Herded and joined clan "ZU HELA"  
- **Woman 3** - Herded and joined clan "ZU HELA"
- Plus 3 more (Player herded NPCs)

### ✅ System Functioning
- **26 herd_wildnpc entries** - Caveman very active
- **3 herding attempts started** - All by AI caveman FURI
- **No reverse herding detected** - Fixes working!
- **Target clearing working** - NPCs that join clan trigger immediate target clearing

---

## 🔴 Critical Issues Found

### Issue #1: Repeated Timeouts on Same Target (Sheep 1362)

**Problem:**
- FURI repeatedly targets **Sheep 1362**
- Timeout after 3 seconds, target invalidated
- Immediately re-targets same Sheep 1362
- Repeats 8+ times in sequence

**Evidence:**
```
⚠️ HERD_WILDNPC: FURI timeout waiting for Sheep 1362 to herd (waited 3.0s, distance: 576.8px)
⚠️ TARGET_VALIDATION: FURI invalidating target Sheep 1362 (not herded after 3.0s at claim center)
[FURI exits herd_wildnpc, re-enters immediately]
⚠️ HERD_WILDNPC: FURI timeout waiting for Sheep 1362 to herd (waited 3.0s, distance: 566.0px)
[Repeats 8 times]
```

**Root Cause:**
- Target validation doesn't blacklist failed targets
- After timeout, caveman immediately finds same target again
- Target is still >500px away, can't herd within 3s
- Infinite loop of timeout → re-target → timeout

**Impact:** **HIGH**
- Caveman wastes time on un-herdable targets
- Reduces efficiency significantly
- Prevents finding better targets

---

### Issue #2: Targets Too Far at Claim Center

**Problem:**
- When FURI reaches claim center, targets are 525-890px away
- Herding only works within 300px range
- Timeout triggers before targets can get close enough

**Evidence:**
```
⚠️ HERD_WILDNPC: FURI timeout waiting for Sheep 1362 to herd (waited 3.0s, distance: 576.8px)
⚠️ HERD_WILDNPC: FURI timeout waiting for Woman 5 to herd (waited 3.0s, distance: 986.2px)
⚠️ HERD_WILDNPC: FURI timeout waiting for Sheep 1362 to herd (waited 3.0s, distance: 525.5px)
```

**Root Cause:**
- Caveman reaches claim center before target is within 300px
- Target is following behind but too far (500-900px)
- 3-second timeout not enough for target to catch up
- Caveman should herd target BEFORE reaching claim center

**Impact:** **HIGH**
- Most targets timeout and fail
- Only targets already close succeed
- Reduces herding success rate significantly

---

### Issue #3: Woman 3 Oscillating at Claim Edge

**Problem:**
- Woman 3 repeatedly moves in/out of claim boundary
- Position oscillates: 206px → 237px → 250px → 285px → 302px → 111px → 179px
- Stuck in loop near claim edge

**Evidence:**
```
📍 POSITION: Woman 3 at (-73.8, 512.9), state=wander, distance_to_claim=237.1/400.0
📍 POSITION: Woman 3 at (-29.8, 504.4), state=wander, distance_to_claim=206.9/400.0
📍 POSITION: Woman 3 at (-137.4, 469.3), state=wander, distance_to_claim=250.8/400.0
[Oscillating between 200-350px]
```

**Root Cause:**
- Wild NPCs avoid land claims in wander state
- Woman 3 keeps approaching claim edge, then backing away
- No clear decision to either enter claim or move far away
- Stuck in boundary zone

**Impact:** **MEDIUM**
- NPCs not effectively moving toward or away from claim
- Could affect herding success

---

### Issue #4: Multiple NPCs Stuck (velocity=0.0)

**Problem:**
- Many NPCs showing velocity=0.0 repeatedly
- Sheep 1161, Sheep 1763, Goat 1062, Sheep 1362 all stuck
- Same position logged multiple times

**Evidence:**
```
📍 POSITION: Sheep 1161 at (-196.3, 600.4), state=wander, distance_to_claim=0.0/400.0, velocity=0.0
📍 POSITION: Sheep 1362 at (-568.3, 1037.7), state=wander, distance_to_claim=0.0/400.0, velocity=0.0
[Repeated many times]
```

**Root Cause:**
- Intentional anti-oscillation code (from npc_base.gd)
- NPCs pause when velocity is very small
- But they're staying paused too long
- Should resume movement after pause

**Impact:** **LOW-MEDIUM**
- NPCs appear frozen
- Reduces visual realism
- Might affect herding if targets are too static

---

### Issue #5: Consistent 3.8s Exit Duration

**Problem:**
- FURI exits herd_wildnpc after exactly 3.8s repeatedly
- Pattern: exit → wander (0.1s) → re-enter → exit (3.8s)
- Suggests timeout is consistently triggering

**Evidence:**
```
⏱️ STATE_EXIT: FURI exited herd_wildnpc after 3.8s
🔄 STATE_ENTRY: FURI entered wander (from herd_wildnpc)
🔄 STATE_ENTRY: FURI entered herd_wildnpc (from wander)
⏱️ STATE_EXIT: FURI exited herd_wildnpc after 3.8s
[Repeats 10+ times]
```

**Root Cause:**
- Timeout set to 3.0 seconds
- Takes ~0.8s for state transition and re-evaluation
- Total cycle: ~3.8s
- Most targets failing the 3-second timeout

**Impact:** **MEDIUM**
- Predictable but inefficient pattern
- Suggests timeout might be too short
- Or targets consistently too far away

---

## 📊 Performance Metrics

| Metric | Value | Status |
|--------|-------|--------|
| NPCs joined clan | 6 | ✅ Excellent |
| Herding attempts | 3 | 🟡 Low |
| herd_wildnpc entries | 26 | ✅ Good |
| Reverse herding | 0 | ✅ Fixed |
| Target clearing | Working | ✅ Good |
| Timeouts | 43 | 🔴 High |
| Success rate | ~7% (3/45 attempts) | 🔴 Low |

---

## 🎯 Priority Issues

### Priority 1: Target Blacklisting (CRITICAL)
- Implement temporary blacklist for failed targets
- Prevent infinite re-targeting loops
- Increase timeout or adjust logic

### Priority 2: Herding Before Claim Center
- Caveman should herd targets while approaching claim
- Don't wait until claim center to start herding
- Herd at 300px range while moving toward claim

### Priority 3: Timeout Duration/Logic
- Consider extending timeout for distant targets
- Or invalidate targets earlier if too far
- Better logic for when timeout should trigger

---

**Analysis Date:** 2026-01-10  
**Status:** System working but needs optimization
