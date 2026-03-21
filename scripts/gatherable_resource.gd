extends Area2D
class_name GatherableResource

const CollectionProgressScript = preload("res://scripts/collection_progress.gd")

@export var resource_type: ResourceData.ResourceType = ResourceData.ResourceType.WOOD
@export var min_amount: int = 4
@export var max_amount: int = 6
@export var collection_time: float = 1.0

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

# OPTIMIZATION: Lock system removed - capacity/reservation system handles resource access
# Old lock system (locked_by, lock_for, unlock) has been migrated to capacity system

func _ready() -> void:
	if BalanceConfig:
		COOLDOWN_DURATION = BalanceConfig.resource_cooldown_seconds
	add_to_group("resources")
	if ResourceIndex:
		ResourceIndex.register(self)
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
	var tree_idx := randi_range(0, 14)
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
	
	if resource_type == ResourceData.ResourceType.WOOD:
		return  # Already handled above
	if sprite_path != "":
		var loaded_texture: Resource = load(sprite_path)
		if loaded_texture is Texture2D:
			var tex := loaded_texture as Texture2D
			sprite.texture = tex
			sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			sprite.centered = true
			sprite.scale = Vector2(1.0 / 3.0, 1.0 / 3.0) if resource_type == ResourceData.ResourceType.BERRIES else Vector2.ONE
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
	else:
		shape.size = Vector2(48, 48)
	collision.shape = shape

var nearby_player: Node2D = null

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
				var other_distance := player_pos.distance_to(main.active_collection_resource.global_position)
				if this_distance < other_distance:
					main.active_collection_resource = self

func _on_body_exited(body: Node2D) -> void:
	if body == nearby_player:
		nearby_player = null
		# Clear active collection if this was the active resource
		var main := get_tree().get_first_node_in_group("main")
		if main:
			if main.active_collection_resource == self:
				main.active_collection_resource = null
		_stop_collection()

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
		var main := get_tree().get_first_node_in_group("main")
		if main:
			# If no resource is active, make this one active
			if main.active_collection_resource == null:
				main.active_collection_resource = self
			# If another resource is active, check if this one is closer
			elif main.active_collection_resource != self:
				var player_pos := nearby_player.global_position
				var this_distance := player_pos.distance_to(global_position)
				var other_distance := player_pos.distance_to(main.active_collection_resource.global_position)
				if this_distance < other_distance:
					main.active_collection_resource = self
		
		# Check if this resource is the active collection resource
		var is_active := false
		if main:
			is_active = (main.active_collection_resource == self)
		
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
					_stop_collection()
	elif is_collecting:
		# Player left area, stop collection
		_stop_collection()

func _is_bumping(player: Node2D) -> bool:
	# Check if player is very close (bump detection)
	var player_pos := player.global_position
	var resource_pos := global_position
	return player_pos.distance_to(resource_pos) < 40.0

func _collect_one_item() -> void:
	# Check if resource is exhausted (in cooldown)
	if is_in_cooldown:
		print("Resource is exhausted, cannot collect")
		return
	
	# Check if tool is required for this resource type
	var main := get_tree().get_first_node_in_group("main")
	if not main:
		return
	
	# Tool requirements: WOOD needs Axe or Oldowan; STONE needs Pick or Oldowan
	if main.has_method("has_tool_for_gather") and not main.has_tool_for_gather(resource_type):
		var msg: String = ""
		if resource_type == ResourceData.ResourceType.WOOD:
			msg = "Need Oldowan or Axe for wood"
		elif resource_type == ResourceData.ResourceType.STONE:
			msg = "Need Oldowan or Pick for stone"
		if msg != "" and main.has_method("_show_placement_warning"):
			main._show_placement_warning(msg)
		return
	
	# This should already be the active resource, but double-check
	if main.active_collection_resource != self:
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
		# Get icon for this resource type
		var icon: Texture2D = null
		var icon_path: String = ResourceData.get_resource_icon_path(resource_type)
		if icon_path != "":
			icon = load(icon_path) as Texture2D
		collection_progress.start_collection(icon)
		collection_progress.collection_time = effective_time
	
	# Wait for collection time, then give item
	is_collecting = true
	var timer := get_tree().create_timer(effective_time)
	timer.timeout.connect(func(): _finish_collection())

func _finish_collection() -> void:
	# If player moved during collection, cancel (no item)
	if gathering_player != null:
		var moved := gathering_player.global_position.distance_to(collection_start_position)
		if moved > MOVE_CANCEL_THRESHOLD:
			gathering_player.set("is_gathering", false)
			gathering_player = null
			is_collecting = false
			if collection_progress:
				collection_progress.stop_collection()
			return
	# Collection complete, give item to player
	var main := get_tree().get_first_node_in_group("main")
	if not main:
		_clear_gathering_player()
		return
	
	# Check if resource is in cooldown (exhausted)
	if is_in_cooldown:
		# Resource is exhausted - can't collect
		is_collecting = false
		if collection_progress:
			collection_progress.stop_collection()
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
	if main and main.has_method("add_to_inventory"):
		main.add_to_inventory(item_type, 1)
	
	# Stop collection visual
	is_collecting = false
	if collection_progress:
		collection_progress.stop_collection()
	_clear_gathering_player()

func _clear_gathering_player() -> void:
	if gathering_player != null:
		gathering_player.set("is_gathering", false)
		gathering_player = null

func _stop_collection() -> void:
	is_collecting = false
	if collection_progress:
		collection_progress.stop_collection()
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
		resource_type == ResourceData.ResourceType.FIBER)

# Task System - Check if resource is harvestable without checking locks (for internal use)
func is_harvestable_ignore_lock() -> bool:
	"""Check if resource is harvestable (cooldown, type) but ignore lock status."""
	if is_in_cooldown:
		return false
	
	return (resource_type == ResourceData.ResourceType.WOOD or 
		resource_type == ResourceData.ResourceType.STONE or 
		resource_type == ResourceData.ResourceType.BERRIES or
		resource_type == ResourceData.ResourceType.WHEAT or
		resource_type == ResourceData.ResourceType.FIBER)

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
