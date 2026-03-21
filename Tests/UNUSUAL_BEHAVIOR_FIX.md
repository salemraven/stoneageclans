# Unusual NPC Behavior Fix

## Issues Identified

### 1. Head-On Positioning Too Strict
- **Problem**: NPCs constantly repositioning, never getting into attack range
- **Cause**: Head-on alignment checks were too strict (60° tolerance, 25px vertical)
- **Result**: NPCs oscillate trying to get perfect alignment

### 2. Repositioning Logic Causing Oscillation
- **Problem**: NPCs keep moving to calculated positions that keep changing
- **Cause**: Target is also moving, so calculated position keeps shifting
- **Result**: Constant repositioning, never attacking

## Fixes Applied

### 1. More Lenient Head-On Checks
- **Angle tolerance**: Increased from 60° (PI/3) to ~72° (PI/2.5) for repositioning
- **Vertical offset**: Increased from 25px to 35px for attack validation
- **Repositioning threshold**: Only reposition if vertical_distance > 40px (was 30px)

### 2. Simplified Repositioning Logic
- **Too far**: Only reposition if distance > attack_range * 1.2 (20% buffer)
- **Severe misalignment**: Only reposition if angle > 72° AND vertical > 35px
- **Prevents oscillation**: Less frequent repositioning = more stable combat

### 3. Attack Range Flexibility
- Allow attacks up to 1.2x attack_range before forcing reposition
- Prevents constant back-and-forth movement

## Expected Behavior

- NPCs position head-on but don't obsess over perfect alignment
- Less oscillation and repositioning
- More natural combat flow
- Attacks happen more reliably
