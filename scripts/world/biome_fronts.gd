extends Node
## Coarse 256 succession grid. Land biome authority when climate is on.

const C = preload("res://scripts/world/climate_constants.gd")
const Eval = preload("res://scripts/world/climate_eval.gd")
const HashRes = preload("res://scripts/world/climate_hash.gd")
const BiomePaletteRes = preload("res://scripts/world/biome_palette.gd")

const ICE_NONE := 0
const ICE_TUNDRA := 1
const ICE_SHEET := 2

var ice: PackedByteArray = PackedByteArray()
var dry: PackedByteArray = PackedByteArray()
var wet: PackedByteArray = PackedByteArray()
var ids: PackedByteArray = PackedByteArray()
var _base: PackedByteArray = PackedByteArray()
var _bw: PackedByteArray = PackedByteArray()
var _ocean: PackedByteArray = PackedByteArray()
var _rd: PackedFloat32Array = PackedFloat32Array()
var _dfc: PackedFloat32Array = PackedFloat32Array()
var dry_line: float = C.DRY_LINE_START
var _tex: ImageTexture
var _inited := false
var _last_metrics: Dictionary = {}


func _ready() -> void:
	call_deferred("ensure_init")


func ensure_init() -> void:
	if _inited and ice.size() == C.FRONT_GRID * C.FRONT_GRID:
		return
	_alloc()
	_seed_from_map()
	_bake_ids()
	_inited = true


func reset_grid() -> void:
	_alloc()
	dry_line = C.DRY_LINE_START
	_seed_from_map()
	_bake_ids()
	_inited = true
	_bump()


func _alloc() -> void:
	var n: int = C.FRONT_GRID * C.FRONT_GRID
	ice.resize(n)
	dry.resize(n)
	wet.resize(n)
	ids.resize(n)
	_base.resize(n)
	_bw.resize(n)
	_ocean.resize(n)
	_rd.resize(n)
	_dfc.resize(n)
	ice.fill(0)
	dry.fill(0)
	wet.fill(0)
	ids.fill(1)
	_base.fill(1)
	_bw.fill(0)
	_ocean.fill(0)
	_rd.fill(1.0)
	_dfc.fill(1.0)


func grid_index(gx: int, gy: int) -> int:
	return gy * C.FRONT_GRID + gx


func world_to_grid(world_pos: Vector2) -> Vector2i:
	var tq: Node = get_node_or_null("/root/TerrainQuery")
	var ws: Vector2 = Vector2(65536, 65536)
	if tq and tq.get("_world_size_px") != null:
		ws = tq._world_size_px
	var gx := clampi(int(floor(world_pos.x / maxf(ws.x, 1.0) * float(C.FRONT_GRID))), 0, C.FRONT_GRID - 1)
	var gy := clampi(int(floor(world_pos.y / maxf(ws.y, 1.0) * float(C.FRONT_GRID))), 0, C.FRONT_GRID - 1)
	return Vector2i(gx, gy)


func cell_world(gx: int, gy: int) -> Vector2:
	var tq: Node = get_node_or_null("/root/TerrainQuery")
	var ws: Vector2 = Vector2(65536, 65536)
	if tq and tq.get("_world_size_px") != null:
		ws = tq._world_size_px
	return Vector2((float(gx) + 0.5) / float(C.FRONT_GRID) * ws.x, (float(gy) + 0.5) / float(C.FRONT_GRID) * ws.y)


func _seed_from_map() -> void:
	var tq: Node = get_node_or_null("/root/TerrainQuery")
	if tq == null or not tq.has_method("get_base_biome"):
		return
	for gy in C.FRONT_GRID:
		for gx in C.FRONT_GRID:
			var i := grid_index(gx, gy)
			var wp := cell_world(gx, gy)
			var base: int = int(tq.get_base_biome(wp))
			var bw: bool = bool(tq.is_base_water(wp))
			var rd: float = float(tq.river_distance_01(wp))
			_base[i] = base
			_bw[i] = 1 if bw else 0
			_rd[i] = rd
			var uv := Vector2((float(gx) + 0.5) / float(C.FRONT_GRID), (float(gy) + 0.5) / float(C.FRONT_GRID))
			_dfc[i] = Eval.dist_from_center_uv(uv)
			_ocean[i] = 1 if (base == Eval.BIOME_OCEAN and not bw) else 0
			wet[i] = 1 if bw else 0
			if base == Eval.BIOME_GLACIER:
				ice[i] = ICE_SHEET
			dry[i] = 0
	_rebuild_rd_from_water()


