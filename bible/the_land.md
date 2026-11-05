# The Land — deity, favor, and climate

**Status:** Design lock, 2026-10-18. Not built. Shipping v1 keeps climate off (painted biomes only).
**Wins with:** [director_locks_2026_10.md](director_locks_2026_10.md) §10. This file is the full spec.
**Map zones:** [environment_goal.md](environment_goal.md) §3.7. Climate overlays: same doc §19.
**Does not replace:** Medic (wounds), shrine relic buffs, or the famine ladder. It uses them.
**Capture:** §9. Not built. Club, cordage, and the shrine sacrifice slot are part of this future pass.

The island has one spirit, **the Land**. Clans may name it. It is not a pantheon and not a quest-giver. Three faces are enough:

| Face | What the player feels | Map system it drives |
|------|----------------------|----------------------|
| **The Wet** | Floods, then shrunken rivers | The four river overlays (`RIVER_NW`, `RIVER_W`, `RIVER_SE`, `RIVER_NE`) |
| **The Hot Sky** | Heat, failed wild grain, animals leave | Desert front and zone rainfall |
| **The Cough** | Sickness in crowded camps | Shaman potions. The Medic stays on wounds and bandages. |

A fourth face (ancestors) waits until death rites need one. Different god names per clan are flavor only. Underneath, every clan bargains with the same three faces.

---

## 1. Two numbers

The server owns both. Clients do not roll weather, spawns, or curses.

| Number | Who it belongs to | What it does | How it fades |
|--------|-------------------|--------------|--------------|
| **Favor** | One clan | Softens the next hit on **that camp** by one step. Biases wild food in **that camp's climate zone**. | Slowly, if they stop offering |
| **Listening** | The whole island | Makes droughts and floods swing less. Slows the ice. Can slip the ice age's start by about a season. | If the island stops offering |

There is a ceiling on Listening. Past it, more blood does not buy more delay. The glacier still grows. Passes still get colder. A long ice age can still leave a small scar in the save (`climate_epoch` in [environment_goal.md](environment_goal.md) §19). Rites buy time to move, store food, and raise cold-resistant children.

**Tithe.** Any offering leaves a little in Listening, even a selfish one (babies, a local soften, a curse). A rite done **to hold the winter** puts most of the offering into Listening and only a little into that clan's Favor.

**Who can see what.** The island sign is public: the Land is listening, or it is not. Your own Favor is shown to you. Other clans' Favor numbers stay hidden. You read them from omens, how rich their land looks, and whether their shrine still holds relics.

---

## 2. What a shaman spends

The shaman already owns potions, body paint, and relic rites. The shrine already parks relics for small camp buffs (morale, hunt, babies) that end if the relic is taken. Favor goes through those. There is no separate spell list.

Offerings come out of the land-claim inventory (or a life). People stop working during a ceremony.

| Offering | What comes back | Favor vs Listening |
|----------|----------------|--------------------|
| Grain or berries | That zone's wild crops replenish sooner, plus a **short** bump to grain-hut output | Normal Favor, small tithe |
| Meat, or a slaughtered animal | The next animal wave of that zone's kit is thicker, plus a **short** bump to animal production | Normal Favor, small tithe |
| A hunt trophy | Same animal-wave bump while it is offered. A relic left on the shrine still uses the relic buffs in [economy_catalog.md](economy_catalog.md) §3.10 | Normal Favor, small tithe |
| One of your own people, or a huge feast | Big climate stability for a shorter time | Large Listening share |
| A captive, **climate rite** | Same as offering one of your own | Large Listening share |
| A captive, **war rite** | A raid and war buff. Not the climate bargain | War buff, small tithe |
| Hold-the-winter rite | Little local bounty | Most of the offering goes to Listening |
| Any other inventory item | A tiny nod, or nothing if it is junk (stone, spare wood) | Tiny, or zero |

One body pays **one** rite. The shrine asks which. A captive given to the Wet or the Hot Sky is the climate offering. A captive given for blood is the war buff. Kin given for blood is the climate price, and the chronicle says it was kin.

Hut and herd bumps fade with Favor. They are a season of help, not a permanent upgrade. Wild replenish is still the main payback. Neighbors can still pick it and hunt it. Junk must not hold off an ice age.

The payback is the **next replenish** of plants and animals that zone already has. It is not items dropped in the stash. It does not add permanent nodes. When Favor fades, the next replenish is normal again. A savanna camp does not spawn desert flint. A jungle camp gets jungle plants and jungle game.

Anyone can pick those plants and hunt those animals. A neighbor on your river can eat your blessing. Territory is the protection.

**Relics** are stored attention. While a relic sits on the shrine, its small buff stays (already locked). Stealing it ends that buff and cuts that clan's ability to feed Listening until they offer again.

