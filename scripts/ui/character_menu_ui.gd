extends Control
class_name CharacterMenuUI

# Character Menu UI - Displays NPC information when clicked
# Shows name, lineage, hominid class, and traits table
# Follows UI.md design standards

const PANEL_WIDTH := 400
const PANEL_HEIGHT := 700  # Increased to fit both info and inventory
const PANEL_PADDING := 16
const SLOT_COUNT := 10
const SLOT_SIZE := 32

var is_open: bool = false
var target_npc: NPCBase = null  # The NPC this menu displays info for
var character_panel: Panel = null
var content_container: VBoxContainer = null

# UI Elements
var name_label: Label = null
var lineage_label: Label = null
var mother_label: Label = null
var hominid_class_label: Label = null
var status_bars_container: VBoxContainer = null
var bravery_bar: Control = null
var agro_bar: Control = null
var traits_table: Control = null

# Timer display (top right corner)
var timer_container: Control = null
var timer_label: Label = null

# Inventory elements (merged into character menu)
var inventory_data: InventoryData = null
var inventory_section: Control = null
var inventory_header: Label = null
var slot_container: VBoxContainer = null
var slots: Array[InventorySlot] = []
var drag_manager: Node = null

func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Get drag manager for inventory interactions
	drag_manager = get_node_or_null("/root/DragManager")
	if not drag_manager:
		var main: Node = get_tree().get_first_node_in_group("main")
		if main and main.has_method("get") and main.get("drag_manager"):
			drag_manager = main.drag_manager
	
	if drag_manager and not drag_manager.drag_ended.is_connected(_on_drag_ended):
		drag_manager.drag_ended.connect(_on_drag_ended)
	
	set_process_input(true)
	_setup_panel()

func _setup_panel() -> void:
	# Root control - full screen
	custom_minimum_size = Vector2(1280, 720)
	anchors_preset = Control.PRESET_FULL_RECT
	
	# Create character info panel
	character_panel = Panel.new()
	character_panel.name = "CharacterPanel"
	UITheme.apply_panel_style(character_panel)
	character_panel.custom_minimum_size = Vector2(PANEL_WIDTH, PANEL_HEIGHT)
	character_panel.set_as_top_level(true)  # Allow positioning above NPC
	add_child(character_panel)
	
	# Position will be set in _update_panel_position()
	
	# MarginContainer with padding
	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", PANEL_PADDING)
	margin.add_theme_constant_override("margin_top", PANEL_PADDING)
	margin.add_theme_constant_override("margin_right", PANEL_PADDING)
	margin.add_theme_constant_override("margin_bottom", PANEL_PADDING)
	character_panel.add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# Timer display container (top right corner)
	timer_container = Control.new()
	timer_container.name = "TimerContainer"
	timer_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	character_panel.add_child(timer_container)
	
	# Position timer in top right
	timer_container.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	timer_container.anchor_left = 1.0
	timer_container.anchor_top = 0.0
	timer_container.anchor_right = 1.0
	timer_container.anchor_bottom = 0.0
	timer_container.offset_left = -150  # 150px wide
	timer_container.offset_top = 8  # 8px from top
	timer_container.offset_right = -8  # 8px from right edge
	timer_container.offset_bottom = 40  # ~40px tall
	
	timer_label = Label.new()
	timer_label.name = "TimerLabel"
	timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	timer_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	timer_label.add_theme_font_size_override("font_size", 12)
	timer_label.add_theme_color_override("font_color", UITheme.COLOR_TEXT_SECONDARY)
	timer_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	timer_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	timer_label.text = ""
	timer_container.add_child(timer_label)
	
	# Main content container (vertical)
	content_container = VBoxContainer.new()
	content_container.name = "ContentContainer"
	content_container.add_theme_constant_override("separation", 8)
	margin.add_child(content_container)
	content_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# Build UI elements
	_build_ui_elements()

