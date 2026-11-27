"""Le double salon : la salle à manger (au nord) et le salon (au sud, sur la rue), une seule longue pièce sans cloison,
d'après les photos de reference/photos-8/ (en ordre). Les meubles qui comptent pour le jeu viennent des plans
data/pieces/salle_a_manger.json et salon.json.

Chaque partie est un objet nommé : le jeu cache, selon la caméra de la mission, ce qui gênerait la vue (le champ
`cache` des plans) ; l'objet Noel n'est montré qu'au party des Fêtes ; un seul écran de télé est montré à la fois.

Blender --background --python tools/blender/double_salon.py
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
PIECES = C.ROOT / "data" / "pieces"
SAM = json.loads((PIECES / "salle_a_manger.json").read_text())
SALON = json.loads((PIECES / "salon.json").read_text())
FETES = json.loads((PIECES / "fetes.json").read_text())
rng = random.Random(8)
M = C.material

# Les murs et les ouvertures (repère du double salon).
X0, X1 = -1.65, 1.65
ZN, ZS = -3.6, 3.8
CEIL = 2.9
WALL = 0.12
DOOR = (-2.85, -2.05)            # la porte de bois, mur ouest de la salle à manger
OPENING = (0.1, 1.4)             # la grande ouverture du corridor, mur ouest du salon
WINDOW = (0.05, 1.25, 0.75, 2.45)  # la fenêtre du salon : x0, x1, bas, haut


def rect(a):
    return a[0], a[1], a[2], a[3]


def mat(name, maps, **kw):
    return M(name, **maps, **kw)


# ---------------------------------------------------------------- matières

floor_m = mat("plancher_erable", T.floor(rng, "plancher_erable", ["#d39d5c", "#cc944f", "#d9a662", "#c99050", "#d6a05f",
                                                                  "#ddaa69", "#cf9855", "#d49e5b"], along_z=True))
wall_m = mat("mur_salon", T.plaster("mur_salon", "#ede7dd"))
slate = mat("mur_ardoise", T.plaster("mur_ardoise", "#2c3238", 1.0))
walnut = mat("noyer", T.wood("noyer", "#77492f", "#432619", False, 0.6, 0.4, 0.8))
table_wood = mat("bois_table", T.wood("bois_table", "#4e3324", "#2c1b12", False, 0.9, 0.3, 0.7))
blond = mat("bois_blond", T.wood("bois_blond", "#e4c08c", "#c59660", False, 0.8, 0.42, 0.6))
teak = mat("teck", T.wood("teck", "#a86c3d", "#6c3e1f", False, 0.7, 0.36, 0.7))
corner_wood = mat("bois_ancien", T.wood("bois_ancien", "#5b3825", "#311c11", True, 0.7, 0.32, 0.8))
mustard = mat("velours_moutarde", T.corduroy("velours_moutarde", "#c8962c"))
navy = mat("velours_marine", T.velvet("velours_marine", "#24345c"))
curtain = mat("rideau_marine", T.fabric("rideau_marine", "#1d2a4c", 0.3, 7))
blanket_m = mat("couverture_cage", T.blanket("couverture_cage"))
cushion_m = mat("coussin_mauve", T.fabric("coussin_mauve", "#8f6ba9", 0.2, 6))
dog_bed = mat("coussin_salon", T.fabric("coussin_salon", "#8b8f9a", 0.25, 7))
white_cushion = mat("coussin_blanc", T.fabric("coussin_blanc", "#f1ede6", 0.25, 6))
plaster_trim = M("platre", "#f5f1ea", 0.55)
black = M("noir_meuble", "#1c1c20", 0.55)
piano_black = M("noir_piano", "#111114", 0.22)
iron = M("fer", "#19191c", 0.42, 0.55)
brass = M("laiton", "#cda75f", 0.28, 0.9)
opal = M("opale", "#f7f2e7", 0.3, emit="#ffe9c4", emit_power=0.7)
smoke = M("verre_fume", "#9a7650", 0.08, alpha=0.5)
bulb = M("ampoule", "#fff1cf", 0.3, emit="#ffd391", emit_power=6.0)
glass = M("vitre", "#d5e6ee", 0.05, alpha=0.18)
white_paint = M("blanc_peint", "#f2f0eb", 0.45)
radiator_m = M("radiateur", "#f0eee9", 0.4)
frame_black = M("cadre_noir", "#141416", 0.4)
frame_gold = M("cadre_or", "#c79a4a", 0.3, 0.85)
mirror_m = M("miroir", "#d9dde2", 0.04, 1.0)
paper_m = M("passe_partout", "#f4f0e8", 0.8)
key_white = M("touche_blanche", "#f3f1ea", 0.3)
leaf = M("feuille", "#4f9440", 0.6)
leaf_d = M("feuille_fonce", "#2f6a30", 0.65)
leaf_l = M("feuille_claire", "#79b04a", 0.6)
soil = M("terre", "#3a2a1c", 1.0)
pot = M("pot", "#e7e2d8", 0.5)
basket_m = M("panier", "#b88d55", 0.9)
glazes = [M(f"glacure_{n}", c, 0.22) for n, c in (("creme", "#efe6d2"), ("rose", "#e9b4b6"), ("eau", "#a9d6c3"),
                                                   ("bleu", "#a8c5e2"), ("jaune", "#f2d88c"), ("sable", "#d9c3a1"),
                                                   ("blanc", "#f6f3ee"), ("lilas", "#c9b6dd"))]
vinyl = [M(f"disque_{i}", c, 0.7) for i, c in enumerate(("#c7533f", "#2f5d8c", "#e3c45a", "#3c7a5a", "#8c3f6e", "#e9e2d6"))]
game_box = [M(f"jeu_{i}", c, 0.6) for i, c in enumerate(("#d9493c", "#3a7cc0", "#f1b83a", "#4f9a5a"))]


# ---------------------------------------------------------------- les murs

def baseboard(o, axis, at, a0, a1, inward):
    """Une plinthe de bois foncé le long d'un mur. axis "x" : le long de x (mur nord ou sud) ; inward : vers la pièce."""
    lo, hi = sorted((at, at + inward * 0.018))
    if axis == "x":
        o.box(a0, 0, lo, a1, 0.15, hi, walnut, bevel=0.004, seg=1)
        o.box(a0, 0.15, lo, a1, 0.165, hi, walnut, bevel=0.003, seg=1)
    else:
        o.box(lo, 0, a0, hi, 0.15, a1, walnut, bevel=0.004, seg=1)
        o.box(lo, 0.15, a0, hi, 0.165, a1, walnut, bevel=0.003, seg=1)


