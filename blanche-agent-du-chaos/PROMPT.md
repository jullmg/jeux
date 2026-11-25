# Blanche Pronovost agent du Chaos : prompt de réalisation

> Brouillon à réviser. Les choix marqués **(P)** sont des propositions : garde-les, change-les ou raye-les.
> Les questions ouvertes sont à la fin.

## 1. Ta mission

Tu construis **Blanche Pronovost agent du Chaos**, un jeu 3D complet, **prêt à être livré**, dans
`blanche-agent-du-chaos/` : conception, art, code, son, interface, tests, revues, exportation et documentation. Un
prototype ou une démo ne suffit pas : à la fin, on installe le jeu et on y joue du début à la fin sans toi.

**Le jeu :** on est Blanche, une chienne dans la cuisine familiale. Maman cuisine. Quand elle a le dos tourné, on attrape
de la nourriture sur le comptoir. Quand elle regarde, on a intérêt à avoir l'air sage.

**Le ton :** drôle, chaleureux, jamais punitif ni méchant. Maman chicane, soupire et finit souvent par rire.

**Le public (P) :** toute la famille, dès 6 ans, avec assez de défi dans les derniers niveaux pour un adulte.

## 2. Le jeu

### 2.1 Boucle de base

1. Par défaut, Blanche est assise **dans son coin de la cuisine, près de la porte**. Chaque niveau commence là.
2. Maman est occupée : la fenêtre est ouverte. Blanche quitte son coin, va au pied des comptoirs et choisit une cible.
3. On **maintient** le bouton : Blanche met les pattes sur le comptoir et étire le cou. Un anneau se remplit.
4. On relâche (elle redescend) ou on va au bout (elle attrape).
5. Blanche mange sa prise. Les points comptent quand c'est avalé.
6. Un **indice** annonce que Maman va se retourner : il faut avoir l'air sage à temps.
7. Prise en flagrant délit, Maman crie **« AU COIN ! »** et Blanche doit retourner dans son coin.

Le plaisir vient d'une seule question : « Encore une demi-seconde pour le gros morceau, ou je redescends ? »

### 2.2 Maman

Une machine à états lisible : **occupée → indice → se retourne → regarde → retourne à sa tâche**.

- **L'indice est toujours visible et audible** (le fredonnement qui s'arrête, les épaules qui bougent, un « Hmm ? »). Rien
  ne repose sur le son seul ni sur la couleur seule.
- **Elle prend Blanche en flagrant délit** si, pendant qu'elle regarde, Blanche a les pattes sur le comptoir ou de la
  nourriture dans la gueule. Assise l'air sage, au coin ou ailleurs, Blanche ne risque rien. **(P)** Être loin du coin
  fait seulement monter un peu le soupçon.
- **La fenêtre dure plus ou moins longtemps selon la situation :**

| Situation | Effet sur la fenêtre |
|---|---|
| La tête dans le frigo, au téléphone | Longue |
| Elle brasse la sauce, lave la vaisselle | Moyenne |
| Elle coupe des légumes près de Blanche | Courte |
| La minuterie sonne, un chaudron déborde | Très longue, mais soudaine |
| Blanche fait tomber un ustensile ou jappe | Se referme vite |
| Soupçon élevé | Plus courte, avec des vérifications |

- **Jauge de soupçon (P) :** monte avec le bruit, la gourmandise et les flagrants délits ; redescend quand Blanche reste
  sage ou fait ses yeux piteux.
- **Feintes (niveaux avancés) :** elle commence à se retourner puis change d'idée. Une feinte reste distinguable d'un vrai
  indice par un joueur attentif.

#### « AU COIN ! »

C'est le moment fort du jeu : Maman pointe le coin et crie, le mot s'affiche en gros, la caméra réagit. Il doit rester
drôle à la vingtième fois (plusieurs variantes de gestes et de mines piteuses).

- Blanche échappe ce qu'elle avait dans la gueule, le combo revient à ×1 et le soupçon monte.
- **(P)** Elle retourne au coin toute seule, la tête basse, et y reste assise un court moment (environ 2 s, plus long aux
  récidives). On reprend ensuite la main.
- **La punition, c'est le temps perdu** pendant que le repas avance, d'autant plus que la cible était loin du coin.

### 2.3 Nourriture et points (P, à ajuster par l'équilibrage)

| Prise | Temps pour attraper | Temps pour manger | Points |
|---|---|---|---|
| Miette | 0,3 s | instantané | 10 |
| Petit morceau | 1,0 s | 0,5 s | 50 |
| Gros morceau | 2,0 s | 1,5 s | 150 |
| Trésor du niveau (rare) | 3,5 s | 3,0 s | 500 |

