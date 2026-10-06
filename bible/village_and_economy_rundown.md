# Village, buildings, gatherables & economy — rundown

**Status:** Living synthesis doc (conversation + existing canon).  
**Last updated:** October 2026  
**When this fights locked design:** [economy_catalog.md](economy_catalog.md) wins on classes, stations, and clothing pipeline; [environment_goal.md](environment_goal.md) wins on biome kits.

**Purpose:** One place to read what we have **talked about** for filling out the clan village, world resources, and a more **authentic Stone Age camp** feel — without opening ten other files.

---

## 1. Design tension we agreed on

| RPG-style (current drift) | Authentic camp (target feel) |
|---------------------------|------------------------------|
| One building per output (Oven, Dairy, Farm, Cheese hut…) | **One fire**, **few shelters**, **outdoor work**, **piles of stuff** |
| Walk to “the bread building” | Cook, knap, dry, sew **at the hearth or a small station** |
| Many `ResourceType` buildings | **ClanBrain need** → assign skilled worker → use **nearest station tag** |

See also: [future implementations/village.md](future%20implementations/village.md) (supply/demand, experience by task, homes for male+female pairs).

**Tier naming (locked):** Tier 1 = **Campfire** (nomad claim). Tier 2 = **Flag / land claim** (settled). [nomad.md](nomad.md), [earlygame_vision.md](earlygame_vision.md).

---

## 2. Gatherables & world resources

### 2.1 In the game today (chunk / gather nodes)

| Node / source | Yields | Tool notes |
|---------------|--------|------------|
| Trees | Wood (+ ~25% chance extra **nuts** on chop) | Axe / Oldowan |
| Boulders | Stone | Pick / Oldowan |
| Berry bushes | Berries | Hands |
| Wild wheat | **Grain** (processed name in inventory) | Hands |
| Fiber plants | Fiber | Hands |
| Tall grass | **Bugs** (`GrassBugPatch`) | Hands |
| Mushroom | Mushroom (in spawn rotation) | Hands |
| Corpses (butcher) | Meat, hide, bone | Blade / Oldowan |

**Universal (design):** wood + stone in **every biome** with variant ratios — [environment_goal.md](environment_goal.md) §6–7.

### 2.2 In `ResourceData` but mostly not world nodes

Crafted, butchered, or building outputs: grain, bread, wool, milk, leather, cordage, blade, cooked meat, etc. Full list: `scripts/resource_data.gd`, [items_guide.md](items_guide.md) (item properties; list partly stale).

### 2.3 Brainstorm — biome kits (~10 per biome)

**Rule:** 4 **eatables** + 5 **craftables** + 1 **special** per biome; wood/stone **not** counted in the 10.

**Quadrant rares (island exclusives):**

| Quadrant | Rare |
|----------|------|
| NORTH | Glacier blue lichen |
| SOUTH | Sun resin tears |
| EAST | Tide pearl |
| WEST | Sacred red ochre vein |

**Biome gatherable tables (full names):** [environment_goal.md](environment_goal.md) §5 — DESERT, SAVANNA, FOREST, FOREST_COLD, MOUNTAIN, WETLAND, COAST, SPRING/OASIS.

**Expanded archaeology-style list (grouped by use):** [future implementations/more_items.md](future%20implementations/more_items.md) — food, knapping stones, sinew/resin, furs, herbs, ochre, copper/salt/ivory late game.

**Dual-use tags (design):** F+D (food + dye), C+J (craft + jewelry), C+M (craft + medicine).

### 2.4 Suggested add order (when implementing gatherables)

1. Extend **mushroom, nuts, bugs** as proper nodes (not only side drops).  
2. Temperate forest kit first (acorn, pine resin, inner bark, brambleberry, hen-of-woods).  
3. Universal extras: **clay, salt, ochre**.  
4. Full biome tables when `TerrainQuery` / island painting ships.

