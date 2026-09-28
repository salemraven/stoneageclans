# Your terms

**Written:** Sep 2026. **Sources:** design docs only (`gdd.md`, `earlygame_vision.md`, `nomad.md`, `game_dictionary.md`, `bible.md`, `clan_founding_and_exile.md`, `party_ui.md`, `AgroGuide.md`, `hominids.md`, `edits.md`). No code was used.

These are the words that name the game: people, land, orders, buildings, food, genetics. When two docs disagree, the newer design doc wins, and the old line is noted.

`game_dictionary.md` still wins over the short table at the top of `bible.md` when those two fight.

---

## People

| Term | Definition | Where the docs disagree |
|------|------------|-------------------------|
| **Caveman** | Any **male** NPC. In settled play he belongs to a clan that has a land claim. | The short table in `bible.md` still says “wild humans.” That line is old. The dictionary and the exile doc replaced it. |
| **Clansman** | A caveman who **belongs to a clan**. The word stresses membership and jobs (work, defend, follow, raid). Women and herd animals are not clansmen. | `gdd.md` still says clansmen are only surplus babies turned into an army. Current meaning is broader: any male in the clan. |
| **Woman** | Female NPC. Not a clansman. She can be **part of the clan** once claimed or assigned. Same genetics layer as fighters. | — |
| **Baby** | Child before promotion. Grows with the mother, then a timer promotes him to a **clansman** (male) today. Not a clansman until then. | Female babies (grow into women) are **planned**, not current. |
| **Baby pool** | A cap on how many babies the clan can hold. Each Living Hut adds room. Extra babies become clansmen. | `bible.md` also says population is driven by the hut itself (one woman + her children), not only an abstract pool. Both ideas are in the docs. |
| **Worker** | A clansman who is **not** on defend duty (gather, build, craft, follow orders). | — |
| **Defender** | A clansman assigned to **guard the claim edge** (flag border or campfire edge). Not “anyone who is fighting.” | **Guard** (below) is a moving party stance. Defender stays on the border. |
| **Searcher** | A clansman the clan sends into the **wilderness** to find herdables. | — |
| **Herder** | Whoever is leading herdables: the **player** or a **clansman**. The animal or woman decides to attach. Cavemen do not “own” them. | — |
| **Herdable** | Someone who can be herded: **women, sheep, goats** (and similar animals). Predators cannot. | — |
| **Wild NPC** | An NPC **without a clan**. Includes herdables and enemies. Enemies cannot be herded. | — |
| **Wild caveman** | A male with **no land claim**: exile after the flag dies, a defector, or a founder waiting for a slot. **Planned.** Not the same as a woman or goat going wild. | Not in the game yet. Today males can keep a dead clan name with no claim. |
| **Predator** | Hostile wild NPC (wolf, and sometimes mammoth). Not herdable. Fights or hunts. | **Mammoth** is also listed as **hunt prey** (meat) in the early-game vision and the Area of Hunt notes. Docs have not picked one role. |
| **Bloodline** | Your lineage for one run. You pick one founder species, then each generation mixes. Wipe is permadeath for that line. | — |
| **Part of the clan** | Women and herd animals **claimed** by the clan. They are clan members for ownership. They are still not clansmen. | — |
| **Claimed** | A herdable tied to a clan. Opposite of wild. | — |

---

## Wild land and exile (planned)

From `clan_founding_and_exile.md`. Not built yet.

| Term | Definition |
|------|------------|
| **Wild** | No clan owns that NPC. |
| **Wilderness** | Land no claim covers. |
| **Exile** | The wild-caveman phase right after home is lost: no claim, no follow, no clan brain home. |
| **Founder candidate** | A wild caveman who passed the clan-slot check and may get a new claim. |
| **Founder** | That male placed with a new land claim. Clan name is his personal name. |
| **Clan slot** | “May the world add one more AI clan?” A budget, separate from the minimum number of clans. |
| **Defector** | A clansman who leaves on purpose (hunger, morale) and becomes a wild caveman. Same founder path later. |

---

## Orders you give

