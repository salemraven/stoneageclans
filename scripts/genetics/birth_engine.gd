extends RefCounted
class_name BirthEngine

const GenomeOps := preload("res://scripts/genetics/genome_ops.gd")
const Phenotype := preload("res://scripts/genetics/phenotype.gd")


static func genome_from_profile(profile: Variant) -> Dictionary:
	if not (profile is Dictionary):
		return {}
	var raw: Variant = (profile as Dictionary).get("genome", {})
	if raw is Dictionary:
		return (raw as Dictionary).duplicate(true)
	return {}


static func genome_from_entity(entity: Variant) -> Dictionary:
	if entity == null:
		return {}
	if entity is Dictionary:
		return genome_from_profile((entity as Dictionary).get("genetics_profile", {}))
	if entity.get("genetics_profile") != null:
		return genome_from_profile(entity.get("genetics_profile"))
	return {}


static func _rng_for_entity(entity: Variant) -> RandomNumberGenerator:
	var ws: int = 0
	var sim = Engine.get_main_loop()
	if sim:
		var tree := sim.root as Window
		if tree:
			var sr: Node = tree.get_node_or_null("/root/SimRng")
			if sr and sr.has_method("get_world_seed"):
				ws = int(sr.call("get_world_seed"))
	var salt: int = 0
	if entity != null and not (entity is Dictionary):
		salt = int(entity.get_instance_id())
		var er: Node = null
		if sim:
			er = (sim.root as Window).get_node_or_null("/root/EntityRegistry")
		if er and er.has_method("get_id"):
			salt = int(er.call("get_id", entity))
	salt = int(salt) ^ int(hash("birth_engine_founder"))
	return preload("res://scripts/network/sim_rng.gd").make_scoped_rng(ws, salt)


static func apply_genome(entity: Variant, genome: Dictionary) -> String:
	var hair: String = Phenotype.hair_tone_from_genome(genome)
	var skin_label: String = Phenotype.skin_tone_label(genome)
	var skin_col: Color = Phenotype.skin_modulate_from_genome(genome)
	var sex: String = "male"
	if entity is Dictionary:
		sex = Phenotype.sex_from_npc_type(str((entity as Dictionary).get("npc_type", "")))
	elif entity != null:
		sex = Phenotype.sex_from_npc_type(str(entity.get("npc_type")))
	var body_sc: Vector2 = Phenotype.body_scale_from_genome(genome, sex)
	var head_sc: Vector2 = Phenotype.head_scale_from_genome(genome)
	if entity == null:
		return hair
	if entity is Dictionary:
		var d: Dictionary = entity
		var profile: Dictionary = {}
		if d.get("genetics_profile") is Dictionary:
			profile = (d.get("genetics_profile") as Dictionary).duplicate(true)
		profile["genome"] = genome.duplicate(true)
		profile["skin_modulate"] = skin_col
		profile["body_scale"] = body_sc
		profile["head_scale"] = head_sc
		d["genetics_profile"] = profile
		d["hair_tone"] = hair
		d["skin_tone"] = skin_label
		return hair
	var profile_e: Dictionary = {}
	if entity.get("genetics_profile") is Dictionary:
		profile_e = (entity.get("genetics_profile") as Dictionary).duplicate(true)
	profile_e["genome"] = genome.duplicate(true)
	profile_e["skin_modulate"] = skin_col
	profile_e["body_scale"] = body_sc
	profile_e["head_scale"] = head_sc
	entity.set("genetics_profile", profile_e)
	entity.set("hair_tone", hair)
	entity.set("skin_tone", skin_label)
	if entity.has_method("set_meta"):
		entity.set_meta("hair_tone", hair)
		entity.set_meta("skin_tone", skin_label)
	return hair


static func ensure_genome(entity: Variant, rng: RandomNumberGenerator = null) -> Dictionary:
	var existing: Dictionary = genome_from_entity(entity)
	if GenomeOps.has_complete_genome(existing):
		return existing
	var use_rng: RandomNumberGenerator = rng
	if use_rng == null:
		use_rng = _rng_for_entity(entity)
	var genome: Dictionary
	if existing.is_empty():
		genome = GenomeOps.random_founder_genome(use_rng)
	else:
		genome = GenomeOps.fill_missing_loci(existing, use_rng)
	apply_genome(entity, genome)
	_trace_skin("founder" if existing.is_empty() else "ensure_fill", entity, genome)
	return genome


static func spawn_child_genome(mother: Variant, father: Variant, rng: RandomNumberGenerator) -> Dictionary:
	var mom_g: Dictionary = genome_from_entity(mother)
	if not GenomeOps.has_complete_genome(mom_g):
		mom_g = ensure_genome(mother, rng)
	var dad_g: Dictionary = genome_from_entity(father)
	if not GenomeOps.has_complete_genome(dad_g):
		dad_g = ensure_genome(father, rng)
	return GenomeOps.recombine(mom_g, dad_g, rng)


static func apply_child_to_entity(child: Variant, mother: Variant, father: Variant, rng: RandomNumberGenerator) -> Dictionary:
	var genome: Dictionary = spawn_child_genome(mother, father, rng)
	apply_genome(child, genome)
	_trace_skin("birth", child, genome, {
		"mother_count": Phenotype.skin_dark_count(genome_from_entity(mother)),
		"father_count": Phenotype.skin_dark_count(genome_from_entity(father)),
	})
	return genome


static func _entity_name(entity: Variant) -> String:
	if entity == null:
		return ""
	if entity is Dictionary:
		return str((entity as Dictionary).get("npc_name", (entity as Dictionary).get("name", "")))
	if entity.get("npc_name") != null:
		return str(entity.get("npc_name"))
	if entity.get("player_name") != null:
		return str(entity.get("player_name"))
	return str(entity.get("name")) if entity.get("name") != null else ""


static func _trace_skin(kind: String, entity: Variant, genome: Dictionary, extra: Dictionary = {}) -> void:
	var row: Dictionary = Phenotype.debug_snapshot(genome)
	row["kind"] = kind
	row["name"] = _entity_name(entity)
	for k in extra:
		row[k] = extra[k]
	var tree_ok := Engine.get_main_loop() != null
	var dc: Node = null
	var pi: Node = null
	if tree_ok:
		var root: Window = Engine.get_main_loop().root as Window
		if root:
			dc = root.get_node_or_null("/root/DebugConfig")
			pi = root.get_node_or_null("/root/PlaytestInstrumentor")
	if pi and pi.has_method("is_enabled") and pi.is_enabled() and pi.has_method("log_event"):
		if kind == "birth" or (dc != null and bool(dc.get("enable_skin_gene_log"))):
			pi.call("log_event", "skin_gene", row)
	if dc != null and bool(dc.get("enable_skin_gene_log")):
		print("SKIN_GENE %s" % JSON.stringify(row))
