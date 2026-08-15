extends SceneTree

## Lock-in: club / clansmen_1 — windup loop baseline (placeholder until visual re-tune).

const WeaponLimbPresetScript = preload("res://scripts/config/weapon_limb_preset.gd")
const LimbPresetRegistryScript = preload("res://scripts/systems/limb_preset_registry.gd")
const ClubWindupMotion = preload("res://scripts/systems/club_windup_motion.gd")

const TOLERANCE_PX := 0.05

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	var registry := LimbPresetRegistryScript.new()
	var preset: WeaponLimbPreset = registry.reload_preset(ResourceData.ResourceType.WOOD, "clansmen_1")
	if preset == null:
		_fail("club_clansmen_1.tres missing")
		_report()
		quit(1)
		return

	print("=== club_clansmen_1 lock-in (windup baseline) ===")
	if not preset.has_club_windup_idle_loop():
		_fail("windup keyframes missing — run seed_baseline_weapon_presets first")

	_validate_windup_motion(preset)

	var err := registry.save_preset(preset)
	if err != OK:
		_fail("save failed: %s" % error_string(err))

	_report()
	quit(0 if _failures.is_empty() else 1)


func _validate_windup_motion(preset: WeaponLimbPreset) -> void:
	print("\n-- Windup loop motion --")
	var prev: Vector2 = preset.sample_club_windup_idle_loop(0.0).get("ready_offset_px", Vector2.ZERO) as Vector2
	for i in range(1, 9):
		var phase := float(i) / 8.0
		var sample: Dictionary = preset.sample_club_windup_idle_loop(phase)
		var ready: Vector2 = sample.get("ready_offset_px", Vector2.ZERO) as Vector2
		if ready.distance_to(prev) > 120.0:
			_fail("club windup teleport at phase %.2f" % phase)
		prev = ready
	var weights := ClubWindupMotion.segment_weights(0.125)
	if weights.get("rest", 0.0) <= 0.0 and weights.get("a", 0.0) <= 0.0:
		_fail("club windup segment weights invalid")
	if _failures.is_empty():
		print("  club windup loop: OK (9 samples)")


func _fail(msg: String) -> void:
	_failures.append(msg)
	print("FAIL: ", msg)


func _report() -> void:
	print("\n=== Lock-in summary ===")
	if _failures.is_empty():
		print("lockin_club_clansmen_1: PASS")
	else:
		print("lockin_club_clansmen_1: FAIL (%d)" % _failures.size())
		for f in _failures:
			print("  - ", f)
