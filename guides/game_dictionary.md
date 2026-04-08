# Game dictionary

Canonical vocabulary for **Stone Age Clans**. Use these definitions in UI, design docs, and **new** code comments. When old code uses a different name, add a short note or refactor toward these terms.

**`bible.md`** is a wide lore + implementation index; its terminology table is older in places. Where this file disagrees (e.g. “wild cavemen”), **this dictionary wins** for canon.

---

## People & NPCs

| Term | Definition |
|------|------------|
| **Caveman** | Any **male** NPC in the game. All males are cavemen. Cavemen **always** belong to a clan — they are **never** wild, **never** “unclaimed,” and **never** wander the map without a clan. |
| **Clansman** / **clansmen** | A caveman who **belongs to your (or a) clan**. Same male units; “clansman” stresses **clan membership** and duties (work, defend, follow, raid). **Women and herd animals are not clansmen**, even when they are part of the clan. |
| **Woman** | Female NPC type. Not a clansman; not a wild NPC in the same category as herdables or predators. Can be **part of the clan** if claimed / assigned. |
| **Worker** | A clansman who is **not** currently acting as a **defender** (gathering, building, crafting, following orders, etc.). |
| **Defender** | A clansman assigned to **defend the territory** — standing guard at the **land claim border** (or campfire edge), not the generic “anyone in combat.” |
| **Searcher** | A clansman the **ClanBrain** assigns to **search the wilderness** for herdables (pairs with **searcher quota**; FSM **`herd_wildnpc`** search / lead behaviors). |
| **Baby** | Child NPC before promotion; grows in the mother’s **Living Hut** context, then timer promotes to **clansman** (male). Not a clansman until promoted. |
| **Bloodline** | Player’s lineage run: one founder species at start, **hybridization** each generation. **Permadeath** on wipe — no soft continue of the same bloodline unless design adds it. |

*Legacy docs sometimes call AI male leaders “wild cavemen.” **Canon:** all males are **cavemen**; they always have a **clan** — there are no clanless male wanderers. AI leaders are still clan-affiliated.*

---

## Wild vs clan

| Term | Definition |
|------|------------|
| **Wild** | **Without a clan** — no clan owns or claims that NPC. |
| **Wild NPC** | An NPC that is **wild**. Includes **herdables** (e.g. goats, sheep) and **enemies** (e.g. wolves). **Enemy NPCs cannot be herded.** |
| **Wilderness** | **Land that is not claimed** — no land claim (flag) covers it. |
| **Part of the clan** | Women and herd NPCs **can** be part of the clan when **claimed** by that clan. They are **not** clansmen, but they **are** clan members for ownership / UI / systems. |
| **Claimed** (herd NPC) | A herdable (or similar) tied to a clan. Opposite of **wild**. |

**Raid / clan destroyed:** When a clan is wiped and the **land claim** goes away, **wild** NPCs that belonged to the clan (herd animals, etc.) **return to the wilderness** — they become **wild / unclaimed** again. **Cavemen do not become wild**; they are not in that pipeline.

---

## Follow vs herd

