# Raid Mechanic — Stone Age Clans

**Status:** NPC raids use motive + goal evaluation (`raid_motive_picker.gd`, `clan_brain.gd`). Score-based start is **removed.**  
**Last Updated:** 2026-11-04  
**Locked, code pending (2026-10-13, refined 2026-11-04):** there is no blunt “more men than us, never raid” rule. A bigger camp can be hit when the odds look good. A march still starts only when the brain thinks it can win (opportunity, distance, winnability). How often a clan raids comes from its fighters' **bravery and aggression** (replaces `raid_temper`). Raiders break off when the party's nerve breaks. Details: [director_locks_2026_10.md](director_locks_2026_10.md) §3, §4, and §11. Where this file still says "not larger", that is today's code, not the rule.  
**Grudge expiry (2026-10-31):** blood and theft no longer expire on a timer. They stay open until answered. The names that outlive the pressure live in [story_data.md](story_data.md) §8. The 60-second gap between raids is unchanged.  
**Feud target (2026-11-04):** if several bloods are open, march on the worst kill score among neighbors they can beat. One death still answers the oldest blood. [director_locks_2026_10.md](director_locks_2026_10.md) §11.  
**Odds gate (2026-11-04):** the brain starts a raid or a blood feud only when it thinks it can win. Opportunity, distance, and winnability weigh more than the feud. A rival can tip a close call. A rival cannot force a suicide march. The blunt “they have more men, never raid” skip stays retired. The old score table stays retired. The cutoff is not a chosen number yet.  
**Related:** `bible/hunting.md`, `bible/trade.md` (neighbor list is the road; trade is not built), [story_data.md](story_data.md)

---

## Overview

Raiding is an **offensive clan action**: fighters leave their territory, march to an enemy claim, work a **goal**, and return home. It uses a **pull-based** model: the ClanBrain sets **raid intent** (motive + goal); NPCs discover it and self-assign via RaidState. No score bar — the first matching **motive** in a fixed list wins.

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

- **ClanBrain** decides *when* to raid (`RaidMotivePicker.pick` after hard stops) and maintains raid intent.
- **RaidState** (NPC FSM) decides *how* to raid moment-to-moment (move, engage, retreat).
- NPCs **pull** raid participation: they read `should_npc_raid(npc)` and `get_raid_intent()` and self-assign.

---

## Motives and goals (current)

One raid has one motive and one goal. The first motive that is fully true wins. The others do not add points, and they do not cancel it. A neighbor merely existing is not a reason to march.

The target comes from `get_neighbor_claims()` (the same list as defense and, later, trade). Equal size may be attacked. **Today's code:** a larger camp is never the target. **Locked:** that blunt skip is retired. A bigger camp can be hit when the odds look good (weak, shamed, or short of defenders). A smaller camp is left alone when the march is long or the fight looks like a loss. See the odds gate below.

### Hard stops

If any of these is true, no motive is considered. Each prints one `RAID_SKIP` and stays quiet until that fact changes.

| Skip | Rule |
|------|------|
| `too_few` | Fewer than 6 living fighters. Corpses are not a warband. That clan hunts. |
| `outnumbered` | Every listed neighbor has more living fighters than we do. **Retired as a blunt rule. Still in code.** Replaced by the odds gate, which can still refuse a bigger camp when the fight looks unwinnable. |
| `alert` | Someone is already fighting us. |
| `hunting` | A hunt is still out. |
| `cooldown` | Less than 60 seconds since the **last raid ended** (not since it started). |
| `no_prize` | Motive needs food, a matching theft prize, or a thin goal the target can supply — and no listed neighbor has it. |
| `trade` | The only camp we could hit is one a trade group is already walking to. Reserved. Trade is not built. |

A clan with one or two fighters never reaches this. Survival mode keeps them on the hunt.

Clan morale under 30 still calls off a raid that has already started.

### Motives, in order

