# Wildlife migration — seasonal cross-plane travel

**Purpose:** Canonical design for **wild NPC herds** (deer, mammoth, sheep, goats, future species) migrating **across the continuous world plane** — spawn on one edge, travel through the map, despawn on the far edge, then **return on a later season**. Tied to the **continuous plane** ([settlement_sim.md](settlement_sim.md)) and environment/season systems.

**Status:** **Design lock + partial implementation** — local chunk-band migration exists; **full cross-plane seasonal routes are not built**.

**Last updated:** August 2026

**See also:** [wildlife_movement.md](wildlife_movement.md) (current code), [settlement_sim.md](settlement_sim.md) (continuous plane + sim tiers), [game_map.md](game_map.md) (chunks, coordinates), [environment_goal.md](environment_goal.md) (seasons, biomes), [hunting.md](hunting.md), [guides/lag.md](../guides/lag.md)

---

## Design lock

> **Wild herds migrate on the same continuous 2D plane as the player** — not on a separate map layer. Season changes **flip travel direction** (outbound leg → return leg) so animals visibly **come and go** across the world, creating hunting pressure, empty windows, and “the herd is back” moments.

This complements **settlement sim** (villages at fixed coords) with **moving wildlife corridors** through wilderness between them.

---

## Player fantasy

| Season / phase | What the player notices |
|----------------|-------------------------|
| **Spring outbound** | Herds appear from the **north** (example) and drift **south** across grasslands |
| **Summer** | Rich hunting along the route; clans time hunts to crossing zones |
| **Autumn return** | Same species drift **north** again before winter |
| **Winter** | Fewer migratory spawns in harsh biomes; territorial / local prey replace corridor density |
| **Travel** | Walk the same plane — meet a deer column on the trail between two villages |

Coordinates are **world pixels** (`ChunkUtils`, land claims). No instanced hunting maps.

---

## Today vs target

| Aspect | **Today (shipped)** | **Target (seasonal cross-plane)** |
|--------|---------------------|-----------------------------------|
| **Route length** | Player-centered **chunk band** or **single chunk width** (west↔east) | **World-scale corridor** — one side of active map to opposite |
| **Direction** | Random entry west or east per spawn | **Season-driven** global `migration_flow_sign` (+X / −X or N/S per species) |
| **Return trip** | Despawn at exit; respawn timers spawn new band near player | **Same population wave** tracked in data OR seeded **return leg** after season tick |
| **Spawn trigger** | Chunk load rolls (`WorldGenConfig.wild_migratory_*`) | Season start + biome gates + **spawn edge** from world bounds / biome ring |
| **Parent node** | `world_objects` (survives chunk unload) ✅ | Same — **required** for cross-plane travel |
| **Sleep** | Migratory NPCs **exempt** from `NPCSleepManager` ✅ | Keep exempt while `migration_active` |
| **Despawn** | `_check_migration_despawn()` past `migration_exit_x` + margin | Despawn at **far world edge** or abstract handoff to off-plane wave record |

**Code anchors today:** `NPCBase.migration_entry_side`, `migration_exit_x`, `migration_active`, `_check_migration_despawn()`, `_finalize_migratory_npc()`, `NPCConfig.WildMovement.MIGRATORY`, `main.gd` `_get_migration_bounds()` (player-centered — **to be replaced** for world routes).

---

## Simulation tier (wildlife corridor)

Fits the hot / warm / cold model from [settlement_sim.md](settlement_sim.md):

```
HOT   — migratory herd near any player
          Full NPC nodes: wander + drift, flee, hunt interaction

WARM  — herd on plane, far from players
          Option A: reduced tick (drift only, no perception) — future
          Option B: abstract wave (count + center + velocity) until hot interest

COLD  — between waves / wrong season
          No migratory actors; next wave scheduled from season + seed
```

**Rule:** Do **not** use clan **settlement tick** for wildlife — different system (`MigrationWaveManager` or extend `WildRole` scheduler). Do **not** freeze migratory herds by chunk unload (already parented to `world_objects`).

---

## Season + route model (sketch)

**Server authority.** Deterministic from `world_seed + world_day + species_id`.

