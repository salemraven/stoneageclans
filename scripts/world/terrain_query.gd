extends Node
## Autoload: authored island biome lookups from a downsampled mask + island_meta.json.
## Chunks load display art separately; this answers gameplay biome at world positions.
## Water layer is separate from biome — use is_water() for river/water checks.

const BiomePaletteRes = preload("res://scripts/world/biome_palette.gd")
const ClimateEvalRes = preload("res://scripts/world/climate_eval.gd")
const ClimateHashRes = preload("res://scripts/world/climate_hash.gd")
const ClimateConstantsRes = preload("res://scripts/world/climate_constants.gd")

const META_PATH := "res://maps/island/island_meta.json"
const MASK_PATH := "res://maps/island/biome_mask.png"
const WATER_LAYER_PATH := "res://maps/island/water_layer.png"
const RIVER_DISTANCE_PATH := "res://maps/island/river_distance.png"
const CHUNKS_DIR := "res://maps/island/chunks"
const CHUNK_SIZE_PX := 2048.0

var _meta: Dictionary = {}
var _mask_image: Image
var _water_image: Image
var _river_dist_image: Image
var _mask_size: Vector2i = Vector2i.ZERO
var _water_size: Vector2i = Vector2i.ZERO
var _world_size_px: Vector2 = Vector2.ZERO
var _sample_stride_px: float = 32.0
var _chunk_count: Vector2i = Vector2i(32, 32)
var _authored := false
var _has_water_layer := false
var _has_river_dist := false
var _river_dist_tex: ImageTexture
var _eco_cache: Dictionary = {}
var _eco_cache_gen: int = -999
var _eco_cache_step: int = -1


func get_river_distance_texture() -> Texture2D:
	if _river_dist_tex != null:
		return _river_dist_tex
	if _river_dist_image == null:
		return null
	_river_dist_tex = ImageTexture.create_from_image(_river_dist_image)
	return _river_dist_tex


func _ready() -> void:
	_try_load_authored()


func is_authored() -> bool:
	return _authored


func get_world_size_px() -> Vector2:
	return _world_size_px


func get_mask_size() -> Vector2i:
	return _mask_size


func get_chunk_count() -> Vector2i:
	return _chunk_count


func has_authored_chunk_tile(chunk: Vector2i) -> bool:
	if not _authored:
		return false
	var path := _chunk_tile_path(chunk)
	return FileAccess.file_exists(path)


func world_to_mask_cell(world_pos: Vector2) -> Vector2i:
	if _mask_size.x <= 0:
		return Vector2i.ZERO
	var wx: float = clampf(world_pos.x, 0.0, maxf(_world_size_px.x - 1.0, 0.0))
	var wy: float = clampf(world_pos.y, 0.0, maxf(_world_size_px.y - 1.0, 0.0))
	var mx: int = clampi(int(floor(wx / _sample_stride_px)), 0, _mask_size.x - 1)
	var my: int = clampi(int(floor(wy / _sample_stride_px)), 0, _mask_size.y - 1)
	return Vector2i(mx, my)


func get_biome(world_pos: Vector2) -> int:
	return get_effective_biome(world_pos)


func get_base_biome(world_pos: Vector2) -> int:
	if not _authored or _mask_image == null or _mask_size.x <= 0 or _mask_size.y <= 0:
		return BiomePaletteRes.Biome.SAVANNA
	var cell := world_to_mask_cell(world_pos)
	var pixel: Color = _mask_image.get_pixel(cell.x, cell.y)
	return BiomePaletteRes.id_from_mask_luma(pixel.r)


func get_effective_biome(world_pos: Vector2) -> int:
	return int(_effective_at(world_pos).get("biome", BiomePaletteRes.Biome.SAVANNA))


func get_biome_id(world_pos: Vector2) -> String:
	return BiomePaletteRes.biome_to_name(BiomePaletteRes.biome_from_index(get_biome(world_pos)))


func get_chunk_biome(_world_seed: int, chunk: Vector2i, _cfg: Node = null) -> String:
	var center := Vector2(float(chunk.x), float(chunk.y)) * CHUNK_SIZE_PX + Vector2(CHUNK_SIZE_PX * 0.5, CHUNK_SIZE_PX * 0.5)
	return get_biome_id(center)


func get_biome_available_resources(_world_seed: int, chunk: Vector2i, _cfg: Node = null) -> Array:
	var biome_name: String = get_chunk_biome(_world_seed, chunk, _cfg)
	return BiomePaletteRes.get_resources_for_biome_name(biome_name)


