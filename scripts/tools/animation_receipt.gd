extends RefCounted
class_name AnimationReceipt

## Full animation receipt for Copy for chat — one paste = lock-in ready bundle.

const AnimCatalog = preload("res://scripts/config/character_animation_catalog.gd")
const WalkArmMotion = preload("res://scripts/systems/walk_arm_motion.gd")
const GatherArmMotion = preload("res://scripts/systems/gather_arm_motion.gd")
const LimbPresetRegistryScript = preload("res://scripts/systems/limb_preset_registry.gd")

const RECEIPT_VERSION := 1


static func build(
	preset: WeaponLimbPreset,
	mode: WeaponLimbPreset.TunerAnimMode,
	holdable_label: String,
	anim_label: String,
	rig: LimbTunerRig = null
) -> Dictionary:
	var receipt := {
		"receipt_version": RECEIPT_VERSION,
		"generated_utc_hint": Time.get_datetime_string_from_system(true),
		"lock_in_instruction": (
			"Paste this receipt in chat and say: lock in this animation"
		),
		"holdable": holdable_label,
		"holdable_type": preset.weapon_type,
		"body_card_id": preset.body_card_id,
		"animation_mode": _mode_slug(mode),
		"animation_label": anim_label,
		"preset_resource": _preset_resource_path(preset),
		"morphology": _build_morphology(preset, rig),
		"anchors": _build_anchors(preset),
		"orientation": _build_orientation(preset, mode, rig),
		"animation": _build_animation_block(preset, mode, rig),
	}
	return receipt


static func format_clipboard(receipt: Dictionary) -> String:
	var lines: PackedStringArray = PackedStringArray()
	lines.append("=== Stone Age Clans · Animation Receipt v%d ===" % int(receipt.get("receipt_version", 1)))
	lines.append(str(receipt.get("lock_in_instruction", "")))
	lines.append("")
	lines.append(
		"Holdable: %s · Body: %s · Animation: %s (%s)"
		% [
			receipt.get("holdable", "?"),
			receipt.get("body_card_id", "?"),
			receipt.get("animation_label", "?"),
			receipt.get("animation_mode", "?"),
		]
	)
	lines.append("Preset: %s" % receipt.get("preset_resource", "?"))
	if receipt.has("generated_utc_hint"):
		lines.append("Generated: %s" % receipt.get("generated_utc_hint"))
	lines.append("")
	_append_section(lines, "Morphology (shared rig)", receipt.get("morphology", {}))
	_append_section(lines, "Anchors (shoulders / head layout)", receipt.get("anchors", {}))
	_append_section(lines, "Orientation", receipt.get("orientation", {}))
	_append_animation_human(lines, receipt.get("animation", {}))
	lines.append("")
	lines.append("--- JSON (machine-readable lock-in bundle) ---")
	lines.append(JSON.stringify(receipt, "\t"))
	return "\n".join(lines)


static func _append_section(lines: PackedStringArray, title: String, block: Dictionary) -> void:
	lines.append("--- %s ---" % title)
	if block.is_empty():
		lines.append("(none)")
		lines.append("")
		return
	for key in block.keys():
		lines.append("%s: %s" % [str(key), _stringify_value(block[key])])
	lines.append("")


static func _append_animation_human(lines: PackedStringArray, anim: Dictionary) -> void:
	lines.append("--- Animation data ---")
	if anim.is_empty():
		lines.append("(none)")
		return
	if anim.has("weapon_overlay"):
		_append_section(lines, "Weapon / holdable overlay", anim["weapon_overlay"])
	if anim.has("pose_rows"):
		for row in anim["pose_rows"] as Array:
			_append_pose_row(lines, row as Dictionary)
	if anim.has("single_pose"):
		_append_pose_row(lines, anim["single_pose"] as Dictionary)
	if anim.has("motion"):
		_append_motion(lines, anim["motion"] as Dictionary)
	if anim.has("extra_fields"):
		_append_section(lines, "Extra fields", anim["extra_fields"])


static func _append_pose_row(lines: PackedStringArray, row: Dictionary) -> void:
	if row.is_empty():
		return
	lines.append("--- Pose: %s ---" % row.get("label", "?"))
	if row.has("saved"):
		lines.append("saved: %s" % str(row["saved"]))
	for pin_key in ["hand_1", "hand_2", "elbow_1_pole", "elbow_2_pole", "overlay", "head"]:
		if row.has(pin_key):
			lines.append("%s: %s" % [pin_key, _stringify_value(row[pin_key])])
	for bend_key in ["elbow_1_bend", "elbow_2_bend"]:
		if row.has(bend_key):
			lines.append("%s: %s" % [bend_key, row[bend_key]])
	if row.has("rotation_deg"):
		lines.append("rotation_deg: %s" % _stringify_value(row["rotation_deg"]))
	if row.has("lock_in_constants"):
		lines.append("lock_in_constants:")
		for const_name in (row["lock_in_constants"] as Dictionary).keys():
			var v = row["lock_in_constants"][const_name]
			lines.append("  %s = %s" % [const_name, _stringify_value(v)])
	lines.append("")


