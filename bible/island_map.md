# Authored island map (art reference)

**Status:** **Design lock — in active authoring.** Layout spec is final; Godot pipeline is **partially built** (water layer shipped in editor; biomes and export still pending). Today’s playable main loop still uses procedural chunks until authored chunks replace them.  
**Canonical design doc:** **[environment_goal.md](environment_goal.md)** — map, biomes, weather, resources, wildlife. **This file** is the **layout index + map2 checklist + implementation progress tracker**. **If art and environment_goal disagree, environment_goal wins** (update art unless map is explicitly re-approved).  
**Canonical image:** [`assets/island_map2.jpg`](assets/island_map2.jpg) (`map2.jpg`) — **guide, not pixel law**  
**Last updated:** September 2026 (water paint pipeline + progress tracker)

**See also:** [game_map.md](game_map.md) · [future implementations/island_mp.md](future%20implementations/island_mp.md) · [earlygame_vision.md](earlygame_vision.md) §7 · [roadmap_2026.md](roadmap_2026.md) Phase 5

---

## 1. Island overview

| Property | Spec |
|----------|------|
| **Shape** | Single large landmass; **organic, irregular** coastline — not geometric |
| **Look** | **Soft continuous ground** — gradual biome blends; **no** RimWorld/DF square cells or hard 90° biome corners. Chunks = load streaming only (invisible) |
| **View** | Top-down orthographic 2D (tactical / classic overworld) |
| **Scale** | Large enough for **diverse ecosystems** and multiple clans |
| **Orientation** | North up, south down, west left, east right |
| **Boundary** | **100%** of playable land is inside the blue ocean rim |
| **Ocean** | Solid uniform blue — **impassible** world edge beyond beaches |

All clans, AI tribes, and MP sessions play on **this fixed geography** once worldgen ships. Chunk streaming loads **pieces** of the map; content comes from **authored biome + prop data**, not infinite noise.

**Not today’s code:** `ChunkGenerator` pseudo-labels (`forest`, `plains`, `rocky`, `swamp`) are off-screen placeholders only.

---

## 1b. Map authoring pipeline (data layers)

**Decision (locked):** The shipping island is **hand-authored**, not procedurally generated. map2 guides layout; **authored PNG/layer files** are source of truth.

| Layer | File / storage | Role | Status |
|-------|----------------|------|--------|
| **Biome base** | `maps/island/biome_mask.png` | Regional IDs: savanna, desert, jungle, swamp, glacier, ocean, beach | ✅ **Generated** by `bash tools/rebuild_island_biomes.sh` (see 1c) |
| **Water / rivers** | `maps/island/water_layer_guides.png` → `water_layer.png` | Hand-painted river paths — separate from biome IDs. **Guides are the truth**; `water_layer.png` is a copy, never mutated by tools | ✅ **Painted + saved** (WorldMapEditor) |
| **Wetland overlay** | TBD (`wetland_layer.png` or chunk field) | 1–3 tile bank strip along rivers | ⬜ Not started |
| **Pass corridors** | TBD (`pass_layer.png` or `mountain_cost_mask`) | Narrow routes through glacier | ⬜ Not started |
| **Forest patch overlay** | TBD | ~10% scattered on savanna | ⬜ Not started |
| **SPRING points** | TBD (point layer) | Desert oases only — no glacial drainage | ⬜ Not started |
| **Ground art** | `maps/island/chunks/tile_<cx>_<cy>.png` | Seamless 2048×2048 visual slices (textures only) | ⬜ Artist pass |
| **Chunk gameplay data** | `world/island/chunks/chunk_<cx>_<cy>.tres` | biome grid, water, passes, prop zones | ⬜ Export not wired |
| **Runtime mutations** | `MutationStore` | Chops, depletions, builds on top of base map | ✅ Exists (dev) |
| **Climate overlays** | `ClimateState` + chunk overlays (Phase 6) | Flood, drought, glacier grow, aridification | ❌ Design only — [environment_goal.md](environment_goal.md) §19 |

