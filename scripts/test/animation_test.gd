extends Control

# Animation Test Scene - Test and tweak sprite sheet animations
# Run this scene independently to preview combat animations

@onready var sprite: Sprite2D = $VBox/SpriteContainer/Sprite
@onready var frame_info: Label = $VBox/FrameInfo
@onready var prev_button: Button = $VBox/Controls/PrevFrame
@onready var play_button: Button = $VBox/Controls/PlayPause
@onready var next_button: Button = $VBox/Controls/NextFrame
@onready var path_input: LineEdit = $VBox/Settings/SpriteSheetPath/PathInput
@onready var load_button: Button = $VBox/Settings/SpriteSheetPath/LoadButton
@onready var frame_count_spin: SpinBox = $VBox/Settings/FrameCount/FrameCountSpin
@onready var windup_spin: SpinBox = $VBox/Settings/Timing/WindupTime/WindupSpin
@onready var hit_spin: SpinBox = $VBox/Settings/Timing/HitDisplay/HitSpin
@onready var recovery_spin: SpinBox = $VBox/Settings/Timing/RecoveryTime/RecoverySpin
@onready var test_attack_button: Button = $VBox/TestAttack
@onready var loop_checkbox: CheckBox = $VBox/LoopCheckbox/LoopCheck

var sprite_sheet: Texture2D = null
var frame_count: int = 5
var frame_width: int = 0
var current_frame: int = 0
var is_playing: bool = false
var animation_timer: float = 0.0
var current_state: String = "IDLE"  # IDLE, WINDUP, HIT, RECOVERY

# Timing values
var windup_time: float = 0.45
var hit_display_time: float = 0.15
var recovery_time: float = 0.8

func _ready() -> void:
	print("🎬 Animation Test: _ready() called")
	
	# Wait a frame to ensure all @onready nodes are ready
	await get_tree().process_frame
	
	# Verify nodes exist
	if not sprite:
		print("❌ ERROR: Sprite node not found!")
		return
	if not path_input:
		print("❌ ERROR: PathInput node not found!")
		return
	
	print("✅ All nodes found")
	
	# Connect buttons
	prev_button.pressed.connect(_on_prev_frame)
	next_button.pressed.connect(_on_next_frame)
	play_button.pressed.connect(_on_play_pause)
	load_button.pressed.connect(_on_load_sprite_sheet)
	test_attack_button.pressed.connect(_on_test_attack)
	
	# Connect spinboxes
	frame_count_spin.value_changed.connect(_on_frame_count_changed)
	windup_spin.value_changed.connect(_on_windup_changed)
	hit_spin.value_changed.connect(_on_hit_changed)
	recovery_spin.value_changed.connect(_on_recovery_changed)
	
	# Make sprite visible
	sprite.visible = true
	print("✅ Sprite visibility set to true")
	
	# Load default sprite sheet
	print("📂 Attempting to load sprite sheet...")
	_on_load_sprite_sheet()
	
	# Update display
	_update_frame_display()
	
	# Auto-start animation after a short delay
	await get_tree().create_timer(0.5).timeout
	print("🎬 Auto-starting animation...")
	_on_test_attack()

func _process(delta: float) -> void:
	if is_playing:
		animation_timer += delta
		_update_animation_state()

func _on_load_sprite_sheet() -> void:
	if not path_input:
		print("❌ PathInput not available")
		return
		
	var path = path_input.text.strip_edges()
	if path.is_empty():
		print("⚠️ No path specified")
		frame_info.text = "⚠️ No path specified"
		return
	
	print("📂 Loading sprite sheet from: %s" % path)
	
	# Check if file exists using ResourceLoader
	if not ResourceLoader.exists(path):
		print("❌ File does not exist at path: %s" % path)
		frame_info.text = "❌ File not found: %s" % path
		sprite.texture = null
		return
	
	sprite_sheet = load(path) as Texture2D
	if sprite_sheet:
		var width = sprite_sheet.get_width()
		var height = sprite_sheet.get_height()
		print("✅ Loaded sprite sheet: %s" % path)
		print("   Dimensions: %dx%d" % [width, height])
		print("   Expected frame count: %d" % frame_count)
		
		_update_frame_width()
		
		# Validate layout
		if frame_width > 0:
			print("   Calculated frame width: %d" % frame_width)
			print("   Each frame should be: %dx%d" % [frame_width, height])
			
			# Check if dimensions make sense
			if width % frame_count != 0:
				print("⚠️ WARNING: Image width (%d) is not evenly divisible by frame count (%d)" % [width, frame_count])
				print("   This may cause frame misalignment!")
			else:
				print("   ✓ Frame width is evenly divisible")
		else:
			print("   ❌ Could not calculate frame width")
		
		_update_frame_display()
		print("✅ Sprite sheet loaded and displayed")
	else:
		print("❌ Failed to load sprite sheet: %s" % path)
		print("   Check that the file exists at this path")
		frame_info.text = "❌ Failed to load: %s" % path
		sprite.texture = null