func is_base_water(world_pos: Vector2) -> bool:
	if _has_water_layer and _water_image != null and _water_size.x > 0:
		var cell := world_to_mask_cell(world_pos)
		cell.x = clampi(cell.x, 0, _water_size.x - 1)
		cell.y = clampi(cell.y, 0, _water_size.y - 1)
		return _water_image.get_pixel(cell.x, cell.y).r > 0.5
	return get_base_biome(world_pos) == BiomePaletteRes.Biome.RIVER


func is_water(world_pos: Vector2) -> bool:
	return bool(_effective_at(world_pos).get("water", false))


func get_effective_water(world_pos: Vector2) -> bool:
	return is_water(world_pos)


func river_distance_01(world_pos: Vector2) -> float:
	if not _has_river_dist or _river_dist_image == null:
		return 0.0 if is_base_water(world_pos) else 1.0
	var cell := world_to_mask_cell(world_pos)
	var sz := _river_dist_image.get_size()
	cell.x = clampi(cell.x, 0, sz.x - 1)
	cell.y = clampi(cell.y, 0, sz.y - 1)
	return _river_dist_image.get_pixel(cell.x, cell.y).r


func has_water_layer() -> bool:
	return _has_water_layer


func is_ocean(world_pos: Vector2) -> bool:
	if is_water(world_pos):
		return false
	return get_effective_biome(world_pos) == BiomePaletteRes.Biome.OCEAN


func sample_histogram_uv(uv0: Vector2, uv1: Vector2, step: int = 48) -> Dictionary:
	var counts: Dictionary = {}
	if _mask_size.x <= 0:
		return counts
	var x0 := clampi(int(floor(uv0.x * float(_mask_size.x))), 0, _mask_size.x - 1)
	var y0 := clampi(int(floor(uv0.y * float(_mask_size.y))), 0, _mask_size.y - 1)
	var x1 := clampi(int(ceil(uv1.x * float(_mask_size.x))), 1, _mask_size.x)
	var y1 := clampi(int(ceil(uv1.y * float(_mask_size.y))), 1, _mask_size.y)
	var n := 0
	var y := y0
	while y < y1:
		var x := x0
		while x < x1:
			var wp := Vector2((float(x) + 0.5) * _sample_stride_px, (float(y) + 0.5) * _sample_stride_px)
			var bid := get_effective_biome(wp)
			var key := str(bid)
			counts[key] = int(counts.get(key, 0)) + 1
			n += 1
			x += step
		y += step
	var out: Dictionary = {}
	if n <= 0:
		return out
	for k in counts.keys():
		out[k] = float(counts[k]) / float(n)
	out["n"] = n
	return out


func sample_climate_histogram(step: int = 32) -> Dictionary:
	var counts: Dictionary = {}
	if _mask_size.x <= 0:
		return counts
	var n := 0
	var y := 0
	while y < _mask_size.y:
		var x := 0
		while x < _mask_size.x:
			var wp := Vector2((float(x) + 0.5) * _sample_stride_px, (float(y) + 0.5) * _sample_stride_px)
			var bid := get_effective_biome(wp)
			var key := str(bid)
			counts[key] = int(counts.get(key, 0)) + 1
			n += 1
			x += step
		y += step
	var out: Dictionary = {}
	if n <= 0:
		return out
	for k in counts.keys():
		out[k] = float(counts[k]) / float(n)
	out["n"] = n
	return out


func sample_ring_histogram(r0: float, r1: float, step: int = 48) -> Dictionary:
	var counts: Dictionary = {}
	if _mask_size.x <= 0:
		return counts
	var n := 0
	var y := 0
	while y < _mask_size.y:
		var x := 0
		while x < _mask_size.x:
			var wp := Vector2((float(x) + 0.5) * _sample_stride_px, (float(y) + 0.5) * _sample_stride_px)
			var uv := Vector2(wp.x / maxf(_world_size_px.x, 1.0), wp.y / maxf(_world_size_px.y, 1.0))
			var d := ClimateEvalRes.dist_from_center_uv(uv)
			if d >= r0 and d < r1:
				var bid := get_effective_biome(wp)
				var key := str(bid)
				counts[key] = int(counts.get(key, 0)) + 1
				n += 1
			x += step
		y += step
	var out: Dictionary = {}
	if n <= 0:
		return out
	for k in counts.keys():
		out[k] = float(counts[k]) / float(n)
	out["n"] = n
	return out


