# Revues

## 1. Revue de code (`/code-review high`, 2026-11-24)

Dix constats, **tous corrigés**, avec un essai pour chacun des défauts de jeu.

| Trouvé | Correction |
|---|---|
| Le résultat pouvait se perdre (pause ou menu pendant « Le repas est prêt ») | Noté dès la fin ; plus de pause ensuite |
| Toucher un meuble : Blanche poussait contre lui sans fin | Le but est ramené à une place libre, et abandonné si elle n'avance plus |
| Pattes qui tremblent au-delà de 60 images/s | Vitesse mesurée au rythme des règles, positions lissées |
| Le deuxième doigt ne servait à rien quand le bouton était tenu | Seul un nouvel appui annule le but |
| Seule la première manette fonctionnait | Toutes les manettes |
| Après un « AU COIN ! », elle repartait vers l'ancien but | Le but est oublié |
| La vérification des scripts pouvait dire « OK » sans que Godot ait tourné | Le code de sortie est vérifié |
| Start et P mettaient en pause sans reprendre | Ils reprennent aussi |
| La démo par robot écrivait la vraie sauvegarde | La démo ne sauvegarde pas |
| Charlotte ne voyait pas une prise par-dessus l'îlot | Les pattes en l'air, elle voit toujours |

## 2. Regard neuf (sous-agent sans contexte, modèle Sonnet, 2026-11-24)

Aucun blocage ni exploit trouvé au coin ou à la pause. Quinze constats.

