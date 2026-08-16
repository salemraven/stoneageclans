extends Node
## Ensures only one running game process (editor Play, exported exe, or run_playtest.ps1).
## Binds localhost TCP port; second instance fails and quits.
## Set environment SKIP_SINGLE_INSTANCE=1 to bypass (e.g. parallel automated tests).

const LOCK_PORT := 45287

var _lock: TCPServer

func _ready() -> void:
	# Web: no TCP server; multi-tab / multiplayer clients must not quit each other.
	if OS.get_name() == "Web":
		return
	if _should_skip_single_instance_lock():
		return
	_lock = TCPServer.new()
	var err: Error = _lock.listen(LOCK_PORT, "127.0.0.1")
	if err != OK:
		push_error(
			"Stone Age Clans: another instance is already running (lock port %d in use)." % LOCK_PORT
		)
		get_tree().quit()


func _should_skip_single_instance_lock() -> bool:
	if OS.get_environment("SKIP_SINGLE_INSTANCE") == "1":
		return true
	for arg: String in OS.get_cmdline_args():
		if arg == "--skip-single-instance":
			return true
		if arg.contains("LimbTuner"):
			return true
	for arg: String in OS.get_cmdline_user_args():
		if arg == "--skip-single-instance":
			return true
	return false
