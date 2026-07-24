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

**Startup:** opens on **Club** + **Idle**, loading `assets/limb_presets/club_clansmen_1.tres` so handles are not piled at the origin. Change **default_weapon_type** on the scene root if you want a different preset on open.

## Saves

- **Limb presets** → `assets/limb_presets/*.tres` (`WeaponLimbPreset`, via `LimbPresetRegistry`)
- **Body/head placement** → `assets/character_cards/layered_blank_1.tres` (`CharacterCardLayerLayout`)

### Club idle baseline (2026-07-24)

Tuned in web card tuner, saved to `assets/limb_presets/club_clansmen_1.tres`. **Animation: Idle · Weapon: Club.**

| Field | Value |
|-------|-------|
| `shoulder_offset_px` | (129.46, -163.65) |
| `support_shoulder_offset_px` | (-89.88, -167.77) |
| `overlay_offset_idle_px` / club grip | (282.21, -140.25) |
| `hand_grip_offset_px` | (0, 0) — grip anchored to overlay |
| `support_hand_idle_offset_px` | (-36.89, 66.31) |
| `weapon_elbow_pole_idle_px` | (215.05, -177.01) |
| `support_elbow_pole_idle_px` | (-124.93, -51.6) |
| `upper_arm_length` / `lower_arm_length` | 120 / 120 |

Godot LimbTuner and the game load this file at runtime for club + idle.

### None idle baseline (2026-07-24)

Tuned in web card tuner, saved to `assets/limb_presets/none_clansmen_1.tres`. **Animation: Idle · Weapon: None** (empty hands, no club).

| Field | Value |
|-------|-------|
| `shoulder_offset_px` | (129.46, -163.65) |
| `support_shoulder_offset_px` | (-89.88, -167.77) |
| `hand_grip_offset_px` | (180.33, 58.45) |
| `support_hand_idle_offset_px` | (-112.12, 61.76) |
| `weapon_elbow_pole_idle_px` | (215.05, -177.01) |
| `support_elbow_pole_idle_px` | (-80.94, -46.76) |
| `upper_arm_length` / `lower_arm_length` | 120 / 120 |

Shoulders match the club idle preset; hands/elbows are the unarmed idle pose.

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
