# Test 3 Deep Dive Analysis & Recommendations

## Executive Summary

Test 3 ran successfully for 180 seconds. Analysis reveals **low herding success rate** (3 successful herds out of 44 `herd_wildnpc` entries) and **systematic timeout issues** (targets consistently 1000+px away when timeout triggers).

---

## Key Metrics

| Metric | Value | Analysis |
|--------|-------|----------|
| **Total `herd_wildnpc` entries** | 44 | Caveman actively trying to herd |
| **Successful herds** | 3 | Goat 929 (147px), Sheep 1029 (139px), Sheep 927 (128px) |
| **Clan joins** | 6 | 3 herded NPCs joined + 3 others? |
| **Timeouts** | 40 | Targets 1000-1346px away when timeout triggers |
| **Success rate** | ~6.8% | Very low - only 3/44 entries successful |
| **Average timeout distance** | ~1093px | Targets too far when timeout triggers |
| **Intercept rejections** | 8,783 | 🚨 CRITICAL: Intercept validation blocking movement |
| **Caveman avg target distance** | ~990px | Very far from targets |
| **Caveman positions inside claim** | 327/335 (97.6%) | Caveman mostly inside claim |

---

## Critical Issues Identified

### 🔴 Issue #1: Timeout Distance Problem

**Problem:**
- Caveman reaches claim center (<50px from claim)
- Target is still **1000-1250px away** when timeout triggers (3 seconds)
- Targets never get within 150px herding range before timeout

**Evidence:**
```
⚠️ HERD_WILDNPC: TIPO timeout waiting for Sheep 1529 to herd (waited 3.0s, distance: 1035.4px)
⚠️ HERD_WILDNPC: TIPO timeout waiting for Woman 5 to herd (waited 3.0s, distance: 1080.1px)
⚠️ HERD_WILDNPC: TIPO timeout waiting for Sheep 1630 to herd (waited 3.0s, distance: 1044.6px)
```

**Root Cause:**
- Extended herding range (300px) attempts herding during approach
- But targets are still **1000+px away** when caveman reaches claim center
- Herding never succeeds because target never gets within 150px capture range
- 3-second timeout is too short for targets 1000px away

**Impact:**
- **~13 timeouts** during test
- Targets blacklisted for 60 seconds
- Caveman wastes time on impossible targets

---

### 🔴 Issue #2: Low Herding Success Rate

**Problem:**
- Only **3 successful herds** out of **44 `herd_wildnpc` entries**
- Success rate: **~6.8%**
- Most entries result in timeout or target invalidation

**Evidence:**
```
✅ HERD_SUCCESS: YEEY successfully herded Goat 929 while approaching (distance: 147.0px)
✅ HERD_SUCCESS: YEEY successfully herded Sheep 1029 while approaching (distance: 139.7px)
✅ HERD_SUCCESS: YEEY successfully herded Sheep 927 while approaching (distance: 128.7px)
```

**Observations:**
- All 3 successes happened when target was **128-147px away** (within capture range)
- Successful herds were during approach phase (extended range working)
- But most attempts never get close enough (1000+px away)

**Root Cause:**
- Targets spawn far from land claim
- Caveman approaches but target is still 1000+px away when timeout triggers
- Only targets that are already close (within 150px) get successfully herded

**Impact:**
- Very low herding efficiency
- Most targets never get herded
- Caveman wastes time on distant targets

---

### 🟡 Issue #3: Regular 3.8s State Cycles

**Problem:**
- Caveman enters `herd_wildnpc` → exits after ~3.8s → enters `wander` → immediately re-enters `herd_wildnpc`
- Pattern repeats consistently (~3.8s cycles)

**Evidence:**
```
⏱️ STATE_EXIT: TIPO exited herd_wildnpc after 3.8s
🔄 STATE_ENTRY: TIPO entered wander (from herd_wildnpc)
🔄 STATE_ENTRY: TIPO entered herd_wildnpc (from wander)
⏱️ STATE_EXIT: TIPO exited herd_wildnpc after 3.8s
🔄 STATE_ENTRY: TIPO entered wander (from herd_wildnpc)
🔄 STATE_ENTRY: TIPO entered herd_wildnpc (from wander)
```

**Root Cause:**
- 3-second timeout at claim center triggers state exit
- Target blacklisted for 60s
- Caveman finds new target immediately
- New target also times out after 3.8s

**Impact:**
- Caveman stuck in timeout cycle
- Wastes time on impossible targets
- Doesn't effectively search for closer targets

---

### 🔴 Issue #4: Intercept Validation Blocking Movement (CRITICAL)

**Problem:**
- **8,783 intercept validation rejections** during test
- Intercept validation rejects movement beyond **500px** (claim boundary + 100px buffer)
- But targets are often **1000+px away** from claim
- This prevents caveman from reaching distant targets

**Evidence:**
```
⚠️ HERD_WILDNPC: TIPO intercept would go beyond claim boundary (534.5px > 500.0px) - leading to claim instead
⚠️ HERD_WILDNPC: TIPO intercept would go beyond claim boundary (534.4px > 500.0px) - leading to claim instead
(8,783 total rejections)
```

**Root Cause:**
- Intercept validation uses claim boundary (400px) + buffer (100px) = 500px max
- But targets spawn 1000-2000px from claim
- Caveman tries to intercept target beyond 500px → validation rejects → caveman leads to claim instead
- Caveman can't reach targets beyond 500px from claim

