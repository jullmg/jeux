"""La chambre de Charlotte, le soir de la soirée pyjama, d'après les photos de Julien (reference/, jamais copiées :
aucune image, aucun visage, aucune inscription n'en est tirée). Les meubles qui comptent pour le jeu viennent du plan
data/pieces/chambre.json.

Le lit de métal blanc et sa douillette rose contre le mur ouest, le rideau de lumières devant la fenêtre du nord, le
cœur néon rose, l'affiche aux fraises, les étagères à livres, le fauteuil papillon en fourrure, le bureau blanc et sa
chaise rouge à trous, la commode blanche avec la cage de verre du hamster ; ce soir, les sacs de couchage des filles,
le plateau des collations et la tablette du film.

Blender --background --python tools/blender/chambre.py
"""
import json
import math
import pathlib
import random
import sys

sys.path.insert(0, str(pathlib.Path(__file__).parent))
import common as C  # noqa: E402
import decor as D  # noqa: E402
import textures as T  # noqa: E402
from mathutils import Matrix, Vector  # noqa: E402

C.reset()
PLAN = json.loads((C.ROOT / "data" / "pieces" / "chambre.json").read_text())
rng = random.Random(15)
M = C.material

R = PLAN["room"]
X0, X1, ZN, ZS = R["x0"], R["x1"], R["z0"], R["z1"]
CEIL = 2.65
WALL = 0.12
WINDOW = (-0.25, 0.75, 0.82, 2.18)          # la fenêtre du nord : x0, x1, bas, haut
DOOR = (-0.95, -0.15)                       # la porte du corridor, mur est (z0, z1)


def rect(a):
    return a[0], a[1], a[2], a[3]


def mat(name, maps, **kw):
    return M(name, **maps, **kw)


# ---------------------------------------------------------------- matières

floor_m = mat("plancher_chambre", T.floor(rng, "plancher_chambre", ["#c98e55", "#c0844c", "#d0975e", "#bd7f47",
                                                                     "#c78b52", "#d39b62", "#c4884f", "#ca9058"],
                                          along_z=True))
wall_m = mat("mur_chambre", T.plaster("mur_chambre", "#f1e4de"))
trim = M("boiserie_blanche", "#f5f1ea", 0.5)
base_wood = mat("plinthe_chambre", T.wood("plinthe_chambre", "#8a5a36", "#55331d", False, 0.6, 0.4, 0.8))
oak = mat("chene_porte", T.wood("chene_porte", "#a36b38", "#6a3f1d", True, 0.7, 0.32, 0.85))
white_metal = M("metal_blanc", "#f3f0ea", 0.35, 0.35)
white_wood = M("bois_blanc", "#f4f1ec", 0.45)
knob_m = M("bouton_commode", "#d9c9a8", 0.3, 0.5)
duvet = mat("douillette_rose", T.fabric("douillette_rose", "#f2b6c2", 0.3, 9))
duvet_d = mat("douillette_rose_pli", T.fabric("douillette_rose_pli", "#e79eae", 0.3, 9))
sheet = mat("drap_blanc", T.fabric("drap_blanc", "#f7f3ee", 0.25, 8))
pillow_m = mat("oreiller_rose", T.fabric("oreiller_rose", "#f6c6cf", 0.2, 7))
fluffy = M("peluche_fleur", "#f7a8c0", 0.95)
fluffy_c = M("peluche_coeur", "#fff3f6", 0.9)
straw = M("peluche_fraise", "#e2394f", 0.85)
straw_seed = M("graine_fraise", "#fff0b0", 0.7)
leafy = M("feuille_peluche", "#4f9a48", 0.9)
fur_m = M("fourrure_fauteuil", "#f6f3ee", 0.96, **T.fur())
iron = M("fer_noir", "#1d1c20", 0.42, 0.55)
red_chair = M("chaise_rouge", "#c9334a", 0.4)
hole_m = M("trou_chaise", "#5a1420", 0.7)
glass = M("verre_cage", "#dde9ee", 0.04, alpha=0.2)
shavings = mat("copeaux", T.food("copeaux", "#e8cf9c", [("#d2b27a", 0.55, 0.8)], [("#f7e7c3", 0.05)], 0.9,
                                 relief=2.4, cells=70))
