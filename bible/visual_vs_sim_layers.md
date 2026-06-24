# Visual vs Simulation Layers

**Purpose:** Single source of truth for splitting cheap world visuals from gameplay simulation. Enables higher decor density and more tribes without linear node-count lag.

**See also:** [game_map.md](game_map.md), [multiplayer.md](multiplayer.md)

---

## Three layers per chunk

| Layer | Contents | Cost |
|-------|----------|------|
| **VisualRoot** | `GrassBatch`, `TreeBatch` (MultiMesh) | Draw only |
| **SimRoot** | `GatherableResource`, `GrassBugPatch`, `GroundItem`, active NPCs | Indexed + scripted |
| **DataLayer** | `ChunkGenerator` output + `MutationStore` deltas | Dictionary only |

**Invariant:** Same `world_seed` + same `MutationStore` snapshot → identical gameplay state after chunk load/unload/reload.

---

## Stable ID contract

Format (`WorldGenConfig.generate_stable_id`):

```
"{chunk_x}_{chunk_y}_{layer}_{index}"
```

Examples: `3_-1_resource_0`, `3_-1_grass_bug_12`, `3_-1_tree_0_2`, `3_-1_ground_4`

Rules:

- Assigned at **generation** time only (deterministic from seed + chunk + salt).
- Every **depletable** entity must have a stable_id before spawn.
- Visual-only grass blades do **not** need stable_ids (cleared by zone, not per-blade).

Layers: `resource`, `grass_bug`, `tree_{group}`, `ground`, `grass_clear` (implicit via zones).

---

## MutationStore schema (per chunk key `"cx,cy"`)

```gdscript
{
  "clan_deaths": 0,
  "depleted": ["3_-1_resource_0", "3_-1_grass_bug_2"],  # stable_ids
  "grass_clear_zones": [{"x": 1200.0, "y": 800.0, "r": 400.0}]  # world px
}
```

**Server authority:** Only server writes mutations. Clients apply via `GameSync.receive_world_snapshot`.

---

## DecorIndex

Spatial grid (200px cells, same as ResourceIndex) for interactable decor:

- `GrassBugPatch` (Area2D markers)
- Future: hidden loot, mushroom-in-grass

**Banned in gameplay:** `get_nodes_in_group("tallgrass")` — use `DecorIndex.query_near()`.

---

## NPC simulation tiers

| Tier | Name | When | Cost |
|------|------|------|------|
| A | Full actor | Near interest, assigned job, hunt target | physics + FSM |
| B | Sleeping | Off-chunk, idle | data record in NPCSleepManager |
| C | Ambient | Migratory herds (future) | batched visual or simplified mover |

Sleep record (Tier B):

```gdscript
{
  "network_id": 123,
  "npc_type": "clansman",
  "clan_name": "HI MAIP",
  "position": Vector2,
  "hp": 100.0,
  "hunger": 45.0,
  "calories": 1800.0,
  "inventory": {}
}
```

Wake: chunk load containing position, ClanBrain job assignment, hunt target, player party radius.

---

## ClanBrain dormant mode

| Mode | Condition | Update |
|------|-----------|--------|
| Active | Claim chunk loaded OR member awake nearby | Full `update()` — hunt/raid + 5s eval |
| Dormant | No awake members in interest chunks | `dormant_update()` every 30s — abstract food/pop only |

Set by `WorldInterestManager.is_claim_active(claim)`.

---

## WorldInterestManager

Active chunk set = union of:

1. Player chunk disk (`WorldGenConfig.get_effective_load_radius()`)
2. Chunks containing active land claims / campfires
3. Chunks with active hunt parties (future hook)

ChunkManager prefers interest manager center/radius when autoload present.

---

## Verification gates

| Phase | Pass criteria |
|-------|----------------|
| 1 | `tallgrass` group empty in chunk mode; node count drops; forage works |
| 2 | Depleted resource/bug stays gone after chunk reload |
| 3 | No `get_nodes_in_group("tallgrass")` in gameplay code |
| 4 | Tree MultiMesh + choppable subset still gatherable |
| 5 | NPC sleep/wake preserves inventory on chunk cycle |
| 6 | 10 claims; only active run full brain eval |
| 7 | MP interest union keeps chunks for all players |

---

## File index

| File | Role |
|------|------|
| `scripts/world/grass_batch.gd` | MultiMesh tallgrass visual |
| `scripts/world/tree_batch.gd` | MultiMesh decorative trees |
| `scripts/world/grass_bug_patch.gd` | Sim marker for bug forage |
| `scripts/systems/decor_index.gd` | Spatial index for decor sim |
| `scripts/world/mutation_store.gd` | Authoritative deltas |
| `scripts/systems/npc_sleep_manager.gd` | Tier B NPC storage |
| `scripts/systems/world_interest_manager.gd` | Active chunk/claim set |
