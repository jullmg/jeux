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
from mathutils import Vector  # noqa: E402


def build(who, spec):
    C.reset()
    C._materials.clear()
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
    body.tube([P(0, 0.84, 0), P(0, 0.93, 0), P(0, 1.0, 0)], [hip_r * 0.85 * k, hip_r * k, hip_r * 0.9 * k], pants, seg=28,
              squash=(1.0, 0.72), weights=torso_w)
    chest_r = spec.get("chest_r", 0.165)
    path, radii = C.curve([P(0, 0.94, 0), P(0, 1.03, 0.0), P(0, 1.12, 0.005), P(0, 1.22, 0.01), P(0, 1.30, 0.0), P(0, 1.36, 0)],
                          [r * k for r in (hip_r * 0.98, hip_r * 0.92, chest_r * 0.95, chest_r, chest_r * 0.97, 0.11)], 3)
    body.tube(path, radii, top, seg=32, squash=(1.08 * wide, 0.70), weights=torso_w)
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
        body.tube(path, radii, top, seg=18, weights=arm_w)
        body.torus(wrist, r * 0.62 * k, 0.012 * k, trim, axis=(0.12 * s, -1, 0.08), sides=8, weights={f: 1.0})
        # main : paume, pouce et doigts
        hw = {h: 1.0}
        palm = Vector(P((sh_x + 0.09) * s, 0.795, 0.025))
        body.ball(palm, (0.024 * k, 0.045 * k, 0.034 * k), skin, weights=hw)
        for i in range(4):
            z = 0.002 + i * 0.016
            base = Vector(P((sh_x + 0.092) * s, 0.775, z))
            body.tube([base, base + Vector((0.004 * s * k, -0.052 * k, 0.006 * k))], [0.0095 * k, 0.0075 * k], skin, seg=8,
                      weights=hw, cap_rings=3)
        body.tube([P((sh_x + 0.082) * s, 0.81, 0.045), P((sh_x + 0.07) * s, 0.765, 0.068)], [0.012 * k, 0.009 * k], skin,
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
        body.tube(path, radii, pants, seg=18, weights=leg_w)
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

    ob = body.build()
    C.skin(ob, armature)
    heads.build(who, armature, spec, hc, hr, rng)

    heads.for_game(True)
    C.export(spec["file"])
    heads.for_game(False)
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
    file="papa", height=1.82, skin="#dfaa8d", hair="#7d5b3c", hair2="#5e422c", hair_root="#422e1f", brow="#4a321f",
    eyes="#6a93b3", eye_rim="#233a4c", lash="#6b4734", lips="#bd7a6c", mouth_line="#7d463d", stubble="#9a7260",
    top="#8a5a30", top2="#74491f", trim="#74491f", pants="#3f5675", shoes="#5b5a60", neck_r=0.057,
    hip_r=0.15, chest_r=0.18, shoulders=1.14, arm_r=0.062, extras=[open_hoodie]))

build("charlotte", dict(
    file="charlotte", height=1.28, child=True, skin="#efbea2", hair="#b88e5e", hair2="#8c6440", hair_root="#5c3e28",
    brow="#7a5234", eyes="#5e3b20", lips="#cf756c", top="#eee5d2", top2="#d9cfba", trim="#7ea58c", pants="#8d6f86",
    shoes="#d98ab0", neck_r=0.042, hip_r=0.14, chest_r=0.15, shoulders=0.92, arm_r=0.056, leg_r=0.074,
    extras=[fleece]))
