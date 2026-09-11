#!/usr/bin/env python3
"""
Generate realistic biome transitions using fractal noise.
- Jagged, irregular edges (not smooth blobs)
- Varied patch sizes
- Forests denser near rivers
- Natural terrain logic
"""

import numpy as np
from PIL import Image
from scipy.ndimage import distance_transform_edt, binary_dilation
from pathlib import Path
import time
import math

# Paths
REPO = Path(__file__).parent.parent
MASK_IN = REPO / "maps" / "island" / "biome_mask_original.png"
MASK_OUT = REPO / "maps" / "island" / "biome_mask.png"
PREVIEW_OUT = REPO / "maps" / "island" / "preview_realistic.png"
WATER_PATH = REPO / "maps" / "island" / "water_layer.png"

# Biome IDs
SCALE = 28.33
OCEAN = 0
SAVANNA = round(1 * SCALE)
DESERT = round(2 * SCALE)
JUNGLE = round(3 * SCALE)
SWAMP = round(4 * SCALE)
GLACIER = round(5 * SCALE)
FOREST = round(6 * SCALE)
BEACH = round(8 * SCALE)

# Sub-biome markers for preview
SAVANNA_TAN = 29
DESERT_GRASS = 31

BIOME_NAMES = {
    OCEAN: "ocean", SAVANNA: "savanna", DESERT: "desert",
    JUNGLE: "jungle", SWAMP: "swamp", GLACIER: "glacier",
    FOREST: "forest", BEACH: "beach",
}

# Preview colors matching map2
PREVIEW_COLORS = {
    OCEAN: (70, 130, 180),
    SAVANNA: (160, 165, 95),
    SAVANNA_TAN: (175, 160, 110),
    DESERT: (210, 185, 125),
    DESERT_GRASS: (150, 155, 90),
    JUNGLE: (48, 100, 40),
    SWAMP: (100, 85, 60),
    GLACIER: (245, 250, 255),
    FOREST: (55, 85, 45),
    BEACH: (240, 230, 200),
}


# ============ PERLIN NOISE IMPLEMENTATION ============

def fade(t):
    """Perlin fade function for smooth interpolation."""
    return t * t * t * (t * (t * 6 - 15) + 10)

def lerp(a, b, t):
    return a + t * (b - a)

def grad(hash_val, x, y):
    """Gradient function for 2D Perlin noise."""
    h = hash_val & 7
    u = x if h < 4 else y
    v = y if h < 4 else x
    return (u if (h & 1) == 0 else -u) + (v if (h & 2) == 0 else -v)

class PerlinNoise:
    """2D Perlin noise generator."""
    
    def __init__(self, seed=0):
        np.random.seed(seed)
        self.p = np.arange(256, dtype=int)
        np.random.shuffle(self.p)
        self.p = np.tile(self.p, 2)
    
    def noise(self, x, y):
        """Generate Perlin noise at coordinates."""
        X = int(math.floor(x)) & 255
        Y = int(math.floor(y)) & 255
        
        x -= math.floor(x)
        y -= math.floor(y)
        
        u = fade(x)
        v = fade(y)
        
        A = self.p[X] + Y
        B = self.p[X + 1] + Y
        
        return lerp(
            lerp(grad(self.p[A], x, y), grad(self.p[B], x - 1, y), u),
            lerp(grad(self.p[A + 1], x, y - 1), grad(self.p[B + 1], x - 1, y - 1), u),
            v
        )


def fractal_noise(x, y, perlin, octaves=6, persistence=0.5, lacunarity=2.0, scale=0.01):
    """Multi-octave fractal noise for natural-looking patterns."""
    total = 0
    amplitude = 1
    frequency = scale
    max_value = 0
    
    for _ in range(octaves):
        total += perlin.noise(x * frequency, y * frequency) * amplitude
        max_value += amplitude
        amplitude *= persistence
        frequency *= lacunarity
    
    return (total / max_value + 1) / 2  # Normalize to 0-1


def ridged_noise(x, y, perlin, octaves=4, scale=0.01):
    """Ridged noise for mountain/glacier patterns."""
    total = 0
    amplitude = 1
    frequency = scale
    
    for _ in range(octaves):
        n = perlin.noise(x * frequency, y * frequency)
        n = 1 - abs(n)  # Create ridges
        n = n * n  # Sharpen ridges
        total += n * amplitude
        amplitude *= 0.5
        frequency *= 2.0
    
    return total / 2


