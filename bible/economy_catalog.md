# Economy catalog — crafting, resources, buildings, gatherables

**Status:** Design lock from Q&A (13 Sep 2026). **Most of this is not in code.**  
**Owner:** This file wins on *classification, stations, clothing pipeline, containers, food states, and building tier/mastery.*  
**Code snapshot** still lives in `scripts/resource_data.gd`, `craft_registry.gd`, `building_registry.gd`, `production_config.gd`.  
**Island kits (what grows where):** [environment_goal.md](environment_goal.md) §5–6 — names to add later; do not invent new `ResourceType`s until a recipe needs a unique ID.  
**Building tiers / community gates:** [future implementations/production_tiers.md](future%20implementations/production_tiers.md) — **except** tailor recipes that say `2 hide → cloak` (superseded; see §8).

If this fights [items_guide.md](items_guide.md) or [Buildings.md](Buildings.md), **this file wins** until those are rewritten.

---

## 1. What this is

One place for:

- How we **name** things (class vs tag vs gatherable)
- What **folders** items live in
- How **raw stuff becomes finished stuff**
- **Edible vs craft** vs animal drops vs world nodes
- Every **station**: in → out, who walks there, bottles, tiers
- What is **shipped today** vs locked for later

**Multiplayer:** Server owns stocks, crafts, building inventories, and animal hunger. Clients send “start work / take item.” No client-only milk or stew.

**World spawn:** New nodes stay **chunk-scoped + seeded**. Mutations (chopped, emptied, farmed) are server/save diffs — see [game_map.md](game_map.md) and the chunk-spawn rule.

---

## 2. Words (use these or we get confused)

| Word | Meaning | Not |
|------|---------|-----|
| **Gatherable** | You picked it from the world or a corpse. Not made at a building. | Not a class. Clay is gatherable **and** a Resource. Wool from the farm is **not** gatherable. |
| **Found** | Already usable as-is (gourd, skull, a nice flint flake). Still has a class (usually Container or Resource). | Not a class. |
| **Class** | The main folder for recipes and UI. An item **may have two classes** (example: we still prefer tags for dye — see §4). | Not “processed.” |
| **Tag** | Extra job. List **stays open**. Locked today: `fuel`, `dye`, `feed`. | Not a class. Wood is not class Fuel. |
| **Source** | What it was made from (mammoth hide, plant fiber, lion hide). Finished items **remember source** for stats. | Potions: bottle does **not** change the potion. |
| **State** | **Food only.** Exactly one: `raw` · `cooked` · `preserved`. | Not stacked (no cooked + smoked jerky). |
| **Size / job** | **Container:** `small` or `large`, and **liquid** vs **items**. | Hearth cauldron is part of the building. Travois = largest **item** hauler, no liquids. |
| **Work grade** | How well it was made: **common / good / master**. | **Legendary** = rare extra, any building tier. |
| **Building tier** | T1 / T2 / T3 = extra huts, extra women, extra *recipes*. | Does **not** raise the material bill for the same item. |
| **Building mastery** | XP from doing the work. Raises chance of better work grade + legendary. | A mastered T1 Tailor still only makes **cloaks**. |
| **Imbue** (later) | Diablo-like: extra items on a garment add **stat lines only**. No new cloak art. | Not a new clothing class. |

**Processed is not a class.** When hide becomes strips, those items **are Cordage**, not “processed hide.”

---

## 3. Classes

### 3.1 Resource

Raw piles you gather or butcher or pull from a farm:

wood · stone · clay · fiber · hide · fat · salt · bone / horn / antler / ivory / tooth / shell · resin

**Also Resource:** wool (from the Animal pen — not gatherable).

Examples:

