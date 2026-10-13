extends SceneTree
## Living hut specialty. Run: godot --path . --headless -s res://tools/test_hut_specialty.gd

const HutSpecialtyScript = preload("res://scripts/buildings/hut_specialty.gd")
const ProductionConfigScript = preload("res://scripts/config/production_config.gd")
const ProductionComponentScript = preload("res://scripts/buildings/components/production_component.gd")

var _passed := 0
var _failed := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== HUT_SPECIALTY_TEST start ===")
	_test_menu()
	_test_pay_rules()
	_test_oven()
	_test_one_bread()
	_test_rack()
	_test_weaver()
	_test_crop()
	_test_dismantle_mid_craft()
	_test_identity()
	_test_old_buildings()
	_test_enums()
	_test_art()
	print("HUT_SPECIALTY_TEST passed=%d failed=%d" % [_passed, _failed])
	quit(0 if _failed == 0 else 1)


func _hut() -> BuildingBase:
	var hut := BuildingBase.new()
	hut.building_type = ResourceData.ResourceType.LIVING_HUT
	hut.inventory = InventoryData.new(6, true, 20)
	return hut


func _claim() -> InventoryData:
	var inv := InventoryData.new(8, true, 99)
	inv.add_item(ResourceData.ResourceType.WOOD, 5)
	inv.add_item(ResourceData.ResourceType.STONE, 5)
	return inv


func _test_menu() -> void:
	var names: PackedStringArray = PackedStringArray()
	for building in BuildingRegistry.get_menu_buildings():
		names.append(building.display_name)
	if names.has("Living Hut") and names.has("Supply Hut") and names.has("Shrine"):
		_pass("menu keeps living hut, supply, shrine")
	else:
		_fail("menu keeps living hut, supply, shrine", ",".join(names))
	var banned := ["Oven", "Farm", "Dairy Farm", "Drying Rack"]
	var leaked := ""
	for banned_name in banned:
		if names.has(banned_name):
			leaked = banned_name
	if leaked == "":
		_pass("menu hides old production cards")
	else:
		_fail("menu hides old production cards", leaked)


func _test_pay_rules() -> void:
	var hut := _hut()
	var claim := _claim()
	if HutSpecialtyScript.specialize(hut, claim, "oven") and hut.hut_specialty == "oven" and claim.get_count(ResourceData.ResourceType.WOOD) == 4 and claim.get_count(ResourceData.ResourceType.STONE) == 4:
		_pass("specialize spends claim wood and stone")
	else:
		_fail("specialize spends claim wood and stone", hut.hut_specialty)
	var wood_after := claim.get_count(ResourceData.ResourceType.WOOD)
	if not HutSpecialtyScript.specialize(hut, claim, "weaver") and hut.hut_specialty == "oven" and claim.get_count(ResourceData.ResourceType.WOOD) == wood_after:
		_pass("second specialize does not switch or spend")
	else:
		_fail("second specialize does not switch or spend", hut.hut_specialty)
	var bag := InventoryData.new(8, true, 99)
	bag.add_item(ResourceData.ResourceType.WOOD, 5)
	bag.add_item(ResourceData.ResourceType.STONE, 5)
	var poor := InventoryData.new(8, true, 99)
	var fresh := _hut()
	if not HutSpecialtyScript.specialize(fresh, poor, "oven") and fresh.hut_specialty == "" and bag.get_count(ResourceData.ResourceType.WOOD) == 5:
		_pass("player bag does not pay")
	else:
		_fail("player bag does not pay", fresh.hut_specialty)
	var supply := _hut()
	supply.building_type = ResourceData.ResourceType.SUPPLY_HUT
	var oven := _hut()
	oven.building_type = ResourceData.ResourceType.OVEN
	if not HutSpecialtyScript.specialize(supply, claim, "oven") and not HutSpecialtyScript.specialize(oven, claim, "rack"):
		_pass("supply hut and old oven refuse specialize")
	else:
		_fail("supply hut and old oven refuse specialize", "")
	var before_wood := claim.get_count(ResourceData.ResourceType.WOOD)
	if HutSpecialtyScript.dismantle(hut) and hut.hut_specialty == "" and claim.get_count(ResourceData.ResourceType.WOOD) == before_wood:
		_pass("dismantle refunds nothing")
	else:
		_fail("dismantle refunds nothing", hut.hut_specialty)
	if not HutSpecialtyScript.dismantle(hut):
		_pass("dismantle of empty hut is a no-op")
	else:
		_fail("dismantle of empty hut is a no-op", "")
	if HutSpecialtyScript.specialize(hut, claim, "weaver") and hut.hut_specialty == "weaver":
		_pass("specialize works again after dismantle")
	else:
		_fail("specialize works again after dismantle", hut.hut_specialty)


