# Sprite Sheet Layout Guide

## Required Format

The combat animation sprite sheet (`clubss.png`) must be a **horizontal strip** with all frames in a single row.

## Layout Structure

```
┌─────────────────────────────────────────────────────────┐
│                                                           │
│  Frame 0    Frame 1    Frame 2    Frame 3    Frame 4    │
│  (Idle)     (Windup)   (Mid)      (Hit)      (Recovery) │
│                                                           │
└─────────────────────────────────────────────────────────┘
     ↑           ↑           ↑           ↑           ↑
   Frame 0    Frame 1    Frame 2    Frame 3    Frame 4
```

## Specifications

### Dimensions
- **Format**: Horizontal strip (all frames in one row)
- **Frame Count**: 5 frames (0-4)
- **Frame Width**: `Total Width ÷ 5`
- **Frame Height**: Full height of the image (all frames same height)

### Example Dimensions

**If each frame is 64x64 pixels:**
- Total width: `64 × 5 = 320 pixels`
- Total height: `64 pixels`
- Final size: `320 × 64 pixels`

**If each frame is 32x32 pixels:**
- Total width: `32 × 5 = 160 pixels`
- Total height: `32 pixels`
- Final size: `160 × 32 pixels`

### Frame Order (Left to Right)

1. **Frame 0** - Idle (not used in combat, shows default sprite)
2. **Frame 1** - Windup (shown during windup phase)
3. **Frame 2** - Mid-windup (currently unused, reserved for future)
4. **Frame 3** - Hit/Impact (shown at exact moment of attack)
5. **Frame 4** - Recovery (shown during recovery phase)

## Important Rules

✅ **DO:**
- All frames must be the **same width**
- All frames must be the **same height**
- Frames must be arranged **left to right** in order
- No gaps between frames (frames should touch)
- Use PNG format with transparency support

❌ **DON'T:**
- Don't use vertical strips (frames stacked top to bottom)
- Don't mix frame sizes
- Don't add spacing/padding between frames
- Don't rearrange frame order

## Frame Width Calculation

The system automatically calculates frame width:
```
frame_width = total_image_width / frame_count
```

**Example:**
- Image width: `320 pixels`
- Frame count: `5`
- Frame width: `320 ÷ 5 = 64 pixels`

## Creating Your Sprite Sheet

### In Photoshop/GIMP/Other Editors:

1. **Create new image:**
   - Width: `frame_width × 5`
   - Height: `frame_height`
   - Example: `320 × 64` for 64px frames

2. **Set up grid:**
   - Enable grid/snap
   - Set grid to match frame width
   - This helps align frames perfectly

3. **Place frames:**
   - Frame 0 (Idle) at x=0
   - Frame 1 (Windup) at x=frame_width
   - Frame 2 (Mid) at x=frame_width×2
   - Frame 3 (Hit) at x=frame_width×3
   - Frame 4 (Recovery) at x=frame_width×4

4. **Export:**
   - Save as PNG
   - Preserve transparency
   - Place in `res://assets/sprites/clubss.png`

## Testing Your Layout

Use the animation test scene to verify:

1. **Load your sprite sheet** in `AnimationTest.tscn`
2. **Set Frame Count** to `5`
3. **Click through frames** using Prev/Next buttons
4. **Check that each frame displays correctly**

If frames look wrong:
- Verify frame count matches actual frames
- Check that all frames are same width
- Ensure no gaps between frames
- Confirm frames are in correct order

## Common Issues

### Frames are cut off or misaligned
- **Cause**: Frames not evenly sized or gaps between frames
- **Fix**: Ensure all frames are exactly the same width

### Wrong frame shows
- **Cause**: Frame count doesn't match actual frames
- **Fix**: Adjust "Frame Count" in test scene to match your sheet

### Only first frame shows
- **Cause**: Frame width calculation is wrong
- **Fix**: Verify total width is divisible by frame count

### Sprite sheet not loading
- **Cause**: File path incorrect or file doesn't exist
- **Fix**: Check path is `res://assets/sprites/clubss.png`

## Example Layout (Visual)

```
┌──────┬──────┬──────┬──────┬──────┐
│      │      │      │      │      │
│  0   │  1   │  2   │  3   │  4   │
│ Idle │Windup│ Mid  │ Hit  │Recov │
│      │      │      │      │      │
└──────┴──────┴──────┴──────┴──────┘
  64px   64px   64px   64px   64px
  Total: 320px wide × 64px tall
```

## Quick Reference

- **File**: `res://assets/sprites/clubss.png`
- **Format**: Horizontal strip, PNG
- **Frames**: 5 (0-4)
- **Layout**: Left to right, no gaps
- **Frame Size**: Must be consistent (all same width/height)
