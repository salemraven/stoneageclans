# Fight or Flight System - Unified Combat & Aggression Guide

## Overview

The **Fight or Flight (FoF)** system determines whether NPCs (cavemen/clansmen) choose to fight or flee when threatened. This system integrates with the melee combat system and aggression (agro) mechanics to create dynamic, personality-driven NPC behavior.

**Key Concepts:**
- NPCs evaluate threats and decide: **Fight** (agro/combat) or **Flight** (flee/hide)
- Decision based on personality traits, situation, and calculated odds
- Fight = Enter combat state when agro_meter >= 70.0
- Flight = Retreat to land claim while hiding behind environmental sprites (planned)
- FoF will depend largely on proximity to other clan members, so we can simulate running away when outnumbered. something that would naturally happen in the stoneage

**Current Status:** ✅ Combat system implemented, Flight system planned

---

## Part 1: Combat System Philosophy (Current Implementation)

### Core Philosophy: Event-Driven, Agro-Based Combat

The current combat system is **event-driven** and **agro-meter based**. NPCs enter combat automatically when their `agro_meter` reaches 70.0 or higher, triggered primarily by land claim intrusion.

**Key Principles:**
1. **Agro Meter Drives Combat**: Simple threshold system - `agro_meter >= 70.0` = combat entry
2. **Event-Driven Timing**: Combat uses `CombatScheduler` for precise windup/recovery timing (no per-frame polling)
3. **Spatial Detection**: `DetectionArea` uses Area2D signals for efficient enemy detection (60x performance improvement)
4. **Tactical Positioning**: Attack arcs (90° cone) require proper positioning - attacks can whiff
5. **Stagger System**: Successful hits interrupt enemy windup attacks, creating tactical depth

### Combat Entry: Agro Meter Threshold

**Entry Condition:** `agro_meter >= 70.0`

**Agro Meter Range:** 0.0 to 100.0

**How Agro Meter Increases:**
- **Land Claim Intrusion**: 50.0 per second (fast - fills from 0 to 70 in 1.4 seconds)
- **Direct Attack**: Instant 100.0 (full agro)
- **Natural Decay**: 5.0 per second when not in combat (if agro_meter < 100.0)

**Combat State Priority:** 12.0 (very high, overrides most states)

### Land Claim Defense (Primary Trigger) ✅ IMPLEMENTED

**When:** An enemy (caveman/clansmen from different clan, or player) enters the NPC's land claim radius  
**Action:** `agro_meter` increases rapidly at 50.0 per second  
**Result:** When `agro_meter >= 70.0`, NPC enters combat state

**Conditions:**
- NPC must have a land claim placed (`clan_name != ""`)
- Enemy must be inside land claim radius (400px default)
- Enemy must be from different clan (or player)
- Player and clansmen can freely enter enemy land claims (raiding mechanics)

**Implementation:**
- `_check_land_claim_intrusion()` in `npc_base.gd` detects intruders
- Rapidly increases `agro_meter` (50/sec) when intruders detected
- Sets `combat_target` to nearest intruder when `agro_meter >= 70.0`

**What It Protects:**
- **Land Claim Territory:** Base, buildings, resources
- **Herded NPCs:** Any wild NPCs (women, sheep, goats) following or inside land claim
- **Clan Members:** NPCs that have joined the clan

#### 2. Enemy Near Land Claim 🔮 PLANNED
**When:** An enemy approaches within a certain distance of the land claim (but not yet inside)  
**Priority:** 14.0 (high, but below direct intrusion)  
**Action:** NPC enters agro state preemptively  
**Agro Level:** Starts at 5.0, increases faster as enemy gets closer

**Conditions:**
- Enemy within "near land claim" radius (e.g., 600px from land claim center)
- Enemy moving toward land claim
- NPC has land claim and is nearby

**Purpose:** Proactive defense before enemy reaches land claim

#### 3. Herd Animal Stolen 🔮 PLANNED
**When:** A herded animal (sheep, goat) that was following the NPC stops following and switches to another leader  
**Priority:** 13.0 (high priority)  
**Action:** NPC enters agro state, targets the thief  
**Agro Level:** Starts at 20.0 (higher initial agro for theft)

**Conditions:**
- NPC was leading a herd animal
- Animal stops following NPC
- Animal starts following another caveman/clansmen
- NPC detects the theft (within detection range)

**Purpose:** Defend herd resources from theft

#### 4. Enemy in Area of Perception (AoP) 🔮 PLANNED
**When:** An enemy enters the NPC's Area of Perception (AoP)  
**Priority:** Dynamic (based on agro level)  
**Action:** Agro level increases over time while enemy remains in AoP  
**Agro Level:** Increases at accelerating rate the longer enemy stays in AoP

**Agro Increase Formula:**
```gdscript
# Base increase rate
agro_increase_rate = 5.0 per second

# Acceleration based on time in AoP
time_in_aop = current_time - enemy_entered_aop_time
acceleration_factor = 1.0 + (time_in_aop / 10.0)  # +10% per 10 seconds
actual_increase = agro_increase_rate * acceleration_factor

# Example:
# 0-10 seconds: 5.0/sec
# 10-20 seconds: 5.5/sec
# 20-30 seconds: 6.0/sec
# etc.
```

**Conditions:**
- Enemy enters AoP radius (varies by NPC perception stat)
- Enemy remains in AoP
- NPC is not already in full agro (agro_level < 100.0)

**Purpose:** Gradual escalation - longer enemy stays, more aggressive NPC becomes

#### 5. Direct Attack (Full Agro) ✅ IMMEDIATE
**When:** NPC is directly attacked (takes damage from enemy)  
**Priority:** 15.0 (maximum)  
**Action:** Agro immediately goes to 100.0 (full agro)  
**Agro Level:** 100.0 (maximum)

**Conditions:**
- NPC takes damage from enemy attack
- Enemy is identified as attacker
- No cooldown or delay

**Purpose:** Immediate full agro when directly threatened with violence

### Agro Level System

**Agro Level Range:** 0.0 to 100.0

**Agro Level Effects:**
- **0-29:** No agro (normal behavior)
- **30-69:** Low agro (aware of threat, but not yet hostile)
- **70-99:** High agro (hostile, shows "!!!" indicator, ready to fight)
- **100:** Full agro (maximum aggression, combat priority)

**Agro Increase Rates:**
- **Enemy in land claim:** 10.0 per second
- **Enemy near land claim:** 5.0 per second (increases as enemy approaches)
- **Enemy in AoP:** 5.0 per second (with acceleration over time)
- **Herd stolen:** Instant +20.0, then 8.0 per second
- **Direct attack:** Instant 100.0 (full agro)

**Agro Decrease:**
- **Enemy leaves land claim:** -20.0 per second until 0.0
- **Enemy leaves AoP:** -5.0 per second until 0.0
- **No threat detected:** -2.0 per second until 0.0

**Visual Indicators:**
- **Agro Level 70-99:** "!!!" indicator appears above NPC (red text)
- **Agro Level 100:** "!!!" indicator + combat state active

### Agro State Behavior

**When Agro Triggers:**
1. **Detect Threat:** NPC detects enemy via one of the trigger conditions
2. **Set Agro Target:** Enemy becomes `agro_target`
3. **Enter Agro State:** FSM transitions to `agro` state (priority 15.0)
4. **Combat Ready:** If agro_level >= 70.0, NPC is ready for combat
5. **Combat Active:** If agro_level == 100.0, NPC enters combat state

**Agro Behavior:**
- Move toward agro target
- Push/chase target away from land claim
- If in combat range and agro_level >= 70.0, engage in melee combat
- Maintain agro until threat is eliminated or leaves range

**Agro Persistence:**
- Agro continues while threat remains
- Agro drops when threat leaves land claim/AoP
- Agro clears immediately when threat is eliminated
- No cooldown period (agro clears when conditions no longer met)

---

## Part 2: Flight System

### Flight Decision

When an NPC meets the flee condition (agro_meter == 0 AND bravery == 0), they attempt to retreat to safety rather than fight.

### Flight Behavior

**Primary Goal:** Reach land claim (safe zone) where NPC is defended by clansmen

**Flight Path:**
1. **Calculate Path:** Determine path from current position to land claim center
2. **Identify Hiding Spots:** Find resource nodes (trees, boulders, berry bushes) along path
3. **Move to Hiding Spots:** Navigate to each hiding spot in sequence
4. **Hide at Spots:** Stop and "hide" for 1-2 seconds at each resource node
5. **Continue to Next:** Move to next hiding spot, repeat until reaching land claim
6. **Reach Safety:** Once inside land claim, flight ends (safe from threat)

### Hiding Mechanics

**Hiding Spots:**
- **Trees:** Large sprites that provide cover
- **Boulders:** Rock formations that block line of sight
- **Berry Bushes:** Dense vegetation that provides concealment

**Hiding Behavior:**
- NPC moves to same position as resource node (overlaps sprite)
- NPC stops movement for 1-2 seconds (simulating hiding)
- During hide, NPC is considered "hidden" (enemy may lose track)
- After hide duration, NPC moves to next hiding spot

**Hiding Duration:**
- **Base Duration:** 1.5 seconds per hiding spot
- **Random Variation:** ±0.5 seconds (1.0 to 2.0 seconds)
- **Threat Proximity Modifier:** If enemy very close (<100px), reduce hide time to 0.5-1.0 seconds

**Hiding Spot Selection:**
- Find all resource nodes (trees, boulders, berry bushes) within flight path
- Filter by distance: prefer nodes 200-400px apart (not too close, not too far)
- Prioritize nodes that provide better cover (trees > boulders > berry bushes)
- Select sequence of 3-5 hiding spots along path to land claim

### Flight State Priority

**Priority:** 11.5 (high, but below combat/agro)

**Flight vs Other States:**
- **Flight (11.5)** < **Combat (12.0)** < **Agro (15.0)**
- Flight can be interrupted by combat if enemy catches up
- Flight takes priority over gather, deposit, herd (survival priority)

### Flight Conditions

**When Flight Triggers:**
1. **Flee Condition Met:** agro_meter == 0 AND bravery == 0 (both must be exactly 0)
2. **Threat Detected:** Enemy in AoP, near land claim, or in land claim (but agro meter is 0)
3. **NPC Not in Combat:** NPC is not already engaged in melee (agro_meter < 70)
4. **Land Claim Available:** NPC has a land claim to retreat to

**Flight Ends When:**
- NPC reaches land claim (safe zone)
- Threat is eliminated (enemy dies or leaves)
- NPC is caught and forced into combat (enemy gets too close)
- NPC re-rolls FoF and chooses "fight" instead

### Flight Visual Indicators

**Flight State:**
- NPC moves faster than normal (fleeing speed)
- NPC path shows movement toward land claim
- Optional: Visual indicator showing NPC is fleeing (e.g., "🏃" or different sprite animation)