def crown(o, axis, at, a0, a1, inward):
    """La corniche de plâtre moulurée, en trois gradins."""
    for k, (y0, depth) in enumerate(((CEIL - 0.06, 0.03), (CEIL - 0.1, 0.055), (CEIL - 0.14, 0.02))):
        lo, hi = sorted((at, at + inward * depth))
        if axis == "x":
            o.box(a0, y0, lo, a1, y0 + 0.04 + k * 0.01, hi, plaster_trim, bevel=0.006, seg=1)
        else:
            o.box(lo, y0, a0, hi, y0 + 0.04 + k * 0.01, a1, plaster_trim, bevel=0.006, seg=1)


def wall_x(o, z, x0, x1, material, holes=()):
    """Un mur est-ouest (nord ou sud), percé de `holes` = [(x0, x1, bas, haut)]."""
    z0, z1 = sorted((z, z + (WALL if z > 0 else -WALL)))
    cuts = sorted(holes)
    x = x0
    for hx0, hx1, hy0, hy1 in cuts:
        o.box(x, 0, z0, hx0, CEIL, z1, material)
        o.box(hx0, 0, z0, hx1, hy0, z1, material)
        o.box(hx0, hy1, z0, hx1, CEIL, z1, material)
        x = hx1
    o.box(x, 0, z0, x1, CEIL, z1, material)


def wall_z(o, x, z0, z1, material, holes=()):
    """Un mur nord-sud (ouest ou est), percé de `holes` = [(z0, z1, bas, haut)]."""
    xa, xb = sorted((x, x + (WALL if x > 0 else -WALL)))
    z = z0
    for hz0, hz1, hy0, hy1 in sorted(holes):
        o.box(xa, 0, z, xb, CEIL, hz0, material)
        o.box(xa, 0, hz0, xb, hy0, hz1, material)
        o.box(xa, hy1, hz0, xb, CEIL, hz1, material)
        z = hz1
    o.box(xa, 0, z, xb, CEIL, z1, material)


floor_ob = C.Obj("Plancher")
# il s'arrête sous le mur ouest, là où commence celui du corridor : deux planchers superposés clignotaient dans
# les portes
floor_ob.box(X0 - WALL, -0.06, ZN - 0.2, X1 + 0.2, 0.0, ZS + 0.2, floor_m)
floor_ob.build()

# Le mur nord, ardoise, avec sa plinthe et sa corniche blanches.
north = C.Obj("MurNord")
wall_x(north, ZN, X0 - WALL, X1 + WALL, slate)
baseboard(north, "x", ZN, X0, X1, 1)
crown(north, "x", ZN, X0, X1, 1)
# l'interrupteur, près du coin de la cage
north.box(-1.5, 1.18, ZN, -1.42, 1.3, ZN + 0.012, white_paint, bevel=0.004, seg=1)
north.build()

# Le mur sud, sur la rue : la fenêtre à guillotine.
south = C.Obj("MurSud")
wx0, wx1, wy0, wy1 = WINDOW
wall_x(south, ZS, X0 - WALL, X1 + WALL, wall_m, [(wx0, wx1, wy0, wy1)])
baseboard(south, "x", ZS, X0, X1, -1)
crown(south, "x", ZS, X0, X1, -1)
# le cadre, les deux châssis, le meneau et l'appui
for a, b, c, d in ((wx0 - 0.07, wx0, wy0 - 0.04, wy1 + 0.07), (wx1, wx1 + 0.07, wy0 - 0.04, wy1 + 0.07),
                   (wx0 - 0.07, wx1 + 0.07, wy1, wy1 + 0.09)):
    south.box(a, c, ZS - 0.02, b, d, ZS + 0.01, white_paint, bevel=0.006, seg=1)
south.box(wx0 - 0.1, wy0 - 0.05, ZS - 0.06, wx1 + 0.1, wy0, ZS + 0.02, white_paint, bevel=0.008, seg=1)
mid_y = (wy0 + wy1) / 2
for zz, (y0, y1) in ((ZS + 0.03, (wy0, mid_y + 0.03)), (ZS + 0.06, (mid_y - 0.03, wy1))):
    for a, b, c, d in ((wx0, wx1, y0, y0 + 0.05), (wx0, wx1, y1 - 0.05, y1), (wx0, wx0 + 0.05, y0, y1),
                       (wx1 - 0.05, wx1, y0, y1)):
        south.box(a, c, zz, b, d, zz + 0.03, white_paint, bevel=0.004, seg=1)
    south.box(wx0 + 0.05, y0 + 0.05, zz + 0.012, wx1 - 0.05, y1 - 0.05, zz + 0.016, glass)
# la tringle et les rideaux marine, de chaque côté
south.tube([(wx0 - 0.3, wy1 + 0.16, ZS - 0.07), (wx1 + 0.3, wy1 + 0.16, ZS - 0.07)], 0.011, iron, seg=8)
for cx, width in ((wx0 - 0.12, 0.3), (wx1 + 0.12, 0.22)):
    folds = 7
    for k in range(folds):
        x = cx - width / 2 + k * width / (folds - 1)
        sway = 0.018 * math.sin(k * 1.7)
        south.tube([(x, wy1 + 0.15, ZS - 0.07 + 0.01 * (k % 2)), (x + sway, 1.2, ZS - 0.09 + 0.012 * (k % 2)),
                    (x + sway * 1.5, 0.04, ZS - 0.08)], [0.03, 0.034, 0.036], curtain, seg=8, squash=(0.55, 1.0),
                   cap_rings=2)
# le garde-corps de fer forgé, dehors
for k in range(13):
    x = wx0 + 0.04 + k * (wx1 - wx0 - 0.08) / 12
    south.tube([(x, wy0 - 0.2, ZS + 0.32), (x, wy0 + 0.55, ZS + 0.32)], 0.008, iron, seg=6)
    if k % 2 == 0:
        south.torus((x + 0.045, wy0 + 0.2, ZS + 0.32), 0.04, 0.005, iron, axis=(0, 0, 1), seg=14, sides=4)
for y in (wy0 + 0.55, wy0 + 0.02):
    south.tube([(wx0 - 0.1, y, ZS + 0.32), (wx1 + 0.1, y, ZS + 0.32)], 0.014, iron, seg=6)
south.build()
view_img = T.street(rng)
D.wall_picture("VueSalon", view_img, ((wx0 + wx1) / 2, (wy0 + wy1) / 2 + 0.1, ZS + 0.5),
               (wx1 - wx0 + 1.1, wy1 - wy0 + 1.0), "-z", None, emit=1.0)

# Le mur ouest : la porte de bois (salle à manger) et la grande ouverture (salon) donnent sur le corridor.
west_sam = C.Obj("MurOuestSAM")
wall_z(west_sam, X0, ZN - WALL, 0.0, wall_m, [(DOOR[0], DOOR[1], 0.0, 2.15)])
baseboard(west_sam, "z", X0, ZN, DOOR[0] - 0.07, 1)
baseboard(west_sam, "z", X0, DOOR[1] + 0.07, 0.0, 1)
crown(west_sam, "z", X0, ZN, 0.0, 1)
# le cadre de porte en bois verni et la porte ouverte vers le corridor
for a, b, c, d in ((DOOR[0] - 0.08, DOOR[0], 0, 2.23), (DOOR[1], DOOR[1] + 0.08, 0, 2.23),
                   (DOOR[0] - 0.08, DOOR[1] + 0.08, 2.15, 2.23)):
    west_sam.box(X0 - 0.13, c, a, X0 + 0.022, d, b, walnut, bevel=0.006, seg=1)
