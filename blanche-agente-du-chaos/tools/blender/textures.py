"""Les matières de la cuisine, entièrement fabriquées par le calcul : couleur, relief et brillance.

Chaque fonction rend un dictionnaire pour common.material : `texture` (couleur), `normal` (relief) et `orm`
(rugosité dans le vert, métal dans le bleu), avec `tex_size`, le nombre de mètres couvert par l'image.
Toutes les images se répètent sans raccord.
"""
import math

import common as C
import numpy as np

TAU = math.tau


def _fbm(h, w, cell_y, cell_x, octaves=4, gain=0.55):
    """Bruit à plusieurs échelles, répétable, entre 0 et 1."""
    total, weight, amp = np.zeros((h, w)), 0.0, 1.0
    for i in range(octaves):
        total += amp * C.value_noise(h, w, max(1, cell_y >> i), max(1, cell_x >> i))
        weight += amp
        amp *= gain
    return total / weight


def _hex(c):
    return np.array(C.srgb(c))


def _ramp(t, stops):
    """Un dégradé : t entre 0 et 1, stops = [(position, "#couleur"), …]."""
    xs = [p for p, _ in stops]
    cols = np.array([C.srgb(c) for _, c in stops])
    return np.stack([np.interp(t, xs, cols[:, k]) for k in range(3)], axis=-1)


def _normal(height, strength):
    """Le relief à partir des hauteurs (en pixels) ; convention OpenGL, comme glTF."""
    dx = (np.roll(height, -1, axis=1) - np.roll(height, 1, axis=1)) * 0.5 * strength
    dy = (np.roll(height, -1, axis=0) - np.roll(height, 1, axis=0)) * 0.5 * strength
    n = np.dstack([-dx, -dy, np.ones_like(height)])
    n /= np.linalg.norm(n, axis=2, keepdims=True)
    return n * 0.5 + 0.5


def _soft_edge(dist, width):
    """0 au bord, 1 à plus de `width` pixels : un chanfrein."""
    return np.clip(dist / width, 0.0, 1.0) ** 0.6


def _pack(name, color, height, rough, meters, strength=1.0, metal=0.0):
    h, w = rough.shape
    orm = np.dstack([np.ones((h, w)), np.clip(rough, 0.02, 1.0), np.full((h, w), metal)])
    return dict(texture=C.image(name, color), normal=C.image(name + "_relief", _normal(height, strength), data=True),
                orm=C.image(name + "_brillance", orm, data=True), tex_size=meters)


