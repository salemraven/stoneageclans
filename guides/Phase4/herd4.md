# Herding & Herd Deposit – Definitions

**Version**: 5 (animal-authoritative)  
**Purpose**: Canonical definitions of how herding and herd deposit (delivery) work in the codebase.

---

## Overview

**Herding**: Animal-authoritative. Wild NPCs (women, sheep, goats) have HerdInfluenceArea. When cavemen, clansmen, or player enter range, influence accumulates. After contest window, animal attaches to best herder. Herders do not own targets; they own intent (search or lead).

**Herd deposit (delivery)**: Follower joins clan inside herder's claim. Animal sets delivery cooldown on herder before `_clear_herd()`.

---

## Herding (Animal-Authoritative)

**What it is**: Cavemen/clansmen enter `herd_wildnpc` state (target-less). If `herded_count > 0`: lead to claim. Else: spiral search. Animals detect herders via HerdInfluenceArea (Area2D), accumulate influence, and call `_try_herd_chance(leader, true)` when threshold held for contest_min_duration.

### Who Can Herd

- **Cavemen** and **clansmen** (herd_wildnpc state)
- **Player** (animals attach when player in HerdInfluenceArea)
- Must have clan to enter herd_wildnpc (cavemen/clansmen)

### Who Can Be Herded

- **Wild** women, sheep, goats (`clan_name == ""`)
- HerdInfluenceArea on each herdable

### HerdInfluenceArea (scripts/npc/components/herd_influence_area.gd)

- **Radius**: 200px (herd_mentality_detection_range)
- **Detection**: body_entered/body_exited on npcs + player groups
- **Influence**: Base rate + proximity factor; decay when out of range
- **Threshold**: influence_threshold (default 50); must hold for contest_min_duration (0.75s)
- **Tie-breaker**: If influence equal, choose smaller distance (deterministic)
- **max_herd_size**: Don't attach if herder.herded_count >= 8
- **Combat lock**: Herd locked when leader has combat_target

### Herd Wild NPC State Flow (Target-Less)

1. **Enter**: No target required. Initialize spiral search from land claim.

2. **If herded_count > 0**: Lead to claim (speed 0.9). Animals follow via herd state.

3. **If herded_count == 0**: Spiral search pattern. Animals attach when herder enters their HerdInfluenceArea (influence + contest).

4. **Exit**: No animals attached for 14s (2× max_no_target_time); inventory 50%+; herded_count >= 2 and near claim (deposit); too far from claim with no herd.

### Herding Chance (`_try_herd_chance` on target)

- **Range**: Leader within **150px** of target.
- **Chance**: 10% at 150px, 80% at very close (<50px); linear in between (`proximity_factor = 1 - distance/150`).
- **Stealing** (target already herded by someone else):
  - Stealer must be **closer** than current herder.
  - Steal chance = 25% of normal; if herder within 150px, further reduced (0.1× at 0px from herder to 1.0× at 150px).
  - Must be within **100px** for effective steal (else chance reduced up to 80%).
  - **1s cooldown** between steals.
- **Same clan**: Cannot steal from a clan mate.
- **Ordered follow**: If target has `follow_is_ordered`, cannot be stolen.
- On success: `is_herded = true`, `herder = leader`, `herd_mentality_active = true`; target FSM enters herd (priority 11.0).

### Follower (Herd State)

- **When**: `is_herded == true`, `herder` valid, not dead.
- **Follow distances**: min **50px**, max **150px** (NPCConfig herd_follow_distance_min/max); ideal ~100px. If hostile: 40–120px, max 250px.
- **Herd break distance**: **300px** (NPCConfig.herd_max_distance_before_break). If herder farther, herd breaks: `_clear_herd()`, exit herd state.
- **Movement**: Target position = herder position + offset (update every 0.3s); steering seek to that; speed 1.0 (or 0.15 when backing up).
- **Clan join check**: Each frame, `_check_clan_joining()` in herd_state; also npc_base checks every 0.2s when wild + herded (inside claim belonging to herder → join clan).

### Code

- `scripts/npc/states/herd_wildnpc_state.gd` – caveman/clansman herding
- `scripts/npc/states/herd_state.gd` – follower follow + clan join
- `scripts/npc/npc_base.gd` – `_try_herd_chance()`, periodic clan-join when herded inside herder's claim

