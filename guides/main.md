# Stone Age Clans – Main Mechanics & Implementation Report

**Date**: February 2026  
**Status**: Living document – single source for mechanics, gameplay loop, and implementation status.

---

## 1. Core Fantasy & Win Condition

- **Fantasy**: Generational permadeath + brutal raiding. Build a bloodline that dominates the map through combat, resource management, and clan expansion.
- **Win condition**: Your bloodline completely dominates the map. Pure sandbox – no hard victory screen; domination is the goal.
- **Design mix**: Stoneshard (tactical combat, survival, inventory) + RimWorld (colony management, emergent storytelling, permadeath).

---

## 2. Gameplay Loop – Building Tribes & Fighting for Dominance

### Intended full loop

1. **Spawn** – Player spawns at age 13; choose hominid species (future).
2. **Establish** – Place land claim; start clan; NPCs deposit and work around it.
3. **Gather** – Collect wood, stone, berries, wheat; herd women, sheep, goats into claim radius.
4. **Build** – Construct Living Huts, Supply Hut, Shrine, Dairy Farm, Oven, etc. from land claim build menu.
5. **Produce** – Oven: Wood + Grain → Bread; (future) Dairy, Farm, Armory, Tailor, Medic Hut.
6. **Expand** – Grow clan (reproduction, baby pool, surplus → clansmen); more buildings, more capacity.
7. **Defend** – ClanBrain assigns defenders; agro on intruders; combat when enemies enter/raid.
8. **Raid** – ClanBrain organizes raid parties; attack enemy land claims; loot buildings; destroy flag = total wipe.
9. **Reproduce** – Women in claim radius birth babies; babies grow to clansmen; baby pool cap from Living Huts.
10. **Age & continue** – Player ages (future: die at 101); next generation; repeat until map dominated.

### Current loop (what works today)

1. Spawn (player + NPCs; battle royale mode can force combat).
2. Place land claim (player or NPCs after cooldown).
3. Gather (player and NPCs: berries, wood, stone, wheat).
4. Build (craft buildings from land claim inventory; drag to place: Living Hut, Supply Hut, Shrine, Dairy Farm, Oven).
5. Produce (Oven only: 1 Wood + 1 Grain → 1 Bread in 15s; fire button).
6. Herd (right-click NPCs; bring women/sheep/goats into claim → claimed).
7. Combat (agro on intrusion; melee with windup/recovery; death → corpse looting).
8. Defend (ClanBrain defender quota; NPCs self-assign Defend state).
9. Raid (ClanBrain raid intent; NPCs self-assign Raid state; move → engage → loot → retreat).
10. Reproduction (women in claim reproduce; babies spawn, grow to clansmen).
11. Tasks (NPCs pull jobs: Gather, DropOff, MoveTo, etc. from land claim/buildings).

---

## 3. What Players Can Do

### Controls (implemented)

- **WASD / Arrow keys** – Move.
- **I** – Open inventory (player + nearby building/corpse/land claim).
- **Tab** – Toggle player inventory.
- **9 / 0** – Consume item in hotbar slot 9 or 0.
- **Click NPC** – Attack (if weapon equipped).
- **Right-click NPC** – Herd (NPC follows player).
- **Right-click land claim** – Context menu (e.g. INFO → building inventory / build menu).
- **H** (War Horn) – Planned; not implemented (all idle clansmen sprint to player and herd).

### Actions

- **Gather** – Walk to trees/boulders/berries/wheat; use axe/pick/hands; items go to inventory.
- **Craft land claim** – Wood + Stone + Berries + Leather (from inventory); carry and place in world.
- **Place buildings** – From build menu (I near claim): buy building with materials from claim inventory; drag building item onto world inside claim; 50px buffer between buildings.
- **Deposit / withdraw** – Drag-and-drop between player ↔ land claim ↔ buildings ↔ NPCs ↔ corpses ↔ ground.
- **Herding** – Right-click woman/sheep/goat/caveman → they follow; enter claim radius to claim for clan.
- **Combat** – Equip weapon (axe/pick); click enemy; windup → hit → recovery; loot corpse with I.
- **Eat** – Consume berries/grain/bread from inventory or hotbar slots 9/0.
- **Oven** – Open building inventory; add 1 Wood + 1 Grain; toggle Fire; wait 15s → Bread.

### Not yet (from GDD)

- War Horn (H).
- Stats panel (Tab = full stats).
- Character/Clan menu (detailed NPC/clan info).
- Age progression and generational permadeath.
- Hominid species and hybridization.

---

## 4. Mechanics – How They Work

### 4.1 Player

