# Prompt : la salle à manger et le salon (nouvelles missions)

Demande de Julien (2026-11-25) : de nouvelles missions dans la salle à manger et le salon, d'après les photos qu'il a
ajoutées. « Pas obligé de répliquer exactement tous les objets ; il y a un peu de désordre : imagine que les pièces
sont en ordre. »

> Les choix marqués **(P)** sont des propositions : Julien peut les garder, les changer ou les rayer avant de lancer.

## 1. Ta mission

Ajouter à **Blanche Pronovost agente du Chaos** deux nouvelles pièces jouables, **la salle à manger** et **le salon**,
avec leurs missions, à la même qualité que la cuisine (rc4) : règles, plan, modèles 3D, matières, lumière,
personnages, nourriture, sons, textes, interface, tests, équilibrage, performance, application macOS et documentation.
À la fin, on joue les huit missions de la cuisine, puis les nouvelles, du début à la fin, sans toi.

Lis d'abord `CLAUDE.md`, `PROMPT.md` (cahier des charges, toujours valable), `PROMPT-GRAPHIQUES.md` (direction
artistique), `docs/etat.md`, `docs/fiche-reference.md`, puis le code de `game/`, `kitchen/stage.gd`,
`tools/blender/kitchen.py` et un fichier `levels/niveau_N.json`.

Travaille sans t'arrêter aux points de contrôle (comme Julien l'a demandé le 2026-11-24) : chaque choix fait sans lui
est noté dans `docs/etat.md`, section « Choix faits en l'absence de Julien ».

## 2. Les photos

Dans `reference/photos-8/` (extraites de `reference/Photos-1-001 (8).zip`). Jamais versionnées, jamais dans le jeu.

| Photo | Ce qu'on y voit |
|---|---|
| `20261125_124731.jpg` | Du salon (divan au premier plan) vers la salle à manger, avec la grande ouverture du corridor à gauche |
| `20261125_124736.jpg` | La salle à manger : mur du fond foncé, étagère, buffet, cage, table et chaises, lampe sur pied |
| `20261125_124747.jpg` | De la porte de la salle à manger vers le salon et sa fenêtre sur rue |
| `20261125_124757.jpg` | Le salon : divan, mur de cadres, coin de la fenêtre, télé, fauteuils, table basse |

Ce que j'y ai relevé (à vérifier et compléter dans la fiche) :

