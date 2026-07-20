extends RefCounted
class_name ProceduralArm

const ProceduralArmConfigScript = preload("res://scripts/systems/procedural_arm_config.gd")

var _line: Line2D
var _endpoint_root: Node2D
var _shoulder_marker: Node2D
var _hand_marker: Node2D
var _debug_root: Node2D
var _debug_elbow: Node2D

var _points: PackedVector2Array = PackedVector2Array([Vector2.ZERO, Vector2.ZERO, Vector2.ZERO])
var _last_shoulder := Vector2.ZERO
var _last_elbow := Vector2.ZERO
var _last_hand := Vector2.ZERO
var _endpoint_markers_visible := true


func setup(parent: Node2D, side_label: String, config: Resource) -> void:
	var cfg := _as_config(config)
	if cfg == null:
		return
	_line = Line2D.new()
	_line.name = "ArmLine_%s" % side_label
	_line.z_as_relative = false
	_line.z_index = cfg.arm_z_index
	_line.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_line.joint_mode = Line2D.LINE_JOINT_ROUND
	_line.begin_cap_mode = Line2D.LINE_CAP_BOX
	_line.end_cap_mode = Line2D.LINE_CAP_BOX
	_line.antialiased = false
	_apply_line_style(cfg)
	parent.add_child(_line)

	_endpoint_root = Node2D.new()
	_endpoint_root.name = "ArmEndpoints_%s" % side_label
	_endpoint_root.z_as_relative = false
	_endpoint_root.z_index = cfg.arm_z_index
	parent.add_child(_endpoint_root)
	_shoulder_marker = _make_circle_marker(_endpoint_root, cfg.shoulder_marker_color)
	_hand_marker = _make_circle_marker(_endpoint_root, cfg.hand_marker_color)

	_debug_root = Node2D.new()
	_debug_root.name = "ArmDebug_%s" % side_label
	_debug_root.z_as_relative = false
	_debug_root.z_index = cfg.arm_z_index
	_debug_root.visible = false
	parent.add_child(_debug_root)
	_debug_elbow = _make_circle_marker(_debug_root, Color(0.9, 0.8, 0.1, 1.0))


func set_endpoint_markers_visible(visible_markers: bool) -> void:
	_endpoint_markers_visible = visible_markers
	if _endpoint_root:
		_endpoint_root.visible = visible_markers and (_line != null and _line.visible)


func set_visible_arm(visible_arm: bool) -> void:
	if _line:
		_line.visible = visible_arm
	if _endpoint_root:
		_endpoint_root.visible = visible_arm and _endpoint_markers_visible
	if _debug_root:
		_debug_root.visible = visible_arm and _debug_root.get_meta("debug_enabled", false)


func set_debug_enabled(enabled: bool) -> void:
	if _debug_root:
		_debug_root.set_meta("debug_enabled", enabled)
		_debug_root.visible = enabled and _line != null and _line.visible


func update_arm(
	local_shoulder: Vector2,
	local_hand: Vector2,
	config: Resource,
	bend_sign: float,
	sprite_scale: Vector2,
	pole_hint_override: Vector2 = Vector2.ZERO,
	use_pole_override: bool = false
) -> void:
	var cfg := _as_config(config)
	if _line == null or cfg == null:
		return
	var upper_len: float = cfg.upper_arm_length * absf(sprite_scale.x)
	var lower_len: float = cfg.lower_arm_length * absf(sprite_scale.x)
	var pole_hint := pole_hint_override if use_pole_override else _elbow_pole_hint(
		local_shoulder, local_hand, cfg, bend_sign, sprite_scale
	)
	var elbow := _solve_ik(local_shoulder, local_hand, upper_len, lower_len, pole_hint)

	_points[0] = local_shoulder
	_points[1] = elbow
	_points[2] = local_hand
	_trim_line_endpoints(cfg, sprite_scale)
	_line.points = _points

	_last_shoulder = local_shoulder
	_last_elbow = elbow
	_last_hand = local_hand
	_update_endpoint_markers(cfg)
	_update_debug_markers(cfg)


func get_last_joint_positions() -> Dictionary:
	return {
		"shoulder": _last_shoulder,
		"elbow": _last_elbow,
		"hand": _last_hand,
	}


func _as_config(config: Resource) -> ProceduralArmConfigScript:
	return config as ProceduralArmConfigScript


func _apply_line_style(cfg: ProceduralArmConfigScript) -> void:
	var width_mult: float = cfg.width_genetics_mult
	_line.width = cfg.arm_width * width_mult
	_line.default_color = cfg.arm_color
	var curve := Curve.new()
	curve.add_point(Vector2(0.0, cfg.arm_width * width_mult))
	curve.add_point(Vector2(1.0, cfg.hand_width * width_mult))
	_line.width_curve = curve
	var tex: Texture2D = cfg.arm_texture
	if tex == null:
		tex = _default_arm_texture()
	if tex:
		_line.texture = tex
		_line.texture_mode = Line2D.LINE_TEXTURE_TILE


