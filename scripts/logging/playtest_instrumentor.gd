extends Node

const CombatAllyCheck = preload("res://scripts/systems/combat_ally_check.gd")

# Playtest Instrumentor - Captures structured events during playtests for debugging
# Enable with: --playtest-capture (or --herd-capture)
# Output: user://playtest_YYYYMMDD_HHMMSS.jsonl (JSON Lines - one object per line)
# Each line: {"t": float, "evt": string, ...event-specific fields}
# Each line is flushed immediately (_write → store_string + flush) so logs survive crashes mid-session.

var _enabled: bool = false
var _file: FileAccess = null
var _file_path: String = ""
var _start_time: float = 0.0
var _snapshot_interval: float = 5.0
var _last_snapshot_time: float = 0.0
var _agro_combat_test: bool = false  # When true, capture is for agro combat test; shorter snapshot interval
var _raid_test: bool = false  # When true, capture is for ClanBrain raid test
var _playtest_2min: bool = false  # When true, 2-min productivity test; shorter snapshot, state counts
var _playtest_4min: bool = false  # When true, 4-min productivity test
var _playtest_duration_sec: float = 120.0  # Auto-quit after this many seconds
var _combat_started_count: int = 0  # For invariant check
var _friendly_fire_instrumented_hits: int = 0  # combat_hit where target is ally (should stay 0 if pipeline is correct)
var _party_test: bool = false  # --party-test: same capture profile as agro, tag session for party validation

func _ready() -> void:
	if OS.get_name() == "Web":
		return
	var args = OS.get_cmdline_user_args()
	if "--playtest-capture" in args or "--herd-capture" in args:
		_enabled = true
	if "--playtest-2min" in args:
		_enabled = true
		_playtest_2min = true
		_playtest_duration_sec = 120.0
		_snapshot_interval = 2.0
	if "--playtest-4min" in args:
		_enabled = true
		_playtest_4min = true
		_playtest_duration_sec = 240.0
		_snapshot_interval = 2.0
	# DebugConfig.playtest_capture_always: enable capture for normal play without cmdline
	var dc = get_node_or_null("/root/DebugConfig")
	if dc and dc.get("playtest_capture_always") == true:
		_enabled = true
	if "--agro-combat-test" in args and dc and dc.get("allow_agro_combat_test_from_cli") == true:
		_enabled = true
		_agro_combat_test = true
		_snapshot_interval = 2.0  # More FPS samples during short combat test
	if "--party-test" in args and dc and dc.get("allow_agro_combat_test_from_cli") == true:
		_enabled = true
		_agro_combat_test = true
		_party_test = true
		_snapshot_interval = 2.0
	if "--raid-test" in args:
		_enabled = true
		_raid_test = true
		_snapshot_interval = 2.0  # Raid test: snapshots every 2s
	if _enabled:
		_start()
	if _enabled:
		print("✓ Playtest capture enabled: %s" % _get_file_path())
		print("✓ Gather diagnostics: gather_hitbox_ready (spawn), gather_space_pressed (each Space), gather_body_* / gather_* flow, hitbox vs node origin, overlaps[]")
		if _party_test:
			print("✓ Party test data collection (NPC-led party / formation ticks; snapshots every %.1fs)" % _snapshot_interval)
		elif _agro_combat_test:
			print("✓ Agro/combat test data collection (snapshots every %.1fs)" % _snapshot_interval)
		if _raid_test:
			print("✓ Raid test data collection (snapshots every %.1fs)" % _snapshot_interval)
		if _playtest_2min:
			print("✓ 2-min productivity test (snapshots every %.1fs, auto-quit at %.0fs)" % [_snapshot_interval, _playtest_duration_sec])
		if _playtest_4min:
			print("✓ 4-min productivity test (snapshots every %.1fs, auto-quit at %.0fs)" % [_snapshot_interval, _playtest_duration_sec])

const MARKER_FILE := "user://last_playtest_path.txt"

