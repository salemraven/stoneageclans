#!/usr/bin/env python3
"""Tile-based procedural rivers for Stone Age Clans.

Glacier hub + spokes to ocean on a 64px tile grid.
map2.jpg guides land/ocean only — rivers are procedural for an authentic game-map feel.
"""

from __future__ import annotations

import math
import random
from collections import deque
from dataclasses import dataclass, field

import numpy as np

WORLD_SIZE = 65536
TILE_SIZE = 64
GRID_SIZE = WORLD_SIZE // TILE_SIZE  # 1024 tiles

WIDTH_MAIN_TILES = 3
WIDTH_TRIBUTARY_TILES = 1
AUTHORING_MIN_WIDTH = 2  # Gameplay drought can shrink to 1 tile later

BIOME_OCEAN = 0
BIOME_SAVANNA = 1
BIOME_RIVER = 7


@dataclass
class RiverNetwork:
    """Legacy container kept for JSON export compatibility."""
    segments: list = field(default_factory=list)
    seed: int = 42


def _neighbors8(x: int, y: int, w: int, h: int) -> list[tuple[int, int]]:
    out: list[tuple[int, int]] = []
    for dy in (-1, 0, 1):
        for dx in (-1, 0, 1):
            if dx == 0 and dy == 0:
                continue
            nx, ny = x + dx, y + dy
            if 0 <= nx < w and 0 <= ny < h:
                out.append((nx, ny))
    return out


def _neighbors4(x: int, y: int, w: int, h: int) -> list[tuple[int, int]]:
    out: list[tuple[int, int]] = []
    for dx, dy in ((0, -1), (1, 0), (0, 1), (-1, 0)):
        nx, ny = x + dx, y + dy
        if 0 <= nx < w and 0 <= ny < h:
            out.append((nx, ny))
    return out


def downsample_land_mask(full_land: np.ndarray, grid_size: int) -> np.ndarray:
    """Downsample a high-res land mask to tile grid (majority land per block)."""
    h, w = full_land.shape
    block_y = h / grid_size
    block_x = w / grid_size
    grid = np.zeros((grid_size, grid_size), dtype=bool)
    for ty in range(grid_size):
        y0 = int(ty * block_y)
        y1 = int((ty + 1) * block_y)
        for tx in range(grid_size):
            x0 = int(tx * block_x)
            x1 = int((tx + 1) * block_x)
            block = full_land[y0:y1, x0:x1]
            grid[ty, tx] = block.mean() > 0.5 if block.size else False
    return grid


def distance_to_ocean(land: np.ndarray) -> np.ndarray:
    """For each land tile, steps to nearest ocean (BFS). Ocean / non-land = 0."""
    h, w = land.shape
    dist = np.full((h, w), -1, dtype=np.int32)
    q: deque[tuple[int, int]] = deque()

    for y in range(h):
        for x in range(w):
            if not land[y, x]:
                dist[y, x] = 0
                q.append((x, y))

    while q:
        x, y = q.popleft()
        d = dist[y, x]
        for nx, ny in _neighbors4(x, y, w, h):
            if land[ny, nx] and dist[ny, nx] < 0:
                dist[ny, nx] = d + 1
                q.append((nx, ny))

    return dist


def find_glacier_hub(land: np.ndarray, dist: np.ndarray) -> tuple[int, int]:
    """Hub = land tile near island center with good inland depth."""
    h, w = land.shape
    ys, xs = np.where(land)
    if len(xs) == 0:
        return w // 2, h // 2

    cx = int(np.mean(xs))
    cy = int(np.mean(ys))
    best = (cx, cy)
    best_score = -1.0

    max_dist = int(dist[land].max()) if land.any() else 1
    for y in range(h):
        for x in range(w):
            if not land[y, x] or dist[y, x] <= 0:
                continue
            # Prefer deep inland but stay close to island center
            center_penalty = math.hypot(x - cx, y - cy) / max(w, h)
            depth = dist[y, x] / max(max_dist, 1)
            score = depth * 0.75 - center_penalty * 0.25
            if score > best_score:
                best_score = score
                best = (x, y)
    return best


