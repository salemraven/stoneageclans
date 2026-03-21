# Wander Rule - CAVEMEN ONLY - Documentation Update

## Correction:
The 1-second wander rule applies **ONLY TO CAVEMEN**, not to other NPCs.

## Code Verification:
✅ **wander_state.gd** line 234: `if npc_type_wander == "caveman":` - Correctly checks for caveman only
✅ **gather_state.gd** line 844: `if npc_type_search == "caveman":` - Correctly checks for caveman only

## Rule:
- **CAVEMEN ONLY:** Wander is a brief 1-second reset state
- **Other NPCs (women, sheep, goats):** Can wander normally without time restrictions

## Documentation Updated:
All markdown files have been updated to clarify this rule applies to CAVEMEN ONLY.
