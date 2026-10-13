extends RefCounted
class_name RaidMotivePicker

## Pure raid motive + goal selection (no scene). See bible/raid.md § Next raid.

const WHY_BLOOD := "blood"
const WHY_THEFT := "theft"
const WHY_FOOD := "food"
const WHY_THIN := "thin"
const WHY_RESTLESS := "restless"

const GOAL_FOOD := "food"
const GOAL_TAKE_WOMEN := "take_women"
const GOAL_TAKE_ANIMALS := "take_animals"
const GOAL_WEAKEN := "weaken"

const KIND_KILLED := "killed"
const KIND_STOLE := "stole"

const DEFAULT_TUNE := {
	"raid_hunger_days": 1.0,
	"raid_grudge_sec": 600.0,
	"raid_restless_quiet_sec": 300.0,
	"raid_restless_quiet_warlike_sec": 120.0,
	"raid_restless_morale": 70.0,
	"raid_restless_morale_warlike": 50.0,
	"raid_restless_pantry_days": 3.0,
	"raid_thin_morale_min": 50.0,
	"raid_thin_enemy_max_fraction": 0.5,
	"raid_motive_min_morale": 30.0,
	"raid_take_women_count": 1,
	"raid_weaken_kills": 2,
}


static func tune_value(tune: Dictionary, key: String) -> Variant:
	if tune.has(key):
		return tune[key]
	return DEFAULT_TUNE.get(key, 0)


static func skip_signature(reason: String, detail: String) -> String:
	if reason == "cooldown":
		return reason
	return reason + "|" + detail


static func cooldown_blocks(now: float, last_raid_end: float, cooldown_sec: float) -> bool:
	return now - last_raid_end < cooldown_sec


static func pick(ctx: Dictionary) -> Dictionary:
	## Returns {ok:true, why, goal, target} or {ok:false, skip, detail}.
	var living: int = int(ctx.get("living_fighters", 0))
	if living < 6:
		return {"ok": false, "skip": "too_few", "detail": "living=%d need=6" % living}
	if bool(ctx.get("alert", false)):
		return {"ok": false, "skip": "alert", "detail": str(ctx.get("alert_detail", ""))}
	if bool(ctx.get("hunting", false)):
		return {"ok": false, "skip": "hunting", "detail": ""}
	if not bool(ctx.get("cooldown_ok", true)):
		return {"ok": false, "skip": "cooldown", "detail": ""}
	if bool(ctx.get("trade_blocked", false)):
		return {"ok": false, "skip": "trade", "detail": ""}

	var neighbors: Array = ctx.get("neighbors", []) as Array
	if neighbors.is_empty():
		return {"ok": false, "skip": "no_target", "detail": "neighbors=0"}

	var legal: Array = []
	for n in neighbors:
		if n is Dictionary:
			var their: int = int(n.get("their_fighters", 999))
			if their <= living:
				legal.append(n)

	if legal.is_empty():
		return {"ok": false, "skip": "outnumbered", "detail": "living=%d" % living}

	var tune: Dictionary = ctx.get("tune", {}) as Dictionary
	var morale: float = float(ctx.get("morale", 50.0))
	var motive_min: float = float(tune_value(tune, "raid_motive_min_morale"))
	var temper: float = float(ctx.get("temper", 0.0))
	var now: float = float(ctx.get("now", 0.0))
	var food_days: float = float(ctx.get("food_days", 99.0))
	var wrongs: Array = ctx.get("wrongs", []) as Array
	var last_quiet: float = float(ctx.get("last_quiet_at", 0.0))
	var grudge_sec: float = float(tune_value(tune, "raid_grudge_sec"))

	# 1 blood
	if morale >= motive_min:
		var blood: Dictionary = _pick_grudge_target(wrongs, KIND_KILLED, grudge_sec, now, living, neighbors)
		if blood.get("ok", false):
			return {
				"ok": true,
				"why": WHY_BLOOD,
				"goal": GOAL_WEAKEN,
				"target": blood.get("target"),
				"target_clan": blood.get("target_clan", ""),
			}

	# 2 theft
	if morale >= motive_min:
		var theft: Dictionary = _pick_grudge_target(wrongs, KIND_STOLE, grudge_sec, now, living, neighbors)
		if theft.get("ok", false):
			var g: String = str(theft.get("goal", GOAL_TAKE_WOMEN))
			var trow: Dictionary = _neighbor_row_for_clan(neighbors, str(theft.get("target_clan", "")))
			if not _neighbor_has_goal_prize(trow, g):
				return {"ok": false, "skip": "no_prize", "detail": "theft goal=%s" % g}
			return {
				"ok": true,
				"why": WHY_THEFT,
				"goal": g,
				"target": theft.get("target"),
				"target_clan": theft.get("target_clan", ""),
			}

	# 3 food
	if morale >= motive_min:
		var hunger: float = float(tune_value(tune, "raid_hunger_days"))
		if food_days < hunger:
			var food_n: Dictionary = _closest_with_prize(legal, GOAL_FOOD)
			if food_n.is_empty():
				return {"ok": false, "skip": "no_prize", "detail": "food"}
			return {
				"ok": true,
				"why": WHY_FOOD,
				"goal": GOAL_FOOD,
				"target": food_n.get("claim"),
				"target_clan": str(food_n.get("clan", "")),
			}

	# 4 thin (optional by temper)
	if morale >= float(tune_value(tune, "raid_thin_morale_min")) and not _temper_peaceful(temper):
		var our_need: String = str(ctx.get("our_need", "food"))
		var thin_hit: Dictionary = _pick_thin_target(legal, living, tune, our_need)
		if thin_hit.get("ok", false):
			return {
				"ok": true,
				"why": WHY_THIN,
				"goal": thin_hit.get("goal", GOAL_FOOD),
				"target": thin_hit.get("target"),
				"target_clan": thin_hit.get("target_clan", ""),
			}
		if bool(thin_hit.get("had_thin_neighbor", false)) and str(thin_hit.get("goal", "")) == "":
			return {"ok": false, "skip": "no_prize", "detail": "thin need=%s" % our_need}

	# 5 restless
	if not _temper_peaceful(temper):
		var restless: Dictionary = _restless_ok(food_days, morale, temper, last_quiet, now, tune)
		if restless.get("ok", false):
			var closest_r: Dictionary = _closest_legal(legal)
			if not closest_r.is_empty():
				return {
					"ok": true,
					"why": WHY_RESTLESS,
					"goal": GOAL_WEAKEN,
					"target": closest_r.get("claim"),
					"target_clan": str(closest_r.get("clan", "")),
				}

	return {"ok": false, "skip": "no_motive", "detail": ""}