hamster_m = M("hamster", "#d8a061", 0.9)
hamster_w = M("hamster_ventre", "#f6ead8", 0.9)
candle_jar = M("pot_bougie", "#f2dfc6", 0.1, alpha=0.55)
wax = M("cire", "#f7efe2", 0.6)
flame = M("flamme_bougie", "#ffd27a", 0.3, emit="#ffb648", emit_power=6.0)
gum_red = M("machine_gomme", "#d8323f", 0.3, 0.3)
gum_balls = [M(f"gomme_{i}", c, 0.25) for i, c in enumerate(("#f25c7a", "#f6d14b", "#5bc0eb", "#7bd389", "#ffffff"))]
neon = M("neon_coeur", "#ff5a86", 0.3, emit="#ff4f82", emit_power=7.0)
led = M("ampoule_del", "#fff2cf", 0.3, emit="#ffe3a6", emit_power=9.0)
wire = M("fil_del", "#c9c2b5", 0.6)
sheer = M("voilage", "#fbf6ef", 0.9, alpha=0.55)
book_colors = ["#e85a6b", "#5b8fd6", "#f2c14e", "#7cc08a", "#b07cd8", "#f08a4b", "#4fb3b3", "#e7e1d2"]
books = [M(f"livre_{i}", c, 0.6) for i, c in enumerate(book_colors)]
paper = M("papier_livre", "#f6f1e4", 0.8)
notebook = M("cahier_mauve", "#5e4b7e", 0.6)
cup_blue = M("verre_bleu", "#8fb9e2", 0.25, alpha=0.85)
bag_pink = mat("sac_rose", T.fabric("sac_rose", "#d77fb0", 0.3, 8))
bag_mint = mat("sac_menthe", T.fabric("sac_menthe", "#7cc7b8", 0.3, 8))
bag_lining = M("doublure_sac", "#f5efe6", 0.8)
dog_bed = mat("coussin_blanche", T.fabric("coussin_blanche", "#a9a3b8", 0.25, 7))
dog_bed_rim = mat("bord_coussin", T.fabric("bord_coussin", "#e3a3bb", 0.25, 7))
tray_m = M("plateau_blanc", "#f2ede6", 0.4)
tablet_m = M("tablette", "#2a2b30", 0.3, 0.4)
napkin = M("serviette_papier", "#fbe1ea", 0.8)
rug_m = mat("tapis_moelleux", T.fabric("tapis_moelleux", "#efe7ea", 0.2, 6, 1.0))
plaster = M("platre", "#f5f1ea", 0.55)


# ---------------------------------------------------------------- murs, plancher, fenêtre, porte

def baseboard(o, axis, at, a0, a1, inward):
    lo, hi = sorted((at, at + inward * 0.018))
    if axis == "x":
        o.box(a0, 0, lo, a1, 0.13, hi, base_wood, bevel=0.004, seg=1)
    else:
        o.box(lo, 0, a0, hi, 0.13, a1, base_wood, bevel=0.004, seg=1)


def crown(o, axis, at, a0, a1, inward):
    for k, (y0, depth) in enumerate(((CEIL - 0.05, 0.03), (CEIL - 0.09, 0.05), (CEIL - 0.12, 0.018))):
        lo, hi = sorted((at, at + inward * depth))
        if axis == "x":
            o.box(a0, y0, lo, a1, y0 + 0.035 + k * 0.01, hi, plaster, bevel=0.006, seg=1)
        else:
            o.box(lo, y0, a0, hi, y0 + 0.035 + k * 0.01, a1, plaster, bevel=0.006, seg=1)


def wall_x(o, z, x0, x1, material, holes=()):
    z0, z1 = sorted((z, z + (WALL if z > 0 else -WALL)))
    x = x0
    for hx0, hx1, hy0, hy1 in sorted(holes):
        o.box(x, 0, z0, hx0, CEIL, z1, material)
        o.box(hx0, 0, z0, hx1, hy0, z1, material)
        o.box(hx0, hy1, z0, hx1, CEIL, z1, material)
        x = hx1
    o.box(x, 0, z0, x1, CEIL, z1, material)


def wall_z(o, x, z0, z1, material, holes=()):
    xa, xb = sorted((x, x + (WALL if x > 0 else -WALL)))
    z = z0
    for hz0, hz1, hy0, hy1 in sorted(holes):
        o.box(xa, 0, z, xb, CEIL, hz0, material)
        o.box(xa, 0, hz0, xb, hy0, hz1, material)
        o.box(xa, hy1, hz0, xb, CEIL, hz1, material)
        z = hz1
    o.box(xa, 0, z, xb, CEIL, z1, material)


floor_ob = C.Obj("Plancher")
# jusque sous le mur est, là où commence le plancher du corridor (sans chevauchement : il clignoterait)
floor_ob.box(X0 - WALL - 0.2, -0.06, ZN - 0.2, X1 + WALL, 0.0, ZS + 0.6, floor_m)
floor_ob.build()

north = C.Obj("MurNord")
wx0, wx1, wy0, wy1 = WINDOW
wall_x(north, ZN, X0 - WALL, X1 + WALL, wall_m, [(wx0, wx1, wy0, wy1)])
baseboard(north, "x", ZN, X0, X1, 1)
crown(north, "x", ZN, X0, X1, 1)
for a, b, c, d in ((wx0 - 0.07, wx0, wy0 - 0.04, wy1 + 0.07), (wx1, wx1 + 0.07, wy0 - 0.04, wy1 + 0.07),
                   (wx0 - 0.07, wx1 + 0.07, wy1, wy1 + 0.08)):
    north.box(a, c, ZN - 0.01, b, d, ZN + 0.02, trim, bevel=0.006, seg=1)
