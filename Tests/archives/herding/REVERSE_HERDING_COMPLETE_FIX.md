# Reverse Herding - Complete Fix (Once and For All)
**Generated:** January 11, 2026
**Goal:** Eliminate reverse herding and yo-yo oscillation permanently

## Root Cause Summary

**PRIMARY ROOT CAUSE:** Feedback loop between caveman speed adjustment and follower distance
- Caveman adjusts speed (0.4x-0.6x) based on follower distance
- Follower distance changes based on caveman speed
- **Result:** Continuous yo-yo oscillation

**SECONDARY ROOT CAUSES:**
1. Follower target placement can flip behind herder
2. Speed mismatch (follower 1.25x vs caveman 0.4-0.6x)
3. No hysteresis in distance thresholds
4. Safety check only reactive, not preventative

---

## Complete Fix Strategy

### Fix #1: Add Hysteresis to Speed Adjustment (BREAKS FEEDBACK LOOP)

**Problem:** Caveman speed changes continuously based on follower distance, creating feedback loop.

**Solution:** Add dead zone (hysteresis) so speed only changes at extremes, not constantly.

**Implementation:**
```gdscript
# In herd_wildnpc_state.gd, lines 518-531:
# Replace current speed adjustment with hysteresis-based version

var ideal_distance: float = 100.0
var min_speed_mult: float = 0.4  # Slowest speed (when follower is far)
var max_speed_mult: float = 0.6  # Fastest speed (when follower is close)

# HYSTERESIS: Different thresholds for speeding up vs slowing down
var speed_up_threshold: float = 150.0   # Speed up when follower > 150px
var slow_down_threshold: float = 80.0    # Slow down when follower < 80px
var dead_zone_speed: float = 0.5        # Constant speed in dead zone (80-150px)

# Current speed multiplier (track across frames)
var current_speed_mult: float = npc.get_meta("leading_speed_mult", 0.5) if npc.has_meta("leading_speed_mult") else 0.5

var leading_speed_mult: float
if woman_distance > speed_up_threshold:
    # Follower is far (>150px) - slow down to wait (0.4x)
    leading_speed_mult = min_speed_mult
elif woman_distance < slow_down_threshold:
    # Follower is close (<80px) - speed up (0.6x)
    leading_speed_mult = max_speed_mult
else:
    # Follower in dead zone (80-150px) - keep current speed or use constant speed
    # Use current speed to maintain stability (no change)
    leading_speed_mult = current_speed_mult
    # OR use constant: leading_speed_mult = dead_zone_speed

# Store current speed for next frame
if npc.has_meta("leading_speed_mult"):
    npc.set_meta("leading_speed_mult", leading_speed_mult)
else:
    npc.set_meta("leading_speed_mult", leading_speed_mult)

if npc.steering_agent and "speed_multiplier" in npc.steering_agent:
    npc.steering_agent.speed_multiplier = speed_multiplier * leading_speed_mult
```

**Why This Works:**
- **Dead zone (80-150px):** Speed doesn't change → breaks feedback loop
- **Hysteresis:** Different thresholds for speeding up (150px) vs slowing down (80px)
- **Gap (70px):** Prevents oscillation around single threshold
- **Result:** Follower can maintain distance in dead zone without triggering speed changes

---

### Fix #2: Fix Follower Target Placement (PREVENTS REVERSE MOVEMENT)

**Problem:** Follower target can be placed behind herder, causing follower to move away.

**Solution:** Ensure target is always between follower and herder, never behind.

**Implementation:**
```gdscript
# In herd_state.gd, lines 138-151:
# Fix target calculation to prevent placement behind herder

# Good distance (50-300px) - maintain ideal distance
var direction_to_herder: Vector2 = (herder_pos - npc.global_position).normalized()

# Clamp drift angle to smaller range to prevent flipping
var max_drift_angle: float = 0.08  # Reduced from 0.15 to 0.08 (≈4.6°)
var drift_angle: float = clamp(randf_range(-max_drift_angle, max_drift_angle), -0.08, 0.08)
var drift_direction: Vector2 = direction_to_herder.rotated(drift_angle)

# Calculate target position
var target = herder_pos - drift_direction * target_distance

# VERIFY: Ensure target is always between follower and herder (never behind herder)
var follower_to_target: Vector2 = (target - npc.global_position).normalized()
var follower_to_herder: Vector2 = direction_to_herder
var dot_product: float = follower_to_target.dot(follower_to_herder)

# If target is behind herder (dot product negative), fix it
if dot_product < 0.3:  # Allow some tolerance (0.3 = ~72°)
    # Target is too far behind herder - flip to correct side
    # Use opposite of drift direction to place target between follower and herder
    target = herder_pos + drift_direction * target_distance
    # Re-verify
    follower_to_target = (target - npc.global_position).normalized()
    dot_product = follower_to_target.dot(follower_to_herder)
    # If still wrong, use direct direction (no drift)
    if dot_product < 0.3:
        target = herder_pos - direction_to_herder * target_distance

current_target = target
```