| Item | Gatherable? | Tags | Becomes |
|------|-------------|------|---------|
| Wood | Yes (tree) | `fuel` | Buildings, oven/hearth fuel, hafts |
| Stone | Yes (boulder) | — | Buildings, knap tools (later) |
| Clay | Yes | — | **Pit fire** → small pot; Hearth **build** uses clay |
| Plant fiber | Yes | `feed` | Weaver → sheet; cordage; animal feed; **herbivore emergency food** |
| Hide | Yes (butcher) | — | Rack → 1 sheet + 4 strips |
| Fat | Yes (butcher) | later `fuel`? | Paint, later lamps — not locked |
| Salt | Yes (later biome) | — | Preserve craft (ash too) |
| Bone / horn / shell | Yes (butcher / beach) | — | Tools, relics, found skull-cup |
| Resin | Yes (later) | — | Binder / glue |
| Wool | **No** (Farm) | — | Weaver → sheet |
| Sinew | Yes (butcher) | — | Cordage **thread** (sew only). No sheet. |

**Not Resource:** berries (Food), bread (Food), a cloak (Clothing), a pot (Container).

### 3.2 Food

You can eat it. **State:** raw **or** cooked **or** preserved.

Plant foods and animal foods are **subtypes**, not extra classes.

Both raw and cooked can be **ingredients** in another recipe (stew, bread). The stew is a **new** Food; you don’t keep the leftover steak as a separate meat stack unless the recipe says so.

**Herbivores** (sheep/goats): may eat fiber as **emergency** food. Humans do **not** eat fiber as normal food. `is_food()` in code should match this (today fiber is in the herbivore diet list but not `EDIBLE_FOOD_TYPES` — pick **emergency herbivore only**).

### 3.3 Sheet

Worked panel. **Not** a shirt yet.

| Source | Who makes it | Role (qualitative; numbers later) |
|--------|----------------|-----------------------------------|
| Plant fiber | **Weaver** | A bit of warmth + a bit of armor (basic) |
| Wool | **Weaver** | High warmth, low armor |
| Leather | **Rack / Tannery / Leather workshop** | High armor + medium warmth; **animal** changes it (mammoth warmer than lion) |

### 3.4 Cordage

Finished tie / sew stuff.

| Grade | Source | Jobs |
|-------|--------|------|
| Plant rope | Plant fiber | Tie + sew clothes. **Hands:** 3 fiber → 1 cordage (today’s craft). **Weaver:** stacks / better work grade. |
| Sinew thread | Sinew | **Sew only** (not a sinew shirt) |
| Leather strips | Hide at the Rack (4 per hide) | Heavy tie + hide sewing |

Recipes may ask for a **min grade** or “any cordage.”

### 3.5 Clothing

Finished wear. **Tailor** sews: **sheet + cordage**.

- **T1 Tailor:** cloaks only  
- **T2:** cloaks + **tunics** + **satchel** (worn extra slots)  
- **T3:** cloaks + tunics + **robes** + satchel  

**Sheet** → armor vs warmth. **Cordage** → how long it lasts.  
**Recipe cost does not change with building tier.** A T3 cloak costs the same sheets/cordage as a T1 cloak. Tier/mastery change **work grade**, not the shopping list.

Tunic / robe **counts** (how many sheets) are **not locked** — same cost at every tier once we set them.

**Imbue (later):** add items onto the cloak; extra buffs show on the **stat panel only**.

### 3.6 Container

Two jobs (tag or flag): **liquid** vs **items**.

| Kind | Examples | Where made |
|------|----------|------------|
| **Small liquid** | Milk, potions, stew bowls. Pit-fired pot, bladder, found gourd/skull | Pit fire / hands (bladder) / found |
| **Large liquid** | **Storage jar** (not amphora), water haul later | **Pit fire T2** |
| **Item crate** | Woven **basket** (T1 Weaver, crude) | Weaver |
| **Satchel** | Worn extra slots (not a crate) | **Tailor T2** (sheet + cordage). Rename: not “backpack.” |
| **Travois** | Biggest **item** hauler. **No liquids.** Move camp, raid loot | **Hands:** leather + wood |

Dairy / Shaman / Hearth still need **small liquid empties** or they produce nothing.

Hearth’s cook-pot is **part of the building**, not an inventory amphora.

**Potion:** bottle does **not** change the potion.

### 3.7 Potion

Shaman-made drinks / doses. Many kinds. Always stored in a **small Container**. Empty bottle required to brew (same rule as milk).

**Tiers:** T1 Shaman Hut does **not** make potions (no bottles required yet). **T2** = potions. **T3** = stronger potions + body paints (paint items may be Dye/Paint-tagged Resource or Medicine — recipes later).

