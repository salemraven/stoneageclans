# Task System Implementation Report
**Date:** 2026-01-27  
**Status:** Partially Implemented - Jobs Not Being Pulled

---

## Executive Summary

The Task System infrastructure (Steps 12-17) is **implemented** but **not functioning**. NPCs are not pulling jobs from buildings. The core issue: `generate_job()` returns `null` when called, preventing job assignment.

**Key Finding:** Women remain in `reproduction` state (priority 8.0) instead of entering `work_at_building` state, even though `work_at_building` should have priority 9.0 when jobs are available.

---

## What's Supposed to Happen (Design Intent)

Based on `Task_system.md`:

### Execution Flow
1. **NPC in WORKING mode** enters `work_at_building` state
2. **State checks for jobs:** `_has_available_job()` queries buildings via `generate_job(worker)`
3. **Building generates job:** Returns a `Job` (ordered list of tasks) if work is available
4. **NPC pulls job:** Assigns job to `TaskRunner` component
5. **TaskRunner executes:** Runs tasks sequentially (PickUp → MoveTo → DropOff → Occupy → PickUp → MoveTo → DropOff)
6. **Job completes:** NPC becomes idle, can pull another job

### Expected Job Sequence (Oven)
```
1. PickUp Wood from land claim
2. MoveTo oven
3. DropOff Wood to oven
4. PickUp Grain from land claim
5. MoveTo oven
6. DropOff Grain to oven
7. Occupy oven (wait for production)
8. PickUp Bread from oven
9. MoveTo land claim
10. DropOff Bread to land claim
```

### State Priority System
- `work_at_building` priority: **7.0** (normal), **9.0** (when job available)
- `reproduction` priority: **8.0**
- **Expected:** When job available, `work_at_building` (9.0) should beat `reproduction` (8.0)

---

## What's Actually Happening

### ✅ Working Components

1. **TaskRunner Created:** All 4 women have TaskRunner components created successfully
   ```
   Task System: Created TaskRunner component for [NPC_NAME]
   ```

2. **Job Generation Called:** `generate_job()` is being called repeatedly
   ```
   DEBUG generate_job: Building Oven checking for job (type: 14, occupied: false, clan: Test)
   ```

3. **State System Active:** FSM is evaluating states, `can_enter()` and `get_priority()` are being called

4. **Task Scripts Loaded:** All task scripts (PickUp, MoveTo, DropOff, Occupy) load at runtime

### ❌ Broken Components

1. **Jobs Not Generated:** `generate_job()` always returns `null`
   ```
   DEBUG: [NPC_NAME] - generate_job() returned null for Oven (occupied: false, has_production: yes)
   ```

2. **Women Stuck in Reproduction:** All women remain in `reproduction` state
   ```
   WOMAN: [NAME] | State: reproduction | Clan: Test
   ```

3. **No Jobs Pulled:** Zero instances of "pulled job" or "Assigned job" in logs

4. **No Task Execution:** No task start/completion logs

---

## Root Cause Analysis

### Primary Issue: `generate_job()` Returns Null

The function fails at one of these checks:

1. **Building type check** (line 209): Only ovens generate jobs ✓ (passing)
2. **Occupied check** (line 213): Building must be unoccupied ✓ (passing - logs show `occupied: false`)
3. **Clan match** (line 217): Worker must be in same clan ✓ (passing - both are "Test")
4. **Production component** (line 221): Must exist ✓ (passing - logs show `has_production: yes`)
5. **Recipe check** (line 231): Recipe must exist ❓ (unknown - no debug log)
6. **Land claim find** (line 235): `_find_land_claim()` must return valid claim ❓ (likely failing)
7. **Input availability** (line 250): Land claim must have required inputs ❓ (likely failing)
8. **Output space** (line 268): Building must have space for output ✓ (likely passing)

### Most Likely Failures

#### 1. Land Claim Not Found (`_find_land_claim()`) - VERIFIED NOT THE ISSUE

**Code Location:** `scripts/buildings/building_base.gd:329-350`

**Logic:**
- Searches `get_nodes_in_group("land_claims")`
- Filters by `clan_name` match
- Checks if building is within `land_claim.radius`

**Verification:**
- ✅ Land claim IS added to "land_claims" group (`scripts/land_claim.gd:48`)
- ✅ Land claim radius is 400px (`scripts/land_claim.gd:5`)
- ✅ Ovens are 150px from land claim center (well within radius)
- ✅ Both have clan_name "Test"

**Conclusion:** Land claim finding should work. Issue must be elsewhere.

**Debug Evidence:**
- No "DEBUG generate_job: No land claim found" messages in logs
- But also no "DEBUG generate_job: Land claim missing [resource]" messages
- Suggests function might be returning `null` silently or failing earlier, OR debug logs aren't being hit

#### 2. Missing Input Resources

