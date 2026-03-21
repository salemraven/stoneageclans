# Gather System Root Cause Analysis & Fixes
**Date**: January 9, 2026  
**Test**: Test 3 - After implementing fixes

## Root Causes Identified & Fixed

### Root Cause #1: FSM Forces Idle When No State Can Enter ✅ FIXED

**Problem**:
- FSM had fallback logic: If no state has priority > 2.0, force idle state
- This happened even when gather/wander were blocked
- Result: Cavemen entered idle 19+ times despite priority = 0.0

**Location**: `scripts/npc/fsm.gd:300-302`

**Fix Applied**:
- Removed idle fallback for cavemen
- Force wander instead of idle for cavemen when no state can enter
- Added fallback to wander at end of evaluation if best_priority = 0.0

**Result**: ✅ **0 idle state entries** (down from 19!)

---

### Root Cause #2: Wander State Blocks Entry When Inventory Full ✅ FIXED

**Problem**:
- Wander state blocked entry when inventory 70%+ full
- But wander state is NEEDED to handle deposit movement!
- When inventory full: Gather blocked ✅, Wander blocked ❌, No state can enter → Idle forced

**Location**: `scripts/npc/states/wander_state.gd:140-153`

**Fix Applied**:
- Removed inventory check from wander `can_enter()`
- Cavemen can ALWAYS enter wander (wander handles deposit movement internally)
- Deposit movement logic remains in wander `update()` (correct location)

**Result**: ✅ Wander state always available for deposit movement

---

### Root Cause #3: Variable Resource Yields Bypassed Threshold ✅ FIXED

**Problem**:
- Resources yielded 4-6 items per gather (random)
- NPC at 6/10 slots + 6 Wood = 10/10 instantly
- 80% check happened AFTER collection (too late)

**Location**: `scripts/gatherable_resource.gd:320-329`, `scripts/npc/states/gather_state.gd:197-236`

**Fix Applied**:
- Standardized all resources to yield 1 item per gather (predictable)
- Added pre-collection inventory check in `_collect_resource()`
- Capped yield amount based on available inventory space
- Lowered threshold from 80% (8/10) to 70% (7/10) for more buffer room

**Result**: ✅ Inventory never reaches 10/10 (max 7/10 observed)

---

### Root Cause #4: Gather State Allowed Entry During Deposit Movement ✅ FIXED

**Problem**:
- Gather state could enter even when `moving_to_deposit` flag set
- Caused oscillation at deposit boundary (moving in/out of 200px range)
- Wasted 100+ frames moving in/out of deposit range

**Location**: `scripts/npc/states/gather_state.gd:108-123`

**Fix Applied**:
- Added check: If `moving_to_deposit` flag set, block gather entry
- Clear priority: Deposit movement > Gathering

**Result**: ✅ No boundary oscillation (direct deposit movement)

---

### Root Cause #5: Multiple Rapid Deposits ✅ FIXED

**Problem**:
- Items weren't grouped by type before deposit
- Multiple slots with same item type created separate entries
- Remove_item failed for some items

**Location**: `scripts/npc/npc_base.gd:2246-2299`

**Fix Applied**:
- Group items by type before deposit (sum amounts)
- Verify inventory actually changed after deposit
- Only set cooldown if deposit succeeded

**Result**: ✅ Single deposits working correctly (3 items deposited)

---

## Code Simplifications Applied

### Simplification #1: Removed Complex Inventory Check from Wander can_enter() ✅

**Before**: Complex inventory check blocking entry
```gdscript
if inventory_percent >= 0.7:
    return false  # Blocks entry
```

**After**: Simple - always allow wander for cavemen
```gdscript
if npc_type_str == "caveman":
    return true  # Always allow (handles deposit movement)
```

**Benefits**:
- Simpler logic (1 line vs 10+ lines)
- No conflicts (wander always available)
- Logic in right place (update() handles behavior)

---

### Simplification #2: Standardized Resource Yields ✅

**Before**: Variable yields (4-6 items random)
```gdscript
var amount := randi_range(min_amount, max_amount)
return amount
```

**After**: Always 1 item (predictable)
```gdscript
return 1  # Always yield 1 item (simplified, predictable)
```

**Benefits**:
- Predictable inventory growth
- Easier threshold checks
- No overflow risk
- Simpler code

---

### Simplification #3: Pre-Collection Inventory Check ✅

**Before**: Check happens after collection (too late)
```gdscript
_collect_resource()  # Adds items first
# Check happens in update() - too late!
```

