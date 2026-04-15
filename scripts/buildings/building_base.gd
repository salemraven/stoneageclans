extends Node2D
class_name BuildingBase

# Task classes for generate_job() - preloaded at parse time
const PickUpTaskScript = preload("res://scripts/ai/tasks/pick_up_task.gd")
const MoveToTaskScript = preload("res://scripts/ai/tasks/move_to_task.gd")
const DropOffTaskScript = preload("res://scripts/ai/tasks/drop_off_task.gd")
const OccupyTaskScript = preload("res://scripts/ai/tasks/occupy_task.gd")
const JobScript = preload("res://scripts/ai/jobs/job.gd")

# Base class for all buildings
# Similar structure to LandClaim

@export var building_type: ResourceData.ResourceType = ResourceData.ResourceType.LIVING_HUT
@export var clan_name: String = ""  # Which clan owns this building
@export var player_owned: bool = false  # True if player owns this building

var sprite: Sprite2D = null
var inventory: InventoryData = null  # All buildings have inventory
var land_claim: LandClaim = null  # Reference to the land claim this building belongs to
var woman_slots: Array = []  # Array of Node (women occupying)
var animal_slots: Array = []  # Array of Node (sheep or goats)
var animal_slot_reserved_by: Array = []  # Per-slot reservation for OccupationSystem
var requires_woman: bool = false  # Whether this building needs a woman to operate
var is_active: bool = false  # Whether building is turned on/active (default off)
var job_reserved_by: Node = null  # NPC that has reserved a production job (prevents multiple NPCs pulling same job)
var transport_reserved_by: Node = null  # NPC that has reserved a transport job (prevents multiple NPCs transporting same bread)

# Last reason generate_job returned null (for diagnostics)
var _last_generate_job_reason: String = ""

# Building health and decay system
var max_health: float = 100.0
var current_health: float = 100.0
var is_decaying: bool = false
var decay_rate: float = 2.0  # Health lost per second (default, varies by building type)
var health_bar: Control = null  # Health bar UI
var is_raidable: bool = false  # Whether building inventory can be raided (clan died)

# OPTIMIZATION: Throttle health bar updates during decay
var _health_bar_update_frame: int = 0
const HEALTH_BAR_UPDATE_INTERVAL: int = 5  # Update every 5 frames (~12 times per second at 60fps)
const FARM_DAIRY_START_FIBER: int = 5  # Enables occupy-only job when land claim has no fiber

# Oven cooking animation (3x4 sprite sheet, 12 frames, loops while producing)
var _cook_sprite: Sprite2D = null
var _cook_sheet: Texture2D = null
var _cook_frame_width: int = 0
var _cook_frame_height: int = 0
var _cook_frame_timer: float = 0.0
var _cook_frame_index: int = 0
const COOK_COLS: int = 3
const COOK_ROWS: int = 4
const COOK_FRAME_COUNT: int = 11  # 11 frames in 3x4 grid
const COOK_FRAME_DURATION: float = 0.12  # ~8 fps for 12-frame loop
const COOK_DISTANCE: float = 22.0  # Fixed distance from oven center

func _ready() -> void:
	# Initialize slot arrays based on building type
	_init_slots()
	_setup_visuals()
	_setup_collision()
	
	# Create inventory (6 slots, stacking enabled for buildings)
	if not inventory:
		inventory = InventoryData.new(6, true, 999)  # 6 slots, stacking enabled, max stack 999
	
	# Add to group for easy finding
	add_to_group("buildings")
	
	# Handle production building setup
	if building_type == ResourceData.ResourceType.OVEN:
		_setup_oven()
	elif building_type == ResourceData.ResourceType.FARM:
		_setup_farm()
	elif building_type == ResourceData.ResourceType.DAIRY_FARM:
		_setup_dairy()
	elif building_type == ResourceData.ResourceType.LIVING_HUT:
		_setup_living_hut()
	
	# Farm/Dairy: use correct empty sprite (farm.png/dairy.png), not icon (farm1.png)
	if building_type in [ResourceData.ResourceType.FARM, ResourceData.ResourceType.DAIRY_FARM]:
		_update_building_sprite()
	
	# Manual z_index by sprite foot + offset so player stays in front until past building
	if sprite:
		sprite.z_as_relative = false
		YSortUtils.update_building_draw_order(sprite, self)
	
	# Setup health bar
	_setup_health_bar()
	
	# Set decay rate based on building type (land claim is slowest)
	_set_decay_rate()
	
	# Enable processing for decay
	set_process(true)

# Load task scripts at runtime (avoids compile-time dependency issues)
func _init_slots() -> void:
	var w_count := get_woman_slot_count()
	var a_count := get_animal_slot_count()
	woman_slots.resize(w_count)
	woman_slots.fill(null)
	animal_slots.resize(a_count)
	animal_slots.fill(null)
	animal_slot_reserved_by.resize(a_count)
	animal_slot_reserved_by.fill(null)

func get_woman_slot_count() -> int:
	match building_type:
		ResourceData.ResourceType.LIVING_HUT: return 1
		ResourceData.ResourceType.OVEN: return 1
		ResourceData.ResourceType.FARM: return 2
		ResourceData.ResourceType.DAIRY_FARM: return 2
	return 0

func get_animal_slot_count() -> int:
	match building_type:
		ResourceData.ResourceType.FARM: return 3  # sheep
		ResourceData.ResourceType.DAIRY_FARM: return 3  # goats
	return 0

