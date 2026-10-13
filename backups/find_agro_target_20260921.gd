# Archived 2026-09-21 from npc_base._find_agro_target.
# Dead code: no callers, and the live function returned immediately.
# Kept so we can restore the scan if agro targeting is rebuilt on the grid.

func _find_agro_target() -> void:
	var perception: float = get_stat("perception")
	var detection_range: float = perception * 20.0 * 2.0
	var nearest_target: Node2D = null
	var nearest_distance: float = INF
	var player_nodes := get_tree().get_nodes_in_group("player")
	for player_node in player_nodes:
		if not is_instance_valid(player_node):
			continue
		var distance: float = global_position.distance_to(player_node.global_position)
		if distance < detection_range and distance < nearest_distance:
			nearest_target = player_node
			nearest_distance = distance
	var npcs := get_tree().get_nodes_in_group("npcs")
	for other_npc in npcs:
		if other_npc == self or not is_instance_valid(other_npc):
			continue
		if other_npc.has_method("is_dead") and other_npc.is_dead():
			continue
		var other_type: String = other_npc.get("npc_type") if other_npc else ""
		if other_type == "caveman":
			var distance: float = global_position.distance_to(other_npc.global_position)
			if distance < detection_range and distance < nearest_distance:
				nearest_target = other_npc
				nearest_distance = distance
	agro_target = nearest_target
