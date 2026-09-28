extends Control
## Look lab: four stacked cells. Left hard, right wobbly. Not wired to Main.

@onready var _wobbly_label: Label = $WobblyLabel
@onready var _hint: Label = $Hint

var _pair := 2


func _ready() -> void:
	var strip: ColorRect = $Strip
	var mat := strip.material as ShaderMaterial
	if mat == null:
		return
	var grass: Texture2D = load("res://assets/tiles/grass1.png") as Texture2D
	if grass == null:
		grass = load("res://assets/tiles/dirtgrassbase.png") as Texture2D
	if grass:
		mat.set_shader_parameter("grass_tex", grass)
	var sand: Texture2D = load("res://assets/tiles/dirtbase.png") as Texture2D
	if sand:
		mat.set_shader_parameter("sand_tex", sand)
	_apply_pair(mat)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_S:
			_pair = 1
		elif event.keycode == KEY_N:
			_pair = 0
		elif event.keycode == KEY_F:
			_pair = 2
		else:
			return
		_apply_pair(($Strip.material) as ShaderMaterial)


func _apply_pair(mat: ShaderMaterial) -> void:
	if mat == null:
		return
	mat.set_shader_parameter("pair", _pair)
	if _pair == 1:
		_wobbly_label.text = "Wobbly grass to sand"
		_hint.text = "Bottom = grass. Top = sand. N snow, F forest."
	elif _pair == 2:
		_wobbly_label.text = "Wobbly grass to forest floor"
		_hint.text = "Bottom = grass. Top = forest floor. N snow, S sand."
	else:
		_wobbly_label.text = "Wobbly grass to snow"
		_hint.text = "Bottom = grass. Top = snow. S sand, F forest."
