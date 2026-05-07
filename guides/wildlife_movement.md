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

## Deer flight (`flee_prey`)

Migratory drift is separate from **predator/player pressure**. Deer use FSM **`flee_prey`** (`scripts/npc/states/flee_prey_state.gd`):

- **Detection:** Humans (player, caveman, clansman, woman) inside **`DetectionArea`** feed **`PerceptionArea.get_deer_threat_centroid`** for “run away from this point.” Loud sounds (`SoundDetection` vs **`deer_sound_threshold`**) also count as threatened.
- **Player fallback:** If overlap signals miss (edge cases), the centroid helper still treats the **`player`** group member **inside `deer_perception_visual` / DetectionArea radius** as a threat so walk-up reliably spooks deer.
- **Fright meter** (`NPCBase.deer_fright_meter`): While a threat is visible in range, the meter **fills** (faster when the player is **closer**); it **decays** when safe, while **herded**, or during **`flee_prey`**. When it crosses **`deer_fright_flee_at`** (scaled to **`deer_fright_meter_max`**), **`FSM.change_state("flee_prey")`** runs so flee is gated like a tension bar—not a single frame flip.
  - Tune: **`NPCConfig`** — **`deer_fright_meter_max`**, **`deer_fright_fill_per_sec`**, **`deer_fright_decay_per_sec`**, **`deer_fright_flee_at`** (plus **`deer_perception_visual`**).
- **Speed:** **Burst** (panic sprint) uses **`deer_flee_burst_speed_mult`** on **`SteeringAgent`**; **winded** uses **`deer_winded_speed_mult`**; exiting **`flee_prey`** restores base speed via **`restore_original_speed()`**.
- **Panic ripple:** **`deer_panic`** sound when flee starts (**`deer_panic_spread_*`** tuning).

Gameplay detail alongside hunt stances: **`guides/Phase4/raiding_hunting.md`** §5.

## Debugging migrations & wild spawns (JSONL)

- **`--wild-npc-trace`** or **`DebugConfig.enable_wild_npc_trace`**: writes **`user://wild_npc_trace_*.jsonl`** with structured lines such as **`migratory_spawn`**, **`wild_chunk_spawn_start`**, throttled **`wild_migratory_tick`**, **`migration_complete`**. Throttle interval: **`DebugConfig.wild_npc_trace_interval_sec`**.
- **`--playtest-capture`** / **`DebugConfig.playtest_capture_always`**: **`PlaytestInstrumentor`** snapshot **`npc_world_probe`** lists **deer** and **mammoth** alongside other probed types, and **`mig_act` / `mig_side` / `mig_exit`** when migration fields exist. **`migration_complete`** is logged via **`log_event`** while capture is on.

## Testing (plan checklist)

| Goal | Command / action |
|------|------------------|
| Boot + enums load | `bash tools/run_instrumented_playtest.sh` (expect exit 0; no hard script errors in log) |
| Profiles + migration + despawn contract | `SKIP_SINGLE_INSTANCE=1 godot --headless --path . --script res://tools/wild_npc_movement_verify.gd` → `WILD_NPC_MOVEMENT_VERIFY_OK` |
| F7 spawn + edge logs | In running game **F7** → `MIGRATORY_SPAWN` / `DEBUG F7` lines; deer at west or east band |
| Drift visually | Watch F7 deer 30–60s — should wander but trend toward **`migration_exit_x`** |
| Combat/hunt delay despawn | Engage deer in combat / set **`combat_target`** — past exit edge it should **not** despawn until clear |
| Deer fright + sprint | Approach a deer inside vision — meter builds, then **`flee_prey`** + faster **burst** move; horn / loud sounds spike panic |
| Women territorial | Wild woman wanders near **`territorial_anchor`** (radius from config); profile **TERRITORIAL** |
| Herd pause/resume | Herd sheep → migration pauses on attach; detach → **`resume_migration()`** |
