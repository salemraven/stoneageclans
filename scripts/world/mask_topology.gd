class_name MaskTopology
extends RefCounted
## Tile rules for biome_mask + water_layer. Mirrors tools/clean_biome_mask_specks.py
## and tools/biome_mask_shape_rules.py — keep the two in sync.
##
## Source of truth
##   * water_layer.png = hand-painted rivers. NEVER modified by fix().
##   * biome_mask.png  = gameplay grid. Only this is edited.
##   * Organic region SHAPE is produced offline by tools/shape_biome_regions.py
##     (region-level smooth + seeded warp). Straight borders are only DETECTED here.
##
## Rules (3+ of 4 cardinal neighbours)
##   * land tile with 3+ OCEAN sides (map edge counts as ocean) -> ocean
##   * ocean tile with 3+ land sides -> savanna
##   * ocean not connected to the map-edge sea -> savanna
##   * land tile with 3+ sides of one other land biome -> that biome (rivers/ocean skipped)
##   * desert never touches a river: desert tile beside river -> savanna

const OCEAN := 0
const SAVANNA := 1
const DESERT := 2
const JUNGLE := 3
const SWAMP := 4
const GLACIER := 5
const BEACH := 8
const LAND_SPECK_BIOMES: Array[int] = [SAVANNA, DESERT, JUNGLE, SWAMP, GLACIER, BEACH]
const BIOME_SCALE := 9.0
const MIN_OPPOSING_SIDES := 3

## Straight-border detection (see biome_mask_shape_rules.py for the derivation of 28).
const MIN_STRAIGHT_REPORT_LEN := 8
const MIN_STRAIGHT_BORDER_LEN := 28
const STRAIGHT_GAP_MERGE := 2

const CARDINAL: Array[Vector2i] = [
	Vector2i(0, -1),
	Vector2i(0, 1),
	Vector2i(-1, 0),
	Vector2i(1, 0),
]


static func biome_id_from_pixel(p: Color) -> int:
	return clampi(int(roundf(p.r * BIOME_SCALE)), 0, 8)


static func pixel_from_biome_id(biome_id: int) -> Color:
	var v := float(biome_id) / BIOME_SCALE
	return Color(v, v, v, 1.0)


# --- cell predicates --------------------------------------------------------------


static func is_water_cell(water: Image, x: int, y: int) -> bool:
	if water == null:
		return false
	if x < 0 or y < 0 or x >= water.get_width() or y >= water.get_height():
		return false
	return water.get_pixel(x, y).r > 0.5


static func is_ocean_cell(mask: Image, water: Image, x: int, y: int) -> bool:
	if is_water_cell(water, x, y):
		return false
	if x < 0 or y < 0 or x >= mask.get_width() or y >= mask.get_height():
		return false
	return biome_id_from_pixel(mask.get_pixel(x, y)) == OCEAN


## Ocean or off-map. Rivers are NOT "ocean" for topology rules.
static func is_ocean_or_edge(mask: Image, x: int, y: int) -> bool:
	if x < 0 or y < 0 or x >= mask.get_width() or y >= mask.get_height():
		return true
	return biome_id_from_pixel(mask.get_pixel(x, y)) == OCEAN


static func is_land_cell(mask: Image, water: Image, x: int, y: int) -> bool:
	if x < 0 or y < 0 or x >= mask.get_width() or y >= mask.get_height():
		return false
	if biome_id_from_pixel(mask.get_pixel(x, y)) == OCEAN:
		return false
	return not is_water_cell(water, x, y)


static func count_cardinal_ocean(mask: Image, x: int, y: int) -> int:
	var count := 0
	for d in CARDINAL:
		if is_ocean_or_edge(mask, x + d.x, y + d.y):
			count += 1
	return count


static func count_cardinal_land(mask: Image, water: Image, x: int, y: int) -> int:
	var count := 0
	for d in CARDINAL:
		if is_land_cell(mask, water, x + d.x, y + d.y):
			count += 1
	return count


static func count_cardinal_river(water: Image, x: int, y: int) -> int:
	var count := 0
	for d in CARDINAL:
		if is_water_cell(water, x + d.x, y + d.y):
			count += 1
	return count


static func _land_biome_at(mask: Image, water: Image, x: int, y: int) -> int:
	if not is_land_cell(mask, water, x, y):
		return -1
	return biome_id_from_pixel(mask.get_pixel(x, y))


# --- validate ------------------------------------------------------------------------


