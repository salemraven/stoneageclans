# SimRng migration guide

Stone Age Clans uses **three official RNG channels** plus a small **VisualRng** allowlist.

## Channels

| Channel | API | Use for |
|---------|-----|---------|
| **SimRng** | `SimRng.sim_randf()` / `sim_randi_range()` | Global server sim timeline |
| **Scoped** | `SimRng.make_scoped_rng(world_seed, salt)` | Order-independent rolls (clan stagger, spawn slot) |
| **EntityRng** | `npc.npc_randf()` / `npc_randi_range()` | Per-NPC AI, wander, influence |
| **ChunkRng** | `ChunkRng.create(world_seed, cx, cy, salt)` | Chunk layout, wildlife herds |
| **VisualRng** | bare `randf()` | Client-only cosmetics (allowlist only) |

## Rules

1. **No bare `randf()` / `randi()` in `scripts/`** except VisualRng allowlist.
2. **Bootstrap:** `SimRng.bootstrap_from_world_config()` runs on boot; `world_seed` is source of truth.
3. **Multiplayer:** Server owns SimRng; clients use replicated state, not local sim rolls.
4. **Legacy spawn:** Removed — chunk streaming is the only world content path.

## VisualRng allowlist

- `scripts/ground_item.gd` — mushroom sprite variant
- `scripts/buildings/building_base.gd` — cosmetic angle
- `scripts/tools/*` — editor/tuner only

## Verification

```bash
bash tools/run_sim_rng_tests.sh
```
