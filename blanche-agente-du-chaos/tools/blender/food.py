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
import textures as T  # noqa: E402
from mathutils import Matrix, Vector  # noqa: E402

C.reset()
rng = random.Random(12)
M = C.material


def m(name, color, rough=0.65, **kw):
    return M(name, color, rough, **kw)


def tasty(name, base, patches=(), speckles=(), rough=0.5, **kw):
    return M(name, **T.food(name, base, patches, speckles, rough, **kw))


plate = m("assiette", "#f6f3ec", 0.18)
rim = m("liseret", "#3a6fb5", 0.2)
platter = m("plateau", "#d3d6dc", 0.22, metal=0.6)
wood = M("planche", **T.wood("planche", "#cf9d62", "#8f6234", False, 0.3, 0.45, 0.6))
dough = tasty("pate", "#efd9ac", [("#dcbc83", 0.55, 0.8)], [("#fff3d8", 0.04)], 0.75)
golden = tasty("dore", "#e6a84c", [("#b56a1f", 0.52, 0.9), ("#f6cd7e", 0.58, 0.8)], [("#8c4f18", 0.012)], 0.45)
golden_d = tasty("dore_fonce", "#ab6420", [("#6f3a10", 0.52, 0.8)], [("#d99543", 0.03)], 0.42)
crust = tasty("croute", "#c98036", [("#8a4b17", 0.5, 0.9), ("#e5ae62", 0.58, 0.7)], [("#f7e2bc", 0.018)], 0.6, relief=1.8)
crumb_c = tasty("mie", "#f4e0ad", [("#e2c586", 0.55, 0.9)], [("#d3ae6d", 0.04), ("#fff2cf", 0.04)], 0.85, relief=2.0, cells=20)
pink = tasty("jambon", "#e6878a", [("#f4bcb6", 0.57, 0.9), ("#cf6670", 0.55, 0.6)], (), 0.35)
pink_l = tasty("jambon_pale", "#f1b2ab", [("#fbddd6", 0.57, 0.9)], (), 0.35)
cheese = tasty("fromage", "#f8c437", [("#ffdc6e", 0.55, 0.8), ("#e09a1c", 0.63, 0.9)], (), 0.32)
cheese_w = tasty("fromage_blanc", "#f7efd6", [("#fffaea", 0.55, 0.8), ("#e6d8ae", 0.6, 0.7)], [("#7d8f5e", 0.006)], 0.35)
meat = tasty("viande", "#80411f", [("#4b2110", 0.5, 0.9), ("#b26a3a", 0.6, 0.8)], [("#d9a176", 0.02)], 0.42, relief=2.2)
meat_l = tasty("viande_rose", "#bd6a59", [("#e8b0a0", 0.58, 0.9), ("#8f3f33", 0.55, 0.6)], (), 0.4)
sauce = tasty("sauce", "#cb331f", [("#8f1a0d", 0.52, 0.8), ("#ea6a3c", 0.62, 0.7)], [("#3f6b22", 0.008)], 0.16)
carrot = m("carotte", "#f2801c", 0.4)
lettuce = tasty("laitue", "#84c747", [("#b9e47a", 0.55, 0.8), ("#559a2a", 0.55, 0.7)], (), 0.55, relief=2.0)
herb = m("herbe", "#3f8a30", 0.55)
tomato = tasty("tomate", "#dd3a28", [("#f47052", 0.58, 0.8)], [("#f6d9a0", 0.012)], 0.22)
pepperoni = tasty("pepperoni", "#b62f1d", [("#7c1a0e", 0.52, 0.8), ("#e2804f", 0.64, 0.9)], (), 0.3, cells=20)
fat = m("gras", "#f4cbb4", 0.35)
butter = m("beurre", "#ffe673", 0.18)
pasta = tasty("nouille", "#f4d478", [("#dcae4a", 0.55, 0.8)], (), 0.25)
bone = m("os", "#f6eede", 0.35)
syrup = m("sirop", "#a8540f", 0.05)
dot = m("point_biscuit", "#52301a", 0.25)
blue = m("etiquette", "#3a6fb5", 0.4)
skin_c = tasty("peau_doree", "#cf7c1c", [("#8e440c", 0.5, 0.9), ("#eca93f", 0.58, 0.9)], [("#3f6b22", 0.006)], 0.24, relief=1.6)
olive = m("olive", "#26231f", 0.2)
mushroom = m("champignon", "#e6d3b3", 0.55)
pepper = m("poivron", "#3f9c3a", 0.3)
lemon = m("citron", "#f6d52e", 0.3)

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


def dish(o, r):
    """Une assiette creuse au rebord arrondi, avec son liseré bleu."""
    o.cyl((0, 0.0, 0), r * 0.78, 0.012, plate, seg=40, top=r)
    o.torus((0, 0.0125, 0), r * 0.965, 0.006, plate, seg=48, sides=8)
    o.torus((0, 0.0132, 0), r * 0.86, 0.0022, rim, seg=48, sides=6, squash=1.0)


def wavy(o, y, r, h, mat, x=0.0, z=0.0, ripple=0.05):
    """Un disque au bord irrégulier et bombé (une crêpe)."""
    seg = 30
    phase = rng.uniform(0, 6)
    rings = ((0.0, r * 0.86), (h * 0.45, r), (h, r * 0.9), (h * 1.1, r * 0.4))
    verts, faces = [], []
    for yy, rr in rings:
        for i in range(seg):
            a = math.tau * i / seg
            k = 1.0 + ripple * math.sin(a * 5 + phase) + ripple * 0.6 * math.sin(a * 11 + phase * 2)
            verts.append((x + math.cos(a) * rr * k, y + yy + h * 0.12 * math.sin(a * 3 + phase) * (rr / r),
                          z + math.sin(a) * rr * k))
    for j in range(len(rings) - 1):
        for i in range(seg):
            a, b = j * seg + i, j * seg + (i + 1) % seg
            faces.append([a, a + seg, b + seg, b])
    faces.append(list(range(seg)))
    faces.append([(len(rings) - 1) * seg + i for i in range(seg)][::-1])
    o.add(verts, faces, mat, smooth=True)


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
    dish(o, 0.15)
    for i in range(7):
        wavy(o, 0.012 + i * 0.017, 0.108 - rng.uniform(0, 0.008), 0.0145, golden if i % 3 else dough,
             rng.uniform(-0.008, 0.008), rng.uniform(-0.008, 0.008))
    # des petits fruits autour
    for a in (1.3, 3.5, 5.4):
        for k in range(3):
            o.ball((math.cos(a + k * 0.16) * 0.128, 0.026, math.sin(a + k * 0.16) * 0.128), 0.014,
                   tomato if a < 4 else olive, seg=10, rings=8)
    disc(o, 0.131, 0.075, 0.007, syrup, bevel=0.003)
    for a in (0.4, 2.5, 4.4):
        o.tube([(math.cos(a) * 0.06, 0.134, math.sin(a) * 0.06), (math.cos(a) * 0.108, 0.09, math.sin(a) * 0.108)],
               [0.014, 0.008], syrup, seg=10)
    o.box(-0.022, 0.138, -0.02, 0.022, 0.156, 0.02, butter, bevel=0.006)


