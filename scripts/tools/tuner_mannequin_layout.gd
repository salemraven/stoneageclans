extends RefCounted
class_name TunerMannequinLayout

## Mannequin sizing in card texture space so limb presets + arms match in-game card scale.

const _Self = preload("res://scripts/tools/tuner_mannequin_layout.gd")
const PartsRegistry = preload("res://scripts/config/character_card_parts_registry.gd")

const DEFAULT_REF_HEIGHT := 816.0
const DEFAULT_DISPLAY_HEIGHT := 128.0

var ref_texture_height := DEFAULT_REF_HEIGHT
var display_height := DEFAULT_DISPLAY_HEIGHT
var sprite_scale := 1.0
var foot_y := -64.0
var feet_local_y := 408.0


static func from_body_texture(body_tex: Texture2D, registry = null):
	var layout = _Self.new()
	if body_tex != null and registry != null:
		layout.ref_texture_height = float(body_tex.get_height())
		layout.sprite_scale = registry.get_card_scale(body_tex)
		layout.foot_y = registry.get_card_foot_y(body_tex)
	elif body_tex != null:
		layout.ref_texture_height = float(body_tex.get_height())
		layout.sprite_scale = layout.display_height / layout.ref_texture_height
		layout.foot_y = -layout.display_height * 0.5
	else:
		layout.ref_texture_height = DEFAULT_REF_HEIGHT
		layout.sprite_scale = layout.display_height / layout.ref_texture_height
		layout.foot_y = -layout.display_height * 0.5
	layout.feet_local_y = layout.ref_texture_height * 0.5
	return layout


static func from_registry(registry, card_index: int = 1):
	var body_tex: Texture2D = PartsRegistry.load_blank_body()
	if body_tex != null:
		return from_body_texture(body_tex, registry)
	var layout = _Self.new()
	var tex: Texture2D = registry.get_clansmen_card(card_index) if registry else null
	if tex != null:
		layout.ref_texture_height = float(tex.get_height())
		layout.sprite_scale = registry.get_card_scale(tex)
		layout.foot_y = registry.get_card_foot_y(tex)
	else:
		layout.ref_texture_height = DEFAULT_REF_HEIGHT
		layout.sprite_scale = layout.display_height / layout.ref_texture_height
		layout.foot_y = -layout.display_height * 0.5
	layout.feet_local_y = layout.ref_texture_height * 0.5
	return layout


func display_to_local(display_px: float) -> float:
	if sprite_scale < 0.001:
		return display_px
	return display_px / sprite_scale


func local_to_display(local_px: float) -> float:
	return local_px * sprite_scale


## Body proportions (target display px, converted to card-local space).
func body_width_local() -> float:
	return display_to_local(52.0)


func body_height_local() -> float:
	return display_to_local(72.0)


func corner_radius_local() -> float:
	return display_to_local(12.0)


func head_radius_local() -> float:
	return display_to_local(20.0)


func head_gap_local() -> float:
	return display_to_local(8.0)


func head_bob_local() -> float:
	return display_to_local(2.5)
