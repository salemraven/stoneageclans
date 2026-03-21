# Playtest Checklist

## Pre-Playtest Setup

### Console & Logging (Playtest Mode)
- **Default run**: Clean console (minimal logs). Use `--debug` for verbose logs.
- **Command-line**: `./StoneAgeClans --debug` for task system, placement, and NPC logs.

### Building & Oven Flow
- **Starting inventory**: 1 land claim, 1 farm, 1 dairy, 1 oven
- **Land claim**: Adds 5 grain + 5 wood on placement (women bring these to oven)
- **Oven flow**:
  1. Place land claim → place oven inside claim
  2. Open oven (click) → turn on fire (button) → women gather grain/wood from claim and cook bread
  3. Cook sprite plays (ovencook.png) while producing
- **Arrive distance**: Women walk closer to buildings before entering (~28px)

### Spawn Counts
- 0 cavemen, 8 women, 3 sheep, 3 goats

### ✅ Combat System
- [x] Event-driven combat implemented
- [x] Sprite sheet animation working
- [x] All NPCs have weapons
- [x] Aggro rates doubled
- [x] DetectionArea for spatial queries
- [x] Combat scheduler functional

### ✅ Animation
- [x] Sprite sheet (clubss.png) in correct location
- [x] Animation test scene working
- [x] Frame layout verified (320×64, 5 frames)

### ⚠️ Known Issues to Watch For
- Crash on attack (being monitored)
- Animation loading issues
- Combat state transitions
- Aggro system behavior

## Playtest Scenarios

### Basic Combat
1. **Player attacks NPC**
   - Equip weapon (Axe/Pick)
   - Click NPC within range
   - Watch animation sequence
   - Verify damage applied

2. **NPC vs NPC combat**
   - Two NPCs near each other
   - One attacks the other
   - Verify combat states
   - Check aggro increases

3. **Multiple NPCs fighting**
   - 5+ NPCs in combat
   - Monitor performance
   - Check for crashes

### Aggro System
1. **Attack triggers aggro**
   - Attack NPC
   - Verify aggro increases (should be fast - 50 per hit)
   - Check hostile indicator appears

2. **Agro state behavior**
   - NPC enters agro state
   - Verify combat engagement
   - Check state transitions

### Animation
1. **Sprite sheet display**
   - Verify frames show correctly
   - Check windup → hit → recovery
   - Ensure smooth transitions

## Monitoring

### Log File Location
- `logs/combat_TIMESTAMP.log`
- Check for error markers: `❌`
- Look for crash stack traces

### Key Log Markers
- `🔵 COMBAT` - Combat state changes
- `🎨 ANIMATION` - Sprite updates
- `⏰ SCHEDULER` - Event timing
- `❌` - Errors/crashes
- `💥 COMBAT` - Damage application

### Performance Checks
- Frame rate during combat
- CPU usage with multiple NPCs
- Memory leaks (long play session)

## Common Crash Points

1. **On Attack**
   - Sprite sheet loading
   - Frame calculations
   - Null reference checks

2. **Combat State Transitions**
   - FSM conflicts
   - Combat lock issues
   - State machine errors

3. **Animation Updates**
   - AtlasTexture creation
   - Frame bounds
   - Sprite node access

## Post-Playtest

### Report Issues
- Crash logs with timestamps
- Steps to reproduce
- Expected vs actual behavior
- Screenshots if possible

### Performance Notes
- FPS during combat
- Number of NPCs tested
- Any lag or stuttering
