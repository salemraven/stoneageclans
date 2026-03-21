# Stone Age Clans – Dev Menu Specification

**Date**: January 2026  
**Status**: Planning Document  
**Purpose**: Comprehensive in-game developer menu for testing, debugging, and game balancing

---

## Overview

The Dev Menu is an in-game overlay accessible via a key binding (e.g., `F1` or `~`) that provides developers and testers with tools to manipulate game state, spawn entities, modify values, and debug systems. All dev menu features should be clearly marked and disabled in production builds.

---

## 1. Player Controls

### Player State Modifiers

**God Mode**
- Toggle player invincibility (no damage taken)
- Visual indicator when active (e.g., glow effect, icon)
- Default: OFF

**Invisibility Mode**
- Toggle player visibility to NPCs
- NPCs cannot detect/interact with invisible player
- Visual indicator when active
- Default: OFF

**No Clip / Fly Mode**
- Toggle collision detection for player
- Allow player to move through walls/terrain
- Optional: Fly mode (vertical movement enabled)
- Default: OFF

**Speed Multiplier**
- Slider: 0.1x to 10x movement speed
- Default: 1.0x
- Real-time adjustment

**Teleport**
- Input field: X, Y coordinates
- Button: "Teleport to Coordinates"
- Button: "Teleport to Mouse Position" (teleport to current mouse world position)
- Button: "Teleport to Nearest NPC"
- Button: "Teleport to Nearest Building"
- Button: "Teleport to Nearest Corpse"

**Player Stats**
- Display current player stats (health, age, clan, etc.)
- Modify player stats (health, age, etc.)
- Set player name/clan name

---

## 2. Spawning System

### NPC Spawning

**Spawn Caveman**
- Button: "Spawn Caveman at Player"
- Button: "Spawn Caveman at Mouse"
- Input: Number of cavemen to spawn (1-100)
- Options:
  - Set agro meter (0-100)
  - Equip weapon (dropdown: None, Axe, etc.)
  - Set age (13-50)
  - Set clan name (or leave wild)

**Spawn Clansman**
- Button: "Spawn Clansman at Player"
- Button: "Spawn Clansman at Mouse"
- Input: Number of clansmen to spawn (1-100)
- Options:
  - Set clan name (required)
  - Equip weapon
  - Set age

**Spawn Woman**
- Button: "Spawn Woman at Player"
- Button: "Spawn Woman at Mouse"
- Input: Number of women to spawn (1-100)
- Options:
  - Set age
  - Set clan name (or leave wild)

**Spawn Animal**
- Dropdown: Animal type (Sheep, Goat, Horse, etc.)
- Button: "Spawn at Player"
- Button: "Spawn at Mouse"
- Input: Number to spawn (1-100)

**Spawn NPC (Generic)**
- Dropdown: NPC type (all available types)
- Input: Number to spawn
- Button: "Spawn at Player"
- Button: "Spawn at Mouse"
- Options: All NPC-specific options

### Resource Spawning

**Spawn Resource Node**
- Dropdown: Resource type (Tree, Boulder, Berry Bush, Wheat, etc.)
- Button: "Spawn at Player"
- Button: "Spawn at Mouse"
- Input: Number to spawn (1-100)
- Options:
  - Set resource quantity/health
  - Set respawn timer (if applicable)

**Spawn Ground Item**
- Dropdown: Item type (Axe, Berry, Wood, Stone, etc.)
- Button: "Spawn at Player"
- Button: "Spawn at Mouse"
- Input: Number to spawn (1-100)
- Input: Stack size (1-999)

### Building Spawning

**Spawn Land Claim**
- Button: "Spawn at Player"
- Button: "Spawn at Mouse"
- Options:
  - Set clan name
  - Set radius
  - Set upgrade level (Flag, Tower, Keep, Castle)

**Spawn Building**
- Dropdown: Building type (Living Hut, Farm, Spinner, etc.)
- Button: "Spawn at Player"
- Button: "Spawn at Mouse"
- Options:
  - Assign woman (if required)
  - Set inventory contents

---

## 3. World & Environment

### Time & Game Speed

