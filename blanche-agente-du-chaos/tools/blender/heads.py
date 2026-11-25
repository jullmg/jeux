"""Les têtes de Maman, Papa et Charlotte : un visage lisse d'une seule pièce, des yeux, des cils, des sourcils, une
chevelure fondue en une masse peinte et quatre bouches (le jeu n'en montre qu'une à la fois).

Ce qui distingue chaque tête est dans LOOKS ; les couleurs sont dans people.py. Utilisé par people.py.
"""
import math

import common as C
import bpy
from mathutils import Vector, noise
from mathutils.bvhtree import BVHTree

# Les mesures sont en mètres autour du centre de la tête, pour une tête d'échelle 1.
LOOKS = {
    # Maman : un ovale fin, des yeux soulignés, de longs cheveux ondulés.
    "maman": dict(
        size=0.95,
        # (x, y, z, rayons) ; les formes « paires » sont répétées de chaque côté
        shapes=((0, 0.004, -0.002, 0.083, 0.112, 0.099),       # le crâne
                (0, -0.040, 0.020, 0.058, 0.056, 0.067),       # le bas du visage, qui s'affine
                (0, -0.076, 0.052, 0.022, 0.021, 0.030)),      # le menton
        pairs=((0.031, -0.020, 0.057, 0.025, 0.023, 0.030),),  # les pommettes
        nose=dict(bridge=(0.0055, 0.0075), tip=0.0115, wing=0.0072),
        ear=0.083,
        eye=dict(x=0.036, y=0.007, size=1.12, lash=1.0, flick=True),
        brow=dict(arc=((0.0135, 0.0310), (0.025, 0.0353), (0.038, 0.0378), (0.051, 0.0364), (0.062, 0.0305)), thick=1.0),
        mouth=dict(y=-0.050, width=1.0, lips=1.0, grin=False),
        blush=(0.046, -0.026, 0.34),
        hair=dict(long=0.245, wave=0.013, part=0.022, forehead=0.076, narrow=0.885),
    ),
    # Papa : un visage plus large, la mâchoire carrée, la barbe de quelques jours, les cheveux courts relevés.
    "papa": dict(
        size=0.95,
        shapes=((0, 0.004, -0.002, 0.087, 0.113, 0.101),
                (0, -0.042, 0.016, 0.071, 0.056, 0.072),
                (0, -0.077, 0.048, 0.034, 0.024, 0.036)),
        pairs=((0.034, -0.016, 0.057, 0.024, 0.022, 0.028),
               (0.037, -0.058, 0.018, 0.027, 0.026, 0.036)),   # les coins de la mâchoire
        nose=dict(bridge=(0.0068, 0.0095), tip=0.0135, wing=0.0095),
        ear=0.088,
        eye=dict(x=0.035, y=0.008, size=0.94, lash=0.5, flick=False),
        brow=dict(arc=((0.0115, 0.0285), (0.024, 0.0315), (0.039, 0.0325), (0.052, 0.0315), (0.063, 0.0272)), thick=1.35),
        mouth=dict(y=-0.051, width=1.08, lips=0.62, grin=True),
        blush=(0.046, -0.024, 0.16),
        hair=dict(long=0.0, forehead=0.082),
    ),
    # Charlotte : une tête ronde d'enfant, de grands yeux placés bas, de petites joues pleines.
    "charlotte": dict(
        size=0.98,
        shapes=((0, 0.004, -0.002, 0.091, 0.108, 0.100),
                (0, -0.034, 0.022, 0.067, 0.051, 0.067),
                (0, -0.062, 0.050, 0.023, 0.019, 0.028)),
        pairs=((0.036, -0.028, 0.054, 0.030, 0.027, 0.032),),
        nose=dict(bridge=(0.0038, 0.0052), tip=0.0092, wing=0.0055),
        ear=0.090,
        eye=dict(x=0.038, y=-0.001, size=1.30, lash=0.75, flick=True),
        brow=dict(arc=((0.0170, 0.0270), (0.028, 0.0302), (0.040, 0.0315), (0.052, 0.0300), (0.061, 0.0255)), thick=0.72),
        mouth=dict(y=-0.046, width=0.86, lips=0.72, grin=True),
        blush=(0.050, -0.030, 0.46),
        hair=dict(long=0.300, wave=0.019, part=-0.014, forehead=0.070, narrow=0.955),
    ),
}


