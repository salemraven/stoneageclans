extends Node
class_name ProductionComponent

# Handles recipe-based production for buildings
# Manages crafting timers, input consumption, and output creation

var building: BuildingBase = null  # Reference to the building this component is attached to
var recipe: Dictionary = {}  # Recipe definition: {"inputs": [...], "output": {...}, "craft_time": float}
var craft_timer: float = 0.0  # Current crafting progress
var is_crafting: bool = false  # Whether currently crafting
var requires_woman: bool = true  # Whether a woman must be present to craft

func _init(building_ref: BuildingBase = null, recipe_data: Dictionary = {}) -> void:
	building = building_ref
	recipe = recipe_data
	if recipe.has("requires_woman"):
		requires_woman = recipe["requires_woman"]
	else:
		requires_woman = true  # Default to requiring woman

func _ready() -> void:
	if not building:
		print("ERROR: ProductionComponent created without building reference")
		return
	
	# Ensure building has inventory
	if not building.inventory:
		building.inventory = InventoryData.new(6, true, 999)  # 6 slots, stacking enabled
	
	# Enable processing for this component
	set_process(true)
	print("🔵 ProductionComponent._ready() - process enabled")

func _process(delta: float) -> void:
	if not building:
		return
	
	if not is_instance_valid(building):
		return
	
	if not building.inventory:
		return
	
	# If building is active but can't craft (no resources), automatically turn it off
	if building.is_active and not _can_craft():
		# Check if we're missing materials (not just space issues)
		var has_materials = _has_required_materials()
		if not has_materials:
			# No materials - automatically turn off
			building.set_active(false)
			print("🔵 ProductionComponent: Building automatically turned off (no materials)")
			# Reset crafting state
			craft_timer = 0.0
			is_crafting = false
			# Notify UI to update fire button state
			_notify_inventory_changed()
			return
	
	# Check if we can craft
	if _can_craft():
		if not is_crafting:
			_start_crafting()
		
		# Update crafting timer
		craft_timer += delta
		var craft_time: float = recipe.get("craft_time", 60.0)
		
		if craft_timer >= craft_time:
			_complete_crafting()
	else:
		# Reset timer if we can't craft
		if is_crafting:
			craft_timer = 0.0
			is_crafting = false

func _can_craft() -> bool:
	if not building:
		return false
	
	if not is_instance_valid(building):
		return false
	
	if not building.inventory:
		return false
	
	# Check if building is active (turned on)
	if not building.is_active:
		return false
	
	if requires_woman:
		if not building.is_occupied():
			return false
	# Farm/Dairy require at least 1 animal of correct type
	if building.building_type == ResourceData.ResourceType.FARM:
		if not building.has_animal_type("sheep"):
			return false
	if building.building_type == ResourceData.ResourceType.DAIRY_FARM:
		if not building.has_animal_type("goat"):
			return false
	
	# Check if we have all required inputs
	if not recipe.has("inputs"):
		return false
	
	var inputs: Array = recipe["inputs"]
	for input in inputs:
		var input_type: ResourceData.ResourceType = input.get("type", ResourceData.ResourceType.NONE)
		var input_quantity: int = input.get("quantity", 1)
		
		if not building.inventory.has_item(input_type, input_quantity):
			return false
	
	# Check if we have space for output
	if recipe.has("output"):
		var output: Dictionary = recipe["output"]
		var output_type: ResourceData.ResourceType = output.get("type", ResourceData.ResourceType.NONE)
		
		# Check if we can add the output
		# First, check if there's an empty slot
		if building.inventory.has_space():
			# Has empty slot, can add
			pass
		else:
			# No empty slots - check if we can add to existing stack
			var existing_count: int = building.inventory.get_count(output_type)
			if existing_count > 0:
				# Check if existing stack has room (find a slot with this item that's not full)
				var can_add_to_stack: bool = false
				for i in building.inventory.slot_count:
					var slot = building.inventory.get_slot(i)
					if slot != null and slot.get("type", -1) == output_type:
						var current_count: int = slot.get("count", 1) as int
						if current_count < building.inventory.max_stack:
							# Found a stack with room
							can_add_to_stack = true
							break
				
				if not can_add_to_stack:
					# All stacks are full, no space
					return false
			else:
				# No existing stack and no empty slots - can't add
				return false
	
	return true