| # | Trouvé | Suite |
|---|---|---|
| 1 | Le tutoriel n'apprenait pas à lâcher | Consignes et message dédiés ; bouton « Lâche ! » |
| 2 | Lâcher rendait l'îlot inutile | Lâcher fait perdre le combo |
| 3 | Maman découvrait une Blanche cachée en marchant, sans indice | Elle ne marche plus en surveillant (hors tour de l'îlot) |
| 4 | Marteler Espace sautait les résultats | « Valider » ignoré une seconde |
| 5 | Un appui très bref se perdait | L'appui est retenu jusqu'au pas suivant |
| 6 | Lâcher pendant la descente reprenait le morceau | Il faut relâcher avant |
| 7 | 1re étoile de la mission 1 trop haute | 700 |
| 8 | Le tutoriel cachait la carte de mastication | Carte déplacée |
| 9 | Toucher la cachette envoyait vers un morceau | Rayon réduit dans la cachette |
| 10 | Le rire de Maman ne se voyait pas | Il suit l'arrivée au coin |
| 11 | Pas d'objectif chiffré | « Prochaine étoile : N » |
| 12 | Papa disparaissait au milieu de la pièce | Il ressort par la porte |
| 13 | Un trésor perdu l'était pour de bon | Il revient sur un meuble |
| 14 | Changer un volume défaisait un plein écran | Le mode ne change qu'avec son réglage |
| 15 | Textes maladroits, « Espace » affiché à la manette | Corrigés ; le bouton nomme la bonne commande |

Fonctions du cahier des charges relevées comme partielles : ajoutés depuis, le fredonnement qui s'arrête, le soupçon
quand on se cache trop longtemps, des façons variées de chicaner et la fin à revoir. Les autres sont listées dans
`docs/etat.md` (« Pas fait ou fait en partie »).

## 3. Simplification (`/simplify`, quatre relecteurs, 2026-11-24)

| Appliqué | |
|---|---|
| Réutilisation | Un seul parcours de chemin ; aides communes dans les règles (indice, punition, endroit d'un morceau, durée d'une fenêtre, cercles des personnes, grilles) ; tailles de nourriture nommées une fois |
| Simplification | Code, textes et données inutilisés retirés (jeu et scripts Blender) ; un seul minuteur pour le trésor ; sauvegarde « en mémoire » sans faux fichier ; bouton à l'écran par signal ; fredonnement déduit de l'état |
| Efficacité | Zone cachée calculée seulement sur les cases utiles ; boîtes de l'interface réutilisées ; personnages hors champ non animés ; décalages d'os morts retirés ; shader de silhouette préparé au titre |
| Justesse | Vapeur du chaudron qui restait allumée ; essai du record redevenu exact ; calibrage qui ne touche plus aux niveaux avant d'avoir mesuré |

Vérifié : les parties de robots à graines fixes donnent **exactement** les mêmes résultats avant et après.

Laissé de côté (gain faible pour le risque) : fusion des scripts shell dans un fichier commun, aide commune pour les
matières de la scène, rangées des options, géométrie des pointes de fromage, redessin de l'interface seulement quand
elle change.

## 4. Revues propres au jeu

- **Jeu :** chaque mission montre sa nouveauté dans ses consignes ; l'équilibrage est mesuré par robots
  (`tools/check_balance.py`). L'envie de recommencer ne se juge que par des essais humains.
- **Art :** rendus et captures comparés aux photos (disposition, couleurs, objets marquants, robe de Blanche).
- **Accessibilité :** chaque indice a une forme (« ! » triangle, « ? » rond, flèche), un son et une barre de temps ; la
  cachette a un motif, une icône et un mot ; indices plus longs et mouvements réduits en option.
- **Textes :** relus ; québécois pour les adultes, plus standard pour Charlotte.

## 5. Droits, vie privée et sécurité (2026-11-24)

- Aucune ressource externe sauf la police Fredoka (OFL) ; voir `SOURCES.md`.
- `reference/` ignoré par git ; aucune photo suivie ; l'application exportée est vérifiée sans photo.
- Le jeu n'ouvre aucune connexion, ne lance aucun programme et ne désérialise aucun objet : il lit ses données JSON et
  écrit sa sauvegarde dans `user://`. Un fichier de sauvegarde abîmé ou falsifié est testé.
- Aucun secret ni adresse dans le dépôt.
- Les arguments d'essai (`--autotest`, `--scenario`, `--sauvegarde`) restent dans l'application : ils n'écrivent qu'à
  l'endroit qu'on leur donne en la lançant à la main.
- Le titre contient un nom de famille et les personnages représentent des proches : à considérer avant tout partage.

## 6. Assurance qualité finale (2026-11-24)

| Essai | Résultat |
|---|---|
| `tools/test.sh --complet` | 44 essais de règles (2829 vérifications), 102 vérifications d'intégration, parcours des huit missions, équilibrage à 1000 parties par niveau et par profil : **tout passe** |
| Équité | Le robot « sage » n'est pris aucune fois, sur 8000 parties |
| Stratégies dégénérées | Marteler, camper : 0 % de réussite ; miettes : moins de 1 % ; ne jamais redescendre : 13 à 23 %, jamais trois étoiles |
| Débutant robot (réaction 0,7 s) | Réussit de 86 à 100 % des parties ; trois étoiles de 58 % (mission 1) à 10 % (mission 8) |
| Performance, 1920×1080, M1 Pro | 67 à 79 images/s en moyenne, 99 % sous 20 ms, pire 31 ms ; chargement d'un niveau sous 0,15 s ; mémoire stable sur 20 parties |
| Formats d'écran | 16:9, 16:10 et 4:3 vérifiés sur captures |
| Application macOS exportée | Universelle, signée « ad hoc », sans photo, autotest réussi deux fois, sauvegarde conservée au redémarrage, captures vérifiées |

Non vérifié : écoute du son, manette et écran tactile réels, ouverture sur un autre Mac, plaisir de jeu.

## 7. Refonte graphique (2026-11-25)

Sept chantiers de `PROMPT-GRAPHIQUES.md`, chacun vérifié par captures, essais et mesures.

| Mesure, 1920×1080, M1 Pro | Avant (rc2) | Après (rc3) |
|---|---|---|
| Images par seconde, en moyenne | 62 à 74 | 87 à 92 |
| 99 % des images sous | 17 à 23 ms | 12 à 15 ms |
| Pire image (deuxième lancement) | 21 à 35 ms | 25 à 52 ms |
| Chargement d'une mission | sous 0,16 s | sous 0,11 s |
| Mémoire vidéo | 146 Mo | environ 630 Mo |

Au tout premier lancement, quelques à-coups de 50 à 100 ms viennent de la préparation des shaders.

Batterie complète (`tools/test.sh --complet`) après la refonte : 49 essais de règles (2830 vérifications),
102 vérifications d'intégration, parcours des huit missions et équilibrage à 1000 parties par niveau et par profil :
**tout passe**. Le robot « sage » n'est pris aucune fois.

Ce qui reste faible : les mains et la démarche des personnages restent simples ; les cheveux sont des masses lisses ;
les cartes de missions verrouillées ne montrent qu'une silhouette ; le moteur mobile n'est pas réglé.

## 8. Fluidité (2026-11-25)

Julien a trouvé le jeu moins fluide. Les mesures de la section 7 n'étaient faites qu'en 1920×1080, plus petit que ses
écrans : c'était l'erreur. Mesures sans limite d'images, M1 Pro :

| Taille de la fenêtre | rc3 | rc4 | 99 % des images (rc4) |
|---|---|---|---|
| 3440×1440 (écran large) | 45 images/s | 105 à 109 | sous 11 ms |
| 3416×2064 (Retina) | 31 images/s | 93 à 97 | sous 12 ms |

En jeu, la cadence est celle de l'écran à 60 Hz, et 60 images/s sur un écran à 120 Hz.

## Salle à manger et salon : revue après le chantier 3 (2026-11-25)

### Revue de code (`/code-review high`)

| Trouvé | Suite |
|---|---|
| L'exportation attendait encore 8 missions débloquées | Elle lit le nombre de missions dans le rapport de l'autotest |
| La visite qui dénonce coupait une chicane en cours | En pleine chicane, Maman n'entend rien d'autre (essai ajouté) |
| La chaise qui vacille était cherchée dans l'arbre à chaque image | Trouvée une fois au choc, remise en place à la fin |
| Des clés de niveau mal écrites ne plantaient qu'en partie | `Levels.validate` les vérifie (essai ajouté) |
| La finale échappait à la vérification « la difficulté ne recule pas » | Elle doit être la plus dure à réussir (réussite et trois étoiles) |
| La fin et les cartes 9 à 15 montrent l'image des crêpes | Laissé au chantier 6 (images des plats) |
| `CLAUDE.md` disait les missions 9 à 14 « à faire » | Corrigé |

### Simplification (`/simplify`)

Les quatre relecteurs automatiques n'ont pas pu tourner (limite d'utilisation du modèle) : passe faite à la main.