def build(who, armature, spec, hc, hr, rng):
    """`hc` : centre de la tête ; `hr` : échelle de la tête selon la taille du personnage."""
    look = LOOKS[who]
    hr *= look["size"]

    def H(x, y, z):
        return hc + Vector((x, y, z)) * hr

    surface = _face(armature, spec, look, hc, hr, H)
    _features(armature, spec, look, hr, H, surface)
    if look["hair"]["long"] > 0.0:
        _long_hair(armature, spec, look["hair"], hc, hr, H, rng)
    else:
        _short_hair(armature, spec, look["hair"], hc, hr, H, rng)
    _mouths(armature, spec, look["mouth"], hr, H, surface)


def _face(armature, spec, look, hc, hr, H):
    skin_m = C.material("peau_visage", "#ffffff", 0.6, vertex_colors=True)
    head = C.Obj("Visage")

    def ball(x, y, z, rx, ry, rz):
        head.ball(H(x, y, z), (rx * hr, ry * hr, rz * hr), skin_m, seg=32, rings=24)

    for shape in look["shapes"]:
        ball(*shape)
    for x, *rest in look["pairs"]:
        for s in (1, -1):
            ball(x * s, *rest)
    nose = look["nose"]
    tip, wing = nose["tip"], nose["wing"]
    head.tube([H(0, 0.004, 0.092), H(0, -0.016, 0.101)], [r * hr for r in nose["bridge"]], skin_m, seg=12)
    ball(0, -0.022, 0.103, tip, tip * 0.83, tip * 0.91)
    for s in (1, -1):
        ball(wing * 1.18 * s, -0.025, 0.099, wing, wing * 0.9, wing * 1.04)
    ob = head.build()
    C.remesh(ob, 0.0036, 24, 0.4)

    skin = C.vec(spec["skin"])
    blush = C.vec("#d9786c")
    rose = C.vec("#d98a7c")
    shade = C.vec("#c9876f")
    stubble = C.vec(spec["stubble"]) if "stubble" in spec else None
    bx, by, amount = look["blush"]
    eye, mouth = look["eye"], look["mouth"]

    def color_at(p):
        q = (p - hc) / hr
        c = skin.copy()
        if stubble is not None and q.z > -0.01:
            # la barbe : le bas des joues, le menton et le dessus de la lèvre, en grain irrégulier
            edge = -0.030 - 0.016 * (1.0 - min(1.0, abs(q.x) / 0.055)) * C.smoothstep(0.02, 0.05, abs(q.x))
            cover = C.smoothstep(edge + 0.008, edge - 0.012, q.y)
            moustache = (1.0 - C.smoothstep(0.5, 1.2, math.hypot(q.x / 0.030, (q.y - (mouth["y"] + 0.012)) / 0.008)))
            grain = 0.75 + 0.45 * noise.noise(p * 330.0)
            c = c.lerp(stubble, min(1.0, 0.72 * max(cover, moustache * 0.8) * grain))
        for s in (1, -1):
            d = math.hypot((q.x - bx * s) / 0.025, (q.y - by) / 0.017)
            if q.z > 0.03:
                c = c.lerp(blush, amount * (1.0 - C.smoothstep(0.2, 1.15, d)))
            # un creux d'ombre autour des yeux, pour qu'ils aient du relief
            d = math.hypot((q.x - eye["x"] * s) / 0.027, (q.y - eye["y"] - 0.003) / 0.019)
            if q.z > 0.06:
                c = c.lerp(shade, 0.22 * (1.0 - C.smoothstep(0.35, 1.1, d)))
        d = math.hypot(q.x / 0.016, (q.y + 0.022) / 0.013)
        if q.z > 0.09:
            c = c.lerp(rose, 0.30 * (1.0 - C.smoothstep(0.2, 1.0, d)))
        return c

    C.paint(ob, color_at)
    C.weigh(ob, lambda p: {"head": 1.0})
    C.skin(ob, armature)
    tree = BVHTree.FromPolygons([v.co.copy() for v in ob.data.vertices], [list(p.vertices) for p in ob.data.polygons])

    def surface(x, y, out=0.0):
        """Le point de la peau vu de face en (x, y), avancé de `out`."""
        start = H(x, y, 0.4)
        hit, _normal, _index, _distance = tree.ray_cast(Vector(C.G(start)), Vector(C.G((0, 0, -1))))
        z = -hit.y if hit else H(x, y, 0.09).z
        return Vector((start.x, start.y, z + out * hr))

    return surface