**Editor:** `scenes/WorldMapEditor.tscn` — view/pan/zoom, water paint, save, connectivity check, **Validate Map Shape**, **Fix Map (Specks + Topology)**. Biome/pass/spring brushes **planned next**.

### 1c. Biome mask pipeline (deterministic, one command)

`bash tools/rebuild_island_biomes.sh` rebuilds `biome_mask.png` from map2 + the river guides. Seed = `world_seed` in `island_meta.json`; same inputs → same mask.

| Step | Tool | What it does |
|------|------|--------------|
| 0 | `cp` | `water_layer.png ← water_layer_guides.png` (rivers are never edited by tools) |
| 1 | inline | land → savanna (ocean + rivers untouched) |
| 2 | `paint_biome_from_map2.py` | glacier (centre, radius-grown), desert (NE wedge), jungle (SW wedge), swamp (NW wedge, one body, grown to ~10 % of land, never crosses a river) |
| 3 | `shape_biome_regions.py` | **organic borders**: drop stray blobs → open/close (kill spikes) → seeded domain-warp (3 octaves) → blur + threshold → compose glacier > desert > swamp > jungle; desert retracts 2 tiles from rivers; beach on ocean shore (not swamp shore) |
| 4 | `clean_biome_mask_specks.py` | 3/4 speck rule, land/ocean topology, desert off rivers |
| 5 | `clean_biome_mask_specks.py --check-only` | gate: 0 specks, 0 topology faults, 0 straight borders |
| 6 | `render_biome_preview.py` | `maps/island/preview_biomes.png` for eyeballing |

**Why region shaping, not tile nibbling:** flipping tiles along a straight edge only turns a line into a dashed line (still reads as a ruler). Warping the whole region with low-frequency seeded noise gives real curves; the 3/4 speck rule then keeps the 1-tile scale clean.

**Straight-border metric** (`biome_mask_shape_rules.py` ↔ `mask_topology.gd`): collinear edge chains (gaps ≤ 2 tiles merge, so dashed lines count). Fail at **≥ 28 tiles** — a smooth curve of radius R has grid flats ≈ 2√R, so regions this size legitimately produce flats up to ~25; ≥ 28 can only be a genuinely straight edge. 8–27 is reported as minor.

**Current result:** savanna 66 %, jungle 14.7 %, swamp 9.9 %, desert 9.1 %, glacier 3.0 %, beach 0.8 %; longest straight chain 25.

**Runtime lookups:** `scripts/world/terrain_query.gd` — `get_biome()`, `is_water()` from masks + `island_meta.json`. Move cost, temperature, spring queries **planned**.

**Meta:** `maps/island/island_meta.json` — world size 65536×65536, 32×32 chunks, 64px sample stride, `water_layer_path`.

---

## 1c. Implementation progress (living checklist)

Update this section when a layer ships or validation passes.

### Authoring layers

| Step | Task | Status |
|------|------|--------|
| 1 | Island silhouette + ocean boundary (from map2 / biome mask) | 🟡 Partial |
| 2 | Paint **regional biomes** (savanna, desert NE, jungle SW, swamp W, glacier center) | ⬜ Next |
| 3 | Paint **four river systems** from glacier (separate headwaters OK) | ✅ Done (`water_layer.png`) |
| 4 | Paint **wetland** strips along river banks | ⬜ |
| 5 | Paint **glacier** zone + **pass corridors** through center | ⬜ |
| 6 | Paint **forest patch** overlay (~10% on savanna) | ⬜ |
| 7 | Place **SPRING** oases in desert | ⬜ |
| 8 | Mark gameplay zones (quadrant rares, MP spawns, trade nodes) | ⬜ |

### Tooling & engine

