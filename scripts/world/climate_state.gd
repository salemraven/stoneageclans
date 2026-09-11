extends Node
## Regional temperature/rainfall. Climate off unless --climate or enable_for_tests().

const ClimateConstantsRes = preload("res://scripts/world/climate_constants.gd")
const ClimateEvalRes = preload("res://scripts/world/climate_eval.gd")

signal climate_changed

var climate_enabled: bool = false
var world_seed: int = 882001
var ritual_pressure: float = 0.0
var active_event: String = ""  # joined flags for logs
var event_ice: bool = false
var event_drought: bool = false
var event_flood: bool = false
var sim_day: int = 0
var ice_radius: float = 0.0
var season_phase: float = 0.0
var season_cold: float = 0.0
var season_wet: float = 0.0

var temperature: Dictionary = {}
var rainfall: Dictionary = {}
var moisture_stress: Dictionary = {}
var cold_stress: Dictionary = {}

var _cache: Dictionary = {}
var _cache_generation: int = 0


func _ready() -> void:
	_reset_knobs()
	if OS.get_name() != "Web":
		for a in OS.get_cmdline_args():
			if a == "--climate":
				climate_enabled = true


func enable_for_tests() -> void:
	climate_enabled = true


func reset_knobs() -> void:
	sim_day = 0
	active_event = ""
	event_ice = false
	event_drought = false
	event_flood = false
	ritual_pressure = 0.0
	ice_radius = 0.0
	season_phase = 0.0
	season_cold = 0.0
	season_wet = 0.0
	_reset_knobs()
	var bf: Node = get_node_or_null("/root/BiomeFronts")
	if bf and bf.has_method("reset_grid"):
		bf.reset_grid()


func _reset_knobs() -> void:
	for r in ClimateConstantsRes.REGIONS:
		temperature[r] = 0.0
		rainfall[r] = 0.0
		moisture_stress[r] = 0.0
		cold_stress[r] = 0.0
	_bump_cache()


func set_event_flag(name: String, on: bool) -> void:
	match name:
		"ice_age":
			event_ice = on
		"drought":
			event_drought = on
		"flood":
			event_flood = on
		"":
			event_ice = false
			event_drought = false
			event_flood = false
	_sync_active_event_string()
	_bump_cache()


func _sync_active_event_string() -> void:
	var parts: PackedStringArray = []
	if event_ice:
		parts.append("ice_age")
	if event_drought:
		parts.append("drought")
	if event_flood:
		parts.append("flood")
	active_event = ",".join(parts)


func has_event(name: String) -> bool:
	match name:
		"ice_age":
			return event_ice
		"drought":
			return event_drought
		"flood":
			return event_flood
	return active_event == name


func sync_events_from_string() -> void:
	if active_event == "":
		event_ice = false
		event_drought = false
		event_flood = false
		return
	event_ice = active_event.contains("ice_age")
	event_drought = active_event.contains("drought")
	event_flood = active_event.contains("flood")


func season_offsets() -> Vector2:
	## x = cold add (winter > 0), y = wet add
	var ang: float = season_phase * TAU
	return Vector2(
		ClimateConstantsRes.SEASON_COLD_AMP * sin(ang),
		ClimateConstantsRes.SEASON_WET_AMP * cos(ang)
	)


func effective_ice_radius() -> float:
	var from_temp: float = ClimateEvalRes.ice_radius_from_center_temp(float(temperature.get("CENTER", 0.0)))
	var extra: float = 0.02 * maxf(season_cold, 0.0)
	return minf(ClimateConstantsRes.ICE_RADIUS_MAX, maxf(ice_radius, from_temp) + extra)


func world_to_mask_cell(world_pos: Vector2, world_size: Vector2, mask_size: Vector2i) -> Vector2i:
	var wx: float = clampf(world_pos.x, 0.0, maxf(world_size.x - 1.0, 0.0))
	var wy: float = clampf(world_pos.y, 0.0, maxf(world_size.y - 1.0, 0.0))
	var mx: int = clampi(int(floor(wx / maxf(world_size.x / float(mask_size.x), 1.0))), 0, mask_size.x - 1)
	var my: int = clampi(int(floor(wy / maxf(world_size.y / float(mask_size.y), 1.0))), 0, mask_size.y - 1)
	return Vector2i(mx, my)