def _features(armature, spec, look, hr, H, surface):
    """Les yeux, les cils, les sourcils et les oreilles."""
    parts = C.Obj("Traits")
    M = C.material
    skin = M("peau", spec["skin"], 0.62)
    white = M("blanc_oeil", "#fbf7f3", 0.25)
    iris = M("iris", spec["eyes"], 0.12)
    ring = M("iris_bord", spec.get("eye_rim", "#34200f"), 0.12)
    pupil = M("pupille", "#140d0b", 0.1)
    shine = M("reflet", "#ffffff", 0.2, emit="#ffffff", emit_power=0.9)
    lash = M("cils", spec.get("lash", "#2a1a13"), 0.8)
    brow = M("sourcil", spec["brow"], 0.8)
    w = {"head": 1.0}
    eye = look["eye"]
    EX, EY, E, L = eye["x"], eye["y"], eye["size"], eye["lash"]
    arc, thick = look["brow"]["arc"], look["brow"]["thick"]
    for s in (1, -1):
        parts.ball(H(look["ear"] * s, -0.008, -0.006), (0.012 * hr, 0.025 * hr, 0.018 * hr), skin, weights=w)
        center = surface(EX * s, EY, -0.0042)
        front = center.z

        def disc(dx, dy, dz, rx, ry, rz, mat, **kw):
            p = Vector((center.x + dx * E * hr, center.y + dy * E * hr, front + dz * hr))
            parts.ball(p, (rx * E * hr, ry * E * hr, rz * hr), mat, weights=w, **kw)

        disc(0, 0, 0, 0.0205, 0.0138, 0.0078, white, seg=28, rings=18)
        disc(-0.0012 * s, -0.0006, 0.0064, 0.0112, 0.0116, 0.0030, ring, seg=24)
        disc(-0.0012 * s, -0.0006, 0.0071, 0.0096, 0.0100, 0.0030, iris, seg=24)
        disc(-0.0012 * s, -0.0006, 0.0094, 0.0050, 0.0053, 0.0016, pupil)
        disc(0.0030, 0.0040, 0.0110, 0.0028, 0.0028, 0.0012, shine, seg=10, rings=8)
        disc(-0.0042, -0.0030, 0.0106, 0.0012, 0.0012, 0.0008, shine, seg=8, rings=6)
        # la ligne des cils (la paupière du haut), qui dessine l'œil
        pts = []
        for i in range(9):
            t = -1.0 + 2.0 * i / 8
            x = EX * s + t * 0.0208 * E * s
            y = EY + 0.0138 * E * math.sqrt(max(0.0, 1.0 - (t * 0.94) ** 2)) - 0.0004
            pts.append(Vector((H(x, y, 0).x, H(x, y, 0).y,
                               front + (0.0072 * math.sqrt(max(0.0, 1.0 - t * t * 0.8)) + 0.0016) * hr)))
        radii = [0.0009, 0.0016, 0.0021, 0.0023, 0.0024, 0.0025, 0.0025, 0.0022, 0.0018]
        if eye["flick"]:
            # une petite pointe vers l'extérieur
            end = H(EX * s + 0.0245 * E * s, EY + 0.0085 * E, 0)
            pts.append(Vector((end.x, end.y, pts[-1].z - 0.002 * hr)))
            radii.append(0.0003)
        path, rr = C.curve(pts, [r * L * hr for r in radii], 3)
        parts.tube(path, rr, lash, seg=8, weights=w, cap_rings=2)
        # le sourcil : un arc doux
        path, rr = C.curve([surface(x * s, y, 0.0012) for x, y in arc],
                           [r * thick * hr for r in (0.0022, 0.0028, 0.0025, 0.0018, 0.0005)], 4)
        parts.tube(path, rr, brow, seg=8, weights=w, cap_rings=2)
    C.skin(parts.build(), armature)


