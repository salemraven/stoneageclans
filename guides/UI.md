# Stone Age Clans – UI Design Standards

**Date**: January 2026  
**Status**: Living Document  
**Last Updated**: January 2026 (Added corpse looting system, updated inventory sizes, drag-and-drop specifications)  
**Purpose**: Standardize all UI elements (menus, inventories, info screens) for consistency across the game

## Overview

This document defines the visual style, layout patterns, and interaction standards for all UI elements in Stone Age Clans. All UI elements should follow these standards to ensure a cohesive user experience.

## Design Philosophy

**Stone Age Aesthetic:**
- Rustic, earthy brown color palette
- Semi-transparent panels (allow world visibility)
- Simple, functional design (no ornate decorations)
- Clear, readable text
- Consistent sizing and spacing

**Usability Principles:**
- Drag-and-drop is primary interaction method
- Panels can overlap (player can see multiple at once)
- Keyboard shortcuts for common actions
- Visual feedback for all interactions
- Unified inventory system (player, buildings, NPCs, corpses all use same drag-and-drop)

---

## 1. Color Palette

### Primary Colors

**Background:**
- Dark brown: `#1a1512` at 85% opacity (0.85 alpha)
- Used for: All panel backgrounds

**Border:**
- Saddle brown: `#8b4513` at 90% opacity (0.9 alpha)
- Used for: Panel borders, outlines
- Border width: 2px

**Shadow:**
- Black: `#000000` at 25% opacity (0.25 alpha)
- Shadow size: 4px
- Shadow offset: `Vector2(0, 5)` (5px vertical)

### Text Colors

**Primary Text:**
- Off-white: `#e8e8e8` (RGB: 232, 232, 232)
- Used for: Labels, titles, descriptions

**Secondary Text:**
- Light gray: `#b0b0b0` (RGB: 176, 176, 176)
- Used for: Subtle information, hints

**Error/Unavailable:**
- Red: `#d32f2f` (RGB: 211, 47, 47)
- Used for: Missing materials, errors, disabled states

**Success/Available:**
- Green: `#66bb6a` (RGB: 102, 187, 106)
- Used for: Available actions, sufficient resources

**Warning/Selected:**
- Gold/Yellow: `#ffa726` (RGB: 255, 167, 38)
- Used for: Selected items, warnings

### Corner Radius

- All panels: **12px** (uniform rounded corners)

---

## 2. Panel Specifications

### Standard Panel Style

All UI panels share the same base style:

```gdscript
var style: StyleBoxFlat = StyleBoxFlat.new()
style.bg_color = Color(0x1a / 255.0, 0x15 / 255.0, 0x12 / 255.0, 0.85)  # Dark brown, 85% opacity
style.border_color = Color(0x8b / 255.0, 0x45 / 255.0, 0x13 / 255.0, 0.9)  # Saddle brown, 90% opacity
style.set_border_width_all(2)
style.corner_radius_top_left = 12
style.corner_radius_top_right = 12
style.corner_radius_bottom_left = 12
style.corner_radius_bottom_right = 12
style.shadow_color = Color(0, 0, 0, 0.25)  # Black, 25% opacity
style.shadow_size = 4
style.shadow_offset = Vector2(0, 5)
```

### Panel Sizing

**Standard Inventory Panel:**
- Width: **320px** (scales with screen resolution)
- Height: **400px** (adjustable for content, scales with screen resolution)
- Padding: **8px** (all sides, scales proportionally)

**Hotbar Panel:**
- Width: Variable (based on slot count)
- Height: **64px**
- Padding: **12px** (all sides)

**Dialog Panel:**
- Width: **400px** (minimum)
- Height: Variable (based on content)
- Padding: **16px** (all sides)

**Large Info Panel:**
- Width: **600px** (for Stats Panel, etc.)
- Height: **500px** (adjustable)
- Padding: **16px** (all sides)

---

## 3. Inventory System UI

### Inventory Panel Layout

All inventories follow this structure:

```
Panel (320×400px)
└── MarginContainer (8px padding)
    └── VBoxContainer / HBoxContainer
        └── InventorySlots (vertical or horizontal list)
```

### Slot Specifications

**Slot Size:**
- Standard: **32×32 pixels**
- Spacing: **0px** (for vertical), **6px** (for horizontal hotbars)

**Slot Style:**
- Background: Slightly lighter than panel (hover highlight)
- Border: 1px (lighter brown when empty, darker when filled)
- Icon: Fits within 32×32 area
- Count text: Bottom-right corner, 10-12px font

### Player Inventory

**Trigger:** Tab key (toggle)  
**Layout:**
- Main inventory: 5 vertical slots (320px wide) - reduced from 10
- Hotbar: 5 horizontal slots (always visible at bottom) - reduced from 10
- Position: Centered on screen, hotbar at bottom
- Deposit trigger: 80% full (4 out of 5 slots)

**Visual:**
- Same panel style as all inventories
- Hotbar: Separate panel, always visible

