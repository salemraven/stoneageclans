# Battle Royale Playtest Readiness Checklist

**Date**: January 2026  
**Purpose**: Verify all systems are ready for battle royale combat playtest

## ⚠️ Battle Royale Requirements
- ✅ **Land claims disabled** for Battle Royale minigame
- ✅ **No wild NPCs spawned** for Battle Royale minigame (only 6 cavemen)

---

## ✅ UI Updates Status

### Inventory Sizes
- ✅ Player inventory: **5 slots** (reduced from 10)
- ✅ Player hotbar: **10 slots** (equipment slots with large transparent numbers)
- ✅ NPC inventory: **5 slots** (reduced from 10)
- ✅ Deposit trigger: **80% full** (4 out of 5 slots)

### Corpse System
- ✅ Corpse interaction range: **50px** (reduced from 100px)
- ✅ Corpse title: **"Corpse of [NPC Name]"** displayed in BuildingInventoryUI
- ✅ Corpse sprite: **corpsecm.png** on death
- ✅ **Character info display**: Shows name, type, and death info (killed by, weapon, clan)
- ✅ **Building icons hidden** for corpse inventories (only shown on land claims)
- ✅ **Corpse range visual highlight**: Subtle glow when player within 50px (warm yellow tint, 15% brightness increase)
- ⚠️ Corpse decomposition timers: Not yet implemented (60s to bones, 60s despawn)

### Drag-and-Drop
- ✅ Single item transfer: **1 item per drag** (not entire stack)
- ✅ Source slot semi-transparency: **50% opacity** when dragging
- ✅ Valid drop target highlight: **#FFCE1B gold** at 30% opacity
- ✅ Invalid drop target highlight: **#B31B1B red** at 30% opacity
- ✅ Drag cancellation: **Dropping on world map cancels drag** (restores item)
- ✅ Inventory reorganization: **Works** (drag within own inventory)
- ✅ **Corpse inventory drag-and-drop**: Fixed - can drag items from corpse to player inventory

### Hotbar System
- ✅ 10-slot hotbar with equipment labels
- ✅ Large transparent numbers (1-0) centered in slots
- ✅ Equipment slots: 1=right hand, 2=left hand, 3=head, 4=body, 5=legs, 6=feet, 7=neck, 8=backpack, 9=consumable, 0=consumable
- ✅ Number key presses: **9 and 0** consume items from hotbar slots
- ✅ NPCs have 10-slot hotbar (cavemen and clansmen)
- ✅ **NPCs can eat from hotbar**: NPCs check both inventory and hotbar (slots 9 and 0) for food

---

## ✅ Battle Royale Setup

### Spawn Configuration
- ✅ **6 cavemen** spawn in circle around center
- ✅ Spawn radius: **200-300px** from center
- ✅ All cavemen have **max agro (100.0)** - fight immediately
- ✅ All cavemen spawn with **axe in inventory**
- ✅ All cavemen have **axe equipped** (sprite: `male1a.png`)

### Combat System
- ✅ Health: **30 HP** (3 hits to kill)
- ✅ Damage: **10 per hit** (base damage)
- ✅ Death system: NPCs die after 3 hits
- ✅ Corpse sprite: **corpsecm.png** on death
- ✅ Dead NPCs stop acting (no movement, no herding, no gathering)

### Looting System
- ✅ Corpse inventory preserved on death
- ✅ Press **I** near corpse (50px range) to open inventory
- ✅ Drag-and-drop items from corpse to player inventory
- ✅ Corpse title shows "Corpse of [NPC Name]"
- ✅ All items from NPC inventory available for looting

### Disabled Systems (for combat test)
- ✅ Land claims disabled (player cannot place)
- ✅ NPC land claim building disabled
- ✅ Agro system bypassed (max agro set directly)
- ✅ **World interactions blocked** when inventory is open (no clicking land claims, NPCs, or attacking)

---

## ⚠️ Not Yet Implemented (Non-Critical for Playtest)

1. **Corpse Decomposition Timers**
   - 60 seconds to bones (corpsecm.png → bonescm.png)
   - 60 seconds bones despawn
   - Empty inventory = bones sprite immediately

---

## 🎮 Battle Royale Controls

### Player Controls
- **WASD / Arrow Keys**: Move
- **I**: Open inventory (player + nearby building/corpse)
- **Tab**: Toggle player inventory
- **9**: Consume item from hotbar slot 9
- **0**: Consume item from hotbar slot 0
- **Click NPC**: Attack (if weapon in hotbar slot 1)
- **Click + Hold NPC**: Open NPC inventory (debug/testing)

