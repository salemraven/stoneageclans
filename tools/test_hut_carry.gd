extends SceneTree
## Woman specialty-hut carry. Run: godot --path . --headless -s res://tools/test_hut_carry.gd

const HutCarryScript = preload("res://scripts/buildings/hut_carry.gd")
const HutSpecialtyScript = preload("res://scripts/buildings/hut_specialty.gd")
const ClanBrainScript = preload("res://scripts/ai/clan_brain.gd")

var _passed := 0
var _failed := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_slots()
	_test_owner()
	_test_moves()
	_test_hands()
	_test_grain()
	_test_old_oven()
	_test_reserved_stock()
	_test_authority()
	_test_unstick()
	_test_park_camp()
	_test_tick_budget()
	print("HUT_CARRY_TEST passed=%d failed=%d" % [_passed, _failed])
	quit(0 if _failed == 0 else 1)


class HutStub extends Node:
	var inventory: InventoryData
	var hut_specialty: String = ""
	var building_type: int = 0


func _inv(slots: int, stack: int) -> InventoryData:
	return InventoryData.new(slots, true, stack)


func _test_slots() -> void:
	var woman := NPCBase.new()
	woman.npc_type = "woman"
	woman._initialize_inventory()
	var man := NPCBase.new()
	man.npc_type = "clansman"
	man._initialize_inventory()
	if woman.inventory.slot_count == 1 and woman.inventory.max_stack == 5 and woman.inventory.can_stack and woman.inventory.get_slot(0).is_empty():
		_pass("woman has one empty stack of 5")
	else:
		_fail("woman has one empty stack of 5", str(woman.inventory.slot_count))
	if man.inventory.slot_count == 5 and not man.inventory.can_stack:
		_pass("clansman inventory unchanged")
	else:
		_fail("clansman inventory unchanged", str(man.inventory.slot_count))


func _test_owner() -> void:
	var brain = ClanBrainScript.new()
	var oven_woman := Node.new()
	var other := Node.new()
	var hut := Node.new()
	brain.work_requests.append({
		"state": "PENDING",
		"owner": oven_woman,
		"building": hut,
		"npc": null,
	})
	if brain.claim_work_request(other).is_empty() and brain.claim_work_request(oven_woman).get("npc") == oven_woman:
		_pass("only the home woman claims the request")
	else:
		_fail("only the home woman claims the request", "")


