# Phase 2 Cleanup Plan

## Overview
This document outlines cleanup tasks to fix integration issues between the task system, FSM states, and other NPC systems (defend, combat, following, etc.).

## Priority Order

### Phase 1: Critical Integration Fixes (Do First)
These fix bugs where systems conflict and cause incorrect behavior.

### Phase 2: Code Consolidation (Do Second)
These reduce duplication and make the codebase more maintainable.

### Phase 3: Documentation & Polish (Do Last)
These improve clarity and prevent future issues.

---

## Phase 1: Critical Integration Fixes

### 1.1 Add Helper Functions to `base_state.gd`
**File:** `scripts/npc/states/base_state.gd`

**Add these helper functions:**
```gdscript
# Check if NPC is defending
func _is_defending() -> bool:
	if not npc:
		return false
	var defend_target = npc.get("defend_target")
	return defend_target != null and is_instance_valid(defend_target)

# Check if NPC is in combat
func _is_in_combat() -> bool:
	if not npc:
		return false
	var combat_target = npc.get("combat_target")
	return combat_target != null and is_instance_valid(combat_target)

# Check if NPC is following (ordered follow)
func _is_following() -> bool:
	if not npc:
		return false
	return npc.get("follow_is_ordered") == true

# Cancel tasks if active (standardized pattern)
func _cancel_tasks_if_active() -> void:
	if not npc or not npc.task_runner:
		return
	if npc.task_runner.has_method("has_job") and npc.task_runner.has_job():
		npc.task_runner.cancel_current_job()
```

**Why:** Eliminates code duplication and ensures consistent checks across all states.

---

### 1.2 Fix `gather_state.gd` - Add `follow_is_ordered` Check
**File:** `scripts/npc/states/gather_state.gd`

**Changes:**
- In `can_enter()`: Add check for `_is_following()` - return `false` if following
- In `update()`: Add check for `_is_following()` - exit to herd state if following
- Replace duplicate defend/combat checks with `_is_defending()` and `_is_in_combat()` calls

**Why:** NPCs shouldn't gather while following the player.

---

### 1.3 Fix `wander_state.gd` - Add `follow_is_ordered` Check
**File:** `scripts/npc/states/wander_state.gd`

**Changes:**
- In `can_enter()`: Add check for `_is_following()` - return `false` if following
- In `update()`: Add check for `_is_following()` - exit to herd state if following
- Add task cancellation during deposit movement (before setting steering target)
- Ensure speed multiplier is restored if state is interrupted

**Why:** NPCs shouldn't wander while following, and deposit movement shouldn't conflict with tasks.

---

### 1.4 Fix `agro_state.gd` - Add State Blocking Checks
**File:** `scripts/npc/states/agro_state.gd`

**Changes:**
- In `can_enter()`: Add check for `_is_following()` - return `false` if following
- In `can_enter()`: Add check for `_is_defending()` - return `false` if defending
- In `can_enter()`: Add check for `_is_in_combat()` - return `false` if in combat
- Replace duplicate task cancellation code with `_cancel_tasks_if_active()` call

**Why:** Agro shouldn't trigger while following/defending/combatting.

---

### 1.5 Fix `defend_state.gd` - Add `follow_is_ordered` Check in Update
**File:** `scripts/npc/states/defend_state.gd`

**Changes:**
- In `update()`: Add check for `_is_following()` - exit to herd state if following
- Replace duplicate task cancellation code with `_cancel_tasks_if_active()` call

**Why:** Defenders shouldn't defend while following the player.

---

### 1.6 Fix `occupy_building_state.gd` - Continuous Task Cancellation
**File:** `scripts/npc/states/occupy_building_state.gd`

**Changes:**
- In `update()`: Call `_cancel_tasks_if_active()` every frame (not just once)
- Replace duplicate defend/combat checks with helper function calls

**Why:** Building occupation should continuously override task movement.

---

### 1.7 Fix `work_at_building_state.gd` - Continuous Task Cancellation
**File:** `scripts/npc/states/work_at_building_state.gd`

