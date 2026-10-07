# Gather — canon

**Status:** Partial (rules locked; code gaps listed in §8)  
**Lock date:** 2026-10-07  
**Owner doc:** this file  
**Supersedes:** Treat [GatherGuide.md](../GatherGuide.md) as implementation detail; this file wins on rules.  
**Code truth:** `gatherable_resource.gd`, `gather_state.gd`, `gather_job.gd`, `gather_task.gd`, `resource_index.gd`, `abstract_gather.gd`, `chunk_generator.gd`

**See also:** [economy_catalog.md](../economy_catalog.md) §3.1 (what is gatherable), [game_map.md](../game_map.md) (chunks/mutations), [production_canon.md](production_canon.md) (stash → production), [environment_goal.md](../environment_goal.md) §5 (future biome nodes)

---

## 0. One-paragraph intent

**Gather** is how the clan pulls **raw materials and wild food** from the world into **territory storage** so brains, women, and crafters can use them. Fighters (cavemen/clansmen) do the hauling; the **land claim (or campfire claim) is the authority** that assigns work and receives deposits. The world is **chunk-spawned and seeded**; player changes are **mutations**, not client fiction.

---

## 1. Scope & boundaries

| In scope | Out of scope |
|----------|----------------|
| NPC gather jobs (clansmen/cavemen) | Women production ([production_canon.md](production_canon.md)) |
| Player gather (Space / overlap) | Butchering corpses (hunt/combat; shares harvest tasks) |
| ResourceIndex registration/query | Crafting at stations |
| Tool gates (axe/pick/oldowan) | Farm/Dairy/wool/milk (building output) |
| Deposit into claim inventory | Raid looting enemy buildings |
| Chunk spawn list (v1 types) | Full island biome tables (environment_goal; later) |
| Abstract/off-screen gather when claim dormant | Pathfinding tuning, FSM priority numbers (fsm canon) |

**Multiplayer:** **Server** owns gather start/finish, node depletion/mutation, job leases, and claim inventory changes. Clients send intent; server validates overlap, tools, capacity, and emits inventory deltas.

---

## 2. Player-visible behavior

- **Clansmen** near resources harvest with a progress bar; when carry is “full enough,” they walk home and items appear in the **claim stash** (I near claim).
- **Player:** **Space** on overlapping gatherable (one active target); need correct tool for wood/stone or use Oldowan (slower). Berries/fiber/wheat hands OK.
- **Failure feedback:** blocked tool, node depleted, no capacity on node, outside claim for deposit (NPCs without claim keep gathering but cannot deposit).

---

## 3. Core rules (bulletproof logic)

### Authority & jobs

1. **MUST NOT** assign gather targets by per-NPC world scans in production code; **MUST** issue gather work through **territory job generation** using **ResourceIndex.query_near**.
2. **MUST** reserve a worker slot on a gather node while a gather job is active; **MUST** release on job complete, cancel, or expiry.
3. **MUST NOT** start NPC gather jobs without a **clan_name** and a valid **owning claim** (campfire or land claim).
4. Job chain **MUST** be: MoveTo(node) → GatherTask → MoveTo(claim) → deposit (unless `skip_deposit` flag for special jobs).

### Deposit & carry

5. Deposit trigger when `used_slots >= max(3, ceil(slot_count * gather_deposit_threshold))`. **Config source:** `NPCConfig.gather_deposit_threshold` (tune in one place).
6. **MUST** deposit all non-kept items when within **`NPCConfig.deposit_range`** of claim center (default 100px).
7. **MUST** keep at most **one edible food item total** in NPC inventory for personal use when depositing; deposit all other food stacks. Edible set = `ResourceData` edible foods used by deposit logic (align with economy_catalog §6).
8. **MUST NOT** treat **fiber** as normal human food in gather-keep rules (herbivore emergency only — economy_catalog §3.2).

### Same-node harvesting

9. **MUST** continue harvesting the **same node** until inventory fill ≥ `gather_same_node_until_pct` of capacity **or** node depleted, then release node.
10. **MUST** cancel active gather if worker moves farther than **`gather_move_cancel_threshold`** from gather anchor (anti-bump).

### Node capacity (defaults)

| Resource type | max_workers |
|---------------|-------------|
| Wood (tree) | 3 |
| Stone | 2 |
| Berries, wheat, fiber | 1 each |
| Other / default | 1–2 per `gatherable_resource` setup |

11. **MUST NOT** assign more concurrent gatherers than `max_workers` on a node.

### Tools

