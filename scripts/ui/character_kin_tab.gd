extends Control
class_name CharacterKinTab

const KinTabData = preload("res://scripts/ui/character_kin_tab_data.gd")
const ThemeScript = preload("res://scripts/ui/ui_theme.gd")

const ANCESTOR_SCROLL_MAX := 118
const DESCENDANT_SCROLL_MAX := 118

signal kin_npc_pressed(npc: NPCBase)

var ancestors_list: VBoxContainer = null
var descendants_list: VBoxContainer = null
var focal_label: Label = null
var hint_label: Label = null


func _ready() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 6)
	add_child(root)
	
	var ancestors_box := _make_scroll_stack("↑ Ancestors", ANCESTOR_SCROLL_MAX)
	root.add_child(ancestors_box.panel)
	ancestors_list = ancestors_box.list
	
	focal_label = Label.new()
	focal_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	focal_label.add_theme_font_size_override("font_size", 15)
	focal_label.add_theme_color_override("font_color", ThemeScript.COLOR_TEXT_SELECTED)
	var focal_panel := Panel.new()
	var focal_style := StyleBoxFlat.new()
	focal_style.bg_color = Color(0, 0, 0, 0.22)
	focal_style.border_color = Color(ThemeScript.COLOR_TEXT_SELECTED, 0.45)
	focal_style.set_border_width_all(1)
	focal_style.set_corner_radius_all(8)
	focal_panel.add_theme_stylebox_override("panel", focal_style)
	focal_panel.custom_minimum_size = Vector2(0, 40)
	var focal_margin := MarginContainer.new()
	focal_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	focal_margin.add_theme_constant_override("margin_top", 8)
	focal_margin.add_theme_constant_override("margin_bottom", 8)
	focal_panel.add_child(focal_margin)
	focal_margin.add_child(focal_label)
	root.add_child(focal_panel)
	
	var descendants_box := _make_scroll_stack("↓ Descendants", DESCENDANT_SCROLL_MAX)
	root.add_child(descendants_box.panel)
	descendants_list = descendants_box.list
	
	hint_label = Label.new()
	hint_label.text = "Bloodline up and down. Gold = on map."
	hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint_label.add_theme_font_size_override("font_size", 11)
	hint_label.add_theme_color_override("font_color", ThemeScript.COLOR_TEXT_SECONDARY)
	root.add_child(hint_label)


func _make_scroll_stack(title: String, max_height: float) -> Dictionary:
	var panel := Panel.new()
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0, 0, 0, 0.12)
	panel_style.border_color = Color(ThemeScript.COLOR_BORDER_SADDLE_BROWN, 0.55)
	panel_style.set_border_width_all(1)
	panel_style.set_corner_radius_all(6)
	panel.add_theme_stylebox_override("panel", panel_style)
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	var outer := VBoxContainer.new()
	outer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	outer.offset_left = 8
	outer.offset_top = 6
	outer.offset_right = -8
	outer.offset_bottom = -6
	outer.add_theme_constant_override("separation", 4)
	panel.add_child(outer)
	
	var header := Label.new()
	header.text = title
	header.add_theme_font_size_override("font_size", 11)
	header.add_theme_color_override("font_color", ThemeScript.COLOR_TEXT_SELECTED)
	outer.add_child(header)
	
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, max_height)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	outer.add_child(scroll)
	
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 4)
	scroll.add_child(list)
	
	return {"panel": panel, "list": list}


func refresh(npc: NPCBase) -> void:
	var data: Dictionary = KinTabData.get_lineage_display(npc)
	if focal_label:
		focal_label.text = str(data.get("focal_name", "Unknown"))
	_fill_groups(ancestors_list, data.get("ancestor_groups", []), true)
	_fill_groups(descendants_list, data.get("descendant_groups", []), false)
	if hint_label:
		var link_count := _count_groups_links(data.get("ancestor_groups", [])) + _count_groups_links(data.get("descendant_groups", []))
		if link_count == 0:
			hint_label.text = "No one on the map in this line yet — grey is name-only."
		else:
			hint_label.text = "Bloodline up and down. Gold = on map."


func _count_groups_links(groups: Array) -> int:
	var n := 0
	for g in groups:
		if not g is Dictionary:
			continue
		for row in g.get("rows", []):
			if row is Dictionary and row.get("npc") != null:
				n += 1
	return n


func _fill_groups(box: VBoxContainer, groups: Array, is_ancestor: bool) -> void:
	_clear_list(box)
	if groups.is_empty():
		var empty := Label.new()
		empty.text = "No ancestors listed" if is_ancestor else "No descendants yet"
		empty.add_theme_font_size_override("font_size", 12)
		empty.add_theme_color_override("font_color", ThemeScript.COLOR_TEXT_SECONDARY)
		box.add_child(empty)
		return
	for g in groups:
		if not g is Dictionary:
			continue
		var title: String = str(g.get("title", ""))
		if title != "":
			var sub := Label.new()
			sub.text = title
			sub.add_theme_font_size_override("font_size", 10)
			sub.add_theme_color_override("font_color", ThemeScript.COLOR_TEXT_SECONDARY)
			box.add_child(sub)
		for row in g.get("rows", []):
			if not row is Dictionary:
				continue
			var role: String = str(row.get("label", "")) if is_ancestor else ""
			_add_kin_row(box, role, row)


func _clear_list(box: VBoxContainer) -> void:
	for c in box.get_children():
		c.queue_free()


func _add_kin_row(box: VBoxContainer, role_prefix: String, row: Dictionary) -> void:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	if role_prefix != "":
		var role_l := Label.new()
		role_l.text = role_prefix
		role_l.custom_minimum_size.x = 52
		role_l.add_theme_font_size_override("font_size", 12)
		role_l.add_theme_color_override("font_color", ThemeScript.COLOR_TEXT_SECONDARY)
		h.add_child(role_l)
	var npc: NPCBase = row.get("npc") as NPCBase
	var display_name: String = str(row.get("display_name", "?"))
	var note: String = str(row.get("note", ""))
	if npc != null and is_instance_valid(npc):
		var link := Button.new()
		link.text = "› %s" % display_name
		link.focus_mode = Control.FOCUS_NONE
		link.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		link.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		ThemeScript.apply_kin_link_button(link)
		link.pressed.connect(func() -> void:
			kin_npc_pressed.emit(npc)
		)
		h.add_child(link)
	else:
		var name_l := Label.new()
		var suffix := " (%s)" % note if note != "" else ""
		name_l.text = "%s%s" % [display_name, suffix]
		name_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_l.add_theme_font_size_override("font_size", 12)
		name_l.add_theme_color_override("font_color", ThemeScript.COLOR_TEXT_SECONDARY)
		h.add_child(name_l)
	box.add_child(h)
