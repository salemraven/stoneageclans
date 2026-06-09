# Wander State Rule - CRITICAL

## Rule:
**Wander is a brief 1-second reset state only - CAVEMEN ONLY**

## Details:
- **Applies To:** **CAVEMEN ONLY** - Other NPCs (women, sheep, goats) are NOT affected
- **Purpose:** Wander is ONLY used to reset a caveman after task completion
- **Maximum Duration:** 1 second (for cavemen only)
- **After 1 Second:** Immediately force FSM evaluation to find productive state (gather, deposit, herd)
- **Never:** Use wander for extended periods, idle behavior, or exploration (cavemen only)

## Implementation:
- Timer starts when NPC enters wander state
- After 1 second, force `fsm.evaluate_states()` to find next productive state
- NPCs cannot stay in wander - must transition to productive state

## Why:
Cavemen must ALWAYS be productive. They cannot:
- Stand in one spot
- Wander aimlessly for more than 1 second
- Be idle or unproductive

## Files:
- `scripts/npc/states/wander_state.gd` - 1-second timer implementation
- `scripts/npc/states/gather_state.gd` - 1-second search timer

## Related Rules:
- See `CavemanGuide.md` for full productivity requirements
- See `PRODUCTIVITY_REQUIREMENT.md` for detailed implementation
