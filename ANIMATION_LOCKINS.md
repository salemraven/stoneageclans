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

### Walk 1 Pose A - 2026-08-15
**Holdable:** none  
**Body:** clansmen_1  
**Description:** Right forward, left back pendulum position

**Pin Data:**
- shoulder_1: (118.0, -179.0)
- shoulder_2: (-95.0, -178.0)
- hand_1: (225.82, 34.35)
- hand_2: (-173.19, 41.69)
- elbow_1_pole: (181.45, -77.15)
- elbow_2_pole: (-160.83, -77.67)
- elbow_1_bend: -1.0 (outward -)
- elbow_2_bend: +1.0 (outward +)
- overlay: (22.0, -34.0)

**Lock-in script:** `tools/lockin_walk1_pose_a.gd`  
**Status:** ✅ LOCKED - Do not modify without sign-off

---

### Walk 1 Pose B - [Pending]
**Next to author**

---

## Usage Instructions

### 1. Author a pose in the tuner
- Drag pins to desired positions
- Use Shift+click to flip elbows
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

- [ ] Walk 1 Pose B
- [ ] Idle (simple breathe/sway)
- [ ] Walk 1 motion validation test
- [ ] Golden trajectory capture
- [ ] Document in animation_tuner.md
