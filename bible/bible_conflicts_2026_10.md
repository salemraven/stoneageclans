# Bible conflicts — October 2026

**Status:** Working list. Not a design lock.  
**Rule:** Newer dated lock wins. Build plans in Cursor (`.cursor/plans/`) describe what a system pass actually built or was told to build. They beat older bible pages. They do **not** beat [director_locks_2026_10.md](director_locks_2026_10.md) unless we mark the row **ask**.

Sources used: director locks (Oct 13 / Oct 18), player fantasy, dormancy, economy catalog §8.5, raid.md, and these plans:

- Hut specialize overhaul
- Woman hut carry
- Bulletproof hut economy
- One settlement clock
- Living dormant clans
- Next raid + raid gap locks
- Living Island

---

## Newest wins (do not re-ask)

| Topic | Loser | Winner |
|-------|--------|--------|
| Baby room | Economy catalog / production tiers: **+5 once per hut**, upgrades add no cap | Director §2: **+5 per woman**. T3 hut = +15. Code still has +5 and it is off. |
| Craft quality | Production tiers: building tier makes Common / Good / Master | Director §2: quality comes from **materials**. Tier sets women, recipes, capacity. |
| Hut height | Production tiers: food days and population gate T2/T3 | Director §2: **claim tier** is the only gate. Empty woman slots and food decide if it runs. |
| Change craft | Economy catalog and the hut plan: dismantle back to an empty hut | **Locked 2026-10-19: convert only.** Tier and materials stay. Work in progress is cancelled. No return to an empty living hut. |
| Big claims | Village rundown: Flag → Tower → Keep → Castle | Director §2: those names are **retired**. Claim tier 3 is a totem or great fire ring and needs a relic. |
| Word “pantry” | bible.md, ClanBrain notes | Player fantasy: say **land claim inventory**. |
| Raid size | Next-raid plan hard stop “not larger than us” | **Refined 2026-11-04.** The blunt skip is still retired. The brain marches only when the odds look good. A bigger weak camp can be hit. A rival cannot force a bad fight. [director_locks_2026_10.md](director_locks_2026_10.md) §11. Code may still skip larger camps. |
| Far camps | settlement_sim.md status lines | Dormancy + one-settlement-clock + living-dormant-clans: the **record** is the clan. A body is only drawn when someone is close. One 30s clock. Do not sim the same food or birth twice. |
| Island plans | Three older living-map plans | Living Island plan: one recipe. Climate, viewer, then ecology catalog. |
| Raid start | ClanBrain score: hunger adds raid score | **Old.** [raid.md](raid.md) motives decide a start, then the **odds gate** (2026-11-04). Hunger is the `food` motive, not a score bonus. Do not bring back the point-score table. |
| World shape | Older concentric rings (coast → savanna → desert → forest → mountains) | [environment_goal.md](environment_goal.md): **wedge / regional** biomes. [island_map.md](island_map.md) is the map2 checklist. If they disagree, environment_goal wins. |

---

## What the hut plans actually specify

From **Hut specialize overhaul** and **Woman hut carry** (implementation slice, not the full director vision):

- Build menu keeps **Living Hut, Supply Hut, Shrine**. Oven, Farm, Dairy, Drying Rack leave the menu. Already-placed copies of those old types keep working.
- The hut stays type `LIVING_HUT`. Specialty is a field: `none`, `oven`, `weaver`, `rack`, `crop`.
- Place costs 1 wood + 1 stone. Specialize costs the same. The plan’s dismantle-back-to-empty step is **retired** (2026-10-19): convert the craft instead.
- **Tier 2 is out of that pass.** Baby cap stays **off**.
- Recipes in that pass: Oven = grain + wood → bread. Rack = hide → 1 leather sheet + 4 cordage. Weaver = fiber or wool → matching sheet. Crop = grain over time.
- The woman who **lives in that hut** is the only one who carries for it. One slot, stack of 5. She does not craft herself; she waits on the hut timer.
- **People do not eat grain.** Sheep and goats still can.
- Asleep camps do one of those carry moves per hut per tick. The old asleep oven and drying-rack crafts stop.
- Bulletproof hut economy: when a chunk unloads, park the claim **and** its huts together. Craft and carry are server-only. Session memory only until MutationStore save exists.

---

## Locked from the 2026-10-19 answers

| Question | Decision |
|----------|----------|
| Hut slice vs full lock | **More layers.** Oven, Weaver, Rack, and Crop are layer 1. Director rules (more women, T2/T3, more industries, +5 baby room per woman) stay and get added on top. |
| Dismantle vs convert | **Convert only.** Swap the craft. Tier and materials stay. No return to an empty living hut. |
| Player camp sleep | **Stays awake** the whole session. The settlement-clock plan does not put the player camp on the sleeping record. |
| Grain | People do **not** eat raw grain. **Bread** is still human food. Sheep and goats can eat grain. |
| Village “work at the fire only” | Old flavor. Specialty huts are the production path. |

---

## Not in this pass

Phase folders, console logs, and animation guides. If a file is not named above, leave it until a later wave.
