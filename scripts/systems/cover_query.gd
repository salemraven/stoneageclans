extends RefCounted

## Find gatherable world props usable as visual cover (trees, bushes, tall grass).

static func find_nearest_cover(from: Vector2, tree: SceneTree, max_dist: float = -1.0) -> Node2D:
	if tree == null:
		return null
	var md: float = max_dist
	if md <= 0.0 and NPCConfig:
		md = NPCConfig.cover_query_max_dist
	elif md <= 0.0:
		md = 300.0
	var ri: Node = tree.root.get_node_or_null("ResourceIndex") if tree.root else null
	if ri == null or not ri.has_method("query_near"):
		return null
	var cover_types: Array = [
		ResourceData.ResourceType.WOOD,
		ResourceData.ResourceType.BERRIES,
		ResourceData.ResourceType.WHEAT,
		ResourceData.ResourceType.FIBER,
	]
	var best: Node2D = null
	var best_d: float = INF
	for rt in cover_types:
		var hits: Array = ri.query_near(from, md, {"resource_type": rt, "exclude_empty": false})
		for h in hits:
			var entry = h as Dictionary
			var node: Node2D = entry.get("node") as Node2D
			if node == null or not is_instance_valid(node):
				continue
			var d: float = float(entry.get("distance", from.distance_to(node.global_position)))
			if d < best_d:
				best_d = d
				best = node
	return best


## Position slightly past the cover node, away from the threat (approximate “behind” cover).
static func get_hide_position(cover: Node2D, threat_position: Vector2) -> Vector2:
	if cover == null or not is_instance_valid(cover):
		return Vector2.ZERO
	var cpos: Vector2 = cover.global_position
	var away: Vector2 = (cpos - threat_position)
	if away.length_squared() < 1.0:
		away = Vector2.RIGHT * 40.0
	else:
		away = away.normalized() * 40.0
	return cpos + away


static func get_cover_reduction(npc: Node2D) -> float:
	"""Detection dampening factor while hiding (1 = no extra dampening)."""
	if npc == null:
		return 1.0
	if npc.get_meta("is_hidden", false) == true:
		if npc.get_meta("hide_has_cover", false) == true:
			return 1.0 - (NPCConfig.cover_full_detection_reduction if NPCConfig else 0.9)
		return 1.0 - (NPCConfig.cover_exposed_detection_reduction if NPCConfig else 0.5)
	return 1.0
