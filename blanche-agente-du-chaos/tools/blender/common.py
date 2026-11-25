"""Outils communs aux scripts qui fabriquent les modèles.

Toute la géométrie est écrite en coordonnées Godot (x à droite, y en haut, z vers la caméra) et convertie pour Blender.
"""
import math
import pathlib
import random
import sys

import bpy
import numpy as np
from mathutils import Vector

ROOT = pathlib.Path(__file__).resolve().parents[2]
MODELS = ROOT / "art" / "models"
PREVIEWS = ROOT / "art" / "previews"


def G(p):
    """Point Godot -> point Blender."""
    return (p[0], -p[2], p[1])


def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    random.seed(2026)
    np.random.seed(2026)


def srgb(hex_color):
    h = hex_color.lstrip("#")
    return tuple(int(h[i:i + 2], 16) / 255.0 for i in (0, 2, 4))


def lin(c):
    return tuple(((v + 0.055) / 1.055) ** 2.4 if v > 0.04045 else v / 12.92 for v in c)


# ---------------------------------------------------------------- matières

_materials = {}
_tex_scale = {}


def material(name, color="#ffffff", rough=0.8, metal=0.0, texture=None, tex_size=1.0, emit=None, emit_power=1.0,
             alpha=1.0, vertex_colors=False, normal=None, orm=None, glow=None):
    if name in _materials:
        return _materials[name]
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    bsdf = m.node_tree.nodes["Principled BSDF"]
    bsdf.inputs["Base Color"].default_value = (*lin(srgb(color)), 1.0)
    bsdf.inputs["Roughness"].default_value = rough
    bsdf.inputs["Metallic"].default_value = metal
    if texture is not None:
        node = m.node_tree.nodes.new("ShaderNodeTexImage")
        node.image = texture
        m.node_tree.links.new(node.outputs["Color"], bsdf.inputs["Base Color"])
        _tex_scale[name] = tex_size
    if normal is not None:
        node = m.node_tree.nodes.new("ShaderNodeTexImage")
        node.image = normal
        bump = m.node_tree.nodes.new("ShaderNodeNormalMap")
        m.node_tree.links.new(node.outputs["Color"], bump.inputs["Color"])
        m.node_tree.links.new(bump.outputs["Normal"], bsdf.inputs["Normal"])
    if orm is not None:
        # glTF : rugosité dans le vert, métal dans le bleu
        node = m.node_tree.nodes.new("ShaderNodeTexImage")
        node.image = orm
        split = m.node_tree.nodes.new("ShaderNodeSeparateColor")
        m.node_tree.links.new(node.outputs["Color"], split.inputs["Color"])
        m.node_tree.links.new(split.outputs["Green"], bsdf.inputs["Roughness"])
        m.node_tree.links.new(split.outputs["Blue"], bsdf.inputs["Metallic"])
    if vertex_colors:
        node = m.node_tree.nodes.new("ShaderNodeVertexColor")
        node.layer_name = "Col"
        m.node_tree.links.new(node.outputs["Color"], bsdf.inputs["Base Color"])
    if glow is not None:
        # une image qui brille d'elle-même (la vue par la fenêtre)
        node = m.node_tree.nodes.new("ShaderNodeTexImage")
        node.image = glow
        m.node_tree.links.new(node.outputs["Color"], bsdf.inputs["Emission Color"])
        bsdf.inputs["Emission Strength"].default_value = emit_power
        _tex_scale[name] = tex_size
    if emit is not None:
        bsdf.inputs["Emission Color"].default_value = (*lin(srgb(emit)), 1.0)
        bsdf.inputs["Emission Strength"].default_value = emit_power
    if alpha < 1.0:
        bsdf.inputs["Alpha"].default_value = alpha
        m.surface_render_method = "BLENDED"
    m.diffuse_color = (*lin(srgb(color)), alpha)
    _materials[name] = m
    return m


def image(name, rgb, data=False):
    """rgb : tableau (hauteur, largeur, 3) en sRGB 0-1. `data` : des nombres (relief, brillance), pas des couleurs."""
    h, w, _ = rgb.shape
    img = bpy.data.images.new(name, w, h, alpha=True)
    if data:
        img.colorspace_settings.name = "Non-Color"
    rgba = np.ones((h, w, 4), dtype=np.float32)
    rgba[..., :3] = np.clip(rgb, 0, 1)
    img.pixels.foreach_set(rgba.ravel())
    img.pack()
    return img


