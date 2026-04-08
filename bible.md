# Stone Age Clans — Lore Bible

**Single source of truth for lore, design, mechanics, code, and systems.**  
Compiled from guides, GDD, and implementation docs. Covers both design intent and actual scripts/logic. Last consolidated: April 2026.

---

## Terminology

**Canonical definitions:** `guides/game_dictionary.md` (updated for player-facing and design vocabulary). The table below is a quick index + implementation aliases; if anything conflicts, the dictionary wins.

Definitions of project-specific terms used throughout design and code.

| Term | Meaning |
|------|---------|
| **AOP** | Area of Perception. Design term. Universal radius — what each NPC can sense. Implemented by PerceptionArea. |
| **AOA** | Area of Agro. Inner zone within AOP. When hostile enters AOA, agro increases (fight-or-flight). |
| **PerceptionArea** | Component (Area2D) that implements AOP. Tracks entities in range. Feeds AOA, combat, agro. |
| **Herd** | Wild herdables only (women, sheep, goats). FSM state **`herd`**: tethered follow; influence/steal; join clan when delivered. |
| **Party** | Fighters (cavemen, clansmen) in **ordered follow** with stances Follow/Guard/Attack. FSM state **`party`**: same formations as player-led squads (`FormationUtils` + `formation_slots` on player or NPC leader). |
| **Follow** | Stance/mode within a party (`command_context.mode`), not the FSM state name. |
| **Herdable** | NPC that can be herded: animals, women. Has HerdInfluenceArea. |
| **Herder** | NPC leading herdables: player or caveman. |
| **Agro** | Aggro meter 0–100. Enter combat at 70, exit at 60. Triggers: intrusion, AOA, damage, herd steal. |
| **ClanBrain** | AI strategy RefCounted on land claim. Defender/searcher quotas, raid intent. |
| **Defender quota** | ClanBrain-assigned number of NPCs to patrol claim border. |
| **Searcher quota** | ClanBrain-assigned number of NPCs to search for herdables (Herd Wild NPC state). |
| **follow_is_ordered** | Ordered follow (player drag/menu, horn rally, or **ClanBrain raid party**); unbreakable for fighters; prevents herd steal on wild herdables. |
| **command_context** | Dictionary on ordered fighters: `mode` (FOLLOW/GUARD/ATTACK), agro/chase tuning, `commander_id`, `issued_at_time`. Player path: `main.gd`; NPC leader path: **`PartyCommandUtils`**. |
| **formation_slots** | Leader `meta` (player or NPC caveman/clansman): shared slot positions / steer targets (`main._update_formation_slots` for player; `FormationUtils.publish_slots_for_npc_leader` for NPC-led parties). |
| **RTS_CONFIG** | `scripts/config/rts_formation_config.gd` — rally radius, horn cooldown, leash, catch-up multiplier, snapshot interval, etc. |
| **Cavemen** | Wild humans; can place claims, become clan leaders; AI clans. |
| **Clansmen** | Surplus babies promoted to permanent AI army; belong to a clan. |
| **Village** | Land claim at scale: large radius, many huts; ClanBrain drives supply/demand and task assignment. |
| **Supply/demand** | ClanBrain tracks what the clan needs (food, resources, buildings) and assigns work; see village.md. |
| **Trait** | Inheritable bonus tied to hominid species (e.g. +20% Strength). Passed to offspring 50/50 per trait from mother/father. Max 6 per NPC. |
| **Gene** | Optional allele (dominant/recessive) for a trait; used in the anthropological model in reproductiontraits.md. |
| **Appearance (2D)** | NPC look = **sprite sheets / textures** (`AssetRegistry`, `DirectionalSpriteSheet`, walk/club paths in code). **Not** MakeHuman, CharMorph, Mixamo, or morph-vector genetics. |
| **DragonBones** | **Not used.** Removed from the project; 2D uses sprite sheets / `DirectionalSpriteSheet` only. |

---

## Game systems (overview)

All major systems in one place. Each row links to the section where that system is detailed.

| System | What it does | Detailed in |
|--------|----------------|-------------|
| **World & resources** | Infinite 2D world; trees, boulders, berries, wheat, fiber; respawn rules; gatherable hitboxes aligned to sprite art (berries). | §II World, §XIII Items & resources, §XIX Gather & deposit |
| **Player** | Movement, hunger, hotbar consumables (9/0), direct control; speed modifiers (hunger, herding, **formation stance** debuff with ordered followers). | §III Player character, §IV Universal controls & UI |
| **Land claim & territory** | Placement (craft recipe); radius 400px; campfire (250px, 3 huts max) vs land claim; inventory; destroy flag = wipe. | §V Land claim & territory |
| **Buildings** | Placement (50px min, 128×128); Living Hut, Supply Hut, Shrine, Dairy, Oven; costs; woman slots; production. | §VI Buildings |
| **Reproduction & housing** | 1 woman per Living Hut; pregnancy requires hut; birth timer in radius; baby growth → clansman; trait inheritance. | §VII Reproduction & housing |
| **NPCs** | Types: women, sheep, goats, clansmen, cavemen; spawn sources; purpose (reproduction, herd, combat, work). | §VIII NPCs |
| **Hominid species & genetics** | 5 species; traits; 50/50 hybridization; species/trait/stat inheritance at birth. (Visuals = 2D art, not morph genomes.) | §IX Hominid classes |
| **Combat & healing** | Agro meter (70/60); CombatComponent (windup → hit → recovery); attack arc; stagger; death/corpse; Medic Hut planned. | §X Combat & healing |
| **Raiding** | Loot buildings/flag; destroy flag = total wipe; ClanBrain sets raid_intent; NPCs self-assign to Raid state. | §XI Raiding |
| **Food & production** | Oven (Wood + Grain → Bread); consumables (berries, grain, bread); wild wheat rule; Dairy/Meat planned. | §XII Food & production |
| **Items & resources** | Wood, stone, wheat, fiber, leather; tools (axe, pick, club); equipment slots (hotbar 1–0). | §XIII Items & resources |
| **Relics & shrine** | Rare items; place in Shrine → clan-wide buff; flag upgrades may require relics. | §XIV Relics & shrine |
| **Herding** | HerdInfluenceArea on herdables; influence → attach to herder; follow; join clan in radius; cross-clan steal; follow_is_ordered. | §XV Herding system |
| **ClanBrain (AI)** | One brain per claim; defender/searcher/raid quotas; strategic state (peaceful/defensive/aggressive/raiding/recovering); economic weights; alert decay. | §XVI ClanBrain |
| **FSM (NPC states)** | Priority-based state machine; eval every 0.1s; includes **`party`** (fighter formations), **`herd`** (wild herdables), Agro, Combat, Defend, Raid, Gather, Wander, etc. | §XVII FSM states |
| **RTS controls** | War Horn **H**; stances **Follow / Guard / Attack**; line/rings formations; **Break** **B**; drag + box select; defend claim/campfire. | §XVIII RTS controls, **`guides/rts.md`** |
| **Gather & deposit** | 40% slots → deposit; land claim generates GatherJob (ResourceIndex); MoveTo → GatherTask → MoveTo(claim); auto-deposit 100px. | §XIX Gather & deposit |
| **Inventory & drag-drop** | Player, claim, building, NPC, corpse inventories; drag manager; slot rules; hotbar equipment and consumables. | §IV, §XIII, §XX (inventory/, drag_manager) |
| **Occupation system** | Building slot assignment (woman to Living Hut/Dairy/etc.; animals to Farm); request_slot / confirm_arrival. | §VII, §XX (occupation_system.gd) |
| **Spatial indices** | ResourceIndex (200px grid, query_near); HostileEntityIndex; ClaimBuildingIndex; cached land claims for performance. | §XX Code architecture (systems/) |