func _build_ui_elements() -> void:
	# Header Section: NPC Name (bold, 20px)
	name_label = Label.new()
	name_label.name = "NameLabel"
	name_label.add_theme_font_size_override("font_size", 20)
	name_label.add_theme_color_override("font_color", UITheme.COLOR_TEXT_PRIMARY)
	name_label.add_theme_constant_override("outline_size", 0)  # No outline for now
	content_container.add_child(name_label)
	
	# Lineage: "Son of [Father] of Clan [Name]"
	lineage_label = Label.new()
	lineage_label.name = "LineageLabel"
	lineage_label.add_theme_font_size_override("font_size", 14)
	lineage_label.add_theme_color_override("font_color", UITheme.COLOR_TEXT_SECONDARY)
	content_container.add_child(lineage_label)
	
	# Mother: "Mother XXXX" (only for babies and clansmen)
	mother_label = Label.new()
	mother_label.name = "MotherLabel"
	mother_label.add_theme_font_size_override("font_size", 14)
	mother_label.add_theme_color_override("font_color", UITheme.COLOR_TEXT_SECONDARY)
	content_container.add_child(mother_label)
	
	# Spacer
	var spacer1 := Control.new()
	spacer1.custom_minimum_size = Vector2(0, 8)
	content_container.add_child(spacer1)
	
	# Hominid Class Section
	var hominid_header := Label.new()
	hominid_header.name = "HominidHeader"
	hominid_header.text = "Hominid Class:"
	hominid_header.add_theme_font_size_override("font_size", 16)
	hominid_header.add_theme_color_override("font_color", UITheme.COLOR_TEXT_PRIMARY)
	content_container.add_child(hominid_header)
	
	hominid_class_label = Label.new()
	hominid_class_label.name = "HominidClassLabel"
	hominid_class_label.add_theme_font_size_override("font_size", 14)
	hominid_class_label.add_theme_color_override("font_color", UITheme.COLOR_TEXT_PRIMARY)
	content_container.add_child(hominid_class_label)
	
	# Spacer
	var spacer2 := Control.new()
	spacer2.custom_minimum_size = Vector2(0, 8)
	content_container.add_child(spacer2)
	
	# Status Section Header
	var status_header := Label.new()
	status_header.name = "StatusHeader"
	status_header.text = "Status:"
	status_header.add_theme_font_size_override("font_size", 16)
	status_header.add_theme_color_override("font_color", UITheme.COLOR_TEXT_PRIMARY)
	content_container.add_child(status_header)
	
	# Status bars container
	status_bars_container = VBoxContainer.new()
	status_bars_container.name = "StatusBarsContainer"
	status_bars_container.add_theme_constant_override("separation", 8)
	content_container.add_child(status_bars_container)
	
	# Bravery bar
	bravery_bar = _create_status_bar("Bravery:")
	status_bars_container.add_child(bravery_bar)
	
	# Agro bar
	agro_bar = _create_status_bar("Agro:")
	status_bars_container.add_child(agro_bar)
	
	# Spacer
	var spacer3 := Control.new()
	spacer3.custom_minimum_size = Vector2(0, 8)
	content_container.add_child(spacer3)
	
	# Traits Section Header
	var traits_header := Label.new()
	traits_header.name = "TraitsHeader"
	traits_header.text = "Traits:"
	traits_header.add_theme_font_size_override("font_size", 16)
	traits_header.add_theme_color_override("font_color", UITheme.COLOR_TEXT_PRIMARY)
	content_container.add_child(traits_header)
	
	# Traits Table (will be populated when NPC is set)
	traits_table = VBoxContainer.new()
	traits_table.name = "TraitsTable"
	traits_table.add_theme_constant_override("separation", 2)
	content_container.add_child(traits_table)
	
	# Spacer before inventory section
	var spacer4 := Control.new()
	spacer4.custom_minimum_size = Vector2(0, 16)
	content_container.add_child(spacer4)
	
	# Inventory Section Header
	inventory_header = Label.new()
	inventory_header.name = "InventoryHeader"
	inventory_header.text = "Inventory:"
	inventory_header.add_theme_font_size_override("font_size", 16)
	inventory_header.add_theme_color_override("font_color", UITheme.COLOR_TEXT_PRIMARY)
	content_container.add_child(inventory_header)
	
	# Inventory slot container
	inventory_section = VBoxContainer.new()
	inventory_section.name = "InventorySection"
	inventory_section.add_theme_constant_override("separation", 2)
	content_container.add_child(inventory_section)
	
	slot_container = VBoxContainer.new()
	slot_container.name = "SlotContainer"
	slot_container.add_theme_constant_override("separation", 2)
	inventory_section.add_child(slot_container)

func setup(npc: NPCBase) -> void:
	print("CharacterMenuUI: setup() called for NPC")
	if not npc or not is_instance_valid(npc):
		print("CharacterMenuUI: Cannot setup - NPC is invalid!")
		return
	print("CharacterMenuUI: NPC is valid, setting target_npc")
	target_npc = npc
	
	# Setup inventory if NPC has one
	var npc_inventory = npc.get("inventory") if npc else null
	if npc_inventory and npc_inventory is InventoryData:
		inventory_data = npc_inventory
		_setup_inventory()
	else:
		# No inventory - hide inventory section
		if inventory_header:
			inventory_header.visible = false
		if inventory_section:
			inventory_section.visible = false
		inventory_data = null
	
	print("CharacterMenuUI: Calling _update_display()")
	_update_display()
	print("CharacterMenuUI: _update_display() completed")