leaf_door = Matrix.Translation(Vector((X0 - 0.13, 0, DOOR[0]))) @ Matrix.Rotation(math.radians(-80), 4, "Y") \
    @ Matrix.Translation(Vector((-(X0 - 0.13), 0, -DOOR[0])))
west_sam.box(X0 - 0.17, 0.01, DOOR[0], X0 - 0.13, 2.13, DOOR[1], walnut, bevel=0.01, seg=1, matrix=leaf_door)
for y0, y1 in ((0.2, 0.95), (1.15, 2.0)):
    west_sam.box(X0 - 0.178, y0, DOOR[0] + 0.1, X0 - 0.165, y1, DOOR[1] - 0.1, corner_wood, bevel=0.006, seg=1,
                 matrix=leaf_door)
west_sam.box(X0 + 0.01, 1.16, -1.74, X0 + 0.03, 1.24, -1.66, white_paint, bevel=0.004, seg=1)
west_sam.build()

west_salon = C.Obj("MurOuestSalon")
wall_z(west_salon, X0, 0.0, ZS + WALL, wall_m, [(OPENING[0], OPENING[1], 0.0, 2.35)])
baseboard(west_salon, "z", X0, OPENING[1] + 0.09, ZS, 1)
crown(west_salon, "z", X0, 0.0, ZS, 1)
for a, b, c, d in ((OPENING[0] - 0.09, OPENING[0], 0, 2.44), (OPENING[1], OPENING[1] + 0.09, 0, 2.44),
                   (OPENING[0] - 0.09, OPENING[1] + 0.09, 2.35, 2.44)):
    west_salon.box(X0 - 0.13, c, a, X0 + 0.025, d, b, white_paint, bevel=0.008, seg=1)
west_salon.build()

# Le mur est : les trois affiches (salle à manger) et le mur de cadres (salon).
east_sam = C.Obj("MurEstSAM")
wall_z(east_sam, X1, ZN - WALL, 0.0, wall_m)
baseboard(east_sam, "z", X1, ZN, 0.0, -1)
crown(east_sam, "z", X1, ZN, 0.0, -1)
posters = (("affiche_lettres", "lettres", -2.75, (0.42, 0.56)), ("affiche_lune", "lune", -2.05, (0.4, 0.54)),
           ("affiche_motifs", "motifs", -1.32, (0.46, 0.6)))
for name, kind, z, size in posters:
    D.frame(east_sam, (X1 - 0.005, 1.6, z), size, "-x", frame_gold, border=0.018, depth=0.02, mat_inner=paper_m)
east_sam_ob = east_sam.build()
for name, kind, z, size in posters:
    D.wall_picture(name, T.picture(name, kind), (X1 - 0.012, 1.6, z), (size[0] - 0.05, size[1] - 0.05), "-x",
                   east_sam_ob)

east_salon = C.Obj("MurEstSalon")
wall_z(east_salon, X1, 0.0, ZS + WALL, wall_m)
baseboard(east_salon, "z", X1, 0.0, ZS, -1)
crown(east_salon, "z", X1, 0.0, ZS, -1)
gallery = (("cadre_aquarelle", "aquarelle", 1.85, 1.15, (0.34, 0.26)), ("cadre_chien", "chien", 1.86, 1.58, (0.2, 0.26)),
           ("cadre_falaise", "falaise", 1.42, 1.25, (0.46, 0.32)), ("cadre_ciel", "ciel", 1.83, 2.42, (0.3, 0.4)),
           ("cadre_vagues", "vagues", 1.85, 2.85, (0.26, 0.34)), ("cadre_motifs", "motifs", 1.38, 1.83, (0.2, 0.26)))
for name, kind, y, z, size in gallery:
    D.frame(east_salon, (X1 - 0.005, y, z), size, "-x", frame_black, border=0.028, depth=0.022, mat_inner=paper_m)
# le miroir ovale doré et l'horloge de bois
east_salon.torus((X1 - 0.02, 1.85, 2.0), 0.17, 0.025, frame_gold, axis=(1, 0, 0), seg=40, sides=8, squash=1.35)
east_salon.cyl((X1 - 0.03, 1.85, 2.0), 0.165, 0.008, mirror_m, axis=(-1, 0, 0), seg=40)
east_salon.box(X1 - 0.05, 1.36, 2.16, X1, 1.56, 2.3, walnut, bevel=0.02, seg=2)
east_salon.cyl((X1 - 0.052, 1.48, 2.23), 0.05, 0.004, paper_m, axis=(-1, 0, 0), seg=24)
east_salon.tube([(X1 - 0.058, 1.48, 2.23), (X1 - 0.058, 1.52, 2.24)], 0.003, black, seg=5)
east_salon.tube([(X1 - 0.058, 1.48, 2.23), (X1 - 0.058, 1.47, 2.27)], 0.003, black, seg=5)
east_salon_ob = east_salon.build()
for name, kind, y, z, size in gallery:
    D.wall_picture(name, T.picture(name, kind), (X1 - 0.012, y, z), (size[0] - 0.04, size[1] - 0.04), "-x",
                   east_salon_ob)

# Le corridor, qu'on devine par la porte et la grande ouverture.
hall = C.Obj("Corridor")
hall.box(-3.0, -0.06, ZN, X0 - WALL, 0.0, ZS, floor_m)
hall.box(-3.12, 0, ZN, -3.0, CEIL, ZS, wall_m)
baseboard(hall, "z", -3.0, ZN, ZS, 1)
hall.box(-2.99, 1.55, 0.35, -2.97, 1.6, 1.15, walnut)
for zz in (0.45, 0.7, 0.95):
    hall.tube([(-2.97, 1.57, zz), (-2.9, 1.52, zz)], 0.008, brass, seg=6)
D.frame(hall, (-2.995, 1.5, -2.45), (0.3, 0.4), "+x", frame_black, mat_inner=paper_m)
hall_ob = hall.build()
D.wall_picture("cadre_corridor", T.picture("cadre_corridor", "paysage"), (-2.988, 1.5, -2.45), (0.26, 0.36), "+x", hall_ob)