**Code Location:** `scripts/buildings/building_base.gd:240-260`

**Logic:**
- Checks if land claim inventory has `Wood x1` and `Grain x1`
- Test environment should have `Wood x10, Grain x10`

**Potential Issues:**
- Land claim inventory not initialized
- Inventory exists but `has_item()` check fails
- Resource type enum mismatch

**Debug Evidence:**
- Should see "DEBUG generate_job: Land claim missing..." if this fails
- Not seeing these messages suggests failure happens earlier

#### 3. Recipe Not Found

**Code Location:** `scripts/buildings/building_base.gd:225-232`

**Logic:**
- Gets recipe from `production_component.recipe`
- Recipe should be set in `_setup_oven()`

**Potential Issues:**
- Recipe not set on production component
- Recipe property name mismatch
- Recipe is empty dictionary

**Debug Evidence:**
- No explicit debug log for this check
- Would fail silently if recipe is empty

---

## Code Flow Analysis

### State Evaluation Flow

```
FSM evaluates states
  ↓
work_at_building_state.can_enter()
  ↓
_has_available_job()
  ↓
Loop through buildings in "buildings" group
  ↓
building.generate_job(npc)
  ↓
[RETURNS NULL] ❌
  ↓
can_enter() returns false
  ↓
State not entered
```

### Priority Evaluation Flow

```
FSM evaluates priorities
  ↓
work_at_building_state.get_priority()
  ↓
_has_available_job()  [called again]
  ↓
generate_job() returns null
  ↓
get_priority() returns 7.0 (not 9.0)
  ↓
reproduction (8.0) beats work_at_building (7.0)
  ↓
NPC stays in reproduction state
```

**Problem:** `_has_available_job()` is called twice (once in `can_enter()`, once in `get_priority()`), and both times `generate_job()` returns null, so priority never increases to 9.0.

---

## Implementation Status by Step

| Step | Component | Status | Notes |
|------|-----------|--------|-------|
| 12 | Task base class | ✅ Complete | `task.gd` with start/tick/cancel |
| 13 | TaskRunner | ✅ Complete | Component created, tick loop works |
| 14 | Job class | ✅ Complete | Data container for task list |
| 15 | Concrete tasks | ✅ Complete | MoveTo, PickUp, DropOff, Wait implemented |
| 16 | Building generate_job | ⚠️ Partial | Function exists but returns null |
| 16 | OccupyTask | ✅ Complete | Task implemented |
| 17 | NPC-pull wiring | ⚠️ Partial | Logic exists but jobs never pulled |
| 18 | Interrupt wiring | ❌ Not Started | Mode switch/agro cancellation |

---

## Specific Code Issues

### Issue 1: `generate_job()` Silent Failures

**File:** `scripts/buildings/building_base.gd:201-326`

**Problem:** Function has multiple early returns with minimal logging. When it returns null, we don't know which check failed.

**Fix Needed:** Add debug logging at each return point (already partially done, but some checks still silent).

### Issue 2: `_find_land_claim()` May Fail

**File:** `scripts/buildings/building_base.gd:329-350`

**Problem:** Function searches by group "land_claims" and checks radius. If land claim isn't in group or building is outside radius, returns null.

**Potential Issues:**
- Land claim might not be added to "land_claims" group
- Building might be outside land claim radius (test setup places oven 150px from land claim)
- Land claim radius might be too small

**Fix Needed:** 
- Verify land claim is in "land_claims" group
- Check if building is within radius
- Add debug logging to `_find_land_claim()`

### Issue 3: State Priority Not Working

**File:** `scripts/npc/states/work_at_building_state.gd:84-88`

**Problem:** `get_priority()` calls `_has_available_job()` which calls `generate_job()`. Since `generate_job()` returns null, priority stays at 7.0 instead of 9.0.

**Fix Needed:** Fix `generate_job()` to return valid jobs, then priority will work correctly.

### Issue 4: Task Script Loading

**File:** `scripts/buildings/building_base.gd:4-9, 50-60`

**Problem:** Task scripts are loaded at runtime in `_load_task_scripts()`. If any script fails to load, `generate_job()` will fail when creating tasks.

**Current Status:** Scripts appear to load (no errors), but need verification.

---

## Test Environment Analysis

### Setup (from `main.gd:_setup_task_system_test_environment()`)

- **Land Claim:** Created at `player.position + Vector2(200, 0)`
- **Oven 1:** At `land_claim.position + Vector2(150, -100)` (350, -100)
- **Oven 2:** At `land_claim.position + Vector2(150, 100)` (350, 100)
- **Resources:** Land claim pre-populated with `Wood x10, Grain x10`
- **Women:** 4 women, all assigned to clan "Test"

### Potential Issues

1. **Distance Check:** Ovens are 150px from land claim center. Need to verify land claim radius is >= 150px.

