#!/usr/bin/env python3
"""
Apply patchy biome transitions to the full map - matching map2 reference.
Key features from map2:
- Scattered forest patches throughout savanna
- Tan/dirt patches scattered in grass
- Grass patches inside desert
- Patchy transitions at all biome boundaries
"""

import numpy as np
from PIL import Image
from scipy.ndimage import gaussian_filter, binary_dilation, distance_transform_edt
from pathlib import Path
import time

# Paths
REPO = Path(__file__).parent.parent
MASK_IN = REPO / "maps" / "island" / "biome_mask.png"
MASK_OUT = REPO / "maps" / "island" / "biome_mask_transitions.png"
PREVIEW_OUT = REPO / "maps" / "island" / "preview_transitions.png"
WATER_PATH = REPO / "maps" / "island" / "water_layer.png"

# Biome IDs (grayscale values in mask)
SCALE = 28.33
OCEAN = 0
SAVANNA = round(1 * SCALE)      # 28
DESERT = round(2 * SCALE)       # 57
JUNGLE = round(3 * SCALE)       # 85
SWAMP = round(4 * SCALE)        # 113
GLACIER = round(5 * SCALE)      # 142
FOREST = round(6 * SCALE)       # 170
BEACH = round(8 * SCALE)        # 227

# Additional sub-biome colors for preview (not separate biome IDs)
SAVANNA_DARK = 29   # Darker grass patches
SAVANNA_TAN = 30    # Tan/dirt patches in savanna
DESERT_GRASS = 31   # Grass patches in desert

BIOME_NAMES = {
    OCEAN: "ocean",
    SAVANNA: "savanna", 
    DESERT: "desert",
    JUNGLE: "jungle",
    SWAMP: "swamp",
    GLACIER: "glacier",
    FOREST: "forest",
    BEACH: "beach",
}

# Preview colors (RGB) - matching map2
PREVIEW_COLORS = {
    OCEAN: (70, 130, 180),        # Ocean blue
    SAVANNA: (160, 165, 95),      # Light yellow-green grass
    SAVANNA_DARK: (130, 140, 75), # Darker grass  
    SAVANNA_TAN: (180, 160, 110), # Tan patches in grass
    DESERT: (210, 185, 125),      # Desert tan
    DESERT_GRASS: (150, 155, 90), # Grass patches in desert
    JUNGLE: (48, 100, 40),        # Deep green jungle
    SWAMP: (100, 85, 60),         # Brown swamp
    GLACIER: (245, 250, 255),     # White snow
    FOREST: (70, 100, 55),        # Dark forest green
    BEACH: (240, 230, 200),       # Sandy beach
}


def generate_smooth_noise(shape: tuple, scale: float, seed: int) -> np.ndarray:
    """Generate smooth blob-like noise using gaussian filtering."""
    np.random.seed(seed)
    noise = np.random.rand(*shape)
    smooth = gaussian_filter(noise, sigma=scale, mode='wrap')
    smooth = (smooth - smooth.min()) / (smooth.max() - smooth.min() + 1e-10)
    return smooth


def add_scattered_forest_patches(ids: np.ndarray, water: np.ndarray, seed: int = 1000) -> np.ndarray:
    """Add scattered dark forest patches throughout savanna - like map2.
    Map2 has LOTS of small dark green tree clumps scattered everywhere."""
    h, w = ids.shape
    result = ids.copy()
    
    # Generate multiple scales of blob noise
    # Smaller scales = more frequent, smaller patches
    large_blobs = generate_smooth_noise((h, w), scale=35, seed=seed)
    medium_blobs = generate_smooth_noise((h, w), scale=18, seed=seed + 1)
    small_blobs = generate_smooth_noise((h, w), scale=8, seed=seed + 2)
    tiny_blobs = generate_smooth_noise((h, w), scale=5, seed=seed + 3)
    
    # Combine with emphasis on smaller patches (more frequent)
    combined = large_blobs * 0.25 + medium_blobs * 0.3 + small_blobs * 0.25 + tiny_blobs * 0.2
    
    savanna_mask = ids == SAVANNA
    
    # Lower threshold = more forest patches (map2 has lots!)
    # Aiming for ~12-15% of savanna to be forest patches
    forest_threshold = 0.62
    forest_patches = savanna_mask & (combined > forest_threshold) & ~water
    
    result[forest_patches] = FOREST
    print(f"    Added {forest_patches.sum():,} forest patch pixels ({100*forest_patches.sum()/savanna_mask.sum():.1f}% of savanna)")
    
    return result


def add_tan_patches_in_savanna(ids: np.ndarray, water: np.ndarray, seed: int = 2000) -> np.ndarray:
    """Add scattered tan/dirt patches in savanna - like map2."""
    h, w = ids.shape
    result = ids.copy()
    
    # Multiple scales for tan patches
    tan_large = generate_smooth_noise((h, w), scale=25, seed=seed)
    tan_small = generate_smooth_noise((h, w), scale=10, seed=seed + 1)
    tan_noise = tan_large * 0.6 + tan_small * 0.4
    
    # Only in savanna (not forest patches we just added)
    savanna_mask = ids == SAVANNA
    
    # More tan patches - ~8% of remaining savanna
    tan_threshold = 0.68
    tan_patches = savanna_mask & (tan_noise > tan_threshold) & ~water
    
    result[tan_patches] = SAVANNA_TAN
    print(f"    Added {tan_patches.sum():,} tan patch pixels")
    
    return result


