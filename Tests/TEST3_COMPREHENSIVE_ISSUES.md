# Test 3 Comprehensive Issues Analysis

## Test Results

**Duration:** 180 seconds  
**Caveman:** FURI  
**Status:** 🟢 **SUCCESS - 6 NPCs Joined Clan!**

---

## ✅ Major Successes

1. **6 NPCs joined clan** - Excellent performance!
   - Sheep 1461, Goat 1363, Woman 3 (by FURI)
   - Plus 3 more by Player
2. **26 herd_wildnpc entries** - Caveman very active
3. **No reverse herding** - Fixes working perfectly
4. **Target clearing working** - NPCs that join trigger immediate clearing

---

## 🔴 Critical Issues

### Issue #1: Intercept Validation Too Strict Near Claim Edge

**Problem:**
- 31 intercept rejections when caveman is 195-200px from claim center
- Intercept would move to 400px (claim edge/boundary)
- This is rejected as "moving away"
- But targets might be at claim edge (just outside 400px boundary)

**Evidence:**
```
⚠️ HERD_WILDNPC: FURI intercept would move away (196.9px → 399.0px) - leading to claim instead
⚠️ HERD_WILDNPC: FURI intercept would move away (196.3px → 399.1px) - leading to claim instead
[31 total rejections]
```

**Root Cause:**
- Check: `if intercept_to_claim > npc_to_claim + 0.0` rejects ANY movement away
- When caveman at 195px, moving to 400px is "away" from center
- But 400px is claim boundary - targets might be just outside
- Caveman should be able to approach claim edge to reach targets

**Impact:** **HIGH**
- Prevents caveman from reaching targets at claim boundary
- Forces caveman to stay at claim center waiting
- Reduces herding success rate

**Fix Needed:**
- Allow movement to claim edge (up to claim radius + buffer)
- Only reject if intercept is significantly beyond claim boundary

---

### Issue #2: No Target Blacklisting

**Problem:**
- Same target (Sheep 1362) repeatedly targeted and timed out
- 8+ consecutive failures on same target
- No memory of failed attempts
- Caveman wastes time on un-herdable targets

**Evidence:**
```
⚠️ HERD_WILDNPC: FURI timeout waiting for Sheep 1362 to herd (waited 3.0s, distance: 576.8px)
[FURI exits, re-enters immediately]
⚠️ HERD_WILDNPC: FURI timeout waiting for Sheep 1362 to herd (waited 3.0s, distance: 566.0px)
[Repeats 8 times]
```

**Root Cause:**
- `_find_woman_to_herd()` doesn't check if target was recently failed
- No blacklist mechanism
- Target selection only checks distance and validity

**Impact:** **HIGH**
- Wastes time on repeatedly failing targets
- Reduces efficiency
- Prevents finding better targets

**Fix Needed:**
- Add temporary blacklist (30-60 seconds)
- Store failed targets with timestamp
- Skip blacklisted targets in `_find_woman_to_herd()`

---

### Issue #3: Targets Too Far When Reaching Claim Center

**Problem:**
- Caveman reaches claim center (0.2px)
- Target is 1000+ pixels away
- Timeout triggers after 3 seconds
- Target never gets within 300px herding range

**Evidence:**
```
📍 HERD_WILDNPC: FURI at (64.2, 320.0), target=Woman 5, distance_to_claim=0.2/400.0
⚠️ HERD_WILDNPC: FURI timeout waiting for Woman 5 to herd (waited 3.0s, distance: 1030.4px)
```

**Root Cause:**
- Caveman leads to claim center too quickly
- Target is following behind but too far
- Caveman should herd target BEFORE reaching claim center
- Or wait longer at claim center for target to catch up

**Impact:** **MEDIUM**
- Most targets fail timeout
- Only targets already close succeed
- Reduces overall success rate

**Fix Needed:**
- Herd targets while approaching claim (when within 300-600px range)
- Or extend timeout when target is far but moving toward claim
- Or slow down approach to let target catch up

---

### Issue #4: Intercept Calculation Issue Near Claim Edge

**Problem:**
- When caveman is inside claim (195px), intercept calculates position at claim edge (400px)
- This is correct (target is likely at edge or just outside)
- But validation rejects it as "moving away from claim center"
- Creates conflict between intercept logic and validation logic

**Root Cause:**
- Intercept correctly tries to approach target at claim edge
- But validation only cares about distance to claim CENTER
- No consideration for claim BOUNDARY

**Fix Needed:**
- Allow movement to claim radius + small buffer (e.g., 500px)
- Consider claim boundary, not just center
- Only reject if intercept is far beyond claim boundary

---

### Issue #5: Multiple NPCs Stuck (velocity=0.0)

**Problem:**
- Many NPCs showing velocity=0.0 repeatedly
- Same position logged multiple times
- Sheep 1161, Sheep 1763, Goat 1062, Sheep 1362 all stuck

**Impact:** **LOW-MEDIUM**
- Visual issue (NPCs appear frozen)
- Might affect herding if targets are too static

---

## 📊 Performance Metrics

| Metric | Value | Target | Status |
|--------|-------|--------|--------|
| NPCs joined | 6 | 5+ | ✅ Excellent |
| Herding attempts | 3 | 10+ | 🟡 Low |
| Success rate | ~7% (3/45) | 30%+ | 🔴 Low |
| Timeouts | 43 | <10 | 🔴 High |
| Reverse herding | 0 | 0 | ✅ Fixed |

---

## 🎯 Priority Fixes

### Priority 1: Fix Intercept Validation Near Claim Edge
- Allow movement to claim boundary (400px) + buffer (100px)
- Total: allow up to 500px from claim center
- Only reject if intercept > 500px when caveman < 400px

### Priority 2: Implement Target Blacklisting
- Add failed_targets dictionary with timestamps
- Blacklist targets for 30-60 seconds after timeout
- Check blacklist in `_find_woman_to_herd()`

### Priority 3: Improve Herding Timing
- Herd targets while approaching claim (600-300px range)
- Don't wait until claim center
- Or extend timeout when target is far but approaching

---

**Analysis Date:** 2026-01-10  
**Status:** System working but needs optimization
