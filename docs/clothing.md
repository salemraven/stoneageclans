# Clothing, hair, body paint & clan colors (design)

**Current game:** player and NPCs use **2D sprites** (`assets/sprites/`, `WalkAnimation`). The notes below are **design intent** if you add layered 2D outfits, palette swaps, or a future pipeline.

## Goals

- Multiple **stone-age** looks.
- **Clan / player accent color** chosen in game; apply only where authored (trims, body paint), not whole-sprite multiply unless intentional.
- **White or light-neutral** base pixels where runtime tint should apply.

## Masking (2D)

- Use **separate regions** in the sheet, **palette indices**, or a **mask texture** alongside the sprite to drive where `clan_color` blends.

## Multiplayer

- **Server** owns canonical **clan color**; clients render received state.