north.box(wx0 - 0.09, wy0 - 0.05, ZN - 0.02, wx1 + 0.09, wy0, ZN + 0.05, trim, bevel=0.008, seg=1)
mid_y = (wy0 + wy1) / 2
for zz, (y0, y1) in ((ZN - 0.03, (wy0, mid_y + 0.03)), (ZN - 0.06, (mid_y - 0.03, wy1))):
    for a, b, c, d in ((wx0, wx1, y0, y0 + 0.05), (wx0, wx1, y1 - 0.05, y1), (wx0, wx0 + 0.05, y0, y1),
                       (wx1 - 0.05, wx1, y0, y1)):
        north.box(a, c, zz - 0.03, b, d, zz, trim, bevel=0.004, seg=1)
north.box(wx0 + 0.05, wy0 + 0.05, ZN - 0.075, wx1 - 0.05, wy1 - 0.05, ZN - 0.071, M("vitre", "#cfe0ee", 0.05, alpha=0.2))
# le voilage blanc et le rideau de lumières : des fils qui tombent de la tringle, une petite ampoule à tous les 8 cm
north.tube([(wx0 - 0.25, wy1 + 0.18, ZN + 0.06), (wx1 + 0.25, wy1 + 0.18, ZN + 0.06)], 0.009, white_metal, seg=8)
folds = 12
for k in range(folds):
    x = wx0 - 0.2 + k * (wx1 - wx0 + 0.4) / (folds - 1)
    north.tube([(x, wy1 + 0.17, ZN + 0.06 + 0.008 * (k % 2)), (x + 0.01, 1.2, ZN + 0.07 + 0.01 * (k % 2)),
                (x - 0.01, 0.06, ZN + 0.075)], [0.03, 0.034, 0.036], sheer, seg=8, squash=(0.5, 1.0), cap_rings=2)
strands = 9
for k in range(strands):
    x = wx0 - 0.12 + k * (wx1 - wx0 + 0.24) / (strands - 1)
    top, bottom = wy1 + 0.16, 0.45 + 0.08 * math.sin(k * 1.9)
    north.tube([(x, top, ZN + 0.11), (x + 0.012 * math.sin(k), (top + bottom) / 2, ZN + 0.115), (x, bottom, ZN + 0.11)],
               0.0018, wire, seg=4, cap_rings=1)
    y = top - 0.05 - (k % 3) * 0.025
    while y > bottom:
        north.ball((x + 0.01 * math.sin(y * 9 + k), y, ZN + 0.112), 0.0085, led, seg=6, rings=4)
        y -= 0.075
north.build()
D.wall_picture("VueChambre", T.picture("vue_chambre", "lune", 384, 384), ((wx0 + wx1) / 2, mid_y, ZN - 0.6),
               (wx1 - wx0 + 1.0, wy1 - wy0 + 1.0), "+z", None, emit=1.0)

west = C.Obj("MurOuest")
wall_z(west, X0, ZN - WALL, ZS, wall_m)
baseboard(west, "z", X0, ZN, ZS, 1)
crown(west, "z", X0, ZN, ZS, 1)
# le cœur néon rose sur son fil, près de la tête du lit
heart = []
for i in range(41):
    t = i / 40 * math.tau
    hx = 16 * math.sin(t) ** 3
    hy = 13 * math.cos(t) - 5 * math.cos(2 * t) - 2 * math.cos(3 * t) - math.cos(4 * t)
    heart.append((X0 + 0.03, 1.5 + hy * 0.0085, -1.18 + hx * 0.0085))
west.tube(heart, 0.0085, neon, seg=8, caps=False)
west.box(X0, 1.33, -1.24, X0 + 0.012, 1.68, -1.12, M("plaque_neon", "#e8e2dc", 0.2, alpha=0.35))
west.tube([(X0 + 0.02, 1.34, -1.18), (X0 + 0.02, 0.9, -1.25), (X0 + 0.02, 0.32, -1.3)], 0.003, wire, seg=4)
# le tableau fleuri au-dessus de la commode
cx0, cz0, cx1, cz1 = rect(PLAN["obstacles"]["commode"])
D.frame(west, (X0 + 0.004, 1.55, (cz0 + cz1) / 2), (0.46, 0.56), "+x", trim)
west_ob = west.build()
D.wall_picture("tableau_fleurs", T.picture("tableau_fleurs", "fleurs", 256, 320), (X0 + 0.012, 1.55, (cz0 + cz1) / 2),
               (0.46, 0.56), "+x", west_ob)

east = C.Obj("MurEst")
wall_z(east, X1, ZN - WALL, ZS, wall_m, [(DOOR[0], DOOR[1], 0.0, 2.08)])
baseboard(east, "z", X1, ZN, DOOR[0] - 0.07, -1)
baseboard(east, "z", X1, DOOR[1] + 0.07, ZS, -1)
crown(east, "z", X1, ZN, ZS, -1)
for a, b, c, d in ((DOOR[0] - 0.08, DOOR[0], 0, 2.16), (DOOR[1], DOOR[1] + 0.08, 0, 2.16),
                   (DOOR[0] - 0.08, DOOR[1] + 0.08, 2.08, 2.16)):
    east.box(X1 - 0.025, c, a, X1 + WALL + 0.01, d, b, oak, bevel=0.006, seg=1)
