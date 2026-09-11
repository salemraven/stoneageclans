#!/usr/bin/env python3
"""
Generate a test image showing grass-to-snow biome transition
with patchy blending (discrete patches, not color gradients).
"""

import numpy as np
from PIL import Image, ImageDraw
from pathlib import Path
from scipy.ndimage import gaussian_filter
import math

# Output path
OUTPUT = Path(__file__).parent.parent / "maps" / "test_transition.png"

# Image size
WIDTH = 512
HEIGHT = 512

# Colors (RGB)
GRASS_GREEN = (124, 152, 80)      # Main grass
GRASS_DARK = (98, 128, 64)        # Darker grass patches
DIRT_BROWN = (139, 119, 85)       # Dirt patches in grass
SNOW_WHITE = (240, 245, 250)      # Main snow
SNOW_BLUE = (210, 225, 240)       # Icy patches
ROCK_GRAY = (128, 128, 128)       # Exposed rock in snow
CHARACTER_COLOR = (180, 100, 80)  # Simple character placeholder


def generate_smooth_noise(width: int, height: int, scale: float, seed: int = 42) -> np.ndarray:
    """Generate smooth blob-like noise using gaussian filtering."""
    np.random.seed(seed)
    # Start with random noise
    noise = np.random.rand(height, width)
    # Apply gaussian blur to create smooth blobs
    # Larger sigma = bigger blobs
    sigma = scale
    smooth = gaussian_filter(noise, sigma=sigma, mode='wrap')
    # Normalize to 0-1
    smooth = (smooth - smooth.min()) / (smooth.max() - smooth.min())
    return smooth

def generate_transition_image():
    """Generate the test transition image."""
    img = Image.new('RGB', (WIDTH, HEIGHT), GRASS_GREEN)
    pixels = img.load()
    
    # Pre-generate smooth noise layers (big blobs!)
    # sigma=40 means blobs roughly 80-120 pixels across
    big_blobs = generate_smooth_noise(WIDTH, HEIGHT, scale=50, seed=42)
    med_blobs = generate_smooth_noise(WIDTH, HEIGHT, scale=25, seed=123)
    small_detail = generate_smooth_noise(WIDTH, HEIGHT, scale=10, seed=456)
    
    # Internal texture noise
    grass_texture = generate_smooth_noise(WIDTH, HEIGHT, scale=30, seed=789)
    snow_texture = generate_smooth_noise(WIDTH, HEIGHT, scale=35, seed=321)
    
    # Transition zone parameters
    transition_start = WIDTH * 0.1   # Grass zone ends (left edge)
    transition_end = WIDTH * 0.9     # Snow zone starts (right edge)
    transition_width = transition_end - transition_start
    
    for y in range(HEIGHT):
        for x in range(WIDTH):
            # Get position in transition (0 = pure grass, 1 = pure snow)
            if x < transition_start:
                t = 0.0
            elif x > transition_end:
                t = 1.0
            else:
                t = (x - transition_start) / transition_width
            
            # Combine noise layers - big blobs dominate
            combined = big_blobs[y, x] * 0.6 + med_blobs[y, x] * 0.3 + small_detail[y, x] * 0.1
            
            # Threshold based on position
            # At t=0: threshold is 0.85 (very hard to be snow - need noise > 0.85)
            # At t=0.5: threshold is 0.5 (50/50)
            # At t=1: threshold is 0.15 (very easy to be snow - need noise > 0.15)
            threshold = 0.85 - t * 0.7
            
            is_snow = combined > threshold
            
            # Force pure zones at far edges
            if t < 0.02:
                is_snow = False
            elif t > 0.98:
                is_snow = True
            
            if is_snow:
                # Snow/glacier zone - internal texture patches
                tex = snow_texture[y, x]
                if tex > 0.75:
                    color = ROCK_GRAY  # Exposed rock patches
                elif tex > 0.4:
                    color = SNOW_BLUE  # Icy blue patches
                else:
                    color = SNOW_WHITE  # Normal snow
            else:
                # Grass zone - internal texture patches
                tex = grass_texture[y, x]
                if tex > 0.78:
                    color = DIRT_BROWN  # Bare dirt patches
                elif tex > 0.45:
                    color = GRASS_DARK  # Darker grass patches
                else:
                    color = GRASS_GREEN  # Normal grass
            
            pixels[x, y] = color
    
    # Draw a simple character for scale (64x64 pixels roughly)
    draw = ImageDraw.Draw(img)
    char_x = WIDTH // 2
    char_y = HEIGHT // 2
    char_size = 32  # Character is about 64 pixels tall total
    
    # Body (simple rectangle)
    draw.rectangle([
        char_x - 12, char_y - char_size,
        char_x + 12, char_y + char_size - 10
    ], fill=CHARACTER_COLOR, outline=(100, 60, 50))
    
    # Head (circle)
    head_radius = 10
    draw.ellipse([
        char_x - head_radius, char_y - char_size - head_radius * 2,
        char_x + head_radius, char_y - char_size
    ], fill=(210, 170, 140), outline=(100, 60, 50))
    
    # Legs
    draw.rectangle([
        char_x - 10, char_y + char_size - 10,
        char_x - 3, char_y + char_size + 15
    ], fill=(80, 60, 50))
    draw.rectangle([
        char_x + 3, char_y + char_size - 10,
        char_x + 10, char_y + char_size + 15
    ], fill=(80, 60, 50))
    
    # Add label
    # Simple text simulation with rectangles
    label_y = 20
    draw.rectangle([10, label_y - 5, 200, label_y + 15], fill=(0, 0, 0, 128))
    
    # Save
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    img.save(OUTPUT)
    print(f"Saved: {OUTPUT}")
    return OUTPUT

if __name__ == "__main__":
    path = generate_transition_image()
    print(f"Test transition image created at: {path}")
