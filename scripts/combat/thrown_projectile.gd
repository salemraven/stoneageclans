extends Node2D

const ThrowHitResolver = preload("res://scripts/combat/throw_hit_resolver.gd")

const MAX_IN_FLIGHT := 16
const MAX_LANDED_THROWN := 20

static var _pool: Array = []
static var _landed: Array[Node] = []

var _from: Vector2 = Vector2.ZERO
var _to: Vector2 = Vector2.ZERO
var _elapsed: float = 0.0
var _duration: float = ThrowHitResolver.FALLBACK_FLIGHT_SEC
var _thrower: Node2D = null
var _damage: int = 6
var _item_type: ResourceData.ResourceType = ResourceData.ResourceType.STONE
var _in_use: bool = false

var _rock: Sprite2D = null
var _shadow: Sprite2D = null


func _ready() -> void:
	z_as_relative = false
	z_index = YSortUtils.Z_ABOVE_WORLD
	if _rock == null:
		_rock = Sprite2D.new()
		_rock.name = "Rock"
		_rock.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_rock.centered = true
		add_child(_rock)
	if _shadow == null:
		_shadow = Sprite2D.new()
		_shadow.name = "Shadow"
		_shadow.centered = true
		_shadow.modulate = Color(0, 0, 0, 0.35)
		_shadow.scale = Vector2(0.45, 0.22)
		add_child(_shadow)
	set_process(false)
	visible = false


static func fire(
	parent: Node,
	from: Vector2,
	to: Vector2,
	thrower: Node2D,
	damage: int = -1,
	item_type: ResourceData.ResourceType = ResourceData.ResourceType.STONE
):
	if ThrowHitResolver.is_online_client():
		return null
	var shot = _take(parent)
	var dmg: int = damage if damage >= 0 else ThrowHitResolver.throw_damage()
	shot._begin(from, to, thrower, dmg, item_type)
	return shot


static func _take(parent: Node):
	for p in _pool:
		if is_instance_valid(p) and not p._in_use:
			return p
	if _pool.size() >= MAX_IN_FLIGHT:
		for p in _pool:
			if is_instance_valid(p):
				p._recycle()
				return p
	var n: Node2D = (load("res://scripts/combat/thrown_projectile.gd") as GDScript).new() as Node2D
	if parent:
		parent.add_child(n)
	_pool.append(n)
	return n


func _held_overlay_scale(thrower: Node2D, icon: Texture2D) -> Vector2:
	if thrower:
		if thrower.has_meta("throw_flight_scale"):
			var stored: Vector2 = thrower.get_meta("throw_flight_scale") as Vector2
			if stored.length_squared() > 0.0001:
				return stored
		var overlay: Sprite2D = thrower.get_node_or_null("Sprite/WeaponOverlay") as Sprite2D
		if overlay and overlay.texture == icon:
			return overlay.global_scale.abs()
	if _item_type == ResourceData.ResourceType.STONE:
		return Vector2(0.55, 0.55)
	return Vector2(0.12, 0.12)


func _begin(
	from: Vector2,
	to: Vector2,
	thrower: Node2D,
	damage: int,
	item_type: ResourceData.ResourceType
) -> void:
	_from = from
	_to = to
	_thrower = thrower
	_damage = damage
	_item_type = item_type
	_elapsed = 0.0
	_duration = ThrowHitResolver.flight_sec()
	_in_use = true
	visible = true
	var icon: Texture2D = load(ResourceData.get_resource_icon_path(item_type)) as Texture2D
	if _rock:
		_rock.texture = icon
		_rock.scale = _held_overlay_scale(thrower, icon)
		_rock.rotation = 0.0
		if thrower and thrower.has_meta("throw_flight_rotation"):
			_rock.rotation = float(thrower.get_meta("throw_flight_rotation"))
	if _shadow:
		_shadow.texture = icon
		_shadow.scale = _rock.scale * Vector2(1.0, 0.35) if _rock else Vector2(0.45, 0.22)
		_shadow.rotation = _rock.rotation if _rock else 0.0
	global_position = from
	set_process(true)


func _process(delta: float) -> void:
	_elapsed += delta
	var t: float = clampf(_elapsed / _duration, 0.0, 1.0)
	var ground: Vector2 = _from.lerp(_to, t)
	var height: float = 4.0 * ThrowHitResolver.arc_height_px() * t * (1.0 - t)
	global_position = ground
	if _shadow:
		_shadow.position = Vector2.ZERO
	if _rock:
		_rock.position = Vector2(0, -height)
	if t >= 1.0:
		_land(ground)