| Term | Definition | Where the docs disagree |
|------|------------|-------------------------|
| **Herd** | Leading **herdables** (women, sheep, goats). They can be stolen, or join the clan when brought inside the claim. Not used for cavemen. | — |
| **Follow** | Order for **clansmen**: stay with you or a leader, in formation, for travel and combat. You break it. It is not stolen like a herd. | Older notes treated Follow as the clansman’s state. Current dictionary: Follow is a **stance**. The squad itself is a **party**. |
| **Party** | Clansmen in ordered follow, with stances Follow / Guard / Attack (agreed next names: **Walk / Hunt / Fight**). | Added when Follow was narrowed to a stance. |
| **Guard** | Moving bodyguard stance: ring around the leader, tighter, more ready to fight. | Not the same as **Defender** on the claim border. |
| **Attack** | Party stance: push to fight. Agreed next label is **Fight**. Raid is Fight while you are away from home, not a fourth mode. | — |
| **Stance** | Follow, Guard, or Attack. Changes how eager they are to fight and how they stand around you. | — |
| **Break** | **B**. Dismiss ordered follow. They walk **home**. | Agreed next, not shipped: also split the party pile into pockets, then drop it at your claim. |
| **War Horn** | **H**. Rally clansmen to you. | **Today** in docs: about 1500 px, and H during a hunt aborts the hunt. **Agreed next:** about 400 px, fighters only, and a searcher who is already herding ignores the horn. |
| **Direct control** | You steer only your own body. Clansmen are AI plus these orders. | — |
| **Primitive command model** | Lore limit: gesture-level orders only (follow, guard, attack, defend the claim, horn, break). No modern tactic menu. | — |

**Agreed next, not shipped** (`party_ui.md`): **Walk**, **Hunt**, **Fight** replace the stance labels. **Party dock** is one window (thin bar, or a bigger sheet on **I**). **Party pile** is shared kit and loot for that band.

---

## Land

| Term | Definition | Where the docs disagree |
|------|------------|-------------------------|
| **Land claim** | The territory: the ground inside the circle, plus the object that anchors it. | — |
| **Campfire** | **Tier 1.** Small movable land claim. Nomad home. Radius **250 px**. Up to **3 Living Huts**. You can **abandon camp** and move without disbanding. | Old snapshot said the campfire has **no** clan brain and **6** storage slots. Sep 2026 nomad doc says it **does** have a clan brain (nomadic mode) and **20** slots. |
| **Flag** | **Tier 2.** Settled land claim. Radius **400 px**. Full production. Destroying an enemy flag wipes that territory (loot first). Herdables go wild. | — |
| **Tier 1 / Tier 2** | Locked names. Tier 1 = campfire. Tier 2 = flag. Same kind of claim, different size and rules. | — |
| **Village** | A land claim grown large: big radius, many huts. The clan brain tracks what the clan needs and assigns work. | — |
| **Nomad Mode** | Moving the **clan** (player abandon-camp, or AI when resources are low). | **Migration** is only for wild animals moving on corridors. Do not use “migration” for clans. |
| **Territory wipe** | Flag destroyed: inventories and buildings gone. Women and animals scatter wild. Babies despawn with the claim. Male survivors as wild cavemen are planned. | — |

---

## World stuff

| Term | Definition |
|------|------------|
| **Resource node** | A map resource that runs out and comes back (berries, stone, tree). |
| **Gatherable** | Something you or an NPC pick up from the map. |
| **Wild wheat** | Wheat that grows **only outside** any claim. Reason to leave home, and a reason to settle so you can farm later. |
| **Relic** | Rare item that does **not** respawn. Put it in a Shrine for a clan-wide buff. Higher flag upgrades may require relics. |
| **Infinite respawn** | Trees, stone, berries, animals come back forever. Relics do not. |
| **Forage** | Berries and (future) roots. Food for the walk. |
| **Meat** | From hunts or butchering the flock. |
| **Grain / bread** | Wild wheat, or a settled field plus an oven on the **flag**. Reason to settle. |

---

## Sensing and fighting

| Term | Definition |
|------|------------|
| **AOP** | **Area of Perception.** How far an NPC can sense others. |
| **AOA** | **Area of Agro.** Inner circle inside AOP. A hostile here raises agro (fight or flight). |
| **Agro** | Tension from 0 to 100. Enter combat at **70**. Leave combat under **60**. Raised by trespass, AOA, damage, herd steal. |
| **Herd steal** | Pulling another clan’s herdable. Same clan cannot steal from itself. Cross-clan can. Blocked while that herder’s clansmen are in ordered follow. |
| **Combat** | Auto fight: wind up, hit, recover. A stagger can cancel the windup. Death leaves a corpse. |
| **Corpse** | Dead body you can loot. |
| **Raid** | Hostile trip: take building and flag goods. Horn plus ordered followers is a war party. |
| **Leader succession** | When a leader dies, the oldest clansman (or a similar rule) continues the AI clan. |