- **Les deux pièces se suivent** (double salon d'un plex de Montréal) : salon à l'avant, sur la rue ; salle à manger
  derrière. Plafond haut, moulures, rosace de plâtre au-dessus de chaque luminaire. Plancher de lattes étroites
  d'érable miel, luisant ; plinthes de bois foncé ; murs blanc cassé.
- **Salle à manger :** mur du fond **ardoise très foncée** (gris-bleu presque noir) ; porte de bois verni à gauche de ce
  mur ; étagère à montants de fer noir et quatre planches de bois blond, couverte de **céramiques artisanales**
  (tasses, bols, vases aux glaçures pastel) ; buffet bas noir dessous (tourne-disque, disques, jeux de société) ;
  **la cage de Blanche** (fil noir, couverture à motifs, coussin mauve) entre le buffet et le coin ; table de bois
  foncé aux coins arrondis et quatre chaises de style scandinave (dossier de noyer, siège noir) ; suspension globe opale
  sur tige laiton ; lampe sur pied en laiton à globe de verre fumé ; trois affiches encadrées au mur de droite.
- **Salon :** divan **velours côtelé moutarde** ; mur de cadres (cadres noirs, un miroir ovale doré, une horloge de
  bois) ; étagère de coin ancienne en bois foncé ; fauteuil berçant blanc à structure de bois blond ; petit fauteuil
  marine ; grande fenêtre à guillotine, rideaux marine, garde-corps de fer forgé dehors, radiateur blanc dessous ;
  grande télé à droite ; meuble noir sous la télé (un piano numérique ? à confirmer) ; table basse rétro en bois à
  tablette ; une plante sur une petite boîte de bois, un panier ; plafonnier à trois spots.

**Les pièces en ordre :** on ne reproduit pas le désordre (ordinateur, boîtes de mouchoirs, casque d'écoute,
couvertures en boule, fils, papiers). On garde ce qui fait la pièce : les meubles, la cage, les céramiques, le mur
foncé, le divan moutarde, le mur de cadres, les lampes, la fenêtre. On peut simplifier les objets nombreux
(céramiques, disques) en quelques formes lisibles.

**Vie privée (non négociable) :** aucun visage, aucune photo de famille, aucune affiche, aucune inscription, aucune
texture tirés des photos. Les cadres montrent des images génériques fabriquées par script (paysage, motif, chien
stylisé, carte du ciel inventée). Tout est fabriqué par `tools/blender/` et `tools/audio/`.

## 3. Les missions (P)

Toujours la même boucle (attraper quand on ne regarde pas, avoir l'air sage ou être cachée à l'indice, « AU COIN ! »).
Chaque mission ajoute **une seule** nouveauté et la montre avant de la punir. Les missions de la cuisine (1 à 8) ne
changent pas.

| # | Pièce | Repas | Nouveauté | Indice minimal |
|---|---|---|---|---|
| 9 | Salle à manger | Le brunch du dimanche | **Sous la table** : la nouvelle cachette, et la cage comme coin | 600 ms |
| 10 | Salle à manger | Le souper en famille | **Les allers-retours** : Maman sert et repart à la cuisine (porte), puis revient | 550 ms |
| 11 | Salle à manger | La fête de Charlotte | **Charlotte complice** : elle échappe des morceaux sous la table ; si Maman la voit, chicane | 500 ms |
| 12 | Salon | La soirée du hockey | **Papa surveille** du divan ; la **table basse** (pas besoin de se dresser) ; derrière le divan, la cachette | 500 ms |
| 13 | Salon | Le film en famille | **Le noir** : lumières éteintes, la télé éclaire la pièce par éclats ; on voit moins loin, sauf aux scènes claires | 450 ms |
| 14 | Salle à manger et salon | Le party des Fêtes | Tout combiné, la visite qui circule, grand trésor final | 400 ms |

Détails proposés :

- **Le coin** : dans la salle à manger, c'est **sa cage, porte ouverte** (« AU COIN ! » devient parfois « DANS TA
  CAGE ! » : variantes dans `texts.gd`). Dans le salon, un coussin près du radiateur. Le trajet coin → nourriture
  compte toujours.
- **Sous la table (9)** : couchée sous la table de la salle à manger, Blanche est cachée de quelqu'un **debout** ; une
  personne **assise à table** voit sous la table de son côté seulement. Le dessous se lit au plancher comme la zone
  de l'îlot. Les chaises gênent le passage (elles bougent un peu et peuvent grincer, comme le tabouret). Les pattes
  sur la table, Blanche n'est jamais cachée.
- **Les allers-retours (10)** : Maman quitte la pièce par la porte de la cuisine (longue fenêtre, elle n'est plus à
  l'écran) et revient avec un plat. Son retour s'annonce toujours : pas qui approchent, « J'arrive ! », une icône au
  bord de l'écran du côté de la porte, au moins `hint_min` avant qu'elle voie la pièce.
- **Charlotte complice (11)** : assise à table, elle glisse des morceaux sous la table (une source de nourriture au
  plancher, peu risquée) ; si Maman la voit faire, c'est la chicane Maman–Charlotte (`activity == "chicane"`,
  règles existantes). Trésor : une part du gâteau d'anniversaire.
- **Papa surveille (12)** : la personne qui surveille devient une donnée du niveau (`"watcher": "papa"`), avec ses
  propres indices (pause publicitaire, il cherche la télécommande, « Hein ? »). Un **but** des Canadiens est une très
  longue fenêtre, mais soudaine (il saute de joie). Sur la table basse : bol de chips, pop-corn, nachos. Grimper n'est
  pas nécessaire : une prise sur la table basse se fait le nez tendu (surface `"low"`), plus vite, et n'est jamais
  cachée.
- **Le noir (13)** : la portée du regard dépend de la lumière de la télé (`Sim`, testé) ; l'éclairage suit la même
  valeur que les règles, pour que ce qu'on voit à l'écran dise la vérité. Les indices restent visibles et audibles.
