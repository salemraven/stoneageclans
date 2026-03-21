# Wander 1-Second Fix

## Requirement:
**Wander should ONLY be used to reset an NPC after task completion**
**Wander should not last longer than 1 second**

## Changes Applied:

### 1. ✅ Added 1-Second Productivity Timer in Wander
- **Location:** `scripts/npc/states/wander_state.gd` line 231-247
- **Action:** After 1 second in wander, force immediate FSM evaluation
- **Result:** Cavemen cannot stay in wander - must transition to productive state

### 2. ✅ Updated Gather Search Timer to 1 Second
- **Location:** `scripts/npc/states/gather_state.gd` line 1011-1040
- **Before:** 2 seconds max before forced exploration
- **After:** 1 second max before forced exploration

### 3. ✅ Removed 3-Second Proactive Check
- **Before:** Checked for resources after 3 seconds in wander
- **After:** Removed - 1-second timer handles this immediately

## Result:
- Wander is now a brief 1-second reset state only
- NPCs immediately transition to productive states (gather, deposit, herd) after reset
- No idle time or extended wandering
- Cavemen are always productive
