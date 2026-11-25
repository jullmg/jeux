"""Assemble plusieurs images en une planche, pour les comparer d'un coup d'œil.

Blender --background --python tools/blender/montage.py -- sortie.png colonnes largeur_case image1 image2…
"""
import sys

import bpy
import numpy as np

args = sys.argv[sys.argv.index("--") + 1:]
out, cols, width, files = args[0], int(args[1]), int(args[2]), args[3:]
tiles = []
for path in files:
    img = bpy.data.images.load(path)
    w, h = img.size
    new_h = max(1, round(h * width / w))
    img.scale(width, new_h)
    buf = np.empty(width * new_h * 4, dtype=np.float32)
    img.pixels.foreach_get(buf)
    tiles.append(buf.reshape(new_h, width, 4))
cell = max(t.shape[0] for t in tiles)
rows = (len(tiles) + cols - 1) // cols
sheet = np.zeros((rows * cell + (rows - 1) * 6, cols * width + (cols - 1) * 6, 4), dtype=np.float32)
sheet[..., 3] = 1
sheet[..., :3] = 0.08
for i, tile in enumerate(tiles):
    r, c = divmod(i, cols)
    y = sheet.shape[0] - r * (cell + 6) - tile.shape[0]
    x = c * (width + 6)
    sheet[y:y + tile.shape[0], x:x + width, :3] = tile[..., :3]
result = bpy.data.images.new("planche", sheet.shape[1], sheet.shape[0], alpha=True)
result.pixels.foreach_set(sheet.ravel())
result.filepath_raw = out
result.file_format = "PNG"
result.save()
print("PLANCHE", out)
