# Stone Age Clans — Lore Keeper

**Performance issues, optimization opportunities, and better ways of doing things.**  
Companion to `bible.md`. Last updated: March 2026.

---

## Quick Wins (P0)

### 1. CombatScheduler Debug Spam
**Location:** `scripts/systems/combat_scheduler.gd` L24–65

**Issue:** Multiple `print()` calls in `_process()` fire whenever events are pending. At 60 FPS with combat, this floods the console.

**Fix:** Gate all scheduler prints behind `if DebugConfig.enable_debug_mode:`.

---

### 2. NPCs Group Fallback
**Location:** `scripts/inventory/building_inventory_ui.gd` ~L1491

**Issue:** Fallback to `get_nodes_in_group("NPCs")` when `"npcs"` is empty. NPCs are added to `"npcs"` in `npc_base.gd`; no one uses `"NPCs"`. Dead code.

**Fix:** Remove the `"NPCs"` fallback; use only `"npcs"`.

---

### 3. Per-Frame Task Cancellation
**Location:** `scripts/npc/states/agro_state.gd` L146, `scripts/npc/states/herd_state.gd` L42

**Issue:** Both call `_cancel_tasks_if_active()` every frame in `update()`. Tasks are already cancelled on enter; repeating every frame is redundant.

**Fix:** Cancel only on enter (like defend/combat). Add cheap guard if needed: `if not npc.task_runner.has_job(): return` before cancel.

---

## Performance & Scalability (P1)

### 4. get_nodes_in_group Overuse
**Scope:** 100+ calls across codebase. Worst offenders:
- `main.gd` — 53 calls
- `npc_base.gd` — 37 calls
- `CombatTick` — iterates all NPCs every 25 Hz for agro decay
- `steering_agent.gd` — 8 calls (some already use land claims cache)

**Fix:** Add caches like `get_cached_land_claims()`:
- `get_cached_npcs()` (invalidate on spawn/death)
- `get_cached_buildings()` (invalidate on build/destroy)
- `get_cached_corpses()` if used heavily

`NodeCache` exists and delegates to main's land claims cache, but many states still call `get_nodes_in_group` directly.

---

### 5. FSM Uses load() Instead of preload()
**Location:** `scripts/npc/fsm.gd` L59–75

**Issue:** Uses `load()` for all 16 state scripts. Disk I/O at runtime for every NPC.

**Fix:** Switch to `preload()` at top of file. Scripts load once at parse time, not per-NPC.

---

### 6. ResourceIndex is_position_in_enemy_claim()
**Location:** `scripts/systems/resource_index.gd` L16–30

**Issue:** Static helper uses `tree.get_nodes_in_group("land_claims")`. Called during gather job generation.

**Fix:** Pass main's cached land claims (or similar) into the function instead of querying the group.

---

### 7. Job Script Loading
**Location:** `scripts/ai/jobs/gather_job.gd`, `craft_job.gd`, `building_base.gd`, various tasks

**Issue:** `load()` for task scripts inside `_init` or `_build_task_sequence`. Loads scripts every time a job is created.

**Fix:** Use `preload()` at file scope for task scripts; reuse.

---

## Code Structure (P2)

### 8. God Classes
- **main.gd** — ~5.8k lines: spawn, UI, input, building placement, dialogs, etc.
- **npc_base.gd** — ~3.4k lines: FSM, components, agro, herding, deposit, etc.

**Fix:** Extract subsystems:
- main.gd → `SpawnManager`, `PlayerInteractionManager`, `UIOrchestrator`, `BuildingPlacementManager`
- npc_base.gd → `CombatBehavior`, `FollowBehavior`, `InventoryBehavior` (or similar)

---

### 9. Texture Loading
**Scope:** Many `load(path)` calls for textures at runtime (main.gd NPC sprites, weapon_component, building_base, etc.). Same paths repeated.

**Fix:** Centralize common textures (player, woman, sheep, goat) with `preload()` or a small asset registry; reuse.

---

## Logic & Design Notes

### 10. TaskRunner should_abort_work() Every Frame
**Location:** `scripts/ai/task_runner.gd`

TaskRunner checks `npc.should_abort_work()` every `_physics_process`. Correct for responsiveness. Ensure `should_abort_work()` is cheap (property checks only, no group queries).

---

### 11. ClanBrain Update Frequency
**Location:** `scripts/land_claim.gd`

Each land claim calls `clan_brain.update(delta)` every frame. Brain does heavy work only every 5s, but the call happens every frame. Consider a timer or central manager that updates brains on a fixed interval.

---

### 12. Combat Whiff Rate
**Note:** SOSA reports whiffs > hits (e.g. 28 vs 121). Causes: 210° arc, head-on checks, target switching. Tunable, not a bug.

---

## Suggested Priority Order

1. Gate CombatScheduler prints (immediate, no risk)
2. Remove per-frame cancel in agro_state and herd_state
3. Switch FSM to `preload()` for state scripts
4. Add `npcs` cache and use in CombatTick and hot paths
5. Preload task scripts in jobs
6. Split main.gd and npc_base.gd when refactoring

---

## What's Already Solid

- Land claims cache + invalidation
- ResourceIndex spatial grid (200px cells)
- DetectionArea (event-driven, throttled)
- CombatScheduler (event-driven timing)
- Task cancel-on-enter for defend/combat
- NodeCache design (TTL + land claims delegation)
- Pull-based ClanBrain (no direct NPC assignment)

---

*See also: `bible.md` (lore + code architecture), `guides/SOSA.md` (state of the game)*
