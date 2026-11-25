"""La tête de Maman : un visage lisse d'une seule pièce (joues rondes, petit nez), de grands yeux, des sourcils doux
et une longue chevelure ondulée, foncée à la racine et blonde aux pointes, qui encadre le visage sans le couvrir.

Utilisée par people.py. Les bouches sont des pièces à part : le jeu n'en montre qu'une à la fois.
"""
import math

import common as C
import bpy
from mathutils import Vector, noise
from mathutils.bvhtree import BVHTree


def _smoothstep(a, b, x):
    t = max(0.0, min(1.0, (x - a) / (b - a)))
    return t * t * (3 - 2 * t)


def _lin(hex_color):
    return Vector(C.lin(C.srgb(hex_color)))


def _remesh(ob, voxel, iterations, keep):
    """Fond les formes en une seule surface lisse."""
    bpy.context.view_layer.objects.active = ob
    ob.select_set(True)
    for kind, settings in (("REMESH", {"mode": "VOXEL", "voxel_size": voxel}),
                           ("SMOOTH", {"factor": 0.6, "iterations": iterations}),
                           ("DECIMATE", {"ratio": keep})):
        mod = ob.modifiers.new(kind.lower(), kind)
        for key, value in settings.items():
            setattr(mod, key, value)
        bpy.ops.object.modifier_apply(modifier=mod.name)
    ob.select_set(False)
    for p in ob.data.polygons:
        p.use_smooth = True


_painted = []


def _paint(ob, color_at):
    """Couleurs aux sommets ; `color_at` reçoit le point en coordonnées Godot."""
    colors = ob.data.color_attributes.new("Col", "FLOAT_COLOR", "POINT")
    for i, v in enumerate(ob.data.vertices):
        c = color_at(Vector((v.co.x, v.co.z, -v.co.y)))
        colors.data[i].color = (c.x, c.y, c.z, 1.0)
    _painted.append(ob)


def for_game(encode):
    """Le moteur du jeu (GL Compatibility) lit les couleurs des sommets en sRGB, Blender en linéaire : on les convertit
    juste pour l'exportation (`encode`), puis on les remet pour les aperçus."""
    def to_srgb(v):
        return v * 12.92 if v <= 0.0031308 else 1.055 * v ** (1 / 2.4) - 0.055

    def to_linear(v):
        return v / 12.92 if v <= 0.04045 else ((v + 0.055) / 1.055) ** 2.4

    convert = to_srgb if encode else to_linear
    for ob in _painted:
        for d in ob.data.color_attributes["Col"].data:
            r, g, b, a = d.color
            d.color = (convert(r), convert(g), convert(b), a)


def _weigh(ob, weights_at):
    groups = {}
    for i, v in enumerate(ob.data.vertices):
        for bone, w in weights_at(Vector((v.co.x, v.co.z, -v.co.y))).items():
            if bone not in groups:
                groups[bone] = ob.vertex_groups.new(name=bone)
            groups[bone].add([i], w, "REPLACE")


def build(armature, spec, hc, hr, rng):
    """`hc` : centre de la tête ; `hr` : échelle de la tête."""
    _painted.clear()

    def H(x, y, z):
        return hc + Vector((x, y, z)) * hr

    surface = _face(armature, spec, hc, hr, H)
    _features(armature, spec, hr, H, surface)
    _hair(armature, spec, hc, hr, H, rng)
    _mouths(armature, spec, hr, H, surface)


