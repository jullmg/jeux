# Grille d'essais humains

Les robots vérifient que le jeu fonctionne et que l'équilibre se tient. Ils ne savent pas s'il est **amusant**.
Faire jouer chacun sans rien expliquer, regarder, puis remplir.

| Question | Joueur 1 | Joueur 2 | Joueur 3 |
|---|---|---|---|
| Prénom ou rôle, âge | | | |
| A compris quoi faire sans aide (mission 1) ? | | | |
| A compris qu'il faut maintenir le bouton ? | | | |
| A remarqué le « ! » à temps ? | | | |
| A compris la cachette derrière l'îlot (mission 2) ? | | | |
| S'est senti pris injustement ? Quand ? | | | |
| Mission la plus haute réussie, étoiles | | | |
| Un niveau trop dur ? Trop facile ? | | | |
| Un moment qui a fait rire ? | | | |
| Une chose agaçante ? | | | |
| Avait envie de recommencer ? | | | |
| Reconnaît la cuisine, Blanche, les personnages ? | | | |

## Réglages faciles à changer

| Si… | Changer |
|---|---|
| Trop dur de réagir | `hint_min` (secondes) dans `levels/niveau_N.json` |
| Fenêtres trop courtes | `window_mult` |
| Étoiles trop difficiles | `stars`, ou le facteur `HUMAN` de `tools/calibrate.py` puis `--write-stars` |
| Niveaux trop longs | `duration` |
| Pas assez de nourriture | `spawn`, `max_items`, `weights` |
