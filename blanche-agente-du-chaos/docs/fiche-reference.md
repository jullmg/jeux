# Fiche de référence (étape 0)

Établie à partir des photos de `reference/` (jamais versionnées). Les dimensions sont **estimées** : les corriger dans
`data/kitchen.json`, puis relancer `tools/build_art.sh`.

## La cuisine

Pièce d'environ 4,0 m (est-ouest) × 4,2 m (nord-sud), plafond à 2,8 m. La caméra regarde vers le nord, comme sur la
première photo ; le mur sud n'est pas montré.

| Mur | De gauche à droite |
|---|---|
| Nord | Garde-manger, frigo inox (congélateur en bas, papiers aimantés), comptoir, cuisinière et hotte blanche, comptoir, micro-ondes sur sa tablette, coin de brique |
| Est | Comptoir, évier double à robinet noir sous la fenêtre (plantes), lave-vaisselle inox, panneau de bout, porte blanche à carreau avec store, imposte, climatiseur blanc au-dessus |
| Sud | Radiateur de fonte blanc près du coin de Blanche |
| Ouest | Buffet blanc à dessus de bois, appareils, armoire murale vitrée dépolie, plantes suspendues |

- **Armoires :** bois blond (érable), portes à cadre, poignées horizontales en laiton clair.
- **Comptoir :** stratifié bleu-gris foncé moucheté, à environ 92 cm.
- **Dosseret :** petits carreaux blancs. **Murs et soffite :** blanc cassé.
- **Plancher :** lattes de bois étroites, miel, usées et luisantes.
- **Éclairage :** rail de quatre projecteurs au plafond, lumière chaude.
- **Îlot :** dessus de bois blond, pattes blanches, panneau plein et tablettes ouvertes au bout sud (panier, poubelle),
  environ 70 × 135 cm. **Tabouret** gris à pattes de bois et cerceau noir, du côté ouest.
- **Coin de Blanche :** coussin gris devant la porte, au bout du radiateur ; support à deux bols en bois gris ; balle
  jaune ; jouet à deux anneaux rouges et boule noire.

## Blanche