func _test_moves() -> void:
	var hut := _inv(6, 20)
	var claim := _inv(8, 20)
	claim.add_item(ResourceData.ResourceType.GRAIN, 10)
	claim.add_item(ResourceData.ResourceType.WOOD, 10)
	var first := HutCarryScript.apply_move(hut, claim, "oven")
	var second := HutCarryScript.apply_move(hut, claim, "oven")
	if int(first["qty"]) == 5 and int(first["type"]) == int(ResourceData.ResourceType.GRAIN) and hut.get_count(ResourceData.ResourceType.GRAIN) == 5 and int(second["type"]) == int(ResourceData.ResourceType.WOOD):
		_pass("oven brings grain then wood, and does not move the same stack twice")
	else:
		_fail("oven brings grain then wood, and does not move the same stack twice", str(first))
	if hut.get_count(ResourceData.ResourceType.BREAD) == 0:
		_pass("carry does not bake")
	else:
		_fail("carry does not bake", str(hut.get_count(ResourceData.ResourceType.BREAD)))
	var grain_only := _inv(6, 20)
	grain_only.add_item(ResourceData.ResourceType.GRAIN, 5)
	var wood_claim := _inv(4, 20)
	wood_claim.add_item(ResourceData.ResourceType.WOOD, 5)
	var wood_trip := HutCarryScript.next_action(grain_only, wood_claim, "oven")
	if str(wood_trip["kind"]) == "input" and int(wood_trip["type"]) == int(ResourceData.ResourceType.WOOD):
		_pass("grain without wood does not stay")
	else:
		_fail("grain without wood does not stay", str(wood_trip))
	var tight := _inv(1, 2)
	var full_hut := _inv(6, 20)
	full_hut.add_item(ResourceData.ResourceType.BREAD, 5)
	var small := HutCarryScript.next_action(full_hut, tight, "oven")
	if str(small["kind"]) == "output" and int(small["qty"]) == 2:
		_pass("product trip takes only what the claim can hold")
	else:
		_fail("product trip takes only what the claim can hold", str(small))
	var before := HutCarryScript.next_action(full_hut, _inv(4, 20), "oven")
	var empty_inputs := _inv(6, 20)
	empty_inputs.add_item(ResourceData.ResourceType.GRAIN, 1)
	var input_trip := HutCarryScript.next_action(empty_inputs, claim, "oven")
	if str(before["kind"]) == "output" and str(input_trip["kind"]) == "input":
		_pass("product trip runs before an input trip")
	else:
		_fail("product trip runs before an input trip", str(before))
	if HutCarryScript.carry_qty(3, 5) == 3 and HutCarryScript.carry_qty(0, 5) == 0:
		_pass("pickup takes what remains and stops at zero")
	else:
		_fail("pickup takes what remains and stops at zero", "")
	var rack := _inv(6, 4)
	rack.add_item(ResourceData.ResourceType.CORDAGE, 4)
	rack.add_item(ResourceData.ResourceType.HIDE, 1)
	rack.add_item(ResourceData.ResourceType.STONE, 4)
	rack.add_item(ResourceData.ResourceType.WOOD, 4)
	rack.add_item(ResourceData.ResourceType.FIBER, 4)
	rack.add_item(ResourceData.ResourceType.BONE, 4)
	var blocked := HutCarryScript.next_action(rack, _inv(4, 20), "rack")
	if str(blocked["kind"]) == "output" and int(blocked["type"]) == int(ResourceData.ResourceType.CORDAGE):
		_pass("blocked cordage is carried instead of waiting")
	else:
		_fail("blocked cordage is carried instead of waiting", str(blocked))
	var asleep_hut := _inv(6, 20)
	var asleep_claim := _inv(8, 20)
	asleep_claim.add_item(ResourceData.ResourceType.GRAIN, 5)
	HutCarryScript.apply_move(asleep_hut, asleep_claim, "oven")
	var again := HutCarryScript.apply_move(asleep_hut, asleep_claim, "oven")
	if asleep_hut.get_count(ResourceData.ResourceType.GRAIN) == 5 and int(again["qty"]) == 0:
		_pass("second asleep tick does not move the same stack")
	else:
		_fail("second asleep tick does not move the same stack", str(again))
	var idle := Node.new()
	var ticking := Node.new()
	root.add_child(ticking)
	ticking.set_process(true)
	if not HutSpecialtyScript.live_is_ticking(idle) and HutSpecialtyScript.live_is_ticking(ticking):
		_pass("a processing hut is the one the asleep move skips")
	else:
		_fail("a processing hut is the one the asleep move skips", "")
	ticking.queue_free()


func _test_hands() -> void:
	var hands := _inv(1, 5)
	var origin := _inv(4, 20)
	hands.add_item(ResourceData.ResourceType.GRAIN, 3)
	var claim_before := 4
	origin.add_item(ResourceData.ResourceType.GRAIN, claim_before)
	var woman := HutStub.new()
	woman.inventory = hands
	HutCarryScript.destroy_hands(woman)
	if hands.get_count(ResourceData.ResourceType.GRAIN) == 0 and origin.get_count(ResourceData.ResourceType.GRAIN) == claim_before:
		_pass("combat destroy deletes her stack and does not refund the claim")
	else:
		_fail("combat destroy deletes her stack and does not refund the claim", str(hands.get_count(ResourceData.ResourceType.GRAIN)))
	var again := _inv(1, 5)
	again.add_item(ResourceData.ResourceType.GRAIN, 3)
	if HutCarryScript.return_stack(again, origin) and again.get_count(ResourceData.ResourceType.GRAIN) == 0 and origin.get_count(ResourceData.ResourceType.GRAIN) == claim_before + 3:
		_pass("a failed drop returns the stack")
	else:
		_fail("a failed drop returns the stack", str(origin.get_count(ResourceData.ResourceType.GRAIN)))
	var hut := HutStub.new()
	hut.inventory = _inv(6, 20)
	hut.inventory.add_item(ResourceData.ResourceType.HIDE, 2)
	hut.hut_specialty = "rack"
	hut.building_type = ResourceData.ResourceType.LIVING_HUT
	HutSpecialtyScript.dismantle(hut)
	if str(hut.hut_specialty) == "" and hut.inventory.get_count(ResourceData.ResourceType.HIDE) == 2:
		_pass("dismantle ends production and leaves hut goods")
	else:
		_fail("dismantle ends production and leaves hut goods", str(hut.get("hut_specialty")))


