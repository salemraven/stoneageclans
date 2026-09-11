class_name EcoMigrate
extends RefCounted
## Illegal fauna walk toward a legal biome, then despawn.

const BiomePaletteRes = preload("res://scripts/world/biome_palette.gd")


static func _cat() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	return tree.root.get_node_or_null("/root/BiomeLifeCatalog")


static func _biome_name(biome_id: int) -> String:
	var cat := _cat()
	if cat and cat.has_method("biome_name_from_id"):
		return str(cat.biome_name_from_id(biome_id))
	return BiomePaletteRes.biome_to_name(BiomePaletteRes.biome_from_index(biome_id))


static func _can_spawn(npc_id: String, biome_id: int, river_dist01: float) -> bool:
	var cat := _cat()
	if cat and cat.has_method("can_spawn_fauna"):
		return bool(cat.can_spawn_fauna(npc_id, biome_id, river_dist01))
	return true


static func step_toward_legal(npc_id: String, world_pos: Vector2, tq: Node, step_px: float = 420.0) -> Dictionary:
	var bid: int = int(tq.get_effective_biome(world_pos))
	var from_name: String = _biome_name(bid)
	if _can_spawn(npc_id, bid, tq.river_distance_01(world_pos)):
		return {"npc": npc_id, "from_biome": from_name, "to_biome": from_name, "pos": world_pos, "despawn": false, "ok": true}
	var best := world_pos
	var best_ok := false
	var center := Vector2(32768, 32768)
	for i in 10:
		var nxt: Vector2 = world_pos.lerp(center, 0.08 * float(i + 1))
		var nb: int = int(tq.get_effective_biome(nxt))
		if _can_spawn(npc_id, nb, tq.river_distance_01(nxt)):
			best = nxt
			best_ok = true
			break
	if not best_ok:
		var dirs: Array[Vector2] = [
			Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1),
			Vector2(1, 1), Vector2(-1, 1), Vector2(1, -1), Vector2(-1, -1),
		]
		for d in dirs:
			var nxt2: Vector2 = world_pos + d.normalized() * step_px
			nxt2.x = clampf(nxt2.x, 80.0, 65400.0)
			nxt2.y = clampf(nxt2.y, 80.0, 65400.0)
			var nb2: int = int(tq.get_effective_biome(nxt2))
			if _can_spawn(npc_id, nb2, tq.river_distance_01(nxt2)):
				best = nxt2
				best_ok = true
				break
	if best_ok:
		return {
			"npc": npc_id,
			"from_biome": from_name,
			"to_biome": _biome_name(int(tq.get_effective_biome(best))),
			"pos": best,
			"despawn": false,
			"ok": true,
		}
	return {"npc": npc_id, "from_biome": from_name, "to_biome": "despawn", "pos": world_pos, "despawn": true, "ok": false}