func _start() -> void:
	if not _enabled:
		return
	if OS.get_name() == "Web":
		_enabled = false
		return
	# CLI wins over env (PowerShell env sometimes not visible to Godot on Windows)
	var log_dir_cli: String = ""
	var ua := OS.get_cmdline_user_args()
	for i in range(ua.size()):
		if ua[i] == "--playtest-log-dir" and i + 1 < ua.size():
			log_dir_cli = str(ua[i + 1]).strip_edges().trim_suffix("/")
			break
	var env_dir := OS.get_environment("GODOT_TEST_LOG_DIR").strip_edges().trim_suffix("/")
	if log_dir_cli != "":
		_file_path = log_dir_cli + "/playtest_session.jsonl"
	elif env_dir != "":
		_file_path = env_dir + "/playtest_session.jsonl"
	else:
		var now = Time.get_datetime_dict_from_system()
		_file_path = "user://playtest_%04d%02d%02d_%02d%02d%02d.jsonl" % [
			now.year, now.month, now.day, now.hour, now.minute, now.second
		]
	_start_time = Time.get_ticks_msec() / 1000.0
	_last_snapshot_time = _start_time
	_file = FileAccess.open(_file_path, FileAccess.WRITE)
	if _file:
		# Write marker so reporter can locate session (user:// or GODOT_TEST_LOG_DIR absolute path)
		var marker = FileAccess.open(MARKER_FILE, FileAccess.WRITE)
		if marker:
			var path_for_marker: String = _file_path
			if not _file_path.begins_with("user://") and _file_path != "":
				path_for_marker = ProjectSettings.globalize_path(_file_path)
			marker.store_string(path_for_marker)
			marker.close()
		var session: Dictionary = {"t": 0.0, "evt": "session_start", "path": _file_path}
		if _party_test:
			session["party_test"] = true
		if _agro_combat_test:
			session["agro_combat_test"] = true
		if _raid_test:
			session["raid_test"] = true
		if _playtest_2min or _playtest_4min:
			session["playtest_2min"] = true
		if _playtest_4min:
			session["playtest_4min"] = true
		session["playtest_duration_sec"] = _playtest_duration_sec
		_write(session)

func _get_file_path() -> String:
	return ProjectSettings.globalize_path(_file_path) if _file_path != "" else ""

func _write(obj: Dictionary) -> void:
	if not _enabled or not _file or not _file.is_open():
		return
	obj["t"] = (Time.get_ticks_msec() / 1000.0) - _start_time
	var line = JSON.stringify(obj) + "\n"
	_file.store_string(line)
	_file.flush()

func is_enabled() -> bool:
	return _enabled

func is_playtest_2min() -> bool:
	return _playtest_2min

func is_playtest_timed() -> bool:
	return _playtest_2min or _playtest_4min

func get_playtest_duration_sec() -> float:
	return _playtest_duration_sec

func end_playtest_2min() -> void:
	"""Call before quit: write test_run_ended, flush."""
	if not _enabled or not (_playtest_2min or _playtest_4min):
		return
	_write({"evt": "test_run_ended_2min"})
	if _file and _file.is_open():
		_file.flush()

# --- Herding events ---

func herd_wildnpc_can_enter(npc_name: String, result: bool, reason: String = "") -> void:
	_write({"evt": "herd_wildnpc_can_enter", "npc": npc_name, "result": result, "reason": reason})

func herd_wildnpc_enter(npc_name: String, herded_count: int) -> void:
	_write({"evt": "herd_wildnpc_enter", "npc": npc_name, "herded_count": herded_count})

func herd_wildnpc_exit(npc_name: String, herded_count: int) -> void:
	_write({"evt": "herd_wildnpc_exit", "npc": npc_name, "herded_count": herded_count})

func herd_influence_body_entered(animal_name: String, herder_name: String, herder_type: String) -> void:
	_write({"evt": "herd_influence_entered", "animal": animal_name, "herder": herder_name, "herder_type": herder_type})

func herd_influence_body_exited(animal_name: String, herder_name: String) -> void:
	_write({"evt": "herd_influence_exited", "animal": animal_name, "herder": herder_name})

func herd_influence_contested(animal_name: String, challenger_name: String, influence: float) -> void:
	_write({"evt": "herd_influence_contested", "animal": animal_name, "challenger": challenger_name, "influence": influence})

func herd_influence_transfer(animal_name: String, old_herder: String, new_herder: String) -> void:
	_write({"evt": "herd_influence_transfer", "animal": animal_name, "from": old_herder, "to": new_herder})

func herd_try_chance(animal_name: String, leader_name: String, success: bool, force_influence: bool) -> void:
	_write({"evt": "herd_try_chance", "animal": animal_name, "leader": leader_name, "success": success, "force_influence": force_influence})

func herd_count_change(npc_name: String, old_count: int, new_count: int, cause: String) -> void:
	_write({"evt": "herd_count_change", "npc": npc_name, "old": old_count, "new": new_count, "cause": cause})

func herd_delivery_cooldown(herder_name: String, cooldown_sec: float) -> void:
	_write({"evt": "herd_delivery_cooldown", "herder": herder_name, "cooldown_sec": cooldown_sec})

