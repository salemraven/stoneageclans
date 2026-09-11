# Environment — goals & design

**Purpose:** **Canonical single reference** for the shipping island — **map layout**, **wedge biomes**, **weather & seasons**, **resources**, **wildlife**, water, generational clan adaptation, trade routes, and phased work.

**Status:** **Design lock / in active authoring** — cross-check runtime in [game_map.md](game_map.md). Static island pipeline partial (water layer shipped). Living climate (hard biome IDs, regional knobs) is implemented but **off in shipping v1** unless `--climate` / tests — see [§19](#climate-change-mechanic-long-term-design-lock) and plan `living_world_map_system_815d153a.plan.md`.

**Art reference (layout truth):** [`assets/island_map2.jpg`](assets/island_map2.jpg) · quick index [island_map.md](island_map.md) (points here).

**Authority (locked):** If painted map and this doc disagree, **this doc wins** — update art to match unless you explicitly re-approve a map change.

**See also (by topic):**

| Topic | Doc |
|-------|-----|
| **Map layout & art (map2)** | [island_map.md](island_map.md) · [`assets/island_map2.jpg`](assets/island_map2.jpg) |
| **Chunks, streaming, code today** | [game_map.md](game_map.md) |
| **Island multiplayer** | [future implementations/island_mp.md](future%20implementations/island_mp.md) · [multiplayer.md](multiplayer.md) |
| **Wildlife behavior (code)** | [wildlife_movement.md](wildlife_movement.md) |
| **Seasonal herd migration** | [wildlife_migration.md](wildlife_migration.md) · §19 below |
| **Hunting** | [hunting.md](hunting.md) |
| **Gathering & tools** | [GatherGuide.md](GatherGuide.md) |
| **Herding (women, sheep, goats)** | [HERDING_SYSTEM_GUIDE.md](HERDING_SYSTEM_GUIDE.md) |
| **ClanBrain + local resources** | [ai_clan_brain.md](ai_clan_brain.md) · §16 below |
| **Generational looks / genetics** | [traits.md](traits.md) · [genetics.md](genetics.md) · [guides/pawn_goal.md](../guides/pawn_goal.md) |
| **Off-screen village sim** | [settlement_sim.md](settlement_sim.md) · [visual_vs_sim_layers.md](visual_vs_sim_layers.md) |
| **Early game on the island** | [earlygame_vision.md](earlygame_vision.md) · [nomad.md](nomad.md) |
| **Proto farming (river valleys)** | [future implementations/proto_farming.md](future%20implementations/proto_farming.md) |
| **Build order** | [roadmap_2026.md](roadmap_2026.md) |
| **Doc index** | [README.md](README.md) · [bible.md](bible.md) §XXII |

---

## Table of contents

1. [Vision (player-facing)](#1-vision-player-facing)
2. [Hand-authored island map](#2-hand-authored-island-map)
3. [Island layout & biomes](#3-island-layout--biomes)
4. [Quadrants — N / S / E / W](#4-quadrants--n--s--e--w)
5. [Biome gatherable kit (10 per biome)](#5-biome-gatherable-kit-10-per-biome)
6. [Biome wildlife kit (7 + universal herdables)](#6-biome-wildlife-kit-7--universal-herdables)
7. [Wood & stone — universal variants](#7-wood--stone--universal-variants)
8. [Central glacier — passable corridor](#8-central-glacier--passable-corridor)
9. [Generational clan adaptation](#9-generational-clan-adaptation)
10. [Trade routes (vs raiding)](#10-trade-routes-vs-raiding)
11. [What exists today](#11-what-exists-today)
12. [Chunk streaming & authored data](#12-chunk-streaming--authored-data)
13. [Foliage & lushness](#13-foliage--lushness)
14. [Ground tiles](#14-ground-tiles)
15. [Gatherables & tools](#15-gatherables--tools)
16. [ClanBrain & local resources](#16-clanbrain--local-resources)
17. [Water — design (no collision)](#17-water--design-no-collision)
18. [Hazards — water, glacier, biome predators](#18-hazards--water-glacier-biome-predators)
19. [Weather, seasons, catastrophes & climate change](#19-weather-seasons--catastrophes)
20. [Drinking & settlement value](#20-drinking--settlement-value)
21. [Phased implementation roadmap](#21-phased-implementation-roadmap)
22. [Open design questions](#22-open-design-questions)
23. [File index](#23-file-index)

---

## 1. Vision (player-facing)

Stone Age Clans should feel like a **harsh, alive wilderness** on a **single huge island** you designed by hand — not a random procedural world.

**Core environment goals:**

- **Hand-authored map** — full island layout, biomes, rivers, mountain passes, prop placement, and resource zones designed in-editor (or exported from an external map tool). **No procedural terrain generation** for the shipping island.
- **Chunk streaming** still loads/unloads **pieces** of that fixed map as players move (performance + multiplayer), but content comes from **authored data**, not noise rolls.
- **Ground** from **100% procedural shader** (`biome_ground.gdshader`): biome mask lookup + edge blending + FBM noise per biome — **no** artist-painted textures, seamless everywhere.
- **Look lock:** **No RimWorld / Dwarf Fortress blockiness** — no square biome cells, no hard 90° biome corners for the player. Chunks (2048px) are **load streaming only**; they must be invisible. Biome IDs for gameplay can snap under the hood; **what you see is continuous painted ground**.
- **Wedge biomes** — one organic island; **savanna/plains is the majority** (~55% land); **regional biomes** (desert NE, jungle + swamp SW, glacier center); **forest patches** scattered on savanna — **not** concentric rings around the whole island.
- **Central glacier / alpine** — snow, ice, rock ground at the watershed; cold hazard; **all rivers originate here**; passable foothills (no collision walls).
- **Coasts** — outer ocean is **impassible** (world boundary). Interior rivers/lagoons are **crossable with a speed penalty** and hazards (e.g. crocodiles).
- **Water is valuable** — paleolithic groups clustered near water; springs and river mouths create competition.
- **Trade routes** — biome-exclusive resources should encourage **exchange**, not only raid-and-pillage, if we can build trust/neutral-zone mechanics.
- **Resource kit per biome** — about **10 gatherables** each: **4 eatables**, **5 craftables**, **1 special**; **3 native dye colors** (many dual-use: food + dye).
- **Craft depth** — fabrics, jewelry, medicines, **body paints** from hunt drops (bear blood, croc bile, etc.) — short buffs, balanced per biome.
- **Quadrant rares** — island split **N / S / E / W** (circle + X through center); each quadrant holds **one extra rare** not found elsewhere.
- **Wood & stone everywhere** — every biome has both, but **different variants** and **different spawn ratios**.
- **Wildlife kit per biome** — **3 prey**, **3 predators**, **1 special** (predator or prey with melee self-defense, e.g. mammoth); special may be **tameable / rideable / pack labor**.
- **Universal herdables** — **sheep, goats, women** spawn in **all biomes** (like wood/stone) — core to herding, reproduction, and clan growth ([HERDING_SYSTEM_GUIDE.md](HERDING_SYSTEM_GUIDE.md)).
- **ClanBrain** should know resources **around the land claim**, not only chest contents.

---

## 2. Hand-authored island map

**Decision:** The island is **designed, not procedurally generated**.

| Approach | Use |
|----------|-----|
| **Authoring** | Paint biomes, water, glacier center, prop spawn zones in a map editor (`scenes/WorldMapEditor.tscn` or external tool → import). |
| **Storage** | Per-chunk **authored layer files** (e.g. biome ID grid, water mask, placed props with stable IDs) keyed by `chunk_coords`. |
| **Runtime** | `ChunkManager` loads authored chunk data when player enters range; **MutationStore** tracks depletions/chops/builds on top. |
| **Legacy procedural** | Today’s `ChunkGenerator` (seeded random fill) remains for **dev sandbox / tests** until authored chunks replace it. |

**Why hand-authored fits the project:**

- You control **story geography** — mountain pass to opposite coast, desert coast vs cold interior, where crocs live, where flint spawns.
- **Biome borders** are clean and intentional, not noise artifacts.
- **Trade routes** follow **real paths** you draw (river fords, mountain gaps, coastal trails).
- Multiplayer stays deterministic: **same authored files + same mutation snapshot = same world** for all clients.

**Authoring workflow (locked order — track progress in [island_map.md](island_map.md) §1c):**

1. Design **organic island silhouette** — ocean = impassible boundary (rectangular image file is fine; island shape inside is irregular). 🟡 Partial (map2 + biome mask ocean)
2. Generate **regional biomes** (§3): savanna base, desert NE, jungle + swamp SW, glacier center — `bash tools/rebuild_island_biomes.sh` (organic borders via domain warp). ✅ **Baseline shipped** (desert % below art target; see [island_map.md](island_map.md) §4)
3. Paint **four river systems** from glacier; **wetland bank strip** along rivers (not in desert). ✅ Rivers painted (`water_layer_guides.png`); copied to `water_layer.png` at rebuild; wetland overlay ⬜
4. Paint **glacier hazard** + optional pass corridors (passable, slow, cold — no collision geometry). ⬜
5. **Ground procedural** — shader handles biome colors, edge blending, per-biome noise. Trees, grass tufts, bushes, rocks, gatherables placed later as **sprites** in-engine. ✅ Shader-driven
6. Mark **desert oases** (`SPRING`) — no glacial drainage into desert. ⬜
7. Export **chunk tiles** (§12); validate passability, biome queries, desert-no-rivers rule. ⬜

**Data layer model:** Biome IDs, water, wetlands, passes, and springs are **separate authored layers** (PNG or chunk fields). Gameplay reads discrete grids; visuals may blend softly on top. See [island_map.md](island_map.md) §1b.

**Climate Change (long-term):** Shipping v1 uses **base layers only** — no runtime climate overlays. See [§19 Climate Change mechanic](#climate-change-mechanic-long-term-design-lock).

---

## 3. Island layout & biomes

**Geographic concept:** One **hand-authored island** with **wedge / regional biomes** — not concentric rings. Most land is **savanna/plains**; special regions (desert, jungle, swamp, glacier) create travel, trade, and survival pressure.

### 3.1 Map scale & delivery

| Property | Spec |
|----------|------|
| **Target size** | **32 × 32 chunks** = **65,536 × 65,536 px** (2048 px per chunk) — **locked** |
| **Scale-up path** | Art at power-of-two sizes; can grow to 48×48 later |
| **Browser / MP** | Never load one giant PNG — slice into **2,048×2,048 tile images** per chunk |
| **Walk time** | ~**10 min** coast-to-coast at NPC speed (~110 px/s) — large enough for clans to spread, small enough to contest |
| **View** | **Top-down orthographic only** — flat 2D; **no perspective or isometric** on ground art |
| **Collision** | **None** for terrain — water, cold, heat = movement rules + debuffs, not physics walls |

**Artist deliverable:** **None for ground** — `biome_ground.gdshader` procedurally renders biomes, edges, and noise patterns. Trees, bushes, rocks, and props are placed as **sprites** in-engine.

### 3.2 Land-use (map2 / approved layout)

Percentages = **land area only** (excluding ocean).

| Biome ID | ~% land | Region | Ground look (shader-generated) |
|----------|---------|--------|--------------------------------|
| `SAVANNA` / `PLAINS` | **~55%** | Central + most of island | Light green/yellow grass, tan dirt patches |
| `DESERT` | **~20%** | **Northeast** + east cape | Tan sand, cracked dry earth |
| `JUNGLE` | **~15%** | **Southwest** finger | Deep emerald green, damp dark earth |
| `SWAMP` | **~10%** | **Mid-west coast**, north of jungle | Dark muddy brown, murky pools |
| `GLACIER` / `ALPINE` | **~3–5%** | **Absolute center** | White snow, ice blue, grey rock |
| `FOREST_PATCH` | **~10% overlay** | Scattered on savanna (esp. north of glacier) | Dark green grass, leaf litter — **overlay**, not a full region |

**Generated baseline (Sep 2026, `world_seed=882001`):** savanna 66 %, desert 9 % (**below target**), jungle 15 %, swamp 10 %, glacier 3 %, beach 1 %. Rebuild: `bash tools/rebuild_island_biomes.sh`. Details: [island_map.md](island_map.md) §1c + §4.

**Coast:** Narrow **beach sand** almost everywhere; **swamp coast = mud** (no beach). **Ocean** = solid blue, impassible.

```text
                    NORTH (short NE river + lake)
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

### 3.3 Biome rules (gameplay)

| Zone | Travel | Hazard / note |
|------|--------|----------------|
| **Ocean** | Blocked | World edge |
| **Coast** | Normal | Fishing, salt, nomad starts |
| **Savanna** | Normal | Default herding & early game |
| **Desert** | Normal; **heat debuff** | **No rivers** — water = oases only |
| **Jungle** | Normal | **Dense tree sprites** create slow paths — **no terrain move debuff** (locked) |
| **Swamp** | **Slow** | Mud, disease/croc hazard |
| **Glacier / alpine** | **Slow; cold debuff** | Most hominids need **cold genetics** to live here long-term |
| **Forest patch** | Normal | Uses temperate forest kit (overlay on savanna) |
| **River / wetland bank** | **Shallow penalty** | Crossable water; crocs, reeds, drink |

**Biome query priority (per cell):** `RIVER`/`WETLAND` overlay **>** `SPRING` point **>** regional biome **>** `FOREST_PATCH` overlay **>** base `SAVANNA`.

```gdscript
TerrainQuery.get_biome(world_pos) -> BiomeId
TerrainQuery.get_quadrant(world_pos) -> N | S | E | W
TerrainQuery.get_move_cost(world_pos) -> float
TerrainQuery.get_temperature_stress(world_pos) -> float  # cold / heat
```

### 3.4 Hydrography (hard constraints)

**Origin:** Central **glacier only** — watershed divide for the whole island.

**Four primary river systems** (map2):

| System | Flow | Mouth |
|--------|------|-------|
| **Northwest** | Center → NW | **Two main mouths**; large NW bay |
| **West** | Center → W | Western bay; **delta** |
| **Southeast** | Center → SE | **Delta** before coast |
| **Northeast** | Center → N/NE | Short steep run; **inland lake** chain → northern coast |

**Critical rule — desert is arid:**

> **No rivers flow into, through, or across the desert region.** Rivers may approach the boundary but must not enter cracked desert terrain. Desert water = **authored oasis / `SPRING` points only**.

**Wetland banks:** 1–3 tile cells wide along rivers (not a full-map biome). Regional **SWAMP** in the west is separate — persistently wet ground, not only river-adjacent.

**Separate headwaters:** The four systems may **not** form one connected paint blob at the glacier. Gaps between branches = separate **ice-melt / spring** sources. Validation checks **four systems each reach the coast**, not 8-connected single component.

**Dynamic water (runtime — Phase 6):** Base rivers = static `water_layer.png`. Flood/drought modify **overlays** only — see [Climate Change mechanic](#climate-change-mechanic-long-term-design-lock).

### 3.5 Ground vs foliage (implementation split)

| Layer | Who authors | Examples |
|-------|-------------|----------|
| **Ground rendering** | **Procedural shader** (`biome_ground.gdshader`) | Biome colors, edge blending, FBM noise per biome |
| **Props & foliage** | Game engine / level pass | Trees, bushes, grass tufts, gatherable nodes, rocks |

The island art map is the **tabletop** — all interactive objects are **sprites placed on top** with biome-aware spawn tables (§5–6, §13).

### 3.6 Gameplay flow

New clans start **coast / savanna** → forage and herd locally → travel to **desert** (salt, flint, heat) or **jungle/swamp** (exotic goods) → **glacier foothills** for stone/obsidian → **river valleys** for water, grain, and trade. **Cross-island trips** should require planning (water, cold/heat gear, genetics over generations — §9).

---

## 4. Quadrants — N / S / E / W

The island is divided into **four compass quadrants** by lines through the **glacier center** (NE/NW/SE/SW are implicit).

```text
              NORTH quadrant
                  |
    WEST -------- + -------- EAST
                  |
              SOUTH quadrant
```

| Rule | Detail |
|------|--------|
| **Border** | Vertical + horizontal through glacier center (may rotate slightly to match art passes). |
| **Query** | `TerrainQuery.get_quadrant(world_pos) -> N \| S \| E \| W` |
| **Quadrant rare** | **One exclusive rare gatherable per quadrant** — layered on regional biome kits. |
| **Purpose** | Forces **cross-quadrant travel/trade** — e.g. desert in NE vs jungle in SW. |
| **Placement** | Rares in **mid-island** slices (savanna/desert/jungle), not on glacier peak. |

### Quadrant rare resources

| Quadrant | Dominant biomes | Rare |
|----------|-----------------|------|
| **NORTH** | Savanna + forest patches + NE river lake | **Glacier blue lichen** (dye + cold cream) |
| **EAST** | Desert cape + savanna edge | **Tide pearl** (jewelry + dye booster) |
| **SOUTH** | Savanna + SE river delta | **Sun resin tears** (heat varnish) |
| **WEST** | Bays, swamp, jungle edge | **Sacred red ochre vein** (best red paint) |

---

## 5. Biome gatherable kit (10 per biome)

**Standard kit — every gameplay biome gets ~10 gatherable types:**

| Slot | Count | Role |
|------|-------|------|
| **Eatables** | **4** | Food, hunger, some basic nutrition |
| **Craftables** | **5** | Inputs to tools, buildings, cordage, leather, etc. |
| **Special** | **1** | **Either** a buff food **or** a craft ingredient that buffs an **end product** (spear, bread, cloak, etc.) |

**Not counted in the 10:** **Wood** and **stone** — universal, see §6 (variants + ratios).

**Special slot design:**

| Special kind | Example | Effect |
|--------------|---------|--------|
| **Buff eatable** | Alpine berry, cactus fruit, sacred mushroom | Temporary stat: cold resist, stamina, hunt focus |
| **Buff craftable** | Pine resin, salt crystal, iron ochre | Added to recipe → stronger/faster/longer-lasting product |

### Balance rules (no biome wins everything)

Every biome must provide **enough to survive**; none should supply **every optimal buff + every dye + best gear**.

| Every biome gets | Never exclusive to one biome |
|------------------|------------------------------|
| Food (eatables), wood + stone (variants), fiber/hide path, salt or ash preservative *or* access via trade one jump away | Women, sheep, goats (herdables) |
| **3 native dye/paint colors** (some dual-use on food plants) | Basic cordage, bone, charcoal black (common) |
| 1–2 **fabric sources** (plant fiber, hide, wool, reed…) | Meat from hunt |
| 1 **medicine tier** (salve, tea, paste — weaker locally, stronger imports) | Flint-quality tools (mountain/desert trade up) |

**Trade pull:** each biome exports **2–3 things others want** and imports **2–3 gaps**. Quadrant rares (§4) sit **above** this — island-level luxury.

**Dual-use items:** mark with **F+D** (food + dye), **C+J** (craft + jewelry), **C+M** (craft + medicine). Same node or same item type in two recipes.

**Body / clothing paints:** rare **hunt drops** (blood, fat + pigment) → temporary buff when applied to skin or cloak — short duration, costly, not stackable with same type.

---

### Craft systems (paleolithic — recommendations)

| System | Examples | Notes |
|--------|----------|-------|
| **Dyes / paints** | Ochre, charcoal, kaolin white, berry juice, lichen vat, copper-green mineral | 3 **signature colors** per biome; fix with urine/alum analogues or oil |
| **Fabrics** | Woven grass, nettle linen, flax, wool, hide, fur, reed mat | Clothing recipes need **fabric tag** — any biome can make *something*, best cloaks need imports |
| **Jewelry** | Shell beads, bone tubes, predator fangs, antler tips, stone disc, amber analogue | Prestige + small passive (morale, trade value) — not raw combat power |
| **Medicine** | Salve (resin+fat), tea (herb), paste (root), venom dose (weapon coat) | Heal over time, antidote, stamina — weaker than special eatables |
| **Body paint buffs** | Bear blood, croc bile + ochre, mammoth fat scarlet | **Temporary** combat / resist / fear — consumed on apply |

---

### Full biome kits (recommended fill)

Each block: **gatherables** · **3 dye colors** · **trade exports** · **wildlife + hunt drops**

---

#### DESERT

| E1 | E2 | E3 | E4 | C1 | C2 | C3 | C4 | C5 | S1 special |
|----|----|----|----|----|----|----|----|----|------------|
| **Prickly pear** (food) | **Mesquite pod** | **Agave heart** (roast) | **Locust cluster** | **Rock salt** | **Chert/flint** | **Agave fiber** | **Gourd shell** (container) | **Desert resin** (glue) | **Sunfruit** — eatable: **heat resist** 1 sim-day |

| Dye colors (native) | Source | Dual-use |
|---------------------|--------|----------|
| **Ochre yellow** | Yellow clay slip | C1 craft + paint |
| **Iron red** | Red desert stone dust | Jewelry stain |
| **Bone white** | Burned gypsum | C5 + hide prep |

| Fabrics / clothing | **Agave fiber** sash; **hide** (hare/fox hunt); no heavy fur |
| Trade exports | Salt, flint, heat-resist sunfruit, yellow ochre |
| Survival gap | Weak wood; imports pine pitch, fur, cold dyes |

| Wood | Stone | Ratio |
|------|-------|-------|
| Mesquite deadwood | Sandstone / chert | 1 : 4 |

**Wildlife**

| P1 | P2 | P3 | D1 | D2 | D3 | S1 |
|----|----|----|----|----|----|-----|
| Desert hare | Sand grouse | **Dung beetle** (forage protein) | **Scorpion** | Sand fox | **Vulture** | **Desert aurochs** — melee; **pack** |

| Hunt / predator drops | Use |
|-----------------------|-----|
| Hare hide, fox tail | Fabric, ornament |
| Scorpion **venom sac** | C+M: weapon poison (weak DoT) |
| Vulture **feather** | Fletching, bone-white dye mordant |
| Aurochs **horn** | C+J: trade trophy, tool handle |

---

#### SAVANNA

| E1 | E2 | E3 | E4 | C1 | C2 | C3 | C4 | C5 | S1 special |
|----|----|----|----|----|----|----|----|----|------------|
| **Marula fruit** **F+D** | **Wild sorghum** | **Baobab leaf** (tea) | **Termite mound** (protein) | **Tall grass fiber** | **Termite clay** | **Ostrich egg shell** C+J | **Horn core** (generic) | **Ash salt** | **Baobab pulp** — eatable: **long satiety** |

| Dye colors | Source | Dual-use |
|------------|--------|----------|
| **Marula gold** | Marula fruit **F+D** | Food + yellow dye |
| **Earth brown** | Termite clay | Pottery + paint |
| **Soot black** | Grass fire ash | Universal dark |

| Fabrics | **Grass weave** (C1); **hide** antelope; ostrich feather trim |
| Trade exports | Grain, marula dye, ostrich shell beads, satiety food |
| Survival gap | No obsidian; stone average |

| Wood | Stone | Ratio |
|------|-------|-------|
| Acacia | Surface quartz | 2 : 3 |

**Wildlife**

| P1 | P2 | P3 | D1 | D2 | D3 | S1 |
|----|----|----|----|----|----|-----|
| **Gazelle** | **Zebra** analogue | **Warthog** | **Hyena** | **Lion** analogue | **Jackal** | **White rhino** analogue — melee; **ride?** |

| Drops | Use |
|-------|-----|
| Antelope **hide** | Standard leather |
| Warthog **tusk** | C+J: jewelry, small knife |
| Hyena **jawbone** | Morale ornament, crush tool |
| Lion **fang** | C+J: prestige necklace; poison slot |
| Rhino **horn plate** | C+J: heavy ornament (trade, not magic sword) |

---

#### FOREST (patch overlay + north-of-glacier)

Used for **`FOREST_PATCH`** overlay on savanna and cold-adjacent strips. Default **temperate** kit below. Optional **`FOREST_COLD`** sub-strip where forest touches glacier — use cold block instead.

| E1 | E2 | E3 | E4 | C1 | C2 | C3 | C4 | C5 | S1 special |
|----|----|----|----|----|----|----|----|----|----|------------|
| **Brambleberry** **F+D** | **Hen-of-woods** mushroom | **Acorn** (leach) | **Wild pear** | **Inner bark fiber** | **Pine resin** | **Sphagnum moss** C+M | **Feather bundle** | **Antler shed** C+J | **Truffle** — craftable: **morale feast** (+ clan buff 1 meal) |

| Dye colors | Source | Dual-use |
|------------|--------|----------|
| **Bramble purple** | Berry **F+D** | Food + purple dye |
| **Walnut brown** | Hull husk (C2 process) | Leather tan + brown paint |
| **Mushroom tan** | Cap wash | Fabric stain |

| Fabrics | **Bark linen**; **wool** (herdable); **deer hide** |
| Trade exports | Resin, purple dye, truffle morale, balanced wood/stone |
| Survival gap | No salt mine — trade desert/salt coast |

**Wildlife**

| P1 | P2 | P3 | D1 | D2 | D3 | S1 |
|----|----|----|----|----|----|-----|
| **Red deer** | **Rabbit** | **Wild boar** | **Grey wolf** | **Lynx** | **Yearling bear** | **Aurochs bull** — melee; **tame + pack** |

| Drops | Use |
|-------|-----|
| Deer **hide**, antler | Leather, C+J |
| Boar **bristle** | Brush, binding |
| Wolf **fang** | C+J + poison slot |
| **Bear cub → yearling bear blood** | **Body paint buff**: +melee courage, 10 min — **temperate exclusive drop** |
| Lynx **claw** | Jewelry, small cutting tool |
| Aurochs **horn** | Pack harness, trade |

---

#### FOREST_COLD (sub-region — north or mountain-adjacent forest only)

| E1 | E2 | E3 | E4 | C1 | C2 | C3 | C4 | C5 | S1 special |
|----|----|----|----|----|----|----|----|----|----|------------|
| **Cloudberry** **F+D** | **Frozen tuber** | **Pine nut** | **Reindeer lichen** (tea) | **Fur scrap** (ground) | **Pine pitch** | **Birch bark** (container) | **Antler shard** C+J | **Render fat** | **Coldcap** mushroom — eatable: **cold resist** |

| Dye colors | Source | Dual-use |
|------------|--------|----------|
| **Cloudberry red** | Berry **F+D** | Food + lip paint |
| **Birch blue-grey** | Birch bark ash | Fabric + ritual paint |
| **Charcoal black** | Pine soot | Common |

| Fabrics | **Fur** (hunt + C1); **wool**; **birch-bark** mat |
| Trade exports | Fur, cold resist food, pitch, reindeer antler |
| Survival gap | Low berries in deep winter (seasonal later); grain trade |

| Wood | Stone | Ratio |
|------|-------|-------|
| Pine / spruce | Granite | 5 : 2 |

**Wildlife**

| P1 | P2 | P3 | D1 | D2 | D3 | S1 |
|----|----|----|----|----|----|-----|
| **Elk** | **Snowshoe hare** | **Caribou** | **Wolf pack** | **Wolverine** | **Great owl** ( dive hazard ) | **Mammoth** — melee; **pack labor** |

| Drops | Use |
|-------|-----|
| Elk/caribou **antler**, hide | C+J, fur cloak |
| Wolverine **gland** | C+M: musk paste (**fear** body paint ingredient) |
| Mammoth **ivory chip**, fat | Jewelry, **cold-resist grease** cream |
| Wolf **pelt** | Best cold cloak lining (with fur scrap) |

---

#### GLACIER / ALPINE (center — `GLACIER`)

Former **MOUNTAIN** kit. Small **~3–5%** center watershed. **Ground art = snow/ice/rock only** — passable, cold hazard, no collision cliffs.

| E1 | E2 | E3 | E4 | C1 | C2 | C3 | C4 | C5 | S1 special |
|----|----|----|----|----|----|----|----|----|----|------------|
| **Alpine sorrel** | **Mountain bilberry** **F+D** | **Edible lichen** | **Cave cricket** | **Obsidian flake** | **Copper-green mineral** (malachite analogue) | **Talc/stone soap** | **Eagle down** | **Iron ochre lump** | **Peak moss** — craftable: **stamina paste** (C+M) |

| Dye colors | Source | Dual-use |
|------------|--------|----------|
| **Copper green** | Malachite C2 | Jewelry + face paint |
| **Iron ochre red** | C5 | Paint + trade (overlap west quadrant — mountain veins weaker saturation) |
| **Snow white** | Talc | Body chalk, cloth bleach |

| Fabrics | **Goat hide** (mountain goat hunt); **yak hair** (special); minimal plant fiber |
| Trade exports | Obsidian, green dye, stamina paste, best flint-knapping stone |
| Survival gap | Food sparse — hunt-dependent; import bulk grain/fiber |

| Wood | Stone | Ratio |
|------|-------|-------|
| Sparse larch | Granite / obsidian | 1 : 5 |

**Wildlife**

| P1 | P2 | P3 | D1 | D2 | D3 | S1 |
|----|----|----|----|----|----|-----|
| **Mountain goat** | **Marmot** | **Rock dove** | **Golden eagle** | **Snow leopard** analogue | **Cave bear** | **Yak** analogue — melee; **ride + pack** |

| Drops | Use |
|-------|-----|
| Goat **horn** | C+J, climbing tool |
| Eagle **talon** | C+J: necklace, spear barb |
| Cave bear **blood + fat** | **Body paint**: **damage resist** (short) — mountain/cave exclusive |
| Snow leopard **fang** | Poison coat, prestige |
| Obsidian from butchering? | No — **gather only** (balance) |

---

#### JUNGLE (regional — southwest ~15%)

Dense tropical region; **ground art = deep green + damp earth** — trees/props placed in-engine.

| E1 | E2 | E3 | E4 | C1 | C2 | C3 | C4 | C5 | S1 special |
|----|----|----|----|----|----|----|----|----|----|------------|
| **Wild fig** **F+D** | **Palm heart** | **Giant taro** | **Grub cluster** (protein) | **Bamboo fiber** | **Liana rope** | **Palm resin** | **Hardwood shard** | **Spice bark** | **Vision root** — eatable: **hunt focus** (short) |

| Dye colors | Source | Dual-use |
|------------|--------|----------|
| **Fig purple** | Fig **F+D** | Food + purple dye |
| **Charcoal black** | Burned palm | Common dark |
| **Clay red-brown** | Laterite wash | Body paint + pottery |

| Fabrics | **Liana weave**; **palm mat**; **tapir hide** |
| Trade exports | Liana rope, purple dye, spice bark, exotic fiber |
| Survival gap | Low salt; import desert salt or coastal trade |

| Wood | Stone | Ratio |
|------|-------|-------|
| Bamboo / palm | Laterite / river stone | 4 : 2 |

**Wildlife**

| P1 | P2 | P3 | D1 | D2 | D3 | S1 |
|----|----|----|----|----|----|-----|
| **Tapir** analogue | **Peccary** | **Monkey** (forage) | **Jaguar** analogue | **Boa** | **Giant bat** swarm | **Forest rhino** analogue — melee; **pack?** |

| Drops | Use |
|-------|-----|
| Tapir **hide** | Tough leather, trade |
| Jaguar **fang** | C+J, poison slot |
| Boa **venom** | C+M: strong poison coat |
| Monkey **bone** | Small tools, ornaments |

---

#### SWAMP (regional — mid-west ~10%)

Persistent wetland **region** (not only river banks). **Muddy coast** — no sandy beach. Overlaps **WETLAND** kit where rivers also cross.

| E1 | E2 | E3 | E4 | C1 | C2 | C3 | C4 | C5 | S1 special |
|----|----|----|----|----|----|----|----|----|----|------------|
| **Cattail root** | **Frog leg** | **Water chestnut** | **Snail** (food) | **Clay** | **Reed fiber** | **Freshwater mussel shell** C+J | **Leech oil** C+M | **Bog iron** | **Lotus bulb** — eatable: **hydration + stamina** |

| Dye colors | Source | Dual-use |
|------------|--------|----------|
| **Reed green** | Reed chlorophyll wash | Fabric + camouflage paint |
| **Mussel purple** | Shell gland extract | Rare dye — trade luxury |
| **Bog black** | Iron-rich mud | Paint + pottery |

| Fabrics | **Reed mat**; **woven sedge**; fish-leather (optional) |
| Trade exports | Purple dye, clay, hydration food, leech medicine |
| Survival gap | Wood often wet-rot — import dry timber |

| Wood | Stone | Ratio |
|------|-------|-------|
| Willow / driftwood | Soft river stone | 2 : 2 |

**Wildlife**

| P1 | P2 | P3 | D1 | D2 | D3 | S1 |
|----|----|----|----|----|----|-----|
| **Mallard** | **Beaver** (prey hunt) | **Carp** (shore) | **Crocodile** | **Python** analogue | **Swarm midges** (debuff) | **Hippo** analogue — melee; predator special |

| Drops | Use |
|-------|-----|
| Beaver **castor** | C+M: waterproofing cream (cloak buff) |
| Croc **tooth**, bile | C+J; bile + ochre = **fear body paint** |
| Python **venom** | C+M: strong poison coat |
| Duck **feather** | Fletching, dye brush |

---

#### WETLAND (stream overlay — paint along rivers)

Apply **wetland kit** on cells tagged `WETLAND` where streams cross savanna, jungle, forest patches, and swamp. **Never in desert.** Small coastal estuaries optional.

→ **Gatherables & wildlife:** use **SWAMP** tables above (§5).

---

#### COAST (beach band — all shores except muddy swamp coast)

| E1 | E2 | E3 | E4 | C1 | C2 | C3 | C4 | C5 | S1 special |
|----|----|----|----|----|----|----|----|----|----|------------|
| **Mussel** | **Kelp** (food) | **Coastal plum** **F+D** | **Crab** | **Sea salt** | **Kelp rope** | **Abalone shell** C+J | **Shark cartilage** | **Ambergris analogue** (rare wash) | **Coral lime** — craftable: **stronger oven/adobe** |

| Dye colors | Source | Dual-use |
|------------|--------|----------|
| **Coastal plum pink** | Plum **F+D** | Food + pink dye |
| **Shell white** | Abalone / lime | Jewelry, white paint |
| **Kelp olive** | Kelp boil | Fabric + net dye |

| Fabrics | **Kelp rope**; **shell** ornaments; **seal hide** (hunt) |
| Trade exports | Salt, shell jewelry, lime, pink dye |
| Survival gap | Fresh water — spring/oasis trade critical |

| Wood | Stone | Ratio |
|------|-------|-------|
| Driftwood | Coastal limestone | 2 : 3 |

**Wildlife**

| P1 | P2 | P3 | D1 | D2 | D3 | S1 |
|----|----|----|----|----|----|-----|
| **Seal** | **Sea turtle** | **Pelican** | **Shark** (offshore) | **Komodo** analogue (islet) | **Sea eagle** | **Dugong** analogue — prey special; **thick hide** craft |

| Drops | Use |
|-------|-----|
| Shell, **pearl** (east quadrant boost) | C+J |
| Shark **tooth** | C+J, knife |
| Seal **blubber** | C+M: cold cream (ironic import item) |
| Turtle **shell** | Shield, container |

---

#### SPRING / OASIS (micro-biome)

| E1–E4 | **Date palm fruit**, **wild mint**, **cattail**, **minnow** |
| C1–C5 | **Limestone**, **palm fiber**, **salt crust**, **mint oil** C+M, **silt clay** |
| S1 | **Spring water** — drink + short heal/stamina |

| Dye colors | **Mint green**, **limestone white**, **palm amber** (3 — oasis palette) |
| Role | **Neutral ground** — every quadrant wants access; fight magnet |

---

### Quadrant rares (updated recommendations)

| Quadrant | Rare | Type | Trade / buff |
|----------|------|------|--------------|
| **NORTH** | **Glacier blue lichen** | Craftable + dye | Cold resist **cream**; unique **blue** body paint |
| **SOUTH** | **Sun resin tears** | Craftable | Heat resist varnish; binds jewelry |
| **EAST** | **Tide pearl** | Craftable C+J | Prestige; **shell pink** saturation booster |
| **WEST** | **Sacred red ochre vein** | Craftable + dye | Best **red** paint; shrine morale buff |

---

### Body paint & medicine quick reference

| Item | Source biome | Apply to | Buff (short, ~1 sim-hour) |
|------|--------------|----------|---------------------------|
| **Bear blood mix** | Temperate forest | Skin / cloak | +courage / melee morale |
| **Cave bear fat scarlet** | Glacier / alpine | Skin | +damage resist |
| **Croc bile ochre** | Wetland | Skin | Enemy **fear** (NPC hesitate) |
| **Wolverine musk paste** | Cold forest | Skin | Stealth / reduce agro radius |
| **Mammoth grease white** | Cold forest | Cloak | Cold resist stack |
| **Leech oil salve** | Wetland | Skin | Heal over time |
| **Peak moss paste** | Glacier / alpine | Eat or skin | Stamina regen |
| **Scorpion venom** | Desert | Weapon | Poison DoT (not body paint) |

**Balance:** max **1 body paint buff** active; paints consume rare hunt drops; biomes with strong paint lack another axis (desert: heat food but weak wood).

---

### Template table (authoring checklist)

- Author **spawn zones** per gatherable type; chunk load spawns from zone + biome/quadrant filters.
- **Stable IDs** + `MutationStore` depletion unchanged.
- New items need `ResourceType` entries (or subtypes) in `scripts/resource_data.gd` + recipes in craft registry.
- **Ratio** = relative spawn weight in biome spawn tables (not “only 4 wood nodes exist”).

---

## 6. Biome wildlife kit (7 + universal herdables)

Mirrors the gatherable kit: each biome gets a **fixed wildlife roster** for hunt/threat fantasy. **Herdables are separate** — they are **essential** and **global**.

### Standard kit — 7 wild NPC types per biome

| Slot | Count | Role |
|------|-------|------|
| **Prey** | **3** | Hunt for meat/hide; flee behavior; AoH targets |
| **Predators** | **3** | Threaten player/clan NPCs; hostile AI |
| **Special** | **1** | Predator **or** prey that **fights back in melee** (e.g. mammoth, boar patriarch, hippo analogue) |

**Special slot — extra rules:**

| Property | Options (pick 1+ per species design) |
|----------|--------------------------------------|
| **Combat** | High HP, melee counter-attack — not a free kill |
| **Tameable** | Rare post-hunt or calm approach → join clan (long-term) |
| **Rideable** | Mount for faster travel (player or clansman) |
| **Pack / labor** | Carries items (travois-like); reduces caravan burden |

Not every special needs all four — e.g. **mammoth**: prey + melee defense + pack labor; **camel analogue**: tameable + pack, not rideable in v1.

**Existing code hooks:** `npc_type` (deer, sheep, goat, woman, mammoth…), `WildRole`, herd via `HerdInfluenceArea`, hunt via land claim AoH + `hunt_state` — see [wildlife_movement.md](wildlife_movement.md).

### Universal herdables (all biomes)

Like wood and stone — **always available**, different **variants/ratios** optional later.

| NPC | Role | Why global |
|-----|------|------------|
| **Woman** | Reproduction, production work, herdable | Core clan loop |
| **Sheep** | Wool, herd, farm slot | Economy + herding tutorial |
| **Goat** | Milk, herd, farm slot | Economy + herding |

| Dimension | Design |
|-----------|--------|
| **Spawn** | Every biome chunk roll includes herdable packs; authored **herdable zones** on map |
| **Ratio** | Tune density per biome (savanna high, desert low) — never zero |
| **Variant** | Optional cosmetic/stat variants (desert goat vs mountain goat) — same herd mechanics |
| **WildRole** | Migratory / ambient — not the same as biome “prey slot” deer |

**Wild women** vs clan women: wild women use same herd pipeline ([HERDING_SYSTEM_GUIDE.md](HERDING_SYSTEM_GUIDE.md)) — searcher quota, steal, deliver to claim.

### Template — wildlife by biome (aligned with §5 hunt drops)

Columns: `P1–P3` prey · `D1–D3` predators · `S1` special · Key **drops** in §5

#### DESERT

| P1 | P2 | P3 | D1 | D2 | D3 | S1 special |
|----|----|----|----|----|----|------------|
| Desert hare | Sand grouse | Dung beetle | Scorpion | Sand fox | Vulture | **Desert aurochs** — pack |

**Key drops:** venom sac, fox tail, aurochs horn.

#### SAVANNA

| P1 | P2 | P3 | D1 | D2 | D3 | S1 special |
|----|----|----|----|----|----|------------|
| Gazelle | Zebra analogue | Warthog | Hyena | Lion analogue | Jackal | **White rhino** analogue |

**Key drops:** warthog tusk, lion fang, rhino horn plate.

#### FOREST (patch overlay + north-of-glacier)

| P1 | P2 | P3 | D1 | D2 | D3 | S1 special |
|----|----|----|----|----|----|------------|
| Red deer | Rabbit | Wild boar | Grey wolf | Lynx | Yearling bear | **Aurochs bull** — tame + pack |

**Key drops:** **bear blood** (body paint buff), wolf fang, antler.

#### FOREST_COLD (sub-region)

| P1 | P2 | P3 | D1 | D2 | D3 | S1 special |
|----|----|----|----|----|----|------------|
| Elk | Snowshoe hare | Caribou | Wolf pack | Wolverine | Great owl | **Mammoth** — pack labor |

**Key drops:** antler/ivory, wolverine musk paste, mammoth fat cream.

#### GLACIER / ALPINE (center)

| P1 | P2 | P3 | D1 | D2 | D3 | S1 special |
|----|----|----|----|----|----|------------|
| Mountain goat | Marmot | Rock dove | Golden eagle | Snow leopard | Cave bear | **Yak** analogue — ride + pack |

**Key drops:** **cave bear blood** (damage resist paint), eagle talon, goat horn.

#### JUNGLE (regional SW)

| P1 | P2 | P3 | D1 | D2 | D3 | S1 special |
|----|----|----|----|----|----|------------|
| Tapir analogue | Peccary | Monkey | Jaguar analogue | Boa | Giant bat | **Forest rhino** analogue |

**Key drops:** tapir hide, jaguar fang, boa venom.

#### SWAMP + WETLAND (regional + river overlay)

| P1 | P2 | P3 | D1 | D2 | D3 | S1 special |
|----|----|----|----|----|----|------------|
| Mallard | Beaver | Carp | Crocodile | Python analogue | Midge swarm | **Hippo** analogue |

**Key drops:** beaver castor cream, croc bile paint, python venom.

#### COAST (beach band)

| P1 | P2 | P3 | D1 | D2 | D3 | S1 special |
|----|----|----|----|----|----|------------|
| Seal | Sea turtle | Pelican | Shark | Komodo analogue | Sea eagle | **Dugong** analogue |

**Key drops:** shark tooth, pearl, seal blubber, turtle shell.

### Quadrant + wildlife

Quadrant **gatherable** rares (§4) are separate. Optional: **one quadrant-exclusive special animal** (e.g. only EAST has a rideable ostrich analogue) — decide when painting map.

### Wildlife implementation note

- Author **wildlife spawn zones** per species; chunk load + `MutationStore` for killed-out pockets (respawn rules TBD).
- **Herdables** use separate zone layer or shared “migratory herd” pass with biome density only.
- **Special** flags stored on species resource: `WildSpeciesDef { tameable, rideable, pack_capacity, melee_threat_tier }`.
- **ClanBrain** AoH already lists huntables — extend filters by prey vs predator vs special.

---

## 7. Wood & stone — universal variants

**Wood** and **stone** appear in **every biome**, but they are **not identical**:

| Dimension | Design |
|-----------|--------|
| **Variant** | Biome-specific **visual + item ID** (e.g. `WOOD_PINE`, `WOOD_ACACIA`, `STONE_GRANITE`, `STONE_SANDSTONE`) — may map to base WOOD/STONE in recipes with tags, or separate types. |
| **Ratio** | Spawn table weight per biome (e.g. desert 1:4 wood:stone, cold forest 5:2). |
| **Tool** | Same tools (axe / pick / Oldowan) unless a variant needs tier-2 tool later. |
| **Craft** | Most recipes accept any wood/stone; **buff specials** may require a **specific variant** (pine pitch needs pine wood). |
| **Trade** | Quadrant rare + variant shortage drives caravans (e.g. west wants pine, south wants flint-heavy desert stone). |

**Implementation options (pick one when coding):**

1. **Subtype meta** on gather node — one `WOOD` enum, `variant_id: String` for art and special recipes.  
2. **Separate ResourceType** per variant — clearer inventory, more enum growth.

Prefer **(1)** for v1 unless inventory UI needs distinct icons for every variant.

---

## 8. Central glacier — passable corridor

**Design intent:** The **glacier / alpine center** is not a wall — it is **cold, rocky ground** (snow/ice texture on the art map). Dangerous **pass corridors** let clans cut through toward another coast without walking the long way around the island rim.

| Property | Value |
|----------|--------|
| Region | **~3–5%** of land at absolute center |
| Passability | **Yes** — no collision; movement rules only |
| Move cost | High — e.g. 0.5× speed vs 0.7× shallow water |
| Hazards | **Cold exposure** (vital drain); most clans need **generations in cold** or gear to settle here |
| Route shape | **Narrow authored paths** through snow/rock — you draw the fun route |
| Gameplay | Trade caravans and raids contest passes; ambush fantasy |

**TerrainQuery additions:**

```gdscript
TerrainQuery.get_biome(world_pos) -> BiomeId
TerrainQuery.get_move_cost(world_pos) -> float  # glacier > shallow water > land
TerrainQuery.get_temperature_stress(world_pos) -> float  # cold forest + glacier
```

---

## 9. Generational clan adaptation

**Design intent:** The longer a bloodline **lives and breeds in a biome**, the more NPCs **look and feel** suited to that environment — without instant transformation when someone walks into a desert.

### Is it realistic?

**Partly yes — if framed as generations, not weeks.**

| Trait | Real-world basis | Game framing |
|-------|------------------|--------------|
| **Stockier, shorter build in cold** | [Bergmann’s rule](https://en.wikipedia.org/wiki/Bergmann%27s_rule) — colder climates → larger/stockier bodies to conserve heat (population trend, not one person moving north) | **Bone scale** bias after N generations in `FOREST_COLD` / `GLACIER` |
| **Shorter limbs in cold** | [Allen’s rule](https://en.wikipedia.org/wiki/Allen%27s_rule) — reduced limb length in cold | Limb scale clamp toward shorter over generations |
| **Darker skin in high-UV desert** | Melanin protects against UV; **populations** adapt over **many thousands of years** in reality | **Skin tint** (shader on grayscale base — see [pawn_goal.md](../guides/pawn_goal.md)) drifts toward darker in `DESERT` / `SAVANNA` over generations |
| **Lighter skin in low-UV cold center** | Lower UV at high latitude / heavy clothing forest life | Lighter tint drift in `FOREST_COLD` over generations |

**Important design rules (avoid bad optics / bad sim):**

1. **Generational, not personal** — adaptation applies to **children born** in a biome (or with both parents adapted), not an adult who walked there for one season.
2. **Gradual** — blend toward biome target over 3–10 generations using existing **trait/reproduction** systems (`traits.md`, `reproductiontraits.md`).
3. **Never erase identity** — keep species/hominid baseline + parent mix; biome is a **bias**, not a hard overwrite.
4. **Migrants stay mixed** — raiding a desert clan and bringing women home produces **blended** offspring (already aligned with hybridization design).
5. **Gameplay stats optional** — cold-adapted: slower cold debuff; heat-adapted: slower heat debuff. Cosmetic-only v1 is fine.

**Suggested data:**

```text
npc.biome_exposure: Dictionary  # e.g. { "DESERT": 0.72, "FOREST_COLD": 0.1 }
# Increment for children based on claim biome at birth
# Morph targets: height, bulk, limb_length, skin_tint → lerp from genetics + exposure
```

---

## 10. Trade routes (vs raiding)

**Problem:** Biome-exclusive resources (salt, flint, fur, rare herbs) create demand. If the only tool is **raid**, the map becomes constant battle and trade fantasy dies.

**Goal:** **Caravan trade** as a viable path — risky but not identical to war.

### Design pillars

| Pillar | Idea |
|--------|------|
| **Scarcity map** | Each biome exports from its **10-kit**; each **quadrant** adds **1 rare**; wood/stone **variants** differ by biome. |
| **Neutral corridors** | Mountain pass, major river fords, coastal meeting beaches — authored **trade nodes** where truce rules apply. |
| **Trade state** | Party flagged `TRADING` / `CARAVAN` — attacking breaks **reputation**; defenders may get AI agro penalty vs traders. |
| **Gift / tribute UI** | Simple exchange at meeting point: offer wood for salt (no shop UI — physical crates or inventory RPC). |
| **Escort + risk** | Trade is slower and vulnerable to **bandit** players who break truce for profit. |
| **ClanBrain trade intent** | When local scarcity detected (no salt, buffer critical), brain sends **trade expedition** not only raid. |
| **Reputation** | Track per-clan: `trusted_trader` vs ` oathbreaker` — affects NPC willingness and player diplomacy later. |

### Flow (draft)

```text
ClanBrain detects need (e.g. salt) → trade_intent on claim
→ NPCs load caravan (goods + guards) → path to neutral trade node
→ Other clan meets → exchange → return home
Alternative: player-initiated trade at neutral zone
Failure mode: ambush = valid gameplay but costs reputation / triggers feud
```

### Relation to raiding

- **Raid** = fast, violent, burns relations, steals everything.  
- **Trade** = slower, needs safe-ish routes, builds recurring supply.  
- **Mountain pass** = both trade choke **and** raid ambush — same geography, different player/clan choices.

**Status:** Not implemented — note in `bible.md` §XXII / `future implementations/lategame.md` theme. Design before code.

---

## 11. What exists today

| Area | Status |
|------|--------|
| Chunk streaming | ✅ Implemented |
| Procedural chunk fill (`ChunkGenerator`) | ✅ Dev default — **to be replaced/suppressed for authored island** |
| Trees, grass, gatherables, ground piles | ✅ Procedural per chunk |
| MutationStore | ✅ Depletion, grass clear |
| ResourceIndex / DecorIndex | ✅ Spatial queries |
| **WorldMapEditor** — view, pan, zoom, water paint, save, **Validate / Fix** | ✅ Implemented |
| **`water_layer_guides.png`** — hand-painted rivers (source of truth) | ✅ Authored (Sep 2026) |
| **`water_layer.png`** — runtime copy of guides (never mutated by tools) | ✅ Synced by rebuild pipeline |
| **`TerrainQuery`** — `get_biome()`, `is_water()` | 🟡 Partial — loads masks; move cost / temperature ⬜ |
| **Biome ground shader** — solid water, grass bank softening | ✅ Dev preview in editor |
| **`biome_mask.png`** — regional biomes (generated) | ✅ **Generated** — `bash tools/rebuild_island_biomes.sh` |
| **`shape_biome_regions.py`** — organic borders (domain warp, not tile nibbling) | ✅ Shipped |
| **`mask_topology.gd`** — speck/topology fix; straight-border **detection only** | ✅ Shipped |
| Biome / wetland / pass / spring paint in editor | ⬜ Manual brush optional — proc baseline exists |
| Chunk export + authored chunk load in `ChunkManager` | ⬜ Not implemented |
| Main game wired to authored ground | ⬜ `_setup_biome_ground()` missing (parse error in `main.gd`) |
| Hand-authored island / biomes (full wedge layout) | 🟡 **Baseline generated** — desert % tuning, passes, overlays remain — [island_map.md](island_map.md) §1c |
| **Climate Change overlays** | ❌ Design lock only — §19 below; **disabled until static map ships** |
| Biome-specific spawns | ❌ Uniform rotation |
| Generational morph by biome | ❌ Not implemented |
| Trade system | ❌ Not implemented |
| ClanBrain resource snapshot | ❌ Not implemented |

---

## 12. Chunk streaming & authored data

**Chunks stay** — the island is huge; only load nearby **2048 px** squares.

**Change from today:** Instead of `ChunkGenerator` rolling random props, each chunk loads:

```text
res://world/island/chunks/chunk_<cx>_<cy>.tres   # or JSON
  - biome_grid (optional compressed)
  - water_mask
  - mountain_cost_mask
  - placed_props[] { stable_id, type, position, variant }
  - wildlife_zones[]
```

**Flow:**

1. Player moves → `ChunkManager` ensures chunk loaded.  
2. If **authored file exists** → spawn from file + apply `MutationStore`.  
3. Else if **dev mode** → fall back to procedural `ChunkGenerator` (sandbox only).  
4. Unload → free nodes; mutations already saved server-side.

**Multiplayer:** Authoring is client-agnostic content; server owns mutations. No `randf()` for layout on shipping map.

---

## 13. Foliage & lushness

**Goal:** Each biome feels **full** — you place density when authoring, not hope RNG fills the map.

| Biome | Lushness target (sprites placed in-engine) |
|-------|---------------------------------------------|
| **SAVANNA** | Moderate grass tufts; open — main herding band |
| **FOREST_PATCH** | High tree + understory on overlay cells |
| **JUNGLE** | Highest prop density — **no terrain slow debuff**; pathing feel from sprite placement |
| **SWAMP** | Reeds, mud plants, low visibility |
| **DESERT** | Sparse — not empty; cactus analogue, dry scrub |
| **GLACIER** | Almost none — rock, snow, sparse alpine scrub |
| **WETLAND (rivers)** | Reeds along banks only |

**Procedural lush pass (optional tool):** Biome brush fills a chunk with templates; you hand-edit hero areas.

---

## 14. Ground tiles

**Look lock (player-facing):** Ground must feel like **one continuous painted map**, not a colony-sim grid.

- **Organic edges** — biome borders curve and blend (messy, natural). **No** square cells or hard corners like RimWorld / Dwarf Fortress.
- **Chunks are invisible** — slicing into 2,048×2,048 is for loading/bandwidth only. Adjacent tiles must abut with **zero visible seam**.
- **Soft blends in the art** — artist paints transitions (e.g. savanna→desert fades over distance). Gameplay biome IDs may snap to nearest type under the hood; that snap must **not** redraw the ground into blocks.

**Artist map (cartographer):**

- **Top-down orthographic only** — flat ground texture; **no perspective**, no painted trees/bushes/rocks.
- **Organic island** inside a rectangular image file; ocean fills unused canvas.
- Deliver at **65,536 × 65,536 px** (or pre-sliced **2,048 × 2,048** chunk tiles).
- Biome ground sets: savanna grass, desert sand, jungle floor, swamp mud, glacier snow/rock, beach sand, river water, ocean — with **gradual painted transitions** between them (except sharp water/ocean edges where intended).

**In-game display (engine):**

- Prefer **continuous texture slices** (Sprite2D / equivalent) from the authored paint — **not** a visible TileMap of hard biome squares.
- Existing seamless tiles (`assets/tiles/dirtgrassbase1–4.png`) remain for **dev/procedural sandbox** or prop underlays until the authored island ships.
- Hidden **biome mask** feeds `TerrainQuery` (spawn, weather, hazards). Passability from **TerrainQuery**, not tile collision.

---

## 15. Gatherables & tools

Unchanged core — see [GatherGuide.md](GatherGuide.md). **Biome tables (§4)** define *what* appears *where*.

---

## 16. ClanBrain & local resources

**Goal unchanged:** `TerritoryResourceSnapshot` + wire `get_gathering_priorities()` → `TerritoryJobService`.

**Biome addition:** Brain knows **claim biome** and **nearby biome mix** — e.g. desert clan prioritizes water runs and salt trade over berry gather.

---

## 17. Water — design (no collision)

**Principle:** Water and coast use **terrain data + movement rules**, not physics collision (NPCs already use `collision_mask = 0`).

| Kind | Passable? | Move cost | Source |
|------|-----------|-----------|--------|
| **OCEAN** | No | ∞ | Authored coast |
| **SHALLOW** (river, lagoon) | Yes | 0.4–0.7 | Authored + penalty |
| **BANK / SPRING** | Yes | 1.0 | Authored drink points |
| **LAND** | Yes | 1.0 | — |

Rivers/lagoons are **painted on the map**, not seeded. Crocs and wetland resources live in shallow zones (§15).

---

## 18. Hazards — water, glacier, biome predators

| Hazard | Biome | Behavior |
|--------|-------|----------|
| **Crocodiles** | WETLAND / rivers | Aggro in shallow water |
| **Cold exposure** | `FOREST_COLD`, `GLACIER` | Vital drain over time |
| **Heat exposure** | `DESERT` | Hydration drain faster |
| **Alpine fatigue** | `GLACIER` | Stamina / speed debuff |
| **Desert scorpion** (etc.) | DESERT | Small hostile |

All hazards = **entities or debuff zones**, not blocking collision.

---

## 19. Weather, seasons & catastrophes

**One global clock** for the whole island (finite map advantage over infinite plane).

### Seasons (server sim-day driven)

| Season | Island-wide | Biome-specific effects |
|--------|-------------|------------------------|
| **Spring** | More forage regrowth | River high flow; swamp/jungle mud |
| **Summer** | Heat peak | **Desert** hydration drain ↑; savanna hunt peak |
| **Autumn** | Grain/forage harvest window | Forest patch nut drop; migration windows |
| **Winter** | Cold peak | **Glacier / cold forest** lethal without gear/genetics; desert milder at night |

**Systems touched:** gatherable regrowth, [wildlife_migration.md](wildlife_migration.md), herd routes, optional crop/Field rings on river valleys.

### Weather (local overlays — planned)

| Weather | Where | Gameplay |
|---------|-------|----------|
| **Rain** | All (less in desert) | Fills rain-catch pots; river swell; mood/debuff stubs |
| **Storm** | Coast, jungle, swamp | Visibility; raid risk; fishing penalty |
| **Heat shimmer** | Desert | Stacks with desert biome heat debuff |
| **Blizzard** | Glacier, cold forest | Cold exposure spike |
| **Dry spell** | Desert, late summer savanna | Oasis value ↑; herd movement |

Weather runs **server-side**, deterministic from **world_seed + day + region** — same for all MP clients.

### Catastrophes (long-term — after core island ships)

| Event | Effect |
|-------|--------|
| **Ice age pulse** | Glacier footprint grows slightly; cold forest expands |
| **Desertification** | Desert region expands into savanna edge |
| **Flood year** | River wetlands widen; grain bonus then rot risk |

Implemented as **runtime evaluation** on top of the static base map — **not** by editing authored PNGs at runtime. Full spec: [Climate Change mechanic](#climate-change-mechanic-long-term-design-lock). Plan file: `living_world_map_system_815d153a.plan.md`.

### Climate Change mechanic (long-term design lock)

**Plan (source of truth for code):** `living_world_map_system_815d153a.plan.md`

**Intent:** A **living, breathing island** — rivers swell and shrink, glaciers grow, desert creeps, clans abandon dying villages, and rituals may slow or redirect climate pressure. **Shipping v1 = knobs at 0** (effective biome == base). Turn on with `--climate` or headless tests.

**Locked model:** 9 regions each have temperature and rainfall. Shader and gameplay resolve the **same hard biome ID** (no cross-biome color blending). Patchiness is a shared 32-bit integer hash. Rivers use baked `river_distance.png`. Rituals only change daily nudge rate/target.

#### Base vs climate (never mix)

| Layer | Source | Runtime edits |
|-------|--------|---------------|
| **Layer 0 — Base** | Authored PNGs / chunk export (`biome_mask`, `water_layer`, passes, springs) | **Never** modified in play |
| **Layer 1 — Climate** | Server `ClimateState` + per-chunk overlay deltas | Added/removed by seasons, catastrophes, rituals |

All gameplay queries use **effective** values:

```text
effective_water   = base_water   + climate_water_delta
effective_biome   = base_biome     + climate_biome_delta   (priority rules apply)
effective_wetland = base_wetland   + climate_wetland_delta
```

**Solid water rule:** Base `water_layer.png` defines the **normal full river channel**. Drought **masks off** some base water tiles via overlay (river **shrinks** visually). Flood **adds** wetland/water tiles **outside** the base channel (river **grows** at banks). The base PNG files on disk are never rewritten.

#### River flow — grow and shrink

Painted rivers = **normal flow** (100%). Climate adjusts per **river system**:

| ID | System |
|----|--------|
| `RIVER_NW` | Northwest (twin mouths) |
| `RIVER_W` | West (delta) |
| `RIVER_SE` | Southeast (delta) |
| `RIVER_NE` | Northeast (lake chain) |

Each water cell in export metadata carries a **system id** (e.g. `rivers.json` or chunk field).

| Condition | Scope | Effect |
|-----------|-------|--------|
| **Spring / rain** | Global or regional | `flow_level` ↑; wetland banks widen |
| **Flood year** | Global or regional | Wetland overlay expands; grain bonus → rot risk |
| **Drought** | **Global** or **1–2 systems** | `flow_level` ↓; hide base water tiles; fords may dry; oases critical |
| **Dry spell** | Desert + late-summer savanna | Hydration pressure; oasis value ↑ (see Weather table) |

**Separate glacier headwaters** at the center stay valid — drought targets **downstream flow**, not the existence of separate melt sources.

#### Fluid biomes (slow map change)

| Event | Overlay behavior | Gameplay |
|-------|------------------|----------|
| **Ice age pulse** | Glacier / cold-forest footprint **expands** from center | Cold hazard spreads; passes harder |
| **Aridification** | Desert front **advances** into savanna edge | Farms fail; clans **migrate or abandon** |
| **Recovery** | Overlays **ease back** when climate improves | Map heals over sim-time |

**Temporary vs permanent:** Seasonal flood/drought overlays **revert**. Multi-year aridification / ice-age pulses may leave a **small permanent delta** in world save (`climate_epoch` state) — still not edited PNGs.

#### Rituals & player influence

Climate is **not** purely scripted. Clan actions feed **`ritual_pressure`** (sacrifices, feasts, shamans — social system TBD):

- ↑ short-term rain / slow aridification
- ↓ drought severity on one river system
- Never **instant** full reversal — momentum + decay

**Authority:** Server sim from `world_seed + sim_day + region + ClimateState + ritual_pressure`. Same for all MP clients.

#### Planned `ClimateState` (server-owned sketch)

```gdscript
# Design sketch — not implemented
var aridification_rate: float      # desert creep speed
var drought_severity: float        # 0..1 global
var per_river_flow: Dictionary     # RIVER_NW..NE → 0..1
var glacier_radius_bonus: int      # tiles expanded from center
var ritual_pressure: float         # clan rituals; decays over time
var active_overlays: Dictionary    # chunk_key → overlay blob
```

Store overlays in **`ClimateOverlayStore`** or an extended **`MutationStore`** chunk record. **`TerrainQuery.get_effective_water()`** / **`get_effective_biome()`** apply base + overlay; until Phase 6, these equal base queries only.

#### Hooks to add during static map work (cheap, future-proof)

While building the **static** map (Phase 1–2), reserve:

1. **River system ids** on every water cell at export time  
2. **`TerrainQuery.get_river_system(world_pos) -> String`** (stub OK)  
3. **`get_effective_*()`** API that **delegates to base** until climate ships  
4. Chunk export schema includes empty **`climate_overlay`** slot  

#### Phase gate

| Milestone | Climate |
|-----------|---------|
| **v1 static island** | Climate **disabled** — base layers only |
| **Phase 6** | Enable overlays, seasons, catastrophes, ritual pressure |
| **Playtests** | Scripted drought/flood scenarios before MP ship |

**Progress tracker (static map):** [island_map.md](island_map.md) §1c

---

## 20. Drinking & settlement value

Springs, river mouths, and oasis **`SPRING`** cells = high-value claim sites. Ties to hydration (`BalanceConfig.hydration_start_percent` placeholder) and trade demand for water skins/caravan supply.

---

## 21. Phased implementation roadmap

### Phase 0 — Design doc ✅

- This file.

### Phase 1 — Map authoring pipeline 🟡 In progress

- ✅ Water layer paint in `WorldMapEditor`; save to `water_layer_guides.png`; `TerrainQuery.is_water()`.  
- ✅ **Biome generation** — `bash tools/rebuild_island_biomes.sh` (paint → shape → speck/topology gate).  
- ✅ **Validation gate** — specks, land/ocean topology, desert-off-river, straight borders (≥ 28 tiles).  
- ⬜ Export chunk format; full `TerrainQuery` (move cost, temperature, overlays).  
- ⬜ Ocean coast impassible in gameplay; four-system river connectivity check.  
- ⬜ Reserve river system ids + `get_effective_*()` stubs for Phase 6.  
- **Track:** [island_map.md](island_map.md) §1c

### Phase 2 — Paint the island 🟡 Started

- ✅ **Four river systems** hand-painted from glacier (separate headwaters OK).  
- ✅ **Regional biomes generated** — wedge layout, organic borders, desert never touches rivers.  
- ⬜ Tune **desert %** toward map2 ~20 % (current generated ~9 %).  
- ⬜ **Pass corridors** through glacier center.  
- ⬜ **Quadrant** borders + **one quadrant rare** per slice.  
- ⬜ Fill **biome gatherable kits** (4+5+1 per biome) + wood/stone variant ratios.

### Phase 3 — Biome gameplay

- Biome-specific **gatherable** spawn tables.  
- Biome **wildlife kit** (3 prey + 3 predators + 1 special); universal herdables layer.  
- `WildSpeciesDef` flags: tameable / rideable / pack capacity.  
- Cold/heat debuffs; mountain pass costs.  
- Croc + other biome hazards.

### Phase 4 — ClanBrain + economy

- Resource snapshot; priorities by biome need.  
- Trade nodes + basic gift exchange + reputation stub.

### Phase 5 — Generational adaptation

- `biome_exposure` on birth; morph/skin drift over generations.  
- Optional cold/heat resistance stats.

### Phase 6 — Seasons, trade AI, climate change & catastrophes

- ClanBrain `trade_intent`; caravan FSM.  
- Seasonal regrowth; river swell / drought shrink ([Climate Change mechanic](#climate-change-mechanic-long-term-design-lock)).  
- **`ClimateState`** + per-chunk overlays; glacier grow / aridification / flood year.  
- **Ritual pressure** — sacrifices and ceremonies influence rain and drought (social system TBD).  
- Village abandon when biome under claim becomes uninhabitable.

---

## 22. Open design questions

1. **Map editor** — extend `WorldMapEditor.tscn` vs external Tiled/LDtk import?  
2. ~~**Island size**~~ — **locked: 32×32 chunks (65,536 px)**; scale to 48×48 later if needed.  
3. **Glacier pass count** — one main corridor vs multiple?  
4. **Quadrant rare names** — finalize N/S/E/W exclusives and buff types.  
5. **Wood/stone variants** — subtype meta vs separate `ResourceType` per variant?  
6. **Special slot** — always one per biome, or some biomes share a regional special?  
7. **Trade truce** — automatic neutral zone or player-negotiated ceasefire?  
8. **Adaptation speed** — how many generations to full biome look?  
9. ~~**Desert ring width**~~ — replaced by **regional desert ~20% NE** (map2).  
10. **Wetland width** — 1 tile vs 3 tiles along streams?  
11. **Procedural fallback** — keep for test arena forever or remove when island ships?  
12. **Special wildlife** — which biomes get tame vs ride vs pack on the same species?  
13. **Herdable density** — minimum women/sheep/goats per chunk so herding never feels dead.  
14. **Dye overlap** — charcoal black is everywhere; is that OK or do we gate quality tiers?  
15. ~~**Body paint stacking**~~ — TBD (cloak + skin slots?).  
16. ~~**Jungle slow movement**~~ — **locked: props only**, no terrain debuff.
17. **Drought river shrink** — mask base tiles vs narrow channel only? (see §19 Climate Change)
18. **Ritual balance** — how strong can player influence on climate be before it breaks MP fairness?

---

## 23. File index

### Design docs (this folder)

| File | Role |
|------|------|
| **[environment_goal.md](environment_goal.md)** | **This file** — canonical map, biomes, weather, resources, wildlife |
| [island_map.md](island_map.md) | Map2 art/layout checklist → points here |
| [game_map.md](game_map.md) | Chunk streaming, coordinates, **current code** |
| [wildlife_movement.md](wildlife_movement.md) | Wild NPC movement — **shipped behavior** |
| [wildlife_migration.md](wildlife_migration.md) | Seasonal cross-island migration (design + partial code) |
| [hunting.md](hunting.md) | Hunt systems hub |
| [GatherGuide.md](GatherGuide.md) | Gather jobs, deposit |
| [HERDING_SYSTEM_GUIDE.md](HERDING_SYSTEM_GUIDE.md) | Herd pipeline |
| [ai_clan_brain.md](ai_clan_brain.md) | Territory jobs, raid/hunt intent |
| [traits.md](traits.md) · [genetics.md](genetics.md) | Inheritance, adaptation |
| [settlement_sim.md](settlement_sim.md) | Off-screen village tick |
| [earlygame_vision.md](earlygame_vision.md) | Opening 10 min on the island |
| [roadmap_2026.md](roadmap_2026.md) | Phase 5 island implementation |
| [future implementations/island_mp.md](future%20implementations/island_mp.md) | MP spawns, claims on island |
| [future implementations/proto_farming.md](future%20implementations/proto_farming.md) | Grain / Field on river valleys |
| [future implementations/world_systems_implementation_plan.md](future%20implementations/world_systems_implementation_plan.md) | Legacy chunk-ecology plan — cross-check against §3 here |
| [future implementations/off_screen_clan_balance.md](future%20implementations/off_screen_clan_balance.md) | Pseudo-biomes in code today (not shipping biomes) |

### Code & assets

| File | Role |
|------|------|
| [`assets/island_map2.jpg`](assets/island_map2.jpg) | Approved layout art reference |
| `scenes/WorldMapEditor.tscn` | In-engine map authoring — water paint + Validate/Fix shipped; manual biome brush optional |
| `maps/island/water_layer_guides.png` | Hand-painted river layer (**source of truth**) |
| `maps/island/water_layer.png` | Runtime river copy — rebuilt from guides; **never mutated by cleanup tools** |
| `maps/island/biome_mask.png` | Regional biome ID mask — **`bash tools/rebuild_island_biomes.sh`** |
| `maps/island/preview_biomes.png` | Colour preview from `render_biome_preview.py` |
| `maps/island/island_meta.json` | World scale, stride, layer paths, `world_seed` |
| `tools/rebuild_island_biomes.sh` | One-command deterministic rebuild + validation gate |
| `tools/shape_biome_regions.py` | Organic biome borders (seeded domain warp) |
| `tools/clean_biome_mask_specks.py` | Speck + topology cleanup; `--check-only` gate |
| `scripts/world/mask_topology.gd` | Editor Validate/Fix mirror of Python cleanup |
| `scripts/world/terrain_query.gd` | Biome + water lookups (partial; `get_effective_*` planned Phase 6) |
| `scripts/world/mutation_store.gd` | World deltas today; climate overlays may extend or parallel in Phase 6 |
| `scripts/world/chunk_manager.gd` | Load/unload — will load authored chunks |
| `scripts/world/chunk_generator.gd` | **Legacy procedural** — dev/sandbox |
| `scripts/config/world_gen_config.gd` | Streaming tunables |
| `scripts/world/mutation_store.gd` | World mutations |
| `guides/pawn_goal.md` | Skin tint / layered appearance |

**Planned code:**

- `scripts/world/terrain_query.gd` — biome, passability, move cost, temperature  
- `scripts/world/wild_species_def.gd` — prey/predator/special; tame/ride/pack flags  
- `world/island/` — authored chunk data directory  
- `bible/trade.md` — when trade design matures (optional split)  

---

*When implementation starts, update [game_map.md](game_map.md) and [CHANGELOG.md](CHANGELOG.md).*
