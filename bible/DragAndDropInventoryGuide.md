# Drag & Drop & Inventory Guide

## Overview

The drag-and-drop inventory system is the core interaction mechanic in Stone Age Clans. **Everything is drag-and-drop** - you can seamlessly drag items between inventories, from inventories to the game world, and from the world to inventories. The system is designed to be intuitive, responsive, and visually clear.

**Core Principle**: Drag-and-drop absolutely everything (player ↔ flag ↔ buildings ↔ clansmen ↔ ground)

## Perfect System Vision

### Seamless Drag & Drop
- **Drag from anywhere**: Player inventory, building inventory, cart inventory, NPC inventory (view-only), ground items
- **Drop to anywhere**: Any inventory slot, ground (spawns item entity), building placement (drag building icon to map)
- **Visual feedback**: Clear hover states, valid/invalid drop indicators, smooth animations
- **No restrictions**: Items flow freely between all inventories (except NPC inventories are read-only)

### Intuitive UI
- **64x64 grid slots**: All inventory slots are uniform 64x64 pixels (square, grid layout)
- **Item info on hover**: Show item name, description, stats, quality when hovering (1 second delay)
- **Visual clarity**: Quality borders, count labels, clear icons
- **Responsive panels**: ⚠️ Draggable inventory panels (NOT YET IMPLEMENTED - currently fixed positions, max 3 open simultaneously)
- **Fixed hotbar**: Always visible at bottom, 10 slots (32x32 each)

### Building Placement
- **Drag building icon**: From inventory to world map
- **Visual scaling**: Icon scales up (32px → 64px+) when over world
- **Placement preview**: Shows valid/invalid placement zones
- **Auto-consume**: Resources consumed from inventory when building placed

## Inventory Types

### Player Inventory
- **Slots**: 10 slots (64x64 grid)
- **Stacking**: No stacking (1 item per slot)
- **Hotbar**: 10 slots (32x32, always visible at bottom)
- **Hotbar Restrictions**:
  - Slot 1: Hand object (tool or melee weapon)
  - Slot 2: Ranged weapon
  - Slot 3: Head armor/hat
  - Slot 4: Body armor/clothing
  - Slot 5: Leg/feet armor
  - Slot 6: Consumable (food/healing)
  - Slot 7: Special item (amulet)
  - Slots 8-10: Additional equipment
- **Position**: Center of screen (fixed position, draggable NOT YET IMPLEMENTED)
- **Toggle**: Press **I** to open/close

### Building Inventory
- **Slots**: 6 slots (64x64 grid, 3x2 layout)
- **Stacking**: Yes (up to 10 per slot)
- **Position**: Left of player inventory (fixed position, draggable NOT YET IMPLEMENTED)
- **Auto-show**: When near building + press **I**
- **Auto-close**: When player moves away from building
- **Limit**: Only 1 building inventory open at a time

### Cart/Backpack Inventory
- **Slots**: 10 slots (64x64 grid)
- **Stacking**: Yes (up to 10 per slot)
- **Position**: Right of player inventory (fixed position, draggable NOT YET IMPLEMENTED)
- **Auto-show**: When cart/backpack equipped
- **Auto-close**: When cart/backpack unequipped
- **Shared position**: Cart and backpack share same position

### NPC Inventory (View-Only)
- **Slots**: 10 slots (64x64 grid)
- **Stacking**: No stacking (1 item per slot)
- **Position**: Near NPC (follows NPC position)
- **Interaction**: **Read-only** - cannot drag items in or out
- **Toggle**: Left-click NPC to view, stays open until closed manually
- **Close**: X button on title bar

### Land Claim Inventory
- **Slots**: 6 slots (64x64 grid, 3x2 layout)
- **Stacking**: Yes (up to 10 per slot)
- **Position**: Near land claim (fixed position, draggable NOT YET IMPLEMENTED)
- **Toggle**: Press **I** when near land claim

## Drag & Drop Mechanics

### Drag Start
1. **Left-click and hold** on any item in any inventory
2. **Drag preview** appears (32x32 icon, 80% opacity)
3. **Source slot** is cleared (or reduced by 1 if stacked)
4. **Item follows mouse** smoothly

