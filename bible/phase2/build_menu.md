# Building Menu System - Implementation Document

**Date**: January 2026  
**Last updated**: January 2026 (placement 50px, Building.tscn for all types, baby pool / woman occupation disabled)  
**Status**: Implemented  
**Scope**: Building menu UI, building selection, and building placement system

## Overview

The Building Menu is a UI system that allows players to view available buildings, check required resources, and place buildings within their land claim. The menu is **integrated into the Land Claim Inventory UI** (opened with **I** key when near a land claim). The building selection panel appears on the right side when viewing the land claim inventory.

## UI Layout

### Overall Structure

The Building Menu is **integrated into the Land Claim Inventory UI**. When the player opens the land claim inventory (press **I** when near a land claim), two panels are displayed:

1. **Land Claim Inventory Panel** (Center) - Displays current resources available for building (via BuildingInventoryUI)
2. **Building Selection Panel** (Right Side) - Lists all available buildings with icons and descriptions (via BuildMenuUI)

### Layout Details

```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│        [Land Claim Inventory - Center Panel]                │
│        ┌─────┐ ┌─────┐ ┌─────┐                              │
│        │ 10  │ │  5  │ │  3  │                              │
│        │Wood │ │Fiber│ │Stone│                              │
│        └─────┘ └─────┘ └─────┘                              │
│        ┌─────┐ ┌─────┐                                       │
│        │  2  │ │  1  │                                       │
│        │Hide │ │Meat │                                       │
│        └─────┘ └─────┘                                       │
│                                                             │
│                                          ┌─────────────────┐│
│                                          │  Building Menu  ││
│                                          ├─────────────────┤│
│                                          │ ┌─────┐         ││
│                                          │ │     │ Living  ││
│                                          │ │ Hut │ Hut     ││
│                                          │ │     │ +5 baby ││
│                                          │ └─────┘ cap     ││
│                                          │ Cost: 10 Wood,  ││
│                                          │       10 Fiber  ││
│                                          ├─────────────────┤│
│                                          │ ┌─────┐         ││
│                                          │ │     │ Farm    ││
│                                          │ │ Farm│ [Desc]  ││
│                                          │ └─────┘         ││
│                                          │ Cost: ...       ││
│                                          └─────────────────┘│
└─────────────────────────────────────────────────────────────┘
```

### Panel Specifications

**Land Claim Inventory Panel:**
- **Position**: Center of screen (via BuildingInventoryUI)
- **Size**: 320px wide × 500px tall
- **Style**: Same semi-transparent brown style as existing inventory UIs
- **Content**: Displays all items in the land claim's inventory
- **Slots**: 6 vertical slots with stacking enabled (max stack: 999)
- **Drag-and-Drop**: Enabled (player can move items in/out)
- **Building Icons**: Also shows building icons at the bottom (Living Hut, Oven, etc.) for quick access

**Building Selection Panel:**
- **Position**: Right side of screen
- **Width**: ~280-320px
- **Height**: Matches screen height or scrollable
- **Style**: Same semi-transparent brown style
- **Content**: Vertical list of building cards
- **Scrollable**: Yes (if buildings exceed panel height)

### Building Card Structure

Each building is displayed as a card with:

```
┌─────────────────────┐
│ [Building Icon]     │  (64x64 or 48x48 pixels)
│                     │
│ Building Name       │  (e.g., "Living Hut")
│                     │
│ Description Text    │  (2-3 lines)
│ - Effect/Benefit    │
│                     │
│ Cost:               │
│ • 10 Wood           │
│ • 10 Fiber          │
│                     │
│ [Buildable/Not]     │  (Visual indicator)
└─────────────────────┘
```

**Building Card Elements:**
- **Icon**: Building sprite (e.g., `hut.png` for Living Hut)
- **Name**: Building type name (bold, larger font)
- **Description**: Brief 2-3 line explanation of building function
- **Cost**: List of required materials with quantities
- **Availability Indicator**: 
  - Green highlight if player has all required materials
  - Gray/red if missing materials
  - Shows missing material count in red

## Input & Controls

### Opening the Menu