func _update_display() -> void:
	print("CharacterMenuUI: _update_display() START")
	if not target_npc or not is_instance_valid(target_npc):
		print("CharacterMenuUI: Cannot update display - target_npc is invalid!")
		return
	
	# Safety check: ensure UI elements are initialized
	if not name_label or not lineage_label or not hominid_class_label or not traits_table:
		print("CharacterMenuUI: UI elements not initialized!")
		return
	
	print("CharacterMenuUI: Getting NPC name...")
	# Update NPC name (bold header) - use same pattern as main.gd
	var npc_name: String = "Unknown"
	if is_instance_valid(target_npc):
		# Use same pattern as main.gd: npc.get("npc_name") if npc else "unknown"
		var name_val = target_npc.get("npc_name") if target_npc else null
		if name_val != null:
			if name_val is String:
				npc_name = name_val if name_val != "" else "Unknown"
			else:
				npc_name = str(name_val)
	
	if npc_name == "":
		npc_name = "Unknown"
	print("CharacterMenuUI: About to set name_label.text to: %s" % npc_name)
	if name_label:
		name_label.text = npc_name
		print("CharacterMenuUI: NPC name set successfully")
	else:
		print("CharacterMenuUI: ERROR - name_label is null!")
	
	print("CharacterMenuUI: Getting lineage...")
	# Update lineage: "Son of [Father] of Clan [Name]"
	# Note: father_name may not exist on all NPCs - handle gracefully
	var father_name: String = ""
	# Try get() first, then try meta as fallback
	var father_val = target_npc.get("father_name") if target_npc else null
	if father_val != null and father_val is String:
		father_name = father_val
	else:
		# Try meta as fallback
		if target_npc and target_npc.has_meta("father_name"):
			var meta_father = target_npc.get_meta("father_name")
			if meta_father != null and meta_father is String:
				father_name = meta_father
	
	if father_name != "":
		print("CharacterMenuUI: Found father_name: '%s'" % father_name)
	else:
		print("CharacterMenuUI: No father_name found (get()=%s, meta=%s)" % [father_val, target_npc.get_meta("father_name", "none") if target_npc and target_npc.has_meta("father_name") else "none"])
	
	# Safely get clan name - handle method call errors gracefully
	var clan_name: String = ""
	# Try get() directly first (returns null if property doesn't exist)
	var clan_val = target_npc.get("clan_name") if target_npc else null
	if clan_val != null and clan_val is String:
		clan_name = clan_val
	# Fallback: try method if property didn't work
	if clan_name == "" and is_instance_valid(target_npc) and target_npc.has_method("get_clan_name"):
		clan_name = target_npc.get_clan_name()
		if clan_name == null:
			clan_name = ""
	
	# Get mother name (for babies and clansmen)
	var mother_name: String = ""
	var mother_val = target_npc.get("mother_name") if target_npc else null
	if mother_val != null and mother_val is String:
		mother_name = mother_val
	else:
		# Try meta as fallback
		if target_npc and target_npc.has_meta("mother_name"):
			var meta_mother = target_npc.get_meta("mother_name")
			if meta_mother != null and meta_mother is String:
				mother_name = meta_mother
	
	print("CharacterMenuUI: Clan name: '%s', Father name: '%s', Mother name: '%s'" % [clan_name, father_name, mother_name])
	# Display lineage for babies and clansmen (they have father_name)
	var npc_type_val = target_npc.get("npc_type") if target_npc else null
	var npc_type: String = npc_type_val as String if npc_type_val != null and npc_type_val is String else ""
	
	if npc_type == "baby" or npc_type == "clansman":
		# Babies and clansmen should have lineage - format: "Son of XXXX of Clan XXXX"
		if father_name != "" and clan_name != "":
			lineage_label.text = "Son of %s of Clan %s" % [father_name, clan_name]
		elif clan_name != "":
			lineage_label.text = "Clan %s" % clan_name
		else:
			lineage_label.text = "No clan affiliation"
		
		# Display mother name: "Mother XXXX"
		if mother_name != "":
			mother_label.text = "Mother %s" % mother_name
			mother_label.visible = true
		else:
			mother_label.text = ""
			mother_label.visible = false
	else:
		# Other NPCs just show clan
		if clan_name != "":
			lineage_label.text = "Clan %s" % clan_name
		else:
			lineage_label.text = "No clan affiliation"
		
		# Hide mother label for non-baby/clansman NPCs
		mother_label.text = ""
		mother_label.visible = false
	
	print("CharacterMenuUI: Getting hominid class...")
	# Update hominid class
	var hominid_class: String = _get_hominid_class(target_npc)
	hominid_class_label.text = hominid_class
	print("CharacterMenuUI: Hominid class: %s" % hominid_class)
	
	print("CharacterMenuUI: Updating status bars...")
	# Update status bars (bravery and agro)
	_update_status_bars()
	
	print("CharacterMenuUI: Updating traits table...")
	# Update traits table
	_update_traits_table()
	
	# Update timer display
	_update_timers()
	
	print("CharacterMenuUI: _update_display() END")

