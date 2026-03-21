# Stone Age Clans – Items Guide

**Date**: January 2026  
**Status**: Living Document  
**Purpose**: Comprehensive guide to all items in the game, their categories, and properties

---

## Overview

This document categorizes all items in Stone Age Clans by their type (consumable, resource, tool, weapon, building, etc.) and provides details about their properties, uses, and behaviors.

---

## Item Categories

### Consumables
Items that can be eaten/consumed to restore hunger, health, or provide other effects. Can be placed in hotbar slots 9 and 0 for quick use.

### Resources
Raw materials used for crafting, building, and other game mechanics. Cannot be consumed directly.

### Tools
Items used for gathering resources or performing actions. Can be equipped in equipment slots.

### Weapons
Items used for combat. Can be equipped in equipment slots (typically right hand).

### Buildings
Placeable structures that can be built on the world map. Require resources to construct.

### Equipment
Items that can be worn/equipped on the character. Includes armor, accessories, and utility items.

---

## All Items

### 1. Berries
**Type**: Consumable  
**Category**: Food  
**Icon**: `res://assets/sprites/berries.png`  
**Color**: Green (RGB: 51, 153, 51)

**Properties:**
- **Hunger Restoration**: 5% of max hunger
- **Nutrition Value**: 5 points
- **Stackable**: No (inventory), Yes (building inventories)
- **Max Stack**: 1 (inventory), 999999 (building inventories)

**Uses:**
- Can be eaten to restore hunger
- Can be placed in hotbar slots 9 or 0 for quick consumption
- Used in crafting recipes (e.g., Land Claim requires berries)
- Can be stored in building inventories

**Notes:**
- Basic food item, lowest nutrition value
- Spawns naturally in the world
- NPCs can gather berries from berry bushes

---

### 2. Wood
**Type**: Resource  
**Category**: Raw Material  
**Icon**: `res://assets/sprites/wood.png`  
**Color**: Brown (RGB: 102, 64, 38)

**Properties:**
- **Stackable**: No (inventory), Yes (building inventories)
- **Max Stack**: 1 (inventory), 999999 (building inventories)

**Uses:**
- Used in crafting recipes (e.g., Land Claim, buildings)
- Required for building construction
- Can be gathered from trees using an Axe

**Notes:**
- Basic resource, essential for most crafting
- Trees spawn naturally in the world
- NPCs can gather wood with axes

---

### 3. Stone
**Type**: Resource  
**Category**: Raw Material  
**Icon**: `res://assets/sprites/stone.png`  
**Color**: Gray (RGB: 128, 128, 128)

**Properties:**
- **Stackable**: No (inventory), Yes (building inventories)
- **Max Stack**: 1 (inventory), 999999 (building inventories)

**Uses:**
- Used in crafting recipes (e.g., Land Claim, buildings)
- Required for building construction
- Can be gathered from boulders using a Pick

**Notes:**
- Basic resource, essential for most crafting
- Boulders spawn naturally in the world
- NPCs can gather stone with picks

---

### 4. Wheat
**Type**: Resource  
**Category**: Raw Material  
**Icon**: `res://assets/sprites/wheat.png`  
**Color**: Yellow (RGB: 230, 204, 77)

**Properties:**
- **Stackable**: No (inventory), Yes (building inventories)
- **Max Stack**: 1 (inventory), 999999 (building inventories)

**Uses:**
- Can be harvested from wild wheat plants
- Used in Bakery recipes (converted to Grain/Bread)
- Required for bread production

**Notes:**
- Wild wheat grows only outside land claim radius
- Must be processed (via Bakery) to become consumable
- NPCs can gather wheat from wild wheat plants

---

### 5. Grain
**Type**: Consumable  
**Category**: Food  
**Icon**: `res://assets/sprites/grain.png`  
**Color**: Light Yellow/Gold (RGB: 242, 217, 102)

**Properties:**
- **Hunger Restoration**: 7% of max hunger
- **Nutrition Value**: 7 points
- **Stackable**: No (inventory), Yes (building inventories)
- **Max Stack**: 1 (inventory), 999999 (building inventories)

**Uses:**
- Can be eaten to restore hunger (better than berries)
- Can be placed in hotbar slots 9 or 0 for quick consumption
- Used in Bakery recipes (combined with other edibles to make Bread)
- Can be stored in building inventories

