extends Node
## Autoload: authored island biome lookups from a downsampled mask + island_meta.json.
## Chunks load display art separately; this answers gameplay biome at world positions.
## Water layer is separate from biome — use is_water() for river/water checks.

const BiomePaletteRes = preload("res://scripts/world/biome_palette.gd")

const META_PATH := "res://maps/island/island_meta.json"
const MASK_PATH := "res://maps/island/biome_mask.png"
const WATER_LAYER_PATH := "res://maps/island/water_layer.png"
const CHUNKS_DIR := "res://maps/island/chunks"
const CHUNK_SIZE_PX := 2048.0

var _meta: Dictionary = {}
var _mask_image: Image
var _water_image: Image
var _mask_size: Vector2i = Vector2i.ZERO
var _water_size: Vector2i = Vector2i.ZERO
var _world_size_px: Vector2 = Vector2.ZERO
var _sample_stride_px: float = 32.0
var _chunk_count: Vector2i = Vector2i(32, 32)
var _authored := false
var _has_water_layer := false


func _ready() -> void:
	_try_load_authored()


func is_authored() -> bool:
	return _authored


func get_world_size_px() -> Vector2:
	return _world_size_px


func get_chunk_count() -> Vector2i:
	return _chunk_count


func has_authored_chunk_tile(chunk: Vector2i) -> bool:
	if not _authored:
		return false
	var path := _chunk_tile_path(chunk)
	return FileAccess.file_exists(path)


func get_biome(world_pos: Vector2) -> int:
	if not _authored or _mask_image == null or _mask_size.x <= 0 or _mask_size.y <= 0:
		return BiomePaletteRes.Biome.SAVANNA
	var wx: float = clampf(world_pos.x, 0.0, maxf(_world_size_px.x - 1.0, 0.0))
	var wy: float = clampf(world_pos.y, 0.0, maxf(_world_size_px.y - 1.0, 0.0))
	var mx: int = clampi(int(floor(wx / _sample_stride_px)), 0, _mask_size.x - 1)
	var my: int = clampi(int(floor(wy / _sample_stride_px)), 0, _mask_size.y - 1)
	var pixel: Color = _mask_image.get_pixel(mx, my)
	return BiomePaletteRes.nearest_biome(pixel)


func get_biome_id(world_pos: Vector2) -> String:
	return BiomePaletteRes.biome_to_name(BiomePaletteRes.biome_from_index(get_biome(world_pos)))


func get_chunk_biome(_world_seed: int, chunk: Vector2i, _cfg: Node = null) -> String:
	var center := Vector2(float(chunk.x), float(chunk.y)) * CHUNK_SIZE_PX + Vector2(CHUNK_SIZE_PX * 0.5, CHUNK_SIZE_PX * 0.5)
	return get_biome_id(center)


func get_biome_available_resources(_world_seed: int, chunk: Vector2i, _cfg: Node = null) -> Array:
	var biome_name: String = get_chunk_biome(_world_seed, chunk, _cfg)
	return BiomePaletteRes.get_resources_for_biome_name(biome_name)


## Check if a world position is water (river, lake, etc.)
## Uses the painted water_layer.png if available, else falls back to biome_mask RIVER ID.
func is_water(world_pos: Vector2) -> bool:
	if _has_water_layer and _water_image != null and _water_size.x > 0 and _water_size.y > 0:
		var wx: float = clampf(world_pos.x, 0.0, maxf(_world_size_px.x - 1.0, 0.0))
		var wy: float = clampf(world_pos.y, 0.0, maxf(_world_size_px.y - 1.0, 0.0))
		var mx: int = clampi(int(floor(wx / _sample_stride_px)), 0, _water_size.x - 1)
		var my: int = clampi(int(floor(wy / _sample_stride_px)), 0, _water_size.y - 1)
		var pixel: Color = _water_image.get_pixel(mx, my)
		return pixel.r > 0.5
	else:
		# Fallback: check biome_mask for RIVER ID
		var biome := get_biome(world_pos)
		return biome == BiomePaletteRes.Biome.RIVER


## Check if water layer is available (painted in editor)
func has_water_layer() -> bool:
	return _has_water_layer


## Impassible ocean — biome is OCEAN and not an authored river tile.
func is_ocean(world_pos: Vector2) -> bool:
	if is_water(world_pos):
		return false
	return get_biome(world_pos) == BiomePaletteRes.Biome.OCEAN


func _try_load_authored() -> void:
	_authored = false
	_has_water_layer = false
	_meta = {}
	_mask_image = null
	_water_image = null
	_mask_size = Vector2i.ZERO
	_water_size = Vector2i.ZERO
	if not FileAccess.file_exists(META_PATH):
		return
	var meta_text: String = FileAccess.get_file_as_string(META_PATH)
	var parsed: Variant = JSON.parse_string(meta_text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("TerrainQuery: invalid island_meta.json")
		return
	_meta = parsed as Dictionary
	_world_size_px = Vector2(
		float(_meta.get("world_width_px", 65536)),
		float(_meta.get("world_height_px", 65536))
	)
	_chunk_count = Vector2i(
		int(_meta.get("chunk_count_x", 32)),
		int(_meta.get("chunk_count_y", 32))
	)
	_sample_stride_px = maxf(float(_meta.get("sample_stride_px", 32.0)), 1.0)
	if not FileAccess.file_exists(MASK_PATH):
		push_warning("TerrainQuery: island_meta present but biome_mask missing at %s" % MASK_PATH)
		return
	var fs_path := ProjectSettings.globalize_path(MASK_PATH)
	_mask_image = Image.load_from_file(fs_path)
	if _mask_image == null or _mask_image.is_empty():
		push_warning("TerrainQuery: biome mask image empty")
		return
	_mask_size = _mask_image.get_size()
	_authored = true

	# Try to load water layer (optional — may not exist yet)
	_water_image = _load_grayscale_image_from_project(WATER_LAYER_PATH)
	if _water_image != null and not _water_image.is_empty():
		_water_size = _water_image.get_size()
		_has_water_layer = true
		print("TerrainQuery: loaded water layer %dx%d" % [_water_size.x, _water_size.y])


func _load_grayscale_image_from_project(project_path: String) -> Image:
	if not FileAccess.file_exists(project_path):
		return null
	var fs_path := ProjectSettings.globalize_path(project_path)
	var img := Image.load_from_file(fs_path)
	if img == null or img.is_empty():
		push_warning("TerrainQuery: failed to read image at %s" % project_path)
		return null
	img.convert(Image.FORMAT_L8)
	return img


func _chunk_tile_path(chunk: Vector2i) -> String:
	return "%s/tile_%d_%d.png" % [CHUNKS_DIR, chunk.x, chunk.y]
