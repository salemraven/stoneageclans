# Windup Stuck Issue - Fix Analysis

## Problem Identified

**Symptom:** Cavemen stuck in WINDUP state, never executing hit frames

**Root Cause:** Infinite loop of attack cancellation
1. `combat_state.update()` calls `request_attack()` every frame when in range
2. `request_attack()` sees state=WINDUP → cancels attack → restarts
3. New attack starts → immediately cancelled again → repeat
4. Result: Attacks never complete, scheduler events get cancelled before execution

## Fix Applied

### 1. Combat State Update - Only Request When IDLE
**File:** `scripts/npc/states/combat_state.gd`

**Change:**
- Added check: Only call `request_attack()` if `combat_comp.state == CombatComponent.CombatState.IDLE`
- Prevents spamming attack requests while already attacking

### 2. Request Attack - Reject Instead of Cancel
**File:** `scripts/npc/components/combat_component.gd`

**Change:**
- Removed: "If in WINDUP, cancel and restart" logic
- Added: "If not IDLE, reject request" (don't cancel - let current attack finish)
- Prevents interrupting attacks in progress

## Expected Behavior After Fix

1. Attack requested when in range and IDLE
2. Windup starts → state = WINDUP
3. Scheduler event scheduled for hit frame
4. `combat_state.update()` sees WINDUP → doesn't request new attack
5. Scheduler executes event → hit frame fires
6. State transitions: WINDUP → RECOVERY → IDLE
7. Cycle repeats when back in range

## Test Results

Waiting for test to complete...
