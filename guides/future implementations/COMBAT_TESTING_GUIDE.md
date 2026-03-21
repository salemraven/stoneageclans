# Combat System Testing Guide

## How Combat Works

### Combat Flow (Event-Driven)

1. **Attack Request** → `request_attack(target)`
   - Checks if in IDLE state (rejects spam)
   - Validates target and range
   - Updates weapon profile (timings)

2. **Windup Phase** (0.1s for player, 0.45s for NPCs)
   - State: `WINDUP`
   - Sprite: Frame 1 (windup frame)
   - Schedules hit event via CombatScheduler

3. **Hit Frame** (exact moment of impact)
   - State: `RECOVERY` (starts here)
   - Sprite: Frame 3 (hit/impact frame)
   - Validates target (alive, in range, in arc)
   - Applies damage
   - Applies stagger (if applicable)

4. **Hit Display** (0.15s)
   - Shows Frame 3 briefly
   - Then switches to recovery frame

5. **Recovery Phase** (0.3s for player, 0.8s for NPCs)
   - State: `RECOVERY`
   - Sprite: Frame 4 (recovery frame)
   - Prevents new attacks

6. **Idle** (back to normal)
   - State: `IDLE`
   - Sprite: Default texture (restored)

### Sprite Sheet Animation (clubss.png)

**5-Frame Horizontal Strip:**
- **Frame 0**: Idle (not used - restores default sprite)
- **Frame 1**: Windup (shown during windup phase)
- **Frame 2**: (unused - could be mid-windup)
- **Frame 3**: Hit/Impact (shown at exact hit moment)
- **Frame 4**: Recovery (shown during recovery)

---

## Best Way to Test Swing Animation

### Method 1: In-Game Testing (Easiest)

1. **Start the game**
2. **Equip a weapon** (Axe or Pick in first hotbar slot)
3. **Click on an NPC** (within 100px range)
4. **Watch the animation:**
   - Player sprite should show Frame 1 (windup)
   - Then Frame 3 (hit) briefly
   - Then Frame 4 (recovery)
   - Then back to default sprite

**What to look for:**
- Smooth frame transitions
- Correct timing (windup → hit → recovery)
- Sprite returns to default after attack

### Method 2: With Logging (Debug Mode)

Run with logging to see exactly what's happening:

```bash
cd /Users/macbook/Desktop/stoneageclans
./run_with_logging.sh
```

Then attack an NPC and check the log file in `logs/` directory.

**Log markers:**
- `🎨 ANIMATION` = Sprite updates
- `⏰ SCHEDULER` = Event timing
- `🔵 COMBAT` = Combat state changes
- `❌` = Errors/crashes

### Method 3: Quick Test Scene (Optional)

Create a simple test scene with just player + one NPC for isolated testing.

---

## Troubleshooting

### Animation Not Showing?
- Check if `clubss.png` exists at `res://assets/sprites/clubss.png`
- Check console for sprite sheet loading messages
- Verify sprite sheet is 5 frames horizontal

### Wrong Frame Timing?
- Player windup: 0.1s (very fast)
- NPC windup: 0.45s (axe) or 0.5s (pick)
- Hit display: 0.15s
- Recovery: 0.3s (player) or 0.8s (NPC)

### Crash on Attack?
- Check logs for `❌` markers
- Look for frame bounds errors
- Check if sprite node exists

---

## Quick Test Checklist

- [ ] Player has weapon in first hotbar slot
- [ ] Click NPC within 100px range
- [ ] See windup frame (Frame 1)
- [ ] See hit frame (Frame 3) briefly
- [ ] See recovery frame (Frame 4)
- [ ] Sprite returns to default
- [ ] No crashes
- [ ] Animation feels smooth

---

## Frame Timing Reference

**Player Attack (with Axe):**
- Windup: 0.1s → Frame 1
- Hit: 0.0s → Frame 3 (instant)
- Hit Display: 0.15s → Frame 3
- Recovery: 0.3s → Frame 4
- **Total: ~0.45s**

**NPC Attack (with Axe):**
- Windup: 0.45s → Frame 1
- Hit: 0.0s → Frame 3 (instant)
- Hit Display: 0.15s → Frame 3
- Recovery: 0.8s → Frame 4
- **Total: ~1.4s**
