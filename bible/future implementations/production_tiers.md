# Production Tiers — No Tech Tree (future)

**Status:** **Design concept — not implemented.**  
**Core principle:** Mastery comes from **infrastructure and specialization**, not unlocking recipes.  
**Last updated:** September 2026

**See also:** [economy_catalog.md](../economy_catalog.md) (classes, sheet+cordage, two sliders: **tier + mastery**) · [production_economy.md](../production_economy.md) · [Buildings.md](../Buildings.md) · [settlement_sim.md](../settlement_sim.md) · [earlygame_vision.md](../earlygame_vision.md)

**Recipe note (Sep 2026):** Examples below that say `2 hide → cloak` are **old**. Canonical clothes path: hide → Rack/Tannery/Workshop (**1 sheet + 4 strips**) → Tailor (**sheet + cordage**). Same material **cost** at T1 and T3; tier/mastery change **work grade**, not the bill.

---

## Why no tech tree

A main pillar of this game is the understanding of humanity **The problem with tech trees:** They treat knowledge as a binary gate. Once you "research" something. in reality no one can make anything without the foundation, the community and the reasources.

**Reality:** Knowing *how* to make something doesn't mean you have the **means** to make it. A master tailor needs:
- **Time** — not hunting or gathering daily
- **Materials** — consistent supply of quality hides, sinew, dyes
- **Space** — workshop, tools, storage
- **Support** — a community large enough to feed specialists

**Our solution:** **Tiered production buildings** that require progressively larger, more stable communities to sustain specialist craftspeople.

---

## Core design — building tiers

Each production building type (Tailor, Forge, Kiln, Tannery, etc.) has **three tiers** representing mastery levels.

### Structure growth (physical)

| Tier | Huts | Workers | Represents |
|------|------|---------|------------|
| **Tier 1** | 1 small hut | 1 worker | **Generalist** — basic survival craft |
| **Tier 2** | 2 connected huts | 2 workers | **Apprentice system** — refined techniques |
| **Tier 3** | 3-hut compound | 3 workers | **Master workshop** — dedicated artisans |

**Visual:** Each tier **adds** a hut module to the building footprint. Tier 3 looks like a small compound, not a single shack.

### Capability growth (what they make)

Higher tiers don't "unlock" new items — they **specialize** and produce **higher quality** versions of the same goods.

**Example: Tailor**

| Tier | Baseline quality | Can also make | Notes |
|------|------------------|---------------|-------|
| **1** | **Common** cloak | — | Simple wraps; one-size approach; fast but crude |
| **2** | **Good** cloak | Tunics | Fitted garments; better insulation + armor; requires more hides per piece |
| **3** | **Master** cloak | Tunics, Robes | Complex patterns, layered protection, status symbols |

**Key:** Building tier = baseline quality for that craft. A **Tier 1 tailor** makes **Common cloaks**. A **Tier 2 tailor** makes **Good cloaks** (and can also craft Tunics at Good quality). A **Tier 3 tailor** makes **Master cloaks** — the best standard gear.

**Legendary** items are **truly rare** — special drops, unique materials, or extreme luck. Not tied to building tiers.

---

## Quality tiers (all crafts)

Every crafted item has a quality tier based on the **building tier** that made it.

| Quality | Stat bonus | Building tier | Notes |
|---------|------------|---------------|-------|
| **Common** | Base stats | **Tier 1** | Standard survival gear; fast to make |
| **Good** | +25% stats | **Tier 2** | Refined techniques; better materials, better craft |
| **Master** | +50% stats | **Tier 3** | Peak craftsmanship; dedicated artisans |
| **Legendary** | +75% stats + special effect | **Any tier** (very rare) | Unique finds, quest rewards, or extreme luck — not standard production |

**Legendary** items are **truly rare** — maybe a 1% chance even at Tier 3 with perfect materials, or special drops from hunt/raid events. They have unique properties (cloak grants stealth, spear ignores armor, etc.).

**Simple rule:** Tier 1 = Common, Tier 2 = Good, Tier 3 = Master. Legendary is special.

---

## Community cost (why tiers matter)

Higher-tier buildings require **more people doing less survival work**.

### Tier 1 — Everyone survives

- **1 worker** in the building
- Worker **hunts/forages** when no orders (part-time craft)
- Clan food buffer: **~2 days** (still nomadic or early settlement)
- **Output quality:** Common

