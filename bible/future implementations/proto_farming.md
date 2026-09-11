# Proto farming — settled crops in a ring (future)

**Status:** Design draft — **not implemented**.  
**Scope:** Adds **in-claim agriculture** (crop ring around a field building). Complements — does **not** replace — today's **wild wheat gather** and the existing **Farm** building (sheep → wool).  
**Drafted:** Sep 2026

---

## Why

**Today:**

- **Grain** comes from gathering **wild wheat** that spawns **outside** any land-claim radius (bible §XII, GDD).
- **Oven:** 1 Wood + 1 Grain → 1 Bread (15s); women haul grain from claim stockpile.
- **Farm** building = **animal processing** (fiber + sheep → wool), **not** planted crops (`bible/farms.md`).

**Future goal:** **Proto farming** — a building **inside the claim** with **crops growing in a ring** around it. Settled clans can feed themselves without sending everyone to the wilderness for wheat. Still Stone Age: simple plots, not industrial farms.

---

## Naming (avoid confusion)

| Term | Meaning today | After proto farming |
|------|---------------|---------------------|
| **Farm** (building) | Sheep slots; fiber → wool | **Keep name** — animal farm, unchanged |
| **Wild wheat** | World gatherable outside claims | Still exists; competes with settled grain |
| **Field / Planting Hut** (proposed) | — | New building; crop ring host |
| **Grain** | Resource from wild wheat gather | Also from **harvesting settled crops** |

Do **not** overload the existing `FARM` ResourceType for crops — add a new building type (e.g. `FIELD`, `PLANTING_HUT`, or `CROP_RING`).

---

## Core loop (sketch)

1. Player or AI places **Field** building inside land-claim radius (same placement rules as other buildings: 50px min spacing, 128×128 footprint).
2. On build (or first activate), **N crop plots** appear in a **ring** around the building center (not under the sprite).
3. Player or woman **plants** (consumes seed/grain/fiber — TBD) → plot state `GROWING`.
4. After **grow time** (sim tick or real-time timer), plot → `HARVESTABLE`.
5. **Harvest** → grain (or crop-specific item) into building or claim inventory.
6. **Oven** chain unchanged: wood + grain → bread.

```
        [plot][plot][plot]
      [plot]  FIELD  [plot]
        [plot][plot][plot]
              ↓
         claim stockpile
              ↓
            Oven → bread
```

---

## Crop ring layout (proposed)

| Parameter | Starter value | Notes |
|-----------|---------------|-------|
| Ring radius | ~80–120 px from building center | Inside claim; visible ring |
| Plot count | 6–8 | Even spacing on circle |
| Plot size | 32×32 or 64×64 | Match art grid |
| Max fields per claim | 1–2 (v1) | Tune for balance |
| Grow time | 2–5 sim days | Tie to `SimulationManager` tick |

Plots are **children of the Field node** or a dedicated `CropPlot` scene registered in `ClaimBuildingIndex`.

---

## Workers & automation

**v1 options** (pick one before coding):

| Mode | Behavior |
|------|----------|
| **Passive growth** | Plots grow on sim tick; player/woman only plants + harvests |
| **Woman slot (1)** | Assigned woman runs plant/harvest jobs like Oven |
| **ClanBrain abstract** | Off-screen claim accrues grain from field count (settlement sim path) |

Recommended: **1 woman slot** + reuse **OccupationSystem** / `production_work` pattern so Field feels like Oven/Farm family.

**No animal slots** on Field.

---

## Wild wheat vs settled grain

Both can coexist:

| Source | Pros | Cons |
|--------|------|------|
| **Wild gather** | No building cost; works at campfire tier | Travel outside claim; AoH/hunt competition |
| **Settled ring** | Food inside walls; scales with women/fields | Building + seed cost; raiders can burn fields (future) |

**Design intent:** Early game = wild gather + Oven milestone. Mid game = Field when clan is rooted on a **land claim** (not campfire-only — align with Farm/Dairy milestones).

**Wild wheat rule:** Can stay “only outside claims” **or** wild wheat inside claim is disabled when Field exists — **decide at implementation** (default: keep wild rule globally; settled grain is additive).

---

## Raid / wipe interaction

- **LOOT raid:** Field building inventory + unharvested grain in plots (if stored on building).
- **WIPE / flag destroy:** Field node destroyed with other buildings; **crop state is not persisted** unless harvested to claim stockpile first (same as “loot before smash”).
- **Future:** partial field damage (trampled plots) without full wipe — not v1.

---

## Multiplayer & chunk rules

Per project architecture:

1. **Initial plot layout:** deterministic from `world_seed + claim_id + field_instance_id` if any procedural variation — otherwise fixed ring template.
2. **Mutations:** plot state (`EMPTY`, `GROWING`, `HARVESTABLE`), timers, and harvested yields are **server-authoritative** deltas (not regenerated from seed alone after plant).
3. **Streaming:** Field + plots spawn/despawn with claim chunk activity; save plot state on claim persist.

---

## ClanBrain hooks (future)

- Queue **Field** milestone when `food_days_buffer` low and Oven exists but wild gather is far/unsafe.
- `WorkRequest`: plant when plots empty + seed in stock; harvest when `HARVESTABLE`.
- Off-screen sim (`settlement_sim.md`): abstract `+grain_per_tick` from field count when claim is dormant.

---

## UI

- **Build menu:** new card (Field / Planting Hut) alongside Oven, Farm, etc.
- **Field inventory UI:** ring status (icons per plot: empty / growing / ready), plant/harvest actions or auto-jobs.
- **Not** the same as opening Oven — Field is **world-visible ring** + small building panel.

---

## Order to build

1. **Lock v1 decisions** — building name, plot count, grow time, seed cost, woman slot yes/no.
2. **`CropPlot` scene** — state machine: EMPTY → GROWING → HARVESTABLE.
3. **`FieldBuilding`** extends `BuildingBase` — spawns ring on `_ready`, registers with `ClaimBuildingIndex`.
4. **Plant / harvest server verbs** — validate claim, range, plot state.
5. **Hook grain** into existing `ResourceData.GRAIN` + Oven recipes.
6. **Woman jobs** (if using slots) — plant and harvest task chain.
7. **Build menu + milestone** — land-claim only (like Farm/Dairy).
8. **ClanBrain + off-screen** abstract production optional pass.
9. **Playtest JSONL** — `field_planted`, `field_harvested`, grain/day from settled vs wild.

---

## Reliability gates (lock before coding)

| Decision | Status |
|----------|--------|
| New building type id (not reuse FARM) | **Proposed** |
| Ring geometry (count, radius) | **Open** |
| Seed input (grain vs fiber vs new item) | **Open** |
| Grow clock (sim tick vs wall time) | **Open** — prefer sim tick |
| Woman slot vs passive | **Open** — lean 1 woman |
| Wild wheat interaction | **Open** — lean keep both |
| Raid damage to plots | **Out of v1** |

---

## Related docs

- `bible/farms.md` — **current** Farm/Dairy/Oven (animal + oven production)
- `bible/bible.md` §XII — wild wheat rule, Oven bread chain
- `bible/settlement_sim.md` — off-screen grain production
- `bible/future implementations/village.md` — supply/demand at scale
- `scripts/buildings/building_registry.gd` — where new building registers

---

## Promote-to-bible criteria

When shipped, add one row to `bible.md §XXII` and a short §XII note: “Settled fields (planned doc) add in-claim grain; wild wheat still …”

Ship criteria:

- Field building places inside claim; crop ring visible.
- Plant → grow → harvest yields grain into claim/building stock.
- Oven bread chain works from settled grain.
- Server owns plot state in MP path.