| Term | Definition |
|------|------------|
| **Follow** | Order/movement for **clansmen** (ordered follow, party formations, player-led squads). In RTS UI this is a **stance** (`command_context.mode`), not the FSM state name `party`. |
| **Herd** | Escort / influence for **herdables** (women, sheep, goats, etc.) — **not** clansman party follow. Uses **HerdInfluenceArea**, tethered follow, steal rules. **Enemy wild NPCs are not herdable.** Once a herdable is **claimed** by a clan, it is still **herded** with the same mechanics when moving; “herd” is the verb/system for those NPC types, not for cavemen. |
| **Party** | **Clansmen** under **ordered follow** with stances **Follow / Guard / Attack** — shared formations (`FormationUtils`, `formation_slots` on player or NPC leader). Matches FSM state **`party`**. |
| **Ordered follow** | Clansmen (or player-led selection) locked into party command: `follow_is_ordered` + **`command_context`** (`mode`, commander, agro/chase tuning). **Unbreakable** by normal herd steal on wild herdables; cleared by **Break** or leash. |
| **command_context** | Dictionary on ordered clansmen: `mode` (FOLLOW / GUARD / ATTACK), tuning, `commander_id`, `issued_at_time`. Player path: `main.gd`; NPC leader path: **`PartyCommandUtils`**. |
| **formation_slots** | Leader **meta** (player or male NPC): slot positions / steer targets for each follower. Player: `main._update_formation_slots`; NPC leader: **`FormationUtils.publish_slots_for_npc_leader`**. |
| **follow_is_ordered** | True while clansmen are in ordered party follow (player drag, menu, **War Horn** rally, or **ClanBrain** raid party). Blocks cross-clan **herd steal** on wild herdables. |
| **Break** | RTS control (**B** or HUD): dismiss ordered follow; followers return toward **land claim** / work. Sets **`returning_from_break`** meta so clansmen path home before low-priority jobs steal the FSM. |
| **War Horn** | **H**: rally clansmen in radius (~1500 px per **`RTS_CONFIG`**); applies ordered follow + stance context; herders **detach herd** so they can form up. |
| **Stance** | **Follow**, **Guard**, **Attack** — affects agro threshold, chase distance, and **formation_speed_mult** (player + clansmen). **Guard** while moving = ring around leader; **not** the same as static **defend** on the claim border. |
| **RTS_CONFIG** | `scripts/config/rts_formation_config.gd` — rally radius, horn cooldown, leash, catch-up multiplier, snapshot interval, stance numbers. |

### Herding targets (types)

| Term | Definition |
|------|------------|
| **Herdable** | NPC type that can be **herded**: animals (sheep, goat, …) and **women**. Has **HerdInfluenceArea**. Distinct from **predators** / hostile wildlife, which are **not** herdable. |
| **Herder** | Who leads herdables: **player** or a **clansman** (male). Herdables attach by influence + contest rules; **cavemen don’t “own”** herdables in code — the animal/woman side authorizes attach. |

---

## Territory & structures

| Term | Definition |
|------|------------|
| **Land claim** | The **territory**: the **land inside** the claim **circle / radius** (plus the claim object as anchor). |
| **Campfire** | A **small, movable** clan base — a **mobile land claim** (same role as a claim, smaller radius, nomadic). |
| **Flag** | The **permanent** land claim — settled clan territory (the main **LandClaim**-style base). Destroying an **enemy** flag triggers a **total wipe** (inventories, buildings, clansmen dead, women/herdables scatter as **wild**). |
| **Village** | **Land claim at scale**: large radius, many huts/buildings; **ClanBrain** drives **supply/demand** and (planned) richer task assignment. Campfire supports up to **3 Living Huts** then you need a **flag** claim. |
| **Nomadic base** | Synonym context for **campfire** — smaller radius, fewer slots, **no ClanBrain**, no heavy buildings. |

---

## Resources & map objects

| Term | Definition |
|------|------------|
| **Resource node** | A **world resource** on the map that **depletes** and **replenishes** over time (berries, stone outcrop, tree, etc.). *Note: not the same word as Godot’s `Node` class — in code this is often a scene/script type like `GatherableResource`.* |
| **Gatherable** | Something the player or NPCs **gather** from the map (yield / pickup), as opposed to abstract inventory-only items. |
| **Wild wheat** | Wheat plants that (per design) grow **only outside** any land-claim radius — pushes expansion / nomad phases. |
| **Relic** | Rare **finite** world item (not infinitely respawning like trees/berries). Placed in **Shrine** for **clan-wide buffs**; may gate flag upgrades. |
| **Infinite respawn** | Normal map resources (trees, stone nodes, berries, animals, etc.) **respawn forever**; only **relics** break that rule. |

---

## Perception & agro

