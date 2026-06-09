extends TileMap

# Ground is drawn by DirtBase (repeating dirtbase.png). This TileMap is kept for
# optional overlays (e.g. grass patches) or collision; no procedural tiles.

func ensure_chunks_for_position(world_position: Vector2, delta_sec: float = 0.0) -> void:
	var cm: Node = get_node_or_null("/root/ChunkManager")
	var wgc: Node = get_node_or_null("/root/WorldGenConfig")
	if cm and wgc and bool(wgc.use_chunk_content_streaming):
		cm.call("update_streaming", world_position, delta_sec)
