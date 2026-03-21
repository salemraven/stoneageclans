# Mechanics Optimization & Simplification Plan

**Date:** February 2026  
**Status:** Plan (implementation not started)  
**Scope:** Task system, FSM, ClanBrain, land claim, inventory UI, and related mechanics.

---

## Overview

This document turns the codebase audit into an actionable plan. Items are ordered by impact and ease: quick wins first, then structural simplifications, then larger refactors.

---

## 1. Centralize “should abort work” checks

**Problem:** The same condition is duplicated in many places: `defend_target != null && valid`, `combat_target != null && valid`, `follow_is_ordered`. Used in:

- `scripts/ai/task_runner.gd` (`_process`, ~lines 42–61)
- `scripts/ai/tasks/gather_task.gd` (`_tick_impl`, ~82–88)
- `scripts/ai/tasks/drop_off_task.gd`, `pick_up_task.gd`, `move_to_task.gd`, `knap_task.gd` (same pattern)

`scripts/npc/states/base_state.gd` already has `_is_defending()`, `_is_in_combat()`, `_is_following()` (lines 246–260).

**Plan:**

1. Add a single helper on **NPCBase**, e.g. `should_abort_work() -> bool`, that returns `true` when the NPC is defending, in combat, or in ordered follow.
2. Optionally implement it by delegating to the FSM’s state or to the same logic as base_state (without requiring state to be loaded). Prefer one source of truth (e.g. NPCBase properties only).
3. In **TaskRunner** `_process`, replace the inline checks with one call to `npc_base.should_abort_work()`; if true, `cancel_current_job()` and return.
4. In each **Task** that currently checks defend/combat/follow in `_tick_impl` (and `_start_impl` if needed), replace those checks with the same helper (actor as NPCBase).

**Files to touch:** `npc_base.gd`, `task_runner.gd`, `gather_task.gd`, `drop_off_task.gd`, `pick_up_task.gd`, `move_to_task.gd`, `knap_task.gd`.

**Outcome:** One place to change “when to abort work”; fewer branches and less copy-paste.

---

## 2. TaskRunner: deduplicate job cleanup

**Problem:** In `scripts/ai/task_runner.gd`, `cancel_current_job()` and `_clear_job()` both:

- Release `current_job.resource_node` (if the job has it and it has a `release(npc)` method).
- Clear `building.job_reserved_by` and `building.transport_reserved_by` when the job has a building reference.

**Plan:**

1. Add a private method, e.g. `_release_job_resources()`, that:
   - If `current_job` exists and has `resource_node`, call `release(npc)` if valid.
   - If `current_job.building` exists and is valid, set `job_reserved_by` and `transport_reserved_by` to null (with the same `"in"` checks you use now).
2. Call `_release_job_resources()` from both `cancel_current_job()` and `_clear_job()` before nulling `current_job` / `current_task` and setting `is_active = false`.
3. Remove the duplicated blocks from both call sites.

**Files to touch:** `scripts/ai/task_runner.gd`.

**Outcome:** Single place for “release resources and building reservations”; fewer bugs when adding new job types.

---

## 3. Trim DEBUG prints in tasks

**Problem:**

- `scripts/ai/tasks/gather_task.gd`: many `print("DEBUG GatherTask...")` in `_start_impl` and `_tick_impl` (the latter runs every frame).
- `scripts/ai/task_runner.gd`: `print("DEBUG TaskRunner: ...")` on job assign, task start, success, and fail.

**Plan:**

1. Remove or replace with `UnifiedLogger` at DEBUG level (or behind a debug flag) so they are off in normal runs.
2. Prefer one log line per meaningful event (e.g. task start, task end, job assign, job cancel) rather than per-tick logs in `_tick_impl`.

**Files to touch:** `scripts/ai/tasks/gather_task.gd`, `scripts/ai/task_runner.gd`; optionally other task scripts that have similar prints.

**Outcome:** Less console spam and better performance when many NPCs run tasks.

---

## 4. FSM: data-driven state creation

**Problem:** `scripts/npc/fsm.gd` has a very long `_create_state_instances()` with repeated blocks: load script → create Node → set_script → add_child → initialize → set fsm (and sometimes different error handling per state).

**Plan:**

1. Define a single table (e.g. Dictionary or array of config) mapping state name → script path (and optional flags if needed).
2. In one loop over that table:
   - Load the script; if fail, push_error and continue.
   - Create a Node, set_script, add_child, initialize(npc), set("fsm", self).
   - Store in `states[state_name]`.
3. Remove the large per-state blocks. Keep any state that needs special handling as a small branch inside the loop or as a post-pass.
4. Ensure all states currently registered are present in the table (idle, wander, seek, eat, gather, herd, herd_wildnpc, agro, combat, defend, raid, search, build, reproduction, occupy_building, work_at_building, craft).

**Files to touch:** `scripts/npc/fsm.gd`.

**Outcome:** Shorter FSM file; adding a new state = one table entry; fewer copy-paste bugs.

---

## 5. Gather state: single code path

**Problem:** In `scripts/npc/states/gather_state.gd`, `USE_GATHER_JOBS = true` but the state still contains the full legacy path: `_find_target()`, move-to-target, gather timer, `_collect_resource()`, `_exit_to_deposit()`, etc. Two parallel flows are maintained.

**Plan:**

1. Decide that the gather **job** path (TaskRunner + GatherJob) is the only supported path.
2. In gather state:
   - On enter: try to pull a gather job; if pulled, return (TaskRunner runs it).
   - In update: if TaskRunner has no job, try to pull again; if still no job, optionally exit to wander (or stay and retry next frame with a small delay to avoid spin).