func _test_grain() -> void:
	if not ResourceData.can_eat(ResourceData.DietType.OMNIVORE, ResourceData.ResourceType.GRAIN) and not ResourceData.is_food(ResourceData.ResourceType.GRAIN):
		_pass("people do not eat grain")
	else:
		_fail("people do not eat grain", "")
	if ResourceData.can_eat(ResourceData.DietType.HERBIVORE, ResourceData.ResourceType.GRAIN):
		_pass("a sheep can still eat grain")
	else:
		_fail("a sheep can still eat grain", "")


func _test_reserved_stock() -> void:
	var hut := _inv(6, 20)
	var claim := _inv(8, 20)
	claim.add_item(ResourceData.ResourceType.GRAIN, 5)
	claim.add_item(ResourceData.ResourceType.WOOD, 5)
	var reserved := {int(ResourceData.ResourceType.GRAIN): 5}
	var action := HutCarryScript.next_action(hut, claim, "oven", reserved)
	if str(action["kind"]) == "input" and int(action["type"]) == int(ResourceData.ResourceType.WOOD):
		_pass("reserved grain is skipped so the next hut takes wood")
	else:
		_fail("reserved grain is skipped so the next hut takes wood", str(action))
	var all_held := {
		int(ResourceData.ResourceType.GRAIN): 5,
		int(ResourceData.ResourceType.WOOD): 5,
	}
	var none := HutCarryScript.next_action(hut, claim, "oven", all_held)
	if str(none["kind"]) == "none":
		_pass("fully reserved claim stock issues no input trip")
	else:
		_fail("fully reserved claim stock issues no input trip", str(none))


class CraftStub extends Node:
	var hut_specialty: String = "crop"
	var hut_craft_timer: float = 0.0
	var hut_live_frame: int = -1
	var inventory: InventoryData
	var building_type: int = 0


class TickBrain extends RefCounted:
	var ticks: int = 0
	func set_dormant(_value: bool) -> void:
		pass
	func dormant_update(_delta: float) -> void:
		ticks += 1


class CampProbe extends Node2D:
	var player_owned: bool = false
	var clan_name: String = ""
	var clan_brain: TickBrain


class FakeMain extends Node:
	var npcs_container: Node = null
	var spawned: Array = []
	func spawn_npc_from_sleep_data(data: Dictionary, parent: Node) -> void:
		var body := NPCBase.new()
		body.npc_type = str(data.get("npc_type", "woman"))
		body.clan_name = str(data.get("clan_name", ""))
		body.npc_name = str(data.get("name", "restored"))
		parent.add_child(body)
		body.add_to_group("npcs")
		spawned.append(body)


func _test_authority() -> void:
	var hut := _inv(6, 20)
	var claim := _inv(8, 20)
	claim.add_item(ResourceData.ResourceType.GRAIN, 5)
	HutSpecialtyScript.block_sim_for_test = true
	var blocked: Dictionary = HutCarryScript.apply_move(hut, claim, "oven")
	var stub := CraftStub.new()
	stub.inventory = _inv(6, 20)
	var crafted: bool = HutSpecialtyScript.advance(stub, 999.0, false)
	HutSpecialtyScript.block_sim_for_test = false
	if int(blocked.get("qty", 0)) == 0 and hut.get_count(ResourceData.ResourceType.GRAIN) == 0 and not crafted and stub.inventory.get_count(ResourceData.ResourceType.GRAIN) == 0:
		_pass("a non-server flag skips carry and craft")
	else:
		_fail("a non-server flag skips carry and craft", str(blocked))
	stub.free()


