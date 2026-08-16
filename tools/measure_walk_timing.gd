extends SceneTree

## Headless: measure body bounce vs arm keyframe cycle periods in walk preview.

const WalkArmMotionScript = preload("res://scripts/systems/walk_arm_motion.gd")
const Registry = preload("res://scripts/config/placeholder_card_registry.gd")

const DT := 1.0 / 60.0
const STEPS := 600


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	var speed := Registry.effective_walk_bounce_speed()
	var bounce_time := 0.0
	var last_body := 0.0
	var last_blend := 0.0
	var body_crossings := 0
	var blend_crossings := 0
	var body_peaks := 0
	var blend_peaks := 0
	for i in STEPS:
		bounce_time += DT * speed
		var body := sin(bounce_time)
		var phase := WalkArmMotionScript.cycle_phase_from_bounce(bounce_time)
		var blend := WalkArmMotionScript.body_snapshot_blend(phase)
		if i > 0:
			if last_body < 0.0 and body >= 0.0:
				body_crossings += 1
			if last_blend < 0.5 and blend >= 0.5:
				blend_crossings += 1
			if last_body < body and body > sin(bounce_time - DT * speed):
				pass
		if i > 1:
			var prev_body := sin(bounce_time - DT * speed)
			if prev_body < body and body > sin(bounce_time + DT * speed):
				body_peaks += 1
			var prev_blend := WalkArmMotionScript.body_snapshot_blend(
				WalkArmMotionScript.cycle_phase_from_bounce(bounce_time - DT * speed)
			)
			if prev_blend < blend and blend > WalkArmMotionScript.body_snapshot_blend(
				WalkArmMotionScript.cycle_phase_from_bounce(bounce_time + DT * speed)
			):
				blend_peaks += 1
		last_body = body
		last_blend = blend
	var theory_period := TAU / speed
	print("=== Walk timing measurement ===")
	print("effective_walk_bounce_speed: %.4f rad/s" % speed)
	print("theoretical period (2pi/speed): %.4f s" % theory_period)
	print("sim time: %.2f s" % (STEPS * DT))
	print("body zero-up crossings: %d" % body_crossings)
	print("blend mid-up crossings (0.5): %d" % blend_crossings)
	print("body local peaks (approx): %d" % body_peaks)
	print("blend local peaks (approx): %d" % blend_peaks)
	var phase_direct := WalkArmMotionScript.cycle_phase_from_bounce(bounce_time)
	var phase_wrong := fposmod(bounce_time, 1.0)
	print("phase at end (correct /TAU): %.4f" % phase_direct)
	print("phase at end (wrong fmod 1): %.4f" % phase_wrong)
	quit(0)
