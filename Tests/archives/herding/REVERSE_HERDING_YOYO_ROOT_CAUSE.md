# Reverse Herding & Yo-Yo Oscillation Root Cause Analysis
**Generated:** January 11, 2026
**Based on:** Analysis of all reverse herding documentation and current code

## Problem Statement

**Yo-Yo Behavior:** Caveman and herded NPC alternate between following each other, moving back and forth without making progress toward the land claim. They waste time oscillating instead of moving together toward the goal.

**Pattern:**
1. Caveman herds NPC (herding succeeds)
2. Caveman tries to lead toward land claim
3. Herded NPC follows caveman
4. **But:** Caveman moves toward NPC or follower moves away
5. **Result:** They oscillate back and forth (yo-yo pattern)
6. Never make progress toward land claim

---

## Root Cause Analysis

### Root Cause #1: Caveman Speed Adjustment Creates Follower/Caveman Feedback Loop

**Code Location:** `scripts/npc/states/herd_wildnpc_state.gd` lines 518-531

**Current Logic:**
```gdscript
# Adjust speed based on follower distance (smooth curve to prevent yo-yo oscillation)
var ideal_distance: float = 100.0
var min_speed_mult: float = 0.4  # Slowest speed (when follower is far)
var max_speed_mult: float = 0.6  # Fastest speed (when follower is close)
var smoothing_distance: float = 200.0

var normalized_distance: float = clamp(woman_distance / smoothing_distance, 0.0, 1.0)
var leading_speed_mult: float = lerp(max_speed_mult, min_speed_mult, normalized_distance)

npc.steering_agent.speed_multiplier = speed_multiplier * leading_speed_mult
```

**The Problem:**
1. **Follower is close (<100px)** → Caveman speeds up (0.6x)
2. Caveman moves faster → Follower falls behind
3. **Follower falls behind (>100px)** → Caveman slows down (0.4x)
4. Caveman moves slower → Follower catches up
5. **Follower catches up (<100px)** → Caveman speeds up again
6. **LOOP:** This creates a feedback loop causing yo-yo oscillation

**Why This Happens:**
- Caveman adjusts speed based on follower distance
- But follower distance changes based on caveman speed
- Creates a feedback loop: speed change → distance change → speed change → ...
- Result: Continuous oscillation without making progress

### Root Cause #2: Follower Target Calculation Can Flip Direction

**Code Location:** `scripts/npc/states/herd_state.gd` lines 138-151

**Current Logic:**
```gdscript
# Good distance (50-300px) - maintain ideal distance
var direction_to_herder: Vector2 = (herder_pos - npc.global_position).normalized()
var drift_angle: float = randf_range(-0.15, 0.15)  # ±0.15 radians
var drift_direction: Vector2 = direction_to_herder.rotated(drift_angle)
target = herder_pos - drift_direction * target_distance
```

**The Problem:**
1. Follower calculates `direction_to_herder` (toward caveman)
2. Applies drift angle rotation (±0.15 radians ≈ ±8.6°)
3. Places target at: `herder_pos - drift_direction * target_distance`
4. **If drift angle is large enough AND positions align wrong:** Target can be placed BEHIND the herder (opposite direction from follower)
5. Follower moves toward target → moves away from herder
6. Distance increases → caveman adjusts → oscillation

**Why This Happens:**
- Target placement: `herder_pos - drift_direction * target_distance`
- If `drift_direction` points away from follower → target is placed behind herder
- Follower moves toward target → moves away from herder
- Creates oscillation

### Root Cause #3: Caveman May Be Following NPC Instead of Leading

**Code Location:** `scripts/npc/states/herd_wildnpc_state.gd` lines 487-539

**The Problem:**
1. Caveman should ALWAYS lead to land claim when NPC is herded
2. Code sets `steering_agent.target_position = claim_position` (correct)
3. **BUT:** If caveman's target calculation is wrong or gets overridden, caveman might move toward NPC instead
4. If caveman moves toward NPC, and NPC follows caveman → they meet in middle
5. Then caveman leads away, NPC follows → oscillation

**Current Leading Logic:**
```gdscript
if should_lead:
    if land_claim:
        npc.steering_agent.set_target_position(claim_position)  # Should always go to claim
```

This looks correct, but if `should_lead` is false or gets set incorrectly, caveman falls through to approach logic.

### Root Cause #4: Follower Speed vs Caveman Speed Mismatch

**Code Location:** `scripts/npc/states/herd_state.gd` line 160

