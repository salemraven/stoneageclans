# Flint Knapping Minigame in Godot 4 – Using Polygon2D for the Core

This is an updated version of the previous markdown guide, now **fully based on Polygon2D** for representing both the current core shape and the target outline. This approach makes it easier to visually show chipping, fractures, and shape changes.

## 1. Scene Structure (Polygon2D Focus)

```
KnappingMinigame (Control)
├── Background (ColorRect - semi-transparent dark overlay)
├── CoreContainer (Node2D - centered)
│   ├── CorePolygon (Polygon2D - the current stone shape)
│   ├── TargetOutline (Line2D or Polygon2D with no fill - faint target shape)
│   ├── FlakeParticles (GPUParticles2D - sparks and chip bits)
│   └── FractureLines (Line2D - red cracks on bad strikes)
├── ToolIndicator (TextureRect - shows hammerstone / billet / flaker icon)
├── ProgressBar (ProgressBar - 0–100% match to target)
├── StrikePreview (Line2D - drag arc preview)
└── UI (Control)
    ├── CancelButton (Button)
    └── StatusLabel (Label - feedback messages)
```

## 2. CorePolygon (Polygon2D) Setup

- **CorePolygon** will hold the current shape of the stone.
- **TargetOutline** is a separate Line2D or unfilled Polygon2D showing the desired final tool shape (faint gray/white).

### Initializing the Core Shape

```gdscript
# KnappingCore.gd (attach to CoreContainer)
extends Node2D

@export var core_polygon: Polygon2D
@export var target_outline: Line2D  # or Polygon2D with color & no fill
@export var flake_particles: GPUParticles2D
@export var fracture_lines: Line2D

var current_vertices: PackedVector2Array = []
var target_vertices: PackedVector2Array = []

var current_tool: String = "hammerstone"
var is_dragging: bool = false
var drag_start: Vector2 = Vector2.ZERO

var progress: float = 0.0  # 0.0 to 1.0

func _ready():
    # Example rough pebble shape for Oldowan
    current_vertices = PackedVector2Array([
        Vector2(-80, -60), Vector2(-40, -90), Vector2(30, -80),
        Vector2(90, -30), Vector2(70, 40), Vector2(20, 80),
        Vector2(-50, 70), Vector2(-90, 20)
    ])
    core_polygon.polygon = current_vertices
    core_polygon.color = Color(0.4, 0.4, 0.4)  # dark flint
    core_polygon.antialiased = true

    # Example target: rough handaxe teardrop shape
    target_vertices = PackedVector2Array([
        Vector2(0, -100), Vector2(60, -40), Vector2(80, 20),
        Vector2(60, 80), Vector2(0, 100), Vector2(-60, 80),
        Vector2(-80, 20), Vector2(-60, -40)
    ])
    target_outline.points = target_vertices + PackedVector2Array([target_vertices[0]])  # closed loop
    target_outline.width = 3
    target_outline.default_color = Color(1, 1, 1, 0.3)
```

## 3. Drag-to-Strike Logic

```gdscript
func _input(event):
    if not visible: return

    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
        if event.pressed:
            # Only start drag if near an edge/platform
            if is_near_edge(get_local_mouse_position()):
                is_dragging = true
                drag_start = get_local_mouse_position()
        else:
            if is_dragging:
                attempt_strike(drag_start, get_local_mouse_position())
            is_dragging = false
            $StrikePreview.points = []

    if event is InputEventMouseMotion and is_dragging:
        update_preview(drag_start, get_local_mouse_position())

func is_near_edge(pos: Vector2) -> bool:
    # Simple: check distance to any vertex or edge
    for v in current_vertices:
        if (pos - v).length() < 40:
            return true
    return false

func update_preview(start: Vector2, end: Vector2):
    var mid = (start + end) / 2
    var dir = (end - start).normalized()
    var strength = (end - start).length() / 150.0
    var curve_point = mid + dir.rotated(deg_to_rad(90)) * -30 * strength

    $StrikePreview.points = [start, curve_point, end]
    $StrikePreview.default_color = Color.GREEN if strength < 1.5 and strength > 0.4 else Color.RED

func attempt_strike(start_pos: Vector2, end_pos: Vector2):
    var direction = (end_pos - start_pos).normalized()
    var power = clamp((end_pos - start_pos).length() / 150.0, 0.3, 2.0)

    var quality = evaluate_strike_quality(direction, power, start_pos)

    if quality > 0.7:
        # Good strike → remove a flake
        remove_flake(start_pos, direction, power)
        progress += 0.08 + (quality * 0.12)
        flake_particles.emitting = true
        flake_particles.position = start_pos
    elif quality > 0.3:
        progress += 0.03  # minor chip
    else:
        apply_fracture(start_pos, direction)

    update_progress_visual()

    if progress >= 1.0:
        finish_tool("sharp")
    elif progress < -0.3:
        shatter_core()
```