| Step | Task | Status |
|------|------|--------|
| A | WorldMapEditor **water paint** + save | ✅ |
| B | WorldMapEditor **biome paint** brush | ⬜ Next |
| C | Overlay brushes (wetland, forest, pass, spring) | ⬜ |
| D | **Validation panel** (4 river systems → coast, desert-no-rivers, biome %) | ⬜ |
| E | Fix river check: **4 systems**, not one connected blob | ⬜ |
| F | **Chunk export** pipeline | ⬜ |
| G | `ChunkManager` loads authored chunks (suppress proc on shipping map) | ⬜ |
| H | Wire **Main** to authored ground shader / chunk tiles | ⬜ (`_setup_biome_ground()` missing) |
| I | `TerrainQuery`: move cost, temperature, spring, overlay priority | ⬜ |

### Art delivery

| Step | Task | Status |
|------|------|--------|
| J | Per-biome seamless ground textures | ⬜ |
| J | 2048×2048 chunk slices, zero visible seams | ⬜ |
| J | Soft organic biome blends in art (logic grid may snap under hood) | ⬜ |

### Validation (map data final)

- [ ] Four river systems each reach coast (or NE lake chain → coast)
- [ ] **No rivers in desert** (oases = SPRING only)
- [ ] Glacier ~3–5% at center; at least one pass corridor
- [ ] Biome percentages roughly match §4 table
- [ ] All layers export to chunks; `TerrainQuery` spot-checks pass
- [ ] MP: same authored files + seed = same world

### Gameplay hookup (map shippable in game)

- [ ] Movement costs (water, glacier, passes)
- [ ] Cold / heat debuffs from biome
- [ ] Biome gatherable + wildlife spawn tables
- [ ] River floodplains as settlement targets

### Later — Climate Change (Phase 6, not v1)

**Full spec:** [environment_goal.md](environment_goal.md) §19 — **Climate Change mechanic**.

| Feature | Summary |
|---------|---------|
| **Flood / spring swell** | Wetland banks widen; extra water **outside** base channel |
| **Drought** | Rivers **shrink** — overlay masks base water; global or per-system (`RIVER_NW`…`NE`) |
| **Ice age** | Glacier biome grows from center |
| **Aridification** | Desert creeps into savanna; villages abandon |
| **Rituals** | Sacrifices / ceremonies → `ritual_pressure` → rain or slower drought |

**v1 rule:** Base PNGs (`water_layer.png`, `biome_mask.png`) are **never edited at runtime**. Climate = server overlays on top. Reserve **river system ids** at export time.

**Suggested work order:** 2 → 5 → 4 → 6 → 7 → B–I → validation → art (J) → gameplay tables.

---

## 2. Center of origin — glacier / snow cap

| Property | Spec |
|----------|------|
| **Description** | High-altitude **snow field + glacier** (volcanic massif). Pure white snow; lighter blue **glacial river channels** in the ice |
| **Location** | **Absolute geographic center** |
| **Area** | **~3–5%** of total island land (small but critical) |
| **Biome ID** | `GLACIER` / `ALPINE` |
| **Design rule** | **All rivers originate here.** This is the **watershed divide** — zero-point for hydrography |

**Gameplay:** Cold hazard, stone/flint/obsidian, mountain passes; headwaters for drink + settlement competition.

---

## 3. Biome distribution (clockwise from southwest)

Traverse the island **clockwise starting at the SW corner**. Percentages are **land area only** (excluding ocean).

### A. Jungle — southwest corner

| Property | Spec |
|----------|------|
| **Look** | Dense **deep emerald green** — thick canopy, damp earth; **richer/darker** than savanna |
| **Location** | Entire SW “finger”; blends into lower-left central region; **north border = swamp** |
| **Area** | **~15%** |
| **Biome ID** | `JUNGLE` |
| **Transitions** | **Gradual** blend to lighter savanna-green on **east and north** edges |

**Gameplay:** Fiber, exotic dye, dense cover, late-game extraction; slow movement.

### B. Swamp — mid-west (adjacent to jungle)

