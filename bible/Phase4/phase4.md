# Stone Age Clans – Phase 4 Backlog

**Date**: February 2026  
**Purpose**: Track next steps and TODOs so nothing gets forgotten.

---

## Herding Animals Crash – FIXED (Feb 2026)

- [x] **Root cause**: `npc_base.gd` `_check_and_assign_to_building()` cast `building_type` (enum int) `as String` → Invalid cast crash when sheep/goat enters land claim
- [x] **Fix**: Compare enum `ResourceData.ResourceType.DAIRY_FARM` directly; use `ResourceData.get_resource_name()` for logging

## Verify Recent Fixes (Feb 2026)

- [ ] Oven cannot go in hotbar (red highlight on hover, drop rejected)
- [ ] Single oven placement (no duplicate when dropping on world)
- [ ] No "Invalid cast: could not convert value to String" at startup

---

## Baby Pool Capacity (Phase 2 carryover)

- [ ] Enable `can_add_baby()` – currently always returns `true`, baby cap is disabled
- [ ] Living-hut-based capacity limits
- [ ] Surplus baby handling (instant promotion when over capacity)
- [ ] Manual promotion UI (optional)

---

## Code TODOs

| Location | Task |
|----------|------|
| `main.gd:164` | Apply food effects (restore hunger, health) |
| `main.gd:3741` | Modify inventory size for babies specifically |
| `combat_state.gd:470` | Remove DetectionArea workaround once all NPCs have it |
| `building_inventory_ui.gd:1248` | Fire button – load/play actual sound file |
| `reproduction_component.gd:317` | Prioritize mates by traits/age when traits implemented |

---

## Console / Runtime Issues (from console.md)

- [ ] NPCs stuck in wander/reproduction for extended periods (STATE_DURATION warnings)
- [ ] HERD_WILDNPC targets beyond max distance – invalidation flow
- [ ] Combat state duration timeouts – potentially stuck in combat

---

## Linter Cleanup

- [ ] `main.gd` – `slot_num` and `player_land_claim` confusable declarations
- [ ] `main.gd` – static `apply_panel_style` called on instance
- [ ] `building_base.gd` – unused `worker` param in `_generate_occupy_only_job`