# Le dessus de la maison coupée : un couvercle sombre au-dessus de chaque côté, et la moulure du haut des murs. Un par
# côté, pour que la vue du côté de la caméra puisse le cacher.
dark = M("coupe", "#000000", 1.0, emit="#1b110f", emit_power=1.0)
for side, cap, trim in (("Ouest", (-8.0, X0 - WALL, -8.0, 8.0), (X0 - WALL, X0, ZN - WALL, ZS + WALL)),
                        ("Est", (X1 + WALL, 8.0, -8.0, 8.0), (X1, X1 + WALL, ZN - WALL, ZS + WALL)),
                        ("Nord", (X0 - WALL, X1 + WALL, -8.0, ZN - WALL), (X0 - WALL, X1 + WALL, ZN - WALL, ZN)),
                        ("Sud", (X0 - WALL, X1 + WALL, ZS + WALL, 8.0), (X0 - WALL, X1 + WALL, ZS, ZS + WALL))):
    cut = C.Obj("Coupe" + side)
    cut.box(cap[0], CEIL, cap[2], cap[1], CEIL + 0.02, cap[3], dark)
    cut.box(trim[0] - 0.01, CEIL - 0.04, trim[2], trim[1] + 0.01, CEIL + 0.015, trim[3], plaster_trim, bevel=0.006, seg=1)
    cut.build()


# ---------------------------------------------------------------- la salle à manger

sam = C.Obj("SalleAManger")
# le buffet noir et ce qu'il porte (loin des deux endroits à nourriture)
bx0, bz0, bx1, bz1 = rect(SAM["obstacles"]["buffet"])
BH = SAM["surfaces"]["buffet"]
sam.box(bx0, 0.06, bz0, bx1, BH - 0.025, bz1 - 0.01, black, bevel=0.01, seg=1)
sam.box(bx0 - 0.01, BH - 0.025, bz0, bx1 + 0.01, BH, bz1, black, bevel=0.008, seg=1)
for lx in (bx0 + 0.05, bx1 - 0.08):
    for lz in (bz0 + 0.04, bz1 - 0.07):
        sam.box(lx, 0, lz, lx + 0.03, 0.06, lz + 0.03, black)
dw = (bx1 - bx0) / 4
for k in range(4):
    a = bx0 + k * dw
    sam.box(a + 0.012, 0.1, bz1 - 0.012, a + dw - 0.012, BH - 0.05, bz1 + 0.004, black, bevel=0.006, seg=1)
    sam.box(a + 0.04, 0.13, bz1 + 0.004, a + dw - 0.04, BH - 0.08, bz1 + 0.01, M("noir_panneau", "#232328", 0.5),
            bevel=0.004, seg=1)
    sam.cyl((a + (dw - 0.06 if k % 2 == 0 else 0.06), BH - 0.2, bz1 + 0.012), 0.012, 0.02, brass, axis=(0, 0, 1), seg=10)
# le tourne-disque au milieu, la pile de disques à l'est, les jeux de société à l'ouest
sam.box(-0.16, BH, -3.52, 0.26, BH + 0.11, -3.2, M("tourne_disque", "#7a5634", 0.4), bevel=0.012, seg=1)
sam.cyl((0.02, BH + 0.11, -3.36), 0.13, 0.008, M("plateau_disque", "#26262a", 0.3), seg=32)
sam.cyl((0.02, BH + 0.118, -3.36), 0.12, 0.003, vinyl[0], seg=32)
sam.cyl((0.02, BH + 0.121, -3.36), 0.04, 0.002, vinyl[4], seg=24)
sam.tube([(0.2, BH + 0.13, -3.26), (0.18, BH + 0.135, -3.38), (0.1, BH + 0.13, -3.42)], 0.005, brass, seg=6)
for k in range(9):
    tilt = Matrix.Translation((0.74, BH, -3.4)) @ Matrix.Rotation(0.12 - k * 0.03, 4, "Z") @ Matrix.Translation((-0.74, -BH, 3.4))
    sam.box(0.7 + k * 0.009, BH, -3.55, 0.706 + k * 0.009, BH + 0.31, -3.25, vinyl[k % len(vinyl)], matrix=tilt)
for k, (h_, m_) in enumerate(((0.05, game_box[0]), (0.04, game_box[1]), (0.06, game_box[2]))):
    y = BH + sum((0.05, 0.04, 0.06)[:k])
    sam.box(-0.76, y, -3.54 + k * 0.01, -0.58 + k * 0.01, y + h_, -3.28, m_, bevel=0.006, seg=1)
# l'étagère : montants de fer noir et quatre planches de bois blond, couvertes de céramiques
SH = (1.16, 1.5, 1.84, 2.18)
for ux in (-0.73, 0.69):
    sam.box(ux - 0.013, BH, -3.6, ux + 0.013, 2.42, -3.575, iron)
    sam.box(ux - 0.013, BH, -3.41, ux + 0.013, 2.42, -3.385, iron)
    for y in SH:
        sam.box(ux - 0.012, y - 0.02, -3.6, ux + 0.012, y, -3.385, iron)
for y in SH:
    sam.box(-0.78, y, -3.6, 0.74, y + 0.028, -3.36, blond, bevel=0.005, seg=1)
for y in SH[:3]:
    x = -0.66
    while x < 0.6:
        kind = rng.random()
        g = glazes[rng.randrange(len(glazes))]
        top = y + 0.028
        if kind < 0.45:
            D.cup(sam, (x, top, -3.47), 0.032, 0.07, g)
            x += 0.1
        elif kind < 0.7:
            D.bowl(sam, (x, top, -3.48), 0.055, 0.05, g)
            x += 0.13
        elif kind < 0.88:
            D.vase(sam, (x, top, -3.48), 0.04, rng.uniform(0.12, 0.2), g)
            x += 0.1
        else:
            for k in range(4):
                sam.cyl((x + 0.02, top + k * 0.012, -3.48), 0.08, 0.01, g, top=0.09, seg=22)
            x += 0.19
# sur la planche du haut : deux petits cadres appuyés, une plante qui retombe
top = SH[3] + 0.028
for k, (cx, kind, w_, h_) in enumerate(((-0.42, "aquarelle", 0.2, 0.26), (0.32, "motifs", 0.18, 0.22))):
    tilt = Matrix.Translation((cx, top, -3.5)) @ Matrix.Rotation(-0.12, 4, "X") @ Matrix.Translation((-cx, -top, 3.5))
    sam.box(cx - w_ / 2, top, -3.53, cx + w_ / 2, top + h_, -3.51, frame_black, matrix=tilt)
D.plant(sam, (-0.66, top, -3.48), 0.05, 0.12, 14, rng, pot, soil, [leaf, leaf_d, leaf_l], trailing=5)
D.vase(sam, (0.58, top, -3.47), 0.035, 0.16, glazes[5])
# la cage de Blanche : fil noir, porte ouverte vers la pièce, couverture et coussin mauve
cx0, cz0, cx1, cz1 = rect(SAM["obstacles"].get("cage", [-1.6, -3.58, -0.84, -3.0]))
CH = 0.62
sam.box(cx0, 0.0, cz0, cx1, 0.025, cz1, M("plateau_cage", "#2a2a2e", 0.5), bevel=0.006, seg=1)
bars = 0.055
x = cx0
while x <= cx1 + 1e-6:
    sam.tube([(x, 0.02, cz0), (x, CH, cz0)], 0.0035, iron, seg=5, caps=False)
    sam.tube([(x, CH, cz0), (x, CH, cz1)], 0.0035, iron, seg=5, caps=False)
    x += bars
