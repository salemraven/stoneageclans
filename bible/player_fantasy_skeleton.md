# Player fantasy skeleton — Q&A lock (Oct 2026)

**Status:** Design lock from owner Q&A. Flesh on the big-picture skeleton; not a implementation spec.  
**Supersedes nothing** — extends [earlygame_vision.md](earlygame_vision.md), [nomad.md](nomad.md), [dormancy.md](dormancy.md).  
**Terminology:** Use **land claim inventory** (campfire or flag). **Do not use “pantry.”**

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
| **Who next** | **Automatic: oldest eligible clansman** |
| **Eligible** | **Adult clansmen only** (not babies/children until grown) |
| **No adult clansman alive** | **Youngest just-promoted adult** — among people who **just aged into** adult clansman status, pick the **youngest** (dynasty continues through the next generation) |
| **No successor at all** | **Game over / clan lost** — e.g. only women and babies, no child eligible to promote to adult clansman; the run ends (claim and roster do not continue under player control) |
| **After clan lost** | **Main menu only** — start a **fresh run** (no same-world respawn, spectator, or inherit rivals) |
| **Clan lost moment** | **Short extinction screen** — **clan name**, **seasons survived**, **cause of extinction**, then **main menu** (richer than a one-liner; not instant skip) |

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

## Open (not asked yet)

- Numeric “few deposits,” food-days thresholds, adult age rule  
- MP / domination panel  
- Island/biome as explorer pressure  
- War horn / party UI timing in sandbox  

---

## Changelog

| Date | Change |
|------|--------|
| 2026-10-07 | Initial skeleton from owner Q&A (Q1–Q20) |
| 2026-10-07 | Q21: no adult clansmen → youngest just-promoted adult |
| 2026-10-07 | Q22: no one to promote → game over / clan lost |
| 2026-10-07 | Q23: after clan lost → main menu, fresh run |
| 2026-10-07 | Q24: successful succession → one-line beat then control |
