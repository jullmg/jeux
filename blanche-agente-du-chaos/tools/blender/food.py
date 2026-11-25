"""Tous les morceaux à chiper, un objet par nom, posés à l'origine. Tailles exagérées pour être lisibles de haut.

Blender --background --python tools/blender/food.py
"""
import json
import math
import pathlib
import random
import sys

sys.path.insert(0, str(pathlib.Path(__file__).parent))
import common as C  # noqa: E402
import bpy  # noqa: E402
from mathutils import Matrix, Vector  # noqa: E402

C.reset()
rng = random.Random(12)
M = C.material


def m(name, color, rough=0.65, **kw):
    return M(name, color, rough, **kw)


plate = m("assiette", "#f2efe8", 0.35)
platter = m("plateau", "#c9ccd2", 0.3, metal=0.5)
wood = m("planche", "#b88350", 0.6)
dough = m("pate", "#ead3a6", 0.8)
golden = m("dore", "#d9963f", 0.55)
golden_d = m("dore_fonce", "#a9621f", 0.55)
crust = m("croute", "#c07b34", 0.7)
crumb_c = m("mie", "#f0d9a4", 0.85)
pink = m("jambon", "#e58f8d", 0.55)
pink_l = m("jambon_pale", "#f2b9b2", 0.6)
cheese = m("fromage", "#f6c33b", 0.45)
cheese_w = m("fromage_blanc", "#f5ecd2", 0.45)
meat = m("viande", "#7c3f24", 0.6)
meat_l = m("viande_rose", "#b9685a", 0.55)
sauce = m("sauce", "#c63523", 0.35)
carrot = m("carotte", "#ef7f1f", 0.55)
lettuce = m("laitue", "#7fbf4a", 0.7)
herb = m("herbe", "#4d8b3a", 0.7)
tomato = m("tomate", "#d8392c", 0.4)
pepperoni = m("pepperoni", "#b3301f", 0.45)
fat = m("gras", "#f0c3ae", 0.5)
butter = m("beurre", "#ffe37a", 0.35)
pasta = m("nouille", "#f1d27a", 0.5)
bone = m("os", "#f3ead6", 0.5)
syrup = m("sirop", "#9a4d12", 0.15)
dot = m("point_biscuit", "#8a5a2a", 0.7)
blue = m("etiquette", "#3a6fb5", 0.5)
skin_c = m("peau_doree", "#c9781f", 0.35)

made = []


def food(name):
    def wrap(fn):
        o = C.Obj(name)
        fn(o)
        made.append(o)
        return fn
    return wrap


def crumbs(o, mat, count=7, r=0.05, size=0.016):
    for i in range(count):
        a = rng.uniform(0, math.tau)
        d = rng.uniform(0.0, r)
        s = rng.uniform(0.55, 1.0) * size
        x, z = math.cos(a) * d, math.sin(a) * d
        rot = Matrix.Translation((x, s * 0.6, z)) @ Matrix.Rotation(rng.uniform(0, 3), 4, "Y") @ Matrix.Rotation(
            rng.uniform(-0.4, 0.4), 4, "X")
        o.box(-s, -s * 0.6, -s * 0.8, s, s * 0.6, s * 0.8, mat, bevel=s * 0.35, seg=1, matrix=rot)


def disc(o, y, r, h, mat, x=0.0, z=0.0, bevel=0.0):
    o.cyl((x, y, z), r, h, mat, seg=28, bevel=bevel)


def lumpy(o, center, radii, mat, lumps=14, r=0.35):
    c = Vector(center)
    o.ball(c, radii, mat)
    for _ in range(lumps):
        v = Vector((rng.gauss(0, 1), rng.gauss(0, 1), rng.gauss(0, 1))).normalized()
        p = c + Vector((v.x * radii[0], v.y * radii[1], v.z * radii[2])) * 0.8
        s = min(radii) * r * rng.uniform(0.7, 1.2)
        o.ball(p, s, mat, seg=10, rings=7)


