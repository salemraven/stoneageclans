# Draw Order Y-Sorting Implementation Plan

## Goal
Implement proper draw order based on vertical (Y) position so that:
- Objects lower on screen (higher Y value) appear in front
- Objects higher on screen (lower Y value) appear behind
- Works for: Player, NPCs, Buildings, Trees, Resources, and future Grass
- Creates natural depth effect when walking behind/in front of objects

## Current State (IMPLEMENTED)
- Y-sorting implemented via YSortUtils + WorldObjects y_sort_enabled
- Scene structure:
  - Main (Node2D)
    - **WorldLayer** (Node2D) - draws first, floor never covers entities
      - World (TileMap) - ground
    - **WorldObjects** (Node2D, y_sort_enabled=true) - entities sort by Y
      - Player, Resources, LandClaims, buildings, NPCs, ground items (added at runtime)
    - UI (CanvasLayer) - on top

## Implementation Strategy

### Option 1: Manual z_index Updates (RECOMMENDED)
**Pros:**
- Full control over sorting
- Works with existing scene structure
- Can handle sprite offsets correctly
- Easy to debug
- Good performance

**Cons:**
- Need to update in _process/_physics_process
- Must remember to apply to all sprites

### Option 2: YSort Node
**Pros:**
- Automatic sorting
- Built-in Godot feature

**Cons:**
- Requires restructuring scene tree
- Less control
- May conflict with existing z_index usage
- Doesn't handle sprite offsets well

## Chosen Approach: Manual z_index Updates

### Implementation Steps

#### Step 1: Create Y-Sorting Helper Utility (✅ DONE)
Create `scripts/systems/y_sort_utils.gd`:
- Static utility class with helper functions
- Centralized Y-sorting logic (one place to fix bugs)
- Base layer offsets to prevent z_index conflicts
- Accounts for sprite offset (sprite position relative to parent)
- Simple API: `YSortUtils.update_object_y_sort(sprite, self)`

#### Step 2: Apply to Player
- Add Y-sorting to `scripts/player.gd`
- Call `YSortUtils.update_object_y_sort(sprite, self)` in `_physics_process()`
- One line of code, guaranteed consistent with all other objects

#### Step 3: Apply to NPCs
- Add Y-sorting to `scripts/npc/npc_base.gd`
- Call `YSortUtils.update_object_y_sort(sprite, self)` in `_physics_process()`
- NPCs already have _physics_process, just add one line

#### Step 4: Apply to Buildings
- Add Y-sorting to `scripts/buildings/building_base.gd` and `land_claim.gd`
- Call `YSortUtils.update_building_draw_order(sprite, self)` in `_ready()`
- Uses tunable `building_sort_offset_y` (-80 default): negative = player stays in front longer

#### Step 5: Apply to Resources
- Add Y-sorting to `scripts/gatherable_resource.gd`
- Call `YSortUtils.update_object_y_sort(sprite, self)` in `_ready()` or `_process()`
- Resources are static, so update once in `_ready()` is sufficient

#### Step 6: Apply to Trees (when added)
- Same pattern as buildings/resources
- Static objects, update in `_process()`

#### Step 7: Apply to Grass (when added)
- If grass is TileMap, it's already sorted by tile position
- If grass is individual sprites, apply same pattern as resources

### Technical Details

#### z_index Calculation Formula (UPDATED - with base layers)
```gdscript
# Use YSortUtils helper function (recommended)
YSortUtils.update_object_y_sort(sprite, self)

# Or manually with base layer:
# Calculate sprite's global Y position (accounting for sprite offset)
var sprite_global_y: float = global_position.y + sprite.position.y

# Set z_index: base layer + Y position
# Higher Y = higher z_index (appears in front)
sprite.z_index = Z_OBJECT_BASE + int(sprite_global_y)
```

#### Z-Index Layer Bands
```gdscript
# scripts/systems/y_sort_utils.gd
const Z_BASE = 5000000        # Sprites stay above TileMap when Y is negative (north)
const Z_ABOVE_WORLD = 15000000  # Progress bars, lines, indicators
# Floor: WorldLayer draws first (tree order), always behind
```

#### Editable Values
| Variable | Default | Description |
|----------|---------|-------------|
| `building_sort_offset_y` | -80 | Negative = player stays in front longer; positive = goes behind sooner. Edit in y_sort_utils.gd or Project Settings > Autoload > YSortUtils. |

**Why base layers matter:**
- Prevents z_index conflicts with UI elements (already use z_index 5, 10, 15)
- Future-proofs for effects, decals, shadows, projectiles
- Clear separation between object types
- Easy to add new layers without breaking existing code

#### Optimization Considerations
1. **Update Frequency:**
   - Moving objects (Player, NPCs): Update every frame in `_physics_process()`
   - Static objects (Buildings, Resources): Update in `_ready()` or when position changes
   - Can use `_process()` with throttling for static objects

