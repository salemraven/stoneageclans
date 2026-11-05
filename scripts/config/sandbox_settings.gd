extends Node
## Sandbox difficulty. AI productivity is the only player-facing pace knob.
## Saved in user://sandbox_settings.cfg. Pace arena always uses 1.0.

const SAVE_PATH := "user://sandbox_settings.cfg"
const MIN_SCALE := 0.5
const MAX_SCALE := 2.0
const DEFAULT_SCALE := 1.0

var _scale: float = DEFAULT_SCALE


func _ready() -> void:
	_load()


func ai_productivity() -> float:
	var debug := get_node_or_null("/root/DebugConfig")
	if debug != null and bool(debug.get("enable_pace_arena")):
		return DEFAULT_SCALE
	return _scale


func set_ai_productivity(value: float) -> void:
	_scale = clampf(snappedf(value, 0.25), MIN_SCALE, MAX_SCALE)
	_save()


func scale_ai_time(is_player_camp: bool, delta: float) -> float:
	if is_player_camp:
		return delta
	return delta * ai_productivity()


func scale_ai_count(base: int, fighters: int) -> int:
	if fighters <= 0 or base <= 0:
		return 0
	var scaled := int(round(float(base) * ai_productivity()))
	return clampi(scaled, 1, fighters)


func npc_in_player_camp(npc: Node) -> bool:
	if npc == null or not is_instance_valid(npc):
		return false
	if npc.is_in_group("player"):
		return true
	var clan := ""
	if npc.get("clan_name") != null:
		clan = str(npc.get("clan_name"))
	if clan.is_empty():
		return false
	var tree := npc.get_tree()
	if tree == null:
		return false
	for claim in tree.get_nodes_in_group("land_claims"):
		if claim == null or not is_instance_valid(claim):
			continue
		var claim_clan := ""
		if claim.get("clan_name") != null:
			claim_clan = str(claim.get("clan_name"))
		if claim_clan == clan:
			return claim.get("player_owned") == true
	return false


func pace_label(value: float) -> String:
	if value < 0.9:
		return "Easier"
	if value > 1.1:
		return "Harder"
	return "Normal"


func _load() -> void:
	var cf := ConfigFile.new()
	if cf.load(SAVE_PATH) != OK:
		_scale = DEFAULT_SCALE
		return
	_scale = clampf(float(cf.get_value("sandbox", "ai_productivity", DEFAULT_SCALE)), MIN_SCALE, MAX_SCALE)


func _save() -> void:
	var cf := ConfigFile.new()
	cf.set_value("sandbox", "ai_productivity", _scale)
	cf.save(SAVE_PATH)
