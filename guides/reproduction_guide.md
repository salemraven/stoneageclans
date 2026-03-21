# Reproduction Guide

**Last Updated:** 2026-02-21  
**Status:** Active System

## Overview

Clan women reproduce with male cavemen (or the player) inside a land claim. Babies spawn as NPCs, grow to clansmen after a timer, and receive clubs. Wild women cannot reproduce—they must be herded into a land claim and join the clan first.

## Flow

1. Cavemen (or player) herd wild women into the land claim via `herd_wildnpc` / `herd` states.
2. When a herded woman enters the land claim radius, she joins the clan via `set_clan_name(clan_name)`.
3. `ReproductionComponent` runs each frame: finds a mate (player or caveman in same clan, inside claim), starts pregnancy, counts down birth timer.
4. When timer hits 0, `main._spawn_baby()` spawns a baby NPC at the land claim center.
5. `BabyGrowthComponent` ages the baby; after 35 seconds the baby becomes a clansman and gets a club.

---

## Requirements for Reproduction

All must be true:

| Requirement | Where checked |
|-------------|---------------|
| `npc_type == "woman"` | `reproduction_component.gd`, `reproduction_state.gd` |
| `clan_name != ""` | `reproduction_component.gd` |
| Woman inside land claim radius | `_is_in_land_claim()` |
| Mate (player or caveman) in same clan | `_try_find_mate()` |
| Mate inside land claim | `_is_player_in_land_claim()`, `_is_npc_in_land_claim()` |
| Not pregnant | `is_pregnant == false` |
| Birth cooldown expired | `time_since_last_birth >= config.birth_cooldown` |

---

## Key Files

| File | Purpose |
|------|---------|
| `scripts/npc/components/reproduction_component.gd` | Pregnancy logic, mate finding, birth timer, spawn call |
| `scripts/npc/states/reproduction_state.gd` | FSM state (priority 8.0); logic in component |
| `scripts/config/reproduction_config.gd` | Birth timer, cooldown, baby pool capacity |
| `scripts/systems/baby_pool_manager.gd` | Capacity tracking; `can_add_baby()` always returns true |
| `scripts/npc/components/baby_growth_component.gd` | Baby aging → clansman transition |
| `scripts/main.gd` | `_spawn_baby()` – instantiates baby, sets lineage, sprite |

---

## Configuration

### ReproductionConfig

| Property | Default | Notes |
|----------|---------|------|
| `birth_timer_base` | 30.0 | Pregnancy duration (seconds) |
| `birth_cooldown` | 20.0 | Seconds between births per woman |
| `baby_pool_base_capacity` | 3 | Base capacity from land claim |
| `living_hut_capacity_bonus` | 5 | Per Living Hut |
| `baby_growth_time_testing` | 35.0 | Seconds until baby → clansman |
| `baby_growth_age_normal` | 13 | Age for normal mode (unused) |

### BalanceConfig

| Property | Default |
|----------|---------|
| `pregnancy_seconds` | 30.0 |
| `baby_growth_seconds` | 35.0 |

---

## Mate Selection

- Candidates: player (if same clan, inside claim) + NPC cavemen (same clan, inside claim).
- Selection: prefer player, else first NPC. No distance or trait checks.

---

## ClanBrain Integration

ClanBrain stores on land claim meta:

| Meta key | Source | Used by |
|----------|--------|---------|
| `breeding_females` | Count of women in clan | `gather_state`, `herd_wildnpc_state` |
| `reproduction_pressure` | 0–1, how much clan needs women | `herd_wildnpc_state` |

### reproduction_pressure

- `desired_women = max(2, population * 0.4)`
- `pressure = clamp((desired_women - women) / desired_women, 0, 1)`
- When 0 women: pressure ≈ 1.0.

### breeding_females == 0

- **gather_state:** `can_enter()` returns false.
- **herd_wildnpc_state:** Skips return-to-claim and timeout exits; caveman keeps searching.
- **herd_wildnpc_state:** Uses full detection range (1700px) for women instead of perception (250px).

---

## Baby Spawning

1. `reproduction_component._spawn_baby()` checks `baby_pool_manager.can_add_baby()` (always true).
2. `main._spawn_baby(clan_name, spawn_pos, mother, father)`:
   - Instantiates NPC, sets `npc_type = "baby"`, `clan_name`, `age = 0`.
   - Sets `father_name`, `mother_name` (lineage).
   - Uses `baby.png` sprite.
   - Adds to `world_objects`, positions at land claim center.
3. Baby gets `BabyGrowthComponent`; after 35s becomes clansman, gets club, inventory upgraded to 10 slots.

---

## State Priorities

| State | Priority | Notes |
|-------|----------|------|
| Herd Wild NPC (leading) | 11.5 | Caveman leading herd |
| Herd Wild NPC (searching, target) | 6.1 | When `reproduction_pressure >= 0.8` |
| Herd Wild NPC (searching, no target) | 5.5 | Below gather |
| Reproduction | 8.0 | Women seeking mates or gestating |
| Gather | 5.6–6.0 | Blocked when `breeding_females == 0` |

---

## Baby Pool

- Capacity: base 3 + (Living Huts × 5).
- `can_add_baby()` always returns true (cap disabled).