z = cz0
while z <= cz1 + 1e-6:
    for xx in (cx0, cx1):
        sam.tube([(xx, 0.02, z), (xx, CH, z)], 0.0035, iron, seg=5, caps=False)
    sam.tube([(cx0, CH, z), (cx1, CH, z)], 0.0035, iron, seg=5, caps=False)
    z += bars
for y in (0.02, 0.2, 0.4, CH):
    sam.tube([(cx0, y, cz1), (cx0, y, cz0), (cx1, y, cz0), (cx1, y, cz1)], 0.0045, iron, seg=5, caps=False)
sam.tube([(cx0, CH, cz1), (cx1, CH, cz1)], 0.0045, iron, seg=5, caps=False)
# la porte ouverte, rabattue contre le flanc ouest de la cage
door_w = cz1 - cz0 - 0.06
for k in range(10):
    zz = cz1 - 0.03 - k * door_w / 9
    sam.tube([(cx0 - 0.03, 0.04, zz), (cx0 - 0.03, CH - 0.03, zz)], 0.0035, iron, seg=5, caps=False)
for y in (0.04, CH - 0.03):
    sam.tube([(cx0 - 0.03, y, cz1 - 0.03), (cx0 - 0.03, y, cz1 - 0.03 - door_w)], 0.0045, iron, seg=5, caps=False)
sam.box(cx0 + 0.02, 0.025, cz0 + 0.02, cx1 - 0.02, 0.06, cz1 - 0.04, blanket_m, bevel=0.02, seg=2)
sam.box(cx0 + 0.25, 0.05, cz0 + 0.05, cx1 - 0.08, 0.1, cz0 + 0.24, cushion_m, bevel=0.03, seg=2)
# la table de bois foncé aux coins arrondis
tx0, tz0, tx1, tz1 = rect(SAM["hides"][0]["rect"])
TH = SAM["hides"][0]["height"]
sam.box(tx0, TH - 0.035, tz0, tx1, TH, tz1, table_wood, bevel=0.03, seg=3)
sam.box(tx0 + 0.06, TH - 0.1, tz0 + 0.06, tx1 - 0.06, TH - 0.035, tz1 - 0.06, table_wood)
for lx in (tx0 + 0.09, tx1 - 0.09):
    for lz in (tz0 + 0.09, tz1 - 0.09):
        sam.tube([(lx, TH - 0.1, lz), (lx, 0.0, lz)], [0.026, 0.016], table_wood, seg=10)
# la suspension : globe opale sur sa tige de laiton
pcx, pcz = (tx0 + tx1) / 2, (tz0 + tz1) / 2
sam.tube([(pcx, CEIL, pcz), (pcx, 2.08, pcz)], 0.007, brass, seg=8)
sam.cyl((pcx, 2.06, pcz), 0.024, 0.03, brass, seg=12)
sam.ball((pcx, 1.95, pcz), 0.115, opal, seg=24, rings=16)
sam.build()

# Les chaises scandinaves : dossier courbé de noyer, siège noir rembourré ; une par objet, pour qu'elles vacillent.
seat_m = M("siege_noir", "#202024", 0.85)
for name, c in SAM["chairs"].items():
    px, pz = c["pos"]
    back = -1 if pz < (tz0 + tz1) / 2 else 1        # le dossier est du côté opposé à la table
    ch = C.Obj("Chaise_" + name, origin=(px, 0, pz))
    ch.box(px - 0.21, 0.42, pz - 0.2, px + 0.21, 0.48, pz + 0.2, seat_m, bevel=0.025, seg=2)
    for dx in (-0.17, 0.17):
        for dz in (-0.16, 0.16):
            lean = 0.03 * (1 if dz * back > 0 else -0.3)
            ch.tube([(px + dx, 0.43, pz + dz), (px + dx * 1.1, 0.0, pz + dz + lean * back)], [0.02, 0.013], walnut, seg=8)
    zb = pz + back * 0.19
    for dx in (-0.17, 0.17):
        ch.tube([(px + dx, 0.45, zb), (px + dx, 0.8, zb + back * 0.05)], 0.016, walnut, seg=8)
    path = [(px - 0.21, 0.74, zb + back * 0.02), (px, 0.75, zb + back * 0.07), (px + 0.21, 0.74, zb + back * 0.02)]
    pts, radii = C.curve(path, [0.05, 0.05, 0.05], 6)
    ch.tube(pts, radii, walnut, seg=10, squash=(1.0, 0.35))
    ch.build()

# Le couvert de chaque place : assiette de grès, fourchette sur sa serviette, couteau, verre d'eau. Le jeu ne montre
# que ceux des places occupées (Couvert_<chaise>). Les verres vont vers le milieu de la table, loin des endroits à
# nourriture des bouts de la table.
plate_m = M("assiette_gres", "#f4efe4", 0.3)
plate_rim = M("assiette_bord", "#4f7f8c", 0.3)
sauce_m = M("assiette_sauce", "#a4472c", 0.45)
cutlery = M("ustensiles", "#d9dde2", 0.25, 0.85)
napkin_m = mat("serviette_table", T.fabric("serviette_table", "#d8a33a", 0.3, 9))
wine_glass = M("verre_vin", "#e8eef2", 0.04, alpha=0.22)
water = M("eau_verre", "#cfe6f0", 0.05, alpha=0.35)
tcx = (tx0 + tx1) / 2
for name, c in SAM["chairs"].items():
    px, pz = c["pos"]
    toward = 1 if pz < (tz0 + tz1) / 2 else -1        # vers la table, en z
    side = 1 if px < tcx else -1                       # vers le milieu de la table, en x
    left = toward                                       # la gauche de qui est assis (face à la table)
    cv = C.Obj("Couvert_" + name, origin=(px, TH, pz))
    plz = (tz0 + 0.19) if toward == 1 else (tz1 - 0.19)
    cv.cyl((px, TH, plz), 0.125, 0.012, plate_m, seg=36, top=0.13, bevel=0.003)
    cv.torus((px, TH + 0.013, plz), 0.112, 0.006, plate_rim, seg=40, sides=6)
    cv.cyl((px, TH + 0.012, plz), 0.085, 0.003, plate_m, seg=32)
    # un reste de sauce et un bout de croûte : on a déjà commencé
    cv.ball((px + 0.03 * side, TH + 0.016, plz + 0.02 * toward), (0.045, 0.004, 0.03), sauce_m, seg=14, rings=6)
    cv.ball((px - 0.035 * side, TH + 0.018, plz - 0.025 * toward), (0.018, 0.008, 0.012), M("croute", "#d8a85c", 0.6),
            seg=10, rings=6)
    # la serviette pliée et la fourchette à gauche (les dents vers le milieu de la table), le couteau à droite
    fx = px + 0.17 * left
    cv.box(fx - 0.045, TH, plz - 0.07, fx + 0.045, TH + 0.008, plz + 0.07, napkin_m, bevel=0.003, seg=1)
    za, zb = plz - 0.075 * toward, plz + 0.03 * toward
    cv.box(fx - 0.005, TH + 0.008, min(za, zb), fx + 0.005, TH + 0.012, max(za, zb), cutlery, bevel=0.001, seg=1)
    cv.box(fx - 0.011, TH + 0.008, min(zb, zb + 0.012 * toward), fx + 0.011, TH + 0.012, max(zb, zb + 0.012 * toward),
           cutlery)
    for k in range(4):
        tine_x = fx - 0.0095 + k * 0.0063
        z0_, z1_ = zb + 0.01 * toward, zb + 0.05 * toward
        cv.box(tine_x - 0.0013, TH + 0.0085, min(z0_, z1_), tine_x + 0.0013, TH + 0.0115, max(z0_, z1_), cutlery)
    kx = px - 0.16 * left
    cv.box(kx - 0.007, TH, plz - 0.09, kx + 0.007, TH + 0.005, plz + 0.09, cutlery, bevel=0.001, seg=1)
    # le verre d'eau (il va avec tous les repas, et Charlotte aussi y a droit)
    gx, gz = px + 0.15 * side, plz + 0.16 * toward
    cv.cyl((gx, TH, gz), 0.029, 0.1, wine_glass, seg=24, top=0.033)
    cv.cyl((gx, TH + 0.004, gz), 0.026, 0.07, water, seg=20, top=0.029)
    cv.build()

