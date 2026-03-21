# Critical Fixes — Prioritized List

**Purpose:** Address blockers and high-impact bugs before beta. Cross-referenced with IMPLEMENTATION_CHECKLIST, bible.md, and codebase.

**Post-3D failure (March 2025):** 3D real-time rendering abandoned. Project is **2D sprites only**. See `guides/failed3d.md`. Re-identified fixes below.

---

## Tier 1: Blockers (Fix First)

### 1. Combat Stagger Self-Target Bug
**Location:** `scripts/npc/components/combat_component.gd` line 605  
**Issue:** `_apply_stagger_to_target()` can be called on self — would cancel own attack.  
**Status:** Guard exists (`print("CRITICAL BUG")`) but verify logic never reaches self.  
**Action:** Audit call path; add explicit `if target == self: return` at function entry.

---

### 2. PerceptionArea (AOP) — DetectionArea Refactor Complete
**Location:** `scripts/npc/components/perception_area.gd`, `scripts/npc/states/combat_state.gd`  
**Status:** ✅ AOP refactor complete. DetectionArea renamed to PerceptionArea; AOA, proximity agro, mammoth agro now use PerceptionArea instead of `get_nodes_in_group()`. Node name "DetectionArea" retained in NPC.tscn.  
**Action:** None. Verify with `--agro-combat-test`.

---

