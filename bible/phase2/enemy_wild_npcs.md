# Enemy Wild NPCs (Predators) - Implementation Plan

## Overview
Enemy wild NPCs are hostile predators (wolves, etc.) that spawn in the wilderness and attack NPCs. They provide combat challenges and drop loot (Hide, Bone) when killed. This system introduces danger to the world and creates conflict.

## Integration with Existing Framework

### 1. Predator NPC Type

**New NPC Type: `predator_npc.gd`**
- Location: `scripts/npc/predator_npc.gd`
- Extends: `NPCBase`
- Purpose: Hostile predator behavior

**Predator Properties:**
```gdscript
extends NPCBase
class_name PredatorNPC

@export var predator_type: String = "dire_wolf"  # "dire_wolf", "bear", "mammoth"
@export var base_damage: int = 15
@export var base_hp: int = 50
@export var detection_range: float = 800.0  # Longer than normal NPCs
@export var speed_multiplier: float = 1.2  # 20% faster
```

**NPC Type Distinction:**
- `npc_type = "predator"` (distinct from "animal", "human", "caveman")
- Predators are always hostile
- Predators attack all NPCs (player, clansmen, women, animals)

### 2. Predator Spawning System

**Spawn Manager: `predator_spawn_manager.gd`**
- Location: `scripts/systems/predator_spawn_manager.gd`
- Singleton or attached to Main scene
- Purpose: Spawns predators in wilderness

**Spawn Logic:**
- Spawn rate: 1 predator per 5000px² area (configurable)
- Spawn only in wilderness (outside land claims)
- Spawn at random positions
- Limit total predators (e.g., max 10 active)

**Spawn Types:**
- Dire Wolf: Fast, moderate damage, common
- Bear: Slow, high damage, rare (future)
- Mammoth: Very slow, very high damage, very rare (future)

### 3. Hunt State

**State: `hunt_state.gd`**
- Location: `scripts/npc/states/hunt_state.gd`
- Extends: `base_state.gd`
- Priority: 13.0 (very high, overrides most states)

**State Logic:**
- Entry: Prey detected within detection range (800px)
- Action: Move toward prey, attack when in range
- Exit: Prey dead, prey out of range, or higher priority state

**Hunt Behavior:**
- Detect prey (all NPCs are potential prey)
- Prioritize weak targets (low HP, unarmed)
- Move toward target
- Attack when in range (100px)
- Continue until target dead

### 4. Predator Wander State

**State: `predator_wander_state.gd`**
- Location: `scripts/npc/states/predator_wander_state.gd`
- Extends: `base_state.gd` (or reuse `wander_state.gd`)
- Priority: 1.0 (low, default state)

**State Logic:**
- Entry: No prey detected
- Action: Wander randomly in wilderness
- Exit: Prey detected (enter hunt state)

**Wander Behavior:**
- Similar to normal wander state
- Stay in wilderness (avoid land claims)
- Move randomly
- Search for prey

### 5. Loot System

**Loot on Death:**
- Predators drop loot when killed
- Drop amounts: 2-4 Hide, 1-2 Bone (random)
- Loot appears as ground items (can be gathered)

**Loot Implementation:**
- On death: Create ground items at predator position
- Use existing `GroundItem` system
- Randomize drop amounts
- Items can be gathered by NPCs/player

### 6. Hostility System

**Hostility Rules:**
- Predators attack all NPCs (no exceptions)
- Predators don't attack other predators (same type)
- NPCs attack predators (defensive)
- Player can attack predators

**Detection:**
- Predators have longer detection range (800px vs 300px)
- Predators prioritize weak targets
- Predators can switch targets if better prey appears

### 7. Integration with Combat System

**Combat Integration:**
- Predators use same combat system (combat_component, health_component)
- Predators have combat state (or hunt state handles combat)
- Predators take damage from NPCs/player
- Predators die and drop loot

**Combat Stats:**
- Dire Wolf: 50 HP, 15 damage, 1.2x speed
- Higher stats than normal NPCs
- Can be balanced via config

### 8. Respawn System

**Respawn Logic:**
- Predators respawn after death
- Respawn timer: 60 seconds (configurable)
- Respawn in wilderness (outside land claims)
- Limit total active predators

**Respawn Manager:**
- Track dead predators
- Respawn after timer expires
- Maintain predator population

## File Structure

```
scripts/
├── npc/
│   ├── predator_npc.gd (NEW)
│   └── states/
│       ├── hunt_state.gd (NEW)
│       └── predator_wander_state.gd (NEW)
├── systems/
│   └── predator_spawn_manager.gd (NEW)
└── config/
    └── predator_config.gd (NEW)
```

## Configuration

