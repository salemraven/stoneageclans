extends Area2D
class_name GatherableResource

const CollectionProgressScript = preload("res://scripts/collection_progress.gd")

@export var resource_type: ResourceData.ResourceType = ResourceData.ResourceType.WOOD
@export var min_amount: int = 4
@export var max_amount: int = 6
@export var collection_time: float = 1.0
## WOOD only: 0–14 = fixed frame on trees.png (5×3 sheet). -1 = random frame (default for scattered spawns).
@export var tree_sheet_index: int = -1

# RULE 1: Resources have worker capacity
# Every gatherable resource must declare how many workers it can support
@export var max_workers: int = 2  # Default: 2 workers per resource
var reserved_workers: Array[Node] = []  # Workers that have reserved slots on this resource

@onready var sprite: Sprite2D = $"Sprite"
@onready var collision: CollisionShape2D = $"CollisionShape2D"

var gathered := false
var is_collecting := false
var collection_progress: Node2D = null
var last_gather_press_time := 0.0
const GATHER_COOLDOWN := 0.2  # Small cooldown to prevent double-presses
# Stay in place while gathering — moving cancels (same as NPC)
var collection_start_position: Vector2 = Vector2.ZERO
var gathering_player: Node2D = null  # Player who started collection (to clear is_gathering)
const MOVE_CANCEL_THRESHOLD: float = 20.0

# Resource cooldown system (90 seconds after 3 gathers)
var gather_count: int = 0  # How many times this resource has been gathered
var cooldown_start_time: float = 0.0  # When cooldown started
const MAX_GATHERS_BEFORE_COOLDOWN: int = 3
var COOLDOWN_DURATION: float = 120.0  # Playtest: 120s (BalanceConfig.resource_cooldown_seconds)
var is_in_cooldown: bool = false
var original_modulate: Color = Color.WHITE  # Store original color for cooldown visual
# Bush sprites: swap texture instead of shading (bushon = gatherable, bushoff = cooldown)
var _bush_on_texture: Texture2D = null
var _bush_off_texture: Texture2D = null
# Player searched a tree without axe/oldowan — timer only, no wood; may roll hidden nuts
var _wood_nut_search: bool = false
# Throttle playtest logs when Space is pressed near this node but another target is active
var _gather_diag_wrong_target_last_t: float = -100.0

# OPTIMIZATION: Lock system removed - capacity/reservation system handles resource access
# Old lock system (locked_by, lock_for, unlock) has been migrated to capacity system

func _ready() -> void:
	if BalanceConfig:
		COOLDOWN_DURATION = BalanceConfig.resource_cooldown_seconds
	add_to_group("resources")
	if ResourceIndex:
		ResourceIndex.register(self)
	monitoring = true
	monitorable = false
	_setup_visuals()
	_setup_collision()
	_setup_collection_progress()
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# Store original modulate color for cooldown visual
	if sprite:
		original_modulate = sprite.modulate
	
	# RULE 1: Set max_workers based on resource type if not already set
	# Trees might allow 2-3, Berry bushes maybe 1, Big mammoth carcass maybe 4-6
	if max_workers == 2:  # Only set if using default value
		match resource_type:
			ResourceData.ResourceType.WOOD:
				max_workers = 3  # Trees: 2-3 workers
			ResourceData.ResourceType.STONE:
				max_workers = 2  # Boulders: 2 workers
			ResourceData.ResourceType.BERRIES:
				max_workers = 1  # Berry bushes: 1 worker
			ResourceData.ResourceType.WHEAT:
				max_workers = 1  # Wheat: 1 worker
			ResourceData.ResourceType.FIBER:
				max_workers = 1  # Fiber plants: 1 worker
			ResourceData.ResourceType.BUGS, ResourceData.ResourceType.NUTS:
				max_workers = 1
			_:
				max_workers = 2  # Default fallback
	
	if sprite:
		sprite.z_as_relative = false
		if resource_type == ResourceData.ResourceType.WOOD and sprite.texture:
			YSortUtils.update_tree_draw_order(sprite, self, sprite.texture)
		else:
			YSortUtils.update_object_y_sort(sprite, self)

