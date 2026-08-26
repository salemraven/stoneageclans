extends Node
## Phase 6: UI proposes inventory/build mutations; server validates and applies.
## Single-player and listen-server: validate synchronously then emit inventory_mutate_validated.

signal inventory_mutate_validated(op: Dictionary)
signal inventory_mutate_rejected(op: Dictionary, reason: String)

const OP_MOVE: String = "move"
const OP_CRAFT: String = "craft"
const OP_PLACE: String = "place"
const OP_PICKUP: String = "pickup"
const OP_DROP: String = "drop"

const INV_PLAYER: String = "player"
const INV_HOTBAR: String = "hotbar"
const INV_BUILDING: String = "building"
const INV_NPC: String = "npc"
const INV_CORPSE: String = "corpse"

const MODE_STACK_FULL: String = "stack_full"
const MODE_STACK_PARTIAL: String = "stack_partial"
const MODE_SWAP: String = "swap"
const MODE_MOVE: String = "move"

const KEY_TYPE: String = "type"
const KEY_MODE: String = "mode"
const KEY_FROM_INV: String = "from_inventory"
const KEY_FROM_SLOT: String = "from_slot"
const KEY_FROM_ENTITY: String = "from_entity_id"
const KEY_TO_INV: String = "to_inventory"
const KEY_TO_SLOT: String = "to_slot"
const KEY_TO_ENTITY: String = "to_entity_id"
const KEY_ITEM_TYPE: String = "item_type"
const KEY_COUNT: String = "count"
const KEY_PEER_ID: String = "peer_id"
const KEY_SWAP_ITEM: String = "swap_item"
const KEY_REMAINDER_COUNT: String = "remainder_count"
const KEY_TO_CAN_STACK: String = "to_can_stack"
const KEY_TO_MAX_STACK: String = "to_max_stack"
const KEY_CRAFT_OUTPUT: String = "craft_output"
const KEY_CRAFT_PHASE: String = "craft_phase"
const CRAFT_PHASE_CONSUME: String = "consume"
const CRAFT_PHASE_FINISH: String = "finish"

const INTERACTION_RANGE_BUILDING: float = 100.0
const INTERACTION_RANGE_CORPSE: float = 50.0
const INTERACTION_RANGE_NPC: float = 80.0


func propose_inventory_mutate(op: Dictionary) -> bool:
	if op.is_empty():
		return false
	var validated_op: Dictionary = op.duplicate(true)
	if multiplayer.has_multiplayer_peer() and not multiplayer.is_server():
		submit_inventory_mutate_to_server.rpc_id(1, validated_op)
		return true
	validated_op[KEY_PEER_ID] = _resolve_local_peer_id()
	if not _validate_inventory_op(validated_op):
		return false
	_emit_validated_op(validated_op)
	return true


@rpc("any_peer", "call_remote", "reliable")
func submit_inventory_mutate_to_server(op: Dictionary) -> void:
	if not multiplayer.is_server():
		return
	var validated_op: Dictionary = op.duplicate(true)
	validated_op[KEY_PEER_ID] = multiplayer.get_remote_sender_id()
	if not _validate_inventory_op(validated_op):
		return
	_emit_validated_op(validated_op)


@rpc("authority", "call_remote", "reliable")
func confirm_inventory_mutate(op: Dictionary) -> void:
	if multiplayer.is_server():
		return
	inventory_mutate_validated.emit(op)


func _emit_validated_op(op: Dictionary) -> void:
	if not apply_inventory_op(op):
		return
	inventory_mutate_validated.emit(op)
	if not multiplayer.has_multiplayer_peer():
		return
	var peer_id: int = int(op.get(KEY_PEER_ID, 0))
	if peer_id <= 0 or peer_id == multiplayer.get_unique_id():
		return
	confirm_inventory_mutate.rpc_id(peer_id, op)


func apply_inventory_op(op: Dictionary) -> bool:
	if op.is_empty():
		return false
	var op_type: String = str(op.get(KEY_TYPE, ""))
	match op_type:
		OP_MOVE:
			return _apply_move_op(op)
		OP_CRAFT:
			return _apply_craft_op(op)
		OP_PLACE, OP_PICKUP, OP_DROP:
			push_warning("InventoryActionBridge: op type '%s' apply not implemented yet" % op_type)
			return false
		_:
			push_warning("InventoryActionBridge: unknown op type '%s'" % op_type)
			return false


