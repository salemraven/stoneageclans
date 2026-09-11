# Island multiplayer (future)

**Status:** Design draft — **not implemented.**  
**Island layout:** **[../environment_goal.md](../environment_goal.md)** (canonical) · [../island_map.md](../island_map.md) (map2 checklist) · [`../assets/island_map2.jpg`](../assets/island_map2.jpg)  
**Drafted:** September 2026

---

## Why

Today: **infinite chunked plane**, local-player interest only ([game_map.md](../game_map.md)). Target: **one authored island**, **2+ players**, shared herdables, **ClanBrain runs your claim when you disconnect**.

---

## World

| Rule | Detail |
|------|--------|
| **Geometry** | Single island from **map2** — ocean impassible beyond beaches |
| **Streaming** | Same `ChunkManager` pattern; cells load **authored** biome + props |
| **Determinism** | `world_seed` + authored layers + **MutationStore** deltas = identical world for all clients |
| **Legacy dev** | Infinite procedural sandbox may remain for headless tests only |

---

## Player spawns

**Goal:** Leaders do **not** share the first wild flock or the same beach.

| Rule | Implementation sketch |
|------|------------------------|
| **Four zones** | One coastal spawn per **quadrant** (N/E/S/W) on map2 |
| **Min separation** | Extend `WorldGenConfig.player_spawn_min_distance_px` (today 3000) — tune from island size |
| **Per peer** | `GameSync.consume_spawn_world_position_for_peer()` — already partial ([multiplayer.md](../multiplayer.md)) |
| **Tier 1 start** | Each player begins **nomad** — no flag; place **campfire** near their quadrant coast |

---

## Land claims

| Rule | Detail |
|------|--------|
| **No overlap** | Claim circles (campfire 250px / flag 400px) cannot intersect |
| **Validation** | Server rejects placement; UI shows red ghost |
| **Herdables** | World objects — **steal is PvP** ([herdable_raiding.md](herdable_raiding.md)) |
| **Chunks** | Claims register mutations per chunk; interest union loads chunks for **all** peers (MP gap today) |

---

## Disconnect / reconnect

| State | Authority |
|-------|-----------|
| **Player online** | Player commands; server sim validates |
| **Disconnect** | **ClanBrain** on that player’s territory continues defend/search/production/off-screen tick |
| **Reconnect** | Snapshot: roster, claim inventory, raid/hunt intent, mutations |

**Do not** pause the world for disconnected clans — other players keep playing.

---

## Domination panel (UI target)

Per island session:

- Living **sons** (clansmen count)
- **Women** (wild + clan)
- **Trait mix** histogram for the clan ([earlygame_vision.md](../earlygame_vision.md) §8)
- **Claims held** (campfires + flags)
- Optional: quadrant control, raid wins, wipe count

---

## Raid / herd / MP safety

- **Cordage bond**, raid goals, delivery — **server-only** ([herdable_raiding.md](herdable_raiding.md))
- **Herd attach** — server `HerdAuthority` (engineering plan)
- **AoH / hunt** — server prey counts; clients render

---

## Build order

1. Authored biome mask from map2 ([environment_goal.md](../environment_goal.md) §3, [island_map.md](../island_map.md)).
2. Island boundary + ocean collision.
3. Four spawn zones + overlap test for claims.
4. Chunk **interest union** for all peers.
5. Disconnect → ClanBrain ownership flag on player claim.
6. Domination panel (read-only stats first).

---

## Related

- [multiplayer.md](../multiplayer.md) — WebSocket, GameSync stubs
- [environment_goal.md](../environment_goal.md) — **canonical** island biomes, resources, wildlife (Sep 2026)
- [island_map.md](../island_map.md) — map2 art checklist
- [earlygame_vision.md](../earlygame_vision.md) §7