| Term | Definition |
|------|------------|
| **AOP** | **Area of Perception** — how far an NPC **senses** others (design); implemented by **`PerceptionArea`**. |
| **AOA** | **Area of Agro** — inner zone inside AOP; hostiles here ramp **agro** (fight-or-flight pressure). |
| **PerceptionArea** | **Area2D** on NPC implementing AOP: tracks bodies, feeds AOA, combat targeting, herd detection, proximity events. |
| **Agro** | 0–100 **tension meter**: enter **combat** at **≥ 70**, exit at **< 60** (hysteresis). Raised by claim intrusion, AOA, damage, **herd steal**, etc. Tuned in **NPCConfig** / combat tick. |
| **Herd steal** | Pulling another clan’s **herdable** via herding contest. **Same-clan** herders can’t steal from each other; **cross-clan** allowed. Blocked while target’s herder has **`follow_is_ordered`**. |
| **EnemiesInClaim** | Land-claim **Area2D** that detects intruders for **defender** logic (event-driven border threat). |

---

## Combat & raid

| Term | Definition |
|------|------------|
| **Combat** | Auto-combat loop: **CombatComponent** windup → hit frame → recovery; **attack arc** / cone checks; **stagger** interrupts windup; death → **corpse** (loot). |
| **Corpse** | Dead body with **lootable** inventory (leather, gear, etc.). |
| **Leader succession** | When a leader dies, design uses **oldest clansman** (or similar rule) for AI continuity. |
| **Raid** | Hostile expedition: loot building + flag inventories; **ClanBrain** **`raid_intent`**; NPCs take **Raid** FSM. Horn + ordered followers = large war party. |
| **Predator** | Hostile **wild NPC** (wolf, mammoth, …) — **not** herdable; hunts / fights. *(Many species planned / partial in code.)* |
| **Fighter activity** | *(Code / telemetry only.)* NPC **right now** in **combat**, **defend**, **agro**, or **raid** FSM — **not** roster headcount. **`GameTerms.is_fighter_activity(npc)`**. Player text: **defender** / **in combat** / **raiding**. |

---

## ClanBrain, jobs & economy loop

| Term | Definition |
|------|------------|
| **ClanBrain** | **RefCounted** AI strategy object owned by a **flag** land claim (not campfire). Sets **defender quota**, **searcher quota**, **raid_intent**, strategic mood, economic weights. NPCs **pull** quotas and self-assign states. |
| **Defender quota** | How many clansmen **ClanBrain** wants on **defend** duty at the claim edge. |
| **Searcher quota** | How many clansmen should **search / herd wild** herdables (wilderness recruitment). |
| **Strategic state** | ClanBrain mood: **PEACEFUL**, **DEFENSIVE**, **AGGRESSIVE**, **RAIDING**, **RECOVERING** (gates budgets and intent). |
| **Supply / demand** | Design frame: brain tracks what the clan needs (food, wood, stone, builds) and assigns work — detailed in village / economy docs. |
| **Economic weights** | `food_weight`, `resource_weight`, `build_weight`, `herd_weight` (on claim meta) — bias which jobs NPCs pick. |
| **Gather job** | **Job** from land claim: **MoveTo** resource → **GatherTask** → **MoveTo** claim → **auto-deposit** near center. Throttled requests; **ResourceIndex** + **reserve/release** workers. |
| **Deposit threshold** | Inventory rule: ~**40%** full (min 3 slots) triggers “go deposit”; keep **one food** stack, send rest to claim. |
| **Occupation** | Building **slot** assignment (woman to **Living Hut**, animal to **Farm**, etc.): `request_slot` / **confirm_arrival** via **OccupationSystem**. |
| **Task** / **Job** | **Task** = one step (move, gather, drop); **Job** = ordered list of tasks run by **TaskRunner** (cancels on defend/combat/ordered follow). |

---

## Buildings (dictionary subset)

| Term | Definition |
|------|------------|
| **Living Hut** | Houses **one woman** + her children; **pregnancy** requires assignment here + woman inside claim radius. Drives population pacing. |
| **Supply Hut** | Extra shared **storage** slots. |
| **Shrine** | Holds **relics** → buffs whole clan. |
| **Dairy Farm** | Production building; needs assigned woman; milk → cheese/butter (design). |
| **Oven** | **Wood + grain → bread** (timed craft). |

