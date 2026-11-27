# État du projet

Point de reprise d'une session à l'autre. Julien a demandé de tout faire sans s'arrêter aux points de contrôle
(2026-11-24) : les choix faits à ces points sont notés ici pour révision.

## Avancement

| Étape | État |
|---|---|
| 0. Préparation | fait |
| 1. Prototype (règles) | fait : règles sans affichage, tests, robots joueurs |
| 2. Direction artistique | fait : cuisine, Blanche, Maman, Papa, Charlotte, nourriture |
| 3. Tranche complète | fait |
| 4. Production | fait : les huit missions |
| 5. Finition | fait : équilibrage, performance, accessibilité, icône |
| 6. Assurance qualité | fait : revues corrigées, batterie complète réussie (`docs/revues.md`) |
| 7. Livraison | version macOS 1.0.0-rc4 exportée et testée ; puis 1.1.0-rc1 avec les missions 9 à 15, puis 1.2.0-rc1 (soirée pyjama, corrections, passe d'amélioration) ; **acceptation de Julien à venir** |

## Salle à manger et salon (`PROMPT-PIECES.md`, commencé le 2026-11-25)

| Chantier | État |
|---|---|
| 1. Fiche de référence | fait |
| 2. Moteur multi-pièces | fait : plans par pièce, cachettes en liste, Maman hors de la pièce, personnes assises, visite qui circule, le noir ; non-régression de la cuisine |
| 3. Les missions en données | fait : missions 9 à 15, répliques, tests des nouvelles règles, étoiles calibrées |
| 4. Les pièces en 3D | fait : le double salon d'un seul modèle (`tools/blender/double_salon.py`), une caméra et un éclairage par pièce |
| 5. Personnages et animations | fait : assis à table et au divan, servir, manger, le but, la télécommande, Charlotte qui glisse un morceau, la visite (deux nouveaux modèles), Blanche qui rampe et tend le nez |
| 6. La nourriture | fait : 21 nouveaux morceaux (brunch, pâté chinois, fête, lasagne, hockey, film, buffet des Fêtes) et les images des plats 9 à 15 |
| 7. Lumière, son et interface | fait : une lumière par soirée (brunch, fête, souper, hockey, film dans le noir, Fêtes), le cercle de vue du noir, six nouveaux sons, l'écran des missions par pièce |
| 8. Finition et livraison | fait : performance mesurée aux tailles de tes écrans, revues finales corrigées (`docs/revues.md`), batterie complète, version macOS 1.1.0-rc1 exportée et vérifiée |

Réponses de Julien (2026-11-25) : un corridor mène de la salle à manger à la cuisine ; le meuble noir sous la télé est
un piano ; la cage comme coin et « DANS TA CAGE ! », c'est bon ; les six missions conviennent, **et on peut ajouter un
souper avec des invités**.

### Choix faits en l'absence de Julien (salle à manger et salon)

- **Sept nouvelles missions au lieu de six** : le souper avec des invités (demandé par Julien) devient la mission 12,
  dans la salle à manger ; la soirée du hockey, le film et le party des Fêtes passent à 13, 14 et 15.
- Les deux pièces forment un **seul modèle 3D**, le double salon (il n'y a pas de cloison entre elles) ; chaque mission
  choisit sa caméra : vers le mur ardoise pour la salle à manger, vers la fenêtre pour le salon, et les deux pièces à
  la fois pour le party des Fêtes.
- Maman part à la cuisine par la **porte de bois** de la salle à manger (elle donne sur le corridor).
- **Assis, on n'est pas un obstacle** (Papa ou Maman au divan, la visite à table) : le chiot leur passe entre les
  jambes, sinon la table basse serait inaccessible. Les chaises, elles, bloquent et grincent.
- **Dans le noir**, la personne qui surveille ne voit pas au-delà de la lumière de la télé, **mais les pattes en l'air,
  Blanche est toujours vue** (règle de la cuisine conservée). La lumière ne monte jamais pendant un regard : une scène
  claire ne trahit pas une Blanche qui s'était fiée au noir.
- Charlotte complice **sauve** Blanche quand Maman la voit glisser un morceau : la chicane commence au lieu du regard.
- Pendant qu'elle est à la cuisine, la zone cachée se compte depuis **la porte** par où elle reviendra.
- Les chantiers 4 (décor) et 5 (personnages) sont livrés dans un seul commit : la scène 3D (`stage.gd`) montre les deux
  à la fois (une personne assise a besoin de son siège dans le décor).
- Au party, la caméra montre **les deux pièces d'un coup**, de côté (depuis le mur est) : tout est plus petit que dans
  la cuisine, mais Maman, Blanche, le coin et la nourriture restent dans le cadre.
- Dans le noir, **un cercle clair au plancher** montre jusqu'où voit la personne qui surveille (la même valeur que
  les règles) ; la télé éclaire la pièce avec la même lumière.
- L'écran des missions a **un onglet par pièce** (la cuisine, la salle à manger, le salon, le party des Fêtes) ; une
  pièce s'ouvre quand sa première mission l'est.
- Les chaises, le fauteuil berçant et le piano sont simplifiés ; le banc du piano est rangé ; les céramiques sont des
  formes simples (tasses, bols, vases, piles d'assiettes) aux glaçures pastel.
- **Le party des Fêtes (15)** a demandé des réglages pour que s'entêter (ne jamais redescendre) ne paie pas :
  Maman se déplace moins (de longs trajets entre les deux pièces étaient des fenêtres gratuites), Charlotte glisse
  moins de morceaux, le jambon vaut 800 points, et la 1re étoile est plafonnée à 950 comme à la dinde.
- **La punition s'allonge davantage aux récidives** dans les nouvelles missions (`"repeat_max"` : jusqu'à 5 s au lieu
  de 4, 9 s au party) : presque rien pour qui se fait prendre deux ou trois fois, beaucoup pour qui s'entête. Dans la
  cage, elle dure 0,6 s de plus (Maman referme la porte). La cuisine n'a pas changé.
- La visite qui circule ne voit qu'en marchant ; elle jase longtemps entre deux déplacements. La visite à table ne voit
  que les morceaux proches d'elle (environ 85 cm), et seulement quand elle ne jase pas.
- Les débuts de pièce (9, 13, 15) ont droit à une difficulté un peu plus basse que la mission d'avant ; la finale doit
  être nettement plus dure que le début de la salle à manger (vérifié par `tools/check_balance.py`).

### Corrections de la salle à manger (2026-11-26, demandes de Julien)

- Maman passait à travers la table : elle en fait maintenant le tour (et ne pousse plus Blanche de dessous la table).
  Étoiles des missions 9 à 15 recalibrées (ses trajets sont un peu plus longs).
- Papa (et tout le monde) était assis trop près du bord : les hanches reculent de 6 cm vers le dossier.
- Maman tenait une cafetière noire en servant la lasagne : elle tient maintenant le vrai plat du repas, à plat (la
  cafetière de verre reste au brunch).
- Le souper en famille et le brunch : Papa et Charlotte sont à table (Papa lit le journal au brunch) ; assis, chacun
  mange pour vrai (bouchées, couper, boire, se tourner pour jaser).
- Un couvert à chaque place occupée (assiette, ustensiles, serviette, verre d'eau).
- Papa, Charlotte, Maman assise et la visite jasent à table : une quarantaine de conversations drôles et de répliques
  seules, selon le repas (la visite ne parle que quand elle jase pour vrai, pour ne pas tromper la joueuse).
- La lasagne (gratinée, ses étages) et le pâté chinois (purée à la fourchette, blé d'Inde, steak) refaits.
- Le plancher qui clignotait sous la porte de bois : deux planchers se chevauchaient.
- Les cloches au-dessus de certains endroits : ce sont les endroits bruyants (y prendre un morceau fait tinter la
  vaisselle et Maman l'entend).

### La soirée pyjama (2026-11-26, demandée par Julien)

- **Mission 15, dans la chambre de Charlotte**, faite d'après tes photos (le lit de métal blanc et sa douillette rose,
  le rideau de lumières, le cœur néon, l'affiche aux fraises, le tableau fleuri, les étagères, le fauteuil en fourrure,
  le bureau et sa chaise rouge à trous, la commode et la cage de verre du hamster) ; aucune image n'en est copiée et la
  pancarte de la porte n'a pas de mots.
- Compris ainsi (à corriger au besoin) : **c'est Charlotte qui surveille**, « comme le reste de Maman » : indices,
  regards, au coin, et des allers-retours à la cuisine pour remplir le bol. Elle regarde le film dans le nid, nourrit
  le hamster, invente une chorégraphie. **Alyzée** (cheveux noirs, coton ouaté à petits oursons, teint pâle, inventée)
  voit son bout du plateau quand elle ne jase pas. Charlotte est en pyjama rose à pois.
- Blanche vise le pop-corn, les oursons en jujube, les canettes de bubly (sans logo) et, en trésor, le gros sac de bonbons.
- **Ordre des missions** : le party des Fêtes reste la grande finale ; la soirée pyjama passe avant lui (15), le party
  devient la 16. Une sauvegarde d'avant garde le record du party.
- Les filles jasent entre elles pendant le film (conversations propres à la soirée pyjama).

### Passe d'amélioration générale (nuit du 2026-11-26, demandée par Julien : tout améliorer sans changer le jeu)

- **Les pieds au sol** : en marchant, le pied avant flottait (jusqu'à une dizaine de centimètres) ; le corps descend
  maintenant d'autant que les jambes s'écartent ou que les genoux plient (comme Blanche).
- **Une démarche plus vivante** : les hanches balancent, le torse tourne à l'inverse, les coudes plient ; au repos, on
  change d'appui d'une jambe à l'autre et on parle avec les mains ; tout le monde **cligne des yeux** (paupières
  ajoutées aux modèles).
- **Blanche** bâille de temps en temps quand elle est assise et renifle l'air quand elle est debout.
- **Les bulles** ont une queue tournée vers qui parle ; les onglets des missions se lisent (encre sur crème).
- **Le salon** a son tapis d'Orient rose et beige délavé ; **le jambon à l'érable** est garni à la québécoise
  (rondelles d'ananas, cerises, tranches en éventail).
- Charlotte et Alyzée appellent d'une voix plus aiguë que Maman.
- Changer de mission pendant que Blanche redescend d'une table plantait (corrigé, testé).

## Choix faits en l'absence de Julien (à réviser)

- Le prototype gris à l'écran a été sauté : personne n'était là pour juger s'il est amusant. Les règles ont été
  validées par des tests et des robots joueurs. Le « plaisir » reste à vérifier par des essais humains.
- Personnages : modèles générés par script (la voie « modèle libre adapté » n'a pas été montrée).
- Appuyer la gueule pleine **lâche** le morceau, et **fait perdre le combo** : sans le lâcher, un gros morceau pouvait
  rendre un flagrant délit inévitable ; sans le coût, l'îlot ne servait plus à rien.
- Maman change de poste **sans surveiller** : qui s'est bien caché n'est jamais découvert sans nouvel indice. Le seul
  regard en marchant est le tour de l'îlot, annoncé.
- Un trésor perdu dans un « AU COIN ! » revient sur un meuble 12 secondes plus tard.
- Plan ajusté pour qu'aucun poste de Maman ne coince Blanche (frigo, planche, buffet).
- Radiateur retiré à la demande de Julien ; le rail de luminaires n'est pas montré (il boucherait la vue).
- Étoiles calibrées sur des robots, avec une marge pour des humains : première chose à revoir après les essais.
- Pas de version web (retirée avec les réponses du 2026-11-24).

## Pas fait ou fait en partie

- **Essais humains** (`docs/grille-essais.md`) et acceptation. L'étiquette git `blanche-v1.0.0` attend celle-ci.
- Commandes sur du matériel réel : manette, écran tactile et clic « toucher pour cliquer » ne sont essayés que par
  des entrées simulées. Le son n'a pas été **écouté** : il est synthétisé, les essais sont muets.
- iPad et Android (étape suivante) : sur le moteur mobile, la lumière est à régler.
- Pas de bouton « yeux piteux » ni de jappement commandé : l'air sage vient en restant immobile.
- Le tabouret grince et vacille, mais ne tombe pas, et la vitesse n'y change rien.
- La mission 1 annonce « AU COIN ! » dans ses consignes sans le jouer d'avance.
- L'application n'est pas notariée (compte développeur Apple requis).
- Salle à manger et salon : **aucun essai humain** (le plaisir et la difficulté des missions 9 à 15 ne sont jugés que
  par les robots) ; les nouveaux sons (foule, sirène, assiette, chaise, tourne-disque, clochettes) n'ont pas été
  écoutés.
- Le film en Retina tourne à 90 images/s (la cuisine à 97 à 100) : invisible à 60 Hz, mais un peu sous la cuisine.
- Au party des Fêtes, la vue des deux pièces d'un coup rend tout plus petit (voir les questions).
- Les chaises, le fauteuil berçant et le piano sont simplifiés ; `kitchen.py` n'utilise pas encore les aides de
  `decor.py` (il faudrait régénérer la cuisine, qui ne devait pas bouger).

## Questions pour Julien (soirée pyjama et passe d'amélioration, 2026-11-27)

1. La soirée pyjama est-elle comme tu l'imaginais ? J'ai compris « c'est Charlotte qui surveille, comme Maman » ;
   « en faisant du reste de maman » voulait-il dire autre chose (Maman qui passe vérifier, par exemple) ?
2. Alyzée te ressemble-t-elle à ce que tu avais en tête (cheveux noirs, coton ouaté lilas à oursons, pantalon mauve) ?
   Et Charlotte en pyjama rose à pois ?
3. Les canettes de bubly sont sans logo (des couleurs et un sourire) : veux-tu le vrai logo ?
4. La chambre : manque-t-il quelque chose d'important (la cage du hamster est sur la commode, à gauche) ?
5. Les conversations à table : le ton te plaît-il ? Papa parle-t-il assez souvent ?

## Questions pour Julien (salle à manger et salon)

1. Les sept nouvelles missions et leur difficulté te conviennent-elles ? Le souper des invités est-il comme tu
   l'imaginais (ma tante et mon oncle à table, qui disent ce qu'ils voient de leur côté) ?
2. Le party des Fêtes montre les deux pièces d'un coup : tout y est plus petit. Est-ce assez lisible sur ton écran ?
3. Dans le noir du film, le cercle de lumière au plancher est-il clair ? Veux-tu le noir plus noir ?
4. Ressemblances : la salle à manger et le salon te semblent-ils les tiens (le mur ardoise, l'étagère, la cage, le
   divan moutarde, le mur de cadres) ? Qu'est-ce qui manque le plus ?

## Questions pour Julien

1. La nouvelle allure (rc3) te plaît-elle ? Les visages de Maman, Papa et Charlotte sont-ils assez ressemblants ?
2. La méfiance de Maman et la chicane : bien comprises, bien dosées ? Papa ne passe qu'aux missions 7 et 8 : le faire
   venir plus tôt ?
3. La difficulté et les étoiles (recalculées) conviennent-elles ?
4. La nouvelle musique joyeuse te convient-elle ?
5. Style « agente secrète » (`docs/idees.md`) ?