func get_animal_type_for_building() -> String:
	match building_type:
		ResourceData.ResourceType.FARM: return "sheep"
		ResourceData.ResourceType.DAIRY_FARM: return "goat"
	return ""

func _setup_health_bar() -> void:
	"""Create health bar UI for building"""
	# Create health bar container (use min size to avoid anchor/size override warning)
	health_bar = Control.new()
	health_bar.name = "HealthBar"
	health_bar.set_anchors_preset(Control.PRESET_CENTER_TOP)
	health_bar.position = Vector2(-40, -60)  # Above building
	health_bar.custom_minimum_size = Vector2(80, 8)
	health_bar.size = Vector2(80, 8)
	health_bar.visible = false  # Hidden until damaged/decaying
	add_child(health_bar)
	
	# Background bar (red) - no explicit size to avoid anchor override warning
	var bg_bar = ColorRect.new()
	bg_bar.name = "Background"
	bg_bar.color = Color(0.3, 0.0, 0.0, 0.8)
	bg_bar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	health_bar.add_child(bg_bar)
	
	# Health bar (green) - top-left anchored, size updated in _update_health_bar
	var health_fill = ColorRect.new()
	health_fill.name = "HealthFill"
	health_fill.color = Color(0.0, 1.0, 0.0, 0.8)
	health_fill.set_anchors_preset(Control.PRESET_TOP_LEFT)
	health_fill.position = Vector2(0, 0)
	health_fill.size = Vector2(80, 8)
	health_bar.add_child(health_fill)

func _set_decay_rate() -> void:
	"""Set decay rate based on building type (land claim is slowest)"""
	# Note: LandClaim is a separate class, not a ResourceType
	# For BuildingBase buildings, set decay rates
	match building_type:
		ResourceData.ResourceType.OVEN:
			decay_rate = 2.0
		ResourceData.ResourceType.FARM:
			decay_rate = 2.0
		ResourceData.ResourceType.DAIRY_FARM:
			decay_rate = 2.0
		ResourceData.ResourceType.LIVING_HUT:
			decay_rate = 1.5
		_:
			decay_rate = 2.0

func _update_health_bar() -> void:
	"""Update health bar visual"""
	if not health_bar:
		return
	
	var health_fill = health_bar.get_node_or_null("HealthFill")
	if not health_fill:
		return
	
	# Show health bar if damaged or decaying
	if current_health < max_health or is_decaying:
		health_bar.visible = true
	else:
		health_bar.visible = false
	
	# Update health bar width
	var health_percent: float = current_health / max_health
	health_fill.size.x = 80.0 * health_percent
	
	# Change color based on health
	if health_percent > 0.6:
		health_fill.color = Color(0.0, 1.0, 0.0, 0.8)  # Green
	elif health_percent > 0.3:
		health_fill.color = Color(1.0, 1.0, 0.0, 0.8)  # Yellow
	else:
		health_fill.color = Color(1.0, 0.0, 0.0, 0.8)  # Red

func start_decay() -> void:
	"""Start building decay when clan dies"""
	if is_decaying:
		return  # Already decaying
	
	is_decaying = true
	is_raidable = true  # Building inventory can now be raided
	print("💀 Building %s started decaying (raidable: %s)" % [ResourceData.get_resource_name(building_type), is_raidable])

func start_fast_decay() -> void:
	"""Switch to fast decay when land claim is destroyed (Phase 2)."""
	if not is_decaying:
		start_decay()
	decay_rate = 5.0

func take_damage(damage: float) -> void:
	"""Take damage from player/NPC attacks"""
	current_health -= damage
	current_health = max(0.0, current_health)
	_update_health_bar()
	# Building attacked = raid - trigger emergency defend so clansmen return
	if not is_decaying:
		var claim: LandClaim = _find_land_claim()
		if claim and is_instance_valid(claim) and not claim.is_decaying:
			claim.report_raid()
	if current_health <= 0.0:
		_destroy_building()

func _process(delta: float) -> void:
	"""Process building decay and oven cooking animation"""
	if building_type == ResourceData.ResourceType.OVEN and _cook_sprite:
		_update_oven_cook_animation(delta)
	
	if not is_decaying:
		return
	
	# Reduce health over time
	current_health -= decay_rate * delta
	current_health = max(0.0, current_health)
	
	# Visual feedback: make building darker as it decays
	if sprite:
		var health_percent: float = current_health / max_health
		sprite.modulate = Color(health_percent, health_percent, health_percent, 1.0)
	
	# OPTIMIZATION: Throttle health bar updates (update every N frames instead of every frame)
	_health_bar_update_frame += 1
	if _health_bar_update_frame >= HEALTH_BAR_UPDATE_INTERVAL:
		_health_bar_update_frame = 0
		_update_health_bar()
	
	# If health reaches 0, destroy the building
	if current_health <= 0.0:
		_destroy_building()

func _destroy_building() -> void:
	"""Destroy the building when health reaches 0"""
	print("💀 Building %s for clan %s has been destroyed" % [ResourceData.get_resource_name(building_type), clan_name])
	if OccupationSystem:
		OccupationSystem.notify_building_destroyed(self)
	if ClaimBuildingIndex:
		ClaimBuildingIndex.unregister_building(self)
	# Inventory despawns with building (no drop)
	# Remove the building
	queue_free()

