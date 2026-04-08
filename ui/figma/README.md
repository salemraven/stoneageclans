# Figma ↔ Stone Age Clans UI

There is **no live sync** between Figma and Godot (same as most game engines). The practical workflow is: **design system in Figma** → **handoff** → **tokens + assets in the repo** → **Godot reads `UITheme` + scenes**.

## What lives where

| Figma | Repo |
|-------|------|
| Variables (colors, radii, spacing, type scale) | `ui/design_tokens/design_tokens.json` |
| Frames, components, layout | Reference for building/editing `.tscn` and scripted UI; move controls in Godot |
| Icons, 9-slice panel PNGs, bitmap UI | `ui/textures/` (or `assets/` if shared with gameplay art) |
| Written spec | `guides/UI.md` (behavior + patterns) |

## Design language (keep it boring)

Use familiar patterns so the game stays readable:

- **Panels**: rounded rect, semi-transparent fill, thin border (maps to `UITheme.get_panel_style()` = `StyleBoxFlat`).
- **Text**: primary / secondary / error / success / selected — same names as `design_tokens.json` → `UITheme.COLOR_*`.
- **Spacing**: 8px grid (`panel_padding_standard` / `_large`, slot sizes).
- **New screens**: reuse `UITheme` helpers; add optional `ui/components/` scenes for repeated blocks.

## Figma file setup (recommended)

1. Create a **Variable collection** (e.g. `SAC / UI`) with modes if you need light/dark later.
2. Mirror **semantic names** used in JSON under `colors.*`, `layout.*`, `sizes.*`, `typography.*` (e.g. `text_primary`, not `Gray/100`).
3. For raster UI: export **@1x** PNG unless the project standardizes scale; Godot stretch mode is in `project.godot` (`canvas_items`).

## Export → Godot

1. **Tokens**: Copy values into `ui/design_tokens/design_tokens.json`, or use any **Design Tokens JSON** export (Tokens Studio, Variables → plugin) and **reshape** to match this file’s shape (see keys above). Colors: `#RRGGBB` or `#RRGGBBAA` strings.
2. **Reload in dev**: call `UITheme.reload_design_tokens()` from a debug menu or temporarily from `_ready()` — or restart the game after editing JSON.
3. **Textures**: Export slices / 9-slice assets into `ui/textures/`, import in Godot, use `StyleBoxTexture` or `TextureRect` in scenes that need bitmap chrome. `get_panel_style()` stays **flat** so existing code can still tweak `bg_color` on the style.

## Optional tools (not bundled)

- Community experiments (e.g. Figma JSON → Godot node trees) are **fragile** for full games; prefer tokens + scenes for production.
- Figma REST API can automate token extraction; add a small script in `tools/` later if you want CI sync.

## Multiplayer note

UI is **client-local**. Tokens and textures do not affect simulation authority; no extra sync cost.