func build_move_op(
	from_kind: String,
	from_entity_id: int,
	from_slot: int,
	to_kind: String,
	to_entity_id: int,
	to_slot: int,
	dragged_item: Dictionary,
	target_item: Dictionary,
	to_can_stack: bool,
	to_max_stack: int
) -> Dictionary:
	if dragged_item.is_empty():
		return {}
	var dragged_type: ResourceData.ResourceType = dragged_item.get("type", ResourceData.ResourceType.NONE) as ResourceData.ResourceType
	var dragged_count: int = maxi(1, int(dragged_item.get("count", 1)))
	var op: Dictionary = {
		KEY_TYPE: OP_MOVE,
		KEY_FROM_INV: from_kind,
		KEY_FROM_SLOT: from_slot,
		KEY_FROM_ENTITY: from_entity_id,
		KEY_TO_INV: to_kind,
		KEY_TO_SLOT: to_slot,
		KEY_TO_ENTITY: to_entity_id,
		KEY_ITEM_TYPE: int(dragged_type),
		KEY_COUNT: dragged_count,
		KEY_TO_CAN_STACK: to_can_stack,
		KEY_TO_MAX_STACK: to_max_stack,
	}
	if target_item.is_empty():
		op[KEY_MODE] = MODE_MOVE
		return op
	var target_type: ResourceData.ResourceType = target_item.get("type", ResourceData.ResourceType.NONE) as ResourceData.ResourceType
	if target_type != dragged_type or not to_can_stack:
		op[KEY_MODE] = MODE_SWAP
		op[KEY_SWAP_ITEM] = target_item.duplicate()
		return op
	var target_count: int = int(target_item.get("count", 1))
	var total: int = target_count + dragged_count
	if total <= to_max_stack:
		op[KEY_MODE] = MODE_STACK_FULL
	else:
		op[KEY_MODE] = MODE_STACK_PARTIAL
		op[KEY_REMAINDER_COUNT] = dragged_count - (to_max_stack - target_count)
	return op


func resolve_slot_context(slot: InventorySlot) -> Dictionary:
	var result := {
		"kind": INV_PLAYER,
		"entity_id": -1,
		"inventory_data": null,
		"is_hotbar": slot.is_hotbar if slot else false,
	}
	if slot == null or not is_instance_valid(slot):
		return result
	var main: Node = get_tree().get_first_node_in_group("main")
	if main == null:
		return result
	var player_ui = main.get("player_inventory_ui")
	if player_ui:
		if slot in player_ui.slots:
			result["kind"] = INV_PLAYER
			result["inventory_data"] = player_ui.inventory_data
			return result
		if slot in player_ui.hotbar_slots:
			result["kind"] = INV_HOTBAR
			result["inventory_data"] = player_ui.get_meta("hotbar_data", null)
			return result
	var building_ui = main.get("building_inventory_ui")
	if building_ui and slot in building_ui.slots:
		result["kind"] = INV_CORPSE if building_ui.is_corpse_inventory else INV_BUILDING
		result["inventory_data"] = building_ui.inventory_data
		result["entity_id"] = _entity_id_for_building_ui(building_ui)
		return result
	var npc_ui = main.get("npc_inventory_ui")
	if npc_ui and slot in npc_ui.slots:
		result["kind"] = INV_NPC
		result["inventory_data"] = npc_ui.inventory_data
		if npc_ui.get("target_npc"):
			result["entity_id"] = get_entity_id(npc_ui.target_npc)
		return result
	var inv := _walk_parent_inventory_data(slot)
	if inv:
		result["inventory_data"] = inv
	return result


func get_entity_id(node: Node) -> int:
	if node == null or not is_instance_valid(node):
		return -1
	if EntityRegistry:
		var network_id: int = EntityRegistry.get_network_id(node)
		if network_id > 0:
			return network_id
	return node.get_instance_id()