func _land(ground: Vector2) -> void:
	_apply_hit(ground)
	if ThrowHitResolver.leaves_ground_pickup(_item_type):
		_spawn_ground(ground)
	else:
		_stick_in_world(ground)
	_recycle()


func _stick_in_world(ground: Vector2) -> void:
	var parent: Node = get_parent()
	if parent == null:
		return
	var stuck := Sprite2D.new()
	stuck.name = "StuckSpear"
	stuck.texture = _rock.texture if _rock else null
	stuck.centered = true
	stuck.rotation = (_to - _from).angle() + PI * 0.5
	stuck.scale = _rock.scale if _rock else Vector2.ONE
	stuck.z_as_relative = false
	stuck.z_index = 0
	parent.add_child(stuck)
	stuck.global_position = ground


func _apply_hit(ground: Vector2) -> void:
	if not is_inside_tree():
		return
	if ThrowHitResolver.is_online_client():
		return
	var tree := get_tree()
	var radius: float = ThrowHitResolver.land_hit_radius_px()
	var best: Node2D = ThrowHitResolver.find_best_target_at_point(ground, radius, _thrower, tree)
	var best_d: float = INF
	if best:
		best_d = ground.distance_to(ThrowHitResolver.get_hit_point(best))
	_log_throw_result(ground, best, best_d, radius)
	if best == null:
		return
	if not ThrowHitResolver.roll_hit(_thrower, ground):
		_log_throw_whiff(ground, best, "skill_roll")
		return
	if best.is_in_group("buildings") and best.has_method("take_damage"):
		best.take_damage(float(_damage))
		return
	var hc: Node = best.get_node_or_null("HealthComponent")
	if hc and hc.has_method("take_damage"):
		hc.take_damage(_damage, _thrower, _item_type)


func _log_throw_result(ground: Vector2, best: Node2D, best_d: float, radius: float) -> void:
	var dc: Node = get_node_or_null("/root/DebugConfig")
	if dc == null or not bool(dc.get("enable_throw_debug")):
		return
	if best == null:
		print("THROW_WHIFF land=%s radius=%.1f (no target)" % [ground, radius])
		_debug_mark_land(ground, false)
		return
	print("THROW_HIT land=%s victim=%s dist=%.1f radius=%.1f" % [
		ground, best.name if best else "?", best_d, radius
	])
	_debug_mark_land(ground, true)


func _log_throw_whiff(ground: Vector2, best: Node2D, reason: String) -> void:
	var dc: Node = get_node_or_null("/root/DebugConfig")
	if dc == null or not bool(dc.get("enable_throw_debug")):
		return
	print("THROW_WHIFF land=%s victim=%s reason=%s" % [ground, best.name if best else "?", reason])
	_debug_mark_land(ground, false)


func _debug_mark_land(ground: Vector2, hit: bool) -> void:
	var marker := Node2D.new()
	marker.name = "ThrowLandDebug"
	marker.global_position = ground
	var ring := Line2D.new()
	ring.width = 2.0
	ring.closed = true
	ring.default_color = Color(0.2, 1.0, 0.3, 0.85) if hit else Color(1.0, 0.35, 0.2, 0.85)
	var r: float = ThrowHitResolver.land_hit_radius_px()
	var pts: PackedVector2Array = PackedVector2Array()
	for i in 24:
		var a: float = TAU * float(i) / 24.0
		pts.append(Vector2(cos(a), sin(a)) * r)
	ring.points = pts
	marker.add_child(ring)
	var parent_n: Node = get_parent()
	if parent_n:
		parent_n.add_child(marker)
		marker.global_position = ground
	get_tree().create_timer(1.2).timeout.connect(marker.queue_free)


func _spawn_ground(ground: Vector2) -> void:
	var main: Node = get_tree().get_first_node_in_group("main")
	if main and main.has_method("spawn_thrown_ground_item"):
		main.spawn_thrown_ground_item(_item_type, ground)


func _recycle() -> void:
	_in_use = false
	visible = false
	set_process(false)
	_thrower = null


static func register_landed(item: Node) -> void:
	_prune_landed()
	if item:
		_landed.append(item)
	while _landed.size() > MAX_LANDED_THROWN:
		var old: Node = _landed.pop_front()
		if old and is_instance_valid(old):
			old.queue_free()


static func _prune_landed() -> void:
	var keep: Array[Node] = []
	for n in _landed:
		if n and is_instance_valid(n):
			keep.append(n)
	_landed = keep