3. Remove the legacy gather logic: `_find_target()`, manual move, gather_timer, `_collect_resource()`, `_exit_to_deposit()`, and related helpers that exist only for the legacy path. Keep helpers used by both paths (e.g. `_get_used_slots()`, `_get_inventory_threshold()`) if still needed for `can_enter` / `is_complete`.
4. Remove the `USE_GATHER_JOBS` flag.

**Files to touch:** `scripts/npc/states/gather_state.gd`.

**Outcome:** One clear flow: “gather state = run gather jobs only”; less code and easier tuning.

---

## 6. ClanBrain: split or modularize

**Problem:** `scripts/ai/clan_brain.gd` is 1000+ lines: evaluation, threat cache, raid logic, resource status, alerts, strategic state, etc.

**Plan (choose one or combine):**

- **Option A – Split by responsibility:** Extract into smaller RefCounted (or Node) helpers, e.g.:
  - Threat/alert evaluation (threat cache, alert level, decay).
  - Raid logic (raid scoring, party formation, raid state machine).
  - Resource/state evaluation and ratio updates.
  ClanBrain then holds references and delegates; each module has a clear API.
- **Option B – Keep one file but group:** Move constants and `resource_status` into a small config struct or resource; group methods into clear sections (threat, raid, resources, assignment) with comments. Add a short “Architecture” comment at the top.
- **Option C – Extract only raid:** Move raid-specific logic (scoring, party, state) into a `RaidPlanner` or `RaidController` class; ClanBrain keeps evaluation and assignment and calls into it.

**Files to touch:** `scripts/ai/clan_brain.gd`; new file(s) if splitting (e.g. under `scripts/ai/`).

**Outcome:** Easier to read, tune, and test; fewer merge conflicts.

---

## 7. Land claim: single prune helper for role pools

**Problem:** `scripts/land_claim.gd` has `_prune_defenders()` and `_prune_searchers()` with identical logic (keep only valid + not dead).

**Plan:**

1. Add a generic helper, e.g. `_prune_pool(pool: Array) -> void`, that:
   - Iterates the array, keeps only elements where `is_instance_valid(n)` and `not (n.has_method("is_dead") and n.is_dead())`.
   - Assigns the result back to the same array (or clears and re-adds).
2. Replace `_prune_defenders()` body with `_prune_pool(assigned_defenders)` and `_prune_searchers()` with `_prune_pool(assigned_searchers)`.
3. Keep the public `add_defender` / `remove_defender` / `add_searcher` / `remove_searcher` APIs unchanged; they continue to call the prune before/after mutating.

**Files to touch:** `scripts/land_claim.gd`.

**Outcome:** One implementation of “valid + alive” pruning; future role pools can reuse it.

---

## 8. Inventory UI: reduce setup logging

**Problem:** `scripts/inventory/inventory_ui.gd` `setup()` has multiple `print()` calls that run whenever an inventory is opened.

**Plan:**

1. Remove or replace with a single `UnifiedLogger` call at DEBUG level (e.g. “InventoryUI setup: slot_count=%d”) or guard with a debug flag.
2. Avoid logging on every slot build/update; at most one log per setup call.

**Files to touch:** `scripts/inventory/inventory_ui.gd`.

**Outcome:** Less console noise when opening inventories frequently.

---

## 9. Jobs vs FSM (documentation / mental model)

**Problem:** Two layers exist—**Jobs** (ordered task lists: e.g. MoveTo → Gather → MoveTo → DropOff) and **FSM states** (e.g. gather, craft). The gather state can either pull a GatherJob (TaskRunner runs it) or use legacy gather behavior. This can be confusing.

**Plan:**

1. Add a short section to a relevant guide (e.g. `guides/phase2/Task_system.md` or `guides/tasks_guide.md`) that states:
   - **States** decide “what role the NPC is in” (gather, defend, craft, etc.).
   - **Jobs** are the concrete sequence of tasks for that role (e.g. gather = one GatherJob).
   - TaskRunner runs the current job’s tasks; states that use jobs only assign jobs and let TaskRunner run.
2. After completing item 5 (gather single path), update that doc to say gather state is job-only.

**Files to touch:** One of `guides/phase2/Task_system.md`, `guides/tasks_guide.md`, or `guides/main.md` (brief “Systems” subsection).

**Outcome:** Clear mental model for future changes and for anyone reading the task system.

---

## Implementation order (suggested)

| Order | Item | Effort | Impact |
|-------|------|--------|--------|
| 1 | Centralize “should abort work” (1) | Small | High – less duplication, one place to fix behavior |
| 2 | TaskRunner cleanup deduplication (2) | Small | Medium – fewer bugs in job lifecycle |
| 3 | Trim DEBUG prints (3) | Small | Medium – performance and log clarity |
| 4 | Inventory UI setup logging (8) | Tiny | Low – less noise |
| 5 | FSM data-driven state creation (4) | Medium | High – shorter FSM, easier to add states |
| 6 | Gather single code path (5) | Medium | High – simpler gather state |
| 7 | Land claim prune helper (7) | Tiny | Low – consistency |
| 8 | ClanBrain split/modularize (6) | Large | High – long-term maintainability |
| 9 | Jobs vs FSM documentation (9) | Tiny | Medium – clarity |

---

## Completion checklist (for each item)

- [ ] 1. Centralize “should abort work”
- [ ] 2. TaskRunner deduplicate job cleanup
- [ ] 3. Trim DEBUG prints in tasks
- [ ] 4. FSM data-driven state creation
- [ ] 5. Gather state single code path
- [ ] 6. ClanBrain split/modularize
- [ ] 7. Land claim single prune helper
- [ ] 8. Inventory UI setup logging
- [ ] 9. Jobs vs FSM documentation

---

*Generated from codebase audit; update this plan as items are implemented or deferred.*
