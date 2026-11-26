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


def floor(rng, name="plancher", tones=None, along_z=False):
    """Un vieux plancher de bois franc verni : lattes étroites, teintes inégales, nœuds, joints, usure.

    `along_z` : les lattes courent dans la longueur de la pièce (le double salon)."""
    size, meters, rows = 1024, 1.6, 24
    color = np.zeros((size, size, 3))
    height = np.zeros((size, size))
    rough = np.zeros((size, size))
    tones = tones or ["#a4622c", "#b57536", "#c08544", "#965528", "#ad6d31", "#c8904f", "#9d5e2c", "#b97d3e"]
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
    if along_z:
        color, height, rough = color.transpose(1, 0, 2), height.T, rough.T
    return _pack(name, color, height, rough, meters, 0.9)


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


def view(rng):
    """La vue par la fenêtre : le ciel et ses nuages, les arbres de la ruelle, la maison de brique d'en face."""
    w, h = 512, 448
    y = np.linspace(0, 1, h)[:, None] * np.ones((1, w))          # 0 en bas, 1 en haut (comme Blender)
    x = np.linspace(0, 1, w)[None, :] * np.ones((h, 1))
    img = _ramp(y, [(0.3, "#e9f3fb"), (0.65, "#aed2f2"), (1.0, "#6fa9e4")])
    clouds = np.clip((_fbm(h, w, 90, 170, 5) - 0.56) * 5, 0, 1) * np.clip((y - 0.5) * 4, 0, 1)
    img = img + (_hex("#ffffff") - img) * clouds[..., None]
    # la maison d'en face et son toit
    house = (x > 0.06) & (x < 0.58) & (y < 0.60)
    brick_rows = ((y * 56).astype(int) + 0) % 2
    mortar = (((y * 56) % 1 < 0.16) | (((x * 34 + brick_rows * 0.5) % 1) < 0.07))
    wall_ = _hex("#a85b47") * (0.88 + 0.24 * _fbm(h, w, 14, 24))[..., None]
    wall_[mortar] = C.srgb("#cbb7a5")
    img[house] = wall_[house]
    roof = (x > 0.03) & (x < 0.61) & (y >= 0.60) & (y < 0.66)
    img[roof] = C.srgb("#4a4550")
    for wx in (0.12, 0.28, 0.44):
        for wy in (0.20, 0.40):
            frame = (x > wx - 0.008) & (x < wx + 0.098) & (y > wy - 0.01) & (y < wy + 0.135)
            pane = (x > wx) & (x < wx + 0.09) & (y > wy) & (y < wy + 0.125)
            img[frame] = C.srgb("#f2eee6")
            glass = _ramp((y - wy) / 0.125, [(0.0, "#3d5774"), (1.0, "#9cc0de")])
            img[pane] = glass[pane]
            img[pane & (np.abs(x - wx - 0.045) < 0.004)] = C.srgb("#f2eee6")
            img[pane & (np.abs(y - wy - 0.065) < 0.004)] = C.srgb("#f2eee6")
    # les arbres : des boules de feuillage à plusieurs tons
    gy, gx = np.mgrid[0:h, 0:w]
    ragged = (_fbm(h, w, 10, 10, 3) - 0.5) * 22
    for cx, cy, r, tone in ((0.70, 0.36, 76, "#6d9a3e"), (0.86, 0.45, 92, "#86ad45"), (0.96, 0.27, 70, "#577f34"),
                            (0.76, 0.18, 66, "#4c7230"), (0.02, 0.16, 55, "#5d8a39"), (0.60, 0.14, 42, "#79a342")):
        d = np.hypot(gx - cx * w, gy - cy * h) + ragged
        leaves = _hex(tone) * (0.72 + 0.62 * _fbm(h, w, 8, 8, 3))[..., None]
        leaves *= (0.86 + 0.28 * np.clip((gy - cy * h) / r + 0.5, 0, 1))[..., None]
        img[d < r] = leaves[d < r]
    # la clôture de bois et le gazon
    fence = (y < 0.15) & (((x * 22) % 1) < 0.86)
    img[fence] = (_hex("#b98c5c") * (0.85 + 0.3 * _fbm(h, w, 40, 6))[..., None])[fence]
    grass = y < 0.035
    img[grass] = (_hex("#5e8c38") * (0.8 + 0.4 * _fbm(h, w, 4, 4))[..., None])[grass]
    return C.image("vue", np.clip(img, 0, 1))