**Time Scale**
- Slider: 0.1x to 10x game speed
- Default: 1.0x
- Real-time adjustment
- Display: Current time scale

**Day/Night Cycle** (if implemented)
- Toggle: Enable/disable day/night cycle
- Slider: Set time of day
- Button: "Skip to Dawn"
- Button: "Skip to Dusk"

**Pause/Unpause**
- Toggle: Pause all game logic
- Visual indicator when paused

### World Settings

**Resource Spawn Rates**
- Slider: Global resource spawn multiplier (0.1x to 10x)
- Individual resource type spawn rates:
  - Trees: Spawn rate multiplier
  - Boulders: Spawn rate multiplier
  - Berry Bushes: Spawn rate multiplier
  - Wheat: Spawn rate multiplier
  - Animals: Spawn rate multiplier
- Default: 1.0x for all

**Resource Respawn Timer**
- Slider: Global respawn timer multiplier (0.1x to 10x)
- Faster respawn = lower multiplier
- Default: 1.0x

**World Size / Chunk Settings**
- Display: Current chunk count
- Input: Chunk render distance
- Button: "Regenerate World"
- Button: "Clear All Resources"

---

## 4. NPC Management

### NPC Controls

**Kill All NPCs**
- Button: "Kill All NPCs"
- Confirmation dialog: "Are you sure?"
- Options:
  - Kill all NPCs
  - Kill all enemies
  - Kill all friendly
  - Kill all wild

**Kill Nearest NPC**
- Button: "Kill Nearest NPC to Player"
- Button: "Kill Nearest NPC to Mouse"

**Modify NPC**
- Button: "Select NPC" (click on NPC in world)
- Display: Selected NPC info (name, type, stats, etc.)
- Options:
  - Set health (0-100)
  - Set agro meter (0-100)
  - Set age
  - Set clan name
  - Equip/unequip weapon
  - Add item to inventory
  - Clear inventory
  - Force state (idle, wander, combat, etc.)

**NPC Spawn Rates**
- Slider: Global NPC spawn multiplier (0.1x to 10x)
- Individual NPC type spawn rates:
  - Cavemen: Spawn rate multiplier
  - Women: Spawn rate multiplier
  - Animals: Spawn rate multiplier
- Default: 1.0x for all

**NPC Behavior**
- Toggle: Disable NPC AI (freeze all NPCs)
- Toggle: Disable NPC combat
- Toggle: Disable NPC gathering
- Toggle: Disable NPC herding
- Toggle: Disable NPC building

**NPC Stats Display**
- Toggle: Show NPC health bars
- Toggle: Show NPC names
- Toggle: Show NPC states (idle, wander, combat, etc.)
- Toggle: Show NPC paths/steering vectors
- Toggle: Show NPC agro meters

---

## 5. Combat & Damage

### Combat Settings

**Damage Multipliers**
- Slider: Player damage multiplier (0.1x to 10x)
- Slider: NPC damage multiplier (0.1x to 10x)
- Default: 1.0x for both

**Health Settings**
- Slider: Player max HP (1-9999)
- Slider: NPC max HP multiplier (0.1x to 10x)
- Default: 1.0x

**Combat Behavior**
- Toggle: Disable all combat
- Toggle: One-hit kill mode (all entities die in 1 hit)
- Toggle: Invincible NPCs (NPCs take no damage)
- Toggle: Invincible player (player takes no damage)

**Corpse Settings**
- Slider: Corpse to bones timer (seconds, 1-300)
- Slider: Bones despawn timer (seconds, 1-300)
- Default: 60 seconds each
- Toggle: Disable corpse decomposition

---

## 6. Inventory & Items

### Item Management

**Give Item to Player**
- Dropdown: Item type (all available items)
- Input: Quantity (1-999)
- Button: "Give to Player"
- Options:
  - Add to inventory
  - Add to hotbar (specify slot)
  - Drop at player position

**Clear Player Inventory**
- Button: "Clear Player Inventory"
- Button: "Clear Player Hotbar"
- Confirmation dialog

**Set Player Inventory Size**
- Input: Main inventory slots (1-50)
- Input: Hotbar slots (1-20)
- Button: "Apply"

