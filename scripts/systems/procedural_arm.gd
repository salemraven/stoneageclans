extends RefCounted
class_name ProceduralArm

const ProceduralArmConfigScript = preload("res://scripts/systems/procedural_arm_config.gd")

var _draw_root: Node2D
var _line: Line2D
var _line_outline: Line2D
var _line_upper: Line2D
var _line_upper_outline: Line2D
var _line_lower: Line2D
var _line_lower_outline: Line2D
var _endpoint_root: Node2D
var _endpoint_root_upper: Node2D
var _endpoint_root_lower: Node2D
var _shoulder_marker: Node2D
var _hand_marker: Node2D
var _debug_root: Node2D
var _debug_elbow: Node2D

var _points: PackedVector2Array = PackedVector2Array([Vector2.ZERO, Vector2.ZERO, Vector2.ZERO])
var _last_shoulder := Vector2.ZERO
var _last_elbow := Vector2.ZERO
var _last_hand := Vector2.ZERO
var _elbow_solution_sign: float = 0.0
var _pole_pick_locked := false
var _pole_pick_a := true
var _endpoint_markers_visible := true

const ELBOW_POLE_HYSTERESIS_PX := 10.0
const ELBOW_SMOOTH_RATE := 22.0
const ELBOW_SMOOTH_RATE_WALK := 14.0


func setup(parent: Node2D, side_label: String, config: Resource) -> void:
	var cfg := _as_config(config)
	if cfg == null:
		return
	_draw_root = Node2D.new()
	_draw_root.name = "ArmDraw_%s" % side_label
	parent.add_child(_draw_root)
	var under_tuner := parent.name in ["Arm1Draw", "Arm2Draw"]
	var line_z := 0 if under_tuner else cfg.arm_z_index
	var line_relative := under_tuner
	var line_parent := _draw_root
	if cfg.split_depth_at_elbow:
		_line_upper = _create_arm_line(line_parent, "ArmUpper_%s" % side_label, line_z, line_relative, cfg)
		_line_upper_outline = _line_upper.get_meta("outline_line") as Line2D
		_line_lower = _create_arm_line(line_parent, "ArmLower_%s" % side_label, line_z, line_relative, cfg)
		_line_lower_outline = _line_lower.get_meta("outline_line") as Line2D
		_endpoint_root_upper = _create_endpoint_root(line_parent, "ArmEndpointsUpper_%s" % side_label, line_z, line_relative)
		_endpoint_root_lower = _create_endpoint_root(line_parent, "ArmEndpointsLower_%s" % side_label, line_z, line_relative)
		_shoulder_marker = _make_circle_marker(_endpoint_root_upper, cfg.shoulder_marker_color)
		_hand_marker = _make_circle_marker(_endpoint_root_lower, cfg.hand_marker_color)
	else:
		_line = _create_arm_line(line_parent, "ArmLine_%s" % side_label, line_z, line_relative, cfg)
		_line_outline = _line.get_meta("outline_line") as Line2D
		_endpoint_root = _create_endpoint_root(line_parent, "ArmEndpoints_%s" % side_label, line_z, line_relative)
		_shoulder_marker = _make_circle_marker(_endpoint_root, cfg.shoulder_marker_color)
		_hand_marker = _make_circle_marker(_endpoint_root, cfg.hand_marker_color)

	_debug_root = Node2D.new()
	_debug_root.name = "ArmDebug_%s" % side_label
	_debug_root.z_as_relative = line_relative
	_debug_root.z_index = line_z
	_debug_root.visible = false
	line_parent.add_child(_debug_root)
	_debug_elbow = _make_circle_marker(_debug_root, _elbow_joint_color(side_label))


func reparent_draw_to(new_parent: Node2D) -> void:
	if _draw_root == null or new_parent == null:
		return
	if _draw_root.get_parent() == new_parent:
		return
	_draw_root.reparent(new_parent)
	_apply_draw_band_for_parent(new_parent)


func get_draw_root() -> Node2D:
	return _draw_root


