# Blanche Pronovost agente du Chaos – contexte du projet

Jeu 3D Godot 4.7 (Forward+ sur Mac, 1920×1080) : la chienne Blanche vole de la nourriture pendant que Maman cuisine.
Texte en français du Québec. Cahier des charges : `PROMPT.md` ; avancement et décisions : `docs/etat.md` ; revues :
`docs/revues.md` ; refonte graphique : `PROMPT-GRAPHIQUES.md` ; salle à manger et salon (missions 9 à 15, en cours :
moteur et données faits, 3D, personnages, nourriture et interface à venir) : `PROMPT-PIECES.md`, photos dans
`reference/photos-8/`. Version 1.0.0-rc4 : Mac d'abord, iPad et Android
ensuite.

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
  `room_map.gd` (`RoomMap` : collisions, cachettes et ligne de vue d'une pièce), `nav.gd` (A*), `follower.gd`,
  `bot.gd` (robots), `levels.gd`, `save_data.gd`, `texts.gd` (**tout le texte**).
- `data/pieces/<pièce>.json` : **le plan de chaque pièce** (meubles, cachettes, endroits à nourriture, postes, places
  assises, caméra), lu par Godot et par Blender : `cuisine`, `salle_a_manger`, `salon`, `fetes` (les deux réunies).
  Mètres, x vers l'est, z vers le sud. Les cachettes sont une liste : `"bloc"` (l'îlot, le divan : l'ombre derrière) ou
  `"dessous"` (la table : personne debout ne voit dessous ; assis, on voit sa moitié). Un poste peut être `"assis"`,
  `"dehors"` (Maman à la cuisine : son retour est un indice « retour », puis elle apparaît dans `mom_door`) ou regarder
  `"devant"`. Sans modèle 3D, la pièce est montrée en gris (`kitchen/maquette.gd`).
- `levels/niveau_N.json` : les missions. Chaque niveau dit sa pièce (`"piece"`, la cuisine par défaut), qui surveille
  (`"watcher"`, Maman ou Papa), ses personnes assises (`"seated"` : `complice`, `temoin`, `decor`), sa visite qui
  circule (`"walkers"`), le noir (`"dark"`). Étoiles recalculées par `tools/calibrate.py --write-stars`.
- **Les missions 1 à 8 doivent jouer exactement comme avant** : `tests/regression.gd` rejoue 144 parties de robots et
  les compare à `tests/regression_cuisine.json` (dans `tools/test.sh`). Une nouvelle règle ne touche pas au hasard de
  la cuisine.
- Le double salon (salle à manger et salon) est **un seul modèle**, `art/models/double_salon.glb` (script
  `tools/blender/double_salon.py`, aides partagées dans `tools/blender/decor.py`) : chaque plan dit ce que sa caméra
  doit cacher (`"cache"`), l'objet `Noel` n'est montré qu'au moment « noel », un seul `Ecran*` de la télé à la fois.
  `Ambiance.set_room()` change les lumières et la sonde de reflets (`"probe"` du plan). La visite : `tante.glb`,
  `oncle.glb` (`people.py -- tante oncle`). `PersonView.seat_y` assoit quelqu'un (les jambes plient sous toute pose) ;
  `"hanches"` et `"siege"` d'une place ou d'un poste disent où et à quelle hauteur.
- `kitchen/stage.gd` : la scène 3D qui montre une `Sim` ; `kitchen/ambiance.gd` : lumières, rendu et moments du jour
  (`"moment"` de chaque niveau) ; `kitchen/effects.gd` : les particules. `characters/` : `rig.gd` (poses par code, rotations dans les
  axes du modèle), `dog_view.gd`, `person_view.gd`. `ui/` : `hud.gd`, `menus.gd`, `ui_style.gd`, `icons.gd`,
  `logo.gd`, `confetti.gd`.
- `scenes/main.gd` : états, commandes, sons, sauvegarde. `scenes/autotest.gd`, `scenes/scenario.gd` : essais.
- `audio/sound.gd` (autoload `Sound`).

## Règles du jeu à ne pas casser

- Toute période où Maman surveille commence par un indice d'au moins `hint_min` ; redescendre (0,2 s) est plus court que
  tout indice. Un appui la gueule pleine lâche le morceau. Le robot « sage » ne doit **jamais** être pris.
- Les pattes en l'air, Blanche n'est jamais cachée (ni de Maman, ni de Charlotte).
- Aucun poste de Maman ne doit coincer Blanche (`test_maman_ne_coince_jamais`) : le revérifier si le plan change.
- Les stratégies dégénérées (marteler, camper, miettes seulement, ne jamais redescendre) ne gagnent pas.
- La méfiance (`Sim.suspicion`, constantes `WARY_*`) doit **se voir monter** dans toutes les missions (testé).
- La chicane (`activity == "chicane"`) : Maman ne surveille pas ; ce qui suit repasse toujours par un indice. Quelqu'un
  d'immobile n'est pas un obstacle (`Sim.people_circles`), sinon Blanche peut rester coincée.
- Après tout changement de règle : `tools/calibrate.py --games 400 --write-stars`, puis `tools/test.sh`.

## Art et son

- **Ne jamais modifier un `.glb` ni un `.wav` à la main** : changer le script (`tools/blender/*.py`,
  `tools/audio/generate_audio.py`) et régénérer. Aperçus dans `art/previews/` (non versionnés) : les regarder.
- Blanche est un **chiot de cinq mois**, petit et mignon (demande de Julien). Sa taille est `TAILLE` dans `dog.py` et
  `DogView.SIZE` (même valeur, testée) ; dressée, elle est soulevée et étirée pour accrocher ses pattes au meuble
  (`DogView._plant_feet`, `STRETCH`), et `stage.gd` la place en face du morceau.
- Têtes des personnages : `tools/blender/heads.py` (`LOOKS` par personne) ; corps fondus en surfaces lisses dans
  `people.py` (`_soft`). Matières : `tools/blender/textures.py` (couleur, relief, brillance).
- Les couleurs peintes aux sommets des personnages sont enregistrées en **sRGB** (`C.for_game`) ;
  `PersonView._paint_by_vertex` le dit au moteur Forward+ (le moteur mobile les prend telles quelles).
- Maman ne doit pas avoir un visage large (demande de Julien) ; son visage reste visible quand elle regarde (signes à
  côté de sa tête, `Hud._beside_mom`, tête haute dans la pose « look »).
- Les images des plats des menus (`art/ui/plat_N.png`) sont rendues par `food.py` (`PLATS`).
- Décor de la cuisine : rien près des endroits à nourriture ; l'objet `Noel` n'est montré qu'au moment « noel » ; le
  tapis reste sous la zone cachée (hauteur < 0,006).
- Sur le moteur mobile (iPad, Android), le jeu démarre mais la lumière est trop forte : à régler avant d'y livrer.
- `tools/shots.sh` ignore un avertissement du moteur à la fermeture (images de la sonde de reflets).
- **Mesurer la performance aux tailles des écrans de Julien** (3440×1440 et plein écran Retina 3456×2160), pas
  seulement en 1080p : `tools/shots.sh dossier 3440x1440 --seulement=perf` (sans limite ; `--cadence` pour le jeu tel
  qu'on y joue). Référence M1 Pro : environ 105 images/s en 3440×1440, 95 en Retina.
- `kitchen/fluidity.gd` règle la part calculée en 3D et la cadence ; `stage.tick()` interpole les positions entre les
  pas des règles (`physics_jitter_fix` à 0).
- Musique **joyeuse** (demande de Julien) : `jeu` et `tension` ont le même tempo, la même durée et les mêmes accords.
- `common.py` : tout est écrit en coordonnées Godot. Les personnages sont une peau liée à un squelette ; les noms d'os
  sont utilisés par le code (`test_modeles_complets`).
- Performance : ne pas créer de matière ou d'objet 3D en pleine partie (recompilation de shader, à-coup de 135 ms) : les
  fabriquer une fois et les montrer ou cacher.

## Vie privée

`reference/` (photos de famille et de la maison) est ignoré par git et exclu de l'exportation. N'en tirer aucune texture,
aucun visage, aucune inscription.