def drumstick(o, base, direction, size, mat=skin_c):
    b = Vector(base)
    d = Vector(direction).normalized()
    path, radii = C.curve([b, b + d * size * 0.45, b + d * size * 0.9, b + d * size * 1.15],
                          [size * 0.30, size * 0.34, size * 0.14, size * 0.09], 4)
    o.tube(path, radii, mat, seg=18)
    o.tube([b + d * size * 1.15, b + d * size * 1.5], size * 0.07, bone, seg=10)
    side = d.cross(Vector((0, 1, 0))).normalized()
    for s in (-1, 1):
        o.ball(b + d * size * 1.52 + side * s * size * 0.07, size * 0.085, bone, seg=10, rings=7)


@food("miette")
def _(o):
    crumbs(o, crumb_c)


@food("bout_carotte")
def _(o):
    for i in range(4):
        x, z = rng.uniform(-0.035, 0.035), rng.uniform(-0.035, 0.035)
        o.cyl((x, 0, z), 0.018, 0.012, carrot, seg=12, bevel=0.003)


@food("bout_nouille")
def _(o):
    for i in range(3):
        a = i * 2.2
        pts = [(math.cos(a + k) * 0.03 * (k - 1), 0.008, math.sin(a + k * 0.7) * 0.028 + (i - 1) * 0.015) for k in range(4)]
        path, radii = C.curve(pts, [0.006] * 4, 5)
        o.tube(path, radii, pasta, seg=8)


@food("crepe")
def _(o):
    o.tube([(-0.075, 0.032, 0), (0.075, 0.032, 0)], 0.032, golden, seg=20, cap_rings=2)
    for s in (-1, 1):
        o.torus((0.103 * s, 0.032, 0), 0.015, 0.005, dough, axis=(1, 0, 0), sides=6)
    for x in (-0.04, 0.01, 0.05):
        o.ball((x, 0.063, 0.004), (0.018, 0.003, 0.012), golden_d)


@food("pile_crepes")
def _(o):
    disc(o, 0.0, 0.14, 0.012, plate)
    for i in range(7):
        disc(o, 0.012 + i * 0.017, 0.108 - rng.uniform(0, 0.008), 0.016, golden if i % 2 else dough,
             rng.uniform(-0.007, 0.007), rng.uniform(-0.007, 0.007), 0.006)
    disc(o, 0.131, 0.075, 0.007, syrup, bevel=0.003)
    for a in (0.4, 2.5, 4.4):
        o.tube([(math.cos(a) * 0.06, 0.134, math.sin(a) * 0.06), (math.cos(a) * 0.108, 0.09, math.sin(a) * 0.108)],
               [0.014, 0.008], syrup, seg=10)
    o.box(-0.022, 0.138, -0.02, 0.022, 0.156, 0.02, butter, bevel=0.006)


@food("saucisse")
def _(o):
    disc(o, 0.0, 0.15, 0.012, plate)
    path, radii = C.curve([(-0.12, 0.05, 0.035), (-0.045, 0.052, -0.012), (0.045, 0.052, -0.012), (0.12, 0.05, 0.035)],
                          [0.042] * 4, 8)
    o.tube(path, radii, meat, seg=20)
    for x in (-0.06, 0.0, 0.06):
        o.tube([(x - 0.015, 0.093, -0.02), (x + 0.015, 0.093, 0.012)], 0.005, golden_d, seg=8)


@food("fromage")
def _(o):
    o.box(-0.06, 0.0, -0.06, 0.06, 0.018, 0.06, cheese, bevel=0.004, seg=1)
    for x, z, r in ((-0.02, 0.01, 0.014), (0.028, -0.025, 0.01), (0.02, 0.03, 0.008)):
        disc(o, 0.0181, r, 0.001, golden, x, z)


@food("sandwich")
def _(o):
    def tri(y, h, s, mat):
        v = [(-s, y, -s * 0.8), (s, y, -s * 0.8), (0, y, s), (-s, y + h, -s * 0.8), (s, y + h, -s * 0.8), (0, y + h, s)]
        faces = [[0, 1, 2], [3, 5, 4], [0, 3, 4, 1], [1, 4, 5, 2], [2, 5, 3, 0]]
        verts, out = [], []
        for f in faces:
            out.append(list(range(len(verts), len(verts) + len(f))))
            verts.extend(v[i] for i in f)
        o.add(verts, out, mat)

    y = 0.0
    for h, s, mat in ((0.026, 0.11, crumb_c), (0.008, 0.118, lettuce), (0.011, 0.108, tomato), (0.012, 0.112, pink),
                      (0.026, 0.11, crumb_c), (0.009, 0.115, cheese), (0.012, 0.108, meat_l), (0.026, 0.11, crumb_c)):
        tri(y, h, s, mat)
        y += h
    tri(y, 0.004, 0.112, crust)
    o.tube([(0, y, 0.0), (0, y + 0.06, 0.0)], 0.003, wood, seg=6)
    o.ball((0, y + 0.066, 0), 0.015, herb)


