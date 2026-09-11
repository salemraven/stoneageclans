# Stone Age Clans – Main Mechanics & Implementation Report

**Date**: Sep 2026  
**Status**: Living **implementation** report (what ships in code). **Design canon:** `bible.md` + `bible/game_dictionary.md`. **Early-game vision (Tier 1 campfire, food, raids, horn):** [earlygame_vision.md](earlygame_vision.md). **Index:** `bible/README.md`. **World / streaming:** `bible/game_map.md`. **Hunting:** `bible/hunting.md`.

---

## 1. Core Fantasy & Win Condition

- **Fantasy**: Generational permadeath + brutal raiding. Build a bloodline that dominates the map through combat, resource management, and clan expansion.
- **Win condition**: Your bloodline completely dominates the map. Pure sandbox – no hard victory screen; domination is the goal.
- **Design mix**: Stoneshard (tactical combat, survival, inventory) + RimWorld (colony management, emergent storytelling, permadeath).

---

## 2. Gameplay Loop – Building Tribes & Fighting for Dominance

### Intended full loop

1. **Spawn** – No territory; gather and craft.
2. **Tier 1 Campfire** – First home: stash, herd into radius, **ABANDON CAMP** ([nomad.md](nomad.md)).
3. **Tier 2 Flag** – Settle: full radius, AoH, production buildings.
4. **Gather** – Forage, wood, stone, wild wheat.
5. **Build & produce** – Huts, Oven, Farm/Dairy ([farms.md](farms.md)).
6. **Expand** – Reproduction, baby pool, clansmen; *planned:* daughters → clanswomen ([female_baby.md](future%20implementations/female_baby.md)).
7. **Defend / Hunt / Raid** – ClanBrain quotas; player RTS; *planned:* cordage STEAL ([herdable_raiding.md](future%20implementations/herdable_raiding.md)).
8. **Dominate** – Generational sandbox win (bloodline on map).

**Design owner:** [earlygame_vision.md](earlygame_vision.md)

### Current loop (what works today)

1. Spawn (player + NPCs; no claim at start in SP).
2. **Campfire** and/or **flag** placement; Nomad Mode on campfire ([camp_relocation.md](camp_relocation.md)).
3. Gather (berries, wood, stone, wheat).
4. Build (Living Hut, Supply Hut, Shrine, Farm, Dairy, Oven, Drying Rack — tier-dependent).
5. Produce (Oven bread; Farm wool; Dairy milk; Drying Rack leather — see [farms.md](farms.md)).
6. Herd (**wild** herdables: proximity influence ~250px; context menu on NPCs — not instant right-click follow).
7. Combat, defend, raid (AI ClanBrain), hunt (AI + player RTS modes).
8. Reproduction (babies → **clansmen** only today).
9. Tasks (Gather, production_work, deposit, etc.).

---

## 3. What Players Can Do

### Controls (implemented)

- **WASD / Arrow keys** – Move.
- **I** – Open inventory (player + nearby building/corpse/land claim).
- **Tab** – Toggle player inventory.
- **9 / 0** – Consume item in hotbar slot 9 or 0.
- **Click NPC** – Attack (if weapon equipped).
- **Right-click NPC** – Context menu (Follow, Defend, Search, Work, Info). **Wild herdables:** influence attach when you walk within ~250px.
- **Right-click campfire** – **ABANDON CAMP**, INFO, etc. ([camp_relocation.md](camp_relocation.md)).
- **Right-click land claim / flag** – Context menu (INFO → inventory / build menu).
- **H** (War Horn) – Rally clansmen within ~1500 px (`RTS_CONFIG`); ordered follow + `command_context`. In **HUNT** mode, **H aborts** the hunt (does not rally). See `bible/rts.md`.
- **B** – Break ordered follow; clansmen return toward claim.
- **Box select / drag to player** – Multi-select clansmen; ordered follow (RTS).
- **PEACE / AGRO / HUNT** – Combat HUD modes when clansmen selected (`bible/Phase4/raiding_hunting.md`).

### Actions

