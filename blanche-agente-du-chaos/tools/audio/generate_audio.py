"""Fabrique tous les sons et les musiques (synthèse pure, aucune ressource externe).

Se lance avec le Python de Blender (qui contient numpy) : tools/build_audio.sh
"""
import pathlib
import wave

import numpy as np

SR = 22050
ROOT = pathlib.Path(__file__).resolve().parents[2]
OUT = ROOT / "audio" / "generated"
rng = np.random.default_rng(2026)


def t(seconds):
    return np.arange(int(seconds * SR)) / SR


def env(n, attack=0.005, release=0.05, decay=0.0):
    x = np.ones(n)
    a = min(n, max(1, int(attack * SR)))
    r = min(n, max(1, int(release * SR)))
    x[:a] *= np.linspace(0, 1, a)
    x[-r:] *= np.linspace(1, 0, r)
    if decay > 0:
        x *= np.exp(-np.arange(n) / SR / decay)
    return x


def sine(f, seconds, **kw):
    s = t(seconds)
    f = np.broadcast_to(f, s.shape) if np.isscalar(f) else f
    return np.sin(2 * np.pi * np.cumsum(np.broadcast_to(f, s.shape)) / SR) * env(len(s), **kw)


def sweep(f0, f1, seconds, **kw):
    s = t(seconds)
    return np.sin(2 * np.pi * np.cumsum(np.linspace(f0, f1, len(s))) / SR) * env(len(s), **kw)


def noise(seconds, low=0.0, high=SR / 2, **kw):
    n = int(seconds * SR)
    spec = np.fft.rfft(rng.standard_normal(n))
    f = np.fft.rfftfreq(n, 1 / SR)
    spec *= 1 / (1 + (np.maximum(low - f, 0) / 80) ** 2) / (1 + (np.maximum(f - high, 0) / 200) ** 2)
    x = np.fft.irfft(spec, n)
    x /= np.max(np.abs(x)) + 1e-9
    return x * env(n, **kw)


def mix(*parts):
    """(début en secondes, signal, volume)"""
    end = max(int(p[0] * SR) + len(p[1]) for p in parts)
    out = np.zeros(end)
    for start, sig, gain in parts:
        i = int(start * SR)
        out[i:i + len(sig)] += sig * gain
    return out


