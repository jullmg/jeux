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


def quarrel(base, seed):
    """Quelques syllabes bougonnes, sans paroles : la voix monte et retombe à chacune."""
    own = np.random.default_rng(seed)
    sounds = (vowel((750, 600, 130, 1.0), (1350, 1150, 200, 0.6)), vowel((450, 520, 100, 1.0), (900, 850, 150, 0.7)),
              vowel((400, 550, 100, 1.0), (2000, 1700, 220, 0.45)))
    parts, at = [], 0.0
    for i in range(6):
        d = own.uniform(0.09, 0.16)
        f = base * own.uniform(0.9, 1.3)
        syllable = voice(lambda u, f=f: np.interp(u, [0, 0.45, 1], [f, f * 1.14, f * 0.85]), sounds[i % 3], d,
                         attack=0.015, release=0.035)
        parts.append((at, syllable, own.uniform(0.7, 1.0)))
        at += d * 0.95
    return mix(*parts)


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
    tune = (67, 71, 72, 71, 69, 67, 64, 67, 69, 72, 71, 67)
    notes = [(i * 0.42, voice(lambda u, f=hz(n - 12): np.full_like(u, f), vowel((250, 250, 80, 1.0), (1100, 1100, 200, 0.12)),
                                0.46 if i % 4 == 3 else 0.38, breath=0.008, attack=0.07, release=0.12), 1.0)
             for i, n in enumerate(tune)]
    save("fredon", mix(*notes, (len(tune) * 0.42, np.zeros(int(0.9 * SR)), 1.0)), 0.5)
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
    """Corde pincée (Karplus-Strong), accordée juste."""
    n = int(seconds * SR)
    period = max(2, int(SR / f))
    buf = rng.uniform(-1, 1, period)
    buf = bright * buf + (1 - bright) * np.convolve(buf, np.ones(5) / 5, mode="same")
    # la période est un nombre entier d'échantillons (plus un demi du filtre) : on relit au bon rythme pour la justesse
    ratio = f * (period + 0.5) / SR
    out = np.zeros(int(n * ratio) + 2)
    for i in range(0, len(out), period):
        k = min(period, len(out) - i)
        out[i:i + k] = buf[:k]
        buf = 0.994 * 0.5 * (buf + np.roll(buf, 1))
    out = np.interp(np.arange(n) * ratio, np.arange(len(out)), out)
    return out * env(n, 0.002, 0.04)


def kick():
    return sweep(140, 45, 0.14, attack=0.002, release=0.08)


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


# Les instruments du jeu : ukulélé, tuba, sifflet, clochettes, claquements de mains.

def strum(notes, seconds, up=False):
    """Un coup d'ukulélé : les cordes l'une après l'autre."""
    parts = []
    for k, n in enumerate(reversed(notes) if up else notes):
        string = pluck(hz(n), seconds, 0.75)
        parts.append((k * 0.011, string * np.exp(-t(seconds)[:len(string)] / 0.28), 0.8 if up else 1.0))
    return mix(*parts)


def tuba(f, seconds):
    s = t(seconds)
    x = np.sin(2 * np.pi * f * s) + 0.45 * np.sin(2 * np.pi * 2 * f * s) + 0.12 * np.sin(2 * np.pi * 3 * f * s)
    return x * np.exp(-s * 4.5) * env(len(s), 0.012, 0.05)


def whistle(f, seconds):
    s = t(seconds)
    scoop = 1 - 0.035 * np.exp(-s / 0.025)
    vibrato = 1 + 0.009 * np.sin(2 * np.pi * 5.8 * s) * np.clip((s - 0.09) / 0.1, 0, 1)
    phase = 2 * np.pi * np.cumsum(f * scoop * vibrato) / SR
    x = np.sin(phase) + 0.06 * np.sin(2 * phase) + noise(seconds, f * 0.9, f * 1.2) * 0.03
    return x * env(len(s), 0.028, 0.06)


def glock(f, seconds):
    s = t(seconds)
    x = np.sin(2 * np.pi * f * s) * np.exp(-s * 5) + 0.4 * np.sin(2 * np.pi * f * 2.76 * s) * np.exp(-s * 11) \
        + 0.15 * np.sin(2 * np.pi * f * 5.4 * s) * np.exp(-s * 20)
    return x * env(len(s), 0.002, 0.05)


def clap():
    burst = lambda: noise(0.03, 900, 3600, attack=0.001, decay=0.007)
    return mix((0.0, burst(), 0.7), (0.011, burst(), 0.8), (0.022, noise(0.14, 900, 3200, attack=0.001, decay=0.035), 1.0))


def shaker():
    return noise(0.07, 5000, 9500, attack=0.014, decay=0.02)