- **Gather** – Walk to trees/boulders/berries/wheat; use axe/pick/hands; items go to inventory.
- **Craft land claim** – Wood + Stone + Berries + Leather (from inventory); carry and place in world.
- **Place buildings** – From build menu (I near claim): buy building with materials from claim inventory; drag building item onto world inside claim; 50px buffer between buildings.
- **Deposit / withdraw** – Drag-and-drop between player ↔ land claim ↔ buildings ↔ NPCs ↔ corpses ↔ ground.
- **Herding** – **Wild** women/sheep/goats: proximity **HerdInfluenceArea** (~250px) → follow → join clan in claim radius. Context menu for fighters (Follow/Defend/etc.). **Claimed enemy herdables:** cordage bond — planned ([herdable_raiding.md](future%20implementations/herdable_raiding.md)).
- **Combat** – Equip weapon (axe/pick); click enemy; windup → hit → recovery; loot corpse with I.
- **Eat** – Consume berries/grain/bread from inventory or hotbar slots 9/0.
- **Oven** – Open building inventory; add 1 Wood + 1 Grain; toggle Fire; wait 15s → Bread.

### Not yet (from GDD)

- Stats panel (Tab = full clan stats — Tab may toggle inventory today).
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
- **Herding**: Proximity influence on wild herdables; context menu for ordered follow on clansmen — see [HERDING_SYSTEM_GUIDE.md](HERDING_SYSTEM_GUIDE.md).

### 4.2 Territory (Tier 1 Campfire / Tier 2 Flag)

- **Tier 1 Campfire:** 250px, nomadic brain, Living Huts (max 3), **ABANDON CAMP**. See [nomad.md](nomad.md).
- **Tier 2 Flag:** Craft and place; 400px radius; AoH; full building set.
- **Clan death:** Flag destroy = wipe; herdables `become_wild()`; wild cavemen — planned ([clan_founding_and_exile.md](clan_founding_and_exile.md)).

### 4.3 Buildings

- **Registry**: `BuildingRegistry` — Living Hut, Supply Hut, Shrine, Farm, Dairy Farm, Oven, Drying Rack.
- **Production:** Oven, Farm, Dairy, Drying Rack use **OccupationSystem** + women ([farms.md](farms.md)).
- **Living Hut**: +5 baby pool capacity per hut (`BabyPoolManager`); **`enforce_baby_cap`** default off in dev.
- **Field (proto farming):** planned, flag-only ([proto_farming.md](future%20implementations/proto_farming.md)).

### 4.4 Inventory & Items

- **Drag-and-drop**: Everything: player ↔ flag ↔ buildings ↔ NPCs ↔ corpses ↔ ground. Single-item drag (one at a time).
- **Feedback**: Valid drop = gold highlight; invalid = red; source slot 50% opacity while dragging.
- **Item types**: Consumables (berries, grain, bread), resources (wood, stone, wheat, fiber), tools (axe, pick), buildings (land claim, huts, etc.). Corpse keeps dead NPC inventory + hotbar.

### 4.5 NPCs – Types & Roles

- **Cavemen**: Wild humans; can be herded; can place claims and become clan “leaders.”
- **Clansmen**: Promoted from babies or from surplus baby pool; full FSM (gather, herd, defend, raid, etc.).
- **Women**: Wild; herded into claim → claimed; reproduction only in claim radius.
- **Sheep / Goats**: Herd into claim for future production (wool/milk); no production logic yet.
- **Deer**: Wild prey (not herdable); **fright meter** + **`flee_prey`** when humans get close / loud sounds; migratory herds when using wild spawn (**`bible/wildlife_movement.md`**).
- **Babies**: Spawn from reproduction; grow to **clansmen** today. **Female babies planned** ([female_baby.md](future%20implementations/female_baby.md)).
- **Predators / Horses**: Planned (wolves, mammoths; horses for riding/travois); not in.

### 4.6 NPC AI – FSM & States

- **FSM**: Priority-based; evaluates states every 0.1s; highest valid priority wins.
- **States (examples)**: Idle, Wander, Gather, Eat, Herd, HerdWildNpc, **FleePrey (deer)**, Combat, Defend, Raid, Build, Reproduction, Seek, Agro, Deposit, Search, WorkAtBuilding, OccupyBuilding, Craft.
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

- **Start**: Player walks into **HerdInfluenceArea** (~250px) or NPC `herd_wildnpc` search; `_try_herd_chance`; wild **`is_wild()`** only today.
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

