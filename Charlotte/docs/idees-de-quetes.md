# Idées de quêtes à implémenter

Liste de Julien, à faire plus tard. Quand une quête est faite, la déplacer dans `world/quests.gd` et la rayer ici
(les quêtes déjà dans le jeu sont décrites dans `.claude/CLAUDE.md`, section « Quests and growing up »).
Rappels : une seule chose dans les bras à la fois (voir `world/carry.gd`) ; un nouveau lieu va dans `DebugMenu.PLACES`.

1. **Trouver les morceaux de pizza cachés par un écureuil** (première quête de la liste)
2. **Aller faire du jogging avec papa**
3. **Aller acheter des chips crème sure et oignons au dépanneur** en bas de la rue, sur Dandurand
   (le dépanneur Xin-Xin vend déjà ces chips, de marque **Ruffles** : présentoir `chips_gondola`, saveur `creme` dans `ShopArt.CHIPS`)
4. **Aller cueillir des framboises dans la cour**
5. **Aller cueillir des raisins dans la cour**
6. **Trouver le livre perdu d'un ami dans le croque-livre** (mission donnée par un ami)

## Notes de départ (à préciser avec Julien avant de programmer)

- La quête des chips peut se donner par Maman ou Papa et se rapporter à la maison, comme le lait ; elle ne mettrait rien
  dans les bras (le sac se tient à la main) ou passerait par `Carry` si on veut le voir porté.
- Les écureuils existent déjà sur les rues (`world/squirrel.gd`, ils fuient Charlotte et grimpent aux arbres) : les morceaux
  de pizza pourraient être cachés près de leurs arbres.
- Le jogging avec Papa demanderait un parcours (le tour du bloc est déjà permis avant 8 ans) et Papa qui court à côté d'elle.
- Framboises et raisins : la cour de Charlotte est le lot `OWN_LOT` de la ruelle du milieu (balançoire, vélo de Papa, marelle). Il faudra y
  dessiner les plants (`LaneArt._yard`, `_foliage` pour les feuilles) ; ils dépendent de la saison (framboises en été, raisins à l'automne),
  et on peut les porter par `Carry` comme le lait. Le bas de clôture ne permet pas encore d'entrer dans la cour : à décider.
- Le livre perdu : il y a déjà un croque-livre dans chaque ruelle (`LaneArt.croque_livre`, `_open_croque_livre` en attente d'une quête) et des
  enfants qui jouent dans les ruelles (`JumpRopeKid`, `BallKid`, cliquables) qui pourraient être l'ami qui donne la mission. Le lecteur de
  livres `BookReader` peut montrer le livre retrouvé.
