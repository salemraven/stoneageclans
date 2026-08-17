extends RefCounted
class_name CharacterAnimationSampler

## Deterministic Pose 1 ↔ Pose 2 ping-pong sampler for tuner, reviewer, bake, and runtime visuals.

const CharacterAnimationPoseScript = preload("res://scripts/config/character_animation_pose.gd")
const ProceduralArmScript = preload("res://scripts/systems/procedural_arm.gd")


static func ping_pong_phase(elapsed_sec: float, duration_sec: float) -> float:
	if duration_sec <= 0.001:
		return 0.0
	var cycle := elapsed_sec / duration_sec
	var ping := fmod(cycle, 2.0)
	if ping > 1.0:
		ping = 2.0 - ping
	return clampf(ping, 0.0, 1.0)


static func sample_clip(clip, elapsed_sec: float):
	if clip == null:
		return CharacterAnimationPoseScript.new()
	var pose_a = clip.pose_at_index(0)
	var pose_b = clip.pose_at_index(1)
	if pose_a == null or pose_b == null:
		return CharacterAnimationPoseScript.new()
	var t := ping_pong_phase(elapsed_sec, clip.duration_sec)
	return sample_between(pose_a, pose_b, t)


static func sample_between(pose_a, pose_b, t: float):
	if pose_a == null or pose_b == null:
		return pose_a.duplicate_pose() if pose_a else CharacterAnimationPoseScript.new()
	if _needs_front_sweep(pose_a, pose_b):
		return _sample_with_front_sweep(pose_a, pose_b, t)
	return pose_a.lerp_to(pose_b, t)


static func _needs_front_sweep(pose_a, pose_b) -> bool:
	var weapon_flip := (
		absf(pose_a.elbow_weapon_bend_sign) > 0.001
		and absf(pose_b.elbow_weapon_bend_sign) > 0.001
		and signf(pose_a.elbow_weapon_bend_sign) != signf(pose_b.elbow_weapon_bend_sign)
	)
	var support_flip := (
		absf(pose_a.elbow_support_bend_sign) > 0.001
		and absf(pose_b.elbow_support_bend_sign) > 0.001
		and signf(pose_a.elbow_support_bend_sign) != signf(pose_b.elbow_support_bend_sign)
	)
	return weapon_flip or support_flip


static func _sample_with_front_sweep(pose_a, pose_b, t: float):
	var eased := CharacterAnimationPoseScript._smoothstep01(t)
	var base = pose_a.lerp_to(pose_b, eased)
	if not _needs_front_sweep(pose_a, pose_b):
		return base
	var weapon_sweep := _sweep_elbow_display(
		pose_a.shoulder_weapon_px,
		pose_a.hand_weapon_px,
		pose_b.shoulder_weapon_px,
		pose_b.hand_weapon_px,
		pose_a.elbow_weapon_bend_sign,
		pose_b.elbow_weapon_bend_sign,
		eased
	)
	var support_sweep := _sweep_elbow_display(
		pose_a.shoulder_support_px,
		pose_a.hand_support_px,
		pose_b.shoulder_support_px,
		pose_b.hand_support_px,
		pose_a.elbow_support_bend_sign,
		pose_b.elbow_support_bend_sign,
		eased
	)
	if weapon_sweep.length_squared() > 0.0001:
		base = _apply_elbow_from_display(base, true, weapon_sweep)
	if support_sweep.length_squared() > 0.0001:
		base = _apply_elbow_from_display(base, false, support_sweep)
	return base


static func _sweep_elbow_display(
	shoulder_a: Vector2,
	hand_a: Vector2,
	shoulder_b: Vector2,
	hand_b: Vector2,
	bend_a: float,
	bend_b: float,
	t: float
) -> Vector2:
	if signf(bend_a) == signf(bend_b):
		return Vector2.ZERO
	var upper := 140.0
	var lower := 140.0
	var rest_elbow := ProceduralArmScript.estimate_elbow_position(
		shoulder_a, hand_a, upper, lower, _auto_sweep_pole(shoulder_a, hand_a), true
	)
	var raised_elbow := ProceduralArmScript.estimate_elbow_position(
		shoulder_b, hand_b, upper, lower, _auto_sweep_pole(shoulder_b, hand_b), true
	)
	var mid_shoulder := shoulder_a.lerp(shoulder_b, 0.42)
	var mid_hand := hand_a.lerp(hand_b, 0.52)
	var front_elbow := ProceduralArmScript.estimate_elbow_position(
		mid_shoulder, mid_hand, upper, lower, _auto_sweep_pole(mid_shoulder, mid_hand), true
	)
	return _quadratic_bezier(rest_elbow, front_elbow, raised_elbow, t)


static func _auto_sweep_pole(shoulder: Vector2, hand: Vector2) -> Vector2:
	var mid := shoulder.lerp(hand, 0.38)
	return mid + Vector2(maxf(56.0, -mid.x + 40.0), 36.0)


static func _quadratic_bezier(a: Vector2, b: Vector2, c: Vector2, t: float) -> Vector2:
	var u := 1.0 - t
	return a * (u * u) + b * (2.0 * u * t) + c * (t * t)


static func _apply_elbow_from_display(pose, _dominant: bool, _elbow_display: Vector2):
	return pose.duplicate_pose()


static func mirror_pose_for_facing(pose, facing_left: bool):
	if not facing_left or pose == null:
		return pose.duplicate_pose() if pose else CharacterAnimationPoseScript.new()
	var out = pose.duplicate_pose()
	out.shoulder_weapon_px.x = -out.shoulder_weapon_px.x
	out.shoulder_support_px.x = -out.shoulder_support_px.x
	out.hand_weapon_px.x = -out.hand_weapon_px.x
	out.hand_support_px.x = -out.hand_support_px.x
	out.overlay_offset_px.x = -out.overlay_offset_px.x
	out.head_offset_px.x = -out.head_offset_px.x
	out.grip_on_art_px.x = -out.grip_on_art_px.x
	if absf(out.elbow_weapon_bend_sign) > 0.001:
		out.elbow_weapon_bend_sign = -out.elbow_weapon_bend_sign
	if absf(out.elbow_support_bend_sign) > 0.001:
		out.elbow_support_bend_sign = -out.elbow_support_bend_sign
	return out
