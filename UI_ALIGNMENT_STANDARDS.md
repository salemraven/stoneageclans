# UI Alignment Standards

## Panel Layout Standards

### Padding & Margins
- **Panel Padding**: 8px on all sides (16px total width/height)
- **Title Bar Height**: 24px
- **Slot Spacing**: 6px between slots (horizontal and vertical)
- **Hotbar Padding**: 12px from bottom of screen
- **Hotbar Internal Padding**: 12px on all sides

### Slot Dimensions
- **Standard Slots**: 64x64 pixels
- **Hotbar Slots**: 32x32 pixels
- **Icon Size**: 32x32 pixels (centered in slot)
- **Slot Border**: 2px width

### Panel Structure
```
Panel
├── Title Bar (24px height)
│   ├── Title Label (centered)
│   └── Close Button (24x24, top right, 2px padding)
└── Margin Container (8px margins)
    └── Grid Container
        └── Slots (64x64, 6px spacing)
```

## Default Positions

### Player Inventory
- **Position**: Center of screen
- **Vertical Offset**: 100px up from center (to account for hotbar)
- **Formula**: `(viewport_width - panel_width) / 2, (viewport_height - panel_height) / 2 - 100`

### Building Inventory
- **Default Position**: Left of center
- **Horizontal Offset**: Panel width + 20px gap from center
- **Vertical Offset**: 100px up from center
- **Formula**: `center_x - panel_width - 20, center_y - 100`
- **Alternative**: Positioned near building if building is visible

### Cart/Backpack Inventory
- **Default Position**: Right of center
- **Horizontal Offset**: Panel width + 20px gap from center
- **Vertical Offset**: 100px up from center
- **Formula**: `center_x + panel_width + 20, center_y - 100`

### Hotbar
- **Position**: Bottom center
- **Vertical Offset**: 12px from bottom
- **Formula**: `(viewport_width - hotbar_width) / 2, viewport_height - hotbar_height - 12`

## Alignment Rules

### Grid Alignment
- All slots align to a 64x64 grid
- 6px spacing between slots creates 70px centers (64 + 6)
- Grid containers use `h_separation: 6` and `v_separation: 6`

### Text Alignment
- **Title**: Centered horizontally and vertically in title bar
- **Count Label**: Top-right corner of slot (2px from edge)
- **Tooltip**: Appears to the right of slot (or left if no space)

### Visual Alignment
- All panels use consistent styling (colors, borders, shadows)
- Title bar is always 24px height
- Close button is always 24x24, positioned at top right with 2px padding
- Slots have 2px borders that brighten on hover

## Spacing Standards

### Between Panels
- **Minimum Gap**: 20px when positioned side-by-side
- **Overlap Prevention**: Panels automatically push apart if overlapping

### Within Panels
- **Content Padding**: 8px from panel edges
- **Title Bar**: 24px height, no padding (content fills)
- **Slot Grid**: 6px spacing between slots

## Size Calculations

### Panel Width
```
width = (columns × 64) + ((columns - 1) × 6) + 16
```
- Columns × slot width
- Plus spacing between slots
- Plus 8px padding on each side (16px total)

### Panel Height
```
height = (rows × 64) + ((rows - 1) × 6) + 24 + 16
```
- Rows × slot height
- Plus spacing between rows
- Plus 24px title bar
- Plus 8px padding top and bottom (16px total)

### Hotbar Width
```
width = (7 × 32) + (6 × 6) + (12 × 2)
```
- 7 slots × 32px
- 6 gaps × 6px
- 12px padding on each side (24px total)

## Testing Checklist

- [ ] All panels align to grid
- [ ] Slots are evenly spaced (6px gaps)
- [ ] Title bars are consistent (24px height)
- [ ] Close buttons are properly positioned
- [ ] Default positions don't overlap
- [ ] Hotbar is centered at bottom
- [ ] Panels clamp to screen bounds
- [ ] Text is properly aligned
- [ ] Icons are centered in slots
- [ ] Borders are consistent (2px)