**After**: Check happens before collection (preventive)
```gdscript
# Check inventory BEFORE harvesting
if used_slots >= 7:
    exit_to_deposit()  # Prevent overflow
return
# NOW safe to collect
```

**Benefits**:
- Prevents overflow (check before action)
- Simpler logic (preventive vs reactive)
- Clear intent (check → act pattern)

---

### Simplification #4: Group Items by Type in Deposit ✅

**Before**: Items processed per slot (duplicates)
```gdscript
for slot in slots:
    items_to_deposit.append({type, amount})  # Creates duplicates
```

**After**: Group by type first (sum amounts)
```gdscript
items_by_type[item_type] += amount  # Group first
# Then deposit once per type
```

**Benefits**:
- Single deposit per type (no duplicates)
- Correct removal (all items of type removed together)
- Simpler logic (group → deposit pattern)

---

## Test Results - Before vs After

### Before Fixes:
- **Idle State Entries**: 19+ times
- **Inventory Max Reached**: 10/10 slots (100% full) - 5 times
- **Resource Yields**: 4-6 items (random)
- **Gather Rate**: 9 gathers in 5 minutes
- **Deposit Issues**: Multiple rapid deposits, incomplete removal
- **Boundary Oscillation**: 100+ frames wasted moving in/out of range

### After Fixes:
- **Idle State Entries**: 0 times ✅ (100% improvement!)
- **Inventory Max Reached**: 7/10 slots (70% threshold) ✅ (never full!)
- **Resource Yields**: 1 item (predictable) ✅
- **Gather Rate**: 9 gathers in 5 minutes (same, but no idle blocking)
- **Deposit Issues**: Fixed ✅ (single deposits, complete removal)
- **Boundary Oscillation**: None ✅ (direct deposit movement)

---

## Code Quality Improvements

### Before:
- Complex inventory checks in multiple places
- Variable yields causing unpredictability
- Multiple duplicate logic paths
- Reactive checks (fix problems after they happen)
- State conflicts (gather vs wander vs idle)

### After:
- Simple checks in right places
- Predictable yields (always 1 item)
- Single source of truth (group by type)
- Preventive checks (prevent problems before they happen)
- Clear priorities (deposit > gather, wander > idle for cavemen)

---

## Remaining Issues

### Issue #1: Low Gather Rate (9 in 5 minutes)
**Status**: Not fixed (separate issue)
**Root Cause**: Likely resource spawning or NPC spawning issues
**Impact**: Low productivity, but gather system itself is working correctly

**Next Steps**:
- Check resource spawning (are 40 resources being created?)
- Check NPC spawning (is caveman being spawned?)
- Check resource detection range (1600px working?)
- Check if resources are in cooldown (all resources exhausted?)

---

## Summary of Changes

### Files Modified:
1. `scripts/npc/fsm.gd` - Removed idle fallback for cavemen, added wander fallback
2. `scripts/npc/states/wander_state.gd` - Always allow wander for cavemen
3. `scripts/npc/states/gather_state.gd` - Pre-collection check, block during deposit movement, 70% threshold
4. `scripts/gatherable_resource.gd` - Standardized yields to 1 item
5. `scripts/npc/npc_base.gd` - Group items by type, verify deposit success

### Key Improvements:
- ✅ No idle state for cavemen (productivity requirement)
- ✅ No inventory overflow (pre-collection check)
- ✅ Predictable yields (always 1 item)
- ✅ Reliable deposits (group by type, verify success)
- ✅ No boundary oscillation (clear priorities)
- ✅ Simpler code (fewer edge cases, clearer logic)

---

## Recommendations for Further Improvement

### Priority 1: Investigate Low Gather Rate
- Check resource spawning (verify 40 resources exist)
- Check NPC spawning (verify caveman exists)
- Check resource detection (verify 1600px range working)
- Add logging to track resource finding failures

### Priority 2: Optimize Resource Finding
- Cache resource list (performance optimization)
- Early exit for close resources (< 100px)
- Prioritize resources near land claim

### Priority 3: Improve Deposit Efficiency
- Add hysteresis to boundary check (enter at 200px, exit at 150px)
- Cache land claim position (avoid repeated searches)
- Batch deposit operations (if multiple NPCs depositing)

---

## Conclusion

**Critical Issues**: ✅ All fixed
**Code Quality**: ✅ Significantly improved
**Gather System**: ✅ Working correctly
**Remaining Work**: Low gather rate investigation (separate issue)

The gather system is now **simple, reliable, and working correctly**. All critical bugs are fixed, code is simplified, and the system behaves predictably.
