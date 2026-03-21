# Raid Mechanic — Stone Age Clans

**Status:** Implemented (NPC clans). Pull-based, ClanBrain-driven.  
**Last Updated:** 2026-02-25

---

## Overview

Raiding is an **offensive clan action**: fighters leave their land claim, march to an enemy claim, engage defenders, and return home. It uses a **pull-based** model: the ClanBrain sets **raid intent**; NPCs discover it and self-assign via RaidState. No central micromanagement — emergent behavior from stat-driven decisions.

**Who raids:**
- **NPC clans:** Full raid logic (evaluate → recruit → march → engage → retreat).
- **Player clans:** No automatic raids. Player can lead a hostile party (weapon equipped + Follow/Guard) to raid manually.

---

## Architecture

```
ClanBrain (WHEN to raid)          RaidState (HOW to raid)
        │                                    │
        ├─ _evaluate_raid_opportunity()       ├─ ASSEMBLING → rally point
        ├─ _start_raid(target)               ├─ MOVING → target claim
        ├─ raid_intent (state, target,       ├─ ENGAGING → combat
        │   rally_point, raider_quota)       └─ RETREATING → home
        └─ _update_raid() (state machine)
```

- **ClanBrain** decides *when* to raid (score-based evaluation) and maintains raid intent.
- **RaidState** (NPC FSM) decides *how* to raid moment-to-moment (move, engage, retreat).
- NPCs **pull** raid participation: they read `should_npc_raid(npc)` and `get_raid_intent()` and self-assign.

---

## When Raids Start (ClanBrain)

### Gates (must pass all)

| Gate | Requirement |
|------|-------------|
| Not already raiding | `raid_intent.state == NONE` |
| Not under attack | `alert_level < SKIRMISH` |
| Cooldown | ≥ 60s since last raid start |
| Enough fighters | `cavemen.size() >= MIN_RAID_PARTY_SIZE + 1` (need at least 1 defender) |
| Defense satisfied | `available_for_raid = cavemen - defender_quota >= 2` |

### Score-based evaluation (threshold = 1.0)

A single **score** is computed; if **score ≥ 1.0** and a valid target exists, raid starts.

| Signal | Contribution | Notes |
|--------|--------------|-------|
| **Food pressure** | up to 0.4 | If `food_ratio < raid_hunger_threshold` (0.3): `(1 - food_ratio) * 0.4` |
| **Population pressure** | up to 0.3 | `clan_members/10 * raid_population_pressure * 0.3` |
| **Aggression** | up to 0.3 | `raid_aggression` (per-clan, 0–1) |
| **Weak enemy** | 0.4 | If `_find_weak_enemy()` returns a claim (enemy within range, not too strong) |
| **Strategic state** | +0.2 / -0.3 | AGGRESSIVE +0.2, DEFENSIVE -0.3 |

**Target selection:** `_find_weak_enemy()` — enemy claim within `RAID_DISTANCE_MAX`, enemy strength ≤ `available_raiders * 1.5`. Scored by weakness and distance.

---

## Raid Intent (ClanBrain → NPCs)

Stored on ClanBrain and duplicated to `land_claim.set_meta("raid_intent")`:

| Field | Type | Description |
|------|------|--------------|
| `state` | RaidState enum | NONE, RECRUITING, ACTIVE, RETREATING |
| `target` | Node | Enemy land claim |
| `target_position` | Vector2 | Target claim center |
| `rally_point` | Vector2 | Between our claim and target (claim_radius + 50px) |
| `raider_quota` | int | Max raiders wanted |
| `start_time` | float | For timeouts |

---

## Raid State Machine (ClanBrain._update_raid)

| State | Condition to advance | Condition to cancel |
|-------|----------------------|---------------------|
| **RECRUITING** | `raider_count >= 2` → ACTIVE | 30s timeout → cancel |
| **ACTIVE** | `enemy_fighters == 0` → RETREATING | `raider_count < 2` → cancel |
| **RETREATING** | 60s total elapsed → complete | — |
| — | Target invalid/destroyed → complete | — |
| — | Target now friendly → complete | — |

---

## NPC Raid Phases (RaidState)

Each raider runs through local phases driven by ClanBrain raid state:

