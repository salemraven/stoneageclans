extends SceneTree
## Headless Punnett / seed checks for Mendelian hair loci.
## SKIP_SINGLE_INSTANCE=1 godot --headless --path . --script res://tools/test_birth_alleles.gd

const GenomeOps := preload("res://scripts/genetics/genome_ops.gd")
const Phenotype := preload("res://scripts/genetics/phenotype.gd")
const Catalog := preload("res://scripts/genetics/locus_catalog.gd")
const BirthEngine := preload("res://scripts/genetics/birth_engine.gd")


func _init() -> void:
	call_deferred("_run")


func _fail(msg: String) -> void:
	push_error("TEST_BIRTH_ALLELES_FAIL: %s" % msg)
	quit(1)


func _rng(seed_val: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_val
	return rng


func _run() -> void:
	var founder: Dictionary = GenomeOps.random_founder_genome(_rng(7))
	if not GenomeOps.has_complete_genome(founder):
		_fail("founder missing loci")
	for locus_id in Catalog.locus_ids():
		if not founder.has(locus_id):
			_fail("founder missing %s" % locus_id)

	var mom_bb: Dictionary = {}
	GenomeOps.set_pair(mom_bb, Catalog.HAIR_DARK, ["B", "B"])
	GenomeOps.set_pair(mom_bb, Catalog.HAIR_RED, ["r", "r"])
	var dad_bb: Dictionary = {}
	GenomeOps.set_pair(dad_bb, Catalog.HAIR_DARK, ["b", "b"])
	GenomeOps.set_pair(dad_bb, Catalog.HAIR_RED, ["r", "r"])
	for i in range(20):
		var child: Dictionary = GenomeOps.recombine(mom_bb, dad_bb, _rng(100 + i), false)
		var dark: Array[String] = GenomeOps.get_pair(child, Catalog.HAIR_DARK)
		if dark[0] != "B" or dark[1] != "b":
			_fail("BB x bb should be Bb, got %s/%s" % [dark[0], dark[1]])
		if Phenotype.hair_tone_from_genome(child) != "Brown":
			_fail("Bb + rr should express Brown, got %s" % Phenotype.hair_tone_from_genome(child))

	var light: Dictionary = {}
	GenomeOps.set_pair(light, Catalog.HAIR_DARK, ["b", "b"])
	GenomeOps.set_pair(light, Catalog.HAIR_RED, ["r", "r"])
	for i in range(12):
		var kid: Dictionary = GenomeOps.recombine(light, light, _rng(200 + i), false)
		if Phenotype.hair_tone_from_genome(kid) != "LightBrown":
			_fail("bb x bb should be LightBrown, got %s" % Phenotype.hair_tone_from_genome(kid))
		var red: Array[String] = GenomeOps.get_pair(kid, Catalog.HAIR_RED)
		if red[0] == "R" or red[1] == "R":
			_fail("rr x rr produced R")
		if Phenotype.hair_tone_from_genome(kid) == "Auburn":
			_fail("rr x rr should never be Auburn")

	var black: Dictionary = {}
	GenomeOps.set_pair(black, Catalog.HAIR_DARK, ["B", "B"])
	GenomeOps.set_pair(black, Catalog.HAIR_RED, ["r", "r"])
	if Phenotype.hair_tone_from_genome(black) != "Black":
		_fail("BB rr should be Black")

	var auburn: Dictionary = {}
	GenomeOps.set_pair(auburn, Catalog.HAIR_DARK, ["B", "b"])
	GenomeOps.set_pair(auburn, Catalog.HAIR_RED, ["R", "r"])
	if Phenotype.hair_tone_from_genome(auburn) != "Auburn":
		_fail("B_ R_ should be Auburn")

	var seed_a: Dictionary = GenomeOps.recombine(mom_bb, dad_bb, _rng(9991), false)
	var seed_b: Dictionary = GenomeOps.recombine(mom_bb, dad_bb, _rng(9991), false)
	if GenomeOps.get_pair(seed_a, Catalog.HAIR_DARK) != GenomeOps.get_pair(seed_b, Catalog.HAIR_DARK):
		_fail("same seed should match child dark pair")
	if GenomeOps.get_pair(seed_a, Catalog.HAIR_RED) != GenomeOps.get_pair(seed_b, Catalog.HAIR_RED):
		_fail("same seed should match child red pair")

	var mom_ent := {"genetics_profile": {"genome": mom_bb}}
	var dad_ent := {"genetics_profile": {"genome": dad_bb}}
	var baby := {}
	BirthEngine.apply_child_to_entity(baby, mom_ent, dad_ent, _rng(3))
	if str(baby.get("hair_tone", "")) != "Brown":
		_fail("BirthEngine child should be Brown, got %s" % str(baby.get("hair_tone", "")))
	var g: Dictionary = BirthEngine.genome_from_profile(baby.get("genetics_profile", {}))
	if not GenomeOps.has_complete_genome(g):
		_fail("BirthEngine child missing genome")
	if not (baby.get("genetics_profile") is Dictionary and (baby["genetics_profile"] as Dictionary).has("skin_modulate")):
		_fail("BirthEngine child should store skin_modulate")
	if str(baby.get("skin_tone", "")) == "":
		_fail("BirthEngine child should store skin_tone label")

	# --- polygenic skin ---
	var hair_only: Dictionary = mom_bb.duplicate(true)
	if GenomeOps.has_complete_genome(hair_only):
		_fail("hair-only genome should be incomplete after skin loci added")
	var filled: Dictionary = GenomeOps.fill_missing_loci(hair_only, _rng(44))
	if not GenomeOps.has_complete_genome(filled):
		_fail("fill_missing_loci should complete genome")
	if GenomeOps.get_pair(filled, Catalog.HAIR_DARK) != GenomeOps.get_pair(hair_only, Catalog.HAIR_DARK):
		_fail("fill_missing_loci must not rewrite hair_dark")
	if GenomeOps.get_pair(filled, Catalog.HAIR_RED) != GenomeOps.get_pair(hair_only, Catalog.HAIR_RED):
		_fail("fill_missing_loci must not rewrite hair_red")

	var all_d: Dictionary = hair_only.duplicate(true)
	var all_l: Dictionary = hair_only.duplicate(true)
	for sid in Catalog.skin_locus_ids():
		GenomeOps.set_pair(all_d, sid, ["D", "D"])
		GenomeOps.set_pair(all_l, sid, ["d", "d"])
	if Phenotype.skin_dark_count(all_d) != 8:
		_fail("all D should count 8, got %d" % Phenotype.skin_dark_count(all_d))
	if Phenotype.skin_dark_count(all_l) != 0:
		_fail("all d should count 0")
	if Phenotype.skin_tone_label(all_d) != "Dark":
		_fail("score 8 label Dark")
	if Phenotype.skin_tone_label(all_l) != "Light":
		_fail("score 0 label Light")
	var dark_c: Color = Phenotype.skin_modulate_from_genome(all_d)
	var light_c: Color = Phenotype.skin_modulate_from_genome(all_l)
	if dark_c.r >= light_c.r:
		_fail("dark modulate should be darker (lower r) than light")
	for i in range(8):
		var kid_d: Dictionary = GenomeOps.recombine(all_d, all_d, _rng(500 + i), false)
		if Phenotype.skin_dark_count(kid_d) != 8:
			_fail("all-D parents must produce count 8")
		var kid_l: Dictionary = GenomeOps.recombine(all_l, all_l, _rng(600 + i), false)
		if Phenotype.skin_dark_count(kid_l) != 0:
			_fail("all-d parents must produce count 0")

	var mid: Dictionary = hair_only.duplicate(true)
	GenomeOps.set_pair(mid, Catalog.SKIN_A, ["D", "d"])
	GenomeOps.set_pair(mid, Catalog.SKIN_B, ["D", "d"])
	GenomeOps.set_pair(mid, Catalog.SKIN_C, ["D", "d"])
	GenomeOps.set_pair(mid, Catalog.SKIN_D, ["D", "d"])
	if Phenotype.skin_dark_count(mid) != 4:
		_fail("mid parent should count 4")
	var sum_c := 0
	for i in range(24):
		var kid_m: Dictionary = GenomeOps.recombine(mid, mid, _rng(700 + i), false)
		var kc: int = Phenotype.skin_dark_count(kid_m)
		if kc < 0 or kc > 8:
			_fail("child skin count out of range")
		sum_c += kc
	var avg: float = float(sum_c) / 24.0
	if avg < 2.0 or avg > 6.0:
		_fail("mid x mid mean count should sit mid-band, got %.2f" % avg)

	var skin_seed_a: Dictionary = GenomeOps.recombine(mid, mid, _rng(4242), false)
	var skin_seed_b: Dictionary = GenomeOps.recombine(mid, mid, _rng(4242), false)
	for sid in Catalog.skin_locus_ids():
		if GenomeOps.get_pair(skin_seed_a, sid) != GenomeOps.get_pair(skin_seed_b, sid):
			_fail("same seed should match child skin pair %s" % sid)

	var snap: Dictionary = Phenotype.debug_snapshot(all_d)
	if int(snap.get("skin_dark_count", -1)) != 8:
		_fail("debug_snapshot missing count")
	if not snap.has("skin_pairs") or not snap.has("skin_melanin"):
		_fail("debug_snapshot incomplete")

	# --- body height / width ---
	var skin_hair: Dictionary = all_l.duplicate(true)
	var tall: Dictionary = skin_hair.duplicate(true)
	var shortg: Dictionary = skin_hair.duplicate(true)
	var wide: Dictionary = skin_hair.duplicate(true)
	var narrow: Dictionary = skin_hair.duplicate(true)
	for hid in Catalog.height_locus_ids():
		GenomeOps.set_pair(tall, hid, ["H", "H"])
		GenomeOps.set_pair(shortg, hid, ["h", "h"])
		GenomeOps.set_pair(wide, hid, ["h", "h"])
		GenomeOps.set_pair(narrow, hid, ["h", "h"])
	for wid in Catalog.width_locus_ids():
		GenomeOps.set_pair(tall, wid, ["w", "w"])
		GenomeOps.set_pair(shortg, wid, ["w", "w"])
		GenomeOps.set_pair(wide, wid, ["W", "W"])
		GenomeOps.set_pair(narrow, wid, ["w", "w"])
	if Phenotype.height_tall_count(tall) != 8:
		_fail("all H should count 8, got %d" % Phenotype.height_tall_count(tall))
	if Phenotype.height_tall_count(shortg) != 0:
		_fail("all h should count 0")
	if Phenotype.width_wide_count(wide) != 8:
		_fail("all W should count 8")
	if Phenotype.width_wide_count(narrow) != 0:
		_fail("all w should count 0")
	var tall_sc: Vector2 = Phenotype.body_scale_from_genome(tall, "male")
	var short_sc: Vector2 = Phenotype.body_scale_from_genome(shortg, "male")
	if not is_equal_approx(tall_sc.y, Phenotype.HEIGHT_SCALE_MAX):
		_fail("all H should be Y max, got %s" % tall_sc)
	if not is_equal_approx(short_sc.y, Phenotype.HEIGHT_SCALE_MIN):
		_fail("all h should be Y min")
	var wide_sc: Vector2 = Phenotype.body_scale_from_genome(wide, "male")
	var nar_sc: Vector2 = Phenotype.body_scale_from_genome(narrow, "male")
	if not is_equal_approx(wide_sc.x, Phenotype.WIDTH_SCALE_MAX):
		_fail("all W should be X max")
	if not is_equal_approx(nar_sc.x, Phenotype.WIDTH_SCALE_MIN):
		_fail("all w should be X min")
	if not is_equal_approx(tall_sc.x, Phenotype.WIDTH_SCALE_MIN):
		_fail("max height + min width should be tall-narrow")
	if tall_sc.y <= nar_sc.y + 0.001 and tall_sc.x >= wide_sc.x - 0.001:
		_fail("tall-narrow vs wide should differ on axes")
	for i in range(8):
		var kid_h: Dictionary = GenomeOps.recombine(tall, tall, _rng(800 + i), false)
		if Phenotype.height_tall_count(kid_h) != 8:
			_fail("all-H parents must produce height 8")
		var kid_s: Dictionary = GenomeOps.recombine(shortg, shortg, _rng(900 + i), false)
		if Phenotype.height_tall_count(kid_s) != 0:
			_fail("all-h parents must produce height 0")
		var kid_w: Dictionary = GenomeOps.recombine(wide, wide, _rng(910 + i), false)
		if Phenotype.width_wide_count(kid_w) != 8:
			_fail("all-W parents must produce width 8")
		var kid_n: Dictionary = GenomeOps.recombine(narrow, narrow, _rng(920 + i), false)
		if Phenotype.width_wide_count(kid_n) != 0:
			_fail("all-w parents must produce width 0")

	var mid_hw: Dictionary = skin_hair.duplicate(true)
	for hid in Catalog.height_locus_ids():
		GenomeOps.set_pair(mid_hw, hid, ["H", "h"])
	for wid in Catalog.width_locus_ids():
		GenomeOps.set_pair(mid_hw, wid, ["W", "w"])
	if Phenotype.height_tall_count(mid_hw) != 4 or Phenotype.width_wide_count(mid_hw) != 4:
		_fail("mid parent should count 4/4")
	var saw_not_extreme := false
	for i in range(24):
		var kid_hw: Dictionary = GenomeOps.recombine(mid_hw, mid_hw, _rng(930 + i), false)
		var hc: int = Phenotype.height_tall_count(kid_hw)
		var wc: int = Phenotype.width_wide_count(kid_hw)
		if hc < 0 or hc > 8 or wc < 0 or wc > 8:
			_fail("child height/width out of range")
		if hc != 0 and hc != 8 and wc != 0 and wc != 8:
			saw_not_extreme = true
	if not saw_not_extreme:
		_fail("mid x mid should not force every child to 0 or 8")

	var hs_only: Dictionary = {}
	GenomeOps.set_pair(hs_only, Catalog.HAIR_DARK, ["B", "B"])
	GenomeOps.set_pair(hs_only, Catalog.HAIR_RED, ["r", "r"])
	for sid in Catalog.skin_locus_ids():
		GenomeOps.set_pair(hs_only, sid, ["D", "d"])
	var filled_hw: Dictionary = GenomeOps.fill_missing_loci(hs_only, _rng(55))
	if GenomeOps.get_pair(filled_hw, Catalog.HAIR_DARK) != GenomeOps.get_pair(hs_only, Catalog.HAIR_DARK):
		_fail("fill height/width must not rewrite hair")
	if GenomeOps.get_pair(filled_hw, Catalog.SKIN_A) != GenomeOps.get_pair(hs_only, Catalog.SKIN_A):
		_fail("fill height/width must not rewrite skin")
	if not GenomeOps.has_complete_genome(filled_hw):
		_fail("fill should add height/width")

	var m_sc: Vector2 = Phenotype.body_scale_from_genome(tall, "male")
	var f_sc: Vector2 = Phenotype.body_scale_from_genome(tall, "female")
	if m_sc != f_sc:
		_fail("dimorph stub: male and female body_scale must match")
	if Phenotype.dimorph_offset(tall, "male") != 0.0 or Phenotype.dimorph_offset(tall, "female") != 0.0:
		_fail("dimorph_offset must be 0 while disabled")
	if Phenotype.head_scale_from_genome(tall) != Vector2.ONE:
		_fail("head_scale hook must be (1, 1)")

	var man := {"npc_type": "caveman"}
	var woman := {"npc_type": "woman"}
	BirthEngine.apply_genome(man, tall)
	BirthEngine.apply_genome(woman, tall)
	var mp: Dictionary = man["genetics_profile"]
	var wp: Dictionary = woman["genetics_profile"]
	if mp.get("body_scale") != wp.get("body_scale"):
		_fail("apply_genome male/female body_scale should match while dimorph off")
	if mp.get("head_scale") != Vector2.ONE:
		_fail("apply_genome should store head_scale ONE")
	var baby_ent := {"npc_type": "baby"}
	BirthEngine.apply_genome(baby_ent, tall)
	var bp: Dictionary = baby_ent["genetics_profile"]
	if not is_equal_approx((bp.get("body_scale") as Vector2).y, Phenotype.HEIGHT_SCALE_MAX):
		_fail("baby apply_genome should store tall body_scale Y, got %s" % str(bp.get("body_scale")))
	BirthEngine.apply_genome(baby_ent, shortg)
	bp = baby_ent["genetics_profile"]
	if not is_equal_approx((bp.get("body_scale") as Vector2).y, Phenotype.HEIGHT_SCALE_MIN):
		_fail("baby apply_genome should store short body_scale Y")
	if Phenotype.body_scale_from_genome(tall, "baby") != Phenotype.body_scale_from_genome(tall, "male"):
		_fail("baby gene scale should match male while dimorph off")

	print("TEST_BIRTH_ALLELES_PASS")
	quit(0)