func _setup_tree_from_sheet() -> void:
	"""Load trees.png sprite sheet (5 cols x 3 rows = 15 trees) and pick random frame."""
	var tex := AssetRegistry.get_treess_sprite()
	if not tex:
		return
	sprite.texture = tex
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.centered = true
	var tree_idx: int
	if tree_sheet_index >= 0 and tree_sheet_index <= 14:
		tree_idx = tree_sheet_index
	else:
		tree_idx = randi_range(0, 14)
	var cols := 5
	var rows := 3
	var cell_w := tex.get_width() / cols
	var cell_h := tex.get_height() / rows
	var col := tree_idx % cols
	var row := tree_idx / cols
	sprite.region_enabled = true
	sprite.region_rect = Rect2(col * cell_w, row * cell_h, cell_w, cell_h)
	sprite.scale = Vector2(1.15, 1.15)
	sprite.position = YSortUtils.get_tree_sprite_position_for_cell_height(cell_h, sprite.scale.y)

func _setup_visuals() -> void:
	# Use sprite files for each resource type
	var sprite_path := ""
	match resource_type:
		ResourceData.ResourceType.WOOD:
			_setup_tree_from_sheet()
			return
		ResourceData.ResourceType.STONE:
			sprite_path = "res://assets/sprites/boulder.png"
		ResourceData.ResourceType.BERRIES:
			_bush_on_texture = load("res://assets/sprites/bushon.png") as Texture2D
			_bush_off_texture = load("res://assets/sprites/bushoff.png") as Texture2D
			sprite_path = "res://assets/sprites/bushon.png"  # default = gatherable
		ResourceData.ResourceType.WHEAT:
			sprite_path = "res://assets/sprites/wheat.png"
		ResourceData.ResourceType.FIBER:
			sprite_path = "res://assets/sprites/fiberplant.png"
		ResourceData.ResourceType.BUGS:
			var bug_paths: Array[String] = [
				"res://assets/sprites/bugs.png",
				"res://assets/sprites/bugs2.png",
				"res://assets/sprites/bugs3.png"
			]
			sprite_path = bug_paths[randi() % bug_paths.size()]
		ResourceData.ResourceType.NUTS:
			var nut_paths: Array[String] = [
				"res://assets/sprites/nuts1.png",
				"res://assets/sprites/nuts2.png",
				"res://assets/sprites/nuts3.png",
				"res://assets/sprites/nuts4.png"
			]
			sprite_path = nut_paths[randi() % nut_paths.size()]
	
	if resource_type == ResourceData.ResourceType.WOOD:
		return  # Already handled above
	if sprite_path != "":
		var loaded_texture: Resource = load(sprite_path)
		if loaded_texture is Texture2D:
			var tex := loaded_texture as Texture2D
			sprite.texture = tex
			sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			sprite.centered = true
			var small_sprite: bool = (
				resource_type == ResourceData.ResourceType.BERRIES
				or resource_type == ResourceData.ResourceType.BUGS
				or resource_type == ResourceData.ResourceType.NUTS
			)
			sprite.scale = Vector2(1.0 / 3.0, 1.0 / 3.0) if small_sprite else Vector2.ONE
			sprite.position = YSortUtils.get_grass_sprite_position_for_texture(tex)
			return
	
	# Fallback: generate colored square if sprite not found
	var image := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	var color := ResourceData.get_resource_color(resource_type)
	image.fill(color)
	var texture := ImageTexture.create_from_image(image)
	sprite.texture = texture
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func _setup_collision() -> void:
	var shape := RectangleShape2D.new()
	# Make trees block a bit more space than other resources
	if resource_type == ResourceData.ResourceType.WOOD:
		shape.size = Vector2(72, 72)
		collision.shape = shape
		collision.position = Vector2.ZERO
		return
	elif resource_type == ResourceData.ResourceType.BUGS or resource_type == ResourceData.ResourceType.NUTS:
		shape.size = Vector2(40, 40)
	else:
		shape.size = Vector2(48, 48)
	collision.shape = shape
	collision.position = Vector2.ZERO
	# Berry bush / wheat / etc.: sprite is shifted up (feet at node) with get_grass_sprite_position_for_texture.
	# A 48×48 rect at the node origin sits *under* a tall texture (e.g. bushon 406×215 @ ⅓ scale) — no overlap → cannot gather.
	_align_gather_hitbox_to_sprite()
	_emit_gather_hitbox_ready()

var nearby_player: Node2D = null


