# Reverse Herding Safety Check Status
**Generated:** January 11, 2026

## Safety Check Status: ✅ **ACTIVE**

**Location:** `scripts/npc/states/herd_wildnpc_state.gd` lines 498-511

### Current Implementation

```gdscript
# SAFETY CHECK: Detect and stop reverse herding
# Track distance to claim - if it increases significantly, reverse herding detected
var last_distance_key = "last_distance_to_claim_leading"
if npc.has_meta(last_distance_key):
    var last_distance: float = npc.get_meta(last_distance_key)
    var distance_increase: float = current_distance - last_distance
    
    # If distance increased significantly (>100px), reverse herding detected
    if distance_increase > 100.0 and current_distance > 500.0:
        print("⚠️ REVERSE_HERDING_DETECTED: %s moving away from claim (%.1fpx -> %.1fpx, +%.1fpx) - forcing correction" % [
            npc.npc_name, last_distance, current_distance, distance_increase
        ])
        # Force immediate correction - lead directly to claim
        npc.steering_agent.set_target_position(claim_position)

# Store current distance for next frame comparison
npc.set_meta(last_distance_key, current_distance)
```

### How It Works

1. **Tracks Distance:** Stores last distance to claim in meta `"last_distance_to_claim_leading"`
2. **Detects Increase:** Compares current distance to last distance
3. **Triggers:** If distance increased >100px AND current distance >500px
4. **Corrects:** Forces target to claim position when detected

### Conditions for Safety Check to Run

The safety check ONLY runs when:
- ✅ `should_lead` is true (line 487)
- ✅ `land_claim` exists (line 493)
- ✅ Caveman is in `herd_wildnpc` state and leading

**Potential Issue:** If `should_lead` becomes false for any reason, the safety check won't run, and reverse herding could occur.

### Status Check

**Safety Check:** ✅ **ACTIVE** - No comments disabling it, no conditional that would turn it off

**Trigger Conditions:**
- ✅ Distance increase >100px: **ACTIVE**
- ✅ Current distance >500px: **ACTIVE**
- ✅ Correction force: **ACTIVE**

### Why It Might Not Be Working

**Issue 1: Only Runs When Leading**
- Safety check is inside `if should_lead:` block (line 487)
- If `should_lead` is false, check doesn't run
- Reverse herding could occur before leading logic executes

**Issue 2: Threshold May Be Too High**
- Requires >100px increase AND >500px current distance
- May not catch smaller oscillations (<100px)
- May not catch reverse herding when close to claim (<500px)

**Issue 3: Reactive, Not Preventative**
- Only detects AFTER reverse herding happens
- Corrects it, but doesn't prevent it
- May not prevent yo-yo oscillation (oscillating back and forth within threshold)

### Test Results

**From Test 3 Log:**
- Need to check if `REVERSE_HERDING_DETECTED` messages appeared
- If yes: Safety check is working but not preventing all cases
- If no: Safety check may not be triggering (threshold too high or not reaching that code path)

---

## Answer to Your Question

**Yes, we created a safety check to stop reverse herding.**

**No, it did NOT get shut off - it's still active in the code.**

**However:**
- ✅ Safety check exists and is active
- ⚠️ Only runs when `should_lead` is true
- ⚠️ May have threshold issues (>100px AND >500px may be too restrictive)
- ⚠️ Reactive (detects after it happens) rather than preventative
- ⚠️ May not prevent yo-yo oscillation if oscillation is <100px per frame

**The safety check is active, but it may not be catching all cases of yo-yo oscillation because:**
1. Oscillation might be <100px per frame (below threshold)
2. Yo-yo might happen when `should_lead` is false (check doesn't run)
3. Reactive correction may not break the feedback loop causing continuous oscillation

---

## Recommendations

1. **Lower thresholds** - Make detection more sensitive (<100px increase)
2. **Remove distance requirement** - Remove >500px requirement to catch close oscillations
3. **Add preventative measures** - Fix the root cause (feedback loop) instead of just detecting it
4. **Check if safety check is triggering** - Look for `REVERSE_HERDING_DETECTED` messages in logs
