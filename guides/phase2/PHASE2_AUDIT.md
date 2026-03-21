# Phase 2 Implementation Audit & Cleanup Plan

**Date:** 2026-01-27  
**Purpose:** Identify all Phase 2 work, verify implementation status, and create cleanup/efficiency improvements plan.

---

## Overview

Phase 2 includes:
1. **Context Menu System** (Steps 1-4, Phase A-B)
2. **Ordered Follow** (Steps 5-6, Phase C)
3. **DEFEND System** (Steps 7-8, Phase D)
4. **HUD & NPC Drag** (Steps 9-10, Phase E)
5. **Task System** (Steps 12-18, Phase G)
6. **Gather Job System** (Additional work)

---

## 1. Context Menu System (Phase A-B)

### ✅ Implemented Components

**Files:**
- `scripts/ui/dropdown_menu_ui.gd` - Context menu UI (Step 1)
- `scripts/main.gd` - Right-click handling, menu integration (Step 2-4)

**Features:**
- ✅ Right-click opens context menu at target
- ✅ Hover highlights options
- ✅ Left-click confirms option
- ✅ NPC freezes when menu open
- ✅ Menu closes on ESC/click outside
- ✅ Target-specific options (Info, Open Inventory, Follow, Defend)

### 🔍 Cleanup Opportunities

1. **Menu State Management**
   - Check if menu properly closes on all edge cases
   - Verify NPC unfreezing works correctly
   - Ensure no memory leaks from frozen NPCs

