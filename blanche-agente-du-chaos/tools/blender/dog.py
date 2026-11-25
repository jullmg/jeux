"""Blanche : chienne noire, oreilles tombantes, yeux ambrés, tache blanche au poitrail, bout des pattes blanc.

Une seule peau lissée, un squelette, et des pièces rigides (yeux, truffe, collier). Elle regarde vers +z.
Blender --background --python tools/blender/dog.py
"""
import math
import pathlib
import random
import sys

sys.path.insert(0, str(pathlib.Path(__file__).parent))
import common as C  # noqa: E402
import bpy  # noqa: E402
from mathutils import Matrix, Vector, noise  # noqa: E402

C.reset()
rng = random.Random(8)


# ---------------------------------------------------------------- squelette

BONES = [
    ("root", None, (0, 0, 0), (0, 0.1, 0)),
    ("hips", "root", (0, 0.40, -0.22), (0, 0.41, -0.08)),
    ("spine", "hips", (0, 0.41, -0.08), (0, 0.42, 0.07)),
    ("chest", "spine", (0, 0.42, 0.07), (0, 0.44, 0.20)),
    ("neck", "chest", (0, 0.48, 0.20), (0, 0.60, 0.31)),
    ("head", "neck", (0, 0.60, 0.31), (0, 0.66, 0.40)),
    ("jaw", "head", (0, 0.605, 0.39), (0, 0.585, 0.53)),
    ("tail1", "hips", (0, 0.44, -0.33), (0, 0.46, -0.45)),
    ("tail2", "tail1", (0, 0.46, -0.45), (0, 0.46, -0.56)),
    ("tail3", "tail2", (0, 0.46, -0.56), (0, 0.44, -0.66)),
]
for side, s in (("L", 1), ("R", -1)):
    BONES += [
        ("ear" + side, "head", (0.092 * s, 0.745, 0.335), (0.145 * s, 0.60, 0.345)),
        ("lid" + side, "head", (0.052 * s, 0.713, 0.462), (0.052 * s, 0.713, 0.49)),
        ("brow" + side, "head", (0.052 * s, 0.742, 0.462), (0.052 * s, 0.742, 0.49)),
        ("shoulder" + side, "chest", (0.088 * s, 0.40, 0.155), (0.095 * s, 0.225, 0.145)),
        ("elbow" + side, "shoulder" + side, (0.095 * s, 0.225, 0.145), (0.097 * s, 0.065, 0.165)),
        ("paw" + side, "elbow" + side, (0.097 * s, 0.065, 0.165), (0.098 * s, 0.025, 0.235)),
        ("thigh" + side, "hips", (0.088 * s, 0.39, -0.235), (0.10 * s, 0.235, -0.165)),
        ("knee" + side, "thigh" + side, (0.10 * s, 0.235, -0.165), (0.10 * s, 0.105, -0.27)),
        ("hock" + side, "knee" + side, (0.10 * s, 0.105, -0.27), (0.10 * s, 0.045, -0.25)),
        ("hpaw" + side, "hock" + side, (0.10 * s, 0.045, -0.25), (0.10 * s, 0.022, -0.185)),
    ]
armature = C.make_armature("Squelette", BONES)

# ---------------------------------------------------------------- la peau

coat = C.material("poil", "#ffffff", 0.58, vertex_colors=True)
body = C.Obj("Peau")
body.ball((0, 0.415, -0.04), (0.128, 0.128, 0.24), coat, seg=24, rings=18)
body.ball((0, 0.405, 0.12), (0.132, 0.155, 0.15), coat, seg=24, rings=18)
body.ball((0, 0.41, -0.225), (0.125, 0.125, 0.135), coat, seg=24, rings=18)
body.tube([(0, 0.43, 0.15), (0, 0.54, 0.245), (0, 0.63, 0.32)], [0.112, 0.085, 0.072], coat, seg=20)
# tête ronde, front marqué, museau large
body.ball((0, 0.678, 0.365), (0.106, 0.100, 0.108), coat, seg=24, rings=18)
body.ball((0, 0.714, 0.40), (0.078, 0.058, 0.072), coat)
body.tube([(0, 0.668, 0.41), (0, 0.652, 0.495), (0, 0.648, 0.535)], [0.066, 0.052, 0.044], coat, seg=18,
          squash=(1.05, 0.82))
