extends RefCounted
class_name GeneticsPhenotype

## Maps genome → visual ids. Hair Mendelian; skin / body height / body width additive.
## Head size genes (tall vs wide skull) are not in the catalog yet — head_scale stays (1,1).

const Catalog := preload("res://scripts/genetics/locus_catalog.gd")
const GenomeOps := preload("res://scripts/genetics/genome_ops.gd")

const SKIN_LIGHT := Color(0.98, 0.84, 0.72, 1.0)
const SKIN_MID := Color(0.72, 0.52, 0.38, 1.0)
const SKIN_DARK := Color(0.32, 0.22, 0.16, 1.0)
## Height: 0.88–1.12 still shy side-by-side. 0.80–1.20 is ~40% (~22px on a 56px card).
const HEIGHT_SCALE_MIN := 0.80
const HEIGHT_SCALE_MAX := 1.20
## Width: same 80–120% as height for the first side-by-side look.
const WIDTH_SCALE_MIN := 0.80
const WIDTH_SCALE_MAX := 1.20
## Future dimorph: overall larger sex gets +k on both X and Y. Off until loci ship.
const DIMORPH_ENABLED := false
const DIMORPH_K := 0.02
const DIMORPH_ON := "dimorph_on"
const DIMORPH_SEX := "dimorph_sex"


static func hair_tone_from_genome(genome: Dictionary) -> String:
	if not GenomeOps.has_locus(genome, Catalog.HAIR_DARK) or not GenomeOps.has_locus(genome, Catalog.HAIR_RED):
		return "Brown"
	var dark_pair: Array[String] = GenomeOps.get_pair(genome, Catalog.HAIR_DARK)
	var red_pair: Array[String] = GenomeOps.get_pair(genome, Catalog.HAIR_RED)
	var dark_ex: String = Catalog.expressed_allele(Catalog.HAIR_DARK, dark_pair)
	var red_ex: String = Catalog.expressed_allele(Catalog.HAIR_RED, red_pair)
	var has_red: bool = red_ex == "R"
	var dark_count := 0
	if dark_pair.size() >= 1 and dark_pair[0] == "B":
		dark_count += 1
	if dark_pair.size() >= 2 and dark_pair[1] == "B":
		dark_count += 1
	if has_red:
		if dark_ex == "B":
			return "Auburn"
		return "DirtyBlonde"
	if dark_count >= 2:
		return "Black"
	if dark_count == 1:
		return "Brown"
	return "LightBrown"


static func skin_dark_count(genome: Dictionary) -> int:
	var n := 0
	for locus_id in Catalog.skin_locus_ids():
		var pair: Array[String] = GenomeOps.get_pair(genome, locus_id)
		if pair.size() >= 1 and pair[0] == "D":
			n += 1
		if pair.size() >= 2 and pair[1] == "D":
			n += 1
	return n


static func skin_slot_count() -> int:
	return Catalog.skin_locus_ids().size() * 2


static func skin_melanin(genome: Dictionary) -> float:
	var slots: int = skin_slot_count()
	if slots < 1:
		return 0.5
	return float(skin_dark_count(genome)) / float(slots)


static func skin_tone_label(genome: Dictionary) -> String:
	var n: int = skin_dark_count(genome)
	if n <= 2:
		return "Light"
	if n <= 5:
		return "Medium"
	return "Dark"


static func _count_letter(locus_ids: Array[String], genome: Dictionary, letter: String) -> int:
	var n := 0
	for locus_id in locus_ids:
		var pair: Array[String] = GenomeOps.get_pair(genome, locus_id)
		if pair.size() >= 1 and pair[0] == letter:
			n += 1
		if pair.size() >= 2 and pair[1] == letter:
			n += 1
	return n


static func height_tall_count(genome: Dictionary) -> int:
	return _count_letter(Catalog.height_locus_ids(), genome, "H")


static func width_wide_count(genome: Dictionary) -> int:
	return _count_letter(Catalog.width_locus_ids(), genome, "W")


static func _slot_count(locus_ids: Array[String]) -> int:
	return locus_ids.size() * 2


