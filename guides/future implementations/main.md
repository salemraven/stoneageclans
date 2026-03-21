# Stone Age Clans – Main Game Mechanics & Vision

**Date**: January 2026  
**Status**: Living Document  
**Vision**: A mix of **Stoneshard** (tactical combat, survival, inventory management) + **RimWorld** (colony management, emergent storytelling, permadeath)

---

## 🎯 Core Vision & Goals

### Primary Fantasy
**Generational permadeath + brutal raiding.** Build a bloodline that dominates the map through strategic combat, resource management, and clan expansion. Pure sandbox – no hard victory screen, only total map domination.

### Design Pillars
1. **Tactical Combat** (Stoneshard-inspired)
   - Direct player control with tactical positioning
   - Weapon-based combat with damage calculations
   - Corpse looting and inventory management
   - Death has consequences (permadeath)

2. **Colony Management** (RimWorld-inspired)
   - AI NPCs with autonomous behaviors (gathering, building, combat)
   - Resource production chains (gather → craft → build)
   - Clan system with land claims and territory control
   - Emergent storytelling through NPC interactions

3. **Survival & Progression**
   - Hunger/thirst systems (currently hunger implemented)
   - Age-based progression (spawn at 13, die at 101)
   - Generational bloodline system
   - Resource scarcity and management

---

## ✅ Currently Implemented Mechanics

### 1. Core Player Systems

#### Player Character
- ✅ Direct control (WASD/Arrow keys)
- ✅ Player inventory (5 slots)
- ✅ Player hotbar (10 equipment slots)
  - Slot 1: Right hand (weapons/tools)
  - Slot 2: Left hand (shield/ammo)
  - Slots 3-8: Equipment (head, body, legs, feet, neck, backpack)
  - Slots 9-0: Consumables (food, health items)
- ✅ Player name system
- ✅ Player attack system (click NPCs to attack)
- ✅ Player can herd NPCs (right-click)
- ⚠️ Age system (structure exists, not fully implemented)
- ⚠️ Hominid species system (planned, not implemented)

#### Player Controls
- ✅ **WASD / Arrow Keys**: Movement
- ✅ **I**: Open inventory (player + nearby building/corpse)
- ✅ **Tab**: Toggle player inventory
- ✅ **9 / 0**: Consume items from hotbar slots
- ✅ **Click NPC**: Attack (if weapon equipped)
- ✅ **Right-click NPC**: Herd (NPC follows player)
- ⚠️ **H** (War Horn): Planned but not implemented

---

### 2. Combat System

#### Core Combat Mechanics
- ✅ **Melee combat**: Click to attack NPCs
- ✅ **Damage system**: Base damage + weapon bonuses
- ✅ **Health system**: HP-based (currently 30 HP = 3 hits to kill)
- ✅ **Death system**: NPCs die and become corpses
- ✅ **Corpse system**: Dead NPCs show corpse sprite (`corpsecm.png`)
- ✅ **Death tracking**: Stores killer and weapon used
- ✅ **Combat component**: Handles attack logic and cooldowns
- ✅ **Weapon component**: Manages equipped weapons and damage bonuses
- ✅ **Health component**: Manages HP, damage, and death events

#### NPC Combat AI
- ✅ **Auto-combat**: NPCs attack each other based on agro meter
- ✅ **Agro system**: NPCs have agro meter (0-100)
- ✅ **Combat state**: FSM state for active combat
- ✅ **Target acquisition**: NPCs select combat targets
- ✅ **Attack cooldowns**: Prevents spam attacks

#### Combat Features
- ✅ **Weapon types**: Axe, Pick (tools can be weapons)
- ✅ **Weapon sprites**: Equipped weapons change NPC appearance (`male1a.png` for axe)
- ✅ **Corpse looting**: Loot items from dead NPCs
- ⚠️ **Wounds system**: Planned (RimWorld-style), not implemented
- ⚠️ **Healing system**: Planned (Medic Hut), not implemented

---

### 3. Inventory & Item Management

#### Inventory System
- ✅ **Unified drag-and-drop**: Works across all inventories
  - Player ↔ Building ↔ NPC ↔ Corpse ↔ Ground
