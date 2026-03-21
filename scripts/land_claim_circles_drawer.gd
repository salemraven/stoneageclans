extends Node2D
# Draws all land claim radius circles in world space.
# This node lives under WorldLayer so circles render over ground but behind WorldObjects (sprites).

const CIRCLE_POINTS := 64
const LINE_WIDTH := 4.0
const LINE_COLOR := Color(1.0, 1.0, 1.0, 0.5)

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	var claims := get_tree().get_nodes_in_group("land_claims")
	for claim in claims:
		if not is_instance_valid(claim):
			continue
		if claim.get_meta("circle_hidden", false):
			continue
		var radius: float = claim.get("radius") if claim.get("radius") != null else 400.0
		var pos: Vector2 = claim.global_position - global_position
		_draw_circle_outline(pos, radius)

func _draw_circle_outline(center: Vector2, radius: float) -> void:
	# Draw several circles at offset radii so the line looks thicker
	var half := int(LINE_WIDTH) / 2
	for o in range(-half, half + 1):
		var r := radius + float(o)
		var points := PackedVector2Array()
		for i in CIRCLE_POINTS:
			var angle := (TAU * i) / CIRCLE_POINTS
			points.append(center + Vector2(cos(angle), sin(angle)) * r)
		points.append(points[0])
		draw_polyline(points, LINE_COLOR)
