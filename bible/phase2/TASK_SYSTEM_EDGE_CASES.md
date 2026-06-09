# Task System Edge Case Fixes
**Date:** 2026-01-27  
**Status:** Fixed

---

## Edge Cases Addressed

### ✅ Edge Case 1: Reservation Starvation

**Problem:** If a woman reserves a job but gets interrupted (aggro, role change, follow) before completing it, the reservation might not be cleared, preventing other women from getting jobs.

**Fixes Applied:**

1. **TaskRunner cancellation clears reservations:**
   - `cancel_current_job()` now clears both `job_reserved_by` and `transport_reserved_by`
   - `_clear_job()` also clears both reservations on completion

2. **State exit clears reservations:**
   - `work_at_building_state.exit()` now checks if NPC has reservations and clears them
   - Handles case where NPC exits state before job is assigned

3. **Building clear_occupied clears reservations:**
   - When woman leaves building, both reservations are cleared
   - Prevents stale reservations from dead NPCs

**Test Scenario:**
- Start production job
- Interrupt worker mid-job (change state, agro, etc.)
- Confirm: `job_reserved_by` is cleared
- Another woman can pull job

---

### ✅ Edge Case 2: Transport Job vs Production Job Conflict

**Problem:** When an oven is occupied and has bread, two women might query jobs simultaneously and both get transport jobs, potentially duplicating bread.

**Fixes Applied:**

1. **Transport job reservation:**
   - Added `transport_reserved_by` to track which NPC is transporting bread
   - `_generate_transport_job()` reserves the transport job for the worker
   - `has_available_job()` checks if transport is already reserved

2. **Bread pickup clears reservation:**
   - `PickUpTask._tick_impl()` clears `transport_reserved_by` when bread is picked up
   - Prevents duplicate transport jobs for the same bread

3. **Reservation clearing:**
   - Transport reservations cleared on job cancel/completion
   - Transport reservations cleared when woman leaves building

**Test Scenario:**
- Oven occupied with bread
- Two women query jobs simultaneously
- Expected: Only one transport job generated
- Bread count decrements correctly
- Second woman waits or finds another job

---

## Additional Safety Fixes

### ✅ Production Mid-Craft Cancellation

**Problem:** If a woman leaves during production, bread might appear later even though she's gone.

**Fix Applied:**
- `clear_occupied()` now resets production component state:
  - `craft_timer = 0.0`
  - `is_crafting = false`
- Building turns off immediately
- Prevents "ghost bread" appearing after woman leaves

**Test Scenario:**
- Woman starts production
- Woman leaves during production
- Building must stop
- No bread should appear later

---

## Implementation Details

### Reservation System

**Production Jobs:**
- Reserved in `generate_job()` when not occupied
- Cleared on job cancel/completion
- Cleared on state exit
- Cleared when building is cleared

**Transport Jobs:**
- Reserved in `_generate_transport_job()` when occupied
- Cleared when bread is picked up (in PickUpTask)
- Cleared on job cancel/completion
- Cleared when building is cleared

### State Exit Handling

`work_at_building_state.exit()` now:
1. Clears building occupation
2. Shows NPC sprite
3. Cancels active job (if any)
4. Clears any reservations the NPC might have

This ensures no stale reservations remain when NPC leaves the state.

---

## Testing Checklist

### Edge Case 1 Tests
- [ ] Start production job
- [ ] Interrupt worker (change state)
- [ ] Verify `job_reserved_by` is null
- [ ] Verify another woman can pull job
- [ ] Test with agro interruption
- [ ] Test with follow command
- [ ] Test with NPC death

### Edge Case 2 Tests
- [ ] Oven occupied with bread
- [ ] Two women query simultaneously
- [ ] Verify only one transport job generated
- [ ] Verify bread count decrements by 1
- [ ] Verify second woman finds different job
- [ ] Test multiple bread items (should generate multiple transport jobs sequentially)

### Production Cancellation Tests
- [ ] Woman starts production
- [ ] Woman leaves during production
- [ ] Verify building turns off
- [ ] Verify no bread appears later
- [ ] Verify craft_timer is reset
- [ ] Verify is_crafting is false

---

## Code Locations

**Reservation Properties:**
- `scripts/buildings/building_base.gd:24-25`

**Reservation Clearing:**
- `scripts/ai/task_runner.gd:92-105` (cancel_current_job)
- `scripts/ai/task_runner.gd:107-120` (_clear_job)
- `scripts/npc/states/work_at_building_state.gd:14-45` (exit)
- `scripts/buildings/building_base.gd:184-199` (clear_occupied)

**Transport Reservation:**
- `scripts/buildings/building_base.gd:416-450` (_generate_transport_job)
- `scripts/ai/tasks/pick_up_task.gd:68-78` (clears on pickup)

**Production Cancellation:**
- `scripts/buildings/building_base.gd:184-199` (clear_occupied)

---

## Future Improvements (Optional)

As suggested, consider formalizing job types:

```gdscript
enum JobType { NONE, PRODUCTION, TRANSPORT }

func get_job_type(worker) -> JobType:
    # Determine job type based on building state
    if is_occupied():
        if has_bread_to_transport():
            return JobType.TRANSPORT
        return JobType.NONE
    else:
        if can_produce():
            return JobType.PRODUCTION
        return JobType.NONE
```

This would improve clarity as more buildings and job types are added.

---

**All edge cases have been addressed and are ready for testing.**