static func _append_motion(lines: PackedStringArray, motion: Dictionary) -> void:
	lines.append("--- Motion (how poses blend) ---")
	for key in motion.keys():
		if key == "samples":
			continue
		lines.append("%s: %s" % [str(key), _stringify_value(motion[key])])
	if motion.has("samples"):
		lines.append("samples:")
		for sample in motion["samples"] as Array:
			lines.append("  %s" % JSON.stringify(sample))
	lines.append("")


static func _build_morphology(preset: WeaponLimbPreset, rig: LimbTunerRig) -> Dictionary:
	var out := {
		"upper_arm_length_px": preset.upper_arm_length,
		"lower_arm_length_px": preset.lower_arm_length,
		"weapon_upper_arm_length_px": preset.weapon_upper_arm_length,
		"weapon_lower_arm_length_px": preset.weapon_lower_arm_length,
		"support_upper_arm_length_px": preset.support_upper_arm_length,
		"support_lower_arm_length_px": preset.support_lower_arm_length,
		"arm_width_px": preset.arm_width,
		"hand_width_px": preset.hand_width,
		"elbow_hint_outward_px": preset.elbow_hint_outward,
	}
	if rig != null:
		if rig.sprite != null:
			out["mannequin_sprite_scale"] = rig.sprite.scale
		var layout = rig.get_layer_layout() if rig.has_method("get_layer_layout") else null
		if layout != null:
			out["body_texture"] = layout.body_texture_path
			out["head_texture"] = layout.head_texture_path
			out["body_neck_socket_px"] = _vec2_array(layout.body_neck_socket_px)
			out["head_pivot_px"] = _vec2_array(layout.head_pivot_px)
			out["body_offset_px"] = _vec2_array(layout.body_offset_px)
		if rig.has_method("get_mannequin_layout"):
			var mannequin = rig.get("_mannequin_layout")
			if mannequin != null:
				out["card_ref_texture_height"] = mannequin.ref_texture_height
				out["card_display_height"] = mannequin.display_height
	return out


static func _build_anchors(preset: WeaponLimbPreset) -> Dictionary:
	return {
		"shoulder_1_px": _vec2_array(preset.shoulder_offset_px),
		"shoulder_2_px": _vec2_array(preset.support_shoulder_offset_px),
		"support_shoulder_idle_raise_offset_px": _vec2_array(
			preset.support_shoulder_idle_raise_offset_px
		),
	}


static func _build_orientation(
	preset: WeaponLimbPreset,
	mode: WeaponLimbPreset.TunerAnimMode,
	rig: LimbTunerRig
) -> Dictionary:
	var out := {
		"overlay_rotation_deg": _rotation_for_export(preset.get_rotation_deg_for_mode(mode)),
	}
	if rig != null and rig.sprite != null:
		out["body_flip_h"] = rig.sprite.flip_h
		if rig.has_method("get_walk_direction"):
			out["walk_travel_direction"] = rig.get_walk_direction()
	return out


static func _build_animation_block(
	preset: WeaponLimbPreset,
	mode: WeaponLimbPreset.TunerAnimMode,
	rig: LimbTunerRig
) -> Dictionary:
	var block := {}
	block["weapon_overlay"] = _build_weapon_overlay_block(preset, mode, rig)
	match mode:
		WeaponLimbPreset.TunerAnimMode.WALK1:
			block["pose_rows"] = [
				_build_walk1_pose_row(preset, false),
				_build_walk1_pose_row(preset, true),
			]
			block["motion"] = _build_walk1_motion(preset)
		WeaponLimbPreset.TunerAnimMode.GATHER1:
			block["pose_rows"] = [
				_build_gather1_pose_row(preset, false),
				_build_gather1_pose_row(preset, true),
			]
			block["motion"] = _build_gather1_motion(preset)
		WeaponLimbPreset.TunerAnimMode.ATTACK:
			block["single_pose"] = _build_attack_pose_row(preset)
		WeaponLimbPreset.TunerAnimMode.IDLE_CLUB1:
			block["single_pose"] = _build_idle_club1_pose_row(preset)
		_:
			block["single_pose"] = _build_generic_pose_row(preset, mode)
	return block