def _cap(hair, mat, H, rx, ry, rz, back, limit_at):
    """La calotte : la sphère de la tête, arrêtée à la ligne des cheveux `limit_at(x, z)`."""
    verts, faces, seg, rings = [], [], 48, 32
    for i in range(rings + 1):
        lat = -math.pi / 2 + math.pi * i / rings
        for j in range(seg):
            lon = 2 * math.pi * j / seg
            x = math.cos(lat) * math.cos(lon) * rx
            y = math.sin(lat) * ry + 0.008
            z = math.cos(lat) * math.sin(lon) * rz + back
            limit = limit_at(x, z)
            if y < limit:
                y = limit
                x *= 0.92
                z *= 0.90
            verts.append(tuple(H(x, y, z)))
    for i in range(rings):
        for j in range(seg):
            a, b = i * seg + j, i * seg + (j + 1) % seg
            faces.append([a, a + seg, b + seg, b])
    hair.add(verts, faces, mat, smooth=True)


def _hair_paint(ob, spec, hc, hr, low, high):
    """Foncé à la racine, la couleur au milieu, plus clair aux pointes, avec des filets de mèches."""
    root = C.vec(spec["hair_root"])
    middle = C.vec(spec["hair2"])
    tips = C.vec(spec["hair"])

    def color_at(p):
        q = (p - hc) / hr
        angle = math.atan2(q.z, q.x)
        # le bruit varie vite autour de la tête et lentement de haut en bas
        streak = noise.noise(Vector((angle * 9.0, q.y * 7.0, math.hypot(q.x, q.z) * 20.0)))
        fine = noise.noise(Vector((angle * 23.0, q.y * 5.0, 3.0)))
        h = q.y + streak * 0.035
        if h > low:
            c = middle.lerp(root, C.smoothstep(low + 0.015, high, h))
        else:
            c = middle.lerp(tips, C.smoothstep(low, low - 0.095, h))
        return c * (1.0 + 0.22 * streak + 0.16 * fine)

    C.paint(ob, color_at)


def _long_hair(armature, spec, style, hc, hr, H, rng):
    """De longues mèches ondulées qui encadrent le visage sans le couvrir."""
    mat = C.material("cheveux_ombre", "#ffffff", 0.55, vertex_colors=True)
    hair = C.Obj("Cheveux")
    part, wave_size = style["part"], style["wave"]

    def limit_at(x, z):
        forehead = style["forehead"] - 3.6 * (x - part * 0.7) ** 2 - 1.4 * max(0.0, abs(x) - 0.044)
        sides = -0.040
        return sides + (forehead - sides) * C.smoothstep(-0.005, 0.045, z)

    _cap(hair, mat, H, 0.095, 0.128, 0.114, -0.010, limit_at)

    def lock(points, widths, squash=(1.0, 0.7)):
        # `narrow` resserre les mèches autour du visage
        path, radii = C.curve([H(x * style["narrow"], y, z) for x, y, z in points], [r * hr for r in widths], 5)
        hair.tube(path, radii, mat, seg=12, squash=squash, cap_rings=3)

    # la masse du dos, d'un côté à l'autre en passant par derrière
    count = 22
    for i in range(count):
        a = math.radians(-8 - i * (164 / (count - 1)))
        dx, dz = math.cos(a), math.sin(a)
        length = (style["long"] - 0.035 * abs(dx)) * rng.uniform(0.9, 1.1)
        pts, rr = [], []
        for j in range(8):
            t = j / 7
            y = 0.055 - t * (length + 0.055)
            spread = 0.095 + 0.022 * math.sin(math.pi * min(1.0, t * 1.35)) + 0.030 * t
            wave = math.sin(t * math.pi * 2.6 + i * 1.7) * wave_size * t
            pts.append((dx * spread + wave, y, dz * spread * 0.98 + wave * 0.5 - 0.006))
            rr.append(0.026 - 0.016 * t ** 2.4)
        lock(pts, rr)
    # devant : deux grandes mèches de chaque côté, de la raie aux tempes puis sur la poitrine, hors du visage
    stretch = style["long"] / 0.245
    for s in (1, -1):
        for k, (out, end, depth) in enumerate(((0.000, -0.235, 0.000), (0.010, -0.195, -0.028))):
            bend = (wave_size - 0.013) * (1 if k else -1)
            pts = [(part + 0.004 * s, 0.128 - k * 0.004, 0.030 + depth * 0.5),
                   (part + (0.050 if s * part >= 0 else 0.080) * s, 0.106 - k * 0.006, 0.062 + depth * 0.7),
                   ((0.096 + out) * s, 0.048, 0.050 + depth),
                   ((0.106 + out + bend) * s, -0.020, 0.040 + depth),
                   ((0.099 + out * 1.4 - bend) * s, -0.085 * stretch, 0.052 + depth),
                   ((0.116 + out * 1.4 + bend) * s, -0.150 * stretch, 0.070 + depth),
                   ((0.096 + out - bend) * s, end * stretch, 0.092 + depth)]
            lock(pts, [0.008, 0.019, 0.022, 0.021, 0.021, 0.018, 0.008], (1.0, 0.66))
        # une mèche en vague sur l'épaule
        lock([(0.100 * s, -0.030, -0.010), (0.128 * s, -0.100 * stretch, 0.012), (0.112 * s, -0.165 * stretch, 0.040),
              (0.136 * s, -0.215 * stretch, 0.050)], [0.016, 0.022, 0.017, 0.008])
    ob = hair.build()
    C.remesh(ob, 0.0042, 7, 0.42)
    _hair_paint(ob, spec, hc, hr, 0.0, 0.105)

    def weights_at(p):
        # de la tête au torse en douceur : un saut ferait déchirer les mèches quand elle tourne la tête
        t = C.smoothstep(0.045, 0.215, -(p.y - hc.y) / hr)
        return {"head": 1.0 - 0.94 * t, "chest": 0.94 * t}

    C.weigh(ob, weights_at)
    C.skin(ob, armature)


