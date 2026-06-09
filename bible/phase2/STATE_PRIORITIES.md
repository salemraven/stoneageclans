# State Priority Hierarchy

**Last Updated:** 2026-05-13 (Hunt row: AoH = PREY only)

**Source of truth:** Numeric defaults live in [`scripts/config/npc_config.gd`](../../scripts/config/npc_config.gd) under `@export_group("State Priorities")` (and related exports such as `priority_combat_state`, `priority_craft_*`, `priority_defend_*`, etc.). This document summarizes behavior; tune the autoload for gameplay changes.

## FSM evaluation order (critical)

In [`scripts/npc/fsm.gd`](../../scripts/npc/fsm.gd) `_evaluate_states()`:

1. **Combat** — If `combat_state.can_enter()`, the FSM switches to combat and **returns** (before the sorted priority pass).
2. **Defend** — If `defend_state.can_enter()`, the FSM switches to defend and **returns** (before the sorted priority pass). This implements the defend directive / quota (“bypasses work priority” per in-code comment).
3. **Sorted list** — Remaining states are sorted by `get_priority()`; first with `can_enter() == true` wins (subject to transport lock, craft lock, etc.).

So “highest number in the table” does not always win if combat/defend short-circuit first.

## Priority Values (reference — see NPCConfig for exact floats)

### Critical (Life/Death)
| State | Config keys (examples) | Notes |
|-------|-------------------------|-------|
| **Combat** | `priority_combat_state` | Melee combat; also evaluated **early** in FSM |
| **Agro** | `priority_agro`, `priority_agro_recover`, `priority_agro_low`, `priority_agro_defend_boost` | Recover vs defend paths; caveman land defense adds boost vs caveman/player |
| **Flee combat** | `priority_flee_combat` | Disengage |
| **Wander (deposit)** | `priority_wander_moving_to_deposit`, `priority_wander_returning_from_break` | High priority return/deposit legs |

### Player / follow
| State | Config keys | Notes |
|-------|-------------|-------|
| **Herd catchup** | `herd_catchup_priority` (see NPCConfig) | When far from leader |
| **Herd / Party** | `priority_herd`, `priority_party_herd_inactive` | Following |

### Build
| State | Config keys | Notes |
|-------|-------------|-------|
| **Build (urgent)** | `priority_build_land_claim_urgent` | 8+ items / claim placement |
| **Build (default)** | `priority_build` | Land claim when ready |

### Herd Wild NPC
| State | Config keys | Notes |
|-------|-------------|-------|
| **Leading** | `priority_herd_wildnpc_woman`, `priority_herd_wildnpc` | |
| **Searching** | `priority_herd_wildnpc_searching`, `priority_herd_wildnpc_searching_boosted`, `priority_herd_wildnpc_no_target` | |

### Defense & work
| State | Config keys | Notes |
|-------|-------------|-------|
| **Defend** | `priority_defend_trait`, `priority_defend_default` | Trait “protective/guardian” uses trait priority; also evaluated **early** when `can_enter` |
| **Raid** | `priority_raid` | |
| **Hunt** | `priority_hunt` | **NPC ClanBrain hunting only.** Targets **`WildRole.PREY`** in **Area of Hunt** (see **`NPCConfig.is_ai_hunt_prey_type`**, `land_claim`); sheep/goats use **herd_wildnpc**, not this hunt quota |
| **Search** | `priority_search` | |
| **Craft** | `priority_craft_*`, `min_fighters_for_craft_priority_over_gather` | Craft vs gather uses `StateEconomyRules` + fighter count |
| **Reproduction** | `priority_reproduction` | |
| **Occupy / work building** | `priority_occupy_building`, `priority_work_at_building_*` | |

### Eat
| State | Config keys | Notes |
|-------|-------------|-------|
| **Eat tiers** | `priority_eat_very_hungry`, `priority_eat_hungry`, `priority_eat_low` | |

### Gather
| State | Config keys | Notes |
|-------|-------------|-------|
| **Gather** | `priority_gather_no_clan`, `priority_gather_inventory_full`, `priority_gather_other`, `priority_gather_productivity`, `caveman_productivity_test` | |

### Fallback
| State | Config keys | Notes |
|-------|-------------|-------|
| **Wander** | `priority_wander`, `priority_wander_caveman_fallback` | |
| **Idle** | `priority_idle_*` | Tiered by NPC type |
| **Seek** | `priority_seek` | |

## Priority Rules

1. **Combat / defend early exit** — Checked before the global priority sort (see above).
2. **Herd catchup** — Typically beats normal herd when far from leader.
3. **Build urgent** — Very high vs most states when caveman must place claim.
4. **Craft lock** — When actively crafting with a job, only defend/combat paths short-circuit (see `fsm.gd`).
5. **Gather** — Blocked when `can_enter` false (no claim, inventory, etc.) regardless of priority number.

## Notes

- FSM evaluation interval: near player ~0.1s, far ~0.25s (`fsm.gd`); **additional** distance scaling skips whole FSM ticks in `npc_base.gd` — see [Movement guide](../movement.md#fsm-evaluation-vs-distance-scaling).
- **Multiplayer:** `fsm.update` runs only on `is_multiplayer_authority()` when a multiplayer peer is active (`npc_base.gd`).
- Min state change cooldown reduces thrashing.
- Economy rule helper: [`scripts/npc/state_economy_rules.gd`](../../scripts/npc/state_economy_rules.gd).

## Regression

- After instrumented runs, `tools/assert_session_economy.sh` can assert minimum `WORK_GATHER_BUILT` and max `[ERROR]` lines. Enable with `ASSERT_ECONOMY=1` when using `run_session_instrument.sh`.
