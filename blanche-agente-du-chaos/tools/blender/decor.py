"""Les petites choses qui habitent une pièce, partagées par les scripts des pièces : images encadrées, feuilles, plantes,
céramiques. Tout est en coordonnées Godot.
"""
import math

import bpy
import common as C
from mathutils import Vector


def picture(name, corners, material_, parent=None):
    """Un rectangle qui montre une image entière : coins bas-gauche, bas-droit, haut-droit, haut-gauche (vus de face)."""
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata([C.G(c) for c in corners], [], [[0, 1, 2, 3]])
    mesh.materials.append(material_)
    uv = mesh.uv_layers.new(name="UVMap")
    for i, at in enumerate(((0, 0), (1, 0), (1, 1), (0, 1))):
        uv.data[i].uv = at
    ob = bpy.data.objects.new(name, mesh)
    bpy.context.scene.collection.objects.link(ob)
    if parent is not None:
        ob.parent = parent
    return ob


def wall_picture(name, image, center, size, facing, parent=None, emit=0.0):
    """Une image à plat sur un mur. `facing` : la direction où elle regarde ("+x", "-x", "+z", "-z")."""
    cx, cy, cz = center
    w, h = size
    if facing in ("+x", "-x"):
        s = 1 if facing == "+x" else -1        # vue de face, la gauche de l'image est du côté +z si elle regarde vers +x
        a, b = (cx, cy - h / 2, cz + s * w / 2), (cx, cy - h / 2, cz - s * w / 2)
        c, d = (cx, cy + h / 2, cz - s * w / 2), (cx, cy + h / 2, cz + s * w / 2)
    else:
        s = 1 if facing == "+z" else -1
        a, b = (cx - s * w / 2, cy - h / 2, cz), (cx + s * w / 2, cy - h / 2, cz)
        c, d = (cx + s * w / 2, cy + h / 2, cz), (cx - s * w / 2, cy + h / 2, cz)
    mat = C.material(name, "#000000", 0.6, glow=image, emit_power=emit) if emit > 0 \
        else C.material(name, "#ffffff", 0.7)
    if emit <= 0:
        node = mat.node_tree.nodes.new("ShaderNodeTexImage")
        node.image = image
        mat.node_tree.links.new(node.outputs["Color"], mat.node_tree.nodes["Principled BSDF"].inputs["Base Color"])
    return picture(name, (a, b, c, d), mat, parent)


def frame(o, center, size, facing, mat, depth=0.025, border=0.03, mat_inner=None):
    """Un cadre autour d'une image posée sur un mur (`center` est le centre de l'image)."""
    cx, cy, cz = center
    w, h = size
    out = {"+x": (1, 0), "-x": (-1, 0), "+z": (0, 1), "-z": (0, -1)}[facing]
    for du0, du1, dv0, dv1 in ((-w / 2 - border, w / 2 + border, h / 2, h / 2 + border),
                               (-w / 2 - border, w / 2 + border, -h / 2 - border, -h / 2),
                               (-w / 2 - border, -w / 2, -h / 2, h / 2), (w / 2, w / 2 + border, -h / 2, h / 2)):
        if out[0] != 0:
            x0, x1 = sorted((cx - out[0] * 0.003, cx + out[0] * depth))
            o.box(x0, cy + dv0, cz + du0, x1, cy + dv1, cz + du1, mat, bevel=0.004, seg=1)
        else:
            z0, z1 = sorted((cz - out[1] * 0.003, cz + out[1] * depth))
            o.box(cx + du0, cy + dv0, z0, cx + du1, cy + dv1, z1, mat, bevel=0.004, seg=1)
    if mat_inner is not None:
        if out[0] != 0:
            x0, x1 = sorted((cx - out[0] * 0.004, cx - out[0] * 0.001))
            o.box(x0, cy - h / 2, cz - w / 2, x1, cy + h / 2, cz + w / 2, mat_inner)
        else:
            z0, z1 = sorted((cz - out[1] * 0.004, cz - out[1] * 0.001))
            o.box(cx - w / 2, cy - h / 2, z0, cx + w / 2, cy + h / 2, z1, mat_inner)