static func _temper_peaceful(temper: float) -> bool:
	return temper <= -0.5


static func _temper_warlike(temper: float) -> bool:
	return temper >= 0.5


static func _pick_grudge_target(
	wrongs: Array,
	kind: String,
	grudge_sec: float,
	now: float,
	living: int,
	neighbors: Array
) -> Dictionary:
	var best_at: float = -INF
	var best_clan: String = ""
	var best_goal: String = GOAL_TAKE_WOMEN
	for w in wrongs:
		if w is not Dictionary:
			continue
		if str(w.get("kind", "")) != kind:
			continue
		var at: float = float(w.get("at", 0.0))
		if now - at > grudge_sec:
			continue
		var enemy: String = str(w.get("enemy", ""))
		if enemy == "":
			continue
		if at > best_at:
			best_at = at
			best_clan = enemy
			if w.has("goal"):
				best_goal = str(w.get("goal"))
			elif kind == KIND_STOLE:
				best_goal = str(w.get("stole_goal", GOAL_TAKE_WOMEN))
	if best_clan == "":
		return {"ok": false}
	for n in neighbors:
		if n is not Dictionary:
			continue
		if str(n.get("clan", "")) != best_clan:
			continue
		var their: int = int(n.get("their_fighters", 999))
		if their > living:
			return {"ok": false}
		return {"ok": true, "target": n.get("claim"), "target_clan": best_clan, "goal": best_goal}
	return {"ok": false}


static func _closest_legal(legal: Array) -> Dictionary:
	var best: Dictionary = {}
	var best_d: float = INF
	for n in legal:
		if n is not Dictionary:
			continue
		var d: float = float(n.get("distance", INF))
		if d < best_d:
			best_d = d
			best = n
	return best


static func _neighbor_row_for_clan(neighbors: Array, clan: String) -> Dictionary:
	for n in neighbors:
		if n is Dictionary and str(n.get("clan", "")) == clan:
			return n
	return {}


static func _neighbor_has_goal_prize(row: Dictionary, goal: String) -> bool:
	if row is not Dictionary:
		return false
	match goal:
		GOAL_TAKE_WOMEN:
			return bool(row.get("has_woman", false))
		GOAL_TAKE_ANIMALS:
			return bool(row.get("has_animal", false))
		GOAL_FOOD:
			return bool(row.get("has_food", false))
		_:
			return true


static func _closest_with_prize(legal: Array, goal: String) -> Dictionary:
	var best: Dictionary = {}
	var best_d: float = INF
	for n in legal:
		if n is not Dictionary:
			continue
		if not _neighbor_has_goal_prize(n, goal):
			continue
		var d: float = float(n.get("distance", INF))
		if d < best_d:
			best_d = d
			best = n
	return best


static func _pick_thin_target(legal: Array, living: int, tune: Dictionary, our_need: String) -> Dictionary:
	var frac: float = float(tune_value(tune, "raid_thin_enemy_max_fraction"))
	var best: Dictionary = {}
	var best_their: int = 999
	var had_thin: bool = false
	for n in legal:
		if n is not Dictionary:
			continue
		var their: int = int(n.get("their_fighters", 999))
		if float(their) > float(living) * frac:
			continue
		had_thin = true
		var goal: String = resolve_thin_goal_for_need(n, our_need)
		if goal == "":
			continue
		if their < best_their:
			best_their = their
			best = n
	if best.is_empty():
		return {"ok": false, "had_thin_neighbor": had_thin, "goal": ""}
	var goal_best: String = resolve_thin_goal_for_need(best, our_need)
	if goal_best == "":
		return {"ok": false, "had_thin_neighbor": had_thin, "goal": ""}
	return {
		"ok": true,
		"target": best.get("claim"),
		"target_clan": str(best.get("clan", "")),
		"goal": goal_best,
		"had_thin_neighbor": had_thin,
	}


