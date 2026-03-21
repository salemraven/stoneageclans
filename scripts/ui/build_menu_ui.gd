extends Control
class_name BuildMenuUI

# Build Menu UI - Opens with B key when player is inside their land claim
# Shows land claim inventory (center) and building selection cards (right)

const PANEL_WIDTH := 320
const PANEL_HEIGHT := 400
const BUILDING_CARD_WIDTH := 280
const BUILDING_CARD_HEIGHT := 120

var is_open: bool = false
var land_claim: LandClaim = null  # Reference to player's land claim
var inventory_panel: Panel = null  # Center panel showing land claim inventory
var buildings_panel: Panel = null  # Right panel showing building cards
var building_cards_container: VBoxContainer = null
var building_cards: Array[Control] = []

# Reference to building inventory UI for displaying land claim inventory
var building_inventory_ui: BuildingInventoryUI = null

func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_setup_panels()

func _setup_panels() -> void:
	# Root control - full screen
	custom_minimum_size = Vector2(1280, 720)
	anchors_preset = Control.PRESET_FULL_RECT
	
	# Create building selection panel (right side)
	buildings_panel = Panel.new()
	buildings_panel.name = "BuildingsPanel"
	UITheme.apply_panel_style(buildings_panel)
	buildings_panel.custom_minimum_size = Vector2(BUILDING_CARD_WIDTH + 16, 600)  # Width + padding
	add_child(buildings_panel)
	
	# Position buildings panel on right side
	buildings_panel.anchors_preset = Control.PRESET_CENTER_RIGHT
	buildings_panel.anchor_left = 1.0
	buildings_panel.anchor_top = 0.5
	buildings_panel.anchor_right = 1.0
	buildings_panel.anchor_bottom = 0.5
	buildings_panel.offset_left = -BUILDING_CARD_WIDTH - 16 - 20  # 20px from right edge
	buildings_panel.offset_top = -300
	buildings_panel.offset_bottom = 300
	
	# MarginContainer with padding
	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	buildings_panel.add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# ScrollContainer for building cards
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.name = "ScrollContainer"
	margin.add_child(scroll)
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# Container for building cards
	building_cards_container = VBoxContainer.new()
	building_cards_container.name = "CardsContainer"
	building_cards_container.add_theme_constant_override("separation", 8)
	scroll.add_child(building_cards_container)

func setup(land_claim_ref: LandClaim, inventory_ui_ref: BuildingInventoryUI) -> void:
	land_claim = land_claim_ref
	building_inventory_ui = inventory_ui_ref
	_build_building_cards()

func _build_building_cards() -> void:
	# Clear existing cards
	for card in building_cards:
		if is_instance_valid(card):
			card.queue_free()
	building_cards.clear()
	
	# Get all buildings from registry
	var buildings = BuildingRegistry.get_all_buildings()
	
	for building_data in buildings:
		var card := _create_building_card(building_data)
		building_cards_container.add_child(card)
		building_cards.append(card)

# Update card availability when inventory changes
func _update_card_availability() -> void:
	if not land_claim or not land_claim.inventory:
		return
	
	var buildings = BuildingRegistry.get_all_buildings()
	for i in range(min(building_cards.size(), buildings.size())):
		var card = building_cards[i]
		if not is_instance_valid(card):
			continue
		
		var building = buildings[i]
		var can_afford := BuildingRegistry.can_afford_building(building, land_claim.inventory)
		
		# Update card style based on affordability
		var style := UITheme.get_panel_style()
		style.bg_color.a = 0.9
		if not can_afford:
			# Gray out if can't afford
			style.bg_color = Color(style.bg_color.r * 0.6, style.bg_color.g * 0.6, style.bg_color.b * 0.6, 0.9)
		card.add_theme_stylebox_override("panel", style)
		
		# Update cost label colors
		var cost_label := card.get_node_or_null("VBox/MarginContainer/VBoxContainer/CostLabel") as Label
		if cost_label:
			var cost_color := UITheme.COLOR_TEXT_SUCCESS if can_afford else UITheme.COLOR_TEXT_ERROR
			cost_label.add_theme_color_override("font_color", cost_color)

