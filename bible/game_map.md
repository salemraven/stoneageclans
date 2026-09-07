# Game map — complete guide

**Purpose:** Single reference for **everything about the world map**: how the scene is laid out, coordinates, **chunk streaming**, procedural fill, NPC/world interaction, spatial queries, legacy spawn paths, multiplayer hooks, and where to tune or extend behavior.

**Last updated:** September 2026 · **Chunk constants:** `bible.md` §II · **Index:** `bible/README.md`

**Status:** Living doc — update when `Main`, `ChunkManager`, `ChunkGenerator`, `WorldGenConfig`, or world-related scenes change. **Authored island progress:** [island_map.md](island_map.md) §1c. **Climate Change (Phase 6):** [environment_goal.md](environment_goal.md) §19.

**See also:** `bible/draw_order.md` (Y-sort / `WorldObjects`), `bible/main.md` (overall loop), `bible/game_dictionary.md` (terms), `bible/multiplayer.md` (network roadmap), `bible/hunting.md`, `bible/settlement_sim.md` (continuous plane + off-screen village sim), **`bible/environment_goal.md`** (shipping island — biomes, weather, resources, wildlife), `bible/island_map.md` (map2 art checklist).

---

## Table of contents

1. [What “the map” is in this project](#1-what-the-map-is-in-this-project)  
2. [Scene tree & rendering](#2-scene-tree--rendering)  
3. [Coordinates, chunk grid, and sizes](#3-coordinates-chunk-grid-and-sizes)  
4. [Systems that touch the map (autoloads)](#4-systems-that-touch-the-map-autoloads)  
5. [Chunk streaming (full flow)](#5-chunk-streaming-full-flow)  
6. [Deterministic generation (`ChunkGenerator`)](#6-deterministic-generation-chunkgenerator)  
7. [What gets spawned per chunk (`ChunkManager`)](#7-what-gets-spawned-per-chunk-chunkmanager)  
8. [WorldGenConfig — full field reference](#8-worldgenconfig--full-field-reference)  
9. [MutationStore](#9-mutationstore)  
10. [Spatial indexing & groups](#10-spatial-indexing--groups)  
11. [NPCs and the map (beyond chunks)](#11-npcs-and-the-map-beyond-chunks)  
12. [Legacy / non-chunk world content](#12-legacy--non-chunk-world-content)  
13. [Land claims, buildings, player](#13-land-claims-buildings-player)  
14. [Multiplayer & future work](#14-multiplayer--future-work)  
15. [Debugging & operations](#15-debugging--operations)  
16. [Known gaps (honest list)](#16-known-gaps-honest-list)  
17. [File index](#17-file-index)

---

## 1. What “the map” is in this project

- The game world is a **large 2D plane** in **pixels**. **Today:** no hard world border in code — infinite procedural chunks ([§16 gaps](#16-known-gaps-honest-list)). **Shipping target:** **one finite authored island** — ocean rim, wedge biomes, four river systems ([environment_goal.md](environment_goal.md), [island_map.md](island_map.md)).
- **Design lock:** **One continuous plane** — the player walks from their settlement to any other on the same map (not instanced colony maps like RimWorld / Dwarf Fortress). Settlements persist at fixed coordinates; sim fidelity tiers by distance ([settlement_sim.md](settlement_sim.md)).
- **Gameplay entities** (player, NPCs, gatherables, land claims, buildings, grass, corpses, etc.) live under **`Main` → `WorldObjects`**, which uses **Y-sorting** so depth looks correct when moving north/south.
- **Ground appearance** is mostly **not** the `World` TileMap’s tiles: **`world.gd`** documents that **DirtBase** (elsewhere in the scene) draws **repeating dirt**; the **TileMap** is reserved for optional overlays / collision, not procedural tile painting.
- **Optional chunk streaming** adds/removes **procedural** resources, trees, grass, ground piles, and **some** AI clans **based on player position** and a **world seed**.

---

## 2. Scene tree & rendering

Canonical structure (from `bible/draw_order.md` and `Main`):

```
Main
├── WorldLayer              ← floor / world backdrop (draws behind)
│   └── World (TileMap)     ← scripts/world.gd — chunk streaming entry calls here
├── WorldObjects            ← y_sort_enabled — all “things in the world”
│   ├── Player
│   ├── Resources           ← grouping container (not all nodes use it exclusively)
│   ├── LandClaims
│   └── … runtime: NPCs, chunk roots Chunk_x_y, grass, corpses, etc.
├── WorldArea               ← large Area2D for input / drop detection
└── UI (CanvasLayer)
```

**Rules of thumb**

- Anything that should **sort in the world** should end up under **`WorldObjects`** (directly or under a chunk root that is itself a child of `WorldObjects`).
- Use **`YSortUtils`** for foot-based draw order on sprites; do not invent new `z_index` rules (`bible/draw_order.md`).
- **Chunk roots** are named `Chunk_<cx>_<cy>` (chunk indices), with meta **`chunk_coords`** = `Vector2i(cx, cy)`.

---

## 3. Coordinates, chunk grid, and sizes

Defined in **`ChunkUtils`** (`scripts/world/chunk_utils.gd`):

| Constant | Value | Meaning |
|----------|--------|---------|
| `TILE_SIZE` | 64 | Tile art size (px); used elsewhere in the project. |
| `CHUNK_TILES` | 32 | Chunk width/height in tiles (conceptual). |
| **`CHUNK_SIZE`** | **2048** | Chunk width/height in **pixels** (= 64 × 32). |
| `ROAM_RADIUS` | `CHUNK_SIZE * 0.8` (~1638) | Default **wild NPC roam** radius (chunk-themed). |
| `HOME_UPDATE_TIME` | 30 s | How often some wild NPCs may refresh **home chunk** / wander anchor logic. |
| `CLAN_AVOID_RADIUS` | 600 | Used in wander / spacing logic near claims. |
| `WOMAN_CLAN_AVOID_RADIUS` | 800 | Slightly larger avoid radius for women vs claims. |

**Chunk index from world position**

- `ChunkUtils.get_chunk_coords(world_pos: Vector2) -> Vector2i`  
  `cx = floor(world_pos.x / CHUNK_SIZE)`, same for `y`.

**Chunk center (for spawn zones, etc.)**

- `ChunkUtils.get_chunk_center(chunk: Vector2i) -> Vector2`  
  Returns the **center pixel** of that chunk’s square.

**World seed**

- Stored on **`WorldGenConfig.world_seed`**.  
- If it is **0** on first **`ChunkManager.ensure_initial_load`**, it is set to **`randi()`** once so a run gets a random layout unless you set a fixed seed for reproducible tests.

---

## 4. Systems that touch the map (autoloads)

| Autoload | Role on the map |
|----------|------------------|
| **`ChunkUtils`** | Chunk math; roam-related constants; used by **`ChunkManager`**, **`ChunkGenerator`**, **`npc_base`**, **`wander_state`**, **`GameSync`**. |
| **`WorldGenConfig`** | All **tunable** chunk/streaming/MP/tick/stable-id settings (see §8). |
| **`MutationStore`** | **Per-chunk** mutation dictionary (currently **`clan_deaths`** per chunk key). |
| **`ChunkManager`** | **Load/unload** chunk roots; **instantiate** procedural content; **density timer** for extra clans. |
| **`ResourceIndex`** | **Spatial grid** (200 px cells) for fast “what resources are near here?” — gatherables and ground items **register** in `_ready` / **unregister** on free. |
| **`YSortUtils`** | **Draw order** for world sprites (feet-based). |
| **`BalanceConfig`** | **Non-chunk** spawn counts/radii for the **minigame** bootstrap (cavemen, women, animals, legacy resource radius). |
| **`GameSync`** | **MP:** spawn positions at **chunk centers** from `player_spawn_zones`; world snapshot RPC (seed + mutations). |

---

## 5. Chunk streaming (full flow)

### 5.1 Session bootstrap (chunk-only)

**All world content** is **chunk-seeded** — there is no legacy radius burst and no player-centered minigame ring.

**`SpawnManager.setup_npcs()`** flow:

1. Log **`session_started`** (PlaytestInstrumentor + UnifiedLogger).  
2. Run **`Main._try_run_dev_test_harness()`** if a dev flag/cmdline test is active (quickstart, agro test, `--repro-harness`, etc.).  
3. **Normal play:** place player at **`(0,0)`** (single-player) or **`Main.find_mp_spawn_location_for_peer()`** (online multiplayer — far from other players).  
4. **`ChunkManager.ensure_initial_load(main)`** — loads the disk around the player.  
5. Log **`spawn_flow_summary`**.

Per-chunk NPC rolls (deterministic from **`world_seed + chunk_coords`**):

| Content | Source |
|---------|--------|
| AI clans + claims | `ChunkGenerator` → `ChunkManager._spawn_clans` |
| Wild women | `ChunkGenerator` → `Main._spawn_wild_women_for_loaded_chunk` |
| Migratory wildlife | `Main._spawn_wildlife_for_loaded_chunk` |
| Resources / trees / grass | `ChunkGenerator` → `ChunkManager` |

Tune women: **`WorldGenConfig.wild_woman_chunk_chance`**, **`wild_woman_per_chunk_max`**.  
Tune MP spawn spacing: **`player_spawn_min_distance_px`**.

### 5.2 Binding `Main`

**`ChunkManager`** needs a reference to **`Main`** (as `Node2D`). **`ensure_initial_load(main)`** calls **`bind_main(main)`** so later **`update_streaming`** knows where **`world_objects`** and **`player`** live.

### 5.3 Initial load

1. Optionally assigns **`world_seed`** if still `0`.  
2. Reads **player** position.  
3. Computes **radius** = `max(get_effective_load_radius(), single_player_initial_load_radius)`.  
4. **Queues** every chunk in a **square** around that center chunk.  
5. Calls **`_process_pending_loads(true)`** → **unlimited** loads that frame (high budget) so startup fills quickly.

### 5.4 Every frame (while playing)

**`Main._process`** (after camera follow) calls:

```gdscript
world.ensure_chunks_for_position(player.global_position, delta)
```

**`world.gd`** forwards to **`ChunkManager.update_streaming(pos, delta)`**.

Inside **`update_streaming`**:

1. **`_queue_disk(center, r)`** — `r = get_effective_load_radius()`; enqueues missing chunks in the **square** \([-r..r]\) around the player’s chunk (FIFO `_pending_loads`).  
2. **`_process_pending_loads(false)`** — loads up to **`chunks_load_per_frame`** chunks.  
3. **`_process_unloads(center, r, delta)`** — builds **`want`** set: square of half-size **`r + chunk_unload_hysteresis`**. Any **loaded** chunk **not** in `want` starts a **grace timer**; after **`chunk_unload_no_interest_grace_ms`**, it is added to an unload list; up to **`chunks_unload_per_frame`** chunks are **`queue_free`**.  
4. **`_process_density_timer(delta)`** — accumulates time; every **`clan_density_check_interval_sec`**, may spawn a **density-fill** clan via **`Main`** (§7 / §11).

**Note:** This is **single-player interest** (player only). A future **multiplayer “union of all players’ interest”** is not implemented in `ChunkManager` yet; MP scaling today is mainly via **`get_effective_load_radius()`** tiers.

### 5.5 Chunk root lifecycle

- On load: create **`Node2D`** `Chunk_<cx>_<cy>`, `set_meta("chunk_coords", Vector2i(cx,cy))`, parent to **`Main.world_objects`**, store in **`_loaded`**.  
- On unload: **`queue_free`** that root → all children exit tree → **`GatherableResource` / `GroundItem`** unregister from **`ResourceIndex`** in their **`_exit_tree`**.  
- **`_clan_spawned_chunks`** tracks which chunk indices already spawned a **seeded** clan this session (for neighbor spacing); cleared on unload for that chunk.

---

## 6. Deterministic generation (`ChunkGenerator`)

**File:** `scripts/world/chunk_generator.gd` — **`RefCounted`** instance owned by **`ChunkManager`**.

**Output shape** (dictionary keys):

| Key | Type | Meaning |
|-----|------|---------|
| `resources` | `Array` of dicts | `type` (`ResourceData.ResourceType`), `position`, `stable_id` |
| `tree_groups` | `Array` of `Array` | Each inner array: tree dicts `position`, `tree_idx` 0–14, `stable_id` |
| `tallgrass_clusters` | `Array` of dicts | `points` (`Array` of `Vector2`), `has_bugs` (bool) |
| `ground_items` | `Array` of dicts | `position`, `stable_id` |
| `clans` | `Array` of dicts | `claim_center`, `caveman_offset`, `clan_name_seed` |

**RNG (determinism)**

- For each **layer** (resources, trees, grass, ground, clans) a **separate** `RandomNumberGenerator` is built:  
  `seed = hash(hash(Vector3i(world_seed, cx, cy)) + layer_salt)` so the same **(seed, chunk, layer)** is always identical.  
- **World origin** for that chunk’s local positions:  
  `(Vector2(chunk) * CHUNK_SIZE)` — i.e. chunk **(0,0)** occupies world rectangle **[0, 2048) × [0, 2048)** in pixels (before hysteresis / floating placement).

**Layer salting** (string names hashed with chunk): `res`, `trees`, `grass`, `ground`, `clans`.

**Probabilities & counts** — all read from **`WorldGenConfig`** via `cfg.get("...")` (see §8).

**Clan suppression before spawn**

- If **`MutationStore.get_clan_deaths_in_chunk(chunk) >= clan_max_deaths_per_chunk`**, **`ChunkManager`** clears **`clans`** for that load so **no new seeded clan** appears in an “exhausted” chunk (design hook for anti-farming).

### Pseudo-biome labels (off-screen gather only)

**Not player-facing biomes** — the map does not yet show forest/plains/swamp regions to the player. These labels exist only for **abstract off-screen gather** (`AbstractGather` → `ChunkGenerator.get_biome_available_resources()`).

| Method | Role |
|--------|------|
| `get_chunk_biome(world_seed, chunk_coords)` | Seeded roll: `forest`, `plains`, `rocky`, `swamp` |
| `BIOME_RESOURCE_KEYS` | Which abstract resource keys a dormant clan may pull from that chunk’s pool |

**Survivability rule (design lock 2026-09-05):** Until real biomes ship, no label may leave a clan with **zero edible gather options** for an entire run. Today **`rocky`** violates this (`stone`, `fiber` only). See [off_screen_clan_balance.md](future%20implementations/off_screen_clan_balance.md).

---

## 7. What gets spawned per chunk (`ChunkManager`)

**Gatherables** — scene `res://scenes/GatherableResource.tscn`; amounts match legacy **`Main._spawn_resource`** style per type; **`chunk_coords`** and optional **`stable_id`** meta.

**Trees** — `Node2D` wrapper in group **`decorative_trees`**; child **`GatherableResource`** WOOD with **`tree_sheet_index`**; positions use **`YSortUtils.tree_sort_offset_y`** like legacy forest spawn.

**Tall grass** — `Node2D` + `Sprite2D`; textures from `res://assets/sprites/tallgrass1.png` … `tallgrass6.png`; group **`tallgrass`**; **`YSortUtils.update_draw_order`**; optional **`has_bugs` / `bugs_remaining`** meta (subset of blades also roll extra bug placement at **spawn** time — not fully deterministic vs generator’s `has_bugs` flag).

**Ground items** — **`GroundItem.new()`** with a **`Sprite2D`** child; type cycles **STONE / WOOD / MUSHROOM** by `posmod(int(pos.x+pos.y), 3)`; groups **`ground_items`** + **`resources`** (see `ground_item.gd`).

**Seeded AI clan** — at most **one** pack per chunk from the generator list: calls **`Main.spawn_seeded_ai_clan_at(claim_center, cave_pos, clan_name, root)`** so **land claim + caveman** are parented under the **chunk root** (they unload with the chunk). **`NamingUtils.generate_landclaim_name_seeded(clan_name_seed)`** picks the clan string.

**Neighbor spacing**

- Before spawning, **`_neighbors_block_clan_spawn`** checks **`_clan_spawned_chunks`** within **`clan_min_spacing_chunks`** Chebyshev-ish square (all `dx,dy` except `0,0`). If any neighbor already spawned a clan, **skip** entire clan list for this chunk.

**Density fill** (not the same as seeded layout)

- **`Main.spawn_density_fill_clan_at_chunk(chunk, chunk_root)`** uses a **hash of (chunk, world_seed)** for RNG and name — used when the world is **too empty** near the player, not for strict per-chunk reproducibility.

---

## 8. WorldGenConfig — full field reference

**File:** `scripts/config/world_gen_config.gd`

### World

| Variable | Default | Role |
|----------|---------|------|
| `world_seed` | `0` | `0` → randomized on first chunk load unless you set it earlier. |

### Chunk load / unload

| Variable | Default | Role |
|----------|---------|------|
| `chunk_load_radius_base` | `1` | Base **half-width** in chunks (1 ⇒ 3×3) when adaptive tiers use “normal” radius. |
| `chunk_unload_hysteresis` | `1` | Extra **chunk layers** kept in the **`want`** set before unload eligibility (reduces edge flicker). |
| `chunk_unload_delay_sec` | `0` | Reserved / future; not driving a separate delay path in `ChunkManager` today. |
| `single_player_initial_load_radius` | `2` | **Minimum** half-size for **initial** disk (`max` with effective radius). |
| `chunks_load_per_frame` | `2` | Budget while **playing** (initial load uses “infinite” budget). |
| `chunks_unload_per_frame` | `3` | Max chunk roots freed per frame. |
| `chunk_unload_no_interest_grace_ms` | `500` | Time a chunk must stay **outside** the expanded `want` set before unload. |
| `chunk_defer_unload_if_npcs_active` | `true` | **Planned / config only** — `ChunkManager` does **not** yet consult this when unloading. |
| `chunk_defer_unload_if_player_building` | `true` | **Planned / config only** — same as above. |
| `wild_woman_chunk_chance` | `0.15` | Per-chunk roll for wild women. |
| `wild_woman_per_chunk_max` | `2` | Max women per chunk when roll succeeds. |
| `player_spawn_min_distance_px` | `3000` | MP join: minimum spacing from other players. |

### Adaptive radius (multiplayer-oriented)

| Variable | Default | Role |
|----------|---------|------|
| `adaptive_load_radius_enabled` | `true` | If `false`, always **`chunk_load_radius_base`**. |
| `load_radius_tier_1_players` | `5` | Up to this many peers+host ⇒ base radius. |
| `load_radius_tier_2_players` | `20` | Still base radius up to this count. |
| `load_radius_tier_3_players` | `50` | Above tier 2 up to this ⇒ tier 3 **value**. |
| `load_radius_tier_3_value` | `0` | **0** ⇒ **1×1** chunk (current chunk only) for high player counts. |

**Special case:** If **no** multiplayer peer is active, **`get_effective_load_radius()`** returns **`max(single_player_initial_load_radius, chunk_load_radius_base)`** so solo stays **generous**.

### MP spawn zones (chunk indices, not pixels)

| Variable | Default | Role |
|----------|---------|------|
| `player_spawn_grid_spacing` | `15` | Doc / spacing concept between zone entries (see zone list). |
| `player_spawn_zones` | 9× `Vector2i` | **Chunk coordinates** for spawn **centers** — **`GameSync`** converts with **`ChunkUtils.get_chunk_center`**. |

### Seeded clans (generator)

| Variable | Default | Role |
|----------|---------|------|
| `clan_spawn_chance` | `0.08` | Per chunk, probability of **one** clan entry in descriptor list. |
| `clan_min_spacing_chunks` | `2` | Don’t spawn seeded clan if another chunk with a clan exists within this **Manhattan square** (implementation: all offsets except self). |
| `clans_per_spawn` | `1` | Reserved for future multi-pack; generator emits at most one pack today. |

### Clan respawn / density (`ChunkManager` + `Main`)

| Variable | Default | Role |
|----------|---------|------|
| `clan_respawn_enabled` | `true` | Master switch for **density timer** checks. |
| `clan_respawn_delay_sec` | `300` | Config exists; **density** path uses **`clan_density_check_interval_sec`** for periodic checks (naming legacy). |
| `clan_max_deaths_per_chunk` | `3` | If **`MutationStore`** deaths ≥ this, **strip** `clans` from chunk generation on load. |
| `min_clans_per_player` | `2` | Target minimum **AI cavemen-with-claim** count near player. |
| `clan_check_radius_chunks` | `5` | Radius in **chunks** × **`CHUNK_SIZE`** for counting clans. |
| `clan_density_check_interval_sec` | `30` | How often density check runs. |
| `clan_respawn_avoid_player_chunk` | `true` | Prefer not to pick **player’s current chunk** as density-fill target. |

### Resources / trees / decor (generator)

| Variable | Default | Role |
|----------|---------|------|
| `resource_spawn_chance` | `0.55` | Chance the chunk gets **full** `resources_per_chunk` scatter. |
| `resources_per_chunk` | `10` | Count of gatherable nodes if chance passes. |
| `tree_group_chance` | `0.35` | Chance to emit **any** tree groups. |
| `tree_groups_per_chunk` | `2` | Number of **clusters**. |
| `trees_per_group_min` / `max` | `3` / `6` | Trees per cluster. |
| `tree_group_spread_radius` | `280` | Random offset radius within cluster. |
| `tallgrass_clusters_per_chunk` | `4` | Number of grass **clusters**. |
| `tallgrass_per_cluster_min` / `max` | `6` / `12` | Blades per cluster. |
| `ground_items_per_chunk` | `4` | Ground pile count. |

### Multiplayer / replication (light)

| Variable | Default | Role |
|----------|---------|------|
| `server_tick_rate` | `30` | Steps per “second” of tick accumulation on **server** (or solo). |
| `server_current_tick` | `0` | Monotonic counter. |
| `server_tick_accumulator_sec` | `0` | Fixed-step accumulator in `_process`. |
| `expected_bandwidth_per_player_kb_s` | `3.0` | **Design budget** only (not enforced by code here). |

### Stable IDs

| Variable | Default | Role |
|----------|---------|------|
| `stable_id_format` | `"%d_%d_%s_%d"` | **`generate_stable_id(chunk, layer, index)`** — for future MP / save correlation. |

**Methods**

- **`get_effective_load_radius() -> int`** — adaptive + solo rules above.  
- **`generate_stable_id(chunk, layer, index) -> String`** — printf-style stable string.  
- **`_process`** — advances **`server_current_tick`** when not a **multiplayer client**.

---

## 9. MutationStore

**File:** `scripts/world/mutation_store.gd`

- Keys: **`"%d,%d" % [chunk.x, chunk.y]`**.  
- Default record: `{ "clan_deaths": 0 }`.  
- **`record_clan_death(chunk)`** / **`get_clan_deaths_in_chunk(chunk)`** / **`reset_chunk(chunk)`**.  
- **`to_dict()` / `load_from_dict()`** — used by **`GameSync.receive_world_snapshot`** on clients.

**Wired (gameplay):** Clan extinction records **`clan_deaths`** once per wiped clan via **`LandClaim.try_record_clan_extinction(reason)`**:

| Reason | Trigger |
|--------|---------|
| **`soft_last_caveman`** | Last caveman dies and no clansmen remain (`health_component._handle_clan_death`) |
| **`flag_destroyed`** | Land claim HP/decay reaches zero (`land_claim._destroy_building`) |
| **`player_extinction`** | Player dies with no living heir (`main._handle_clan_extinction`) |

Double-count guard: static per-clan set on **`LandClaim`** so soft death + later flag destroy counts **once**. Instrumentation: **`PlaytestInstrumentor.clan_death`**, **`UnifiedLogger` `CLAN_DEATH` / `PLAYER_CLAN_EXTINCTION`**.

**Planned — wild cavemen / founder clans:** [clan_founding_and_exile.md](clan_founding_and_exile.md). Survivor-founded clans may bypass chunk death budget for **seeded** spawns but still respect **`max_ai_clans_*`** slot cap (not in code yet).

---

## 10. Spatial indexing & groups

### ResourceIndex

- **`CELL_SIZE` = 200** px.  
- **`register` / `unregister`** on node position; **`query_near`** (and variants) for tasks / AI.  
- **Chunk streaming is compatible:** nodes register when they enter the tree and unregister when chunks unload.

### Common groups (world-relevant)

| Group | Typical members |
|-------|------------------|
| `resources` | `GatherableResource`, **`GroundItem`** (also `ground_items`). |
| `ground_items` | Loose pickups. |
| `tallgrass` | Decorative grass nodes. |
| `decorative_trees` | Tree **wrapper** nodes (WOOD gatherable child). |
| `npcs` | All NPC scenes. |
| `player` | Player node (single primary). |
| `land_claims` | Claims (cached by **`Main.get_cached_land_claims()`**). |

### Static helper

- **`ResourceIndex.is_position_in_enemy_claim(land_claims, position, my_clan)`** — used for **raid / gather safety** checks; not chunk-specific.

---

## 11. NPCs and the map (beyond chunks)

### Player join (not minigame)

- **Single-player:** player spawns at **world origin** `(0,0)` with no claim or clan.  
- **Online multiplayer:** server assigns spawn via **`Main.find_mp_spawn_location_for_peer()`** (seeded, far from other players).  
- **Dev harnesses** (`DebugConfig` flags, `--repro-harness`, etc.) bypass normal spawn via **`Main._try_run_dev_test_harness()`**.

### Chunk-spawned NPCs

- **Seeded** and **density-fill** clans are parented under **`Chunk_*`** → **they disappear when that chunk unloads**. Design implication: **long-term persistence** of those clans would require **mutation / save** design or reparenting to a non-chunk node.

### Wild NPC home chunk (`npc_base.gd` + `ChunkUtils`)

Wild NPCs track **`home_chunk`**, **`chunk_center`**, **`roam_radius`** (often **`ChunkUtils.ROAM_RADIUS`**), and periodically refresh behavior with **`ChunkUtils.HOME_UPDATE_TIME`**. **`wander_state`** uses **`ChunkUtils`** avoid radii near claims. This is **orthogonal** to **ChunkManager** streaming: NPCs can walk across loaded/unloaded areas; if they reference freed world nodes, other systems must handle validity (ongoing project concern).

### Counting for density

- **`Main.count_ai_clans_with_claims_near(pos, radius_px)`** — scans **`npcs`** group for **cavemen** with **`has_land_claim` meta** within radius. Used by **`ChunkManager`** density timer.

---

## 12. Removed legacy spawn paths

The old **one-shot radius burst** and **minigame ring** (`_initialize_minigame`) were **removed**. All static world fill and wild NPC rolls come from **chunk generation**.

| System | Behavior |
|--------|----------|
| **`Main._spawn_ground_items_around_player`** | Called from **`_process`** — continuous small ground spawns near the player. |

**BalanceConfig** radii/counts for cavemen/women remain for **dev test harnesses only**, not normal game start.

---

## 13. Land claims, buildings, player

- **Land claims** and **player-placed buildings** are spawned through **`Main`** / build flows; they typically live under **`world_objects`** (often **`land_claims_container`** for claims — verify scene at runtime).  
- **Grid snapping:** AI land claim placement in **`Main`** uses **64 px** grid alignment for claims (matches build placement conventions).  
- **Chunk streaming does not automatically “pin”** claims inside chunk roots; **player claims** therefore **do not move** with chunk unload unless you change parenting — today they are **not** children of `Chunk_*`.  
- **`WorldArea`** — **10 000 × 10 000** px rectangle for mouse/drop; not tied to chunk bounds.

---

## 14. Multiplayer & future work

**Implemented today**

- **`GameSync.consume_spawn_world_position_for_peer(peer_id)`** — assigns **spawn slot** per joining peer; uses **`WorldGenConfig.player_spawn_zones`** as **chunk coordinates**, converts to **world pixels** via **`ChunkUtils.get_chunk_center`**.  
- **`GameSync.server_send_spawn_to_peer` / `apply_spawn_position` RPC** — teleports the **local** `Main.player` when the RPC targets that client.  
- **`receive_world_snapshot`** — applies **`world_seed`** + **`MutationStore.load_from_dict`**.  
- **`Main`** connects **`NetworkManager`** signals via **`GameSync`** for server-side assignment / snapshot send.

**Not yet “full MMO map”**

- **No** **union interest** over all peers in **`ChunkManager`** (server should eventually keep chunks loaded if **any** player needs them).  
- **No** automatic **chunk preload** before `apply_spawn_position` on join.  
- **No** full replication of gatherable state per client beyond stubs in **`multiplayer.md`**.

**Authored island + Climate Change (design lock)**

- **v1:** One static authored island — base layers only (`biome_mask`, `water_layer`, chunk export). **`TerrainQuery`** reads base; no runtime climate. Rebuild: **`bash tools/rebuild_island_biomes.sh`** — see [island_map.md](island_map.md) §1c.  
- **Phase 6:** **Climate Change** — server `ClimateState` + per-chunk overlays (flood swell, **drought shrink**, glacier grow, aridification, ritual pressure). Base PNGs **never** edited at runtime. Spec: [environment_goal.md](environment_goal.md) §19.  
- **`MutationStore`** today = depletions / grass clear; climate may extend it or use a parallel **`ClimateOverlayStore`**.

---

## 15. Debugging & operations

**Reproducible layout**

- Set **`WorldGenConfig.world_seed`** to a **non-zero** fixed value before **`ensure_initial_load`** runs (e.g. from a debug menu or `Main._ready` guard in dev builds).

**Compare density**

- Tune **`WorldGenConfig.resource_density_multiplier`**, **`wild_woman_chunk_chance`**, and **`clan_spawn_chance`**; restart with a fixed seed and compare **`spawn_flow_summary`** in logs.

**Inspect loaded chunks**

- In editor remote tree: look under **`WorldObjects`** for **`Chunk_*`** nodes.  
- **`ChunkManager.get_loaded_chunk_coords()`** exists for tooling / debug prints.

**Performance knobs**

- Lower **`chunks_load_per_frame`** / raise **`chunks_unload_per_frame`** to smooth frames vs memory.  
- Tighten **`get_effective_load_radius()`** tiers for many players.  
- Reduce **`resources_per_chunk`** / grass clusters for low-end tests.

**Visuals**

- If trees vanish: confirm **`AssetRegistry.get_treess_sprite()`** returns a texture (trees skip silently if null).

---

## 16. Known gaps (honest list)

| Area | Gap |
|------|-----|
| **Unload safety** | `chunk_defer_unload_if_npcs_active` / `..._player_building` are **not** enforced in **`ChunkManager._unload_chunk`**. |
| **Mutation wiring** | **`record_clan_death`** wired via **`LandClaim.try_record_clan_extinction`** (soft death, flag destroy, player extinction). Headless: **`tools/test_clan_death_mutation.gd`**. |
| **MP interest** | Single-player **interest set** only. |
| **Ground spawn** | **`_spawn_ground_items_around_player`** still spawns **globally** near player regardless of chunk mode → possible **overlap / double density** with chunk ground items. |
| **Tall grass texture** | **`ChunkManager`** uses **`randi()`** for texture pick per blade — **not** fully determined by `world_seed` alone. |
| **Corpses / buildings / claims** | Not integrated with chunk pinning / persistence from the design doc; **manual** design if those must survive chunk unload. |

---

## 17. File index

| Area | Path |
|------|------|
| World / streaming entry | `scripts/world.gd` |
| Chunk orchestration | `scripts/world/chunk_manager.gd` |
| Chunk data generation | `scripts/world/chunk_generator.gd` |
| Chunk math / roam constants | `scripts/world/chunk_utils.gd` |
| Tunables | `scripts/config/world_gen_config.gd` |
| Mutations | `scripts/world/mutation_store.gd` |
| Main world + spawn helpers | `scripts/main.gd` |
| Spawn order | `scripts/managers/spawn_manager.gd` |
| MP spawn / snapshot | `scripts/network/game_sync.gd` |
| Spatial resource grid | `scripts/systems/resource_index.gd` |
| Draw order | `scripts/systems/y_sort_utils.gd` |
| Balance (legacy radii / counts) | `scripts/config/balance_config.gd` |
| Seeded clan names | `scripts/naming_utils.gd` (`generate_landclaim_name_seeded`) |
| Autoload registration | `project.godot` |

---

*Last updated: April 2026.*
