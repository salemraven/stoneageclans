extends RefCounted
class_name LocusCatalog

## Discrete loci. Hair = Mendelian. Skin / body height / body width = additive.

const KIND_DISCRETE := "discrete"
const INHERIT_MENDELIAN := "mendelian"
const INHERIT_ADDITIVE := "additive"
## Slot 0 is the picture on the face. Slot 1 is hidden.
const INHERIT_PAIR := "pair"

const HAIR_DARK := "hair_dark"
const HAIR_RED := "hair_red"
const SKIN_A := "skin_a"
const SKIN_B := "skin_b"
const SKIN_C := "skin_c"
const SKIN_D := "skin_d"
const HEIGHT_A := "height_a"
const HEIGHT_B := "height_b"
const HEIGHT_C := "height_c"
const HEIGHT_D := "height_d"
const WIDTH_A := "width_a"
const WIDTH_B := "width_b"
const WIDTH_C := "width_c"
const WIDTH_D := "width_d"
const NOSE := "nose"
const NOSE_STRENGTH := "nose_strength"
const BROW := "brow"
const BROW_STRENGTH := "brow_strength"
const EYE_SIZE_A := "eye_size_a"
const EYE_SIZE_B := "eye_size_b"
const EYE_SIZE_C := "eye_size_c"
const EYE_SIZE_D := "eye_size_d"
const EYE_SHAPE_A := "eye_shape_a"
const EYE_SHAPE_B := "eye_shape_b"
const EYE_DARK := "eye_dark"
const EYE_HUE := "eye_hue"
const NOSE_ART_COUNT := 14
const BROW_ART_COUNT := 12
## Planned (not in locus_ids yet): dimorph_on D/d, dimorph_sex M/F; head_height_* / head_width_*.

const MUTATION_PER_ALLELE := 0.001
## Nose and brow pictures only. About one new face in a family of 12 children.
const FACE_MUTATION_PER_ALLELE := 0.02


static func locus_ids() -> Array[String]:
	return [
		HAIR_DARK, HAIR_RED,
		SKIN_A, SKIN_B, SKIN_C, SKIN_D,
		HEIGHT_A, HEIGHT_B, HEIGHT_C, HEIGHT_D,
		WIDTH_A, WIDTH_B, WIDTH_C, WIDTH_D,
		NOSE, NOSE_STRENGTH, BROW, BROW_STRENGTH,
		EYE_SIZE_A, EYE_SIZE_B, EYE_SIZE_C, EYE_SIZE_D,
		EYE_SHAPE_A, EYE_SHAPE_B,
		EYE_DARK, EYE_HUE,
	]


static func skin_locus_ids() -> Array[String]:
	return [SKIN_A, SKIN_B, SKIN_C, SKIN_D]


static func height_locus_ids() -> Array[String]:
	return [HEIGHT_A, HEIGHT_B, HEIGHT_C, HEIGHT_D]


static func width_locus_ids() -> Array[String]:
	return [WIDTH_A, WIDTH_B, WIDTH_C, WIDTH_D]


static func eye_size_locus_ids() -> Array[String]:
	return [EYE_SIZE_A, EYE_SIZE_B, EYE_SIZE_C, EYE_SIZE_D]


static func eye_shape_locus_ids() -> Array[String]:
	return [EYE_SHAPE_A, EYE_SHAPE_B]


static func _art_alleles(count: int) -> Array[String]:
	var alleles: Array[String] = []
	for i in count:
		alleles.append(str(i + 1))
	return alleles


static func _additive_locus(locus_id: String, tall_or_wide: String, short_or_narrow: String) -> Dictionary:
	return {
		"id": locus_id,
		"kind": KIND_DISCRETE,
		"inherit": INHERIT_ADDITIVE,
		"alleles": [tall_or_wide, short_or_narrow],
		"dominant": [tall_or_wide, short_or_narrow],
	}


static func _skin_locus(locus_id: String) -> Dictionary:
	return {
		"id": locus_id,
		"kind": KIND_DISCRETE,
		"inherit": INHERIT_ADDITIVE,
		"alleles": ["D", "d"],
		"dominant": ["D", "d"],
	}