- **Key**: **I** (same as opening land claim inventory)
- **Condition**: Player must be near their own land claim
- **How it works**: 
  - Press **I** when near a land claim to open the land claim inventory
  - The BuildingInventoryUI shows the land claim inventory in the center
  - The BuildMenuUI automatically shows building cards on the right side
  - Both panels are shown together
- **Toggle**: Pressing I again closes both panels
- **Alternative Close**: Click outside panels or press ESC

### Building Selection

- **Click Building Card**: Consumes materials from land claim inventory and adds building item to player inventory
- **Visual Feedback**: 
  - Cards show green cost text if player can afford
  - Cards show red cost text if player cannot afford
  - Cards are grayed out if materials are insufficient
- **Cost Display**: Shows "X/Y Material" format (e.g., "2/2 Stone" if you have enough, "1/2 Stone" if missing)

### Building Placement

After clicking a building card:

1. Materials are consumed from land claim inventory
2. Building item is added to player inventory (as a placeable item)
3. Player can then place the building by dragging the building item from inventory to world
4. Valid locations: Inside land claim, 50px from other buildings/land claims
5. Invalid locations: Outside land claim (cannot place)

## Building System Specifications

### Baby Cap System

**Base Baby Cap:**
- Every land claim starts with **3 baby capacity**
- Babies beyond capacity become instant clansmen

**Living Hut Bonus:**
- Each Living Hut adds **+5** to baby pool capacity
- Example: 1 land claim + 2 Living Huts = 3 + (2×5) = **13 baby capacity**

**Implementation:**
- BabyPoolManager tracks total capacity per land claim
- Capacity = Base (3) + (Living Hut Count × 5)
- When Living Hut is built: `baby_pool_manager.increase_capacity(land_claim, 5)` — **currently disabled** in `main.gd` (_handle_building_placed)
- When Living Hut is destroyed: `baby_pool_manager.decrease_capacity(land_claim, 5)`

### Living Hut Specifications

**Living Hut:**
- **Icon**: `hut.png` (from assets/sprites/)
- **Cost**: 
  - 1 Wood (testing)
  - 1 Stone (testing)
- **Function**: +5 baby pool capacity
- **Woman Required**: No (0 women)
- **Build Time**: Instant (for Phase 2, may change later)
- **Placement Size**: 128×128 pixels (2×2 tiles)

### Building Placement Rules

**Placement Validation:**
1. Must be inside player's own land claim radius
2. Minimum 50px distance from other buildings (safety zone)
3. Cannot overlap with existing buildings
4. Must have required materials in land claim inventory

**Material Consumption:**
- Materials are consumed from land claim inventory when building card is clicked
- Building item is added to player inventory (as placeable item)
- Player then drags building item from inventory to place in world
- If materials are insufficient, building card is grayed out and cannot be clicked

**Drag Animation System:**
All placeable buildings (Land Claim, Living Hut, Supply Hut, Shrine, Dairy Farm, Oven) have a consistent drag animation:

- **Icon Size (32×32)**: When dragging over UI areas, preview shows at icon size (32×32 pixels)
- **Building Size (64×64)**: When dragging over world (not over UI), preview smoothly animates to building size (64×64 pixels)
- **Smooth Transition**: Size change is animated with 0.2 second tween for smooth visual feedback
- **Opacity**: Preview is semi-transparent (80% opacity over UI, 90% opacity over world)
- **Consistency**: All placeable buildings use the same animation system for uniform UX

**Placement "Plop" Animation:**
When building is successfully placed:
- Building starts at scale 0 (invisible)
- Animates to scale 1.2 (overshoot) in 0.15 seconds with EASE_OUT + TRANS_BACK
- Settles to scale 1.0 in 0.1 seconds
- Optional: Sprite rotation wiggle (5° → -5° → 0°) for extra polish
- **Consistency**: All buildings use the same placement animation for uniform feel

**Implementation Details:**
- Drag animation handled by `DragManager._process()` in `scripts/inventory/drag_manager.gd`
- Detects mouse position relative to UI vs world
- Uses `create_tween()` for smooth size transitions
- Building preview follows mouse cursor
- Preview uses actual building sprite (not icon) for better visual feedback
- Placement animation handled by `_animate_building_placement()` in `scripts/main.gd`

**Construction:**
- Phase 2: Buildings appear instantly (no construction timer)
- Future: May add construction timers or NPC builders