func _emit_gather_hitbox_ready() -> void:
	var pi: Node = get_node_or_null("/root/PlaytestInstrumentor")
	if not pi or not pi.has_method("gather_diagnostic") or not pi.has_method("is_enabled") or not pi.is_enabled():
		return
	if not collision or not collision.shape is RectangleShape2D or not sprite:
		return
	var sh: RectangleShape2D = collision.shape as RectangleShape2D
	var tw: float = float(sprite.texture.get_width()) if sprite.texture else 0.0
	var th: float = float(sprite.texture.get_height()) if sprite.texture else 0.0
	if sprite.texture and sprite.region_enabled:
		tw = sprite.region_rect.size.x
		th = sprite.region_rect.size.y
	var d: Dictionary = {
		"evt": "gather_hitbox_ready",
		"resource": ResourceData.get_resource_name(resource_type),
		"resource_enum": int(resource_type),
		"node_id": get_instance_id(),
		"node_global_x": snappedf(global_position.x, 0.1),
		"node_global_y": snappedf(global_position.y, 0.1),
		"collision_local_x": snappedf(collision.position.x, 0.1),
		"collision_local_y": snappedf(collision.position.y, 0.1),
		"collision_w": sh.size.x,
		"collision_h": sh.size.y,
		"hitbox_center_global_x": snappedf(collision.global_position.x, 0.1),
		"hitbox_center_global_y": snappedf(collision.global_position.y, 0.1),
		"dist_node_origin_to_hitbox_center": snappedf(global_position.distance_to(collision.global_position), 0.1),
		"sprite_local_x": snappedf(sprite.position.x, 0.1),
		"sprite_local_y": snappedf(sprite.position.y, 0.1),
		"sprite_scaled_w": snappedf(tw * absf(sprite.scale.x), 0.1),
		"sprite_scaled_h": snappedf(th * absf(sprite.scale.y), 0.1),
	}
	pi.gather_diagnostic(d)


func _align_gather_hitbox_to_sprite() -> void:
	if not collision or not sprite or not sprite.texture:
		return
	if not collision.shape is RectangleShape2D:
		return
	var shape: RectangleShape2D = collision.shape as RectangleShape2D
	var tex_w: float = float(sprite.texture.get_width())
	var tex_h: float = float(sprite.texture.get_height())
	if sprite.region_enabled:
		tex_w = sprite.region_rect.size.x
		tex_h = sprite.region_rect.size.y
	var sx: float = absf(sprite.scale.x)
	var sy: float = absf(sprite.scale.y)
	var vis_w: float = tex_w * sx
	var vis_h: float = tex_h * sy
	if vis_w < 4.0 or vis_h < 4.0:
		return
	# Center pickup volume on the sprite; cover ~80% of visual so standing “on” the art registers.
	var cover: float = 0.8
	shape.size = Vector2(maxf(shape.size.x, vis_w * cover), maxf(shape.size.y, vis_h * cover))
	collision.position = sprite.position


func _emit_gather_diagnostic(evt: String, player: Node2D, main: Node, extra: Dictionary = {}) -> void:
	var pi: Node = get_node_or_null("/root/PlaytestInstrumentor")
	if not pi or not pi.has_method("gather_diagnostic") or not pi.has_method("is_enabled"):
		return
	if not pi.is_enabled():
		return
	var d: Dictionary = _gather_diagnostic_payload(evt, player, main)
	for k in extra:
		d[k] = extra[k]
	pi.gather_diagnostic(d)