func deposit_while_herding(npc_name: String, herded_count: int, items_deposited: int) -> void:
	"""Verification event: deposit triggered with herded_count >= 2 (not-full inventory path)."""
	_write({"evt": "deposit_while_herding", "npc": npc_name, "herded_count": herded_count, "items_deposited": items_deposited})

func herd_fsm_eval(npc_name: String, from_state: String, to_state: String) -> void:
	if "herd" in from_state or "herd" in to_state or "party" in from_state or "party" in to_state:
		_write({"evt": "herd_fsm_transition", "npc": npc_name, "from": from_state, "to": to_state})


## Any AI NPC FSM change (excludes player). Use for verify sessions — see npc_world_probe for positions.
func npc_fsm_transition(
		npc_name: String,
		npc_type: String,
		clan_name: String,
		from_state: String,
		to_state: String,
		herded_count: int,
		follow_ordered: bool,
		herder_name: String) -> void:
	_write({
		"evt": "npc_fsm_transition",
		"npc": npc_name,
		"type": npc_type,
		"clan": clan_name,
		"from": from_state,
		"to": to_state,
		"herded_count": herded_count,
		"follow_ordered": follow_ordered,
		"herder": herder_name,
	})


func party_formed(leader_name: String, follower_count: int, source: String) -> void:
	_write({"evt": "party_formed", "leader": leader_name, "follower_count": follower_count, "source": source})


func party_disbanded(leader_name: String, reason: String) -> void:
	_write({"evt": "party_disbanded", "leader": leader_name, "reason": reason})


func party_stance_changed(leader_name: String, old_mode: String, new_mode: String) -> void:
	_write({"evt": "party_stance_changed", "leader": leader_name, "from": old_mode, "to": new_mode})


func party_formation_tick(leader_name: String, followers_data: Array) -> void:
	_write({"evt": "party_formation_tick", "leader": leader_name, "followers": followers_data})


func herd_follow_tick(animal_name: String, herder_name: String, dist_to_herder: float, speed_mult: float, break_dist: float) -> void:
	_write({
		"evt": "herd_follow_tick",
		"animal": animal_name,
		"herder": herder_name,
		"dist": snappedf(dist_to_herder, 1.0),
		"speed_mult": snappedf(speed_mult, 0.01),
		"break_dist": snappedf(break_dist, 1.0),
	})

# --- Agro / combat events (Part 0 Step 0b) ---

func agro_increased(npc_name: String, value: float, reason: String) -> void:
	_write({"evt": "agro_increased", "npc": npc_name, "value": value, "reason": reason})

func agro_threshold_crossed(npc_name: String, above_70: bool) -> void:
	_write({"evt": "agro_threshold_crossed", "npc": npc_name, "above_70": above_70})

func combat_started(npc_name: String, target_name: String, attacker_clan: String = "", target_clan: String = "", friendly_fire: bool = false) -> void:
	_combat_started_count += 1
	if friendly_fire:
		_write({"evt": "friendly_fire_combat_started", "npc": npc_name, "target": target_name, "attacker_clan": attacker_clan, "target_clan": target_clan})
	_write({"evt": "combat_started", "npc": npc_name, "target": target_name, "attacker_clan": attacker_clan, "target_clan": target_clan, "friendly_fire": friendly_fire})

func combat_ended(npc_name: String, target_name: String) -> void:
	_write({"evt": "combat_ended", "npc": npc_name, "target": target_name})

func combat_target_switch(npc_name: String, old_target: String, new_target: String, reason: String) -> void:
	_write({"evt": "combat_target_switch", "npc": npc_name, "old_target": old_target, "new_target": new_target, "reason": reason})

func combat_hit(npc_name: String, target_name: String, attacker_clan: String = "", target_clan: String = "", friendly_fire: bool = false) -> void:
	if friendly_fire:
		_friendly_fire_instrumented_hits += 1
	_write({"evt": "combat_hit", "npc": npc_name, "target": target_name, "attacker_clan": attacker_clan, "target_clan": target_clan, "friendly_fire": friendly_fire})

func combat_whiff(npc_name: String, target_name: String, reason: String) -> void:
	_write({"evt": "combat_whiff", "npc": npc_name, "target": target_name, "reason": reason})

func stagger_self_blocked(npc_name: String, target_name: String) -> void:
	_write({"evt": "stagger_self_blocked", "npc": npc_name, "target": target_name})

func combat_detection_null(npc_name: String) -> void:
	_write({"evt": "combat_detection_null", "npc": npc_name})

