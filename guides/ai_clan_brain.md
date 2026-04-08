# AI Clan Brain System

**Status:** Implemented. Defense, searcher, and raid systems active; strategic pressures drive quotas.  
**Last Updated:** 2026-02-21 (metric-driven evaluation loop added)

## Overview

AI controller for NPC clans. It:

- Sets **defender** and **searcher** quotas on the land claim (NPCs self-assign via pull-based model)
- Requires **minimum land claim stock** (10 stone, 10 wood, 10 food) before allowing defenders, unless under alert
- Runs full assignment logic only when clan has **2+ cavemen/clansmen** (single caveman stays free to herd/gather)
- **Player clans:** Quota = **max(n/4, defender pool size)**. Example: 4 fighters → base 1 defender; drag a second clansman to the **map outside** the claim → pool 2 → quota 2 (**2:2**). Drag **inside** the claim → work, pool drops, quota follows; no raid evaluation
- **NPC clans:** Can set **raid intent**; raiders discover intent and self-assign via RaidState
- Tracks resources, threats, strategic state, and alert level

**Location:** `scripts/ai/clan_brain.gd` (RefCounted; no `_process`. Land claim calls `brain.update(delta)` each frame.)

**Combat allies:** Friendly-fire rules (same clan, herder/party, shared defend/search claim, player-owned claim ties, `get_my_land_claim()` match) live in **`CombatAllyCheck.is_ally(a, b)`** (`scripts/systems/combat_ally_check.gd`). Perception, hostile index, agro, combat state, hit validation, and retaliation all call it—do not duplicate inline `clan_a == clan_b` checks elsewhere. Call sites use `const CombatAllyCheck = preload("res://scripts/systems/combat_ally_check.gd")` so autoloads/CLI parse before the global class cache is built.

---

## Main loop

- **Land claim** calls `clan_brain.update(delta)` every frame.
- Each frame: **alert decay** is updated; for NPC clans, **raid state** is updated (`_update_raid()`).
- Every **EVALUATION_INTERVAL** (5s):
  1. `_evaluate_clan_state()` — refresh clan members, resources; **evaluate metrics**; update economic weights; update threat and pressures; update defender and searcher assignments
  2. For NPC clans only: `_make_strategic_decisions()` — update strategic state (PEACEFUL/DEFENSIVE/AGGRESSIVE/RAIDING/RECOVERING) and optionally evaluate raid
  3. `_update_land_claim_ratios()` — write `defend_ratio` (defender_quota / fighters) and `search_ratio` to land claim
- **Threat cache** (enemy threat scores) is refreshed every **THREAT_CACHE_INTERVAL** (30s), NPC clans only.

---

## When the brain runs (assignment logic)

- **2+ cavemen/clansmen:** Full evaluation: threat, pressures, defender quota, searcher quota. Single-caveman exception: if not in emergency (player emergency defend or RAID alert), defender quota is 0 and all defenders are evicted so the single caveman can leave to gather/herd.
- **&lt; 2 cavemen:** Defender quota forced to 0, all defenders evicted. When **no breeding females**, searcher_quota = 1 (lone caveman looks for woman); otherwise searcher_quota = 0.

---

## Defense system

### Gates (in order)

1. **Clansmen count:** If `cavemen.size() < 2` and not in emergency, defender_quota = 0 and all defenders evicted.
2. **Minimum stock:** If land claim has &lt; 10 stone, &lt; 10 wood, or &lt; 10 total food (berries + grain + bread), and **alert_level &lt; INTRUDER**, defender_quota = 0 and all defenders evicted. (When alert ≥ INTRUDER, the min-stock gate is skipped so threatened clans can defend even when poor.)
3. **Player emergency defend:** If the player clicked DEFEND on the claim, quota = all fighters until **PLAYER_EMERGENCY_DEFEND_COOLDOWN** (30s) has passed since last intrusion.
4. **RAID alert:** Quota = all fighters.
5. **Otherwise:** **Baseline** `target_defenders = cavemen.size() / 4` (3 workers : 1 defender per block of four). **AI only:** if **INTRUDER ≤ alert &lt; RAID**, `target_defenders = max(baseline, ceil(cavemen.size() * defend_pressure))`. **Player:** after pruning the defender pool, `target_defenders = max(baseline, assigned_defenders.size())` so drag-out extras keep a slot. Clamped to [0, cavemen.size()].

