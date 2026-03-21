extends RefCounted
class_name BuildingRegistry

# Registry of all building types with their costs, icons, and descriptions
# Used by BuildMenuUI to display available buildings

class BuildingData:
	var building_type: ResourceData.ResourceType
	var display_name: String
	var description: String
	var icon_path: String
	var cost: Dictionary  # {"wood": 1, "stone": 1, ...}
	
	func _init(type: ResourceData.ResourceType, name: String, desc: String, icon: String, building_cost: Dictionary):
		building_type = type
		display_name = name
		description = desc
		icon_path = icon
		cost = building_cost

# Building definitions
static var _buildings: Array[BuildingData] = []

static func _initialize_buildings() -> void:
	if not _buildings.is_empty():
		return  # Already initialized
	
	# Living Hut: +5 baby pool capacity
	_buildings.append(BuildingData.new(
		ResourceData.ResourceType.LIVING_HUT,
		"Living Hut",
		"Provides +5 Baby Pool.",
		"res://assets/sprites/hut.png",
		{"wood": 1, "stone": 1}  # Testing cost: 1 wood, 1 stone
	))
	
	# Supply Hut: Extra storage
	_buildings.append(BuildingData.new(
		ResourceData.ResourceType.SUPPLY_HUT,
		"Supply Hut",
		"Provides extra storage.",
		"res://assets/sprites/supply.png",
		{"wood": 1, "stone": 1}  # Testing cost: 1 wood, 1 stone
	))
	
	# Shrine: Place of worship
	_buildings.append(BuildingData.new(
		ResourceData.ResourceType.SHRINE,
		"Shrine",
		"A place of worship.",
		"res://assets/sprites/shrine.png",
		{"wood": 1, "stone": 1}  # Testing cost: 1 wood, 1 stone
	))
	
	# Dairy Farm: Fiber to milk (goats + women)
	_buildings.append(BuildingData.new(
		ResourceData.ResourceType.DAIRY_FARM,
		"Dairy Farm",
		"Fiber to milk. Requires goats and women.",
		"res://assets/sprites/dairy.png",
		{"wood": 1, "stone": 1}
	))
	
	# Farm: Fiber to wool (sheep + women)
	_buildings.append(BuildingData.new(
		ResourceData.ResourceType.FARM,
		"Farm",
		"Fiber to wool. Requires sheep and women.",
		"res://assets/sprites/farm1.png",
		{"wood": 1, "stone": 1}
	))
	
	# Oven: Produces bread from wood and grain (requires woman)
	_buildings.append(BuildingData.new(
		ResourceData.ResourceType.OVEN,
		"Oven",
		"Produces bread from wood and grain. Requires 1 woman to operate.",
		"res://assets/sprites/oven.png",
		{"stone": 2}  # Testing cost: 2 stone
	))

# Get all building definitions
static func get_all_buildings() -> Array[BuildingData]:
	_initialize_buildings()
	return _buildings

# Get building data by type
static func get_building(type: ResourceData.ResourceType) -> BuildingData:
	_initialize_buildings()
	for building in _buildings:
		if building.building_type == type:
			return building
	return null

# Check if player has required materials in inventory
static func can_afford_building(building: BuildingData, inventory: InventoryData) -> bool:
	if not building or not inventory:
		return false
	
	for material_type in building.cost:
		var required_count: int = building.cost[material_type]
		var resource_type: ResourceData.ResourceType = material_name_to_type(material_type)
		var available_count: int = count_resource_in_inventory(inventory, resource_type)
		
		if available_count < required_count:
			return false
	
	return true

# Get missing materials (returns dict of {material: needed_count})
static func get_missing_materials(building: BuildingData, inventory: InventoryData) -> Dictionary:
	var missing: Dictionary = {}
	if not building or not inventory:
		return missing
	
	for material_type in building.cost:
		var required_count: int = building.cost[material_type]
		var resource_type: ResourceData.ResourceType = material_name_to_type(material_type)
		var available_count: int = count_resource_in_inventory(inventory, resource_type)
		
		if available_count < required_count:
			missing[material_type] = required_count - available_count
	
	return missing

# Helper: Convert material name string to ResourceType (public for UI access)
static func material_name_to_type(material_name: String) -> ResourceData.ResourceType:
	match material_name.to_lower():
		"wood": return ResourceData.ResourceType.WOOD
		"stone": return ResourceData.ResourceType.STONE
		"fiber": return ResourceData.ResourceType.FIBER
		"berries": return ResourceData.ResourceType.BERRIES
		_: return ResourceData.ResourceType.NONE

# Helper: Count specific resource in inventory (public for UI access)
static func count_resource_in_inventory(inventory: InventoryData, resource_type: ResourceData.ResourceType) -> int:
	var count: int = 0
	for i in range(inventory.slot_count):
		var slot_data = inventory.get_slot(i)
		if not slot_data.is_empty():
			var slot_type = slot_data.get("type", -1) as ResourceData.ResourceType
			if slot_type == resource_type:
				count += slot_data.get("count", 1)
	return count

# Consume required materials from inventory
# Returns true if all materials were consumed, false otherwise
static func consume_materials(building: BuildingData, inventory: InventoryData) -> bool:
	if not can_afford_building(building, inventory):
		return false
	
	# Consume each required material
	for material_type in building.cost:
		var required_count: int = building.cost[material_type]
		var resource_type: ResourceData.ResourceType = material_name_to_type(material_type)
		_consume_resource_from_inventory(inventory, resource_type, required_count)
	
	return true

# Helper: Consume specific amount of resource from inventory
static func _consume_resource_from_inventory(inventory: InventoryData, resource_type: ResourceData.ResourceType, amount: int) -> void:
	var remaining: int = amount
	
	for i in range(inventory.slot_count):
		if remaining <= 0:
			break
		
		var slot_data = inventory.get_slot(i)
		if not slot_data.is_empty():
			var slot_type = slot_data.get("type", -1) as ResourceData.ResourceType
			if slot_type == resource_type:
				var slot_count: int = slot_data.get("count", 1)
				if slot_count <= remaining:
					# Remove entire stack
					inventory.set_slot(i, {})
					remaining -= slot_count
				else:
					# Remove partial stack
					slot_data["count"] = slot_count - remaining
					inventory.set_slot(i, slot_data)
					remaining = 0
