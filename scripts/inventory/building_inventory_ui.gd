extends InventoryUI
class_name BuildingInventoryUI

const CampfireScript = preload("res://scripts/campfire.gd")

# Icons for occupation slots
const WOMAN_ICON: Texture2D = preload("res://assets/sprites/woman.png")
const WOMAN_ICON_FALLBACK: Texture2D = preload("res://assets/sprites/female1.png")
const SHEEP_ICON: Texture2D = preload("res://assets/sprites/sheep.png")
const GOAT_ICON: Texture2D = preload("res://assets/sprites/goat.png")

# Building inventory: 6 slots in vertical list (matching player inventory layout exactly)
# Stacking enabled (no limit for testing), opens when near building + press I

const SLOT_COUNT := 6
const PANEL_WIDTH := 320  # Match player inventory width exactly
const PANEL_HEIGHT := 500  # Increased to accommodate building icons section
const BUILDING_ICON_SIZE := 48  # Size of building icons
const BUILDING_ICON_SPACING := 8  # Spacing between building icons

var inventory_panel: Panel = null
var inventory_container: VBoxContainer = null  # Changed from GridContainer to VBoxContainer for consistency
var buildings_container: HBoxContainer = null  # Container for building icons
var building_icons: Array[Control] = []  # Array of building icon controls
var land_claim: LandClaim = null  # Reference to land claim for checking resources
var building: BuildingBase = null  # Reference to building (for non-land-claim buildings)
var campfire: CampfireScript = null  # Reference to campfire (small base, fire on/off)
var title_label: Label = null  # Title label (for "Corpse of [NPC Name]" or building name)
var character_info_label: Label = null  # Character info label (for corpse inventories)
var is_corpse_inventory: bool = false  # Track if this is showing a corpse inventory
var corpse_npc: Node = null  # Reference to corpse NPC (if showing corpse inventory)
var title_container: HBoxContainer = null  # Container for woman icon, title, and fire button
var woman_icon: TextureRect = null  # DEPRECATED
var occupation_container: VBoxContainer = null
var woman_slot_container: HBoxContainer = null
var animal_slot_container: HBoxContainer = null
var woman_slots_ui: Array = []  # Slot controls for woman slots
var animal_slots_ui: Array = []  # Slot controls for animal slots
var fire_button: Button = null  # Fire button (right of title, for oven activation)
var production_progress: ProgressBar = null  # Production progress bar
var fire_button_audio: AudioStreamPlayer = null  # Audio player for fire button click
var clan_control_container: VBoxContainer = null  # Defend % slider for player land claims
var defend_slider: HSlider = null
var defend_label: Label = null
var campfire_upgrade_button: Button = null  # Upgrade to Land Claim (campfire) or Pickup (travois)
var campfire_upgrade_slot: Control = null  # Drop Land Claim here to upgrade (next to Living Hut)

func _ready() -> void:
	super._ready()
	set_meta("travois_ground_ref", null)  # Ensure meta exists to avoid get_meta errors
	
	# Create inventory data (6 slots, stacking enabled, no stack limit for testing) - will be replaced by setup()
	inventory_data = InventoryData.new(SLOT_COUNT, true, 999999)  # Very high stack limit for testing
	
	# Setup panel
	_setup_panel()
	
	# Build slots (use call_deferred to ensure nodes are ready)
	call_deferred("_build_slots")
	
	# Enable input processing for global mouse release detection
	set_process_input(true)
	
	# Enable process for updating progress bar
	set_process(true)
	
	# Add to group so production component can find it
	add_to_group("building_inventory_ui")
	
	# Initially hidden
	visible = false

func _setup_panel() -> void:
	if not has_node("InventoryPanel"):
		inventory_panel = Panel.new()
		inventory_panel.name = "InventoryPanel"
		add_child(inventory_panel)
	
	inventory_panel.custom_minimum_size = Vector2(PANEL_WIDTH, PANEL_HEIGHT)
	
	# Style panel using UITheme
	UITheme.apply_panel_style(inventory_panel)
	
	# Vertical container with padding (matching player inventory layout)
	if not inventory_panel.has_node("MarginContainer"):
		var margin: MarginContainer = MarginContainer.new()
		margin.name = "MarginContainer"
		margin.add_theme_constant_override("margin_left", 8)  # Matching player inventory
		margin.add_theme_constant_override("margin_top", 8)  # Matching player inventory
		margin.add_theme_constant_override("margin_right", 8)  # Matching player inventory
		margin.add_theme_constant_override("margin_bottom", 8)  # Matching player inventory
		inventory_panel.add_child(margin)
		
		# Main vertical container for inventory slots and building icons
		var main_container: VBoxContainer = VBoxContainer.new()
		main_container.name = "MainContainer"
		main_container.add_theme_constant_override("separation", 8)  # Spacing between sections
		margin.add_child(main_container)
		
		# Title container (HBoxContainer for title, fire button)
		if not title_container:
			title_container = HBoxContainer.new()
			title_container.name = "TitleContainer"
			title_container.add_theme_constant_override("separation", 8)
			main_container.add_child(title_container)
			
			# Title label (center, expands to fill space)
			title_label = Label.new()
			title_label.name = "TitleLabel"
			title_label.text = "Inventory"
			title_label.add_theme_font_size_override("font_size", 16)
			title_label.add_theme_color_override("font_color", UITheme.COLOR_TEXT_PRIMARY)
			title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			title_container.add_child(title_label)
			
			# Fire button (right, for oven activation)
			fire_button = Button.new()
			fire_button.name = "FireButton"
			fire_button.custom_minimum_size = Vector2(32, 32)
			fire_button.visible = false  # Hidden by default, shown for ovens
			# Style fire button (red background)
			var style_box = StyleBoxFlat.new()
			style_box.bg_color = Color(0.8, 0.2, 0.2)  # Red
			style_box.border_color = Color(0.6, 0.1, 0.1)
			style_box.border_width_left = 2
			style_box.border_width_right = 2
			style_box.border_width_top = 2
			style_box.border_width_bottom = 2
			fire_button.add_theme_stylebox_override("normal", style_box)
			fire_button.add_theme_stylebox_override("hover", style_box)
			fire_button.add_theme_stylebox_override("pressed", style_box)
			# Add fire icon (text or emoji for now, can be replaced with texture)
			fire_button.text = "🔥"
			fire_button.pressed.connect(_on_fire_button_pressed)
			title_container.add_child(fire_button)
			
			campfire_upgrade_button = Button.new()
			campfire_upgrade_button.name = "CampfireUpgradeButton"
			campfire_upgrade_button.text = "Upgrade"
			campfire_upgrade_button.visible = false
			campfire_upgrade_button.pressed.connect(_on_campfire_upgrade_pressed)
			title_container.add_child(campfire_upgrade_button)
			
			# Audio player for fire button
			fire_button_audio = AudioStreamPlayer.new()
			fire_button_audio.name = "FireButtonAudio"
			add_child(fire_button_audio)
			
			# Occupation slots container (woman + animal slots) - separate section below title
			occupation_container = VBoxContainer.new()
			occupation_container.name = "OccupationContainer"
			occupation_container.add_theme_constant_override("separation", 4)
			woman_slot_container = HBoxContainer.new()
			woman_slot_container.name = "WomanSlotContainer"
			woman_slot_container.add_theme_constant_override("separation", 4)
			animal_slot_container = HBoxContainer.new()
			animal_slot_container.name = "AnimalSlotContainer"
			animal_slot_container.add_theme_constant_override("separation", 4)
			occupation_container.add_child(woman_slot_container)
			occupation_container.add_child(animal_slot_container)
			occupation_container.visible = false
			main_container.add_child(occupation_container)
		
		# Production progress bar (below title, for buildings with production)
		if not production_progress:
			production_progress = ProgressBar.new()
			production_progress.name = "ProductionProgress"
			production_progress.min_value = 0.0
			production_progress.max_value = 1.0
			production_progress.value = 0.0
			production_progress.custom_minimum_size = Vector2(0, 20)
			production_progress.visible = false  # Hidden by default
			main_container.add_child(production_progress)
		
		# Clan control (Defend % slider) - for player land claims only
		if not clan_control_container:
			clan_control_container = VBoxContainer.new()
			clan_control_container.name = "ClanControlContainer"
			clan_control_container.add_theme_constant_override("separation", 4)
			clan_control_container.visible = false
			main_container.add_child(clan_control_container)
			defend_label = Label.new()
			defend_label.name = "DefendLabel"
			defend_label.text = "Defend: 0%"
			defend_label.add_theme_font_size_override("font_size", 12)
			defend_label.add_theme_color_override("font_color", UITheme.COLOR_TEXT_PRIMARY)
			clan_control_container.add_child(defend_label)
			defend_slider = HSlider.new()
			defend_slider.name = "DefendSlider"
			defend_slider.min_value = 0
			defend_slider.max_value = 100
			defend_slider.step = 1
			defend_slider.value = 0
			defend_slider.custom_minimum_size = Vector2(0, 24)
			defend_slider.value_changed.connect(_on_defend_slider_changed)
			clan_control_container.add_child(defend_slider)
		
		# Character info label (for corpse inventories - name, hominid, death info)
		if not character_info_label:
			character_info_label = Label.new()
			character_info_label.name = "CharacterInfoLabel"
			character_info_label.text = ""
			character_info_label.add_theme_font_size_override("font_size", 12)
			character_info_label.add_theme_color_override("font_color", UITheme.COLOR_TEXT_SECONDARY)
			character_info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			character_info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			character_info_label.visible = false  # Hidden by default, shown for corpses
			main_container.add_child(character_info_label)
		
		# Inventory slots container
		if not inventory_container:
			inventory_container = VBoxContainer.new()
			inventory_container.name = "SlotContainer"
			inventory_container.add_theme_constant_override("separation", 0)  # No spacing between slots (matching player inventory)
			main_container.add_child(inventory_container)
		
		# Separator line (only for land claims, not corpses)
		var separator: HSeparator = main_container.get_node_or_null("Separator")
		if not separator:
			separator = HSeparator.new()
			separator.name = "Separator"
			main_container.add_child(separator)
		
		# Building icons label (only for land claims, not corpses)
		var buildings_label: Label = main_container.get_node_or_null("BuildingsLabel")
		if not buildings_label:
			buildings_label = Label.new()
			buildings_label.name = "BuildingsLabel"
			buildings_label.text = "Buildings:"
			buildings_label.add_theme_font_size_override("font_size", 12)
			buildings_label.add_theme_color_override("font_color", UITheme.COLOR_TEXT_PRIMARY)
			main_container.add_child(buildings_label)
		
		# Building icons container (horizontal) - only for land claims
		if not buildings_container:
			buildings_container = HBoxContainer.new()
			buildings_container.name = "BuildingsContainer"
			buildings_container.add_theme_constant_override("separation", BUILDING_ICON_SPACING)
			main_container.add_child(buildings_container)
	else:
		# Panel exists - retrieve existing labels and containers
		var margin = inventory_panel.get_node_or_null("MarginContainer")
		if margin:
			var main_container = margin.get_node_or_null("MainContainer")
			if main_container:
				if not title_label:
					title_label = main_container.get_node_or_null("TitleLabel") as Label
				if not occupation_container:
					occupation_container = main_container.get_node_or_null("OccupationContainer") as VBoxContainer
					if occupation_container:
						woman_slot_container = occupation_container.get_node_or_null("WomanSlotContainer") as HBoxContainer
						animal_slot_container = occupation_container.get_node_or_null("AnimalSlotContainer") as HBoxContainer
				if not character_info_label:
					character_info_label = main_container.get_node_or_null("CharacterInfoLabel") as Label
				if not inventory_container:
					inventory_container = main_container.get_node_or_null("SlotContainer") as VBoxContainer
				if not buildings_container:
					buildings_container = main_container.get_node_or_null("BuildingsContainer") as HBoxContainer
				if not clan_control_container:
					clan_control_container = main_container.get_node_or_null("ClanControlContainer") as VBoxContainer
				if clan_control_container and not defend_slider:
					defend_slider = clan_control_container.get_node_or_null("DefendSlider") as HSlider
				if clan_control_container and not defend_label:
					defend_label = clan_control_container.get_node_or_null("DefendLabel") as Label
				if not campfire_upgrade_button and title_container:
					campfire_upgrade_button = title_container.get_node_or_null("CampfireUpgradeButton") as Button
	
	# Root control setup - match player inventory positioning exactly
	custom_minimum_size = Vector2(PANEL_WIDTH, PANEL_HEIGHT)
	anchors_preset = Control.PRESET_FULL_RECT
	anchor_left = 0.0
	anchor_top = 0.0
	anchor_right = 1.0
	anchor_bottom = 1.0
	offset_left = 0.0
	offset_top = 0.0
	offset_right = 0.0
	offset_bottom = 0.0
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Position inventory panel to left of player inventory (matching player inventory structure)
	inventory_panel.anchors_preset = Control.PRESET_CENTER
	inventory_panel.anchor_left = 0.5
	inventory_panel.anchor_top = 0.5
	inventory_panel.anchor_right = 0.5
	inventory_panel.anchor_bottom = 0.5
	inventory_panel.offset_left = -PANEL_WIDTH / 2.0 - 380  # Left of center (180px gap + 200px further left = 380px total)
	inventory_panel.offset_top = -PANEL_HEIGHT / 2.0 - 120  # Match player inventory vertical offset exactly
	inventory_panel.offset_right = PANEL_WIDTH / 2.0 - 380
	inventory_panel.offset_bottom = PANEL_HEIGHT / 2.0 - 120