def add_grass_patches_in_desert(ids: np.ndarray, water: np.ndarray, seed: int = 3000) -> np.ndarray:
    """Add scattered grass patches inside desert - like map2."""
    h, w = ids.shape
    result = ids.copy()
    
    # Multiple noise layers for varied grass patches in desert
    grass_large = generate_smooth_noise((h, w), scale=30, seed=seed)
    grass_medium = generate_smooth_noise((h, w), scale=15, seed=seed + 1)
    grass_noise = grass_large * 0.5 + grass_medium * 0.5
    
    desert_mask = ids == DESERT
    
    # More grass patches in desert - like map2 shows
    grass_threshold = 0.35
    grass_patches = desert_mask & (grass_noise < grass_threshold) & ~water
    
    result[grass_patches] = DESERT_GRASS
    print(f"    Added {grass_patches.sum():,} grass-in-desert pixels ({100*grass_patches.sum()/max(1,desert_mask.sum()):.1f}% of desert)")
    
    return result


def apply_transition(ids: np.ndarray, biome_a: int, biome_b: int, 
                     width: int, seed: int) -> np.ndarray:
    """Apply patchy transition between two biomes."""
    h, w = ids.shape
    
    mask_a = ids == biome_a
    mask_b = ids == biome_b
    
    if not mask_a.any() or not mask_b.any():
        return ids
    
    # Distance from each biome
    dist_from_b = distance_transform_edt(~mask_b)
    dist_from_a = distance_transform_edt(~mask_a)
    
    # Transition zone
    in_a_zone = mask_a & (dist_from_b < width)
    in_b_zone = mask_b & (dist_from_a < width)
    transition_zone = in_a_zone | in_b_zone
    
    if not transition_zone.any():
        return ids
    
    # Generate blob noise for this transition
    noise = generate_smooth_noise((h, w), scale=width * 0.5, seed=seed)
    
    result = ids.copy()
    
    # Vectorized operation for speed
    ys, xs = np.where(transition_zone)
    da = dist_from_a[ys, xs]
    db = dist_from_b[ys, xs]
    
    total = da + db + 1e-10
    ratio = da / total
    
    threshold = 0.5 + (ratio - 0.5) * 1.0
    noise_vals = noise[ys, xs]
    
    choose_a = noise_vals < threshold
    result[ys[choose_a], xs[choose_a]] = biome_a
    result[ys[~choose_a], xs[~choose_a]] = biome_b
    
    return result


def apply_all_transitions(ids: np.ndarray, water: np.ndarray) -> np.ndarray:
    """Apply all map2-style features."""
    result = ids.copy()
    
    # 1. Add scattered forest patches in savanna (like map2)
    print("  Adding scattered forest patches...")
    result = add_scattered_forest_patches(result, water, seed=1000)
    
    # 2. Biome edge transitions
    print("  Applying biome transitions...")
    transition_pairs = [
        (SAVANNA, GLACIER, 50, 100),
        (SAVANNA, DESERT, 60, 200),
        (SAVANNA, JUNGLE, 50, 300),
        (SAVANNA, SWAMP, 50, 400),
        (JUNGLE, SWAMP, 35, 500),
        (FOREST, SAVANNA, 30, 600),   # Forest patches blend into savanna
        (FOREST, GLACIER, 25, 700),
        (FOREST, JUNGLE, 25, 800),
    ]
    
    for biome_a, biome_b, width, seed in transition_pairs:
        name_a = BIOME_NAMES.get(biome_a, str(biome_a))
        name_b = BIOME_NAMES.get(biome_b, str(biome_b))
        print(f"    {name_a} <-> {name_b}...")
        result = apply_transition(result, biome_a, biome_b, width, seed)
    
    # 3. Add tan patches in remaining savanna
    print("  Adding tan patches in savanna...")
    result = add_tan_patches_in_savanna(result, water, seed=2000)
    
    # 4. Add grass patches inside desert  
    print("  Adding grass patches in desert...")
    result = add_grass_patches_in_desert(result, water, seed=3000)
    
    # Restore water
    result[water] = ids[water]
    
    return result


def create_preview(ids: np.ndarray, water: np.ndarray | None = None) -> Image.Image:
    """Create a color preview matching map2 colors, rivers on top."""
    h, w = ids.shape
    rgb = np.zeros((h, w, 3), dtype=np.uint8)
    
    for biome_val, color in PREVIEW_COLORS.items():
        mask = ids == biome_val
        rgb[mask] = color
    
    # Unmapped -> savanna
    unmapped = ~np.isin(ids, list(PREVIEW_COLORS.keys()))
    if unmapped.any():
        rgb[unmapped] = PREVIEW_COLORS[SAVANNA]
    
    if water is not None:
        rgb[water] = (60, 130, 220)
    
    return Image.fromarray(rgb)


def main():
    print("Loading biome mask...")
    ids = np.array(Image.open(MASK_IN))
    print(f"  Size: {ids.shape}")
    
    # Load water layer
    water = np.zeros(ids.shape, dtype=bool)
    if WATER_PATH.exists():
        water_img = np.array(Image.open(WATER_PATH).convert('L'))
        if water_img.shape == ids.shape:
            water = water_img > 128
            print(f"  Water pixels: {water.sum():,}")
    
    unique = np.unique(ids)
    print(f"  Biomes found: {[BIOME_NAMES.get(u, u) for u in unique]}")
    
    print("Applying map2-style features...")
    t0 = time.time()
    result = apply_all_transitions(ids, water)
    print(f"  Done in {time.time() - t0:.1f}s")
    
    # Save mask
    print(f"Saving mask to {MASK_OUT}...")
    Image.fromarray(result.astype(np.uint8)).save(MASK_OUT)
    
    # Save preview
    print(f"Saving preview to {PREVIEW_OUT}...")
    preview = create_preview(result, water)
    preview.save(PREVIEW_OUT)
    
    print("Done!")
    return PREVIEW_OUT


if __name__ == "__main__":
    preview_path = main()
    print(f"\nPreview: {preview_path}")