**Hiding State:**
- NPC stops at resource node position
- NPC sprite overlaps with resource sprite (appears hidden)
- Optional: NPC sprite becomes slightly transparent or changes color while hiding

---

## Part 3: Agro Meter & Bravery System

### Simplified Behavior System

NPCs use **two values** to determine behavior: **Agro Meter** and **Bravery**. This creates a simple, predictable system without random rolls.

**Behavior Rules:**
- **Combat State:** When agro meter >= 70 → NPC attacks/combats (regardless of bravery)
- **Flee State:** When agro meter == 0 AND bravery == 0 → NPC flees to land claim
- **Defensive/Neutral State:** All other combinations → NPC is aware but not fully committed

**Key Advantage:** Simple AND condition for fleeing - both values must be zero. No complex thresholds or random rolls.

### Agro Meter System

**Agro Meter Range:** 0.0 to 100.0

**Behavior Conditions:**
- **agro_meter >= 70:** Combat state (NPC attacks enemy)
- **agro_meter == 0 AND bravery == 0:** Flee state (NPC retreats to land claim)
- **All other values:** Defensive/neutral state (NPC aware but not committed)

**How It Works:**
1. Threat detected → Agro meter starts increasing (from 25% base)
2. Meter rises/falls continuously based on circumstances
3. Bravery influences agro meter rate (multiplier effect)
4. When agro >= 70 → Enter combat (regardless of bravery)
5. When bravery hits 0 → Agro automatically drops to 0
6. When agro == 0 AND bravery == 0 → Enter flee state
7. Otherwise → Stay in defensive/neutral state

### Agro Meter Rate Calculation

The agro meter changes at a **rate per second** based on multiple factors. Bravery is the primary modifier that affects how fast the meter changes.

```gdscript
# Base increase rate (when threat present)
var base_increase_rate = 5.0  # Per second

# Bravery modifier (0.0 = no bravery, 1.0 = fearless)
var bravery = personality_traits.get("bravery", 0.5)
var bravery_multiplier = 0.5 + (bravery * 1.0)  # Range: 0.5x to 1.5x
# Low bravery (0.0): 0.5x multiplier (slower increase, faster decrease)
# Balanced (0.5): 1.0x multiplier (normal rate)
# High bravery (1.0): 1.5x multiplier (faster increase, slower decrease)

# Situational rate modifiers (additive to base rate)
var situational_modifier = 0.0
situational_modifier += herd_protection_rate      # +0.0 to +3.0 (based on herd size)
situational_modifier += resource_value_rate        # +0.0 to +2.0 (based on land claim resources)
situational_modifier += health_rate                # -3.0 to +2.0 (based on current HP)
situational_modifier += relative_strength_rate     # -3.0 to +3.0 (based on strength comparison)
situational_modifier += distance_to_claim_rate     # -1.0 to +2.0 (based on proximity to land claim)
situational_modifier += clan_member_proximity_rate  # -5.0 to +4.0 (based on allies vs enemies nearby)
situational_modifier += resource_scarcity_rate     # +0.0 to +1.5 (based on available resources)
situational_modifier += resource_competition_rate   # +0.0 to +2.0 (when competing for same resource)

# Additional personality trait modifiers
situational_modifier += territorial_modifier       # +0.0 to +2.0 (when defending land claim)
situational_modifier += protective_modifier         # +0.0 to +2.0 (when defending herd)
situational_modifier += greedy_modifier            # +0.0 to +1.5 (when resources threatened)

# Final rate calculation
var total_rate = base_increase_rate + situational_modifier

# Apply bravery multiplier
# For positive rates (increasing): multiply
# For negative rates (decreasing): divide (so high bravery decreases slower, low bravery decreases faster)
if total_rate >= 0:
    total_rate = total_rate * bravery_multiplier  # Increase faster if brave
else:
    total_rate = total_rate / bravery_multiplier  # Decrease slower if brave

# Apply to agro meter
agro_meter += total_rate * delta  # delta = time since last update
agro_meter = clamp(agro_meter, 0.0, 100.0)

# Critical: If bravery hits 0, force agro to 0
if bravery <= 0.0:
    bravery = 0.0
    agro_meter = 0.0  # Automatic agro reset when bravery is 0
```

**Bravery Influence:**
- **High Bravery (0.7-1.0):** Meter increases faster when threatened, decreases slower when safe
  - **Increase:** Base rate 5.0/sec → Brave NPC gets 7.5/sec (1.5x multiplier)
  - **Decrease:** Base rate -5.0/sec → Brave NPC gets -3.3/sec (divide by 1.5x = slower decrease)
  - Result: Reaches combat threshold (70) faster, stays in combat longer
- **Low Bravery (0.0-0.3):** Meter increases slower when threatened, decreases faster when safe
  - **Increase:** Base rate 5.0/sec → Low bravery NPC gets 2.5/sec (0.5x multiplier)
  - **Decrease:** Base rate -5.0/sec → Low bravery NPC gets -10.0/sec (divide by 0.5x = faster decrease)
  - Result: Takes longer to reach combat threshold, flees sooner when threat lessens
- **Balanced Bravery (0.4-0.6):** Normal rates, responds to situation

**Key Insight:** Bravery doesn't change the thresholds (70 = combat, 30 = flee), it changes **how fast** the meter moves toward those thresholds.

**Bravery Multiplier Application:**
- **For positive rates (meter increasing):** `final_rate = base_rate * bravery_multiplier`
- **For negative rates (meter decreasing):** `final_rate = base_rate / bravery_multiplier`
  - This ensures high bravery NPCs decrease slower (stay aggressive longer)
  - And low bravery NPCs decrease faster (flee sooner)

### Dynamic Bravery System

**Bravery Range:** 0.0 to 1.0

**Key Rule:** When bravery reaches 0.0, agro meter automatically drops to 0.0 as well. This makes the flee condition (`agro == 0 AND bravery == 0`) achievable.

**Additional Personality Traits:**

Beyond bravery, NPCs can have additional personality traits that influence behavior:

**Territorial Trait (0.0-1.0):**
- **Effect on AOA:** Increases Area of Agro size (+50px to +150px)
- **Agro Rate Modifier:** +0.5 to +2.0/sec when defending land claim
- **Purpose:** NPCs with high territorial trait are more defensive of their territory
- **Example:** Territorial NPC (0.8) has larger AOA and faster agro increase when defending land claim

**Protective Trait (0.0-1.0):**
- **Effect:** Increases agro rate when defending herd (+0.5 to +2.0/sec)
- **Purpose:** NPCs with high protective trait defend their herd more aggressively
- **Example:** Protective NPC (0.9) has +1.8/sec agro rate when herd is threatened

**Greedy Trait (0.0-1.0):**
- **Effect:** Increases agro rate when valuable resources threatened (+0.3 to +1.5/sec)
- **Purpose:** NPCs with high greedy trait fight harder for resources
- **Example:** Greedy NPC (0.7) has +1.05/sec agro rate when resources are threatened

**Survivalist Trait (0.0-1.0):**
- **Effect:** Increases bravery decrease rate when low health (multiplier 1.2x to 1.5x)
- **Purpose:** NPCs with high survivalist trait flee sooner when injured (prioritize survival)
- **Example:** Survivalist NPC (0.8) has 1.4x multiplier to bravery decrease when health < 30%

**Trait Integration:**
```gdscript
# Add to situational modifiers
var territorial_modifier = personality_traits.get("territorial", 0.5) * 2.0  # +0.0 to +2.0/sec when defending land claim
var protective_modifier = personality_traits.get("protective", 0.5) * 2.0  # +0.0 to +2.0/sec when defending herd
var greedy_modifier = personality_traits.get("greedy", 0.5) * 1.5  # +0.0 to +1.5/sec when resources threatened
var survivalist_multiplier = 1.0 + (personality_traits.get("survivalist", 0.5) * 0.5)  # 1.0x to 1.5x multiplier to bravery decrease when low health
```

**Bravery is Dynamic:**
- Starts at base value (from personality traits, inherited from parents)
- Changes during gameplay based on circumstances
- Can decrease when: taking damage, outnumbered, allies die, health is low
- Can increase when: allies nearby, winning fights, safe in land claim

**Bravery Decrease Events:**

1. **Taking Damage (Big Chunks):**
   - When NPC takes damage in combat
   - Decrease: -0.1 to -0.3 per hit (based on damage amount)
   - Example: Taking 20 damage → -0.2 bravery
   - Example: Taking 50 damage → -0.3 bravery
   - **Result:** Sustained damage quickly reduces bravery

2. **Outnumbered:**
   - When more enemies than allies in AoP
   - Decrease rate: -0.05 to -0.1 per second while outnumbered
   - Example: 1 ally vs 3 enemies → -0.1/sec
   - **Result:** Bravery drops over time when outnumbered

3. **Allies Die Nearby:**
   - When ally (same clan) dies within AoP
   - Instant decrease: -0.2 to -0.4 per ally death
   - Example: 2 allies die → -0.6 bravery total
   - **Result:** Witnessing ally deaths reduces bravery significantly

4. **Low Health:**
   - When health drops below thresholds
   - Decrease rate: -0.02 to -0.05 per second when health < 30%
   - Example: Health at 20% → -0.05/sec bravery decrease
   - **Result:** Low health makes NPC more cautious

**Bravery Increase Events:**

1. **Allies Nearby:**
   - When more allies than enemies in AoP
   - Increase rate: +0.02 to +0.05 per second while allies nearby
   - Example: 3 allies vs 1 enemy → +0.05/sec
   - **Result:** Safety in numbers increases bravery

2. **Winning Fights (Trait Evolution):**
   - When enemy takes significant damage or dies
   - Instant increase: +0.05 to +0.15 per enemy defeated (confidence boost)
   - **Result:** Success in combat boosts confidence
   - **Long-term:** NPCs that win fights become more confident over time

3. **Successful Herd Defense:**
   - When successfully defending herd from intruder
   - Instant increase: +0.02 to +0.1 (protective success)
   - **Result:** Successful defense increases confidence

4. **Safe in Land Claim:**
   - When inside own land claim with no threats
   - Increase rate: +0.01 per second (slow recovery)
   - **Result:** Being safe allows bravery to recover gradually

**Trait Evolution from Combat:**
- **Win Fight (Enemy Defeated):** +0.05 to +0.15 bravery (confidence boost)
- **Lose Fight (Take Significant Damage):** -0.1 to -0.3 bravery (fear increase)
- **Successful Herd Defense:** +0.02 to +0.1 bravery (protective success)
- **Failed Herd Defense (Herd Stolen):** -0.1 to -0.2 bravery (failure)
- **Repeated Victories:** NPCs become more confident (higher base bravery over time)
- **Repeated Failures:** NPCs become more cautious (lower base bravery over time)