@food("paquet_jambon")
def _(o):
    o.box(-0.13, 0.0, -0.09, 0.13, 0.02, 0.09, plate, bevel=0.008)
    for i in range(4):
        x = -0.07 + i * 0.047
        o.ball((x, 0.03 + i * 0.006, 0.0), (0.062, 0.012, 0.072), pink if i % 2 else pink_l)
    o.box(-0.13, 0.02, 0.045, -0.01, 0.07, 0.092, blue, bevel=0.008)
    o.box(-0.115, 0.07, 0.055, -0.025, 0.072, 0.082, plate)


@food("pain")
def _(o):
    o.ball((0, 0.038, 0), (0.072, 0.045, 0.052), crust)
    o.ball((0.032, 0.04, 0), (0.048, 0.036, 0.046), crumb_c)


@food("poulet_morceau")
def _(o):
    lumpy(o, (0, 0.05, 0), (0.095, 0.045, 0.065), golden, 18)
    for x in (-0.04, 0.03):
        o.ball((x, 0.095, 0.0), (0.02, 0.006, 0.014), golden_d)


def bird(o, scale, bow=False):
    s = scale
    disc(o, 0.0, 0.17 * s, 0.014, platter)
    o.ball((0, 0.085 * s, -0.01 * s), (0.12 * s, 0.085 * s, 0.105 * s), skin_c, seg=28, rings=18)
    o.ball((0, 0.12 * s, -0.025 * s), (0.09 * s, 0.055 * s, 0.08 * s), golden)
    for d in (-1, 1):
        drumstick(o, (0.07 * s * d, 0.065 * s, 0.045 * s), (0.45 * d, 0.5, 0.75), 0.1 * s)
        path, radii = C.curve([(0.095 * s * d, 0.09 * s, -0.04 * s), (0.13 * s * d, 0.06 * s, 0.0),
                               (0.1 * s * d, 0.04 * s, 0.04 * s)], [0.03 * s, 0.025 * s, 0.012 * s], 5)
        o.tube(path, radii, golden_d, seg=14)
    for i in range(12):
        a = i * math.tau / 12
        o.ball((math.cos(a) * 0.15 * s, 0.022, math.sin(a) * 0.15 * s), (0.016 * s, 0.01 * s, 0.016 * s),
               herb if i % 3 else tomato, seg=10, rings=7)


@food("poulet_roti")
def _(o):
    bird(o, 1.0)


@food("dinde")
def _(o):
    bird(o, 1.35)


def cookie(o, x, y, z, r):
    o.cyl((x, y, z), r, 0.018, golden, seg=22, top=r * 0.88, bevel=0.006)
    for i in range(6):
        a = i * 2.4
        d = r * 0.65 * ((i % 3 + 1) / 3)
        o.ball((x + math.cos(a) * d, y + 0.018, z + math.sin(a) * d), (0.008, 0.004, 0.008), dot, seg=8, rings=6)


@food("biscuit")
def _(o):
    cookie(o, 0, 0, 0, 0.06)


@food("pate")
def _(o):
    lumpy(o, (0, 0.06, 0), (0.085, 0.062, 0.085), dough, 9, 0.4)


@food("plaque_biscuits")
def _(o):
    o.box(-0.17, 0.0, -0.12, 0.17, 0.014, 0.12, platter, bevel=0.005, seg=1)
    for a, b, c, d in ((-0.17, 0.17, -0.12, -0.11), (-0.17, 0.17, 0.11, 0.12), (-0.17, -0.16, -0.12, 0.12),
                       (0.16, 0.17, -0.12, 0.12)):
        o.box(a, 0.01, c, b, 0.032, d, platter)
    for i in range(3):
        for j in range(2):
            cookie(o, -0.105 + i * 0.105, 0.014 + rng.uniform(0, 0.003), -0.055 + j * 0.11, 0.046)


