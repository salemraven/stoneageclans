# Director locks — October 2026 interview

**Status:** Design locks agreed with the director on **2026-10-13**. This is design, not code. Each row says what the code does today.
**Wins over:** `bible.md`, `raid.md`, `ai_clan_brain.md`, `economy_catalog.md`, `production_tiers.md`, `clan_founding_and_exile.md`, and `leader_hut.md` wherever they disagree with this file. Those docs now point here.
**Does not override:** `systems/*_canon.md` locks that this file does not mention.
**Story record details:** [story_data.md](story_data.md).

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
| **Flag wiped, player survives:** you keep playing, but **all your clansmen are lost**. It is a solo restart. | pending |
| **First contact:** a **standoff ladder** on first sighting. Freeze, arm up, then back off, hold or charge, decided by bravery, traits and how the player has behaved. It is skipped when there is a grudge, and then it is a straight fight. It works the same for AI and human clans. | pending |
| **Famine ladder** (five visible steps, each with a warning): no pregnancies, then babies weaken, then everyone is slower and fights worse, then men desert as wild exiles who can found clans later, then deaths (babies first, breeders last). | pending |
| **Mammoth:** dangerous big prey that fights back and never hunts people. High reward. Taming is deferred. | partial |
| **Orders vs fear:** an Attack or Guard order gives a courage bonus. It does not remove fear. The weakest can still break and run, shown with the yellow `!!`. | partial. `raid_joined` men currently never lose nerve from the nudge. |

## 4. Bravery and the aggression bar

The in-fight **nerve bar** and personal **break line** are `built` ([morale_bar_flight.md](future%20implementations/morale_bar_flight.md)). The rest below is `pending`.

- Each person has a lasting **bravery**. It already sets his break line.
- Bravery comes from genes, traits and age. Over a life, kills raise it, and scars and lost kin lower it.
- Each person also has an individual **aggression bar**, with **attack** at one end and **flee** at the other. Bravery affects this bar.
- **Raids are joined by the bold.** Timid men stay home as defenders, hunters or builders.
- **Clan aggression** is the average bravery and aggression of its fighters, tilted by the leader. It replaces the separate `raid_temper` number.
- A clan full of bold men raids often. A clan of timid men keeps its head down.
- Raiders break off when the party's own nerve breaks (see §3, orders vs fear). A brave or cornered party can still be wiped out.

Still open: how the aggression bar relates to the nerve bar, and the exact things that move each (see §8).

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
| **Multiplayer shape: host-a-world.** One player hosts. A few friends join, each running **their own clan with their own flag** on a shared island with AI clans. It stops when the host quits. | stubs only |
| **Phase promoted now:** story-data logging. Everything else on the roadmap keeps its place. | n/a |
| **Day and night, and exhaustion:** deferred until right after lineage and daughters. | n/a |

This changes [roadmap_2026.md](roadmap_2026.md). Multiplayer was phase 6 and now comes right after story data. See §9.

## 7. Packages still deferred

Predators, trade trips, prisoners, research, graves and age quality tiers, proto farming, clan menu and tutorial. They stay as ideas in §XXII.

## 8. Open items

1. **Bravery vs the aggression bar.** How the two relate, and what raises or lowers each. Recommended: bravery moves slowly over a life, and the aggression bar moves fast in a fight.
2. **Flag wipe and AI clans.** The new rule is for the player. `clan_founding_and_exile.md` still says AI survivors become exiles, and one may found a new clan. Recommended: keep that for AI clans, and decide whether the player's lost clansmen die or scatter as wild exiles.
3. **Tool chain.** The knapping and hafting huts, tar and bows need recipes. Durability is not spent anywhere yet.
4. **Multiplayer details.** What happens to the clans when the host leaves, how many players, whether saves are shared, and whether the foundation waits for the authored island (roadmap Phase 5) or starts on the current map.
5. **Population-day gates.** `production_tiers.md` still lists population and food-day gates. They are retired (claim tier is the only gate), but the numbers there could still be useful for staffing and food tuning.

## 9. Known risks

- **No new-camp protection** plus multiplayer: a friend can hit a 2-person campfire in the first few minutes. Playtest it before changing it.
- **Multiplayer before wounds, daughters and tools:** the network layer must carry story records and hut conversion, so those systems should be built server-first.
- **Biggest camp has no safe size:** with the size rule gone, a growing player is always a target. Watch whether raids feel fair or constant.
- **Age re-tune:** changing the speed of ageing touches pregnancy, growth and the age display. Measure every one of them first.
