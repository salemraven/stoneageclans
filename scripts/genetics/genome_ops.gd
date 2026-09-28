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
		var loc: Dictionary = Catalog.get_locus(locus_id)
		var alleles: Array = loc.get("alleles", [])
		if alleles.is_empty() or rng == null:
			continue
		var a: String = str(alleles[rng.randi_range(0, alleles.size() - 1)])
		var b: String = str(alleles[rng.randi_range(0, alleles.size() - 1)])
		set_pair(out, locus_id, [a, b])
	return out


static func random_founder_genome(rng: RandomNumberGenerator) -> Dictionary:
	var genome: Dictionary = {}
	for locus_id in Catalog.locus_ids():
		var loc: Dictionary = Catalog.get_locus(locus_id)
		var alleles: Array = loc.get("alleles", [])
		if alleles.is_empty() or rng == null:
			continue
		var a: String = str(alleles[rng.randi_range(0, alleles.size() - 1)])
		var b: String = str(alleles[rng.randi_range(0, alleles.size() - 1)])
		set_pair(genome, locus_id, [a, b])
	return genome


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


static func recombine(
	mother: Dictionary,
	father: Dictionary,
	rng: RandomNumberGenerator,
	allow_mutation: bool = true
) -> Dictionary:
	var child: Dictionary = {}
	for locus_id in Catalog.locus_ids():
		var mom: Array[String] = get_pair(mother, locus_id)
		var dad: Array[String] = get_pair(father, locus_id)
		var a: String = _pick_one(mom, rng)
		var b: String = _pick_one(dad, rng)
		if allow_mutation:
			a = _maybe_mutate(locus_id, a, rng)
			b = _maybe_mutate(locus_id, b, rng)
		set_pair(child, locus_id, [a, b])
	return child