12. Wood harvest **MUST** require axe **or** Oldowan equipped (Oldowan = slower yield path).
13. Stone harvest **MUST** require pick **or** Oldowan (Oldowan = slower).
14. Player wood without axe/oldowan **MAY** run “search tree” (no wood; optional nuts roll) — not a substitute for real chop.

### World & types (v1 shipped set)

15. Chunk/content **MUST** spawn only from **seed + chunk coords** (+ mutation overlay) for static props.
16. **v1 gather node types:** wood, stone, berries, wheat (yields **grain** in inventory), fiber, mushroom; bugs via grass patch; nuts as wood chop bonus until dedicated nodes exist.
17. **MUST** register gatherables and ground items in ResourceIndex on enter tree; **MUST** unregister on free.

### Off-screen (settlement)

18. When claim is **warm/dormant** without live gatherers, **MAY** add resources via **abstract_gather** using the same **resource type set** and claim authority — **MUST NOT** invent types that on-screen gather cannot produce.
19. Abstract gather **MUST** respect mutation/pool rules documented in `off_screen_clan_balance.md`.

### Edge cases

| Situation | Outcome |
|-----------|---------|
| No resources in query radius | No job; backoff before retry (no tight loop spam) |
| Job issued but node freed | Release lease; fail job safely |
| Inventory full mid-gather | Complete gather pass; exit to deposit |
| Enemy claim filter on query | Do not assign jobs to harvest inside hostile territory (when filter enabled) |
| Nomad march | Live gather may continue; brain production paused separately |
| Wheat node | Yield **grain** (food), not item “wheat” |

### Code vs doc drift (resolve toward config)

| Knob | GatherGuide text | Live default (`npc_config.gd`) |
|------|------------------|--------------------------------|
| Deposit threshold | 40% | **0.5** (50%) unless project overrides |
| Same-node until | 80% | **1.0** (100%) |

**Canon:** numbers come from **NPCConfig**; update GatherGuide when tuning.

---

## 4. Data model

- **GatherableResource:** `resource_type`, `max_workers`, `reserved_workers`, chunk meta, optional `stable_id`.
- **GroundItem:** indexed like gatherables for pickup jobs.
- **GatherJob:** lease reference to node + claim; `gather_until_pct` from config.
- **ResourceIndex:** spatial hash cell 200px; filters: type, capacity, cooldown, enemy claim, empty.

---

## 5. State machine / lifecycle

- FSM: `gather_state` requests jobs (throttled); exits when at deposit threshold → `wander` for movement → auto-deposit on `npc_base`.
- No gather state for women as primary haulers (production_work is separate).

---

## 6. Integration map

| System | Contract |
|--------|----------|
| ClanBrain | Reads claim stock; may request abstract gather when dormant |
| TerritoryJobService / land_claim | `generate_gather_job()` |
| Hunt | Clansmen may equip club in gather; hunt meta blocks gather equip rules |
| Production | Consumes deposited wood, grain, hide |
| ChunkManager | Spawns/despawns nodes; mutations on depletion |

---

## 7. Balance hooks

| Key (`NPCConfig` / `BalanceConfig`) | Role |
|-------------------------------------|------|
| `gather_deposit_threshold` | When to head home |
| `gather_same_node_until_pct` | Stay on one node |
| `gather_move_cancel_threshold` | Cancel if pushed |
| `deposit_range` | Auto-deposit radius |
| `SEARCH_THROTTLE` / backoff constants | Job request rate (gather_state) |

---

## 8. Implementation status

| Piece | Shipped? | Notes |
|-------|----------|-------|
| Job-only gather | Yes | No legacy scan in gather_state |
| ResourceIndex | Yes | |
| Player gather + tools | Yes | |
| Biome-specific spawn tables | No | Plain rotation |
| MP server validate gather | Partial | See multiplayer.md |
| Fiber diet / human eat | Gap | Catalog vs EDIBLE lists |
| GatherGuide % text | Stale | Use this canon + NPCConfig |

---

## 9. Test & verification

- `bash tools/run_instrumented_playtest.sh`
- `tools/test_abstract_gather.gd`
- Playtest JSONL: `gather_*` when `--playtest-capture`
- Invariants: no duplicate lease on full node; deposit increases claim counts

---

## 10. Open questions

- Exact respawn: infinite regen vs mutation cooldown per chunk (lock with game_map).
- Ground-item gather jobs vs only gatherable nodes in job generator.
- When island biomes ship: extend §16 list without breaking v1 saves (subtype meta).

---

## 11. Changelog

| Date | Change |
|------|--------|
| 2026-10-07 | Initial partial canon from GatherGuide + code + economy_catalog |