### 3.8 Medicine

Salves, smeared herbs, poultices — not bottled spells. **T1 Shaman** output is Medicine only. **Starter recipe:** 1 Food with tag `dye` **or** a later herb Resource → 1 poultice. **Berries work on day 1.** No container. T2+ can still make Medicine and also Potion.

### 3.9 Tool / Weapon

Tool: oldowan, axe, pick, mortar pestle (if we require one later).  
Weapon: spear, club.  
Can be two classes if something is both (axe today).

### 3.10 Relic

Shrine / trophy. **Relics are hunt trophies:** rare horns, fangs, quadrant rares, a named skull — not “any legendary cloak.” Can be class Relic, or Resource you **declare** at the shrine (exact flag later).

**Shrine job:** park relics → clan-wide small buff **while they stay**. Buff type is on the **relic** (morale / hunt / babies). Remove or steal → that buff ends. **No production.** Not the Shaman Hut.

**Slots by tier:** T1 = 1 relic · T2 = 2 · T3 = 3. Relics **full-stack**, even two of the same (two fangs = double hunt buff).

### 3.11 Seed

Chance when you **pick a plant**. **Every plant node** can drop a seed (wheat, fiber, berries, later biome plants). **Not** the food/resource pile (grain ≠ wheat seed). The hut grows **whatever** you slot (berry seed → berry bush, etc.).

Goes into the **Cultivation hut** (4 slots). Slot of wheat seed → wheat plant sprite → harvest **grain**. Slot of fiber seed → fiber plant → harvest **fiber**. Mix allowed (2 wheat + 2 fiber → two of each).

**Emergency food** (like fiber for herbivores): you *can* eat a seed in a pinch — bad calories. Main job is planting.

**Harvest:** Cultivated plants are **not** one-and-done. You pick them **several times** (example: ~3 picks) then a cooldown. **More yield** and **shorter cooldown** than the same plant in the wild. Exact 3× / timers later. Seed-back chance still applies so you can expand slots.

### 3.12 Building

Placeable station or claim piece. The **item** in inventory before placement is still this class (living hut kit, etc.).

---

## 4. Tags (open list)

| Tag | Means | Example |
|-----|--------|---------|
| `fuel` | Can burn | Wood. Fat later maybe. |
| `dye` | Color / paint recipes | Berries, ochre |
| `feed` | Animals eat it | Fiber, later hay |

Add tags when a recipe needs one. Prefer a **tag** over a new class (same as fuel).

**Two classes vs tag:** If two jobs are both “real families” (eat + dye), two classes **are allowed**. We locked **dye as a tag** for berries/ochre so the dye vat looks for `dye`, not class Dye.

---

## 5. Pipeline (every family)

```
RAW (often Resource or Food, often gatherable)
  → WORKED (Sheet, flour, Cordage, small pot, milk-in-bottle)
    → FINISHED (Clothing, bread, stew, cloak, Potion)
```

Some foods skip the middle (meat on the campfire).  
**Source remembered** on worked + finished (except potion vs bottle).

**Quality stack on a finished item (concept):**

1. **Source stats** — mammoth hide warmth vs lion hide armor; stew ingredients  
2. **Work grade** — common / good / master from building **tier baseline + mastery luck**  
3. **Legendary** — rare extra, any tier; mastery raises the chance  
4. **Imbue** (later) — extra stat lines  

Do **not** invent armor % or calorie tables here. Measure / balance later.

---

## 6. Food system

### 6.1 Default rule

Most foods: eat **raw**, or **cook** for a better tier-2 (more calories / a buff). A few raw-only or must-cook later.

### 6.2 States (exclusive)

| State | How | Typical deal |
|-------|-----|----------------|
| Raw | Gather / butcher / dairy | Fine to eat; weaker |
| Cooked | Campfire (meat), Oven (bread), Hearth (stew) | More calories / buff |
| Preserved | Campfire **smoke** (long wait) or salt/ash **craft** | Lasts longer, **fewer** calories |

No “cooked then smoked” combo.

### 6.3 Campfire (meat only)

