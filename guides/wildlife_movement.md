# Wildlife movement & classification

This doc matches the wild NPC pipeline in code (`NPCConfig`, `NPCBase`, `wander_state.gd`, spawn helpers in `main.gd`).

## Concepts (plain English)

- **Migratory**: herd animals spawn on one vertical “edge” of a **chunk band** around the player, drift across the band toward the opposite X, then **despawn** past the far edge (with margin). Chunk “home” does **not** follow them while migration is active.
- **Territorial**: wild NPC has a fixed **anchor** at first profile apply time and wanders mainly inside a **radius** derived from configured chunk radius (see `NPCConfig.territorial_chunk_radius`).
- **Wild profile**: per `npc_type` — movement mode, predator/prey role (for combat / future AI), whether they can be **herded**, and defensive flag.

## Config (`scripts/config/npc_config.gd`)

- **Enums**: `WildMovement` (MIGRATORY / TERRITORIAL), `WildRole` (PREY / PREDATOR / NONE).
- **Exports** (Wild NPC Movement): `migration_drift_strength`, `migration_wander_noise`, `migration_despawn_margin`, `territorial_chunk_radius`, `migration_wander_center_bias_scale`, **`migration_band_half_chunks`** (player-centered spawn band).
- **Profiles**: `wild_npc_profiles` + `get_wild_profile(type)`.

## Runtime (`NPCBase`)

- Migratory corridor: `migration_entry_side`, `migration_exit_x`, `migration_active`.
- Territory: `territorial_anchor`, `territorial_radius`.
- Helpers: `is_migratory()`, `is_territorial_movement()`, `pause_migration()` / `resume_migration()` (herding overrides migration).
- **Despawn**: `_check_migration_despawn()` when migratory — skipped if **CombatComponent** not IDLE, **valid `combat_target`** (hunted), **`hunt_target_of` meta** lists any valid hunter, or herded (`_has_migration_corridor`).

## Wander (`scripts/npc/states/wander_state.gd`)

- `_wild_wander_center_radius()` picks:
  1. Territorial anchor + radius (women with profile applied).
  2. Else migratory biased center toward exit X (`migration_wander_*` tunes) + noise-scaled roam radius.
  3. Else legacy chunk roam (`chunk_center` / `roam_radius`).
  4. Else spawn-position fallback.

## Spawning (`main.gd` + `ChunkManager`)

- **`WorldGenConfig.use_chunk_content_streaming == true`** (default): Migratory deer / sheep / goats are **rolled per streamed terrain chunk** when it loads (`Main._spawn_wildlife_for_loaded_chunk`). Corridor is **across that chunk’s width** (west↔east edge): animals sit on **`world_objects`**, so **chunk unload does not delete them** while they migrate. The old “one mega ring near the player” batch in `_initialize_minigame` is **skipped** to avoid doubling. Tune rolls in **`WorldGenConfig`** — `wild_migratory_chunk_spawns_enabled`, `wild_migratory_chunk_pass_chance`, `wild_migratory_packs_min` / `_max`.

- **`use_chunk_content_streaming == false`**: Legacy single batch — **`_spawn_sheep_and_goats`** + **`_deer`** still use **`_get_migration_bounds()`** (player-centered band) plus **`_finalize_migratory_npc()`**.

- Respawn timers still top up hunted species after corridors complete / caps allow.

- **F7**: `_spawn_debug_migratory_deer_f7()` near player migration band.

- Women: territorial ring + **`_spawn_wild_woman`** **`_apply_wild_profile()`** after position where applicable.

## Quick tuning

- More “straight across the map” drift: raise `migration_drift_strength` (0–1).
- Wider meander while still trending: raise `migration_wander_noise` and/or `wander_radius` interaction (migratory uses `roam_radius * noise`).
- Earlier/later despawn: adjust `migration_despawn_margin`.
- **See animals on screen**: `migration_band_half_chunks` … (legacy / non-streaming batch only).
- **Chunk streaming wildlife density**: `WorldGenConfig.wild_migratory_chunk_pass_chance`, `wild_migratory_packs_min` / `wild_migratory_packs_max`, or set `wild_migratory_chunk_spawns_enabled` false to rely on respawn timers only.

## Testing (plan checklist)

| Goal | Command / action |
|------|------------------|
| Boot + enums load | `bash tools/run_instrumented_playtest.sh` (expect exit 0; no hard script errors in log) |
| Profiles + migration + despawn contract | `SKIP_SINGLE_INSTANCE=1 godot --headless --path . --script res://tools/wild_npc_movement_verify.gd` → `WILD_NPC_MOVEMENT_VERIFY_OK` |
| F7 spawn + edge logs | In running game **F7** → `MIGRATORY_SPAWN` / `DEBUG F7` lines; deer at west or east band |
| Drift visually | Watch F7 deer 30–60s — should wander but trend toward **`migration_exit_x`** |
| Combat/hunt delay despawn | Engage deer in combat / set **`combat_target`** — past exit edge it should **not** despawn until clear |
| Women territorial | Wild woman wanders near **`territorial_anchor`** (radius from config); profile **TERRITORIAL** |
| Herd pause/resume | Herd sheep → migration pauses on attach; detach → **`resume_migration()`** |