func _on_frame_count_changed(value: float) -> void:
	frame_count = int(value)
	_update_frame_width()
	_update_frame_display()

func _on_windup_changed(value: float) -> void:
	windup_time = value

func _on_hit_changed(value: float) -> void:
	hit_display_time = value

func _on_recovery_changed(value: float) -> void:
	recovery_time = value

func _update_frame_width() -> void:
	if sprite_sheet and frame_count > 0:
		frame_width = sprite_sheet.get_width() / frame_count
		print("📐 Frame width: %d (sheet width: %d, frames: %d)" % [
			frame_width, sprite_sheet.get_width(), frame_count
		])
	else:
		frame_width = 0

func _update_frame_display() -> void:
	if not sprite:
		print("❌ Sprite node not available")
		return
		
	if not sprite_sheet or frame_width <= 0:
		sprite.texture = null
		frame_info.text = "No sprite sheet loaded"
		print("⚠️ Cannot update display: sprite_sheet=%s, frame_width=%d" % ["valid" if sprite_sheet else "null", frame_width])
		return
	
	if current_frame < 0:
		current_frame = 0
	if current_frame >= frame_count:
		current_frame = frame_count - 1
	
	# Create AtlasTexture for current frame
	var frame_x = current_frame * frame_width
	var frame_y = 0
	var frame_h = sprite_sheet.get_height()
	
	print("🎨 Updating frame display: frame=%d, x=%d, width=%d, height=%d" % [current_frame, frame_x, frame_width, frame_h])
	
	var atlas_texture = AtlasTexture.new()
	atlas_texture.atlas = sprite_sheet
	atlas_texture.region = Rect2(frame_x, frame_y, frame_width, frame_h)
	
	sprite.texture = atlas_texture
	sprite.visible = true
	
	# Update frame info
	var frame_names = ["Idle", "Windup", "Mid", "Hit", "Recovery"]
	var frame_name = frame_names[current_frame] if current_frame < frame_names.size() else "Frame %d" % current_frame
	frame_info.text = "Frame %d / %d: %s" % [current_frame, frame_count - 1, frame_name]
	
	print("✅ Frame %d displayed: %s" % [current_frame, frame_name])

func _on_prev_frame() -> void:
	current_frame -= 1
	if current_frame < 0:
		current_frame = frame_count - 1
	_update_frame_display()

func _on_next_frame() -> void:
	current_frame += 1
	if current_frame >= frame_count:
		current_frame = 0
	_update_frame_display()

func _on_play_pause() -> void:
	is_playing = !is_playing
	if is_playing:
		play_button.text = "⏸ Pause"
		animation_timer = 0.0
		current_state = "WINDUP"
		current_frame = 1  # Start at windup frame
		_update_frame_display()
	else:
		play_button.text = "▶ Play"
		current_state = "IDLE"
		current_frame = 0
		_update_frame_display()

func _update_animation_state() -> void:
	if not is_playing:
		return
	
	match current_state:
		"WINDUP":
			if animation_timer >= windup_time:
				# Switch to hit frame
				current_state = "HIT"
				current_frame = 3  # Hit frame
				animation_timer = 0.0
				_update_frame_display()
		
		"HIT":
			if animation_timer >= hit_display_time:
				# Switch to recovery frame
				current_state = "RECOVERY"
				current_frame = 4  # Recovery frame
				animation_timer = 0.0
				_update_frame_display()
		
		"RECOVERY":
			if animation_timer >= recovery_time:
				# Check if looping is enabled
				if loop_checkbox and loop_checkbox.button_pressed:
					# Loop: restart from windup
					current_state = "WINDUP"
					current_frame = 1
					animation_timer = 0.0
					_update_frame_display()
					print("🔄 Looping animation...")
				else:
					# No loop: back to idle
					current_state = "IDLE"
					current_frame = 0
					animation_timer = 0.0
					is_playing = false
					play_button.text = "▶ Play"
					_update_frame_display()
					print("⏹ Animation finished")

func _on_test_attack() -> void:
	# Reset and play full attack sequence
	is_playing = false
	animation_timer = 0.0
	current_state = "WINDUP"
	current_frame = 1
	_update_frame_display()
	
	# Start playing
	is_playing = true
	play_button.text = "⏸ Pause"
	
	print("🎬 Testing attack sequence:")
	print("   Windup: %.2fs (Frame 1)" % windup_time)
	print("   Hit: %.2fs (Frame 3)" % hit_display_time)
	print("   Recovery: %.2fs (Frame 4)" % recovery_time)
	print("   Total: %.2fs" % (windup_time + hit_display_time + recovery_time))
