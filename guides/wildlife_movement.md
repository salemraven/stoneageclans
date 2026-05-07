# Wildlife movement & classification

This doc matches the wild NPC pipeline in code (`NPCConfig`, `NPCBase`, `wander_state.gd`, spawn helpers in `main.gd`).

## Concepts (plain English)

- **Migratory**: herd animals spawn on one vertical “edge” of a **chunk band** around the player, drift across the band toward the opposite X, then **despawn** past the far edge (with margin). Chunk “home” does **not** follow them while migration is active.
- **Territorial**: wild NPC has a fixed **anchor** at first profile apply time and wanders mainly inside a **radius** derived from configured chunk radius (see `NPCConfig.territorial_chunk_radius`).
- **Wild profile**: per `npc_type` — movement mode, predator/prey role (for combat / future AI), whether they can be **herded**, and defensive flag.

## Config (`scripts/config/npc_config.gd`)

- **Enums**: `WildMovement` (MIGRATORY / TERRITORIAL), `WildRole` (PREY / PREDATOR / NONE).
- **Exports** (Wild NPC Movement): `migration_drift_strength`, `migration_wander_noise`, `migration_despawn_margin`, `territorial_chunk_radius`, `migration_wander_center_bias_scale`.
- **Profiles**: `wild_npc_profiles` + `get_wild_profile(type)`.

## Runtime (`NPCBase`)

- Migratory corridor: `migration_entry_side`, `migration_exit_x`, `migration_active`.
- Territory: `territorial_anchor`, `territorial_radius`.
- Helpers: `is_migratory()`, `is_territorial_movement()`, `pause_migration()` / `resume_migration()` (herding overrides migration).
- **Despawn**: `_check_migration_despawn()` in physics when migratory — skipped if fighting (combat not IDLE) or herded (`_has_migration_corridor`).

## Wander (`scripts/npc/states/wander_state.gd`)

- `_wild_wander_center_radius()` picks:
  1. Territorial anchor + radius (women with profile applied).
  2. Else migratory biased center toward exit X (`migration_wander_*` tunes) + noise-scaled roam radius.
  3. Else legacy chunk roam (`chunk_center` / `roam_radius`).
  4. Else spawn-position fallback.

## Spawning (`main.gd`)

- Initial and respawn spawns for **deer**, **sheep**, **goats** use `_get_migration_bounds()` (player-centered chunk rectangle) plus `_finalize_migratory_npc()` (sets corridor + `_apply_wild_profile()`).
- **F7**: `_spawn_debug_migratory_deer_f7()` for a single test deer.
- Women: `_spawn_wild_woman` calls `_apply_wild_profile()` after position so territorial anchor matches spawn.

## Quick tuning

- More “straight across the map” drift: raise `migration_drift_strength` (0–1).
- Wider meander while still trending: raise `migration_wander_noise` and/or `wander_radius` interaction (migratory uses `roam_radius * noise`).
- Earlier/later despawn: adjust `migration_despawn_margin`.