# La lampe sur pied en laiton, au globe de verre fumé (entre la salle à manger et le salon).
lx0, lz0, lx1, lz1 = rect(SAM["obstacles"]["lampe_pied"])
lcx, lcz = (lx0 + lx1) / 2, (lz0 + lz1) / 2
lamp = C.Obj("Lampe")
lamp.cyl((lcx, 0, lcz), 0.12, 0.02, brass, top=0.11, seg=28, bevel=0.006)
lamp.tube([(lcx, 0.02, lcz), (lcx, 1.55, lcz)], 0.011, brass, seg=10)
arc = [(lcx, 1.55, lcz), (lcx - 0.05, 1.66, lcz), (lcx - 0.16, 1.68, lcz), (lcx - 0.24, 1.62, lcz)]
pts, radii = C.curve(arc, [0.011] * 4, 6)
lamp.tube(pts, radii, brass, seg=8)
lamp.ball((lcx - 0.26, 1.48, lcz), 0.12, smoke, seg=24, rings=16)
lamp.build()
# l'ampoule à part : le jeu l'éteint pendant le film
light_bulb = C.Obj("Ampoule")
light_bulb.ball((lcx - 0.26, 1.49, lcz), 0.035, bulb, seg=12, rings=8)
light_bulb.build()


# ---------------------------------------------------------------- le salon

# le tapis d'Orient délavé du salon, sous la table basse : à plat sous la zone cachée (moins de 6 mm)
rug_img = T.oriental_rug("tapis_salon")
rug_mat = M("tapis_salon", "#ffffff", 0.96)
rug_node = rug_mat.node_tree.nodes.new("ShaderNodeTexImage")
rug_node.image = rug_img
rug_mat.node_tree.links.new(rug_node.outputs["Color"], rug_mat.node_tree.nodes["Principled BSDF"].inputs["Base Color"])
rx0, rz0, rx1, rz1 = -0.72, 1.64, 1.02, 3.0
rug_ob = D.picture("Tapis", [(rx0, 0.004, rz1), (rx1, 0.004, rz1), (rx1, 0.004, rz0), (rx0, 0.004, rz0)], rug_mat)

salon = C.Obj("Salon")
OB = SALON["obstacles"]
# le divan de velours côtelé moutarde, dos à la salle à manger
sx0, sz0, sx1, sz1 = rect(OB["divan"])
salon.box(sx0 + 0.04, 0.08, sz0 + 0.04, sx1 - 0.04, 0.4, sz1 - 0.02, mustard, bevel=0.05, seg=2)
for lx in (sx0 + 0.08, sx1 - 0.08):
    for lz in (sz0 + 0.08, sz1 - 0.08):
        salon.cyl((lx, 0.0, lz), 0.022, 0.08, walnut, top=0.026, seg=10)
for a, b in ((sx0, sx0 + 0.17), (sx1 - 0.17, sx1)):
    salon.box(a, 0.08, sz0 + 0.02, b, 0.64, sz1, mustard, bevel=0.07, seg=3)
mid = (sx0 + sx1) / 2
for a, b in ((sx0 + 0.17, mid), (mid, sx1 - 0.17)):
    salon.box(a + 0.01, 0.38, sz0 + 0.3, b - 0.01, 0.55, sz1 - 0.01, mustard, bevel=0.07, seg=3)
    tilt = Matrix.Translation(((a + b) / 2, 0.45, sz0 + 0.2)) @ Matrix.Rotation(-0.18, 4, "X") \
        @ Matrix.Translation((-(a + b) / 2, -0.45, -(sz0 + 0.2)))
    salon.box(a + 0.015, 0.4, sz0 + 0.05, b - 0.015, 0.9, sz0 + 0.3, mustard, bevel=0.09, seg=3, matrix=tilt)
salon.box(sx0 + 0.02, 0.38, sz0 + 0.0, sx1 - 0.02, 0.82, sz0 + 0.12, mustard, bevel=0.05, seg=2)
# la table basse rétro, sa tablette du dessous
cx0_, cz0_, cx1_, cz1_ = rect(OB["table_basse"])
LH = SALON["surfaces"]["low"]
salon.box(cx0_, LH - 0.03, cz0_, cx1_, LH, cz1_, teak, bevel=0.012, seg=2)
salon.box(cx0_ + 0.08, 0.14, cz0_ + 0.06, cx1_ - 0.08, 0.16, cz1_ - 0.06, teak, bevel=0.005, seg=1)
for lx, sxn in ((cx0_ + 0.07, -1), (cx1_ - 0.07, 1)):
    for lz, szn in ((cz0_ + 0.06, -1), (cz1_ - 0.06, 1)):
        salon.tube([(lx, LH - 0.03, lz), (lx + sxn * 0.04, 0.0, lz + szn * 0.03)], [0.018, 0.011], teak, seg=8)
# le piano numérique noir, et la télé au-dessus
px0, pz0, px1, pz1 = rect(OB["piano"])
PH = SALON["surfaces"]["piano"]
salon.box(px0, 0.0, pz1 - 0.06, px0 + 0.04, PH, pz1, piano_black)
salon.box(px1 - 0.04, 0.0, pz1 - 0.06, px1, PH, pz1, piano_black)
for sx in (px0, px1 - 0.04):
    salon.box(sx, 0.0, pz0 + 0.04, sx + 0.04, 0.68, pz1 - 0.04, piano_black, bevel=0.008, seg=1)
