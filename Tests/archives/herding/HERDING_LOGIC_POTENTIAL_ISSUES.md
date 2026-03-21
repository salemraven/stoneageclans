# Herding Logic Potential Issues Analysis
**Generated:** January 11, 2026
**Issue:** Are there other problems in herding logic that will cause issues?

## Already Fixed Issues

1. ✅ **900px intercept limit preventing herding** - Fixed (allow approaching unherded targets)
2. ✅ **Max distance limits** - Fixed (dynamic limits for herded vs unherded)
3. ✅ **Reverse herding from "too close" path** - Fixed (slow backup speed)
4. ✅ **Follower movement validation** - Fixed (enforce movement toward herder)

## Potential Issues to Check

### 1. Target Validation Logic

**Location:** Lines 196-213 (target in land claim check)

**Potential Issue:**
- Target moves into land claim → immediately cleared
- But what if target is already herded?
- Should we continue leading until claim is reached?

**Check:** Is target cleared immediately even if already herded?

### 2. Target Joins Clan While Being Herded

**Location:** Lines 181-195 (target joined clan check)

**Potential Issue:**
- Target joins clan → target cleared immediately
- But what if target joined OUR clan?
- Should we continue leading until claim is reached?

**Check:** Does this handle the case where target joins our clan?

### 3. Rapid State Transitions

**Potential Issue:**
- Caveman enters herd_wildnpc → immediately hits max distance → exits
- Re-enters → immediately hits max distance → exits
- Could create rapid state oscillation

**Check:** Is there protection against rapid state transitions?

### 4. Target Selection Filtering

**Location:** Lines 1090-1125 (target selection)

**Potential Issue:**
- 900px intercept check was preventing target selection
- Now fixed to use max_distance
- But what about other filters?

**Check:** Are there other filters preventing valid targets?

### 5. Herding Attempt Range vs Capture Range

**Location:** Lines 423-425 (herding attempt)

**Potential Issue:**
- Herding attempted within 300px (extended_herding_range)
- But capture requires 150px (_try_herd_chance max_range)
- If caveman is at 250px, attempts herding but always fails
- Could waste time attempting herding that can never succeed

**Check:** Should we only attempt herding within 150px, not 300px?

### 6. Intercept Calculation Issues

**Location:** Lines 562-578 (intercept calculation)

**Potential Issue:**
- Intercept position calculated
- But what if intercept position is invalid?
- What if target is moving unpredictably?
- Intercept might be wrong

**Check:** Is intercept calculation reliable?

### 7. Stealing Logic Conflicts

**Potential Issue:**
- Multiple cavemen try to herd same target
- Stealing logic determines who wins
- But what if both cavemen are at same distance?
- What if stealing causes rapid target switching?

**Check:** Is stealing logic stable?

### 8. Distance Limits Applied Inconsistently

**Potential Issue:**
- Max distance check at line 153: 2000px (or 2500px for herded)
- Intercept limit at line 567: 2000px for unherded, 900px for herded
- Target selection at line 1098: max_distance check
- Could have inconsistent limits

**Check:** Are all limits consistent?

### 9. Grace Period Logic

**Location:** Lines 214-228 (grace period)

**Potential Issue:**
- Target becomes invalid → grace period starts
- After grace period → target cleared
- But what if target becomes valid again during grace period?
- Is grace period reset?

**Check:** Is grace period logic correct?

### 10. Search Pattern When No Target

**Location:** Lines 243-310 (search pattern)

**Potential Issue:**
- When no target found, uses spiral search
- But what if all targets are filtered out?
- Caveman might spiral forever
- Is there a timeout?

**Check:** Is there protection against infinite searching?

## Issues Found

### Issue 1: Herding Attempt Range Mismatch

**Problem:**
- Herding attempted within 300px (extended_herding_range)
- But _try_herd_chance requires distance <= 150px
- If caveman is at 250px, attempts herding but always fails
- Wastes time on attempts that can never succeed

**Impact:** LOW - Caveman eventually gets closer, but wastes time

**Fix Needed:** Consider only attempting herding within 150px, or increase capture range

### Issue 2: Inconsistent Distance Limits

**Problem:**
- Max distance: 2000px (or 2500px for herded)
- Intercept limit: 2000px for unherded, 900px for herded
- Target selection: max_distance check
- These are now consistent, but should verify

**Impact:** LOW - Already fixed in recent changes

**Fix Needed:** Verify all limits are consistent

### Issue 3: Target Validation During Leading

**Problem:**
- Target validation checks happen even when leading
- If target enters land claim or joins clan, target is cleared
- But what if target joins OUR clan?
- Should we continue leading until claim is reached?

**Impact:** MEDIUM - Could cause premature target clearing

**Fix Needed:** Check if target joined our clan before clearing

### Issue 4: No Protection Against Rapid State Oscillation

**Problem:**
- Caveman enters herd_wildnpc → hits limit → exits
- Re-enters → hits limit → exits
- Could create rapid state transitions

**Impact:** MEDIUM - Could cause performance issues

**Fix Needed:** Add cooldown or hysteresis to prevent rapid transitions

## Recommended Fixes (Priority Order)

1. **HIGH:** Target validation during leading (check if target joined our clan)
2. **MEDIUM:** Rapid state oscillation protection (cooldown/hysteresis)
3. **LOW:** Herding attempt range optimization (only attempt within 150px)
4. **LOW:** Verify all distance limits are consistent
