class_name Texts
extends RefCounted
## Tout le texte du jeu, en français du Québec. Les répliques ont plusieurs variantes.

const TITLE := "Blanche Pronovost"
const SUBTITLE := "agente du Chaos"
const TAGLINE := "Maman cuisine. Le comptoir est plein. Reste sage… ou pas."

const PLAY := "Jouer"
const CONTINUE := "Continuer"
const LEVELS := "Les missions"
const OPTIONS := "Options"
const CREDITS := "Crédits"
const QUIT := "Quitter"
const BACK := "Retour"
const START := "C'est parti !"
const RESUME := "Reprendre"
const RETRY := "Recommencer"
const NEXT := "Mission suivante"
const MENU := "Menu principal"
const PAUSE := "Pause"
const LOCKED := "À débloquer"
const MISSION := "Mission %d"
const NEW := "Nouveauté — %s"
const BEST := "Record : %d"
const SCORE := "Score"
const NEXT_STAR := "Prochaine étoile : %d"
const ALL_STARS := "Trois étoiles !"
const SUSPICION := "Soupçon"
const HIDDEN := "Cachée"
const VISIBLE := "Visible"
const GRAB := "Attraper"
const DROP := "Lâcher"
const LET_GO := "Relâche !"
const KEY_HINTS := {"clavier": "Espace", "manette": "Bouton A", "pointeur": "Maintiens"}
const DROP_NOW := "Lâche !"
const COMBO_LOST := "Combo perdu"
const SEE_END := "Revoir la fin"
const WON := "Mission réussie !"
const LOST := "Le repas est servi…"
const LOST_TEXT := "Il manque %d points pour la première étoile."
const NEW_RECORD := "Nouveau record !"
const STATS := "Miettes : %d    Petits : %d    Gros : %d    Trésors : %d    Au coin : %d"
const END_TITLE := "Agente du Chaos, mission accomplie !"
const END_TEXT := "La dinde n'a jamais eu de chance.\nMaman t'aime quand même. Beaucoup.\n\nÉtoiles : %d sur %d"
const ERASE := "Effacer la progression"
const ERASE_CONFIRM := "Vraiment tout effacer ?"
const YES := "Oui, effacer"
const NO := "Non"
const MUSIC_VOLUME := "Musique"
const SFX_VOLUME := "Bruitages"
const FULLSCREEN := "Plein écran"
const REDUCED_MOTION := "Mouvements réduits"
const LONG_HINTS := "Indices plus longs"
const ON := "Oui"
const OFF := "Non"
const CONTROLS_TEXT := "Se déplacer : flèches ou WASD · manette : stick ou croix · souris ou doigt : toucher le plancher\nAttraper : maintenir Espace · manette : A · bouton à l'écran\nLâcher ce qu'on a dans la gueule : appuyer de nouveau\nPause : Échap · manette : Start"
const CREDITS_TEXT := "Blanche Pronovost agente du Chaos\n\nUne idée de Julien. Avec Blanche, Maman, Papa et Charlotte.\n\nModèles, sons et musiques fabriqués par script (Blender et synthèse).\nCode et art réalisés avec Claude.\n\nMoteur : Godot Engine (licence MIT).\nPolice : Fredoka (SIL Open Font License)."
const AU_COIN := "AU COIN !"
const COMBO := "×%d"
const TREASURE_ALERT := "%s vient d'apparaître !"
const NOISE_ALERT := "Quel vacarme !"
const TICKING := "Le repas est presque prêt !"

const ACTIVITY := {
	"brasser": "brasse la sauce", "four": "surveille le four", "couper": "coupe des légumes", "laver": "lave la vaisselle",
	"frigo": "fouille dans le frigo", "telephone": "jase au téléphone", "ilot": "pétrit sur l'îlot",
	"surprise": "sauve son chaudron", "charlotte": "écoute Charlotte",
}

const MOM := {
	"intro": ["Toi, tu bouges pas de ton coin, hein ?", "Je cuisine. Sois fine.", "Blanche, je te surveille.",
		"Reste couchée, ma belle."],
	"hint": ["Hmm ?", "Hein ?", "C'tait quoi, ça ?", "Coudonc…"],
	"feint": ["La la la…", "Où j'ai mis le sel ?", "Mmm…", "Bon…"],
	"round": ["Est où, elle, là ?", "Blanche ? T'es où, là ?", "C'est ben tranquille…"],
	"caught": ["Blanche ! AU COIN !", "Eille ! AU COIN !", "Ben là ! AU COIN !", "Je t'ai vue ! AU COIN !",
		"Pas touche ! AU COIN !", "Tannante ! AU COIN !"],
	"scold_after": ["Astheure, tu restes là.", "Pfff… Franchement.", "Qu'est-ce qu'on va faire avec toi ?",
		"Fais-moi pas ces yeux-là.", "T'es chanceuse d'être cute."],
	"surprise": ["Mon chaudron !", "La minuterie !", "Ça déborde !"],
	"noise": ["C'est quoi ce bruit-là ?", "Qu'est-ce qui tombe ?"],
	"distract": ["Oui, ma grande ?", "Montre-moi ça !", "Ah, c'est ben beau !"],
}
const CHARLOTTE := {
	"in": ["Maman, regarde mon dessin !", "Maman, j'ai faim !", "Maman, c'est quand qu'on mange ?"],
	"snitch": ["Hon !", "Hooon !"],
	"call": ["Maman ! Blanche !", "Mamaaan ! Blanche vole de la bouffe !"],
}
const PAPA := {
	"in": ["Je fais juste passer !", "Chaud devant !", "Tassez-vous, j'ai les bras pleins."],
	"drop": ["Oups…", "J'ai rien vu."],
}

const TUTORIAL := {
	"leave": "Sors de ton coin : flèches (ou touche le plancher) pour aller près d'un comptoir.",
	"approach": "Approche-toi d'un morceau de nourriture sur le comptoir.",
	"hold": "Maintiens Espace (ou le gros bouton) pour attraper.",
	"keep": "Garde le bouton enfoncé jusqu'au bout !",
	"eat": "Tu mâches… Les points comptent quand c'est avalé.",
	"warning": "Maman se retourne : redescends et aie l'air sage !",
	"drop": "La gueule pleine ! Appuie encore pour lâcher, ou file derrière l'îlot !",
	"safe": "Bien cachée ! Ne bouge pas.",
	"corner": "Au coin ! Tu repars dans un petit instant.",
	"good": "Bravo ! Remplis ton score avant que le repas soit prêt.",
}


static func pick(list: Array, rng: RandomNumberGenerator) -> String:
	return list[rng.randi_range(0, list.size() - 1)]