func _has_required_materials() -> bool:
	# Check if we have all required input materials (ignoring output space)
	if not building or not building.inventory:
		return false
	
	if not recipe.has("inputs"):
		return false
	
	var inputs: Array = recipe["inputs"]
	for input in inputs:
		var input_type: ResourceData.ResourceType = input.get("type", ResourceData.ResourceType.NONE)
		var input_quantity: int = input.get("quantity", 1)
		
		if not building.inventory.has_item(input_type, input_quantity):
			return false
	
	return true

func _start_crafting() -> void:
	if not building or not is_instance_valid(building):
		return
	is_crafting = true
	craft_timer = 0.0
	print("🔵 ProductionComponent: Started crafting at %s" % ResourceData.get_resource_name(building.building_type))

func _complete_crafting() -> void:
	if not building:
		return
	
	if not is_instance_valid(building):
		return
	
	if not building.inventory:
		return
	
	# Consume inputs
	var inputs: Array = recipe.get("inputs", [])
	for input in inputs:
		var input_type: ResourceData.ResourceType = input.get("type", ResourceData.ResourceType.NONE)
		var input_quantity: int = input.get("quantity", 1)
		
		building.inventory.remove_item(input_type, input_quantity)
	
	# Create output
	if recipe.has("output"):
		var output: Dictionary = recipe["output"]
		var output_type: ResourceData.ResourceType = output.get("type", ResourceData.ResourceType.NONE)
		var output_quantity: int = output.get("quantity", 1)
		
		var added: bool = building.inventory.add_item(output_type, output_quantity)
		if added:
			print("🔵 ProductionComponent: Created %d x %s at %s" % [
				output_quantity,
				ResourceData.get_resource_name(output_type),
				ResourceData.get_resource_name(building.building_type)
			])
			# Notify building to refresh UI (if building inventory UI is open)
			_notify_inventory_changed()
		else:
			print("ERROR: ProductionComponent: Failed to add output to inventory")
	
	# Reset crafting state
	craft_timer = 0.0
	is_crafting = false
	
	# NEW BEHAVIOR: Don't auto-start next craft - fire button must be pressed again
	# This prevents continuous production without player/NPC interaction
	# Turn off building after producing one item
	building.set_active(false)
	print("🔵 ProductionComponent: Produced one item, building turned off (press fire button again for next item)")

func set_recipe(new_recipe: Dictionary) -> void:
	recipe = new_recipe
	if recipe.has("requires_woman"):
		requires_woman = recipe["requires_woman"]
	else:
		requires_woman = true

func get_craft_progress() -> float:
	# Returns 0.0 to 1.0 progress
	if not is_crafting:
		return 0.0
	var craft_time: float = recipe.get("craft_time", 60.0)
	if craft_time <= 0.0:
		return 1.0
	return min(craft_timer / craft_time, 1.0)

func _notify_inventory_changed() -> void:
	# Notify any open building inventory UI to refresh
	# Find building inventory UI through the scene tree
	if not building or not is_instance_valid(building):
		return
	
	var scene_tree = building.get_tree()
	if not scene_tree:
		return
	
	# Try to find BuildingInventoryUI in the scene
	var ui_nodes = scene_tree.get_nodes_in_group("building_inventory_ui")
	for ui_node in ui_nodes:
		if ui_node.has_method("_update_all_slots"):
			# Check if this UI is showing the inventory for this building
			if ui_node.has_method("get") and ui_node.get("building") == building:
				# Call deferred to avoid issues during production
				ui_node.call_deferred("_update_all_slots")
				print("🔵 ProductionComponent: Notified building inventory UI to refresh")
