# Baked animation strips (Limb Tuner → Bake clip)

Exported from **Character Animation Tuner** via **Bake clip**. Each holdable gets a subfolder with horizontal PNG strips and JSON manifests.

## Layout

```
assets/baked/clansmen_1/
  spear/
    idle.png + idle.json
    walk.png + walk.json
  club/
    idle.png
    walk.png
  none/
    ...
```

## Manifest fields

| Field | Meaning |
|-------|---------|
| `frame_size` | `[width, height]` per cell (128×128) |
| `padding` | Pixels between frames in the strip |
| `columns` | Frame count in the strip |
| `fps` | Playback rate |
| `loop` | Whether the clip loops |
| `direction` | Facing baked into the strip (`E` for v1) |

## Authoring

1. Tune pose in `scenes/tools/LimbTuner.tscn`
2. Select **Idle**, **Walk**, or **Gather** pose row
3. Click **Bake clip** → review popup plays the loop
4. Files write under `assets/baked/clansmen_1/<weapon>/`

Combat thrust/swing clips are planned next (8 directions).
