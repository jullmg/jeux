# Blanche Pronovost agente du Chaos – contexte du projet

Jeu 3D Godot 4.7 (GL Compatibility, 1920×1080) : la chienne Blanche vole de la nourriture pendant que Maman cuisine.
Texte en français du Québec. Cahier des charges : `PROMPT.md` ; avancement et décisions : `docs/etat.md` ; revues :
`docs/revues.md`. Version 1.0.0-rc2 : Mac d'abord, iPad et Android ensuite.

## Vérifier

- `tools/test.sh` (`--complet` pour 1000 parties de robots) : compilation, règles (`tests/run_tests.gd`), vraies entrées
  (`tests/integration.tscn`), parcours complet (`--autotest`), équilibrage (`tools/check_balance.py`). Doit finir par
  « TOUS LES TESTS PASSENT ». Chaque bogue corrigé reçoit un test.
- `tools/check_scripts.sh` : compile et démarre le jeu, rapide.
- `tools/shots.sh DOSSIER [1600x900] [--seulement=menus,jeu,cachette,niveaux,situations,fin,poses] [--pics]` ou
  `--seulement=perf` : captures et mesures. Assembler des images : `tools/montage.sh sortie.png colonnes largeur …`.
- `tools/export.sh` : application macOS dans `build/`, vérifiée (signature, aucune photo, autotest, sauvegarde).
- Fenêtres : toujours muettes, en arrière-plan, sur l'écran du MacBook (`tools/ecran_macbook.sh`), `--no-save`.
  Tout essai sans sauvegarde voulue passe `--no-save`. Fichiers temporaires `zz_*`. `rm` et `cp` demandent une
  confirmation dans ce shell : `/bin/rm -f`, `/bin/cp -f`.
- Après un nouveau `class_name` ou un modèle régénéré : `Godot --headless --path . --import`.

## Organisation

- `game/` : les règles, sans affichage. `sim.gd` (`Sim.step(dt, move, grab)` + liste d'événements, graine fixe),
  `kitchen_map.gd` (collisions, ligne de vue de l'îlot), `nav.gd` (A*), `follower.gd`, `bot.gd` (robots),
  `levels.gd`, `save_data.gd`, `texts.gd` (**tout le texte**).
- `data/kitchen.json` : **plan unique** (meubles, endroits à nourriture, postes de Maman, caméra), lu par Godot et par
  Blender. Mètres, x vers l'est, z vers la caméra.
- `levels/niveau_N.json` : les huit missions. Étoiles recalculées par `tools/calibrate.py --write-stars`.
- `kitchen/stage.gd` : la scène 3D qui montre une `Sim`. `characters/` : `rig.gd` (poses par code, rotations dans les
  axes du modèle), `dog_view.gd`, `person_view.gd`. `ui/` : `hud.gd`, `menus.gd`, `ui_style.gd`, `icons.gd`.
- `scenes/main.gd` : états, commandes, sons, sauvegarde. `scenes/autotest.gd`, `scenes/scenario.gd` : essais.
- `audio/sound.gd` (autoload `Sound`).

## Règles du jeu à ne pas casser

- Toute période où Maman surveille commence par un indice d'au moins `hint_min` ; redescendre (0,2 s) est plus court que
  tout indice. Un appui la gueule pleine lâche le morceau. Le robot « sage » ne doit **jamais** être pris.
- Les pattes en l'air, Blanche n'est jamais cachée (ni de Maman, ni de Charlotte).
- Aucun poste de Maman ne doit coincer Blanche (`test_maman_ne_coince_jamais`) : le revérifier si le plan change.
- Les stratégies dégénérées (marteler, camper, miettes seulement, ne jamais redescendre) ne gagnent pas.

## Art et son

- **Ne jamais modifier un `.glb` ni un `.wav` à la main** : changer le script (`tools/blender/*.py`,
  `tools/audio/generate_audio.py`) et régénérer. Aperçus dans `art/previews/` (non versionnés) : les regarder.
- Blanche est un **chiot de cinq mois**, petit et mignon (demande de Julien). Sa taille est `TAILLE` dans `dog.py` et
  `DogView.SIZE` (même valeur, testée) ; dressée, elle est soulevée et étirée pour accrocher ses pattes au meuble
  (`DogView._plant_feet`, `STRETCH`), et `stage.gd` la place en face du morceau.
- Musique **joyeuse** (demande de Julien) : `jeu` et `tension` ont le même tempo, la même durée et les mêmes accords.
- `common.py` : tout est écrit en coordonnées Godot. Les personnages sont une peau liée à un squelette ; les noms d'os
  sont utilisés par le code (`test_modeles_complets`).
- Performance : ne pas créer de matière ou d'objet 3D en pleine partie (recompilation de shader, à-coup de 135 ms) : les
  fabriquer une fois et les montrer ou cacher.

## Vie privée

`reference/` (photos de famille et de la maison) est ignoré par git et exclu de l'exportation. N'en tirer aucune texture,
aucun visage, aucune inscription.