**Bravery Clamping:**
- Bravery is clamped to 0.0-1.0 range
- Cannot go below 0.0 or above 1.0
- Base value acts as a "resting point" that bravery tends toward when safe
- **Trait Evolution:** Base bravery can slowly shift based on combat experiences (long-term learning)

**Critical Rule - Bravery to 0 Forces Agro to 0:**
```gdscript
# When bravery hits 0, agro automatically goes to 0
if bravery <= 0.0:
    bravery = 0.0
    agro_meter = 0.0  # Force agro to 0
    # Now meets flee condition: agro == 0 AND bravery == 0
```

**How It Works:**
1. NPC starts with base bravery (e.g., 0.7)
2. Takes damage → Bravery decreases (e.g., 0.7 → 0.5)
3. More damage → Bravery continues decreasing (0.5 → 0.3 → 0.1)
4. Bravery hits 0 → Agro automatically drops to 0
5. Now meets flee condition → NPC flees to land claim

**Example Flow:**
- NPC with 0.8 bravery, 70 agro (in combat)
- Takes 30 damage → Bravery: 0.8 → 0.5 (-0.3)
- Takes 20 more damage → Bravery: 0.5 → 0.3 (-0.2)
- Ally dies nearby → Bravery: 0.3 → 0.1 (-0.2)
- Takes 10 more damage → Bravery: 0.1 → 0.0 (-0.1)
- **Bravery hits 0 → Agro automatically: 70 → 0.0**
- **Flee condition met (agro == 0 AND bravery == 0) → NPC flees**

### Situational Rate Modifiers

These modifiers affect the **rate** at which the agro meter increases/decreases, not a roll chance.

#### 1. Herd Protection Rate (+0.0 to +3.0 per second)
- **No herd:** +0.0/sec
- **Small herd (1-2):** +1.0/sec
- **Medium herd (3-4):** +2.0/sec
- **Large herd (5+):** +3.0/sec
- **Reason:** More to lose, meter rises faster when herd threatened

#### 2. Resource Value Rate (+0.0 to +2.0 per second)
- **Land claim has <10 of each resource:** +0.0/sec
- **Land claim has 10-19 of each:** +1.0/sec
- **Land claim has 20+ of each:** +2.0/sec
- **Reason:** More invested, meter rises faster when resources threatened

#### 3. Health Rate (-3.0 to +2.0 per second)
- **Health >80%:** +2.0/sec
- **Health 50-80%:** +0.0/sec
- **Health 30-50%:** -1.0/sec
- **Health <30%:** -3.0/sec (meter decreases faster, encourages flight)
- **Reason:** Low health = meter decreases faster, NPC flees sooner

#### 4. Relative Strength Rate (-3.0 to +3.0 per second)
- **Much stronger than enemy:** +3.0/sec
- **Slightly stronger:** +2.0/sec
- **Equal strength:** +0.0/sec
- **Slightly weaker:** -1.0/sec
- **Much weaker:** -3.0/sec (meter decreases, encourages flight)
- **Reason:** Confident when stronger (meter rises), cautious when weaker (meter falls)

#### 5. Distance to Land Claim Rate (-1.0 to +2.0 per second)
- **Inside land claim:** +2.0/sec (defending home, meter rises faster)
- **Near land claim (<200px):** +1.0/sec
- **Far from land claim (>500px):** -1.0/sec (meter decreases, less defensive)
- **Reason:** More defensive when closer to home

#### 6. Clan Member Proximity Rate (-5.0 to +4.0 per second) ⭐ KEY MODIFIER
**Purpose:** Simulates natural stone age behavior - meter rises faster with allies, decreases faster when outnumbered

**Calculation:**
- Count allies (same clan) within AoP radius
- Count enemies (different clan) within same radius
- Compare: `allies_count vs enemies_count`

**Rate Values:**
- **Outnumbered (more enemies than allies):** -3.0 to -5.0/sec (meter decreases rapidly)
  - Example: 1 ally vs 3 enemies = -4.0/sec
  - Example: 0 allies vs 2 enemies = -5.0/sec
  - Result: Meter drops toward flee threshold (30)
- **Even numbers (equal allies and enemies):** -1.0 to +1.0/sec (slight modifier)
  - Example: 2 allies vs 2 enemies = +0.0/sec
- **Allies nearby (more allies than enemies):** +2.0 to +4.0/sec (meter rises faster)
  - Example: 3 allies vs 1 enemy = +3.0/sec
  - Example: 5 allies vs 2 enemies = +4.0/sec
  - Result: Meter rises toward combat threshold (70) faster

**Proximity Radius:**
- **Uses AoP (Area of Perception)** - same radius as NPC's detection range
- NPCs within AoP are considered "nearby" for calculation
- Only counts active NPCs (not dead, not in different state)

**Dynamic Behavior:**
- As allies die nearby → Rate decreases (less support)
- As allies arrive nearby → Rate increases (more support)
- Creates natural group dynamics - NPCs feel safer with backup, naturally retreat when outnumbered

**Example Scenario:**
- NPC with 50 agro meter, 2 allies vs 1 enemy nearby
- Rate: +3.0/sec (allies nearby modifier)
- With bravery 0.7 (1.35x multiplier): +4.05/sec
- Result: Meter rises from 50 → 70 in ~5 seconds → Enters combat

#### 7. Resource Scarcity Rate (+0.0 to +1.5 per second) ⭐ NATURAL ESCALATION
**Purpose:** As resources deplete in the world, NPCs become more competitive and aggressive. Creates natural escalation of conflict as game progresses.

**Calculation:**
- Count available harvestable resources within AoP radius
- Calculate scarcity based on resource count

**Rate Values:**
- **Many resources available (10+):** +0.0/sec (no modifier, resources plentiful)
- **Few resources (5-9):** +0.5/sec (slight increase in agro rate)
- **Very few resources (2-4):** +1.0/sec (moderate increase)
- **Critical scarcity (0-1):** +1.5/sec (high increase - fight for remaining resources)

**Implementation:**
```gdscript
func _calculate_resource_scarcity_rate() -> float:
    var detection_range = get_stat("perception") * 200.0  # Use AoP
    var resources = get_tree().get_nodes_in_group("resources")
    
    var available_resources = 0
    for resource in resources:
        if not is_instance_valid(resource):
            continue
        var distance = global_position.distance_to(resource.global_position)
        if distance <= detection_range:
            if resource.has_method("is_harvestable") and resource.is_harvestable():
                available_resources += 1
    
    # Calculate scarcity modifier
    if available_resources >= 10:
        return 0.0  # No modifier
    elif available_resources >= 5:
        return 0.5  # Slight increase
    elif available_resources >= 2:
        return 1.0  # Moderate increase
    else:
        return 1.5  # High increase - fight for remaining resources
```

**Gameplay Impact:**
- **Early game:** Plenty of resources → Less conflict, peaceful gathering
- **Mid game:** Resources deplete → More competition, occasional conflicts
- **Late game:** Critical scarcity → High conflict, NPCs fight over remaining resources
- **Creates natural progression:** Game becomes more competitive over time

#### 8. Resource Node Competition Rate (+0.0 to +2.0 per second) ⭐ NATURAL CONFLICT
**Purpose:** When two NPCs from different clans approach the same resource node, their agro meters rise, creating natural competition without explicit rules.

**Trigger:**
- NPC A approaches resource node
- NPC B (different clan) also approaches same resource node
- Both NPCs detect each other within AoP
- Agro meters start increasing for both

**Rate Values:**
- **Same resource, different clans:** +1.0 to +2.0/sec (base competition rate)
- **Resource scarcity high:** Additional +0.5 to +1.0/sec
- **Result:** NPCs compete for resource, may enter combat if agro reaches 70

**Behavior:**
- NPCs continue gathering while agro rises
- If agro reaches 70 → Enter combat state
- Winner takes resource, loser may flee (if bravery hits 0)
- Creates dynamic resource competition

**Implementation:**
```gdscript
# In gather_state.gd or resource detection
func _check_resource_competition(resource_node: Node2D) -> float:
    var all_npcs = get_tree().get_nodes_in_group("npcs")
    var competition_rate = 0.0
    
    for other_npc in all_npcs:
        if other_npc == self or not is_instance_valid(other_npc):
            continue
        if other_npc.get("clan_name") == clan_name:
            continue  # Same clan, no competition
        
        # Check if other NPC is also approaching same resource
        var other_target = other_npc.get("current_gather_target")
        if other_target == resource_node:
            var distance = global_position.distance_to(other_npc.global_position)
            if distance <= get_stat("perception") * 200.0:  # Within AoP
                # Both want same resource - increase agro rate
                competition_rate = 1.5  # Base competition rate
                if _is_resource_scarcity_high():
                    competition_rate += 1.0  # Higher when resources scarce
                break  # Only count first competitor
    
    return competition_rate
```

### Agro Meter Behavior Outcomes

#### High Agro Meter (70-100) → Combat State

**When agro meter >= 70:**
1. **Combat State:** Enters `combat_state` (priority 12.0)
2. **Agro Target:** Enemy becomes `agro_target`
3. **Behavior:** Move toward enemy, engage in melee combat if in range
4. **Visual:** Red "!!!" indicator appears above NPC
5. **Combat:** If enemy in attack range (100px), perform melee attacks

**Combat Behavior:**
- Moves toward enemy aggressively
- Attacks on cooldown (2.0 seconds)
- Continues until enemy dead, enemy out of range, or meter drops below 70

**Meter Changes During Combat:**
- **Enemy takes damage:** Meter stays high (maintains combat)
- **Enemy retreats:** Meter decreases gradually
- **NPC takes damage:** Bravery decreases (big chunks: -0.1 to -0.3 per hit)
- **Health drops below 25%:** Health rate modifier kicks in (-3.0/sec), AND bravery decreases (-0.05/sec)
- **Allies die nearby:** Clan proximity rate decreases, AND bravery decreases (-0.2 to -0.4 per death)
- **Bravery hits 0:** Agro automatically drops to 0 → Exit combat, enter flee state
- **Combat ends when:** agro_meter < 70 (returns to defensive/neutral state) OR bravery == 0 (forces flee)
- **Flee condition:** agro_meter == 0 AND bravery == 0 (both must be zero)

#### Flee State (Agro == 0 AND Bravery == 0)

**When BOTH agro meter == 0 AND bravery == 0:**
1. **Flight State:** Enters `flee_state` (priority 11.5)
2. **Behavior:** Retreats to land claim while hiding behind resource sprites
3. **Visual:** Green "!!!" indicator appears above NPC (3 green exclamations)
4. **Hiding:** Stops at trees/boulders/berry bushes for 1-2 seconds each
5. **Safety:** Reaches land claim where defended by clansmen