for s in (1, -1):
    body.ball((0.045 * s, 0.642, 0.448), (0.038, 0.035, 0.05), coat)
    body.ball((0.062 * s, 0.653, 0.40), (0.044, 0.045, 0.045), coat)
    # arcades sourcilières
    body.ball((0.048 * s, 0.74, 0.442), (0.034, 0.017, 0.028), coat)
    # pattes avant
    body.tube([(0.078 * s, 0.42, 0.15), (0.092 * s, 0.31, 0.145), (0.095 * s, 0.22, 0.147), (0.097 * s, 0.075, 0.163)],
              [0.072, 0.047, 0.036, 0.031], coat, seg=16)
    body.ball((0.098 * s, 0.034, 0.188), (0.044, 0.034, 0.058), coat)
    for t in (-1, 0, 1):
        body.ball((0.098 * s + t * 0.025, 0.022, 0.232 - abs(t) * 0.008), (0.016, 0.019, 0.022), coat, seg=10, rings=8)
    # pattes arrière
    body.ball((0.082 * s, 0.37, -0.225), (0.062, 0.095, 0.098), coat)
    body.tube([(0.085 * s, 0.37, -0.215), (0.10 * s, 0.235, -0.165), (0.10 * s, 0.112, -0.268), (0.10 * s, 0.05, -0.252)],
              [0.073, 0.044, 0.028, 0.028], coat, seg=16)
    body.ball((0.10 * s, 0.032, -0.222), (0.041, 0.031, 0.055), coat)
    for t in (-1, 0, 1):
        body.ball((0.10 * s + t * 0.023, 0.021, -0.182 - abs(t) * 0.007), (0.015, 0.018, 0.021), coat, seg=10, rings=8)
# queue touffue
body.tube([(0, 0.435, -0.31), (0, 0.46, -0.44), (0, 0.462, -0.55), (0, 0.445, -0.665)], [0.054, 0.045, 0.036, 0.012],
          coat, seg=14, squash=(0.8, 1.2))
# franges : poitrail, culotte, dessous de la queue
for _ in range(34):
    p = Vector((rng.uniform(-0.07, 0.07), rng.uniform(0.34, 0.47), rng.uniform(0.215, 0.25)))
    body.tube([p, p + Vector((p.x * 0.25, -0.045, 0.012))], [0.026, 0.004], coat, seg=8, cap_rings=2)
for i in range(16):
    z = -0.36 - i * 0.018
    p = Vector((rng.uniform(-0.012, 0.012), 0.44, z))
    body.tube([p, p + Vector((0, -0.075 + i * 0.002, -0.03))], [0.022, 0.003], coat, seg=8, cap_rings=2)
for s in (1, -1):
    for i in range(6):
        p = Vector((0.07 * s, 0.38 - i * 0.022, -0.29 + i * 0.012))
        body.tube([p, p + Vector((0.008 * s, -0.05, -0.028))], [0.022, 0.003], coat, seg=8, cap_rings=2)

skin = body.build()
bpy.context.view_layer.objects.active = skin
skin.select_set(True)
remesh = skin.modifiers.new("remaillage", "REMESH")
remesh.mode = "VOXEL"
remesh.voxel_size = 0.0075
bpy.ops.object.modifier_apply(modifier=remesh.name)
smooth = skin.modifiers.new("lissage", "SMOOTH")
smooth.factor = 0.7
smooth.iterations = 5
bpy.ops.object.modifier_apply(modifier=smooth.name)
dec = skin.modifiers.new("allegement", "DECIMATE")
dec.ratio = 0.42
bpy.ops.object.modifier_apply(modifier=dec.name)
for p in skin.data.polygons:
    p.use_smooth = True


