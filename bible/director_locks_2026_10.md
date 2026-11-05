# Director locks — October 2026 interview

**Status:** Design locks agreed with the director on **2026-10-13**, plus **The Land** on **2026-10-18** (§10), plus the **memory system** on **2026-10-31** (§5), plus **clan feuds** on **2026-11-04** (§11), plus **eight core attributes**, **perks**, and **fight or flight** vocabulary on **2026-11-04** (§4, §12, [fight_or_flight.md](fight_or_flight.md)); core **#7 Toughness** (renamed from Constitution **2026-11-05**). This is design, not code. Each row says what the code does today.
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
| **No blunt size skip.** A camp is not safe just because it has more men, and it is not a target just because it has fewer. **Refined 2026-11-04:** the brain marches only when the odds look good. Opportunity, distance, and whether they can win weigh more than a feud. A rival can tip a close call. A rival cannot send them on a suicide march. The old `outnumbered` skip is still the wrong rule. See §11. | pending. Code still skips any larger camp (`outnumbered`). |
| **How often a clan raids depends on its aggression.** Some clans never raid. See §4. | partial (`raid_temper` is a stub stuck at 0) |
| **No protection for new camps.** A fresh camp can be raided. | built (nothing prevents it) |
| **Flag wiped, player survives:** you keep playing, but **all your clansmen are lost**. It is a solo restart. | pending |
| **First contact:** a **standoff ladder** on first sighting. Freeze, arm up, then back off, hold or charge, decided by bravery, traits and how the player has behaved. It is skipped when there is a grudge, and then it is a straight fight. It works the same for AI and human clans. | pending |
| **Famine ladder** (five visible steps, each with a warning): no pregnancies, then babies weaken, then everyone is slower and fights worse, then men desert as wild exiles who can found clans later, then deaths (babies first, breeders last). | pending |
| **Mammoth:** dangerous big prey that fights back and never hunts people. High reward. Taming is deferred. | partial |
| **Orders vs fear:** an Attack or Guard order gives a courage bonus. It does not remove fear. The weakest can still break and run, shown with the yellow `!!`. | partial. `raid_joined` men currently never lose nerve from the nudge. |

## 4. Character attributes and fight nerve

Full build spec: [future implementations/character_attributes.md](future%20implementations/character_attributes.md). **Eight cores**, four derived stats each. **Not fully coded** — `stats.gd` still uses the old nine-stat shape.

The in-fight **nerve bar** and personal **break line** are `built` ([morale_bar_flight.md](future%20implementations/morale_bar_flight.md)). Wiring them to **core Bravery** is `pending`.