func _build_slots() -> void:
	# Ensure container exists - create it if needed
	if not inventory_container:
		if inventory_panel:
			var margin = inventory_panel.get_node_or_null("MarginContainer")
			if margin:
				var main_container = margin.get_node_or_null("MainContainer")
				if main_container:
					inventory_container = main_container.get_node_or_null("SlotContainer") as VBoxContainer
					if not inventory_container:
						inventory_container = VBoxContainer.new()
						inventory_container.name = "SlotContainer"
						inventory_container.add_theme_constant_override("separation", 0)
						main_container.add_child(inventory_container)
	
	if not inventory_container:
		print("ERROR: Failed to create inventory container")
		return
	
	# Clear existing
	for slot in slots:
		if is_instance_valid(slot):
			slot.queue_free()
	slots.clear()
	
	# CRITICAL: Use actual inventory slot count, not hardcoded SLOT_COUNT
	# This fixes issues where inventory has different slot count (e.g., old 9-slot inventories)
	var actual_slot_count = inventory_data.slot_count if inventory_data else SLOT_COUNT
	
	# Create vertical list of slots (use actual slot count from inventory)
	for i in actual_slot_count:
		var slot: InventorySlot = InventorySlot.new()
		slot.slot_index = i
		slot.is_hotbar = false
		slot.can_stack = true  # Buildings can stack
		# Make slots expand horizontally to fill available width (matching player inventory)
		slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if not slot.slot_clicked.is_connected(_on_slot_clicked):
			slot.slot_clicked.connect(_on_slot_clicked)
		if not slot.slot_drag_ended.is_connected(_on_slot_drag_ended):
			slot.slot_drag_ended.connect(_on_slot_drag_ended)
		inventory_container.add_child(slot)
		slots.append(slot)
	
	# Build building icons (only if not corpse inventory)
	if not is_corpse_inventory:
		_build_building_icons()
	else:
		# Hide building icons container for corpse inventories
		_hide_building_icons()
	
	# Update display
	_update_all_slots()
	
	# Update title
	_update_title()

func setup_travois_ground(tg: Node) -> void:
	building = null
	land_claim = null
	campfire = null
	var inv = tg.get("inventory") if tg else null
	if tg and inv and inv is InventoryData:
		inventory_data = inv as InventoryData
		_build_slots()
		_hide_building_icons()
		title_label.text = "Travois"
		title_label.visible = true
		if fire_button:
			fire_button.visible = false
		if clan_control_container:
			clan_control_container.visible = false
		if occupation_container:
			occupation_container.visible = false
		set_meta("travois_ground_ref", tg)
		_update_travois_pickup_button()

func _update_travois_pickup_button() -> void:
	var tg = get_meta("travois_ground_ref") if has_meta("travois_ground_ref") else null
	if not tg or not campfire_upgrade_button:
		return
	if tg.has_method("is_empty") and tg.is_empty():
		campfire_upgrade_button.visible = true
		campfire_upgrade_button.text = "Pickup"
	else:
		campfire_upgrade_button.visible = false

func setup_campfire(campfire_ref: CampfireScript) -> void:
	building = null
	land_claim = null
	set_meta("travois_ground_ref", null)
	campfire = campfire_ref
	is_corpse_inventory = false
	corpse_npc = null
	if campfire and campfire.inventory:
		inventory_data = campfire.inventory
		_build_slots()
		_show_building_icons()
		_update_building_icon_states()
		_update_title()
		_update_campfire_fire_button()
		_update_campfire_upgrade_icon()
		var pi = get_node_or_null("/root/PlaytestInstrumentor")
		if pi and pi.has_method("campfire_opened"):
			pi.campfire_opened(campfire.clan_name, campfire.inventory.slot_count)
	else:
		print("ERROR setup_campfire: campfire or inventory is null!")

func setup_land_claim(land_claim_ref: LandClaim) -> void:
	building = null
	campfire = null
	set_meta("travois_ground_ref", null)
	land_claim = land_claim_ref
	is_corpse_inventory = false
	corpse_npc = null
	
	# DEBUG: Verify setup
	print("DEBUG setup_land_claim: land_claim=%s, building=%s" % [land_claim, building])
	
	if land_claim and land_claim.inventory:
		inventory_data = land_claim.inventory
		_build_slots()
		# Show building icons for land claims
		_show_building_icons()
		_update_building_icon_states()
		_update_title()
		_update_clan_control_display()
	else:
		print("ERROR setup_land_claim: land_claim or inventory is null!")

func setup_inventory(inventory: InventoryData, corpse_npc_ref: Node = null, building_ref: BuildingBase = null) -> void:
	# Backward compatibility method for non-land-claim buildings
	# If corpse_npc_ref is provided, this is a corpse inventory
	# If building_ref is provided, this is a regular building (Oven, etc.)
	is_corpse_inventory = (corpse_npc_ref != null)
	corpse_npc = corpse_npc_ref
	building = building_ref
	land_claim = null
	campfire = null
	set_meta("travois_ground_ref", null)
	
	# Call parent setup to ensure proper initialization
	super.setup(inventory)
	_build_slots()
	
	# Hide building icons for corpse inventories and regular buildings
	# Only show building icons for land claims (they have the build menu)
	if is_corpse_inventory or building:
		_hide_building_icons()
	elif land_claim:
		_show_building_icons()
	else:
		_hide_building_icons()
	
	# Update title based on whether this is a corpse or building
	_update_title()
	
	# Hide clan control when showing non-land-claim
	_update_clan_control_display()
	
	# Build and update occupation slots when setting up building
	if building:
		_build_occupation_slots()
		_update_occupation_slots()