**Item Spawn Rates** (if applicable)
- Slider: Ground item spawn multiplier
- Slider: Loot drop rate multiplier

---

## 7. Building & Construction

### Building Controls

**Instant Build**
- Toggle: All buildings build instantly (no construction time)
- Default: OFF

**Building Requirements**
- Toggle: Disable resource requirements for building
- Toggle: Disable land claim requirements

**Building Spawn Rates**
- Slider: Building construction speed multiplier (0.1x to 10x)
- Default: 1.0x

**Land Claim Settings**
- Slider: Land claim radius multiplier (0.1x to 10x)
- Toggle: Disable land claim restrictions
- Toggle: Allow building outside land claims

---

## 8. Herding & Clans

### Herding Controls

**Auto-Herd**
- Button: "Herd All Nearby NPCs" (all NPCs within range follow player)
- Input: Herd range (pixels)
- Toggle: Disable herd breaking

**Clan Management**
- Input: Set player clan name
- Button: "Create New Clan"
- Button: "Join Nearest Clan"
- Button: "Leave Current Clan"

**Clan Settings**
- Toggle: Disable clan restrictions
- Toggle: Allow cross-clan interactions

---

## 9. Reproduction & Baby Pool

### Reproduction Controls

**Reproduction Settings**
- Slider: Reproduction rate multiplier (0.1x to 10x)
- Toggle: Instant reproduction (no timer)
- Toggle: Disable reproduction

**Baby Pool**
- Display: Current baby pool count
- Display: Baby pool capacity
- Input: Set baby pool count
- Input: Set baby pool capacity
- Button: "Add Baby to Pool"
- Button: "Clear Baby Pool"

**Living Hut Settings**
- Slider: Living Hut capacity bonus multiplier (0.1x to 10x)
- Default: 1.0x

---

## 10. Debug Visualization

### Visual Debug Tools

**Show Paths**
- Toggle: Show NPC pathfinding paths
- Toggle: Show player path
- Color coding for different path types

**Show Hitboxes**
- Toggle: Show collision boxes
- Toggle: Show interaction ranges
- Toggle: Show attack ranges

**Show AI States**
- Toggle: Show NPC FSM states (idle, wander, combat, etc.)
- Text overlay on NPCs showing current state
- Color coding for different states

**Show Steering Vectors**
- Toggle: Show NPC steering vectors
- Toggle: Show separation forces
- Toggle: Show alignment forces
- Toggle: Show cohesion forces

**Show Inventory Slots**
- Toggle: Show all NPC inventories (visual overlay)
- Toggle: Show building inventories

**Show Land Claims**
- Toggle: Show land claim boundaries (visual circles)
- Toggle: Show land claim ownership (color coding)

**Show Resource Nodes**
- Toggle: Highlight all resource nodes
- Toggle: Show resource quantities/health

**Show Corpses**
- Toggle: Highlight all corpses
- Toggle: Show corpse decomposition timers

**Grid Overlay**
- Toggle: Show world grid
- Toggle: Show chunk boundaries
- Input: Grid size

**Camera Controls**
- Button: "Reset Camera to Player"
- Input: Camera zoom level
- Slider: Camera zoom (0.1x to 5x)
- Toggle: Lock camera to player

---

## 11. Statistics & Logging

### Real-Time Statistics

**Performance Stats**
- Display: FPS (frames per second)
- Display: Frame time (ms)
- Display: Memory usage
- Display: Active NPC count
- Display: Active resource count
- Display: Active building count

**Game Statistics**
- Display: Total NPCs spawned (lifetime)
- Display: Total NPCs killed
- Display: Total items collected
- Display: Total buildings constructed
- Display: Current game time
- Display: Player position (X, Y)
- Display: Player velocity

**NPC Statistics**
- Display: NPC count by type
- Display: NPC count by clan
- Display: Average NPC age
- Display: Average NPC health

**Resource Statistics**
- Display: Resource count by type
- Display: Resource spawn rate
- Display: Resource respawn rate

