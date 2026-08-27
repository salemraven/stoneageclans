extends Node
## Server-owned RNG for global simulation timeline. Bootstrap from WorldGenConfig.world_seed.

var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var debug_log_draws: bool = false

var _draw_count: int = 0
var _world_seed: int = 0


func _ready() -> void:
	call_deferred("_deferred_bootstrap")


func _deferred_bootstrap() -> void:
	bootstrap_from_world_config()


func bootstrap_from_world_config() -> int:
	var wgc: Node = get_node_or_null("/root/WorldGenConfig")
	if wgc == null:
		return _world_seed
	var seed_val: int = int(wgc.get("world_seed"))
	if seed_val == 0:
		var bootstrap := RandomNumberGenerator.new()
		bootstrap.seed = int(hash(str(Time.get_unix_time_from_system()) + str(Time.get_ticks_usec())))
		seed_val = bootstrap.randi_range(1, 2147483646)
		wgc.world_seed = seed_val
	set_sim_seed(seed_val)
	return seed_val


func set_sim_seed(seed_val: int) -> void:
	_world_seed = seed_val
	rng.seed = seed_val if seed_val != 0 else 1
	_draw_count = 0


func get_world_seed() -> int:
	return _world_seed


func get_draw_count() -> int:
	return _draw_count


func sim_randf() -> float:
	_draw_count += 1
	if debug_log_draws and OS.is_debug_build():
		print("[SimRng] draw #%d -> randf" % _draw_count)
	return rng.randf()


func sim_randf_range(from: float, to: float) -> float:
	_draw_count += 1
	if debug_log_draws and OS.is_debug_build():
		print("[SimRng] draw #%d -> randf_range(%s,%s)" % [_draw_count, from, to])
	return rng.randf_range(from, to)


func sim_randi_range(from: int, to: int) -> int:
	_draw_count += 1
	if debug_log_draws and OS.is_debug_build():
		print("[SimRng] draw #%d -> randi_range(%s,%s)" % [_draw_count, from, to])
	return rng.randi_range(from, to)


## Order-independent scoped RNG (clan name, entity id, etc.) — does not advance global draw counter.
static func make_scoped_rng(world_seed: int, salt: int) -> RandomNumberGenerator:
	var scoped := RandomNumberGenerator.new()
	var h: int = hash(Vector3i(int(world_seed), int(salt), 99173))
	scoped.seed = int(h) if h != 0 else 1
	return scoped