func _update_title() -> void:
	if not title_label:
		return
	var tg = get_meta("travois_ground_ref") if has_meta("travois_ground_ref") else null
	print("DEBUG _update_title: is_corpse=%s, land_claim=%s, building=%s, campfire=%s, tg=%s" % [is_corpse_inventory, land_claim, building, campfire, tg])
	if tg:
		title_label.text = "Travois"
		title_label.visible = true
		if fire_button:
			fire_button.visible = false
		if campfire_upgrade_button:
			campfire_upgrade_button.visible = tg.has_method("is_empty") and tg.is_empty()
			campfire_upgrade_button.text = "Pickup"
		if clan_control_container:
			clan_control_container.visible = false
		if occupation_container:
			occupation_container.visible = false
	elif campfire:
		title_label.text = "%s's Campfire" % campfire.clan_name
		title_label.visible = true
		if campfire_upgrade_button:
			campfire_upgrade_button.visible = false
		if character_info_label:
			character_info_label.visible = false
		if fire_button:
			fire_button.visible = true
		if production_progress:
			production_progress.visible = false
		if clan_control_container:
			clan_control_container.visible = false
		if occupation_container:
			occupation_container.visible = false
	elif is_corpse_inventory and corpse_npc:
		# Show "Corpse of [NPC Name]"
		var npc_name = corpse_npc.get("npc_name") if corpse_npc else "Unknown"
		title_label.text = "Corpse of %s" % npc_name
		title_label.visible = true
		
		# Update character info for corpse
		_update_character_info()
	elif land_claim:
		# Show land claim/clan name
		var clan_name = land_claim.get("clan_name") if land_claim else ""
		if clan_name != "":
			title_label.text = "%s's Land Claim" % clan_name
		else:
			title_label.text = "Land Claim"
		title_label.visible = true
		
		# Hide character info for land claims
		if character_info_label:
			character_info_label.visible = false
		
		# CRITICAL: Hide fire button for land claims (only ovens should have it)
		if fire_button:
			fire_button.visible = false
			print("DEBUG _update_title: Hiding fire button for land claim")
		if campfire_upgrade_button:
			campfire_upgrade_button.visible = false
		
		# Hide production progress for land claims
		if production_progress:
			production_progress.visible = false
	elif building:
		# Show building name
		var building_name = ResourceData.get_resource_name(building.building_type)
		title_label.text = building_name
		title_label.visible = true
		
		# Living Hut info for housing buildings (Living Hut, Oven, Farm, Dairy)
		if character_info_label:
			var is_housing = building.building_type == ResourceData.ResourceType.LIVING_HUT or building.building_type == ResourceData.ResourceType.OVEN or building.building_type == ResourceData.ResourceType.FARM or building.building_type == ResourceData.ResourceType.DAIRY_FARM
			if is_housing:
				_update_living_hut_info()
				character_info_label.visible = true
			else:
				character_info_label.visible = false
		
		# Show fire button for production buildings (Oven, Farm, Dairy)
		if fire_button:
			var prod = building.building_type == ResourceData.ResourceType.OVEN or building.building_type == ResourceData.ResourceType.FARM or building.building_type == ResourceData.ResourceType.DAIRY_FARM
			fire_button.visible = prod
			_update_fire_button_state()
		
		# Update occupation slots
		_update_occupation_slots()
		
		# Show production progress for buildings with production
		if production_progress:
			var prod = building.building_type == ResourceData.ResourceType.OVEN or building.building_type == ResourceData.ResourceType.FARM or building.building_type == ResourceData.ResourceType.DAIRY_FARM
			production_progress.visible = prod
		
		# Update UI state
		_update_building_ui_state()
	elif inventory_data and inventory_data.has_method("get_meta"):
		# Fallback: generic building inventory
		title_label.text = "Building Inventory"
		title_label.visible = true
		
		# Hide character info for buildings
		if character_info_label:
			character_info_label.visible = false
	else:
		# Default title
		title_label.text = "Inventory"
		title_label.visible = true
		
		# Hide character info for other inventories
		if character_info_label:
			character_info_label.visible = false

func _update_character_info() -> void:
	"""Update character info label for corpse inventories"""
	if not character_info_label or not is_corpse_inventory or not corpse_npc:
		return
	
	var info_lines: Array[String] = []
	
	# NPC Name
	var npc_name = corpse_npc.get("npc_name") if corpse_npc else "Unknown"
	info_lines.append("Name: %s" % npc_name)
	
	# Hominid class/species (if available)
	var npc_type = corpse_npc.get("npc_type") if corpse_npc else ""
	if npc_type:
		info_lines.append("Type: %s" % npc_type.capitalize())
	
	# Death info (killed by)
	var killed_by = corpse_npc.get_meta("killed_by", null) if corpse_npc else null
	var death_weapon = corpse_npc.get_meta("death_weapon", ResourceData.ResourceType.NONE) if corpse_npc else ResourceData.ResourceType.NONE
	
	if killed_by and is_instance_valid(killed_by):
		var killer_name: String = ""
		var killer_clan: String = ""
		
		# Check if killer is player
		if killed_by.is_in_group("player"):
			var main: Node = get_tree().get_first_node_in_group("main")
			if main:
				var player = main.get("player") if main.has_method("get") else null
				if player and killed_by == player:
					# Get player name
					if player.has_method("get") and player.get("player_name"):
						killer_name = player.get("player_name")
					else:
						killer_name = "Player"
					
					# Get player's clan from land claim
					if main.has_method("_get_player_land_claim"):
						var player_claim = main._get_player_land_claim()
						if player_claim:
							killer_clan = player_claim.get("clan_name") if player_claim else ""
		else:
			# Killer is an NPC
			killer_name = killed_by.get("npc_name") if killed_by.has_method("get") and killed_by.get("npc_name") else "Unknown"
			killer_clan = killed_by.get("clan_name") if killed_by.has_method("get") and killed_by.get("clan_name") else ""
		
		# Format death info
		var weapon_name: String = ""
		if death_weapon != ResourceData.ResourceType.NONE:
			weapon_name = ResourceData.get_resource_name(death_weapon)
		
		var death_info: String = ""
		if killer_clan != "":
			# "Killed by: XXXX of the clan XX XXXX by Axe"
			death_info = "Killed by: %s of the clan %s" % [killer_name, killer_clan]
		else:
			# "Killed by: XXXX by Axe"
			death_info = "Killed by: %s" % killer_name
		
		if weapon_name != "":
			death_info += " by %s" % weapon_name
		
		info_lines.append(death_info)
	
	# Set text
	character_info_label.text = "\n".join(info_lines)
	character_info_label.visible = true

func _update_living_hut_info() -> void:
	"""Update Living Hut info: woman, mate, children. Empty: 'No woman assigned'."""
	if not character_info_label or not building:
		return
	var info_lines: Array[String] = []
	var woman = building.get_primary_occupant() if building.has_method("get_primary_occupant") else null
	if not woman or not is_instance_valid(woman):
		info_lines.append("No woman assigned")
		character_info_label.text = "\n".join(info_lines)
		return
	var woman_name: String = woman.get("npc_name") if woman.get("npc_name") != null else "Unknown"
	info_lines.append("Woman: %s" % woman_name)
	var mate: Node = null
	if woman.has_node("ReproductionComponent"):
		var rc = woman.get_node("ReproductionComponent")
		if rc and rc.get("current_mate") != null:
			mate = rc.current_mate
	if mate and is_instance_valid(mate):
		var mate_name: String = "Player" if mate.is_in_group("player") else (mate.get("npc_name") if mate.get("npc_name") != null else "Unknown")
		info_lines.append("Mating with: %s" % mate_name)
	else:
		info_lines.append("Mating with: —")
	var children_lines: Array[String] = []
	var all_npcs = get_tree().get_nodes_in_group("npcs")
	for n in all_npcs:
		if not is_instance_valid(n):
			continue
		var mother = n.get("mother_name") if n.get("mother_name") != null else ""
		if mother != woman_name:
			continue
		var child_name: String = n.get("npc_name") if n.get("npc_name") != null else "Unknown"
		var father_name: String = n.get("father_name") if n.get("father_name") != null else "unknown"
		var age_val = n.get("age")
		var age_str: String = str(int(age_val)) if age_val != null else "0"
		children_lines.append("%s son of %s age %s" % [child_name, father_name, age_str])
	if children_lines.size() > 0:
		info_lines.append("")
		info_lines.append("Children:")
		for line in children_lines:
			info_lines.append("  %s" % line)
	character_info_label.text = "\n".join(info_lines)

func show_inventory() -> void:
	# Update occupation slot when showing inventory
	if building:
		_update_occupation_slots()
	visible = true
	_update_title()  # Ensure title is updated when showing
	
	# CRITICAL: Verify inventory_data is set and log instance
	if not inventory_data:
		print("❌ BUILDING UI ERROR: inventory_data is NULL when showing inventory!")
		return
	
	print("🔍 BUILDING UI SHOW: inventory_data instance: %s (slot_count=%d, can_stack=%s)" % [inventory_data, inventory_data.slot_count, inventory_data.can_stack])
	
	# Log raw slots array
	print("🔍 BUILDING UI SHOW: Raw slots array: %s" % str(inventory_data.slots))
	
	_update_all_slots()
	
	# Only update building icon states if this is a land claim (not a corpse)
	if not is_corpse_inventory:
		_update_building_icon_states()
	else:
		# Hide building icons for corpse inventories
		_hide_building_icons()
	
	# Log inventory contents when opened (for verification)
	if inventory_data:
		var total_items = 0
		var item_breakdown: Dictionary = {}
		for i in range(inventory_data.slot_count):
			var slot_data = inventory_data.slots[i]
			if slot_data != null:
				var item_type = slot_data.get("type")
				var item_count = slot_data.get("count", 0)
				total_items += item_count
				if item_type != null:
					var item_name = ResourceData.get_resource_name(item_type)
					if not item_breakdown.has(item_name):
						item_breakdown[item_name] = 0
					item_breakdown[item_name] += item_count
				print("🔍 BUILDING UI SHOW: Slot %d: type=%s, count=%d" % [i, ResourceData.get_resource_name(item_type) if item_type != null else "null", item_count])
			else:
				print("🔍 BUILDING UI SHOW: Slot %d: null" % i)
		var breakdown_str: String = ""
		for item_name in item_breakdown:
			breakdown_str += "%s: %d, " % [item_name, item_breakdown[item_name]]
		breakdown_str = breakdown_str.trim_suffix(", ")
		print("📦 LAND CLAIM INVENTORY: Total items: %d | Breakdown: %s" % [total_items, breakdown_str if breakdown_str != "" else "empty"])
		for i in range(inventory_data.slot_count):
			var slot = inventory_data.slots[i]
			if slot != null:
				var item_type = slot.get("type", -1)
				var item_count = slot.get("count", 0)
				var item_name = ResourceData.get_resource_name(item_type) if item_type >= 0 else "UNKNOWN"
				print("  Slot %d: %d x %s" % [i, item_count, item_name])
	
	UnifiedLogger.log_inventory("BuildingInventoryUI opened")

func hide_inventory() -> void:
	visible = false
	
	UnifiedLogger.log_inventory("BuildingInventoryUI closed")