static func resolve_thin_goal_for_need(neighbor: Dictionary, our_need: String) -> String:
	match our_need:
		"women":
			if bool(neighbor.get("has_woman", false)):
				return GOAL_TAKE_WOMEN
			if bool(neighbor.get("has_animal", false)):
				return GOAL_TAKE_ANIMALS
			if bool(neighbor.get("has_food", false)):
				return GOAL_FOOD
		"animals":
			if bool(neighbor.get("has_animal", false)):
				return GOAL_TAKE_ANIMALS
			if bool(neighbor.get("has_food", false)):
				return GOAL_FOOD
		_:
			if bool(neighbor.get("has_food", false)):
				return GOAL_FOOD
	return ""


static func resolve_thin_goal(neighbor: Dictionary, ctx: Dictionary) -> String:
	return resolve_thin_goal_for_need(neighbor, str(ctx.get("our_need", "food")))


static func _restless_ok(
	food_days: float,
	morale: float,
	temper: float,
	last_quiet: float,
	now: float,
	tune: Dictionary
) -> Dictionary:
	var pantry_need: float = float(tune_value(tune, "raid_restless_pantry_days"))
	if food_days < pantry_need:
		return {"ok": false}
	var morale_need: float = float(tune_value(tune, "raid_restless_morale"))
	var quiet_need: float = float(tune_value(tune, "raid_restless_quiet_sec"))
	if _temper_warlike(temper):
		morale_need = float(tune_value(tune, "raid_restless_morale_warlike"))
		quiet_need = float(tune_value(tune, "raid_restless_quiet_warlike_sec"))
	if morale < morale_need:
		return {"ok": false}
	if now - last_quiet < quiet_need:
		return {"ok": false}
	return {"ok": true}


## --- Goal completion helpers (unit tests) ---

static func is_weaken_goal_done(enemy_kills: int, tune: Dictionary = {}) -> bool:
	var need: int = int(tune_value(tune, "raid_weaken_kills"))
	return enemy_kills >= need


static func is_food_goal_done(
	arrived: bool,
	all_in_range_bags_full: bool,
	enemy_store_has_food: bool
) -> bool:
	if not arrived:
		return false
	if all_in_range_bags_full:
		return true
	return not enemy_store_has_food


static func is_capture_goal_done(captures: int, goal: String, tune: Dictionary = {}) -> bool:
	if goal == GOAL_TAKE_WOMEN:
		return captures >= int(tune_value(tune, "raid_take_women_count"))
	if goal == GOAL_TAKE_ANIMALS:
		return captures >= 1
	return false


static func evaluate_capture_prizes(states: Array) -> Dictionary:
	var pending: int = 0
	var joined: int = 0
	for entry in states:
		if entry is not Dictionary:
			continue
		match str(entry.get("state", "")):
			"pending":
				pending += 1
			"joined":
				joined += 1
	if pending > 0:
		return {"done": false, "failed": false}
	if joined > 0:
		return {"done": true, "failed": false}
	return {"done": false, "failed": true}


static func apply_prize_state(states: Array, prize_id: int, new_state: String, why: String = "") -> Dictionary:
	var out: Array = []
	var events: Array = []
	for entry in states:
		if entry is not Dictionary:
			continue
		var e: Dictionary = entry.duplicate()
		if int(e.get("prize_id", 0)) == prize_id and str(e.get("state", "")) != new_state:
			e["state"] = new_state
			events.append({"prize_id": prize_id, "state": new_state, "why": why, "name": str(e.get("name", ""))})
		out.append(e)
	return {"states": out, "events": events}


static func npc_is_sheltered(npc: Node) -> bool:
	if npc == null:
		return false
	var tree: SceneTree = npc.get_tree() if npc.is_inside_tree() else null
	if tree:
		var occ = tree.root.get_node_or_null("OccupationSystem")
		if occ and occ.has_method("get_workplace"):
			var wp: Node = occ.get_workplace(npc)
			if wp != null and is_instance_valid(wp):
				return true
	if npc.get("assigned_building") != null:
		var b: Variant = npc.get("assigned_building")
		if b is Node and is_instance_valid(b):
			return true
	if npc.has_meta("assigned_building"):
		return true
	return false


static func prize_raidable(npc: Node, building_must_be_gone: bool, building_still_up: bool) -> bool:
	if npc == null:
		return false
	if building_must_be_gone and building_still_up:
		return false
	if building_still_up and npc_is_sheltered(npc):
		return false
	return true
