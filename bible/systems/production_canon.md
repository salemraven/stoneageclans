# Production — canon

**Status:** Partial (bread/leather/campfire cook locked; Farm/Dairy + catalog stations are gaps)  
**Lock date:** 2026-10-07  
**Owner doc:** this file  
**Supersedes:** [production_economy.md](../production_economy.md) for rules; that file stays for code map/events. [Buildings.md](../Buildings.md) for placement buffer only.  
**Code truth:** `clan_brain.gd`, `production_chain_registry.gd`, `production_work_state.gd`, `building_base.gd`, `passive_production_component.gd`, `production_component.gd`, `campfire.gd`

**See also:** [economy_catalog.md](../economy_catalog.md) §5–11 (target pipelines), [gather_canon.md](gather_canon.md), [nomad.md](../nomad.md) (tier buildings), [village_and_economy_rundown.md](../village_and_economy_rundown.md) §4 (hearth-centric future)

---

## 0. One-paragraph intent

**Production** turns **claim stash** inputs into **better food, preservation, and craft materials** using **buildings and the central fire**. **ClanBrain** decides what the clan needs, posts **WorkRequests**, and **women** run haul + station jobs. Men **gather** raw stuff; women **transform** it (see gather canon). No tech tree — need + stock + buildings drive what runs.

---

## 1. Scope & boundaries

| In scope | Out of scope |
|----------|----------------|
| WorkRequest lifecycle | Player hands craft (`CraftRegistry`) |
| Chains in `ProductionChainRegistry` | Knapping minigame |
| Oven bread, drying rack leather | Full tailor/weaver/shaman (catalog only) |
| Campfire passive meat→cooked | MP replication detail (stub rules only) |
| Brain abundance + food_days_buffer | Farm/Dairy **design** (pen); legacy occupy path documented |
| Tier 1 vs 2 building allow-list | Building placement validation (Buildings.md) |
| Woman home hut restore after work | Combat, raid |

**Multiplayer:** **Server** owns claim/building inventories, WorkRequest board, passive timers, and chain completion. Clients animate claimed jobs only.

---

## 2. Player-visible behavior

- Player stocks claim via gather; opens building inventory (I); may toggle **oven fire** in UI (testing path — see §8 gap).
- Women walk with goods; oven shows craft progress when occupied; rack dries hide over time.
- Campfire with wood can passively cook meat in stash.
- Farm/Dairy: animals in slots; women occupy — **placeholder fiber→wool/milk** until animal pen ships.

---

## 3. Core rules (bulletproof logic)

### Who produces

1. **MUST** route **bread** and **leather** (v1 chains) through **ClanBrain WorkRequests** + **`production_work_state`** on women.
2. **MUST NOT** let clients complete crafts or add outputs without server authority.
3. After production work, woman **MUST** return to **her bound Living Hut** (`HOME_LIVING_HUT_META`), not a random hut.

### WorkRequest lifecycle

4. States: `PENDING` → `CLAIMED` → `IN_PROGRESS` → `COMPLETED` (removed on cleanup).
5. **MUST** expire stale `PENDING` after `work_request_expire_seconds` (default 90s).
6. **MUST** maintain at most **one active production request per woman** (debug invariants).
7. On abort, **MUST** release request back to board or clear; restore home hut.

### Brain allocation

8. **MUST** pause production allocation while **nomad march** active on campfire (`nomad_state != NONE`).
9. Allocation tick on established camp: abundance = `stock / max(daily_need + safety_buffer, 1)` per resource class used in rules.
10. **Bread chain** — issue delivery when:
    - Territory has **Oven** building, AND
    - Claim storage has ≥1 wood AND ≥1 grain, AND
    - (`food_days_buffer` below target **OR** grain abundance ≥ surplus threshold), AND
    - No duplicate pending request for same building+type.
11. **Leather chain** — issue delivery when:
    - **Drying rack** exists, AND
    - Claim has ≥1 hide, AND
    - (low food buffer **OR** hide abundance ≥ `production_leather_abundance_min` **OR** general abundance threshold), AND
    - Rack can accept passive input.
12. **MUST** issue **pickup** WorkRequest when passive building has finished output (leather on rack) for haul to claim.
13. Milestone: **MAY** auto-place drying rack when hide count ≥ 3 (current ClanBrain behavior).

### Registered chains (v1 code)

| chain_id | Building | Passive? | Inputs | Output | Woman |
|----------|----------|----------|--------|--------|-------|
| `bread` | Oven | No | 1 wood + 1 grain | 1 bread | Occupy during craft |
| `leather` | Drying rack | Yes | 1 hide in building inv | 1 leather | Deliver hide; pickup output |

Craft times: `BalanceConfig.bread_craft_time`, `BalanceConfig.drying_rack_process_time`.