2. **Option Filtering**
   - Verify role-based filtering (women can't defend)
   - Check if all invalid options are hidden correctly

3. **Integration with Other Systems**
   - Ensure menu doesn't conflict with drag system
   - Verify menu closes when NPC dies/is invalidated

---

## 2. Ordered Follow System (Phase C)

### ✅ Implemented Components

**Files:**
- `scripts/npc/states/herd_state.gd` - Follow behavior
- `scripts/main.gd` - Follow command handling

**Features:**
- ✅ `follow_is_ordered` flag exists
- ✅ Unbreakable follow (no distance break when ordered)
- ✅ Context menu "Follow" option
- ✅ "Break Follow" functionality

### 🔍 Cleanup Opportunities

1. **State Integration**
   - ✅ Fixed: `herd_state.gd` now checks defend/combat
   - ⚠️ Need to verify: All states check `follow_is_ordered` before entering
   - ⚠️ Need to verify: States exit properly when follow starts

2. **Follow Priority**
   - Current: Herd catchup priority 15.0, normal herd 11.0
   - Question: Should follow beat defend (8.0)? (Probably yes - player orders)
   - Question: Should follow beat combat (12.0)? (Probably no - life over orders)

3. **Task Cancellation**
   - ✅ Fixed: `herd_state.gd` cancels tasks on enter and every frame
   - ⚠️ Need to verify: Tasks are cancelled when follow starts from other states

---

## 3. DEFEND System (Phase D)

### ✅ Implemented Components

**Files:**
- `scripts/npc/states/defend_state.gd` - Defend behavior
- `scripts/main.gd` - Defend command handling (context menu + drag)

**Features:**
- ✅ `defend_state` exists (priority 8.0)
- ✅ NPCs patrol land claim border
- ✅ Guard position calculation
- ✅ Context menu "Defend" option
- ✅ Drag NPC → land claim sets defend

### 🔍 Cleanup Opportunities

1. **State Integration**
   - ✅ Fixed: Defend cancels tasks every frame
   - ✅ Fixed: Defend checks for follow_is_ordered
   - ⚠️ Need to verify: All states check defend_target before entering
   - ⚠️ Need to verify: States exit properly when defend starts

2. **Defend Priority**
   - Current: 8.0 (increased from 6.0)
   - Question: Should defend beat reproduction (8.0)? (Tie - need tie-breaker)
   - Question: Should defend beat work_at_building (7.0-10.0)? (Probably yes for defense)

3. **Task Cancellation**
   - ✅ Fixed: `defend_state.gd` cancels tasks every frame
   - ✅ Fixed: TaskRunner checks defend before running tasks
   - ✅ Fixed: All tasks check defend before executing

4. **Movement Override**
   - ✅ Fixed: Defend sets steering target every frame
   - ⚠️ Need to verify: Tasks don't override defend movement

---

## 4. HUD & NPC Drag (Phase E)

### ✅ Implemented Components

**Files:**
- `scripts/main.gd` - HUD setup, drag handling
- `scripts/inventory/drag_manager.gd` - Drag system (if exists)

**Features:**
- ✅ Combat HUD (Hostile toggle, Break Follow)
- ✅ NPC drag system (left-click hold → drag → drop)
- ✅ Drag preview
- ✅ Drop on player → follow
- ✅ Drop on land claim → defend

### 🔍 Cleanup Opportunities

1. **Drag System Integration**
   - Verify drag doesn't conflict with context menu
   - Check if drag properly cancels when menu opens
   - Ensure drag preview is cleaned up correctly

2. **HUD State Management**
   - Verify Hostile toggle works correctly
   - Check if Break Follow clears all followers
   - Ensure HUD updates when NPCs join/leave follow

3. **Input Handling**
   - Verify right-click vs left-click hold distinction
   - Check if drag threshold (0.2s) is appropriate
   - Ensure no input conflicts

---

## 5. Task System (Phase G)

### ✅ Implemented Components

**Files:**
- `scripts/ai/task.gd` - Task base class (Step 12)
- `scripts/ai/task_runner.gd` - TaskRunner component (Step 13)
- `scripts/ai/job.gd` - Job container (Step 14)
- `scripts/ai/tasks/move_to_task.gd` - MoveTo task (Step 15)
- `scripts/ai/tasks/pick_up_task.gd` - PickUp task (Step 15)
- `scripts/ai/tasks/drop_off_task.gd` - DropOff task (Step 15)
- `scripts/ai/tasks/occupy_task.gd` - Occupy task (Step 15)
- `scripts/ai/tasks/wait_task.gd` - Wait task (Step 15)
- `scripts/ai/tasks/gather_task.gd` - Gather task (additional)
- `scripts/buildings/building_base.gd` - `generate_job()` (Step 16)
- `scripts/npc/states/work_at_building_state.gd` - Job pulling (Step 17)
- `scripts/npc/states/occupy_building_state.gd` - Building occupation (Step 17)

**Features:**
- ✅ Task base class with status enum
- ✅ TaskRunner component on NPCs
- ✅ Job container with task sequence
- ✅ All concrete tasks implemented
- ✅ Building job generation
- ✅ NPC job pulling
- ✅ Task cancellation on interrupt

### 🔍 Cleanup Opportunities

1. **Task Execution Efficiency**
   - ⚠️ **Issue**: Tasks check defend/combat every tick - could cache this
   - ⚠️ **Issue**: TaskRunner checks defend/combat every frame - could optimize
   - **Suggestion**: Cache state checks, only re-check when state changes

2. **Job Generation**
   - ⚠️ **Issue**: `generate_job()` called frequently - could cache results
   - ⚠️ **Issue**: Multiple NPCs query same building - could use job queue
   - **Suggestion**: Implement job reservation system (partially done)

3. **Task Status Reporting**
   - ⚠️ **Issue**: Debug logging is verbose - should be throttled
   - **Suggestion**: Use UnifiedLogger with appropriate levels

4. **Task Cancellation**
   - ✅ Fixed: Tasks check defend/combat
   - ✅ Fixed: TaskRunner checks defend/combat
   - ⚠️ **Issue**: Some states don't cancel tasks on exit
   - **Suggestion**: Standardize exit cleanup pattern

5. **Movement Conflicts**
   - ✅ Fixed: Defend/combat override task movement
   - ⚠️ **Issue**: Some states use steering_agent but don't cancel tasks
   - **Suggestion**: Rule: "If state controls movement, cancel tasks every frame"

---

## 6. Gather Job System (Additional Work)

### ✅ Implemented Components

**Files:**
- `scripts/ai/jobs/gather_job.gd` - Gather job sequence
- `scripts/npc/states/gather_state.gd` - Gather state with job integration
- `scripts/land_claim.gd` - Gather job generation

**Features:**
- ✅ Gather jobs (MoveTo resource → Gather → MoveTo land claim → DropOff)
- ✅ 80% inventory threshold for deposits
- ✅ Resource prioritization (finish current node)
- ✅ Job pulling from land claims

### 🔍 Cleanup Opportunities

1. **Job Pulling Efficiency**
   - ⚠️ **Issue**: Jobs pulled every frame when idle - could throttle
   - **Suggestion**: Check for jobs every 0.5-1.0 seconds, not every frame

2. **Resource Locking**
   - ✅ Implemented: Resources can be locked
   - ⚠️ **Issue**: Lock might not be released if NPC dies/interrupted
   - **Suggestion**: Add lock cleanup on task cancellation

3. **Inventory Threshold**
   - ✅ Implemented: Dynamic 80% threshold
   - ⚠️ **Issue**: Threshold calculation repeated - could cache
   - **Suggestion**: Cache threshold, recalculate when inventory changes

4. **State Integration**
   - ✅ Fixed: Gather checks defend/combat
   - ⚠️ **Issue**: Gather doesn't check follow_is_ordered
   - **Suggestion**: Add follow check (in cleanup plan)

---

## 7. State System Integration Issues

### 🔍 Common Problems Found

1. **Missing State Blocking Checks**
   - Many states don't check `follow_is_ordered` before entering
   - Some states don't check `defend_target` before entering
   - Some states don't check `combat_target` before entering

2. **Inconsistent Task Cancellation**
   - Some states cancel tasks on enter only
   - Some states cancel tasks every frame
   - Some states don't cancel tasks at all

3. **Movement Override Conflicts**
   - States that use `steering_agent` don't always cancel tasks
   - Tasks can override state movement
   - No clear rule for movement priority

4. **Code Duplication**
   - Defend/combat checks repeated in many states
   - Task cancellation code repeated
   - State blocking logic duplicated

---

## 8. Efficiency Improvements

### Performance Optimizations

1. **State Check Caching**
   - Cache `defend_target`, `combat_target`, `follow_is_ordered` checks
   - Only re-check when state changes (use signals/meta)
   - Reduces per-frame overhead

2. **Job Generation Caching**
   - Cache job generation results for 0.5-1.0 seconds
   - Prevents repeated queries to same building
   - Reduces building inventory lookups

3. **Task Status Caching**
   - Cache task status checks
   - Only re-evaluate when conditions change
   - Reduces redundant checks

4. **Logging Throttling**
   - Throttle debug logs to once per second max
   - Use appropriate log levels (DEBUG vs INFO)
   - Reduce console spam

### Code Quality Improvements

1. **Helper Functions**
   - Add `_is_defending()`, `_is_in_combat()`, `_is_following()` to `base_state.gd`
   - Add `_cancel_tasks_if_active()` helper
   - Eliminate code duplication

2. **Standardized Patterns**
   - Standardize state exit cleanup
   - Standardize state transition handling
   - Standardize task cancellation timing

3. **Documentation**
   - Document state priority hierarchy
   - Document state blocking rules
   - Document task cancellation rules

---

## 9. Priority Decisions Needed

### Edge Cases to Resolve

1. **Following vs Defending**
   - Current: Herd catchup 15.0, Defend 8.0
   - **Decision**: Should following beat defending? (Recommend: YES - player orders)
   - **Action**: Adjust priorities or add explicit check

2. **Combat vs Work**
   - Current: Combat 12.0, Work (active) 10.0
   - **Decision**: Should combat interrupt active work? (Recommend: YES - life over work)
   - **Action**: Already correct, but document decision

3. **Reproduction vs Defend**
   - Current: Both 8.0 (tie)
   - **Decision**: Should reproduction beat defend? (Recommend: NO - defense more urgent)
   - **Action**: Adjust reproduction to 7.5 or add tie-breaker

4. **Following vs Combat**
   - Current: Herd catchup 15.0, Combat 12.0
   - **Decision**: Should following beat combat? (Recommend: NO - life over orders)
   - **Action**: Add explicit check in combat state

---

## 10. Testing Checklist

### Integration Tests

- [ ] NPCs following player don't gather/work/defend
- [ ] NPCs defending don't gather/work/follow
- [ ] NPCs in combat don't gather/work/follow
- [ ] Task system doesn't interfere with defend/combat/follow
- [ ] State transitions are smooth (no stuttering)
- [ ] Context menu works with all target types
- [ ] Drag system doesn't conflict with menu
- [ ] HUD buttons work correctly
- [ ] Job pulling works for women
- [ ] Gather jobs work for clansmen

### Performance Tests

- [ ] No frame rate drops with 20+ NPCs
- [ ] Task system doesn't cause lag
- [ ] Job generation is efficient
- [ ] State checks don't cause overhead

### Edge Case Tests

- [ ] NPC dies while following - follow breaks correctly
- [ ] NPC dies while defending - defend clears correctly
- [ ] NPC dies while in task - task cancels correctly
- [ ] Building destroyed while NPC working - job cancels
- [ ] Resource depleted while gathering - job handles gracefully
- [ ] Multiple NPCs try to use same building - reservation works

---

## 11. Implementation Priority

### Phase 1: Critical Fixes (Do First)
1. Add helper functions to `base_state.gd`
2. Fix missing `follow_is_ordered` checks
3. Fix inconsistent task cancellation
4. Fix movement override conflicts

### Phase 2: Code Consolidation (Do Second)
1. Standardize state exit cleanup
2. Standardize state transition patterns
3. Consolidate task cancellation logic
4. Fix steering agent override patterns

### Phase 3: Efficiency Improvements (Do Third)
1. Cache state checks
2. Cache job generation
3. Throttle logging
4. Optimize task status checks

### Phase 4: Documentation (Do Last)
1. Document priority hierarchy
2. Document state blocking rules
3. Document task cancellation rules
4. Add code comments explaining decisions

---

## 12. Files That Need Review

### High Priority
- `scripts/npc/states/base_state.gd` - Add helper functions
- `scripts/npc/states/gather_state.gd` - Add follow check
- `scripts/npc/states/wander_state.gd` - Add follow check, fix task cancellation
- `scripts/npc/states/agro_state.gd` - Add state blocking checks
- `scripts/npc/states/defend_state.gd` - Add follow check in update
- `scripts/npc/states/work_at_building_state.gd` - Continuous task cancellation
- `scripts/npc/states/occupy_building_state.gd` - Continuous task cancellation

### Medium Priority
- `scripts/ai/task_runner.gd` - Optimize state checks
- `scripts/buildings/building_base.gd` - Cache job generation
- `scripts/land_claim.gd` - Cache gather job generation
- `scripts/npc/states/herd_state.gd` - Use helper functions
- `scripts/npc/states/combat_state.gd` - Use helper functions

### Low Priority
- `scripts/main.gd` - Review drag/menu integration
- `scripts/ui/dropdown_menu_ui.gd` - Review edge cases
- All task files - Review for efficiency improvements

---

## Summary

**Total Components:** ~20 files  
**Critical Issues:** 7 state integration problems  
**Efficiency Issues:** 4 performance optimizations  
**Code Quality Issues:** 3 consolidation opportunities  
**Documentation Gaps:** 3 areas need documentation  

**Estimated Cleanup Time:**
- Phase 1 (Critical): 2-3 hours
- Phase 2 (Consolidation): 1-2 hours
- Phase 3 (Efficiency): 1-2 hours
- Phase 4 (Documentation): 1 hour

**Total:** 5-8 hours of focused cleanup work