def fur():
    """Le grain d'un pelage de chiot : de fines mèches couchées, qui accrochent la lumière par endroits."""
    size = 512
    strands = C.value_noise(size, size, 22, 2) * 0.6 + C.value_noise(size, size, 9, 1) * 0.4
    tufts = _fbm(size, size, 48, 20, 3)
    height = strands * 2.6 + tufts * 2.0
    rough = 0.56 + 0.30 * (1.0 - strands) + 0.10 * (tufts - 0.5)
    return dict(normal=C.image("poil_relief", _normal(height, 0.75), data=True),
                orm=C.image("poil_brillance", np.dstack([np.ones_like(rough), rough, np.zeros_like(rough)]), data=True))


def food(name, base, patches=(), speckles=(), rough=0.5, relief=1.2, meters=0.16, cells=44):
    """Une matière à manger : une couleur de fond, des plages (dorées, grillées, marbrées) et des grains.

    patches = [("#couleur", seuil, force)] : là où un nuage dépasse le seuil ; speckles = [("#couleur", part)]."""
    size = 256
    cloud = _fbm(size, size, cells, cells, 4)
    color = np.ones((size, size, 3)) * _hex(base) * (0.93 + 0.14 * _fbm(size, size, 12, 12, 3))[..., None]
    for i, (tone, threshold, strength) in enumerate(patches):
        field = cloud if i % 2 == 0 else _fbm(size, size, cells // 2, cells // 2, 4)
        amount = np.clip((field - threshold) * 7.0, 0, 1) * strength
        color = color + (_hex(tone) - color) * amount[..., None]
    for tone, share in speckles:
        dots = np.random.rand(size // 2, size // 2).repeat(2, axis=0).repeat(2, axis=1)
        color[dots < share] = C.srgb(tone)
    height = _fbm(size, size, 10, 10, 3) * 2.0 + cloud * 1.5
    return _pack(name, np.clip(color, 0, 1), height, np.clip(rough + (cloud - 0.5) * 0.2, 0.05, 1), meters, relief)


# ---------------------------------------------------------------- le double salon

def corduroy(name, color_, meters=0.18):
    """Le velours côtelé du divan : des côtes en relief, plus claires sur le dessus, et un peu de lustre."""
    size = 256
    x = np.arange(size)[None, :] * np.ones((size, 1))
    rib = 0.5 + 0.5 * np.cos(TAU * x / 8.0)
    fuzz = C.value_noise(size, size, 2, 2)
    worn = _fbm(size, size, 64, 64)
    color = _hex(color_) * (0.78 + 0.26 * rib + 0.08 * (fuzz - 0.5) + 0.10 * (worn - 0.5))[..., None]
    return _pack(name, color, rib * 2.4 + fuzz * 0.5, 0.78 - 0.22 * rib, meters, 0.9)


def velvet(name, color_, meters=0.3):
    """Un velours lisse (le fauteuil marine) : de grandes ondes de lustre."""
    size = 256
    sheen = _fbm(size, size, 90, 90, 3)
    fuzz = C.value_noise(size, size, 2, 2)
    color = _hex(color_) * (0.85 + 0.25 * sheen + 0.06 * (fuzz - 0.5))[..., None]
    return _pack(name, color, fuzz * 0.6, 0.7 - 0.2 * sheen, meters, 0.6)


def picture(name, kind, w=256, h=320):
    """Une image inventée pour un cadre (rien n'est tiré des photos) : paysage, motifs, lune, chien, carte du ciel…"""
    import random
    rng = random.Random(name)
    y = np.linspace(0, 1, h)[:, None] * np.ones((1, w))          # 0 en bas
    x = np.linspace(0, 1, w)[None, :] * np.ones((h, 1))
    img = np.ones((h, w, 3)) * _hex("#f3efe6")
    if kind == "paysage":
        img = _ramp(y, [(0.0, "#f6e6c8"), (0.6, "#f2c9a0"), (1.0, "#c7d9e8")])
        for k, (base, amp, tone) in enumerate(((0.55, 0.12, "#8aa7b8"), (0.42, 0.10, "#5f8a6f"), (0.25, 0.08, "#3f6a4e"))):
            ridge = base + amp * np.sin(x * TAU * (1.1 + k * 0.7) + k) * 0.6 + amp * 0.4 * np.sin(x * TAU * 3.3 + k * 2)
            img[y < ridge] = C.srgb(tone)
        sun = np.hypot(x - 0.7, (y - 0.74) * h / w) < 0.09
        img[sun] = C.srgb("#f39a5b")
    elif kind == "motifs":
        img[:] = _hex("#f5f1e8")
        for r in range(6):
            for c in range(4):
                cx, cy = (c + 0.5) / 4, (r + 0.5) / 6
                shape = rng.randrange(3)
                tone = ["#3d4a6b", "#c46b4a", "#7f9c8a", "#d9a441"][rng.randrange(4)]
                if shape == 0:
                    m = np.hypot(x - cx, (y - cy) * h / w) < 0.07
                elif shape == 1:
                    m = (np.abs(x - cx) < 0.07) & (np.abs(y - cy) < 0.05)
                else:
                    m = (np.abs(x - cx) + np.abs(y - cy) * h / w) < 0.08
                img[m] = C.srgb(tone)
    elif kind == "lune":
        img = _ramp(y, [(0.0, "#141821"), (1.0, "#262c3d")])
        stars = np.random.rand(h, w) > 0.996
        img[stars] = C.srgb("#f4f0dc")
        moon = np.hypot(x - 0.5, (y - 0.58) * h / w)
        img[moon < 0.2] = (_hex("#e9e2c7") * (0.85 + 0.2 * _fbm(h, w, 16, 16, 3))[..., None])[moon < 0.2]
        hill = y < 0.18 + 0.03 * np.sin(x * 9)
        img[hill] = C.srgb("#0d1016")
    elif kind == "lettres":
        img[:] = _hex("#f4f1ea")
        for r in range(4):
            for c in range(3):
                cx, cy = (c + 0.5) / 3, (r + 0.5) / 4
                bar = (np.abs(x - cx) < 0.11) & (np.abs(y - cy) < 0.018)
                post = (np.abs(x - cx + 0.06 * (1 if (r + c) % 2 else -1)) < 0.018) & (np.abs(y - cy) < 0.09)
                img[bar | post] = C.srgb("#2a2a2e")
    elif kind == "aquarelle":
        img[:] = _hex("#f7f3ea")
        for k in range(7):
            cx, cy, r = rng.uniform(0.2, 0.8), rng.uniform(0.25, 0.8), rng.uniform(0.08, 0.2)
            tone = _hex(["#e4774f", "#5e9ac4", "#f0c64b", "#7bb07a", "#c45d8e"][k % 5])
            d = np.hypot(x - cx, (y - cy) * h / w * 0.6) + (_fbm(h, w, 20, 20, 3) - 0.5) * 0.08
            a = np.clip((r - d) * 12, 0, 0.6)[..., None]
            img = img * (1 - a) + tone * a
    elif kind == "chien":
        img[:] = _hex("#ece4d4")
        head = np.hypot(x - 0.5, (y - 0.55) * 1.1) < 0.24
        ears = (np.hypot(x - 0.28, (y - 0.5) * 0.7) < 0.1) | (np.hypot(x - 0.72, (y - 0.5) * 0.7) < 0.1)
        img[head | ears] = C.srgb("#1f1c1d")
        nose = np.hypot(x - 0.5, y - 0.45) < 0.035
        img[nose] = C.srgb("#4a3a36")
        chest = (np.abs(x - 0.5) < 0.06) & (y < 0.3) & (y > 0.2)
        img[chest] = C.srgb("#f4efe6")
    elif kind == "ciel":
        img = np.ones((h, w, 3)) * _hex("#16213b")
        disc = np.hypot(x - 0.5, (y - 0.58) * h / w)
        img[disc < 0.36] = C.srgb("#1d2b4c")
        stars = (np.random.rand(h, w) > 0.985) & (disc < 0.36)
        img[stars] = C.srgb("#f3edd2")
        ring = np.abs(disc - 0.36) < 0.004
        img[ring] = C.srgb("#c9b984")
        for _ in range(5):
            ax, ay = rng.uniform(0.3, 0.7), rng.uniform(0.4, 0.75)
            bx, by = ax + rng.uniform(-0.12, 0.12), ay + rng.uniform(-0.1, 0.1)
            t_ = np.clip(((x - ax) * (bx - ax) + (y - ay) * (by - ay)) / ((bx - ax) ** 2 + (by - ay) ** 2 + 1e-6), 0, 1)
            line = np.hypot(x - ax - t_ * (bx - ax), y - ay - t_ * (by - ay)) < 0.003
            img[line] = C.srgb("#c9b984")
        img[(y < 0.16) & (y > 0.13) & (np.abs(x - 0.5) < 0.22)] = C.srgb("#c9b984")
    elif kind == "vagues":
        img[:] = _hex("#f5f2ea")
        for k in range(9):
            line = np.abs(y - (0.15 + k * 0.05) - 0.02 * np.sin(x * TAU * 2 + k)) < 0.005
            img[line] = C.srgb("#3a3a3f")
        sun = np.hypot(x - 0.62, (y - 0.78) * h / w) < 0.12
        img[sun] = C.srgb("#f1c33c")
    elif kind == "falaise":
        img = _ramp(y, [(0.0, "#6d6f72"), (0.5, "#b9bbbe"), (1.0, "#dfe1e3")])
        cliff = (x < 0.55 + 0.2 * y) & (y < 0.62 - 0.1 * np.sin(x * 7))
        img[cliff] = (_hex("#3c3e42") * (0.8 + 0.4 * _fbm(h, w, 12, 12, 3))[..., None])[cliff]
        sea = (y < 0.22) & ~cliff
        img[sea] = C.srgb("#8b8f94")
    return C.image(name, np.clip(img, 0, 1))


def screen(name, kind):
    """L'écran de la télé : une partie de hockey dessinée (vue d'en haut), ou une scène de film inventée."""
    w, h = 384, 216
    y = np.linspace(0, 1, h)[:, None] * np.ones((1, w))
    x = np.linspace(0, 1, w)[None, :] * np.ones((h, 1))
    if kind == "hockey":
        img = np.ones((h, w, 3)) * _hex("#eef4f8")
        img[(y < 0.12) | (y > 0.88)] = C.srgb("#2c2f3a")             # la foule
        crowd = (np.random.rand(h, w) > 0.6) & ((y < 0.12) | (y > 0.88))
        img[crowd] = C.srgb("#b3373a")
        img[np.abs(x - 0.5) < 0.006] = C.srgb("#c8262b")             # la ligne rouge
        img[np.abs(x - 0.33) < 0.006] = C.srgb("#2a56b8")
        img[np.abs(x - 0.67) < 0.006] = C.srgb("#2a56b8")
        circle = np.abs(np.hypot(x - 0.5, (y - 0.5) * h / w) - 0.09) < 0.004
        img[circle] = C.srgb("#2a56b8")
        for cx, cy, tone in ((0.42, 0.45, "#c8262b"), (0.58, 0.6, "#f4f4f4"), (0.55, 0.38, "#c8262b"),
                             (0.38, 0.62, "#f4f4f4"), (0.47, 0.52, "#c8262b")):
            dot = np.hypot(x - cx, (y - cy) * h / w) < 0.018
            img[dot] = C.srgb("#202126")
            img[np.hypot(x - cx, (y - cy) * h / w) < 0.013] = C.srgb(tone)
        img[np.hypot(x - 0.5, (y - 0.47) * h / w) < 0.005] = C.srgb("#111111")   # la rondelle
    else:
        img = _ramp(y, [(0.0, "#3b5f3a"), (0.35, "#6f9a4e"), (0.4, "#f2c57a"), (1.0, "#7cb6e8")])
        hill = y < 0.38 + 0.06 * np.sin(x * 5)
        img[hill] = (_hex("#5d8c45") * (0.8 + 0.3 * y)[..., None])[hill]
        castle = (np.abs(x - 0.72) < 0.06) & (y < 0.62) & ~((y > 0.56) & ((x * 40).astype(int) % 2 == 0))
        img[castle & ~hill] = C.srgb("#e8d9c0")
        sun = np.hypot(x - 0.25, (y - 0.75) * h / w) < 0.07
        img[sun] = C.srgb("#fff2b8")
    return C.image(name, np.clip(img, 0, 1))


def street(rng):
    """La vue par la fenêtre du salon : les plex d'en face, leurs balcons et un arbre de la rue."""
    w, h = 512, 512
    y = np.linspace(0, 1, h)[:, None] * np.ones((1, w))
    x = np.linspace(0, 1, w)[None, :] * np.ones((h, 1))
    img = _ramp(y, [(0.6, "#dfeaf3"), (1.0, "#9cc4e6")])
    for k, (x0, x1, tone) in enumerate(((0.0, 0.36, "#9b4f3e"), (0.36, 0.7, "#b77a52"), (0.7, 1.0, "#8d5a48"))):
        block = (x >= x0) & (x < x1) & (y < 0.82)
        rows = ((y * 70).astype(int)) % 2
        mortar = ((y * 70) % 1 < 0.14) | (((x * 40 + rows * 0.5) % 1) < 0.06)
        wall_ = _hex(tone) * (0.88 + 0.24 * _fbm(h, w, 14, 24))[..., None]
        wall_[mortar] = C.srgb("#c9b6a4")
        img[block] = wall_[block]
        img[(x >= x0) & (x < x1) & (y >= 0.8) & (y < 0.84)] = C.srgb("#d8d2c6")   # la corniche
        for wx in (x0 + 0.05, x0 + (x1 - x0) / 2 + 0.02):
            for wy in (0.22, 0.52):
                pane = (x > wx) & (x < wx + 0.1) & (y > wy) & (y < wy + 0.17)
                img[pane] = _ramp((y - wy) / 0.17, [(0.0, "#36506b"), (1.0, "#8fb3d2")])[pane]
                img[pane & ((np.abs(x - wx - 0.05) < 0.004) | (np.abs(y - wy - 0.085) < 0.004))] = C.srgb("#efe9df")
        img[(x >= x0) & (x < x1) & (np.abs(y - 0.47) < 0.008)] = C.srgb("#2a2a2e")      # le balcon de fer
        bars = (x >= x0) & (x < x1) & (y > 0.47) & (y < 0.51) & (((x * 160) % 1) < 0.25)
        img[bars] = C.srgb("#2a2a2e")
    gy, gx = np.mgrid[0:h, 0:w]
    ragged = (_fbm(h, w, 10, 10, 3) - 0.5) * 26
    for cx, cy, r, tone in ((0.18, 0.55, 110, "#6d9a3e"), (0.08, 0.7, 80, "#86ad45"), (0.3, 0.68, 70, "#577f34")):
        d = np.hypot(gx - cx * w, gy - cy * h) + ragged
        leaves = _hex(tone) * (0.72 + 0.62 * _fbm(h, w, 8, 8, 3))[..., None]
        img[d < r] = leaves[d < r]
    trunk = (np.abs(x - 0.18) < 0.012) & (y < 0.45)
    img[trunk] = C.srgb("#4a3626")
    img[y < 0.12] = C.srgb("#6f6f74")                                  # la rue
    img[(y < 0.13) & (y > 0.11)] = C.srgb("#d8d4cc")                   # le trottoir
    return C.image("vue_rue", np.clip(img, 0, 1))


def blanket(name, meters=0.6):
    """La couverture de la cage : crème, avec des arcs-en-ciel pastel."""
    size = 256
    x = np.arange(size)[None, :] * np.ones((size, 1)) / size
    y = np.arange(size)[:, None] * np.ones((1, size)) / size
    img = np.ones((size, size, 3)) * _hex("#efe6d6")
    for cx, cy in ((0.25, 0.25), (0.75, 0.75), (0.75, 0.2), (0.25, 0.72)):
        d = np.hypot(x - cx, y - cy)
        for k, tone in enumerate(("#e98b8b", "#f2c46b", "#9cc98a", "#8fb6e0")):
            band = (np.abs(d - (0.12 - k * 0.022)) < 0.009) & (y < cy)
            img[band] = C.srgb(tone)
    fuzz = C.value_noise(size, size, 2, 2)
    img *= (0.94 + 0.1 * (fuzz - 0.5))[..., None]
    return _pack(name, img, fuzz * 0.7, np.full((size, size), 0.95), meters, 0.6)
