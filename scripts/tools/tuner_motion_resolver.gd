extends RefCounted
class_name TunerMotionResolver

## Single walk-preview decision path for Character Tuner, baker, and runtime parity.

const AnimMode = WeaponLimbPreset.TunerAnimMode

enum PreviewMotion { IDLE, WALK }


static func walk_sample_mode() -> int:
	return AnimMode.WALK1


static func travel_walk_swing_active() -> bool:
	## Legacy WalkArmSwing travel preview — retired; Walk 1 keyframes only.
	return false


static func walk_keyframe_preview_active(
	preview_motion: int,
	anim_mode: int,
	rig: Node,
	walk_pose_edit: bool,
	anim_playing: bool
) -> bool:
	if preview_motion == PreviewMotion.WALK:
		return true
	if not WeaponLimbPreset.is_walk_mode(anim_mode):
		return false
	if walk_pose_edit:
		return true
	if anim_playing and WeaponLimbPreset.is_walk_mode(anim_mode):
		return true
	if rig == null:
		return false
	return rig.is_walk_keyframe_playing() or rig.is_walking()


static func should_tick_walk_keyframes(
	preview_motion: int,
	preview_walk_mode: bool,
	walk_keyframe_overlay: bool
) -> bool:
	return preview_walk_mode or preview_motion == PreviewMotion.WALK or walk_keyframe_overlay