**Combat Statistics**
- Display: Total damage dealt
- Display: Total damage taken
- Display: Total kills
- Display: Combat events log

### Logging

**Console Output**
- Toggle: Enable debug console
- Toggle: Show all log messages
- Filter: Log level (Debug, Info, Warning, Error)
- Button: "Clear Console"
- Button: "Export Logs to File"

**Event Logging**
- Toggle: Log NPC spawns
- Toggle: Log NPC deaths
- Toggle: Log combat events
- Toggle: Log inventory changes
- Toggle: Log building construction

**Save Logs**
- Button: "Save Current Logs"
- Input: Log file name
- Format: Timestamped log files

---

## 12. Save & Load

### Save System

**Quick Save**
- Button: "Quick Save" (save to dev slot)
- Display: Last save time

**Quick Load**
- Button: "Quick Load" (load from dev slot)
- Confirmation dialog

**Save Management**
- Button: "Save Game"
- Input: Save file name
- Button: "Load Game"
- Dropdown: Available save files
- Button: "Delete Save"

**Reset Game**
- Button: "Reset to Default State"
- Button: "Reset World Only"
- Button: "Reset Player Only"
- Confirmation dialog for all reset options

---

## 13. Camera & View

### Camera Controls

**Camera Position**
- Input: Camera X, Y coordinates
- Button: "Set Camera Position"
- Button: "Reset Camera to Player"

**Camera Zoom**
- Slider: Zoom level (0.1x to 5x)
- Default: 1.0x
- Button: "Reset Zoom"

**Camera Follow**
- Toggle: Lock camera to player
- Toggle: Smooth camera follow
- Slider: Camera follow speed

**View Modes**
- Toggle: Wireframe mode (if applicable)
- Toggle: Show/hide UI
- Toggle: Show/hide world
- Toggle: Show/hide NPCs
- Toggle: Show/hide resources
- Toggle: Show/hide buildings

---

## 14. Testing & Scenarios

### Test Scenarios

**Battle Royale Mode**
- Button: "Start Battle Royale"
- Input: Number of participants (2-50)
- Options:
  - Spawn all participants in circle
  - Give all participants weapons
  - Set max agro
  - Disable land claims

**Stress Test**
- Button: "Spawn 100 NPCs"
- Button: "Spawn 1000 Resources"
- Button: "Spawn 100 Buildings"
- Display: Performance impact

**Combat Test**
- Button: "Spawn Combat Arena"
- Options:
  - Spawn 2 teams of NPCs
  - Set team sizes
  - Give all weapons
  - Set agro to max

**Gathering Test**
- Button: "Spawn Resource Test Area"
- Spawns various resource types in organized area

**Building Test**
- Button: "Spawn Building Test Area"
- Spawns land claim with all building types

### Scenario Presets

**Save Scenario**
- Input: Scenario name
- Button: "Save Current State as Scenario"
- Saves: World state, NPCs, buildings, player state

**Load Scenario**
- Dropdown: Available scenarios
- Button: "Load Scenario"
- Confirmation dialog

**Scenario Management**
- Button: "Delete Scenario"
- List: All saved scenarios

---

## 15. Advanced Settings

### System Settings

**Physics Settings**
- Toggle: Enable/disable physics
- Slider: Gravity multiplier
- Slider: Friction multiplier

**Rendering Settings**
- Toggle: Show/hide sprites
- Toggle: Show/hide particles
- Toggle: Show/hide effects
- Slider: Render distance

**Audio Settings**
- Toggle: Mute all sounds
- Slider: Master volume
- Slider: Music volume
- Slider: SFX volume

**Input Settings**
- Toggle: Disable player input
- Toggle: Disable NPC input
- Display: Last key pressed
- Display: Mouse position (world coordinates)

### Data Management

**Export Data**
- Button: "Export NPC Data" (to JSON/CSV)
- Button: "Export Resource Data"
- Button: "Export Building Data"
- Button: "Export All Game Data"

**Import Data**
- Button: "Import NPC Data"
- Button: "Import Resource Data"
- Button: "Import Building Data"
- File picker for data files

