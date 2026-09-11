extends Node
## Daily climate nudge. Off unless ClimateState.climate_enabled.

const ClimateConstantsRes = preload("res://scripts/world/climate_constants.gd")

var _last_hist: Dictionary = {}
var _last_glacier: float = -1.0
var _last_desert: float = -1.0
var _log_path: String = ""
var _eco_tick_path: String = ""
var _eco_ladder_path: String = ""
var _front_tick_path: String = ""


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	var sm := get_node_or_null("/root/SimulationManager")
	if sm and sm.has_signal("simulation_tick"):
		sm.simulation_tick.connect(_on_sim_tick)
	_log_path = ProjectSettings.globalize_path("res://Tests/logs/climate_tick.jsonl")
	_eco_tick_path = ProjectSettings.globalize_path("res://Tests/logs/eco_tick.jsonl")
	_eco_ladder_path = ProjectSettings.globalize_path("res://Tests/logs/eco_ladder.jsonl")
	_front_tick_path = ProjectSettings.globalize_path("res://Tests/logs/front_tick.jsonl")
	call_deferred("_log_boot")


var _tick_accum: int = 0


func _on_sim_tick(_dt: float = 0.0) -> void:
	var cs: Node = get_node_or_null("/root/ClimateState")
	if cs == null or not bool(cs.climate_enabled):
		return
	if not multiplayer.has_multiplayer_peer() or multiplayer.is_server():
		_tick_accum += 1
		if _tick_accum < 30:
			return
		_tick_accum = 0
		advance_day()


func skip_days(count: int) -> void:
	var n: int = maxi(count, 0)
	for _i in n:
		advance_day()


func advance_day() -> void:
	var cs: Node = get_node_or_null("/root/ClimateState")
	if cs == null:
		return
	if cs.has_method("sync_events_from_string"):
		cs.sync_events_from_string()
	cs.sim_day = int(cs.sim_day) + 1
	cs.season_phase = fmod(float(cs.sim_day) / ClimateConstantsRes.DAYS_PER_YEAR, 1.0)
	var so: Vector2 = cs.season_offsets() if cs.has_method("season_offsets") else Vector2.ZERO
	cs.season_cold = so.x
	cs.season_wet = so.y
	var max_t: float = ClimateConstantsRes.MAX_TEMP_DELTA_PER_DAY
	var max_r: float = ClimateConstantsRes.MAX_RAIN_DELTA_PER_DAY
	var spring: float = ClimateConstantsRes.SPRING_RETURN_FORCE
	var inertia: float = ClimateConstantsRes.RITUAL_INERTIA
	var rit: float = clampf(float(cs.ritual_pressure), -ClimateConstantsRes.RITUAL_CAP_PER_REGION_PER_DAY, ClimateConstantsRes.RITUAL_CAP_PER_REGION_PER_DAY)
	var ice_on: bool = bool(cs.event_ice)
	var dry_on: bool = bool(cs.event_drought)
	var flood_on: bool = bool(cs.event_flood)
	var any_ev: bool = ice_on or dry_on or flood_on
	for region in ClimateConstantsRes.REGIONS:
		var t: float = float(cs.temperature[region])
		var r: float = float(cs.rainfall[region])
		var t_tgt := 0.0
		var r_tgt := 0.0
		if ice_on:
			t_tgt = -0.85 if region == "CENTER" else -0.32
		if dry_on:
			r_tgt = -0.8 if region in ["NE", "E", "N"] else -0.4
			t_tgt = maxf(t_tgt, 0.25) if not ice_on else t_tgt
		if flood_on:
			r_tgt = 0.75
		if not any_ev:
			t_tgt = 0.0
			r_tgt = 0.0
		t_tgt = clampf(t_tgt + rit * inertia * 8.0, -1.0, 1.0)
		r_tgt = clampf(r_tgt + rit * inertia * 8.0, -1.0, 1.0)
		var dt: float = clampf(t_tgt - t, -max_t, max_t)
		var dr: float = clampf(r_tgt - r, -max_r, max_r)
		if not any_ev:
			dt = clampf(-t * spring * 2.0, -max_t, max_t)
			dr = clampf(-r * spring * 2.0, -max_r, max_r)
		cs.temperature[region] = clampf(t + dt, -1.0, 1.0)
		cs.rainfall[region] = clampf(r + dr, -1.0, 1.0)
		_chase_stress(cs, region)
	if ice_on:
		cs.ice_radius = minf(ClimateConstantsRes.ICE_RADIUS_MAX, float(cs.ice_radius) + ClimateConstantsRes.ICE_RADIUS_PER_DAY)
	else:
		cs.ice_radius = maxf(0.0, float(cs.ice_radius) - ClimateConstantsRes.ICE_RADIUS_PER_DAY * 0.55)
	cs.ritual_pressure = float(cs.ritual_pressure) * ClimateConstantsRes.RITUAL_DECAY
	var bf: Node = get_node_or_null("/root/BiomeFronts")
	if bf and bf.has_method("step"):
		bf.step()
	if cs.has_method("invalidate_cache"):
		cs.invalidate_cache()
	else:
		cs._bump_cache()
	_log_tick()
	_log_eco()
	if multiplayer.has_multiplayer_peer() and multiplayer.is_server():
		rpc("receive_climate_payload", cs.to_payload())


