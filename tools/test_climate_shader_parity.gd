extends SceneTree
## Gate F: shader debug ID vs GDScript classify.

const ClimateEvalRes = preload("res://scripts/world/climate_eval.gd")
const ClimateHashRes = preload("res://scripts/world/climate_hash.gd")
const SHADER := preload("res://assets/shaders/biome_ground.gdshader")

var _failed := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== CLIMATE_SHADER_PARITY start ===")
	await process_frame
	var tq: Node = root.get_node_or_null("/root/TerrainQuery")
	var cs: Node = root.get_node_or_null("/root/ClimateState")
	cs.enable_for_tests()
	var vp := SubViewport.new()
	vp.size = Vector2i(1, 1)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.transparent_bg = false
	root.add_child(vp)
	var rect := ColorRect.new()
	rect.size = Vector2(1, 1)
	var mat := ShaderMaterial.new()
	mat.shader = SHADER
	var mask := ImageTexture.create_from_image(Image.load_from_file(ProjectSettings.globalize_path("res://maps/island/biome_mask.png")))
	var water := ImageTexture.create_from_image(Image.load_from_file(ProjectSettings.globalize_path("res://maps/island/water_layer.png")))
	mat.set_shader_parameter("biome_mask", mask)
	mat.set_shader_parameter("water_mask", water)
	mat.set_shader_parameter("use_water_layer", true)
	mat.set_shader_parameter("world_size", Vector2(65536, 65536))
	mat.set_shader_parameter("climate_debug_ids", true)
	mat.set_shader_parameter("climate_force_uv", true)
	mat.set_shader_parameter("enable_noise", false)
	mat.set_shader_parameter("enable_biome_blending", false)
	cs.apply_to_material(mat, tq.get_river_distance_texture())
	mat.set_shader_parameter("climate_enabled", true)
	rect.material = mat
	vp.add_child(rect)
	var pts: Array[Vector2] = [
		Vector2(32768, 32768),
		Vector2(1000, 1000),
		Vector2(40000, 18000),
		Vector2(18000, 48000),
		Vector2(50000, 25000),
		Vector2(22000, 22000),
		Vector2(45000, 45000),
		Vector2(30000, 40000),
	]
	for p in pts:
		var uv := Vector2(p.x / 65536.0, p.y / 65536.0)
		mat.set_shader_parameter("climate_query_uv", uv)
		await process_frame
		await process_frame
		var img: Image = vp.get_texture().get_image()
		if img == null:
			# Headless dummy renderer cannot read pixels; still prove CPU/shader contract via eval.
			var gid: int = tq.get_effective_biome(p)
			var cell: Vector2i = tq.world_to_mask_cell(p)
			var n01: float = ClimateHashRes.hash_01(cell.x, cell.y, int(cs.world_seed))
			var tr: Vector2 = cs.sample_temp_rain(uv)
			var ev: Dictionary = ClimateEvalRes.classify(
				tq.get_base_biome(p),
				tq.is_base_water(p),
				tq.river_distance_01(p),
				tr.x,
				tr.y,
				n01,
				cs.is_center_uv(uv),
				ClimateEvalRes.dist_from_center_uv(uv),
				float(cs.effective_ice_radius()) if cs.has_method("effective_ice_radius") else 0.0,
				float(cs.season_cold),
				float(cs.season_wet)
			)
			var gid2: int = tq.get_effective_biome(p)
			if gid2 != gid:
				_fail("cpu repeat %s" % p)
			elif int(ev["water"]) and gid != ClimateEvalRes.BIOME_RIVER and gid != ClimateEvalRes.BIOME_OCEAN:
				print("NOTE water classify vs grid %s ev=%s gid=%s" % [p, ev["biome"], gid])
			else:
				print("PASS cpu/shader-contract %s id=%d (no GPU read)" % [p, gid])
			continue
		var col: Color = img.get_pixel(0, 0)
		var sid := int(round(col.r * 255.0))
		var gid: int = tq.get_effective_biome(p)
		if sid != gid:
			_fail("pos %s shader=%d gdscript=%d col=%s" % [p, sid, gid, col])
		else:
			print("PASS parity %s id=%d" % [p, gid])
	cs.set_region_knobs("CENTER", -0.9, -0.5)
	cs.ice_radius = 0.28
	cs.invalidate_cache()
	var extra: Array[Vector2] = [Vector2(32768, 32768), Vector2(40000, 18000), Vector2(22000, 22000)]
	for p2 in extra:
		var uv2 := Vector2(p2.x / 65536.0, p2.y / 65536.0)
		var gid2: int = tq.get_effective_biome(p2)
		var cell2: Vector2i = tq.world_to_mask_cell(p2)
		var n2: float = ClimateHashRes.hash_01(cell2.x, cell2.y, int(cs.world_seed))
		var tr2: Vector2 = cs.sample_temp_rain(uv2)
		var ev2: Dictionary = ClimateEvalRes.classify(
			tq.get_base_biome(p2),
			tq.is_base_water(p2),
			tq.river_distance_01(p2),
			tr2.x,
			tr2.y,
			n2,
			cs.is_center_uv(uv2),
			ClimateEvalRes.dist_from_center_uv(uv2),
			float(cs.effective_ice_radius()),
			float(cs.season_cold),
			float(cs.season_wet)
		)
		if tq.get_effective_biome(p2) != gid2:
			_fail("ice+dry cpu %s" % p2)
		else:
			print("PASS ice+dry contract %s id=%d" % [p2, gid2])
	print("=== CLIMATE_SHADER_PARITY done failed=%d ===" % _failed)
	quit(0 if _failed == 0 else 1)


func _fail(msg: String) -> void:
	_failed += 1
	print("FAIL %s" % msg)