@food("saucisse")
def _(o):
    dish(o, 0.155)
    o.tube([(-0.09, 0.016, -0.075), (-0.02, 0.018, -0.09), (0.07, 0.016, -0.07)], [0.012, 0.016, 0.008], lettuce, seg=10,
           squash=(1.6, 0.5))
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
    for i in range(14):
        a = i * math.tau / 14
        x, z = math.cos(a) * 0.148 * s, math.sin(a) * 0.148 * s
        if i % 3 == 0:
            o.cyl((x, 0.014, z), 0.024 * s, 0.008, lemon, seg=18, bevel=0.002)
            o.cyl((x, 0.0222, z), 0.016 * s, 0.001, butter, seg=18)
        elif i % 3 == 1:
            o.ball((x, 0.026, z), 0.017 * s, tomato, seg=12, rings=9)
        for k in range(3):
            o.ball((x * 0.96 + (k - 1) * 0.012 * s, 0.02 + k * 0.003, z * 0.96), (0.017 * s, 0.004 * s, 0.007 * s), herb,
                   seg=8, rings=5, matrix=Matrix.Rotation(a + k * 0.7, 3, "Y"))


@food("poulet_roti")
def _(o):
    bird(o, 1.0)


@food("dinde")
def _(o):
    bird(o, 1.35)
    # le houx des fêtes
    for a in (0.55, 2.5, 4.9):
        x, z = math.cos(a) * 0.2, math.sin(a) * 0.2
        for k in range(3):
            o.ball((x + math.cos(k * 2.1) * 0.012, 0.036, z + math.sin(k * 2.1) * 0.012), 0.013, tomato, seg=10, rings=8)
        for k in (-1, 1):
            o.ball((x + k * 0.032, 0.026, z - k * 0.012), (0.03, 0.004, 0.017), herb, seg=10, rings=6,
                   matrix=Matrix.Rotation(a + k * 0.5, 3, "Y"))


