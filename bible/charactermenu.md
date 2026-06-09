Godot Engine v4.5.1.stable.official.f62fdbde1 - https://godotengine.org
Metal 3.2 - Forward+ - Using Device #0: Apple - Apple M3 Pro (Apple9)

✓ UnifiedLogger settings applied from DebugConfig
🏆 Competition Tracker initialized (tracking deposits by resource type)
⚔️ CombatScheduler initialized
🔍 SCHEDULER: _process() enabled
Player._ready() - sprite visible: true, texture: valid, position: (0.0, 0.0)
🎨 ANIMATION: _load_attack_sprite_sheet() called
🎨 ANIMATION: Loading sprite sheet from: res://assets/sprites/swingclub.png
✅ ANIMATION: Sprite sheet loaded successfully
🎨 ANIMATION: Texture dimensions - width=840, height=560
✅ ANIMATION: Frame size: 280x280 (grid 3x2)
✅ ANIMATION: Default sprite texture stored
🔵 Main._ready(): Connected drag_ended signal to _on_drag_ended
TASK SYSTEM: Logger configured - NPC=true, INVENTORY=true, Console=true, MinLevel=DEBUG
DEBUG _update_title: is_corpse=false, land_claim=<null>, building=<null>
🔍 NPC_INVENTORY_UI: _build_slots() called
   - slot_container: SlotContainer:<VBoxContainer#97056196600>
   - Clearing existing slots (count: 0)...
   - Slots cleared
   - Creating 10 slots...
   - Creating slot 0...
   - Slot 0 created and added
   - Creating slot 1...
   - Slot 1 created and added
   - Creating slot 2...
   - Slot 2 created and added
   - Creating slot 3...
   - Slot 3 created and added
   - Creating slot 4...
   - Slot 4 created and added
   - Creating slot 5...
   - Slot 5 created and added
   - Creating slot 6...
   - Slot 6 created and added
   - Creating slot 7...
   - Slot 7 created and added
   - Creating slot 8...
   - Slot 8 created and added
   - Creating slot 9...
   - Slot 9 created and added
   - All slots created (total: 10)
   - Calling _update_all_slots()...
✅ NPC_INVENTORY_UI: _build_slots() completed
TASK SYSTEM LOGGER: Called at time 1.0
[2026-02-16T13:24:18] [INFO] [NPC] ═══════════════════════════════════════════════════════
[2026-02-16T13:24:18] [INFO] [NPC] === TASK SYSTEM LOG: 0 Women ===
[2026-02-16T13:24:18] [INFO] [INVENTORY] === TASK SYSTEM LOG: 0 Land Claims ===
[2026-02-16T13:24:18] [INFO] [INVENTORY] TASK SYSTEM DEBUG: buildings group=0, with building_type=0, ovens=0
[2026-02-16T13:24:18] [INFO] [INVENTORY] === TASK SYSTEM LOG: 0 Ovens ===
[2026-02-16T13:24:18] [INFO] [NPC] SUMMARY: 0 women, 0 land claims, 0 ovens (0 occupied)
[2026-02-16T13:24:18] [INFO] [NPC] ═══════════════════════════════════════════════════════
Spawning 0 cavemen
Spawning 8 women
🎨 ANIMATION: _load_attack_sprite_sheet() called
🎨 ANIMATION: Loading sprite sheet from: res://assets/sprites/swingclub.png
✅ ANIMATION: Sprite sheet loaded successfully
🎨 ANIMATION: Texture dimensions - width=840, height=560
✅ ANIMATION: Frame size: 280x280 (grid 3x2)
✅ ANIMATION: Default sprite texture stored
FSM: Creating states for WUYA - idle:OK wander:OK seek:OK eat:OK gather:OK herd:OK herd_wildnpc:OK agro:OK build:OK
FSM: Successfully created eat state for WUYA
FSM: Successfully created gather state for WUYA
FSM: Successfully created herd state for WUYA
FSM: Successfully created herd_wildnpc state for WUYA
FSM: Successfully created agro state for WUYA
FSM: Successfully created combat state for WUYA
FSM: Successfully created defend state for WUYA
FSM: Successfully created raid state for WUYA
FSM: Successfully created search state for WUYA
FSM: Successfully created build state for WUYA
FSM: Successfully created reproduction state for WUYA
FSM: Successfully created occupy_building state for WUYA
FSM: Successfully created work_at_building state for WUYA
FSM: Successfully created craft state for WUYA
Task System: Created TaskRunner component for WUYA
[2026-02-16T13:24:18] [INFO] [NPC] NPC initialized at (0.0, 0.0) (sprite: found) npc=WUYA pos=0.0,0.0 sprite=found
[2026-02-16T13:24:18] [INFO] [NPC] NPC inventory initialized: 10 slots (started with 1 berry) npc=WUYA slot_count=10 starting_item=berries
Spawning 40 ground items across map (radius: 2000) around position: (0.0, 0.0)
Ground items spawned!
Starting items added: 1 Land Claim, 1 Farm, 1 Dairy
[2026-02-16T13:24:18] [DEBUG] [NPC] Hunger changed: 100.0% → 100.0% (depletion) npc=WUYA old_hunger=100.0% new_hunger=100.0% change=-0.0% reason=depletion deplete_rate=1.00/min
[2026-02-16T13:24:18] [DEBUG] [NPC] Steering behavior: WANDER - center npc=WUYA behavior=WANDER target=center position=80.2,499.3 radius=300.0
[2026-02-16T13:24:18] [INFO] [NPC] POSITION: WUYA at (80.2, 499.3), state=wander, distance_to_claim=0.0/400.0, velocity=20.0 npc=WUYA pos=80.2,499.3 state=wander distance_to_claim=0.0 claim_radius=400.0 velocity=20.0
[2026-02-16T13:24:18] [DEBUG] [NPC] Can enter check: WUYA cannot enter agro (not_caveman) npc=WUYA state=agro can_enter=false reason=not_caveman npc_type=woman
[2026-02-16T13:24:18] [DEBUG] [NPC] Priority eval: WUYA - agro (priority=15.0, can_enter=false) npc=WUYA state=agro priority=15.0 can_enter=false
[2026-02-16T13:24:18] [DEBUG] [NPC] Priority eval: WUYA - combat (priority=12.0, can_enter=false) npc=WUYA state=combat priority=12.0 can_enter=false
[2026-02-16T13:24:18] [DEBUG] [NPC] Can enter check: WUYA cannot enter herd (not_herded) npc=WUYA state=herd can_enter=false reason=not_herded herder=unknown
[2026-02-16T13:24:18] [DEBUG] [NPC] Priority eval: WUYA - herd (priority=11.0, can_enter=false) npc=WUYA state=herd priority=11.0 can_enter=false
✓ Spawned Woman: WUYA at (80.22551, 499.301) (agility 9.0 = 288.0 speed)
🎨 ANIMATION: _load_attack_sprite_sheet() called
🎨 ANIMATION: Loading sprite sheet from: res://assets/sprites/swingclub.png
✅ ANIMATION: Sprite sheet loaded successfully
🎨 ANIMATION: Texture dimensions - width=840, height=560
✅ ANIMATION: Frame size: 280x280 (grid 3x2)
✅ ANIMATION: Default sprite texture stored
FSM: Creating states for PUIK - idle:OK wander:OK seek:OK eat:OK gather:OK herd:OK herd_wildnpc:OK agro:OK build:OK
FSM: Successfully created eat state for PUIK
FSM: Successfully created gather state for PUIK
FSM: Successfully created herd state for PUIK
FSM: Successfully created herd_wildnpc state for PUIK
FSM: Successfully created agro state for PUIK
FSM: Successfully created combat state for PUIK
FSM: Successfully created defend state for PUIK
FSM: Successfully created raid state for PUIK
FSM: Successfully created search state for PUIK
FSM: Successfully created build state for PUIK
FSM: Successfully created reproduction state for PUIK
FSM: Successfully created occupy_building state for PUIK
FSM: Successfully created work_at_building state for PUIK
FSM: Successfully created craft state for PUIK
Task System: Created TaskRunner component for PUIK
TASK SYSTEM LOGGER: Called at time 1.2
[2026-02-16T13:24:18] [INFO] [INVENTORY] === TASK SYSTEM LOG: 0 Land Claims ===
[2026-02-16T13:24:18] [INFO] [INVENTORY] TASK SYSTEM DEBUG: buildings group=0, with building_type=0, ovens=0
[2026-02-16T13:24:18] [INFO] [INVENTORY] === TASK SYSTEM LOG: 0 Ovens ===
✓ Spawned Woman: PUIK at (683.0189, 296.2405) (agility 9.0 = 288.0 speed)
🎨 ANIMATION: _load_attack_sprite_sheet() called
🎨 ANIMATION: Loading sprite sheet from: res://assets/sprites/swingclub.png
✅ ANIMATION: Sprite sheet loaded successfully
🎨 ANIMATION: Texture dimensions - width=840, height=560
✅ ANIMATION: Frame size: 280x280 (grid 3x2)
✅ ANIMATION: Default sprite texture stored
FSM: Creating states for GEEZ - idle:OK wander:OK seek:OK eat:OK gather:OK herd:OK herd_wildnpc:OK agro:OK build:OK
FSM: Successfully created eat state for GEEZ
FSM: Successfully created gather state for GEEZ
FSM: Successfully created herd state for GEEZ
FSM: Successfully created herd_wildnpc state for GEEZ
FSM: Successfully created agro state for GEEZ
FSM: Successfully created combat state for GEEZ
FSM: Successfully created defend state for GEEZ
FSM: Successfully created raid state for GEEZ
FSM: Successfully created search state for GEEZ
FSM: Successfully created build state for GEEZ
FSM: Successfully created reproduction state for GEEZ
FSM: Successfully created occupy_building state for GEEZ
FSM: Successfully created work_at_building state for GEEZ
FSM: Successfully created craft state for GEEZ
Task System: Created TaskRunner component for GEEZ
✓ Spawned Woman: GEEZ at (393.1698, 499.6281) (agility 9.0 = 288.0 speed)
🎨 ANIMATION: _load_attack_sprite_sheet() called
🎨 ANIMATION: Loading sprite sheet from: res://assets/sprites/swingclub.png
✅ ANIMATION: Sprite sheet loaded successfully
🎨 ANIMATION: Texture dimensions - width=840, height=560
✅ ANIMATION: Frame size: 280x280 (grid 3x2)
✅ ANIMATION: Default sprite texture stored
FSM: Creating states for KUKO - idle:OK wander:OK seek:OK eat:OK gather:OK herd:OK herd_wildnpc:OK agro:OK build:OK
FSM: Successfully created eat state for KUKO
FSM: Successfully created gather state for KUKO
FSM: Successfully created herd state for KUKO
FSM: Successfully created herd_wildnpc state for KUKO
FSM: Successfully created agro state for KUKO
FSM: Successfully created combat state for KUKO
FSM: Successfully created defend state for KUKO
FSM: Successfully created raid state for KUKO
FSM: Successfully created search state for KUKO
FSM: Successfully created build state for KUKO
FSM: Successfully created reproduction state for KUKO
FSM: Successfully created occupy_building state for KUKO
FSM: Successfully created work_at_building state for KUKO
FSM: Successfully created craft state for KUKO
Task System: Created TaskRunner component for KUKO
✓ Spawned Woman: KUKO at (377.7031, 499.8419) (agility 9.0 = 288.0 speed)
🎨 ANIMATION: _load_attack_sprite_sheet() called
🎨 ANIMATION: Loading sprite sheet from: res://assets/sprites/swingclub.png
✅ ANIMATION: Sprite sheet loaded successfully
🎨 ANIMATION: Texture dimensions - width=840, height=560
✅ ANIMATION: Frame size: 280x280 (grid 3x2)
✅ ANIMATION: Default sprite texture stored
FSM: Creating states for XIUF - idle:OK wander:OK seek:OK eat:OK gather:OK herd:OK herd_wildnpc:OK agro:OK build:OK
FSM: Successfully created eat state for XIUF
FSM: Successfully created gather state for XIUF
FSM: Successfully created herd state for XIUF
FSM: Successfully created herd_wildnpc state for XIUF
FSM: Successfully created agro state for XIUF
FSM: Successfully created combat state for XIUF
FSM: Successfully created defend state for XIUF
FSM: Successfully created raid state for XIUF
FSM: Successfully created search state for XIUF
FSM: Successfully created build state for XIUF
FSM: Successfully created reproduction state for XIUF
FSM: Successfully created occupy_building state for XIUF
FSM: Successfully created work_at_building state for XIUF
FSM: Successfully created craft state for XIUF
Task System: Created TaskRunner component for XIUF
✓ Spawned Woman: XIUF at (-217.8984, 371.3142) (agility 9.0 = 288.0 speed)
🎨 ANIMATION: _load_attack_sprite_sheet() called
🎨 ANIMATION: Loading sprite sheet from: res://assets/sprites/swingclub.png
✅ ANIMATION: Sprite sheet loaded successfully
🎨 ANIMATION: Texture dimensions - width=840, height=560
✅ ANIMATION: Frame size: 280x280 (grid 3x2)
✅ ANIMATION: Default sprite texture stored
FSM: Creating states for DEIS - idle:OK wander:OK seek:OK eat:OK gather:OK herd:OK herd_wildnpc:OK agro:OK build:OK
FSM: Successfully created eat state for DEIS
FSM: Successfully created gather state for DEIS
FSM: Successfully created herd state for DEIS
FSM: Successfully created herd_wildnpc state for DEIS
FSM: Successfully created agro state for DEIS
FSM: Successfully created combat state for DEIS
FSM: Successfully created defend state for DEIS
FSM: Successfully created raid state for DEIS
FSM: Successfully created search state for DEIS
FSM: Successfully created build state for DEIS
FSM: Successfully created reproduction state for DEIS
FSM: Successfully created occupy_building state for DEIS
FSM: Successfully created work_at_building state for DEIS
FSM: Successfully created craft state for DEIS
Task System: Created TaskRunner component for DEIS
✓ Spawned Woman: DEIS at (100.8812, -297.1961) (agility 9.0 = 288.0 speed)
🎨 ANIMATION: _load_attack_sprite_sheet() called
🎨 ANIMATION: Loading sprite sheet from: res://assets/sprites/swingclub.png
✅ ANIMATION: Sprite sheet loaded successfully
🎨 ANIMATION: Texture dimensions - width=840, height=560
✅ ANIMATION: Frame size: 280x280 (grid 3x2)
✅ ANIMATION: Default sprite texture stored
FSM: Creating states for WUEC - idle:OK wander:OK seek:OK eat:OK gather:OK herd:OK herd_wildnpc:OK agro:OK build:OK
FSM: Successfully created eat state for WUEC
FSM: Successfully created gather state for WUEC
FSM: Successfully created herd state for WUEC
FSM: Successfully created herd_wildnpc state for WUEC
FSM: Successfully created agro state for WUEC
FSM: Successfully created combat state for WUEC
FSM: Successfully created defend state for WUEC
FSM: Successfully created raid state for WUEC
FSM: Successfully created search state for WUEC
FSM: Successfully created build state for WUEC
FSM: Successfully created reproduction state for WUEC
FSM: Successfully created occupy_building state for WUEC
FSM: Successfully created work_at_building state for WUEC
FSM: Successfully created craft state for WUEC
Task System: Created TaskRunner component for WUEC
✓ Spawned Woman: WUEC at (-58.75729, 243.2352) (agility 9.0 = 288.0 speed)
🎨 ANIMATION: _load_attack_sprite_sheet() called
🎨 ANIMATION: Loading sprite sheet from: res://assets/sprites/swingclub.png
✅ ANIMATION: Sprite sheet loaded successfully
🎨 ANIMATION: Texture dimensions - width=840, height=560
✅ ANIMATION: Frame size: 280x280 (grid 3x2)
✅ ANIMATION: Default sprite texture stored
FSM: Creating states for BAHI - idle:OK wander:OK seek:OK eat:OK gather:OK herd:OK herd_wildnpc:OK agro:OK build:OK
FSM: Successfully created eat state for BAHI
FSM: Successfully created gather state for BAHI
FSM: Successfully created herd state for BAHI
FSM: Successfully created herd_wildnpc state for BAHI
FSM: Successfully created agro state for BAHI
FSM: Successfully created combat state for BAHI
FSM: Successfully created defend state for BAHI
FSM: Successfully created raid state for BAHI
FSM: Successfully created search state for BAHI
FSM: Successfully created build state for BAHI
FSM: Successfully created reproduction state for BAHI
FSM: Successfully created occupy_building state for BAHI
FSM: Successfully created work_at_building state for BAHI
FSM: Successfully created craft state for BAHI
Task System: Created TaskRunner component for BAHI
✓ Spawned Woman: BAHI at (322.4399, -112.3169) (agility 9.0 = 288.0 speed)
Spawning 3 sheep and 3 goats around center
🎨 ANIMATION: _load_attack_sprite_sheet() called
🎨 ANIMATION: Loading sprite sheet from: res://assets/sprites/swingclub.png
✅ ANIMATION: Sprite sheet loaded successfully
🎨 ANIMATION: Texture dimensions - width=840, height=560
✅ ANIMATION: Frame size: 280x280 (grid 3x2)
✅ ANIMATION: Default sprite texture stored
FSM: Creating states for Sheep 1217 - idle:OK wander:OK seek:OK eat:OK gather:OK herd:OK herd_wildnpc:OK agro:OK build:OK
FSM: Successfully created eat state for Sheep 1217
FSM: Successfully created gather state for Sheep 1217
FSM: Successfully created herd state for Sheep 1217
FSM: Successfully created herd_wildnpc state for Sheep 1217
FSM: Successfully created agro state for Sheep 1217
FSM: Successfully created combat state for Sheep 1217
FSM: Successfully created defend state for Sheep 1217
FSM: Successfully created raid state for Sheep 1217
FSM: Successfully created search state for Sheep 1217
FSM: Successfully created build state for Sheep 1217
FSM: Successfully created reproduction state for Sheep 1217
FSM: Successfully created occupy_building state for Sheep 1217
FSM: Successfully created work_at_building state for Sheep 1217
FSM: Successfully created craft state for Sheep 1217
Task System: Created TaskRunner component for Sheep 1217
✓ Spawned Sheep: Sheep 1217 at (-441.7727, -678.5728)
🎨 ANIMATION: _load_attack_sprite_sheet() called
🎨 ANIMATION: Loading sprite sheet from: res://assets/sprites/swingclub.png
✅ ANIMATION: Sprite sheet loaded successfully
🎨 ANIMATION: Texture dimensions - width=840, height=560
✅ ANIMATION: Frame size: 280x280 (grid 3x2)
✅ ANIMATION: Default sprite texture stored
FSM: Creating states for Sheep 1319 - idle:OK wander:OK seek:OK eat:OK gather:OK herd:OK herd_wildnpc:OK agro:OK build:OK
FSM: Successfully created eat state for Sheep 1319
FSM: Successfully created gather state for Sheep 1319
FSM: Successfully created herd state for Sheep 1319
FSM: Successfully created herd_wildnpc state for Sheep 1319
FSM: Successfully created agro state for Sheep 1319
FSM: Successfully created combat state for Sheep 1319
FSM: Successfully created defend state for Sheep 1319
FSM: Successfully created raid state for Sheep 1319
FSM: Successfully created search state for Sheep 1319
FSM: Successfully created build state for Sheep 1319
FSM: Successfully created reproduction state for Sheep 1319
FSM: Successfully created occupy_building state for Sheep 1319
FSM: Successfully created work_at_building state for Sheep 1319
FSM: Successfully created craft state for Sheep 1319
Task System: Created TaskRunner component for Sheep 1319
✓ Spawned Sheep: Sheep 1319 at (-473.9521, -758.3456)
🎨 ANIMATION: _load_attack_sprite_sheet() called
🎨 ANIMATION: Loading sprite sheet from: res://assets/sprites/swingclub.png
✅ ANIMATION: Sprite sheet loaded successfully
🎨 ANIMATION: Texture dimensions - width=840, height=560
✅ ANIMATION: Frame size: 280x280 (grid 3x2)
✅ ANIMATION: Default sprite texture stored
FSM: Creating states for Sheep 1418 - idle:OK wander:OK seek:OK eat:OK gather:OK herd:OK herd_wildnpc:OK agro:OK build:OK
FSM: Successfully created eat state for Sheep 1418
FSM: Successfully created gather state for Sheep 1418
FSM: Successfully created herd state for Sheep 1418
FSM: Successfully created herd_wildnpc state for Sheep 1418
FSM: Successfully created agro state for Sheep 1418
FSM: Successfully created combat state for Sheep 1418
FSM: Successfully created defend state for Sheep 1418
FSM: Successfully created raid state for Sheep 1418
FSM: Successfully created search state for Sheep 1418
FSM: Successfully created build state for Sheep 1418
FSM: Successfully created reproduction state for Sheep 1418
FSM: Successfully created occupy_building state for Sheep 1418
FSM: Successfully created work_at_building state for Sheep 1418
FSM: Successfully created craft state for Sheep 1418
Task System: Created TaskRunner component for Sheep 1418
✓ Spawned Sheep: Sheep 1418 at (962.213, -79.55444)
🎨 ANIMATION: _load_attack_sprite_sheet() called
🎨 ANIMATION: Loading sprite sheet from: res://assets/sprites/swingclub.png
✅ ANIMATION: Sprite sheet loaded successfully
🎨 ANIMATION: Texture dimensions - width=840, height=560
✅ ANIMATION: Frame size: 280x280 (grid 3x2)
✅ ANIMATION: Default sprite texture stored
FSM: Creating states for Goat 1218 - idle:OK wander:OK seek:OK eat:OK gather:OK herd:OK herd_wildnpc:OK agro:OK build:OK
FSM: Successfully created eat state for Goat 1218
FSM: Successfully created gather state for Goat 1218
FSM: Successfully created herd state for Goat 1218
FSM: Successfully created herd_wildnpc state for Goat 1218
FSM: Successfully created agro state for Goat 1218
FSM: Successfully created combat state for Goat 1218
FSM: Successfully created defend state for Goat 1218
FSM: Successfully created raid state for Goat 1218
FSM: Successfully created search state for Goat 1218
FSM: Successfully created build state for Goat 1218
FSM: Successfully created reproduction state for Goat 1218
FSM: Successfully created occupy_building state for Goat 1218
FSM: Successfully created work_at_building state for Goat 1218
FSM: Successfully created craft state for Goat 1218
Task System: Created TaskRunner component for Goat 1218
✓ Spawned Goat: Goat 1218 at (-161.014, 701.3181)
🎨 ANIMATION: _load_attack_sprite_sheet() called
🎨 ANIMATION: Loading sprite sheet from: res://assets/sprites/swingclub.png
✅ ANIMATION: Sprite sheet loaded successfully
🎨 ANIMATION: Texture dimensions - width=840, height=560
✅ ANIMATION: Frame size: 280x280 (grid 3x2)
✅ ANIMATION: Default sprite texture stored
FSM: Creating states for Goat 1319 - idle:OK wander:OK seek:OK eat:OK gather:OK herd:OK herd_wildnpc:OK agro:OK build:OK
FSM: Successfully created eat state for Goat 1319
FSM: Successfully created gather state for Goat 1319
FSM: Successfully created herd state for Goat 1319
FSM: Successfully created herd_wildnpc state for Goat 1319
FSM: Successfully created agro state for Goat 1319
FSM: Successfully created combat state for Goat 1319
FSM: Successfully created defend state for Goat 1319
FSM: Successfully created raid state for Goat 1319
FSM: Successfully created search state for Goat 1319
FSM: Successfully created build state for Goat 1319
FSM: Successfully created reproduction state for Goat 1319
FSM: Successfully created occupy_building state for Goat 1319
FSM: Successfully created work_at_building state for Goat 1319
FSM: Successfully created craft state for Goat 1319
Task System: Created TaskRunner component for Goat 1319
✓ Spawned Goat: Goat 1319 at (758.719, -355.3054)
🎨 ANIMATION: _load_attack_sprite_sheet() called
🎨 ANIMATION: Loading sprite sheet from: res://assets/sprites/swingclub.png
✅ ANIMATION: Sprite sheet loaded successfully
🎨 ANIMATION: Texture dimensions - width=840, height=560
✅ ANIMATION: Frame size: 280x280 (grid 3x2)
✅ ANIMATION: Default sprite texture stored
FSM: Creating states for Goat 1419 - idle:OK wander:OK seek:OK eat:OK gather:OK herd:OK herd_wildnpc:OK agro:OK build:OK
FSM: Successfully created eat state for Goat 1419
FSM: Successfully created gather state for Goat 1419
FSM: Successfully created herd state for Goat 1419
FSM: Successfully created herd_wildnpc state for Goat 1419
FSM: Successfully created agro state for Goat 1419
FSM: Successfully created combat state for Goat 1419
FSM: Successfully created defend state for Goat 1419
FSM: Successfully created raid state for Goat 1419
FSM: Successfully created search state for Goat 1419
FSM: Successfully created build state for Goat 1419
FSM: Successfully created reproduction state for Goat 1419
FSM: Successfully created occupy_building state for Goat 1419
FSM: Successfully created work_at_building state for Goat 1419
FSM: Successfully created craft state for Goat 1419
Task System: Created TaskRunner component for Goat 1419
✓ Spawned Goat: Goat 1419 at (-587.8028, -719.8277)
Spawning tallgrass in 25 groups (radius: 2000)
Tallgrass spawned!
Spawning 75 resources randomly across map (radius: 2000) around position: (0.0, 0.0)
Resources spawned!
Resources spawned!
Resources spawned!
Resources spawned!
Resources spawned!
Resources spawned!
Resources spawned!
Resources spawned!
Resources spawned!
Resources spawned!
Resources spawned!
Resources spawned!
Resources spawned!
Resources spawned!
Resources spawned!
Resources spawned!
Resources spawned!
Resources spawned!
Resources spawned!
Resources spawned!
Resources spawned!
Resources spawned!
Resources spawned!
Resources spawned!
Resources spawned!
Resources spawned!
Resources spawned!
Resources spawned!
Resources spawned!
Resources spawned!
Resources spawned!
Resources spawned!
Resources spawned!
Resources spawned!
Resources spawned!
Resources spawned!
Resources spawned!
Resources spawned!
Resources spawned!
Resources spawned!
Resources spawned!
Resources spawned!
Resources spawned!
Resources spawned!
Resources spawned!
Resources spawned!
Resources spawned!
Resources spawned!
Resources spawned!
Resources spawned!
Resources spawned!
Resources spawned!
Resources spawned!
Resources spawned!
Resources spawned!
Resources spawned!
Resources spawned!
Resources spawned!
Resources spawned!
Resources spawned!
Resources spawned!
Resources spawned!
Resources spawned!
Resources spawned!
Resources spawned!
Resources spawned!
Resources spawned!
Resources spawned!
Resources spawned!
Resources spawned!
Resources spawned!
Resources spawned!
Resources spawned!
Resources spawned!
Resources spawned!
[2026-02-16T13:24:20] [INFO] [NPC] POSITION: GEEZ at (428.3, 473.6), state=wander, distance_to_claim=0.0/400.0, velocity=39.4 npc=GEEZ pos=428.3,473.6 state=wander distance_to_claim=0.0 claim_radius=400.0 velocity=39.4
[2026-02-16T13:24:20] [INFO] [NPC] POSITION: KUKO at (367.8, 516.6), state=wander, distance_to_claim=0.0/400.0, velocity=49.1 npc=KUKO pos=367.8,516.6 state=wander distance_to_claim=0.0 claim_radius=400.0 velocity=49.1
[2026-02-16T13:24:20] [INFO] [NPC] POSITION: XIUF at (-238.0, 408.1), state=wander, distance_to_claim=0.0/400.0, velocity=58.5 npc=XIUF pos=-238.0,408.1 state=wander distance_to_claim=0.0 claim_radius=400.0 velocity=58.5
[2026-02-16T13:24:20] [INFO] [NPC] POSITION: DEIS at (51.7, -284.3), state=wander, distance_to_claim=0.0/400.0, velocity=57.4 npc=DEIS pos=51.7,-284.3 state=wander distance_to_claim=0.0 claim_radius=400.0 velocity=57.4
[2026-02-16T13:24:20] [DEBUG] [NPC] Can enter check: GEEZ cannot enter agro (not_caveman) npc=GEEZ state=agro can_enter=false reason=not_caveman npc_type=woman
[2026-02-16T13:24:20] [DEBUG] [NPC] Priority eval: GEEZ - agro (priority=15.0, can_enter=false) npc=GEEZ state=agro priority=15.0 can_enter=false
[2026-02-16T13:24:20] [DEBUG] [NPC] Priority eval: GEEZ - combat (priority=12.0, can_enter=false) npc=GEEZ state=combat priority=12.0 can_enter=false
[2026-02-16T13:24:20] [DEBUG] [NPC] Can enter check: GEEZ cannot enter herd (not_herded) npc=GEEZ state=herd can_enter=false reason=not_herded herder=unknown
[2026-02-16T13:24:20] [DEBUG] [NPC] Priority eval: GEEZ - herd (priority=11.0, can_enter=false) npc=GEEZ state=herd priority=11.0 can_enter=false
[2026-02-16T13:24:20] [DEBUG] [NPC] Priority eval: GEEZ - raid (priority=8.5, can_enter=false) npc=GEEZ state=raid priority=8.5 can_enter=false
[2026-02-16T13:24:21] [INFO] [NPC] POSITION: XIUF at (-259.8, 453.1), state=wander, distance_to_claim=0.0/400.0, velocity=28.0 npc=XIUF pos=-259.8,453.1 state=wander distance_to_claim=0.0 claim_radius=400.0 velocity=28.0
[2026-02-16T13:24:21] [INFO] [NPC] POSITION: DEIS at (33.6, -279.4), state=wander, distance_to_claim=0.0/400.0, velocity=18.8 npc=DEIS pos=33.6,-279.4 state=wander distance_to_claim=0.0 claim_radius=400.0 velocity=18.8
[2026-02-16T13:24:21] [INFO] [NPC] POSITION: Sheep 1217 at (-402.9, -619.4), state=wander, distance_to_claim=0.0/400.0, velocity=18.8 npc=Sheep 1217 pos=-402.9,-619.4 state=wander distance_to_claim=0.0 claim_radius=400.0 velocity=18.8
[2026-02-16T13:24:21] [INFO] [NPC] POSITION: Sheep 1319 at (-498.7, -733.9), state=wander, distance_to_claim=0.0/400.0, velocity=5.7 npc=Sheep 1319 pos=-498.7,-733.9 state=wander distance_to_claim=0.0 claim_radius=400.0 velocity=5.7
[2026-02-16T13:24:21] [INFO] [NPC] POSITION: Goat 1319 at (662.7, -397.1), state=wander, distance_to_claim=0.0/400.0, velocity=47.0 npc=Goat 1319 pos=662.7,-397.1 state=wander distance_to_claim=0.0 claim_radius=400.0 velocity=47.0
[2026-02-16T13:24:21] [DEBUG] [NPC] Can enter check: XIUF cannot enter agro (not_caveman) npc=XIUF state=agro can_enter=false reason=not_caveman npc_type=woman
[2026-02-16T13:24:21] [DEBUG] [NPC] Priority eval: XIUF - agro (priority=15.0, can_enter=false) npc=XIUF state=agro priority=15.0 can_enter=false
[2026-02-16T13:24:21] [DEBUG] [NPC] Priority eval: XIUF - combat (priority=12.0, can_enter=false) npc=XIUF state=combat priority=12.0 can_enter=false
[2026-02-16T13:24:21] [DEBUG] [NPC] Can enter check: XIUF cannot enter herd (not_herded) npc=XIUF state=herd can_enter=false reason=not_herded herder=unknown
[2026-02-16T13:24:21] [DEBUG] [NPC] Priority eval: XIUF - herd (priority=11.0, can_enter=false) npc=XIUF state=herd priority=11.0 can_enter=false
TASK SYSTEM LOGGER: Called at time 3.9
[2026-02-16T13:24:21] [INFO] [INVENTORY] === TASK SYSTEM LOG: 0 Land Claims ===
[2026-02-16T13:24:21] [INFO] [INVENTORY] TASK SYSTEM DEBUG: buildings group=0, with building_type=0, ovens=0
[2026-02-16T13:24:21] [INFO] [INVENTORY] === TASK SYSTEM LOG: 0 Ovens ===
[2026-02-16T13:24:22] [DEBUG] [NPC] Can enter check: Sheep 1217 cannot enter agro (not_caveman) npc=Sheep 1217 state=agro can_enter=false reason=not_caveman npc_type=sheep
[2026-02-16T13:24:22] [DEBUG] [NPC] Priority eval: Sheep 1217 - agro (priority=15.0, can_enter=false) npc=Sheep 1217 state=agro priority=15.0 can_enter=false
[2026-02-16T13:24:22] [DEBUG] [NPC] Priority eval: Sheep 1217 - combat (priority=12.0, can_enter=false) npc=Sheep 1217 state=combat priority=12.0 can_enter=false
[2026-02-16T13:24:22] [DEBUG] [NPC] Can enter check: Sheep 1217 cannot enter herd (not_herded) npc=Sheep 1217 state=herd can_enter=false reason=not_herded herder=unknown
[2026-02-16T13:24:22] [DEBUG] [NPC] Priority eval: Sheep 1217 - herd (priority=11.0, can_enter=false) npc=Sheep 1217 state=herd priority=11.0 can_enter=false
[2026-02-16T13:24:22] [DEBUG] [NPC] Priority eval: Sheep 1217 - raid (priority=8.5, can_enter=false) npc=Sheep 1217 state=raid priority=8.5 can_enter=false
[2026-02-16T13:24:22] [DEBUG] [NPC] Priority eval: Sheep 1217 - reproduction (priority=8.0, can_enter=false) npc=Sheep 1217 state=reproduction priority=8.0 can_enter=false
[2026-02-16T13:24:22] [DEBUG] [NPC] Priority eval: Sheep 1217 - occupy_building (priority=7.5, can_enter=false) npc=Sheep 1217 state=occupy_building priority=7.5 can_enter=false
[2026-02-16T13:24:22] [DEBUG] [NPC] Priority eval: Sheep 1217 - work_at_building (priority=7.0, can_enter=false) npc=Sheep 1217 state=work_at_building priority=7.0 can_enter=false
[2026-02-16T13:24:22] [DEBUG] [NPC] Can enter check: Sheep 1217 cannot enter seek (no_target) npc=Sheep 1217 state=seek can_enter=false reason=no_target
[2026-02-16T13:24:23] [INFO] [NPC] POSITION: XIUF at (-181.6, 490.5), state=wander, distance_to_claim=0.0/400.0, velocity=31.4 npc=XIUF pos=-181.6,490.5 state=wander distance_to_claim=0.0 claim_radius=400.0 velocity=31.4
[2026-02-16T13:24:23] [DEBUG] [NPC] Can enter check: XIUF cannot enter agro (not_caveman) npc=XIUF state=agro can_enter=false reason=not_caveman npc_type=woman
[2026-02-16T13:24:23] [DEBUG] [NPC] Priority eval: XIUF - agro (priority=15.0, can_enter=false) npc=XIUF state=agro priority=15.0 can_enter=false
[2026-02-16T13:24:23] [DEBUG] [NPC] Priority eval: XIUF - combat (priority=12.0, can_enter=false) npc=XIUF state=combat priority=12.0 can_enter=false
[2026-02-16T13:24:23] [DEBUG] [NPC] Can enter check: XIUF cannot enter herd (not_herded) npc=XIUF state=herd can_enter=false reason=not_herded herder=unknown
[2026-02-16T13:24:23] [DEBUG] [NPC] Priority eval: XIUF - herd (priority=11.0, can_enter=false) npc=XIUF state=herd priority=11.0 can_enter=false
[2026-02-16T13:24:23] [DEBUG] [NPC] Priority eval: XIUF - raid (priority=8.5, can_enter=false) npc=XIUF state=raid priority=8.5 can_enter=false
[2026-02-16T13:24:23] [DEBUG] [NPC] Priority eval: XIUF - reproduction (priority=8.0, can_enter=false) npc=XIUF state=reproduction priority=8.0 can_enter=false
[2026-02-16T13:24:23] [DEBUG] [NPC] Priority eval: XIUF - occupy_building (priority=7.5, can_enter=false) npc=XIUF state=occupy_building priority=7.5 can_enter=false
[2026-02-16T13:24:23] [DEBUG] [NPC] Priority eval: XIUF - work_at_building (priority=7.0, can_enter=false) npc=XIUF state=work_at_building priority=7.0 can_enter=false
[2026-02-16T13:24:24] [DEBUG] [NPC] Can enter check: PUIK cannot enter herd (not_herded) npc=PUIK state=herd can_enter=false reason=not_herded herder=unknown
[2026-02-16T13:24:24] [DEBUG] [NPC] Priority eval: PUIK - herd (priority=11.0, can_enter=false) npc=PUIK state=herd priority=11.0 can_enter=false
[2026-02-16T13:24:24] [DEBUG] [NPC] Priority eval: PUIK - raid (priority=8.5, can_enter=false) npc=PUIK state=raid priority=8.5 can_enter=false
[2026-02-16T13:24:24] [DEBUG] [NPC] Priority eval: PUIK - reproduction (priority=8.0, can_enter=false) npc=PUIK state=reproduction priority=8.0 can_enter=false
[2026-02-16T13:24:24] [DEBUG] [NPC] Priority eval: PUIK - occupy_building (priority=7.5, can_enter=false) npc=PUIK state=occupy_building priority=7.5 can_enter=false
[2026-02-16T13:24:24] [DEBUG] [NPC] Priority eval: PUIK - work_at_building (priority=7.0, can_enter=false) npc=PUIK state=work_at_building priority=7.0 can_enter=false
[2026-02-16T13:24:24] [DEBUG] [NPC] Can enter check: PUIK cannot enter seek (no_target) npc=PUIK state=seek can_enter=false reason=no_target
[2026-02-16T13:24:24] [DEBUG] [NPC] Priority eval: PUIK - seek (priority=2.0, can_enter=false) npc=PUIK state=seek priority=2.0 can_enter=false
[2026-02-16T13:24:24] [DEBUG] [NPC] Evaluated 8 states: agro(priority=15.0,can_enter=false) combat(priority=12.0,can_enter=false) herd(priority=11.0,can_enter=false) raid(priority=8.5,can_enter=false) reproduction(priority=8.0,can_enter=false) occupy_building(priority=7.5,can_enter=false) work_at_building(priority=7.0,can_enter=false) seek(priority=2.0,can_enter=false) -> Best: wander (priority=1.0) npc=PUIK best_state=wander best_priority=1.0
[2026-02-16T13:24:24] [INFO] [NPC] POSITION: XIUF at (-148.7, 503.1), state=wander, distance_to_claim=0.0/400.0, velocity=5.0 npc=XIUF pos=-148.7,503.1 state=wander distance_to_claim=0.0 claim_radius=400.0 velocity=5.0
TASK SYSTEM LOGGER: Called at time 6.9
[2026-02-16T13:24:24] [INFO] [INVENTORY] === TASK SYSTEM LOG: 0 Land Claims ===
[2026-02-16T13:24:24] [INFO] [INVENTORY] TASK SYSTEM DEBUG: buildings group=0, with building_type=0, ovens=0
[2026-02-16T13:24:24] [INFO] [INVENTORY] === TASK SYSTEM LOG: 0 Ovens ===
[2026-02-16T13:24:25] [INFO] [NPC] POSITION: XIUF at (-151.4, 502.1), state=wander, distance_to_claim=0.0/400.0, velocity=33.7 npc=XIUF pos=-151.4,502.1 state=wander distance_to_claim=0.0 claim_radius=400.0 velocity=33.7
[2026-02-16T13:24:25] [DEBUG] [NPC] Can enter check: XIUF cannot enter agro (not_caveman) npc=XIUF state=agro can_enter=false reason=not_caveman npc_type=woman
[2026-02-16T13:24:25] [DEBUG] [NPC] Priority eval: XIUF - agro (priority=15.0, can_enter=false) npc=XIUF state=agro priority=15.0 can_enter=false
[2026-02-16T13:24:25] [DEBUG] [NPC] Priority eval: XIUF - combat (priority=12.0, can_enter=false) npc=XIUF state=combat priority=12.0 can_enter=false
[2026-02-16T13:24:25] [DEBUG] [NPC] Can enter check: XIUF cannot enter herd (not_herded) npc=XIUF state=herd can_enter=false reason=not_herded herder=unknown
[2026-02-16T13:24:25] [DEBUG] [NPC] Priority eval: XIUF - herd (priority=11.0, can_enter=false) npc=XIUF state=herd priority=11.0 can_enter=false
[2026-02-16T13:24:25] [DEBUG] [NPC] Priority eval: XIUF - raid (priority=8.5, can_enter=false) npc=XIUF state=raid priority=8.5 can_enter=false
[2026-02-16T13:24:25] [DEBUG] [NPC] Priority eval: XIUF - reproduction (priority=8.0, can_enter=false) npc=XIUF state=reproduction priority=8.0 can_enter=false
[2026-02-16T13:24:25] [DEBUG] [NPC] Priority eval: XIUF - occupy_building (priority=7.5, can_enter=false) npc=XIUF state=occupy_building priority=7.5 can_enter=false
[2026-02-16T13:24:25] [DEBUG] [NPC] Priority eval: XIUF - work_at_building (priority=7.0, can_enter=false) npc=XIUF state=work_at_building priority=7.0 can_enter=false
[2026-02-16T13:24:26] [INFO] [NPC] POSITION: XIUF at (-149.5, 496.3), state=wander, distance_to_claim=0.0/400.0, velocity=56.6 npc=XIUF pos=-149.5,496.3 state=wander distance_to_claim=0.0 claim_radius=400.0 velocity=56.6
[2026-02-16T13:24:26] [DEBUG] [NPC] Can enter check: XIUF cannot enter agro (not_caveman) npc=XIUF state=agro can_enter=false reason=not_caveman npc_type=woman
[2026-02-16T13:24:26] [DEBUG] [NPC] Priority eval: XIUF - agro (priority=15.0, can_enter=false) npc=XIUF state=agro priority=15.0 can_enter=false
[2026-02-16T13:24:26] [DEBUG] [NPC] Priority eval: XIUF - combat (priority=12.0, can_enter=false) npc=XIUF state=combat priority=12.0 can_enter=false
[2026-02-16T13:24:26] [DEBUG] [NPC] Can enter check: XIUF cannot enter herd (not_herded) npc=XIUF state=herd can_enter=false reason=not_herded herder=unknown
[2026-02-16T13:24:26] [DEBUG] [NPC] Priority eval: XIUF - herd (priority=11.0, can_enter=false) npc=XIUF state=herd priority=11.0 can_enter=false
[2026-02-16T13:24:26] [DEBUG] [NPC] Priority eval: XIUF - raid (priority=8.5, can_enter=false) npc=XIUF state=raid priority=8.5 can_enter=false
[2026-02-16T13:24:26] [DEBUG] [NPC] Priority eval: XIUF - reproduction (priority=8.0, can_enter=false) npc=XIUF state=reproduction priority=8.0 can_enter=false
[2026-02-16T13:24:26] [DEBUG] [NPC] Priority eval: XIUF - occupy_building (priority=7.5, can_enter=false) npc=XIUF state=occupy_building priority=7.5 can_enter=false
[2026-02-16T13:24:26] [DEBUG] [NPC] Priority eval: XIUF - work_at_building (priority=7.0, can_enter=false) npc=XIUF state=work_at_building priority=7.0 can_enter=false
[2026-02-16T13:24:27] [DEBUG] [NPC] Can enter check: Sheep 1217 cannot enter agro (not_caveman) npc=Sheep 1217 state=agro can_enter=false reason=not_caveman npc_type=sheep
[2026-02-16T13:24:27] [DEBUG] [NPC] Priority eval: Sheep 1217 - agro (priority=15.0, can_enter=false) npc=Sheep 1217 state=agro priority=15.0 can_enter=false
[2026-02-16T13:24:27] [DEBUG] [NPC] Priority eval: Sheep 1217 - combat (priority=12.0, can_enter=false) npc=Sheep 1217 state=combat priority=12.0 can_enter=false
[2026-02-16T13:24:27] [DEBUG] [NPC] Can enter check: Sheep 1217 cannot enter herd (not_herded) npc=Sheep 1217 state=herd can_enter=false reason=not_herded herder=unknown
[2026-02-16T13:24:27] [DEBUG] [NPC] Priority eval: Sheep 1217 - herd (priority=11.0, can_enter=false) npc=Sheep 1217 state=herd priority=11.0 can_enter=false
[2026-02-16T13:24:27] [DEBUG] [NPC] Priority eval: Sheep 1217 - raid (priority=8.5, can_enter=false) npc=Sheep 1217 state=raid priority=8.5 can_enter=false
[2026-02-16T13:24:27] [DEBUG] [NPC] Priority eval: Sheep 1217 - reproduction (priority=8.0, can_enter=false) npc=Sheep 1217 state=reproduction priority=8.0 can_enter=false
[2026-02-16T13:24:27] [DEBUG] [NPC] Priority eval: Sheep 1217 - occupy_building (priority=7.5, can_enter=false) npc=Sheep 1217 state=occupy_building priority=7.5 can_enter=false
[2026-02-16T13:24:27] [DEBUG] [NPC] Priority eval: Sheep 1217 - work_at_building (priority=7.0, can_enter=false) npc=Sheep 1217 state=work_at_building priority=7.0 can_enter=false
[2026-02-16T13:24:27] [DEBUG] [NPC] Can enter check: Sheep 1217 cannot enter seek (no_target) npc=Sheep 1217 state=seek can_enter=false reason=no_target
TASK SYSTEM LOGGER: Called at time 9.9
[2026-02-16T13:24:27] [INFO] [INVENTORY] === TASK SYSTEM LOG: 0 Land Claims ===
[2026-02-16T13:24:27] [INFO] [INVENTORY] TASK SYSTEM DEBUG: buildings group=0, with building_type=0, ovens=0
[2026-02-16T13:24:27] [INFO] [INVENTORY] === TASK SYSTEM LOG: 0 Ovens ===
[2026-02-16T13:24:28] [DEBUG] [NPC] Can enter check: BAHI cannot enter agro (not_caveman) npc=BAHI state=agro can_enter=false reason=not_caveman npc_type=woman
[2026-02-16T13:24:28] [DEBUG] [NPC] Priority eval: BAHI - agro (priority=15.0, can_enter=false) npc=BAHI state=agro priority=15.0 can_enter=false
[2026-02-16T13:24:28] [DEBUG] [NPC] Priority eval: BAHI - combat (priority=12.0, can_enter=false) npc=BAHI state=combat priority=12.0 can_enter=false
[2026-02-16T13:24:28] [DEBUG] [NPC] Can enter check: BAHI cannot enter herd (not_herded) npc=BAHI state=herd can_enter=false reason=not_herded herder=unknown
[2026-02-16T13:24:28] [DEBUG] [NPC] Priority eval: BAHI - herd (priority=11.0, can_enter=false) npc=BAHI state=herd priority=11.0 can_enter=false
[2026-02-16T13:24:28] [DEBUG] [NPC] Priority eval: BAHI - raid (priority=8.5, can_enter=false) npc=BAHI state=raid priority=8.5 can_enter=false
[2026-02-16T13:24:28] [DEBUG] [NPC] Priority eval: BAHI - reproduction (priority=8.0, can_enter=false) npc=BAHI state=reproduction priority=8.0 can_enter=false
[2026-02-16T13:24:28] [DEBUG] [NPC] Priority eval: BAHI - occupy_building (priority=7.5, can_enter=false) npc=BAHI state=occupy_building priority=7.5 can_enter=false
[2026-02-16T13:24:28] [DEBUG] [NPC] Priority eval: BAHI - work_at_building (priority=7.0, can_enter=false) npc=BAHI state=work_at_building priority=7.0 can_enter=false
[2026-02-16T13:24:28] [DEBUG] [NPC] Can enter check: BAHI cannot enter seek (no_target) npc=BAHI state=seek can_enter=false reason=no_target
[2026-02-16T13:24:29] [DEBUG] [NPC] Can enter check: XIUF cannot enter agro (not_caveman) npc=XIUF state=agro can_enter=false reason=not_caveman npc_type=woman
[2026-02-16T13:24:29] [DEBUG] [NPC] Priority eval: XIUF - agro (priority=15.0, can_enter=false) npc=XIUF state=agro priority=15.0 can_enter=false
[2026-02-16T13:24:29] [DEBUG] [NPC] Priority eval: XIUF - combat (priority=12.0, can_enter=false) npc=XIUF state=combat priority=12.0 can_enter=false
[2026-02-16T13:24:29] [DEBUG] [NPC] Can enter check: XIUF cannot enter herd (not_herded) npc=XIUF state=herd can_enter=false reason=not_herded herder=unknown
[2026-02-16T13:24:29] [DEBUG] [NPC] Priority eval: XIUF - herd (priority=11.0, can_enter=false) npc=XIUF state=herd priority=11.0 can_enter=false
[2026-02-16T13:24:29] [DEBUG] [NPC] Priority eval: XIUF - raid (priority=8.5, can_enter=false) npc=XIUF state=raid priority=8.5 can_enter=false
[2026-02-16T13:24:29] [DEBUG] [NPC] Priority eval: XIUF - reproduction (priority=8.0, can_enter=false) npc=XIUF state=reproduction priority=8.0 can_enter=false
[2026-02-16T13:24:29] [DEBUG] [NPC] Priority eval: XIUF - occupy_building (priority=7.5, can_enter=false) npc=XIUF state=occupy_building priority=7.5 can_enter=false
[2026-02-16T13:24:29] [DEBUG] [NPC] Priority eval: XIUF - work_at_building (priority=7.0, can_enter=false) npc=XIUF state=work_at_building priority=7.0 can_enter=false
[2026-02-16T13:24:29] [DEBUG] [NPC] Can enter check: XIUF cannot enter seek (no_target) npc=XIUF state=seek can_enter=false reason=no_target
[2026-02-16T13:24:30] [DEBUG] [NPC] Can enter check: Sheep 1418 cannot enter agro (not_caveman) npc=Sheep 1418 state=agro can_enter=false reason=not_caveman npc_type=sheep
[2026-02-16T13:24:30] [DEBUG] [NPC] Priority eval: Sheep 1418 - agro (priority=15.0, can_enter=false) npc=Sheep 1418 state=agro priority=15.0 can_enter=false
[2026-02-16T13:24:30] [DEBUG] [NPC] Priority eval: Sheep 1418 - combat (priority=12.0, can_enter=false) npc=Sheep 1418 state=combat priority=12.0 can_enter=false
[2026-02-16T13:24:30] [DEBUG] [NPC] Can enter check: Sheep 1418 cannot enter herd (not_herded) npc=Sheep 1418 state=herd can_enter=false reason=not_herded herder=unknown
[2026-02-16T13:24:30] [DEBUG] [NPC] Priority eval: Sheep 1418 - herd (priority=11.0, can_enter=false) npc=Sheep 1418 state=herd priority=11.0 can_enter=false
[2026-02-16T13:24:30] [DEBUG] [NPC] Priority eval: Sheep 1418 - raid (priority=8.5, can_enter=false) npc=Sheep 1418 state=raid priority=8.5 can_enter=false
[2026-02-16T13:24:30] [DEBUG] [NPC] Priority eval: Sheep 1418 - reproduction (priority=8.0, can_enter=false) npc=Sheep 1418 state=reproduction priority=8.0 can_enter=false
[2026-02-16T13:24:30] [DEBUG] [NPC] Priority eval: Sheep 1418 - occupy_building (priority=7.5, can_enter=false) npc=Sheep 1418 state=occupy_building priority=7.5 can_enter=false
[2026-02-16T13:24:30] [DEBUG] [NPC] Priority eval: Sheep 1418 - work_at_building (priority=7.0, can_enter=false) npc=Sheep 1418 state=work_at_building priority=7.0 can_enter=false
[2026-02-16T13:24:30] [DEBUG] [NPC] Can enter check: Sheep 1418 cannot enter seek (no_target) npc=Sheep 1418 state=seek can_enter=false reason=no_target
TASK SYSTEM LOGGER: Called at time 12.9
[2026-02-16T13:24:30] [INFO] [INVENTORY] === TASK SYSTEM LOG: 0 Land Claims ===
[2026-02-16T13:24:30] [INFO] [INVENTORY] TASK SYSTEM DEBUG: buildings group=0, with building_type=0, ovens=0
[2026-02-16T13:24:30] [INFO] [INVENTORY] === TASK SYSTEM LOG: 0 Ovens ===
[2026-02-16T13:24:31] [DEBUG] [NPC] Can enter check: WUEC cannot enter agro (not_caveman) npc=WUEC state=agro can_enter=false reason=not_caveman npc_type=woman
[2026-02-16T13:24:31] [DEBUG] [NPC] Priority eval: WUEC - agro (priority=15.0, can_enter=false) npc=WUEC state=agro priority=15.0 can_enter=false
[2026-02-16T13:24:31] [DEBUG] [NPC] Priority eval: WUEC - combat (priority=12.0, can_enter=false) npc=WUEC state=combat priority=12.0 can_enter=false
[2026-02-16T13:24:31] [DEBUG] [NPC] Can enter check: WUEC cannot enter herd (not_herded) npc=WUEC state=herd can_enter=false reason=not_herded herder=unknown
[2026-02-16T13:24:31] [DEBUG] [NPC] Priority eval: WUEC - herd (priority=11.0, can_enter=false) npc=WUEC state=herd priority=11.0 can_enter=false
[2026-02-16T13:24:31] [DEBUG] [NPC] Priority eval: WUEC - raid (priority=8.5, can_enter=false) npc=WUEC state=raid priority=8.5 can_enter=false
[2026-02-16T13:24:31] [DEBUG] [NPC] Priority eval: WUEC - reproduction (priority=8.0, can_enter=false) npc=WUEC state=reproduction priority=8.0 can_enter=false
[2026-02-16T13:24:31] [DEBUG] [NPC] Priority eval: WUEC - occupy_building (priority=7.5, can_enter=false) npc=WUEC state=occupy_building priority=7.5 can_enter=false
[2026-02-16T13:24:31] [DEBUG] [NPC] Priority eval: WUEC - work_at_building (priority=7.0, can_enter=false) npc=WUEC state=work_at_building priority=7.0 can_enter=false
[2026-02-16T13:24:31] [DEBUG] [NPC] Can enter check: WUEC cannot enter seek (no_target) npc=WUEC state=seek can_enter=false reason=no_target
[2026-02-16T13:24:32] [INFO] [NPC] POSITION: Goat 1419 at (-539.1, -731.3), state=wander, distance_to_claim=0.0/400.0, velocity=51.1 npc=Goat 1419 pos=-539.1,-731.3 state=wander distance_to_claim=0.0 claim_radius=400.0 velocity=51.1
[2026-02-16T13:24:32] [DEBUG] [NPC] Can enter check: Goat 1419 cannot enter agro (not_caveman) npc=Goat 1419 state=agro can_enter=false reason=not_caveman npc_type=goat
[2026-02-16T13:24:32] [DEBUG] [NPC] Priority eval: Goat 1419 - agro (priority=15.0, can_enter=false) npc=Goat 1419 state=agro priority=15.0 can_enter=false
[2026-02-16T13:24:32] [DEBUG] [NPC] Priority eval: Goat 1419 - combat (priority=12.0, can_enter=false) npc=Goat 1419 state=combat priority=12.0 can_enter=false
[2026-02-16T13:24:32] [DEBUG] [NPC] Can enter check: Goat 1419 cannot enter herd (not_herded) npc=Goat 1419 state=herd can_enter=false reason=not_herded herder=unknown
[2026-02-16T13:24:32] [DEBUG] [NPC] Priority eval: Goat 1419 - herd (priority=11.0, can_enter=false) npc=Goat 1419 state=herd priority=11.0 can_enter=false
[2026-02-16T13:24:32] [DEBUG] [NPC] Priority eval: Goat 1419 - raid (priority=8.5, can_enter=false) npc=Goat 1419 state=raid priority=8.5 can_enter=false
[2026-02-16T13:24:32] [DEBUG] [NPC] Priority eval: Goat 1419 - reproduction (priority=8.0, can_enter=false) npc=Goat 1419 state=reproduction priority=8.0 can_enter=false
[2026-02-16T13:24:32] [DEBUG] [NPC] Priority eval: Goat 1419 - occupy_building (priority=7.5, can_enter=false) npc=Goat 1419 state=occupy_building priority=7.5 can_enter=false
[2026-02-16T13:24:32] [DEBUG] [NPC] Priority eval: Goat 1419 - work_at_building (priority=7.0, can_enter=false) npc=Goat 1419 state=work_at_building priority=7.0 can_enter=false
[2026-02-16T13:24:33] [INFO] [NPC] POSITION: GEEZ at (446.3, 460.0), state=wander, distance_to_claim=0.0/400.0, velocity=58.0 npc=GEEZ pos=446.3,460.0 state=wander distance_to_claim=0.0 claim_radius=400.0 velocity=58.0
[2026-02-16T13:24:33] [DEBUG] [NPC] Steering behavior: WANDER - center npc=GEEZ behavior=WANDER target=center position=393.2,499.6 radius=300.0
[2026-02-16T13:24:33] [DEBUG] [NPC] Can enter check: GEEZ cannot enter agro (not_caveman) npc=GEEZ state=agro can_enter=false reason=not_caveman npc_type=woman
[2026-02-16T13:24:33] [DEBUG] [NPC] Priority eval: GEEZ - agro (priority=15.0, can_enter=false) npc=GEEZ state=agro priority=15.0 can_enter=false
[2026-02-16T13:24:33] [DEBUG] [NPC] Priority eval: GEEZ - combat (priority=12.0, can_enter=false) npc=GEEZ state=combat priority=12.0 can_enter=false
[2026-02-16T13:24:33] [DEBUG] [NPC] Can enter check: GEEZ cannot enter herd (not_herded) npc=GEEZ state=herd can_enter=false reason=not_herded herder=unknown
[2026-02-16T13:24:33] [DEBUG] [NPC] Priority eval: GEEZ - herd (priority=11.0, can_enter=false) npc=GEEZ state=herd priority=11.0 can_enter=false
[2026-02-16T13:24:33] [DEBUG] [NPC] Priority eval: GEEZ - raid (priority=8.5, can_enter=false) npc=GEEZ state=raid priority=8.5 can_enter=false
[2026-02-16T13:24:33] [DEBUG] [NPC] Priority eval: GEEZ - reproduction (priority=8.0, can_enter=false) npc=GEEZ state=reproduction priority=8.0 can_enter=false
[2026-02-16T13:24:33] [DEBUG] [NPC] Priority eval: GEEZ - occupy_building (priority=7.5, can_enter=false) npc=GEEZ state=occupy_building priority=7.5 can_enter=false
TASK SYSTEM LOGGER: Called at time 15.9
[2026-02-16T13:24:33] [INFO] [INVENTORY] === TASK SYSTEM LOG: 0 Land Claims ===
[2026-02-16T13:24:33] [INFO] [INVENTORY] TASK SYSTEM DEBUG: buildings group=0, with building_type=0, ovens=0
[2026-02-16T13:24:33] [INFO] [INVENTORY] === TASK SYSTEM LOG: 0 Ovens ===
[2026-02-16T13:24:33] [INFO] [INVENTORY] PlayerInventoryUI opened
Player inventory toggled: OPEN
[2026-02-16T13:24:33] [INFO] [INVENTORY] BuildingInventoryUI closed
[2026-02-16T13:24:34] [DEBUG] [NPC] Can enter check: DEIS cannot enter agro (not_caveman) npc=DEIS state=agro can_enter=false reason=not_caveman npc_type=woman
[2026-02-16T13:24:34] [DEBUG] [NPC] Priority eval: DEIS - agro (priority=15.0, can_enter=false) npc=DEIS state=agro priority=15.0 can_enter=false
[2026-02-16T13:24:34] [DEBUG] [NPC] Priority eval: DEIS - combat (priority=12.0, can_enter=false) npc=DEIS state=combat priority=12.0 can_enter=false
[2026-02-16T13:24:34] [DEBUG] [NPC] Can enter check: DEIS cannot enter herd (not_herded) npc=DEIS state=herd can_enter=false reason=not_herded herder=unknown
[2026-02-16T13:24:34] [DEBUG] [NPC] Priority eval: DEIS - herd (priority=11.0, can_enter=false) npc=DEIS state=herd priority=11.0 can_enter=false
[2026-02-16T13:24:34] [DEBUG] [NPC] Priority eval: DEIS - raid (priority=8.5, can_enter=false) npc=DEIS state=raid priority=8.5 can_enter=false
[2026-02-16T13:24:34] [DEBUG] [NPC] Priority eval: DEIS - reproduction (priority=8.0, can_enter=false) npc=DEIS state=reproduction priority=8.0 can_enter=false
[2026-02-16T13:24:34] [DEBUG] [NPC] Priority eval: DEIS - occupy_building (priority=7.5, can_enter=false) npc=DEIS state=occupy_building priority=7.5 can_enter=false
[2026-02-16T13:24:34] [DEBUG] [NPC] Priority eval: DEIS - work_at_building (priority=7.0, can_enter=false) npc=DEIS state=work_at_building priority=7.0 can_enter=false
[2026-02-16T13:24:34] [DEBUG] [NPC] Can enter check: DEIS cannot enter seek (no_target) npc=DEIS state=seek can_enter=false reason=no_target
[2026-02-16T13:24:35] [INFO] [NPC] POSITION: WUYA at (38.8, 557.0), state=wander, distance_to_claim=0.0/400.0, velocity=38.2 npc=WUYA pos=38.8,557.0 state=wander distance_to_claim=0.0 claim_radius=400.0 velocity=38.2
[2026-02-16T13:24:35] [DEBUG] [NPC] Can enter check: DEIS cannot enter agro (not_caveman) npc=DEIS state=agro can_enter=false reason=not_caveman npc_type=woman
[2026-02-16T13:24:35] [DEBUG] [NPC] Priority eval: DEIS - agro (priority=15.0, can_enter=false) npc=DEIS state=agro priority=15.0 can_enter=false
[2026-02-16T13:24:35] [DEBUG] [NPC] Priority eval: DEIS - combat (priority=12.0, can_enter=false) npc=DEIS state=combat priority=12.0 can_enter=false
[2026-02-16T13:24:35] [DEBUG] [NPC] Can enter check: DEIS cannot enter herd (not_herded) npc=DEIS state=herd can_enter=false reason=not_herded herder=unknown
[2026-02-16T13:24:35] [DEBUG] [NPC] Priority eval: DEIS - herd (priority=11.0, can_enter=false) npc=DEIS state=herd priority=11.0 can_enter=false
[2026-02-16T13:24:35] [DEBUG] [NPC] Priority eval: DEIS - raid (priority=8.5, can_enter=false) npc=DEIS state=raid priority=8.5 can_enter=false
[2026-02-16T13:24:35] [DEBUG] [NPC] Priority eval: DEIS - reproduction (priority=8.0, can_enter=false) npc=DEIS state=reproduction priority=8.0 can_enter=false
[2026-02-16T13:24:35] [DEBUG] [NPC] Priority eval: DEIS - occupy_building (priority=7.5, can_enter=false) npc=DEIS state=occupy_building priority=7.5 can_enter=false
[2026-02-16T13:24:35] [DEBUG] [NPC] Priority eval: DEIS - work_at_building (priority=7.0, can_enter=false) npc=DEIS state=work_at_building priority=7.0 can_enter=false
[2026-02-16T13:24:36] [INFO] [NPC] POSITION: WUYA at (38.8, 557.0), state=wander, distance_to_claim=0.0/400.0, velocity=33.5 npc=WUYA pos=38.8,557.0 state=wander distance_to_claim=0.0 claim_radius=400.0 velocity=33.5
[2026-02-16T13:24:36] [DEBUG] [NPC] Can enter check: BAHI cannot enter agro (not_caveman) npc=BAHI state=agro can_enter=false reason=not_caveman npc_type=woman
[2026-02-16T13:24:36] [DEBUG] [NPC] Priority eval: BAHI - agro (priority=15.0, can_enter=false) npc=BAHI state=agro priority=15.0 can_enter=false
[2026-02-16T13:24:36] [DEBUG] [NPC] Priority eval: BAHI - combat (priority=12.0, can_enter=false) npc=BAHI state=combat priority=12.0 can_enter=false
[2026-02-16T13:24:36] [DEBUG] [NPC] Can enter check: BAHI cannot enter herd (not_herded) npc=BAHI state=herd can_enter=false reason=not_herded herder=unknown
[2026-02-16T13:24:36] [DEBUG] [NPC] Priority eval: BAHI - herd (priority=11.0, can_enter=false) npc=BAHI state=herd priority=11.0 can_enter=false
[2026-02-16T13:24:36] [DEBUG] [NPC] Priority eval: BAHI - raid (priority=8.5, can_enter=false) npc=BAHI state=raid priority=8.5 can_enter=false
[2026-02-16T13:24:36] [DEBUG] [NPC] Priority eval: BAHI - reproduction (priority=8.0, can_enter=false) npc=BAHI state=reproduction priority=8.0 can_enter=false
[2026-02-16T13:24:36] [DEBUG] [NPC] Priority eval: BAHI - occupy_building (priority=7.5, can_enter=false) npc=BAHI state=occupy_building priority=7.5 can_enter=false
[2026-02-16T13:24:36] [DEBUG] [NPC] Priority eval: BAHI - work_at_building (priority=7.0, can_enter=false) npc=BAHI state=work_at_building priority=7.0 can_enter=false
TASK SYSTEM LOGGER: Called at time 18.9
[2026-02-16T13:24:36] [INFO] [INVENTORY] === TASK SYSTEM LOG: 0 Land Claims ===
[2026-02-16T13:24:36] [INFO] [INVENTORY] TASK SYSTEM DEBUG: buildings group=0, with building_type=0, ovens=0
[2026-02-16T13:24:36] [INFO] [INVENTORY] === TASK SYSTEM LOG: 0 Ovens ===
=== ClanNameDialog._ready() called ===
  name_input: true
  confirm_button: true
  Dialog setup complete, signals connected
  Focus set on name_input
🔵 _on_drag_ended() called
🔵 _on_drag_ended: from_slot=@TextureRect@18:<TextureRect#90009765532>, dragged_item={ "type": 10, "count": 1, "quality": 0 }
🔵 _on_drag_ended: item_type=10 (Land Claim)
🔵 _on_drag_ended: is_placeable_building=true
⚠️ Clan name dialog already open, ignoring duplicate request
[2026-02-16T13:24:37] [INFO] [NPC] POSITION: WUYA at (62.6, 548.7), state=wander, distance_to_claim=0.0/400.0, velocity=63.2 npc=WUYA pos=62.6,548.7 state=wander distance_to_claim=0.0 claim_radius=400.0 velocity=63.2
[2026-02-16T13:24:37] [DEBUG] [NPC] Can enter check: WUYA cannot enter agro (not_caveman) npc=WUYA state=agro can_enter=false reason=not_caveman npc_type=woman
[2026-02-16T13:24:37] [DEBUG] [NPC] Priority eval: WUYA - agro (priority=15.0, can_enter=false) npc=WUYA state=agro priority=15.0 can_enter=false
[2026-02-16T13:24:37] [DEBUG] [NPC] Priority eval: WUYA - combat (priority=12.0, can_enter=false) npc=WUYA state=combat priority=12.0 can_enter=false
[2026-02-16T13:24:37] [DEBUG] [NPC] Can enter check: WUYA cannot enter herd (not_herded) npc=WUYA state=herd can_enter=false reason=not_herded herder=unknown
[2026-02-16T13:24:37] [DEBUG] [NPC] Priority eval: WUYA - herd (priority=11.0, can_enter=false) npc=WUYA state=herd priority=11.0 can_enter=false
[2026-02-16T13:24:37] [DEBUG] [NPC] Priority eval: WUYA - raid (priority=8.5, can_enter=false) npc=WUYA state=raid priority=8.5 can_enter=false
[2026-02-16T13:24:37] [DEBUG] [NPC] Priority eval: WUYA - reproduction (priority=8.0, can_enter=false) npc=WUYA state=reproduction priority=8.0 can_enter=false
[2026-02-16T13:24:37] [DEBUG] [NPC] Priority eval: WUYA - occupy_building (priority=7.5, can_enter=false) npc=WUYA state=occupy_building priority=7.5 can_enter=false
[2026-02-16T13:24:37] [DEBUG] [NPC] Priority eval: WUYA - work_at_building (priority=7.0, can_enter=false) npc=WUYA state=work_at_building priority=7.0 can_enter=false
[2026-02-16T13:24:38] [DEBUG] [NPC] Can enter check: XIUF cannot enter agro (not_caveman) npc=XIUF state=agro can_enter=false reason=not_caveman npc_type=woman
[2026-02-16T13:24:38] [DEBUG] [NPC] Priority eval: XIUF - agro (priority=15.0, can_enter=false) npc=XIUF state=agro priority=15.0 can_enter=false
[2026-02-16T13:24:38] [DEBUG] [NPC] Priority eval: XIUF - combat (priority=12.0, can_enter=false) npc=XIUF state=combat priority=12.0 can_enter=false
[2026-02-16T13:24:38] [DEBUG] [NPC] Can enter check: XIUF cannot enter herd (not_herded) npc=XIUF state=herd can_enter=false reason=not_herded herder=unknown
[2026-02-16T13:24:38] [DEBUG] [NPC] Priority eval: XIUF - herd (priority=11.0, can_enter=false) npc=XIUF state=herd priority=11.0 can_enter=false
[2026-02-16T13:24:38] [DEBUG] [NPC] Priority eval: XIUF - raid (priority=8.5, can_enter=false) npc=XIUF state=raid priority=8.5 can_enter=false
[2026-02-16T13:24:38] [DEBUG] [NPC] Priority eval: XIUF - reproduction (priority=8.0, can_enter=false) npc=XIUF state=reproduction priority=8.0 can_enter=false
[2026-02-16T13:24:38] [DEBUG] [NPC] Priority eval: XIUF - occupy_building (priority=7.5, can_enter=false) npc=XIUF state=occupy_building priority=7.5 can_enter=false
[2026-02-16T13:24:38] [DEBUG] [NPC] Priority eval: XIUF - work_at_building (priority=7.0, can_enter=false) npc=XIUF state=work_at_building priority=7.0 can_enter=false
[2026-02-16T13:24:38] [DEBUG] [NPC] Can enter check: XIUF cannot enter seek (no_target) npc=XIUF state=seek can_enter=false reason=no_target
[2026-02-16T13:24:39] [INFO] [NPC] POSITION: BAHI at (422.2, -191.2), state=wander, distance_to_claim=0.0/400.0, velocity=68.6 npc=BAHI pos=422.2,-191.2 state=wander distance_to_claim=0.0 claim_radius=400.0 velocity=68.6
[2026-02-16T13:24:39] [DEBUG] [NPC] Can enter check: BAHI can enter idle (always_available) npc=BAHI state=idle can_enter=true reason=always_available
[2026-02-16T13:24:39] [DEBUG] [NPC] Can enter check: BAHI can enter wander (no_higher_priority_needs) npc=BAHI state=wander can_enter=true reason=no_higher_priority_needs
[2026-02-16T13:24:39] [DEBUG] [NPC] Can enter check: BAHI cannot enter seek (no_target) npc=BAHI state=seek can_enter=false reason=no_target
[2026-02-16T13:24:39] [DEBUG] [NPC] Can enter check: BAHI cannot enter herd (not_herded) npc=BAHI state=herd can_enter=false reason=not_herded herder=unknown
[2026-02-16T13:24:39] [DEBUG] [NPC] Can enter check: BAHI cannot enter agro (not_caveman) npc=BAHI state=agro can_enter=false reason=not_caveman npc_type=woman
[2026-02-16T13:24:39] [DEBUG] [NPC] Can enter check: BAHI cannot enter herd_wildnpc (not_caveman_or_clansman) npc=BAHI state=herd_wildnpc can_enter=false reason=not_caveman_or_clansman npc_type=woman
[2026-02-16T13:24:39] [INFO] [NPC] STATE_EXIT: BAHI exited wander after 3.5s npc=BAHI state=wander duration_s=3.5
[2026-02-16T13:24:39] [INFO] [NPC] State exited: BAHI left wander npc=BAHI state=wander
[2026-02-16T13:24:39] [INFO] [NPC] STATE_ENTRY: BAHI entered idle (from wander) npc=BAHI state=idle from_state=wander
TASK SYSTEM LOGGER: Called at time 21.9
[2026-02-16T13:24:39] [INFO] [INVENTORY] === TASK SYSTEM LOG: 0 Land Claims ===
[2026-02-16T13:24:39] [INFO] [INVENTORY] TASK SYSTEM DEBUG: buildings group=0, with building_type=0, ovens=0
[2026-02-16T13:24:39] [INFO] [INVENTORY] === TASK SYSTEM LOG: 0 Ovens ===
[2026-02-16T13:24:40] [DEBUG] [NPC] Can enter check: WUYA cannot enter agro (not_caveman) npc=WUYA state=agro can_enter=false reason=not_caveman npc_type=woman
[2026-02-16T13:24:40] [DEBUG] [NPC] Priority eval: WUYA - agro (priority=15.0, can_enter=false) npc=WUYA state=agro priority=15.0 can_enter=false
[2026-02-16T13:24:40] [DEBUG] [NPC] Priority eval: WUYA - combat (priority=12.0, can_enter=false) npc=WUYA state=combat priority=12.0 can_enter=false
[2026-02-16T13:24:40] [DEBUG] [NPC] Can enter check: WUYA cannot enter herd (not_herded) npc=WUYA state=herd can_enter=false reason=not_herded herder=unknown
[2026-02-16T13:24:40] [DEBUG] [NPC] Priority eval: WUYA - herd (priority=11.0, can_enter=false) npc=WUYA state=herd priority=11.0 can_enter=false
[2026-02-16T13:24:40] [DEBUG] [NPC] Priority eval: WUYA - raid (priority=8.5, can_enter=false) npc=WUYA state=raid priority=8.5 can_enter=false
[2026-02-16T13:24:40] [DEBUG] [NPC] Priority eval: WUYA - reproduction (priority=8.0, can_enter=false) npc=WUYA state=reproduction priority=8.0 can_enter=false
[2026-02-16T13:24:40] [DEBUG] [NPC] Priority eval: WUYA - occupy_building (priority=7.5, can_enter=false) npc=WUYA state=occupy_building priority=7.5 can_enter=false
[2026-02-16T13:24:40] [DEBUG] [NPC] Priority eval: WUYA - work_at_building (priority=7.0, can_enter=false) npc=WUYA state=work_at_building priority=7.0 can_enter=false
[2026-02-16T13:24:40] [DEBUG] [NPC] Can enter check: WUYA cannot enter seek (no_target) npc=WUYA state=seek can_enter=false reason=no_target
=== ClanNameDialog._on_confirm() called ===
  Clan name: OKOK length: 4
  Emitting name_confirmed signal with name: OKOK
✓ Player name set to: OKOK
🔵 LAND_CLAIM._READY: Using EXISTING inventory for OKOK (inventory=<RefCounted#-9223371727248027720>, slot_count=12)
🧠 ClanBrain initialized for clan: OKOK
✓ Land claim placed at (-1049.549, 688.502) with name: OKOK
[MONITOR] Land claim placed at (-1049.549, 688.502) clan=OKOK
  Building inventory created with 12 slots (stacking enabled)
  Dialog closed
[2026-02-16T13:24:41] [DEBUG] [NPC] Can enter check: WUYA cannot enter agro (not_caveman) npc=WUYA state=agro can_enter=false reason=not_caveman npc_type=woman
[2026-02-16T13:24:41] [DEBUG] [NPC] Priority eval: WUYA - agro (priority=15.0, can_enter=false) npc=WUYA state=agro priority=15.0 can_enter=false
[2026-02-16T13:24:41] [DEBUG] [NPC] Priority eval: WUYA - combat (priority=12.0, can_enter=false) npc=WUYA state=combat priority=12.0 can_enter=false
[2026-02-16T13:24:41] [DEBUG] [NPC] Can enter check: WUYA cannot enter herd (not_herded) npc=WUYA state=herd can_enter=false reason=not_herded herder=unknown
[2026-02-16T13:24:41] [DEBUG] [NPC] Priority eval: WUYA - herd (priority=11.0, can_enter=false) npc=WUYA state=herd priority=11.0 can_enter=false
[2026-02-16T13:24:41] [DEBUG] [NPC] Priority eval: WUYA - raid (priority=8.5, can_enter=false) npc=WUYA state=raid priority=8.5 can_enter=false
[2026-02-16T13:24:41] [DEBUG] [NPC] Priority eval: WUYA - reproduction (priority=8.0, can_enter=false) npc=WUYA state=reproduction priority=8.0 can_enter=false
[2026-02-16T13:24:41] [DEBUG] [NPC] Priority eval: WUYA - occupy_building (priority=7.5, can_enter=false) npc=WUYA state=occupy_building priority=7.5 can_enter=false
[2026-02-16T13:24:41] [DEBUG] [NPC] Priority eval: WUYA - work_at_building (priority=7.0, can_enter=false) npc=WUYA state=work_at_building priority=7.0 can_enter=false
[2026-02-16T13:24:41] [DEBUG] [NPC] Can enter check: WUYA cannot enter seek (no_target) npc=WUYA state=seek can_enter=false reason=no_target
🔵 _place_building() called: type=Farm, pos=(-1238.64, 622.5357), from_slot=@TextureRect@19:<TextureRect#90278201004>, dragged_item_data={  }
🔵 _place_building: original_item={ "type": 15, "count": 1 }
🔵 _place_building: player_land_claim = LandClaim:<Node2D#309556416475>
✅ _place_building: Validation passed, creating building...
🔵 _on_drag_ended() called
🔵 _on_drag_ended: from_slot=@TextureRect@19:<TextureRect#90278201004>, dragged_item={ "type": 15, "count": 1, "quality": 0 }
🔵 _on_drag_ended: item_type=15 (Farm)
🔵 _on_drag_ended: is_placeable_building=true
🔵 BUILDING PLACEMENT: from_slot valid: true
🔵 _place_building() called: type=Farm, pos=(-1238.64, 622.5357), from_slot=@TextureRect@19:<TextureRect#90278201004>, dragged_item_data={ "type": 15, "count": 1, "quality": 0 }
🔵 _place_building: original_item={ "type": 15, "count": 1, "quality": 0 }
🔵 _place_building: player_land_claim = LandClaim:<Node2D#309556416475>
✅ _place_building: Validation passed, creating building...
🔵 _place_building: Instantiating building scene...
🔵 _place_building: Building instantiated successfully
🔵 _place_building: Setting building properties...
🔵 _place_building: Setting building_type...
🔵 _place_building: building_type set successfully
🔵 _place_building: Getting clan_name from land claim...
🔵 _place_building: Got clan_name via direct property: OKOK
🔵 _place_building: Setting clan_name=OKOK...
🔵 _place_building: clan_name set successfully
🔵 _place_building: Setting player_owned=true...
🔵 _place_building: player_owned set successfully
🔵 _place_building: Setting global_position=(-1238.64, 622.5357)...
🔵 _place_building: global_position set successfully
🔵 _place_building: All properties set - type=Farm, clan=OKOK, pos=(-1238.64, 622.5357)
🔵 _place_building: Adding building to scene tree...
🔵 ProductionComponent._ready() - process enabled
🔵 _place_building: Building added to scene tree, _ready() should have been called
Building Farm placed at (-1238.64, 622.5357) (inside land claim: OKOK)
[MONITOR] Farm placed at (-1238.64, 622.5357) clan=OKOK
🔵 _place_building: Instantiating building scene...
🔵 _place_building: Building instantiated successfully
🔵 _place_building: Setting building properties...
🔵 _place_building: Setting building_type...
🔵 _place_building: building_type set successfully
🔵 _place_building: Getting clan_name from land claim...
🔵 _place_building: Got clan_name via direct property: OKOK
🔵 _place_building: Setting clan_name=OKOK...
🔵 _place_building: clan_name set successfully
🔵 _place_building: Setting player_owned=true...
🔵 _place_building: player_owned set successfully
🔵 _place_building: Setting global_position=(-1238.64, 622.5357)...
🔵 _place_building: global_position set successfully
🔵 _place_building: All properties set - type=Farm, clan=OKOK, pos=(-1238.64, 622.5357)
🔵 _place_building: Adding building to scene tree...
🔵 ProductionComponent._ready() - process enabled
🔵 _place_building: Building added to scene tree, _ready() should have been called
Building Farm placed at (-1238.64, 622.5357) (inside land claim: OKOK)
[MONITOR] Farm placed at (-1238.64, 622.5357) clan=OKOK
TASK SYSTEM LOGGER: Called at time 24.9
[2026-02-16T13:24:42] [INFO] [INVENTORY] === TASK SYSTEM LOG: 1 Land Claims ===
[2026-02-16T13:24:42] [INFO] [INVENTORY] LAND CLAIM: OKOK | Pos: (-1050, 689) | Inventory: empty clan_name=OKOK position=(-1049.549, 688.502) inventory=[]
[2026-02-16T13:24:42] [INFO] [INVENTORY] TASK SYSTEM DEBUG: buildings group=3, with building_type=2, ovens=0
[2026-02-16T13:24:42] [INFO] [INVENTORY] === TASK SYSTEM LOG: 0 Ovens ===
[2026-02-16T13:24:43] [DEBUG] [NPC] Can enter check: WUEC cannot enter agro (not_caveman) npc=WUEC state=agro can_enter=false reason=not_caveman npc_type=woman
[2026-02-16T13:24:43] [DEBUG] [NPC] Priority eval: WUEC - agro (priority=15.0, can_enter=false) npc=WUEC state=agro priority=15.0 can_enter=false
[2026-02-16T13:24:43] [DEBUG] [NPC] Priority eval: WUEC - combat (priority=12.0, can_enter=false) npc=WUEC state=combat priority=12.0 can_enter=false
[2026-02-16T13:24:43] [DEBUG] [NPC] Can enter check: WUEC cannot enter herd (not_herded) npc=WUEC state=herd can_enter=false reason=not_herded herder=unknown
[2026-02-16T13:24:43] [DEBUG] [NPC] Priority eval: WUEC - herd (priority=11.0, can_enter=false) npc=WUEC state=herd priority=11.0 can_enter=false
[2026-02-16T13:24:43] [DEBUG] [NPC] Priority eval: WUEC - raid (priority=8.5, can_enter=false) npc=WUEC state=raid priority=8.5 can_enter=false
[2026-02-16T13:24:43] [DEBUG] [NPC] Priority eval: WUEC - reproduction (priority=8.0, can_enter=false) npc=WUEC state=reproduction priority=8.0 can_enter=false
[2026-02-16T13:24:43] [DEBUG] [NPC] Priority eval: WUEC - occupy_building (priority=7.5, can_enter=false) npc=WUEC state=occupy_building priority=7.5 can_enter=false
[2026-02-16T13:24:43] [DEBUG] [NPC] Priority eval: WUEC - work_at_building (priority=7.0, can_enter=false) npc=WUEC state=work_at_building priority=7.0 can_enter=false
[2026-02-16T13:24:43] [DEBUG] [NPC] Can enter check: WUEC cannot enter seek (no_target) npc=WUEC state=seek can_enter=false reason=no_target
[2026-02-16T13:24:44] [DEBUG] [NPC] Can enter check: Goat 1419 cannot enter agro (not_caveman) npc=Goat 1419 state=agro can_enter=false reason=not_caveman npc_type=goat
[2026-02-16T13:24:44] [DEBUG] [NPC] Priority eval: Goat 1419 - agro (priority=15.0, can_enter=false) npc=Goat 1419 state=agro priority=15.0 can_enter=false
[2026-02-16T13:24:44] [DEBUG] [NPC] Priority eval: Goat 1419 - combat (priority=12.0, can_enter=false) npc=Goat 1419 state=combat priority=12.0 can_enter=false
[2026-02-16T13:24:44] [DEBUG] [NPC] Can enter check: Goat 1419 cannot enter herd (not_herded) npc=Goat 1419 state=herd can_enter=false reason=not_herded herder=unknown
[2026-02-16T13:24:44] [DEBUG] [NPC] Priority eval: Goat 1419 - herd (priority=11.0, can_enter=false) npc=Goat 1419 state=herd priority=11.0 can_enter=false
[2026-02-16T13:24:44] [DEBUG] [NPC] Priority eval: Goat 1419 - raid (priority=8.5, can_enter=false) npc=Goat 1419 state=raid priority=8.5 can_enter=false
[2026-02-16T13:24:44] [DEBUG] [NPC] Priority eval: Goat 1419 - reproduction (priority=8.0, can_enter=false) npc=Goat 1419 state=reproduction priority=8.0 can_enter=false
[2026-02-16T13:24:44] [DEBUG] [NPC] Priority eval: Goat 1419 - occupy_building (priority=7.5, can_enter=false) npc=Goat 1419 state=occupy_building priority=7.5 can_enter=false
[2026-02-16T13:24:44] [DEBUG] [NPC] Priority eval: Goat 1419 - work_at_building (priority=7.0, can_enter=false) npc=Goat 1419 state=work_at_building priority=7.0 can_enter=false
[2026-02-16T13:24:44] [DEBUG] [NPC] Can enter check: Goat 1419 cannot enter seek (no_target) npc=Goat 1419 state=seek can_enter=false reason=no_target
🔵 _place_building() called: type=Dairy Farm, pos=(-852.6257, 749.9959), from_slot=@TextureRect@20:<TextureRect#90546636476>, dragged_item_data={  }
🔵 _place_building: original_item={ "type": 14, "count": 1 }
🔵 _place_building: player_land_claim = LandClaim:<Node2D#309556416475>
✅ _place_building: Validation passed, creating building...
🔵 _on_drag_ended() called
🔵 _on_drag_ended: from_slot=@TextureRect@20:<TextureRect#90546636476>, dragged_item={ "type": 14, "count": 1, "quality": 0 }
🔵 _on_drag_ended: item_type=14 (Dairy Farm)
🔵 _on_drag_ended: is_placeable_building=true
🔵 BUILDING PLACEMENT: from_slot valid: true
🔵 _place_building() called: type=Dairy Farm, pos=(-852.6257, 749.9959), from_slot=@TextureRect@20:<TextureRect#90546636476>, dragged_item_data={ "type": 14, "count": 1, "quality": 0 }
🔵 _place_building: original_item={ "type": 14, "count": 1, "quality": 0 }
🔵 _place_building: player_land_claim = LandClaim:<Node2D#309556416475>
✅ _place_building: Validation passed, creating building...
🔵 _place_building: Instantiating building scene...
🔵 _place_building: Building instantiated successfully
🔵 _place_building: Setting building properties...
🔵 _place_building: Setting building_type...
🔵 _place_building: building_type set successfully
🔵 _place_building: Getting clan_name from land claim...
🔵 _place_building: Got clan_name via direct property: OKOK
🔵 _place_building: Setting clan_name=OKOK...
🔵 _place_building: clan_name set successfully
🔵 _place_building: Setting player_owned=true...
🔵 _place_building: player_owned set successfully
🔵 _place_building: Setting global_position=(-852.6257, 749.9959)...
🔵 _place_building: global_position set successfully
🔵 _place_building: All properties set - type=Dairy Farm, clan=OKOK, pos=(-852.6257, 749.9959)
🔵 _place_building: Adding building to scene tree...
🔵 ProductionComponent._ready() - process enabled
🔵 _place_building: Building added to scene tree, _ready() should have been called
Building Dairy Farm placed at (-852.6257, 749.9959) (inside land claim: OKOK)
[MONITOR] Dairy placed at (-852.6257, 749.9959) clan=OKOK
🔵 _place_building: Instantiating building scene...
🔵 _place_building: Building instantiated successfully
🔵 _place_building: Setting building properties...
🔵 _place_building: Setting building_type...
🔵 _place_building: building_type set successfully
🔵 _place_building: Getting clan_name from land claim...
🔵 _place_building: Got clan_name via direct property: OKOK
🔵 _place_building: Setting clan_name=OKOK...
🔵 _place_building: clan_name set successfully
🔵 _place_building: Setting player_owned=true...
🔵 _place_building: player_owned set successfully
🔵 _place_building: Setting global_position=(-852.6257, 749.9959)...
🔵 _place_building: global_position set successfully
🔵 _place_building: All properties set - type=Dairy Farm, clan=OKOK, pos=(-852.6257, 749.9959)
🔵 _place_building: Adding building to scene tree...
🔵 ProductionComponent._ready() - process enabled
🔵 _place_building: Building added to scene tree, _ready() should have been called
Building Dairy Farm placed at (-852.6257, 749.9959) (inside land claim: OKOK)
[MONITOR] Dairy placed at (-852.6257, 749.9959) clan=OKOK
[2026-02-16T13:24:45] [INFO] [INVENTORY] PlayerInventoryUI closed
Player inventory toggled: CLOSED
[2026-02-16T13:24:45] [INFO] [INVENTORY] BuildingInventoryUI closed
[2026-02-16T13:24:45] [DEBUG] [NPC] Can enter check: Sheep 1217 cannot enter agro (not_caveman) npc=Sheep 1217 state=agro can_enter=false reason=not_caveman npc_type=sheep
[2026-02-16T13:24:45] [DEBUG] [NPC] Priority eval: Sheep 1217 - agro (priority=15.0, can_enter=false) npc=Sheep 1217 state=agro priority=15.0 can_enter=false
[2026-02-16T13:24:45] [DEBUG] [NPC] Priority eval: Sheep 1217 - combat (priority=12.0, can_enter=false) npc=Sheep 1217 state=combat priority=12.0 can_enter=false
[2026-02-16T13:24:45] [DEBUG] [NPC] Can enter check: Sheep 1217 cannot enter herd (not_herded) npc=Sheep 1217 state=herd can_enter=false reason=not_herded herder=unknown
[2026-02-16T13:24:45] [DEBUG] [NPC] Priority eval: Sheep 1217 - herd (priority=11.0, can_enter=false) npc=Sheep 1217 state=herd priority=11.0 can_enter=false
[2026-02-16T13:24:45] [DEBUG] [NPC] Priority eval: Sheep 1217 - raid (priority=8.5, can_enter=false) npc=Sheep 1217 state=raid priority=8.5 can_enter=false
[2026-02-16T13:24:45] [DEBUG] [NPC] Priority eval: Sheep 1217 - reproduction (priority=8.0, can_enter=false) npc=Sheep 1217 state=reproduction priority=8.0 can_enter=false
[2026-02-16T13:24:45] [DEBUG] [NPC] Priority eval: Sheep 1217 - occupy_building (priority=7.5, can_enter=false) npc=Sheep 1217 state=occupy_building priority=7.5 can_enter=false
[2026-02-16T13:24:45] [DEBUG] [NPC] Priority eval: Sheep 1217 - work_at_building (priority=7.0, can_enter=false) npc=Sheep 1217 state=work_at_building priority=7.0 can_enter=false
[2026-02-16T13:24:45] [DEBUG] [NPC] Can enter check: Sheep 1217 cannot enter seek (no_target) npc=Sheep 1217 state=seek can_enter=false reason=no_target
TASK SYSTEM LOGGER: Called at time 27.9
[2026-02-16T13:24:45] [INFO] [INVENTORY] === TASK SYSTEM LOG: 1 Land Claims ===
[2026-02-16T13:24:45] [INFO] [INVENTORY] LAND CLAIM: OKOK | Pos: (-1050, 689) | Inventory: empty clan_name=OKOK position=(-1049.549, 688.502) inventory=[]
[2026-02-16T13:24:45] [INFO] [INVENTORY] TASK SYSTEM DEBUG: buildings group=5, with building_type=4, ovens=0
[2026-02-16T13:24:45] [INFO] [INVENTORY] === TASK SYSTEM LOG: 0 Ovens ===
[2026-02-16T13:24:46] [DEBUG] [NPC] Can enter check: WUEC cannot enter agro (not_caveman) npc=WUEC state=agro can_enter=false reason=not_caveman npc_type=woman
[2026-02-16T13:24:46] [DEBUG] [NPC] Priority eval: WUEC - agro (priority=15.0, can_enter=false) npc=WUEC state=agro priority=15.0 can_enter=false
[2026-02-16T13:24:46] [DEBUG] [NPC] Priority eval: WUEC - combat (priority=12.0, can_enter=false) npc=WUEC state=combat priority=12.0 can_enter=false
[2026-02-16T13:24:46] [DEBUG] [NPC] Can enter check: WUEC cannot enter herd (not_herded) npc=WUEC state=herd can_enter=false reason=not_herded herder=unknown
[2026-02-16T13:24:46] [DEBUG] [NPC] Priority eval: WUEC - herd (priority=11.0, can_enter=false) npc=WUEC state=herd priority=11.0 can_enter=false
[2026-02-16T13:24:46] [DEBUG] [NPC] Priority eval: WUEC - raid (priority=8.5, can_enter=false) npc=WUEC state=raid priority=8.5 can_enter=false
[2026-02-16T13:24:46] [DEBUG] [NPC] Priority eval: WUEC - reproduction (priority=8.0, can_enter=false) npc=WUEC state=reproduction priority=8.0 can_enter=false
[2026-02-16T13:24:46] [DEBUG] [NPC] Priority eval: WUEC - occupy_building (priority=7.5, can_enter=false) npc=WUEC state=occupy_building priority=7.5 can_enter=false
[2026-02-16T13:24:46] [DEBUG] [NPC] Priority eval: WUEC - work_at_building (priority=7.0, can_enter=false) npc=WUEC state=work_at_building priority=7.0 can_enter=false
[2026-02-16T13:24:46] [DEBUG] [NPC] Can enter check: WUEC cannot enter seek (no_target) npc=WUEC state=seek can_enter=false reason=no_target
[2026-02-16T13:24:47] [DEBUG] [NPC] Can enter check: KUKO cannot enter agro (not_caveman) npc=KUKO state=agro can_enter=false reason=not_caveman npc_type=woman
[2026-02-16T13:24:47] [DEBUG] [NPC] Priority eval: KUKO - agro (priority=15.0, can_enter=false) npc=KUKO state=agro priority=15.0 can_enter=false
[2026-02-16T13:24:47] [DEBUG] [NPC] Priority eval: KUKO - combat (priority=12.0, can_enter=false) npc=KUKO state=combat priority=12.0 can_enter=false
[2026-02-16T13:24:47] [DEBUG] [NPC] Can enter check: KUKO cannot enter herd (not_herded) npc=KUKO state=herd can_enter=false reason=not_herded herder=unknown
[2026-02-16T13:24:47] [DEBUG] [NPC] Priority eval: KUKO - herd (priority=11.0, can_enter=false) npc=KUKO state=herd priority=11.0 can_enter=false
[2026-02-16T13:24:47] [DEBUG] [NPC] Priority eval: KUKO - raid (priority=8.5, can_enter=false) npc=KUKO state=raid priority=8.5 can_enter=false
[2026-02-16T13:24:47] [DEBUG] [NPC] Priority eval: KUKO - reproduction (priority=8.0, can_enter=false) npc=KUKO state=reproduction priority=8.0 can_enter=false
[2026-02-16T13:24:47] [DEBUG] [NPC] Priority eval: KUKO - occupy_building (priority=7.5, can_enter=false) npc=KUKO state=occupy_building priority=7.5 can_enter=false
[2026-02-16T13:24:47] [DEBUG] [NPC] Priority eval: KUKO - work_at_building (priority=7.0, can_enter=false) npc=KUKO state=work_at_building priority=7.0 can_enter=false
[2026-02-16T13:24:47] [DEBUG] [NPC] Can enter check: KUKO cannot enter seek (no_target) npc=KUKO state=seek can_enter=false reason=no_target
[2026-02-16T13:24:48] [DEBUG] [NPC] Can enter check: KUKO cannot enter agro (not_caveman) npc=KUKO state=agro can_enter=false reason=not_caveman npc_type=woman
[2026-02-16T13:24:48] [DEBUG] [NPC] Priority eval: KUKO - agro (priority=15.0, can_enter=false) npc=KUKO state=agro priority=15.0 can_enter=false
[2026-02-16T13:24:48] [DEBUG] [NPC] Priority eval: KUKO - combat (priority=12.0, can_enter=false) npc=KUKO state=combat priority=12.0 can_enter=false
[2026-02-16T13:24:48] [DEBUG] [NPC] Can enter check: KUKO cannot enter herd (not_herded) npc=KUKO state=herd can_enter=false reason=not_herded herder=unknown
[2026-02-16T13:24:48] [DEBUG] [NPC] Priority eval: KUKO - herd (priority=11.0, can_enter=false) npc=KUKO state=herd priority=11.0 can_enter=false
[2026-02-16T13:24:48] [DEBUG] [NPC] Priority eval: KUKO - raid (priority=8.5, can_enter=false) npc=KUKO state=raid priority=8.5 can_enter=false
[2026-02-16T13:24:48] [DEBUG] [NPC] Priority eval: KUKO - reproduction (priority=8.0, can_enter=false) npc=KUKO state=reproduction priority=8.0 can_enter=false
[2026-02-16T13:24:48] [DEBUG] [NPC] Priority eval: KUKO - occupy_building (priority=7.5, can_enter=false) npc=KUKO state=occupy_building priority=7.5 can_enter=false
[2026-02-16T13:24:48] [DEBUG] [NPC] Priority eval: KUKO - work_at_building (priority=7.0, can_enter=false) npc=KUKO state=work_at_building priority=7.0 can_enter=false
[2026-02-16T13:24:48] [DEBUG] [NPC] Can enter check: KUKO cannot enter seek (no_target) npc=KUKO state=seek can_enter=false reason=no_target
TASK SYSTEM LOGGER: Called at time 30.9
[2026-02-16T13:24:48] [INFO] [INVENTORY] === TASK SYSTEM LOG: 1 Land Claims ===
[2026-02-16T13:24:48] [INFO] [INVENTORY] LAND CLAIM: OKOK | Pos: (-1050, 689) | Inventory: empty clan_name=OKOK position=(-1049.549, 688.502) inventory=[]
[2026-02-16T13:24:48] [INFO] [INVENTORY] TASK SYSTEM DEBUG: buildings group=5, with building_type=4, ovens=0
[2026-02-16T13:24:48] [INFO] [INVENTORY] === TASK SYSTEM LOG: 0 Ovens ===
🎨 ANIMATION: _load_attack_sprite_sheet() called
🎨 ANIMATION: Loading sprite sheet from: res://assets/sprites/swingclub.png
✅ ANIMATION: Sprite sheet loaded successfully
🎨 ANIMATION: Texture dimensions - width=840, height=560
✅ ANIMATION: Frame size: 280x280 (grid 3x2)
✅ ANIMATION: Default sprite texture stored
FSM: Creating states for JOEC - idle:OK wander:OK seek:OK eat:OK gather:OK herd:OK herd_wildnpc:OK agro:OK build:OK
FSM: Successfully created eat state for JOEC
FSM: Successfully created gather state for JOEC
FSM: Successfully created herd state for JOEC
FSM: Successfully created herd_wildnpc state for JOEC
FSM: Successfully created agro state for JOEC
FSM: Successfully created combat state for JOEC
FSM: Successfully created defend state for JOEC
FSM: Successfully created raid state for JOEC
FSM: Successfully created search state for JOEC
FSM: Successfully created build state for JOEC
FSM: Successfully created reproduction state for JOEC
FSM: Successfully created occupy_building state for JOEC
FSM: Successfully created work_at_building state for JOEC
FSM: Successfully created craft state for JOEC
Task System: Created TaskRunner component for JOEC
✓ Respawned Wild Woman: JOEC at (-23.58099, 1413.936) (agility 9.0 = 288.0 speed)
[2026-02-16T13:24:49] [DEBUG] [NPC] Can enter check: XIUF cannot enter agro (not_caveman) npc=XIUF state=agro can_enter=false reason=not_caveman npc_type=woman
[2026-02-16T13:24:49] [DEBUG] [NPC] Priority eval: XIUF - agro (priority=15.0, can_enter=false) npc=XIUF state=agro priority=15.0 can_enter=false
[2026-02-16T13:24:49] [DEBUG] [NPC] Priority eval: XIUF - combat (priority=12.0, can_enter=false) npc=XIUF state=combat priority=12.0 can_enter=false
[2026-02-16T13:24:49] [DEBUG] [NPC] Can enter check: XIUF cannot enter herd (not_herded) npc=XIUF state=herd can_enter=false reason=not_herded herder=unknown
[2026-02-16T13:24:49] [DEBUG] [NPC] Priority eval: XIUF - herd (priority=11.0, can_enter=false) npc=XIUF state=herd priority=11.0 can_enter=false
[2026-02-16T13:24:49] [DEBUG] [NPC] Priority eval: XIUF - raid (priority=8.5, can_enter=false) npc=XIUF state=raid priority=8.5 can_enter=false
[2026-02-16T13:24:49] [DEBUG] [NPC] Priority eval: XIUF - reproduction (priority=8.0, can_enter=false) npc=XIUF state=reproduction priority=8.0 can_enter=false
[2026-02-16T13:24:49] [DEBUG] [NPC] Priority eval: XIUF - occupy_building (priority=7.5, can_enter=false) npc=XIUF state=occupy_building priority=7.5 can_enter=false
[2026-02-16T13:24:49] [DEBUG] [NPC] Priority eval: XIUF - work_at_building (priority=7.0, can_enter=false) npc=XIUF state=work_at_building priority=7.0 can_enter=false
[2026-02-16T13:24:49] [DEBUG] [NPC] Can enter check: XIUF cannot enter seek (no_target) npc=XIUF state=seek can_enter=false reason=no_target
[2026-02-16T13:24:50] [WARNING] [NPC] STATE_DURATION: JOEC in wander for 32.4s (LONG - potentially stuck!) npc=JOEC state=wander duration_s=32.4 warning=potentially_stuck
🚨 HIGH PRIORITY FOLLOW: Goat 1218 immediately entered herd state (following Player)
[2026-02-16T13:24:50] [INFO] [NPC] POSITION: Goat 1419 at (-646.0, -768.8), state=wander, distance_to_claim=0.0/400.0, velocity=36.9 npc=Goat 1419 pos=-646.0,-768.8 state=wander distance_to_claim=0.0 claim_radius=400.0 velocity=36.9
[2026-02-16T13:24:50] [DEBUG] [NPC] Can enter check: Goat 1419 cannot enter agro (not_caveman) npc=Goat 1419 state=agro can_enter=false reason=not_caveman npc_type=goat
[2026-02-16T13:24:50] [DEBUG] [NPC] Priority eval: Goat 1419 - agro (priority=15.0, can_enter=false) npc=Goat 1419 state=agro priority=15.0 can_enter=false
[2026-02-16T13:24:50] [DEBUG] [NPC] Priority eval: Goat 1419 - combat (priority=12.0, can_enter=false) npc=Goat 1419 state=combat priority=12.0 can_enter=false
[2026-02-16T13:24:50] [DEBUG] [NPC] Can enter check: Goat 1419 cannot enter herd (not_herded) npc=Goat 1419 state=herd can_enter=false reason=not_herded herder=unknown
[2026-02-16T13:24:50] [DEBUG] [NPC] Priority eval: Goat 1419 - herd (priority=11.0, can_enter=false) npc=Goat 1419 state=herd priority=11.0 can_enter=false
[2026-02-16T13:24:50] [DEBUG] [NPC] Priority eval: Goat 1419 - raid (priority=8.5, can_enter=false) npc=Goat 1419 state=raid priority=8.5 can_enter=false
[2026-02-16T13:24:50] [DEBUG] [NPC] Priority eval: Goat 1419 - reproduction (priority=8.0, can_enter=false) npc=Goat 1419 state=reproduction priority=8.0 can_enter=false
[2026-02-16T13:24:50] [DEBUG] [NPC] Priority eval: Goat 1419 - occupy_building (priority=7.5, can_enter=false) npc=Goat 1419 state=occupy_building priority=7.5 can_enter=false
[2026-02-16T13:24:50] [DEBUG] [NPC] Priority eval: Goat 1419 - work_at_building (priority=7.0, can_enter=false) npc=Goat 1419 state=work_at_building priority=7.0 can_enter=false
[2026-02-16T13:24:51] [DEBUG] [NPC] Can enter check: Sheep 1418 cannot enter agro (not_caveman) npc=Sheep 1418 state=agro can_enter=false reason=not_caveman npc_type=sheep
[2026-02-16T13:24:51] [DEBUG] [NPC] Priority eval: Sheep 1418 - agro (priority=15.0, can_enter=false) npc=Sheep 1418 state=agro priority=15.0 can_enter=false
[2026-02-16T13:24:51] [DEBUG] [NPC] Priority eval: Sheep 1418 - combat (priority=12.0, can_enter=false) npc=Sheep 1418 state=combat priority=12.0 can_enter=false
[2026-02-16T13:24:51] [DEBUG] [NPC] Can enter check: Sheep 1418 cannot enter herd (not_herded) npc=Sheep 1418 state=herd can_enter=false reason=not_herded herder=unknown
[2026-02-16T13:24:51] [DEBUG] [NPC] Priority eval: Sheep 1418 - herd (priority=11.0, can_enter=false) npc=Sheep 1418 state=herd priority=11.0 can_enter=false
[2026-02-16T13:24:51] [DEBUG] [NPC] Priority eval: Sheep 1418 - raid (priority=8.5, can_enter=false) npc=Sheep 1418 state=raid priority=8.5 can_enter=false
[2026-02-16T13:24:51] [DEBUG] [NPC] Priority eval: Sheep 1418 - reproduction (priority=8.0, can_enter=false) npc=Sheep 1418 state=reproduction priority=8.0 can_enter=false
[2026-02-16T13:24:51] [DEBUG] [NPC] Priority eval: Sheep 1418 - occupy_building (priority=7.5, can_enter=false) npc=Sheep 1418 state=occupy_building priority=7.5 can_enter=false
[2026-02-16T13:24:51] [DEBUG] [NPC] Priority eval: Sheep 1418 - work_at_building (priority=7.0, can_enter=false) npc=Sheep 1418 state=work_at_building priority=7.0 can_enter=false
[2026-02-16T13:24:51] [DEBUG] [NPC] Can enter check: Sheep 1418 cannot enter seek (no_target) npc=Sheep 1418 state=seek can_enter=false reason=no_target
TASK SYSTEM LOGGER: Called at time 33.9
[2026-02-16T13:24:51] [INFO] [INVENTORY] === TASK SYSTEM LOG: 1 Land Claims ===
[2026-02-16T13:24:51] [INFO] [INVENTORY] LAND CLAIM: OKOK | Pos: (-1050, 689) | Inventory: empty clan_name=OKOK position=(-1049.549, 688.502) inventory=[]
[2026-02-16T13:24:51] [INFO] [INVENTORY] TASK SYSTEM DEBUG: buildings group=5, with building_type=4, ovens=0
[2026-02-16T13:24:51] [INFO] [INVENTORY] === TASK SYSTEM LOG: 0 Ovens ===
[2026-02-16T13:24:52] [INFO] [NPC] POSITION: BAHI at (361.6, -295.4), state=wander, distance_to_claim=0.0/400.0, velocity=52.8 npc=BAHI pos=361.6,-295.4 state=wander distance_to_claim=0.0 claim_radius=400.0 velocity=52.8
[2026-02-16T13:24:52] [DEBUG] [NPC] Can enter check: BAHI cannot enter agro (not_caveman) npc=BAHI state=agro can_enter=false reason=not_caveman npc_type=woman
[2026-02-16T13:24:52] [DEBUG] [NPC] Priority eval: BAHI - agro (priority=15.0, can_enter=false) npc=BAHI state=agro priority=15.0 can_enter=false
[2026-02-16T13:24:52] [DEBUG] [NPC] Priority eval: BAHI - combat (priority=12.0, can_enter=false) npc=BAHI state=combat priority=12.0 can_enter=false
[2026-02-16T13:24:52] [DEBUG] [NPC] Can enter check: BAHI cannot enter herd (not_herded) npc=BAHI state=herd can_enter=false reason=not_herded herder=unknown
[2026-02-16T13:24:52] [DEBUG] [NPC] Priority eval: BAHI - herd (priority=11.0, can_enter=false) npc=BAHI state=herd priority=11.0 can_enter=false
[2026-02-16T13:24:52] [DEBUG] [NPC] Priority eval: BAHI - raid (priority=8.5, can_enter=false) npc=BAHI state=raid priority=8.5 can_enter=false
[2026-02-16T13:24:52] [DEBUG] [NPC] Priority eval: BAHI - reproduction (priority=8.0, can_enter=false) npc=BAHI state=reproduction priority=8.0 can_enter=false
[2026-02-16T13:24:52] [DEBUG] [NPC] Priority eval: BAHI - occupy_building (priority=7.5, can_enter=false) npc=BAHI state=occupy_building priority=7.5 can_enter=false
[2026-02-16T13:24:52] [DEBUG] [NPC] Priority eval: BAHI - work_at_building (priority=7.0, can_enter=false) npc=BAHI state=work_at_building priority=7.0 can_enter=false
[2026-02-16T13:24:53] [DEBUG] [NPC] Can enter check: KUKO cannot enter agro (not_caveman) npc=KUKO state=agro can_enter=false reason=not_caveman npc_type=woman
[2026-02-16T13:24:53] [DEBUG] [NPC] Priority eval: KUKO - agro (priority=15.0, can_enter=false) npc=KUKO state=agro priority=15.0 can_enter=false
[2026-02-16T13:24:53] [DEBUG] [NPC] Priority eval: KUKO - combat (priority=12.0, can_enter=false) npc=KUKO state=combat priority=12.0 can_enter=false
[2026-02-16T13:24:53] [DEBUG] [NPC] Can enter check: KUKO cannot enter herd (not_herded) npc=KUKO state=herd can_enter=false reason=not_herded herder=unknown
[2026-02-16T13:24:53] [DEBUG] [NPC] Priority eval: KUKO - herd (priority=11.0, can_enter=false) npc=KUKO state=herd priority=11.0 can_enter=false
[2026-02-16T13:24:53] [DEBUG] [NPC] Priority eval: KUKO - raid (priority=8.5, can_enter=false) npc=KUKO state=raid priority=8.5 can_enter=false
[2026-02-16T13:24:53] [DEBUG] [NPC] Priority eval: KUKO - reproduction (priority=8.0, can_enter=false) npc=KUKO state=reproduction priority=8.0 can_enter=false
[2026-02-16T13:24:53] [DEBUG] [NPC] Priority eval: KUKO - occupy_building (priority=7.5, can_enter=false) npc=KUKO state=occupy_building priority=7.5 can_enter=false
[2026-02-16T13:24:53] [DEBUG] [NPC] Priority eval: KUKO - work_at_building (priority=7.0, can_enter=false) npc=KUKO state=work_at_building priority=7.0 can_enter=false
[2026-02-16T13:24:53] [DEBUG] [NPC] Can enter check: KUKO cannot enter seek (no_target) npc=KUKO state=seek can_enter=false reason=no_target
[2026-02-16T13:24:54] [INFO] [NPC] POSITION: Sheep 1217 at (-316.4, -736.5), state=wander, distance_to_claim=0.0/400.0, velocity=41.0 npc=Sheep 1217 pos=-316.4,-736.5 state=wander distance_to_claim=0.0 claim_radius=400.0 velocity=41.0
[2026-02-16T13:24:54] [DEBUG] [NPC] Steering behavior: WANDER - center npc=Sheep 1217 behavior=WANDER target=center position=-441.8,-678.6 radius=300.0
[2026-02-16T13:24:54] [DEBUG] [NPC] Can enter check: Sheep 1217 cannot enter agro (not_caveman) npc=Sheep 1217 state=agro can_enter=false reason=not_caveman npc_type=sheep
[2026-02-16T13:24:54] [DEBUG] [NPC] Priority eval: Sheep 1217 - agro (priority=15.0, can_enter=false) npc=Sheep 1217 state=agro priority=15.0 can_enter=false
[2026-02-16T13:24:54] [DEBUG] [NPC] Priority eval: Sheep 1217 - combat (priority=12.0, can_enter=false) npc=Sheep 1217 state=combat priority=12.0 can_enter=false
[2026-02-16T13:24:54] [DEBUG] [NPC] Can enter check: Sheep 1217 cannot enter herd (not_herded) npc=Sheep 1217 state=herd can_enter=false reason=not_herded herder=unknown
[2026-02-16T13:24:54] [DEBUG] [NPC] Priority eval: Sheep 1217 - herd (priority=11.0, can_enter=false) npc=Sheep 1217 state=herd priority=11.0 can_enter=false
[2026-02-16T13:24:54] [DEBUG] [NPC] Priority eval: Sheep 1217 - raid (priority=8.5, can_enter=false) npc=Sheep 1217 state=raid priority=8.5 can_enter=false
[2026-02-16T13:24:54] [DEBUG] [NPC] Priority eval: Sheep 1217 - reproduction (priority=8.0, can_enter=false) npc=Sheep 1217 state=reproduction priority=8.0 can_enter=false
[2026-02-16T13:24:54] [DEBUG] [NPC] Priority eval: Sheep 1217 - occupy_building (priority=7.5, can_enter=false) npc=Sheep 1217 state=occupy_building priority=7.5 can_enter=false
TASK SYSTEM LOGGER: Called at time 37.0
[2026-02-16T13:24:54] [INFO] [INVENTORY] === TASK SYSTEM LOG: 1 Land Claims ===
[2026-02-16T13:24:54] [INFO] [INVENTORY] LAND CLAIM: OKOK | Pos: (-1050, 689) | Inventory: empty clan_name=OKOK position=(-1049.549, 688.502) inventory=[]
[2026-02-16T13:24:54] [INFO] [INVENTORY] TASK SYSTEM DEBUG: buildings group=5, with building_type=4, ovens=0
[2026-02-16T13:24:54] [INFO] [INVENTORY] === TASK SYSTEM LOG: 0 Ovens ===
[2026-02-16T13:24:55] [DEBUG] [NPC] Can enter check: BAHI cannot enter agro (not_caveman) npc=BAHI state=agro can_enter=false reason=not_caveman npc_type=woman
[2026-02-16T13:24:55] [DEBUG] [NPC] Priority eval: BAHI - agro (priority=15.0, can_enter=false) npc=BAHI state=agro priority=15.0 can_enter=false
[2026-02-16T13:24:55] [DEBUG] [NPC] Priority eval: BAHI - combat (priority=12.0, can_enter=false) npc=BAHI state=combat priority=12.0 can_enter=false
[2026-02-16T13:24:55] [DEBUG] [NPC] Can enter check: BAHI cannot enter herd (not_herded) npc=BAHI state=herd can_enter=false reason=not_herded herder=unknown
[2026-02-16T13:24:55] [DEBUG] [NPC] Priority eval: BAHI - herd (priority=11.0, can_enter=false) npc=BAHI state=herd priority=11.0 can_enter=false
[2026-02-16T13:24:55] [DEBUG] [NPC] Priority eval: BAHI - raid (priority=8.5, can_enter=false) npc=BAHI state=raid priority=8.5 can_enter=false
[2026-02-16T13:24:55] [DEBUG] [NPC] Priority eval: BAHI - reproduction (priority=8.0, can_enter=false) npc=BAHI state=reproduction priority=8.0 can_enter=false
[2026-02-16T13:24:55] [DEBUG] [NPC] Priority eval: BAHI - occupy_building (priority=7.5, can_enter=false) npc=BAHI state=occupy_building priority=7.5 can_enter=false
[2026-02-16T13:24:55] [DEBUG] [NPC] Priority eval: BAHI - work_at_building (priority=7.0, can_enter=false) npc=BAHI state=work_at_building priority=7.0 can_enter=false
[2026-02-16T13:24:55] [DEBUG] [NPC] Can enter check: BAHI cannot enter seek (no_target) npc=BAHI state=seek can_enter=false reason=no_target
[2026-02-16T13:24:56] [DEBUG] [NPC] Can enter check: JOEC cannot enter agro (not_caveman) npc=JOEC state=agro can_enter=false reason=not_caveman npc_type=woman
[2026-02-16T13:24:56] [DEBUG] [NPC] Priority eval: JOEC - agro (priority=15.0, can_enter=false) npc=JOEC state=agro priority=15.0 can_enter=false
[2026-02-16T13:24:56] [DEBUG] [NPC] Priority eval: JOEC - combat (priority=12.0, can_enter=false) npc=JOEC state=combat priority=12.0 can_enter=false
[2026-02-16T13:24:56] [DEBUG] [NPC] Can enter check: JOEC cannot enter herd (not_herded) npc=JOEC state=herd can_enter=false reason=not_herded herder=unknown
[2026-02-16T13:24:56] [DEBUG] [NPC] Priority eval: JOEC - herd (priority=11.0, can_enter=false) npc=JOEC state=herd priority=11.0 can_enter=false
[2026-02-16T13:24:56] [DEBUG] [NPC] Priority eval: JOEC - raid (priority=8.5, can_enter=false) npc=JOEC state=raid priority=8.5 can_enter=false
[2026-02-16T13:24:56] [DEBUG] [NPC] Priority eval: JOEC - reproduction (priority=8.0, can_enter=false) npc=JOEC state=reproduction priority=8.0 can_enter=false
[2026-02-16T13:24:56] [DEBUG] [NPC] Priority eval: JOEC - occupy_building (priority=7.5, can_enter=false) npc=JOEC state=occupy_building priority=7.5 can_enter=false
[2026-02-16T13:24:56] [DEBUG] [NPC] Priority eval: JOEC - work_at_building (priority=7.0, can_enter=false) npc=JOEC state=work_at_building priority=7.0 can_enter=false
[2026-02-16T13:24:56] [DEBUG] [NPC] Can enter check: JOEC cannot enter seek (no_target) npc=JOEC state=seek can_enter=false reason=no_target
TASK SYSTEM LOGGER: Called at time 40.0
[2026-02-16T13:24:57] [INFO] [NPC] ═══════════════════════════════════════════════════════
[2026-02-16T13:24:57] [INFO] [NPC] === TASK SYSTEM LOG: 9 Women ===
[2026-02-16T13:24:57] [INFO] [NPC] WOMAN: WUYA | State: wander | Clan:  | Pos: (84, 436) | Inventory: Berries x0 npc_name=WUYA state=wander clan= position=(83.84829, 436.2249) inventory=["Berries x0"]
[2026-02-16T13:24:57] [INFO] [NPC] WOMAN: PUIK | State: idle | Clan:  | Pos: (703, 260) | Inventory: Berries x0 npc_name=PUIK state=idle clan= position=(703.4576, 259.6548) inventory=["Berries x0"]
[2026-02-16T13:24:57] [INFO] [NPC] WOMAN: GEEZ | State: idle | Clan:  | Pos: (300, 601) | Inventory: Berries x0 npc_name=GEEZ state=idle clan= position=(299.9385, 600.8686) inventory=["Berries x0"]
[2026-02-16T13:24:57] [INFO] [NPC] WOMAN: KUKO | State: idle | Clan:  | Pos: (453, 545) | Inventory: Berries x0 npc_name=KUKO state=idle clan= position=(452.7769, 544.8745) inventory=["Berries x0"]
[2026-02-16T13:24:57] [INFO] [NPC] WOMAN: XIUF | State: wander | Clan:  | Pos: (12, 469) | Inventory: Berries x0 npc_name=XIUF state=wander clan= position=(11.97396, 468.8672) inventory=["Berries x0"]
[2026-02-16T13:24:57] [INFO] [NPC] WOMAN: DEIS | State: idle | Clan:  | Pos: (13, -99) | Inventory: Berries x0 npc_name=DEIS state=idle clan= position=(13.37521, -99.00105) inventory=["Berries x0"]
[2026-02-16T13:24:57] [INFO] [NPC] WOMAN: WUEC | State: idle | Clan:  | Pos: (-15, 285) | Inventory: Berries x0 npc_name=WUEC state=idle clan= position=(-14.92741, 284.7758) inventory=["Berries x0"]
[2026-02-16T13:24:57] [INFO] [NPC] WOMAN: BAHI | State: wander | Clan:  | Pos: (507, -277) | Inventory: Berries x0 npc_name=BAHI state=wander clan= position=(506.946, -277.1731) inventory=["Berries x0"]
[2026-02-16T13:24:57] [INFO] [INVENTORY] === TASK SYSTEM LOG: 1 Land Claims ===
[2026-02-16T13:24:57] [INFO] [INVENTORY] LAND CLAIM: OKOK | Pos: (-1050, 689) | Inventory: empty clan_name=OKOK position=(-1049.549, 688.502) inventory=[]
[2026-02-16T13:24:57] [INFO] [INVENTORY] TASK SYSTEM DEBUG: buildings group=5, with building_type=4, ovens=0
[2026-02-16T13:24:57] [INFO] [INVENTORY] === TASK SYSTEM LOG: 0 Ovens ===
[2026-02-16T13:24:58] [DEBUG] [NPC] Can enter check: Sheep 1418 cannot enter agro (not_caveman) npc=Sheep 1418 state=agro can_enter=false reason=not_caveman npc_type=sheep
[2026-02-16T13:24:58] [DEBUG] [NPC] Priority eval: Sheep 1418 - agro (priority=15.0, can_enter=false) npc=Sheep 1418 state=agro priority=15.0 can_enter=false
[2026-02-16T13:24:58] [DEBUG] [NPC] Priority eval: Sheep 1418 - combat (priority=12.0, can_enter=false) npc=Sheep 1418 state=combat priority=12.0 can_enter=false
[2026-02-16T13:24:58] [DEBUG] [NPC] Can enter check: Sheep 1418 cannot enter herd (not_herded) npc=Sheep 1418 state=herd can_enter=false reason=not_herded herder=unknown
[2026-02-16T13:24:58] [DEBUG] [NPC] Priority eval: Sheep 1418 - herd (priority=11.0, can_enter=false) npc=Sheep 1418 state=herd priority=11.0 can_enter=false
[2026-02-16T13:24:58] [DEBUG] [NPC] Priority eval: Sheep 1418 - raid (priority=8.5, can_enter=false) npc=Sheep 1418 state=raid priority=8.5 can_enter=false
[2026-02-16T13:24:58] [DEBUG] [NPC] Priority eval: Sheep 1418 - reproduction (priority=8.0, can_enter=false) npc=Sheep 1418 state=reproduction priority=8.0 can_enter=false
[2026-02-16T13:24:58] [DEBUG] [NPC] Priority eval: Sheep 1418 - occupy_building (priority=7.5, can_enter=false) npc=Sheep 1418 state=occupy_building priority=7.5 can_enter=false
[2026-02-16T13:24:58] [DEBUG] [NPC] Priority eval: Sheep 1418 - work_at_building (priority=7.0, can_enter=false) npc=Sheep 1418 state=work_at_building priority=7.0 can_enter=false
[2026-02-16T13:24:58] [DEBUG] [NPC] Can enter check: Sheep 1418 cannot enter seek (no_target) npc=Sheep 1418 state=seek can_enter=false reason=no_target
NPC Goat 1218 joined clan OKOK (entered herder's land claim)
🏠 Goat 1218: Herd cleared (no longer following)
[Assign] Goat 1218 entry clan=OKOK assigned=false
[ASSIGN] Goat 1218 ClaimBuildingIndex returned 4 buildings for claim OKOK
[Assign] Goat 1218 assign_success -> @Node2D@617 dist=198
[Assign] Goat 1218 add_animal_attempt -> @Node2D@617 dist=198 (enter_range=220)
[MONITOR] Animal Goat 1218 entered Dairy Farm
[2026-02-16T13:24:59] [DEBUG] [NPC] Can enter check: XIUF cannot enter agro (not_caveman) npc=XIUF state=agro can_enter=false reason=not_caveman npc_type=woman
[2026-02-16T13:24:59] [DEBUG] [NPC] Priority eval: XIUF - agro (priority=15.0, can_enter=false) npc=XIUF state=agro priority=15.0 can_enter=false
[2026-02-16T13:24:59] [DEBUG] [NPC] Priority eval: XIUF - combat (priority=12.0, can_enter=false) npc=XIUF state=combat priority=12.0 can_enter=false
[2026-02-16T13:24:59] [DEBUG] [NPC] Can enter check: XIUF cannot enter herd (not_herded) npc=XIUF state=herd can_enter=false reason=not_herded herder=unknown
[2026-02-16T13:24:59] [DEBUG] [NPC] Priority eval: XIUF - herd (priority=11.0, can_enter=false) npc=XIUF state=herd priority=11.0 can_enter=false
[2026-02-16T13:24:59] [DEBUG] [NPC] Priority eval: XIUF - raid (priority=8.5, can_enter=false) npc=XIUF state=raid priority=8.5 can_enter=false
[2026-02-16T13:24:59] [DEBUG] [NPC] Priority eval: XIUF - reproduction (priority=8.0, can_enter=false) npc=XIUF state=reproduction priority=8.0 can_enter=false
[2026-02-16T13:24:59] [DEBUG] [NPC] Priority eval: XIUF - occupy_building (priority=7.5, can_enter=false) npc=XIUF state=occupy_building priority=7.5 can_enter=false
[2026-02-16T13:24:59] [DEBUG] [NPC] Priority eval: XIUF - work_at_building (priority=7.0, can_enter=false) npc=XIUF state=work_at_building priority=7.0 can_enter=false
[2026-02-16T13:24:59] [DEBUG] [NPC] Can enter check: XIUF cannot enter seek (no_target) npc=XIUF state=seek can_enter=false reason=no_target
[Assign] Goat 1218 assign_success -> @Node2D@617 dist=180
[Assign] Goat 1218 assign_success -> @Node2D@617 dist=180
TASK SYSTEM LOGGER: Called at time 43.0
[2026-02-16T13:25:00] [INFO] [NPC] ═══════════════════════════════════════════════════════
[2026-02-16T13:25:00] [INFO] [NPC] === TASK SYSTEM LOG: 9 Women ===
[2026-02-16T13:25:00] [INFO] [NPC] WOMAN: WUYA | State: idle | Clan:  | Pos: (137, 484) | Inventory: Berries x0 npc_name=WUYA state=idle clan= position=(137.1498, 483.9365) inventory=["Berries x0"]
[2026-02-16T13:25:00] [INFO] [NPC] WOMAN: PUIK | State: wander | Clan:  | Pos: (716, 274) | Inventory: Berries x0 npc_name=PUIK state=wander clan= position=(715.7746, 274.0418) inventory=["Berries x0"]
[2026-02-16T13:25:00] [INFO] [NPC] WOMAN: GEEZ | State: idle | Clan:  | Pos: (251, 621) | Inventory: Berries x0 npc_name=GEEZ state=idle clan= position=(250.9496, 621.0736) inventory=["Berries x0"]
[2026-02-16T13:25:00] [INFO] [NPC] WOMAN: KUKO | State: wander | Clan:  | Pos: (515, 509) | Inventory: Berries x0 npc_name=KUKO state=wander clan= position=(514.67, 509.1712) inventory=["Berries x0"]
[2026-02-16T13:25:00] [INFO] [NPC] WOMAN: XIUF | State: idle | Clan:  | Pos: (-81, 360) | Inventory: Berries x0 npc_name=XIUF state=idle clan= position=(-80.74237, 360.3645) inventory=["Berries x0"]
[2026-02-16T13:25:00] [INFO] [NPC] WOMAN: DEIS | State: idle | Clan:  | Pos: (2, -104) | Inventory: Berries x0 npc_name=DEIS state=idle clan= position=(1.634118, -104.1381) inventory=["Berries x0"]
[2026-02-16T13:25:00] [INFO] [NPC] WOMAN: WUEC | State: wander | Clan:  | Pos: (-27, 223) | Inventory: Berries x0 npc_name=WUEC state=wander clan= position=(-27.49484, 222.5527) inventory=["Berries x0"]
[2026-02-16T13:25:00] [INFO] [NPC] WOMAN: BAHI | State: idle | Clan:  | Pos: (425, -276) | Inventory: Berries x0 npc_name=BAHI state=idle clan= position=(425.4083, -276.4825) inventory=["Berries x0"]
[2026-02-16T13:25:00] [INFO] [INVENTORY] === TASK SYSTEM LOG: 1 Land Claims ===
[2026-02-16T13:25:00] [INFO] [INVENTORY] LAND CLAIM: OKOK | Pos: (-1050, 689) | Inventory: empty clan_name=OKOK position=(-1049.549, 688.502) inventory=[]
[2026-02-16T13:25:00] [INFO] [INVENTORY] TASK SYSTEM DEBUG: buildings group=5, with building_type=4, ovens=0
[2026-02-16T13:25:00] [INFO] [INVENTORY] === TASK SYSTEM LOG: 0 Ovens ===
[Assign] Goat 1218 assign_success -> @Node2D@617 dist=180
[2026-02-16T13:25:01] [INFO] [NPC] POSITION: Sheep 1217 at (-390.3, -715.1), state=wander, distance_to_claim=0.0/400.0, velocity=28.5 npc=Sheep 1217 pos=-390.3,-715.1 state=wander distance_to_claim=0.0 claim_radius=400.0 velocity=28.5
[2026-02-16T13:25:01] [DEBUG] [NPC] Can enter check: Sheep 1217 cannot enter agro (not_caveman) npc=Sheep 1217 state=agro can_enter=false reason=not_caveman npc_type=sheep
[2026-02-16T13:25:01] [DEBUG] [NPC] Priority eval: Sheep 1217 - agro (priority=15.0, can_enter=false) npc=Sheep 1217 state=agro priority=15.0 can_enter=false
[2026-02-16T13:25:01] [DEBUG] [NPC] Priority eval: Sheep 1217 - combat (priority=12.0, can_enter=false) npc=Sheep 1217 state=combat priority=12.0 can_enter=false
[2026-02-16T13:25:01] [DEBUG] [NPC] Can enter check: Sheep 1217 cannot enter herd (not_herded) npc=Sheep 1217 state=herd can_enter=false reason=not_herded herder=unknown
[2026-02-16T13:25:01] [DEBUG] [NPC] Priority eval: Sheep 1217 - herd (priority=11.0, can_enter=false) npc=Sheep 1217 state=herd priority=11.0 can_enter=false
[2026-02-16T13:25:01] [DEBUG] [NPC] Priority eval: Sheep 1217 - raid (priority=8.5, can_enter=false) npc=Sheep 1217 state=raid priority=8.5 can_enter=false
[2026-02-16T13:25:01] [DEBUG] [NPC] Priority eval: Sheep 1217 - reproduction (priority=8.0, can_enter=false) npc=Sheep 1217 state=reproduction priority=8.0 can_enter=false
[2026-02-16T13:25:01] [DEBUG] [NPC] Priority eval: Sheep 1217 - occupy_building (priority=7.5, can_enter=false) npc=Sheep 1217 state=occupy_building priority=7.5 can_enter=false
[2026-02-16T13:25:01] [DEBUG] [NPC] Priority eval: Sheep 1217 - work_at_building (priority=7.0, can_enter=false) npc=Sheep 1217 state=work_at_building priority=7.0 can_enter=false
[Assign] Goat 1218 add_animal_attempt -> @Node2D@617 dist=180 (enter_range=220)
[Assign] Goat 1218 assign_success -> @Node2D@617 dist=180
[2026-02-16T13:25:02] [DEBUG] [NPC] Can enter check: XIUF cannot enter agro (not_caveman) npc=XIUF state=agro can_enter=false reason=not_caveman npc_type=woman
[2026-02-16T13:25:02] [DEBUG] [NPC] Priority eval: XIUF - agro (priority=15.0, can_enter=false) npc=XIUF state=agro priority=15.0 can_enter=false
[2026-02-16T13:25:02] [DEBUG] [NPC] Priority eval: XIUF - combat (priority=12.0, can_enter=false) npc=XIUF state=combat priority=12.0 can_enter=false
[2026-02-16T13:25:02] [DEBUG] [NPC] Can enter check: XIUF cannot enter herd (not_herded) npc=XIUF state=herd can_enter=false reason=not_herded herder=unknown
[2026-02-16T13:25:02] [DEBUG] [NPC] Priority eval: XIUF - herd (priority=11.0, can_enter=false) npc=XIUF state=herd priority=11.0 can_enter=false
[2026-02-16T13:25:02] [DEBUG] [NPC] Priority eval: XIUF - raid (priority=8.5, can_enter=false) npc=XIUF state=raid priority=8.5 can_enter=false
[2026-02-16T13:25:02] [DEBUG] [NPC] Priority eval: XIUF - reproduction (priority=8.0, can_enter=false) npc=XIUF state=reproduction priority=8.0 can_enter=false
[2026-02-16T13:25:02] [DEBUG] [NPC] Priority eval: XIUF - occupy_building (priority=7.5, can_enter=false) npc=XIUF state=occupy_building priority=7.5 can_enter=false
[2026-02-16T13:25:02] [DEBUG] [NPC] Priority eval: XIUF - work_at_building (priority=7.0, can_enter=false) npc=XIUF state=work_at_building priority=7.0 can_enter=false
[2026-02-16T13:25:02] [DEBUG] [NPC] Can enter check: XIUF cannot enter seek (no_target) npc=XIUF state=seek can_enter=false reason=no_target
[Assign] Goat 1218 assign_success -> @Node2D@617 dist=180
TASK SYSTEM LOGGER: Called at time 46.0
[2026-02-16T13:25:03] [INFO] [INVENTORY] === TASK SYSTEM LOG: 1 Land Claims ===
[2026-02-16T13:25:03] [INFO] [INVENTORY] LAND CLAIM: OKOK | Pos: (-1050, 689) | Inventory: empty clan_name=OKOK position=(-1049.549, 688.502) inventory=[]
[2026-02-16T13:25:03] [INFO] [INVENTORY] TASK SYSTEM DEBUG: buildings group=5, with building_type=4, ovens=0
[2026-02-16T13:25:03] [INFO] [INVENTORY] === TASK SYSTEM LOG: 0 Ovens ===
[2026-02-16T13:25:03] [DEBUG] [NPC] Can enter check: Goat 1419 cannot enter agro (not_caveman) npc=Goat 1419 state=agro can_enter=false reason=not_caveman npc_type=goat
[2026-02-16T13:25:03] [DEBUG] [NPC] Priority eval: Goat 1419 - agro (priority=15.0, can_enter=false) npc=Goat 1419 state=agro priority=15.0 can_enter=false
[2026-02-16T13:25:03] [DEBUG] [NPC] Priority eval: Goat 1419 - combat (priority=12.0, can_enter=false) npc=Goat 1419 state=combat priority=12.0 can_enter=false
[2026-02-16T13:25:03] [DEBUG] [NPC] Can enter check: Goat 1419 cannot enter herd (not_herded) npc=Goat 1419 state=herd can_enter=false reason=not_herded herder=unknown
[2026-02-16T13:25:03] [DEBUG] [NPC] Priority eval: Goat 1419 - herd (priority=11.0, can_enter=false) npc=Goat 1419 state=herd priority=11.0 can_enter=false
[2026-02-16T13:25:03] [DEBUG] [NPC] Priority eval: Goat 1419 - raid (priority=8.5, can_enter=false) npc=Goat 1419 state=raid priority=8.5 can_enter=false
[2026-02-16T13:25:03] [DEBUG] [NPC] Priority eval: Goat 1419 - reproduction (priority=8.0, can_enter=false) npc=Goat 1419 state=reproduction priority=8.0 can_enter=false
[2026-02-16T13:25:03] [DEBUG] [NPC] Priority eval: Goat 1419 - occupy_building (priority=7.5, can_enter=false) npc=Goat 1419 state=occupy_building priority=7.5 can_enter=false
[2026-02-16T13:25:03] [DEBUG] [NPC] Priority eval: Goat 1419 - work_at_building (priority=7.0, can_enter=false) npc=Goat 1419 state=work_at_building priority=7.0 can_enter=false
[2026-02-16T13:25:03] [DEBUG] [NPC] Can enter check: Goat 1419 cannot enter seek (no_target) npc=Goat 1419 state=seek can_enter=false reason=no_target
[Assign] Goat 1218 assign_success -> @Node2D@617 dist=180
[Assign] Goat 1218 add_animal_attempt -> @Node2D@617 dist=180 (enter_range=220)
[2026-02-16T13:25:04] [DEBUG] [NPC] Can enter check: Sheep 1217 cannot enter agro (not_caveman) npc=Sheep 1217 state=agro can_enter=false reason=not_caveman npc_type=sheep
[2026-02-16T13:25:04] [DEBUG] [NPC] Priority eval: Sheep 1217 - agro (priority=15.0, can_enter=false) npc=Sheep 1217 state=agro priority=15.0 can_enter=false
[2026-02-16T13:25:04] [DEBUG] [NPC] Priority eval: Sheep 1217 - combat (priority=12.0, can_enter=false) npc=Sheep 1217 state=combat priority=12.0 can_enter=false
[2026-02-16T13:25:04] [DEBUG] [NPC] Can enter check: Sheep 1217 cannot enter herd (not_herded) npc=Sheep 1217 state=herd can_enter=false reason=not_herded herder=unknown
[2026-02-16T13:25:04] [DEBUG] [NPC] Priority eval: Sheep 1217 - herd (priority=11.0, can_enter=false) npc=Sheep 1217 state=herd priority=11.0 can_enter=false
[2026-02-16T13:25:04] [DEBUG] [NPC] Priority eval: Sheep 1217 - raid (priority=8.5, can_enter=false) npc=Sheep 1217 state=raid priority=8.5 can_enter=false
[2026-02-16T13:25:04] [DEBUG] [NPC] Priority eval: Sheep 1217 - reproduction (priority=8.0, can_enter=false) npc=Sheep 1217 state=reproduction priority=8.0 can_enter=false
[2026-02-16T13:25:04] [DEBUG] [NPC] Priority eval: Sheep 1217 - occupy_building (priority=7.5, can_enter=false) npc=Sheep 1217 state=occupy_building priority=7.5 can_enter=false
[2026-02-16T13:25:04] [DEBUG] [NPC] Priority eval: Sheep 1217 - work_at_building (priority=7.0, can_enter=false) npc=Sheep 1217 state=work_at_building priority=7.0 can_enter=false
[2026-02-16T13:25:04] [DEBUG] [NPC] Can enter check: Sheep 1217 cannot enter seek (no_target) npc=Sheep 1217 state=seek can_enter=false reason=no_target
[Assign] Goat 1218 entry clan=OKOK assigned=false
[ASSIGN] Goat 1218 ClaimBuildingIndex returned 4 buildings for claim OKOK
[Assign] Goat 1218 assign_success -> @Node2D@617 dist=175
[Assign] Goat 1218 assign_success -> @Node2D@617 dist=147
[2026-02-16T13:25:05] [DEBUG] [NPC] Can enter check: KUKO cannot enter agro (not_caveman) npc=KUKO state=agro can_enter=false reason=not_caveman npc_type=woman
[2026-02-16T13:25:05] [DEBUG] [NPC] Priority eval: KUKO - agro (priority=15.0, can_enter=false) npc=KUKO state=agro priority=15.0 can_enter=false
[2026-02-16T13:25:05] [DEBUG] [NPC] Priority eval: KUKO - combat (priority=12.0, can_enter=false) npc=KUKO state=combat priority=12.0 can_enter=false
[2026-02-16T13:25:05] [DEBUG] [NPC] Can enter check: KUKO cannot enter herd (not_herded) npc=KUKO state=herd can_enter=false reason=not_herded herder=unknown
[2026-02-16T13:25:05] [DEBUG] [NPC] Priority eval: KUKO - herd (priority=11.0, can_enter=false) npc=KUKO state=herd priority=11.0 can_enter=false
[2026-02-16T13:25:05] [DEBUG] [NPC] Priority eval: KUKO - raid (priority=8.5, can_enter=false) npc=KUKO state=raid priority=8.5 can_enter=false
[2026-02-16T13:25:05] [DEBUG] [NPC] Priority eval: KUKO - reproduction (priority=8.0, can_enter=false) npc=KUKO state=reproduction priority=8.0 can_enter=false
[2026-02-16T13:25:05] [DEBUG] [NPC] Priority eval: KUKO - occupy_building (priority=7.5, can_enter=false) npc=KUKO state=occupy_building priority=7.5 can_enter=false
[2026-02-16T13:25:05] [DEBUG] [NPC] Priority eval: KUKO - work_at_building (priority=7.0, can_enter=false) npc=KUKO state=work_at_building priority=7.0 can_enter=false
[2026-02-16T13:25:05] [DEBUG] [NPC] Can enter check: KUKO cannot enter seek (no_target) npc=KUKO state=seek can_enter=false reason=no_target
[Assign] Goat 1218 assign_success -> @Node2D@617 dist=122
TASK SYSTEM LOGGER: Called at time 49.0
[2026-02-16T13:25:06] [INFO] [INVENTORY] === TASK SYSTEM LOG: 1 Land Claims ===
[2026-02-16T13:25:06] [INFO] [INVENTORY] LAND CLAIM: OKOK | Pos: (-1050, 689) | Inventory: empty clan_name=OKOK position=(-1049.549, 688.502) inventory=[]
[2026-02-16T13:25:06] [INFO] [INVENTORY] TASK SYSTEM DEBUG: buildings group=5, with building_type=4, ovens=0
[2026-02-16T13:25:06] [INFO] [INVENTORY] === TASK SYSTEM LOG: 0 Ovens ===
[2026-02-16T13:25:06] [INFO] [NPC] POSITION: JOEC at (-59.6, 1493.1), state=wander, distance_to_claim=0.0/400.0, velocity=10.0 npc=JOEC pos=-59.6,1493.1 state=wander distance_to_claim=0.0 claim_radius=400.0 velocity=10.0
[2026-02-16T13:25:06] [DEBUG] [NPC] Can enter check: JOEC can enter idle (always_available) npc=JOEC state=idle can_enter=true reason=always_available
[2026-02-16T13:25:06] [DEBUG] [NPC] Can enter check: JOEC can enter wander (no_higher_priority_needs) npc=JOEC state=wander can_enter=true reason=no_higher_priority_needs
[2026-02-16T13:25:06] [DEBUG] [NPC] Can enter check: JOEC cannot enter seek (no_target) npc=JOEC state=seek can_enter=false reason=no_target
[2026-02-16T13:25:06] [DEBUG] [NPC] Can enter check: JOEC cannot enter herd (not_herded) npc=JOEC state=herd can_enter=false reason=not_herded herder=unknown
[2026-02-16T13:25:06] [DEBUG] [NPC] Can enter check: JOEC cannot enter agro (not_caveman) npc=JOEC state=agro can_enter=false reason=not_caveman npc_type=woman
[2026-02-16T13:25:06] [DEBUG] [NPC] Can enter check: JOEC cannot enter herd_wildnpc (not_caveman_or_clansman) npc=JOEC state=herd_wildnpc can_enter=false reason=not_caveman_or_clansman npc_type=woman
[2026-02-16T13:25:06] [INFO] [NPC] STATE_EXIT: JOEC exited wander after 4.1s npc=JOEC state=wander duration_s=4.1
[2026-02-16T13:25:06] [INFO] [NPC] State exited: JOEC left wander npc=JOEC state=wander
[2026-02-16T13:25:06] [INFO] [NPC] STATE_ENTRY: JOEC entered idle (from wander) npc=JOEC state=idle from_state=wander
[Assign] Goat 1218 add_animal_attempt -> @Node2D@617 dist=120 (enter_range=220)
[Assign] Goat 1218 assign_success -> @Node2D@617 dist=120
[2026-02-16T13:25:07] [DEBUG] [NPC] Can enter check: Sheep 1217 cannot enter agro (not_caveman) npc=Sheep 1217 state=agro can_enter=false reason=not_caveman npc_type=sheep
[2026-02-16T13:25:07] [DEBUG] [NPC] Priority eval: Sheep 1217 - agro (priority=15.0, can_enter=false) npc=Sheep 1217 state=agro priority=15.0 can_enter=false
[2026-02-16T13:25:07] [DEBUG] [NPC] Priority eval: Sheep 1217 - combat (priority=12.0, can_enter=false) npc=Sheep 1217 state=combat priority=12.0 can_enter=false
[2026-02-16T13:25:07] [DEBUG] [NPC] Can enter check: Sheep 1217 cannot enter herd (not_herded) npc=Sheep 1217 state=herd can_enter=false reason=not_herded herder=unknown
[2026-02-16T13:25:07] [DEBUG] [NPC] Priority eval: Sheep 1217 - herd (priority=11.0, can_enter=false) npc=Sheep 1217 state=herd priority=11.0 can_enter=false
[2026-02-16T13:25:07] [DEBUG] [NPC] Priority eval: Sheep 1217 - raid (priority=8.5, can_enter=false) npc=Sheep 1217 state=raid priority=8.5 can_enter=false
[2026-02-16T13:25:07] [DEBUG] [NPC] Priority eval: Sheep 1217 - reproduction (priority=8.0, can_enter=false) npc=Sheep 1217 state=reproduction priority=8.0 can_enter=false
[2026-02-16T13:25:07] [DEBUG] [NPC] Priority eval: Sheep 1217 - occupy_building (priority=7.5, can_enter=false) npc=Sheep 1217 state=occupy_building priority=7.5 can_enter=false
[2026-02-16T13:25:07] [DEBUG] [NPC] Priority eval: Sheep 1217 - work_at_building (priority=7.0, can_enter=false) npc=Sheep 1217 state=work_at_building priority=7.0 can_enter=false
[2026-02-16T13:25:07] [DEBUG] [NPC] Can enter check: Sheep 1217 cannot enter seek (no_target) npc=Sheep 1217 state=seek can_enter=false reason=no_target
[Assign] Goat 1218 assign_success -> @Node2D@617 dist=120
[2026-02-16T13:25:08] [DEBUG] [NPC] Can enter check: Sheep 1319 cannot enter agro (not_caveman) npc=Sheep 1319 state=agro can_enter=false reason=not_caveman npc_type=sheep
[2026-02-16T13:25:08] [DEBUG] [NPC] Priority eval: Sheep 1319 - agro (priority=15.0, can_enter=false) npc=Sheep 1319 state=agro priority=15.0 can_enter=false
[2026-02-16T13:25:08] [DEBUG] [NPC] Priority eval: Sheep 1319 - combat (priority=12.0, can_enter=false) npc=Sheep 1319 state=combat priority=12.0 can_enter=false
[2026-02-16T13:25:08] [DEBUG] [NPC] Can enter check: Sheep 1319 cannot enter herd (not_herded) npc=Sheep 1319 state=herd can_enter=false reason=not_herded herder=unknown
[2026-02-16T13:25:08] [DEBUG] [NPC] Priority eval: Sheep 1319 - herd (priority=11.0, can_enter=false) npc=Sheep 1319 state=herd priority=11.0 can_enter=false
[2026-02-16T13:25:08] [DEBUG] [NPC] Priority eval: Sheep 1319 - raid (priority=8.5, can_enter=false) npc=Sheep 1319 state=raid priority=8.5 can_enter=false
[2026-02-16T13:25:08] [DEBUG] [NPC] Priority eval: Sheep 1319 - reproduction (priority=8.0, can_enter=false) npc=Sheep 1319 state=reproduction priority=8.0 can_enter=false
[2026-02-16T13:25:08] [DEBUG] [NPC] Priority eval: Sheep 1319 - occupy_building (priority=7.5, can_enter=false) npc=Sheep 1319 state=occupy_building priority=7.5 can_enter=false
[2026-02-16T13:25:08] [DEBUG] [NPC] Priority eval: Sheep 1319 - work_at_building (priority=7.0, can_enter=false) npc=Sheep 1319 state=work_at_building priority=7.0 can_enter=false
[2026-02-16T13:25:08] [DEBUG] [NPC] Can enter check: Sheep 1319 cannot enter seek (no_target) npc=Sheep 1319 state=seek can_enter=false reason=no_target
[Assign] Goat 1218 assign_success -> @Node2D@617 dist=120
[Assign] Goat 1218 add_animal_attempt -> @Node2D@617 dist=118 (enter_range=220)
TASK SYSTEM LOGGER: Called at time 52.0
[2026-02-16T13:25:09] [INFO] [INVENTORY] === TASK SYSTEM LOG: 1 Land Claims ===
[2026-02-16T13:25:09] [INFO] [INVENTORY] LAND CLAIM: OKOK | Pos: (-1050, 689) | Inventory: empty clan_name=OKOK position=(-1049.549, 688.502) inventory=[]
[2026-02-16T13:25:09] [INFO] [INVENTORY] TASK SYSTEM DEBUG: buildings group=5, with building_type=4, ovens=0
[2026-02-16T13:25:09] [INFO] [INVENTORY] === TASK SYSTEM LOG: 0 Ovens ===
[Assign] Goat 1218 assign_success -> @Node2D@617 dist=116
[2026-02-16T13:25:09] [DEBUG] [NPC] Can enter check: WUEC cannot enter agro (not_caveman) npc=WUEC state=agro can_enter=false reason=not_caveman npc_type=woman
[2026-02-16T13:25:09] [DEBUG] [NPC] Priority eval: WUEC - agro (priority=15.0, can_enter=false) npc=WUEC state=agro priority=15.0 can_enter=false
[2026-02-16T13:25:09] [DEBUG] [NPC] Priority eval: WUEC - combat (priority=12.0, can_enter=false) npc=WUEC state=combat priority=12.0 can_enter=false
[2026-02-16T13:25:09] [DEBUG] [NPC] Can enter check: WUEC cannot enter herd (not_herded) npc=WUEC state=herd can_enter=false reason=not_herded herder=unknown
[2026-02-16T13:25:09] [DEBUG] [NPC] Priority eval: WUEC - herd (priority=11.0, can_enter=false) npc=WUEC state=herd priority=11.0 can_enter=false
[2026-02-16T13:25:09] [DEBUG] [NPC] Priority eval: WUEC - raid (priority=8.5, can_enter=false) npc=WUEC state=raid priority=8.5 can_enter=false
[2026-02-16T13:25:09] [DEBUG] [NPC] Priority eval: WUEC - reproduction (priority=8.0, can_enter=false) npc=WUEC state=reproduction priority=8.0 can_enter=false
[2026-02-16T13:25:09] [DEBUG] [NPC] Priority eval: WUEC - occupy_building (priority=7.5, can_enter=false) npc=WUEC state=occupy_building priority=7.5 can_enter=false
[2026-02-16T13:25:09] [DEBUG] [NPC] Priority eval: WUEC - work_at_building (priority=7.0, can_enter=false) npc=WUEC state=work_at_building priority=7.0 can_enter=false
[2026-02-16T13:25:09] [DEBUG] [NPC] Can enter check: WUEC cannot enter seek (no_target) npc=WUEC state=seek can_enter=false reason=no_target
[Assign] Goat 1218 entry clan=OKOK assigned=true
[ASSIGN] Goat 1218 ClaimBuildingIndex returned 4 buildings for claim OKOK
[Assign] Goat 1218 assign_success -> @Node2D@617 dist=89
[2026-02-16T13:25:10] [DEBUG] [NPC] Can enter check: Sheep 1217 cannot enter agro (not_caveman) npc=Sheep 1217 state=agro can_enter=false reason=not_caveman npc_type=sheep
[2026-02-16T13:25:10] [DEBUG] [NPC] Priority eval: Sheep 1217 - agro (priority=15.0, can_enter=false) npc=Sheep 1217 state=agro priority=15.0 can_enter=false
[2026-02-16T13:25:10] [DEBUG] [NPC] Priority eval: Sheep 1217 - combat (priority=12.0, can_enter=false) npc=Sheep 1217 state=combat priority=12.0 can_enter=false
[2026-02-16T13:25:10] [DEBUG] [NPC] Can enter check: Sheep 1217 cannot enter herd (not_herded) npc=Sheep 1217 state=herd can_enter=false reason=not_herded herder=unknown
[2026-02-16T13:25:10] [DEBUG] [NPC] Priority eval: Sheep 1217 - herd (priority=11.0, can_enter=false) npc=Sheep 1217 state=herd priority=11.0 can_enter=false
[2026-02-16T13:25:10] [DEBUG] [NPC] Priority eval: Sheep 1217 - raid (priority=8.5, can_enter=false) npc=Sheep 1217 state=raid priority=8.5 can_enter=false
[2026-02-16T13:25:10] [DEBUG] [NPC] Priority eval: Sheep 1217 - reproduction (priority=8.0, can_enter=false) npc=Sheep 1217 state=reproduction priority=8.0 can_enter=false
[2026-02-16T13:25:10] [DEBUG] [NPC] Priority eval: Sheep 1217 - occupy_building (priority=7.5, can_enter=false) npc=Sheep 1217 state=occupy_building priority=7.5 can_enter=false
[2026-02-16T13:25:10] [DEBUG] [NPC] Priority eval: Sheep 1217 - work_at_building (priority=7.0, can_enter=false) npc=Sheep 1217 state=work_at_building priority=7.0 can_enter=false
[2026-02-16T13:25:10] [DEBUG] [NPC] Can enter check: Sheep 1217 cannot enter seek (no_target) npc=Sheep 1217 state=seek can_enter=false reason=no_target
[Assign] Goat 1218 assign_success -> @Node2D@617 dist=65
[Assign] Goat 1218 add_animal_attempt -> @Node2D@617 dist=47 (enter_range=220)
[2026-02-16T13:25:11] [DEBUG] [NPC] Can enter check: PUIK cannot enter agro (not_caveman) npc=PUIK state=agro can_enter=false reason=not_caveman npc_type=woman
[2026-02-16T13:25:11] [DEBUG] [NPC] Priority eval: PUIK - agro (priority=15.0, can_enter=false) npc=PUIK state=agro priority=15.0 can_enter=false
[2026-02-16T13:25:11] [DEBUG] [NPC] Priority eval: PUIK - combat (priority=12.0, can_enter=false) npc=PUIK state=combat priority=12.0 can_enter=false
[2026-02-16T13:25:11] [DEBUG] [NPC] Can enter check: PUIK cannot enter herd (not_herded) npc=PUIK state=herd can_enter=false reason=not_herded herder=unknown
[2026-02-16T13:25:11] [DEBUG] [NPC] Priority eval: PUIK - herd (priority=11.0, can_enter=false) npc=PUIK state=herd priority=11.0 can_enter=false
[2026-02-16T13:25:11] [DEBUG] [NPC] Priority eval: PUIK - raid (priority=8.5, can_enter=false) npc=PUIK state=raid priority=8.5 can_enter=false
[2026-02-16T13:25:11] [DEBUG] [NPC] Priority eval: PUIK - reproduction (priority=8.0, can_enter=false) npc=PUIK state=reproduction priority=8.0 can_enter=false
[2026-02-16T13:25:11] [DEBUG] [NPC] Priority eval: PUIK - occupy_building (priority=7.5, can_enter=false) npc=PUIK state=occupy_building priority=7.5 can_enter=false
[2026-02-16T13:25:11] [DEBUG] [NPC] Priority eval: PUIK - work_at_building (priority=7.0, can_enter=false) npc=PUIK state=work_at_building priority=7.0 can_enter=false
[2026-02-16T13:25:11] [DEBUG] [NPC] Can enter check: PUIK cannot enter seek (no_target) npc=PUIK state=seek can_enter=false reason=no_target
[Assign] Goat 1218 assign_success -> @Node2D@617 dist=39
TASK SYSTEM LOGGER: Called at time 55.0
[2026-02-16T13:25:12] [INFO] [INVENTORY] === TASK SYSTEM LOG: 1 Land Claims ===
[2026-02-16T13:25:12] [INFO] [INVENTORY] LAND CLAIM: OKOK | Pos: (-1050, 689) | Inventory: empty clan_name=OKOK position=(-1049.549, 688.502) inventory=[]
[2026-02-16T13:25:12] [INFO] [INVENTORY] TASK SYSTEM DEBUG: buildings group=5, with building_type=4, ovens=0
[2026-02-16T13:25:12] [INFO] [INVENTORY] === TASK SYSTEM LOG: 0 Ovens ===
[2026-02-16T13:25:12] [DEBUG] [NPC] Can enter check: WUEC cannot enter agro (not_caveman) npc=WUEC state=agro can_enter=false reason=not_caveman npc_type=woman
[2026-02-16T13:25:12] [DEBUG] [NPC] Priority eval: WUEC - agro (priority=15.0, can_enter=false) npc=WUEC state=agro priority=15.0 can_enter=false
[2026-02-16T13:25:12] [DEBUG] [NPC] Priority eval: WUEC - combat (priority=12.0, can_enter=false) npc=WUEC state=combat priority=12.0 can_enter=false
[2026-02-16T13:25:12] [DEBUG] [NPC] Can enter check: WUEC cannot enter herd (not_herded) npc=WUEC state=herd can_enter=false reason=not_herded herder=unknown
[2026-02-16T13:25:12] [DEBUG] [NPC] Priority eval: WUEC - herd (priority=11.0, can_enter=false) npc=WUEC state=herd priority=11.0 can_enter=false
[2026-02-16T13:25:12] [DEBUG] [NPC] Priority eval: WUEC - raid (priority=8.5, can_enter=false) npc=WUEC state=raid priority=8.5 can_enter=false
[2026-02-16T13:25:12] [DEBUG] [NPC] Priority eval: WUEC - reproduction (priority=8.0, can_enter=false) npc=WUEC state=reproduction priority=8.0 can_enter=false
[2026-02-16T13:25:12] [DEBUG] [NPC] Priority eval: WUEC - occupy_building (priority=7.5, can_enter=false) npc=WUEC state=occupy_building priority=7.5 can_enter=false
[2026-02-16T13:25:12] [DEBUG] [NPC] Priority eval: WUEC - work_at_building (priority=7.0, can_enter=false) npc=WUEC state=work_at_building priority=7.0 can_enter=false
[2026-02-16T13:25:12] [DEBUG] [NPC] Can enter check: WUEC cannot enter seek (no_target) npc=WUEC state=seek can_enter=false reason=no_target
[Assign] Goat 1218 assign_success -> @Node2D@617 dist=12
[Assign] Goat 1218 assign_success -> @Node2D@617 dist=12
[2026-02-16T13:25:13] [DEBUG] [NPC] Can enter check: Sheep 1217 cannot enter herd (not_herded) npc=Sheep 1217 state=herd can_enter=false reason=not_herded herder=unknown
[2026-02-16T13:25:13] [DEBUG] [NPC] Priority eval: Sheep 1217 - herd (priority=11.0, can_enter=false) npc=Sheep 1217 state=herd priority=11.0 can_enter=false
[2026-02-16T13:25:13] [DEBUG] [NPC] Priority eval: Sheep 1217 - raid (priority=8.5, can_enter=false) npc=Sheep 1217 state=raid priority=8.5 can_enter=false
[2026-02-16T13:25:13] [DEBUG] [NPC] Priority eval: Sheep 1217 - reproduction (priority=8.0, can_enter=false) npc=Sheep 1217 state=reproduction priority=8.0 can_enter=false
[2026-02-16T13:25:13] [DEBUG] [NPC] Priority eval: Sheep 1217 - occupy_building (priority=7.5, can_enter=false) npc=Sheep 1217 state=occupy_building priority=7.5 can_enter=false
[2026-02-16T13:25:13] [DEBUG] [NPC] Priority eval: Sheep 1217 - work_at_building (priority=7.0, can_enter=false) npc=Sheep 1217 state=work_at_building priority=7.0 can_enter=false
[2026-02-16T13:25:13] [DEBUG] [NPC] Can enter check: Sheep 1217 cannot enter seek (no_target) npc=Sheep 1217 state=seek can_enter=false reason=no_target
[2026-02-16T13:25:13] [DEBUG] [NPC] Priority eval: Sheep 1217 - seek (priority=2.0, can_enter=false) npc=Sheep 1217 state=seek priority=2.0 can_enter=false
[2026-02-16T13:25:13] [DEBUG] [NPC] Evaluated 8 states: agro(priority=15.0,can_enter=false) combat(priority=12.0,can_enter=false) herd(priority=11.0,can_enter=false) raid(priority=8.5,can_enter=false) reproduction(priority=8.0,can_enter=false) occupy_building(priority=7.5,can_enter=false) work_at_building(priority=7.0,can_enter=false) seek(priority=2.0,can_enter=false) -> Best: wander (priority=1.0) npc=Sheep 1217 best_state=wander best_priority=1.0
[2026-02-16T13:25:13] [DEBUG] [NPC] Can enter check: Goat 1319 cannot enter agro (not_caveman) npc=Goat 1319 state=agro can_enter=false reason=not_caveman npc_type=goat
[Assign] Goat 1218 add_animal_attempt -> @Node2D@617 dist=12 (enter_range=220)
[Assign] Goat 1218 assign_success -> @Node2D@617 dist=12
[2026-02-16T13:25:14] [DEBUG] [NPC] Can enter check: DEIS cannot enter agro (not_caveman) npc=DEIS state=agro can_enter=false reason=not_caveman npc_type=woman
[2026-02-16T13:25:14] [DEBUG] [NPC] Priority eval: DEIS - agro (priority=15.0, can_enter=false) npc=DEIS state=agro priority=15.0 can_enter=false
[2026-02-16T13:25:14] [DEBUG] [NPC] Priority eval: DEIS - combat (priority=12.0, can_enter=false) npc=DEIS state=combat priority=12.0 can_enter=false
[2026-02-16T13:25:14] [DEBUG] [NPC] Can enter check: DEIS cannot enter herd (not_herded) npc=DEIS state=herd can_enter=false reason=not_herded herder=unknown
[2026-02-16T13:25:14] [DEBUG] [NPC] Priority eval: DEIS - herd (priority=11.0, can_enter=false) npc=DEIS state=herd priority=11.0 can_enter=false
[2026-02-16T13:25:14] [DEBUG] [NPC] Priority eval: DEIS - raid (priority=8.5, can_enter=false) npc=DEIS state=raid priority=8.5 can_enter=false
[2026-02-16T13:25:14] [DEBUG] [NPC] Priority eval: DEIS - reproduction (priority=8.0, can_enter=false) npc=DEIS state=reproduction priority=8.0 can_enter=false
[2026-02-16T13:25:14] [DEBUG] [NPC] Priority eval: DEIS - occupy_building (priority=7.5, can_enter=false) npc=DEIS state=occupy_building priority=7.5 can_enter=false
[2026-02-16T13:25:14] [DEBUG] [NPC] Priority eval: DEIS - work_at_building (priority=7.0, can_enter=false) npc=DEIS state=work_at_building priority=7.0 can_enter=false
[2026-02-16T13:25:14] [DEBUG] [NPC] Can enter check: DEIS cannot enter seek (no_target) npc=DEIS state=seek can_enter=false reason=no_target
[Assign] Goat 1218 entry clan=OKOK assigned=false
[Assign] Goat 1218 assign_success -> @Node2D@617 dist=12
TASK SYSTEM LOGGER: Called at time 58.0
[2026-02-16T13:25:15] [INFO] [INVENTORY] === TASK SYSTEM LOG: 1 Land Claims ===
[2026-02-16T13:25:15] [INFO] [INVENTORY] LAND CLAIM: OKOK | Pos: (-1050, 689) | Inventory: empty clan_name=OKOK position=(-1049.549, 688.502) inventory=[]
[2026-02-16T13:25:15] [INFO] [INVENTORY] TASK SYSTEM DEBUG: buildings group=5, with building_type=4, ovens=0
[2026-02-16T13:25:15] [INFO] [INVENTORY] === TASK SYSTEM LOG: 0 Ovens ===
[2026-02-16T13:25:15] [DEBUG] [NPC] Steering behavior: SEEK - position npc=WUYA behavior=SEEK target=position position=33.9,509.8
[2026-02-16T13:25:15] [DEBUG] [NPC] Can enter check: JOEC cannot enter agro (not_caveman) npc=JOEC state=agro can_enter=false reason=not_caveman npc_type=woman
[2026-02-16T13:25:15] [DEBUG] [NPC] Priority eval: JOEC - agro (priority=15.0, can_enter=false) npc=JOEC state=agro priority=15.0 can_enter=false
[2026-02-16T13:25:15] [DEBUG] [NPC] Priority eval: JOEC - combat (priority=12.0, can_enter=false) npc=JOEC state=combat priority=12.0 can_enter=false
[2026-02-16T13:25:15] [DEBUG] [NPC] Can enter check: JOEC cannot enter herd (not_herded) npc=JOEC state=herd can_enter=false reason=not_herded herder=unknown
[2026-02-16T13:25:15] [DEBUG] [NPC] Priority eval: JOEC - herd (priority=11.0, can_enter=false) npc=JOEC state=herd priority=11.0 can_enter=false
[2026-02-16T13:25:15] [DEBUG] [NPC] Priority eval: JOEC - raid (priority=8.5, can_enter=false) npc=JOEC state=raid priority=8.5 can_enter=false
[2026-02-16T13:25:15] [DEBUG] [NPC] Priority eval: JOEC - reproduction (priority=8.0, can_enter=false) npc=JOEC state=reproduction priority=8.0 can_enter=false
[2026-02-16T13:25:15] [DEBUG] [NPC] Priority eval: JOEC - occupy_building (priority=7.5, can_enter=false) npc=JOEC state=occupy_building priority=7.5 can_enter=false
[2026-02-16T13:25:15] [DEBUG] [NPC] Priority eval: JOEC - work_at_building (priority=7.0, can_enter=false) npc=JOEC state=work_at_building priority=7.0 can_enter=false
[ASSIGN] Goat 1218 ClaimBuildingIndex returned 4 buildings for claim OKOK
[Assign] Goat 1218 assign_success -> @Node2D@617 dist=12
[Assign] Goat 1218 add_animal_attempt -> @Node2D@617 dist=12 (enter_range=220)
[2026-02-16T13:25:17] [DEBUG] [NPC] Can enter check: JOEC cannot enter agro (not_caveman) npc=JOEC state=agro can_enter=false reason=not_caveman npc_type=woman
[2026-02-16T13:25:17] [DEBUG] [NPC] Priority eval: JOEC - agro (priority=15.0, can_enter=false) npc=JOEC state=agro priority=15.0 can_enter=false
[2026-02-16T13:25:17] [DEBUG] [NPC] Priority eval: JOEC - combat (priority=12.0, can_enter=false) npc=JOEC state=combat priority=12.0 can_enter=false
[2026-02-16T13:25:17] [DEBUG] [NPC] Can enter check: JOEC cannot enter herd (not_herded) npc=JOEC state=herd can_enter=false reason=not_herded herder=unknown
[2026-02-16T13:25:17] [DEBUG] [NPC] Priority eval: JOEC - herd (priority=11.0, can_enter=false) npc=JOEC state=herd priority=11.0 can_enter=false
[2026-02-16T13:25:17] [DEBUG] [NPC] Priority eval: JOEC - raid (priority=8.5, can_enter=false) npc=JOEC state=raid priority=8.5 can_enter=false
[2026-02-16T13:25:17] [DEBUG] [NPC] Priority eval: JOEC - reproduction (priority=8.0, can_enter=false) npc=JOEC state=reproduction priority=8.0 can_enter=false
[2026-02-16T13:25:17] [DEBUG] [NPC] Priority eval: JOEC - occupy_building (priority=7.5, can_enter=false) npc=JOEC state=occupy_building priority=7.5 can_enter=false
[2026-02-16T13:25:17] [DEBUG] [NPC] Priority eval: JOEC - work_at_building (priority=7.0, can_enter=false) npc=JOEC state=work_at_building priority=7.0 can_enter=false
[2026-02-16T13:25:17] [DEBUG] [NPC] Can enter check: JOEC cannot enter seek (no_target) npc=JOEC state=seek can_enter=false reason=no_target
[Assign] Goat 1218 assign_success -> @Node2D@617 dist=12
[Assign] Goat 1218 assign_success -> @Node2D@617 dist=7
[2026-02-16T13:25:18] [DEBUG] [NPC] Steering behavior: SEEK - position npc=Goat 1218 behavior=SEEK target=position position=-852.6,750.0
[2026-02-16T13:25:18] [INFO] [NPC] Action started: assign_to_building (building: Dairy Farm) npc=Goat 1218 action=assign_to_building target=Dairy Farm npc_type=goat building=@Node2D@617 distance=7.0
[2026-02-16T13:25:18] [DEBUG] [NPC] Can enter check: WUEC cannot enter agro (not_caveman) npc=WUEC state=agro can_enter=false reason=not_caveman npc_type=woman
[2026-02-16T13:25:18] [DEBUG] [NPC] Priority eval: WUEC - agro (priority=15.0, can_enter=false) npc=WUEC state=agro priority=15.0 can_enter=false
[2026-02-16T13:25:18] [DEBUG] [NPC] Priority eval: WUEC - combat (priority=12.0, can_enter=false) npc=WUEC state=combat priority=12.0 can_enter=false
[2026-02-16T13:25:18] [DEBUG] [NPC] Can enter check: WUEC cannot enter herd (not_herded) npc=WUEC state=herd can_enter=false reason=not_herded herder=unknown
[2026-02-16T13:25:18] [DEBUG] [NPC] Priority eval: WUEC - herd (priority=11.0, can_enter=false) npc=WUEC state=herd priority=11.0 can_enter=false
[2026-02-16T13:25:18] [DEBUG] [NPC] Priority eval: WUEC - raid (priority=8.5, can_enter=false) npc=WUEC state=raid priority=8.5 can_enter=false
[2026-02-16T13:25:18] [DEBUG] [NPC] Priority eval: WUEC - reproduction (priority=8.0, can_enter=false) npc=WUEC state=reproduction priority=8.0 can_enter=false
[2026-02-16T13:25:18] [DEBUG] [NPC] Priority eval: WUEC - occupy_building (priority=7.5, can_enter=false) npc=WUEC state=occupy_building priority=7.5 can_enter=false
TASK SYSTEM LOGGER: Called at time 61.0
[2026-02-16T13:25:18] [INFO] [INVENTORY] === TASK SYSTEM LOG: 1 Land Claims ===
[2026-02-16T13:25:18] [INFO] [INVENTORY] LAND CLAIM: OKOK | Pos: (-1050, 689) | Inventory: empty clan_name=OKOK position=(-1049.549, 688.502) inventory=[]
[2026-02-16T13:25:18] [INFO] [INVENTORY] TASK SYSTEM DEBUG: buildings group=5, with building_type=4, ovens=0
[2026-02-16T13:25:18] [INFO] [INVENTORY] === TASK SYSTEM LOG: 0 Ovens ===
[Assign] Goat 1218 assign_success -> @Node2D@617 dist=5
🎨 ANIMATION: _load_attack_sprite_sheet() called
🎨 ANIMATION: Loading sprite sheet from: res://assets/sprites/swingclub.png
✅ ANIMATION: Sprite sheet loaded successfully
🎨 ANIMATION: Texture dimensions - width=840, height=560
✅ ANIMATION: Frame size: 280x280 (grid 3x2)
✅ ANIMATION: Default sprite texture stored
FSM: Creating states for BIYU - idle:OK wander:OK seek:OK eat:OK gather:OK herd:OK herd_wildnpc:OK agro:OK build:OK
FSM: Successfully created eat state for BIYU
FSM: Successfully created gather state for BIYU
FSM: Successfully created herd state for BIYU
FSM: Successfully created herd_wildnpc state for BIYU
FSM: Successfully created agro state for BIYU
FSM: Successfully created combat state for BIYU
FSM: Successfully created defend state for BIYU
FSM: Successfully created raid state for BIYU
FSM: Successfully created search state for BIYU
FSM: Successfully created build state for BIYU
FSM: Successfully created reproduction state for BIYU
FSM: Successfully created occupy_building state for BIYU
FSM: Successfully created work_at_building state for BIYU
FSM: Successfully created craft state for BIYU
Task System: Created TaskRunner component for BIYU
🎨 ANIMATION: _load_attack_sprite_sheet() called
🎨 ANIMATION: Loading sprite sheet from: res://assets/sprites/swingclub.png
✅ ANIMATION: Sprite sheet loaded successfully
🎨 ANIMATION: Texture dimensions - width=840, height=560
✅ ANIMATION: Frame size: 280x280 (grid 3x2)
✅ ANIMATION: Default sprite texture stored
FSM: Creating states for Sheep 61220 - idle:OK wander:OK seek:OK eat:OK gather:OK herd:OK herd_wildnpc:OK agro:OK build:OK
FSM: Successfully created eat state for Sheep 61220
FSM: Successfully created gather state for Sheep 61220
FSM: Successfully created herd state for Sheep 61220
FSM: Successfully created herd_wildnpc state for Sheep 61220
FSM: Successfully created agro state for Sheep 61220
FSM: Successfully created combat state for Sheep 61220
FSM: Successfully created defend state for Sheep 61220
FSM: Successfully created raid state for Sheep 61220
FSM: Successfully created search state for Sheep 61220
FSM: Successfully created build state for Sheep 61220
FSM: Successfully created reproduction state for Sheep 61220
FSM: Successfully created occupy_building state for Sheep 61220
FSM: Successfully created work_at_building state for Sheep 61220
FSM: Successfully created craft state for Sheep 61220
Task System: Created TaskRunner component for Sheep 61220
✓ Respawned Wild Sheep: Sheep 61220 at (112.4514, 570.0791)
✓ Respawned Wild Woman: BIYU at (-785.1359, 1564.523) (agility 9.0 = 288.0 speed)
[2026-02-16T13:25:19] [INFO] [NPC] POSITION: Sheep 1418 at (802.0, -129.2), state=wander, distance_to_claim=0.0/400.0, velocity=41.6 npc=Sheep 1418 pos=802.0,-129.2 state=wander distance_to_claim=0.0 claim_radius=400.0 velocity=41.6
[2026-02-16T13:25:19] [DEBUG] [NPC] Can enter check: Sheep 1418 cannot enter agro (not_caveman) npc=Sheep 1418 state=agro can_enter=false reason=not_caveman npc_type=sheep
[2026-02-16T13:25:19] [DEBUG] [NPC] Priority eval: Sheep 1418 - agro (priority=15.0, can_enter=false) npc=Sheep 1418 state=agro priority=15.0 can_enter=false
[2026-02-16T13:25:19] [DEBUG] [NPC] Priority eval: Sheep 1418 - combat (priority=12.0, can_enter=false) npc=Sheep 1418 state=combat priority=12.0 can_enter=false
[2026-02-16T13:25:19] [DEBUG] [NPC] Can enter check: Sheep 1418 cannot enter herd (not_herded) npc=Sheep 1418 state=herd can_enter=false reason=not_herded herder=unknown
[2026-02-16T13:25:19] [DEBUG] [NPC] Priority eval: Sheep 1418 - herd (priority=11.0, can_enter=false) npc=Sheep 1418 state=herd priority=11.0 can_enter=false
[2026-02-16T13:25:19] [DEBUG] [NPC] Priority eval: Sheep 1418 - raid (priority=8.5, can_enter=false) npc=Sheep 1418 state=raid priority=8.5 can_enter=false
[2026-02-16T13:25:19] [DEBUG] [NPC] Priority eval: Sheep 1418 - reproduction (priority=8.0, can_enter=false) npc=Sheep 1418 state=reproduction priority=8.0 can_enter=false
[2026-02-16T13:25:19] [DEBUG] [NPC] Priority eval: Sheep 1418 - occupy_building (priority=7.5, can_enter=false) npc=Sheep 1418 state=occupy_building priority=7.5 can_enter=false
[2026-02-16T13:25:19] [DEBUG] [NPC] Priority eval: Sheep 1418 - work_at_building (priority=7.0, can_enter=false) npc=Sheep 1418 state=work_at_building priority=7.0 can_enter=false
[Assign] Goat 1218 add_animal_attempt -> @Node2D@617 dist=3 (enter_range=220)
[Assign] Goat 1218 assign_success -> @Node2D@617 dist=3
[2026-02-16T13:25:20] [DEBUG] [NPC] Can enter check: WUEC cannot enter agro (not_caveman) npc=WUEC state=agro can_enter=false reason=not_caveman npc_type=woman
[2026-02-16T13:25:20] [DEBUG] [NPC] Priority eval: WUEC - agro (priority=15.0, can_enter=false) npc=WUEC state=agro priority=15.0 can_enter=false
[2026-02-16T13:25:20] [DEBUG] [NPC] Priority eval: WUEC - combat (priority=12.0, can_enter=false) npc=WUEC state=combat priority=12.0 can_enter=false
[2026-02-16T13:25:20] [DEBUG] [NPC] Can enter check: WUEC cannot enter herd (not_herded) npc=WUEC state=herd can_enter=false reason=not_herded herder=unknown
[2026-02-16T13:25:20] [DEBUG] [NPC] Priority eval: WUEC - herd (priority=11.0, can_enter=false) npc=WUEC state=herd priority=11.0 can_enter=false
[2026-02-16T13:25:20] [DEBUG] [NPC] Priority eval: WUEC - raid (priority=8.5, can_enter=false) npc=WUEC state=raid priority=8.5 can_enter=false
[2026-02-16T13:25:20] [DEBUG] [NPC] Priority eval: WUEC - reproduction (priority=8.0, can_enter=false) npc=WUEC state=reproduction priority=8.0 can_enter=false
[2026-02-16T13:25:20] [DEBUG] [NPC] Priority eval: WUEC - occupy_building (priority=7.5, can_enter=false) npc=WUEC state=occupy_building priority=7.5 can_enter=false
[2026-02-16T13:25:20] [DEBUG] [NPC] Priority eval: WUEC - work_at_building (priority=7.0, can_enter=false) npc=WUEC state=work_at_building priority=7.0 can_enter=false
[2026-02-16T13:25:20] [DEBUG] [NPC] Can enter check: WUEC cannot enter seek (no_target) npc=WUEC state=seek can_enter=false reason=no_target
[2026-02-16T13:25:20] [INFO] [INVENTORY] PlayerInventoryUI opened
Player inventory toggled: OPEN
🔍 INVENTORY_UI: setup() called
   - inventory: <RefCounted#-9223371688744316937> (valid: true)
🔍 INVENTORY UI SETUP: Setting inventory_data from <RefCounted#-9223371949546142188> to <RefCounted#-9223371688744316937> (slot_count=6)
   - Calling _build_slots() deferred...
   - Calling _update_all_slots() deferred...
✅ INVENTORY_UI: setup() completed
DEBUG _update_title: is_corpse=false, land_claim=<null>, building=@Node2D@617:<Node2D#348009795497>
DEBUG _update_title: is_corpse=false, land_claim=<null>, building=@Node2D@617:<Node2D#348009795497>
🔵 Building inventory opened for Dairy Farm
DEBUG _update_title: is_corpse=false, land_claim=<null>, building=@Node2D@617:<Node2D#348009795497>
🔍 BUILDING UI SHOW: inventory_data instance: <RefCounted#-9223371688744316937> (slot_count=6, can_stack=true)
🔍 BUILDING UI SHOW: Raw slots array: [<null>, <null>, <null>, <null>, <null>, <null>]
🔍 BUILDING UI SHOW: Slot 0: null
🔍 BUILDING UI SHOW: Slot 1: null
🔍 BUILDING UI SHOW: Slot 2: null
🔍 BUILDING UI SHOW: Slot 3: null
🔍 BUILDING UI SHOW: Slot 4: null
🔍 BUILDING UI SHOW: Slot 5: null
📦 LAND CLAIM INVENTORY: Total items: 0 | Breakdown: empty
[2026-02-16T13:25:20] [INFO] [INVENTORY] BuildingInventoryUI opened
DEBUG _update_title: is_corpse=false, land_claim=<null>, building=@Node2D@617:<Node2D#348009795497>
[Assign] Goat 1218 assign_success -> @Node2D@617 dist=3
[Assign] Goat 1218 entry clan=OKOK assigned=true
[2026-02-16T13:25:20] [WARNING] [NPC] STATE_DURATION: BIYU in wander for 63.2s (LONG - potentially stuck!) npc=BIYU state=wander duration_s=63.2 warning=potentially_stuck
[2026-02-16T13:25:21] [DEBUG] [NPC] Can enter check: Goat 1319 cannot enter agro (not_caveman) npc=Goat 1319 state=agro can_enter=false reason=not_caveman npc_type=goat
[2026-02-16T13:25:21] [DEBUG] [NPC] Priority eval: Goat 1319 - agro (priority=15.0, can_enter=false) npc=Goat 1319 state=agro priority=15.0 can_enter=false
[2026-02-16T13:25:21] [DEBUG] [NPC] Priority eval: Goat 1319 - combat (priority=12.0, can_enter=false) npc=Goat 1319 state=combat priority=12.0 can_enter=false
[2026-02-16T13:25:21] [DEBUG] [NPC] Can enter check: Goat 1319 cannot enter herd (not_herded) npc=Goat 1319 state=herd can_enter=false reason=not_herded herder=unknown
[2026-02-16T13:25:21] [DEBUG] [NPC] Priority eval: Goat 1319 - herd (priority=11.0, can_enter=false) npc=Goat 1319 state=herd priority=11.0 can_enter=false
[2026-02-16T13:25:21] [DEBUG] [NPC] Priority eval: Goat 1319 - raid (priority=8.5, can_enter=false) npc=Goat 1319 state=raid priority=8.5 can_enter=false
[2026-02-16T13:25:21] [DEBUG] [NPC] Priority eval: Goat 1319 - reproduction (priority=8.0, can_enter=false) npc=Goat 1319 state=reproduction priority=8.0 can_enter=false
[2026-02-16T13:25:21] [DEBUG] [NPC] Priority eval: Goat 1319 - occupy_building (priority=7.5, can_enter=false) npc=Goat 1319 state=occupy_building priority=7.5 can_enter=false
[2026-02-16T13:25:21] [DEBUG] [NPC] Priority eval: Goat 1319 - work_at_building (priority=7.0, can_enter=false) npc=Goat 1319 state=work_at_building priority=7.0 can_enter=false
[2026-02-16T13:25:21] [DEBUG] [NPC] Can enter check: Goat 1319 cannot enter seek (no_target) npc=Goat 1319 state=seek can_enter=false reason=no_target
[Assign] Goat 1218 assign_success -> @Node2D@617 dist=3
[Assign] Goat 1218 add_animal_attempt -> @Node2D@617 dist=3 (enter_range=220)
TASK SYSTEM LOGGER: Called at time 64.0
[2026-02-16T13:25:21] [INFO] [INVENTORY] === TASK SYSTEM LOG: 1 Land Claims ===
[2026-02-16T13:25:21] [INFO] [INVENTORY] LAND CLAIM: OKOK | Pos: (-1050, 689) | Inventory: empty clan_name=OKOK position=(-1049.549, 688.502) inventory=[]
[2026-02-16T13:25:21] [INFO] [INVENTORY] TASK SYSTEM DEBUG: buildings group=5, with building_type=4, ovens=0
[2026-02-16T13:25:21] [INFO] [INVENTORY] === TASK SYSTEM LOG: 0 Ovens ===
[2026-02-16T13:25:22] [WARNING] [NPC] STATE_DURATION: Sheep 61220 in wander for 64.2s (LONG - potentially stuck!) npc=Sheep 61220 state=wander duration_s=64.2 warning=potentially_stuck
[2026-02-16T13:25:22] [DEBUG] [NPC] Steering behavior: WANDER - center npc=GEEZ behavior=WANDER target=center position=393.2,499.6 radius=300.0
[2026-02-16T13:25:22] [DEBUG] [NPC] Can enter check: GEEZ cannot enter agro (not_caveman) npc=GEEZ state=agro can_enter=false reason=not_caveman npc_type=woman
[2026-02-16T13:25:22] [DEBUG] [NPC] Priority eval: GEEZ - agro (priority=15.0, can_enter=false) npc=GEEZ state=agro priority=15.0 can_enter=false
[2026-02-16T13:25:22] [DEBUG] [NPC] Priority eval: GEEZ - combat (priority=12.0, can_enter=false) npc=GEEZ state=combat priority=12.0 can_enter=false
[2026-02-16T13:25:22] [DEBUG] [NPC] Can enter check: GEEZ cannot enter herd (not_herded) npc=GEEZ state=herd can_enter=false reason=not_herded herder=unknown
[2026-02-16T13:25:22] [DEBUG] [NPC] Priority eval: GEEZ - herd (priority=11.0, can_enter=false) npc=GEEZ state=herd priority=11.0 can_enter=false
[2026-02-16T13:25:22] [DEBUG] [NPC] Priority eval: GEEZ - raid (priority=8.5, can_enter=false) npc=GEEZ state=raid priority=8.5 can_enter=false
[2026-02-16T13:25:22] [DEBUG] [NPC] Priority eval: GEEZ - reproduction (priority=8.0, can_enter=false) npc=GEEZ state=reproduction priority=8.0 can_enter=false
[2026-02-16T13:25:22] [DEBUG] [NPC] Priority eval: GEEZ - occupy_building (priority=7.5, can_enter=false) npc=GEEZ state=occupy_building priority=7.5 can_enter=false
[2026-02-16T13:25:22] [DEBUG] [NPC] Priority eval: GEEZ - work_at_building (priority=7.0, can_enter=false) npc=GEEZ state=work_at_building priority=7.0 can_enter=false
[ASSIGN] Goat 1218 ClaimBuildingIndex returned 4 buildings for claim OKOK
[Assign] Goat 1218 assign_success -> @Node2D@617 dist=3
[Assign] Goat 1218 assign_success -> @Node2D@617 dist=3
[2026-02-16T13:25:23] [DEBUG] [NPC] Can enter check: XIUF cannot enter agro (not_caveman) npc=XIUF state=agro can_enter=false reason=not_caveman npc_type=woman
[2026-02-16T13:25:23] [DEBUG] [NPC] Priority eval: XIUF - agro (priority=15.0, can_enter=false) npc=XIUF state=agro priority=15.0 can_enter=false
[2026-02-16T13:25:23] [DEBUG] [NPC] Priority eval: XIUF - combat (priority=12.0, can_enter=false) npc=XIUF state=combat priority=12.0 can_enter=false
[2026-02-16T13:25:23] [DEBUG] [NPC] Can enter check: XIUF cannot enter herd (not_herded) npc=XIUF state=herd can_enter=false reason=not_herded herder=unknown
[2026-02-16T13:25:23] [DEBUG] [NPC] Priority eval: XIUF - herd (priority=11.0, can_enter=false) npc=XIUF state=herd priority=11.0 can_enter=false
[2026-02-16T13:25:23] [DEBUG] [NPC] Priority eval: XIUF - raid (priority=8.5, can_enter=false) npc=XIUF state=raid priority=8.5 can_enter=false
[2026-02-16T13:25:23] [DEBUG] [NPC] Priority eval: XIUF - reproduction (priority=8.0, can_enter=false) npc=XIUF state=reproduction priority=8.0 can_enter=false
[2026-02-16T13:25:23] [DEBUG] [NPC] Priority eval: XIUF - occupy_building (priority=7.5, can_enter=false) npc=XIUF state=occupy_building priority=7.5 can_enter=false
[2026-02-16T13:25:23] [DEBUG] [NPC] Priority eval: XIUF - work_at_building (priority=7.0, can_enter=false) npc=XIUF state=work_at_building priority=7.0 can_enter=false
[2026-02-16T13:25:23] [DEBUG] [NPC] Can enter check: XIUF cannot enter seek (no_target) npc=XIUF state=seek can_enter=false reason=no_target
[Assign] Goat 1218 assign_success -> @Node2D@617 dist=2
[2026-02-16T13:25:24] [DEBUG] [NPC] Can enter check: PUIK cannot enter agro (not_caveman) npc=PUIK state=agro can_enter=false reason=not_caveman npc_type=woman
[2026-02-16T13:25:24] [DEBUG] [NPC] Priority eval: PUIK - agro (priority=15.0, can_enter=false) npc=PUIK state=agro priority=15.0 can_enter=false
[2026-02-16T13:25:24] [DEBUG] [NPC] Priority eval: PUIK - combat (priority=12.0, can_enter=false) npc=PUIK state=combat priority=12.0 can_enter=false
[2026-02-16T13:25:24] [DEBUG] [NPC] Can enter check: PUIK cannot enter herd (not_herded) npc=PUIK state=herd can_enter=false reason=not_herded herder=unknown
[2026-02-16T13:25:24] [DEBUG] [NPC] Priority eval: PUIK - herd (priority=11.0, can_enter=false) npc=PUIK state=herd priority=11.0 can_enter=false
[2026-02-16T13:25:24] [DEBUG] [NPC] Priority eval: PUIK - raid (priority=8.5, can_enter=false) npc=PUIK state=raid priority=8.5 can_enter=false
[2026-02-16T13:25:24] [DEBUG] [NPC] Priority eval: PUIK - reproduction (priority=8.0, can_enter=false) npc=PUIK state=reproduction priority=8.0 can_enter=false
[2026-02-16T13:25:24] [DEBUG] [NPC] Priority eval: PUIK - occupy_building (priority=7.5, can_enter=false) npc=PUIK state=occupy_building priority=7.5 can_enter=false
[2026-02-16T13:25:24] [DEBUG] [NPC] Priority eval: PUIK - work_at_building (priority=7.0, can_enter=false) npc=PUIK state=work_at_building priority=7.0 can_enter=false
[2026-02-16T13:25:24] [DEBUG] [NPC] Can enter check: PUIK cannot enter seek (no_target) npc=PUIK state=seek can_enter=false reason=no_target
[Assign] Goat 1218 add_animal_attempt -> @Node2D@617 dist=1 (enter_range=220)
[Assign] Goat 1218 assign_success -> @Node2D@617 dist=1
TASK SYSTEM LOGGER: Called at time 67.0
[2026-02-16T13:25:24] [INFO] [INVENTORY] === TASK SYSTEM LOG: 1 Land Claims ===
[2026-02-16T13:25:24] [INFO] [INVENTORY] LAND CLAIM: OKOK | Pos: (-1050, 689) | Inventory: empty clan_name=OKOK position=(-1049.549, 688.502) inventory=[]
[2026-02-16T13:25:24] [INFO] [INVENTORY] TASK SYSTEM DEBUG: buildings group=5, with building_type=4, ovens=0
[2026-02-16T13:25:24] [INFO] [INVENTORY] === TASK SYSTEM LOG: 0 Ovens ===
🔓 MAIN: NPC Goat 1218 movement resumed
[2026-02-16T13:25:24] [INFO] [INVENTORY] BuildingInventoryUI closed
[2026-02-16T13:25:25] [DEBUG] [NPC] Can enter check: WUEC cannot enter agro (not_caveman) npc=WUEC state=agro can_enter=false reason=not_caveman npc_type=woman
[2026-02-16T13:25:25] [DEBUG] [NPC] Priority eval: WUEC - agro (priority=15.0, can_enter=false) npc=WUEC state=agro priority=15.0 can_enter=false
[2026-02-16T13:25:25] [DEBUG] [NPC] Priority eval: WUEC - combat (priority=12.0, can_enter=false) npc=WUEC state=combat priority=12.0 can_enter=false
[2026-02-16T13:25:25] [DEBUG] [NPC] Can enter check: WUEC cannot enter herd (not_herded) npc=WUEC state=herd can_enter=false reason=not_herded herder=unknown
[2026-02-16T13:25:25] [DEBUG] [NPC] Priority eval: WUEC - herd (priority=11.0, can_enter=false) npc=WUEC state=herd priority=11.0 can_enter=false
[2026-02-16T13:25:25] [DEBUG] [NPC] Priority eval: WUEC - raid (priority=8.5, can_enter=false) npc=WUEC state=raid priority=8.5 can_enter=false
[2026-02-16T13:25:25] [DEBUG] [NPC] Priority eval: WUEC - reproduction (priority=8.0, can_enter=false) npc=WUEC state=reproduction priority=8.0 can_enter=false
[2026-02-16T13:25:25] [DEBUG] [NPC] Priority eval: WUEC - occupy_building (priority=7.5, can_enter=false) npc=WUEC state=occupy_building priority=7.5 can_enter=false
[2026-02-16T13:25:25] [DEBUG] [NPC] Priority eval: WUEC - work_at_building (priority=7.0, can_enter=false) npc=WUEC state=work_at_building priority=7.0 can_enter=false
[2026-02-16T13:25:25] [DEBUG] [NPC] Can enter check: WUEC cannot enter seek (no_target) npc=WUEC state=seek can_enter=false reason=no_target
[Assign] Goat 1218 assign_success -> @Node2D@617 dist=1
[2026-02-16T13:25:26] [DEBUG] [NPC] Steering behavior: SEEK - position npc=JOEC behavior=SEEK target=position position=-32.2,1507.9
[2026-02-16T13:25:26] [DEBUG] [NPC] Can enter check: Sheep 1418 cannot enter agro (not_caveman) npc=Sheep 1418 state=agro can_enter=false reason=not_caveman npc_type=sheep
[2026-02-16T13:25:26] [DEBUG] [NPC] Priority eval: Sheep 1418 - agro (priority=15.0, can_enter=false) npc=Sheep 1418 state=agro priority=15.0 can_enter=false
[2026-02-16T13:25:26] [DEBUG] [NPC] Priority eval: Sheep 1418 - combat (priority=12.0, can_enter=false) npc=Sheep 1418 state=combat priority=12.0 can_enter=false
[2026-02-16T13:25:26] [DEBUG] [NPC] Can enter check: Sheep 1418 cannot enter herd (not_herded) npc=Sheep 1418 state=herd can_enter=false reason=not_herded herder=unknown
[2026-02-16T13:25:26] [DEBUG] [NPC] Priority eval: Sheep 1418 - herd (priority=11.0, can_enter=false) npc=Sheep 1418 state=herd priority=11.0 can_enter=false
[2026-02-16T13:25:26] [DEBUG] [NPC] Priority eval: Sheep 1418 - raid (priority=8.5, can_enter=false) npc=Sheep 1418 state=raid priority=8.5 can_enter=false
[2026-02-16T13:25:26] [DEBUG] [NPC] Priority eval: Sheep 1418 - reproduction (priority=8.0, can_enter=false) npc=Sheep 1418 state=reproduction priority=8.0 can_enter=false
[2026-02-16T13:25:26] [DEBUG] [NPC] Priority eval: Sheep 1418 - occupy_building (priority=7.5, can_enter=false) npc=Sheep 1418 state=occupy_building priority=7.5 can_enter=false
[2026-02-16T13:25:26] [DEBUG] [NPC] Priority eval: Sheep 1418 - work_at_building (priority=7.0, can_enter=false) npc=Sheep 1418 state=work_at_building priority=7.0 can_enter=false
[Assign] Goat 1218 entry clan=OKOK assigned=false
[Assign] Goat 1218 assign_success -> @Node2D@617 dist=1
[2026-02-16T13:25:26] [INFO] [INVENTORY] PlayerInventoryUI closed
Player inventory toggled: CLOSED
🔍 INVENTORY_UI: setup() called
   - inventory: <RefCounted#-9223371688744316937> (valid: true)
🔍 INVENTORY UI SETUP: Setting inventory_data from <RefCounted#-9223371688744316937> to <RefCounted#-9223371688744316937> (slot_count=6)
   - Calling _build_slots() deferred...
   - Calling _update_all_slots() deferred...
✅ INVENTORY_UI: setup() completed
DEBUG _update_title: is_corpse=false, land_claim=<null>, building=@Node2D@617:<Node2D#348009795497>
DEBUG _update_title: is_corpse=false, land_claim=<null>, building=@Node2D@617:<Node2D#348009795497>
🔵 Building inventory opened for Dairy Farm
[2026-02-16T13:25:26] [INFO] [INVENTORY] BuildingInventoryUI closed
DEBUG _update_title: is_corpse=false, land_claim=<null>, building=@Node2D@617:<Node2D#348009795497>
[Assign] Goat 1218 add_animal_attempt -> @Node2D@617 dist=1 (enter_range=220)
[Assign] Goat 1218 assign_success -> @Node2D@617 dist=1
[2026-02-16T13:25:27] [INFO] [INVENTORY] PlayerInventoryUI opened
Player inventory toggled: OPEN
🔍 INVENTORY_UI: setup() called
   - inventory: <RefCounted#-9223371688744316937> (valid: true)
🔍 INVENTORY UI SETUP: Setting inventory_data from <RefCounted#-9223371688744316937> to <RefCounted#-9223371688744316937> (slot_count=6)
   - Calling _build_slots() deferred...
   - Calling _update_all_slots() deferred...
✅ INVENTORY_UI: setup() completed
DEBUG _update_title: is_corpse=false, land_claim=<null>, building=@Node2D@617:<Node2D#348009795497>
DEBUG _update_title: is_corpse=false, land_claim=<null>, building=@Node2D@617:<Node2D#348009795497>
🔵 Building inventory opened for Dairy Farm
DEBUG _update_title: is_corpse=false, land_claim=<null>, building=@Node2D@617:<Node2D#348009795497>
🔍 BUILDING UI SHOW: inventory_data instance: <RefCounted#-9223371688744316937> (slot_count=6, can_stack=true)
🔍 BUILDING UI SHOW: Raw slots array: [<null>, <null>, <null>, <null>, <null>, <null>]
🔍 BUILDING UI SHOW: Slot 0: null
🔍 BUILDING UI SHOW: Slot 1: null
🔍 BUILDING UI SHOW: Slot 2: null
🔍 BUILDING UI SHOW: Slot 3: null
🔍 BUILDING UI SHOW: Slot 4: null
🔍 BUILDING UI SHOW: Slot 5: null
📦 LAND CLAIM INVENTORY: Total items: 0 | Breakdown: empty
[2026-02-16T13:25:27] [INFO] [INVENTORY] BuildingInventoryUI opened
DEBUG _update_title: is_corpse=false, land_claim=<null>, building=@Node2D@617:<Node2D#348009795497>
[2026-02-16T13:25:27] [DEBUG] [NPC] Can enter check: KUKO cannot enter agro (not_caveman) npc=KUKO state=agro can_enter=false reason=not_caveman npc_type=woman
[2026-02-16T13:25:27] [DEBUG] [NPC] Priority eval: KUKO - agro (priority=15.0, can_enter=false) npc=KUKO state=agro priority=15.0 can_enter=false
[2026-02-16T13:25:27] [DEBUG] [NPC] Priority eval: KUKO - combat (priority=12.0, can_enter=false) npc=KUKO state=combat priority=12.0 can_enter=false
[2026-02-16T13:25:27] [DEBUG] [NPC] Can enter check: KUKO cannot enter herd (not_herded) npc=KUKO state=herd can_enter=false reason=not_herded herder=unknown
[2026-02-16T13:25:27] [DEBUG] [NPC] Priority eval: KUKO - herd (priority=11.0, can_enter=false) npc=KUKO state=herd priority=11.0 can_enter=false
[2026-02-16T13:25:27] [DEBUG] [NPC] Priority eval: KUKO - raid (priority=8.5, can_enter=false) npc=KUKO state=raid priority=8.5 can_enter=false
[2026-02-16T13:25:27] [DEBUG] [NPC] Priority eval: KUKO - reproduction (priority=8.0, can_enter=false) npc=KUKO state=reproduction priority=8.0 can_enter=false
[2026-02-16T13:25:27] [DEBUG] [NPC] Priority eval: KUKO - occupy_building (priority=7.5, can_enter=false) npc=KUKO state=occupy_building priority=7.5 can_enter=false
[2026-02-16T13:25:27] [DEBUG] [NPC] Priority eval: KUKO - work_at_building (priority=7.0, can_enter=false) npc=KUKO state=work_at_building priority=7.0 can_enter=false
[2026-02-16T13:25:27] [DEBUG] [NPC] Can enter check: KUKO cannot enter seek (no_target) npc=KUKO state=seek can_enter=false reason=no_target
TASK SYSTEM LOGGER: Called at time 70.0
[2026-02-16T13:25:27] [INFO] [INVENTORY] === TASK SYSTEM LOG: 1 Land Claims ===
[2026-02-16T13:25:27] [INFO] [INVENTORY] LAND CLAIM: OKOK | Pos: (-1050, 689) | Inventory: empty clan_name=OKOK position=(-1049.549, 688.502) inventory=[]
[2026-02-16T13:25:27] [INFO] [INVENTORY] TASK SYSTEM DEBUG: buildings group=5, with building_type=4, ovens=0
[2026-02-16T13:25:27] [INFO] [INVENTORY] === TASK SYSTEM LOG: 0 Ovens ===
[ASSIGN] Goat 1218 ClaimBuildingIndex returned 4 buildings for claim OKOK
[Assign] Goat 1218 assign_success -> @Node2D@617 dist=1
[2026-02-16T13:25:28] [DEBUG] [NPC] Can enter check: XIUF cannot enter agro (not_caveman) npc=XIUF state=agro can_enter=false reason=not_caveman npc_type=woman
[2026-02-16T13:25:28] [DEBUG] [NPC] Priority eval: XIUF - agro (priority=15.0, can_enter=false) npc=XIUF state=agro priority=15.0 can_enter=false
[2026-02-16T13:25:28] [DEBUG] [NPC] Priority eval: XIUF - combat (priority=12.0, can_enter=false) npc=XIUF state=combat priority=12.0 can_enter=false
[2026-02-16T13:25:28] [DEBUG] [NPC] Can enter check: XIUF cannot enter herd (not_herded) npc=XIUF state=herd can_enter=false reason=not_herded herder=unknown
[2026-02-16T13:25:28] [DEBUG] [NPC] Priority eval: XIUF - herd (priority=11.0, can_enter=false) npc=XIUF state=herd priority=11.0 can_enter=false
[2026-02-16T13:25:28] [DEBUG] [NPC] Priority eval: XIUF - raid (priority=8.5, can_enter=false) npc=XIUF state=raid priority=8.5 can_enter=false
[2026-02-16T13:25:28] [DEBUG] [NPC] Priority eval: XIUF - reproduction (priority=8.0, can_enter=false) npc=XIUF state=reproduction priority=8.0 can_enter=false
[2026-02-16T13:25:28] [DEBUG] [NPC] Priority eval: XIUF - occupy_building (priority=7.5, can_enter=false) npc=XIUF state=occupy_building priority=7.5 can_enter=false
[2026-02-16T13:25:28] [DEBUG] [NPC] Priority eval: XIUF - work_at_building (priority=7.0, can_enter=false) npc=XIUF state=work_at_building priority=7.0 can_enter=false
[2026-02-16T13:25:28] [DEBUG] [NPC] Can enter check: XIUF cannot enter seek (no_target) npc=XIUF state=seek can_enter=false reason=no_target
[Assign] Goat 1218 assign_success -> @Node2D@617 dist=5
[Assign] Goat 1218 add_animal_attempt -> @Node2D@617 dist=6 (enter_range=220)
[2026-02-16T13:25:29] [INFO] [NPC] POSITION: Sheep 1418 at (953.0, -111.1), state=wander, distance_to_claim=0.0/400.0, velocity=61.7 npc=Sheep 1418 pos=953.0,-111.1 state=wander distance_to_claim=0.0 claim_radius=400.0 velocity=61.7
[2026-02-16T13:25:29] [DEBUG] [NPC] Can enter check: Sheep 1418 cannot enter agro (not_caveman) npc=Sheep 1418 state=agro can_enter=false reason=not_caveman npc_type=sheep
[2026-02-16T13:25:29] [DEBUG] [NPC] Priority eval: Sheep 1418 - agro (priority=15.0, can_enter=false) npc=Sheep 1418 state=agro priority=15.0 can_enter=false
[2026-02-16T13:25:29] [DEBUG] [NPC] Priority eval: Sheep 1418 - combat (priority=12.0, can_enter=false) npc=Sheep 1418 state=combat priority=12.0 can_enter=false
[2026-02-16T13:25:29] [DEBUG] [NPC] Can enter check: Sheep 1418 cannot enter herd (not_herded) npc=Sheep 1418 state=herd can_enter=false reason=not_herded herder=unknown
[2026-02-16T13:25:29] [DEBUG] [NPC] Priority eval: Sheep 1418 - herd (priority=11.0, can_enter=false) npc=Sheep 1418 state=herd priority=11.0 can_enter=false
[2026-02-16T13:25:29] [DEBUG] [NPC] Priority eval: Sheep 1418 - raid (priority=8.5, can_enter=false) npc=Sheep 1418 state=raid priority=8.5 can_enter=false
[2026-02-16T13:25:29] [DEBUG] [NPC] Priority eval: Sheep 1418 - reproduction (priority=8.0, can_enter=false) npc=Sheep 1418 state=reproduction priority=8.0 can_enter=false
[2026-02-16T13:25:29] [DEBUG] [NPC] Priority eval: Sheep 1418 - occupy_building (priority=7.5, can_enter=false) npc=Sheep 1418 state=occupy_building priority=7.5 can_enter=false
[2026-02-16T13:25:29] [DEBUG] [NPC] Priority eval: Sheep 1418 - work_at_building (priority=7.0, can_enter=false) npc=Sheep 1418 state=work_at_building priority=7.0 can_enter=false
[Assign] Goat 1218 assign_success -> @Node2D@617 dist=6
🔓 MAIN: NPC Goat 1218 movement resumed
[2026-02-16T13:25:29] [INFO] [INVENTORY] BuildingInventoryUI closed
[Assign] Goat 1218 assign_success -> @Node2D@617 dist=6
[2026-02-16T13:25:30] [DEBUG] [NPC] Steering behavior: SEEK - position npc=Goat 1218 behavior=SEEK target=position position=-852.6,750.0
[2026-02-16T13:25:30] [INFO] [NPC] Action started: assign_to_building (building: Dairy Farm) npc=Goat 1218 action=assign_to_building target=Dairy Farm npc_type=goat building=@Node2D@617 distance=6.0
[2026-02-16T13:25:30] [DEBUG] [NPC] Can enter check: JOEC cannot enter agro (not_caveman) npc=JOEC state=agro can_enter=false reason=not_caveman npc_type=woman
[2026-02-16T13:25:30] [DEBUG] [NPC] Priority eval: JOEC - agro (priority=15.0, can_enter=false) npc=JOEC state=agro priority=15.0 can_enter=false
[2026-02-16T13:25:30] [DEBUG] [NPC] Priority eval: JOEC - combat (priority=12.0, can_enter=false) npc=JOEC state=combat priority=12.0 can_enter=false
[2026-02-16T13:25:30] [DEBUG] [NPC] Can enter check: JOEC cannot enter herd (not_herded) npc=JOEC state=herd can_enter=false reason=not_herded herder=unknown
[2026-02-16T13:25:30] [DEBUG] [NPC] Priority eval: JOEC - herd (priority=11.0, can_enter=false) npc=JOEC state=herd priority=11.0 can_enter=false
[2026-02-16T13:25:30] [DEBUG] [NPC] Priority eval: JOEC - raid (priority=8.5, can_enter=false) npc=JOEC state=raid priority=8.5 can_enter=false
[2026-02-16T13:25:30] [DEBUG] [NPC] Priority eval: JOEC - reproduction (priority=8.0, can_enter=false) npc=JOEC state=reproduction priority=8.0 can_enter=false
[2026-02-16T13:25:30] [DEBUG] [NPC] Priority eval: JOEC - occupy_building (priority=7.5, can_enter=false) npc=JOEC state=occupy_building priority=7.5 can_enter=false
TASK SYSTEM LOGGER: Called at time 73.0
[2026-02-16T13:25:30] [INFO] [INVENTORY] === TASK SYSTEM LOG: 1 Land Claims ===
[2026-02-16T13:25:30] [INFO] [INVENTORY] LAND CLAIM: OKOK | Pos: (-1050, 689) | Inventory: empty clan_name=OKOK position=(-1049.549, 688.502) inventory=[]
[2026-02-16T13:25:30] [INFO] [INVENTORY] TASK SYSTEM DEBUG: buildings group=5, with building_type=4, ovens=0
[2026-02-16T13:25:30] [INFO] [INVENTORY] === TASK SYSTEM LOG: 0 Ovens ===
[2026-02-16T13:25:30] [INFO] [INVENTORY] PlayerInventoryUI closed
Player inventory toggled: CLOSED
🔍 INVENTORY_UI: setup() called
   - inventory: <RefCounted#-9223371688744316937> (valid: true)
🔍 INVENTORY UI SETUP: Setting inventory_data from <RefCounted#-9223371688744316937> to <RefCounted#-9223371688744316937> (slot_count=6)
   - Calling _build_slots() deferred...
   - Calling _update_all_slots() deferred...
✅ INVENTORY_UI: setup() completed
DEBUG _update_title: is_corpse=false, land_claim=<null>, building=@Node2D@617:<Node2D#348009795497>
DEBUG _update_title: is_corpse=false, land_claim=<null>, building=@Node2D@617:<Node2D#348009795497>
🔵 Building inventory opened for Dairy Farm
[2026-02-16T13:25:30] [INFO] [INVENTORY] BuildingInventoryUI closed
DEBUG _update_title: is_corpse=false, land_claim=<null>, building=@Node2D@617:<Node2D#348009795497>
[Assign] Goat 1218 assign_success -> @Node2D@617 dist=6
[2026-02-16T13:25:31] [INFO] [NPC] POSITION: WUYA at (-3.0, 520.0), state=wander, distance_to_claim=0.0/400.0, velocity=19.5 npc=WUYA pos=-3.0,520.0 state=wander distance_to_claim=0.0 claim_radius=400.0 velocity=19.5
[2026-02-16T13:25:31] [DEBUG] [NPC] Steering behavior: SEEK - position npc=WUYA behavior=SEEK target=position position=-3.0,520.0
[2026-02-16T13:25:31] [INFO] [NPC] POSITION: XIUF at (-76.8, 404.9), state=wander, distance_to_claim=0.0/400.0, velocity=18.9 npc=XIUF pos=-76.8,404.9 state=wander distance_to_claim=0.0 claim_radius=400.0 velocity=18.9
[2026-02-16T13:25:31] [DEBUG] [NPC] Can enter check: XIUF cannot enter agro (not_caveman) npc=XIUF state=agro can_enter=false reason=not_caveman npc_type=woman
[2026-02-16T13:25:31] [DEBUG] [NPC] Priority eval: XIUF - agro (priority=15.0, can_enter=false) npc=XIUF state=agro priority=15.0 can_enter=false
[2026-02-16T13:25:31] [DEBUG] [NPC] Priority eval: XIUF - combat (priority=12.0, can_enter=false) npc=XIUF state=combat priority=12.0 can_enter=false
[2026-02-16T13:25:31] [DEBUG] [NPC] Can enter check: XIUF cannot enter herd (not_herded) npc=XIUF state=herd can_enter=false reason=not_herded herder=unknown
[2026-02-16T13:25:31] [DEBUG] [NPC] Priority eval: XIUF - herd (priority=11.0, can_enter=false) npc=XIUF state=herd priority=11.0 can_enter=false
[2026-02-16T13:25:31] [DEBUG] [NPC] Priority eval: XIUF - raid (priority=8.5, can_enter=false) npc=XIUF state=raid priority=8.5 can_enter=false
[2026-02-16T13:25:31] [DEBUG] [NPC] Priority eval: XIUF - reproduction (priority=8.0, can_enter=false) npc=XIUF state=reproduction priority=8.0 can_enter=false
[Assign] Goat 1218 entry clan=OKOK assigned=true
[Assign] Goat 1218 add_animal_attempt -> @Node2D@617 dist=6 (enter_range=220)
[2026-02-16T13:25:31] [INFO] [INVENTORY] PlayerInventoryUI opened
Player inventory toggled: OPEN
🔍 INVENTORY_UI: setup() called
   - inventory: <RefCounted#-9223371688744316937> (valid: true)
🔍 INVENTORY UI SETUP: Setting inventory_data from <RefCounted#-9223371688744316937> to <RefCounted#-9223371688744316937> (slot_count=6)
   - Calling _build_slots() deferred...
   - Calling _update_all_slots() deferred...
✅ INVENTORY_UI: setup() completed
DEBUG _update_title: is_corpse=false, land_claim=<null>, building=@Node2D@617:<Node2D#348009795497>
DEBUG _update_title: is_corpse=false, land_claim=<null>, building=@Node2D@617:<Node2D#348009795497>
🔵 Building inventory opened for Dairy Farm
DEBUG _update_title: is_corpse=false, land_claim=<null>, building=@Node2D@617:<Node2D#348009795497>
🔍 BUILDING UI SHOW: inventory_data instance: <RefCounted#-9223371688744316937> (slot_count=6, can_stack=true)
🔍 BUILDING UI SHOW: Raw slots array: [<null>, <null>, <null>, <null>, <null>, <null>]
🔍 BUILDING UI SHOW: Slot 0: null
🔍 BUILDING UI SHOW: Slot 1: null
🔍 BUILDING UI SHOW: Slot 2: null
🔍 BUILDING UI SHOW: Slot 3: null
🔍 BUILDING UI SHOW: Slot 4: null
🔍 BUILDING UI SHOW: Slot 5: null
📦 LAND CLAIM INVENTORY: Total items: 0 | Breakdown: empty
[2026-02-16T13:25:31] [INFO] [INVENTORY] BuildingInventoryUI opened
DEBUG _update_title: is_corpse=false, land_claim=<null>, building=@Node2D@617:<Node2D#348009795497>
[Assign] Goat 1218 assign_success -> @Node2D@617 dist=8
[2026-02-16T13:25:32] [DEBUG] [NPC] Can enter check: KUKO cannot enter agro (not_caveman) npc=KUKO state=agro can_enter=false reason=not_caveman npc_type=woman
[2026-02-16T13:25:32] [DEBUG] [NPC] Priority eval: KUKO - agro (priority=15.0, can_enter=false) npc=KUKO state=agro priority=15.0 can_enter=false
[2026-02-16T13:25:32] [DEBUG] [NPC] Priority eval: KUKO - combat (priority=12.0, can_enter=false) npc=KUKO state=combat priority=12.0 can_enter=false
[2026-02-16T13:25:32] [DEBUG] [NPC] Can enter check: KUKO cannot enter herd (not_herded) npc=KUKO state=herd can_enter=false reason=not_herded herder=unknown
[2026-02-16T13:25:32] [DEBUG] [NPC] Priority eval: KUKO - herd (priority=11.0, can_enter=false) npc=KUKO state=herd priority=11.0 can_enter=false
[2026-02-16T13:25:32] [DEBUG] [NPC] Priority eval: KUKO - raid (priority=8.5, can_enter=false) npc=KUKO state=raid priority=8.5 can_enter=false
[2026-02-16T13:25:32] [DEBUG] [NPC] Priority eval: KUKO - reproduction (priority=8.0, can_enter=false) npc=KUKO state=reproduction priority=8.0 can_enter=false
[2026-02-16T13:25:32] [DEBUG] [NPC] Priority eval: KUKO - occupy_building (priority=7.5, can_enter=false) npc=KUKO state=occupy_building priority=7.5 can_enter=false
[2026-02-16T13:25:32] [DEBUG] [NPC] Priority eval: KUKO - work_at_building (priority=7.0, can_enter=false) npc=KUKO state=work_at_building priority=7.0 can_enter=false
[2026-02-16T13:25:32] [DEBUG] [NPC] Can enter check: KUKO cannot enter seek (no_target) npc=KUKO state=seek can_enter=false reason=no_target
[Assign] Goat 1218 assign_success -> @Node2D@617 dist=5
[2026-02-16T13:25:33] [INFO] [NPC] POSITION: GEEZ at (407.0, 664.3), state=wander, distance_to_claim=0.0/400.0, velocity=49.1 npc=GEEZ pos=407.0,664.3 state=wander distance_to_claim=0.0 claim_radius=400.0 velocity=49.1
[2026-02-16T13:25:33] [DEBUG] [NPC] Can enter check: GEEZ cannot enter agro (not_caveman) npc=GEEZ state=agro can_enter=false reason=not_caveman npc_type=woman
[2026-02-16T13:25:33] [DEBUG] [NPC] Priority eval: GEEZ - agro (priority=15.0, can_enter=false) npc=GEEZ state=agro priority=15.0 can_enter=false
[2026-02-16T13:25:33] [DEBUG] [NPC] Priority eval: GEEZ - combat (priority=12.0, can_enter=false) npc=GEEZ state=combat priority=12.0 can_enter=false
[2026-02-16T13:25:33] [DEBUG] [NPC] Can enter check: GEEZ cannot enter herd (not_herded) npc=GEEZ state=herd can_enter=false reason=not_herded herder=unknown
[2026-02-16T13:25:33] [DEBUG] [NPC] Priority eval: GEEZ - herd (priority=11.0, can_enter=false) npc=GEEZ state=herd priority=11.0 can_enter=false
[2026-02-16T13:25:33] [DEBUG] [NPC] Priority eval: GEEZ - raid (priority=8.5, can_enter=false) npc=GEEZ state=raid priority=8.5 can_enter=false
[2026-02-16T13:25:33] [DEBUG] [NPC] Priority eval: GEEZ - reproduction (priority=8.0, can_enter=false) npc=GEEZ state=reproduction priority=8.0 can_enter=false
[2026-02-16T13:25:33] [DEBUG] [NPC] Priority eval: GEEZ - occupy_building (priority=7.5, can_enter=false) npc=GEEZ state=occupy_building priority=7.5 can_enter=false
[2026-02-16T13:25:33] [DEBUG] [NPC] Priority eval: GEEZ - work_at_building (priority=7.0, can_enter=false) npc=GEEZ state=work_at_building priority=7.0 can_enter=false
[ASSIGN] Goat 1218 ClaimBuildingIndex returned 4 buildings for claim OKOK
[Assign] Goat 1218 assign_success -> @Node2D@617 dist=5
TASK SYSTEM LOGGER: Called at time 76.0
[2026-02-16T13:25:33] [INFO] [INVENTORY] === TASK SYSTEM LOG: 1 Land Claims ===
[2026-02-16T13:25:33] [INFO] [INVENTORY] LAND CLAIM: OKOK | Pos: (-1050, 689) | Inventory: empty clan_name=OKOK position=(-1049.549, 688.502) inventory=[]
[2026-02-16T13:25:33] [INFO] [INVENTORY] TASK SYSTEM DEBUG: buildings group=5, with building_type=4, ovens=0
[2026-02-16T13:25:33] [INFO] [INVENTORY] === TASK SYSTEM LOG: 0 Ovens ===
[Assign] Goat 1218 add_animal_attempt -> @Node2D@617 dist=3 (enter_range=220)
🔓 MAIN: NPC Goat 1218 movement resumed
[2026-02-16T13:25:34] [INFO] [INVENTORY] BuildingInventoryUI closed
[2026-02-16T13:25:34] [DEBUG] [NPC] Can enter check: Goat 1419 cannot enter agro (not_caveman) npc=Goat 1419 state=agro can_enter=false reason=not_caveman npc_type=goat
[2026-02-16T13:25:34] [DEBUG] [NPC] Priority eval: Goat 1419 - agro (priority=15.0, can_enter=false) npc=Goat 1419 state=agro priority=15.0 can_enter=false
[2026-02-16T13:25:34] [DEBUG] [NPC] Priority eval: Goat 1419 - combat (priority=12.0, can_enter=false) npc=Goat 1419 state=combat priority=12.0 can_enter=false
[2026-02-16T13:25:34] [DEBUG] [NPC] Can enter check: Goat 1419 cannot enter herd (not_herded) npc=Goat 1419 state=herd can_enter=false reason=not_herded herder=unknown
[2026-02-16T13:25:34] [DEBUG] [NPC] Priority eval: Goat 1419 - herd (priority=11.0, can_enter=false) npc=Goat 1419 state=herd priority=11.0 can_enter=false
[2026-02-16T13:25:34] [DEBUG] [NPC] Priority eval: Goat 1419 - raid (priority=8.5, can_enter=false) npc=Goat 1419 state=raid priority=8.5 can_enter=false
[2026-02-16T13:25:34] [DEBUG] [NPC] Priority eval: Goat 1419 - reproduction (priority=8.0, can_enter=false) npc=Goat 1419 state=reproduction priority=8.0 can_enter=false
[2026-02-16T13:25:34] [DEBUG] [NPC] Priority eval: Goat 1419 - occupy_building (priority=7.5, can_enter=false) npc=Goat 1419 state=occupy_building priority=7.5 can_enter=false
[2026-02-16T13:25:34] [DEBUG] [NPC] Priority eval: Goat 1419 - work_at_building (priority=7.0, can_enter=false) npc=Goat 1419 state=work_at_building priority=7.0 can_enter=false
[2026-02-16T13:25:34] [DEBUG] [NPC] Can enter check: Goat 1419 cannot enter seek (no_target) npc=Goat 1419 state=seek can_enter=false reason=no_target
[Assign] Goat 1218 assign_success -> @Node2D@617 dist=3
[Assign] Goat 1218 assign_success -> @Node2D@617 dist=2
[2026-02-16T13:25:35] [DEBUG] [NPC] Priority eval: Goat 1319 - combat (priority=12.0, can_enter=false) npc=Goat 1319 state=combat priority=12.0 can_enter=false
[2026-02-16T13:25:35] [DEBUG] [NPC] Can enter check: Goat 1319 cannot enter herd (not_herded) npc=Goat 1319 state=herd can_enter=false reason=not_herded herder=unknown
[2026-02-16T13:25:35] [DEBUG] [NPC] Priority eval: Goat 1319 - herd (priority=11.0, can_enter=false) npc=Goat 1319 state=herd priority=11.0 can_enter=false
[2026-02-16T13:25:35] [DEBUG] [NPC] Priority eval: Goat 1319 - raid (priority=8.5, can_enter=false) npc=Goat 1319 state=raid priority=8.5 can_enter=false
[2026-02-16T13:25:35] [DEBUG] [NPC] Priority eval: Goat 1319 - reproduction (priority=8.0, can_enter=false) npc=Goat 1319 state=reproduction priority=8.0 can_enter=false
[2026-02-16T13:25:35] [DEBUG] [NPC] Priority eval: Goat 1319 - occupy_building (priority=7.5, can_enter=false) npc=Goat 1319 state=occupy_building priority=7.5 can_enter=false
[2026-02-16T13:25:35] [DEBUG] [NPC] Priority eval: Goat 1319 - work_at_building (priority=7.0, can_enter=false) npc=Goat 1319 state=work_at_building priority=7.0 can_enter=false
[2026-02-16T13:25:35] [DEBUG] [NPC] Can enter check: Goat 1319 cannot enter seek (no_target) npc=Goat 1319 state=seek can_enter=false reason=no_target
[2026-02-16T13:25:35] [DEBUG] [NPC] Priority eval: Goat 1319 - seek (priority=2.0, can_enter=false) npc=Goat 1319 state=seek priority=2.0 can_enter=false
[2026-02-16T13:25:35] [DEBUG] [NPC] Evaluated 8 states: agro(priority=15.0,can_enter=false) combat(priority=12.0,can_enter=false) herd(priority=11.0,can_enter=false) raid(priority=8.5,can_enter=false) reproduction(priority=8.0,can_enter=false) occupy_building(priority=7.5,can_enter=false) work_at_building(priority=7.0,can_enter=false) seek(priority=2.0,can_enter=false) -> Best: wander (priority=1.0) npc=Goat 1319 best_state=wander best_priority=1.0
[2026-02-16T13:25:35] [INFO] [INVENTORY] PlayerInventoryUI closed
Player inventory toggled: CLOSED
🔍 INVENTORY_UI: setup() called
   - inventory: <RefCounted#-9223371688744316937> (valid: true)
🔍 INVENTORY UI SETUP: Setting inventory_data from <RefCounted#-9223371688744316937> to <RefCounted#-9223371688744316937> (slot_count=6)
   - Calling _build_slots() deferred...
   - Calling _update_all_slots() deferred...
✅ INVENTORY_UI: setup() completed
DEBUG _update_title: is_corpse=false, land_claim=<null>, building=@Node2D@617:<Node2D#348009795497>
DEBUG _update_title: is_corpse=false, land_claim=<null>, building=@Node2D@617:<Node2D#348009795497>
🔵 Building inventory opened for Dairy Farm
[2026-02-16T13:25:35] [INFO] [INVENTORY] BuildingInventoryUI closed
DEBUG _update_title: is_corpse=false, land_claim=<null>, building=@Node2D@617:<Node2D#348009795497>
[Assign] Goat 1218 assign_success -> @Node2D@617 dist=2
[2026-02-16T13:25:36] [DEBUG] [NPC] Can enter check: WUEC cannot enter agro (not_caveman) npc=WUEC state=agro can_enter=false reason=not_caveman npc_type=woman
[2026-02-16T13:25:36] [DEBUG] [NPC] Priority eval: WUEC - agro (priority=15.0, can_enter=false) npc=WUEC state=agro priority=15.0 can_enter=false
[2026-02-16T13:25:36] [DEBUG] [NPC] Priority eval: WUEC - combat (priority=12.0, can_enter=false) npc=WUEC state=combat priority=12.0 can_enter=false
[2026-02-16T13:25:36] [DEBUG] [NPC] Can enter check: WUEC cannot enter herd (not_herded) npc=WUEC state=herd can_enter=false reason=not_herded herder=unknown
[2026-02-16T13:25:36] [DEBUG] [NPC] Priority eval: WUEC - herd (priority=11.0, can_enter=false) npc=WUEC state=herd priority=11.0 can_enter=false
[2026-02-16T13:25:36] [DEBUG] [NPC] Priority eval: WUEC - raid (priority=8.5, can_enter=false) npc=WUEC state=raid priority=8.5 can_enter=false
[2026-02-16T13:25:36] [DEBUG] [NPC] Priority eval: WUEC - reproduction (priority=8.0, can_enter=false) npc=WUEC state=reproduction priority=8.0 can_enter=false
[2026-02-16T13:25:36] [DEBUG] [NPC] Priority eval: WUEC - occupy_building (priority=7.5, can_enter=false) npc=WUEC state=occupy_building priority=7.5 can_enter=false
[2026-02-16T13:25:36] [DEBUG] [NPC] Priority eval: WUEC - work_at_building (priority=7.0, can_enter=false) npc=WUEC state=work_at_building priority=7.0 can_enter=false
[2026-02-16T13:25:36] [DEBUG] [NPC] Can enter check: WUEC cannot enter seek (no_target) npc=WUEC state=seek can_enter=false reason=no_target
[Assign] Goat 1218 add_animal_attempt -> @Node2D@617 dist=1 (enter_range=220)
[2026-02-16T13:25:36] [INFO] [INVENTORY] PlayerInventoryUI opened
Player inventory toggled: OPEN
🔍 INVENTORY_UI: setup() called
   - inventory: <RefCounted#-9223371688744316937> (valid: true)
🔍 INVENTORY UI SETUP: Setting inventory_data from <RefCounted#-9223371688744316937> to <RefCounted#-9223371688744316937> (slot_count=6)
   - Calling _build_slots() deferred...
   - Calling _update_all_slots() deferred...
✅ INVENTORY_UI: setup() completed
DEBUG _update_title: is_corpse=false, land_claim=<null>, building=@Node2D@617:<Node2D#348009795497>
DEBUG _update_title: is_corpse=false, land_claim=<null>, building=@Node2D@617:<Node2D#348009795497>
🔵 Building inventory opened for Dairy Farm
DEBUG _update_title: is_corpse=false, land_claim=<null>, building=@Node2D@617:<Node2D#348009795497>
🔍 BUILDING UI SHOW: inventory_data instance: <RefCounted#-9223371688744316937> (slot_count=6, can_stack=true)
🔍 BUILDING UI SHOW: Raw slots array: [<null>, <null>, <null>, <null>, <null>, <null>]
🔍 BUILDING UI SHOW: Slot 0: null
🔍 BUILDING UI SHOW: Slot 1: null
🔍 BUILDING UI SHOW: Slot 2: null
🔍 BUILDING UI SHOW: Slot 3: null
🔍 BUILDING UI SHOW: Slot 4: null
🔍 BUILDING UI SHOW: Slot 5: null
📦 LAND CLAIM INVENTORY: Total items: 0 | Breakdown: empty
[2026-02-16T13:25:36] [INFO] [INVENTORY] BuildingInventoryUI opened
DEBUG _update_title: is_corpse=false, land_claim=<null>, building=@Node2D@617:<Node2D#348009795497>
[Assign] Goat 1218 entry clan=OKOK assigned=false
[Assign] Goat 1218 assign_success -> @Node2D@617 dist=1
TASK SYSTEM LOGGER: Called at time 79.1
[2026-02-16T13:25:36] [INFO] [INVENTORY] === TASK SYSTEM LOG: 1 Land Claims ===
[2026-02-16T13:25:36] [INFO] [INVENTORY] LAND CLAIM: OKOK | Pos: (-1050, 689) | Inventory: empty clan_name=OKOK position=(-1049.549, 688.502) inventory=[]
[2026-02-16T13:25:36] [INFO] [INVENTORY] TASK SYSTEM DEBUG: buildings group=5, with building_type=4, ovens=0
[2026-02-16T13:25:36] [INFO] [INVENTORY] === TASK SYSTEM LOG: 0 Ovens ===
[2026-02-16T13:25:37] [DEBUG] [NPC] Can enter check: KUKO cannot enter agro (not_caveman) npc=KUKO state=agro can_enter=false reason=not_caveman npc_type=woman
[2026-02-16T13:25:37] [DEBUG] [NPC] Priority eval: KUKO - agro (priority=15.0, can_enter=false) npc=KUKO state=agro priority=15.0 can_enter=false
[2026-02-16T13:25:37] [DEBUG] [NPC] Priority eval: KUKO - combat (priority=12.0, can_enter=false) npc=KUKO state=combat priority=12.0 can_enter=false
[2026-02-16T13:25:37] [DEBUG] [NPC] Can enter check: KUKO cannot enter herd (not_herded) npc=KUKO state=herd can_enter=false reason=not_herded herder=unknown
[2026-02-16T13:25:37] [DEBUG] [NPC] Priority eval: KUKO - herd (priority=11.0, can_enter=false) npc=KUKO state=herd priority=11.0 can_enter=false
[2026-02-16T13:25:37] [DEBUG] [NPC] Priority eval: KUKO - raid (priority=8.5, can_enter=false) npc=KUKO state=raid priority=8.5 can_enter=false
[2026-02-16T13:25:37] [DEBUG] [NPC] Priority eval: KUKO - reproduction (priority=8.0, can_enter=false) npc=KUKO state=reproduction priority=8.0 can_enter=false
[2026-02-16T13:25:37] [DEBUG] [NPC] Priority eval: KUKO - occupy_building (priority=7.5, can_enter=false) npc=KUKO state=occupy_building priority=7.5 can_enter=false
[2026-02-16T13:25:37] [DEBUG] [NPC] Priority eval: KUKO - work_at_building (priority=7.0, can_enter=false) npc=KUKO state=work_at_building priority=7.0 can_enter=false
[2026-02-16T13:25:37] [DEBUG] [NPC] Can enter check: KUKO cannot enter seek (no_target) npc=KUKO state=seek can_enter=false reason=no_target
[2026-02-16T13:25:37] [INFO] [INVENTORY] BuildingInventoryUI closed
[Assign] Goat 1218 assign_success -> @Node2D@617 dist=1
[2026-02-16T13:25:38] [INFO] [NPC] POSITION: Sheep 1217 at (-433.4, -721.7), state=wander, distance_to_claim=0.0/400.0, velocity=47.6 npc=Sheep 1217 pos=-433.4,-721.7 state=wander distance_to_claim=0.0 claim_radius=400.0 velocity=47.6
[2026-02-16T13:25:38] [DEBUG] [NPC] Can enter check: Sheep 1217 cannot enter agro (not_caveman) npc=Sheep 1217 state=agro can_enter=false reason=not_caveman npc_type=sheep
[2026-02-16T13:25:38] [DEBUG] [NPC] Priority eval: Sheep 1217 - agro (priority=15.0, can_enter=false) npc=Sheep 1217 state=agro priority=15.0 can_enter=false
[2026-02-16T13:25:38] [DEBUG] [NPC] Priority eval: Sheep 1217 - combat (priority=12.0, can_enter=false) npc=Sheep 1217 state=combat priority=12.0 can_enter=false
[2026-02-16T13:25:38] [DEBUG] [NPC] Can enter check: Sheep 1217 cannot enter herd (not_herded) npc=Sheep 1217 state=herd can_enter=false reason=not_herded herder=unknown
[2026-02-16T13:25:38] [DEBUG] [NPC] Priority eval: Sheep 1217 - herd (priority=11.0, can_enter=false) npc=Sheep 1217 state=herd priority=11.0 can_enter=false
[2026-02-16T13:25:38] [DEBUG] [NPC] Priority eval: Sheep 1217 - raid (priority=8.5, can_enter=false) npc=Sheep 1217 state=raid priority=8.5 can_enter=false
[2026-02-16T13:25:38] [DEBUG] [NPC] Priority eval: Sheep 1217 - reproduction (priority=8.0, can_enter=false) npc=Sheep 1217 state=reproduction priority=8.0 can_enter=false
[2026-02-16T13:25:38] [DEBUG] [NPC] Priority eval: Sheep 1217 - occupy_building (priority=7.5, can_enter=false) npc=Sheep 1217 state=occupy_building priority=7.5 can_enter=false
[2026-02-16T13:25:38] [DEBUG] [NPC] Priority eval: Sheep 1217 - work_at_building (priority=7.0, can_enter=false) npc=Sheep 1217 state=work_at_building priority=7.0 can_enter=false
[Assign] Goat 1218 assign_success -> @Node2D@617 dist=1
[2026-02-16T13:25:38] [INFO] [INVENTORY] PlayerInventoryUI closed
Player inventory toggled: CLOSED
🔍 INVENTORY_UI: setup() called
   - inventory: <RefCounted#-9223371688744316937> (valid: true)
🔍 INVENTORY UI SETUP: Setting inventory_data from <RefCounted#-9223371688744316937> to <RefCounted#-9223371688744316937> (slot_count=6)
   - Calling _build_slots() deferred...
   - Calling _update_all_slots() deferred...
✅ INVENTORY_UI: setup() completed
DEBUG _update_title: is_corpse=false, land_claim=<null>, building=@Node2D@617:<Node2D#348009795497>
DEBUG _update_title: is_corpse=false, land_claim=<null>, building=@Node2D@617:<Node2D#348009795497>
🔵 Building inventory opened for Dairy Farm
[2026-02-16T13:25:38] [INFO] [INVENTORY] BuildingInventoryUI closed
DEBUG _update_title: is_corpse=false, land_claim=<null>, building=@Node2D@617:<Node2D#348009795497>
[Assign] Goat 1218 add_animal_attempt -> @Node2D@617 dist=1 (enter_range=220)
[ASSIGN] Goat 1218 ClaimBuildingIndex returned 4 buildings for claim OKOK
[Assign] Goat 1218 assign_success -> @Node2D@617 dist=1
[2026-02-16T13:25:39] [INFO] [NPC] POSITION: BAHI at (303.4, -85.3), state=wander, distance_to_claim=0.0/400.0, velocity=21.2 npc=BAHI pos=303.4,-85.3 state=wander distance_to_claim=0.0 claim_radius=400.0 velocity=21.2
[2026-02-16T13:25:39] [DEBUG] [NPC] Can enter check: BAHI cannot enter agro (not_caveman) npc=BAHI state=agro can_enter=false reason=not_caveman npc_type=woman
[2026-02-16T13:25:39] [DEBUG] [NPC] Priority eval: BAHI - agro (priority=15.0, can_enter=false) npc=BAHI state=agro priority=15.0 can_enter=false
[2026-02-16T13:25:39] [DEBUG] [NPC] Priority eval: BAHI - combat (priority=12.0, can_enter=false) npc=BAHI state=combat priority=12.0 can_enter=false
[2026-02-16T13:25:39] [DEBUG] [NPC] Can enter check: BAHI cannot enter herd (not_herded) npc=BAHI state=herd can_enter=false reason=not_herded herder=unknown
[2026-02-16T13:25:39] [DEBUG] [NPC] Priority eval: BAHI - herd (priority=11.0, can_enter=false) npc=BAHI state=herd priority=11.0 can_enter=false
[2026-02-16T13:25:39] [DEBUG] [NPC] Priority eval: BAHI - raid (priority=8.5, can_enter=false) npc=BAHI state=raid priority=8.5 can_enter=false
[2026-02-16T13:25:39] [DEBUG] [NPC] Priority eval: BAHI - reproduction (priority=8.0, can_enter=false) npc=BAHI state=reproduction priority=8.0 can_enter=false
[2026-02-16T13:25:39] [DEBUG] [NPC] Priority eval: BAHI - occupy_building (priority=7.5, can_enter=false) npc=BAHI state=occupy_building priority=7.5 can_enter=false
[2026-02-16T13:25:39] [DEBUG] [NPC] Priority eval: BAHI - work_at_building (priority=7.0, can_enter=false) npc=BAHI state=work_at_building priority=7.0 can_enter=false
TASK SYSTEM LOGGER: Called at time 82.1
[2026-02-16T13:25:39] [INFO] [INVENTORY] === TASK SYSTEM LOG: 1 Land Claims ===
[2026-02-16T13:25:39] [INFO] [INVENTORY] LAND CLAIM: OKOK | Pos: (-1050, 689) | Inventory: empty clan_name=OKOK position=(-1049.549, 688.502) inventory=[]
[2026-02-16T13:25:39] [INFO] [INVENTORY] TASK SYSTEM DEBUG: buildings group=5, with building_type=4, ovens=0
[2026-02-16T13:25:39] [INFO] [INVENTORY] === TASK SYSTEM LOG: 0 Ovens ===
[Assign] Goat 1218 assign_success -> @Node2D@617 dist=1
[2026-02-16T13:25:40] [DEBUG] [NPC] Can enter check: JOEC cannot enter agro (not_caveman) npc=JOEC state=agro can_enter=false reason=not_caveman npc_type=woman
[2026-02-16T13:25:40] [DEBUG] [NPC] Priority eval: JOEC - agro (priority=15.0, can_enter=false) npc=JOEC state=agro priority=15.0 can_enter=false
[2026-02-16T13:25:40] [DEBUG] [NPC] Priority eval: JOEC - combat (priority=12.0, can_enter=false) npc=JOEC state=combat priority=12.0 can_enter=false
[2026-02-16T13:25:40] [DEBUG] [NPC] Can enter check: JOEC cannot enter herd (not_herded) npc=JOEC state=herd can_enter=false reason=not_herded herder=unknown
[2026-02-16T13:25:40] [DEBUG] [NPC] Priority eval: JOEC - herd (priority=11.0, can_enter=false) npc=JOEC state=herd priority=11.0 can_enter=false
[2026-02-16T13:25:40] [DEBUG] [NPC] Priority eval: JOEC - raid (priority=8.5, can_enter=false) npc=JOEC state=raid priority=8.5 can_enter=false
[2026-02-16T13:25:40] [DEBUG] [NPC] Priority eval: JOEC - reproduction (priority=8.0, can_enter=false) npc=JOEC state=reproduction priority=8.0 can_enter=false
[2026-02-16T13:25:40] [DEBUG] [NPC] Priority eval: JOEC - occupy_building (priority=7.5, can_enter=false) npc=JOEC state=occupy_building priority=7.5 can_enter=false
[2026-02-16T13:25:40] [DEBUG] [NPC] Priority eval: JOEC - work_at_building (priority=7.0, can_enter=false) npc=JOEC state=work_at_building priority=7.0 can_enter=false
[2026-02-16T13:25:40] [DEBUG] [NPC] Can enter check: JOEC cannot enter seek (no_target) npc=JOEC state=seek can_enter=false reason=no_target
[Assign] Goat 1218 assign_success -> @Node2D@617 dist=1
[Assign] Goat 1218 add_animal_attempt -> @Node2D@617 dist=1 (enter_range=220)
[2026-02-16T13:25:41] [DEBUG] [NPC] Can enter check: Goat 1218 cannot enter herd (not_herded) npc=Goat 1218 state=herd can_enter=false reason=not_herded herder=unknown
[2026-02-16T13:25:41] [DEBUG] [NPC] Priority eval: Goat 1218 - herd (priority=15.0, can_enter=false) npc=Goat 1218 state=herd priority=15.0 can_enter=false
[2026-02-16T13:25:41] [DEBUG] [NPC] Can enter check: Goat 1218 cannot enter agro (not_caveman) npc=Goat 1218 state=agro can_enter=false reason=not_caveman npc_type=goat
[2026-02-16T13:25:41] [DEBUG] [NPC] Priority eval: Goat 1218 - agro (priority=15.0, can_enter=false) npc=Goat 1218 state=agro priority=15.0 can_enter=false
[2026-02-16T13:25:41] [DEBUG] [NPC] Priority eval: Goat 1218 - combat (priority=12.0, can_enter=false) npc=Goat 1218 state=combat priority=12.0 can_enter=false
[2026-02-16T13:25:41] [DEBUG] [NPC] Priority eval: Goat 1218 - work_at_building (priority=9.0, can_enter=false) npc=Goat 1218 state=work_at_building priority=9.0 can_enter=false
[2026-02-16T13:25:41] [DEBUG] [NPC] Priority eval: Goat 1218 - raid (priority=8.5, can_enter=false) npc=Goat 1218 state=raid priority=8.5 can_enter=false
[2026-02-16T13:25:41] [DEBUG] [NPC] Priority eval: Goat 1218 - reproduction (priority=8.0, can_enter=false) npc=Goat 1218 state=reproduction priority=8.0 can_enter=false
[2026-02-16T13:25:41] [DEBUG] [NPC] Priority eval: Goat 1218 - occupy_building (priority=7.5, can_enter=false) npc=Goat 1218 state=occupy_building priority=7.5 can_enter=false
[2026-02-16T13:25:41] [DEBUG] [NPC] Can enter check: Goat 1218 cannot enter seek (no_target) npc=Goat 1218 state=seek can_enter=false reason=no_target
[Assign] Goat 1218 assign_success -> @Node2D@617 dist=2
[Assign] Goat 1218 entry clan=OKOK assigned=true
[2026-02-16T13:25:42] [DEBUG] [NPC] Can enter check: Sheep 1217 cannot enter agro (not_caveman) npc=Sheep 1217 state=agro can_enter=false reason=not_caveman npc_type=sheep
[2026-02-16T13:25:42] [DEBUG] [NPC] Priority eval: Sheep 1217 - agro (priority=15.0, can_enter=false) npc=Sheep 1217 state=agro priority=15.0 can_enter=false
[2026-02-16T13:25:42] [DEBUG] [NPC] Priority eval: Sheep 1217 - combat (priority=12.0, can_enter=false) npc=Sheep 1217 state=combat priority=12.0 can_enter=false
[2026-02-16T13:25:42] [DEBUG] [NPC] Can enter check: Sheep 1217 cannot enter herd (not_herded) npc=Sheep 1217 state=herd can_enter=false reason=not_herded herder=unknown
[2026-02-16T13:25:42] [DEBUG] [NPC] Priority eval: Sheep 1217 - herd (priority=11.0, can_enter=false) npc=Sheep 1217 state=herd priority=11.0 can_enter=false
[2026-02-16T13:25:42] [DEBUG] [NPC] Priority eval: Sheep 1217 - raid (priority=8.5, can_enter=false) npc=Sheep 1217 state=raid priority=8.5 can_enter=false
[2026-02-16T13:25:42] [DEBUG] [NPC] Priority eval: Sheep 1217 - reproduction (priority=8.0, can_enter=false) npc=Sheep 1217 state=reproduction priority=8.0 can_enter=false
[2026-02-16T13:25:42] [DEBUG] [NPC] Priority eval: Sheep 1217 - occupy_building (priority=7.5, can_enter=false) npc=Sheep 1217 state=occupy_building priority=7.5 can_enter=false
[2026-02-16T13:25:42] [DEBUG] [NPC] Priority eval: Sheep 1217 - work_at_building (priority=7.0, can_enter=false) npc=Sheep 1217 state=work_at_building priority=7.0 can_enter=false
[2026-02-16T13:25:42] [DEBUG] [NPC] Can enter check: Sheep 1217 cannot enter seek (no_target) npc=Sheep 1217 state=seek can_enter=false reason=no_target
[Assign] Goat 1218 assign_success -> @Node2D@617 dist=1
TASK SYSTEM LOGGER: Called at time 85.1
[2026-02-16T13:25:42] [INFO] [INVENTORY] === TASK SYSTEM LOG: 1 Land Claims ===
[2026-02-16T13:25:42] [INFO] [INVENTORY] LAND CLAIM: OKOK | Pos: (-1050, 689) | Inventory: empty clan_name=OKOK position=(-1049.549, 688.502) inventory=[]
[2026-02-16T13:25:42] [INFO] [INVENTORY] TASK SYSTEM DEBUG: buildings group=5, with building_type=4, ovens=0
[2026-02-16T13:25:42] [INFO] [INVENTORY] === TASK SYSTEM LOG: 0 Ovens ===
[Assign] Goat 1218 assign_success -> @Node2D@617 dist=2
[2026-02-16T13:25:43] [DEBUG] [NPC] Can enter check: Sheep 1418 cannot enter agro (not_caveman) npc=Sheep 1418 state=agro can_enter=false reason=not_caveman npc_type=sheep
[2026-02-16T13:25:43] [DEBUG] [NPC] Priority eval: Sheep 1418 - agro (priority=15.0, can_enter=false) npc=Sheep 1418 state=agro priority=15.0 can_enter=false
[2026-02-16T13:25:43] [DEBUG] [NPC] Priority eval: Sheep 1418 - combat (priority=12.0, can_enter=false) npc=Sheep 1418 state=combat priority=12.0 can_enter=false
[2026-02-16T13:25:43] [DEBUG] [NPC] Can enter check: Sheep 1418 cannot enter herd (not_herded) npc=Sheep 1418 state=herd can_enter=false reason=not_herded herder=unknown
[2026-02-16T13:25:43] [DEBUG] [NPC] Priority eval: Sheep 1418 - herd (priority=11.0, can_enter=false) npc=Sheep 1418 state=herd priority=11.0 can_enter=false
[2026-02-16T13:25:43] [DEBUG] [NPC] Priority eval: Sheep 1418 - raid (priority=8.5, can_enter=false) npc=Sheep 1418 state=raid priority=8.5 can_enter=false
[2026-02-16T13:25:43] [DEBUG] [NPC] Priority eval: Sheep 1418 - reproduction (priority=8.0, can_enter=false) npc=Sheep 1418 state=reproduction priority=8.0 can_enter=false
[2026-02-16T13:25:43] [DEBUG] [NPC] Priority eval: Sheep 1418 - occupy_building (priority=7.5, can_enter=false) npc=Sheep 1418 state=occupy_building priority=7.5 can_enter=false
[2026-02-16T13:25:43] [DEBUG] [NPC] Priority eval: Sheep 1418 - work_at_building (priority=7.0, can_enter=false) npc=Sheep 1418 state=work_at_building priority=7.0 can_enter=false
[2026-02-16T13:25:43] [DEBUG] [NPC] Can enter check: Sheep 1418 cannot enter seek (no_target) npc=Sheep 1418 state=seek can_enter=false reason=no_target
[Assign] Goat 1218 add_animal_attempt -> @Node2D@617 dist=1 (enter_range=220)
[Assign] Goat 1218 assign_success -> @Node2D@617 dist=0
[2026-02-16T13:25:44] [DEBUG] [NPC] Can enter check: WUEC cannot enter agro (not_caveman) npc=WUEC state=agro can_enter=false reason=not_caveman npc_type=woman
[2026-02-16T13:25:44] [DEBUG] [NPC] Priority eval: WUEC - agro (priority=15.0, can_enter=false) npc=WUEC state=agro priority=15.0 can_enter=false
[2026-02-16T13:25:44] [DEBUG] [NPC] Priority eval: WUEC - combat (priority=12.0, can_enter=false) npc=WUEC state=combat priority=12.0 can_enter=false
[2026-02-16T13:25:44] [DEBUG] [NPC] Can enter check: WUEC cannot enter herd (not_herded) npc=WUEC state=herd can_enter=false reason=not_herded herder=unknown
[2026-02-16T13:25:44] [DEBUG] [NPC] Priority eval: WUEC - herd (priority=11.0, can_enter=false) npc=WUEC state=herd priority=11.0 can_enter=false
[2026-02-16T13:25:44] [DEBUG] [NPC] Priority eval: WUEC - raid (priority=8.5, can_enter=false) npc=WUEC state=raid priority=8.5 can_enter=false
[2026-02-16T13:25:44] [DEBUG] [NPC] Priority eval: WUEC - reproduction (priority=8.0, can_enter=false) npc=WUEC state=reproduction priority=8.0 can_enter=false
[2026-02-16T13:25:44] [DEBUG] [NPC] Priority eval: WUEC - occupy_building (priority=7.5, can_enter=false) npc=WUEC state=occupy_building priority=7.5 can_enter=false
[2026-02-16T13:25:44] [DEBUG] [NPC] Priority eval: WUEC - work_at_building (priority=7.0, can_enter=false) npc=WUEC state=work_at_building priority=7.0 can_enter=false
[2026-02-16T13:25:44] [DEBUG] [NPC] Can enter check: WUEC cannot enter seek (no_target) npc=WUEC state=seek can_enter=false reason=no_target
🚨 HIGH PRIORITY FOLLOW: WUYA immediately entered herd state (following Player)
[ASSIGN] Goat 1218 ClaimBuildingIndex returned 4 buildings for claim OKOK
[Assign] Goat 1218 assign_success -> @Node2D@617 dist=0
[2026-02-16T13:25:45] [DEBUG] [NPC] Can enter check: DEIS cannot enter agro (not_caveman) npc=DEIS state=agro can_enter=false reason=not_caveman npc_type=woman
[2026-02-16T13:25:45] [DEBUG] [NPC] Priority eval: DEIS - agro (priority=15.0, can_enter=false) npc=DEIS state=agro priority=15.0 can_enter=false
[2026-02-16T13:25:45] [DEBUG] [NPC] Priority eval: DEIS - combat (priority=12.0, can_enter=false) npc=DEIS state=combat priority=12.0 can_enter=false
[2026-02-16T13:25:45] [DEBUG] [NPC] Can enter check: DEIS cannot enter herd (not_herded) npc=DEIS state=herd can_enter=false reason=not_herded herder=unknown
[2026-02-16T13:25:45] [DEBUG] [NPC] Priority eval: DEIS - herd (priority=11.0, can_enter=false) npc=DEIS state=herd priority=11.0 can_enter=false
[2026-02-16T13:25:45] [DEBUG] [NPC] Priority eval: DEIS - raid (priority=8.5, can_enter=false) npc=DEIS state=raid priority=8.5 can_enter=false
[2026-02-16T13:25:45] [DEBUG] [NPC] Priority eval: DEIS - reproduction (priority=8.0, can_enter=false) npc=DEIS state=reproduction priority=8.0 can_enter=false
[2026-02-16T13:25:45] [DEBUG] [NPC] Priority eval: DEIS - occupy_building (priority=7.5, can_enter=false) npc=DEIS state=occupy_building priority=7.5 can_enter=false
[2026-02-16T13:25:45] [DEBUG] [NPC] Priority eval: DEIS - work_at_building (priority=7.0, can_enter=false) npc=DEIS state=work_at_building priority=7.0 can_enter=false
[2026-02-16T13:25:45] [DEBUG] [NPC] Can enter check: DEIS cannot enter seek (no_target) npc=DEIS state=seek can_enter=false reason=no_target
[Assign] Goat 1218 assign_success -> @Node2D@617 dist=0
TASK SYSTEM LOGGER: Called at time 88.1
[2026-02-16T13:25:45] [INFO] [INVENTORY] === TASK SYSTEM LOG: 1 Land Claims ===
[2026-02-16T13:25:45] [INFO] [INVENTORY] LAND CLAIM: OKOK | Pos: (-1050, 689) | Inventory: empty clan_name=OKOK position=(-1049.549, 688.502) inventory=[]
[2026-02-16T13:25:45] [INFO] [INVENTORY] TASK SYSTEM DEBUG: buildings group=5, with building_type=4, ovens=0
[2026-02-16T13:25:45] [INFO] [INVENTORY] === TASK SYSTEM LOG: 0 Ovens ===
[Assign] Goat 1218 add_animal_attempt -> @Node2D@617 dist=0 (enter_range=220)
[2026-02-16T13:25:46] [DEBUG] [NPC] Can enter check: PUIK cannot enter agro (not_caveman) npc=PUIK state=agro can_enter=false reason=not_caveman npc_type=woman
[2026-02-16T13:25:46] [DEBUG] [NPC] Priority eval: PUIK - agro (priority=15.0, can_enter=false) npc=PUIK state=agro priority=15.0 can_enter=false
[2026-02-16T13:25:46] [DEBUG] [NPC] Priority eval: PUIK - combat (priority=12.0, can_enter=false) npc=PUIK state=combat priority=12.0 can_enter=false
[2026-02-16T13:25:46] [DEBUG] [NPC] Can enter check: PUIK cannot enter herd (not_herded) npc=PUIK state=herd can_enter=false reason=not_herded herder=unknown
[2026-02-16T13:25:46] [DEBUG] [NPC] Priority eval: PUIK - herd (priority=11.0, can_enter=false) npc=PUIK state=herd priority=11.0 can_enter=false
[2026-02-16T13:25:46] [DEBUG] [NPC] Priority eval: PUIK - raid (priority=8.5, can_enter=false) npc=PUIK state=raid priority=8.5 can_enter=false
[2026-02-16T13:25:46] [DEBUG] [NPC] Priority eval: PUIK - reproduction (priority=8.0, can_enter=false) npc=PUIK state=reproduction priority=8.0 can_enter=false
[2026-02-16T13:25:46] [DEBUG] [NPC] Priority eval: PUIK - occupy_building (priority=7.5, can_enter=false) npc=PUIK state=occupy_building priority=7.5 can_enter=false
[2026-02-16T13:25:46] [DEBUG] [NPC] Priority eval: PUIK - work_at_building (priority=7.0, can_enter=false) npc=PUIK state=work_at_building priority=7.0 can_enter=false
[2026-02-16T13:25:46] [DEBUG] [NPC] Can enter check: PUIK cannot enter seek (no_target) npc=PUIK state=seek can_enter=false reason=no_target
[Assign] Goat 1218 assign_success -> @Node2D@617 dist=0
[Assign] Goat 1218 entry clan=OKOK assigned=false
[Assign] Goat 1218 assign_success -> @Node2D@617 dist=0
[2026-02-16T13:25:47] [DEBUG] [NPC] Can enter check: JOEC cannot enter agro (not_caveman) npc=JOEC state=agro can_enter=false reason=not_caveman npc_type=woman
[2026-02-16T13:25:47] [DEBUG] [NPC] Priority eval: JOEC - agro (priority=15.0, can_enter=false) npc=JOEC state=agro priority=15.0 can_enter=false
[2026-02-16T13:25:47] [DEBUG] [NPC] Priority eval: JOEC - combat (priority=12.0, can_enter=false) npc=JOEC state=combat priority=12.0 can_enter=false
[2026-02-16T13:25:47] [DEBUG] [NPC] Can enter check: JOEC cannot enter herd (not_herded) npc=JOEC state=herd can_enter=false reason=not_herded herder=unknown
[2026-02-16T13:25:47] [DEBUG] [NPC] Priority eval: JOEC - herd (priority=11.0, can_enter=false) npc=JOEC state=herd priority=11.0 can_enter=false
[2026-02-16T13:25:47] [DEBUG] [NPC] Priority eval: JOEC - raid (priority=8.5, can_enter=false) npc=JOEC state=raid priority=8.5 can_enter=false
[2026-02-16T13:25:47] [DEBUG] [NPC] Priority eval: JOEC - reproduction (priority=8.0, can_enter=false) npc=JOEC state=reproduction priority=8.0 can_enter=false
[2026-02-16T13:25:47] [DEBUG] [NPC] Priority eval: JOEC - occupy_building (priority=7.5, can_enter=false) npc=JOEC state=occupy_building priority=7.5 can_enter=false
[2026-02-16T13:25:47] [DEBUG] [NPC] Priority eval: JOEC - work_at_building (priority=7.0, can_enter=false) npc=JOEC state=work_at_building priority=7.0 can_enter=false
[2026-02-16T13:25:47] [DEBUG] [NPC] Can enter check: JOEC cannot enter seek (no_target) npc=JOEC state=seek can_enter=false reason=no_target
[2026-02-16T13:25:48] [WARNING] [NPC] NPC lost herder Player (outside perception range: 300.8 >= 300.0) npc=WUYA leader=Player distance=300.8 max_distance=300.0
🏠 WUYA: Herd cleared (no longer following)
[Assign] Goat 1218 assign_success -> @Node2D@617 dist=0
[2026-02-16T13:25:48] [DEBUG] [NPC] Can enter check: Goat 1218 cannot enter herd (not_herded) npc=Goat 1218 state=herd can_enter=false reason=not_herded herder=unknown
[2026-02-16T13:25:48] [DEBUG] [NPC] Priority eval: Goat 1218 - herd (priority=15.0, can_enter=false) npc=Goat 1218 state=herd priority=15.0 can_enter=false
[2026-02-16T13:25:48] [DEBUG] [NPC] Can enter check: Goat 1218 cannot enter agro (not_caveman) npc=Goat 1218 state=agro can_enter=false reason=not_caveman npc_type=goat
[2026-02-16T13:25:48] [DEBUG] [NPC] Priority eval: Goat 1218 - agro (priority=15.0, can_enter=false) npc=Goat 1218 state=agro priority=15.0 can_enter=false
[2026-02-16T13:25:48] [DEBUG] [NPC] Priority eval: Goat 1218 - combat (priority=12.0, can_enter=false) npc=Goat 1218 state=combat priority=12.0 can_enter=false
[2026-02-16T13:25:48] [DEBUG] [NPC] Priority eval: Goat 1218 - work_at_building (priority=9.0, can_enter=false) npc=Goat 1218 state=work_at_building priority=9.0 can_enter=false
[2026-02-16T13:25:48] [DEBUG] [NPC] Priority eval: Goat 1218 - raid (priority=8.5, can_enter=false) npc=Goat 1218 state=raid priority=8.5 can_enter=false
[2026-02-16T13:25:48] [DEBUG] [NPC] Priority eval: Goat 1218 - reproduction (priority=8.0, can_enter=false) npc=Goat 1218 state=reproduction priority=8.0 can_enter=false
[2026-02-16T13:25:48] [DEBUG] [NPC] Priority eval: Goat 1218 - occupy_building (priority=7.5, can_enter=false) npc=Goat 1218 state=occupy_building priority=7.5 can_enter=false
[2026-02-16T13:25:48] [DEBUG] [NPC] Can enter check: Goat 1218 cannot enter seek (no_target) npc=Goat 1218 state=seek can_enter=false reason=no_target
[Assign] Goat 1218 add_animal_attempt -> @Node2D@617 dist=0 (enter_range=220)
TASK SYSTEM LOGGER: Called at time 91.1
[2026-02-16T13:25:48] [INFO] [INVENTORY] === TASK SYSTEM LOG: 1 Land Claims ===
[2026-02-16T13:25:48] [INFO] [INVENTORY] LAND CLAIM: OKOK | Pos: (-1050, 689) | Inventory: empty clan_name=OKOK position=(-1049.549, 688.502) inventory=[]
[2026-02-16T13:25:48] [INFO] [INVENTORY] TASK SYSTEM DEBUG: buildings group=5, with building_type=4, ovens=0
[2026-02-16T13:25:48] [INFO] [INVENTORY] === TASK SYSTEM LOG: 0 Ovens ===
🎨 ANIMATION: _load_attack_sprite_sheet() called
🎨 ANIMATION: Loading sprite sheet from: res://assets/sprites/swingclub.png
✅ ANIMATION: Sprite sheet loaded successfully
🎨 ANIMATION: Texture dimensions - width=840, height=560
✅ ANIMATION: Frame size: 280x280 (grid 3x2)
✅ ANIMATION: Default sprite texture stored
FSM: Creating states for VIIB - idle:OK wander:OK seek:OK eat:OK gather:OK herd:OK herd_wildnpc:OK agro:OK build:OK
FSM: Successfully created eat state for VIIB
FSM: Successfully created gather state for VIIB
FSM: Successfully created herd state for VIIB
FSM: Successfully created herd_wildnpc state for VIIB
FSM: Successfully created agro state for VIIB
FSM: Successfully created combat state for VIIB
FSM: Successfully created defend state for VIIB
FSM: Successfully created raid state for VIIB
FSM: Successfully created search state for VIIB
FSM: Successfully created build state for VIIB
FSM: Successfully created reproduction state for VIIB
FSM: Successfully created occupy_building state for VIIB
FSM: Successfully created work_at_building state for VIIB
FSM: Successfully created craft state for VIIB
Task System: Created TaskRunner component for VIIB
✓ Respawned Wild Woman: VIIB at (-1341.546, 1108.636) (agility 9.0 = 288.0 speed)
[Assign] Goat 1218 assign_success -> @Node2D@617 dist=1
[2026-02-16T13:25:49] [DEBUG] [NPC] Can enter check: KUKO cannot enter agro (not_caveman) npc=KUKO state=agro can_enter=false reason=not_caveman npc_type=woman
[2026-02-16T13:25:49] [DEBUG] [NPC] Priority eval: KUKO - agro (priority=15.0, can_enter=false) npc=KUKO state=agro priority=15.0 can_enter=false
[2026-02-16T13:25:49] [DEBUG] [NPC] Priority eval: KUKO - combat (priority=12.0, can_enter=false) npc=KUKO state=combat priority=12.0 can_enter=false
[2026-02-16T13:25:49] [DEBUG] [NPC] Can enter check: KUKO cannot enter herd (not_herded) npc=KUKO state=herd can_enter=false reason=not_herded herder=unknown
[2026-02-16T13:25:49] [DEBUG] [NPC] Priority eval: KUKO - herd (priority=11.0, can_enter=false) npc=KUKO state=herd priority=11.0 can_enter=false
[2026-02-16T13:25:49] [DEBUG] [NPC] Priority eval: KUKO - raid (priority=8.5, can_enter=false) npc=KUKO state=raid priority=8.5 can_enter=false
[2026-02-16T13:25:49] [DEBUG] [NPC] Priority eval: KUKO - reproduction (priority=8.0, can_enter=false) npc=KUKO state=reproduction priority=8.0 can_enter=false
[2026-02-16T13:25:49] [DEBUG] [NPC] Priority eval: KUKO - occupy_building (priority=7.5, can_enter=false) npc=KUKO state=occupy_building priority=7.5 can_enter=false
[2026-02-16T13:25:49] [DEBUG] [NPC] Priority eval: KUKO - work_at_building (priority=7.0, can_enter=false) npc=KUKO state=work_at_building priority=7.0 can_enter=false
[2026-02-16T13:25:49] [DEBUG] [NPC] Can enter check: KUKO cannot enter seek (no_target) npc=KUKO state=seek can_enter=false reason=no_target
🚨 HIGH PRIORITY FOLLOW: WUYA immediately entered herd state (following Player)
[Assign] Goat 1218 assign_success -> @Node2D@617 dist=0
[2026-02-16T13:25:50] [WARNING] [NPC] STATE_DURATION: VIIB in wander for 92.5s (LONG - potentially stuck!) npc=VIIB state=wander duration_s=92.5 warning=potentially_stuck
[2026-02-16T13:25:50] [DEBUG] [NPC] Priority eval: XIUF - raid (priority=8.5, can_enter=false) npc=XIUF state=raid priority=8.5 can_enter=false
[2026-02-16T13:25:50] [DEBUG] [NPC] Priority eval: XIUF - reproduction (priority=8.0, can_enter=false) npc=XIUF state=reproduction priority=8.0 can_enter=false
[2026-02-16T13:25:50] [DEBUG] [NPC] Priority eval: XIUF - occupy_building (priority=7.5, can_enter=false) npc=XIUF state=occupy_building priority=7.5 can_enter=false
[2026-02-16T13:25:50] [DEBUG] [NPC] Priority eval: XIUF - work_at_building (priority=7.0, can_enter=false) npc=XIUF state=work_at_building priority=7.0 can_enter=false
[2026-02-16T13:25:50] [DEBUG] [NPC] Can enter check: XIUF cannot enter seek (no_target) npc=XIUF state=seek can_enter=false reason=no_target
[2026-02-16T13:25:50] [DEBUG] [NPC] Priority eval: XIUF - seek (priority=2.0, can_enter=false) npc=XIUF state=seek priority=2.0 can_enter=false
[2026-02-16T13:25:50] [DEBUG] [NPC] Evaluated 8 states: agro(priority=15.0,can_enter=false) combat(priority=12.0,can_enter=false) herd(priority=11.0,can_enter=false) raid(priority=8.5,can_enter=false) reproduction(priority=8.0,can_enter=false) occupy_building(priority=7.5,can_enter=false) work_at_building(priority=7.0,can_enter=false) seek(priority=2.0,can_enter=false) -> Best: wander (priority=1.0) npc=XIUF best_state=wander best_priority=1.0
[2026-02-16T13:25:50] [DEBUG] [NPC] Can enter check: Goat 1419 cannot enter agro (not_caveman) npc=Goat 1419 state=agro can_enter=false reason=not_caveman npc_type=goat
[2026-02-16T13:25:50] [DEBUG] [NPC] Priority eval: Goat 1419 - agro (priority=15.0, can_enter=false) npc=Goat 1419 state=agro priority=15.0 can_enter=false
[2026-02-16T13:25:50] [DEBUG] [NPC] Priority eval: Goat 1419 - combat (priority=12.0, can_enter=false) npc=Goat 1419 state=combat priority=12.0 can_enter=false
[ASSIGN] Goat 1218 ClaimBuildingIndex returned 4 buildings for claim OKOK
[Assign] Goat 1218 assign_success -> @Node2D@617 dist=2
[Assign] Goat 1218 add_animal_attempt -> @Node2D@617 dist=2 (enter_range=220)
[Assign] Goat 1218 assign_success -> @Node2D@617 dist=2
[2026-02-16T13:25:51] [INFO] [NPC] POSITION: Goat 1319 at (801.8, -549.0), state=wander, distance_to_claim=0.0/400.0, velocity=56.9 npc=Goat 1319 pos=801.8,-549.0 state=wander distance_to_claim=0.0 claim_radius=400.0 velocity=56.9
[2026-02-16T13:25:51] [DEBUG] [NPC] Can enter check: Goat 1319 cannot enter agro (not_caveman) npc=Goat 1319 state=agro can_enter=false reason=not_caveman npc_type=goat
[2026-02-16T13:25:51] [DEBUG] [NPC] Priority eval: Goat 1319 - agro (priority=15.0, can_enter=false) npc=Goat 1319 state=agro priority=15.0 can_enter=false
[2026-02-16T13:25:51] [DEBUG] [NPC] Priority eval: Goat 1319 - combat (priority=12.0, can_enter=false) npc=Goat 1319 state=combat priority=12.0 can_enter=false
[2026-02-16T13:25:51] [DEBUG] [NPC] Can enter check: Goat 1319 cannot enter herd (not_herded) npc=Goat 1319 state=herd can_enter=false reason=not_herded herder=unknown
[2026-02-16T13:25:51] [DEBUG] [NPC] Priority eval: Goat 1319 - herd (priority=11.0, can_enter=false) npc=Goat 1319 state=herd priority=11.0 can_enter=false
[2026-02-16T13:25:51] [DEBUG] [NPC] Priority eval: Goat 1319 - raid (priority=8.5, can_enter=false) npc=Goat 1319 state=raid priority=8.5 can_enter=false
[2026-02-16T13:25:51] [DEBUG] [NPC] Priority eval: Goat 1319 - reproduction (priority=8.0, can_enter=false) npc=Goat 1319 state=reproduction priority=8.0 can_enter=false
[2026-02-16T13:25:51] [DEBUG] [NPC] Priority eval: Goat 1319 - occupy_building (priority=7.5, can_enter=false) npc=Goat 1319 state=occupy_building priority=7.5 can_enter=false
[2026-02-16T13:25:51] [DEBUG] [NPC] Priority eval: Goat 1319 - work_at_building (priority=7.0, can_enter=false) npc=Goat 1319 state=work_at_building priority=7.0 can_enter=false
TASK SYSTEM LOGGER: Called at time 94.1
[2026-02-16T13:25:51] [INFO] [INVENTORY] === TASK SYSTEM LOG: 1 Land Claims ===
[2026-02-16T13:25:51] [INFO] [INVENTORY] LAND CLAIM: OKOK | Pos: (-1050, 689) | Inventory: empty clan_name=OKOK position=(-1049.549, 688.502) inventory=[]
[2026-02-16T13:25:51] [INFO] [INVENTORY] TASK SYSTEM DEBUG: buildings group=5, with building_type=4, ovens=0
[2026-02-16T13:25:51] [INFO] [INVENTORY] === TASK SYSTEM LOG: 0 Ovens ===
[Assign] Goat 1218 assign_success -> @Node2D@617 dist=2
[2026-02-16T13:25:52] [DEBUG] [NPC] Can enter check: Sheep 1319 cannot enter agro (not_caveman) npc=Sheep 1319 state=agro can_enter=false reason=not_caveman npc_type=sheep
[2026-02-16T13:25:52] [DEBUG] [NPC] Priority eval: Sheep 1319 - agro (priority=15.0, can_enter=false) npc=Sheep 1319 state=agro priority=15.0 can_enter=false
[2026-02-16T13:25:52] [DEBUG] [NPC] Priority eval: Sheep 1319 - combat (priority=12.0, can_enter=false) npc=Sheep 1319 state=combat priority=12.0 can_enter=false
[2026-02-16T13:25:52] [DEBUG] [NPC] Can enter check: Sheep 1319 cannot enter herd (not_herded) npc=Sheep 1319 state=herd can_enter=false reason=not_herded herder=unknown
[2026-02-16T13:25:52] [DEBUG] [NPC] Priority eval: Sheep 1319 - herd (priority=11.0, can_enter=false) npc=Sheep 1319 state=herd priority=11.0 can_enter=false
[2026-02-16T13:25:52] [DEBUG] [NPC] Priority eval: Sheep 1319 - raid (priority=8.5, can_enter=false) npc=Sheep 1319 state=raid priority=8.5 can_enter=false
[2026-02-16T13:25:52] [DEBUG] [NPC] Priority eval: Sheep 1319 - reproduction (priority=8.0, can_enter=false) npc=Sheep 1319 state=reproduction priority=8.0 can_enter=false
[2026-02-16T13:25:52] [DEBUG] [NPC] Priority eval: Sheep 1319 - occupy_building (priority=7.5, can_enter=false) npc=Sheep 1319 state=occupy_building priority=7.5 can_enter=false
[2026-02-16T13:25:52] [DEBUG] [NPC] Priority eval: Sheep 1319 - work_at_building (priority=7.0, can_enter=false) npc=Sheep 1319 state=work_at_building priority=7.0 can_enter=false
[2026-02-16T13:25:52] [DEBUG] [NPC] Can enter check: Sheep 1319 cannot enter seek (no_target) npc=Sheep 1319 state=seek can_enter=false reason=no_target
[Assign] Goat 1218 entry clan=OKOK assigned=true
[Assign] Goat 1218 assign_success -> @Node2D@617 dist=2
[2026-02-16T13:25:53] [DEBUG] [NPC] Steering behavior: SEEK - position npc=Goat 1218 behavior=SEEK target=position position=-852.6,750.0
[Assign] Goat 1218 add_animal_attempt -> @Node2D@617 dist=2 (enter_range=220)
[2026-02-16T13:25:53] [DEBUG] [NPC] Steering behavior: WANDER - center npc=Goat 1218 behavior=WANDER target=center position=-852.8,752.1 radius=50.0
[2026-02-16T13:25:53] [INFO] [NPC] POSITION: BAHI at (349.7, -66.7), state=wander, distance_to_claim=0.0/400.0, velocity=74.9 npc=BAHI pos=349.7,-66.7 state=wander distance_to_claim=0.0 claim_radius=400.0 velocity=74.9
[2026-02-16T13:25:53] [DEBUG] [NPC] Can enter check: BAHI cannot enter agro (not_caveman) npc=BAHI state=agro can_enter=false reason=not_caveman npc_type=woman
[2026-02-16T13:25:53] [DEBUG] [NPC] Priority eval: BAHI - agro (priority=15.0, can_enter=false) npc=BAHI state=agro priority=15.0 can_enter=false
[2026-02-16T13:25:53] [DEBUG] [NPC] Priority eval: BAHI - combat (priority=12.0, can_enter=false) npc=BAHI state=combat priority=12.0 can_enter=false
[2026-02-16T13:25:53] [DEBUG] [NPC] Can enter check: BAHI cannot enter herd (not_herded) npc=BAHI state=herd can_enter=false reason=not_herded herder=unknown
[2026-02-16T13:25:53] [DEBUG] [NPC] Priority eval: BAHI - herd (priority=11.0, can_enter=false) npc=BAHI state=herd priority=11.0 can_enter=false
[2026-02-16T13:25:53] [DEBUG] [NPC] Priority eval: BAHI - raid (priority=8.5, can_enter=false) npc=BAHI state=raid priority=8.5 can_enter=false
[2026-02-16T13:25:53] [DEBUG] [NPC] Priority eval: BAHI - reproduction (priority=8.0, can_enter=false) npc=BAHI state=reproduction priority=8.0 can_enter=false
[Assign] Goat 1218 assign_success -> @Node2D@617 dist=2
[2026-02-16T13:25:54] [DEBUG] [NPC] Can enter check: Goat 1218 cannot enter herd (not_herded) npc=Goat 1218 state=herd can_enter=false reason=not_herded herder=unknown
[2026-02-16T13:25:54] [DEBUG] [NPC] Priority eval: Goat 1218 - herd (priority=15.0, can_enter=false) npc=Goat 1218 state=herd priority=15.0 can_enter=false
[2026-02-16T13:25:54] [DEBUG] [NPC] Can enter check: Goat 1218 cannot enter agro (not_caveman) npc=Goat 1218 state=agro can_enter=false reason=not_caveman npc_type=goat
[2026-02-16T13:25:54] [DEBUG] [NPC] Priority eval: Goat 1218 - agro (priority=15.0, can_enter=false) npc=Goat 1218 state=agro priority=15.0 can_enter=false
[2026-02-16T13:25:54] [DEBUG] [NPC] Priority eval: Goat 1218 - combat (priority=12.0, can_enter=false) npc=Goat 1218 state=combat priority=12.0 can_enter=false
[2026-02-16T13:25:54] [DEBUG] [NPC] Priority eval: Goat 1218 - work_at_building (priority=9.0, can_enter=false) npc=Goat 1218 state=work_at_building priority=9.0 can_enter=false
[2026-02-16T13:25:54] [DEBUG] [NPC] Priority eval: Goat 1218 - raid (priority=8.5, can_enter=false) npc=Goat 1218 state=raid priority=8.5 can_enter=false
[2026-02-16T13:25:54] [DEBUG] [NPC] Priority eval: Goat 1218 - reproduction (priority=8.0, can_enter=false) npc=Goat 1218 state=reproduction priority=8.0 can_enter=false
[2026-02-16T13:25:54] [DEBUG] [NPC] Priority eval: Goat 1218 - occupy_building (priority=7.5, can_enter=false) npc=Goat 1218 state=occupy_building priority=7.5 can_enter=false
[2026-02-16T13:25:54] [DEBUG] [NPC] Can enter check: Goat 1218 cannot enter seek (no_target) npc=Goat 1218 state=seek can_enter=false reason=no_target
[Assign] Goat 1218 assign_success -> @Node2D@617 dist=1
TASK SYSTEM LOGGER: Called at time 97.1
[2026-02-16T13:25:54] [INFO] [INVENTORY] === TASK SYSTEM LOG: 1 Land Claims ===
[2026-02-16T13:25:54] [INFO] [INVENTORY] LAND CLAIM: OKOK | Pos: (-1050, 689) | Inventory: empty clan_name=OKOK position=(-1049.549, 688.502) inventory=[]
[2026-02-16T13:25:54] [INFO] [INVENTORY] TASK SYSTEM DEBUG: buildings group=5, with building_type=4, ovens=0
[2026-02-16T13:25:54] [INFO] [INVENTORY] === TASK SYSTEM LOG: 0 Ovens ===
NPC WUYA joined clan OKOK (entered herder's land claim)
🏠 WUYA: Herd cleared (no longer following)
🏠 HERD_STATE: WUYA no longer herded (likely joined clan) - exiting to wander
✓ REPRODUCTION: WUYA started pregnancy (mate: Player, clan: OKOK, timer: 22.5s)
DEBUG _find_land_claim: Building Farm (clan: OKOK, pos: (-1238.64, 622.5357)) searching 1 land claims
DEBUG _find_land_claim: Claim 'OKOK' at distance 200.3, radius: 400.0
DEBUG _find_land_claim: Found matching land claim! Inventory - Wood: 0, Grain: 0
DEBUG _find_land_claim: Building Farm (clan: OKOK, pos: (-1238.64, 622.5357)) searching 1 land claims
DEBUG _find_land_claim: Claim 'OKOK' at distance 200.3, radius: 400.0
DEBUG _find_land_claim: Found matching land claim! Inventory - Wood: 0, Grain: 0
DEBUG _find_land_claim: Building Dairy Farm (clan: OKOK, pos: (-852.6257, 749.9959)) searching 1 land claims
DEBUG _find_land_claim: Claim 'OKOK' at distance 206.3, radius: 400.0
DEBUG _find_land_claim: Found matching land claim! Inventory - Wood: 0, Grain: 0
DEBUG _find_land_claim: Building Dairy Farm (clan: OKOK, pos: (-852.6257, 749.9959)) searching 1 land claims
DEBUG _find_land_claim: Claim 'OKOK' at distance 206.3, radius: 400.0
DEBUG _find_land_claim: Found matching land claim! Inventory - Wood: 0, Grain: 0
Task System: WUYA found 5 same-clan building(s) but no job (last reason: missing inputs)
[Assign] Goat 1218 assign_success -> @Node2D@617 dist=2
[2026-02-16T13:25:55] [DEBUG] [NPC] Steering behavior: SEEK - position npc=Goat 1218 behavior=SEEK target=position position=-852.6,750.0
[2026-02-16T13:25:55] [INFO] [NPC] Action started: assign_to_building (building: Dairy Farm) npc=Goat 1218 action=assign_to_building target=Dairy Farm npc_type=goat building=@Node2D@617 distance=1.9
[2026-02-16T13:25:55] [DEBUG] [NPC] Can enter check: BIYU cannot enter agro (not_caveman) npc=BIYU state=agro can_enter=false reason=not_caveman npc_type=woman
[2026-02-16T13:25:55] [DEBUG] [NPC] Priority eval: BIYU - agro (priority=15.0, can_enter=false) npc=BIYU state=agro priority=15.0 can_enter=false
[2026-02-16T13:25:55] [DEBUG] [NPC] Priority eval: BIYU - combat (priority=12.0, can_enter=false) npc=BIYU state=combat priority=12.0 can_enter=false
[2026-02-16T13:25:55] [DEBUG] [NPC] Can enter check: BIYU cannot enter herd (not_herded) npc=BIYU state=herd can_enter=false reason=not_herded herder=unknown
[2026-02-16T13:25:55] [DEBUG] [NPC] Priority eval: BIYU - herd (priority=11.0, can_enter=false) npc=BIYU state=herd priority=11.0 can_enter=false
[2026-02-16T13:25:55] [DEBUG] [NPC] Priority eval: BIYU - raid (priority=8.5, can_enter=false) npc=BIYU state=raid priority=8.5 can_enter=false
[2026-02-16T13:25:55] [DEBUG] [NPC] Priority eval: BIYU - reproduction (priority=8.0, can_enter=false) npc=BIYU state=reproduction priority=8.0 can_enter=false
[2026-02-16T13:25:55] [DEBUG] [NPC] Priority eval: BIYU - occupy_building (priority=7.5, can_enter=false) npc=BIYU state=occupy_building priority=7.5 can_enter=false
[Assign] Goat 1218 add_animal_attempt -> @Node2D@617 dist=1 (enter_range=220)
[ASSIGN] Goat 1218 ClaimBuildingIndex returned 4 buildings for claim OKOK
[Assign] Goat 1218 assign_success -> @Node2D@617 dist=2
[2026-02-16T13:25:56] [DEBUG] [NPC] Can enter check: WUYA cannot enter herd (not_herded) npc=WUYA state=herd can_enter=false reason=not_herded herder=unknown
[2026-02-16T13:25:56] [DEBUG] [NPC] Priority eval: WUYA - herd (priority=15.0, can_enter=false) npc=WUYA state=herd priority=15.0 can_enter=false
[2026-02-16T13:25:56] [DEBUG] [NPC] Can enter check: WUYA cannot enter agro (not_caveman) npc=WUYA state=agro can_enter=false reason=not_caveman npc_type=woman
[2026-02-16T13:25:56] [DEBUG] [NPC] Priority eval: WUYA - agro (priority=15.0, can_enter=false) npc=WUYA state=agro priority=15.0 can_enter=false
[2026-02-16T13:25:56] [DEBUG] [NPC] Priority eval: WUYA - combat (priority=12.0, can_enter=false) npc=WUYA state=combat priority=12.0 can_enter=false
[2026-02-16T13:25:56] [DEBUG] [NPC] Evaluated 3 states: herd(priority=15.0,can_enter=false) agro(priority=15.0,can_enter=false) combat(priority=12.0,can_enter=false) -> Best: work_at_building (priority=9.0) npc=WUYA best_state=work_at_building best_priority=9.0
[2026-02-16T13:25:56] [DEBUG] [NPC] Can enter check: VIIB cannot enter agro (not_caveman) npc=VIIB state=agro can_enter=false reason=not_caveman npc_type=woman
[2026-02-16T13:25:56] [DEBUG] [NPC] Priority eval: VIIB - agro (priority=15.0, can_enter=false) npc=VIIB state=agro priority=15.0 can_enter=false
[2026-02-16T13:25:56] [DEBUG] [NPC] Priority eval: VIIB - combat (priority=12.0, can_enter=false) npc=VIIB state=combat priority=12.0 can_enter=false
[2026-02-16T13:25:56] [DEBUG] [NPC] Can enter check: VIIB cannot enter herd (not_herded) npc=VIIB state=herd can_enter=false reason=not_herded herder=unknown
[Assign] Goat 1218 assign_success -> @Node2D@617 dist=2
DEBUG _find_land_claim: Using cached land claim, inventory - Wood: 0, Grain: 0
DEBUG _find_land_claim: Using cached land claim, inventory - Wood: 0, Grain: 0
DEBUG _find_land_claim: Using cached land claim, inventory - Wood: 0, Grain: 0
DEBUG _find_land_claim: Using cached land claim, inventory - Wood: 0, Grain: 0
[2026-02-16T13:25:57] [DEBUG] [NPC] Can enter check: XIUF cannot enter agro (not_caveman) npc=XIUF state=agro can_enter=false reason=not_caveman npc_type=woman
[2026-02-16T13:25:57] [DEBUG] [NPC] Priority eval: XIUF - agro (priority=15.0, can_enter=false) npc=XIUF state=agro priority=15.0 can_enter=false
[2026-02-16T13:25:57] [DEBUG] [NPC] Priority eval: XIUF - combat (priority=12.0, can_enter=false) npc=XIUF state=combat priority=12.0 can_enter=false
[2026-02-16T13:25:57] [DEBUG] [NPC] Can enter check: XIUF cannot enter herd (not_herded) npc=XIUF state=herd can_enter=false reason=not_herded herder=unknown
[2026-02-16T13:25:57] [DEBUG] [NPC] Priority eval: XIUF - herd (priority=11.0, can_enter=false) npc=XIUF state=herd priority=11.0 can_enter=false
[2026-02-16T13:25:57] [DEBUG] [NPC] Priority eval: XIUF - raid (priority=8.5, can_enter=false) npc=XIUF state=raid priority=8.5 can_enter=false
[2026-02-16T13:25:57] [DEBUG] [NPC] Priority eval: XIUF - reproduction (priority=8.0, can_enter=false) npc=XIUF state=reproduction priority=8.0 can_enter=false
[2026-02-16T13:25:57] [DEBUG] [NPC] Priority eval: XIUF - occupy_building (priority=7.5, can_enter=false) npc=XIUF state=occupy_building priority=7.5 can_enter=false
[2026-02-16T13:25:57] [DEBUG] [NPC] Priority eval: XIUF - work_at_building (priority=7.0, can_enter=false) npc=XIUF state=work_at_building priority=7.0 can_enter=false
[2026-02-16T13:25:57] [DEBUG] [NPC] Can enter check: XIUF cannot enter seek (no_target) npc=XIUF state=seek can_enter=false reason=no_target
TASK SYSTEM LOGGER: Called at time 100.1
[2026-02-16T13:25:57] [INFO] [INVENTORY] === TASK SYSTEM LOG: 1 Land Claims ===
[2026-02-16T13:25:57] [INFO] [INVENTORY] LAND CLAIM: OKOK | Pos: (-1050, 689) | Inventory: empty clan_name=OKOK position=(-1049.549, 688.502) inventory=[]
[2026-02-16T13:25:57] [INFO] [INVENTORY] TASK SYSTEM DEBUG: buildings group=5, with building_type=4, ovens=0
[2026-02-16T13:25:57] [INFO] [INVENTORY] === TASK SYSTEM LOG: 0 Ovens ===
[Assign] Goat 1218 entry clan=OKOK assigned=false
[Assign] Goat 1218 assign_success -> @Node2D@617 dist=2
[Assign] Goat 1218 add_animal_attempt -> @Node2D@617 dist=2 (enter_range=220)
[2026-02-16T13:25:58] [DEBUG] [NPC] Can enter check: WUEC can enter idle (always_available) npc=WUEC state=idle can_enter=true reason=always_available
[2026-02-16T13:25:58] [DEBUG] [NPC] Can enter check: WUEC can enter wander (no_higher_priority_needs) npc=WUEC state=wander can_enter=true reason=no_higher_priority_needs
[2026-02-16T13:25:58] [DEBUG] [NPC] Can enter check: WUEC cannot enter seek (no_target) npc=WUEC state=seek can_enter=false reason=no_target
[2026-02-16T13:25:58] [DEBUG] [NPC] Can enter check: WUEC cannot enter herd (not_herded) npc=WUEC state=herd can_enter=false reason=not_herded herder=unknown
[2026-02-16T13:25:58] [DEBUG] [NPC] Can enter check: WUEC cannot enter agro (not_caveman) npc=WUEC state=agro can_enter=false reason=not_caveman npc_type=woman
[2026-02-16T13:25:58] [DEBUG] [NPC] Can enter check: WUEC cannot enter herd_wildnpc (not_caveman_or_clansman) npc=WUEC state=herd_wildnpc can_enter=false reason=not_caveman_or_clansman npc_type=woman
[2026-02-16T13:25:58] [INFO] [NPC] STATE_EXIT: WUEC exited wander after 0.4s npc=WUEC state=wander duration_s=0.4
[2026-02-16T13:25:58] [INFO] [NPC] State exited: WUEC left wander npc=WUEC state=wander
[2026-02-16T13:25:58] [INFO] [NPC] STATE_ENTRY: WUEC entered idle (from wander) npc=WUEC state=idle from_state=wander
[2026-02-16T13:25:58] [INFO] [NPC] State entered: WUEC entered idle npc=WUEC state=idle
[Assign] Goat 1218 assign_success -> @Node2D@617 dist=2
DEBUG _find_land_claim: Using cached land claim, inventory - Wood: 0, Grain: 0
DEBUG _find_land_claim: Using cached land claim, inventory - Wood: 0, Grain: 0
DEBUG _find_land_claim: Using cached land claim, inventory - Wood: 0, Grain: 0
DEBUG _find_land_claim: Using cached land claim, inventory - Wood: 0, Grain: 0
[2026-02-16T13:25:59] [DEBUG] [NPC] Can enter check: Sheep 1418 cannot enter agro (not_caveman) npc=Sheep 1418 state=agro can_enter=false reason=not_caveman npc_type=sheep
[2026-02-16T13:25:59] [DEBUG] [NPC] Priority eval: Sheep 1418 - agro (priority=15.0, can_enter=false) npc=Sheep 1418 state=agro priority=15.0 can_enter=false
[2026-02-16T13:25:59] [DEBUG] [NPC] Priority eval: Sheep 1418 - combat (priority=12.0, can_enter=false) npc=Sheep 1418 state=combat priority=12.0 can_enter=false
[2026-02-16T13:25:59] [DEBUG] [NPC] Can enter check: Sheep 1418 cannot enter herd (not_herded) npc=Sheep 1418 state=herd can_enter=false reason=not_herded herder=unknown
[2026-02-16T13:25:59] [DEBUG] [NPC] Priority eval: Sheep 1418 - herd (priority=11.0, can_enter=false) npc=Sheep 1418 state=herd priority=11.0 can_enter=false
[2026-02-16T13:25:59] [DEBUG] [NPC] Priority eval: Sheep 1418 - raid (priority=8.5, can_enter=false) npc=Sheep 1418 state=raid priority=8.5 can_enter=false
[2026-02-16T13:25:59] [DEBUG] [NPC] Priority eval: Sheep 1418 - reproduction (priority=8.0, can_enter=false) npc=Sheep 1418 state=reproduction priority=8.0 can_enter=false
[2026-02-16T13:25:59] [DEBUG] [NPC] Priority eval: Sheep 1418 - occupy_building (priority=7.5, can_enter=false) npc=Sheep 1418 state=occupy_building priority=7.5 can_enter=false
[2026-02-16T13:25:59] [DEBUG] [NPC] Priority eval: Sheep 1418 - work_at_building (priority=7.0, can_enter=false) npc=Sheep 1418 state=work_at_building priority=7.0 can_enter=false
[2026-02-16T13:25:59] [DEBUG] [NPC] Can enter check: Sheep 1418 cannot enter seek (no_target) npc=Sheep 1418 state=seek can_enter=false reason=no_target
[Assign] Goat 1218 assign_success -> @Node2D@617 dist=2
[Assign] Goat 1218 assign_success -> @Node2D@617 dist=2
[2026-02-16T13:26:00] [DEBUG] [NPC] Can enter check: WUYA cannot enter herd (not_herded) npc=WUYA state=herd can_enter=false reason=not_herded herder=unknown
[2026-02-16T13:26:00] [DEBUG] [NPC] Priority eval: WUYA - herd (priority=15.0, can_enter=false) npc=WUYA state=herd priority=15.0 can_enter=false
[2026-02-16T13:26:00] [DEBUG] [NPC] Can enter check: WUYA cannot enter agro (not_caveman) npc=WUYA state=agro can_enter=false reason=not_caveman npc_type=woman
[2026-02-16T13:26:00] [DEBUG] [NPC] Priority eval: WUYA - agro (priority=15.0, can_enter=false) npc=WUYA state=agro priority=15.0 can_enter=false
[2026-02-16T13:26:00] [DEBUG] [NPC] Priority eval: WUYA - combat (priority=12.0, can_enter=false) npc=WUYA state=combat priority=12.0 can_enter=false
[2026-02-16T13:26:00] [DEBUG] [NPC] Evaluated 3 states: herd(priority=15.0,can_enter=false) agro(priority=15.0,can_enter=false) combat(priority=12.0,can_enter=false) -> Best: work_at_building (priority=9.0) npc=WUYA best_state=work_at_building best_priority=9.0
[2026-02-16T13:26:00] [DEBUG] [NPC] Can enter check: Sheep 1217 cannot enter agro (not_caveman) npc=Sheep 1217 state=agro can_enter=false reason=not_caveman npc_type=sheep
[2026-02-16T13:26:00] [DEBUG] [NPC] Priority eval: Sheep 1217 - agro (priority=15.0, can_enter=false) npc=Sheep 1217 state=agro priority=15.0 can_enter=false
[2026-02-16T13:26:00] [DEBUG] [NPC] Priority eval: Sheep 1217 - combat (priority=12.0, can_enter=false) npc=Sheep 1217 state=combat priority=12.0 can_enter=false
[2026-02-16T13:26:00] [DEBUG] [NPC] Can enter check: Sheep 1217 cannot enter herd (not_herded) npc=Sheep 1217 state=herd can_enter=false reason=not_herded herder=unknown
TASK SYSTEM LOGGER: Called at time 103.1
[2026-02-16T13:26:00] [INFO] [INVENTORY] === TASK SYSTEM LOG: 1 Land Claims ===
[2026-02-16T13:26:00] [INFO] [INVENTORY] LAND CLAIM: OKOK | Pos: (-1050, 689) | Inventory: empty clan_name=OKOK position=(-1049.549, 688.502) inventory=[]
[2026-02-16T13:26:00] [INFO] [INVENTORY] TASK SYSTEM DEBUG: buildings group=5, with building_type=4, ovens=0
[2026-02-16T13:26:00] [INFO] [INVENTORY] === TASK SYSTEM LOG: 0 Ovens ===
[Assign] Goat 1218 add_animal_attempt -> @Node2D@617 dist=0 (enter_range=220)
[Assign] Goat 1218 assign_success -> @Node2D@617 dist=3
DEBUG _find_land_claim: Using cached land claim, inventory - Wood: 0, Grain: 0
DEBUG _find_land_claim: Using cached land claim, inventory - Wood: 0, Grain: 0
DEBUG _find_land_claim: Using cached land claim, inventory - Wood: 0, Grain: 0
DEBUG _find_land_claim: Using cached land claim, inventory - Wood: 0, Grain: 0
Task System: WUYA found 5 same-clan building(s) but no job (last reason: missing inputs)
[2026-02-16T13:26:01] [DEBUG] [NPC] Can enter check: WUEC cannot enter agro (not_caveman) npc=WUEC state=agro can_enter=false reason=not_caveman npc_type=woman
[2026-02-16T13:26:01] [DEBUG] [NPC] Priority eval: WUEC - agro (priority=15.0, can_enter=false) npc=WUEC state=agro priority=15.0 can_enter=false
[2026-02-16T13:26:01] [DEBUG] [NPC] Priority eval: WUEC - combat (priority=12.0, can_enter=false) npc=WUEC state=combat priority=12.0 can_enter=false
[2026-02-16T13:26:01] [DEBUG] [NPC] Can enter check: WUEC cannot enter herd (not_herded) npc=WUEC state=herd can_enter=false reason=not_herded herder=unknown
[2026-02-16T13:26:01] [DEBUG] [NPC] Priority eval: WUEC - herd (priority=11.0, can_enter=false) npc=WUEC state=herd priority=11.0 can_enter=false
[2026-02-16T13:26:01] [DEBUG] [NPC] Priority eval: WUEC - raid (priority=8.5, can_enter=false) npc=WUEC state=raid priority=8.5 can_enter=false
[2026-02-16T13:26:01] [DEBUG] [NPC] Priority eval: WUEC - reproduction (priority=8.0, can_enter=false) npc=WUEC state=reproduction priority=8.0 can_enter=false
[2026-02-16T13:26:01] [DEBUG] [NPC] Priority eval: WUEC - occupy_building (priority=7.5, can_enter=false) npc=WUEC state=occupy_building priority=7.5 can_enter=false
[2026-02-16T13:26:01] [DEBUG] [NPC] Priority eval: WUEC - work_at_building (priority=7.0, can_enter=false) npc=WUEC state=work_at_building priority=7.0 can_enter=false
[2026-02-16T13:26:01] [DEBUG] [NPC] Can enter check: WUEC cannot enter seek (no_target) npc=WUEC state=seek can_enter=false reason=no_target
[ASSIGN] Goat 1218 ClaimBuildingIndex returned 4 buildings for claim OKOK
[Assign] Goat 1218 assign_success -> @Node2D@617 dist=2
[2026-02-16T13:26:02] [DEBUG] [NPC] Can enter check: BIYU cannot enter agro (not_caveman) npc=BIYU state=agro can_enter=false reason=not_caveman npc_type=woman
[2026-02-16T13:26:02] [DEBUG] [NPC] Priority eval: BIYU - agro (priority=15.0, can_enter=false) npc=BIYU state=agro priority=15.0 can_enter=false
[2026-02-16T13:26:02] [DEBUG] [NPC] Priority eval: BIYU - combat (priority=12.0, can_enter=false) npc=BIYU state=combat priority=12.0 can_enter=false
[2026-02-16T13:26:02] [DEBUG] [NPC] Can enter check: BIYU cannot enter herd (not_herded) npc=BIYU state=herd can_enter=false reason=not_herded herder=unknown
[2026-02-16T13:26:02] [DEBUG] [NPC] Priority eval: BIYU - herd (priority=11.0, can_enter=false) npc=BIYU state=herd priority=11.0 can_enter=false
[2026-02-16T13:26:02] [DEBUG] [NPC] Priority eval: BIYU - raid (priority=8.5, can_enter=false) npc=BIYU state=raid priority=8.5 can_enter=false
[2026-02-16T13:26:02] [DEBUG] [NPC] Priority eval: BIYU - reproduction (priority=8.0, can_enter=false) npc=BIYU state=reproduction priority=8.0 can_enter=false
[2026-02-16T13:26:02] [DEBUG] [NPC] Priority eval: BIYU - occupy_building (priority=7.5, can_enter=false) npc=BIYU state=occupy_building priority=7.5 can_enter=false
[2026-02-16T13:26:02] [DEBUG] [NPC] Priority eval: BIYU - work_at_building (priority=7.0, can_enter=false) npc=BIYU state=work_at_building priority=7.0 can_enter=false
[2026-02-16T13:26:02] [DEBUG] [NPC] Can enter check: BIYU cannot enter seek (no_target) npc=BIYU state=seek can_enter=false reason=no_target
[Assign] Goat 1218 assign_success -> @Node2D@617 dist=2
[Assign] Goat 1218 entry clan=OKOK assigned=true
[Assign] Goat 1218 add_animal_attempt -> @Node2D@617 dist=1 (enter_range=220)
DEBUG _find_land_claim: Using cached land claim, inventory - Wood: 0, Grain: 0
DEBUG _find_land_claim: Using cached land claim, inventory - Wood: 0, Grain: 0
DEBUG _find_land_claim: Using cached land claim, inventory - Wood: 0, Grain: 0
DEBUG _find_land_claim: Using cached land claim, inventory - Wood: 0, Grain: 0
[2026-02-16T13:26:03] [DEBUG] [NPC] Can enter check: WUYA cannot enter herd (not_herded) npc=WUYA state=herd can_enter=false reason=not_herded herder=unknown
[2026-02-16T13:26:03] [DEBUG] [NPC] Priority eval: WUYA - herd (priority=15.0, can_enter=false) npc=WUYA state=herd priority=15.0 can_enter=false
[2026-02-16T13:26:03] [DEBUG] [NPC] Can enter check: WUYA cannot enter agro (not_caveman) npc=WUYA state=agro can_enter=false reason=not_caveman npc_type=woman
[2026-02-16T13:26:03] [DEBUG] [NPC] Priority eval: WUYA - agro (priority=15.0, can_enter=false) npc=WUYA state=agro priority=15.0 can_enter=false
[2026-02-16T13:26:03] [DEBUG] [NPC] Priority eval: WUYA - combat (priority=12.0, can_enter=false) npc=WUYA state=combat priority=12.0 can_enter=false
[2026-02-16T13:26:03] [DEBUG] [NPC] Evaluated 3 states: herd(priority=15.0,can_enter=false) agro(priority=15.0,can_enter=false) combat(priority=12.0,can_enter=false) -> Best: work_at_building (priority=9.0) npc=WUYA best_state=work_at_building best_priority=9.0
[2026-02-16T13:26:03] [DEBUG] [NPC] Can enter check: JOEC can enter idle (always_available) npc=JOEC state=idle can_enter=true reason=always_available
[2026-02-16T13:26:03] [DEBUG] [NPC] Can enter check: JOEC can enter wander (no_higher_priority_needs) npc=JOEC state=wander can_enter=true reason=no_higher_priority_needs
[2026-02-16T13:26:03] [DEBUG] [NPC] Can enter check: JOEC cannot enter seek (no_target) npc=JOEC state=seek can_enter=false reason=no_target
[2026-02-16T13:26:03] [DEBUG] [NPC] Can enter check: JOEC cannot enter herd (not_herded) npc=JOEC state=herd can_enter=false reason=not_herded herder=unknown
[Assign] Goat 1218 assign_success -> @Node2D@617 dist=2
TASK SYSTEM LOGGER: Called at time 106.1
[2026-02-16T13:26:03] [INFO] [INVENTORY] === TASK SYSTEM LOG: 1 Land Claims ===
[2026-02-16T13:26:03] [INFO] [INVENTORY] LAND CLAIM: OKOK | Pos: (-1050, 689) | Inventory: empty clan_name=OKOK position=(-1049.549, 688.502) inventory=[]
[2026-02-16T13:26:03] [INFO] [INVENTORY] TASK SYSTEM DEBUG: buildings group=5, with building_type=4, ovens=0
[2026-02-16T13:26:03] [INFO] [INVENTORY] === TASK SYSTEM LOG: 0 Ovens ===
[2026-02-16T13:26:04] [INFO] [INVENTORY] PlayerInventoryUI opened
Player inventory toggled: OPEN
[2026-02-16T13:26:04] [INFO] [INVENTORY] BuildingInventoryUI closed
[Assign] Goat 1218 assign_success -> @Node2D@617 dist=2
[2026-02-16T13:26:04] [INFO] [INVENTORY] PlayerInventoryUI closed
Player inventory toggled: CLOSED
[2026-02-16T13:26:04] [INFO] [INVENTORY] BuildingInventoryUI closed
[2026-02-16T13:26:04] [DEBUG] [NPC] Can enter check: Goat 1218 cannot enter herd (not_herded) npc=Goat 1218 state=herd can_enter=false reason=not_herded herder=unknown
[2026-02-16T13:26:04] [DEBUG] [NPC] Priority eval: Goat 1218 - herd (priority=15.0, can_enter=false) npc=Goat 1218 state=herd priority=15.0 can_enter=false
[2026-02-16T13:26:04] [DEBUG] [NPC] Can enter check: Goat 1218 cannot enter agro (not_caveman) npc=Goat 1218 state=agro can_enter=false reason=not_caveman npc_type=goat
[2026-02-16T13:26:04] [DEBUG] [NPC] Priority eval: Goat 1218 - agro (priority=15.0, can_enter=false) npc=Goat 1218 state=agro priority=15.0 can_enter=false
[2026-02-16T13:26:04] [DEBUG] [NPC] Priority eval: Goat 1218 - combat (priority=12.0, can_enter=false) npc=Goat 1218 state=combat priority=12.0 can_enter=false
[2026-02-16T13:26:04] [DEBUG] [NPC] Priority eval: Goat 1218 - work_at_building (priority=9.0, can_enter=false) npc=Goat 1218 state=work_at_building priority=9.0 can_enter=false
[2026-02-16T13:26:04] [DEBUG] [NPC] Priority eval: Goat 1218 - raid (priority=8.5, can_enter=false) npc=Goat 1218 state=raid priority=8.5 can_enter=false
[2026-02-16T13:26:04] [DEBUG] [NPC] Priority eval: Goat 1218 - reproduction (priority=8.0, can_enter=false) npc=Goat 1218 state=reproduction priority=8.0 can_enter=false
[2026-02-16T13:26:04] [DEBUG] [NPC] Priority eval: Goat 1218 - occupy_building (priority=7.5, can_enter=false) npc=Goat 1218 state=occupy_building priority=7.5 can_enter=false
[2026-02-16T13:26:04] [DEBUG] [NPC] Can enter check: Goat 1218 cannot enter seek (no_target) npc=Goat 1218 state=seek can_enter=false reason=no_target
[Assign] Goat 1218 assign_success -> @Node2D@617 dist=2
DEBUG _find_land_claim: Using cached land claim, inventory - Wood: 0, Grain: 0
DEBUG _find_land_claim: Using cached land claim, inventory - Wood: 0, Grain: 0
DEBUG _find_land_claim: Using cached land claim, inventory - Wood: 0, Grain: 0
DEBUG _find_land_claim: Using cached land claim, inventory - Wood: 0, Grain: 0
[2026-02-16T13:26:05] [INFO] [NPC] POSITION: PUIK at (612.8, 459.3), state=wander, distance_to_claim=0.0/400.0, velocity=42.4 npc=PUIK pos=612.8,459.3 state=wander distance_to_claim=0.0 claim_radius=400.0 velocity=42.4
[2026-02-16T13:26:05] [DEBUG] [NPC] Steering behavior: WANDER - center npc=PUIK behavior=WANDER target=center position=683.0,296.2 radius=300.0
[2026-02-16T13:26:05] [DEBUG] [NPC] Can enter check: PUIK cannot enter agro (not_caveman) npc=PUIK state=agro can_enter=false reason=not_caveman npc_type=woman
[2026-02-16T13:26:05] [DEBUG] [NPC] Priority eval: PUIK - agro (priority=15.0, can_enter=false) npc=PUIK state=agro priority=15.0 can_enter=false
[2026-02-16T13:26:05] [DEBUG] [NPC] Priority eval: PUIK - combat (priority=12.0, can_enter=false) npc=PUIK state=combat priority=12.0 can_enter=false
[2026-02-16T13:26:05] [DEBUG] [NPC] Can enter check: PUIK cannot enter herd (not_herded) npc=PUIK state=herd can_enter=false reason=not_herded herder=unknown
[2026-02-16T13:26:05] [DEBUG] [NPC] Priority eval: PUIK - herd (priority=11.0, can_enter=false) npc=PUIK state=herd priority=11.0 can_enter=false
[2026-02-16T13:26:05] [DEBUG] [NPC] Priority eval: PUIK - raid (priority=8.5, can_enter=false) npc=PUIK state=raid priority=8.5 can_enter=false
[2026-02-16T13:26:05] [DEBUG] [NPC] Priority eval: PUIK - reproduction (priority=8.0, can_enter=false) npc=PUIK state=reproduction priority=8.0 can_enter=false
[2026-02-16T13:26:05] [DEBUG] [NPC] Priority eval: PUIK - occupy_building (priority=7.5, can_enter=false) npc=PUIK state=occupy_building priority=7.5 can_enter=false
[Assign] Goat 1218 add_animal_attempt -> @Node2D@617 dist=1 (enter_range=220)
[Assign] Goat 1218 assign_success -> @Node2D@617 dist=12
[2026-02-16T13:26:06] [DEBUG] [NPC] Can enter check: WUYA cannot enter herd (not_herded) npc=WUYA state=herd can_enter=false reason=not_herded herder=unknown
[2026-02-16T13:26:06] [DEBUG] [NPC] Priority eval: WUYA - herd (priority=15.0, can_enter=false) npc=WUYA state=herd priority=15.0 can_enter=false
[2026-02-16T13:26:06] [DEBUG] [NPC] Can enter check: WUYA cannot enter agro (not_caveman) npc=WUYA state=agro can_enter=false reason=not_caveman npc_type=woman
[2026-02-16T13:26:06] [DEBUG] [NPC] Priority eval: WUYA - agro (priority=15.0, can_enter=false) npc=WUYA state=agro priority=15.0 can_enter=false
[2026-02-16T13:26:06] [DEBUG] [NPC] Priority eval: WUYA - combat (priority=12.0, can_enter=false) npc=WUYA state=combat priority=12.0 can_enter=false
[2026-02-16T13:26:06] [DEBUG] [NPC] Evaluated 3 states: herd(priority=15.0,can_enter=false) agro(priority=15.0,can_enter=false) combat(priority=12.0,can_enter=false) -> Best: work_at_building (priority=9.0) npc=WUYA best_state=work_at_building best_priority=9.0
[2026-02-16T13:26:06] [DEBUG] [NPC] Can enter check: Sheep 1217 cannot enter agro (not_caveman) npc=Sheep 1217 state=agro can_enter=false reason=not_caveman npc_type=sheep
[2026-02-16T13:26:06] [DEBUG] [NPC] Priority eval: Sheep 1217 - agro (priority=15.0, can_enter=false) npc=Sheep 1217 state=agro priority=15.0 can_enter=false
[2026-02-16T13:26:06] [DEBUG] [NPC] Priority eval: Sheep 1217 - combat (priority=12.0, can_enter=false) npc=Sheep 1217 state=combat priority=12.0 can_enter=false
[2026-02-16T13:26:06] [DEBUG] [NPC] Can enter check: Sheep 1217 cannot enter herd (not_herded) npc=Sheep 1217 state=herd can_enter=false reason=not_herded herder=unknown
TASK SYSTEM LOGGER: Called at time 109.1
[2026-02-16T13:26:06] [INFO] [INVENTORY] === TASK SYSTEM LOG: 1 Land Claims ===
[2026-02-16T13:26:06] [INFO] [INVENTORY] LAND CLAIM: OKOK | Pos: (-1050, 689) | Inventory: empty clan_name=OKOK position=(-1049.549, 688.502) inventory=[]
[2026-02-16T13:26:06] [INFO] [INVENTORY] TASK SYSTEM DEBUG: buildings group=5, with building_type=4, ovens=0
[2026-02-16T13:26:06] [INFO] [INVENTORY] === TASK SYSTEM LOG: 0 Ovens ===
[Assign] Goat 1218 assign_success -> @Node2D@617 dist=6
DEBUG _find_land_claim: Using cached land claim, inventory - Wood: 0, Grain: 0
DEBUG _find_land_claim: Using cached land claim, inventory - Wood: 0, Grain: 0
DEBUG _find_land_claim: Using cached land claim, inventory - Wood: 0, Grain: 0
DEBUG _find_land_claim: Using cached land claim, inventory - Wood: 0, Grain: 0
Task System: WUYA found 5 same-clan building(s) but no job (last reason: missing inputs)
[2026-02-16T13:26:07] [DEBUG] [NPC] Can enter check: Sheep 1319 cannot enter agro (not_caveman) npc=Sheep 1319 state=agro can_enter=false reason=not_caveman npc_type=sheep
[2026-02-16T13:26:07] [DEBUG] [NPC] Priority eval: Sheep 1319 - agro (priority=15.0, can_enter=false) npc=Sheep 1319 state=agro priority=15.0 can_enter=false
[2026-02-16T13:26:07] [DEBUG] [NPC] Priority eval: Sheep 1319 - combat (priority=12.0, can_enter=false) npc=Sheep 1319 state=combat priority=12.0 can_enter=false
[2026-02-16T13:26:07] [DEBUG] [NPC] Can enter check: Sheep 1319 cannot enter herd (not_herded) npc=Sheep 1319 state=herd can_enter=false reason=not_herded herder=unknown
[2026-02-16T13:26:07] [DEBUG] [NPC] Priority eval: Sheep 1319 - herd (priority=11.0, can_enter=false) npc=Sheep 1319 state=herd priority=11.0 can_enter=false
[2026-02-16T13:26:07] [DEBUG] [NPC] Priority eval: Sheep 1319 - raid (priority=8.5, can_enter=false) npc=Sheep 1319 state=raid priority=8.5 can_enter=false
[2026-02-16T13:26:07] [DEBUG] [NPC] Priority eval: Sheep 1319 - reproduction (priority=8.0, can_enter=false) npc=Sheep 1319 state=reproduction priority=8.0 can_enter=false
[2026-02-16T13:26:07] [DEBUG] [NPC] Priority eval: Sheep 1319 - occupy_building (priority=7.5, can_enter=false) npc=Sheep 1319 state=occupy_building priority=7.5 can_enter=false
[2026-02-16T13:26:07] [DEBUG] [NPC] Priority eval: Sheep 1319 - work_at_building (priority=7.0, can_enter=false) npc=Sheep 1319 state=work_at_building priority=7.0 can_enter=false
[2026-02-16T13:26:07] [DEBUG] [NPC] Can enter check: Sheep 1319 cannot enter seek (no_target) npc=Sheep 1319 state=seek can_enter=false reason=no_target
[ASSIGN] Goat 1218 ClaimBuildingIndex returned 4 buildings for claim OKOK
[Assign] Goat 1218 assign_success -> @Node2D@617 dist=5
[Assign] Goat 1218 add_animal_attempt -> @Node2D@617 dist=5 (enter_range=220)
[Assign] Goat 1218 entry clan=OKOK assigned=false
[Assign] Goat 1218 assign_success -> @Node2D@617 dist=5
[2026-02-16T13:26:08] [DEBUG] [NPC] Can enter check: PUIK cannot enter agro (not_caveman) npc=PUIK state=agro can_enter=false reason=not_caveman npc_type=woman
[2026-02-16T13:26:08] [DEBUG] [NPC] Priority eval: PUIK - agro (priority=15.0, can_enter=false) npc=PUIK state=agro priority=15.0 can_enter=false
[2026-02-16T13:26:08] [DEBUG] [NPC] Priority eval: PUIK - combat (priority=12.0, can_enter=false) npc=PUIK state=combat priority=12.0 can_enter=false
[2026-02-16T13:26:08] [DEBUG] [NPC] Can enter check: PUIK cannot enter herd (not_herded) npc=PUIK state=herd can_enter=false reason=not_herded herder=unknown
[2026-02-16T13:26:08] [DEBUG] [NPC] Priority eval: PUIK - herd (priority=11.0, can_enter=false) npc=PUIK state=herd priority=11.0 can_enter=false
[2026-02-16T13:26:08] [DEBUG] [NPC] Priority eval: PUIK - raid (priority=8.5, can_enter=false) npc=PUIK state=raid priority=8.5 can_enter=false
[2026-02-16T13:26:08] [DEBUG] [NPC] Priority eval: PUIK - reproduction (priority=8.0, can_enter=false) npc=PUIK state=reproduction priority=8.0 can_enter=false
[2026-02-16T13:26:08] [DEBUG] [NPC] Priority eval: PUIK - occupy_building (priority=7.5, can_enter=false) npc=PUIK state=occupy_building priority=7.5 can_enter=false
[2026-02-16T13:26:08] [DEBUG] [NPC] Priority eval: PUIK - work_at_building (priority=7.0, can_enter=false) npc=PUIK state=work_at_building priority=7.0 can_enter=false
[2026-02-16T13:26:08] [DEBUG] [NPC] Can enter check: PUIK cannot enter seek (no_target) npc=PUIK state=seek can_enter=false reason=no_target
[2026-02-16T13:26:09] [INFO] [INVENTORY] PlayerInventoryUI opened
Player inventory toggled: OPEN
🔍 INVENTORY_UI: setup() called
   - inventory: <RefCounted#-9223371688744316937> (valid: true)
🔍 INVENTORY UI SETUP: Setting inventory_data from <RefCounted#-9223371688744316937> to <RefCounted#-9223371688744316937> (slot_count=6)
   - Calling _build_slots() deferred...
   - Calling _update_all_slots() deferred...
✅ INVENTORY_UI: setup() completed
DEBUG _update_title: is_corpse=false, land_claim=<null>, building=@Node2D@617:<Node2D#348009795497>
DEBUG _update_title: is_corpse=false, land_claim=<null>, building=@Node2D@617:<Node2D#348009795497>
🔵 Building inventory opened for Dairy Farm
DEBUG _update_title: is_corpse=false, land_claim=<null>, building=@Node2D@617:<Node2D#348009795497>
🔍 BUILDING UI SHOW: inventory_data instance: <RefCounted#-9223371688744316937> (slot_count=6, can_stack=true)
🔍 BUILDING UI SHOW: Raw slots array: [<null>, <null>, <null>, <null>, <null>, <null>]
🔍 BUILDING UI SHOW: Slot 0: null
🔍 BUILDING UI SHOW: Slot 1: null
🔍 BUILDING UI SHOW: Slot 2: null
🔍 BUILDING UI SHOW: Slot 3: null
🔍 BUILDING UI SHOW: Slot 4: null
🔍 BUILDING UI SHOW: Slot 5: null
📦 LAND CLAIM INVENTORY: Total items: 0 | Breakdown: empty
[2026-02-16T13:26:09] [INFO] [INVENTORY] BuildingInventoryUI opened
DEBUG _update_title: is_corpse=false, land_claim=<null>, building=@Node2D@617:<Node2D#348009795497>
[Assign] Goat 1218 assign_success -> @Node2D@617 dist=5
DEBUG _find_land_claim: Using cached land claim, inventory - Wood: 0, Grain: 0
DEBUG _find_land_claim: Using cached land claim, inventory - Wood: 0, Grain: 0
DEBUG _find_land_claim: Using cached land claim, inventory - Wood: 0, Grain: 0
DEBUG _find_land_claim: Using cached land claim, inventory - Wood: 0, Grain: 0
[2026-02-16T13:26:09] [DEBUG] [NPC] Can enter check: WUYA cannot enter herd (not_herded) npc=WUYA state=herd can_enter=false reason=not_herded herder=unknown
[2026-02-16T13:26:09] [DEBUG] [NPC] Priority eval: WUYA - herd (priority=15.0, can_enter=false) npc=WUYA state=herd priority=15.0 can_enter=false
[2026-02-16T13:26:09] [DEBUG] [NPC] Can enter check: WUYA cannot enter agro (not_caveman) npc=WUYA state=agro can_enter=false reason=not_caveman npc_type=woman
[2026-02-16T13:26:09] [DEBUG] [NPC] Priority eval: WUYA - agro (priority=15.0, can_enter=false) npc=WUYA state=agro priority=15.0 can_enter=false
[2026-02-16T13:26:09] [DEBUG] [NPC] Priority eval: WUYA - combat (priority=12.0, can_enter=false) npc=WUYA state=combat priority=12.0 can_enter=false
[2026-02-16T13:26:09] [DEBUG] [NPC] Evaluated 3 states: herd(priority=15.0,can_enter=false) agro(priority=15.0,can_enter=false) combat(priority=12.0,can_enter=false) -> Best: work_at_building (priority=9.0) npc=WUYA best_state=work_at_building best_priority=9.0
[2026-02-16T13:26:09] [DEBUG] [NPC] Steering behavior: WANDER - center npc=Sheep 61220 behavior=WANDER target=center position=112.5,570.1 radius=300.0
[2026-02-16T13:26:09] [INFO] [NPC] POSITION: Sheep 61220 at (121.2, 541.2), state=wander, distance_to_claim=0.0/400.0, velocity=33.7 npc=Sheep 61220 pos=121.2,541.2 state=wander distance_to_claim=0.0 claim_radius=400.0 velocity=33.7
TASK SYSTEM LOGGER: Called at time 112.1
[2026-02-16T13:26:09] [INFO] [NPC] ═══════════════════════════════════════════════════════
[2026-02-16T13:26:09] [INFO] [NPC] === TASK SYSTEM LOG: 11 Women ===
[2026-02-16T13:26:09] [INFO] [INVENTORY] === TASK SYSTEM LOG: 1 Land Claims ===
[2026-02-16T13:26:09] [INFO] [INVENTORY] LAND CLAIM: OKOK | Pos: (-1050, 689) | Inventory: empty clan_name=OKOK position=(-1049.549, 688.502) inventory=[]
[2026-02-16T13:26:09] [INFO] [INVENTORY] TASK SYSTEM DEBUG: buildings group=5, with building_type=4, ovens=0
[2026-02-16T13:26:09] [INFO] [INVENTORY] === TASK SYSTEM LOG: 0 Ovens ===
[Assign] Goat 1218 assign_success -> @Node2D@617 dist=5
[2026-02-16T13:26:10] [INFO] [INVENTORY] PlayerInventoryUI closed
Player inventory toggled: CLOSED
🔍 INVENTORY_UI: setup() called
   - inventory: <RefCounted#-9223371688744316937> (valid: true)
🔍 INVENTORY UI SETUP: Setting inventory_data from <RefCounted#-9223371688744316937> to <RefCounted#-9223371688744316937> (slot_count=6)
   - Calling _build_slots() deferred...
   - Calling _update_all_slots() deferred...
✅ INVENTORY_UI: setup() completed
DEBUG _update_title: is_corpse=false, land_claim=<null>, building=@Node2D@617:<Node2D#348009795497>
DEBUG _update_title: is_corpse=false, land_claim=<null>, building=@Node2D@617:<Node2D#348009795497>
🔵 Building inventory opened for Dairy Farm
[2026-02-16T13:26:10] [INFO] [INVENTORY] BuildingInventoryUI closed
DEBUG _update_title: is_corpse=false, land_claim=<null>, building=@Node2D@617:<Node2D#348009795497>
[Assign] Goat 1218 add_animal_attempt -> @Node2D@617 dist=5 (enter_range=220)
[2026-02-16T13:26:10] [DEBUG] [NPC] Can enter check: Goat 1319 cannot enter agro (not_caveman) npc=Goat 1319 state=agro can_enter=false reason=not_caveman npc_type=goat
[2026-02-16T13:26:10] [DEBUG] [NPC] Priority eval: Goat 1319 - agro (priority=15.0, can_enter=false) npc=Goat 1319 state=agro priority=15.0 can_enter=false
[2026-02-16T13:26:10] [DEBUG] [NPC] Priority eval: Goat 1319 - combat (priority=12.0, can_enter=false) npc=Goat 1319 state=combat priority=12.0 can_enter=false
[2026-02-16T13:26:10] [DEBUG] [NPC] Can enter check: Goat 1319 cannot enter herd (not_herded) npc=Goat 1319 state=herd can_enter=false reason=not_herded herder=unknown
[2026-02-16T13:26:10] [DEBUG] [NPC] Priority eval: Goat 1319 - herd (priority=11.0, can_enter=false) npc=Goat 1319 state=herd priority=11.0 can_enter=false
[2026-02-16T13:26:10] [DEBUG] [NPC] Priority eval: Goat 1319 - raid (priority=8.5, can_enter=false) npc=Goat 1319 state=raid priority=8.5 can_enter=false
[2026-02-16T13:26:10] [DEBUG] [NPC] Priority eval: Goat 1319 - reproduction (priority=8.0, can_enter=false) npc=Goat 1319 state=reproduction priority=8.0 can_enter=false
[2026-02-16T13:26:10] [DEBUG] [NPC] Priority eval: Goat 1319 - occupy_building (priority=7.5, can_enter=false) npc=Goat 1319 state=occupy_building priority=7.5 can_enter=false
[2026-02-16T13:26:10] [DEBUG] [NPC] Priority eval: Goat 1319 - work_at_building (priority=7.0, can_enter=false) npc=Goat 1319 state=work_at_building priority=7.0 can_enter=false
[2026-02-16T13:26:10] [DEBUG] [NPC] Can enter check: Goat 1319 cannot enter seek (no_target) npc=Goat 1319 state=seek can_enter=false reason=no_target
[Assign] Goat 1218 assign_success -> @Node2D@617 dist=5
DEBUG _find_land_claim: Using cached land claim, inventory - Wood: 0, Grain: 0
DEBUG _find_land_claim: Using cached land claim, inventory - Wood: 0, Grain: 0
DEBUG _find_land_claim: Using cached land claim, inventory - Wood: 0, Grain: 0
DEBUG _find_land_claim: Using cached land claim, inventory - Wood: 0, Grain: 0
[2026-02-16T13:26:11] [DEBUG] [NPC] Can enter check: BIYU cannot enter agro (not_caveman) npc=BIYU state=agro can_enter=false reason=not_caveman npc_type=woman
[2026-02-16T13:26:11] [DEBUG] [NPC] Priority eval: BIYU - agro (priority=15.0, can_enter=false) npc=BIYU state=agro priority=15.0 can_enter=false
[2026-02-16T13:26:11] [DEBUG] [NPC] Priority eval: BIYU - combat (priority=12.0, can_enter=false) npc=BIYU state=combat priority=12.0 can_enter=false
[2026-02-16T13:26:11] [DEBUG] [NPC] Can enter check: BIYU cannot enter herd (not_herded) npc=BIYU state=herd can_enter=false reason=not_herded herder=unknown
[2026-02-16T13:26:11] [DEBUG] [NPC] Priority eval: BIYU - herd (priority=11.0, can_enter=false) npc=BIYU state=herd priority=11.0 can_enter=false
[2026-02-16T13:26:11] [DEBUG] [NPC] Priority eval: BIYU - raid (priority=8.5, can_enter=false) npc=BIYU state=raid priority=8.5 can_enter=false
[2026-02-16T13:26:11] [DEBUG] [NPC] Priority eval: BIYU - reproduction (priority=8.0, can_enter=false) npc=BIYU state=reproduction priority=8.0 can_enter=false
[2026-02-16T13:26:11] [DEBUG] [NPC] Priority eval: BIYU - occupy_building (priority=7.5, can_enter=false) npc=BIYU state=occupy_building priority=7.5 can_enter=false
[2026-02-16T13:26:11] [DEBUG] [NPC] Priority eval: BIYU - work_at_building (priority=7.0, can_enter=false) npc=BIYU state=work_at_building priority=7.0 can_enter=false
[2026-02-16T13:26:11] [DEBUG] [NPC] Can enter check: BIYU cannot enter seek (no_target) npc=BIYU state=seek can_enter=false reason=no_target
[Assign] Goat 1218 assign_success -> @Node2D@617 dist=3
[Assign] Goat 1218 assign_success -> @Node2D@617 dist=3
[2026-02-16T13:26:12] [DEBUG] [NPC] Can enter check: WUYA cannot enter herd (not_herded) npc=WUYA state=herd can_enter=false reason=not_herded herder=unknown
[2026-02-16T13:26:12] [DEBUG] [NPC] Priority eval: WUYA - herd (priority=15.0, can_enter=false) npc=WUYA state=herd priority=15.0 can_enter=false
[2026-02-16T13:26:12] [DEBUG] [NPC] Can enter check: WUYA cannot enter agro (not_caveman) npc=WUYA state=agro can_enter=false reason=not_caveman npc_type=woman
[2026-02-16T13:26:12] [DEBUG] [NPC] Priority eval: WUYA - agro (priority=15.0, can_enter=false) npc=WUYA state=agro priority=15.0 can_enter=false
[2026-02-16T13:26:12] [DEBUG] [NPC] Priority eval: WUYA - combat (priority=12.0, can_enter=false) npc=WUYA state=combat priority=12.0 can_enter=false
[2026-02-16T13:26:12] [DEBUG] [NPC] Evaluated 3 states: herd(priority=15.0,can_enter=false) agro(priority=15.0,can_enter=false) combat(priority=12.0,can_enter=false) -> Best: work_at_building (priority=9.0) npc=WUYA best_state=work_at_building best_priority=9.0
[2026-02-16T13:26:12] [INFO] [NPC] POSITION: JOEC at (58.5, 1374.5), state=wander, distance_to_claim=0.0/400.0, velocity=56.1 npc=JOEC pos=58.5,1374.5 state=wander distance_to_claim=0.0 claim_radius=400.0 velocity=56.1
[2026-02-16T13:26:12] [DEBUG] [NPC] Can enter check: JOEC cannot enter agro (not_caveman) npc=JOEC state=agro can_enter=false reason=not_caveman npc_type=woman
[2026-02-16T13:26:12] [DEBUG] [NPC] Priority eval: JOEC - agro (priority=15.0, can_enter=false) npc=JOEC state=agro priority=15.0 can_enter=false
[2026-02-16T13:26:12] [DEBUG] [NPC] Priority eval: JOEC - combat (priority=12.0, can_enter=false) npc=JOEC state=combat priority=12.0 can_enter=false
TASK SYSTEM LOGGER: Called at time 115.2
[2026-02-16T13:26:12] [INFO] [INVENTORY] === TASK SYSTEM LOG: 1 Land Claims ===
[2026-02-16T13:26:12] [INFO] [INVENTORY] LAND CLAIM: OKOK | Pos: (-1050, 689) | Inventory: empty clan_name=OKOK position=(-1049.549, 688.502) inventory=[]
[2026-02-16T13:26:12] [INFO] [INVENTORY] TASK SYSTEM DEBUG: buildings group=5, with building_type=4, ovens=0
[2026-02-16T13:26:12] [INFO] [INVENTORY] === TASK SYSTEM LOG: 0 Ovens ===
[Assign] Goat 1218 add_animal_attempt -> @Node2D@617 dist=0 (enter_range=220)
DEBUG _find_land_claim: Using cached land claim, inventory - Wood: 0, Grain: 0
DEBUG _find_land_claim: Using cached land claim, inventory - Wood: 0, Grain: 0
DEBUG _find_land_claim: Using cached land claim, inventory - Wood: 0, Grain: 0
DEBUG _find_land_claim: Using cached land claim, inventory - Wood: 0, Grain: 0
Task System: WUYA found 5 same-clan building(s) but no job (last reason: missing inputs)
[ASSIGN] Goat 1218 ClaimBuildingIndex returned 4 buildings for claim OKOK
[Assign] Goat 1218 assign_success -> @Node2D@617 dist=2
[2026-02-16T13:26:13] [DEBUG] [NPC] Can enter check: WUEC can enter idle (always_available) npc=WUEC state=idle can_enter=true reason=always_available
[2026-02-16T13:26:13] [DEBUG] [NPC] Can enter check: WUEC can enter wander (no_higher_priority_needs) npc=WUEC state=wander can_enter=true reason=no_higher_priority_needs
[2026-02-16T13:26:13] [DEBUG] [NPC] Can enter check: WUEC cannot enter seek (no_target) npc=WUEC state=seek can_enter=false reason=no_target
[2026-02-16T13:26:13] [DEBUG] [NPC] Can enter check: WUEC cannot enter herd (not_herded) npc=WUEC state=herd can_enter=false reason=not_herded herder=unknown
[2026-02-16T13:26:13] [DEBUG] [NPC] Can enter check: WUEC cannot enter agro (not_caveman) npc=WUEC state=agro can_enter=false reason=not_caveman npc_type=woman
[2026-02-16T13:26:13] [DEBUG] [NPC] Can enter check: WUEC cannot enter herd_wildnpc (not_caveman_or_clansman) npc=WUEC state=herd_wildnpc can_enter=false reason=not_caveman_or_clansman npc_type=woman
[2026-02-16T13:26:13] [INFO] [NPC] STATE_EXIT: WUEC exited wander after 0.4s npc=WUEC state=wander duration_s=0.4
[2026-02-16T13:26:13] [INFO] [NPC] State exited: WUEC left wander npc=WUEC state=wander
[2026-02-16T13:26:13] [INFO] [NPC] STATE_ENTRY: WUEC entered idle (from wander) npc=WUEC state=idle from_state=wander
[2026-02-16T13:26:13] [INFO] [NPC] State entered: WUEC entered idle npc=WUEC state=idle
[Assign] Goat 1218 entry clan=OKOK assigned=true
[Assign] Goat 1218 assign_success -> @Node2D@617 dist=3
[2026-02-16T13:26:14] [INFO] [INVENTORY] PlayerInventoryUI opened
Player inventory toggled: OPEN
🔍 INVENTORY_UI: setup() called
   - inventory: <RefCounted#-9223371688744316937> (valid: true)
🔍 INVENTORY UI SETUP: Setting inventory_data from <RefCounted#-9223371688744316937> to <RefCounted#-9223371688744316937> (slot_count=6)
   - Calling _build_slots() deferred...
   - Calling _update_all_slots() deferred...
✅ INVENTORY_UI: setup() completed
DEBUG _update_title: is_corpse=false, land_claim=<null>, building=@Node2D@617:<Node2D#348009795497>
DEBUG _update_title: is_corpse=false, land_claim=<null>, building=@Node2D@617:<Node2D#348009795497>
🔵 Building inventory opened for Dairy Farm
DEBUG _update_title: is_corpse=false, land_claim=<null>, building=@Node2D@617:<Node2D#348009795497>
🔍 BUILDING UI SHOW: inventory_data instance: <RefCounted#-9223371688744316937> (slot_count=6, can_stack=true)
🔍 BUILDING UI SHOW: Raw slots array: [<null>, <null>, <null>, <null>, <null>, <null>]
🔍 BUILDING UI SHOW: Slot 0: null
🔍 BUILDING UI SHOW: Slot 1: null
🔍 BUILDING UI SHOW: Slot 2: null
🔍 BUILDING UI SHOW: Slot 3: null
🔍 BUILDING UI SHOW: Slot 4: null
🔍 BUILDING UI SHOW: Slot 5: null
📦 LAND CLAIM INVENTORY: Total items: 0 | Breakdown: empty
[2026-02-16T13:26:14] [INFO] [INVENTORY] BuildingInventoryUI opened
DEBUG _update_title: is_corpse=false, land_claim=<null>, building=@Node2D@617:<Node2D#348009795497>
[2026-02-16T13:26:14] [DEBUG] [NPC] Can enter check: PUIK cannot enter agro (not_caveman) npc=PUIK state=agro can_enter=false reason=not_caveman npc_type=woman
[2026-02-16T13:26:14] [DEBUG] [NPC] Priority eval: PUIK - agro (priority=15.0, can_enter=false) npc=PUIK state=agro priority=15.0 can_enter=false
[2026-02-16T13:26:14] [DEBUG] [NPC] Priority eval: PUIK - combat (priority=12.0, can_enter=false) npc=PUIK state=combat priority=12.0 can_enter=false
[2026-02-16T13:26:14] [DEBUG] [NPC] Can enter check: PUIK cannot enter herd (not_herded) npc=PUIK state=herd can_enter=false reason=not_herded herder=unknown
[2026-02-16T13:26:14] [DEBUG] [NPC] Priority eval: PUIK - herd (priority=11.0, can_enter=false) npc=PUIK state=herd priority=11.0 can_enter=false
[2026-02-16T13:26:14] [DEBUG] [NPC] Priority eval: PUIK - raid (priority=8.5, can_enter=false) npc=PUIK state=raid priority=8.5 can_enter=false
[2026-02-16T13:26:14] [DEBUG] [NPC] Priority eval: PUIK - reproduction (priority=8.0, can_enter=false) npc=PUIK state=reproduction priority=8.0 can_enter=false
[2026-02-16T13:26:14] [DEBUG] [NPC] Priority eval: PUIK - occupy_building (priority=7.5, can_enter=false) npc=PUIK state=occupy_building priority=7.5 can_enter=false
[2026-02-16T13:26:14] [DEBUG] [NPC] Priority eval: PUIK - work_at_building (priority=7.0, can_enter=false) npc=PUIK state=work_at_building priority=7.0 can_enter=false
[2026-02-16T13:26:14] [DEBUG] [NPC] Can enter check: PUIK cannot enter seek (no_target) npc=PUIK state=seek can_enter=false reason=no_target
[Assign] Goat 1218 assign_success -> @Node2D@617 dist=1
DEBUG _find_land_claim: Using cached land claim, inventory - Wood: 0, Grain: 0
DEBUG _find_land_claim: Using cached land claim, inventory - Wood: 0, Grain: 0
DEBUG _find_land_claim: Using cached land claim, inventory - Wood: 0, Grain: 0
DEBUG _find_land_claim: Using cached land claim, inventory - Wood: 0, Grain: 0
[Assign] Goat 1218 add_animal_attempt -> @Node2D@617 dist=0 (enter_range=220)
TASK SYSTEM LOGGER: Called at time 118.1
[2026-02-16T13:26:15] [INFO] [INVENTORY] === TASK SYSTEM LOG: 1 Land Claims ===
[2026-02-16T13:26:15] [INFO] [INVENTORY] LAND CLAIM: OKOK | Pos: (-1050, 689) | Inventory: empty clan_name=OKOK position=(-1049.549, 688.502) inventory=[]
[2026-02-16T13:26:15] [INFO] [INVENTORY] TASK SYSTEM DEBUG: buildings group=5, with building_type=4, ovens=0
[2026-02-16T13:26:15] [INFO] [INVENTORY] === TASK SYSTEM LOG: 0 Ovens ===
[2026-02-16T13:26:15] [INFO] [NPC] POSITION: GEEZ at (331.0, 474.4), state=wander, distance_to_claim=0.0/400.0, velocity=64.2 npc=GEEZ pos=331.0,474.4 state=wander distance_to_claim=0.0 claim_radius=400.0 velocity=64.2
[2026-02-16T13:26:15] [DEBUG] [NPC] Can enter check: Goat 1419 cannot enter agro (not_caveman) npc=Goat 1419 state=agro can_enter=false reason=not_caveman npc_type=goat
[2026-02-16T13:26:15] [DEBUG] [NPC] Priority eval: Goat 1419 - agro (priority=15.0, can_enter=false) npc=Goat 1419 state=agro priority=15.0 can_enter=false
[2026-02-16T13:26:15] [DEBUG] [NPC] Priority eval: Goat 1419 - combat (priority=12.0, can_enter=false) npc=Goat 1419 state=combat priority=12.0 can_enter=false
[2026-02-16T13:26:15] [DEBUG] [NPC] Can enter check: Goat 1419 cannot enter herd (not_herded) npc=Goat 1419 state=herd can_enter=false reason=not_herded herder=unknown
[2026-02-16T13:26:15] [DEBUG] [NPC] Priority eval: Goat 1419 - herd (priority=11.0, can_enter=false) npc=Goat 1419 state=herd priority=11.0 can_enter=false
[2026-02-16T13:26:15] [DEBUG] [NPC] Priority eval: Goat 1419 - raid (priority=8.5, can_enter=false) npc=Goat 1419 state=raid priority=8.5 can_enter=false
[2026-02-16T13:26:15] [DEBUG] [NPC] Priority eval: Goat 1419 - reproduction (priority=8.0, can_enter=false) npc=Goat 1419 state=reproduction priority=8.0 can_enter=false
[2026-02-16T13:26:15] [DEBUG] [NPC] Priority eval: Goat 1419 - occupy_building (priority=7.5, can_enter=false) npc=Goat 1419 state=occupy_building priority=7.5 can_enter=false
[2026-02-16T13:26:15] [DEBUG] [NPC] Priority eval: Goat 1419 - work_at_building (priority=7.0, can_enter=false) npc=Goat 1419 state=work_at_building priority=7.0 can_enter=false
[Assign] Goat 1218 assign_success -> @Node2D@617 dist=0
[2026-02-16T13:26:16] [INFO] [NPC] POSITION: GEEZ at (295.9, 474.0), state=wander, distance_to_claim=0.0/400.0, velocity=95.2 npc=GEEZ pos=295.9,474.0 state=wander distance_to_claim=0.0 claim_radius=400.0 velocity=95.2
[2026-02-16T13:26:16] [DEBUG] [NPC] Can enter check: Goat 1218 cannot enter herd (not_herded) npc=Goat 1218 state=herd can_enter=false reason=not_herded herder=unknown
[2026-02-16T13:26:16] [DEBUG] [NPC] Priority eval: Goat 1218 - herd (priority=15.0, can_enter=false) npc=Goat 1218 state=herd priority=15.0 can_enter=false
[2026-02-16T13:26:16] [DEBUG] [NPC] Can enter check: Goat 1218 cannot enter agro (not_caveman) npc=Goat 1218 state=agro can_enter=false reason=not_caveman npc_type=goat
[2026-02-16T13:26:16] [DEBUG] [NPC] Priority eval: Goat 1218 - agro (priority=15.0, can_enter=false) npc=Goat 1218 state=agro priority=15.0 can_enter=false
[2026-02-16T13:26:16] [DEBUG] [NPC] Priority eval: Goat 1218 - combat (priority=12.0, can_enter=false) npc=Goat 1218 state=combat priority=12.0 can_enter=false
[2026-02-16T13:26:16] [DEBUG] [NPC] Priority eval: Goat 1218 - work_at_building (priority=9.0, can_enter=false) npc=Goat 1218 state=work_at_building priority=9.0 can_enter=false
[2026-02-16T13:26:16] [DEBUG] [NPC] Priority eval: Goat 1218 - raid (priority=8.5, can_enter=false) npc=Goat 1218 state=raid priority=8.5 can_enter=false
[2026-02-16T13:26:16] [DEBUG] [NPC] Priority eval: Goat 1218 - reproduction (priority=8.0, can_enter=false) npc=Goat 1218 state=reproduction priority=8.0 can_enter=false
[2026-02-16T13:26:16] [DEBUG] [NPC] Priority eval: Goat 1218 - occupy_building (priority=7.5, can_enter=false) npc=Goat 1218 state=occupy_building priority=7.5 can_enter=false
[Assign] Goat 1218 assign_success -> @Node2D@617 dist=2
DEBUG _find_land_claim: Using cached land claim, inventory - Wood: 0, Grain: 0
DEBUG _find_land_claim: Using cached land claim, inventory - Wood: 0, Grain: 0
DEBUG _find_land_claim: Using cached land claim, inventory - Wood: 0, Grain: 0
DEBUG _find_land_claim: Using cached land claim, inventory - Wood: 0, Grain: 0
[Assign] Goat 1218 assign_success -> @Node2D@617 dist=2
FSM: Creating states for WERE - idle:OK wander:OK seek:OK eat:OK gather:OK herd:OK herd_wildnpc:OK agro:OK build:OK
FSM: Successfully created eat state for WERE
FSM: Successfully created gather state for WERE
FSM: Successfully created herd state for WERE
FSM: Successfully created herd_wildnpc state for WERE
FSM: Successfully created agro state for WERE
FSM: Successfully created combat state for WERE
FSM: Successfully created defend state for WERE
FSM: Successfully created raid state for WERE
FSM: Successfully created search state for WERE
FSM: Successfully created build state for WERE
FSM: Successfully created reproduction state for WERE
FSM: Successfully created occupy_building state for WERE
FSM: Successfully created work_at_building state for WERE
FSM: Successfully created craft state for WERE
Task System: Created TaskRunner component for WERE
✓ REPRODUCTION: WUYA gave birth to baby (clan: OKOK)
✓ Spawned Baby: WERE at (-1049.549, 688.502) (clan: OKOK, mother: WUYA, father: OKOK)
[2026-02-16T13:26:17] [INFO] [NPC] POSITION: GEEZ at (290.9, 466.4), state=wander, distance_to_claim=0.0/400.0, velocity=40.9 npc=GEEZ pos=290.9,466.4 state=wander distance_to_claim=0.0 claim_radius=400.0 velocity=40.9
[2026-02-16T13:26:17] [DEBUG] [NPC] Can enter check: BIYU cannot enter agro (not_caveman) npc=BIYU state=agro can_enter=false reason=not_caveman npc_type=woman
[2026-02-16T13:26:17] [DEBUG] [NPC] Priority eval: BIYU - agro (priority=15.0, can_enter=false) npc=BIYU state=agro priority=15.0 can_enter=false
[2026-02-16T13:26:17] [DEBUG] [NPC] Priority eval: BIYU - combat (priority=12.0, can_enter=false) npc=BIYU state=combat priority=12.0 can_enter=false
[2026-02-16T13:26:17] [DEBUG] [NPC] Can enter check: BIYU cannot enter herd (not_herded) npc=BIYU state=herd can_enter=false reason=not_herded herder=unknown
[2026-02-16T13:26:17] [DEBUG] [NPC] Priority eval: BIYU - herd (priority=11.0, can_enter=false) npc=BIYU state=herd priority=11.0 can_enter=false
[2026-02-16T13:26:17] [DEBUG] [NPC] Priority eval: BIYU - raid (priority=8.5, can_enter=false) npc=BIYU state=raid priority=8.5 can_enter=false
[2026-02-16T13:26:17] [DEBUG] [NPC] Priority eval: BIYU - reproduction (priority=8.0, can_enter=false) npc=BIYU state=reproduction priority=8.0 can_enter=false
[2026-02-16T13:26:17] [DEBUG] [NPC] Priority eval: BIYU - occupy_building (priority=7.5, can_enter=false) npc=BIYU state=occupy_building priority=7.5 can_enter=false
[2026-02-16T13:26:17] [DEBUG] [NPC] Priority eval: BIYU - work_at_building (priority=7.0, can_enter=false) npc=BIYU state=work_at_building priority=7.0 can_enter=false
[Assign] Goat 1218 add_animal_attempt -> @Node2D@617 dist=0 (enter_range=220)
[2026-02-16T13:26:18] [INFO] [INVENTORY] PlayerInventoryUI closed
Player inventory toggled: CLOSED
🔍 INVENTORY_UI: setup() called
   - inventory: <RefCounted#-9223371688744316937> (valid: true)
🔍 INVENTORY UI SETUP: Setting inventory_data from <RefCounted#-9223371688744316937> to <RefCounted#-9223371688744316937> (slot_count=6)
   - Calling _build_slots() deferred...
   - Calling _update_all_slots() deferred...
✅ INVENTORY_UI: setup() completed
DEBUG _update_title: is_corpse=false, land_claim=<null>, building=@Node2D@617:<Node2D#348009795497>
DEBUG _update_title: is_corpse=false, land_claim=<null>, building=@Node2D@617:<Node2D#348009795497>
🔵 Building inventory opened for Dairy Farm
[2026-02-16T13:26:18] [INFO] [INVENTORY] BuildingInventoryUI closed
DEBUG _update_title: is_corpse=false, land_claim=<null>, building=@Node2D@617:<Node2D#348009795497>
[Assign] Goat 1218 assign_success -> @Node2D@617 dist=3
TASK SYSTEM LOGGER: Called at time 121.2
[2026-02-16T13:26:18] [INFO] [INVENTORY] === TASK SYSTEM LOG: 1 Land Claims ===
[2026-02-16T13:26:18] [INFO] [INVENTORY] LAND CLAIM: OKOK | Pos: (-1050, 689) | Inventory: empty clan_name=OKOK position=(-1049.549, 688.502) inventory=[]
[2026-02-16T13:26:18] [INFO] [INVENTORY] TASK SYSTEM DEBUG: buildings group=5, with building_type=4, ovens=0
[2026-02-16T13:26:18] [INFO] [INVENTORY] === TASK SYSTEM LOG: 0 Ovens ===
[2026-02-16T13:26:19] [DEBUG] [NPC] Can enter check: WUYA cannot enter herd (not_herded) npc=WUYA state=herd can_enter=false reason=not_herded herder=unknown
[2026-02-16T13:26:19] [DEBUG] [NPC] Priority eval: WUYA - herd (priority=15.0, can_enter=false) npc=WUYA state=herd priority=15.0 can_enter=false
[2026-02-16T13:26:19] [DEBUG] [NPC] Can enter check: WUYA cannot enter agro (not_caveman) npc=WUYA state=agro can_enter=false reason=not_caveman npc_type=woman
[2026-02-16T13:26:19] [DEBUG] [NPC] Priority eval: WUYA - agro (priority=15.0, can_enter=false) npc=WUYA state=agro priority=15.0 can_enter=false
[2026-02-16T13:26:19] [DEBUG] [NPC] Priority eval: WUYA - combat (priority=12.0, can_enter=false) npc=WUYA state=combat priority=12.0 can_enter=false
[2026-02-16T13:26:19] [DEBUG] [NPC] Evaluated 3 states: herd(priority=15.0,can_enter=false) agro(priority=15.0,can_enter=false) combat(priority=12.0,can_enter=false) -> Best: work_at_building (priority=9.0) npc=WUYA best_state=work_at_building best_priority=9.0
[2026-02-16T13:26:19] [INFO] [NPC] POSITION: GEEZ at (280.1, 422.8), state=wander, distance_to_claim=0.0/400.0, velocity=57.0 npc=GEEZ pos=280.1,422.8 state=wander distance_to_claim=0.0 claim_radius=400.0 velocity=57.0
[2026-02-16T13:26:19] [DEBUG] [NPC] Can enter check: JOEC cannot enter agro (not_caveman) npc=JOEC state=agro can_enter=false reason=not_caveman npc_type=woman
[2026-02-16T13:26:19] [DEBUG] [NPC] Priority eval: JOEC - agro (priority=15.0, can_enter=false) npc=JOEC state=agro priority=15.0 can_enter=false
[2026-02-16T13:26:19] [DEBUG] [NPC] Priority eval: JOEC - combat (priority=12.0, can_enter=false) npc=JOEC state=combat priority=12.0 can_enter=false
🎨 ANIMATION: _load_attack_sprite_sheet() called
🎨 ANIMATION: Loading sprite sheet from: res://assets/sprites/swingclub.png
✅ ANIMATION: Sprite sheet loaded successfully
🎨 ANIMATION: Texture dimensions - width=840, height=560
✅ ANIMATION: Frame size: 280x280 (grid 3x2)
✅ ANIMATION: Default sprite texture stored
FSM: Creating states for CEFI - idle:OK wander:OK seek:OK eat:OK gather:OK herd:OK herd_wildnpc:OK agro:OK build:OK
FSM: Successfully created eat state for CEFI
FSM: Successfully created gather state for CEFI
FSM: Successfully created herd state for CEFI
FSM: Successfully created herd_wildnpc state for CEFI
FSM: Successfully created agro state for CEFI
FSM: Successfully created combat state for CEFI
FSM: Successfully created defend state for CEFI
FSM: Successfully created raid state for CEFI
FSM: Successfully created search state for CEFI
FSM: Successfully created build state for CEFI
FSM: Successfully created reproduction state for CEFI
FSM: Successfully created occupy_building state for CEFI
FSM: Successfully created work_at_building state for CEFI
FSM: Successfully created craft state for CEFI
Task System: Created TaskRunner component for CEFI
🎨 ANIMATION: _load_attack_sprite_sheet() called
🎨 ANIMATION: Loading sprite sheet from: res://assets/sprites/swingclub.png
✅ ANIMATION: Sprite sheet loaded successfully
🎨 ANIMATION: Texture dimensions - width=840, height=560
✅ ANIMATION: Frame size: 280x280 (grid 3x2)
✅ ANIMATION: Default sprite texture stored
FSM: Creating states for Sheep 121219 - idle:OK wander:OK seek:OK eat:OK gather:OK herd:OK herd_wildnpc:OK agro:OK build:OK
FSM: Successfully created eat state for Sheep 121219
FSM: Successfully created gather state for Sheep 121219
FSM: Successfully created herd state for Sheep 121219
FSM: Successfully created herd_wildnpc state for Sheep 121219
FSM: Successfully created agro state for Sheep 121219
FSM: Successfully created combat state for Sheep 121219
FSM: Successfully created defend state for Sheep 121219
FSM: Successfully created raid state for Sheep 121219
FSM: Successfully created search state for Sheep 121219
FSM: Successfully created build state for Sheep 121219
FSM: Successfully created reproduction state for Sheep 121219
FSM: Successfully created occupy_building state for Sheep 121219
FSM: Successfully created work_at_building state for Sheep 121219
FSM: Successfully created craft state for Sheep 121219
Task System: Created TaskRunner component for Sheep 121219
✓ Respawned Wild Sheep: Sheep 121219 at (-1493.808, 1427.816)
✓ Respawned Wild Woman: CEFI at (-997.7572, 48.77856) (agility 9.0 = 288.0 speed)
[2026-02-16T13:26:19] [WARNING] [NPC] STATE_DURATION: CEFI in wander for 121.3s (LONG - potentially stuck!) npc=CEFI state=wander duration_s=121.3 warning=potentially_stuck
[2026-02-16T13:26:19] [WARNING] [NPC] STATE_DURATION: WERE in wander for 121.6s (LONG - potentially stuck!) npc=WERE state=wander duration_s=121.6 warning=potentially_stuck
[2026-02-16T13:26:19] [WARNING] [NPC] STATE_DURATION: Sheep 121219 in wander for 121.6s (LONG - potentially stuck!) npc=Sheep 121219 state=wander duration_s=121.6 warning=potentially_stuck
[Assign] Goat 1218 entry clan=OKOK assigned=false
[ASSIGN] Goat 1218 ClaimBuildingIndex returned 4 buildings for claim OKOK
[Assign] Goat 1218 assign_success -> @Node2D@617 dist=3
DEBUG _find_land_claim: Using cached land claim, inventory - Wood: 0, Grain: 0
DEBUG _find_land_claim: Using cached land claim, inventory - Wood: 0, Grain: 0
DEBUG _find_land_claim: Using cached land claim, inventory - Wood: 0, Grain: 0
DEBUG _find_land_claim: Using cached land claim, inventory - Wood: 0, Grain: 0
Task System: WUYA found 5 same-clan building(s) but no job (last reason: missing inputs)
[2026-02-16T13:26:20] [DEBUG] [NPC] Can enter check: WUEC cannot enter agro (not_caveman) npc=WUEC state=agro can_enter=false reason=not_caveman npc_type=woman
[2026-02-16T13:26:20] [DEBUG] [NPC] Priority eval: WUEC - agro (priority=15.0, can_enter=false) npc=WUEC state=agro priority=15.0 can_enter=false
[2026-02-16T13:26:20] [DEBUG] [NPC] Priority eval: WUEC - combat (priority=12.0, can_enter=false) npc=WUEC state=combat priority=12.0 can_enter=false
[2026-02-16T13:26:20] [DEBUG] [NPC] Can enter check: WUEC cannot enter herd (not_herded) npc=WUEC state=herd can_enter=false reason=not_herded herder=unknown
[2026-02-16T13:26:20] [DEBUG] [NPC] Priority eval: WUEC - herd (priority=11.0, can_enter=false) npc=WUEC state=herd priority=11.0 can_enter=false
[2026-02-16T13:26:20] [DEBUG] [NPC] Priority eval: WUEC - raid (priority=8.5, can_enter=false) npc=WUEC state=raid priority=8.5 can_enter=false
[2026-02-16T13:26:20] [DEBUG] [NPC] Priority eval: WUEC - reproduction (priority=8.0, can_enter=false) npc=WUEC state=reproduction priority=8.0 can_enter=false
[2026-02-16T13:26:20] [DEBUG] [NPC] Priority eval: WUEC - occupy_building (priority=7.5, can_enter=false) npc=WUEC state=occupy_building priority=7.5 can_enter=false
[2026-02-16T13:26:20] [DEBUG] [NPC] Priority eval: WUEC - work_at_building (priority=7.0, can_enter=false) npc=WUEC state=work_at_building priority=7.0 can_enter=false
[2026-02-16T13:26:20] [DEBUG] [NPC] Can enter check: WUEC cannot enter seek (no_target) npc=WUEC state=seek can_enter=false reason=no_target
[Assign] Goat 1218 assign_success -> @Node2D@617 dist=2
[Assign] Goat 1218 add_animal_attempt -> @Node2D@617 dist=2 (enter_range=220)
🏆 Competition: No deposits recorded yet
[2026-02-16T13:26:21] [DEBUG] [NPC] Can enter check: WUYA cannot enter herd (not_herded) npc=WUYA state=herd can_enter=false reason=not_herded herder=unknown
[2026-02-16T13:26:21] [DEBUG] [NPC] Priority eval: WUYA - herd (priority=15.0, can_enter=false) npc=WUYA state=herd priority=15.0 can_enter=false
[2026-02-16T13:26:21] [DEBUG] [NPC] Can enter check: WUYA cannot enter agro (not_caveman) npc=WUYA state=agro can_enter=false reason=not_caveman npc_type=woman
[2026-02-16T13:26:21] [DEBUG] [NPC] Priority eval: WUYA - agro (priority=15.0, can_enter=false) npc=WUYA state=agro priority=15.0 can_enter=false
[2026-02-16T13:26:21] [DEBUG] [NPC] Priority eval: WUYA - combat (priority=12.0, can_enter=false) npc=WUYA state=combat priority=12.0 can_enter=false
[2026-02-16T13:26:21] [DEBUG] [NPC] Evaluated 3 states: herd(priority=15.0,can_enter=false) agro(priority=15.0,can_enter=false) combat(priority=12.0,can_enter=false) -> Best: work_at_building (priority=9.0) npc=WUYA best_state=work_at_building best_priority=9.0
[2026-02-16T13:26:21] [INFO] [NPC] POSITION: XIUF at (-112.8, 429.3), state=wander, distance_to_claim=0.0/400.0, velocity=22.0 npc=XIUF pos=-112.8,429.3 state=wander distance_to_claim=0.0 claim_radius=400.0 velocity=22.0
[2026-02-16T13:26:21] [INFO] [NPC] POSITION: Goat 1218 at (-852.6, 751.6), state=wander, distance_to_claim=206.8/400.0, velocity=0.0 npc=Goat 1218 pos=-852.6,751.6 state=wander distance_to_claim=206.8 claim_radius=400.0 velocity=0.0
[Assign] Goat 1218 assign_success -> @Node2D@617 dist=2
[2026-02-16T13:26:21] [DEBUG] [NPC] Steering behavior: SEEK - position npc=Goat 1218 behavior=SEEK target=position position=-852.6,750.0
[2026-02-16T13:26:21] [INFO] [NPC] Action started: assign_to_building (building: Dairy Farm) npc=Goat 1218 action=assign_to_building target=Dairy Farm npc_type=goat building=@Node2D@617 distance=1.6