- **Owner**: One `ClanBrain` per **territory** — `land_claim.gd` or `campfire.gd` (nomadic mode on campfire). RefCounted; `update(delta)` each frame.
- **Evaluation**: Every ~5s; `_update_pressures()`; threat cache ~30s; strategic state: PEACEFUL, DEFENSIVE, AGGRESSIVE, RAIDING, RECOVERING.
- **Defense / search**: Defender and searcher quotas; pull-based Defend / HerdWildNpc.
- **Raids**: AI clans — `raid_intent`, party formation, `raid_state` (see `bible/ai_clan_brain.md`).
- **Hunts**: AI clans — AoH prey only (deer/mammoth); `hunt_intent` + `hunt_state`; skipped for player-owned claims and **survival mode** (&lt;2 fighters). See `bible/hunting.md`.
- **Metrics**: `calories_days_buffer`, `calories_in_storage`, `calories_daily_need`, meat/hide, population — drive pressures and weights.
- **Full detail**: `bible/ai_clan_brain.md`, `bible.md` §XVI.

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
- **Destroy flag**: **Territory wipe** (inventory, buildings gone; herdables scatter wild). **Wild cavemen** / founder — **planned** ([clan_founding_and_exile.md](clan_founding_and_exile.md)).

---

## 5. Detailed Implementation Report

### 5.1 Fully implemented

| System | Details |
|--------|--------|
| **Player** | Movement, inventory + hotbar, direct control, attack (with weapon), herd wild NPCs via **proximity influence**, eat (9/0). |
| **Combat** | CombatComponent (windup/hit/recovery), CombatScheduler, DetectionArea, CombatState, agro meter, attack arcs, stagger, weapon profiles, player combat, death, corpse, leader succession. |
| **Inventory** | Drag-and-drop everywhere; player/building/NPC/corpse/ground; visual feedback; single-item drag. |
| **Land claim** | Placement, 400px radius, inventory, build menu (I), building cards, clan ownership. |
| **Buildings** | BuildingRegistry, build menu UI, placement (drag from inventory, 50px buffer), Living Hut / Supply Hut / Shrine / Dairy Farm / Oven; Oven production (Wood+Grain→Bread 15s). |
| **NPC FSM** | Idle, Wander, Gather, Eat, Herd, HerdWildNpc, **flee_prey (deer)**, **hunt_state (NPC clans vs AoH prey)**, Combat, Defend, Raid, Build, Reproduction, Deposit, Search, etc.; priority-based; state blocking (e.g. combat_locked). |
| **NPC components** | Health, Combat, Weapon, Stats (hunger), Reproduction, BabyGrowth, DetectionArea; SteeringAgent (cached traits, herded_count, land claim cache, separation/avoid by intent). |
| **Tasks & jobs** | Task base, MoveTo, Gather, DropOff, PickUp, Occupy, Wait, etc.; Job; TaskRunner; job generation from claim/buildings; cancel on defend/combat/follow. |
| **ClanBrain** | Per territory (flag + campfire): defense, search, raids, **hunts** (AI), pressures, metrics; pull-based quotas. |
| **RTS** | War Horn rally, PEACE/AGRO/HUNT, formations, Break — `bible/rts.md`. |
| **Chunk world** | `ChunkUtils`, streaming, seed — `bible/game_map.md`. |
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
| **NPC hunt tuning** | AoH + hunt wired | Food buffer, party disband, hunt frequency — see `bible/clanbrain_report.md`. |
| **Player hunt modes** | HUD + stances | Spear ambush throw may be partial. |
| **Multiplayer** | Stubs | `bible/multiplayer.md`, `bible.md` §XX-A. |
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
- **World**: `land_claim.gd`, `world.gd`, `gatherable_resource.gd`, `ground_item.gd`; streamed filler: **`WorldGenConfig`**, **`ChunkManager`**, **`ChunkGenerator`**, **`MutationStore`** (`mutation_store.gd`).
- **Chunk streaming (map load / procedural filler)**: **`bible/game_map.md`** — `ChunkManager`, `ChunkGenerator`, `WorldGenConfig`, `MutationStore`, spawn toggle.
- **Systems**: `systems/baby_pool_manager.gd`, `systems/combat_scheduler.gd`.

---

## 6. References

- **bible.md** – Consolidated lore + mechanics + code map (this folder).
- **bible/README.md** – Index of all guides.
- **game_dictionary.md** – Terminology.
- **hunting.md** – Hunting hub (NPC + player).
- **ai_clan_brain.md** – ClanBrain implementation.
- **gdd.md** – Vision GDD (verify numbers in code).
- **game_map.md** – Chunk streaming, world seed.
- **rts.md** / **Phase4/raiding_hunting.md** – Player orders + hunt stances.
- **clanbrain_report.md** – Standard AI playtest report.
- **multiplayer.md** – MP roadmap.
- **phase1.md**, **phase2.md** – Historical phase notes.
- **future implementations/** – Aspirational only (`bible.md` §XXII).

---

*Last updated: September 2026. **Vision:** [earlygame_vision.md](earlygame_vision.md). Prefer `bible.md` + this file over stale phase checklists and `future implementations/main.md`.*