static func validate(mask: Image, water: Image) -> Dictionary:
	var report := {
		"ok": true,
		"grass_in_water": 0,
		"ocean_in_grass": 0,
		"desert_on_river": 0,
		"biome_specks": 0,
		"straight_borders": 0,
		"straight_longest": 0,
	}
	if mask == null or mask.is_empty():
		report["ok"] = false
		return report

	var w := mask.get_width()
	var h := mask.get_height()
	for y in range(h):
		for x in range(w):
			if is_land_cell(mask, water, x, y):
				if count_cardinal_ocean(mask, x, y) >= MIN_OPPOSING_SIDES:
					report["grass_in_water"] += 1
				if biome_id_from_pixel(mask.get_pixel(x, y)) == DESERT and count_cardinal_river(water, x, y) > 0:
					report["desert_on_river"] += 1
			elif is_ocean_cell(mask, water, x, y) and count_cardinal_land(mask, water, x, y) >= MIN_OPPOSING_SIDES:
				report["ocean_in_grass"] += 1

	report["biome_specks"] = count_biome_specks(mask, water)
	var segments := find_straight_borders(mask, water, MIN_STRAIGHT_REPORT_LEN)
	var serious := 0
	var longest := 0
	for seg in segments:
		var length: int = seg["length"]
		longest = maxi(longest, length)
		if length >= MIN_STRAIGHT_BORDER_LEN:
			serious += 1
	report["straight_borders"] = serious
	report["straight_longest"] = longest
	report["ok"] = (
		report["grass_in_water"] == 0
		and report["ocean_in_grass"] == 0
		and report["desert_on_river"] == 0
		and report["biome_specks"] == 0
		and report["straight_borders"] == 0
	)
	return report


static func format_report(report: Dictionary) -> String:
	if report.get("ok", false):
		return "✓ Map OK (topology + shape rules)"
	return (
		"⚠ Map issues:\n"
		+ "  land in ocean (3+ sides): %d\n" % report.get("grass_in_water", 0)
		+ "  ocean in land (3+ sides): %d\n" % report.get("ocean_in_grass", 0)
		+ "  desert touching river: %d\n" % report.get("desert_on_river", 0)
		+ "  biome specks (3+ sides): %d\n" % report.get("biome_specks", 0)
		+ "  straight borders (>=%d tiles): %d" % [MIN_STRAIGHT_BORDER_LEN, report.get("straight_borders", 0)]
	)


static func format_shape_report(mask: Image, water: Image) -> String:
	var specks := count_biome_specks(mask, water)
	var segments := find_straight_borders(mask, water, MIN_STRAIGHT_REPORT_LEN)
	var serious: Array = []
	var longest := 0
	for seg in segments:
		longest = maxi(longest, int(seg["length"]))
		if int(seg["length"]) >= MIN_STRAIGHT_BORDER_LEN:
			serious.append(seg)
	var lines: PackedStringArray = PackedStringArray([
		"biome_specks=%d" % specks,
		"straight_borders=%d (minor_%d_%d=%d, longest=%d)" % [
			serious.size(), MIN_STRAIGHT_REPORT_LEN, MIN_STRAIGHT_BORDER_LEN - 1,
			segments.size() - serious.size(), longest,
		],
	])
	serious.sort_custom(func(a, b): return int(a["length"]) > int(b["length"]))
	var limit := mini(serious.size(), 6)
	for i in range(limit):
		var seg: Dictionary = serious[i]
		lines.append(
			"  %s biome=%d len=%d row=%d col=%d span=%d-%d" % [
				seg["axis"], seg["biome"], seg["length"], seg["row"], seg["col"], seg["start"], seg["end"],
			]
		)
	if serious.size() > limit:
		lines.append("  ... +%d more" % (serious.size() - limit))
	return "\n".join(lines)


# --- biome specks (3/4 rule) ------------------------------------------------------


static func _count_land_biome_neighbors(mask: Image, water: Image, x: int, y: int, biome_id: int) -> int:
	var count := 0
	for d in CARDINAL:
		if _land_biome_at(mask, water, x + d.x, y + d.y) == biome_id:
			count += 1
	return count


static func _speck_target_biome(mask: Image, water: Image, x: int, y: int) -> int:
	var current := _land_biome_at(mask, water, x, y)
	if current < 0:
		return -1
	var best_biome := -1
	var best_count := 0
	for biome_id in LAND_SPECK_BIOMES:
		if biome_id == current:
			continue
		var n := _count_land_biome_neighbors(mask, water, x, y, biome_id)
		if n >= MIN_OPPOSING_SIDES and n > best_count:
			best_biome = biome_id
			best_count = n
	return best_biome