# la porte de chêne, grande ouverte sur le corridor, avec la pancarte colorée de Charlotte (sans mots)
hinge = Vector((X1 + 0.04, 0, DOOR[0]))
leaf_rot = Matrix.Translation(hinge) @ Matrix.Rotation(math.radians(70), 4, "Y") @ Matrix.Translation(-hinge)
east.box(X1 + 0.02, 0.01, DOOR[0], X1 + 0.06, 2.06, DOOR[1], oak, bevel=0.01, seg=1, matrix=leaf_rot)
for y0, y1 in ((0.15, 0.95), (1.08, 1.95)):
    east.box(X1 + 0.004, y0, DOOR[0] + 0.1, X1 + 0.02, y1, DOOR[1] - 0.1, oak, bevel=0.008, seg=1, matrix=leaf_rot)
for k, tone in enumerate(("#e85a6b", "#f2c14e", "#7cc08a", "#5b8fd6", "#b07cd8")):
    east.box(X1 + 0.0, 1.5 - k * 0.022, DOOR[0] + 0.22, X1 + 0.004, 1.52 - k * 0.022, DOOR[1] - 0.22,
             M(f"pancarte_{k}", tone, 0.7), matrix=leaf_rot)
east.ball(tuple(leaf_rot @ Vector((X1 - 0.01, 1.0, DOOR[1] - 0.07))), 0.025, M("poignee_verre", "#e9f2f5", 0.05, alpha=0.6),
          seg=12, rings=8)
# l'affiche aux fraises entre le coin et la porte
D.frame(east, (X1 - 0.004, 1.62, -1.38), (0.42, 0.56), "-x", M("cadre_rose", "#f0c6d6", 0.4))
east_ob = east.build()
D.wall_picture("affiche_fraises", T.picture("affiche_fraises", "fraises", 256, 340), (X1 - 0.012, 1.62, -1.38),
               (0.42, 0.56), "-x", east_ob)

# le corridor, qu'on devine par la porte : son plancher, son mur, une veilleuse
hall = C.Obj("Corridor")
hall.box(X1 + WALL, -0.06, ZN - 0.2, X1 + 1.8, 0.0, ZS, floor_m)
hall.box(X1 + 1.8, 0, ZN, X1 + 1.92, CEIL, ZS, wall_m)
hall.box(X1 + 1.79, 0.25, -0.62, X1 + 1.8, 0.33, -0.5, M("veilleuse", "#fff0cf", 0.3, emit="#ffd99a", emit_power=3.0))
hall.build()

# le haut de la maison coupée : un couvercle sombre et la moulure du haut des murs, un par côté
dark = M("coupe", "#000000", 1.0, emit="#1b110f", emit_power=1.0)
for side, cap, top in (("Ouest", (-8.0, X0 - WALL, -8.0, 8.0), (X0 - WALL, X0, ZN - WALL, ZS + WALL)),
                       ("Est", (X1 + WALL, 8.0, -8.0, 8.0), (X1, X1 + WALL, ZN - WALL, ZS + WALL)),
                       ("Nord", (X0 - WALL, X1 + WALL, -8.0, ZN - WALL), (X0 - WALL, X1 + WALL, ZN - WALL, ZN)),
                       ("Sud", (X0 - WALL, X1 + WALL, ZS + WALL, 8.0), (X0 - WALL, X1 + WALL, ZS, ZS + WALL))):
    cut = C.Obj("Coupe" + side)
    cut.box(cap[0], CEIL, cap[2], cap[1], CEIL + 0.02, cap[3], dark)
    cut.box(top[0] - 0.01, CEIL - 0.04, top[2], top[1] + 0.01, CEIL + 0.015, top[3], plaster, bevel=0.006, seg=1)
    cut.build()


# ---------------------------------------------------------------- le lit

room = C.Obj("Chambre")
bx0, bz0, bx1, bz1 = rect(PLAN["hides"][0]["rect"])
under = PLAN["hides"][0]["height"]
top_y = PLAN["surfaces"]["lit"]
# le cadre de métal : pieds, longerons, la tête haute à barreaux et à arche, le pied plus bas
for lx in (bx0 + 0.03, bx1 - 0.03):
    for lz, h in ((bz0 + 0.03, 1.12), (bz1 - 0.03, 0.82)):
        room.tube([(lx, 0.0, lz), (lx, h, lz)], 0.016, white_metal, seg=10)
        room.ball((lx, h + 0.012, lz), 0.024, white_metal, seg=12, rings=8)
for lz in (bz0 + 0.03, bz1 - 0.03):
    room.tube([(bx0 + 0.03, under + 0.02, lz), (bx1 - 0.03, under + 0.02, lz)], 0.012, white_metal, seg=8)
for lx in (bx0 + 0.03, bx1 - 0.03):
    room.tube([(lx, under + 0.02, bz0 + 0.03), (lx, under + 0.02, bz1 - 0.03)], 0.012, white_metal, seg=8)