**Current Logic:**
```gdscript
npc.steering_agent.speed_multiplier = 1.25  # 25% faster when following
```

**The Problem:**
1. Follower moves at 1.25x speed (25% faster)
2. Caveman moves at 0.4-0.6x speed when leading (40-60% of normal)
3. **Speed mismatch:** Follower is faster than caveman when caveman slows down
4. Follower catches up too fast → overshoots ideal distance
5. Caveman speeds up → follower falls behind
6. **Oscillation:** Continuous catch-up/overshoot cycle

### Root Cause #5: No Hysteresis in Distance Thresholds

**Code Location:** Both `herd_wildnpc_state.gd` and `herd_state.gd`

**The Problem:**
1. Caveman uses single threshold (100px ideal distance)
2. Follower uses single thresholds (50px min, 150px max)
3. **No hysteresis:** Same threshold for speeding up and slowing down
4. If distance hovers around threshold → continuous state changes
5. **Example:** Distance = 100px (exactly at threshold)
   - Frame 1: Distance = 99px → caveman speeds up
   - Frame 2: Follower catches up, distance = 98px → caveman still fast
   - Frame 3: Follower overshoots, distance = 102px → caveman slows down
   - Frame 4: Follower falls behind, distance = 103px → caveman still slow
   - Frame 5: Distance = 99px → caveman speeds up again
   - **LOOP:** Continuous oscillation

---

## Why Previous Fixes Didn't Work

### Fix #1: Velocity Clearing (Implemented)
- ✅ Clears velocity when herding succeeds
- ✅ Prevents 1-frame reverse herding
- ❌ **Doesn't prevent ongoing oscillation** - only fixes initial frame

### Fix #2: Immediate Redirect (Implemented)
- ✅ Sets target to claim immediately when herding succeeds
- ✅ Prevents initial reverse movement
- ❌ **Doesn't prevent ongoing oscillation** - only fixes initial frame

### Fix #3: Safety Check (Implemented)
- ✅ Detects reverse herding and corrects it
- ✅ Forces correction when distance increases
- ❌ **Reactive, not preventative** - detects after it happens
- ❌ **May actually cause oscillation** - if threshold too sensitive

### Fix #4: Smooth Speed Interpolation (Implemented)
- ✅ Uses lerp instead of discrete thresholds
- ❌ **Still creates feedback loop** - speed still changes based on distance
- ❌ **Doesn't break oscillation cycle** - just makes it smoother

**Why These Didn't Work:**
- All fixes address **symptoms** (reverse movement, speed changes)
- None address **root cause** (feedback loop between speed and distance)
- The fundamental problem: **Caveman speed adjustment reacts to follower distance, but follower distance changes based on caveman speed → feedback loop**

---

## The Fundamental Problem: Feedback Loop

### The Feedback Loop:

```
1. Follower distance increases
   ↓
2. Caveman slows down (to wait for follower)
   ↓
3. Follower catches up (caveman is slower)
   ↓
4. Follower distance decreases
   ↓
5. Caveman speeds up (follower is close)
   ↓
6. Follower falls behind (caveman is faster)
   ↓
7. LOOP BACK TO STEP 1
```

**This is a classic feedback loop problem:**
- **Input:** Follower distance
- **Output:** Caveman speed
- **Feedback:** Caveman speed affects follower distance
- **Result:** Continuous oscillation

### Why It's Hard to Fix:

1. **Speed adjustment is necessary** - Caveman needs to slow down when follower is far
2. **But speed adjustment causes oscillation** - Creates feedback loop
3. **Challenge:** Break the feedback loop without removing speed adjustment entirely

---

## Root Cause Summary

| Root Cause | Impact | Severity |
|------------|--------|----------|
| **Feedback Loop** | Caveman speed → follower distance → caveman speed | CRITICAL |
| **Follower Target Placement** | Target can be behind herder, causing reverse movement | HIGH |
| **Speed Mismatch** | Follower faster than slow caveman, overshoots | HIGH |
| **No Hysteresis** | Threshold triggers oscillation around boundary | MEDIUM |
| **Should_lead Check** | May fail, causing approach logic instead of leading | MEDIUM |

**Primary Root Cause:** **Feedback loop between caveman speed adjustment and follower distance**

---

## Proposed Solutions (Ordered by Root Cause Fix)

### Solution 1: Remove Speed Adjustment (BREAKS FEEDBACK LOOP)

**The Simplest Fix:** Don't adjust caveman speed based on follower distance.

