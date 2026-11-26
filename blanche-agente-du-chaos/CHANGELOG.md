# Journal des versions

## 1.1.0-rc1 (2026-11-26) : la salle à manger et le salon

- **Sept nouvelles missions** (9 à 15) : le brunch du dimanche, le souper en famille, la fête de Charlotte, le souper
  des invités (demandé par Julien), la soirée du hockey, le film en famille et le party des Fêtes, qui réunit les deux
  pièces et finit le jeu.
- Nouveautés, une par mission : se cacher sous la table (la cage comme coin), Maman qui part à la cuisine et revient
  toujours annoncée, Charlotte complice, la visite à table, Papa qui surveille du divan (table basse et cachette
  derrière le divan), le noir éclairé par la télé, puis tout à la fois avec la visite qui circule.
- La salle à manger et le salon en 3D d'après les photos, en ordre : un seul modèle, une caméra et une lumière par
  pièce ; deux nouveaux personnages (ma tante et mon oncle, visages inventés) ; on s'assoit à table et au divan.
- Vingt et une nouvelles nourritures et les images de leurs plats ; six nouveaux sons ; l'écran des missions a un
  onglet par pièce.
- Les missions 1 à 8 jouent exactement comme avant (essai de non-régression) ; une partie qui avait fini la cuisine
  ouvre la salle à manger.

## 1.0.0-rc4 (2026-11-25) : fluidité

- Le jeu saccadait sur les grands écrans (45 images/s en 3440×1440, 31 en plein écran sur le MacBook). La 3D est
  maintenant calculée à une taille proche du 1080p puis agrandie (textes et boutons nets), avec des ombres et un
  anticrénelage un peu plus légers.
- Les personnages sont affichés entre deux pas des règles : plus d'à-coups dans les mouvements.
- Sur un écran à 120 Hz, le jeu tient 60 images régulières.

## 1.0.0-rc3 (2026-11-25) : deuxième série de retours et refonte graphique

Retours :

- Blanche a des yeux de chiot, bruns et doux, sans lueur.
- Le radiateur en avant-plan est retiré.
- Les signes au-dessus de Maman ne cachent plus son visage.
- Maman, Papa et Charlotte ont de nouveaux visages ; celui de Maman est affiné.
- La jauge « Méfiance de Maman » monte à vue d'œil, dit son état et pourquoi elle monte.
- Nouveau : Papa qui passe se met dans le chemin, et la chicane qui s'ensuit est une occasion pour Blanche.

Graphiques (`PROMPT-GRAPHIQUES.md`) :

- Rendu Forward+ sur Mac : ombres de contact, ombres douces, reflets, halo ; un moment du jour par mission.
- Matières avec relief et brillance : bois, quartz, céramique, brique, inox, plâtre, tissus.
- Une cuisine habitée, une vue par la fenêtre, des murs coupés net, et Noël à la dernière mission.
- Personnages lissés, vêtements plissés, pelage de Blanche, contre-jour, tuque de Noël, petits effets.
- Nourriture texturée et garnie.
- Interface refaite : lettrage du titre, boutons à relief, cartes illustrées par leur plat, résultats avec confettis,
  zone cachée à traces de pattes.
- Étoiles recalculées.

## 1.0.0-rc2 (2026-11-25) : retours du premier essai

- Cuisine : le sac accroché à côté de la porte est retiré.
- Blanche est redessinée en chiot de cinq mois : plus petite, grosse tête, grands yeux, langue sortie, grosses pattes.
  Elle trottine, penche la tête, halète, et s'accroche au bord des meubles en gigotant des pattes arrière. Icône refaite.
- Nouvelles musiques, joyeuses : ukulélé, basse sautillante, sifflet, clochettes et claquements de mains. La couche de
  tension est un tic-tac de bois, sans dissonance.
- Les règles et l'équilibrage ne changent pas.

## 1.0.0-rc1 (2026-11-24) : version à essayer

Première version complète, pour Mac. Elle deviendra la 1.0.0 quand Julien y aura joué et l'aura acceptée.

- Huit missions, des crêpes du déjeuner à la dinde de Noël, chacune avec sa nouveauté et ses trois étoiles.
- Blanche dans son coin, Maman et ses sept postes, l'indice, les feintes, le tour de l'îlot, la minuterie.
- L'îlot cache Blanche ; la zone cachée est dessinée au plancher.
- Bruits, soupçon, combo, tabouret, endroits bruyants, Papa et Charlotte.
- Cuisine, Blanche, Maman, Papa, Charlotte et nourriture modelés par script d'après les photos.
- Sons et musiques synthétisés.
- Clavier, manette, souris et tactile ; mouvements réduits et indices plus longs.