func slot_accepts_item_for_inventory(
	inv_kind: String,
	slot_index: int,
	is_hotbar: bool,
	item_type: ResourceData.ResourceType
) -> bool:
	if inv_kind == INV_HOTBAR or (inv_kind == INV_PLAYER and is_hotbar):
		return PlayerInventoryUI.slot_accepts_item(slot_index, true, item_type)
	if inv_kind == INV_PLAYER:
		return PlayerInventoryUI.slot_accepts_item(slot_index, false, item_type)
	return true


func get_max_stack_for_slot(
	inv_kind: String,
	slot_index: int,
	is_hotbar: bool,
	item_type: ResourceData.ResourceType,
	inventory_data: InventoryData
) -> int:
	if inv_kind == INV_HOTBAR or inv_kind == INV_PLAYER:
		if ResourceData.is_food(item_type) and slot_accepts_item_for_inventory(inv_kind, slot_index, is_hotbar, item_type):
			return PlayerInventoryUI.FOOD_MAX_STACK
		if is_hotbar:
			return 1
	if inventory_data:
		return inventory_data.max_stack
	return 1


func _validate_inventory_op(op: Dictionary) -> bool:
	var op_type: String = str(op.get(KEY_TYPE, ""))
	match op_type:
		OP_MOVE:
			return _validate_move_op(op)
		OP_CRAFT:
			return _validate_craft_op(op)
		OP_PLACE:
			return _validate_place_op(op)
		OP_PICKUP, OP_DROP:
			inventory_mutate_rejected.emit(op, "unsupported_op_type")
			return false
		_:
			inventory_mutate_rejected.emit(op, "missing_op_type")
			return false


func _validate_move_op(op: Dictionary) -> bool:
	var peer_id: int = int(op.get(KEY_PEER_ID, _resolve_local_peer_id()))
	var player: Node2D = _resolve_player_for_peer(peer_id)
	if player == null:
		inventory_mutate_rejected.emit(op, "no_player")
		return false
	var from_kind: String = str(op.get(KEY_FROM_INV, ""))
	var to_kind: String = str(op.get(KEY_TO_INV, ""))
	var from_entity: int = int(op.get(KEY_FROM_ENTITY, -1))
	var to_entity: int = int(op.get(KEY_TO_ENTITY, -1))
	var from_slot: int = int(op.get(KEY_FROM_SLOT, -1))
	var to_slot: int = int(op.get(KEY_TO_SLOT, -1))
	var item_type: ResourceData.ResourceType = int(op.get(KEY_ITEM_TYPE, -1)) as ResourceData.ResourceType
	var count: int = int(op.get(KEY_COUNT, 0))
	var mode: String = str(op.get(KEY_MODE, ""))
	if count <= 0 or item_type == ResourceData.ResourceType.NONE:
		inventory_mutate_rejected.emit(op, "invalid_item")
		return false
	if from_slot == to_slot and from_kind == to_kind and from_entity == to_entity:
		inventory_mutate_rejected.emit(op, "same_slot")
		return false
	var from_data: InventoryData = _resolve_inventory_data(from_kind, from_entity, peer_id)
	var to_data: InventoryData = _resolve_inventory_data(to_kind, to_entity, peer_id)
	if from_data == null or to_data == null:
		inventory_mutate_rejected.emit(op, "missing_inventory")
		return false
	if not _slot_in_bounds(from_data, from_slot) or not _slot_in_bounds(to_data, to_slot):
		inventory_mutate_rejected.emit(op, "slot_out_of_bounds")
		return false
	if not _check_inventory_access(player, from_kind, from_entity, peer_id, false):
		inventory_mutate_rejected.emit(op, "from_access_denied")
		return false
	if not _check_inventory_access(player, to_kind, to_entity, peer_id, true):
		inventory_mutate_rejected.emit(op, "to_access_denied")
		return false
	var from_is_hotbar: bool = from_kind == INV_HOTBAR
	var to_is_hotbar: bool = to_kind == INV_HOTBAR
	if not slot_accepts_item_for_inventory(to_kind, to_slot, to_is_hotbar, item_type):
		inventory_mutate_rejected.emit(op, "slot_rejects_item")
		return false
	var to_max_stack: int = int(op.get(KEY_TO_MAX_STACK, to_data.max_stack))
	var to_can_stack: bool = bool(op.get(KEY_TO_CAN_STACK, to_data.can_stack))
	var target_item: Dictionary = to_data.get_slot(to_slot)
	match mode:
		MODE_MOVE:
			if not target_item.is_empty():
				inventory_mutate_rejected.emit(op, "target_not_empty")
				return false
		MODE_SWAP:
			if target_item.is_empty():
				inventory_mutate_rejected.emit(op, "swap_target_empty")
				return false
			var swap_type: ResourceData.ResourceType = target_item.get("type", ResourceData.ResourceType.NONE) as ResourceData.ResourceType
			if not slot_accepts_item_for_inventory(from_kind, from_slot, from_is_hotbar, swap_type):
				inventory_mutate_rejected.emit(op, "swap_source_rejects")
				return false
		MODE_STACK_FULL, MODE_STACK_PARTIAL:
			if target_item.is_empty():
				inventory_mutate_rejected.emit(op, "stack_target_empty")
				return false
			if int(target_item.get("type", -1)) != int(item_type):
				inventory_mutate_rejected.emit(op, "stack_type_mismatch")
				return false
			if not to_can_stack and not (to_kind in [INV_PLAYER, INV_HOTBAR]):
				inventory_mutate_rejected.emit(op, "stacking_disabled")
				return false
			var target_count: int = int(target_item.get("count", 1))
			if mode == MODE_STACK_FULL and target_count + count > to_max_stack:
				inventory_mutate_rejected.emit(op, "stack_overflow")
				return false
			if mode == MODE_STACK_PARTIAL:
				var remainder: int = int(op.get(KEY_REMAINDER_COUNT, -1))
				var expected_remainder: int = count - (to_max_stack - target_count)
				if remainder != expected_remainder or expected_remainder <= 0:
					inventory_mutate_rejected.emit(op, "partial_stack_invalid")
					return false
		_:
			inventory_mutate_rejected.emit(op, "unknown_mode")
			return false
	return true


