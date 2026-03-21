# Melee Combat System - Implementation Plan

## Overview
The melee combat system implements RimWorld/Dwarf Fortress-style auto-combat. NPCs automatically engage in melee when enemies are detected, with damage calculation based on stats, weapons, and armor. Combat is automatic with no direct unit control.

## Integration with Existing Framework

### 1. Combat Component

**Component: `combat_component.gd`**
- Location: `scripts/npc/components/combat_component.gd`
- Attached to: All NPCs (cavemen, women, predators)
- Purpose: Handles attack logic, damage calculation, combat state

**Component Structure:**
```gdscript
extends Node
class_name CombatComponent

var npc: NPCBase = null
var attack_range: float = 100.0
var attack_cooldown: float = 2.0
var last_attack_time: float = 0.0
var current_target: NPCBase = null
var base_damage: int = 10
```

**Integration:**
- Attach to NPCs in scene or via `npc_base.gd`
- Component updates in `_process()` or NPC update loop
- Checks for enemies, calculates damage, applies attacks

### 2. Health Component

**Component: `health_component.gd`**
- Location: `scripts/npc/components/health_component.gd`
- Attached to: All NPCs
- Purpose: Tracks HP, wounds, death

**Component Structure:**
```gdscript
extends Node
class_name HealthComponent

var npc: NPCBase = null
var max_hp: int = 100
var current_hp: int = 100
var wounds: Array[Dictionary] = []  # {type: String, severity: float, location: String}
var is_dead: bool = false
```

**Wound System:**
- Wounds reduce max HP temporarily
- Wounds heal over time at Medic Hut (if berries stocked)
- Multiple wounds can stack
- Death at 0 HP

### 3. Weapon Component

**Component: `weapon_component.gd`**
- Location: `scripts/npc/components/weapon_component.gd`
- Attached to: NPCs that can equip weapons
- Purpose: Tracks equipped weapon, damage bonuses

**Component Structure:**
```gdscript
extends Node
class_name WeaponComponent

var npc: NPCBase = null
var equipped_weapon: ResourceData.ResourceType = ResourceData.ResourceType.NONE
var weapon_damage_bonus: int = 0  # Spear +5, Club +3
```

**Weapon Types:**
- Spear: +5 damage bonus
- Club: +3 damage bonus
- Unarmed: 0 bonus

**Weapon Equipping:**
- NPCs can equip weapons from inventory
- Weapons from Armory can be equipped
- Auto-equip best weapon when available

### 4. Armor Component

**Component: `armor_component.gd`**
- Location: `scripts/npc/components/armor_component.gd`
- Attached to: NPCs that can equip armor
- Purpose: Tracks equipped armor, damage reduction

**Component Structure:**
```gdscript
extends Node
class_name ArmorComponent

var npc: NPCBase = null
var equipped_armor: ResourceData.ResourceType = ResourceData.ResourceType.NONE
var armor_reduction: int = 0  # Hide Armor -3 damage
```

**Armor Types:**
- Hide Armor: -3 damage reduction per hit
- No armor: 0 reduction

**Armor Equipping:**
- NPCs can equip armor from inventory
- Armor from Tailor can be equipped
- Auto-equip armor when available

### 5. Combat State

**State: `combat_state.gd`**
- Location: `scripts/npc/states/combat_state.gd`
- Extends: `base_state.gd`
- Priority: 12.0 (very high, overrides most states)

**State Logic:**
- Entry: Enemy detected within attack range (100px)
- Action: Move toward enemy, attack on cooldown
- Exit: Enemy dead, enemy out of range, or higher priority state

**Combat Behavior:**
- Move toward target until in range
- Attack when cooldown expires
- Continue until target dead or out of range
- Can switch targets if better target appears

### 6. Flee State

**State: `flee_state.gd`**
- Location: `scripts/npc/states/flee_state.gd`
- Extends: `base_state.gd`
- Priority: 11.5 (high, but below combat)

**State Logic:**
- Entry: Enemy detected, aggression < 30, low HP
- Action: Move away from enemy, run to safety
- Exit: Enemy out of range, or higher priority state

**Flee Behavior:**
- Move away from enemy
- Run to land claim (if in clan)
- Run to nearest ally (if available)
- Continue until safe

### 7. Damage Calculation

**Damage Formula:**
```gdscript
base_damage = 10
strength_bonus = (npc.stats.get_stat("Strength") / 10) * strength_damage_multiplier
weapon_bonus = weapon_component.weapon_damage_bonus
total_damage = base_damage + strength_bonus + weapon_bonus

armor_reduction = target.armor_component.armor_reduction
final_damage = max(1, total_damage - armor_reduction)  # Minimum 1 damage
```

**Damage Application:**
- Apply damage to target's health component
- Create wound if damage > threshold
- Check for death (HP <= 0)
- Emit death signal if dead

### 8. Enemy Detection

**Detection Logic:**
- Check for enemies within detection range (varies by NPC type)
- Filter by hostility (same clan = friendly, different clan = enemy)
- Predators attack all NPCs
- NPCs attack predators and enemy clan members

**Detection Range:**
- Normal NPCs: 300px
- Predators: 800px (longer range)
- Configurable per NPC type

### 9. Medic Hut Integration

**Healing System:**
- Hurt NPCs (wounded, low HP) auto-path to Medic Hut
- Medic Hut requires berries in inventory
- Wounds heal over time when at Medic Hut
- Healing rate: 1 HP per 10 seconds (configurable)

**Healing State:**
- New state: `heal_state.gd` (optional, or use seek state)
- Priority: 9.0 (below combat, above reproduction)
- Entry: Wounded, Medic Hut available, berries in hut
- Action: Move to Medic Hut, wait for healing