**Notes:**
- Processed from Wheat
- Medium nutrition value (better than berries)
- NPCs can consume grain from inventory or hotbar

---

### 6. Fiber
**Type**: Resource  
**Category**: Raw Material  
**Icon**: `res://assets/sprites/fiber.png`  
**Color**: Tan/Brown (RGB: 179, 128, 77)

**Properties:**
- **Stackable**: No (inventory), Yes (building inventories)
- **Max Stack**: 1 (inventory), 999999 (building inventories)

**Uses:**
- Used in crafting recipes (e.g., cloth, rope, clothing)
- Required for certain building types
- Can be gathered from fiber plants

**Notes:**
- **NOT a consumable** - cannot be eaten
- Used for crafting and building only
- NPCs can gather fiber from fiber plants
- Important for clothing and textile production

---

### 7. Axe
**Type**: Tool/Weapon  
**Category**: Tool (Primary), Weapon (Secondary)  
**Icon**: `res://assets/sprites/axe.png`  
**Color**: Dark Brown (RGB: 77, 51, 38)

**Properties:**
- **Tier**: 1 (White border)
- **Stackable**: No
- **Max Stack**: 1

**Uses:**
- **Tool**: Used to gather wood from trees
- **Weapon**: Can be used in combat (deals damage)
- Can be equipped in right hand (hotbar slot 1)
- Required for efficient wood gathering

**Notes:**
- Dual-purpose: tool and weapon
- NPCs can equip axes for gathering and combat
- Visual indicator: NPC sprite changes to show axe when equipped
- Damage bonus when used as weapon

---

### 8. Pick
**Type**: Tool  
**Category**: Tool  
**Icon**: `res://assets/sprites/pick.png`  
**Color**: Gray (RGB: 102, 102, 102)

**Properties:**
- **Tier**: 1 (White border)
- **Stackable**: No
- **Max Stack**: 1

**Uses:**
- **Tool**: Used to gather stone from boulders
- Can be equipped in right hand (hotbar slot 1)
- Required for efficient stone gathering

**Notes:**
- Primary use is resource gathering
- NPCs can equip picks for gathering
- Not typically used as a weapon (unlike axe)

---

### 9. Land Claim
**Type**: Building  
**Category**: Building (Placeable)  
**Icon**: `res://assets/sprites/landclaim.png`  
**Tier**: 1 (White border)

**Properties:**
- **Stackable**: No
- **Max Stack**: 1
- **Placeable**: Yes (can be placed on world map)

**Uses:**
- First craftable building
- Creates circular radius (invisible fence - NPCs cannot leave on their own)
- Own drag-and-drop storage inventory
- Upgradable in-place: Flag → Tower → Keep → Castle
- War Horn built-in (H key)
- One-time clan symbol + color picker when placed

**Crafting Requirements:**
- Wood + Stone + Berries + Leather (exact amounts TBD)

**Notes:**
- Can be dragged from inventory to world map for placement
- Essential for establishing a clan
- Destroying enemy flag = total wipe (all inventories vanish, baby pool erased, clansmen drop dead)

---

### 10. Living Hut
**Type**: Building  
**Category**: Building (Placeable)  
**Icon**: `res://assets/sprites/hut.png`  
**Tier**: 1 (White border)

**Properties:**
- **Stackable**: No
- **Max Stack**: 1
- **Placeable**: Yes (can be placed on world map)

**Uses:**
- Adds +X to baby pool capacity
- Must be placed inside land claim radius
- Can be built via Building Inventory UI

**Crafting Requirements:**
- TBD (requires resources)

**Notes:**
- Can be dragged from inventory to world map for placement
- Multiple Living Huts increase baby pool capacity

---

### 11. Supply Hut
**Type**: Building  
**Category**: Building (Placeable)  
**Icon**: `res://assets/sprites/supply.png`  
**Tier**: 1 (White border)

**Properties:**
- **Stackable**: No
- **Max Stack**: 1
- **Placeable**: Yes (can be placed on world map)

**Uses:**
- Provides extra shared storage
- Must be placed inside land claim radius
- Can be built via Building Inventory UI

**Crafting Requirements:**
- TBD (requires resources)

**Notes:**
- Can be dragged from inventory to world map for placement
- Additional storage for clan resources

---

