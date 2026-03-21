# Level 1 Buildings System - Implementation Plan

## Overview
Level 1 buildings are functional structures that can be placed inside land claims. They have inventories, require materials to build, and some require assigned women to produce items. Buildings include: Living Hut, Farm, Storage Hut, Armory, and Tailor.

## Integration with Existing Framework

### 1. Building Base Class

**Base Building: `building_base.gd`**
- Location: `scripts/buildings/building_base.gd`
- Extends: `Node2D` (similar to `LandClaim`)
- Purpose: Common functionality for all buildings

**Base Structure:**
```gdscript
extends Node2D
class_name BuildingBase

@export var building_type: String = ""  # "living_hut", "farm", etc.
@export var clan_name: String = ""  # Which clan owns this building
@export var build_materials: Dictionary = {}  # Required materials
@export var build_time: float = 180.0  # Construction time
@export var is_built: bool = false  # Construction complete
@export var assigned_woman: NPCBase = null  # Assigned woman (if required)

var inventory: InventoryData = null
var production_component: Node = null  # For production buildings
var sprite: Sprite2D = null
```

**Common Functionality:**
- Inventory system (drag-and-drop)
- Construction state (unbuilt → building → built)
- Visual representation
- Click interaction (open inventory)
- Clan ownership

### 2. Building Placement System

**Placement Method:**
- Drag building item from inventory
- Drop on valid location (inside land claim, 256px from other buildings)
- Check materials in inventory
- Start construction if materials available

**Placement Validation:**
- Must be inside land claim radius
- Minimum 256px distance from other buildings/claims
- Must have required materials in inventory
- One building per position (no overlap)

**Integration with Main:**
- Add building placement handler to `main.gd`
- Similar to land claim placement
- Create building scene instance
- Remove building item from inventory

### 3. Building Inventory System

**Inventory Component:**
- All buildings have `InventoryData` (like LandClaim)
- Drag-and-drop enabled
- Materials placed in inventory for processing
- Outputs appear in inventory when ready

**Inventory Integration:**
- Use existing `BuildingInventoryUI` (already exists)
- Connect to building's inventory
- Display in UI when building clicked

### 4. Production System

**Production Component: `production_component.gd`**
- Location: `scripts/buildings/components/production_component.gd`
- Attached to: Production buildings (Farm, Armory, Tailor)
- Purpose: Process materials over time, create outputs

**Production Logic:**
- Check for required materials in inventory
- Check for assigned woman (if required)
- Process on timer (60s cycles)
- Create output items in inventory
- Remove consumed materials

**Production States:**
- **Idle**: No materials or no woman
- **Processing**: Materials + woman present, timer running
- **Complete**: Output ready in inventory

### 5. Building Assignment System

**Woman Assignment:**
- Auto-assignment: Women auto-assign to nearest unstaffed building
- Manual assignment: Drag-drop woman onto building
- One woman per building (no stacking)
- Assignment range: 500px from building

**Assignment Priority:**
- Farm > Armory > Tailor (closest first)
- Only unstaffed buildings
- Only women in same clan

**Assignment State:**
- New NPC state: `assign_to_building_state.gd`
- Priority: 7.0 (below reproduction, above gather)
- Moves woman to assigned building
- New NPC state: `work_at_building_state.gd`
- Priority: 6.5 (below assign, above gather)
- Woman works at building (idle animation, production enabled)

### 6. Individual Building Implementations

#### Living Hut
- **Script**: `scripts/buildings/living_hut.gd`
- **Materials**: 20 Wood, 10 Stone, 5 Hide
- **Build Time**: 180s
- **Function**: Increases baby pool capacity (+5)
- **Woman Required**: No
- **Production**: None

**Integration:**
- On build complete: Notify BabyPoolManager of capacity increase
- On destroy: Notify BabyPoolManager of capacity decrease

#### Farm
- **Script**: `scripts/buildings/farm.gd`
- **Materials**: 15 Wood, 5 Stone
- **Build Time**: 150s
- **Function**: Produces Wheat (1 per 60s) and Berries (1 per 120s)
- **Woman Required**: Yes (1 woman)
- **Production**: Yes (wheat/berries)

