# Browser Multiplayer Roadmap

**Goal:** Get StoneAgeClans running in the browser with multiplayer. Players can spawn, move, and play together.

**Architecture:** Dedicated server (Godot headless or external). WebSocket transport for browser clients.

---

## Phase 1: Browser Export (Single Player)

Get the game running in a browser with no multiplayer. Fix Web-specific breakages.

### 1.1 Export Setup

- [ ] Add Web export preset (Project → Export → Add → Web)
- [ ] Download Web export template (Godot prompts on first export)
- [ ] Export to HTML5 and test locally (e.g. `python -m http.server` or Godot's built-in)
- [ ] Verify game loads and runs in Chrome/Firefox/Safari

### 1.2 Browser Compatibility Fixes

| File | Issue | Fix |
|------|-------|-----|
| `scripts/logging/playtest_instrumentor.gd` | `FileAccess`, `OS.get_cmdline_user_args()`, `OS.get_environment()` | Disable when `OS.get_name() == "Web"`; stub or skip file writes |
| `scripts/logging/playtest_reporter.gd` | Same + `OS.get_user_data_dir()` | Same; no file access in browser |
| `scripts/config/debug_config.gd` | `OS.get_cmdline_args()` | Use `JavaScriptBridge` or URL params for browser; fallback to empty |
| `scripts/main.gd` | `--headless` via `OS.get_cmdline_args()` | Use export preset or project setting instead of CLI |

### 1.3 Web-Specific Checks

- [ ] Replace any `OS.get_cmdline_args()` / `OS.get_cmdline_user_args()` with browser-safe alternatives
- [ ] Ensure `load()` calls work (or switch to `preload()` where possible)
- [ ] Test audio in browser (may need user gesture to unlock)
- [ ] Verify no blocking main-thread ops that freeze the tab

### 1.4 Definition of Done

- Game exports to Web and runs in browser
- No crashes from CLI/file/OS calls
- Single-player playable (spawn, move, gather, build)

---

## Phase 2: Network Foundation

Add networking layer. No gameplay changes yet—just connect/disconnect.

### 2.1 Transport & Peer Setup

- [ ] Create `scripts/network/network_manager.gd` (or similar)
- [ ] Use `WebSocketMultiplayerPeer` (required for browser)
- [ ] Server: create peer, listen on port (e.g. 9080)
- [ ] Client: create peer, connect to `ws://host:port`
- [ ] Integrate with Godot `MultiplayerAPI` (`get_tree().multiplayer.multiplayer_peer`)

### 2.2 Connection Flow

- [ ] Server: start listening on `_ready()` or via menu
- [ ] Client: "Join Game" → enter host URL → connect
- [ ] Handle `peer_connected`, `peer_disconnected`
- [ ] Simple lobby: show connected peer count
- [ ] Disconnect / reconnect handling

### 2.3 Server vs Client Detection

- [ ] `multiplayer.is_server()` for server-only logic
- [ ] `multiplayer.get_unique_id()` for peer IDs
- [ ] Guard all server-authoritative code with `if multiplayer.is_server():`

### 2.4 Definition of Done

- Server starts and listens
- Browser client connects via WebSocket
- Connection/disconnection logged
- No gameplay yet—just network handshake

---

## Phase 3: Network IDs & Entity Identity

Replace `instance_id` with stable network IDs so server and clients can refer to the same entities.

### 3.1 Network ID System

- [ ] Extend or replace `EntityRegistry` with network IDs
- [ ] Server assigns IDs (e.g. incrementing int) on spawn
- [ ] Store `network_id` on entities (player, NPC, resource, building, etc.)
- [ ] Server maintains `network_id → node` map; clients maintain `network_id → node` for spawned entities
- [ ] Use network IDs in all sync messages (combat target, gather target, etc.)

### 3.2 Entity Spawn Sync

- [ ] Server spawns entity → broadcasts `spawn_entity(network_id, type, position, ...)`
- [ ] Clients receive → instantiate scene, set `network_id`, add to world
- [ ] Server despawns → broadcasts `despawn_entity(network_id)`
- [ ] Clients remove from scene

### 3.3 Definition of Done

- Every spawned entity has a network ID
- Server and clients can resolve `network_id` to node
- Spawn/despawn messages work

---

## Phase 4: Player Spawn & Movement

Players spawn and move. Server-authoritative.

### 4.1 Player Spawn

- [ ] Server spawns player on connect (`peer_connected`)
- [ ] Assign `multiplayer.get_unique_id()` as player owner (or map to network_id)
- [ ] Broadcast `player_spawned(peer_id, network_id, position)` to all clients
- [ ] Each client instantiates player; server sets `set_multiplayer_authority(peer_id)` for that player
- [ ] Client only sends input for their own player

### 4.2 Input → Server

- [ ] Client: capture `Input` (WASD, etc.) in `_process` or `_physics_process`
- [ ] Client: send `player_input(input_vector, facing)` via RPC to server
- [ ] Server: receive, validate, apply movement to player node
- [ ] Server: broadcast `player_state(network_id, position, velocity, facing)` at fixed rate (e.g. 20 Hz)

### 4.3 Client-Side Prediction (Optional, Later)

- [ ] Client applies input locally for responsiveness
- [ ] Server corrects with authoritative state
- [ ] Defer to Phase 7+ if needed

### 4.4 Definition of Done

- Player spawns when connecting
- Player moves; movement is server-authoritative
- Other clients see the player move
- Camera follows own player

---

## Phase 5: World Spawn Sync

Server spawns world (NPCs, land claims, resources). Clients receive and render.

### 5.1 World Initialization (Server Only)

- [ ] Server runs `_setup_npcs()`, `_spawn_initial_resources()`, etc. (existing logic)
- [ ] For each spawned entity: assign network_id, add to registry
- [ ] Broadcast spawn messages to all connected clients
- [ ] New clients joining mid-game: server sends full world state (all entities)

### 5.2 Spawn Message Format

- [ ] Define `spawn_npc(network_id, npc_type, position, clan_name, ...)`
- [ ] Define `spawn_land_claim(network_id, position, clan_name, player_owned, ...)`
- [ ] Define `spawn_resource(network_id, resource_type, position, ...)`
- [ ] Define `spawn_building(network_id, building_type, position, ...)`
- [ ] Clients instantiate from scene, set properties, add to tree

### 5.3 Late Join (Catch-Up)

- [ ] When client connects, server sends "world snapshot" (all current entities)
- [ ] Client applies snapshot before receiving live updates
- [ ] Ensures new player sees existing world

### 5.4 Definition of Done

- Server spawns world; clients see NPCs, land claims, resources
- Late-joining client receives full world
- No duplicate spawns or missing entities

---

## Phase 6: Server-Authoritative Gameplay

Move all state-changing logic to server. Clients only send input and render.

### 6.1 Combat (CombatTick, CombatScheduler, CombatComponent)

| System | Change |
|--------|--------|
| CombatTick | Run only on server (`if multiplayer.is_server()`). Clients receive agro/combat state via sync. |
| CombatScheduler | Run only on server. Broadcast `combat_hit(network_id, target_id, damage)` etc. |
| CombatComponent | Server decides hits. Clients receive damage events, apply to HealthComponent, play effects. |
| npc_base.gd | `multiplayer.has_multiplayer_peer() or is_multiplayer_authority()` → server only for sim logic |

- [ ] Guard CombatTick `_on_tick` with server check
- [ ] Guard CombatScheduler `_process` with server check
- [ ] CombatComponent: server validates attack, broadcasts hit
- [ ] Clients: receive hit RPC, apply damage, spawn effects

### 6.2 NPC FSM & AI

- [ ] FSM `update()` runs only on server
- [ ] ClanBrain runs only on server
- [ ] Server broadcasts NPC state: `npc_state(network_id, state_name, position, target_id, ...)` at fixed rate
- [ ] Clients: receive state, update NPC position/visuals (no logic)

### 6.3 Gathering & Resources

- [ ] GatherableResource: server validates gather start/finish
- [ ] Server: `gather_start(network_id, resource_id)` / `gather_finish(network_id, resource_id, items)`
- [ ] Clients: show progress bar, receive result
- [ ] Resource depletion/cooldown: server authority; sync to clients

### 6.4 Inventory

- [ ] Player inventory: server authority
- [ ] Client sends `inventory_action(...)` (pickup, drop, craft)
- [ ] Server validates, updates inventory, broadcasts `inventory_update(network_id, slot_data)`
- [ ] Building inventory: same pattern

### 6.5 Building & Land Claims

- [ ] Placement: client sends `place_building(type, position)`; server validates, spawns, broadcasts
- [ ] Land claim placement: same
- [ ] Building state (fuel, cooking, slots): server authority, sync to clients

### 6.6 Definition of Done

- All state changes go through server
- Clients only send input and render
- No client-side authority for world state

### 6.7 Perception RPC

- **Not needed** for server-authoritative AI. PerceptionArea runs on server; clients receive outcomes.
- See `guides/future implementations/perception_rpc.md` for when to add RPC sync.

---

## Phase 7: Determinism & Time

Ensure server simulation is deterministic for consistency and future replay/debug.

### 7.1 Deterministic RNG

- [ ] Replace `randf()`, `randi_range()` with seeded RNG for server sim
- [ ] Use `RandomNumberGenerator` with server-controlled seed
- [ ] All AI, spawn positions, loot tables use this RNG

### 7.2 Server Time Authority

- [ ] Server broadcasts `server_time(ticks_msec)` periodically
- [ ] Clients use server time for sim-related logic (e.g. cooldowns) if any
- [ ] CombatScheduler uses server time

### 7.3 Definition of Done

- Server RNG is deterministic
- Server time is authoritative
- (Optional) Replay from tick log works

---

## Phase 8: Polish & Edge Cases

### 8.1 Disconnect / Reconnect

- [ ] Server: when client disconnects, mark player as disconnected; optionally despawn after timeout
- [ ] Client: show "Disconnected" UI; "Reconnect" button
- [ ] Reconnect: restore player state if possible, or respawn

### 8.2 Lobby & Matchmaking

- [ ] Simple lobby UI: "Host Game" / "Join Game"
- [ ] Host: enter port, start server
- [ ] Join: enter `ws://host:port`, connect
- [ ] (Later) Optional: relay server, room codes, NAT punch-through

### 8.3 Performance

- [ ] Throttle sync rate (e.g. 20 Hz for positions, 10 Hz for NPCs)
- [ ] Delta compression (send only changed values)
- [ ] Interest management (only sync entities near player)—defer if needed

### 8.4 Browser Hosting

- [ ] Server: run Godot headless export on VPS/cloud (Linux)
- [ ] Or: external WebSocket server (Node.js, etc.) that relays to Godot
- [ ] Client: host game HTML on static host (GitHub Pages, Netlify, etc.)
- [ ] HTTPS + WSS for production (browsers require secure WebSocket on HTTPS)

---

## Checklist Summary

| Phase | Focus | Key Deliverable |
|-------|-------|-----------------|
| 1 | Browser export | Game runs in browser, single-player |
| 2 | Network foundation | Server + client connect via WebSocket |
| 3 | Network IDs | Stable entity identity across peers |
| 4 | Player spawn & movement | Players spawn, move, visible to others |
| 5 | World spawn sync | NPCs, resources, claims visible to all |
| 6 | Server-authoritative gameplay | Combat, gather, inventory, building on server |
| 7 | Determinism | Seeded RNG, server time |
| 8 | Polish | Disconnect, lobby, performance, hosting |

---

## Files to Create/Modify (Reference)

| Action | Path |
|--------|------|
| Create | `scripts/network/network_manager.gd` |
| Create | `scripts/network/network_ids.gd` (or extend EntityRegistry) |
| Modify | `scripts/main.gd` (spawn sync, server guards) |
| Modify | `scripts/player.gd` (input RPC, authority) |
| Modify | `scripts/npc/npc_base.gd` (server guards) |
| Modify | `scripts/systems/combat_tick.gd` (server only) |
| Modify | `scripts/systems/combat_scheduler.gd` (server only) |
| Modify | `scripts/npc/components/combat_component.gd` (server hit, RPC) |
| Modify | `scripts/logging/playtest_instrumentor.gd` (browser stub) |
| Modify | `scripts/config/debug_config.gd` (browser-safe config) |
| Modify | `scripts/gatherable_resource.gd` (server gather) |
| Modify | `scripts/land_claim.gd` (server placement) |
| Create | `scenes/ui/LobbyMenu.tscn` (optional) |

---

## Notes

- **WebSocket only:** Browsers cannot use ENet (UDP). Use `WebSocketMultiplayerPeer` for all browser clients.
- **Dedicated server:** One Godot instance runs headless as server. No player-controlled host.
- **Scale later:** Phase 8 can add interest management, delta compression, and relay servers as needed.
- **Testing:** Test with 2+ browser tabs, or desktop client + browser, during development.
