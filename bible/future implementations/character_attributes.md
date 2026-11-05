# Character attributes (build spec)

**Status:** Director decisions **2026-11-04**; core #7 renamed **Constitution → Toughness** **2026-11-05**. **Build to this spec.** Not fully implemented in code today (`stats.gd` and `character_menu_ui.gd` still use the older nine-stat shape).
**Locks:** [director_locks_2026_10.md](../director_locks_2026_10.md) §4 (updated same day). **UI:** [UI.md](../UI.md) § Character menu.

Each person has **eight core attributes** stored at birth and allowed to drift slowly where noted. Each core feeds **four derived statistics** used by gameplay. Derived values are **computed in code**. They are **not** separate bars on the character sheet unless a tooltip or combat panel needs one.

Inherited **traits[]** (perks) and **genes** modify cores or derived values. **Locked perk catalog:** [traits.md](../traits.md) (15 species + 12 v1 general + later pool). Clan **quorum traits** use the same perk ids. Perk lines that named old stats map through the bridge table below.

---

## What the player sees (character menu)

Five ideas, five places. Do not mix them on one pile of bars.

| Section | What it is |
|---------|------------|
| **Born with** | Birth snapshot of the **eight cores**, genes (compact), inherited **traits[]**. |
| **Learned** | **Skills** and craft unlocks. |
| **Now** | Carrying, job/order, moodles, buffs/debuffs, wounds when relevant. Vitals (health, food, water) only when hurt, starving, or thirsty. |
| **Under pressure** | Shown in combat or right after: one or two **computed** reads (e.g. nerve in this fight, likely to break). Not thirty-two derived bars. |
| **Life** | **Story** tab: life beats. **Body**: scars. Summary **tallies** and **ties**. |

Clan traits, feud, and hierarchy stay on the **clan screen**, not on every person.

---

## The eight cores

Scale for design: **0–100** at birth unless a trait shifts it. Parent average ± small mutation at birth. Life events may drift **Bravery** and optionally other cores where noted in [story_data.md](../story_data.md).

### 1. Strength

Physical power and force.

| Derived | Effect |
|---------|--------|
| Melee damage | Physical attack damage |
| Carry capacity | Maximum carrying weight (**not** a separate core) |
| Knockback power | Ability to stagger or push enemies |
| Physical task efficiency | Effectiveness on strength-based tasks (build, chop, haul) |

### 2. Intelligence

Learning, knowledge, and cognitive ability.

| Derived | Effect |
|---------|--------|
| Learning speed | Rate of skill development |
| Crafting efficiency | Craft time and material efficiency |
| Spirituality | Shrine and shaman rites only in **v1** ([the_land.md](../the_land.md) / medic vs shaman split in director §2) |
| Recipe discovery | Chance to discover new recipes — **hook only** until recipe discovery exists |

### 3. Endurance

Ability to sustain physical activity.

| Derived | Effect |
|---------|--------|
| Maximum stamina | Exertion capacity |
| Stamina regeneration | Recovery after exertion |
| Exhaustion resistance | Resistance to fatigue buildup |
| Physical activity efficiency | Energy use during physical tasks |

### 4. Agility

Speed, coordination, and movement.

| Derived | Effect |
|---------|--------|
| Movement speed | Walk and run speed |
| Attack speed | Melee attack cadence |
| Dodge chance | Chance to evade attacks |
| Sneak effectiveness | Approach undetected, ambush — **hook** until hunt stealth is built |

### 5. Perception

Awareness and sensory ability.

| Derived | Effect |
|---------|--------|
| Detection radius | Distance at which entities are noticed |
| Resource detection | Spotting gatherables and hunt prey |
| Tracking effectiveness | Following tracks — **hook** until tracking is built |
| Threat detection | Notice danger; feeds calls and awareness, not a second UI bar |

### 6. Social

Interaction and relationships.

| Derived | Effect |
|---------|--------|
| Herding effectiveness | Control herdables and women influence |
| Storytelling | Player and NPC **showings** (praise, joke, dominance, displeasure): mood and tie nudge size in **v1** ([story_data.md](../story_data.md) §9) |
| Mating compatibility | Reproductive social pairing |
| Leadership influence | Nudge to follow orders and volunteer — **hook**; hierarchy **seats** still weigh clan average separately |

### 7. Toughness

Physical resilience and bodily health. (Locked name **2026-11-05**; was *Constitution* in the 2026-11-04 draft.)