### 10. Death System

**Death Handling:**
- On death (HP <= 0): Set `is_dead = true`
- Emit `npc_died` signal
- Remove from FSM (no more state updates)
- Drop inventory items (as ground items)
- Remove from scene after delay (or immediately)

**Death Effects:**
- Drop loot (inventory items)
- Predators drop Hide and Bone
- Remove NPC from active lists
- Update clan statistics

## File Structure

```
scripts/
├── npc/
│   ├── components/
│   │   ├── combat_component.gd (NEW)
│   │   ├── health_component.gd (NEW)
│   │   ├── weapon_component.gd (NEW)
│   │   └── armor_component.gd (NEW)
│   └── states/
│       ├── combat_state.gd (NEW)
│       ├── flee_state.gd (NEW)
│       └── heal_state.gd (NEW - optional)
└── config/
    └── combat_config.gd (NEW)
```

## Configuration

**New Config File: `combat_config.gd`**
```gdscript
extends Resource
class_name CombatConfig

@export var melee_range: float = 100.0  # Attack range
@export var attack_cooldown: float = 2.0  # Seconds between attacks
@export var base_damage: int = 10  # Base HP damage
@export var strength_damage_multiplier: float = 0.1  # +1 damage per 10 Strength
@export var spear_damage_bonus: int = 5
@export var club_damage_bonus: int = 3
@export var hide_armor_reduction: int = 3
@export var base_hp: int = 100  # Base HP for NPCs
@export var flee_aggression_threshold: float = 30.0  # Flee if aggression < this
@export var flee_hp_threshold: float = 0.3  # Flee if HP < 30%
@export var detection_range_normal: float = 300.0  # Normal NPC detection
@export var detection_range_predator: float = 800.0  # Predator detection
@export var healing_rate: float = 0.1  # HP per second at Medic Hut
```

## Implementation Steps

1. **Create Combat Component**
   - Attack logic and cooldown
   - Target selection
   - Damage calculation

2. **Create Health Component**
   - HP tracking
   - Wound system
   - Death handling

3. **Create Weapon Component**
   - Weapon equipping
   - Damage bonuses
   - Auto-equip logic

4. **Create Armor Component**
   - Armor equipping
   - Damage reduction
   - Auto-equip logic

5. **Create Combat State**
   - Enemy detection
   - Movement toward target
   - Attack on cooldown

6. **Create Flee State**
   - Enemy detection
   - Movement away from target
   - Safety seeking

7. **Integrate with FSM**
   - Register combat and flee states
   - Set priorities (12.0, 11.5)
   - Add to state evaluation

8. **Damage System**
   - Damage calculation formula
   - Damage application
   - Wound creation

9. **Death System**
   - Death detection
   - Loot dropping
   - NPC removal

10. **Medic Hut Integration**
    - Healing logic
    - Auto-path to Medic Hut
    - Wound healing

11. **Testing**
    - Test combat between NPCs
    - Test weapon/armor effects
    - Test death and loot drops
    - Test flee behavior
    - Test healing

## Questions for Clarification

1. **Combat Range**: Should attack range be:
   - Fixed at 100px for all NPCs?
   - Variable based on weapon (spear longer range)?
   - Variable based on NPC size/traits?

2. **Attack Animation**: Should attacks have:
   - Visual animation (swing weapon, etc.)?
   - Just damage application (no animation)?
   - Simple sprite flash/effect?

3. **Combat Interruption**: Can combat be interrupted by:
   - Higher priority states (e.g., deposit)?
   - Player commands?
   - Other enemies (switch targets)?

4. **Multiple Targets**: Can NPCs fight multiple enemies simultaneously?
   - Yes (attack nearest each cooldown)?
   - No (focus one target until dead)?

5. **Flee Behavior**: Should NPCs flee:
   - Only when low HP?
   - Only when low aggression?
   - Both conditions required?
   - Never (always fight to death)?

6. **Weapon Durability**: Should weapons have durability?
   - Yes (break after X uses)?
   - No (infinite durability for Phase 2)?

7. **Auto-Equip**: Should NPCs auto-equip weapons/armor:
   - When available in inventory?
   - When entering combat?
   - Only manual equipping?

8. **Wound System**: Should wounds be:
   - Simple HP reduction (no detailed wounds)?
   - Detailed wounds (location, type, severity)?
   - Simplified for Phase 2 (just HP reduction)?

9. **Death Animation**: Should death have:
   - Animation (fall down, etc.)?
   - Immediate removal?
   - Delay before removal (for animation)?

10. **Loot Dropping**: When NPCs die, should they:
    - Drop all inventory items?
    - Drop only equipped items?
    - Drop random items?
    - Drop nothing (items lost)?

11. **Combat vs Other States**: Should combat override:
    - Herding (yes, combat priority 12.0 > herding 10.6)?
    - Gathering (yes)?
    - Reproduction (yes)?
    - Deposit (maybe, depends on priority)?

12. **Predator Combat**: Should predators:
    - Attack all NPCs (player, clansmen, women, animals)?
    - Only attack weak targets (low HP)?
    - Prefer certain targets (women > animals > men)?

13. **Healing System**: Should healing be:
    - Automatic at Medic Hut (if berries available)?
    - Manual (player must assign NPCs)?
    - Both?

14. **Combat Stats**: Should combat effectiveness be based on:
    - Strength stat only?
    - Multiple stats (Strength, Agility, Endurance)?
    - Traits (combat-related traits)?

15. **Combat Feedback**: Should combat show:
    - Damage numbers (floating text)?
    - HP bars above NPCs?
    - Just visual effects (hits, blood)?
    - Minimal (no UI, just animations)?
