# WEBE Herding Fixes

## Issues Identified

1. **Gather priority too high** - Was 9.5, competing with herd_wildnpc (10.6)
2. **Caveman not moving when searching** - Stuck with velocity 0.0
3. **State priorities wrong** - User wants: herd_wildnpc > deposit > gather (brief reset only)

## Fixes Applied

### 1. Lowered Gather Priority ✅
**File:** `scripts/npc/states/gather_state.gd`

Changed from 9.5 to 7.0-8.0 (below herd_wildnpc 10.6)
- Gather is now only for brief reset, not primary activity
- Herd_wildnpc will take precedence

### 2. Increased Herd_Wildnpc Timeout ✅
**File:** `scripts/npc/states/herd_wildnpc_state.gd`

Doubled timeout from 5s to 10s before exiting state
- Gives more time to find and herd wild NPCs
- Reduces premature state exits

### 3. Ensured Active Movement ✅
**File:** `scripts/npc/states/herd_wildnpc_state.gd`

Added speed multiplier reset when searching:
- Ensures speed_multiplier = 1.0 when searching (not zero)
- Fixed search pattern for no-land-claim case
- Caveman will actively move when searching

### 4. Priority Clarification ✅
**File:** `scripts/npc/states/herd_wildnpc_state.gd`

Updated comments to reflect user requirement:
- Herd mode and deposit mode are PRIMARY activities
- Gather is only for brief reset (1 sec as user mentioned)

## Expected Behavior

Cavemen should now:
1. **Prioritize herding** (10.6) over gathering (7.0-8.0)
2. **Actively search** outside land claim using spiral pattern
3. **Stay in herd_wildnpc** state longer (10s timeout vs 5s)
4. **Move continuously** when searching (no more stuck with velocity 0.0)
5. **Deposit when inventory full** (11.0 priority)
6. **Use gather briefly** only when needed for reset

## Priority Order (Highest to Lowest)

1. Deposit (11.0) - When inventory 80%+ full
2. Herd_wildnpc (10.6) - Primary activity, find and herd wild NPCs
3. Gather (7.0-8.0) - Brief reset only, NOT primary activity
4. Wander (1.0) - Fallback
5. Idle (0.0) - Lowest
