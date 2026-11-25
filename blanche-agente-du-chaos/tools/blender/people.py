"""Maman, Papa et Charlotte : personnages stylisés sur un même squelette. Ils regardent vers +z.

Blender --background --python tools/blender/people.py
"""
import math
import pathlib
import random
import sys

sys.path.insert(0, str(pathlib.Path(__file__).parent))
import common as C  # noqa: E402
import heads  # noqa: E402
import bpy  # noqa: E402
from mathutils import Vector, noise  # noqa: E402
from mathutils.kdtree import KDTree  # noqa: E402


def _soft(parts, armature, color, voxel, smoothing, fold_heights, k, streaks=0.0):
    """Fond des pièces en une surface lisse, reprend leurs poids, puis y creuse des plis et peint le tissu."""
    source = [Vector(v) for v in parts.verts]
    weights = parts.groups
    tree = KDTree(len(source))
    for i, v in enumerate(source):
        tree.insert(v, i)
    tree.balance()
    ob = parts.build()
    ob.vertex_groups.clear()
    C.remesh(ob, voxel, smoothing, 0.35)

    def weights_at(p):
        total = {}
        for _co, i, d in tree.find_n(p, 8):
            w = 1.0 / (d + 0.006) ** 3
            for bone, share in weights[i].items():
                total[bone] = total.get(bone, 0.0) + share * w
        best = sorted(total.items(), key=lambda kv: -kv[1])[:3]
        s = sum(v for _, v in best)
        return {bone: v / s for bone, v in best}

    def fold(p):
        """Les plis : plus marqués près des coudes, de la taille et des genoux."""
        near = sum(math.exp(-((p.y - h) / (0.075 * k)) ** 2) for h in fold_heights)
        return noise.noise(Vector((p.x * 22.0, p.y * 55.0, p.z * 22.0))) * 0.0032 * k * min(1.0, near)

    if color is not None:
        folds = {}
        normals = [v.normal.copy() for v in ob.data.vertices]
        for i, v in enumerate(ob.data.vertices):
            p = Vector((v.co.x, v.co.z, -v.co.y))
            folds[i] = fold(p)
            v.co += normals[i] * folds[i]
        base = C.vec(color)
        index = iter(range(len(ob.data.vertices)))

        def color_at(p):
            i = next(index)
            grain = noise.noise(p * 260.0)
            cloud = noise.noise(p * 13.0)
            line = noise.noise(Vector((p.x * 210.0, p.y * 16.0, p.z * 210.0)))
            shade = 1.0 + 0.10 * grain + 0.07 * cloud + 0.16 * streaks * line * (0.5 if streaks >= 1.0 else 1.0) \
                + folds[i] * 22.0
            # un peu d'éclat dans les tissus très foncés, pour qu'on lise les plis
            return base * shade + Vector((1, 1, 1)) * 0.0025 * max(0.0, grain + cloud)

        C.paint(ob, color_at)
    C.weigh(ob, weights_at)
    C.skin(ob, armature)


