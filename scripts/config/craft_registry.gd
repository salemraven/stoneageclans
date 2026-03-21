extends RefCounted
class_name CraftRegistry

# Registry of player craftables (Oldowan, Cordage, Campfire, Travois)
# Uses combined inventory + hotbar for affordability check

class CraftData:
	var output_type: ResourceData.ResourceType
	var display_name: String
	var icon_path: String
	var cost: Dictionary  # {"stone": 2, "fiber": 3, ...}
	var duration: float  # Seconds to craft
	
	func _init(type: ResourceData.ResourceType, name: String, icon: String, craft_cost: Dictionary, craft_duration: float = 1.0):
		output_type = type
		display_name = name
		icon_path = icon
		cost = craft_cost
		duration = craft_duration

static var _crafts: Array[CraftData] = []

static func _initialize_crafts() -> void:
	if not _crafts.is_empty():
		return
	
	_crafts.append(CraftData.new(
		ResourceData.ResourceType.OLDOWAN,
		"Oldowan",
		"res://assets/sprites/oldowan.png",
		{"stone": 2},
		1.0
	))
	_crafts.append(CraftData.new(
		ResourceData.ResourceType.CORDAGE,
		"Cordage",
		"res://assets/sprites/fiber.png",  # Use fiber as placeholder until cordage.png exists
		{"fiber": 3},
		1.5
	))
	_crafts.append(CraftData.new(
		ResourceData.ResourceType.CAMPFIRE,
		"Campfire",
		"res://assets/sprites/campfire.png",
		{"wood": 2, "stone": 2},
		2.0
	))
	_crafts.append(CraftData.new(
		ResourceData.ResourceType.TRAVOIS,
		"Travois",
		"res://assets/sprites/travois.png",
		{"wood": 2, "cordage": 2},
		2.5
	))

static func get_all_crafts() -> Array[CraftData]:
	_initialize_crafts()
	return _crafts

static func get_craft(type: ResourceData.ResourceType) -> CraftData:
	_initialize_crafts()
	for craft in _crafts:
		if craft.output_type == type:
			return craft
	return null

static func material_name_to_type(material_name: String) -> ResourceData.ResourceType:
	match material_name.to_lower():
		"wood": return ResourceData.ResourceType.WOOD
		"stone": return ResourceData.ResourceType.STONE
		"fiber": return ResourceData.ResourceType.FIBER
		"cordage": return ResourceData.ResourceType.CORDAGE
		"hide": return ResourceData.ResourceType.HIDE
		"bone": return ResourceData.ResourceType.BONE
		"berries": return ResourceData.ResourceType.BERRIES
		_: return ResourceData.ResourceType.NONE

static func count_in_inventory(inv: InventoryData, resource_type: ResourceData.ResourceType) -> int:
	if not inv:
		return 0
	return inv.get_count(resource_type)

static func can_afford(craft: CraftData, inventory_data: InventoryData, hotbar_data: InventoryData) -> bool:
	if not craft:
		return false
	
	for material_type in craft.cost:
		var required_count: int = craft.cost[material_type]
		var resource_type: ResourceData.ResourceType = material_name_to_type(material_type)
		var total: int = count_in_inventory(inventory_data, resource_type) + count_in_inventory(hotbar_data, resource_type)
		if total < required_count:
			return false
	
	return true

static func consume_materials(craft: CraftData, inventory_data: InventoryData, hotbar_data: InventoryData) -> bool:
	if not can_afford(craft, inventory_data, hotbar_data):
		return false
	
	for material_type in craft.cost:
		var required_count: int = craft.cost[material_type]
		var resource_type: ResourceData.ResourceType = material_name_to_type(material_type)
		var remaining: int = required_count
		
		# Prefer inventory over hotbar (keep hotbar equipment)
		if inventory_data:
			var inv_count: int = inventory_data.get_count(resource_type)
			var take_from_inv: int = min(remaining, inv_count)
			if take_from_inv > 0:
				inventory_data.remove_item(resource_type, take_from_inv)
				remaining -= take_from_inv
		
		if remaining > 0 and hotbar_data:
			hotbar_data.remove_item(resource_type, remaining)
	
	return true

static func refund_materials(craft: CraftData, inventory_data: InventoryData, _hotbar_data: InventoryData) -> void:
	"""Restore materials when a craft is cancelled."""
	for material_type in craft.cost:
		var count: int = craft.cost[material_type]
		var resource_type: ResourceData.ResourceType = material_name_to_type(material_type)
		if inventory_data:
			inventory_data.add_item(resource_type, count)
