# State Blocking Rules

**Last Updated:** 2026-01-27

This document defines which states should prevent which other states from being entered.

## Blocking Categories

### Player Commands (Explicit Player Intent)
**Following (follow_is_ordered)** blocks:
- Gather
- Work
- Occupy
- Reproduction
- Defend
- Wander

**Reason:** Player orders override autonomous behavior.

**Herd (is_herded)** blocks:
- Wander

**Reason:** Following leader takes priority over wandering.

### Combat & Agro (Interrupts Work)
**Combat** blocks:
- All states except Defend (combat can happen while defending)

**Reason:** Life/death takes priority over all work.

**Agro (land claim defense)** blocks:
- Gather
- Work
- Occupy
- Reproduction
- Wander

**Reason:** Territory defense interrupts work.

### Defense
**Defend** blocks:
- Gather
- Work
- Occupy
- Reproduction
- Wander

**Reason:** Defense assignment overrides autonomous work.

**Exception:** Following (player command) beats Defend (auto-assignment).

## Implementation

States check blocking conditions in two places:
1. **`can_enter()`** - Prevents entering a state
2. **`update()`** - Exits state if conditions change during execution

This ensures states are blocked both when trying to enter and while running.

## Helper Functions

All states use helper functions from `base_state.gd`:
- `_is_defending()` - Check if NPC is defending
- `_is_in_combat()` - Check if NPC is in combat
- `_is_following()` - Check if NPC is following (ordered follow)

These ensure consistent blocking checks across all states.
