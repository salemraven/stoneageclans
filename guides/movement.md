# Movement Guide

**Last updated:** 2026-05-06

## Overview

NPCs use a **SteeringAgent** for movement; the player uses direct velocity. Both use `CharacterBody2D` and `move_and_slide()`.

**RTS / squad movement** (ordered clansmen, stances, formations) is documented in **[`guides/rts.md`](rts.md)**. This file covers **locomotion** and how formations plug into steering.

---

## Player movement

**File:** `scripts/player.gd`

- **Speed:** `move_speed` (default **110** px/s — aligned with clansman pace + formation tuning)
- **Input:** `input_vector` from move_right/left, move_down/up; normalized
- **Modifiers (multiplied together):**
  - Below 30% hunger: ×0.7
  - **Herd leader debuff:** only when leading **herd animals** (women / sheep / goats) — `HerdManager.get_herd_animal_count(self) > 0` → ×`NPCConfig.herd_leader_speed_multiplier` (default **0.97**). **Ordered clansmen-only** parties do **not** apply this debuff.
  - **Formation stance debuff:** `formation_speed_mult` meta — slowest stance among active ordered followers: **Follow 1.0×**, **Guard 0.75×**, **Attack 0.85×** (see `FormationUtils.STANCE_SPEED_MULT` / `main` stance updates).
- **Output:** `velocity = input_vector * (move_speed * speed_mult)`
- **`formation_velocity`** meta is set each frame to the player’s actual pixel velocity so followers can match facing / slot math.
- No ramp-up/ramp-down; instant speed changes

---

## Ordered clansmen & formations (summary)

Full behavior, controls, and stance strategy: **[`guides/rts.md`](rts.md)**.

| Piece | Role |
|--------|------|
| **`FormationUtils.compute_formation_slots()`** | Slot positions per follower: **FOLLOW** = rear arc behind leader (facing-relative); **GUARD** = ring; **ATTACK** = line ahead along facing, spread perpendicular. |
| **`scripts/config/rts_formation_config.gd`** (`RTS_CONFIG`) | Tunables: follow arc distance/angle, attack forward/lateral spacing, lookahead, leash, catch-up, anchor deadzone on world X, etc. |
| **`main._update_formation_slots()`** | Each frame: leader anchor (`apply_world_anchor_deadzone_ew`), facing from `FormationUtils.get_leader_facing`, then writes **`formation_slots`** on the **player** meta. |
| **`party_state.gd`** | Ordered followers read shared slots; steering targets + **`_apply_formation_speed`** apply stance multipliers and catch-up when moving in formation. |
| **NPC raid / NPC-led parties** | **`FormationUtils.publish_slots_for_npc_leader()`** — same slot math; only the lowest `instance_id` follower publishes once per party per frame. |

**Performance note:** follower collection for NPC leaders scans the `npcs` group — fine at current scale; very large maps may need a per-leader follower index later.

---

## NPC movement (SteeringAgent)

**File:** `scripts/npc/steering_agent.gd`

### Modes

| Mode | Use |
|------|-----|
| SEEK | Move toward target (no slowdown) |
| ARRIVE | Move toward target, slow near it |
| FLEE | Move away from target |
| WANDER | Random points within radius |

### Config (NPCConfig)

| Property | Default | Notes |
|----------|---------|------|
| `max_speed_base` | 95 | Base speed |
| `speed_agility_multiplier` | 9.5 | `max_speed = agility * multiplier` |
| `max_force` | 40 | Steering force cap |
| `arrive_radius` | 100 | Start slowing |
| `arrive_slowdown_radius` | 200 | Gradual slowdown |
| `herd_leader_speed_multiplier` | 0.97 | Applied to **player** when leading herd **animals** (not clansmen-only squads) |

### Steering flow

1. `get_steering_force(delta)` computes desired velocity
2. Combines: seek/arrive/flee/wander + separation + land claim avoidance + boundary
3. Intent delay (100–300ms) before committing target changes to reduce oscillation
4. Stuck detection: if moved &lt; 50px for 1s and pathfinding blocked by 4+ claims → switch to wander

### Oscillation prevention

- `min_target_change_interval` (0.5s) – throttle target changes
- `force_dead_zone` (5.0) – ignore tiny forces
- `velocity_reversal_count` – detect rapid direction flips
- Intent delay – commit target after 100–300ms
- Arrival offset (±6px) – NPCs don’t stack on exact spot

### Temporary speed multipliers

**File:** `steering_agent.gd` — `set_speed_multiplier(m)` sets `max_speed = original_max_speed * m`; `restore_original_speed()` restores **`original_max_speed`**. Used for deposits, scripted slows, etc.

**Deer (`flee_prey`):** **Burst panic sprint** applies **`NPCConfig.deer_flee_burst_speed_mult`** during the **burst** phase; **winded** applies **`deer_winded_speed_mult`**; leaving **`flee_prey`** restores base speed. Details: **`guides/Phase4/raiding_hunting.md`** §5, **`guides/wildlife_movement.md`**.

---

## NPC movement integration

**File:** `scripts/npc/npc_base.gd` (`_physics_process`)

1. Idle/dead/frozen → `velocity = 0`
2. Crafting/gathering → `velocity = 0` (must stay in place)
3. Task controls movement (MoveToTask, DropOffTask) → task sets velocity
4. Else → `steering_agent.get_steering_force(delta)` → apply to velocity
5. **NPC party leaders:** if `HerdManager.has_party_ordered_followers(self)`, multiply desired velocity by **`formation_speed_mult`** meta (match the warband’s slowest stance)
6. Optional movement variation (organic feel) when moving
7. `move_and_slide()`

### Caveman flee

- When not in agro/combat and player within 80px → `set_flee_target(player_pos)`

---

## FSM evaluation vs distance scaling

Two mechanisms reduce how often the NPC FSM re-evaluates states when NPCs are far from the **first player** in the `player` group:

1. **`scripts/npc/fsm.gd`** — `NEAR_PLAYER_DISTANCE` (800 px): beyond that, `evaluation_interval` uses `FAR_EVALUATION_INTERVAL` (0.25 s vs 0.1 s).
2. **`scripts/npc/npc_base.gd`** — When `NPCConfig.distance_update_scale_enabled`, distance to the same player vs `distance_threshold_half_rate` / `distance_threshold_quarter_rate` can **skip entire FSM ticks** (accumulator + `effective_delta == 0`), unless combat/agro forces full rate.

Combat/agro skips the npc_base distance throttle so fights stay responsive. Tune both in `NPCConfig`; see also [`guides/phase2/STATE_PRIORITIES.md`](phase2/STATE_PRIORITIES.md).

---

## Design notes (future)

- Fluid organic movement: ramp up to max speed when moving, ramp down when stopping
- Detailed idle animations for different modes/postures
- Always eliminate oscillation issues
