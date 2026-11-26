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
| 7. Livraison | version macOS 1.0.0-rc4 exportée et testée ; **acceptation de Julien à venir** |

## Salle à manger et salon (`PROMPT-PIECES.md`, commencé le 2026-11-25)

| Chantier | État |
|---|---|
| 1. Fiche de référence | fait |
| 2. Moteur multi-pièces | fait : plans par pièce, cachettes en liste, Maman hors de la pièce, personnes assises, visite qui circule, le noir ; non-régression de la cuisine |
| 3. Les missions en données | à faire |
| 4. Les pièces en 3D | à faire |
| 5. Personnages et animations | à faire |
| 6. La nourriture | à faire |
| 7. Lumière, son et interface | à faire |
| 8. Finition et livraison | à faire |

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

## Questions pour Julien

1. La nouvelle allure (rc3) te plaît-elle ? Les visages de Maman, Papa et Charlotte sont-ils assez ressemblants ?
2. La méfiance de Maman et la chicane : bien comprises, bien dosées ? Papa ne passe qu'aux missions 7 et 8 : le faire
   venir plus tôt ?
3. La difficulté et les étoiles (recalculées) conviennent-elles ?
4. La nouvelle musique joyeuse te convient-elle ?
5. Style « agente secrète » (`docs/idees.md`) ?
