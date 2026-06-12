extends RefCounted
class_name PlayerSuccession

## Full possess: transfer camera, followers, and nomad meta to oldest clansman heir.

static func transfer_to_heir(main: Node, dead_player: Node) -> bool:
	if main == null or dead_player == null or not is_instance_valid(dead_player):
		return false
	var clan_name: String = ""
	if dead_player.has_method("get_clan_name"):
		clan_name = dead_player.get_clan_name()
	if clan_name == "":
		return false

	var heir: Node2D = _find_oldest_heir(dead_player, clan_name)
	if heir == null:
		if main.has_method("_handle_clan_extinction"):
			main._handle_clan_extinction(clan_name)
		return false

	UnifiedLogger.log_system("PLAYER_SUCCESSION", {
		"heir_name": str(heir.get("npc_name")) if heir.get("npc_name") else "",
		"heir_age": heir.get("age") if heir.get("age") != null else 0,
		"clan": clan_name,
	})

	if str(heir.get("npc_type")) == "clansman":
		heir.set("npc_type", "caveman")

	var cam: Camera2D = dead_player.get_node_or_null("Camera2D") as Camera2D
	if cam and is_instance_valid(heir):
		cam.reparent(heir)
		cam.position = Vector2.ZERO

	if dead_player.has_method("set_can_move"):
		dead_player.set_can_move(false)
	dead_player.visible = false

	if dead_player.has_meta("nomad_state"):
		heir.set_meta("nomad_state", dead_player.get_meta("nomad_state"))
		dead_player.remove_meta("nomad_state")
	if dead_player.has_meta("nomad_clan_name"):
		heir.set_meta("nomad_clan_name", dead_player.get_meta("nomad_clan_name"))
		dead_player.remove_meta("nomad_clan_name")

	var tree: SceneTree = dead_player.get_tree()
	if tree:
		for npc in tree.get_nodes_in_group("npcs"):
			if not is_instance_valid(npc):
				continue
			if npc.get("herder") == dead_player:
				npc.set("herder", heir)
				if main.has_method("_set_nomad_follow") and main.is_clan_in_nomad_mode(clan_name):
					main._set_nomad_follow(npc, heir, "succession_rejoin")
				elif main.has_method("_set_ordered_follow"):
					main._set_ordered_follow(npc, "succession_rejoin")

	if main.has_method("set_possessed_npc"):
		main.set_possessed_npc(heir)

	for claim in tree.get_nodes_in_group("land_claims") if tree else []:
		if not is_instance_valid(claim):
			continue
		if str(claim.get("clan_name")) != clan_name:
			continue
		if claim.get("owner_npc") == dead_player:
			claim.set("owner_npc", heir)
			claim.set("owner_npc_name", str(heir.get("npc_name")) if heir.get("npc_name") else "")

	return true


static func _find_oldest_heir(dead_player: Node, clan_name: String) -> Node2D:
	var tree: SceneTree = dead_player.get_tree()
	if tree == null:
		return null
	var candidates: Array = []
	for npc in tree.get_nodes_in_group("npcs"):
		if not is_instance_valid(npc) or npc == dead_player:
			continue
		if npc.has_method("is_dead") and npc.is_dead():
			continue
		var npc_type: String = str(npc.get("npc_type")) if npc.get("npc_type") != null else ""
		if npc_type != "clansman" and npc_type != "caveman":
			continue
		var npc_clan: String = npc.get_clan_name() if npc.has_method("get_clan_name") else str(npc.get("clan_name") if npc.get("clan_name") else "")
		if npc_clan == clan_name:
			candidates.append(npc)
	if candidates.is_empty():
		return null
	var heir: Node2D = null
	var oldest_age: int = -1
	for c in candidates:
		var age: int = int(c.get("age")) if c.get("age") != null else 0
		if age > oldest_age:
			oldest_age = age
			heir = c as Node2D
	return heir