func _test_unstick() -> void:
	var hands := _inv(1, 5)
	var hut := _inv(1, 5)
	hands.add_item(ResourceData.ResourceType.BREAD, 5)
	var home: Dictionary = HutCarryScript.unstick_hands(hands, hut)
	if str(home.get("where", "")) == "hut" and hands.get_slot(0).is_empty() and hut.get_count(ResourceData.ResourceType.BREAD) == 5:
		_pass("a stuck stack returns to the hut when it fits")
	else:
		_fail("a stuck stack returns to the hut when it fits", str(home))
	var full := _inv(1, 5)
	var held := _inv(1, 5)
	full.add_item(ResourceData.ResourceType.WOOD, 5)
	held.add_item(ResourceData.ResourceType.BREAD, 5)
	var ground: Dictionary = HutCarryScript.unstick_hands(held, full)
	if str(ground.get("where", "")) == "ground" and int(ground.get("qty", 0)) == 5 and held.get_slot(0).is_empty() and full.get_count(ResourceData.ResourceType.WOOD) == 5:
		_pass("a stuck stack leaves her hands when the hut is full")
	else:
		_fail("a stuck stack leaves her hands when the hut is full", str(ground))
	var woman := NPCBase.new()
	woman.npc_type = "woman"
	woman._initialize_inventory()
	woman.inventory.add_item(ResourceData.ResourceType.BREAD, 5)
	var hut_inv := _inv(1, 5)
	var claim_inv := _inv(1, 5)
	hut_inv.add_item(ResourceData.ResourceType.WOOD, 5)
	claim_inv.add_item(ResourceData.ResourceType.WOOD, 5)
	var hut_b := CraftStub.new()
	var claim_b := CraftStub.new()
	hut_b.inventory = hut_inv
	claim_b.inventory = claim_inv
	hut_b.hut_specialty = "oven"
	var task_script: GDScript = ResourceLoader.load("res://scripts/ai/tasks/hut_carry_task.gd", "", ResourceLoader.CACHE_MODE_IGNORE) as GDScript
	if task_script == null or not task_script.can_instantiate():
		_fail("a timed-out drop finishes with empty hands", "task script did not compile")
		woman.free()
		hut_b.free()
		claim_b.free()
		return
	var task: RefCounted = task_script.new(hut_b, claim_b)
	task.call("_drop_at", woman, hut_b, claim_b)
	OS.delay_msec(2200)
	var status: int = int(task.call("_drop_at", woman, hut_b, claim_b))
	if status == Task.TaskStatus.SUCCESS and woman.inventory.get_slot(0).is_empty() and str(task.get("_phase")) == "done":
		_pass("a timed-out drop finishes with empty hands")
	else:
		_fail("a timed-out drop finishes with empty hands", "status=%s phase=%s" % [status, task._phase])
	woman.free()
	hut_b.free()
	claim_b.free()


