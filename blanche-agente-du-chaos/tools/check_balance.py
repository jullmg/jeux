#!/usr/bin/env python3
"""Vérifie l'équilibrage en faisant jouer des robots ; échoue si une des règles du cahier des charges est rompue.

  tools/check_balance.py --games 60      # rapide
  tools/check_balance.py --games 1000    # complet (une vingtaine de minutes)
"""
import argparse, pathlib, sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import calibrate

HONEST = ["prudent_300", "equilibre_300", "equilibre_500", "equilibre_700", "gourmand_300", "novice_700", "sage_300"]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--games", type=int, default=60)
    args = ap.parse_args()
    r = calibrate.simulate(args.games)
    calibrate.table(r)
    get = lambda level, profile: r[(level, profile)]
    problems = []

    def need(ok, text):
        if not ok:
            problems.append(text)

    for level in range(1, 9):
        need(get(level, "sage_300")["caught"] == 0, f"équité : le robot sage est pris au niveau {level}")
        need(get(level, "equilibre_300")["pass_rate"] >= 95, f"niveau {level} : un bon joueur ne le réussit pas toujours")
        need(get(level, "equilibre_300")["three_rate"] >= 25, f"niveau {level} : trois étoiles trop rares")
        # Les deux dernières missions ont le droit de résister davantage.
        need(get(level, "novice_700")["pass_rate"] >= (88 if level <= 6 else 78), f"niveau {level} : trop dur pour un débutant")
        for profile in ("spam_300", "campeur_300"):
            need(get(level, profile)["pass_rate"] <= 1, f"niveau {level} : {profile} réussit")
        need(get(level, "miettes_300")["pass_rate"] <= 5, f"niveau {level} : les miettes suffisent")
        need(get(level, "tetu_300")["three_rate"] <= 3, f"niveau {level} : s'entêter donne trois étoiles")
        need(get(level, "tetu_300")["pass_rate"] <= 35, f"niveau {level} : s'entêter suffit souvent à réussir")
        need(get(level, "tetu_300")["median"] < 0.6 * get(level, "novice_700")["median"],
             f"niveau {level} : s'entêter vaut presque un jeu honnête")
        for profile in HONEST:
            need(get(level, profile)["stuck"] == 0, f"niveau {level} : {profile} reste coincé")
    for level in range(2, 9):
        need(get(level, "equilibre_700")["caught"] >= get(level - 1, "equilibre_700")["caught"] - 0.4,
             f"la difficulté recule au niveau {level} (au coin)")
        need(get(level, "novice_700")["three_rate"] <= get(level - 1, "novice_700")["three_rate"] + 15,
             f"la difficulté recule au niveau {level} (trois étoiles)")
    need(get(8, "equilibre_700")["caught"] >= get(1, "equilibre_700")["caught"] + 2, "le dernier niveau n'est pas plus dur")
    need(get(8, "novice_700")["three_rate"] <= get(1, "novice_700")["three_rate"] - 40, "la courbe de difficulté est trop plate")

    if problems:
        print("\nÉQUILIBRAGE : ÉCHEC")
        for p in problems:
            print("  -", p)
        sys.exit(1)
    print(f"\nÉQUILIBRAGE : OK ({args.games} parties par niveau et par profil)")


if __name__ == "__main__":
    main()
