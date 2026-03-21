# Herding System Guide

**Last Updated:** 2026-02-18  
**Status:** Active System - Animal-Authoritative (Production Ready)

## Overview

The herding system allows cavemen (and the player) to bring wild NPCs (women, sheep, goats) into their land claim, where they join the clan. The system is **animal-authoritative**: each herdable has a HerdInfluenceArea (Area2D) that detects nearby herders; animals attach when herders enter range and influence exceeds a threshold. Herders do not own targets—they search or lead. This design enables competition between multiple cavemen and the player.

## Core Architecture

### Animal-Authoritative Model

1. **HerdInfluenceArea** – Each herdable (woman, sheep, goat) has an Area2D child that detects herders (cavemen, clansmen, player) via `body_entered` / `body_exited`.
2. **Influence accumulation** – When a herder is inside the radius, influence builds over time. After `contest_min_duration` above threshold, the animal calls `_try_herd_chance(herder, true)`.
3. **Attachment** – On success, the animal sets `is_herded = true`, `herder = leader`, enters `herd` state, and follows.
4. **Caveman flow** – Cavemen in `herd_wildnpc` state either **lead** (when herded_count > 0) or **search** (ray/cone or active seeking). They never "own" a target; animals attach when the caveman walks into their influence radius.

### Key Distances

| Parameter | Value | Config |
|-----------|-------|--------|
| HerdInfluenceArea radius | 250px | `herd_mentality_detection_range` |
| Active seeking range | 1700px | `herd_detection_range` |
| Deposit override range | 350px | (herdable this close bypasses deposit block) |
| Max distance from claim | 2000px | `herd_max_distance_from_claim` |
| Return to claim (no herd) | 600px | `herd_return_to_claim_distance` |
| Herd break distance | 300px | `herd_max_distance_before_break` |
| Follow distance min/max | 50 / 150px | `herd_follow_distance_min/max` |
| Land claim radius | 400px | (clan join when inside) |

### State Priorities

| State | Priority | Notes |
|-------|----------|-------|
| Agro | 15.0 | Highest – interrupts all |
| Herd (following) | 11.0 | NPCs following their herder |
| **Herd Wild NPC** (leading) | **11.5** | Above deposit – cavemen can interrupt deposit to herd |
| **Herd Wild NPC** (searching, no target) | **5.5** | `priority_herd_wildnpc_searching` — below gather (5.6+) so cavemen prefer gathering when no herd target |
| Deposit | 11.0 | Core gather→deposit loop |
| Gather | 5.6–6.0 | Beats herd-search (5.5); lower than herd when leading (11.5) |
| Wander | 1.0 | Fallback |
| Idle | 0.0 | Lowest |

## HerdInfluenceArea (Critical)

**File:** `scripts/npc/components/herd_influence_area.gd`

### Collision Setup (CRITICAL)

- **collision_mask = 3** – Must detect both layer 1 (player) and layer 2 (cavemen/clansmen).
- Cavemen use `collision_layer = 2` in `npc_base.gd`. The Area2D default `collision_mask = 1` would only detect the player; cavemen would never trigger `body_entered`.
- **Bug (fixed 2026-02-18):** With mask=1, cavemen herding was broken (0 deliveries). Setting mask=3 restored caveman herding (15+ deliveries in 2 min test).

### Influence System

- **Radius:** 250px (`herd_mentality_detection_range`)
- **Initial influence:** 55 (above threshold → near-instant attach when herder enters)
- **Threshold:** 50
- **Contest duration:** 0.08s (~5 frames)
- **Max herd size per herder:** 8
- **Combat lock:** Herd locked when leader has `combat_target`
- **Valid herders:** Player (group "player") or `npc_type` in ["caveman", "clansman"]

### Same-Clan and Stealing

- Same-clan herders cannot steal from each other.
- `follow_is_ordered` prevents stealing (player-ordered follows).

## Herd Wild NPC State

**File:** `scripts/npc/states/herd_wildnpc_state.gd`

### Flow (Target-Less)

1. **Enter** – No target required. Initialize search from land claim edge.
2. **If herded_count > 0** – Lead directly to claim (speed 0.9x). Animals follow via `herd` state.
3. **If herded_count == 0** – Search for herdables:
   - **Active seeking:** `_find_nearest_herdable_target(1700)` – path toward nearest wild woman/sheep/goat.
   - **Fallback:** Ray/cone search – walk straight-ish lines (120 px/s) from claim, rotate 45° when reaching max ray distance (1200px).
4. **Animals attach** – When caveman enters an animal's HerdInfluenceArea (250px), influence accumulates; after ~0.08s above threshold, `_try_herd_chance` runs and animal attaches.

### Entry Conditions (can_enter)