### Drag Process
- **Mouse movement**: Preview follows cursor
- **Hover feedback**: Valid drop targets show green glow, invalid show red X
- **Building icons**: Scale up (64px+) when over world map
- **World detection**: System detects if mouse is over world vs UI

### Drop Targets

#### 1. Inventory Slots
- **Same inventory**: Swap items or move to empty slot
- **Different inventory**: Transfer between inventories
- **Stacking**: Auto-merge if same item type and stacking enabled
- **Partial stacks**: Drag 1 item from stack, remaining stays in source

#### 2. Ground/World
- **Regular items**: Spawns as 64x64 ground item entity
- **Building icons**: Places building on map (if valid position)
- **Invalid drop**: Item snaps back to source with red flash

#### 3. Building Placement
- **Land Claim**: Can be placed anywhere on map
- **Other Buildings**: Must be inside existing land claim radius
- **Visual feedback**: Green ghost preview (valid), red ghost preview (invalid)
- **Auto-consume**: Resources removed from inventory on placement

### Drop Validation

#### Valid Drops
- ✅ Empty slot
- ✅ Same item type (for stacking)
- ✅ Different item type (swap)
- ✅ Ground (spawns item entity)
- ✅ World (for building placement)

#### Invalid Drops
- ❌ NPC inventory (read-only)
- ❌ Same slot (no-op)
- ❌ Hotbar slot with wrong item type (shows red X)
- ❌ Building outside land claim (for non-land-claim buildings)
- ❌ Overlapping existing building

### Stacking Rules

#### Player Inventory
- **No stacking**: 1 item per slot
- **Reason**: Encourages strategic inventory management

#### Building/Cart Inventories
- **Stacking enabled**: Up to 10 items per slot
- **Auto-merge**: Same item type automatically stacks
- **Partial drag**: Dragging from stack only moves 1 item

#### Stacking Algorithm
```
If target slot is empty:
  → Place item in slot

If target slot has same item type:
  → Calculate total count
  → If total <= max_stack (10):
    → Full merge (combine stacks)
  → Else:
    → Partial merge (fill target to max, keep remainder in source)

If target slot has different item type:
  → Swap items
```

## Visual Design

### Slot Design
- **Size**: 64x64 pixels (uniform across all inventories)
- **Layout**: Grid layout (not list)
- **Icon**: 32x32 pixels, centered in slot
- **Count label**: Top-right corner (12px font, white)
- **Quality border**: 2px overlay on icon
- **Background**: `#3c2723` (earthy brown) at 95% opacity
- **Border**: `#8b4513` (saddle brown) at 100% opacity, 2px width

### Panel Design
- **Background**: `#1a1512` at 85% opacity
- **Border**: `#8b4513` at 90% opacity, 2px width
- **Corner radius**: 12px
- **Shadow**: Black at 25% opacity, 4px size, offset (0, 5px)
- **Title bar**: ⚠️ Draggable (NOT YET IMPLEMENTED), shows inventory name, X button to close

### Quality Borders
- **Flawed**: `#808080` (grey)
- **Common**: `#ffffff` (white)
- **Good**: `#3366ff` (blue)
- **Fine**: `#6699ff` (light blue)
- **Master**: `#b366ff` (light purple)
- **Legendary**: `#cc33ff` (purple) with pulse animation

### Hover Tooltips
- **Delay**: 1 second hover before showing
- **Content**: Item name, description, stats, quality tier
- **Style**: RimWorld-inspired, earthy tones
- **Position**: Near cursor, doesn't block view

### Drag Preview
- **Size**: 32x32 pixels (UI), scales to 64px+ (world)
- **Opacity**: 80% (UI), 90% (world)
- **Filter**: NEAREST (pixel-perfect)
- **Position**: Centered on mouse cursor
- **Follow**: Smooth, no lag

### Visual Feedback

#### Hover States
- **Valid drop**: Green glow (2px, `#00ff00` at 30% opacity)
- **Invalid drop**: Red X overlay on slot
- **Empty slot**: Subtle border highlight