### Combat
- Click on NPC to attack (if weapon equipped)
- 3 hits to kill NPCs
- Dead NPCs become lootable corpses
- Press I near corpse to loot

### Inventory Management
- Drag-and-drop items between inventories
- Single item transfer (1 item per drag)
- Drag on world map to cancel (restores item)
- Reorganize items within own inventory

---

## 🧪 Testing Checklist

### Pre-Playtest Verification
- [ ] Game starts without errors
- [ ] 6 cavemen spawn with axes
- [ ] All cavemen have max agro (100.0)
- [ ] All cavemen show axe sprite (male1a.png)
- [ ] Player inventory has 5 slots
- [ ] Player hotbar has 10 slots with numbers
- [ ] NPC inventory has 5 slots

### Combat Testing
- [ ] Player can attack NPCs (click with weapon)
- [ ] NPCs attack each other (auto-combat)
- [ ] 3 hits kills NPCs
- [ ] Dead NPCs show corpse sprite (corpsecm.png)
- [ ] Dead NPCs stop moving/acting
- [ ] Dead NPCs don't participate in herding/gathering

### Looting Testing
- [ ] Press I near corpse (50px range) opens inventory
- [ ] **Corpse shows subtle glow** when player within 50px range
- [ ] Corpse title shows "Corpse of [NPC Name]"
- [ ] **Character info displays**: Name, Type, and "Killed by: XXXX of the clan XX XXXX by Axe" (or "Killed by: XXXX by Axe" if no clan)
- [ ] **Building icons are hidden** on corpse inventory (only inventory slots visible)
- [ ] Corpse inventory contains all NPC items
- [ ] Can drag items from corpse to player inventory
- [ ] Single item transfer works (not entire stack)
- [ ] Can loot axe from corpse

### UI Testing
- [ ] Source slot becomes semi-transparent when dragging
- [ ] Valid drop targets highlight in gold (#FFCE1B)
- [ ] Invalid drop targets highlight in red (#B31B1B)
- [ ] Drag cancellation works (drop on world map)
- [ ] Inventory reorganization works (drag within own inventory)
- [ ] Hotbar numbers visible (large, transparent, centered)
- [ ] **World interactions blocked when inventory open** (can't click land claims, NPCs, or attack)

### Hotbar Testing
- [ ] Press 9 consumes item from hotbar slot 9 (if food)
- [ ] Press 0 consumes item from hotbar slot 0 (if food)
- [ ] Only consumables can be used (berries, grain)
- [ ] Stack count decreases by 1 when consumed
- [ ] Item removed when stack reaches 0

---

## 🐛 Known Issues / Notes

1. **Corpse Decomposition**: Not yet implemented - corpses remain indefinitely
2. **Land Claims**: Disabled for combat test (intentional)

---

## 📋 Quick Reference

**Battle Royale Setup:**
- 6 cavemen spawn in circle (200-300px radius)
- All have axes equipped (male1a.png sprite)
- All have max agro (100.0) - fight immediately
- 3 hits to kill (30 HP, 10 damage per hit)

**Looting:**
- Press I near corpse (50px range)
- Drag items from corpse inventory to player inventory
- Single item transfer (1 item per drag)

**Combat:**
- Click NPC to attack (if weapon in hotbar slot 1)
- NPCs auto-attack each other when agro is high
- Dead NPCs become lootable corpses

---

**Status**: ✅ **READY FOR BATTLE ROYALE PLAYTEST**  
**Last Updated**: January 2026  
**All Critical Features**: ✅ Complete

---

## 🆕 Latest Updates (Pre-Playtest)

### Character Info on Corpses
- ✅ **Death tracking**: Killer and weapon stored when NPC dies
- ✅ **Character info display**: Shows name, type, and death info in corpse inventory
- ✅ **Death info format**: 
  - "Killed by: XXXX of the clan XX XXXX by Axe" (killer with clan)
  - "Killed by: XXXX by Axe" (killer without clan)

### UI Fixes
- ✅ **Corpse drag-and-drop**: Fixed - can now drag items from corpse to player inventory
- ✅ **Building icons**: Hidden on corpse inventories (only shown on land claims)
- ✅ **World interaction blocking**: All world interactions blocked when inventory is open

### Battle Royale Configuration
- ✅ **Wild NPCs disabled**: No women, sheep, or goats spawn in battle royale mode
- ✅ **Only 6 cavemen**: Battle royale spawns only 6 cavemen with axes

### Latest Features (Just Completed)
- ✅ **Corpse range highlight**: Subtle glow effect when player within 50px
- ✅ **NPC hotbar eating**: NPCs can now eat from both inventory and hotbar (slots 9 and 0)