func _input(event: InputEvent) -> void:
	# Global mouse button release handler for drag-and-drop
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and not mouse_event.pressed:
			# Mouse button released - check if we're dragging
			if drag_manager and drag_manager.is_dragging and visible:
				var mouse_pos: Vector2 = get_viewport().get_mouse_position()
				var from_slot: InventorySlot = drag_manager.from_slot if drag_manager else null
				
				# Campfire upgrade slot: drop LANDCLAIM to upgrade (must be from player)
				if campfire and campfire_upgrade_slot and is_instance_valid(campfire_upgrade_slot):
					var slot_rect: Rect2 = Rect2(campfire_upgrade_slot.get_global_rect())
					if slot_rect.has_point(mouse_pos):
						var item_type = drag_manager.dragged_item.get("type", -1) as int
						if item_type == ResourceData.ResourceType.LANDCLAIM:
							_handle_campfire_upgrade_drop()
							get_viewport().set_input_as_handled()
							return
				
				# Check if dragging FROM this building/corpse inventory
				var dragging_from_here: bool = (from_slot != null and from_slot in slots)
				
				# Check building inventory slots (for drops TO this inventory)
				for check_slot in slots:
					var slot_rect: Rect2 = Rect2(check_slot.get_global_rect())
					if slot_rect.has_point(mouse_pos):
						# Mouse is over this slot - handle drop (may be from player inventory)
						_handle_drop(check_slot)
						get_viewport().set_input_as_handled()
						return
				
				# If dragging FROM this building/corpse inventory, check player inventory slots
				if dragging_from_here:
					var main: Node = get_tree().get_first_node_in_group("main")
					if main and main.has_method("get") and main.get("player_inventory_ui"):
						var player_ui = main.get("player_inventory_ui")
						if player_ui and player_ui.is_open:
							# Check player inventory slots
							for check_slot in player_ui.slots:
								var slot_rect: Rect2 = Rect2(check_slot.get_global_rect())
								if slot_rect.has_point(mouse_pos):
									# Dropping from building/corpse to player - explicitly call player's drop handler
									player_ui._handle_drop(check_slot)
									get_viewport().set_input_as_handled()
									return
							
							# Check hotbar slots
							for check_slot in player_ui.hotbar_slots:
								var slot_rect: Rect2 = Rect2(check_slot.get_global_rect())
								if slot_rect.has_point(mouse_pos):
									# Dropping from building/corpse to player hotbar - explicitly call player's drop handler
									player_ui._handle_drop(check_slot)
									get_viewport().set_input_as_handled()
									return
				
				# Not over any slot - end drag (only if we're the visible inventory)
				# Don't end drag here, let it be handled by the inventory that started it
				# or by main.gd for world drops

func _on_slot_drag_ended(_slot: InventorySlot) -> void:
	# This is called when mouse is released over a slot
	# The actual drop handling is done in _input() for better reliability
	pass

func _handle_campfire_upgrade_drop() -> void:
	if not campfire or not is_instance_valid(campfire) or not drag_manager or not drag_manager.is_dragging:
		return
	var main_node = get_tree().get_first_node_in_group("main")
	if not main_node or not main_node.has_method("_on_campfire_upgrade_with_landclaim"):
		return
	main_node._on_campfire_upgrade_with_landclaim(campfire)
	drag_manager.end_drag(false)
	var player_ui = main_node.get("player_inventory_ui")
	if player_ui:
		player_ui._update_all_slots()
		if player_ui.has_method("_update_hotbar_slots"):
			player_ui._update_hotbar_slots()
	_update_building_ui_state()
	_update_all_slots()

func _handle_drop(target_slot: InventorySlot) -> void:
	if not drag_manager or not drag_manager.is_dragging:
		return
	
	var dragged_item: Dictionary = drag_manager.dragged_item
	var from_slot: InventorySlot = drag_manager.from_slot
	if not from_slot:
		UnifiedLogger.log_drag_drop("Drop failed: no_from_slot", {}, UnifiedLogger.Level.DEBUG)
		return
	
	# CRITICAL: Verify inventory_data is set
	if not inventory_data:
		print("❌ BUILDING DROP ERROR: inventory_data is NULL!")
		if drag_manager:
			drag_manager.end_drag()
		return
	
	# Check if same slot
	if target_slot == from_slot:
		UnifiedLogger.log_drag_drop("Drop failed: same_slot", {}, UnifiedLogger.Level.DEBUG)
		return
	
	# Get source inventory (could be player inventory or this building inventory)
	var from_inventory: InventoryData = null
	var main: Node = get_tree().get_first_node_in_group("main")
	
	# Verify the building inventory reference matches the land claim's inventory
	if main and main.has_method("get") and main.get("nearby_building"):
		var land_claim = main.get("nearby_building")
		if land_claim and land_claim.has_method("get") and land_claim.get("inventory"):
			var land_claim_inventory = land_claim.get("inventory") as InventoryData
			if land_claim_inventory != inventory_data:
				print("⚠️ BUILDING DROP WARNING: inventory_data (%s) != land_claim.inventory (%s)!" % [inventory_data, land_claim_inventory])
				print("   - Re-syncing inventory_data to land_claim.inventory")
				inventory_data = land_claim_inventory
	
	# Check if dragging from player inventory
	if main and main.has_method("get") and main.get("player_inventory_ui"):
		var player_ui = main.get("player_inventory_ui")
		if player_ui:
			# Check if from_slot belongs to player inventory
			if from_slot in player_ui.slots or from_slot in player_ui.hotbar_slots:
				# Dragging from player inventory
				if from_slot.is_hotbar:
					from_inventory = player_ui.get_meta("hotbar_data", null) as InventoryData
				else:
					from_inventory = player_ui.inventory_data
	
	# If not from player, assume from this building inventory
	if not from_inventory:
		from_inventory = inventory_data
	
	# Target is always this building inventory
	var to_inventory: InventoryData = inventory_data
	
	if not from_inventory or not to_inventory:
		return
	
	# Get target slot data
	var target_item: Dictionary = target_slot.get_item()
	var dragged_type: ResourceData.ResourceType = dragged_item.get("type", -1) as ResourceData.ResourceType
	var dragged_count: int = dragged_item.get("count", 1) as int
	
	# First, try to stack with target slot if same type
	if not target_item.is_empty():
		var target_type: ResourceData.ResourceType = target_item.get("type", -1) as ResourceData.ResourceType
		if target_type == dragged_type and to_inventory.can_stack:
			# Same type - try to stack
			var target_count: int = target_item.get("count", 1) as int
			var total: int = target_count + dragged_count
			
			print("🔵 BUILDING DROP: Attempting to stack - target has %d, dragging %d, total would be %d (max=%d)" % [target_count, dragged_count, total, to_inventory.max_stack])
			
			if total <= to_inventory.max_stack:
				# Full stack - all dragged items fit
				target_item["count"] = total
				target_slot.set_item(target_item)
				to_inventory.set_slot(target_slot.slot_index, target_item)
				
				# Verify stacking worked
				var verify_slot = to_inventory.get_slot(target_slot.slot_index)
				var verify_count = verify_slot.get("count", 0) if not verify_slot.is_empty() else 0
				if verify_count != total:
					print("❌ BUILDING DROP ERROR: Stacking failed! Expected count %d, got %d" % [total, verify_count])
				else:
					print("✅ BUILDING DROP: Successfully stacked to %d items" % total)
				
				# Source slot is already cleared (handled in start_drag)
				# Just update display
				_update_all_slots()
				_update_fire_button_state()  # Update fire button state after inventory change
				if land_claim or campfire:
					_update_building_icon_states()
				if main and main.has_method("get") and main.get("player_inventory_ui"):
					var player_ui = main.get("player_inventory_ui")
					if player_ui:
						player_ui._update_all_slots()
						if from_slot.is_hotbar:
							player_ui._update_hotbar_slots()
				
				if drag_manager:
					drag_manager.complete_drop(target_slot)
					item_dropped.emit(dragged_item, from_slot, target_slot)
				return
			else:
				# Partial stack - some items fit
				var stack_amount: int = to_inventory.max_stack - target_count
				target_item["count"] = to_inventory.max_stack
				target_slot.set_item(target_item)
				to_inventory.set_slot(target_slot.slot_index, target_item)
				
				# Put remaining items back in source slot
				var remaining: Dictionary = dragged_item.duplicate()
				remaining["count"] = dragged_count - stack_amount
				from_slot.set_item(remaining)
				from_inventory.set_slot(from_slot.slot_index, remaining)
				
				_update_all_slots()
				_update_fire_button_state()  # Update fire button state after inventory change
				if land_claim or campfire:
					_update_building_icon_states()
				if main and main.has_method("get") and main.get("player_inventory_ui"):
					var player_ui = main.get("player_inventory_ui")
					if player_ui:
						player_ui._update_all_slots()
						if from_slot.is_hotbar:
							player_ui._update_hotbar_slots()
				
				if drag_manager:
					drag_manager.complete_drop(target_slot)
					item_dropped.emit(dragged_item, from_slot, target_slot)
				return
	
	# If target is empty, check if there's already a slot with the same item type that can be stacked
	if target_item.is_empty() and to_inventory.can_stack:
		for check_slot in slots:
			if check_slot == target_slot:
				continue
			var check_item: Dictionary = check_slot.get_item()
			if not check_item.is_empty():
				var check_type: ResourceData.ResourceType = check_item.get("type", -1) as ResourceData.ResourceType
				if check_type == dragged_type:
					# Found matching item - try to stack
					var check_count: int = check_item.get("count", 1) as int
					var total: int = check_count + dragged_count
					
					if total <= to_inventory.max_stack:
						# Full stack - all dragged items fit
						check_item["count"] = total
						check_slot.set_item(check_item)
						to_inventory.set_slot(check_slot.slot_index, check_item)
						
						# Source slot is already cleared (handled in start_drag)
						# Just update display
						_update_all_slots()
						_update_fire_button_state()  # Update fire button state after inventory change
						if land_claim or campfire:
							_update_building_icon_states()
						if main and main.has_method("get") and main.get("player_inventory_ui"):
							var player_ui = main.get("player_inventory_ui")
							if player_ui:
								player_ui._update_all_slots()
								if from_slot.is_hotbar:
									player_ui._update_hotbar_slots()
							
							if drag_manager:
								drag_manager.complete_drop(check_slot)
								item_dropped.emit(dragged_item, from_slot, check_slot)
							return
					else:
						# Partial stack - some items fit
						var stack_amount: int = to_inventory.max_stack - check_count
						check_item["count"] = to_inventory.max_stack
						check_slot.set_item(check_item)
						to_inventory.set_slot(check_slot.slot_index, check_item)
						
						# Put remaining items in target slot
						var remaining: Dictionary = dragged_item.duplicate()
						remaining["count"] = dragged_count - stack_amount
						target_slot.set_item(remaining)
						to_inventory.set_slot(target_slot.slot_index, remaining)
						
						_update_all_slots()
						_update_fire_button_state()  # Update fire button state after inventory change
						if land_claim or campfire:
							_update_building_icon_states()
						if main and main.has_method("get") and main.get("player_inventory_ui"):
							var player_ui = main.get("player_inventory_ui")
							if player_ui:
								player_ui._update_all_slots()
								if from_slot.is_hotbar:
									player_ui._update_hotbar_slots()
							
							if drag_manager:
								drag_manager.complete_drop(target_slot)
								item_dropped.emit(dragged_item, from_slot, target_slot)
							return
	
	# No stacking possible - find an empty slot instead of swapping
	# Target slot's item stays where it is, dragged item goes to empty slot
	var empty_slot: InventorySlot = null
	
	# Find first empty slot - check both UI and inventory data to ensure it's truly empty
	for check_slot in slots:
		if check_slot == from_slot:
			continue
		# Check if slot is empty in both UI and inventory data
		var slot_data = to_inventory.get_slot(check_slot.slot_index)
		if check_slot.is_empty() and (slot_data == null or slot_data.is_empty()):
			empty_slot = check_slot
			break
	
	if empty_slot:
		# Found empty slot - place dragged item there
		print("🔵 BUILDING DROP: Adding item to slot %d in building inventory" % empty_slot.slot_index)
		print("🔵 BUILDING DROP: Item type: %s, count: %d" % [ResourceData.get_resource_name(dragged_type), dragged_count])
		print("🔵 BUILDING DROP: Building inventory reference: %s (slot_count=%d)" % [to_inventory, to_inventory.slot_count if to_inventory else 0])
		
		empty_slot.set_item(dragged_item)
		to_inventory.set_slot(empty_slot.slot_index, dragged_item)
		
		# Verify the item was actually added
		var verify_slot = to_inventory.get_slot(empty_slot.slot_index)
		if verify_slot.is_empty():
			print("❌ BUILDING DROP ERROR: Item was NOT added to inventory! Slot %d is still empty!" % empty_slot.slot_index)
		else:
			print("✅ BUILDING DROP: Item successfully added to slot %d" % empty_slot.slot_index)
		
		# Ensure source slot is cleared (it should be, but verify for cross-inventory drops)
		if from_inventory != to_inventory:
			# Cross-inventory drop - ensure source is cleared if not already
			var source_slot_data = from_inventory.get_slot(from_slot.slot_index)
			if not source_slot_data.is_empty() and source_slot_data.get("type", -1) == dragged_type:
				# Source still has item - this shouldn't happen if start_drag worked, but clear it just in case
				var source_count = source_slot_data.get("count", 0)
				if source_count > dragged_count:
					# Still has items after removing dragged amount - update count
					source_slot_data["count"] = source_count - dragged_count
					from_inventory.set_slot(from_slot.slot_index, source_slot_data)
					from_slot.set_item(source_slot_data)
				else:
					# Should be empty now - clear it
					from_inventory.set_slot(from_slot.slot_index, {})
					from_slot.set_item({})
		
		# Log successful drop
		var item_type = dragged_item.get("type", -1)
		var item_name: String = ResourceData.get_resource_name(item_type) if item_type != -1 else "unknown"
		UnifiedLogger.log_drag_drop("Drop success: moved_to_empty - %s" % item_name, {
			"from_slot": from_slot.slot_index if from_slot else -1,
			"to_slot": empty_slot.slot_index if empty_slot else -1
		}, UnifiedLogger.Level.DEBUG)
		
		# Update displays
		_update_all_slots()
		_update_fire_button_state()  # Update fire button state after inventory change
		if land_claim or campfire:
			_update_building_icon_states()
		if main and main.has_method("get") and main.get("player_inventory_ui"):
			var player_ui = main.get("player_inventory_ui")
			if player_ui:
				player_ui._update_all_slots()
				if from_slot.is_hotbar:
					player_ui._update_hotbar_slots()
		
		if drag_manager:
			drag_manager.complete_drop(empty_slot)
			item_dropped.emit(dragged_item, from_slot, empty_slot)
	else:
		# No empty slot found - cancel the drop, put item back in source slot
		from_slot.set_item(dragged_item)
		from_inventory.set_slot(from_slot.slot_index, dragged_item)
		
		# Log drop failure
		UnifiedLogger.log_drag_drop("Drop failed: no_empty_slot", {}, UnifiedLogger.Level.DEBUG)
		
		# Update displays
		_update_all_slots()
		if main and main.has_method("get") and main.get("player_inventory_ui"):
			var player_ui = main.get("player_inventory_ui")
			if player_ui:
				player_ui._update_all_slots()
				if from_slot.is_hotbar:
					player_ui._update_hotbar_slots()
		
		if drag_manager:
			drag_manager.end_drag()
		
		# Update building icon states after inventory changes (if land claim or campfire exists)
		if land_claim or campfire:
			_update_building_icon_states()

