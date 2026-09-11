# Herdable raiding & multi-goal raids (future)

**Status:** Design draft — **not implemented**.  
**Scope:** Extends §XI Raiding, §XV Herding, and `bible/raid.md`. Adds **cordage capture** for **claimed** herdables inside enemy territory and **four raid goals** chosen by ClanBrain (AI) or player intent (RTS).  
**Drafted:** Sep 2026

---

## Why

Today:

- Raids have one behavior: march to the **enemy flag center**, engage defenders, stand on the claim (`raid_state.gd` → MOVING → ENGAGING at `target_position`).
- Herding only attaches to **`is_wild()`** herdables — women, sheep, and goats **already in an enemy claim cannot be stolen** via normal influence (`herd_influence_area.gd`).
- **`raid_loot_focus`** on ClanBrain (0 = burn/kill, 1 = steal resources) is not wired to distinct raid behaviors.

Goal: **cattle-raid fantasy** — rope herdables and lead them out — without turning every raid into a flag smash. Cordage fits the tone better than club violence (“capture,” not beat-until-follow). ClanBrain picks the raid type that **pays the clan most**; players keep manual control of their parties.

---

## Raid goals (one per raid)

Each raid has exactly **one** goal for its lifetime. ClanBrain sets it at `_start_raid(target, goal)`; players express it by **what they do** (equip cordage, loot buildings, fight, smash flag) or an explicit RTS order when that UI exists.

| Goal | Win condition | Pathing | Land claim / flag |
|------|---------------|---------|-------------------|
| **KILL** | Weaken enemy fighters (casualties / time in combat / defenders routed) | Into claim; fight defenders | **Do not destroy flag** unless goal changes to WIPE |
| **LOOT** | Extract resources from **buildings + flag inventory** (drag-and-drop / future auto-loot) | To stockpile buildings near claim | No flag destruction |
| **STEAL** | Bind herdables → lead out → **deliver** into own claim | To **herdables**, **not** flag center | **Hard ban:** no path-to-flag as objective, **no flag damage** |
| **WIPE** | Destroy enemy flag (territory wipe) | Flag after extract, or when target already empty/weak | **Only goal** that may apply flag destruction |

### Invariants (lock before coding)

1. **`goal == STEAL` → never damage or destroy `LandClaim`.**
2. **`goal == STEAL` → `target_position` is a herdable (or edge point near one), not `target.global_position` (flag center).**
3. **`goal == WIPE` → abort / downgrade while any raider has a bound herdable still inside enemy claim radius** (see WIPE rules below).
4. **One goal per raid** — no automatic “STEAL then WIPE” in a single intent; WIPE requires a new evaluation or explicit upgrade with gates.

---

## Cordage capture (STEAL)

### Item

- **Cordage** already exists: craft `fiber × 3` (`craft_registry.gd`, `ResourceData.CORDAGE`).
- Used today for travois / campfire upgrade — **not** yet a raid tool.

### What can be captured

**All herdables:** women, sheep, goats — including those **claimed by the enemy clan** inside their radius.

Wild herdables outside any claim keep using the normal influence path (no cordage).

### Bind rules (agreed)

| Rule | Value |
|------|--------|
| **Cordage consumed** | On **successful delivery** into **own** claim (not on bind attempt) |
| **Max bound per raider** | **2** at a time |
| **Combat during STEAL** | **Defend only** — fight back if attacked; do **not** chase toward flag or buildings as an objective |

**Enemy land-claim context menu (player — planned):**

| Label | `RaidGoal` |
|-------|------------|
| **TAKE HERD** | STEAL |
| **TAKE GOODS** | LOOT |
| **ATTACK MEN** | KILL |
| **BURN FLAG** | WIPE |

Same four goals ClanBrain picks for AI clans.

### Bind flow (proposed)