Jeune chienne de taille moyenne à grande, poil **noir** mi-long et lustré. Grandes oreilles tombantes à franges, tête
ronde, museau assez large, truffe noire, yeux **ambrés**, tache **blanche au poitrail**, bout des pattes blanc, queue
touffue, collier rose pâle avec un médaillon en cœur cuivré (sans l'inscription).

Retenu pour le modèle : environ 55 cm au garrot.

## Les personnages

Stylisés, reconnaissables par la silhouette, la coiffure et les vêtements, sans réalisme photographique.

| Personnage | Retenu |
|---|---|
| Maman | Cheveux aux épaules, blond cendré à racines foncées ; chandail noir à motif doré et blanc ; pantalon noir |
| Papa | Cheveux courts bruns, barbe de quelques jours ; kangourou brun en mouton sur t-shirt kaki ; jeans |
| Charlotte | Longs cheveux châtains ondulés ; polaire crème à bordures vert sauge ; pantalon mauve |

## Ce qui manque (non bloquant)

- Blanche debout, de profil et de dos : la queue et la silhouette sont devinées.
- Maman, Papa et Charlotte en pied : bas du corps, chaussures et tailles inventés.
- Le mur sud et l'entrée de la cuisine.
- Les dimensions réelles (largeur de la pièce, taille de l'îlot).

## Vie privée

Aucun visage des photos du frigo ni aucune inscription n'est reproduit : le frigo porte des papiers et des dessins
génériques. Aucune texture ne vient d'une photo.

## La salle à manger et le salon (missions 9 à 15)

D'après les quatre photos de `reference/photos-8/` (2026-11-25). Les pièces sont montrées **en ordre** : le désordre
du moment est retiré. Les dimensions sont **estimées** ; elles vivent dans `data/pieces/*.json` et
`tools/blender/double_salon.py`.

### Où elles sont

Un double salon de plex montréalais : **une seule longue pièce** d'environ 3,3 m de large sur 7,4 m, sans cloison,
avec deux luminaires au plafond. Le **salon** est à l'avant, sur la rue (sa fenêtre) ; la **salle à manger** derrière,
du côté de la cuisine. Un **corridor** longe le mur ouest jusqu'à la cuisine (réponse de Julien) : la porte de bois de
la salle à manger et la grande ouverture du salon donnent sur lui. La cuisine est au bout du corridor, au nord ; on y
arrive par son coin sud-ouest (la porte d'où viennent Papa et Charlotte dans la cuisine).

Repère commun aux deux pièces (mètres) : x vers l'est, z vers le sud (la rue), l'origine au milieu de la limite entre
les deux pièces. Salle à manger : z de −3,6 à 0 ; salon : z de 0 à 3,8 ; murs à x = ±1,65. Plafond à 2,9 m.

```
                 nord (mur ardoise)
     ┌──porte┬cage┬──buffet + étagère──┬────────┐
     │ bois  └────┘                    │        │
     │            ┌───── table ─────┐  │ trois  │
  co-│            │  quatre chaises │  │affiches│
  rri│            └─────────────────┘  │ lampe  │
  dor│                                 │ sur    │
     ┼ - - - - - - - - - - - - - - - - ┼ pied - ┤  limite des deux pièces (aucune cloison)
     │grande     ┌──── divan ────┐     │        │
     │ouverture  └───────────────┘     │ mur de │
     │                ┌table basse┐    │ cadres │
     │fauteuil        └───────────┘    │berçante│
     │marine                           │plante  │
     │piano + télé   │ fenêtre │  étagère de coin
     └───────────────┴─────────┴──────────────────┘
                 sud (la rue)
```

### Commun aux deux pièces

| Élément | Retenu |
|---|---|
| Plancher | lattes étroites d'érable miel, luisantes, posées dans la longueur |
| Murs, plafond | blanc cassé ; corniche de plâtre moulurée ; une **rosace** de plâtre au-dessus de chaque luminaire |
| Plinthes, cadres de porte | bois foncé verni (noyer) |
| Lumière | jour froid et clair par la fenêtre du salon ; lampes chaudes ; plafond haut |

### La salle à manger (environ 3,3 × 3,6 m)

| Mur | De gauche à droite (vu du salon) |
|---|---|
| Nord | Mur **ardoise très foncée** (gris-bleu presque noir) : la cage de Blanche dans le coin ouest, le buffet bas noir, l'étagère au-dessus |
| Ouest | Porte de bois verni (vers le corridor et la cuisine), près du coin nord ; une affiche |
| Est | Trois affiches encadrées (motifs inventés) ; lampe sur pied en laiton à globe de verre fumé, près du salon |

- **Étagère :** montants de fer noir, quatre planches de bois blond (environ 1,4 m de large), couverte de
  **céramiques artisanales** : tasses, bols, vases et assiettes aux glaçures pastel (crème, rose, vert d'eau, bleu
  pâle, jaune), une plante retombante.
- **Buffet :** bas (environ 75 cm), noir mat, 1,6 × 0,45 m ; dessus : tourne-disque, une pile de disques, deux jeux de
  société, quelques céramiques. Côté cage : rien de près de la nourriture.
- **La cage de Blanche :** caisse de fil noir (environ 75 × 55 × 60 cm), porte ouverte vers la pièce, couverture à
  motifs crème et arc-en-ciel, coussin mauve. **C'est le coin de Blanche dans cette pièce** (« DANS TA CAGE ! »).
- **Table :** bois foncé, coins arrondis, environ 1,5 × 0,9 m, **75 cm** de haut ; on passe dessous.
- **Chaises :** quatre, style scandinave : dossier courbé de noyer, siège rembourré noir, pattes fuselées.
- **Suspension :** globe de verre opale sur une tige de laiton, au-dessus de la table.

### Le salon (environ 3,3 × 3,8 m)

| Mur | De gauche à droite (vu de la salle à manger) |
|---|---|
| Est | **Mur de cadres** (cadres noirs, un miroir ovale doré, une horloge de bois) ; fauteuil berçant blanc à structure de bois blond ; une plante sur une petite boîte de bois et un panier |
| Sud | Étagère de coin ancienne en bois foncé ; grande **fenêtre à guillotine**, rideaux marine, radiateur blanc dessous, garde-corps de fer forgé dehors ; **piano numérique noir** et la **grande télé** au-dessus (Julien : c'est bien un piano) |
| Ouest | Fauteuil marine ; la **grande ouverture** vers le corridor (cadre blanc) |

- **Divan :** velours côtelé **moutarde**, environ 2,1 × 0,95 m, dos à la salle à manger, face à la télé.
- **Table basse :** rétro, bois, environ 1,0 × 0,55 m, **45 cm**, avec une tablette en dessous.
- **Plafonnier** à trois spots sur sa rosace ; la lampe sur pied de laiton éclaire le coin du divan.
- **Coin de Blanche :** un coussin près du radiateur.

### Ce qui a été retiré pour « en ordre »

Ordinateur, boîtes de mouchoirs, casque d'écoute, couvertures en boule, fils, papiers, bouteilles, objets sur la
table, la lingette et les pots de crayons du buffet. Les céramiques et les disques sont simplifiés en quelques formes
lisibles. Le banc du piano est rangé dessous.

### Vie privée

Les cadres, les affiches et l'écran de la télé montrent des images **fabriquées par script** (paysage, motifs, chien
stylisé, carte du ciel inventée, partie de hockey dessinée). Aucune photo de famille, aucun visage, aucune affiche ni
inscription ne vient des photos.

### Ce qui manque (non bloquant)

- Les dimensions réelles des deux pièces et de la table.
- La moitié sud du salon vue de face (la fenêtre, le piano et la télé ne sont vus que de biais).
- Le corridor et la porte de bois vue du corridor : le chemin de Maman vers la cuisine est imaginé.