static func _unit_score(count: int, slots: int) -> float:
	if slots < 1:
		return 0.5
	return clampf(float(count) / float(slots), 0.0, 1.0)


static func _lerp_scale(count: int, slots: int, lo: float, hi: float) -> float:
	return lerpf(lo, hi, _unit_score(count, slots))


## Sex for dimorph: woman → female; player/caveman/clansman → male; baby skips dimorph.
static func sex_from_npc_type(npc_type: String) -> String:
	var t: String = npc_type.strip_edges().to_lower()
	if t == "woman":
		return "female"
	if t == "baby":
		return "baby"
	return "male"


## Future: D/d on, M/F which sex is larger. Returns 0 while DIMORPH_ENABLED is false.
static func dimorph_offset(genome: Dictionary, sex: String) -> float:
	if not DIMORPH_ENABLED:
		return 0.0
	if sex == "baby" or sex.is_empty():
		return 0.0
	if not GenomeOps.has_locus(genome, DIMORPH_ON):
		return 0.0
	var on_ex: String = Catalog.expressed_allele(DIMORPH_ON, GenomeOps.get_pair(genome, DIMORPH_ON))
	if on_ex != "D":
		return 0.0
	var which: String = "M"
	if GenomeOps.has_locus(genome, DIMORPH_SEX):
		which = Catalog.expressed_allele(DIMORPH_SEX, GenomeOps.get_pair(genome, DIMORPH_SEX))
	var larger_is_male: bool = which != "F"
	var is_male: bool = sex == "male"
	if larger_is_male:
		return DIMORPH_K if is_male else -DIMORPH_K
	return DIMORPH_K if not is_male else -DIMORPH_K


static func body_scale_from_genome(genome: Dictionary, sex: String = "male") -> Vector2:
	var hy: float = _lerp_scale(
		height_tall_count(genome), _slot_count(Catalog.height_locus_ids()),
		HEIGHT_SCALE_MIN, HEIGHT_SCALE_MAX
	)
	var wx: float = _lerp_scale(
		width_wide_count(genome), _slot_count(Catalog.width_locus_ids()),
		WIDTH_SCALE_MIN, WIDTH_SCALE_MAX
	)
	var d: float = dimorph_offset(genome, sex)
	return Vector2(wx + d, hy + d)


## Coming: head_height_* and head_width_* additive loci. Always (1,1) until cataloged.
## Hair/hats should sit on HeadPivot (follow head_scale). Body clothes on BodySprite.
static func head_scale_from_genome(_genome: Dictionary) -> Vector2:
	return Vector2.ONE


static func skin_modulate_from_genome(genome: Dictionary) -> Color:
	var m: float = clampf(skin_melanin(genome), 0.0, 1.0)
	if m <= 0.5:
		return SKIN_LIGHT.lerp(SKIN_MID, m * 2.0)
	return SKIN_MID.lerp(SKIN_DARK, (m - 0.5) * 2.0)


static func debug_snapshot(genome: Dictionary) -> Dictionary:
	var skin_pairs: Dictionary = {}
	for locus_id in Catalog.skin_locus_ids():
		var pair: Array[String] = GenomeOps.get_pair(genome, locus_id)
		skin_pairs[locus_id] = [pair[0], pair[1]] if pair.size() >= 2 else []
	var mod: Color = skin_modulate_from_genome(genome)
	return {
		"skin_dark_count": skin_dark_count(genome),
		"skin_slots": skin_slot_count(),
		"skin_melanin": skin_melanin(genome),
		"skin_tone": skin_tone_label(genome),
		"skin_modulate": [mod.r, mod.g, mod.b],
		"skin_pairs": skin_pairs,
		"hair_tone": hair_tone_from_genome(genome),
		"height_tall_count": height_tall_count(genome),
		"width_wide_count": width_wide_count(genome),
		"body_scale": body_scale_from_genome(genome, "male"),
		"head_scale": head_scale_from_genome(genome),
		"dimorph_enabled": DIMORPH_ENABLED,
	}
