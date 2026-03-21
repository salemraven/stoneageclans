extends Control

## Title screen - NEW GAME starts the game. LOAD GAME and SETTINGS disabled for now.

@onready var new_game_button: Button = $MenuContainer/VBox/NewGameButton
@onready var load_game_label: Label = $MenuContainer/VBox/LoadGameLabel
@onready var settings_label: Label = $MenuContainer/VBox/SettingsLabel

const COLOR_DIM := Color(0.5, 0.5, 0.5, 0.6)

func _ready() -> void:
	load_game_label.add_theme_color_override("font_color", COLOR_DIM)
	settings_label.add_theme_color_override("font_color", COLOR_DIM)
	new_game_button.pressed.connect(_start_game)
	new_game_button.grab_focus()

func _start_game() -> void:
	get_tree().change_scene_to_file("res://scenes/Main.tscn")