#### Drop Feedback
- **Valid drop**: Green flash (0.2s)
- **Invalid drop**: Red flash (0.2s) + snap back animation
- **Stack merge**: Subtle scale pulse (1.0 → 1.1 → 1.0, 0.3s)
- **Swap**: Fade out/in (0.2s each)

#### Snap Back Animation
- **Red flash**: Slot flashes red (0.1s)
- **Shake effect**: Slot shakes left-right (0.15s)
- **Return**: Item returns to source slot smoothly

## Panel Management

### Panel Limits
- **Maximum open**: 3 inventory panels simultaneously
- **Types**: Player, Building, Cart/Backpack, Land Claim, NPC (view-only)
- **Z-ordering**: Most recently opened panel on top
- **Click to front**: Clicking panel title bar brings it to front

### Panel Positioning
- **Draggable**: ⚠️ **NOT YET IMPLEMENTED** - Planned feature, panels currently fixed position
- **No overlap**: ⚠️ **NOT YET IMPLEMENTED** - Planned feature, will prevent overlap when draggable
- **No off-screen**: ⚠️ **NOT YET IMPLEMENTED** - Planned feature, will clamp to bounds when draggable
- **Position persistence**: ⚠️ **NOT YET IMPLEMENTED** - Planned feature, will save positions per save file
- **Reset on resolution change**: Positions reset if off-screen after resolution change (when implemented)

### Panel Closing
- **I key**: Closes ALL inventory panels
- **X button**: Closes individual panel (on title bar)
- **Auto-close**: Building inventory closes when player moves away

### Default Positions (Current Implementation)
- **Player**: Center of screen (fixed)
- **Building**: Left of player inventory (fixed)
- **Cart**: Right of player inventory (fixed)
- **Land Claim**: Near land claim position (fixed)
- **NPC**: Near NPC position (follows NPC, fixed)

**Note**: Panels are currently fixed in position. Draggable panels and position persistence are planned features not yet implemented.

## Building Placement System

### How It Works
1. **Drag building icon** from inventory (e.g., LANDCLAIM, FARM, etc.)
2. **Icon scales up** when mouse moves over world map (32px → 64px+)
3. **Visual preview** shows placement location
4. **Release mouse** over valid position
5. **Building placed** and resources consumed

### Placement Rules

#### Land Claim Buildings
- **Can place**: Anywhere on map
- **Creates**: New land claim at placement location
- **No restrictions**: No land claim radius check needed

#### Other Buildings (Farm, Spinner, Bakery, etc.)
- **Must place**: Inside existing land claim radius (400px)
- **Validation**: Check if mouse position is within any land claim
- **Invalid**: Red flash + error message if outside land claim

### Visual Feedback During Placement
- **Valid position**: Green ghost preview at placement location
- **Invalid position**: Red ghost preview with X overlay
- **Inside land claim**: Blue outline on land claim radius
- **Outside land claim**: Red warning text "Must be inside land claim"

### Placement Flow
```
User drags building icon
  ↓
DragManager detects building type
  ↓
Preview scales up when over world (64px+)
  ↓
User releases mouse over world
  ↓
Check if position is valid:
  - If land claim: Always valid
  - If other building: Check if inside land claim radius
  ↓
If valid:
  - Place building on map
  - Remove building icon from inventory
  - Consume resources if needed
  - Emit building_placed signal
  ↓
If invalid:
  - Show error feedback (red flash)
  - Cancel drag (return to source slot)
```

## World Drops

### Dropping Items to Ground
- **Action**: Drag item from inventory and release over world (not over UI)
- **Result**: Spawns 64x64 ground item entity at mouse position
- **Entity**: Can be picked up by player or NPCs
- **Visual**: Item appears on ground with slight bounce animation

### Picking Up Ground Items
- **Action**: Walk over ground item or drag from world to inventory
- **Result**: Item added to inventory (if space available)
- **Auto-pickup**: Can be implemented for items within pickup range

## Cross-Inventory Drag & Drop