**Gameplay:** You can build Tier 1 buildings immediately after settling. They support your clan but don't dominate your economy. Common gear gets the job done.

### Tier 2 — Specialists emerge

- **2 workers** in the building
- Workers **rarely hunt** — only when idle or defending
- Clan food buffer: **~5 days** (stable settlement, surplus food)
- **Living Huts required** — more mouths to feed means more housing
- **Output quality:** Good (+25% stats over Common)

**Gameplay:** You need reliable food (Farm + hunts + forage) and a population of ~10+ clanspeople to support 2 full-time tailors. Good gear gives your clan an edge.

### Tier 3 — Mastery class

- **3 workers** in the building
- Workers **never hunt/gather** unless raided — pure artisans
- Clan food buffer: **~10 days** (thriving settlement)
- **Multiple production chains** — Tier 3 tailor needs Tier 2+ Tannery for quality leather
- **Output quality:** Master (+50% stats over Common)

**Gameplay:** Late-game. You need 15–20+ clanspeople, multiple farms, and a secure territory. Tier 3 is a **prestige** investment — your clan has grown beyond survival. Master gear makes your army formidable.

---

## Example: Tailor tiers (full spec)

### Tier 1 Tailor — "Cloakmaker"

**Building:** Small hide-drying hut (1 worker slot)

**Recipes:**
- **Common Cloak** — 2 hide → 1 Common cloak
- Crafted quickly (~30s); basic wrap design

**Worker behavior:**
- When no cloak orders: **searches** for hides, **hunts** small game, or **idles** near claim
- **Not** a dedicated artisan — helps the clan survive

**Unlock:** Place immediately after Tier 2 flag (settled claim)

---

### Tier 2 Tailor — "Garment Workshop"

**Building:** Two connected huts (2 worker slots)  
**Upgrade cost:** 3 wood, 3 hide, 2 leather, 1 dye

**Recipes:**
- **Good Cloak** — 2 hide → 1 Good cloak (+25% stats over Common)
- **Good Tunic** — 3 hide, 1 sinew → 1 Good tunic (+25% stats)  
  *Better insulation and armor than cloak; requires sinew for stitching*

**Worker behavior:**
- **Primary job:** crafting orders from ClanBrain work queue
- **Rarely hunt** — only if work queue empty and food critically low
- **Specialization** — workers build skill over time (not implemented in Phase 1, but design target)

**Requires:**
- Clan population: **10+ clanspeople**
- Food buffer: **5+ days** in storage
- **Living Huts:** enough housing for non-hunters

---

### Tier 3 Tailor — "Master Clothier"

**Building:** Three-hut compound with dye vats and pattern benches (3 worker slots)  
**Upgrade cost:** 5 wood, 5 leather, 3 dye, 1 quadrant rare (e.g. sacred ochre)

**Recipes:**
- **Master Cloak** — 2 hide → 1 Master cloak (+50% stats over Common)
- **Master Tunic** — 3 hide, 1 sinew → 1 Master tunic (+50% stats)
- **Master Robe** — 4 leather, 2 dye, 1 fur → 1 Master robe (+50% stats)  
  *Layered garment; high armor + cold resist; status symbol*

**Legendary chance (1% with perfect materials):**
- **Legendary Cloak** — +75% stats, +10% stealth in forest
- **Legendary Robe** — +75% stats, +5 prestige (social interactions)

**Worker behavior:**
- **Never hunt/gather** — pure artisans
- **Queue only** — wait for orders or maintain equipment
- Workers **gain experience** (future: skill improves output speed)