- Caveman or clansman only.
- Must have land claim (`clan_name != ""`).
- Not in exit cooldown (0.2s).
- Not in delivery cooldown (~18s config, 28s fallback).
- **Deposit block:** Not `moving_to_deposit` or `is_depositing`, OR herdable within 350px (override).
- **Inventory:** Under 65% full (`herd_inventory_entry_threshold`).
- **Searcher quota:** Claim's ClanBrain allows this caveman as searcher.
- **Distance:** Within 90% of max (1800px of claim).

### Exit Conditions

- No animals attached for **14s** (2× `herd_max_no_target_time`).
- Inventory ≥ 50% full or (herded_count ≥ 2 and within 150px of claim) → exit to wander for deposit.
- Farther than 600px from claim with no herd → return to wander.
- Too far from claim (>90% of 2000px) → blocked from re-entry.

## Herd State (Followers)

**File:** `scripts/npc/states/herd_state.gd`

- **Entry:** `is_herded == true`, valid `herder`, not dead.
- **Follow distances:** Min 50px, max 150px, ideal ~100px.
- **Herd break:** If herder > 300px away, `_clear_herd()`, exit herd state.
- **Clan join:** When inside herder's land claim (≤400px from center), `_try_join_clan_from_claim()` runs; NPC joins clan, `_clear_herd()`, exits herd.

## Herding Chance (npc_base._try_herd_chance)

- **Range:** Leader within 150px of target (200px when `force_influence_transfer` from HerdInfluenceArea).
- **Chance:** 10% at 150px, 80% at <50px; linear interpolation.
- **Resist chance:** ~10% base (`herd_resist_chance_base`) – animal can resist even when challenger would win.
- **Stealing:** Stealer must be closer than current herder; steal chance = 25% of normal; reduced when herder within 150px.

## Delivery Cooldown

When an animal joins clan in `_try_join_clan_from_claim()`, it sets `herder.set_meta("herd_wildnpc_delivery_cooldown_until", current_time + cooldown)` before `_clear_herd()`. Caveman cannot enter `herd_wildnpc` until cooldown expires.

- **Config:** `herd_delivery_cooldown_sec` = 18s
- **Fallback constant:** 28s

## Competitive Mechanics

- Multiple cavemen and the player compete for wild NPCs.
- Animals attach to the herder with highest influence (tie-breaker: smaller distance).
- Stealing: a closer herder can take an already-herded NPC.
- Same-clan herders cannot steal from each other.

## Configuration (npc_config.gd)

```gdscript
# Detection & Search
herd_detection_range = 1700.0           # Active seeking range (px)
herd_mentality_detection_range = 250.0  # HerdInfluenceArea radius
herd_inventory_entry_threshold = 0.65   # Max 65% full to enter
herd_max_no_target_time = 7.0           # Base; exit after 2× = 14s
herd_delivery_cooldown_sec = 18.0       # After delivery
herd_return_to_claim_distance = 600.0   # Return when no herd
herd_max_distance_from_claim = 2000.0   # Max search distance
herd_max_distance_before_break = 300.0   # Herd breaks if herder this far

# Influence (HerdInfluenceArea)
influence_base_rate = 40.0
influence_threshold = 50.0
contest_min_duration = 0.08
initial_influence = 55.0
herd_resist_chance_base = 0.10

# Priorities
priority_herd_wildnpc = 11.5          # When leading (herded_count > 0) or target in range
priority_herd_wildnpc_searching = 5.5 # When no target — below gather (5.6) so cavemen prefer gathering
priority_deposit = 11.0
# See GatherGuide.md for priority_gather_other (5.6) and productivity mode.
```

## Related Files

- `scripts/npc/components/herd_influence_area.gd` – Area2D on herdables; **collision_mask = 3**
- `scripts/npc/states/herd_wildnpc_state.gd` – Caveman herding state
- `scripts/npc/states/herd_state.gd` – Follower state
- `scripts/npc/npc_base.gd` – `_try_herd_chance()`, clan join, HerdInfluenceArea creation
- `scripts/config/npc_config.gd` – Configuration
- `scripts/npc/fsm.gd` – State machine
- `guides/Phase4/herd4.md` – Canonical definitions (herd4)

## Recent Fixes (2026-02-18)

### Collision Mask Fix

**Problem:** Cavemen never herded. HerdInfluenceArea used default `collision_mask = 1`, which only detects bodies on layer 1 (player). Cavemen use `collision_layer = 2`, so `body_entered` never fired for them.

**Solution:** Set `collision_mask = 3` in HerdInfluenceArea to detect both layer 1 and layer 2.

**Result:** Herding deliveries increased from 0 to 15+ in 2 min test. Cavemen now successfully herd goats, sheep, and women into their claims.