def _face(armature, spec, hc, hr, H):
    skin_m = C.material("peau_visage", "#ffffff", 0.6, vertex_colors=True)
    head = C.Obj("Visage")

    def ball(x, y, z, rx, ry, rz):
        head.ball(H(x, y, z), (rx * hr, ry * hr, rz * hr), skin_m, seg=32, rings=24)

    ball(0, 0.002, 0.0, 0.097, 0.115, 0.102)
    ball(0, -0.040, 0.020, 0.083, 0.066, 0.079)           # le bas du visage, plein et rond
    ball(0, -0.070, 0.044, 0.040, 0.032, 0.046)           # le menton
    for s in (1, -1):
        ball(0.030 * s, -0.030, 0.056, 0.036, 0.034, 0.039)   # les joues
    head.tube([H(0, 0.004, 0.092), H(0, -0.016, 0.101)], [0.0055 * hr, 0.0075 * hr], skin_m, seg=12)
    ball(0, -0.022, 0.103, 0.0115, 0.0095, 0.0105)        # le bout du nez
    for s in (1, -1):
        ball(0.0085 * s, -0.025, 0.099, 0.0072, 0.0065, 0.0075)
    ob = head.build()
    _remesh(ob, 0.0036, 24, 0.4)

    skin = _lin(spec["skin"])
    blush = _lin("#d9786c")
    rose = _lin("#d98a7c")
    shade = _lin("#c9876f")

    def color_at(p):
        q = (p - hc) / hr
        c = skin.copy()
        for s in (1, -1):
            d = math.hypot((q.x - 0.052 * s) / 0.028, (q.y + 0.030) / 0.019)
            if q.z > 0.03:
                c = c.lerp(blush, 0.34 * (1.0 - _smoothstep(0.2, 1.15, d)))
            # un creux d'ombre autour des yeux, pour qu'ils aient du relief
            d = math.hypot((q.x - 0.035 * s) / 0.027, (q.y - 0.010) / 0.019)
            if q.z > 0.06:
                c = c.lerp(shade, 0.22 * (1.0 - _smoothstep(0.35, 1.1, d)))
        d = math.hypot(q.x / 0.016, (q.y + 0.022) / 0.013)
        if q.z > 0.09:
            c = c.lerp(rose, 0.30 * (1.0 - _smoothstep(0.2, 1.0, d)))
        return c

    _paint(ob, color_at)
    _weigh(ob, lambda p: {"head": 1.0})
    C.skin(ob, armature)
    tree = BVHTree.FromPolygons([v.co.copy() for v in ob.data.vertices], [list(p.vertices) for p in ob.data.polygons])

    def surface(x, y, out=0.0):
        """Le point de la peau vu de face en (x, y), avancé de `out`."""
        start = H(x, y, 0.4)
        hit, _normal, _index, _distance = tree.ray_cast(Vector(C.G(start)), Vector(C.G((0, 0, -1))))
        z = -hit.y if hit else H(x, y, 0.09).z
        return Vector((start.x, start.y, z + out * hr))

    return surface


def _features(armature, spec, hr, H, surface):
    """Les yeux, les cils, les sourcils et les oreilles."""
    parts = C.Obj("Traits")
    M = C.material
    skin = M("peau", spec["skin"], 0.62)
    white = M("blanc_oeil", "#fbf7f3", 0.25)
    iris = M("iris", spec["eyes"], 0.12)
    ring = M("iris_bord", "#34200f", 0.12)
    pupil = M("pupille", "#140d0b", 0.1)
    shine = M("reflet", "#ffffff", 0.2, emit="#ffffff", emit_power=0.9)
    lash = M("cils", "#2a1a13", 0.8)
    brow = M("sourcil", spec["brow"], 0.8)
    w = {"head": 1.0}
    EX, EY = 0.036, 0.007
    E = 1.12          # la taille des yeux
    for s in (1, -1):
        parts.ball(H(0.096 * s, -0.008, -0.004), (0.014 * hr, 0.027 * hr, 0.019 * hr), skin, weights=w)
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
        # la ligne des cils, qui dessine l'œil et finit en petite pointe vers l'extérieur
        pts = []
        for i in range(9):
            t = -1.0 + 2.0 * i / 8
            x = EX * s + t * 0.0208 * E * s
            y = EY + 0.0138 * E * math.sqrt(max(0.0, 1.0 - (t * 0.94) ** 2)) - 0.0004
            pts.append(Vector((H(x, y, 0).x, H(x, y, 0).y,
                               front + (0.0072 * math.sqrt(max(0.0, 1.0 - t * t * 0.8)) + 0.0016) * hr)))
        pts.append(Vector((H(EX * s + 0.0245 * E * s, 0, 0).x, H(0, EY + 0.0085 * E, 0).y, pts[-1].z - 0.002 * hr)))
        radii = [0.0009, 0.0016, 0.0021, 0.0023, 0.0024, 0.0025, 0.0025, 0.0022, 0.0018, 0.0003]
        path, rr = C.curve(pts, [r * hr for r in radii], 3)
        parts.tube(path, rr, lash, seg=8, weights=w, cap_rings=2)
        # le sourcil : un arc doux, plus haut aux deux tiers
        arc = ((0.0135, 0.0310), (0.025, 0.0353), (0.038, 0.0378), (0.051, 0.0364), (0.062, 0.0305))
        path, rr = C.curve([surface(x * s, y, 0.0012) for x, y in arc],
                           [r * hr for r in (0.0022, 0.0028, 0.0025, 0.0018, 0.0005)], 4)
        parts.tube(path, rr, brow, seg=8, weights=w, cap_rings=2)
    C.skin(parts.build(), armature)


