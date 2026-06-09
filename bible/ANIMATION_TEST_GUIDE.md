# Animation Test Scene Guide

## Overview
The `AnimationTest.tscn` scene lets you test and tweak the combat sprite sheet animation (`clubss.png`) in isolation without running the full game.

## How to Use

### 1. Open the Test Scene
- In Godot, go to **Project → Project Settings → Run → Main Scene**
- Temporarily set main scene to `res://scenes/AnimationTest.tscn`
- Or right-click `scenes/AnimationTest.tscn` → **Run Scene**

### 2. Load Sprite Sheet
- Enter the path to your sprite sheet (default: `res://assets/sprites/clubss.png`)
- Click **"Load"** button
- The sprite should appear (scaled 4x for visibility)

### 3. Manual Frame Navigation
- **◀ Prev** - Go to previous frame
- **Next ▶** - Go to next frame
- Frame info shows current frame number and name

### 4. Adjust Settings

**Frame Count:**
- Set how many frames are in your horizontal sprite strip (default: 5)
- Frame width is automatically calculated

**Timing (seconds):**
- **Windup**: Time to show Frame 1 (default: 0.45s)
- **Hit Display**: Time to show Frame 3 (default: 0.15s)
- **Recovery**: Time to show Frame 4 (default: 0.8s)

### 5. Test Animation

**Play/Pause:**
- Click **▶ Play** to start animation sequence
- Animation cycles: Windup → Hit → Recovery → Idle
- Click **⏸ Pause** to stop

**Test Full Attack:**
- Click **"Test Full Attack Sequence"** to play complete animation
- Shows the full combat flow with your current timing values

## Animation Sequence

The test scene simulates the combat flow:

1. **Idle** (Frame 0) - Default state
2. **Windup** (Frame 1) - Shows for `windup_time` seconds
3. **Hit** (Frame 3) - Shows for `hit_display_time` seconds
4. **Recovery** (Frame 4) - Shows for `recovery_time` seconds
5. **Back to Idle** (Frame 0)

**Note:** Frame 2 (mid-windup) is currently unused but available in the sprite sheet.

## Tips

- **Frame Width**: Automatically calculated as `sheet_width / frame_count`
- **Scale**: Sprite is scaled 4x for better visibility (adjust in scene if needed)
- **Timing**: Adjust values in real-time and test immediately
- **Path**: Change sprite sheet path to test different animations

## Troubleshooting

**Sprite not loading?**
- Check that the path is correct
- Verify the file exists in the project
- Check console for error messages

**Frames look wrong?**
- Verify `frame_count` matches your sprite sheet
- Check that sprite sheet is horizontal strip (frames left-to-right)
- Ensure all frames are same width

**Animation too fast/slow?**
- Adjust timing values (Windup, Hit Display, Recovery)
- Test with different values to find what feels right

## After Testing

Once you've found good timing values:
1. Note the values that work best
2. Update `combat_component.gd` with your preferred timings
3. Or update weapon profiles in `_get_attack_profile_for_weapon()`

## Example Values

**Fast/Responsive (Player):**
- Windup: 0.1s
- Hit Display: 0.15s
- Recovery: 0.3s

**Normal (NPC with Axe):**
- Windup: 0.45s
- Hit Display: 0.15s
- Recovery: 0.8s

**Heavy/Slow (NPC with Pick):**
- Windup: 0.5s
- Hit Display: 0.15s
- Recovery: 0.8s
