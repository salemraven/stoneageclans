# State Priority Hierarchy

**Last Updated:** 2026-02-21

This document defines the priority system for NPC FSM states. Higher priority states take precedence. The FSM evaluates states in priority order; the first state with `can_enter() == true` and priority > current state wins.

## Priority Values (Highest to Lowest)

### Critical (Life/Death)
| State | Priority | Notes |
|-------|----------|-------|
| **Combat** | 12.0 | Melee combat; overrides most states |
| **Agro (defend)** | 10.0–12.0 | Land claim defense: 12.0 when targeting caveman/player; 10.0 for recover; 3.0 when not ready |
| **Wander (deposit)** | 12.0 | When `moving_to_deposit` – above herd so deposit wins when inventory full |

### Player Commands
| State | Priority | Notes |
|-------|----------|-------|
| **Herd (catchup)** | 15.0 | When too far from leader (player-ordered follow) |
| **Herd (following)** | 11.0 | Following player or clan leader |

### Build
| State | Priority | Notes |
|-------|----------|-------|
| **Build (8+ items)** | 25.0 | Caveman has 8+ items – must place land claim |
| **Build (default)** | 9.5 | Has land claim item, cooldown expired; +0.5 if wild NPCs nearby |

### Herd Wild NPC (Search/Lead)
| State | Priority | Notes |
|-------|----------|-------|
| **Herd Wild NPC (leading woman)** | 12.0 | Leading herd with woman |
| **Herd Wild NPC (leading)** | 11.5 | Leading herd (sheep/goat) |
| **Herd Wild NPC (target close)** | 11.5 | Target within 500px |
| **Herd Wild NPC (searching, pressure ≥0.8)** | 6.1 | Clan needs women; beats gather |
| **Herd Wild NPC (searching)** | 5.5 | No target or target far; below gather |

### Defense & Work
| State | Priority | Notes |
|-------|----------|-------|
| **Defend** | 3.0–11.0 | Caveman: 3.0 (prefer gather/herd). Clansman: 11.0; protective: 11.0; solitary: 8.0 |
| **Raid** | 8.5 | AI raiding enemy claims |
| **Reproduction** | 8.0 | Women seeking mates or gestating |

### Eat
| State | Priority | Notes |
|-------|----------|-------|
| **Eat (very hungry <30%)** | 10.0 | Config: `priority_eat_very_hungry` |
| **Eat (hungry <50%)** | 7.0 | Config: `priority_eat_hungry` |
| **Eat (low <80%)** | 5.0 | Config: `priority_eat_low` |

### Gather
| State | Priority | Notes |
|-------|----------|-------|
| **Gather (inventory full)** | 5.0 | Need to deposit |
| **Gather (productivity)** | 6.0 | When `caveman_productivity_test` enabled |
| **Gather (default)** | 4.0 | Config: `priority_gather_other` |

### Fallback
| State | Priority | Notes |
|-------|----------|-------|
| **Wander (caveman/clansman)** | 0.01 | Only when no other state can enter |
| **Wander (other)** | 1.0 | Default for women, animals |
| **Idle** | 0.0 | Cavemen/wild herdables never idle |

## Priority Rules

1. **Combat (12.0) interrupts work** – Life over gather, herd, build.
2. **Herd catchup (15.0) beats herd (11.0)** – Catch up to leader first.
3. **Combat (12.0) beats herd (11.0)** – Life over follow orders.
4. **Build (25.0) beats agro (10–12)** – Place land claim when 8+ items.
5. **Defend (11.0) beats herd_wildnpc (5.5–11.5)** – Clansmen defend when slot available.
6. **Gather blocked when breeding_females == 0** – Cavemen must get a woman first.

## Notes

- Priorities are evaluated every FSM cycle (throttled ~0.1s).
- States sorted by priority descending; first `can_enter() == true` wins.
- `can_enter()` can block a state regardless of priority.
- Min state change cooldown prevents rapid switching.
- Craft lock: only combat may interrupt when actively crafting.
