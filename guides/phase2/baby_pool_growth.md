# Baby Pool & Growth System - Implementation Plan

## Overview
The baby pool system stores babies until they can be promoted to adult clansmen. Babies beyond capacity become instant clansmen. The system tracks capacity per clan and integrates with Living Huts for capacity increases.

## Integration with Existing Framework

### 1. Baby Pool Manager

**Manager Structure:**
- Location: `scripts/systems/baby_pool_manager.gd`
- Singleton or attached to Main scene
- Tracks baby pools per clan

**Data Structure:**
```gdscript
extends Node
class_name BabyPoolManager

var baby_pools: Dictionary = {}  # {clan_name: {babies: Array[Dictionary], capacity: int, max_capacity: int}}
```

**Baby Data Format:**
```gdscript
{
    "id": String,  # Unique baby ID
    "spawn_time": float,  # When baby was created
    "parent1": String,  # Parent 1 NPC name
    "parent2": String,  # Parent 2 NPC name
    "traits": Array[String],  # Inherited traits
    "stats": Dictionary,  # Base stats from parents
    "quality_tier": String,  # Inherited quality
    "position": Vector2  # Spawn position (for promotion)
}
```

### 2. Capacity System

**Base Capacity:**
- Starts at 3 for all clans
- No babies can be stored initially (all become instant clansmen)

**Living Hut Integration:**
- Query building system for Living Hut count per clan
- Each Living Hut adds +5 to max capacity
- Capacity updates when Living Huts are built/destroyed
- Capacity is per-clan (each clan has separate pool)

**Capacity Calculation:**
```gdscript
func get_max_capacity(clan_name: String) -> int:
    var base_capacity = 0
    var living_hut_count = get_living_hut_count(clan_name)
    return base_capacity + (living_hut_count * 5)
```

### 3. Baby Storage System

**Adding Babies:**
- When baby spawns from reproduction, check pool capacity
- If space available: Add to pool (frozen state)
- If pool full: Immediately promote to clansman

**Baby Pool Storage:**
- Babies stored as data (not active NPCs)
- No movement, no aging, no FSM
- Can be queried for display/statistics

**Promotion System:**
- Manual promotion: Player can promote babies from pool (optional UI)
- Automatic promotion: Surplus babies (beyond capacity) become instant clansmen
- Promotion creates adult NPC (age 13+) at stored position

### 4. Growth & Promotion

**Promotion Process:**
1. Retrieve baby data from pool
2. Create new NPC instance
3. Set age to 13+ (adult)
4. Apply inherited traits and stats
5. Spawn at stored position (or land claim center)
6. Initialize FSM (wander state)
7. Remove from baby pool

**Trait Application:**
- Apply all inherited traits to new NPC
- Set base stats from blended parent stats
- Set quality tier
- Set clan_name from parents

### 5. Integration with Reproduction System

**Baby Spawn Flow:**
1. Reproduction system spawns baby
2. Check baby pool capacity
3. If space: Add to pool, freeze baby
4. If full: Immediately promote to clansman

**Capacity Updates:**
- Listen for Living Hut build/destroy events
- Recalculate capacity when buildings change
- Handle surplus babies if capacity decreases

### 6. UI Integration

**Stats Panel Display:**
- Show baby pool status: "Babies: 3/10" (current/max)
- List baby count per clan
- Show promotion options (if manual promotion enabled)

**Clan Menu Display:**
- Baby pool section
- List of babies in pool (names, parents, traits)
- Promote button (if manual promotion enabled)

**Debug UI:**
- Show baby pool data for selected NPC/clan
- Display capacity calculations
- Show promotion history

### 7. Baby NPC Handling

