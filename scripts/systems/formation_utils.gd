extends Object
class_name FormationUtils

## Shared formation slot math for player-led and NPC-led parties.
## Keep slot geometry in sync with main.gd STANCE_CONFIG / RTS_CONFIG consumers.

const RTS_CONFIG := preload("res://scripts/config/rts_formation_config.gd").RTS_CONFIG

## Speed multipliers — keep in sync with main.gd STANCE_CONFIG speed_mult values.
const STANCE_SPEED_MULT := {
	"FOLLOW": 1.0,
	"GUARD": 0.75,
	"ATTACK": 0.85,
}


static func get_leader_facing(leader: Node2D) -> Vector2:
	if not leader or not is_instance_valid(leader):
		return Vector2(0, 1)
	var fv: Vector2 = leader.get_meta("formation_velocity", Vector2.ZERO) as Vector2
	if fv.length_squared() >= 1.0:
		return fv.normalized()
	var lf = leader.get("last_facing")
	if lf is Vector2 and (lf as Vector2).length_squared() > 0.01:
		return (lf as Vector2).normalized()
	var sa = leader.get("steering_agent")
	if sa:
		var lp: Vector2 = leader.global_position
		var tp: Vector2 = sa.target_position
		var to_t: Vector2 = tp - lp
		if to_t.length_squared() > 100.0:
			return to_t.normalized()
	return Vector2(0, 1)


static func is_leader_stopped(leader: Node2D) -> bool:
	if not leader or not is_instance_valid(leader):
		return true
	var fv: Vector2 = leader.get_meta("formation_velocity", Vector2.ZERO) as Vector2
	return fv.length() < 1.0


## follower_nodes: ordered list (same order as player follower cache for player parties).
static func compute_formation_slots(
	leader_pos: Vector2,
	facing: Vector2,
	leader_stopped: bool,
	follower_nodes: Array
) -> Dictionary:
	var slots: Dictionary = {}
	var count: int = follower_nodes.size()
	if count == 0:
		return slots
	if facing.length_squared() < 0.0001:
		facing = Vector2(0, 1)
	else:
		facing = facing.normalized()
	var lookahead: float = RTS_CONFIG.get("formation_lookahead_px", 80.0)
	for i in range(count):
		var fn = follower_nodes[i]
		if not fn or not is_instance_valid(fn):
			continue
		var raw_ctx = fn.get("command_context")
		var ctx: Dictionary = raw_ctx if raw_ctx is Dictionary else {}
		var mode: String = str(ctx.get("mode", "FOLLOW"))
		var ideal_dist: float
		var spread_angle: float
		var formation_dir: Vector2
		var fid: int = fn.get_instance_id()
		if mode == "GUARD":
			ideal_dist = 82.5
			spread_angle = (TAU * i) / max(1, count) + PI if count > 1 else PI
			formation_dir = facing.rotated(spread_angle)
		elif mode == "ATTACK":
			ideal_dist = 120.0
			var line_spacing: float = 60.0
			var line_offset: float = (float(i) - float(count - 1) / 2.0) * line_spacing
			var forward: Vector2 = facing
			var right: Vector2 = Vector2(-facing.y, facing.x)
			var slot_pos_attack: Vector2 = leader_pos + forward * ideal_dist + right * line_offset
			var steer_target_attack: Vector2 = slot_pos_attack + facing * 40.0
			slots[fid] = {
				"slot_pos": slot_pos_attack,
				"steer_target": steer_target_attack,
				"slot_index": i,
				"count": count,
				"facing": facing,
				"player_stopped": leader_stopped,
				"mode": mode,
			}
			continue
		else:
			ideal_dist = 130.0
			var arc_half: float = PI / 3.0
			spread_angle = PI - arc_half + (2.0 * arc_half * float(i) / max(1, count - 1)) if count > 1 else PI
			formation_dir = facing.rotated(spread_angle)
		var slot_pos: Vector2 = leader_pos + formation_dir * ideal_dist
		var steer_target: Vector2 = slot_pos
		if not leader_stopped:
			steer_target = slot_pos + facing * lookahead
		slots[fid] = {
			"slot_pos": slot_pos,
			"steer_target": steer_target,
			"slot_index": i,
			"count": count,
			"facing": facing,
			"player_stopped": leader_stopped,
			"mode": mode,
		}
	return slots


static func collect_ordered_warband_followers(leader: Node2D, tree: SceneTree) -> Array:
	var out: Array = []
	if not leader or not tree:
		return out
	for n in tree.get_nodes_in_group("npcs"):
		if not is_instance_valid(n):
			continue
		var t: String = str(n.get("npc_type")) if n.get("npc_type") != null else ""
		if t != "caveman" and t != "clansman":
			continue
		if n.get("herder") != leader:
			continue
		if n.get("follow_is_ordered") != true:
			continue
		if n.get("is_herded") != true:
			continue
		out.append(n)
	out.sort_custom(func(a, b): return a.get_instance_id() < b.get_instance_id())
	return out


## Only the follower with the smallest instance_id publishes (one compute per party per frame).
static func publish_slots_for_npc_leader(leader: Node2D, current_follower: Node2D, tree: SceneTree) -> void:
	if not leader or not current_follower or not tree:
		return
	if leader is CharacterBody2D:
		leader.set_meta("formation_velocity", (leader as CharacterBody2D).velocity)
	else:
		leader.set_meta("formation_velocity", Vector2.ZERO)
	var followers: Array = collect_ordered_warband_followers(leader, tree)
	if followers.is_empty():
		if leader.has_meta("formation_slots"):
			leader.remove_meta("formation_slots")
		return
	if current_follower.get_instance_id() != (followers[0] as Node).get_instance_id():
		return
	var facing: Vector2 = get_leader_facing(leader)
	var stopped: bool = is_leader_stopped(leader)
	var slots: Dictionary = compute_formation_slots(leader.global_position, facing, stopped, followers)
	leader.set_meta("formation_slots", slots)
	update_leader_formation_speed_mult(leader, followers)


static func update_leader_formation_speed_mult(leader: Node2D, ordered_followers: Array) -> void:
	if not leader or not is_instance_valid(leader):
		return
	var lowest: float = 1.0
	for fn in ordered_followers:
		if not is_instance_valid(fn):
			continue
		if fn.get("follow_is_ordered") != true:
			continue
		var mode_str: String = "FOLLOW"
		if fn.has_method("get_follow_mode_string"):
			mode_str = fn.get_follow_mode_string()
		var m: float = float(STANCE_SPEED_MULT.get(mode_str, STANCE_SPEED_MULT["FOLLOW"]))
		if m < lowest:
			lowest = m
	leader.set_meta("formation_speed_mult", lowest)


static func min_speed_mult_for_follower_nodes(follower_nodes: Array) -> float:
	var lowest: float = 1.0
	for fn in follower_nodes:
		if not is_instance_valid(fn):
			continue
		if fn.get("follow_is_ordered") != true:
			continue
		var mode_str: String = "FOLLOW"
		if fn.has_method("get_follow_mode_string"):
			mode_str = fn.get_follow_mode_string()
		var m: float = float(STANCE_SPEED_MULT.get(mode_str, STANCE_SPEED_MULT["FOLLOW"]))
		if m < lowest:
			lowest = m
	return lowest
