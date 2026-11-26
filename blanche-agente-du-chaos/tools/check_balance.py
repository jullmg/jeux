#!/usr/bin/env python3
"""Vérifie l'équilibrage en faisant jouer des robots ; échoue si une des règles du cahier des charges est rompue.

  tools/check_balance.py --games 60      # rapide
  tools/check_balance.py --games 1000    # complet (une vingtaine de minutes)
"""
import argparse, json, pathlib, sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import calibrate

# Les premières missions d'une nouvelle pièce (la salle à manger, le salon, les deux réunies) : la difficulté y
# redescend un peu. Et les missions qui ont le droit de résister davantage.
PIECES = {l: json.loads((calibrate.ROOT / "levels" / f"niveau_{l}.json").read_text()).get("piece", "cuisine")
          for l in calibrate.LEVELS}
ROOM_START = {l for l in calibrate.LEVELS if l > 1 and PIECES[l] != PIECES[l - 1]}
HARDER = {7, 8, 11, 12, 14, 15}
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

    last = max(calibrate.LEVELS)
    for level in calibrate.LEVELS:
        need(get(level, "sage_300")["caught"] == 0, f"équité : le robot sage est pris au niveau {level}")
        need(get(level, "equilibre_300")["pass_rate"] >= 95, f"niveau {level} : un bon joueur ne le réussit pas toujours")
        need(get(level, "equilibre_300")["three_rate"] >= 25, f"niveau {level} : trois étoiles trop rares")
        # Les missions qui terminent une pièce ont le droit de résister davantage.
        need(get(level, "novice_700")["pass_rate"] >= (78 if level in HARDER else 88),
             f"niveau {level} : trop dur pour un débutant")
        for profile in ("spam_300", "campeur_300"):
            need(get(level, profile)["pass_rate"] <= 1, f"niveau {level} : {profile} réussit")
        need(get(level, "miettes_300")["pass_rate"] <= 5, f"niveau {level} : les miettes suffisent")
        need(get(level, "tetu_300")["three_rate"] <= 3, f"niveau {level} : s'entêter donne trois étoiles")
        need(get(level, "tetu_300")["pass_rate"] <= 35, f"niveau {level} : s'entêter suffit souvent à réussir")
        need(get(level, "tetu_300")["median"] < 0.6 * get(level, "novice_700")["median"],
             f"niveau {level} : s'entêter vaut presque un jeu honnête")
        for profile in HONEST:
            need(get(level, profile)["stuck"] == 0, f"niveau {level} : {profile} reste coincé")
    # La difficulté monte d'une mission à l'autre, sauf au début d'une nouvelle pièce, où elle redescend un peu.
    for level in calibrate.LEVELS:
        if level == 1 or level in ROOM_START:
            continue
        need(get(level, "equilibre_700")["caught"] >= get(level - 1, "equilibre_700")["caught"] - 0.4,
             f"la difficulté recule au niveau {level} (au coin)")
        need(get(level, "novice_700")["three_rate"] <= get(level - 1, "novice_700")["three_rate"] + 15,
             f"la difficulté recule au niveau {level} (trois étoiles)")
    need(get(8, "equilibre_700")["caught"] >= get(1, "equilibre_700")["caught"] + 2, "la cuisine n'est pas plus dure à la fin")
    need(get(8, "novice_700")["three_rate"] <= get(1, "novice_700")["three_rate"] - 40, "la courbe de difficulté est trop plate")
    # La finale se joue dans une autre pièce que la mission d'avant (les deux pièces réunies) : elle peut y envoyer moins
    # souvent au coin, mais elle reste la plus dure à réussir.
    need(get(last, "novice_700")["pass_rate"] <= get(last - 1, "novice_700")["pass_rate"],
         "la dernière mission se réussit plus souvent que celle d'avant")
    need(get(last, "novice_700")["three_rate"] <= get(last - 1, "novice_700")["three_rate"],
         "la dernière mission donne plus souvent trois étoiles que celle d'avant")
    first_new = min(ROOM_START)
    need(get(last, "novice_700")["three_rate"] <= get(first_new, "novice_700")["three_rate"] - 20,
         "la dernière mission n'est pas plus dure que le début de la salle à manger (trois étoiles)")
    need(get(last, "equilibre_700")["caught"] >= get(first_new, "equilibre_700")["caught"] + 1.5,
         "la dernière mission n'est pas plus dure que le début de la salle à manger (au coin)")
    need(get(last, "novice_700")["pass_rate"] <= get(first_new, "novice_700")["pass_rate"] - 5,
         "la dernière mission n'est pas plus dure que le début de la salle à manger (réussite)")

    if problems:
        print("\nÉQUILIBRAGE : ÉCHEC")
        for p in problems:
            print("  -", p)
        sys.exit(1)
    print(f"\nÉQUILIBRAGE : OK ({args.games} parties par niveau et par profil)")


if __name__ == "__main__":
    main()