**Why This Works:**
- **Direction validation:** Checks if target is behind herder using dot product
- **Automatic correction:** Flips target if behind herder
- **Reduced drift:** Smaller angle (0.08 vs 0.15) reduces chance of flipping
- **Result:** Follower always moves toward herder, never away

---

### Fix #3: Improve Safety Check (MORE SENSITIVE, PREVENTATIVE)

**Problem:** Safety check requires >100px increase AND >500px distance, may miss yo-yo oscillation.

**Solution:** Lower thresholds, remove distance requirement, add oscillation detection.

**Implementation:**
```gdscript
# In herd_wildnpc_state.gd, lines 498-511:
# Make safety check more sensitive and preventative

# SAFETY CHECK: Detect and stop reverse herding (IMPROVED)
var last_distance_key = "last_distance_to_claim_leading"
if npc.has_meta(last_distance_key):
    var last_distance: float = npc.get_meta(last_distance_key)
    var distance_increase: float = current_distance - last_distance
    
    # IMPROVED: Lower threshold (50px instead of 100px) and remove distance requirement
    # Also detect oscillation pattern (distance increasing then decreasing)
    if distance_increase > 50.0:  # Reduced from 100px to 50px
        # Reverse herding detected - force correction
        print("⚠️ REVERSE_HERDING_DETECTED: %s moving away from claim (%.1fpx -> %.1fpx, +%.1fpx) - forcing correction" % [
            npc.npc_name, last_distance, current_distance, distance_increase
        ])
        # Force immediate correction - lead directly to claim
        npc.steering_agent.set_target_position(claim_position)
        # Clear velocity to prevent momentum carryover
        if npc is CharacterBody2D:
            var body: CharacterBody2D = npc as CharacterBody2D
            body.velocity = Vector2.ZERO
        
        # Track oscillations (distance increasing then decreasing repeatedly)
        var oscillation_count: int = npc.get_meta("reverse_herding_oscillation_count", 0) if npc.has_meta("reverse_herding_oscillation_count") else 0
        oscillation_count += 1
        npc.set_meta("reverse_herding_oscillation_count", oscillation_count)
        
        # If oscillating too much (>3 times), break the herd temporarily
        if oscillation_count > 3:
            print("🛑 REVERSE_HERDING_PERSISTENT: %s oscillating too much - breaking herd temporarily" % npc.npc_name)
            target_woman = null
            npc.remove_meta("reverse_herding_oscillation_count")
            if fsm:
                fsm.change_state("wander")
            return
    else:
        # Distance not increasing - clear oscillation counter
        if npc.has_meta("reverse_herding_oscillation_count"):
            npc.remove_meta("reverse_herding_oscillation_count")

# Store current distance for next frame comparison
npc.set_meta(last_distance_key, current_distance)
```

**Why This Works:**
- **Lower threshold (50px):** Catches smaller oscillations
- **No distance requirement:** Catches reverse herding at any distance
- **Oscillation detection:** Tracks repeated oscillations
- **Herd break:** Breaks herd if oscillation persists (>3 times)
- **Velocity clearing:** Prevents momentum carryover

---

### Fix #4: Ensure Target is Set Correctly (PREVENT FALLBACK TO APPROACH)

**Problem:** If `should_lead` check fails, code falls through to approach logic which can cause reverse herding.

**Solution:** Ensure leading logic always executes when target is herded, with multiple safeguards.