def trace_spoke(
    start: tuple[int, int],
    land: np.ndarray,
    dist: np.ndarray,
    preferred_angle: float,
    rng: random.Random,
    meander: float = 0.35,
) -> list[tuple[int, int]]:
    """Walk from hub toward ocean following distance field + gentle meander."""
    h, w = land.shape
    x, y = start
    path = [(x, y)]
    visited = {start}
    stale = 0

    while land[y, x] and dist[y, x] > 0 and stale < 12:
        current_dist = dist[y, x]
        candidates: list[tuple[float, int, int]] = []

        for nx, ny in _neighbors8(x, y, w, h):
            if not land[ny, nx] or dist[ny, nx] >= current_dist:
                continue
            drop = current_dist - dist[ny, nx]
            if drop <= 0:
                continue
            # Bias toward preferred outward angle
            dx, dy = nx - x, ny - y
            step_angle = math.atan2(dy, dx)
            angle_diff = abs((step_angle - preferred_angle + math.pi) % (2 * math.pi) - math.pi)
            angle_bonus = (1.0 - angle_diff / math.pi) * 0.4
            wobble = (rng.random() - 0.5) * meander
            score = drop + angle_bonus + wobble
            if (nx, ny) in visited:
                score -= 0.15
            candidates.append((score, nx, ny))

        if not candidates:
            break

        candidates.sort(reverse=True)
        _, nx, ny = candidates[0]
        if (nx, ny) == (x, y):
            break
        if (nx, ny) in visited:
            stale += 1
        else:
            stale = 0
        x, y = nx, ny
        visited.add((x, y))
        path.append((x, y))

    return path


def trace_tributary(
    branch: tuple[int, int],
    main_dir: tuple[float, float],
    land: np.ndarray,
    dist: np.ndarray,
    rng: random.Random,
    meander: float = 0.62,
    side_bias: float | None = None,
) -> list[tuple[int, int]]:
    """Snaking branch that still flows toward ocean."""
    angle = math.atan2(main_dir[1], main_dir[0])
    if side_bias is None:
        side_bias = rng.choice([-1.0, 1.0])
    # Branch roughly perpendicular, then meander downhill
    angle += side_bias * rng.uniform(0.75, 1.35)
    path = trace_spoke(branch, land, dist, angle, rng, meander=meander)
    if len(path) >= 6:
        path = meander_path(path, land, dist, rng, wobble=0.55)
    return path


def meander_path(
    path: list[tuple[int, int]],
    land: np.ndarray,
    dist: np.ndarray,
    rng: random.Random,
    wobble: float = 0.45,
) -> list[tuple[int, int]]:
    """Nudge interior points sideways while staying on land and flowing downhill."""
    if len(path) < 4:
        return path

    h, w = land.shape
    out = [path[0]]
    for i in range(1, len(path) - 1):
        x, y = path[i]
        px, py = path[i - 1]
        nx, ny = path[i + 1]
        mdx = nx - px
        mdy = ny - py
        perp_x, perp_y = _perpendicular(float(mdx), float(mdy))
        step = rng.choice([-1, 0, 1])
        if rng.random() > wobble:
            step = 0
        cx = x + perp_x * step
        cy = y + perp_y * step
        if 0 <= cx < w and 0 <= cy < h and land[cy, cx]:
            if dist[cy, cx] <= dist[y, x] + 1:
                out.append((cx, cy))
                continue
        out.append((x, y))
    out.append(path[-1])
    return out


def _perpendicular(dx: float, dy: float) -> tuple[int, int]:
    if dx == 0 and dy == 0:
        return 0, 1
    length = math.hypot(dx, dy)
    px, py = -dy / length, dx / length
    return int(round(px)), int(round(py))


def _width_offsets(width_tiles: int, px: int, py: int) -> list[tuple[int, int]]:
    offsets = [(0, 0)]
    if width_tiles >= 2:
        offsets.extend([(px, py), (-px, -py)])
    if width_tiles >= 3:
        offsets = [(0, 0), (px, py), (-px, -py)]
    return offsets


def paint_path(
    river: np.ndarray,
    path: list[tuple[int, int]],
    width_tiles: int,
    land: np.ndarray,
) -> None:
    """Paint a river path with tile-accurate width."""
    h, w = river.shape
    if len(path) == 0:
        return

    for i, (x, y) in enumerate(path):
        if i > 0:
            pdx = x - path[i - 1][0]
            pdy = y - path[i - 1][1]
        elif len(path) > 1:
            pdx = path[1][0] - x
            pdy = path[1][1] - y
        else:
            pdx, pdy = 1, 0

        px, py = _perpendicular(float(pdx), float(pdy))
        for ox, oy in _width_offsets(width_tiles, px, py):
            tx, ty = x + ox, y + oy
            if 0 <= tx < w and 0 <= ty < h and land[ty, tx]:
                river[ty, tx] = True