func _validate_craft_op(op: Dictionary) -> bool:
	var peer_id: int = int(op.get(KEY_PEER_ID, _resolve_local_peer_id()))
	var player: Node2D = _resolve_player_for_peer(peer_id)
	if player == null:
		inventory_mutate_rejected.emit(op, "no_player")
		return false
	var output_type: ResourceData.ResourceType = int(op.get(KEY_CRAFT_OUTPUT, -1)) as ResourceData.ResourceType
	if output_type == ResourceData.ResourceType.NONE:
		inventory_mutate_rejected.emit(op, "invalid_craft_output")
		return false
	var craft = CraftRegistry.get_craft(output_type)
	if craft == null:
		inventory_mutate_rejected.emit(op, "unknown_craft")
		return false
	var main: Node = get_tree().get_first_node_in_group("main")
	if main == null:
		inventory_mutate_rejected.emit(op, "no_main")
		return false
	var player_ui = main.get("player_inventory_ui")
	if player_ui == null:
		inventory_mutate_rejected.emit(op, "no_player_ui")
		return false
	var hotbar_data: InventoryData = player_ui.get_meta("hotbar_data", null) as InventoryData
	var inv_data: InventoryData = player_ui.get("inventory_data") as InventoryData
	var phase: String = str(op.get(KEY_CRAFT_PHASE, CRAFT_PHASE_FINISH))
	if phase == CRAFT_PHASE_CONSUME:
		if not CraftRegistry.can_afford(craft, inv_data, hotbar_data):
			inventory_mutate_rejected.emit(op, "cannot_afford")
			return false
	return true


