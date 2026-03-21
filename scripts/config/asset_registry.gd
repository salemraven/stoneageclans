extends Node

# Centralized texture paths and lazy loading for common NPC/building sprites.
# Use load() at runtime (preload fails when .godot/imported cache is missing).
# Centralizes paths for reuse; consider preload() once import cache exists for browser export.

# NPC sprites (player, woman, sheep, goat, baby, mammoth)
const PLAYER_PATH := "res://assets/sprites/PlayerB.png"
const WOMAN_PATH := "res://assets/sprites/woman.png"
const SHEEP_PATH := "res://assets/sprites/sheep.png"
const GOAT_PATH := "res://assets/sprites/goat.png"
const BABY_PATH := "res://assets/sprites/baby.png"
const MAMMOTH_PATH := "res://assets/sprites/mammoth.png"

# Other common sprites
const LANDCLAIM_PATH := "res://assets/sprites/landclaim.png"
const CORPSE_CAVEMAN_PATH := "res://assets/sprites/corpsecm.png"
const OVEN_COOK_PATH := "res://assets/sprites/ovencook.png"
const CAMPFIRE_PATH := "res://assets/sprites/campfire.png"
const TRAVOIS_PATH := "res://assets/sprites/travois.png"
const TREESS_PATH := "res://assets/sprites/treess.png"

# Lazy-loaded textures (cached after first access)
var _player_sprite: Texture2D
var _woman_sprite: Texture2D
var _sheep_sprite: Texture2D
var _goat_sprite: Texture2D
var _baby_sprite: Texture2D
var _mammoth_sprite: Texture2D
var _landclaim_sprite: Texture2D
var _corpse_caveman_sprite: Texture2D
var _oven_cook_sheet: Texture2D
var _campfire_sprite: Texture2D
var _travois_sprite: Texture2D
var _treess_sprite: Texture2D

func get_player_sprite() -> Texture2D:
	if not _player_sprite:
		_player_sprite = load(PLAYER_PATH) as Texture2D
	return _player_sprite

func get_woman_sprite() -> Texture2D:
	if not _woman_sprite:
		_woman_sprite = load(WOMAN_PATH) as Texture2D
	return _woman_sprite

func get_sheep_sprite() -> Texture2D:
	if not _sheep_sprite:
		_sheep_sprite = load(SHEEP_PATH) as Texture2D
	return _sheep_sprite

func get_goat_sprite() -> Texture2D:
	if not _goat_sprite:
		_goat_sprite = load(GOAT_PATH) as Texture2D
	return _goat_sprite

func get_baby_sprite() -> Texture2D:
	if not _baby_sprite:
		_baby_sprite = load(BABY_PATH) as Texture2D
	return _baby_sprite

func get_mammoth_sprite() -> Texture2D:
	if not _mammoth_sprite:
		_mammoth_sprite = load(MAMMOTH_PATH) as Texture2D
	return _mammoth_sprite

func get_landclaim_sprite() -> Texture2D:
	if not _landclaim_sprite:
		_landclaim_sprite = load(LANDCLAIM_PATH) as Texture2D
	return _landclaim_sprite

func get_corpse_caveman_sprite() -> Texture2D:
	if not _corpse_caveman_sprite:
		_corpse_caveman_sprite = load(CORPSE_CAVEMAN_PATH) as Texture2D
	return _corpse_caveman_sprite

func get_oven_cook_sheet() -> Texture2D:
	if not _oven_cook_sheet:
		_oven_cook_sheet = load(OVEN_COOK_PATH) as Texture2D
	return _oven_cook_sheet

func get_campfire_sprite() -> Texture2D:
	if not _campfire_sprite:
		_campfire_sprite = load(CAMPFIRE_PATH) as Texture2D
	return _campfire_sprite

func get_travois_sprite() -> Texture2D:
	if not _travois_sprite:
		_travois_sprite = load(TRAVOIS_PATH) as Texture2D
	return _travois_sprite

func get_treess_sprite() -> Texture2D:
	if not _treess_sprite:
		_treess_sprite = load(TREESS_PATH) as Texture2D
	return _treess_sprite
