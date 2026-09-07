#!/usr/bin/env bash
# Rebuild the island biome mask from map2 — deterministic, one command.
#
#   bash tools/rebuild_island_biomes.sh          # rebuild + validate
#   bash tools/rebuild_island_biomes.sh --check  # validate only
#
# Pipeline (each step is its own tool, all seeded from island_meta.json world_seed):
#   0. water_layer.png  <- water_layer_guides.png   (hand-painted rivers are the truth)
#   1. reset land -> savanna (ocean + rivers untouched)
#   2. paint regional biomes from map2 colours + wedge clamps (glacier, desert, jungle, swamp)
#   3. shape regions: drop stray blobs, smooth, seeded domain-warp  (organic borders)
#   4. speck cleanup 3/4 rule + desert-off-river + ocean topology
#   5. --check-only gate (specks, topology, straight borders >= 20 tiles)
#   6. render maps/island/preview_biomes.png for eyeballing
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

MASK=maps/island/biome_mask.png
WATER=maps/island/water_layer.png
GUIDES=maps/island/water_layer_guides.png

if [[ "${1:-}" == "--check" ]]; then
	python3 tools/clean_biome_mask_specks.py --check-only
	exit $?
fi

echo "== 0. rivers <- guides"
cp "$GUIDES" "$WATER"

echo "== 1. reset land to savanna"
python3 - <<'EOF'
import sys; sys.path.insert(0, "tools")
import numpy as np
from PIL import Image
from clean_biome_mask_specks import ids_from_mask, encode_ids, load_water, OCEAN, SAVANNA
p = "maps/island/biome_mask.png"
ids = ids_from_mask(np.array(Image.open(p)))
is_water = load_water(__import__("pathlib").Path("maps/island/water_layer.png"), ids.shape)
ids[(ids != OCEAN) & ~is_water] = SAVANNA
Image.fromarray(encode_ids(ids)).save(p)
print("   land reset")
EOF

echo "== 2. paint from map2"
for b in glacier desert jungle swamp; do
	python3 tools/paint_biome_from_map2.py --biome "$b"
done

echo "== 3. shape regions"
python3 tools/shape_biome_regions.py

echo "== 4. speck + topology cleanup"
python3 tools/clean_biome_mask_specks.py

echo "== 5. gate"
python3 tools/clean_biome_mask_specks.py --check-only

echo "== 6. preview"
python3 tools/render_biome_preview.py