func _validate_place_op(op: Dictionary) -> bool:
	var peer_id: int = int(op.get(KEY_PEER_ID, _resolve_local_peer_id()))
	var player: Node2D = _resolve_player_for_peer(peer_id)
	if player == null:
		inventory_mutate_rejected.emit(op, "no_player")
		return false
	var item_type: ResourceData.ResourceType = int(op.get(KEY_ITEM_TYPE, -1)) as ResourceData.ResourceType
	if item_type == ResourceData.ResourceType.NONE:
		inventory_mutate_rejected.emit(op, "invalid_place_item")
		return false
	var from_kind: String = str(op.get(KEY_FROM_INV, INV_PLAYER))
	var from_entity: int = int(op.get(KEY_FROM_ENTITY, -1))
	var from_slot: int = int(op.get(KEY_FROM_SLOT, -1))
	if not _check_inventory_access(player, from_kind, from_entity, peer_id, false):
		inventory_mutate_rejected.emit(op, "place_access_denied")
		return false
	var from_data: InventoryData = _resolve_inventory_data(from_kind, from_entity, peer_id)
	if from_data == null or not _slot_in_bounds(from_data, from_slot):
		inventory_mutate_rejected.emit(op, "place_slot_invalid")
		return false
	var slot_data: Dictionary = from_data.get_slot(from_slot)
	if slot_data.is_empty() or int(slot_data.get("type", -1)) != int(item_type):
		inventory_mutate_rejected.emit(op, "place_item_missing")
		return false
	return true


func _apply_move_op(op: Dictionary) -> bool:
	var peer_id: int = int(op.get(KEY_PEER_ID, _resolve_local_peer_id()))
	var from_kind: String = str(op.get(KEY_FROM_INV, ""))
	var to_kind: String = str(op.get(KEY_TO_INV, ""))
	var from_entity: int = int(op.get(KEY_FROM_ENTITY, -1))
	var to_entity: int = int(op.get(KEY_TO_ENTITY, -1))
	var from_slot: int = int(op.get(KEY_FROM_SLOT, -1))
	var to_slot: int = int(op.get(KEY_TO_SLOT, -1))
	var item_type: ResourceData.ResourceType = int(op.get(KEY_ITEM_TYPE, -1)) as ResourceData.ResourceType
	var count: int = int(op.get(KEY_COUNT, 1))
	var mode: String = str(op.get(KEY_MODE, ""))
	var from_data: InventoryData = _resolve_inventory_data(from_kind, from_entity, peer_id)
	var to_data: InventoryData = _resolve_inventory_data(to_kind, to_entity, peer_id)
	if from_data == null or to_data == null:
		return false
	var quality: int = 0
	var dragged := {"type": item_type, "count": count, "quality": quality}
	var target_item: Dictionary = to_data.get_slot(to_slot)
	match mode:
		MODE_MOVE:
			to_data.set_slot(to_slot, dragged.duplicate())
			from_data.set_slot(from_slot, {})
		MODE_SWAP:
			var swap_item: Dictionary = op.get(KEY_SWAP_ITEM, {}).duplicate()
			to_data.set_slot(to_slot, dragged.duplicate())
			from_data.set_slot(from_slot, swap_item)
		MODE_STACK_FULL:
			target_item["count"] = int(target_item.get("count", 1)) + count
			to_data.set_slot(to_slot, target_item)
			from_data.set_slot(from_slot, {})
		MODE_STACK_PARTIAL:
			var to_max: int = int(op.get(KEY_TO_MAX_STACK, get_max_stack_for_slot(to_kind, to_slot, to_kind == INV_HOTBAR, item_type, to_data)))
			target_item["count"] = to_max
			to_data.set_slot(to_slot, target_item)
			var remainder: int = int(op.get(KEY_REMAINDER_COUNT, 0))
			if remainder > 0:
				from_data.set_slot(from_slot, {"type": item_type, "count": remainder, "quality": quality})
			else:
				from_data.set_slot(from_slot, {})
		_:
			return false
	_refresh_inventory_uis(from_kind, to_kind, from_entity, to_entity)
	return true