**Implementation:**
```gdscript
# In herd_wildnpc_state.gd, lines 476-486:
# Add additional safeguards to ensure leading logic executes

# FINAL FIX: Two-stage check to guarantee leading after successful herding
var should_lead: bool = false
if herding_succeeded_this_frame:
    # Stage 1: Just successfully herded - ALWAYS lead, no verification needed
    should_lead = true
elif is_herded_by_us:
    # Stage 2: Target was already herded - verify it's still herded (might have been stolen)
    var verify_herded = target_woman.get("is_herded") if target_woman else false
    var verify_herder = target_woman.get("herder") if target_woman else null
    should_lead = verify_herded and verify_herder == npc
else:
    # ADDITIONAL SAFEGUARD: Check target state directly (bypass is_herded_by_us flag)
    if target_woman:
        var direct_herded = target_woman.get("is_herded") if target_woman else false
        var direct_herder = target_woman.get("herder") if target_woman else null
        if direct_herded and direct_herder == npc:
            # Target is actually herded, but flag is wrong - fix it and lead
            is_herded_by_us = true
            should_lead = true

# CRITICAL: If should_lead is still false but target exists, check one more time
if not should_lead and target_woman and is_instance_valid(target_woman):
    var final_check_herded = target_woman.get("is_herded") if target_woman else false
    var final_check_herder = target_woman.get("herder") if target_woman else null
    if final_check_herded and final_check_herder == npc:
        # Target is herded - MUST lead, override should_lead
        should_lead = true
        is_herded_by_us = true
```

**Why This Works:**
- **Multiple checks:** Ensures leading logic executes even if initial check fails
- **State validation:** Checks target state directly, bypassing flags if needed
- **Override:** Forces `should_lead = true` if target is actually herded
- **Result:** Leading logic always executes when target is herded, never falls through to approach

---

## Complete Implementation

### File 1: `scripts/npc/states/herd_wildnpc_state.gd`

**Location:** Lines 476-531

**Changes:**
1. **Add hysteresis to speed adjustment** (Fix #1)
2. **Improve safety check** (Fix #3)
3. **Add additional safeguards** (Fix #4)

### File 2: `scripts/npc/states/herd_state.gd`

**Location:** Lines 138-151

**Changes:**
1. **Fix follower target placement** (Fix #2)

---

## Testing Plan

1. **Test 1: Basic Reverse Herding**
   - Herd NPC far from claim
   - Verify caveman leads toward claim (not away)
   - Check logs for `REVERSE_HERDING_DETECTED` (should be 0 or very few)

2. **Test 2: Yo-Yo Oscillation**
   - Herd NPC and monitor positions
   - Verify no back-and-forth oscillation
   - Check distance to claim decreases steadily

3. **Test 3: Follower Direction**
   - Herd NPC and monitor follower
   - Verify follower always moves toward herder (not away)
   - Check follower target placement (should never be behind herder)

4. **Test 4: Speed Adjustment**
   - Herd NPC and monitor speeds
   - Verify speed changes only at thresholds (80px and 150px)
   - Verify constant speed in dead zone (80-150px)

5. **Test 5: Long-Term Stability**
   - Run 3-minute test
   - Monitor for any reverse herding or oscillation
   - Check safety check triggers (should be 0 or very few)

---

## Expected Results

**After fixes:**
- ✅ No reverse herding (caveman always leads toward claim)
- ✅ No yo-yo oscillation (dead zone breaks feedback loop)
- ✅ Follower always moves toward herder (target never behind)
- ✅ Stable speed in dead zone (no constant changes)
- ✅ Safety check catches any remaining cases (but shouldn't trigger often)

**Success Criteria:**
- 0 `REVERSE_HERDING_DETECTED` messages in test logs
- Steady decrease in distance to claim (no oscillations)
- No yo-yo patterns in position logs
- Smooth movement (no back-and-forth)

---

## Implementation Order

1. **Fix #2 (Follower Target)** - Prevents reverse movement
2. **Fix #1 (Hysteresis)** - Breaks feedback loop
3. **Fix #4 (Safeguards)** - Ensures leading logic executes
4. **Fix #3 (Safety Check)** - Catches any remaining cases

**Priority:** Fix #1 (Hysteresis) is most critical - it breaks the feedback loop that causes yo-yo oscillation.

---

**This comprehensive fix addresses ALL root causes of reverse herding and should eliminate it once and for all.**
