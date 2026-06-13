extends Node
class_name PassiveProductionComponent

## Passive building production: inputs in building inventory convert to output over time.
## Used by Drying Rack (hide -> leather). No woman occupation required.

var building: BuildingBase = null
var recipe: Dictionary = {}
var process_timer: float = 0.0
var is_processing: bool = false


func _init(building_ref: BuildingBase = null, recipe_data: Dictionary = {}) -> void:
	building = building_ref
	recipe = recipe_data


func _ready() -> void:
	set_process(true)


func _process(delta: float) -> void:
	if not building or not is_instance_valid(building) or not building.inventory:
		return
	if is_processing:
		process_timer += delta
		var craft_time: float = recipe.get("craft_time", 120.0)
		if process_timer >= craft_time:
			_complete_processing()
		return
	if _can_start_processing():
		is_processing = true
		process_timer = 0.0


func _can_start_processing() -> bool:
	if not building or not building.inventory:
		return false
	var inputs: Array = recipe.get("inputs", [])
	for input in inputs:
		var input_type: ResourceData.ResourceType = input.get("type", ResourceData.ResourceType.NONE)
		var input_quantity: int = input.get("quantity", 1)
		if not building.inventory.has_item(input_type, input_quantity):
			return false
	if not recipe.has("output"):
		return false
	var output: Dictionary = recipe.get("output", {})
	var output_type: ResourceData.ResourceType = output.get("type", ResourceData.ResourceType.NONE)
	var output_quantity: int = output.get("quantity", 1)
	if not building.inventory.has_space():
		if building.inventory.get_count(output_type) <= 0:
			return false
		if building.inventory.get_count(output_type) + output_quantity > building.inventory.max_stack:
			return false
	return true


func _complete_processing() -> void:
	if not building or not building.inventory:
		is_processing = false
		process_timer = 0.0
		return
	var inputs: Array = recipe.get("inputs", [])
	for input in inputs:
		var input_type: ResourceData.ResourceType = input.get("type", ResourceData.ResourceType.NONE)
		var input_quantity: int = input.get("quantity", 1)
		building.inventory.remove_item(input_type, input_quantity)
	var output: Dictionary = recipe.get("output", {})
	var output_type: ResourceData.ResourceType = output.get("type", ResourceData.ResourceType.NONE)
	var output_quantity: int = output.get("quantity", 1)
	building.inventory.add_item(output_type, output_quantity)
	is_processing = false
	process_timer = 0.0


func has_output_ready() -> bool:
	if not recipe.has("output") or not building or not building.inventory:
		return false
	var output_type: ResourceData.ResourceType = recipe.get("output", {}).get("type", ResourceData.ResourceType.NONE)
	return building.inventory.get_count(output_type) >= 1


func get_output_type() -> ResourceData.ResourceType:
	if not recipe.has("output"):
		return ResourceData.ResourceType.NONE
	return recipe.get("output", {}).get("type", ResourceData.ResourceType.NONE) as ResourceData.ResourceType