def blade(o, at, direction, length, width, mat):
    """Une feuille pointue, un peu pliée le long de sa nervure et retombante."""
    a = Vector(at)
    d = Vector(direction).normalized()
    side = d.cross(Vector((0, 1, 0)))
    side = side.normalized() if side.length > 0.01 else Vector((1, 0, 0))
    up = side.cross(d).normalized()
    if up.y < 0:
        up = -up
    verts, faces = [], []
    n = 6
    for i in range(n + 1):
        t = i / n
        mid = a + d * length * t + up * (math.sin(t * math.pi) * length * 0.16) - Vector((0, t * t * length * 0.22, 0))
        w = width * math.sin(math.pi * min(0.999, t * 0.86 + 0.07)) * (1.0 - t ** 3)
        verts += [tuple(mid - side * w + up * w * 0.35), tuple(mid), tuple(mid + side * w + up * w * 0.35)]
    for i in range(n):
        for j in (0, 1):
            p = i * 3 + j
            faces.append([p, p + 3, p + 4, p + 1])
    o.add(verts, faces, mat, smooth=True)


def plant(o, base, r, height, leaves, rng, pot, soil, greens, trailing=0):
    """Une plante en pot : des tiges et des feuilles autour du centre, et des tiges qui retombent."""
    o.cyl(base, r * 0.75, r * 1.2, pot, top=r, seg=20)
    o.torus(Vector(base) + Vector((0, r * 1.18, 0)), r, r * 0.09, pot, sides=8)
    top = Vector(base) + Vector((0, r * 1.2, 0))
    o.cyl(top - Vector((0, 0.012, 0)), r * 0.9, 0.008, soil, seg=20)
    for i in range(leaves):
        a = rng.uniform(0, math.tau)
        d = rng.uniform(0.2, 1.0)
        tip = top + Vector((math.cos(a) * r * 1.5 * d, rng.uniform(0.15, 1.0) * height, math.sin(a) * r * 1.5 * d))
        o.tube([top, (top + tip) / 2 + Vector((0, 0.02, 0))], 0.0035, greens[1], seg=5)
        out = Vector((math.cos(a), rng.uniform(-0.1, 0.8), math.sin(a)))
        blade(o, tip, out, rng.uniform(0.07, 0.11), rng.uniform(0.022, 0.034), greens[i % len(greens)])
    for k in range(trailing):
        a = k * math.tau / max(1, trailing)
        p = [top + Vector((math.cos(a) * r, 0, math.sin(a) * r))]
        for j in range(1, 6):
            p.append(p[0] + Vector((math.cos(a) * 0.015 * j, -0.07 * j, math.sin(a) * 0.015 * j)))
        o.tube(p, 0.004, greens[1], seg=5)
        for q in p[1:]:
            b = rng.uniform(0, math.tau)
            blade(o, q, (math.cos(b), -0.2, math.sin(b)), 0.07, 0.024, greens[0])


def cup(o, at, r, h, mat, handle=True):
    """Une tasse de céramique : bombée, son anse sur le côté."""
    x, y, z = at
    o.cyl((x, y, z), r * 0.82, h, mat, top=r, seg=16, bevel=0.003)
    o.cyl((x, y + h - 0.004, z), r * 0.86, 0.004, C.material("cafe_creux", "#3a2a20", 0.6), seg=16)
    if handle:
        o.torus((x + r * 1.05, y + h * 0.5, z), h * 0.24, 0.0045, mat, axis=(0, 0, 1), seg=12, sides=5)


def bowl(o, at, r, h, mat):
    x, y, z = at
    o.cyl((x, y, z), r * 0.55, h, mat, top=r, seg=18, bevel=0.003)
    o.torus((x, y + h, z), r, 0.004, mat, seg=20, sides=5)


def vase(o, at, r, h, mat):
    """Un vase en courbe : pied, ventre, col."""
    x, y, z = at
    path, radii = C.curve([(x, y, z), (x, y + h * 0.35, z), (x, y + h * 0.75, z), (x, y + h, z)],
                          [r * 0.7, r, r * 0.45, r * 0.55], 4)
    o.tube(path, radii, mat, seg=16, caps=True, cap_rings=2)