**Flight Behavior:**
- Moves away from enemy (1.3x speed multiplier)
- Navigates to land claim via hiding spots
- Hides at resource nodes (trees, boulders, berry bushes)
- Hide duration: Longer if enemy closer (more cautious)
- Continues until reaching land claim

**Flee Condition:**
- **Both values must be exactly 0:** `agro_meter == 0.0 AND bravery == 0.0`
- If either value is > 0, NPC does NOT flee
- Example: agro = 0, bravery = 0.1 → Does NOT flee (bravery not 0)
- Example: agro = 0.1, bravery = 0 → Does NOT flee (agro not 0)
- Example: agro = 0, bravery = 0 → FLEES

**Meter Changes During Flight:**
- **Reaching land claim:** Meter stays at 0, bravery may increase (feeling safer)
- **Enemy catches up:** Meter may rise if enemy gets too close → Exit flight if agro >= 70
- **Allies arrive:** Clan proximity rate increases, meter may rise → Exit flight if agro >= 70
- **Enemy leaves AoP:** Meter stays at 0, bravery may increase

**Flight Consequences:**
- **If Gathering:** Abandons resource node (allows enemy to take it)
- **If Herding:** Herd maintains until leader gets too far, then breaks naturally
- **Flight lasts until land claim reached:** No interruption (highest priority except combat)

#### Defensive/Neutral State (All Other Combinations)

**When agro meter is NOT >= 70 AND NOT (agro == 0 AND bravery == 0):**
- NPC is aware of threat but not fully committed
- **Behavior:** Defensive positioning, watches enemy, may approach cautiously
- **Visual:** No indicator (normal behavior)
- **Can transition:** 
  - Meter rising to 70+ → Enters combat
  - Meter falling to 0 AND bravery falling to 0 → Enters flee state

**Defensive Behavior:**
- Maintains distance from enemy
- Watches enemy movements
- May approach if meter rising, retreat if meter falling
- Can continue other activities (gathering, herding) but with awareness

### Agro Meter Continuous Updates

**Meter Updates Every Frame:**
- Calculates current rate based on all modifiers
- Applies rate to meter: `agro_meter += rate * delta`
- Clamps meter to 0.0-100.0 range
- Checks thresholds to trigger state changes

**Rate Recalculation Triggers:**
- **Health changes:** When HP crosses thresholds (80%, 50%, 30%)
- **Allies/enemies enter/leave AoP:** Clan proximity rate changes
- **Enemy moves closer/farther:** Distance to claim rate changes
- **Herd size changes:** Herd protection rate changes
- **Resources change:** Resource value rate changes

**Natural Transitions:**
- Meter rises from 30 → 70: NPC transitions from defensive → combat
- Meter falls from 70 → 30: NPC transitions from combat → flight
- Meter stays in range: NPC maintains current state
- No cooldowns needed - transitions happen naturally as meter crosses thresholds

**Example Flow with Dynamic Bravery:**
1. Enemy enters AoP → Meter starts at 25% (base) → Rate: +5.0/sec
2. With bravery 0.8 (1.4x): Actual rate = 7.0/sec
3. Meter rises: 25 → 50 → 70 (takes ~6 seconds)
4. At 70: Enters combat state (regardless of bravery)
5. During combat:
   - Takes 30 damage → Bravery: 0.8 → 0.5 (-0.3)
   - Health drops to 25% → Health rate: -3.0/sec, Bravery rate: -0.05/sec
   - With bravery 0.5 (1.25x): Agro decrease = -2.4/sec
   - Takes 20 more damage → Bravery: 0.5 → 0.3 (-0.2)
   - Ally dies nearby → Bravery: 0.3 → 0.1 (-0.2)
   - Takes 10 more damage → Bravery: 0.1 → 0.0 (-0.1)
6. **Bravery hits 0 → Agro automatically: 70 → 0.0**
7. **Flee condition met (agro == 0 AND bravery == 0) → Enters flee state**
8. NPC flees to land claim while hiding behind sprites

---

### How Bravery Influences Agro Meter

**Key Concept:** Bravery affects **how fast** the agro meter changes, AND is part of the flee condition (both must be 0 to flee).

**Bravery Multiplier Formula:**
```gdscript
# Bravery value: 0.0 (no bravery) to 1.0 (fearless)
var bravery_multiplier = 0.5 + (bravery * 1.0)
# Range: 0.5x (no bravery) to 1.5x (fearless)

# Apply to all rate calculations
var final_rate = (base_rate + situational_modifiers) * bravery_multiplier
```

**Brave NPC (Bravery 0.8-1.0):**
- **When Threatened:** Meter increases 1.4x-1.5x faster
  - Base rate 5.0/sec → Becomes 7.0-7.5/sec
  - Reaches combat threshold (70) faster
  - More likely to engage in combat
- **When Safe:** Meter decreases 1.4x-1.5x slower
  - Base decrease 5.0/sec → Becomes 3.3-3.6/sec
  - Stays in combat longer
  - **Less likely to flee:** Even if agro drops to 0, bravery is still high (0.8-1.0), so doesn't meet flee condition
- **Flee Condition:** Only flees if BOTH agro == 0 AND bravery == 0 (rare for brave NPCs)

**Low Bravery NPC (Bravery 0.0-0.3):**
- **When Threatened:** Meter increases 0.5x-0.65x slower
  - Base rate 5.0/sec → Becomes 2.5-3.25/sec
  - Takes longer to reach combat threshold (70)
  - Less likely to engage in combat
- **When Safe:** Meter decreases 0.5x-0.65x faster
  - Base decrease 5.0/sec → Becomes 7.5-10.0/sec
  - Agro drops to 0 faster
  - **More likely to flee:** If bravery also drops to 0, meets flee condition (both == 0)
- **Flee Condition:** More likely to have both values at 0, so more likely to flee

**Balanced NPC (Bravery 0.4-0.6):**
- **Normal rates:** 0.9x-1.1x multiplier
- Responds to situation without strong bias
- Natural behavior based on circumstances

**Practical Examples:**

**Scenario 1: Enemy enters land claim**
- **Brave NPC (0.9):** Rate = 5.0 * 1.45 = 7.25/sec → Reaches 70 in ~6 seconds → Combat
- **Low Bravery NPC (0.2):** Rate = 5.0 * 0.7 = 3.5/sec → Reaches 70 in ~13 seconds → Takes longer to engage
- **Result:** Brave NPC engages faster, low bravery NPC hesitates longer

**Scenario 2: Health drops to 25% during combat**
- Health rate modifier: -3.0/sec (meter decreases)
- **Brave NPC (0.9, multiplier 1.45):** Decrease rate = -3.0 / 1.45 = -2.07/sec (slower decrease)
  - Agro drops to 0 in ~34 seconds
  - But bravery still 0.9 → Does NOT flee (bravery not 0)
  - Stays in defensive/neutral state
- **Low Bravery NPC (0.2, multiplier 0.7):** Decrease rate = -3.0 / 0.7 = -4.29/sec (faster decrease)
  - Agro drops to 0 in ~16 seconds
  - If bravery also drops to 0 (e.g., allies die) → THEN flees (both == 0)
- **Result:** Brave NPC stays in defensive state even when agro is 0, low bravery NPC more likely to flee

**Scenario 3: Outnumbered (1 ally vs 3 enemies)**
- Clan proximity rate: -4.0/sec (meter decreases rapidly)
- **Brave NPC (0.9):** Final rate = -4.0 / 1.45 = -2.76/sec → Meter drops slower
  - Agro may drop to 0, but bravery stays high (0.9)
  - Does NOT flee (bravery not 0) → Stays defensive
- **Low Bravery NPC (0.2):** Final rate = -4.0 / 0.7 = -5.71/sec → Meter drops faster
  - Agro drops to 0 faster
  - If bravery also drops to 0 (outnumbered, scared) → THEN flees (both == 0)
- **Result:** Brave NPC more likely to stand ground even when outnumbered, low bravery NPC flees when both values hit 0

**Summary:**
- **Dynamic Bravery:** Changes during gameplay - decreases when taking damage, outnumbered, allies die, low health
- **Bravery to 0 Effect:** When bravery hits 0, agro automatically drops to 0, triggering flee condition
- **High Base Bravery:** Faster escalation to combat, slower de-escalation, but can still flee if bravery drops to 0
- **Low Base Bravery:** Slower escalation to combat, faster de-escalation, more likely to flee (bravery more likely to hit 0)
- **Flee Condition:** BOTH agro == 0 AND bravery == 0 (simple AND condition, made achievable by dynamic bravery)
- **Combat Condition:** agro >= 70 (regardless of bravery)
- **Creates natural personality-driven behavior** - NPCs can start brave but become scared after taking damage/witnessing deaths

---

## Part 4: Melee Combat System ✅ IMPLEMENTED

### Combat Overview

**Current Implementation Status:** ✅ Complete (Event-driven system with windup/recovery)

**Player Combat:**
- **Weapon Requirement:** ✅ IMPLEMENTED - Player MUST equip weapon in 1st hotbar slot to attack
- **Sprite Change:** ✅ IMPLEMENTED - Equipping weapon in 1st slot changes player sprite to show weapon
- **Attack Method:** Player walks close to NPC, then clicks on NPC to attack
- **Godmode:** Player has godmode for testing (immune to damage)
- **No Weapon = No Attack:** ✅ IMPLEMENTED - If no weapon in 1st slot, player cannot attack (click does nothing)
- **Player Timing:** 0.1s windup, 0.3s recovery (responsive for player control)

**NPC Auto-Combat:**
- NPCs automatically engage in melee when `agro_meter >= 70.0`
- No direct unit control (RimWorld/Dwarf Fortress style)
- Event-driven timing system (windup → hit → recovery)
- Spatial detection via `DetectionArea` (Area2D signals, 60x performance improvement)
- Attack arcs (90° cone) require proper positioning
- Stagger system interrupts enemy attacks

**Combat Participants:**
- Currently: Cavemen, clansmen, and player can attack
- All can be targets (NPCs and player)
- Future: May include predators and other NPCs

### Combat Components ✅ IMPLEMENTED

#### 1. Combat Component ✅
**Location:** `scripts/npc/components/combat_component.gd`

**Purpose:** Handles attack logic, damage calculation, combat state machine

**Key Features:**
- **State Machine:** IDLE → WINDUP → RECOVERY states
- **Event-Driven:** Uses `CombatScheduler` for precise timing (no per-frame polling)
- **Weapon Profiles:** Weapon-specific timings (Axe, Pick, Unarmed)
- **Attack Arcs:** 90° cone validation (positioning matters)
- **Stagger System:** Interrupts enemy windup attacks

