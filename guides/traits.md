# Traits Reference

Canonical reference for stats, hominid classes, and traits.

---

## Base Stats (9)

Displayed in Character Menu, used by Stats component.

| Trait | Stat Property | Notes |
|-------|---------------|-------|
| Strength | `strength` | Melee damage, physical power |
| Intelligence | `intelligence` | Craft speed, tier progression |
| Endurance | `endurance` | Wound resistance, hunger depletion |
| Agility | `agility` | Speed, dodge, herd chance |
| Perception | `perception` | Detection range for resources/enemies |
| Social | `social` | Herding/mating success, clan morale |
| Pain Tolerance | `pain_tolerance` | Debuff duration, wound resistance |
| Carry Capacity | `carry_capacity` | Inventory/load limits |
| Bravery | `bravery` | 0.0–1.0, attack vs flee in combat |

**Source:** `character_menu_ui.gd` → `_get_traits_list()`. Stats component must expose matching property names.

---

## Hominid Classes (5)

Each hominid has 3–4 unique traits (stat buffs, behavior tweaks). Base stats 50/100, traits add +X% (editable). Visuals: slight sprite tweaks (e.g., Neanderthal stocky, Floresiensis small).

### 1. Homo sapiens
**Role:** Adaptable social leaders – good all-rounders for early clans.

| Trait | Effect |
|-------|--------|
| Learning | +20% Intelligence (faster tier progression, craft speed) |
| Social Strategist | +15% Social (better herding/mating success, +10% clan morale) |
| Adaptive | +10% Agility (+herd chance, dodge in combat) |

### 2. Neanderthal
**Role:** Tough warriors – tanky for defense/raids.

| Trait | Effect |
|-------|--------|
| Robust | +20% Strength, +15% Endurance (melee damage, wound resistance) |
| Pain Resistant | +25% Pain Tolerance (shorter debuff duration) |
| Hunter's Grit | +10% Aggression (higher attack vs flee chance) |

### 3. Heidelbergensis
**Role:** Sturdy workers – resource machines.

| Trait | Effect |
|-------|--------|
| Enduring Laborer | +20% Stamina, +15% Carry Capacity (longer trips, more loot) |
| Builder's Might | +10% Intelligence (faster build/craft) |
| Resilient | +10% Endurance (less hunger depletion) |

### 4. Denisovan
**Role:** Keen hunters – aggressive scouts.

| Trait | Effect |
|-------|--------|
| Sharp Senses | +20% Perception (longer detection range for resources/enemies) |
| Aggressive Predator | +15% Aggression (higher hunt/attack priority) |
| Nomad Endurance | +10% Pain Tolerance (resist wounds/debuffs) |

### 5. Floresiensis
**Role:** Agile swarmers – fast breeders.

| Trait | Effect |
|-------|--------|
| Swarm Instinct | +20% Social (better flocking/herding, +10% reproduction chance) |
| Nimble | +15% Agility (higher speed/dodge) |
| Compact | +10% Fertility (faster baby growth) |

---

## Hybridization Mechanic

- **Mixing Rule:** Babies inherit 50/50 traits from parents (e.g., sapiens + neanderthal = Learning + Robust, averaged stats).
- **Trait Inheritance:** Random 50% chance per trait from each parent (max 6 traits per NPC).
- **Stat Blending:** Average parent stats (e.g., sapiens 50 Intelligence + neanderthal 40 = 45 for baby).
- **Quality Tier Overlay:** Age-based tiers multiply hybrid stats (Flawed -20%, Legendary +60%).
- **Display:** Clan Menu shows "Hybrid: Sapiens 50% / Neanderthal 50%" + blended traits/icons.
- **Balancing:** Dev menu sliders for inheritance chance, max traits.

**Example:** Start sapiens → herd neanderthal woman → tough smart hybrids → dominate.

**Suggestions:** Trait mutation (1% chance for new random trait on birth). Hybrid art: blend sprites (e.g., sapiens-neanderthal = taller with heavy brow).
