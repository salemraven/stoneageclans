extends SceneTree
## Two-process hut stock sync over ENet. Server crafts, client only receives counts.
## Run server: godot --path . --headless -s res://tools/test_hut_stock_sync.gd -- --role=server
## Run client: godot --path . --headless -s res://tools/test_hut_stock_sync.gd -- --role=client

const HutSpecialtyScript = preload("res://scripts/buildings/hut_specialty.gd")
const HutCarryScript = preload("res://scripts/buildings/hut_carry.gd")

const PORT := 47391
const CLAN := "SYNC"

var _passed := 0
var _failed := 0
var _role := "server"


class ClaimStub extends Node2D:
	var clan_name: String = ""
	var inventory: InventoryData


class HutStub extends Node2D:
	var inventory: InventoryData
	var land_claim: Node = null
	var hut_specialty: String = "oven"
	var hut_craft_timer: float = 0.0
	var hut_live_frame: int = -1
	var building_type: int = 0


func _init() -> void:
	for a in OS.get_cmdline_user_args():
		if str(a).begins_with("--role="):
			_role = str(a).substr(7)
	call_deferred("_run")


func _make_camp() -> Array:
	var claim := ClaimStub.new()
	claim.clan_name = CLAN
	claim.inventory = InventoryData.new(8, true, 999)
	claim.add_to_group("land_claims")
	root.add_child(claim)
	var huts: Array = []
	for i in 2:
		var hut := HutStub.new()
		hut.inventory = InventoryData.new(6, true, 999)
		hut.land_claim = claim
		hut.set_meta("hut_net_id", "%s#%d" % [CLAN, i + 1])
		hut.add_to_group("buildings")
		root.add_child(hut)
		huts.append(hut)
	return [claim, huts]


func _run() -> void:
	print("=== HUT_STOCK_SYNC_TEST role=%s ===" % _role)
	if _role == "server":
		await _run_server()
	else:
		await _run_client()
	print("HUT_STOCK_SYNC_TEST role=%s passed=%d failed=%d" % [_role, _passed, _failed])
	quit(0 if _failed == 0 else 1)


func _run_server() -> void:
	var peer := ENetMultiplayerPeer.new()
	if peer.create_server(PORT, 2) != OK:
		_check("server starts", false, "port %d" % PORT)
		return
	root.multiplayer.multiplayer_peer = peer
	var got_peer := false
	for _i in 600:
		await process_frame
		if root.multiplayer.get_peers().size() > 0:
			got_peer = true
			break
		OS.delay_msec(10)
	_check("client connects", got_peer, "")
	if not got_peer:
		return
	_check("server has sim authority", HutSpecialtyScript.sim_authority_ok(), "")
	for _i in 60:
		await process_frame
		OS.delay_msec(10)
	var camp := _make_camp()
	var claim: ClaimStub = camp[0]
	var huts: Array = camp[1]
	claim.inventory.add_item(ResourceData.ResourceType.GRAIN, 7)
	var a: HutStub = huts[0]
	var b: HutStub = huts[1]
	a.inventory.add_item(ResourceData.ResourceType.GRAIN, 2)
	a.inventory.add_item(ResourceData.ResourceType.WOOD, 2)
	b.inventory.add_item(ResourceData.ResourceType.GRAIN, 5)
	b.inventory.add_item(ResourceData.ResourceType.WOOD, 5)
	var baked_a: bool = HutSpecialtyScript.advance(a, 999.0, true)
	await process_frame
	var baked_b1: bool = HutSpecialtyScript.advance(b, 999.0, true)
	await process_frame
	var baked_b2: bool = HutSpecialtyScript.advance(b, 999.0, true)
	_check("server bakes in both ovens", baked_a and baked_b1 and baked_b2 and a.inventory.get_count(ResourceData.ResourceType.BREAD) == 1 and b.inventory.get_count(ResourceData.ResourceType.BREAD) == 2, "")
	var moved: Dictionary = HutCarryScript.apply_move(a.inventory, claim.inventory, "oven")
	_check("server asleep carry moves bread to the claim", int(moved.get("qty", 0)) > 0, str(moved))
	if int(moved.get("qty", 0)) > 0:
		HutSpecialtyScript.publish_stock(a)
	for _i in 300:
		await process_frame
		OS.delay_msec(10)
		if root.multiplayer.get_peers().is_empty():
			break
	_check("server copy was not double-applied", a.inventory.get_count(ResourceData.ResourceType.BREAD) == 0 and claim.inventory.get_count(ResourceData.ResourceType.BREAD) == 1 and b.inventory.get_count(ResourceData.ResourceType.BREAD) == 2, "")


func _run_client() -> void:
	var peer := ENetMultiplayerPeer.new()
	if peer.create_client("127.0.0.1", PORT) != OK:
		_check("client starts", false, "")
		return
	root.multiplayer.multiplayer_peer = peer
	var connected := false
	for _i in 600:
		await process_frame
		if peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
			connected = true
			break
		OS.delay_msec(10)
	_check("client connects to server", connected, "")
	if not connected:
		return
	_check("client has no sim authority", not HutSpecialtyScript.sim_authority_ok(), "")
	var camp := _make_camp()
	var claim: ClaimStub = camp[0]
	var huts: Array = camp[1]
	var a: HutStub = huts[0]
	var b: HutStub = huts[1]
	a.inventory.add_item(ResourceData.ResourceType.GRAIN, 2)
	a.inventory.add_item(ResourceData.ResourceType.WOOD, 2)
	claim.inventory.add_item(ResourceData.ResourceType.GRAIN, 7)
	var baked: bool = HutSpecialtyScript.advance(a, 999.0, true)
	var moved: Dictionary = HutCarryScript.apply_move(a.inventory, claim.inventory, "oven")
	_check("client does not bake", not baked and a.inventory.get_count(ResourceData.ResourceType.BREAD) == 0, "")
	_check("client does not carry", int(moved.get("qty", 0)) == 0 and a.inventory.get_count(ResourceData.ResourceType.GRAIN) == 2, str(moved))
	var synced := false
	for _i in 800:
		await process_frame
		OS.delay_msec(10)
		if b.inventory.get_count(ResourceData.ResourceType.BREAD) == 2 and claim.inventory.get_count(ResourceData.ResourceType.BREAD) == 1:
			synced = true
			break
	_check("client receives counts from the server", synced, "a_bread=%d b_bread=%d claim_bread=%d" % [a.inventory.get_count(ResourceData.ResourceType.BREAD), b.inventory.get_count(ResourceData.ResourceType.BREAD), claim.inventory.get_count(ResourceData.ResourceType.BREAD)])
	_check("two ovens keep separate counts", a.inventory.get_count(ResourceData.ResourceType.BREAD) == 0 and a.inventory.get_count(ResourceData.ResourceType.GRAIN) == 1 and b.inventory.get_count(ResourceData.ResourceType.BREAD) == 2 and b.inventory.get_count(ResourceData.ResourceType.GRAIN) == 3, "a grain=%d b grain=%d" % [a.inventory.get_count(ResourceData.ResourceType.GRAIN), b.inventory.get_count(ResourceData.ResourceType.GRAIN)])
	_check("claim counts match the server", claim.inventory.get_count(ResourceData.ResourceType.GRAIN) == 7 and claim.inventory.get_count(ResourceData.ResourceType.BREAD) == 1, "")
	root.multiplayer.multiplayer_peer = null


func _check(name: String, ok: bool, detail: String) -> void:
	if ok:
		_passed += 1
		print("PASS %s" % name)
	else:
		_failed += 1
		print("FAIL %s %s" % [name, detail])