1. Raider enters enemy claim with **cordage available** in territory inventory (or on person — TBD).
2. **Bind action** on a claimed herdable in range (see open questions).
3. Server sets capture state (see `raid_captured` below).
4. Raider leads bound NPCs toward **own claim edge** (reuse **`herd` FSM** + steering; cap 2 followers).
5. Each herdable **crosses into own claim radius** → normal join-clan path (`clan_name`, hut rules, etc.).
6. On each successful delivery → **consume 1 cordage** from raider/claim stock.

### Capture state (proposed)

Do **not** call full `become_wild()` on bind — that scatters semantics and breaks hut assignment recovery.

Add a server-owned flag, e.g. **`raid_captured`**:

```
raid_captured = {
  "by_clan": "AttackerClan",
  "by_npc": <NodePath or id>,
  "source_clan": "DefenderClan",
  "bind_tick": <sim tick>,
}
```

- Herdable **leaves enemy clan membership** for steal purposes but is **not** wander-wild until delivery fails or raider dies (see failure).
- **`herd_influence_area`**: allow attach to captor while `raid_captured.by_clan == captor clan`.
- **Agro:** binding inside enemy claim triggers **herd steal** agro (same family as bible §XV / AgroGuide — defender alert).

### STEAL pathing & phases

Extend `raid_state.gd` (or parallel sub-phases) when `raid_intent["goal"] == STEAL`:

| Phase | Behavior |
|-------|----------|
| **ASSEMBLING** | Same as today — rally point |
| **MOVING** | Move toward **nearest capturable herdable** (or assigned slot), skirt flag center |
| **BINDING** | In range; channel bind (if channel — TBD); respect 2-cap per raider |
| **EXTRACTING** | Lead bound herdables **out of enemy radius** toward home |
| **RETREATING** | Home when quota met, timer, or losses — **still no flag damage** |

**Do not enter legacy ENGAGING-at-flag** for STEAL unless a defender forces combat (Combat FSM overrides).

### STEAL success metric (ClanBrain)

Raid completes successfully when:

- **`herdables_delivered >= steal_quota`**, or
- **`herd_value_delta`** from deliveries exceeds threshold, or
- Timer / retreat with partial success (log for scoring).

`steal_quota` defaults from brain need (e.g. “need 1 woman” vs “fill pasture”) — tune in `_evaluate_raid_opportunity`.

---

## WIPE rules

WIPE is the **only** goal that may destroy the enemy flag.

### When WIPE is allowed to start

ClanBrain may pick WIPE when:

- Enemy is **already weak** (low fighters, low food buffer), **and/or**
- **No capturable herdables remain** inside their claim, **and/or**
- Prior STEAL quota for this target is **not** needed (aggression override).

### Abort / downgrade (required)

```
if goal == WIPE
   and any(raider has bound herdable inside enemy_claim.radius):
       downgrade goal to STEAL or RETREATING
       cancel flag damage ticks
```

Never start flag damage while extract is in progress inside their territory.

### After wipe

Align with existing bible §V / §XI: inventories gone, buildings cleared, herdables **`become_wild()`**, founder/exile pipeline per `clan_founding_and_exile.md` (planned).

---

## ClanBrain goal selection

At `_evaluate_raid_opportunity()`, for each valid enemy claim compute **expected payoff** per goal; pick **`argmax(payoff)`** and `_start_raid(target, goal)`.

### Payoff signals (sketch)

| Goal | Pays when… | Needs |
|------|------------|--------|
| **KILL** | High `raid_aggression`; rival fighters threaten you; weakens target for later | Combat win, casualties acceptable |
| **LOOT** | Enemy stockpile rich; few defenders; you need mats/food items | Reach buildings, loot phase |
| **STEAL** | Low women / herd_value; enemy has herdables in claim; **cordage in stock** | Cordage ≥ expected deliveries, raiders free |
| **WIPE** | Target weak; no herdables left to steal; strategic erase | Flag damage path, larger party |