| Order | Why | When it is true | Who they hit |
|-------|-----|-----------------|--------------|
| 1 | `blood` | A named neighbor killed our people, and that neighbor passes the odds gate. The grudge stays open until answered (below) even when the gate says no. It does not expire on a timer. Morale is at least 30. The 60-second cooldown still blocks a new raid from starting. | If several bloods pass the gate, the neighbor with the **worst open score**. If the worst rival fails the gate, skip them. Do not suicide. |
| 2 | `theft` | A named neighbor took a woman or an animal (`stole` wrong recorded **when the prize is taken**, not when she crosses the claim edge). Stays open until answered, even if the odds gate says no today. Morale is at least 30. | That neighbor, if they pass the odds gate and still hold the matching prize (`has_woman` / `has_animal`). Else `no_prize`. Code still also skips a larger camp. |
| 3 | `food` | The pantry is under the hunger line and the warband is intact. The 3-day comfort bar does not apply. Morale is at least 30. | Closest listed neighbor who passes the odds gate **and** `has_food`. Else `no_prize`. Code still also skips a larger camp. |
| 4 | `thin` | We are not hungry. Morale is at least 50. A listed neighbor has half our living fighters or fewer. | That thin camp, for **our** sharpest need (women short of Living Hut slots, else animals short of Farm/Dairy slots, else food) if they can supply it. Else `no_prize`. |
| 5 | `restless` | Pantry has at least 3 days. Morale is at least 70. A long quiet stretch with no fight and no march. | Closest listed neighbor who passes the odds gate. Code still also skips a larger camp. |

Blood and theft remember a clan name, a kind (`killed` or `stole`), and a time. The player-facing names of the deed-doers, kept after this pressure clears, are a rival mark in [story_data.md](story_data.md) §8. Restless reads the last time we fought or marched. Nothing else is a score.

**Answered (2026-10-31).** Several deeds can be open. Names remain after the pressure clears.

- **Blood** clears when your clan kills one of their fighters, or the named killer is already dead. One returned death answers the oldest open blood. Marching uses the worst score, so the clan they march on and the blood a death answers can be two different neighbors.
- Answering a blood shames the loser and emboldens the winner on the clan screen. How big and how long is not chosen. The cooldown below still applies. [future implementations/clan_feud.md](future%20implementations/clan_feud.md).
- **Theft** clears when they no longer hold that woman or animal, or you take a matching prize back.
- The cooldown row above still waits 60 seconds after a raid **ends** before another can start. An open grudge is not a raid every minute.

### Goals

The motive picks the goal. The party does not switch goals at the camp. If the goal is impossible, they go home.

| Motive | Goal | Done when |
|--------|------|-----------|
| `food` | Take food | After the leader has entered the target claim once: store empty, or every living raider **in range** has no bag room (not one bag, not before arrival). |
| `theft` of a woman | Take women | Snapshot **one woman** from the chosen Living Hut (or one loose woman if no hut). Herd only listed prizes via `try_begin_raid_capture` (HerdManager cap, `_start_herd`, `follow_is_ordered`). Done when every listed prize is `joined` or `lost` and at least one `joined`. |
| `theft` of an animal | Take animals | Snapshot **all** sheep/goats in the chosen Farm or Dairy. Same capture/join rules as women. |
| `blood` | Weaken | Two of their fighters are dead, then leave on purpose. No loot. |
| `thin` | The sharpest need | Short of women, else short of animals, else food. Same done rules. |
| `restless` | Weaken | Two fighter kills, then leave. |

Taking women and animals uses the herd walk. Taking food is carry it home and deposit it. Weakening does not stay to finish the camp.

Morale under 30 still ends the raid if the goal is unfinished. They do not pick a new goal because the first one failed.

### Sheltered women and penned animals

A woman in a building is not raidable. Sheep in a Farm and goats in a Dairy are not raidable. The raiders destroy that building. When it falls, the occupants are put on the land claim. Only then can they be herded.

One hit is not enough. A damaged building still holds them. They destroy only the building that holds the prize they came for. An empty hut, Farm, or Dairy is not a target. People and animals already loose on the claim need no building. If the building never falls, they do not pick another building. If the raid breaks before the building falls, the prize stays inside and the goal fails.

Raid leaders with `raid_joined` do **not** enter `herd_wildnpc` when herding a capture (`RAID_LEADER_GUARD`).

### Log contract (playtest + console)

One line per fact (mirrored on `PlaytestInstrumentor` where noted): `RAID_SKIP`, `RAID_WRONG` (`stole` written on the **victim** brain at capture), `RAID_CAPTURE` / `RAID_CAPTURE_FAIL`, `RAID_PRIZE`, `RAID_GOAL_FAIL`, `RAID_FOOD`, `RAID_LEADER_GUARD`, plus existing `RAID_START`, `RAID_GOAL`, `RAID_BUILDING_DOWN`, `RAID_GOAL_DONE`.

