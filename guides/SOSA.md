# Stone Age Clans — State of the Game (Developer Handoff)

**Purpose:** Handoff document for developers finishing the game design. Use this to understand what exists, what's broken, what's missing, and where to look.

**Related docs:** `guides/aboutsoc.md` (systems & loops), `guides/earlygame.md` (design), `guides/gdd.md` (canonical GDD), `guides/multiplayer.md` (browser/net roadmap), `guides/Phase4/not_implemented_systems.md`, `guides/AgroCombatTestIssues.md`

---

## 1. Project Overview

| Item | Value |
|------|-------|
| Engine | Godot 4.5 |
| Main scene | `res://scenes/Main.tscn` |
| Script language | GDScript |
| Target | Desktop (browser/multiplayer planned) |

### Key Directories

```
scripts/
├── main.gd              # Central orchestrator (~5,870 lines) — spawn, UI, input, world
├── player.gd            # Player movement, hunger, herding
├── land_claim.gd        # Land claim logic, ClanBrain, defenders, searchers
├── campfire.gd          # Nomadic base (no ClanBrain)
├── gatherable_resource.gd
├── ai/                  # ClanBrain, jobs, tasks
├── npc/                 # npc_base.gd, fsm.gd, states/, components/
├── buildings/           # building_base.gd, production_component.gd
├── config/              # balance_config, npc_config, debug_config, craft_registry
├── systems/             # combat_tick, combat_scheduler, entity_registry, resource_index, occupation_system
├── inventory/           # player_inventory_ui, building_inventory_ui, drag_manager
├── logging/             # playtest_instrumentor, playtest_reporter
└── ui/                  # dropdown_menu_ui, character_menu_ui, progress_pie_overlay
```

### Autoloads (project.godot)

| Name | Path | Purpose |
|------|------|---------|
| UnifiedLogger | `scripts/logging/unified_logger.gd` | Centralized logging |
| PlaytestInstrumentor | `scripts/logging/playtest_instrumentor.gd` | Playtest event capture |
| OccupationDiagLogger | `scripts/logging/occupation_diag_logger.gd` | Occupation debug |
| NPCConfig | `scripts/config/npc_config.gd` | NPC behavior tuning |
| DebugConfig | `scripts/config/debug_config.gd` | Debug flags, CLI args |
| CombatScheduler | `scripts/systems/combat_scheduler.gd` | Combat event timing |
| CombatTick | `scripts/systems/combat_tick.gd` | Agro decay, thresholds |
| EntityRegistry | `scripts/systems/entity_registry.gd` | Stable entity IDs |
| HostileEntityIndex | `scripts/systems/hostile_entity_index.gd` | Hostile NPC lookup |
| YSortUtils | `scripts/systems/y_sort_utils.gd` | Draw order |
| ClaimBuildingIndex | `scripts/systems/claim_building_index.gd` | Claim → buildings |
| ResourceIndex | `scripts/systems/resource_index.gd` | Spatial resource queries |
| OccupationSystem | `scripts/systems/occupation_system.gd` | Building slot assignment |
| BalanceConfig | `scripts/config/balance_config.gd` | Spawn, production, hunger |
| ChunkUtils | `scripts/world/chunk_utils.gd` | World chunking |
| CorpseConfig | `scripts/config/corpse_config.gd` | Corpse behavior |

---

## 2. Configuration Reference

### BalanceConfig (`scripts/config/balance_config.gd`)

Spawn counts, radii, production times, hunger, reproduction, resource cooldown.

| Key vars | Default | Notes |
|----------|---------|------|
| caveman_count | 1 | AI clans (1 = 1v1 vs player) |
| woman_initial, sheep_initial, goat_initial | 6 each | Wild spawns |
| bread_craft_time, wool_craft_time, milk_craft_time | 90, 45, 45 | Seconds |
| resource_cooldown_seconds | 120 | After gathers_before_cooldown |
| lease_expire_seconds | 90 | Gather job lease |

### NPCConfig (`scripts/config/npc_config.gd`)

