# Reverse Herding Safety Checks Analysis

## Current Safety Mechanisms

### 1. Leading Logic (Lines 407-430)
**What it does:**
- When target is herded (`should_lead` is true), ALWAYS leads to claim: `set_target_position(land_claim.global_position)`
- This is the primary prevention mechanism

**Limitations:**
- Only works if `should_lead` is true
- If `should_lead` is false, falls through to approach logic which can cause reverse herding

### 2. Close Target Check (Lines 420-423)
**What it does:**
- When target is very close (<50px), leads to claim immediately
- Prevents reverse herding when very close

**Limitations:**
- Only applies when target is <50px
- Doesn't detect reverse herding that's already happening

### 3. Movement Away Check (Lines 435-447)
**What it does:**
- Checks if target is moving away from claim rapidly (>100px/s)
- Only applies when caveman is near claim (<500px)
- Leads to claim instead of following

**Limitations:**
- Only checks target movement, not caveman movement
- Only applies when caveman is near claim
- Doesn't detect if caveman itself is moving away

## Missing Safety Mechanisms

### ❌ No Detection of Reverse Herding
- No check to detect if caveman is moving away from claim after herding
- No validation that distance to claim is decreasing when leading
- No safety break if reverse herding is detected

### ❌ No Distance-Based Safety
- No check if caveman's distance to claim is increasing when it should be decreasing
- No maximum distance limit when leading
- No validation that movement is actually toward the claim

### ❌ No Fail-Safe Break
- No mechanism to detect and break reverse herding if it occurs
- No timeout or distance check that would invalidate the herd if reverse herding persists

## Recommended Safety Checks

### Option 1: Distance Validation When Leading
Check if caveman's distance to claim is increasing when it should be decreasing:

```gdscript
if should_lead and land_claim:
    var current_distance = npc.global_position.distance_to(land_claim.global_position)
    var last_distance = npc.get_meta("last_distance_to_claim") if npc.has_meta("last_distance_to_claim") else current_distance
    
    # If distance increased significantly, reverse herding detected
    if current_distance > last_distance + 50.0:  # Moved 50px+ away
        print("⚠️ REVERSE_HERDING_DETECTED: %s moving away from claim (%.1fpx -> %.1fpx)" % [
            npc.npc_name, last_distance, current_distance
        ])
        # Force leading to claim
        npc.steering_agent.set_target_position(land_claim.global_position)
    
    npc.set_meta("last_distance_to_claim", current_distance)
```

### Option 2: Maximum Distance Safety
If caveman gets too far from claim when leading, break the herd:

```gdscript
if should_lead and land_claim:
    var distance_to_claim = npc.global_position.distance_to(land_claim.global_position)
    if distance_to_claim > 2000.0:  # Too far from claim
        print("⚠️ REVERSE_HERDING_DETECTED: %s too far from claim (%.1fpx) - breaking herd" % [
            npc.npc_name, distance_to_claim
        ])
        # Break the herd
        target_woman.is_herded = false
        target_woman.herder = null
        return
```

### Option 3: Direction Validation
Check if caveman is actually moving toward the claim:

```gdscript
if should_lead and land_claim:
    var direction_to_claim = (land_claim.global_position - npc.global_position).normalized()
    var velocity = npc.velocity if "velocity" in npc else Vector2.ZERO
    var moving_toward_claim = velocity.dot(direction_to_claim) > 0
    
    if not moving_toward_claim and velocity.length() > 50.0:  # Moving but not toward claim
        print("⚠️ REVERSE_HERDING_DETECTED: %s not moving toward claim" % npc.npc_name)
        # Force leading to claim
        npc.steering_agent.set_target_position(land_claim.global_position)
```

## Recommended Implementation

**Combine Option 1 + Option 3**: Distance validation + direction validation

This would:
1. Track distance to claim when leading
2. Detect if distance is increasing
3. Validate that velocity is toward claim
4. Force correction if reverse herding detected

This provides both detection and prevention.
