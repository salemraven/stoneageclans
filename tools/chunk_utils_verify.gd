extends SceneTree
# Headless invariant: ChunkUtils constants stay internally consistent (W1 / chunk-spawn docs).
# Run: godot --headless --path <repo> --script res://tools/chunk_utils_verify.gd
# Exit 0 on success, 1 on failure.

func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	# Resolve autoload by path — global `ChunkUtils` may not resolve when run via `--script`.
	var cu: Node = get_root().get_node_or_null("/root/ChunkUtils")
	if cu == null:
		push_error("CHUNK_UTILS_VERIFY_FAIL: /root/ChunkUtils autoload missing")
		quit(1)
		return
	var ts: int = int(cu.get("TILE_SIZE"))
	var ct: int = int(cu.get("CHUNK_TILES"))
	var cs: float = float(cu.get("CHUNK_SIZE"))
	var roam: float = float(cu.get("ROAM_RADIUS"))
	var expected: float = float(ts * ct)
	if abs(cs - expected) > 0.001:
		push_error("CHUNK_UTILS_VERIFY_FAIL: CHUNK_SIZE=%s != TILE_SIZE*CHUNK_TILES (%d*%d=%s)" % [cs, ts, ct, expected])
		quit(1)
		return
	if roam <= 0.0 or roam > cs:
		push_error("CHUNK_UTILS_VERIFY_FAIL: ROAM_RADIUS out of sane range")
		quit(1)
		return
	print("CHUNK_UTILS_VERIFY_OK: TILE_SIZE=%d CHUNK_TILES=%d CHUNK_SIZE=%s ROAM_RADIUS=%s" % [ts, ct, cs, roam])
	quit(0)
