# Phase 4 – Config / Tuning

## NPC movement speeds

**Source of truth:** `scripts/config/npc_config.gd` (NPCConfig autoload)

| Config variable | Current value | Notes |
|-----------------|---------------|--------|
| `max_speed_base` | 95.0 | Fallback when no agility; smoother map movement. |
| `speed_agility_multiplier` | 9.5 | **Effective speed = agility × this.** |

**Formula:** `max_speed = agility * NPCConfig.speed_agility_multiplier`  
(Also: `NPCConfig.get_max_speed(agility)`)

### Effective speed by NPC type

| NPC type | Agility | Effective max speed |
|----------|---------|----------------------|
| Cavemen (default) | 10.0 | 95 |
| Women | 9.0 | 85.5 |
| Other (default stats) | 10.0 | 95 |

*Agility is set in `scripts/npc/stats.gd` (default 10) and overridden in `scripts/main.gd` for women (9.0).*

### Where speed is applied

| Location | Role |
|----------|------|
| `scripts/config/npc_config.gd` | `max_speed_base`, `speed_agility_multiplier`, `get_max_speed(agility)` |
| `scripts/npc/steering_agent.gd` | `initialize()` sets `max_speed` from config; defaults/fallbacks 115 and 95. |
| `scripts/npc/states/idle_state.gd` | On exit from idle, restores `max_speed` via `NPCConfig.speed_agility_multiplier` / `max_speed_base`. |

### Other speed modifiers (unchanged by this doc)

- **Action (eat/gather):** `action_speed_multiplier` = 0.3 (30% speed) in `npc_config.gd`.
- **Herd:** `herd_speed_multiplier_sprint`, `herd_speed_multiplier_normal`, `herd_speed_multiplier_slow` in `npc_config.gd`; applied in herd states.
- **Wild NPC variation:** 70–100% of computed speed (randomized per NPC, updated every 2s) in `npc_base.gd`.

### Changelog (movement)

- Reduced from original 260/26 (and 320 default) in steps: ~2/3, then ~85%, then ~85% again, then ~76% for smoother map movement.
- Current: **95** base, **9.5** agility multiplier (cavemen 95, women 85.5). Player: **200** (`player.gd` move_speed).

---

## Reminders / TODO

- (walk.png 11-frame idle + walk is done: frame 0 = idle, 1–10 = walk.)