func river_dist_grid(world_pos: Vector2) -> float:
	ensure_init()
	var g := world_to_grid(world_pos)
	return float(_rd[grid_index(g.x, g.y)])


func _rebuild_rd_from_water() -> void:
	# PNG river_distance saturates on land (~1.0). Use coarse distance to water instead.
	var gsz: int = C.FRONT_GRID
	var infv := 1.0e9
	var dist: PackedFloat32Array = PackedFloat32Array()
	dist.resize(gsz * gsz)
	dist.fill(infv)
	var q: Array[Vector2i] = []
	for gy in gsz:
		for gx in gsz:
			var i := grid_index(gx, gy)
			if int(_ocean[i]) == 1:
				continue
			if int(_bw[i]) == 1 or int(wet[i]) == 1:
				dist[i] = 0.0
				q.append(Vector2i(gx, gy))
	var head := 0
	var maxd := 1.0
	while head < q.size():
		var c: Vector2i = q[head]
		head += 1
		var ci := grid_index(c.x, c.y)
		var cd: float = dist[ci]
		for oy in range(-1, 2):
			for ox in range(-1, 2):
				if ox == 0 and oy == 0:
					continue
				var nx := c.x + ox
				var ny := c.y + oy
				if nx < 0 or ny < 0 or nx >= gsz or ny >= gsz:
					continue
				var ni := grid_index(nx, ny)
				if int(_ocean[ni]) == 1:
					continue
				var stepd: float = 1.414 if ox != 0 and oy != 0 else 1.0
				var nd: float = cd + stepd
				if nd < dist[ni]:
					dist[ni] = nd
					q.append(Vector2i(nx, ny))
					if nd > maxd:
						maxd = nd
	for i in dist.size():
		if dist[i] >= infv * 0.5:
			_rd[i] = 1.0
		else:
			_rd[i] = clampf(dist[i] / maxd, 0.0, 1.0)
		if int(_bw[i]) == 1 or _rd[i] < 0.03:
			if int(_ocean[i]) == 0:
				wet[i] = 1


func land_biome_id(world_pos: Vector2, base_biome: int) -> int:
	ensure_init()
	var g := world_to_grid(world_pos)
	var i := grid_index(g.x, g.y)
	return _id_from_stages(base_biome, int(ice[i]), int(dry[i]), int(wet[i]))


func is_grid_wet(world_pos: Vector2) -> bool:
	ensure_init()
	var g := world_to_grid(world_pos)
	return wet[grid_index(g.x, g.y)] == 1


func _id_from_stages(base_biome: int, ice_s: int, dry_s: int, wet_s: int = 0) -> int:
	if base_biome == Eval.BIOME_OCEAN and wet_s == 0:
		return Eval.BIOME_OCEAN
	if wet_s == 1:
		return Eval.BIOME_RIVER
	if ice_s == ICE_SHEET:
		return Eval.BIOME_GLACIER
	if ice_s == ICE_TUNDRA:
		return Eval.BIOME_TUNDRA
	if dry_s >= 4:
		return Eval.BIOME_DESERT
	if dry_s >= 2:
		return Eval.BIOME_SAVANNA
	return base_biome