def build(who, spec):
    C.reset()
    C._materials.clear()
    C._painted.clear()
    rng = random.Random(sum(map(ord, who)))
    k = spec["height"] / 1.66          # tout est dessiné pour 1,66 m puis mis à l'échelle
    child = spec.get("child", False)
    head_k = 1.2 if child else 1.0
    wide = spec.get("shoulders", 1.0)

    def P(x, y, z):
        return (x * k, y * k, z * k)

    # hauteurs
    hip_y, knee_y, ankle_y = 0.88, 0.47, 0.085
    chest_y, neck_y, head_y = 1.17, 1.40, 1.515
    sh_x = 0.185 * wide
    bones = [
        ("root", None, P(0, 0, 0), P(0, 0.1, 0)),
        ("hips", "root", P(0, hip_y, 0), P(0, 1.0, 0)),
        ("spine", "hips", P(0, 1.0, 0), P(0, chest_y, 0)),
        ("chest", "spine", P(0, chest_y, 0), P(0, neck_y - 0.03, 0)),
        ("neck", "chest", P(0, neck_y - 0.03, 0), P(0, head_y - 0.03, 0)),
        ("head", "neck", P(0, head_y - 0.03, 0), P(0, head_y + 0.15, 0)),
    ]
    for side, s in (("L", 1), ("R", -1)):
        bones += [
            ("arm" + side, "chest", P(sh_x * s, 1.33, 0), P((sh_x + 0.055) * s, 1.07, 0)),
            ("forearm" + side, "arm" + side, P((sh_x + 0.055) * s, 1.07, 0), P((sh_x + 0.085) * s, 0.83, 0.02)),
            ("hand" + side, "forearm" + side, P((sh_x + 0.085) * s, 0.83, 0.02), P((sh_x + 0.095) * s, 0.74, 0.03)),
            ("thigh" + side, "hips", P(0.09 * s, hip_y, 0), P(0.095 * s, knee_y, 0.005)),
            ("shin" + side, "thigh" + side, P(0.095 * s, knee_y, 0.005), P(0.095 * s, ankle_y, -0.01)),
            ("foot" + side, "shin" + side, P(0.095 * s, ankle_y, -0.01), P(0.095 * s, 0.03, 0.13)),
        ]
    armature = C.make_armature("Squelette", bones)

    M = C.material
    skin = M("peau", spec["skin"], 0.62)
    top = M("haut", spec["top"], 0.9)
    top2 = M("haut2", spec.get("top2", spec["top"]), 0.95)
    trim = M("bordure", spec.get("trim", spec["top"]), 0.9)
    pants = M("pantalon", spec["pants"], 0.85)
    shoes = M("chaussures", spec["shoes"], 0.7)

    body = C.Obj("Corps")
    # les parties fondues en une seule surface lisse : le haut (torse et bras), le bas (bassin et jambes), les mains
    shirt = C.Obj("Haut")
    trousers = C.Obj("Bas")
    hands = C.Obj("Mains")
    shirt_m = C.material("tissu_haut", "#ffffff", 0.92, vertex_colors=True)
    trousers_m = C.material("tissu_bas", "#ffffff", 0.9, vertex_colors=True)

    def blend(a, b, y, mid, half):
        """Poids qui passe de l'os a (en haut) à l'os b (en bas) autour de la hauteur mid."""
        t = max(0.0, min(1.0, (y / k - (mid - half)) / (2 * half)))
        return {a: t, b: 1.0 - t}

    def torso_w(v):
        y = v.y / k
        if y > 1.2:
            return {"chest": 1.0}
        if y > 1.08:
            return blend("chest", "spine", v.y, 1.14, 0.07)
        if y > 0.93:
            return blend("spine", "hips", v.y, 1.0, 0.07)
        return {"hips": 1.0}

    # bassin et torse
    hip_r = spec.get("hip_r", 0.15)
    trousers.tube([P(0, 0.84, 0), P(0, 0.93, 0), P(0, 1.0, 0)], [hip_r * 0.82 * k, hip_r * 0.94 * k, hip_r * 0.80 * k], trousers_m,
                  seg=28, squash=(1.0, 0.72), weights=torso_w)
    chest_r = spec.get("chest_r", 0.165)
    path, radii = C.curve([P(0, 0.94, 0), P(0, 1.03, 0.0), P(0, 1.12, 0.005), P(0, 1.22, 0.01), P(0, 1.30, 0.0), P(0, 1.36, 0)],
                          [r * k for r in (hip_r * 1.05, hip_r * 0.97, chest_r * 0.95, chest_r, chest_r * 0.97, 0.11)], 3)
    shirt.tube(path, radii, shirt_m, seg=32, squash=(spec.get("torso_x", 1.08) * wide, 0.70), weights=torso_w)
    body.torus(P(0, 0.945, 0), hip_r * 0.97 * k, 0.013 * k, top2, sides=8, squash=0.70, weights={"hips": 1.0})
    for side, s in (("L", 1), ("R", -1)):
        a, f, h = "arm" + side, "forearm" + side, "hand" + side
        shoulder = P(sh_x * 0.84 * s, 1.282, 0)
        elbow = P((sh_x + 0.055) * s, 1.07, 0)
        wrist = P((sh_x + 0.083) * s, 0.845, 0.018)

        def arm_w(v, a=a, f=f):
            if v.y / k > 1.27 and abs(v.x / k) < sh_x + 0.01:
                return {a: 0.55, "chest": 0.45}
            return blend(a, f, v.y, 1.07, 0.045)

        r = spec.get("arm_r", 0.054)
        path, radii = C.curve([shoulder, P((sh_x + 0.025) * s, 1.22, 0), elbow, P((sh_x + 0.07) * s, 0.96, 0.008), wrist],
                              [v * k for v in (r * 0.96, r * 0.96, r * 0.84, r * 0.76, r * 0.62)], 5)
        shirt.tube(path, radii, shirt_m, seg=18, weights=arm_w)
        body.torus(wrist, r * 0.62 * k, 0.012 * k, trim, axis=(0.12 * s, -1, 0.08), sides=8, weights={f: 1.0})
        # main : paume, pouce et doigts
        hw = {h: 1.0}
        palm = Vector(P((sh_x + 0.09) * s, 0.795, 0.025))
        hands.ball(palm, (0.022 * k, 0.045 * k, 0.034 * k), skin, weights=hw)
        for i in range(4):
            z = 0.001 + i * 0.0172
            base = Vector(P((sh_x + 0.092) * s, 0.775, z))
            long = 0.050 if i in (1, 2) else 0.042
            # des doigts un peu repliés vers la paume
            hands.tube([base, base + Vector((0.004 * s * k, -long * 0.62 * k, 0.005 * k)),
                        base + Vector((-0.010 * s * k, -long * k, 0.008 * k))], [0.0090 * k, 0.0082 * k, 0.0066 * k], skin,
                       seg=8, weights=hw, cap_rings=3)
        hands.tube([P((sh_x + 0.082) * s, 0.81, 0.045), P((sh_x + 0.07) * s, 0.765, 0.068)], [0.012 * k, 0.009 * k], skin,
                   seg=8, weights=hw, cap_rings=3)
        # jambe
        t, sh, ft = "thigh" + side, "shin" + side, "foot" + side

        def leg_w(v, t=t, sh=sh):
            if v.y / k > 0.84:
                return {t: 0.6, "hips": 0.4}
            return blend(t, sh, v.y, knee_y, 0.05)

        lr = spec.get("leg_r", 0.082)
        path, radii = C.curve([P(0.082 * s, 0.9, 0), P(0.092 * s, 0.68, 0.004), P(0.095 * s, knee_y, 0.005),
                               P(0.095 * s, 0.28, -0.004), P(0.095 * s, 0.105, -0.01)],
                              [v * k for v in (lr, lr * 0.86, lr * 0.66, lr * 0.62, lr * 0.5)], 5)
        trousers.tube(path, radii, trousers_m, seg=18, weights=leg_w)
        fw = {ft: 1.0}
        body.tube([P(0.095 * s, 0.05, -0.03), P(0.095 * s, 0.042, 0.115)], [0.055 * k, 0.048 * k], shoes, seg=16,
                  squash=(1.0, 0.75), weights=fw)
        body.cyl(P(0.095 * s, 0.06, -0.012), 0.046 * k, 0.07 * k, trim if child else shoes, seg=14, weights=fw)

    # cou et tête
    body.tube([P(0, 1.34, 0), P(0, 1.46, 0.004)], spec.get("neck_r", 0.047) * k, skin, seg=16,
              weights=lambda v: blend("neck", "chest", v.y, 1.37, 0.04))
    body.torus(P(0, 1.362, 0.002), (spec.get("neck_r", 0.047) + 0.016) * k, 0.017 * k, trim, sides=10, squash=0.9,
               weights={"chest": 1.0})
    hc = Vector(P(0, head_y + 0.035 * head_k, 0.006))
    hr = k * head_k

    # vêtements propres à chacun
    for decoration in spec.get("extras", []):
        decoration(body, P, k, torso_w, M)

    C.skin(body.build(), armature)
    waist = 1.0 * k
    _soft(shirt, armature, spec["top"], 0.0042, 10, [waist, 1.07 * k], k, streaks=1.0)
    _soft(trousers, armature, spec["pants"], 0.0042, 6, [knee_y * k, 0.86 * k], k, streaks=spec.get("denim", 0.0))
    _soft(hands, armature, None, 0.0022, 3, [], k)
    heads.build(who, armature, spec, hc, hr, rng)

    C.for_game(True)
    C.export(spec["file"])
    C.for_game(False)
    for o in bpy.data.objects:
        if o.name.startswith("Bouche") and o.name != "BoucheSourire":
            o.hide_render = True
    h = spec["height"]
    C.render(spec["file"], (0.9, h * 0.85, 2.7), (0.0, h * 0.52, 0), 36, (800, 1100))
    C.render(spec["file"] + "_tete", (0.16, h * 0.93, 0.85), (0.0, h * 0.91, 0), 26, (800, 800))