## Building Data Structure

### Building Definition

Each building type is defined with:

```gdscript
{
  "building_type": "living_hut",
  "display_name": "Living Hut",
  "icon_path": "res://assets/sprites/hut.png",
  "description": "Increases baby pool capacity by +5.\nProvides shelter for your growing clan.",
  "cost": {
    "wood": 10,
    "fiber": 10
  },
  "build_time": 0.0,  # 0 = instant
  "size": Vector2(128, 128),
  "woman_required": 0,
  "special_effect": "increase_baby_capacity",
  "effect_value": 5
}
```

### Available Buildings (Phase 2 - Level 1)

1. **Living Hut** - +5 baby capacity (1 Wood, 1 Stone - testing costs)
2. **Supply Hut** - Extra storage (1 Wood, 1 Stone - testing costs)
3. **Shrine** - Place of worship (1 Wood, 1 Stone - testing costs)
4. **Dairy Farm** - Milk animals for resources (1 Wood, 1 Stone - testing costs)
5. **Oven** - Bread production (2 Stone) - *See Oven Building Plan below*
6. *Future buildings will be added as they're implemented*

## Implementation Architecture

### File Structure

```
scripts/
├── ui/
│   └── build_menu_ui.gd (IMPLEMENTED)
├── buildings/
│   ├── building_registry.gd (IMPLEMENTED)
│   ├── building_base.gd (IMPLEMENTED)
│   ├── oven.gd (IMPLEMENTED)
│   └── components/
│       └── production_component.gd (IMPLEMENTED)
└── inventory/
    └── building_inventory_ui.gd (IMPLEMENTED - shows land claim inventory)
```

### Component Breakdown

**BuildMenuUI (`build_menu_ui.gd`):**
- Main UI controller for building selection panel
- Integrated with BuildingInventoryUI (shares land claim reference)
- Manages building cards panel (right side)
- Coordinates building selection and material consumption
- Updates card availability based on inventory

**BuildingRegistry (`building_registry.gd`):**
- Static registry of all building types
- Provides building definitions (cost, icon, description)
- Validates building data
- Checks if player can afford buildings
- Consumes materials from inventory

**BuildingBase (`building_base.gd`):**
- Base class for all buildings
- Handles inventory (6 slots, stacking enabled)
- Tracks occupation (occupied_by NPC reference)
- Manages building visuals and interaction

**ProductionComponent (`production_component.gd`):**
- Handles recipe-based crafting for production buildings
- Manages crafting timers
- Consumes inputs and creates outputs
- Checks for woman occupation requirement

### Integration Points

**Main.gd:**
- Detects player near land claim
- Handles I key input (opens BuildingInventoryUI)
- BuildingInventoryUI automatically shows BuildMenuUI when opened
- Manages building placement in world (when building item is dragged from inventory)

**LandClaim.gd:**
- Provides inventory reference to BuildMenuUI
- Tracks buildings placed within radius
- Validates building placement location

**BabyPoolManager:**
- Receives capacity change notifications from Living Huts
- Updates baby pool capacity when huts are built/destroyed

**BuildingInventoryUI:**
- Shows land claim inventory in center panel
- Also displays building icons at bottom (for quick building access)
- Automatically triggers BuildMenuUI to show building cards on right
- Both panels share the same land claim reference

## Building Creation Flow

### Step-by-Step Process

1. **Player presses I near land claim**
   - `main.gd` detects I key
   - Checks if player is near their land claim
   - Opens `BuildingInventoryUI` (shows land claim inventory)
   - `BuildingInventoryUI` automatically triggers `BuildMenuUI` to show building cards

2. **Both panels display**
   - Center: Land claim inventory (via BuildingInventoryUI)
   - Right: Building selection cards (via BuildMenuUI)
   - Both share the same land claim reference

3. **Player clicks building card (e.g., Oven)**
   - `BuildMenuUI` validates materials (checks land claim inventory)
   - If valid: Consumes materials from land claim inventory
   - Adds building item to player inventory
   - Updates inventory display
   - Updates card availability (cards refresh to show new material counts)
   - If invalid: Shows error message, card stays grayed out