func step() -> void:
	ensure_init()
	var cs: Node = get_node_or_null("/root/ClimateState")
	var tq: Node = get_node_or_null("/root/TerrainQuery")
	if cs == null or tq == null:
		return
	if cs.has_method("sync_events_from_string"):
		cs.sync_events_from_string()
	var ice_on := bool(cs.event_ice)
	var dry_on := bool(cs.event_drought)
	var flood_on := bool(cs.event_flood)
	var rad: float = float(cs.effective_ice_radius()) if cs.has_method("effective_ice_radius") else float(cs.ice_radius)
	if dry_on:
		dry_line = maxf(0.03, dry_line - C.DRY_LINE_PER_DAY)
	elif flood_on:
		dry_line = minf(C.DRY_LINE_START, dry_line + C.DRY_LINE_RECOVER * 1.4)
	else:
		dry_line = minf(C.DRY_LINE_START, dry_line + C.DRY_LINE_RECOVER)
	var old_ice := ice.duplicate()
	var old_dry := dry.duplicate()
	var old_wet := wet.duplicate()
	var new_ice := 0
	var new_des := 0
	var new_dry := 0
	var land_n := 0
	var gsz: int = C.FRONT_GRID
	var seed: int = int(cs.world_seed)
	for gy in gsz:
		for gx in gsz:
			var i := grid_index(gx, gy)
			if int(_ocean[i]) == 1:
				ice[i] = ICE_NONE
				dry[i] = 0
				wet[i] = 0
				continue
			land_n += 1
			var base: int = int(_base[i])
			var bw: bool = int(_bw[i]) == 1
			var rd: float = float(_rd[i])
			var dfc: float = float(_dfc[i])
			var uv := Vector2((float(gx) + 0.5) / float(gsz), (float(gy) + 0.5) / float(gsz))
			var tr: Vector2 = cs.sample_temp_rain(uv)
			var n01: float = HashRes.hash_01(gx, gy, seed)
			var n_ice := _count_ice(old_ice, gx, gy)
			var n_tundra := _count_tundra(old_ice, gx, gy)
			var n_drier := _count_drier(old_dry, gx, gy, int(old_dry[i]))
			var n_wet := _count_wet(old_wet, gx, gy)
			var painted_g := base == Eval.BIOME_GLACIER
			ice[i] = _step_ice(int(old_ice[i]), dfc, rad, n_ice, n_tundra, n01, painted_g, ice_on, float(tr.x))
			if ice[i] >= ICE_TUNDRA:
				dry[i] = 0
			else:
				dry[i] = _step_dry(int(old_dry[i]), rd, float(tr.y), n_drier, dry_on, flood_on, base)
			wet[i] = _step_wet(int(old_wet[i]), bw, rd, float(tr.y), n_wet, flood_on)
			if ice[i] == ICE_SHEET and old_ice[i] != ICE_SHEET:
				new_ice += 1
			if dry[i] > old_dry[i]:
				new_dry += 1
			if dry[i] == 4 and old_dry[i] != 4:
				new_des += 1
	var max_new: int = maxi(8, int(float(maxi(land_n, 1)) * C.ICE_POP_HARD))
	if new_ice > max_new or new_des > max_new or new_dry > max_new:
		_cap_new(old_ice, old_dry, max_new)
	_last_metrics = collect_step_metrics(old_ice, old_dry, old_wet, rad)
	_bake_ids()
	_bump()


func _cap_new(old_ice: PackedByteArray, old_dry: PackedByteArray, max_new: int) -> void:
	var gi := 0
	var gd := 0
	for i in ice.size():
		if ice[i] == ICE_SHEET and old_ice[i] != ICE_SHEET:
			gi += 1
			if gi > max_new:
				ice[i] = old_ice[i]
		if dry[i] > old_dry[i]:
			gd += 1
			if gd > max_new:
				dry[i] = old_dry[i]


func _step_ice(cur: int, dfc: float, rad: float, n_ice: int, n_tundra: int, n01: float, painted_g: bool, ice_on: bool, temp: float) -> int:
	if painted_g and (ice_on or temp < C.SNOW_TEMP + 0.25):
		return ICE_SHEET
	if painted_g and not ice_on and temp > C.SNOW_TEMP + 0.2:
		if cur == ICE_SHEET:
			return ICE_TUNDRA
		return ICE_NONE
	var ring_lo: float = rad - C.ICE_RING_WIDTH
	var want := ICE_NONE
	if rad > 0.001:
		if dfc < ring_lo:
			want = ICE_SHEET
		elif dfc <= rad:
			if n_ice >= 1 or painted_g or n01 < 0.16:
				want = ICE_SHEET
			else:
				want = ICE_TUNDRA
		elif dfc <= rad + C.TUNDRA_RING:
			if n_ice >= 1 or n_tundra >= 2 or n01 < 0.22:
				want = ICE_TUNDRA
	if not ice_on and dfc > rad + 0.002:
		want = ICE_NONE
		if cur == ICE_SHEET:
			return ICE_TUNDRA
		if cur == ICE_TUNDRA:
			return ICE_NONE
		return ICE_NONE
	if want == cur:
		return cur
	if want > cur:
		return mini(cur + 1, want) if not (dfc < ring_lo and want == ICE_SHEET) else ICE_SHEET
	# recover slower: one step down
	return maxi(cur - 1, want)


func _step_dry(cur: int, rd: float, rain: float, n_drier: int, dry_on: bool, flood_on: bool, base: int) -> int:
	var beyond := rd > dry_line
	var near_front := rd > dry_line - 0.04
	var edge := n_drier >= C.NEIGHBOR_MIN and near_front
	if flood_on or rain > C.WETLAND_RAIN:
		return maxi(0, cur - 1)
	if not dry_on:
		# Inverse of drought: wet line walks back out. One stage per day.
		# Use <= so cells with rd==1 (far land) recover once dry_line returns to 1.
		if rd <= dry_line or rain > C.PLAINS_CONVERT + C.HYSTERESIS_RAIN:
			return maxi(0, cur - 1)
		return cur
	var can := beyond or edge
	if not can:
		return cur
	if rain < C.DESERT_RAIN and cur >= 3:
		return 4
	if cur < 3:
		return cur + 1
	if cur == 3 and rain < C.DESERT_RAIN + 0.08:
		return 4
	return cur