def _hair(armature, spec, hc, hr, H, rng):
    """De longues mèches fondues en une masse ondulée, peinte du foncé (racine) au blond (pointes)."""
    mat = C.material("cheveux_ombre", "#ffffff", 0.55, vertex_colors=True)
    hair = C.Obj("Cheveux")

    # la calotte : la sphère de la tête, sans le visage ; la raie un peu de côté dessine le front
    verts, faces, seg, rings = [], [], 48, 32
    for i in range(rings + 1):
        lat = -math.pi / 2 + math.pi * i / rings
        for j in range(seg):
            lon = 2 * math.pi * j / seg
            x = math.cos(lat) * math.cos(lon) * 0.108
            y = math.sin(lat) * 0.128 + 0.008
            z = math.cos(lat) * math.sin(lon) * 0.114 - 0.010
            forehead = 0.076 - 3.0 * (x - 0.018) ** 2 - 1.2 * max(0.0, abs(x) - 0.05)
            sides = -0.040
            blend = _smoothstep(-0.005, 0.045, z)
            limit = sides + (forehead - sides) * blend
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

    def lock(points, widths, squash=(1.0, 0.7)):
        path, radii = C.curve([H(*p) for p in points], [r * hr for r in widths], 5)
        hair.tube(path, radii, mat, seg=12, squash=squash, cap_rings=3)

    # la masse du dos, d'un côté à l'autre en passant par derrière
    count = 22
    for i in range(count):
        a = math.radians(-8 - i * (164 / (count - 1)))
        dx, dz = math.cos(a), math.sin(a)
        length = (0.245 - 0.035 * abs(dx)) * rng.uniform(0.9, 1.1)
        pts, rr = [], []
        for j in range(8):
            t = j / 7
            y = 0.055 - t * (length + 0.055)
            spread = 0.095 + 0.022 * math.sin(math.pi * min(1.0, t * 1.35)) + 0.030 * t
            wave = math.sin(t * math.pi * 2.6 + i * 1.7) * 0.013 * t
            pts.append((dx * spread + wave, y, dz * spread * 0.98 + wave * 0.5 - 0.006))
            rr.append(0.026 - 0.016 * t ** 2.4)
        lock(pts, rr)
    # devant : deux grandes mèches de chaque côté, qui partent de la raie, passent près des tempes puis tombent sur
    # la poitrine, toujours en dehors du visage
    for s in (1, -1):
        part = 0.022
        for k, (out, end, depth) in enumerate(((0.000, -0.235, 0.000), (0.010, -0.195, -0.028))):
            pts = [(part + 0.004 * s, 0.128 - k * 0.004, 0.030 + depth * 0.5),
                   (part + (0.050 if s > 0 else -0.080), 0.106 - k * 0.006, 0.062 + depth * 0.7),
                   ((0.096 + out) * s, 0.048, 0.050 + depth),
                   ((0.106 + out) * s, -0.020, 0.040 + depth),
                   ((0.099 + out * 1.4) * s, -0.085, 0.052 + depth),
                   ((0.116 + out * 1.4) * s, -0.150, 0.070 + depth),
                   ((0.096 + out) * s, end, 0.092 + depth)]
            lock(pts, [0.008, 0.019, 0.022, 0.021, 0.021, 0.018, 0.008], (1.0, 0.66))
        # une mèche en vague sur l'épaule
        lock([(0.100 * s, -0.030, -0.010), (0.128 * s, -0.100, 0.012), (0.112 * s, -0.165, 0.040),
              (0.136 * s, -0.215, 0.050)], [0.016, 0.022, 0.017, 0.008])
    ob = hair.build()
    _remesh(ob, 0.0042, 7, 0.42)

    root = _lin(spec["hair_root"])
    middle = _lin(spec["hair2"])
    tips = _lin(spec["hair"])

    def color_at(p):
        q = (p - hc) / hr
        angle = math.atan2(q.z, q.x)
        # des filets de mèches : le bruit varie vite autour de la tête et lentement de haut en bas
        streak = noise.noise(Vector((angle * 9.0, q.y * 7.0, math.hypot(q.x, q.z) * 20.0)))
        h = q.y + streak * 0.035
        if h > 0.0:
            c = middle.lerp(root, _smoothstep(0.015, 0.105, h))
        else:
            c = middle.lerp(tips, _smoothstep(0.0, -0.095, h))
        fine = noise.noise(Vector((angle * 23.0, q.y * 5.0, 3.0)))
        return c * (1.0 + 0.22 * streak + 0.16 * fine)

    _paint(ob, color_at)

    def weights_at(p):
        # de la tête au torse en douceur : un saut ferait déchirer les mèches quand elle tourne la tête
        t = _smoothstep(0.045, 0.215, -(p.y - hc.y) / hr)
        return {"head": 1.0 - 0.94 * t, "chest": 0.94 * t}

    _weigh(ob, weights_at)
    C.skin(ob, armature)