func _apply_draw_band_for_parent(parent: Node2D) -> void:
	var under_tuner := parent != null and parent.name in ["Arm1Draw", "Arm2Draw"]
	var line_z := 0 if under_tuner else (_line.z_index if _line != null else 4095)
	var relative := under_tuner
	if _draw_root:
		_draw_root.z_as_relative = relative
		_draw_root.z_index = line_z
	for line in [_line, _line_upper, _line_lower, _line_outline, _line_upper_outline, _line_lower_outline]:
		if line:
			line.z_as_relative = relative
			line.z_index = line_z
	for root in [_endpoint_root, _endpoint_root_upper, _endpoint_root_lower, _debug_root]:
		if root:
			root.z_as_relative = relative
			root.z_index = line_z


func _create_arm_line(parent: Node2D, line_name: String, z: int, relative: bool, cfg: ProceduralArmConfigScript) -> Line2D:
	var outline := Line2D.new()
	outline.name = "%sOutline" % line_name
	outline.z_as_relative = relative
	outline.z_index = z
	outline.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_apply_line_geometry(outline)
	outline.antialiased = false
	_apply_line_style(outline, cfg, true)
	parent.add_child(outline)
	var line := Line2D.new()
	line.name = line_name
	line.z_as_relative = relative
	line.z_index = z
	line.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_apply_line_geometry(line)
	line.antialiased = false
	_apply_line_style(line, cfg, false)
	line.set_meta("outline_line", outline)
	parent.add_child(line)
	return line


func _create_endpoint_root(parent: Node2D, root_name: String, z: int, relative: bool) -> Node2D:
	var root := Node2D.new()
	root.name = root_name
	root.z_as_relative = relative
	root.z_index = z
	parent.add_child(root)
	return root


func set_endpoint_markers_visible(visible_markers: bool) -> void:
	_endpoint_markers_visible = visible_markers
	var arm_visible := _arm_lines_visible()
	if _endpoint_root:
		_endpoint_root.visible = visible_markers and arm_visible
	if _endpoint_root_upper:
		_endpoint_root_upper.visible = visible_markers and arm_visible
	if _endpoint_root_lower:
		_endpoint_root_lower.visible = visible_markers and arm_visible


func set_visible_arm(visible_arm: bool) -> void:
	for line in [_line, _line_upper, _line_lower, _line_outline, _line_upper_outline, _line_lower_outline]:
		if line:
			line.visible = visible_arm
	if _endpoint_root:
		_endpoint_root.visible = visible_arm and _endpoint_markers_visible
	if _endpoint_root_upper:
		_endpoint_root_upper.visible = visible_arm and _endpoint_markers_visible
	if _endpoint_root_lower:
		_endpoint_root_lower.visible = visible_arm and _endpoint_markers_visible
	if _debug_root:
		_debug_root.visible = visible_arm and _debug_root.get_meta("debug_enabled", false)


func set_draw_z_index(z: int) -> void:
	if _draw_root:
		_draw_root.z_as_relative = false
		_draw_root.z_index = z
	if _line:
		_line.z_index = z
	if _line_outline:
		_line_outline.z_index = z
	if _line_upper:
		_line_upper.z_index = z
	if _line_upper_outline:
		_line_upper_outline.z_index = z
	if _line_lower:
		_line_lower.z_index = z
	if _line_lower_outline:
		_line_lower_outline.z_index = z
	if _endpoint_root:
		_endpoint_root.z_index = z
	if _endpoint_root_upper:
		_endpoint_root_upper.z_index = z
	if _endpoint_root_lower:
		_endpoint_root_lower.z_index = z
	if _debug_root:
		_debug_root.z_index = z


func _arm_lines_visible() -> bool:
	if _line:
		return _line.visible
	if _line_upper:
		return _line_upper.visible
	return false


func set_debug_enabled(enabled: bool) -> void:
	if _debug_root:
		_debug_root.set_meta("debug_enabled", enabled)
		_update_debug_visibility()


func set_show_elbow_joints(show_joints: bool) -> void:
	if _debug_root:
		_debug_root.set_meta("show_elbow_joints", show_joints)
		_update_debug_visibility()


func refresh_line_style(config: Resource) -> void:
	var cfg := _as_config(config)
	if cfg == null:
		return
	for line in [_line, _line_upper, _line_lower]:
		if line:
			_apply_line_style(line, cfg, false)
			var outline: Line2D = line.get_meta("outline_line") as Line2D
			if outline:
				_apply_line_style(outline, cfg, true)


func _update_debug_visibility() -> void:
	if _debug_root == null:
		return
	var show := bool(_debug_root.get_meta("debug_enabled", false)) or bool(_debug_root.get_meta("show_elbow_joints", false))
	_debug_root.visible = show and _arm_lines_visible()


