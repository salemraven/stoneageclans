# Wander Rule Documentation Complete

## Rule Established:
**Wander is a brief 1-second reset state only**

## Documents Updated:

### Guides:
1. ✅ `guides/CavemanGuide.md` - Added rule at top and in states section
2. ✅ `guides/NPCGUIDE.md` - Updated wander state description
3. ✅ `guides/Priority.md` - Updated wander priority description
4. ✅ `guides/HARMONIOUS_PRIORITY_SYSTEM.md` - Updated wander in priority tiers
5. ✅ `guides/GatherGuide.md` - Updated all wander references
6. ✅ `guides/WANDER_STATE_RULE.md` - **NEW** - Dedicated document for this rule

### Tests:
1. ✅ `Tests/PRODUCTIVITY_REQUIREMENT.md` - Added wander rule section
2. ✅ `Tests/PRODUCTIVITY_FIXES_APPLIED.md` - Added wander rule section
3. ✅ `Tests/WANDER_1SECOND_FIX.md` - Implementation details
4. ✅ `Tests/WANDER_RESET_FIX.md` - Implementation details

## Rule Summary:
- **Purpose:** Wander is ONLY used to reset an NPC after task completion
- **Maximum Duration:** 1 second
- **After 1 Second:** Immediately force FSM evaluation to find productive state (gather, deposit, herd)
- **Never:** Use wander for extended periods, idle behavior, or exploration

## Implementation:
- `scripts/npc/states/wander_state.gd` - 1-second timer implementation
- `scripts/npc/states/gather_state.gd` - 1-second search timer

## Status: ✅ COMPLETE
All relevant markdown documents have been updated with the wander state rule.