4. **Player places building**
   - Player drags building item from their inventory
   - Drops building item on valid location in world
   - `main.gd` validates position (inside land claim, 50px from others)
   - If valid: Instantiates building scene at position
   - Building is added to land claim's building list
   - If Oven: Woman NPCs will auto-occupy it (if available)
   - If Living Hut: BabyPoolManager updates capacity

## Visual Design

### Colors & Styling

**Panel Colors:**
- Background: `#1a1512` at 85% opacity (matching inventory UIs)
- Border: `#8b4513` (saddle brown) at 90% opacity
- Corner radius: 12px
- Shadow: Black at 25% opacity, 4px size

**Building Card States:**
- **Normal**: Standard brown background
- **Hover**: Slightly lighter background
- **Selected**: Gold/yellow border highlight
- **Available**: Green text for cost numbers
- **Unavailable**: Red text for missing materials

**Text Styling:**
- Building Name: 18-20px, bold
- Description: 12-14px, normal
- Cost: 12px, normal (green if available, red if missing)

### Icons

- Building icons: 64×64 or 48×48 pixels
- Loaded from `assets/sprites/`
- Scaled to fit card icon area
- Aspect ratio maintained

## Edge Cases & Validation

### Player Not in Land Claim
- B key does nothing (or shows message: "Must be inside your land claim")

### Insufficient Materials
- Building card shows red cost numbers
- Build button disabled (or shows "Insufficient Materials" tooltip)
- Clicking building shows which materials are missing

### Land Claim Full
- If land claim has no space (theoretical limit):
  - Show error: "Not enough space for more buildings"
  - Disable all building cards

### Building Placement Conflicts
- Building too close to another: Red ghost, cannot place
- Clicking invalid location: Flash red, show message: "Too close to existing building"

### Inventory Changes During Menu Open
- Land claim inventory updates in real-time
- Building availability updates when materials change
- Cards re-check availability when materials are added/removed

## Scalability: Adding More Buildings

### Dynamic Building List

**Current Design (Phase 2):**
- Building list is generated dynamically from `BuildingRegistry`
- Cards are created for each registered building type
- Cards are added to a `VBoxContainer` in order

**As Buildings Grow:**

When you add more buildings (Farm, Storage Hut, Armory, Tailor, etc.), the UI automatically adapts:

1. **Building Cards Auto-Generate**: Each building registered in `BuildingRegistry` gets a card
2. **ScrollContainer Handles Overflow**: The right panel uses a `ScrollContainer` → `VBoxContainer` → Building Cards
3. **No Code Changes Needed**: Adding buildings only requires:
   - Add building definition to `BuildingRegistry`
   - UI automatically creates card on next menu open

### Scrolling Implementation

**Phase 2 (1-5 buildings):**
- Vertical list, no scroll needed (fits on screen)
- Panel height: matches screen height

**Future (6+ buildings):**
- ScrollContainer wraps VBoxContainer
- Scrollbar appears automatically when content exceeds panel height
- Mouse wheel / drag scrolling works automatically in Godot

**Implementation:**
```gdscript
# Building Selection Panel Structure
Panel (BuildingSelectionPanel)
└── ScrollContainer
    └── VBoxContainer (cards_container)
        ├── BuildingCard (Living Hut)
        ├── BuildingCard (Farm)
        ├── BuildingCard (Storage Hut)
        └── ... (more cards added dynamically)
```

### Organization Strategies

**Phase 2: Simple List**
- All buildings in single vertical list
- Order: As defined in `BuildingRegistry`
- No categorization needed (few buildings)

**Phase 3+: Categories (Recommended)**
When you have 8+ buildings, add category tabs:

```
┌─────────────────────┐
│ [All] [Prod] [Stor] │  ← Category tabs
├─────────────────────┤
│ ┌─────┐             │
│ │Farm │             │
│ └─────┘             │
│ ┌─────┐             │
│ │Armor│             │
│ └─────┘             │
└─────────────────────┘
```

**Category Examples:**
- **All**: All buildings (default)
- **Production**: Farm, Armory, Tailor, Spinner, Dairy, Bakery
- **Storage**: Storage Hut, Living Hut
- **Defense**: (future buildings)
- **Special**: Shrine, Medic Hut