func _chase_stress(cs: Node, region: String) -> void:
	var kt: float = float(cs.temperature[region])
	var kr: float = float(cs.rainfall[region])
	var st: float = float(cs.cold_stress.get(region, kt))
	var sr: float = float(cs.moisture_stress.get(region, kr))
	var rt: float = ClimateConstantsRes.STRESS_CHASE
	var rr: float = ClimateConstantsRes.STRESS_CHASE
	if absf(kt) < absf(st) - 0.001:
		rt *= 0.42
	if absf(kr) < absf(sr) - 0.001:
		rr *= 0.42
	cs.cold_stress[region] = st + (kt - st) * rt
	cs.moisture_stress[region] = sr + (kr - sr) * rr


func _log_tick() -> void:
	var cs: Node = get_node_or_null("/root/ClimateState")
	var tq: Node = get_node_or_null("/root/TerrainQuery")
	if cs == null or tq == null or not tq.has_method("sample_climate_histogram"):
		return
	var hist: Dictionary = tq.sample_climate_histogram(48)
	var hist_center: Dictionary = {}
	var hist_ne: Dictionary = {}
	if tq.has_method("sample_histogram_uv"):
		hist_center = tq.sample_histogram_uv(Vector2(0.38, 0.38), Vector2(0.62, 0.62), 32)
		hist_ne = tq.sample_histogram_uv(Vector2(0.66, 0.0), Vector2(1.0, 0.34), 32)
	var delta: Dictionary = {}
	for k in hist.keys():
		var prev: float = float(_last_hist.get(k, hist[k]))
		delta[k] = float(hist[k]) - prev
	_last_hist = hist.duplicate()
	var rec := {
		"t": "climate_tick",
		"day": cs.sim_day,
		"event": cs.active_event,
		"ritual": cs.ritual_pressure,
		"hist": hist,
		"hist_center": hist_center,
		"hist_ne": hist_ne,
		"delta_vs_yesterday": delta,
		"temperature": cs.temperature.duplicate(),
		"rainfall": cs.rainfall.duplicate(),
	}
	_append_jsonl(_log_path, rec)
	var pi := get_node_or_null("/root/PlaytestInstrumentor")
	if pi and pi.has_method("log_event"):
		pi.log_event("climate_tick", rec)