**Potions** are the answer during a Cough. They do not replace the rite. **Body paint** is the ceremony.

### Three spends

Favor is spent on one bargain:

1. **Soften** — the next event on your camp drops one severity. The region can still be hit.
2. **Aim** — pay more to push the next event toward one river or one rival camp. They get an omen too. This is a story event with a source clan, a target, and a cost. It is not a hidden nuke.
3. **Babies** — pregnancies come easier for a season. The next severity roll against that camp is worse.

A camp on the glacier gets the full cold no matter its Favor. Favor can still drop an **edge** camp (a savanna zone the ice is entering) by one severity.

---

## 3. How this hits a climate zone

Zones are defined in [environment_goal.md](environment_goal.md) §3.7. Short version: nine whole bodies of land. Each has one temperature and one rainfall. Climate moves a **front** (a single distance), never random speckles inside a zone.

A camp sits in one zone (`TerrainQuery` once that exists). Its Favor applies to that zone only:

- Wild crops and animals use that zone's gatherable kit and wildlife kit, at a higher replenish while Favor there is high.
- That zone's rain and heat swing less.
- If the zone is on a front, Favor there slows **that** front. East savanna can hold the desert line. Any savanna touching the ice can slow the ice **at that edge**. One camp cannot hold every front.
- Several camps in one zone add their Favor for that zone's bounty and for that front. A zone nobody feeds gets the dramatic swing.

Listening is the only thing that slows the **glacier front everywhere**, and only up to the ceiling in §1.

Clans cannot repaint a zone. Desert stays desert. Jungle does not become savanna in holes. Rivers never enter the desert. Oases stay fixed points.

Spawn rolls stay seeded: `world_seed + chunk + zone + layer`. Favor changes the **quota** of the next replenish. The server records what players then pick, chop, or kill. Clients do not spawn their own nodes.

---

## 4. Catastrophes

Three severities. An omen always comes first, same fairness rule as hunger: the player sees it and has time to move food, hunt elsewhere, or hold a rite.

| Step | What it looks like |
|------|--------------------|
| **Omen** | The river looks wrong, herds thin out, a few people cough |
| **Local** | One river, or the camps in one zone. Some fields fail or a handful get sick |
| **Region** | The crowded part of the island takes a real hit |

Favor does not cancel the event. It knocks **your camp** down one step while the zone still suffers.

**What makes a region roll.** A zone that is crowded (many people living in it) rolls toward Region. A zone with high Favor rolls toward a smaller swing. Listening lowers the island-wide drama of drought and flood. It does not erase a local crowd.

**The Cough** spreads in crowded camps. Shaman potions are the counter. The Medic does not become the plague doctor.

**The ice age** is the one event a single shaman cannot stop. It still starts. Listening can push that start by about a season and slow how fast the glacier radius grows. After the ceiling, extra rites do not slow it further. Local Favor only softens edge camps by one step. The center is full cold.

**Recovery.** Seasonal flood and drought overlays go back. A multi-year ice age or desert creep may leave a small permanent delta in the save. The painted map files are never rewritten.

### Population

Two different caps:

1. **Story.** A huge camp that keeps offering is burning the surplus that made it huge, and neighbors can take the wild food that comes back. A huge camp that stops offering gets the dramatic climate, then the famine ladder (no pregnancies, weaker babies, slower fighters, men leave, then deaths). That ladder stays the starvation path. The Land is the world-pressure path.
2. **Safety rail.** If the server is still over a hard NPC ceiling after that, the Land takes the excess and the chronicle says so. Players should almost never see this. If they do often, the story pressure is too weak. The per-clan peak of about 30–60 people ([director_locks_2026_10.md](director_locks_2026_10.md) §1) is unchanged.

---

## 5. What the server stores

Design shape only. Do not treat this as code that exists.

```text
Listening                         # island pool, decays, has a ceiling
Favor per clan                    # decays
Zone state per climate zone       # temperature, rainfall, front distance, severity, bounty quota
River flow per system             # RIVER_NW, RIVER_W, RIVER_SE, RIVER_NE
Active omen / event               # face, severity, zone or river, source clan if aimed
```

Roll inputs: `world_seed + sim_day + climate_zone + Listening + Favor in that zone + how crowded the zone is`. Same result for every player.

Overlays live in `ClimateOverlayStore` or an extended `MutationStore`, as [environment_goal.md](environment_goal.md) §19 already says. Base PNGs stay untouched.

The old single `ritual_pressure` float is retired as the design. Listening plus per-zone Favor replace it.

---

## 6. Stories

Write these into the clan chronicle ([story_data.md](story_data.md)):