func _gather_diagnostic_payload(evt: String, player: Node2D, main: Node) -> Dictionary:
	var mouse_screen := Vector2.ZERO
	var mouse_world := Vector2.ZERO
	var vp := get_viewport()
	if vp:
		mouse_screen = vp.get_mouse_position()
		var cam: Camera2D = vp.get_camera_2d()
		if cam:
			mouse_world = cam.get_global_mouse_position()
	var coll_w := 0.0
	var coll_h := 0.0
	if collision and collision.shape is RectangleShape2D:
		var rs: RectangleShape2D = collision.shape as RectangleShape2D
		coll_w = rs.size.x
		coll_h = rs.size.y
	var spr_tex_w := 0.0
	var spr_tex_h := 0.0
	var spr_sc_x := 1.0
	var spr_sc_y := 1.0
	if sprite:
		spr_sc_x = sprite.scale.x
		spr_sc_y = sprite.scale.y
		if sprite.texture:
			spr_tex_w = float(sprite.texture.get_width())
			spr_tex_h = float(sprite.texture.get_height())
	var px := 0.0
	var py := 0.0
	if player and is_instance_valid(player):
		px = player.global_position.x
		py = player.global_position.y
	var dist_center := global_position.distance_to(Vector2(px, py))
	var active_valid := false
	var active_id := -1
	if main and is_instance_valid(main):
		var ar: Variant = main.get("active_collection_resource")
		if ar != null and ar is Node2D and is_instance_valid(ar):
			active_valid = true
			active_id = (ar as Object).get_instance_id()
	var hcgx := 0.0
	var hcgy := 0.0
	var clx := 0.0
	var cly := 0.0
	var dist_player_to_hitbox := 0.0
	var dist_node_to_hitbox := 0.0
	if collision:
		clx = collision.position.x
		cly = collision.position.y
		hcgx = collision.global_position.x
		hcgy = collision.global_position.y
		dist_node_to_hitbox = global_position.distance_to(collision.global_position)
		if player and is_instance_valid(player):
			dist_player_to_hitbox = player.global_position.distance_to(collision.global_position)
	return {
		"evt": evt,
		"resource": ResourceData.get_resource_name(resource_type),
		"resource_enum": int(resource_type),
		"node_id": get_instance_id(),
		"bush_x": snappedf(global_position.x, 0.1),
		"bush_y": snappedf(global_position.y, 0.1),
		"player_x": snappedf(px, 0.1),
		"player_y": snappedf(py, 0.1),
		"dist_player_to_node_center": snappedf(dist_center, 0.1),
		"collision_local_x": snappedf(clx, 0.1),
		"collision_local_y": snappedf(cly, 0.1),
		"hitbox_center_global_x": snappedf(hcgx, 0.1),
		"hitbox_center_global_y": snappedf(hcgy, 0.1),
		"dist_player_to_hitbox_center": snappedf(dist_player_to_hitbox, 0.1),
		"dist_node_origin_to_hitbox_center": snappedf(dist_node_to_hitbox, 0.1),
		"collision_w": coll_w,
		"collision_h": coll_h,
		"collision_half_w": snappedf(coll_w * 0.5, 0.1),
		"collision_half_h": snappedf(coll_h * 0.5, 0.1),
		"sprite_tex_w": spr_tex_w,
		"sprite_tex_h": spr_tex_h,
		"sprite_scale_x": spr_sc_x,
		"sprite_scale_y": spr_sc_y,
		"approx_visual_w": snappedf(spr_tex_w * absf(spr_sc_x), 0.1),
		"approx_visual_h": snappedf(spr_tex_h * absf(spr_sc_y), 0.1),
		"mouse_screen_x": snappedf(mouse_screen.x, 0.1),
		"mouse_screen_y": snappedf(mouse_screen.y, 0.1),
		"mouse_world_x": snappedf(mouse_world.x, 0.1),
		"mouse_world_y": snappedf(mouse_world.y, 0.1),
		"dist_mouse_to_node_center": snappedf(mouse_world.distance_to(global_position), 0.1),
		"player_in_gather_hitbox": player != null and is_instance_valid(player) and overlaps_body(player),
		"active_target_valid": active_valid,
		"active_target_id": active_id,
		"this_is_active_target": main != null and is_instance_valid(main) and main.get("active_collection_resource") == self,
		"is_cooldown": is_in_cooldown,
		"gather_count": gather_count,
		"move_cancel_threshold_px": MOVE_CANCEL_THRESHOLD,
	}


func _on_body_entered(body: Node2D) -> void:
	if gathered:
		return
	if body.is_in_group("player"):
		nearby_player = body
		# Try to become the active collection resource
		var main := get_tree().get_first_node_in_group("main")
		if main:
			var player_pos := body.global_position
			var this_distance := player_pos.distance_to(global_position)
			
			# If no resource is active, or this one is closer, make it active
			if main.active_collection_resource == null:
				main.active_collection_resource = self
			elif main.active_collection_resource != self:
				var other: Variant = main.active_collection_resource
				if other == null or not is_instance_valid(other):
					main.active_collection_resource = self
				else:
					var other_distance := player_pos.distance_to((other as Node2D).global_position)
					if this_distance < other_distance:
						main.active_collection_resource = self
		_emit_gather_diagnostic("gather_body_entered", body, main)

func _on_body_exited(body: Node2D) -> void:
	if body == nearby_player:
		nearby_player = null
		# Clear active collection if this was the active resource
		var main := get_tree().get_first_node_in_group("main")
		if main:
			if main.active_collection_resource == self:
				main.active_collection_resource = null
		_emit_gather_diagnostic("gather_body_exited", body, main)
		_stop_collection("player_left_hitbox")

func _setup_collection_progress() -> void:
	var progress_node := Node2D.new()
	progress_node.set_script(CollectionProgressScript)
	collection_progress = progress_node
	
	if collection_progress:
		collection_progress.set("collection_time", collection_time)
		# Position above the resource
		var offset_y: float = -40.0
		if sprite and sprite.texture:
			offset_y = -sprite.texture.get_height() / 2.0 - 40.0
		collection_progress.position = Vector2(0, offset_y)
		collection_progress.z_as_relative = false
		collection_progress.z_index = YSortUtils.Z_ABOVE_WORLD  # Above Y-sorted sprite
		add_child(collection_progress)
		collection_progress.visible = false