func _test_park_camp() -> void:
	var main := FakeMain.new()
	main.name = "ParkTestMain"
	main.add_to_group("main")
	root.add_child(main)
	var people := Node2D.new()
	main.add_child(people)
	main.npcs_container = people
	var world := Node2D.new()
	root.add_child(world)
	var chunk := Node2D.new()
	world.add_child(chunk)
	var claim := LandClaim.new()
	claim.clan_name = "PARKTEST"
	claim.player_owned = false
	chunk.add_child(claim)
	var hut := BuildingBase.new()
	hut.building_type = ResourceData.ResourceType.LIVING_HUT
	hut.clan_name = "PARKTEST"
	world.add_child(hut)
	hut.hut_specialty = "crop"
	var index: Node = root.get_node("ClaimBuildingIndex")
	index.call("register_building", hut, claim)
	var woman := NPCBase.new()
	woman.npc_type = "woman"
	woman.clan_name = "PARKTEST"
	woman.npc_name = "ParkWoman"
	woman.add_to_group("npcs")
	world.add_child(woman)
	var coords := Vector2i(9, 4)
	var camps: Node = root.get_node("OffscreenCamps")
	camps.call("park_claim", claim, coords)
	var pop: int = 0
	if claim.clan_brain and claim.clan_brain.roster:
		pop = int(claim.clan_brain.roster.call("get_population"))
	var parked_ok: bool = claim.get_parent() == camps and hut.get_parent() == camps and not claim.is_processing() and not hut.is_processing() and pop >= 1
	if parked_ok:
		_pass("unload parks the claim, its hut, and the roster")
	else:
		_fail("unload parks the claim, its hut, and the roster", "pop=%d claim_parent=%s hut_parent=%s" % [pop, claim.get_parent(), hut.get_parent()])
	woman.free()
	var before: int = hut.inventory.get_count(ResourceData.ResourceType.GRAIN)
	HutSpecialtyScript.advance(hut, 500.0, false)
	if hut.inventory.get_count(ResourceData.ResourceType.GRAIN) > before:
		_pass("a parked hut still crafts while it is not processing")
	else:
		_fail("a parked hut still crafts while it is not processing", str(hut.inventory.get_count(ResourceData.ResourceType.GRAIN)))
	var restored: bool = bool(camps.call("restore_chunk", coords, chunk))
	var claims := 0
	for node in root.find_children("", "LandClaim", true, false):
		if str(node.get("clan_name")) == "PARKTEST":
			claims += 1
	var women := 0
	for body in main.spawned:
		if is_instance_valid(body) and str(body.get("npc_type")) == "woman":
			women += 1
	if restored and claim.get_parent() == chunk and hut.get_parent() == chunk and claim.is_processing() and claims == 1 and women == 1 and not is_instance_valid(woman):
		_pass("load restores one camp and respawns the woman from the roster")
	else:
		_fail("load restores one camp and respawns the woman from the roster", "restored=%s claims=%d women=%d" % [restored, claims, women])
	camps.call("park_claim", claim, coords)
	var again: bool = bool(camps.call("restore_chunk", coords, chunk))
	var extra: bool = bool(camps.call("restore_chunk", coords, chunk))
	claims = 0
	for node in root.find_children("", "LandClaim", true, false):
		if str(node.get("clan_name")) == "PARKTEST":
			claims += 1
	if again and not extra and claims == 1:
		_pass("a second load does not spawn another claim")
	else:
		_fail("a second load does not spawn another claim", "again=%s extra=%s claims=%d" % [again, extra, claims])
	claim.free()
	hut.free()
	main.free()
	world.free()


func _test_tick_budget() -> void:
	var probes: Array = []
	for i in 3:
		var probe := CampProbe.new()
		probe.clan_name = "BUDGET%d" % i
		probe.clan_brain = TickBrain.new()
		root.add_child(probe)
		root.get_node("OffscreenCamps").call("park_claim", probe, Vector2i(20 + i, 1))
		probes.append(probe)
	var camps: Node = root.get_node("OffscreenCamps")
	camps._process(0.016)
	var ticks := 0
	for probe in probes:
		ticks += (probe as CampProbe).clan_brain.ticks
	if ticks == 2:
		_pass("the off-screen driver advances at most two camps per frame")
	else:
		_fail("the off-screen driver advances at most two camps per frame", str(ticks))
	for probe in probes:
		camps._parked.erase(probe)
		probe.free()


func _test_old_oven() -> void:
	var brain = ClanBrainScript.new()
	if brain._select_production_chains().is_empty():
		_pass("old oven chain is not selected")
	else:
		_fail("old oven chain is not selected", "")


func _pass(name: String) -> void:
	_passed += 1
	print("PASS %s" % name)


func _fail(name: String, detail: String) -> void:
	_failed += 1
	print("FAIL %s %s" % [name, detail])