static func get_locus(locus_id: String) -> Dictionary:
	match locus_id:
		HAIR_DARK:
			return {
				"id": HAIR_DARK,
				"kind": KIND_DISCRETE,
				"inherit": INHERIT_MENDELIAN,
				"alleles": ["B", "b"],
				"dominant": ["B", "b"],
			}
		HAIR_RED:
			return {
				"id": HAIR_RED,
				"kind": KIND_DISCRETE,
				"inherit": INHERIT_MENDELIAN,
				"alleles": ["R", "r"],
				"dominant": ["R", "r"],
			}
		SKIN_A, SKIN_B, SKIN_C, SKIN_D:
			return _skin_locus(locus_id)
		HEIGHT_A, HEIGHT_B, HEIGHT_C, HEIGHT_D:
			return _additive_locus(locus_id, "H", "h")
		WIDTH_A, WIDTH_B, WIDTH_C, WIDTH_D:
			return _additive_locus(locus_id, "W", "w")
		NOSE:
			return _pair_locus(NOSE, NOSE_ART_COUNT)
		BROW:
			return _pair_locus(BROW, BROW_ART_COUNT)
		NOSE_STRENGTH, BROW_STRENGTH:
			return _strength_locus(locus_id)
		EYE_SIZE_A, EYE_SIZE_B, EYE_SIZE_C, EYE_SIZE_D:
			return _additive_locus(locus_id, "E", "e")
		EYE_SHAPE_A, EYE_SHAPE_B:
			return _additive_locus(locus_id, "W", "w")
		EYE_DARK:
			return _additive_locus(locus_id, "D", "d")
		EYE_HUE:
			return {
				"id": EYE_HUE,
				"kind": KIND_DISCRETE,
				"inherit": INHERIT_MENDELIAN,
				"alleles": ["H", "h"],
				"dominant": ["H", "h"],
			}
		_:
			return {}


static func _pair_locus(locus_id: String, art_count: int) -> Dictionary:
	var alleles: Array[String] = _art_alleles(art_count)
	return {
		"id": locus_id,
		"kind": KIND_DISCRETE,
		"inherit": INHERIT_PAIR,
		"alleles": alleles,
		"dominant": alleles,
	}


static func _strength_locus(locus_id: String) -> Dictionary:
	var alleles: Array[String] = ["1", "2", "3", "4", "5"]
	return {
		"id": locus_id,
		"kind": KIND_DISCRETE,
		"inherit": INHERIT_ADDITIVE,
		"alleles": alleles,
		"dominant": alleles,
	}


static func inherit_mode(locus_id: String) -> String:
	var loc: Dictionary = get_locus(locus_id)
	return str(loc.get("inherit", INHERIT_MENDELIAN))


static func is_legal_allele(locus_id: String, allele: String) -> bool:
	var loc: Dictionary = get_locus(locus_id)
	if loc.is_empty():
		return false
	var alleles: Array = loc.get("alleles", [])
	return allele in alleles


static func _fallback_allele(loc: Dictionary) -> String:
	var alleles: Array = loc.get("alleles", [])
	if alleles.is_empty():
		return ""
	return str(alleles[alleles.size() - 1])


static func normalize_pair(locus_id: String, pair: Array) -> Array[String]:
	var loc: Dictionary = get_locus(locus_id)
	var a := ""
	var b := ""
	if pair.size() >= 1:
		a = str(pair[0])
	if pair.size() >= 2:
		b = str(pair[1])
	if not is_legal_allele(locus_id, a):
		a = _fallback_allele(loc)
	if not is_legal_allele(locus_id, b):
		b = _fallback_allele(loc)
	if inherit_mode(locus_id) == INHERIT_MENDELIAN:
		var dominant: Array = loc.get("dominant", [])
		if dominant.size() > 0 and b == str(dominant[0]) and a != b:
			var tmp := a
			a = b
			b = tmp
	return [a, b]


static func expressed_allele(locus_id: String, pair: Array) -> String:
	var loc: Dictionary = get_locus(locus_id)
	var dominant: Array = loc.get("dominant", [])
	var norm: Array[String] = normalize_pair(locus_id, pair)
	for allele in dominant:
		if str(allele) == norm[0] or str(allele) == norm[1]:
			return str(allele)
	if norm.size() > 0:
		return norm[0]
	return ""
