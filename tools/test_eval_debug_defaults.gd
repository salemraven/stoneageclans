extends SceneTree

## Defaults for dummy art crowds must be off. CLI still sets them.

func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	var dc: Node = root.get_node_or_null("/root/DebugConfig")
	if dc == null:
		push_error("TEST_EVAL_DEBUG_DEFAULTS: DebugConfig missing")
		quit(1)
		return
	var hair: int = int(dc.get("eval_hair_gallery_count"))
	var women: int = int(dc.get("eval_wild_women_near_start"))
	var claims: int = int(dc.get("eval_ai_claims_near_start"))
	if hair != 0 or women != 0 or claims != 0:
		push_error("TEST_EVAL_DEBUG_DEFAULTS: expected 0,0,0 got %d,%d,%d" % [hair, women, claims])
		quit(1)
		return
	print("TEST_EVAL_DEBUG_DEFAULTS: ok (hair/women/claims = 0)")
	quit(0)