**Raid verbs** (design owner, mostly planned) in `earlygame_vision.md`:

| Term | Definition |
|------|------------|
| **Cordage** | Item you use on an enemy’s **claimed** herdable to bond and lead them out. Without it, a peace walk cannot take claimed herdables. |
| **STEAL / TAKE HERD** | Take their flock with cordage. Not the same as fighting the flock. |
| **LOOT / TAKE GOODS** | Empty building and flag inventories. |
| **KILL / ATTACK MEN** | Fight their clansmen. |
| **WIPE / BURN FLAG** | Destroy the flag after loot rules. |

---

## Clan brain (the idea)

| Term | Definition |
|------|------------|
| **ClanBrain** | The clan’s planner, owned by the territory (flag or campfire). It sets defenders, searchers, raids, and hunts; clansmen pull those orders. **Planned:** it also mirrors the fighting clan — **skills**, **traits**, and **stats** from clansmen (each stat = average; shared traits when enough clansmen have the same trait), a clan **morale bar**, and **buffs/debuffs**. See `ai_clan_brain.md` and `wiki/terms/clan-brain.md`. |
| **Morale bar (ClanBrain)** | *Planned.* Clan-level mood on the brain. Not the per-fighter morale bar. |
| **Defender quota** | How many clansmen the brain wants on the border. |
| **Searcher quota** | How many it wants out looking for herdables. |
| **Supply / demand** | The brain tracks food, resources, and buildings, then assigns work. |
| **Strategic state** | Mood that gates those plans: peaceful, defensive, aggressive, raiding, recovering. |

---

## Buildings you named

| Term | Definition | Where the docs disagree |
|------|------------|-------------------------|
| **Living Hut** | One woman and her children. Pregnancy needs this hut and the woman inside the claim. | `gdd.md` still says the hut has **0** women and only raises the baby pool. `bible.md` says **1** woman and pregnancy. Use the bible line. |
| **Supply Hut** / **Storage Hut** | Extra shared storage. | Two names, one job. |
| **Shrine** | Holds relics. Buffs the whole clan. |
| **Farm** | Wool from sheep, milk from goats. Needs a woman. |
| **Dairy** / **Dairy Farm** | Cheese and butter from milk. Needs a woman. |
| **Oven** | Wood + grain → bread. Timed. | `gdd.md` still says **Bakery**: wheat plus any edible → flavored bread. |
| **Field** | Proto-farm crop ring. **Planned. Flag only.** Campfire does not get it. |
| **Medic Hut** | Planned. Hurt people walk here if berries are stocked. |
| **Grave Mound** | From `edits.md` (idea list): only the player can be buried, age Good or better, one relic slot, raiders can smash it. |

Other GDD buildings still named, not the current short list: **Spinner**, **Armory**, **Tailor**, **Bakery**.

---

## Genetics you named

| Term | Definition | Where the docs disagree |
|------|------------|-------------------------|
| **Species** | One hominid line. Sets the trait pool. | Dictionary / `hominids.md`: Sapiens, Neanderthal, Heidelbergensis, Denisovan, Floresiensis. `earlygame.md` instead lists Erectus and different bonuses. Use the five in `hominids.md`. |
| **Trait** | Inheritable bonus (example: +strength). Up to **6** per NPC. Each trait passes from mother or father about half the time. Only traits that parent’s species can have. |
| **Gene** | Optional dominant/recessive layer on a trait. Finer model in the reproduction notes. |
| **Hybridization** | Child species comes from the parents (about 50/50 which parent). Traits can mix across those pools. |
| **Stats** | Numbers (strength, intelligence, and so on). Often the average of the parents, plus a small change. |
| **Quality tier** | From `edits.md`: age bands for males — Flawed, Common, Good, Fine, Master, Legendary — with stat percent and border color. |
| **Genome** | Old term: a big list of body-shape numbers, child = average of parents plus a mutation. | Current docs say looks are **sprite sheets**, not that morph genome. Do not treat Genome as live. |

---

## How you win

| Term | Definition |
|------|------------|
| **Sandbox / domination** | No win screen. Goal is your bloodline dominating the map, with brutal raids and permadeath. |
