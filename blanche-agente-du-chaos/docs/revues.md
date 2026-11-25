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

Ce qui reste faible : les mains et la démarche des personnages restent simples ; les cheveux sont des masses lisses ;
les cartes de missions verrouillées ne montrent qu'une silhouette ; le moteur mobile n'est pas réglé.
