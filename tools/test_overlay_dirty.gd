extends SceneTree

## Idle overlay: same facing does not apply overlay twice (helpers + call site).


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	var src := FileAccess.get_file_as_string("res://scripts/npc/npc_base.gd")
	if not src.contains("func _weapon_overlay_needs_sync"):
		push_error("TEST_OVERLAY_DIRTY: missing _weapon_overlay_needs_sync")
		quit(1)
		return
	if not src.contains("func _remember_weapon_overlay_sync"):
		push_error("TEST_OVERLAY_DIRTY: missing _remember_weapon_overlay_sync")
		quit(1)
		return
	if not src.contains("if _weapon_overlay_needs_sync(moving):"):
		push_error("TEST_OVERLAY_DIRTY: overlay sync not gated")
		quit(1)
		return
	print("TEST_OVERLAY_DIRTY: ok")
	quit(0)
