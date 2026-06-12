extends Node
## Global simulation tick driver (calorie drain, clan economy, animal feeding).
## Server-authoritative when multiplayer is active.

@export var tick_interval_seconds: float = 120.0
@export var time_acceleration: float = 1.0

var game_time: float = 0.0
var next_tick_time: float = 0.0
var ticks_per_sim_day: int = 5

signal simulation_tick(delta_game_time: float)


func _ready() -> void:
	if BalanceConfig:
		tick_interval_seconds = BalanceConfig.simulation_tick_interval_seconds
		ticks_per_sim_day = maxi(1, BalanceConfig.get_sim_ticks_per_day())
	next_tick_time = tick_interval_seconds


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if not _should_emit_ticks():
		return

	game_time += delta * time_acceleration

	while game_time >= next_tick_time:
		var tick_delta: float = tick_interval_seconds * time_acceleration
		next_tick_time += tick_interval_seconds
		simulation_tick.emit(tick_delta)
		_log_playtest_simulation_tick()
		_broadcast_tick_if_server()


func _should_emit_ticks() -> bool:
	if not is_inside_tree():
		return true
	var mp: MultiplayerAPI = get_multiplayer()
	if mp == null or not mp.has_multiplayer_peer():
		return true
	return mp.is_server()


func sync_from_server(server_game_time: float) -> void:
	game_time = server_game_time
	next_tick_time = game_time + tick_interval_seconds


func _broadcast_tick_if_server() -> void:
	if not is_inside_tree():
		return
	var mp: MultiplayerAPI = get_multiplayer()
	if mp == null or not mp.has_multiplayer_peer() or not mp.is_server():
		return
	sync_game_time.rpc(game_time)


@rpc("authority", "call_remote", "reliable")
func sync_game_time(server_game_time: float) -> void:
	sync_from_server(server_game_time)


func _log_playtest_simulation_tick() -> void:
	if not is_inside_tree():
		return
	var pi: Node = get_tree().root.get_node_or_null("PlaytestInstrumentor")
	if pi and pi.is_enabled() and pi.has_method("simulation_tick"):
		pi.simulation_tick(game_time, tick_interval_seconds, ticks_per_sim_day)
