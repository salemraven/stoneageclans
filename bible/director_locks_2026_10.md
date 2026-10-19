# Director locks — October 2026 interview

**Status:** Design locks agreed with the director on **2026-10-13**. This is design, not code. Each row says what the code does today.
**Wins over:** `bible.md`, `raid.md`, `ai_clan_brain.md`, `economy_catalog.md`, `production_tiers.md`, `clan_founding_and_exile.md`, and `leader_hut.md` wherever they disagree with this file. Those docs now point here.
**Does not override:** `systems/*_canon.md` locks that this file does not mention.
**Story record details:** [story_data.md](story_data.md).  
**Evolution & Agro (director interview, Oct 2026):** [natural_selection_and_evolution.md](natural_selection_and_evolution.md).

**Code column:** `built` = in the game today. `pending` = locked, not coded. `partial` = some of it exists.

---

## 1. People, age and heirs

| Lock | Code |
|------|------|
| **Lifespan ≈ 3 hours of play** for one full life (age 13 to about 101, scaled to fit). That is about 2 minutes of play per year. | pending. The age display today runs 1 year = 2 seconds, so ages must be re-tuned. |
| **Heir:** the oldest living **son** by default. If there is no son, the oldest clansman. The Leader's Hut can switch the law later (sons first or seniority). | partial. `player_succession.gd` picks the oldest clansman or caveman only. |
| **Clan size:** about 30–60 people at peak. Every person is an individual with a life record. | pending |
| **Daughters:** women are born as women, and a daughter grows into a clanswoman ([female_baby.md](future%20implementations/female_baby.md)). | pending |

## 2. Huts, daughters and the claim

| Lock | Code |
|------|------|
| **Claim tier is the only gate for hut tier.** Staffing and food decide what actually runs. An empty woman slot drops the operating tier. | pending |
| **Hut women:** T1, T2 and T3 mean 1, 2 and 3 women, each with her own pregnancy timer. | partial |
| **Baby room: +5 per woman in the hut.** A T3 hut holds +15. This replaces "+5 once per hut footprint". | pending (+5 cap exists in code but is off) |
| **Quality:** output quality comes only from input quality. Building tier sets women, recipes and capacity, not quality. | pending |
| **Claim Tier 3** is a primitive upgrade of the flag (totem circle or great fire ring) and needs a relic. Tower, Keep and Castle are retired. | pending |
| **One building per spot.** The player places buildings freely. | partial |
| **A grown daughter gets a hut.** The clan builds a plain Living Hut from the **claim stockpile**. If it can't pay, she **waits in her family's hut** (no pregnancy of her own yet) and the player sees a small nudge. | pending |
| **Auto-specialize:** the new hut is specialized to the industry with the **biggest surplus** in the stockpile, but only if the stockpile can pay for it. | pending |
| **Applies to every clan, the player's too.** The player can **convert any hut to another industry**. This is the same specialization swap we already locked: tier and materials stay, and the craft in progress is cancelled. | pending |
| **AI clan layouts:** each AI clan gets a **layout style** (tight cluster, ring, line along the water, sprawl) from `world_seed + its location`. Spacing rules keep huts from blocking paths. Every player sees the same village, and each clan still looks different. | pending |
| **Medic:** bandages, salves and wound care for the field. Poultices move from the Shaman to the Medic. **Shaman:** potions, body paints and relic rites. | pending |

Already locked before this interview: one building per plot, no batch system, no tool-repair recipe, specialization swap keeps tier and materials, items carry quality and durability (durability not spent yet), buildings are repairable, knapping hut, hafting hut, tar from campfire resin, bows as a T3 weapon (hafter candidate, not locked), resin from trees, and residents pull inputs from the claim.

## 3. Conflict, raids and fear

| Lock | Code |
|------|------|
| **No size rule on raids.** Any clan may raid any neighbor, including a bigger one. Small clans raid big ones for herdables and loot. The `thin` motive still picks smaller camps because it means "they are weak". | pending. `raid.md` and `raid_motive_picker.gd` still skip larger targets (`outnumbered`). |
| **How often a clan raids depends on its aggression.** Some clans never raid. See §4. | partial (`raid_temper` is a stub stuck at 0) |
| **No protection for new camps.** A fresh camp can be raided. | built (nothing prevents it) |
| **Flag wiped, player survives:** you keep playing with **no clansmen under your command** (solo restart). **Presentation:** most men **die defending** the claim; **instant mass despawn at the flag is wrong**. A **rare** breaker may **wander off** then leave the sim; wild/founder only on that path + clan slots. Detail: [natural_selection_and_evolution.md](natural_selection_and_evolution.md) §2.2. | pending |
| **First contact:** a **standoff ladder** on first sighting. Freeze, arm up, then back off, hold or charge, decided by bravery, traits and how the player has behaved. It is skipped when there is a grudge, and then it is a straight fight. It works the same for AI and human clans. | pending |
| **Famine ladder** (five visible steps, each with a warning): no pregnancies, then babies weaken, then everyone is slower and fights worse, then men desert as wild exiles who can found clans later, then deaths (babies first, breeders last). | pending |
| **Mammoth:** dangerous big prey that fights back and never hunts people. High reward. Taming is deferred. | partial |
| **Orders vs fear:** an Attack or Guard order gives a courage bonus. It does not remove fear. The weakest can still break and run, shown with the yellow `!!`. | partial. `raid_joined` men currently never lose nerve from the nudge. |