func _drop_inventory_items(drop_position: Vector2) -> void:
	"""Drop all inventory items as ground items when building is destroyed"""
	if not inventory:
		return
	
	var main = get_tree().get_first_node_in_group("main")
	if not main:
		return
	
	# Get ground item script
	var ground_item_script = load("res://scripts/ground_item.gd") as GDScript
	if not ground_item_script:
		print("⚠️ Failed to load ground_item.gd script")
		return
	
	# Drop each item in inventory
	for i in range(inventory.slot_count):
		var slot = inventory.slots[i]
		if slot == null:
			continue
		
		var item_type = slot.get("item_type")
		var count = slot.get("count", 0)
		
		if item_type != null and count > 0:
			# Spawn ground items in a small radius around the building
			var angle = (TAU * i) / max(1, inventory.slot_count)  # Spread items in a circle
			var offset = Vector2(cos(angle), sin(angle)) * 32.0  # 32px radius
			var item_pos = drop_position + offset
			
			# Create ground item
			var ground_item: Node2D = ground_item_script.new()
			ground_item.set("item_type", item_type)
			ground_item.set("count", count)
			ground_item.global_position = item_pos
			
			# Add to resources container
			var world_objects = main.get_node_or_null("WorldObjects")
			if world_objects:
				world_objects.add_child(ground_item)
				print("💀 Dropped %d %s from destroyed building" % [count, item_type])

func _setup_visuals() -> void:
	if not is_instance_valid(self):
		print("ERROR: Building is not valid in _setup_visuals()")
		return
	
	sprite = get_node_or_null("Sprite") as Sprite2D
	if not sprite:
		# Create sprite node if it doesn't exist
		sprite = Sprite2D.new()
		sprite.name = "Sprite"
		add_child(sprite)
	
	# Ensure sprite is visible
	if sprite:
		sprite.visible = true
	
	# Only setup if building_type is valid
	if building_type == ResourceData.ResourceType.NONE:
		print("WARNING: Building type is NONE, skipping sprite setup")
		return
	
	# Load building sprite based on type
	var icon_path := ResourceData.get_resource_icon_path(building_type)
	if icon_path == "":
		print("WARNING: No icon path for building type: %s" % ResourceData.get_resource_name(building_type))
		return
	
	var texture := load(icon_path) as Texture2D
	if texture:
		if sprite and is_instance_valid(sprite):
			sprite.texture = texture
			sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			sprite.scale = Vector2.ONE  # Native display
			sprite.position = Vector2.ZERO  # Centered on node
			sprite.visible = true  # Ensure sprite is visible
	else:
		print("ERROR: Could not load building texture: %s for building type: %s" % [icon_path, ResourceData.get_resource_name(building_type)])
		# Don't return - continue with no texture rather than crashing
		# The sprite will just be invisible, which is better than crashing

func _setup_collision() -> void:
	if not is_instance_valid(self):
		print("ERROR: Building is not valid in _setup_collision()")
		return
	
	# Check if collision area already exists (avoid duplicates)
	if has_node("InteractionArea"):
		return
	
	# Create Area2D for clicking/interaction (like LandClaim)
	var collision_area := Area2D.new()
	collision_area.name = "InteractionArea"
	collision_area.input_pickable = true  # REQUIRED in Godot 4 for input events
	
	var collision_shape := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 64.0  # Clickable area (native)
	collision_shape.shape = shape
	collision_area.add_child(collision_shape)
	
	# Enable input detection - connect signal before adding to tree (like LandClaim)
	# Note: input_pickable must be set BEFORE connecting the signal
	if collision_area.has_signal("input_event"):
		var result = collision_area.input_event.connect(_on_input_event)
		if result != OK:
			print("ERROR: Failed to connect input_event signal for building (error code: %d)" % result)
	else:
		print("WARNING: Area2D does not have input_event signal - input detection disabled")
	
	add_child(collision_area)

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		print("Building clicked: %s" % ResourceData.get_resource_name(building_type))
		_on_clicked()

func _on_clicked() -> void:
	var main: Node = get_tree().get_first_node_in_group("main")
	if main and main.has_method("_on_building_clicked"):
		main._on_building_clicked(self)

func is_occupied() -> bool:
	for i in woman_slots.size():
		var n = woman_slots[i]
		if n != null and is_instance_valid(n):
			return true
	return false

## Backward compat: first occupied woman slot (for code that expected single occupant)
func get_primary_occupant() -> Node:
	if woman_slots.size() > 0 and woman_slots[0] != null and is_instance_valid(woman_slots[0]):
		return woman_slots[0]
	return null

func set_occupied(npc: Node) -> void:
	# Find first empty woman slot
	var slot_idx := -1
	for i in woman_slots.size():
		if woman_slots[i] == null or not is_instance_valid(woman_slots[i]):
			slot_idx = i
			break
	if slot_idx < 0:
		return
	set_occupant(slot_idx, npc, true)

func set_occupant(slot_index: int, npc: Node, is_woman: bool) -> void:
	var slots := woman_slots if is_woman else animal_slots
	if slot_index < 0 or slot_index >= slots.size():
		return
	OccupationDiagLogger.log("SET_OCCUPANT", {"npc": str(npc.get("npc_name")) if npc else "?", "type": str(npc.get("npc_type")) if npc else "?", "slot": slot_index, "is_woman": is_woman, "building": name})
	slots[slot_index] = npc
	job_reserved_by = null
	if npc and is_instance_valid(npc):
		var npc_sprite = npc.get_node_or_null("Sprite")
		if npc_sprite:
			npc_sprite.visible = false
		if is_woman and not is_active:
			set_active(true)
		if is_woman:
			_notify_occupation_changed()
		else:
			_update_building_sprite()