@food("pepperoni")
def _(o):
    for i, (x, z) in enumerate(((-0.025, 0.0), (0.03, 0.012))):
        disc(o, i * 0.011, 0.052, 0.011, pepperoni, x, z, 0.003)
        for k in range(6):
            a = k * 2.1 + i
            disc(o, i * 0.011 + 0.0111, 0.006, 0.001, fat, x + math.cos(a) * 0.03, z + math.sin(a) * 0.027)


def wedge(o, a0, a1, r, y, h, mat, steps=10):
    pts = [(0.0, 0.0)] + [(math.cos(a0 + (a1 - a0) * i / steps) * r, math.sin(a0 + (a1 - a0) * i / steps) * r)
                          for i in range(steps + 1)]
    n = len(pts)
    off = (-math.cos((a0 + a1) / 2) * r * 0.5, -math.sin((a0 + a1) / 2) * r * 0.5) if a1 - a0 < 3 else (0, 0)
    low = [(p[0] + off[0], y, p[1] + off[1]) for p in pts]
    high = [(p[0] + off[0], y + h, p[1] + off[1]) for p in pts]
    o.add(high, [list(range(n))[::-1]], mat)
    o.add(low, [list(range(n))], mat)
    for i in range(n):
        j = (i + 1) % n
        o.quad(low[i], high[i], high[j], low[j], mat)
    return off


@food("pointe_pizza")
def _(o):
    a0, a1 = 1.15, 2.0
    off = wedge(o, a0, a1, 0.19, 0.0, 0.018, dough)
    wedge_off = off
    wedge(o, a0 + 0.04, a1 - 0.04, 0.165, 0.018, 0.008, cheese)
    for r, a in ((0.07, 1.55), (0.125, 1.35), (0.13, 1.78)):
        disc(o, 0.026, 0.022, 0.006, pepperoni, math.cos(a) * r + wedge_off[0], math.sin(a) * r + wedge_off[1])
    pts = [(math.cos(a) * 0.178 + wedge_off[0], 0.026, math.sin(a) * 0.178 + wedge_off[1])
           for a in [a0 + (a1 - a0) * i / 8 for i in range(9)]]
    o.tube(pts, 0.018, crust, seg=12)


@food("pizza")
def _(o):
    disc(o, 0.0, 0.2, 0.012, wood)
    disc(o, 0.012, 0.175, 0.016, dough, bevel=0.005)
    disc(o, 0.028, 0.155, 0.005, sauce)
    disc(o, 0.033, 0.145, 0.006, cheese, bevel=0.002)
    o.torus((0, 0.033, 0), 0.168, 0.019, crust, sides=10)
    for i in range(11):
        a = i * 2.4
        r = 0.115 * math.sqrt((i + 0.5) / 11)
        disc(o, 0.039, 0.025, 0.005, pepperoni, math.cos(a) * r, math.sin(a) * r)
    for i in range(7):
        a = i * 1.7 + 1
        o.ball((math.cos(a) * 0.08, 0.045, math.sin(a) * 0.08), (0.012, 0.003, 0.007), herb, seg=8, rings=5)


@food("boulette")
def _(o):
    lumpy(o, (0, 0.045, 0), (0.048, 0.044, 0.048), meat, 14, 0.38)
    o.ball((0, 0.082, 0), (0.034, 0.018, 0.034), sauce)


@food("pain_beurre")
def _(o):
    o.box(-0.085, 0.0, -0.07, 0.085, 0.032, 0.06, crust, bevel=0.016)
    o.box(-0.07, 0.022, -0.058, 0.07, 0.038, 0.048, crumb_c, bevel=0.008)
    o.box(-0.035, 0.037, -0.028, 0.03, 0.05, 0.02, butter, bevel=0.008)


