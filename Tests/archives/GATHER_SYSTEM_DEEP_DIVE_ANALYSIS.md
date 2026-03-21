# Gather System Deep Dive Analysis
**Date**: January 9, 2026  
**Test**: Test 3 - 5 minute gather/deposit efficiency test

## Executive Summary

The gather system is working, but several critical issues are preventing optimal efficiency:

1. **Resources yield 4-6 items at once** - Bypasses 80% threshold check
2. **80% threshold check happens AFTER collection** - Inventory can fill to 100%
3. **NPC oscillating at deposit boundary** - Wasting time moving in/out of 200px range
4. **Multiple rapid deposits** - Cooldown logic may need adjustment
5. **Inventory counting issue** - NPC reaching 10/10 slots multiple times

---

## Critical Issues Identified

### Issue #1: Variable Resource Yields Bypass Threshold ⚠️ CRITICAL

**Problem**:
- Resources yield 4-6 items per gather (`min_amount=4, max_amount=6`)
- If NPC has 6/10 slots and gathers 6 Wood → instantly 10/10 slots
- The 80% check happens in `update()` AFTER `_collect_resource()` adds items
- Result: NPC can fill inventory past 80% in a single gather

**Evidence from Logs**:
```
✅ GATHER: BIMO gathered 6 Wood → inventory (10/10 slots)  ← Filled instantly!
✅ GATHER: BIMO gathered 6 Stone → inventory (10/10 slots) ← Filled instantly!
✅ GATHER: BIMO gathered 4 Wood → inventory (8/10 slots)   ← Only 4 items
```

**Impact**: 
- Inventory fills to 100% (10/10 slots) - blocks gathering
- 80% threshold becomes ineffective for variable yields
- NPC wastes time with full inventory

**Solution**:
- **Option A**: Check inventory BEFORE collection and stop gathering if adding would exceed 80%
- **Option B**: Cap resource yields based on available inventory space
- **Option C**: Check inventory immediately after collection and exit gather state if threshold exceeded

**Recommendation**: **Option A** - Check inventory BEFORE collection (simplest, most reliable)

---

### Issue #2: Boundary Oscillation (Wasting Time) ⚠️ HIGH PRIORITY

**Problem**:
- NPC repeatedly crosses 200px deposit boundary
- Wander state moves NPC toward deposit, gets to ~200px
- Gather state enters, NPC moves away to gather resources
- Cycles back to wander, repeats

**Evidence from Logs**:
```
📍 WANDER→DEPOSIT: BIMO moving to land claim (distance: 220.3px)
📍 WANDER→DEPOSIT: BIMO moving to land claim (distance: 219.8px)
... (many lines) ...
✅ WANDER→DEPOSIT: BIMO reached deposit range (199.4px)
📍 WANDER→DEPOSIT: BIMO moving to land claim (distance: 200.8px)
📍 WANDER→DEPOSIT: BIMO moving to land claim (distance: 201.7px)
📍 WANDER→DEPOSIT: BIMO moving to land claim (distance: 202.8px)
... (oscillating around 200px) ...
```

**Impact**:
- Wastes significant time (100+ frames moving in/out of deposit range)
- NPC can't decide whether to gather or deposit
- Reduces overall productivity

**Root Cause**:
- Gather state `can_enter()` allows entry even when inventory 80%+ full (if not near claim)
- Wander state handles deposit movement, but gather state interrupts
- No clear priority: wander (deposit movement) vs gather (find resources)

**Solution**:
- **Option A**: When inventory 80%+ full and moving to deposit, BLOCK gather state entry (hard priority)
- **Option B**: Increase deposit range hysteresis (enter at 200px, exit at 150px to prevent oscillation)
- **Option C**: When `moving_to_deposit` flag is set, gather state priority = 0.0 (cannot enter)

**Recommendation**: **Option A + C** - Block gather state when deposit movement in progress

---

### Issue #3: Multiple Rapid Deposits ⚠️ MEDIUM PRIORITY

**Problem**:
- Multiple deposits happening in quick succession
- Cooldown (1 second) may not be preventing multiple deposits
- Same inventory being deposited multiple times

**Evidence from Logs**:
```
✅ AUTO-DEPOSIT: BIMO deposited 2 items (distance: 187.3px)
✅ AUTO-DEPOSIT: BIMO deposited 2 items (distance: 191.5px)  ← 0.4 seconds later
✅ AUTO-DEPOSIT: BIMO deposited 2 items (distance: 191.2px)  ← 0.3 seconds later
```