func set_pole_pick_lock(locked: bool, prefer_a: bool = true) -> void:
	_pole_pick_locked = locked
	if locked:
		_pole_pick_a = prefer_a
		_elbow_solution_sign = 1.0 if prefer_a else -1.0


func clear_pole_pick_lock() -> void:
	_pole_pick_locked = false


func update_arm(
	local_shoulder: Vector2,
	local_hand: Vector2,
	config: Resource,
	bend_sign: float,
	sprite_scale: Vector2,
	pole_hint_override: Vector2 = Vector2.ZERO,
	use_pole_override: bool = false,
	segment_upper_px: float = -1.0,
	segment_lower_px: float = -1.0,
	forced_elbow: Vector2 = Vector2.ZERO,
	use_forced_elbow: bool = false,
	relax_min_reach: bool = false,
	use_walk_elbow_limits: bool = false,
	motion_delta: float = 1.0 / 60.0
) -> void:
	var cfg := _as_config(config)
	if _line == null or cfg == null:
		return
	var upper_len: float = (
		segment_upper_px if segment_upper_px > 0.0 else cfg.upper_arm_length
	) * absf(sprite_scale.x)
	var lower_len: float = (
		segment_lower_px if segment_lower_px > 0.0 else cfg.lower_arm_length
	) * absf(sprite_scale.x)
	var solved_hand := local_hand
	var to_hand := local_hand - local_shoulder
	var max_chain := upper_len + lower_len
	if to_hand.length() > max_chain and to_hand.length_squared() > 0.0001:
		solved_hand = local_shoulder + to_hand.normalized() * max_chain
	var pole_hint := pole_hint_override if use_pole_override else _elbow_pole_hint(
		local_shoulder, solved_hand, cfg, bend_sign, sprite_scale
	)
	var target_elbow := forced_elbow if use_forced_elbow else _solve_ik(
		local_shoulder,
		solved_hand,
		upper_len,
		lower_len,
		pole_hint,
		cfg,
		bend_sign,
		relax_min_reach,
		use_walk_elbow_limits,
		use_pole_override or pole_hint.length_squared() > 0.0001
	)
	if use_forced_elbow:
		var forearm := solved_hand - target_elbow
		if forearm.length_squared() > 0.0001 and forearm.length() > lower_len:
			solved_hand = target_elbow + forearm.normalized() * lower_len
	var elbow := target_elbow
	if not use_forced_elbow and _last_elbow.length_squared() > 0.0001:
		var smooth_rate := ELBOW_SMOOTH_RATE_WALK if use_walk_elbow_limits else ELBOW_SMOOTH_RATE
		var smooth := 1.0 - exp(-motion_delta * smooth_rate)
		elbow = _last_elbow.lerp(target_elbow, smooth)

	_points[0] = local_shoulder
	_points[1] = elbow
	_points[2] = solved_hand
	_trim_line_endpoints(cfg, sprite_scale)
	if _line_upper and _line_lower:
		var upper_pts := PackedVector2Array([_points[0], _points[1]])
		var lower_pts := PackedVector2Array([_points[1], _points[2]])
		_line_upper.points = upper_pts
		_line_lower.points = lower_pts
		if _line_upper_outline:
			_line_upper_outline.points = upper_pts
		if _line_lower_outline:
			_line_lower_outline.points = lower_pts
	elif _line:
		_line.points = _points
		if _line_outline:
			_line_outline.points = _points

	_last_shoulder = local_shoulder
	_last_elbow = elbow
	_last_hand = solved_hand
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


func _apply_line_geometry(line: Line2D) -> void:
	line.joint_mode = Line2D.LINE_JOINT_ROUND
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND


func _apply_line_style(line: Line2D, cfg: ProceduralArmConfigScript, is_outline: bool) -> void:
	_apply_line_geometry(line)
	var width_mult: float = cfg.width_genetics_mult
	var outline_pad: float = cfg.arm_outline_width_px * 2.0 if is_outline else 0.0
	var arm_w: float = cfg.arm_width * width_mult + outline_pad
	var hand_w: float = cfg.hand_width * width_mult + outline_pad
	line.width = arm_w
	line.default_color = cfg.arm_outline_color if is_outline else cfg.arm_color
	var curve := Curve.new()
	curve.add_point(Vector2(0.0, arm_w))
	curve.add_point(Vector2(1.0, hand_w))
	line.width_curve = curve
	if is_outline:
		line.texture = null
		line.texture_mode = Line2D.LINE_TEXTURE_NONE
		return
	# Solid fill — texture × tint was darkening arms (e.g. #ecb58e × stripe → #c47243).
	line.texture = null
	line.texture_mode = Line2D.LINE_TEXTURE_NONE


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


