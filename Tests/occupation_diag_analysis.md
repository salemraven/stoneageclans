# Occupation Diagnostic Analysis — 2026-02-16

## Log file
`Tests/occupation_diag_2026-02-16T14-23-50.log`

## Timeline
| Time | Event |
|------|-------|
| 8.80s | LAND_CLAIM_PLACED clan=OKOK |
| 12.53s | BUILDING_PLACED Dairy Farm |
| 14.15s | BUILDING_PLACED Farm |
| 28–90s | Animals: assign, reserve fails, enter, loop |

---

## Finding 1: No women entering — root cause

**No WOMAN_* events in the log** (WOMAN_OCCUPY_FAIL, WOMAN_OCCUPY_CAN_ENTER, WOMAN_OCCUPIED_BUILDING, etc.).

**No NPC_JOINED_CLAN events** — so no women were recorded as joining the clan.

`occupy_building_state.can_enter()` returns false immediately when `npc_clan == ""`. So women must not be in the clan when they try to occupy.

**Conclusion:** Women need to be herded into the land claim to join. They do not auto-join when wandering in later. Place the land claim so it includes women, or herd them in.

---

## Finding 2: Animal assign loop — performance issue

Sheep 4069 and 3968 keep getting assigned and “entered” every ~0.4 s, even after they are already in the building.

Cause:
- After `add_animal` succeeds, `assigned_building = null`
- Next frame, `_check_and_assign_to_building` runs again
- It finds the same Farm (which still has empty slots)
- It does not check “am I already in this building?”
- So it reassigns, the animal is still close, `add_animal` returns `true` (already in)
- Assign/enter repeats every frame

**Fix:** In the building selection logic, skip buildings that already contain this NPC in an animal slot.

---

## Finding 3: Animal flow is working

- Sheep reach the Farm (2 sheep in slots 0 and 1)
- SET_OCCUPANT, ADD_ANIMAL_SUCCESS, ANIMAL_ENTERED_BUILDING all occur
- Initial reserve failures are races between multiple sheep; the system resolves them

---

## Finding 4: Drag-and-drop not tested

No OCCUPATION_DRAG_TO_MAP or OCCUPATION_DRAG_CANCEL events. Drag removal from building slots was not exercised in this run.

---

## Recommendations

1. **Women not entering:** Ensure women are in clan (herd them into the claim, or place claim on/near them). Add UI or feedback when women are not in clan.
2. **Assign loop:** In `_check_and_assign_to_building`, skip buildings where this NPC is already in an animal slot.
3. **Re-test:** Run again, herd women into the claim, and try dragging an animal from a building slot onto the map to confirm drag behavior.
