extends Node
## Phase 7: authoritative time for combat scheduling when dedicated server is used.
## Clients apply offset from periodic server sync (stub).

var server_offset_ms: int = 0


func get_authoritative_ticks_msec() -> int:
	return Time.get_ticks_msec() + server_offset_ms


@rpc("authority", "call_remote", "unreliable")
func sync_server_time(server_ticks: int) -> void:
	var local := Time.get_ticks_msec()
	server_offset_ms = server_ticks - local
