# Character Animation Tuner

**Not** the old clansmen placeholder-card tool. This scene tunes **procedural arms**, **weapon overlay**, and **layered mannequin art** (body + head), then saves presets the game loads at runtime.

## Run

```bash
godot --path . res://scenes/tools/LimbTuner.tscn
```

Or in the editor: open `LimbTuner.tscn` → **F6** (Play Current Scene).

Headless smoke:

```bash
SKIP_SINGLE_INSTANCE=1 godot --headless --path . --script res://tools/test_limb_tuner.gd
```

## Architecture

| Piece | Path |
|-------|------|
| Scene | `scenes/tools/LimbTuner.tscn` |
| App logic | `scripts/tools/limb_tuner.gd` |
| Rig | `scripts/tools/limb_tuner_rig.gd` |
| Mannequin body | `scripts/tools/tuner_body_visual.gd` |
| Layout math | `scripts/tools/tuner_mannequin_layout.gd` |
| Walk preview | `scripts/tools/tuner_walk_preview.gd` |
| Layered art layout | `scripts/config/character_card_layer_layout.gd` |
| Layer registry | `scripts/config/character_card_parts_registry.gd` |

UI title on disk: **Character Animation Tuner**

## Saves

- **Limb presets** → `assets/limb_presets/*.tres` (`WeaponLimbPreset`, via `LimbPresetRegistry`)
- **Body/head placement** → `assets/character_cards/layered_blank_1.tres` (`CharacterCardLayerLayout`)

Scale/coordinate space matches in-game card display height (128px); the tuner uses a **mannequin** (layered body + head sprites), not `clansmen_card*.png` art.

## Controls (summary)

See **HelpLabel** and the on-screen **legend** (top-right). Typical handles:

- **H** — head / neck socket  
- **1 / 1e** — dominant shoulder, hand, elbow pole  
- **2 / 2e** — off arm, elbow pole  
- **3** — weapon overlay  
- **← / →** or **Toggle walk** — walk preview  
- **Shift** — ready | **Shift + click** — strike  

**Idle / Ready** tabs store separate pose data. **Save** commits preset + layer layout.
