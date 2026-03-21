# Reverse Herding - Implementation Guide
**Generated:** January 11, 2026
**Goal:** Fix reverse herding once and for all

## Quick Reference: Exact Code Changes

### Change 1: Add Hysteresis to Speed Adjustment
**File:** `scripts/npc/states/herd_wildnpc_state.gd`  
**Lines:** 518-531  
**Replace current speed adjustment with hysteresis version**

### Change 2: Fix Follower Target Placement
**File:** `scripts/npc/states/herd_state.gd`  
**Lines:** 138-151  
**Add direction validation to prevent target behind herder**

### Change 3: Improve Safety Check
**File:** `scripts/npc/states/herd_wildnpc_state.gd`  
**Lines:** 498-511  
**Lower threshold and add oscillation detection**

### Change 4: Add Safeguards to Leading Logic
**File:** `scripts/npc/states/herd_wildnpc_state.gd`  
**Lines:** 476-486  
**Add multiple checks to ensure leading logic executes**

---

## Why These Fixes Work

1. **Hysteresis:** Breaks feedback loop by creating dead zone where speed doesn't change
2. **Target Fix:** Prevents follower from moving away from herder
3. **Safety Check:** Catches any remaining cases with lower threshold
4. **Safeguards:** Ensures leading logic always executes when target is herded

---

**Ready to implement these fixes?**
