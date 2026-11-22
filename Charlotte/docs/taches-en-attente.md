# Tâches demandées par Julien, en attente (dans l'ordre)

1. ~~FAIT~~ Intérieur du dépanneur **Oh Bon!** (coin Holt) : mieux rangé et plus beau que Xin-Xin, grande télé accrochée haut qui joue
   des émissions. Caissier : un homme chauve, un peu gros, d'allure cambodgienne. (`scenes/ohbon.gd`)
2. ~~FAIT~~ Le dépanneur **Xin-Xin** (coin Dandurand) doit avoir l'air **moins bien rangé** : beaucoup d'objets qui traînent partout,
   très encombré, contrairement à Oh Bon!.
3. ~~FAIT (chambre, salon, corridor, cuisine, vestibule)~~ Améliorer l'apparence de la **chambre et de la maison de Charlotte** ; les améliorations doivent être **réutilisables** pour
   les futurs intérieurs de maison (pièces de `InteriorArt`, `RoomShell`, lumière…).
4. ~~EN GRANDE PARTIE FAIT (clients, objets, encombrement de Xin-Xin, affichage mural d'Oh Bon!)~~ **Revoir l'apparence de tous les dépanneurs** pour qu'ils aient l'air « 10 fois mieux ».
5. ~~FAIT (mouvement et tâches ; apparence : vêtements seulement)~~ Améliorer l'apparence des **parents de Charlotte**, les faire **bouger** et leur faire faire des **tâches au hasard**.

(Fait aussi : une panoplie d'objets de commerce supplémentaires dans `ShopArt`, voir `.claude/CLAUDE.md`.)

## Demandées ensuite (2026-11-02)

6. **Carte (map)** du quartier que Charlotte consulte, dessinée comme par un enfant ; et **les coins ne se tournent plus tout seuls** en
   marchant vers l'intersection : il faut cliquer la rue transversale ou appuyer sur ↑ au coin. (Coins : FAIT. Carte : FAITE, touche C ou bouton à gauche du carnet.)
7. ~~FAIT (miroir, caméra, extincteur, porte arrière, seaux de fleurs, palette, diable, enseigne OUVERT ; catalogue `tools/shop_objects`)~~ Améliorer l'apparence des **objets du dépanneur** (les dessins de `ShopArt` : produits, meubles, accessoires).
8. ~~FAIT~~ Les **écureuils** peuvent parfois **monter sur les poteaux électriques** puis **marcher sur les fils** (`Squirrel`, `UtilityPoles`).
9. ~~FAIT~~ **Personnages** : une articulation (coude) aux bras et des mains avec des doigts (`Character`, `CharacterArt`).
10. ~~FAIT~~ **Genoux** aux jambes des personnages (articulation), puis **réviser tout** (cyclistes, objets portés, laisse, etc.) pour ne rien briser.
11. ~~FAIT~~ **Améliorer l'apparence des vêtements** des personnages (`CharacterArt`).
12. ~~FAIT~~ **Expressions faciales** des personnages selon leurs actions (yeux, bouche, sourcils : content, concentré, surpris, goûte, dort…).

## À réviser par Julien (en jouant)

- **Ruelles, 2026-11-22** (deux passes de bugs visuels, commit 8cb1e51) : regarder les trois ruelles dans les quatre saisons.
  Corrigés : cordes à linge qui montaient dans le ciel, lierre en rectangle sur les murs de côté, plaques rectangulaires sur ces murs,
  lianes nues d'hiver trop serpentines, arbre de cour qui poussait sur le toit d'un garage / d'une tôle / d'un hangar (il est
  maintenant omis derrière ces façades), traînée brune trop large sur la tôle. Seule chose laissée : les clôtures floues du bas de
  l'écran qui s'arrêtent net là où une ruelle s'ouvre (voulu).

## Demandées le 2026-11-22 (dans l'ordre)

14. ~~FAIT (perles du collier, tapis de découpe, cartes du choix, ficelle, perles centrées)~~ **Bricolage** (`ui/craft_studio.gd`, `world/craft_art.gd`) : refonte visuelle complète, d'abord les perles du collier (plus belles), puis le reste de l'atelier (cartes du choix, établi, étiquettes), et améliorer aussi le fonctionnement.
15. ~~FAIT~~ **Bug de la ruelle** (capture `reference/bugs/Screenshot 2026-11-22 at 8.36.04 AM.png`, flèche rouge) : dans la ruelle du milieu, vers la ruelle verte, un petit bâtiment rouge apparaît « à l'intérieur » du grand bâtiment beige (les dos de plex de la vue `LaneArt.junction` / `tee` passent par-dessus le mur d'un bâtiment).
16. ~~FAIT (dos de plex : linteaux, appuis, meneaux, suie, corbeaux de briques, pièce rejointoyée)~~ **Bâtiments des ruelles** : améliorer leur apparence (dos de plex, murs de côté, garages).
17. ~~FAIT (bottes sur leur plateau, bac de recyclage bleu avec son couvercle ouvert)~~ **Maison de Charlotte** : améliorer l'apparence des bottes à l'entrée et du bac de recyclage (`InteriorArt`).
18. **À FAIRE SEULEMENT QUAND JULIEN LE DIRA** (« pas tout de suite ») : **Bac de recyclage** de la maison de Charlotte (`InteriorArt.recycling_bin`) : améliorer le signe de recyclage dessiné dessus.
19. **Bug, fête d'Alyzée** (`scenes/fete_alyzee.gd`, étape de la licorne : épingler la corne les yeux bandés, `_Blindfold`) : pendant ce jeu, Alyzée n'est pas dans l'écran (la vue est cadrée ailleurs, ou le noir la cache) et sa bulle de texte apparaît à côté de l'écran. À corriger : qu'elle reste visible, ou que sa bulle soit placée dans le cadre.
20. **À FAIRE SEULEMENT QUAND JULIEN LE DIRA** : **Fête d'Alyzée**, la piñata (`_Pinata`, étoile en papier crépon) et les bonbons qui tombent : améliorer leur apparence (`scenes/fete_alyzee.gd`, `world/party_art.gd`).
21. **À FAIRE SEULEMENT QUAND JULIEN LE DIRA** : **Charlotte qui mange** (expression « yum » ou « grin » : `CharacterArt._open_smile`, `Character.EXPRESSIONS`) : elle ouvre la bouche avec des yeux contents, mais une langue bizarre, un truc rouge, sort de sa bouche. À arranger (une langue propre, rentrée dans la bouche, ou la retirer).
22. **À FAIRE SEULEMENT QUAND JULIEN LE DIRA** : **Fête d'Alyzée, étape du film** (`scenes/fete_alyzee.gd`, `Stage.FILM`, `FILM_LINES`) : (a) un clic sur la télé fait défiler toutes sortes de postes, ce qui ne marche pas ; on ne doit pas pouvoir changer de poste là, et le film doit démarrer seulement après qu'on a parlé à Alyzée (le clic sur la télé ne doit rien faire d'autre) ; (b) pendant que les enfants regardent le film, la maman d'Alyzée est placée par-dessus les enfants, drôlement : la mettre à un endroit logique (debout derrière le canapé, ou hors du cadre).
