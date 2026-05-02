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
	"HIDE": 0.15,
	"STALK": 0.5,
	"ARC": 0.85,
	"AMBUSH": 0.05,
}


## Soft dead zone on **world X** (east/west): tiny east/west strafes do not drag the formation anchor;
## world Y (north/south) tracks the leader immediately.
static func apply_world_anchor_deadzone_ew(leader: Node2D) -> Vector2:
	if not leader or not is_instance_valid(leader):
		return Vector2.ZERO
	var cur: Vector2 = leader.global_position
	var dz: float = float(RTS_CONFIG.get("formation_world_deadzone_x_px", 28.0))
	if not leader.has_meta("formation_anchor_world"):
		leader.set_meta("formation_anchor_world", cur)
	var anchor: Vector2 = leader.get_meta("formation_anchor_world") as Vector2
	var err_x: float = cur.x - anchor.x
	anchor.x += err_x - clamp(err_x, -dz, dz)
	anchor.y = cur.y
	leader.set_meta("formation_anchor_world", anchor)
	return anchor


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
## **FOLLOW**: loose rear arc behind the leader (facing-relative; see rts.md §4.1). **ATTACK**: line ahead.
## **GUARD**: ring around leader.
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
		elif mode == "ARC":
			var attack_forward_px: float = float(RTS_CONFIG.get("attack_formation_forward_px", 120.0))
			var arc_deg: float = float(RTS_CONFIG.get("arc_formation_span_deg", 120.0))
			var half_arc: float = deg_to_rad(arc_deg) * 0.5
			var t_slot: float = 0.5 if count <= 1 else float(i) / float(count - 1)
			var ang: float = lerp(-half_arc, half_arc, t_slot)
			var forward_a: Vector2 = facing
			var slot_pos_arc: Vector2 = leader_pos + forward_a * attack_forward_px
			slot_pos_arc += forward_a.rotated(ang) * attack_forward_px * 0.35
			var steer_arc: Vector2 = slot_pos_arc + facing * 40.0
			slots[fid] = {
				"slot_pos": slot_pos_arc,
				"steer_target": steer_arc,
				"slot_index": i,
				"count": count,
				"facing": facing,
				"player_stopped": leader_stopped,
				"mode": mode,
			}
			continue
		elif mode == "ATTACK":
			# Line in front of leader, perpendicular to facing (not world-X-only; see rts.md §4.1).
			var attack_forward_px: float = float(RTS_CONFIG.get("attack_formation_forward_px", 120.0))
			var line_spacing: float = float(RTS_CONFIG.get("attack_formation_lateral_spacing_px", 60.0))
			var line_offset: float = (float(i) - float(count - 1) / 2.0) * line_spacing
			var forward_a: Vector2 = facing
			var right_a: Vector2 = Vector2(-facing.y, facing.x)
			var slot_pos_atk: Vector2 = leader_pos + forward_a * attack_forward_px + right_a * line_offset
			var steer_target_atk: Vector2 = slot_pos_atk + facing * 40.0
			slots[fid] = {
				"slot_pos": slot_pos_atk,
				"steer_target": steer_target_atk,
				"slot_index": i,
				"count": count,
				"facing": facing,
				"player_stopped": leader_stopped,
				"mode": mode,
			}
			continue
		else:
			var follow_dist: float = float(RTS_CONFIG.get("follow_formation_ideal_dist_px", 130.0))
			var arc_half: float = float(RTS_CONFIG.get("follow_formation_arc_half_rad", PI / 3.0))
			if mode == "STALK":
				arc_half = float(RTS_CONFIG.get("stalk_formation_arc_half_rad", PI * 0.5))
				follow_dist *= float(RTS_CONFIG.get("stalk_formation_dist_mult", 1.08))
			spread_angle = PI - arc_half + (2.0 * arc_half * float(i) / max(1, count - 1)) if count > 1 else PI
			formation_dir = facing.rotated(spread_angle)
			ideal_dist = follow_dist
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
		if mode_str == "HIDE" or mode_str == "AMBUSH":
			continue
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
		if mode_str == "HIDE" or mode_str == "AMBUSH":
			continue
		var m: float = float(STANCE_SPEED_MULT.get(mode_str, STANCE_SPEED_MULT["FOLLOW"]))
		if m < lowest:
			lowest = m
	return lowest