### Assignment

Pull-based. NPCs in **defend_state** `can_enter()` read `land_claim.get_meta("defender_quota")` and `land_claim.assigned_defenders.size()`; if under quota they call `land_claim.add_defender(npc)` and set `defend_target`. Land claim stores `assigned_defenders` and prunes invalid refs.

### Threat and pressure

- **Threat level** (0.0–1.0): From cached enemy threat scores (distance, enemy strength, defender count, alert). Alert adds: INTRUDER +0.1, SKIRMISH +0.3, RAID +0.5.
- **defend_pressure** (AI) starts at BASE_DEFENSE_RATIO (0.2), increased by threat and resource urgency, clamped to MIN_DEFENSE_RATIO (0.1) – MAX_DEFENSE_RATIO (0.6). It scales **extra** defender slots above the **n/4** baseline when alert is INTRUDER or SKIRMISH (not RAID; RAID uses full quota earlier).
- **search_pressure** and **gather_pressure** are set in `_update_pressures()` (metric-driven: +0.3 search when no breeding females; +0.2 gather when food_days_buffer &lt; 2; small clans get higher search pressure).

---

## Alert system

- **AlertLevel:** NONE, INTRUDER, SKIRMISH, RAID.
- **Land claim** calls `clan_brain.on_alert(level)` when intrusion/combat/raid is detected (e.g. `trigger_alert(1)` for INTRUDER, 2 for SKIRMISH, 3 for RAID).
- **on_alert(level):** Updates `last_intrusion_time`; if new level &gt; current, sets `alert_level` and calls `_recalculate_quotas_immediately(level)` (adjust defend_pressure, update defender/searcher assignments, and on RAID: cancel raids, force_defend_all).
- **Decay:** Every **ALERT_DECAY_TIME** (10s), alert steps down: RAID → SKIRMISH → INTRUDER → NONE. On decay, pressures and quotas are recalculated.

---

## Raiding system (NPC clans only)

Pull-based: ClanBrain sets **raid_intent** on the land claim; NPCs in **raid_state** read it and self-organize.

### Raid party (NPC-led formations)

When **`_start_raid`** succeeds, **`_form_raid_party`** picks the first available non-defender fighter as **leader** and assigns up to **`raider_quota − 1`** followers with **`follow_is_ordered`**, **`herder` = leader**, **`PartyCommandUtils`** command context (default FOLLOW), **`HerdManager.register_follower`**, and FSM **`party`**. Followers use the same **`FormationUtils`** slot geometry as player-led squads. **`_complete_raid`** / **`_cancel_raid`** call **`_disband_raid_party`** to clear follow bindings and metas. Instrumentation: **`party_formed`**, **`party_disbanded`**, **`party_formation_tick`** (JSONL when capture is on).

### Raid intent (stored on ClanBrain and duplicated to land_claim meta)

- **state:** RaidState enum: NONE, RECRUITING, ACTIVE, RETREATING
- **target:** Enemy land claim node
- **target_position,** **rally_point:** Vector2
- **raider_quota:** Number of raiders wanted
- **start_time:** For timeouts

### When raids are considered

- Only when **strategic_state** is PEACEFUL or AGGRESSIVE.
- Not during **alert_level ≥ SKIRMISH** (we’re under attack).
- **RAID_COOLDOWN** (60s) must have passed since last raid start.
- Need at least **MIN_RAID_PARTY_SIZE + 1** cavemen (so at least one can stay to defend).
- **available_for_raid** = cavemen.size() - defender_quota must be ≥ MIN_RAID_PARTY_SIZE (2).

### Score-based raid evaluation