def emblem(body, P, k, torso_w, M):
    """Le motif du chandail de Maman : une grande forme arrondie en trois lignes."""
    for i, color in enumerate(("#c9ac4e", "#dcdcd6", "#c9ac4e")):
        m = M("motif%d" % i, color, 0.8)
        r = 0.062 - i * 0.014
        pts = [P(-r * 0.9, 1.2 + r * 0.75, 0.124), P(r * 0.35, 1.2 + r * 0.75, 0.128), P(r, 1.2, 0.128),
               P(r * 0.35, 1.2 - r * 0.75, 0.124), P(-r * 0.9, 1.2 - r * 0.75, 0.12)]
        path, radii = C.curve(pts, [0.0048 * k] * 5, 5)
        body.tube(path, radii, m, seg=8, weights=torso_w, cap_rings=2)


def open_hoodie(body, P, k, torso_w, M):
    """Le kangourou ouvert de Papa : t-shirt kaki visible au milieu, capuche dans le dos."""
    tee = M("tshirt", "#7b7a62", 0.9)
    sherpa = M("mouton", "#8a5a30", 1.0)
    pts = [P(0, 0.98, 0.112), P(0, 1.1, 0.122), P(0, 1.22, 0.13), P(0, 1.31, 0.11), P(0, 1.355, 0.065)]
    path, radii = C.curve(pts, [v * k for v in (0.035, 0.042, 0.05, 0.045, 0.03)], 4)
    body.tube(path, radii, tee, seg=14, squash=(1.35, 0.35), weights=torso_w)
    for s in (1, -1):
        pts = [P(0.04 * s, 0.97, 0.122), P(0.052 * s, 1.1, 0.132), P(0.062 * s, 1.22, 0.138), P(0.062 * s, 1.31, 0.12),
               P(0.058 * s, 1.37, 0.06)]
        path, radii = C.curve(pts, [v * k for v in (0.012, 0.014, 0.019, 0.022, 0.02)], 4)
        body.tube(path, radii, sherpa, seg=10, weights=torso_w)
    body.tube([P(-0.08, 1.34, -0.07), P(0, 1.30, -0.125), P(0.08, 1.34, -0.07)], [0.04 * k, 0.065 * k, 0.04 * k], sherpa,
              seg=14, weights={"chest": 1.0})