**New Config File: `predator_config.gd`**
```gdscript
extends Resource
class_name PredatorConfig

@export var spawn_rate: float = 0.0002  # Per pixel² (1 per 5000px²)
@export var max_active_predators: int = 10  # Max predators at once
@export var respawn_timer: float = 60.0  # Seconds before respawn
@export var detection_range: float = 800.0  # Detection range
@export var dire_wolf_damage: int = 15  # Base damage
@export var dire_wolf_hp: int = 50  # Base HP
@export var dire_wolf_speed_multiplier: float = 1.2  # Speed bonus
@export var hide_drop_min: int = 2  # Min Hide drops
@export var hide_drop_max: int = 4  # Max Hide drops
@export var bone_drop_min: int = 1  # Min Bone drops
@export var bone_drop_max: int = 2  # Max Bone drops
```

## Implementation Steps

1. **Create Predator NPC Class**
   - Extend NPCBase
   - Add predator-specific properties
   - Set npc_type = "predator"

2. **Create Hunt State**
   - Prey detection
   - Movement toward target
   - Attack logic

3. **Create Predator Wander State**
   - Wilderness wandering
   - Prey searching
   - Avoid land claims

4. **Create Spawn Manager**
   - Spawn logic (rate, position)
   - Wilderness detection
   - Population limits

5. **Integrate with FSM**
   - Register hunt and wander states
   - Set priorities (13.0, 1.0)
   - Add to state evaluation

6. **Loot System**
   - Drop loot on death
   - Randomize drop amounts
   - Create ground items

7. **Respawn System**
   - Track dead predators
   - Respawn after timer
   - Maintain population

8. **Testing**
   - Test predator spawning
   - Test hunt behavior
   - Test combat with NPCs
   - Test loot drops
   - Test respawn

## Questions for Clarification

1. **Predator Types**: For Phase 2, should we implement:
   - Only Dire Wolf?
   - Multiple types (Dire Wolf + Bear)?
   - Just Dire Wolf, others later?

2. **Spawn Rate**: Should spawn rate be:
   - Fixed (1 per 5000px²)?
   - Variable (more predators in certain areas)?
   - Time-based (more predators at night)?

3. **Spawn Location**: Should predators spawn:
   - Only in wilderness (outside land claims)?
   - Anywhere (including near land claims)?
   - Far from land claims (safe zones)?

4. **Predator Behavior**: Should predators:
   - Always hunt (aggressive)?
   - Only hunt when hungry (need food)?
   - Avoid strong targets (flee if outnumbered)?

5. **Target Priority**: Should predators prioritize:
   - Weakest targets (low HP)?
   - Closest targets?
   - Specific types (women > animals > men)?
   - Random selection?

6. **Predator Groups**: Should predators:
   - Spawn alone (solo)?
   - Spawn in packs (2-3 wolves)?
   - Both (solo and packs)?

7. **Combat Difficulty**: Should predators be:
   - Stronger than NPCs (challenging)?
   - Equal strength (balanced)?
   - Weaker (easy to kill)?

8. **Loot Drops**: Should loot be:
   - Guaranteed (always drop Hide/Bone)?
   - Chance-based (X% chance to drop)?
   - Variable amounts (random 2-4 Hide)?

9. **Respawn Behavior**: Should predators:
   - Respawn after death (infinite)?
   - Limited respawns (max X per area)?
   - No respawn (finite population)?

10. **Predator AI**: Should predators:
    - Use same FSM as NPCs (hunt/wander)?
    - Custom AI (more complex behavior)?
    - Simple (just attack nearest)?

11. **Predator Sprites**: Do you have sprites for predators, or should I use placeholders?
    - Use existing sprites (if available)?
    - Create placeholder sprites?
    - Use colored rectangles for now?

12. **Predator Size**: Should predators be:
    - Same size as NPCs?
    - Larger (more intimidating)?
    - Variable (Dire Wolf normal, Bear larger)?

13. **Predator Sounds**: Should predators have:
    - Sound effects (growls, howls)?
    - No sounds (Phase 2)?
    - Optional (can be added later)?

14. **Predator Attacks on Herded NPCs**: If a predator attacks a herded NPC:
    - Should the herd break (NPC flees)?
    - Should the herder defend (attack predator)?
    - Should the herd continue (ignore predator)?

15. **Predator Territory**: Should predators:
    - Wander freely (no territory)?
    - Have territories (stay in area)?
    - Migrate (move between areas)?

16. **Predator vs Player**: Should predators:
    - Attack player immediately (same as NPCs)?
    - Avoid player (unless provoked)?
    - Attack player only if player attacks first?

17. **Predator Population**: Should there be:
    - Unlimited predators (spawn continuously)?
    - Limited predators (max 10 active)?
    - Dynamic (more predators if fewer NPCs)?

18. **Predator Difficulty Scaling**: Should predator difficulty:
    - Stay constant (same stats always)?
    - Scale with time (stronger over time)?
    - Scale with clan size (more predators if larger clan)?