func perception_query(npc_name: String, query_type: String, result_count: int, radius: float = 0.0) -> void:
	if not _enabled or not (_agro_combat_test or _raid_test):
		return
	_write({"evt": "perception_query", "npc": npc_name, "query": query_type, "count": result_count, "radius": radius})

# --- Normal play tuning events ---

func npc_died(npc_name: String, clan_name: String, cause: String) -> void:
	_write({"evt": "npc_died", "npc": npc_name, "clan": clan_name, "cause": cause})

func task_no_job(npc_name: String, building_name: String, reason: String, same_clan_count: int) -> void:
	_write({"evt": "task_no_job", "npc": npc_name, "building": building_name, "reason": reason, "same_clan_count": same_clan_count})

func competition_complete(data: Dictionary) -> void:
	var obj: Dictionary = {"evt": "competition_complete"}
	for k in data:
		obj[k] = data[k]
	_write(obj)

# --- Efficiency / unified test events ---

func npc_joined_clan(npc_name: String, clan_name: String, npc_type: String, reason: String = "herded") -> void:
	_write({"evt": "npc_joined_clan", "npc": npc_name, "clan": clan_name, "type": npc_type, "reason": reason})

func milestone_building_placed(clan_name: String, building_type: int, place_pos: Vector2 = Vector2.ZERO) -> void:
	_write({"evt": "milestone_building_placed", "clan": clan_name, "building_type": building_type, "x": place_pos.x, "y": place_pos.y})

func land_claim_placed(clan_name: String, x: float, y: float, nearest_dist: float, source: String) -> void:
	"""Placement verification: min distance to existing claims (player or AI)."""
	_write({"evt": "land_claim_placed", "clan": clan_name, "x": x, "y": y, "nearest_dist": nearest_dist, "source": source})

func baby_spawned(clan_name: String, mother_name: String, father_name: String, slot_count: int = -1) -> void:
	var obj: Dictionary = {"evt": "baby_spawned", "clan": clan_name, "mother": mother_name, "father": father_name}
	if slot_count >= 0:
		obj["slot_count"] = slot_count
	_write(obj)

func baby_grew_to_clansman(npc_name: String, clan_name: String) -> void:
	_write({"evt": "baby_grew_to_clansman", "npc": npc_name, "clan": clan_name})

# --- Raid test events (ClanBrain / RaidState) ---

func raid_evaluated(clan_name: String, score: float, score_breakdown: Dictionary) -> void:
	var obj: Dictionary = {"evt": "raid_evaluated", "clan": clan_name, "score": score}
	for k in score_breakdown:
		obj[k] = score_breakdown[k]
	_write(obj)

func raid_started(attacker_clan: String, target_clan: String) -> void:
	_write({"evt": "raid_started", "attacker_clan": attacker_clan, "target_clan": target_clan})

func raid_joined(npc_name: String, raid_phase: String) -> void:
	_write({"evt": "raid_joined", "npc": npc_name, "raid_phase": raid_phase})

func raid_aborted(clan_name: String, reason: String) -> void:
	_write({"evt": "raid_aborted", "clan": clan_name, "reason": reason})

func war_horn_triggered(clan_name: String, clansmen_rallied: int, near_claim: bool) -> void:
	_write({"evt": "war_horn_triggered", "clan": clan_name, "clansmen_rallied": clansmen_rallied, "near_claim": near_claim})

## Player-ordered clansman follow (RTS / context menu / drag); source = context_menu | drag_to_player | war_horn
func ordered_follow_started(npc_name: String, mode: String, source: String) -> void:
	_write({"evt": "ordered_follow_started", "npc": npc_name, "mode": mode, "source": source})

func ordered_follow_cleared(follower_count: int) -> void:
	_write({"evt": "ordered_follow_cleared", "follower_count": follower_count})

## Stance HUD (Follow/Guard/Attack) — does not by itself start follow; logs mode change on selected units
func stance_hud_set(npc_name: String, mode: String) -> void:
	_write({"evt": "stance_hud_set", "npc": npc_name, "mode": mode})

## Right-click context menu (debug campfire vs flag: player_clan_known false => only INFO on NPCs)
func context_menu_opened(target_type: String, option_ids: Array, player_clan_known: bool) -> void:
	_write({"evt": "context_menu_opened", "target_type": target_type, "option_ids": option_ids, "player_clan_known": player_clan_known})

