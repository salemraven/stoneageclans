extends RefCounted
class_name LocusCatalog

## Discrete loci. Hair = Mendelian. Skin / body height / body width = additive.

const KIND_DISCRETE := "discrete"
const INHERIT_MENDELIAN := "mendelian"
const INHERIT_ADDITIVE := "additive"

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
## Planned (not in locus_ids yet): dimorph_on D/d, dimorph_sex M/F; head_height_* / head_width_*.
## Planned: "eye_pigment" with alleles P/p — not expressed until eye layers exist.

const MUTATION_PER_ALLELE := 0.001


static func locus_ids() -> Array[String]:
	return [
		HAIR_DARK, HAIR_RED,
		SKIN_A, SKIN_B, SKIN_C, SKIN_D,
		HEIGHT_A, HEIGHT_B, HEIGHT_C, HEIGHT_D,
		WIDTH_A, WIDTH_B, WIDTH_C, WIDTH_D,
	]


static func skin_locus_ids() -> Array[String]:
	return [SKIN_A, SKIN_B, SKIN_C, SKIN_D]


static func height_locus_ids() -> Array[String]:
	return [HEIGHT_A, HEIGHT_B, HEIGHT_C, HEIGHT_D]


static func width_locus_ids() -> Array[String]:
	return [WIDTH_A, WIDTH_B, WIDTH_C, WIDTH_D]


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
		_:
			return {}


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
