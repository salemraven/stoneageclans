extends SceneTree
## Brain sleeps when nobody in the camp is in wake range, combat, or a party.
## A far clansman does not keep the walking brain just because the flag is inside 2400px.

const BrainScript := preload("res://scripts/ai/clan_brain.gd")

var _failed := 0
var _passed := 0


class FakeMain:
	extends Node2D
	var player: Node2D


class FakeClaim:
	extends Node2D
	var clan_name: String = "FAR"
	var player_owned: bool = false


class FakeNpc:
	extends Node2D
	var clan_name: String = "FAR"
	var npc_type: String = "clansman"
	var is_agro: bool = false
	var combat_target: Object = null


func _initialize() -> void:
	var main := FakeMain.new()
	main.name = "Main"
	main.add_to_group("main")
	root.add_child(main)
	var player := Node2D.new()
	player.name = "Player"
	player.add_to_group("player")
	player.position = Vector2.ZERO
	main.add_child(player)
	main.player = player
	var claim := FakeClaim.new()
	claim.position = Vector2(1680, 0)
	main.add_child(claim)
	var npc := FakeNpc.new()
	npc.position = Vector2(1680, 0)
	npc.add_to_group("npcs")
	main.add_child(npc)
	await process_frame
	var brain = BrainScript.new()
	brain.territory = claim
	brain.clan_name = "FAR"
	if brain.should_run_live_sim():
		_fail("camp outside wake is asleep")
	else:
		_pass("camp outside wake is asleep")
	npc.position = Vector2(400, 0)
	if brain.should_run_live_sim():
		_pass("camp inside wake is live")
	else:
		_fail("camp inside wake is live")
	npc.position = Vector2(1680, 0)
	npc.is_agro = true
	if brain.should_run_live_sim():
		_pass("agro keeps the camp live")
	else:
		_fail("agro keeps the camp live")
	npc.is_agro = false
	claim.player_owned = true
	if brain.should_run_live_sim():
		_pass("player camp stays live")
	else:
		_fail("player camp stays live")
	claim.player_owned = false
	npc.remove_from_group("npcs")
	main.remove_child(npc)
	npc.free()
	if brain.should_run_live_sim():
		_fail("empty camp is asleep")
	else:
		_pass("empty camp is asleep")
	print("CAMP_SIM_GATE passed=%d failed=%d" % [_passed, _failed])
	quit(0 if _failed == 0 else 1)


func _pass(label: String) -> void:
	_passed += 1
	print("PASS %s" % label)


func _fail(label: String) -> void:
	_failed += 1
	print("FAIL %s" % label)
