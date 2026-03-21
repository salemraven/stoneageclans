extends Node
class_name NodeCache

# Caches node lookups (land claims, NPCs) to avoid repeated get_nodes_in_group.
# Main owns land_claims cache; we delegate get_land_claims() to Main when possible.
# NPCs: short TTL cache + spatial filter for get_npcs_near_position.

var _npcs_cache: Array = []
var _npcs_cache_time: float = 0.0
const NPCs_CACHE_TTL: float = 0.25  # Refresh every 0.25s

func get_land_claims() -> Array:
	var tree = get_tree()
	if not tree:
		return []
	# Use Main's cache when available (single source of truth)
	var main = tree.root.get_node_or_null("Main")
	if main and main.has_method("get_cached_land_claims"):
		return main.get_cached_land_claims()
	return tree.get_nodes_in_group("land_claims")

func get_npcs_near_position(pos: Vector2, radius: float) -> Array:
	var tree = get_tree()
	if not tree:
		return []
	var now: float = Time.get_ticks_msec() / 1000.0
	if _npcs_cache.is_empty() or (now - _npcs_cache_time) > NPCs_CACHE_TTL:
		_npcs_cache = tree.get_nodes_in_group("npcs")
		_npcs_cache_time = now
	var out: Array = []
	for n in _npcs_cache:
		if not is_instance_valid(n):
			continue
		if pos.distance_to(n.global_position) <= radius:
			out.append(n)
	return out