def value_noise(h, w, cell_y, cell_x):
    """Bruit doux, répétable aux bords."""
    gy, gx = max(1, h // cell_y), max(1, w // cell_x)
    grid = np.random.rand(gy, gx)
    ys = np.arange(h) / h * gy
    xs = np.arange(w) / w * gx
    y0 = ys.astype(int) % gy
    x0 = xs.astype(int) % gx
    y1 = (y0 + 1) % gy
    x1 = (x0 + 1) % gx
    fy = (ys - ys.astype(int))[:, None]
    fx = (xs - xs.astype(int))[None, :]
    fy = fy * fy * (3 - 2 * fy)
    fx = fx * fx * (3 - 2 * fx)
    a = grid[y0][:, x0]
    b = grid[y0][:, x1]
    c = grid[y1][:, x0]
    d = grid[y1][:, x1]
    return a * (1 - fy) * (1 - fx) + b * (1 - fy) * fx + c * fy * (1 - fx) + d * fy * fx


# ---------------------------------------------------------------- géométrie

class Obj:
    """Un objet qu'on remplit de formes, puis qu'on construit."""

    def __init__(self, name, origin=(0, 0, 0)):
        self.name = name
        self.origin = Vector(origin)
        self.verts = []
        self.faces = []
        self.mats = []
        self.face_mat = []
        self.smooth = []
        self.groups = []  # par sommet : {os: poids}

    def _mat_index(self, m):
        if m not in self.mats:
            self.mats.append(m)
        return self.mats.index(m)

    def add(self, verts, faces, mat, smooth=False, weights=None):
        base = len(self.verts)
        self.verts.extend([tuple(v) for v in verts])
        if weights is None:
            weights = [None] * len(verts)
        elif isinstance(weights, dict):
            weights = [weights] * len(verts)
        elif callable(weights):
            weights = [weights(Vector(v)) for v in verts]
        self.groups.extend(weights)
        mi = self._mat_index(mat)
        for f in faces:
            self.faces.append([base + i for i in f])
            self.face_mat.append(mi)
            self.smooth.append(smooth)

    # -- formes

    def quad(self, a, b, c, d, mat, **kw):
        self.add([a, b, c, d], [[0, 1, 2, 3]], mat, **kw)

    def box(self, x0, y0, z0, x1, y1, z1, mat, bevel=0.0, seg=2, weights=None, matrix=None):
        if bevel <= 0:
            v = [(x0, y0, z0), (x1, y0, z0), (x1, y1, z0), (x0, y1, z0), (x0, y0, z1), (x1, y0, z1), (x1, y1, z1),
                 (x0, y1, z1)]
            f = [[0, 3, 2, 1], [4, 5, 6, 7], [0, 1, 5, 4], [3, 7, 6, 2], [0, 4, 7, 3], [1, 2, 6, 5]]
            if matrix is not None:
                v = [tuple(matrix @ Vector(p)) for p in v]
            # sommets séparés par face : arêtes franches
            out_v, out_f = [], []
            for face in f:
                out_f.append(list(range(len(out_v), len(out_v) + 4)))
                out_v.extend(v[i] for i in face)
            self.add(out_v, out_f, mat, weights=weights)
            return
        c = Vector(((x0 + x1) / 2, (y0 + y1) / 2, (z0 + z1) / 2))
        h = Vector(((x1 - x0) / 2, (y1 - y0) / 2, (z1 - z0) / 2))
        r = min(bevel, h.x * 0.99, h.y * 0.99, h.z * 0.99)

        def steps(half):
            inner = half - r
            arc = [inner + r * math.tan(math.pi / 4 * k / seg) for k in range(1, seg + 1)]
            return [-v for v in reversed(arc)] + [-inner, inner] + arc

        index, verts, faces = {}, [], []

        def vid(p):
            key = tuple(round(v, 6) for v in p)
            if key not in index:
                q = Vector([max(-(h[i] - r), min(h[i] - r, p[i])) for i in range(3)])
                d = Vector(p) - q
                out = q + (d.normalized() * r if d.length > 1e-9 else d)
                pos = c + out
                if matrix is not None:
                    pos = matrix @ pos
                index[key] = len(verts)
                verts.append(tuple(pos))
            return index[key]

        for axis in range(3):
            u, w = (axis + 1) % 3, (axis + 2) % 3
            su, sw = steps(h[u]), steps(h[w])
            for sign in (-1, 1):
                for i in range(len(su) - 1):
                    for j in range(len(sw) - 1):
                        quad = []
                        for du, dw in ((0, 0), (1, 0), (1, 1), (0, 1)):
                            p = [0, 0, 0]
                            p[axis] = sign * h[axis]
                            p[u] = su[i + du]
                            p[w] = sw[j + dw]
                            quad.append(vid(p))
                        if sign < 0:
                            quad.reverse()
                        if len(set(quad)) == 4:
                            faces.append(quad)
        self.add(verts, faces, mat, smooth=True, weights=weights)

    def tube(self, points, radii, mat, seg=16, caps=True, weights=None, smooth=True, squash=(1.0, 1.0), cap_rings=4):
        """Un tuyau le long d'une ligne brisée, aux bouts arrondis. squash : ovale (largeur, épaisseur)."""
        pts = [Vector(p) for p in points]
        if isinstance(radii, (int, float)):
            radii = [radii] * len(pts)
        rings = []  # (centre, direction, rayon)
        for i, p in enumerate(pts):
            if i == 0:
                d = pts[1] - p
            elif i == len(pts) - 1:
                d = p - pts[i - 1]
            else:
                d = (pts[i + 1] - p).normalized() + (p - pts[i - 1]).normalized()
            rings.append((p, d.normalized(), radii[i]))
        if caps:
            head, tail = rings[0], rings[-1]
            before, after = [], []
            for k in range(cap_rings, 0, -1):
                a = math.pi / 2 * k / cap_rings
                before.append((head[0] - head[1] * head[2] * math.sin(a), head[1], max(1e-4, head[2] * math.cos(a))))
            for k in range(1, cap_rings + 1):
                a = math.pi / 2 * k / cap_rings
                after.append((tail[0] + tail[1] * tail[2] * math.sin(a), tail[1], max(1e-4, tail[2] * math.cos(a))))
            rings = before + rings + after
        verts, faces = [], []
        side = None
        for c, d, r in rings:
            if side is None:
                side = d.orthogonal().normalized()
                ref = Vector((1, 0, 0))
                if abs(d.dot(ref)) < 0.9:
                    side = (ref - d * d.dot(ref)).normalized()
            else:
                side = (side - d * d.dot(side)).normalized()
            other = d.cross(side).normalized()
            for s in range(seg):
                a = 2 * math.pi * s / seg
                verts.append(tuple(c + side * math.cos(a) * r * squash[0] + other * math.sin(a) * r * squash[1]))
        for i in range(len(rings) - 1):
            for s in range(seg):
                a, b = i * seg + s, i * seg + (s + 1) % seg
                faces.append([a, b, b + seg, a + seg])
        faces.append([s for s in range(seg)][::-1])
        faces.append([(len(rings) - 1) * seg + s for s in range(seg)])
        self.add(verts, faces, mat, smooth=smooth, weights=weights)

    def ball(self, center, radii, mat, seg=18, rings=12, weights=None, matrix=None, smooth=True):
        c = Vector(center)
        if isinstance(radii, (int, float)):
            radii = (radii,) * 3
        verts = []
        for i in range(rings + 1):
            lat = -math.pi / 2 + math.pi * i / rings
            for s in range(seg):
                lon = 2 * math.pi * s / seg
                p = Vector((math.cos(lat) * math.cos(lon) * radii[0], math.sin(lat) * radii[1],
                            math.cos(lat) * math.sin(lon) * radii[2]))
                if matrix is not None:
                    p = matrix @ p
                verts.append(tuple(c + p))
        faces = []
        for i in range(rings):
            for s in range(seg):
                a, b = i * seg + s, i * seg + (s + 1) % seg
                faces.append([a, a + seg, b + seg, b])
        self.add(verts, faces, mat, smooth=smooth, weights=weights)

    def cyl(self, base, radius, height, mat, seg=24, top=None, axis=(0, 1, 0), smooth=True, weights=None, bevel=0.0):
        b = Vector(base)
        d = Vector(axis).normalized()
        top = radius if top is None else top
        side = d.orthogonal().normalized()
        other = d.cross(side)
        profile = [(0.0, radius), (height, top)]
        if bevel > 0:
            profile = [(0.0, radius - bevel), (bevel, radius), (height - bevel, top), (height, top - bevel)]
        verts, faces = [], []
        for h, r in profile:
            for s in range(seg):
                a = 2 * math.pi * s / seg
                verts.append(tuple(b + d * h + (side * math.cos(a) + other * math.sin(a)) * r))
        for i in range(len(profile) - 1):
            for s in range(seg):
                a, c = i * seg + s, i * seg + (s + 1) % seg
                faces.append([a, c, c + seg, a + seg])
        self.add(verts, faces, mat, smooth=smooth, weights=weights)
        for (h, r), flip in ((profile[0], True), (profile[-1], False)):
            ring = [tuple(b + d * h + (side * math.cos(2 * math.pi * s / seg) + other * math.sin(2 * math.pi * s / seg)) * r)
                    for s in range(seg)]
            self.add(ring, [list(range(seg))[::-1] if flip else list(range(seg))], mat, weights=weights)

    def torus(self, center, big, small, mat, axis=(0, 1, 0), seg=32, sides=10, weights=None, arc=(0, 2 * math.pi),
              squash=1.0):
        c = Vector(center)
        d = Vector(axis).normalized()
        side = d.orthogonal().normalized()
        if abs(d.dot(Vector((1, 0, 0)))) < 0.9:
            side = (Vector((1, 0, 0)) - d * d.x).normalized()
        other = d.cross(side)
        full = abs(arc[1] - arc[0] - 2 * math.pi) < 1e-6
        n = seg if full else seg + 1
        verts, faces = [], []
        for i in range(n):
            a = arc[0] + (arc[1] - arc[0]) * i / seg
            radial = side * math.cos(a) + other * math.sin(a) * squash
            for s in range(sides):
                b = 2 * math.pi * s / sides
                verts.append(tuple(c + radial * (big + small * math.cos(b)) + d * small * math.sin(b)))
        for i in range(seg):
            for s in range(sides):
                a = i * sides + s
                b = i * sides + (s + 1) % sides
                j = ((i + 1) % n) * sides
                faces.append([a, j + s, j + (s + 1) % sides, b])
        self.add(verts, faces, mat, smooth=True, weights=weights)

    # -- construction

    def build(self, collection=None):
        mesh = bpy.data.meshes.new(self.name)
        origin = self.origin
        mesh.from_pydata([G(Vector(v) - origin) for v in self.verts], [], self.faces)
        mesh.update()
        for m in self.mats:
            mesh.materials.append(m)
        for i, poly in enumerate(mesh.polygons):
            poly.material_index = self.face_mat[i]
            poly.use_smooth = self.smooth[i]
        # coordonnées de texture : projection selon l'orientation de chaque face
        uv = mesh.uv_layers.new(name="UVMap")
        for poly in mesh.polygons:
            m = self.mats[poly.material_index]
            scale = _tex_scale.get(m.name)
            if scale is None:
                continue
            idx = self.faces[poly.index]
            a, b, c = (Vector(self.verts[idx[0]]), Vector(self.verts[idx[1]]), Vector(self.verts[idx[2]]))
            n = (b - a).cross(c - a)
            axis = max(range(3), key=lambda k: abs(n[k]))
            for li, vi in zip(poly.loop_indices, idx):
                p = Vector(self.verts[vi])
                if axis == 0:
                    u, v = p.z, p.y
                elif axis == 1:
                    u, v = p.x, p.z
                else:
                    u, v = p.x, p.y
                uv.data[li].uv = (u / scale, v / scale)
        ob = bpy.data.objects.new(self.name, mesh)
        ob.location = G(origin)
        (collection or bpy.context.scene.collection).objects.link(ob)
        names = sorted({k for g in self.groups if g for k in g})
        if names:
            vgs = {n: ob.vertex_groups.new(name=n) for n in names}
            for i, g in enumerate(self.groups):
                if g:
                    total = sum(g.values())
                    for n, w in g.items():
                        if w > 0:
                            vgs[n].add([i], w / total, "REPLACE")
        mesh.validate()
        return ob


def make_armature(name, bones):
    """bones : [(nom, parent ou None, tête, queue)] en coordonnées Godot."""
    arm = bpy.data.armatures.new(name)
    ob = bpy.data.objects.new(name, arm)
    bpy.context.scene.collection.objects.link(ob)
    bpy.context.view_layer.objects.active = ob
    bpy.ops.object.mode_set(mode="EDIT")
    made = {}
    for bname, parent, head, tail in bones:
        b = arm.edit_bones.new(bname)
        b.head = G(head)
        b.tail = G(tail)
        if parent:
            b.parent = made[parent]
        made[bname] = b
    bpy.ops.object.mode_set(mode="OBJECT")
    return ob


def skin(mesh_ob, armature):
    mesh_ob.parent = armature
    mod = mesh_ob.modifiers.new("Armature", "ARMATURE")
    mod.object = armature


def curve(points, radii, steps=4):
    """Adoucit une ligne brisée (Catmull-Rom) et ses rayons."""
    pts = [Vector(p) for p in points]
    out_p, out_r = [], []
    for i in range(len(pts) - 1):
        p0, p1, p2, p3 = pts[max(0, i - 1)], pts[i], pts[i + 1], pts[min(len(pts) - 1, i + 2)]
        for k in range(steps):
            t = k / steps
            q = 0.5 * (2 * p1 + (p2 - p0) * t + (2 * p0 - 5 * p1 + 4 * p2 - p3) * t * t
                       + (3 * p1 - p0 - 3 * p2 + p3) * t * t * t)
            out_p.append(q)
            out_r.append(radii[i] + (radii[i + 1] - radii[i]) * t)
    out_p.append(pts[-1])
    out_r.append(radii[-1])
    return out_p, out_r


def segment_distance(p, a, b):
    ab = b - a
    t = max(0.0, min(1.0, (p - a).dot(ab) / max(1e-9, ab.length_squared)))
    return (p - (a + ab * t)).length


# ---------------------------------------------------------------- export et aperçus

def export(name):
    MODELS.mkdir(parents=True, exist_ok=True)
    path = MODELS / f"{name}.glb"
    bpy.ops.export_scene.gltf(filepath=str(path), export_format="GLB", export_yup=True, export_animations=False,
                              export_skins=True, export_apply=False)
    print(f"EXPORT {path} {path.stat().st_size // 1024} Ko")


def render(name, eye, target, fov=44.0, size=(1600, 900)):
    if "--sans-apercu" in sys.argv:
        return
    PREVIEWS.mkdir(parents=True, exist_ok=True)
    scene = bpy.context.scene
    cam_data = bpy.data.cameras.new("cam")
    cam_data.sensor_fit = "VERTICAL"
    cam_data.angle = math.radians(fov)
    cam = bpy.data.objects.new("cam", cam_data)
    scene.collection.objects.link(cam)
    cam.location = G(eye)
    direction = Vector(G(target)) - Vector(G(eye))
    cam.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()
    scene.camera = cam
    extra = [cam]
    sun = bpy.data.lights.new("sun", "SUN")
    sun.energy = 2.2
    sun.color = (1.0, 0.94, 0.86)
    so = bpy.data.objects.new("sun", sun)
    so.rotation_euler = (math.radians(38), math.radians(-24), 0)
    scene.collection.objects.link(so)
    extra.append(so)
    for pos, power in (((-0.8, 2.6, 0.2), 28), ((0.9, 2.5, -0.7), 22), ((0.4, 2.4, 1.6), 16)):
        l = bpy.data.lights.new("p", "POINT")
        l.energy = power
        l.color = (1.0, 0.88, 0.72)
        l.shadow_soft_size = 0.35
        lo = bpy.data.objects.new("p", l)
        lo.location = G(pos)
        scene.collection.objects.link(lo)
        extra.append(lo)
    world = bpy.data.worlds.new("w")
    world.use_nodes = True
    bg = world.node_tree.nodes["Background"]
    bg.inputs["Color"].default_value = (0.35, 0.31, 0.28, 1)
    bg.inputs["Strength"].default_value = 0.75
    scene.world = world
    scene.render.engine = "BLENDER_EEVEE"
    scene.view_settings.view_transform = "Standard"
    scene.render.resolution_x, scene.render.resolution_y = size
    scene.render.filepath = str(PREVIEWS / f"{name}.png")
    bpy.ops.render.render(write_still=True)
    for o in extra:
        bpy.data.objects.remove(o)
    print(f"APERCU {scene.render.filepath}")