Reuse existing signals: `food_days_buffer`, `clan_metrics`, defender counts, distance, `raid_aggression`, `raid_loot_focus` (bias LOOT vs KILL until full scoring exists).

### Gates

| Gate | STEAL-specific |
|------|----------------|
| Cordage | If `cordage_count == 0` → **do not pick STEAL** (gather/craft first) |
| Party size | May use **smaller quota** for STEAL vs WIPE (TBD tuning) |
| Survival mode | Unchanged — `< 2 fighters` → no raid |

### Mid-raid goal changes

- **STEAL:** prefer **retreat** or **downgrade** — do **not** auto-escalate to WIPE while bound NPCs are inside enemy radius.
- **KILL / LOOT:** may retreat on losses via `raid_risk_tolerance` (future).
- **Explicit upgrade** to WIPE only when extract complete and no bound herdables inside enemy claim.

---

## Player parity

- **No ClanBrain auto-raid** on player clans (unchanged).
- Player-led hostile parties use the **same verbs**:
  - Cordage + bind → STEAL behavior (no flag attack).
  - Loot drag from enemy buildings → LOOT.
  - Fight defenders → KILL.
  - Smash flag → WIPE (only when player chooses).
- **War Horn / ordered follow:** Today, Horn → `_set_ordered_follow` **clears herd** on rallied clansmen — breaks STEAL mid-bind.

**Target (earlygame_vision):**

- Horn rallies **workers + defenders** only.
- Searcher with **`herded_count > 0`** or active cordage bond **does not answer Horn**; keeps leading herd.
- **B (Break)** drops herd and sends searchers home.
- STEAL raids: raise searcher quota + cordage; **do not Horn** the bonding party.

---

## Failure & edge cases

| Event | Behavior (proposed) |
|-------|---------------------|
| **Raider dies** with bound herdables | If still inside **enemy** radius → revert herdables to **enemy clan**; if outside enemy radius but not home → **`become_wild()`** |
| **Bind interrupted** | No cordage spent (consumption is on delivery only) |
| **Steal aborted, inside enemy claim** | Bound herdables **snap back** to source clan |
| **Woman in Living Hut** | Bind only when **outside hut / in world** (TBD — see open questions) |
| **Defender sees bind** | Agro + combat; raiders defend only during STEAL |
| **STEAL but no herdables left** | Retreat or ClanBrain re-evaluates LOOT/KILL — **never** default to WIPE |

---

## Multiplayer

- **Bind, unbind, delivery, cordage consume, goal transitions:** **server-authoritative** only.
- Clients send **bind command** / RTS intent; server validates range, cordage stock, cap (2), and claim ownership.
- Leash follow: server sim positions (same as herd today); no client-only steal.

---

## Code touchpoints (when implemented)

| Layer | File / system |
|-------|----------------|
| Goal pick + intent | `scripts/ai/clan_brain.gd` — `_evaluate_raid_opportunity`, `_start_raid`, `_update_raid`, `raid_intent["goal"]` |
| Raid execution | `scripts/npc/states/raid_state.gd` — goal branches; STEAL phases; no flag path |
| Capture verb | New server action `try_bind_herdable(raider, target)` |
| Herdable state | `scripts/npc/npc_base.gd`, `HerdableComponent` / `herd_influence_area.gd` — `raid_captured` |
| Items | `craft_registry.gd`, inventory consume on delivery |
| Flag damage | `scripts/land_claim.gd` — reject damage if attacker raid goal is STEAL |
| Player UI | `main.gd` context menu — “Bind (cordage)” on enemy herdables |
| Telemetry | `playtest_instrumentor.gd` — `raid_goal`, `herdable_bound`, `herdable_delivered`, `wipe_aborted_extract` |

### `raid_intent` schema (extended)