func _build_building_icons() -> void:
	# Ensure buildings container exists
	if not buildings_container:
		if inventory_panel:
			var margin = inventory_panel.get_node_or_null("MarginContainer")
			if margin:
				var main_container = margin.get_node_or_null("MainContainer")
				if main_container:
					buildings_container = main_container.get_node_or_null("BuildingsContainer") as HBoxContainer
					if not buildings_container:
						buildings_container = HBoxContainer.new()
						buildings_container.name = "BuildingsContainer"
						buildings_container.add_theme_constant_override("separation", BUILDING_ICON_SPACING)
						main_container.add_child(buildings_container)
	
	if not buildings_container:
		print("ERROR: Failed to create buildings container")
		return
	
	# Clear existing icons and upgrade slot
	for icon in building_icons:
		if is_instance_valid(icon):
			icon.queue_free()
	building_icons.clear()
	if campfire_upgrade_slot and is_instance_valid(campfire_upgrade_slot):
		campfire_upgrade_slot.queue_free()
		campfire_upgrade_slot = null
	
	# Get buildings: campfire only Living Hut + upgrade slot, land claim gets all
	var buildings: Array
	if campfire:
		var hut = BuildingRegistry.get_building(ResourceData.ResourceType.LIVING_HUT)
		buildings = [hut] if hut else []
	else:
		buildings = BuildingRegistry.get_all_buildings()
	
	# Create icon for each building
	for building_data in buildings:
		var icon := _create_building_icon(building_data)
		buildings_container.add_child(icon)
		building_icons.append(icon)
	
	# Campfire: add "Upgrade to Land Claim" slot (drop LANDCLAIM item here)
	if campfire:
		_create_campfire_upgrade_slot()
	var margin_lbl = inventory_panel.get_node_or_null("MarginContainer") if inventory_panel else null
	var main_mc = margin_lbl.get_node_or_null("MainContainer") if margin_lbl else null
	var buildings_lbl = main_mc.get_node_or_null("BuildingsLabel") if main_mc else null
	if buildings_lbl:
		buildings_lbl.text = "Living Hut & Land Claim upgrade:" if campfire else "Buildings:"
	
	# Update icon states based on resource availability
	_update_building_icon_states()

func _create_building_icon(building: BuildingRegistry.BuildingData) -> Control:
	var icon_container := Panel.new()
	icon_container.custom_minimum_size = Vector2(BUILDING_ICON_SIZE, BUILDING_ICON_SIZE)
	icon_container.mouse_filter = Control.MOUSE_FILTER_STOP
	
	# Apply UI theme
	var style := UITheme.get_panel_style()
	style.bg_color.a = 0.9
	icon_container.add_theme_stylebox_override("panel", style)
	
	# Icon texture
	var icon_texture := TextureRect.new()
	var texture := load(building.icon_path) as Texture2D
	if texture:
		icon_texture.texture = texture
	else:
		# Fallback if texture doesn't load - use a placeholder or log warning
		print("WARNING: Could not load building icon: %s for %s" % [building.icon_path, building.display_name])
		# Create a simple colored rectangle as fallback
		var placeholder := ColorRect.new()
		placeholder.color = Color(0.5, 0.5, 0.5, 0.5)
		placeholder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		icon_container.add_child(placeholder)
		# Still add the texture rect (empty) for consistency
		icon_container.add_child(icon_texture)
		return icon_container
	
	icon_texture.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_texture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	icon_container.add_child(icon_texture)
	
	# Make clickable
	icon_container.gui_input.connect(_on_building_icon_clicked.bind(building))
	
	# Add hover effect
	icon_container.mouse_entered.connect(_on_icon_hovered.bind(icon_container, true))
	icon_container.mouse_exited.connect(_on_icon_hovered.bind(icon_container, false))
	
	return icon_container

func _create_campfire_upgrade_slot() -> void:
	if not buildings_container:
		return
	campfire_upgrade_slot = Panel.new()
	campfire_upgrade_slot.name = "CampfireUpgradeSlot"
	campfire_upgrade_slot.custom_minimum_size = Vector2(BUILDING_ICON_SIZE, BUILDING_ICON_SIZE)
	campfire_upgrade_slot.tooltip_text = "Upgrade to Land Claim: put 1× Cordage, Hide, Wood, Stone in campfire slots and click here — or drop a Land Claim item here."
	campfire_upgrade_slot.mouse_filter = Control.MOUSE_FILTER_STOP
	campfire_upgrade_slot.gui_input.connect(_on_campfire_upgrade_slot_gui_input)
	var style := UITheme.get_panel_style()
	style.bg_color.a = 0.85
	style.bg_color = Color(0.3, 0.5, 0.3, 0.9)  # Slightly green tint = upgrade
	campfire_upgrade_slot.add_theme_stylebox_override("panel", style)
	var icon_rect := TextureRect.new()
	var tex := load("res://assets/sprites/landclaim.png") as Texture2D
	if tex:
		icon_rect.texture = tex
	icon_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	campfire_upgrade_slot.add_child(icon_rect)
	var label := Label.new()
	label.text = "Upgrade"
	label.add_theme_font_size_override("font_size", 10)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.anchor_top = 0.7
	label.offset_top = 0
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	campfire_upgrade_slot.add_child(label)
	buildings_container.add_child(campfire_upgrade_slot)
	_refresh_campfire_upgrade_slot_style()

func _campfire_has_upgrade_materials() -> bool:
	if not campfire or not campfire.inventory:
		return false
	var inv: InventoryData = campfire.inventory
	return inv.get_count(ResourceData.ResourceType.CORDAGE) >= 1 \
		and inv.get_count(ResourceData.ResourceType.HIDE) >= 1 \
		and inv.get_count(ResourceData.ResourceType.WOOD) >= 1 \
		and inv.get_count(ResourceData.ResourceType.STONE) >= 1

