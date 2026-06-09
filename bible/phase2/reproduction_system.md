# Reproduction System - Implementation Plan

## Overview
The reproduction system allows women NPCs to reproduce with male cavemen (player or NPC) to create babies. Babies are active NPCs that wander within the land claim area. The system is modular and may be extended to sheep and goat reproduction in the future. Wild NPCs cannot become pregnant.

**Key Design Decisions:**
- Reproduction only occurs within land claim area
- Land claim provides +3 base baby capacity (no Living Huts needed initially)
- Each Living Hut adds +5 capacity
- Babies are active NPCs (not frozen in pool) that wander within land claim
- Babies grow to clansmen automatically after 1 minute (testing) or at 13 years (normal)
- Birth timer: Fixed 90 seconds for testing (will be variable based on traits later)
- Cooldown: 20 seconds between births
- When land claim is destroyed, pregnant women lose pregnancy (become wild NPCs)
- Women NPCs get random names when spawned (similar to cavemen naming system)
- All NPCs are currently human (no species differentiation needed for naming)

## Integration with Existing Framework

### 1. Component System Integration

**New Component: `reproduction_component.gd`**
- Location: `scripts/npc/components/reproduction_component.gd`
- Attached to: Women NPCs only
- Purpose: Handles birth timers, mate detection, pregnancy state

**Component Structure:**
```gdscript
extends Node
class_name ReproductionComponent

var npc: NPCBase = null
var is_pregnant: bool = false
var birth_timer: float = 0.0
var birth_timer_max: float = 90.0  # Fixed 90s for testing (variable later with traits)
var birth_cooldown: float = 20.0  # 20 second cooldown between births
var last_birth_time: float = 0.0  # Track last birth time
var mate_detected: bool = false
var current_mate: NPCBase = null
```

**Integration Points:**
- Attach component in NPC scene or via `npc_base.gd` initialization
- Check `npc_type == "woman"` to attach component
- Component updates in `_process()` or via NPC's update loop

**Note:** Women NPCs must have random names when spawned (currently use "Woman %d" format). Should use `NamingUtils.generate_caveman_name()` or similar function for random names.

### 2. FSM State Integration

**New State: `reproduction_state.gd`**
- Location: `scripts/npc/states/reproduction_state.gd`
- Extends: `base_state.gd`
- Priority: 8.0 (below herding 10.6, above gathering 3.0)

**State Logic:**
- Only women can enter this state (wild NPCs cannot reproduce)
- Checks for nearby male cavemen (player or NPC, same clan) within land claim area
- Mate selection: Based on traits and age (prefers clan leader/higher quality mates)
- If mate found and not pregnant and cooldown expired: start birth timer
- If pregnant: countdown timer, spawn baby on completion
- Timer only runs when woman is inside her clan's land claim radius
- If land claim destroyed during pregnancy: cancel pregnancy (woman becomes wild NPC)

**FSM Registration:**
- Add to `fsm.gd` `_create_state_instances()` method
- Register as "reproduction" state
- Add priority: 8.0

### 3. Baby Pool Manager

**New Manager: `baby_pool_manager.gd`**
- Location: `scripts/systems/baby_pool_manager.gd`
- Singleton or attached to Main scene
- Purpose: Tracks baby pool capacity per clan, stores baby data

**Manager Structure:**
```gdscript
extends Node
class_name BabyPoolManager

var baby_pools: Dictionary = {}  # {clan_name: {babies: [], capacity: int}}
var living_hut_manager: Node = null  # Reference to building system
```

**Capacity Calculation:**
- Base capacity: +3 from land claim (players/NPCs start with 3 baby capacity)
- Each Living Hut adds +5 to capacity
- Query Living Hut system for count per clan
- Update capacity when Living Huts are built/destroyed
- Formula: `capacity = 3 + (living_hut_count * 5)`

### 4. Baby Spawning System

**Baby Creation:**
- Spawn at land claim center when birth timer completes
- Create NPC instance with `npc_type = "baby"`
- Age: 0 (starts at birth)
- Sprite: `baby.png` (64x64 pixels)
- Active NPC with FSM (not frozen in pool)
- Wander state within land claim area
- Inherit traits from parents (50/50 hybridization - disabled until traits implemented)

**Baby NPC Properties:**
- Active NPC that wanders within land claim (not frozen)
- Sprite: `baby.png` (64x64 pixels) - located in `res://assets/sprites/`
- FSM: Wander state within land claim boundaries only
- Behavior: Babies have nothing to do - just wander within land claim area
- Inventory: 2 slots for food (consumed from land claim inventory when hungry)
- Age tracking: Shows random name and age in inventory UI when clicked
- Growth: Automatically becomes clansman after 1 minute (testing) or at 13 years (normal)

