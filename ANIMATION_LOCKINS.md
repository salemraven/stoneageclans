# Animation Lock-In Log
## Standardized format for capturing and locking animation poses

### Format Guide

Each animation pose should be captured with this structure:

```
## [Animation Name] Pose [A/B/etc] - [Date]
Holdable: [none/spear/club/etc]
Body: clansmen_1

### Pin Data
shoulder_1: (X, Y)
shoulder_2: (X, Y)
hand_1: (X, Y)
hand_2: (X, Y)
elbow_1_pole: (X, Y)
elbow_2_pole: (X, Y)
elbow_1_bend: [+1.0 / -1.0 / 0.0]
elbow_2_bend: [+1.0 / -1.0 / 0.0]
overlay: (X, Y)

### Arm Config
upper_length: 120.0
lower_length: 120.0
arm_width: 14.0
hand_width: 10.0

### Notes
[Any special notes about this pose]
```

---

## Locked Animations

### Walk 1 Pose A - 2026-08-15 (receipt lock-in)
**Holdable:** none  
**Body:** clansmen_1  
**Description:** Walk Pose 1 — right-side swing frame

**Pin Data:**
- shoulder_1: (118.0, -179.0)
- shoulder_2: (-95.0, -178.0)
- hand_1: (115.7, 60.39)
- hand_2: (20.18, 31.88)
- elbow_1_pole: (108.22, -59.39)
- elbow_2_pole: (-44.97, -68.91)
- elbow_1_bend: -1.0 (outward -)
- elbow_2_bend: -1.0 (outward -)
- overlay: (22.0, -34.0)

**Lock-in script:** `tools/lockin_walk1_pose_a.gd`  
**Status:** ✅ LOCKED - Do not modify without sign-off

---

### Walk 1 Pose B - 2026-08-15 (receipt lock-in)
**Holdable:** none  
**Body:** clansmen_1  
**Description:** Walk Pose 2 — opposite swing frame

**Pin Data:**
- hand_1: (233.16, 29.45)
- hand_2: (-163.4, 44.14)
- elbow_1_pole: (162.56, -67.58)
- elbow_2_pole: (-157.77, -75.73)
- elbow_1_bend: -1.0
- elbow_2_bend: -1.0

**Lock-in script:** `tools/lockin_walk1_pose_b.gd` + `tools/lockin_walk_clansmen_1.gd`  
**Golden:** `Tests/golden/walk1_motion.json`  
**Status:** ✅ LOCKED

---

### Idle Rest - 2026-08-15
**Holdable:** none  
**Body:** clansmen_1  

**Pin Data:**
- hand_1: (127.90, 51.48)
- hand_2: (17.75, 24.56)
- elbow_1_pole: (89.89, -62.34)
- elbow_2_pole: (-65.77, -61.62)
- overlay: (22.0, -34.0)

**Lock-in script:** `tools/lockin_idle_none_clansmen_1.gd` + `tools/lockin_none_clansmen_1.gd`  
**Golden:** `Tests/golden/idle_motion.json`  
**Status:** ✅ LOCKED

---

### Spear Idle (default baseline) - 2026-08-15
**Holdable:** spear  
**Body:** clansmen_1  
**Note:** Default shaft grip — needs visual re-tune in tuner before final sign-off

**Lock-in script:** `tools/lockin_spear_clansmen_1.gd`  
**Golden:** `Tests/golden/spear_idle1_motion.json`  
**Status:** ⚠️ BASELINE (not visually signed off)

---

### Club Windup Loop (placeholder) - 2026-08-15
**Holdable:** club (WOOD)  
**Body:** clansmen_1  
**Note:** Placeholder keyframes — needs visual re-tune

**Lock-in script:** `tools/lockin_club_clansmen_1.gd`  
**Status:** ⚠️ BASELINE (not visually signed off)

---

### Gather 1 - Pending
**Lock-in script:** `tools/lockin_gather_clansmen_1.gd` (skips until `gather1_motion.json` locked=true)  
**Status:** ❌ NOT LOCKED

---

## Usage Instructions

### 1. Author a pose in the tuner
- Drag pins to desired positions
- Right-click 1e/2e to flip elbows
- Click "Copy for chat" to export data

### 2. Create lock-in script
```bash
# Template: tools/lockin_[animation]_pose_[letter].gd
# Copy from lockin_walk1_pose_a.gd and update constants
```

### 3. Run lock-in
```bash
godot --headless -s res://tools/lockin_[animation]_pose_[letter].gd
```

### 4. Verify and commit
```bash
# Check that it prints: PASS
git add tools/lockin_*.gd assets/limb_presets/*.tres
git commit -m "feat: lock in [animation] pose [letter]"
```

### 5. Update this log
Add the pose to the "Locked Animations" section above

---

## Protection Rules

1. **Locked poses are immutable** - only change with explicit sign-off
2. **Each pose has its own lock-in script** - validates exact values
3. **Lock-in scripts run in CI** - prevents drift
4. **Isolation architecture** - changing walk won't break idle
5. **Version control** - git tracks every change

---

## Next Animation Checklist

- [x] Walk 1 Pose B
- [x] Idle rest pose
- [x] Walk 1 motion validation test
- [x] Golden trajectory capture (idle + walk1)
- [x] Document isolation architecture in animation_tuner.md
- [ ] Spear idle visual sign-off
- [ ] Gather reach/pull author + lock
- [ ] Club windup visual re-tune
