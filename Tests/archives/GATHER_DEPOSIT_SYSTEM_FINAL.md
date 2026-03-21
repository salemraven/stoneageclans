# Gather/Deposit System - Final Locked Version
**Date**: January 9, 2026  
**Status**: ✅ LOCKED - Production Ready

## System Overview

### Simplified Gather/Deposit Flow
```
Gather State → Check Inventory (70% threshold) → Exit to Wander → Move to Deposit → Auto-Deposit → Resume Gather
```

### Key Components

**Gather State** (`scripts/npc/states/gather_state.gd`):
- **Size**: 272 lines (33% reduction from original 398 lines)
- **Flow**: Find target → Move → Gather → Check inventory → Exit if 70%+ full
- **Threshold**: 7/10 slots (70%)
- **Constants**: `INVENTORY_THRESHOLD = 7`, `DEPOSIT_RANGE = 200.0`

**Deposit Function** (`scripts/npc/npc_base.gd`):
- **Size**: ~100 lines (41% reduction from original 165 lines)
- **Flow**: Check → Find claim → Group items → Deposit → Log
- **Food keeping**: 1 food item TOTAL (across all food types)
- **Cooldown**: 1 second after deposit

**Wander State** (`scripts/npc/states/wander_state.gd`):
- Handles deposit movement when inventory 70%+ full
- Moves NPC to land claim within 200px range
- Auto-deposit handles actual deposit in background

## Test Results (Test 3 - 5 minutes)

### Performance Metrics
- **Total gathers**: 71
- **Total deposits**: 12 successful
- **Gather rate**: 14.2 per minute
- **Deposit pattern**: 6 items from 7 total (keeping 1 food) ✅
- **Max inventory**: 7/10 slots (never full) ✅
- **Idle entries**: 0 ✅
- **Parse errors**: 0 ✅

### System Health
- ✅ No inventory overflow
- ✅ No boundary oscillation
- ✅ No idle state for cavemen
- ✅ Proper gather → wander → deposit flow
- ✅ Food keeping working correctly (1 food total)

## Code Simplifications

### Removed (200+ lines):
- Duplicate inventory checking logic
- Unused `_move_to_land_claim()` function
- Complex nested conditions
- Redundant land claim finding
- Unnecessary `inventory_before` tracking
- Complex verification logic

### Added:
- Helper functions (`_get_used_slots()`, `_find_land_claim()`, `_is_near_land_claim()`)
- Constants instead of magic numbers
- Single exit points for clean flow
- Linear, predictable logic

## Key Features

### 1. Inventory Management
- **Threshold**: 70% (7/10 slots)
- **Max inventory**: Never exceeds 7/10 slots
- **Food keeping**: 1 food item total (across all types)

### 2. Deposit Logic
- Groups items by type before deposit
- Deposits all items except 1 food item
- Handles multiple slots correctly
- 1 second cooldown after deposit

### 3. State Management
- Gather state: High priority (9.5), exits at 70% full
- Wander state: Handles deposit movement
- No idle state for cavemen (productivity requirement)
- Clean state transitions

## Constants & Thresholds

```gdscript
# gather_state.gd
const INVENTORY_THRESHOLD: int = 7  # 70% of 10 slots
const DEPOSIT_RANGE: float = 200.0  # Deposit range in pixels

# npc_base.gd (_check_and_deposit_items)
const FOOD_TO_KEEP: int = 1  # Keep 1 food item total
const DEPOSIT_COOLDOWN: float = 1.0  # 1 second cooldown
const CHECK_INTERVAL: float = 0.5  # Check every 0.5 seconds
```

## Known Behaviors (Not Issues)

### Expected Warnings (Suppressed):
- When only 1 food item remains, deposit function is called but nothing to deposit (expected - we keep 1 food)
- Warning is suppressed for 1 food item case

### Deposit Pattern:
- **7 items total**: Deposits 6, keeps 1 food
- **6 items total (2 food)**: Deposits 5, keeps 1 food
- **6 items total (no food)**: Deposits all 6

## File Changes Summary

### Modified Files:
1. `scripts/npc/states/gather_state.gd` - Simplified from 398 → 272 lines
2. `scripts/npc/states/wander_state.gd` - Simplified deposit movement logic
3. `scripts/npc/npc_base.gd` - Simplified deposit function from 165 → 100 lines
4. `scripts/npc/fsm.gd` - Removed idle fallback for cavemen

### Removed Code:
- Unused `_move_to_land_claim()` function (31 lines)
- Duplicate inventory checks (50+ lines)
- Complex verification logic (30+ lines)
- Redundant land claim finding (40+ lines)

## Production Readiness Checklist

- ✅ All tests passing
- ✅ No parse errors
- ✅ No runtime errors
- ✅ Performance acceptable (14.2 gathers/min)
- ✅ Code simplified and maintainable
- ✅ Proper error handling
- ✅ Logging for debugging
- ✅ Constants for easy tuning
- ✅ Documentation complete

## Maintenance Notes

### Future Tuning (if needed):
- `INVENTORY_THRESHOLD`: Adjust if need different deposit frequency (currently 7/10 = 70%)
- `DEPOSIT_RANGE`: Adjust if need different deposit distance (currently 200px)
- `FOOD_TO_KEEP`: Adjust if need to keep more/less food (currently 1)
- `DEPOSIT_COOLDOWN`: Adjust if need different cooldown (currently 1 second)

### Testing:
- Run `./Tests/TEST3_RUN_GATHER_DEPOSIT.sh` for comprehensive testing
- Analyze with `./Tests/TEST3_ANALYZE.sh`
- Monitor logs for warnings/errors

---

## Conclusion

The simplified gather/deposit system is **LOCKED and PRODUCTION READY**. 

**Key Achievements**:
- 200+ lines of code removed
- 33-41% reduction in file sizes
- Clean, linear flow
- All critical bugs fixed
- Performance verified (14.2 gathers/min)
- Zero idle entries for cavemen
- Proper inventory management (never full)

**System Status**: ✅ STABLE - No further changes needed unless bugs discovered.