### Detection Order
1. Check own slots first
2. Check other visible inventory slots
3. Check building placement (if dragging building icon)
4. Check world drop (if applicable)
5. Cancel drag if no valid target (only if not building icon)

### Implementation Pattern
```gdscript
func _input(event: InputEvent) -> void:
    if event is InputEventMouseButton and not event.pressed:
        if drag_manager.is_dragging:
            var mouse_pos = get_viewport().get_mouse_position()
            var dragged_item = drag_manager.dragged_item
            
            # Check own slots
            for slot in slots:
                if slot.get_global_rect().has_point(mouse_pos):
                    _handle_drop(slot)
                    return
            
            # Check other inventories
            if _check_other_inventories(mouse_pos):
                return
            
            # Check building placement (special case - doesn't cancel)
            if ResourceData.is_placeable_building(dragged_item.get("type", -1)):
                if _is_over_world(mouse_pos):
                    if _handle_building_placement(mouse_pos, dragged_item):
                        drag_manager.complete_drop(null)  # Building placed, no slot
                        return
            
            # Check world drop
            if _is_over_world(mouse_pos):
                _handle_world_drop()
                return
            
            # Cancel drag (only for non-building items)
            drag_manager.cancel_drag()
```

## Technical Implementation

### Core Components

#### DragManager (Singleton)
**Location**: `scripts/inventory/drag_manager.gd`

**Responsibilities**:
- Track current drag operation
- Manage drag preview sprite
- Handle drag start/end/completion
- Detect world vs UI drops
- Scale preview for building placement

**Key Properties**:
```gdscript
var is_dragging: bool = false
var dragged_item: Dictionary = {}
var from_slot: InventorySlot = null
var drag_preview: Control = null
var is_over_world: bool = false
```

**Key Methods**:
- `start_drag(slot: InventorySlot) -> void`
- `end_drag() -> void`
- `complete_drop(to_slot: InventorySlot) -> void`
- `cancel_drag() -> void`

**Signals**:
- `drag_started(item_data: Dictionary, from_slot: InventorySlot)`
- `drag_ended()`
- `drop_completed(item_data: Dictionary, to_slot: InventorySlot)`

#### InventoryUI (Base Class)
**Location**: `scripts/inventory/inventory_ui.gd`

**Responsibilities**:
- Base class for all inventory UIs
- Handle slot creation and layout
- Coordinate drag-and-drop within inventory
- Connect to drag manager signals

**Key Properties**:
```gdscript
var inventory_data: InventoryData
var slots: Array[InventorySlot]
var drag_manager: DragManager
var is_visible: bool
```

**Key Methods**:
- `setup(inventory_data: InventoryData) -> void`
- `show() -> void`
- `hide() -> void`
- `refresh() -> void`
- `_handle_drop(target_slot: InventorySlot) -> void`

#### InventorySlot (Component)
**Location**: `scripts/inventory/inventory_slot.gd`

**Responsibilities**:
- Display single slot content
- Handle mouse input (click, hover)
- Emit drag signals
- Show visual feedback

**Key Properties**:
```gdscript
var slot_index: int
var item_data: Dictionary
var is_hotbar: bool
var can_stack: bool
```

**Signals**:
- `slot_clicked(slot: InventorySlot)`
- `slot_hovered(slot: InventorySlot, is_hovering: bool)`

#### InventoryData (Data Model)
**Location**: `scripts/inventory/inventory_data.gd`

**Responsibilities**:
- Store inventory data (slots, items)
- Handle stacking logic
- Emit change signals

**Key Properties**:
```gdscript
var slot_count: int
var can_stack: bool
var max_stack: int
var slots: Array[Dictionary]
```

### Drag & Drop Flow

#### Phase 1: Drag Start
```
User clicks and holds slot
  ↓
InventorySlot._on_gui_input() detects click
  ↓
Emits slot_clicked signal
  ↓
InventoryUI._on_slot_clicked() receives signal
  ↓
DragManager.start_drag(slot) called
  ↓
Drag preview created and follows mouse
  ↓
drag_started signal emitted
```