A single **score** is computed from several signals (threshold to start raid = **1.0**):

1. **Food pressure:** If food_ratio &lt; raid_hunger_threshold (0.3), add up to 0.4 from (1 - food_ratio).
2. **Population pressure:** clan_members.size()/10 × raid_population_pressure × 0.3.
3. **Aggression:** raid_aggression × 0.3 (per-clan tunable, 0–1).
4. **Weak enemy:** If `_find_weak_enemy()` returns a claim (enemy within RAID_DISTANCE_MAX, not too strong vs our available raiders), add raid_opportunity_weight (0.4).
5. **Strategic state:** AGGRESSIVE +0.2, DEFENSIVE -0.3.

If **score ≥ 1.0** and there is a valid target (weak enemy or best raid target), **raid starts**: raid_intent set to RECRUITING, rally/target/raider_quota filled, intent copied to land_claim meta. Otherwise no raid (e.g. “no_weak_enemy” if score high but no target).

### Raid state machine (_update_raid)

- **RECRUITING:** When `_count_active_raiders()` (NPCs with meta "raid_joined") ≥ MIN_RAID_PARTY_SIZE, switch to ACTIVE. If 30s pass without enough raiders, cancel raid (recruitment_timeout).
- **ACTIVE:** If enemy fighters at target = 0, switch to RETREATING. If raider count &lt; MIN_RAID_PARTY_SIZE, cancel (raiders_lost).
- **RETREATING:** After 60s total raid time, complete raid (timeout). Intent cleared, strategic_state = RECOVERING.
- **Target invalid:** Complete raid (target_destroyed).

### NPC raid API (NPCs call these)

- `should_npc_raid(npc)` — true if raid state ≠ NONE, npc valid, not in assigned_defenders, and raider count &lt; raider_quota.
- `npc_join_raid(npc)` / `npc_leave_raid(npc)` — set/remove meta "raid_joined".
- `get_raid_intent()`, `get_raid_target_position()`, `get_raid_rally_point()` — for RaidState movement/engagement.

### Raid constants

- MIN_RAID_PARTY_SIZE = 2, MAX_RAID_PARTY_SIZE = 8, MIN_DEFENDERS_DURING_RAID = 0.3, RAID_COOLDOWN = 60s, RAID_DISTANCE_MAX = 1500.

---

## Strategic state (NPC clans)

- **StrategicState:** PEACEFUL, DEFENSIVE, AGGRESSIVE, RAIDING, RECOVERING.
- **Transitions** (in `_make_strategic_decisions`): Driven by alert_level and threat_level. Don’t leave RAIDING unless under SKIRMISH+; don’t leave RECOVERING for 30s after raid. Otherwise: alert ≥ RAID → DEFENSIVE; threat &gt; 0.6 → DEFENSIVE; threat &gt; 0.3 and cavemen &gt; 3 → AGGRESSIVE, else DEFENSIVE; else PEACEFUL.
- **Raid evaluation** runs only when state is PEACEFUL or AGGRESSIVE.

---

## Resource status

- **resource_status** dict: keys "wood", "stone", "fiber", "berries". Each value: `{ "current", "target", "critical" }` (e.g. wood: 50 target, 10 critical).
- Filled from **land claim inventory** in `_refresh_resource_status()` (each evaluation).
- **Food for defend gate** uses land claim inventory: berries + grain + bread total ≥ MIN_FOOD_FOR_DEFEND (10).
- Helpers: `get_gathering_priorities()`, `get_most_needed_resource()`, `_calculate_food_ratio()`, `_calculate_resource_urgency()`.

---

## Clan metrics (metric-driven quota updates)

ClanBrain populates **clan_metrics** each evaluation cycle; these drive quota and weight updates.

| Metric | Description |
|--------|-------------|
| population | Total clan members (cavemen + clansmen + women + animals) |
| breeding_females | Women in clan |
| food_total | Berries + grain + bread in land claim inventory |
| food_days_buffer | Proxy: food_total / max(1, population × FOOD_PER_DAY_PROXY) |
| herd_value | Women + sheep + goats in clan |
| building_count | Buildings (non-claim) with same clan_name |
| recent_losses | From land_claim meta "recent_herd_losses" (future: increment on herd steal) |