# la tête : deux traverses, une arche, des barreaux
hz = bz0 + 0.03
arch = [(bx0 + 0.03 + (bx1 - bx0 - 0.06) * t, 0.98 + 0.1 * math.sin(math.pi * t), hz) for t in [i / 12 for i in range(13)]]
room.tube(arch, 0.012, white_metal, seg=8)
room.tube([(bx0 + 0.03, 0.62, hz), (bx1 - 0.03, 0.62, hz)], 0.01, white_metal, seg=8)
for k in range(1, 9):
    x = bx0 + 0.03 + (bx1 - bx0 - 0.06) * k / 9
    room.tube([(x, 0.62, hz), (x, 0.98 + 0.1 * math.sin(math.pi * k / 9) - 0.01, hz)], 0.007, white_metal, seg=6)
fz = bz1 - 0.03
room.tube([(bx0 + 0.03, 0.74, fz), (bx1 - 0.03, 0.74, fz)], 0.011, white_metal, seg=8)
for k in range(1, 7):
    x = bx0 + 0.03 + (bx1 - bx0 - 0.06) * k / 7
    room.tube([(x, under + 0.02, fz), (x, 0.74, fz)], 0.007, white_metal, seg=6)
# le sommier, le matelas et son drap
room.box(bx0 + 0.04, under + 0.02, bz0 + 0.05, bx1 - 0.04, under + 0.06, bz1 - 0.05, M("sommier", "#e8e2d8", 0.8))
room.box(bx0 + 0.05, under + 0.06, bz0 + 0.06, bx1 - 0.05, top_y - 0.03, bz1 - 0.06, sheet, bevel=0.03, seg=2)
# la douillette rose, froissée, qui retombe des deux côtés et au pied ; repliée en haut sur le drap blanc
duv_z0 = bz0 + 0.5
room.box(bx0 + 0.03, under + 0.03, duv_z0, bx1 - 0.03, top_y + 0.03, bz1 - 0.035, duvet, bevel=0.045, seg=3)
room.box(bx0 + 0.04, top_y - 0.01, duv_z0 - 0.07, bx1 - 0.04, top_y + 0.045, duv_z0 + 0.06, sheet, bevel=0.025, seg=2)
for k in range(7):
    z = duv_z0 + 0.18 + k * (bz1 - duv_z0 - 0.3) / 6
    sway = rng.uniform(-0.05, 0.05)
    room.tube([(bx0 + 0.12, top_y + 0.03, z + sway), ((bx0 + bx1) / 2, top_y + 0.045, z), (bx1 - 0.1, top_y + 0.03, z - sway)],
              [0.012, 0.018, 0.012], duvet_d if k % 2 else duvet, seg=8, squash=(1.0, 0.5), cap_rings=2)
# les oreillers, le jeté poilu, la fleur et la fraise en peluche
for k, px in enumerate((bx0 + 0.27, bx1 - 0.27)):
    room.ball((px, top_y + 0.06, bz0 + 0.24), (0.21, 0.07, 0.13), pillow_m, seg=20, rings=12)
room.ball((bx0 + 0.36, top_y + 0.12, bz0 + 0.38), (0.15, 0.09, 0.07), M("coussin_poilu", "#f6cdd6", 0.98, **T.fur()),
          seg=18, rings=10)
fcx, fcy, fcz = bx1 - 0.25, top_y + 0.13, bz0 + 0.42
for i in range(5):
    a = i * math.tau / 5
    room.ball((fcx + math.cos(a) * 0.065, fcy + math.sin(a) * 0.065, fcz + 0.01), (0.05, 0.05, 0.03), fluffy, seg=14,
              rings=8)
room.ball((fcx, fcy, fcz + 0.03), (0.04, 0.04, 0.025), fluffy_c, seg=14, rings=8)
for s in (-1, 1):
    room.ball((fcx + 0.013 * s, fcy + 0.008, fcz + 0.053), 0.0055, iron, seg=8, rings=6)
room.ball((bx0 + 0.16, top_y + 0.1, bz0 + 0.5), (0.07, 0.08, 0.065), straw, seg=16, rings=10)
for i in range(14):
    a, b = rng.uniform(0, math.tau), rng.uniform(-0.6, 0.7)
    room.ball((bx0 + 0.16 + math.cos(a) * 0.066 * math.cos(b), top_y + 0.1 + math.sin(b) * 0.075,
               bz0 + 0.5 + math.sin(a) * 0.06 * math.cos(b)), 0.006, straw_seed, seg=6, rings=4)
for i in range(5):
    a = i * math.tau / 5
    D.blade(room, (bx0 + 0.16, top_y + 0.175, bz0 + 0.5), (math.cos(a), 0.2, math.sin(a)), 0.05, 0.02, leafy)


# ---------------------------------------------------------------- la commode et la cage du hamster