- Le « Hon ! » de Charlotte dans la cuisine passe par la même règle que la visite (`_snitch_step`) : mêmes parties,
  vérifié par la non-régression.
- `mom_seated()` sépare « assise » de « penchée pendant son tour » ; la condition des obstacles se lit d'un coup.
- Code mort retiré (`RoomMap.hide_named`), liste des personnages en un seul endroit (`Levels.PEOPLE`).
- Laissé tel quel, exprès : le temps d'attraper d'un morceau au sol reste celui de sa taille dans les règles (le changer
  changerait les parties de la cuisine) ; seuls les robots comptent zéro pour les morceaux glissés par Charlotte.

### Regard neuf (sous-agent Sonnet)

À faire : la limite d'utilisation du modèle était atteinte. Reporté à la revue finale (chantier 8).

## Salle à manger et salon : revues finales (chantier 8, 2026-11-26)

### Regard neuf (sous-agent Sonnet, sans contexte, reporté du chantier 3)

Lecture du code et des plans seulement, plus un remplissage du plancher des trois plans en Python : toutes les places,
postes, points de passage, portes et la cage sont reliés, aucune poche. Chaque entrée dans un regard ou un tour passe
par un indice d'au moins `hint_min` (retour, visite qui appelle Maman, fin de chicane, retour à la porte).

