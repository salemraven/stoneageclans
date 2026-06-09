# Baseline Test Settings (Before Balance Changes)

Snapshot of current values for rollback reference.

## Player Starting Items
- Land claim: 1
- Farm: 1
- Dairy: 1
- Oven: 1

## Buildings Initial Inventory
- Land claim: GRAIN 5, WOOD 5
- Farm: FIBER 5
- Dairy: FIBER 5

## Spawn Counts (Initial)
- Cavemen: 0
- Women: 8
- Sheep: 3
- Goats: 3

## Respawn
- Women: 1 every 30s
- Sheep/Goats: 1 random (sheep OR goat) every 60s

## Hunger System
- Hunger depletes; when hunger=0, health depletes (no death triggered)
- No starvation death for NPCs

## Corpse Sprite
- All use corpsecm.png (caveman corpse)

## Production Times
- Oven (oven.gd): bread 60s
- ProductionConfig: bread 15s, wool 12s, milk 12s
- Farm/Dairy use ProductionConfig (12s each)

## Food Values (hunger restore %)
- Berries: 5%
- Grain: 7%
- Meat: 10%
- Bread: 15%
- Milk: not consumable

## Reproduction
- Pregnancy (birth_timer_base): 22.5s
- Baby growth (baby_growth_time_testing): 26s

## Resources
- Cooldown: 90s after 3 gathers
- Wood: requires axe
- Stone: requires pick

## Combat
- NPCConfig.combat_disabled: false (or as configured)
