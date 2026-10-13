class_name HutSpecialty
extends RefCounted
## Living-hut specialty. One timer. Inputs are spent only when every output fits.

const ART_FALLBACK := "res://assets/sprites/hut.png"
const PLACEHOLDER_ICON := "res://assets/sprites/placeholder_sheet.png"

const SPECIALTIES: Array[String] = ["oven", "weaver", "rack", "crop"]

const ART_CANDIDATES: Dictionary = {
	"": ["res://assets/buildings/living_hut.png", "res://assets/buildings/living hut1.png"],
	"oven": ["res://assets/buildings/oven_hut.png", "res://assets/buildings/oven hut.png", "res://assets/buildings/overn hut.png"],
	"weaver": ["res://assets/buildings/weaver_hut.png", "res://assets/buildings/wool hut.png", "res://assets/buildings/wool_hut.png"],
	"rack": ["res://assets/buildings/leather_hut.png", "res://assets/buildings/leather hut.png"],
	"crop": ["res://assets/buildings/farm_hut.png", "res://assets/buildings/farm hut.png"],
}


static func is_known(kind: String) -> bool:
	return kind in SPECIALTIES


static func display_name(kind: String) -> String:
	match kind:
		"oven": return "Oven"
		"weaver": return "Weaver"
		"rack": return "Leather"
		"crop": return "Crop Hut"
		_: return "Living Hut"


static func progress_product_type(kind: String, inv: InventoryData) -> ResourceData.ResourceType:
	match kind:
		"oven":
			return ResourceData.ResourceType.BREAD
		"rack":
			return ResourceData.ResourceType.LEATHER_SHEET
		"crop":
			return ResourceData.ResourceType.GRAIN
		"weaver":
			if inv != null and inv.get_count(ResourceData.ResourceType.WOOL) >= 1:
				return ResourceData.ResourceType.WOOL_SHEET
			return ResourceData.ResourceType.FIBER_SHEET
		_:
			return ResourceData.ResourceType.NONE


## Active while the hut timer is advancing toward the next craft (inputs + output space OK).
static func craft_progress_display(building: Node) -> Dictionary:
	var out := {"active": false, "ratio": 0.0, "product": int(ResourceData.ResourceType.NONE)}
	if building == null or not is_instance_valid(building):
		return out
	var kind := str(building.get("hut_specialty"))
	if not is_known(kind):
		return out
	var inv: InventoryData = building.get("inventory") as InventoryData
	if inv == null:
		return out
	var needed := craft_time(kind)
	if needed <= 0.0:
		needed = 0.01
	var timer := float(building.get("hut_craft_timer"))
	var can_craft := craft_can_commit(inv, kind)
	if not can_craft and timer <= 0.001:
		return out
	out["active"] = true
	out["ratio"] = clampf(timer / needed, 0.0, 1.0) if can_craft else 0.0
	out["product"] = int(progress_product_type(kind, inv))
	return out


static func craft_time(kind: String) -> float:
	var cfg := _balance()
	match kind:
		"oven":
			return float(cfg.bread_craft_time) if cfg else 90.0
		"weaver":
			return float(cfg.wool_craft_time) if cfg else 45.0
		"rack":
			return float(cfg.drying_rack_process_time) if cfg else 120.0
		"crop":
			return float(cfg.crop_hut_grain_interval) if cfg else 60.0
		_:
			return 1.0


static func _balance() -> Node:
	var loop := Engine.get_main_loop()
	if loop == null or not (loop is SceneTree):
		return null
	return (loop as SceneTree).root.get_node_or_null("BalanceConfig")


static func display_scale(reference_height: float, texture_height: float) -> float:
	if reference_height <= 0.0 or texture_height <= 0.0:
		return 1.0
	return reference_height / texture_height


static func art_path(kind: String) -> String:
	var listed: Array = ART_CANDIDATES.get(kind, []) as Array
	for path in listed:
		var candidate := str(path)
		# FileAccess sees a PNG that Godot has not imported yet. ResourceLoader.exists does not,
		# and that was sending every hut back to the old sprite.
		if FileAccess.file_exists(candidate) or ResourceLoader.exists(candidate):
			return candidate
	return ART_FALLBACK


