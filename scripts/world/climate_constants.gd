class_name ClimateConstants
extends Object
## Single source of truth for climate thresholds. Shader uniforms must be set from these.

const REGIONS: PackedStringArray = ["NW", "N", "NE", "W", "CENTER", "E", "SW", "S", "SE"]

const MAX_TEMP_DELTA_PER_DAY := 0.02
const MAX_RAIN_DELTA_PER_DAY := 0.02
const SPRING_RETURN_FORCE := 0.01
const RITUAL_CAP_PER_REGION_PER_DAY := 0.015
const RITUAL_INERTIA := 0.25
const RITUAL_DECAY := 0.95

const TUNDRA_TEMP := -0.22
const SNOW_TEMP := -0.45
const DESERT_RAIN := -0.40
const WETLAND_RAIN := 0.32
const WATER_WIDEN_DIST := 0.12
const WATER_NARROW := 0.85
const FOREST_RAIN_THIN := -0.2
const CENTER_SNOW_BIAS := 0.22
const ICE_RADIUS_PER_DAY := 0.012
const ICE_RADIUS_MAX := 0.52
const TUNDRA_RING := 0.06
const OASIS_BOOST := 0.42
const PLAINS_CONVERT := -0.18
const DESERT_RIVER_KEEP := 0.14
const SEASON_COLD_AMP := 0.035
const SEASON_WET_AMP := 0.04
const DAYS_PER_YEAR := 60.0
const STRESS_CHASE := 0.35
const ICE_POP_SOFT := 0.05
const ICE_POP_HARD := 0.12
const FRONT_GRID := 256
const ICE_RING_WIDTH := 0.045
const DRY_LINE_START := 1.0
const DRY_LINE_PER_DAY := 0.022
const DRY_LINE_RECOVER := 0.022
const HYSTERESIS_RAIN := 0.14
const NEIGHBOR_MIN := 3
const RIVER_BASE_WIDTH := 0.018
