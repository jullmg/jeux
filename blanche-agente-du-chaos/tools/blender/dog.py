"""Blanche, chiot de cinq mois : noire, grosse tête ronde, grands yeux ambrés, oreilles tombantes, grosses pattes,
tache blanche au poitrail, bout des pattes blanc, collier rose.

Une seule peau lissée, un squelette, et des pièces rigides (yeux, truffe, langue, collier). Elle regarde vers +z.
Tout est dessiné à l'échelle 1, puis agrandi ou rapetissé d'un coup par TAILLE.
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

# La taille de Blanche : tout (peau, détails, squelette) est mis à cette échelle à la fin.
# DogView.SIZE (characters/dog_view.gd) doit avoir la même valeur.
TAILLE = 1.12

C.reset()
rng = random.Random(8)


# ---------------------------------------------------------------- squelette

BONES = [
    ("root", None, (0, 0, 0), (0, 0.06, 0)),
    ("hips", "root", (0, 0.225, -0.13), (0, 0.23, -0.045)),
    ("spine", "hips", (0, 0.23, -0.045), (0, 0.235, 0.04)),
    ("chest", "spine", (0, 0.235, 0.04), (0, 0.255, 0.115)),
    ("neck", "chest", (0, 0.28, 0.115), (0, 0.355, 0.165)),
    ("head", "neck", (0, 0.355, 0.165), (0, 0.40, 0.235)),
    ("jaw", "head", (0, 0.368, 0.245), (0, 0.355, 0.325)),
    ("tail1", "hips", (0, 0.262, -0.19), (0, 0.31, -0.262)),
    ("tail2", "tail1", (0, 0.31, -0.262), (0, 0.357, -0.308)),
    ("tail3", "tail2", (0, 0.357, -0.308), (0, 0.405, -0.322)),
]
EYE = Vector((0.054, 0.446, 0.2745))
for side, s in (("L", 1), ("R", -1)):
    eye = (EYE.x * s, EYE.y, EYE.z)
    BONES += [
        ("ear" + side, "head", (0.092 * s, 0.505, 0.188), (0.155 * s, 0.375, 0.205)),
        ("lid" + side, "head", eye, (eye[0], eye[1], eye[2] + 0.03)),
        ("brow" + side, "head", (eye[0], eye[1] + 0.048, eye[2]), (eye[0], eye[1] + 0.048, eye[2] + 0.03)),
        ("shoulder" + side, "chest", (0.064 * s, 0.218, 0.092), (0.070 * s, 0.122, 0.090)),
        ("elbow" + side, "shoulder" + side, (0.070 * s, 0.122, 0.090), (0.073 * s, 0.047, 0.104)),
        ("paw" + side, "elbow" + side, (0.073 * s, 0.047, 0.104), (0.074 * s, 0.020, 0.155)),
        ("thigh" + side, "hips", (0.065 * s, 0.208, -0.135), (0.076 * s, 0.130, -0.092)),
        ("knee" + side, "thigh" + side, (0.076 * s, 0.130, -0.092), (0.076 * s, 0.066, -0.164)),
        ("hock" + side, "knee" + side, (0.076 * s, 0.066, -0.164), (0.076 * s, 0.033, -0.152)),
        ("hpaw" + side, "hock" + side, (0.076 * s, 0.033, -0.152), (0.076 * s, 0.018, -0.100)),
    ]
armature = C.make_armature("Squelette", BONES)

# ---------------------------------------------------------------- la peau

coat = C.material("poil", "#ffffff", 0.62, vertex_colors=True)
body = C.Obj("Peau")
# un corps dodu de bébé : ventre rond, petit poitrail bombé
body.ball((0, 0.228, -0.03), (0.100, 0.095, 0.140), coat, seg=24, rings=18)
body.ball((0, 0.235, 0.052), (0.100, 0.105, 0.092), coat, seg=24, rings=18)
body.ball((0, 0.230, -0.115), (0.099, 0.097, 0.090), coat, seg=24, rings=18)
body.tube([(0, 0.250, 0.075), (0, 0.312, 0.133), (0, 0.370, 0.172)], [0.082, 0.068, 0.066], coat, seg=20)
# la tête : grosse, ronde, le front bombé, les joues pleines et un museau tout court
body.ball((0, 0.432, 0.193), (0.126, 0.116, 0.112), coat, seg=28, rings=20)
body.ball((0, 0.466, 0.213), (0.098, 0.078, 0.084), coat, seg=24, rings=16)
body.ball((0, 0.392, 0.278), (0.058, 0.045, 0.056), coat, seg=20, rings=14)
for s in (1, -1):
    body.ball((0.062 * s, 0.393, 0.228), (0.060, 0.052, 0.055), coat)
    body.ball((0.027 * s, 0.380, 0.304), (0.038, 0.032, 0.036), coat)
    # pattes avant, courtes et potelées, au bout de grosses « mitaines »
    body.tube([(0.056 * s, 0.235, 0.085), (0.068 * s, 0.172, 0.088), (0.070 * s, 0.120, 0.090), (0.073 * s, 0.050, 0.104)],
              [0.055, 0.044, 0.036, 0.034], coat, seg=16)
    body.ball((0.074 * s, 0.028, 0.122), (0.043, 0.031, 0.052), coat)
    for t in (-1, 0, 1):
        body.ball((0.074 * s + t * 0.025, 0.019, 0.164 - abs(t) * 0.009), (0.0155, 0.018, 0.021), coat, seg=10, rings=8)
    # pattes arrière
    body.ball((0.060 * s, 0.200, -0.125), (0.052, 0.072, 0.072), coat)
    body.tube([(0.065 * s, 0.200, -0.122), (0.076 * s, 0.130, -0.094), (0.076 * s, 0.072, -0.162), (0.076 * s, 0.036, -0.150)],
              [0.058, 0.040, 0.030, 0.030], coat, seg=16)
    body.ball((0.076 * s, 0.027, -0.122), (0.040, 0.029, 0.051), coat)
    for t in (-1, 0, 1):
        body.ball((0.076 * s + t * 0.023, 0.018, -0.083 - abs(t) * 0.008), (0.0145, 0.017, 0.020), coat, seg=10, rings=8)
# petite queue en panache, relevée
body.tube([(0, 0.255, -0.180), (0, 0.310, -0.262), (0, 0.357, -0.308), (0, 0.405, -0.322)], [0.042, 0.037, 0.029, 0.012],
          coat, seg=14, squash=(0.85, 1.1))
# duvet de chiot : poitrail, culotte, dessous de la queue
for _ in range(30):
    p = Vector((rng.uniform(-0.052, 0.052), rng.uniform(0.215, 0.295), rng.uniform(0.130, 0.150)))
    body.tube([p, p + Vector((p.x * 0.25, -0.032, 0.008))], [0.020, 0.004], coat, seg=8, cap_rings=2)
for i in range(10):
    t = i / 9
    p = Vector((rng.uniform(-0.008, 0.008), 0.262 + t * 0.12, -0.205 - t * 0.108))
    body.tube([p, p + Vector((0, -0.030 + t * 0.012, -0.032))], [0.016, 0.003], coat, seg=8, cap_rings=2)
for s in (1, -1):
    for i in range(5):
        p = Vector((0.052 * s, 0.215 - i * 0.018, -0.176 + i * 0.008))
        body.tube([p, p + Vector((0.006 * s, -0.030, -0.018))], [0.016, 0.003], coat, seg=8, cap_rings=2)

skin = body.build()
bpy.context.view_layer.objects.active = skin
skin.select_set(True)
remesh = skin.modifiers.new("remaillage", "REMESH")
remesh.mode = "VOXEL"
remesh.voxel_size = 0.0056
bpy.ops.object.modifier_apply(modifier=remesh.name)
smooth = skin.modifiers.new("lissage", "SMOOTH")
smooth.factor = 0.7
smooth.iterations = 6
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
black = Vector(C.lin(C.srgb("#1a161a")))
brown = Vector(C.lin(C.srgb("#2c2224")))
soft = Vector(C.lin(C.srgb("#383032")))
white = Vector(C.lin(C.srgb("#f1ece3")))
grey = Vector(C.lin(C.srgb("#7a7270")))


def smoothstep(a, b, x):
    t = max(0.0, min(1.0, (x - a) / (b - a)))
    return t * t * (3 - 2 * t)


for i, v in enumerate(mesh.vertices):
    p = to_godot(v.co)
    n = noise.noise(p * 48.0)
    c = black.lerp(brown, max(0.0, noise.noise(p * 9.0)) * 0.8) * (1.0 + 0.2 * noise.noise(p * 110.0))
    # le museau et le bedon un peu plus doux, pour que le visage se lise
    d = math.sqrt((p.x / 0.075) ** 2 + ((p.y - 0.378) / 0.05) ** 2 + ((p.z - 0.32) / 0.07) ** 2)
    c = c.lerp(soft, 0.75 * (1.0 - smoothstep(0.35, 1.0, d)))
    # tache blanche au poitrail
    d = math.sqrt(((p.x + 0.005) / 0.029) ** 2 + ((p.y - 0.222) / 0.042) ** 2) + n * 0.28
    if p.z > 0.115 and d < 1.15:
        c = c.lerp(white, 1.0 - smoothstep(0.76, 1.12, d))
    # bout des pattes
    if p.y < 0.044:
        front = p.z > 0.0
        edge = (p.z - (0.138 if front else -0.106)) / 0.016 + n * 0.7
        if edge > 0:
            c = c.lerp(white, smoothstep(0.0, 0.9, edge) * (1.0 - smoothstep(0.030, 0.044, p.y)))
    # un soupçon de poil clair au menton
    d = math.sqrt((p.x / 0.024) ** 2 + ((p.y - 0.342) / 0.014) ** 2 + ((p.z - 0.305) / 0.034) ** 2) + n * 0.3
    if d < 1.0:
        c = c.lerp(grey, 0.5 * (1.0 - d))
    colors.data[i].color = (c.x, c.y, c.z, 1.0)

# poids du squelette : distance à chaque os (capsules), sans mélanger la gauche et la droite
RADII = {"hips": 0.092, "spine": 0.092, "chest": 0.10, "neck": 0.064, "head": 0.11, "tail1": 0.036, "tail2": 0.030,
         "tail3": 0.024, "shoulder": 0.036, "elbow": 0.031, "paw": 0.034, "thigh": 0.048, "knee": 0.031,
         "hock": 0.028, "hpaw": 0.032}
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
            if p.x * s < 0.009 or p.y > 0.255:
                continue
        if base == "head" and (p.z < 0.10 or p.y < 0.315):
            continue
        if base.startswith("tail") and p.z > -0.19:
            continue
        d = max(0.0, C.segment_distance(p, a, b) - r * 0.82)
        scores.append((1.0 / (d + 0.008) ** 4, name))
    scores.sort(reverse=True)
    top = scores[:3]
    total = sum(w for w, _ in top)
    for w, name in top:
        if w / total > 0.02:
            groups[name].add([i], w / total, "REPLACE")
C.skin(skin, armature)

# ---------------------------------------------------------------- pièces rigides

parts = C.Obj("Details")
fur = C.material("poil_uni", "#1b171a", 0.65)
lid_m = C.material("poil_paupiere", "#241e21", 0.65)
brow_m = C.material("poil_sourcil", "#292224", 0.7)
nose_m = C.material("truffe", "#2a2427", 0.22)
hole = C.material("narine", "#060405", 0.9)
sclera = C.material("oeil", "#140d0b", 0.08)
iris_rim = C.material("iris_bord", "#5c2f0e", 0.12)
iris = C.material("iris", "#c97a22", 0.08, emit="#4a2606", emit_power=0.6)
iris_low = C.material("iris_clair", "#f0ad45", 0.08, emit="#8a4a0c", emit_power=0.7)
pupil = C.material("pupille", "#0b0605", 0.05)
shine = C.material("reflet", "#ffffff", 0.2, emit="#ffffff", emit_power=1.0)
mouth_m = C.material("gueule", "#5a232b", 0.7)
tongue = C.material("langue", "#f07f8e", 0.4, emit="#3a0f14", emit_power=0.5)
tooth = C.material("dent", "#f4efe4", 0.35)
lip = C.material("levre", "#5a484a", 0.5)
whisker = C.material("moustache", "#6a5d5e", 0.6)
collar = C.material("collier", "#e7a9c1", 0.7)
buckle = C.material("boucle", "#222024", 0.4)
copper = C.material("medaillon", "#d98468", 0.28, 0.7)
ring_m = C.material("anneau", "#e0a56a", 0.25, 0.8)


def ribbon(points, widths, thick, across, mat, weights, seg=24):
    """Un pan plat et arrondi (une oreille) : `across` donne le sens de sa largeur."""
    pts, wid = C.curve(points, widths, 5)
    _, thk = C.curve(points, thick, 5)
    rings = []
    for i, p in enumerate(pts):
        d = (pts[min(i + 1, len(pts) - 1)] - pts[max(i - 1, 0)]).normalized()
        rings.append((p, d, wid[i], thk[i]))
    # bouts arrondis
    for end, sign in ((0, -1), (-1, 1)):
        c, d, w, t = rings[end]
        extra = [(c + d * sign * w * 0.55 * math.sin(a), d, w * math.cos(a), t * math.cos(a))
                 for a in (math.pi / 2 * k / 5 for k in range(1, 6))]
        rings = list(reversed(extra)) + rings if sign < 0 else rings + extra
    verts, faces = [], []
    for c, d, w, t in rings:
        u = (across - d * d.dot(across)).normalized()
        v = d.cross(u).normalized()
        for k in range(seg):
            a = 2 * math.pi * k / seg
            verts.append(tuple(c + u * math.cos(a) * max(w, 1e-4) + v * math.sin(a) * max(t, 1e-4)))
    for i in range(len(rings) - 1):
        for k in range(seg):
            a, b = i * seg + k, i * seg + (k + 1) % seg
            faces.append([a, b, b + seg, a + seg])
    faces.append(list(range(seg))[::-1])
    faces.append([(len(rings) - 1) * seg + k for k in range(seg)])
    parts.add(verts, faces, mat, smooth=True, weights=weights)


wh = {"head": 1.0}
# de combien les paupières ouvertes sont rejetées en arrière (voir DogView : les fermer demande 90 + LID_REST degrés)
LID_REST = 54
for side, s in (("L", 1), ("R", -1)):
    # oreilles : de grands pans mous qui retombent de chaque côté, un peu tournés vers l'avant
    ear = {"ear" + side: 1.0}
    ribbon([(0.070 * s, 0.510, 0.186), (0.106 * s, 0.512, 0.190), (0.130 * s, 0.482, 0.198), (0.141 * s, 0.440, 0.208),
            (0.145 * s, 0.400, 0.216), (0.142 * s, 0.368, 0.222), (0.134 * s, 0.348, 0.226)],
           [0.019, 0.033, 0.042, 0.047, 0.046, 0.037, 0.020], [0.012, 0.016, 0.017, 0.016, 0.014, 0.012, 0.009],
           Vector((0.55 * s, 0.0, 0.83)), fur, ear)
    # grands yeux : globe sombre, iris ambré cerclé, grosse pupille et deux reflets
    c = Vector((EYE.x * s, EYE.y, EYE.z))
    # tournés un peu vers l'extérieur pour épouser la rondeur de la tête
    turn = Matrix.Rotation(0.2 * s, 3, "Y")

    def disc(dx, dy, dz, radii, mat, **kw):
        parts.ball(c + turn @ Vector((dx, dy, dz)), radii, mat, weights=wh, matrix=turn, **kw)

    disc(0, 0, 0, (0.0298, 0.0298, 0.0298), sclera, seg=24, rings=18)
    disc(0, 0, 0.0218, (0.0262, 0.0272, 0.0102), iris_rim, seg=24)
    disc(0, 0, 0.0227, (0.0242, 0.0252, 0.0111), iris, seg=24)
    disc(0, -0.0154, 0.0274, (0.0146, 0.0068, 0.0060), iris_low, seg=20)
    disc(0, 0.0012, 0.0293, (0.0162, 0.0172, 0.0078), pupil, seg=24)
    disc(0.0092, 0.0102, 0.0331, (0.0074, 0.0077, 0.0036), shine, seg=14, rings=10)
    disc(-0.0087, -0.0082, 0.0346, (0.0031, 0.0031, 0.0021), shine, seg=10, rings=8)
    # paupière : une calotte rejetée en arrière, qui descend quand l'os tourne
    lid = {"lid" + side: 1.0}
    r = 0.0397
    pole = turn @ Vector((0, math.cos(math.radians(LID_REST)), -math.sin(math.radians(LID_REST))))
    u = turn @ Vector((1, 0, 0))
    v = pole.cross(u)
    verts, faces = [], []
    seg, rings = 20, 8
    for i in range(rings + 1):
        lat = math.radians(32 + (90 - 32) * i / rings)
        for k in range(seg):
            lon = 2 * math.pi * k / seg
            verts.append(tuple(c + (u * math.cos(lon) + v * math.sin(lon)) * math.cos(lat) * r + pole * math.sin(lat) * r))
    for i in range(rings):
        for k in range(seg):
            a, b = i * seg + k, i * seg + (k + 1) % seg
            faces.append([a, b, b + seg, a + seg])
    parts.add(verts, faces, lid_m, smooth=True, weights=lid)
    # sourcils : deux petites bosses de poil, à peine visibles, qui portent les expressions
    arc, thick = C.curve([(0.036 * s, 0.4978, 0.2732), (0.045 * s, 0.5014, 0.2742), (0.055 * s, 0.5026, 0.2740),
                          (0.065 * s, 0.5010, 0.2708), (0.073 * s, 0.4975, 0.2640)], [0.0008, 0.0023, 0.0027, 0.0022, 0.0008])
    parts.tube(arc, thick, brow_m, seg=10, weights={"brow" + side: 1.0})
    # points de moustaches
    for dx, dy in ((0.024, 0.000), (0.037, 0.004), (0.031, -0.010)):
        parts.ball((dx * s, 0.381 + dy, 0.3385 - max(0.0, dx - 0.024) * 0.55), 0.0023, whisker, weights=wh, seg=8, rings=6)

# truffe : un gros bouton luisant
parts.ball((0, 0.4035, 0.3375), (0.0265, 0.0185, 0.0175), nose_m, weights=wh, seg=24)
parts.ball((0, 0.3925, 0.3400), (0.0150, 0.0120, 0.0130), nose_m, weights=wh)
for s in (1, -1):
    parts.ball((0.0118 * s, 0.4005, 0.3535), (0.0062, 0.0046, 0.0028), hole, weights=wh, seg=10, rings=8,
               matrix=Matrix.Rotation(0.5 * s, 3, "Z"))
# la bouche en « ω » qui sourit
parts.tube([(0, 0.386, 0.3465), (0, 0.3725, 0.3475)], 0.0019, lip, seg=6, weights=wh)
for s in (1, -1):
    parts.tube([(0, 0.3725, 0.3475), (0.011 * s, 0.3665, 0.3455), (0.022 * s, 0.3685, 0.3405), (0.030 * s, 0.3745, 0.3330)],
               [0.0021, 0.0023, 0.0020, 0.0010], lip, seg=8, weights=wh)
# mâchoire, et le petit bout de langue qui dépasse : tout bouge avec l'os « jaw »
wj = {"jaw": 1.0}
parts.tube([(0, 0.362, 0.245), (0, 0.352, 0.292), (0, 0.352, 0.314)], [0.032, 0.027, 0.019], fur, seg=18, squash=(1.18, 0.55),
           weights=wj)
parts.ball((0, 0.3635, 0.292), (0.022, 0.0048, 0.034), mouth_m, weights=wj)
parts.tube([(0, 0.3640, 0.268), (0, 0.3635, 0.318), (0, 0.3560, 0.3360), (0, 0.3465, 0.3385)], [0.010, 0.0135, 0.0128, 0.0085],
           tongue, seg=16, squash=(1.15, 0.40), weights=wj)
for s in (1, -1):
    parts.tube([(0.016 * s, 0.363, 0.312), (0.016 * s, 0.3705, 0.314)], [0.0032, 0.0008], tooth, seg=6, weights=wj,
               cap_rings=2)
# collier rose et son médaillon en cœur
wn = {"neck": 0.75, "chest": 0.25}
axis = Vector((0, 0.74, 0.67)).normalized()
center = Vector((0, 0.304, 0.130))
across = Vector((1, 0, 0))
down = -axis.cross(across)
BIG = 0.0755
parts.torus(center, BIG, 0.0095, collar, axis=axis, seg=48, sides=10, weights=wn)
angle = math.radians(46)
clip = center + (across * math.cos(angle) + down * math.sin(angle)) * (BIG + 0.003)
parts.ball(clip, (0.015, 0.012, 0.013), buckle, weights=wn)
wc = {"chest": 0.6, "neck": 0.4}
front = center + down * (BIG + 0.004)
parts.torus(front + Vector((0, -0.012, 0.010)), 0.0105, 0.0026, ring_m, axis=(0.15, 0, 1), weights=wc)
heart = front + Vector((0, -0.036, 0.016))
for s in (1, -1):
    parts.ball(heart + Vector((0.0082 * s, 0.0030, 0)), (0.0118, 0.0118, 0.0042), copper, weights=wc)
parts.tube([heart, heart + Vector((0, -0.0175, 0))], [0.0178, 0.0018], copper, seg=14, squash=(1.0, 0.24), weights=wc,
           cap_rings=2)
details = parts.build()
C.skin(details, armature)

# mise à la taille voulue : le squelette et les deux peaux ensemble
for data in (armature.data, skin.data, details.data):
    data.transform(Matrix.Scale(TAILLE, 4))
bpy.context.view_layer.update()

C.export("blanche")
K = TAILLE
C.render("blanche_face", (0.36 * K, 0.52 * K, 0.98 * K), (0.0, 0.29 * K, 0.04), 36, (1200, 1200))
C.render("blanche_museau", (0.07, 0.50 * K, 0.86 * K), (0.0, 0.40 * K, 0.20 * K), 28, (1200, 1200))
C.render("blanche_profil", (1.35, 0.38, 0.0), (0.0, 0.28, 0.0), 32, (1600, 1000))
C.render("blanche_jeu", (-0.7, 2.2, 2.2), (0.0, 0.22, 0.0), 17, (1000, 800))