#### Phase 2: Drag Process
```
Mouse moves while button held
  ↓
DragManager._process() updates drag preview position
  ↓
Checks if mouse is over world or UI
  ↓
Updates preview size (32px for UI, larger for world)
  ↓
Checks for hover targets (slots highlight)
```

#### Phase 3: Drag End
```
User releases mouse button
  ↓
InventoryUI._input() detects mouse release globally
  ↓
Checks all inventories for slot under mouse
  ↓
If over valid slot: _handle_drop() processes drop
  ↓
If over world: Handle world drop or building placement
  ↓
If over nothing: Cancel drag (return to source)
```

#### Phase 4: Drop Handling
```
_handle_drop(target_slot) called
  ↓
Validate drop (same slot? invalid target?)
  ↓
Check stacking rules
  ↓
If stackable and same type:
  - Calculate stack space
  - Merge items (full or partial)
  - Update both inventories
  ↓
If not stackable:
  - Swap items
  - Update both inventories
  ↓
Update UI displays
  ↓
Emit item_dropped signal
  ↓
DragManager.complete_drop() called
```

## Special Cases

### NPC Inventory (Read-Only)
- **Cannot drag from**: Items in NPC inventory cannot be dragged
- **Cannot drag to**: Items cannot be dropped into NPC inventory
- **Purpose**: View-only for inspecting NPC equipment/resources
- **Visual**: No hover feedback for drag operations

### Hotbar Restrictions
- **Slot-specific**: Each hotbar slot has specific item type restrictions
- **Visual feedback**: Red X overlay when dragging invalid item type
- **Validation**: Check item type before allowing drop

