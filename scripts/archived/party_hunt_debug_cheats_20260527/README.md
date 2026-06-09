# Party/hunt debug cheats (removed 2026-05-27)

Removed from production paths so AI clans start **fresh** (solo caveman + empty claim).

Previously lived in `main.gd`, `clan_brain.gd`, `debug_config.gd`:

- Force `caveman_spawn_with_boost` in npc-only world
- `_bootstrap_ai_playtest_repro_claim` (2 Living Huts + 2 pregnant women at t≈0)
- `_seed_party_hunt_debug_deer_near_claims` (4 deer per claim in AoH ring)
- Fast repro timers via `--party-hunt-debug`
- `npc_only_world_hunt_stress` / forced hunt need pressure / 8s hunt cooldown override
- Grazing deer that never left AoH (`party_hunt_debug_graze` meta)

`--party-hunt-debug` now only enables **FSM / party group instrumentation** (`party_hunt_instrument.gd`).

Restore from git history before this date if you need the old harness.
