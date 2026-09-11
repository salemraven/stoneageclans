class_name ClimateEval
extends RefCounted
## Shared Evaluation Contract (shader must follow the same order).

const BiomePaletteRes = preload("res://scripts/world/biome_palette.gd")
const ClimateConstantsRes = preload("res://scripts/world/climate_constants.gd")
const ClimateHashRes = preload("res://scripts/world/climate_hash.gd")

const BIOME_OCEAN := 0
const BIOME_SAVANNA := 1
const BIOME_DESERT := 2
const BIOME_JUNGLE := 3
const BIOME_SWAMP := 4
const BIOME_GLACIER := 5
const BIOME_FOREST := 6
const BIOME_RIVER := 7
const BIOME_BEACH := 8
const BIOME_TUNDRA := 9


static func dist_from_center_uv(uv: Vector2) -> float:
	return clampf(uv.distance_to(Vector2(0.5, 0.5)) / 0.7071, 0.0, 1.0)


static func river_width(rain_eff: float) -> float:
	if rain_eff >= 0.0:
		return ClimateConstantsRes.RIVER_BASE_WIDTH + rain_eff * ClimateConstantsRes.WATER_WIDEN_DIST
	return maxf(0.003, ClimateConstantsRes.RIVER_BASE_WIDTH * (1.0 + rain_eff * ClimateConstantsRes.WATER_NARROW))


static func ice_radius_from_center_temp(center_temp: float) -> float:
	if center_temp > -0.22:
		return 0.0
	return clampf((-center_temp - 0.22) / 0.78 * ClimateConstantsRes.ICE_RADIUS_MAX, 0.0, ClimateConstantsRes.ICE_RADIUS_MAX)


static func classify(
	base_biome: int,
	is_base_water: bool,
	river_dist01: float,
	temperature: float,
	rainfall: float,
	noise01: float,
	region_is_center: bool,
	dist_from_center: float = 1.0,
	ice_radius: float = 0.0,
	season_cold: float = 0.0,
	season_wet: float = 0.0
) -> Dictionary:
	if base_biome == BIOME_OCEAN and not is_base_water:
		return {"biome": BIOME_OCEAN, "water": false}

	var rain_eff: float = rainfall + season_wet
	var width: float = river_width(rain_eff)
	var water := false
	if rain_eff > 0.0 and river_dist01 < ClimateConstantsRes.WATER_WIDEN_DIST * rain_eff:
		water = true
	if is_base_water and river_dist01 <= width:
		water = true
	if water:
		return {"biome": BIOME_RIVER, "water": true}

	var rad: float = ice_radius
	if rad <= 0.0 and temperature < -0.22 and region_is_center:
		rad = ice_radius_from_center_temp(temperature)
	var edge: float = 0.035 * (noise01 - 0.5)
	if rad > 0.001 and dist_from_center <= rad + edge:
		return {"biome": BIOME_GLACIER, "water": false}
	if rad > 0.001 and dist_from_center <= rad + ClimateConstantsRes.TUNDRA_RING + edge:
		return {"biome": BIOME_TUNDRA, "water": false}
	if base_biome == BIOME_GLACIER and rad <= 0.001 and temperature > ClimateConstantsRes.SNOW_TEMP + 0.2:
		pass
	elif base_biome == BIOME_GLACIER and rad <= 0.001:
		return {"biome": BIOME_GLACIER, "water": false}

	# Cold wins: no desert if this would be tundra from residual cold (mild, near center).
	var cold_eff: float = temperature - season_cold
	if cold_eff < ClimateConstantsRes.TUNDRA_TEMP and dist_from_center < 0.22 and noise01 < 0.55:
		return {"biome": BIOME_TUNDRA, "water": false}

	var oasis: float = 0.0
	if rain_eff < 0.0:
		oasis = (1.0 - clampf(river_dist01, 0.0, 1.0)) * ClimateConstantsRes.OASIS_BOOST
	var local_rain: float = rain_eff + oasis
	var biome := base_biome
	if biome == BIOME_FOREST or biome == BIOME_JUNGLE or biome == BIOME_SWAMP:
		if local_rain < ClimateConstantsRes.PLAINS_CONVERT and noise01 < 0.62:
			biome = BIOME_SAVANNA
	if biome == BIOME_FOREST and local_rain < ClimateConstantsRes.FOREST_RAIN_THIN and noise01 < -local_rain:
		biome = BIOME_SAVANNA

	if (
		biome == BIOME_SAVANNA
		and local_rain < ClimateConstantsRes.DESERT_RAIN
		and river_dist01 > ClimateConstantsRes.DESERT_RIVER_KEEP
		and cold_eff >= ClimateConstantsRes.TUNDRA_TEMP
		and noise01 < (-local_rain)
	):
		return {"biome": BIOME_DESERT, "water": false}

	if rain_eff > ClimateConstantsRes.WETLAND_RAIN and river_dist01 < 0.18:
		if noise01 < rain_eff and base_biome != BIOME_OCEAN:
			return {"biome": BIOME_SWAMP, "water": false}

	if biome == BIOME_SAVANNA and rain_eff > 0.2 and noise01 > 0.72:
		biome = BIOME_FOREST
	return {"biome": biome, "water": false}


static func hash_noise(mask_x: int, mask_y: int, world_seed: int) -> float:
	return ClimateHashRes.hash_01(mask_x, mask_y, world_seed)