Each new gatherable: `ResourceType` or subtype meta, chunk spawn table, sprite, `gatherable_resource.gd` rules, mutation/depletion on server.

---

## 3. Buildings & crafting locations

### 3.1 Legend

- **Build cost** — spent from **land claim inventory** in build menu (today often **test**: 1 wood + 1 stone).  
- **Production** — placed building or station converts inputs → outputs.  
- **Hands** — player craft via `CraftRegistry` (not a hut).

### 3.2 Shipped today (`BuildingRegistry` + code)

| Place / building | Build cost (code) | Effect / production |
|------------------|-------------------|---------------------|
| **Land claim** | Not from menu | Radius ~400px, stash, build menu (I). Craft bill for claim item not locked. |
| **Campfire** | Hands: 2 wood + 2 stone | Meat cook/smoke; nomad anchor; upgrade path to flag. |
| **Living hut** | 1 wood + 1 stone | +5 baby pool (**disabled** in code). |
| **Supply hut** | 1 wood + 1 stone | Extra storage (~6 slots). |
| **Shrine** | 1 wood + 1 stone | Placeholder; design = relic buffs, no craft. |
| **Oven** | 2 stone | **1 wood + 1 grain → 1 bread** (~15s); fire toggle; women loop mostly off. |
| **Farm** | 1 wood + 1 stone | **1 fiber → 1 wool** (~45s); 2 women + 3 sheep slots. **Not** crop farm. |
| **Dairy farm** | 1 wood + 1 stone | **1 fiber → 1 milk** (~45s); 2 women + 3 goats. |
| **Drying rack** | 1 wood + 1 stone | **1 hide → 1 leather** (~120s) passive. Catalog wants sheet + strips later. |

Sources: [Buildings.md](Buildings.md), `scripts/buildings/building_registry.gd`, `scripts/config/production_config.gd`.

### 3.3 Player hands crafts (`CraftRegistry`)

| Output | Cost (code today) | Design lock notes |
|--------|-------------------|-------------------|
| Oldowan | 2 stone | — |
| Cordage | 3 fiber | Weaver bulk later |
| Campfire | 2 wood + 2 stone | — |
| Travois | 2 wood + 2 cordage | Design: **leather + wood**; item hauler, no liquids |

Axe / pick / blade / spear: partial in code; full hands table in [economy_catalog.md](economy_catalog.md) §12.

### 3.4 Design-lock stations (`economy_catalog` §11)

**Not in build menu yet** (except overlaps above). Test build costs are **not** balance.

| Station | Input → output (summary) | Labor |
|---------|---------------------------|--------|
| **Mortar** | 1 grain or root → 1 flour | Women |
| **Oven / hearth bread** | Flour + wood fuel → bread (no water) | Women |
| **Pit fire** | T1: clay + wood → small pot; T2: storage jar | Women + player |
| **Hearth** | 2 food + wood + small empties → stew bowls; large pot is building | Women |
| **Animal pen** | **Merge Farm+Dairy:** feed + mixed animals → wool and/or milk (milk needs small empties) | 1–3 women by tier |
| **Cheese hut / Butter hut** | Milk in container → product + empty back | Women |
| **Cultivation hut** | Seeds in slots → grain/fiber/berries; multi-harvest, better than wild | Women |
| **Rack / Tannery / Leather workshop** | 1 hide → 1 leather sheet + 4 cordage strips (grade by tier) | Haul / passive |
| **Weaver** | Fiber or wool → sheet; bulk rope; crude basket | Women |
| **Tailor** | Sheet + cordage → cloak (T1), +tunic (T2), +robe (T3); same material bill all tiers | Women |
| **Shaman hut** | T1 poultice (berries/dye); T2+ potions need bottles | Women |
| **Shrine** | Relics in → clan buff; T1/2/3 = 1/2/3 slots | No production |
| **Living hut** | +5 baby cap; 1 woman “home” for walk loop | Housing |
| **Leader’s hut** | 1 hide + 1 wood + 1 cordage; **3 breeding woman slots** | [leader_hut.md](leader_hut.md) |