**Implementation:**
```gdscript
# Remove speed adjustment when leading
if should_lead:
    if land_claim:
        npc.steering_agent.set_target_position(claim_position)
        # Keep speed constant - don't adjust based on follower distance
        if npc.steering_agent and "speed_multiplier" in npc.steering_agent:
            npc.steering_agent.speed_multiplier = speed_multiplier  # Use base speed, no adjustment
```

**Pros:**
- ✅ Breaks feedback loop completely
- ✅ Caveman moves at constant speed toward claim
- ✅ Simple, no complex logic

**Cons:**
- ❌ Caveman won't wait for follower if they fall behind
- ❌ May break herd if follower is too slow
- ❌ Less natural behavior

### Solution 2: Add Hysteresis to Speed Adjustment (REDUCES OSCILLATION)

**The Smart Fix:** Use different thresholds for speeding up vs slowing down.

**Implementation:**
```gdscript
# Hysteresis: Different thresholds for speeding up vs slowing down
var speed_up_threshold: float = 150.0   # Speed up when follower > 150px
var slow_down_threshold: float = 80.0    # Slow down when follower < 80px
# Gap between thresholds (80-150px) prevents oscillation

var leading_speed_mult: float
if woman_distance > speed_up_threshold:
    # Follower is far - speed up (but cap at max)
    leading_speed_mult = min_speed_mult  # Actually, wait - this is backwards
    # Need to fix: far follower = slower caveman (to wait)
    
# Corrected logic:
if woman_distance > speed_up_threshold:
    # Follower is far (>150px) - slow down to wait (0.4x)
    leading_speed_mult = min_speed_mult
elif woman_distance < slow_down_threshold:
    # Follower is close (<80px) - speed up (0.6x)
    leading_speed_mult = max_speed_mult
else:
    # Follower in dead zone (80-150px) - keep current speed or use middle speed
    leading_speed_mult = (min_speed_mult + max_speed_mult) / 2.0  # 0.5x
```

**Pros:**
- ✅ Prevents oscillation around single threshold
- ✅ Creates "dead zone" where speed doesn't change
- ✅ Maintains speed adjustment (waits for follower)

**Cons:**
- ⚠️ Still has feedback loop, just reduces oscillation
- ⚠️ More complex logic

### Solution 3: Limit Speed Adjustment Frequency (REDUCES OSCILLATION)

**The Temporal Fix:** Only adjust speed every N frames, not every frame.

**Implementation:**
```gdscript
var last_speed_adjust_time: float = 0.0
var speed_adjust_interval: float = 0.5  # Adjust every 0.5 seconds

var current_time = Time.get_ticks_msec() / 1000.0
if current_time - last_speed_adjust_time >= speed_adjust_interval:
    last_speed_adjust_time = current_time
    # Only adjust speed here (every 0.5s)
    var leading_speed_mult = lerp(...)  # Calculate speed
    npc.steering_agent.speed_multiplier = speed_multiplier * leading_speed_mult
# Else: Keep previous speed (don't adjust)
```

**Pros:**
- ✅ Reduces frequency of speed changes
- ✅ Allows system to stabilize between adjustments
- ✅ Breaks rapid oscillation cycle

**Cons:**
- ⚠️ Still has feedback loop, just slower
- ⚠️ May feel laggy

### Solution 4: Fix Follower Target Placement (PREVENTS REVERSE MOVEMENT)

**The Direction Fix:** Ensure follower target is always between follower and herder, never behind herder.

**Implementation:**
```gdscript
# Good distance (50-300px) - maintain ideal distance
var direction_to_herder: Vector2 = (herder_pos - npc.global_position).normalized()

# Clamp drift angle to prevent target from flipping behind herder
var max_drift_angle: float = 0.1  # Reduce from 0.15 to 0.1 (≈5.7°)
var drift_angle: float = clamp(randf_range(-max_drift_angle, max_drift_angle), -0.1, 0.1)
var drift_direction: Vector2 = direction_to_herder.rotated(drift_angle)

# Ensure target is always between follower and herder (not behind herder)
var target = herder_pos - drift_direction * target_distance

# Verify target direction is correct (target should be closer to follower than herder)
var follower_to_target: Vector2 = (target - npc.global_position).normalized()
var follower_to_herder: Vector2 = direction_to_herder
var dot_product: float = follower_to_target.dot(follower_to_herder)

# If target is behind herder (dot product negative), fix it
if dot_product < 0.0:
    # Target is behind herder - flip to other side
    target = herder_pos + drift_direction * target_distance
```

