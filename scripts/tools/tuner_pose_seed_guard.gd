extends RefCounted
class_name TunerPoseSeedGuard

## Startup seed contract for LimbTuner — see guides/animation_tuner.md § Startup seed guard.
##
## Rule: relaunching the tuner (any --*-edit / --*-preview flag) must NOT overwrite pose rows
## the user already saved to disk. Seeds may only fill blank fields on first-time setup, or
## repair drift between rows on the *same* preset (e.g. club walk dominant ← idle carry).

const DRIFT_EPS := 0.01

const FINGERPRINT_KEYS: Array[String] = [
	"hand_grip_offset_px",
	"walk_hand_grip_offset_px",
	"walk1_hand_grip_offset_px",
	"walk1_support_hand_offset_px",
	"walk1_pull_hand_grip_offset_px",
	"walk1_pull_support_hand_offset_px",
	"gather1_hand_grip_offset_px",
	"gather1_pull_hand_grip_offset_px",
	"idle_club1_hand_grip_offset_px",
	"ready_offset_px",
	"hand_grip_ready_offset_px",
]


static func vec_unset(v: Vector2) -> bool:
	return v.length_squared() < 0.0001


static func may_seed_into_row(row_saved: bool, field: Vector2) -> bool:
	return not row_saved and vec_unset(field)


static func may_copy_from_foreign_preset(local_row_saved: bool) -> bool:
	return not local_row_saved


static func vectors_differ(a: Vector2, b: Vector2, eps: float = DRIFT_EPS) -> bool:
	return a.distance_to(b) > eps


static func fingerprint(preset: WeaponLimbPreset) -> Dictionary:
	if preset == null:
		return {}
	var full: Dictionary = preset.to_export_dict()
	var out: Dictionary = {}
	for key in FINGERPRINT_KEYS:
		if full.has(key):
			out[key] = full[key]
	out["walk1_pose_a_saved"] = preset.walk1_pose_a_saved
	out["walk1_pose_b_saved"] = preset.walk1_pose_b_saved
	out["gather1_reach_saved"] = preset.gather1_reach_saved
	out["gather1_pull_saved"] = preset.gather1_pull_saved
	out["idle_club1_grip_authoritative"] = preset.idle_club1_grip_authoritative
	return out


static func fingerprint_diff(before: Dictionary, after: Dictionary) -> Array[String]:
	var changes: Array[String] = []
	for key in before.keys():
		if after.get(key) != before.get(key):
			changes.append("%s: %s -> %s" % [key, str(before[key]), str(after[key])])
	for key in after.keys():
		if not before.has(key) and after.get(key) != null:
			changes.append("%s: (missing) -> %s" % [key, str(after[key])])
	return changes