func _get_hominid_class(npc: NPCBase) -> String:
	if not npc or not is_instance_valid(npc):
		return "Unknown"
	
	# Check for hominid species property - use get() directly
	var species = npc.get("hominid_species") if npc else null
	if species != null and species is String and species != "":
		return species
	
	# Fallback: Return placeholder based on NPC type
	var npc_type: String = "generic"
	var type_val = npc.get("npc_type") if npc else null
	if type_val != null and type_val is String:
		npc_type = type_val
	match npc_type:
		"human", "clansman":
			return "Human"  # Placeholder - will need actual hominid species data
		"woman":
			return "Human"  # Placeholder
		"baby":
			return "Human"  # Babies inherit species from parents
		_:
			return "Unknown"

func _get_traits_list() -> Array[Dictionary]:
	# Returns the list of traits to display in the character menu
	# To add new traits, simply add a new dictionary to this array:
	# {"name": "Display Name", "stat": "stat_property_name"}
	# The stat property name must match a valid stat in the Stats component
	# Order matches charactermenu.md specification
	return [
		{"name": "Strength", "stat": "strength"},
		{"name": "Intelligence", "stat": "intelligence"},
		{"name": "Endurance", "stat": "endurance"},
		{"name": "Agility", "stat": "agility"},
		{"name": "Perception", "stat": "perception"},
		{"name": "Social", "stat": "social"},
		{"name": "Pain Tolerance", "stat": "pain_tolerance"},
		{"name": "Carry Capacity", "stat": "carry_capacity"},
		{"name": "Bravery", "stat": "bravery"}  # Dynamic value: 0.0-1.0, displayed as 0-100%
	]

func _update_traits_table() -> void:
	if not target_npc or not is_instance_valid(target_npc):
		return
	
	# Clear existing trait rows
	for child in traits_table.get_children():
		child.queue_free()
	
	# Get stats component - handle missing stats gracefully
	var stats: Stats = null
	# Use get() directly - returns null if property doesn't exist
	var stats_val = target_npc.get("stats_component") if target_npc else null
	if stats_val != null and stats_val is Stats:
		stats = stats_val
	
	if not stats or not is_instance_valid(stats):
		# No stats - show message (this is normal for some NPCs like wild women)
		var no_stats_label := Label.new()
		no_stats_label.text = "No stats available"
		no_stats_label.add_theme_font_size_override("font_size", 12)
		no_stats_label.add_theme_color_override("font_color", UITheme.COLOR_TEXT_SECONDARY)
		traits_table.add_child(no_stats_label)
		return
	
	# Get traits list (flexible - easy to extend)
	var traits_to_show: Array[Dictionary] = _get_traits_list()
	
	# Create table rows
	for trait_data in traits_to_show:
		var row := _create_trait_row(trait_data["name"], trait_data["stat"], stats)
		traits_table.add_child(row)

func _create_trait_row(trait_name: String, stat_name: String, stats: Stats) -> Control:
	# Create row container (horizontal)
	var row := Panel.new()
	row.custom_minimum_size = Vector2(0, 24)  # Row height
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Apply subtle background for alternating rows (optional)
	var row_style := StyleBoxFlat.new()
	row_style.bg_color = Color(0, 0, 0, 0.1)  # Very subtle background
	row.add_theme_stylebox_override("panel", row_style)
	
	# Horizontal container for content
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.add_child(hbox)
	
	# Trait name (left column)
	var trait_name_label := Label.new()
	trait_name_label.text = trait_name
	trait_name_label.add_theme_font_size_override("font_size", 14)
	trait_name_label.add_theme_color_override("font_color", UITheme.COLOR_TEXT_PRIMARY)
	trait_name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(trait_name_label)
	
	# Trait value (right column)
	var value_label := Label.new()
	# Safely get stat value - handle missing stats gracefully
	var stat_value: float = 0.0
	if stats and stats.has_method("get_stat"):
		stat_value = stats.get_stat(stat_name)
	
	# Special handling for bravery: convert 0.0-1.0 to 0-100% display
	var value_text: String
	if stat_name == "bravery":
		# Bravery is stored as 0.0-1.0, display as 0-100%
		var bravery_percent = stat_value * 100.0
		value_text = "%d%%" % int(round(bravery_percent))
	else:
		# Other stats: display as whole number
		value_text = "%.0f" % stat_value
	
	value_label.text = value_text
	value_label.add_theme_font_size_override("font_size", 14)
	value_label.add_theme_color_override("font_color", UITheme.COLOR_TEXT_PRIMARY)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hbox.add_child(value_label)
	
	return row