func sample_river_band_histogram(near: bool, step: int = 48) -> Dictionary:
	var counts: Dictionary = {}
	if _mask_size.x <= 0:
		return counts
	var keep := ClimateConstantsRes.DESERT_RIVER_KEEP if ClimateConstantsRes else 0.14
	var n := 0
	var y := 0
	while y < _mask_size.y:
		var x := 0
		while x < _mask_size.x:
			var wp := Vector2((float(x) + 0.5) * _sample_stride_px, (float(y) + 0.5) * _sample_stride_px)
			if get_base_biome(wp) == BiomePaletteRes.Biome.OCEAN and not is_base_water(wp):
				x += step
				continue
			var rd := river_distance_01(wp)
			var is_near := rd <= keep
			if is_near == near:
				var bid := get_effective_biome(wp)
				var key := str(bid)
				counts[key] = int(counts.get(key, 0)) + 1
				n += 1
			x += step
		y += step
	var out: Dictionary = {}
	if n <= 0:
		return out
	for k in counts.keys():
		out[k] = float(counts[k]) / float(n)
	out["n"] = n
	return out


func sample_authored_river_keep(step: int = 32) -> float:
	if _mask_size.x <= 0:
		return 0.0
	var total := 0
	var kept := 0
	var y := 0
	while y < _mask_size.y:
		var x := 0
		while x < _mask_size.x:
			var wp := Vector2((float(x) + 0.5) * _sample_stride_px, (float(y) + 0.5) * _sample_stride_px)
			if is_base_water(wp):
				total += 1
				if is_water(wp):
					kept += 1
			x += step
		y += step
	if total <= 0:
		return 0.0
	return float(kept) / float(total)


func _hist_norm(counts: Dictionary, n: int) -> Dictionary:
	var out: Dictionary = {}
	if n <= 0:
		return out
	for k in counts.keys():
		out[k] = float(counts[k]) / float(n)
	out["n"] = n
	return out


func eco_hud_snapshot(step: int = 64) -> Dictionary:
	var cs: Node = get_node_or_null("/root/ClimateState")
	var gen := int(cs.cache_generation()) if cs and cs.has_method("cache_generation") else -1
	if gen == _eco_cache_gen and step == _eco_cache_step and not _eco_cache.is_empty():
		return _eco_cache.duplicate(true)
	var hist_c: Dictionary = {}
	var c_c: Dictionary = {}
	var m_c: Dictionary = {}
	var co_c: Dictionary = {}
	var n_c: Dictionary = {}
	var f_c: Dictionary = {}
	var hn := 0
	var cn := 0
	var mn := 0
	var con := 0
	var nn := 0
	var fn := 0
	var keep := ClimateConstantsRes.DESERT_RIVER_KEEP
	var bfn: Node = get_node_or_null("/root/BiomeFronts")
	if _mask_size.x > 0:
		var y := 0
		while y < _mask_size.y:
			var x := 0
			while x < _mask_size.x:
				var wp := Vector2((float(x) + 0.5) * _sample_stride_px, (float(y) + 0.5) * _sample_stride_px)
				var bid := get_effective_biome(wp)
				var key := str(bid)
				hist_c[key] = int(hist_c.get(key, 0)) + 1
				hn += 1
				var uv := Vector2(wp.x / maxf(_world_size_px.x, 1.0), wp.y / maxf(_world_size_px.y, 1.0))
				var d := ClimateEvalRes.dist_from_center_uv(uv)
				if d < 0.22:
					c_c[key] = int(c_c.get(key, 0)) + 1
					cn += 1
				elif d < 0.42:
					m_c[key] = int(m_c.get(key, 0)) + 1
					mn += 1
				elif d < 0.72:
					co_c[key] = int(co_c.get(key, 0)) + 1
					con += 1
				var ocean := get_base_biome(wp) == BiomePaletteRes.Biome.OCEAN and not is_base_water(wp)
				if not ocean:
					var rdn := river_distance_01(wp)
					if bfn and bfn.has_method("river_dist_grid"):
						rdn = float(bfn.river_dist_grid(wp))
					var is_near := rdn <= keep
					if is_near:
						n_c[key] = int(n_c.get(key, 0)) + 1
						nn += 1
					else:
						f_c[key] = int(f_c.get(key, 0)) + 1
						fn += 1
				x += step
			y += step
	var hist := _hist_norm(hist_c, hn)
	var center := _hist_norm(c_c, cn)
	var mid := _hist_norm(m_c, mn)
	var coast := _hist_norm(co_c, con)
	var near := _hist_norm(n_c, nn)
	var far := _hist_norm(f_c, fn)
	var ice_r := 0.0
	var season_p := 0.0
	var dline := 1.0
	if cs:
		ice_r = float(cs.effective_ice_radius()) if cs.has_method("effective_ice_radius") else float(cs.get("ice_radius"))
		season_p = float(cs.get("season_phase"))
	if bfn:
		dline = float(bfn.dry_line)
	var snap := {
		"hist": hist,
		"hist_center": center,
		"hist_mid": mid,
		"hist_coast": coast,
		"near_river": near,
		"far": far,
		"ice_radius": ice_r,
		"season_phase": season_p,
		"glacier_center": float(center.get("5", 0.0)),
		"glacier_mid": float(mid.get("5", 0.0)),
		"glacier_coast": float(coast.get("5", 0.0)),
		"savanna_near": float(near.get("1", 0.0)),
		"desert_near": float(near.get("2", 0.0)),
		"water_near": float(near.get("7", 0.0)),
		"savanna_far": float(far.get("1", 0.0)),
		"desert_far": float(far.get("2", 0.0)),
		"water_far": float(far.get("7", 0.0)),
		"dry_line": dline,
	}
	_eco_cache = snap
	_eco_cache_gen = gen
	_eco_cache_step = step
	return snap.duplicate(true)