func _on_campfire_upgrade_slot_gui_input(event: InputEvent) -> void:
	if not campfire or not is_instance_valid(campfire):
		return
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	if _campfire_has_upgrade_materials():
		var main_node: Node = get_tree().get_first_node_in_group("main")
		if main_node and main_node.has_method("_on_campfire_upgrade_confirmed"):
			main_node._on_campfire_upgrade_confirmed(campfire)
			_update_all_slots()
			_update_building_icon_states()
	else:
		print("Campfire: need 1× Cordage, Hide, Wood, Stone in these slots to upgrade — or drop a Land Claim on this tile.")
	accept_event()

func _refresh_campfire_upgrade_slot_style() -> void:
	if not campfire_upgrade_slot or not is_instance_valid(campfire_upgrade_slot):
		return
	var style := UITheme.get_panel_style()
	style.bg_color.a = 0.9
	if _campfire_has_upgrade_materials():
		style.bg_color = Color(0.25, 0.75, 0.35, 0.95)
	else:
		style.bg_color = Color(0.22, 0.38, 0.24, 0.75)
	campfire_upgrade_slot.add_theme_stylebox_override("panel", style)
	var tex_rect: TextureRect = null
	for c in campfire_upgrade_slot.get_children():
		if c is TextureRect:
			tex_rect = c as TextureRect
			break
	if tex_rect:
		tex_rect.modulate = Color.WHITE if _campfire_has_upgrade_materials() else Color(0.55, 0.55, 0.55, 0.85)

func _on_icon_hovered(icon: Panel, is_hovered: bool) -> void:
	if is_hovered:
		var style := UITheme.get_panel_style()
		style.bg_color.a = 0.95
		icon.add_theme_stylebox_override("panel", style)
	else:
		_update_building_icon_states()

func _on_building_icon_clicked(event: InputEvent, building: BuildingRegistry.BuildingData) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_try_build_building(building)

func _try_build_building(building: BuildingRegistry.BuildingData) -> void:
	var inv: InventoryData = land_claim.inventory if land_claim else (campfire.inventory if campfire else null)
	if not inv:
		print("BuildingInventoryUI: No land claim/campfire or inventory!")
		return
	
	# Campfire: only Living Hut allowed
	if campfire and building.building_type != ResourceData.ResourceType.LIVING_HUT:
		return
	
	# Check if player can afford building
	if not BuildingRegistry.can_afford_building(building, inv):
		var missing := BuildingRegistry.get_missing_materials(building, land_claim.inventory)
		var missing_str := ""
		for mat in missing:
			missing_str += "%d %s, " % [missing[mat], mat.capitalize()]
		missing_str = missing_str.trim_suffix(", ")
		print("BuildingInventoryUI: Cannot afford %s. Missing: %s" % [building.display_name, missing_str])
		return
	
	# Consume materials from inventory
	if not BuildingRegistry.consume_materials(building, inv):
		print("BuildingInventoryUI: Failed to consume materials!")
		return
	
	# Add building item to player inventory
	var main: Node = get_tree().get_first_node_in_group("main")
	if not main or not main.has_method("add_building_item_to_player_inventory"):
		print("BuildingInventoryUI: Main doesn't have add_building_item_to_player_inventory method!")
		return
	
	main.add_building_item_to_player_inventory(building.building_type)
	if campfire:
		var pi = get_node_or_null("/root/PlaytestInstrumentor")
		if pi and pi.has_method("campfire_building_built"):
			pi.campfire_building_built(campfire.clan_name, building.building_type)
	
	# Update inventory display
	_update_all_slots()
	_update_fire_button_state()  # Update fire button state after materials consumed
	
	# Update icon states after materials consumed
	call_deferred("_update_building_icon_states")
	
	print("BuildingInventoryUI: Built %s! Item added to player inventory." % building.display_name)

func _hide_building_icons() -> void:
	"""Hide building icons container and label for corpse inventories"""
	if not inventory_panel:
		return
	
	var margin = inventory_panel.get_node_or_null("MarginContainer")
	if not margin:
		return
	
	var main_container = margin.get_node_or_null("MainContainer")
	if not main_container:
		return
	
	# Hide separator, label, and container
	var separator = main_container.get_node_or_null("Separator")
	if separator:
		separator.visible = false
	
	var buildings_label = main_container.get_node_or_null("BuildingsLabel")
	if buildings_label:
		buildings_label.visible = false
	
	if buildings_container:
		buildings_container.visible = false

func _show_building_icons() -> void:
	"""Show building icons container and label for land claims"""
	if not inventory_panel:
		return
	
	var margin = inventory_panel.get_node_or_null("MarginContainer")
	if not margin:
		return
	
	var main_container = margin.get_node_or_null("MainContainer")
	if not main_container:
		return
	
	# Show separator, label, and container
	var separator = main_container.get_node_or_null("Separator")
	if separator:
		separator.visible = true
	
	var buildings_label = main_container.get_node_or_null("BuildingsLabel")
	if buildings_label:
		buildings_label.visible = true
	
	if buildings_container:
		buildings_container.visible = true

func _update_building_icon_states() -> void:
	if campfire:
		_update_campfire_upgrade_icon()
		# Update Living Hut icon affordability for campfire
		if campfire.inventory and building_icons.size() > 0:
			var hut = BuildingRegistry.get_building(ResourceData.ResourceType.LIVING_HUT)
			if hut:
				var can_afford := BuildingRegistry.can_afford_building(hut, campfire.inventory)
				var icon = building_icons[0] if building_icons.size() > 0 else null
				if icon and is_instance_valid(icon):
					var style := UITheme.get_panel_style()
					style.bg_color.a = 0.9
					if not can_afford:
						style.bg_color = Color(style.bg_color.r * 0.6, style.bg_color.g * 0.6, style.bg_color.b * 0.6, 0.9)
					icon.add_theme_stylebox_override("panel", style)
					var texture_rect := icon.get_child(0) as TextureRect
					if texture_rect:
						texture_rect.modulate = Color.WHITE if can_afford else Color(0.5, 0.5, 0.5, 0.7)
		return
	var tg = get_meta("travois_ground_ref") if has_meta("travois_ground_ref") else null
	if tg:
		_update_travois_pickup_button()
		return
	# Don't update building icons for corpse inventories
	if is_corpse_inventory:
		return
	
	if not land_claim or not land_claim.inventory:
		return
	
	var buildings = BuildingRegistry.get_all_buildings()
	for i in range(min(building_icons.size(), buildings.size())):
		var icon = building_icons[i]
		if not is_instance_valid(icon):
			continue
		
		var building = buildings[i]
		var can_afford := BuildingRegistry.can_afford_building(building, land_claim.inventory)
		
		# Update icon style based on affordability
		var style := UITheme.get_panel_style()
		style.bg_color.a = 0.9
		
		# Get icon texture to apply grey-out effect
		var texture_rect := icon.get_child(0) as TextureRect
		if texture_rect:
			if not can_afford:
				# Grey out: reduce saturation and brightness
				var modulate_color := Color(0.5, 0.5, 0.5, 0.7)  # Grey with reduced opacity
				texture_rect.modulate = modulate_color
			else:
				# Normal color
				texture_rect.modulate = Color.WHITE
		
		# Update panel style (slightly dimmed background for unavailable)
		if not can_afford:
			style.bg_color = Color(style.bg_color.r * 0.6, style.bg_color.g * 0.6, style.bg_color.b * 0.6, 0.9)
		icon.add_theme_stylebox_override("panel", style)

var _last_progress: float = -1.0  # Track last progress value to detect resets

func _process(_delta: float) -> void:
	# Update clan control display (defend slider) when land claim panel is visible
	if land_claim and land_claim.player_owned and visible and clan_control_container:
		_update_clan_control_display()
	# Update production progress bar if building has production
	if building and production_progress and production_progress.visible:
		var production_component = building.get_node_or_null("ProductionComponent")
		if production_component and production_component.has_method("get_craft_progress"):
			var progress = production_component.get_craft_progress()
			production_progress.value = progress
			
			# If progress reset to 0 (new craft started), refresh inventory to show new bread
			if _last_progress > 0.9 and progress < 0.1:
				# Progress just reset - refresh inventory to show newly created items
				_update_all_slots()
			_last_progress = progress
		
		# Update woman icon visibility
		# Update occupation slot
		_update_occupation_slots()

func _update_clan_control_display() -> void:
	"""Show/hide defend slider and update label. Only for player-owned land claims."""
	if not clan_control_container or not defend_label or not defend_slider:
		return
	var show_slider: bool = land_claim != null and land_claim.player_owned
	clan_control_container.visible = show_slider
	if not show_slider:
		return
	defend_slider.set_value_no_signal(int(land_claim.player_defend_ratio * 100))
	var def_count: int = land_claim.assigned_defenders.size() if land_claim else 0
	var total: int = 0
	if land_claim:
		var npcs = get_tree().get_nodes_in_group("npcs")
		for n in npcs:
			if not is_instance_valid(n):
				continue
			var nt: String = n.get("npc_type") as String if n.get("npc_type") != null else ""
			if nt != "caveman" and nt != "clansman":
				continue
			var nc: String = n.get_clan_name() if n.has_method("get_clan_name") else (n.get("clan_name") as String if n.get("clan_name") != null else "")
			if nc != land_claim.clan_name:
				continue
			if n.get("follow_is_ordered") == true:
				continue
			total += 1
	defend_label.text = "Defend: %d%% (%d defending / %d working)" % [
		int(land_claim.player_defend_ratio * 100),
		def_count,
		max(0, total - def_count)
	]

func _on_defend_slider_changed(value: float) -> void:
	if land_claim and land_claim.player_owned:
		land_claim.player_defend_ratio = value / 100.0
		# Immediately update defender quota so NPCs react without waiting for throttled _process
		land_claim._update_player_defender_quota()
		# Force FSM evaluation for all cavemen/clansmen in clan so they immediately check defend state
		_notify_clansmen_defend_quota_changed()