| Property | Spec |
|----------|------|
| **Look** | **Dark muddy brown** wet ground; murky water pools (darker grey-blue shapes) |
| **Location** | **North of jungle**, on **western coastline** — muddy bay |
| **Area** | **~10%** |
| **Biome ID** | `SWAMP` / `WETLAND` |
| **Transitions** | **Abrupt but natural** from jungle; **messy, irregular** edges |

**Gameplay:** Slow travel, unique gatherables, croc hazard (planned). **Coast here = muddy**, not sandy beach.

### C. Great savanna / plains — base biome (core)

| Property | Spec |
|----------|------|
| **Look** | **Light green** open grassland; scattered **light tan** dirt / dry-earth patches |
| **Location** | Central + north-central; wraps glacier; borders **almost every other biome** |
| **Area** | **~55%** (includes glacier footprint in total land math) |
| **Biome ID** | `SAVANNA` / `PLAINS` |
| **Transitions** | **Gradual** blend into neighbors — **except** rivers (sharp water boundary) |

**Gameplay:** Default terrain — **best nomad starts**, open herding, hunt corridors, tan clearings for future **Field** rings.

### D. Great desert — northeast quadrant

| Property | Spec |
|----------|------|
| **Look** | **Tan-yellow sand**; **cracked earth / dune texture** on eastern half |
| **Location** | **Entire NE corner** + far eastern edge — large dry cape |
| **Area** | **~20%** |
| **Biome ID** | `DESERT` |
| **Transitions** | **Gradual** savanna-green → tan sand over short distance |

#### CRITICAL design rule — desert is arid

> **No rivers flow into, through, or across the desert region.**

Rivers may approach the desert boundary but **must not** enter cracked desert terrain. Desert water = **oasis seeps / springs only** (hand-placed `SPRING` points), not glacial drainage.

**Gameplay:** Heat stress, salt, flint; sparse forage; high travel/raid pressure; trade destination for wet-biome goods.

---

## 4. Land-use summary (land only)

| Biome | ~% of island |
|-------|----------------|
| Great savanna / plains (base) | **55%** |
| Great desert (NE) | **20%** |
| Jungle (SW) | **15%** |
| Swamp (mid-west) | **10%** |
| Glacier / center | **3–5%** (counted inside savanna band above) |

**Overlay — scattered forest patches:** **~10%** of island total, **not** a separate ring. Dark green canopy + brown litter dots on savanna, especially **north of glacier** and **NE of central plain**.

---

## 5. Special sub-features & overlays

| Feature | Spec |
|---------|------|
| **Scattered forest patches** | Dark green + brown dots on savanna; ~10% scattered; **Biome ID** `FOREST_PATCH` overlay on `SAVANNA` |
| **Beaches** | Narrow **light tan / white** sand band on **almost entire coast**; widens in bays |
| **Swamp coast** | **No beach** — swamp meets water as **mud** |
| **Tan dirt patches** | Inside savanna — proto-farming clearings, visual variation |
| **River overlay** | Light blue water texture; `RIVER` + optional `WETLAND` bank strip |
| **Springs / oases** | Hand-placed in desert (no river drainage there) |

**Asset rule:** Trees, rocks, bushes, buildings go **on top of** ground texture and **respect biome boundaries**.

---

## 6. River systems (hydrography)

**Origin:** Central glacier / snow cap only.  
**Pattern:** **Radial** — all channels flow **outward** from center.  
**Count:** **Four primary river systems** (not more without revising map2).

| System | Flow | Mouth / notes |
|--------|------|----------------|
| **Northwest** | Center → NW | **Splits into two main mouths**; encloses large **triangular landmass** / NW bay |
| **West** | Center → W (straightest) | Western-central bay; **prominent delta** |
| **Southeast** | Center → SE | **Delta** — multiple channels just before coast |
| **Northeast** | Center → N/NE (short, steep) | Small **inland lake / tributary** system; then to **northern coast** |

**Visual:** Simple **light blue** water texture on ground layer.

### Hydrography rules (hard constraints)