Hunger, panic, movement, herd behavior, agro thresholds, inventory slots. Very large — use `@export` in editor or edit file.

### DebugConfig (`scripts/config/debug_config.gd`)

- `--debug` / `--verbose`: Full debug mode
- `--agro-combat-test`: 2 clans, 10 clansmen each, combat test
- `--raid-test`: ClanBrain raid test
- `enable_debug_mode`, `enable_agro_combat_debug_viz`, etc.

---

## 3. What's Working Well (Detailed)

### 3.1 Core Architecture

- **FSM** (`scripts/npc/fsm.gd`): 16 states, priority-based evaluation every 0.1s. States: idle, wander, seek, eat, gather, herd, herd_wildnpc, agro, combat, defend, raid, search, build, reproduction, occupy_building, work_at_building, craft.
- **Task system** (`scripts/ai/task_runner.gd`, `scripts/ai/tasks/`): Job + Task chains. GatherJob, MoveToTask, PickUpTravoisTask, PlaceTravoisTask, DepositTask. Lease expiry, abort on defend/combat/follow.
- **ClanBrain** (`scripts/ai/clan_brain.gd`): Strategic AI for land claims. Evaluates every 5s. Defender/searcher quotas, raid decisions, economic weights. Player clan uses slider for defend ratio.

### 3.2 Combat

- **CombatTick** (`scripts/systems/combat_tick.gd`): 25 Hz timer. Agro event queue, decay (2.0 combat / 5.0 idle), hysteresis 70 enter / 60 exit.
- **CombatScheduler** (`scripts/systems/combat_scheduler.gd`): Schedules hit frames, recovery at msec. Events sorted by time.
- **CombatComponent** (`scripts/npc/components/combat_component.gd`): Windup → hit → recovery. `request_attack(target)`.
- **DetectionArea** (`scripts/npc/components/detection_area.gd`): Event-driven; body_entered/exited. `get_nearest_enemy()`. Replaces per-frame get_nodes_in_group.
- **EntityRegistry**: instance_id-based stable IDs for combat_target_id, multiplayer readiness.

### 3.3 Performance

- **Land claims cache** (`main.gd`): `get_cached_land_claims()`, `invalidate_land_claims_cache()`. Use instead of `get_nodes_in_group("land_claims")`.
- **ResourceIndex** (`scripts/systems/resource_index.gd`): Spatial grid (200px cells). `query_near(position, radius, filters)`.
- **NodeCache** (`scripts/npc/node_cache.gd`): Caches land claims, NPCs. Exists but not used everywhere.

### 3.4 Content

- **Campfire** (`scripts/campfire.gd`): 250px radius, 6 slots, cooking, clan join. No ClanBrain. Abandonment despawn when extinguished + player far.
- **Land claim** (`scripts/land_claim.gd`): 400px radius, 12 slots, ClanBrain, defenders, searchers, EnemiesInClaim zone.
- **Travois**: Player + clansmen carry. PickUpTravoisTask, PlaceTravoisTask. Movement 70%, no defend when carrying.
- **Production** (`scripts/buildings/components/production_component.gd`): Oven (bread), Dairy (milk), Farm (wool). Recipe-based, woman/animal required.
- **OccupationSystem**: request_slot, confirm_arrival, unassign, force_assign. Woman + animal slots.
- **CraftRegistry** (`scripts/config/craft_registry.gd`): Oldowan, Cordage, Campfire, Travois. Data-driven recipes.
- **Reproduction** (`scripts/npc/components/reproduction_component.gd`): Pregnancy, birth. Baby pool manager.

### 3.5 Testing

- **PlaytestInstrumentor**: Records to `user://playtest_*.jsonl` or `Tests/` when `GODOT_TEST_LOG_DIR=Tests`.
- **Reporter**: `godot --path . -s scripts/logging/playtest_reporter.gd [path]`
- **Scripts**: `playtest_prep.sh`, `run_playtest.sh`, `run_2min_test.sh`, `run_4min_test.sh`
- **Modes**: `--agro-combat-test`, `--raid-test`, `--playtest-2min`, `--playtest-4min`