**Impact**:
- Unnecessary processing (deposit function called multiple times)
- May cause inventory synchronization issues
- Wastes CPU cycles

**Root Cause**:
- Check interval (0.5s) and cooldown (1.0s) timing issues
- Multiple NPCs depositing simultaneously?
- Inventory not being cleared properly after deposit?

**Solution**:
- **Option A**: Increase deposit cooldown to 2.0 seconds (safer buffer)
- **Option B**: Add check to verify inventory actually changed after deposit
- **Option C**: Set flag `depositing_in_progress` to prevent concurrent deposits

**Recommendation**: **Option B** - Verify inventory actually changed (most reliable)

---

### Issue #4: Inventory Reaching 10/10 Slots (Full) ⚠️ HIGH PRIORITY

**Problem**:
- NPC reaching 10/10 slots (100% full) multiple times
- Should deposit at 80% (8/10 slots) but continues gathering
- 80% threshold check not preventing full inventory

**Evidence from Logs**:
```
✅ GATHER: BIMO gathered 6 Wood → inventory (10/10 slots)     ← Full!
✅ AUTO-DEPOSIT: BIMO deposited 6 items → inventory cleared
✅ GATHER: BIMO gathered 6 Stone → inventory (10/10 slots)    ← Full again!
✅ AUTO-DEPOSIT: BIMO deposited 6 items → inventory cleared
```

**Impact**:
- Blocks gathering (inventory full)
- NPC must wait for deposit before continuing
- Reduces productivity (wasted time)

