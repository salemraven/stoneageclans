class_name HutCarry
extends RefCounted

const HutSpecialtyScript = preload("res://scripts/buildings/hut_specialty.gd")
## One item type per walk, at most 5. The hut timer crafts. This only moves stacks.

const MAX_QTY := 5
const HOME_META := "home_living_hut"
const ASSIGNED_META := "assigned_woman"

const PRODUCTS: Dictionary = {
	"oven": [ResourceData.ResourceType.BREAD],
	"rack": [ResourceData.ResourceType.LEATHER_SHEET, ResourceData.ResourceType.CORDAGE],
	"weaver": [ResourceData.ResourceType.FIBER_SHEET, ResourceData.ResourceType.WOOL_SHEET],
	"crop": [ResourceData.ResourceType.GRAIN],
}


static func carry_qty(have: int, room: int) -> int:
	return mini(MAX_QTY, mini(maxi(have, 0), maxi(room, 0)))


static func room_for(inv: InventoryData, type: ResourceData.ResourceType) -> int:
	if inv == null:
		return 0
	var n := 0
	while n < MAX_QTY and inv.can_add_item(type, n + 1):
		n += 1
	return n


static func free_count(inv: InventoryData, reserved: int, type: ResourceData.ResourceType) -> int:
	if inv == null:
		return 0
	return maxi(0, inv.get_count(type) - maxi(reserved, 0))


static func home_woman(building: Node) -> Node:
	if building == null or not is_instance_valid(building):
		return null
	if not building.has_meta(ASSIGNED_META):
		return null
	var woman: Variant = building.get_meta(ASSIGNED_META)
	if woman == null or not is_instance_valid(woman) or not (woman is Node):
		return null
	if woman.has_method("is_dead") and woman.is_dead():
		return null
	if not woman.has_meta(HOME_META) or woman.get_meta(HOME_META) != building:
		return null
	return woman as Node


static func next_action(hut: InventoryData, claim: InventoryData, kind: String, claim_reserved: Dictionary = {}) -> Dictionary:
	var none := {"kind": "none", "type": ResourceData.ResourceType.NONE, "qty": 0}
	if hut == null or claim == null or not HutSpecialtyScript.is_known(kind):
		return none
	var blocked := _blocking_output(hut, kind)
	if blocked != ResourceData.ResourceType.NONE:
		var blocked_qty := carry_qty(hut.get_count(blocked), room_for(claim, blocked))
		if blocked_qty > 0:
			return {"kind": "output", "type": blocked, "qty": blocked_qty}
	var products: Array = PRODUCTS.get(kind, [])
	for type in products:
		var item_type: ResourceData.ResourceType = type
		if item_type == blocked:
			continue
		var out_qty := carry_qty(hut.get_count(item_type), room_for(claim, item_type))
		if out_qty > 0:
			return {"kind": "output", "type": item_type, "qty": out_qty}
	if kind == "crop":
		return {"kind": "wait", "type": ResourceData.ResourceType.GRAIN, "qty": 0}
	var missing := _missing_input(hut, claim, kind, claim_reserved)
	if missing == ResourceData.ResourceType.NONE:
		return none
	var have := free_count(claim, int(claim_reserved.get(int(missing), 0)), missing)
	var in_qty := carry_qty(have, room_for(hut, missing))
	if in_qty <= 0:
		return none
	return {"kind": "input", "type": missing, "qty": in_qty}


static func apply_move(hut: InventoryData, claim: InventoryData, kind: String, claim_reserved: Dictionary = {}) -> Dictionary:
	if not HutSpecialtyScript.sim_authority_ok():
		return {"kind": "none", "type": ResourceData.ResourceType.NONE, "qty": 0}
	var action := next_action(hut, claim, kind, claim_reserved)
	var moved := {"kind": action["kind"], "type": action["type"], "qty": 0}
	if str(action["kind"]) == "output":
		moved["qty"] = _transfer(hut, claim, action["type"], int(action["qty"]))
	elif str(action["kind"]) == "input":
		moved["qty"] = _transfer(claim, hut, action["type"], int(action["qty"]))
	_log_transfer("asleep", str(moved["kind"]), int(moved["type"]), int(moved["qty"]))
	return moved


static func destroy_hands(npc: Node) -> void:
	if npc == null or not is_instance_valid(npc):
		return
	var inv = npc.get("inventory")
	if inv == null or not inv.has_method("set_slot"):
		return
	for i in int(inv.slot_count):
		inv.set_slot(i, {})