**Requires:**
- Clan population: **15–20+ clanspeople**
- Food buffer: **10+ days**
- **Multiple Tier 2 production chains** (Tannery for leather, Dyer for dye)
- Secure territory (you can't afford to lose 3 non-combatants in a raid)

---

## Other building types (examples)

Same tier structure applies to all crafts:

| Building | Tier 1 (Common) | Tier 2 (Good) | Tier 3 (Master) |
|----------|-----------------|---------------|-----------------|
| **Tannery** | Common leather | Good leather, leather strips | Master leather, leather armor |
| **Forge** | Common tools, spears | Good flint tools, spearheads | Master obsidian weapons |
| **Kiln** | Common pots | Good pottery, storage jars | Master ceramics, trade goods |
| **Herbalist** | Common poultices | Good medicine, antidotes | Master salves, body paints |
| **Carver** | Common needles, hooks | Good bone tools, totems | Master relics, ritual items |

**Not a promise** — these are examples of the system, not a commitment to implement all of them in Phase 1.

---

## Upgrade path (in-game)

### How to upgrade a building

1. **Build Tier 1** — standard placement (wood, stone, hide)
2. **Accumulate resources + population** — feed your clan, grow your roster
3. **Unlock Tier 2 upgrade** when:
   - Population threshold (e.g. 10 clanspeople)
   - Food buffer threshold (5+ days)
   - Upgrade materials gathered (varies per building type)
4. **Place upgrade** — consumes materials; building visually expands (2nd hut)
5. **Assign 2nd worker** — drag clanswoman to building (future: auto-assign if ClanBrain enabled)

Same flow for **Tier 2 → Tier 3**.

### Why not auto-upgrade?

You might **not want** Tier 3 buildings early — they're expensive and tie up workers. A small raiding clan might prefer 5 Tier 1 buildings (everyone fights when needed) over 1 Tier 3 (3 artisans who can't defend).

---

## Gameplay implications

### Early game (Tier 1 buildings)

- **Fast setup** — basic crafts support nomad-to-settled transition
- **Part-time workers** — crafters also hunt, so you don't starve
- **Common gear** — enough to survive, not enough to dominate

### Mid game (Tier 2 buildings)

- **Specialization** — you choose which crafts to focus (can't upgrade everything)
- **Trade pressure** — you lack Tier 2 in some crafts, so trade or raid for those goods
- **Good gear** — your focused crafts produce strong items (+25% over Common)

### Late game (Tier 3 buildings)

- **Prestige** — Tier 3 is a flex; shows your clan has surplus
- **Master gear** — peak craftsmanship (+50% over Common); chance for Legendary drops
- **Artisan class** — 3–6 workers across Tier 3 buildings never hunt; your army and economy are separate
- **Target** — enemies know you're rich; Tier 3 compounds are raid magnets

---

## Relation to existing systems

| System | How it changes |
|--------|----------------|
| **ClanBrain work queue** | Now checks building tier to pick recipes; issues work orders per tier |
| **Women FSM** | Workers at Tier 2+ stay near buildings (lower hunt/search priority) |
| **Baby cap / Living Huts** | More huts = larger clan = can sustain specialists |
| **Raid economy** | High-tier buildings are valuable loot/destruction targets |
| **Genetics / traits** | Future: NPCs with "Crafting" trait → better rolls at Tier 2/3 |

---

## What this is NOT

- **Not a tech tree** — you don't "research Tunic" and unlock it globally
- **Not linear** — you choose which buildings to upgrade; can't max everything early
- **Not free** — higher tiers cost population, food security, and materials
- **Not instant** — takes time to gather upgrade materials and grow population
- **Not guaranteed** — even Tier 3 + legendary materials can roll Common (low chance, but possible)

---

## Open questions

1. **Skill XP** — do workers improve over time (e.g. 100 cloaks → +5% Legendary chance)?
2. **Building destruction** — if raiders destroy Tier 3, does it drop to Tier 2 or fully destroy?
3. **Worker death** — if a Tier 3 artisan dies, do you lose the slot or just need a replacement?
4. **Multi-building tiers** — can you have 2 Tier 2 Tailors, or only 1 per type per claim?

---

## Implementation sketch (when this ships)

1. **BuildingTier** enum on building node (`TIER_1`, `TIER_2`, `TIER_3`)
2. **Upgrade UI** — new panel when clicking Tier 1/2 building; shows cost, thresholds, preview
3. **Worker slots** — extend `building_base.gd` to track 1–3 worker node paths
4. **Recipe filtering** — `ProductionChainRegistry` checks `building.tier` and outputs appropriate quality
5. **Quality enum** — `COMMON`, `GOOD`, `MASTER`, `LEGENDARY` (1% rare roll)
6. **ClanBrain upgrade logic** — suggest upgrades when population + food hit thresholds

---

## Related

- [Buildings.md](../Buildings.md) — current Tier 1 buildings
- [production_economy.md](../production_economy.md) — ClanBrain work queue
- [settlement_sim.md](../settlement_sim.md) — off-screen production
- [earlygame_vision.md](../earlygame_vision.md) — nomad → settled transition