func _create_building_card(building: BuildingRegistry.BuildingData) -> Control:
	var card := Panel.new()
	card.custom_minimum_size = Vector2(BUILDING_CARD_WIDTH, BUILDING_CARD_HEIGHT)
	
	# Style card based on affordability
	var can_afford := false
	if land_claim and land_claim.inventory:
		can_afford = BuildingRegistry.can_afford_building(building, land_claim.inventory)
	
	var style := UITheme.get_panel_style()
	style.bg_color.a = 0.9  # Slightly more opaque
	if not can_afford:
		# Gray out if can't afford
		style.bg_color = Color(style.bg_color.r * 0.6, style.bg_color.g * 0.6, style.bg_color.b * 0.6, 0.9)
	card.add_theme_stylebox_override("panel", style)
	
	# Main container
	var vbox := VBoxContainer.new()
	card.add_child(vbox)
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	var margin := MarginContainer.new()
	margin.name = "MarginContainer"
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	vbox.add_child(margin)
	
	var content := VBoxContainer.new()
	content.name = "VBoxContainer"
	content.add_theme_constant_override("separation", 4)
	margin.add_child(content)
	
	# Icon + Name row
	var top_row := HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 8)
	content.add_child(top_row)
	
	# Icon
	var icon := TextureRect.new()
	var icon_texture := load(building.icon_path) as Texture2D
	if icon_texture:
		icon.texture = icon_texture
		icon.custom_minimum_size = Vector2(64, 64)
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	top_row.add_child(icon)
	
	# Name
	var name_label := Label.new()
	name_label.text = building.display_name
	name_label.add_theme_font_size_override("font_size", 18)
	name_label.add_theme_color_override("font_color", UITheme.COLOR_TEXT_PRIMARY)
	top_row.add_child(name_label)
	
	# Description
	var desc_label := Label.new()
	desc_label.text = building.description
	desc_label.add_theme_font_size_override("font_size", 12)
	desc_label.add_theme_color_override("font_color", UITheme.COLOR_TEXT_SECONDARY)
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(desc_label)
	
	# Cost with availability indicators
	var cost_label := Label.new()
	cost_label.name = "CostLabel"
	var cost_text := "Cost: "
	var cost_items: Array[String] = []
	var cost_color: Color = UITheme.COLOR_TEXT_SECONDARY
	
	# Check availability for each material (can_afford already declared above)
	if land_claim and land_claim.inventory:
		# Update can_afford (already declared above)
		can_afford = BuildingRegistry.can_afford_building(building, land_claim.inventory)
		cost_color = UITheme.COLOR_TEXT_SUCCESS if can_afford else UITheme.COLOR_TEXT_ERROR
		
		for material in building.cost:
			var count: int = building.cost[material]
			var resource_type := BuildingRegistry.material_name_to_type(material)
			var available_count := BuildingRegistry.count_resource_in_inventory(land_claim.inventory, resource_type)
			
			var material_text := "%d/%d %s" % [available_count, count, material.capitalize()]
			cost_items.append(material_text)
		
		cost_label.text = cost_text + ", ".join(cost_items)
		cost_label.add_theme_font_size_override("font_size", 11)
		cost_label.add_theme_color_override("font_color", cost_color)
	else:
		# Fallback if no inventory
		for material in building.cost:
			var count: int = building.cost[material]
			cost_items.append("%d %s" % [count, material.capitalize()])
		cost_label.text = cost_text + ", ".join(cost_items)
		cost_label.add_theme_font_size_override("font_size", 11)
		cost_label.add_theme_color_override("font_color", cost_color)
	
	content.add_child(cost_label)
	
	# Make card clickable
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.gui_input.connect(_on_card_clicked.bind(building))
	
	# Add hover effect
	card.mouse_entered.connect(_on_card_hovered.bind(card, true))
	card.mouse_exited.connect(_on_card_hovered.bind(card, false))
	
	return card

func _on_card_hovered(card: Panel, is_hovered: bool) -> void:
	if is_hovered:
		# Lighten background slightly on hover
		var style := UITheme.get_panel_style()
		style.bg_color.a = 0.95
		card.add_theme_stylebox_override("panel", style)
	else:
		# Return to normal
		var style := UITheme.get_panel_style()
		style.bg_color.a = 0.9
		card.add_theme_stylebox_override("panel", style)

func _on_card_clicked(event: InputEvent, building: BuildingRegistry.BuildingData) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_try_build_building(building)

func _try_build_building(building: BuildingRegistry.BuildingData) -> void:
	if not land_claim or not land_claim.inventory:
		print("BuildMenuUI: No land claim or inventory!")
		return
	
	# Check if player can afford building
	if not BuildingRegistry.can_afford_building(building, land_claim.inventory):
		var missing := BuildingRegistry.get_missing_materials(building, land_claim.inventory)
		var missing_str := ""
		for mat in missing:
			missing_str += "%d %s, " % [missing[mat], mat.capitalize()]
		missing_str = missing_str.trim_suffix(", ")
		print("BuildMenuUI: Cannot afford %s. Missing: %s" % [building.display_name, missing_str])
		return
	
	# Consume materials from land claim inventory
	if not BuildingRegistry.consume_materials(building, land_claim.inventory):
		print("BuildMenuUI: Failed to consume materials!")
		return
	
	# Add building item to player inventory
	var main: Node = get_tree().get_first_node_in_group("main")
	if not main or not main.has_method("add_building_item_to_player_inventory"):
		print("BuildMenuUI: Main doesn't have add_building_item_to_player_inventory method!")
		return
	
	main.add_building_item_to_player_inventory(building.building_type)
	
	# Update inventory display (triggers after materials consumed)
	if building_inventory_ui:
		building_inventory_ui._update_all_slots()
	
	# Update card availability after materials consumed (use call_deferred to ensure inventory updated)
	call_deferred("_update_card_availability")
	
	print("BuildMenuUI: Built %s! Item added to player inventory." % building.display_name)

func show_menu() -> void:
	if not land_claim:
		print("BuildMenuUI: Cannot show menu - no land claim!")
		return
	
	is_open = true
	visible = true
	
	# Show building inventory UI (land claim inventory in center)
	if building_inventory_ui:
		building_inventory_ui.show_inventory()
	
	# Update card availability when menu opens
	_update_card_availability()

func hide_menu() -> void:
	is_open = false
	visible = false
	
	# Hide building inventory UI
	if building_inventory_ui:
		building_inventory_ui.hide_inventory()

func toggle() -> void:
	if is_open:
		hide_menu()
	else:
		show_menu()