static func _build_weapon_overlay_block(
	preset: WeaponLimbPreset,
	mode: WeaponLimbPreset.TunerAnimMode,
	rig: LimbTunerRig
) -> Dictionary:
	var out := {
		"weapon_type": preset.weapon_type,
		"overlay_display_px": _vec2_array(preset.resolve_overlay_for_mode(mode)),
	}
	if preset.weapon_type == ResourceData.ResourceType.WOOD and mode != WeaponLimbPreset.TunerAnimMode.ATTACK:
		out["club_grip_on_art_px"] = _vec2_array(preset.resolve_club_overlay_grip_px(mode))
		if preset.uses_saved_club_grip_on_art():
			out["club_carry_body_hand_px"] = _vec2_array(preset.resolve_club_carry_body_hand_px())
	if rig != null and rig.has_weapon_overlay() and rig.weapon_overlay != null:
		out["live_overlay_rotation_deg"] = rad_to_deg(rig.weapon_overlay.rotation)
		if rig.has_method("display_px_from_overlay_position"):
			out["live_overlay_display_px"] = _vec2_array(rig.display_px_from_overlay_position())
	return out


static func _build_walk1_pose_row(preset: WeaponLimbPreset, pose_b: bool) -> Dictionary:
	var label := "Pose 2" if pose_b else "Pose 1"
	var hand_1_px := preset.resolve_club_walk1_dominant_hand_export(pose_b)
	var row := {
		"row_id": "walk1_b" if pose_b else "walk1_a",
		"label": label,
		"saved": preset.walk1_pose_b_saved if pose_b else preset.walk1_pose_a_saved,
		"hand_1": _vec2_array(hand_1_px),
		"hand_2": _vec2_array(
			preset.walk1_pull_support_hand_offset_px
			if pose_b
			else preset.walk1_support_hand_offset_px
		),
		"elbow_1_pole": _vec2_array(
			preset.resolve_walk1_elbow_pole_px(true, pose_b)
		),
		"elbow_2_pole": _vec2_array(
			preset.resolve_walk1_elbow_pole_px(false, pose_b)
		),
		"elbow_1_bend": WeaponLimbPreset.bend_sign_chat_label(
			preset.resolve_elbow_bend_sign_for_pose(
				true, WeaponLimbPreset.TunerAnimMode.WALK1, pose_b, false, 0.0
			)
		),
		"elbow_2_bend": WeaponLimbPreset.bend_sign_chat_label(
			preset.resolve_elbow_bend_sign_for_pose(
				false, WeaponLimbPreset.TunerAnimMode.WALK1, pose_b, false, 0.0
			)
		),
		"overlay": _vec2_array(preset.walk1_overlay_offset_px),
		"rotation_deg": _rotation_for_export(preset.walk1_rotation_deg),
	}
	if preset.weapon_type == ResourceData.ResourceType.WOOD and preset.uses_club_walk_off_arm_travel_swing():
		row["hand_1_role"] = "body_carry"
		row["grip_on_art_px"] = _vec2_array(preset.idle_club1_hand_grip_offset_px)
		row["note"] = "Club Walk 1: hand_1 is body-card carry; off-arm uses empty-hands Walk 1 keyframe loop on hand_2"
	var suffix := "B" if pose_b else "A"
	row["lock_in_constants"] = {
		"WALK1_%s_HAND_1" % suffix: row["hand_1"],
		"WALK1_%s_HAND_2" % suffix: row["hand_2"],
		"WALK1_%s_ELBOW_1_POLE" % suffix: row["elbow_1_pole"],
		"WALK1_%s_ELBOW_2_POLE" % suffix: row["elbow_2_pole"],
	}
	return row


static func _build_walk1_motion(preset: WeaponLimbPreset) -> Dictionary:
	var hand_1_a := preset.walk1_hand_grip_offset_px
	var hand_1_b := preset.walk1_pull_hand_grip_offset_px
	var hand_2_a := preset.walk1_support_hand_offset_px
	var hand_2_b := preset.walk1_pull_support_hand_offset_px
	var pole_1_a := preset.walk1_weapon_elbow_pole_px
	var pole_1_b := preset.walk1_pull_weapon_elbow_pole_px
	var pole_2_a := preset.walk1_support_elbow_pole_px
	var pole_2_b := preset.walk1_pull_support_elbow_pole_px
	var samples: Array = []
	for phase in [0.0, 0.25, 0.5, 0.75, 1.0]:
		samples.append({
			"phase": phase,
			"hand_1": _vec2_array(
				WalkArmMotion.body_snapshot_between_keyframes(hand_1_a, hand_1_b, phase)
			),
			"hand_2": _vec2_array(
				WalkArmMotion.body_snapshot_between_keyframes(hand_2_a, hand_2_b, phase)
			),
			"elbow_1_pole": _vec2_array(
				WalkArmMotion.body_snapshot_between_keyframes(pole_1_a, pole_1_b, phase)
			),
			"elbow_2_pole": _vec2_array(
				WalkArmMotion.body_snapshot_between_keyframes(pole_2_a, pole_2_b, phase)
			),
		})
	return {
		"driver": "WalkArmMotion.body_snapshot_between_keyframes",
		"elbow_driver": "KeyedMotionPlayback (lerp solved elbows at pose extremes)",
		"bounce_cycles_per_arm_cycle": WalkArmMotion.BOUNCE_CYCLES_PER_ARM_CYCLE,
		"blend": "cosine pendulum (1-cos(phase*TAU))/2",
		"samples": samples,
	}