## RTS drag box finished; added_count 0 often means no Flag claim for clan resolution
func selection_box_completed(added_count: int, player_clan_known: bool) -> void:
	_write({"evt": "selection_box_completed", "added_count": added_count, "player_clan_known": player_clan_known})

## _set_ordered_follow returned early (invalid npc / missing herd fields)
func ordered_follow_blocked(reason: String) -> void:
	_write({"evt": "ordered_follow_blocked", "reason": reason})

# ─── RTS clansman state events ────────────────────────────────────────────────

## Clansman entered herd/follow state (ordered follow only)
func clansman_follow_entered(npc_name: String, mode: String, slot: int, count: int, speed_mult: float) -> void:
	_write({"evt": "clansman_follow_entered", "npc": npc_name, "mode": mode, "slot": slot, "count": count, "speed_mult": speed_mult})

## Clansman exited herd/follow state — why it left
func clansman_follow_exited(npc_name: String, mode: String, reason: String) -> void:
	_write({"evt": "clansman_follow_exited", "npc": npc_name, "mode": mode, "reason": reason})

## Formation mode changed while already following (HUD button)
func clansman_mode_changed(npc_name: String, old_mode: String, new_mode: String) -> void:
	_write({"evt": "clansman_mode_changed", "npc": npc_name, "from": old_mode, "to": new_mode})

## Speed multiplier applied this frame (throttled — only on change)
func clansman_speed_set(npc_name: String, mode: String, mult: float) -> void:
	_write({"evt": "clansman_speed_set", "npc": npc_name, "mode": mode, "mult": mult})

## Clansman entered defend state
func clansman_defend_entered(npc_name: String, claim_name: String, angle: float, index: int, total: int) -> void:
	_write({"evt": "clansman_defend_entered", "npc": npc_name, "claim": claim_name, "angle": angle, "index": index, "total": total})

## Clansman left defend state
func clansman_defend_exited(npc_name: String, claim_name: String, reason: String) -> void:
	_write({"evt": "clansman_defend_exited", "npc": npc_name, "claim": claim_name, "reason": reason})

## Combat entry blocked by stance agro threshold
func clansman_combat_blocked(npc_name: String, mode: String, agro: float, threshold: float) -> void:
	_write({"evt": "clansman_combat_blocked", "npc": npc_name, "mode": mode, "agro": agro, "threshold": threshold})

## Clansman disengaged because pursuit leash exceeded
func clansman_leash_break(npc_name: String, mode: String, dist: float, max_dist: float) -> void:
	_write({"evt": "clansman_leash_break", "npc": npc_name, "mode": mode, "dist": dist, "max_dist": max_dist})

## Agro reset after combat exit
func clansman_agro_reset(npc_name: String, mode: String, new_agro: float) -> void:
	_write({"evt": "clansman_agro_reset", "npc": npc_name, "mode": mode, "new_agro": new_agro})

## Per-snapshot RTS follower summary (one entry per ordered follower)
func clansman_rts_snapshot(followers: Array) -> void:
	"""followers: Array of {npc, mode, state, speed_mult, slot, count, dist_to_leader}"""
	if followers.is_empty():
		return
	_write({"evt": "clansman_rts_snapshot", "followers": followers})

## Player gathering diagnostics (berry bushes, trees, etc.). Requires --playtest-capture (or other capture flags).
## Payload should include evt: gather_* and placement fields from GatherableResource._gather_diagnostic_payload().
func gather_diagnostic(payload: Dictionary) -> void:
	if not _enabled or payload.is_empty():
		return
	_write(payload)

## Formation position tick — logged every update_interval per ordered clansman
## slot_target: world position of assigned formation slot
## actual_pos: npc world position
## leader_pos: leader world position
## offset: actual_pos - leader_pos (relative vector, tells you where NPC is vs leader)
## slot_offset: slot_target - leader_pos (where they SHOULD be vs leader)
## dist_to_slot: distance between actual_pos and slot_target
## facing: leader facing direction used for formation geometry
func clansman_formation_tick(
		npc_name: String, mode: String, slot: int, count: int,
		actual_x: float, actual_y: float,
		slot_x: float, slot_y: float,
		leader_x: float, leader_y: float,
		dist_to_slot: float, facing_x: float, facing_y: float,
		speed_mult: float) -> void:
	_write({
		"evt": "clansman_formation_tick",
		"npc": npc_name, "mode": mode, "slot": slot, "count": count,
		"ax": snappedf(actual_x, 1.0), "ay": snappedf(actual_y, 1.0),
		"sx": snappedf(slot_x, 1.0), "sy": snappedf(slot_y, 1.0),
		"lx": snappedf(leader_x, 1.0), "ly": snappedf(leader_y, 1.0),
		"d2slot": snappedf(dist_to_slot, 1.0),
		"fx": snappedf(facing_x, 0.01), "fy": snappedf(facing_y, 0.01),
		"spd": snappedf(speed_mult, 0.01)
	})