static func load_texture(path: String) -> Texture2D:
	if path == "":
		return null
	if ResourceLoader.exists(path):
		var imported := load(path) as Texture2D
		if imported != null:
			return imported
	var absolute := ProjectSettings.globalize_path(path)
	if not FileAccess.file_exists(absolute) and not FileAccess.file_exists(path):
		return null
	var image := Image.new()
	var err := image.load(absolute if FileAccess.file_exists(absolute) else path)
	if err != OK:
		return null
	return ImageTexture.create_from_image(image)


static func can_specialize(building: Node) -> bool:
	if building == null or not is_instance_valid(building):
		return false
	if int(building.get("building_type")) != int(ResourceData.ResourceType.LIVING_HUT):
		return false
	return str(building.get("hut_specialty")) == ""


static func specialize(building: Node, claim_inventory: InventoryData, kind: String) -> bool:
	if not can_specialize(building) or not is_known(kind):
		return false
	if claim_inventory == null:
		return false
	if claim_inventory.get_count(ResourceData.ResourceType.WOOD) < 1:
		return false
	if claim_inventory.get_count(ResourceData.ResourceType.STONE) < 1:
		return false
	if not claim_inventory.remove_item(ResourceData.ResourceType.WOOD, 1):
		return false
	if not claim_inventory.remove_item(ResourceData.ResourceType.STONE, 1):
		claim_inventory.add_item(ResourceData.ResourceType.WOOD, 1)
		return false
	building.set("hut_specialty", kind)
	building.set("hut_craft_timer", 0.0)
	if building.has_method("apply_hut_art"):
		building.call("apply_hut_art")
	return true


static func dismantle(building: Node) -> bool:
	if building == null or not is_instance_valid(building):
		return false
	if int(building.get("building_type")) != int(ResourceData.ResourceType.LIVING_HUT):
		return false
	if str(building.get("hut_specialty")) == "":
		return false
	building.set("hut_specialty", "")
	building.set("hut_craft_timer", 0.0)
	if building.has_method("apply_hut_art"):
		building.call("apply_hut_art")
	return true


static func live_is_ticking(building: Node) -> bool:
	if building == null or not is_instance_valid(building):
		return false
	if not building.is_inside_tree():
		return false
	return building.is_processing()


## Tests set this so a client peer is not required to prove the authority guard.
static var block_sim_for_test: bool = false


static func sim_authority_ok() -> bool:
	if block_sim_for_test:
		return false
	var loop := Engine.get_main_loop()
	if not (loop is SceneTree):
		return true
	var mp := (loop as SceneTree).get_multiplayer()
	if mp == null or not mp.has_multiplayer_peer():
		return true
	return mp.is_server()


static func advance(building: Node, delta: float, as_live: bool) -> bool:
	if not sim_authority_ok():
		return false
	if building == null or not is_instance_valid(building):
		return false
	var kind := str(building.get("hut_specialty"))
	if not is_known(kind):
		return false
	var frame := Engine.get_process_frames()
	if as_live:
		building.set("hut_live_frame", frame)
	elif int(building.get("hut_live_frame")) == frame:
		return false
	elif not as_live and live_is_ticking(building):
		return false
	var inv: InventoryData = building.get("inventory") as InventoryData
	if inv == null:
		return false
	var timer := float(building.get("hut_craft_timer")) + delta
	var needed := craft_time(kind)
	if needed <= 0.0:
		needed = 0.01
	var produced := false
	if timer >= needed:
		if _commit(inv, kind):
			produced = true
			timer = 0.0
			building.set_meta("hut_crafts", int(building.get_meta("hut_crafts", 0)) + 1)
			publish_stock(building)
		else:
			timer = 0.0
	building.set("hut_craft_timer", timer)
	return produced


static func advance_if_asleep(building: Node, delta: float) -> bool:
	if live_is_ticking(building):
		return false
	return advance(building, delta, false)


static func recipe_inputs(inv: InventoryData, kind: String) -> Array:
	return _inputs(inv, kind)


static func recipe_outputs(inv: InventoryData, kind: String) -> Array:
	return _outputs_for(inv, kind, _inputs(inv, kind))