func _process(delta: float) -> void:
	# Update cooldown visual
	_update_cooldown_visual()
	
	# Check if cooldown has expired
	if is_in_cooldown:
		var current_time: float = Time.get_ticks_msec() / 1000.0
		if current_time - cooldown_start_time >= COOLDOWN_DURATION:
			# Cooldown expired - reset
			is_in_cooldown = false
			gather_count = 0
			cooldown_start_time = 0.0
			_update_cooldown_visual()  # Update visual to normal
	
	if gathered:
		return
	
	# Check for E key press (just pressed, not held) when player is nearby
	if nearby_player:
		# Make sure this resource is active if no other is active
		var main: Node = get_tree().get_first_node_in_group("main")
		if main:
			var ar: Variant = main.get("active_collection_resource")
			if ar != null and not is_instance_valid(ar):
				main.active_collection_resource = null
			# If no resource is active, make this one active
			if main.active_collection_resource == null:
				main.active_collection_resource = self
			# If another resource is active, check if this one is closer
			elif main.active_collection_resource != self:
				var player_pos := nearby_player.global_position
				var this_distance := player_pos.distance_to(global_position)
				var other2: Variant = main.active_collection_resource
				if other2 != null and is_instance_valid(other2):
					var other_distance := player_pos.distance_to((other2 as Node2D).global_position)
					if this_distance < other_distance:
						main.active_collection_resource = self
				else:
					main.active_collection_resource = self
		
		# Check if this resource is the active collection resource
		var is_active := false
		if main:
			is_active = (main.active_collection_resource == self)
		
		if Input.is_action_just_pressed("gather") and main and not is_active:
			var now_sec: float = Time.get_ticks_msec() / 1000.0
			if now_sec - _gather_diag_wrong_target_last_t >= 0.35:
				_gather_diag_wrong_target_last_t = now_sec
				_emit_gather_diagnostic("gather_space_wrong_active_target", nearby_player, main, {
					"note": "Space while overlapping this hitbox but active_collection_resource is another node or null"
				})
		
		# Only process if this is the active resource
		if is_active:
			if Input.is_action_just_pressed("gather"):
				var current_time := Time.get_ticks_msec() / 1000.0
				# Prevent double-presses with small cooldown
				if current_time - last_gather_press_time >= GATHER_COOLDOWN:
					last_gather_press_time = current_time
					_collect_one_item()
			elif is_collecting and gathering_player:
				# Player moved — cancel gather (must stay in place)
				var moved := gathering_player.global_position.distance_to(collection_start_position)
				if moved > MOVE_CANCEL_THRESHOLD:
					_stop_collection("moved_while_collecting")
	elif is_collecting:
		# Player left area, stop collection
		_stop_collection("left_hitbox_while_collecting")

func _is_bumping(player: Node2D) -> bool:
	# Check if player is very close (bump detection)
	var player_pos := player.global_position
	var resource_pos := global_position
	return player_pos.distance_to(resource_pos) < 40.0