### 12. Shrine
**Type**: Building  
**Category**: Building (Placeable)  
**Icon**: `res://assets/sprites/shrine.png`  
**Tier**: 1 (White border)

**Properties:**
- **Stackable**: No
- **Max Stack**: 1
- **Placeable**: Yes (can be placed on world map)

**Uses:**
- Place relics → permanent clan-wide buffs
- Must be placed inside land claim radius
- Can be built via Building Inventory UI

**Crafting Requirements:**
- TBD (requires resources, possibly relics)

**Notes:**
- Can be dragged from inventory to world map for placement
- Used for placing relics to gain permanent buffs

---

### 13. Dairy Farm
**Type**: Building  
**Category**: Building (Placeable)  
**Icon**: `res://assets/sprites/dairy.png`  
**Tier**: 1 (White border)

**Properties:**
- **Stackable**: No
- **Max Stack**: 1
- **Placeable**: Yes (can be placed on world map)

**Uses:**
- Produces cheese and butter from milk
- Requires 1 woman assigned
- Must be placed inside land claim radius
- Can be built via Building Inventory UI

**Crafting Requirements:**
- TBD (requires resources)

**Notes:**
- Can be dragged from inventory to world map for placement
- Production building requiring woman assignment

---

## Item Summary Table

| Item | Type | Category | Consumable | Stackable (Inventory) | Stackable (Building) | Placeable | Tier |
|------|------|----------|------------|----------------------|---------------------|-----------|------|
| Berries | Consumable | Food | ✅ Yes | ❌ No | ✅ Yes | ❌ No | 0 |
| Wood | Resource | Raw Material | ❌ No | ❌ No | ✅ Yes | ❌ No | 0 |
| Stone | Resource | Raw Material | ❌ No | ❌ No | ✅ Yes | ❌ No | 0 |
| Wheat | Resource | Raw Material | ❌ No | ❌ No | ✅ Yes | ❌ No | 0 |
| Grain | Consumable | Food | ✅ Yes | ❌ No | ✅ Yes | ❌ No | 0 |
| Fiber | Resource | Raw Material | ❌ No | ❌ No | ✅ Yes | ❌ No | 0 |
| Axe | Tool/Weapon | Tool/Weapon | ❌ No | ❌ No | ❌ No | ❌ No | 1 |
| Pick | Tool | Tool | ❌ No | ❌ No | ❌ No | ❌ No | 1 |
| Land Claim | Building | Building | ❌ No | ❌ No | ❌ No | ✅ Yes | 1 |
| Living Hut | Building | Building | ❌ No | ❌ No | ❌ No | ✅ Yes | 1 |
| Supply Hut | Building | Building | ❌ No | ❌ No | ❌ No | ✅ Yes | 1 |
| Shrine | Building | Building | ❌ No | ❌ No | ❌ No | ✅ Yes | 1 |
| Dairy Farm | Building | Building | ❌ No | ❌ No | ❌ No | ✅ Yes | 1 |

---

## Equipment Slots Reference

**Hotbar Slots (10 total):**
1. **Right Hand** - Tools, weapons (Axe, Pick, etc.)
2. **Left Hand** - Shield, ammo, secondary items
3. **Head** - Helmet, hat, head armor
4. **Body** - Shirt, body armor
5. **Legs** - Pants, leg armor
6. **Feet** - Boots, shoes, foot armor
7. **Neck** - Amulet, neck armor
8. **Backpack** - Increases inventory capacity
9. **Consumable** - Food, health items (press 9 to use)
0. **Consumable** - Food, health items (press 0 to use)

---

## Consumables Quick Reference

**Current Consumables:**
- **Berries** - Restores 5% hunger, nutrition value: 5
- **Grain** - Restores 7% hunger, nutrition value: 7

**Future Consumables (Planned):**
- **Meat** - Will restore 10% hunger, nutrition value: 10 (highest)
- **Bread** - Best food in game (from Bakery)
- **Cheese** - From Dairy Farm
- **Butter** - From Dairy Farm

**How to Use:**
- Place consumable in hotbar slot 9 or 0
- Press **9** to consume from slot 9
- Press **0** to consume from slot 0
- Only food items can be consumed
- NPCs can eat from inventory or hotbar

---

## Tools & Weapons Quick Reference

**Tools:**
- **Axe** - Gathers wood from trees, can be used as weapon
- **Pick** - Gathers stone from boulders

