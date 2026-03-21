# Caveman Herding Efficiency Recommendations

Based on analysis of the current herding system and Test 3 results.

## Current Issues Identified

1. **Caveman only entered `herd_wildnpc` state once** during the entire 3-minute test
2. **Random search pattern** when no target found (wasteful)
3. **Target switching** happens every frame if target becomes invalid (potentially too frequent)
4. **No path prediction** - doesn't account for wild NPC movement
5. **Fixed approach speed** - doesn't adjust speed based on distance/time
6. **No memory of failed targets** - might retry NPCs that keep running away !!this is ok the caveamn can keep rerolling to herd the wild npc !!

## Efficiency Recommendations

### 1. **Smarter Target Selection** ⭐ HIGH PRIORITY

**Current:** Picks nearest unherded NPC, or nearest overall  
**Improvement:**
- **Prioritize by distance AND direction to land claim** - NPCs moving toward land claim are better targets
- **Consider NPC type priority** - Women > Sheep > Goats (or configurable)
- **Weight by success probability** - NPCs closer to land claim edge are easier
- **Avoid targets moving away rapidly** - if NPC velocity is away from caveman + land claim, skip

```gdscript
# Calculate priority score instead of just distance
var priority_score = 1.0 / distance  # Closer = better
if npc_velocity.dot(direction_to_claim) > 0:
    priority_score *= 1.5  # Moving toward land claim = bonus
if npc_type == "woman":
    priority_score *= 1.2  # Prefer women
```

### 2. **Target Persistence** ⭐ HIGH PRIORITY

**Current:** Switches target immediately if current target becomes invalid  
**Improvement:**
- **Don't abandon target if they just moved slightly outside detection range** - give 1-2 second grace period
- **Stick with current target** if within 400px, even if a closer one appears
- **Only switch if new target is significantly better** (>100px closer AND unherded)

```gdscript
# Add hysteresis to target switching
var target_stick_distance: float = 400.0  # Stick with target within this range
var min_distance_improvement: float = 100.0  # Only switch if new target is this much closer
```

### 3. **Movement Speed Optimization** ⭐ HIGH PRIORITY

**Current:** Fixed movement speed  
**Improvement:**
- **Increase speed when far from target** (>500px) - sprint to catch up
- **Normal speed when approaching** (200-500px)
- **Reduce speed when very close** (<200px) - avoid overshooting
- **Speed boost when target is moving away** - match or exceed their speed

```gdscript
var distance_to_target = npc.global_position.distance_to(target.global_position)
var target_speed = target.velocity.length() if target.has("velocity") else 0.0

if distance_to_target > 500.0:
    speed_multiplier = 1.5  # Sprint to catch up
elif distance_to_target < 200.0:
    speed_multiplier = 0.8  # Slow down to avoid overshooting
elif target_speed > npc.move_speed * 0.8:
    speed_multiplier = 1.2  # Match fast-moving targets
```

### 4. **Smart Search Pattern** ⭐ MEDIUM PRIORITY

**Current:** Random direction when no target found  
**Improvement:**
- **Search in expanding spiral** from land claim edge - systematic coverage
- **Prioritize known spawn areas** - remember where wild NPCs were found
- **Search perpendicular to last seen direction** - if NPC went north, search east/west
- **Group search zones** - divide area into quadrants and search systematically

```gdscript
# Spiral search pattern
var search_angle: float = 0.0  # Increment this for spiral
var search_radius: float = claim_radius * 1.5
var spiral_expansion: float = 50.0  # Expand radius each rotation

# Calculate spiral position
search_angle += 0.1
if search_angle >= TAU:
    search_angle = 0.0
    search_radius += spiral_expansion

var search_target = claim_pos + Vector2(cos(search_angle), sin(search_angle)) * search_radius
```

### 5. **Path Prediction & Interception** ⭐ MEDIUM PRIORITY

**Current:** Approaches current position (can cause reverse herding)  
**Improvement:**
- **Predict NPC position** based on velocity - intercept where they'll be
- **Calculate optimal intercept point** - minimize time to reach
- **Account for NPC wander patterns** - if wandering, predict wander target

```gdscript
# Simple interception prediction
var time_to_reach = distance_to_npc / npc.move_speed
var predicted_position = npc.global_position + npc.velocity * time_to_reach
var intercept_point = predicted_position - (direction_to_claim * 150.0)  # Ahead of predicted position
```

### 6. **Target Memory / Blacklist** ⭐ LOW PRIORITY !!NO MEMORY OF FAILED ATTEMPTS NOT USEFUL!!

