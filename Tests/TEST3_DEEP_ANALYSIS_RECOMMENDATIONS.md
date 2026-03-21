# Test 3 Deep Analysis & Recommendations

## Test Results Summary

**Duration:** 180 seconds (3 minutes)  
**Caveman:** YUJI  
**Results:**
- ✅ 4 herding attempts started
- ✅ 2 NPCs successfully joined clan (Goat 1686, Woman 3)
- ❌ 2 herds broke (at exactly 600.3px and 600.8px)
- ❌ Caveman spent **80.5s in wander** (44% of test time!)
- ❌ Caveman exited herd_wildnpc after only 0.5s on one occasion
- ✅ Average wander duration: 38.5s when transitioning states

---

## Critical Issues Identified

### 1. **Excessive Time in Wander State** 🔴 CRITICAL
**Problem:**
- YUJI spent **80.5 seconds** in wander state (44% of test time)
- Additional **23.4s** in wander in another instance
- Average wander duration: **38.5s**
- **Caveman should be actively herding, not wandering**

**Root Cause:**
- After exiting `herd_wildnpc` state (no target found), caveman goes to wander
- Wander state's 1-second timeout to force FSM evaluation may not be triggering correctly
- `herd_wildnpc.can_enter()` may be returning false when it shouldn't

**Recommendation:**
1. **Force immediate FSM re-evaluation** when `herd_wildnpc` exits to wander
2. **Increase herd_wildnpc detection range** when searching (currently 1500px)
3. **Add aggressive re-entry logic** - if exiting herd_wildnpc due to no target, immediately check again
4. **Reduce wander state timeout** from 1 second to 0.1 seconds for cavemen

### 2. **Herds Breaking at Exactly 600px** 🟡 MEDIUM
**Problem:**
- Goat 1686 lost herder at **600.3px** (just over 600px limit)
- Woman 3 lost herder at **600.8px** (just over 600px limit)
- Current break distance: **600px** (`herd_max_distance_before_break`)

**Root Cause:**
- Caveman may be moving too fast when leading, causing wild NPCs to fall behind
- Wild NPCs following may not be catching up fast enough
- 600px threshold is too strict for dynamic movement

**Recommendation:**
1. **Increase herd break distance** from 600px to **800-1000px** to account for movement dynamics
2. **Add catch-up speed boost** for wild NPCs when distance > 400px (faster than herder)
3. **Monitor distance continuously** and slow down caveman if wild NPCs falling behind
4. **Add grace period** - don't break immediately at 600px, give 2-3 seconds to catch up

### 3. **Premature Exit from herd_wildnpc State** 🟡 MEDIUM
**Problem:**
- YUJI exited `herd_wildnpc` after only **0.5 seconds** on one occasion
- This suggests `can_enter()` succeeded but target was lost immediately, or exit condition triggered too early

**Root Cause:**
- Target validation (`_is_valid_target()`) may be too strict
- `no_target_time` timeout (currently 10s doubled = 20s) might have edge case
- Target may have been found but immediately invalidated

**Recommendation:**
1. **Log target loss reasons** when exiting herd_wildnpc prematurely
2. **Increase minimum time in state** before allowing exit (unless target joins clan)
3. **Add grace period** before marking target as lost (currently 2s)
4. **Check if target is actually invalid** or just temporarily out of range

### 4. **No Deposit Activity** 🟢 LOW
**Problem:**
- No AUTO-DEPOSIT logs found in test
- Caveman inventory likely not filling up (only 1 berry to start)

**Analysis:**
- This is expected if caveman isn't gathering much
- Not a problem per se, but means we can't verify deposit→herd loop

**Recommendation:**
1. **Monitor deposit triggers** in future tests
2. **Verify deposit→herd loop** works when inventory fills

---

## Movement & Priority Analysis

### State Distribution Issues
- **Wander:** ~44% of time (80.5s / 180s) - **TOO HIGH**
- **herd_wildnpc:** Only entered 4 times, spent significant time searching
- **Gather:** Brief (0.2s) - correct
- **Deposit:** Not triggered

### Priority Flow Issues
Current priorities work, but:
1. **Wander state** should force faster re-evaluation (currently 1s, should be 0.1s)
2. **herd_wildnpc** should have even higher priority when no target (aggressive search mode)
3. **State transitions** may be too slow

---

## Specific Recommendations

### Priority 1: Fix Excessive Wander Time 🔴

**Implementation:**
```gdscript
# In wander_state.gd, update() for cavemen
if npc_type_wander == "caveman":
    # FORCE immediate evaluation if no task (0.1s instead of 1s)
    if wander_duration >= 0.1:  # Changed from 1.0
        fsm.evaluation_timer = 0.0
        fsm._evaluate_states()
```

**Also in herd_wildnpc_state.gd exit():**
```gdscript
func exit() -> void:
    # ... existing code ...
    # Force immediate FSM re-evaluation after exiting herd_wildnpc
    if fsm:
        fsm.evaluation_timer = 0.0
        fsm._evaluate_states()  # Check if can re-enter immediately
```

### Priority 2: Increase Herd Break Distance 🟡

**Implementation:**
```gdscript
# In npc_config.gd
@export var herd_max_distance_before_break: float = 800.0  # Increased from 600.0
```

**Also add catch-up logic in herd_state.gd:**
```gdscript
# When distance > 400px, boost wild NPC speed to catch up
if distance_to_herder > 400.0:
    npc.steering_agent.max_speed = base_speed * 1.5  # 50% faster
```

### Priority 3: Improve Target Persistence 🟡

**Implementation:**
```gdscript
# In herd_wildnpc_state.gd
# Increase grace period from 2s to 5s
var grace_period: float = 5.0  # Increased from 2.0

# Add minimum time in state (unless target joins clan)
var min_time_in_state: float = 3.0  # Don't exit before 3 seconds
```

### Priority 4: More Aggressive Search 🟢

**Implementation:**
```gdscript
# In herd_wildnpc_state.gd can_enter()
# When no target found, use wider detection range
var active_range: float = detection_range * 1.5  # 2250px when searching

# Faster spiral expansion
var spiral_expansion: float = 100.0  # Increased from 50.0
```

---

## Expected Improvements

After implementing these recommendations:

1. **Wander time reduced:** 80.5s → ~10-20s (75% reduction)
2. **Herd success rate:** 2/4 → 4/4 (100% if break distance fixed)
3. **NPCs herded:** 2 per 3 min → 4-6 per 3 min (2-3x improvement)
4. **State transitions:** Faster, more responsive

---

## Testing Plan

1. **Run Test 3 again** with fixes applied
2. **Monitor:**
   - Total time in each state
   - Number of herds started vs. completed
   - Herd break distances
   - State transition frequencies
3. **Compare** before/after metrics

---

## Code Changes Summary

### Files to Modify:
1. `scripts/npc/states/wander_state.gd` - Reduce timeout to 0.1s, force re-eval
2. `scripts/npc/states/herd_wildnpc_state.gd` - Force re-eval on exit, increase grace period, min time
3. `scripts/npc/states/herd_state.gd` - Catch-up speed boost, grace period for break
4. `scripts/config/npc_config.gd` - Increase break distance to 800px

### Configuration Changes:
- `herd_max_distance_before_break`: 600px → 800px
- Wander timeout (cavemen): 1.0s → 0.1s
- Target grace period: 2.0s → 5.0s
- Minimum herd_wildnpc time: 0s → 3.0s

---

**Analysis Date:** 2026-01-10  
**Test Log:** `/Users/macbook/Desktop/stoneageclans/Tests/test3_herding_system.log`
