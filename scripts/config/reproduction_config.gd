extends Resource
class_name ReproductionConfig

# Reproduction System Configuration
# Used by reproduction component and baby pool manager

@export var birth_timer_base: float = 15.0  # Playtest: keep in sync with BalanceConfig.pregnancy_seconds
@export var birth_cooldown: float = 10.0  # Seconds between births (halved for 2x repro test pace)
@export var baby_pool_base_capacity: int = 3  # Base capacity from land claim (no Living Huts needed initially)
@export var living_hut_capacity_bonus: int = 5  # Per Living Hut (when Living Huts are implemented)
@export var baby_growth_time_testing: float = 17.5  # Playtest: keep in sync with BalanceConfig.baby_growth_seconds
@export var baby_growth_age_normal: int = 13  # Age when baby becomes clansman (normal mode)
