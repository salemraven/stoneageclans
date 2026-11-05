extends RefCounted
class_name GenomeOps

const Catalog := preload("res://scripts/genetics/locus_catalog.gd")


static func empty_genome() -> Dictionary:
	return {}


static func get_pair(genome: Dictionary, locus_id: String) -> Array[String]:
	var raw: Variant = genome.get(locus_id, [])
	var pair: Array = raw if raw is Array else []
	return Catalog.normalize_pair(locus_id, pair)


static func set_pair(genome: Dictionary, locus_id: String, pair: Array) -> void:
	var norm: Array[String] = Catalog.normalize_pair(locus_id, pair)
	genome[locus_id] = [norm[0], norm[1]]


static func has_locus(genome: Dictionary, locus_id: String) -> bool:
	if genome.is_empty() or not genome.has(locus_id):
		return false
	var pair: Array[String] = get_pair(genome, locus_id)
	if pair.size() < 2:
		return false
	return Catalog.is_legal_allele(locus_id, pair[0]) and Catalog.is_legal_allele(locus_id, pair[1])


static func has_complete_genome(genome: Dictionary) -> bool:
	if genome.is_empty():
		return false
	for locus_id in Catalog.locus_ids():
		if not has_locus(genome, locus_id):
			return false
	return true


## Keep existing pairs; roll only missing catalog rows (hair-only saves keep hair).
static func fill_missing_loci(genome: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	var out: Dictionary = genome.duplicate(true)
	for locus_id in Catalog.locus_ids():
		if has_locus(out, locus_id):
			continue
		var rolled: Array = _roll_founder_pair(locus_id, rng)
		if rolled.size() < 2:
			continue
		set_pair(out, locus_id, rolled)
	return out


static func random_founder_genome(rng: RandomNumberGenerator) -> Dictionary:
	var genome: Dictionary = {}
	for locus_id in Catalog.locus_ids():
		var rolled: Array = _roll_founder_pair(locus_id, rng)
		if rolled.size() < 2:
			continue
		set_pair(genome, locus_id, rolled)
	return genome


## Spawned people wear one nose and one brow. Both stored copies match. Strength peaks at 3.
static func _roll_founder_pair(locus_id: String, rng: RandomNumberGenerator) -> Array:
	var loc: Dictionary = Catalog.get_locus(locus_id)
	var alleles: Array = loc.get("alleles", [])
	if alleles.is_empty() or rng == null:
		return []
	if locus_id == Catalog.NOSE or locus_id == Catalog.BROW:
		var art := str(alleles[rng.randi_range(0, alleles.size() - 1)])
		return [art, art]
	if locus_id == Catalog.NOSE_STRENGTH or locus_id == Catalog.BROW_STRENGTH:
		return [_roll_strength_allele(rng), _roll_strength_allele(rng)]
	var a := str(alleles[rng.randi_range(0, alleles.size() - 1)])
	var b := str(alleles[rng.randi_range(0, alleles.size() - 1)])
	return [a, b]


## 1, 2, 4, 3's, 2, 1 out of 10. Mode is 3.
static func _roll_strength_allele(rng: RandomNumberGenerator) -> String:
	var bag: Array[String] = ["1", "2", "2", "3", "3", "3", "3", "4", "4", "5"]
	return bag[rng.randi_range(0, bag.size() - 1)]


static func _pick_one(pair: Array[String], rng: RandomNumberGenerator) -> String:
	if pair.is_empty():
		return ""
	if rng == null or pair.size() == 1:
		return pair[0]
	return pair[rng.randi_range(0, pair.size() - 1)]


static func _maybe_mutate(locus_id: String, allele: String, rng: RandomNumberGenerator) -> String:
	if rng == null:
		return allele
	if rng.randf() >= Catalog.MUTATION_PER_ALLELE:
		return allele
	var loc: Dictionary = Catalog.get_locus(locus_id)
	var alleles: Array = loc.get("alleles", [])
	if alleles.size() < 2:
		return allele
	var pick: String = str(alleles[rng.randi_range(0, alleles.size() - 1)])
	if pick == allele:
		pick = str(alleles[(alleles.find(allele) + 1) % alleles.size()])
	return pick


static func expressed_face_strength(genome: Dictionary, strength_locus: String) -> float:
	if not has_locus(genome, strength_locus):
		return 3.0
	var pair: Array[String] = get_pair(genome, strength_locus)
	return (float(pair[0]) + float(pair[1])) / 2.0


static func recombine(
	mother: Dictionary,
	father: Dictionary,
	rng: RandomNumberGenerator,
	allow_mutation: bool = true
) -> Dictionary:
	var child: Dictionary = {}
	for locus_id in Catalog.locus_ids():
		if locus_id == Catalog.NOSE or locus_id == Catalog.BROW:
			continue
		var mom: Array[String] = get_pair(mother, locus_id)
		var dad: Array[String] = get_pair(father, locus_id)
		var a: String = _pick_one(mom, rng)
		var b: String = _pick_one(dad, rng)
		if allow_mutation:
			a = _maybe_mutate(locus_id, a, rng)
			b = _maybe_mutate(locus_id, b, rng)
		set_pair(child, locus_id, [a, b])
	_recombine_face(child, mother, father, rng, allow_mutation, Catalog.NOSE, Catalog.NOSE_STRENGTH)
	_recombine_face(child, mother, father, rng, allow_mutation, Catalog.BROW, Catalog.BROW_STRENGTH)
	return child


static func _recombine_face(
	child: Dictionary,
	mother: Dictionary,
	father: Dictionary,
	rng: RandomNumberGenerator,
	allow_mutation: bool,
	art_locus: String,
	strength_locus: String
) -> void:
	var sm := expressed_face_strength(mother, strength_locus)
	var sd := expressed_face_strength(father, strength_locus)
	var from_mom := _mutate_face(art_locus, _transmit_face_copy(get_pair(mother, art_locus), sm, rng), rng, allow_mutation)
	var from_dad := _mutate_face(art_locus, _transmit_face_copy(get_pair(father, art_locus), sd, rng), rng, allow_mutation)
	var wear_mom := true
	if rng != null:
		var denom := sm + sd
		wear_mom = rng.randf() < (sm / denom if denom > 0.0 else 0.5)
	elif sd > sm:
		wear_mom = false
	if wear_mom:
		set_pair(child, art_locus, [from_mom, from_dad])
	else:
		set_pair(child, art_locus, [from_dad, from_mom])


static func _transmit_face_copy(pair: Array[String], strength: float, rng: RandomNumberGenerator) -> String:
	if pair.is_empty():
		return ""
	if pair.size() < 2 or pair[0] == pair[1] or rng == null:
		return pair[0]
	var pass_worn := 0.50 + 0.35 * (strength - 1.0) / 4.0
	if rng.randf() < pass_worn:
		return pair[0]
	return pair[1]


static func _mutate_face(locus_id: String, allele: String, rng: RandomNumberGenerator, allow_mutation: bool) -> String:
	if not allow_mutation or rng == null:
		return allele
	if rng.randf() >= Catalog.FACE_MUTATION_PER_ALLELE:
		return allele
	var loc: Dictionary = Catalog.get_locus(locus_id)
	var alleles: Array = loc.get("alleles", [])
	if alleles.size() < 2:
		return allele
	var pick := str(alleles[rng.randi_range(0, alleles.size() - 1)])
	if pick == allele:
		pick = str(alleles[(alleles.find(allele) + 1) % alleles.size()])
	return pick