**Changes:**
- In `update()`: Call `_cancel_tasks_if_active()` every frame (not just once)
- Replace duplicate defend/combat checks with helper function calls

**Why:** Building work should continuously override task movement.

---

### 1.8 Fix `herd_state.gd` - Use Helper Functions
**File:** `scripts/npc/states/herd_state.gd`

**Changes:**
- Replace duplicate task cancellation code with `_cancel_tasks_if_active()` call
- In `can_enter()`: Replace duplicate defend/combat checks with helper function calls

**Why:** Consistency and code reduction.

---

### 1.9 Fix `combat_state.gd` - Use Helper Functions
**File:** `scripts/npc/states/combat_state.gd`

**Changes:**
- Replace duplicate task cancellation code with `_cancel_tasks_if_active()` call

**Why:** Consistency and code reduction.

---

### 1.10 Fix `reproduction_state.gd` - Use Helper Functions
**File:** `scripts/npc/states/reproduction_state.gd`

**Changes:**
- Replace duplicate defend/combat/following checks with helper function calls

**Why:** Consistency and code reduction.

---

## Phase 2: Code Consolidation

### 2.1 Standardize State Exit Cleanup
**Files:** All state files

**Pattern to implement:**
```gdscript
func exit() -> void:
	_cancel_tasks_if_active()
	# State-specific cleanup
```

**States to update:**
- `gather_state.gd` - Cancel tasks on exit
- `wander_state.gd` - Restore speed multiplier, cancel tasks
- `occupy_building_state.gd` - Clear building reservations
- `work_at_building_state.gd` - Clear building reservations
- All other states - Add task cancellation if missing

**Why:** Ensures proper cleanup when states are interrupted.

---

### 2.2 Standardize State Transition Pattern
**Files:** All state files

**Decision:** When should states use `fsm.change_state()` vs returning `false` from `can_enter()`?

**Rule:**
- Use `fsm.change_state()` in `update()` when conditions change during state execution
- Use `return false` in `can_enter()` to prevent entering a state
- Always check conditions in both places for critical states (defend, combat, following)

**States to review:**
- `gather_state.gd` - Currently checks in both places (good, but redundant)
- `work_at_building_state.gd` - Only checks in `update()` (should also check in `can_enter()`)
- `occupy_building_state.gd` - Only checks in `can_enter()` (should also check in `update()`)

---

### 2.3 Consolidate Task Cancellation Logic
**Files:** All state files

**Pattern:**
- States that control movement directly (defend, combat, herd, occupy, work) should cancel tasks every frame
- States that delegate to tasks (gather with jobs) should cancel tasks on enter/exit
- All states should cancel tasks on exit

**Implementation:**
- Use `_cancel_tasks_if_active()` helper function everywhere
- Document which states need continuous cancellation vs one-time

---

### 2.4 Fix Steering Agent Override Pattern
**Files:** States that use `steering_agent`

**Rule:** If a state sets `steering_agent` target, it must:
1. Cancel tasks every frame (if state controls movement)
2. Set steering target every frame (to override task movement)

**States to fix:**
- `occupy_building_state.gd` - Sets target but doesn't cancel tasks every frame
- `work_at_building_state.gd` - Sets target but doesn't cancel tasks every frame
- `wander_state.gd` - Deposit movement doesn't cancel tasks

---

## Phase 3: Documentation & Polish

### 3.1 Document State Priority Hierarchy
**File:** `scripts/npc/states/base_state.gd` or new `STATE_PRIORITIES.md`

**Document:**
```
State Priority Hierarchy (highest to lowest):
- Combat: 12.0 (highest - life or death)
- Herd Catchup: 15.0 (when too far from leader)
- Work (active job): 10.0 (don't interrupt active work)
- Herd: 11.0 (following leader)
- Defend: 8.0 (protecting territory)
- Reproduction: 8.0 (tie with defend - context dependent)
- Work (available job): 9.0 (when job available)
- Occupy Building: 7.5 (moving to building)
- Build: 9.5 (when has 8+ items)
- Agro: 10.0-12.0 (varies by context)
- Gather (inventory full): 5.0 (need to deposit)
- Gather: 3.0 (normal gathering)
- Wander: 0.5-3.0 (varies by context)
```

