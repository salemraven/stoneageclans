# Lag & performance — what we know

**Purpose:** Single reference for **how lag shows up in Stone Age Clans today**, **how to measure it**, **what is already built to scale**, and **what to do when we start a performance pass**. This doc does **not** mean a lag fix is scheduled — it captures evidence and a roadmap so future work is deterministic, not guesswork.

**Last updated:** August 2026  
**See also:** [tools/README.md](../tools/README.md) (profiler commands), [bible/game_map.md](../bible/game_map.md) (chunks/streaming), [bible/multiplayer.md](../bible/multiplayer.md) (MP authority model), [bible/settlement_sim.md](../bible/settlement_sim.md) (actor sleep vs living villages), [pawn_goal.md](pawn_goal.md) (layered character vision), [animation_tuner.md](animation_tuner.md) (bake pipeline)

---

## TL;DR

- A normal **Main** run with full spawns is already heavy: **~7–8 FPS** (~133ms/frame) on dev hardware (Aug 2026 profile).
- The main cost is **world density + physics overlap checks**, not recent features like death fall direction or spear windup.
- The fix path for more players/NPCs/resources is **simulate less at once** (interest management, sleep/despawn, chunk lifecycle) — not micro-optimizing animation tweaks.
- **Actor sleep must not freeze villages** — off-screen clans keep simulating at settlement granularity on the **same continuous map** ([settlement_sim.md](../bible/settlement_sim.md)).
- **Layered characters** (hair, eyes, clothing, etc.) are mostly **not shipped yet**; when they land, **render cost scales with visible pawns × layer count** — plan LOD/baking from the start (see [Layered pawn visuals](#layered-pawn-visuals-hair-face-clothing)).
- Always **profile before and after** any performance change (`--lag-profile` + analyzer).

---

## Baseline measurement (Aug 2026)

Captured with `bash tools/run_lag_profile_capture.sh` (25–60s on `Main.tscn`, full NPC/resource spawn). Steady state = intervals after ~3s with no chunk loads in that second.

| Metric | Value | Notes |
|--------|-------|--------|
| **FPS** | ~7.5 | Target for smooth play: 60 FPS (~16.7ms/frame) |
| **Frame time** | ~133ms avg | |
| **Physics** | ~65ms (~48% of frame) | Godot `TIME_PHYSICS_PROCESS` |
| **Process scripts** | ~51ms (~38% of frame) | Godot `TIME_PROCESS` |
| **NPCs in scene** | ~140 | Most far from player; many partially dormant |
| **Resource nodes** | ~1,298 | ~1,035 gatherables, ~262 ground items |
| **Collision pairs** | ~1,588 | See [Collision pairs ≠ wall bumps](#collision-pairs--wall-bumps) |
| **Procedural arms** | 0 ticks/sec | Disabled in Main — not a bottleneck |
| **Gatherable `_process`** | 0 ticks/sec | Spatial gather path — not a bottleneck |
| **NPC physics ticks** | ~461/sec | Partial dormancy vs full budget (~140 × 60 ≈ 8,400) |
| **Boot chunk loads** | ~25 chunks | Slowest single load ~256ms — causes startup hitches |

**Not implicated in this baseline:** pawn death animation, weapon overlay combat poses, procedural limb animation (all disabled or negligible in profile).

Re-run and refresh this table when hardware, spawn config, or dormancy behavior changes.

---

## How to measure (mandatory before fixes)

### Capture

```bash
# GUI play + log to user://lag_profile_*.jsonl (default 60s)
bash tools/run_lag_profile_capture.sh

# Shorter capture
LAG_PROFILE_SECONDS=25 bash tools/run_lag_profile_capture.sh

# Manual
SKIP_SINGLE_INSTANCE=1 godot --path . res://scenes/Main.tscn --lag-profile
```

Logs land in Godot **user data** (`user://lag_profile_YYYYMMDD_HHMMSS.jsonl`). On macOS, open via Editor → Project → Open User Data Folder.

### Analyze

```bash
godot --headless --path . -s res://tools/analyze_lag_profile.gd
# or pass a specific file:
godot --headless --path . -s res://tools/analyze_lag_profile.gd -- path/to/lag_profile.jsonl
```

Prints steady-state FPS, bottleneck breakdown, and **ranked fix recommendations** with scores.

### What each interval row tracks

From `scripts/debug/lag_profiler.gd`:

- Frame avg/max, spike count
- Engine physics ms, process ms, draw calls
- `physics_2d_collision_pairs`, active objects, islands
- World composition: resources, gatherables, ground items, NPC distance buckets
- Areas monitoring (resources + perception + land claim zones)
- Hot-path counters: NPC physics/FSM, perception, gatherable `_process`, procedural arms
- Chunk load/unload counts and timing

Enable via `--lag-profile` or `DebugConfig.enable_lag_profiling`.

---

## What “lag” means in this project

Three different problems get lumped together:

1. **Steady-state FPS** — every frame too slow while standing still or walking (baseline above).
2. **Hitches / spikes** — one frame takes 200ms+ (often chunk load, big spawn burst, or combat spike).
3. **Multiplayer scale** — server or clients can't keep up when player count, NPC count, or loaded area grows.

The architecture targets **#3** via server authority + interest management. **#1** is the current dev pain on a dense single-player Main run.

---

## Root causes (evidence-based)

### 1. Too many live nodes in the loaded bubble

`WorldGenConfig.resource_density_multiplier` is **2.5×** on top of per-chunk counts (`resources_per_chunk`, tree groups, ground items, tallgrass). With `single_player_initial_load_radius = 2`, many chunks load at once → **~1,300 resource nodes** in tree.

Each node has draw cost, script hooks, and registration in `ResourceIndex`.

### 2. Physics overlap work (collision pairs)

Even with **walk-through** movement (`collision_mask = 0` on NPCs, gatherables not using Area2D for player gather):

- **~140 `CharacterBody2D` NPCs** remain physics shapes on layer 2.
- **PerceptionArea** and **HerdInfluenceArea** on awake NPCs use `monitoring = true`.
- **Land claims** have AoH + enemy zones (`set_sim_zones_monitoring` when claim is "active").

Godot's **`PHYSICS_2D_COLLISION_PAIRS`** counts shape pairs that *might* interact (overlap sensors included), not "how many wall bumps."

### 3. NPCs exist as full nodes when far away

`SimDormancyController` turns off `_physics_process` and perception for distant NPCs, but **the CharacterBody2D still exists** in the scene tree unless `NPCSleepManager` despawned it.

Partial dormancy helped (~461 phys ticks/sec vs ~8,400 if all ran at 60Hz) but **~140 bodies + awake perception on nearby NPCs** still scale poorly.

### 4. Boot / chunk load spikes

Initial load pulls many chunks; individual chunk generation can take **100–250ms+**. Separate from steady FPS but feels like lag when moving into new areas.

### 5. Script process time

~51ms/frame in `_process` / game logic — FSM, ClanBrain, UI, world systems. Scales with awake NPC count and active jobs. Less documented than physics in the Aug 2026 capture; profile again after NPC sleep hardening.

### 6. Layered pawn visuals (future multiplier)

Not the main bottleneck **today**, but must be planned before we add full face/clothing stacks on every NPC. **Canonical plan:** [character_layers.md](character_layers.md). See also [Layered pawn visuals](#layered-pawn-visuals-hair-face-clothing).

---

## Layered pawn visuals (hair, face, clothing)

Each character is meant to be built from **many sprite layers** (hair, eyes, nose, mouth, beard, clothing, armor, jewelry, scars, etc.) — not one baked sprite sheet. That is core to identity and genetics ([pawn_goal.md](pawn_goal.md)).

### What ships today vs what is planned

| Stage | Per pawn (approx.) | Notes |
|-------|-------------------|--------|
| **Today — layered mannequin** | Body + head + weapon overlay | `TunerBodyVisual` under `Sprite/BodyVisual`; ~3–4 draw sprites |
| **Today — legacy baked card** | 1 card texture + weapon | Women/babies still on baked cards |
| **Today — procedural arms** | + many arm/hand layers | **`PROCEDURAL_MANNEQUIN_ENABLED_IN_GAME = false`** in Main — too expensive for now |
| **Planned — full identity stack** | **15–30+ layers** | Face parts, hair, clothing, equipment each as `Sprite2D` on pivots (see pawn hierarchy in pawn_goal) |

The Aug 2026 profile ran with **body+head only** and **procedural arms off**. Lag numbers above **do not yet include** a full hair/eyes/clothing stack on ~140 NPCs.

### What each layer costs

Three separate costs — sim dormancy only fixes the first two partially:

| Cost type | What grows | Dormant NPC | Sleeping NPC (despawned) |
|-----------|------------|-------------|---------------------------|
| **Simulation** | Physics body, perception, FSM | Reduced (physics off) | **Zero** (no node) |
| **Scripts** | Walk bounce, head bob, weapon overlay, future face idle | Still runs if node exists & ticks | **Zero** |
| **Rendering** | One **draw call per visible sprite layer** (typical 2D) | **Still draws if on screen** | **Zero** |

Plain English: an NPC far away can stop "thinking" but if they're still on your screen with 20 face layers, the GPU still draws 20 sprites.

**Rough future math (order of magnitude):**

- 40 visible pawns × 20 cosmetic layers ≈ **800 character draw calls** (before trees, UI, world)
- Same scene today with body+head only ≈ **~120–160** character draw calls for those pawns

Always re-measure with `engine_draw_calls` in the lag profiler — do not trust estimates after art lands.

### Design already acknowledges this

From [pawn_goal.md § Performance Strategy](pawn_goal.md#performance-strategy):

- Start with **layered Sprite2D** for iteration and genetics.
- If needed, **bake appearance layers into combined textures** after generation (fewer draw calls, same look).
- [animation_tuner.md](animation_tuner.md) documents headless **bake** (`run_limb_tuner.sh bake`) as the bridge today.

That matches the world-scale rule here: **full detail only where it matters** (near camera / story-important pawns).

### Mitigations to plan (not all built)

| Strategy | Purpose | Status |
|----------|---------|--------|
| **NPC sleep / despawn** | No node = no layers, no draw | Partial — `NPCSleepManager` wired on chunk unload |
| **Sim dormancy** | Cheaper AI/physics off-screen | Live — `set_sim_dormant()` |
| **Visual LOD tiers** | Far pawns → baked portrait / fewer layers | **Not built** — sim dormancy ≠ visual simplification |
| **Distance cull for detail** | Drop hair/face layers beyond N px | Pattern exists: `NPC_ARM_CULL_DISTANCE_PX` (1400) for procedural arms |
| **Runtime bake per pawn** | Combine stable layers to one texture when outfit locked | Tooling direction (tuner bake); not in Main loop |
| **Headless dedicated server** | Server never draws pawns | MP target — clients render only |
| **Cap "hero" full layers** | Clan leaders, player party, nearby enemies get full face; crowd gets baked | Design rule to enforce in code |
| **Procedural arms gated** | Full IK arms only in tuner / heroes | **`PROCEDURAL_MANNEQUIN_ENABLED_IN_GAME = false`** |

### Recommended visual budgets (when layers ship)

Add to perf gates alongside physics budgets:

| Metric | Starting target | Notes |
|--------|-----------------|-------|
| **Full-detail pawns on screen** | ≤ 15–25 | All face/clothing layers active |
| **Baked/LOD pawns on screen** | ≤ 80 | Single texture or body+head only |
| **Draw calls (whole frame)** | Track trend; flag if >2× baseline after layer pass | From `engine_draw_calls` in profiler |
| **Pawn script tick cost** | No growth in `_tick_pawn_body_mannequin` per dormant NPC | Dormant should skip cosmetic ticks |

### When implementing layers

1. **Profile with layers on** using the same Main preset — update baseline table in this doc.
2. **Never add layers globally** without a LOD or bake path for distant/crowd pawns.
3. **Hook visual LOD to camera distance**, not only sim wake radius (`sim_wake_player_radius_px` is 450px — smaller than arm cull at 1400px).
4. **Server / MP:** replicate **appearance seed + equipment IDs**, not per-layer transform every frame.
5. **Prefer bake on stable outfits** (clansmen in fixed clan gear) over 20 live layers forever.

---

## Collision pairs ≠ wall bumps

| Design choice | Where | Effect |
|---------------|-------|--------|
| NPCs don't block each other / world | `npc_base.gd` — `collision_mask = 0` | No push-back; **body still in physics** |
| Player often no collision | `main.gd` spawn | Same |
| Gather uses spatial query | `ResourceIndex` + `main.gd` | Trees/ground items: **`monitoring = false`** for player gather |
| Distant claim zones sleep | `SimDormancyController` → `land_claim.set_sim_zones_monitoring` | Reduces pairs when claim far from players |

**Takeaway:** lowering pairs means **fewer shapes in the sim** or **fewer monitoring Area2Ds**, not tweaking walk-through masks.

---

## Architecture already in place (scale foundation)

These systems exist; the gap is **how aggressively** they are applied and **MP server-only** discipline.

| System | Autoload / path | Role |
|--------|-----------------|------|
| **ChunkManager** | `scripts/world/chunk_manager.gd` | Load/unload chunk content; stagger via `chunks_load_per_frame` |
| **WorldInterestManager** | `scripts/systems/world_interest_manager.gd` | Which chunks are loaded vs **sim-active**; which land claims are active |
| **SimDormancyController** | `scripts/systems/sim_dormancy_controller.gd` | NPC dormancy; claim zone monitoring; server-only when MP peer active |
| **NPCSleepManager** | `scripts/systems/npc_sleep_manager.gd` | **Tier-B:** serialize NPC → `queue_free`; wake via `spawn_npc_from_sleep_data` |
| **ResourceIndex** | `scripts/systems/resource_index.gd` | O(grid) gather queries — no per-tree Area2D for player |
| **DecorIndex** | `scripts/systems/decor_index.gd` | Same pattern for decor |
| **WorldGenConfig** | `scripts/config/world_gen_config.gd` | Density, load radius, sim wake radius, MP tiers |
| **MutationStore** | `scripts/world/mutation_store.gd` | Server-owned world deltas (chopped, picked up, built) |
| **LagProfiler** | `scripts/debug/lag_profiler.gd` | JSONL capture |
| **analyze_lag_profile** | `tools/analyze_lag_profile.gd` | Ranked recommendations |

### Interest model (today)

- **Loaded chunks:** radius from `get_effective_load_radius()` (SP: at least `single_player_initial_load_radius = 2`).
- **Sim-active chunks:** `sim_active_chunk_radius` (default 1) — smaller ring for "full sim."
- **NPC wake:** `sim_wake_player_radius_px` (default **450px**) — idle NPCs wake on **player proximity**, not whole sim-active ring.
- **Claims active:** within `CLAIM_ACTIVE_WORLD_RADIUS` (2400px) of any player.

### NPC dormancy tiers

| Tier | Behavior | Implementation |
|------|----------|------------------|
| **Awake** | Full physics, perception, herd influence | `set_sim_dormant(false)` |
| **Dormant** | No physics/perception; node still exists | `SimDormancyController` |
| **Sleeping** | No node; data in `NPCSleepManager` | `sleep_npc` / `sleep_npcs_in_chunk` on chunk unload |

Chunk unload calls `NPCSleepManager.sleep_npcs_in_chunk`; chunk load calls `wake_npcs_in_chunk`. Wild migratory and combat NPCs are exempt from sleep (by design).

### Resource monitoring

`SimDormancyController._apply_resource_monitoring` exists but is **not called** from `apply()` — comment says gather uses ResourceIndex. Gatherables/ground items default `_sim_monitoring_enabled = false`. Good for gather; land claims and NPC perception remain the physics focus.

---

## Config knobs (`WorldGenConfig`)

Quick tests (change one at a time, re-profile):

| Field | Default | Performance lever |
|-------|---------|-------------------|
| `resource_density_multiplier` | 2.5 | Lower → fewer trees/items per chunk |
| `single_player_initial_load_radius` | 2 | Lower → fewer chunks at boot |
| `chunk_load_radius_base` | 1 | MP base load radius |
| `sim_active_chunk_radius` | 1 | Smaller → less "full sim" area |
| `sim_wake_player_radius_px` | 450 | Smaller → fewer awake NPCs |
| `chunks_load_per_frame` | 6 | Lower → smoother boot, slower fill |
| `chunks_unload_per_frame` | 3 | Tune unload vs memory |
| `load_radius_tier_3_value` | 0 | For 50+ players — shrink loaded area |
| `resources_per_chunk`, tree/grass counts | various | Direct spawn caps |

**Important:** density affects **resources/trees/grass**, not clan or migratory wildlife rolls (see field comments in `world_gen_config.gd`).

---

## Analyzer-ranked fix paths

`tools/analyze_lag_profile.gd` scores these (higher = more likely to help given current metrics):

| ID | Title | When it scores high |
|----|-------|---------------------|
| `npc_sleep_wake` | NPC sleep/wake by chunk interest | Many NPCs, high physics %, far NPC ratio high |
| `area_monitoring_sleep` | Sleep Area2D monitoring on distant entities | High `areas_monitoring`, high collision pairs |
| `world_density_config` | Lower world density / load radius | resources ≥ ~1200, frame ≥ ~100ms |
| `boot_chunk_stagger` | Stagger boot chunk loading | Many chunk_load events at startup |
| `resource_process_sleep` | Gatherable `_process` sleep | High gatherable tick count (currently low) |
| `perception_script_cost` | Perception `_process` overhead | Many perception ticks vs NPC count |

Aug 2026 capture ranked **NPC sleep**, **area monitoring**, and **world density** highest.

---

## Multiplayer strategy (when we scale)

**Core rule:** Server simulates gameplay; clients send commands and render state.

| Concern | Approach |
|---------|----------|
| **Authority** | Sim on server only (`SimDormancyController` already skips clients when MP peer active) |
| **Interest** | Union of all player positions → loaded chunks; **smaller radius** as player count rises (`get_effective_load_radius`) |
| **NPCs** | Hot = full node near any player; cold = sleep data; clan AI at **ClanBrain** level where possible |
| **Resources** | Seed + chunk spawn; **mutations** authoritative; despawn on chunk unload |
| **Bandwidth** | Events/deltas, not per-frame full state (`expected_bandwidth_per_player_kb_s` stub in config) |
| **Determinism** | `world_seed + chunk_coords` for placement; no bare `randf()` for world layout |

**Known MP gaps** (also in `bible/game_map.md` §16):

- Chunk interest may not yet union all peers correctly in all paths
- No preload before spawn on join
- Full gatherable replication still stubby

More players should mean **smaller hot zones per server**, not loading the entire world for everyone.

---

## Recommended roadmap (when we start a perf pass)

Document-only priority order — **do not implement ad hoc tweaks without profiling.**

### Phase A — Prove a budget (single-player)

- Pick targets: e.g. **≥30 FPS** with **≤40 awake NPCs** and default chunk load on dev machine
- Lower dev-only density/radius temporarily to hit budget while wiring sleep
- Add a `--perf-playtest` or documented spawn preset for repeatable captures

### Phase B — Harden interest & sleep

- Aggressive dormant → sleep for off-screen clan **actors** (not settlement state — see [settlement_sim.md](../bible/settlement_sim.md))
- Ensure chunk unload always sleeps eligible NPCs; verify wake on re-entry
- Land claim zones off when claim inactive (partially done)
- Audit: no global loops over all NPCs every frame (project rule)

### Phase C — Resource lifecycle

- Props only exist in active chunks; state in MutationStore
- Resolve double-density paths (legacy ground spawn near player vs chunk ground items — see game_map gaps)
- MP density tier separate from SP lush dev settings

### Phase D — Multiplayer server

- Server-only sim paths verified
- Per-peer interest union in ChunkManager streaming
- NPC/resource counts scale with **awake** entities, not world population

### Phase E — Layered pawn visuals

- Define **visual LOD tiers** (full layers / body+head / baked card / hidden)
- Wire distance cull for cosmetic layers (extend `NPC_ARM_CULL_DISTANCE_PX` pattern)
- Bake pipeline for stable outfits; hero-only full stacks for party/leaders
- Profile `engine_draw_calls` with representative layer counts before merging art

### Phase F — Content within budget

- Add clans, wildlife, and density **inside** measured budgets
- ClanBrain / party-level AI instead of per-NPC heavy logic where possible

---

## Performance budget (proposed targets)

Use as gates for future PRs — adjust after first optimized baseline:

| Metric | Dev SP target | Notes |
|--------|---------------|--------|
| Steady FPS | ≥ 30 (stretch 60) | Main, standard playtest spawn |
| Frame time | ≤ 33ms (stretch 16.7ms) | |
| Physics share | ≤ 35% of frame | If higher, pairs/NPC bodies first |
| Awake NPC nodes | ≤ 40 | Full CharacterBody2D + perception |
| Resource nodes (loaded) | ≤ 600 | Tunable via density + radius |
| Collision pairs | ≤ 800 | Profile on same preset |
| Chunk load spike | ≤ 50ms | Per chunk after stagger |
| Full-detail pawn layers (on screen) | ≤ 25 | When hair/face/clothing ship |
| `engine_draw_calls` | Record baseline; no >2× after layer pass | Per lag profiler interval |

Always record **machine, date, seed, and config** next to numbers in this doc or in commit messages.

---

## What is unlikely to help much

- Tuning spear windup pixels, death fall rotation, or weapon overlay order (already profiled as negligible vs world load)
- Re-enabling procedural arms in Main without a LOD/dormancy plan
- Adding blocking collision "to simplify physics" — design is intentionally walk-through
- Randomly lowering `server_tick_rate` without measuring sim correctness

---

## Related files

| Area | Path |
|------|------|
| Profiler | `scripts/debug/lag_profiler.gd` |
| Analyzer | `tools/analyze_lag_profile.gd` |
| Capture script | `tools/run_lag_profile_capture.sh` |
| Dormancy | `scripts/systems/sim_dormancy_controller.gd` |
| NPC sleep | `scripts/systems/npc_sleep_manager.gd` |
| Interest | `scripts/systems/world_interest_manager.gd` |
| Chunks | `scripts/world/chunk_manager.gd` |
| Config | `scripts/config/world_gen_config.gd` |
| NPC dormant API | `scripts/npc/npc_base.gd` — `set_sim_dormant()` |
| Gatherables | `scripts/gatherable_resource.gd`, `scripts/ground_item.gd` |
| Dormancy test | `tools/test_visual_sim_layer.gd`, `tools/count_sim_dormancy.gd` |
| Settlement sim (design) | [bible/settlement_sim.md](../bible/settlement_sim.md) |
| Layered pawn (today) | `scripts/tools/tuner_body_visual.gd`, `scripts/systems/placeholder_card_service.gd` |
| Layer vision | [guides/pawn_goal.md](pawn_goal.md) |
| Bake / tuner | [guides/animation_tuner.md](animation_tuner.md) |

---

## Changelog

| Date | Change |
|------|--------|
| Aug 2026 | Link wildlife_migration.md (seasonal cross-plane herds) |
| Aug 2026 | Initial doc from lag profile session + codebase audit; no perf code changes |
