# Player fantasy skeleton — Q&A lock (Oct 2026)

**Status:** Design lock from owner Q&A. Flesh on the big-picture skeleton; not a implementation spec.  
**Supersedes nothing** — extends [earlygame_vision.md](earlygame_vision.md), [nomad.md](nomad.md), [dormancy.md](dormancy.md).  
**Terminology:** Use **land claim inventory** (campfire or flag). **Do not use “pantry.”** (Older docs may still say pantry / `food_days_buffer` — player-facing copy should match [game_dictionary.md](game_dictionary.md) and your terms.)

### Read these before more Q&A (already answered elsewhere)

| Topic | Owner doc | You should not re-ask |
|-------|-----------|------------------------|
| First 10 min, campfire vs flag, forage/meat/bread | [earlygame_vision.md](earlygame_vision.md) §1–2 | Tier 1/2, three foods, **Food: N days** target |
| Wild women, babies, genetics, Living Hut | [earlygame_vision.md](earlygame_vision.md) §3, [reproduction_guide.md](reproduction_guide.md) | Women ≠ clansmen; herd wild vs hut; **baby cap** blocks **starting** pregnancy; **min food buffer** to conceive; cancel in utero on starvation |
| Raid verbs, cordage STEAL, loot before wipe | [earlygame_vision.md](earlygame_vision.md) §4, [herdable_raiding.md](future%20implementations/herdable_raiding.md) | TAKE HERD / GOODS / MEN / BURN |
| War Horn vs searchers/herd | [earlygame_vision.md](earlygame_vision.md) §5, [rts.md](rts.md) | Horn drops herd today; target fix documented |
| Combat outcomes, corpse loot, **player death → succession** | [earlygame_vision.md](earlygame_vision.md) §6 | Baseline: succession on clansman, flag wipe |
| Island / MP / domination panel | [earlygame_vision.md](earlygame_vision.md) §7, [multiplayer.md](multiplayer.md) | Authored island target; overlap claims |
| **Win goal (genetic domination)** | [bible.md](bible.md) § Win, [gdd.md](gdd.md) §1, [genetics.md](genetics.md) | Bloodline dominates map; evolution / species mix; not “sandbox with no point” |
| AI camp when off-screen | [dormancy.md](dormancy.md) | Player claim awake; AI on record tick |
| Camp layout, stations, gatherables brainstorm | [village_and_economy_rundown.md](village_and_economy_rundown.md) | Hearth-centric village, not RPG one-building-one-resource |
| What still needs locking (inventory) | [systems_canon_master.md](systems_canon_master.md) §2–3 | Use ⬜/🟡 rows — not generic “pick A–E” menus |

**This file’s job:** Capture **player-experience choices** from Oct 2026 chat that **refine or extend** the docs above (HUD split, manual eat from land claim inventory, ClanBrain food vs player hunt/raid, sandbox + extinction UX). If a question is already in the table, **read the doc** instead of asking again.

**Tension to resolve later (docs vs Q&A):** [leader_hut.md](leader_hut.md) plans **selectable succession law** (primogeniture vs seniority). Q&A locked **automatic oldest adult clansman** (and promotion fallback) until Leader’s Hut law ships.

---

## North star (all pillars, ordered)

The game intends **survival, war chief, village, dynasty, explorer, and living sim** — not one at the expense of the others.

| Role | What it means here |
|------|---------------------|
| **Spine (0–45 min)** | Survival band — **fed, no stupid deaths** |
| **Layers** | Hunt, settle, raid, huts, succession, island — after spine reads fair |
| **Mid-game** | **Sandbox** — no scripted “chapter 2”; player chooses; world **reacts** |
| **End goal (win)** | **Genetic / bloodline domination** — your lineage wins the hominid competition on the map (owner analogy: like **AMH** as the last hominin standing). Canon: [bible.md](bible.md) § Win, [genetics.md](genetics.md), [gdd.md](gdd.md) §1. Track progress via domination / trait mix ([earlygame_vision.md](earlygame_vision.md) §7–8). **No mandatory win screen** in GDD — domination is the goal while you play. |
| **End (lose)** | **Extinction** — run-ending failure (no successor, etc.) → summary → main menu fresh run (below). Losing is **not** the design endpoint; domination is. |

---

## Spine: survival (first session beat)

### Calories

| Phase | Primary food |
|-------|----------------|
| **Opening** | **Forage** — hands, low risk; map must not feel empty |
| **First escalation (player choice; most do both)** | **Hunt** (meat worth risk) + **settle/grain** (flag, wild wheat, bread stability) |
| **Not the default teach** | Forced nomad move or raid as *first* homework |

### Fairness rule #1