- Des miettes tombent aussi par terre quand Maman coupe : peu de points, peu de risque.
- **Combo (P) :** les prises réussies d'affilée multiplient les points (×2, ×3) ; se faire prendre remet à ×1.
- **Sous la table (P) :** cachette pour manger un gros morceau en sécurité.
- **Aliments dangereux (P, dès le niveau 6) :** chocolat, oignon, raisins. Les reconnaître et les laisser donne un bonus ;
  les prendre coûte des points et Maman réagit. Jamais d'image de Blanche malade.

### 2.4 Réussite et échec

- Un niveau dure le temps de préparer le repas (2 à 3 minutes), avec un score à atteindre.
- 1 à 3 étoiles selon le score ; 1 étoile ouvre le niveau suivant.
- **(P)** Pas de vies : on n'est jamais éliminé en cours de niveau. Le niveau est raté si le score n'est pas atteint
  quand le repas est prêt.
- La distance entre le coin et la nourriture compte : les meilleures prises sont souvent les plus loin de la porte.

### 2.5 Niveaux (P)

Chaque niveau ajoute **une seule** nouveauté et la montre avant de la punir.

| # | Repas | Nouveauté | Indice minimal |
|---|---|---|---|
| 1 | Crêpes du déjeuner | Tutoriel jouable : sortir du coin, attraper, redescendre, « AU COIN ! » | 900 ms |
| 2 | Sandwichs | Plusieurs endroits sur le comptoir | 800 ms |
| 3 | Soupe | Les activités de Maman changent la fenêtre, le frigo | 700 ms |
| 4 | Biscuits | Bruits et jauge de soupçon | 650 ms |
| 5 | Pizza | Feintes | 550 ms |
| 6 | Spaghetti | Aliments dangereux | 500 ms |
| 7 | Souper de la visite | Quelqu'un d'autre traverse la cuisine | 450 ms |
| 8 | Dinde de Noël | Tout combiné, grand trésor final | 400 ms |

**Équité, non négociable :** redescendre prend moins de temps que le plus court indice (250 ms au plus). Aucun
flagrant délit ne doit être impossible à éviter pour un joueur qui réagit à l'indice.

### 2.6 Commandes

- Clavier : ← → (ou A D) pour se déplacer, Espace maintenu pour attraper, ↓ pour la cachette, Échap pour la pause.
- Manette : stick ou croix, bouton A, bouton B, Start.
- Tactile (version web) (P) : trois grands boutons à l'écran.

## 3. Direction artistique

### 3.1 Références

Julien dépose les photos dans `reference/` (jamais versionné : ce sont des photos de famille et le dépôt va sur GitHub).
Aucune photo, ni texture tirée d'une photo, ne se retrouve dans le jeu ou dans git sans son accord.

À partir des photos, tu écris d'abord `docs/fiche-reference.md` : plan de la cuisine (dont la porte et le coin de
Blanche), dimensions estimées (comptoir à
environ 90 cm), couleurs, électroménagers, armoires, poignées, plancher, lumière ; pour Blanche : taille, robe, taches,
oreilles, queue, museau, yeux. Tu y notes ce qui manque et tu demandes les photos qu'il faut.

### 3.2 Style

- **Low poly coloré**, comme un petit film d'animation : formes arrondies, lumière chaude, ombres douces.
- La cuisine est **reconnaissable** : même disposition, mêmes couleurs, mêmes objets marquants.
- Blanche est **reconnaissable** et expressive : c'est la vedette, elle reçoit le plus de soin.
- Caméra **(P)** fixe à hauteur un peu basse, qui suit doucement Blanche. Maman, la cible, le coin et l'indice sont
  toujours dans le cadre.

### 3.3 Animations minimales

- **Blanche :** assise dans son coin, attente, marche, montée sur le comptoir, étirement du cou, prise, descente,
  mâchouillage, air sage, surprise, retour piteux au coin, victoire. Queue et oreilles vivantes.
- **Maman :** une par tâche (couper, brasser, laver, frigo, téléphone, four), indice, demi-tour, regard, « AU COIN ! » le
  doigt pointé, rire, feinte.

### 3.4 Chaîne de production

- Blender sans interface, piloté par des scripts Python dans `tools/blender/`, exporte en `.glb` vers `art/models/`.
  **On modifie le script et on régénère**, jamais le fichier produit.
- Chaque modèle produit aussi un rendu d'aperçu PNG, que tu regardes et compares aux photos.
- Pour les personnages animés, essaie tôt les deux voies (modèle et armature par script ; modèle libre CC0 adapté),
  montre les deux et laisse Julien choisir.
- Tant que Blender n'est pas installé, avance avec des formes simples dans Godot.

## 4. Son et textes