### Proof gates

- `tools/raid_motive_verify.gd` → `RAID_MOTIVE_OK` (start rules, prize states, food goal, no direct herd in loose capture path).
- Headless `--raid-decision-proof` with `--ai-combat-observe` → `RAID_DECISION_PROOF_OK` with `RAID_START why=food` or a real `RAID_SKIP` (not `hungry` / score / `eager_raid`; `no_prize` allowed).
- Headless `--raid-capture-proof` with `--ai-combat-observe` → forced theft `take_women`; must log in order: `RAID_START why=theft goal=take_women`, `RAID_GOAL` (Living Hut), `RAID_BUILDING_DOWN`, `RAID_CAPTURE`, `RAID_WRONG kind=stole`, `NPC … joined clan … (entered herder's land claim)`, `RAID_PRIZE state=joined`, `RAID_GOAL_DONE`, then `RAID_CAPTURE_PROOF_OK`. Raid leader must not sit in `herd_wildnpc` during the march.

### Temper (traits later)

**Locked (2026-10-13):** `raid_temper` is replaced by the average **bravery and aggression** of the clan's fighters, tilted by the leader. Bold men volunteer for raids and timid men stay home. See [director_locks_2026_10.md](director_locks_2026_10.md) §4. The table below describes today's stub.

`raid_temper` is one number from -1 peaceful to +1 warlike. It stays 0 until traits write it. Food, blood, and theft ignore it. It does not open `too_few`, `outnumbered`, `alert`, `hunting`, or `cooldown`.

| Temper | Optional marches |
|--------|------------------|
| Peaceful (-1) | No `restless`. No `thin`. |
| Plain (0) | All five motives as written. |
| Warlike (+1) | `restless` after a shorter quiet, and at morale 50 instead of 70. `thin` still means a neighbor who is actually smaller. |

---

## Engine gates (before a motive can fire)

These run in `_evaluate_raid_opportunity()` **before** `RaidMotivePicker.pick`. Failures log `RAID_SKIP` (see **Hard stops** and recruitment skips above).

| Check | Requirement |
|------|-------------|
| Not already raiding | `raid_intent.state == NONE` |
| Not hunting | No active hunt intent |
| Not under attack | `alert_level < SKIRMISH` |
| Cooldown | ≥ 60s since **last raid ended** (`_last_raid_time` set in `_complete_raid` and `_start_raid`) |
| Living fighters | ≥ `RAID_POPULATION_THRESHOLD` (6); else `too_few` |
| Party size | Enough free fighters after `defender_quota` for `MIN_RAID_PARTY_SIZE` |
| Motive | `pick()` returns `ok` with target, `why`, and `goal`; else skip (`no_motive`, `no_prize`, `no_target`, …) |

Target choice is **neighbor list + motive rules + the odds gate**. There is no restored point-score table and no new hard distance cap. Distance is one of the heavy weights inside the gate.

### Odds gate (2026-11-04)

This runs before a motive can start a march, including an unseen raid. The player ordering his own men does not use this gate.

The brain asks three questions, in this order of weight:

1. **Can we win?** Men we can send, after the home guard stays, against the men we expect to meet. A camp with more men can still lose this check if it is shamed, low on morale, or its fighters are already away. A camp with fewer men can still fail it if the trip strips our own defense.
2. **How far?** A longer march is a worse bet. Men are away. The other clan has time. Far alone can make the odds bad.
3. **Is there an opportunity?** A real prize, a weak camp, a shamed camp, defenders already gone. Opportunity makes a winnable fight more attractive. It does not create a fight the first question said no to.

A feud adds weight on that neighbor and can tip a close call. If the first question is no, the feud does not override it. The grudge stays open. They sit, or they hit a different neighbor who does pass the gate.

The cutoff for “good odds” is not a number yet. Measure it in play. Do not bring back the old weighted raid-score table.

### Removed (do not reintroduce without a design pass)