def _mouths(armature, spec, hr, H, surface):
    M = C.material
    lips = M("levres", spec["lips"], 0.38)
    line = M("bouche_trait", "#7a3b3a", 0.7)
    inside = M("bouche", "#51222a", 0.8)
    teeth = M("dents", "#f7f2ea", 0.35)
    w = {"head": 1.0}
    my = -0.050

    def along(mouth, points, radii, mat, out=0.001, seg=10):
        path, rr = C.curve([surface(x, y, out) for x, y in points], [r * hr for r in radii], 4)
        mouth.tube(path, rr, mat, seg=seg, weights=w, cap_rings=3)

    def closed(mouth, corner, upper_dip):
        """Des lèvres fermées : `corner` relève (positif) ou abaisse les commissures."""
        edge = my + corner
        along(mouth, [(-0.0255, edge), (-0.012, my + 0.0040), (-0.004, my + 0.0066), (0, my + upper_dip), (0.004, my + 0.0066),
                      (0.012, my + 0.0040), (0.0255, edge)],
              [0.0006, 0.0027, 0.0034, 0.0029, 0.0034, 0.0027, 0.0006], lips)
        along(mouth, [(-0.0225, edge - 0.0025), (-0.011, my - 0.0062), (0, my - 0.0080), (0.011, my - 0.0062),
                      (0.0225, edge - 0.0025)], [0.0009, 0.0037, 0.0047, 0.0037, 0.0009], lips)
        along(mouth, [(-0.027, edge + 0.0004), (-0.012, my - 0.0004), (0, my + 0.0004), (0.012, my - 0.0004),
                      (0.027, edge + 0.0004)], [0.0005, 0.0011, 0.0012, 0.0011, 0.0005], line, 0.0022, 8)

    for name in ("Sourire", "Neutre", "Ouverte", "Fachee"):
        mouth = C.Obj("Bouche" + name)
        if name == "Sourire":
            closed(mouth, 0.0085, 0.0044)
        elif name == "Neutre":
            closed(mouth, 0.0010, 0.0046)
        elif name == "Fachee":
            closed(mouth, -0.0080, 0.0040)
        else:
            c = surface(0, my - 0.005, -0.0045)
            mouth.ball(c, (0.0175 * hr, 0.0125 * hr, 0.0070 * hr), inside, weights=w)
            along(mouth, [(-0.0125, my + 0.0030), (0, my + 0.0045), (0.0125, my + 0.0030)], [0.0016, 0.0027, 0.0016], teeth,
                  0.0004)
            along(mouth, [(-0.019, my - 0.002), (-0.009, my + 0.0075), (0, my + 0.0072), (0.009, my + 0.0075),
                          (0.019, my - 0.002)], [0.0012, 0.0029, 0.0027, 0.0029, 0.0012], lips, 0.0018)
            along(mouth, [(-0.019, my - 0.002), (-0.011, my - 0.0150), (0, my - 0.0182), (0.011, my - 0.0150),
                          (0.019, my - 0.002)], [0.0012, 0.0036, 0.0044, 0.0036, 0.0012], lips, 0.0010)
        C.skin(mouth.build(), armature)