**Never starve from hidden hunger.** Player must see pressure and have time to react. Early deaths should feel like *I waited too long*, not *the game didn’t tell me*.

### HUD & eating

| When | What you see |
|------|----------------|
| **Before any claim** | **Personal hunger only** |
| **After campfire (Tier 1)** | **Personal hunger bar** (always — survival game) + **food days** from **land claim inventory** (**clan/NPCs**, not “you included” in that headline) |
| **Player eating** | Eat from **player inventory** / hotbar; when empty, **manually drag-and-drop** food from **land claim inventory** → player inventory, then eat. **No auto-feed** from claim. |
| **Clan eating** | **Everyone at the claim** — clansmen, women, babies — drains **land claim inventory** on sim (rates tunable). Player manual pulls reduce the same stock. |
| **Clan food from land claim inventory** | When the shared stash is **tight**, **feed most hungry first** (same philosophy as deaths). Not role priority (not “warriors eat first”). **Tie on hunger:** **oldest** among tied people gets priority (feed or die first). Player usually eats from **player inventory** / manual drag; sim feeding from claim uses the same **most-hungry** queue for NPCs (and player only if design hooks claim→person feeding later). |
| **Clan famine deaths** | When stock cannot feed everyone, **who dies first = whoever is most hungry** (highest hunger / lowest calories on that person), **not** fixed role order (not “babies always first”). **Tie on hunger:** **oldest** dies / loses the ration first. Same rule for clansmen, women, babies, and the **player** if their personal hunger is worst — player still must **see** hunger (fairness #1). |
| **Population caps** | **Clansmen:** no hard hut cap — **food / starvation** is the limiter (Q31; overrides draft [food.md](future%20implementations/food.md) “huts = clansmen cap”). **Living Huts:** **baby pool cap** only — see [reproduction_guide.md](reproduction_guide.md) § Baby cap. Leader’s Hut = chief household / future law, not clansmen slots. |
| **Baby cap full (Q32)** | Same as repro guide: **no new pregnancy starts** at cap (`enforce_baby_cap` ON). **In-progress pregnancy still births** when timer finishes (cap does not abort delivery). |
| **Food vs new pregnancy** | **Already in repro guide + code** — do not re-ask: need `reproduction_min_food_buffer_days` to **start**; cancel existing pregnancy below `pregnancy_cancel_food_buffer_days`. |

### First claim

- **Campfire** (Tier 1 land claim) is the **intended first** shared stash: deposit, **food days**, relocate optional later.
- **Flag** (Tier 2): **player chooses** when to settle — **no hard gate**; tutorial explains, does not force.

### Teach moments (suggest only, once)

After **campfire + a few deposits** into **land claim inventory**:

- Suggest **hunt** (meat refills stash faster) — **player calls** hunts; brain does **not** auto-hunt player clan.
- **Same moment:** suggest **settle/grain** fork (flag, wheat, bread) — player may do **both** hunt and settle paths.

### Player clan vs AI clan (food crisis)

| Owner | Behavior |
|-------|----------|
| **Player claim** | **ClanBrain auto-prioritizes gather food** into **land claim inventory**. Player handles **hunt and raid** manually. |
| **AI claims** | **ClanBrain decides** gather, hunt, raid mix (on-screen and on record per [dormancy.md](dormancy.md)). |

---

## Sandbox (after food feels comfortable)

| Lock | Detail |
|------|--------|
| **No chapter 2 push** | No scripted “now raid DLC”; player picks build, raid, explore, breed |
| **Explore** | Leave home ring; discovery over quest track |
| **Death OK** | Combat, hunt, wildlife, overextension while exploring — **expected sometimes** |
| **Still banned** | Death from **hidden hunger** (spine fairness #1) |

### Player death → succession

| Lock | Detail |
|------|--------|
| **On death** | **Succession** — play **another clansman**; **clan + land claim inventory** persist |
| **Succession moment** | **Short beat** — one line (e.g. “Elder Korg falls… Tor takes the chief”), then **control** on the new body (not instant snap, not a full pause panel) |
| **Inventory on succession** | **Land claim inventory** unchanged. Dead chief’s **personal gear stays on the corpse**. Successor plays with **their own** inventory/hotbar — **empty hands** until you **loot the corpse** (no auto-transfer of hotbar/equipment) |
| **Who next** | **Automatic: oldest eligible clansman** |
| **Eligible** | **Adult clansmen only** (not babies/children until grown) |
| **No adult clansman alive** | **Youngest just-promoted adult** — among people who **just aged into** adult clansman status, pick the **youngest** (dynasty continues through the next generation) |
| **No successor at all** | **Game over / clan lost** — e.g. only women and babies, no child eligible to promote to adult clansman; the run ends (claim and roster do not continue under player control). **Overrides** legacy code note that babies “persist until claim destroyed” — extinction + main menu even if women/babies still exist in the world sim. |
| **After clan lost** | **Main menu only** — start a **fresh run** (no same-world respawn, spectator, or inherit rivals) |
| **Clan lost moment** | **Short extinction screen** — **clan name**, **seasons survived**, **cause of extinction**, then **main menu** (richer than a one-liner; not instant skip) |
| **Extinction causes** | **Any run-ending failure** gets the **same screen layout**; **cause** is **one line tuned to the case** (e.g. no successor, starvation wipe, last clansman fell in a raid, beast/disaster when those exist — not a single fixed reason) |

*(Heir designation, sons-only, pick-from-list — future UI; default is automatic adult oldest → promotion fallback → game over → main menu.)*

---

## How this relates to “ship today” gaps

| Gap | Skeleton says |
|-----|----------------|
| Unclear first-hour goal | **Forage → campfire → food days + your hunger → hunt/settle suggest** |
| Pantry/clan food unreadable | **Land claim inventory + food days** for clan; **player bar** always |
| RimWorld half missing | **Sandbox** after food — **babies/huts** player-driven, not chapter 2 script |
| Generational pitch | **Succession** on death is core mid-game fantasy |
| AI neighbors | AI brain full food response; player chief model for violence |
| Dormancy | Player camp **never** uses record sleep for own roster; AI uses [dormancy.md](dormancy.md) |

---

## Conflicts worth one owner answer (not in Q&A yet)

| Topic | Doc / code says | Q&A skeleton says | Notes |
|-------|-----------------|-------------------|--------|
| **Clan wipe, no clansmen** | `health_component.gd`: clan death; comment **babies persist** until claim destroyed | **Game over** when no adult successor (Q22, **A locked**) | **Design wins:** extinction → main menu; code should catch up |
| **Succession law** | [leader_hut.md](leader_hut.md): future primogeniture vs seniority UI | **Automatic oldest adult clansman** (+ youngest promoted) | Until Leader’s Hut law ships |
| **Leader role type** | Code: promotes clansman → **`caveman`** + claim `owner_npc` | Player **plays clansman** body after death | Naming / who is “chief” type |

**Big picture queue:** [big_picture_gaps.md](big_picture_gaps.md) — conflicts + true gaps; settle in order §4 there.

## Open (from canon index — read doc first; ask only if silent or conflicting)

Pull from [systems_canon_master.md](systems_canon_master.md):

- **P11** — born **baby feeding** / starvation ([reproduction_guide.md](reproduction_guide.md) § planned — not shipped)
- **Q28–Q30** — **most-hungry-first** ration + death: **player fantasy lock**; not yet in repro guide or `ClanFoodBuffer` (implementation gap)
- **R2–R3** — raid goal scoring vs “low food = gather not raid” ([earlygame_vision.md](earlygame_vision.md) §2 already targets this; code still partial)
- **P5** — female babies / sex at birth ([female_baby.md](future%20implementations/female_baby.md))
- **U4** — party dock / pile ([party_ui.md](party_ui.md)) — agreed next UI
- **Gather/production math** — pause until [dormancy.md](dormancy.md) settles (owner request Oct 2026)
- Numeric “few deposits,” adult age for succession promotion  

---

## Changelog

| Date | Change |
|------|--------|
| 2026-10-07 | Initial skeleton from owner Q&A (Q1–Q20) |
| 2026-10-07 | Q21: no adult clansmen → youngest just-promoted adult |
| 2026-10-07 | Q22: no one to promote → game over / clan lost |
| 2026-10-07 | Q23: after clan lost → main menu, fresh run |
| 2026-10-07 | Q24: successful succession → one-line beat then control |
| 2026-10-07 | Q25: clan lost → extinction screen (name, seasons, cause) → main menu |
| 2026-10-07 | Q26: extinction cause = one line per run-ending case, same layout |
| 2026-10-07 | Q27: succession — claim stash holds; gear on corpse; loot successor |
| 2026-10-07 | Q28: famine — die in order of **most hunger** (individual, not role) |
| 2026-10-07 | Q29: ration claim food — **most hungry fed first** |
| 2026-10-08 | Q30: hunger tie → **oldest** first (feed + death) |
| 2026-10-08 | Q31: clansmen = food-limited; **Living Hut = baby cap** |
| 2026-10-08 | Q32: at baby cap → block **new** pregnancy (matches repro guide) |
| 2026-10-08 | Conflict: no successor → game over (A), not babies-persist limp |