### Building Inventory (Land Claim)

**Trigger:** I key (when near land claim)  
**Layout:**
- 6 vertical slots (320px wide)
- Position: Center-left of screen (left of player inventory if both open)

**Visual:**
- Same panel style
- Displays land claim's inventory data

**Note:** BuildingInventoryUI is also used for corpse looting (see Corpse Inventory section below)

### NPC Inventory

**Trigger:** Click NPC + I key  
**Layout:**
- 5 slots (reduced from variable 6-10)
- Position: Center of screen (or near clicked NPC)
- Hotbar items are combined with main inventory (no separate hotbar section)

**Visual:**
- Same panel style
- Shows NPC's inventory
- Deposit trigger: 80% full (4 out of 5 slots)

### Character Menu (NPC Info Panel)

**Trigger:** Click NPC (displays alongside NPC inventory)  
**Behavior:** NPC freezes movement when clicked (resumes when menu closes)

**Layout:**
- Panel: **400×500px** (Medium panel size)
- Position: Right side of screen (or left if player inventory open)
- Structure: Vertical layout with sections

**Panel Structure:**
```
┌─────────────────────────────┐
│ [NPC Name]                  │  (Bold, 20px, header)
│ son of [Father] Clan [Name] │  (14px, secondary text)
│                             │
│ Hominid Class:              │  (Section header, 16px)
│ [Human/Neanderthal/etc.]    │  (14px, primary text)
│                             │
│ Traits:                     │  (Section header, 16px)
│ ┌─────────────────────────┐ │
│ │ Trait Name    │ Value   │ │  (Table/chart format)
│ │ Strength      │ +15     │ │
│ │ Intelligence  │ +8      │ │
│ │ Endurance     │ +12     │ │
│ │ ...           │ ...     │ │
│ └─────────────────────────┘ │
│                             │
│ [Inventory slots below]     │  (If inventory also open)
└─────────────────────────────┘
```

**Content Sections:**

1. **Header Section:**
   - **NPC Name**: Bold, 20px font, primary text color (`#e8e8e8`)
   - **Lineage**: Format: "son of [Father Name] Clan [Clan Name]"
     - Example: "son of GORAK Clan KOOK"
     - 14px font, secondary text color (`#b0b0b0`)
   - Padding: 16px top, 8px bottom

2. **Hominid Class Section:**
   - **Label**: "Hominid Class:" (16px, bold, primary text)
   - **Value**: Class name (Human, Neanderthal, Denisovan, etc.)
     - 14px font, primary text color
     - Optional: Small icon representing the hominid type
   - Padding: 8px top, 8px bottom

3. **Traits Table:**
   - **Label**: "Traits:" (16px, bold, primary text)
   - **Format**: Two-column table/chart
     - Left column: Trait name (14px, primary text)
     - Right column: Trait value (14px, primary text)
     - Values can be positive/negative (e.g., "+15", "-3")
     - Use green for positive, red for negative (optional)
   - **Table Style:**
     - Alternating row backgrounds (subtle, 10% opacity difference)
     - Border: 1px, secondary color
     - Padding: 4px per cell
   - **Traits to Display:**
     - Strength
     - Intelligence
     - Endurance
     - Speed/Agility
     - Other species-specific traits
   - Padding: 8px top, 16px bottom

**Visual Style:**
- Same panel style as all other UI elements
- Standard brown background (85% opacity)
- 2px border, 12px corner radius
- Shadow: 4px, 25% opacity

**Interaction:**
- Opens automatically when NPC is clicked
- Closes when:
  - ESC key pressed
  - Clicking outside the panel
  - Clicking another NPC
- NPC remains frozen (movement disabled) while menu is open
- NPC resumes normal behavior when menu closes

**Positioning:**
- Default: Right side of screen (centered vertically)
- If player inventory open: Left side of screen (to avoid overlap)
- If building inventory also open: Adjust position to fit all panels

**Integration with NPC Inventory:**
- Character Menu and NPC Inventory can be open simultaneously
- Character Menu shows above inventory slots if both are displayed
- Both panels share the same NPC reference
- Closing either panel does not close the other (independent toggles)

**Future Enhancements:**
- Family tree visualization (future)
- Detailed lineage history (future)
- Trait inheritance visualization (future)
- Comparison with other NPCs (future)

### Cart Inventory

**Trigger:** Click cart + I key  
**Layout:**
- Variable slots (typically 10-20)
- Position: Center of screen

**Visual:**
- Same panel style
- Larger capacity than NPCs

### Corpse Inventory (Looting System)

