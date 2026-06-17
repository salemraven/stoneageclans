extends SceneTree

## Headless smoke: procedural arm config, IK, and Player scene wiring.

const ProceduralArmScript = preload("res://scripts/systems/procedural_arm.gd")
const ProceduralArmConfigScript = preload("res://scripts/systems/procedural_arm_config.gd")

var _failures: Array[String] = []


func _initialize() -> void:
	_test_ik_solver()
	_test_player_scene()
	_test_grip_directions()
	_report()
	quit()


func _test_ik_solver() -> void:
	var cfg: Resource = ProceduralArmConfigScript.new()
	var arm: RefCounted = ProceduralArmScript.new()
	var parent := Node2D.new()
	root.add_child(parent)
	arm.call("setup", parent, "T", cfg)

	var shoulder := Vector2(0.0, 0.0)
	var hand := Vector2(20.0, 4.0)
	var scale := Vector2(0.5, 0.5)
	arm.call("update_arm", shoulder, hand, cfg, 1.0, scale)
	var joints: Dictionary = arm.call("get_last_joint_positions")
	var elbow: Vector2 = joints.get("elbow", Vector2.ZERO)
	var upper_len: float = cfg.upper_arm_length * scale.x
	var lower_len: float = cfg.lower_arm_length * scale.x
	var upper_seg: float = shoulder.distance_to(elbow)
	var lower_seg: float = elbow.distance_to(hand)
	if absf(upper_seg - upper_len) > 0.5:
		_fail("IK upper segment length out of range got %.2f expected ~%.2f" % [upper_seg, upper_len])
	if absf(lower_seg - lower_len) > 0.5:
		_fail("IK lower segment length out of range got %.2f expected ~%.2f" % [lower_seg, lower_len])

	parent.queue_free()


func _test_grip_directions() -> void:
	var cfg: Resource = ProceduralArmConfigScript.new()
	var dirs: Array[Vector2] = [
		Vector2(1.0, 0.0),
		Vector2(0.0, 1.0),
		Vector2(-1.0, 0.0),
		Vector2(0.0, -1.0),
	]
	for dir in dirs:
		var shoulder := Vector2(0.0, 0.0)
		var hand := shoulder + dir * 30.0
		var arm: RefCounted = ProceduralArmScript.new()
		var parent := Node2D.new()
		root.add_child(parent)
		arm.call("setup", parent, "D", cfg)
		arm.call("update_arm", shoulder, hand, cfg, 1.0, Vector2(0.5, 0.5))
		var joints: Dictionary = arm.call("get_last_joint_positions")
		if not joints.has("elbow"):
			_fail("IK missing elbow for dir %s" % str(dir))
		parent.queue_free()


func _test_player_scene() -> void:
	var packed := load("res://scenes/Player.tscn") as PackedScene
	if packed == null:
		_fail("Player.tscn failed to load")
		return
	var player: Node = packed.instantiate()
	root.add_child(player)
	var ctrl: Node = player.get_node_or_null("ProceduralArmController")
	if ctrl == null:
		_fail("ProceduralArmController missing on Player")
	elif not ctrl.has_method("toggle_debug_draw"):
		_fail("ProceduralArmController missing toggle_debug_draw")
	player.queue_free()


func _fail(msg: String) -> void:
	push_error(msg)
	_failures.append(msg)


func _report() -> void:
	if _failures.is_empty():
		print("test_procedural_arms: PASS")
	else:
		for f in _failures:
			print("test_procedural_arms: FAIL — ", f)
		quit(1)
