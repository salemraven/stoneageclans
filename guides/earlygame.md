# Early Game

Early game survival loop: mechanics, progression, and feel.

---

## Hominid Classes

| Class | Bonus | Visual/Flavor |
|-------|--------|---------------|
| **Homo Sapiens** | +20% crafting speed; better experimentation success | Lean, agile; carries more (5 slots base). |
| **Neanderthal** | +30% hunting yield; +cold resistance | Stocky, hairy; starts with 1 extra health. |
| **Denisovan** | +25% foraging (plants); high-altitude biomes bonus | Robust, high cheekbones; poison resistance. |
| **Homo Erectus** (hard mode) | +15% tool durability; firestarting easier | Primitive, fire-hardened tools; slower but tough. |

## Spawn & Initial Situation
You begin alone in a procedural biome (grassy plains edge, forest margin, etc.). Inventory is empty except for your body. Hunger and thirst bars are visible and dropping steadily. It is Day 1, Summer. You must manually consume food items from inventory to restore hunger.

The immediate goal is to avoid death from starvation, thirst, or exposure to night cold.

## Early Game Survival Loop (Solo → Duo/Trio)
The core cycle is:

**Gather basics → Craft Oldowan → Harvest nodes and corpses → Consume food → Prepare for night → Scout/recruit → Repeat**

**Oldowan** is the starting multitool.  
- Crafted by combining 2 Stone.  
- Functions as a crude hand axe, scraper, and chopper in one.  
- Used to gather:  
  - Wood from tree nodes  
  - Stone from boulder nodes  
  - Meat and leather scraps from animal corpses  
- Very inefficient: gathering takes noticeably longer than later specialized tools.

### Starting Sequence
1. Gather loose resources by hand:  
   - Berries, greens, grubs, tubers from bushes and ground  
   - Thatch and fiber bundles from grass  
   - Wood sticks from small branches  
   - Loose stone from the ground  
2. Combine 2 Stone to create the Oldowan multitool.  
3. Use Oldowan to:  
   - Harvest wood from tree nodes  
   - Harvest stone from boulder nodes  
   - Harvest meat scraps and leather scraps from animal corpses  
4. Use a wood stick as a club or throw loose stone to create small animal corpses (rats, grubs, small birds).  
5. Use Oldowan on those corpses to obtain meat scraps and leather scraps.  
6. Consume raw food items from inventory (risk of illness from uncooked meat).  
7. Build a Living Hut (shelter) using wood and stone.  
8. Attempt to start a fire by rubbing a wood stick with dry thatch or fiber (long and unreliable process until better methods are discovered).

### Daily Cycle Expansion
- Use Oldowan to stock wood, stone, meat scraps, and leather scraps.  
- Process leather scraps and tubers at the hearth once fire is established (still slow due to Oldowan inefficiency).  
- Cook meat scraps over the hearth for safe consumption and better hunger restoration.  
- Explore map edges to find potential recruits:  
  - Starving wanderer (share food to recruit)  
  - Wounded child (carry and heal with cooked food)  
  - Lone forager (defeat in combat to recruit)  
- Duo forms around Day 3; trio around Day 5.  
- Carry capacity remains very limited (4 slots base for most classes), forcing constant decisions about what to keep, consume, or drop.

### Night & Exposure
- Without shelter or fire, night cold drains health steadily.  
- **Living Hut** provides shelter (wind and cold protection).  
- Fire (campfire or land claim) provides warmth in a radius and enables cooking. See [shelter_and_warmth.md](shelter_and_warmth.md).

### Weekly Pressure
Around Day 6, stars shift to hint at approaching winter. Stockpile dried tubers and cooked meat (Oldowan harvest + hearth drying/cooking) or prepare to migrate.

## Key Early Milestones & Feel
- First Oldowan creation → gathering becomes possible, though slow  
- First fire → cooking unlocks safe food and warmth  
- First Living Hut → night survival becomes realistic  
- First recruit → parallel gathering and hunting speed up dramatically  
- Oldowan breaking → forces recrafting and highlights the need for better tools  

The loop emphasizes raw scarcity, manual consumption, and the slow grind of a single inefficient multitool. Every improvement (fire, recruits, better tools later) feels like a major breakthrough.

---

## Campfire vs Land Claim: Nomadic vs Stationary

Clear design line separating two playstyles.

