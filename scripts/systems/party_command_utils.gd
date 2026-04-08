extends Object
class_name PartyCommandUtils

## Command context for NPC-led parties — same dict shape as main._build_command_context.
## Keep STANCE_CONFIG in sync with main.gd STANCE_CONFIG.

const STANCE_CONFIG := {
	"FOLLOW": {"aggro_threshold": 0.0, "chase_dist": 0.0, "speed_mult": 1.0},
	"GUARD": {"aggro_threshold": 70.0, "chase_dist": 150.0, "speed_mult": 0.75},
	"ATTACK": {"aggro_threshold": 100.0, "chase_dist": 300.0, "speed_mult": 0.85},
}


static func build_command_context(leader: Node, follower: Node) -> Dictionary:
	var mode: String = "FOLLOW"
	if follower and follower.has_method("get_follow_mode_string"):
		mode = follower.get_follow_mode_string()
	var cfg: Dictionary = STANCE_CONFIG.get(mode, STANCE_CONFIG["FOLLOW"])
	var commander_id: int = -1
	if leader and is_instance_valid(leader):
		if EntityRegistry and EntityRegistry.get_network_id(leader) > 0:
			commander_id = EntityRegistry.get_network_id(leader)
		else:
			commander_id = leader.get_instance_id()
	var is_hostile: bool = false
	if leader and leader.get("is_hostile") != null:
		is_hostile = leader.get("is_hostile") as bool
	return {
		"commander_id": commander_id,
		"mode": mode,
		"stance_aggro_threshold": cfg.get("aggro_threshold", 0.0),
		"stance_chase_dist": cfg.get("chase_dist", 0.0),
		"is_hostile": is_hostile,
		"issued_at_time": Time.get_ticks_msec() / 1000.0,
	}


static func apply_context_to_follower(leader: Node, follower: Node) -> void:
	if not follower or not is_instance_valid(follower):
		return
	var built: Dictionary = build_command_context(leader, follower)
	var ctx: Dictionary = follower.get("command_context") if follower.get("command_context") != null else {}
	ctx = ctx.duplicate()
	for k in built:
		ctx[k] = built[k]
	follower.set("command_context", ctx)
	if "command_context" in follower:
		follower.command_context = ctx
	var hostile: bool = built.get("is_hostile", false) as bool
	follower.set("is_hostile", hostile)
	if hostile and "agro_meter" in follower:
		follower.set("agro_meter", 70.0)
		follower.agro_meter = 70.0


static func set_follower_mode_string(follower: Node, mode: String) -> void:
	if follower and follower.has_method("set_follow_mode_from_string"):
		follower.set_follow_mode_from_string(mode)


static func same_clan_warband_herder(herder: Node, follower: Node) -> bool:
	if not herder or not follower or not is_instance_valid(herder) or not is_instance_valid(follower):
		return false
	var ht: String = str(herder.get("npc_type")) if herder.get("npc_type") != null else ""
	if ht != "caveman" and ht != "clansman":
		return false
	var fc: String = follower.get_clan_name() if follower.has_method("get_clan_name") else str(follower.get("clan_name"))
	var hc: String = herder.get_clan_name() if herder.has_method("get_clan_name") else str(herder.get("clan_name"))
	return fc != "" and fc == hc