static func _build_gather1_pose_row(preset: WeaponLimbPreset, pull: bool) -> Dictionary:
	var label := "Pull" if pull else "Reach"
	return {
		"row_id": "gather_pull" if pull else "gather_reach",
		"label": label,
		"saved": preset.gather1_pull_saved if pull else preset.gather1_reach_saved,
		"hand_1": _vec2_array(
			preset.gather1_pull_hand_grip_offset_px
			if pull
			else preset.gather1_hand_grip_offset_px
		),
		"hand_2": _vec2_array(
			preset.gather1_pull_support_hand_offset_px
			if pull
			else preset.gather1_support_hand_offset_px
		),
		"elbow_1_pole": _vec2_array(preset.resolve_gather1_elbow_pole_px(true, pull)),
		"elbow_2_pole": _vec2_array(preset.resolve_gather1_elbow_pole_px(false, pull)),
		"elbow_1_bend": WeaponLimbPreset.bend_sign_chat_label(
			preset.resolve_elbow_bend_sign_for_pose(
				true, WeaponLimbPreset.TunerAnimMode.GATHER1, false, pull, 0.0
			)
		),
		"elbow_2_bend": WeaponLimbPreset.bend_sign_chat_label(
			preset.resolve_elbow_bend_sign_for_pose(
				false, WeaponLimbPreset.TunerAnimMode.GATHER1, false, pull, 0.0
			)
		),
		"overlay": _vec2_array(preset.gather1_overlay_offset_px),
		"rotation_deg": _rotation_for_export(preset.gather1_rotation_deg),
	}


static func _build_gather1_motion(preset: WeaponLimbPreset) -> Dictionary:
	var samples: Array = []
	for phase in [0.0, 0.25, 0.5, 0.75, 1.0]:
		var arm_work := GatherArmMotion.arm_work_phase(phase)
		var hand_1 := preset.gather1_hand_grip_offset_px
		var hand_2 := preset.gather1_support_hand_offset_px
		if arm_work >= 0.0 and preset.has_gather1_pull_pose():
			var blend := GatherArmMotion.keyframe_blend(arm_work, true)
			hand_1 = hand_1.lerp(preset.gather1_pull_hand_grip_offset_px, blend)
			var blend_2 := GatherArmMotion.keyframe_blend(arm_work, false)
			hand_2 = hand_2.lerp(preset.gather1_pull_support_hand_offset_px, blend_2)
		samples.append({
			"phase": phase,
			"arm_work": arm_work,
			"body_bend_rad": GatherArmMotion.body_bend_rad(phase),
			"hand_1": _vec2_array(hand_1),
			"hand_2": _vec2_array(hand_2),
		})
	return {
		"driver": "GatherArmMotion (bend envelope + reach↔pull pick)",
		"elbow_driver": "KeyedMotionPlayback",
		"cycle_speed": GatherArmMotion.CYCLE_SPEED,
		"samples": samples,
	}


static func _build_attack_pose_row(preset: WeaponLimbPreset) -> Dictionary:
	var row := {
		"row_id": "attack_windup",
		"label": "Attack / windup",
		"saved": (
			preset.spear_attack_pose_saved
			if preset.weapon_type == ResourceData.ResourceType.SPEAR
			else preset.club_attack_pose_saved
		),
		"hand_1": _vec2_array(preset.hand_grip_ready_offset_px),
		"hand_2": _vec2_array(preset.support_hand_offset_px),
		"overlay": _vec2_array(preset.ready_offset_px),
		"strike_overlay": _vec2_array(preset.strike_offset_px),
		"elbow_1_pole": _vec2_array(preset.weapon_elbow_pole_ready_px),
		"elbow_2_pole": _vec2_array(preset.support_elbow_pole_ready_px),
		"elbow_1_bend": WeaponLimbPreset.bend_sign_chat_label(
			preset.weapon_elbow_bend_sign_ready_override
		),
		"elbow_2_bend": WeaponLimbPreset.bend_sign_chat_label(
			preset.support_elbow_bend_sign_ready_override
		),
		"rotation_deg": _rotation_for_export(preset.attack_rotation_deg),
		"ready_forward_px": preset.ready_forward_px,
	}
	return row


