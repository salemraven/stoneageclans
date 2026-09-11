extends Node
## Autoload: data/biome_life.json. Empty sprite paths are OK until art exists.

const PATH := "res://data/biome_life.json"
const BiomePaletteRes = preload("res://scripts/world/biome_palette.gd")

var _data: Dictionary = {"flora": [], "fauna": []}


func _ready() -> void:
	reload()


func reload() -> Dictionary:
	_data = {"flora": [], "fauna": []}
	if not FileAccess.file_exists(PATH):
		return _data
	var f := FileAccess.open(PATH, FileAccess.READ)
	if f == null:
		return _data
	var txt := f.get_as_text()
	f.close()
	var parsed: Variant = JSON.parse_string(txt)
	if parsed is Dictionary:
		_data = parsed
	return _data


func flora() -> Array:
	return _data.get("flora", []) as Array


func fauna() -> Array:
	return _data.get("fauna", []) as Array


func fauna_entry(id: String) -> Dictionary:
	for e in fauna():
		if e is Dictionary and str(e.get("id", "")) == id:
			return e
	return {}


func biome_name_from_id(biome_id: int) -> String:
	return BiomePaletteRes.biome_to_name(BiomePaletteRes.biome_from_index(biome_id))


func legal_flora(biome_id: int, near_water: bool) -> Array:
	var name := biome_name_from_id(biome_id)
	var out: Array = []
	for e in flora():
		if not e is Dictionary:
			continue
		var homes: Array = e.get("home_biomes", [])
		if name not in homes:
			continue
		if bool(e.get("near_water", false)) and not near_water:
			continue
		out.append(e)
	return out


func legal_fauna(biome_id: int) -> Array:
	var name := biome_name_from_id(biome_id)
	var out: Array = []
	for e in fauna():
		if not e is Dictionary:
			continue
		var homes: Array = e.get("home_biomes", [])
		if name in homes or homes.is_empty():
			out.append(e)
	return out


func can_spawn_fauna(id: String, biome_id: int, river_dist01: float = 1.0, rng: RandomNumberGenerator = null) -> bool:
	var e := fauna_entry(id)
	if e.is_empty():
		return true
	var name := biome_name_from_id(biome_id)
	var homes: Array = e.get("home_biomes", [])
	if not homes.is_empty() and name not in homes:
		return false
	var sparse: Array = e.get("sparse_in", [])
	if name in sparse:
		var roll := rng.randf() if rng else 0.15
		if roll > 0.22:
			return false
	if bool(e.get("prefer_rivers", false)) and river_dist01 > 0.22:
		var roll2 := rng.randf() if rng else 0.4
		if roll2 > 0.55:
			return false
	return true


func spawn_weight(id: String, biome_id: int) -> float:
	var e := fauna_entry(id)
	if e.is_empty():
		return 1.0
	var name := biome_name_from_id(biome_id)
	if name in e.get("sparse_in", []):
		return 0.18
	return 1.0
