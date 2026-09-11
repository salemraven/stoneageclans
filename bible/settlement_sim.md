# Settlement simulation — actors vs villages

**Purpose:** Canonical design for how **clans keep living** (babies, buildings, gathering, crafting, genetics) while **individual NPC nodes sleep** for performance. Required for an **open-world evolutionary sandbox** at scale.

**Status:** **Framework / partial implementation** — land claims persist, `ClanBrain.dormant_update()` exists (food drain only), actor sleep/wake exists; **full settlement tick is not built**.

**Last updated:** August 2026

**World model (settled):** **One continuous 2D plane** — the player walks from their settlement to any other on the same map. We do **not** use instanced colony maps (RimWorld tiles, Dwarf Fortress site layers). See [Continuous plane (design lock)](#continuous-plane-design-lock).

**See also:** [visual_vs_sim_layers.md](visual_vs_sim_layers.md) (chunk + NPC tiers), [game_map.md](game_map.md) (chunks, coordinates), [wildlife_migration.md](wildlife_migration.md) (seasonal cross-plane herds), [guides/lag.md](../guides/lag.md) (perf budgets), [production_economy.md](production_economy.md) (on-screen WorkRequests), [reproduction_guide.md](reproduction_guide.md), [camp_relocation.md](camp_relocation.md), [future implementations/genetics.md](future%20implementations/genetics.md), [future implementations/off_screen_clan_balance.md](future%20implementations/off_screen_clan_balance.md) (baseline tuning + production modifiers), [ai_clan_brain.md](ai_clan_brain.md)

---

## Continuous plane (design lock)

**Decision:** Stone Age Clans is **one shared world** in pixel space. Your land claim, rival clans, resources, and travel routes all exist on **the same plane**. You walk (or later ride) from home to another village and back — no map switch, no separate fort instance, no caravan-only abstraction layer between settlements.

This is **not** how RimWorld or Dwarf Fortress handle multiple settlements (separate loaded maps / world-tile instances). It **is** closer to Kenshi’s geography, Mount & Blade’s continuous campaign map, or Factorio’s one surface — with the critical addition that **villages must keep simulating off-screen** via warm settlement ticks (avoid Kenshi’s “base stops when zone unloads” failure mode).

### What the player should feel

| Feel | Means |
|------|--------|
| **Same world** | “That clan is *that way* on the map” — fixed coordinates, not a menu destination |
| **Real travel** | Distance, terrain, wildlife, and time passing while you move |
| **Seasonal wildlife** | Herds cross the plane (e.g. spring southbound, autumn northbound) — see [wildlife_migration.md](wildlife_migration.md) |
| **Living places** | Leave for days; return to the **same spot** — population, buildings, and stockpiles changed |
| **Approach reveals detail** | Far away = abstract life; close up = full NPCs, animation, combat |

### Geography vs simulation fidelity

**Continuous plane applies to space, not to CPU budget.**

```
SPACE (one plane):     Claim A at (x1,y1)  —walk—>  Claim B at (x2,y2)

SIM (tiered by distance from players):
  HOT   near you        → full actor nodes
  WARM  known claim, far → settlement tick on claim (no walking NPCs required)
  COLD  wilderness chunk → seed + mutations only
  CORRIDOR migratory herds on plane → drift / wave (see wildlife_migration.md)
```

Walking is **real** on the plane. Pathfinding and 20-layer pawns are **local** to hot zones.

### Implications for systems (do / don’t)

| Do | Don’t |
|----|--------|
| Persist land claims / campfires at world `(x, y)` under `WorldObjects` | Teleport the player to instanced “colony maps” |
| Warm-tick every claim with state worth keeping | Freeze villages when chunk unloads |
| Stream **chunks** around players; merge MP interest unions | Treat “leave my base” as abandoning a RimWorld tile |
| On approach: spawn actors from roster to match warm state | Pop in identical frozen scene from sleep save |
| Use `WorldInterestManager` + distance for hot/warm boundaries | Rely on zone unload alone (Kenshi pitfall) |

### Reference games (correct tier)

| Game | Useful for | Weak for us |
|------|------------|-------------|
| **Kenshi** | Same plane, walk between towns, zone streaming | Off-screen bases often stop simulating |
| **Mount & Blade** | Continuous map; settlements as data while you ride | No full 2D pawn sim when visiting |
| **Factorio** | One surface; chunk sleep; building logic persists | No genetics / clan social layer |
| **Dwarf Fortress / RimWorld** | Roster + histfig / colony persistence ideas | **Instanced maps** — not our travel model |

### MP note

All peers share **one world seed and one coordinate space**. Server interest = union of player positions on that plane. Settlement ticks run on claims regardless of whether local clients have those chunks meshed in yet.

---

## Core rule

> **Actor sleep is allowed. Settlement sleep is not.**

- **Actors** = walking NPC nodes (physics, FSM, pathfinding, perception, layered sprites).
- **Settlement** = the clan as a living village: people, stockpiles, production, construction, pressure, genetics.

When actors despawn or go dormant, the **settlement must keep simulating** at coarser granularity until a player (or MP interest) returns.

**Do not confuse** “NPC sleep” (no node) with “the clan stopped existing.” Sleep means **no sprite/physics on this pawn**, not **frozen history**.

---

## Why this exists

Stone Age Clans targets:

1. **Large open world** — travel far, meet clans, return later and see change.
2. **Evolutionary sandbox** — generations, traits, settlement growth, not a paused diorama.
3. **Many NPCs + multiplayer** — cannot run full actor sim for every clansman on the map.

Running ~140 full `CharacterBody2D` + FSM + perception nodes causes severe lag ([guides/lag.md](../guides/lag.md)). The fix is **tiered simulation**: rich where it matters, abstract elsewhere — **without freezing off-screen villages**.

---

## Two simulation layers

| Layer | What it is | Examples | When it runs |
|-------|------------|----------|--------------|
| **Actor sim (hot)** | Individual NPC nodes | Walk to tree, deliver grain, build animation, spear combat, pregnancy `_process` | Near player / assigned job / combat |
| **Settlement sim (warm)** | Clan-level state on land claim + ClanBrain | Stockpiles, craft timers, build progress, roster births/deaths, genetics on newborns, nomad pressure | Claim exists but actors may be despawned |

**Cold** (chunk seed + `MutationStore` only) applies to **world props** (trees, ground items), not to established clans with land claims.

---

## Simulation tiers (hot / warm / cold)

```
HOT — near player or active interest
  Full NPC nodes: physics, FSM, TaskRunner, WorkRequests, combat, reproduction _process

WARM — clan has claim/campfire, player far away
  No (or few) actor nodes
  Settlement tick on ClanBrain + claim: economy, roster, build %, passive buildings

COLD — unloaded wilderness chunk, no active claim
  Seed + mutations only; no village sim
```

### Interest triggers (today)

From `WorldInterestManager`:

- Player chunk disk (`WorldGenConfig.get_effective_load_radius()`)
- Chunks with active land claims / campfires (future: union all MP peers)
- Chunks with active hunt parties (hook)

**Claim “active” for full ClanBrain** today: within ~2400px of a player (`CLAIM_ACTIVE_WORLD_RADIUS`). Outside that → `dormant_update()` on the claim.

---

## What settlement sim must cover

A village living without the player is **not** genetics alone. Off-screen settlement state includes:

| Domain | On-screen (today) | Off-screen (required) |
|--------|-------------------|------------------------|
| **Population** | Live NPCs, baby growth component | Roster: counts, ages, roles; aging tick; death rolls |
| **Reproduction** | `ReproductionComponent` on live women | Pregnancy timers on roster; spawn babies on timer complete |
| **Genetics / traits** | Lineage, `card_index`, traits on spawn | Inherit on roster birth; drift per [genetics.md](future%20implementations/genetics.md) |
| **Stockpiles** | Claim / campfire / building inventories | Same inventories — authoritative on claim nodes |
| **Gathering** | Gather jobs, walk to resources | Abstract rates: `+wood`, `+grain`, … per tick from worker count + need |
| **Crafting** | WorkRequests → women walk → TaskRunner | Resolve chains at settlement rate (see production mapping below) |
| **Passive production** | Drying rack timer, campfire meat→cooked | **Keep running** — already timer-based on buildings |
| **Construction** | Clansman walks to site, build FSM | Build request **progress %** advances per tick; spawn building when complete |
| **Pressure** | Panic state, nomad mode walk | Food/wood decay (partially live); nomad trigger / abstract relocate |
| **Raids / hunts** (optional) | Full combat / AoH | Abstract outcomes or defer until hot — TBD |

---

## On-screen → off-screen mapping

When a clan goes **warm**, spatial jobs become **rates**:

| Hot (actor) | Warm (settlement tick) |
|-------------|-------------------------|
| Woman walks grain to oven | `grain → bread` at `f(women, oven, grain_stock, skill)` |
| Clansman pathfinds to build hut | `build_request.progress += rate × delta` |
| Gather task at tree | `inventory += gather_rate × workers × delta` |
| Pregnancy `_process` countdown | `roster.pregnancies[i].timer -= delta` |
| Hunt party in forest | `+meat` abstract roll or pause until hot |

**Passive systems** (no pathfinding) can stay on building nodes in warm mode:

- Campfire wood burn / meat cook ([camp_relocation.md](camp_relocation.md) — decay can run off-screen)
- Drying rack hide → leather timer ([production_economy.md](production_economy.md))

---

## Settlement tick (design sketch)

**Owner:** server only (same as ClanBrain). Clients display results.

**Cadence:** e.g. every 5–30s per warm claim (tune vs `DORMANT_EVAL_INTERVAL` = 30s today).

**Pseudocode:**

```gdscript
func settlement_tick(claim, clan_brain, elapsed_sec: float) -> void:
    var roster := claim.get_roster_snapshot()  # population, pregnancies, genetics refs
    var buildings := claim.get_building_capabilities()  # oven, rack, farm, …
    var stock := claim.inventory

    # Pressure
    apply_food_consumption(roster, stock, elapsed_sec)
    apply_wood_burn(campfire, elapsed_sec)

    # Economy (abstract gather + craft)
    run_gather_rates(roster, stock, biome, elapsed_sec)
    run_production_chains(roster, buildings, stock, elapsed_sec)
    advance_passive_buildings(buildings, elapsed_sec)

    # Construction
    advance_build_requests(clan_brain.build_requests, roster, elapsed_sec)

    # People
    advance_pregnancies(roster, elapsed_sec)
    resolve_births(roster, stock, genetics_rules)
    apply_aging_and_mortality(roster, stock, elapsed_sec)

    # Optional: nomad / raid abstract rolls
    evaluate_settlement_pressure(claim, clan_brain, roster, stock)

    claim.write_roster(roster)
    # Do not spawn actor nodes until wake / interest
```

**Determinism:** tick inputs = `world_seed + clan_id + world_time + roster_hash` so MP and save/load stay consistent.

---

## Wake and reconcile

When player enters interest or chunk loads:

1. **Read settlement state** — roster deltas since last wake, finished buildings, inventory changes.
2. **Spawn or update actors** — `spawn_npc_from_sleep_data` / roster match; new babies, aged adults, missing dead.
3. **Place buildings** — instantiate any completed build requests.
4. **Resume hot sim** — ClanBrain full `update()`, WorkRequests, FSM.

**Invariant:** returning after time `T` away should match **one continuous settlement sim** for `T`, not a reset.

---

## Terminology (avoid confusion)

| Term in code/docs | Means | Settlement frozen? |
|-------------------|-------|--------------------|
| **Sim dormant** (`set_sim_dormant`) | Node exists; physics/perception off | No — claim still runs |
| **Tier B sleep** (`NPCSleepManager`) | Node despawned; record in dictionary | **Only if no settlement tick** — bug for sandbox |
| **ClanBrain dormant** | Full brain off; `dormant_update()` | Partial today — must expand to full settlement tick |
| **Claim inactive** | Far from all players | Should → **warm**, not **off** |

---

## Current implementation (honest)

| Piece | Status |
|-------|--------|
| Land claims on `world_objects` (survive chunk unload) | ✅ |
| `NPCSleepManager` serialize / wake | ✅ Partial — missing `genetics_profile`, pregnancies, inventory in sleep record |
| `ClanBrain.update()` when claim active | ✅ Full job board, raids, hunts |
| `ClanBrain.dormant_update()` when claim inactive | ✅ **Settlement tick** — gather, hunt, slaughter, feed, passive craft, pregnancy (see [off_screen_clan_balance.md](future%20implementations/off_screen_clan_balance.md)) |
| Abstract gather + regen | ✅ Shipped — ⚠️ **pseudo-biome gating** can block all edible food on some chunks until fixed |
| Emergency livestock slaughter | ✅ `AbstractSlaughter` when STARVING + empty pantry + hunt failed |
| Reproduction on live women | ✅ On-screen only |
| WorkRequests / TaskRunner | ✅ On-screen only |
| Build requests (milestone construction) | ✅ On-screen only |
| Passive drying rack / campfire timers | ✅ Can run on building nodes |
| Full genetics evolution | ❌ [genetics.md](future%20implementations/genetics.md) |
| Chunk-spawned clans under `Chunk_*` | ⚠️ Lost on unload unless persisted ([game_map.md](game_map.md) §11) |

**Gap:** actor sleep works for perf; **settlement tick runs** off-screen gather/hunt/feed/births, but **baseline food balance is not stable** until placeholder pseudo-biomes allow edible gather on every chunk (or food-first when starving). Full off-screen **construction milestones** and genetics evolution remain deferred.

---

## Design rules (for implementation)

1. **Never sleep a clan’s settlement state — only sleep its actors.**
2. **Building timers and claim inventories** stay authoritative on server whether actors exist.
3. **Roster is source of truth** for off-screen people; actors are views that reconcile on wake.
4. **No global `_process` over all NPCs** — warm clans tick at claim granularity.
5. **MP:** clients do not run settlement ticks; they receive inventory/roster/build deltas.
6. **Perf:** warm tick cost ∝ **active claims**, not ∝ map population node count.
7. **Return visit fantasy:** player must be able to leave, explore, return — same clan, more babies, new hut, changed stockpiles.

---

## Multiplayer notes

- **Server** runs hot sim for interest bubbles + warm settlement ticks for all claims with state worth persisting (or all claims in world — tune).
- **Interest union:** keep chunks loaded if **any** peer needs them; settlement tick independent of chunk mesh load when claim node persists.
- **Replication:** batch settlement deltas (inventory diff, `building_placed`, `npc_born`, `npc_died`) — not per-NPC transforms while warm.
- **Join-in-progress:** new client applies claim snapshot + roster, spawns local visuals when in range.

See [multiplayer.md](multiplayer.md), [game_map.md](game_map.md) §14.

---

## Implementation phases

| Phase | Deliverable | Pass criteria |
|-------|-------------|---------------|
| **0** | This doc + cross-links | Team agrees actor vs settlement split |
| **1** | Expand sleep record + roster schema | genetics, pregnancy, inventory survive sleep/wake |
| **2** | Settlement tick v1 | Off-screen food + passive buildings + consumption (extend `dormant_update`) |
| **3** | Abstract gather + production | Stockpiles change without WorkRequest actors |
| **4** | Abstract build progress | New building appears after warm timer |
| **5** | Roster reproduction + aging | Babies/deaths while away; wake spawns match roster |
| **6** | Genetics on roster birth | Hook to genetics.md when implemented |
| **7** | MP replication | Server warm ticks; clients reconcile |
| **8** | Playtest gate | Leave clan 10 min, return — pop/build/stock changed deterministically |

---

## Verification / playtest scenario

1. Fix seed + clan name; note population, bread count, build queue.
2. Travel beyond `CLAIM_ACTIVE_WORLD_RADIUS` until actors sleep.
3. Wait real-time (or fast-forward world clock in dev).
4. Return to claim.
5. **Expect:** same claim location; inventory/build/roster reflect settlement tick — not identical frozen state.
6. Log via `--lag-profile` — actor count down while away, settlement tick cost flat per claim.

---

## File index

| Area | Path |
|------|------|
| Claim + dormant brain routing | `scripts/land_claim.gd` |
| Dormant tick (today) | `scripts/ai/clan_brain.gd` — `dormant_update()` |
| Active brain | `scripts/ai/clan_brain.gd` — `update()` |
| Actor sleep | `scripts/systems/npc_sleep_manager.gd` |
| Actor serialize | `scripts/npc/npc_base.gd` — `serialize_to_sleep_data()` |
| Wake spawn | `scripts/main.gd` — `spawn_npc_from_sleep_data()` |
| Interest / claim active | `scripts/systems/world_interest_manager.gd` |
| Production (hot) | `scripts/data/production_chain_registry.gd`, WorkRequests in ClanBrain |
| Reproduction (hot) | `scripts/npc/components/reproduction_component.gd` |
| Chunk / claim persistence | [game_map.md](game_map.md) §11, §13 |
| Perf context | [guides/lag.md](../guides/lag.md) |

---

## Changelog

| Date | Change |
|------|--------|
| Aug 2026 | **Design lock:** continuous 2D plane (not instanced colony maps); geography vs sim fidelity |
| Aug 2026 | Initial framework — actor vs settlement, hot/warm/cold, gaps, phases |