static func _build_idle_club1_pose_row(preset: WeaponLimbPreset) -> Dictionary:
	return {
		"row_id": "idle_club1",
		"label": "Idle club grip",
		"grip_on_art_px": _vec2_array(preset.idle_club1_hand_grip_offset_px),
		"hand_1": _vec2_array(preset.idle_club1_hand_grip_offset_px),
		"hand_1_role": "grip_on_art",
		"hand_2": _vec2_array(preset.idle_club1_support_hand_offset_px),
		"overlay": _vec2_array(preset.idle_club1_overlay_offset_px),
		"elbow_1_pole": _vec2_array(preset.idle_club1_weapon_elbow_pole_px),
		"elbow_2_pole": _vec2_array(preset.idle_club1_support_elbow_pole_px),
		"rotation_deg": _rotation_for_export(preset.idle_club1_rotation_deg),
	}


static func _build_generic_pose_row(
	preset: WeaponLimbPreset,
	mode: WeaponLimbPreset.TunerAnimMode
) -> Dictionary:
	var row := {
		"row_id": _mode_slug(mode),
		"label": AnimCatalog.MODE_LABELS.get(mode, str(mode)),
		"hand_1": _vec2_array(preset.resolve_hand_grip_for_mode(mode)),
		"hand_2": _vec2_array(preset.resolve_support_hand_for_mode(mode)),
		"overlay": _vec2_array(preset.resolve_overlay_for_mode(mode)),
		"elbow_1_pole": _vec2_array(preset.resolve_elbow_pole_for_mode(true, mode)),
		"elbow_2_pole": _vec2_array(preset.resolve_elbow_pole_for_mode(false, mode)),
		"elbow_1_bend": WeaponLimbPreset.bend_sign_chat_label(
			preset.resolve_elbow_bend_sign_override(true, mode)
		),
		"elbow_2_bend": WeaponLimbPreset.bend_sign_chat_label(
			preset.resolve_elbow_bend_sign_override(false, mode)
		),
		"rotation_deg": _rotation_for_export(preset.get_rotation_deg_for_mode(mode)),
	}
	if (
		preset.weapon_type == ResourceData.ResourceType.WOOD
		and mode == WeaponLimbPreset.TunerAnimMode.IDLE
		and preset.uses_saved_club_grip_on_art()
	):
		row["hand_1"] = _vec2_array(preset.resolve_club_carry_body_hand_px())
		row["hand_1_role"] = "body_carry"
		row["grip_on_art_px"] = _vec2_array(preset.idle_club1_hand_grip_offset_px)
	return row


static func _preset_resource_path(preset: WeaponLimbPreset) -> String:
	var reg := LimbPresetRegistryScript.new()
	var slug := "clansmen_1"
	if preset.body_card_id.begins_with("clansmen_"):
		slug = preset.body_card_id
	return reg.preset_path(preset.weapon_type, slug)


static func _mode_slug(mode: WeaponLimbPreset.TunerAnimMode) -> String:
	match mode:
		WeaponLimbPreset.TunerAnimMode.IDLE:
			return "idle"
		WeaponLimbPreset.TunerAnimMode.IDLE1:
			return "idle1"
		WeaponLimbPreset.TunerAnimMode.WALK:
			return "walk"
		WeaponLimbPreset.TunerAnimMode.WALK1:
			return "walk1"
		WeaponLimbPreset.TunerAnimMode.GATHER1:
			return "gather1"
		WeaponLimbPreset.TunerAnimMode.IDLE_CLUB1:
			return "idle_club1"
		WeaponLimbPreset.TunerAnimMode.ATTACK:
			return "attack"
	return str(mode)


static func _rotation_for_export(deg: float) -> Variant:
	if deg <= WeaponLimbPreset.ROTATION_UNSET + 1.0:
		return "inherit_idle"
	return snappedf(deg, 0.01)


static func _vec2_array(v: Vector2) -> Array:
	return [snappedf(v.x, 0.01), snappedf(v.y, 0.01)]


static func _stringify_value(value: Variant) -> String:
	if value is Array:
		return JSON.stringify(value)
	if value is Dictionary:
		return JSON.stringify(value)
	return str(value)