### Building Icon Special Behavior
- **Outside inventory release**: Building icons attempt placement (don't cancel)
- **Normal items**: Releasing outside inventory cancels drag
- **Placement priority**: Building placement checked before cancel

## Error Handling

### Invalid Drop Scenarios
1. **Same slot**: Ignore drop, no feedback
2. **Invalid target**: Red flash, snap back to source
3. **Full inventory**: Red flash, snap back to source
4. **Type restriction**: Red flash, snap back to source (hotbar only)
5. **Stack limit**: Partial stack if possible, otherwise swap
6. **Building placement invalid**: Red flash + error message, snap back to source
   - Outside land claim (for non-land-claim buildings)
   - Overlapping existing building
   - Invalid terrain
   - Insufficient resources

### Snap Back Animation
```gdscript
func _snap_back(slot: InventorySlot) -> void:
    var tween = create_tween()
    tween.set_parallel(true)
    
    # Flash red
    tween.tween_property(slot, "modulate", Color.RED, 0.1)
    tween.tween_property(slot, "modulate", Color.WHITE, 0.1).set_delay(0.1)
    
    # Shake effect
    var original_pos = slot.position
    tween.tween_property(slot, "position", original_pos + Vector2(-2, 0), 0.05)
    tween.tween_property(slot, "position", original_pos + Vector2(2, 0), 0.05).set_delay(0.05)
    tween.tween_property(slot, "position", original_pos, 0.05).set_delay(0.1)
```

## Performance Optimization

### Best Practices
- **Throttle updates**: Only update visible slots
- **Cache lookups**: Cache inventory references
- **Batch operations**: Group multiple slot updates
- **Lazy loading**: Only create slots when inventory is visible
- **Pool animations**: Reuse animation tweens

### Optimization Techniques
- Limit slot count (10 max for player, 6 for buildings)
- Use native resolution icons (32x32, no scaling)
- Minimize texture lookups
- Cache drag preview sprite
- Debounce hover tooltip delays

## Configuration

### Key Settings
Located in `scripts/inventory/`:
- **Slot size**: 64x64 pixels (uniform)
- **Icon size**: 32x32 pixels (native resolution)
- **Hotbar slot size**: 32x32 pixels
- **Max stack**: 10 items (buildings/carts only)
- **Panel max**: 3 simultaneous panels
- **Tooltip delay**: 1 second

## Testing Checklist

### Basic Drag & Drop
- [ ] Drag within same inventory (swap)
- [ ] Drag to empty slot in same inventory
- [ ] Drag from player to building inventory
- [ ] Drag from building to player inventory
- [ ] Drag from hotbar to main inventory
- [ ] Drag from main inventory to hotbar

### Stacking
- [ ] Stack same items in building inventory
- [ ] Partial stack when dragging to full stack
- [ ] Drag 1 item from stack (remaining stays)
- [ ] Stack limit enforcement (max 10)

### Building Placement
- [ ] Drag building icon to world (placement)
- [ ] Drag building icon outside inventory (should place, not cancel)
- [ ] Place land claim building anywhere (valid)
- [ ] Place other building inside land claim (valid)
- [ ] Place other building outside land claim (invalid, should cancel)
- [ ] Place building overlapping existing building (invalid)

### World Drops
- [ ] Drag item to ground (spawns entity)
- [ ] Pick up ground item (adds to inventory)

### Visual Feedback
- [ ] Slots highlight on hover
- [ ] Valid drop targets show green glow
- [ ] Invalid drop targets show red X
- [ ] Drag preview follows mouse smoothly
- [ ] Drop feedback animations play correctly
- [ ] Snap back animation works on invalid drop
- [ ] Quality borders display correctly
- [ ] Hover tooltips show after 1 second

### Panel Management
- [ ] ⚠️ Panels can be dragged by title bar (NOT YET IMPLEMENTED)
- [ ] ⚠️ Panels don't overlap (auto-adjust) (NOT YET IMPLEMENTED)
- [ ] ⚠️ Panels can't go off-screen (NOT YET IMPLEMENTED)
- [x] Max 3 panels open simultaneously
- [x] I key closes all panels
- [x] X button closes individual panel
- [x] Building inventory auto-closes when moving away

### Edge Cases
- [ ] Drag when inventory is full
- [ ] Drag when target slot is full
- [ ] Drag when stack limit reached
- [ ] Drag same item to same slot
- [ ] Drag during animation
- [ ] Rapid drag operations
- [ ] Drag from NPC inventory (should be blocked)
- [ ] Drag to NPC inventory (should be blocked)

## Questions & Answers

**Q: Can I drag items from the game world directly into inventory?**  
A: Yes, ground items can be dragged into inventory. Walk over them or drag them directly.

**Q: What happens if I drag a building icon outside the inventory?**  
A: It attempts to place the building on the map. If placement is invalid, it cancels and returns to source.

**Q: Can I have multiple building inventories open?**  
A: No, only 1 building inventory can be open at a time. Opening a new one closes the previous.

**Q: How do I close all inventories at once?**  
A: Press the **I** key to close all inventory panels.

**Q: Can NPC inventories be interacted with?**  
A: No, NPC inventories are read-only. You can view them but cannot drag items in or out.

**Q: What happens if I drag an invalid item type to a hotbar slot?**  
A: The slot shows a red X overlay and the drop is rejected with a snap-back animation.

**Q: Can panels overlap?**  
A: ⚠️ **NOT YET IMPLEMENTED** - Panels are currently fixed in position. When draggable panels are implemented, they will automatically adjust to prevent overlap and cannot be dragged off-screen.

**Q: Are inventory positions saved?**  
A: ⚠️ **NOT YET IMPLEMENTED** - Position persistence is a planned feature. Currently, panels use fixed default positions. When implemented, positions will be saved per save file and persist between sessions.

**Q: What happens if a saved position is off-screen after resolution change?**  
A: ⚠️ **NOT YET IMPLEMENTED** - When position persistence is implemented, positions will be automatically reset to defaults if they're off-screen after a resolution change.

**Q: How does stacking work when dragging?**  
A: Dragging from a stack only moves 1 item. The remaining items stay in the source slot. When dropping on a stack of the same type, items merge up to the max stack limit (10).

---

**Last Updated**: December 2025  
**Version**: 1.0  
**Status**: Complete Guide - All Systems Documented

I want to expand heavily on the drag and drop system and make it so that gathering is also done by drag and drop from the player. and other things