func _apply_craft_op(op: Dictionary) -> bool:
	var output_type: ResourceData.ResourceType = int(op.get(KEY_CRAFT_OUTPUT, -1)) as ResourceData.ResourceType
	var craft = CraftRegistry.get_craft(output_type)
	if craft == null:
		return false
	var main: Node = get_tree().get_first_node_in_group("main")
	if main == null:
		return false
	var player_ui = main.get("player_inventory_ui")
	if player_ui == null:
		return false
	var hotbar_data: InventoryData = player_ui.get_meta("hotbar_data", null) as InventoryData
	var inv_data: InventoryData = player_ui.get("inventory_data") as InventoryData
	var phase: String = str(op.get(KEY_CRAFT_PHASE, CRAFT_PHASE_FINISH))
	if phase == CRAFT_PHASE_CONSUME:
		if not CraftRegistry.consume_materials(craft, inv_data, hotbar_data):
			return false
		if player_ui.has_method("_update_all_slots"):
			player_ui._update_all_slots()
		if player_ui.has_method("_update_hotbar_slots"):
			player_ui._update_hotbar_slots()
		if player_ui.has_method("_update_craft_icon_states"):
			player_ui._update_craft_icon_states()
		return true
	if ResourceData.is_food(output_type):
		if player_ui.has_method("add_item_preferring_food_slots"):
			player_ui.call("add_item_preferring_food_slots", output_type, 1)
		elif inv_data:
			inv_data.add_item(output_type, 1)
	elif inv_data:
		inv_data.add_item(output_type, 1)
	if player_ui.has_method("_update_all_slots"):
		player_ui._update_all_slots()
	if player_ui.has_method("_update_hotbar_slots"):
		player_ui._update_hotbar_slots()
	if player_ui.has_method("_update_craft_icon_states"):
		player_ui._update_craft_icon_states()
	return true


func _resolve_local_peer_id() -> int:
	if multiplayer.has_multiplayer_peer():
		return multiplayer.get_unique_id()
	return 1


func _resolve_player_for_peer(peer_id: int) -> Node2D:
	var main: Node = get_tree().get_first_node_in_group("main")
	if main == null:
		return null
	if peer_id <= 0 or peer_id == _resolve_local_peer_id():
		return main.get("player") as Node2D
	for p in main.get_tree().get_nodes_in_group("player"):
		if not is_instance_valid(p) or not (p is Node2D):
			continue
		if int(p.get_multiplayer_authority()) == peer_id:
			return p as Node2D
	return main.get("player") as Node2D


func _resolve_inventory_data(kind: String, entity_id: int, _peer_id: int) -> InventoryData:
	var main: Node = get_tree().get_first_node_in_group("main")
	if main == null:
		return null
	var player_ui = main.get("player_inventory_ui")
	match kind:
		INV_PLAYER:
			if player_ui:
				return player_ui.get("inventory_data") as InventoryData
			return null
		INV_HOTBAR:
			if player_ui:
				return player_ui.get_meta("hotbar_data", null) as InventoryData
			return null
		INV_BUILDING, INV_CORPSE:
			var entity: Node = _resolve_entity(entity_id)
			if entity == null:
				var building_ui = main.get("building_inventory_ui")
				if building_ui and building_ui.inventory_data:
					return building_ui.inventory_data
				return null
			if entity.get("inventory") != null:
				return entity.get("inventory") as InventoryData
			return null
		INV_NPC:
			var entity_npc: Node = _resolve_entity(entity_id)
			if entity_npc and entity_npc.get("inventory") != null:
				return entity_npc.get("inventory") as InventoryData
			var npc_ui = main.get("npc_inventory_ui")
			return npc_ui.inventory_data if npc_ui else null
	return null


func _resolve_entity(entity_id: int) -> Node:
	if entity_id < 0:
		return null
	if EntityRegistry:
		var by_network: Node = EntityRegistry.get_node_by_network_id(entity_id)
		if by_network != null:
			return by_network
		var by_instance: Node = EntityRegistry.get_entity_node(entity_id)
		if by_instance != null:
			return by_instance
	var main: Node = get_tree().get_first_node_in_group("main")
	if main == null:
		return null
	var building_ui = main.get("building_inventory_ui")
	if building_ui:
		var from_ui: Node = _entity_node_for_building_ui(building_ui)
		if from_ui != null and get_entity_id(from_ui) == entity_id:
			return from_ui
	return null


func _entity_node_for_building_ui(building_ui: Node) -> Node:
	if building_ui.get("corpse_npc") and is_instance_valid(building_ui.corpse_npc):
		return building_ui.corpse_npc
	if building_ui.get("building") and is_instance_valid(building_ui.building):
		return building_ui.building
	if building_ui.get("campfire") and is_instance_valid(building_ui.campfire):
		return building_ui.campfire
	if building_ui.get("land_claim") and is_instance_valid(building_ui.land_claim):
		return building_ui.land_claim
	return null