## 4. Bravery and Agro (fight-or-flight)

The in-fight **morale / flight** bar and personal **break line** are `built` ([morale_bar_flight.md](future%20implementations/morale_bar_flight.md)); UI still shows legacy **Agro** separately — **merge to one person Agro bar** over time. Full lock: [natural_selection_and_evolution.md](natural_selection_and_evolution.md) §2.1.

- Each person has a lasting **bravery** (genes, traits, age; kills up, scars and lost kin down). It sets the **break line** and biases Agro at rest.
- **Agro** = single per-person **fight-or-flight** meter (fast in combat). Retired as design terms: separate person **aggression bar** + **nerve bar**.
- **AI raids:** bold men **volunteer**; timid stay home. **Player raids:** the **player picks** the squad ([raid.md](raid.md)); bravery/Agro affect break, not draft selection.
- **Clan raid appetite** = ClanBrain from fighters' bravery distribution + leader tilt; replaces `raid_temper` stub.
- Raiders break off when party nerve/Agro breaks (§3 orders vs fear).

## 5. Stories and saved data

Full spec: [story_data.md](story_data.md).

- A person keeps traits, skills, genes, buffs and debuffs, lineage, scars, and tallies of kills made defending, kills made on raids, and animals killed on hunts. All of it shows in the character info.
- **Tallies, genes, lineage and scars are kept for everyone.**
- **Dated timelines are kept in full** for people in the player's clan and for any AI person who crossed paths with the player.
- Everyone else keeps tallies and a one-line fate.
- Ancestors are kept forever.

## 6. Order of work and multiplayer

| Lock | Code |
|------|------|
| **Order:** story data and lineage records, then the **multiplayer foundation**, then daughters, wounds/medic and the tool chain. | n/a |
| **Multiplayer shape:** **Persistent dedicated server** (saved world, reconnect, ClanBrain while offline). Each human runs **their own clan + flag** on a shared island with AI clans. **Listen host** = dev/LAN only, same server-authoritative code. Supersedes production “session ends when host quits.” Detail: [natural_selection_and_evolution.md](natural_selection_and_evolution.md) §2.4. | stubs only |
| **Phase promoted now:** story-data logging. Everything else on the roadmap keeps its place. | n/a |
| **Day and night, and exhaustion:** deferred until right after lineage and daughters. | n/a |

This changes [roadmap_2026.md](roadmap_2026.md). Multiplayer was phase 6 and now comes right after story data. See §9.

## 7. Packages still deferred

Predators, trade trips, prisoners, research, graves and age quality tiers, proto farming, clan menu and tutorial. They stay as ideas in §XXII.

## 8. Open items

**Resolved in director interview (Oct 2026)** — see [natural_selection_and_evolution.md](natural_selection_and_evolution.md): Agro single bar, wipe presentation, tool wear deferred, persistent MP, pop gates as hints only.

Still open:

1. **Tool chain recipes** — knapping, hafting, tar, bows (durability spend **deferred**).
2. **MP fine print** — player count target, zero-humans-online sim speed, island vs current map for first net playtest ([roadmap_2026.md](roadmap_2026.md) reorder note).
3. **Founder count per wipe** — recommended one per [clan_founding_and_exile.md](clan_founding_and_exile.md) §4; confirm for player-origin exiles.
4. **Natural selection v1** — implement per [natural_selection_and_evolution.md](natural_selection_and_evolution.md) §5 after lineage phase.
5. **Story UI** — timeline cap, bloodline-end recap, save Agro vs bravery only ([story_data.md](story_data.md) §6).

## 9. Known risks

- **No new-camp protection** plus multiplayer: a friend can hit a 2-person campfire in the first few minutes. Playtest it before changing it.
- **Multiplayer before wounds, daughters and tools:** the network layer must carry story records and hut conversion, so those systems should be built server-first.
- **Biggest camp has no safe size:** with the size rule gone, a growing player is always a target. Watch whether raids feel fair or constant.
- **Age re-tune:** changing the speed of ageing touches pregnancy, growth and the age display. Measure every one of them first.