func _solve_ik(
	shoulder: Vector2,
	hand: Vector2,
	upper_len: float,
	lower_len: float,
	pole_hint: Vector2,
	cfg: ProceduralArmConfigScript,
	bend_sign: float,
	relax_min_reach: bool = false,
	use_walk_elbow_limits: bool = false,
	use_pole_hint: bool = false
) -> Vector2:
	var to_hand := hand - shoulder
	var dist := to_hand.length()
	if dist < 0.001:
		return shoulder + Vector2(upper_len, 0.0)
	var min_fold := deg_to_rad(cfg.elbow_fold_min_deg)
	var max_fold := deg_to_rad(cfg.elbow_fold_max_deg)
	if use_walk_elbow_limits:
		min_fold = deg_to_rad(cfg.elbow_fold_min_walk_deg)
		max_fold = deg_to_rad(cfg.elbow_fold_max_walk_deg)
	var max_reach := sqrt(
		upper_len * upper_len + lower_len * lower_len - 2.0 * upper_len * lower_len * cos(PI - min_fold)
	) - 0.01
	var min_reach := sqrt(
		upper_len * upper_len + lower_len * lower_len - 2.0 * upper_len * lower_len * cos(PI - max_fold)
	) + 0.01
	if dist > max_reach:
		dist = max_reach
	elif not relax_min_reach and dist < min_reach:
		dist = min_reach
	var dir := to_hand / dist

	var cos_shoulder := (upper_len * upper_len + dist * dist - lower_len * lower_len) / (2.0 * upper_len * dist)
	cos_shoulder = clampf(cos_shoulder, -1.0, 1.0)
	var shoulder_angle := acos(cos_shoulder)

	var elbow_a := shoulder + dir.rotated(shoulder_angle) * upper_len
	var elbow_b := shoulder + dir.rotated(-shoulder_angle) * upper_len
	if use_pole_hint and pole_hint.length_squared() > 0.0001:
		return _pick_elbow_near_pole(elbow_a, elbow_b, pole_hint)

	var pole_side := signf(bend_sign)
	if pole_side == 0.0:
		pole_side = 1.0
	var elbow_dir := dir.rotated(shoulder_angle * pole_side)
	return shoulder + elbow_dir * upper_len


static func ik_elbow_candidates(
	shoulder: Vector2,
	hand: Vector2,
	upper_len: float,
	lower_len: float,
	relax_min_reach: bool = true
) -> Array:
	var to_hand := hand - shoulder
	var dist := to_hand.length()
	if dist < 0.001:
		var fallback := shoulder + Vector2(upper_len, 0.0)
		return [fallback, fallback]
	var min_fold := deg_to_rad(8.0)
	var max_fold := deg_to_rad(150.0)
	var max_reach := sqrt(
		upper_len * upper_len + lower_len * lower_len - 2.0 * upper_len * lower_len * cos(PI - min_fold)
	) - 0.01
	var min_reach := sqrt(
		upper_len * upper_len + lower_len * lower_len - 2.0 * upper_len * lower_len * cos(PI - max_fold)
	) + 0.01
	if dist > max_reach:
		dist = max_reach
	elif not relax_min_reach and dist < min_reach:
		dist = min_reach
	var dir := to_hand / dist
	var cos_shoulder := (upper_len * upper_len + dist * dist - lower_len * lower_len) / (2.0 * upper_len * dist)
	cos_shoulder = clampf(cos_shoulder, -1.0, 1.0)
	var shoulder_angle := acos(cos_shoulder)
	return [
		shoulder + dir.rotated(shoulder_angle) * upper_len,
		shoulder + dir.rotated(-shoulder_angle) * upper_len,
	]