func _collect_one_item() -> void:
	var main: Node = get_tree().get_first_node_in_group("main")
	# Check if resource is exhausted (in cooldown)
	if is_in_cooldown:
		_emit_gather_diagnostic("gather_blocked_cooldown", nearby_player, main)
		print("Resource is exhausted, cannot collect")
		return
	
	# Check if tool is required for this resource type
	if not main:
		return
	
	# Tool requirements: WOOD needs Axe or Oldowan; STONE needs Pick or Oldowan
	if main.has_method("has_tool_for_gather") and not main.has_tool_for_gather(resource_type):
		if resource_type == ResourceData.ResourceType.WOOD:
			_emit_gather_diagnostic("gather_blocked_tool_wood_search", nearby_player, main, {"fallback": "wood_nut_search"})
			_start_wood_nut_search(main)
			return
		var msg: String = ""
		if resource_type == ResourceData.ResourceType.STONE:
			msg = "Need Oldowan or Pick for stone"
		_emit_gather_diagnostic("gather_blocked_tool", nearby_player, main, {"detail": msg})
		if msg != "" and main.has_method("_show_placement_warning"):
			main._show_placement_warning(msg)
		return
	
	# This should already be the active resource, but double-check
	if main.active_collection_resource != self:
		_emit_gather_diagnostic("gather_blocked_not_active_target", nearby_player, main)
		print("Not the active resource, cannot collect")
		return  # Not the active resource, don't collect
	
	# Oldowan slower than Axe/Pick: multiply collection time when using Oldowan for wood/stone
	var effective_time: float = collection_time
	if resource_type == ResourceData.ResourceType.WOOD and main.is_oldowan_equipped() and not main.is_axe_equipped():
		effective_time = collection_time * (BalanceConfig.oldowan_gather_multiplier if BalanceConfig else 1.5)
	elif resource_type == ResourceData.ResourceType.STONE and main.is_oldowan_equipped() and not main.is_pick_equipped():
		effective_time = collection_time * (BalanceConfig.oldowan_gather_multiplier if BalanceConfig else 1.5)
	
	# Start collection progress visual; player must stay in place (moving cancels)
	collection_start_position = nearby_player.global_position
	gathering_player = nearby_player
	if gathering_player != null:
		gathering_player.set("is_gathering", true)
	if collection_progress:
		# Match timer icon to world sprite for multi-variant pickups (bugs1/2/3, nuts1–4). Trees use sheet — keep generic wood icon.
		var icon: Texture2D = null
		match resource_type:
			ResourceData.ResourceType.BUGS, ResourceData.ResourceType.NUTS:
				if sprite and sprite.texture:
					icon = sprite.texture
		if icon == null:
			var icon_path: String = ResourceData.get_resource_icon_path(resource_type)
			if icon_path != "":
				icon = load(icon_path) as Texture2D
		collection_progress.start_collection(icon)
		collection_progress.collection_time = effective_time
	
	# Wait for collection time, then give item
	is_collecting = true
	_emit_gather_diagnostic("gather_started", nearby_player, main, {"effective_time": effective_time})
	var timer := get_tree().create_timer(effective_time)
	timer.timeout.connect(func(): _finish_collection())

func _start_wood_nut_search(main: Node) -> void:
	if is_in_cooldown:
		return
	if main.active_collection_resource != self:
		return
	if not nearby_player:
		return
	_wood_nut_search = true
	collection_start_position = nearby_player.global_position
	gathering_player = nearby_player
	gathering_player.set("is_gathering", true)
	var search_time: float = 0.9
	if collection_progress:
		collection_progress.collection_time = search_time
		collection_progress.start_collection(null)
	is_collecting = true
	var timer := get_tree().create_timer(search_time)
	timer.timeout.connect(func(): _finish_wood_nut_search())

func _finish_wood_nut_search() -> void:
	if not _wood_nut_search:
		return
	_wood_nut_search = false
	var main := get_tree().get_first_node_in_group("main")
	if gathering_player != null:
		var moved := gathering_player.global_position.distance_to(collection_start_position)
		if moved > MOVE_CANCEL_THRESHOLD:
			is_collecting = false
			if collection_progress:
				collection_progress.stop_collection(true)
			_clear_gathering_player()
			return
	is_collecting = false
	if collection_progress:
		collection_progress.stop_collection(false)
	if main and main.has_method("add_to_inventory"):
		if randf() < 0.25:
			main.add_to_inventory(ResourceData.ResourceType.NUTS, 1)
		elif main.has_method("_show_placement_warning"):
			main._show_placement_warning("Nothing here")
	_clear_gathering_player()

func _finish_collection() -> void:
	var main_finish: Node = get_tree().get_first_node_in_group("main")
	# If player moved during collection, cancel (no item)
	if gathering_player != null:
		var moved := gathering_player.global_position.distance_to(collection_start_position)
		if moved > MOVE_CANCEL_THRESHOLD:
			_emit_gather_diagnostic("gather_cancelled_player_moved", gathering_player, main_finish, {"moved_px": moved})
			gathering_player.set("is_gathering", false)
			gathering_player = null
			is_collecting = false
			if collection_progress:
				collection_progress.stop_collection(true)
			return
	# Collection complete, give item to player
	if not main_finish:
		_clear_gathering_player()
		return
	
	# Check if resource is in cooldown (exhausted)
	if is_in_cooldown:
		_emit_gather_diagnostic("gather_blocked_cooldown_at_finish", gathering_player, main_finish)
		is_collecting = false
		if collection_progress:
			collection_progress.stop_collection(false)
		_clear_gathering_player()
		return
	
	# Increment gather count (track player gathers too)
	gather_count += 1
	
	# If reached max gathers, start cooldown (exhausted state)
	if gather_count >= MAX_GATHERS_BEFORE_COOLDOWN:
		is_in_cooldown = true
		cooldown_start_time = Time.get_ticks_msec() / 1000.0
		_update_cooldown_visual()
	
	# Determine what item to give based on resource type
	var item_type: ResourceData.ResourceType = resource_type
	
	# Wheat nodes give grain items
	if resource_type == ResourceData.ResourceType.WHEAT:
		item_type = ResourceData.ResourceType.GRAIN
	# Fiber plants give fiber items
	elif resource_type == ResourceData.ResourceType.FIBER:
		item_type = ResourceData.ResourceType.FIBER
	
	# Give exactly 1 item
	if main_finish and main_finish.has_method("add_to_inventory"):
		main_finish.add_to_inventory(item_type, 1)
		_emit_gather_diagnostic("gather_complete", gathering_player, main_finish, {"item": ResourceData.get_resource_name(item_type)})
		# Hidden nut find while chopping / working the tree (no extra spot on the map)
		if resource_type == ResourceData.ResourceType.WOOD and randf() < 0.25:
			main_finish.add_to_inventory(ResourceData.ResourceType.NUTS, 1)
	else:
		_emit_gather_diagnostic("gather_complete_no_inventory", gathering_player, main_finish, {"item": ResourceData.get_resource_name(item_type)})
	
	# Stop collection visual
	is_collecting = false
	if collection_progress:
		collection_progress.stop_collection(false)
	_clear_gathering_player()