def _short_hair(armature, spec, style, hc, hr, H, rng):
    """Les cheveux courts : une calotte avec les tempes dégagées et des mèches relevées sur le dessus."""
    mat = C.material("cheveux_ombre", "#ffffff", 0.6, vertex_colors=True)
    hair = C.Obj("Cheveux")

    def limit_at(x, z):
        temples = 0.020 * math.exp(-((abs(x) - 0.052) / 0.020) ** 2)
        forehead = style["forehead"] + temples - 2.0 * max(0.0, abs(x) - 0.058)
        sides = -0.006 if z > -0.045 else -0.034
        return sides + (forehead - sides) * C.smoothstep(0.008, 0.058, z)

    _cap(hair, mat, H, 0.092, 0.120, 0.108, -0.006, limit_at)
    # le dessus : des mèches couchées de l'avant vers l'arrière, un peu relevées au front et vers la droite
    for i in range(60):
        row = i // 12
        x = -0.050 + 0.100 * (i % 12) / 11 + rng.uniform(-0.004, 0.004)
        z = 0.064 - row * 0.027 + rng.uniform(-0.004, 0.004)
        top = 0.008 + 0.120 * math.sqrt(max(0.15, 1 - (x / 0.092) ** 2 - ((z + 0.006) / 0.108) ** 2))
        lift = 0.0075 if row == 0 else 0.001
        lean = 0.012 + rng.uniform(-0.002, 0.003)
        path, radii = C.curve([H(x - lean * 0.4, top - 0.009, z + 0.008), H(x + lean * 0.2, top + lift - 0.002, z - 0.006),
                               H(x + lean, top - 0.007, z - 0.032)], [0.0075 * hr, 0.0090 * hr, 0.0028 * hr], 5)
        hair.tube(path, radii, mat, seg=8, squash=(1.0, 0.7), cap_rings=3)
    ob = hair.build()
    C.remesh(ob, 0.0030, 5, 0.36)
    _hair_paint(ob, spec, hc, hr, 0.075, 0.130)
    C.weigh(ob, lambda p: {"head": 1.0})
    C.skin(ob, armature)