**Production Logic:**
- Wheat: Timer 60s, no input materials needed (grows naturally)
- Berries: Timer 120s, no input materials needed
- Outputs appear in building inventory

#### Storage Hut
- **Script**: `scripts/buildings/storage_hut.gd`
- **Materials**: 25 Wood, 10 Stone
- **Build Time**: 200s
- **Function**: Extra shared storage (20 stacks)
- **Woman Required**: No
- **Production**: None

**Storage Logic:**
- Larger inventory than other buildings (20 slots)
- Shared with clan (all NPCs can access)
- No production, just storage

#### Armory
- **Script**: `scripts/buildings/armory.gd`
- **Materials**: 20 Wood, 10 Stone
- **Build Time**: 180s
- **Function**: Produces Spear (1 per 120s) and Club (1 per 90s)
- **Woman Required**: Yes (1 woman)
- **Production**: Yes (weapons)

**Production Logic:**
- Spear: Requires 2 Wood + 1 Stone, 120s timer
- Club: Requires 1 Wood + 1 Stone, 90s timer
- Outputs appear in building inventory

#### Tailor
- **Script**: `scripts/buildings/tailor.gd`
- **Materials**: 20 Wood, 5 Stone, 5 Hide
- **Build Time**: 200s
- **Function**: Produces Thread (1 per 60s from Wool) and Hide Armor (1 per 180s from Thread + Hide)
- **Woman Required**: Yes (1 woman)
- **Production**: Yes (clothing/armor)

**Production Logic:**
- Thread: Requires 1 Wool, 60s timer
- Hide Armor: Requires 1 Thread + 2 Hide, 180s timer
- Outputs appear in building inventory

### 7. Building Scene Structure

**Scene Files:**
- `scenes/buildings/LivingHut.tscn`
- `scenes/buildings/Farm.tscn`
- `scenes/buildings/StorageHut.tscn`
- `scenes/buildings/Armory.tscn`
- `scenes/buildings/Tailor.tscn`

**Scene Structure:**
```
Building (Node2D)
├── Sprite (Sprite2D)
├── CollisionArea (Area2D)
│   └── CollisionShape (CollisionShape2D)
└── Script (building_type.gd)
```

### 8. FSM State Integration

**New States:**
- `assign_to_building_state.gd` - Woman moves to assigned building
  - Priority: 7.0
  - Entry: Woman assigned to building, not at building yet
  - Action: Move to building position
- `work_at_building_state.gd` - Woman works at building
  - Priority: 6.5
  - Entry: Woman at assigned building, building is built
  - Action: Idle animation, enable production

**FSM Registration:**
- Add to `fsm.gd` `_create_state_instances()`
- Register both states
- Set priorities

### 9. Building Item System

**Building Items:**
- Add building items to `ResourceData.ResourceType` enum:
  - `LIVING_HUT_ITEM`
  - `FARM_ITEM`
  - `STORAGE_HUT_ITEM`
  - `ARMORY_ITEM`
  - `TAILOR_ITEM`

**Item Usage:**
- Drag from inventory to place building
- Remove item from inventory on placement
- Check materials before placement

## File Structure

```
scripts/
├── buildings/
│   ├── building_base.gd (NEW)
│   ├── living_hut.gd (NEW)
│   ├── farm.gd (NEW)
│   ├── storage_hut.gd (NEW)
│   ├── armory.gd (NEW)
│   ├── tailor.gd (NEW)
│   └── components/
│       └── production_component.gd (NEW)
├── npc/
│   └── states/
│       ├── assign_to_building_state.gd (NEW)
│       └── work_at_building_state.gd (NEW)
└── config/
    └── building_config.gd (NEW)

scenes/
└── buildings/
    ├── LivingHut.tscn (NEW)
    ├── Farm.tscn (NEW)
    ├── StorageHut.tscn (NEW)
    ├── Armory.tscn (NEW)
    └── Tailor.tscn (NEW)
```

