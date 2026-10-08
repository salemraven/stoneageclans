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
| ~~C5~~ | **Resolved:** **Win** = genetic / bloodline **domination** (canon below). **Lose** = run-ending extinction → main menu (skeleton). Not the same axis. | | |
| C6 | **Flag destroyed:** [clan_founding_and_exile.md](clan_founding_and_exile.md) — males may become **wild cavemen / founders** | **Q&A extinction:** no successor → **game over** (not play exile) | founding doc vs skeleton — *player vs AI* |

---

## Win vs lose (canon — read before asking)

**Player goal (already in docs + owner intent):** **Genetic domination** — like **anatomically modern humans** being the only hominins left today, you push **your bloodline’s** mix of the five hominid lines until it **owns the map** (other clans wiped, absorbed, or bred out of relevance). This is the **point** of generational play, raids, and hybridization.

| Source | Says |
|--------|------|
| [bible.md](bible.md) § Win | You win when your **bloodline completely dominates the map**. Pure sandbox — **no hard victory screen**; domination is the goal. |
| [gdd.md](gdd.md) §1 | Same: bloodline dominates; no hard victory screen. |
| [main.md](main.md) | Fantasy: bloodline dominates through combat, resources, expansion. |
| [game_dictionary.md](game_dictionary.md) | **Sandbox / domination** — generational dominance, brutal raiding, permadeath. |
| [genetics.md](genetics.md) + [future implementations/genetics.md](future%20implementations/genetics.md) | **Selection**, allele ledger, **species mix / replacement** on map; long-horizon evolution sim — not cosmetic. |
| [earlygame_vision.md](earlygame_vision.md) §7–8, [island_mp.md](future%20implementations/island_mp.md) | **Domination panel** — sons, women, **trait mix**, claims (progress UI toward dominance). |
| [player_fantasy_skeleton.md](player_fantasy_skeleton.md) | **Lose:** extinction (no successor, etc.) → summary → **main menu fresh run**. Does **not** replace domination win goal. |

**Still unsettled (implementation polish, not goal):** exact **domination threshold** (all enemy flags gone? global allele %? only one clan with living clansmen?); whether reaching it shows a **win summary** or only the domination panel (GDD: no mandatory win screen).

---

## 3. True gaps (little or no rule in any owner doc)

| Area | Question shape | Notes |
|------|----------------|-------|
| **Domination threshold** | What measurable condition = “you won genetically / map-wide”? | Canon goal exists; **metric** not locked |
| **Win presentation** | Silent panel only vs optional **win** summary screen | GDD: no hard victory screen |
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

1. **Domination threshold + win UI** — goal is locked (§ Win vs lose); pick **metric** + presentation.  
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