**Baby NPC Creation:**
- Create NPC with `npc_type = "baby"`
- Age: 0 (frozen, doesn't age)
- Small sprite (50% scale)
- No FSM (or minimal idle state)
- No movement

**Baby vs Clansman:**
- Babies: Age 0, frozen, in pool
- Clansmen: Age 13+, active, full FSM

## File Structure

```
scripts/
├── systems/
│   └── baby_pool_manager.gd (NEW)
├── npc/
│   └── npc_base.gd (MODIFY - add baby promotion logic)
└── ui/
    └── baby_pool_ui.gd (NEW - optional UI)
```

## Configuration

**Config Values:**
```gdscript
# In reproduction_config.gd or separate baby_pool_config.gd
@export var baby_pool_base_capacity: int = 0
@export var living_hut_capacity_bonus: int = 5
@export var baby_promotion_age: int = 13  # Age when promoted
@export var enable_manual_promotion: bool = true  # Player can promote manually
```

## Implementation Steps

1. **Create Baby Pool Manager**
   - Singleton or Main scene attachment
   - Data structure for baby pools
   - Capacity tracking per clan

2. **Integrate with Living Hut System**
   - Query building system for Living Hut count
   - Calculate capacity per clan
   - Update capacity on build/destroy

3. **Baby Storage Logic**
   - Add baby to pool (if space)
   - Store baby data (traits, stats, parents)
   - Handle surplus babies (immediate promotion)

4. **Promotion System**
   - Create adult NPC from baby data
   - Apply traits and stats
   - Spawn at stored position
   - Remove from pool

5. **UI Integration**
   - Stats panel display
   - Clan menu display (optional)
   - Debug UI

6. **Testing**
   - Test capacity limits
   - Test promotion (automatic and manual)
   - Test capacity updates (Living Hut changes)
   - Test trait inheritance on promotion

## Questions for Clarification

1. **Baby Pool Storage**: Should babies be stored as:
   - Data only (Dictionary, no active NPCs)?
   - Active NPCs in frozen state (no movement/aging)?
   - Hybrid (data + minimal NPC for visuals)?

2. **Capacity Decrease**: If a Living Hut is destroyed and capacity decreases below current baby count:
   - Should surplus babies be immediately promoted?
   - Should babies be "evicted" in order (oldest first)?
   - Should capacity decrease be prevented if it would cause eviction?

3. **Manual Promotion**: Should players be able to manually promote babies from pool?
   - Always available?
   - Only when pool is full?
   - Never (automatic only)?

4. **Promotion Age**: When babies are promoted, what age should they become?
   - Fixed at 13 (matching player spawn age)?
   - Random between 13-18?
   - Based on parent ages?

5. **Baby Spawn Position**: When a baby is promoted, where should it spawn?
   - At original birth position (stored in baby data)?
   - At land claim center?
   - At nearest Living Hut?
   - At woman's current position (if still alive)?

6. **Baby Pool Display**: Where should baby pool information be shown?
   - Stats Panel (Tab key) only?
   - Clan Menu (C key) only?
   - Both?
   - Debug UI only?

7. **Baby Names**: Should babies have names?
   - Generated from parents' names?
   - Random names?
   - No names until promotion?

8. **Pool Limits**: Should there be a maximum total capacity (e.g., 50 babies per clan), or unlimited (only limited by Living Huts)?

9. **Baby Aging**: Should babies in pool age over time, or remain frozen at age 0?
   - Frozen (no aging) - simpler
   - Age slowly (e.g., 1 year per game day)
   - Age normally (but can't be promoted until 13)

10. **Surplus Handling**: When a baby spawns and pool is full:
    - Immediately promote to clansman?
    - Queue for promotion (wait for space)?
    - Reject baby (prevent spawn)?

11. **Multi-Clan Pools**: Each clan has separate baby pool - confirmed?
    - Yes, separate pools per clan
    - Shared global pool (unlikely)

12. **Baby Pool Persistence**: Should baby pools persist when:
    - Land claim is destroyed?
    - Clan is wiped?
    - Game is saved/loaded?

13. **Promotion Priority**: If multiple babies are queued for promotion:
    - First-in-first-out (oldest first)?
    - Random selection?
    - Based on quality/traits?

14. **Baby Visuals**: Should babies in pool be visible in the world?
    - Yes, as small frozen NPCs at spawn location
    - No, only stored as data
    - Optional (toggle in settings)
