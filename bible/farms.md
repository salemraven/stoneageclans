# Farm, Dairy & Oven: Occupation, Production & UI Guide

This guide explains how women, animals, and production buildings work together: the occupation system, production flow, job/task system, and UI.

---

## 1. Overview

**Buildings** (Farm, Dairy, Oven) require **women** in woman slots and optionally **animals** (Farm → sheep, Dairy → goats) in animal slots. Women produce resources via jobs (PickUp materials → Occupy → Produce → Transport output). Animals occupy buildings automatically when herded into the land claim radius.

**Key systems:**
- **OccupationSystem** – single authority for who occupies which slot (women + animals)
- **ClaimBuildingIndex** – which buildings belong to which land claim (for animal targeting)
- **ProductionComponent** – crafting logic (inputs → outputs, craft time)
- **Task/Job system** – women pull jobs from buildings (PickUp, MoveTo, DropOff, Occupy)

---

## 2. Buildings: Slots & Recipes

| Building | Woman Slots | Animal Slots | Animal Type | Recipe |
|----------|-------------|--------------|-------------|--------|
| **Oven** | 1 | 0 | — | 1 Wood + 1 Grain → 1 Bread (15s) |
| **Farm** | 2 | 3 | sheep | 1 Fiber → 1 Wool (12s) |
| **Dairy** | 2 | 3 | goat | 1 Fiber → 1 Milk (12s) |

- **Farm/Dairy**: Start with 5 fiber in building inventory so women can occupy immediately.
- **Oven**: Land claim starts with 5 grain + 5 wood (for testing); women bring Wood + Grain from claim to oven and cook bread.
- All production buildings add themselves to the `"buildings"` group.

**Occupiability (when women can enter):**
- **Oven**: Occupiable when empty woman slot (woman enters and activates the building).
- **Farm/Dairy**: Occupiable when `is_active` OR has at least one animal of the correct type OR has empty animal slots.

---

## 3. Women: Flow & States

### FSM States

| State | Priority | Role |
|-------|----------|------|
| occupy_building | 7.5 | Move to an unoccupied building and take a woman slot |
| work_at_building | 7.0 / 9.0–10.0 | Pull jobs from buildings, execute tasks |

Women enter **occupy_building** when:
- They are in a clan
- Not defending, in combat, or following
- There is an available building (occupiable, not occupied, within 500 units)

Women enter **work_at_building** when:
- There is an available job (production or transport)
- OR they already occupy a building

### Occupy Flow (occupy_building_state)

1. `can_enter()` → `_has_available_building()` scans buildings in `"buildings"` group.
2. If found: `OccupationSystem.request_slot(npc)` → gets building + slot (RESERVED).
3. Woman moves to building (arrive distance 28px – close to sprite before disappearing).
4. On arrival: `OccupationSystem.confirm_arrival(npc)` → RESERVED → OCCUPIED.
5. `building.set_occupant(slot_index, npc, true)` → woman in `woman_slots`, sprite hidden, building activated.
6. FSM transitions to **work_at_building**.

### Work Flow (work_at_building_state)

1. Woman sprite hidden when occupying; visible when transporting.
2. Every 2 seconds: if no active job → `_try_pull_job()`.
3. `generate_job(worker)` on buildings returns:
   - **Production job**: PickUp inputs at claim → MoveTo building → DropOff → Occupy → PickUp output → MoveTo claim → DropOff.
   - **Transport job**: When building is occupied and has output (e.g. bread) → PickUp at building → MoveTo claim → DropOff.
   - **Occupy-only job**: When building already has inputs but land claim has none (Farm/Dairy with fiber) → Occupy → PickUp output → MoveTo claim → DropOff.

---

## 4. Animals: Auto-Occupation

### Flow

1. Animals (sheep/goats) with a clan run `_check_and_assign_to_building()` in `npc_base`.
2. Already assigned: Path to building; when within **220px** (`ANIMAL_ENTER_RANGE`) → `OccupationSystem.confirm_arrival()`.
3. Not assigned: `OccupationSystem.request_slot(npc)` every ~1.5s (throttled).
4. OccupationSystem picks nearest building of correct type (Farm → sheep, Dairy → goat) via `ClaimBuildingIndex.get_buildings_in_claim()`.
5. Up to 3 slots can be reserved in parallel (no "1 reservation when empty" limit).
6. On arrival: `set_occupant()` → animal in `animal_slots`, sprite hidden.
7. Timeout: If not arrived within 12s → unassign, animal retries.

### Requirements

- Animal must be in the same clan as the land claim.
- Building must be inside that land claim’s radius (ClaimBuildingIndex).
- Slot must be empty or unreserved.

---