def woodblock(f):
    s = t(0.09)
    return (np.sin(2 * np.pi * f * s) * np.exp(-s * 55) + 0.4 * np.sin(2 * np.pi * f * 2.4 * s) * np.exp(-s * 120)) \
        * env(len(s), 0.001, 0.02)


# accord : (cordes de l'ukulélé, basse, quinte)
CHORDS = {
    "C": ([60, 64, 67, 72], 48, 43), "F": ([60, 65, 69, 72], 41, 48), "G": ([59, 62, 67, 71], 43, 50),
    "Am": ([60, 64, 69, 72], 45, 40), "D7": ([60, 62, 66, 69], 38, 45), "G7": ([59, 62, 65, 67], 43, 38),
}
# une mesure : un accord, ou deux (un par moitié)
SONG = ["C", "C", "F", "G", "C", "Am", ("F", "G"), "C", "F", "C", "G", "Am", "F", "C", "D7", "G7"]
MENU_SONG = ["C", "G", "Am", "F", "C", "G", ("F", "G"), "C"]
# huit croches par mesure
GAME_TUNE = [
    [76, None, 79, 79, None, 76, 72, None], [74, 76, None, 79, None, None, 67, 69],
    [72, None, 81, None, 79, 77, 76, 77], [79, None, None, 74, 71, None, 74, None],
    [76, None, 79, 79, None, 76, 72, None], [76, 76, None, 81, None, 79, 76, None],
    [77, None, 81, 77, 74, None, 79, 83], [84, None, None, None, 79, None, None, None],
    [81, 84, 81, None, 77, None, 81, None], [79, 84, 79, None, 76, None, 79, None],
    [74, 79, 74, None, 71, None, 74, 76], [76, None, 72, None, 69, None, 72, 76],
    [77, 77, 81, None, 79, 77, None, 81], [79, 79, 76, None, 79, 84, None, None],
    [74, 78, 81, None, 86, None, 81, 78], [79, None, 83, None, 74, None, 71, 74],
]
MENU_TUNE = [
    [72, None, 76, 79, 84, None, 79, None], [74, None, 79, 83, 81, 79, None, None],
    [76, None, 81, 84, 81, None, 76, None], [77, 79, 81, None, 77, None, None, None],
    [72, None, 76, 79, 84, None, 88, None], [86, 83, 79, None, 74, None, 79, None],
    [81, 81, 77, None, 83, 83, 79, None], [84, None, 79, None, 84, None, None, None],
]
GAME_BPM = 118  # la couche de tension joue par-dessus la musique du jeu : même tempo, même longueur
SHUFFLE = 0.08  # les croches « en l'air » traînent un peu : ça sautille


def chord_at(bar, when):
    c = bar if isinstance(bar, str) else bar[0 if when < 2 else 1]
    return CHORDS[c]


def at_beat(bar_start, when, beat):
    return bar_start + (when + (SHUFFLE if when % 1 else 0.0)) * beat


def band(song, beat, claps=True):
    """L'accompagnement : ukulélé, basse sautillante, grosse caisse, mains et maracas."""
    for bar, chords in enumerate(song):
        start = bar * 4 * beat
        for when, up, gain in ((0, False, 1.0), (1, False, 0.75), (1.5, True, 0.6), (2.5, True, 0.65),
                               (3, False, 0.8), (3.5, True, 0.6)):
            yield at_beat(start, when, beat), strum(chord_at(chords, when)[0], beat * 0.75, up), 0.11 * gain
        for when, which in ((0, 1), (2, 2)):
            root = chord_at(chords, when)[which if isinstance(chords, str) else 1]
            yield start + when * beat, tuba(hz(root), beat * 0.85), 0.42
        if bar % 2 == 1:
            yield at_beat(start, 3.5, beat), tuba(hz(chord_at(chords, 3.5)[2]), beat * 0.45), 0.3
        for when in (0, 2):
            yield start + when * beat, kick(), 0.4
        if claps:
            for when in (1, 3):
                yield start + when * beat, clap(), 0.2
        for k in range(8):
            yield at_beat(start, k / 2, beat), shaker(), 0.075 if k % 2 else 0.045


def melody(tune, beat, instrument, gain, octave=0, from_bar=0):
    for bar, notes in enumerate(tune):
        for k, note in enumerate(notes):
            if note is None:
                continue
            # une note tient jusqu'à la suivante
            hold = 1
            while k + hold < 8 and notes[k + hold] is None:
                hold += 1
            start = (from_bar + bar) * 4 * beat
            yield at_beat(start, k / 2, beat), instrument(hz(note + octave), beat * min(hold, 3) * 0.48), gain


def menu_parts(beat):
    """Le thème d'accueil : d'abord aux clochettes, puis sifflé."""
    yield from band(MENU_SONG * 2, beat)
    yield from melody(MENU_TUNE, beat, glock, 0.3)
    yield from melody(MENU_TUNE, beat, whistle, 0.2, from_bar=8)
    yield from melody(MENU_TUNE, beat, marimba, 0.16, -12, from_bar=8)