func _create_status_bar(label_text: String) -> Control:
	# Create a status bar container (label + progress bar)
	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 4)
	container.custom_minimum_size = Vector2(0, 24)
	
	# Label
	var label := Label.new()
	label.text = label_text
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", UITheme.COLOR_TEXT_PRIMARY)
	container.add_child(label)
	
	# Progress bar container (horizontal: bar + percentage)
	var bar_container := HBoxContainer.new()
	bar_container.add_theme_constant_override("separation", 8)
	container.add_child(bar_container)
	
	# Progress bar background
	var bar_bg := Panel.new()
	bar_bg.custom_minimum_size = Vector2(200, 16)
	bar_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = Color(0x2a, 0x2a, 0x2a, 0.6)  # Dark gray, 60% opacity
	bg_style.border_color = Color(0x1a, 0x1a, 0x1a, 1.0)  # Dark gray border
	bg_style.border_width_left = 1
	bg_style.border_width_top = 1
	bg_style.border_width_right = 1
	bg_style.border_width_bottom = 1
	bg_style.corner_radius_top_left = 4
	bg_style.corner_radius_top_right = 4
	bg_style.corner_radius_bottom_left = 4
	bg_style.corner_radius_bottom_right = 4
	bar_bg.add_theme_stylebox_override("panel", bg_style)
	bar_container.add_child(bar_bg)
	
	# Progress bar fill (will be updated dynamically)
	var bar_fill := Panel.new()
	bar_fill.name = "BarFill"
	bar_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar_bg.add_child(bar_fill)
	
	# Percentage label
	var percent_label := Label.new()
	percent_label.name = "PercentLabel"
	percent_label.add_theme_font_size_override("font_size", 14)
	percent_label.add_theme_color_override("font_color", UITheme.COLOR_TEXT_PRIMARY)
	percent_label.text = "0%"
	bar_container.add_child(percent_label)
	
	return container

func _update_status_bars() -> void:
	if not target_npc or not is_instance_valid(target_npc):
		return
	
	# Update Bravery bar
	if bravery_bar:
		_update_status_bar(bravery_bar, "Bravery:", _get_bravery_value(), true)
	
	# Update Agro bar
	if agro_bar:
		_update_status_bar(agro_bar, "Agro:", _get_agro_value(), false)

func _get_bravery_value() -> float:
	# Get bravery value (0.0 to 1.0) from NPC
	if not target_npc or not is_instance_valid(target_npc):
		return 0.0
	
	# Try direct property first
	var bravery_val = target_npc.get("bravery") if target_npc else null
	if bravery_val != null:
		if bravery_val is float:
			return clamp(bravery_val as float, 0.0, 1.0)
		elif bravery_val is int:
			return clamp(float(bravery_val) / 100.0, 0.0, 1.0)
	
	# Try personality_traits dictionary
	if target_npc.has_method("get") and target_npc.get("personality_traits"):
		var traits = target_npc.get("personality_traits")
		if traits is Dictionary and traits.has("bravery"):
			var trait_bravery = traits["bravery"]
			if trait_bravery is float:
				return clamp(trait_bravery as float, 0.0, 1.0)
	
	# Default: 0.5 (medium bravery)
	return 0.5

func _get_agro_value() -> float:
	# Get agro meter value (0.0 to 100.0) from NPC
	if not target_npc or not is_instance_valid(target_npc):
		return 0.0
	
	# Try agro_meter first
	var agro_val = target_npc.get("agro_meter") if target_npc else null
	if agro_val != null:
		if agro_val is float:
			return clamp(agro_val as float, 0.0, 100.0)
		elif agro_val is int:
			return clamp(float(agro_val), 0.0, 100.0)
	
	# Default: 0.0 (no agro)
	return 0.0