def generate_fractal_map(shape, scale, octaves, seed):
    """Generate a full noise map with fractal noise."""
    h, w = shape
    perlin = PerlinNoise(seed)
    result = np.zeros(shape)
    
    for y in range(h):
        for x in range(w):
            result[y, x] = fractal_noise(x, y, perlin, octaves=octaves, scale=scale)
    
    return result


def generate_ridged_map(shape, scale, octaves, seed):
    """Generate ridged noise map for glacier/mountain."""
    h, w = shape
    perlin = PerlinNoise(seed)
    result = np.zeros(shape)
    
    for y in range(h):
        for x in range(w):
            result[y, x] = ridged_noise(x, y, perlin, octaves=octaves, scale=scale)
    
    return result


# ============ BIOME GENERATION ============

def add_forest_patches(ids, water, river_dist, seed=1000):
    """Add forests with varied sizes, denser near rivers."""
    h, w = ids.shape
    result = ids.copy()
    
    print("    Generating fractal forest noise...")
    # Multiple noise layers at different scales
    large_noise = generate_fractal_map((h, w), scale=0.008, octaves=5, seed=seed)
    medium_noise = generate_fractal_map((h, w), scale=0.02, octaves=4, seed=seed+1)
    small_noise = generate_fractal_map((h, w), scale=0.05, octaves=3, seed=seed+2)
    
    # Combine with emphasis on varied sizes
    combined = large_noise * 0.4 + medium_noise * 0.35 + small_noise * 0.25
    
    # River influence - forests more likely near rivers (but not IN water)
    # river_dist: 0 at river, higher values further away
    river_boost = np.clip(1.0 - (river_dist / 100), 0, 0.3)  # Up to 0.3 boost near rivers
    
    savanna_mask = ids == SAVANNA
    
    # Threshold with river boost - forests appear where noise > threshold
    # Higher threshold = less forest
    base_threshold = 0.82  # Target ~15-20% of savanna as forest
    threshold_map = base_threshold - river_boost
    
    forest_mask = savanna_mask & (combined > threshold_map) & ~water
    
    result[forest_mask] = FOREST
    pct = 100 * forest_mask.sum() / max(1, savanna_mask.sum())
    print(f"    Added {forest_mask.sum():,} forest pixels ({pct:.1f}% of savanna)")
    
    return result


def add_tan_patches(ids, water, seed=2000):
    """Add tan/dirt patches in savanna with irregular shapes."""
    h, w = ids.shape
    result = ids.copy()
    
    print("    Generating fractal tan patch noise...")
    noise = generate_fractal_map((h, w), scale=0.03, octaves=4, seed=seed)
    
    savanna_mask = ids == SAVANNA
    tan_mask = savanna_mask & (noise > 0.68) & ~water
    
    result[tan_mask] = SAVANNA_TAN
    print(f"    Added {tan_mask.sum():,} tan patch pixels")
    
    return result


def add_grass_in_desert(ids, water, seed=3000):
    """Add scattered grass patches inside desert."""
    h, w = ids.shape
    result = ids.copy()
    
    print("    Generating fractal desert grass noise...")
    noise = generate_fractal_map((h, w), scale=0.02, octaves=5, seed=seed)
    
    desert_mask = ids == DESERT
    grass_mask = desert_mask & (noise < 0.32) & ~water
    
    result[grass_mask] = DESERT_GRASS
    pct = 100 * grass_mask.sum() / max(1, desert_mask.sum())
    print(f"    Added {grass_mask.sum():,} grass-in-desert pixels ({pct:.1f}%)")
    
    return result