func _test_oven() -> void:
	var hut := _hut()
	hut.hut_specialty = "oven"
	hut.inventory.add_item(ResourceData.ResourceType.GRAIN, 1)
	hut.inventory.add_item(ResourceData.ResourceType.WOOD, 1)
	var step := HutSpecialtyScript.craft_time("oven")
	if HutSpecialtyScript.advance(hut, step, true) and hut.inventory.get_count(ResourceData.ResourceType.BREAD) == 1 and hut.inventory.get_count(ResourceData.ResourceType.GRAIN) == 0:
		_pass("oven specialty bakes bread")
	else:
		_fail("oven specialty bakes bread", str(hut.inventory.get_count(ResourceData.ResourceType.BREAD)))
	var bare := _hut()
	bare.hut_specialty = "oven"
	bare.inventory.add_item(ResourceData.ResourceType.WOOD, 1)
	HutSpecialtyScript.advance(bare, step, true)
	if bare.inventory.get_count(ResourceData.ResourceType.BREAD) == 0 and bare.inventory.get_count(ResourceData.ResourceType.WOOD) == 1:
		_pass("oven without grain does not spend wood")
	else:
		_fail("oven without grain does not spend wood", "")
	var full := BuildingBase.new()
	full.building_type = ResourceData.ResourceType.LIVING_HUT
	full.hut_specialty = "oven"
	full.inventory = InventoryData.new(6, true, 5)
	full.inventory.add_item(ResourceData.ResourceType.BREAD, 5)
	full.inventory.add_item(ResourceData.ResourceType.GRAIN, 1)
	full.inventory.add_item(ResourceData.ResourceType.WOOD, 1)
	full.inventory.add_item(ResourceData.ResourceType.STONE, 5)
	full.inventory.add_item(ResourceData.ResourceType.FIBER, 5)
	full.inventory.add_item(ResourceData.ResourceType.BONE, 5)
	HutSpecialtyScript.advance(full, step, true)
	if full.inventory.get_count(ResourceData.ResourceType.GRAIN) == 1 and full.inventory.get_count(ResourceData.ResourceType.WOOD) == 1:
		_pass("full bread stack does not eat inputs")
	else:
		_fail("full bread stack does not eat inputs", "")


func _test_one_bread() -> void:
	var hut := _hut()
	hut.hut_specialty = "oven"
	hut.inventory.add_item(ResourceData.ResourceType.GRAIN, 4)
	hut.inventory.add_item(ResourceData.ResourceType.WOOD, 4)
	var claim := InventoryData.new(4, true, 20)
	var step := HutSpecialtyScript.craft_time("oven")
	HutSpecialtyScript.advance(hut, step, true)
	HutSpecialtyScript.advance(hut, step, false)
	if hut.inventory.get_count(ResourceData.ResourceType.BREAD) == 1 and claim.get_count(ResourceData.ResourceType.BREAD) == 0:
		_pass("one interval bakes one bread and not the claim pantry")
	else:
		_fail("one interval bakes one bread and not the claim pantry", str(hut.inventory.get_count(ResourceData.ResourceType.BREAD)))


func _test_rack() -> void:
	var hut := _hut()
	hut.hut_specialty = "rack"
	hut.inventory.add_item(ResourceData.ResourceType.HIDE, 1)
	var step := HutSpecialtyScript.craft_time("rack")
	HutSpecialtyScript.advance(hut, step, true)
	if hut.inventory.get_count(ResourceData.ResourceType.LEATHER_SHEET) == 1 and hut.inventory.get_count(ResourceData.ResourceType.CORDAGE) == 4 and hut.inventory.get_count(ResourceData.ResourceType.HIDE) == 0:
		_pass("rack makes a leather sheet and four cordage")
	else:
		_fail("rack makes a leather sheet and four cordage", "sheet=%d cord=%d" % [hut.inventory.get_count(ResourceData.ResourceType.LEATHER_SHEET), hut.inventory.get_count(ResourceData.ResourceType.CORDAGE)])
	var tight := BuildingBase.new()
	tight.building_type = ResourceData.ResourceType.LIVING_HUT
	tight.hut_specialty = "rack"
	tight.inventory = InventoryData.new(6, true, 5)
	tight.inventory.add_item(ResourceData.ResourceType.HIDE, 1)
	tight.inventory.add_item(ResourceData.ResourceType.LEATHER_SHEET, 1)
	tight.inventory.add_item(ResourceData.ResourceType.STONE, 5)
	tight.inventory.add_item(ResourceData.ResourceType.WOOD, 5)
	tight.inventory.add_item(ResourceData.ResourceType.FIBER, 5)
	tight.inventory.add_item(ResourceData.ResourceType.BONE, 5)
	HutSpecialtyScript.advance(tight, step, true)
	if tight.inventory.get_count(ResourceData.ResourceType.HIDE) == 1 and tight.inventory.get_count(ResourceData.ResourceType.LEATHER_SHEET) == 1 and tight.inventory.get_count(ResourceData.ResourceType.CORDAGE) == 0:
		_pass("rack does not spend the hide when cordage does not fit")
	else:
		_fail("rack does not spend the hide when cordage does not fit", "hide=%d" % tight.inventory.get_count(ResourceData.ResourceType.HIDE))