**Current:** No memory of failed attempts  
**Improvement:**
- **Remember NPCs that keep breaking away** - temporary blacklist (30 seconds)
- **Skip NPCs that moved >200px away** in last 5 seconds - they're actively fleeing
- **Prefer NPCs that showed interest** - if they approached before, try again

```gdscript
var blacklisted_targets: Dictionary = {}  # NPC name -> timestamp
var blacklist_duration: float = 30.0  # seconds

# Before selecting target
if blacklisted_targets.has(npc_name):
    var blacklist_time = blacklisted_targets[npc_name]
    if current_time - blacklist_time < blacklist_duration:
        continue  # Skip blacklisted NPCs
```

### 7. **Detection Range Tuning** ⭐ LOW PRIORITY

**Current:** 1500px detection range (very wide)  
**Improvement:**
- **Dynamic detection range** - wider when no targets found, narrower when actively herding
- **Focus detection** - when herding one NPC, reduce range for others (avoid distraction)
- **Layer detection** - immediate detection at 300px, periodic scan at 1500px

```gdscript
var active_detection_range: float = detection_range
if target_woman:
    active_detection_range = herding_range * 2.0  # Focus on current target
else:
    active_detection_range = detection_range  # Wide search
```

### 8. **Multi-Target Handling** ⭐ LOW PRIORITY

**Current:** Single target at a time  
**Improvement:**
- **Maintain target list** - if multiple NPCs are herded, lead them as a group
- **Herd position management** - position self to lead all herded NPCs toward land claim
- **Group speed matching** - move at speed of slowest follower

### 9. **State Entry Conditions** ⭐ HIGH PRIORITY

**Current:** Only entered `herd_wildnpc` once in entire test  
**Improvement:**
- **More aggressive state entry** - enter state even if only 1 wild NPC detected (not multiple)
- **Reduce cooldown** between state entries
- **Check inventory less frequently** - don't exit just because inventory is slightly full
- **Allow entry from more states** - not just wander, but also idle/eat

### 10. **Movement Behavior While Herding** ⭐ MEDIUM PRIORITY

**Current:** Approaches from land claim direction (good)  
**Improvement:**
- **Lead behavior** - when NPC is herded, move directly toward land claim (don't approach NPC)
- **Slow down when NPC follows** - if distance < 200px and NPC is following, reduce speed
- **Pause briefly** if NPC stops following - wait 1 second before abandoning
- **Back up slightly** if too close - maintain 150-200px ideal distance

```gdscript
# When NPC is herded by us
if is_herded_by_us:
    var distance_to_follower = npc.global_position.distance_to(target_woman.global_position)
    
    if distance_to_follower < 150.0:
        # Too close - back up toward land claim
        var direction_away = (land_claim.global_position - npc.global_position).normalized()
        target_pos = npc.global_position + direction_away * 100.0
    elif distance_to_follower > 300.0:
        # Too far - slow down so follower can catch up
        speed_multiplier = 0.7
    else:
        # Good distance - lead toward land claim
        target_pos = land_claim.global_position
```

## Priority Implementation Order

1. **Target Persistence** (prevents switching targets too easily)
2. **Movement Speed Optimization** (faster herding)
3. **State Entry Conditions** (ensures caveman actually enters herd_wildnpc state)
4. **Smart Search Pattern** (finds targets faster)
5. **Path Prediction** (better interception)
6. **Smarter Target Selection** (prioritizes better targets)
7. **Movement Behavior While Herding** (maintains herd better)
8. **Detection Range Tuning** (optimizes performance)
9. **Target Memory** (avoids wasted effort)
10. **Multi-Target Handling** (advanced feature)

## Configuration Values to Consider

```gdscript
# Add to npc_config.gd or herd_wildnpc_state.gd
var target_stick_distance: float = 400.0  # Don't switch targets within this range
var min_distance_improvement: float = 100.0  # Only switch if significantly closer
var sprint_distance: float = 500.0  # Sprint when target is this far
var slow_down_distance: float = 200.0  # Slow down when this close
var speed_multiplier_sprint: float = 1.5
var speed_multiplier_normal: float = 1.0
var speed_multiplier_slow: float = 0.8
var target_grace_period: float = 2.0  # Seconds to keep target after slight range exit
var blacklist_duration: float = 30.0  # Seconds to remember failed targets
```

## Testing Metrics to Track

After implementing improvements, track:
- **Time to find first target** (should decrease)
- **Time to successfully herd NPC to land claim** (should decrease)
- **Number of target switches per successful herd** (should decrease)
- **Success rate** (NPCs herded / attempts)
- **Distance traveled** while herding (should decrease - more direct paths)
