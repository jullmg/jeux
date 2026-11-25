"""L'icône du jeu : la tête de Blanche sur un carré rose arrondi (art/icon.png).

Blender --background --python tools/blender/icon.py
"""
import math
import pathlib
import sys
import tempfile

sys.path.insert(0, str(pathlib.Path(__file__).parent))
import common as C  # noqa: E402
import bpy  # noqa: E402
import numpy as np  # noqa: E402
from mathutils import Vector  # noqa: E402

SIZE = 1024
C.reset()
bpy.ops.import_scene.gltf(filepath=str(C.MODELS / "blanche.glb"))
scene = bpy.context.scene
cam_data = bpy.data.cameras.new("cam")
cam_data.angle = math.radians(24)
cam = bpy.data.objects.new("cam", cam_data)
scene.collection.objects.link(cam)
eye, target = (0.42, 0.78, 1.55), (0.0, 0.615, 0.38)
cam.location = C.G(eye)
cam.rotation_euler = (Vector(C.G(target)) - Vector(C.G(eye))).to_track_quat("-Z", "Y").to_euler()
scene.camera = cam
for rot, energy, color in (((42, -28, 0), 3.0, (1.0, 0.95, 0.9)), ((60, 120, 0), 2.2, (0.85, 0.9, 1.0)),
                           ((20, 210, 0), 2.5, (1.0, 0.85, 0.9))):
    light = bpy.data.lights.new("sun", "SUN")
    light.energy = energy
    light.color = color
    ob = bpy.data.objects.new("sun", light)
    ob.rotation_euler = [math.radians(v) for v in rot]
    scene.collection.objects.link(ob)
world = bpy.data.worlds.new("w")
world.use_nodes = True
world.node_tree.nodes["Background"].inputs["Color"].default_value = (0.6, 0.55, 0.55, 1)
scene.world = world
scene.render.engine = "BLENDER_EEVEE"
scene.view_settings.view_transform = "Standard"
scene.render.film_transparent = True
scene.render.resolution_x = scene.render.resolution_y = SIZE
path = pathlib.Path(tempfile.mkdtemp()) / "tete.png"
scene.render.filepath = str(path)
bpy.ops.render.render(write_still=True)

head = bpy.data.images.load(str(path))
buf = np.empty(SIZE * SIZE * 4, dtype=np.float32)
head.pixels.foreach_get(buf)
head_px = buf.reshape(SIZE, SIZE, 4)
y, x = np.mgrid[0:SIZE, 0:SIZE].astype(np.float32)
# carré arrondi (marge comme les icônes de macOS)
margin, radius = 80.0, 200.0
half = SIZE / 2 - margin
qx = np.maximum(np.abs(x - SIZE / 2) - (half - radius), 0)
qy = np.maximum(np.abs(y - SIZE / 2) - (half - radius), 0)
inside = np.clip(radius - np.sqrt(qx ** 2 + qy ** 2) + 0.5, 0, 1)
light = np.clip(1 - np.sqrt((x - SIZE * 0.5) ** 2 + (y - SIZE * 0.62) ** 2) / (SIZE * 0.6), 0, 1)
bg = np.zeros((SIZE, SIZE, 3), dtype=np.float32)
bg[:] = np.array(C.srgb("#c9527f"))
bg += (np.array(C.srgb("#ffd1c2")) - np.array(C.srgb("#c9527f"))) * light[..., None]
alpha = head_px[..., 3:4]
rgb = head_px[..., :3] * alpha + bg * (1 - alpha)
# liseré doré
ring = np.clip(inside - np.clip(radius - 18 - np.sqrt(qx ** 2 + qy ** 2) + 0.5, 0, 1), 0, 1)
ring *= (np.maximum(np.abs(x - SIZE / 2), np.abs(y - SIZE / 2)) > half - radius).astype(np.float32)
edge = (np.maximum(np.abs(x - SIZE / 2), np.abs(y - SIZE / 2)) > half - 18).astype(np.float32) * inside
gold = np.clip(ring + edge, 0, 1)[..., None]
rgb = rgb * (1 - gold) + np.array(C.srgb("#ffc83d")) * gold
out = np.zeros((SIZE, SIZE, 4), dtype=np.float32)
out[..., :3] = rgb
out[..., 3] = inside
result = bpy.data.images.new("icone", SIZE, SIZE, alpha=True)
result.pixels.foreach_set(out.ravel())
result.filepath_raw = str(C.ROOT / "art" / "icon.png")
result.file_format = "PNG"
result.save()
print("EXPORT", result.filepath_raw)
