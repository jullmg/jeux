# Prompt : refaire les graphiques de « Blanche Pronovost agente du Chaos »

Demande de Julien (2026-11-25) : « on améliore tous les graphiques du jeu », « fais une grosse job ».

## Le but

Qu'à la première image on voie un jeu fini et chaleureux, du niveau d'un petit jeu familial vendu en boutique, et non
un prototype : une lumière qui donne du volume, des matières qu'on reconnaît, une cuisine habitée, des personnages
attachants, une interface soignée. Direction artistique : **film d'animation familial** (formes rondes, couleurs
chaudes et riches sans être criardes, lumière douce), toujours la vraie cuisine de la famille.

## Ce qu'on voit aujourd'hui (état des lieux, rc2)

- Lumière plate et brûlée : les bois virent à l'orange, les surfaces pâles saturent, rien n'ancre les objets au sol
  (aucune ombre de contact).
- Matières unies : acier, comptoir, murs et céramique sans relief ni reflet ; plancher répétitif.
- La pièce flotte dans un vide brun, avec des coins noirs ; la fenêtre ne montre rien.
- Meubles en boîtes ; peu d'objets.
- Corps des personnages : joints visibles aux épaules et aux hanches, vêtements lisses, mains raides.
- Blanche, toute noire, perd ses formes à la distance de jeu.
- Nourriture simpliste.
- Interface correcte mais plate : titre en texte brut, cartes de mission sans image, résultats peu fêtés.

## Les chantiers, dans l'ordre

Chaque chantier finit par des captures comparées à celles d'avant, les essais, une mesure de performance et un commit.

1. **Rendu et lumière.** Essayer le moteur Forward+ sur Mac (ombres de contact, ombres douces, anticrénelage, halo,
   correspondance des tons) et le garder seulement s'il tient la performance. Recomposer l'éclairage : soleil chaud par
   la fenêtre, appoint frais, lampes de la cuisine, une ambiance par moment de la journée.
2. **Matières.** Textures fabriquées par script, avec couleur, relief et brillance : plancher de bois franc, érable des
   armoires, bloc de boucher, comptoir moucheté, céramique et joints, brique, acier brossé, plâtre peint, tissus.
3. **La cuisine.** Portes en relief, poignées, plinthes, moulures ; fenêtre avec une vraie vue dehors ; murs et
   plafond qui ferment le cadre ; objets du quotidien (planche, pots, ustensiles, fruits, cafetière, linges, tapis,
   cadres, plantes fournies, lumières). Une mission du soir et la mission de Noël décorées en conséquence.
4. **Les personnages.** Corps d'une seule pièce aux épaules et aux hanches, plis et coutures, mains ; Blanche avec un
   pelage qui accroche la lumière et un liseré qui détache sa silhouette ; de petits effets (miettes, étincelles,
   cœurs, poussière).
5. **La nourriture.** Chaque morceau redessiné pour être appétissant et lisible de haut, dans son assiette.
6. **L'interface.** Écran titre composé avec un vrai lettrage, boutons à relief, cartes de mission illustrées par leur
   plat, affichage en jeu avec ses icônes, résultats qui se fêtent, transitions douces, zone cachée plus élégante.
7. **Finition.** Revue de toutes les captures, formats 16:9, 16:10 et 4:3, performance, mémoire, application macOS,
   documents, version.

## Règles qui ne bougent pas

- **La lisibilité du jeu passe avant la beauté** : Maman et ses signes, Blanche, chaque morceau, le coin et la zone
  cachée se voient d'un coup d'œil, à toutes les missions. Un décor qui gêne est retiré.
- **Aucune ressource externe** et aucune texture, aucun visage ni aucune inscription tirés des photos : tout est
  fabriqué par les scripts (`tools/blender/`, `tools/audio/`). Jamais de `.glb` retouché à la main.
- **Les règles du jeu ne changent pas** (`game/`) ; l'équilibrage reste vert.
- **Performance** sur le MacBook (M1 Pro, 1920×1080) : au moins 60 images/s en moyenne, 99 % des images sous 25 ms,
  chargement d'une mission sous 0,5 s, mémoire stable.
- Mouvements réduits : les effets ajoutés respectent le réglage.
- Fenêtres d'essai muettes, en arrière-plan, `--no-save`. Un commit par chantier sur `main`, rien n'est poussé.

## Terminé quand

Les sept chantiers sont faits, les captures avant et après montrent le progrès sur tous les écrans, `tools/test.sh`
finit par « TOUS LES TESTS PASSENT », l'application macOS est exportée et vérifiée, et le compte rendu dit
franchement ce qui reste faible.