**Clear Data**
- Button: "Clear All NPCs"
- Button: "Clear All Resources"
- Button: "Clear All Buildings"
- Button: "Clear All Corpses"
- Confirmation dialogs

---

## 16. UI & Menu Settings

### Dev Menu Appearance

**Menu Style**
- Toggle: Compact mode (smaller UI)
- Toggle: Always on top
- Toggle: Auto-hide (hide when not in use)
- Slider: Menu opacity (0-100%)

**Hotkeys**
- Display: All dev menu hotkeys
- Button: "Rebind Hotkey" (for each function)
- Input: New key binding

**Menu Organization**
- Toggle: Collapsible sections
- Toggle: Remember last opened section
- Button: "Reset Menu Layout"

---

## 17. Implementation Notes

### Technical Requirements

**Access Control**
- Dev menu only accessible in debug builds
- Optional: Password protection for release builds
- Optional: Admin key/command to enable in release

**Performance**
- Dev menu should have minimal performance impact
- Lazy loading of statistics (update on demand)
- Efficient rendering of debug overlays

**Persistence**
- Dev menu settings should persist between sessions (optional)
- Save dev menu preferences to config file
- Load preferences on startup

**Error Handling**
- All dev menu actions should have error handling
- Invalid inputs should show error messages
- Confirmation dialogs for destructive actions

### UI Layout Suggestions

**Tabbed Interface**
- Main tabs: Player, Spawning, World, NPCs, Combat, Items, Buildings, Debug, Stats, Settings
- Sub-tabs within each main category
- Search/filter functionality

**Collapsible Sections**
- Each category can be collapsed/expanded
- Remember state between sessions

**Quick Actions Panel**
- Frequently used actions in quick access panel
- Customizable quick actions
- Hotkey support for quick actions

**Command Line Interface** (Optional)
- Text input for commands
- Command history
- Auto-complete suggestions
- Help command listing all available commands

---

## 18. Future Enhancements

### Planned Features

- **Scripting Support**: Lua/Python scripting for automated testing
- **Recording/Playback**: Record test scenarios and playback
- **Performance Profiling**: Built-in profiler for performance analysis
- **Network Debugging**: Multiplayer debugging tools (if applicable)
- **AI Visualization**: Advanced AI state visualization
- **Pathfinding Debug**: Visual pathfinding algorithm debugging
- **Memory Profiling**: Detailed memory usage breakdown
- **Save State Comparison**: Compare two save states
- **Automated Testing**: Run test suites automatically

---

## 19. Quick Reference

### Essential Hotkeys (Suggested)

- `F1` or `~`: Toggle dev menu
- `F2`: Quick save
- `F3`: Quick load
- `F4`: Toggle god mode
- `F5`: Toggle invisibility
- `F6`: Toggle no clip
- `F7`: Spawn caveman at player
- `F8`: Spawn clansman at player
- `F9`: Kill nearest NPC
- `F10`: Toggle debug visualization
- `F11`: Show/hide stats overlay
- `F12`: Screenshot (if not used by system)

### Essential Buttons

- **God Mode**: Quick invincibility toggle
- **Spawn Caveman**: Quick NPC spawn
- **Teleport to Mouse**: Quick teleport
- **Kill All**: Quick cleanup
- **Reset Game**: Quick reset
- **Show Stats**: Quick stats overlay

---

## 20. Testing Checklist

### Pre-Release Testing

- [ ] All dev menu features work correctly
- [ ] No performance impact when dev menu is closed
- [ ] Dev menu disabled in release builds
- [ ] All confirmation dialogs work
- [ ] All sliders/inputs validate correctly
- [ ] Statistics update correctly
- [ ] Save/load functions work
- [ ] Spawning functions work for all entity types
- [ ] Debug visualizations render correctly
- [ ] Hotkeys don't conflict with game controls

---

**Note**: This is a comprehensive specification. Not all features need to be implemented immediately. Prioritize based on testing needs and development workflow.

**Priority Levels**:
- **High**: Essential for testing (spawning, god mode, teleport, stats)
- **Medium**: Useful for debugging (visualization, logging, NPC management)
- **Low**: Nice to have (advanced features, scripting, profiling)