1. **All rivers start at the glacier** — no orphan streams.
2. **Four separate systems** — each may have its own **headwater / melt spring** at the glacier. Gaps between systems at the center are **intentional** (separate ice-melt sources), not bugs. Do **not** force one 8-connected river blob.
3. **Rivers never cross into desert** — arid NE stays dry except authored oases.
4. Rivers are **crossable** (speed penalty + hazard — [environment_goal.md](environment_goal.md) §17).
5. **Ocean** beyond beach = **not** crossable.

**Validation:** Check that **each of the four systems** reaches the ocean (or NE lake → coast), not that all water tiles touch in one component.

### Dynamic water (runtime — Phase 6 only)

Base map = static `water_layer.png`. **Climate Change** adds temporary overlays — see [environment_goal.md](environment_goal.md) §19.

| When | Effect |
|------|--------|
| Spring / rain | River high flow; banks swell |
| Flood year | Wetland widen; grain bonus → rot |
| **Drought** | River **shrinks** (mask base tiles); fords dry |
| Recovery | Overlays ease back |

**Not in v1.** Static painted rivers = normal flow until Phase 6 ships.

```text
                         NORTH (short NE river + lake)
                                |
    NW bay ◄── NW system ──[ GLACIER ]── West system ──► W bay
              (2 mouths)      / | \        (delta)
                             /  |  \
                    SE system   |   (no river → desert NE)
                    (delta)     |
                         SW jungle + swamp
```

---

## 7. Coast & ocean

| Feature | Spec |
|---------|------|
| **Coastline** | Irregular — **deep bays** (west, northwest), **narrow peninsulas** (NW hook) |
| **Ocean** | Uniform blue — open sea on all sides |
| **Landing** | Beaches = nomad starts, fishing, salt |

---

## 8. Build constraints (authoring)

| Rule | Detail |
|------|--------|
| **Top-down only** | No perspective distortion or 3D elevation on the ground paint layer |
| **Paint-first** | Complete **tabletop ground texture** before placing props |
| **Seamless tiling** | If chunks tile, border cells must match neighbors — validate in editor |
| **Biome fidelity** | Respect percentages and **desert-no-rivers** when painting masks |
| **Props later** | Ground layer = biomes + water; assets respect boundaries |

---

## 9. Layout at a glance

```text
                    NORTH (NE river, forest patches)
                           |
     NW hook / twin mouths -+---- GREAT DESERT (20%, NO RIVERS)
              \            |            /
               \     [GLACIER 3-5%]    /
                \    /  |  |  \      /
         W bay    West  |  |  SE     (dry cape east)
                \       |  delta   /
                 \  SWAMP + JUNGLE
                  \   (10% + 15%)
                    SOUTH coast
         ~~~~~~~~ SAVANNA / PLAINS 55% (base) ~~~~~~~~
```

---

## 10. Compass quadrants (N / S / E / W)

Split with **vertical + horizontal lines through the glacier** ([environment_goal.md](environment_goal.md) §4).

| Quadrant | Dominant biomes | Suggested quadrant rare |
|----------|-----------------|-------------------------|
| **NORTH** | Savanna + forest patches + NE river lake | Glacier blue lichen |
| **EAST** | Desert cape + savanna edge | Tide pearl (coastal) or desert rare |
| **SOUTH** | Savanna + SE river delta | Sun resin tears |
| **WEST** | Bays, swamp, jungle edge | Sacred red ochre vein |

---

## 11. Gameplay zones

| Phase | Best map areas |
|-------|----------------|
| **First 10 min (nomad)** | **NW / SE / W coast** — beaches + savanna; **ABANDON CAMP** along shore |
| **Tier 2 flag (settle)** | **River floodplains** (not desert) — grain, water, Field ([proto_farming.md](future%20implementations/proto_farming.md)) |
| **Hunt (AoH)** | Savanna + forest-patch edges; prey radiating from glacier foothills |
| **Forage** | Forest patches, savanna, jungle/swamp specials, desert salt/flint |
| **Hard biomes** | Desert (heat, no rivers), swamp/jungle (slow), glacier (cold) |
| **Raid pressure** | Desert ↔ river valleys; mountain passes as chokepoints |
| **MP spawns** | Four coastal zones — one per quadrant ([island_mp.md](future%20implementations/island_mp.md)) |