---

## I. Core Fantasy & Vision

### Win Condition
- **Generational permadeath + brutal raiding.** You win when your bloodline completely dominates the map.
- **Pure sandbox** — no hard victory screen. Domination is the goal.

### Design Mix
- **Stoneshard** (tactical combat, survival, inventory) + **RimWorld** (colony management, emergent storytelling, permadeath).

### Primitive command model (RTS scope)
- **Lore constraint:** Early Sapiens are **not** modeled as giving **sophisticated verbal orders** or modern-style **army micromanagement**. There is no in-fiction “general barking complex tactics” — only **simple, bodily/social signals** the band can follow: **follow**, **guard** (stay close in a protective ring), **attack** (push forward with the leader), **defend** this territory, **rally** to the horn, **break** and return to chores.
- **Code constraint:** Player → clansmen RTS stays **minimal and modular** — shared `command_context`, single formation slot pass, config-driven tuning (`RTS_CONFIG`, `STANCE_CONFIG`) — so behavior stays **maintainable and optimizable**. See **`guides/rts.md`** for the full RTS doc.

### Art Direction
- **Gritty 64×64 pixel art**, top-down isometric (RimWorld angle: 30° tilt).
- **Strict 16-color muted earthy palette**: browns (#8B4513–#D2B48C), dull greens (#556B2F–#90EE90), stony greys (#696969–#A9A9A9), muddy beiges (#F5F5DC).
- **Rough, scratched cave-painting lines**; subtle dirt textures; strong silhouettes mandatory.
- **Tone**: Grim, savage, exhausted — dirty cavemen, scruffy beasts, collapsing hide huts. Pure prehistory: stone/wood/bone/hide/fire only.

---

## II. World

- **Infinite scrolling 2D plain** (grass, forest patches, rocky areas, water edges).
- **All normal resources respawn infinitely** (trees, boulders, berries, wheat, animals).
- **Only relics are finite** and non-respawning.
- **Wild wheat** grows only outside any land-claim radius (GDD).

---

## III. Player Character

- **Male only**, spawn at age 13 → natural death at 101.
- Choose one of **5 hominid species** at bloodline start → full 50/50 hybridization every generation.
- **Direct control** of player character only; clansmen are AI.
- **Speed**: **~110** px/s base (`player.gd` `move_speed`, aligned with clansman pace for formation); hunger <30% = 0.7×; herding = 0.97× per herded NPC; with **ordered clansmen**, **`formation_speed_mult`** slows the leader to match the strictest stance (**Guard** 0.75×, **Attack** 0.85×, **Follow** 1.0×).

---

## IV. Universal Controls & UI

| Key / Action | Effect |
|--------------|--------|
| **I** | Open any flag or building inventory |
| **Tab** | Stats panel (species mix, clansmen, women, raids, etc.) |
| **9 / 0** | Consume item in hotbar slot 9 or 0 |
| **Right-click NPC** | Herd (they follow you anywhere) |
| **H** (War Horn) | Rally clansmen within **~1500 px**; ordered follow + **command_context**; clears herd on rallied herders so they join formation (see **`guides/rts.md`**) |
| **B** | **Break** — dismiss ordered follow; clansmen return toward land claim / work |
| **Space** | **Gather** active resource / ground item (must overlap hitbox; berries use sprite-aligned collision) |
| **Drag-and-drop** | Player ↔ flag ↔ buildings ↔ clansmen ↔ ground; **drop clansman on player** = ordered follow |
| **Drag box** | Multi-select clansmen (player clan must resolve) |
| **Follow / Guard / Attack / Break** | Bottom HUD when clansmen selected — stances + break (see §XVIII) |

---

## V. Land Claim & Territory

### Placement
- First craftable: **Wood + Stone + Berries + Leather** (carryable at spawn).
- One-time **clan symbol + color picker** when placed.
- **Radius**: 400px (invisible fence — NPCs cannot leave on their own).
- **Upgrades** (planned): Flag → Tower → Keep → Castle (radius, storage, relics).

### Behavior
- Own drag-and-drop storage inventory.
- War Horn (**H**) — rally clansmen (RTS); see §XVIII and `guides/rts.md`.
- **Destroy enemy flag = total wipe**: all inventories vanish, huts destroyed, clansmen drop dead, women/animals scatter as wild.

### Campfire vs Land Claim
| Dimension | Campfire (Nomadic) | Land Claim (Stationary) |
|-----------|--------------------|--------------------------|
| Capacity | 6 slots | 12 slots |
| Radius | 250px | 400px |
| ClanBrain | No | Yes |
| Buildings | None | Oven, dairy, farm, huts, etc. |

### Village & late-game scale
- **Campfire** supports up to 3 Living Huts; then player must place a Land Claim.
- **Village** = claim at scale: large radius (upgradable), many huts and buildings. ClanBrain keeps track of what the clan needs and has clansmen craft/farm accordingly (supply/demand; see `guides/future implementations/village.md`).
- **Task assignment (planned):** clanspeople gain experience in what they do most; highest experience get picked for that task. Home huts (male + female) flavor; economy remains ClanBrain-driven.

---

## VI. Buildings

### Placement
- **50px** minimum between buildings and claim center.
- **128×128** footprint; drag from build menu onto world inside claim.

### Building List (Current)

| Building | Cost | Woman | Purpose |
|----------|------|-------|---------|
| **Living Hut** | 1 Wood, 1 Stone | 1 | Houses 1 woman + her children. Required for pregnancy. |
| **Supply Hut** | 1 Wood, 1 Stone | 0 | Extra storage (6 slots) |
| **Shrine** | 1 Wood, 1 Stone | 0 | Place relics → clan-wide buffs |
| **Dairy Farm** | 1 Wood, 1 Stone | 1 | Cheese & butter from milk |
| **Oven** | 2 Stone | 0 | 1 Wood + 1 Grain → 1 Bread (15s) |

### Full GDD Building List (Aspirational)

| Building | Woman | Main Function |
|----------|-------|---------------|
| Living Hut | 1 | 1 woman + her children; required for pregnancy |
| Farm | 1 | Wool (sheep) / Milk (goats) |
| Spinner | 1 | Cloth from wool |
| Dairy | 1 | Cheese & butter from milk |
| Bakery | 1 | Bread: X Wheat + any edible |
| Armory | 1 | Weapons |
| Tailor | 1 | Armor, backpacks, travois |
| Medic Hut | 1 | Heals wounds (berries) |
| Storage Hut | 0 | Extra shared storage |
| Shrine | 0 | Relics → permanent buffs |

---

## VII. Reproduction & Housing (Simulation Model)

**Pivot:** Population is driven by housing, not an abstract cap. Each Living Hut = 1 woman + her children.

### Living Hut
- **1 woman per Living Hut** (drag-and-drop assignment).
- Houses that woman and her children until they grow up.
- **Pregnancy requires a Living Hut** — women do not get pregnant unless assigned to one.

### Reproduction
- **Women** spawn in wilderness → Herd → bring into radius → claimed.
- Assign woman to Living Hut → birth timer can run.
- **Birth timer** only runs when woman has a Living Hut and is inside land-claim radius.
- Mate detection: male within 200px of woman in claim.

### Baby Growth
- Children live in mother's hut until promoted.
- Timer (e.g. 90s test / 13 years design) → promote to clansman.
- **Genetics**: Species, traits, and stats are resolved at birth from mother + father. See **§IX Genetics & hybridization** for full rules.

---

## VIII. NPCs

| NPC | Spawn | Purpose |
|-----|-------|---------|
| **Women** | Wilderness | Reproduction + production buildings |
| **Sheep / Goats** | Wilderness | Wool & milk |
| **Horses** | Wilderness | Riding + travois (planned) |
| **Clansmen** | Surplus babies | Permanent AI army |
| **Predators** | Wilderness | Dire wolves, mammoths — hostile, loot (planned) |
| **Cavemen** | Spawn | Wild humans; can place claims, become clan leaders |

---

## IX. Hominid Classes (5 Species)

Each has 3–4 unique traits. Base stats 50/100; traits add +X%.

### 1. Homo sapiens
**Role:** Adaptable social leaders.
- Learning (+20% Intelligence)
- Social Strategist (+15% Social)
- Adaptive (+10% Agility)

### 2. Neanderthal
**Role:** Tough warriors.
- Robust (+20% Strength, +15% Endurance)
- Pain Resistant (+25% Pain Tolerance)
- Hunter's Grit (+10% Aggression)

### 3. Heidelbergensis
**Role:** Sturdy workers.
- Enduring Laborer (+20% Stamina, +15% Carry Capacity)
- Builder's Might (+10% Intelligence)
- Resilient (+10% Endurance)

### 4. Denisovan
**Role:** Keen hunters.
- Sharp Senses (+20% Perception)
- Aggressive Predator (+15% Aggression)
- Nomad Endurance (+10% Pain Tolerance)

### 5. Floresiensis
**Role:** Agile swarmers.
- Swarm Instinct (+20% Social)
- Nimble (+15% Agility)
- Compact (+10% Fertility)

### Genetics & hybridization (detailed)

Genetics drive **species**, **traits**, and **numeric stats**. **Appearance** in-game is **2D sprites** (art pipeline), not a morph vector or CharMorph/MakeHuman/Mixamo stack. Rules apply at **bloodline start** (player picks species) and at **every birth** (mother + father → baby).

#### When genetics run
- **Bloodline start:** Player chooses one of the 5 hominid species; that is the founder’s species and trait pool.
- **Birth:** When a woman gives birth, the **father** is the mate at conception (e.g. `current_mate` in ReproductionComponent). Mother and father each have a species and a set of traits; the baby’s species, traits, and stats are derived from both.

#### Species inheritance
- Each NPC has exactly **one species** (sapiens, neanderthal, heidelbergensis, denisovan, floresiensis). Species defines that NPC’s **trait pool** (the 3–4 traits listed in §IX per species).
- **Baby’s species:** Either (a) **50/50 random** — roll once, child gets mother’s or father’s species; or (b) **trait-weighted** — e.g. child inherits the species that contributed more traits (optional, for more “mixed” feel). Design choice; document which rule is used.

#### Trait inheritance
- **Per-trait 50/50:** For each trait slot (e.g. up to 6 per NPC), decide which parent it comes from: 50% mother, 50% father (random per trait). The child’s trait list is built from these draws. If a parent has fewer traits than slots, the other parent fills the rest (or leave slot empty / use default).
- **Which traits exist:** Only traits that belong to the **parent’s species** can be passed. So a sapiens parent can pass Learning, Social Strategist, Adaptive; a neanderthal can pass Robust, Pain Resistant, Hunter’s Grit. A hybrid child can therefore have a mix of sapiens and neanderthal traits (e.g. Learning + Robust).
- **Dominant/recessive (optional, see reproductiontraits.md):** For a more anthropological model, traits can have alleles (dominant/recessive). Then: each parent contributes one allele per “gene”; phenotype = dominant if either allele is dominant, else recessive. Same idea: child’s expressed traits still come from both parents, with a clear rule.

#### Stat blending
- **Numeric stats** (e.g. strength, intelligence, perception, stamina — whatever the game uses):  
  `child_stat = (mother_stat + father_stat) / 2 + mutation`  
  where `mutation` is a small random offset (e.g. ±2% or ±1 point) so siblings differ slightly.

#### Appearance (2D — current plan)
- **Visuals:** Use shared sprite assets per species/role (e.g. woman vs caveman textures in `AssetRegistry` / scenes). Optional future: **variant indices** or **tint** for variety — still **not** a 261-morph genome file.
- **Dropped (historical):** MakeHuman / CharMorph / Mixamo / `genome_baseline.json` morph pipelines were **removed** from the repo; do not document them as the active plan.

#### Implementation hooks
- **At birth:** ReproductionComponent (or the system that spawns the baby) has access to mother and father (e.g. `current_mate` as father). Call a single **resolve_child_genetics(mother, father) → { species, traits[], stats{} }**; apply result to the new baby NPC.
- **Storage:** Each NPC stores `species: String` (enum or id), `traits: Array` (trait ids or names), and optionally `stats: Dictionary`. Baby growth and character menu read from these.
- **Max traits per NPC:** Cap at 6 (or design max); if both parents contribute many traits, pick by priority or random until full.

#### Summary table
| What        | Rule |
|------------|------|
| Baby species | 50/50 random from mother/father (or trait-weighted). |
| Baby traits  | Per slot: 50% from mother, 50% from father; only traits from that parent’s species. Max 6. |
| Baby stats   | Average of mother and father + small mutation. |
| Baby appearance | **2D:** same species/role sprites unless you add explicit art variants (not morph blending). |

---

## X. Combat & Healing

### Style
- **RimWorld / Dwarf Fortress** auto-combat (no direct unit control).
- **Agro meter** (0–100): enter combat at 70, exit at 60.
- **Triggers**: land claim intrusion, area-of-agro, being attacked, herd steal.

### Mechanics
- **CombatComponent**: Windup → hit frame → recovery.
- **Attack arc**: 90° cone (positioning matters).
- **Stagger**: hits interrupt enemy windup.
- **Weapon profiles**: Axe, Pick, Unarmed (different timings).
- **Death**: Health → 0 → corpse (lootable); leader succession (oldest clansman).

### Healing (Planned)
- Wounds exist → hurt characters auto-path to Medic Hut if berries stocked.

---

## XI. Raiding

- **Loot** every building + flag inventory first (drag-and-drop).
- **Destroy enemy flag** → total wipe.
- **War Horn + Herd** = instant massive war parties.
- **ClanBrain** sets raid_intent; NPCs self-assign to Raid state.

---

## XII. Food & Production

### Bakery / Oven
- **Wild Wheat** grows only outside land-claim radius.
- **1 Wood + 1 Grain** → 1 Bread (15s).
- GDD: X Wheat + any one edible (berries, meat, cheese, butter) → flavored Bread Loaf.

### Consumables
| Item | Hunger | Notes |
|------|--------|-------|
| Berries | 5% | Basic |
| Grain | 7% | From wheat |
| Bread | Best | From Oven |
| Meat | 10% | Planned |
| Cheese / Butter | — | From Dairy (planned) |

---

## XIII. Items & Resources

### Resources
- **Wood** (trees, axe) | **Stone** (boulders, pick) | **Wheat** (wild plants) | **Fiber** (plants)
- **Leather** (corpses) | **Wool** (sheep) | **Milk** (goats) — planned

### Tools & Weapons
- **Axe** — wood + combat
- **Pick** — stone
- **Club (WOOD)** — melee, narrow arc
- **Spear** — extended range (planned)

### Equipment Slots (Hotbar)
1. Right Hand | 2. Left Hand | 3. Head | 4. Body | 5. Legs | 6. Feet | 7. Neck | 8. Backpack | 9–0. Consumables

---

## XIV. Relics & Shrine

- **Rare unique items** (wilderness spawns or animal drops).
- Drag into Shrine inventory → **permanent clan-wide buff**.
- Higher flag upgrades require relics.

---

## XV. Herding System

### Model
- **Animal-authoritative**: HerdInfluenceArea (250px) on each herdable detects herders.
- Influence accumulates; above threshold → attach to herder.
- **Cavemen never "own"** — they search or lead; animals attach when herder enters range.

### Key Distances
| Param | Value |
|-------|-------|
| HerdInfluenceArea | 250px |
| Active seeking | 1700px |
| Herd break | 300px |
| Follow min/max | 50 / 150px |
| Claim radius (join) | 400px |

### Stealing
- Same-clan herders **cannot** steal from each other.
- Cross-clan stealing allowed.
- `follow_is_ordered` prevents stealing (player-ordered follow).

---

## XVI. ClanBrain (AI Strategy)

One brain per land claim (RefCounted). Sets intent; NPCs pull quotas and self-assign. Designed to scale for large villages (many huts, large radius).

### Roles
- **Defender quota** — NPCs self-assign to Defend state.
- **Searcher quota** — NPCs self-assign to HerdWildNpc (search).
- **Raid intent** — NPCs self-assign to Raid state.
- **Economic weights** — food_weight, resource_weight, build_weight, herd_weight (on land claim meta for FSM/job selection).

### Strategic States
PEACEFUL | DEFENSIVE | AGGRESSIVE | RAIDING | RECOVERING

### Gates
- **2+ cavemen** for full defender logic; single caveman stays free to herd/gather.
- **Min stock** (10 stone, 10 wood, 10 food) for defenders unless alert.
- **Player clans**: defender ratio from slider; no raid evaluation.

### Scale & efficiency (late-game)
- **Cached data:** uses `main.get_cached_land_claims()` where available instead of `get_nodes_in_group("land_claims")`; threat cache refreshed every 30s.
- **Evaluation interval:** 5s default; staggered per claim to avoid spike.
- **One brain per claim:** no global manager; each claim’s brain only iterates its own clan_members and nearby_enemy_claims.
- **Future (village):** resource targets and quotas can scale by population and building count; supply/demand and experience-based task pick described in `guides/future implementations/village.md`.

---

## XVII. FSM States (Priority Order)

1. Agro (15.0)
2. Combat (12.0)
3. Herd Wild NPC leading (11.5)
4. **Party** (ordered fighters: Follow/Guard/Attack formations) / **Herd** (wild herdables only) (11.0)
5. Deposit moving (12.0 in wander)
6. Defend (8.0)
7. Raid (8.5)
8. Reproduction (7.5)
9. Work at building (7–10)
10. Gather (5.6–6.0)
11. Herd Wild NPC searching (5.5)
12. Wander (0.5–3.0); **returning_from_break** (after RTS **Break**) can evaluate **~13** so clansmen walk home before herd/gather steal the FSM.

---

## XVIII. RTS Controls (Player → Clansmen)

**Design premise:** Orders are **primitive** (gesture, horn, stance), not a modern command vocabulary — see **§I Primitive command model**. **Full detail:** `guides/rts.md` (controls, files, playtest flags, engineering rationale).

### Selection & orders
- **Right-click** clansman → context menu: **Follow**, **Defend** (claim), **Search**, **Work**, **Info** (exact set depends on target and clan resolution).
- **Drag** clansman onto **player** → **ordered follow** (registers follower, builds `command_context`).
- **Drag box** on screen → multi-select clansmen (requires player clan / territory to resolve).

### War Horn (**H**)
- Cooldown ~1 s; rally radius **~1500 px** (`RTS_CONFIG`).
- Idle / in-range clansmen sprint in; **ordered follow** + stance context applied.
- **Herd break:** clansmen who were **herding** animals detach herd when rallied so they can form up.

### Stances (HUD: **Follow | Guard | Attack**)
Applied to **selected** ordered clansmen; stored in **`command_context.mode`** with stance-tuned **agro threshold**, **chase distance**, and **speed multiplier**:

| Stance | Aggro threshold | Chase dist (px) | Clansman speed mult | Player formation mult |
|--------|-----------------|-----------------|---------------------|------------------------|
| **FOLLOW** | 0 | 0 | 1.0 | 1.0 |
| **GUARD** | 70 | 150 | 0.75 | 0.75 |
| **ATTACK** | 100 | 300 | 0.85 | 0.85 |

### Hunt, raid, and long movement (recommended play)
- **Cross terrain at full pace:** For **hunting**, **raiding**, or any **long** move with clansmen, use **Follow** — leader and followers run at **1.0×** formation speed and the group escorts **behind** you.
- **Do not march far in Attack:** **Attack** slows the **player** (**0.85×**) and formation NPCs (**0.85×**); it is for **closing to fight** (line **ahead** of the leader), not for map-crossing. Switch to **Attack** when the **target is close**.
- **Guard** (**0.75×**) is optional for a **tenser** approach; still slower than **Follow** for pure travel. Detail: **`guides/rts.md` §4.4**.

### Formations (moving with a leader)
- **Player-led:** `main._update_formation_slots()` delegates to **`FormationUtils.compute_formation_slots()`** → player **`formation_slots`** meta (per follower: slot position, steer target, facing, mode).
- **NPC-led (same clan):** caveman/clansman leaders with ordered followers publish the same slot layout via **`FormationUtils.publish_slots_for_npc_leader()`** (`formation_velocity` on leader mirrors player). Followers use FSM **`party`** with identical stance tuning as the player path.
- **FOLLOW** — loose group **behind** leader (rear arc).
- **GUARD** — **ring** around leader (even spacing).
- **ATTACK** — **horizontal line in front** of leader (perpendicular to facing).
- **Catch-up:** clansmen farther than ~35 px from slot use **2×** speed until settled (`RTS_CONFIG.catchup_speed_mult`).
- **Leash:** extreme distance (~1200 px) can break ordered follow.

### Break (**B** or Break button)
- Clears ordered follow / follower list; resets relevant combat-follow flags.
- **`returning_from_break`** meta + high **wander** priority → steer to **land claim**, then resume normal jobs (gather, herd, etc.).

### Defend (static)
- **Defend land claim / campfire** = **defend_state** border patrol — not the same as **Guard** stance while moving with the player.

### Hostile flag
- Followers’ **`is_hostile`** can track player weapon for RTS combat alignment (sustain / UI); not a separate “attack move” key beyond **Attack** stance.

---

## XIX. Gather & Deposit

### Threshold
- **40%** of slots (min 3) → move to deposit.
- **1 food item total** kept; rest deposited.

### Flow
1. Request job from land claim (throttled 0.5s)
2. MoveTo(resource) → GatherTask → MoveTo(claim)
3. Auto-deposit within 100px of claim center
4. Repeat

### Resource Capacity
- Trees: 3 | Boulders: 2 | Berries: 1 | Wheat: 1 | Fiber: 1 workers max

### Player gather (Space)
- One **active** gather target at a time (`main.active_collection_resource`); **stale freed refs** cleared each frame and on item pickup.
- **Berry bushes:** sprite uses large texture + **feet-at-node** offset; **collision is aligned to the scaled sprite** (`gatherable_resource._align_gather_hitbox_to_sprite`) so overlap matches visible bush. Playtest: `gather_*` JSONL events when `--playtest-capture` is on.

---

## XX. Code Architecture & Systems

### Script Structure

```
scripts/
├── main.gd                 # Central orchestrator (~5.8k lines): spawn, UI, input, world, building placement
├── player.gd               # Player movement, hunger, herding
├── land_claim.gd           # Land claim logic, ClanBrain owner, defender/searcher pools, EnemiesInClaim zone
├── campfire.gd             # Nomadic base (250px, 6 slots, no ClanBrain)
├── gatherable_resource.gd  # Resource nodes, reserve/release, cooldown, ResourceIndex registration
├── ai/
│   ├── clan_brain.gd       # RefCounted AI strategy (defender/searcher/raid quotas, strategic state)
│   ├── task_runner.gd      # Runs current_job/current_task; lease expiry; cancel on defend/combat/follow
│   ├── jobs/
│   │   ├── job.gd          # Base Job (task list, advance, cancel)
│   │   ├── gather_job.gd   # MoveTo(resource) → GatherTask → MoveTo(claim); expire_time lease
│   │   └── craft_job.gd    # Craft/knap jobs
│   └── tasks/
│       ├── task.gd         # Base Task (tick → RUNNING/SUCCESS/FAILED)
│       ├── move_to_task.gd # Steering to position
│       ├── gather_task.gd  # Harvest from resource; same-node 80%; release on done
│       ├── drop_off_task.gd
│       ├── pick_up_task.gd
│       └── occupy_task.gd
├── npc/
│   ├── npc_base.gd         # ~3.4k lines: FSM, components, agro checks, auto-deposit, herding
│   ├── fsm.gd              # Priority-based state machine; eval every 0.1s; 16 states
│   ├── steering_agent.gd   # SEEK/ARRIVE/FLEE/WANDER; separation; land claim avoidance
│   ├── states/             # One script per state
│   │   ├── base_state.gd   # can_enter(), update(), get_priority(); helper _is_defending(), etc.
│   │   ├── idle_state.gd
│   │   ├── wander_state.gd # Deposit movement when moving_to_deposit
│   │   ├── gather_state.gd # Pulls GatherJob from land_claim; no resource scanning
│   │   ├── party_state.gd    # Ordered fighters: formations + stances (player or NPC leader)
│   │   ├── herd_state.gd     # Wild herdables only (woman/sheep/goat); tethered follow + steal
│   │   ├── herd_wildnpc_state.gd # Cavemen search/lead; searcher quota
│   │   ├── combat_state.gd # Chase target; request_attack via CombatComponent
│   │   ├── defend_state.gd # Patrol claim border; defender quota
│   │   ├── raid_state.gd   # Reads raid_intent from ClanBrain
│   │   ├── build_state.gd  # Cavemen place land claims
│   │   ├── reproduction_state.gd
│   │   ├── occupy_building_state.gd
│   │   ├── work_at_building_state.gd
│   │   ├── craft_state.gd
│   │   ├── eat_state.gd
│   │   ├── agro_state.gd   # Agro recover (herd steal); not land claim defense
│   │   └── search_state.gd # Ant-style exploration
│   └── components/
│       ├── combat_component.gd   # WINDUP → hit frame → RECOVERY; CombatScheduler for timing
│       ├── health_component.gd  # HP, take_damage, death, corpse, leader succession
│       ├── weapon_component.gd
│       ├── perception_area.gd   # AOP; body_entered/exited; get_nearest_enemy(), get_enemies_in_range(), get_threats_in_range(), get_herdables_in_range(), has_herdables()
│       ├── herd_influence_area.gd # On herdables; collision_mask=3; influence → attach
│       ├── reproduction_component.gd
│       └── baby_growth_component.gd
├── systems/
│   ├── formation_utils.gd   # Shared formation slot math (player + NPC party leaders)
│   ├── party_command_utils.gd # NPC leader command_context (stance dict shape matches main.gd)
│   ├── herd_manager.gd      # Follower lists; party ordered followers helper
│   ├── combat_scheduler.gd # Autoload: events[] sorted by time; schedules hit/recovery callables
│   ├── combat_tick.gd      # Autoload: 25 Hz; agro events, decay, hysteresis 70/60
│   ├── entity_registry.gd  # instance_id → entity_id; get_id(), resolve
│   ├── resource_index.gd  # Spatial grid 200px cells; query_near(); register/unregister
│   ├── hostile_entity_index.gd
│   ├── occupation_system.gd # Building slot assignment (woman, animal)
│   ├── baby_pool_manager.gd
│   ├── claim_building_index.gd
│   └── y_sort_utils.gd
├── buildings/
│   ├── building_base.gd    # Health, decay, production_component
│   ├── building_registry.gd # Costs, names, icons for build menu
│   └── oven.gd
├── config/
│   ├── npc_config.gd       # Hunger, movement, herd, agro, gather, FSM priorities
│   ├── balance_config.gd   # Spawn counts, production times, lease_expire_seconds
│   ├── craft_registry.gd   # Recipes (Oldowan, Cordage, Campfire, Travois)
│   ├── rts_formation_config.gd  # RTS_CONFIG: rally, horn CD, leash, catch-up, snapshots
│   ├── debug_config.gd    # --debug, --agro-combat-test, playtest_capture_always, etc.
│   └── corpse_config.gd
├── inventory/
│   ├── drag_manager.gd     # Singleton; drag preview, drop validation
│   ├── inventory_slot.gd
│   ├── player_inventory_ui.gd
│   └── building_inventory_ui.gd
└── ui/
    ├── dropdown_menu_ui.gd # Right-click context menu
    └── character_menu_ui.gd
```

### Autoloads (project.godot)

| Name | Path | Role |
|------|------|------|
| SingleInstance | `single_instance.gd` | One process at a time (TCP lock port 45287); `SKIP_SINGLE_INSTANCE=1` to bypass |
| UnifiedLogger | `logging/unified_logger.gd` | Centralized logging |
| PlaytestInstrumentor | `logging/playtest_instrumentor.gd` | Event capture; `snapshot` has `state_counts`, `ai_caveman_states` / `ai_clansman_states` (AI only, excludes player), `ai_clans` (per AI claim: leader `state`, `herded_count`, `clan_pop`, `brain`) |
| NPCConfig | `config/npc_config.gd` | NPC tuning (hunger, movement, herd, agro, gather) |
| DebugConfig | `config/debug_config.gd` | Debug flags, CLI args |
| BalanceConfig | `config/balance_config.gd` | Spawn, production, lease_expire |
| CombatScheduler | `systems/combat_scheduler.gd` | Schedules hit/recovery at msec |
| CombatTick | `systems/combat_tick.gd` | 25 Hz agro decay, threshold 70/60 |
| EntityRegistry | `systems/entity_registry.gd` | instance_id → entity_id |
| ResourceIndex | `systems/resource_index.gd` | Spatial resource queries |
| OccupationSystem | `systems/occupation_system.gd` | Building slot assignment |
| ClaimBuildingIndex | `systems/claim_building_index.gd` | Claim → buildings |
| HostileEntityIndex | `systems/hostile_entity_index.gd` | Hostile NPC lookup |
| YSortUtils | `systems/y_sort_utils.gd` | Draw order |
| CompetitionTracker | `competition_tracker.gd` | Deposit counts per clan |
| CorpseConfig | `config/corpse_config.gd` | Corpse behavior |
| ChunkUtils | `world/chunk_utils.gd` | World chunking |

### System Flows

**FSM evaluation (adaptive):**
1. Near player (<800px): 0.1s interval. Far: 0.25s (reduces frame spikes).
2. Stagger: `evaluation_timer` offset by `hash(npc_id) % 100` ms at init so NPCs don't all eval same frame.
3. When ≥ interval, reset timer, run `_evaluate_states()`.
4. For each registered state: call `can_enter()` and `get_priority()`.
5. Highest-priority valid state wins.
6. If different from current: `change_state(new_state)`.
7. `current_state.update(delta)` each frame.

**Combat flow:**
1. **Agro**: `CombatTick` receives `push_agro_event()` from intrusion/damage/herd steal
2. **Threshold**: agro ≥ 70 → set `combat_target` / `combat_target_id`; agro < 60 → clear
3. **Combat state**: `combat_state.can_enter()` requires agro ≥ 70 and valid target
4. **Attack**: `combat_state` calls `combat_component.request_attack(target)`
5. **CombatComponent**: IDLE → WINDUP; schedules hit via `CombatScheduler.schedule()`; on hit frame: arc check, damage, stagger; schedules recovery; RECOVERY → IDLE

**Gather/Deposit flow:**
1. `gather_state` calls `land_claim.generate_gather_job(npc)` (throttled 0.5s)
2. Land claim uses `ResourceIndex.query_near()` + soft-cost clan spread; `resource.reserve(worker)`
3. `GatherJob`: MoveTo(resource, 48px) → GatherTask(56px lock, 80% same-node) → MoveTo(claim, 100px)
4. `TaskRunner._physics_process`: runs `current_task.tick()`; SUCCESS → advance job; FAILED → cancel
5. On arrival at claim: `npc_base._check_and_deposit_items()` (auto-deposit within 100px)

**Herding flow (animal-authoritative):**
1. Herdable has `HerdInfluenceArea` (Area2D, collision_mask=3)
2. Herder (caveman/player) enters radius → influence accumulates
3. Above threshold + contest_min_duration → `_try_herd_chance(herder)` on herdable
4. Success: herdable sets `is_herded=true`, `herder=leader`, enters `herd` state
5. `herd_state`: follows herder; inside claim radius → `_try_join_clan_from_claim()`, `_clear_herd()`

**ClanBrain → NPC (pull-based):**
1. Land claim owns `clan_brain`; calls `clan_brain.update(delta)` every frame
2. Every 5s: `_evaluate_clan_state()`, `_update_defender_assignments()`, `_update_searcher_assignments()`
3. Writes `defender_quota`, `searcher_quota`, `raid_intent` to land claim meta
4. `defend_state.can_enter()`: reads quota, `add_defender(npc)` if under
5. `herd_wildnpc_state.can_enter()`: reads searcher_quota, `add_searcher(npc)` if under
6. `raid_state.can_enter()`: `clan_brain.should_npc_raid(npc)` and `is_raiding()`

### Key Config Vars (NPCConfig)

| Var | Default | Purpose |
|-----|---------|---------|
| deposit_range | 100 | Auto-deposit when within this of claim center |
| gather_deposit_threshold | 0.4 | 40% slots → move to deposit |
| gather_same_node_until_pct | 0.8 | Stay at resource until 80% inv |
| gather_distance | 48 | Must be within this to gather |
| gather_move_cancel_threshold | 32 | Moving beyond this during gather cancels |
| herd_mentality_detection_range | 250 | HerdInfluenceArea radius |
| herd_max_distance_before_break | 300 | Herd breaks if herder this far |
| agro_enter_threshold | 70 | Enter combat |
| agro_exit_threshold | 60 | Exit combat (hysteresis) |
| agro_decay_combat | 2.0 | Agro/sec decay in combat |
| agro_decay_idle | 5.0 | Agro/sec decay out of combat |

### Key Config Vars (BalanceConfig)

| Var | Purpose |
|-----|---------|
| lease_expire_seconds | 90 | GatherJob expires, releases resource |
| resource_cooldown_seconds | 120 | After 3 gathers, resource cooldown |
| caveman_count | 4 | AI caveman leaders + land claims at start (tune for 1v1 etc.) |
| bread_craft_time, wool_craft_time, milk_craft_time | Production durations |

### Component Initialization (npc_base)

NPCs get: `FSM`, `SteeringAgent`, `CombatComponent`, `HealthComponent`, `WeaponComponent`, `PerceptionArea` (node name "DetectionArea"), `TaskRunner`, `ReproductionComponent` (women), `BabyGrowthComponent` (babies), `HerdInfluenceArea` (herdables). FSM creates state instances with `load()`; each state `initialize(npc)`.

### Main Scene

`res://scenes/Main.tscn` — root runs `main.gd`.

### Logic & Mechanics (Implementation Details)

**State blocking:** `_is_defending()`, `_is_in_combat()`, `_is_following()` block lower-priority states. Tasks cancel when any of these true.

**Task cancellation:** `npc.should_abort_work()` → true if `defend_target` or `combat_target` or `follow_is_ordered`. TaskRunner checks every frame; cancels job, releases resource reservations.

**Resource reservation lifecycle:** `GatherJob` created → `resource.reserve(worker)`. On job SUCCESS/FAILED/cancel → `GatherTask` or TaskRunner calls `resource.release(worker)`. Lease expiry in TaskRunner also cancels and releases.

**CombatComponent states:** IDLE → `request_attack()` → WINDUP (windup_time) → CombatScheduler fires hit → `_on_hit_frame()` (arc check, damage, stagger) → RECOVERY → CombatScheduler fires → IDLE.

**Attack arc:** 210° cone (7π/6) in front of attacker. Target in range but out of arc → whiff; combat_state may switch to nearest in-arc enemy.

**PerceptionArea (AOP):** Area2D on NPC; implements AOP (Area of Perception). `body_entered`/`body_exited` track enemies and herdables. `get_nearest_enemy()`, `get_enemies_in_range()`, `get_threats_in_range()`, `get_herdables_in_range()`, `has_herdables()`. Base layer for AOA, combat target selection, proximity agro, mammoth agro, herd detection (Phase 2). Within 380px: event-driven. Beyond 380px: herd_wildnpc falls back to get_nodes_in_group for 1700px active seeking. See Terminology section.

**EnemiesInClaim (land claim):** Area2D on land claim; collision_mask=3 (layers 1+2) detects player and NPCs. Event-driven intrusion for defenders.

**HerdInfluenceArea collision_mask:** Must be 3 (layers 1+2) to detect both player and cavemen. Mask=1 only detected player → caveman herding broken.

**Land claim job generation:** `generate_gather_job(worker)` → ResourceIndex.query_near(claim_pos, 3×radius) → soft-cost: `distance + nearby_clan_mates × clan_spread_penalty` → pick lowest; reserve; create GatherJob.

**Auto-deposit:** `_check_and_deposit_items()` in npc_base; runs every 0.5s (0.1s when inv≥4 or herding 2+); within 100px of claim; 1s cooldown; two-pass: collect items to deposit (keep 1 food total), then transfer.

**Directional spritesheets:** `DirectionalSpriteSheet` loads PNG + JSON. Set `DIRECTIONAL_WALK_PATH`, `DIRECTIONAL_CLUB_PATH`, `DIRECTIONAL_WOMAN_PATH` in `walk_animation.gd` to enable 8-direction walk. Layout: rows = directions (S, SE, E, NE, N, NW, W, SW), columns = frames.

**Appearance assets:** 2D only — see `AssetRegistry`, `DirectionalSpriteSheet`, and `walk_animation.gd` paths. CharMorph / genome baseline JSON / MakeHuman / Mixamo are **out of scope** and were removed from the repo.

---

## XXI. Implementation Status (Snapshot)

| Category | Status |
|----------|--------|
| Core gameplay | Solid |
| AI / ClanBrain | Strong |
| Combat | Working |
| Herding | Production-ready |
| Gather/Deposit | Production-ready |
| GDD alignment | ~40% |
| Generational permadeath | Not wired |
| Hominid species | Not implemented |
| War Horn (RTS rally + formations) | Implemented — see §XVIII, `guides/rts.md` |
| Medic Hut / Wounds | Not implemented |
| Predators / Horses | Not implemented |

**Dev resources:** Cursor plans location and plan index → `guides/dev_resources.md`.

---

## XXII. Future implementations (concepts)

The **`guides/future implementations/`** folder holds design notes and concept docs (village, weapons, research, popcontrol, combat plans, etc.). These are **ideas for content that would be fun to add** — not committed roadmap or promised features. They’re there to inspire and to keep “someday” design in one place; priority and scope are decided separately.

Below: every doc in that folder, with a short summary and **implementation-oriented notes** so each could be coded into the game.

---

### Future implementations (by document)

| Doc | Summary | How it could be coded |
|-----|---------|------------------------|
| **village.md** | Village = home huts (male+female), ClanBrain supply/demand, experience-based task assignment. Campfire → 3 huts then claim. | Extend ClanBrain: track "needs" (food, wood, stone) and publish work requests. Add `experience_by_activity: Dictionary` per NPC (gather/craft/defend); when assigning jobs, sort candidates by experience for that activity. Optional "home hut" = Living Hut with assigned couple; reuse OccupationSystem with a "household" slot type. |
| **weapons.md** | Nameable weapons; buffs over time or with kills. | Add `weapon_name: String` and `kill_count: int` (or `use_time: float`) on WeaponComponent or item data. Buffs: resource/script that defines scaling (e.g. +1% damage per 10 kills, cap 20%). UI: rename weapon in inventory or character menu. |
| **research.md** | Small "research" unlocks we take for granted (e.g. defecate outside village first; need to learn it). Gameify mundane behaviors. | Per-clan or global `unlocked_behaviors: Array[String]` (e.g. "defecate_outside"). NPCs check before executing behavior; if not unlocked, use fallback (defecate anywhere → hygiene penalty until researched). Research could be time-based, building-based (Shrine?), or event-triggered. |
| **popcontrol.md** | Persistent world; housing caps clansmen, food caps/throttles babies, starvation kills. SimulationManager tick (e.g. 120s) drives consumption and reproduction. | Add autoload `SimulationManager`: `game_time`, `tick_interval_seconds`, signal `simulation_tick(delta_game_time)`. LandClaim connects to signal; on tick: compute daily_need (women + clansmen + babies), drain food_buffer, trigger_starvation() if buffer < 0, scale birth chance by surplus. `max_clansmen = 3 + living_huts * 3`; promote baby only if `current_clansmen < max_clansmen`. |
| **predator.md** | Hostile wildlife (Wolf first): hunt prey, eat corpses, attack cavemen. Stats (health, damage, attack_speed, hunger, fear threshold). | New NPC type "predator"; reuse NPCBase + CombatComponent + PerceptionArea. Add PredatorType resource or config: max_health, damage, detection_range, attack_range, hunger decay. States: Idle/Wander, Hunt (target sheep/goat), Eat (timer on corpse, restore hunger), Combat (caveman). DetectionArea mask includes prey layer; target selection: nearest prey or caveman by priority. |
| **AOP_PHASE2_PLAN.md** | Herdables in PerceptionArea (event-driven); resources in AOP for gather; trait-based AOP radius; fix EnemiesInClaim mask = 3. | PerceptionArea: add `nearby_herdables` dict, body_entered/exited for woman/sheep/goat (wild only). Expose `get_herdables_in_range()`, `has_herdables()`. herd_wildnpc_state: use PerceptionArea when in range, fallback get_nodes_in_group for 1700px. land_claim.gd: set `_enemies_zone.collision_mask = 3`. |
| **CRITICAL_FIXES.md** | Prioritized bugs/fixes: stagger self-target guard, baby inventory size, 2D/renderer checks, War Horn, Medic Hut, etc. | Per item: apply code change (e.g. combat_component guard `if target == npc: return`; NPCConfig.baby_inventory_slots; build_state MIN_CLAIM_GAP). Use as checklist; tick off in plan or PR. |
| **daynight.md** | Day/night cycle; AOP lowers at night; torches broaden AOP but make you easier to see. | Global `game_time` or EnvironmentController; day_phase 0–1 (0=midnight, 0.5=noon). Shader or CanvasModulate for darkness. NPCConfig or PerceptionArea: `aop_radius_night = aop_radius * 0.5`. Torch: held item or building that adds AOP bonus and sets "torch_active" so hostiles get range bonus to detect carrier. |
| **food.md** | Housing = clansmen cap; food = baby throttle + starvation; daily consumption per role; fertility scales with surplus. | Same as popcontrol: SimulationManager tick + LandClaim _on_simulation_tick. daily_need = women*1 + clansmen*2 + babies*0.5; food_buffer -= daily_need; if food_buffer < 0 trigger_starvation (kill order: babies → clansmen → women). Birth chance = f(food_buffer / daily_need). |
| **knapping.md** | Flint knapping minigame: Polygon2D core, target outline, strike drag, progress bar, fracture on bad strike. | New scene KnappingMinigame: CorePolygon (Polygon2D), TargetOutline (Line2D), StrikePreview (Line2D), ProgressBar. On drag release: ray/arc vs core polygon; subtract chip polygon or adjust vertices; compare to target, update progress. Bad angle → add FractureLines or fail. On success: yield tool item (Oldowan, etc.). |
| **building_improvements.md** | Two-phase commit: placement mode (ghost, no cost) → confirm (consume materials, spawn building). Single place for effects. | UI: on build icon click enter "placement_mode"; show ghost BuildingPreview; on valid click call main._place_building() which consumes inventory and instances. Never consume on click card only. Centralize "building placed" effects in main or land_claim. |
| **optimizations.md** | Event-driven perception, sticky targets, scheduled combat, optional Zone B; disable AOP when sleeping/far. | Already partly done (CombatScheduler, PerceptionArea). Add: target reselect only on enemy_entered/exited, ally_hit, target_died. For Zone B: when distance_to_player > threshold, run simplified combat tick or skip AOP. monitoring = false when sleeping/morale broken. |
| **Clan_Menu.md** | Clan menu at land claim: list members + info; emergency alert (horn) call all to defend; tabs: buildings (on/off), tasks; give orders (gather, defend, hostile, follow/raid). Inheritance: respawn as oldest son, oldest clansman, highest skill. | New UI scene ClanMenu; open from land claim (e.g. key or button). Data: land_claim.clan_brain.get_clan_members(), get_fighters(), ClaimBuildingIndex.get_buildings(claim). Tabs: Members (list + current task), Buildings (toggle production), Orders (icons → set meta or FSM override). Horn: call start_player_emergency_defend() + optional RPC. Inheritance: on player death, show choice; spawn as selected NPC (oldest son = filter babies by age, pick max; highest skill = sort by stat). |
| **joinclan.md** | Player without claim can join existing clan; later usurp leader and take over. | If player has no land_claim and enters claim radius: show "Join [ClanName]" prompt. On accept: set player clan_name, set player_owned = false for that claim (or "member" flag). Usurp: quest/condition (e.g. kill leader, or vote/event); transfer claim ownership to player, set player_owned = true. |
| **customflag.md** | Player-designed flag (32×64, 8 colors, no transparency). Render from pixel data to texture; use for claim and overlays. | Flag as PackedByteArray or Dictionary (32×64, 8 color indices). Editor: fork Piskel or simple grid; export to project format. In-game: Image.create_from_data(); ImageTexture; apply to Sprite2D on claim and optionally to character overlay. Save in save file or player profile. |
| **tutorial.md** | Lessons: 1) land claim, mate, food. 2) buildings, kids. 3) hunt. 4) raid defence. 5) raid. | TutorialManager autoload or scene; state machine (lesson 1..5). Each state: objectives (e.g. "Place land claim"), check conditions (claim placed), show hint, advance on complete. Optional: block certain actions until lesson done; or soft prompts only. |
| **NATURAL_MOVEMENT_IMPROVEMENTS.md** | Smoother follow (update target 0.3s, distance ±15px, angular drift); wild NPCs pause 1–3s, variable wander interval. | steering_agent or herd_state: follow target update timer 0.3s; ideal_distance += randf_range(-15,15); add small angle offset. wander_state: chance per frame to "pause" (set velocity 0) for 1–3s; wander target change interval 3–6s. |
| **reproductiontraits.md** | Traits/genes mixed and passed (dominant/recessive); more scientific/anthropological. | Trait or Gene resource: id, dominant/recessive, expression rule. On birth: for each trait pick from mother/father by allele; resolve phenotype. Store on NPC: genes: Array[GeneInstance]. UI/feedback: "Child has mother's eyes (recessive)." |
| **woman_production.md** | Work = sequence of Tasks; buildings publish Work Requests; Job = ordered task list (RimWorld-style). | Extend task_runner: Job can be "FetchWood → WorkAtOven → DropOff". Building has work_request (resource type, amount); job generator matches request to task chain. Woman/NPC pulls job from claim or building; executes tasks in order. |
| **animals.md** | Pack animals carry large amounts; craft pack from hide + wood. | New item "Pack" (hide + wood); equippable on sheep/goat (or new "pack_animal" type). Increase animal inventory slots when pack equipped; or add "pack_inventory" separate. NPCs can load/unload pack animal at claim. |
| **NPCupdate.md** | Large doc: NPC behavior, movement, combat, herd, FSM refinements. | Use as reference for state fixes, steering tweaks, and new states; implement in small PRs (e.g. one state at a time). |
| **combat_plan.md** | Combat refactor: windup/recovery, DetectionArea, Zone A/B, morale. | Already partially in place (CombatComponent, CombatScheduler). Remaining: Zone B when far from player; morale break (flee); optional client prediction. |
| **perception_rpc.md** | When to add RPC for perception: client prediction, debug UI, shared authority. | No code until multiplayer needs it; then sync PerceptionArea results or "detected_targets" via RPC when one of the listed conditions is true. |
| **grid_system.md** | Movement snaps to 64×64 grid; optional faint overlay. Free movement but characters snap to closest square. | SteeringAgent or movement: after computing position, snap to `floor(pos / 64) * 64 + Vector2(32, 32)`. Optional: draw GridMap or Line2D overlay (64 spacing); toggle in settings. |
| **more_items.md** | Expanded resources: nuts, roots, mushrooms, honey, flint/chert, sinew, furs; crafting chains and epic products. | Add ResourceType enum entries; new gatherable nodes (bush, cave, riverbank); recipes in craft_registry; optional "refining" building or state. Balance: respawn timers, drop tables. |
| **wepons and tools.md** | Stone cores → tools; clay shot for slings. | New recipe: stone_core → tool (knapping or simple craft). New item Sling + ClayShot; weapon type SLING with range and ammo. |
| **newworld.md** / **world_systems_implementation_plan.md** | World gen, biomes, chunks, visuals. | ChunkUtils already exists; extend with biome per chunk, terrain tiles, spawn rules. Optional shaders for day/night or water. |
| **ui.md** | UI standards and layouts. | Reference for new screens (Clan Menu, Tutorial); conform to UITheme, panel style. |
| **Stats.md** | Character stats (strength, intelligence, etc.). | Add StatsComponent or extend NPC; persist on save; feed into damage, gather speed, birth chance; display in character menu. |
| **128upgrade.md** | Redo all graphics at 128×128. | Art pipeline change: re-export sprites at 128; update AssetRegistry and scene scales; adjust camera/zoom if needed. |
| **lategame.md** | Governments, religions, trade. | High-level theme; would need new systems: government type (chiefdom, council), religion (shrine rituals, buffs), trade (between claims, caravans). Design before coding. |
| **future_buildings.md** / **futurebuildings.md** | Additional building ideas. | Add to building_registry and Building List when ready; same pattern as existing buildings (cost, woman slot, production_component). |
| **roadmap.md** | Phase 1–3 roadmap to beta. | Planning only; use to order CRITICAL_FIXES and feature work. |
| **main.md** | Main game mechanics and vision (long). | Reference doc; not a single feature—use for alignment. |
| **notes.md** | Dev notes (e.g. cleanup). | Ad-hoc; no direct code mapping. |
| **COMBAT_TESTING_GUIDE.md** / **COMBAT_IMPLEMENTATION_SUMMARY.md** | Combat test procedures and implementation summary. | Testing and documentation; run tests when changing combat. |
| **characergenerator.md** | Character generation (historical / design notes). | **Not** the active 2D pipeline; use `AssetRegistry` + art when adding NPC visuals. |

---

*Sources: gdd.md, main.md, hominids.md, traits.md, Buildings.md, items_guide.md, HERDING_SYSTEM_GUIDE.md, ai_clan_brain.md, phase1.md, phase2.md, earlygame.md, **guides/rts.md**, rtsguide.md, AgroGuide.md, GatherGuide.md, DragAndDropInventoryGuide.md, movement.md, SOSA.md, Art_Direction.md, village.md + scripts/ (main.gd, party_state.gd, herd_state.gd, formation_utils.gd, party_command_utils.gd, rts_formation_config.gd, fsm.gd, task_runner.gd, combat_scheduler.gd, combat_tick.gd, combat_component.gd, gather_job.gd, resource_index.gd, land_claim.gd, npc_config.gd, playtest_instrumentor.gd, project.godot)*