def to_godot(v):
    return Vector((v.x, v.z, -v.y))


# couleurs peintes aux sommets
mesh = skin.data
colors = mesh.color_attributes.new("Col", "FLOAT_COLOR", "POINT")
black = Vector(C.lin(C.srgb("#171417")))
brown = Vector(C.lin(C.srgb("#231b18")))
white = Vector(C.lin(C.srgb("#e9e4da")))
grey = Vector(C.lin(C.srgb("#6c6663")))


def smoothstep(a, b, x):
    t = max(0.0, min(1.0, (x - a) / (b - a)))
    return t * t * (3 - 2 * t)


for i, v in enumerate(mesh.vertices):
    p = to_godot(v.co)
    n = noise.noise(p * 38.0)
    c = black.lerp(brown, max(0.0, noise.noise(p * 7.0)) * 0.8) * (1.0 + 0.22 * noise.noise(p * 90.0))
    # tache blanche au poitrail
    d = math.sqrt(((p.x + 0.006) / 0.048) ** 2 + ((p.y - 0.365) / 0.062) ** 2) + n * 0.28
    if p.z > 0.19 and d < 1.15:
        c = c.lerp(white, 1.0 - smoothstep(0.78, 1.12, d))
    # bout des pattes
    if p.y < 0.052:
        front = p.z > 0.0
        edge = (p.z - (0.205 if front else -0.21)) / 0.02 + n * 0.8
        if edge > 0:
            c = c.lerp(white, smoothstep(0.0, 0.9, edge) * (1.0 - smoothstep(0.036, 0.052, p.y)))
    # un soupçon de poil clair sous la lèvre
    d = math.sqrt((p.x / 0.03) ** 2 + ((p.y - 0.605) / 0.016) ** 2 + ((p.z - 0.505) / 0.045) ** 2) + n * 0.3
    if d < 1.0:
        c = c.lerp(grey, 0.55 * (1.0 - d))
    colors.data[i].color = (c.x, c.y, c.z, 1.0)

# poids du squelette : distance à chaque os (capsules), sans mélanger la gauche et la droite
RADII = {"hips": 0.12, "spine": 0.12, "chest": 0.135, "neck": 0.078, "head": 0.10, "tail1": 0.045, "tail2": 0.04,
         "tail3": 0.035, "shoulder": 0.042, "elbow": 0.032, "paw": 0.035, "thigh": 0.058, "knee": 0.033,
         "hock": 0.028, "hpaw": 0.034}
segments = []
for name, _parent, head, tail in BONES:
    base = name[:-1] if name[-1] in "LR" else name
    if base not in RADII:
        continue
    segments.append((name, base, Vector(head), Vector(tail), RADII[base]))
groups = {name: skin.vertex_groups.new(name=name) for name, *_ in segments}
LIMBS = {"shoulder", "elbow", "paw", "thigh", "knee", "hock", "hpaw"}
for i, v in enumerate(mesh.vertices):
    p = to_godot(v.co)
    scores = []
    for name, base, a, b, r in segments:
        if base in LIMBS:
            s = 1 if name.endswith("L") else -1
            if p.x * s < 0.012 or p.y > 0.45:
                continue
        if base == "head" and (p.z < 0.28 or p.y < 0.56):
            continue
        if base.startswith("tail") and p.z > -0.31:
            continue
        d = max(0.0, C.segment_distance(p, a, b) - r * 0.82)
        scores.append((1.0 / (d + 0.011) ** 4, name))
    scores.sort(reverse=True)
    top = scores[:3]
    total = sum(w for w, _ in top)
    for w, name in top:
        if w / total > 0.02:
            groups[name].add([i], w / total, "REPLACE")
C.skin(skin, armature)

# ---------------------------------------------------------------- pièces rigides

