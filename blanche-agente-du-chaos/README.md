# Blanche Pronovost agente du Chaos

Maman cuisine, le comptoir est plein, et Blanche est dans son coin… pour l'instant. Attrape de la nourriture quand
Maman a le dos tourné. Si elle te prend en flagrant délit : **AU COIN !**

Un jeu 3D pour Mac (Godot 4.7, modèles Blender), de 9 à 99 ans. Huit missions, une par repas.

## Jouer

Ouvrir `build/Blanche Pronovost agente du Chaos.app` (après `tools/export.sh`), ou depuis les sources :

```sh
/Applications/Godot.app/Contents/MacOS/Godot --path .
```

L'application n'est pas notariée par Apple (il faudrait un compte développeur). Construite sur ce Mac, elle s'ouvre
normalement. Copiée sur un autre Mac, macOS la bloque la première fois : l'ouvrir, puis aller dans **Réglages Système →
Confidentialité et sécurité → Ouvrir quand même**.

| Action | Clavier | Manette | Souris ou doigt |
|---|---|---|---|
| Se déplacer | flèches ou WASD | stick ou croix | toucher le plancher ou un morceau |
| Attraper | maintenir Espace (ou Entrée) | maintenir A | maintenir le gros bouton |
| Lâcher | appuyer de nouveau | A | le gros bouton |
| Pause | Échap ou P | Start | bouton en haut à droite |

### Comment on gagne

- Un morceau attrapé ne compte qu'une fois **avalé**. Les gros prennent plus de temps et valent plus.
- Quand le **« ! »** apparaît, il faut être redescendue (et la gueule vide, ou cachée) avant qu'elle regarde.
- Le **« ? »** gris est une fausse alerte.
- **Derrière l'îlot**, au sol, on n'est pas vue. Les pattes en l'air, on dépasse toujours.
- Trois prises de suite doublent les points, six les triplent.
- Pas de vies : la punition, c'est le temps perdu au coin.
- La **méfiance de Maman** monte quand la nourriture disparaît ou qu'on fait du bruit : elle laisse alors moins de
  temps. Assise dans son coin, Blanche la calme.
- Quand **Papa** est dans le chemin, ils se chicanent : c'est le temps d'en profiter.

Options : volumes, plein écran, mouvements réduits, **indices plus longs** (un quart de seconde de plus).

## Développer

```sh
tools/test.sh              # tous les tests (quelques minutes)
tools/test.sh --complet    # équilibrage avec 1000 parties de robots par niveau et par profil (long)
tools/build_art.sh         # régénère les modèles 3D (Blender)
tools/build_audio.sh       # régénère les sons et les musiques
tools/shots.sh DOSSIER     # captures d'écran (fenêtre muette, en arrière-plan, écran du MacBook)
tools/export.sh            # application macOS dans build/, testée
```

Il faut Godot 4.7.2 (avec ses modèles d'exportation macOS) et Blender 5.3. Les détails techniques sont dans
[CLAUDE.md](CLAUDE.md), l'état du projet dans [docs/etat.md](docs/etat.md).

## Remplacer la musique

Déposer `menu`, `jeu` ou `tension` (`.ogg`, `.mp3` ou `.wav`) dans `audio/music/`. Les pistes `jeu` et `tension` jouent
ensemble : la seconde monte avec la méfiance de Maman, elles doivent donc avoir le même tempo et la même durée.