- Short time on the fire → **cooked**  
- Longer → **preserved** (smoked)  
- Leave it even longer → **stays smoked** (does not burn)  
- Time thresholds: **do not guess** — measure in play  

Salt / ash: no extra building; a craft action.

### 6.4 What is food today in code

`ResourceData.EDIBLE_FOOD_TYPES`: berries, grain, meat, cooked meat, bread, milk, mushroom, bugs, nuts.

Calories (`balance_config.gd`, subject to retune): bugs 25 · mushroom 30 · berries 40 · grain 60 · nuts 80 · milk 100 · meat 250 · bread 300 · cooked meat 320. Daily need ~1800–2200.

Wheat **plant** in the world → inventory **grain** (Food). Wheat is not a carried item.

Milk is **Food**. Carrying / storing lots uses **small containers** (see dairy).

Early-game story ([earlygame_vision.md](earlygame_vision.md)): forage · meat · grain/bread. Extra foods sit under those three.

---

## 7. Container loops (dairy, shaman, hearth)

**Rule:** Production that yields a liquid **serving** needs an empty **small** container in that building’s inventory.

1. Women haul **empties** from the claim into the building (they **stack**).  
2. One fill: 1 empty → 1 filled (milk / potion / stew). Filled stacks.  
3. Women haul **filled** back to the claim.  
4. Cheese hut / Butter hut / drinking / emptying a potion: **returns the empty**. Women may haul empties back to dairy / shaman / hearth.

**No empty → no product.** No “loose milk” pile.

**Dairy:** **small containers only** (not large pots).

**Hearth:** women bring **small empties + food + wood**. Out: **bowls of stew** (filled small containers). The big pot is scenery / part of the building.

---

## 8. Clothing & hide (canonical chain)

```
Animal butcher → Hide (Resource, gatherable)
    → T1 Rack / T2 Tannery / T3 Leather workshop
        → 1 leather Sheet + 4 Cordage strips   (per hide)
            → Tailor: Sheet + cordage → Cloak / Tunic / Robe

Plant fiber (Resource) → Weaver → plant Sheet → Tailor
Wool (Resource, Farm) → Weaver → wool Sheet → Tailor
Sinew → Cordage thread (no sheet)
Hide + cordage → small Container (water bladder) — optional path
```

**Supersedes** `production_tiers.md` recipes like `2 hide → cloak`. That file still owns **hut counts, worker counts, food-buffer gates, and the idea of cloak / tunic / robe.**

**Hide climate:** fluffy / cold animals → more **insulation** on leather sheets. Savanna / thin skins + plant → more **armor**, less fluff. Northern clans want mammoth cloaks; savanna clans can live on plant + light hide.

**Leather work grade by building tier (normal output):**

| Building name | Tier | Normal leather |
|---------------|------|----------------|
| Rack | 1 | Common |
| Tannery | 2 | Good |
| Leather workshop | 3 | Master |

Mastery can still roll **legendary** leather even at T1 (rare).

---

## 9. Building tier + mastery (all production stations)

Copied in spirit from [production_tiers.md](future%20implementations/production_tiers.md), with the **two sliders** we locked:

| Slider | Controls |
|--------|----------|
| **Tier** | Footprint (1 / 2 / 3 huts), women (1 / 2 / 3), **which recipes** exist |
| **Mastery** | How often output is good/master **above** the boring baseline, and legendary chance |

**Baseline (doc):** T1 work feels **common**, T2 **good**, T3 **master**.  
**Plus:** a T1 building that has crafted a lot can be high mastery → more legendaries, still **only T1 recipes**.

**You do not pay more materials** for the same cloak at T3.

**T1 workers** still hunt/forage when idle. **T3** artisans stay on the job unless raided.

Population / food-day gates: use the numbers in `production_tiers.md` until we retune (~2 / ~5 / ~10 food days; ~10 / ~15–20 people). Those are **design**, not code.

**Upgrade:** not automatic. Extra hut modules, extra woman slots. A raid clan may stay T1 on purpose.

**Open (from that doc, still open):** worker XP vs building mastery (we treat **building** mastery as the lock); destroy T3 → drop to T2 or wipe?; dead artisan = empty slot; two T2 Tailors on one claim?