## Full drop that cannot return to the origin. Hut if it fits, otherwise the caller drops the returned stack on the ground.
static func unstick_hands(holder: InventoryData, hut_inv: InventoryData) -> Dictionary:
	if holder == null:
		return {"where": "empty", "type": 0, "qty": 0}
	var slot: Dictionary = holder.get_slot(0)
	if slot.is_empty():
		return {"where": "empty", "type": 0, "qty": 0}
	var item_type: int = int(slot.get("type", 0))
	var count: int = int(slot.get("count", 0))
	if return_stack(holder, hut_inv):
		_log_transfer("live", "", item_type, count, "stuck")
		return {"where": "hut", "type": item_type, "qty": count}
	for i in holder.slot_count:
		holder.set_slot(i, {})
	_log_transfer("live", "", item_type, count, "stuck")
	return {"where": "ground", "type": item_type, "qty": count}


static func return_stack(holder: InventoryData, origin: InventoryData) -> bool:
	if holder == null or origin == null:
		return false
	var slot: Dictionary = holder.get_slot(0)
	if slot.is_empty():
		return true
	var type: ResourceData.ResourceType = slot.get("type", ResourceData.ResourceType.NONE)
	var count: int = int(slot.get("count", 0))
	if count <= 0 or not origin.can_add_item(type, count):
		return false
	if not holder.remove_item(type, count):
		return false
	if not origin.add_item(type, count):
		holder.add_item(type, count)
		return false
	return true


static func _log_transfer(mode: String, kind: String, item_type: int, qty: int, phase: String = "") -> void:
	if qty <= 0:
		return
	var loop := Engine.get_main_loop()
	if not (loop is SceneTree):
		return
	var pi: Node = (loop as SceneTree).root.get_node_or_null("PlaytestInstrumentor")
	if pi and pi.has_method("hut_carry_transfer"):
		pi.call("hut_carry_transfer", mode, kind, item_type, qty, phase)


static func _transfer(src: InventoryData, dest: InventoryData, type: ResourceData.ResourceType, qty: int) -> int:
	var amount := carry_qty(src.get_count(type), room_for(dest, type))
	amount = mini(amount, qty)
	if amount <= 0:
		return 0
	if not src.remove_item(type, amount):
		return 0
	if not dest.add_item(type, amount):
		src.add_item(type, amount)
		return 0
	return amount


static func _blocking_output(hut: InventoryData, kind: String) -> ResourceData.ResourceType:
	var inputs: Array = HutSpecialtyScript.recipe_inputs(hut, kind)
	if kind != "crop" and inputs.is_empty():
		return ResourceData.ResourceType.NONE
	for row in inputs:
		if hut.get_count(row["type"]) < int(row["qty"]):
			return ResourceData.ResourceType.NONE
	for row in HutSpecialtyScript.recipe_outputs(hut, kind):
		if not hut.can_add_item(row["type"], int(row["qty"])):
			if hut.get_count(row["type"]) > 0:
				return row["type"]
	return ResourceData.ResourceType.NONE


static func _missing_input(hut: InventoryData, claim: InventoryData, kind: String, claim_reserved: Dictionary) -> ResourceData.ResourceType:
	if kind == "oven":
		if hut.get_count(ResourceData.ResourceType.GRAIN) < 1 and free_count(claim, int(claim_reserved.get(int(ResourceData.ResourceType.GRAIN), 0)), ResourceData.ResourceType.GRAIN) > 0:
			return ResourceData.ResourceType.GRAIN
		if hut.get_count(ResourceData.ResourceType.WOOD) < 1 and free_count(claim, int(claim_reserved.get(int(ResourceData.ResourceType.WOOD), 0)), ResourceData.ResourceType.WOOD) > 0:
			return ResourceData.ResourceType.WOOD
		return ResourceData.ResourceType.NONE
	if kind == "rack":
		if hut.get_count(ResourceData.ResourceType.HIDE) < 1 and free_count(claim, int(claim_reserved.get(int(ResourceData.ResourceType.HIDE), 0)), ResourceData.ResourceType.HIDE) > 0:
			return ResourceData.ResourceType.HIDE
		return ResourceData.ResourceType.NONE
	if kind == "weaver":
		if hut.get_count(ResourceData.ResourceType.FIBER) >= 1 or hut.get_count(ResourceData.ResourceType.WOOL) >= 1:
			return ResourceData.ResourceType.NONE
		if free_count(claim, int(claim_reserved.get(int(ResourceData.ResourceType.FIBER), 0)), ResourceData.ResourceType.FIBER) > 0:
			return ResourceData.ResourceType.FIBER
		if free_count(claim, int(claim_reserved.get(int(ResourceData.ResourceType.WOOL), 0)), ResourceData.ResourceType.WOOL) > 0:
			return ResourceData.ResourceType.WOOL
	return ResourceData.ResourceType.NONE