@food("grosse_boulette")
def _(o):
    disc(o, 0.0, 0.17, 0.014, plate)
    for i in range(26):
        pts = []
        a = rng.uniform(0, math.tau)
        r = rng.uniform(0.02, 0.12)
        for k in range(5):
            aa = a + k * 0.7
            rr = r + 0.015 * math.sin(k * 2 + i)
            pts.append((math.cos(aa) * rr, 0.022 + rng.uniform(0, 0.03), math.sin(aa) * rr))
        path, radii = C.curve(pts, [0.008] * 5, 4)
        o.tube(path, radii, pasta, seg=7, cap_rings=2)
    lumpy(o, (0, 0.11, 0), (0.08, 0.07, 0.08), meat, 24, 0.34)
    o.ball((0, 0.17, 0), (0.06, 0.028, 0.06), sauce)
    for a in (0.3, 2.4, 4.6):
        o.tube([(math.cos(a) * 0.04, 0.172, math.sin(a) * 0.04), (math.cos(a) * 0.078, 0.12, math.sin(a) * 0.078)],
               [0.016, 0.007], sauce, seg=10)
    o.ball((0.01, 0.2, 0), (0.022, 0.007, 0.014), herb)


@food("saucisson")
def _(o):
    for i, (x, z) in enumerate(((-0.035, -0.01), (0.012, 0.012), (0.045, -0.008))):
        disc(o, i * 0.012, 0.043, 0.013, meat, x, z, 0.003)
        disc(o, i * 0.012 + 0.013, 0.036, 0.001, meat_l, x, z)
        for k in range(5):
            a = k * 2.3 + i
            disc(o, i * 0.012 + 0.0142, 0.006, 0.001, fat, x + math.cos(a) * 0.021, z + math.sin(a) * 0.021)


@food("roti")
def _(o):
    for i in range(3):
        x = -0.055 + i * 0.052
        o.ball((x, 0.025 + i * 0.014, 0.0), (0.075, 0.016, 0.07), golden_d)
        o.ball((x + 0.004, 0.034 + i * 0.014, 0.0), (0.058, 0.01, 0.054), meat_l)


@food("plateau_fromages")
def _(o):
    o.box(-0.18, 0.0, -0.12, 0.18, 0.022, 0.12, wood, bevel=0.01)
    wedge_pts = [(0.3, 1.15, cheese, -0.085, -0.035), (2.2, 3.0, cheese_w, 0.085, 0.045)]
    for a0, a1, mat, x, z in wedge_pts:
        mid = (a0 + a1) / 2
        n = 8
        r = 0.12
        pts = [(0.0, 0.0)] + [(math.cos(a0 + (a1 - a0) * i / n) * r, math.sin(a0 + (a1 - a0) * i / n) * r) for i in range(n + 1)]
        low = [(p[0] - math.cos(mid) * r * 0.5 + x, 0.022, p[1] - math.sin(mid) * r * 0.5 + z) for p in pts]
        high = [(q[0], 0.075, q[2]) for q in low]
        o.add(high, [list(range(len(pts)))[::-1]], mat)
        for i in range(len(pts)):
            j = (i + 1) % len(pts)
            o.quad(low[i], high[i], high[j], low[j], mat)
    disc(o, 0.022, 0.045, 0.045, cheese_w, -0.07, 0.06, 0.012)
    o.box(0.04, 0.022, -0.09, 0.1, 0.065, -0.035, cheese, bevel=0.006)
    for i in range(5):
        disc(o, 0.022 + i * 0.002, 0.026, 0.008, crumb_c, 0.12 - i * 0.022, 0.0 + i * 0.004)


@food("farce")
def _(o):
    lumpy(o, (0, 0.04, 0), (0.055, 0.035, 0.055), m("farce", "#b98b52", 0.8), 16, 0.42)
    for i in range(5):
        a = i * 1.4
        o.ball((math.cos(a) * 0.03, 0.073, math.sin(a) * 0.03), 0.008, carrot if i % 2 else herb, seg=8, rings=6)


@food("cuisse")
def _(o):
    drumstick(o, (-0.08, 0.052, 0.0), (1.0, 0.04, 0.12), 0.135)


levels = [json.loads((C.ROOT / "levels" / f"niveau_{i}.json").read_text()) for i in range(1, 9)]
needed = {entry[0] for level in levels for entry in level["foods"].values()}
missing = needed - {o.name for o in made}
if missing:
    raise SystemExit(f"modèles de nourriture manquants : {sorted(missing)}")

objects = [o.build() for o in made]
C.export("nourriture")
for i, ob in enumerate(objects):
    col, row = i % 8, i // 8
    ob.location = C.G(((col - 3.5) * 0.5, 0.0, (row - 1.5) * 0.5))
C.render("nourriture", (0.0, 3.3, 2.7), (0.0, 0.0, 0.0), 36, (1600, 900))
