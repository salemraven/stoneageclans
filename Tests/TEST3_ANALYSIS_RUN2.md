# Test 3 Deep Analysis - Run 2

## Test Results Summary

**Duration:** 180 seconds (3 minutes)  
**Caveman:** NELI  
**Date:** 2026-01-10

---

## Key Metrics

### Herding Performance
- ✅ **7 herding attempts started** (improved from 4 in Run 1)
- ❌ **Only 1 NPC joined clan** (Sheep 2360) - **WORSE than Run 1** (which had 2)
- ❌ **1 herd broke** at 601.5px (still breaking just over 600px limit)
- ⚠️ **5/7 herdings by PLAYER, only 2/7 by AI caveman NELI**

### State Analysis
- **NELI entered `herd_wildnpc` state:** 1 time (entered at start, never exited)
- **Position logs for NELI in `herd_wildnpc`:** 0 (CRITICAL ISSUE)
- **Time in wander:** 11.7s initial, then entered gather briefly, then herd_wildnpc
- **State distribution:** Not tracked (no position logs while in herd_wildnpc)

### Comparison: Player vs AI Caveman
- **Player herded:** 5 NPCs (Goat 1659, Goat 1760, Woman 3, Woman 4, Woman 5)
- **AI NELI herded:** 2 NPCs (Sheep 2360 - twice, once broke, once succeeded)

---

## Critical Issues Identified

### 🔴 **Issue #1: AI Caveman Not Active in herd_wildnpc State**

**Problem:**
- NELI entered `herd_wildnpc` state once at the start
- **Zero position logs** while in `herd_wildnpc` state
- This suggests either:
  - State's `update()` method not running
  - Position logging not happening in this state
  - Caveman stuck immediately after state entry

**Evidence:**
- `STATE_ENTRY: NELI entered herd_wildnpc (from gather)`
- No `STATE_EXIT: NELI exited herd_wildnpc` found
- No position logs with `state=herd_wildnpc`
- Only 20 total position logs for NELI (all in wander state)

**Impact:**
- AI caveman essentially inactive
- Player doing 71% of herding work (5/7)
- Only 1 NPC joined clan vs 2 in previous test

### 🟡 **Issue #2: Herd Still Breaking at 600px Limit**

**Problem:**
- Sheep 2360 lost herder at **601.5px** (just barely over 600px)
- Same issue as Run 1 (600.3px, 600.8px)
- Break distance too strict for dynamic movement

**Evidence:**
- `NPC Sheep 2360 lost herder NPC (outside perception range: 601.5 >= 600.0)`
- Herding distances when started: 250-300px (good)
- Break happened during movement back to land claim

**Impact:**
- 1 herd broken (could have been 2 successful herds)

### 🟡 **Issue #3: AI Caveman Less Effective Than Player**

**Problem:**
- AI caveman (NELI) only responsible for 2 herding events
- Player responsible for 5 herding events
- This suggests AI detection/approach logic needs work