**Pros:**
- ✅ Prevents follower from moving away from herder
- ✅ Ensures follower always moves toward herder
- ✅ Fixes root cause #2

**Cons:**
- ⚠️ Doesn't fix speed feedback loop
- ⚠️ More complex validation

### Solution 5: Match Speeds (REDUCES OVERSHOOT)

**The Speed Fix:** Make follower speed match caveman's adjusted speed.

**Implementation:**
```gdscript
# In herd_wildnpc_state.gd when leading:
var leading_speed_mult = lerp(...)  # Calculate caveman speed
npc.steering_agent.speed_multiplier = speed_multiplier * leading_speed_mult

# Pass caveman speed to follower somehow (meta or signal)
npc.set_meta("leading_speed_multiplier", leading_speed_mult)

# In herd_state.gd when following:
var herder_speed_mult: float = 1.0
if npc.herder and npc.herder.has_meta("leading_speed_multiplier"):
    herder_speed_mult = npc.herder.get_meta("leading_speed_multiplier")

# Match follower speed to herder's adjusted speed
npc.steering_agent.speed_multiplier = 1.0 * herder_speed_mult
# Or: npc.steering_agent.speed_multiplier = base_speed * herder_speed_mult * 1.1  # Slightly faster to catch up
```

**Pros:**
- ✅ Prevents speed mismatch
- ✅ Follower and caveman move at similar speeds
- ✅ Reduces overshoot/catch-up cycle

**Cons:**
- ⚠️ Requires communication between states
- ⚠️ Doesn't fix feedback loop if speed still adjusts

---

## Recommended Solution: Multi-Layered Fix

**Combine Solutions 1 + 2 + 4:**

1. **Solution 2 (Hysteresis):** Add dead zone to speed adjustment (80-150px)
2. **Solution 4 (Target Fix):** Ensure follower target is never behind herder
3. **Solution 1 (Simplified):** Keep constant speed in dead zone, only adjust at extremes

**Implementation:**
```gdscript
# In herd_wildnpc_state.gd:
if should_lead:
    if land_claim:
        npc.steering_agent.set_target_position(claim_position)
        
        # HYSTERESIS: Different thresholds for speeding up vs slowing down
        var speed_up_threshold: float = 150.0   # Speed up when follower > 150px
        var slow_down_threshold: float = 80.0    # Slow down when follower < 80px
        var dead_zone_speed: float = 0.5        # Speed in dead zone (80-150px)
        
        var leading_speed_mult: float
        if woman_distance > speed_up_threshold:
            # Follower is far (>150px) - slow down to wait (0.4x)
            leading_speed_mult = min_speed_mult
        elif woman_distance < slow_down_threshold:
            # Follower is close (<80px) - speed up (0.6x)
            leading_speed_mult = max_speed_mult
        else:
            # Follower in dead zone (80-150px) - constant speed (0.5x)
            leading_speed_mult = dead_zone_speed
        
        npc.steering_agent.speed_multiplier = speed_multiplier * leading_speed_mult

# In herd_state.gd:
# Fix target placement to never be behind herder
var direction_to_herder: Vector2 = (herder_pos - npc.global_position).normalized()
var max_drift_angle: float = 0.1  # Reduced from 0.15
var drift_angle: float = clamp(randf_range(-max_drift_angle, max_drift_angle), -0.1, 0.1)
var drift_direction: Vector2 = direction_to_herder.rotated(drift_angle)
var target = herder_pos - drift_direction * target_distance

# Verify target direction
var follower_to_target: Vector2 = (target - npc.global_position).normalized()
var dot_product: float = follower_to_target.dot(direction_to_herder)
if dot_product < 0.0:
    # Target is behind herder - fix it
    target = herder_pos + drift_direction * target_distance
```

**Why This Works:**
1. **Hysteresis** breaks rapid oscillation (dead zone prevents constant speed changes)
2. **Target fix** prevents reverse movement (follower never moves away)
3. **Constant speed in dead zone** reduces feedback loop strength

---

## Next Steps

1. **Implement Solution 2 (Hysteresis)** - Add dead zone to speed adjustment
2. **Implement Solution 4 (Target Fix)** - Ensure follower target is never behind herder
3. **Test** - Run test 3 and monitor for yo-yo behavior
4. **If still oscillating:** Consider Solution 1 (remove speed adjustment entirely) or Solution 5 (match speeds)

---

**Root Cause Identified:** **Feedback loop between caveman speed adjustment and follower distance**
**Primary Fix:** **Add hysteresis to speed adjustment (dead zone) to break oscillation cycle**
