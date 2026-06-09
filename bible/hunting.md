# Hunting — NPC clans & player RTS

**Last updated:** May 2026  
**Canonical detail:** `bible.md` §XV-A, §XVI, §XVIII

This is the **hub guide** for hunting. Deep dives live in linked docs.

---

## Two hunting paths

| Who | How | Doc |
|-----|-----|-----|
| **AI clans** | **Area of Hunt (AoH)** → ClanBrain **`hunt_intent`** → fighters **`hunt_state`** | [ai_clan_brain.md](ai_clan_brain.md) § Hunting |
| **Player** | RTS HUD **PEACE / AGRO / HUNT** + stances (STALK, ARC, AMBUSH, …) | [Phase4/raiding_hunting.md](Phase4/raiding_hunting.md), [rts.md](rts.md) §11a |

**Not hunt targets via AoH:** sheep, goat, woman — use **herd / searcher** ([HERDING_SYSTEM_GUIDE.md](HERDING_SYSTEM_GUIDE.md), [wildlife_movement.md](wildlife_movement.md)).

---

## Area of Hunt (AoH)

- **Land claims only** — `land_claim.gd` → `AreaOfHunt` (radius &gt; claim footprint).
- Prey **inside the inner claim disk** are excluded (defend/flee/hunt break).
- List: `get_huntables_in_aoh()` — types passing `NPCConfig.is_ai_hunt_prey_type()` (deer, mammoth).
- **Campfires** have no AoH ring.

---

## NPC hunt pipeline

1. **Evaluate** — food pressure (`food_days_buffer`, meat/hide), AoH count, fighters, cooldown, not in survival mode.
2. **Survival mode** — AI fighters **&lt; 2** → no hunt/raid ([ai_clan_brain.md](ai_clan_brain.md)).
3. **`_start_hunt()`** — brain states: `NONE` → `RECRUITING` → `ACTIVE` → `LOOTING` → `RETREATING`.
4. **NPC `hunt_state`** — `FORMING` → `CHASING` → `KILLING` → `LOOTING` → `RETURNING`.
5. **Player-owned territory** — brain does not start hunt parties.

**Edge cases:** `docs/hunting_system_edge_cases.md`  
**Tuning:** `bash tools/run_clanbrain_report_5min.sh` → [clanbrain_report.md](clanbrain_report.md)

### Known gaps (May 2026)

Reports often show: strong pop growth, **low food_days_buffer**, **one hunt per clan per run**, **stuck parties** (formed − disbanded &gt; 0). Active work — not design-final.

---

## Player RTS hunting

### Modes (bottom HUD when clansmen selected)

| Mode | Stances (examples) | Role |
|------|-------------------|------|
| **PEACE** | FOLLOW, GUARD, HIDE | Travel, ring, crouch in cover |
| **AGRO** | ATTACK, GUARD, AMBUSH | Fight; ambush on leader windup |
| **HUNT** | AMBUSH, STALK, ARC | Quiet approach, arc ahead of leader |

Stored in `command_context.mode`. Formations: `FormationUtils` + `rts_formation_config.gd`.

### War Horn vs hunt

- **PEACE / AGRO:** **H** rallies fighters (~1500 px, `RTS_CONFIG`).
- **HUNT:** **H** **aborts** hunt (PEACE + FOLLOW, loud — spooks deer).

### Prey behavior

- **Deer:** `flee_prey_state` — threat centroid, sound — [Phase4/raiding_hunting.md](Phase4/raiding_hunting.md) §5.

---

## Files (quick map)

| File | Role |
|------|------|
| `scripts/ai/clan_brain.gd` | hunt_intent, pressures, `_update_hunt()` |
| `scripts/land_claim.gd` | AoH zone, huntable list |
| `scripts/npc/states/hunt_state.gd` | Party hunt phases |
| `scripts/npc/states/flee_prey_state.gd` | Deer flee |
| `scripts/config/npc_config.gd` | `is_ai_hunt_prey_type`, wild profiles |
| `main.gd` | RTS hunt mode HUD, horn abort |

---

## Related

- [raid.md](raid.md) — raid parties (parallel brain pattern)
- [movement.md](movement.md) — STALK speed mult
- [Ultimate_npc_clanbrain_test.md](Ultimate_npc_clanbrain_test.md) — AoH / hunt gates