func _elbow_pole_hint(
	shoulder: Vector2,
	hand: Vector2,
	cfg: ProceduralArmConfigScript,
	bend_sign: float,
	sprite_scale: Vector2
) -> Vector2:
	var to_hand := hand - shoulder
	if to_hand.length_squared() < 0.01:
		to_hand = Vector2(0.0, 1.0)
	var outward := Vector2(-to_hand.y, to_hand.x).normalized() * signf(bend_sign)
	var outward_dist: float = cfg.elbow_hint_outward * absf(sprite_scale.x)
	return shoulder + outward * outward_dist


func _solve_ik(shoulder: Vector2, hand: Vector2, upper_len: float, lower_len: float, pole_hint: Vector2) -> Vector2:
	var to_hand := hand - shoulder
	var dist := to_hand.length()
	if dist < 0.001:
		return shoulder + Vector2(upper_len, 0.0)
	var max_reach := upper_len + lower_len - 0.01
	var min_reach := absf(upper_len - lower_len) + 0.01
	dist = clampf(dist, min_reach, max_reach)
	var dir := to_hand / dist

	var cos_shoulder := (upper_len * upper_len + dist * dist - lower_len * lower_len) / (2.0 * upper_len * dist)
	cos_shoulder = clampf(cos_shoulder, -1.0, 1.0)
	var shoulder_angle := acos(cos_shoulder)

	var mid := shoulder + dir * (dist * 0.5)
	var pole_side := signf((pole_hint - mid).cross(dir))
	if pole_side == 0.0:
		pole_side = 1.0

	var elbow_dir := dir.rotated(shoulder_angle * pole_side)
	return shoulder + elbow_dir * upper_len


func _update_endpoint_markers(cfg: ProceduralArmConfigScript) -> void:
	var r: float = cfg.endpoint_marker_radius
	_shoulder_marker.position = _last_shoulder
	_hand_marker.position = _last_hand
	_resize_circle_marker(_shoulder_marker, r)
	_resize_circle_marker(_hand_marker, r)


func _update_debug_markers(cfg: ProceduralArmConfigScript) -> void:
	var r: float = cfg.debug_marker_radius
	_debug_elbow.position = _last_elbow
	_resize_circle_marker(_debug_elbow, r)


func _trim_line_endpoints(cfg: ProceduralArmConfigScript, sprite_scale: Vector2) -> void:
	if _points.size() < 3:
		return
	var width_mult: float = cfg.width_genetics_mult
	var inset: float = cfg.line_endpoint_inset_px * absf(sprite_scale.x)
	if inset <= 0.0:
		inset = cfg.hand_width * width_mult * 0.45
	var shoulder_to_elbow := _points[1] - _points[0]
	if shoulder_to_elbow.length_squared() > 0.01:
		_points[0] += shoulder_to_elbow.normalized() * minf(inset, shoulder_to_elbow.length() * 0.35)
	var elbow_to_hand := _points[2] - _points[1]
	if elbow_to_hand.length_squared() > 0.01:
		_points[2] -= elbow_to_hand.normalized() * minf(inset, elbow_to_hand.length() * 0.35)


func _make_circle_marker(parent: Node2D, color: Color) -> Node2D:
	var marker := Node2D.new()
	var poly := Polygon2D.new()
	poly.color = color
	poly.polygon = _circle_polygon(4.0, 10)
	marker.add_child(poly)
	parent.add_child(marker)
	return marker


func _resize_circle_marker(marker: Node2D, radius: float) -> void:
	if marker == null or marker.get_child_count() == 0:
		return
	var poly := marker.get_child(0) as Polygon2D
	if poly:
		poly.polygon = _circle_polygon(radius, 12)


func _circle_polygon(radius: float, segments: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in range(segments):
		var angle := TAU * float(i) / float(segments)
		pts.append(Vector2(cos(angle), sin(angle)) * radius)
	return pts


static var _cached_default_texture: Texture2D

static func _default_arm_texture() -> Texture2D:
	if _cached_default_texture != null:
		return _cached_default_texture
	var img := Image.create(8, 8, false, Image.FORMAT_RGBA8)
	for y in range(8):
		for x in range(8):
			var stripe: bool = int(x / 2) % 2 == 0
			img.set_pixel(x, y, Color(0.55, 0.42, 0.35) if stripe else Color(0.45, 0.32, 0.25))
	_cached_default_texture = ImageTexture.create_from_image(img)
	return _cached_default_texture