parts = C.Obj("Details")
fur = C.material("poil_uni", "#161316", 0.6)
fur_in = C.material("poil_oreille", "#241c1c", 0.7)
nose_m = C.material("truffe", "#1b191b", 0.28)
hole = C.material("narine", "#050405", 0.9)
iris = C.material("iris", "#c07a24", 0.12)
iris_dark = C.material("iris_bord", "#5a3010", 0.2)
pupil = C.material("pupille", "#0a0605", 0.08)
shine = C.material("reflet", "#ffffff", 0.2, emit="#ffffff", emit_power=0.8)
mouth_m = C.material("gueule", "#4a1c22", 0.7)
tongue = C.material("langue", "#d4676f", 0.45)
tooth = C.material("dent", "#efe9dc", 0.35)
collar = C.material("collier", "#cfa6b6", 0.75)
buckle = C.material("boucle", "#222024", 0.4)
copper = C.material("medaillon", "#c8745a", 0.3, 0.7)
ring_m = C.material("anneau", "#d99a62", 0.25, 0.8)
lip = C.material("levre", "#100d0f", 0.45)

for side, s in (("L", 1), ("R", -1)):
    # oreilles : un grand pan arrondi qui pend, avec des franges
    ear = "ear" + side
    w = {ear: 1.0}
    pts = [(0.070 * s, 0.742, 0.34), (0.100 * s, 0.745, 0.338), (0.124 * s, 0.728, 0.338), (0.138 * s, 0.700, 0.340),
           (0.144 * s, 0.668, 0.345), (0.146 * s, 0.634, 0.351), (0.142 * s, 0.602, 0.358), (0.134 * s, 0.578, 0.365),
           (0.126 * s, 0.564, 0.370)]
    ear_pts, ear_radii = C.curve(pts, [0.024, 0.038, 0.049, 0.056, 0.059, 0.056, 0.047, 0.034, 0.018])
    parts.tube(ear_pts, ear_radii, fur, seg=28, squash=(0.3, 1.08), weights=w, cap_rings=8)
    for k in range(9):
        t = k / 8
        base = Vector((0.138 * s, 0.70 - t * 0.12, 0.31 + t * 0.02))
        parts.tube([base, base + Vector((0.006 * s, -0.05, -0.012 + t * 0.012))], [0.011, 0.0015], fur, seg=6,
                   weights=w, cap_rings=2)
    parts.tube([(0.115 * s, 0.70, 0.352), (0.128 * s, 0.63, 0.364)], [0.022, 0.018], fur_in, seg=12,
               squash=(0.25, 1.0), weights=w)
    # yeux
    wh = {"head": 1.0}
    eye = Vector((0.046 * s, 0.708, 0.4545))
    parts.ball(eye, 0.0185, iris_dark, weights=wh)
    parts.ball(eye + Vector((0.0, -0.0008, 0.0048)), 0.0152, iris, weights=wh)
    parts.ball(eye + Vector((-0.001 * s, 0.0, 0.0165)), (0.0072, 0.0078, 0.0042), pupil, weights=wh)
    parts.ball(eye + Vector((0.0052, 0.0062, 0.0192)), 0.0032, shine, weights=wh, seg=10, rings=8)
    # paupière : une calotte qui descend quand l'os tourne
    lid = {"lid" + side: 1.0}
    r = 0.0222
    verts, faces = [], []
    seg, rings = 16, 7
    for i in range(rings + 1):
        lat = math.radians(38 + (90 - 38) * i / rings)
        for k in range(seg):
            lon = 2 * math.pi * k / seg
            verts.append(tuple(eye + Vector((math.cos(lat) * math.cos(lon) * r, math.sin(lat) * r,
                                             math.cos(lat) * math.sin(lon) * r))))
    for i in range(rings):
        for k in range(seg):
            a, b = i * seg + k, i * seg + (k + 1) % seg
            faces.append([a, a + seg, b + seg, b])
    parts.add(verts, faces, fur, smooth=True, weights=lid)
    # sourcil : petite bosse qui porte les expressions
    parts.tube([(0.028 * s, 0.7335, 0.462), (0.048 * s, 0.7385, 0.462), (0.068 * s, 0.7325, 0.449)], [0.002, 0.0048, 0.002],
               fur, seg=10, weights={"brow" + side: 1.0})