- **Character**: One player-controlled character; direct control only (clansmen are AI).
- **Inventory**: 5 slots + 10-slot hotbar (right hand, left hand, equipment 3–8, consumables 9–0).
- **Movement**: Steering/velocity; no FSM (unlike NPCs).
- **Combat**: Same CombatComponent as NPCs; click-to-attack; weapon required; short windup (0.1s) / recovery (0.3s) for responsiveness.
- **Herding**: Right-click sets target as follower via `_try_herd_chance`; herded_count on player.

### 4.2 Land Claim & Territory

- **Placement**: Drag land claim from inventory; must be valid position (e.g. min distance from other claims for NPCs: 800px in Phase 1; 200px in checklist).
- **Radius**: 400px (configurable); defines “clan territory.”
- **Behavior**: NPCs deposit at claim; wild NPCs entering radius become clan-owned; claim holds unlimited inventory; build menu (I) shows claim inventory + building cards.
- **Clan death**: If claim is destroyed (flag destroyed = total wipe per GDD), inventories vanish, baby pool cleared, clansmen die, women/animals scatter wild.
- **Upgrades**: Flag → Tower → Keep → Castle planned (radius, storage, relics); not implemented.

### 4.3 Buildings

- **Registry**: `BuildingRegistry` – Living Hut, Supply Hut, Shrine, Dairy Farm, Oven (costs in wood/stone).
- **Placement**: Build menu consumes materials from land claim; adds building item to player; player drags onto world; must be inside player land claim, 50px from other buildings and claim center.
- **Shared scene**: All use `Building.tscn`; `building_type` set at placement.
- **Living Hut**: +5 baby pool capacity (capacity logic present; integration disabled in code).
- **Supply Hut**: Extra storage (6 slots).
- **Shrine**: No production yet.
- **Dairy Farm**: No production yet.
- **Oven**: Only production building: 1 Wood + 1 Grain → 1 Bread, 15s; Fire button; no woman occupation.

### 4.4 Inventory & Items

- **Drag-and-drop**: Everything: player ↔ flag ↔ buildings ↔ NPCs ↔ corpses ↔ ground. Single-item drag (one at a time).
- **Feedback**: Valid drop = gold highlight; invalid = red; source slot 50% opacity while dragging.
- **Item types**: Consumables (berries, grain, bread), resources (wood, stone, wheat, fiber), tools (axe, pick), buildings (land claim, huts, etc.). Corpse keeps dead NPC inventory + hotbar.

### 4.5 NPCs – Types & Roles

- **Cavemen**: Wild humans; can be herded; can place claims and become clan “leaders.”
- **Clansmen**: Promoted from babies or from surplus baby pool; full FSM (gather, herd, defend, raid, etc.).
- **Women**: Wild; herded into claim → claimed; reproduction only in claim radius.
- **Sheep / Goats**: Herd into claim for future production (wool/milk); no production logic yet.
- **Babies**: Spawn from reproduction; grow to clansmen after timer (e.g. 1 min test / 13 years design).
- **Predators / Horses**: Planned (wolves, mammoths; horses for riding/travois); not in.

### 4.6 NPC AI – FSM & States

- **FSM**: Priority-based; evaluates states every 0.1s; highest valid priority wins.
- **States (examples)**: Idle, Wander, Gather, Eat, Herd, HerdWildNpc, Combat, Defend, Raid, Build, Reproduction, Seek, Agro, Deposit, Search, WorkAtBuilding, OccupyBuilding, Craft.
- **Combat entry**: Agro meter (0–100); e.g. intrusion into claim increases agro; when ≥ 70 enter Combat state.
- **Pull-based assignment**: ClanBrain sets quotas on land claim (defender_quota, searcher_quota, raid_intent); NPCs read quotas and self-assign in state `can_enter()` (no direct ClanBrain → NPC orders).

### 4.7 Combat

- **CombatComponent**: Windup → hit frame → recovery; event-driven via `CombatScheduler` (no per-frame attack polling).
- **DetectionArea**: Per-NPC Area2D; nearby enemies tracked; target check ~1s interval (not every frame).
- **Hit validation**: On hit frame: target alive, in range, in 90° arc; then damage + stagger.
- **Stagger**: Hit interrupts enemy windup.
- **Weapon profiles**: Axe, Pick, Unarmed (different windup/recovery).
- **Death**: Health → 0 → corpse (sprite change, lootable inventory); leader succession (oldest clansman becomes leader).

### 4.8 Herding

- **Start**: Right-click (player) or NPC herding logic; `_try_herd_chance`; `herder.herded_count += 1`.
- **Stop**: Herder dead, out of range, or released; `herder.herded_count -= 1`; `_clear_herd()`.
- **Claim conversion**: When herded NPC enters claim radius (400px), ownership becomes permanent (clan).
- **Herd stealing**: Other caveman within range can take over herd (proximity-based).

