# ClanBrain raid scoring (future)

**Status:** Design draft — **replaces hunger-boosts-raid behavior.**  
**See:** [herdable_raiding.md](herdable_raiding.md) · [earlygame_vision.md](../earlygame_vision.md) §6 · `scripts/ai/clan_brain.gd`  
**Drafted:** September 2026

---

## Problem today

`_evaluate_raid_opportunity()` in `clan_brain.gd`:

- Blocks raids when food is **very low** (good).
- Also **adds raid score when hungry** (bad for design) — pushes **KILL/WIPE** when the clan should **hunt, forage, or STEAL herdables**.

Target: **food_days_buffer** drives **peaceful recovery** vs **raid goal pick**, not “starving → fight everyone.”

---

## Core metric: `food_days_buffer`

```text
food_days_buffer = total_edible_calories_in_claim / daily_calorie_burn
```

| Input | Source |
|-------|--------|
| Edible calories | Claim storage + counted herdables + ready crops (future) |
| Daily burn | Roster size × per-capita hunger rate (sim tick) |

**Tune** `min_days_to_consider_raid` (e.g. 1.5) — below this, **no offensive raid** except defend.

---

## Decision tree (high level)

```text
IF under_attack → DEFEND (existing)
ELIF food_days_buffer < min_days_to_consider_raid → HUNT / SEARCH / FORAGE (no raid intent)
ELIF raid_cooldown → idle economy
ELSE score each goal: KILL, LOOT, STEAL, WIPE → pick max if above threshold
```

**Hungry clans** should spike **HUNT** and **FORAGE**, not WIPE.

---

## Goal scoring (sketch)

Each goal gets `score = base × need × opportunity × risk`. Values are **tunable** in `RaidConfig`.

### Shared factors

| Factor | Meaning |
|--------|---------|
| `need_steal` | High when low women/sheep + nearby enemy herdables |
| `need_food` | High when buffer low but above raid floor — prefer LOOT grain, not WIPE |
| `need_revenge` | Recent raid loss, dead clansmen |
| `opportunity` | Enemy claim weak, far from their defenders, herdables visible |
| `risk` | Distance, enemy army size, our wounded count (future) |

### Per goal

| Goal | When it wins | Hard rules |
|------|----------------|------------|
| **STEAL** | `need_steal × opportunity` high; buffer moderate | Never path to flag; cordage only ([herdable_raiding.md](herdable_raiding.md)) |
| **LOOT** | Low buffer + enemy storage rich | No flag damage |
| **KILL** | Revenge + weak patrol | Clansmen focus, not herd extraction |
| **WIPE** | Revenge extreme + we can hold flag fight | **Only** goal that damages flag; abort if bound herdables still inside enemy radius |

### Penalties

- **Low buffer:** multiply WIPE/KILL scores by **0.2**; multiply STEAL/LOOT by **0.8** if steal target is food-adjacent (sheep).
- **High buffer:** WIPE only if revenge + dominance objective active.

---

## Interaction with hunt / search

| Buffer | ClanBrain priority |
|--------|---------------------|
| `< 0.5 days` | Emergency forage + hunt; **defend only** |
| `0.5 – 1.5 days` | Hunt/search jobs; STEAL if women deficit |
| `> 1.5 days` | Full raid scoring; optional WIPE for meta |

Use existing **`raid_intent`** field but set **`raid_loot_focus`** / new **`raid_goal`** enum: `STEAL | LOOT | KILL | WIPE`.

---

## War Horn interaction

- Horn = **defend rally** — OK.
- Horn must **not** clear cordage binds on STEAL searchers ([earlygame_vision.md](../earlygame_vision.md) §6).
- Scoring: if `raid_goal == STEAL` and units mid-bind, **ignore horn** for those units until delivery or abort.

---

## MP / determinism

- All scores computed **server-side** on sim tick.
- Same inputs → same goal (no frame rand).
- Log: `raid_score STEAL=12 LOOT=4 WIPE=1 → STEAL` for playtests.

---

## Implementation steps

1. Add `food_days_buffer` helper on claim inventory.
2. Remove “hunger adds raid score” branch in `_evaluate_raid_opportunity`.
3. Add `raid_goal` enum + per-goal score functions.
4. Wire task issuance: STEAL → searchers + cordage; LOOT → storage path; etc.
5. Playtest: starving clan should hunt, not wipe neighbor.

---

## Related

- [herdable_raiding.md](herdable_raiding.md)
- [raid.md](../raid.md)
- [off_screen_clan_balance.md](off_screen_clan_balance.md)