| Trouvé | Suite |
|---|---|
| Dans le noir, la lumière de la télé pouvait monter pendant l'indice : une chienne cachée par le noir devenait visible au regard | La lumière ne monte plus pendant l'indice non plus (essai `test_portee_dans_le_noir` élargi) |
| L'œil de la zone cachée se posait entre les deux cachettes de la finale, sur du plancher à découvert | Il se pose sur la case cachée la plus proche du centre |
| Un tour de la table lancé depuis le divan traversait le divan et durait 8 à 10 s | Pas de tour loin de la table (`_ring_near`, essai `test_pas_de_tour_loin_de_la_table`) |
| Papa debout pendant le regard qui suit un but | Il reste assis (l'activité « but » ne le lève plus) |
| « Les étoiles de la cuisine ont changé » | Faux positif : comparé à un commit d'avant ce travail ; aucune différence depuis `9901b11` |

Notés sans correction : un passant de la visite peut s'arrêter tout près de Maman (cosmétique) ; Maman au divan voit
Charlotte derrière elle (cohérent avec « elle voit toute la pièce »).

### Revue de code (`/code-review high`, `d8c2147..HEAD`)

| Trouvé | Suite |
|---|---|
| Après les changements de règles, la finale laissait réussir le robot « têtu » (36,7 % pour 35 % permis, 60 parties) | Étoiles recalculées (`calibrate.py --games 400 --write-stars` : seules 14 et 15 bougent) ; batterie complète |
| Retour depuis la fiche d'une mission : la liste revenait sur la pièce de la dernière mission débloquée | Le bouton revient sur la pièce de la mission vue |
| La portée du soleil de la cuisine était passée de 8 à 9 m | Portée par pièce : 8 m dans la cuisine (comme avant), 9 m au double salon |
| La sonde de reflets était photographiée deux fois à chaque début de partie | `set_room` n'est appelé que si la pièce change et ne réapplique plus le moment |
| « Où est la télécommande ? » pouvait être dit par Papa debout | Décidé par les règles (`remote_hint`, Papa assis, sans hasard), la réplique et la pose le lisent |
| Assise, Maman tournait la tête depuis la position des règles, pas depuis le siège | La visée part de l'endroit affiché |
| En s'assoyant ou en se levant, Maman sautait d'un coup entre ses pieds et le siège | Glissement doux pendant 0,45 s |

### Simplification (`/simplify`, quatre relecteurs : réutilisation, simplification, efficacité, altitude)

- Faits : aides communes dans `stage.gd` (matières plates, teinte, visée) ; cachettes et noir mis en cache plutôt que
  recalculés à chaque image ; ce que chaque moment montre ou cache, et l'écran de la télé, décrits dans les plans
  (`montre`, `cache_au`, `vue`, `tele`) plutôt que codés en dur ; la pose des personnes assises du décor dite dans les
  niveaux (`"pose"`) ; liste des pièces du menu en cache et états des boutons en une aide (`_candy_states`) ; lumières
  décrites par pièce (`_rig` : portées en données) ; code mort retiré de `double_salon.py` et `food.py`.
- Laissé exprès : le temps d'attraper d'un morceau au sol reste celui des règles de la cuisine (le changer changerait les
  parties 1 à 8) ; `kitchen.py` ne passe pas par `decor.py` (il faudrait régénérer la cuisine, qui ne doit pas bouger).
- Vérifié après : non-régression 144 parties, 0 différente ; 66 essais de règles verts.

### Sécurité et vie privée (`/security-review`)

Aucune faille trouvée. Rien de `reference/` n'est suivi par git ni ne l'a jamais été ; l'exportation exclut
`reference/*`, `tests/*`, `tools/*`, `docs/*`, `zz_*`, et `tools/export.sh` échoue si l'application contient une
photo ou la trace de `reference/`. Aucun script ne lit d'image dans `reference/` : les cadres et affiches du double
salon sont dessinés par script (lettres, lune, aquarelle, falaise), les visages de la visite sont inventés. La
sauvegarde est lue en JSON, chaque champ vérifié et borné ; rien n'est chargé depuis `user://` ; aucun `OS.execute`,
`Expression` ni `eval` dans le jeu. Le pixel des images générées n'a pas été inspecté par la revue : la garantie repose
sur les scripts et la vérification de l'exportation.

### Performance (M1 Pro, `tools/shots.sh --seulement=perf`)

| Mission | 3440×1440 | Retina 3416×2064 |
|---|---|---|
| 1 (cuisine) | 111 images/s | 100 |
| 8 (cuisine) | 105 | 97 |
| 9 (brunch) | 105 | 102 |
| 12 (souper des invités) | 104 | 95 |
| 13 (hockey) | 105 | 95 |
| 14 (film) | 99 | 90 |
| 15 (party des Fêtes) | 102 | 102 |

Chargement d'une mission : 15 à 120 ms. Mémoire après 2 puis 20 parties : 131,1 → 131,2 Mo (Retina 141,2 → 141,0).
Le film en Retina (90) reste un peu sous la cuisine (97 à 100) ; à 60 Hz ou 120 Hz plafonné à 60, ça ne se voit pas.

### Batterie complète (`tools/test.sh --complet`, 1000 parties par mission et par profil)

« TOUS LES TESTS PASSENT » (43 min) : 66 essais de règles (5607 vérifications), non-régression 144 parties sans
différence, intégration (106 vérifications), parcours complet, équilibrage des 15 missions. Les robots honnêtes ne
restent jamais coincés. Le robot « têtu » reste immobile plus de 6 s dans 15 à 26 % des parties de la salle à manger
(2 à 10 sur 1000 dans la cuisine) : quand Maman est au buffet, la place devant le côté nord de la table est dans son
cercle et il pousse tout droit dessus ; un joueur attrape ce morceau à 10 cm de là, depuis dessous la table. Défaut
du robot, pas une poche (`test_aucune_poche` le vérifie avec Maman à chacun de ses postes).