func clear_occupant(slot_index: int, is_woman: bool) -> void:
	var slots := woman_slots if is_woman else animal_slots
	if slot_index < 0 or slot_index >= slots.size():
		return
	var npc_leaving = slots[slot_index]
	slots[slot_index] = null
	if npc_leaving and is_instance_valid(npc_leaving):
		var npc_name: String = str(npc_leaving.get("npc_name")) if npc_leaving else "?"
		var npc_type: String = str(npc_leaving.get("npc_type")) if npc_leaving else "?"
		OccupationDiagLogger.log("CLEAR_OCCUPANT", {"npc": npc_name, "type": npc_type, "slot": slot_index, "is_woman": is_woman, "building": name})
		var claim = _find_land_claim()
		if claim and claim.has_method("release_items"):
			claim.release_items(npc_leaving)
		var npc_sprite = npc_leaving.get_node_or_null("Sprite")
		if npc_sprite:
			npc_sprite.visible = true
	if is_woman:
		job_reserved_by = null
		transport_reserved_by = null
		if not is_occupied() and is_active:
			set_active(false)
			var production_component = get_node_or_null("ProductionComponent")
			if production_component:
				if "craft_timer" in production_component:
					production_component.craft_timer = 0.0
				if "is_crafting" in production_component:
					production_component.is_crafting = false
		_notify_occupation_changed()
	else:
		_update_building_sprite()

## OccupationSystem: per-slot reservation (slot-index bound)
func reserve_slot(slot_index: int, is_woman: bool, npc: Node) -> bool:
	if is_woman:
		# Woman slots: no physical reservation; OccupationSystem holds ref
		return true
	if slot_index < 0 or slot_index >= animal_slot_reserved_by.size():
		return false
	if animal_slot_reserved_by[slot_index] != null:
		return false
	if animal_slots[slot_index] != null and is_instance_valid(animal_slots[slot_index]):
		return false
	var filled := 0
	for n in animal_slots:
		if n != null and is_instance_valid(n):
			filled += 1
	var reserved_count := 0
	for r in animal_slot_reserved_by:
		if r != null:
			reserved_count += 1
	if filled + reserved_count >= animal_slots.size():
		return false
	animal_slot_reserved_by[slot_index] = npc
	return true

func unreserve_slot(slot_index: int, is_woman: bool) -> void:
	if is_woman:
		return
	if slot_index >= 0 and slot_index < animal_slot_reserved_by.size():
		animal_slot_reserved_by[slot_index] = null

## Building wrappers for Phase 7 compatibility
func get_occupant(slot_index: int, is_woman: bool) -> Node:
	var slots := woman_slots if is_woman else animal_slots
	if slot_index < 0 or slot_index >= slots.size():
		return null
	var n = slots[slot_index]
	if n != null and is_instance_valid(n):
		return n
	return null

func get_occupants(is_woman: bool) -> Array:
	var slots := woman_slots if is_woman else animal_slots
	var out: Array = []
	for n in slots:
		if n != null and is_instance_valid(n):
			out.append(n)
	return out

func has_animal_type(want_type: String) -> bool:
	for n in animal_slots:
		if n != null and is_instance_valid(n):
			var t: String = n.get("npc_type") as String if n.get("npc_type") != null else ""
			if t == want_type:
				return true
	return false

func clear_occupant_for_npc(npc: Node) -> void:
	for i in woman_slots.size():
		if woman_slots[i] == npc:
			clear_occupant(i, true)
			return
	for i in animal_slots.size():
		if animal_slots[i] == npc:
			clear_occupant(i, false)
			return

func clear_occupied(npc: Node = null) -> void:
	if npc != null:
		clear_occupant_for_npc(npc)
		return
	# Backward compat: clear first woman slot (Oven)
	if woman_slots.size() > 0:
		clear_occupant(0, true)

func _notify_occupation_changed() -> void:
	if not is_inside_tree():
		return  # Avoid engine ERROR: get_tree() when tree is null (e.g. NPC exit_tree → unassign during teardown)
	var tree = get_tree()
	if not tree:
		return
	var building_ui = tree.get_first_node_in_group("building_inventory_ui")
	if building_ui and building_ui.has_method("_update_occupation_slots"):
		building_ui._update_occupation_slots()
	elif building_ui and building_ui.has_method("_update_occupation_slot"):
		building_ui._update_occupation_slot()

func _setup_oven() -> void:
	requires_woman = true
	if has_node("ProductionComponent"):
		return
	var production_component = ProductionComponent.new(self, ProductionConfig.get_oven_recipe())
	production_component.name = "ProductionComponent"
	add_child(production_component)
	# Cooking animation sprite (ovencook.png 3x4 sheet)
	_setup_oven_cook_animation()

func _setup_farm() -> void:
	requires_woman = true
	if has_node("ProductionComponent"):
		return
	var production_component = ProductionComponent.new(self, ProductionConfig.get_farm_recipe())
	production_component.name = "ProductionComponent"
	add_child(production_component)
	# Playtest: farm spawns empty (no starting FIBER)

func _setup_dairy() -> void:
	requires_woman = true
	if has_node("ProductionComponent"):
		return
	var production_component = ProductionComponent.new(self, ProductionConfig.get_dairy_recipe())
	production_component.name = "ProductionComponent"
	add_child(production_component)
	# Playtest: dairy spawns empty (no starting FIBER)