- An offering, and which face it was for.
- An omen, and whether the camp softened it.
- A curse: who aimed it, who received it.
- A baby bargain, and the harder season that followed.
- The ice age starting, slipping, or reaching the camp.
- The safety rail taking people, if it ever happens.
- A capture, a finished downed person, a kin sacrifice, and a captive war rite (§9).

---

## 7. When this gets built

Do not build the rites before the map can name a zone.

| Map work already planned | What The Land needs from it |
|--------------------------|-----------------------------|
| Painted biomes and chunk export ([island_map.md](island_map.md), [environment_goal.md](environment_goal.md) §12) | Every land cell stores a `climate_zone` id |
| River system ids on water cells | The Wet can shrink or swell one river |
| `dist` from glacier center, and from the authored desert edge | Fronts move in order, not as speckles |
| Gatherable and wildlife kits per biome (§5–§6) | Bounty adds more of **that** kit |
| Migration waves ([wildlife_migration.md](wildlife_migration.md)) | Drought and ice can cancel a wave; zone Favor can keep the next one thick |
| Phase 6 climate overlays | Listening and Favor are the inputs that used to be `ritual_pressure` |

Until that export exists, keep climate knobs at 0. Scripted drought and flood tests can run before rites exist. Rites hook on after a cell can answer "which zone am I in?"

---

## 8. Still open (numbers, not rules)

These are tuning, measured in playtests, not guessed up front:

- How fast Favor and Listening fade.
- How much one offering moves a front.
- How many people in a zone count as crowded.
- The hard NPC ceiling.
- The exact length of "about a season" of ice delay.
- How long a downed person stays down before they get up (§9).
- How long the war buff lasts, and how strong the parked-captive raid edge is.

The rules in §1–§4 and §9 stay even when those numbers change.

---

## 9. Capture, the club, and the shrine

**Status:** Design lock, 2026-10-18. Not built. Build with the Land rites, not before.

This is how a life gets from the field onto the shrine. Sheep and goats are not part of it. Butcher them and offer the meat (§2).

### Club

A spear or an axe still kills. The **club** does not, on the first hit.

| Hit | Result |
|-----|--------|
| Club on a standing person | They fall. No death shadow. They are **downed**, not dead. |
| Any weapon on a downed person | They die. |
| Nobody binds them | They get back up after a short time. The map does not fill with sleeping bodies. |

Knockout is a tool you choose. Laborers swinging a work club do not knock people out. AI camps still kill with spears in a normal fight. Taking a prisoner is its own future raid goal, beside kill, loot, and burn.

The server owns the downed state. Clients only show the fall.

### Cordage becomes the person

Cordage already exists as crafted rope (`fiber × 3`). Loose rope stays a normal stack in inventories, for travois and clothes.

To take someone:

1. They are downed.
2. You have **loose cordage equipped**.
3. You use it on them. One rope is spent. That hotbar slot **becomes** the captive. The item holds their person id.

| Rule | Detail |
|------|--------|
| Who | Any **adult**. Children are not roped in this pass. |
| Where it can sit | Hotbar **1** and hotbar **2** only. One captive each. Two is the max. |
| Backpack | Bound cordage cannot go in the player inventory. |
| Other hotbar slots | Still weapons and tools. If both hands are ropes, you cannot swing until you select another slot. |
| Drop on the ground | Not allowed while you are alive. |
| You die | The ropes drop. The captives run. |
| What they are not | Not a clan member, not a herdable, no hut, no pregnancy. |

Wild herding stays the **white** line and does not use this rope. The herding contract for the brown line is [HERDING_SYSTEM_GUIDE.md](HERDING_SYSTEM_GUIDE.md) § Captive cord. The older draft that had cordage steal sheep, goats, and women **into your clan** is retired for people. See the note at the top of [herdable_raiding.md](future%20implementations/herdable_raiding.md).

### At the camp

Drag the bound rope from the hotbar into the **land-claim inventory**. The person is tied to the camp.

| Line | Means |
|------|--------|
| White | Herd |
| Red | Party |
| **Brown** | Captive, leashed to the claim (or a short brown leash to the carrier while you are still holding the rope) |

They eat from the land-claim inventory. They can starve, escape, or be cut free by a rival raid. While the brown line holds, the camp has a **small** raid edge. It ends when they leave, die, or are sacrificed. Sacrificing them spends that edge.

### Shrine

The shrine is the altar. The shaman hut is not. The shaman hut keeps potions and body paint.

Relic slots stay as they are (T1 = 1, T2 = 2, T3 = 3). Add **one sacrifice slot** that is not a relic slot, so a fang does not have to come off the shrine to kill a captive.

Drop the bound rope in that slot. The person and the rope are spent. You pick the rite (§2): climate or war. The chronicle records which, and whether it was kin.