func _test_weaver() -> void:
	var hut := _hut()
	hut.hut_specialty = "weaver"
	hut.inventory.add_item(ResourceData.ResourceType.FIBER, 1)
	hut.inventory.add_item(ResourceData.ResourceType.WOOL, 1)
	HutSpecialtyScript.advance(hut, HutSpecialtyScript.craft_time("weaver"), true)
	if hut.inventory.get_count(ResourceData.ResourceType.FIBER_SHEET) == 1 and hut.inventory.get_count(ResourceData.ResourceType.FIBER) == 0 and hut.inventory.get_count(ResourceData.ResourceType.WOOL) == 1 and hut.inventory.get_count(ResourceData.ResourceType.WOOL_SHEET) == 0:
		_pass("weaver uses fiber before wool")
	else:
		_fail("weaver uses fiber before wool", "")
	var wool_hut := _hut()
	wool_hut.hut_specialty = "weaver"
	wool_hut.inventory.add_item(ResourceData.ResourceType.WOOL, 1)
	HutSpecialtyScript.advance(wool_hut, HutSpecialtyScript.craft_time("weaver"), true)
	if wool_hut.inventory.get_count(ResourceData.ResourceType.WOOL_SHEET) == 1 and wool_hut.inventory.get_count(ResourceData.ResourceType.WOOL) == 0 and wool_hut.inventory.get_count(ResourceData.ResourceType.FIBER_SHEET) == 0:
		_pass("weaver uses wool when there is no fiber")
	else:
		_fail("weaver uses wool when there is no fiber", "")


func _test_crop() -> void:
	var hut := _hut()
	hut.hut_specialty = "crop"
	var step := HutSpecialtyScript.craft_time("crop")
	HutSpecialtyScript.advance(hut, step, true)
	if hut.inventory.get_count(ResourceData.ResourceType.GRAIN) == 1:
		_pass("crop hut adds one grain")
	else:
		_fail("crop hut adds one grain", str(hut.inventory.get_count(ResourceData.ResourceType.GRAIN)))
	hut.inventory.add_item(ResourceData.ResourceType.GRAIN, 1)
	var before := hut.inventory.get_count(ResourceData.ResourceType.GRAIN)
	HutSpecialtyScript.advance(hut, step, true)
	if hut.inventory.get_count(ResourceData.ResourceType.GRAIN) == before + 1:
		_pass("crop hut does not consume grain")
	else:
		_fail("crop hut does not consume grain", str(hut.inventory.get_count(ResourceData.ResourceType.GRAIN)))
	var full := BuildingBase.new()
	full.building_type = ResourceData.ResourceType.LIVING_HUT
	full.hut_specialty = "crop"
	full.inventory = InventoryData.new(2, true, 5)
	full.inventory.add_item(ResourceData.ResourceType.GRAIN, 10)
	var held := full.inventory.get_count(ResourceData.ResourceType.GRAIN)
	HutSpecialtyScript.advance(full, step, true)
	if full.inventory.get_count(ResourceData.ResourceType.GRAIN) == held:
		_pass("full grain stack stops the crop hut")
	else:
		_fail("full grain stack stops the crop hut", str(full.inventory.get_count(ResourceData.ResourceType.GRAIN)))


func _test_dismantle_mid_craft() -> void:
	var hut := _hut()
	var claim := _claim()
	HutSpecialtyScript.specialize(hut, claim, "oven")
	hut.inventory.add_item(ResourceData.ResourceType.GRAIN, 1)
	hut.inventory.add_item(ResourceData.ResourceType.WOOD, 1)
	HutSpecialtyScript.advance(hut, HutSpecialtyScript.craft_time("oven") * 0.5, true)
	HutSpecialtyScript.dismantle(hut)
	if hut.hut_specialty == "" and hut.inventory.get_count(ResourceData.ResourceType.GRAIN) == 1 and hut.inventory.get_count(ResourceData.ResourceType.WOOD) == 1 and hut.inventory.get_count(ResourceData.ResourceType.BREAD) == 0:
		_pass("dismantle mid-craft keeps the inputs")
	else:
		_fail("dismantle mid-craft keeps the inputs", "")


