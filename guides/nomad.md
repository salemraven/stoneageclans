# Nomadic Playstyle & Clan Migration

Collected design concepts for nomadic living, packing up, and clan migration. Single doc to flesh out the full vision.

**Related:** [earlygame.md](../earlygame.md) (Campfire vs Land Claim, travois concepts), [village.md](village.md) (campfire supports 3 living huts → land claim), [phase3.md](../../Phase3/phase3.md) (ClanBrain migration impulse, defectors).

---

## Design Principle

**Campfire = survival and mobility.**  
**Land claim = production and territory.**

- **Nomadic:** Gather, herd, reproduce, move. Lower risk (can flee). Smaller scale.
- **Stationary:** Build, produce, defend, raid. Higher risk (raids). Larger scale.

---

## Campfire (Nomadic Base)

| Dimension | Campfire | Land Claim |
|----------|----------|------------|
| Identity | Temporary base | Permanent settlement |
| Capacity | 6 slots | 12 slots |
| Radius | 250px | 400px |
| Buildings | None | Oven, dairy, farm, huts, etc. |
| ClanBrain | No | Yes |
| Decay | Despawns when extinguished + player far | Decays when clan dies |
| Upgrade path | Can become land claim | N/A |

**Campfire does:** Deposit, reproduction, clan join (herd into radius), cooking, warmth, basic "home."

**Campfire does not:** Place buildings, run ClanBrain, production chains, defenders/searchers.

---

## Migration Triggers

### 1. Seasonal Pressure (earlygame)

Around Day 6, stars shift to hint at approaching winter. Player must either:
- Stockpile dried tubers and cooked meat, or
- **Prepare to migrate** — pack up and move.

### 2. ClanBrain Migration Impulse (phase3)

Voluntary "strike out" when conditions are met:
- Clan is stable
- Male has been there long enough
- **Migration impulse from ClanBrain** — AI decides to send someone to found a satellite or move the whole clan

### 3. Crisis Triggers (phase3)

- **Flee:** Threat/panic → run. If claim destroyed, become cavemen, can found new clan.
- **Leave:** Hunger + no food, long hunger, long low morale → voluntary leave. Same outcome: caveman → can found new clan.

---

## Packing & Moving

### Clansmen Carry Travois

Clansmen can pick up and carry travois (like the player), increasing mobile capacity for the whole tribe.

**Systems:**
- `carried_travois_inventory: InventoryData | null` on NPCBase
- Hotbar slots 0+1 = TRAVOIS when carrying (2-handed)
- `PickUpTravoisTask` — MoveTo(travois) → reserve → transfer → destroy node → set carried state
- `PlaceTravoisTask` — MoveTo(pos) → spawn TravoisGround → transfer → clear carried state
- `carried_by: NPCBase` on TravoisGround — reservation

**AI:** TransportJob chains. Clan brain or land claim generates jobs when transport needed.

### Delegation & Aggregate Carry Capacity

- Player: fixed slots
- Each clansman: 5 inventory + 8 travois (when carrying)
- 3 clansmen with travois ≈ 39 extra slots of mobile storage

**Design intent:** Growth directly increases logistics. Player shifts from "I do everything" to "I lead, they work."

### Pack Hut into Travois

Dismantle a nomadic hut and convert its materials into a travois. Leftover materials go into the travois inventory.

**Formula:** `pack_result = hut_recipe - travois_recipe` (per resource). If any result < 0, cannot pack.

**Example:** Hut = 4 wood, 2 cordage, 8 hides. Travois = 2 wood, 2 cordage. Result: 1 travois with 2 wood + 8 hides in inventory.

**Implementation:** `get_pack_into_travois_result()` using CraftRegistry. Data-driven; works for multiple hut tiers.

---

## Hut Tier Progression (Thatch → Hide)

- **Thatch hut** — cheaper (wood, cordage, fiber)
- **Hide hut** — more expensive (wood, cordage, hides)

Pack-into-travois only works when hut materials satisfy travois recipe. Hide hut can pack; thatch may not if cordage deficit.

---

## Decay for Abandoned Structures

Abandoned structures decay over time. In-use structures do not.

**"In use" definition:**
- Campfire/land claim: has living clan members, items in inventory, recent deposit/interaction, assigned NPCs
- Building: has occupant, has items, belongs to active claim

**Decay trigger:** `last_activity_time`. Decay when `Time.now - last_activity_time > ABANDON_THRESHOLD` AND not in use.

**Performance:** Central `DecayManager`, staggered batch processing, spatial culling, lazy evaluation.

---

## Open Questions & To Flesh Out

### Animal Migration (concept)

- Do wild herds (sheep, goats) migrate seasonally? (e.g. move toward water/greener areas)
- Do clans follow animal migrations — move camp to stay near herds?
- Or is clan migration purely human-driven (seasonal pressure, resources depleted, ClanBrain)?

### Nomadic Huts vs Living Huts

- **village.md:** Campfire can support up to 3 living huts; then player must claim land.
- **bible:** Living Hut requires land claim for pregnancy; houses 1 woman + children.
- **Tension:** Can nomadic campfire have "temporary huts" (thatch/hide) that don't enable pregnancy? Or does campfire reproduction use a different model (lean-to, no hut)?

### Migration Flow (step-by-step)

1. Player decides to migrate — how? (UI action? ClanBrain suggestion?)
2. Pack hut(s) into travois
3. Clansmen pick up travois, women/children follow
4. Player leads — where? (Waypoint? Follow herds? Random direction?)
5. Place campfire at new location
6. Unpack? Or build new huts from carried materials?

### Campfire → Land Claim Upgrade

- When does player "claim land" — place flag, convert campfire?
- What happens to campfire inventory? To huts?
- village.md: campfire supports 3 living huts → then must claim. So nomadic phase has huts before land claim?

### Environment (project-context)

- Storms, droughts, migrations, harsh winters — how do these affect nomadic vs stationary?
- Does winter force migration? Does drought force migration toward water?

---

## Summary Checklist

| Concept | Status | Source |
|---------|--------|--------|
| Campfire vs Land Claim split | Solid | earlygame, bible |
| Seasonal migration pressure | Concept | earlygame |
| Pack hut into travois | Designed | earlygame |
| Clansmen carry travois | Designed | earlygame |
| Hut tiers (thatch/hide) | Designed | earlygame |
| Decay for abandoned | Designed | earlygame |
| ClanBrain migration impulse | Concept | phase3 |
| Animal migration follow | Unspecified | — |
| Full migration flow | To flesh | — |
