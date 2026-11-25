#!/usr/bin/env python3
"""Fait jouer les robots en parallèle et résume les résultats.

  tools/calibrate.py --games 300                 # tableau
  tools/calibrate.py --games 300 --write-stars   # recalcule les seuils d'étoiles dans levels/
"""
import argparse, concurrent.futures, json, os, pathlib, subprocess, sys, tempfile

ROOT = pathlib.Path(__file__).resolve().parent.parent
GODOT = os.environ.get("GODOT", "/Applications/Godot.app/Contents/MacOS/Godot")
PROFILES = ["sage_300", "prudent_300", "equilibre_300", "equilibre_500", "equilibre_700", "gourmand_300", "novice_700",
            "tetu_300", "spam_300", "miettes_300", "campeur_300"]
# Part des débutants qui ratent chaque niveau, visée par le seuil de la première étoile.
FAIL_TARGET = [3, 8, 12, 17, 22, 28, 34, 40]
# Une personne est moins efficace qu'un robot (elle vise, hésite, regarde ailleurs) : part des scores robots demandée
# pour 1, 2 et 3 étoiles. À ajuster après les essais humains.
HUMAN = [0.45, 0.5, 0.72]


def run(level, profile, games, folder):
    out = os.path.join(folder, f"{level}_{profile}.json")
    cmd = [GODOT, "--headless", "--path", str(ROOT), "-s", "res://tests/run_bots.gd", "--", "--no-save",
           f"--levels={level}", f"--profiles={profile}", f"--games={games}", f"--out={out}"]
    res = subprocess.run(cmd, capture_output=True, text=True, timeout=1800)
    errors = [l for l in (res.stdout + res.stderr).splitlines() if "ERROR" in l]
    if errors or not os.path.exists(out):
        raise RuntimeError(f"niveau {level} {profile} : " + "\n".join(errors[:5]))
    with open(out) as f:
        return json.load(f)[0]


def simulate(games, profiles=PROFILES, levels=range(1, 9)):
    with tempfile.TemporaryDirectory() as folder, concurrent.futures.ThreadPoolExecutor(max(2, os.cpu_count() - 2)) as pool:
        jobs = [pool.submit(run, l, p, games, folder) for l in levels for p in profiles]
        return {(r["level"], r["profile"]): r for r in (j.result() for j in jobs)}


def table(results):
    for (level, profile), r in sorted(results.items()):
        print(f"niveau {level} {profile:<14} médiane {r['median']:>5}  q25 {r['q25']:>5}  q75 {r['q75']:>5}  "
              f"réussite {r['pass_rate']:>5.1f}%  3★ {r['three_rate']:>5.1f}%  au coin {r['caught']:>5.2f}  "
              f"trésor {r['treasure']:>5.1f}%  coincé {r['stuck']}")


def write_stars(games):
    """Seuils : 1 étoile selon les débutants, 2 et 3 étoiles selon les bons joueurs, avec une marge pour des humains."""
    sys.path.insert(0, str(ROOT / "tools"))
    for level in range(1, 9):
        path = ROOT / "levels" / f"niveau_{level}.json"
        data = json.loads(path.read_text())
        # Des seuils impossibles à franchir pendant la mesure : on lit seulement les scores.
        data["stars"] = [1, 2, 3]
        path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n")
    with tempfile.TemporaryDirectory() as folder, concurrent.futures.ThreadPoolExecutor(max(2, os.cpu_count() - 2)) as pool:
        def scores(level, profile):
            return run(level, profile, games, folder)
        jobs = {(l, p): pool.submit(scores, l, p) for l in range(1, 9) for p in ["novice_700", "equilibre_500", "equilibre_300"]}
        results = {k: v.result() for k, v in jobs.items()}
    round50 = lambda v: int(round(v / 50.0) * 50)
    for level in range(1, 9):
        novice = sorted(results[(level, "novice_700")]["scores"])
        s1 = round50(max(300, novice[int(len(novice) * FAIL_TARGET[level - 1] / 100)] * HUMAN[0]))
        s2 = round50(max(results[(level, "equilibre_500")]["median"] * HUMAN[1], s1 * 1.5))
        s3 = round50(max(results[(level, "equilibre_300")]["median"] * HUMAN[2], s2 * 1.3))
        path = ROOT / "levels" / f"niveau_{level}.json"
        data = json.loads(path.read_text())
        data["stars"] = [s1, s2, s3]
        path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n")
        print(f"niveau {level} : étoiles {data['stars']}")


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--games", type=int, default=200)
    ap.add_argument("--write-stars", action="store_true")
    args = ap.parse_args()
    if args.write_stars:
        write_stars(args.games)
    else:
        table(simulate(args.games))