| Phase | Behavior |
|-------|----------|
| **ASSEMBLING** | Move to rally point, wait for others. Timeout 30s. |
| **MOVING** | Move toward `target_position`. Enter ENGAGING when within target claim radius (~400px). |
| **ENGAGING** | Find nearest enemy (caveman/clansman of target clan) in range; set `combat_target` and `agro_meter = 100`. Combat state (higher priority) takes over. If no enemies, stay at target. |
| **RETREATING** | Move to home land claim. Exit raid when within claim radius. |

**Priority:** RaidState = 8.5. Combat (9.0+) overrides; Defend (8.0) is below. Following (herd) overrides raid — if `follow_is_ordered`, raider exits raid.

---

## Who Can Raid

| Check | Result |
|------|--------|
| caveman or clansman | Required |
| Not `follow_is_ordered` | Block (following takes priority) |
| Not defending | Block (defenders stay home) |
| `clan_brain.is_raiding()` | Required |
| `clan_brain.should_npc_raid(npc)` | Under quota, not in assigned_defenders |

---

## Raid Constants

| Constant | Value | Purpose |
|----------|-------|---------|
| MIN_RAID_PARTY_SIZE | 2 | Min raiders to start/continue |
| MAX_RAID_PARTY_SIZE | 8 | Max raiders in party |
| MIN_DEFENDERS_DURING_RAID | 0.3 | Keep 30% defending (informational) |
| RAID_COOLDOWN | 60.0 | Seconds between raid starts |
| RAID_DISTANCE_MAX | 1500.0 | Max distance to consider targets |
| Assembly timeout | 30.0 | Seconds to wait at rally before exit |
| Total raid timeout | 60.0 | Seconds in RETREATING before complete |

---

## Per-Clan Raid Tuning (ClanBrain)

| Variable | Default | Description |
|---------|---------|-------------|
| raid_aggression | 0.5 | 0–1, how willing to raid when stable |
| raid_risk_tolerance | 0.3 | Casualties tolerated before retreat (future) |
| raid_hunger_threshold | 0.3 | Food ratio below this increases raid desire |
| raid_population_pressure | 0.7 | Weight for population in score |
| raid_opportunity_weight | 0.4 | Weight for weak-enemy opportunity |

---

## Alert Interaction

- **Raid evaluation blocked** when `alert_level >= SKIRMISH` (we're under attack).
- **Raid cancelled** when alert escalates (e.g. RAID → force_defend_all).
- **Strategic state:** RAIDING → RECOVERING after raid completes. Don't leave RECOVERING for 30s.

---

## Player Raiding

Player clans do **not** use ClanBrain raid evaluation. Player raiding is manual:

1. Equip weapon (axe, pick, club) → followers become hostile.
2. Set Follow or Guard mode.
3. Move toward enemy claim.
4. Intrusion triggers; defenders respond; combat.

See `rtsguide.md` §6 Hostile Mode (Raid).

---

## NPC Raid API (for RaidState / other systems)

| Method | Returns | Description |
|--------|---------|-------------|
| `is_raiding()` | bool | Raid in progress |
| `get_raid_state()` | int | NONE/RECRUITING/ACTIVE/RETREATING |
| `get_raid_intent()` | Dictionary | Full intent |
| `get_raid_target_position()` | Vector2 | Target claim center |
| `get_raid_rally_point()` | Vector2 | Rally point |
| `should_npc_raid(npc)` | bool | NPC eligible to join |
| `npc_join_raid(npc)` | — | Set meta "raid_joined" |
| `npc_leave_raid(npc)` | — | Remove meta |

---

## Future / Expansion Ideas

- **Looting:** Raiders pick up resources from enemy claim/buildings (Phase3 mentioned LOOTING phase).
- **Casualty-based retreat:** Use `raid_risk_tolerance` — retreat if losses exceed threshold.
- **Raid types:** Quick skirmish vs full sack (different quotas, durations).
- **Morale / fear:** Defenders or raiders break based on casualties.
- **Traits / culture:** "Aggressive tribe" = higher `raid_aggression`; "Desperate" = lower food threshold.
- **Player-initiated raid:** Context menu "RAID" on enemy claim to set raid intent for player clan.

---

## References

- **ClanBrain:** `scripts/ai/clan_brain.gd`
- **RaidState:** `scripts/npc/states/raid_state.gd`
- **AI Clan Brain guide:** `guides/ai_clan_brain.md`
- **RTS / Hostile mode:** `guides/rtsguide.md`
- **Combat / Agro:** `guides/AgroGuide.md`