func _effective_at(world_pos: Vector2) -> Dictionary:
	var cs: Node = get_node_or_null("/root/ClimateState")
	var cell := world_to_mask_cell(world_pos)
	if cs and cs.has_method("cache_get"):
		var hit: Variant = cs.cache_get(cell)
		if hit != null:
			return hit as Dictionary
	var base := get_base_biome(world_pos)
	var bw := is_base_water(world_pos)
	var dist := river_distance_01(world_pos)
	var temp := 0.0
	var rain := 0.0
	var seed := 882001
	var center := false
	if cs and bool(cs.get("climate_enabled")):
		seed = int(cs.world_seed)
		var uv := Vector2(world_pos.x / maxf(_world_size_px.x, 1.0), world_pos.y / maxf(_world_size_px.y, 1.0))
		var tr: Vector2 = cs.sample_temp_rain(uv)
		temp = tr.x
		rain = tr.y
		center = cs.is_center_uv(uv)
		if cs.get("world_seed") != null:
			seed = int(cs.world_seed)
	var noise := ClimateHashRes.hash_01(cell.x, cell.y, seed)
	var dfc := 1.0
	var ice_r := 0.0
	var sc := 0.0
	var sw := 0.0
	if cs and bool(cs.get("climate_enabled")):
		var uv2 := Vector2(world_pos.x / maxf(_world_size_px.x, 1.0), world_pos.y / maxf(_world_size_px.y, 1.0))
		dfc = ClimateEvalRes.dist_from_center_uv(uv2)
		if cs.has_method("effective_ice_radius"):
			ice_r = float(cs.effective_ice_radius())
		else:
			ice_r = float(cs.get("ice_radius"))
		sc = float(cs.get("season_cold"))
		sw = float(cs.get("season_wet"))
	var ev: Dictionary = ClimateEvalRes.classify(base, bw, dist, temp, rain, noise, center, dfc, ice_r, sc, sw)
	var bf: Node = get_node_or_null("/root/BiomeFronts")
	if cs and bool(cs.get("climate_enabled")) and bf:
		if base == ClimateEvalRes.BIOME_OCEAN and not bw:
			ev = {"biome": ClimateEvalRes.BIOME_OCEAN, "water": false}
		elif bf.has_method("is_grid_wet") and bool(bf.is_grid_wet(world_pos)):
			ev = {"biome": ClimateEvalRes.BIOME_RIVER, "water": true}
		else:
			ev = {"biome": bf.land_biome_id(world_pos, base), "water": false}
	if cs and cs.has_method("cache_put"):
		cs.cache_put(cell, ev)
	return ev


func _try_load_authored() -> void:
	_authored = false
	_has_water_layer = false
	_has_river_dist = false
	_meta = {}
	var wgc: Node = get_node_or_null("/root/WorldGenConfig")
	if wgc and not bool(wgc.get("use_authored_island_map")):
		print("TerrainQuery: authored island map off — using classic DirtBase + procedural chunks")
		return
	_mask_image = null
	_water_image = null
	_river_dist_image = null
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
	var cs: Node = get_node_or_null("/root/ClimateState")
	if cs:
		cs.world_seed = int(_meta.get("world_seed", 882001))

	_water_image = _load_grayscale_image_from_project(WATER_LAYER_PATH)
	if _water_image != null and not _water_image.is_empty():
		_water_size = _water_image.get_size()
		_has_water_layer = true
		print("TerrainQuery: loaded water layer %dx%d" % [_water_size.x, _water_size.y])
	_river_dist_image = _load_grayscale_image_from_project(RIVER_DISTANCE_PATH)
	if _river_dist_image != null and not _river_dist_image.is_empty():
		_has_river_dist = true
		print("TerrainQuery: loaded river distance %dx%d" % [_river_dist_image.get_width(), _river_dist_image.get_height()])


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
