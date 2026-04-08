extends Area2D
class_name GroundItem

# Ground items (stone, wood, mushrooms) — walk up, Space + timer, then pickup (like loose wood/stone piles)
# Players and NPCs must gather them with a timer before picking them up

const CollectionProgressScript = preload("res://scripts/collection_progress.gd")

@export var item_type: ResourceData.ResourceType = ResourceData.ResourceType.STONE
@export var collection_time: float = 1.0  # Time to gather

# For compatibility with resource system - NPCs look for resource_type
var resource_type: ResourceData.ResourceType:
	get:
		return item_type
	set(value):
		item_type = value

@onready var sprite: Sprite2D = $"Sprite"
var collision: CollisionShape2D = null  # Will be created in _setup_collision()

var is_picked_up: bool = false
var is_collecting: bool = false
var collection_progress: Node2D = null
var nearby_player: Node2D = null
var last_gather_press_time := 0.0
const GATHER_COOLDOWN := 0.2  # Small cooldown to prevent double-presses

func _ready() -> void:
	add_to_group("ground_items")
	add_to_group("resources")  # Also add to resources group so NPCs can find them
	if ResourceIndex:
		ResourceIndex.register(self)
	_setup_visuals()
	_setup_collision()
	_setup_collection_progress()
	
	# Enable monitoring for body detection
	monitoring = true
	monitorable = false  # Ground items don't need to be detected by other areas
	
	# Connect signals
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# Manual z_index by sprite foot (draw_order.md)
	if sprite:
		sprite.z_as_relative = false
		YSortUtils.update_draw_order(sprite, self)

func _setup_visuals() -> void:
	# Ensure sprite exists
	if not sprite:
		sprite = get_node_or_null("Sprite")
		if not sprite:
			sprite = Sprite2D.new()
			sprite.name = "Sprite"
			add_child(sprite)
	
	var sprite_path := ""
	match item_type:
		ResourceData.ResourceType.STONE:
			sprite_path = "res://assets/sprites/stone.png"
		ResourceData.ResourceType.WOOD:
			sprite_path = "res://assets/sprites/wood.png"
		ResourceData.ResourceType.MUSHROOM:
			var mush_paths: Array[String] = [
				"res://assets/sprites/mushroom.png",
				"res://assets/sprites/mushroom2.png"
			]
			sprite_path = mush_paths[randi() % mush_paths.size()]
		_:
			return  # Not a valid ground item type
	
	if sprite_path != "":
		var loaded_texture: Resource = load(sprite_path)
		if loaded_texture is Texture2D:
			var tex: Texture2D = loaded_texture as Texture2D
			sprite.texture = tex
			sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			sprite.scale = Vector2(2.0 / 3.0, 2.0 / 3.0) if item_type == ResourceData.ResourceType.MUSHROOM else Vector2.ONE
			sprite.centered = true
			sprite.position = YSortUtils.get_grass_sprite_position_for_texture(tex)
			sprite.visible = true

func _setup_collision() -> void:
	# Check if collision already exists
	var existing_collision := get_node_or_null("CollisionShape2D")
	if existing_collision:
		collision = existing_collision
		return
	
	collision = CollisionShape2D.new()
	collision.name = "CollisionShape2D"
	var shape := CircleShape2D.new()
	shape.radius = 32.0  # Interaction range
	collision.shape = shape
	add_child(collision)

func _setup_collection_progress() -> void:
	var progress_node := Node2D.new()
	progress_node.set_script(CollectionProgressScript)
	collection_progress = progress_node
	
	if collection_progress:
		collection_progress.set("collection_time", collection_time)
		# Position above the item
		var offset_y: float = -40.0
		if sprite and sprite.texture:
			offset_y = -sprite.texture.get_height() / 2.0 - 40.0
		collection_progress.position = Vector2(0, offset_y)
		collection_progress.z_as_relative = false
		collection_progress.z_index = YSortUtils.Z_ABOVE_WORLD  # Above Y-sorted sprite
		add_child(collection_progress)
		collection_progress.visible = false

func _exit_tree() -> void:
	var main_node := get_tree().get_first_node_in_group("main")
	if main_node and main_node.get("active_collection_resource") == self:
		main_node.active_collection_resource = null
	if ResourceIndex:
		ResourceIndex.unregister(self)

func _on_body_entered(body: Node2D) -> void:
	if is_picked_up:
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

func _process(_delta: float) -> void:
	if is_picked_up:
		return
	
	# Check for player gathering (SPACE key)
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
	elif is_collecting:
		# Player moved away, stop collection
		_stop_collection()

func _collect_one_item() -> void:
	# This should already be the active resource, but double-check
	var main := get_tree().get_first_node_in_group("main")
	if main and main.active_collection_resource != self:
		print("Not the active resource, cannot collect")
		return  # Not the active resource, don't collect
	
	# Start collection progress visual — use the same texture as the world sprite when set (mushroom1 vs mushroom2, etc.)
	if collection_progress:
		var icon: Texture2D = null
		if sprite and sprite.texture:
			icon = sprite.texture
		else:
			var icon_path: String = ResourceData.get_resource_icon_path(item_type)
			if icon_path != "":
				icon = load(icon_path) as Texture2D
		collection_progress.start_collection(icon)
		collection_progress.collection_time = collection_time
	
	# Wait for collection time, then give item
	is_collecting = true
	var timer := get_tree().create_timer(collection_time)
	timer.timeout.connect(func(): _finish_collection())

func _finish_collection() -> void:
	# Collection complete, give item to player
	var main := get_tree().get_first_node_in_group("main")
	if not main:
		return
	
	# Give exactly 1 item
	if main and main.has_method("add_to_inventory"):
		main.add_to_inventory(item_type, 1)
	
	# Stop collection visual
	is_collecting = false
	if collection_progress:
		collection_progress.stop_collection()
	
	# Make sprite disappear and remove from world
	is_picked_up = true
	sprite.visible = false
	if main.active_collection_resource == self:
		main.active_collection_resource = null
	queue_free()
	print("Player gathered %s" % ResourceData.get_resource_name(item_type))

func _stop_collection() -> void:
	is_collecting = false
	if collection_progress:
		collection_progress.stop_collection()

# NPC interaction methods
func is_harvestable() -> bool:
	return (
		item_type == ResourceData.ResourceType.STONE
		or item_type == ResourceData.ResourceType.WOOD
		or item_type == ResourceData.ResourceType.MUSHROOM
	)

func harvest() -> int:
	# NPCs harvest ground items, returns yield amount
	# Note: The NPC gather_state handles the timer and progress display
	# This method is called AFTER the timer completes, so we just remove the item
	
	# Make sprite disappear and remove from world
	is_picked_up = true
	sprite.visible = false
	queue_free()
	
	return 1  # Ground items give 1 item
