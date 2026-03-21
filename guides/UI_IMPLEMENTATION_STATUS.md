# UI Implementation Status

**Date**: January 2026  
**Purpose**: Track implementation status of UI features from UI.md specification

---

## ✅ Already Implemented

1. **Single Item Transfer** - `drag_manager.gd` already implements single item transfer (lines 41-48)
   - When dragging from a stack, only 1 item is transferred
   - Stack count is reduced by 1 in source slot
   - ✅ Working correctly

2. **Corpse Looting System** - Basic implementation exists
   - Corpse detection system in place
   - Inventory preservation on death
   - BuildingInventoryUI used for corpse inventory
   - ⚠️ Needs updates (see below)

---

## 🔧 Needs Implementation/Updates

### High Priority

1. **Corpse Interaction Range** - `scripts/main.gd:152`
   - Current: 100px
   - Required: 50px
   - File: `scripts/main.gd`
   - Line: 152 (`closest_distance := 100.0`)

2. **Player Inventory Size** - `scripts/inventory/player_inventory_ui.gd`
   - Current: 10 slots (`SLOT_COUNT := 10`)
   - Required: 5 slots
   - File: `scripts/inventory/player_inventory_ui.gd`
   - Line: 7

3. **Player Hotbar Size** - `scripts/inventory/player_inventory_ui.gd`
   - Current: 10 slots (`HOTBAR_COUNT := 10`)
   - Required: 5 slots
   - File: `scripts/inventory/player_inventory_ui.gd`
   - Line: 8

4. **NPC Inventory Size** - `scripts/npc/npc_base.gd`
   - Current: 10 slots for caveman/woman/human
   - Required: 5 slots
   - File: `scripts/npc/npc_base.gd`
   - Lines: 754-757

5. **Deposit Trigger** - Need to find where this is checked
   - Current: Unknown (need to search)
   - Required: 80% full (4 out of 5 slots)
   - Files to check: `scripts/npc/npc_base.gd`, `scripts/npc/states/gather_state.gd`

### Medium Priority

6. **Corpse Title** - `scripts/inventory/building_inventory_ui.gd`
   - Current: No title displayed
   - Required: "Corpse of [NPC Name]"
   - File: `scripts/inventory/building_inventory_ui.gd`
   - Need to add title label/header

7. **Visual Feedback: Source Slot Semi-Transparency** - `scripts/inventory/inventory_slot.gd`
   - Current: Not implemented
   - Required: Source slot becomes semi-transparent when dragging
   - File: `scripts/inventory/inventory_slot.gd`
   - Need to add modulate/alpha change when slot is source of drag

8. **Visual Feedback: Valid Drop Target** - `scripts/inventory/inventory_slot.gd`
   - Current: Not implemented
   - Required: Highlight with semi-transparent gold (`#FFCE1B`) when mouse hovers over valid drop slot
   - File: `scripts/inventory/inventory_slot.gd`
   - Need to add hover detection and color overlay

9. **Visual Feedback: Invalid Drop Target** - `scripts/inventory/inventory_slot.gd`
   - Current: Not implemented
   - Required: Show semi-transparent red (`#B31B1B`) when mouse hovers over invalid drop slot
   - File: `scripts/inventory/inventory_slot.gd`
   - Need to add hover detection and color overlay

10. **Drag Cancellation** - `scripts/inventory/drag_manager.gd` and `scripts/main.gd`
    - Current: Items can be dropped on world (for buildings)
    - Required: Regular items can be cancelled by dropping on world map (outside inventory slots)
    - Files: `scripts/inventory/drag_manager.gd`, `scripts/main.gd`
    - Need to handle world drop for non-building items as cancellation

11. **Inventory Reorganization** - Should already work, but verify
    - Current: Unknown if drag within own inventory works
    - Required: Players can move items around within their own inventory
    - Files: `scripts/inventory/drag_manager.gd`, `scripts/inventory/player_inventory_ui.gd`
    - Need to verify and test

### Low Priority

12. **Corpse Range Visual Feedback** - `scripts/main.gd` or visual system
    - Current: No visual feedback
    - Required: Subtle highlight/glow when player is within 50px range of corpse
    - Files: `scripts/main.gd`, possibly need visual indicator system
    - Could use shader, sprite overlay, or particle effect

13. **Corpse Decomposition System** - `scripts/npc/components/health_component.gd`
    - Current: Basic death system exists
    - Required: 
      - 60 seconds to bones (configurable)
      - 60 seconds bones despawn (configurable)
      - Empty inventory = bones sprite immediately
    - File: `scripts/npc/components/health_component.gd`
    - Need to add timers and sprite switching logic