- **Eight cores** at birth (0–100 design scale): Strength, Intelligence, Endurance, Agility, Perception, Social, **Toughness**, **Bravery**. Parent average ± mutation. **Carry capacity** is derived from Strength, not a core. **Pain tolerance** is derived from **Toughness**, not a core. (*Core #7 was named Constitution in the 2026-11-04 lock; renamed Toughness 2026-11-05.*)
- **Bravery (core #8)** is disposition over a life. Derived: aggression threshold, patience, fear resistance, stress tolerance. Kills raise the core slowly; scars, lost kin, and a sticking **times picked on** tally lower it. One shove does not.
- **Fight or flight** ([fight_or_flight.md](fight_or_flight.md)): player **Fight** = **`agro_meter` at max** + attacking + red **`!!!`**. Player **Flight** = morale below flight line + yellow **`!!`**. **`agro_meter`**, AOA, **`agro_state`**, and RTS **Agro mode** stay as **technical agro** names in code.
- Fast attack ↔ flee and the **nerve bar** (0–100) are computed from Bravery + orders. **Not** a ninth core. Show under **Under pressure**, not Born with.
- **Raids are joined by the bold.** Timid men stay home as defenders, hunters or builders.
- **Clan aggression** is the average **Bravery core** of fighters, tilted by the leader. It replaces `raid_temper`.
- Raiders break off when the party nerve breaks (§3, orders vs fear).

Still open: exact derived formulas (measure in play); whether fight state is saved ([story_data.md](story_data.md) §13).

## 5. Stories and saved data

Full spec: [story_data.md](story_data.md). The **2026-10-31** bullets replace the older "any AI person who crossed you gets a full timeline" rule.

- A person keeps traits, skills, genes, buffs and debuffs, lineage, scars, and tallies of kills made defending, kills made on raids, and animals killed on hunts. All of it shows in the character info.
- **Tallies, genes, lineage and scars are kept for everyone** the sim tracks. That is not a diary.
- **Dated timelines, ties, moodles, and dawn lines** are kept for the player's clan and for each human friend's clan on the host. Each of those clans remembers its own people.
- **AI clans get no story.** A crossing stores a rival mark: the clan, and the names of the people who killed or stole. Those names stay after death. Details: [story_data.md](story_data.md) §8.
- **Blood and theft stay open until answered.** One returned death answers the oldest blood. Getting the prize back, or them no longer holding it, answers that theft. The 60-second gap between raids stays. Names remain after the pressure clears. Owner of the pressure rule: [raid.md](raid.md).
- Ancestors in an own clan are kept forever.

## 6. Order of work and multiplayer

| Lock | Code |
|------|------|
| **Order:** story data and lineage records, then the **multiplayer foundation**, then daughters, wounds/medic and the tool chain. | n/a |
| **Multiplayer shape: host-a-world.** One player hosts. A few friends join, each running **their own clan with their own flag** on a shared island with AI clans. It stops when the host quits. | stubs only |
| **Phase promoted now:** story-data logging. Everything else on the roadmap keeps its place. | n/a |
| **Day and night, and exhaustion:** deferred until right after lineage and daughters. | n/a |

This changes [roadmap_2026.md](roadmap_2026.md). Multiplayer was phase 6 and now comes right after story data. See §9.

## 7. Packages still deferred

Predators, trade trips, research, graves and age quality tiers, proto farming, clan menu and tutorial. They stay as ideas in §XXII. **Prisoners** are no longer a blank: the capture rules are locked in [the_land.md](the_land.md) §9 and are still not built.

## 8. Open items

1. **Derived stat formulas.** Eight cores are locked; coefficients for each derived stat are measured in play, not guessed. Fight state vs nerve bar wiring: [character_attributes.md](future%20implementations/character_attributes.md).
2. **Flag wipe and AI clans.** The new rule is for the player. `clan_founding_and_exile.md` still says AI survivors become exiles, and one may found a new clan. Recommended: keep that for AI clans, and decide whether the player's lost clansmen die or scatter as wild exiles.
3. **Tool chain.** The knapping and hafting huts, tar and bows need recipes. Durability is not spent anywhere yet.
4. **Multiplayer details.** What happens to the clans when the host leaves, how many players, whether saves are shared, and whether the foundation waits for the authored island (roadmap Phase 5) or starts on the current map.
5. **Population-day gates.** `production_tiers.md` still lists population and food-day gates. They are retired (claim tier is the only gate), but the numbers there could still be useful for staffing and food tuning.

## 9. Known risks

- **No new-camp protection** plus multiplayer: a friend can hit a 2-person campfire in the first few minutes. Playtest it before changing it.
- **Multiplayer before wounds, daughters and tools:** the network layer must carry story records and hut conversion, so those systems should be built server-first.
- **Odds gate, not a size shield:** a big camp is left alone when attacking it looks like a loss. A big camp that is weak, shamed, or empty of defenders can still be hit. Watch whether raids feel fair.
- **Age re-tune:** changing the speed of ageing touches pregnancy, growth and the age display. Measure every one of them first.

## 10. The Land (2026-10-18)

Full spec: [the_land.md](the_land.md). Zone map: [environment_goal.md](environment_goal.md) §3.7. Not built. Climate stays off until the map can name a zone per cell.

| Lock | Code |
|------|------|
| One spirit, **the Land**, with three faces: the Wet, the Hot Sky, the Cough. Clan names for it are flavor. | pending |
| **Favor** is per clan and biases that clan's **climate zone** (wild crops, animals, one-step softer local hit, slower front if the zone is on one). **Listening** is the island pool. It slows the ice everywhere and can slip an ice age by about a season. It has a ceiling. The ice age still comes. | pending |
| Every offering leaves a tithe in Listening. A hold-the-winter rite puts most of the offering there. | pending |
| Offerings: grain or plants, meat or a trophy, a life or a huge feast. Payback is the next replenish in that zone, not items in the stash, and not permanent new nodes. | pending |
| Spends: soften one step, aim an event at a river or rival (they get an omen), or easier babies with a harder next severity. | pending |
| Nine climate zones move as **fronts**, not random patches. Shader dirt-and-grass noise is not a biome. Forest clumps stay a painted overlay on north savanna. | pending |
| Crowded zones roll worse catastrophes. The famine ladder is still the starvation path. A hard NPC ceiling is only a safety rail, written in the chronicle if it ever fires. | pending |
| Server rolls from world seed, day, zone, Listening, Favor, and how crowded the zone is. | pending |
| **Club** downs on the first hit (no death shadow). A second hit from any weapon kills. A downed person gets back up if they are not roped. | pending |
| **Bound cordage** is the captive. Hotbar 1 and 2 only, max two, never the backpack. Loose cordage stays a normal stack. Adults only. | pending |
| At the claim, captive rope sits in the claim inventory and draws a **brown** line (white = herd, red = party). They eat, and they are not a member. | pending |
| The **shrine** has one sacrifice slot besides relic slots. One body, one rite: climate stability or a war buff, not both. | pending |

## 11. Clan feuds (2026-11-04)

The rival is a clan. This is the nemesis idea without a man who levels up or returns from the dead. Full note: [future implementations/clan_feud.md](future%20implementations/clan_feud.md). Not built.

- Each clan brain stores one feud line per neighbor: kill counts both ways, the last **3** death pairs, and whether blood or theft is still open. Older pairs drop. Counts stay. This is the rival mark. It is not an AI diary.
- The worst open score is the one **stamped rival** on the clan screen. Score means their kills of us minus our kills of them.
- Several open bloods: among neighbors they **can beat**, they march on the worst score. If the stamped rival fails the odds gate, the grudge stays and they do not march on that rival. One returned death still **answers** the oldest blood. [raid.md](raid.md) owns the pressure rule.
- **Odds gate (2026-11-04).** A raid or a blood feud starts only when the brain thinks it can win. The heavy weights are opportunity (a real prize, a weak or shamed camp, defenders already gone), distance (a long march is a worse bet), and winnability (men they can send against the men they expect to meet). A rival adds weight and can tip a close call. It cannot force a bad fight. The player can still order a hopeless attack. The line for “good odds” is measured in play, not guessed. The old score table stays retired.
- An unseen blood raid removes **two named fighters** from the defender’s roster, once. Those two are a seeded roll among fighters only. An unseen food raid still only moves food, once. [dormancy.md](dormancy.md).
- When a blood is answered, the loser shows shame and the winner shows emboldened, on the clan screen. Shame may push clan morale under 30, which already stops a raid. The size of that drop is not chosen. The 60-second gap stays.
- A kill does not change high seats. The killer keeps one fact: the rival clan, and the victim’s name. A newer rival kill replaces it. Player-clan killers also get that fact as a life beat.
- The player clan stores the same lines and does not raid by itself.
- Whether the stamped rival’s men wear the angry face is still open.

## 12. Perks and clan traits (2026-11-04)

Full tables: [traits.md](traits.md). Build with [future implementations/character_attributes.md](future%20implementations/character_attributes.md).

- **15 species perks** + **12 general v1 perks** + **11 general later** perks. Each row names which **core** or **derived** stat it modifies.
- At most **6** perks per person. **Clan trait** when **≥40%** weighted clansmen share a perk (threshold measured in play). Clan applies that bonus **once**, cap **+25%**.
- **Clan cores** = average of clansmen **eight cores** (seats weighted). **Not** a second list of raid personality floats when perks ship.
- Emergent labels (Bold, Timid, …) are UI-only from averages, not perks.