func sample_temp_rain(world_uv: Vector2) -> Vector2:
	## Bilinear over 3x3 region lattice. uv in 0..1
	var gx: float = clampf(world_uv.x, 0.0, 1.0) * 2.0
	var gy: float = clampf(world_uv.y, 0.0, 1.0) * 2.0
	var ix: int = clampi(int(floor(gx)), 0, 1)
	var iy: int = clampi(int(floor(gy)), 0, 1)
	var fx: float = gx - float(ix)
	var fy: float = gy - float(iy)
	var t00 := _temp_at(ix, iy)
	var t10 := _temp_at(ix + 1, iy)
	var t01 := _temp_at(ix, iy + 1)
	var t11 := _temp_at(ix + 1, iy + 1)
	var r00 := _rain_at(ix, iy)
	var r10 := _rain_at(ix + 1, iy)
	var r01 := _rain_at(ix, iy + 1)
	var r11 := _rain_at(ix + 1, iy + 1)
	var t: float = lerpf(lerpf(t00, t10, fx), lerpf(t01, t11, fx), fy)
	var r: float = lerpf(lerpf(r00, r10, fx), lerpf(r01, r11, fx), fy)
	return Vector2(t, r)


func region_name_at_grid(ix: int, iy: int) -> String:
	## ix,iy 0..2  (NW N NE / W C E / SW S SE)
	var names: Array = [
		["NW", "N", "NE"],
		["W", "CENTER", "E"],
		["SW", "S", "SE"],
	]
	ix = clampi(ix, 0, 2)
	iy = clampi(iy, 0, 2)
	return str(names[iy][ix])


func _temp_at(ix: int, iy: int) -> float:
	var key := region_name_at_grid(ix, iy)
	return float(cold_stress.get(key, temperature.get(key, 0.0)))


func _rain_at(ix: int, iy: int) -> float:
	var key := region_name_at_grid(ix, iy)
	return float(moisture_stress.get(key, rainfall.get(key, 0.0)))


func is_center_uv(world_uv: Vector2) -> bool:
	return world_uv.distance_to(Vector2(0.5, 0.5)) < 0.18


func set_region_knobs(region: String, temp: float, rain: float) -> void:
	temperature[region] = clampf(temp, -1.0, 1.0)
	rainfall[region] = clampf(rain, -1.0, 1.0)
	cold_stress[region] = temperature[region]
	moisture_stress[region] = rainfall[region]
	var bf: Node = get_node_or_null("/root/BiomeFronts")
	if climate_enabled and bf and bf.has_method("step"):
		bf.step()
	_bump_cache()


func apply_payload(payload: Dictionary) -> void:
	sim_day = int(payload.get("day", sim_day))
	active_event = str(payload.get("event", active_event))
	ritual_pressure = float(payload.get("ritual", ritual_pressure))
	ice_radius = float(payload.get("ice_radius", ice_radius))
	season_phase = float(payload.get("season_phase", season_phase))
	event_ice = bool(payload.get("event_ice", event_ice))
	event_drought = bool(payload.get("event_drought", event_drought))
	event_flood = bool(payload.get("event_flood", event_flood))
	var t: Dictionary = payload.get("temperature", {}) as Dictionary
	var r: Dictionary = payload.get("rainfall", {}) as Dictionary
	var cs: Dictionary = payload.get("cold_stress", {}) as Dictionary
	var ms: Dictionary = payload.get("moisture_stress", {}) as Dictionary
	for k in ClimateConstantsRes.REGIONS:
		if t.has(k):
			temperature[k] = float(t[k])
		if r.has(k):
			rainfall[k] = float(r[k])
		if cs.has(k):
			cold_stress[k] = float(cs[k])
		if ms.has(k):
			moisture_stress[k] = float(ms[k])
	_sync_active_event_string()
	var bf: Node = get_node_or_null("/root/BiomeFronts")
	if bf and payload.has("fronts") and bf.has_method("from_blob"):
		bf.from_blob(payload["fronts"] as Dictionary)
	_bump_cache()


