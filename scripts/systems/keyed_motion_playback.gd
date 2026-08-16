extends RefCounted
class_name KeyedMotionPlayback

## Keyed animation playback — one motion source for hands AND elbows.
##
## Rule: while `is_active`, never drive elbows from ProceduralArmController generic IK.
## Each animation mode delegates to its motion file / rig pose extremes (lerp A→B).

const WalkArmMotionScript = preload("res://scripts/systems/walk_arm_motion.gd")
const GatherArmMotionScript = preload("res://scripts/systems/gather_arm_motion.gd")


static func is_active(
	rig: LimbTunerRig,
	mode: WeaponLimbPreset.TunerAnimMode
) -> bool:
	if rig == null:
		return false
	match mode:
		WeaponLimbPreset.TunerAnimMode.WALK1:
			return rig.is_walk_keyframe_playing()
		WeaponLimbPreset.TunerAnimMode.GATHER1:
			return rig.is_gather_preview_playing()
	return false


static func elbow_global(
	rig: LimbTunerRig,
	preset: WeaponLimbPreset,
	dominant: bool,
	mode: WeaponLimbPreset.TunerAnimMode,
	shoulder_global: Vector2
) -> Vector2:
	if rig == null or preset == null:
		return shoulder_global
	return rig.elbow_joint_global_from_keyed_motion(preset, dominant, mode, shoulder_global)