wh = {"head": 1.0}
parts.ball((0, 0.664, 0.561), (0.032, 0.024, 0.024), nose_m, weights=wh)
parts.ball((0, 0.649, 0.556), (0.017, 0.016, 0.018), nose_m, weights=wh)
for s in (1, -1):
    parts.ball((0.0155 * s, 0.661, 0.5825), (0.0085, 0.0065, 0.0035), hole, weights=wh, seg=10, rings=8,
               matrix=Matrix.Rotation(0.5 * s, 3, "Z"))
parts.tube([(0, 0.642, 0.566), (0, 0.627, 0.562)], 0.0022, lip, seg=6, weights=wh)
parts.tube([(-0.040, 0.624, 0.505), (-0.021, 0.619, 0.546), (0, 0.624, 0.558), (0.021, 0.619, 0.546), (0.040, 0.624, 0.505)],
           0.0032, lip, seg=8, weights=wh)
# mâchoire et langue : elles bougent avec l'os « jaw »
wj = {"jaw": 1.0}
parts.tube([(0, 0.612, 0.43), (0, 0.607, 0.50), (0, 0.608, 0.538)], [0.04, 0.033, 0.023], fur, seg=16, squash=(1.1, 0.55),
           weights=wj)
parts.ball((0, 0.6215, 0.50), (0.027, 0.006, 0.045), mouth_m, weights=wj)
parts.tube([(0, 0.623, 0.45), (0, 0.6245, 0.505), (0, 0.620, 0.538)], [0.016, 0.019, 0.012], tongue, seg=12,
           squash=(1.0, 0.3), weights=wj)
for s in (1, -1):
    parts.tube([(0.019 * s, 0.621, 0.53), (0.019 * s, 0.630, 0.532)], [0.004, 0.001], tooth, seg=6, weights=wj, cap_rings=2)
# collier rose et son médaillon en cœur
wn = {"neck": 0.8, "chest": 0.2}
axis = Vector((0, 0.80, 0.60)).normalized()
center = Vector((0, 0.515, 0.232))
parts.torus(center, 0.092, 0.0105, collar, axis=axis, seg=40, sides=10, weights=wn)
across = Vector((1, 0, 0))
down = -axis.cross(across)
angle = math.radians(48)
clip = center + (across * math.cos(angle) + down * math.sin(angle)) * 0.096
parts.ball(clip, (0.017, 0.013, 0.014), buckle, weights=wn)
parts.torus((0, 0.435, 0.318), 0.012, 0.0028, ring_m, axis=(0.2, 0, 1), weights={"chest": 0.6, "neck": 0.4})
wc = {"chest": 0.6, "neck": 0.4}
for s in (1, -1):
    parts.ball((0.0085 * s, 0.4085, 0.33), (0.0125, 0.0125, 0.004), copper, weights=wc)
parts.tube([(0, 0.4055, 0.33), (0, 0.388, 0.33)], [0.019, 0.002], copper, seg=12, squash=(1.0, 0.22), weights=wc,
           cap_rings=2)
details = parts.build()
C.skin(details, armature)

C.export("blanche")
C.render("blanche_face", (0.45, 0.72, 1.35), (0.0, 0.43, 0.05), 38, (1200, 1200))
C.render("blanche_profil", (1.75, 0.55, 0.0), (0.0, 0.38, -0.02), 34, (1600, 1000))
C.render("blanche_jeu", (-0.7, 2.2, 2.2), (0.0, 0.3, 0.0), 24, (1000, 800))