def _mouths(armature, spec, style, hr, H, surface):
    M = C.material
    lips = M("levres", spec["lips"], 0.38)
    line = M("bouche_trait", spec.get("mouth_line", "#7a3b3a"), 0.7)
    inside = M("bouche", "#51222a", 0.8)
    teeth = M("dents", "#f7f2ea", 0.35)
    w = {"head": 1.0}
    my, wide, full = style["y"], style["width"], style["lips"]

    def along(mouth, points, radii, mat, out=0.001, seg=10):
        path, rr = C.curve([surface(x * wide, y, out) for x, y in points], [r * hr for r in radii], 4)
        mouth.tube(path, rr, mat, seg=seg, weights=w, cap_rings=3)

    def lip(mouth, points, radii, out=0.001):
        along(mouth, points, [r * full for r in radii], lips, out)

    def fill(mouth, upper, lower, mat, out):
        """La surface entre deux lignes de la bouche (le dedans, les dents)."""
        top, _ = C.curve([Vector((x * wide, y, 0)) for x, y in upper], [0] * len(upper), 6)
        bottom, _ = C.curve([Vector((x * wide, y, 0)) for x, y in lower], [0] * len(lower), 6)
        n, rows = min(len(top), len(bottom)), 5
        verts = []
        for i in range(n):
            for r in range(rows):
                p = top[i].lerp(bottom[i], r / (rows - 1))
                verts.append(tuple(surface(p.x, p.y, out)))
        faces = []
        for i in range(n - 1):
            for r in range(rows - 1):
                a = i * rows + r
                faces.append([a, a + 1, a + rows + 1, a + rows])
        mouth.add(verts, faces, mat, smooth=True, weights=w)

    def closed(mouth, corner, upper_dip):
        """Des lèvres fermées : `corner` relève (positif) ou abaisse les commissures."""
        edge = my + corner
        lip(mouth, [(-0.0255, edge), (-0.012, my + 0.0040), (-0.004, my + 0.0066), (0, my + upper_dip),
                    (0.004, my + 0.0066), (0.012, my + 0.0040), (0.0255, edge)],
            [0.0006, 0.0027, 0.0034, 0.0029, 0.0034, 0.0027, 0.0006])
        lip(mouth, [(-0.0225, edge - 0.0025), (-0.011, my - 0.0062), (0, my - 0.0080), (0.011, my - 0.0062),
                    (0.0225, edge - 0.0025)], [0.0009, 0.0037, 0.0047, 0.0037, 0.0009])
        along(mouth, [(-0.027, edge + 0.0004), (-0.012, my - 0.0004), (0, my + 0.0004), (0.012, my - 0.0004),
                      (0.027, edge + 0.0004)], [0.0005, 0.0011, 0.0012, 0.0011, 0.0005], line, 0.0022, 8)

    def grin(mouth):
        """Un grand sourire à pleines dents."""
        upper = [(-0.026, my + 0.0085), (-0.013, my + 0.0045), (0, my + 0.0040), (0.013, my + 0.0045), (0.026, my + 0.0085)]
        lower = [(-0.026, my + 0.0085), (-0.015, my - 0.0070), (0, my - 0.0110), (0.015, my - 0.0070), (0.026, my + 0.0085)]
        middle = [(-0.026, my + 0.0085), (-0.014, my - 0.0004), (0, my - 0.0018), (0.014, my - 0.0004), (0.026, my + 0.0085)]
        fill(mouth, upper, lower, inside, 0.0009)
        fill(mouth, upper, middle, teeth, 0.0016)
        lip(mouth, upper, [0.0008, 0.0025, 0.0024, 0.0025, 0.0008], 0.0018)
        lip(mouth, lower, [0.0008, 0.0029, 0.0034, 0.0029, 0.0008], 0.0016)

    for name in ("Sourire", "Neutre", "Ouverte", "Fachee"):
        mouth = C.Obj("Bouche" + name)
        if name == "Sourire":
            if style["grin"]:
                grin(mouth)
            else:
                closed(mouth, 0.0085, 0.0044)
        elif name == "Neutre":
            closed(mouth, 0.0010, 0.0046)
        elif name == "Fachee":
            closed(mouth, -0.0080, 0.0040)
        else:
            c = surface(0, my - 0.005, -0.0045)
            mouth.ball(c, (0.0175 * wide * hr, 0.0125 * hr, 0.0070 * hr), inside, weights=w)
            along(mouth, [(-0.0125, my + 0.0030), (0, my + 0.0045), (0.0125, my + 0.0030)], [0.0016, 0.0027, 0.0016], teeth,
                  0.0004)
            lip(mouth, [(-0.019, my - 0.002), (-0.009, my + 0.0075), (0, my + 0.0072), (0.009, my + 0.0075),
                        (0.019, my - 0.002)], [0.0012, 0.0029, 0.0027, 0.0029, 0.0012], 0.0018)
            lip(mouth, [(-0.019, my - 0.002), (-0.011, my - 0.0150), (0, my - 0.0182), (0.011, my - 0.0150),
                        (0.019, my - 0.002)], [0.0012, 0.0036, 0.0044, 0.0036, 0.0012], 0.0010)
        C.skin(mouth.build(), armature)
