# Reproduction System Test Findings

**Date**: January 17, 2026  
**Status**: Investigation Complete

## Test Results Summary

### ✅ Working Systems

1. **Women Random Names**: ✅ WORKING
   - Women spawn with random names (DUQI, GEUM, RAVE, YUXI, WOIB, etc.)
   - Using `NamingUtils.generate_caveman_name()` correctly
   - Names are 4-letter consonant-vowel patterns (CvCv or CvvC)

2. **Reproduction Component**: ✅ LOADING CORRECTLY
   - Component attaches to women NPCs
   - Component's `update()` is being called in `_physics_process()`
   - No compilation or runtime errors

3. **Reproduction State**: ✅ REGISTERED
   - State is registered in FSM for all NPCs (including sheep/goats - harmless)
   - State priority set to 8.0
   - State creation successful

4. **Baby Pool Manager**: ✅ INITIALIZING
   - Manager initializes on game start
   - "Baby pool manager initialized" log confirms it

### ❌ Not Working / Missing Activity

1. **No Pregnancy Logs**: No "started pregnancy" messages
2. **No Baby Spawning**: No "gave birth" or "Spawned Baby" messages
3. **No Mate Detection**: No evidence of mate finding

## Root Cause Analysis

### Reproduction Requirements (ALL must be true):

1. ✅ Woman must exist (`npc_type == "woman"`)
2. ❌ Woman must be in clan (`clan_name != ""`) - **Women spawn wild**
3. ❌ Woman must be inside land claim (`_is_in_land_claim() == true`)
4. ❌ Mate must exist (player or NPC caveman in same clan)
5. ❌ Mate must be inside land claim (`_is_npc_in_land_claim(mate) == true`)

### Why Reproduction Isn't Happening:

**Women spawn as wild NPCs** (no clan_name). They need to:
1. Be herded by player/NPC caveman
2. Enter land claim radius while being herded
3. Join the clan (clan_name gets set)
4. THEN reproduction can start

**In a short automated test (30 seconds):**
- Women spawn wild
- Land claims might be placed
- But women aren't herded into land claims automatically
- So they never join clans
- So reproduction never starts

## Verification Steps

### Manual Testing Checklist:

1. ✅ **Start game** - Women should have random names
2. ❌ **Place land claim** - Player places land claim (creates clan)
3. ❌ **Herd a woman** - Right-click woman to herd, bring her into land claim
4. ❌ **Woman joins clan** - Check console for "joined clan" message
5. ❌ **Stay in land claim** - Player stays inside land claim with woman
6. ❌ **Wait 90 seconds** - Pregnancy timer should start and count down
7. ❌ **Baby spawns** - After 90 seconds, baby should spawn at land claim center

### Debug Logging Added:

- Pregnancy start: "✓ REPRODUCTION: [woman] started pregnancy (mate: [mate], clan: [clan], timer: 90.0s)"
- Birth: "✓ REPRODUCTION: [woman] gave birth to baby (clan: [clan])"

## Expected Behavior in Manual Playtest

1. **Women spawn with random names** (e.g., "YUXI", "WOIB") ✅
2. **Player places land claim** → Creates clan (e.g., "BA DOKU")
3. **Player herds woman** → Right-click woman, she follows player
4. **Woman enters land claim** → Woman joins player's clan (console: "NPC [name] joined clan [clan]")
5. **Player stays in land claim with woman** → Both inside 400px radius
6. **Reproduction starts** → Console: "✓ REPRODUCTION: [woman] started pregnancy (mate: Player, clan: [clan], timer: 90.0s)"
7. **90 seconds pass** → Birth timer counts down
8. **Baby spawns** → Console: "✓ REPRODUCTION: [woman] gave birth to baby (clan: [clan])"
9. **Baby wanders** → Baby wanders within land claim
10. **60 seconds pass** → Baby grows to clansman

## Potential Issues to Check

1. **Is the player's clan name being set correctly?**
   - When player places land claim, does the land claim have `player_owned = true`?
   - Does `_get_player_clan_name()` return the correct clan name?

2. **Is the woman actually inside the land claim?**
   - Check distance: `woman.position.distance_to(land_claim.position) <= land_claim.radius` (400px)

3. **Is the player actually inside the land claim?**
   - Player must also be inside the 400px radius for mate detection

4. **Is the reproduction component actually running?**
   - Component should update every frame if woman is in clan and in land claim
   - Check if `_is_in_land_claim()` is returning true

## Recommendations

1. **Test manually** - Automated tests won't work because women need to be manually herded
2. **Check console logs** - Look for "joined clan" and "REPRODUCTION" messages
3. **Verify positions** - Make sure player and woman are both inside land claim radius
4. **Wait full 90 seconds** - Pregnancy timer is 90 seconds, need to wait that long

## Next Steps

If reproduction still doesn't work in manual playtest:

1. Add more debug logging to `_is_in_land_claim()`
2. Add debug logging to `_try_find_mate()`
3. Add debug logging to `_get_player_clan_name()`
4. Verify land claim `player_owned` flag is being set correctly
5. Check if reproduction component's `update()` is actually being called when woman is in clan
