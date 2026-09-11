# Stone Age Clans – Official Game Design Document  
**Current Living Version – September 2026** (vision & rules; **verify** numbers in code/`BalanceConfig` / `WorldGenConfig`)  
**Design intent** lives here; **implementation truth** is `bible.md` + `bible/main.md` + [earlygame_vision.md](earlygame_vision.md).  
**Opening loop (Tier 1 campfire → Tier 2 flag):** [earlygame_vision.md](earlygame_vision.md), [nomad.md](nomad.md).

**Implementation note (May 2026):** The world uses **chunk-based streaming** for procedural resources, trees, grass, ground items, wild women, migratory wildlife, and optional seeded AI clans. Infinite plain, seed, load/unload, and file map → **`bible/game_map.md`**. GDD §2 “world” remains the **player-facing** description.

## 1. Core Fantasy & Win Condition
Generational permadeath + brutal raiding.  
You win only when your bloodline completely dominates the map.  
Pure sandbox – no hard victory screen.

## 2. World
- Infinite scrolling 2D plain (grass, forest patches, rocky areas, water edges)  
- All normal resources respawn infinitely (trees, boulders, berries, wheat, animals)  
- Only relics are finite and non-respawning

## 3. Player Character
- Male only, spawn at age 13 → natural death at 101  
- Choose one of 5 hominid species at bloodline start → full 50/50 hybridization every generation  
- Direct control of player character only (clansmen are AI)

## 4. Universal Controls & UI
- **I** = open any flag or building inventory  
- **Drag-and-drop** absolutely everything (player ↔ flag ↔ buildings ↔ clansmen ↔ ground)  
- **Right-click NPC** → **context menu** (Follow, Defend, Search, Work, Info). **Wild herdables:** walk within influence range (~250px) to attach — not instant follow from menu alone.  
- **H** = **War Horn** → rally nearby clansmen (~1500 px). **Today:** can clear active herds on rallied units. **Planned:** searchers mid-herd ignore Horn ([rts.md](rts.md)). In **HUNT** mode, **H aborts** the hunt.  
- **B** = **Break** — dismiss formation; return toward claim.

## 5. Territory — Tier 1 Campfire → Tier 2 Flag
- **Spawn** with no claim; first home = **Tier 1 Campfire** (nomadic land claim, **ABANDON CAMP**, max 3 Living Huts).  
- **Tier 2 Flag** = settle: craft **wood + stone + berries + leather**; 400px radius; full production + AoH.  
- Destroy enemy flag = **territory wipe** (loot first). **Wild cavemen** — planned ([clan_founding_and_exile.md](clan_founding_and_exile.md)).

## 6. Baby Pool & Living Huts
- Baby pool has a maximum capacity  
- Every **Living Hut** adds **+X** to maximum capacity  
- Surplus babies beyond capacity → permanent AI clansmen

## 7. Women
- Wild women spawn in wilderness → Herd → bring into radius → claimed  
- Drag-and-drop assignment: **1 woman per production building**  
- Birth timer only runs inside an active land-claim radius

## 8. Buildings (all inside radius only, drag-and-drop inventories)
| Building      | Woman | Main Function                                      |
|---------------|-------|----------------------------------------------------|
| Living Hut    | 0     | +X baby pool capacity                              |
| Farm          | 1     | Wool (sheep) / Milk (goats) – herd animals in      |
| Spinner       | 1     | Cloth from wool                                    |
| Dairy         | 1     | Cheese & Butter from milk                          |
| Bakery        | 1     | Bread: X Wild Wheat + any one edible (berries/meat/cheese/butter) |
| Armory        | 1     | Weapons                                            |
| Tailor        | 1     | Armor, backpacks, travois                          |
| Medic Hut     | 1     | Heals wounds over time (needs berries in inventory) – hurt NPCs auto-path here |
| Storage Hut   | 0     | Extra shared storage                               |
| Shrine        | 0     | Place relics → permanent clan-wide buffs          |

## 9. NPCs
| NPC            | Spawn         | Purpose                                      |
|----------------|---------------|----------------------------------------------|
| Women          | Wilderness    | Reproduction + production buildings          |
| Sheep / Goats  | Wilderness    | Wool & milk                                  |
| Horses         | Wilderness    | Bareback riding + travois pulling            |
| Clansmen       | Surplus babies| Permanent AI army (auto-guard or herded)     |
| Predators      | Wilderness    | Dire wolves, mammoths, etc. – hostile, loot  |

## 10. Combat & Healing
- RimWorld / Dwarf Fortress style auto-combat (no direct unit control)  
- Wounds exist → hurt characters automatically walk to Medic Hut if berries are stocked

## 11. Raiding
- Loot every building + flag inventory first (drag-and-drop)  
- Destroy enemy flag → **territory wipe** (wild cavemen / founder — planned — [clan_founding_and_exile.md](clan_founding_and_exile.md))
- War Horn + Herd = instant massive war parties

## 12. Food – Bakery & Bread
- Wild Wheat grows **only outside any land-claim radius**  
- Drag **X Wheat + any one edible** (berries, meat, cheese, or butter) into Bakery → **X-second** timer → **1 flavored Bread Loaf** (best food in the game)

## 13. Relics & Shrine
- Rare unique items (wilderness spawns or animal drops)  
- Drag into Shrine inventory → permanent clan-wide buff  
- Higher flag upgrades require relics

## 14. Stats Panel (Tab key)
Tracks species mix, exact hybrid bonuses, clansmen count, baby pool/cap, raids won, women claimed, bread baked, etc. – full Dwarf Fortress-style emergent storytelling.

This is the **complete living game design** for vision, systems, and intent as of **April 20, 2026**.  
Prototype gameplay exists; numeric balance lives in config scripts and guides noted above.  
Placeholder costs in tables remain **X** until explicitly replaced in the GDD.