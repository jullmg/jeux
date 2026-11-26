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
const SUSPICION := "Méfiance de Maman"
## La jauge porte le nom de qui surveille.
const SUSPICION_OF := {"maman": "Méfiance de Maman", "papa": "Méfiance de Papa"}
## L'état de la jauge, du plus tranquille au plus méfiant, et ce qui vient de la faire monter.
const WARY_STATES := ["Calme", "Se méfie", "Aux aguets !"]
## « tip » est le conseil donné une fois par mission.
const WARY_WHY := {"food": "Il manque de la bouffe…", "noise": "Elle a entendu !", "caught": "Prise sur le fait !",
	"tip": "Assise dans ton coin, tu la calmes."}
## Le même conseil quand le coin est la cage, ou quand c'est Papa qui surveille.
const WARY_TIPS := {"cage": "Couchée dans ta cage, tu la calmes.", "papa": "Assise dans ton coin, tu le calmes."}
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
const END_TEXT := "Le jambon à l'érable n'a jamais eu de chance.\nToute la famille t'aime quand même. Beaucoup.\n\nÉtoiles : %d sur %d"
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
## Dans la salle à manger, le coin, c'est la cage : la bannière dit parfois ceci.
const DANS_TA_CAGE := "DANS TA CAGE !"
## Au bord de l'écran, du côté de la porte, quand Maman revient de la cuisine.
const COMING_BACK := "J'arrive !"
## Les pièces, pour l'écran des missions.
const ROOMS := {"cuisine": "La cuisine", "salle_a_manger": "La salle à manger", "salon": "Le salon",
	"fetes": "Le party des Fêtes"}
const COMBO := "×%d"
const TREASURE_ALERT := "%s vient d'apparaître !"
const NOISE_ALERT := "Quel vacarme !"
const TICKING := "Le repas est presque prêt !"