**economic_priority_weights** (0.0–1.0) are stored on land claim for FSM/job selection: food_weight, resource_weight, build_weight, herd_weight. ClanBrain sets them from metrics (e.g. food_weight = 1.2 when food_days_buffer &lt; 2; herd_weight = 1.0 when no breeding females and population ≥ 1).

---

## Searcher assignments

- **searcher_quota** and **defenders_can_search** are set on the land claim.
- While **RAIDING** or **alert ≥ SKIRMISH**, searcher_quota = 0, defenders_can_search = false.
- Otherwise: target_searchers from `ceil(cavemen.size() * search_pressure)`, at least 1 (and at least 2 when cavemen ≥ 2), clamped to cavemen.size(). **defenders_can_search** = true when cavemen.size() ≤ 3.
- NPCs in **herd_wildnpc** (and related logic) read searcher_quota and defenders_can_search to self-assign.

---

## Enemy / threat evaluation

- **nearby_enemy_claims:** Land claims with different clan_name within **THREAT_DISTANCE_MAX** (2000). Refreshed each evaluation.
- **cached_threats:** Per enemy claim, threat score and last_updated. Refreshed every THREAT_CACHE_INTERVAL (30s) via `_refresh_threat_cache()`.
- **Threat score** (_evaluate_enemy_threat): Distance factor (0.4), enemy strength ratio (0.3), enemy defender ratio (0.2), plus 0.1 if alert ≥ SKIRMISH. Sum clamped 0–1.
- **threat_level:** Sum of cached threat scores, plus alert bonus, clamped 0–1.

---

## Land claim role

The **land claim** is the interface between ClanBrain and NPCs. It stores quotas and pools, reports alerts, and generates jobs.

### Ownership and update

- **Owns ClanBrain** — Initialized in `_initialize_clan_brain()`; land claim holds `clan_brain` (RefCounted).
- **Calls** `clan_brain.update(delta)` every frame in `_process()` (skipped when decaying).

### Alert reporting (land claim → ClanBrain)

NPCs detect intruders/combat locally; land claim escalates to ClanBrain:

| Method | Level | When called |
|--------|-------|-------------|
| `report_intruder()` | INTRUDER (1) | Enemy (caveman/clansman from other clan or player) enters claim; 1 intruder |
| `report_skirmish()` | SKIRMISH (2) | Combat started in claim area |
| `report_raid()` | RAID (3) | 2+ intruders, or building attacked |

Each calls `trigger_alert(level)` (throttled 0.5s per level) → `clan_brain.on_alert(level)`.

**Source:** `npc_base._check_land_claim_intrusion()` — when intruders in claim: `report_raid()` if 2+, else `report_intruder()`.

### Quotas and pools (ClanBrain → land claim meta)

| Meta / property | Set by | Read by |
|-----------------|--------|---------|
| `defender_quota` | ClanBrain `_update_defender_assignments()` | defend_state `can_enter()` |
| `searcher_quota` | ClanBrain `_update_searcher_assignments()` or single-caveman branch | herd_wildnpc_state `can_enter()` |
| `defenders_can_search` | ClanBrain | herd_wildnpc_state (defenders can search when quota full if true) |
| `raid_intent` | ClanBrain `_start_raid()` | raid_state (via clan_brain.get_raid_intent) |
| `economic_priority_weights` | ClanBrain `_update_economic_weights()` | Future FSM/job selection |

### Defender/searcher pools (land claim)

- **assigned_defenders** — Array of NPCs currently defending. NPCs call `add_defender(npc)` / `remove_defender(npc)`.
- **assigned_searchers** — Array of NPCs currently searching. NPCs call `add_searcher(npc)`.
- **should_i_defend(npc)** — Returns false if over quota; NPCs self-evict. Lazy eviction.
- **should_i_search(npc)** — Same for searchers.

