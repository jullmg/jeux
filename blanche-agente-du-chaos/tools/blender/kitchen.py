"""La cuisine, d'après les photos, aux dimensions de data/kitchen.json.

Blender --background --python tools/blender/kitchen.py
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
PLAN = json.loads((C.ROOT / "data" / "kitchen.json").read_text())
OB = PLAN["obstacles"]
H = PLAN["counter_height"]
rng = random.Random(5)


M = C.material


def mat(name, maps, **kw):
    return M(name, **maps, **kw)


floor_m = mat("plancher", T.floor(rng))
maple = mat("erable", T.wood("erable", "#e2b980", "#bf8e55", contrast=0.5))
maple_panel = mat("erable_panneau", T.wood("erable_panneau", "#dab077", "#b58450", contrast=0.45))
butcher = mat("billot", T.butcher(rng))
counter = mat("comptoir", T.quartz())
brick = mat("brique", T.bricks(rng))
tile = mat("carreaux", T.tiles(rng))
cushion_m = mat("coussin", T.fabric("coussin", "#767a86", 0.25, 7))
grey_wood = mat("bois_gris", T.wood("bois_gris", "#c2bfb7", "#87837a", False, 0.4, 0.6))
buffet_top = mat("dessus_buffet", T.wood("dessus_buffet", "#c89c68", "#85603a", False, 0.9, 0.36))
towel = mat("linge", T.fabric("linge", "#dedcd7", 0.14, 5))

wall = mat("mur", T.plaster("mur", "#ebe4d6"))
soffit = M("soffite", "#f1eee7", 0.9)
white = M("blanc", "#f3f1ec", 0.45)
white_soft = M("blanc_mat", "#e9e6df", 0.75)
steel = mat("inox", T.brushed("inox", "#e4e8ee", 0.9, 0.34, 0.7))
steel_dark = mat("inox_fonce", T.brushed("inox_fonce", "#aab0ba", 0.9, 0.38, 0.7))
black = M("noir", "#17161a", 0.35)
black_glass = M("vitre_noire", "#0e0f13", 0.12, 0.2)
black_mat = M("noir_mat", "#232227", 0.7)
brass = M("poignee", "#d8bd8e", 0.35, 0.6)
chrome = M("chrome", "#e2e4e8", 0.2, 0.8)
sky = M("ciel", "#bfd9ee", 1.0, emit="#a9cdea", emit_power=0.9)
yard = M("cour", "#a9654f", 1.0, emit="#7e4a3a", emit_power=0.5)
leaf = M("feuille", "#4f8a3d", 0.8)
leaf_d = M("feuille_fonce", "#356b32", 0.8)
pot_clay = M("pot", "#b9704a", 0.85)
pot_white = M("pot_blanc", "#ddd8ce", 0.5)
glass = M("verre", "#cfe3ea", 0.08, alpha=0.28)
frost = M("verre_depoli", "#dfe6e4", 0.5, alpha=0.72)
blind = M("store", "#cfd0cc", 0.7)
red = M("rouge", "#d9483f", 0.6)
yellow = M("jaune", "#d8e23c", 0.8)
orange = M("orange", "#ee8a2b", 0.6)
green_v = M("vert_chou", "#a9cc72", 0.7)
bread = M("pain_sac", "#d9a65f", 0.75)
paper = [M(f"papier{i}", c, 0.8) for i, c in enumerate(
    ["#f7f4ec", "#f6c9c4", "#fbe9a6", "#bfe0f2", "#cfe8bd", "#e2cdf0", "#f4b269", "#7a4f9c"])]
dark_glass_bottle = M("bouteille", "#4a2d18", 0.15)
steam_pot = M("chaudron", "#a9282b", 0.3, 0.2)


# ---------------------------------------------------------------- aides

def cabinet_front(o, axis, plane, a0, a1, y0, y1, handle="h", mat=None):
    """Une porte ou un tiroir à cadre sur une face. axis 'z' : face au sud (plan z) ; 'x' : face à l'ouest (plan x).

    La normale pointe vers +z pour 'z', vers -x pour 'x', vers +x pour 'x+'."""
    mat = mat or maple
    out = 1.0 if axis in ("z", "x+") else -1.0

    def slab(u0, u1, v0, v1, d0, d1, m, bevel=0.004):
        lo, hi = sorted((plane + out * d0, plane + out * d1))
        if axis == "z":
            o.box(u0, v0, lo, u1, v1, hi, m, bevel=bevel, seg=1)
        else:
            o.box(lo, v0, u0, hi, v1, u1, m, bevel=bevel, seg=1)

    g = 0.006
    slab(a0 + g, a1 - g, y0 + g, y1 - g, 0.0, 0.016, mat)
    f = 0.055 if min(a1 - a0, y1 - y0) > 0.2 else 0.028
    # cadre en relief
    slab(a0 + g, a0 + g + f, y0 + g, y1 - g, 0.016, 0.028, maple)
    slab(a1 - g - f, a1 - g, y0 + g, y1 - g, 0.016, 0.028, maple)
    slab(a0 + g + f, a1 - g - f, y0 + g, y0 + g + f, 0.016, 0.028, maple)
    slab(a0 + g + f, a1 - g - f, y1 - g - f, y1 - g, 0.016, 0.028, maple)
    if handle == "h":
        mid = (a0 + a1) / 2
        half = min(0.09, (a1 - a0) * 0.28)
        yy = y1 - 0.06 if y1 - y0 > 0.3 else (y0 + y1) / 2
        slab(mid - half, mid + half, yy - 0.01, yy + 0.01, 0.045, 0.062, brass)
        for s in (-1, 1):
            slab(mid + s * half * 0.7 - 0.008, mid + s * half * 0.7 + 0.008, yy - 0.008, yy + 0.008, 0.016, 0.047, brass,
                 0.0)
    elif handle in ("left", "right"):
        u = a0 + 0.045 if handle == "left" else a1 - 0.045
        yy = y0 + 0.07 if y0 > 1.0 else y1 - 0.1
        slab(u - 0.014, u + 0.014, yy - 0.014, yy + 0.014, 0.028, 0.055, brass, 0.012)


def plant(o, base, r, height, leaves, mat_pot=pot_clay, trailing=0):
    o.cyl(base, r * 0.75, r * 1.2, mat_pot, top=r, seg=16)
    top = Vector(base) + Vector((0, r * 1.2, 0))
    for i in range(leaves):
        a = rng.uniform(0, math.tau)
        d = rng.uniform(0.2, 1.0)
        tip = top + Vector((math.cos(a) * r * 1.8 * d, rng.uniform(0.2, 1.0) * height, math.sin(a) * r * 1.8 * d))
        o.tube([top, (top + tip) / 2 + Vector((0, 0.02, 0))], 0.004, leaf_d, seg=5)
        rot = Matrix.Rotation(a, 3, "Y") @ Matrix.Rotation(rng.uniform(-0.8, 0.8), 3, "Z")
        o.ball(tip, (0.04, 0.009, 0.024), leaf if i % 3 else leaf_d, seg=8, rings=5, matrix=rot)
    for k in range(trailing):
        a = k * math.tau / max(1, trailing)
        p = [top + Vector((math.cos(a) * r, 0, math.sin(a) * r))]
        for j in range(1, 6):
            p.append(p[0] + Vector((math.cos(a) * 0.015 * j, -0.07 * j, math.sin(a) * 0.015 * j)))
        o.tube(p, 0.004, leaf_d, seg=5)
        for q in p[1:]:
            o.ball(q, (0.032, 0.008, 0.022), leaf, seg=8, rings=5, matrix=Matrix.Rotation(rng.uniform(0, 6), 3, "Y"))


# ---------------------------------------------------------------- pièce

room = C.Obj("Piece")
room.box(-2.15, -0.06, -2.25, 2.15, 0.0, 3.4, floor_m)
# mur nord et mur ouest
room.box(-2.15, 0, -2.25, 2.15, 2.8, -2.1, wall)
room.box(-2.15, 0, -2.1, -2.0, 2.8, 2.15, wall)
# mur est, percé pour la fenêtre
wz0, wz1 = PLAN["window"]
wy0, wy1 = 1.14, 2.04
room.box(2.0, 0, -2.1, 2.15, 2.8, wz0, wall)
room.box(2.0, 0, wz1, 2.15, 2.8, 2.15, wall)
room.box(2.0, 0, wz0, 2.15, wy0, wz1, wall)
room.box(2.0, wy1, wz0, 2.15, 2.8, wz1, wall)
# plinthes
room.box(-2.0, 0, -0.52, -1.985, 0.1, 2.15, white)
room.box(1.985, 0, 1.92, 2.0, 0.1, 2.15, white)
# soffite et sa moulure
room.box(-2.0, 2.27, -2.1, 2.0, 2.8, -1.74, soffit)
room.box(1.64, 2.27, -1.74, 2.0, 2.8, 0.8, soffit)
room.box(-2.0, 2.46, -1.745, 1.66, 2.49, -1.725, white)
room.box(1.625, 2.46, -1.74, 1.645, 2.49, 0.8, white)
# dosseret
room.box(-0.65, H, -2.1, 1.74, 1.44, -2.092, tile)
room.box(1.992, H, -1.88, 2.0, 1.12, 0.8, tile)
room.box(1.992, 1.12, -1.88, 2.0, 1.44, wz0, tile)
room.box(1.992, 1.12, wz1, 2.0, 1.44, 0.8, tile)
# coin de brique
room.box(1.74, H, -2.1, 2.0, 2.27, -1.88, brick)
room.build()

# ---------------------------------------------------------------- mur nord

north = C.Obj("MurNord")
# garde-manger
x0, z0, x1, z1 = OB["pantry"]
north.box(x0, 0, z0, x1, 2.25, z1 - 0.02, maple_panel)
cabinet_front(north, "z", z1 - 0.02, x0, x1, 0.1, 0.9, "right")
cabinet_front(north, "z", z1 - 0.02, x0, x1, 0.9, 1.72, "right")
cabinet_front(north, "z", z1 - 0.02, x0, x1, 1.72, 2.25, "right")
# armoire au-dessus du frigo
north.box(-1.45, 1.82, -2.1, -0.65, 2.27, -1.52, maple_panel)
cabinet_front(north, "z", -1.52, -1.45, -1.05, 1.82, 2.27, "right")
cabinet_front(north, "z", -1.52, -1.05, -0.65, 1.82, 2.27, "left")
# frigo : une caisse ouverte au-dessus du congélateur
fx0, fx1 = -1.43, -0.67
north.box(fx0, 0.03, -2.08, fx1, 0.64, -1.45, steel, bevel=0.012)
north.box(fx0, 0.64, -2.08, fx1, 1.78, -2.02, white)
north.box(fx0, 0.64, -2.02, fx0 + 0.05, 1.78, -1.45, steel)
north.box(fx1 - 0.05, 0.64, -2.02, fx1, 1.78, -1.45, steel)
north.box(fx0 + 0.05, 1.72, -2.02, fx1 - 0.05, 1.78, -1.45, steel)
for sy in (0.66, 1.0, 1.34):
    north.box(fx0 + 0.05, sy, -2.02, fx1 - 0.05, sy + 0.018, -1.5, white)
inside_colors = [orange, red, green_v, pot_white, dark_glass_bottle, paper[3], paper[2]]
for sy in (0.68, 1.02, 1.36):
    x = fx0 + 0.11
    while x < fx1 - 0.14:
        m = inside_colors[rng.randrange(len(inside_colors))]
        if rng.random() < 0.5:
            north.cyl((x, sy, -1.75), 0.045, rng.uniform(0.1, 0.24), m, seg=12)
        else:
            north.box(x - 0.05, sy, -1.84, x + 0.05, sy + rng.uniform(0.08, 0.18), -1.7, m, bevel=0.012, seg=1)
        x += 0.14
north.box(fx0 + 0.08, 1.64, -1.98, fx0 + 0.2, 1.7, -1.9, M("lumiere_frigo", "#fff6da", 1.0, emit="#fff1c2", emit_power=2.0))
# poignée du congélateur
north.tube([(fx0 + 0.1, 0.55, -1.40), (fx1 - 0.1, 0.55, -1.40)], 0.014, chrome, seg=10)
for hx in (fx0 + 0.12, fx1 - 0.12):
    north.box(hx - 0.012, 0.54, -1.45, hx + 0.012, 0.56, -1.405, chrome)
# assiette sur le frigo
north.cyl((-1.0, 1.78, -1.75), 0.16, 0.025, pot_white, top=0.19)
# comptoirs du nord
for a, b in ((-0.65, -0.12), (0.64, 2.0)):
    north.box(a, 0.0, -2.1, b, 0.1, -1.58, black_mat)
    north.box(a, 0.1, -2.1, min(b, 1.40), 0.88, -1.52, maple_panel)
    north.box(a, 0.88, -2.1, min(b, 1.38), H, -1.48, counter, bevel=0.01, seg=1)
# bloc de coin
north.box(1.38, 0.88, -2.1, 2.0, H, -1.48, counter)
north.box(1.40, 0.1, -2.1, 2.0, 0.88, -1.52, maple_panel)
cabinet_front(north, "z", -1.52, -0.65, -0.12, 0.66, 0.88)
cabinet_front(north, "z", -1.52, -0.65, -0.12, 0.4, 0.66)
cabinet_front(north, "z", -1.52, -0.65, -0.12, 0.1, 0.4)
cabinet_front(north, "z", -1.52, 0.64, 1.02, 0.1, 0.88, "right")
cabinet_front(north, "z", -1.52, 1.02, 1.40, 0.1, 0.88, "left")
# armoires du haut
uz = -1.76
north.box(-0.65, 1.42, -2.1, -0.12, 2.27, uz, maple_panel)
cabinet_front(north, "z", uz, -0.65, -0.385, 1.42, 2.27, "right")
cabinet_front(north, "z", uz, -0.385, -0.12, 1.42, 2.27, "left")
north.box(-0.12, 1.72, -2.1, 0.64, 2.27, uz, maple_panel)
cabinet_front(north, "z", uz, -0.12, 0.26, 1.72, 2.27, "right")
cabinet_front(north, "z", uz, 0.26, 0.64, 1.72, 2.27, "left")
north.box(0.64, 1.72, -2.1, 1.38, 2.27, uz, maple_panel)
cabinet_front(north, "z", uz, 0.64, 1.01, 1.72, 2.27, "right")
cabinet_front(north, "z", uz, 1.01, 1.38, 1.72, 2.27, "left")
north.box(1.38, 1.42, -2.1, 1.74, 2.27, uz, maple_panel)
cabinet_front(north, "z", uz, 1.38, 1.74, 1.42, 2.27, "left")
# hotte
north.box(-0.12, 1.58, -2.1, 0.64, 1.72, -1.72, white, bevel=0.02)
north.box(-0.1, 1.55, -2.08, 0.62, 1.58, -1.76, white_soft)
# micro-ondes sur sa tablette
north.box(0.66, 1.29, -2.1, 1.38, 1.32, -1.72, maple)
north.box(0.66, 1.32, -2.1, 0.69, 1.72, -1.76, maple)
north.box(0.74, 1.325, -2.06, 1.32, 1.64, -1.75, steel, bevel=0.012)
north.box(0.78, 1.36, -1.75, 1.17, 1.60, -1.742, black_glass)
north.box(1.20, 1.36, -1.75, 1.29, 1.60, -1.742, black_mat)
for k in range(4):
    north.box(1.215, 1.39 + k * 0.045, -1.742, 1.275, 1.41 + k * 0.045, -1.738, steel_dark)
# cuisinière
north.box(-0.115, 0.02, -2.09, 0.635, 0.9, -1.50, steel, bevel=0.01, seg=1)
north.box(-0.115, 0.9, -2.09, 0.635, H, -1.49, black_glass, bevel=0.006, seg=1)
for bx, bz, br in ((0.06, -1.66, 0.11), (0.46, -1.66, 0.085), (0.06, -1.93, 0.075), (0.46, -1.93, 0.1)):
    north.torus((bx, H + 0.001, bz), br, 0.004, steel_dark, sides=5)
north.box(-0.115, H, -2.09, 0.635, 1.13, -2.03, steel, bevel=0.012)
north.box(0.15, 0.99, -2.03, 0.39, 1.08, -2.025, black_glass)
north.box(0.22, 1.02, -2.025, 0.32, 1.05, -2.022, M("afficheur", "#7fd4ff", 1.0, emit="#7fd4ff", emit_power=1.5))
for kx in (-0.05, 0.05, 0.47, 0.57):
    north.cyl((kx, 1.035, -2.03), 0.028, 0.03, chrome, axis=(0, 0, 1), seg=16)
north.box(-0.07, 0.34, -1.50, 0.59, 0.72, -1.488, black_glass)
north.tube([(-0.06, 0.78, -1.455), (0.58, 0.78, -1.455)], 0.016, chrome, seg=10)
for hx in (-0.04, 0.56):
    north.box(hx - 0.012, 0.77, -1.50, hx + 0.012, 0.79, -1.46, chrome)
north.box(0.30, 0.50, -1.447, 0.50, 0.795, -1.437, towel, bevel=0.004, seg=1)
for k in range(3):
    north.box(0.30, 0.54 + k * 0.05, -1.4365, 0.50, 0.55 + k * 0.05, -1.436, black_mat)
north.box(0.1, 0.12, -1.49, 0.42, 0.13, -1.485, steel_dark)
# chaudron et poêle
north.cyl((0.06, H, -1.76), 0.12, 0.13, steam_pot, seg=28, bevel=0.012)
north.torus((0.06, H + 0.13, -1.76), 0.115, 0.007, steel, sides=6)
for s in (-1, 1):
    north.box(0.06 + s * 0.12 - 0.025, H + 0.1, -1.775, 0.06 + s * 0.12 + 0.025, H + 0.118, -1.745, black)
north.cyl((0.44, H, -1.9), 0.1, 0.035, black_mat, top=0.12)
north.tube([(0.54, H + 0.03, -1.88), (0.70, H + 0.04, -1.84)], 0.012, black, seg=8)
# objets du comptoir (au fond, loin des endroits à nourriture)
north.cyl((-0.57, H, -1.98), 0.06, 0.28, white_soft, seg=20)
north.cyl((-0.57, H, -1.98), 0.012, 0.31, steel, seg=8)
north.box(-0.30, H, -2.06, -0.14, H + 0.17, -1.9, steel_dark, bevel=0.035, seg=3)
north.box(-0.28, H + 0.17, -2.0, -0.16, H + 0.18, -1.96, black)
north.cyl((-0.255, H + 0.07, -1.9), 0.016, 0.012, black, axis=(0, 0, 1), seg=10)
north.box(0.70, H, -2.06, 0.80, H + 0.19, -1.98, black, bevel=0.02)
north.cyl((0.75, H + 0.19, -2.02), 0.035, 0.05, chrome)
north.cyl((1.1, H, -2.0), 0.035, 0.2, white, seg=14)
north.cyl((1.1, H + 0.2, -2.0), 0.014, 0.06, white, seg=10)
north.cyl((1.2, H, -2.02), 0.03, 0.17, black_mat, seg=14)
# cafetière dans le coin
north.box(1.48, H, -2.06, 1.74, H + 0.3, -1.84, black, bevel=0.03)
north.box(1.52, H + 0.04, -1.84, 1.70, H + 0.19, -1.82, black_glass)
north.cyl((1.61, H + 0.04, -1.80), 0.05, 0.1, dark_glass_bottle, top=0.044)
north.cyl((1.69, H + 0.24, -1.84), 0.014, 0.012, orange, axis=(0, 0, 1))
north.build()

# porte du frigo, articulée à gauche
door = C.Obj("PorteFrigo", origin=(-1.43, 0.0, -1.45))
door.box(-1.43, 0.655, -1.45, -0.67, 1.78, -1.40, steel, bevel=0.016)
door.tube([(-0.74, 0.8, -1.355), (-0.74, 1.6, -1.355)], 0.014, chrome, seg=10)
for hy in (0.83, 1.57):
    door.box(-0.752, hy - 0.012, -1.40, -0.728, hy + 0.012, -1.36, chrome)


def note(x, y, w, h, m, doodle=None, tilt=0.0):
    mat = Matrix.Translation((x, y, -1.3975)) @ Matrix.Rotation(tilt, 4, "Z") @ Matrix.Translation((-x, -y, 1.3975))
    door.box(x - w / 2, y - h / 2, -1.399, x + w / 2, y + h / 2, -1.3965, m, matrix=mat)
    z = -1.3955
    if doodle == "lignes":
        for k in range(int(h / 0.022) - 1):
            door.box(x - w * 0.38, y + h / 2 - 0.025 - k * 0.022, -1.3968, x + w * rng.uniform(0.0, 0.38),
                     y + h / 2 - 0.018 - k * 0.022, z, steel_dark, matrix=mat)
    elif doodle == "soleil":
        door.cyl((x - w * 0.18, y + h * 0.18, z - 0.001), 0.018, 0.002, yellow, axis=(0, 0, 1))
        door.box(x - w * 0.4, y - h * 0.4, -1.3968, x + w * 0.4, y - h * 0.25, z, leaf)
        door.box(x, y - h * 0.25, -1.3968, x + w * 0.22, y + h * 0.02, z, red)
    elif doodle == "coeur":
        for dx in (-0.012, 0.012):
            door.cyl((x + dx, y + 0.008, z - 0.001), 0.016, 0.002, red, axis=(0, 0, 1))
        door.box(x - 0.016, y - 0.022, -1.3968, x + 0.016, y + 0.004, z, red,
                 matrix=Matrix.Translation((x, y - 0.006, 0)) @ Matrix.Rotation(math.pi / 4, 4, "Z") @ Matrix.Translation((-x, -(y - 0.006), 0)))
    elif doodle == "chien":
        door.ball((x, y - 0.01, z - 0.004), (0.035, 0.03, 0.004), black)
        for dx in (-0.032, 0.032):
            door.ball((x + dx, y + 0.002, z - 0.004), (0.014, 0.028, 0.004), black)
    door.cyl((x, y + h / 2 - 0.012, -1.397), 0.011, 0.008, paper[rng.randrange(1, 8)], axis=(0, 0, 1), seg=10)


note(-1.27, 1.64, 0.22, 0.15, paper[0], "lignes", 0.03)
note(-1.0, 1.62, 0.17, 0.13, paper[3], "soleil", -0.06)
note(-0.83, 1.55, 0.11, 0.12, paper[1], None, 0.1)
note(-1.29, 1.43, 0.16, 0.2, paper[2], "chien", -0.04)
note(-1.05, 1.42, 0.24, 0.11, paper[0], "soleil", 0.02)
note(-0.87, 1.32, 0.13, 0.16, paper[4], "coeur", -0.08)
note(-1.22, 1.17, 0.2, 0.22, paper[0], "lignes", 0.05)
note(-0.97, 1.19, 0.12, 0.1, paper[5], "coeur", 0.09)
note(-0.9, 0.97, 0.2, 0.23, paper[0], "lignes", -0.03)
note(-1.14, 0.87, 0.18, 0.11, paper[7], None, 0.02)
note(-1.31, 0.9, 0.1, 0.14, paper[6], "soleil", 0.06)
door.build()

# ---------------------------------------------------------------- mur est

east = C.Obj("MurEst")
east.box(1.5, 0.0, -1.48, 2.0, 0.1, 0.72, black_mat)
east.box(1.42, 0.1, -1.48, 2.0, 0.7, 0.10, maple_panel)
cabinet_front(east, "x", 1.42, -1.48, -1.06, 0.62, 0.88)
cabinet_front(east, "x", 1.42, -1.48, -1.06, 0.36, 0.62)
cabinet_front(east, "x", 1.42, -1.48, -1.06, 0.1, 0.36)
cabinet_front(east, "x", 1.42, -1.06, -0.55, 0.1, 0.88, "right")
cabinet_front(east, "x", 1.42, -0.55, 0.10, 0.1, 0.88, "left")
# comptoir percé pour l'évier
sz0, sz1 = PLAN["sink"]
sx0, sx1 = 1.50, 1.86
east.box(1.38, 0.88, -1.48, 2.0, H, sz0, counter, bevel=0.008, seg=1)
east.box(1.38, 0.88, sz1, 2.0, H, 0.80, counter, bevel=0.008, seg=1)
east.box(1.38, 0.88, sz0, sx0, H, sz1, counter, bevel=0.008, seg=1)
east.box(sx1, 0.88, sz0, 2.0, H, sz1, counter)
east.box(1.42, 0.7, -1.06, 1.49, 0.88, 0.10, maple_panel)
mid = (sz0 + sz1) / 2
for a, b in ((sz0, mid - 0.012), (mid + 0.012, sz1)):
    east.box(sx0, 0.73, a, sx1, 0.745, b, steel_dark)
    east.box(sx0, 0.73, a, sx0 + 0.012, H, b, steel)
    east.box(sx1 - 0.012, 0.73, a, sx1, H, b, steel)
    east.box(sx0, 0.73, a, sx1, H, a + 0.012, steel)
    east.box(sx0, 0.73, b - 0.012, sx1, H, b, steel)
    east.cyl(((sx0 + sx1) / 2, 0.745, (a + b) / 2), 0.03, 0.004, chrome)
for a, b, c, d in ((sx0 - 0.02, sx1 + 0.02, sz0 - 0.02, sz0), (sx0 - 0.02, sx1 + 0.02, sz1, sz1 + 0.02),
                   (sx0 - 0.02, sx0, sz0, sz1), (sx1, sx1 + 0.02, sz0, sz1), (sx0, sx1, mid - 0.012, mid + 0.012)):
    east.box(a, H, c, b, H + 0.006, d, steel)
# robinet noir
east.cyl((1.93, H, mid), 0.03, 0.05, black)
east.tube([(1.93, H, mid), (1.93, 1.2, mid), (1.90, 1.26, mid), (1.83, 1.275, mid), (1.76, 1.25, mid),
           (1.73, 1.19, mid)], 0.016, black, seg=10)
east.tube([(1.93, 0.99, mid), (1.93, 1.0, mid + 0.09)], 0.009, black, seg=8)
# lave-vaisselle et panneau de bout
dz0, dz1 = PLAN["dishwasher"]
east.box(1.41, 0.09, dz0, 2.0, 0.88, dz1, steel, bevel=0.01, seg=1)
east.box(1.402, 0.79, dz0 + 0.02, 1.412, 0.86, dz1 - 0.02, steel_dark)
east.tube([(1.375, 0.755, dz0 + 0.06), (1.375, 0.755, dz1 - 0.06)], 0.012, chrome, seg=8)
for hz in (dz0 + 0.08, dz1 - 0.08):
    east.box(1.375, 0.745, hz - 0.01, 1.41, 0.765, hz + 0.01, chrome)
east.box(1.41, 0.0, 0.72, 2.0, 0.88, 0.80, maple_panel)
# armoires du haut
ux = 1.66
east.box(ux, 1.42, -1.74, 2.0, 2.27, -1.16, maple_panel)
cabinet_front(east, "x", ux, -1.74, -1.45, 1.42, 2.27, "right")
cabinet_front(east, "x", ux, -1.45, -1.16, 1.42, 2.27, "left")
east.box(ux, 1.42, 0.16, 2.0, 2.27, 0.76, maple_panel)
cabinet_front(east, "x", ux, 0.16, 0.76, 1.42, 2.27, "left")
# fenêtre
east.box(2.09, wy0 - 0.02, wz0 - 0.02, 2.1, wy1 + 0.02, wz1 + 0.02, sky)
east.box(2.085, wy0, wz0, 2.09, wy0 + 0.3, wz1, yard)
for k in range(9):
    east.ball((2.08, wy0 + rng.uniform(0.24, 0.42), rng.uniform(wz0 + 0.05, wz1 - 0.05)), (0.01, 0.1, 0.11), leaf_d,
              seg=10, rings=6)
for a, b, c, d in ((wy0, wy0 + 0.05, wz0, wz1), (wy1 - 0.05, wy1, wz0, wz1), (wy0, wy1, wz0, wz0 + 0.05),
                   (wy0, wy1, wz1 - 0.05, wz1), (1.57, 1.61, wz0, wz1), (wy0, wy1, mid - 0.0, mid + 0.025)):
    east.box(1.975, a, c, 2.03, b, d, white, bevel=0.005, seg=1)
east.box(1.9, wy0 - 0.025, wz0 - 0.04, 2.0, wy0, wz1 + 0.04, white, bevel=0.006, seg=1)
plant(east, (1.92, wy0, -0.88), 0.055, 0.28, 34)
plant(east, (1.92, wy0, -0.62), 0.04, 0.18, 16, pot_white)
for k in range(5):
    a = -0.16 + k * 0.012
    east.tube([(1.93, wy0 + 0.08, a), (1.93 + rng.uniform(-0.02, 0.02), wy0 + 0.42 - abs(k - 2) * 0.04, a + (k - 2) * 0.02)],
              [0.018, 0.004], leaf if k % 2 else leaf_d, seg=8, squash=(0.35, 1.0))
east.cyl((1.93, wy0, -0.14), 0.045, 0.09, black_mat)
east.box(1.91, wy0, -0.42, 1.96, wy0 + 0.04, -0.34, pot_white, bevel=0.012)
# vaisselle près de l'évier et au bord du mur
east.cyl((1.82, H, -1.20), 0.09, 0.07, pot_white, top=0.12)
east.cyl((1.86, H + 0.07, -1.2), 0.06, 0.04, M("plat_bleu", "#4fb3c4", 0.5), top=0.075)
east.cyl((1.80, H, -1.40), 0.05, 0.06, M("tasse_rose", "#d94f8a", 0.4))
east.cyl((1.88, H, 0.12), 0.034, 0.18, dark_glass_bottle)
east.cyl((1.88, H + 0.18, 0.12), 0.012, 0.05, black)
east.cyl((1.89, H, 0.30), 0.05, 0.13, pot_white, seg=16)
for k in range(6):
    a = rng.uniform(-0.035, 0.035)
    b = rng.uniform(-0.035, 0.035)
    east.tube([(1.89, H + 0.06, 0.30), (1.89 + a * 1.8, H + 0.27, 0.30 + b * 1.8)], 0.007,
              [maple, black, steel, red][k % 4], seg=7)
east.cyl((1.9, H, 0.66), 0.045, 0.09, black_mat)
# porte blanche, imposte et climatiseur
dz0, dz1 = PLAN["door"]["z0"], PLAN["door"]["z1"]
east.box(1.985, 0, dz0 - 0.08, 2.0, 2.54, dz0, white, bevel=0.005, seg=1)
east.box(1.985, 0, dz1, 2.0, 2.54, dz1 + 0.08, white, bevel=0.005, seg=1)
east.box(1.975, 2.08, dz0 - 0.08, 2.0, 2.16, dz1 + 0.08, white, bevel=0.005, seg=1)
east.box(1.975, 2.48, dz0 - 0.08, 2.0, 2.56, dz1 + 0.08, white, bevel=0.005, seg=1)
east.box(1.992, 2.16, dz0, 2.0, 2.48, dz1, M("imposte", "#33404f", 0.1, 0.3))
east.box(1.955, 0.01, dz0 + 0.01, 2.0, 2.07, dz1 - 0.01, white, bevel=0.006, seg=1)
gz0, gz1 = dz0 + 0.14, dz1 - 0.14
east.box(1.945, 0.84, gz0 - 0.05, 1.956, 1.97, gz1 + 0.05, white, bevel=0.006, seg=1)
east.box(1.940, 0.89, gz0, 1.946, 1.92, gz1, blind)
y = 0.9
while y < 1.9:
    east.box(1.936, y, gz0, 1.941, y + 0.004, gz1, steel_dark)
    y += 0.036
# panneau mouluré au bas de la porte
for t in (0.18, 0.7):
    east.box(1.944, t, gz0, 1.956, t + 0.025, gz1, white_soft, bevel=0.004, seg=1)
for t in (gz0, gz1 - 0.025):
    east.box(1.944, 0.18, t, 1.956, 0.7, t + 0.025, white_soft, bevel=0.004, seg=1)
east.cyl((1.95, 1.02, dz0 + 0.07), 0.028, 0.025, steel_dark, axis=(-1, 0, 0))
east.tube([(1.915, 1.02, dz0 + 0.07), (1.915, 1.02, dz0 + 0.18)], 0.012, steel_dark, seg=8)
east.cyl((1.95, 1.18, dz0 + 0.07), 0.025, 0.018, brass, axis=(-1, 0, 0))
east.box(1.8, 2.5, 0.98, 2.0, 2.76, 1.80, white, bevel=0.05, seg=3)
east.box(1.795, 2.53, 1.03, 1.81, 2.56, 1.75, steel_dark)
east.build()

# ---------------------------------------------------------------- mur ouest : buffet et armoire vitrée

west = C.Obj("MurOuest")
x0, z0, x1, z1 = OB["buffet"]
west.box(x0, 0.1, z0, x1 - 0.02, 0.86, z1, white_soft, bevel=0.006, seg=1)
west.box(x0, 0.86, z0 - 0.02, x1, 0.9, z1 + 0.02, buffet_top, bevel=0.008, seg=1)
for lz in (z0 + 0.04, (z0 + z1) / 2, z1 - 0.04):
    west.box(x1 - 0.1, 0, lz - 0.02, x1 - 0.06, 0.1, lz + 0.02, buffet_top)
dw = (z1 - z0) / 4
for k in range(4):
    a = z0 + k * dw
    west.box(x1 - 0.022, 0.12, a + 0.008, x1 - 0.006, 0.84, a + dw - 0.008, white, bevel=0.004, seg=1)
    u = a + dw - 0.06 if k % 2 == 0 else a + 0.06
    west.box(x1 - 0.006, 0.55, u - 0.014, x1 + 0.016, 0.68, u + 0.014, maple, bevel=0.006, seg=1)
# sur le buffet, loin de l'endroit à nourriture
west.box(-1.94, 0.9, -0.48, -1.66, 1.22, -0.2, black, bevel=0.07, seg=3)
west.box(-1.66, 0.98, -0.40, -1.645, 1.05, -0.28, black_glass)
west.box(-1.95, 0.9, 0.46, -1.72, 1.12, 0.72, black_mat, bevel=0.03)
west.box(-1.88, 0.9, 0.80, -1.68, 1.0, 0.94, M("mouchoirs", "#3d5a86", 0.8), bevel=0.014)
west.ball((-1.78, 1.03, 0.87), (0.05, 0.035, 0.03), white)
plant(west, (-1.8, 0.9, 1.15), 0.085, 0.4, 44, pot_white, 3)
# armoire murale à portes dépolies
cz0, cz1 = -0.35, 0.95
west.box(-2.0, 1.40, cz0, -1.70, 2.10, cz1, white_soft)
for y0, y1 in ((1.40, 1.74), (1.76, 2.10)):
    west.box(-1.70, y0, cz0, -1.675, y1, cz1, frost)
    for a, b, c, d in ((y0, y0 + 0.04, cz0, cz1), (y1 - 0.04, y1, cz0, cz1), (y0, y1, cz0, cz0 + 0.04),
                       (y0, y1, cz1 - 0.04, cz1)):
        west.box(-1.702, a, c, -1.665, b, d, maple, bevel=0.005, seg=1)
    west.box(-1.665, y0 + 0.055, (cz0 + cz1) / 2 - 0.05, -1.645, y0 + 0.075, (cz0 + cz1) / 2 + 0.05, steel)
plant(west, (-1.84, 2.10, -0.2), 0.08, 0.2, 26, pot_clay, 5)
west.cyl((-1.82, 2.10, 0.5), 0.05, 0.24, dark_glass_bottle)
west.box(-1.9, 2.10, 0.66, -1.74, 2.34, 0.78, M("boite_menthe", "#69c3a8", 0.6), bevel=0.02)
plant(west, (-1.82, 1.52 + 0.78, -1.2 + 0.0), 0.06, 0.1, 14, pot_white, 4)
west.build()

# ---------------------------------------------------------------- îlot et tabouret

island = C.Obj("Ilot")
x0, z0, x1, z1 = OB["island"]
island.box(x0 - 0.025, H - 0.045, z0 - 0.025, x1 + 0.025, H, z1 + 0.025, butcher, bevel=0.012, seg=2)
open_from = 0.22
for lx in (x0 + 0.02, x1 - 0.06):
    for lz in (z0 + 0.02, open_from - 0.02, z1 - 0.06):
        if lx < x0 + 0.1 and lz == open_from - 0.02:
            continue
        island.box(lx, 0, lz, lx + 0.045, H - 0.045, lz + 0.045, white, bevel=0.006, seg=1)
island.box(x0 + 0.13, 0.09, z0 + 0.04, x1 - 0.03, H - 0.05, open_from, white, bevel=0.006, seg=1)
for lz in (z0 + 0.02, z1 - 0.06):
    island.box(x0 + 0.06, 0.1, lz + 0.012, x1 - 0.06, 0.13, lz + 0.034, white)
island.box(x0 + 0.04, 0.80, z0 + 0.05, x0 + 0.062, H - 0.045, z1 - 0.05, white)
island.box(x0 + 0.04, 0.80, z1 - 0.045, x1 - 0.05, H - 0.045, z1 - 0.025, white)
for sy in (0.20, 0.56):
    island.box(x0 + 0.05, sy, open_from, x1 - 0.03, sy + 0.025, z1 - 0.03, white, bevel=0.004, seg=1)
# panier et poubelle sur les tablettes
basket = M("panier", "#d8d3c8", 0.95)
island.box(-0.22, 0.585, 0.26, 0.2, 0.74, 0.50, basket, bevel=0.04, seg=3)
island.box(-0.16, 0.72, 0.30, 0.12, 0.77, 0.46, towel, bevel=0.02)
island.box(-0.12, 0.225, 0.28, 0.14, 0.50, 0.50, white_soft, bevel=0.03)
island.box(-0.13, 0.50, 0.27, 0.15, 0.525, 0.51, black, bevel=0.01)
# sur l'îlot, côté nord, loin des endroits à nourriture
for k, (r, m) in enumerate(((0.105, green_v), (0.108, M("vert_pale", "#c4dc98", 0.7)))):
    island.ball((0.02, H + 0.09 - k * 0.004, -0.38), (r * (1 - k * 0.02), r * 0.88, r), m,
                matrix=Matrix.Rotation(k * 0.9, 3, "Y"))
for a in range(5):
    island.torus((0.02, H + 0.09, -0.38), 0.104, 0.004, M("nervure", "#e6f0c8", 0.7),
                 axis=(math.cos(a * 1.25), 0.15, math.sin(a * 1.25)), arc=(0.2, 2.6), sides=5, seg=14)
island.box(-0.24, H, -0.74, 0.02, H + 0.09, -0.58, bread, bevel=0.04, seg=3)
island.box(-0.18, H + 0.091, -0.70, -0.04, H + 0.093, -0.62, paper[0])
for dx, hh in ((0.0, 0.14), (0.08, 0.12)):
    island.cyl((0.08 + dx, H, -0.16), 0.032, hh, dark_glass_bottle, seg=16)
    island.cyl((0.08 + dx, H + hh, -0.16), 0.02, 0.025, M("bouchon", "#2f7d5c", 0.5), seg=14)
    island.cyl((0.08 + dx, H + 0.035, -0.16), 0.0335, 0.06, paper[0], seg=16)
island.cyl((-0.18, H, -0.18), 0.05, 0.1, glass, top=0.056)
island.build()

sx, sz, sr = PLAN["stool"]["x"], PLAN["stool"]["z"], PLAN["stool"]["r"]
stool = C.Obj("Tabouret", origin=(sx, 0, sz))
seat = M("siege", "#44464e", 0.55)
wood_leg = M("patte", "#b98d58", 0.6)
stool.box(sx - 0.18, 0.62, sz - 0.19, sx + 0.17, 0.67, sz + 0.19, seat, bevel=0.024, seg=3)
for k in range(7):
    a = -0.19 + k * 0.38 / 6
    curve = 0.05 * (abs(k - 3) / 3) ** 2
    stool.box(sx - 0.215 + curve, 0.65, sz + a - 0.034, sx - 0.17 + curve, 0.94 - curve * 0.8, sz + a + 0.034, seat,
              bevel=0.02, seg=2)
for dx in (-1, 1):
    for dz in (-1, 1):
        stool.tube([(sx + dx * 0.09, 0.62, sz + dz * 0.1), (sx + dx * 0.17, 0.0, sz + dz * 0.17)], [0.022, 0.016],
                   wood_leg, seg=10)
        stool.tube([(sx + dx * 0.09, 0.61, sz + dz * 0.1), (sx - dx * 0.11, 0.42, sz + dz * 0.12)], 0.006, black, seg=6)
stool.torus((sx, 0.24, sz), 0.19, 0.012, black)
stool.build()

# ---------------------------------------------------------------- le coin de Blanche

corner = C.Obj("Coin")
x0, z0, x1, z1 = PLAN["cushion"]
corner.box(x0, 0.0, z0, x1, 0.055, z1, cushion_m, bevel=0.027, seg=3)
for a, b, c, d in ((x0 + 0.02, x1 - 0.02, z0 + 0.02, z0 + 0.03), (x0 + 0.02, x1 - 0.02, z1 - 0.03, z1 - 0.02),
                   (x0 + 0.02, x0 + 0.03, z0 + 0.02, z1 - 0.02), (x1 - 0.03, x1 - 0.02, z0 + 0.02, z1 - 0.02)):
    corner.box(a, 0.04, c, b, 0.062, d, M("passepoil", "#60646d", 0.9), bevel=0.008, seg=1)
# balle jaune et jouet à deux anneaux
corner.ball((x0 + 0.1, 0.097, z0 + 0.14), 0.043, yellow)
corner.torus((x0 + 0.1, 0.097, z0 + 0.14), 0.043, 0.0035, white, axis=(0.6, 0.5, 0.6), sides=5)
cx, cz = x0 + 0.17, z1 - 0.15
corner.torus((cx - 0.065, 0.07, cz - 0.02), 0.058, 0.013, red)
corner.torus((cx + 0.07, 0.07, cz + 0.025), 0.058, 0.013, red)
corner.ball((cx, 0.088, cz), 0.034, black)
corner.torus((cx, 0.088, cz), 0.034, 0.008, black_mat, axis=(1, 0.3, 0.3))
# support à bols
bx0, bz0, bx1, bz1 = OB["bowls"]
corner.box(bx0, 0.15, bz0, bx1, 0.19, bz1, grey_wood, bevel=0.008, seg=1)
for lx in (bx0 + 0.02, bx1 - 0.055):
    corner.box(lx, 0.0, bz0 + 0.02, lx + 0.035, 0.15, bz1 - 0.02, grey_wood, bevel=0.006, seg=1)
mid = (bz0 + bz1) / 2
for k, bz in enumerate((mid - 0.065, mid + 0.065)):
    bx = (bx0 + bx1) / 2
    corner.cyl((bx, 0.188, bz), 0.052, 0.025, steel, top=0.064, seg=24)
    corner.torus((bx, 0.214, bz), 0.062, 0.005, chrome, sides=6)
    corner.cyl((bx, 0.2135, bz), 0.056, 0.001, M("eau", "#9fc6d8", 0.05, 0.3) if k == 0 else steel_dark, seg=24)
corner.build()

C.export("cuisine")
cam = PLAN["camera"]
C.render("cuisine", cam["pos"], cam["target"], cam["fov"])
C.render("cuisine_coin", (0.1, 1.5, 2.9), (1.4, 0.3, 1.4), 45)