def width_for_progress(
    progress: float,
    min_width: int = 1,
    max_width: int = 3,
) -> int:
    """River width from source (0) to mouth (1): thin -> wide."""
    t = max(0.0, min(1.0, progress))
    if t < 0.25:
        return min_width
    if t < 0.55:
        return min(min_width + 1, max_width)
    return max_width


def paint_path_tapered(
    river: np.ndarray,
    path: list[tuple[int, int]],
    land: np.ndarray,
    dist: np.ndarray,
    min_width: int = 1,
    max_width: int = 3,
) -> None:
    """Paint main river: 1 tile at source, 2 mid-course, 3 near coast."""
    if len(path) == 0:
        return

    source_dist = max(dist[path[0][1], path[0][0]], 1)
    last = len(path) - 1

    for i, (x, y) in enumerate(path):
        progress = i / max(last, 1)
        # Also bias width by how close we are to ocean on the distance field
        dist_progress = 1.0 - (dist[y, x] / source_dist)
        blend = progress * 0.55 + dist_progress * 0.45
        width_tiles = width_for_progress(blend, min_width, max_width)

        if i > 0:
            pdx = x - path[i - 1][0]
            pdy = y - path[i - 1][1]
        elif len(path) > 1:
            pdx = path[1][0] - x
            pdy = path[1][1] - y
        else:
            pdx, pdy = 1, 0

        px, py = _perpendicular(float(pdx), float(pdy))
        h, w = river.shape
        for ox, oy in _width_offsets(width_tiles, px, py):
            tx, ty = x + ox, y + oy
            if 0 <= tx < w and 0 <= ty < h and land[ty, tx]:
                river[ty, tx] = True


