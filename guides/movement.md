# Movement Guide

**Last Updated:** 2026-02-21

## Overview

NPCs use a **SteeringAgent** for movement; the player uses direct velocity. Both use `CharacterBody2D` and `move_and_slide()`.

---

## Player Movement

**File:** `scripts/player.gd`

- **Speed:** `move_speed` (default 200)
- **Input:** `input_vector` from move_right/left, move_down/up; normalized
- **Modifiers:**
  - Hunger < 30%: `speed_mult = 0.7`
  - Herding (`herded_count > 0`): `speed_mult *= 0.97` (NPCConfig.herd_leader_speed_multiplier)
- **Output:** `velocity = input_vector * (move_speed * speed_mult)`
- No ramp-up/ramp-down; instant speed changes

---

## NPC Movement (SteeringAgent)

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
| `herd_leader_speed_multiplier` | 0.97 | When leading herd |

### Steering Flow

1. `get_steering_force(delta)` computes desired velocity
2. Combines: seek/arrive/flee/wander + separation + land claim avoidance + boundary
3. Intent delay (100–300ms) before committing target changes to reduce oscillation
4. Stuck detection: if moved < 50px for 1s and pathfinding blocked by 4+ claims → switch to wander

### Oscillation Prevention

- `min_target_change_interval` (0.5s) – throttle target changes
- `force_dead_zone` (5.0) – ignore tiny forces
- `velocity_reversal_count` – detect rapid direction flips
- Intent delay – commit target after 100–300ms
- Arrival offset (±6px) – NPCs don’t stack on exact spot

---

## NPC Movement Integration

**File:** `scripts/npc/npc_base.gd` (`_physics_process`)

1. Idle/dead/frozen → `velocity = 0`
2. Crafting/gathering → `velocity = 0` (must stay in place)
3. Task controls movement (MoveToTask, DropOffTask) → task sets velocity
4. Else → `steering_agent.get_steering_force(delta)` → apply to velocity
5. Optional movement variation (organic feel) when moving
6. `move_and_slide()`

### Caveman Flee

- When not in agro/combat and player within 80px → `set_flee_target(player_pos)`

---

## Design Notes (Future)

- Fluid organic movement: ramp up to max speed when moving, ramp down when stopping
- Detailed idle animations for different modes/postures
- Always eliminate oscillation issues
