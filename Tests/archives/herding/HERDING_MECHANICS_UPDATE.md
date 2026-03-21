# Herding Mechanics Update - "Capturing" & Proximity-Based Protection

## Summary

Updated herding mechanics to simulate "capturing" wild NPCs and add proximity-based protection for stealing.

---

## Changes Made

### 1. **Initial Herding Range: 300px → 150px** ✅

**File:** `scripts/npc/states/herd_wildnpc_state.gd`
- `herding_range`: 300.0 → 150.0
- Caveman must get **closer** to initiate follow (simulates "capturing")
- Comment added: "Must get close to 'capture'"

**File:** `scripts/npc/npc_base.gd`
- `max_range` in `_try_herd_chance()`: 300.0 → 150.0
- Herding only works within 150px (was 300px)

**Rationale:** Caveman must get close to "capture" the wild NPC, making it feel more like an active interaction.

---

### 2. **Follow Distance While Leading: 50-300px → 50-150px** ✅

**Files:**
- `scripts/npc/states/herd_wildnpc_state.gd` (caveman leading logic)
- `scripts/npc/states/herd_state.gd` (NPC following logic)
- `scripts/config/npc_config.gd` (config values)

**Changes:**
- `distance_max`: 300.0 → 150.0
- `ideal_distance`: 175px → 100px (middle of 50-150px range)
- NPCs follow **closer** to the caveman while he's leading to claim

**Rationale:** Tighter herd = easier to protect, harder to steal.

---

### 3. **Stealing Requires Very Close Proximity** ✅

**File:** `scripts/npc/npc_base.gd`

**New Logic:**
- Stealer must be **closer** than current herder to even attempt steal
- Stealer must be within **100px** to steal effectively
- Chance heavily reduced (up to 80%) if stealer is 100-150px away

**Code:**
```gdscript
# Stealer must be closer than herder
if distance >= herder_distance:
    return false  # Can't steal if not closer

# Must be very close to steal effectively
var steal_close_range: float = 100.0
if distance > steal_close_range:
    # Heavily reduce chance if not very close
    var distance_penalty: float = (distance - steal_close_range) / (max_range - steal_close_range)
    chance *= (1.0 - distance_penalty * 0.8)  # Reduce by up to 80%
```

**Rationale:** Stealing requires getting **very close** to the NPC, making it a risky maneuver.

---

### 4. **Proximity-Based Protection** ✅

**File:** `scripts/npc/npc_base.gd`

**New Logic:**
- Base steal chance: **50% → 25%** of normal (much harder)
- If herder is within **150px** of the NPC, stealing becomes **much harder**
- Protection factor: 0.1x to 1.0x based on herder distance
  - Herder at 0px: 0.1x chance (very hard to steal)
  - Herder at 150px: 1.0x chance (normal steal difficulty)

**Code:**
```gdscript
# Base steal chance is much lower (25% of normal)
chance *= 0.25

# PROXIMITY-BASED PROTECTION
var protection_distance: float = 150.0
if herder_distance < protection_distance:
    # Protection multiplier: 0.1x to 1.0x based on distance
    var protection_factor: float = herder_distance / protection_distance
    chance *= (0.1 + 0.9 * protection_factor)  # Range: 0.1x to 1.0x
```

**Rationale:** **Being close to your herd protects it** - simulates active defense.

---

### 5. **Updated Chance Values** ✅

**File:** `scripts/npc/npc_base.gd`

**Changes:**
- `base_chance`: 0.15 (15%) → 0.10 (10%) at max range (150px)
- `max_chance`: 0.70 (70%) → 0.80 (80%) at very close range (<50px)

**Rationale:** Higher chance when very close, but must get closer (150px vs 300px).

---

## New Mechanics Flow

### Initial Herding (Capturing):
1. Caveman approaches wild NPC
2. Must get within **150px** to attempt herding (was 300px)
3. Chance: 10% at 150px, up to 80% at <50px
4. Once herded, NPC starts following

### Following (While Leading):
1. NPC follows at **50-150px** distance (was 50-300px)
2. Ideal distance: **100px** (was 175px)
3. Tighter herd = easier to protect

### Stealing:
1. Stealer must be **closer than herder** to attempt
2. Stealer must be within **100px** for good chance
3. Base steal chance: **25% of normal** (was 50%)
4. If herder is **close (<150px)**, steal chance is **0.1x to 1.0x** based on distance
   - Herder at 0px: **0.1x** (very hard)
   - Herder at 150px: **1.0x** (normal)
5. If stealer is 100-150px away, chance reduced by up to **80%**

### Protection Strategy:
- **Stay close to your herd** (<150px) to protect it
- Protection scales: closer = better protection
- Enemy must get **very close** (<100px) and be **closer than you** to steal

---

## Expected Behavior

1. **Initial Herding:** Caveman must get close (150px) to "capture" wild NPC
2. **Following:** NPCs follow closer (50-150px) while being led to claim
3. **Stealing:** 
   - Requires getting very close (<100px)
   - Must be closer than current herder
   - Much harder if herder is close (<150px)
4. **Protection:** Staying close to your herd protects it from theft

---

## Testing Recommendations

1. **Single Caveman:**
   - Verify caveman must get within 150px to herd
   - Verify NPCs follow at 50-150px distance
   
2. **Multi-Caveman (Future):**
   - Test stealing requires getting very close (<100px)
   - Test protection: close herder = harder to steal
   - Test: stealer must be closer than herder

---

**Update Date:** 2026-01-10  
**Status:** ✅ All changes implemented