**Implementation:**
- `TabContainer` or horizontal `HBoxContainer` of buttons above cards
- Filter cards by category when tab clicked
- Cards hide/show based on category filter

### Sorting Options (Future)

**Default Sort:**
- Registration order (as defined in `BuildingRegistry`)

**Alternative Sorts:**
- **Alphabetical**: A-Z by name
- **Cost**: Cheapest first
- **Available**: Buildable buildings first
- **Type**: Grouped by category

**UI Control:**
- Dropdown or button in panel header
- Changes card order dynamically

### Search/Filter (Future Enhancement)

**When Needed:**
- 15+ buildings (advanced feature)

**Implementation:**
- Search box at top of building panel
- Filters cards in real-time as you type
- Matches: Building name, description, or materials
- Example: Type "wood" → shows buildings that need wood

### Performance Considerations

**Card Creation:**
- Cards created on menu open (not during gameplay)
- No performance impact until menu opened
- Card count doesn't affect game performance (only UI responsiveness)

**Optimization (if 20+ buildings):**
- **Lazy Loading**: Only create visible cards, load others on scroll
- **Pagination**: Show 10 buildings per page (probably unnecessary)
- **Virtual Scrolling**: Godot's ScrollContainer handles this well automatically

**Current Design:**
- Single VBoxContainer with all cards (simple, fast for <20 buildings)
- No optimization needed in Phase 2

### Card Size & Layout

**Fixed Card Height:**
- Each card ~120-150px tall
- Icons: 48×48 or 64×64 pixels
- Consistent spacing between cards (8-12px)

**Panel Height Calculation:**
- Screen height: ~720px
- Panel usable height: ~650px (accounting for header/padding)
- Fits ~4-5 cards before scrolling needed
- With scrolling: Unlimited buildings

### Code Structure (Scalability)

**BuildingRegistry Pattern:**
```gdscript
# BuildingRegistry automatically includes all registered buildings
func get_all_buildings() -> Array:
    return [
        get_building("living_hut"),
        get_building("farm"),
        get_building("storage_hut"),
        # Adding new buildings here auto-includes them in UI
    ]
```

**BuildMenuUI Pattern:**
```gdscript
func _build_building_cards() -> void:
    # Get all buildings from registry (scales automatically)
    var buildings = BuildingRegistry.get_all_buildings()
    
    # Clear existing cards
    _clear_cards()
    
    # Create card for each building
    for building_data in buildings:
        var card = BuildingCard.new()
        card.setup(building_data)
        cards_container.add_child(card)
    
    # ScrollContainer handles overflow automatically
```

**Adding New Building:**
1. Add building definition to `BuildingRegistry`
2. Add building scene/prefab if needed
3. UI automatically includes it on next menu open
4. No UI code changes required

### Visual Adaptations

**Compact Mode (Future):**
- Option to show smaller cards (icon + name only)
- Hover shows full description
- Allows more buildings visible at once

**Grid Layout (Future):**
- Switch from vertical list to 2-column grid
- Doubles visible buildings (half as tall)
- Useful for 15+ buildings

**Current (Phase 2):**
- Vertical list (best for small building count)
- Full card details always visible
- Simple, readable

## Future Enhancements (Post-Phase 2)

- Construction timers (buildings appear over time)
- NPC builders (NPCs must construct buildings)
- Building upgrades (Living Hut → Improved Living Hut)
- Building destruction/removal
- **Building categories/tabs** (Production, Storage, Defense) - *See Scalability section above*
- **Building search/filter** - *See Scalability section above*
- **Building sorting** - *See Scalability section above*
- Building hotkeys (keyboard shortcuts for common buildings)
- Building tooltips (hover for detailed stats)
- Compact mode / grid layout options

## Questions for Clarification

1. **Menu Overlap**: Can Build Menu and Building Inventory (I key) be open simultaneously?
   - **Decision**: They are integrated - Building Inventory (I key) automatically shows Build Menu on the right side

2. **Menu Close**: Should menu close automatically after building placement?
   - **Decision**: No, stays open so player can build multiple buildings. Player closes with I key.

3. **Placement**: How are buildings placed?
   - **Decision**: Click building card → materials consumed → building item added to player inventory → drag building item from inventory to world to place