func _test_identity() -> void:
	var hut := _hut()
	var claim := _claim()
	HutSpecialtyScript.specialize(hut, claim, "oven")
	var count := 0
	if hut.building_type == ResourceData.ResourceType.LIVING_HUT:
		count = 1
	var woman := Node2D.new()
	woman.set_meta("home_living_hut", hut)
	var occ := get_root().get_node_or_null("OccupationSystem")
	var home: Node = null
	if occ and occ.has_method("get_home_living_hut"):
		home = occ.get_home_living_hut(woman)
	if hut.building_type == ResourceData.ResourceType.LIVING_HUT and count == 1 and home == hut:
		_pass("specialty hut stays a living hut home")
	else:
		_fail("specialty hut stays a living hut home", str(home))


func _test_old_buildings() -> void:
	var recipe: Dictionary = ProductionConfigScript.get_drying_rack_recipe()
	var output: Dictionary = recipe.get("output", {})
	if int(output.get("type", -1)) == int(ResourceData.ResourceType.LEATHER):
		_pass("old drying rack still outputs leather")
	else:
		_fail("old drying rack still outputs leather", str(output))
	var stub := BuildingBase.new()
	stub.building_type = ResourceData.ResourceType.OVEN
	stub.is_active = true
	stub.inventory = InventoryData.new(6, true, 20)
	stub.inventory.add_item(ResourceData.ResourceType.GRAIN, 1)
	stub.inventory.add_item(ResourceData.ResourceType.WOOD, 1)
	var comp: Node = ProductionComponentScript.new(stub, {
		"inputs": [
			{"type": ResourceData.ResourceType.WOOD, "quantity": 1},
			{"type": ResourceData.ResourceType.GRAIN, "quantity": 1},
		],
		"output": {"type": ResourceData.ResourceType.BREAD, "quantity": 1},
		"craft_time": 1.0,
		"requires_woman": true,
	})
	comp._process(5.0)
	if stub.inventory.get_count(ResourceData.ResourceType.BREAD) == 0 and stub.inventory.get_count(ResourceData.ResourceType.GRAIN) == 1:
		_pass("old oven does not bake without a woman")
	else:
		_fail("old oven does not bake without a woman", "")


func _test_enums() -> void:
	if int(ResourceData.ResourceType.LEATHER_SHEET) > int(ResourceData.ResourceType.COOKED_MEAT) and int(ResourceData.ResourceType.FIBER_SHEET) > int(ResourceData.ResourceType.COOKED_MEAT) and int(ResourceData.ResourceType.WOOL_SHEET) > int(ResourceData.ResourceType.COOKED_MEAT):
		_pass("new sheet items are appended after cooked meat")
	else:
		_fail("new sheet items are appended after cooked meat", "")


func _test_art() -> void:
	var scaled := HutSpecialtyScript.display_scale(40.0, 400.0)
	if is_equal_approx(scaled, 0.1) and not is_equal_approx(scaled, 1.0):
		_pass("tall art scales down to the hut height")
	else:
		_fail("tall art scales down to the hut height", str(scaled))
	if is_equal_approx(HutSpecialtyScript.display_scale(0.0, 400.0), 1.0):
		_pass("missing hut reference does not divide by zero")
	else:
		_fail("missing hut reference does not divide by zero", "")
	var path := HutSpecialtyScript.art_path("not-a-specialty")
	var texture = load(path)
	if path == HutSpecialtyScript.ART_FALLBACK and texture != null:
		_pass("unknown specialty stays on the old hut sprite")
	else:
		_fail("unknown specialty stays on the old hut sprite", path)
	var fallback_tex = load(HutSpecialtyScript.ART_FALLBACK) as Texture2D
	var fallback_height := float(fallback_tex.get_height()) if fallback_tex else 0.0
	var expected := {
		"": "living hut1.png",
		"oven": "oven hut.png",
		"weaver": "wool hut.png",
		"rack": "leather hut.png",
		"crop": "farm hut.png",
	}
	for kind in expected.keys():
		var art := HutSpecialtyScript.art_path(str(kind))
		var art_tex := HutSpecialtyScript.load_texture(art)
		var label: String = "specialty art %s" % str(kind if str(kind) != "" else "living")
		if art != HutSpecialtyScript.ART_FALLBACK and art.ends_with(str(expected[kind])) and art_tex != null and float(art_tex.get_height()) > fallback_height:
			_pass(label)
		else:
			_fail(label, art)


func _pass(name: String) -> void:
	_passed += 1
	print("PASS %s" % name)


func _fail(name: String, detail: String) -> void:
	_failed += 1
	print("FAIL %s %s" % [name, detail])