static func craft_can_commit(inv: InventoryData, kind: String) -> bool:
	if inv == null or not is_known(kind):
		return false
	var inputs: Array = _inputs(inv, kind)
	var outputs: Array = _outputs_for(inv, kind, inputs)
	if kind != "crop" and inputs.is_empty():
		return false
	for row in inputs:
		if inv.get_count(row["type"]) < int(row["qty"]):
			return false
	for row in outputs:
		if not inv.can_add_item(row["type"], int(row["qty"])):
			return false
	return true


static func _inputs(inv: InventoryData, kind: String) -> Array:
	match kind:
		"oven":
			return [
				{"type": ResourceData.ResourceType.WOOD, "qty": 1},
				{"type": ResourceData.ResourceType.GRAIN, "qty": 1},
			]
		"rack":
			return [{"type": ResourceData.ResourceType.HIDE, "qty": 1}]
		"weaver":
			if inv.get_count(ResourceData.ResourceType.FIBER) >= 1:
				return [{"type": ResourceData.ResourceType.FIBER, "qty": 1}]
			if inv.get_count(ResourceData.ResourceType.WOOL) >= 1:
				return [{"type": ResourceData.ResourceType.WOOL, "qty": 1}]
			return []
		_:
			return []


static func _outputs(kind: String) -> Array:
	match kind:
		"oven":
			return [{"type": ResourceData.ResourceType.BREAD, "qty": 1}]
		"rack":
			return [
				{"type": ResourceData.ResourceType.LEATHER_SHEET, "qty": 1},
				{"type": ResourceData.ResourceType.CORDAGE, "qty": 4},
			]
		"weaver":
			return []
		"crop":
			return [{"type": ResourceData.ResourceType.GRAIN, "qty": 1}]
		_:
			return []


static func _commit(inv: InventoryData, kind: String) -> bool:
	var inputs: Array = _inputs(inv, kind)
	var outputs: Array = _outputs_for(inv, kind, inputs)
	if kind != "crop" and inputs.is_empty():
		return false
	for row in inputs:
		if inv.get_count(row["type"]) < int(row["qty"]):
			return false
	for row in outputs:
		if not inv.can_add_item(row["type"], int(row["qty"])):
			return false
	for row in inputs:
		if not inv.remove_item(row["type"], int(row["qty"])):
			return false
	var placed: Array = []
	for row in outputs:
		if not inv.add_item(row["type"], int(row["qty"])):
			for done in placed:
				inv.remove_item(done["type"], int(done["qty"]))
			for back in inputs:
				inv.add_item(back["type"], int(back["qty"]))
			return false
		placed.append(row)
	return true


static func inventory_rows(inv: InventoryData) -> Array:
	var rows: Array = []
	if inv == null:
		return rows
	for slot in inv.slots:
		if slot == null or not (slot is Dictionary):
			continue
		var rec: Dictionary = slot as Dictionary
		var count: int = int(rec.get("count", 0))
		if count <= 0:
			continue
		rows.append({"type": int(rec.get("type", 0)), "count": count})
	return rows


static func publish_stock(building: Node) -> void:
	if building == null or not is_instance_valid(building) or not sim_authority_ok():
		return
	if not building.has_meta("hut_net_id"):
		return
	var claim: Node = building.get("land_claim") as Node
	if claim == null or not (claim.get("inventory") is InventoryData):
		return
	var loop := Engine.get_main_loop()
	if not (loop is SceneTree):
		return
	var sync: Node = (loop as SceneTree).root.get_node_or_null("GameSync")
	if sync and sync.has_method("publish_hut_stock"):
		sync.call(
			"publish_hut_stock",
			str(claim.get("clan_name")),
			str(building.get_meta("hut_net_id")),
			inventory_rows(building.get("inventory") as InventoryData),
			inventory_rows(claim.get("inventory") as InventoryData)
		)


static func _outputs_for(inv: InventoryData, kind: String, inputs: Array) -> Array:
	if kind == "weaver":
		if inputs.is_empty():
			return []
		var used: ResourceData.ResourceType = inputs[0]["type"]
		if used == ResourceData.ResourceType.WOOL:
			return [{"type": ResourceData.ResourceType.WOOL_SHEET, "qty": 1}]
		return [{"type": ResourceData.ResourceType.FIBER_SHEET, "qty": 1}]
	return _outputs(kind)