def fleece(body, P, k, torso_w, M):
    """La polaire crème de Charlotte : col et patte verts à boutons-pression."""
    sage = M("sauge", "#7ea58c", 0.95)
    snap = M("pression", "#eeeae0", 0.35, 0.4)
    pts = [P(0, 1.34, 0.085), P(0, 1.24, 0.131), P(0, 1.14, 0.123)]
    path, radii = C.curve(pts, [0.022 * k] * 3, 4)
    body.tube(path, radii, sage, seg=10, squash=(1.0, 0.45), weights=torso_w)
    for y, z in ((1.31, 0.112), (1.24, 0.144), (1.17, 0.14)):
        body.ball(P(0, y, z), 0.008 * k, snap, weights={"chest": 1.0}, seg=10, rings=8)
    for s in (1, -1):
        body.tube([P(0.012 * s, 1.355, 0.07), P(0.075 * s, 1.33, 0.088)], [0.022 * k, 0.012 * k], sage, seg=10,
                  squash=(1.0, 0.45), weights={"chest": 1.0})


build("maman", dict(
    file="maman", height=1.66, skin="#e8b49a", hair="#c7b193", hair2="#8c7055", hair_root="#463023", brow="#5a3d2a",
    eyes="#7a5426", lips="#c46e6c", top="#1d1c20", top2="#151418", trim="#26242a", pants="#2a2930", shoes="#c98a8f",
    hip_r=0.158, chest_r=0.155, shoulders=0.98, extras=[emblem]))

build("papa", dict(
    file="papa", height=1.82, skin="#dfaa8d", hair="#7d5b3c", hair2="#5e422c", hair_root="#422e1f", denim=1.0, brow="#4a321f",
    eyes="#6a93b3", eye_rim="#233a4c", lash="#6b4734", lips="#bd7a6c", mouth_line="#7d463d", stubble="#9a7260",
    top="#8a5a30", top2="#74491f", trim="#74491f", pants="#3f5675", shoes="#5b5a60", neck_r=0.057,
    hip_r=0.15, chest_r=0.17, shoulders=1.12, torso_x=0.97, arm_r=0.058, extras=[open_hoodie]))

build("charlotte", dict(
    file="charlotte", height=1.28, child=True, skin="#efbea2", hair="#b88e5e", hair2="#8c6440", hair_root="#5c3e28",
    brow="#7a5234", eyes="#5e3b20", lips="#cf756c", top="#eee5d2", top2="#d9cfba", trim="#7ea58c", pants="#8d6f86",
    shoes="#d98ab0", neck_r=0.042, hip_r=0.14, chest_r=0.15, shoulders=0.92, arm_r=0.056, leg_r=0.074,
    extras=[fleece]))