---

## 12. Food layer ([earlygame_vision.md](earlygame_vision.md) three foods)

| Food | Where |
|------|--------|
| **Forage** | Savanna, forest patches, coastal berries, jungle edge |
| **Meat** | Savanna hunts; large prey near glacier foothills |
| **Grain / bread** | **River valleys only** (desert excluded from river grain) — wild wheat + future Field rings |

---

## 13. Relation to `environment_goal.md`

**[environment_goal.md](environment_goal.md) is the master doc** for map layout, wedge biomes, weather, resources, and wildlife.

**This file + map2** are the **art/layout checklist**:

| Topic | Source |
|-------|--------|
| Coast shape, bays, peninsula | **map2 / this doc** |
| Desert = NE, **no rivers** | **map2 / this doc** |
| Jungle SW 15%, swamp 10%, savanna 55% | **map2 / this doc** |
| Gatherable / wildlife kits, seasons, trade | **environment_goal.md** §5–6, §9–10, §19 |

Each authored cell: **`biome_id`** + overlays (`RIVER`, `WETLAND`, `FOREST_PATCH`, `SPRING`) + **quadrant** for rares.

---

## 14. Implementation path

**Phase 1 — Authoring pipeline (in progress)**

1. ✅ **Water layer** — paint in `WorldMapEditor`, save to `water_layer.png`; `TerrainQuery.is_water()`.
2. ✅ **Biome paint** — `bash tools/rebuild_island_biomes.sh` (regional wedges + organic shaping, §1c).
3. 🟡 **Glacier + pass corridors** — glacier zone done; narrow routes through center pending.
4. ⬜ **Overlays** — wetland banks, forest patch, desert SPRING points.
5. 🟡 **Validation** — specks, topology, desert-off-river, straight borders gated in `--check-only` + editor Validate; biome % printed by the pipeline.
6. ⬜ **Chunk export** — slice layers into 32×32 × 2048px chunk files.
7. ⬜ **Runtime** — `ChunkManager` loads authored data; Main uses authored ground.

**Phase 2 — Content on the map**

8. **Ocean boundary** at coast; swamp = muddy shore (no beach tile).
9. **Four quadrant spawn zones** + claim non-overlap.
10. Biome gatherable + wildlife spawn tables per zone.
11. **MutationStore** for player deltas (unchanged MP story).

**Retired / dev-only:** JPG river trace and hub-and-spoke proc rivers (`build_biome_mask_from_map2.py --phase rivers-proc`) — replaced by **hand-painted `water_layer.png`**. Proc tools may remain for grass baseline only.

---

## 15. Art pipeline

| Asset | Notes |
|-------|--------|
| **`island_map2.jpg`** | Layout truth — match percentages and hydrography |
| Ground tiles | Per-biome seamless sets ([environment_goal.md](environment_goal.md) §14) |
| Water | Light blue rivers; glacial blue in center; ocean = barrier |
| **Campfire vs flag** | Distinct anchors on savanna/coast ([nomad.md](nomad.md)) |

---

## 16. Open questions

1. ~~Exact **world size in pixels** / chunk count?~~ — **Locked:** 32×32 chunks, 65,536×65,536 px, 2048 px/chunk, 64 px sample stride ([environment_goal.md](environment_goal.md) §3.1).
2. **NE river** — does it terminate at northern coast only, or feed the inland lake exclusively before coast?
3. Single-player spawn at **nearest coast** until island ships?
4. **Glacier pass count** — one main corridor vs multiple? ([environment_goal.md](environment_goal.md) §22 Q3)
5. **Wetland width** — 1 tile vs 3 along streams? ([environment_goal.md](environment_goal.md) §22 Q10)