---

## 4. What Works But Could Be More Efficient

| Area | Location | Issue | Fix |
|------|----------|-------|-----|
| main.gd | `scripts/main.gd` | ~5,870 lines, god class | Split: PlayerInteractionManager, SpawnManager, UIOrchestrator, BuildingPlacementManager |
| npc_base.gd | `scripts/npc/npc_base.gd` | ~3,400 lines | Extract: CombatBehavior, FollowBehavior, InventoryBehavior |
| get_nodes_in_group | Many files | 100+ calls | Add caches for `npcs`, `buildings`, `corpses`, `ground_items` (main has land_claims cache) |
| FSM init | `scripts/npc/fsm.gd` L59–75 | Uses `load()` for 16 state scripts | Switch to `preload()` for faster startup |
| CombatScheduler | `scripts/systems/combat_scheduler.gd` L24–65 | Debug `print()` in `_process` when events pending | Gate behind `DebugConfig.enable_debug_mode` |
| NodeCache | `scripts/npc/node_cache.gd` | Exists, underused | Use in wander_state, herd_state, agro_state, etc. |
| ResourceIndex | `scripts/systems/resource_index.gd` L16–30 | `is_position_in_enemy_claim()` uses get_nodes_in_group | Use main's land claims cache |

---

## 5. What Needs Work

### 5.1 Bugs & Edge Cases

| Bug | Location | Notes |
|-----|----------|-------|
| CLI agro-combat test aborts | Run env | `Command failed to spawn: Aborted`. Run manually: `godot --path . -- --agro-combat-test` |
| Formation creep | `main.gd` agro block | Leaders can drift at border. Verify target_position not from moving point. BORDER_ZONE_INNER/OUTER = 0.70/1.20 |
| NPCs group typo | `scripts/inventory/building_inventory_ui.gd` ~L1491 | `get_nodes_in_group("NPCs")` vs `"npcs"` — inconsistent |

### 5.2 TODOs in Code

| TODO | File | Line | Description |
|------|------|------|-------------|
| Baby inventory size | `scripts/main.gd` | ~5075 | Modify inventory size for babies specifically |
| DetectionArea migration | `scripts/npc/states/combat_state.gd` | ~597 | Remove legacy enemy search once all NPCs have DetectionArea |
| Fire click sound | `scripts/inventory/building_inventory_ui.gd` | ~1400 | Load actual sound file (e.g. `res://assets/sounds/fire_click.ogg`) |
| Reproduction prioritization | `scripts/npc/components/reproduction_component.gd` | ~317 | Prioritize by traits and age when traits implemented |

### 5.3 Planned But Not Implemented

| Feature | Design doc | Notes |
|---------|------------|-------|
| Decay for abandoned buildings | `guides/earlygame.md` | last_activity_time, ABANDON_THRESHOLD, DecayManager |
| Pack hut into travois | `guides/earlygame.md` | get_pack_into_travois_result(), hut_recipe - travois_recipe |
| Campfire → land claim upgrade | `guides/earlygame.md` | Progression path |
| TransportJob for clansmen travois | `guides/earlygame.md` | ClanBrain/claim generates when transport needed |
| Hominid classes | `guides/earlygame.md`, `guides/hominids.md` | Homo Sapiens, Neanderthal, Denisovan, Homo Erectus |
| Thirst | GDD | Only hunger in |
| Day/night cycle | `guides/future implementations/daynight.md` | Exposure, torches |
| Wounds & healing | GDD, `guides/Phase4/not_implemented_systems.md` | Medic Hut, auto-path |
| Relics & Shrine | GDD | Clan-wide buffs |
| War Horn (H) | GDD | Herd idle clansmen to player |
| Predators | `guides/future implementations/predator.md` | Wolves, mammoths |
| Horses | GDD | Riding, travois |

### 5.4 Combat Balance

- Whiff count > hit count (e.g. 28 hits vs 121 whiffs). Acceptable but tunable. Causes: club arc, head-on checks, target switching, movement.

