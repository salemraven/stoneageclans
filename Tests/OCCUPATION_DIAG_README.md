# Occupation Diagnostic Test

## Purpose

Diagnose building occupation issues:
- **Women not entering Farm/Dairy** after joining clan
- **Animals returning immediately** after drag-and-drop removal
- **Drag-and-drop not removing** animals from building slots

## Run the test

```bash
# From project root
./Tests/run_occupation_test.sh
```

Or capture both console and file output:

```bash
./Tests/run_occupation_test.sh 2>&1 | tee Tests/occupation_console.log
```

## Test procedure

1. **Place Land Claim** – Use Land Claim from hotbar, place in world, name your clan
2. **Place Farm and Dairy** – Open land claim inventory (right-click), drag Farm and Dairy icons into world
3. **Herd in NPCs** – Lead sheep, goats, and women into the land claim (they auto-join when herded in)
4. **Optional: test drag removal** – Open Farm/Dairy inventory, drag an animal from its slot onto the map

## Log file

Writes to `Tests/occupation_diag_<timestamp>.log` with events:

| Event | Meaning |
|-------|---------|
| LAND_CLAIM_PLACED | Player placed land claim |
| BUILDING_PLACED | Farm or Dairy placed |
| NPC_JOINED_CLAN | Sheep, goat, or woman joined clan |
| **REQUEST_SLOT_GRANTED** | OccupationSystem granted slot (RESERVED) |
| **REQUEST_SLOT_DENIED** | OccupationSystem denied (e.g. reserve_failed) |
| **CONFIRM_ARRIVAL** | NPC arrived, state → OCCUPIED |
| **UNASSIGN** | NPC unassigned (reason: death, player_drag, timeout, etc.) |
| **FORCE_ASSIGN** | UI dropped NPC into slot |
| **BUILDING_DESTROYED** | Building removed, occupants unassigned |
| **SNAPSHOT** | Periodic (every 5s) dump of OccupationSystem + building slots |
| WOMAN_OCCUPY_FAIL | Woman can't enter (reason: H2_not_occupiable, H4_too_far, H5_already_occupied) |
| WOMAN_OCCUPY_NO_BUILDING | No buildings in range or all failed checks |
| WOMAN_OCCUPY_CAN_ENTER | Woman found available building |
| WOMAN_FOUND_BUILDING | Woman has target, pathing to it |
| WOMAN_OCCUPIED_BUILDING | Woman successfully entered |
| ANIMAL_ASSIGNED_TO_BUILDING | Sheep/goat assigned to Farm/Dairy |
| ANIMAL_ENTERED_BUILDING | Sheep/goat successfully entered |
| ANIMAL_ASSIGN_TIMEOUT | Animal gave up after 5s |
| CLEAR_OCCUPANT | NPC removed from building slot |
| SET_OCCUPANT | NPC placed in slot |
| ADD_ANIMAL_SUCCESS | add_animal() succeeded |
| OCCUPATION_DRAG_TO_MAP | Animal dragged from slot to map |
| OCCUPATION_DRAG_CANCEL | Drag released on panel (canceled) |

## Run with live monitor

To play-test while watching the log in real time:

```bash
./Tests/run_occupation_test_with_monitor.sh
```

Runs the game and tails the diagnostic log. Press Ctrl+C to stop.

## Analysis

- **Woman not entering**: Look for WOMAN_OCCUPY_FAIL with reason (H2, H4, H5) or WOMAN_OCCUPY_NO_BUILDING
- **Animal returns after drag**: Look for CLEAR_OCCUPANT followed quickly by ANIMAL_ASSIGNED_TO_BUILDING (assigned_building not cleared)
- **Drag not removing**: Look for OCCUPATION_DRAG_CANCEL instead of OCCUPATION_DRAG_TO_MAP (panel rect issue)