4. **Building Rotation**: Can buildings be rotated before placement?
   - **Decision**: No rotation in Phase 2 (all buildings face same direction)

5. **Material Display**: Show exact counts (10/10) or just requirement (10)?
   - **Decision**: Shows "X/Y Material" format (e.g., "2/2 Stone" if you have enough, "1/2 Stone" if missing). Green text if affordable, red if not.

---

## Oven Building - Implementation Plan

**Date**: January 2026  
**Status**: Implemented  
**Priority**: High - First production building with crafting system

### Overview

The Oven is a production building that requires a woman NPC to operate. It crafts bread from wood and grain resources. This building introduces several new systems:
- Building occupation system (women moving into buildings)
- Crafting/refining system (resource conversion)
- Stackable inventory items (wood, grain, bread)

### Oven Specifications

**Building Type**: `oven`  
**Display Name**: "Oven"  
**Icon**: `oven.png` (to be created, placeholder for now)

**Build Cost:**
- **2 Stone** (testing phase)
- *Future*: Will require Clay + Stone (when clay system is implemented)

**Build Time**: Instant (for testing, may add construction timer later)

**Placement:**
- Must be inside land claim
- Minimum 50px from other buildings/land claims
- Size: 128×128 pixels (2×2 tiles)

**Inventory:**
- **6 slots** (stackable items)
- Can store: Wood, Grain, Bread
- All items stack in inventory (no per-slot limits for same item type)

**Woman Requirement:**
- ~~**1 woman NPC** must occupy the building to produce bread~~ **DISABLED** - Production works without women (feature disabled for testing)
- Building requires manual activation via fire button
- Fire button only enabled when building has 1 Wood + 1 Grain in inventory

**Production:**
- **Recipe**: 1 Wood + 1 Grain → 1 Bread
- **Output**: `bread.png` (new item type)
- **Production Time**: **15 seconds** per bread
- **Auto-crafting**: When building is active (turned on) and materials are available
- **Auto-shutdown**: Building automatically turns off when resources run out
- **Continuous Production**: If materials remain after bread is created, next bread starts immediately

### Building Activation System

**New System**: Oven requires manual activation via fire button.

**Activation Mechanics:**
1. **Fire Button**:
   - Located to the right of building name in inventory UI
   - Red square button with fire symbol (🔥 when on, ❄️ when off)
   - Only enabled when building has required materials (1 Wood + 1 Grain)
   - Disabled (grayed out) when materials are missing

2. **Activation Requirements**:
   - Building must have 1 Wood in inventory
   - Building must have 1 Grain in inventory
   - Fire button becomes clickable when both materials present

3. **Building States**:
   - **Inactive (Default)**: Building is off when placed, no production
   - **Active**: Building is on, production runs automatically
   - **Auto-shutdown**: Building automatically turns off when resources exhausted

4. **UI Feedback**:
   - Fire button shows visual state (🔥 = on, ❄️ = off)
   - Production progress bar appears when building is active
   - UI refreshes immediately when fire button is pressed
   - Button has animation and sound feedback on click

**Building Occupation System (DISABLED):**
- ~~Women NPCs can occupy buildings~~ - **Feature disabled for testing**
- Production works without women occupation
- Occupation system code exists but is disabled (`occupy_building_state.can_enter()` always returns false)

### Crafting/Refining System

**New System**: Buildings can convert input resources into output resources.

**Crafting Logic:**
1. **Recipe Definition**:
   ```gdscript
   {
     "inputs": [
       {"type": ResourceData.ResourceType.WOOD, "quantity": 1},
       {"type": ResourceData.ResourceType.GRAIN, "quantity": 1}
     ],
     "output": {"type": ResourceData.ResourceType.BREAD, "quantity": 1},
     "craft_time": 15.0  # 15 seconds per bread
   }
   ```

2. **Crafting Process**:
   - Check building inventory for required inputs
   - Check if building is active (turned on via fire button)
   - Start crafting timer when conditions met
   - Progress bar shows crafting progress (0.0 to 1.0)
   - Consume inputs when timer completes (15 seconds)
   - Add output to building inventory (bread stacks automatically)
   - If materials still available, start next craft immediately (progress bar resets to 0)