- Effets : jappements, pas de pattes, mâchouillage, cuisine (couteau, chaudron, frigo, minuterie), indice, flagrant
  délit, victoire. Synthétisés par code ou libres (CC0), chaque source notée dans `SOURCES.md`.
- Musique : une ambiance au menu, une en jeu qui se tend quand le soupçon monte. Julien peut fournir ses morceaux ;
  le jeu fonctionne sans eux.
- Tout le texte est en **français du Québec** ; Maman parle québécois (« ben là », « astheure », « tsé »). Toutes les
  répliques sont dans un seul fichier, avec plusieurs variantes pour éviter la répétition.

## 5. Écrans

Titre · choix du niveau avec étoiles · tutoriel intégré au niveau 1 · jeu avec HUD (score, objectif, soupçon, temps du
repas) · pause · niveau réussi · niveau raté · fin du jeu · options (volumes, plein écran, commandes, mouvements
réduits, indices plus longs) · crédits.

Interface grosse et lisible, utilisable entièrement au clavier, à la manette et à la souris.

## 6. Technique

- **Godot 4.7**, GDScript typé, moteur de rendu **Compatibility (P)** pour permettre la version web. 1920×1080 de base,
  autres formats sans coupure.
- **Les règles sont séparées de l'affichage** : fenêtre, détection, soupçon et score fonctionnent sans 3D et avec une
  graine fixe, pour être testés et simulés.
- **Les niveaux sont des données** (un fichier par niveau) : ajouter un niveau ne demande aucun nouveau code, sauf pour
  une nouvelle mécanique.
- Sauvegarde dans `user://` : niveaux débloqués, étoiles, meilleurs scores, options. Un fichier corrompu ou ancien ne
  fait jamais planter le jeu.
- Structure : `scenes/`, `game/` (règles), `characters/`, `kitchen/`, `ui/`, `audio/`, `art/`, `levels/`, `tests/`,
  `tools/`, `docs/`.

## 7. Étapes

À chaque **arrêt**, tu montres le résultat (captures, ou commande pour jouer), tu poses tes questions et **tu attends le
feu vert**. Entre deux arrêts, tu travailles seul et tu notes les questions non bloquantes pour le rapport.

| Étape | Livrable | Arrêt : la question posée |
|---|---|---|
| 0. Préparation | Squelette du projet, `CLAUDE.md`, ligne dans le `CLAUDE.md` racine, fiche de référence | La fiche est-elle juste ? |
| 1. Prototype gris | Boucle complète avec des formes simples, un niveau, tests des règles | Est-ce **amusant** ? |
| 2. Direction artistique | Blanche, Maman et la cuisine : premiers rendus à côté des photos | Les reconnaît-on ? |
| 3. Tranche complète | Niveau 1 à la qualité finale : art, animations, son, interface | Est-ce la qualité voulue ? |
| 4. Production | Les 8 niveaux et toutes les mécaniques | Que faut-il changer après y avoir joué ? |
| 5. Finition | Équilibrage, effets, rythme, accessibilité | La difficulté monte-t-elle bien ? |
| 6. Assurance qualité | Tous les tests et revues, corrections | Rapport complet |
| 7. Livraison | Versions exportées, documentation, version 1.0.0 | Acceptation finale |

On ne commence pas l'art détaillé avant que le prototype soit jugé amusant.

## 8. Tests

Une seule commande, `tools/test.sh`, lance tous les tests automatiques et échoue au moindre problème. Les tests
s'écrivent **en même temps** que le code ; chaque bogue corrigé reçoit un test.

1. **Règles** (sans fenêtre) : états de Maman, détection aux limites de temps, retour au coin (aucune prise possible
   pendant la punition, jamais de blocage), points, combo, soupçon, étoiles, déblocage, sauvegarde et fichiers corrompus.
2. **Robots joueurs** (sans fenêtre, accéléré, graines fixes, au moins 1000 parties par niveau et par profil) : prudent,
   gourmand, et trois temps de réaction (300, 500, 700 ms). Vérifier que chaque niveau se gagne, que 3 étoiles sont
   atteignables, que la réussite baisse d'un niveau à l'autre, que l'équité de 2.5 tient et qu'aucune stratégie
   dégénérée (spammer le bouton, ne prendre que des miettes) ne bat un jeu honnête.
3. **Intégration** : chaque écran et chaque transition avec des entrées simulées (clavier, manette, souris, tactile),
   pause à tout moment, perte de focus. Journaux sans erreur, avertissement ni fuite.
4. **Visuels** : captures de chaque écran, niveau et animation clé, en 16:9, 16:10 et un format étroit. **Tu les
   regardes** : découpes, modèles qui se traversent, texte coupé, indice peu lisible.