**Structure:**
```gdscript
extends Node
class_name CombatComponent

enum CombatState { IDLE, WINDUP, RECOVERY }

var npc: Node2D = null  # Can be NPCBase or Player
var current_target: Node2D = null  # Can be NPCBase or Player
var attack_range: float = 100.0
var state: CombatState = CombatState.IDLE

# Event-driven timing
var windup_time: float = 0.45  # Weapon-specific
var recovery_time: float = 0.8  # Weapon-specific
var attack_arc: float = PI  # 180° (90° cone each side)
var stagger_time: float = 0.0

# Weapon profiles
var base_damage: int = 10
```

#### 2. Health Component ✅
**Location:** `scripts/npc/components/health_component.gd`

**Purpose:** Tracks HP, death, corpse creation, leader succession

**Key Features:**
- **HP System:** 30 HP default (3 hits to kill at 10 damage per hit)
- **Death Handling:** Sets corpse sprite, breaks herd relationships, emits signals
- **Leader Succession:** When caveman dies, oldest clansman becomes new leader
- **Agro on Damage:** Taking damage increases `agro_meter` by 50.0 and sets combat target

**Structure:**
```gdscript
extends Node
class_name HealthComponent

var npc: NPCBase = null
var max_hp: int = 30
var current_hp: int = 30
var is_dead: bool = false
var last_attacker: Node = null
var death_weapon: ResourceData.ResourceType = ResourceData.ResourceType.NONE

signal npc_died(npc: NPCBase)
```

**Death System:**
- On death: Sets `is_dead = true`, changes sprite to `corpsecm.png`
- Breaks herd relationships (releases NPCs that were following)
- Preserves inventory for looting
- Triggers leader succession (if caveman dies, promotes oldest clansman)
- Emits `npc_died` signal

#### 3. Detection Area ✅
**Location:** `scripts/npc/components/detection_area.gd`

**Purpose:** Event-driven spatial target acquisition (replaces `get_nodes_in_group()`)

**Key Features:**
- **Area2D Signals:** Uses `body_entered`/`body_exited` for efficient detection
- **Performance:** 60x reduction in target acquisition overhead
- **Range:** 300px detection radius (matches combat detection range)

**Structure:**
```gdscript
extends Area2D
class_name DetectionArea

var nearby_enemies := {}
var detection_range: float = 300.0

func get_nearest_enemy(origin: Vector2, npc: NPCBase = null) -> Node:
    # Returns nearest valid enemy (NPCBase or Player)
    # Filters by: alive, different clan, caveman/clansman/player type
```

**How It Works:**
- Tracks enemies via Area2D signals (event-driven, not polling)
- `CombatState` queries `DetectionArea` every 1 second (throttled)
- Returns nearest valid enemy or null

#### 4. Combat Scheduler ✅
**Location:** `scripts/systems/combat_scheduler.gd`

**Purpose:** Event-driven timing system for combat actions

**Key Features:**
- **Autoload Singleton:** Available globally
- **Event Scheduling:** Schedules windup/hit/recovery events
- **Precise Timing:** No per-frame polling, events fire exactly on time

**Structure:**
```gdscript
extends Node
class_name CombatScheduler

var scheduled_events: Array[Dictionary] = []

func schedule_event(time: float, callback: Callable, data: Dictionary = {})
func process_events(current_time: float)
```

**How It Works:**
- `CombatComponent.request_attack()` schedules windup → hit → recovery events
- `CombatScheduler` processes events each frame, firing callbacks on time
- Creates smooth, predictable combat timing without frame-dependent calculations

### Combat States ✅ IMPLEMENTED

#### Combat State ✅
**Location:** `scripts/npc/states/combat_state.gd`  
**Priority:** 12.0 (very high, overrides most states)

**State Logic:**
- **Entry:** `agro_meter >= 70.0` AND valid enemy found (via `DetectionArea` or existing `combat_target`)
- **Action:** Position for attack, call `CombatComponent.request_attack()` when in range
- **Exit:** Enemy dead, enemy out of range, `agro_meter < 70.0`, or higher priority state

**Combat Behavior:**
- Uses `DetectionArea` for efficient enemy detection (throttled to 1 query/second)
- Positions NPC at optimal attack range (maintains distance, head-on alignment)
- Calls `CombatComponent.request_attack()` when in range and aligned
- Respects `combat_locked` flag (prevents FSM state switching during windup/recovery)
- Can switch targets if better target appears (nearest enemy)

**Positioning System:**
- Maintains optimal attack range (70-95% of max range)
- Requires head-on alignment (within ~72° angle)
- Tracks target movement to maintain position
- Prevents oscillation with position stability checks

#### Flee State
**Location:** `scripts/npc/states/flee_state.gd`  
**Priority:** 11.5 (high, but below combat)

**State Logic:**
- **Entry:** agro_meter == 0 AND bravery == 0 (both must be exactly 0)
- **Action:** Move away from enemy, run to safety (land claim) while hiding
- **Exit:** Reached land claim, agro_meter > 0 (enemy caught up), or higher priority state (combat)

**Flee Behavior:**
- Move away from enemy
- Navigate to land claim via hiding spots
- Hide at resource nodes (trees, boulders, berry bushes) for 1-2 seconds
- Continue until safe (inside land claim)

### Damage Calculation ✅ IMPLEMENTED

**Current Damage Formula:**
```gdscript
base_damage = 10  # Fixed base damage
total_damage = base_damage  # Simple for now (no strength/weapon bonuses yet)
final_damage = total_damage  # No armor reduction yet
```

**Damage Application:**
- Apply damage to target's `HealthComponent`
- Target's `take_damage()` increases their `agro_meter` by 50.0
- Target's `agro_meter` increase sets attacker as `combat_target`
- Check for death (HP <= 0)
- Emit `npc_died` signal if dead
- Show red X hitmarker when damage is done
- **Stagger System:** If target is in WINDUP, interrupt their attack

**Future Enhancements:**
- Strength-based damage bonuses
- Weapon damage bonuses (Spear +5, Club +3)
- Armor damage reduction (Hide Armor -3)

### Enemy Detection ✅ IMPLEMENTED

**Detection System:**
- **DetectionArea:** Uses Area2D signals (`body_entered`/`body_exited`)
- **Spatial Queries:** Event-driven, not polling (60x performance improvement)
- **Throttled Checks:** `CombatState` queries `DetectionArea` every 1 second

**Detection Logic:**
- Filters by: alive, different clan, caveman/clansman/player type
- Same clan = friendly (not attacked)
- Different clan or player = enemy
- Returns nearest valid enemy within 300px range

**Detection Range:**
- **Normal NPCs:** 300px (via `DetectionArea`)
- **Attack Range:** 100px (melee range)
- **Future:** Predators may have longer detection range (800px)

### Death System ✅ IMPLEMENTED

**Death Handling:**
- On death (HP <= 0): Set `is_dead = true`
- Change sprite to `corpsecm.png` (corpse sprite)
- Stop FSM processing (no more state updates)
- Stop steering agent (no more movement)
- Preserve inventory for looting
- Emit `npc_died` signal
- Break herd relationships (release NPCs that were following)
- **Leader Succession:** If caveman dies, oldest clansman becomes new leader

**Death Effects:**
- **Looting:** Player can press 'I' near corpse to open inventory (drag-and-drop loot)
- **Corpse Persistence:** Corpse remains in scene for looting
- **Land Claim Ownership:** Transferred to new leader (if caveman died)
- **Herd Release:** All NPCs following the dead NPC are released (become wild if applicable)

**Leader Succession Logic:**
- When caveman dies, `_select_new_leader()` in `HealthComponent`:
  1. Finds all clansmen in same clan
  2. Selects oldest by age
  3. Promotes to caveman (`npc_type = "caveman"`)
  4. Transfers land claim ownership to new leader

### Medic Hut Integration

**Healing System:** future add
- Hurt NPCs (wounded, low HP) auto-path to Medic Hut
- Medic Hut requires berries in inventory
- Wounds heal over time when at Medic Hut
- Healing rate: 1 HP per 10 seconds (configurable)

**Healing State:** fufutre add
- New state: `heal_state.gd` (optional, or use seek state)
- Priority: 9.0 (below combat, above reproduction)
- Entry: Wounded, Medic Hut available, berries in hut
- Action: Move to Medic Hut, wait for healing

---

## Part 5: Current Implementation Status

### ✅ Implemented Features

**Phase 1: Core Combat System ✅**
1. ✅ Event-driven combat timing (`CombatScheduler`)
2. ✅ Spatial enemy detection (`DetectionArea`)
3. ✅ Combat state machine (IDLE/WINDUP/RECOVERY)
4. ✅ Weapon profiles (Axe, Pick, Unarmed with specific timings)
5. ✅ Attack arcs (90° cone validation)
6. ✅ Stagger system (interrupts enemy windup)
7. ✅ Land claim intrusion detection (fast agro increase: 50/sec)
8. ✅ Agro meter-based combat entry (`agro_meter >= 70.0`)
9. ✅ Leader succession (oldest clansman becomes new leader when caveman dies)
10. ✅ Player combat integration (weapon requirement, responsive timings)

**Phase 2: Planned Features 🔮**
1. 🔮 Enemy near land claim (proactive defense)
2. 🔮 Herd animal stolen (theft defense)
3. 🔮 Enemy in AoP with accelerating agro
4. 🔮 Flight system (flee to land claim with hiding)
5. 🔮 Bravery system (dynamic personality traits)
6. 🔮 Additional personality traits (territorial, protective, greedy, survivalist)

### 🔮 Planned Features (Future)

**Flight System (Planning)**
1. 🔮 Create flee state with hiding behavior
2. 🔮 Implement pathfinding to land claim via hiding spots
3. 🔮 Add hiding mechanics (stop at resource nodes for 1-2 seconds)
4. 🔮 Visual indicators for flight and hiding states (3 green !!!)

**Agro Meter & Bravery System (Planning)**
1. 🔮 Add personality traits to NPCs (bravery, territorial, protective, greedy, survivalist)
2. 🔮 Create dynamic agro meter system with rate calculations
3. 🔮 Implement dynamic bravery system (decreases/increases based on events)
4. 🔮 Integrate bravery multiplier with agro meter rates
5. 🔮 Situational modifiers (herd protection, resource value, health, strength, proximity, etc.)

**Advanced Combat Features (Planning)**
1. 🔮 Weapon damage bonuses (Spear +5, Club +3)
2. 🔮 Armor damage reduction (Hide Armor -3)
3. 🔮 Strength-based damage calculations
4. 🔮 Wound system (temporary HP reduction)
5. 🔮 Medic Hut healing integration

### Current System Integration ✅

**1. Agro System Integration (Current):**
- **Land Claim Intrusion:** Enemy enters land claim → `agro_meter` increases at 50.0/sec
- **Combat Entry:** When `agro_meter >= 70.0` → Enter combat state
- **Direct Attack:** Taking damage → `agro_meter` increases by 50.0, sets `combat_target` to attacker
- **Natural Decay:** `agro_meter` decreases at 5.0/sec when not in combat (if < 100.0)
- **Combat Exit:** When `agro_meter < 70.0` → Exit combat state

