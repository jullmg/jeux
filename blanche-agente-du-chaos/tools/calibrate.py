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
# Cibles des seuils, mesurées sur le robot débutant (lent à réagir et à se décider) :
# part qui rate le niveau (1re étoile), puis part qui obtient trois étoiles.
FAIL_TARGET = [3, 4, 5, 6, 7, 8, 9, 10]
THREE_TARGET = [58, 50, 43, 36, 28, 21, 15, 9]
# Une personne est moins efficace qu'un robot (elle vise, hésite, regarde ailleurs) : la 1re étoile ne demande qu'une
# part du score des débutants. À ajuster après les essais humains.
HUMAN = 0.45
# La première étoile du tutoriel reste facile, et la dernière mission reste gagnable.
STAR1_MAX = {1: 700, 8: 850}


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
    """1 étoile : au-dessus de ce qu'on obtient sans jamais redescendre ; 3 étoiles : une courbe qui se resserre."""
    results = simulate(games, ["novice_700", "tetu_300"])
    round50 = lambda v: int(round(v / 50.0) * 50)
    for level in range(1, 9):
        novice = sorted(results[(level, "novice_700")]["scores"])
        stubborn = sorted(results[(level, "tetu_300")]["scores"])
        quantile = lambda scores, percent: scores[min(len(scores) - 1, int(len(scores) * percent / 100))]
        s1 = max(300, quantile(novice, FAIL_TARGET[level - 1]) * HUMAN, quantile(stubborn, 82))
        s1 = round50(min(s1, STAR1_MAX.get(level, s1)))
        s3 = round50(max(quantile(novice, 100 - THREE_TARGET[level - 1]), s1 * 1.9))
        s2 = round50(s1 + (s3 - s1) * 0.5)
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