**Campfire (design):** meat only — short = cooked, long = preserved; salt/ash preserve as craft.

**Container rule:** liquids (milk, stew, potions) need **small empty containers** in building inventory; no loose milk piles.

### 3.5 Older parallel plan (`level1_buildings.md`)

Superseded for clothing by economy catalog. Kept for reference:

| Building | Old build cost | Old production |
|----------|----------------|----------------|
| Living hut | 20 wood, 10 stone, 5 hide | +5 baby cap |
| Farm | 15 wood, 5 stone | Wheat 60s, berries 120s (no inputs) |
| Storage hut | 25 wood, 10 stone | 20-slot storage |
| Armory | 20 wood, 10 stone | Spear / club from wood+stone |
| Tailor | 20 wood, 5 stone, 5 hide | Wool→thread; thread+hide→armor |

### 3.6 Other mentions

- **Land claim upgrades:** Flag → Tower → Keep → Castle (costs not locked).  
- **Proto farming Field:** crop ring on flag only — [future implementations/proto_farming.md](future%20implementations/proto_farming.md).  
- **Defense drums:** occupy for defense buff — [future implementations/future_buildings.md](future%20implementations/future_buildings.md).  
- **Production tiers:** 1/2/3 hut modules, 1/2/3 workers, quality common/good/master — [future implementations/production_tiers.md](future%20implementations/production_tiers.md).

---

## 4. Authentic village — reframed building set

### 4.1 Real camp vs game layers

| Real | Game layer |
|------|------------|
| Hearth | Campfire → **central hearth** on flag |
| Lean-to / hut | **Dwelling** (+ baby cap) |
| Work near fire | Recipes on **fire + props**, not separate shops |
| Rack / frame | **Drying frame** (meat, hide) |
| Pen | **One corral** (sheep + goats) |
| Garden patch | **Field / garden ring** (settled) |
| Midden | Optional scrap / bone pile (later) |
| Elders / trophies | **Leader hut**, **relic post** |

### 4.2 Proposed categories (build menu UX)

| Category | Examples |
|----------|----------|
| **Shelter** | Dwelling, lean-to, leader hut, storage platform |
| **Camp infrastructure** | Central hearth upgrade, corral, garden ring |
| **Stations** (small props) | Drying frame, knap spot, weaving stake, pottery pit, butcher mat |
| **Identity / defense** | Relic post, signal/drum post, travois depot |

### 4.3 Stations worth adding (fantasy)

| Station | Role | Inputs → outputs |
|---------|------|-------------------|
| Central hearth | All cooking | Meat cooked/smoked; stew; bread (flour + fuel) |
| Pottery pit | Pots | Clay + fuel → small pot / jar |
| Mortar spot | Grind | Grain/root → flour |
| Drying frame | Dry | Hide → sheet + strips; meat → preserved |
| Knap spot | Tools | Stone → blades / oldowan |
| Weaving stake | Textiles | Fiber/wool → sheet, rope, basket |
| Sewing spot | Clothes | Sheet + cordage → cloak (or woman job at any hut) |
| Butcher mat | Process kills | Corpse → meat, hide, bone |
| Corral | Herd | Feed → wool; milk with empties |
| Garden ring | Crops | Seeds → grain, fiber, berries |
| Relic post | Trophies | Relic in → buff (no craft out) |

Cheese/tanning can be **hearth or rack recipes** unless we want a separate pit for flavor.

### 4.4 Resources for a “messy camp” (piles + tags)

Wood, stone/flint, clay, fiber, hide/fat/bone, grain/roots, meat, resin (later), feed, containers (pots). Prefer **tags** (`fuel`, `dye`, `feed`) over new classes — [economy_catalog.md](economy_catalog.md) §3–4.

### 4.5 How play should feel

