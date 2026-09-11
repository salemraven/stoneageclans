#!/usr/bin/env bash
# Rebuild the island biome mask from map2 — deterministic, one command.
#
#   bash tools/rebuild_island_biomes.sh          # rebuild at 4096x4096 (default)
#   bash tools/rebuild_island_biomes.sh --size 1024  # legacy 1024x1024
#   bash tools/rebuild_island_biomes.sh --check  # validate only
#
# Pipeline (each step is its own tool, all seeded from island_meta.json world_seed):
#   0. water_layer.png  <- water_layer_guides.png (upscaled to match mask size)
#   1. reset land -> savanna (ocean + rivers untouched)
#   2. paint regional biomes from map2 colours + wedge clamps (glacier, desert, jungle, swamp)
#   3. shape regions: drop stray blobs, smooth, seeded domain-warp  (organic borders)
#   4. speck cleanup 3/4 rule + desert-off-river + ocean topology
#   5. --check-only gate (specks, topology, straight borders >= 28 tiles scaled)
#   6. render maps/island/preview_biomes.png for eyeballing
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

MASK_SIZE=4096
while [[ $# -gt 0 ]]; do
	case "$1" in
		--check)
			python3 tools/log_island_map_build.py
			python3 tools/bake_river_distance.py
			python3 tools/clean_biome_mask_specks.py --check-only || echo "WARN: speck/topology check failed (existing mask)"
			exit 0
			;;
		--size)
			MASK_SIZE="$2"
			shift 2
			;;
		*)
			echo "Unknown arg: $1"; exit 1
			;;
	esac
done

MASK=maps/island/biome_mask.png
WATER=maps/island/water_layer.png
GUIDES=maps/island/water_layer_guides.png
META=maps/island/island_meta.json

echo "== 0. rivers <- guides (upscaled to ${MASK_SIZE}x${MASK_SIZE})"
python3 - "$GUIDES" "$WATER" "$MASK_SIZE" <<'EOF'
from PIL import Image
import sys
src, dst, size = sys.argv[1], sys.argv[2], int(sys.argv[3])
img = Image.open(src).convert("L")
if img.size != (size, size):
    img = img.resize((size, size), Image.Resampling.NEAREST)
img.save(dst)
print(f"   water layer {img.size[0]}x{img.size[1]}")
EOF

echo "== 1. reset land to savanna (${MASK_SIZE}x${MASK_SIZE})"
python3 - "$MASK" "$WATER" "$MASK_SIZE" <<'EOF'
import sys; sys.path.insert(0, "tools")
import numpy as np
from PIL import Image
from clean_biome_mask_specks import ids_from_mask, encode_ids, load_water, OCEAN, SAVANNA

p, water_p, size = sys.argv[1], sys.argv[2], int(sys.argv[3])
# Load or create mask at target size
try:
    img = Image.open(p)
    if img.size != (size, size):
        img = img.resize((size, size), Image.Resampling.NEAREST)
    ids = ids_from_mask(np.array(img))
except FileNotFoundError:
    ids = np.full((size, size), OCEAN, dtype=np.uint8)

is_water = load_water(__import__("pathlib").Path(water_p), (size, size))
ids[(ids != OCEAN) & ~is_water] = SAVANNA
Image.fromarray(encode_ids(ids)).save(p)
print(f"   land reset {size}x{size}")
EOF

echo "== 2. paint from map2"
for b in glacier desert jungle swamp; do
	python3 tools/paint_biome_from_map2.py --biome "$b"
done

echo "== 3. shape regions"
python3 tools/shape_biome_regions.py

echo "== 4. speck + topology cleanup"
python3 tools/clean_biome_mask_specks.py

echo "== 5. update island_meta.json"
python3 - "$META" "$MASK_SIZE" <<'EOF'
import json, sys
meta_path, size = sys.argv[1], int(sys.argv[2])
meta = json.loads(open(meta_path).read())
meta["mask_size"] = size
meta["sample_stride_px"] = 65536 // size  # world_width / mask_size
open(meta_path, "w").write(json.dumps(meta, indent=2) + "\n")
print(f"   mask_size={size}, stride={meta['sample_stride_px']}px")
EOF

echo "== 6. gate"
python3 tools/clean_biome_mask_specks.py --check-only

echo "== 7. preview"
python3 tools/render_biome_preview.py

echo "== 8. map build log"
python3 tools/log_island_map_build.py

echo "== 9. river distance bake"
python3 tools/bake_river_distance.py

echo "=== Done: ${MASK_SIZE}x${MASK_SIZE} mask generated ==="