def game_parts(beat):
    """En jeu : un petit air sifflé qui trotte, repris aux clochettes."""
    yield from band(SONG, beat)
    yield from melody(GAME_TUNE[:8], beat, whistle, 0.2)
    yield from melody(GAME_TUNE[8:], beat, glock, 0.27, from_bar=8)
    yield from melody(GAME_TUNE[8:], beat, marimba, 0.18, -12, from_bar=8)


def tension_parts(beat):
    """La couche qui monte avec le soupçon : tic-tac de bois et basse qui presse, sans devenir inquiétant."""
    for bar, chords in enumerate(SONG):
        start = bar * 4 * beat
        for k in range(8):
            yield at_beat(start, k / 2, beat), woodblock(1180 if k % 2 == 0 else 880), 0.34 if k % 2 == 0 else 0.22
            yield at_beat(start, k / 2, beat), pluck(hz(chord_at(chords, k / 2)[1] + 12), beat * 0.4, 0.4), 0.28
        if bar % 4 == 3:
            for k in range(8):
                yield start + (3 + k / 8) * beat, clap(), 0.06 + 0.025 * k


def rooms():
    """Les sons de la salle à manger et du salon (après tous les autres : le hasard des sons d'avant ne change pas)."""
    # la foule du hockey : une rumeur qui monte, quelques « ooh »
    crowd = noise(2.2, 250, 2600, attack=0.4, release=0.8) * (0.7 + 0.3 * np.sin(2 * np.pi * 1.3 * t(2.2)))
    oohs = [(0.3 + k * 0.45, voice(lambda u, f=f: f * (1 + 0.15 * u), vowel((420, 420, 90, 1.0), (800, 800, 140, 0.4)), 0.7,
                                   breath=0.08, attack=0.1, release=0.3), 0.25) for k, f in enumerate((170, 220, 196, 247))]
    save("foule", mix((0, crowd, 1.0), *oohs), 0.5)
    # la sirène du but : un klaxon grave et riche, qui tient
    s = t(1.6)
    horn = sum(np.sin(2 * np.pi * 196 * h * s * (1 + 0.004 * np.sin(2 * np.pi * 5 * s))) / h ** 1.2 for h in range(1, 12))
    save("sirene", mix((0, horn * env(len(s), 0.06, 0.4), 1.0), (0.2, crowd[:int(1.4 * SR)], 0.5)), 0.7)
    # une assiette posée sur la table
    save("assiette", mix((0, sine(2350, 0.25, decay=0.05), 1.0), (0.004, sine(3420, 0.2, decay=0.04), 0.6),
                         (0, noise(0.04, 1500, 7000, decay=0.01), 0.5), (0.0, sine(240, 0.08, decay=0.03), 0.6)), 0.5)
    # une chaise qui grince et frotte le plancher
    scrape = noise(0.32, 180, 1100, attack=0.03, release=0.08) * (0.6 + 0.4 * np.sin(2 * np.pi * 31 * t(0.32)))
    save("chaise", mix((0, scrape, 1.0), (0.05, sweep(520, 380, 0.22, attack=0.03, release=0.1), 0.35)), 0.55)
    # le tourne-disque : le crépitement, puis quelques notes joyeuses
    crackle = noise(1.6, 1500, 8000) * (rng.random(int(1.6 * SR)) > 0.985) * 1.0
    melody_ = [(0.35 + i * 0.18, marimba(hz(n), 0.4), 0.7) for i, n in enumerate((72, 76, 79, 84, 79, 76))]
    save("disque", mix((0, crackle, 0.5), (0, noise(1.6, 60, 300, attack=0.1, release=0.3), 0.12), *melody_), 0.55)
    # les clochettes des Fêtes
    bells = [(rng.uniform(0, 0.9), mix((0, sine(f, 0.35, decay=0.08), 1.0), (0, sine(f * 2.76, 0.2, decay=0.05), 0.4)),
              rng.uniform(0.4, 1.0)) for f in rng.uniform(2200, 3600, 16)]
    save("clochettes", mix(*bells), 0.5)


if __name__ == "__main__":
    sfx()
    loop(126, 16, menu_parts, "musique_menu", 0.75)
    loop(GAME_BPM, 16, game_parts, "musique_jeu", 0.75)
    loop(GAME_BPM, 16, tension_parts, "musique_tension", 0.65)
    # à la fin, pour ne pas changer le hasard des sons précédents
    save("chicane_maman", quarrel(265, 21), 0.7)
    save("chicane_papa", quarrel(128, 34), 0.8)
    rooms()
    files = sorted(OUT.glob("*.wav"))
    print(f"AUDIO {len(files)} fichiers, {sum(f.stat().st_size for f in files) // 1024} Ko")
