# Systems & Mechanics Not Yet Implemented

Condensed from `guides/future implementations/main.md` and related docs.  
**Last updated**: February 2026

---

## Player & Progression

- **Age system** – Spawn at 13, die at 101 (structure exists, not fully wired)
- **Hominid species** – 5 species at bloodline start
- **Hybridization** – 50/50 per generation
- **War Horn (H)** – Gather/herd into war party
- **Thirst** – Only hunger is in; thirst is planned
- **Stats Panel (Tab)** – Species mix, hybrid bonuses, stats

---

## Combat

- **Wounds** – RimWorld-style body-part damage
- **Healing** – Medic Hut + berry-based healing
- **Auto-healing** – Hurt NPCs path to Medic Hut
- **More weapons/armor** – Broader weapon set + armor system
- **Combat refactor** – Windup/hit/recovery, DetectionArea, Combat Scheduler, Zone A/B (see `combat_plan.md`)

---

## Buildings & Production

- **Land claim radius** – “Invisible fence” (not fully in)
- **Building upgrades** – Flag → Tower → Keep → Castle
- **Two-phase building** – Placement intent → confirm then consume resources (see `building_improvements.md`)
- **Farm** – Wool (sheep) / milk (goats)
- **Spinner** – Cloth from wool
- **Bakery** – Bread (wheat + edible)
- **Dairy** – Cheese & butter from milk
- **Armory** – Weapon crafting
- **Tailor** – Armor, backpacks, travois
- **Medic Hut** – Healing with berries
- **Storage Hut** – Extra shared storage

Living Hut, Supply Hut, Shrine, Dairy Farm exist as structures but their production/baby-pool/relic/milk roles are not fully implemented.

---

## Clan & Raiding

- **Enemy clans** – Multiple clans on map
- **Raid mechanics** – Attack enemy land claims
- **Total wipe** – Destroy enemy flag = wipe clan
- **War parties** – War Horn + herd = instant army
- **Clan Menu** – Clan management UI

---

## Reproduction & Population

- **Baby pool** – Max capacity and overflow rules
- **Surplus babies** – Become permanent AI clansmen
- **Women assignment** – 1 woman per production building
- **Birth timers** – Only run inside land-claim radius
- **Housing = clansmen cap, food = baby throttle + starvation** – Full food/housing loop (see `food.md`)

---

## World & Resources

- **Resource respawning** – Infinite (except relics), not fully in
- **Biomes** – Grass, forest, rocky, water (only basic)
- **Wild wheat** – Grows only outside land-claim radius
- **Corpse decomposition** – e.g. 60s to bones, 60s despawn

---

## NPCs & Creatures

- **Horses** – Bareback riding + travois
- **Predators** – Wolves, mammoths (hostile, lootable); design in `predator.md`

---

## Relics & Shrine

- **Relics** – Rare unique items (wilderness spawns)
- **Shrine buffs** – Place relics → permanent clan-wide buffs
- **Relic requirements** – Higher flag upgrades need relics

---

## UI

- **Character Menu** – Full NPC info (basic structure only)
- **Clan Menu** – Clan management
- **Dev Menu** – In-game dev tools (see `dev_menu.md`)

---

## Other (from other docs)

- **Day/night cycle** – AOP lower at night, torches (`daynight.md`)
- **Knapping** – See `knapping.md`
- **Grid system** – See `grid_system.md`
- **Natural movement improvements** – See `NATURAL_MOVEMENT_IMPROVEMENTS.md`
- **World systems** – See `world_systems_implementation_plan.md`

---

## Summary

**Implemented:** Core movement, melee combat, death/looting, inventory/hotbar, NPC AI (gather/eat/combat/herd), basic buildings (land claim + shells), herding, corpse system.

**Not implemented:** Full generational/permadeath, hominids/hybridization, production chains, raiding, relics/shrine, wounds/healing, predators/horses, thirst, day/night, and most of the planned UI (Stats, Character, Clan, Dev menus).