func _update_status_bar(bar_container: Control, label_text: String, value: float, is_bravery: bool) -> void:
	if not bar_container:
		return
	
	# Get bar fill and percent label
	var bar_bg: Panel = null
	var bar_fill: Panel = null
	var percent_label: Label = null
	
	# Find bar_bg (first Panel child of HBoxContainer)
	var hbox: HBoxContainer = bar_container.get_child(1) as HBoxContainer if bar_container.get_child_count() > 1 else null
	if hbox:
		bar_bg = hbox.get_child(0) as Panel if hbox.get_child_count() > 0 else null
		if bar_bg:
			bar_fill = bar_bg.get_node_or_null("BarFill") as Panel
		percent_label = hbox.get_child(1) as Label if hbox.get_child_count() > 1 else null
	
	if not bar_fill or not percent_label:
		return
	
	# Calculate percentage and fill width
	var percent: float = 0.0
	var fill_width: float = 0.0
	
	if is_bravery:
		# Bravery: 0.0-1.0 → 0-100%
		percent = value * 100.0
		fill_width = value * 200.0  # Bar width is 200px
	else:
		# Agro: 0.0-100.0 → 0-100%
		percent = value
		fill_width = (value / 100.0) * 200.0  # Bar width is 200px
	
	# Clamp values
	percent = clamp(percent, 0.0, 100.0)
	fill_width = clamp(fill_width, 0.0, 200.0)
	
	# Update percentage label
	percent_label.text = "%d%%" % int(round(percent))
	
	# Update bar fill
	var fill_style := StyleBoxFlat.new()
	
	# Color based on value and type
	if is_bravery:
		# Bravery colors: Low (0-0.3) = Red, Medium (0.3-0.7) = Orange, High (0.7-1.0) = Green
		if value <= 0.3:
			fill_style.bg_color = Color(0xd3, 0x2f, 0x2f, 1.0)  # Red
		elif value <= 0.7:
			fill_style.bg_color = Color(0xff, 0x98, 0x00, 1.0)  # Orange
		else:
			fill_style.bg_color = Color(0x66, 0xbb, 0x6a, 1.0)  # Green
	else:
		# Agro colors: Low (0-30) = Green, Medium (30-70) = Orange, High (70-100) = Red
		if value <= 30.0:
			fill_style.bg_color = Color(0x66, 0xbb, 0x6a, 1.0)  # Green
		elif value <= 70.0:
			fill_style.bg_color = Color(0xff, 0x98, 0x00, 1.0)  # Orange
		else:
			fill_style.bg_color = Color(0xd3, 0x2f, 0x2f, 1.0)  # Red
	
	fill_style.corner_radius_top_left = 4
	fill_style.corner_radius_top_right = 4
	fill_style.corner_radius_bottom_left = 4
	fill_style.corner_radius_bottom_right = 4
	bar_fill.add_theme_stylebox_override("panel", fill_style)
	
	# Set fill size
	bar_fill.custom_minimum_size = Vector2(fill_width, 16)
	bar_fill.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	bar_fill.offset_left = 0
	bar_fill.offset_top = 0
	bar_fill.offset_right = fill_width
	bar_fill.offset_bottom = 16

func show_menu() -> void:
	print("CharacterMenuUI: show_menu() called")
	if not target_npc or not is_instance_valid(target_npc):
		print("CharacterMenuUI: Cannot show menu - no target NPC or invalid!")
		return
	
	print("CharacterMenuUI: Target NPC is valid, proceeding...")
	# Track when menu opens to prevent immediate close
	_menu_open_time = Time.get_ticks_msec() / 1000.0
	
	is_open = true
	visible = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	
	print("CharacterMenuUI: Freezing NPC movement...")
	# Freeze NPC movement FIRST (before showing UI)
	_freeze_npc_movement(true)
	
	print("CharacterMenuUI: Updating panel position...")
	# Update panel position (above NPC)
	_update_panel_position()
	
	print("CharacterMenuUI: Updating display...")
	# Update display (setup() already called this, but call again to ensure fresh data)
	_update_display()
	
	# Update inventory display
	if inventory_data:
		_update_inventory()
	
	print("CharacterMenuUI: show_menu() completed successfully")

func hide_menu() -> void:
	is_open = false
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Reset timing
	_menu_open_time = 0.0
	
	# Unfreeze NPC movement
	_freeze_npc_movement(false)

func toggle() -> void:
	if is_open:
		hide_menu()
	else:
		show_menu()

func _freeze_npc_movement(freeze: bool) -> void:
	print("CharacterMenuUI: _freeze_npc_movement(%s) called" % freeze)
	if not target_npc or not is_instance_valid(target_npc):
		print("CharacterMenuUI: Cannot pause/unpause - target_npc is invalid")
		return
	
	if freeze:
		print("CharacterMenuUI: Pausing NPC movement...")
		# Pause NPC movement: Set velocity to zero and mark as frozen
		# The NPC's _physics_process will check this flag and skip movement updates
		target_npc.velocity = Vector2.ZERO
		target_npc.set_meta("inspection_frozen", true)
		print("CharacterMenuUI: NPC movement paused successfully")
	else:
		# Unpause NPC: Remove frozen flag - they'll resume movement naturally
		if target_npc.has_meta("inspection_frozen"):
			target_npc.remove_meta("inspection_frozen")
		print("CharacterMenuUI: NPC movement resumed")