def apply_biome_transition(ids, biome_a, biome_b, width, seed):
    """Apply jagged transition between two biomes using fractal noise."""
    h, w = ids.shape
    
    mask_a = ids == biome_a
    mask_b = ids == biome_b
    
    if not mask_a.any() or not mask_b.any():
        return ids
    
    dist_from_b = distance_transform_edt(~mask_b)
    dist_from_a = distance_transform_edt(~mask_a)
    
    # Transition zone
    in_a_zone = mask_a & (dist_from_b < width)
    in_b_zone = mask_b & (dist_from_a < width)
    transition_zone = in_a_zone | in_b_zone
    
    if not transition_zone.any():
        return ids
    
    # Generate fractal noise for this transition (NOT gaussian blur!)
    perlin = PerlinNoise(seed)
    
    result = ids.copy()
    ys, xs = np.where(transition_zone)
    
    for y, x in zip(ys, xs):
        da = dist_from_a[y, x]
        db = dist_from_b[y, x]
        
        # Position ratio
        total = da + db + 1e-10
        ratio = da / total  # 0 = at biome_a, 1 = at biome_b
        
        # Use fractal noise for jagged boundary
        noise_val = fractal_noise(x, y, perlin, octaves=4, scale=0.02)
        
        # Threshold based on position - with noise offset for jagged edge
        threshold = ratio + (noise_val - 0.5) * 0.4
        
        if threshold < 0.5:
            result[y, x] = biome_a
        else:
            result[y, x] = biome_b
    
    return result


def apply_all_features(ids, water):
    """Apply all realistic biome features."""
    result = ids.copy()
    
    # Calculate river distance for forest placement
    print("  Calculating river distances...")
    river_dist = distance_transform_edt(~water)
    
    # 1. Biome transitions with fractal noise (jagged edges)
    print("  Applying biome transitions...")
    transitions = [
        (SAVANNA, GLACIER, 40, 100),
        (SAVANNA, DESERT, 50, 200),
        (SAVANNA, JUNGLE, 45, 300),
        (SAVANNA, SWAMP, 45, 400),
        (JUNGLE, SWAMP, 30, 500),
    ]
    
    for biome_a, biome_b, width, seed in transitions:
        name_a = BIOME_NAMES.get(biome_a, str(biome_a))
        name_b = BIOME_NAMES.get(biome_b, str(biome_b))
        print(f"    {name_a} <-> {name_b}...")
        result = apply_biome_transition(result, biome_a, biome_b, width, seed)
    
    # 2. Add forests (varied sizes, river-aware)
    print("  Adding forest patches...")
    result = add_forest_patches(result, water, river_dist, seed=1000)
    
    # 3. Forest transitions
    print("  Blending forest edges...")
    result = apply_biome_transition(result, FOREST, SAVANNA, 20, 600)
    
    # 4. Tan patches in savanna
    print("  Adding tan patches...")
    result = add_tan_patches(result, water, seed=2000)
    
    # 5. Grass in desert
    print("  Adding grass in desert...")
    result = add_grass_in_desert(result, water, seed=3000)
    
    # Restore water
    result[water] = ids[water]
    
    return result


def create_preview(ids, water=None):
    """Create color preview with rivers on top."""
    h, w = ids.shape
    rgb = np.zeros((h, w, 3), dtype=np.uint8)
    
    for biome_val, color in PREVIEW_COLORS.items():
        mask = ids == biome_val
        rgb[mask] = color
    
    unmapped = ~np.isin(ids, list(PREVIEW_COLORS.keys()))
    if unmapped.any():
        rgb[unmapped] = PREVIEW_COLORS[SAVANNA]
    
    if water is not None:
        rgb[water] = (60, 130, 220)
    
    return Image.fromarray(rgb)


def main():
    print("Loading biome mask...")
    
    # Use original if available
    if MASK_IN.exists():
        ids = np.array(Image.open(MASK_IN))
    else:
        ids = np.array(Image.open(MASK_OUT))
    
    print(f"  Size: {ids.shape}")
    
    # Load water
    water = np.zeros(ids.shape, dtype=bool)
    if WATER_PATH.exists():
        water_img = np.array(Image.open(WATER_PATH).convert('L'))
        if water_img.shape == ids.shape:
            water = water_img > 128
            print(f"  Water pixels: {water.sum():,}")
    
    print(f"  Biomes: {[BIOME_NAMES.get(u, u) for u in np.unique(ids)]}")
    
    print("Applying realistic biome features (fractal noise)...")
    t0 = time.time()
    result = apply_all_features(ids, water)
    print(f"  Done in {time.time() - t0:.1f}s")
    
    print(f"Saving mask to {MASK_OUT}...")
    Image.fromarray(result.astype(np.uint8)).save(MASK_OUT)
    
    print(f"Saving preview to {PREVIEW_OUT}...")
    preview = create_preview(result, water)
    preview.save(PREVIEW_OUT)
    
    print("Done!")
    return PREVIEW_OUT


if __name__ == "__main__":
    main()
