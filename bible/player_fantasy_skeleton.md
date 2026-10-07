# Player fantasy skeleton — Q&A lock (Oct 2026)

**Status:** Design lock from owner Q&A. Flesh on the big-picture skeleton; not a implementation spec.  
**Supersedes nothing** — extends [earlygame_vision.md](earlygame_vision.md), [nomad.md](nomad.md), [dormancy.md](dormancy.md).  
**Terminology:** Use **land claim inventory** (campfire or flag). **Do not use “pantry.”** (Older docs may still say pantry / `food_days_buffer` — player-facing copy should match [game_dictionary.md](game_dictionary.md) and your terms.)

### Read these before more Q&A (already answered elsewhere)

| Topic | Owner doc | You should not re-ask |
|-------|-----------|------------------------|
| First 10 min, campfire vs flag, forage/meat/bread | [earlygame_vision.md](earlygame_vision.md) §1–2 | Tier 1/2, three foods, **Food: N days** target |
| Wild women, babies, genetics, Living Hut | [earlygame_vision.md](earlygame_vision.md) §3, [reproduction_guide.md](reproduction_guide.md) | Women ≠ clansmen; herd wild vs hut |
| Raid verbs, cordage STEAL, loot before wipe | [earlygame_vision.md](earlygame_vision.md) §4, [herdable_raiding.md](future%20implementations/herdable_raiding.md) | TAKE HERD / GOODS / MEN / BURN |
| War Horn vs searchers/herd | [earlygame_vision.md](earlygame_vision.md) §5, [rts.md](rts.md) | Horn drops herd today; target fix documented |
| Combat outcomes, corpse loot, **player death → succession** | [earlygame_vision.md](earlygame_vision.md) §6 | Baseline: succession on clansman, flag wipe |
| Island / MP / domination panel | [earlygame_vision.md](earlygame_vision.md) §7, [multiplayer.md](multiplayer.md) | Authored island target; overlap claims |
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
| **No successor at all** | **Game over / clan lost** — e.g. only women and babies, no child eligible to promote to adult clansman; the run ends (claim and roster do not continue under player control) |
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

## Open (from canon index — ask only if docs conflict)

Pull from [systems_canon_master.md](systems_canon_master.md), not from scratch:

- **P10–P11** — housing cap vs food cap; **starvation death order** (who dies first)
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
