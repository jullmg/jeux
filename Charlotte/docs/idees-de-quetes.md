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
11. **Le bonhomme de neige avec Billie et Auguste** (choisie par Julien, 2026-11-19) : leur première quête. Charlotte rassemble
    une carotte (au Fraîchement Bon), des boutons et une tuque, puis on monte le bonhomme dans la ruelle.
12. **La glissade dans la cour d'école** (choisie par Julien, 2026-11-19) : la butte de neige de la cour est déjà dessinée ;
    il faut d'abord emprunter un traîneau.
13. **La souffleuse passe la nuit** (choisie par Julien, 2026-11-19) : après une tempête, Charlotte aide Papa à pelleter
    l'escalier ; les voitures sont parties pour le déneigement et les gros camions (souffleuse, camions) passent dans la rue.
14. **Faire le sapin de Noël** (Julien, 2026-11-19) : décorer le sapin de Noël à la maison.

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
- Le bonhomme de neige : Billie et Auguste (`world/billie_auguste.gd`) attendent leur première quête dans `BillieAuguste.interact`.
  La carotte au Fraîchement Bon pose problème : il est sur Masson, qu'on n'atteint pas encore depuis son bloc, et il faut
  traverser (8 ans). Avant 8 ans : la carotte chez Xin-Xin ou Oh Bon!, ou dans le frigo de Maman. Les boutons et la tuque
  pourraient venir de la maison (sa commode, la penderie de l'entrée). Une chose à la fois dans les bras (`Carry`).
- La glissade : la butte de neige est dans `SchoolYardArt` (hiver, avec un enfant qui glisse déjà) ; la cour n'est atteinte
  que par la quête de l'école. Le traîneau à emprunter : aux jumelles, à Alyzée, ou au service de garde ?
- La souffleuse : les voitures ont été retirées des rues (2026-10-31, voir l'historique git) ; il faudrait dessiner la
  souffleuse, les camions et les pancartes orange de déneigement, et pelleter l'escalier extérieur de son duplex.
- Le sapin de Noël : à préciser. Le sapin s'achète-t-il (un vendeur de sapins sur le trottoir, comme à Montréal en
  décembre) ou sort-il de la boîte ? Où va-t-il (le salon) ? Les décorations : boules, guirlandes, lumières, l'étoile ou
  l'ange en haut (Papa la soulève ?), une à la fois depuis une boîte comme le ménage de sa chambre. Le sapin reste décoré
  ensuite (un flag), allumé le soir.
- Le livre perdu (fait) : Constance le demande, il est dans le croque-livre de la ruelle verte (`ruelle.gd` `BOOK_LANE`), Charlotte le porte dans ses bras
  (`Carry` « book », `LaneArt.lost_book`) et le `BookReader` s'ouvre sur « Minou et la lune » quand elle le rapporte.
