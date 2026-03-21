# Stone Age Clans – Official Game Design Document  
**Current Living Version – November 27, 2025**  
**Everything in this file is the single source of truth.**  
All previous documents (July 2025 PDFs) are officially obsolete.

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
- **Right-click** any NPC → **Herd** (they follow you anywhere)  
- **H** next to your Clan Flag = **War Horn** → every idle clansman instantly sprints to you and auto-herds (no cooldown – spamming is harmless)

## 5. Clan Flag & Land Claim
- First craftable object: **X wood + X stone + X berries + X leather** (carryable at spawn)  
- One-time clan symbol + color picker when placed  
- Creates circular radius (invisible fence – your NPCs cannot leave on their own)  
- Own drag-and-drop storage inventory  
- Upgradable in-place: Flag → Tower → Keep → Castle (X radius, X storage, X costs + relics for higher tiers)  
- **War Horn** built-in (H key)  
- Destroy enemy flag = **total wipe** (all inventories vanish, baby pool erased, clansmen drop dead, women/animals scatter as wild)

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
- Destroy enemy flag → total wipe  
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

This is the **complete, current, living game design** as of November 27, 2025.  
Ready for prototype.  
All values remain **X** until you give the order to replace them.