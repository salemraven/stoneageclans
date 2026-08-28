extends RefCounted
class_name AnimationReceipt

## Full animation receipt for Copy for chat — one paste = lock-in ready bundle.

const AnimCatalog = preload("res://scripts/config/character_animation_catalog.gd")
const CharacterAnimationPresetStoreScript = preload(
	"res://scripts/config/character_animation_preset_store.gd"
)
const CharacterAnimationSamplerScript = preload(
	"res://scripts/config/character_animation_sampler.gd"
)
const LimbPresetRegistryScript = preload("res://scripts/systems/limb_preset_registry.gd")

const RECEIPT_VERSION := 2


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
	if anim.has("clip_id"):
		lines.append("clip_id: %s" % anim.get("clip_id", "?"))
		lines.append("duration_sec: %s" % anim.get("duration_sec", "?"))
		lines.append(
			"saved: %s · pose_b_saved: %s"
			% [str(anim.get("saved", false)), str(anim.get("pose_b_saved", false))]
		)
		lines.append("")
	if anim.has("weapon_overlay"):
		_append_section(lines, "Weapon / holdable overlay", anim["weapon_overlay"])
	if anim.has("pose_a"):
		_append_pose_row(lines, anim["pose_a"] as Dictionary)
	if anim.has("pose_b"):
		_append_pose_row(lines, anim["pose_b"] as Dictionary)
	if anim.has("motion"):
		_append_motion(lines, anim["motion"] as Dictionary)


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
	if row.has("grip_on_art_px"):
		lines.append("grip_on_art_px: %s" % _stringify_value(row["grip_on_art_px"]))
	if row.has("hand_1_role"):
		lines.append("hand_1_role: %s" % row["hand_1_role"])
	if row.has("note"):
		lines.append("note: %s" % row["note"])
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
	preset.ensure_unified_clips(null)
	var clip_id := AnimCatalog.clip_id_for_mode(mode, preset.weapon_type)
	var clip = CharacterAnimationPresetStoreScript.ensure_clip(preset, clip_id, null)
	var block := {
		"clip_id": String(clip_id),
		"duration_sec": snappedf(clip.duration_sec, 0.001),
		"saved": clip.saved,
		"pose_b_saved": clip.pose_b_saved,
		"weapon_overlay": _build_weapon_overlay_block(preset, mode, rig),
		"pose_a": _build_pose_block(clip.pose_at_index(0), "Pose 1", clip_id, false),
		"pose_b": _build_pose_block(clip.pose_at_index(1), "Pose 2", clip_id, true),
	}
	if _clip_has_motion(clip_id):
		block["motion"] = _build_clip_motion(clip)
	_apply_club_walk_pose_notes(preset, clip_id, block)
	return block


static func _clip_has_motion(clip_id: StringName) -> bool:
	return (
		clip_id == CharacterAnimationPresetStoreScript.CLIP_WALK
		or clip_id == CharacterAnimationPresetStoreScript.CLIP_GATHER
	)


static func _build_pose_block(
	pose,
	label: String,
	clip_id: StringName,
	pose_b: bool
) -> Dictionary:
	var suffix := "B" if pose_b else "A"
	var row := {
		"label": label,
		"hand_1": _vec2_array(pose.hand_weapon_px),
		"hand_2": _vec2_array(pose.hand_support_px),
		"overlay": _vec2_array(pose.overlay_offset_px),
		"elbow_1_bend": WeaponLimbPreset.bend_sign_chat_label(pose.elbow_weapon_bend_sign),
		"elbow_2_bend": WeaponLimbPreset.bend_sign_chat_label(pose.elbow_support_bend_sign),
		"rotation_deg": _rotation_for_export(pose.weapon_rotation_deg),
	}
	if pose.grip_on_art_px.length_squared() > 0.0001:
		row["grip_on_art_px"] = _vec2_array(pose.grip_on_art_px)
	if pose.head_offset_px.length_squared() > 0.0001:
		row["head"] = _vec2_array(pose.head_offset_px)
	var clip_key := String(clip_id).to_upper()
	row["lock_in_constants"] = {
		"%s_%s_HAND_WEAPON" % [clip_key, suffix]: row["hand_1"],
		"%s_%s_HAND_SUPPORT" % [clip_key, suffix]: row["hand_2"],
		"%s_%s_OVERLAY" % [clip_key, suffix]: row["overlay"],
	}
	return row


static func _apply_club_walk_pose_notes(
	preset: WeaponLimbPreset,
	clip_id: StringName,
	block: Dictionary
) -> void:
	if clip_id != CharacterAnimationPresetStoreScript.CLIP_WALK:
		return
	if preset.weapon_type != ResourceData.ResourceType.WOOD:
		return
	if not preset.uses_club_walk_off_arm_travel_swing():
		return
	var pose_a: Dictionary = block["pose_a"]
	pose_a["hand_1_role"] = "body_carry"
	pose_a["hand_1"] = _vec2_array(preset.resolve_club_carry_body_hand_px())
	if preset.uses_saved_club_grip_on_art():
		pose_a["grip_on_art_px"] = _vec2_array(preset.idle_club1_hand_grip_offset_px)
	pose_a["note"] = (
		"Club walk: hand_1 is body-card carry; off-arm uses empty-hands walk keyframe on hand_2"
	)
	var constants: Dictionary = pose_a.get("lock_in_constants", {})
	constants["WALK_A_HAND_WEAPON"] = pose_a["hand_1"]
	pose_a["lock_in_constants"] = constants


static func _build_clip_motion(clip) -> Dictionary:
	var pose_a = clip.pose_at_index(0)
	var pose_b = clip.pose_at_index(1)
	var samples: Array = []
	for phase in [0.0, 0.25, 0.5, 0.75, 1.0]:
		var sampled = CharacterAnimationSamplerScript.sample_between(pose_a, pose_b, phase)
		samples.append({
			"phase": phase,
			"hand_1": _vec2_array(sampled.hand_weapon_px),
			"hand_2": _vec2_array(sampled.hand_support_px),
		})
	return {
		"driver": "CharacterAnimationSampler.sample_between (Pose 1 ↔ Pose 2, pendulum ease)",
		"duration_sec": snappedf(clip.duration_sec, 0.001),
		"samples": samples,
	}


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