**Possible Causes:**
- Detection range too small
- Target selection not optimal
- Movement speed/pathfinding issues
- State not actually executing (Issue #1)

---

## Detailed Analysis

### NELI State Timeline

1. **Wander (11.7s)** - Initial wander after spawn
2. **Gather (0.2s)** - Brief gather state
3. **herd_wildnpc (remainder of test)** - Entered but no activity logs
   - No position updates
   - No state exit
   - No target tracking
   - No movement visible

### Player Herding Activity

Player successfully herded:
1. Goat 1659 (299.5px distance, 15.1% chance)
2. Goat 1760 (279.2px distance, 18.8% chance)
3. Woman 3 (297.0px distance, 15.5% chance)
4. Woman 4 (292.6px distance, 16.4% chance)
5. Woman 5 (271.7px distance, 20.2% chance)

All at reasonable distances (250-300px).

### AI NELI Herding Activity

NELI herded:
1. Sheep 2360 (263.5px distance, 21.7% chance) → **BROKE at 601.5px**
2. Sheep 2360 (250.3px distance, 24.1% chance) → **SUCCESS, joined clan**

---

## Root Causes

### Why NELI Isn't Active

**Theory 1: State Update Not Running**
- `herd_wildnpc.update()` may not be called
- FSM might not be properly updating states
- Position logging might not be triggered

**Theory 2: No Targets Found**
- `can_enter()` passed (state entered)
- But `_find_woman_to_herd()` returns no targets
- Caveman stuck waiting for timeout (currently 20s doubled = 40s)
- Position logging may be skipped when no target

**Theory 3: Position Logging Location**
- Position logs might only happen in certain states
- `herd_wildnpc` state might not trigger position logging
- Need to check where position logging occurs

### Why Herds Break at 600px

**Theory:**
- Caveman moves too fast when leading
- Wild NPC can't keep up
- Distance grows from 250-300px to 600px+
- No catch-up mechanism
- Break happens immediately at 600px threshold

---

## Recommendations

### Priority 1: Fix AI Caveman Inactivity 🔴 CRITICAL

**1. Add Debug Logging to herd_wildnpc State**
```gdscript
func update(_delta: float) -> void:
    print("🔵 HERD_WILDNPC UPDATE: %s - target=%s, no_target_time=%.1f" % [
        npc.npc_name, 
        target_woman.get("npc_name") if target_woman else "none",
        no_target_time
    ])
    # ... existing code ...
```

**2. Verify FSM Update Loop**
- Check if `fsm.update()` is being called
- Verify state machine is processing states correctly

**3. Add Position Logging in herd_wildnpc**
- Force position logs every frame or every 0.5s
- Log even when no target (for debugging)

**4. Check Target Detection**
- Log when `_find_woman_to_herd()` is called
- Log what targets are found (if any)
- Log why targets are rejected

### Priority 2: Increase Herd Break Distance 🟡 HIGH

**Implementation:**
```gdscript
# npc_config.gd
@export var herd_max_distance_before_break: float = 800.0  # Increased from 600.0
```

**Also add catch-up speed boost:**
```gdscript
# herd_state.gd
if distance_to_herder > 400.0:
    # Boost speed to catch up
    npc.steering_agent.max_speed = base_speed * 1.3  # 30% faster
```

### Priority 3: Improve AI Detection & Movement 🟡 MEDIUM

**1. Increase detection range when searching**
- Current: 1500px
- Recommended: 2000px for initial search

**2. Faster spiral expansion**
- Current: 50px per rotation
- Recommended: 100px per rotation

**3. Better target prioritization**
- Prioritize closer targets
- Consider movement direction
- Avoid targets already herded by others (unless stealing)

---

## Expected Improvements After Fixes

1. **AI Activity:**
   - Position logs in `herd_wildnpc` state visible
   - NELI actively searching and herding
   - 5-7 NPCs herded by AI (matching player performance)

2. **Herd Success Rate:**
   - Break distance increased → fewer breaks
   - Catch-up speed → herds stay together
   - Success rate: 1/2 → 8/10 (80%+)

3. **Overall Performance:**
   - NPCs joined: 1 → 4-6 per 3 min
   - AI vs Player: 2 vs 5 → 5-7 vs 5-7 (balanced)

---

## Next Steps

1. **Add comprehensive logging** to `herd_wildnpc.update()`
2. **Run another test** to see if logging reveals the issue
3. **Fix herd break distance** (800px + catch-up speed)
4. **Verify FSM update loop** is working correctly
5. **Compare AI vs Player detection ranges** (why is player more effective?)

---

## Comparison: Run 1 vs Run 2

| Metric | Run 1 (YUJI) | Run 2 (NELI) | Change |
|--------|--------------|--------------|--------|
| Herdings started | 4 | 7 | ✅ +75% |
| NPCs joined clan | 2 | 1 | ❌ -50% |
| Herds broken | 2 | 1 | ✅ +50% |
| AI caveman active | Yes (4 entries) | No (1 entry, inactive) | ❌ |
| Wander time | 80.5s (44%) | Unknown | ❓ |
| Break distance | 600.3px, 600.8px | 601.5px | Same issue |

**Overall:** Run 2 shows more herding attempts but worse completion rate. AI caveman appears inactive.

---

**Analysis Date:** 2026-01-10  
**Test Log:** `/Users/macbook/Desktop/stoneageclans/Tests/test3_herding_system.log`