- ✅ **Single item transfer**: Drag moves 1 item (not entire stack)
- ✅ **Visual feedback**:
  - Source slot: 50% opacity when dragging
  - Valid drop: Gold highlight (#FFCE1B, 30% opacity)
  - Invalid drop: Red highlight (#B31B1B, 30% opacity)
- ✅ **Drag cancellation**: Drop on world map restores item
- ✅ **Inventory reorganization**: Drag within own inventory

#### Inventory Types
- ✅ **Player inventory**: 5 slots (reduced from 10)
- ✅ **Player hotbar**: 10 equipment slots
- ✅ **NPC inventory**: 5 slots
- ✅ **NPC hotbar**: 10 equipment slots (cavemen, clansmen)
- ✅ **Building inventory**: Unlimited slots (land claims)
- ✅ **Corpse inventory**: Preserves NPC's inventory + hotbar on death

#### Item Categories (Currently Implemented)
- ✅ **Consumables**: Berries, Grain
  - Can be eaten to restore hunger
  - Can be placed in hotbar slots 9 and 0
  - NPCs can eat from inventory or hotbar
- ✅ **Resources**: Wood, Stone, Wheat, Fiber
  - Used for crafting and building
  - Cannot be consumed directly
- ✅ **Tools**: Axe, Pick
  - Used for gathering resources
  - Can be equipped as weapons
- ✅ **Buildings**: Land Claim, Living Hut, Supply Hut, Shrine, Dairy Farm
  - Placeable structures
  - Have inventories for storage/crafting

---

### 4. NPC Systems

#### NPC Types (Currently Implemented)
- ✅ **Cavemen**: Wild human NPCs (can be herded, can join clans)
- ✅ **Clansmen**: NPCs that belong to a clan
- ✅ **Women**: Wild NPCs (reproduction system)
- ✅ **Sheep**: Wild animals (can be herded)
- ✅ **Goats**: Wild animals (can be herded)
- ⚠️ **Horses**: Planned, not implemented
- ⚠️ **Predators**: Planned (wolves, mammoths), not implemented

#### NPC Components
- ✅ **Health Component**: HP, damage, death
- ✅ **Combat Component**: Attack logic, damage calculation
- ✅ **Weapon Component**: Equipped weapons, damage bonuses
- ✅ **Stats Component**: Hunger, stats (perception, etc.)
- ✅ **Reproduction Component**: Birth timers (women only)
- ✅ **Baby Growth Component**: Baby aging system

#### NPC States (FSM - Finite State Machine)
- ✅ **Idle**: Default state, no action
- ✅ **Wander**: Random movement
- ✅ **Gather**: Collect resources (berries, wood, stone)
- ✅ **Eat**: Consume food to restore hunger
- ✅ **Combat**: Attack targets based on agro
- ✅ **Herd**: Follow a herder (player or NPC)
- ✅ **Herd Wild NPC**: Herd wild animals (sheep, goats)
- ✅ **Seek**: Move toward a target
- ✅ **Agro**: Aggressive behavior toward targets
- ✅ **Build**: Place land claims (currently disabled for battle royale)
- ✅ **Reproduction**: Birth process (women only)

#### NPC Behaviors
- ✅ **Autonomous gathering**: NPCs gather resources automatically
- ✅ **Auto-deposit**: NPCs deposit resources when inventory is 80% full (4/5 slots)
- ✅ **Auto-eating**: NPCs eat when hungry (below 80% hunger)
- ✅ **Clan system**: NPCs can belong to clans
- ✅ **Herding system**: NPCs can follow leaders
- ✅ **Herd breaking**: Herd breaks if leader dies
- ✅ **Dead NPC handling**: Dead NPCs stop all actions

---

### 5. World & Resources

#### World System
- ✅ **Infinite scrolling 2D world**: TileMap-based
- ✅ **Resource spawning**: Trees, boulders, berries, wheat spawn naturally
- ✅ **Ground items**: Items can be dropped on ground
- ✅ **Resource gathering**: Player and NPCs can gather resources
- ⚠️ **Resource respawning**: Planned (infinite), not fully implemented
- ⚠️ **Biomes**: Planned (grass, forest, rocky, water), basic implementation

#### Resources (Currently Implemented)
- ✅ **Berries**: Consumable food (5% hunger restore, 5 nutrition)
- ✅ **Wood**: Resource (gathered with axe)
- ✅ **Stone**: Resource (gathered with pick)
- ✅ **Wheat**: Resource (gathered from wheat patches)
- ✅ **Grain**: Consumable food (7% hunger restore, 7 nutrition)
- ✅ **Fiber**: Resource (NOT consumable, crafting only)

---

### 6. Building & Land Claims

#### Land Claim System
- ✅ **Land Claim item**: Craftable (wood + stone + berries + leather)
- ✅ **Placement system**: Can be placed on world map
- ✅ **Inventory**: Land claims have unlimited storage
- ✅ **Clan assignment**: Land claims belong to clans
- ✅ **Building icons**: Can craft buildings from land claim inventory
- ⚠️ **Radius system**: Planned (invisible fence), not fully implemented
- ⚠️ **Upgrades**: Planned (Flag → Tower → Keep → Castle), not implemented
- ⚠️ **War Horn**: Planned (H key), not implemented

#### Buildings (Currently Implemented)
- ✅ **Land Claim**: Base structure, storage, building crafting
- ✅ **Living Hut**: Planned (+baby pool capacity), structure exists
- ✅ **Supply Hut**: Storage building, structure exists
- ✅ **Shrine**: Planned (relic buffs), structure exists
- ✅ **Dairy Farm**: Planned (milk production), structure exists
- ⚠️ **Farm**: Planned (wool/milk), not implemented
- ⚠️ **Spinner**: Planned (cloth from wool), not implemented
- ⚠️ **Bakery**: Planned (bread crafting), not implemented
- ⚠️ **Armory**: Planned (weapon crafting), not implemented
- ⚠️ **Tailor**: Planned (armor crafting), not implemented
- ⚠️ **Medic Hut**: Planned (healing), not implemented

---

### 7. UI Systems

#### Inventory UI
- ✅ **Player Inventory UI**: 5 slots + 10-slot hotbar
- ✅ **Building Inventory UI**: Unlimited slots (land claims, corpses)
- ✅ **NPC Inventory UI**: 5 slots
- ✅ **Corpse Inventory UI**: Shows character info (name, type, death info)
- ✅ **Drag Manager**: Global drag-and-drop system
- ✅ **Inventory Slot**: Individual slot with drag support

#### UI Features
- ✅ **Hotbar numbers**: Large, transparent numbers (1-0) centered in slots
- ✅ **Character info**: Corpse inventories show death details
- ✅ **Building icons**: Shown on land claims (hidden on corpses)
- ✅ **World interaction blocking**: Inventory open blocks world clicks
- ✅ **Visual feedback**: Highlights, transparency, drag effects
- ⚠️ **Stats Panel**: Planned (Tab key), not implemented
- ⚠️ **Character Menu**: Planned (NPC info), basic structure exists

#### UI Theme
- ✅ **Color palette**: Dark brown backgrounds, saddle brown borders
- ✅ **Panel style**: Semi-transparent, rounded corners (12px)
- ✅ **Text colors**: Off-white primary, light gray secondary
- ✅ **Consistent styling**: All UI follows theme

---

### 8. Special Systems

#### Battle Royale Mode (Testing)
- ✅ **6 cavemen spawn**: Circle formation (200-300px radius)
- ✅ **Max agro**: All NPCs fight immediately (agro = 100.0)
- ✅ **Axe equipped**: All cavemen spawn with axes
- ✅ **Wild NPCs disabled**: No women, sheep, goats spawn
- ✅ **Land claims disabled**: Cannot place land claims

#### Herding System
- ✅ **Player herding**: Right-click NPC to herd
- ✅ **NPC herding**: NPCs can herd wild animals
- ✅ **Herd breaking**: Herd breaks if leader dies
- ✅ **Follow distance**: NPCs maintain follow distance
- ✅ **Herd area radius**: NPCs stay within 300px of leader

#### Death & Corpse System
- ✅ **Death mechanics**: NPCs die when HP reaches 0
- ✅ **Corpse sprite**: Changes to `corpsecm.png` on death
- ✅ **Corpse inventory**: Preserves all items from NPC
- ✅ **Corpse looting**: Press I near corpse (50px range)
- ✅ **Corpse highlight**: Subtle glow when within 50px
- ✅ **Death tracking**: Stores killer name, clan, weapon
- ⚠️ **Corpse decomposition**: Planned (60s to bones, 60s despawn), not implemented

---

## 🚧 Planned Mechanics (From GDD)

### 1. Generational System
- ⚠️ **Age progression**: Spawn at 13, die at 101
- ⚠️ **Hominid species**: 5 species at bloodline start
- ⚠️ **Hybridization**: 50/50 hybridization every generation
- ⚠️ **Baby pool**: Maximum capacity system
- ⚠️ **Surplus babies**: Become permanent AI clansmen

### 2. Advanced Combat
- ⚠️ **Wounds system**: RimWorld-style body part damage
- ⚠️ **Healing system**: Medic Hut with berry-based healing
- ⚠️ **Auto-healing**: Hurt NPCs path to Medic Hut
- ⚠️ **Combat variety**: More weapon types, armor system

### 3. Production Chains
- ⚠️ **Bakery**: Bread crafting (Wheat + edible → Bread)
- ⚠️ **Spinner**: Cloth from wool
- ⚠️ **Dairy**: Cheese & Butter from milk
- ⚠️ **Armory**: Weapon crafting
- ⚠️ **Tailor**: Armor, backpacks, travois crafting

### 4. Advanced Buildings
- ⚠️ **Farm**: Wool (sheep) / Milk (goats) production
- ⚠️ **Medic Hut**: Healing with berries
- ⚠️ **Storage Hut**: Extra shared storage
- ⚠️ **Building upgrades**: Flag → Tower → Keep → Castle

### 5. Raiding System
- ⚠️ **Enemy clans**: Multiple clans on map
- ⚠️ **Raid mechanics**: Attack enemy land claims
- ⚠️ **Total wipe**: Destroy enemy flag = wipe clan
- ⚠️ **War parties**: War Horn + Herd = instant army

### 6. Relics & Shrine
- ⚠️ **Relics**: Rare unique items (wilderness spawns)
- ⚠️ **Shrine buffs**: Place relics → permanent clan-wide buffs
- ⚠️ **Relic requirements**: Higher flag upgrades need relics

### 7. Advanced NPCs
- ⚠️ **Horses**: Bareback riding + travois pulling
- ⚠️ **Predators**: Dire wolves, mammoths (hostile, lootable)
- ⚠️ **Women assignment**: 1 woman per production building
- ⚠️ **Birth timers**: Only run inside land-claim radius

### 8. World Features
- ⚠️ **Resource respawning**: Infinite resources (except relics)
- ⚠️ **Biome variety**: Grass, forest, rocky, water edges
- ⚠️ **Wild wheat**: Grows only outside land-claim radius

### 9. UI Enhancements
- ⚠️ **Stats Panel**: Tab key (species mix, hybrid bonuses, stats)
- ⚠️ **Character Menu**: Full NPC info panel
- ⚠️ **Clan Menu**: Clan management interface
- ⚠️ **Dev Menu**: In-game developer tools (see `dev_menu.md`)

---

## 🎮 Gameplay Loop (Current State)

### Current Loop
1. **Spawn**: Player spawns with basic items (axe, land claim)
2. **Gather**: Collect resources (wood, stone, berries)
3. **Combat**: Fight NPCs (battle royale mode)
4. **Loot**: Collect items from corpses
5. **Manage**: Organize inventory, use consumables
6. **Repeat**: Continue gathering and fighting

### Intended Loop (Full Vision)
1. **Spawn**: Player spawns at age 13, choose hominid species
2. **Establish**: Place land claim, start clan
3. **Gather**: Collect resources, herd animals
4. **Build**: Construct buildings, assign women
5. **Produce**: Create food, weapons, armor
6. **Expand**: Grow clan, claim more territory
7. **Raid**: Attack enemy clans, loot resources
8. **Reproduce**: Manage baby pool, grow bloodline
9. **Age**: Player ages, dies at 101
10. **Continue**: Next generation takes over
11. **Dominate**: Expand until map is controlled

---

## 📊 Implementation Status

### ✅ Fully Implemented
- Core player movement and controls
- Combat system (melee, death, looting)
- Inventory system (drag-and-drop, hotbar)
- NPC AI (gathering, eating, combat, herding)
- Basic building system (land claims)
- UI framework (inventories, drag-and-drop)
- Corpse system (death, looting, character info)

### 🟡 Partially Implemented
- **NPC states**: Most states work, some need refinement
- **Building system**: Structures exist, production chains not implemented
- **Clan system**: Basic structure exists, full features not implemented
- **Resource system**: Gathering works, respawning not fully implemented
- **Age system**: Structure exists, not fully functional

### ⚠️ Planned (Not Implemented)
- Generational permadeath system
- Hominid species and hybridization
- Production chains (bakery, spinner, dairy, etc.)
- Raiding system
- Relics and shrine buffs
- Advanced NPCs (horses, predators)
- Stats panel and character menus
- Full building upgrade system

---

## 🎯 Main Goals & Evolution Path

### Short-Term Goals
1. **Complete core combat**: Wounds, healing, more weapon types
2. **Implement production chains**: Bakery, spinner, dairy
3. **Expand building system**: All planned buildings functional
4. **NPC assignment**: Women to production buildings
5. **Baby pool system**: Full reproduction mechanics

### Medium-Term Goals
1. **Generational system**: Age progression, permadeath
2. **Hominid species**: 5 species, hybridization
3. **Raiding system**: Enemy clans, war parties
4. **Relics system**: Rare items, shrine buffs
5. **Advanced NPCs**: Horses, predators

### Long-Term Goals
1. **Map domination**: Win condition system
2. **Emergent storytelling**: Full stats panel, event system
3. **Advanced combat**: More tactical depth
4. **World variety**: Biomes, resource distribution
5. **Polish**: UI/UX improvements, balance tuning

---

## 🔗 Related Documents

- **`gdd.md`**: Original game design document (vision)
- **`UI.md`**: UI design standards and specifications
- **`items_guide.md`**: Complete item catalog and properties
- **`BATTLE_ROYALE_READINESS.md`**: Current playtest status
- **`charactermenu.md`**: Character menu specifications
- **`dev_menu.md`**: Developer menu planning
- **`guides/dev_resources.md`**: Cursor plans, dev workflow

---

## 📝 Notes

### Design Philosophy
- **Stoneshard**: Tactical combat, inventory management, survival focus
- **RimWorld**: Colony management, AI autonomy, emergent storytelling
- **Hybrid**: Direct player control + autonomous NPCs = strategic depth

### Current Focus
- Battle royale combat testing
- Core systems refinement
- UI/UX polish
- Inventory and item management

### Future Vision
- Full generational bloodline system
- Complex production chains
- Strategic raiding and territory control
- Emergent storytelling through NPC interactions

---

**Last Updated**: January 2026  
**Status**: Living Document – Update as mechanics evolve

Yeah — this hybrid actually makes a *lot* of sense, and you’re already thinking about the right constraints. The key is: **Stoneshard’s readability + RimWorld’s chaos**, without inheriting Stoneshard’s turn-based baggage.

I’ll break this down in a *systems-thinking* way, not engine-specific, so you can visualize options and tradeoffs before committing.

---

## First: the core constraint you’re solving

You want combat that is:

* **Real-time**
* **Simple to reason about at scale** (dozens of units, multiplayer)
* **Readable in pixel art**
* **Works for AI and players**
* **Feels brutal + tactical, not button-mashy**
* **Does NOT turn into RTS micro hell**

That immediately rules out a lot of common systems.

---

## Mental Model: Combat as “Micro-Events,” not Turns

Instead of turns, think in **discrete combat events happening in real time**.

Each unit runs this loop every frame/tick:

```
Perception → Intent → Windup → Resolve → Recovery
```

That loop is your Stoneshard DNA, just **desynced and continuous**.

---

## OPTION 1 (Best Fit): Real-Time Cooldown + Windup Combat

*(This is what I’d recommend you anchor the whole game on)*

### Core idea

* Attacks are **not instant**
* Every attack has:

  * **Windup time** (animation telegraph)
  * **Hit frame**
  * **Recovery cooldown**

Think *Mount & Blade*, *Darkest Dungeon*, *Stoneshard*, and *RimWorld melee* had a baby.

---

### How it feels in play

* Units circle or close distance
* You *see* an axe coming before it lands
* Positioning matters
* Being surrounded is deadly
* Big raids look chaotic but legible

---

### Combat timing example (melee)

| Phase     | Duration | What happens            |
| --------- | -------- | ----------------------- |
| Windup    | 0.3–0.6s | Attack animation begins |
| Hit frame | instant  | Damage + effects apply  |
| Recovery  | 0.4–1.2s | Cannot attack again     |

All real-time. No pausing. No turns.

---

### Why this works for multiplayer + AI

* **Server-friendly**: events are deterministic
* **AI-friendly**: AI just decides *when* to attack
* **Animation-friendly**: 3–5 frames per attack is enough
* **Readable in pixel art**: windup silhouettes matter

---

### How targeting works (important)

Avoid skill targeting. Use **proximity + facing**.

**Melee hit conditions:**

* Target is within range
* Target is inside attack arc (e.g. 90° cone)
* Target still valid on hit frame

That alone adds depth without UI clutter.

---

### What player skill looks like

* Stepping out of range during windup
* Timing attacks to stagger enemies
* Choosing when to commit vs disengage
* Pulling enemies into bad formations

No hotbars. No cooldown UI spam.

---

## OPTION 2: RimWorld-Style “Statistical Real-Time” (Use Sparingly)

This is more *background combat* for large raids.

### How it works

* Attacks resolve probabilistically every X seconds
* Units “swing” but results are math-driven
* Less animation precision

### Pros

* Handles **50+ units easily**
* Very low micromanagement
* Good for AI vs AI raids

### Cons

* Less tactile
* Less skill expression
* Feels less “Stoneshard”

### Where it *does* fit

* Background NPC skirmishes
* Offscreen raids
* Non-player-controlled combat

👉 **Recommendation:**
Use this **only when the player is not directly involved**.

## My Recommended Hybrid (Very Important)

### Player-controlled units:

* **Full windup + hit-frame combat**
* Positioning and timing matter

### AI-controlled masses:

* Same system, but with **simplified decision logic**
* AI doesn’t dodge perfectly
* AI commits more often

Same mechanics, different *brains*.

This avoids “player rules vs AI rules” jank.

---

## Crowd Combat: Preventing Blob Death Spirals

This is critical for raiding.

Add **soft constraints**, not hard rules:

### 1. Limited engagement slots

* Only X attackers can hit a target simultaneously
* Others push, reposition, or wait

### 2. Friendly body blocking

* Units have collision
* Formations naturally emerge
* Narrow terrain matters

### 3. Morale breaks (very RimWorld)

* When:

  * Leader dies
  * HP drops below threshold
  * Outnumbered 3:1
* Units flee instead of fighting to death

This turns raids into **stories**, not meat grinders.

---

## Damage Model: Keep it Brutal but Simple

Avoid bloated RPG math.

### Example

```
Final Damage =
Weapon Damage
+ Strength Bonus
− Armor Flat Reduction
± Random (small)
```

Then layer *effects* instead of numbers:

* Bleed
* Stagger (delay next attack)
* Cripple (slow move speed)

Very Stoneshard. Very readable.

---

## Animation Budget (Pixel Art Friendly)

You do NOT need a lot.

### Melee weapon:

* Idle
* Windup
* Hit
* Recovery

That’s it.
4–6 frames total can sell the whole system.

Add:

* Screen shake on hit
* Small blood sprites
* Sound priority > animation fidelity

---

## Multiplayer Considerations (Early Warning ⚠️)

Design combat assuming:

* **Authoritative server**
* Client predicts movement, not damage
* Hit resolution happens server-side on hit frame

Windups are your friend here — they hide latency.

Perfect — this is where it gets *fun*, because the hybrid only really works if you’re deliberate about **where precision lives and where abstraction kicks in**. I’m going to walk you from **concept → system boundaries → concrete implementation**, so this doesn’t stay hand-wavy.

I’ll structure this in layers so you can literally map it onto code.

---

# 1️⃣ What “Hybrid Option 1 + 2” *Actually* Means (No Vibes, Just Rules)

You are **not** making two combat systems.

You are making **one combat pipeline** with **two resolution modes**:

| Layer        | Player / Nearby Combat | Distant / Mass Combat |
| ------------ | ---------------------- | --------------------- |
| Movement     | Fully simulated        | Fully simulated       |
| Targeting    | Explicit               | Probabilistic         |
| Windup / Hit | Yes (frame-accurate)   | Virtualized           |
| Animation    | Required               | Optional / implied    |
| Damage       | Event-driven           | Time-sliced           |
| AI           | Tactical               | Statistical           |

Same stats. Same weapons. Same HP.
Different **resolution fidelity**.

Think of it as **Level of Detail (LOD) for combat**, not “mode switching”.

---

## Core Combat Loop

Every combat-capable entity runs this **finite state loop**:

```
Idle
 → AcquireTarget
 → Approach
 → WindupAttack
 → ResolveHit
 → Recovery
 → (repeat or disengage)
```

This loop never changes.
What changes is **how precise each step is**.

---

## Combat Resolution LOD (The Most Important Decision)

You define **Combat Resolution Zones**:

### Zone A — High-Fidelity (Player Bubble)

Used when:

* Player is within X tiles (ex: 20–30)
* Or entity is player-controlled
* Or entity is “important” (leaders, champions)

**Uses Option 1 (full real-time combat)**

### Zone B — Low-Fidelity (Background)

Used when:

* Far from player
* Large groups fighting
* No direct player observation

**Uses Option 2 (statistical ticks)**

> Key rule:
> **Units can transition between zones without resetting combat state**

---

## Zone A: Full Real-Time Combat

This is your Stoneshard-feel core.

### Attack Data Structure (example)

```plaintext
AttackProfile {
  range: 1.2 tiles
  arc: 90 degrees
  windup_time: 0.45s
  recovery_time: 0.8s
  base_damage: 8
  stagger: 0.2s
}
```

---

### Timeline of a Single Attack

```
t = 0.00  Windup begins (animation starts)
t = 0.45  Hit frame → damage calculated
t = 0.45–1.25 Recovery (cannot attack)
```

Damage happens **once**, on the hit frame.

---

### Hit Validation (critical for fairness)

On hit frame:

* Is target alive?
* Is target still in range?
* Is target still in arc?
* Line-of-sight clear?

If yes → apply damage
If no → whiff

This alone adds skill without any UI.

---

### Stagger & Interrupts (lightweight but huge impact)

When hit:

* Add `stagger_time` to enemy’s recovery
* Optional: cancel windup if hit early

This naturally creates:

* Focus fire value
* Flanking value
* Weapon identity

---

## Zone B: Statistical Real-Time Combat

This is where RimWorld DNA kicks in.

### Important rule

**Zone B combat still runs in real time**, just **chunked**.

Example:

* Combat ticks every **0.5–1.0 seconds**
* No per-frame checks
* No animation dependency

---

### Group-Based Combat Resolution

Instead of resolving per swing, you resolve **per combat pair** or **small cluster**.

Example tick logic:

```plaintext
For each engaged unit:
  chance_to_hit = f(skill, fatigue, numbers)
  expected_damage = weapon_damage * chance_to_hit
  apply_damage(expected_damage)
```

You can even bias outcomes:

* Outnumbered units take morale damage
* Leaders add bonuses
* Injuries accumulate

---

### Visual Representation (Important!)

You still show:

* Occasional swing animations
* Blood puffs
* HP drops

But these are **cosmetic**, not authoritative.

---

## Transitioning Between Zone B → Zone A

You must **reify** combat cleanly.

### When a player approaches a background fight:

1. Freeze statistical ticks
2. Snapshot combat state:

   * Current HP
   * Who is fighting who
   * Who is staggered / fleeing
3. Spawn entities into:

   * Windup
   * Recovery
   * Idle (based on timers)

You **never rewind** combat.

This makes fights feel continuous, not “fake”.

---

## AI Decision-Making (Same Brain, Different Resolution)

### AI doesn’t think in attacks — it thinks in intents

```
Intent = {
  target: X
  desired_range: melee / short / long
  aggression: 0–1
}
```

Zone A:

* AI respects windups
* AI may dodge or reposition
* AI times attacks imperfectly

Zone B:

* AI intent updates less frequently
* Outcomes are math-driven

Same AI data. Different execution granularity.

---

## Crowd Control Without Hard Rules

Instead of “only 3 attackers allowed”, do this:

### Soft Engagement Pressure

* Collision bodies prevent stacking
* Attack arcs overlap poorly in blobs
* Friendly fire risk (even minimal) discourages density
* Morale penalties for overcrowding

Result:

* Natural lines
* Natural flanks
* Organic chaos

---

# 9️⃣ Multiplayer Implications (You’re Doing This Right)

### Server authoritative rules:

* Movement is predicted
* Attacks are validated server-side
* Damage happens only on server hit frame

### Why windups help:

* Client can *see* attack coming
* Latency is masked by anticipation
* Desync feels like “miss” not “bug”

---

## Implementation Order (Do This in This Order)

If you want this to actually ship:

1. **Single-unit Zone A combat**

   * Windup → hit → recovery
2. **AI melee vs player**
3. **2v2 AI vs AI (Zone A)**
4. **Zone B tick-based combat**
5. **Zone transition logic**
6. **Morale & fleeing**
7. **Raid-scale testing (10–30 units)**

Do NOT start with raids. They hide bugs.

---

## TL;DR (Engineering Version)

* One combat loop
* Two resolution fidelities
* Windups are king
* Damage is event-based, not spam-based
* AI thinks in intent, not attacks
* Zone switching must be lossless

---
1. Combat is discrete, even in real time

Even Zone A combat is not continuous. It’s:

Attack started

Attack resolved

Cooldown finished

Those are events, not per-frame math.

2. Precision is a presentation choice

Zone A and Zone B share:

Same stats

Same outcomes

Same causality

They differ only in:

How often outcomes are sampled

How much animation is tied to them

This lets you downgrade fidelity without changing rules.

3. AI intent > AI actions

AI does not think “swing sword now”.
AI thinks:

Who to fight

How aggressive

Whether to flee

Actions are emergent from timers.

This prevents AI CPU blowups.You use time-based scheduling.

Each unit owns:

next_attack_time

next_ai_update_time

next_morale_check_time

Nothing happens until those timers expire.

---

## Core Architecture

### A. Combat Component (data-only mindset)

Each unit has a CombatComponent, not logic everywhere.

**CombatComponent:**
- `state` (Idle, Windup, Recovery)
- `target_id`
- `attack_profile`
- `next_event_time`

No Update() doing math every frame.

### B. Central Combat Scheduler (performance backbone)

Instead of units polling, you push events into a queue.

Conceptually:

PriorityQueue<CombatEvent> combatEvents


Events are:

AttackHit

RecoveryEnd

MoraleCheck

ZoneTransition

Each event has:

timestamp

entity_id

payload

C. Frame loop becomes dirt cheap

Each frame:

now = current_time

while combatEvents.peek().time <= now:
  event = combatEvents.pop()
  resolve(event)


That’s it.

No loops over units unless needed.

## Zone A Implementation (High-Fidelity)
Windup implementation (cheap + elegant)

When AI or player commits to attack:

state = Windup
schedule_event(
  time = now + windup_time,
  type = AttackHit
)


No polling. No animation dependency.

Animation just listens to state.

Hit resolution (single check, single moment)

At AttackHit event:

Validate target

Apply damage

Apply stagger

Schedule RecoveryEnd

Then forget about it.

Why this scales

100 units attacking does NOT mean:

100 checks per frame

It means:

100 events spread over time

## Zone B Implementation (Low-Fidelity)

Zone B does NOT mean “fake combat”.

It means batching.

Engagement clusters (huge performance win)

Instead of:

20 vs 20 individual duels

You build:

Several engagement clusters

Each cluster tracks:

Cluster:
  participants[]
  next_tick_time


Tick every 0.5–1.0s.

Cluster resolution math (cheap)

Per tick:

Sum attack power per side

Apply damage proportionally

Apply morale pressure

Possibly break engagement

One loop per cluster, not per unit.

Visuals are decoupled

Units can:

Play idle / swing animations randomly

Emit blood FX occasionally

But no animation drives logic.

## Zone Transition (Performance-Safe)

When player enters Zone B area:

Stop cluster ticking

For each unit:

Assign state (Idle / Recovery)

Set next_attack_time with small randomness

Insert into combat scheduler

No rewinds. No resims.

This avoids CPU spikes.

## Pathfinding + Combat

Rule:

Combat units do not pathfind every frame

Instead:

Path only when:

Target changes

Obstacle encountered

Morale breaks

During combat:

Local steering

Push forces

Simple separation

This is way cheaper than A* spam.

## Multiplayer Performance
Server does:

Event scheduling

Damage resolution

Morale logic

Clients do:

Predict movement

Play animations

Interpolate HP

Only events replicate:

Attack started

Hit occurred

Unit died

Morale broke

This keeps bandwidth sane.

9️⃣ WHY THIS OUTPERFORMS “REALTIME” SYSTEMS

Because:

Traditional	Your System
Frame-driven	Event-driven
Polling	Scheduling
Per-unit logic	Clustered logic
Animation-driven	Data-driven
CPU-bound	Time-bound

Your worst-case cost is bounded.

## Hard Rules (Write These Down)

No per-frame combat math

No AI polling

No animation-authoritative logic

All combat resolves at scheduled times

Precision scales with relevance, not count

Follow those, and this will scale to:

50 units easily

100+ units with Zone B

Multiplayer without melting

---

## Core Theoretical Pillars

1. **Combat is discrete, even in real time**
   - Even Zone A combat is not continuous. It's: Attack started → Attack resolved → Cooldown finished
   - Those are events, not per-frame math.

2. **Precision is a presentation choice**
   - Zone A and Zone B share: Same stats, Same outcomes, Same causality
   - They differ only in: How often outcomes are sampled, How much animation is tied to them
   - This lets you downgrade fidelity without changing rules.

3. **AI intent > AI actions**
   - AI does not think "swing sword now"
   - AI thinks: Who to fight, How aggressive, Whether to flee
   - Actions are emergent from timers.
   - This prevents AI CPU blowups.

**Time-based scheduling:**
- Each unit owns: `next_attack_time`, `next_ai_update_time`, `next_morale_check_time`
- Nothing happens until those timers expire.

---

## Core Architecture Overview
A. Combat Component (data-only mindset)

Each unit has a CombatComponent, not logic everywhere.

CombatComponent:
  state (Idle, Windup, Recovery)
  target_id
  attack_profile
  next_event_time


No Update() doing math every frame.

B. Central Combat Scheduler (performance backbone)

Instead of units polling, you push events into a queue.

Conceptually:

PriorityQueue<CombatEvent> combatEvents


Events are:

AttackHit

RecoveryEnd

MoraleCheck

ZoneTransition

Each event has:

timestamp

entity_id

payload

C. Frame loop becomes dirt cheap

Each frame:

now = current_time

while combatEvents.peek().time <= now:
  event = combatEvents.pop()
  resolve(event)


That’s it.

No loops over units unless needed.

## Zone A Implementation (High-Fidelity)
Windup implementation (cheap + elegant)

When AI or player commits to attack:

state = Windup
schedule_event(
  time = now + windup_time,
  type = AttackHit
)


No polling. No animation dependency.

Animation just listens to state.

Hit resolution (single check, single moment)

At AttackHit event:

Validate target

Apply damage

Apply stagger

Schedule RecoveryEnd

Then forget about it.

Why this scales

100 units attacking does NOT mean:

100 checks per frame

It means:

100 events spread over time

## Zone B Implementation (Low-Fidelity)

Zone B does NOT mean “fake combat”.

It means batching.

Engagement clusters (huge performance win)

Instead of:

20 vs 20 individual duels

You build:

Several engagement clusters

Each cluster tracks:

Cluster:
  participants[]
  next_tick_time


Tick every 0.5–1.0s.

Cluster resolution math (cheap)

Per tick:

Sum attack power per side

Apply damage proportionally

Apply morale pressure

Possibly break engagement

One loop per cluster, not per unit.

Visuals are decoupled

Units can:

Play idle / swing animations randomly

Emit blood FX occasionally

But no animation drives logic.

## Zone Transition (Performance-Safe)

When player enters Zone B area:

Stop cluster ticking

For each unit:

Assign state (Idle / Recovery)

Set next_attack_time with small randomness

Insert into combat scheduler

No rewinds. No resims.

This avoids CPU spikes.

## Pathfinding + Combat

Rule:

Combat units do not pathfind every frame

Instead:

Path only when:

Target changes

Obstacle encountered

Morale breaks

During combat:

Local steering

Push forces

Simple separation

This is way cheaper than A* spam.

## Multiplayer Performance
Server does:

Event scheduling

Damage resolution

Morale logic

Clients do:

Predict movement

Play animations

Interpolate HP

Only events replicate:

Attack started

Hit occurred

Unit died

Morale broke

This keeps bandwidth sane.

9️⃣ WHY THIS OUTPERFORMS “REALTIME” SYSTEMS

Because:

Traditional	Your System
Frame-driven	Event-driven
Polling	Scheduling
Per-unit logic	Clustered logic
Animation-driven	Data-driven
CPU-bound	Time-bound

Your worst-case cost is bounded.

## Hard Rules (Write These Down)

No per-frame combat math

No AI polling

No animation-authoritative logic

All combat resolves at scheduled times

Precision scales with relevance, not count

Follow those, and this will scale to:

50 units easily

100+ units with Zone B

Multiplayer without melting
Excellent choice. This is one of those refactors that quietly unlocks **everything else**: performance, raids, multiplayer sanity, and cleaner AI.

I’m going to walk you through this in a very concrete way:

1. **The theory of spatial target acquisition (why it works)**
2. **What to STOP doing immediately**
3. **The spatial system you should build**
4. **How NPCs use it (without polling)**
5. **How this supports Zone A / Zone B later**
6. **Incremental refactor steps so you don’t break the game**

I’ll stay Godot-native since you’re in GDScript, but the ideas are engine-agnostic.

---

---

## Spatial Target Detection System

### The Theory: Targets Are a Spatial Query Problem, Not an AI Problem

Right now, your NPCs think like this:

> “Every frame, look at *everyone*, decide who to fight.”

That’s backwards.

Instead:

> “The world tells me *who is near me* when I ask.”

Key insight:

* **Target acquisition frequency ≠ frame rate**
* NPCs only need *fresh target data every 0.5–2 seconds*
* Combat precision comes later, during attack resolution

So we separate:

* **Detection** (spatial system)
* **Decision** (AI / FSM)
* **Execution** (CombatComponent)

---

### What You Must Stop Doing (Hard Stop)

Anywhere in your code that looks like this is poison at scale:

```gdscript
get_tree().get_nodes_in_group("npcs")
get_tree().get_nodes_in_group("player")
```

Especially inside:

* `update()`
* `can_enter()`
* combat loops

Groups are fine for *rare logic*, not combat.

---

### The Spatial Target System (Core Architecture)

You want a **Spatial Index** that answers one question efficiently:

> “Who is near this position, optionally filtered?”

### Minimal viable options (ranked)

1. **Physics2D Overlap Queries** (recommended, fastest to implement)
2. Uniform grid (spatial hashing)
3. Quadtree (overkill for now)

You should start with **Physics2D**, then graduate later if needed.

---

### Implementation: Physics-Based Target Detection (Best First Step)

#### A. Give every combat-capable unit a Detection Area

Each NPC gets:

```
NPC
 └── DetectionArea (Area2D)
     └── CollisionShape2D (Circle)
```

Radius = perception range (e.g. 200–400 px).

Layer/mask:

* Layer: “detector”
* Mask: “npc | player | hostile”

This is **O(entities entering/exiting)**, not O(n²).

---

### B. DetectionArea Script (event-driven!)

```gdscript
extends Area2D

var nearby_enemies := {}

func _on_body_entered(body):
    if body.is_in_group("combatant"):
        nearby_enemies[body.get_instance_id()] = body

func _on_body_exited(body):
    nearby_enemies.erase(body.get_instance_id())
```

No searching. No loops over the world.

---

#### C. Expose a Query API (important)

```gdscript
func get_nearest_enemy(origin: Vector2) -> Node:
    var closest := null
    var best_dist := INF

    for enemy in nearby_enemies.values():
        if not enemy.is_alive():
            continue
        var d = origin.distance_squared_to(enemy.global_position)
        if d < best_dist:
            best_dist = d
            closest = enemy

    return closest
```

This is now:

* Bounded
* Local
* Cheap

---

### NPC CombatState Uses Timed Queries (NOT per frame)

### Add a retarget timer

In `CombatState.gd`:

```gdscript
var next_target_check := 0
const TARGET_CHECK_INTERVAL := 1.0
```

Then:

```gdscript
func update(_delta):
    if Time.get_ticks_msec() < next_target_check:
        return

    next_target_check = Time.get_ticks_msec() + TARGET_CHECK_INTERVAL * 1000

    if not combat_target or not combat_target.is_alive():
        combat_target = npc.detection_area.get_nearest_enemy(npc.global_position)
```

That’s it.

Targeting now costs:

* **1 small loop**
* **once per second**
* **only over nearby units**

---

### Filtering (Clan, Faction, Morale)

Do NOT bake logic into the spatial system.

Instead, filter in AI:

```gdscript
if enemy.clan_id == npc.clan_id:
    continue
if enemy.is_fleeing:
    continue
```

Spatial system only answers **who is nearby**, not *who to hate*.

---

### How This Enables Zone A / Zone B Later

This system is resolution-agnostic.

### Zone A:

* Detection radius small
* Frequent retarget checks
* High-fidelity combat

### Zone B:

* Larger radius
* Less frequent checks
* Engagement clusters formed from overlapping detection areas

Same data source. Different usage.

---

### Performance Characteristics (Why This Scales)

Let’s compare.

### BEFORE

* 100 NPCs
* Each checks 100 NPCs
* Every frame

👉 ~10,000 distance checks per frame

---

### AFTER

* 100 NPCs
* Each checks ~5–10 nearby entities
* Once per second

👉 ~500 checks per second total

That’s the difference between:

* “Feels fine in testing”
* “Ships with raids”

---

### Incremental Refactor Plan (Do This Safely)

**Do these in order:**

1. Add `DetectionArea` to one NPC
2. Remove `get_nodes_in_group()` from CombatState
3. Switch target acquisition to DetectionArea
4. Add retarget timer
5. Test 1v1
6. Test 10 NPCs idle
7. Test 10 NPCs fighting

Do **not** refactor everything at once.

---

## 10️⃣ Future Upgrade Path (Don’t Do Yet)

Later, when you need more scale:

* Replace Area2D with a **uniform grid manager**
* Keep the same query API
* NPC code stays untouched

That’s how you future-proof.

---

### TL;DR (Sticky Note Version)

* Target acquisition is spatial, not AI logic
* Never scan the world
* Detect locally, query periodically
* Area2D is your first weapon
* Timers beat frames
* FSM sets intent, not awareness

Alright, let’s do this **surgically and safely**, using *your existing FSM* and layering DetectionArea in without blowing things up.

I’ll give you:

1. **The new responsibility split**
2. **DetectionArea contract (what CombatState expects)**
3. **Before → After CombatState logic**
4. **Concrete GDScript example**
5. **Common pitfalls (so you don’t regress performance)**

This is a *real refactor*, not a rewrite.

---

# 1️⃣ New Responsibility Split (Lock This In)

After this refactor:

### CombatState is responsible for:

✅ Deciding *whether* to fight
✅ Choosing *who* to fight (via DetectionArea)
✅ Moving toward target
❌ NOT deciding *when* to attack
❌ NOT scanning the world
❌ NOT dealing damage

### DetectionArea is responsible for:

✅ Tracking nearby entities (event-driven)
✅ Offering query functions (`get_nearest_enemy`)
❌ NOT filtering by AI intent
❌ NOT handling combat logic

---

### DetectionArea Contract (What CombatState Relies On)

CombatState should assume the NPC has:

```plaintext
npc.detection_area
```

With **at least** this API:

```gdscript
func get_nearest_enemy(origin: Vector2) -> Node
func has_enemies() -> bool
```

If DetectionArea does *anything more*, that’s fine — but CombatState should not care.

---

### What We Are Removing From CombatState

### ❌ DELETE these patterns entirely

Anything like:

```gdscript
get_tree().get_nodes_in_group("npcs")
get_tree().get_nodes_in_group("player")
```

Anything like:

```gdscript
func _find_nearest_enemy():
```

Anything like:

```gdscript
combat_comp.attack(target) # per frame
```

If CombatState does *any* of that, it’s still wrong.

---

### New CombatState Flow (Conceptual)

CombatState now runs on **two clocks**:

### Clock A — Movement (frame-based)

* Move toward target
* Face target
* Maintain distance

### Clock B — Targeting (time-sliced)

* Runs every ~1 second
* Asks DetectionArea for best target
* Updates intent

---

### Concrete Refactored CombatState (GDScript)

This is intentionally close to what you already have.

```gdscript
extends NPCState

const TARGET_CHECK_INTERVAL := 1.0

var combat_target: Node = null
var next_target_check_time := 0

func enter(msg := {}):
    combat_target = null
    next_target_check_time = 0

func exit():
    combat_target = null

func update(_delta: float) -> void:
    _update_targeting()
    _update_movement()

func _update_targeting() -> void:
    var now := Time.get_ticks_msec()
    if now < next_target_check_time:
        return

    next_target_check_time = now + int(TARGET_CHECK_INTERVAL * 1000)

    # Target still valid? Keep it.
    if combat_target and _is_valid_target(combat_target):
        return

    # Ask DetectionArea, NOT the world
    if npc.detection_area.has_enemies():
        combat_target = npc.detection_area.get_nearest_enemy(npc.global_position)
    else:
        combat_target = null

func _update_movement() -> void:
    if not combat_target:
        npc.steering_agent.stop()
        return

    var distance := npc.global_position.distance_to(combat_target.global_position)

    if distance > npc.attack_range:
        npc.steering_agent.set_target_position(combat_target.global_position)
    else:
        npc.steering_agent.stop()

        # IMPORTANT: we do NOT attack here
        # We only express intent
        var combat_comp := npc.get_node_or_null("CombatComponent")
        if combat_comp:
            combat_comp.request_attack(combat_target)

func _is_valid_target(target: Node) -> bool:
    if not is_instance_valid(target):
        return false
    if not target.is_alive():
        return false
    if target.clan_id == npc.clan_id:
        return false
    return true
```

---

### Why This Is Correct (Performance + Design)

### Target acquisition:

* Happens **once per second**
* Operates on a **small local set**
* Zero global scanning

### Movement:

* Still smooth and reactive
* Uses existing steering logic

### Combat:

* Requested once per engagement
* No FPS-dependent behavior
* Ready for windup/hit/recovery

---

### Important Follow-Ups (Do NOT Skip These)

### A. DetectionArea must be persistent

Do **not** recreate it.
Do **not** disable it during combat.

### B. CombatComponent must reject spam

Your `request_attack()` **must** check internal state:

```gdscript
if state != "idle":
    return
```

This ensures CombatState can safely call it.

---

### How This Unlocks Zone A / Zone B

Later:

* Zone A NPCs:

  * `TARGET_CHECK_INTERVAL = 0.5`
  * Smaller DetectionArea

* Zone B NPCs:

  * `TARGET_CHECK_INTERVAL = 2.0`
  * Larger DetectionArea
  * Eventually cluster-based combat

**Same CombatState. Same API.**

---

### Quick Sanity Tests (Do These Now)

1. 1 NPC vs Player — attacks still happen
2. 5 NPCs idle — CPU stays flat
3. 5 NPCs fighting — no attack spam
4. Kill target — NPC retargets after ~1s

If all pass, you’re officially on the right track.


## 🤔 Questions & Clarifications for Combat System Refactor

### Architecture & Implementation

1. **Combat Scheduler Implementation**
   - Should the combat scheduler be a singleton/autoload, or a component on a manager node?
   - How do we handle event priority when multiple events occur at the same timestamp?
   - Should the scheduler support event cancellation (e.g., if unit dies before scheduled hit)?
   - What's the maximum event queue size we should allow before batching/compression?

2. **CombatComponent State Machine**
   - Should CombatComponent be a state machine itself (Idle/Windup/Recovery), or just data + event handlers?
   - How do we handle state transitions when events are cancelled (target dies during windup)?
   - Should windup be interruptible by taking damage, or only by death?
   - How do we handle simultaneous attacks (both units windup at same time)?

3. **Zone A/B Transition**
   - What's the exact distance threshold for Zone A vs Zone B? (e.g., 20-30 tiles mentioned)
   - Should transition be instant or gradual (fade between systems)?
   - How do we handle units that are partially in both zones (edge cases)?
   - Should player-controlled units always be Zone A, even if far from camera?
   - What happens to scheduled events when a unit transitions zones?

4. **DetectionArea & Spatial System**
   - Should DetectionArea radius be configurable per NPC type (leaders have better perception)?
   - How do we handle DetectionArea when NPC is dead (should it still detect for corpse looting)?
   - Should DetectionArea have different layers for different entity types (enemies vs allies vs neutrals)?
   - What's the performance impact of 100+ DetectionAreas vs a single spatial grid manager?
   - Should DetectionArea be disabled when NPC is in certain states (e.g., sleeping, unconscious)?

5. **Event-Driven Combat**
   - How do we handle frame timing vs real-time timing? (Godot's Time.get_ticks_msec() vs delta accumulation)
   - Should windup/recovery times be frame-independent or frame-dependent for consistency?
   - How do we sync scheduled events with animation keyframes?
   - What happens if game is paused during a windup? (events queue up or cancel?)

### Edge Cases & Error Handling

6. **Target Validation**
   - What happens if target dies during windup but before hit frame?
   - What happens if target moves out of range during windup?
   - What happens if target moves out of attack arc during windup?
   - Should we validate line-of-sight on hit frame, or only at windup start?
   - How do we handle targets that become invalid (despawned, teleported, etc.)?

7. **Combat State Persistence**
   - How do we save/load combat state (windup progress, scheduled events)?
   - Should combat events persist across scene transitions?
   - How do we handle combat state when NPC is unloaded/loaded (streaming)?

8. **Multi-Unit Interactions**
   - How do we handle friendly fire in blobs? (mentioned as "minimal" but not defined)
   - What's the exact collision/body blocking behavior during combat?
   - How do units push each other in formations? (steering forces vs hard collision)
   - Should units be able to attack through allies, or must they reposition?

### Player vs AI Differences

9. **Player Combat**
   - Should player attacks use the same windup/recovery system, or instant with cooldown?
   - How does player click-to-attack integrate with windup system?
   - Should player have different attack profiles than NPCs (faster, more responsive)?
   - How do we handle player input buffering during windup/recovery?

10. **AI Decision Making**
    - How often should AI update "intent" vs "actions"? (mentioned but not quantified)
    - Should AI have different aggression levels that affect windup commitment?
    - How do we prevent AI from constantly retargeting (target switching spam)?
    - Should AI be able to cancel windup to dodge, or is commitment required?

### Performance & Optimization

11. **Performance Metrics**
    - What's the target FPS with 50 units in Zone A combat?
    - What's the target FPS with 100+ units in Zone B combat?
    - How do we profile/measure combat system performance?
    - Should we have performance budgets (max events per frame, max checks per second)?

12. **Zone B Cluster System**
    - How do we determine cluster boundaries? (proximity-based, faction-based, both?)
    - What's the optimal cluster size before splitting?
    - How do we handle units joining/leaving clusters dynamically?
    - Should cluster resolution be deterministic for multiplayer sync?

13. **Pathfinding Integration**
    - How do we prevent pathfinding spam during combat? (mentioned but not detailed)
    - Should combat units use simpler steering during active combat?
    - How do we handle pathfinding when target is moving (recalculate frequency)?
    - Should we cache paths or recalculate every time?

### Animation & Visual Feedback

14. **Animation System**
    - How do animations sync with windup/hit/recovery events?
    - Should animations drive timing, or timing drive animations?
    - How do we handle animation cancellation (interrupted attacks)?
    - What's the minimum animation budget (frames per attack state)?

15. **Visual Feedback**
    - How do we show windup telegraphs in pixel art? (sprite changes, color shifts, particles?)
    - Should hit effects (blood, screen shake) be tied to hit events or animations?
    - How do we show Zone B combat visually (swing animations are "cosmetic")?
    - Should we show damage numbers, or keep it minimal?

### Morale & Advanced Systems

16. **Morale System**
    - What are the exact morale break conditions? (HP threshold, outnumbered ratio, leader death)
    - How does morale affect combat behavior (flee timing, attack frequency)?
    - Should morale be per-unit or per-cluster in Zone B?
    - How do we handle morale recovery (regrouping, rallying)?

17. **Stagger & Interrupts**
    - How does stagger duration scale with damage/weapon type?
    - Can stagger stack, or does it reset?
    - Should small staggers interrupt windups, or only large ones?
    - How do we prevent stagger spam (cooldown on stagger application)?

### Weapon & Damage System

18. **Attack Profiles**
    - Should each weapon type have unique windup/recovery times?
    - How do we balance fast weapons (low damage, quick) vs slow weapons (high damage, slow)?
    - Should weapon reach affect attack arc, or just range?
    - How do we handle weapon switching mid-combat (cancel current attack?)?

19. **Damage Calculation**
    - What's the exact damage formula? (mentioned but not fully specified)
    - How does armor reduction work (flat vs percentage)?
    - Should there be damage variance/randomization, and if so, what range?
    - How do we handle critical hits (if planned)?

### Migration & Testing

20. **Refactoring Path**
    - How do we migrate existing combat code without breaking current gameplay?
    - Should we implement new system alongside old, then switch, or direct replacement?
    - How do we test combat balance during transition?
    - What's the rollback plan if new system has issues?

21. **Testing Strategy**
    - How do we unit test event-driven combat (mock timers, events)?
    - How do we stress test with 100+ units?
    - How do we test Zone A/B transitions?
    - Should we have combat replay/recording for debugging?

### Multiplayer (Future)

22. **Network Synchronization**
    - How do we sync scheduled events across clients?
    - Should clients predict attacks or wait for server confirmation?
    - How do we handle desync (client thinks hit, server says miss)?
    - What's the event replication strategy (all events vs only important ones)?

23. **Server Authority**
    - Should server validate all attacks, or only important ones?
    - How do we prevent cheating (speed hacks, damage hacks)?
    - Should client-side prediction be allowed, or pure server authority?

### Integration with Existing Systems

24. **FSM Integration**
    - How does CombatState interact with other states (Wander, Gather, etc.)?
    - Should combat be interruptible by other state priorities (e.g., low hunger)?
    - How do we handle state transitions during windup/recovery?

25. **Inventory & Equipment**
    - How does weapon switching affect scheduled attacks?
    - Should unequipping a weapon cancel current attack?
    - How do we handle weapon durability/breaking during combat?

26. **Clan & Faction System**
    - How do we determine enemy vs ally in DetectionArea queries?
    - Should clan relationships affect combat behavior (aggression, targeting priority)?
    - How do we handle neutral NPCs (should they be detectable but not targetable)?

---

**Next Steps**: Prioritize these questions based on implementation order. Start with architecture questions (#1-5) before moving to edge cases and optimizations.

---

## 🔧 Implementation-Specific Questions (Based on Current Codebase)

### Current System Analysis

**What exists now:**
- `CombatComponent`: Simple cooldown-based (2s), instant attacks, no windup
- `CombatState`: Uses `get_nodes_in_group()` every frame in `_find_nearest_enemy()` (line 101-102) - **THIS IS THE PERFORMANCE KILLER**
- `FSM`: Priority-based, evaluates every 0.1s
- Player combat: Direct click-to-attack in `main.gd` (`_player_attack_npc()`), instant damage
- `HealthComponent`: Already has damage tracking, death handling, agro meter integration

**Will the proposed system work?** ✅ **YES, but with these considerations:**

### Critical Integration Questions

27. **Godot Event Scheduler Implementation**
    - Godot doesn't have a built-in PriorityQueue. Should we use:
      - Array + sort (simple, O(n log n) insertion)
      - Custom heap implementation (efficient, more complex)
      - Godot's Timer nodes (easier but less precise)?
    - Where should the scheduler live? (Autoload singleton vs manager node)
    - How do we handle scene tree changes (NPCs destroyed/created) without leaking events?

28. **CombatComponent Refactor**
    - Current `CombatComponent` has `can_attack()` and `attack()` - should we:
      - Keep existing API and add `request_attack()` that schedules events?
      - Completely replace with state machine (Idle/Windup/Recovery)?
      - Hybrid: keep `attack()` for backwards compat, add event system internally?
    - Current system uses `last_attack_time` + cooldown - how do we migrate to windup/recovery?

29. **FSM Integration**
    - Current FSM evaluates states every 0.1s - will CombatState's 1s target check conflict?
    - CombatState currently calls `combat_comp.attack(target)` every frame when in range (line 69) - this will break with windup system
    - How do we prevent FSM from switching states during windup/recovery? (Add state lock?)

30. **Player Combat Integration**
    - Player currently attacks via `_player_attack_npc()` in `main.gd` - instant damage
    - Should player use same windup system, or instant with cooldown?
    - How do we handle player click-to-attack with windup? (Queue attack, show windup animation?)
    - Player doesn't have FSM - how do we integrate CombatComponent for player?

31. **DetectionArea Implementation**
    - Current `CombatState._find_nearest_enemy()` scans all NPCs (line 101-102) - needs to be replaced
    - Should DetectionArea be added to NPC scene, or created dynamically?
    - How do we handle NPCs that don't have DetectionArea yet (backwards compat during migration)?

32. **Agro Meter Integration**
    - Current system uses `agro_meter >= 70` to enter combat (line 83 in CombatState)
    - Agro increases when attacked (HealthComponent line 34-35)
    - How does agro system work with DetectionArea? (Still check agro before entering combat state?)

33. **Zone A/B System**
    - Current system has no concept of zones - how do we determine Zone A vs B?
    - Should we check distance to player every frame, or cache zone membership?
    - How do we handle NPCs transitioning zones mid-combat? (Current combat state doesn't track zone)

34. **Animation Integration**
    - Current system has no combat animations (just sprite changes for weapons)
    - How do we sync windup/hit/recovery with sprites? (AnimationPlayer vs state-driven sprite changes?)
    - Do we need new sprites for windup/recovery, or can we use existing sprites with timing?

35. **Migration Path**
    - Current combat works (battle royale mode) - how do we migrate without breaking existing gameplay?
    - Should we implement new system alongside old, then switch via feature flag?
    - How do we test new system without affecting current battle royale testing?

36. **Performance Validation**
    - Current system: `get_nodes_in_group("npcs")` called every frame per NPC in combat
    - With 6 NPCs in battle royale, that's ~6 scans per frame = ~360 scans/second at 60fps
    - Proposed system: 1 DetectionArea query per second per NPC = 6 queries/second
    - **This is a 60x reduction** - but how do we verify it actually works?

37. **HealthComponent Compatibility**
    - Current `take_damage()` expects instant damage - will work with event system
    - But `take_damage()` also increases agro meter - does this need to change?
    - Death handling already works - should be compatible with scheduled events

38. **Steering Agent Integration**
    - Current CombatState uses `npc.steering_agent.set_target_position()` for movement (line 64)
    - This should still work - movement is frame-based, combat is event-based
    - But what if target moves during windup? (Already handled by hit validation on hit frame)

### Answers & Recommendations

**✅ Will it work?** Yes, with these changes:

1. **Start with DetectionArea refactor** (biggest performance win, lowest risk)
2. **Add windup/recovery to CombatComponent** (keep existing API, add internal state)
3. **Implement event scheduler as autoload singleton** (use Array + sort for MVP)
4. **Player combat**: Use same system but with instant windup (0.1s) for responsiveness
5. **Zone A/B**: Start with Zone A only, add Zone B later when needed

**⚠️ Biggest Risks:**
- FSM state switching during windup (add state lock)
- Player combat feeling sluggish (use shorter windup)
- Event scheduler performance (test with 50+ NPCs early)

**🎯 Recommended Implementation Order:**
1. DetectionArea + CombatState refactor (removes `get_nodes_in_group()`)
2. Windup/recovery in CombatComponent (event-driven)
3. Event scheduler (autoload singleton)
4. Player combat integration
5. Zone A/B system (later, when needed for raids)


---

## ✅ Implementation Guide: Answers to Questions 27-38

**Making the right tradeoffs** so you don't over-engineer early or paint yourself into a corner.

Clear recommendations, not "it depends".

---

## 27. Godot Event Scheduler Implementation

### ✅ What to use **right now**

**Array + sort** is the correct choice.

Why:

* Your event volume is low (dozens/sec, not thousands)
* Simpler to debug
* Easy to throw away later

```gdscript
var events := []

func schedule(time_msec: int, callable: Callable):
    events.append({ "time": time_msec, "callable": callable })
    events.sort_custom(func(a, b): return a.time < b.time)
```

This will not be your bottleneck for a *long* time.

### ❌ What NOT to use

* **Timer nodes** → scene-tree overhead, hard to cancel safely
* **Custom heap** → premature optimization

### 📍 Where it should live

**Autoload singleton** (`CombatScheduler`).

Reasons:

* Global time authority (important for multiplayer later)
* Survives scene reloads
* No dependency loops

### 🧼 Scene tree safety

When resolving events:

* Always check `callable.is_valid()`
* Never store raw node references without validation

You already handle death cleanly — this plugs right in.

---

## 28. CombatComponent Refactor Strategy

### ✅ Correct approach

**Hybrid migration** (do NOT nuke the API yet).

#### Keep:

* `attack()` (deprecated)
* `can_attack()`

#### Add:

* `request_attack()`
* Internal state machine (Idle / Windup / Recovery)

Then internally:

```gdscript
func attack(target):
    request_attack(target)
```

This avoids breaking:

* Player combat
* Battle royale mode
* Any scripts you forgot about

### Migrating from cooldown → windup/recovery

Your current:

```gdscript
last_attack_time + cooldown
```

Becomes:

* `windup_time`
* `recovery_time`

Cooldown = windup + recovery (mentally).

---

## 29. FSM Integration (Important One)

### ❓ Will FSM @ 0.1s conflict with CombatState @ 1s?

**No**, because they're solving different problems.

* FSM decides *what state am I in*
* CombatState decides *who am I fighting*
* CombatComponent decides *when damage happens*

This is the correct separation.

---

### 🚨 Prevent FSM switching during windup

Yes — **you need a soft state lock**, not a hard one.

Add to NPC:

```gdscript
var combat_locked := false
```

CombatComponent:

```gdscript
func _enter_windup():
    owner.combat_locked = true

func _exit_recovery():
    owner.combat_locked = false
```

FSM transition check:

```gdscript
if npc.combat_locked:
    return false
```

This prevents:

* Wander → Idle → Combat flicker
* Combat breaking mid-windup

---

## 30. Player Combat Integration

### ✅ Use the SAME CombatComponent

Do **not** special-case player logic long-term.

### Player-specific tuning

* Windup: `0.1s`
* Recovery: `0.3–0.5s`

This keeps:

* Responsiveness
* Fairness
* Multiplayer consistency

### Click-to-attack flow

```gdscript
func _player_attack_npc(npc):
    player.combat_component.request_attack(npc)
```

### No FSM? No problem.

Player just:

* Faces target
* Stops movement
* Requests attack

CombatComponent does the rest.

---

## 31. DetectionArea Implementation

### ✅ Add it to the NPC scene

Do **not** create dynamically.

Reasons:

* Scene clarity
* Editor-visible
* Zero runtime cost after spawn

### Backwards compatibility

During migration:

```gdscript
if npc.has_node("DetectionArea"):
    use it
else:
    fallback (temporary)
```

Delete fallback once migration is done.

---

## 32. Agro Meter Integration

Your agro system is **still valid**.

### How it fits now:

* DetectionArea answers: *who is near*
* Agro answers: *do I care enough to fight*

CombatState should still check:

```gdscript
if npc.agro_meter < 70:
    return
```

Agro increase on damage stays exactly as-is.

Later, agro becomes:

* Retarget priority
* Morale pressure input

---

## 33. Zone A / Zone B System

### ❌ Do NOT implement this yet

You were right to postpone it.

### When you do:

* Cache zone membership
* Re-evaluate every ~2 seconds
* Or on player movement threshold

Zone transitions should be **events**, not frame checks.

Your current architecture supports this cleanly later.

---

## 34. Animation Integration

### MVP recommendation

**State-driven sprites**, not AnimationPlayer yet.

Example:

```gdscript
if state == WINDUP:
    sprite.frame = WINDUP_FRAME
```

This avoids:

* Animation sync bugs
* Timeline coupling
* Godot AnimationPlayer complexity

Later you can swap in AnimationPlayer without touching combat logic.

---

## 35. Migration Path (You're Thinking Correctly)

### ✅ Feature flag approach is ideal

Example:

```gdscript
const USE_EVENT_COMBAT := true
```

* Keep battle royale working
* Flip flag for testing
* Remove old code once stable

Do NOT migrate everything at once.

---

## 36. Performance Validation

You already did the most important math correctly.

### How to verify in practice:

1. Add debug counters:

```gdscript
CombatScheduler.events_processed_per_second
DetectionArea.query_count
```

2. Log during:

* Idle
* 6 NPC fight
* 20 NPC fight

You should see:

* Flat CPU
* Linear event count
* No frame spikes

If that holds → system is working.

---

## 37. HealthComponent Compatibility

### ✅ No changes needed

Your system is already event-safe.

* Damage remains instant *when event fires*
* Agro increase stays correct
* Death handling cancels future events naturally

This is one of the biggest wins of your architecture.

---

## 38. Steering Agent Integration

You nailed this already.

* Movement remains frame-based
* Combat remains event-based
* Target moving during windup is handled by hit validation

This is exactly how real combat systems work.

---

# Final Verdict

You are **100% on the right track**.

Your design now has:

* Event-driven combat
* Spatial target acquisition
* FSM intent separation
* Clear migration path
* Multiplayer viability
* Raid scalability

Very few indie projects get this architecture right *before* content creep. You did.

---

## What I strongly recommend next

Next highest leverage step:

👉 **Add morale + flee logic as scheduled events**

That's what will turn your raids from "blob DPS" into:

* Breaks
* Chases
* Rout stories
* RimWorld-grade emergent moments

If you want, next I can:

* Design morale math
* Add morale checks into CombatScheduler
* Show how a 20v20 raid collapses organically
* Or help you cleanly delete the old combat code

Say the word and we keep pushing.