def generate_glacier_spoke_rivers(
    land: np.ndarray,
    seed: int = 42,
    num_spokes: int = 5,
    tributaries_per_spoke: int = 2,
) -> np.ndarray:
    """Build one connected river network on the tile grid."""
    rng = random.Random(seed)
    h, w = land.shape
    river = np.zeros((h, w), dtype=bool)
    dist = distance_to_ocean(land)
    hub = find_glacier_hub(land, dist)

    # Glacier pool — small filled disc at hub so spokes connect visually
    pool_r = 2
    for dy in range(-pool_r, pool_r + 1):
        for dx in range(-pool_r, pool_r + 1):
            if dx * dx + dy * dy <= pool_r * pool_r:
                tx, ty = hub[0] + dx, hub[1] + dy
                if 0 <= tx < w and 0 <= ty < h and land[ty, tx]:
                    river[ty, tx] = True

    angle_step = 2 * math.pi / num_spokes
    start_angle = rng.uniform(0, angle_step)

    for i in range(num_spokes):
        angle = start_angle + i * angle_step + rng.uniform(-0.15, 0.15)
        # Start spoke just outside pool
        sx = int(hub[0] + math.cos(angle) * (pool_r + 1))
        sy = int(hub[1] + math.sin(angle) * (pool_r + 1))
        if not (0 <= sx < w and 0 <= sy < h and land[sy, sx]):
            sx, sy = hub

        path = trace_spoke((sx, sy), land, dist, angle, rng, meander=0.28)
        if len(path) < 8:
            continue
        paint_path(river, path, WIDTH_MAIN_TILES, land)

        # Tributaries
        for _ in range(rng.randint(
            max(0, tributaries_per_spoke - 1),
            tributaries_per_spoke + 1,
        )):
            if len(path) < 16:
                continue
            idx = rng.randint(len(path) // 5, len(path) * 4 // 5)
            branch = path[idx]
            if idx > 0:
                mdx = branch[0] - path[idx - 1][0]
                mdy = branch[1] - path[idx - 1][1]
            else:
                mdx, mdy = 1, 0
            trib = trace_tributary(branch, (float(mdx), float(mdy)), land, dist, rng)
            if len(trib) >= 4:
                paint_path(river, trib, WIDTH_TRIBUTARY_TILES, land)

    return river


def grids_to_biome_mask(land: np.ndarray, river: np.ndarray) -> np.ndarray:
    """Encode land + river tile grids as biome mask grayscale."""
    ids = np.full(land.shape, BIOME_SAVANNA, dtype=np.uint8)
    ids[~land] = BIOME_OCEAN
    ids[river & land] = BIOME_RIVER
    return np.rint(ids.astype(np.float32) / 9.0 * 255.0).astype(np.uint8)


def upscale_mask(mask: np.ndarray, target_size: int) -> np.ndarray:
    """Nearest-neighbor upscale (each tile becomes a block)."""
    if mask.shape[0] == target_size:
        return mask
    from PIL import Image

    img = Image.fromarray(mask)
    img = img.resize((target_size, target_size), Image.Resampling.NEAREST)
    return np.array(img)


# --- Legacy API stubs used by older tooling ---

def generate_river_network(*args, **kwargs) -> RiverNetwork:
    return RiverNetwork(seed=kwargs.get("seed", 42))


def rasterize_network(*args, **kwargs) -> np.ndarray:
    raise NotImplementedError("Use generate_glacier_spoke_rivers() instead")


def add_edge_wobble(river_mask: np.ndarray, seed: int = 42) -> np.ndarray:
    return river_mask


def _component_pixels(component: np.ndarray) -> set[tuple[int, int]]:
    ys, xs = np.where(component)
    return set(zip(xs.tolist(), ys.tolist()))


def extract_main_path(
    component: np.ndarray,
    dist: np.ndarray,
) -> list[tuple[int, int]]:
    """Trace the main spine through a painted river blob.
    
    Follows painted pixels as closely as possible, visiting the entire
    painted route from inland to coast.
    """
    from collections import deque
    
    pixels = _component_pixels(component)
    if not pixels:
        return []

    h, w = component.shape
    
    # Find endpoints: deepest inland and closest to coast
    start = max(pixels, key=lambda p: dist[p[1], p[0]])
    end = min(pixels, key=lambda p: dist[p[1], p[0]])
    
    # DFS to find longest path through painted pixels
    # We want to visit as many painted pixels as possible
    path = [start]
    visited = {start}
    x, y = start
    
    backtrack_stack = []
    
    while True:
        current_dist = dist[y, x]
        
        # Find all unvisited neighbors in the painted area
        neighbors = []
        for nx, ny in _neighbors8(x, y, w, h):
            if (nx, ny) in pixels and (nx, ny) not in visited:
                neighbors.append((nx, ny))
        
        if neighbors:
            # Prefer neighbors that continue toward coast, but visit all
            # Sort by: distance to coast (prefer closer)
            neighbors.sort(key=lambda p: dist[p[1], p[0]])
            
            # Save current position for backtracking if needed
            if len(neighbors) > 1:
                backtrack_stack.append((x, y, neighbors[1:]))
            
            # Move to best neighbor
            nx, ny = neighbors[0]
            path.append((nx, ny))
            visited.add((nx, ny))
            x, y = nx, ny
        else:
            # No neighbors - try jumping to nearest unvisited painted pixel
            best_jump = None
            best_jump_dist = float('inf')
            for px, py in pixels:
                if (px, py) in visited:
                    continue
                manhattan = abs(px - x) + abs(py - y)
                if manhattan < best_jump_dist and manhattan < 20:
                    best_jump_dist = manhattan
                    best_jump = (px, py)
            
            if best_jump:
                x, y = best_jump
                path.append((x, y))
                visited.add((x, y))
            elif backtrack_stack:
                # Backtrack
                bx, by, remaining = backtrack_stack.pop()
                if remaining:
                    nx, ny = remaining[0]
                    if remaining[1:]:
                        backtrack_stack.append((bx, by, remaining[1:]))
                    path.append((nx, ny))
                    visited.add((nx, ny))
                    x, y = nx, ny
            else:
                break  # Done
        
        # Check if we've visited most pixels or reached the coast
        if len(visited) >= len(pixels) * 0.95 or dist[y, x] <= 0:
            break
        
        # Safety limit
        if len(path) > len(pixels) * 2:
            break
    
    return path


def simplify_path(path: list[tuple[int, int]], step: int = 3) -> list[tuple[int, int]]:
    """Sample path at intervals to smooth stair-stepping while keeping shape."""
    if len(path) <= 4 or step <= 1:
        return path
    out = [path[0]]
    for i in range(step, len(path) - 1, step):
        out.append(path[i])
    out.append(path[-1])
    return out


def smooth_path(path: list[tuple[int, int]], iterations: int = 2) -> list[tuple[int, int]]:
    """Gentle smoothing to reduce jaggedness."""
    if len(path) < 3:
        return path
    result = list(path)
    for _ in range(iterations):
        new_result = [result[0]]
        for i in range(1, len(result) - 1):
            px, py = result[i - 1]
            cx, cy = result[i]
            nx, ny = result[i + 1]
            # Average with neighbors
            sx = int(round((px + cx + nx) / 3))
            sy = int(round((py + cy + ny) / 3))
            new_result.append((sx, sy))
        new_result.append(result[-1])
        result = new_result
    return result


def extend_path_to_coast(
    path: list[tuple[int, int]],
    land: np.ndarray,
    dist: np.ndarray,
    rng: random.Random,
) -> list[tuple[int, int]]:
    """Continue a path downhill until it reaches the ocean edge (dist=0)."""
    if len(path) < 2:
        return path
    h, w = land.shape
    x, y = path[-1]
    if dist[y, x] <= 0:
        return path
    
    # Get direction from last segment
    mdx = path[-1][0] - path[-2][0]
    mdy = path[-1][1] - path[-2][1]
    angle = math.atan2(mdy, mdx)
    
    tail = trace_spoke((x, y), land, dist, angle, rng, meander=0.15)
    if not tail:
        return path
    if tail and tail[0] == (x, y):
        tail = tail[1:]
    
    return path + tail


def _collect_painted_components(
    painted: np.ndarray,
    land: np.ndarray,
) -> list[tuple[int, np.ndarray]]:
    from collections import deque

    base = painted.astype(bool) & land
    h, w = land.shape
    seen = np.zeros((h, w), dtype=bool)
    components: list[tuple[int, np.ndarray]] = []

    for y in range(h):
        for x in range(w):
            if not base[y, x] or seen[y, x]:
                continue
            comp = np.zeros((h, w), dtype=bool)
            q: deque[tuple[int, int]] = deque([(x, y)])
            seen[y, x] = True
            comp[y, x] = True
            count = 1
            while q:
                cx, cy = q.popleft()
                for nx, ny in _neighbors4(cx, cy, w, h):
                    if base[ny, nx] and not seen[ny, nx]:
                        seen[ny, nx] = True
                        comp[ny, nx] = True
                        count += 1
                        q.append((nx, ny))
            components.append((count, comp))

    components.sort(reverse=True, key=lambda item: item[0])
    return components


def _pick_branch_indices(
    path_len: int,
    count: int,
    rng: random.Random,
    coastal_bias: float = 0.65,
) -> list[int]:
    """Pick branch points; favor mid-course and coastal sections."""
    if path_len < 20 or count <= 0:
        return []

    lo = max(3, path_len // 8)
    hi = max(lo + 2, path_len - 2)
    picks: list[int] = []
    coastal_start = int(path_len * (1.0 - coastal_bias))

    for _ in range(count):
        if rng.random() < coastal_bias and coastal_start < hi:
            idx = rng.randint(max(lo, coastal_start), hi)
        else:
            idx = rng.randint(lo, hi)
        if idx not in picks:
            picks.append(idx)

    return sorted(picks)


def rebuild_rivers_from_guides(
    land: np.ndarray,
    painted: np.ndarray,
    seed: int = 42,
    main_width: int = AUTHORING_MIN_WIDTH,
    tributary_width: int = 1,
    tributaries_per_main: int = 6,
    min_component_size: int = 100,
    min_tributary_length: int = 8,
    min_branch_dist: int = 6,
) -> tuple[np.ndarray, dict]:
    """Build fresh tile rivers from painted guide marks (guides are not kept).
    
    The painted marks define WHERE rivers flow. We trace along them, smooth
    the path, extend to coast if needed, then paint 2-wide rivers.
    """
    rng = random.Random(seed)
    h, w = land.shape
    base = painted.astype(bool) & land
    river = np.zeros((h, w), dtype=bool)
    dist = distance_to_ocean(land)
    main_width = max(AUTHORING_MIN_WIDTH, main_width)
    tributary_width = max(AUTHORING_MIN_WIDTH, tributary_width)

    components = _collect_painted_components(painted, land)
    stats = {
        "main_systems": 0,
        "tributaries_added": 0,
        "guide_pixels": int(base.sum()),
        "pixels_after": 0,
        "replaced_guides": True,
        "paths": [],
    }

    for size, comp in components:
        if size < min_component_size:
            continue

        # Extract spine following the painted route
        path = extract_main_path(comp, dist)
        if len(path) < 10:
            continue
            
        # Smooth, meander, extend to coast
        path = simplify_path(path, step=3)
        path = smooth_path(path, iterations=3)
        path = meander_path(path, land, dist, rng, wobble=0.35)
        path = extend_path_to_coast(path, land, dist, rng)

        if len(path) < 8:
            continue

        # Tapered main stem: 1 tile at glacier -> 2 mid -> 3 at coast
        paint_path_tapered(
            river,
            path,
            land,
            dist,
            min_width=1,
            max_width=max(main_width + 1, 3),
        )
        stats["main_systems"] += 1
        stats["paths"].append(len(path))

        if len(path) < 20:
            continue

        branch_indices = _pick_branch_indices(len(path), tributaries_per_main, rng)
        side_toggle = 1.0

        for idx in branch_indices:
            branch = path[idx]
            bd = dist[branch[1], branch[0]]
            if bd < min_branch_dist:
                continue

            if idx > 0:
                mdx = branch[0] - path[idx - 1][0]
                mdy = branch[1] - path[idx - 1][1]
            elif idx + 1 < len(path):
                mdx = path[idx + 1][0] - branch[0]
                mdy = path[idx + 1][1] - branch[1]
            else:
                mdx, mdy = 1, 0

            side_toggle *= -1.0
            trib = trace_tributary(
                branch,
                (float(mdx), float(mdy)),
                land,
                dist,
                rng,
                meander=0.68,
                side_bias=side_toggle,
            )
            if len(trib) < min_tributary_length:
                continue
            # Tributaries stay thin; widen slightly near their mouth
            paint_path_tapered(
                river,
                trib,
                land,
                dist,
                min_width=tributary_width,
                max_width=max(tributary_width + 1, 2),
            )
            stats["tributaries_added"] += 1

    stats["pixels_after"] = int(river.sum())
    return river, stats


def enrich_painted_rivers(
    land: np.ndarray,
    painted: np.ndarray,
    seed: int = 42,
    main_width: int = 2,
    tributaries_per_main: int = 4,
    min_component_size: int = 100,
    min_tributary_length: int = 4,
    min_branch_dist: int = 8,
) -> tuple[np.ndarray, dict]:
    """Legacy: widen existing paint in-place. Prefer rebuild_rivers_from_guides()."""
    from collections import deque

    rng = random.Random(seed)
    h, w = land.shape
    base = painted.astype(bool) & land
    river = base.copy()
    dist = distance_to_ocean(land)
    components = _collect_painted_components(painted, land)
    stats = {
        "main_systems": 0,
        "tributaries_added": 0,
        "pixels_before": int(base.sum()),
        "pixels_after": 0,
        "widened_paths": 0,
    }

    for size, comp in components:
        if size < min_component_size:
            continue

        path = extract_main_path(comp, dist)
        if len(path) >= 6:
            paint_path(river, path, main_width, land)
            stats["widened_paths"] += 1
        stats["main_systems"] += 1

        if len(path) < 12:
            continue

        lo = max(2, len(path) // 6)
        hi = max(lo + 1, len(path) * 5 // 6)
        branch_points = sorted(
            rng.sample(range(lo, hi), k=min(tributaries_per_main, hi - lo)),
        )

        for idx in branch_points:
            branch = path[idx]
            if dist[branch[1], branch[0]] < min_branch_dist:
                continue
            if idx > 0:
                mdx = branch[0] - path[idx - 1][0]
                mdy = branch[1] - path[idx - 1][1]
            elif idx + 1 < len(path):
                mdx = path[idx + 1][0] - branch[0]
                mdy = path[idx + 1][1] - branch[1]
            else:
                mdx, mdy = 1, 0

            trib = trace_tributary(branch, (float(mdx), float(mdy)), land, dist, rng)
            if len(trib) < min_tributary_length:
                continue
            paint_path(river, trib, WIDTH_TRIBUTARY_TILES, land)
            stats["tributaries_added"] += 1

    # Never erase painted pixels
    river |= base
    stats["pixels_after"] = int(river.sum())
    stats["pixels_added"] = stats["pixels_after"] - stats["pixels_before"]
    return river, stats