| Field | Type | Description |
|-------|------|-------------|
| `goal` | `RaidGoal` enum | `KILL`, `LOOT`, `STEAL`, `WIPE` |
| `steal_quota` | int | Target deliveries for STEAL |
| `herdables_delivered` | int | Progress |
| `wipe_allowed` | bool | False while extract inside enemy radius |
| *(existing)* | | `state`, `target`, `target_position`, `rally_point`, `raider_quota`, … |

For STEAL, `target_position` = **herdable position** or extract waypoint — **not** flag center.

---

## Order to build

1. **Design lock** — resolve open questions below; add invariants to a headless test or assert in debug builds.
2. **`RaidGoal` enum + `raid_intent["goal"]`** on ClanBrain; log only (no behavior change).
3. **`raid_captured` state + server `try_bind_herdable`** — player-only first, one herdable type (sheep).
4. **Delivery + cordage consume on join own claim** — hook existing clan-join in claim radius.
5. **`raid_state.gd` STEAL phases** — no flag path; cap 2; defend-only combat.
6. **ClanBrain payoff scoring** — pick STEAL vs KILL vs LOOT vs WIPE; cordage gate.
7. **WIPE abort rule** — `_update_raid` downgrade while bound inside enemy radius.
8. **LOOT phase** (if not already) — building/stockpile extraction for LOOT goal.
9. **AI bind action** — NPCs use same server verb as player.
10. **Player RTS order + horn steal context** — explicit STEAL mode on rallied party.
11. **JSONL / `clanbrain_report.py`** — raid goal columns for playtest analysis.

---

## Reliability gates (lock before coding)

| Decision | Status |
|----------|--------|
| STEAL = all herdables | **Agreed** |
| Cordage on delivery only | **Agreed** |
| 2 bound per raider | **Agreed** |
| STEAL = defend-only combat | **Agreed** |
| STEAL = no flag path / no flag damage | **Agreed** |
| WIPE abort during in-radius extract | **Agreed** |
| One goal per raid | **Proposed** |
| Bind UI (menu vs hotbar vs auto) | **Open** |
| Bind channel time / interrupt rules | **Open** |
| Bind range (250px vs melee) | **Open** — suggest 250px to match herd influence |
| Woman inside Living Hut | **Open** — suggest bind only when outside hut |
| Raider death / leash transfer | **Proposed** — see failure table |
| War Horn + STEAL on ordered followers | **Open** |
| STEAL party size vs WIPE party size | **Open** |
| Mid-raid upgrade to WIPE | **Proposed** — only after extract clear |

---

## Open questions (resolve before phase 3+)

1. **Bind action UX:** context menu “Bind with cordage,” hotbar use on target, or auto when in range with cordage equipped?
2. **Bind channel:** instant vs 1–2 s channel that defenders can interrupt?
3. **Leash transfer:** if binding raider retreats, can another party member pick up the leash?
4. **Player goal UI:** explicit four-way raid order vs inferred from equipment/actions only?
5. **Horn rally:** do ordered followers participate in bind+lead, or only player + non-ordered NPCs?

---

## Related docs

- `bible/raid.md` — current pull-based raid (single behavior)
- `bible/HERDING_SYSTEM_GUIDE.md` — wild influence, same-clan steal rules
- `bible/ai_clan_brain.md` — `raid_intent`, evaluation gates
- `bible/rts.md`, `bible/rtsguide.md` — player hostile parties
- `bible/AgroGuide.md` — herd steal agro
- `bible/clan_founding_and_exile.md` — post-wipe wild cavemen (planned)
- `craft_registry.gd` — cordage recipe

---

## Promote-to-bible criteria

When implemented, add **one row** to `bible.md §XXII` and a short **§XI** cross-link (“multi-goal raids + cordage steal — see herdable_raiding.md”).

Ship criteria:

- STEAL raids never damage enemy flag (assert + playtest).
- Claimed herdables can be bound with cordage and delivered home; cordage consumed on delivery.
- ClanBrain selects goal from payoff; WIPE aborts during in-radius extract.
- Server-authoritative bind/delivery in multiplayer path.
