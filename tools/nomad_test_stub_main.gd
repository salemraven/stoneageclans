extends Node
## Minimal Main stand-in for headless Nomad Mode tests (no full Main.tscn boot).

var _follower_cache: Array = []
var player: Node2D = null


func _ready() -> void:
	add_to_group("main")
	player = Node2D.new()
	player.name = "TestPlayer"
	player.add_to_group("player")
	add_child(player)


func get_active_leader() -> Node2D:
	return player


func is_player_in_nomad_mode() -> bool:
	if player and player.has_meta("nomad_state"):
		return int(player.get_meta("nomad_state")) != 0
	return false


func is_clan_in_nomad_mode(_clan: String) -> bool:
	return is_player_in_nomad_mode()


func _set_ordered_follow(npc: Node, _follow_source: String = "unknown") -> void:
	if not npc or not player:
		return
	npc.set("is_herded", true)
	npc.set("herder", player)
	npc.set("follow_is_ordered", true)
	var fid: int = npc.get_instance_id()
	if _follower_cache.find(fid) < 0:
		_follower_cache.append(fid)


func _set_nomad_follow(npc: Node, leader: Node, _follow_source: String = "nomad_mode") -> void:
	if not npc or not leader:
		return
	var npc_type: String = str(npc.get("npc_type")) if npc.get("npc_type") != null else ""
	if npc_type == "clansman" or npc_type == "caveman":
		npc.set("is_herded", true)
		npc.set("herder", leader)
		npc.set("follow_is_ordered", true)
	elif npc_type == "woman":
		npc.set("is_herded", true)
		npc.set("herder", leader)
		npc.set("follow_is_ordered", true)


func _break_and_dismiss_all() -> void:
	if is_player_in_nomad_mode():
		return
	_follower_cache.clear()
	for npc in get_tree().get_nodes_in_group("npcs"):
		if not is_instance_valid(npc):
			continue
		npc.set("is_herded", false)
		npc.set("herder", null)
		npc.set("follow_is_ordered", false)
