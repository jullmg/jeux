# Idées de quêtes à implémenter

Liste de Julien, à faire plus tard. Quand une quête est faite, la déplacer dans `world/quests.gd` et la rayer ici
(les quêtes déjà dans le jeu sont décrites dans `.claude/CLAUDE.md`, section « Quests and growing up »).
Rappels : une seule chose dans les bras à la fois (voir `world/carry.gd`) ; un nouveau lieu va dans `DebugMenu.PLACES`.

1. **Trouver les morceaux de pizza cachés par un écureuil** (première quête de la liste)
2. **Aller faire du jogging avec papa**
3. ~~**Aller acheter des chips crème sure et oignons au dépanneur**~~ (fait : la quête `chips`, après l'Halloween ; Papa
   donne 3 $, elle rapporte le sac de Ruffles et il met le hockey à la télé)
4. **Aller cueillir des framboises dans la cour**
5. **Aller cueillir des raisins dans la cour**
6. ~~**Trouver le livre perdu d'un ami dans le croque-livre**~~ (fait : la quête `livre`, donnée par Constance après la cachette ; le livre attend dans le croque-livre de la ruelle verte et elles le lisent ensemble au retour)
7. ~~**Planifier une soirée cinéma avec des amis**~~ (fait : la quête `cinema`, après l'Halloween ; les jumelles la proposent,
   Maman donne 5 $, chips et bonbons au dépanneur, puis le film devant la télé du corridor, `world/cinema.gd`)
8. **La fête d'un ami** : elle va acheter un cadeau avec Maman
9. ~~**Jouer à la cachette avec les amis**~~ (fait : la quête `cachette`, la première des jumelles)
10. **L'orage et la panne d'électricité** (idée de Julien, 2026-11-18) : un orage éclate (ciel noir, éclairs, tonnerre, pluie),
    Charlotte doit rentrer vite à la maison, et là il y a une panne d'électricité : plus de lumières ni de télé, il faut trouver
    la lampe de poche (ou des chandelles avec Maman et Papa) et attendre que le courant revienne.
11. ~~**Le bonhomme de neige avec Billie et Auguste**~~ (fait : la quête `bonhomme`, `world/snowman.gd` ; la carotte vient du
    frigo, les boutons de Maman, la tuque du Canadien de Papa)
12. ~~**La glissade dans la cour d'école**~~ (fait : la quête `glissade`, `world/sledding.gd` ; Jade prête le traîneau au
    service de garde, trois descentes sur la butte de la cour)
13. ~~**La souffleuse passe la nuit**~~ (fait : la quête `souffleuse`, `world/snowstorm.gd` et `world/snow_removal.gd` ; la
    tempête au coucher, les quatre tas sur le perron et les marches avec Papa, puis la souffleuse et son camion)
14. ~~**Faire le sapin de Noël**~~ (fait : la quête `sapin`, `world/xmas_tree.gd` et `world/tree_sale.gd` ; la vente de sapins
    dans la cour d'école avec Papa, puis les décorations une à une et l'étoile)
15. ~~**Noël**~~ (fait : la quête `noel`, `world/christmas.gd` ; la lettre au père Noël, les biscuits avec Maman, le réveillon,
    le traîneau dans la nuit, les cadeaux du matin de Noël)

16. **Le jour de l'an** (Julien, 2026-11-19, après Noël) : la veillée à la maison, le Bye Bye à la télé, le compte à rebours à
    minuit, les feux d'artifice par la fenêtre, les souhaits le matin.
17. **Le fort de neige** (Julien, 2026-11-19) : bâtir un fort avec les jumelles dans la ruelle, puis une bataille de balles de
    neige contre Billie et Auguste.
18. **La dent qui branle** (Julien, 2026-11-19) : sa dent tombe, sous l'oreiller, la fée des dents laisse des sous.
19. **La fête de Charlotte, le 1er février** (Julien, 2026-11-19) : elle choisit les amis qu'elle invite, cinq au plus. Elle
    garde 7 ans pour l'instant (pas encore le droit de traverser seule).

## Notes de départ (à préciser avec Julien avant de programmer)

- La quête des chips peut se donner par Maman ou Papa et se rapporter à la maison, comme le lait ; elle ne mettrait rien
  dans les bras (le sac se tient à la main) ou passerait par `Carry` si on veut le voir porté.
- Les écureuils existent déjà sur les rues (`world/squirrel.gd`, ils fuient Charlotte et grimpent aux arbres) : les morceaux
  de pizza pourraient être cachés près de leurs arbres.
- Le jogging avec Papa demanderait un parcours (le tour du bloc est déjà permis avant 8 ans) et Papa qui court à côté d'elle.
- Framboises et raisins : la cour de Charlotte est le lot `OWN_LOT` de la ruelle du milieu (balançoire, vélo de Papa, marelle). Il faudra y
  dessiner les plants (`LaneArt._yard`, `_foliage` pour les feuilles) ; ils dépendent de la saison (framboises en été, raisins à l'automne),
  et on peut les porter par `Carry` comme le lait. Le bas de clôture ne permet pas encore d'entrer dans la cour : à décider.
- Alphée et Constance Turcotte (`world/twins.gd`) ont déjà donné la cachette et le livre perdu ; la soirée cinéma et la fête leur iraient bien aussi.
- Soirée cinéma : le dépanneur vend déjà de quoi grignoter (`Shop._buy`, `Shop.PRICES`) et l'argent de poche existe (`GameState.money`) ; il faudrait que Maman ou Papa lui en donne (nouveau), et un lieu où regarder le film (la télé du corridor, `TvScreen`).
- La fête : il n'y a pas encore de magasin de cadeaux, et Maman ne sort pas encore de la maison (elle marche seulement à l'intérieur, `FamilyRoutine`). À décider.
- Le livre perdu (fait) : Constance le demande, il est dans le croque-livre de la ruelle verte (`ruelle.gd` `BOOK_LANE`), Charlotte le porte dans ses bras
  (`Carry` « book », `LaneArt.lost_book`) et le `BookReader` s'ouvre sur « Minou et la lune » quand elle le rapporte.
