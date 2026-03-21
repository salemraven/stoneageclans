extends RefCounted
class_name InventoryData

# Data model for inventory - stores items in slots
# Player: 10 slots, no stacking
# Building: 9 slots (3x3), stacking up to 10
# Cart: 10 slots, stacking up to 10

var slots: Array = []  # Array of Dictionary: {"type": ResourceType, "count": int, "quality": int} or null
var slot_count: int = 10
var can_stack: bool = false
var max_stack: int = 1

func _init(count: int = 10, stacking: bool = false, max_stack_size: int = 1) -> void:
	slot_count = count
	can_stack = stacking
	max_stack = max_stack_size
	slots.resize(slot_count)
	for i in slot_count:
		slots[i] = null

func add_item(type: ResourceData.ResourceType, amount: int = 1, quality: int = 0) -> bool:
	if amount <= 0:
		return true  # Nothing to add
	
	var remaining: int = amount
	
	# Try to add to existing stack first (if stacking enabled)
	if can_stack:
		for i in slot_count:
			if remaining <= 0:
				return true
			var slot = slots[i]
			if slot != null and slot.get("type", -1) == type:
				var current_count: int = slot.get("count", 1) as int
				var space_left: int = max_stack - current_count
				if space_left > 0:
					var add_amount: int = min(remaining, space_left)
					# CRITICAL: Directly modify the slot in the array, not a copy
					slots[i]["count"] = current_count + add_amount
					remaining -= add_amount
					if remaining <= 0:
						return true
	
	# Add to empty slots (if stacking, create stacks; if not, one item per slot)
	if can_stack:
		# With stacking: try to add remaining amount to empty slots
		while remaining > 0:
			var added := false
			for i in slot_count:
				if slots[i] == null:
					var stack_size: int = min(remaining, max_stack)
					slots[i] = {"type": type, "count": stack_size, "quality": quality}
					remaining -= stack_size
					added = true
					break
			if not added:
				return false  # Inventory full
		return true
	else:
		# Without stacking: one item per slot
		for _i in range(remaining):
			var added := false
			for i in slot_count:
				if slots[i] == null:
					slots[i] = {"type": type, "count": 1, "quality": quality}
					added = true
					break
			if not added:
				return false  # Inventory full
		return true

func remove_item(type: ResourceData.ResourceType, amount: int = 1) -> bool:
	var removed := 0
	var total_available: int = get_count(type)  # Get total count of this item type
	
	# If amount requested is more than available, remove all available
	var amount_to_remove: int = min(amount, total_available)
	
	if amount_to_remove <= 0:
		return false  # Nothing to remove
	
	for i in slot_count:
		if removed >= amount_to_remove:
			break
		if slots[i] != null and slots[i].get("type", -1) == type:
			var current_count: int = slots[i].get("count", 1) as int
			var need_to_remove: int = amount_to_remove - removed
			if current_count <= need_to_remove:
				removed += current_count
				slots[i] = null
			else:
				slots[i]["count"] = current_count - need_to_remove
				removed += need_to_remove
			if removed >= amount_to_remove:
				break
	
	# Return true if we removed at least 1 item (or all requested if less available)
	return removed > 0

func get_slot(index: int) -> Dictionary:
	if index < 0 or index >= slot_count:
		return {}
	var slot = slots[index]
	if slot == null:
		return {}
	return slot.duplicate()

func set_slot(index: int, data: Dictionary) -> void:
	if index < 0 or index >= slot_count:
		return
	if data.is_empty():
		slots[index] = null
	else:
		slots[index] = data.duplicate()

func swap_slots(index1: int, index2: int) -> void:
	if index1 < 0 or index1 >= slot_count or index2 < 0 or index2 >= slot_count:
		return
	var temp = slots[index1]
	slots[index1] = slots[index2]
	slots[index2] = temp

func get_count(type: ResourceData.ResourceType) -> int:
	var count := 0
	for slot in slots:
		if slot != null and slot.get("type", -1) == type:
			count += slot.get("count", 1) as int
	return count

func has_space() -> bool:
	for slot in slots:
		if slot == null:
			return true
	return false

func has_item(type: ResourceData.ResourceType, amount: int = 1) -> bool:
	# Check if inventory has at least 'amount' of this item type
	return get_count(type) >= amount

func get_used_slots() -> int:
	# Count how many slots are currently in use (not null)
	var count := 0
	for slot in slots:
		if slot != null:
			count += 1
	return count