---

## 📋 Implementation Checklist

### Phase 1: Inventory Size Updates
- [ ] Update player inventory from 10 to 5 slots
- [ ] Update player hotbar from 10 to 5 slots
- [ ] Update NPC inventory (caveman/woman/human) from 10 to 5 slots
- [ ] Update deposit trigger to 80% (4/5 slots)
- [ ] Test inventory functionality with new sizes

### Phase 2: Corpse System Updates
- [ ] Change corpse interaction range from 100px to 50px
- [ ] Add "Corpse of [NPC Name]" title to BuildingInventoryUI
- [ ] Add subtle highlight when in range of corpse
- [ ] Implement corpse decomposition timers (60s to bones, 60s to despawn)
- [ ] Implement empty inventory = bones sprite immediately

### Phase 3: Drag-and-Drop Visual Feedback
- [ ] Add source slot semi-transparency when dragging
- [ ] Add valid drop target highlight (#FFCE1B)
- [ ] Add invalid drop target highlight (#B31B1B)
- [ ] Test visual feedback with all inventory types

### Phase 4: Drag Cancellation & Reorganization
- [ ] Implement drag cancellation by dropping on world map
- [ ] Verify inventory reorganization works (drag within own inventory)
- [ ] Test drag cancellation for all item types

---

## 🔍 Files to Modify

### Core Inventory Files
- `scripts/inventory/player_inventory_ui.gd` - Player inventory size, hotbar size
- `scripts/inventory/npc_inventory_ui.gd` - NPC inventory UI (if separate from base)
- `scripts/inventory/building_inventory_ui.gd` - Corpse title, visual feedback
- `scripts/inventory/inventory_slot.gd` - Visual feedback (semi-transparency, highlights)
- `scripts/inventory/drag_manager.gd` - Drag cancellation, single item transfer (already done)

### NPC Files
- `scripts/npc/npc_base.gd` - NPC inventory size, deposit trigger
- `scripts/npc/components/health_component.gd` - Corpse decomposition system
- `scripts/npc/states/gather_state.gd` - Deposit trigger check (if applicable)

### Main Game Files
- `scripts/main.gd` - Corpse interaction range, drag cancellation handling

---

## 🎨 Visual Feedback Implementation Notes

### Color Values
- Valid drop target: `Color("#FFCE1B")` - Semi-transparent gold
- Invalid drop target: `Color("#B31B1B")` - Semi-transparent red
- Source slot: `modulate = Color(1, 1, 1, 0.5)` - 50% opacity

### Implementation Approach
1. **Source Slot Semi-Transparency**: 
   - When drag starts, set source slot `modulate` to 50% opacity
   - When drag ends, restore to full opacity

2. **Valid/Invalid Drop Highlights**:
   - On mouse enter slot: Check if drop is valid
   - If valid: Add color overlay with `#FFCE1B` at ~30% opacity
   - If invalid: Add color overlay with `#B31B1B` at ~30% opacity
   - On mouse exit: Remove overlay

3. **Corpse Range Highlight**:
   - When player is within 50px of corpse, add subtle glow/shader effect
   - Could use `modulate` with slight brightness increase
   - Or add a small particle effect/sprite overlay

---

## 🧪 Testing Checklist

After implementation, test:
- [ ] Player inventory has 5 slots
- [ ] Player hotbar has 5 slots
- [ ] NPC inventory has 5 slots
- [ ] Deposit trigger works at 4/5 slots (80%)
- [ ] Corpse interaction works at 50px range
- [ ] Corpse title shows "Corpse of [NPC Name]"
- [ ] Source slot becomes semi-transparent when dragging
- [ ] Valid drop targets highlight in gold
- [ ] Invalid drop targets highlight in red
- [ ] Drag cancellation works by dropping on world
- [ ] Inventory reorganization works (drag within own inventory)
- [ ] Single item transfer works (not entire stack)
- [ ] Corpse decomposition timers work (60s to bones, 60s despawn)
- [ ] Empty corpse shows bones sprite immediately

---

## 📝 Notes

- Single item transfer is already implemented in `drag_manager.gd` (lines 41-48)
- Drag-and-drop system is functional, needs visual polish
- Corpse system is basic but functional, needs enhancements
- All inventory size changes are straightforward constant updates
- Visual feedback will require new code in `inventory_slot.gd`
