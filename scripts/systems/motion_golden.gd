class_name MotionGolden

## Load and validate motion samples against Tests/golden/*.json trajectories.

const WalkArmMotion = preload("res://scripts/systems/walk_arm_motion.gd")


static func load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var text := FileAccess.get_file_as_string(path)
	if text.is_empty():
		return {}
	var parsed: Variant = JSON.parse_string(text)
	return parsed if parsed is Dictionary else {}


static func validate_walk1_pendulum(
	golden_path: String,
	pose_a_hand_1: Vector2,
	pose_b_hand_1: Vector2,
	pose_a_hand_2: Vector2,
	pose_b_hand_2: Vector2
) -> Array[String]:
	var errors: Array[String] = []
	var data := load_json(golden_path)
	if data.is_empty():
		errors.append("golden missing: %s" % golden_path)
		return errors
	var tolerance := float(data.get("tolerance_px", 2.0))
	var samples: Array = data.get("samples", [])
	for sample in samples:
		if not sample is Dictionary:
			continue
		var phase := float(sample.get("phase", 0.0))
		var want_h1: Array = sample.get("hand_1", [])
		var want_h2: Array = sample.get("hand_2", [])
		if want_h1.size() >= 2:
			var want := Vector2(float(want_h1[0]), float(want_h1[1]))
			var got := WalkArmMotion.body_snapshot_between_keyframes(
				pose_a_hand_1, pose_b_hand_1, phase
			)
			if got.distance_to(want) > tolerance:
				errors.append(
					"walk1 hand_1 phase %.2f expected %s got %s" % [phase, str(want), str(got)]
				)
		if want_h2.size() >= 2:
			var want2 := Vector2(float(want_h2[0]), float(want_h2[1]))
			var got2 := WalkArmMotion.body_snapshot_between_keyframes(
				pose_a_hand_2, pose_b_hand_2, phase
			)
			if got2.distance_to(want2) > tolerance:
				errors.append(
					"walk1 hand_2 phase %.2f expected %s got %s" % [phase, str(want2), str(got2)]
				)
	return errors


static func validate_idle_rest(golden_path: String, preset: WeaponLimbPreset) -> Array[String]:
	var errors: Array[String] = []
	if preset == null:
		errors.append("preset null for idle golden")
		return errors
	var data := load_json(golden_path)
	if data.is_empty():
		errors.append("golden missing: %s" % golden_path)
		return errors
	var tolerance := float(data.get("tolerance_px", 2.0))
	var rest: Dictionary = data.get("rest", {})
	var hand_1: Array = rest.get("hand_1", [])
	var hand_2: Array = rest.get("hand_2", [])
	if hand_1.size() >= 2:
		var want := Vector2(float(hand_1[0]), float(hand_1[1]))
		if preset.hand_grip_offset_px.distance_to(want) > tolerance:
			errors.append("idle hand_1 golden mismatch")
	if hand_2.size() >= 2:
		var want2 := Vector2(float(hand_2[0]), float(hand_2[1]))
		if preset.support_hand_idle_offset_px.distance_to(want2) > tolerance:
			errors.append("idle hand_2 golden mismatch")
	return errors