| Derived | Effect |
|---------|--------|
| Maximum health | Total health capacity |
| Pain tolerance | Shorter debuffs, tougher through wounds (**replaces** old standalone pain_tolerance core) |
| Recovery rate | Speed of physical healing |
| Exhaustion sickness | **Deferred.** Slot reserved; no disease sim in v1. Do not show a fourth Toughness-derived bar until illness exists |

### 8. Bravery

Emotional disposition and nerve over a **life** (core #8). Not a separate “temperament” name.

| Derived | Effect |
|---------|--------|
| Aggression threshold | How easily they escalate to fight |
| Patience | Tolerance before reacting to provocation (standoff ladder) |
| Fear resistance | Resistance to panic; shifts personal **flight line** |
| Stress tolerance | Resistance to psychological stress and break pressure |

**Fight or flight (locked):** Player **Fight** and **Flight** vs technical **`agro_meter`**. Full glossary: [fight_or_flight.md](../fight_or_flight.md). In combat the sim runs **`agro_meter`** (toward **Fight** at max + red **`!!!`**) and the **morale bar** (toward **Flight** + yellow **`!!`**). Bravery core + derived + orders tune both. Not a ninth core. Show **under pressure**, not Born with. Persistence: [story_data.md](../story_data.md) §13.

**Life drift on Bravery core:** Kills raise it slowly; scars and lost kin lower it; a sticking **times picked on** tally can lower it. One shove does not. Showings may nudge fight state; they do not rewrite the core in one act.

**Clan raid appetite:** Average **Bravery core** (and bold volunteers) among fighters, tilted by leader — replaces `raid_temper`. See [raid.md](../raid.md).

---

## v1 derived stats (must work when attributes ship)

| Derived | Core |
|---------|------|
| Melee damage, carry capacity, physical task efficiency | Strength |
| Learning speed, crafting efficiency, spirituality (shrine/rites) | Intelligence |
| Max stamina, regen, exhaustion resistance, activity efficiency | Endurance |
| Movement speed, attack speed, dodge | Agility |
| Detection radius, resource detection, threat detection | Perception |
| Herding, storytelling (showings), mating compatibility | Social |
| Max health, pain tolerance, recovery rate | Toughness |
| Aggression threshold, patience, fear resistance, stress tolerance | Bravery |

Everything marked **hook** or **deferred** above may return a neutral multiplier until its system exists.

---

## Bridge: old stat → new home

Use when refactoring `stats.gd`, saves, and UI.

| Old (nine-stat era) | New |
|---------------------|-----|
| `strength` | Core **Strength** |
| `intelligence` | Core **Intelligence** |
| `endurance` | Core **Endurance** |
| `agility` | Core **Agility** |
| `perception` | Core **Perception** |
| `social` | Core **Social** |
| `pain_tolerance` | **Toughness** → derived **Pain tolerance** |
| `constitution` (2026-11-04 draft name) | Core **Toughness** — use `toughness` in new saves/code |
| `carry_capacity` | **Strength** → derived **Carry capacity** |
| `bravery` (0–1 on `npc_base`) | Core **Bravery** (rescale to 0–100 in new code) |
| `aggression` on Stats | Retire into Bravery derived; not a core |
| `agro_meter` | Technical fill toward player **Fight**; see [fight_or_flight.md](../fight_or_flight.md) |
| `morale_bar` / nerve | Player **Flight** side of fight or flight; [morale_bar_flight.md](morale_bar_flight.md) |
| Stamina resource | **Endurance** derived; still a runtime pool |

**ClanBrain average:** Average the **eight cores** across clansmen only. Do not average thirty-two derived values. Hierarchy seat weight still applies on top ([clan_hierarchy.md](clan_hierarchy.md)).

---

## Formulas

**Not chosen in docs.** Each derived stat is a function of core, traits, gear, wounds, and context. Measure coefficients in play; do not guess numbers in the bible.

---

## Code today

| Piece | State |
|-------|--------|
| `scripts/npc/stats.gd` | Old fields including separate carry, pain_tolerance, aggression |
| `scripts/npc/npc_base.gd` | `bravery` 0–1 |
| `scripts/ui/character_menu_ui.gd` | Eight born-with rows + bravery/agro bars (pre-spec UI) |
| `scripts/combat/morale_bar.gd` | Nerve bar built; align with Bravery core when attributes ship |

Implement **server-side** cores + derived getters first; then UI Born-with eight rows; then migrate saves with the bridge table.