---

## Herd Deposit (Delivery)

**What it is**: The herded NPC is brought into the herder's land claim and joins the clan. That counts as a "delivery"; the caveman then has a cooldown before re-entering herd_wildnpc.

### When Delivery Happens

1. **Follower joins clan**: In npc_base `_try_join_clan_from_claim()`, when animal joins (inside herder's claim, claim_clan == herder_clan), animal sets `herder.set_meta("herd_wildnpc_delivery_cooldown_until", ...)` before `_clear_herd()`.

### How Joining Works (the "deposit")

- **Where**: Follower must be **inside** a land claim (distance to claim center ≤ radius, 400px).
- **Whose claim**: Claim's `clan_name` must equal herder's clan (player-owned for player, or caveman's clan for caveman).
- **Checks**:
  - In **herd_state**: `_check_clan_joining()` each frame – if inside claim and claim is herder's and `can_join_clan()`, set `clan_name = claim_clan`, `_clear_herd()`, change state to wander.
  - In **npc_base**: Every 0.2s, if wild + herded and inside a claim and claim_clan == herder_clan and `can_join_clan()`, set `clan_name = claim_clan` (and for women, re-init reproduction component).
- **After join**: `is_herded = false`, `herder = null` (via `_clear_herd()`); NPC exits herd state, enters wander; no longer wild.

### Delivery Cooldown (Caveman)

- When animal joins clan in `_try_join_clan_from_claim()`, animal sets `herder.set_meta("herd_wildnpc_delivery_cooldown_until", current_time + 28)` before `_clear_herd()`.
- **can_enter(herd_wildnpc)** fails while `current_time < herd_wildnpc_delivery_cooldown_until`.
- Config: herd_delivery_cooldown_sec (28s).

### Alternative: Land Claim Placed on Them

- If the **player** places a land claim and a wild (or herded) woman is inside it, main.gd `_handle_npcs_in_new_land_claim` auto-joins her: `set_clan_name(clan_name)`, release from herd. That is not "herd deposit" by a caveman but has the same result (woman in clan).

### Code

- npc_base `_try_join_clan_from_claim()`: sets delivery cooldown on herder before `_clear_herd()`
- herd_state: `_check_clan_joining()`
- npc_base: periodic clan join when herded + inside herder's claim
- main.gd: `_handle_npcs_in_new_land_claim` (player claim placed)

---

## Constants Summary

| Constant | Value | Location |
|----------|-------|----------|
| HerdInfluenceArea radius | 200px | NPCConfig.herd_mentality_detection_range |
| Influence threshold | 50 | NPCConfig.influence_threshold |
| Contest min duration | 0.75s | NPCConfig.contest_min_duration |
| max_herd_size | 8 | NPCConfig.max_herd_size |
| Herding range (_try_herd_chance) | 150px | npc_base; 200px when force_influence_transfer |
| Max distance from claim | 2000px | NPCConfig.herd_max_distance_from_claim |
| Return to claim (no herd) | 600px | NPCConfig.herd_return_to_claim_distance |
| Follow distance min/max | 50 / 150px | NPCConfig herd_follow_distance_min/max |
| Herd break distance | 300px | NPCConfig.herd_max_distance_before_break |
| Delivery cooldown | 28s | NPCConfig.herd_delivery_cooldown_sec |
| agro_steal_attempt | 20 | NPCConfig (failed steal attempt) |
| agro_steal_success | 40 | NPCConfig (successful steal) |

---

## Flow Overview

```
HERDING (animal-authoritative):
  Caveman in herd_wildnpc → spiral search (or lead if herded_count > 0) →
  Animal's HerdInfluenceArea detects caveman → influence accumulates →
  After contest_min_duration (0.75s) above threshold → _try_herd_chance(caveman, true) →
  target.is_herded=true, herder=caveman → target enters herd state →
  herded_count increments → caveman leads to claim

HERD DEPOSIT (DELIVERY):
  Follower in herd state, inside herder's claim (≤400px) →
  _try_join_clan_from_claim() → herder.set_meta(delivery_cooldown) → _clear_herd() →
  follower exits herd, enters wander (now clanswoman/etc.)
```