**Baby Inventory:**
- 2 inventory slots for food
- Food comes from land claim inventory (auto-transfers when baby hungry)
- When baby clicked: Shows inventory UI with random name and age display
- Babies eat automatically when hungry (consume food from inventory)

**Baby Growth System:**
- Testing: Babies grow to clansmen after 1 minute (60 seconds)
- Normal: Babies become clansmen at age 13 years (future implementation)
- Growth timer: Tracks time since birth (or age for normal mode)
- Automatic promotion: No manual promotion - happens automatically

### 5. Clansmen System

**Clansman Creation:**
- When baby growth timer completes (1 min testing / 13 years normal)
- Create NPC instance with `npc_type = "clansman"`
- Sprite: Same caveman sprite as NPC cavemen
- Age: 13+ (adult)
- Same clan as parents

**Clansman Properties:**
- Behavior: Same FSM as NPC cavemen - gather, herd, deposit loop
- FSM States: Same as NPC cavemen (gather, herd_wildnpc, deposit, etc.)
- Clan Membership: Belongs to same clan as parents
- Appearance: Uses caveman sprite (same as NPC cavemen)
- Function: Permanent AI workforce for the clan

**Clansman Behavior:**
- Follows same FSM priorities as NPC cavemen
- Gathers resources (trees, boulders, berries)
- Herds wild NPCs (women, sheep, goats)
- Deposits items at land claim
- Participates in clan activities (same loop as NPC cavemen)


### 6. Trait Inheritance System

**Status:** Disabled until traits system is implemented

**Future Hybridization Logic:**
- Each parent contributes 50% of traits
- Random selection: 50% chance per trait from each parent
- Max 6 traits per NPC
- Stat blending: Average parent base stats
- Quality tier: Inherit from parents or random

**Future Implementation:**
- New function in `npc_base.gd`: `inherit_traits(parent1: NPCBase, parent2: NPCBase)`
- Called when baby is created
- Stores parent references for trait calculation
- Currently: Babies inherit basic stats/clan from parents only

### 7. Integration with Land Claim System

**Land Claim Detection:**
- Use existing `_is_position_in_land_claim()` helper from `base_state.gd`
- Check if woman is inside her clan's land claim
- Birth timer only decrements when inside claim
- Women stay inside land claim as long as they are part of the clan
- If land claim is destroyed: Women become wild NPCs (pregnancy canceled)

**Clan Membership:**
- Woman must have `clan_name != ""` to reproduce (wild NPCs cannot reproduce)
- Mate must be same clan (`clan_name == woman.clan_name`)
- Babies inherit clan from parents
- When land claim destroyed: All clan NPCs (including pregnant women) become wild NPCs

### 8. Visual Feedback

**Pregnancy Indicator:**
- No visual sprite modification (no tint/overlay)
- Show in NPC debug UI: "Pregnant: 45s remaining" (birth timer countdown)

