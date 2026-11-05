# Perks (inherited traits)

**Status:** Locked **2026-11-04** with [future implementations/character_attributes.md](future%20implementations/character_attributes.md). **Build to these tables.** Code today: `NPCBase.traits` is `Array[String]`; bonuses are not applied yet.

**Director:** [director_locks_2026_10.md](director_locks_2026_10.md) §4 (cores) and §12 (perks).

Perks are **named inherited bonuses**. They modify **cores** or **derived statistics** (see character_attributes). They are not the eight cores themselves. **Bold**, **Timid**, **Crafty**, and similar **clan labels** come from averaged cores on the clan screen, not from this list.

---

## Rules

| Rule | Value |
|------|--------|
| Per person | At most **6** perks (`traits[]`). |
| At birth | Up to **3** species perks from the father’s species pool; hybrid parents roll **50%** per parent perk; **1%** mutation can add one perk from the **general pool**. |
| Bonus format | `+X%` multiplies that core or derived value by `(1 + X/100)` unless the row says **hook** or **context**. |
| **Hook** | Listed for design; uses a neutral multiplier until that system ships. |
| **Context** | Bonus or debuff only in the situation named (combat, on claim, hunting). |
| Clan trait | Same perk name on the **clan screen** when **weighted share** of clansmen with that perk ≥ **40%** (measure in play). High seats count extra: [clan_hierarchy.md](future%20implementations/clan_hierarchy.md). |
| Clan bonus cap | When a perk is active on the clan, apply its listed bonus **once**, capped at **+25%** even if almost every man has it. |
| Legacy raid floats | `raid_aggression`, `raid_risk_tolerance`, etc. in `clan_brain.gd` are **retired** when cores + perks ship; use **average Bravery core** and quorum perks instead. |

**Character menu:** **Born with** = eight cores (snapshot) + perk names. **Clan screen** = averaged cores + quorum perk list + emergent labels + buffs/debuffs.

---

## Species perks (15)

Each hominid contributes from its pool at founding and through fathers at birth.

### Homo sapiens — adaptable leaders

| Perk | Modifiers |
|------|-----------|
| **Learning** | Intelligence core **+20%** → learning speed, crafting efficiency |
| **Social Strategist** | Social core **+15%** → herding, storytelling, mating compatibility; **clan morale bar +10%** when this perk is a **clan trait** |
| **Adaptive** | Agility core **+10%** → movement, dodge, herding effectiveness |

### Neanderthal — tough fighters

| Perk | Modifiers |
|------|-----------|
| **Robust** | Strength **+20%**, Toughness **+15%** → melee damage, max health, pain tolerance derived |
| **Pain Resistant** | Pain tolerance derived **+25%** |
| **Hunter's Grit** | Aggression threshold derived **+10%** |

### Heidelbergensis — sturdy workers

| Perk | Modifiers |
|------|-----------|
| **Enduring Laborer** | Endurance **+20%**, carry capacity derived **+15%** |
| **Builder's Might** | Intelligence **+10%** → crafting efficiency, build tasks |
| **Resilient** | Endurance **+10%** → exhaustion resistance, stamina regen; hunger depletion **hook** −5% |

### Denisovan — keen hunters

| Perk | Modifiers |
|------|-----------|
| **Sharp Senses** | Perception **+20%** → detection radius, resource detection, threat detection |
| **Aggressive Predator** | Aggression threshold **+15%**; tracking effectiveness **hook +10%** |
| **Nomad Endurance** | Pain tolerance derived **+10%** |

### Floresiensis — agile, fast-growing

| Perk | Modifiers |
|------|-----------|
| **Swarm Instinct** | Social **+20%** → herding; mating compatibility **+10%**; reproduction chance **hook +10%** |
| **Nimble** | Agility **+15%** → movement, dodge, attack speed |
| **Compact** | Baby growth **hook +10%**; Toughness max health **−5%** (tradeoff) |

---

## General pool — v1 (12)

Any species can receive these from **hybrid overflow**, **mutation**, or future events. IDs match perk names in saves.

### Fight, raid, standoff