- **Le party des Fêtes (14)** : décor de Noël dans les deux pièces, buffet garni (tourtière, jambon à l'érable,
  bûche), Papa et Charlotte, la visite. Trésor final : le jambon à l'érable. La fin du jeu passe à cette mission.

## 4. Les chantiers, dans l'ordre

Chaque chantier finit par les essais (`tools/test.sh` vert), des captures regardées et un commit sur `main`.

1. **Fiche de référence.** Ajouter à `docs/fiche-reference.md` les deux pièces : plan vu de dessus (meubles,
   ouvertures, porte vers la cuisine, cage, fenêtre), dimensions estimées (environ 3,2 m de large chacune ; table
   environ 75 cm, table basse environ 45 cm, divan), couleurs, matières, lumière, ce qu'on a retiré pour « en ordre »,
   ce qui manque. Placer chaque pièce par rapport à la cuisine.
2. **Moteur multi-pièces, sans art.** Un plan par pièce : `data/pieces/cuisine.json` (l'actuel `kitchen.json`),
   `salle_a_manger.json`, `salon.json` (P), lus par Godot et Blender. Chaque niveau dit sa pièce (`"piece"`, par défaut
   `"cuisine"`). Les cachettes deviennent une liste dans le plan (`"bloc"` comme l'îlot ou le divan, `"dessous"` comme
   la table) au lieu de l'îlot codé en dur ; la surface `"low"` ; le coin par pièce ; la personne qui surveille ;
   Maman hors de la pièce. **Les missions 1 à 8 doivent donner exactement les mêmes parties qu'avant** pour les mêmes
   graines : ajoute un test de non-régression (scores et événements des robots avant et après). `Levels.COUNT`,
   sauvegarde (une partie qui avait fini la mission 8 débloque la 9 ; un vieux fichier ne plante jamais), menus et
   tests qui comptent « huit missions ».
3. **Les missions en données.** `levels/niveau_9.json` à `niveau_14.json`, `texts.gd` (consignes, répliques de Maman
   et de Papa en québécois, avec variantes), tests des nouvelles règles (cachette sous la table aux limites, retour
   annoncé de Maman, portée dans le noir, Papa qui surveille, Charlotte complice, aucun poste qui coince Blanche dans
   chaque pièce), robots, `tools/calibrate.py --games 400 --write-stars`.
4. **Les pièces en 3D.** Un script par pièce dans `tools/blender/` (en partageant ce que `kitchen.py`, `common.py` et
   `textures.py` savent déjà faire), modèles dans `art/models/`, aperçus dans `art/previews/` à comparer avec les
   photos. Matières par script : érable du plancher, mur ardoise, velours côtelé moutarde, bois foncé de la table,
   noyer des chaises, fer noir, laiton, verre opale et fumé, céramiques à glaçure, fil de la cage, tissu des rideaux,
   plâtre des moulures et rosaces. Une vue par la fenêtre du salon (la rue, le garde-corps de fer forgé). La pièce
   voisine se devine par l'ouverture. La caméra en plongée garde dans le cadre Blanche, la personne qui surveille, la
   cible, le coin et la cachette.
5. **Personnages et animations.** Maman : servir, poser un plat, partir et revenir par la porte, s'asseoir et manger.
   Papa : assis au divan, regarder la télé, le but (il saute), chercher la télécommande, se retourner. Charlotte :
   assise à table, glisser un morceau en cachette, se faire chicaner. Blanche : se coucher et ramper sous la table,
   le nez tendu sur la table basse, assise dans sa cage. La visite (mission 14) : réutiliser les corps existants avec
   d'autres têtes et vêtements génériques (`heads.py`, `people.py`), jamais des visages réels.
6. **La nourriture.** Brunch (œufs, bacon, rôties, cretons, fèves au lard, fruits), souper en famille, gâteau de
   fête, chips, pop-corn, nachos, buffet des Fêtes. Lisible de haut, dans son assiette ou son bol (`food.py`), et les
   images `art/ui/plat_N.png` des nouvelles missions.
7. **Lumière, son et interface.** Une ambiance par mission (`kitchen/ambiance.gd` : matin du brunch, soir de souper,
   soir de hockey sous la lampe sur pied, film dans le noir éclairé par la télé, Fêtes). Sons synthétisés
   (`tools/audio/generate_audio.py`) : foule du hockey et sirène du but, porte, assiettes, chaises, tourne-disque,
   clochettes des Fêtes ; musique toujours joyeuse. Écran des missions regroupé par pièce (Cuisine, Salle à manger,
   Salon), avec l'image de chaque plat ; la fin du jeu après la mission 14.
8. **Finition et livraison.** Équilibrage (la difficulté remonte un peu au début de chaque nouvelle pièce, puis monte),
   captures de chaque nouvelle mission en 16:9, 16:10 et 4:3 et des poses clés, performance, revues, application
   macOS, documents, version **1.1.0-rc1** (P).

## 5. Règles qui ne bougent pas

- Toutes les règles de `CLAUDE.md` (« Règles du jeu à ne pas casser ») valent dans chaque pièce : indice d'au moins
  `hint_min` avant tout regard, redescendre plus court que tout indice, jamais cachée les pattes en l'air, le robot
  « sage » jamais pris, aucun poste qui coince Blanche, aucune stratégie dégénérée gagnante, la méfiance se voit
  monter, la chicane repasse par un indice. Les étendre à toute nouvelle personne qui surveille.
- **La lisibilité passe avant la beauté**, surtout dans le noir de la mission 13.
- Ne jamais modifier un `.glb` ni un `.wav` à la main ; ne créer aucune matière ni aucun objet 3D en pleine partie
  (tout préparer au chargement de la mission).
- **Performance** aux tailles des écrans de Julien (3440×1440 et Retina 3456×2160) comme en 1080p, dans chaque pièce :
  pas moins que la cuisine (`tools/shots.sh dossier 3440x1440 --seulement=perf`), chargement d'une mission sous
  0,5 s, mémoire stable après 20 parties.
- Blanche reste un chiot de cinq mois (`TAILLE`, `DogView.SIZE`) ; Maman sans visage large ; musique joyeuse.
- Fenêtres d'essai muettes, en arrière-plan, sur l'écran du MacBook, `--no-save`, fichiers temporaires `zz_*`.
- Un commit par chantier sur `main`, seulement les fichiers de Blanche ; rien n'est poussé ; pas de ligne au journal
  d'usage. Ne pas toucher aux autres jeux.

## 6. Revues

Après les chantiers 3 et 8 : `/code-review high` puis `/simplify` ; un sous-agent sans contexte (`model: sonnet`)
cherche les bogues des nouvelles règles ; revue du jeu (chaque mission enseigne-t-elle sa nouveauté ?), de l'art
(rendus à côté des photos), de l'accessibilité (indices sans son ni couleur, mouvements réduits, indices plus longs),
des textes (français du Québec), de la vie privée (aucune photo ni inscription dans le dépôt ou l'application ;
`/security-review` avant la livraison). Tout est consigné dans `docs/revues.md`.

## 7. Terminé quand

- [ ] les missions 9 à 14 se jouent du début à la fin, avec leurs étoiles, et la fin du jeu vient après la 14 ;
- [ ] les missions 1 à 8 jouent exactement comme avant (test de non-régression) ;
- [ ] `tools/test.sh --complet` finit par « TOUS LES TESTS PASSENT », sortie montrée ;
- [ ] captures des nouvelles pièces à côté des photos, regardées ; mesures de performance notées ;
- [ ] l'application macOS est exportée et vérifiée (`tools/export.sh`) ;
- [ ] `CLAUDE.md`, `docs/etat.md`, `docs/fiche-reference.md`, `README.md`, `CHANGELOG.md` à jour ;
- [ ] le compte rendu dit franchement ce qui reste faible et ce qui n'a pas pu être vérifié.

## 8. Questions pour Julien (notées dans `docs/etat.md`, non bloquantes)

1. La porte de bois de la salle à manger mène-t-elle à la cuisine ? Sinon, par où Maman passe-t-elle ? Il y a un corridor jusqua la cuisine
2. Le meuble noir sous la télé est-il un piano ? oui
3. La cage est-elle vraiment le coin de Blanche dans cette pièce, et « DANS TA CAGE ! » te fait-il rire ? oui cest bon
4. Les six missions et leur ordre te conviennent-ils ? D'autres repas ou habitudes de la famille à mettre ? cest parfait! on peut ajouter un souper avec des invites