static func count_biome_specks(mask: Image, water: Image) -> int:
	var specks := 0
	for y in range(mask.get_height()):
		for x in range(mask.get_width()):
			if _speck_target_biome(mask, water, x, y) >= 0:
				specks += 1
	return specks


static func _clean_all_land_biome_specks(mask: Image, water: Image) -> int:
	var w := mask.get_width()
	var h := mask.get_height()
	var fixed := 0
	for _i in range(64):
		var changed := 0
		for y in range(h):
			for x in range(w):
				var target := _speck_target_biome(mask, water, x, y)
				if target < 0:
					continue
				mask.set_pixel(x, y, pixel_from_biome_id(target))
				changed += 1
		fixed += changed
		if changed == 0:
			break
	return fixed


# --- straight borders (detection only) --------------------------------------------


## Edge runs along one row/column, merged into collinear chains (gap <= STRAIGHT_GAP_MERGE).
## Each element: {start, end, biome, side}. side 0 = first perpendicular line, 1 = second.
static func _edge_chains_1d(line: PackedInt32Array, side_a: PackedInt32Array, side_b: PackedInt32Array) -> Array:
	var n := line.size()
	var runs: Array = []
	var i := 0
	while i < n:
		var b := line[i]
		if b < 0 or b == BEACH:
			i += 1
			continue
		var j := i
		while j < n and line[j] == b:
			j += 1
		var length := j - i
		if length >= 2:
			var sides := [side_a, side_b]
			for side_idx in range(2):
				var side: PackedInt32Array = sides[side_idx]
				var diff := 0
				for k in range(i, j):
					if side[k] >= 0 and side[k] != b:
						diff += 1
				if diff >= length - 1:
					runs.append({"start": i, "end": j - 1, "biome": b, "side": side_idx})
					break
		i = j

	var chains: Array = []
	for run in runs:
		if not chains.is_empty():
			var last: Dictionary = chains[chains.size() - 1]
			if (
				last["biome"] == run["biome"]
				and last["side"] == run["side"]
				and int(run["start"]) - int(last["end"]) - 1 <= STRAIGHT_GAP_MERGE
			):
				last["end"] = maxi(int(last["end"]), int(run["end"]))
				continue
		chains.append(run.duplicate())
	return chains


static func _land_line_row(mask: Image, water: Image, y: int) -> PackedInt32Array:
	var w := mask.get_width()
	var out := PackedInt32Array()
	out.resize(w)
	for x in range(w):
		out[x] = _land_biome_at(mask, water, x, y)
	return out


static func _land_line_col(mask: Image, water: Image, x: int) -> PackedInt32Array:
	var h := mask.get_height()
	var out := PackedInt32Array()
	out.resize(h)
	for y in range(h):
		out[y] = _land_biome_at(mask, water, x, y)
	return out


static func _off_line(n: int) -> PackedInt32Array:
	var out := PackedInt32Array()
	out.resize(n)
	out.fill(-1)
	return out


## Segments with length >= min_len: {axis, biome, neighbor, length, row, col, start, end}.
static func find_straight_borders(mask: Image, water: Image, min_len: int = MIN_STRAIGHT_REPORT_LEN) -> Array:
	var w := mask.get_width()
	var h := mask.get_height()
	var segments: Array = []

	var prev := _off_line(w)
	var cur := _land_line_row(mask, water, 0)
	for y in range(h):
		var next := _land_line_row(mask, water, y + 1) if y + 1 < h else _off_line(w)
		for chain in _edge_chains_1d(cur, prev, next):
			var length: int = int(chain["end"]) - int(chain["start"]) + 1
			if length < min_len:
				continue
			var mid: int = (int(chain["start"]) + int(chain["end"])) / 2
			var nb_line: PackedInt32Array = prev if int(chain["side"]) == 0 else next
			var nb: int = nb_line[mid] if nb_line[mid] >= 0 else SAVANNA
			segments.append({
				"axis": "h", "biome": chain["biome"], "neighbor": nb, "length": length,
				"row": y, "col": mid, "start": chain["start"], "end": chain["end"],
			})
		prev = cur
		cur = next

	prev = _off_line(h)
	cur = _land_line_col(mask, water, 0)
	for x in range(w):
		var next := _land_line_col(mask, water, x + 1) if x + 1 < w else _off_line(h)
		for chain in _edge_chains_1d(cur, prev, next):
			var length: int = int(chain["end"]) - int(chain["start"]) + 1
			if length < min_len:
				continue
			var mid: int = (int(chain["start"]) + int(chain["end"])) / 2
			var nb_line: PackedInt32Array = prev if int(chain["side"]) == 0 else next
			var nb: int = nb_line[mid] if nb_line[mid] >= 0 else SAVANNA
			segments.append({
				"axis": "v", "biome": chain["biome"], "neighbor": nb, "length": length,
				"row": mid, "col": x, "start": chain["start"], "end": chain["end"],
			})
		prev = cur
		cur = next

	return segments


