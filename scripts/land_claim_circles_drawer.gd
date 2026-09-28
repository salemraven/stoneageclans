extends Node2D
# Draws all land claim radius circles in world space.
# Redraws when a claim is added/removed, not every frame.

const CIRCLE_POINTS := 64

func _ready() -> void:
	var main := get_node_or_null("/root/Main")
	if main and main.has_signal("land_claims_changed"):
		main.land_claims_changed.connect(_on_claims_changed)
	queue_redraw()


func _on_claims_changed() -> void:
	queue_redraw()


func _draw() -> void:
	if LagProfiler and LagProfiler.is_enabled():
		LagProfiler.record_claim_circle_redraw()
	var claims: Array = []
	var main := get_node_or_null("/root/Main")
	if main and main.has_method("get_cached_land_claims"):
		claims = main.get_cached_land_claims()
	else:
		claims = get_tree().get_nodes_in_group("land_claims")
	for claim in claims:
		if not is_instance_valid(claim):
			continue
		if claim.get_meta("circle_hidden", false):
			continue
		var radius: float = claim.get("radius") if claim.get("radius") != null else 400.0
		var pos: Vector2 = claim.global_position - global_position
		_draw_circle_outline(pos, radius)


func _draw_circle_outline(center: Vector2, radius: float) -> void:
	var points := PackedVector2Array()
	for i in CIRCLE_POINTS:
		var angle := (TAU * i) / CIRCLE_POINTS
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
	if points.size() > 0:
		points.append(points[0])
	draw_polyline(points, YSortUtils.WORLD_OVERLAY_LINE_HERD_COLOR, YSortUtils.WORLD_OVERLAY_LINE_WIDTH_PX, true)
