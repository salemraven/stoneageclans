# Web Card Tuner (optional preview only)

> **Source of truth:** Godot `scenes/tools/LimbTuner.tscn` (Character Animation Tuner).  
> Use the web tuner only for quick browser previews. It does not support walk/attack mode fields, elbow bend overrides, or the full preset schema. **Save from Godot** when tuning for the game.

Browser preview of overlapping `layered_blank_1.tres` + `club_clansmen_1.tres` files.

## Quick start (local)

```bash
python3 tools/card_tuner_web/server.py
```

Open http://localhost:8765/

## Share link (for reviewing agent changes)

From repo root:

```bash
bash tools/card_tuner_web/share.sh
```

Prints a **public URL** (via cloudflared). The agent should run this after tuner changes and send you that link.

- Link dies when the tunnel stops.
- Header shows **build SHA + branch** so you can confirm you're on the latest commit.
- **Save** writes the same `.tres` files Godot uses.

## Godot vs web

| | Web | Godot `LimbTuner.tscn` |
|---|-----|------------------------|
| Preview in browser | Yes | No (desktop) |
| Handle 3 on club grip | Yes | Yes (best reference) |
| Save to repo | Yes | Yes |
| Combat / ready test | No | Yes (Shift+click) |

Use **web** to review agent work from a link. Use **Godot** for final combat poses.
