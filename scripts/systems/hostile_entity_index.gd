extends Node

# HostileEntityIndex - one spatial index for combat target candidates. Step 5.
# Swap get_combat_target_candidates to use this instead of per-NPC DetectionArea.

func get_enemies_in_range(origin: Vector2, radius: float, npc: Node) -> Array:
	"""Returns valid enemy nodes within radius of origin (same validity as DetectionArea)."""
	var out: Array = []
	var tree = get_tree()
	if not tree or not npc:
		return out
	var r2: float = radius * radius
	var all_npcs: Array = tree.get_nodes_in_group("npcs")
	var players: Array = tree.get_nodes_in_group("player")
	var my_clan: String = npc.get_clan_name() if npc.has_method("get_clan_name") else ""
	for target in all_npcs + players:
		if not is_instance_valid(target) or target == npc:
			continue
		var target_type: String = target.get("npc_type") as String if target.get("npc_type") != null else ""
		var is_player: bool = target.is_in_group("player")
		if target_type != "caveman" and target_type != "clansman" and not is_player:
			continue
		if is_player:
			if npc.get("herder") == target:
				continue
			var dt = npc.get("defend_target")
			var shc = npc.get("search_home_claim")
			if (dt != null and is_instance_valid(dt) and dt.get("player_owned") == true) or (shc != null and is_instance_valid(shc) and shc.get("player_owned") == true):
				continue
			var player_clan: String = target.get_clan_name() if target.has_method("get_clan_name") else ""
			if my_clan != "" and player_clan != "" and my_clan == player_clan:
				continue
		if not is_player and target.has_method("get_clan_name") and target.get_clan_name() == my_clan and my_clan != "":
			continue
		var th: HealthComponent = target.get_node_or_null("HealthComponent")
		if th and th.is_dead:
			continue
		if origin.distance_squared_to(target.global_position) <= r2:
			out.append(target)
	return out
