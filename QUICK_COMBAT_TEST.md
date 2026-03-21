# Quick Combat Animation Test

## Fastest Way to Test

1. **Start the game** (normal or with `./run_with_logging.sh`)

2. **Make sure you have a weapon:**
   - Open inventory (I key)
   - Drag Axe or Pick to first hotbar slot (slot 1)
   - Close inventory

3. **Find an NPC** (caveman, woman, etc.)

4. **Click on the NPC** (left-click while within 100px)
   - If you have weapon equipped → attacks
   - If no weapon → opens character menu

5. **Watch the animation:**
   - **Frame 1** (windup) - very brief for player (0.1s)
   - **Frame 3** (hit) - shows for 0.15s
   - **Frame 4** (recovery) - shows for 0.3s
   - **Default sprite** - returns after recovery

## What You Should See

**Player Attack Sequence:**
```
Default Sprite → Frame 1 (windup) → Frame 3 (hit) → Frame 4 (recovery) → Default Sprite
    0ms              100ms             100ms           250ms           450ms
```

**If animation doesn't work:**
- Check console for sprite sheet loading messages
- Verify `clubss.png` is in `res://assets/sprites/`
- Check logs for errors (if using logging script)

## Console Output

When you attack, you should see:
```
🔵 COMBAT: request_attack() called
✅ COMBAT: Starting attack
🎨 ANIMATION: Updating sprite to WINDUP frame
🎨 ANIMATION: Sprite valid, updating frame
⏰ SCHEDULER: Scheduled event...
🎯 COMBAT: _on_hit_frame() called
🎨 ANIMATION: Updating sprite to HIT frame
💥 COMBAT: Applying damage
🎨 ANIMATION: Switching to RECOVERY frame
🔄 COMBAT: _on_recovery_end() called
```

If you see `❌` markers, that's where the crash is happening.