const ACTIVITY := {
	"brasser": "brasse la sauce", "four": "surveille le four", "couper": "coupe des légumes", "laver": "lave la vaisselle",
	"frigo": "fouille dans le frigo", "telephone": "jase au téléphone", "ilot": "pétrit sur l'îlot",
	"surprise": "sauve son chaudron", "charlotte": "écoute Charlotte", "chicane": "se chicane avec Papa",
	"servir": "sert à table", "manger": "mange", "buffet": "s'affaire au buffet", "disque": "choisit un disque",
	"cuisine": "est à la cuisine", "hockey": "regarde le hockey", "but": "fête le but !", "film": "regarde le film",
	"jaser": "jase avec la visite",
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
	# La salle à manger : la cage, les allers-retours à la cuisine.
	"caught_cage": ["Blanche ! DANS TA CAGE !", "Eille ! Dans ta cage !", "Ben là ! DANS TA CAGE !",
		"Pas sur la table ! Dans ta cage !", "Je t'ai vue ! DANS TA CAGE !"],
	"scold_cage": ["Pis tu restes couchée, là.", "Ta cage, c'est ta place.", "Franchement… sur la table !",
		"T'es chanceuse d'être cute, toi."],
	"out": ["Je reviens, là.", "Bouge pas, toi.", "Je vais chercher le plat.", "Personne touche à rien !"],
	"retour": ["J'arrive !", "Me v'là !", "Chaud, chaud, chaud !", "Attention, ça sort du four !"],
	"served": ["Et un plat chaud !", "Bon appétit, tout le monde !", "Servez-vous !"],
	"busted": ["Charlotte ! Je t'ai vue !", "Charlotte… on nourrit pas le chien à table !", "Hein ? Charlotte !"],
}
## Papa qui surveille du divan, pendant la game.
const PAPA_WATCH := {
	"intro": ["Bon, la game commence !", "Toi, tu restes tranquille, hein ?", "Go Habs go !"],
	"hint": ["Hein ?", "Bon, une pause pub…", "C'est quoi, ce bruit-là ?", "Hmm ?"],
	"remote": ["Où est la télécommande ?", "Voyons, la manette…", "Elle est où, la zapette ?"],
	"feint": ["Allez, allez !", "Lance !", "Ah ben voyons, l'arbitre !", "Mmm…"],
	"round": ["Blanche ? T'es où ?"],
	"caught": ["Blanche ! AU COIN !", "Eille, toi ! AU COIN !", "Pas les nachos ! AU COIN !", "Je t'ai vue ! AU COIN !"],
	"scold_after": ["Tu me fais manquer la game, là.", "Franchement, Blanche…", "Reste là, astheure.", "Coudonc…"],
	"surprise": ["BUT !", "OUI ! BUT !", "Il l'a mis !"],
	"noise": ["Hein ? Le piano ?", "C'est quoi, ça ?"],
}
## Maman pendant le film : elle chuchote.
const MOM_FILM := {
	"intro": ["Chut, ça commence…", "Toi, tu te couches, hein ?", "On regarde le film, là."],
	"hint": ["Hmm ?", "Chut…", "C'tait quoi, ça ?"],
	"caught": ["Blanche ! AU COIN !", "Psst ! AU COIN !", "Pas le pop-corn ! AU COIN !"],
	"scold_after": ["Pis chut, là.", "On écoute le film.", "Franchement…"],
	"noise": ["Chut ! Le piano !", "C'est quoi, ce bruit ?"],
}
const CHARLOTTE := {
	"in": ["Maman, regarde mon dessin !", "Maman, j'ai faim !", "Maman, c'est quand qu'on mange ?"],
	"snitch": ["Hon !", "Hooon !"],
	"call": ["Maman ! Blanche !", "Mamaaan ! Blanche vole de la bouffe !"],
	"slip": ["Psst… tiens, Blanche !", "Chut… c'est pour toi.", "Hi hi…"],
}
## La chicane quand Papa est dans le chemin : les répliques alternent, Maman d'abord.
const CHICANE := [
	["Tu vois pas que t'es dans mon chemin ?", "Ben là, je fais juste passer !", "T'es planté en plein milieu !",
		"Ok, ok, je me tasse…"],
	["Ôte-toi de d'là, je cuisine !", "Relaxe, je veux juste prendre de quoi.", "Astheure ? En plein souper ?",
		"Ben quoi, j'ai faim, moi !"],
	["Eille, tu me bloques !", "C'est pas moi, c'est la cuisine qui est petite.", "La cuisine est ben correcte !",
		"C'est ça, c'est de ma faute."],
	["T'avais pas d'affaire à passer là !", "Y a rien qu'un chemin, tsé.", "Fais le tour de l'îlot !",
		"Avec un panier de même ?"],
]
## La chicane quand Maman voit Charlotte nourrir la chienne : Maman d'abord.
const CHICANE_CHARLOTTE := [
	["Charlotte ! On nourrit pas le chien à table !", "C'est pas moi, c'est tombé tout seul !", "Tout seul, hein ?",
		"Ben… un peu tout seul."],
	["Je t'ai vue, ma grande !", "Elle me faisait des yeux piteux…", "C'est pas une raison !", "Mais c'est ma fête !"],
	["Charlotte, tes mains sur la table.", "Je faisais rien !", "Rien, avec un morceau de hot-dog ?",
		"Il était trop gros pour moi…"],
]
## La visite : ce qu'elle dit en jasant, quand elle voit Blanche, et quand elle appelle Maman.
const GUESTS := {
	"tante": {"chat": ["Pis, la job ?", "C'est ben bon !", "Ça fait donc ben longtemps !", "Charlotte a grandi !"],
		"snitch": ["Oh !", "Ah ben !"], "call": ["Le chien est sur la table !", "Euh… ta chienne se sert !"]},
	"oncle": {"chat": ["As-tu vu la game hier ?", "Passe-moi le sel.", "Hé, que c'est bon !", "Pis, le char ?"],
		"snitch": ["Hé !", "Ho, ho !"], "call": ["Y a un chien dans la lasagne !", "Ta chienne a faim, là !"]},
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