func _clear_gathering_player() -> void:
	if gathering_player != null:
		gathering_player.set("is_gathering", false)
		gathering_player = null

func _stop_collection(reason: String = "unspecified") -> void:
	var gp: Node2D = gathering_player
	var was_collecting: bool = is_collecting or _wood_nut_search
	_wood_nut_search = false
	is_collecting = false
	if collection_progress:
		collection_progress.stop_collection(true)
	if was_collecting and gp != null and is_instance_valid(gp):
		var main_stop: Node = get_tree().get_first_node_in_group("main")
		_emit_gather_diagnostic("gather_stopped", gp, main_stop, {"reason": reason})
	_clear_gathering_player()

# NPC interaction methods
func is_edible() -> bool:
	# Berries, wheat, and fiber are edible (for sheep/goats)
	return resource_type == ResourceData.ResourceType.BERRIES or resource_type == ResourceData.ResourceType.WHEAT or resource_type == ResourceData.ResourceType.FIBER

# Empty/depleted = in cooldown or not harvestable. We do NOT mark as "harvested" (queue_free);
# nodes respawn via cooldown so NPCs skip empty nodes in detection and don't call harvest() on them.
func is_harvestable() -> bool:
	# Trees, boulders, berries, wheat, and fiber plants are harvestable
	# But not if they're in cooldown
	if is_in_cooldown:
		return false
	
	# OPTIMIZATION: Lock check removed - capacity/reservation system handles access control
	return (resource_type == ResourceData.ResourceType.WOOD or 
		resource_type == ResourceData.ResourceType.STONE or 
		resource_type == ResourceData.ResourceType.BERRIES or
		resource_type == ResourceData.ResourceType.WHEAT or
		resource_type == ResourceData.ResourceType.FIBER or
		resource_type == ResourceData.ResourceType.BUGS or
		resource_type == ResourceData.ResourceType.NUTS)

# Task System - Check if resource is harvestable without checking locks (for internal use)
func is_harvestable_ignore_lock() -> bool:
	"""Check if resource is harvestable (cooldown, type) but ignore lock status."""
	if is_in_cooldown:
		return false
	
	return (resource_type == ResourceData.ResourceType.WOOD or 
		resource_type == ResourceData.ResourceType.STONE or 
		resource_type == ResourceData.ResourceType.BERRIES or
		resource_type == ResourceData.ResourceType.WHEAT or
		resource_type == ResourceData.ResourceType.FIBER or
		resource_type == ResourceData.ResourceType.BUGS or
		resource_type == ResourceData.ResourceType.NUTS)

# OPTIMIZATION: Lock system methods removed - migrated to capacity/reservation system
# Use reserve()/release() methods instead of lock_for()/unlock()

func is_in_cooldown_state() -> bool:
	# Public method to check if resource is in cooldown
	return is_in_cooldown

func consume() -> void:
	# NPCs consume edible resources
	# DISABLED FOR TESTING: Resources are unlimited
	#if is_edible():
	#	queue_free()
	pass

