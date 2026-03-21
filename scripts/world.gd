extends TileMap

# Ground is drawn by DirtBase (repeating dirtbase.png). This TileMap is kept for
# optional overlays (e.g. grass patches) or collision; no procedural tiles.

func ensure_chunks_for_position(_world_position: Vector2) -> void:
	pass