---

## 10. Women labor (all stations)

```
Living hut (home)
  → Land claim (pick up materials / empties)
    → Production building (walk, short craft animation)
      → Land claim (drop products / filled containers)
```

Applies to: Oven, Pit fire, Hearth, Mortar, Cheese, Butter, Animal pen, Rack/Tannery/Workshop, Weaver, Tailor, Shaman, Cultivation — and future stations.

One job at a time. No “bread and pottery in the same oven tick.”

---

## 11. Station list (detail)

Costs in **code today** are test numbers (1 wood + 1 stone). **Do not treat those as balance.** Hearth clay/wood examples (e.g. 6 clay + 4 wood) are **examples only**.

### 11.1 Campfire

- **Today:** player craft 2 wood + 2 stone (`CraftRegistry`). Cooks meat passively. Can upgrade toward land claim (see nomad / campfire docs).  
- **Lock:** meat **only**. Roast vs smoke by **time**.  
- Not a build-menu building.

### 11.2 Land claim

- Clan radius, storage, build menu, women hub.  
- Not from the build menu (start item / campfire upgrade).  
- Exact craft bill (old docs: wood+stone+berries+leather) **not locked**.

### 11.3 Living hut

- **T1:** +5 baby cap. **1 woman** lives/sleeps here (start of the walk loop).  
- **Code today:** +5 exists but is **off** — turn it on when we implement this lock.  
- T2/T3 hut (more beds / more cap): not locked.

### 11.4 Supply hut

- Extra storage. No extra logic locked.

### 11.5 Shrine

- Hunt-trophy relics. **Slots:** T1 = 1 · T2 = 2 · T3 = 3. **Full stack**, including duplicates. Relic out → that buff gone. No crafting.  
- Shaman Hut is a **separate** building.

### 11.6 Mortar

- **1 grain or 1 root → 1 flour.** No fuel. Women yes.  
- Pestle as a required Tool: **not** required for now.

### 11.7 Oven (cooking oven)

- **Flour + wood → bread.** **No water** in the recipe (rivers/water later; we chose skip water, not fake-free water).  
- Does **not** fire pottery. Does **not** stew.

### 11.8 Pit fire (was “Kiln”)

- Open/pit firing — how Corded Ware / Bell Beaker pots were actually made (not a brick kiln).  
- **T1:** 1 clay + 1 wood (`fuel`) → 1 **small pot** (art can be corded or bell beaker).  
- **T2:** **storage jar** (large liquid). More clay + wood; exact counts later.  
- Women walk here; **player can also** load clay+wood and run it.  
- T3 nicer ware: later.

### 11.9 Hearth

- **Build:** includes a large pot (clay + wood in the **building** cost). Large pots are **not** produced as items.  
- **Run:** 2 Food (any) + wood + small empties → stew in small pots. Pot (building) stays.  
- Stew work grade from hearth tier/mastery; **nutrition from ingredients**.

### 11.10 Animal pen

- **One building** — not a separate Farm and Dairy. Same idea as the cultivation hut.  
- **Slots:** T1 = 4 animals / 1 woman · T2 = 8 / 2 · T3 = 12 / 3 (4 animals per woman).  
- Any mix. Sprites in the fence = who’s in the slots.  
- Outputs follow who’s inside: sheep → wool; goats (and later other milk animals) → milk. 4 sheep = wool only. 2+2 = wool **and** milk.  
- Milk still needs **small empties** in the building. Wool does not.  
- Input: `feed`. No feed too long → animals weaken then die.  
- Cheese / Butter stay **other** buildings.

### 11.11 Cheese hut / Butter hut

- **Two buildings.** Milk-in-container in → cheese **or** butter out + **empty back**.  
- Women loop applies.

### 11.12b Cultivation hut

- **Different from animals**, same slot math. **Slots:** T1 = 4 seeds / 1 woman · T2 = 8 / 2 · T3 = 12 / 3.  
- Mix-and-match seeds. Whatever you plant grows.  
- **Visible plants** around the hut (like animals in a pen).  
- Gather **any** plant: chance to drop **Seed** (class). Hut grows that plant (berries included).  
- Output = that crop’s normal item (wheat seed → grain, fiber seed → fiber, berry seed → berries).  
- Harvest: pick **multiple times** (~3) then cooldown; **better** than wild (more stuff, shorter wait). Then cooldown, not “rip out and replant every time.”  
- Chance of extra **seed** so you can fill more slots.  
- Seeds are also **emergency food** (bad calories).