**2. Combat System Integration (Current):**
- **Detection:** `DetectionArea` tracks nearby enemies (event-driven, 300px range)
- **Target Selection:** `CombatState` finds nearest enemy via `DetectionArea` (throttled to 1 query/sec)
- **Positioning:** NPC positions at optimal attack range with head-on alignment
- **Attack Request:** When in range, calls `CombatComponent.request_attack()`
- **Combat Lock:** FSM respects `combat_locked` flag (prevents state switching during windup/recovery)
- **Stagger:** Successful hits interrupt enemy windup attacks

**3. State Priority System (Current):**
- **Combat (12.0)** > **Other states** (gather, wander, herd_wildnpc, etc.)
- Combat state has very high priority, overrides most other states
- FSM respects `combat_locked` flag (prevents state switching during windup/recovery)
- State transitions are smooth (FSM handles transitions automatically)

**4. Performance Optimizations (Current):**
- **DetectionArea:** Event-driven spatial queries (60x faster than `get_nodes_in_group()`)
- **Throttled Checks:** Combat state checks for targets every 1 second (not every frame)
- **Event Scheduling:** Combat timing uses `CombatScheduler` (no per-frame polling)
- **Position Stability:** Prevents oscillation with position tracking and thresholds

**5. Future Integration (Planned):**
- **Flight System:** Will trigger when `agro_meter == 0 AND bravery == 0` (both must be exactly 0)
- **Bravery System:** Will affect agro meter rate (high bravery = faster increase, slower decrease)
- **Personality Traits:** Will modify agro rates (territorial, protective, greedy, survivalist)
- **Situational Modifiers:** Will add context-based rate adjustments (herd size, resources, health, etc.)

### Testing Considerations

**Before Implementation:**
1. Define all agro triggers clearly
2. Define flight behavior clearly (hiding spots, duration, pathfinding)
3. Define FoF modifiers and ranges
4. Define state priorities and transitions

**During Implementation:**
1. Test each agro trigger individually
2. Test flight behavior with various hiding spot configurations
3. Test agro meter rate calculations with different personality traits
4. Test dynamic bravery changes (damage, allies die, etc.)
5. Test state transitions and priorities

**After Implementation:**
1. Test full system integration (agro triggers → meter rises → combat/flight based on thresholds)
2. Test edge cases (multiple enemies, no hiding spots, bravery hits 0 during combat, etc.)
3. Balance agro meter rates and bravery modifiers
4. Test performance with many NPCs (agro meter updates every frame)
5. Test trait evolution (NPCs learning from combat experiences)

---

## Part 6: Configuration

### Combat Config
**Location:** `scripts/config/combat_config.gd`

```gdscript
extends Resource
class_name CombatConfig

# Combat
@export var melee_range: float = 100.0  # Attack range
@export var attack_cooldown: float = 2.0  # Seconds between attacks
@export var base_damage: int = 10  # Base HP damage
@export var strength_damage_multiplier: float = 0.1  # +1 damage per 10 Strength
@export var spear_damage_bonus: int = 5
@export var club_damage_bonus: int = 3
@export var hide_armor_reduction: int = 3
@export var base_hp: int = 100  # Base HP for NPCs

# Agro
@export var agro_increase_rate_land_claim: float = 10.0  # Per second when enemy in land claim
@export var agro_increase_rate_near_claim: float = 5.0  # Per second when enemy near land claim
@export var agro_increase_rate_aop: float = 5.0  # Per second when enemy in AoP
@export var agro_increase_rate_herd_stolen: float = 8.0  # Per second after herd stolen
@export var agro_decrease_rate: float = 5.0  # Per second when threat gone
@export var agro_full_on_attack: float = 100.0  # Instant agro when attacked
@export var agro_herd_stolen_initial: float = 20.0  # Initial agro when herd stolen
@export var hostile_threshold: float = 70.0  # Agro level to show "!!!" indicator

# Flight
@export var flee_aggression_threshold: float = 30.0  # Flee if aggression < this
@export var flee_hp_threshold: float = 0.3  # Flee if HP < 30%
@export var hide_duration_base: float = 1.5  # Base hide duration (seconds)
@export var hide_duration_variance: float = 0.5  # Random variation (±seconds)
@export var hide_spot_min_distance: float = 200.0  # Minimum distance between hiding spots
@export var hide_spot_max_distance: float = 400.0  # Maximum distance between hiding spots
@export var flight_speed_multiplier: float = 1.3  # Flight speed vs normal speed

# Detection
@export var detection_range_normal: float = 300.0  # Normal NPC detection
@export var detection_range_predator: float = 800.0  # Predator detection
@export var near_land_claim_radius: float = 600.0  # Distance from land claim to trigger "near" agro

# Agro Meter System
@export var agro_meter_base_rate: float = 5.0  # Base increase rate per second (when threat present)
@export var agro_meter_combat_threshold: float = 70.0  # Meter level to trigger combat (70-100)
@export var agro_meter_initial_on_entry: float = 25.0  # Initial meter when enemy enters land claim (25%)
@export var bravery_multiplier_min: float = 0.5  # Low bravery multiplier (slower increase, faster decrease)
@export var bravery_multiplier_max: float = 1.5  # High bravery multiplier (faster increase, slower decrease)
# Note: Flee condition is agro_meter == 0.0 AND bravery == 0.0 (both must be exactly 0)
# Note: When bravery hits 0, agro automatically drops to 0

# Dynamic Bravery System
@export var bravery_damage_decrease_per_hit: float = 0.15  # Base decrease per damage hit (-0.1 to -0.3 based on damage)
@export var bravery_damage_threshold_medium: float = 20.0  # Medium damage threshold
@export var bravery_damage_threshold_high: float = 40.0  # High damage threshold
@export var bravery_outnumbered_decrease_rate: float = 0.08  # Per second when outnumbered (-0.05 to -0.1/sec)
@export var bravery_ally_death_decrease: float = 0.3  # Per ally death (-0.2 to -0.4)
@export var bravery_low_health_decrease_rate: float = 0.035  # Per second when health < 30% (-0.02 to -0.05/sec)
@export var bravery_ally_nearby_increase_rate: float = 0.035  # Per second when allies nearby (+0.02 to +0.05/sec)
@export var bravery_win_fight_increase: float = 0.15  # Per enemy defeated (+0.1 to +0.2)
@export var bravery_safe_recovery_rate: float = 0.01  # Per second when safe in land claim (+0.01/sec)

# Agro Meter Rate Modifiers (per second)
@export var agro_rate_herd_protection_max: float = 3.0  # Max herd protection rate (+0.0 to +3.0/sec)
@export var agro_rate_resource_value_max: float = 2.0  # Max resource value rate (+0.0 to +2.0/sec)
@export var agro_rate_health_range: float = 5.0  # Health rate range (-3.0 to +2.0/sec)
@export var agro_rate_strength_range: float = 6.0  # Strength rate range (-3.0 to +3.0/sec)
@export var agro_rate_distance_claim_range: float = 3.0  # Distance to claim range (-1.0 to +2.0/sec)
@export var agro_rate_clan_proximity_max: float = 5.0  # Max clan proximity rate (-5.0 to +4.0/sec)
@export var agro_rate_clan_proximity_radius: float = 500.0  # Radius to check for nearby allies/enemies (uses AoP)
@export var agro_rate_resource_scarcity_max: float = 1.5  # Max resource scarcity rate (+0.0 to +1.5/sec)
@export var agro_rate_resource_competition_max: float = 2.0  # Max resource competition rate (+0.0 to +2.0/sec)

# Additional Personality Traits
@export var territorial_trait_max_modifier: float = 2.0  # Max territorial modifier (+0.0 to +2.0/sec)
@export var protective_trait_max_modifier: float = 2.0  # Max protective modifier (+0.0 to +2.0/sec)
@export var greedy_trait_max_modifier: float = 1.5  # Max greedy modifier (+0.0 to +1.5/sec)
@export var survivalist_trait_max_multiplier: float = 1.5  # Max survivalist multiplier (1.0x to 1.5x for bravery decrease)

# Healing
@export var healing_rate: float = 0.1  # HP per second at Medic Hut
```

### NPC Trait Ranges

```gdscript
# Personality trait ranges (for trait generation)
trait_min: float = 0.0
trait_max: float = 1.0
trait_default: float = 0.5

# Common trait distributions:
# Low bravery: 0.0-0.3 (30% of NPCs)
# Balanced: 0.3-0.7 (50% of NPCs)
# High bravery: 0.7-1.0 (20% of NPCs)
```

---

## Part 7: File Structure

```
scripts/
├── npc/
│   ├── components/
│   │   ├── combat_component.gd (NEW)
│   │   ├── health_component.gd (NEW)
│   │   ├── weapon_component.gd (NEW)
│   │   └── armor_component.gd (NEW)
│   └── states/
│       ├── combat_state.gd (NEW)
│       ├── flee_state.gd (NEW - enhanced with hiding)
│       └── heal_state.gd (NEW - optional)
└── config/
    └── combat_config.gd (NEW)
```

---

## Part 8: Questions for Clarification

### Agro System
1. **Agro Acceleration in AoP:** Should agro increase rate accelerate linearly or exponentially?
exponentially
2. **Near Land Claim Radius:** What distance should trigger "near land claim" agro? (Suggested: 600px) 
3. **Herd Stolen Detection:** How should NPC detect that a herd animal was stolen? (Distance check? Follow status check?)
4. **Agro Persistence:** Should agro persist if enemy leaves but returns quickly? (Cooldown system?)
5. **Multiple Enemies in Land Claim:** If multiple enemies enter land claim, should NPC prioritize closest enemy or strongest enemy?
closest
6. **Agro Level on Entry:** When enemy first enters land claim, should agro start at 0.0 and increase, or start at a base value (e.g., 10.0)?
there should be a 25% base i think for now
7. **Agro Decay Rate:** How fast should agro decrease when threat is gone? Should it decay immediately or gradually?
gradually
8. **Enemy Leaving Range:** If enemy leaves land claim but stays in AoP, should agro continue increasing or switch to AoP rate? switch to aop