---

## Genetics & characters

| Term | Definition |
|------|------------|
| **Species** | One of five hominid lines (Sapiens, Neanderthal, Heidelbergensis, Denisovan, Floresiensis) — defines **trait pool** and flavor. |
| **Trait** | Inheritable bonus (e.g. +% Strength); up to **6** per NPC; passed **~50/50** per slot from mother/father; only traits valid for a parent’s species can roll. |
| **Gene** | Optional **allele** layer (dominant/recessive) for a trait — finer reproduction model in design docs. |
| **Hybridization** | Child **species** from parents (e.g. 50/50 which parent’s species); **traits** can mix across species pools. |
| **Stats** | Numeric attributes (strength, intelligence, …) — often **average of parents ± small mutation** at birth. |
| **Appearance (2D)** | Look = **sprite sheets** / **DirectionalSpriteSheet** / **AssetRegistry** — **not** MakeHuman, morph genomes, or Mixamo. |

---

## FSM (names you’ll see in code)

High-level priority stack (not every state): **Agro** → **Combat** → **Herd wild NPC** (search/lead) → **Party** / **Herd** (tethered herdables) → **Defend** → **Raid** → **Reproduction** → **Work at building** → **Gather** → **Wander**. **`returning_from_break`** boosts wander priority so clansmen **walk home** after **Break**.

---

## Vision & player control

| Term | Definition |
|------|------------|
| **Sandbox / domination** | No mandatory win screen; goal is **generational dominance** with **brutal raiding** and permadeath tone. |
| **Primitive command model** | **Lore:** early humans don’t issue modern tactical vocabulary — only **gesture-level** orders: follow, guard ring, attack push, defend claim, **War Horn** rally, **Break**. **Code:** keep RTS **small** (`command_context`, `RTS_CONFIG`, one formation pass). |
| **Direct control** | Only the **player character** is fully direct-driven; **clansmen** are AI plus RTS orders / quotas. |

---

## Inventory & UI (brief)

| Term | Definition |
|------|------------|
| **Hotbar** | **1–8** equipment (hands, armor, backpack, …); **9–0** **consumables** (eat on key). |
| **Drag-and-drop** | Move stacks between player, **flag** inventory, **buildings**, **NPCs**, **corpse**, ground. **Drop clansman on player** → **ordered follow**. |

---

## Spatial & performance (code names)

| Term | Definition |
|------|------------|
| **ResourceIndex** | Grid (~200px cells) for **resource node** queries near a claim (`query_near`, register/unregister). |
| **HostileEntityIndex** | Fast lookup for hostile NPCs. |
| **ClaimBuildingIndex** | Maps **land claim** → buildings inside it. |
| **HerdInfluenceArea** | **Area2D** on each **herdable**; herder overlap builds influence until attach / contest resolves. |

---

## Implementation notes (code vs design)

Godot still uses two `npc_type` strings for males: **`"caveman"`** and **`"clansman"`**. **Both** count as **clansmen** in the design sense when they share the clan’s `clan_name`. Many systems do `npc_type == "caveman" or npc_type == "clansman"` for quotas, raids, and formations.

| Design term | Typical code today |
|-------------|-------------------|
| Full clan (everyone in clan) | `ClanBrain.clan_members` / `get_clan_members()` |
| Clansmen headcount (males in clan) | `ClanBrain.cavemen` (array name is legacy), `get_fighters()` — **rename toward `get_clansmen()`** when refactoring |
| Defender pool | `LandClaim.assigned_defenders`, `defend_target`, defend FSM |

---

## Changelog

- Replaced ad-hoc **warband** wording with **clansmen** / **caveman** per project canon.
- **Fighter** limited to **fighter activity** (combat posture), not roster counts.
- Pulled **bible.md** terminology (AOP/AOA, RTS, ClanBrain, jobs, genetics, buildings, FSM, relics, etc.) into sections above; **dictionary overrides** old bible lines that called cavemen “wild.”