### 11.13 Hide line

- T1 **Rack** · T2 **Tannery** · T3 **Leather workshop**  
- **1 hide → 1 sheet + 4 strips** (yield locked; tune later if hunt economy breaks).  
- Player/woman does not pick “sheet or strips” — **both** from one hide.

### 11.14 Weaver

- Plant fiber **or** wool → matching **Sheet**.  
- Does **not** sew clothes. Does **not** do leather.

### 11.15 Tailor

- Sews Clothing. T1 cloaks; T2 + tunics; T3 + robes.  
- Inputs: sheets + cordage (plus dye/fur on robe — **later**).  
- Suggested starting cloak bill (tunable): **1 sheet + 2 cordage** — not sacred.

### 11.16 Shaman hut

- **T1:** Medicine only. 1 `dye` food (berries) or herb → 1 poultice. No bottle.  
- **T2:** Potions — **small empties** required (same as dairy). Empty returns when drunk / emptied.  
- **T3:** Stronger potions + body paints.  
- Women walk here like other stations.

### 11.17 Farm/dairy vs old Oven woman flag

Code oven recipe says `requires_woman`; play often uses a fire toggle. **This catalog:** women **walk and work** at stations. Occupied work is the intended sim, not “click fire and leave forever” — except we may keep a player toggle for solo testing.

---

## 12. Player crafts (code today vs lock)

`CraftRegistry` now:

| Output | Cost | Time |
|--------|------|------|
| Oldowan | 2 stone | 1s |
| Cordage | 3 fiber | 1.5s |
| Campfire | 2 wood + 2 stone | 2s |
| Travois | leather + wood (replaces old 2 wood + 2 cordage) | item Container, no liquids |

**Hands T1 (Oldowan stays first):**

| Output | Spend | Keep? |
|--------|--------|--------|
| **Bladder** | 1 hide **or** 1 leather sheet + cordage | Small **liquid** Container. Hands. |
| Oldowan | 2 stone | — |
| **Axe** | 1 Oldowan + 1 wood + cordage | Oldowan **consumed** (becomes the head) |
| **Pick** | 1 Oldowan + 1 wood + cordage | Oldowan **consumed** |
| **Blade** | 1 stone (+ must have Oldowan) | Oldowan **kept** (hammer). Stone used up. |
| **Spear (T1)** | 1 wood (+ must have Oldowan) | Oldowan **kept**. Wood used up. Sharpened stick. |
| **Spear (tipped, later)** | wood + blade + cordage | Point is the blade. |

A later hut can make the same recipes at better work grade. Exact cordage count on axe/pick: later (start **1**).

**Plant rope:** hands **and** Weaver. Personal craft = 1× (3 fiber). Weaver = bulk / better work grade.

**T1 Weaver jobs (pick one per work):** sheet · plant rope (bulk) · **crude basket** (item Container).

---

## 13. What the game actually spawns today

World nodes (`gatherable_resource.gd`): wood (axe/oldowan; 25% extra nuts), stone (pick/oldowan), berries, wheat→grain, fiber, bugs (tall grass), nuts.

Butcher: **meat, hide, bone** (blade / oldowan). Same three for every corpse until drop tables exist.

Chunk fill still **rotates** wood/stone/berries/wheat/fiber. Off-screen AI uses fake biomes (`forest` / `plains` / `swamp` / `rocky`) — **not** island biomes yet.

`biome_life.json` is a stub (a few woods + deer/sheep/goat/mammoth).

**Island design** (not items yet): ~4 foods + 5 crafts + 1 special per biome, plus wood/stone everywhere, plus sheep/goats/women everywhere — [environment_goal.md](environment_goal.md) §5–6.

When we fill the island list: prefer **skins + tags** on current kinds first; new IDs only when a recipe **must** say “flint, not river stone.”

---