func _step_wet(cur: int, bw: bool, rd: float, rain: float, n_wet: int, flood_on: bool) -> int:
	var width: float = Eval.river_width(rain)
	if flood_on or rain > 0.0:
		if bw or rd < C.WATER_WIDEN_DIST * maxf(rain, 0.05):
			return 1
		return cur
	if not bw and rd > width:
		return 0
	if bw:
		if rd <= width:
			return 1
		# bank erosion: lose wet if few wet neighbors
		if rain < 0.0 and n_wet < 4:
			return 0
		return 1
	return 0


func _count_ice(buf: PackedByteArray, gx: int, gy: int) -> int:
	return _count_pred(buf, gx, gy, ICE_SHEET, true)


func _count_tundra(buf: PackedByteArray, gx: int, gy: int) -> int:
	var n := 0
	for oy in range(-1, 2):
		for ox in range(-1, 2):
			if ox == 0 and oy == 0:
				continue
			var x := gx + ox
			var y := gy + oy
			if x < 0 or y < 0 or x >= C.FRONT_GRID or y >= C.FRONT_GRID:
				continue
			if int(buf[grid_index(x, y)]) == ICE_TUNDRA:
				n += 1
	return n


func _count_drier(buf: PackedByteArray, gx: int, gy: int, self_d: int) -> int:
	var n := 0
	for oy in range(-1, 2):
		for ox in range(-1, 2):
			if ox == 0 and oy == 0:
				continue
			var x := gx + ox
			var y := gy + oy
			if x < 0 or y < 0 or x >= C.FRONT_GRID or y >= C.FRONT_GRID:
				continue
			if int(buf[grid_index(x, y)]) > self_d:
				n += 1
	return n


func _count_wet(buf: PackedByteArray, gx: int, gy: int) -> int:
	return _count_pred(buf, gx, gy, 1, false)


func _count_pred(buf: PackedByteArray, gx: int, gy: int, val: int, _ice: bool) -> int:
	var n := 0
	for oy in range(-1, 2):
		for ox in range(-1, 2):
			if ox == 0 and oy == 0:
				continue
			var x := gx + ox
			var y := gy + oy
			if x < 0 or y < 0 or x >= C.FRONT_GRID or y >= C.FRONT_GRID:
				continue
			if int(buf[grid_index(x, y)]) == val:
				n += 1
	return n


func _bake_ids() -> void:
	for gy in C.FRONT_GRID:
		for gx in C.FRONT_GRID:
			var i := grid_index(gx, gy)
			var base: int = int(_base[i]) if _base.size() > i else Eval.BIOME_SAVANNA
			ids[i] = _id_from_stages(base, int(ice[i]), int(dry[i]), int(wet[i]))
	_upload_tex()


func _upload_tex() -> void:
	var img := Image.create_from_data(C.FRONT_GRID, C.FRONT_GRID, false, Image.FORMAT_R8, ids)
	if _tex == null:
		_tex = ImageTexture.create_from_image(img)
	else:
		_tex.update(img)


func get_texture() -> Texture2D:
	ensure_init()
	return _tex


func to_blob() -> Dictionary:
	return {
		"dry_line": dry_line,
		"ice": Marshalls.raw_to_base64(ice),
		"dry": Marshalls.raw_to_base64(dry),
		"wet": Marshalls.raw_to_base64(wet),
	}


func from_blob(d: Dictionary) -> void:
	ensure_init()
	dry_line = float(d.get("dry_line", dry_line))
	if d.has("ice"):
		ice = Marshalls.base64_to_raw(str(d["ice"]))
	if d.has("dry"):
		dry = Marshalls.base64_to_raw(str(d["dry"]))
	if d.has("wet"):
		wet = Marshalls.base64_to_raw(str(d["wet"]))
	_bake_ids()


func get_last_metrics() -> Dictionary:
	return _last_metrics.duplicate()