salon.box(px0, 0.62, pz0 + 0.02, px1, 0.7, pz1, piano_black, bevel=0.01, seg=1)
salon.box(px0 + 0.05, 0.7, pz0 + 0.06, px1 - 0.05, 0.72, pz0 + 0.2, key_white)
k = 0
x = px0 + 0.06
while x < px1 - 0.07:
    if k % 7 not in (2, 6):
        salon.box(x + 0.012, 0.72, pz0 + 0.12, x + 0.022, 0.735, pz0 + 0.2, piano_black)
    x += 0.0236
    k += 1
salon.box(px0, 0.7, pz0 + 0.2, px1, PH, pz1, piano_black, bevel=0.012, seg=1)
salon.box(px0 + 0.1, PH, pz1 - 0.14, px1 - 0.1, PH + 0.22, pz1 - 0.12, piano_black, bevel=0.006, seg=1)
salon.box(px0 + 0.48, 0.0, pz0 + 0.16, px1 - 0.48, 0.05, pz0 + 0.3, piano_black, bevel=0.01, seg=1)
for k in range(3):
    salon.box(px0 + 0.52 + k * 0.06, 0.05, pz0 + 0.17, px0 + 0.55 + k * 0.06, 0.06, pz0 + 0.26, brass)
tvx = (px0 + px1) / 2
salon.box(tvx - 0.64, 1.12, ZS - 0.07, tvx + 0.64, 1.88, ZS - 0.02, piano_black, bevel=0.012, seg=1)
salon.box(tvx - 0.1, 1.3, ZS - 0.02, tvx + 0.1, 1.6, ZS, iron)
# le fauteuil marine, tourné vers la pièce
ax0, az0, ax1, az1 = rect(OB["fauteuil_marine"])
salon.box(ax0 + 0.06, 0.14, az0 + 0.04, ax1 - 0.02, 0.42, az1 - 0.04, navy, bevel=0.05, seg=2)
salon.box(ax0, 0.14, az0 + 0.04, ax0 + 0.16, 0.86, az1 - 0.04, navy, bevel=0.07, seg=3)
for a, b in ((az0, az0 + 0.12), (az1 - 0.12, az1)):
    salon.box(ax0 + 0.06, 0.14, a, ax1 - 0.04, 0.62, b, navy, bevel=0.05, seg=2)
for lx in (ax0 + 0.1, ax1 - 0.08):
    for lz in (az0 + 0.1, az1 - 0.1):
        salon.tube([(lx, 0.15, lz), (lx + (0.02 if lx > ax0 + 0.2 else -0.02), 0.0, lz)], [0.018, 0.012], blond, seg=8)
# le fauteuil berçant blanc à structure de bois blond, tourné vers l'ouest
rx0, rz0, rx1, rz1 = rect(OB["berceuse"])
for rz in (rz0 + 0.05, rz1 - 0.05):
    runner = [(rx0 + 0.02, 0.06, rz), (rx0 + 0.3, 0.01, rz), (rx1 - 0.08, 0.03, rz), (rx1 - 0.06, 0.5, rz),
              (rx1 - 0.02, 0.95, rz)]
    pts, radii = C.curve(runner, [0.022] * 5, 5)
    salon.tube(pts, radii, blond, seg=8, squash=(0.6, 1.0))
    salon.tube([(rx0 + 0.04, 0.06, rz), (rx0 + 0.06, 0.45, rz), (rx0 + 0.28, 0.5, rz)], 0.02, blond, seg=8)
cush = [(rx0 + 0.08, 0.42, 0), (rx0 + 0.4, 0.36, 0), (rx1 - 0.12, 0.46, 0), (rx1 - 0.05, 0.92, 0)]
pts, _ = C.curve(cush, [0.0] * 4, 5)
for k in range(len(pts) - 1):
    a, b = pts[k], pts[k + 1]
    salon.box(min(a[0], b[0]) - 0.02, min(a[1], b[1]) - 0.035, rz0 + 0.07, max(a[0], b[0]) + 0.02,
              max(a[1], b[1]) + 0.035, rz1 - 0.07, white_cushion, bevel=0.03, seg=2)
# la plante sur sa petite boîte de bois, et le panier
bx0_, bz0_, bx1_, bz1_ = rect(OB["plante"])
salon.box(bx0_ + 0.02, 0.0, bz0_ + 0.02, bx1_ - 0.02, 0.26, bz0_ + 0.22, blond, bevel=0.01, seg=1)
D.plant(salon, ((bx0_ + bx1_) / 2, 0.26, bz0_ + 0.12), 0.06, 0.22, 26, rng, pot, soil, [leaf, leaf_d, leaf_l])
salon.box(bx0_ + 0.06, 0.0, bz1_ - 0.12, bx1_ - 0.04, 0.18, bz1_ - 0.01, basket_m, bevel=0.03, seg=2)
# l'étagère de coin ancienne, en bois foncé
ex0, ez0, ex1, ez1 = rect(OB["etagere_coin"])
for k, y in enumerate((0.0, 0.42, 0.8, 1.18, 1.56)):
    salon.box(ex0 + 0.03, y, ez0 + 0.03, ex1, y + 0.03, ez1, corner_wood, bevel=0.006, seg=1)
salon.box(ex0 + 0.03, 0.0, ez0 + 0.03, ex0 + 0.06, 1.62, ez0 + 0.06, corner_wood)
salon.box(ex0 + 0.03, 0.0, ez1 - 0.04, ex0 + 0.06, 1.62, ez1, corner_wood)
salon.box(ex1 - 0.04, 0.0, ez0 + 0.03, ex1, 1.62, ez0 + 0.06, corner_wood)
for k, y in enumerate((0.45, 0.83, 1.21)):
    D.vase(salon, (ex0 + 0.2, y, ez0 + 0.22), 0.035, 0.14, glazes[(k * 3) % len(glazes)])
    salon.box(ex0 + 0.26, y, ez1 - 0.12, ex1 - 0.04, y + 0.16, ez1 - 0.1, frame_black, bevel=0.004, seg=1)
# le radiateur blanc sous la fenêtre
gx0, gz0, gx1, gz1 = rect(OB["radiateur"])
n_cols = 16
for k in range(n_cols):
    x = gx0 + (k + 0.5) * (gx1 - gx0) / n_cols
    salon.box(x - 0.022, 0.12, gz0 + 0.03, x + 0.022, 0.62, gz1 - 0.02, radiator_m, bevel=0.012, seg=1)