### 4.9 Task System

- **Tasks**: Atomic – MoveTo, Gather, DropOff, PickUp, Occupy, Wait, etc.
- **Job**: Ordered list of tasks; data only.
- **TaskRunner**: On NPC; runs `current_job` / `current_task`; `tick()` → RUNNING/SUCCESS/FAILED; cancel on interrupt (combat, defend, etc.).
- **Job generation**: Land claim / buildings expose jobs; NPCs pull (e.g. “do you have work?”); no building-to-NPC assignment.
- **Resource capacity**: Prevents too many NPCs on same resource node.

### 4.10 ClanBrain (AI strategy)

- **Owner**: One `ClanBrain` per land claim (RefCounted); updated in land_claim `_process`.
- **Evaluation**: Every ~5s; threat cache ~30s; strategic state: PEACEFUL, DEFENSIVE, AGGRESSIVE, RAIDING, RECOVERING.
- **Defense**: Computes defender need from threat/distance; sets defender quota; NPCs self-assign to Defend state.
- **Searchers**: Sets searcher quota for finding wild NPCs/resources; NPCs self-assign to Search/HerdWildNpc.
- **Raids**: Evaluates raid opportunity (cooldown, resources, weak enemies); raid state machine: PLANNING → ASSEMBLING → MOVING → ENGAGING → LOOTING → RETREATING → COMPLETE; sets raid_intent; NPCs self-assign to Raid state and follow raid target/positions.
- **Resources**: Tracks clan resources; `get_most_needed_resource()`, `get_gathering_priorities()`; `should_expand()`, `should_search_for_npcs()`, `get_clan_strength()`.

### 4.11 Reproduction & Baby Pool

- **ReproductionComponent**: Women; pregnancy/birth timer; mate detection in claim radius.
- **Birth**: Timer (e.g. 90s test) → spawn baby at claim center; baby type.
- **BabyGrowthComponent**: Timer (e.g. 1 min test / 13 years) → promote to clansman.
- **BabyPoolManager**: Capacity = base (3) + 5 per Living Hut; `can_add_baby()` currently always true (cap disabled); surplus babies would promote instantly when over cap (not enforced yet).

### 4.12 World & Resources

- **World**: Infinite scrolling 2D TileMap; gatherable nodes (trees, boulders, bushes, wheat).
- **GatherableResource**: Area2D; type (wood, stone, berries, wheat, etc.); tool requirement (axe, pick); depletion/respawn as designed (respawning infinite per GDD except relics).
- **Ground items**: Dropped items on ground (GroundItem); can be picked up.

### 4.13 Raiding (current)

- **Loot**: Open building/flag inventories (I); drag items out.
- **Combat**: Kill defenders; ClanBrain sends raiders to target claim.
- **Destroy flag**: Total wipe (inventory, baby pool, clansmen die, women/animals scatter) – per GDD; exact wipe behavior in code to be confirmed.

---

## 5. Detailed Implementation Report

### 5.1 Fully implemented

| System | Details |
|--------|--------|
| **Player** | Movement, 5-slot inventory + 10 hotbar, direct control, attack (with weapon), herding (right-click), eat (9/0). |
| **Combat** | CombatComponent (windup/hit/recovery), CombatScheduler, DetectionArea, CombatState, agro meter, attack arcs, stagger, weapon profiles, player combat, death, corpse, leader succession. |
| **Inventory** | Drag-and-drop everywhere; player/building/NPC/corpse/ground; visual feedback; single-item drag. |
| **Land claim** | Placement, 400px radius, inventory, build menu (I), building cards, clan ownership. |
| **Buildings** | BuildingRegistry, build menu UI, placement (drag from inventory, 50px buffer), Living Hut / Supply Hut / Shrine / Dairy Farm / Oven; Oven production (Wood+Grain→Bread 15s). |
| **NPC FSM** | Idle, Wander, Gather, Eat, Herd, HerdWildNpc, Combat, Defend, Raid, Build, Reproduction, Deposit, Search, etc.; priority-based; state blocking (e.g. combat_locked). |
| **NPC components** | Health, Combat, Weapon, Stats (hunger), Reproduction, BabyGrowth, DetectionArea; SteeringAgent (cached traits, herded_count, land claim cache, separation/avoid by intent). |
| **Tasks & jobs** | Task base, MoveTo, Gather, DropOff, PickUp, Occupy, Wait, etc.; Job; TaskRunner; job generation from claim/buildings; cancel on defend/combat/follow. |
| **ClanBrain** | Core brain, defense (defender quota), raids (raid state machine, raid_intent), searchers, strategic state, resource tracking, pull-based quotas. |
| **Reproduction** | ReproductionComponent/State; birth timer; baby spawn; BabyGrowthComponent; promotion to clansman. |
| **Herding** | Start/stop; herded_count on player/NPC; claim conversion; herd stealing; Phase 3 refactor (event-based count, no scan). |
| **Phase 3 refactor** | Cache NPC traits, cache land claims, herded_count, split separation/avoid by intent, intent delay, velocity smoothing, arrival offset, micro-wander; ClanBrain Phases 1–5. |
| **World** | TileMap, GatherableResource, resource types (wood, stone, berries, wheat, fiber); ground items. |
| **UI** | Player/building/NPC/corpse inventories; drag manager; hotbar numbers; building icons on claim; theme (colors, panels). |