def cookie(o, x, y, z, r):
    o.cyl((x, y, z), r, 0.018, golden, seg=22, top=r * 0.88, bevel=0.006)
    for i in range(9):
        a = i * 2.4
        d = r * 0.72 * math.sqrt((i + 0.3) / 9)
        o.ball((x + math.cos(a) * d, y + 0.0175, z + math.sin(a) * d), (0.0095, 0.0058, 0.0082), dot, seg=8, rings=6,
               matrix=Matrix.Rotation(a, 3, "Y"))


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
    wedge(o, a0 + 0.04, a1 - 0.04, 0.165, 0.018, 0.008, cheese)
    for r, a in ((0.07, 1.55), (0.125, 1.35), (0.13, 1.78)):
        disc(o, 0.026, 0.022, 0.006, pepperoni, math.cos(a) * r + off[0], math.sin(a) * r + off[1])
    pts = [(math.cos(a) * 0.178 + off[0], 0.026, math.sin(a) * 0.178 + off[1])
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
    for i in range(6):
        a = i * 1.05 + 0.35
        x, z = math.cos(a) * (0.06 + 0.06 * (i % 2)), math.sin(a) * (0.06 + 0.06 * (i % 2))
        if i % 2:
            o.torus((x, 0.043, z), 0.011, 0.0055, olive, sides=8, seg=16)
            o.ball((x + 0.025, 0.043, z + 0.01), (0.017, 0.006, 0.013), mushroom, seg=10, rings=6)
        else:
            o.torus((x, 0.042, z), 0.02, 0.0045, pepper, sides=6, seg=16, arc=(a, a + 3.6))


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
    dish(o, 0.175)
    for i in range(34):
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


# la soupe de la troisième mission : seulement pour son image
@food("bol_soupe")
def _(o):
    bowl = m("bol_bleu", "#2f6f9e", 0.18)
    # le bol est plein : le bouillon et ce qui flotte sont posés juste au-dessus de son dessus, sous le rebord
    o.cyl((0, 0, 0), 0.085, 0.085, bowl, seg=48, top=0.165)
    o.torus((0, 0.086, 0), 0.158, 0.011, plate, seg=56, sides=10)
    o.cyl((0, 0.084, 0), 0.153, 0.005, tasty("bouillon", "#e59a2c", [("#f4bd55", 0.55, 0.8)], [("#3f7a24", 0.01)], 0.08), seg=48)
    for i in range(9):
        a = i * 2.4
        r = 0.11 * math.sqrt((i + 0.4) / 9)
        x, z = math.cos(a) * r, math.sin(a) * r
        if i % 3 == 0:
            o.cyl((x, 0.087, z), 0.022, 0.006, carrot, seg=18, bevel=0.002)
        elif i % 3 == 1:
            o.torus((x, 0.091, z), 0.018, 0.0055, pasta, sides=8, seg=14, arc=(a, a + 4.2))
        else:
            o.box(x - 0.014, 0.086, z - 0.012, x + 0.014, 0.096, z + 0.012, golden, bevel=0.005, seg=2)
    for i in range(7):
        a = i * 1.9
        o.ball((math.cos(a) * 0.06, 0.0905, math.sin(a) * 0.05), (0.011, 0.002, 0.006), herb, seg=8, rings=5)
    o.tube([(0.06, 0.085, 0.02), (0.17, 0.13, 0.05), (0.24, 0.13, 0.07)], [0.012, 0.01, 0.016], platter, seg=10,
           squash=(1.4, 0.7))


# ---------------------------------------------------------------- la salle à manger et le salon

egg_w = m("blanc_oeuf", "#fbf6ea", 0.3)
yolk = m("jaune_oeuf", "#f5b21c", 0.18)
bacon_m = tasty("bacon", "#b3402c", [("#7d2416", 0.52, 0.8)], (), 0.32)
bacon_fat = m("gras_bacon", "#f2c3a8", 0.35)
cretons = tasty("cretons", "#9c6b50", [("#7a4e38", 0.55, 0.8)], [("#d8b49a", 0.02)], 0.6)
beans = m("feves", "#8a3b1c", 0.15)
strawberry = m("fraise", "#d92e3a", 0.25)
blueberry = m("bleuet", "#3c4a8e", 0.25)
orange_c = m("orange_fruit", "#f39a2a", 0.35)
corn = m("mais", "#f4c63e", 0.3)
potato = tasty("patate_pilee", "#f4dfa4", [("#e8c27c", 0.55, 0.8)], [("#c7542c", 0.004)], 0.55, relief=2.2)
baking = m("plat_four", "#f1e9da", 0.16)
baking_band = m("plat_four_bord", "#2f5d8a", 0.2)
# la lasagne et le pâté chinois : de vrais étages, un dessus gratiné
mozza = tasty("mozza", "#f7dc8c", [("#fdebb8", 0.55, 0.8), ("#eebd62", 0.6, 0.7)], (), 0.22, relief=1.6)
mozza_gold = tasty("mozza_doree", "#e8a446", [("#c97c2a", 0.52, 0.8), ("#f3c46e", 0.6, 0.6)], (), 0.26, relief=1.8)
mozza_dark = tasty("mozza_grillee", "#b4672a", [("#87461a", 0.5, 0.8), ("#d08a3c", 0.6, 0.6)], (), 0.3, relief=2.0)
meat_sauce = tasty("sauce_viande", "#a3301b", [("#6e1c0d", 0.5, 0.9), ("#cc4a2a", 0.6, 0.7)], [("#5a2a14", 0.06)], 0.28,
                   relief=2.2, cells=60)
ricotta = tasty("ricotta", "#f8f2e2", [("#ffffff", 0.55, 0.6), ("#eadfc4", 0.6, 0.5)], [("#e0d2b0", 0.05)], 0.6, relief=2.0)
parmesan = m("parmesan", "#fbf3d6", 0.6)
basil = m("basilic", "#2f7a2c", 0.45)
corn_layer = tasty("mais_creme", "#f2c23a", [("#f8dc6c", 0.5, 0.9), ("#d9981c", 0.6, 0.7)], [("#fff1a0", 0.08)], 0.32,
                   relief=2.6, cells=64)
potato_gold = tasty("patate_doree", "#e2a752", [("#b9752b", 0.5, 0.8), ("#f2cd85", 0.6, 0.6)], [("#c7542c", 0.004)], 0.5,
                    relief=2.0)
potato_toast = tasty("patate_grillee", "#b8742c", [("#8a4e1c", 0.5, 0.8), ("#d39a50", 0.6, 0.6)], (), 0.5, relief=2.0)
paprika = m("paprika", "#b4321a", 0.5)
parsley = m("persil", "#3f8a30", 0.5)
sponge = tasty("gateau", "#f2d79c", [("#e4bd78", 0.55, 0.8)], [("#d8a85e", 0.02)], 0.7, relief=1.6)
frosting = m("glacage_rose", "#f6b8cb", 0.3)
frosting_w = m("glacage_blanc", "#fbf5ec", 0.3)
sprinkles = [m(f"vermicelle{i}", c, 0.4) for i, c in enumerate(("#4fb3e8", "#f5d33c", "#7fcf5a", "#e8547a"))]
candle = m("chandelle", "#7fc3e8", 0.4)
flame = m("flamme", "#ffd36a", 0.3, emit="#ffb43c", emit_power=3.0)
mustard = m("moutarde", "#f2c21b", 0.25)
sausage = tasty("saucisse_rouge", "#b24a35", [("#8a3021", 0.55, 0.8)], (), 0.3)
chip = tasty("chip", "#f2c457", [("#d89a35", 0.6, 0.7)], [("#fff1b8", 0.03)], 0.4)
bowl_red = m("bol_rouge", "#d43b33", 0.2)
bowl_white = m("bol_blanc", "#f4f1ea", 0.2)
popcorn = tasty("popcorn", "#fbf1d3", [("#f4d27a", 0.6, 0.6)], (), 0.7, relief=2.0)
melted = tasty("fromage_fondu", "#f4a632", [("#e07f1c", 0.55, 0.8)], (), 0.2)
salsa = m("salsa", "#c8331f", 0.2)
jalapeno = m("jalapeno", "#4a9a3a", 0.3)
licorice = m("reglisse", "#c32333", 0.3)
cardboard = tasty("carton", "#c9a272", [("#b48a5a", 0.55, 0.8)], (), 0.85)
pie_crust = tasty("pate_tarte", "#dcaa5c", [("#b77b34", 0.55, 0.9), ("#efcc8a", 0.6, 0.7)], [("#f7e4bc", 0.01)], 0.5,
                  relief=1.8)
filling = tasty("garniture", "#7a4a30", [("#5a3220", 0.5, 0.9)], [("#a77a52", 0.03)], 0.5, relief=2.0)
choco = tasty("chocolat", "#5a3420", [("#3f2213", 0.55, 0.8)], (), 0.35, relief=1.8)
sugar = m("sucre_glace", "#fbf8f2", 0.6)
holly = m("houx", "#2f6b33", 0.4)
glaze = tasty("jambon_glace", "#a9471d", [("#7e3010", 0.52, 0.9), ("#d9783a", 0.62, 0.8)], (), 0.12, relief=1.4)
ham_in = tasty("jambon_coeur", "#ef9a92", [("#f6c2b8", 0.57, 0.9)], (), 0.35)
clove = m("clou_girofle", "#3a2416", 0.6)
maple = m("erable_sirop", "#b8631a", 0.04)
pineapple = m("ananas", "#f5cf4a", 0.3)
cherry = m("cerise", "#c8102e", 0.08)


def bacon_strip(o, z, length=0.16, y=0.012):
    """Une tranche de bacon ondulée : rouge, avec des bandes de gras."""
    for i in range(9):
        x = -length / 2 + i * length / 8
        yy = y + 0.006 * math.sin(i * 1.4)
        o.box(x - 0.0095, yy, z - 0.022, x + 0.0095, yy + 0.008, z + 0.022, bacon_m if i % 3 else bacon_fat,
              bevel=0.002, seg=1)


@food("bacon")
def _(o):
    bacon_strip(o, -0.02)
    bacon_strip(o, 0.025, 0.14, 0.018)


@food("rotie_cretons")
def _(o):
    o.box(-0.07, 0.0, -0.07, 0.07, 0.02, 0.07, crust, bevel=0.012, seg=2)
    o.box(-0.062, 0.012, -0.062, 0.062, 0.024, 0.062, crumb_c, bevel=0.006, seg=1)
    lumpy(o, (0.0, 0.03, 0.0), (0.05, 0.01, 0.05), cretons, 8, 0.5)


@food("assiette_brunch")
def _(o):
    dish(o, 0.175)
    for x, z in ((-0.05, -0.05), (0.045, -0.065)):
        wavy(o, 0.012, 0.045, 0.006, egg_w, x, z, 0.12)
        o.ball((x + 0.004, 0.022, z), (0.019, 0.011, 0.019), yolk, seg=16, rings=10)
    # deux tranches de bacon ondulées, rouges striées de gras
    for k in range(2):
        for i in range(9):
            t = -0.05 + i * 0.0125
            rot = Matrix.Translation((0.075, 0.016 + 0.005 * math.sin(i * 1.5 + k), 0.03 + k * 0.035)) @ Matrix.Rotation(0.5, 4, "Y")
            o.box(t - 0.0072, -0.004, -0.012, t + 0.0072, 0.004, 0.012, bacon_m if (i + k) % 3 else bacon_fat, bevel=0.002,
                  seg=1, matrix=rot)
    o.box(-0.13, 0.012, 0.02, -0.04, 0.026, 0.11, crust, bevel=0.01, seg=1)
    o.box(-0.122, 0.02, 0.028, -0.048, 0.03, 0.102, crumb_c, bevel=0.005, seg=1)
    for i in range(14):
        a = i * 2.4
        o.ball((0.02 + math.cos(a) * 0.025 * math.sqrt(i / 14), 0.02, 0.08 + math.sin(a) * 0.02 * math.sqrt(i / 14)),
               (0.009, 0.007, 0.007), beans, seg=8, rings=6)
    for k, (x, z) in enumerate(((0.11, -0.04), (0.125, 0.0), (0.105, 0.075))):
        o.ball((x, 0.026, z), 0.016, strawberry if k != 1 else blueberry, seg=12, rings=8)
    o.cyl((-0.11, 0.014, -0.08), 0.03, 0.006, orange_c, seg=18)


@food("mais")
def _(o):
    for i in range(7):
        a = rng.uniform(0, math.tau)
        d = rng.uniform(0, 0.04)
        rot = Matrix.Translation((math.cos(a) * d, 0.007, math.sin(a) * d)) @ Matrix.Rotation(rng.uniform(0, 3), 4, "Y")
        o.box(-0.008, -0.006, -0.007, 0.008, 0.006, 0.007, corn, bevel=0.003, seg=1, matrix=rot)


@food("petit_pain")
def _(o):
    o.ball((0, 0.035, 0), (0.055, 0.035, 0.05), crust, seg=20, rings=12)
    o.tube([(-0.035, 0.066, 0.0), (0.035, 0.066, 0.0)], 0.004, golden_d, seg=6)


def bumps(seed, freq, count=6):
    """Un relief doux et sans motif : une somme d'ondes croisées, de -1 à 1 environ."""
    r = random.Random(seed)
    waves = [(r.uniform(0.6, 1.4) * freq, r.uniform(0.6, 1.4) * freq, r.uniform(0, 6.3), r.uniform(0, 6.3))
             for _ in range(count)]
    return lambda x, z: sum(math.sin(x * a + p) * math.sin(z * b + q) for a, b, p, q in waves) * 2.0 / count


def relief(o, x0, z0, x1, z1, step, height, pick, skip=None):
    """Une surface en relief au-dessus d'un rectangle : height(x, z) → y ; pick(x, z) → la matière de chaque carreau ;
    skip(x, z) : les carreaux à laisser vides (la portion déjà servie)."""
    nx, nz = max(2, round((x1 - x0) / step)), max(2, round((z1 - z0) / step))
    groups = {}
    for i in range(nx):
        for j in range(nz):
            cx, cz = x0 + (x1 - x0) * (i + 0.5) / nx, z0 + (z1 - z0) * (j + 0.5) / nz
            if skip and skip(cx, cz):
                continue
            groups.setdefault(pick(cx, cz), []).append((i, j))
    for mat, cells in groups.items():
        index, verts, faces = {}, [], []

        def vid(i, j):
            if (i, j) not in index:
                x, z = x0 + (x1 - x0) * i / nx, z0 + (z1 - z0) * j / nz
                index[(i, j)] = len(verts)
                verts.append((x, height(x, z), z))
            return index[(i, j)]
        for i, j in cells:
            faces.append([vid(i, j), vid(i, j + 1), vid(i + 1, j + 1), vid(i + 1, j)])
        o.add(verts, faces, mat, smooth=True)


def layers_around_cut(o, iw, id_, cx0, cz0, y, stack):
    """Les étages d'un plat dont on a servi le coin avant droit (x > cx0, z > cz0) : on voit leur tranche."""
    for th, mat in stack:
        o.box(-iw, y, -id_, cx0, y + th, id_, mat)
        o.box(cx0, y, -id_, iw, y + th, cz0, mat)
        y += th
    return y


def baking_dish(o, w, d, h, mat):
    o.box(-w / 2, 0.0, -d / 2, w / 2, 0.012, d / 2, mat, bevel=0.006, seg=1)
    for a, b, c, e in ((-w / 2, w / 2, -d / 2, -d / 2 + 0.012), (-w / 2, w / 2, d / 2 - 0.012, d / 2),
                       (-w / 2, -w / 2 + 0.012, -d / 2, d / 2), (w / 2 - 0.012, w / 2, -d / 2, d / 2)):
        o.box(a, 0.0, c, b, h, e, mat, bevel=0.004, seg=1)
    for s in (-1, 1):
        o.box(s * w / 2 - (0.03 if s > 0 else 0.0), h - 0.012, -0.04, s * w / 2 + (0.03 if s < 0 else 0.0), h, 0.04, mat,
              bevel=0.006, seg=1)
    # le liseré bleu du grès, tout le tour, sous le rebord
    for a, b, c, e in ((-w / 2 - 0.001, w / 2 + 0.001, -d / 2 - 0.001, -d / 2 + 0.002),
                       (-w / 2 - 0.001, w / 2 + 0.001, d / 2 - 0.002, d / 2 + 0.001),
                       (-w / 2 - 0.001, -w / 2 + 0.002, -d / 2, d / 2), (w / 2 - 0.002, w / 2 + 0.001, -d / 2, d / 2)):
        o.box(a, h - 0.022, c, b, h - 0.014, e, baking_band)


def leaf(o, x, y, z, length, width, angle, mat):
    """Une feuille pointue aux deux bouts, un peu bombée sur sa nervure (le basilic, le persil)."""
    rot = Matrix.Rotation(angle, 3, "Y")
    n = 8
    pts = []
    for side in (1, -1):
        for i in range(n + 1):
            t = i / n if side == 1 else 1 - i / n
            w = width * math.sin(math.pi * t) ** 0.8 * side
            pts.append(Vector(((t - 0.5) * length, 0.0006, w)))
    center = Vector((0, 0.0016, 0))
    verts = [tuple(Vector((x, y, z)) + rot @ center)] + [tuple(Vector((x, y, z)) + rot @ p) for p in pts]
    faces = [[0, 1 + (i + 1) % len(pts), 1 + i] for i in range(len(pts))]
    o.add(verts, faces, mat, smooth=True)


def mashed_top(o, x0, z0, x1, z1, top, seed, skip=None, dome_at=None, ridge=420.0):
    """La purée à la fourchette : des sillons serrés qui ondulent, dorés sur les crêtes et grillés par endroits, plus
    bombée au milieu ; un soupçon de paprika et de persil."""
    bump = bumps(seed, 60)
    gold = bumps(seed + 1, 40, 8)
    edge_of = dome_at or (lambda x, z: min(x - x0, x1 - x, z - z0, z1 - z))

    def wave(x, z):
        return math.sin(z * ridge + 2.4 * math.sin(x * 26.0 + seed) + 0.8 * math.sin(x * 61.0))

    def height(x, z):
        dome = min(1.0, max(0.0, edge_of(x, z)) / 0.025)
        return top + 0.004 + 0.01 * dome + 0.0022 * wave(x, z) * (0.4 + 0.6 * dome) + 0.0018 * bump(x, z)

    def pick(x, z):
        crest = wave(x, z) + 0.45 * gold(x, z) + (0.2 if edge_of(x, z) < 0.02 else 0.0)
        if crest > 1.05:
            return potato_toast
        if crest > 0.55:
            return potato_gold
        return potato
    relief(o, x0, z0, x1, z1, 0.0025, height, pick, skip)
    for i in range(int((x1 - x0) * (z1 - z0) * 900)):
        x, z = rng.uniform(x0 + 0.01, x1 - 0.01), rng.uniform(z0 + 0.01, z1 - 0.01)
        if skip and skip(x, z):
            continue
        if i % 4:
            o.ball((x, height(x, z) + 0.0008, z), (0.0016, 0.0005, 0.0016), paprika, seg=5, rings=3)
        else:
            leaf(o, x, height(x, z) + 0.0004, z, 0.006, 0.0022, rng.uniform(0, 3), parsley)


def corn_kernels(o, points):
    for x, y, z in points:
        o.ball((x, y, z), (0.0034, 0.003, 0.0034), corn, seg=8, rings=5)


@food("portion_pate_chinois")
def _(o):
    w, d = 0.11, 0.09
    o.box(-w / 2, 0.0, -d / 2, w / 2, 0.022, d / 2, meat, bevel=0.004, seg=1)
    o.box(-w / 2, 0.022, -d / 2, w / 2, 0.036, d / 2, corn_layer, bevel=0.002, seg=1)
    o.box(-w / 2, 0.036, -d / 2, w / 2, 0.044, d / 2, potato, bevel=0.002, seg=1)
    mashed_top(o, -w / 2, -d / 2, w / 2, d / 2, 0.04, 21)
    # les grains de blé d'Inde qui sortent de la tranche
    corn_kernels(o, [(rng.uniform(-w / 2.1, w / 2.1), rng.uniform(0.025, 0.033), s * d / 2) for s in (-1, 1)
                     for _ in range(9)] + [(s * w / 2, rng.uniform(0.025, 0.033), rng.uniform(-d / 2.1, d / 2.1))
                                           for s in (-1, 1) for _ in range(7)])


@food("pate_chinois")
def _(o):
    w, d, h = 0.3, 0.22, 0.07
    baking_dish(o, w, d, h, baking)
    iw, id_ = w / 2 - 0.012, d / 2 - 0.012
    cx0, cz0 = iw - 0.085, id_ - 0.075
    cut = lambda x, z: x > cx0 and z > cz0
    top = layers_around_cut(o, iw, id_, cx0, cz0, 0.012, [(0.022, meat), (0.013, corn_layer), (0.006, potato)])
    edge = lambda x, z: min(iw - abs(x), id_ - abs(z), max(cx0 - x, cz0 - z))
    mashed_top(o, -iw, -id_, iw, id_, top - 0.004, 11, skip=cut, dome_at=edge)
    # la portion servie : la tranche des trois étages, le blé d'Inde en grains, un fond de viande dans le plat
    kernels = [(cx0 + 0.002, rng.uniform(0.036, 0.045), rng.uniform(cz0 + 0.005, id_ - 0.005)) for _ in range(10)]
    kernels += [(rng.uniform(cx0 + 0.005, iw - 0.005), rng.uniform(0.036, 0.045), cz0 + 0.002) for _ in range(10)]
    corn_kernels(o, kernels)
    for i in range(7):
        o.ball((rng.uniform(cx0 + 0.015, iw - 0.015), 0.014, rng.uniform(cz0 + 0.015, id_ - 0.015)),
               (0.008, 0.003, 0.007), meat, seg=8, rings=4)


@food("miette_gateau")
def _(o):
    crumbs(o, sponge, 6)
    o.ball((0.02, 0.012, 0.0), 0.009, frosting, seg=8, rings=6)


@food("sandwich_pointe")
def _(o):
    for k, (y, h, mat) in enumerate(((0.0, 0.014, crumb_c), (0.014, 0.008, pink), (0.022, 0.014, crumb_c))):
        v = [(-0.05, y, -0.04), (0.05, y, -0.04), (0.0, y, 0.05), (-0.05, y + h, -0.04), (0.05, y + h, -0.04),
             (0.0, y + h, 0.05)]
        faces = [[0, 1, 2], [3, 5, 4], [0, 3, 4, 1], [1, 4, 5, 2], [2, 5, 3, 0]]
        verts, out = [], []
        for f in faces:
            out.append(list(range(len(verts), len(verts) + len(f))))
            verts.extend(v[i] for i in f)
        o.add(verts, out, mat)


def hot_dog(o, z=0.0, turn=0.0):
    rot = Matrix.Rotation(turn, 3, "Y")

    def at(x, y, zz):
        return tuple(Vector((0, 0, z)) + rot @ Vector((x, y, zz)))
    o.tube([at(-0.075, 0.025, 0.0), at(0.075, 0.025, 0.0)], 0.03, golden, seg=16, squash=(1.0, 0.8), cap_rings=3)
    o.tube([at(-0.085, 0.045, 0.0), at(0.085, 0.045, 0.0)], 0.018, sausage, seg=14)
    path, radii = C.curve([at(-0.06, 0.064, -0.006), at(-0.03, 0.065, 0.006), at(0.0, 0.064, -0.006),
                           at(0.03, 0.065, 0.006), at(0.06, 0.064, -0.006)], [0.0045] * 5, 4)
    o.tube(path, radii, mustard, seg=8)


@food("plateau_hot_dogs")
def _(o):
    """Le plateau que Maman apporte à la fête : quatre hot-dogs moutarde."""
    dish(o, 0.19)
    for k in range(4):
        hot_dog(o, -0.09 + k * 0.06, rng.uniform(-0.08, 0.08))


@food("hot_dog")
def _(o):
    hot_dog(o)


@food("part_gateau")
def _(o):
    dish(o, 0.14)
    off = wedge(o, 1.1, 2.0, 0.17, 0.012, 0.06, sponge)
    wedge(o, 1.1, 2.0, 0.17, 0.035, 0.008, frosting)
    wedge(o, 1.1, 2.0, 0.17, 0.072, 0.012, frosting)
    for i in range(16):
        a = rng.uniform(1.2, 1.9)
        r = rng.uniform(0.03, 0.15)
        o.box(-0.006, 0, -0.0015, 0.006, 0.003, 0.0015, sprinkles[i % 4],
              matrix=Matrix.Translation((math.cos(a) * r + off[0], 0.085, math.sin(a) * r + off[1]))
              @ Matrix.Rotation(rng.uniform(0, 3), 4, "Y"))
    o.cyl((off[0] + math.cos(1.55) * 0.1, 0.084, off[1] + math.sin(1.55) * 0.1), 0.006, 0.07, candle, seg=10)
    o.ball((off[0] + math.cos(1.55) * 0.1, 0.162, off[1] + math.sin(1.55) * 0.1), (0.008, 0.014, 0.008), flame, seg=8,
           rings=6)


@food("miette_pain_ail")
def _(o):
    crumbs(o, crust, 7)
    o.ball((0.0, 0.01, 0.02), (0.006, 0.002, 0.006), herb, seg=6, rings=4)


@food("pain_ail")
def _(o):
    o.cyl((0, 0, 0), 0.05, 0.022, crust, seg=22, bevel=0.008)
    o.cyl((0, 0.018, 0), 0.044, 0.008, crumb_c, seg=22)
    o.cyl((0, 0.026, 0), 0.038, 0.003, butter, seg=18)
    for i in range(6):
        a = i * 1.1
        o.ball((math.cos(a) * 0.024, 0.029, math.sin(a) * 0.024), (0.006, 0.002, 0.004), herb, seg=6, rings=4)


LASAGNA_STACK = [(0.005, pasta), (0.011, meat_sauce), (0.006, ricotta), (0.005, pasta), (0.011, meat_sauce),
                 (0.005, pasta), (0.004, sauce)]


def cheese_top(o, x0, z0, x1, z1, top, seed, skip=None, edge_of=None):
    """La mozzarella gratinée : bombée et cloquée, dorée par plaques, grillée par taches, la sauce qui perce ici et là
    et bouillonne contre le plat ; du parmesan et quelques feuilles de basilic. Peinte carreau par carreau, assez fin
    (2,5 mm) pour qu'on ne voie pas les marches en jeu."""
    bump = bumps(seed, 110)
    broad = bumps(seed + 1, 45, 8)
    fine = bumps(seed + 2, 160, 8)
    holes = bumps(seed + 3, 120, 8)
    edge_of = edge_of or (lambda x, z: min(x - x0, x1 - x, z - z0, z1 - z))

    def height(x, z):
        dome = min(1.0, max(0.0, edge_of(x, z)) / 0.018)
        return top + 0.003 + 0.005 * dome + 0.0022 * bump(x, z) * dome

    def pick(x, z):
        edge = edge_of(x, z)
        if edge < 0.005 + 0.003 * fine(x, z):
            return sauce
        toast = broad(x, z) * 0.7 + fine(x, z) * 0.45 + (0.25 if edge < 0.03 else 0.0)
        if holes(x, z) > 0.78:
            return meat_sauce
        if toast > 0.72:
            return mozza_dark
        if toast > 0.25:
            return mozza_gold
        return mozza
    relief(o, x0, z0, x1, z1, 0.0025, height, pick, skip)
    area = (x1 - x0) * (z1 - z0)
    for i in range(int(area * 900)):
        x, z = rng.uniform(x0 + 0.01, x1 - 0.01), rng.uniform(z0 + 0.01, z1 - 0.01)
        if not (skip and skip(x, z)):
            o.ball((x, height(x, z) + 0.0018, z), (0.0016, 0.0006, 0.0013), parmesan, seg=5, rings=3)
    for i in range(max(1, int(area * 70))):
        x, z = rng.uniform(x0 + 0.02, x1 - 0.02), rng.uniform(z0 + 0.02, z1 - 0.02)
        if skip and skip(x, z):
            continue
        leaf(o, x, height(x, z) + 0.0016, z, 0.024, 0.008, rng.uniform(0, math.pi), basil)


def lasagna_block(o, w, d):
    y = 0.0
    for th, mat in LASAGNA_STACK:
        o.box(-w / 2, y, -d / 2, w / 2, y + th, d / 2, mat, bevel=0.0015, seg=1)
        y += th
    # les bords ondulés des pâtes qui dépassent un peu de la tranche
    yy = 0.0
    for th, mat in LASAGNA_STACK:
        if mat is pasta:
            for s in (-1, 1):
                o.box(-w / 2 - 0.002, yy, s * d / 2 - 0.0015, w / 2 + 0.002, yy + th, s * d / 2 + 0.0015, pasta, bevel=0.001,
                      seg=1)
        yy += th
    cheese_top(o, -w / 2, -d / 2, w / 2, d / 2, y, 31)
    return y + 0.01


@food("carre_lasagne")
def _(o):
    lasagna_block(o, 0.11, 0.09)
    o.ball((0.0, 0.07, 0.0), (0.012, 0.003, 0.008), herb, seg=8, rings=5)


@food("lasagne")
def _(o):
    w, d, h = 0.32, 0.23, 0.075
    baking_dish(o, w, d, h, baking)
    iw, id_ = w / 2 - 0.012, d / 2 - 0.012
    cx0, cz0 = iw - 0.09, id_ - 0.08
    cut = lambda x, z: x > cx0 and z > cz0
    top = layers_around_cut(o, iw, id_, cx0, cz0, 0.012, LASAGNA_STACK)
    edge = lambda x, z: min(iw - abs(x), id_ - abs(z), max(cx0 - x, cz0 - z) + 0.012)
    cheese_top(o, -iw, -id_, iw, id_, top, 41, skip=cut, edge_of=edge)
    # la portion servie : un fond de sauce dans le plat, et une lasagne qui s'écroule un peu à la tranche
    for i in range(6):
        o.ball((rng.uniform(cx0 + 0.015, iw - 0.015), 0.013, rng.uniform(cz0 + 0.015, id_ - 0.015)),
               (0.012, 0.0025, 0.01), meat_sauce, seg=8, rings=4)
    for s in range(5):
        o.ball((cx0 + 0.002, 0.03 + s * 0.006, rng.uniform(cz0, id_)), (0.004, 0.003, 0.006), meat_sauce, seg=6, rings=4)


def chip_disc(o, x, y, z, r, tilt):
    rot = Matrix.Translation((x, y, z)) @ Matrix.Rotation(tilt[0], 4, "X") @ Matrix.Rotation(tilt[1], 4, "Z")
    verts, faces = [], []
    seg = 14
    for i in range(seg):
        a = math.tau * i / seg
        k = 1.0 + 0.08 * math.sin(a * 3)
        for yy in (0.0, 0.004):
            p = Vector((math.cos(a) * r * k, yy + 0.008 * math.sin(a * 2), math.sin(a) * r * k))
            verts.append(tuple(rot @ p))
    for i in range(seg):
        a, b = i * 2, ((i + 1) % seg) * 2
        faces.append([a, b, b + 1, a + 1])
    faces.append([i * 2 for i in range(seg)][::-1])
    faces.append([i * 2 + 1 for i in range(seg)])
    o.add(verts, faces, chip, smooth=True)


@food("miette_chips")
def _(o):
    for i in range(4):
        chip_disc(o, rng.uniform(-0.03, 0.03), 0.006, rng.uniform(-0.03, 0.03), 0.014, (rng.uniform(-0.4, 0.4), 0.2))


@food("bol_chips")
def _(o):
    o.cyl((0, 0, 0), 0.07, 0.07, bowl_white, top=0.13, seg=32, bevel=0.004)
    o.torus((0, 0.07, 0), 0.128, 0.006, bowl_red, seg=36, sides=6)
    for i in range(30):
        a = i * 2.4
        r = 0.1 * math.sqrt((i + 0.5) / 30)
        chip_disc(o, math.cos(a) * r, 0.065 + rng.uniform(0, 0.02), math.sin(a) * r, 0.026,
                  (rng.uniform(-0.6, 0.6), rng.uniform(-0.6, 0.6)))


@food("popcorn")
def _(o):
    for i in range(6):
        a = i * 1.7
        lumpy(o, (math.cos(a) * 0.025, 0.014, math.sin(a) * 0.025), (0.013, 0.012, 0.013), popcorn, 4, 0.6)


@food("grain_popcorn")
def _(o):
    for i in range(3):
        a = i * 2.1
        lumpy(o, (math.cos(a) * 0.018, 0.012, math.sin(a) * 0.018), (0.012, 0.011, 0.012), popcorn, 4, 0.6)


@food("bol_popcorn")
def _(o):
    for k in range(12):
        a0, a1 = k * math.tau / 12, (k + 1) * math.tau / 12
        mat = bowl_red if k % 2 == 0 else bowl_white
        pts = []
        for a in (a0, a1):
            pts.append((math.cos(a) * 0.075, 0.0, math.sin(a) * 0.075))
            pts.append((math.cos(a) * 0.11, 0.13, math.sin(a) * 0.11))
        o.quad(pts[0], pts[2], pts[3], pts[1], mat)
    o.cyl((0, 0, 0), 0.075, 0.004, bowl_white, seg=24)
    for i in range(26):
        a = i * 2.4
        r = 0.09 * math.sqrt((i + 0.5) / 26)
        lumpy(o, (math.cos(a) * r, 0.13 + rng.uniform(-0.01, 0.025), math.sin(a) * r), (0.017, 0.015, 0.017), popcorn, 3, 0.6)


# La soirée pyjama : des oursons en jujube, une canette de bubly, le gros sac de bonbons.
gummy = [m(f"jujube_{n}", c, 0.12, alpha=0.82) for n, c in (("rouge", "#e8303f"), ("vert", "#62c23a"),
                                                            ("jaune", "#f6c21c"), ("orange", "#f47a1f"))]
can_m = m("canette_rose", "#f05f86", 0.25, metal=0.6)
can_top = m("canette_alu", "#d7dbe0", 0.2, metal=0.9)
can_band = m("canette_bande", "#fbe7ee", 0.3)
can_dot = m("canette_bulle", "#ffffff", 0.2)
fruit = m("pamplemousse", "#f59a5c", 0.4)
bucket_red = m("seau_rouge", "#d63a3a", 0.3)
bucket_white = m("seau_blanc", "#f6f2ea", 0.3)


def gummy_bear(o, x, z, turn, mat, y=0.0):
    """Un ourson en jujube couché sur le dos : ventre, tête, oreilles, pattes ; translucide et luisant."""
    rot = Matrix.Rotation(turn, 3, "Y")

    def at(px, py, pz):
        return tuple(Vector((x, y, z)) + rot @ Vector((px, py, pz)))
    o.ball(at(0, 0.011, 0.0), (0.012, 0.009, 0.015), mat, seg=12, rings=8)
    o.ball(at(0, 0.012, -0.019), (0.011, 0.009, 0.010), mat, seg=12, rings=8)
    for s in (-1, 1):
        o.ball(at(0.008 * s, 0.013, -0.027), 0.0045, mat, seg=8, rings=6)
        o.ball(at(0.012 * s, 0.009, -0.004), (0.005, 0.005, 0.006), mat, seg=8, rings=6)
        o.ball(at(0.009 * s, 0.009, 0.014), (0.0055, 0.005, 0.007), mat, seg=8, rings=6)


@food("oursons")
def _(o):
    for i, (x, z, turn) in enumerate(((-0.018, 0.006, 0.4), (0.018, -0.004, -0.5), (0.0, 0.026, 1.6))):
        gummy_bear(o, x, z, turn, gummy[i % len(gummy)])


@food("bubly")
def _(o):
    """Une canette de bubly au pamplemousse rose : le corps coloré, sa bande pâle, des bulles et un sourire, le
    dessus d'alu et sa languette."""
    r, h = 0.034, 0.12
    o.cyl((0, 0, 0), r * 0.86, 0.008, can_top, seg=28, top=r)
    o.cyl((0, 0.008, 0), r, h - 0.02, can_m, seg=28)
    o.cyl((0, 0.05, 0), r + 0.0006, 0.03, can_band, seg=28)
    o.cyl((0, h - 0.012, 0), r, 0.012, can_top, seg=28, top=r * 0.82)
    o.torus((0, h, 0), r * 0.8, 0.0025, can_top, seg=28, sides=6)
    o.box(-0.006, h, -0.012, 0.006, h + 0.002, 0.008, can_top, bevel=0.001, seg=1)
    # le fruit et le sourire sur la bande, des bulles plus haut
    o.ball((0, 0.065, r + 0.002), (0.011, 0.011, 0.003), fruit, seg=12, rings=6)
    path, radii = C.curve([(-0.012, 0.056, r * 0.93 + 0.0035), (0.0, 0.052, r + 0.0035), (0.012, 0.056, r * 0.93 + 0.0035)],
                          [0.0016] * 3, 4)
    o.tube(path, radii, can_m, seg=6)
    for i in range(9):
        a = rng.uniform(-1.2, 1.2)
        y = rng.uniform(0.084, 0.1)
        o.ball((math.sin(a) * (r + 0.0015), y, math.cos(a) * (r + 0.0015)), 0.0028, can_dot, seg=6, rings=4)


@food("sac_bonbons")
def _(o):
    """Le gros sac de bonbons de la soirée pyjama : un sachet de cellophane bombé, noué d'un ruban rose, plein d'oursons
    en jujube et de bonbons emballés, deux suçons qui dépassent."""
    cello = m("cellophane", "#f4f8fb", 0.04, alpha=0.32)
    ribbon = m("ruban_rose", "#ef6fa1", 0.35)
    wraps = [m(f"papillote_{i}", c, 0.3) for i, c in enumerate(("#5bc0eb", "#f6d14b", "#9b5de5", "#f15bb5"))]
    # le contenu d'abord (on le voit à travers le sachet)
    for i in range(34):
        y = rng.uniform(0.035, 0.14)
        room = 0.105 * math.sqrt(max(0.0, 1 - ((y - 0.09) / 0.095) ** 2)) - 0.03
        a, r = rng.uniform(0, math.tau), room * math.sqrt(rng.uniform(0, 1))
        x, z = math.cos(a) * r, math.sin(a) * r
        if i % 3 == 0:
            w = wraps[i % len(wraps)]
            rot = Matrix.Rotation(rng.uniform(0, 3), 3, "Y")
            o.tube([tuple(Vector((x, y, z)) + rot @ Vector((-0.022, 0, 0))), tuple(Vector((x, y, z)) + rot @ Vector((0.022, 0, 0)))],
                   [0.004, 0.011, 0.004], w, seg=10)
        else:
            gummy_bear(o, x, z, rng.uniform(0, 6), gummy[i % len(gummy)], y - 0.01)
    # le sachet, son col froncé et le ruban
    o.ball((0, 0.09, 0), (0.105, 0.095, 0.1), cello, seg=28, rings=18)
    o.cyl((0, 0.175, 0), 0.03, 0.06, cello, seg=18, top=0.05)
    o.torus((0, 0.185, 0), 0.032, 0.007, ribbon, seg=20, sides=8)
    for s_ in (-1, 1):
        o.ball((0.03 * s_, 0.2, 0.0), (0.03, 0.016, 0.009), ribbon, seg=12, rings=8, matrix=Matrix.Rotation(0.5 * s_, 3, "Z"))
        o.tube([(0.03 * s_, 0.185, 0.03), (0.05 * s_, 0.17, 0.05)], [0.006, 0.005], ribbon, seg=6, squash=(1.0, 0.35))
    # deux suçons qui dépassent du col
    for k, (dx, tone) in enumerate(((-0.02, "#ff7eb6"), (0.024, "#7bd389"))):
        o.tube([(dx * 0.5, 0.16, 0.0), (dx, 0.26, 0.01)], 0.004, m("baton", "#f8f4ec", 0.5), seg=6)
        o.cyl((dx, 0.27, 0.01), 0.028, 0.012, m(f"sucon_{k}", tone, 0.15), axis=(0, 0, 1), seg=24, bevel=0.003)
        o.torus((dx, 0.27, 0.0235), 0.016, 0.0025, m("spirale_blanche", "#ffffff", 0.2), axis=(0, 0, 1), seg=20, sides=5)


@food("nachos")
def _(o):
    dish(o, 0.18)
    for i in range(18):
        a = rng.uniform(0, math.tau)
        r = rng.uniform(0.0, 0.11)
        x, z = math.cos(a) * r, math.sin(a) * r
        rot = Matrix.Translation((x, 0.02 + rng.uniform(0, 0.025), z)) @ Matrix.Rotation(rng.uniform(0, 6), 4, "Y") \
            @ Matrix.Rotation(rng.uniform(-0.5, 0.5), 4, "X")
        v = [(-0.035, 0, -0.03), (0.035, 0, -0.03), (0.0, 0, 0.045), (-0.035, 0.004, -0.03), (0.035, 0.004, -0.03),
             (0.0, 0.004, 0.045)]
        v = [tuple(rot @ Vector(p)) for p in v]
        faces = [[0, 1, 2], [3, 5, 4], [0, 3, 4, 1], [1, 4, 5, 2], [2, 5, 3, 0]]
        verts, out = [], []
        for f in faces:
            out.append(list(range(len(verts), len(verts) + len(f))))
            verts.extend(v[i] for i in f)
        o.add(verts, out, chip)
    for i in range(9):
        a = i * 2.3
        r = 0.06 * math.sqrt((i + 0.5) / 9)
        o.ball((math.cos(a) * r, 0.055, math.sin(a) * r), (0.028, 0.008, 0.022), melted, seg=12, rings=6)
    for i in range(6):
        a = i * 1.9 + 0.5
        o.ball((math.cos(a) * 0.05, 0.064, math.sin(a) * 0.05), (0.012, 0.006, 0.012), salsa, seg=10, rings=6)
        o.torus((math.cos(a + 0.9) * 0.07, 0.062, math.sin(a + 0.9) * 0.07), 0.009, 0.0035, jalapeno, sides=6, seg=12)


@food("reglisse")
def _(o):
    for k in range(2):
        pts = [(-0.07, 0.01 + k * 0.014, -0.012 + k * 0.024), (0.0, 0.012 + k * 0.014, 0.0 + k * 0.02),
               (0.07, 0.01 + k * 0.014, -0.012 + k * 0.024)]
        path, radii = C.curve(pts, [0.009] * 3, 6)
        o.tube(path, radii, licorice, seg=6, cap_rings=2)


@food("boite_pizza")
def _(o):
    o.box(-0.19, 0.0, -0.19, 0.19, 0.012, 0.19, cardboard)
    for a, b, c, d in ((-0.19, 0.19, -0.19, -0.18), (-0.19, 0.19, 0.18, 0.19), (-0.19, -0.18, -0.19, 0.19),
                       (0.18, 0.19, -0.19, 0.19)):
        o.box(a, 0.0, c, b, 0.04, d, cardboard)
    lid = Matrix.Translation((0, 0.04, -0.19)) @ Matrix.Rotation(-1.9, 4, "X") @ Matrix.Translation((0, -0.04, 0.19))
    o.box(-0.19, 0.036, -0.19, 0.19, 0.044, 0.19, cardboard, matrix=lid)
    disc(o, 0.012, 0.165, 0.014, dough, bevel=0.004)
    disc(o, 0.026, 0.148, 0.005, sauce)
    disc(o, 0.031, 0.14, 0.005, cheese, bevel=0.002)
    o.torus((0, 0.03, 0), 0.157, 0.016, crust, sides=10)
    for i in range(9):
        a = i * 2.4
        r = 0.105 * math.sqrt((i + 0.5) / 9)
        disc(o, 0.036, 0.024, 0.005, pepperoni, math.cos(a) * r, math.sin(a) * r)
    for k in range(6):
        a = k * math.pi / 3
        o.box(-0.0015, 0.037, -0.15, 0.0015, 0.039, 0.0, golden_d,
              matrix=Matrix.Rotation(a, 4, "Y"))


@food("miette_tourtiere")
def _(o):
    crumbs(o, pie_crust, 6)
    crumbs(o, filling, 3, 0.03, 0.012)


@food("tranche_buche")
def _(o):
    o.cyl((0, 0, 0), 0.045, 0.03, choco, seg=26, axis=(0, 1, 0), bevel=0.004)
    for k in range(3):
        o.torus((0, 0.0305, 0), 0.012 + k * 0.011, 0.003, frosting_w, seg=24, sides=5)
    for i in range(10):
        o.ball((rng.uniform(-0.035, 0.035), 0.032, rng.uniform(-0.035, 0.035)), (0.006, 0.001, 0.006), sugar, seg=6,
               rings=4)


def tourtiere(o, r, y=0.0):
    o.cyl((0, y, 0), r * 0.85, 0.045, pie_crust, top=r, seg=36, bevel=0.006)
    o.torus((0, y + 0.046, 0), r * 0.95, 0.012, pie_crust, seg=40, sides=8)
    for k in range(5):
        a = k * math.tau / 5
        rot = Matrix.Translation((math.cos(a) * r * 0.35, y + 0.048, math.sin(a) * r * 0.35)) @ Matrix.Rotation(-a, 4, "Y")
        o.box(-0.025, 0, -0.003, 0.025, 0.003, 0.003, filling, matrix=rot)


@food("tourtiere")
def _(o):
    """La tourtière entière, dans son assiette, que Maman sert au party."""
    dish(o, 0.2)
    tourtiere(o, 0.16, 0.012)


@food("pointe_tourtiere")
def _(o):
    off = wedge(o, 1.15, 2.0, 0.15, 0.0, 0.04, filling)
    wedge(o, 1.15, 2.0, 0.155, 0.04, 0.012, pie_crust)
    pts = [(math.cos(a) * 0.15 + off[0], 0.03, math.sin(a) * 0.15 + off[1]) for a in [1.15 + 0.85 * i / 8 for i in range(9)]]
    o.tube(pts, 0.016, pie_crust, seg=10)


@food("jambon_erable")
def _(o):
    """Le jambon glacé à l'érable des Fêtes : quadrillé et piqué de clous de girofle, garni à la québécoise de rondelles
    d'ananas et de cerises, des tranches roses en éventail devant, du houx sur le plat."""
    disc(o, 0.0, 0.21, 0.014, platter)
    o.ball((0, 0.09, 0), (0.15, 0.1, 0.115), glaze, seg=32, rings=20)

    def on_ham(x, z, lift=0.0):
        inside = max(0.0, 1 - (x / 0.15) ** 2 - (z / 0.115) ** 2)
        return 0.09 + 0.1 * math.sqrt(inside) + lift, inside
    # le quadrillage d'entailles, un clou de girofle à chaque croisement
    for i in range(-3, 4):
        for j in range(-3, 4):
            x, z = (i + j) * 0.026, (i - j) * 0.02
            y, inside = on_ham(x, z)
            if inside < 0.25:
                continue
            o.ball((x, y - 0.001, z), 0.0065, clove, seg=6, rings=4)
    # les rondelles d'ananas et leur cerise, couchées sur le dos du jambon
    for x, z in ((-0.06, -0.035), (0.055, -0.03), (0.0, 0.04), (-0.07, 0.05), (0.075, 0.055)):
        y, inside = on_ham(x, z, 0.004)
        tilt_x, tilt_z = -x / 0.15 * 0.9, z / 0.115 * 0.9
        rot = Matrix.Rotation(tilt_z, 3, "X") @ Matrix.Rotation(tilt_x, 3, "Z")
        o.torus((x, y, z), 0.021, 0.0062, pineapple, axis=tuple(rot @ Vector((0, 1, 0))), seg=24, sides=8, squash=0.55)
        o.ball((x, y + 0.004, z), 0.0075, cherry, seg=12, rings=8)
    # le glaçage qui a coulé au pied du jambon : des perles luisantes sur le plat
    for k in range(24):
        a = k * math.tau / 24 + rng.uniform(-0.08, 0.08)
        o.ball((math.cos(a) * 0.128, 0.016, math.sin(a) * 0.097), (0.026, 0.005, 0.017), maple, seg=10, rings=5,
               matrix=Matrix.Rotation(-a, 3, "Y"))
    # trois tranches ovales en éventail devant, chacune sur son bord de gras
    for k in range(3):
        a = 0.2 + k * 0.45
        cx, cz = 0.13 + math.cos(a) * 0.05, 0.06 + math.sin(a) * 0.05
        rot = Matrix.Rotation(-a, 3, "Y") @ Matrix.Rotation(0.12, 3, "Z")
        o.ball((cx, 0.022 + k * 0.007, cz), (0.052, 0.0045, 0.04), ham_in, seg=20, rings=6, matrix=rot)
        o.ball((cx + 0.004, 0.0205 + k * 0.007, cz), (0.057, 0.004, 0.045), fat, seg=20, rings=6, matrix=rot)
    for k in (-1, 1):
        o.ball((-0.17, 0.03, k * 0.06), (0.03, 0.006, 0.016), holly, seg=10, rings=6,
               matrix=Matrix.Rotation(k * 0.6, 3, "Y"))
        o.ball((-0.17, 0.034, k * 0.02), 0.012, tomato, seg=10, rings=8)


levels = [json.loads((C.ROOT / "levels" / f"niveau_{i}.json").read_text()) for i in range(1, len(list((C.ROOT / "levels").glob("niveau_*.json"))) + 1)]
needed = {entry[0] for level in levels for entry in level["foods"].values()}
missing = needed - {o.name for o in made}
if missing:
    raise SystemExit(f"modèles de nourriture manquants : {sorted(missing)}")

objects = [o.build() for o in made]
C.export("nourriture")

# les images des plats, pour les cartes de mission (fond transparent)
PLATS = {1: "pile_crepes", 2: "sandwich", 3: "bol_soupe", 4: "plaque_biscuits", 5: "pizza", 6: "grosse_boulette",
         7: "plateau_fromages", 8: "dinde", 9: "assiette_brunch", 10: "pate_chinois", 11: "part_gateau", 12: "lasagne",
         13: "nachos", 14: "bol_popcorn", 15: "sac_bonbons", 16: "jambon_erable"}
by_name = {o.name: o for o in objects}
for level, name in PLATS.items():
    for o in objects:
        o.hide_render = o.name != name
    points = [Vector((v.co.x, v.co.z, -v.co.y)) for v in by_name[name].data.vertices]
    low = Vector([min(p[i] for p in points) for i in range(3)])
    high = Vector([max(p[i] for p in points) for i in range(3)])
    center = (low + high) / 2
    reach = max((p - center).length for p in points)
    eye = center + Vector((0.25, 0.85, 1.0)).normalized() * reach * 3.35
    C.render_icon(f"plat_{level}", tuple(eye), tuple(center), 29, 384)
for o in objects:
    o.hide_render = False
for i, ob in enumerate(objects):
    col, row = i % 8, i // 8
    ob.location = C.G(((col - 3.5) * 0.5, 0.0, (row - 1.5) * 0.5))
C.render("nourriture", (0.0, 3.3, 2.7), (0.0, 0.0, 0.0), 36, (1600, 900))