def save(name, x, peak=0.85):
    OUT.mkdir(parents=True, exist_ok=True)
    x = x / (np.max(np.abs(x)) + 1e-9) * peak
    data = (np.clip(x, -1, 1) * 32767).astype("<i2")
    with wave.open(str(OUT / f"{name}.wav"), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(data.tobytes())


# ---------------------------------------------------------------- voix synthétiques

def voice(pitch, formants, seconds, breath=0.04, vibrato=0.015, **kw):
    """pitch et formants : fonctions du temps relatif (0 à 1)."""
    n = int(seconds * SR)
    u = np.linspace(0, 1, n)
    f0 = pitch(u) * (1 + vibrato * np.sin(2 * np.pi * 6 * u * seconds))
    phase = np.cumsum(f0) / SR
    out = np.zeros(n)
    fs = formants(u)
    for h in range(1, 28):
        fh = f0 * h
        amp = np.zeros(n)
        for freq, bw, g in fs:
            amp += g / (1 + ((fh - freq) / bw) ** 2)
        amp *= (fh < SR / 2.2)
        out += np.sin(2 * np.pi * phase * h) * amp / h ** 0.35
    out += noise(seconds, 900, 4000) * breath
    return out * env(n, **kw)


def vowel(*specs):
    def f(u):
        return [(np.interp(u, [0, 1], [a, b]), bw, g) for a, b, bw, g in specs]
    return f


def au_coin():
    o = voice(lambda u: np.interp(u, [0, 0.3, 1], [290, 350, 330]),
              vowel((520, 460, 90, 1.0), (900, 800, 130, 0.7), (2600, 2600, 300, 0.2)), 0.30, attack=0.03, release=0.05)
    k = noise(0.04, 1500, 4500, release=0.02)
    wa = voice(lambda u: np.interp(u, [0, 0.35, 1], [330, 390, 210]),
               lambda u: [(np.interp(u, [0, 0.25, 1], [350, 640, 600]), 110, 1.0),
                          (np.interp(u, [0, 0.25, 1], [750, 1500, 1350]), 160, 0.8),
                          (np.interp(u, [0, 1], [250, 280]), 80, 0.35),
                          (2700, 300, 0.2)], 0.55, attack=0.02, release=0.16)
    return mix((0.0, o, 1.0), (0.34, k, 0.5), (0.37, wa, 1.15))


def mom_hmm(up=True):
    return voice(lambda u: np.interp(u, [0, 0.6, 1], [215, 225, 330 if up else 185]),
                 vowel((280, 300, 90, 1.0), (1100, 1200, 200, 0.25)), 0.38, breath=0.015, attack=0.04, release=0.09)


def hon():
    return voice(lambda u: np.interp(u, [0, 0.25, 1], [420, 560, 470]),
                 vowel((600, 480, 110, 1.0), (1050, 900, 160, 0.7), (3000, 3000, 400, 0.2)), 0.42, attack=0.02, release=0.15)


def maman_call():
    ma = voice(lambda u: np.interp(u, [0, 1], [470, 520]), vowel((800, 850, 130, 1.0), (1450, 1450, 200, 0.7)), 0.22,
               attack=0.03, release=0.04)
    man = voice(lambda u: np.interp(u, [0, 0.4, 1], [560, 620, 480]),
                vowel((750, 520, 130, 1.0), (1350, 1100, 200, 0.6), (260, 260, 70, 0.4)), 0.4, attack=0.03, release=0.15)
    return mix((0, ma, 1), (0.24, man, 1.1))


def bark():
    def one(f):
        v = voice(lambda u: np.interp(u, [0, 0.2, 1], [f, f * 1.35, f * 0.7]),
                  vowel((700, 500, 220, 1.0), (1500, 1100, 350, 0.7)), 0.13, breath=0.35, attack=0.008, release=0.06)
        return v
    return mix((0, one(360), 1), (0.2, one(330), 0.85))


# ---------------------------------------------------------------- bruitages

def sfx():
    save("pas", mix((0, noise(0.05, 80, 700, decay=0.012), 1), (0.001, sine(110, 0.05, decay=0.015), 0.5)), 0.35)
    save("hop", mix((0, sweep(240, 520, 0.09, release=0.05), 0.5), (0, noise(0.07, 300, 1800, decay=0.02), 0.6)), 0.55)
    save("redescend", sweep(430, 220, 0.09, release=0.05), 0.35)
    save("prise", mix((0, sweep(300, 900, 0.07, release=0.03), 1), (0.05, sine(1320, 0.09, decay=0.04), 0.5)), 0.7)
    crunch = [(i * 0.13, noise(0.07, 600, 3800, decay=0.018) * (1 + 0.5 * np.sin(2 * np.pi * 55 * t(0.07))), 1 - i * 0.12)
              for i in range(3)]
    save("mache", mix(*crunch), 0.6)
    save("miette", mix((0, sine(1500, 0.05, decay=0.015), 1), (0.03, sine(2100, 0.05, decay=0.015), 0.6)), 0.45)
    save("avale", mix((0, sine(660, 0.12, decay=0.06), 1), (0.08, sine(990, 0.2, decay=0.09), 0.9)), 0.65)
    save("combo", mix(*[(i * 0.07, sine(f, 0.18, decay=0.08), 1) for i, f in enumerate((660, 830, 990, 1320))]), 0.65)
    save("lache", sweep(500, 180, 0.12, release=0.06), 0.45)
    save("indice", mom_hmm(True), 0.75)
    save("feinte", mom_hmm(False), 0.45)
    save("alerte", mix((0, sine(880, 0.09, release=0.02), 0.8), (0.11, sine(1175, 0.16, decay=0.08), 1.0)), 0.55)
    save("tour", mix(*[(i * 0.12, sine(f, 0.14, decay=0.07), 1) for i, f in enumerate((587, 740, 587, 880))]), 0.6)
    save("demi_tour", noise(0.22, 200, 1400, attack=0.09, release=0.1), 0.35)
    wah = []
    for i, f in enumerate((392, 370, 349)):
        s = t(0.18 if i < 2 else 0.5)
        tone = sum(np.sin(2 * np.pi * f * h * s * (1 + 0.006 * np.sin(2 * np.pi * 7 * s))) / h for h in range(1, 9))
        wah.append((0.75 + i * 0.2, tone * env(len(s), 0.02, 0.1), 0.22))
    save("au_coin", mix((0, au_coin(), 1.0), *wah), 0.95)
    clang = [(rng.uniform(0, 0.22), sine(f, 0.35, decay=0.07), rng.uniform(0.4, 0.9)) for f in (523, 1187, 1733, 2417, 3109, 1480)]
    save("fracas", mix((0, noise(0.2, 900, 6000, decay=0.05), 0.8), *clang), 0.8)
    ring = sine(2093, 1.0, attack=0.002, release=0.1) * (0.55 + 0.45 * np.sign(np.sin(2 * np.pi * 18 * t(1.0))))
    save("minuterie", mix((0, ring, 1), (0, sine(2637, 1.0, release=0.1), 0.35)), 0.5)
    save("frigo", mix((0, noise(0.09, 60, 500, decay=0.025), 1), (0.05, sine(180, 0.5, attack=0.1, release=0.3), 0.2)), 0.55)
    save("couteau", mix((0, noise(0.04, 500, 5000, decay=0.008), 1), (0.002, sine(190, 0.06, decay=0.012), 0.9)), 0.45)
    save("brasse", noise(0.45, 250, 1500, attack=0.2, release=0.2) * (0.6 + 0.4 * np.sin(2 * np.pi * 5 * t(0.45))), 0.25)
    save("eau", noise(1.2, 900, 6500, attack=0.2, release=0.4), 0.22)
    save("tresor", mix(*[(i * 0.06, sine(f, 0.4, decay=0.13), 1) for i, f in enumerate((784, 988, 1175, 1568, 1976, 2349))]), 0.6)
    save("porte", mix((0, noise(0.12, 60, 700, decay=0.03), 1), (0.14, sine(740, 0.12, decay=0.05), 0.35)), 0.5)
    save("hon", hon(), 0.75)
    save("maman_appel", maman_call(), 0.75)
    save("tombe", mix((0, noise(0.1, 60, 600, decay=0.025), 1), (0.01, sine(130, 0.12, decay=0.03), 0.8)), 0.6)
    save("jappe", bark(), 0.8)
    save("libre", mix((0, sine(523, 0.08, release=0.03), 1), (0.07, sine(784, 0.12, decay=0.05), 1)), 0.45)
    save("clic", sine(1200, 0.045, decay=0.014), 0.4)
    save("choix", sine(900, 0.035, decay=0.01), 0.25)
    save("etoile", mix((0, sine(1047, 0.3, decay=0.12), 1), (0.06, sine(1568, 0.35, decay=0.14), 0.8)), 0.65)
    notes = [(0.0, 523), (0.14, 659), (0.28, 784), (0.42, 1047), (0.66, 880), (0.8, 1047)]
    save("victoire", mix(*[(a, marimba(f, 0.5 if a < 0.8 else 1.1), 1) for a, f in notes]), 0.75)
    save("rate", mix(*[(i * 0.28, marimba(f, 0.6), 1) for i, f in enumerate((392, 330, 262))]), 0.65)
    save("repas", mix(*[(i * 0.35, sine(f, 0.9, decay=0.35), 1) for i, f in enumerate((1319, 1047))]), 0.6)


# ---------------------------------------------------------------- musique

def hz(n):
    """n : numéro de note MIDI."""
    return 440.0 * 2 ** ((n - 69) / 12)


def marimba(f, seconds):
    s = t(seconds)
    x = np.sin(2 * np.pi * f * s) * np.exp(-s * 5) + 0.35 * np.sin(2 * np.pi * f * 3.93 * s) * np.exp(-s * 16) \
        + 0.12 * np.sin(2 * np.pi * f * 9.2 * s) * np.exp(-s * 30)
    return x * env(len(s), 0.003, 0.05)


def pluck(f, seconds, bright=0.5):
    """Corde pincée (Karplus-Strong)."""
    n = int(seconds * SR)
    period = max(2, int(SR / f))
    buf = rng.uniform(-1, 1, period)
    buf = bright * buf + (1 - bright) * np.convolve(buf, np.ones(5) / 5, mode="same")
    out = np.zeros(n)
    for i in range(0, n, period):
        k = min(period, n - i)
        out[i:i + k] = buf[:k]
        buf = 0.994 * 0.5 * (buf + np.roll(buf, 1))
    return out * env(n, 0.002, 0.04)


def kick():
    return sweep(140, 45, 0.14, attack=0.002, release=0.08)


def brush(strong=False):
    return noise(0.09, 2500, 8000, decay=0.03 if strong else 0.014)


def loop(bpm, bars, parts_of, name, peak):
    beat = 60.0 / bpm
    total = int(bars * 4 * beat * SR)
    out = np.zeros(total)
    for when, sig, gain in parts_of(beat):
        i = int(when * SR) % total
        n = len(sig)
        # la queue d'une note qui dépasse revient au début : la boucle ne se voit pas
        first = min(n, total - i)
        out[i:i + first] += sig[:first] * gain
        if n > first:
            out[:n - first] += sig[first:] * gain
    save(name, out, peak)


def menu_parts(beat):
    chords = [(48, [60, 64, 67]), (45, [57, 60, 64]), (41, [57, 60, 65]), (43, [59, 62, 67])] * 2
    melody = [
        [76, None, 79, 76, 72, None, 74, 76], [72, None, 76, 72, 69, None, 71, 72],
        [69, 72, 77, None, 76, 74, 72, None], [71, None, 74, 79, 77, 74, 71, None],
        [76, 76, 79, None, 84, None, 79, 76], [72, 72, 76, None, 81, None, 76, 72],
        [77, 76, 74, 72, 69, None, 72, 74], [79, None, 77, 74, 72, None, None, None],
    ]
    for bar, (root, chord) in enumerate(chords):
        at = bar * 4 * beat
        for k, note in enumerate((root, root + 7, root, root + 7)):
            yield at + k * beat, pluck(hz(note), beat * 0.9, 0.3), 0.55
        for k in (1, 3):
            for note in chord:
                yield at + (k + 0.5) * beat, pluck(hz(note), beat * 0.4, 0.55), 0.14
        for k, note in enumerate(melody[bar]):
            if note:
                yield at + k * beat / 2, marimba(hz(note), beat * 1.3), 0.42
        yield at, kick(), 0.5
        yield at + 2 * beat, kick(), 0.4
        for k in range(8):
            yield at + k * beat / 2, brush(k % 2 == 1), 0.07 if k % 2 == 0 else 0.11


BASS = [[38, 45, 41, 45], [38, 45, 41, 44], [43, 50, 46, 50], [45, 49, 52, 49],
        [38, 45, 41, 45], [46, 41, 45, 40], [43, 46, 45, 44], [38, 45, 38, None]]


def game_parts(beat):
    """Ambiance d'espionnage : contrebasse qui marche, pizzicatos et claquements de doigts."""
    motif = [
        [None, 74, None, 77, 76, None, 74, None], [None, 74, None, 77, 80, 81, None, None],
        [None, 79, None, 82, 81, None, 79, None], [76, None, 73, None, 69, None, None, None],
        [None, 74, None, 77, 76, None, 74, 72], [70, None, 69, None, None, 65, 69, None],
        [67, None, 70, 69, None, 68, None, None], [74, None, None, None, None, 69, 71, 73],
    ]
    for bar in range(8):
        at = bar * 4 * beat
        for k, note in enumerate(BASS[bar]):
            if note:
                swing = beat * 0.04 if k % 2 else 0
                yield at + k * beat + swing, pluck(hz(note), beat * 0.95, 0.18), 0.7
        for k, note in enumerate(motif[bar]):
            if note:
                swing = beat * 0.12 if k % 2 else 0
                yield at + k * beat / 2 + swing, pluck(hz(note), beat * 0.7, 0.65), 0.24
        for k in (1, 3):
            yield at + k * beat, noise(0.05, 1500, 4500, decay=0.01), 0.22
        for k in range(8):
            swing = beat * 0.12 if k % 2 else 0
            yield at + k * beat / 2 + swing, brush(), 0.045
        if bar % 4 == 3:
            yield at + 3 * beat, marimba(hz(86), beat), 0.14


def tension_parts(beat):
    """La couche qui monte avec le soupçon : tic-tac, basse pressante et trémolo."""
    for bar in range(8):
        at = bar * 4 * beat
        root = BASS[bar][0]
        for k in range(16):
            yield at + k * beat / 4, noise(0.025, 4000, 9000, decay=0.006), 0.25 if k % 4 == 0 else 0.13
        for k in range(8):
            yield at + k * beat / 2, pluck(hz(root), beat * 0.45, 0.25), 0.35
        s = t(4 * beat)
        trem = (np.sin(2 * np.pi * hz(root + 24) * s) + np.sin(2 * np.pi * hz(root + 25) * s)) * (
            0.5 + 0.5 * np.sin(2 * np.pi * 9 * s))
        yield at, trem * env(len(s), 0.3, 0.3), 0.07


if __name__ == "__main__":
    sfx()
    loop(112, 8, menu_parts, "musique_menu", 0.7)
    loop(104, 8, game_parts, "musique_jeu", 0.7)
    loop(104, 8, tension_parts, "musique_tension", 0.6)
    files = sorted(OUT.glob("*.wav"))
    print(f"AUDIO {len(files)} fichiers, {sum(f.stat().st_size for f in files) // 1024} Ko")