- **Score-based** raid start (weighted food/population/aggression/weak-enemy table, threshold 1.0).
- **`RAID_MIN_FOOD_DAYS_FOR_RAID`** 3-day hard stop — hunger uses the `food` motive and `raid_hunger_days` tuning instead.
- **`RAID_DISTANCE_MAX`** as the primary target filter — motives use `get_neighbor_claims()` only.

Old design notes: `bible/future implementations/clanbrain_raid_scoring.md`.

---

## Raid intent (ClanBrain → NPCs)

Stored on ClanBrain and duplicated to `land_claim.set_meta("raid_intent")`:

| Field | Description |
|------|-------------|
| `state` | `NONE`, `RECRUITING`, `ACTIVE`, `RETREATING` |
| `why` / `goal` | Motive id and goal id from the picker (e.g. `theft` + `take_women`) |
| `target` | Enemy land claim |
| `target_position` / `rally_point` | March and form-up |
| `raider_quota` | Party size cap |
| `building_target` | Living Hut / Farm / Dairy for capture goals; cleared after `RAID_BUILDING_DOWN` |
| `raid_prizes` | Snapshotted prizes with `pending` / `joined` / `lost` |
| `food_arrived` | Food goal: leader entered target claim at least once |
| `building_down_logged` | One `RAID_BUILDING_DOWN` per chosen building |

---

## Raid state machine (ClanBrain._update_raid)

| State | Advance | Cancel / fail |
|-------|---------|----------------|
| **RECRUITING** | Party leaves claim (`raid_form_left`) → **ACTIVE** | Form-up timeout / no leader → cancel |
| **ACTIVE** | Goal complete or goal failed → **RETREATING** (`goal_done`, `goal_failed`, morale call-off) | Too few raiders → cancel; invalid target → complete |
| **RETREATING** | ~30s in retreat phase → `_complete_raid` | — |

While **ACTIVE**, capture goals tick building choice, `RAID_BUILDING_DOWN`, `try_begin_raid_capture`, prize states, and food loot. Retreat does **not** mean “camp wiped”; it means the goal finished or failed.

---

## NPC raid phases (RaidState)

| Phase | Behavior |
|-------|----------|
| **ASSEMBLING** | Rally inside own claim until the party marches out. |
| **MOVING** | Toward enemy claim; enter **ENGAGING** in target radius. |
| **ENGAGING** | Defenders in interrupt radius → fight. For `take_women` / `take_animals`, attack `building_target` when set. Food raiders loot store in range. |
| **RETREATING** | Home; exit raid FSM inside own claim. |

**Priority:** Combat overrides raid. Player **ordered follow** pulls fighters out of raid FSM; raid **captures** use `follow_is_ordered` on the **prize**, not the leader (`RAID_LEADER_GUARD` keeps the leader out of `herd_wildnpc`).

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
| RAID_COOLDOWN | 60.0 | Seconds after **raid ends** before a new march |
| Assembly / retreat | ~30s | Form-up and retreat-phase timeouts (see `_update_raid`) |

Motive thresholds (hunger days, restless quiet, weaken kill count, etc.) live in **`raid_motive_picker.gd`** (`DEFAULT_TUNE`) and `ClanBrain._raid_tune()`.

---

## Per-clan fields (legacy / future)

| Variable | Notes |
|---------|--------|
| `raid_aggression` | Still on ClanBrain; **not** used for motive pick (was score-era). |
| `raid_risk_tolerance` | Reserved; retreat is goal + morale (under 30), not casualty quota. |
| `raid_hunger_threshold`, `raid_population_pressure`, `raid_opportunity_weight` | **Unused** for start; do not document as live raid drivers. |

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

## Future / expansion

Still open:

- **Player-initiated raid:** Context menu "RAID" on an enemy claim for the player clan.
- **Casualty retreat beyond morale:** `raid_risk_tolerance` is unused. Call-off under clan morale 30 is the rule.

---

## References

- **Motive + goals:** `scripts/ai/raid_motive_picker.gd`
- **ClanBrain:** `scripts/ai/clan_brain.gd`
- **RaidState:** `scripts/npc/states/raid_state.gd`
- **Verify (no world):** `tools/raid_motive_verify.gd`
- **AI Clan Brain guide:** `bible/ai_clan_brain.md`
- **RTS / Hostile mode:** `bible/rtsguide.md`
- **Combat / Agro:** `bible/AgroGuide.md`
