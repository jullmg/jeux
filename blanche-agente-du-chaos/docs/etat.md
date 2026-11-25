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
| 7. Livraison | version macOS 1.0.0-rc3 exportée et testée ; **acceptation de Julien à venir** |

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
