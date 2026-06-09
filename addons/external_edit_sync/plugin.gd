@tool
extends EditorPlugin

const _AUTO_RELOAD_KEY := "text_editor/behavior/files/auto_reload_scripts_on_external_change"

func _enter_tree() -> void:
	_apply_editor_settings()


func _apply_editor_settings() -> void:
	var ei := get_editor_interface()
	if ei == null:
		return
	var es: EditorSettings = ei.get_editor_settings()
	if es == null:
		return
	if es.has_setting(_AUTO_RELOAD_KEY) and not es.get_setting(_AUTO_RELOAD_KEY):
		es.set_setting(_AUTO_RELOAD_KEY, true)