---

## 6. Design Gaps vs GDD

The GDD (`guides/gdd.md`) is the canonical design. Current implementation gaps:

| GDD item | Status |
|----------|--------|
| Generational permadeath, age 13→101 | Age structure exists, not wired |
| 5 hominid species, hybridization | Not implemented |
| Clan Flag (first craftable) | Land claim exists; flag/upgrade path different |
| Invisible fence (NPCs can't leave) | Not fully in |
| Flag → Tower → Keep → Castle | Not implemented |
| War Horn (H) | Not implemented |
| Destroy enemy flag = total wipe | Raid exists; total wipe logic partial |
| Baby pool capacity, Living Huts | Baby pool exists; capacity/hut link partial |
| 1 woman per production building | OccupationSystem does this |
| Full building list (Spinner, Dairy, Bakery, Armory, Tailor, Medic, Storage, Shrine) | Oven, Farm, Dairy exist; others shells or missing |
| Wild wheat only outside claim | Not implemented |
| Wounds, Medic Hut, auto-heal | Not implemented |
| Drag-and-drop everything | Implemented |

---

## 7. Implementation Priorities (Suggested)

### P0 — Quick wins

1. Gate CombatScheduler debug prints behind `DebugConfig.enable_debug_mode`
2. Fix `building_inventory_ui.gd` NPCs group typo (L1491)
3. Add `npcs` and `buildings` caches (like land_claims)

### P1 — Performance & stability

4. Switch FSM to `preload()` for state scripts
5. Use NodeCache / caches in wander_state, herd_state, agro_state
6. ResourceIndex: use land claims cache in `is_position_in_enemy_claim()`

### P2 — Code health

7. Split main.gd into subsystems
8. Extract npc_base.gd behaviors into components

### P3 — Content

9. Campfire → land claim upgrade flow
10. Decay for abandoned buildings
11. Pack hut into travois
12. Finish DetectionArea migration for all NPCs

### P4 — Design completion

13. Hominid classes, traits
14. Thirst, day/night
15. Wounds, Medic Hut
16. War Horn
17. Browser export (see `guides/multiplayer.md` Phase 1)

---

## 8. Testing Quick Reference

```bash
./playtest_prep.sh                    # Verify Godot, print commands
./run_playtest.sh                     # Normal play
./run_2min_test.sh                    # 120s auto-quit
./run_4min_test.sh                    # 240s auto-quit
godot --path . -- --agro-combat-test  # Combat test (run manually, 60–90s)
godot --path . -- --raid-test         # Raid test, 90s auto-quit
godot --path . -s scripts/logging/playtest_reporter.gd user://playtest_*.jsonl  # Analyze
```

Export `GODOT_TEST_LOG_DIR=Tests` to write logs into project.

---

## 9. Key Entry Points for Common Tasks

| Task | Where to look |
|------|---------------|
| Add new NPC state | `scripts/npc/fsm.gd` (register), `scripts/npc/states/` (new state script) |
| Tune combat | `NPCConfig` agro_*, `scripts/systems/combat_tick.gd` thresholds |
| Add craftable | `scripts/config/craft_registry.gd` |
| Add production building | `scripts/buildings/building_base.gd`, ProductionComponent, CraftRegistry |
| Change spawn counts | `BalanceConfig` |
| Add playtest event | `scripts/logging/playtest_instrumentor.gd` |
| Player input | `main.gd` _input(), _configure_input() |
| NPC job assignment | ClanBrain, land_claim defender/searcher quotas, OccupationSystem |

---

## 10. Summary Snapshot

| Category | Status |
|----------|--------|
| Core gameplay | Solid |
| AI / clan logic | Strong |
| Combat | Working, tuning possible |
| Performance | Good base, optimization headroom |
| Testing infra | Good |
| Code structure | main.gd, npc_base.gd need refactor |
| GDD alignment | ~40% (core loop in, progression/permadeath/raiding partial) |
| Multiplayer | Not started |
| Browser | Not started |