## Configuration

**New Config File: `building_config.gd`**
```gdscript
extends Resource
class_name BuildingConfig

@export var min_building_distance: float = 256.0  # Min distance between buildings
@export var assignment_range: float = 500.0  # Auto-assignment range
@export var production_cycle_time: float = 60.0  # Base production cycle
@export var build_snap_size: float = 64.0  # Snap to grid size
```

## Implementation Steps

1. **Create Building Base Class**
   - Common functionality (inventory, construction, visuals)
   - Base structure for all buildings

2. **Create Individual Building Scripts**
   - Living Hut (capacity bonus)
   - Farm (wheat/berries)
   - Storage Hut (extra storage)
   - Armory (weapons)
   - Tailor (clothing/armor)

3. **Create Production Component**
   - Material processing logic
   - Timer-based production
   - Output creation

4. **Create Building Placement System**
   - Drag-drop placement
   - Validation (position, materials)
   - Construction state management

5. **Create Assignment States**
   - Assign to building state
   - Work at building state
   - Auto-assignment logic

6. **Integrate with FSM**
   - Register new states
   - Set priorities
   - Add to state evaluation

7. **Create Building Scenes**
   - Scene files for each building
   - Sprites and collision

8. **Add Building Items**
   - Resource types for buildings
   - Item creation/usage

9. **Testing**
   - Test building placement
   - Test construction
   - Test production
   - Test woman assignment
   - Test inventory system

## Questions for Clarification

1. **Building Placement**: Should buildings be placed via:
   - Drag-drop from inventory (building item)?
   - Craft menu (select building, place)?
   - Both?

2. **Construction Time**: Should construction be:
   - Instant (materials consumed immediately)?
   - Timed (materials consumed, building appears after timer)?
   - Manual (NPCs must build it, like land claims)?

3. **Building Destruction**: Can buildings be destroyed?
   - By player (right-click menu)?
   - By enemies (raids)?
   - By decay (if not maintained)?
   - Not destroyable in Phase 2?

4. **Building Movement**: Can buildings be moved after placement?
   - Yes (pick up and move)?
   - No (permanent placement)?

5. **Production Timers**: Should production timers be:
   - Fixed (60s for all cycles)?
   - Variable (based on woman's traits/stats)?
   - Pausable (pause when woman leaves)?

6. **Material Consumption**: When production completes:
   - Consume materials immediately when timer starts?
   - Consume materials when output is created?
   - Consume materials gradually over time?

7. **Multiple Outputs**: For buildings with multiple outputs (Farm: wheat + berries):
   - Separate timers for each output?
   - Shared timer, alternate outputs?
   - Random output selection?

8. **Woman Assignment**: Should women:
   - Auto-assign immediately when building is built?
   - Auto-assign when idle (no other tasks)?
   - Only manual assignment (drag-drop)?

9. **Assignment Priority**: For auto-assignment, should priority be:
   - Closest building first?
   - Building type priority (Farm > Armory > Tailor)?
   - Both (type priority, then closest)?

10. **Building Inventory Size**: Should all buildings have same inventory size, or different?
    - Same size (e.g., 10 slots)?
    - Variable (Storage Hut larger, others smaller)?

11. **Production Without Woman**: Can production buildings produce without assigned woman?
    - No (woman required)?
    - Yes, but slower (50% speed)?
    - Yes, but different outputs?

12. **Building Sprites**: Do you have sprites for buildings, or should I use placeholders?
    - Use existing sprites (if available)?
    - Create placeholder sprites?
    - Use colored rectangles for now?

13. **Building Snap**: Should buildings snap to grid?
    - Yes (64px grid, like land claims)?
    - No (free placement)?
    - Optional (hold Shift for free placement)?

14. **Building Limits**: Should there be limits on building counts?
    - Unlimited buildings per clan?
    - Max buildings per land claim?
    - Max of each type per clan?

15. **Storage Hut Access**: Should Storage Hut be:
    - Shared inventory (all NPCs can access)?
    - Separate inventory (must manually transfer)?
    - Linked to land claim inventory?
