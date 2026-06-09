extends Control
class_name GodmodeClanJumperUI

## ClanBrain test tool: clan name list (top-right). Click a name to jump the observer camera to that land claim.

const REFRESH_INTERVAL: float = 1.5

var _main: Node = null
var _list: VBoxContainer = null
var _refresh_timer: float = 0.0
var _clan_to_claim: Dictionary = {}


func setup(main_ref: Node) -> void:
	_main = main_ref
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_TOP_RIGHT)
	offset_left = -196.0
	offset_top = 12.0
	offset_right = -12.0
	offset_bottom = 12.0

	var panel := Panel.new()
	panel.name = "ClanJumperPanel"
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	UITheme.apply_panel_style(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(panel)

	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 4)
	panel.add_child(root)

	var title := Label.new()
	title.text = "Clans (ClanBrain test)"
	title.add_theme_font_size_override("font_size", 13)
	root.add_child(title)

	var hint := Label.new()
	hint.text = "Click to jump camera"
	hint.add_theme_font_size_override("font_size", 10)
	hint.modulate = Color(0.82, 0.82, 0.82)
	root.add_child(hint)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(172.0, 120.0)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)

	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 2)
	scroll.add_child(_list)

	if _main and _main.has_signal("land_claims_changed"):
		_main.land_claims_changed.connect(refresh_clan_list)
	call_deferred("refresh_clan_list")


func _process(delta: float) -> void:
	_refresh_timer += delta
	if _refresh_timer >= REFRESH_INTERVAL:
		_refresh_timer = 0.0
		refresh_clan_list()


func refresh_clan_list() -> void:
	if not _list or not _main or not _main.has_method("get_cached_land_claims"):
		return
	_clan_to_claim.clear()
	var claims: Array = _main.get_cached_land_claims()
	for claim_node in claims:
		if not is_instance_valid(claim_node) or not (claim_node is LandClaim):
			continue
		var claim: LandClaim = claim_node as LandClaim
		var cn: String = str(claim.clan_name).strip_edges()
		if cn.is_empty():
			continue
		if not _clan_to_claim.has(cn):
			_clan_to_claim[cn] = claim
		elif bool(claim.player_owned):
			_clan_to_claim[cn] = claim

	var names: Array = _clan_to_claim.keys()
	names.sort()

	for child in _list.get_children():
		child.queue_free()

	if names.is_empty():
		var empty := Label.new()
		empty.text = "(no land claims yet)"
		empty.add_theme_font_size_override("font_size", 11)
		_list.add_child(empty)
		return

	for clan_name in names:
		var btn := Button.new()
		btn.text = str(clan_name)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.add_theme_font_size_override("font_size", 12)
		var captured: String = str(clan_name)
		btn.pressed.connect(func() -> void:
			_on_clan_pressed(captured)
		)
		_list.add_child(btn)


func _on_clan_pressed(clan_name: String) -> void:
	if not _main or not _main.has_method("godmode_teleport_to_clan"):
		return
	_main.godmode_teleport_to_clan(clan_name)