cx0, cz0, cx1, cz1 = rect(PLAN["obstacles"]["commode"])
CH = PLAN["surfaces"]["commode"]
room.box(cx0, 0.06, cz0, cx1, CH, cz1, white_wood, bevel=0.012, seg=2)
for lx in (cx0 + 0.04, cx1 - 0.04):
    for lz in (cz0 + 0.04, cz1 - 0.04):
        room.cyl((lx, 0.0, lz), 0.02, 0.06, white_wood, seg=10)
for k in range(4):
    y0 = 0.1 + k * 0.175
    room.box(cx1, y0, cz0 + 0.03, cx1 + 0.012, y0 + 0.155, cz1 - 0.03, white_wood, bevel=0.005, seg=1)
    for zz in (cz0 + 0.2, cz1 - 0.2):
        room.ball((cx1 + 0.022, y0 + 0.078, zz), 0.016, knob_m, seg=10, rings=8)
# la cage de verre : un aquarium à couvercle grillagé blanc, des copeaux, la cabane, la roue… et le hamster
gx0, gx1, gz0, gz1 = cx0 + 0.03, cx1 - 0.04, cz1 - 0.48, cz1 - 0.04
gh = 0.3
room.box(gx0, CH, gz0, gx1, CH + 0.02, gz1, M("socle_cage", "#e9e4db", 0.5))
room.box(gx0 + 0.01, CH + 0.02, gz0 + 0.01, gx1 - 0.01, CH + 0.07, gz1 - 0.01, shavings)
for a, b, c, d in ((gx0, gx0 + 0.006, gz0, gz1), (gx1 - 0.006, gx1, gz0, gz1), (gx0, gx1, gz0, gz0 + 0.006),
                   (gx0, gx1, gz1 - 0.006, gz1)):
    room.box(a, CH + 0.02, c, b, CH + gh, d, glass)
room.box(gx0, CH + gh, gz0, gx1, CH + gh + 0.012, gz1, M("couvercle_cage", "#f4f2ee", 0.5), bevel=0.003, seg=1)
# les arêtes blanches de l'aquarium : on voit le verre
for ex in (gx0, gx1):
    for ez in (gz0, gz1):
        room.box(ex - 0.008, CH + 0.02, ez - 0.008, ex + 0.008, CH + gh, ez + 0.008, white_metal)
for ez in (gz0, gz1):
    room.box(gx0, CH + gh - 0.012, ez - 0.006, gx1, CH + gh, ez + 0.006, white_metal)
for ex in (gx0, gx1):
    room.box(ex - 0.006, CH + gh - 0.012, gz0, ex + 0.006, CH + gh, gz1, white_metal)
for k in range(1, 12):
    z = gz0 + (gz1 - gz0) * k / 12
    room.box(gx0 + 0.01, CH + gh + 0.012, z - 0.002, gx1 - 0.01, CH + gh + 0.016, z + 0.002, white_metal)
room.box(gx0 + 0.02, CH + 0.07, gz0 + 0.03, gx0 + 0.15, CH + 0.16, gz0 + 0.16, M("cabane_hamster", "#d6a86a", 0.8),
         bevel=0.01, seg=1)
room.torus(((gx0 + gx1) / 2 + 0.06, CH + 0.17, gz1 - 0.12), 0.08, 0.008, M("roue_hamster", "#5bc0eb", 0.4),
           axis=(1, 0, 0), seg=24, sides=6)
hx, hz = (gx0 + gx1) / 2 - 0.02, (gz0 + gz1) / 2 + 0.02
room.ball((hx, CH + 0.1, hz), (0.055, 0.042, 0.065), hamster_m, seg=16, rings=10)
room.ball((hx + 0.03, CH + 0.09, hz + 0.01), (0.02, 0.022, 0.035), hamster_w, seg=12, rings=8)
for s in (-1, 1):
    room.ball((hx + 0.015, CH + 0.13, hz + 0.03 * s), (0.008, 0.012, 0.01), M("oreille_hamster", "#e8a6a0", 0.8),
              seg=8, rings=6)
    room.ball((hx + 0.04, CH + 0.11, hz + 0.017 * s), 0.0045, iron, seg=6, rings=4)
# la bougie dans son pot et la petite machine à gommes, au bout de la commode (loin de la collation)
room.cyl((cx0 + 0.12, CH, cz0 + 0.09), 0.04, 0.075, candle_jar, seg=18)
room.cyl((cx0 + 0.12, CH, cz0 + 0.09), 0.034, 0.05, wax, seg=16)
room.ball((cx0 + 0.12, CH + 0.068, cz0 + 0.09), (0.006, 0.014, 0.006), flame, seg=8, rings=6)
room.cyl((cx0 + 0.3, CH, cz0 + 0.08), 0.03, 0.05, gum_red, seg=16, top=0.022)
room.ball((cx0 + 0.3, CH + 0.09, cz0 + 0.08), 0.042, M("globe_gommes", "#eef6fa", 0.05, alpha=0.3), seg=16, rings=10)
for i in range(16):
    a, b = rng.uniform(0, math.tau), rng.uniform(-1.2, 0.6)
    room.ball((cx0 + 0.3 + math.cos(a) * math.cos(b) * 0.028, CH + 0.085 + math.sin(b) * 0.028,
               cz0 + 0.08 + math.sin(a) * math.cos(b) * 0.028), 0.011, gum_balls[i % 5], seg=8, rings=6)
