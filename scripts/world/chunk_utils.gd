extends Node
## Chunk utilities for chunk-bound wildlife roaming.
## Autoload as ChunkUtils.

const TILE_SIZE: int = 64
const CHUNK_TILES: int = 32
const CHUNK_SIZE: float = 2048.0  # TILE_SIZE * CHUNK_TILES
const ROAM_RADIUS: float = CHUNK_SIZE * 0.8  # 1638.4
const HOME_UPDATE_TIME: float = 30.0
const CLAN_AVOID_RADIUS: float = 600.0
const WOMAN_CLAN_AVOID_RADIUS: float = 800.0


func get_chunk_coords(world_pos: Vector2) -> Vector2i:
	return Vector2i(floor(world_pos.x / CHUNK_SIZE), floor(world_pos.y / CHUNK_SIZE))


func get_chunk_center(chunk: Vector2i) -> Vector2:
	return Vector2(chunk) * CHUNK_SIZE + Vector2(CHUNK_SIZE * 0.5, CHUNK_SIZE * 0.5)