**Trigger:** I key (when near dead NPC/corpse, within 50px range)  
**Layout:**
- Uses BuildingInventoryUI (reuses same panel system)
- Variable slots (matches dead NPC's original inventory size)
- Position: Center-left of screen (left of player inventory when both open)
- Title: "Corpse of [NPC Name]" (displayed in header)

**Visual:**
- Same panel style as BuildingInventoryUI (brown background, no color change)
- Panel size varies based on slot count (different amounts of slots = different sizes)
- Displays all items from dead NPC's inventory
- All items from NPC's inventory and hotbar are preserved in corpse inventory (hotbar items combined into main inventory)

**Behavior:**
- Opens automatically when player presses I near a corpse (even if empty)
- Player inventory opens simultaneously (side-by-side layout)
- Player movement is disabled when inventory is open
- Drag-and-drop items from corpse inventory to player inventory (single item at a time)
- Corpse inventory closes when player inventory closes
- Dead NPCs are marked with `is_corpse` meta and added to "corpses" group
- Corpse sprite (`corpsecm.png`) replaces normal NPC sprite on death

**Corpse Decomposition System:**
- **60 seconds after death** (configurable for game balancing): Corpse sprite changes to `bonescm.png` (simulates decomposition/scavenging)
  - Inventory items are removed when corpse becomes bones (simulating animals scavenging)
- **60 seconds after becoming bones** (configurable for game balancing): Bones despawn completely from map
- **Empty inventory**: If corpse inventory is fully looted (empty), sprite immediately changes to `bonescm.png`
- **Visual feedback**: Subtle highlight/glow when player is within 50px range to loot (helps with proximity detection)
- **Resource Gathering**: Future feature - gathering from corpses (meat, bones, hide, sinew, etc.) will work like gathering from resource nodes, but requires special tools (blades and scrapers)

**Technical Details:**
- **Architecture**: Corpses are treated as a type of storage building in code (simplifies codebase by reusing building inventory systems)
- Corpse detection: Checks all nodes in "corpses" group within 50px range
- Closest corpse is selected if multiple are nearby (no cycling needed)
- Inventory preservation: NPC's inventory is preserved when they die (not cleared)
- Uses `nearby_corpse` variable in `main.gd` to track closest corpse
- BuildingInventoryUI's `setup_inventory()` method is called with corpse's inventory data
- Player character death: When player dies, their inventory becomes a lootable corpse (same as cavemen and clansmen)

---

## 4. Build Menu UI (Integrated)

**Status:** Building selection is now integrated into Building Inventory UI  
**Trigger:** I key (when near land claim)  
**Layout:**
- Single panel showing:
  - **Top Section**: Land Claim Inventory slots (6 vertical slots)
  - **Separator**: Horizontal line
  - **Bottom Section**: Building icons (horizontal row)
    - Icons grey out if insufficient resources
    - Click icon to build (consumes resources, adds item to player inventory)

**Building Icons:**
- Size: 48×48 pixels
- Spacing: 8px between icons
- Style: Standard panel style (brown background)
- Visual feedback: 
  - **Greyed out**: When player lacks sufficient resources to build
  - **Full color and brightness**: When player has required resources
- Hover: Slight brightness increase
- Icons are always visible at bottom of panel (integrated, not collapsible)

**Previous Build Menu:** The separate B key build menu has been removed. All building functionality is now accessible through the land claim inventory window.

See `guides/phase2/build_menu.md` for historical reference (now integrated).

---

## 5. Dialog Windows

### Clan Name Dialog

**Trigger:** First land claim placement  
**Layout:**
- AcceptDialog base
- Text input field (4 characters max, uppercase)
- Confirm/Cancel buttons

**Style:**
- Same panel style
- Centered on screen
- Auto-focus on text input

**Colors:**
- Background: Standard panel brown
- Input field: Lighter background, dark text
- Button: Standard brown, gold highlight on hover

---

## 6. Stats Panel (Future)

**Trigger:** Tab key (or separate key binding)  
**Layout:**
- Large panel (600×500px)
- Scrollable content area
- Sections:
  - Clan statistics
  - Species mix
  - Baby pool status
  - Raids/achievements

**Visual:**
- Same panel style
- Text-based (no icons)
- Organized by sections with headers

---

## 7. Debug UI (Development)

**NPCDebugUI:**
- Position: Top-left corner
- Style: Semi-transparent, minimal
- Content: NPC state, position, stats (debug info)
- Toggle: Debug mode key (if implemented)

**Visual:**
- Smaller font (10-12px)
- Dark background, light text
- Minimal borders

---

## 8. Text Styling

### Font Sizes

**Titles/Headers:**
- Size: **18-20px**
- Weight: **Bold**
- Color: Primary text (`#e8e8e8`)

**Body Text:**
- Size: **12-14px**
- Weight: **Normal**
- Color: Primary text (`#e8e8e8`)

**Secondary Text:**
- Size: **10-12px**
- Weight: **Normal**
- Color: Secondary text (`#b0b0b0`)

**Counts/Numbers:**
- Size: **12px**
- Weight: **Normal**
- Color: Primary text (or green/red for status)

### Font Recommendations

- Use system default fonts or game-appropriate pixel font
- Ensure readability at all sizes
- Consider font licensing if custom fonts used

---

## 9. Interaction Patterns

### Drag-and-Drop

**Visual Feedback:**
- Dragged item follows mouse cursor
- **Source slot**: Becomes semi-transparent when item is being dragged
- **Valid drop target**: Slot highlights with semi-transparent gold color (`#FFCE1B`) when mouse hovers over valid drop slot
- **Invalid drop target**: Slot shows semi-transparent red color (`#B31B1B`) when mouse hovers over invalid drop slot
- No tooltip while dragging (to avoid clutter)

**Drag Behavior:**
- **Single item transfer**: Only 1 item is transferred per drag (not entire stack)
  - Stack quantity updates immediately to show 1 item was removed
  - Simulates realistic time it takes to move items
  - Prevents unrealistic bulk transfers (e.g., moving 10 stones at once)
- **Stack handling**: When dragging from a stack, only 1 item moves, stack count decreases by 1
- **Buildings**: Can be dragged from player inventory to world map for placement
- **Regular items**: Cannot be dropped on world map (only in inventories)
- **Drag cancellation**: Players can cancel a drag by dropping item on world map (outside inventory slot menus)
- **Inventory reorganization**: Players can move items around within their own inventory (drag-and-drop between own slots)
- **No quick transfer**: Only drag-and-drop, no double-click or Shift+click shortcuts

**Inventory Interaction Mode:**
- When inventory screen (I key) is open, player can ONLY interact with inventory items
- World map interactions are disabled to prevent menu stacking
- Exception: Buildings can still be dragged from inventory to world map for placement
- This ensures clean, focused inventory management without accidental world interactions

**Supported Drag-and-Drop:**
- Player inventory ↔ Building inventory (land claims)
- Player inventory ↔ NPC inventory
- Player inventory ↔ Corpse inventory (looting)
- Player inventory ↔ Ground items
- Building inventory ↔ Ground items
- NPC inventory ↔ Ground items
- Corpse inventory ↔ Ground items
- Player inventory → World map (buildings only)

**Audio (Future):**
- Pick up sound (subtle)
- Drop sound (different for valid/invalid)

### Hover States

**Panel Elements:**
- Slightly lighter background on hover
- Cursor changes to pointer
- Subtle scale increase (1.05x) on buttons

**Inventory Slots:**
- Border highlight (lighter brown)
- Tooltip if available (future enhancement)

### Click States

**Buttons:**
- Pressed: Darker background
- Released: Return to normal
- Disabled: Grayed out, no interaction

### Selection States

**Selected Item:**
- Gold/yellow border highlight
- Slightly brighter background

---

## 10. Positioning Standards

### Screen Layout Zones

```
┌─────────────────────────────────────────┐
│ Top: Debug info, notifications          │
│                                         │
│ Left:    Center:         Right:         │
│ Build    Player Inv      Character      │
│ Menu     (or Build)      Menu (NPC)     │
│          NPC Inv         Building       │
│                         Selection       │
│                                         │
│ Bottom: Hotbar (always visible)         │
└─────────────────────────────────────────┘
```

### Panel Positioning

**Centered Panels:**
- Player inventory: Center screen
- NPC inventory: Center screen (when Character Menu open, may shift left)
- Dialogs: Center screen

**Side Panels:**
- Building inventory: Left of center (if player inventory open)
- Character Menu: Right side (when NPC clicked)
- Build menu building list: Right side (integrated into Building Inventory)
- Stats panel: Right side (when implemented)

**Fixed Panels:**
- Hotbar: Bottom center (always visible)
- Debug UI: Top-left (dev mode only)

### Z-Order (Layer Priority)

1. **Top Layer**: Dialogs, popups (highest priority)
2. **Menu Layer**: Inventories, menus
3. **HUD Layer**: Hotbar, stats panel
4. **Debug Layer**: Debug UI (lowest priority)

---

## 11. Responsive Considerations

### Screen Size Assumptions

**Minimum:**
- Width: 1280px
- Height: 720px

**Standard:**
- Width: 1280px (current)
- Height: 720px (current)

**Scalability:**
- All sizes scale with screen resolution (not fixed pixels)
- Panels scale proportionally at different resolutions
- Text size scales with menu size, menu size scales with screen size
- UI elements maintain aspect ratios when scaling

---

## 12. Animation Standards

### Transitions

**Panel Open/Close:**
- Fade in/out: 0.2 seconds
- Optional: Slide from edge (0.3 seconds)

**Slot Updates:**
- Instant (no animation for performance)

**Button Press:**
- Scale: 0.95x on press, 1.0x on release (0.1 seconds)

### Animation Philosophy

- Keep animations subtle and quick
- Don't obstruct gameplay
- Performance over flashy effects

---

## 13. Accessibility (Future)

### Accessibility Features

**Text Scaling:**
- Text size scales with menu size
- Menu size scales with screen size
- UI elements scale with screen resolution

**Color Blind Support:**
- Not implemented (single Stone Age aesthetic)
- Visual indicators use icons + colors where applicable

**Other Accessibility:**
- High contrast mode: Not implemented
- Screen reader support: Not implemented
- Colorblind-friendly indicators: Not implemented

### Keyboard Navigation

- All menus accessible via keyboard
- Tab key cycles through elements
- Enter/Return activates buttons
- ESC closes menus
- **Key Rebinding**: All keyboard shortcuts are rebindable (including I for inventory, Tab for stats)
- **Controller Support**: Planned for future implementation

---

## 14. UI Element Checklist

When creating a new UI element, ensure:

- [ ] Uses standard panel style (brown, 85% opacity)
- [ ] 12px corner radius
- [ ] 2px border (saddle brown)
- [ ] Shadow (4px, 25% opacity black)
- [ ] Standard text colors and sizes
- [ ] Consistent padding (8px or 16px)
- [ ] Drag-and-drop support (if applicable)
- [ ] Keyboard shortcuts (if applicable)
- [ ] Proper positioning (doesn't overlap awkwardly)
- [ ] Hover/selection states
- [ ] Close/toggle behavior (ESC key support)

---

## 15. Current UI Elements Reference

### Implemented

1. **PlayerInventoryUI** (`scripts/inventory/player_inventory_ui.gd`)
   - Tab key toggle
   - 5 slots + 5-slot hotbar (reduced from 10)
   - Standard panel style ✓
   - Deposit trigger: 80% full

2. **BuildingInventoryUI** (`scripts/inventory/building_inventory_ui.gd`)
   - I key (near land claim)
   - 6 slots
   - Standard panel style ✓

3. **NPCInventoryUI** (`scripts/inventory/npc_inventory_ui.gd`)
   - Click NPC + I key
   - 5 slots (reduced from variable)
   - Hotbar items combined with main inventory
   - Standard panel style ✓
   - Deposit trigger: 80% full

4. **CharacterMenuUI** (Planned - `scripts/ui/character_menu_ui.gd`)
   - Click NPC (auto-opens)
   - NPC info display (name, lineage, hominid class, traits)
   - Standard panel style
   - Freezes NPC movement when open

5. **ClanNameDialog** (`ui/clan_name_dialog.gd`)
   - AcceptDialog base
   - Text input (4 char max)
   - Standard dialog style ✓

6. **NPCDebugUI** (`scripts/npc/npc_debug_ui.gd`)
   - Debug info display
   - Minimal style

### Planned (Phase 2+)

1. **CharacterMenuUI** (Planned)
   - Click NPC (auto-opens)
   - NPC name, lineage, hominid class, traits table
   - Freezes NPC movement
   - See Character Menu section above for details

2. **BuildMenuUI** (`scripts/ui/build_menu_ui.gd`)
   - ~~B key (inside land claim)~~ **REMOVED** - Building icons now integrated into Building Inventory UI
   - Building selection integrated into land claim inventory

3. **StatsPanel** (Future)
   - Tab key or separate key
   - Large info panel
   - Statistics display

4. **ClanMenu** (Future)
   - C key (mentioned in docs)
   - Clan management
   - Baby pool info

5. **Corpse Looting System** (Implemented - January 2026)
   - I key (when near dead NPC/corpse, 50px range)
   - Uses BuildingInventoryUI to display corpse inventory
   - Title: "Corpse of [NPC Name]"
   - Drag-and-drop looting from corpse to player (single item at a time)
   - All NPC inventory items preserved on death
   - Corpse decomposition: 60s to bones, 60s to despawn
   - Empty corpses show bones sprite immediately
   - Standard panel style ✓

---

## 16. Code Style Guidelines

### Naming Conventions

**UI Classes:**
- Suffix: `UI` (e.g., `PlayerInventoryUI`, `BuildMenuUI`)
- Base classes: `InventoryUI`, etc.

**UI Nodes:**
- Panels: `InventoryPanel`, `HotbarPanel`
- Containers: `SlotContainer`, `CardsContainer`
- Buttons: `ConfirmButton`, `CancelButton`

**Variables:**
- Panel references: `inventory_panel`, `hotbar_panel`
- Containers: `inventory_container`, `cards_container`
- Slots: `slots: Array[InventorySlot]`

### Code Patterns

**Panel Setup:**
```gdscript
func _setup_panel() -> void:
    panel = Panel.new()
    panel.custom_minimum_size = Vector2(PANEL_WIDTH, PANEL_HEIGHT)
    
    var style: StyleBoxFlat = StyleBoxFlat.new()
    style.bg_color = Color(0x1a / 255.0, 0x15 / 255.0, 0x12 / 255.0, 0.85)
    # ... (standard style setup)
    panel.add_theme_stylebox_override("panel", style)
```

**Consistent Style Function:**
- Consider creating `UITheme.get_panel_style()` helper function
- All UI elements call same function for consistency

---

## 17. Visual Reference

### Color Values Summary

| Element | Color | RGB | Hex | Opacity |
|---------|-------|-----|-----|---------|
| Panel BG | Dark Brown | 26, 21, 18 | #1a1512 | 85% |
| Border | Saddle Brown | 139, 69, 19 | #8b4513 | 90% |
| Shadow | Black | 0, 0, 0 | #000000 | 25% |
| Primary Text | Off-white | 232, 232, 232 | #e8e8e8 | 100% |
| Secondary Text | Light Gray | 176, 176, 176 | #b0b0b0 | 100% |
| Error | Red | 211, 47, 47 | #d32f2f | 100% |
| Success | Green | 102, 187, 106 | #66bb6a | 100% |
| Selected | Gold | 255, 167, 38 | #ffa726 | 100% |

### Size Reference Summary

| Element | Width | Height | Notes |
|---------|-------|--------|-------|
| Standard Panel | 320px | 400px | Inventories |
| Hotbar Panel | Variable | 64px | Based on slots |
| Dialog Panel | 400px | Variable | Content-based |
| Character Menu | 400px | 500px | NPC info panel |
| Large Panel | 600px | 500px | Stats/info |
| Slot Size | 32px | 32px | Standard |
| Slot Spacing | 0-6px | 0-6px | Varies by layout |
| Padding | 8-16px | 8-16px | Panel-dependent |
| Corner Radius | 12px | 12px | All panels |

---

## 18. Future Enhancements

### Planned UI Elements

- **Clan Menu** (C key): Clan overview, baby pool display
- **Stats Panel** (Tab or separate key): Detailed statistics
- **Settings Menu**: Audio, controls, graphics
- **Tooltips**: Hover information on UI elements
- **Notifications**: Temporary messages (top of screen)
- **Loading Screen**: Game startup/loading

### Style Improvements

- **Custom Font**: Stone age-appropriate pixel font
- **Icons**: Consistent icon set for all resources/buildings
- **Animations**: Subtle panel transitions
- **Sound Effects**: UI interaction audio

---

## 19. Consistency Checklist

Before adding new UI elements, verify:

- [ ] Colors match standard palette
- [ ] Panel style uses standard StyleBoxFlat
- [ ] Text sizes follow hierarchy (18-20px titles, 12-14px body)
- [ ] Padding is consistent (8px or 16px)
- [ ] Corner radius is 12px
- [ ] Shadow is 4px, 25% opacity
- [ ] Border is 2px, saddle brown
- [ ] Positioning doesn't overlap awkwardly
- [ ] Keyboard shortcuts don't conflict
- [ ] ESC closes/menu (if applicable)
- [ ] Hover/selection states are implemented
- [ ] Drag-and-drop works (if applicable)

---

This document serves as the **single source of truth** for UI design standards.  
All UI elements must follow these guidelines for consistency across the game.  
Update this document when new patterns or standards are established.


### Positive Aspects of Your Current UI Outline
Your UI standards document is already a strong foundation—it's comprehensive, well-organized, and emphasizes consistency through shared styles (e.g., the StyleBoxFlat setup in GDScript) and a cohesive Stone Age aesthetic. The earthy color palette, semi-transparent panels, and drag-and-drop focus align well with an RPG-inspired game, evoking simplicity and immersion like in survival-RPGs (e.g., Valheim or early Minecraft mods). Principles like visual feedback, keyboard shortcuts, and overlapping panels support quick, intuitive gameplay without pulling players out of the world. The checklist sections (e.g., UI Element Checklist, Consistency Checklist) are excellent for maintaining standards as you iterate.

However, to streamline, scale, simplify, and enhance understandability while keeping RPG consistency, here are targeted advice points. I'll break them down by category, drawing directly from your outline.

### Streamlining the UI
Your current setup has detailed specs for various panels and elements, but some areas could be consolidated to reduce complexity and development overhead. Streamlining means fewer unique rules, more reusable components, and prioritizing core RPG interactions (e.g., inventory management, building, stats).

- **Consolidate Panel Types**: You have multiple panel sizes (e.g., 320x400 for inventories, 600x500 for stats, variable for dialogs). Reduce to 2-3 modular templates: Small (e.g., 320x variable height for quick views like NPC inventories), Medium (400x variable for dialogs/menus), and Large (scalable 600+ for stats/build menus). Use Godot's Container nodes (e.g., VBoxContainer with auto-sizing) to make heights dynamic based on content, avoiding fixed heights that might overflow on different devices.
  
- **Simplify Inventory Variations**: Player, Building, NPC, and Cart inventories all share similar structures but have slight differences (e.g., slot counts, triggers). Unify them under a single `InventoryUI` base class with configurable params (e.g., slot_count, layout_orientation). This cuts redundant code—e.g., instead of separate scripts like `player_inventory_ui.gd` and `npc_inventory_ui.gd`, extend from a base and override only triggers/positions. For RPG feel, add a quick-swap hotkey (e.g., number keys for hotbar) to all, inspired by games like Skyrim.

- **Merge Related Menus**: The Build Menu (B key) opens two panels (Land Claim Inventory + Building Selection). Consider combining into one tabbed or split-view panel to reduce screen clutter. Similarly, integrate Stats Panel (future) with Clan Menu for a unified "Clan Overview" accessible via one key (e.g., C for Clan/Stats toggle). This streamlines navigation, making it feel more like a cohesive RPG hub.

- **Trim Debug and Future Elements**: Move NPCDebugUI and planned features (e.g., Tooltips, Notifications) to a separate "Advanced/Phase 3" section in your doc. Focus core implementation on essentials first—inventories, dialogs, build menu—to avoid scope creep.

### Making It Scalable
Your outline assumes fixed pixels (e.g., 1280x720 min resolution), which works for desktop but limits scalability to mobiles or ultra-wide screens. RPGs like Genshin Impact scale UI dynamically for cross-platform play.

- **Switch to Relative Sizing**: Replace fixed widths/heights with percentages or anchors. In Godot, use Control nodes with `anchor_*` properties (e.g., anchor inventory to 50% screen width). For slots, use a GridContainer with adaptive cell sizes (e.g., min 32px, but scale to 48px on larger screens). This ensures panels don't clip or feel tiny on 4K monitors.

- **Modular Code for Expansion**: Your GDScript examples (e.g., `_setup_panel()`) are good—expand to a central `UITheme.gd` singleton with functions like `get_panel_style(size_type: String) -> StyleBoxFlat`. This allows easy tweaks (e.g., change all corner radii globally) and supports future themes (e.g., "Winter Update" palette). For RPG scalability, design slots to handle variable item types (e.g., stackable resources vs. unique gear) via data-driven configs (e.g., a JSON file for item icons/sizes).

- **Resolution Independence**: Add a UI scaling factor in settings (e.g., 0.8x-1.5x). Test with Godot's stretch modes (e.g., `Viewport` scaling). For overlapping panels, implement auto-repositioning logic (e.g., if two panels overlap >50%, shift one right by 20%).

- **Performance Considerations**: With animations (e.g., 0.2s fades), add toggles for low-end devices. Use Godot's Tween for smooth scaling without lag.

### Simplifying and Improving Understandability
The Stone Age philosophy (simple, functional) is spot-on for an RPG, but some specs (e.g., multiple text colors, detailed hovers) could overwhelm new players. Aim for "at-a-glance" clarity like in Zelda: Breath of the Wild—minimal text, strong visuals.

- **Reduce Visual Complexity**: Limit text colors to 3-4 max (e.g., merge Secondary Text with Hints; use icons for Success/Error instead of just color). For building cards, shorten descriptions to 1-2 lines and use tooltips for details (as planned). Add universal icons (e.g., wood log for resources) to make inventories scannable without reading.

- **Intuitive Triggers and Feedback**: Standardize keys (e.g., I for all inventories, B for Build, C for Clan/Stats). Add on-screen prompts (e.g., "Press I to Open" near interactables) for first-time users. Enhance drag-and-drop with snap-to-grid and undo (e.g., Ctrl+Z), making it forgiving like in Diablo's inventory.

- **Clear Layouts**: Use consistent zones (as in your Screen Layout Zones diagram)—e.g., always bottom for hotbar, center for mains. For understandability, add a quick tutorial overlay on first open (e.g., "Drag items to equip"). Group related info (e.g., in Stats Panel, use accordions for sections like "Species Mix" to avoid info overload).

- **Accessibility Boosts**: Build on your future plans—implement color-blind modes now (e.g., patterns for red/green). Ensure all text is >=12px and high-contrast (your #e8e8e8 on #1a1512 is good, ratio ~15:1).

### Ensuring Consistency with the Game
Your RPG-inspired game benefits from UI that feels like an extension of the world—rustic, immersive, not modern.

- **Thematic Alignment**: Reinforce Stone Age vibes by adding subtle textures (e.g., wood-grain overlay on panels via Godot shaders) without complicating the palette. Ensure all elements tie back to gameplay loops (e.g., inventories support crafting/building, stats reflect clan progression).

- **Consistency Tools**: Leverage your checklists—make them mandatory in code reviews. Add a "UI Audit" script in Godot to scan scenes for non-standard styles (e.g., check border widths). For RPG consistency, benchmark against similar games: Ensure menus pause/resume smoothly, and hotbar is always accessible during combat/exploration.

- **Testing Advice**: Prototype with placeholders—build a demo scene with all panels open to check overlaps. User-test for confusion (e.g., "Is drag-and-drop obvious?"). Iterate based on feedback, updating the doc as a living reference.

### Quick Wins Summary Table
Here's a prioritized list of changes to implement:

| Priority | Change | Impact |
|----------|--------|--------|
| High | Unify inventory classes under one base | Streamlines code, reduces bugs |
| High | Switch to relative sizing/anchors | Improves scalability across devices |
| Medium | Limit text colors to 3-4; add icons | Simplifies visuals, boosts understandability |
| Medium | Create `UITheme.gd` singleton | Ensures global consistency |
| Low | Add on-screen prompts/tutorials | Eases onboarding for RPG newbies |

Overall, your outline is 80% there—focus on modularity and player testing to refine. If you share more details (e.g., specific pain points or Godot scenes), I can give more tailored advice!

---

## 20. Future Enhancements & Open Questions

### Planned Features (Not Yet Implemented)

**Inventory Management:**
- **Auto-sort**: Code structure to allow sorting (by type, by name) - not implemented in test version
- **Search/Filter**: Code structure to allow search/filter for large inventories - not implemented in test version
- **Tooltips**: Code structure to allow tooltips with item name, description, stats on hover - not implemented in test version
- **Expandable Inventories**: 
  - Backpacks and other items will dynamically add more slots to inventory
  - Backpack is worn on last hotbar square (visually shows on character's back)
  - When I inventory is open, additional slots become visible on screen
  - Menu dynamically resizes to fit all slots
  - Individual slots are visibly separate so player can see how many slots are left empty
- **Hominid Strength**: Different hominid species will have different carry capacity slots (simulating strength) - implementation details to be determined when feature is added

**Combat/Death UI:**
- **Death Notification**: No UI popup notification - only visual sprite change when NPC dies
- **Clan Menu Integration**: When clan menu is added, will display all living members; when one dies, status will show as "dead"
- **Health Bars**: Hidden during combat for immersion (no health bars visible for enemies)
- **Enemy Visibility**: In final game, enemy inventories and states will not be visible to player (currently enabled for testing/development via click-and-hold)
- **Clan Member Visibility**: Player's own clan members will show stats, inventories, and health bars
- **Resource Gathering from Corpses**: Future feature to gather resources from corpses (meat, bones, hide, sinew, etc.)
  - Works like gathering from resource nodes
  - Requires special tools (blades and scrapers)

**Visual/Audio Feedback:**
- **Subtle Animations**: Fun, subtle animations for inventory interactions
- **Auditory Aids**: Sound effects for drag-and-drop, item transfers, etc.

### Open Questions for Future Discussion

1. **Controller Support for Drag-and-Drop**: When implementing controller support, how should drag-and-drop work?
   - What is most common and efficient in other RPG games that use drag-and-drop?
   - Cursor mode with controller?
   - Grid-based selection with D-pad?
   - Button-based quick transfer?
   - **Note**: Controller support is required for future implementation

2. **Mobile Touch Drag-and-Drop**: For future mobile/touch support, how should drag-and-drop work?
   - What is most common and efficient in other RPG games that use drag-and-drop?
   - Tap-and-hold to start drag?
   - Separate drag mode toggle?
   - Gesture-based interactions?
   - **Note**: Touch support is required for future implementation

3. **Hominid Strength Display**: When different hominids have different carry capacities, how should this be displayed?
   - Visible in the inventory UI (e.g., "5/8 slots")?
   - Only visible in character menu/stats?
   - Both?
   - **Note**: Implementation details to be determined when feature is added

4. **Backpack Visual Integration**: When a backpack is equipped (last hotbar slot), should the visual representation:
   - Always show on character's back in world view?
   - Only show when inventory is open?
   - Have different visual states (empty vs. full)?

5. **Corpse Resource Gathering Tools**: When implementing resource gathering from corpses, should the required tools (blades, scrapers):
   - Be consumed/damaged during gathering?
   - Have durability that decreases?
   - Be specific tool types or any sharp tool?

6. **Player Death Corpse Behavior**: When player character dies and becomes a lootable corpse:
   - Should it have a special visual indicator (different from NPC corpses)?
   - Should it persist longer than NPC corpses?
   - How does this interact with the generational permadeath system (next generation can loot previous)?

7. **Inventory Reorganization Feedback**: When players reorganize items within their own inventory:
   - Should there be visual/audio feedback for successful moves?
   yes
   - Should there be an "undo" option for accidental moves?
   no a player can just drag and drop it back
   - Should items snap to grid or allow free positioning?
   snap it the grid, the grid should be visible, visible slots like the hotbar looks. consistancy

8. **Configurable Values System**: For game balancing values (corpse decomposition timers, etc.):
   - Should these be in a centralized config file?
   - Should they be editable in-game (dev mode) or only in config files?
   these should be in a dev menu relating to resource spawns, npcs spawns, etc. add this info to dev_menu.md if needed

---

**Note**: These questions are for discussion and future refinement. Current implementation follows the standards outlined in this document, but these questions may inform future enhancements or design decisions.

**Controller & Touch Support Research Needed:**
- Research common patterns in RPG games with drag-and-drop inventory systems
- Document best practices for controller-based inventory management
- Document best practices for touch/mobile drag-and-drop interactions
- Consider accessibility and ease of use across different input methods