**Weapons:**
- **Axe** - Can be used in combat (deals damage)

**Future Tools/Weapons (Planned):**
- Various weapons from Armory
- Additional tools for specialized gathering

---

## Resources Quick Reference

**Basic Resources:**
- **Wood** - From trees (requires Axe)
- **Stone** - From boulders (requires Pick)
- **Wheat** - From wild wheat plants
- **Fiber** - From fiber plants

**Processed Resources:**
- **Grain** - Processed from Wheat (via Bakery or manual processing)

**Future Resources (Planned):**
- **Leather** - From animals
- **Wool** - From sheep (via Farm)
- **Milk** - From goats (via Farm)
- **Cloth** - From wool (via Spinner)

---

## Buildings Quick Reference

**All buildings are:**
- Placeable on world map (drag from inventory)
- Must be placed inside land claim radius
- Require resources to build
- Have drag-and-drop inventories
- Built via Building Inventory UI (I key near land claim)

**Building Types:**
- **Land Claim** - First building, establishes clan
- **Living Hut** - Increases baby pool capacity
- **Supply Hut** - Extra storage
- **Shrine** - Place relics for buffs
- **Dairy Farm** - Produces cheese/butter (requires woman)

**Future Buildings (Planned):**
- **Farm** - Wool/milk production (requires woman, herd animals)
- **Spinner** - Cloth from wool (requires woman)
- **Bakery** - Bread production (requires woman)
- **Armory** - Weapons (requires woman)
- **Tailor** - Armor, backpacks, travois (requires woman)
- **Medic Hut** - Heals wounds (requires woman, needs berries)

---

## Item Properties Details

### Stacking Rules

**Player/NPC Inventory:**
- Most items: **No stacking** (1 per slot)
- Exception: Building inventories allow stacking

**Building Inventories:**
- All items: **Stackable** (up to 999999 for testing)
- Allows efficient storage

### Tier System

**Tier 0 (Grey Border):**
- Basic resources (Wood, Stone, Berries, Wheat, Grain, Fiber)
- Basic consumables

**Tier 1 (White Border):**
- Tools (Axe, Pick)
- Buildings (Land Claim, Living Hut, Supply Hut, Shrine, Dairy Farm)

**Future Tiers:**
- Tier 2 (Light Blue) - Advanced items
- Tier 3 (Purple) - Master/Legendary items

---

## Item Interactions

### Drag-and-Drop
- All items can be dragged between inventories
- Buildings can be dragged to world map for placement
- Regular items cannot be dropped on world map
- Single item transfer (not entire stack)

### Hotbar Usage
- Equipment slots (1-8): Tools, weapons, armor, accessories
- Consumable slots (9-0): Food items only
- Press 9 or 0 to consume from respective hotbar slot

### NPC Behavior
- NPCs can gather resources with appropriate tools
- NPCs can eat from inventory or hotbar
- NPCs can equip tools/weapons in right hand
- NPCs auto-deposit resources when inventory is 80% full

---

## Future Items (Planned)

### Consumables
- **Meat** - From animals, highest nutrition
- **Bread** - From Bakery, best food
- **Cheese** - From Dairy Farm
- **Butter** - From Dairy Farm

### Resources
- **Leather** - From animals
- **Wool** - From sheep (via Farm)
- **Milk** - From goats (via Farm)
- **Cloth** - From wool (via Spinner)

### Tools
- Additional specialized gathering tools
- Advanced tools for new resources

### Weapons
- Various weapons from Armory
- Ranged weapons (future)
- Advanced weapons (future)

### Equipment
- **Shield** - Left hand equipment
- **Helmet** - Head equipment
- **Armor** - Body, legs, feet equipment
- **Backpack** - Increases inventory capacity
- **Amulet** - Neck equipment (buffs)

---

## Notes

- **FIBER is NOT a consumable** - it's a crafting resource only
- All consumables must be food items (checked via `ResourceData.is_food()`)
- Only hotbar slots 9 and 0 accept consumables for quick use
- Equipment slots (1-8) are for tools, weapons, and armor
- Buildings can only be placed inside land claim radius
- NPCs have the same hotbar system as players (10 slots)

---

**Last Updated**: January 2026  
**Status**: Living Document - Will be updated as new items are added

ITEMS TO ADD
Glue
sinue
meat
bone
health
