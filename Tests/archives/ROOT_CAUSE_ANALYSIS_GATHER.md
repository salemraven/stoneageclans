# Root Cause Analysis - Gather System Issues
**Date**: January 9, 2026  
**Test**: Test 3 - Gather/Deposit Efficiency

## Root Causes Identified

### Root Cause #1: FSM Forces Idle When No State Can Enter 🔴 CRITICAL

**Location**: `scripts/npc/fsm.gd:300-302`

**Problem**:
```gdscript
if not has_higher_priority:
    change_state("idle")  # ← FORCES IDLE!
    return
```

**Issue**: 
- If no state has priority > 2.0, FSM forces idle state
- This happens even when gather/wander are blocked
- Cavemen end up in idle despite priority = 0.0 for cavemen

**Impact**: 
- NPCs spend 19+ cycles in idle state
- Blocks productivity (cavemen should never idle)
- Causes 4+ second idle periods

**Fix**: Don't force idle for cavemen - force wander instead

---

### Root Cause #2: Wander State Blocks Entry When Inventory Full 🔴 CRITICAL

**Location**: `scripts/npc/states/wander_state.gd:140-146`

**Problem**:
```gdscript
# CRITICAL FIX: Cavemen with full inventory (70%+) should NOT wander - they should deposit
if npc_type_str == "caveman" and npc.inventory:
    if inventory_percent >= 0.7:  # 70%+ full
        return false  # ← BLOCKS WANDER!
```

**Issue**: 
- When inventory is 70%+ full, wander state blocks entry
- But wander state is needed to HANDLE deposit movement!
- Gather state also blocks entry at 70%+
- Result: NO state can enter → FSM forces idle

**Impact**:
- NPCs can't move to deposit when inventory full
- Get stuck in idle state
- Deposit movement never happens

**Fix**: Wander state should ALWAYS allow entry for cavemen (it handles deposit movement)

---

### Root Cause #3: Conflicting Logic - Deposit Movement vs Gather Block 🔴 CRITICAL

**Current Logic Conflict**:
1. Gather state blocks entry if inventory 70%+ full ✅ (correct - should deposit)
2. Wander state blocks entry if inventory 70%+ full ❌ (WRONG - needed for deposit movement!)
3. FSM forces idle if no state can enter ❌ (WRONG - should force wander for cavemen)

**Result**: 
- When inventory full: Gather blocked ✅, Wander blocked ❌, Idle forced ❌
- NPC stuck in idle, can't deposit

**Fix**: 
- Gather: Block at 70%+ (correct - keep this)
- Wander: ALWAYS allow for cavemen (needed for deposit movement)
- FSM: Force wander (not idle) for cavemen

---

## Code Simplification Recommendations

### Simplification #1: Remove Idle Fallback for Cavemen ✅ HIGH PRIORITY

**Current** (fsm.gd:300-302):
```gdscript
if not has_higher_priority:
    change_state("idle")  # Forces idle
    return
```

**Simplified**:
```gdscript
# Don't force idle for cavemen - force wander instead (cavemen should always be productive)
var npc_type_str: String = npc.get("npc_type") if npc else ""
if not has_higher_priority:
    if npc_type_str == "caveman":
        # Cavemen should always wander (productivity requirement)
        if _get_state("wander") and _get_state("wander").can_enter():
            change_state("wander")
            return
    else:
        # Other NPCs can idle
        change_state("idle")
    return
```

**Benefits**:
- Cavemen never idle (always productive)
- Simple check in one place
- Clear priority: wander > idle for cavemen

---

### Simplification #2: Always Allow Wander Entry for Cavemen ✅ HIGH PRIORITY

**Current** (wander_state.gd:140-146):
```gdscript
# CRITICAL FIX: Cavemen with full inventory (70%+ full) should NOT wander - they should deposit
if npc_type_str == "caveman" and npc.inventory:
    if inventory_percent >= 0.7:
        return false  # Blocks wander
```

**Problem**: Blocks wander when it's needed for deposit movement!

**Simplified**:
```gdscript
# Cavemen can ALWAYS wander - wander state handles deposit movement when inventory full
if npc_type_str == "caveman":
    return true  # Always allow wander (handles deposit movement internally)
```

**Benefits**:
- Simple: Always allow wander for cavemen
- Wander state already handles deposit movement logic internally
- No conflicts with gather state blocking

---

### Simplification #3: Remove Complex Inventory Check from Wander can_enter() ✅ MEDIUM PRIORITY

**Current**: Complex inventory check in can_enter() that blocks entry

**Simplified**: Remove the check entirely - let wander state handle it in update()

**Reasoning**:
- Wander state already checks inventory in update() and moves to deposit
- can_enter() should be simple (just check if NPC type can wander)
- Complex logic belongs in update(), not can_enter()

**Benefits**:
- Simpler can_enter() (fewer conditions)
- Logic in right place (update() handles behavior)
- Fewer edge cases

---

### Simplification #4: Remove Random Idle Chance ✅ LOW PRIORITY

**Current** (idle_state.gd:135-136):
```gdscript
if randf() < 0.05:  # 5% chance to force idle
    return 0.5  # Slightly higher priority to allow idle breaks
```

**Issue**: Adds randomness and complexity

**Simplified**: Remove random chance - deterministic behavior

**Benefits**:
- More predictable
- Easier to debug
- Simpler code

---

## Implementation Priority

### Critical Fixes (Must Do Now) 🔴
1. ✅ Remove wander block when inventory full (allows deposit movement)
2. ✅ Remove idle fallback for cavemen (force wander instead)
3. ✅ Always allow wander entry for cavemen

### High Priority Simplifications 🟠
4. ✅ Remove complex inventory check from wander can_enter()
5. ✅ Simplify wander can_enter() logic

### Medium Priority 🟡
6. ⚠️ Remove random idle chance
7. ⚠️ Add better logging for state transitions

---

## Expected Impact After Fixes

### Before Fixes:
- **Idle Cycles**: 19+ times in 5 minutes
- **Gather Rate**: 9 gathers in 5 minutes (very low)
- **Productivity**: ~30% (spending 70% time in idle/wander cycles)

### After Fixes:
- **Idle Cycles**: 0 times (cavemen never idle)
- **Gather Rate**: 30-50 gathers in 5 minutes (expected)
- **Productivity**: ~90% (always gathering or depositing)

### Improvement:
- **3-5x more productive** (no idle blocking)
- **Consistent gather/deposit cycles**
- **No stuck states**

---

## Code Changes Required

### File 1: `scripts/npc/states/wander_state.gd`
- Remove inventory check from can_enter() (line 140-146)
- Always return true for cavemen
- Keep deposit movement logic in update()

### File 2: `scripts/npc/fsm.gd`
- Remove idle fallback for cavemen (line 300-302)
- Force wander instead of idle for cavemen
- Keep idle fallback for other NPC types

### File 3: `scripts/npc/states/idle_state.gd`
- Already has priority = 0.0 for cavemen ✅ (working)
- Could remove random chance (optional)

---

## Testing Plan

1. Run test 3 again after fixes
2. Verify: No idle state entries for cavemen
3. Verify: Consistent gather/deposit cycles
4. Verify: Inventory never reaches 10/10
5. Verify: Gather rate improves (30+ gathers in 5 minutes)