2. **Group Membership:** Land claim must be in "land_claims" group. Need to verify `add_to_group("land_claims")` is called.

3. **Inventory Initialization:** Land claim inventory must be created before resources are added. Code shows `inventory = InventoryData.new(...)` before `add_item()`, so this should be fine.

---

## Recommended Fixes (Priority Order)

### Fix 1: Add Comprehensive Debug Logging to `generate_job()`

**Priority:** HIGH  
**Effort:** Low

Add debug logs at every return point to identify which check fails:

```gdscript
# After each check that could fail:
if building_type != ResourceData.ResourceType.OVEN:
    print("DEBUG generate_job: Not an oven (type: %s)" % building_type)
    return null

if is_occupied():
    print("DEBUG generate_job: Building already occupied")
    return null

# ... etc for all checks
```

### Fix 2: Verify Land Claim Group and Radius

**Priority:** HIGH  
**Effort:** Low

1. Check if land claim is added to "land_claims" group in `land_claim.gd`
2. Check land claim radius value
3. Verify building is within radius (distance <= radius)
4. Add debug logging to `_find_land_claim()`:

```gdscript
func _find_land_claim() -> LandClaim:
    var land_claims = get_tree().get_nodes_in_group("land_claims")
    print("DEBUG _find_land_claim: Found %d land claims in group" % land_claims.size())
    
    for claim in land_claims:
        var distance = global_position.distance_to(lc.global_position)
        print("DEBUG _find_land_claim: Claim '%s' (clan: %s) at distance %.1f, radius: %.1f" % [
            lc.clan_name, lc.clan_name, distance, lc.radius
        ])
        # ... rest of logic
```

### Fix 3: Verify Recipe Setup

**Priority:** MEDIUM  
**Effort:** Low

Check if production component has recipe set:

```gdscript
# In generate_job(), after getting production_component:
if "recipe" in production_component:
    var recipe_value = production_component.get("recipe")
    print("DEBUG generate_job: Recipe found: %s" % recipe_value)
    if recipe_value is Dictionary:
        recipe = recipe_value
        print("DEBUG generate_job: Recipe is valid dict with %d inputs" % recipe.get("inputs", []).size())
else:
    print("DEBUG generate_job: Production component has no 'recipe' property")
```

### Fix 4: Verify Inventory State

**Priority:** MEDIUM  
**Effort:** Low

Add logging to verify land claim inventory state:

```gdscript
# In generate_job(), after finding land claim:
if land_claim.inventory:
    print("DEBUG generate_job: Land claim inventory exists, has %d items" % land_claim.inventory.get_item_count())
    for input in inputs:
        var count = land_claim.inventory.get_count(input_type)
        print("DEBUG generate_job: Land claim has %s x%d (needs x%d)" % [
            ResourceData.get_resource_name(input_type), count, input_quantity
        ])
else:
    print("DEBUG generate_job: Land claim has no inventory!")
```

---

## Next Steps

1. **Immediate:** Run test with enhanced debug logging to identify exact failure point
2. **Short-term:** Fix the identified issue (likely land claim finding or inventory check)
3. **Medium-term:** Complete Step 18 (interrupt wiring)
4. **Long-term:** Optimize job pulling (caching, throttling per design doc)

---

## Files Modified (Current Implementation)

- `scripts/ai/tasks/task.gd` - Base task class
- `scripts/ai/task_runner.gd` - TaskRunner component
- `scripts/ai/jobs/job.gd` - Job data container
- `scripts/ai/tasks/move_to_task.gd` - Movement task
- `scripts/ai/tasks/pick_up_task.gd` - Pickup task
- `scripts/ai/tasks/drop_off_task.gd` - Dropoff task
- `scripts/ai/tasks/wait_task.gd` - Wait task
- `scripts/ai/tasks/occupy_task.gd` - Building occupation task
- `scripts/buildings/building_base.gd` - `generate_job()` implementation
- `scripts/npc/npc_base.gd` - TaskRunner component creation
- `scripts/npc/states/work_at_building_state.gd` - Job-pull logic

---

## Conclusion

The Task System architecture is **correctly implemented** according to the design document. The failure is in the **execution path**: `generate_job()` returns null, preventing jobs from being created and assigned. 

**Key Findings:**
- ✅ Infrastructure is correct (TaskRunner, Job, Tasks all implemented)
- ✅ Land claim setup is correct (group membership, radius, resources)
- ❌ `generate_job()` returns null but we don't know which check fails
- ❌ State priority system can't work because jobs never exist

**Next Action:** Add comprehensive debug logging to `generate_job()` to identify the exact failure point. Most likely candidates:
1. Recipe not set on production component
2. Inventory check failing silently
3. Task script loading issue (though no errors seen)

**Estimated Fix Time:** 1-2 hours (debugging + fix)  
**Blocker:** Cannot proceed to Step 18 until jobs are being pulled successfully
