extends SceneTree

func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	var packed := load("res://scenes/tools/LimbTuner.tscn") as PackedScene
	var app: Node = packed.instantiate()
	root.add_child(app)
	for _i in range(12):
		await process_frame
	var rig: Node2D = app.get_node_or_null("World/Stage/TunerRig") as Node2D
	if rig == null:
		push_error("no rig")
		quit(1)
		return
	print("=== TunerRig children (draw order) ===")
	for i in rig.get_child_count():
		var c := rig.get_child(i)
		var zi := 0
		var zrel := true
		if c is CanvasItem:
			zi = (c as CanvasItem).z_index
			zrel = (c as CanvasItem).z_as_relative
		print("  [%d] %s z=%d rel=%s" % [i, c.name, zi, zrel])
	var arm1: Node = rig.get_node_or_null("Arm1Draw")
	var arm2: Node = rig.get_node_or_null("Arm2Draw")
	var body_sprite: Sprite2D = null
	var bv: Node = rig.get_node_or_null("Sprite/BodyVisual")
	if bv and bv.has_method("get_body_sprite"):
		body_sprite = bv.call("get_body_sprite") as Sprite2D
	var head_pivot: Node2D = rig.get_node_or_null("Sprite/HeadPivot") as Node2D
	print("=== z values ===")
	if arm1:
		print("Arm1Draw z=%d rel=%s" % [(arm1 as CanvasItem).z_index, (arm1 as CanvasItem).z_as_relative])
	if body_sprite:
		print("BodySprite z=%d rel=%s visible=%s" % [body_sprite.z_index, body_sprite.z_as_relative, body_sprite.visible])
	if head_pivot:
		print("HeadPivot z=%d rel=%s scale=%s" % [head_pivot.z_index, head_pivot.z_as_relative, str(head_pivot.scale)])
	if arm2:
		print("Arm2Draw z=%d rel=%s" % [(arm2 as CanvasItem).z_index, (arm2 as CanvasItem).z_as_relative])
	print("=== handles ===")
	var handle_names := [
		"ShoulderHandle", "HandHandle", "SupportShoulderHandle", "SupportHandHandle",
		"HeadNeckHandle", "WeaponElbowHandle", "SupportElbowHandle", "SpearHandle",
	]
	for hn in handle_names:
		var h: Node = _find_handle(rig, app, hn)
		if h == null:
			print("  %s MISSING" % hn)
			continue
		var ci := h as CanvasItem
		var poly: Polygon2D = h.get_child(0) as Polygon2D if h.get_child_count() > 0 else null
		print(
			"  %s parent=%s global=%s z=%d rel=%s vis=%s poly=%s radius=%s"
			% [
				hn,
				h.get_parent().name if h.get_parent() else "?",
				str(h.global_position),
				ci.z_index if ci else -1,
				ci.z_as_relative if ci else "?",
				ci.visible if ci else "?",
				poly.polygon.size() if poly else 0,
				h.get("handle_radius") if h.has_method("get") else "?",
			]
		)
	var arm_ctrl: ProceduralArmController = rig.get_node_or_null("ProceduralArmController") as ProceduralArmController
	if arm_ctrl:
		print("=== arm controller ===")
		print("  use_tuner_arm_layers=%s z=%d" % [arm_ctrl.use_tuner_arm_layers, arm_ctrl.z_index])
		for c in arm_ctrl.get_children():
			print("  ctrl child: %s" % c.name)
	if arm1:
		for c in arm1.get_children():
			print("  arm1 child: %s" % c.name)
			for cc in c.get_children():
				if cc is Line2D:
					var ln := cc as Line2D
					print("    line %s z=%d rel=%s vis=%s pts=%d" % [cc.name, ln.z_index, ln.z_as_relative, ln.visible, ln.points.size()])
	if arm2:
		for c in arm2.get_children():
			print("  arm2 child: %s" % c.name)
			for cc in c.get_children():
				if cc is Line2D:
					var ln := cc as Line2D
					print("    line %s z=%d rel=%s vis=%s pts=%d" % [cc.name, ln.z_index, ln.z_as_relative, ln.visible, ln.points.size()])
	quit()


func _find_handle(rig: Node, app: Node, name: String) -> Node:
	var n := rig.find_child(name, true, false)
	if n:
		return n
	var stage: Node = app.get_node_or_null("World/HandleLayer/HandleStage")
	if stage:
		return stage.get_node_or_null(name)
	return null