### Job generation (land claim → NPCs)

| Method | Job type | Pulled by |
|--------|----------|-----------|
| `generate_gather_job(worker)` | Gather (PickUp from resource, Deposit to claim) | gather_state |
| `generate_craft_job(worker)` | Craft (PickUp stone, KnapTask, Deposit blade) | craft_state |

Land claim also has `reserve_items(worker, items)`, `release_items(worker)` for production jobs (prevents PickUp race).

### Other land claim APIs

- `get_clan_brain()`, `get_threat_level()`, `get_strategic_state()`, `is_raiding()`, `get_clan_strength()`, `get_clan_brain_debug()` — delegate to ClanBrain.
- `start_player_emergency_defend()` — Player clicked DEFEND; calls `clan_brain.start_player_emergency_defend()`.

---

## NPC tasks and decisions

NPCs do **not** receive direct orders. They read quotas and intent from the land claim (and ClanBrain) and self-assign via FSM `can_enter()`.

### FSM state flow (pull-based)

1. FSM evaluates states by **priority** (highest valid `can_enter()` wins).
2. States read **land claim meta** (defender_quota, searcher_quota, raid_intent) or **ClanBrain** (should_npc_raid, get_raid_intent).
3. If under quota, NPC calls `add_defender(npc)` / `add_searcher(npc)` and enters state.
4. On exit, NPC calls `remove_defender(npc)` / `remove_searcher(npc)` (except when transitioning to combat).

### Defend state (priority **3.0** default; **11.0** if trait `protective` or `guardian`)

Default matches cavemen: gather (~4–6), search (5.5), work (7–10), and herd_wildnpc (11.5) all **beat** defend so the clan works first; quota still fills when those states cannot `can_enter`.

| Check | Action |
|-------|--------|
| caveman or clansman | Required |
| `defender_quota` | Read from `claim.get_meta("defender_quota", 0)` |
| `current_count < quota` | Self-assign via `claim.add_defender(npc)`, set `defend_target` |
| In state: `should_i_defend(npc)` | Self-evict if over quota |

**File:** `scripts/npc/states/defend_state.gd`

### Herd (search) state (herd_wildnpc, priority 11.5–12.0)

| Check | Action |
|-------|--------|
| caveman or clansman | Required |
| Same-clan land claim | Required |
| `searcher_quota` | Read from `claim.get_meta("searcher_quota", 1)` |
| `current_count < quota` or (defenders_can_search and is_defender) | Self-assign via `claim.add_searcher(npc)` |
| Inventory not full | Block if &gt;65% full (configurable) |
| Distance from claim | Block if &gt;90% of herd_max_distance |

**File:** `scripts/npc/states/herd_wildnpc_state.gd`

### Raid state (priority 8.5)

| Check | Action |
|-------|--------|
| caveman or clansman | Required |
| Not follow_is_ordered | Required |
| Not defending (defend_target) | Block |
| `clan_brain.is_raiding()` | Required |
| `clan_brain.should_npc_raid(npc)` | True = under raider_quota, not defender |

**File:** `scripts/npc/states/raid_state.gd` — reads raid_intent, rally_point, target_position from clan_brain.

### Economic jobs (TaskRunner, not FSM state selection)

| State | Job source | Pull |
|-------|------------|------|
| gather_state | `land_claim.generate_gather_job(npc)` | `_try_pull_gather_job()` |
| craft_state | `land_claim.generate_craft_job(npc)` | `_try_pull_craft_job()` |
| work_at_building_state | `building.generate_job(npc)` | `_try_pull_job()` from same-clan buildings |

Jobs are **pulled** by NPCs when entering state; no ClanBrain or land claim pushes jobs.

### NPC → land claim (alert reporting)

- **npc_base** `_check_land_claim_intrusion()` — When enemies (other-clan cavemen/clansmen or player) in claim: calls `my_claim.report_intruder()` (1 intruder) or `my_claim.report_raid()` (2+ intruders).