func collect_step_metrics(old_ice: PackedByteArray, old_dry: PackedByteArray, old_wet: PackedByteArray, rad: float) -> Dictionary:
	var gsz: int = C.FRONT_GRID
	var ring_lo: float = rad - C.ICE_RING_WIDTH
	var land := 0
	var ice_sheet := 0
	var ice_tundra := 0
	var ice_edge := 0
	var new_ice := 0
	var new_ice_ring := 0
	var new_ice_interior := 0
	var new_ice_outside := 0
	var new_ice_nb := 0
	var ice_dfc_sum := 0.0
	var ice_dfc_max := 0.0
	var dry_n := [0, 0, 0, 0, 0]
	var new_dry := 0
	var new_des := 0
	var new_dry_beyond := 0
	var new_dry_nb := 0
	var new_des_rd_sum := 0.0
	var new_dry_rd_sum := 0.0
	var wet_n := 0
	var wet_lost := 0
	var wet_gained := 0
	for gy in gsz:
		for gx in gsz:
			var i := grid_index(gx, gy)
			if int(_ocean[i]) == 1:
				continue
			land += 1
			var dfc: float = float(_dfc[i])
			var rd: float = float(_rd[i])
			var ic: int = int(ice[i])
			var od: int = int(old_dry[i]) if old_dry.size() > i else 0
			var nd: int = int(dry[i])
			if ic == ICE_SHEET:
				ice_sheet += 1
				ice_dfc_sum += dfc
				if dfc > ice_dfc_max:
					ice_dfc_max = dfc
				if _count_ice(ice, gx, gy) < 8:
					ice_edge += 1
			elif ic == ICE_TUNDRA:
				ice_tundra += 1
			if ic == ICE_SHEET and int(old_ice[i]) != ICE_SHEET:
				new_ice += 1
				if dfc < ring_lo:
					new_ice_interior += 1
				elif dfc <= rad:
					new_ice_ring += 1
				else:
					new_ice_outside += 1
				if _count_ice(old_ice, gx, gy) >= 1:
					new_ice_nb += 1
			var ds: int = clampi(nd, 0, 4)
			dry_n[ds] = int(dry_n[ds]) + 1
			if nd > od:
				new_dry += 1
				new_dry_rd_sum += rd
				if rd > dry_line:
					new_dry_beyond += 1
				if _count_drier(old_dry, gx, gy, od) >= C.NEIGHBOR_MIN:
					new_dry_nb += 1
			if nd == 4 and od != 4:
				new_des += 1
				new_des_rd_sum += rd
			if int(wet[i]) == 1:
				wet_n += 1
			if int(old_wet[i]) == 1 and int(wet[i]) == 0:
				wet_lost += 1
			if int(old_wet[i]) == 0 and int(wet[i]) == 1:
				wet_gained += 1
	return {
		"t": "front_tick",
		"land": land,
		"ice_sheet": ice_sheet,
		"ice_tundra": ice_tundra,
		"ice_edge": ice_edge,
		"ice_edge_frac": float(ice_edge) / float(maxi(ice_sheet, 1)),
		"ice_mean_dfc": ice_dfc_sum / float(maxi(ice_sheet, 1)),
		"ice_max_dfc": ice_dfc_max,
		"new_ice": new_ice,
		"new_ice_ring": new_ice_ring,
		"new_ice_interior": new_ice_interior,
		"new_ice_outside": new_ice_outside,
		"new_ice_neighbor": new_ice_nb,
		"new_ice_margin_frac": float(new_ice - new_ice_interior) / float(maxi(new_ice, 1)),
		"new_ice_interior_frac": float(new_ice_interior) / float(maxi(new_ice, 1)),
		"dry0": dry_n[0],
		"dry1": dry_n[1],
		"dry2": dry_n[2],
		"dry3": dry_n[3],
		"dry4": dry_n[4],
		"new_dry": new_dry,
		"new_des": new_des,
		"new_dry_beyond": new_dry_beyond,
		"new_dry_neighbor": new_dry_nb,
		"new_des_mean_rd": new_des_rd_sum / float(maxi(new_des, 1)),
		"new_dry_mean_rd": new_dry_rd_sum / float(maxi(new_dry, 1)),
		"wet": wet_n,
		"wet_lost": wet_lost,
		"wet_gained": wet_gained,
		"dry_line": dry_line,
		"ice_radius": rad,
		"new_ice_share": float(new_ice) / float(maxi(land, 1)),
		"new_dry_share": float(new_dry) / float(maxi(land, 1)),
		"new_des_share": float(new_des) / float(maxi(land, 1)),
	}


func _bump() -> void:
	var cs: Node = get_node_or_null("/root/ClimateState")
	if cs and cs.has_method("invalidate_cache"):
		cs.invalidate_cache()
	# do not recurse: invalidate only clears query cache