## 4. Removing a Flake (Core Chipping)

```gdscript
func remove_flake(strike_point: Vector2, direction: Vector2, power: float):
    # Find the closest vertex to the strike point
    var closest_idx = 0
    var min_dist = INF
    for i in current_vertices.size():
        var dist = (current_vertices[i] - strike_point).length()
        if dist < min_dist:
            min_dist = dist
            closest_idx = i

    # Create a "chip" polygon: triangle or quad removed from the core
    var chip_size = 20 + power * 30
    var chip_points = [
        current_vertices[closest_idx],
        current_vertices[closest_idx] + direction * chip_size,
        current_vertices[closest_idx] + direction.rotated(deg_to_rad(60)) * chip_size * 0.7
    ]

    # Remove the chip area from the core polygon
    # Use Geometry2D.clip_polygons (subtract chip from core)
    var chip_poly = PackedVector2Array(chip_points)
    var new_polygon = Geometry2D.clip_polygons(current_vertices, chip_poly)

    if new_polygon.size() > 0:
        current_vertices = new_polygon[0]  # take the main remaining piece
        core_polygon.polygon = current_vertices
```

**Note**: `Geometry2D.clip_polygons()` returns an array of resulting polygons. For simplicity we take the first (largest) one. In a real game you might want to handle multiple resulting pieces or choose the biggest.

## 5. Fracture & Shatter

```gdscript
func apply_fracture(strike_point: Vector2, direction: Vector2):
    progress -= 0.15
    # Add a visible crack
    fracture_lines.add_point(strike_point)
    fracture_lines.add_point(strike_point + direction * 80)
    fracture_lines.default_color = Color.RED

func shatter_core():
    # Dramatic failure
    var explosion = GPUParticles2D.new()
    explosion.emitting = true
    # ... configure big shatter particles
    add_child(explosion)
    await get_tree().create_timer(1.0).timeout
    # Signal failure to main game → core lost
    queue_free()
```

## 6. Tool Switching & Progression

```gdscript
func set_tool(tool_name: String):
    current_tool = tool_name
    # Change evaluation logic based on tool
    match tool_name:
        "hammerstone":
            # Big, forgiving strikes
            pass
        "pressure_flaker":
            # Short, precise inward drags
            # Modify evaluate_strike_quality() accordingly
            pass
```

## 7. Evaluate Strike Quality (Tool-Dependent)

```gdscript
func evaluate_strike_quality(dir: Vector2, power: float, pos: Vector2) -> float:
    var ideal_angle = Vector2(1, -0.4).normalized()  # example shallow angle
    var angle_diff = abs(dir.angle_to(ideal_angle))

    var power_ok = power > 0.5 and power < 1.4 if current_tool == "hammerstone" else power < 0.6

    if angle_diff > deg_to_rad(50):
        return 0.1
    if not power_ok:
        return 0.2

    # Add more nuance: distance from platform, etc.
    return 0.7 + (1.0 - angle_diff / deg_to_rad(80))
```

## 8. Final Touches

- **Progress Visual**: Scale/tint the TargetOutline based on progress.
- **Skill Modifier**: Multiply good zone size by villager skill (e.g. 1.0 + skill * 0.3).
- **Audio**: Add AudioStreamPlayer for crunch (good), snap (bad), shatter (fail).
- **Polish**: Slight camera shake on good strikes, screen flash on shatter.

This Polygon2D-based approach gives a satisfying, evolving core shape that visibly changes as the player knaps — perfect for the grim, tactile feel of your Paleolithic game.

Start by getting the basic drag → flake removal working, then add tool switching and fracture visuals. Good luck — this will be a standout mechanic!