func harvest() -> int:
	# NPCs harvest resources, returns yield amount
	# Check if resource is in cooldown
	if is_in_cooldown:
		return 0  # Can't harvest during cooldown
	
	# OPTIMIZATION: Lock system removed - use is_harvestable_ignore_lock() directly
	var can_harvest: bool = false
	if has_method("is_harvestable_ignore_lock"):
		can_harvest = is_harvestable_ignore_lock()
	else:
		# Fallback: use is_harvestable() (no longer checks locks)
		can_harvest = is_harvestable()
	
	if can_harvest:
		# Increment gather count
		gather_count += 1
		
		# If reached max gathers, start cooldown
		if gather_count >= MAX_GATHERS_BEFORE_COOLDOWN:
			is_in_cooldown = true
			cooldown_start_time = Time.get_ticks_msec() / 1000.0
			_update_cooldown_visual()
		
		# SIMPLIFIED: All resources now yield 1 item per harvest for predictability
		# This prevents inventory overflow and makes threshold checks reliable
		# Previous: Wood/Stone yielded 4-6 items (random), causing overflow issues
		# Now: All resources yield 1 item - predictable, simple, reliable
		# DISABLED FOR TESTING: Resources are unlimited
		#queue_free()
		return 1  # Always yield 1 item per harvest (simplified, predictable)
	return 0

func _update_cooldown_visual() -> void:
	if not sprite:
		return
	# Berries: swap sprite to bushon (gatherable) / bushoff (cooldown), no shading
	if resource_type == ResourceData.ResourceType.BERRIES and _bush_on_texture and _bush_off_texture:
		sprite.texture = _bush_off_texture if is_in_cooldown else _bush_on_texture
		sprite.modulate = original_modulate
		return
	# Other resources: darker and less saturated during cooldown (exhausted state)
	if is_in_cooldown:
		var exhausted_color: Color = original_modulate
		exhausted_color.r = exhausted_color.r * 0.4
		exhausted_color.g = exhausted_color.g * 0.4
		exhausted_color.b = exhausted_color.b * 0.4
		var grey: float = (exhausted_color.r + exhausted_color.g + exhausted_color.b) / 3.0
		exhausted_color.r = lerp(grey, exhausted_color.r, 0.3)
		exhausted_color.g = lerp(grey, exhausted_color.g, 0.3)
		exhausted_color.b = lerp(grey, exhausted_color.b, 0.3)
		exhausted_color.a = original_modulate.a
		sprite.modulate = exhausted_color
	else:
		sprite.modulate = original_modulate

# RULE 2: Jobs reserve resource slots
# Reserve a slot on this resource for a worker
func reserve(worker: Node) -> bool:
	"""Reserve a slot on this resource. Returns true if reservation succeeded, false if full."""
	# Clean up invalid workers first
	_prune_reserved_workers()
	
	# Check if resource has capacity
	if reserved_workers.size() >= max_workers:
		return false  # Resource is full
	
	# Check if worker is already reserved (prevent duplicates)
	if worker in reserved_workers:
		return true  # Already reserved
	
	# Reserve slot
	reserved_workers.append(worker)
	return true

# Release a slot when job ends (success OR fail)
func release(worker: Node) -> void:
	"""Release a slot on this resource."""
	reserved_workers.erase(worker)
	_prune_reserved_workers()

# RULE 3: Job generator must skip saturated resources
func has_capacity() -> bool:
	"""Check if resource has available capacity for more workers."""
	_prune_reserved_workers()
	return reserved_workers.size() < max_workers

# Clean up invalid workers from reserved list
func _prune_reserved_workers() -> void:
	"""Remove invalid workers from reserved_workers list."""
	var valid_workers: Array[Node] = []
	for worker in reserved_workers:
		if is_instance_valid(worker):
			valid_workers.append(worker)
	reserved_workers = valid_workers

func _exit_tree() -> void:
	var main_node := get_tree().get_first_node_in_group("main")
	if main_node and main_node.get("active_collection_resource") == self:
		main_node.active_collection_resource = null
	if ResourceIndex:
		ResourceIndex.unregister(self)
	"""OPTIMIZATION: Cleanup when resource is destroyed - release all reservations and cancel affected jobs"""
	# Release all reservations and notify workers to cancel their jobs (iterate copy to avoid modification during iteration)
	for worker in reserved_workers.duplicate():
		if is_instance_valid(worker):
			# Cancel job for this worker (job cancellation will release the reservation)
			if worker.has_method("get") and "task_runner" in worker:
				var task_runner = worker.get("task_runner")
				if task_runner and is_instance_valid(task_runner) and task_runner.has_method("cancel_current_job"):
					task_runner.cancel_current_job()
					var worker_name: String = "unknown"
					if worker.has_method("get"):
						var name_value = worker.get("npc_name")
						if name_value != null:
							worker_name = str(name_value)
					print("🔧 Resource destroyed - cancelled job for worker %s" % worker_name)
	reserved_workers.clear()