static func prefers_elbow_a_near_pole(
	shoulder: Vector2,
	hand: Vector2,
	upper_len: float,
	lower_len: float,
	pole_hint: Vector2,
	relax_min_reach: bool = true
) -> bool:
	var candidates: Array = ik_elbow_candidates(shoulder, hand, upper_len, lower_len, relax_min_reach)
	var elbow_a: Vector2 = candidates[0]
	var elbow_b: Vector2 = candidates[1]
	if pole_hint.length_squared() <= 0.0001:
		return true
	return elbow_a.distance_squared_to(pole_hint) <= elbow_b.distance_squared_to(pole_hint)


static func estimate_elbow_position(
	shoulder: Vector2,
	hand: Vector2,
	upper_len: float,
	lower_len: float,
	pole_hint: Vector2,
	use_pole_hint: bool = true
) -> Vector2:
	var to_hand := hand - shoulder
	var dist := to_hand.length()
	if dist < 0.001:
		return shoulder + Vector2(upper_len, 0.0)
	var min_fold := deg_to_rad(8.0)
	var max_fold := deg_to_rad(150.0)
	var max_reach := sqrt(
		upper_len * upper_len + lower_len * lower_len - 2.0 * upper_len * lower_len * cos(PI - min_fold)
	) - 0.01
	var min_reach := sqrt(
		upper_len * upper_len + lower_len * lower_len - 2.0 * upper_len * lower_len * cos(PI - max_fold)
	) + 0.01
	if dist > max_reach:
		dist = max_reach
	elif dist < min_reach:
		dist = min_reach
	var dir := to_hand / dist
	var cos_shoulder := (upper_len * upper_len + dist * dist - lower_len * lower_len) / (2.0 * upper_len * dist)
	cos_shoulder = clampf(cos_shoulder, -1.0, 1.0)
	var shoulder_angle := acos(cos_shoulder)
	var elbow_a := shoulder + dir.rotated(shoulder_angle) * upper_len
	var elbow_b := shoulder + dir.rotated(-shoulder_angle) * upper_len
	if use_pole_hint and pole_hint.length_squared() > 0.0001:
		return elbow_a if elbow_a.distance_squared_to(pole_hint) <= elbow_b.distance_squared_to(pole_hint) else elbow_b
	return elbow_a


func _pick_elbow_near_pole(elbow_a: Vector2, elbow_b: Vector2, pole_hint: Vector2) -> Vector2:
	if _pole_pick_locked:
		return elbow_a if _pole_pick_a else elbow_b
	var dist_a := elbow_a.distance_squared_to(pole_hint)
	var dist_b := elbow_b.distance_squared_to(pole_hint)
	var hyst := ELBOW_POLE_HYSTERESIS_PX * ELBOW_POLE_HYSTERESIS_PX
	var pick_a := dist_a <= dist_b
	if _elbow_solution_sign > 0.0:
		pick_a = dist_a <= dist_b + hyst
	elif _elbow_solution_sign < 0.0:
		pick_a = dist_a + hyst < dist_b
	_elbow_solution_sign = 1.0 if pick_a else -1.0
	return elbow_a if pick_a else elbow_b


func _update_endpoint_markers(cfg: ProceduralArmConfigScript) -> void:
	var r: float = cfg.endpoint_marker_radius
	_shoulder_marker.position = _last_shoulder
	_hand_marker.position = _last_hand
	_resize_circle_marker(_shoulder_marker, r)
	_resize_circle_marker(_hand_marker, r)


func _update_debug_markers(cfg: ProceduralArmConfigScript) -> void:
	var r: float = cfg.elbow_joint_radius if cfg.show_elbow_joints else cfg.debug_marker_radius
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

static func _elbow_joint_color(side_label: String) -> Color:
	if side_label == "R":
		return Color(0.95, 0.55, 0.1, 1.0)
	return Color(0.2, 0.75, 0.85, 1.0)


static func _default_arm_texture() -> Texture2D:
	if _cached_default_texture != null:
		return _cached_default_texture
	var img := Image.create(8, 8, false, Image.FORMAT_RGBA8)
	var fill := Color("#ecb58e")
	var stripe := Color("#d4a078")
	for y in range(8):
		for x in range(8):
			var use_stripe: bool = int(x / 2) % 2 == 0
			img.set_pixel(x, y, fill if use_stripe else stripe)
	_cached_default_texture = ImageTexture.create_from_image(img)
	return _cached_default_texture