func to_payload() -> Dictionary:
	var fronts := {}
	var bf: Node = get_node_or_null("/root/BiomeFronts")
	if bf and bf.has_method("to_blob"):
		fronts = bf.to_blob()
	return {
		"day": sim_day,
		"event": active_event,
		"event_ice": event_ice,
		"event_drought": event_drought,
		"event_flood": event_flood,
		"ritual": ritual_pressure,
		"ice_radius": ice_radius,
		"season_phase": season_phase,
		"temperature": temperature.duplicate(),
		"rainfall": rainfall.duplicate(),
		"cold_stress": cold_stress.duplicate(),
		"moisture_stress": moisture_stress.duplicate(),
		"fronts": fronts,
		"dry_line": float(fronts.get("dry_line", 1.0)),
	}


func payload_hash() -> int:
	return hash(JSON.stringify(to_payload()))


func cache_get(key: Vector2i) -> Variant:
	if _cache.has(key):
		return _cache[key]
	return null


func cache_put(key: Vector2i, value: Dictionary) -> void:
	_cache[key] = value


func cache_generation() -> int:
	return _cache_generation


func invalidate_cache() -> void:
	_bump_cache()


func apply_to_material(mat: ShaderMaterial, river_tex: Texture2D = null) -> void:
	if mat == null:
		return
	var temps := PackedFloat32Array()
	var rains := PackedFloat32Array()
	temps.resize(9)
	rains.resize(9)
	for i in 9:
		var name: String = str(ClimateConstantsRes.REGIONS[i])
		temps[i] = float(cold_stress.get(name, temperature.get(name, 0.0)))
		rains[i] = float(moisture_stress.get(name, rainfall.get(name, 0.0)))
	mat.set_shader_parameter("climate_enabled", climate_enabled)
	mat.set_shader_parameter("climate_world_seed", world_seed)
	mat.set_shader_parameter("climate_temp", temps)
	mat.set_shader_parameter("climate_rain", rains)
	mat.set_shader_parameter("u_snow_temp", ClimateConstantsRes.SNOW_TEMP)
	mat.set_shader_parameter("u_tundra_temp", ClimateConstantsRes.TUNDRA_TEMP)
	mat.set_shader_parameter("u_desert_rain", ClimateConstantsRes.DESERT_RAIN)
	mat.set_shader_parameter("u_wetland_rain", ClimateConstantsRes.WETLAND_RAIN)
	mat.set_shader_parameter("u_water_widen", ClimateConstantsRes.WATER_WIDEN_DIST)
	mat.set_shader_parameter("u_water_narrow", ClimateConstantsRes.WATER_NARROW)
	mat.set_shader_parameter("u_forest_thin", ClimateConstantsRes.FOREST_RAIN_THIN)
	mat.set_shader_parameter("u_center_snow_bias", ClimateConstantsRes.CENTER_SNOW_BIAS)
	mat.set_shader_parameter("u_ice_radius", effective_ice_radius())
	mat.set_shader_parameter("u_season_cold", season_cold)
	mat.set_shader_parameter("u_season_wet", season_wet)
	mat.set_shader_parameter("u_oasis_boost", ClimateConstantsRes.OASIS_BOOST)
	mat.set_shader_parameter("u_plains_convert", ClimateConstantsRes.PLAINS_CONVERT)
	mat.set_shader_parameter("u_desert_river_keep", ClimateConstantsRes.DESERT_RIVER_KEEP)
	mat.set_shader_parameter("u_tundra_ring", ClimateConstantsRes.TUNDRA_RING)
	mat.set_shader_parameter("u_river_base_width", ClimateConstantsRes.RIVER_BASE_WIDTH)
	if river_tex:
		mat.set_shader_parameter("river_distance_tex", river_tex)
		mat.set_shader_parameter("use_river_distance", true)
	var bf: Node = get_node_or_null("/root/BiomeFronts")
	if bf and bf.has_method("get_texture"):
		var stx: Texture2D = bf.get_texture()
		if stx:
			mat.set_shader_parameter("succession_tex", stx)
			mat.set_shader_parameter("use_succession", climate_enabled)


func _bump_cache() -> void:
	_cache.clear()
	_cache_generation += 1
	climate_changed.emit()