### Flight System
1. **Hiding Spot Selection:** Should NPCs prefer certain resource types? (Trees > Boulders > Berry Bushes?)
those 3 will work for now
2. **Hiding Duration:** Should hide duration vary based on threat proximity? (Closer enemy = shorter hide?)
closer enimy should be longer hide
3. **Flight Path:** Should NPCs take direct path or prefer paths with more hiding spots?
there should be a mix, going more direct if the landclaim is nearby 
4. **Flight Interruption:** Can flight be interrupted by other states? (E.g., very hungry, need to eat?)
no flight lasts until the npc gets to their landclaim
5. **No Hiding Spots Available:** What happens if there are no trees/boulders/berry bushes along the flight path? Should NPC take direct path or find alternative route?
directly to their landclaim
6. **Hiding Spot Occupied:** What if another NPC is already hiding at a resource node? Should fleeing NPC wait, find another spot, or continue?
find another spot
7. **Flight While Herding:** If NPC is herding animals and chooses flight, do the animals follow or scatter? Do they also try to hide?
the herd will maintain herd until the leader gets too far and the herd breaks, the herd moves slow and a fleeing npc moves faster than the herd so naturally there will be a break unless the leader gets to the landclaim in.
8. **Flight Speed:** Should fleeing NPCs move faster than normal? By how much? (Suggested: 1.3x multiplier)
yes we can start with 1.3x for now
9. **Reaching Land Claim:** Once NPC reaches land claim, should flight end immediately or continue until enemy is far enough away?
it will end still be high but it will decrease quickly 
10. **Flight Visual Feedback:** Should there be visual indicators that NPC is fleeing? (Different sprite, animation, indicator text?) 
Use 3 green !!! exclamations to indicate flight

### Agro Meter & Bravery System
1. **Meter Update Frequency:** Should meter update every frame or at fixed intervals? (Every frame for smooth transitions)
2. **Bravery Multiplier Range:** Is 0.5x-1.5x appropriate, or should it be wider/narrower? (Current: 0.5x low bravery, 1.5x high bravery)
3. **Combat Threshold:** Is 70 a good threshold for combat, or should it be adjusted? (Current: 70+ = combat)
4. **Flee Condition:** Both values must be exactly 0 - is this too restrictive or appropriate? (Current: agro == 0 AND bravery == 0)
5. **Initial Meter on Threat:** When enemy first detected, should meter start at 0, 25%, or based on threat level? (User answered: 25% base)
6. **Health-Based Meter Changes:** Should meter decrease rate increase when health drops below thresholds? (User answered: Yes, tied to health bar level - 25% increments)
7. **Clan Member Proximity:** How should proximity to clan members affect meter rate? (User answered: Uses AoP, more clansmen = boost to rate, clansmen die = lose rate)
8. **Outnumbered Calculation:** When there are more enemies in AoP than clansmen, how much should rate decrease? (User answered: -3.0 to -5.0/sec seems good)
9. **Allies Nearby Boost:** When more allies than enemies in AoP, how much should rate increase? (User answered: +2.0 to +4.0/sec seems good)
10. **Direct Attack Response:** If NPC is directly attacked, should meter instantly jump to 100 or increase rapidly? (Recommendation: Instant jump to 100 for direct attack)
11. **Meter During Combat:** Should meter continue to change during combat based on health/ally changes? (User answered: Yes, changes at 25% health increments)
12. **Bravery Changes:** Should bravery value change during gameplay (e.g., decrease when outnumbered, increase with allies)? Or stay static? (Needs clarification)
13. **Flight Reset:** When NPC reaches land claim after flight, should meter reset to 0 or decrease gradually? (User answered: Decreases quickly but stays high initially)
14. **Rate Modifier Ranges:** Are the suggested rate ranges appropriate? (User answered: Seems good for now, may edit)
15. **Personality Trait Inheritance:** Should bravery trait be inherited from parents? (User answered: Yes, traits come from parents with hybridizing)

### Combat System
1. **Combat Range:** Should attack range be fixed at 100px or variable based on weapon? (Spear longer range than club?)
variable when we add more wepons in the future, there will also be ranged wepons
2. **Attack Animation:** Should attacks have visual animation or just damage application?
there will be an animation but for now we just need a red X hit marker on the npc taking damage
3. **Combat Interruption:** Can combat be interrupted by higher priority states? (E.g., starving to death?)
no its the highest, if the npc is low on health and bravery drops to 0 (causing agro to drop to 0) then combat will break and the npc will enter flee state and return to the landclaim, if it is hurt it will heal. the logic should flow like that naturally
4. **Multiple Targets:** Can NPCs fight multiple enemies simultaneously? Or focus one target until dead?
NPC should attack the closest target
5. **Combat While Fleeing:** If NPC is fleeing and enemy catches up, should combat automatically trigger or require FoF re-roll? if NPC is in flight mode then it will continue to the landclaim while periodically hiding behind sprites like stated above
6. **Weapon Durability:** Should weapons have durability and break after X uses, or infinite durability for Phase 2?
infinite for now
7. **Auto-Equip Weapons:** Should NPCs auto-equip weapons when entering combat, or only use already-equipped weapons?
they should auto-equip weapons when entering combat
8. **Combat vs Gathering:** If NPC is gathering and enemy approaches, should combat interrupt gathering immediately or wait for agro meter to rise? 
it can with a low trust trait npc, low trust will cause agro meter to rise faster, or shorten the time a rival can be in their AOP before agro meter reaches 70
9. **Player Combat:** When player attacks NPC, should NPC immediately agro at player, or let agro meter rise?
Player can only attack if weapon is equipped in 1st hotbar slot (sprite changes to show weapon). When player attacks NPC, agro meter should start rising when player enters AoP, but direct attack sets agro_meter to 100.0 (full agro). If player has no weapon in 1st slot, cannot attack.
10. **Combat Feedback:** Should combat show damage numbers, HP bars, or just visual effects (red X hitmarker)?
red X marker only for now
11. **Death Animation:** Should NPCs have death animation (fall down) or immediate removal/corpse sprite?
there will be an animation but for now switch their sprite to corpsecm.png 
12. **Loot Dropping:** When NPCs die, should they drop all inventory items, only equipped items, or random selection?
when they die a player will be able to walk close to thier corpse and press I this will open the player inventory and the corpse inventory which will have all the items the NPC had in thier inventory. the corpse will also become a resource node for a short time allowing the player to gather meat, bone, hide, sinue, fat etc depending if they have the proper tools

### Integration & Edge Cases
1. **State Priority Conflicts:** What happens if multiple high-priority states conflict? (E.g., starving AND enemy in land claim?)
combat, and fleeing will be top 2 
2. **No Land Claim:** If NPC has no land claim, where do they flee to? Nearest safe location? Random direction?
a wild npc can also flee, it will move away from the npc threating it for a few seconds (depending on what wild npc it is) some npcs will also hide if we allow them that ability.
3. **Enemy Clan Members:** How do NPCs identify enemy clan members? Different clan_name? Visual indicator?
NPCs will only be friendly to thier own clan, anyone else is a threat, when 2 npcs enter eachother AOP then rolls happen and one could go agro and attack depending on the circumstances, like traits, and hunger etc
4. **Player as Enemy:** Should player be treated as enemy for all clans, or only specific clans? Can player be "friendly" to some clans? 
Player will be seen as enemy by all clans as default. besides his own clan
5. **Predator Agro:** Do predators trigger agro in NPCs? Should NPCs agro at predators, or only at other cavemen/clansmen?
NPCs can agro at predators but they will be more likly to flee if the predator is too strong.
6. **Agro Chain Reaction:** If NPC A agros at NPC B, and NPC B is near NPC C (same clan as A), should NPC C also agro?
yes, to be accurate to tribe mentality one tribe member attacking would cause the nearby clansmen to also attack, i hope that we program the bravery to be high when in a group thusly causing a fight roll to happen. in the case a rival enters the landclaim all clansmen in the landclaim and within AOP should agro 
7. **Herd Animal Behavior:** When herd animals are "stolen", do they actively switch leaders, or just stop following?
this is already established in Herding_System_Guide.md
8. **Resource Node Competition:** If two NPCs from different clans approach same resource, should they fight over it or share?
They should both move to it but agro meters will rise and one may move away or there may be conflict.
9. **Performance Concerns:** With many NPCs checking agro/FoF, should we limit checks per frame or use spatial partitioning?
not sure about this
10. **Agro Memory:** Should NPCs "remember" enemies that previously attacked them? (Persistent agro even after enemy leaves?)
not nessisary
11. **Flight Pathfinding:** Should flight use A* pathfinding to find hiding spots, or simple direct path with nearest hiding spots?
simple direct path with nearest hiding spots
12. **Hiding Spot Detection:** How should NPCs detect available hiding spots? Raycast? Distance check? Pre-computed paths?
what ever is simpest and eaiset on performance
13. **Multiple Threats:** If NPC faces multiple enemies, should FoF consider total threat level or just nearest enemy?
it should consider total like in "outnumbered"
14. **Agro Transfer:** If NPC A is agro at enemy, and NPC B (same clan) sees this, should NPC B also agro at same enemy?
yes they should help their clansman
15. **Land Claim Defense Coordination:** Should multiple NPCs from same clan coordinate defense, or act independently?
there will be triggers such as population that will trigger the npc clansmen to group up into a raiding party and simulate a coordinated attack. when an enimy enters their landclaim the npc will defend there wont be as much coordinated defese but every clansmen in the area will come defend their landclaim

---

## Summary

### Current Implementation ✅

**Combat System Philosophy:**
- **Event-Driven:** Uses `CombatScheduler` for precise timing (windup → hit → recovery)
- **Spatial Detection:** `DetectionArea` uses Area2D signals (60x performance improvement)
- **Agro-Based Entry:** Simple threshold - `agro_meter >= 70.0` = combat entry
- **Tactical Positioning:** Attack arcs (90° cone) require proper positioning
- **Stagger System:** Successful hits interrupt enemy windup attacks

**Key Features:**
- **Land Claim Defense:** Enemy enters land claim → `agro_meter` increases at 50.0/sec
- **Fast Combat Entry:** Fills from 0 to 70 in 1.4 seconds (rapid escalation)
- **Player/Clansmen Can Raid:** Can freely enter enemy land claims (triggers defense)
- **Leader Succession:** When caveman dies, oldest clansman becomes new leader
- **Combat Lock:** FSM respects `combat_locked` flag (prevents state switching during attacks)

**Current Behavior Rules:**
- **Combat Entry:** `agro_meter >= 70.0` (regardless of other factors)
- **Combat Exit:** `agro_meter < 70.0` OR enemy dead OR enemy out of range
- **Agro Increase:** 50.0/sec when intruders in land claim, +50.0 when taking damage
- **Agro Decay:** 5.0/sec when not in combat (if `agro_meter < 100.0`)

### Planned Features 🔮

**Future Enhancements:**
- **Flight System:** Flee when `agro_meter == 0 AND bravery == 0` (both must be exactly 0)
- **Bravery System:** Dynamic personality trait that affects agro meter rate
- **Personality Traits:** Territorial, Protective, Greedy, Survivalist modifiers
- **Situational Modifiers:** Herd protection, resource value, health, strength, proximity rates
- **Resource Scarcity:** Natural escalation as resources deplete
- **Resource Competition:** Agro meters rise when NPCs compete for same resource
- **Trait Evolution:** NPCs learn from combat experiences