func _setup_living_hut() -> void:
	requires_woman = true

func _setup_oven_cook_animation() -> void:
	"""Create cooking animation sprite next to oven. Random angle, fixed distance."""
	_cook_sheet = AssetRegistry.get_oven_cook_sheet()
	if not _cook_sheet:
		return
	_cook_frame_width = int(_cook_sheet.get_width() / float(COOK_COLS))
	_cook_frame_height = int(_cook_sheet.get_height() / float(COOK_ROWS))
	if _cook_frame_width <= 0 or _cook_frame_height <= 0:
		return
	_cook_sprite = Sprite2D.new()
	_cook_sprite.name = "OvenCookAnimation"
	_cook_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_cook_sprite.scale = Vector2(WalkAnimation.WOMAN_SCALE, WalkAnimation.WOMAN_SCALE)  # Match woman display size
	_cook_sprite.visible = false
	# Random angle, fixed distance – each oven gets different position
	var angle: float = randf() * TAU
	_cook_sprite.position = Vector2(cos(angle), sin(angle)) * COOK_DISTANCE
	# Align with oven sprite foot (oven Sprite is at 0,-32)
	_cook_sprite.position.y -= 32
	_cook_sprite.z_index = 1  # In front of oven
	add_child(_cook_sprite)

func _update_oven_cook_animation(delta: float) -> void:
	"""Show and animate cooking sprite while producing; hide when idle."""
	var prod = get_node_or_null("ProductionComponent")
	var is_producing: bool = prod and prod.get("is_crafting") == true
	if not _cook_sprite or not _cook_sheet:
		return
	if is_producing:
		_cook_sprite.visible = true
		_cook_frame_timer += delta
		if _cook_frame_timer >= COOK_FRAME_DURATION:
			_cook_frame_timer = 0.0
			_cook_frame_index = (_cook_frame_index + 1) % COOK_FRAME_COUNT
		var col := _cook_frame_index % COOK_COLS
		var row := int(_cook_frame_index / COOK_COLS)
		var atlas := AtlasTexture.new()
		atlas.atlas = _cook_sheet
		atlas.region = Rect2(col * _cook_frame_width, row * _cook_frame_height, _cook_frame_width, _cook_frame_height)
		_cook_sprite.texture = atlas
	else:
		_cook_sprite.visible = false
		_cook_frame_timer = 0.0
		_cook_frame_index = 0

func _update_building_sprite() -> void:
	if not sprite or not is_instance_valid(sprite):
		return
	var animal_count := 0
	for n in animal_slots:
		if n != null and is_instance_valid(n):
			animal_count += 1
	# Sprite by filled count (1=farm1/dairy1, 2=farm2/dairy2, 3=farm3/dairy3). If dairy1 shows 3 goats, asset naming may be inverted.
	var idx := clampi(animal_count, 1, 3) if animal_count > 0 else 0
	match building_type:
		ResourceData.ResourceType.FARM:
			var path: String
			if animal_count == 0:
				path = "res://assets/sprites/farm.png"
			else:
				path = "res://assets/sprites/farm%d.png" % idx
			var tex := load(path) as Texture2D
			if tex:
				sprite.texture = tex
				sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
				YSortUtils.update_building_draw_order(sprite, self)
		ResourceData.ResourceType.DAIRY_FARM:
			var path: String
			if animal_count == 0:
				path = "res://assets/sprites/dairy.png"
			else:
				path = "res://assets/sprites/dairy%d.png" % idx
			var tex := load(path) as Texture2D
			if not tex and animal_count == 2:
				tex = load("res://assets/sprites/dairy1.png") as Texture2D
			if tex:
				sprite.texture = tex
				sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
				YSortUtils.update_building_draw_order(sprite, self)

func set_active(active: bool) -> void:
	is_active = active
	if not active:
		# Clear all woman slots when turning off; keep animal slots
		for i in woman_slots.size():
			if woman_slots[i] != null and is_instance_valid(woman_slots[i]):
				var npc = woman_slots[i]
				woman_slots[i] = null
				job_reserved_by = null
				transport_reserved_by = null
				var npc_sprite = npc.get_node_or_null("Sprite")
				if npc_sprite:
					npc_sprite.visible = true
				var claim = _find_land_claim()
				if claim and claim.has_method("release_items"):
					claim.release_items(npc)
		_notify_occupation_changed()

# Task System - Step 16: Check if building has available work (cheap, non-destructive)
# Used by FSM for priority/can_enter checks. Does NOT check resources/occupancy.
func has_available_job(worker: NPCBase) -> bool:
	if building_type != ResourceData.ResourceType.OVEN and building_type != ResourceData.ResourceType.FARM and building_type != ResourceData.ResourceType.DAIRY_FARM:
		return false
	
	# Check if worker is in the same clan (case-insensitive)
	if worker.get_clan_name().to_upper() != clan_name.to_upper():
		return false
	
	# Get production component
	var production_component = get_node_or_null("ProductionComponent")
	if not production_component:
		return false
	
	# Check if recipe exists
	if not "recipe" in production_component:
		return false
	
	var recipe_value = production_component.get("recipe")
	if not recipe_value is Dictionary:
		return false
	
	var recipe: Dictionary = recipe_value
	if recipe.is_empty():
		return false
	
	# If building is occupied, check if there's bread to transport
	if is_occupied():
		var output_type: ResourceData.ResourceType = recipe.get("output", {}).get("type", ResourceData.ResourceType.NONE)
		if inventory and inventory.has_item(output_type, 1):
			# EDGE CASE: Only return true if no one is already transporting this bread
			if transport_reserved_by and is_instance_valid(transport_reserved_by):
				return false  # Someone is already transporting
			return true  # Has bread to transport and no one is transporting it
		return false  # Occupied but no bread to transport
	
	# If not occupied, check if we can generate a production job (has inputs, space for output)
	return true  # Will be checked in generate_job()