func _setup_inventory() -> void:
	if not inventory_data or not slot_container:
		return
	
	# Clear existing slots
	for slot in slots:
		if is_instance_valid(slot):
			slot.queue_free()
	slots.clear()
	
	# Show inventory section
	if inventory_header:
		inventory_header.visible = true
	if inventory_section:
		inventory_section.visible = true
	
	# Create slots based on inventory size
	var slot_count = inventory_data.slot_count if inventory_data else SLOT_COUNT
	for i in slot_count:
		var slot: InventorySlot = InventorySlot.new()
		slot.slot_index = i
		slot.is_hotbar = false
		slot.can_stack = false
		slot.custom_minimum_size = Vector2(SLOT_SIZE, SLOT_SIZE)
		slot.name = "Slot%d" % i
		
		# Connect signals
		if not slot.slot_clicked.is_connected(_on_slot_clicked):
			slot.slot_clicked.connect(_on_slot_clicked)
		if not slot.slot_drag_ended.is_connected(_on_slot_drag_ended):
			slot.slot_drag_ended.connect(_on_slot_drag_ended)
		
		slot_container.add_child(slot)
		slots.append(slot)
	
	# Update slot displays
	_update_inventory()

func _update_inventory() -> void:
	if not inventory_data or slots.size() != inventory_data.slot_count:
		return
	
	for i in slots.size():
		if i >= inventory_data.slot_count:
			break
		var slot_data: Dictionary = inventory_data.get_slot(i)
		if i < slots.size() and slots[i] and is_instance_valid(slots[i]):
			slots[i].set_item(slot_data)

func _on_slot_clicked(slot: InventorySlot) -> void:
	# NPC inventory is read-only - prevent dragging items out
	# But allow drag-and-drop INTO NPC inventory
	if not drag_manager:
		return
	
	# If dragging from another inventory, allow drop
	if drag_manager.is_dragging:
		# Handle drop
		_handle_drop(slot)
		return
	
	# If clicking on NPC inventory slot, don't allow taking items
	pass

func _on_slot_drag_ended(slot: InventorySlot) -> void:
	# Handle drop when mouse is released over slot
	if not drag_manager or not drag_manager.is_dragging:
		return
	
	var mouse_pos: Vector2 = get_viewport().get_mouse_position()
	var slot_rect: Rect2 = Rect2(slot.get_global_rect())
	if slot_rect.has_point(mouse_pos):
		_handle_drop(slot)

func _on_drag_ended() -> void:
	# Update inventory display when drag ends
	_update_inventory()

func _handle_drop(target_slot: InventorySlot) -> void:
	if not drag_manager or not drag_manager.is_dragging or not inventory_data:
		return
	
	var dragged_item: Dictionary = drag_manager.dragged_item
	var from_slot: InventorySlot = drag_manager.from_slot
	
	if not from_slot:
		return
	
	# Check if same slot
	if target_slot == from_slot:
		return
	
	# Get target slot data
	var target_item: Dictionary = target_slot.get_item()
	
	# Swap items
	var temp: Dictionary = target_item.duplicate()
	target_slot.set_item(dragged_item)
	inventory_data.set_slot(target_slot.slot_index, dragged_item)
	
	from_slot.set_item(temp)
	# Update from inventory if it's different
	var from_inventory = _get_inventory_for_slot(from_slot)
	if from_inventory:
		from_inventory.set_slot(from_slot.slot_index, temp)
	
	drag_manager.complete_drop(target_slot)

func _get_inventory_for_slot(slot: InventorySlot) -> InventoryData:
	# Helper to find which inventory data a slot belongs to
	var parent = slot.get_parent()
	while parent:
		if parent.has_method("get") and parent.get("inventory_data"):
			return parent.get("inventory_data") as InventoryData
		parent = parent.get_parent()
	return null