| Perk | Modifiers |
|------|-----------|
| **Protective** | Fear resistance **+15%**; knockback power **+5%** **context:** defending own claim; defend FSM priority nudge |
| **Territorial** | Patience **+10%** on own claim; aggression threshold **+15%** vs intruders on claim |
| **Raid Caller** | Stress tolerance **+10%**; raid volunteer weight **hook +15%** (still obeys **odds gate**) |
| **Skittish** | Bravery core **−10%**; fear resistance **−15%**; dodge chance **+5%** |
| **Berserker** | Melee damage **+10%** **context:** in combat; pain tolerance **−10%** **context:** in combat |

### Hunt, craft, social

| Perk | Modifiers |
|------|-----------|
| **Tracker** | Tracking effectiveness **hook +20%**; Perception **+5%** |
| **Ambusher** | Sneak effectiveness **hook +15%**; melee damage **+10%** **context:** ambush first hit |
| **Stone Knapper** | Crafting efficiency **+15%**; recipe discovery **hook +5%** |
| **Storykeeper** | Storytelling derived **+20%** → showing mood/tie nudge |
| **Herder's Voice** | Herding effectiveness **+20%** |
| **Hardy Gut** | Exhaustion resistance **+15%**; famine ladder **hook** one step softer |
| **Peacemaker** | Patience **+15%**; aggression threshold **−10%** |

---

## General pool — later (documented, not required for first perks pass)

| Perk | Modifiers |
|------|-----------|
| **Beast Slayer** | Melee damage vs animals **+15%**; threat detection **+5%** |
| **Patient Stalker** | Patience **+15%**; movement speed **−5%** **context:** hunting |
| **Pack Mule** | Carry capacity **+20%**; movement speed **−5%** when carry &gt; 80% |
| **Greedy** | Carry capacity **+10%**; raid loot share behavior **hook** (keeps more food) |
| **Mocking** | Storytelling **+10%** for displeasure/joke showings only; patience **−5%** |
| **Loyal** | Leadership influence **hook +10%**; ordered follow break **hook** slower |
| **Spirit-Touched** | Spirituality derived **+20%** |
| **Omen Reader** | Spirituality **+10%**; threat detection **+10%** |
| **Sacred Duty** | Spirituality **+15%**; Bravery **−5%** when refusing shrine task **hook** |
| **Guardian** | Fear resistance **+10%**; max health **+5%**; stronger defend quota lean when clan trait |
| **Survivalist** | Physical activity efficiency **+10%**; low-pantry stamina penalty **hook −10%** severity |

---

## Clan traits (quorum)

1. Recompute **eight core averages** on the brain (clansmen only; seats weighted).  
2. For each perk id, compute **weighted fraction** of clansmen who have it.  
3. If fraction ≥ **40%** (tune in play), add perk to **clan traits** and apply its bonus **once** (cap **+25%**).  
4. **Emergent labels** (Bold, Timid, Crafty, Pious, …): optional **2–4** labels from core averages on the clan screen only—not stored perks. Thresholds: measure in play; do not duplicate quorum perks.

**Do not** list moodles, feud shame, or relic buffs as perks—they stay in **buffs/debuffs**.

---

## Hybridization (unchanged intent)

- **Cores:** average of parents ± small mutation at birth.  
- **Perks:** each parent perk **50%** chance to pass; max **6** on child.  
- **Species pool:** child’s species (hybrid rule from [genetics.md](genetics.md)) sets which **species perks** can roll at birth.  
- **Quality tier overlay** (Flawed / Legendary age tiers): still multiplies effective cores when that system is active—does not add new perk names.

**Example:** Sapiens founder + Neanderthal bloodline → Learning + Robust on sons → at **40%** roster share, clan trait **Learning** applies once to clan crafting bias.

---

## Code pointers

| Piece | Today |
|-------|--------|
| `scripts/npc/npc_base.gd` | `traits: Array[String]`, `has_trait(name)` |
| `scripts/npc/stats.gd` | Pre-spec cores; perk application **pending** |
| `scripts/ai/clan_brain.gd` | Legacy `raid_*` personality floats; replace with averages + quorum |

Implement **one perk resolver**: `apply_perk_modifiers(base_core_or_derived, perk_ids[], context) -> float`.