| Dimension | Campfire (Nomadic) | Land Claim (Stationary) |
|-----------|--------------------|--------------------------|
| **Identity** | Temporary base | Permanent settlement |
| **Capacity** | 6 slots | 12 slots |
| **Radius** | 250px | 400px |
| **Buildings** | None | Oven, dairy, farm, huts, etc. |
| **Production** | None | Bread, cheese, crops |
| **ClanBrain** | No | Yes (defenders, searchers, raids) |
| **Defender quota** | 0 | Yes |
| **Searcher quota** | 0 | Yes |
| **Raid target** | Yes | Yes |
| **Decay** | Despawns when extinguished + player far | Decays when clan dies |
| **Upgrade path** | Can become land claim | N/A |

### Campfire Does

- Deposit (shared storage)
- Reproduction (babies)
- Clan join (herd into radius)
- Cooking (fire on)
- Warmth
- Basic "home" for clan

### Campfire Does Not

- Place buildings
- Run ClanBrain (no defender/searcher quotas)
- Have production chains
- Assign defenders or searchers

### Design Principle

**Campfire = survival and mobility.**  
**Land claim = production and territory.**

- **Nomadic:** Gather, herd, reproduce, move. Lower risk (can flee). Smaller scale.
- **Stationary:** Build, produce, defend, raid. Higher risk (raids). Larger scale.

### Progression

Campfire is the first step. Land claim is the second. Player can upgrade campfire → land claim when ready to settle.

---

## Content to Add

Planned systems and mechanics for the nomadic early game and beyond.

### Clansmen Carry Travois

**Concept:** Clansmen can pick up and carry travois (like the player), increasing mobile capacity for the whole tribe.

**Systems:**
- `carried_travois_inventory: InventoryData | null` on NPCBase – when set, NPC is carrying a travois
- Hotbar slots 0+1 = TRAVOIS when carrying (2-handed, matches player)
- `PickUpTravoisTask` – MoveTo(travois) → reserve → transfer inventory → destroy node → set carried state
- `PlaceTravoisTask` – MoveTo(pos) → spawn TravoisGround → transfer inventory → clear carried state
- `carried_by: NPCBase` on TravoisGround – reservation to prevent two NPCs grabbing same travois

**AI:** TransportJob chains MoveTo + PickUpTravois + item transfers. Clan brain or land claim generates jobs when transport is needed.

### Delegation & Aggregate Carry Capacity

**Concept:** Player orchestrates; clan executes. Total mobile capacity = sum of all carriers.

- Player: fixed slots
- Each clansman: 5 inventory + 8 travois (when carrying)
- 3 clansmen with travois ≈ 39 extra slots of mobile storage

**Design intent:** Growth (recruiting, babies) directly increases logistics. Player shifts from "I do everything" to "I lead, they work."

### Pack Hut into Travois

**Concept:** Dismantle a nomadic hut and convert its materials into a travois. Leftover materials go into the travois inventory.

**Formula:** `pack_result = hut_recipe - travois_recipe` (per resource). If any result < 0, cannot pack.

**Example:** Hut = 4 wood, 2 cordage, 8 hides. Travois = 2 wood, 2 cordage. Result: 1 travois with 2 wood + 8 hides in inventory.

**Implementation:** Single `get_pack_into_travois_result()` using CraftRegistry recipes. Data-driven; works for multiple hut tiers (thatch, hide) as long as hut materials satisfy travois cost.

### Decay for Abandoned Buildings & Campfire Land Claims

**Concept:** Abandoned structures decay over time. In-use structures do not.

**"In use" definition:**
- Land claim / campfire: has living clan members, has items in inventory, had deposit/interaction recently, has assigned NPCs
- Building: has occupant, has items, belongs to active land claim

**Decay trigger:** `last_activity_time` per object. Decay when `Time.now - last_activity_time > ABANDON_THRESHOLD` AND not in use.

**Multiplayer performance:**
- Central `DecayManager` – staggered batch processing (e.g. every 30s, process 50 candidates)
- Spatial culling: only tick objects in loaded chunks or near players
- Lazy evaluation: add to candidates when eligible; remove on use or destroy

### Hut Tier Progression (Thatch → Hide)

**Concept:** Different shelter tiers with different costs. Better structures cost more.

- **Thatch hut** – cheaper (e.g. wood, cordage, fiber)
- **Hide hut** – more expensive (e.g. wood, cordage, hides)

Same structure as equipment tiers. Pack-into-travois only works when hut materials satisfy travois recipe (e.g. hide hut can pack; thatch hut may not if cordage deficit).
