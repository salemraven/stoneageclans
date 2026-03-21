# Herding Behavior Analysis

## Current Behavior

Based on code analysis:

### When Caveman Herds One NPC:

1. **Herding succeeds**: `is_herded_by_us = true`, `herding_succeeded_this_frame = true`
2. **Immediately redirects**: Sets `steering_agent.target_position = land_claim.global_position` (line 383, 452)
3. **Leads to claim**: `should_lead = true` → Always leads to claim (line 423-452)
4. **Stays in state**: Remains in `herd_wildnpc` state while leading
5. **Exits when NPC joins clan**: Only exits when target joins clan (`clan_name != ""`)

### Multi-Target Handling

The system has infrastructure for multi-target handling:
- `herded_npcs: Array[Node2D]` - tracks all NPCs being herded by this caveman
- `_update_herded_npcs_list()` - updates the list every frame

**BUT**: The leading logic only uses `target_woman` (single target), not `herded_npcs`.

### Current Flow:

```
1. Caveman finds target (Woman 1)
2. Caveman herds Woman 1 → is_herded_by_us = true
3. Caveman immediately redirects to claim
4. Caveman leads Woman 1 to claim (should_lead = true)
5. Woman 1 joins clan → caveman exits herd_wildnpc state
6. Caveman re-enters herd_wildnpc state
7. Caveman finds new target (Woman 2)
8. Repeat...
```

**So YES, the caveman DOES return immediately after herding one NPC.**

## Question: Should Caveman Herd Multiple NPCs?

### Option A: Return Immediately (Current)
- ✅ **Pros**: Simple, efficient, NPC joins clan quickly
- ✅ **Pros**: Reduces risk of losing herd (NPC breaks away)
- ✅ **Pros**: Simpler state management
- ❌ **Cons**: Less efficient (more trips back and forth)

### Option B: Herd Multiple Before Returning
- ✅ **Pros**: More efficient (fewer trips to claim)
- ✅ **Pros**: Can build up a herd
- ❌ **Cons**: Higher risk (herds can break, NPCs can be stolen)
- ❌ **Cons**: More complex (need to manage multiple NPCs)
- ❌ **Cons**: NPCs might wander off while waiting for more

## Recommendation

**Current behavior (return immediately) is probably correct** because:
1. The system is designed to prevent reverse herding by always leading to claim
2. Leading multiple NPCs simultaneously while searching for more is complex
3. NPCs can break away or be stolen, making multi-NPC herding risky
4. Simpler state machine is more reliable

**However**, if we want to optimize for efficiency, we could:
1. Track `herded_npcs` array
2. While leading, still search for nearby targets (<300px)
3. If found, herd them too and add to herd
4. Lead entire herd to claim
5. Exit when all NPCs join clan or all break away

But this would require significant code changes to the leading logic.
