# Playtest Balance Config

## Spawn Counts (Initial)
- cavemen: 4
- women: 3
- sheep: 3
- goats: 3

## Respawn (per minute)
- women: 1
- sheep: 1
- goats: 1

## Respawn Caps
- women_respawn_cap: 12 (max wild women)
- sheep_respawn_cap: 15 (max total sheep)
- goat_respawn_cap: 15 (max total goats)

## Cavemen Spawn
- spread: far (90° angles, radius 900-1200)
- caveman_spawn_radius_min: 900
- caveman_spawn_radius_max: 1200

## Caveman Respawn
- trigger: when caveman dies AND land claim destroyed (clan death / raid)
- spawn: 1 new caveman at good distance from existing claims/players

## Safety
- starvation_safety_seconds: 20 — NPCs don't die from hunger in first N seconds after spawn

## Production (seconds)
- bread_craft_time: 90
- wool_craft_time: 45
- milk_craft_time: 45

## Food Hunger Restore (%)
- berries: 5
- grain: 7
- meat: 10
- bread: 15
- milk: 6 (humans only)

## Hunger
- depletion_rate_per_min: 15 (or 20 from NPCConfig)
- slow_deplete_threshold: (optional)

## Reproduction
- pregnancy_seconds: 30
- baby_growth_seconds: 35

## Resources
- resource_cooldown_seconds: 120
- gathers_before_cooldown: 3

## Combat/Agro
- combat_disabled: false (must be off)
- agro_* values in NPCConfig for tuning

## Full Editable Values Table

| Category | Key | Default | Notes |
|----------|-----|---------|-------|
| Spawn | cavemen | 4 | |
| | women_initial | 3 | |
| | sheep_initial | 3 | |
| | goats_initial | 3 | |
| Respawn | women_per_min | 1 | |
| | sheep_per_min | 1 | |
| | goats_per_min | 1 | |
| Respawn caps | women_respawn_cap | 12 | max wild women |
| | sheep_respawn_cap | 15 | max total |
| | goat_respawn_cap | 15 | max total |
| Safety | starvation_safety_seconds | 20 | NPCs no starve |
| Production | bread_craft_time | 90 | seconds |
| | wool_craft_time | 45 | |
| | milk_craft_time | 45 | |
| Food | berries_percent | 5 | |
| | grain_percent | 7 | |
| | meat_percent | 10 | |
| | bread_percent | 15 | |
| | milk_percent | 6 | humans only |
| Hunger | depletion_rate_per_min | 15 | |
| Reproduction | pregnancy_seconds | 30 | |
| | baby_growth_seconds | 35 | |
| Resources | resource_cooldown_seconds | 120 | |
| | gathers_before_cooldown | 3 | |
| Combat | combat_disabled | false | must be off |