### Priority order (FSM, approximate)

Combat (12.0) &gt; Herd/search (11.5–12.0) &gt; Defend if protective/guardian (11.0) &gt; Raid (8.5) &gt; Reproduction (8.0) &gt; Work at building (7–10) &gt; Search (5.5) &gt; Gather (4–6) &gt; **Defend default (3.0)** &gt; Craft (2–12) &gt; Wander (0.01–12). Following (herd with herder) overrides raid; combat has highest priority.

---

## Integration summary

- **Land claim** owns ClanBrain, stores quotas and pools, reports alerts, generates gather/craft jobs.
- **ClanBrain** sets quotas, raid_intent, economic_priority_weights; never assigns specific NPCs.
- **NPCs** read quotas and intent, self-assign to defend/search/raid; pull jobs from land claim and buildings.

---

## Key constants (in script)

| Constant | Value | Purpose |
|----------|--------|--------|
| MIN_CLANSMEN_FOR_BRAIN | 2 | Full defender/searcher logic only when 2+ cavemen |
| MIN_STONE_FOR_DEFEND | 10 | Min stone in claim to allow defenders (unless alert) |
| MIN_WOOD_FOR_DEFEND | 10 | Min wood in claim to allow defenders (unless alert) |
| MIN_FOOD_FOR_DEFEND | 10 | Min total food (berries+grain+bread) in claim |
| EVALUATION_INTERVAL | 5.0 | Seconds between full state evaluations |
| THREAT_CACHE_INTERVAL | 30.0 | Seconds between threat cache refresh |
| THREAT_DISTANCE_MAX | 2000.0 | Max distance to consider enemy claims |
| BASE_DEFENSE_RATIO / MIN / MAX | 0.2 / 0.1 / 0.6 | defend_pressure bounds |
| ALERT_DECAY_TIME | 10.0 | Seconds before alert level decays one step |
| PLAYER_EMERGENCY_DEFEND_COOLDOWN | 30.0 | Seconds with no intrusion before releasing player-forced defend |
| MIN_RAID_PARTY_SIZE | 2 | Minimum raiders to start/continue raid |
| MAX_RAID_PARTY_SIZE | 8 | Max raiders in party |
| RAID_COOLDOWN | 60.0 | Seconds between raid starts |
| RAID_DISTANCE_MAX | 1500.0 | Max distance to consider raid targets |
| FOOD_PER_DAY_PROXY | 2.0 | Used for food_days_buffer calculation |

---

## Public / debug API (summary)

- **State:** `get_clan_members()`, `get_fighters()`, `get_threat_level()`, `get_strategic_state()`, `get_defend_ratio()`, `get_search_ratio()`, `get_gather_ratio()`, `get_resource_status()`, `get_debug_info()`.
- **Defense:** `get_defender_quota()`, `get_current_defender_count()`, `needs_more_defenders()`, `is_defender_slot_available()`, `force_defend_all()`, `start_player_emergency_defend()`.
- **Raids:** `is_raiding()`, `get_raid_state()`, `get_raid_intent()`, `should_npc_raid(npc)`, `npc_join_raid(npc)`, `npc_leave_raid(npc)`, `get_raid_target_position()`, `get_raid_rally_point()`.
- **Searchers:** `get_searcher_quota()`, `get_current_searcher_count()`, `needs_more_searchers()`, `is_searcher_slot_available()`.
- **Resources:** `is_resource_critical(name)`, `needs_resources()`, `get_gathering_priorities()`, `get_most_needed_resource()`.

---

## References

- **ClanBrain:** `scripts/ai/clan_brain.gd`
- **Land claim (ownership, update, alerts):** `scripts/land_claim.gd`
- **Defend state (pull-based):** `scripts/npc/states/defend_state.gd`
- **Raid state (pull-based):** `scripts/npc/states/raid_state.gd`
- **Combat / agro:** `guides/AgroGuide.md`, `scripts/npc/states/combat_state.gd`