### 5.2 Partially implemented

| System | Done | Missing / disabled |
|--------|------|--------------------|
| **Baby pool** | BabyPoolManager, capacity = 3 + 5×Living Huts | `can_add_baby()` always true; surplus promotion not enforced. |
| **Living Hut** | Building exists, placement | Baby cap increase commented out in `main.gd`. |
| **Building placement** | All 5 from menu, 50px rule | Living Hut → BabyPoolManager connection disabled. |
| **Woman assignment** | Occupy/WorkAtBuilding states exist | Disabled for Oven; no 1 woman per building. |
| **Resource respawning** | Gatherable nodes exist | Infinite respawn per GDD not fully confirmed in code. |
| **Age / species** | Structure/placeholders | No real age progression or hominid species. |
| **Flag upgrades** | GDD design | Flag → Tower → Keep → Castle not implemented. |
| **War Horn** | GDD design | H key not implemented. |
| **Stats / character menu** | Some UI scaffolding | No Tab stats panel; no full character/clan menu. |

### 5.3 Not implemented (from GDD / guides)

- **Generational permadeath**: Age 13 → 101; death; next generation take over.
- **Hominid species**: 5 species at bloodline start; 50/50 hybridization each generation.
- **Medic Hut**: Heal wounds with berries; hurt NPCs path to Medic Hut.
- **Wounds**: RimWorld-style body part damage / temporary HP reduction.
- **Farm**: Wool (sheep) / milk (goats) production.
- **Spinner / Dairy (production)**: Cloth from wool; cheese/butter from milk.
- **Armory / Tailor**: Weapons; armor, backpacks, travois.
- **Relics & Shrine**: Rare items; place in Shrine for clan-wide buffs; flag upgrades require relics.
- **Horses**: Riding, travois.
- **Predators**: Wolves, mammoths; hostile; loot.
- **Wild wheat rule**: Wheat grows only outside land-claim radius (GDD).
- **Foraging mode / knapping**: Future implementations (actions.md) – forage in area; knapping spots for blades/scrapers.

### 5.4 Script / scene summary (key files)

- **Player**: `player.gd`; `scenes/` + `ui/` for inventory.
- **NPC**: `npc_base.gd`, `fsm.gd`, `steering_agent.gd`; states in `npc/states/`; components in `npc/components/`; `detection_area.gd`.
- **Combat**: `combat_component.gd`, `health_component.gd`, `weapon_component.gd`; `systems/combat_scheduler.gd` (autoload).
- **AI**: `ai/clan_brain.gd`; `ai/task_runner.gd`; `ai/tasks/*.gd`; `ai/jobs/*.gd`.
- **Buildings**: `buildings/building_registry.gd`, `building_base.gd`, `oven.gd`; `scenes/Building.tscn`.
- **World**: `land_claim.gd`, `world.gd`, `gatherable_resource.gd`, `ground_item.gd`.
- **Systems**: `systems/baby_pool_manager.gd`, `systems/combat_scheduler.gd`.

---

## 6. References

- **gdd.md** – Official game design (single source of truth for vision).
- **phase1.md** – Phase 1 loop (land claim, herding, deposit, agro).
- **phase2.md** – Phase 2 (reproduction, buildings, combat, tasks, clan death).
- **Phase3/phase3.md** – Refactor + ClanBrain.
- **phase2/Task_system.md** – Tasks, jobs, modes, pull-based work.
- **Buildings.md** – Building list, placement, Oven.
- **items_guide.md** – Item catalog.
- **future implementations/main.md** – Combat design (windup, zones, morale, etc.).
- **future implementations/ai_clan_brain.md** – ClanBrain design detail.
- **IMPLEMENTATION_CHECKLIST.md** – Open items (min distance, AOA, deposit trigger, etc.).

---

*Last updated: February 2026. Update as mechanics and implementation change.*