room.ball((cx0 + 0.3, CH + 0.136, cz0 + 0.08), 0.012, gum_red, seg=10, rings=6)


# ---------------------------------------------------------------- le bureau, sa chaise rouge à trous

dx0, dz0, dx1, dz1 = rect(PLAN["obstacles"]["bureau"])
DH = PLAN["surfaces"]["bureau"]
room.box(dx0, DH - 0.03, dz0, dx1, DH, dz1, white_wood, bevel=0.008, seg=2)
for lx in (dx0 + 0.04, dx1 - 0.04):
    for lz in (dz0 + 0.04, dz1 - 0.04):
        room.box(lx - 0.02, 0.0, lz - 0.02, lx + 0.02, DH - 0.03, lz + 0.02, white_wood, bevel=0.004, seg=1)
room.box(dx0 + 0.06, DH - 0.13, dz0 + 0.1, dx0 + 0.08, DH - 0.03, dz1 - 0.1, white_wood)
# le cahier mauve, un verre bleu, un pot de crayons (c'est lui qui fait du bruit), une petite lampe
room.box(dx0 + 0.12, DH, dz1 - 0.45, dx0 + 0.36, DH + 0.012, dz1 - 0.12, notebook, bevel=0.003, seg=1)
for k in range(9):
    room.torus((dx0 + 0.12, DH + 0.008, dz1 - 0.42 + k * 0.034), 0.008, 0.0015, white_metal, axis=(0, 0, 1), seg=10, sides=4)
room.cyl((dx1 - 0.1, DH, dz1 - 0.08), 0.035, 0.1, cup_blue, seg=18, top=0.04)
room.cyl((dx1 - 0.12, DH, dz0 + 0.42), 0.035, 0.09, M("pot_crayons", "#f2c14e", 0.5), seg=16)
for k in range(6):
    a = k * 1.05
    room.tube([(dx1 - 0.12 + math.cos(a) * 0.015, DH + 0.05, dz0 + 0.42 + math.sin(a) * 0.015),
               (dx1 - 0.12 + math.cos(a) * 0.03, DH + 0.17, dz0 + 0.42 + math.sin(a) * 0.03)], 0.005,
              books[k % len(books)], seg=6)
room.build()

kx, kz = PLAN["chairs"]["chaise_bureau"]["pos"]
chair = C.Obj("Chaise_chaise_bureau", origin=(kx, 0, kz))
chair.cyl((kx, 0.38, kz), 0.2, 0.06, red_chair, seg=24, bevel=0.02)
chair.cyl((kx, 0.1, kz), 0.025, 0.28, white_metal, seg=12)
for k in range(5):
    a = k * math.tau / 5 + 0.3
    end = (kx + math.cos(a) * 0.26, 0.06, kz + math.sin(a) * 0.26)
    chair.tube([(kx, 0.1, kz), end], [0.02, 0.014], white_metal, seg=8)
    chair.ball((end[0], 0.03, end[2]), 0.028, iron, seg=10, rings=6)
# le dossier rouge, tourné vers le bureau, percé de trous ronds
back = Vector((kx - 0.18, 0.0, kz))
chair.tube([(kx - 0.12, 0.42, kz), (kx - 0.2, 0.55, kz)], 0.018, white_metal, seg=8)
chair.box(kx - 0.235, 0.52, kz - 0.17, kx - 0.205, 0.92, kz + 0.17, red_chair, bevel=0.02, seg=2)
for y in (0.6, 0.7, 0.8):
    for zz in (-0.09, 0.0, 0.09):
        if (y, zz) == (0.7, 0.0):
            continue
        chair.cyl((kx - 0.237, y + (0.03 if zz == 0.0 else 0.0), kz + zz), 0.024, 0.034, hole_m, axis=(1, 0, 0), seg=14)
chair.build()


# ---------------------------------------------------------------- le fauteuil papillon, les étagères à livres

ax0, az0, ax1, az1 = rect(PLAN["obstacles"]["fauteuil"])
chair_c = Vector(((ax0 + ax1) / 2, 0, (az0 + az1) / 2))
fauteuil = C.Obj("Fauteuil")
for s in (-1, 1):
    fauteuil.tube([chair_c + Vector((-0.26, 0.0, 0.22 * s)), chair_c + Vector((0.2, 0.82, 0.26 * s))], 0.011, iron, seg=8)
    fauteuil.tube([chair_c + Vector((0.24, 0.0, 0.22 * s)), chair_c + Vector((-0.22, 0.52, 0.28 * s))], 0.011, iron, seg=8)