**Why:** Makes priority decisions clear and prevents conflicts.

---

### 3.2 Document State Blocking Rules
**File:** New `STATE_BLOCKING_RULES.md` or in `base_state.gd`

**Document:**
```
State Blocking Rules:
- Defend blocks: Gather, Work, Occupy, Reproduction, Wander
- Combat blocks: All states except Defend
- Following (follow_is_ordered) blocks: Gather, Work, Occupy, Reproduction, Defend, Wander
- Herd (is_herded) blocks: Wander (already implemented)
```

**Why:** Makes it clear which states should prevent which other states.

---

### 3.3 Reduce Excessive Logging
**File:** `scripts/npc/states/gather_state.gd`

**Changes:**
- Reduce clansman gather logging from INFO to DEBUG
- Only log state transitions, not every evaluation
- Throttle logging to once per second max

**Why:** Reduces console spam while keeping useful debugging info.

---

### 3.4 Add State Validation Checks
**Files:** States that track targets

**Add validation:**
- `herd_state.gd` - Validate `herder` in `can_enter()` (not just `update()`)
- `occupy_building_state.gd` - Validate building still available in `update()`
- `work_at_building_state.gd` - Validate building still exists in `update()`

**Why:** Prevents states from entering with invalid targets.

---

### 3.5 Fix Priority Edge Cases
**Files:** Multiple state files

**Issues:**
1. `reproduction_state.gd` (8.0) vs `defend_state.gd` (8.0) - tie-breaker needed
2. `work_at_building_state.gd` (10.0 with active job) vs `combat_state.gd` (12.0) - should combat interrupt work?
3. `herd_state.gd` catchup (15.0) vs `defend_state.gd` (8.0) - should following beat defending?

**Decisions needed:**
- Should combat interrupt active work? (Probably yes - life over work)
- Should following beat defending? (Probably yes - player orders override auto-defense)
- Should reproduction beat defend? (Probably no - defense is more urgent)

**Implementation:**
- Adjust priorities based on decisions
- Add comments explaining priority choices

---

## Implementation Checklist

### Phase 1: Critical Fixes
- [ ] 1.1 Add helper functions to `base_state.gd`
- [ ] 1.2 Fix `gather_state.gd` - add `follow_is_ordered` check
- [ ] 1.3 Fix `wander_state.gd` - add `follow_is_ordered` check
- [ ] 1.4 Fix `agro_state.gd` - add state blocking checks
- [ ] 1.5 Fix `defend_state.gd` - add `follow_is_ordered` check in update
- [ ] 1.6 Fix `occupy_building_state.gd` - continuous task cancellation
- [ ] 1.7 Fix `work_at_building_state.gd` - continuous task cancellation
- [ ] 1.8 Fix `herd_state.gd` - use helper functions
- [ ] 1.9 Fix `combat_state.gd` - use helper functions
- [ ] 1.10 Fix `reproduction_state.gd` - use helper functions

### Phase 2: Code Consolidation
- [ ] 2.1 Standardize state exit cleanup
- [ ] 2.2 Standardize state transition pattern
- [ ] 2.3 Consolidate task cancellation logic
- [ ] 2.4 Fix steering agent override pattern

### Phase 3: Documentation & Polish
- [ ] 3.1 Document state priority hierarchy
- [ ] 3.2 Document state blocking rules
- [ ] 3.3 Reduce excessive logging
- [ ] 3.4 Add state validation checks
- [ ] 3.5 Fix priority edge cases

---

## Testing After Cleanup

After implementing cleanup, test:
1. NPCs following player don't gather/work/defend
2. NPCs defending don't gather/work/follow
3. NPCs in combat don't gather/work/follow
4. Task system doesn't interfere with defend/combat/follow
5. State transitions are smooth (no stuttering)
6. No console spam from excessive logging
7. Priority system works correctly (higher priority states win)

---

## Notes

- All changes should maintain backward compatibility
- Test each phase before moving to the next
- Keep existing functionality while fixing integration issues
- Document any priority changes in code comments
