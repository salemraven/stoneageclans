extends AcceptDialog

signal name_confirmed(clan_name: String, dye_index: int)
signal dialog_cancelled()

var name_input: LineEdit = null
var confirm_button: Button = null
var _swatches: Array[Button] = []
var dye_index := 0

var max_length := 4

func _ready() -> void:
	print("=== ClanNameDialog._ready() called ===")
	# Get nodes safely
	name_input = get_node_or_null("VBox/NameInput") as LineEdit
	confirm_button = get_node_or_null("VBox/Buttons/ConfirmButton") as Button
	
	print("  name_input: ", name_input != null)
	print("  confirm_button: ", confirm_button != null)
	
	if not name_input:
		print("ERROR: NameInput node not found in ClanNameDialog")
		# Try alternative path
		name_input = get_node_or_null("NameInput") as LineEdit
		if not name_input:
			print("ERROR: NameInput not found at alternative path either")
			return
		else:
			print("  Found NameInput at alternative path")
	
	if not confirm_button:
		print("ERROR: ConfirmButton node not found in ClanNameDialog")
		# Try alternative path
		confirm_button = get_node_or_null("ConfirmButton") as Button
		if not confirm_button:
			print("ERROR: ConfirmButton not found at alternative path either")
			return
		else:
			print("  Found ConfirmButton at alternative path")
	
	title = "What will you name your clan?"
	_build_color_row()
	name_input.max_length = max_length
	name_input.text_changed.connect(_on_text_changed)
	confirm_button.pressed.connect(_on_confirm)
	
	# Hide built-in OK/Cancel buttons - we only want the custom Confirm button
	# AcceptDialog has OK and Cancel buttons by default, hide them
	# Get the OK button (first button) and Cancel button (second button) if they exist
	call_deferred("_hide_builtin_buttons")
	
	print("  Dialog setup complete, signals connected")
	
	# Focus the input
	name_input.grab_focus()
	print("  Focus set on name_input")

func _on_text_changed(new_text: String) -> void:
	if not name_input or not confirm_button:
		return
	
	# Convert to uppercase and limit length
	var upper_text := new_text.to_upper()
	if upper_text.length() > max_length:
		upper_text = upper_text.substr(0, max_length)
	
	if upper_text != new_text:
		var caret_pos := name_input.caret_column
		name_input.text = upper_text
		name_input.caret_column = min(caret_pos, upper_text.length())
	
	# Enable/disable confirm button
	confirm_button.disabled = upper_text.length() < max_length

func _on_confirm() -> void:
	print("=== ClanNameDialog._on_confirm() called ===")
	if not name_input:
		print("  ERROR: name_input is null")
		return
	var clan_name := name_input.text.to_upper().substr(0, max_length)
	print("  Clan name: ", clan_name, " length: ", clan_name.length())
	if clan_name.length() == max_length:
		print("  Emitting name_confirmed signal with name: ", clan_name)
		name_confirmed.emit(clan_name, dye_index)
		# Close and remove dialog
		queue_free()
		print("  Dialog closed")
	else:
		print("  ERROR: Clan name length is not ", max_length, " (got ", clan_name.length(), ")")

func _on_cancel() -> void:
	dialog_cancelled.emit()
	queue_free()

func _build_color_row() -> void:
	var pcs: Node = get_node_or_null("/root/PlaceholderCardService")
	var vbox: Node = get_node_or_null("VBox")
	if pcs == null or vbox == null or not pcs.has_method("dye_option_count"):
		return
	var label := Label.new()
	label.text = "Clan color"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 6)
	var count: int = int(pcs.call("dye_option_count"))
	for i in count:
		var swatch := Button.new()
		swatch.custom_minimum_size = Vector2(28, 28)
		swatch.focus_mode = Control.FOCUS_NONE
		swatch.pressed.connect(_pick_dye.bind(i))
		row.add_child(swatch)
		_swatches.append(swatch)
	var buttons: Node = vbox.get_node_or_null("Buttons")
	vbox.add_child(label)
	vbox.add_child(row)
	if buttons:
		vbox.move_child(label, buttons.get_index())
		vbox.move_child(row, buttons.get_index())
	_refresh_swatches()


func _pick_dye(index: int) -> void:
	dye_index = index
	_refresh_swatches()


func _refresh_swatches() -> void:
	var pcs: Node = get_node_or_null("/root/PlaceholderCardService")
	if pcs == null:
		return
	for i in _swatches.size():
		var color: Color = pcs.call("dye_option_color", i)
		var box := StyleBoxFlat.new()
		box.bg_color = color
		box.set_border_width_all(3 if i == dye_index else 1)
		box.border_color = Color.WHITE if i == dye_index else Color(0.15, 0.12, 0.08)
		var swatch: Button = _swatches[i]
		for state_name in ["normal", "hover", "pressed", "focus"]:
			swatch.add_theme_stylebox_override(state_name, box)


func _hide_builtin_buttons() -> void:
	# AcceptDialog has built-in OK and Cancel buttons
	# Hide the OK button (Cancel button may not exist in AcceptDialog, only in ConfirmationDialog)
	var ok_button = get_ok_button()
	if ok_button:
		ok_button.visible = false
		ok_button.disabled = true  # Also disable to prevent interaction

func popup_at_position(_pos: Vector2) -> void:
	print("=== ClanNameDialog.popup_at_position() called ===")
	popup_centered()
	print("  Dialog popup_centered() called, visible=", visible)