3. **Crafting States**:
   - **Idle**: No materials or building inactive
   - **Crafting**: Materials + building active, timer running (15 seconds)
   - **Complete**: Output added to inventory, ready for next craft (if materials remain)
   - **Auto-shutdown**: Building turns off automatically when resources exhausted

4. **Production Component**:
   - Component: `production_component.gd`
   - Attached to production buildings (Oven, future: Farm, Armory, etc.)
   - Handles recipe checking, timer management, input/output
   - Notifies UI when items are created (refreshes inventory display)

**Crafting Timer:**
- Fixed timer: **15 seconds** per bread
- Timer only runs when building is active (turned on)
- Timer pauses if building is turned off
- Progress bar updates in real-time (visible in building inventory UI)
- Continuous production: Next bread starts immediately if materials available

### Inventory Stacking System

**New Feature**: Items can stack in building inventories.

**Stacking Rules:**
- **Wood**: Stacks in inventory (no per-slot limit)
- **Grain**: Stacks in inventory
- **Bread**: Stacks in inventory
- Same item type stacks together
- Inventory shows total count per item type

**Implementation:**
- Modify `InventoryData` to support stacking
- Track item counts per type: `{item_type: count}`
- UI displays stacked items with count badges
- Drag-and-drop handles stacked items (split stacks, merge stacks)

**Inventory Display:**
- Show item icon + count (e.g., "Wood x5")
- Empty slots show as empty
- Max stack size: 999 per item type (effectively unlimited)
- Bread stacks automatically in building inventory
- UI refreshes automatically when bread is created

### Bread Item

**New Item Type**: `bread.png`

**Item Properties:**
- **Type**: `ResourceData.ResourceType.BREAD`
- **Sprite**: `res://assets/sprites/bread.png`
- **Stackable**: Yes
- **Consumable**: Yes (food item, best food in game)
- **Value**: High (better than raw meat/berries)

**Item Integration:**
- Add `BREAD` to `ResourceData.ResourceType` enum
- Add bread sprite to assets
- Bread can be consumed by NPCs/player (food system)
- Bread can be stored in any inventory (player, building, land claim)

### Implementation Steps

1. **Add Oven to Building Registry**
   - Register oven building type
   - Define build cost (2 Stone)
   - Define inventory size (6 slots)
   - Define woman requirement (1 woman)

2. **Create Oven Building Script**
   - `scripts/buildings/oven.gd`
   - Extends `BuildingBase`
   - Implements production component
   - Handles occupation tracking

3. **Create Production Component**
   - `scripts/buildings/components/production_component.gd`
   - Recipe system (inputs → output)
   - Crafting timer management
   - Inventory interaction

4. **Implement Building Activation System**
   - Fire button in building inventory UI
   - Button validation (requires wood + grain)
   - Building active/inactive state management
   - Auto-shutdown when resources exhausted
   - UI refresh on activation (shows production progress bar)
   
   **Building Occupation System (DISABLED):**
   - FSM states exist but are disabled (`occupy_building_state.gd`, `work_at_building_state.gd`)
   - Production works without women (for testing)

5. **Implement Inventory Stacking**
   - Modify `InventoryData` for stacking support
   - Update `BuildingInventoryUI` to show stacks
   - Handle drag-and-drop with stacked items

6. **Add Bread Item**
   - Add `BREAD` to `ResourceData.ResourceType`
   - Create/import `bread.png` sprite
   - Add bread to item database

7. **Create Oven Scene**
   - `scenes/buildings/Oven.tscn`
   - Sprite and script attachment

8. **Integrate with Build Menu**
   - Add Oven card to building selection panel
   - Show cost (2 Stone)
   - Show description (bread production)

9. **Testing**
   - ✅ Test oven placement
   - ✅ Test fire button activation (requires wood + grain)
   - ✅ Test crafting (wood + grain → bread in 15 seconds)
   - ✅ Test inventory stacking (bread stacks in inventory)
   - ✅ Test production progress bar (shows in UI when active)
   - ✅ Test auto-shutdown (oven turns off when resources exhausted)
   - ✅ Test continuous production (next bread starts immediately if materials available)
   - ✅ Test UI refresh (production bar appears immediately when activated)
   - ⏳ Test bread consumption (food system)