def _grain(h, w, rng, along_x=True, rings=9.0, wobble=2.4):
    """Les veines du bois : des cernes étirés et ondulés le long de la planche. Entre 0 (clair) et 1 (veine)."""
    if along_x:
        warp = _fbm(h, w, h // 6, w // 2, 3)
        fine = C.value_noise(h, w, 2, max(1, w // 8)) * 0.6 + C.value_noise(h, w, 1, 24) * 0.4
        v = np.linspace(0, 1, h, endpoint=False)[:, None] * np.ones((1, w))
    else:
        warp = _fbm(h, w, h // 2, w // 6, 3)
        fine = C.value_noise(h, w, max(1, h // 8), 2) * 0.6 + C.value_noise(h, w, 24, 1) * 0.4
        v = np.linspace(0, 1, w, endpoint=False)[None, :] * np.ones((h, 1))
    waves = 0.5 + 0.5 * np.sin(TAU * (v * rings + warp * wobble))
    return np.clip(waves ** 3 * 0.75 + (fine - 0.45) * 0.9, 0.0, 1.0)


def floor(rng):
    """Un vieux plancher de bois franc verni : lattes étroites, teintes inégales, nœuds, joints, usure."""
    size, meters, rows = 1024, 1.6, 24
    color = np.zeros((size, size, 3))
    height = np.zeros((size, size))
    rough = np.zeros((size, size))
    tones = ["#a4622c", "#b57536", "#c08544", "#965528", "#ad6d31", "#c8904f", "#9d5e2c", "#b97d3e"]
    wear = _fbm(size, size, 200, 340)
    ph = size / rows
    yy = np.arange(size)
    for r in range(rows):
        y0, y1 = int(r * ph), int((r + 1) * ph)
        x = rng.randrange(size)
        covered = 0
        while covered < size:
            length = min(rng.randrange(240, 620), size - covered)
            xs = (np.arange(x, x + length)) % size
            band = (y1 - y0, length)
            tone = _hex(tones[rng.randrange(len(tones))])
            grain = _grain(256, 512, rng, True, rng.uniform(2.5, 5.0), rng.uniform(0.8, 2.2))
            oy, ox = rng.randrange(256 - band[0]), rng.randrange(512)
            g = grain[oy:oy + band[0]][:, (ox + np.arange(length)) % 512]
            block = tone * (1.07 - 0.30 * g)[..., None]
            relief = -g * 0.35
            if rng.random() < 0.35:
                kx, ky = rng.uniform(20, length - 20), rng.uniform(5, band[0] - 5)
                gy, gx = np.mgrid[0:band[0], 0:length]
                d = np.sqrt(((gx - kx) / rng.uniform(7, 16)) ** 2 + ((gy - ky) / rng.uniform(3, 6)) ** 2)
                knot = np.clip(1.0 - d, 0, 1)[..., None]
                block = block * (1 - 0.62 * knot)
                relief = relief - knot[..., 0] * 0.5
            gy, gx = np.mgrid[0:band[0], 0:length]
            edge = np.minimum(np.minimum(gy, band[0] - 1 - gy), np.minimum(gx, length - 1 - gx))
            bevel = _soft_edge(edge, 2.6)
            block = block * (0.50 + 0.50 * bevel)[..., None]
            idx = np.ix_(yy[y0:y1], xs)
            color[idx] = block
            height[idx] = bevel * 2.2 + relief + rng.uniform(-0.25, 0.25)
            rough[idx] = 0.27 + 0.10 * g + (1 - bevel) * 0.4
            x += length
            covered += length
    color *= (0.90 + 0.20 * wear)[..., None]
    rough += (wear - 0.5) * 0.22
    scratch = C.value_noise(size, size, 1, 22) * C.value_noise(size, size, 90, 90)
    lines = np.clip((scratch - 0.52) * 6, 0, 1)
    rough += lines * 0.18
    color += (lines * 0.05)[..., None]
    return _pack("plancher", color, height, rough, meters, 0.9)


def wood(name, light, dark, vertical=True, meters=0.8, rough=0.42, contrast=0.85):
    size = 512
    import random
    own = random.Random(name)
    g = _grain(size, size, own, not vertical, 6.0, 2.6)
    cloud = _fbm(size, size, 160, 160)
    color = _hex(light) + (_hex(dark) - _hex(light)) * np.clip(g * contrast + (cloud - 0.5) * 0.5, 0, 1)[..., None]
    pores = (C.value_noise(size, size, 5 if vertical else 1, 1 if vertical else 5) > 0.74).astype(float)
    color *= (1.0 - 0.09 * pores)[..., None]
    return _pack(name, color, -g * 0.7 - pores * 0.3, rough + 0.14 * g + 0.08 * pores, meters, 0.7)


def butcher(rng):
    """Le bloc de boucher de l'îlot : des lames collées, aboutées, huilées."""
    size, strips, meters = 512, 12, 0.7
    color = np.zeros((size, size, 3))
    height = np.zeros((size, size))
    rough = np.zeros((size, size))
    tones = ["#e0bd85", "#d4ab6e", "#e9ca94", "#c99c60", "#dbb376"]
    edges = [round(i * size / strips) for i in range(strips + 1)]
    for i in range(strips):
        x0, x1 = edges[i], edges[i + 1]
        y = rng.randrange(size)
        covered = 0
        while covered < size:
            length = min(rng.randrange(150, 330), size - covered)
            ys = (np.arange(y, y + length)) % size
            tone = _hex(tones[rng.randrange(len(tones))])
            grain = _grain(512, 128, rng, False, rng.uniform(2, 5), 1.6)
            g = grain[(rng.randrange(512) + np.arange(length)) % 512][:, :x1 - x0]
            gy, gx = np.mgrid[0:length, 0:x1 - x0]
            edge = np.minimum(np.minimum(gx, x1 - x0 - 1 - gx), np.minimum(gy, length - 1 - gy))
            bevel = _soft_edge(edge, 1.8)
            idx = np.ix_(ys, np.arange(x0, x1))
            color[idx] = tone * (1.04 - 0.2 * g)[..., None] * (0.82 + 0.18 * bevel)[..., None]
            height[idx] = bevel * 0.8 - g * 0.2
            rough[idx] = 0.34 + 0.12 * g
            y += length
            covered += length
    return _pack("billot", color, height, rough, meters, 0.8)


def quartz():
    """Le comptoir bleu nuit, moucheté, avec quelques veines pâles."""
    size = 512
    cloud = _fbm(size, size, 130, 130)
    color = _ramp(cloud, [(0.2, "#2b3242"), (0.55, "#3a4356"), (0.85, "#465066")])
    speck = np.random.rand(size // 2, size // 2).repeat(2, axis=0).repeat(2, axis=1)
    color[speck > 0.955] = C.srgb("#9aa8c0")
    color[speck > 0.993] = C.srgb("#e4e9f2")
    color[speck < 0.04] = C.srgb("#171b25")
    vein = np.abs(_fbm(size, size, 220, 220, 5) - 0.5)
    veins = np.clip(1.0 - vein / 0.012, 0, 1) * np.clip((_fbm(size, size, 120, 120) - 0.45) * 4, 0, 1)
    color = color + (_hex("#aab6cc") - color) * (veins * 0.45)[..., None]
    return _pack("comptoir", color, speck * 0.08, 0.16 + 0.08 * cloud, 0.6, 0.5)


def tiles(rng):
    """La céramique du dosseret : des carreaux émaillés, bombés, jamais tout à fait de la même teinte."""
    size, n, meters = 512, 4, 0.44
    cell = size // n
    color = np.zeros((size, size, 3))
    height = np.zeros((size, size))
    rough = np.zeros((size, size))
    gy, gx = np.mgrid[0:cell, 0:cell]
    edge = np.minimum(np.minimum(gx, cell - 1 - gx), np.minimum(gy, cell - 1 - gy)).astype(float)
    face = _soft_edge(edge - 2.0, 9.0)
    joint = (edge < 3.0).astype(float)
    ripple = _fbm(size, size, 64, 64)
    for r in range(n):
        for c in range(n):
            shade = rng.uniform(0.955, 1.02)
            tint = _hex("#f1ede4") * shade
            idx = np.ix_(np.arange(r * cell, (r + 1) * cell), np.arange(c * cell, (c + 1) * cell))
            color[idx] = tint * (1 - joint)[..., None] + _hex("#b7afa2") * joint[..., None]
            color[idx] *= (0.93 + 0.07 * face)[..., None]
            height[idx] = face * 3.0 + rng.uniform(-0.3, 0.3)
            rough[idx] = 0.12 + joint * 0.75
    height += ripple * 0.9
    return _pack("carreaux", color, height, rough, meters, 0.7)


def bricks(rng):
    size, meters = 512, 0.75
    bh, bw, gap = 64, 128, 9
    grit = _fbm(size, size, 20, 20)
    color = _hex("#b4a597") * (0.88 + 0.24 * grit)[..., None]
    height = grit * 1.2
    rough = np.full((size, size), 0.95)
    tones = ["#93513f", "#7d4436", "#a2604b", "#6c3b30", "#ab6f58", "#874a39"]
    for r in range(size // bh):
        off = (r % 2) * bw // 2
        for c in range(size // bw):
            w, h = bw - gap, bh - gap
            gy, gx = np.mgrid[0:h, 0:w]
            edge = np.minimum(np.minimum(gx, w - 1 - gx), np.minimum(gy, h - 1 - gy)).astype(float)
            chip = _fbm(h, w, 12, 12)
            face = _soft_edge(edge - (chip - 0.5) * 7, 6.0)
            tone = _hex(tones[rng.randrange(len(tones))]) * (0.82 + 0.36 * chip)[..., None]
            idx = np.ix_(np.arange(r * bh + gap // 2, r * bh + gap // 2 + h), (np.arange(w) + c * bw + off) % size)
            on = (face > 0.05)[..., None]
            color[idx] = np.where(on, tone, color[idx])
            height[idx] = np.maximum(height[idx], face * 4.5 + chip * 1.8)
            rough[idx] = 0.82
    return _pack("brique", color, height, rough, meters, 0.9)


def fabric(name, color_, meters=0.25, weave=6, rough=0.92):
    """Un tissu : trame croisée et petites irrégularités."""
    size = 256
    x = np.arange(size)[None, :] * np.ones((size, 1))
    y = x.T
    cross = np.sin(TAU * x / weave) * np.sign(np.sin(TAU * y / (weave * 2))) \
        + np.sin(TAU * y / weave) * np.sign(np.sin(TAU * x / (weave * 2)))
    fuzz = C.value_noise(size, size, 2, 2)
    blot = _fbm(size, size, 64, 64)
    color = _hex(color_) * (0.90 + 0.05 * cross + 0.12 * (fuzz - 0.5) + 0.12 * (blot - 0.5))[..., None]
    return _pack(name, color, cross * 0.8 + fuzz * 0.8, np.full((size, size), rough), meters, 0.8)


def plaster(name, color_, meters=1.2):
    """Un mur peint : à peine grenu."""
    size = 512
    grain = _fbm(size, size, 6, 6, 3)
    cloud = _fbm(size, size, 240, 240, 3)
    color = _hex(color_) * (0.972 + 0.056 * cloud)[..., None]
    return _pack(name, color, grain * 1.6, 0.82 + 0.1 * grain, meters, 0.55)


def brushed(name, color_, meters=0.9, rough=0.30, metal=0.85, vertical=True):
    """L'inox brossé : de fines stries qui étirent les reflets."""
    size = 512
    streak = C.value_noise(size, size, 256, 1) * 0.6 + C.value_noise(size, size, 64, 2) * 0.4
    if not vertical:
        streak = streak.T
    cloud = _fbm(size, size, 200, 200)
    color = _hex(color_) * (0.955 + 0.07 * streak + 0.04 * (cloud - 0.5))[..., None]
    return _pack(name, color, streak * 0.5, rough + 0.16 * (streak - 0.5) + 0.05 * (cloud - 0.5), meters, 0.35, metal)


def rug(name, base, stripe, border, meters=1.0):
    """Un petit tapis tissé à rayures : une image par tapis (échelle = sa largeur)."""
    size = 512
    x = np.arange(size)[None, :] * np.ones((size, 1))
    y = x.T
    weave = np.sin(TAU * x / 8) * np.sin(TAU * y / 8)
    fuzz = C.value_noise(size, size, 3, 3)
    color = np.ones((size, size, 3)) * _hex(base)
    for k, (at, width) in enumerate(((0.10, 0.05), (0.22, 0.02), (0.50, 0.09), (0.78, 0.02), (0.90, 0.05))):
        band = np.abs(x / size - at) < width / 2
        color[band] = _hex(stripe if k % 2 == 0 else border)
    color *= (0.90 + 0.07 * weave + 0.2 * (fuzz - 0.5))[..., None]
    return _pack(name, color, weave * 1.2 + fuzz, np.full((size, size), 0.95), meters, 0.8)
