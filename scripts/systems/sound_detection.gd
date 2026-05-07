extends RefCounted

## Short-lived sound events for prey hearing (footsteps, combat, horn). Throttled emitters + cheap polling.

const MAX_EVENTS := 48
const EVENT_MAX_AGE_SEC := 1.2

static var _events: Array[Dictionary] = []

static func _now() -> float:
	return Time.get_ticks_msec() / 1000.0


static func _prune() -> void:
	var t: float = _now()
	while _events.size() > MAX_EVENTS:
		_events.pop_front()
	var kept: Array[Dictionary] = []
	for ev in _events:
		if t - float(ev.get("t", 0.0)) <= EVENT_MAX_AGE_SEC:
			kept.append(ev)
	_events = kept


## Register a loudness event at world position (volume is linear “source strength”, not dB).
static func register_sound(world_position: Vector2, volume: float, sound_kind: StringName = &"generic") -> void:
	if volume <= 0.001:
		return
	_prune()
	_events.append({"t": _now(), "pos": world_position, "vol": volume, "kind": sound_kind})


## Max heard intensity at listener: vol / distance (with floor on distance).
static func heard_intensity_at(listener_position: Vector2) -> float:
	_prune()
	var best: float = 0.0
	var t: float = _now()
	for ev in _events:
		if t - float(ev.get("t", 0.0)) > EVENT_MAX_AGE_SEC:
			continue
		var pos: Vector2 = ev.get("pos", Vector2.ZERO) as Vector2
		var vol: float = float(ev.get("vol", 0.0))
		var dist: float = maxf(8.0, listener_position.distance_to(pos))
		var hi: float = vol / dist
		if hi > best:
			best = hi
	return best


static func maybe_emit_footstep(npc: CharacterBody2D) -> void:
	if npc == null or not is_instance_valid(npc):
		return
	if npc.has_meta("is_hidden") and npc.get_meta("is_hidden") == true:
		return
	var nt: String = str(npc.get("npc_type")) if npc.get("npc_type") != null else ""
	var is_pc: bool = npc.is_in_group("player")
	if nt != "caveman" and nt != "clansman" and not is_pc:
		return
	var spd: float = npc.velocity.length()
	var walk_thr: float = 14.0
	var run_thr: float = 85.0
	if spd < walk_thr:
		return
	var walk_iv: float = NPCConfig.sound_footstep_walk_interval if NPCConfig else 0.3
	var run_iv: float = NPCConfig.sound_footstep_run_interval if NPCConfig else 0.15
	var now: float = _now()
	var last: float = float(npc.get_meta("_sound_last_footstep", -999.0))
	var iv: float = run_iv if spd >= run_thr else walk_iv
	if now - last < iv:
		return
	var vol_walk: float = NPCConfig.sound_footstep_walk_volume if NPCConfig else 30.0
	var vol_run: float = NPCConfig.sound_footstep_run_volume if NPCConfig else 60.0
	var vol_stalk: float = NPCConfig.sound_footstep_stalk_volume if NPCConfig else 15.0
	var vol: float = vol_run if spd >= run_thr else vol_walk
	var stalking: bool = false
	if nt == "caveman" or nt == "clansman":
		if npc.has_method("get_follow_mode_string") and npc.get_follow_mode_string() == "STALK":
			stalking = true
	if npc.get_meta("is_stalking", false) == true:
		stalking = true
	if stalking:
		vol = vol_stalk
	npc.set_meta("_sound_last_footstep", now)
	register_sound(npc.global_position, vol, &"footstep")


static func emit_attack_swing(origin: Node2D) -> void:
	if origin == null or not is_instance_valid(origin):
		return
	var vol: float = NPCConfig.sound_attack_swing_volume if NPCConfig else 100.0
	register_sound(origin.global_position, vol, &"attack")


## Reserved for future spear-throw gameplay. Disabled until throw art/VFX and ranged pipeline exist.
static func emit_spear_throw(origin: Node2D) -> void:
	const SPEAR_THROW_ENABLED: bool = false
	if not SPEAR_THROW_ENABLED:
		return
	if not origin or not is_instance_valid(origin):
		return
	var vol: float = NPCConfig.sound_spear_throw_volume if NPCConfig else 120.0
	register_sound(origin.global_position, vol, &"throw")


static func emit_horn(origin: Node2D) -> void:
	if origin == null or not is_instance_valid(origin):
		return
	var vol: float = NPCConfig.sound_horn_volume if NPCConfig else 300.0
	register_sound(origin.global_position, vol, &"horn")