```gdscript
# Conceptual — not implemented as single autoload yet
MigrationRoute = {
  "species": "deer",
  "axis": "x",                    # or "y" for north-south
  "season_outbound": SPRING,
  "season_return": AUTUMN,
  "spawn_edge": -1,               # west or north
  "exit_edge": +1,
  "biome_filter": ["grassland", "forest_edge"],
  "pack_size_min": 2,
  "pack_size_max": 6,
}

# Each season tick:
#   if season matches outbound → spawn waves at spawn_edge (seeded positions)
#   if season matches return   → flip entry_side / exit_x
#   herds drift via existing migration_wander + migration_drift_strength
#   on exit → despawn or register WaveRecord for count conservation
```

**Return leg:** Either (1) **flip corridor** on all active migratory NPCs when season changes, or (2) **despawn + respawn** return wave from `WaveRecord` (preserves population counts without simulating every deer off-screen).

Prefer **(2) for perf** with **deterministic spawn positions** so MP clients agree.

---

## Performance rules

1. **Cap active migratory actors** globally and per species (config on `WorldGenConfig` or `NPCConfig`).
2. **Interest:** full flee/perception only within player chunk disk; distant herds use drift-only or abstract wave.
3. **Never** add migratory bodies to clan sleep — already exempt in `NPCSleepManager.sleep_npcs_in_chunk`.
4. **Despawn at edge** is mandatory — prevents infinite deer accumulation across the plane.
5. **Profile** with `--lag-profile` + `--wild-npc-trace` when enabling world-scale routes.
6. **Chunk streaming** spawns **local packs** that **join** a global wave direction — not independent random bands per player (avoid duplication in MP).

---

## Interaction with other systems

| System | Behavior |
|--------|----------|
| **Hunting / AoH** | Migratory prey pauses despawn while `combat_target` / hunt meta active ([wildlife_movement.md](wildlife_movement.md)) |
| **Herding** | `pause_migration()` / `resume_migration()` on herd attach — sheep/goats |
| **Clan settlements** | Villages are fixed; migrations **pass through** wilderness — creates timed hunting opportunities |
| **Biomes / seasons** | Route availability from [environment_goal.md](environment_goal.md); drought/ice may cancel or shorten waves |
| **Multiplayer** | Server owns wave schedule + spawn; clients render herds in interest range |

---

## Implementation phases

| Phase | Deliverable |
|-------|-------------|
| **0** | This doc + links (design lock) |
| **1** | Replace player-centered `_get_migration_bounds()` with **world edge** bounds (configurable half-extent or biome ring) |
| **2** | `MigrationWaveManager` autoload — season → flow sign, spawn quota, species routes |
| **3** | Return leg — flip or respawn on season change; verify determinism with fixed seed |
| **4** | MP — single server wave table; no per-client duplicate spawns |
| **5** | Warm abstract wave (optional) — reduce actor count far from players |
| **6** | Playtest gate — spring: herd crosses player base eastbound; autumn: herd crosses westbound |

---

## Verification

```bash
# Current migration contract (local corridor + despawn)
SKIP_SINGLE_INSTANCE=1 godot --headless --path . --script res://tools/wild_npc_movement_verify.gd

# Trace spawns / migration_complete in GUI
SKIP_SINGLE_INSTANCE=1 godot --path . --wild-npc-trace
```

Future: headless season-step test — assert wave direction flips and spawn edge matches `world_seed`.

---

## File index

| Area | Path |
|------|------|
| Migratory runtime | `scripts/npc/npc_base.gd` |
| Wander / drift | `scripts/npc/states/wander_state.gd` |
| Wild profiles | `scripts/config/npc_config.gd` |
| Chunk spawn rolls | `scripts/main.gd` — `_spawn_wildlife_for_loaded_chunk` |
| Legacy band spawn | `scripts/main.gd` — `_get_migration_bounds`, `_finalize_migratory_npc` |
| Chunk config | `scripts/config/world_gen_config.gd` — `wild_migratory_*` |
| Sleep exemption | `scripts/systems/npc_sleep_manager.gd` |
| Verify | `tools/wild_npc_movement_verify.gd` |
| Trace | `DebugConfig.enable_wild_npc_trace` |

---

## Changelog

| Date | Change |
|------|--------|
| Aug 2026 | Design lock: seasonal cross-plane wildlife migration on continuous world |