salon.box(gx0, 0.06, gz0 + 0.06, gx1, 0.12, gz1 - 0.04, radiator_m)
salon.box(gx0, 0.6, gz0 + 0.06, gx1, 0.64, gz1 - 0.04, radiator_m, bevel=0.01, seg=1)
# le coussin de Blanche près du radiateur
qx0, qz0, qx1, qz1 = rect(SALON["cushion"])
salon.box(qx0, 0.0, qz0, qx1, 0.07, qz1, dog_bed, bevel=0.035, seg=3)
salon.torus(((qx0 + qx1) / 2, 0.06, (qz0 + qz1) / 2), min(qx1 - qx0, qz1 - qz0) / 2 - 0.04, 0.035, dog_bed, seg=28,
            sides=8, squash=(qz1 - qz0) / (qx1 - qx0))
salon.build()

# Les écrans de la télé : la partie de hockey, le film, ou éteint (le jeu en montre un seul).
for name, kind, glow in (("EcranHockey", "hockey", 1.3), ("EcranFilm", "film", 1.3), ("EcranNoir", None, 0.0)):
    if kind is None:
        o = C.Obj(name)
        o.box(tvx - 0.6, 1.16, ZS - 0.075, tvx + 0.6, 1.84, ZS - 0.07, M("ecran_noir", "#08090b", 0.15))
        o.build()
    else:
        D.wall_picture(name, T.screen("ecran_" + kind, kind), (tvx, 1.5, ZS - 0.074), (1.2, 0.68), "-z", None, emit=glow)


# ---------------------------------------------------------------- Noël : montré seulement au party des Fêtes

xmas = C.Obj("Noel")
pine = M("sapin", "#1f5c38", 0.8)
pine_l = M("sapin_clair", "#2f7a46", 0.8)
bulbs = [M(f"ampoule_noel{i}", c, 0.3, emit=c, emit_power=3.0) for i, c in enumerate(("#ff4a3d", "#ffc23d", "#4fd56a", "#58a8ff"))]
ribbon = M("ruban", "#c8202c", 0.45)
gold_ball = M("boule_or", "#d8b04a", 0.25, 0.8)
# le sapin, dans le coin nord-est de la salle à manger
fx0, fz0, fx1, fz1 = rect(FETES["obstacles"]["sapin"])
tcx, tcz = (fx0 + fx1) / 2, (fz0 + fz1) / 2
xmas.cyl((tcx, 0, tcz), 0.16, 0.22, M("pot_sapin", "#a0342c", 0.6), top=0.2, seg=20)
xmas.tube([(tcx, 0.2, tcz), (tcx, 2.05, tcz)], [0.04, 0.015], M("tronc", "#5a3d26", 0.9), seg=8)
for k in range(260):
    t_ = k / 260
    y = 0.35 + t_ * 1.65
    r = (1.0 - t_) * 0.34 + 0.04
    a = k * 2.39996
    at = Vector((tcx + math.cos(a) * r * 0.3, y, tcz + math.sin(a) * r * 0.3))
    d = Vector((math.cos(a), -0.35, math.sin(a)))
    D.blade(xmas, at, d, r * 0.95 + 0.06, 0.03, pine if k % 3 else pine_l)
    if k % 9 == 0:
        xmas.ball(tuple(at + d.normalized() * r * 0.9), 0.022, bulbs[(k // 9) % 4], seg=10, rings=8)
    elif k % 13 == 0:
        xmas.ball(tuple(at + d.normalized() * r * 0.8), 0.03, gold_ball if k % 2 else ribbon, seg=12, rings=8)
xmas.ball((tcx, 2.1, tcz), 0.05, M("etoile", "#ffd75a", 0.3, emit="#ffd75a", emit_power=2.5), seg=8, rings=5)
for k, (gx, gz, s, m_) in enumerate(((-0.12, 0.2, 0.16, ribbon), (0.14, 0.18, 0.13, game_box[1]), (0.0, 0.28, 0.11, game_box[3]))):
    xmas.box(tcx + gx - s / 2, 0, tcz + gz - s / 2 - 0.1, tcx + gx + s / 2, s * 0.8, tcz + gz + s / 2 - 0.1, m_, bevel=0.01, seg=1)
# une guirlande de sapin et de lumières sur l'étagère, une autre au-dessus de la fenêtre
def garland(points, sag, step=0.03):
    total = 0
    for a_, b_ in zip(points, points[1:]):
        a_, b_ = Vector(a_), Vector(b_)
        n_ = max(1, int((b_ - a_).length / step))
        for i_ in range(n_):
            t_ = i_ / n_
            p_ = a_.lerp(b_, t_) - Vector((0, sag * math.sin(t_ * math.pi), 0))
            for _ in range(2):
                d_ = Vector((rng.uniform(-1, 1), rng.uniform(-1, 0.7), rng.uniform(-1, 1)))
                D.blade(xmas, p_, d_, rng.uniform(0.045, 0.07), 0.009, pine if rng.random() < 0.6 else pine_l)
            if total % 5 == 2:
                xmas.ball(p_ + Vector((0, -0.03, 0)), 0.016, bulbs[(total // 5) % 4], seg=10, rings=8)
            total += 1


garland([(-0.78, 2.24, -3.39), (0.0, 2.24, -3.39), (0.74, 2.24, -3.39)], 0.08)
garland([(wx0 - 0.35, wy1 + 0.2, ZS - 0.1), ((wx0 + wx1) / 2, wy1 + 0.2, ZS - 0.1), (wx1 + 0.35, wy1 + 0.2, ZS - 0.1)], 0.1)
# un chemin de table rouge sur la table du buffet des Fêtes
xmas.box(tx0 + 0.05, TH, (tz0 + tz1) / 2 - 0.14, tx1 - 0.05, TH + 0.003, (tz0 + tz1) / 2 + 0.14, ribbon)
# les bas de Noël accrochés au buffet
for k, bx in enumerate((-0.62, -0.1, 0.4)):
    col = ribbon if k != 1 else pine_l
    xmas.tube([(bx, 0.68, bz1 + 0.03), (bx, 0.46, bz1 + 0.035), (bx + 0.07, 0.42, bz1 + 0.035)], [0.05, 0.048, 0.04],
              col, seg=12, squash=(1.0, 0.45))
    xmas.box(bx - 0.065, 0.66, bz1 + 0.01, bx + 0.065, 0.73, bz1 + 0.06, M("fourrure", "#f4f1ea", 1.0), bevel=0.02, seg=2)
xmas.build()

C.export("double_salon")


# ---------------------------------------------------------------- aperçus, une vue par mission

def preview(name, plan, show_noel=False, screen="EcranNoir"):
    hidden = set(plan.get("cache", []))
    for ob in C.bpy.data.objects:
        top_ = ob
        while top_.parent is not None:
            top_ = top_.parent
        ob.hide_render = top_.name in hidden or (top_.name == "Noel" and not show_noel) \
            or (top_.name.startswith("Ecran") and top_.name != screen)
    cam = plan["camera"]
    C.render(name, cam["pos"], cam["target"], cam["fov"])


preview("double_salon_salle_a_manger", SAM)
preview("double_salon_salon", SALON, screen="EcranHockey")
preview("double_salon_fetes", FETES, True)