## F5 / --rts-playtest-spawn: player-owned claim + 5 same-clan clansmen for RTS validation (JSONL when capture on)
func rts_playtest_pack_spawned(clan_name: String, claim_x: float, claim_y: float, nearest_dist: float, source: String, npc_names: Array) -> void:
	var obj: Dictionary = {
		"evt": "rts_playtest_pack_spawned",
		"clan": clan_name,
		"x": claim_x,
		"y": claim_y,
		"nearest_dist": nearest_dist,
		"source": source,
		"clansmen": npc_names,
		"count": npc_names.size()
	}
	_write(obj)

func gather_empty_switch(npc_name: String, resource_type: int, reason: String) -> void:
	_write({"evt": "gather_empty_switch", "npc": npc_name, "resource_type": resource_type, "reason": reason})

# --- Campfire events ---

func campfire_opened(clan_name: String, slot_count: int = -1) -> void:
	var obj: Dictionary = {"evt": "campfire_opened", "clan": clan_name}
	if slot_count >= 0:
		obj["slot_count"] = slot_count
	_write(obj)

func campfire_placed(clan_name: String, x: float = 0.0, y: float = 0.0) -> void:
	_write({"evt": "campfire_placed", "clan": clan_name, "x": x, "y": y})

func campfire_upgraded(clan_name: String) -> void:
	_write({"evt": "campfire_upgraded", "clan": clan_name})

func campfire_despawned(clan_name: String, reason: String = "") -> void:
	_write({"evt": "campfire_despawned", "clan": clan_name, "reason": reason})

func campfire_fire_toggled(clan_name: String, fire_on: bool) -> void:
	_write({"evt": "campfire_fire_toggled", "clan": clan_name, "fire_on": fire_on})

func campfire_building_built(clan_name: String, building_type: int) -> void:
	_write({"evt": "campfire_building_built", "clan": clan_name, "building_type": building_type})

func end_raid_test() -> void:
	"""Call before quit when raid test: write test_run_ended_raid, flush."""
	if not _enabled or not _raid_test:
		return
	_write({"evt": "test_run_ended_raid"})
	if _file and _file.is_open():
		_file.flush()

# --- Periodic snapshot ---

func _process(_delta: float) -> void:
	if not _enabled:
		return
	var now = Time.get_ticks_msec() / 1000.0
	if now - _last_snapshot_time >= _snapshot_interval:
		_last_snapshot_time = now
		_capture_snapshot()

# Matches ClanBrain.StrategicState order (PEACEFUL..RECOVERING) for snapshot labels only
const _BRAIN_STRATEGIC_NAMES: Array = ["PEACEFUL", "DEFENSIVE", "AGGRESSIVE", "RAIDING", "RECOVERING"]


