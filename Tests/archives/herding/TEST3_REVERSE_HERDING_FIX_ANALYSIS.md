# Test 3 - Reverse Herding Fix Analysis

## Test Results Summary

**Duration:** 180 seconds (3 minutes)  
**Caveman:** QABE  
**Date:** 2026-01-10  
**Status:** ⚠️ **Regression - Very Low Activity**

---

## Key Metrics

### Herding Performance ⚠️ REGRESSION
- **Herding attempts:** 2 (down from 9)
- **NPCs joined clan:** 0 (down from 4)
- **Herds broken:** 0 (same)
- **Herder switches:** 0 (down from 8)
- **herd_wildnpc entries:** 1 (down from 3)

### Reverse Herding ✅ FIXED
- **Reverse herding detected:** 0 (down from 8 suspicious patterns)
- **✅ No reverse herding issues!**

---

## Issues Found

### 🔴 **Critical: Very Low Herding Activity**

**Problem:**
- Only 1 entry to `herd_wildnpc` state
- Only 2 herding attempts (both by Player, not QABE)
- 0 NPCs joined clan
- Caveman seems inactive in herding

**Possible Causes:**
1. **Extreme distance check too aggressive?** - 5000px threshold might be invalidating valid targets
2. **Intercept validation too strict?** - 200px threshold might be rejecting all intercept positions
3. **Caveman stuck in other states?** - Might be spending all time in gather/wander
4. **Target detection issues?** - Might not be finding targets at all

**Need to investigate:**
- Why did QABE only enter `herd_wildnpc` once?
- What state was QABE in for the rest of the test?
- Were there valid targets that QABE should have detected?
- Did the extreme distance check or intercept validation block all herding?

---

## Positive Findings ✅

1. **Reverse Herding:** ✅ **FIXED!** - No reverse herding patterns detected
2. **No Extreme Distances:** ✅ No caveman chasing targets 30k+ pixels away
3. **No Herds Broken:** ✅ All herding attempts maintained (though only 2)
4. **No Rapid Stealing:** ✅ No ping-pong stealing behavior

---

## Comparison: Before vs After Reverse Herding Fix

| Metric | Before Fix | After Fix | Change |
|--------|-----------|-----------|--------|
| Herding attempts | 9 | 2 | ⚠️ **-78%** |
| NPCs joined | 4 | 0 | ⚠️ **-100%** |
| herd_wildnpc entries | 3 | 1 | ⚠️ **-67%** |
| Reverse herding | 8 patterns | 0 | ✅ **FIXED** |
| Extreme distances | Yes (30k+px) | No | ✅ **FIXED** |
| Rapid stealing | 7 switches | 0 | ✅ **FIXED** |

---

## Hypothesis: Over-Correction

**Theory:** The fixes might be too aggressive:
1. **Extreme distance check (5000px):** Might be rejecting targets that are far but still valid
2. **Intercept validation (200px):** Might be rejecting all intercept positions, causing caveman to always lead to claim even when target is far away
3. **<50px direct lead:** This is probably fine, but combined with strict intercept validation, might prevent any herding attempts

**Possible Solution:**
- Reduce extreme distance threshold from 5000px to 2000px
- Reduce intercept validation threshold from 200px to 100px
- Add logging to see why targets are being rejected

---

## Next Steps

1. **Check QABE's state distribution** - How much time in each state?
2. **Check target detection** - Were there valid targets that should have been detected?
3. **Review extreme distance logs** - How many targets were rejected for being too far?
4. **Review intercept validation** - How many intercept positions were rejected?
5. **Adjust thresholds** - Make fixes less aggressive

---

**Analysis Date:** 2026-01-10  
**Status:** Reverse herding fixed, but regression in herding activity - need to adjust thresholds