**Impact:**
- **CRITICAL**: Caveman physically cannot reach targets beyond 500px
- Targets 1000+px away are impossible to reach
- All timeouts are for targets >1000px away
- This is the PRIMARY cause of low success rate

**Fix Required:**
- Remove or relax intercept validation for targets beyond claim boundary
- Allow movement beyond 500px when approaching distant targets
- Only apply validation when target is relatively close (<800px from claim)

---

## Recommendations to Improve Herding Rates

### 🔧 Priority 1: Increase Timeout Duration (CRITICAL)

**Problem:** 3-second timeout is too short for targets 1000px away

**Solution:** 
- Increase timeout from 3s to **8-10 seconds** for targets >500px away
- Dynamic timeout based on target distance:
  - Target <500px: 3s timeout (current)
  - Target 500-1000px: 6s timeout
  - Target >1000px: 10s timeout

**Expected Impact:**
- Targets have more time to approach within 150px range
- Reduce timeout cycles
- Increase success rate from ~7% to ~20-30%

**Implementation:**
```gdscript
# In herd_wildnpc_state.gd, update timeout logic
var timeout_duration: float = 3.0
if woman_distance > 1000.0:
    timeout_duration = 10.0  # Give more time for distant targets
elif woman_distance > 500.0:
    timeout_duration = 6.0
```

---

### 🔧 Priority 3: Improve Target Selection (MEDIUM)

**Problem:** Caveman selects targets that are too far (1000+px), leading to timeouts

**Solution:**
- Prioritize targets that are **closer** (within 800px from claim)
- Reduce priority for targets >1200px from claim
- Add "feasibility score" to target selection:
  - Distance from claim: closer = higher score
  - Distance from caveman: closer = higher score
  - Already moving toward claim: bonus score

**Expected Impact:**
- More successful herds (targets closer)
- Fewer timeouts
- Higher success rate

**Implementation:**
- Update `_calculate_target_priority()` to include distance-from-claim factor
- Weight targets within 800px 2x higher than targets >1200px

---

### 🔧 Priority 4: Extend Herding Range Further (LOW)

**Problem:** 150px capture range is too close for distant targets

**Solution:**
- Keep 150px capture range (for "capturing" mechanic)
- But increase **extended herding range** from 300px to **500px**
- Attempt herding more aggressively during approach

**Expected Impact:**
- More herding attempts during approach
- Targets have more opportunities to be herded
- Slightly higher success rate

**Trade-off:**
- Might make herding too easy (user requested closer range for "capturing")
- Balance: Keep 150px capture, but attempt more during approach

---

### 🔧 Priority 5: Improve Search Pattern (LOW)

**Problem:** Caveman searches randomly, doesn't prioritize closer targets

**Solution:**
- Refine spiral search to prioritize targets within 800px
- Don't target NPCs >1200px from claim unless no closer targets available
- Add "search zones" - search close first, then expand

**Expected Impact:**
- More efficient target selection
- Fewer wasted attempts on distant targets
- Better success rate

---

### 🔧 Priority 6: Reduce Blacklist Duration (LOW)

**Problem:** 60-second blacklist might be too long

**Solution:**
- Reduce blacklist from 60s to **30-45 seconds**
- Allow re-targeting sooner if target gets closer

**Expected Impact:**
- More attempts per target
- Slightly higher success rate
- Less wasted time

**Trade-off:**
- Might cause more timeout cycles if target is still too far

---

## Summary of Recommendations

| Priority | Recommendation | Expected Impact | Complexity |
|----------|---------------|-----------------|------------|
| **1** | Fix intercept validation (allow movement beyond 500px for distant targets) | 🔴 CRITICAL | Medium |
| **2** | Increase timeout duration (8-10s for distant targets) | 🔴 HIGH | Low |
| **3** | Improve target selection (prioritize closer targets) | 🟡 MEDIUM | Medium |
| **4** | Extend herding range further (300px → 500px) | 🟢 LOW | Low |
| **5** | Improve search pattern (prioritize close targets) | 🟢 LOW | Medium |
| **6** | Reduce blacklist duration (60s → 30-45s) | 🟢 LOW | Low |

---

## Expected Results After Fixes

**Current State:**
- Success rate: **~7%** (3/44 entries)
- Average timeout distance: **~1093px**
- Timeouts per 180s: **40**
- Intercept rejections: **8,783** (CRITICAL)

**After Priority 1 Fix (Intercept Validation):**
- Success rate: **~40-50%** (18-22/44 entries) - **MAJOR IMPROVEMENT**
- Average timeout distance: **~800px** (fewer distant targets)
- Timeouts per 180s: **~10-15** (reduced by ~70%)
- Intercept rejections: **~500** (reduced by ~95%)

**After Priority 1 & 2 Fixes:**
- Success rate: **~50-60%** (22-26/44 entries)
- Average timeout distance: **~600px**
- Timeouts per 180s: **~5-8**

**After All Fixes:**
- Success rate: **~60-70%** (26-31/44 entries)
- Average timeout distance: **~500px**
- Timeouts per 180s: **~3-5**

---

## Next Steps

1. **Implement Priority 1** (fix intercept validation) - **CRITICAL** - This is the #1 blocker
2. **Implement Priority 2** (increase timeout duration) - **HIGH**
3. **Test and verify** improvements (should see ~40-50% success rate)
4. **Implement Priority 3-6** if needed for further optimization

---

**Analysis Date:** 2026-01-10  
**Test Duration:** 180 seconds  
**Status:** Critical issues identified - ready for fixes