func _entity_id_for_building_ui(building_ui: Node) -> int:
	var node: Node = _entity_node_for_building_ui(building_ui)
	return get_entity_id(node) if node else -1


func _check_inventory_access(
	player: Node2D,
	inv_kind: String,
	entity_id: int,
	peer_id: int,
	is_target: bool
) -> bool:
	match inv_kind:
		INV_PLAYER, INV_HOTBAR:
			return _player_owns_inventory(player, peer_id)
		INV_NPC:
			if is_target:
				return false
			return _check_entity_distance(player, entity_id, INTERACTION_RANGE_NPC)
		INV_CORPSE:
			return _check_entity_distance(player, entity_id, INTERACTION_RANGE_CORPSE)
		INV_BUILDING:
			return _check_building_access(player, entity_id)
	return false


func _player_owns_inventory(player: Node2D, peer_id: int) -> bool:
	if player == null:
		return false
	if multiplayer.has_multiplayer_peer():
		return int(player.get_multiplayer_authority()) == peer_id
	return true


func _check_entity_distance(player: Node2D, entity_id: int, range_px: float) -> bool:
	var entity: Node = _resolve_entity(entity_id)
	if entity == null or not (entity is Node2D):
		return false
	return player.global_position.distance_to((entity as Node2D).global_position) <= range_px


func _check_building_access(player: Node2D, entity_id: int) -> bool:
	var entity: Node = _resolve_entity(entity_id)
	if entity == null:
		return false
	if not (entity is Node2D):
		return false
	if player.global_position.distance_to((entity as Node2D).global_position) > INTERACTION_RANGE_BUILDING:
		return false
	if entity.get("player_owned") == true:
		return true
	if entity.get("is_raidable") == true:
		return true
	var player_clan: String = _get_player_clan_name(player)
	var entity_clan: String = str(entity.get("clan_name")) if entity.get("clan_name") != null else ""
	if player_clan != "" and entity_clan != "" and player_clan.to_upper() == entity_clan.to_upper():
		return true
	return false


func _get_player_clan_name(player: Node) -> String:
	if player and player.has_method("get_clan_name"):
		var cn: String = player.get_clan_name()
		if cn != "":
			return cn
	var main: Node = get_tree().get_first_node_in_group("main")
	if main and main.has_method("_get_player_clan_name"):
		return main._get_player_clan_name()
	return ""


func _slot_in_bounds(inventory_data: InventoryData, slot_index: int) -> bool:
	return slot_index >= 0 and slot_index < inventory_data.slot_count


func _walk_parent_inventory_data(slot: InventorySlot) -> InventoryData:
	var parent: Node = slot.get_parent()
	while parent:
		if parent.get("inventory_data"):
			return parent.get("inventory_data") as InventoryData
		parent = parent.get_parent()
	return null


func _refresh_inventory_uis(from_kind: String, to_kind: String, from_entity: int, to_entity: int) -> void:
	var main: Node = get_tree().get_first_node_in_group("main")
	if main == null:
		return
	var player_ui = main.get("player_inventory_ui")
	if player_ui:
		if from_kind in [INV_PLAYER, INV_HOTBAR] or to_kind in [INV_PLAYER, INV_HOTBAR]:
			if player_ui.has_method("_update_all_slots"):
				player_ui._update_all_slots()
			if player_ui.has_method("_update_hotbar_slots"):
				player_ui._update_hotbar_slots()
	var building_ui = main.get("building_inventory_ui")
	if building_ui and (from_kind in [INV_BUILDING, INV_CORPSE] or to_kind in [INV_BUILDING, INV_CORPSE]):
		building_ui._update_all_slots()
		if building_ui.has_method("_update_building_ui_state"):
			building_ui._update_building_ui_state()
	var npc_ui = main.get("npc_inventory_ui")
	if npc_ui and (from_kind == INV_NPC or to_kind == INV_NPC):
		npc_ui._update_all_slots()
	if main.has_method("_update_equipment"):
		if from_kind == INV_HOTBAR or to_kind == INV_HOTBAR:
			main._update_equipment()