static func count_straight_borders(mask: Image, water: Image) -> int:
	var n := 0
	for seg in find_straight_borders(mask, water, MIN_STRAIGHT_BORDER_LEN):
		if int(seg["length"]) >= MIN_STRAIGHT_BORDER_LEN:
			n += 1
	return n


# --- fix (biome mask only; rivers untouched) --------------------------------------


static func _retract_desert_from_rivers(mask: Image, water: Image) -> int:
	var changed := 0
	for y in range(mask.get_height()):
		for x in range(mask.get_width()):
			if biome_id_from_pixel(mask.get_pixel(x, y)) != DESERT:
				continue
			if count_cardinal_river(water, x, y) > 0:
				mask.set_pixel(x, y, pixel_from_biome_id(SAVANNA))
				changed += 1
	return changed


static func _remove_disconnected_ocean(mask: Image) -> int:
	var w := mask.get_width()
	var h := mask.get_height()
	var connected := {}
	var queue: Array[Vector2i] = []

	for x in range(w):
		for y in [0, h - 1]:
			if biome_id_from_pixel(mask.get_pixel(x, y)) != OCEAN:
				continue
			var key := Vector2i(x, y)
			if connected.has(key):
				continue
			connected[key] = true
			queue.append(key)
	for y in range(h):
		for x in [0, w - 1]:
			if biome_id_from_pixel(mask.get_pixel(x, y)) != OCEAN:
				continue
			var key := Vector2i(x, y)
			if connected.has(key):
				continue
			connected[key] = true
			queue.append(key)

	var head := 0
	while head < queue.size():
		var cell: Vector2i = queue[head]
		head += 1
		for d in CARDINAL:
			var nx: int = cell.x + d.x
			var ny: int = cell.y + d.y
			if nx < 0 or ny < 0 or nx >= w or ny >= h:
				continue
			if biome_id_from_pixel(mask.get_pixel(nx, ny)) != OCEAN:
				continue
			var nkey := Vector2i(nx, ny)
			if connected.has(nkey):
				continue
			connected[nkey] = true
			queue.append(nkey)

	var changed := 0
	for y in range(h):
		for x in range(w):
			if biome_id_from_pixel(mask.get_pixel(x, y)) != OCEAN:
				continue
			if connected.has(Vector2i(x, y)):
				continue
			mask.set_pixel(x, y, pixel_from_biome_id(SAVANNA))
			changed += 1
	return changed


## Fix illegal tiles in `mask`. `water` is read-only (rivers are the painted truth).
static func fix(mask: Image, water: Image, max_passes: int = 16) -> Dictionary:
	var fixed := {
		"grass_in_water": 0,
		"ocean_in_grass": 0,
		"disconnected_ocean": 0,
		"desert_retracted": 0,
		"biome_specks_fixed": 0,
		"passes": 0,
	}
	if mask == null or mask.is_empty():
		return fixed
	if water == null:
		water = Image.create(mask.get_width(), mask.get_height(), false, Image.FORMAT_L8)
		water.fill(Color.BLACK)

	var w := mask.get_width()
	var h := mask.get_height()

	for pass_idx in range(max_passes):
		var step := 0
		var n := _retract_desert_from_rivers(mask, water)
		fixed["desert_retracted"] += n
		step += n

		n = _clean_all_land_biome_specks(mask, water)
		fixed["biome_specks_fixed"] += n
		step += n

		for y in range(h):
			for x in range(w):
				if is_land_cell(mask, water, x, y) and count_cardinal_ocean(mask, x, y) >= MIN_OPPOSING_SIDES:
					mask.set_pixel(x, y, pixel_from_biome_id(OCEAN))
					fixed["grass_in_water"] += 1
					step += 1

		for y in range(h):
			for x in range(w):
				if is_ocean_cell(mask, water, x, y) and count_cardinal_land(mask, water, x, y) >= MIN_OPPOSING_SIDES:
					mask.set_pixel(x, y, pixel_from_biome_id(SAVANNA))
					fixed["ocean_in_grass"] += 1
					step += 1

		n = _remove_disconnected_ocean(mask)
		fixed["disconnected_ocean"] += n
		step += n

		fixed["passes"] = pass_idx + 1
		if step == 0:
			break

	return fixed
