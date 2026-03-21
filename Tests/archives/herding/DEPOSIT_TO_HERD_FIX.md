# Deposit to Herd Fix

## Issue
After the caveman deposits items, he doesn't know what to do. He should go right back into herd mode to get more wild NPCs from outside the land claim.

## Root Cause
After auto-deposit completes in `npc_base.gd`, there was no immediate FSM evaluation to check if `herd_wildnpc` state could enter. The caveman would stay in wander state, waiting for the 1-second wander timeout before evaluating states again.

## Fix Applied

### 1. Auto-Deposit Completion Trigger ✅
**File:** `scripts/npc/npc_base.gd` (line ~1862)

After successful deposit:
- Clears `moving_to_deposit` meta flag
- Clears `is_depositing` meta flag (if exists)
- **Forces immediate FSM evaluation** - triggers `fsm._evaluate_states()` immediately

This ensures `herd_wildnpc` (priority 10.6) is evaluated right after deposit, taking priority over:
- Gather (7.0-8.0)
- Wander (1.0)

### 2. Comment Update ✅
**File:** `scripts/npc/states/wander_state.gd` (line ~252)

Added comment noting that auto-deposit will trigger state evaluation after deposit completes.

## Expected Behavior

**Flow after deposit:**
1. Caveman deposits items (auto-deposit in `npc_base.gd`)
2. ✅ **NEW:** Immediate FSM evaluation triggered
3. `herd_wildnpc.can_enter()` is checked
4. If wild NPCs are detected → enters `herd_wildnpc` state
5. Caveman goes outside land claim to search for and herd wild NPCs

**Priority Order:**
1. Deposit (11.0) - When inventory 80%+ full
2. Herd_wildnpc (10.6) - **Immediately after deposit**
3. Gather (7.0-8.0) - Brief reset only
4. Wander (1.0) - Fallback

## Result
Caveman will now **immediately return to herding** after depositing items, creating a continuous loop:
- Herd wild NPCs → Deposit → **Immediately go back to herding** → Repeat