## 14. Buildings in code vs this catalog

| Code (`BuildingRegistry`) | Catalog |
|---------------------------|---------|
| Living hut | Same; baby cap off |
| Supply hut | Same; thin |
| Shrine | Same; thin. **Not** the shaman |
| Dairy farm + Farm | **Merge in design:** one Animal pen (mix sheep/goats). Code still has two menu items. |
| Oven | **Bread only** (was also “the” production building) |
| Drying rack | **T1 Rack** (hide → sheet + strips). Leather over time in code is hide→leather **item**; catalog splits sheet vs strips |

**New (not in registry):** Pit fire, Hearth, Mortar, Cheese hut, Butter hut, Weaver, Tailor, Shaman hut, Cultivation hut, Animal pen (replaces Farm+Dairy in design).  
**Campfire** exists as a placeable from player craft.

---

## 15. Walk-throughs (use as the template)

### Berry

Gatherable **Food** + tag `dye`. State raw. Eat, or cook, or preserve. Dye recipes look for `dye`.

### Hide

Butcher → Resource. Rack: 1 sheet (leather, animal-source stats) + 4 strips. Tailor and/or bladder.

### Clay

Gatherable Resource. Pit fire → small pot. Also spent when **building** a Hearth.

### Meat

Butcher → Food raw. Campfire → cooked or smoked. May be an **ingredient** in stew/bread (new Food).

### Wool

Farm (sheep + feed, 1 woman, max 4) → Resource. Weaver → wool Sheet. Tailor → warm cloak.

### Sinew

Butcher → Resource. → Cordage thread. Sew only.

### Milk

Dairy: feed + goats + small empties → Food (milk) in bottles. Cheese / Butter consume milk, return empty.

### Stew

Hearth: 2 foods + wood + small empties. Better ingredients → better nutrition. Building sets work grade.

### Cloak

Sheet + cordage at Tailor. T1 or T3: **same cost**. T3 more likely **master** work. Later imbue = extra stats, same sprite.

---

## 16. Decisions we explicitly did **not** lock

- Exact calories, craft seconds, starve timers, hearth / pit-fire / upgrade material counts  
- Tunic/robe sheet counts  
- Imbue slot rules  
- Water gathering (skins, gourds, rivers)  
- Axe / pick / blade / spear recipes  
- Living hut T2/T3  
- Cultivation grow time; seed-drop %  
- Weaver UI: sheet vs rope in the same building  
- Pit fire T2 storage-jar clay/wood counts  
- Whether farm/dairy animals graze for free (locked: dumped feed required; no-feed → die)  
- Full biome item IDs  
- Destroyed T3 building remnant  
- One vs many Tailors per claim  

---

## 17. Implementation order (suggestion, not a promise)

1. Keep current items; fix fiber/diet to match §3.2.  
2. Woman haul loop on **existing** oven + drying rack (honest labor).  
3. Split leather into sheet + strips when Tailor exists; until then hide→leather in code can stay.  
4. Dairy/farm: 1 woman, max 4 animals, feed + death. Small bottles for milk.  
5. Pit fire + small pots; Hearth as a new building; Oven bread-only.  
6. Weaver + Tailor T1 cloaks.  
7. Cheese / Butter / Shaman / Mortar.  
8. T2/T3 + mastery.  
9. Biome spawn tables using **current** kinds, then unique island items.

---

## 18. Related

| Doc | Role |
|-----|------|
| [environment_goal.md](environment_goal.md) | Biome kits, wildlife drops, wood/stone ratios |
| [future implementations/production_tiers.md](future%20implementations/production_tiers.md) | Tier hut/worker/food gates; cloak/tunic/robe **names** |
| [production_economy.md](production_economy.md) | WorkRequests, current bread/leather in code |
| [Buildings.md](Buildings.md) | Placement buffer, what’s in the menu today |
| [items_guide.md](items_guide.md) | **Stale** (May 2026) — properties/hotbar still useful, item list is not |
| [GatherGuide.md](GatherGuide.md) | Gather jobs, tools |
| [earlygame_vision.md](earlygame_vision.md) | Forage / meat / grain |
| [game_map.md](game_map.md) | Chunks, mutations |
