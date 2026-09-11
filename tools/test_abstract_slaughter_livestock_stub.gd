extends Node2D

var npc_type: String = "sheep"
var npc_name: String = "StubSheep"
var clan_name: String = ""


func get_clan_name() -> String:
	return clan_name


func is_dead() -> bool:
	return false