## 5. Production Component

`ProductionComponent` runs on buildings with recipes.

### _can_craft() Checks

- Building `is_active`
- If `requires_woman`: at least one woman in woman slots
- Farm: at least one sheep
- Dairy: at least one goat
- Building inventory has required inputs
- Building inventory has space for output

### Craft Cycle

1. While `_can_craft()`: increment `craft_timer`, complete when `craft_time` reached.
2. On complete: consume inputs, add output, set `is_active = false` (one item per activation).
3. If active but no materials: auto-turn off.

### Fire Button (UI)

- Oven, Farm, Dairy show a fire button in the building inventory title.
- Pressing it calls `building.set_active(true)`.
- Disabled when materials are missing; enabled when `_can_craft()` would pass.

---

## 6. Occupation System

**OccupationSystem** is the single authority. All slot changes go through it.

### Methods

| Method | Purpose |
|--------|---------|
| `request_slot(npc)` | NPC asks for a slot → returns `{ building, slot_index, slot_type }` or `{}`. Sets state RESERVED. |
| `confirm_arrival(npc)` | NPC reached building → RESERVED → OCCUPIED, calls `building.set_occupant()`. |
| `unassign(npc, reason)` | Clear assignment; `building.clear_occupant_for_npc()`. |
| `force_assign(npc, building, slot, type)` | Manual assign (e.g. drag-drop). Unassigns previous occupant. |
| `get_workplace(npc)` | Building this NPC is assigned to. |
| `get_ref_state(npc)` | NONE, RESERVED, or OCCUPIED. |

### States

- **NONE**: No assignment.
- **RESERVED**: NPC has a slot but hasn’t arrived yet.
- **OCCUPIED**: NPC is in the building (`woman_slots` / `animal_slots`).

---

## 7. Building Inventory UI

### Occupation Slots

- **Woman slots**: 32×32 slots; show occupant icon or empty.
- **Animal slots**: Same for sheep/goats (per building type).
- Built by `_build_occupation_slots()` from `get_woman_slot_count()` and `get_animal_slot_count()`.

### Drag-Drop

- **From slot to map**: Unassign via OccupationSystem, place NPC at cursor. 5s cooldown before re-assign.
- **From map to slot**: `OccupationSystem.force_assign()` if clan matches and type matches (woman / sheep / goat).
- **Slot to slot**: Reassign occupant; previous occupant unassigned.

### Fire Button

- Shown for Oven, Farm, Dairy.
- Disabled when materials missing or building already active.
- Toggles `is_active`; production runs until one item is crafted, then building turns off.

---

## 8. Job / Task Chain

Typical **production job**:

1. **PickUpTask** – Take inputs from land claim (reserved).
2. **MoveToTask** – Go to building.
3. **DropOffTask** – Put inputs in building inventory.
4. **OccupyTask** – Force-assign woman, wait for production, unassign on completion.
5. **PickUpTask** – Take output from building.
6. **MoveToTask** – Go to land claim.
7. **DropOffTask** – Put output in land claim.

**OccupyTask**:

- Force-assigns woman to first empty woman slot.
- Activates building if inactive.
- Checks `_can_craft()`; fails if materials missing (e.g. Farm/Dairy need fiber).
- Completes when `_can_craft()` becomes false (inputs exhausted).
- Unassigns woman on completion.

---

## 9. Key Scripts

| Script | Role |
|--------|------|
| `scripts/systems/occupation_system.gd` | Slot assignment, request/confirm/unassign |
| `scripts/systems/claim_building_index.gd` | Buildings per land claim |
| `scripts/buildings/building_base.gd` | Slots, `set_occupant`, `reserve_slot`, `generate_job` |
| `scripts/buildings/components/production_component.gd` | Craft logic, `_can_craft` |
| `scripts/npc/states/occupy_building_state.gd` | Woman move-to-building state |
| `scripts/npc/states/work_at_building_state.gd` | Woman job-pull & work state |
| `scripts/npc/npc_base.gd` | `_check_and_assign_to_building` for animals |
| `scripts/ai/tasks/occupy_task.gd` | Occupy and wait for production |
| `scripts/inventory/building_inventory_ui.gd` | Occupation slots, fire button, drag-drop |

---

## 10. Diagnostics

- **OccupationDiagLogger** (with `--occupation-diag`): Logs REQUEST_SLOT_GRANTED/DENIED, CONFIRM_ARRIVAL, UNASSIGN, SET_OCCUPANT, etc.
- **Tests/run_occupation_test_with_monitor.sh**: Runs game and tails the occupation diag log.
- `generate_job` failure reasons: `get_last_job_failure_reason()` (e.g. `missing inputs`, `job reserved by another`).