func _update_panel_position() -> void:
	if not character_panel or not target_npc:
		return
	
	# Position above NPC (like NPC inventory was)
	var viewport: Viewport = get_viewport()
	if not viewport:
		return
	
	var camera: Camera2D = viewport.get_camera_2d()
	if not camera:
		return
	
	# Convert NPC world position to screen position
	var world_pos: Vector2 = target_npc.global_position
	var camera_pos: Vector2 = camera.global_position
	var viewport_size: Vector2 = viewport.get_visible_rect().size
	var screen_center: Vector2 = viewport_size / 2.0
	var relative_pos: Vector2 = world_pos - camera_pos
	var screen_pos: Vector2 = screen_center + relative_pos
	
	# Position above NPC sprite (offset upward)
	var offset_y: float = -120.0  # Above the NPC (higher than inventory was)
	
	# Convert to global position and set
	var panel_pos: Vector2 = screen_pos + Vector2(-PANEL_WIDTH / 2.0, offset_y)
	
	# Clamp to screen bounds
	panel_pos.x = clamp(panel_pos.x, 10, viewport_size.x - PANEL_WIDTH - 10)
	panel_pos.y = clamp(panel_pos.y, 10, viewport_size.y - PANEL_HEIGHT - 10)
	
	# Set position (panel is top-level, so use global position)
	character_panel.global_position = panel_pos

var _menu_open_time: float = 0.0  # Track when menu was opened to prevent immediate close

func _input(event: InputEvent) -> void:
	# Handle drag-and-drop for inventory
	if event is InputEventMouseButton and drag_manager:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and not mouse_event.pressed:
			# Mouse button released - check if dragging
			if drag_manager.is_dragging:
				# Check all slots to see if mouse is over any of them
				var mouse_pos: Vector2 = get_viewport().get_mouse_position()
				for check_slot in slots:
					var slot_rect: Rect2 = Rect2(check_slot.get_global_rect())
					if slot_rect.has_point(mouse_pos):
						_handle_drop(check_slot)
						get_viewport().set_input_as_handled()
						return
	
	# Close menu on mouse button release (simple and flexible)
	# But prevent immediate close when menu first opens (wait at least 0.1 seconds)
	if event is InputEventMouseButton and is_open:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and not mouse_event.pressed:
			# Left mouse button released - close menu if it's been open for a bit
			var time_since_open = Time.get_ticks_msec() / 1000.0 - _menu_open_time
			if time_since_open > 0.1:  # Prevent immediate close (menu opens on press, this release might be the same click)
				hide_menu()
				get_viewport().set_input_as_handled()
				return
	
	# Update position continuously while open (NPC might be moving)
	if is_open:
		_update_panel_position()

func _update_timers() -> void:
	if not timer_label or not target_npc:
		return
	
	var timer_texts: Array[String] = []
	
	# Get NPC type
	var npc_type: String = ""
	var type_val = target_npc.get("npc_type") if target_npc else null
	if type_val != null and type_val is String:
		npc_type = type_val
	
	# Show pregnancy timer for women
	if npc_type == "woman":
		var repro_comp = target_npc.get_node_or_null("ReproductionComponent")
		if repro_comp and repro_comp is ReproductionComponent:
			if repro_comp.is_pregnant and repro_comp.birth_timer > 0.0:
				var timer_seconds = int(ceil(repro_comp.birth_timer))
				timer_texts.append("Pregnant: %ds" % timer_seconds)
	
	# Show age - different handling for babies vs others
	if npc_type == "baby":
		# Babies: get age from BabyGrowthComponent (1 year = 2 seconds)
		var growth_comp = target_npc.get_node_or_null("BabyGrowthComponent")
		if growth_comp and growth_comp is BabyGrowthComponent:
			# Access growth_timer property directly
			var growth_timer_val = growth_comp.get("growth_timer") if growth_comp else null
			if growth_timer_val != null:
				var growth_timer: float = growth_timer_val as float if growth_timer_val is float else 0.0
				var age_years = int(floor(growth_timer / 2.0))  # 1 year = 2 seconds
				timer_texts.append("Age: %dy" % age_years)
	else:
		# Other NPCs: get age from age property
		var age_val = target_npc.get("age") if target_npc else null
		if age_val != null:
			var age: int = age_val as int if age_val is int else 0
			if age >= 0:  # Only show if age is valid (0+)
				timer_texts.append("Age: %dy" % age)
	
	# Update timer label
	if timer_texts.size() > 0:
		timer_label.text = "\n".join(timer_texts)
		timer_label.visible = true
	else:
		timer_label.text = ""
		timer_label.visible = false

var position_update_timer: float = 0.0
const POSITION_UPDATE_INTERVAL: float = 0.1  # Update position every 0.1 seconds

func _process(delta: float) -> void:
	if not is_open or not target_npc:
		return
	
	# Update position periodically (NPC might be moving while frozen)
	position_update_timer += delta
	if position_update_timer >= POSITION_UPDATE_INTERVAL:
		position_update_timer = 0.0
		_update_panel_position()
		
		# Update inventory display
		if inventory_data:
			_update_inventory()
		
		# Update status bars (bravery and agro change dynamically)
		_update_status_bars()
		
		# Update timers (pregnancy timer counts down, age may update)
		_update_timers()