fauteuil.build()
# la housse en fourrure blanche, en hamac : des formes fondues en une seule surface moelleuse
sling = C.Obj("FauteuilHousse")
for i in range(22):
    t = i / 21
    p = chair_c + Vector((0.2 - 0.44 * t, 0.8 - 0.44 * math.sin(t * math.pi * 0.85) - 0.12 * t, 0.0))
    sling.ball(p, (0.1, 0.075, 0.27 - 0.04 * abs(t - 0.45)), fur_m, seg=14, rings=8)
sling_ob = sling.build()
C.remesh(sling_ob, 0.018, 6, 0.5)

ledges = C.Obj("Etageres")
for k, y in enumerate((1.05, 1.42, 1.79)):
    lx0, lx1 = 0.92, 1.48
    ledges.box(lx0, y, ZN, lx1, y + 0.02, ZN + 0.1, trim, bevel=0.004, seg=1)
    ledges.box(lx0, y, ZN + 0.09, lx1, y + 0.05, ZN + 0.1, trim, bevel=0.003, seg=1)
    x = lx0 + 0.02
    while x < lx1 - 0.1:
        w = rng.uniform(0.11, 0.15)
        h = rng.uniform(0.17, 0.24)
        lean = rng.uniform(0.04, 0.07)
        m_ = books[rng.randrange(len(books))]
        rot = Matrix.Translation((x + w / 2, y + 0.02, ZN + 0.07)) @ Matrix.Rotation(-lean * 2.0, 4, "X")
        ledges.box(-w / 2, 0, -0.012, w / 2, h, 0.0, paper, matrix=rot)
        ledges.box(-w / 2, 0, 0.0, w / 2, h, 0.004, m_, matrix=rot)
        # une illustration de couverture, en aplats (aucun titre)
        ledges.box(-w * 0.32, h * 0.25, 0.004, w * 0.32, h * 0.68, 0.0055, books[(books.index(m_) + 3) % len(books)],
                   matrix=rot)
        x += w * 0.72
ledges.build()


# ---------------------------------------------------------------- la soirée pyjama : sacs de couchage, plateau, coussin

night = C.Obj("SoireePyjama")
# le tapis moelleux, les deux sacs de couchage ouverts et leurs oreillers
night.cyl((0.2, 0.0, -0.35), 0.95, 0.008, rug_m, seg=40)
for (sx0, sx1), bag in (((-0.42, 0.2), bag_pink), ((0.2, 0.78), bag_mint)):
    night.box(sx0, 0.008, -0.95, sx1, 0.07, 0.2, bag, bevel=0.035, seg=2)
    night.box(sx0 + 0.04, 0.07, -0.95, sx1 - 0.04, 0.074, -0.35, bag_lining)
    night.box(sx0 + 0.02, 0.06, -0.38, sx1 - 0.02, 0.1, -0.22, bag, bevel=0.03, seg=2)
    night.ball(((sx0 + sx1) / 2, 0.11, -0.84), (0.2, 0.06, 0.11), pillow_m if bag is bag_pink else sheet, seg=18,
               rings=10)
# le plateau bas des collations, la tablette sur son support (l'écran vers les filles), des serviettes
px0, pz0, px1, pz1 = rect(PLAN["obstacles"]["plateau"])
PH = PLAN["surfaces"]["low"]
night.box(px0, PH - 0.03, pz0, px1, PH, pz1, tray_m, bevel=0.012, seg=2)
for lx in (px0 + 0.05, px1 - 0.05):
    for lz in (pz0 + 0.05, pz1 - 0.05):
        night.cyl((lx, 0.0, lz), 0.02, PH - 0.03, white_wood, seg=10, top=0.022)
night.box(0.0, PH, 0.47, 0.16, PH + 0.012, 0.52, tablet_m, bevel=0.003, seg=1)
night.box(0.01, PH + 0.01, 0.47, 0.15, PH + 0.13, 0.48, tablet_m, bevel=0.004, seg=1)
night.box(px1 - 0.12, PH, pz1 - 0.1, px1 - 0.04, PH + 0.01, pz1 - 0.03, napkin)
# le coussin de Blanche, rond, au pied de la fenêtre
qx0, qz0, qx1, qz1 = PLAN["cushion"]
qc = ((qx0 + qx1) / 2, 0.0, (qz0 + qz1) / 2)
night.cyl(qc, (qx1 - qx0) / 2 - 0.02, 0.05, dog_bed, seg=32, bevel=0.02)
night.torus((qc[0], 0.06, qc[2]), (qx1 - qx0) / 2 - 0.05, 0.045, dog_bed_rim, seg=32, sides=10)
night.build()

screen_img = T.screen("ecran_tablette", "film")
D.wall_picture("EcranTablette", screen_img, (0.08, PH + 0.072, 0.468), (0.13, 0.11), "-z", None, emit=1.6)

C.export("chambre")


def preview(name, plan):
    hidden = set(plan.get("cache", []))
    for ob in C.bpy.data.objects:
        top_ = ob
        while top_.parent is not None:
            top_ = top_.parent
        ob.hide_render = top_.name in hidden
    cam = plan["camera"]
    C.render(name, cam["pos"], cam["target"], cam["fov"])


preview("chambre", PLAN)
