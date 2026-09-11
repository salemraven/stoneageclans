# Legacy sprite sheets (archived 2026-09-07)

Retired caveman / walk animation PNG sprite sheets. Game uses **character cards** (limb tuner) instead.

Moved here because oversized PNGs crashed Godot on import (GPU max texture width ~16384):

- `stwalk_walk.png` — 18502×2054
- `caveman_walk.png`, `caveman_idle.png` — 12334×4110
- `*walkbig.png` — unused legacy sheets

JSON sidecars (`caveman_*.json`, `stwalk_walk.json`) archived with them.

**Do not move back into `assets/sprites/`** without splitting sheets under GPU limits.