func _log_eco() -> void:
	var cs: Node = get_node_or_null("/root/ClimateState")
	var tq: Node = get_node_or_null("/root/TerrainQuery")
	if cs == null or tq == null or not tq.has_method("eco_hud_snapshot"):
		return
	var bf: Node = get_node_or_null("/root/BiomeFronts")
	var snap: Dictionary = tq.eco_hud_snapshot(56)
	var hist: Dictionary = snap.get("hist", {})
	var g: float = float(hist.get("5", 0.0))
	var d: float = float(hist.get("2", 0.0))
	var dg: float = 0.0
	var dd: float = 0.0
	if _last_glacier >= 0.0:
		dg = absf(g - _last_glacier)
	if _last_desert >= 0.0:
		dd = absf(d - _last_desert)
	_last_glacier = g
	_last_desert = d
	var max_d: float = maxf(dg, dd)
	var events: Array = []
	if cs.event_ice:
		events.append("ice_age")
	if cs.event_drought:
		events.append("drought")
	if cs.event_flood:
		events.append("flood")
	var rec := {
		"t": "eco_tick",
		"day": cs.sim_day,
		"events": events,
		"ice_radius": float(cs.ice_radius),
		"dry_line": float(bf.dry_line) if bf else 1.0,
		"season_phase": float(cs.season_phase),
		"hist": hist,
		"hist_center": snap.get("hist_center", {}),
		"hist_mid": snap.get("hist_mid", {}),
		"hist_coast": snap.get("hist_coast", {}),
		"near_river": snap.get("near_river", {}),
		"far": snap.get("far", {}),
		"max_abs_hist_delta": max_d,
	}
	var pi := get_node_or_null("/root/PlaytestInstrumentor")
	if bf and bf.has_method("get_last_metrics"):
		var fm: Dictionary = bf.get_last_metrics()
		for k in fm.keys():
			if k != "t":
				rec["f_" + str(k)] = fm[k]
		fm["day"] = cs.sim_day
		fm["events"] = events.duplicate()
		_append_jsonl(_front_tick_path, fm)
		if pi and pi.has_method("log_event"):
			pi.log_event("front_tick", fm)
	_append_jsonl(_eco_tick_path, rec)
	if cs.event_drought or cs.event_ice:
		var lad := {
			"t": "eco_ladder",
			"day": cs.sim_day,
			"forest": float(hist.get("6", 0.0)),
			"savanna": float(hist.get("1", 0.0)),
			"desert": float(hist.get("2", 0.0)),
			"swamp": float(hist.get("4", 0.0)),
			"jungle": float(hist.get("3", 0.0)),
			"water": float(hist.get("7", 0.0)),
			"glacier": g,
		}
		_append_jsonl(_eco_ladder_path, lad)
	if pi and pi.has_method("log_event"):
		pi.log_event("eco_tick", rec)


func _append_jsonl(path: String, rec: Dictionary) -> void:
	if path == "":
		return
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var f := FileAccess.open(path, FileAccess.READ_WRITE)
	if f == null:
		f = FileAccess.open(path, FileAccess.WRITE)
	else:
		f.seek_end()
	if f:
		f.store_line(JSON.stringify(rec))
		f.close()


func _log_boot() -> void:
	var cs: Node = get_node_or_null("/root/ClimateState")
	var tq: Node = get_node_or_null("/root/TerrainQuery")
	var rec := {
		"t": "climate_boot",
		"enabled": bool(cs.climate_enabled) if cs else false,
		"seed": int(cs.world_seed) if cs else 0,
		"mask": tq.get_mask_size() if tq and tq.has_method("get_mask_size") else Vector2i.ZERO,
	}
	var pi := get_node_or_null("/root/PlaytestInstrumentor")
	if pi and pi.has_method("log_event"):
		pi.log_event("climate_boot", rec)
	_log_query_sample()


func _log_query_sample() -> void:
	var tq: Node = get_node_or_null("/root/TerrainQuery")
	var cs: Node = get_node_or_null("/root/ClimateState")
	if tq == null or not tq.has_method("get_effective_biome"):
		return
	var pts: Array[Vector2] = [
		Vector2(32768, 32768),
		Vector2(40000, 18000),
		Vector2(18000, 45000),
		Vector2(50000, 20000),
		Vector2(20000, 20000),
		Vector2(48000, 48000),
		Vector2(1000, 1000),
		Vector2(64000, 64000),
		Vector2(32768, 20000),
		Vector2(20000, 32768),
		Vector2(40000, 40000),
		Vector2(25000, 40000),
		Vector2(45000, 25000),
		Vector2(30000, 50000),
		Vector2(50000, 30000),
		Vector2(35000, 35000),
	]
	var samples: Array = []
	for p in pts:
		var uv := Vector2(p.x / 65536.0, p.y / 65536.0)
		var tr := Vector2.ZERO
		if cs and cs.has_method("sample_temp_rain"):
			tr = cs.sample_temp_rain(uv)
		samples.append({
			"pos": [p.x, p.y],
			"base": tq.get_base_biome(p),
			"effective": tq.get_effective_biome(p),
			"water": tq.is_water(p),
			"temp": tr.x,
			"rain": tr.y,
		})
	var rec := {"t": "climate_query_sample", "samples": samples}
	var pi := get_node_or_null("/root/PlaytestInstrumentor")
	if pi and pi.has_method("log_event"):
		pi.log_event("climate_query_sample", rec)


@rpc("authority", "call_remote", "reliable")
func receive_climate_payload(payload: Dictionary) -> void:
	var cs: Node = get_node_or_null("/root/ClimateState")
	if cs:
		cs.apply_payload(payload)