**Baby Spawn Effect:**
- Spawn baby at land claim center (not woman's position)
- Baby appears with `baby.png` sprite (64x64 pixels)
- Baby immediately enters wander state within land claim

## File Structure

```
scripts/
├── npc/
│   ├── components/
│   │   └── reproduction_component.gd (NEW)
│   └── states/
│       └── reproduction_state.gd (NEW)
├── systems/
│   └── baby_pool_manager.gd (NEW)
└── config/
    └── reproduction_config.gd (NEW)
```

## Configuration

**New Config File: `reproduction_config.gd`**
```gdscript
extends Resource
class_name ReproductionConfig

@export var reproduction_range: float = 200.0  # Detection range for mates
@export var birth_timer_base: float = 90.0  # Fixed 90s for testing (variable later with traits)
@export var birth_cooldown: float = 20.0  # Seconds between births
@export var baby_pool_base_capacity: int = 3  # Base capacity from land claim
@export var living_hut_capacity_bonus: int = 5  # Per Living Hut
@export var baby_growth_time_testing: float = 60.0  # 1 minute to grow to clansman (testing)
@export var baby_growth_age_normal: int = 13  # Age when baby becomes clansman (normal)
@export var reproduction_range_check: bool = true  # Check if within land claim (no pixel distance needed)
@export var birth_cooldown: float = 20.0  # Seconds between births
@export var trait_inheritance_chance: float = 0.5  # 50% chance per trait
@export var max_traits_per_npc: int = 6
```

## Implementation Steps

1. **Add Random Names to Women NPCs**
   - Update women spawning to use random names
   - Use `NamingUtils.generate_caveman_name()` or create `generate_woman_name()` function
   - Apply names when women spawn (initial spawn and respawn)
   - All NPCs are human (no species differentiation needed)

2. **Create Reproduction Component**
   - Component structure and initialization
   - Mate detection logic (within land claim area)
   - Mate selection (based on traits and age - prefers clan leader)
   - Birth timer management (90s fixed for testing)
   - Birth cooldown system (20s between births)

3. **Create Reproduction State**
   - State entry conditions (woman, in claim, mate nearby)
   - State update logic (timer countdown)
   - Baby spawning on completion

4. **Create Baby Pool Manager**
   - Singleton or Main scene attachment
   - Capacity tracking per clan
   - Baby storage/retrieval

5. **Implement Baby System** (Trait inheritance disabled until traits implemented)
   - Baby spawning at land claim center
   - Baby NPC creation with `baby.png` sprite (64x64)
   - Baby wander state within land claim
   - Baby inventory (2 slots for food from land claim)
   - Baby age tracking and growth system (1 min testing / 13 years normal)
   - Baby to clansman promotion (automatic only)

6. **Integrate with FSM**
   - Register reproduction state
   - Set priority (8.0)
   - Add to state evaluation

7. **Add Visual Feedback**
   - Pregnancy indicator in NPC debug UI (no sprite tint)
   - Baby spawn effect at land claim center
   - Baby inventory UI (shows random name and age when clicked)

8. **Implement Clansmen System**
   - Baby growth timer (1 minute for testing)
   - Clansman spawn (uses caveman sprite)
   - Clansman FSM (gather, herd, deposit loop)
   - Clansman clan membership

9. **Testing**
   - Test reproduction with player (leader of clan)
   - Test reproduction with NPC cavemen
   - Test baby pool capacity (3 base + 5 per Living Hut)
   - Test baby wandering within land claim
   - Test baby inventory and food consumption
   - Test baby growth to clansman (1 min testing)
   - Test pregnancy cancellation when land claim destroyed

## Design Decisions Summary

### Reproduction Mechanics
- **Reproduction Range**: Within land claim area only (no specific pixel distance, just must be inside claim)
- **Mate Selection**: Based on traits and age - prefers clan leader (highest quality mates first)
- **Birth Timer**: Fixed 90 seconds for all women (testing phase). Will be variable based on traits/classes when implemented.
- **Birth Cooldown**: 20 seconds between births (prevents rapid succession)
- **Player Reproduction**: Yes, player can reproduce as clan leader
- **Pregnancy Cancellation**: If land claim is destroyed, pregnant women become wild NPCs and pregnancy is canceled (wild NPCs cannot be pregnant)

### Baby System
- **Baby Capacity**: 
  - Land claim provides +3 base capacity (no buildings needed for first 3 babies)
  - Each Living Hut adds +5 capacity
  - Formula: `capacity = 3 + (living_hut_count * 5)`
- **Baby Spawn**: At land claim center (not woman's position)
- **Baby Sprite**: `baby.png` (64x64 pixels)
- **Baby Behavior**: Active NPCs that wander within land claim area (not frozen in pool)
- **Baby Growth**: 
  - Testing: 1 minute to become clansman
  - Normal: At 13 years old (future implementation)
- **Baby Promotion**: Automatic only (no manual promotion)
- **Baby Inventory**: 2 slots for food (consumed from land claim inventory when hungry)
- **Baby UI**: Shows random name and age when clicked on
- **Surplus Babies**: Disabled for testing (babies grow automatically instead of instant promotion)

### Clansmen System
- **Clansman Sprite**: Uses same caveman sprite as NPC cavemen
- **Clansman Behavior**: Same FSM as NPC cavemen - gather, herd, deposit loop
- **Clansman Clan**: Belongs to same clan as parents

### UI Display
- **Clan Panel (Tab key)**: Shows all NPCs belonging to the clan (women, sheep, goats, babies, clansmen)
- **Pregnancy Display**: NPC debug UI shows "Pregnant: Xs remaining" (no sprite tint/overlay)
- **Baby Info**: Click baby to see inventory with name and age

### System Modularity
- **Future Expansion**: System designed to be modular - may add sheep and goat reproduction later
- **Wild NPC Restriction**: Wild NPCs cannot become pregnant (only clan members can reproduce)
- **Land Claim Dependency**: Women must be in clan and inside land claim to reproduce
- **Trait Inheritance**: Disabled until traits system is implemented (will use 50/50 hybridization)

### NPC Naming System
- **Women Names**: Women NPCs must have random names when spawned (currently use "Woman %d" format)
- **Name Generation**: Use `NamingUtils.generate_caveman_name()` or create similar function for women
- **All NPCs Human**: All NPCs are currently human - no species differentiation needed for naming
- **Name Application**: Apply random names when women spawn (initial spawn and respawn)

### Land Claim Destruction
- When land claim is destroyed:
  - All clan NPCs become wild NPCs (women, clansmen, etc.)
  - Pregnant women lose pregnancy (wild NPCs cannot be pregnant)
  - Babies become wild NPCs (or removed)