# Task System - Step 16: Generate job for worker (actual job creation)
# Used ONLY when NPC actually enters work_at_building state.
# Returns a Job if this building has work available, null otherwise
func generate_job(worker: NPCBase) -> Job:
	_last_generate_job_reason = ""
	# First do cheap availability check
	if not has_available_job(worker):
		_last_generate_job_reason = "has_available_job false"
		return null
	
	# Get production component and recipe
	var production_component = get_node_or_null("ProductionComponent")
	if not production_component:
		_last_generate_job_reason = "no ProductionComponent"
		return null
	
	var recipe: Dictionary = {}
	if "recipe" in production_component:
		var recipe_value = production_component.get("recipe")
		if recipe_value is Dictionary:
			recipe = recipe_value
	if recipe.is_empty():
		_last_generate_job_reason = "empty recipe"
		return null
	
	# If building is occupied, generate transport job (pick up bread and deliver to land claim)
	if is_occupied():
		var transport_job = _generate_transport_job(worker, recipe)
		# If transport job was generated, return it; otherwise fall through to check for production job
		if transport_job:
			return transport_job
		# If no transport job (already reserved or no bread), return null
		_last_generate_job_reason = "occupied, no transport job"
		return null
	
	# If not occupied, generate production job (bring materials, occupy, produce)
	# Check if job is already reserved by another NPC
	if job_reserved_by and is_instance_valid(job_reserved_by) and job_reserved_by != worker:
		_last_generate_job_reason = "job reserved by another"
		return null
	
	# Find land claim for this building (don't reserve job until we know we can create it)
	var claim: LandClaim = _find_land_claim()
	if not claim:
		_last_generate_job_reason = "no land claim"
		return null
	
	# Check if land claim has required inputs
	var inputs: Array = recipe.get("inputs", [])
	var has_all_inputs: bool = true
	
	for input in inputs:
		var input_type: ResourceData.ResourceType = input.get("type", ResourceData.ResourceType.NONE)
		var input_quantity: int = input.get("quantity", 1)
		# Women: require only recipe minimum (1) so job can be created with 1+ of each; they bring min(5, available)
		var required_count: int = input_quantity
		if worker and worker.get("npc_type") == "woman":
			required_count = 1
		if not claim.inventory:
			has_all_inputs = false
			break
		
		var actual_count = claim.inventory.get_count(input_type)
		var reserved_count = claim.get_reserved_count(input_type) if claim.has_method("get_reserved_count") else 0
		var available_count = actual_count - reserved_count
		var has_item_result = available_count >= required_count
		
		if not has_item_result:
			has_all_inputs = false
			break
	
	if not has_all_inputs:
		# Land claim has no inputs - allow job when building already has materials (occupy → produce → transport output)
		# Farm/Dairy need animals - skip occupy-only or OccupyTask will fail on _can_craft()
		if building_type == ResourceData.ResourceType.FARM and not has_animal_type("sheep"):
			_last_generate_job_reason = "missing inputs; farm needs sheep"
			return null
		if building_type == ResourceData.ResourceType.DAIRY_FARM and not has_animal_type("goat"):
			_last_generate_job_reason = "missing inputs; dairy needs goat"
			return null
		if _building_has_recipe_inputs(recipe):
			var short_job = _generate_occupy_only_job(worker, recipe, claim)
			if short_job:
				job_reserved_by = worker  # Reserve before returning
				return short_job
		_last_generate_job_reason = "missing inputs"
		return null
	
	# Check if building has space for output
	var output = recipe.get("output", {})
	var output_type: ResourceData.ResourceType = output.get("type", ResourceData.ResourceType.NONE)
	if not inventory:
		_last_generate_job_reason = "no inventory"
		return null
	if not inventory.has_space():
		# Check if we can stack output
		if inventory.can_stack:
			if inventory.get_count(output_type) >= inventory.max_stack:
				_last_generate_job_reason = "output stack full"
				return null  # Output stack is full
		else:
			_last_generate_job_reason = "no output space"
			return null  # No space
	
	# Reserve job only after all validation passes (prevents building stuck when land claim lacks inputs)
	job_reserved_by = worker
	
	# Build transport quantities and reserve items (prevents PickUpTask race when multiple buildings share claim)
	var input_transport_quantities: Array[int] = []
	var items_to_reserve: Dictionary = {}  # ResourceType (int): amount
	for input in inputs:
		var input_type: ResourceData.ResourceType = input.get("type", ResourceData.ResourceType.NONE)
		var input_quantity: int = input.get("quantity", 1)
		var transport_quantity: int = input_quantity
		if worker and worker.get("npc_type") == "woman":
			var avail: int = claim.inventory.get_count(input_type) - (claim.get_reserved_count(input_type) if claim.has_method("get_reserved_count") else 0)
			transport_quantity = min(5, avail)
		input_transport_quantities.append(transport_quantity)
		if transport_quantity > 0:
			items_to_reserve[int(input_type)] = items_to_reserve.get(int(input_type), 0) + transport_quantity
	
	# Reserve items before creating job (another building's job can't use them now)
	if not items_to_reserve.is_empty() and claim.has_method("reserve_items"):
		if not claim.reserve_items(worker, items_to_reserve):
			job_reserved_by = null
			_last_generate_job_reason = "reserve_items failed"
			return null
	
	# Create job: PickUp inputs → MoveTo building → DropOff inputs → Occupy → PickUp output → MoveTo land claim → DropOff output
	var tasks: Array = []
	for i in range(inputs.size()):
		var input = inputs[i]
		var input_type: ResourceData.ResourceType = input.get("type", ResourceData.ResourceType.NONE)
		var transport_quantity: int = input_transport_quantities[i] if i < input_transport_quantities.size() else input.get("quantity", 1)
		
		# Check if land claim has enough items (after reservation, should always pass)
		if not claim.inventory or transport_quantity <= 0:
			job_reserved_by = null
			_last_generate_job_reason = "no transport quantity"
			if claim.has_method("release_items"):
				claim.release_items(worker)
			return null
		
		# PickUp from land claim (use transport quantity)
		if PickUpTaskScript:
			var pick_up = PickUpTaskScript.new(claim, input_type, transport_quantity)
			tasks.append(pick_up)
		
		# MoveTo building
		if MoveToTaskScript:
			var move_to = MoveToTaskScript.new(global_position, 18.0)  # Walk right up to building before drop-off
			tasks.append(move_to)
		
		# DropOff to building (use stack size)
		if DropOffTaskScript:
			var drop_off = DropOffTaskScript.new(self, input_type, transport_quantity, 20.0)  # Close to building for drop-off
			tasks.append(drop_off)
	
	# Occupy building (wait for production)
	if OccupyTaskScript:
		var occupy = OccupyTaskScript.new(self)
		tasks.append(occupy)
	else:
		UnifiedLogger.log_system("generate_job: OccupyTaskScript is null - OccupyTask will not be added", {"building": clan_name}, UnifiedLogger.Level.ERROR)
	
	# PickUp output from building - amount = what we'll produce (min of input quantities)
	var output_transport_amount: int = output.get("quantity", 1)
	if worker and worker.get("npc_type") == "woman" and input_transport_quantities.size() > 0:
		output_transport_amount = input_transport_quantities.min()
	
	# Output will be produced during OccupyTask; no pre-check needed
	
	# PickUp output from building (after OccupyTask produces)
	if PickUpTaskScript:
		var pick_up_output = PickUpTaskScript.new(self, output_type, output_transport_amount)
		tasks.append(pick_up_output)
	
	# MoveTo land claim
	if MoveToTaskScript:
		var move_to_claim = MoveToTaskScript.new(claim.global_position, 50.0)
		tasks.append(move_to_claim)
	
	# DropOff output to land claim (use stack size for women)
	if DropOffTaskScript:
		var drop_off_output = DropOffTaskScript.new(claim, output_type, output_transport_amount, 50.0)
		tasks.append(drop_off_output)
	
	# Create job with building reference
	var job = null
	if JobScript:
		job = JobScript.new(tasks)
	if job:
		job.building = self
	return job

