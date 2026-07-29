extends SceneTree

## Headless Character Animation Tuner CLI for cloud agents and CI.
## Usage:
##   godot --headless --path . --script res://tools/limb_tuner_cli.gd -- smoke
##   godot --headless --path . --script res://tools/limb_tuner_cli.gd -- bake --weapon none --clip idle

const LimbAnimationBakerScript = preload("res://scripts/tools/limb_animation_baker.gd")
const TUNER_SCENE := "res://scenes/tools/LimbTuner.tscn"

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var parsed := _parse_args()
	if parsed.get("help", false):
		_print_help()
		quit(0)
		return
	var command: String = str(parsed.get("command", ""))
	match command:
		"smoke":
			await _cmd_smoke()
		"bake":
			await _cmd_bake(str(parsed.get("weapon", "none")), str(parsed.get("clip", "idle")))
		_:
			_fail("Unknown command %r — use smoke or bake (see --help)." % command)
	await _report()


func _parse_args() -> Dictionary:
	var out := {
		"help": false,
		"command": "",
		"weapon": "none",
		"clip": "idle",
	}
	var argv := OS.get_cmdline_user_args()
	if argv.is_empty():
		argv = OS.get_cmdline_args()
	var i := 0
	while i < argv.size():
		var token: String = str(argv[i])
		if token in ["--help", "-h"]:
			out["help"] = true
		elif token == "smoke" or token == "bake":
			out["command"] = token
		elif token == "--weapon" and i + 1 < argv.size():
			i += 1
			out["weapon"] = str(argv[i])
		elif token == "--clip" and i + 1 < argv.size():
			i += 1
			out["clip"] = str(argv[i])
		elif token.begins_with("--weapon="):
			out["weapon"] = token.substr("--weapon=".length())
		elif token.begins_with("--clip="):
			out["clip"] = token.substr("--clip=".length())
		i += 1
	return out


func _print_help() -> void:
	print(
		"""LIMB_TUNER_CLI — headless Character Animation Tuner

Commands (after `--`):
  smoke                         Load LimbTuner.tscn, print rig summary, exit 0
  bake --weapon <slug> --clip <clip>
                                Bake PNG+JSON from current presets on disk

Weapon slugs: none, club, spear, axe, pick, oldowan
Clip slugs:   idle, idle1, walk, gather1

Examples:
  godot --headless --path . --script res://tools/limb_tuner_cli.gd -- smoke
  godot --headless --path . --script res://tools/limb_tuner_cli.gd -- bake --weapon none --clip idle

Or use: bash tools/run_limb_tuner.sh verify|bake|smoke|gui|share-web
"""
	)


func _instantiate_tuner() -> Node:
	var packed := load(TUNER_SCENE) as PackedScene
	if packed == null:
		_fail("LimbTuner scene missing: %s" % TUNER_SCENE)
		return null
	var app: Node = packed.instantiate()
	root.add_child(app)
	for _i in range(3):
		await process_frame
	return app


func _cmd_smoke() -> void:
	var app := await _instantiate_tuner()
	if app == null:
		return
	var rig: Node = app.get("_rig")
	var preset = app.get("_preset")
	var weapon_slug := LimbAnimationBakerScript.weapon_slug(app.get("_selected_weapon"))
	print(
		"LIMB_TUNER_SMOKE_OK weapon=%s clip_capable=%s rig=%s preset=%s"
		% [
			weapon_slug,
			LimbAnimationBakerScript.clip_for_anim_mode(app.get("_anim_mode")),
			"ok" if rig != null else "missing",
			"ok" if preset != null else "missing",
		]
	)
	app.queue_free()


func _cmd_bake(weapon_slug: String, clip: String) -> void:
	var app := await _instantiate_tuner()
	if app == null:
		return
	if not app.has_method("configure_for_cli_bake"):
		_fail("LimbTunerApp missing configure_for_cli_bake")
		app.queue_free()
		return
	var cfg: Dictionary = app.configure_for_cli_bake(weapon_slug, clip)
	if not cfg.get("ok", false):
		_fail(str(cfg.get("error", "configure failed")))
		app.queue_free()
		return
	await process_frame
	var baker := LimbAnimationBakerScript.new()
	var normalized_clip: String = str(cfg.get("clip", clip))
	var result: Dictionary = await baker.bake_from_tuner(app, normalized_clip)
	app.queue_free()
	if not result.get("ok", false):
		_fail("bake failed: %s" % str(result.get("error", "")))
		return
	print(
		"LIMB_TUNER_BAKE_OK weapon=%s clip=%s png=%s json=%s"
		% [
			str(cfg.get("weapon", weapon_slug)),
			normalized_clip,
			str(result.get("png_path", "")),
			str(result.get("json_path", "")),
		]
	)


func _fail(msg: String) -> void:
	_failures.append(msg)
	push_error("limb_tuner_cli: %s" % msg)


func _report() -> void:
	if _failures.is_empty():
		quit(0)
	else:
		for f in _failures:
			print("FAIL: ", f)
		quit(1)
