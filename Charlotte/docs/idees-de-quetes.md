# Idées de quêtes à implémenter

Liste de Julien, à faire plus tard. Quand une quête est faite, la déplacer dans `world/quests.gd` et la rayer ici
(les quêtes déjà dans le jeu sont décrites dans `.claude/CLAUDE.md`, section « Quests and growing up »).
Rappels : une seule chose dans les bras à la fois (voir `world/carry.gd`) ; un nouveau lieu va dans `DebugMenu.PLACES`.

1. **Trouver les morceaux de pizza cachés par un écureuil** (première quête de la liste)
2. **Aller faire du jogging avec papa**
3. **Aller acheter des chips crème sure et oignons au dépanneur** en bas de la rue, sur Dandurand
   (le dépanneur Xin-Xin vend déjà ces chips : présentoir `chips_gondola`, saveur `creme` dans `ShopArt.CHIPS`)

## Notes de départ (à préciser avec Julien avant de programmer)

- La quête des chips peut se donner par Maman ou Papa et se rapporter à la maison, comme le lait ; elle ne mettrait rien
  dans les bras (le sac se tient à la main) ou passerait par `Carry` si on veut le voir porté.
- Les écureuils existent déjà sur les rues (`world/squirrel.gd`, ils fuient Charlotte et grimpent aux arbres) : les morceaux
  de pizza pourraient être cachés près de leurs arbres.
- Le jogging avec Papa demanderait un parcours (le tour du bloc est déjà permis avant 8 ans) et Papa qui court à côté d'elle.
