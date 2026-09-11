class_name BiomePalette
extends RefCounted
## Authoring legend + gameplay biome IDs for the authored island map.

enum Biome {
	OCEAN,
	SAVANNA,
	DESERT,
	JUNGLE,
	SWAMP,
	GLACIER,
	FOREST_PATCH,
	RIVER,
	BEACH,
	TUNDRA,
}

const BIOME_NAMES: Dictionary = {
	Biome.OCEAN: "ocean",
	Biome.SAVANNA: "savanna",
	Biome.DESERT: "desert",
	Biome.JUNGLE: "jungle",
	Biome.SWAMP: "swamp",
	Biome.GLACIER: "glacier",
	Biome.FOREST_PATCH: "forest_patch",
	Biome.RIVER: "river",
	Biome.BEACH: "beach",
	Biome.TUNDRA: "tundra",
}

## Flat legend colors for mask authoring / nearest-color snap (display art may blend softly).
const LEGEND_COLORS: Array[Color] = [
	Color("#0066cc"), # OCEAN
	Color("#c8d878"), # SAVANNA
	Color("#e8d9a0"), # DESERT
	Color("#1a5c2e"), # JUNGLE
	Color("#4a3728"), # SWAMP
	Color("#eef4ff"), # GLACIER
	Color("#2d5a2d"), # FOREST_PATCH
	Color("#4499dd"), # RIVER
	Color("#f5e6c8"), # BEACH
	Color("#c8d0c0"), # TUNDRA (runtime climate ID, not in mask)
]

const BIOME_RESOURCE_KEYS: Dictionary = {
	"ocean": [],
	"savanna": ["grain", "fiber", "berries"],
	"plains": ["grain", "fiber", "berries"],
	"desert": ["stone", "fiber"],
	"jungle": ["fiber", "wood", "berries"],
	"swamp": ["fiber", "bugs"],
	"glacier": ["stone", "fiber"],
	"forest_patch": ["wood", "berries", "fiber", "nuts"],
	"river": ["fiber", "berries"],
	"beach": ["fiber", "stone"],
	"tundra": ["stone", "fiber"],
	# Legacy procedural labels (dev sandbox fallback).
	"forest": ["wood", "berries", "fiber", "nuts"],
	"rocky": ["stone", "fiber"],
}


static func biome_from_index(index: int) -> Biome:
	if index < 0 or index >= Biome.size():
		return Biome.SAVANNA
	return index as Biome


static func biome_to_name(biome: Biome) -> String:
	return str(BIOME_NAMES.get(biome, "savanna"))


static func name_to_biome(name: String) -> Biome:
	var key := name.to_lower()
	for b in Biome.values():
		if BIOME_NAMES.get(b, "") == key:
			return b as Biome
	match key:
		"plains":
			return Biome.SAVANNA
		"forest":
			return Biome.FOREST_PATCH
		"tundra":
			return Biome.TUNDRA
		"rocky", "alpine":
			return Biome.GLACIER
		"wetland":
			return Biome.SWAMP
		_:
			return Biome.SAVANNA


static func color_from_biome(biome: Biome) -> Color:
	var idx: int = int(biome)
	if idx >= 0 and idx < LEGEND_COLORS.size():
		return LEGEND_COLORS[idx]
	return LEGEND_COLORS[Biome.SAVANNA]


static func id_from_mask_luma(r: float) -> int:
	# Same as biome_ground.gdshader mask_to_biome_id. Mask is gray index, not legend RGB.
	return clampi(int(round(r * 9.0)), 0, 8)


static func nearest_biome(pixel: Color) -> Biome:
	var best: Biome = Biome.SAVANNA
	var best_dist: float = INF
	# Ignore alpha for painted map edges.
	var sample := Color(pixel.r, pixel.g, pixel.b, 1.0)
	for i in 9:
		var biome := i as Biome
		var legend: Color = LEGEND_COLORS[i]
		var dr: float = sample.r - legend.r
		var dg: float = sample.g - legend.g
		var db: float = sample.b - legend.b
		var dist: float = dr * dr + dg * dg + db * db
		if dist < best_dist:
			best_dist = dist
			best = biome
	return best


static func get_resources_for_biome_name(biome_name: String) -> Array:
	return (BIOME_RESOURCE_KEYS.get(biome_name, ["fiber", "berries"]) as Array).duplicate()