func _on_fire_button_pressed() -> void:
	if campfire:
		campfire.set_fire_on(not campfire.is_fire_on)
		_update_campfire_fire_button()
		var pi = get_node_or_null("/root/PlaytestInstrumentor")
		if pi and pi.has_method("campfire_fire_toggled"):
			pi.campfire_fire_toggled(campfire.clan_name, campfire.is_fire_on)
		return
	if not building:
		return
	var bt = building.building_type
	if bt != ResourceData.ResourceType.OVEN and bt != ResourceData.ResourceType.FARM and bt != ResourceData.ResourceType.DAIRY_FARM:
		return
	if not building.inventory:
		return
	var can_produce := false
	match bt:
		ResourceData.ResourceType.OVEN:
			can_produce = building.inventory.has_item(ResourceData.ResourceType.WOOD, 1) and building.inventory.has_item(ResourceData.ResourceType.GRAIN, 1)
			if not can_produce:
				print("⚠️ Cannot produce: need 1 Wood + 1 Grain")
		ResourceData.ResourceType.FARM, ResourceData.ResourceType.DAIRY_FARM:
			can_produce = building.inventory.has_item(ResourceData.ResourceType.FIBER, 1)
			if not can_produce:
				print("⚠️ Cannot produce: need 1 Fiber")
	if not can_produce:
		return
	if building.is_active:
		print("⚠️ Building is already producing - wait for current item to finish")
		return
	building.set_active(true)
	print("🔵 Fire button: Started production (will turn off when complete)")
	
	# Notify nearby women NPCs to re-evaluate their states
	_notify_npcs_of_active_building()

func _update_campfire_fire_button() -> void:
	if not campfire or not fire_button:
		return
	fire_button.text = "🔥" if campfire.is_fire_on else "❄"
	fire_button.visible = true

func _update_campfire_upgrade_icon() -> void:
	# Upgrade to Land Claim is only in the buildings row (land-claim tile): click with mats or drop Land Claim item.
	if campfire and campfire_upgrade_button:
		campfire_upgrade_button.visible = false
	_refresh_campfire_upgrade_slot_style()

func _on_campfire_upgrade_pressed() -> void:
	var tg = get_meta("travois_ground_ref") if has_meta("travois_ground_ref") else null
	if tg and is_instance_valid(tg) and tg.has_method("is_empty") and tg.is_empty():
		var main = get_tree().get_first_node_in_group("main")
		if main and main.has_method("_on_travois_pickup"):
			main._on_travois_pickup(tg)
		return
	if not campfire or not is_instance_valid(campfire):
		return
	var main = get_tree().get_first_node_in_group("main")
	if main and main.has_method("_on_campfire_upgrade_confirmed"):
		main._on_campfire_upgrade_confirmed(campfire)
	
	# Play sound (create a simple beep sound programmatically)
	_play_fire_button_sound()
	
	# Animate button (scale animation)
	_animate_fire_button()
	
	# Update building UI state (updates fire button, production progress bar visibility, etc.)
	_update_building_ui_state()
	
	# Refresh inventory display to show any changes
	_update_all_slots()
	
	print("🔵 Oven activated - producing ONE bread")

func _play_fire_button_sound() -> void:
	# Play sound feedback (can be enhanced with actual sound file)
	# For now, we'll use a simple approach - you can add an audio file later
	if fire_button_audio:
		# TODO: Load and play actual sound file (e.g., "res://assets/sounds/fire_click.ogg")
		# For now, just print - sound can be added later
		print("🔊 Fire button sound played")

func _animate_fire_button() -> void:
	if not fire_button:
		return
	
	# Create a scale animation (pulse effect)
	var tween = create_tween()
	tween.set_loops(1)
	tween.tween_property(fire_button, "scale", Vector2(1.2, 1.2), 0.1)
	tween.tween_property(fire_button, "scale", Vector2(1.0, 1.0), 0.1)

func _update_fire_button_state() -> void:
	if not fire_button or not building:
		return
	
	# Check if building has required materials (wood + grain) for activation
	var can_activate: bool = false
	if building.inventory:
		var has_wood = building.inventory.has_item(ResourceData.ResourceType.WOOD, 1)
		var has_grain = building.inventory.has_item(ResourceData.ResourceType.GRAIN, 1)
		can_activate = has_wood and has_grain
	
	# Update button appearance based on active state and material availability
	var style_box = StyleBoxFlat.new()
	if building.is_active:
		# Bright red when active
		style_box.bg_color = Color(1.0, 0.3, 0.3)
		style_box.border_color = Color(0.8, 0.1, 0.1)
		fire_button.text = "🔥"  # Fire emoji
		fire_button.disabled = false  # Can always turn off
	else:
		# Darker red when inactive
		style_box.bg_color = Color(0.6, 0.15, 0.15)
		style_box.border_color = Color(0.4, 0.05, 0.05)
		fire_button.text = "❄️"  # Snowflake emoji (off state)
		# Disable button if missing materials
		fire_button.disabled = not can_activate
		if not can_activate:
			# Gray out when disabled
			style_box.bg_color = Color(0.3, 0.3, 0.3)
			style_box.border_color = Color(0.2, 0.2, 0.2)
	
	style_box.border_width_left = 2
	style_box.border_width_right = 2
	style_box.border_width_top = 2
	style_box.border_width_bottom = 2
	fire_button.add_theme_stylebox_override("normal", style_box)
	fire_button.add_theme_stylebox_override("hover", style_box)
	fire_button.add_theme_stylebox_override("pressed", style_box)
	fire_button.add_theme_stylebox_override("disabled", style_box)

func _update_building_ui_state() -> void:
	# Update all building-related UI elements
	if not building:
		return
	
	# Update fire button state
	_update_fire_button_state()
	
	# Update occupation slot
	_update_occupation_slots()
	
	# Update production progress visibility
	if production_progress:
		var prod = building.building_type == ResourceData.ResourceType.OVEN or building.building_type == ResourceData.ResourceType.FARM or building.building_type == ResourceData.ResourceType.DAIRY_FARM
		production_progress.visible = (prod and building.is_active)

func _notify_npcs_of_active_building() -> void:
	# Notify all women NPCs in the same clan to re-evaluate their states
	# This forces them to check for the newly active building immediately
	if not building:
		print("⚠️ _notify_npcs_of_active_building: building is null")
		return
	
	var building_clan: String = building.clan_name
	if building_clan == "":
		print("⚠️ _notify_npcs_of_active_building: building has no clan_name")
		return
	
	print("🔵 _notify_npcs_of_active_building: Building '%s' activated, notifying women in clan '%s'" % [
		ResourceData.get_resource_name(building.building_type),
		building_clan
	])
	
	# Find all NPCs (use cache when main available)
	var npcs: Array = []
	var main_node = get_tree().current_scene
	if main_node and main_node.has_method("get_cached_npcs"):
		npcs = main_node.get_cached_npcs()
	else:
		npcs = get_tree().get_nodes_in_group("npcs")
	
	var notified_count = 0
	for npc in npcs:
		if not is_instance_valid(npc):
			continue
		
		var npc_name = npc.get("npc_name") if npc else "unknown"
		var npc_type = npc.get("npc_type") if npc else ""
		
		# Only notify women NPCs
		if npc_type != "woman":
			continue
		
		# Only notify NPCs in the same clan
		var npc_clan: String = ""
		if npc.has_method("get_clan_name"):
			npc_clan = npc.get_clan_name()
		else:
			if "clan_name" in npc:
				npc_clan = npc.get("clan_name")
		
		if npc_clan != building_clan:
			print("🔵 _notify_npcs: Skipping %s (clan '%s' != building clan '%s')" % [npc_name, npc_clan, building_clan])
			continue
		
		# Force FSM to re-evaluate by resetting evaluation timer
		var fsm = npc.get_node_or_null("FSM")
		if fsm and fsm.has_method("force_evaluation"):
			fsm.force_evaluation()
			notified_count += 1
			print("🔵 _notify_npcs: Forced FSM evaluation for %s (clan: %s)" % [npc_name, npc_clan])
		elif fsm:
			# Fallback: reset evaluation timer directly
			fsm.set("evaluation_timer", 0.0)
			notified_count += 1
			print("🔵 _notify_npcs: Reset evaluation timer for %s (clan: %s)" % [npc_name, npc_clan])
		else:
			print("⚠️ _notify_npcs: No FSM found for %s" % npc_name)
	
	print("🔵 _notify_npcs_of_active_building: Notified %d women NPCs" % notified_count)

func _notify_clansmen_defend_quota_changed() -> void:
	# Force FSM evaluation for cavemen/clansmen in player's clan so they immediately check defend state
	if not land_claim or not land_claim.player_owned:
		return
	var clan_name: String = land_claim.clan_name
	if clan_name.is_empty():
		return
	var npcs: Array = []
	var main_node = get_tree().current_scene
	if main_node and main_node.has_method("get_cached_npcs"):
		npcs = main_node.get_cached_npcs()
	else:
		npcs = get_tree().get_nodes_in_group("npcs")
	var notified = 0
	for npc in npcs:
		if not is_instance_valid(npc):
			continue
		var t: String = npc.get("npc_type") if npc else ""
		if t != "caveman" and t != "clansman":
			continue
		var c: String = npc.get_clan_name() if npc.has_method("get_clan_name") else str(npc.get("clan_name"))
		if c != clan_name:
			continue
		npc.remove_meta("defend_last_exit_time")  # Clear re-entry cooldown so they can defend when slider raised
		var fsm = npc.get_node_or_null("FSM")
		if fsm and fsm.has_method("force_evaluation"):
			fsm.force_evaluation()
			notified += 1
	UnifiedLogger.log_npc("Defend quota changed, forced FSM evaluation for %d cavemen/clansmen" % notified, {"clan": clan_name, "count": notified})

func _build_occupation_slots() -> void:
	if not building or not woman_slot_container or not animal_slot_container:
		return
	# Clear existing
	for c in woman_slots_ui:
		if is_instance_valid(c):
			c.queue_free()
	for c in animal_slots_ui:
		if is_instance_valid(c):
			c.queue_free()
	woman_slots_ui.clear()
	animal_slots_ui.clear()
	var w_count: int = building.get_woman_slot_count()
	var a_count: int = building.get_animal_slot_count()
	var animal_type: String = building.get_animal_type_for_building()
	for i in w_count:
		var slot = _create_npc_slot("woman", i, true)
		woman_slot_container.add_child(slot)
		woman_slots_ui.append(slot)
	for i in a_count:
		var slot = _create_npc_slot(animal_type, i, false)
		animal_slot_container.add_child(slot)
		animal_slots_ui.append(slot)
	if occupation_container:
		occupation_container.visible = (w_count > 0 or a_count > 0)