func get_last_job_failure_reason() -> String:
	"""Return short reason why generate_job last returned null (for diagnostics)."""
	return _last_generate_job_reason

# True if this building's inventory has at least the recipe minimum of each input (so woman can occupy and produce without claim)
func _building_has_recipe_inputs(recipe: Dictionary) -> bool:
	if not inventory:
		return false
	var inputs: Array = recipe.get("inputs", [])
	for input in inputs:
		var input_type: ResourceData.ResourceType = input.get("type", ResourceData.ResourceType.NONE)
		var input_quantity: int = input.get("quantity", 1)
		if not inventory.has_item(input_type, input_quantity):
			return false
	return true

# Short production job when oven already has inputs: Occupy → produce → PickUp output → MoveTo claim → DropOff
func _generate_occupy_only_job(worker: NPCBase, recipe: Dictionary, claim: LandClaim) -> Job:
	var output = recipe.get("output", {})
	var output_type: ResourceData.ResourceType = output.get("type", ResourceData.ResourceType.NONE)
	var output_quantity: int = output.get("quantity", 1)
	if not inventory or not claim or not claim.inventory:
		return null
	if not inventory.has_space() and inventory.get_count(output_type) >= (inventory.max_stack if inventory.can_stack else 999):
		return null
	var tasks: Array = []
	if OccupyTaskScript:
		tasks.append(OccupyTaskScript.new(self))
	if PickUpTaskScript:
		tasks.append(PickUpTaskScript.new(self, output_type, output_quantity))
	if MoveToTaskScript:
		tasks.append(MoveToTaskScript.new(claim.global_position, 50.0))
	if DropOffTaskScript:
		tasks.append(DropOffTaskScript.new(claim, output_type, output_quantity, 50.0))
	var job = JobScript.new(tasks) if JobScript else null
	if job:
		job.building = self
	return job