5. **Performance** : 60 images/s en 1080p sur le MacBook (M1 Pro), chargement d'un niveau en moins de 3 s, mémoire
   stable après 20 parties de suite, taille de la version web notée.
6. **Versions exportées** : lancer l'application macOS et la version web (servie localement, dans un navigateur), faire un
   niveau, vérifier la sauvegarde après redémarrage.
7. **Essais humains** : tu ne peux pas juger seul le plaisir. Prépare une grille courte (compris sans explication ?
   injustice ressentie ? niveau trop dur ?), puis corrige à partir des réponses de Julien et de sa famille.

## 9. Revues

Aux étapes 3, 4 et 6, et corriger avant d'avancer :

- **Code** : `/code-review high`, puis `/simplify`.
- **Regard neuf** : un sous-agent sans contexte relit le jeu et le code et cherche les bogues (`model: sonnet` ; `opus`
  pour un bogue subtil).
- **Jeu** : chaque niveau enseigne-t-il sa nouveauté ? L'échec est-il compris ? A-t-on envie de recommencer ?
- **Art** : rendus côte à côte avec les photos ; cohérence du style.
- **Accessibilité** : indices sans son et sans couleur, taille du texte, mouvements réduits, indices plus longs.
- **Textes** : orthographe, français du Québec, ton bienveillant.
- **Droits et vie privée** : chaque ressource externe a une source et une licence ; aucune photo ni donnée personnelle
  dans le dépôt ou les versions exportées ; `/security-review` avant la livraison.

Chaque revue laisse une trace dans `docs/revues.md` : trouvé, corrigé, ou laissé de côté avec la raison.

## 10. Livraison

- Application **macOS** et version **web** **(P)**, produites par `tools/export.sh` (les modèles d'exportation Godot sont
  à installer). Sans compte développeur Apple, l'application ne sera pas notariée : documenter comment l'ouvrir.
- Icône, écran de démarrage, nom et numéro de version.
- `README.md` (jouer, tester, exporter), `CHANGELOG.md`, `SOURCES.md`, `CLAUDE.md` à jour.
- Étiquette git `blanche-v1.0.0` à la version acceptée.
- Aucune publication en ligne sans demande explicite.

### Le jeu est terminé quand

- [ ] les 8 niveaux se jouent du début à la fin, avec leurs étoiles et la fin du jeu ;
- [ ] `tools/test.sh` passe, et la sortie est montrée ;
- [ ] les versions exportées sont testées ;
- [ ] aucune forme provisoire, aucun texte de remplissage, aucun bogue connu bloquant ;
- [ ] les revues sont consignées et les corrections faites ;
- [ ] la documentation permet de reprendre le projet sans toi ;
- [ ] Julien y a joué et accepte.

## 11. Règles de travail

- Un commit par tâche terminée et vérifiée, sur `main`, avec seulement les fichiers de la tâche. Pousser seulement sur
  demande. Ne pas toucher aux autres jeux.
- Toute fenêtre Godot : sans son (`--audio-driver Dummy`), sans prendre le focus (`open -g`), sur l'écran du MacBook,
  avec `-- --no-save`, et elle se ferme seule. Tests logiques sans fenêtre.
- Pas de ligne dans le journal d'usage (projet personnel).
- Une demande reçue en cours de tâche attend la fin de celle-ci.
- Rapporter honnêtement : ce qui échoue, ce qui est sauté, ce qui n'a pas pu être vérifié.
- Tenir `docs/etat.md` : étape en cours, fait, à faire, questions. C'est le point de reprise d'une session à l'autre.
- Toute idée hors de ce document va dans `docs/idees.md` et attend un accord.

## 12. Hors de la version 1.0 (P)

Multijoueur, mode sans fin, autres pièces que la cuisine, boutique ou costumes, classement en ligne, autres langues,
magasins d'applications.

## 13. Questions à régler

1. Où le jeu doit-il tourner : Mac seulement, web, iPad, Windows ?
2. Qui jouera, et quel âge ont les plus jeunes ?
3. Maman : à partir d'une photo, d'une description, ou inventée ?
4. D'autres personnages (niveau 7) : Papa, un enfant, un chat ?
5. Les 8 repas conviennent-ils ? Y a-t-il des recettes ou des habitudes de la famille à mettre ?
6. As-tu des répliques typiques de Maman ou des manies de Blanche à reproduire ?
7. Musique : tes propres morceaux ?
8. Les aliments dangereux : on les garde ?
9. Veux-tu enregistrer la vraie voix de Maman qui crie « AU COIN ! » (et d'autres répliques) ?
10. Sans vies, avec le temps perdu comme seule punition : ça te va, ou faut-il une limite de « AU COIN ! » par niveau ?