2. **Z-Index Range:**
   - Use int(global_position.y) directly
   - Godot z_index is int, so this works well
   - Typical Y range: 0-5000+ pixels, which fits in int range

3. **Sprite Offset Handling:**
   - Most sprites have offset (e.g., position = Vector2(0, -6))
   - Use sprite's global position, not parent's global position
   - Calculate: `sprite_global_y = parent.global_position.y + sprite.position.y`

4. **UI Elements:**
   - Keep UI elements in CanvasLayer (already on top)
   - UI z_index should be very high (1000+) to stay above everything
   - Current UI elements already use high z_index (5, 10, 15)

### Code Structure

#### Y-Sort Utility (✅ IMPLEMENTED)
```gdscript
# scripts/systems/y_sort_utils.gd
# Static utility class - no instantiation needed
# Just call: YSortUtils.update_object_y_sort(sprite, self)

# Benefits:
# - One place to fix bugs
# - Guaranteed consistent math everywhere
# - Base layer offsets prevent conflicts
# - Simple API: one line per object
```

**Usage Example:**
```gdscript
# In player.gd _physics_process():
YSortUtils.update_object_y_sort(sprite, self)

# In npc_base.gd _physics_process():
YSortUtils.update_object_y_sort(sprite, self)

# In building_base.gd and land_claim.gd _ready():
YSortUtils.update_building_draw_order(sprite, self)
```

### Files to Modify

1. **scripts/player.gd**
   - Add z_index update in `_physics_process()`

2. **scripts/npc/npc_base.gd**
   - Add z_index update in `_physics_process()`

3. **scripts/buildings/building_base.gd**
   - Add z_index update in `_ready()` or `_process()`

4. **scripts/gatherable_resource.gd**
   - Add z_index update in `_ready()` or `_process()`

5. **Future: scripts/trees/tree.gd** (when trees are added)
   - Same pattern as buildings

6. **Future: Grass handling** (when grass is added)
   - If TileMap: already sorted
   - If sprites: same pattern as resources

### Testing Checklist (manual verification)

**Run the game and verify:**

- [ ] **Player vs buildings:** Walk behind a building (player Y > building Y) → player should appear in front
- [ ] **Player vs buildings:** Walk in front of a building (player Y < building Y) → player should appear behind
- [ ] NPCs sort correctly relative to player
- [ ] NPCs sort correctly relative to buildings
- [ ] Buildings sort correctly relative to each other
- [ ] Resources sort correctly
- [ ] No z-fighting or flickering
- [ ] Performance is acceptable (no lag from z_index updates)
- [ ] UI elements still appear on top
- [ ] Works with sprite offsets (sprites positioned above/below node center)

### Edge Cases to Handle

1. **Identical Y Positions:**
   - Objects at same Y will have same z_index
   - This is acceptable - one will draw on top based on scene tree order
   - Can add small offset if needed: `z_index = int(global_position.y) + small_offset`

2. **Negative Y Positions:**
   - Should work fine, int() handles negatives
   - Test to ensure no issues

3. **Very Large Y Positions:**
   - int() can handle large values
   - Typical game Y range is fine

4. **Sprite Offsets:**
   - Must account for sprite.position.y offset
   - Most sprites have negative offset (sprite above node center)

5. **Moving vs Static Objects:**
   - Moving: update every frame
   - Static: update once in _ready() or when position changes

### Performance Notes

- Updating z_index is very cheap (just setting an int property)
- No need to optimize unless profiling shows issues
- Can throttle static object updates if needed (update every N frames)

### Future Enhancements

1. **Y-Sort Groups:**
   - Group objects that should sort together
   - Useful for complex multi-sprite objects

2. **Z-Index Layers:**
   - Different layers for different object types
   - E.g., ground layer (0-1000), object layer (1000-2000), character layer (2000-3000)
   - Prevents objects from sorting incorrectly across layers

3. **Sorting Precision:**
   - Currently uses int(global_position.y)
   - Could use higher precision if needed (multiply by 10, etc.)

## Implementation Order

1. ✅ Create plan (this document)
2. ✅ Create YSortUtils helper (scripts/systems/y_sort_utils.gd)
3. ✅ Implement player Y-sorting
4. ✅ Implement NPC Y-sorting
5. ✅ Implement building Y-sorting
6. ✅ Implement resource Y-sorting
7. ✅ Implement land claim Y-sorting
8. ✅ Implement ground item Y-sorting
9. ⬜ Test all combinations (player vs buildings, NPCs, resources, ground items)
10. ⬜ Apply to trees when added
11. ⬜ Apply to grass when added

## Key Improvements (Implemented)

✅ **WorldLayer**: Floor (TileMap) in separate layer, draws first, never covers entities

✅ **Building sort offset**: `building_sort_offset_y` (-80) – tunable, player stays in front until past building

✅ **z_as_relative=false**: Sprites sort across branches (player vs building in different parents)

✅ **Centralized YSortUtils**: `update_draw_order()` for entities, `update_building_draw_order()` for buildings/land claims