# Generate transport job: PickUp bread from occupied oven → MoveTo land claim → DropOff bread
func _generate_transport_job(worker: NPCBase, recipe: Dictionary) -> Job:
	# Check if transport job is already reserved by another NPC
	if transport_reserved_by and is_instance_valid(transport_reserved_by) and transport_reserved_by != worker:
		return null  # Another NPC is already transporting
	
	# Check if building has bread to transport
	var output = recipe.get("output", {})
	var output_type: ResourceData.ResourceType = output.get("type", ResourceData.ResourceType.NONE)
	var output_quantity: int = output.get("quantity", 1)
	
	# Women transport min(5, available); others transport recipe quantity
	var transport_amount: int = output_quantity
	if worker and worker.get("npc_type") == "woman":
		var available: int = inventory.get_count(output_type) if inventory else 0
		transport_amount = min(5, available)
	
	# Check if building has enough items to transport
	if not inventory or transport_amount <= 0 or not inventory.has_item(output_type, transport_amount):
		return null  # Not enough items to transport
	
	# Find land claim
	var claim: LandClaim = _find_land_claim()
	if not claim:
		return null
	
	# Check if land claim has space for bread
	if not claim.inventory or not claim.inventory.has_space():
		# Check if we can stack
		if claim.inventory.can_stack:
			if claim.inventory.get_count(output_type) >= claim.inventory.max_stack:
				return null  # Stack is full
		else:
			return null  # No space
	
	# Reserve transport job for this worker
	transport_reserved_by = worker
	
	# Create transport job: PickUp bread → MoveTo land claim → DropOff bread
	var tasks: Array = []
	
	# PickUp bread from oven (use transport_amount, which is 5 for women)
	if PickUpTaskScript:
		var pick_up = PickUpTaskScript.new(self, output_type, transport_amount)
		tasks.append(pick_up)
	
	# MoveTo land claim
	if MoveToTaskScript:
		var move_to = MoveToTaskScript.new(claim.global_position, 50.0)
		tasks.append(move_to)
	
	# DropOff bread to land claim (use transport_amount, which is 5 for women)
	if DropOffTaskScript:
		var drop_off = DropOffTaskScript.new(claim, output_type, transport_amount, 50.0)
		tasks.append(drop_off)
	
	# Create job
	var job = null
	if JobScript:
		job = JobScript.new(tasks)
	if job:
		job.building = self
	return job

# Helper function to find the land claim this building belongs to
func _find_land_claim() -> LandClaim:
	# First check if we have a cached reference
	if land_claim and is_instance_valid(land_claim):
		# DEBUG: Verify cached inventory (only when --debug)
		if DebugConfig and DebugConfig.enable_debug_mode and land_claim.inventory:
			var cached_wood = land_claim.inventory.get_count(ResourceData.ResourceType.WOOD)
			var cached_grain = land_claim.inventory.get_count(ResourceData.ResourceType.GRAIN)
			UnifiedLogger.log_system("_find_land_claim: Using cached land claim, inventory - Wood: %d, Grain: %d" % [cached_wood, cached_grain], {"building": ResourceData.get_resource_name(building_type)}, UnifiedLogger.Level.DEBUG)
		return land_claim
	
	# Find land claim by position and clan name
	if not is_inside_tree():
		return null
	var tree = get_tree()
	if not tree:
		return null  # Node exiting tree (e.g. during scene teardown)
	var land_claims = tree.get_nodes_in_group("land_claims")
	if DebugConfig.enable_debug_mode:
		print("DEBUG _find_land_claim: Building %s (clan: %s, pos: %s) searching %d land claims" % [
			ResourceData.get_resource_name(building_type),
			clan_name,
			global_position,
			land_claims.size()
		])
	
	for claim in land_claims:
		if not is_instance_valid(claim) or not (claim is LandClaim):
			continue
		
		var lc: LandClaim = claim as LandClaim
		
		# Check if same clan (case-insensitive)
		if lc.clan_name.to_upper() != clan_name.to_upper():
			if DebugConfig and DebugConfig.enable_debug_mode:
				UnifiedLogger.log_system("_find_land_claim: Clan mismatch - building: '%s', claim: '%s'" % [clan_name, lc.clan_name], {"building": ResourceData.get_resource_name(building_type)}, UnifiedLogger.Level.DEBUG)
			continue
		
		# Check if building is within land claim radius
		var distance = global_position.distance_to(lc.global_position)
		if DebugConfig and DebugConfig.enable_debug_mode:
			UnifiedLogger.log_system("_find_land_claim: Claim '%s' at distance %.1f, radius: %.1f" % [lc.clan_name, distance, lc.radius], {"building": ResourceData.get_resource_name(building_type)}, UnifiedLogger.Level.DEBUG)
		if distance <= lc.radius:
			land_claim = lc  # Cache for next time
			# DEBUG: Check inventory when found (only when --debug)
			if DebugConfig and DebugConfig.enable_debug_mode:
				if lc.inventory:
					var found_wood = lc.inventory.get_count(ResourceData.ResourceType.WOOD)
					var found_grain = lc.inventory.get_count(ResourceData.ResourceType.GRAIN)
					UnifiedLogger.log_system("_find_land_claim: Found matching land claim! Inventory - Wood: %d, Grain: %d" % [found_wood, found_grain], {"building": ResourceData.get_resource_name(building_type)}, UnifiedLogger.Level.DEBUG)
				else:
					UnifiedLogger.log_system("_find_land_claim: Found matching land claim but NO INVENTORY!", {"building": ResourceData.get_resource_name(building_type)}, UnifiedLogger.Level.DEBUG)
			return lc
	
	if DebugConfig and DebugConfig.enable_debug_mode:
		UnifiedLogger.log_system("_find_land_claim: No matching land claim found", {"building": ResourceData.get_resource_name(building_type)}, UnifiedLogger.Level.DEBUG)
	return null