### Campfire (Tier 1 claim)

14. **MUST** allow passive **meat → cooked meat** on campfire inventory when fuel rules satisfied (`campfire_cooking_interval`).
15. Tier 1 **MAY** place Living Hut, Oven, Drying Rack; **MUST NOT** place Farm/Dairy on campfire (nomad doc).
16. Tier 2 land claim **MAY** place Farm, Dairy, and full milestone set.

### Containers & food states (design lock — not all coded)

17. **Target (economy_catalog):** liquids (milk, stew, potions) require **small empty containers** in building stock; no loose milk piles.
18. **Target:** flour from mortar before bread; hearth for stew; hide → **sheet + 4 strips** not single leather item.
19. **v1 ships as:** grain→bread, hide→leather item until tailor pipeline exists.

### Farm / Dairy (legacy until animal pen)

20. **Current code:** Farm = 1 fiber → 1 wool; Dairy = 1 fiber → 1 milk via **occupy/work_at_building**, **not** WorkRequests.
21. **MUST** treat this as **placeholder** in design docs and UI; **target** = animal pen + feed + bottles (economy_catalog §11.10).
22. **MUST NOT** document fiber→milk as final design in new features.

### Edge cases

| Situation | Outcome |
|-----------|---------|
| Missing inputs in claim | No delivery request (silent skip) |
| Rack busy / cannot accept hide | Block delivery |
| No oven on territory | No bread requests |
| Woman dies mid-job | Release request; clear occupant |
| Building destroyed | Drop or refund per building_base policy; clear requests |

### Authentic village direction (not v1 code)

23. **Design north star:** merge oven into **central hearth** recipes; one **corral**; drying **frame** — see village rundown. New buildings **SHOULD** use **station tags** before new enum explosion.

---

## 4. Data model

- **ProductionChain** resource: `chain_id`, `building_type`, `inputs[]`, `output`, `craft_time`, `is_passive`, `min_stage`.
- **WorkRequest** on ClanBrain: type delivery/pickup, chain ref, building ref, state, timestamps.
- **Building inventories:** stackable slots; passive component reads/writes building inv.
- **OccupationSystem:** woman slots, animal slots (Farm/Dairy legacy).

---

## 5. State machine / lifecycle

- Woman: `production_work_state` (priority ~11.8–12 when pending) beats herd/repro → TaskRunner jobs (PickUp, MoveTo, Occupy, DropOff).
- Oven: `ProductionComponent` when active/occupied.
- Rack: `PassiveProductionComponent` timer when hide present.

---

## 6. Integration map

| System | Contract |
|--------|----------|
| Gather | Supplies wood, grain, hide to claim |
| ClanBrain | `food_days_buffer`, `_evaluate_resource_allocation` |
| Living hut | Home binding after work |
| Settlement sim | Passive timers + abstract production when warm |
| Proto farming (future) | Grain from Field, not Farm building |

---

## 7. Balance hooks

| Key | Role |
|-----|------|
| `abundance_threshold` | Surplus chains |
| `production_bread_surplus_grain_abundance` | Bread when food OK |
| `production_leather_abundance_min` | Leather pressure |
| `safety_buffer_days` | Abundance denominator |
| `allocation_eval_interval` | Brain tick multiplier |
| `daily_need_*_per_capita` | Abundance inputs |
| `campfire_cooking_interval` | Meat cook |
| `bread_craft_time` / `drying_rack_process_time` | Durations |

---

## 8. Implementation status

| Piece | Shipped? | Notes |
|-------|----------|-------|
| bread + leather WorkRequests | Yes | |
| Campfire cook | Yes | |
| Farm/Dairy WorkRequests | No | Legacy occupy |
| Oven fire without woman | Yes | Conflict with §1 intent; keep for solo test |
| Mortar, hearth, pen, containers | No | Catalog |
| hide → sheet + strips | No | Single LEATHER type |
| MP authoritative production | Partial | |

---

## 9. Test & verification

- `bash tools/run_playtest_npc_only_5min_economy.sh`
- `tools/test_abstract_gather.gd` (dormant + brain)
- JSONL: `work_request_*`, `production_allocation_eval`, `campfire_passive_cooked`
- `python3 scripts/logging/analyze_playtest.py --strict-production`

---

## 10. Open questions

- Merge Oven into hearth scene vs keep separate building.
- When to migrate Farm/Dairy to pen + WorkRequests.
- Require woman occupy for oven in release builds (disable fire-only toggle?).
- Off-screen production: same chain registry as on-screen (settlement_sim).

---

## 11. Changelog

| Date | Change |
|------|--------|
| 2026-10-07 | Initial partial canon from production_economy + economy_catalog + code |
