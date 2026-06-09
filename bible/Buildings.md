# Stone Age Clans – Buildings

All buildings have a building inventory where materials can be placed to be turned into refined items.

---

## Current implementation (Phase 2)

This section reflects the **current state of the game**. See [phase2/build_menu.md](phase2/build_menu.md) for full build menu and placement details.

### Placement rules (in code)

- **Buffer**: Minimum **50px** between buildings and between buildings and land claim center (`BUILDING_MIN_DISTANCE` in `main.gd`).
- **Scene**: All building types use the shared **Building.tscn**; `building_type` is set at placement.
- **Size**: 128×128 pixels (2×2 tiles). Placed by dragging building item from inventory onto the world; must be inside player land claim.

### Land Claim

- **How you get it**: From inventory (cavemen start with one; not in build menu). Placed by dragging from inventory.
- **Purpose**: Establishes clan base. NPCs deposit here; build menu (I near claim) opens land claim inventory + building cards.
- **Radius**: 400px (configurable on land claim).
- **Not built from build menu** – placed separately.

### Buildings in build menu (I near land claim)

All five are in [BuildingRegistry](scripts/buildings/building_registry.gd). Clicking a card consumes materials from the land claim inventory and adds the building item to player inventory; player then drags the item onto the world to place.

| Building      | Cost (current) | Purpose / notes |
|--------------|----------------|------------------|
| **Living Hut** | 1 Wood, 1 Stone | +5 baby pool capacity per hut. **Currently disabled** in code (`_handle_building_placed` in main.gd). |
| **Supply Hut** | 1 Wood, 1 Stone | Extra storage (6 slots, stacking). |
| **Shrine**     | 1 Wood, 1 Stone | Place of worship (no special logic yet). |
| **Dairy Farm** | 1 Wood, 1 Stone | Milk animals (no production logic yet). |
| **Oven**       | 2 Stone         | **Production**: 1 Wood + 1 Grain → 1 Bread in 15s. Fire button toggles on/off; no woman required (occupation disabled). |

### Oven (only production building implemented)

- **Recipe**: 1 Wood + 1 Grain → 1 Bread.
- **Craft time**: 15 seconds. Progress bar in building inventory UI.
- **Activation**: Fire button in building inventory; only enabled when building has 1 Wood + 1 Grain. Auto-shuts off when out of materials.
- **Woman occupation**: Disabled; production runs with fire button only.
- **Inventory**: 6 slots (stackable); Wood, Grain, Bread.

### Disabled / not yet in use

- **Living Hut baby pool**: BabyPoolManager capacity increase is commented out in main.gd.
- **Woman occupation**: Occupy/work_at_building states exist but are disabled for Oven (production works without women).
- **Dairy Farm / Shrine / Supply Hut**: No production or special logic yet; placement and inventory only.

### Key files

- **Registry**: `scripts/buildings/building_registry.gd` – costs, names, icons for build menu.
- **Placement**: `scripts/main.gd` – `_place_building`, `_validate_building_placement`, `BUILDING_MIN_DISTANCE = 50`.
- **Shared building**: `scripts/buildings/building_base.gd`, `scenes/Building.tscn` – all types; Oven uses `production_component.gd`.
- **Oven-specific**: `scripts/buildings/oven.gd` – sets `building_type = OVEN`.

---

## NPC Build State (Land Claim Placement)

**File:** `scripts/npc/states/build_state.gd`

The build state is for **cavemen placing land claims only** – not buildings. Buildings are placed by the player via the build menu.

### Flow

1. **can_enter()** – Caveman only; has LANDCLAIM item; no clan yet; spawn cooldown expired (10s) or has 8+ items.
2. **update()** – Snap position to 64px grid; check overlap with existing claims (min distance = 2×400 + 400 = 1200px center-to-center).
3. **Overlap** – If overlap: set `last_overlap_position`, `overlap_cooldown` (3s), exit to wander.
4. **Place** – If no overlap: call `main._place_npc_land_claim()`; caveman gets clan name, claim created.
5. **Exit** – If already has claim: exit to wander → gather.

### Priority

| Condition | Priority |
|-----------|----------|
| 8+ items in inventory | 25.0 |
| Has land claim item, cooldown expired, no claim | 25.0 |
| Has land claim item, wild NPCs nearby | 10.0 |
| Default | 9.5 |

### Overlap

- `MIN_CLAIM_GAP = 400` – gap between claim edges.
- `LAND_CLAIM_RADIUS = 400` – each claim radius.
- Min center-to-center = 1200px.

### Land Claim Placement (Wander)

- Cavemen can also place land claims from **wander_state** when overlapping another claim (cooldown logic).

---

## Future / design reference

The list below is **aspirational design** (not all implemented). Current placement uses **50px** buffer; design doc used 256px for future tuning.

### Core design principles

- **Aesthetic**: Rough, temporary structures (hide roofs, wood frames, stone piles) matching pixel-art. Earthy palette (#3c2723, #8b4513 accents).
- **Placement**: Drag from inventory → place in world if inside land claim and 50px from others. 128×128 footprint.
- **Production**: Buildings process materials over time with NPC labor; outputs stack in building inventory.
- **Modularity**: Add new buildings via BuildingRegistry + building_type; shared Building.tscn or dedicated scene.
- **Destruction**: Buildings can decay when land claim is destroyed (raid/damage system).

### Design building list (future)

1. **Land Claim Flag** – Base; 256px radius morale (design). *In game: Land Claim, 400px radius, no build menu.*
2. **Hut** – Housing, +5 baby cap. *In game: Living Hut, same idea; baby cap currently disabled.*
3. **Farm** – Wheat/berries. *Not in game yet.*
4. **Storage Hut** – Extra storage. *In game: Supply Hut.*
5. **Dairy** – Milk from goats. *In game: Dairy Farm (no production yet).*
6. **Shepherd** – Wool from sheep. *Not in game yet.*
7. **Armory** – Spears/clubs. *Not in game yet.*
8. **Tailor** – Hide armor. *Not in game yet.*
9. **Grave** – Burial, morale. *Not in game yet.*

### Material refinement (design)

- Wood, Stone: Gathered from nodes. Hide/Bone from corpses. Wheat/Berries from Farm. Milk from Dairy, Wool from Shepherd (when implemented).

### NPC integration (design)

- Build state, woman auto-assign to buildings, maintenance/decay. *In game: woman occupation disabled; Oven runs via fire button.*

---

*For build menu UI, placement flow, and Oven details, see [phase2/build_menu.md](phase2/build_menu.md).*