func _capture_snapshot() -> void:
	var tree = get_tree()
	if not tree:
		return
	var npcs = tree.get_nodes_in_group("npcs")
	var in_herd_wildnpc: Array = []
	var herdable_wild: int = 0
	var total_herded_count: int = 0
	var in_combat_count: int = 0
	var ally_combat_violations: int = 0
	var ally_combat_samples: Array = []
	const MAX_ALLY_COMBAT_SAMPLES: int = 12
	var alive_count: int = 0
	# Global FSM distribution (efficiency / idle vs work)
	var state_counts: Dictionary = {}
	# AI fighters only (exclude player character) — caveman vs clansman for tuning
	var ai_caveman_states: Dictionary = {}
	var ai_clansman_states: Dictionary = {}
	var npc_probes: Array = []
	const MAX_NPC_PROBE: int = 64
	const _PROBE_TYPES: Array = ["caveman", "clansman", "woman", "sheep", "goat"]
	# Player is not in group "npcs" — add one row for distance-to-AI analysis
	var pnode: Node = tree.get_first_node_in_group("player")
	if pnode and is_instance_valid(pnode) and not (pnode.has_method("is_dead") and pnode.is_dead()):
		var vp: Vector2 = Vector2.ZERO
		if pnode is CharacterBody2D:
			vp = (pnode as CharacterBody2D).velocity
		var pclan: String = str(pnode.get("clan_name")) if pnode.get("clan_name") != null else ""
		var phc: int = int(pnode.get("herded_count")) if pnode.get("herded_count") != null else 0
		npc_probes.append({
			"name": "Player",
			"type": "player",
			"clan": pclan,
			"state": "-",
			"x": snappedf(pnode.global_position.x, 1),
			"y": snappedf(pnode.global_position.y, 1),
			"v": snappedf(vp.length(), 1),
			"herded_count": phc,
			"is_herded": pnode.get("is_herded") == true,
			"follow_ordered": pnode.get("follow_is_ordered") == true,
			"herder": "",
		})
	for n in npcs:
		if not is_instance_valid(n):
			continue
		var fsm = n.get("fsm")
		var state = ""
		if fsm:
			state = fsm.get_current_state_name() if fsm.has_method("get_current_state_name") else ""
		var is_dead: bool = n.has_method("is_dead") and n.is_dead()
		if not is_dead:
			alive_count += 1
			var st_count: String = state if state != "" else "unknown"
			state_counts[st_count] = state_counts.get(st_count, 0) + 1
			var nt_f: String = str(n.get("npc_type")) if n.get("npc_type") != null else ""
			var is_player_char: bool = n.is_in_group("player")
			if not is_player_char:
				if nt_f == "caveman":
					ai_caveman_states[st_count] = ai_caveman_states.get(st_count, 0) + 1
				elif nt_f == "clansman":
					ai_clansman_states[st_count] = ai_clansman_states.get(st_count, 0) + 1
		if state == "combat" and not is_dead:
			in_combat_count += 1
			var ct = n.get("combat_target")
			if ct != null and is_instance_valid(ct) and CombatAllyCheck.is_ally(n, ct):
				ally_combat_violations += 1
				if ally_combat_samples.size() < MAX_ALLY_COMBAT_SAMPLES:
					var tnm: String = "?"
					if ct is NPCBase:
						tnm = (ct as NPCBase).npc_name
					elif ct.is_in_group("player"):
						tnm = "Player"
					elif ct.get("npc_name") != null:
						tnm = str(ct.get("npc_name"))
					ally_combat_samples.append({
						"attacker": str(n.get("npc_name")) if n.get("npc_name") != null else str(n.name),
						"target": tnm,
						"attacker_clan": str(n.get("clan_name")) if n.get("clan_name") != null else "",
					})
		if state == "herd_wildnpc":
			var hc = n.get("herded_count") as int if n.get("herded_count") != null else 0
			in_herd_wildnpc.append({"npc": n.get("npc_name") if n else "?", "herded_count": hc})
			total_herded_count += hc
		var nt = n.get("npc_type") as String if n.get("npc_type") != null else ""
		if nt in ["woman", "sheep", "goat"]:
			var clan = n.get("clan_name") as String if n.get("clan_name") != null else ""
			if clan == "" and (not n.has_method("is_dead") or not n.is_dead()):
				herdable_wild += 1
		# Periodic world probe: real positions + velocity (unlike ai_clans which uses claim origin)
		if npc_probes.size() < MAX_NPC_PROBE and not is_dead:
			var nt_p: String = str(n.get("npc_type")) if n.get("npc_type") != null else ""
			if n.is_in_group("player"):
				nt_p = "player"
			elif not (nt_p in _PROBE_TYPES):
				nt_p = ""
			if nt_p != "":
				var vel_len: float = 0.0
				if n is CharacterBody2D:
					vel_len = (n as CharacterBody2D).velocity.length()
				var hname: String = ""
				var hr = n.get("herder")
				if hr != null and is_instance_valid(hr):
					var nnh = hr.get("npc_name")
					hname = str(nnh) if nnh != null else str(hr.name)
				var cnm: String = str(n.get("clan_name")) if n.get("clan_name") != null else ""
				npc_probes.append({
					"name": str(n.get("npc_name")) if n.get("npc_name") != null else str(n.name),
					"type": nt_p,
					"clan": cnm,
					"state": state if state != "" else "?",
					"x": snappedf(n.global_position.x, 1),
					"y": snappedf(n.global_position.y, 1),
					"v": snappedf(vel_len, 1),
					"herded_count": int(n.get("herded_count")) if n.get("herded_count") != null else 0,
					"is_herded": n.get("is_herded") == true,
					"follow_ordered": n.get("follow_is_ordered") == true,
					"herder": hname,
				})
	var snap: Dictionary = {
		"evt": "snapshot",
		"fps": Engine.get_frames_per_second(),
		"in_herd_wildnpc": in_herd_wildnpc.size(),
		"herders": in_herd_wildnpc,
		"herdable_wild": herdable_wild,
		"total_herded_count": total_herded_count,
		"state_counts": state_counts,
		"ai_caveman_states": ai_caveman_states,
		"ai_clansman_states": ai_clansman_states,
		"alive_npcs": alive_count
	}
	if _agro_combat_test or _raid_test:
		snap["in_combat"] = in_combat_count
	snap["ally_combat_violations"] = ally_combat_violations
	if not ally_combat_samples.is_empty():
		snap["ally_combat_samples"] = ally_combat_samples
	# Per AI land claim: leader FSM, herd size, clan population, ClanBrain strategic state
	var ai_clans: Array = []
	var claims = tree.get_nodes_in_group("land_claims")
	for lc in claims:
		if not is_instance_valid(lc):
			continue
		if lc.get("player_owned") == true:
			continue
		var claim_owner = lc.get("owner_npc")
		if not claim_owner or not is_instance_valid(claim_owner):
			continue
		var ntype = str(claim_owner.get("npc_type")) if claim_owner.get("npc_type") != null else ""
		if ntype != "caveman" and ntype != "clansman":
			continue
		var clan: String = str(lc.get("clan_name")) if lc.get("clan_name") != null else ""
		var fsm_o = claim_owner.get("fsm")
		var leader_state: String = fsm_o.get_current_state_name() if (fsm_o and fsm_o.has_method("get_current_state_name")) else ""
		var hc_leader = int(claim_owner.get("herded_count")) if claim_owner.get("herded_count") != null else 0
		var pop: int = 0
		for m in npcs:
			if not is_instance_valid(m) or (m.has_method("is_dead") and m.is_dead()):
				continue
			if str(m.get("clan_name")) == clan:
				pop += 1
		var entry: Dictionary = {
			"clan": clan,
			"leader": str(claim_owner.get("npc_name")) if claim_owner.get("npc_name") != null else str(claim_owner.name),
			"leader_type": ntype,
			"state": leader_state,
			"herded_count": hc_leader,
			"clan_pop": pop,
			"x": snappedf(lc.global_position.x, 1),
			"y": snappedf(lc.global_position.y, 1)
		}
		var cb = lc.get("clan_brain")
		if cb and cb.has_method("get_strategic_state"):
			var ss = cb.get_strategic_state()
			var si: int = int(ss)
			if si >= 0 and si < _BRAIN_STRATEGIC_NAMES.size():
				entry["brain"] = _BRAIN_STRATEGIC_NAMES[si]
			else:
				entry["brain"] = str(ss)
		ai_clans.append(entry)
	snap["ai_clans"] = ai_clans
	_write(snap)
	if not npc_probes.is_empty():
		_write({"evt": "npc_world_probe", "count": npc_probes.size(), "npcs": npc_probes})