### File Structure

All building types (Living Hut, Supply Hut, Shrine, Dairy Farm, Oven) use the shared **Building.tscn** scene; `building_type` is set in `main.gd` at placement. Oven-specific logic lives in `building_base.gd` (production component) and `oven.gd` (extends BuildingBase, sets building_type).

```
scripts/
├── buildings/
│   ├── building_base.gd (IMPLEMENTED - handles all types, production for Oven)
│   ├── oven.gd (IMPLEMENTED - Oven-specific, sets building_type)
│   └── components/
│       └── production_component.gd (IMPLEMENTED)
├── npc/
│   └── states/
│       ├── occupy_building_state.gd (IMPLEMENTED - woman occupation disabled)
│       └── work_at_building_state.gd (IMPLEMENTED)
└── (no separate production_config.gd - config in building_base)

scenes/
└── Building.tscn (IMPLEMENTED - shared for all building types)

assets/
└── sprites/
    └── bread.png (add if missing)
    └── oven.png (add if missing - placeholder ok)
```

### Configuration

**New Config File: `production_config.gd`**
```gdscript
extends Resource
class_name ProductionConfig

@export var default_craft_time: float = 60.0  # Base crafting time
@export var occupation_range: float = 500.0  # Auto-assignment range
@export var max_stack_size: int = 999  # Max items per stack (unlimited)
```

### Recipe System

**Oven Recipe Definition:**
```gdscript
{
  "building_type": "oven",
  "recipe_name": "bread",
  "inputs": [
    {"type": ResourceData.ResourceType.WOOD, "quantity": 1},
    {"type": ResourceData.ResourceType.GRAIN, "quantity": 1}
  ],
  "output": {"type": ResourceData.ResourceType.BREAD, "quantity": 1},
  "craft_time": 60.0,
  "requires_woman": true
}
```

### Future Enhancements

- **Clay Requirement**: Oven will require Clay + Stone (when clay system added)
- **Multiple Recipes**: Oven may have multiple bread recipes (different bread types)
- **Production Speed**: Based on woman's traits/stats (faster/slower crafting)
- **Manual Assignment**: Drag woman onto building to assign
- **Building Upgrades**: Improved Oven (faster crafting, more slots)
- **Fuel System**: Wood consumed as fuel (separate from recipe input)

### Design Decisions

1. **Build Cost**: 2 Stone for testing (simple, available resource)
2. **Inventory Size**: 6 slots (enough for inputs + outputs)
3. **Stacking**: Unlimited stacks (simplifies inventory management)
4. **Auto-Occupation**: Women automatically find buildings (better UX)
5. **Craft Time**: 60-90 seconds (testing, may adjust based on balance)
6. **Woman Required**: Yes (adds strategic element - need women for production)

---

## Current Implementation Status

**Implemented Features:**
- ✅ Building menu integrated into land claim inventory (I key)
- ✅ Building cards panel on right side showing all available buildings
- ✅ Material cost checking and validation
- ✅ Building item creation (materials consumed, item added to player inventory)
- ✅ Building placement via drag-and-drop from inventory
- ✅ Building registry with all building types
- ✅ Oven building with production system
- ✅ Fire button activation system (on/off switch)
- ✅ Production component for crafting recipes (15 second bread production)
- ✅ Production progress bar in building inventory UI
- ✅ Auto-shutdown when resources exhausted
- ✅ Continuous production (next bread starts immediately)
- ✅ Inventory stacking (bread stacks in building inventory)
- ✅ UI auto-refresh when production completes or building activated
- ✅ Drag animation system for all placeable buildings

**Building Occupation System:**
- ⚠️ **DISABLED** - Women occupation feature is disabled for testing
- Production works without women
- Occupation code exists but `occupy_building_state.can_enter()` always returns false

**Remaining Tasks:**
- ⏳ Create bread.png and oven.png sprite assets (if missing)
- ⏳ Re-enable woman occupation system (when ready)
- ⏳ Re-enable Living Hut baby pool capacity increase (when ready; currently disabled in main.gd)
- ⏳ Testing and balancing

---

This document defines the complete Building Menu system for Phase 2.  
The system is implemented and integrated with the land claim inventory UI.
