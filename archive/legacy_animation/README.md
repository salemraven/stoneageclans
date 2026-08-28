# Legacy animation lock-in scripts (archived 2026-08-17)

Moved here during **unified-only Pose Tuner cutover**. These tools wrote or validated flat `walk1_*` fields and/or dual-wrote legacy + unified clips.

| File | Was |
|------|-----|
| `lockin_walk1_pose_a.gd` | Legacy Walk Pose 1 flat fields |
| `lockin_walk1_pose_b.gd` | Legacy Walk Pose 2 flat fields |
| `lockin_walk_clansmen_1_legacy_dual_write.gd` | Unified + legacy dual-write lock-in |

**Replacement:** Pose Tuner → **Save Animation** → `animation_clips[]` on preset `.tres`. Fresh defaults: `godot --headless -s res://tools/reset_all_presets_unified.gd`.

In-game runtime cutover (Milestone 4) is separate — see plan `unified-only_tuner_cutover`.