func emit_combat_ended_for_all_in_combat() -> void:
	"""Emit combat_ended for each NPC still in combat (fixes dangling combats invariant at test end)."""
	var tree = get_tree()
	if not tree:
		return
	var npcs = tree.get_nodes_in_group("npcs")
	for n in npcs:
		if not is_instance_valid(n):
			continue
		if n.has_method("is_dead") and n.is_dead():
			continue
		var fsm = n.get("fsm")
		var state = ""
		if fsm and fsm.has_method("get_current_state_name"):
			state = fsm.get_current_state_name()
		var target = n.get("combat_target")
		var in_combat: bool = (state == "combat") or (target != null and is_instance_valid(target))
		if in_combat:
			var npc_name: String = n.get("npc_name") if n.get("npc_name") != null else str(n.name)
			var target_name: String = "unknown"
			if target and is_instance_valid(target):
				target_name = target.get("npc_name") if target.get("npc_name") != null else str(target.name)
			combat_ended(npc_name, target_name)

func end_agro_combat_test() -> void:
	"""Call before quit: emit combat_ended for dangling combats, test_run_ended, test_failed_no_engagements if zero combats, flush."""
	if not _enabled or not _agro_combat_test:
		return
	emit_combat_ended_for_all_in_combat()
	_write({"evt": "test_run_ended", "combat_started": _combat_started_count, "friendly_fire_hits": _friendly_fire_instrumented_hits})
	if _friendly_fire_instrumented_hits > 0:
		_write({"evt": "test_failed_friendly_fire", "combat_hits_vs_ally": _friendly_fire_instrumented_hits})
	if _combat_started_count == 0:
		_write({"evt": "test_failed_no_engagements"})
	if _file and _file.is_open():
		_file.flush()