func _create_npc_slot(_npc_type: String, slot_index: int, is_woman: bool) -> Control:
	var slot = TextureRect.new()
	slot.custom_minimum_size = Vector2(32, 32)
	slot.texture_filter = TEXTURE_FILTER_NEAREST
	slot.mouse_filter = Control.MOUSE_FILTER_STOP
	slot.set_meta("slot_index", slot_index)
	slot.set_meta("is_woman", is_woman)
	# Match InventorySlot hotbar style (earthy brown, 1px border, 3px radius)
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0x2a / 255.0, 0x1f / 255.0, 0x1a / 255.0, 0.98)
	style.border_color = Color(0x8b / 255.0, 0x65 / 255.0, 0x3e / 255.0, 0.4)
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	slot.add_theme_stylebox_override("panel", style)
	var icon = TextureRect.new()
	icon.name = "Icon"
	icon.custom_minimum_size = Vector2(24, 24)
	icon.texture_filter = TEXTURE_FILTER_NEAREST
	icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.position = Vector2(4, 4)  # Center 24x24 in 32x32
	slot.add_child(icon)
	slot.gui_input.connect(_on_occupation_slot_gui_input.bind(slot_index, is_woman))
	return slot

func _on_occupation_slot_gui_input(event: InputEvent, slot_index: int, is_woman: bool) -> void:
	if not building:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			var npc = building.woman_slots[slot_index] if is_woman else building.animal_slots[slot_index]
			if npc != null and is_instance_valid(npc):
				_start_occupation_drag(slot_index, is_woman)
		else:
			_handle_npc_drop_on_occupation_slot(slot_index, is_woman)

func _start_occupation_drag(slot_index: int, is_woman: bool) -> void:
	if not building:
		return
	var slots_arr = building.woman_slots if is_woman else building.animal_slots
	if slot_index < 0 or slot_index >= slots_arr.size():
		return
	var npc = slots_arr[slot_index]
	if not npc or not is_instance_valid(npc):
		return
	var main = get_tree().get_first_node_in_group("main")
	if main:
		main.set("clicked_npc", npc)
		main.set("dragged_occupation_slot_index", slot_index)
		main.set("dragged_occupation_is_woman", is_woman)
		main.set("dragged_occupation_building", building)
		UnifiedLogger.write_log_entry("Occupation drag start (slot)", UnifiedLogger.Category.DRAG_DROP, UnifiedLogger.Level.DEBUG, {"slot": slot_index, "is_woman": is_woman})

func try_resolve_occupation_drag_release(global_pos: Vector2) -> bool:
	"""Phase 5: Resolve slot-to-slot or slot-to-map release. Returns true if handled."""
	var main = get_tree().get_first_node_in_group("main")
	if not main:
		return false
	var src_building = main.get("dragged_occupation_building") if "dragged_occupation_building" in main else null
	var src_idx = main.get("dragged_occupation_slot_index") if "dragged_occupation_slot_index" in main else -1
	var src_woman = main.get("dragged_occupation_is_woman") if "dragged_occupation_is_woman" in main else false
	if not src_building or src_idx < 0 or not (src_building is BuildingBase):
		return false
	var b: BuildingBase = src_building as BuildingBase
	# Over occupation slot? Delegate to _handle_npc_drop_on_occupation_slot
	for i in woman_slots_ui.size():
		var slot = woman_slots_ui[i]
		if slot and is_instance_valid(slot) and Rect2(slot.get_global_rect()).has_point(global_pos):
			_handle_npc_drop_on_occupation_slot(i, true)
			return true
	for i in animal_slots_ui.size():
		var slot = animal_slots_ui[i]
		if slot and is_instance_valid(slot) and Rect2(slot.get_global_rect()).has_point(global_pos):
			_handle_npc_drop_on_occupation_slot(i, false)
			return true
	# Over building panel but not a slot? Still count as "handled" if we're dragging from this building
	var panel_rect: Rect2
	if inventory_panel and is_instance_valid(inventory_panel):
		panel_rect = Rect2(inventory_panel.get_global_rect())
	else:
		panel_rect = Rect2(get_global_rect())
	if panel_rect.has_point(global_pos):
		# Release on empty area of panel - cancel drag, don't move
		OccupationDiagLogger.log("OCCUPATION_DRAG_CANCEL", {"reason": "released_on_panel", "slot": src_idx, "is_woman": src_woman})
		return true
	# Over map: OccupationSystem unassign, place NPC at cursor
	var slots_arr = b.woman_slots if src_woman else b.animal_slots
	if src_idx >= slots_arr.size():
		return true
	var npc = slots_arr[src_idx]
	if not npc or not is_instance_valid(npc):
		return true
	if not OccupationSystem:
		return true  # Consume drag but cannot process without OccupationSystem
	OccupationSystem.unassign(npc, "player_drag")
	# Position NPC at world mouse with small offset to avoid geometry
	var world_pos: Vector2 = main._get_world_mouse_position()
	npc.global_position = world_pos + Vector2(24, 0)
	OccupationDiagLogger.log("OCCUPATION_DRAG_TO_MAP", {"npc": str(npc.get("npc_name")), "type": str(npc.get("npc_type")), "slot": src_idx, "is_woman": src_woman, "pos": "%.0f,%.0f" % [world_pos.x, world_pos.y]})
	UnifiedLogger.write_log_entry("Occupation release to map", UnifiedLogger.Category.DRAG_DROP, UnifiedLogger.Level.DEBUG, {"slot": src_idx, "is_woman": src_woman})
	return true

func try_drop_npc_from_map(global_pos: Vector2, npc: Node) -> bool:
	"""Phase 4: Drop NPC from world onto an occupation slot. Returns true if successful."""
	if not building or not is_instance_valid(building):
		return false
	var npc_type: String = npc.get("npc_type") as String if npc.get("npc_type") != null else ""
	var npc_clan: String = npc.get_clan_name() if npc.has_method("get_clan_name") else (npc.get("clan_name") if "clan_name" in npc else "")
	if npc_clan != building.clan_name:
		return false
	# Check woman slots
	for i in woman_slots_ui.size():
		var slot = woman_slots_ui[i]
		if slot and is_instance_valid(slot) and Rect2(slot.get_global_rect()).has_point(global_pos):
			if npc_type != "woman":
				return false
			if OccupationSystem:
				OccupationSystem.force_assign(npc, building, i, "woman")
				_update_occupation_slots()
				UnifiedLogger.write_log_entry("Occupation drop success (map→slot)", UnifiedLogger.Category.DRAG_DROP, UnifiedLogger.Level.DEBUG, {"slot": i, "is_woman": true})
				return true
			return false
	# Check animal slots
	var want_animal := building.get_animal_type_for_building()
	for i in animal_slots_ui.size():
		var slot = animal_slots_ui[i]
		if slot and is_instance_valid(slot) and Rect2(slot.get_global_rect()).has_point(global_pos):
			if npc_type != want_animal:
				return false
			if OccupationSystem:
				OccupationSystem.force_assign(npc, building, i, "animal")
				_update_occupation_slots()
				UnifiedLogger.write_log_entry("Occupation drop success (map→slot)", UnifiedLogger.Category.DRAG_DROP, UnifiedLogger.Level.DEBUG, {"slot": i, "is_woman": false})
				return true
			return false
	return false

func _handle_npc_drop_on_occupation_slot(slot_index: int, is_woman: bool) -> void:
	if not building:
		return
	var main = get_tree().get_first_node_in_group("main")
	if not main:
		return
	var dragged_npc = main.get("clicked_npc") if "clicked_npc" in main else null
	if not dragged_npc or not is_instance_valid(dragged_npc):
		return
	# Validate drop target
	if is_woman:
		if dragged_npc.get("npc_type") != "woman":
			main.set("clicked_npc", null)
			return
	else:
		var want = building.get_animal_type_for_building()
		if dragged_npc.get("npc_type") != want:
			main.set("clicked_npc", null)
			return
	var npc_clan: String = dragged_npc.get_clan_name() if dragged_npc.has_method("get_clan_name") else (dragged_npc.get("clan_name") if "clan_name" in dragged_npc else "")
	if npc_clan != building.clan_name:
		main.set("clicked_npc", null)
		return
	if not OccupationSystem:
		main.set("clicked_npc", null)
		return  # Cannot assign without OccupationSystem
	OccupationSystem.force_assign(dragged_npc, building, slot_index, "woman" if is_woman else "animal")
	main.set("clicked_npc", null)
	main.set("dragged_occupation_slot_index", -1)
	main.set("dragged_occupation_is_woman", false)
	main.set("dragged_occupation_building", null)
	_update_occupation_slots()
	UnifiedLogger.write_log_entry("Occupation drop success (slot→slot)", UnifiedLogger.Category.DRAG_DROP, UnifiedLogger.Level.DEBUG, {"slot": slot_index, "is_woman": is_woman})

func _update_occupation_slots() -> void:
	if not occupation_container or not building or not is_instance_valid(building):
		if occupation_container:
			occupation_container.visible = false
		return
	var a_count: int = building.get_animal_slot_count()
	var w_count: int = building.get_woman_slot_count()
	occupation_container.visible = (w_count > 0 or a_count > 0)
	# Phase 1: Throttled occupation drag log (DRAG_DROP category, enabled with --debug)
	if occupation_container.visible and UnifiedLogger:
		var now: float = Time.get_ticks_msec() / 1000.0
		var last: float = get_meta("occupation_drag_log_last", 0.0) as float
		if now - last >= 2.0:
			set_meta("occupation_drag_log_last", now)
			UnifiedLogger.write_log_entry("Occupation slots visible (building=%s, w=%d a=%d)" % [ResourceData.get_resource_name(building.building_type), w_count, a_count], UnifiedLogger.Category.DRAG_DROP, UnifiedLogger.Level.DEBUG)
	for i in woman_slots_ui.size():
		var slot = woman_slots_ui[i]
		if not is_instance_valid(slot):
			continue
		var icon = slot.get_node_or_null("Icon") as TextureRect
		if not icon:
			continue
		if i < building.woman_slots.size():
			var npc = building.woman_slots[i]
			if npc != null and is_instance_valid(npc):
				icon.texture = WOMAN_ICON if WOMAN_ICON else WOMAN_ICON_FALLBACK
				icon.visible = true
			else:
				icon.texture = null
				icon.visible = false
	for i in animal_slots_ui.size():
		var slot = animal_slots_ui[i]
		if not is_instance_valid(slot):
			continue
		var icon = slot.get_node_or_null("Icon") as TextureRect
		if not icon:
			continue
		if i < building.animal_slots.size():
			var npc = building.animal_slots[i]
			var animal_type = building.get_animal_type_for_building()
			if npc != null and is_instance_valid(npc):
				icon.texture = SHEEP_ICON if animal_type == "sheep" else GOAT_ICON
				icon.visible = true
			else:
				icon.texture = null
				icon.visible = false