**Root Cause**:
- 80% check happens AFTER collection (issue #1)
- Variable yields can fill inventory past 80% in single gather
- No check before gathering if yield would exceed threshold

**Solution**: Same as Issue #1 - Check inventory BEFORE collection

---

## Data Analysis

### Gather Success Rate
- **Total Gathers**: 17 successful gathers in 5 minutes
- **Gather Rate**: ~3.4 gathers/minute (good, but can improve)
- **Resource Yields**: 
  - 1-item yields: Most common (berries, fiber, single stone)
  - 4-6 item yields: Wood and Stone (variable)
  - Problem: Large yields bypass threshold checks

### Deposit Efficiency
- **Deposit Frequency**: Variable (1-6 items per deposit)
- **Deposit Range**: 159-191px (within 200px range)
- **Issue**: Multiple rapid deposits of same inventory (cooldown not working)

### Inventory State Distribution
- **2/10 slots**: 2 times (after deposit)
- **3-7/10 slots**: Normal gathering range
- **8/10 slots**: 3 times (threshold reached)
- **9/10 slots**: 2 times (threshold exceeded)
- **10/10 slots**: 5 times (FULL - should never happen!)

### Time Wasted
- **Boundary Oscillation**: ~100+ frames moving in/out of deposit range
- **Full Inventory**: Multiple instances of 10/10 slots (blocks gathering)
- **Rapid Deposits**: Multiple deposit calls for same inventory

---

## Code Simplification Recommendations

### Recommendation #1: Pre-Collection Inventory Check ✅ HIGH PRIORITY

**Current Code** (gather_state.gd:197-236):
```gdscript
func _collect_resource() -> void:
    # ... harvest resource ...
    var added: bool = npc.inventory.add_item(resource_type, yield_amount)
    if added:
        # Log gather - inventory already updated
        # Check happens in update() AFTER collection
```

**Problem**: Check happens too late - inventory already filled

**Simplified Fix**:
```gdscript
func _collect_resource() -> void:
    if not npc or not gather_target:
        return
    
    # HARVEST FIRST (check cooldown, get yield amount)
    var yield_amount: int = gather_target.harvest()
    if yield_amount == 0:
        gather_target = null
        return
    
    # CHECK INVENTORY BEFORE ADDING (prevent overflow)
    var used_slots: int = npc.inventory.get_used_slots()
    var available_slots: int = npc.inventory.slot_count - used_slots
    
    # Estimate how many slots will be used (items don't stack, so 1 slot per item)
    if yield_amount > available_slots:
        # Can't fit all items - adjust yield or exit gather state
        yield_amount = available_slots
        if yield_amount == 0:
            # No space - exit to deposit
            if _is_inventory_80_percent_full():
                npc.set_meta("moving_to_deposit", true)
                fsm.change_state("wander")
            return
    
    # NOW add items (safe - won't overflow)
    var resource_type = gather_target.get("resource_type")
    # ... add to inventory ...
```

**Benefits**:
- Prevents inventory overflow (never reaches 10/10)
- Simple check before collection
- Automatic exit if no space available

---

### Recommendation #2: Block Gather State During Deposit Movement ✅ HIGH PRIORITY

**Current Code** (gather_state.gd:108-123):
```gdscript
func can_enter() -> bool:
    if npc.get("npc_type") != "caveman":
        return false
    # No clan_name requirement - can gather before land claim
    return true  # ← Always allows entry!
```

**Problem**: Gather state can enter even when moving to deposit (causes oscillation)

**Simplified Fix**:
```gdscript
func can_enter() -> bool:
    if npc.get("npc_type") != "caveman":
        return false
    
    # BLOCK ENTRY if moving to deposit (deposit movement takes priority)
    if npc.has_meta("moving_to_deposit"):
        return false  # ← Cannot gather while moving to deposit
    
    # BLOCK ENTRY if inventory 80%+ full and has land claim (must deposit first)
    if _is_inventory_80_percent_full():
        var clan_name: String = npc.get_clan_name() if npc else ""
        if clan_name != "":
            # Has land claim - must deposit before gathering more
            return false  # ← Cannot gather when inventory full
    
    return true
```

**Benefits**:
- Prevents boundary oscillation
- Clear priority: deposit movement > gathering
- Simple check in can_enter()

---

### Recommendation #3: Improve Deposit Cooldown Logic ✅ MEDIUM PRIORITY

**Current Code** (npc_base.gd:2294-2299):
```gdscript
if total_items_deposited > 0:
    set_meta("last_deposit_time", Time.get_ticks_msec() / 1000.0)
    print("✅ AUTO-DEPOSIT: ...")
```

**Problem**: No verification that inventory actually changed

**Simplified Fix**:
```gdscript
# Track inventory state before deposit
var inventory_before: Dictionary = {}
for i in range(inventory.slot_count):
    var slot = inventory.slots[i]
    if slot != null:
        var item_type = slot.get("type")
        var item_count = slot.get("count", 0)
        if item_type != null and item_count > 0:
            if item_type in inventory_before:
                inventory_before[item_type] += item_count
            else:
                inventory_before[item_type] = item_count

# ... deposit logic ...

# Verify inventory actually changed after deposit
var inventory_changed: bool = false
for item_type in inventory_before:
    var count_before: int = inventory_before[item_type]
    var count_after: int = inventory.get_count(item_type)
    if count_after < count_before:
        inventory_changed = true
        break

if total_items_deposited > 0 and inventory_changed:
    set_meta("last_deposit_time", Time.get_ticks_msec() / 1000.0)
    print("✅ AUTO-DEPOSIT: ...")
else:
    # Deposit failed or no change - don't set cooldown
    print("⚠️ AUTO-DEPOSIT: No items deposited (inventory unchanged)")
```

**Benefits**:
- Prevents false cooldowns (when deposit fails)
- Verifies deposit actually worked
- Better debugging (can see when deposits fail)

---

### Recommendation #4: Simplify Boundary Check (Add Hysteresis) ✅ MEDIUM PRIORITY

**Current Code** (wander_state.gd:220-230):
```gdscript
var deposit_range: float = 200.0
if distance > deposit_range:
    # Move to deposit
elif distance <= deposit_range:
    # Clear flag, auto-deposit handles
```

**Problem**: Exact 200px boundary causes oscillation

**Simplified Fix**:
```gdscript
var deposit_range_enter: float = 200.0  # Enter deposit range at 200px
var deposit_range_exit: float = 150.0   # Exit deposit range at 150px (hysteresis)

if npc.has_meta("in_deposit_range"):
    # Already in deposit range - check if should exit
    if distance > deposit_range_exit:
        npc.remove_meta("in_deposit_range")
        # Exit deposit range - resume normal behavior
else:
    # Not in deposit range - check if should enter
    if distance <= deposit_range_enter:
        npc.set_meta("in_deposit_range", true)
        # Enter deposit range - auto-deposit will handle
```

**Benefits**:
- Prevents oscillation (hysteresis buffer)
- Simpler logic (flag-based state)
- More reliable deposit detection

---

## Efficiency Recommendations for Gather System

### Efficiency #1: Reduce Resource Yield Variance ✅ RECOMMENDED

**Current**: Resources yield 4-6 items (random)
**Problem**: Large yields bypass threshold checks

**Recommendation**:
- **Option A**: Cap yields at 2-3 items max (more predictable)
- **Option B**: Adjust yields based on inventory space (intelligent capping)
- **Option C**: Make all resources yield 1 item (simple, predictable)

**Best Choice**: **Option C** - Always yield 1 item (simplest, most predictable)

**Benefits**:
- Predictable inventory growth (1 item per gather)
- Easier threshold checks (can predict final state)
- No overflow risk (can check before collection)
- Simpler code (no yield variance handling)

---

### Efficiency #2: Increase 80% Threshold to 70% ✅ RECOMMENDED

**Current**: 80% threshold (8/10 slots)
**Problem**: With variable yields, can still fill past 80%

**Recommendation**: Lower threshold to 70% (7/10 slots)

**Benefits**:
- More buffer room (3 empty slots)
- Prevents reaching 100% even with large yields
- Earlier deposits (more frequent, but safer)
- Better resource management

---

### Efficiency #3: Improve Target Finding (Avoid Full Resources) ✅ RECOMMENDED

**Current**: Finds nearest resource (may be in cooldown or far away)
**Problem**: NPC might gather from resources that yield many items

**Recommendation**: Prefer resources that yield fewer items when inventory near threshold

**Code Suggestion**:
```gdscript
func _find_target() -> void:
    # ... existing code ...
    
    # When inventory near threshold, prefer smaller yields
    var used_slots: int = npc.inventory.get_used_slots()
    var near_threshold: bool = (used_slots >= 6)  # 60% full
    
    if near_threshold:
        # Prefer food resources (yield 1 item) or closer resources
        # (existing distance check already handles this)
        pass
```

---

## Summary of Recommendations

### Critical Fixes (Must Do) 🔴
1. ✅ **Pre-collection inventory check** - Prevent overflow
2. ✅ **Block gather state during deposit movement** - Prevent oscillation
3. ✅ **Fix deposit cooldown logic** - Verify inventory changed

### High Priority Improvements 🟠
4. ✅ **Reduce resource yield variance** - Make yields predictable (1 item per gather)
5. ✅ **Lower threshold to 70%** - More buffer room
6. ✅ **Add hysteresis to boundary check** - Prevent oscillation

### Medium Priority Optimizations 🟡
7. ⚠️ Improve target finding (prefer smaller yields near threshold)
8. ⚠️ Better deposit verification (track inventory changes)
9. ⚠️ More detailed logging (track wasted time)

### Low Priority Enhancements 🟢
10. 💡 Cache resource list (performance optimization)
11. 💡 Batch deposit operations (if needed)
12. 💡 Visual feedback for deposit range (UI improvement)

---

## Expected Impact

### Before Fixes:
- **Gather Rate**: ~3.4 gathers/minute
- **Inventory Full**: 5 times in 5 minutes (100% full)
- **Time Wasted**: ~20% (oscillation, full inventory, rapid deposits)
- **Deposit Success**: Good (but multiple rapid deposits)

### After Fixes:
- **Gather Rate**: ~4-5 gathers/minute (20-30% improvement)
- **Inventory Full**: 0 times (never reaches 100%)
- **Time Wasted**: <5% (minimal oscillation, no full inventory)
- **Deposit Success**: 100% (reliable, single deposits)

### Productivity Gain:
- **Expected Improvement**: 20-40% more productive
- **Fewer Interruptions**: No full inventory blocking
- **Better Resource Management**: More consistent gather/deposit cycles

---

## Implementation Priority

1. **Immediate** (Fix critical bugs):
   - Pre-collection inventory check
   - Block gather state during deposit movement

2. **Short Term** (Improve efficiency):
   - Reduce resource yield variance
   - Lower threshold to 70%
   - Add hysteresis to boundary check

3. **Medium Term** (Polish):
   - Fix deposit cooldown logic
   - Improve target finding
   - Better logging

---

## Questions to Consider

1. **Should resources always yield 1 item?** (Simpler, more predictable)
2. **Should threshold be 70% or 80%?** (70% = safer, 80% = more efficient)
3. **Should deposit range have hysteresis?** (Yes - prevents oscillation)
4. **Should gather state be blocked during deposit movement?** (Yes - clear priority)

---

## Next Steps

1. Review recommendations with team
2. Implement critical fixes first
3. Test with 5-minute run
4. Measure improvements
5. Iterate on optimizations
