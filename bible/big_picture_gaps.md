# Big picture — what is not settled in canon docs

**Status:** Working list (Oct 2026). Use this before Q&A so we only ask **gaps** or **conflicts**, not topics already owned elsewhere.

**Read first:** [earlygame_vision.md](earlygame_vision.md), [dormancy.md](dormancy.md), [reproduction_guide.md](reproduction_guide.md), [game_dictionary.md](game_dictionary.md), [systems_canon_master.md](systems_canon_master.md).

**Player-experience locks (Oct Q&A):** [player_fantasy_skeleton.md](player_fantasy_skeleton.md) — many rows are **not** copied into other guides yet.

---

## 1. Locked in Q&A but not in owner docs (promote when ready)

| Topic | Lock (short) | Target home |
|-------|----------------|-------------|
| HUD / eating | Personal hunger always; **food days** = land claim inventory; manual drag to eat; no auto-feed from claim | `UI.md` / population canon |
| Food crisis split | **Player claim:** brain gathers; **player** hunts/raids. **AI claim:** brain does all | `ai_clan_brain.md` + skeleton |
| Teach beats | After campfire + few deposits → suggest hunt **and** settle (no force) | `earlygame_vision.md` or tutorial canon |
| Sandbox tone | No chapter-2 push; explore; combat death OK; **not** hidden hunger death | skeleton → `gdd.md` align |
| Succession chain | Oldest adult clansman → youngest just-promoted → else **game over** | `leader_hut.md` / combat canon |
| Succession UX | One-line beat; gear on corpse; successor empty until loot | combat / UI canon |
| Extinction UX | Summary screen (name, seasons, cause) → **main menu fresh run** | meta / UI canon |
| No successor | Game over even if women/babies remain (**overrides** code “babies persist”) | combat + reproduction cross-ref |
| Famine fairness | Feed + die: **most hungry first**; tie → **oldest** | `population_canon` / `ClanFoodBuffer` (not in repro guide) |
| Population | Clansmen limited by **food**; **Living Hut = baby cap** only (not clansmen slots) | overrides draft [food.md](future%20implementations/food.md) |

---

## 2. Conflicts (docs or code disagree — need one owner pick)

| # | A | B | Where |
|---|--|--|--------|
| C1 | **GDD §6:** surplus babies beyond cap → **permanent clansmen** | **Repro guide + Q32:** cap blocks **new pregnancy**; delivery of in-progress OK | [gdd.md](gdd.md) vs [reproduction_guide.md](reproduction_guide.md) |
| C2 | **Leader’s Hut:** future **primogeniture vs seniority** UI | **Q&A:** automatic **oldest adult clansman** until law ships | [leader_hut.md](leader_hut.md) vs skeleton |
| C3 | **Code succession:** promote clansman → **`caveman`** + `owner_npc` | **Q&A:** player plays **clansman** body; story “chief” | `health_component.gd` vs skeleton |
| C4 | **Dictionary / code:** **oldest clansman** (no “adult only” filter) | **Q&A:** **adult clansmen only**; youngest **just-promoted** fallback | [game_dictionary.md](game_dictionary.md) vs skeleton |
| C5 | **Bible §I:** win = **bloodline dominates map**; **no victory screen** | **Q23:** extinction → **main menu fresh run** (session ends) | [bible.md](bible.md) vs skeleton — *what is a “run”?* |
| C6 | **Flag destroyed:** [clan_founding_and_exile.md](clan_founding_and_exile.md) — males may become **wild cavemen / founders** | **Q&A extinction:** no successor → **game over** (not play exile) | founding doc vs skeleton — *player vs AI* |

---

## 3. True gaps (little or no rule in any owner doc)

| Area | Question shape | Notes |
|------|----------------|-------|
| **Run / win** | Is there ever a **win screen**, or only domination as unmarked goal until extinction? | GDD says no hard victory; island MP mentions domination panel |
| **Fresh run** | New **world seed** every time, or same world template? | Q23 said main menu only — not specified |
| **Player identity** | Succession = same **“you”** (dynasty soul) or new person with no meta carryover? | Affects UI copy, not just npc_type |
| **Adult age** | Age threshold for **adult clansman** (succession + promotion fallback) | Code uses `age`; no design number |
| **“Few deposits”** | Teach moment after N deposits to land claim inventory | Skeleton only |
| **Total wipe by famine** | Run ends when **last person** dies vs **last clansman** vs **food days = 0** for X ticks | Extinction causes list vs sim |
| **Flag lost while heir alive** | Player at flag wipe: succession continue elsewhere, exile fantasy, or instant loss? | founding doc is AI-focused |
| **Born baby feeding** | Genetics metabolism + claim food for **spawned** babies | [reproduction_guide.md](reproduction_guide.md) § planned |
| **Female babies** | Sex at birth, daughters | [female_baby.md](future%20implementations/female_baby.md) |
| **Raid scoring** | Low food → gather not raid | [earlygame_vision.md](earlygame_vision.md) §2 target; code partial |
| **Party / pile UI** | Next agreed UI | [party_ui.md](party_ui.md) |
| **Gather/production math** | Pause until dormancy settles | Owner Oct 2026 |

---

## 4. Suggested settlement order (big picture)

1. **Session model** — run length, win vs extinction, fresh run meaning (**§3 run/win** + **C5**).  
2. **Player identity** — chief slot vs any clansman body (**C3**, **§3 identity**).  
3. **Promote skeleton food + succession** into `systems/population_canon.md` (when written).  
4. **Resolve C1** (GDD baby surplus vs repro cap) — one line in GDD stamp.  
5. **Player flag wipe** vs exile founder (**C6** for **player** only).  
6. P0 systems from [systems_canon_master.md](systems_canon_master.md) that stay ⬜ after 1–5.

---

## Changelog

| Date | Change |
|------|--------|
| 2026-10-08 | Initial gap inventory from doc audit + player_fantasy_skeleton |