**Next Steps:**
1. ✅ Core combat system (DONE)
2. 🔮 Implement flight system (flee state with hiding)
3. 🔮 Add bravery system (dynamic personality traits)
4. 🔮 Add situational modifiers (herd, resources, health, etc.)
5. 🔮 Implement additional personality traits
6. 🔮 Add resource scarcity and competition systems

---

## Part 9: Additional Ideas from Original FightOrFlightGuide

### Area of Agro (AOA) - Enhanced Detection Zone

**Concept:** A personal defensive zone around each NPC that extends beyond land claim radius. When enemies enter this zone, agro meter starts increasing even before they reach the land claim.

**AOA Characteristics:**
- **Base Size:** 300-500px (trait-based, default 400px)
- **Dynamic:** Can be influenced by situation (herd size, resources, health)
- **Purpose:** Proactive defense before intruders reach land claim or steal herd

**AOA Size Modifiers:**
- **Base AOA:** 400px (default)
- **Large Herd (5+ wild NPCs):** +100px (more protective)
- **Low Health (<50%):** -50px (more cautious)
- **Well-Stocked Land Claim (20+ each resource):** +50px (defending valuable territory)
- **No Herd:** -50px (less to defend)
- **Territorial Trait:** +50px to +150px (based on trait value)

**AOA Integration:**
- When enemy enters AOA (outside land claim) → Agro meter starts increasing at base rate
- When enemy enters land claim → Agro meter increases faster (land claim defense rate)
- Creates natural escalation: Enemy approaches → AOA detection → Land claim defense → Combat

**Implementation:**
```gdscript
# Calculate AOA radius
func _calculate_aoa_radius() -> float:
    var base_aoa = 400.0
    var territorial_trait = personality_traits.get("territorial", 0.5)
    var aoa = base_aoa + (territorial_trait * 150.0)  # +0 to +150px
    
    # Situational modifiers
    if herd_size >= 5:
        aoa += 100.0
    if health_percent < 0.5:
        aoa -= 50.0
    if land_claim_resources_well_stocked():
        aoa += 50.0
    if herd_size == 0:
        aoa -= 50.0
    
    return clamp(aoa, 200.0, 1000.0)  # Min 200px, max 1000px
```

### Resource Scarcity Modifier

**Concept:** As resources deplete in the world, NPCs become more competitive and aggressive. This creates natural escalation of conflict as the game progresses.

**Resource Scarcity Rate Modifier:**
- **Many resources available (10+):** +0.0/sec (no modifier)
- **Few resources (5-9):** +0.5/sec (slight increase in agro rate)
- **Very few resources (2-4):** +1.0/sec (moderate increase)
- **Critical scarcity (0-1):** +1.5/sec (high increase - fight for remaining resources)

**Calculation:**
```gdscript
func _calculate_resource_scarcity_rate() -> float:
    var detection_range = get_stat("perception") * 200.0
    var resources = get_tree().get_nodes_in_group("resources")
    
    var available_resources = 0
    for resource in resources:
        if not is_instance_valid(resource):
            continue
        var distance = global_position.distance_to(resource.global_position)
        if distance <= detection_range:
            if resource.has_method("is_harvestable") and resource.is_harvestable():
                available_resources += 1
    
    # Calculate scarcity modifier
    if available_resources >= 10:
        return 0.0  # No modifier
    elif available_resources >= 5:
        return 0.5  # Slight increase
    elif available_resources >= 2:
        return 1.0  # Moderate increase
    else:
        return 1.5  # High increase - fight for remaining resources
```

**Gameplay Impact:**
- Early game: Plenty of resources → Less conflict
- Mid game: Resources deplete → More competition
- Late game: Critical scarcity → High conflict, NPCs fight over remaining resources
- Creates natural progression and escalation

### Additional Personality Traits

**Beyond Bravery:** Additional traits that influence agro meter rates and behavior.

**Territorial Trait (0.0-1.0):**
- **Effect:** Increases AOA size (+50px to +150px)
- **Agro Rate Modifier:** +0.5 to +2.0/sec when defending land claim
- **Purpose:** NPCs with high territorial trait are more defensive of their territory

**Protective Trait (0.0-1.0):**
- **Effect:** Increases agro rate when defending herd (+0.5 to +2.0/sec)
- **Purpose:** NPCs with high protective trait defend their herd more aggressively

**Greedy Trait (0.0-1.0):**
- **Effect:** Increases agro rate when valuable resources threatened (+0.3 to +1.5/sec)
- **Purpose:** NPCs with high greedy trait fight harder for resources

**Survivalist Trait (0.0-1.0):**
- **Effect:** Increases bravery decrease rate when low health (multiplier 1.2x to 1.5x)
- **Purpose:** NPCs with high survivalist trait flee sooner when injured (prioritize survival)

**Implementation:**
```gdscript
# Add to situational modifiers
var territorial_modifier = personality_traits.get("territorial", 0.5) * 2.0  # +0.0 to +2.0/sec when defending land claim
var protective_modifier = personality_traits.get("protective", 0.5) * 2.0  # +0.0 to +2.0/sec when defending herd
var greedy_modifier = personality_traits.get("greedy", 0.5) * 1.5  # +0.0 to +1.5/sec when resources threatened
var survivalist_modifier = personality_traits.get("survivalist", 0.5) * 0.3  # +0.0 to +0.3x multiplier to bravery decrease when low health
```

### Resource Node Competition

**Concept:** When two NPCs from different clans approach the same resource node, their agro meters rise, creating natural competition.

**Trigger:**
- NPC A approaches resource node
- NPC B (different clan) also approaches same resource node
- Both NPCs detect each other within AoP
- Agro meters start increasing for both

**Agro Rate Increase:**
- **Same resource, different clans:** +1.0 to +2.0/sec (based on resource scarcity)
- **Resource scarcity high:** Additional +0.5 to +1.0/sec
- **Result:** NPCs compete for resource, may enter combat if agro reaches 70

**Behavior:**
- NPCs continue gathering while agro rises
- If agro reaches 70 → Enter combat state
- Winner takes resource, loser may flee (if bravery hits 0)
- Creates dynamic resource competition without explicit rules

**Implementation:**
```gdscript
# In gather_state.gd or resource detection
func _check_resource_competition(resource_node: Node2D) -> void:
    var all_npcs = get_tree().get_nodes_in_group("npcs")
    for other_npc in all_npcs:
        if other_npc == self or not is_instance_valid(other_npc):
            continue
        if other_npc.get("clan_name") == clan_name:
            continue  # Same clan, no competition
        
        # Check if other NPC is also approaching same resource
        var other_target = other_npc.get("current_gather_target")
        if other_target == resource_node:
            var distance = global_position.distance_to(other_npc.global_position)
            if distance <= get_stat("perception") * 200.0:  # Within AoP
                # Both want same resource - increase agro rate
                var competition_rate = 1.5  # Base competition rate
                if resource_scarcity_high:
                    competition_rate += 1.0  # Higher when resources scarce
                agro_meter_rate += competition_rate
```

### Trait Evolution (Learning from Experience)

**Concept:** NPCs learn from combat experiences, affecting their bravery and future behavior.

**Bravery Changes from Combat:**
- **Win Fight (Enemy Defeated):** +0.05 to +0.15 bravery (confidence boost)
- **Lose Fight (Take Significant Damage):** -0.1 to -0.3 bravery (fear increase)
- **Successful Herd Defense:** +0.02 to +0.1 bravery (protective success)
- **Failed Herd Defense (Herd Stolen):** -0.1 to -0.2 bravery (failure)

**Trait Changes:**
- **Successful Territory Defense:** Territorial trait increases slightly (+0.01 to +0.05)
- **Successful Herd Defense:** Protective trait increases slightly (+0.01 to +0.05)
- **Repeated Failures:** Traits may decrease slightly (learned caution)

**Implementation:**
```gdscript
# After combat ends
func _on_combat_end(victory: bool, damage_taken: float) -> void:
    if victory:
        # Won fight - gain confidence
        bravery += randf_range(0.05, 0.15)
        bravery = clamp(bravery, 0.0, 1.0)
    else:
        # Lost fight - lose confidence
        bravery -= randf_range(0.1, 0.3)
        bravery = clamp(bravery, 0.0, 1.0)
    
    # If bravery hits 0, agro automatically drops to 0
    if bravery <= 0.0:
        bravery = 0.0
        agro_meter = 0.0
```

**Long-Term Impact:**
- NPCs that win fights become more confident (higher bravery)
- NPCs that lose fights become more cautious (lower bravery)
- Creates dynamic NPC personalities that evolve over time
- Successful defenders become more territorial/protective

### Alliance System (Future Consideration)

**Concept:** NPCs with similar traits or repeated positive interactions may form alliances.

**Alliance Benefits:**
- Allies don't trigger AOA (no agro when approaching)
- Allies coordinate defense (when one agro, nearby allies may also agro)
- Allies share resources more easily
- Creates faction-like behavior

**Alliance Formation:**
- NPCs with similar traits (bravery, territorial, protective) more likely to ally
- Repeated positive interactions (successful joint defense, resource sharing)
- Proximity (NPCs in same land claim or nearby)

**Future Implementation:**
- Track "relationship" value between NPCs
- Positive interactions increase relationship
- High relationship → Alliance formed
- Allies coordinate agro and defense

---

## Summary of Additional Ideas

**From Original FightOrFlightGuide:**

1. ✅ **Area of Agro (AOA)** - Enhanced detection zone with trait-based size modifiers
2. ✅ **Resource Scarcity Modifier** - Natural escalation as resources deplete
3. ✅ **Additional Personality Traits** - Territorial, Protective, Greedy, Survivalist
4. ✅ **Resource Node Competition** - Natural conflict when multiple NPCs want same resource
5. ✅ **Trait Evolution** - NPCs learn from combat experiences
6. 🔮 **Alliance System** - Future consideration for coordinated defense

**Integration with Current System:**
- All ideas enhance the agro meter system (rate modifiers)
- AOA integrates with existing "Enemy Near Land Claim" trigger
- Resource scarcity adds to situational modifiers
- Additional traits expand personality system beyond just bravery
- Trait evolution enhances dynamic bravery system
- Resource competition creates natural conflict without explicit rules

**Implementation Priority:**
1. **High:** Resource scarcity modifier (simple, high impact)
2. **High:** Resource node competition (creates natural conflict)
3. **Medium:** AOA with size modifiers (enhances detection)
4. **Medium:** Additional personality traits (expands system)
5. **Low:** Trait evolution (adds depth, but complex)
6. **Future:** Alliance system (requires relationship tracking)