### 3. Baby Inventory Size
**Location:** `scripts/main.gd` line 5132  
**Issue:** `# TODO: Modify inventory size for babies specifically`  
**Status:** Babies may use wrong slot count.  
**Action:** Define `NPCConfig.baby_inventory_slots` (or 0 if babies don't carry); wire in spawn.

---

## Tier 2: 2D / Renderer (Post-3D Failure)

### 4. Verify 2D Main Game Runs
**Context:** 3D failed on RTX 5070 (Vulkan + Compatibility). 2D uses Canvas — different pipeline.  
**Status:** Main scene is `Main.tscn` (2D). `project.godot` has no `rendering_method` → Godot default (Forward+).  
**Action:** Confirm main game runs without black/grey screen. If RTX 50 series shows issues, add to `project.godot`:
```
[rendering]
renderer/rendering_method="gl_compatibility"
renderer/rendering_method.mobile="gl_compatibility"
```
`project.godot.renderer_backup` has this config; copy if needed.

---

### 5. AssetRegistry / 2D Sprite Pipeline
**Location:** `scripts/config/asset_registry.gd`  
**Context:** All sprite loading goes through AssetRegistry (player, woman, sheep, goat, mammoth, baby, trees, oven, corpse, landclaim, travois, campfire).  
**Action:** Verify asset paths resolve to valid 2D textures. No orphaned 3D or deleted file references.

---

### 6. 3D Folder Isolation
**Context:** `3d/` contains abandoned Test3D, test3d_world, test_player_3d.gd, run scripts.  
**Status:** Main game does not load 3D scenes.  
**Action:** Do not run `run_test3d_vulkan.ps1` — it modifies `project.godot`. Keep 3D artifacts isolated.

---

## Tier 2b: Design / Balance (High Priority)

### 7. Land Claim Minimum Distance
**Location:** `scripts/npc/states/build_state.gd`  
**Status:** ✅ Already implemented — `MIN_CLAIM_GAP = 400px`, center-to-center min ≈ 1200px.  
**Action:** None.

---

### 8. Area of Agro (AOA) Outside Claim
**Location:** `scripts/npc/npc_base.gd` — `_check_area_of_agro()`  
**Issue:** AOA (200px) only triggers when enemy is **inside our land claim**.  
**Current:** `_check_proximity_agro()` (380px) already triggers in wilderness — no claim required.  
**Action:** Decide: (a) Keep as-is; or (b) Add AOA trigger when enemy within 200px **anywhere**. Low effort if (b).

---

### 9. Deposit Trigger with Herd Size
**Location:** `scripts/npc/states/wander_state.gd` line 289; `herd_wildnpc_state.gd` line 121  
**Status:** ✅ Implemented — `herded_count >= 2` triggers deposit.  
**Action:** None. Verify in playtest.

---

## Tier 3: Missing Core Features (Roadmap Phase 1)

### 10. War Horn (H Key)
**Status:** Not implemented.  
**GDD:** H next to Clan Flag → every idle clansman sprints to player and auto-herds.  
**Action:** Add input action; on H when near flag, broadcast "rally" to clansmen; set follow + herd on all idle.

---

### 11. Medic Hut / Wounds
**Status:** Not implemented.  
**GDD:** Wounds exist; hurt NPCs auto-path to Medic Hut when berries stocked.  
**Action:** Add wound state to HealthComponent; add Medic Hut building; add `heal_at_medic` state or task.

---

### 12. Resource Empty State Handling
**Location:** `scripts/npc/states/gather_state.gd`  
**Issue:** Partially implemented — NPCs may target empty/depleted nodes.  
**Action:** In GatherTask/GatherJob, skip or release nodes with `harvestable == false`; don't mark empty nodes as harvested (they respawn).

---

## Tier 4: Performance (Scale for Beta)

### 13. FSM Priority Caching
**Location:** `scripts/npc/fsm.gd`  
**Issue:** Priorities recalculated every 0.1s for all states × all NPCs.  
**Action:** Cache `get_priority()` per state; invalidate only when relevant world state changes.

---

### 14. Distance-Based NPC Update Scaling
**Location:** `scripts/npc/npc_base.gd`  
**Issue:** All NPCs update every frame regardless of distance to player.  
**Action:** Throttle `_physics_process` or FSM eval for NPCs far from player.

---

## Tier 5: Polish / Low Priority

### 15. OccupyTask / TaskRunner Debug Prints
**Location:** `scripts/ai/tasks/occupy_task.gd`, `task_runner.gd`  
**Issue:** `print("DEBUG OccupyTask: ...")` — spam console.  
**Action:** Replace with `UnifiedLogger` at DEBUG level; gate by `DebugConfig`.

---

### 16. Building _find_land_claim Debug Prints
**Location:** `scripts/buildings/building_base.gd`  
**Issue:** `print("DEBUG _find_land_claim: ...")` — verbose.  
**Action:** Use UnifiedLogger; gate by `--debug`.

---

## Deprioritized (Post-3D)

- 3D character refactor, Mixamo/YBot, CharacterBody3D
- Rendering_method switching for 3D
- Test3D scene loading or debugging

---

## Summary Table

| # | Fix | Tier | Effort | Status |
|---|-----|------|--------|--------|
| 1 | Stagger self-target guard | 1 | S | Audit + add guard |
| 2 | PerceptionArea (AOP) refactor | 1 | — | Done |
| 3 | Baby inventory size | 1 | S | Config + wire |
| 4 | Verify 2D main game runs | 2 | S | Post-3D validation |
| 5 | AssetRegistry / sprite paths | 2 | S | 2D pipeline check |
| 6 | 3D folder isolation | 2 | S | Don't run 3D scripts |
| 7 | Land claim distance | 2b | — | Done |
| 8 | AOA outside claim | 2b | M | Design decision |
| 9 | Deposit + herd size | 2b | — | Done |
| 10 | War Horn | 3 | M | New feature |
| 11 | Medic Hut / Wounds | 3 | L | New systems |
| 12 | Resource empty handling | 3 | M | GatherTask logic |
| 13 | FSM priority cache | 4 | M | Performance |
| 14 | Distance-based updates | 4 | M | Performance |
| 15–16 | Debug print cleanup | 5 | S | Logging |

---

## Recommended Order

1. **Tier 1** (1–3) — Quick wins, prevent crashes/wrong behavior.  
2. **Tier 2** (4–6) — Verify 2D runs; validate sprite pipeline; avoid 3D scripts.  
3. **Tier 3** (10–12) — War Horn, Medic, resource handling.  
4. **Tier 4** (13–14) — Performance before scaling NPC count.  
5. **Tier 5** (15–16) — Cleanup when stable.

---

*Updated post-3D failure. Sources: IMPLEMENTATION_CHECKLIST, bible.md, failed3d.md, combat_component.gd, npc_base.gd, wander_state.gd, build_state.gd, asset_registry.gd*
