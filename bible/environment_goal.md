# Environment — goals & design

**Purpose:** Single reference for **world environment vision**, **hand-authored island map**, biomes, water, foliage, generational clan adaptation, trade routes, and phased work. Consolidates planning from environment design sessions (2026).

**Status:** **Goals / not fully implemented** — cross-check shipped behavior in [game_map.md](game_map.md) and [main.md](main.md).

**See also:** [game_map.md](game_map.md) (chunks, streaming), [ai_clan_brain.md](ai_clan_brain.md), [GatherGuide.md](GatherGuide.md), [wildlife_movement.md](wildlife_movement.md), [traits.md](traits.md), [guides/pawn_goal.md](../guides/pawn_goal.md) (skin/clothing layers), [future implementations/world_systems_implementation_plan.md](future%20implementations/world_systems_implementation_plan.md).

---

## Table of contents

1. [Vision (player-facing)](#1-vision-player-facing)
2. [Hand-authored island map](#2-hand-authored-island-map)
3. [Island layout & biomes](#3-island-layout--biomes)
4. [Quadrants — N / S / E / W](#4-quadrants--n--s--e--w)
5. [Biome gatherable kit (10 per biome)](#5-biome-gatherable-kit-10-per-biome)
6. [Biome wildlife kit (7 + universal herdables)](#6-biome-wildlife-kit-7--universal-herdables)
7. [Wood & stone — universal variants](#7-wood--stone--universal-variants)
8. [Central mountains — passable corridor](#8-central-mountains--passable-corridor)
9. [Generational clan adaptation](#9-generational-clan-adaptation)
10. [Trade routes (vs raiding)](#10-trade-routes-vs-raiding)
11. [What exists today](#11-what-exists-today)
12. [Chunk streaming & authored data](#12-chunk-streaming--authored-data)
13. [Foliage & lushness](#13-foliage--lushness)
14. [Ground tiles](#14-ground-tiles)
15. [Gatherables & tools](#15-gatherables--tools)
16. [ClanBrain & local resources](#16-clanbrain--local-resources)
17. [Water — design (no collision)](#17-water--design-no-collision)
18. [Hazards — water, mountains, biome predators](#18-hazards--water-mountains-biome-predators)
19. [Seasons & catastrophes](#19-seasons--catastrophes)
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
- **Ground** from artist-made tiles: **seamless borders**, **interior variation**.
- **Biome rings** — hand-painted **concentric bands**: **coast → savanna → desert → forest → mountains** (center). **Wetland** only along **streams/rivers**, not a full ring.
- **Central mountains** — passable, hazardous; **shortcuts** through the center to the opposite coast (trade + ambush).
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
| **Authoring** | Paint biomes, water, mountains, props, spawn zones in a map editor (`scenes/WorldMapEditor.tscn` or external tool → import). |
| **Storage** | Per-chunk **authored layer files** (e.g. biome ID grid, water mask, placed props with stable IDs) keyed by `chunk_coords`. |
| **Runtime** | `ChunkManager` loads authored chunk data when player enters range; **MutationStore** tracks depletions/chops/builds on top. |
| **Legacy procedural** | Today’s `ChunkGenerator` (seeded random fill) remains for **dev sandbox / tests** until authored chunks replace it. |

**Why hand-authored fits the project:**

- You control **story geography** — mountain pass to opposite coast, desert coast vs cold interior, where crocs live, where flint spawns.
- **Biome borders** are clean and intentional, not noise artifacts.
- **Trade routes** follow **real paths** you draw (river fords, mountain gaps, coastal trails).
- Multiplayer stays deterministic: **same authored files + same mutation snapshot = same world** for all clients.

**Authoring workflow (planned):**

1. Design island silhouette — ocean coast = impassible boundary.
2. Paint **biome rings** (§3): coast → savanna → desert → forest → mountains.
3. Paint **streams/rivers**; stamp **wetland** strip along water (overrides ring below).
4. Paint **mountain hazard** layer on center ring (passable, slow).
5. Place **props**, gatherables, wildlife zones per biome (+ wetland kit on stream cells).
6. Mark **springs** on streams and desert oases.
7. Export per-chunk bundles; validate passability + biome queries.

---

## 3. Island layout & biomes

**Geographic concept** — one island as **concentric biome rings** from the **coast inward**. **Wetland** is not a ring — it is painted **along streams** only.

```text
                 ╭────── OCEAN (impassible) ──────╮
                 │  ┌──── COAST ring ────┐       │
                 │  │ ┌── SAVANNA ring ──┐ │       │
                 │  │ │ ┌ DESERT ring ┐ │ │       │
                 │  │ │ │ ┌ FOREST ─┐ │ │ │       │
                 │  │ │ │ │ MOUNTAIN│ │ │ │       │
                 │  │ │ │ │ (center)│ │ │ │       │
                 │  │ │ │ └─────────┘ │ │ │       │
                 │  │ │ └─────────────┘ │ │       │
                 │  │ └─────────────────┘ │       │
                 │  └─────────────────────┘       │
                 ╰───────────────────────────────╯

        ~~~ stream ~~~  →  WETLAND strip on both banks
                              (overrides local ring)
```

**Ring order (outside → in):**

| Ring # | Biome ID | Role |
|--------|----------|------|
| 0 | `OCEAN` | Impassible world edge |
| 1 | `COAST` | Beaches, cliffs, shellfish, salt spray, landing |
| 2 | `SAVANNA` | Open flat grassland — main early hunting & herding band |
| 3 | `DESERT` | Dry ring before deep forest — heat stress, salt, flint; **must cross** to reach inner forest from outer plains |
| 4 | `FOREST` | Wood, berries, mushrooms, hunt — main “rich” resource band |
| 5 | `MOUNTAIN` | **Center** — passable peaks; cold + stamina hazard; **pass to opposite coast** |

**Overlays (not rings):**

| Overlay | Where | Overrides |
|---------|--------|-----------|
| `WETLAND` | **Both banks of streams/rivers** (and small lagoons) | Local ring biome → wetland kit + shallow water penalty |
| `SPRING` | Headwaters, desert seeps, oasis points | Drink + high-value camp sites |

**Streams:** Authored rivers flow **outward** (mountain → forest → desert → savanna → coast) or cross rings; wherever water runs, paint **wetland** buffer (e.g. 1–3 tile cells wide). Crocs, reeds, purple dye, hydration — **live on the water**, not across whole map.

**Cold forest variant:** The **forest ring** uses the temperate kit by default. Optional **`FOREST_COLD`** sub-strip — e.g. **north quadrant** of forest ring or **forest touching mountains** — same ring, colder palette + fur game (see §5 kits). Not a separate concentric band unless you want a narrow cold collar in the map editor.

| Zone | Travel | Settlement notes |
|------|--------|-------------------|
| **Ocean** | Blocked | Edge of world |
| **Coast** | Normal | Fishing, salt, trade landings |
| **Savanna** | Normal | Best open herding; gateway to desert ring |
| **Desert** | Normal; heat debuff | Water scarce; cross to reach forest interior |
| **Forest** | Normal | Default clan heartland; rivers = wetland overlay |
| **Mountain** | Passable, slow, cold | Shortcuts, mining, ambush passes |
| **Wetland (stream)** | Shallow penalty | River crossings = fights + trade fords |

**Biome IDs (authoring):**

| ID | Ring / overlay | Summary |
|----|----------------|---------|
| `OCEAN` | Edge | Impassible |
| `COAST` | Ring 1 | Shore gatherables, seabirds, driftwood |
| `SAVANNA` | Ring 2 | Flat grass, gazelles, grain, marula dye |
| `DESERT` | Ring 3 | Salt, flint, heat, sparse wood |
| `FOREST` | Ring 4 | Wood-heavy, berries, bear blood paint |
| `FOREST_COLD` | Sub-region of ring 4 | Optional north/mountain-adjacent cold strip |
| `MOUNTAIN` | Ring 5 (center) | Obsidian, passes, cave bear paint |
| `WETLAND` | Stream overlay | Reeds, crocs, mussel purple — **not a full ring** |
| `SPRING` | Point feature | Drink, oasis |

Each cell: `TerrainQuery.get_biome(world_pos)` → ring biome **or** `WETLAND` if on stream overlay (stream wins).

**Gameplay flow:** New clans start **coast/savanna** → push through **desert ring** for salt/flint → **forest ring** for wood/food → **mountains** for obsidian and coast-to-coast shortcuts. **Rivers** cut through all rings — wetland resources and croc hazards **follow the water**.

---

## 4. Quadrants — N / S / E / W

The island is a **circle** divided into **four quadrants** by an **X** through the center (NE/NW/SE/SW are implicit; compass quadrants are the design unit).

```text
              NORTH quadrant
                  |
    WEST -------- + -------- EAST
                  |
              SOUTH quadrant
```

| Rule | Detail |
|------|--------|
| **Border** | Two lines through island center (vertical + horizontal in world space, or rotated to match mountain pass art). |
| **Query** | `TerrainQuery.get_quadrant(world_pos) -> N \| S \| E \| W` |
| **Quadrant rare** | **One exclusive rare gatherable per quadrant** — spawns only in that slice, layered on top of biome kits. |
| **Purpose** | Forces **cross-quadrant travel/trade** even if two clans share the same biome type on different sides of the island. |
| **Center overlap** | Mountain core + quadrant X meet at center — place quadrant rares **mid-ring** in each slice (savanna/desert/forest), not on the peak itself. |

### Quadrant rare resources

See **§5 full table** — island exclusives layered on biome kits:

| Quadrant | Rare |
|----------|------|
| **NORTH** | Glacier blue lichen (dye + cold cream) |
| **SOUTH** | Sun resin tears (heat varnish) |
| **EAST** | Tide pearl (jewelry + dye booster) |
| **WEST** | Sacred red ochre vein (best red paint) |

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

#### FOREST (ring 4)

Default **temperate** kit. Optional **`FOREST_COLD`** sub-strip on north quadrant or forest–mountain border — use cold block below instead of this table.

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

#### MOUNTAIN

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

#### WETLAND (stream overlay — paint along rivers)

Not a ring. Apply **wetland kit** on cells tagged `WETLAND` where streams cross savanna/desert/forest. Small coastal estuaries optional.

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
| Python **venom** | C+M: strong poison coat (short bottles) |
| Duck **feather** | Fletching, dye brush |

---

#### COAST (ring 1 — was COAST_WARM)

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
| **Cave bear fat scarlet** | Mountain | Skin | +damage resist |
| **Croc bile ochre** | Wetland | Skin | Enemy **fear** (NPC hesitate) |
| **Wolverine musk paste** | Cold forest | Skin | Stealth / reduce agro radius |
| **Mammoth grease white** | Cold forest | Cloak | Cold resist stack |
| **Leech oil salve** | Wetland | Skin | Heal over time |
| **Peak moss paste** | Mountain | Eat or skin | Stamina regen |
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

#### FOREST (ring 4)

| P1 | P2 | P3 | D1 | D2 | D3 | S1 special |
|----|----|----|----|----|----|------------|
| Red deer | Rabbit | Wild boar | Grey wolf | Lynx | Yearling bear | **Aurochs bull** — tame + pack |

**Key drops:** **bear blood** (body paint buff), wolf fang, antler.

#### FOREST_COLD (sub-region)

| P1 | P2 | P3 | D1 | D2 | D3 | S1 special |
|----|----|----|----|----|----|------------|
| Elk | Snowshoe hare | Caribou | Wolf pack | Wolverine | Great owl | **Mammoth** — pack labor |

**Key drops:** antler/ivory, wolverine musk paste, mammoth fat cream.

#### MOUNTAIN

| P1 | P2 | P3 | D1 | D2 | D3 | S1 special |
|----|----|----|----|----|----|------------|
| Mountain goat | Marmot | Rock dove | Golden eagle | Snow leopard | Cave bear | **Yak** analogue — ride + pack |

**Key drops:** **cave bear blood** (damage resist paint), eagle talon, goat horn.

#### WETLAND (stream overlay — paint along rivers)

Not a ring. Apply **wetland kit** on cells tagged `WETLAND` where streams cross savanna/desert/forest. Small coastal estuaries optional.

| P1 | P2 | P3 | D1 | D2 | D3 | S1 special |
|----|----|----|----|----|----|------------|
| Mallard | Beaver | Carp | Crocodile | Python analogue | Midge swarm | **Hippo** analogue |

**Key drops:** beaver castor cream, croc bile paint, python venom.

#### COAST (ring 1 — was COAST_WARM)

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

## 8. Central mountains — passable corridor

**Design intent:** Mountains sit at the **center ring** — not a wall. Dangerous **passes** let clans cut through to the **far coast** without walking the full outer circuit (coast → savanna → desert → forest → around).

| Property | Value |
|----------|--------|
| Ring position | **Innermost** (after forest ring) |
| Passability | **Yes** — no collision; movement rules only |
| Move cost | High — e.g. 0.5× speed vs 0.7× shallow water |
| Hazards | Cold exposure (vital drain), rockfall events (later), mountain predators |
| Route shape | **Narrow authored paths** — passes, ridges (you draw the fun route) |
| Gameplay | Trade caravans and raids both contest the pass; ambush fantasy |

**TerrainQuery additions:**

```gdscript
TerrainQuery.get_biome(world_pos) -> BiomeId
TerrainQuery.get_move_cost(world_pos) -> float  # mountain > shallow water > land
TerrainQuery.get_temperature_stress(world_pos) -> float  # cold forest + mountains
```

---

## 9. Generational clan adaptation

**Design intent:** The longer a bloodline **lives and breeds in a biome**, the more NPCs **look and feel** suited to that environment — without instant transformation when someone walks into a desert.

### Is it realistic?

**Partly yes — if framed as generations, not weeks.**

| Trait | Real-world basis | Game framing |
|-------|------------------|--------------|
| **Stockier, shorter build in cold** | [Bergmann’s rule](https://en.wikipedia.org/wiki/Bergmann%27s_rule) — colder climates → larger/stockier bodies to conserve heat (population trend, not one person moving north) | **Bone scale** bias after N generations in `FOREST_COLD` / `MOUNTAIN` |
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
| Ground (DirtBase shader) | ✅ Not biome-painted |
| Hand-authored island / biomes | ❌ Design only |
| TerrainQuery / passability | ❌ Not implemented |
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

| Biome | Lushness target |
|-------|-----------------|
| FOREST (ring 4) | High tree + understory; rivers cut through with wetland overlay |
| SAVANNA / DESERT | Open rings — sparse trees, not empty |
| WETLAND | **Stream banks only** — reeds, crocs |
| MOUNTAIN (center) | Sparse trees, boulders |

**Procedural lush pass (optional tool):** Biome brush fills a chunk with templates; you hand-edit hero areas.

---

## 14. Ground tiles

- Artist tiles: `assets/tiles/dirtgrassbase1–4.png` — seamless edges, interior variation.  
- **Biome tile sets** (planned): desert sand, cold dirt, forest grass, mountain rock, shore — painted on **TileMap_Ground** in map editor.  
- Passability from **TerrainQuery**, not tile collision.

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

## 18. Hazards — water, mountains, biome predators

| Hazard | Biome | Behavior |
|--------|-------|----------|
| **Crocodiles** | WETLAND / rivers | Aggro in shallow water |
| **Cold exposure** | FOREST_COLD, MOUNTAIN | Vital drain over time |
| **Heat exposure** | DESERT | Hydration drain faster |
| **Mountain fatigue** | MOUNTAIN | Stamina / speed debuff |
| **Desert scorpion** (etc.) | DESERT | Small hostile |

All hazards = **entities or debuff zones**, not blocking collision.

---

## 19. Seasons & catastrophes

**Seasons:** Affect regrowth and migration — server sim-day driven.

**Catastrophes (long-term):** Ice age / desertification shift biome boundaries on **authored map variants** or overlay mutations — heavy scope; after core island ships.

---

## 20. Drinking & settlement value

Springs, river mouths, and oasis **`SPRING`** cells = high-value claim sites. Ties to hydration (`BalanceConfig.hydration_start_percent` placeholder) and trade demand for water skins/caravan supply.

---

## 21. Phased implementation roadmap

### Phase 0 — Design doc ✅

- This file.

### Phase 1 — Map authoring pipeline

- Biome + water + ocean mask in `WorldMapEditor` (or Tiled → import).  
- Export chunk format; `TerrainQuery` reads authored cells.  
- Ocean coast impassible; debug overlay.

### Phase 2 — Paint the island

- **You** design full island: **biome rings** (coast → savanna → desert → forest → mountains), **streams with wetland banks**, mountain passes.  
- **Quadrant X** borders (N/S/E/W) + place **one quadrant rare** per slice.  
- Fill **biome gatherable kits** (4+5+1 per biome) + wood/stone variant ratios.

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

### Phase 6 — Seasons, trade AI, catastrophes

- ClanBrain `trade_intent`; caravan FSM.  
- Seasonal regrowth; late catastrophic events.

---

## 22. Open design questions

1. **Map editor** — extend `WorldMapEditor.tscn` vs external Tiled/LDtk import?  
2. **Island size** — how many chunks across? (Affects art scope.)  
3. **Mountain pass count** — one main corridor vs multiple?  
4. **Quadrant rare names** — finalize N/S/E/W exclusives and buff types.  
5. **Wood/stone variants** — subtype meta vs separate `ResourceType` per variant?  
6. **Special slot** — always one per biome, or some biomes share a regional special?  
7. **Trade truce** — automatic neutral zone or player-negotiated ceasefire?  
8. **Adaptation speed** — how many generations to full biome look?  
9. **Desert ring width** — how many chunks thick before forest? Sets cross-island difficulty.  
10. **Wetland width** — 1 tile vs 3 tiles along streams?  
11. **Procedural fallback** — keep for test arena forever or remove when island ships?  
12. **Special wildlife** — which biomes get tame vs ride vs pack on the same species?  
13. **Herdable density** — minimum women/sheep/goats per chunk so herding never feels dead.  
14. **Dye overlap** — charcoal black is everywhere; is that OK or do we gate quality tiers?  
15. **Body paint stacking** — one buff only, or cloak + skin different slots?

---

## 23. File index

| File | Role |
|------|------|
| `scenes/WorldMapEditor.tscn` | Starting point for hand-authored map |
| `scripts/world/chunk_manager.gd` | Load/unload — will load authored chunks |
| `scripts/world/chunk_generator.gd` | **Legacy procedural** — dev/sandbox |
| `scripts/config/world_gen_config.gd` | Streaming tunables |
| `scripts/world/mutation_store.gd` | World mutations |
| `guides/pawn_goal.md` | Skin tint / layered appearance |
| `bible/traits.md` | Trait inheritance |
| `bible/wildlife_movement.md` | Deer, mammoth, herdables, WildRole |
| `bible/HERDING_SYSTEM_GUIDE.md` | Women / sheep / goats herd pipeline |
| `bible/game_map.md` | Current chunk streaming reference |

**Planned:**

- `scripts/world/terrain_query.gd` — biome, passability, move cost, temperature  
- `scripts/world/wild_species_def.gd` — prey/predator/special; tame/ride/pack flags  
- `world/island/` — authored chunk data directory  
- `bible/trade.md` — when trade design matures (optional split)  

---

*When implementation starts, update [game_map.md](game_map.md) and [CHANGELOG.md](CHANGELOG.md).*