1. **Nomad:** fire + 1–3 lean-tos + travois + ground piles; brain assigns gather/hunt/craft at fire.  
2. **Settled:** fire + ring of huts + corral + drying frames + garden; **no row of specialty shops**.  
3. **ClanBrain:** tracks deficits (food days, empties, hides) → assigns best worker → job uses **station tag** (hearth, rack, corral).

### 4.6 Migration from current code

| Today | Direction |
|-------|-----------|
| Oven | Hearth recipe on flag fire |
| Farm + Dairy | One **corral** |
| Drying rack | Keep; rename **drying frame** |
| Shrine | **Relic post** |
| Living hut | **Dwelling** |
| Catalog Mortar/Cheese/Weaver huts | Stations or hearth/rack recipes first |

### 4.7 Minimum authentic village (MVP target)

1. Central fire (cook, stew, bread)  
2. 3–6 dwellings  
3. One corral  
4. 1–2 drying frames  
5. Ground pile props (wood/stone ↔ claim stash)  
6. Garden ring (flag only)  
7. Leader hut or relic post  
8. Optional: knap spot, weaving stake, pottery pit  

Aligns with early game foods: **forage · meat · grain/bread** — [earlygame_vision.md](earlygame_vision.md).

---

## 5. Pipelines (cheat sheet)

```
World gather / butcher → Resources & Food
  → Rack: hide → sheet + strips
  → Weaver: fiber/wool → sheet
  → Mortar: grain/root → flour
  → Hearth: flour + fuel → bread; meat → cooked/smoked
  → Hearth: foods + empties → stew
  → Corral: feed + animals → wool / milk (bottled)
  → Cheese/Butter: milk → … (optional separate or hearth)
  → Cultivation: seeds → crops
  → Tailor: sheet + cordage → clothing
  → Shaman: herbs/berries → medicine / potions
  → Pit fire: clay → pots
Hands: fiber → cordage; stone → oldowan; …
```

---

## 6. Implementation order (from catalog §17, adjusted)

1. Match fiber/diet to herbivore emergency rules.  
2. Woman haul loop on **oven + drying rack** (honest labor).  
3. Leather → sheet + strips when Tailor exists.  
4. **Corral** (merge farm/dairy): feed, death, milk bottles.  
5. Pit fire + pots; hearth building; oven bread-only on hearth.  
6. Weaver + Tailor T1 cloaks.  
7. Cheese / butter / shaman / mortar.  
8. T2/T3 + mastery.  
9. Biome spawn tables.  
10. **Village layout doc in code:** campfire vs flag allow-lists, station props, merge corral.

---

## 7. Related documents

**Program:** [systems_canon_master.md](systems_canon_master.md) — full game systems list and lock workflow.

| Doc | Role |
|-----|------|
| [economy_catalog.md](economy_catalog.md) | **Design lock** — classes, stations, containers, tiers |
| [environment_goal.md](environment_goal.md) | Biome gatherables, wildlife, wood/stone ratios |
| [Buildings.md](Buildings.md) | What the menu does in code today |
| [production_economy.md](production_economy.md) | WorkRequests, bread/leather in code |
| [farms.md](farms.md) | Farm/Dairy/Oven occupation (planned/shipped mix) |
| [leader_hut.md](leader_hut.md) | Leader’s hut |
| [settlement_sim.md](settlement_sim.md) | Off-screen warm tick, passive buildings |
| [GatherGuide.md](GatherGuide.md) | NPC gather/deposit |
| [future implementations/village.md](future%20implementations/village.md) | ClanBrain supply/demand vision |

---

## 8. Open questions (not locked)

- Exact build costs for real balance (not 1w+1s test).  
- One hearth vs keep Oven scene as child of hearth.  
- Whether cheese/tanning get own props or only recipes.  
- Max hut counts per tier (campfire max 3 dwellings today in nomad doc).  
- When to split `economy_catalog` station list into **data-driven station registry** in Godot.
