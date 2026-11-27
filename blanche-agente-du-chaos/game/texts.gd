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
const SUSPICION_OF := {"maman": "Méfiance de Maman", "papa": "Méfiance de Papa", "charlotte": "Méfiance de Charlotte"}
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
const END_TEXT := "Le jambon à l'érable et le pop-corn de la soirée pyjama n'ont jamais eu de chance.\nToute la famille t'aime quand même. Beaucoup.\n\nÉtoiles : %d sur %d"
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
const CREDITS_TEXT := "Blanche Pronovost agente du Chaos\n\nUne idée de Julien. Avec Blanche, Maman, Papa, Charlotte et son amie Alyzée,\net la visite : ma tante et mon oncle.\n\nModèles, sons et musiques fabriqués par script (Blender et synthèse).\nCode et art réalisés avec Claude.\n\nMoteur : Godot Engine (licence MIT).\nPolice : Fredoka (SIL Open Font License)."
const AU_COIN := "AU COIN !"
## Dans la salle à manger, le coin, c'est la cage : la bannière dit parfois ceci.
const DANS_TA_CAGE := "DANS TA CAGE !"
## Au bord de l'écran, du côté de la porte, quand Maman revient de la cuisine.
const COMING_BACK := "J'arrive !"
## Les pièces, pour l'écran des missions.
const ROOMS := {"cuisine": "La cuisine", "salle_a_manger": "La salle à manger", "salon": "Le salon",
	"fetes": "Le party des Fêtes", "chambre": "La chambre"}
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
	"jaser": "jase avec la visite", "hamster": "nourrit le hamster", "danse": "invente une chorégraphie",
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
	# Le repas est prêt : la partie finit sur un mot.
	"done": ["C'est prêt ! À table !", "Le repas est servi !", "Bon appétit, tout le monde !"],
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
	"done": ["Quelle game !", "Bon, la game est finie…", "Ils ont gagné ! Ou presque."],
}
## Maman pendant le film : elle chuchote.
const MOM_FILM := {
	"intro": ["Chut, ça commence…", "Toi, tu te couches, hein ?", "On regarde le film, là."],
	"hint": ["Hmm ?", "Chut…", "C'tait quoi, ça ?"],
	"caught": ["Blanche ! AU COIN !", "Psst ! AU COIN !", "Pas le pop-corn ! AU COIN !"],
	"scold_after": ["Pis chut, là.", "On écoute le film.", "Franchement…"],
	"noise": ["Chut ! Le piano !", "C'est quoi, ce bruit ?"],
	"done": ["Ah… c'était un beau film.", "Bon, au lit, tout le monde."],
}
## Charlotte qui garde les collations à la soirée pyjama : elle parle comme une grande, ou presque.
const CHARLOTTE_WATCH := {
	"intro": ["Blanche, les collations, c'est pour nous !", "Toi, tu restes sur ton coussin, OK ?",
		"Alyzée, surveille les bonbons avec moi !"],
	"hint": ["Hein ?", "Blanche ?", "Attends… c'tait quoi, ça ?", "Hmm…"],
	"feint": ["Oh, regarde ! Le chat dans le film !", "La la la…", "Hi hi !", "Mmm, des jujubes…"],
	"round": ["Blanche ? T'es où, coquine ?", "Pssst… Blanche ?"],
	"caught": ["Blanche ! AU COIN !", "Hé ! C'est à nous ! AU COIN !", "Pas mes oursons ! AU COIN !",
		"Je t'ai vue ! Sur ton coussin !"],
	"scold_after": ["Pis tu bouges pus, là.", "T'es ben trop cute pour être chicanée…", "Franchement, Blanche !",
		"Fais-moi pas tes yeux piteux."],
	"noise": ["C'est quoi ce bruit-là ?", "Hein ? Le bureau ?"],
	"out": ["Je vais chercher du pop-corn !", "Bouge pas, Blanche !", "Alyzée, surveille-la !"],
	"retour": ["Me v'là !", "Pop-corn tout chaud !", "J'arrive avec le pop-corn !"],
	"served": ["Encore du pop-corn !", "Servez-vous, les filles !", "Une autre canette ?"],
	"done": ["Bonne nuit, Blanche !", "Meilleure soirée pyjama de l'univers !"],
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
	"alyzee": {"chat": ["J'adore ce film !", "Tes oursons sont trop bons !", "On fait une chorégraphie après ?"],
		"snitch": ["Oh !", "Hiii !"], "call": ["Charlotte ! Blanche mange nos jujubes !", "Ta chienne vole le pop-corn !"]},
}
const PAPA := {
	"in": ["Je fais juste passer !", "Chaud devant !", "Tassez-vous, j'ai les bras pleins."],
	"drop": ["Oups…", "J'ai rien vu."],
}

## Les conversations à table (et au party) : chaque réplique est [qui, quoi]. « sur » : le moment ou le plat de la
## mission où elle se dit (vide : à table, dans la salle à manger, à tous les repas). Avec la visite assise, au plus
## trois répliques : elle ne parle que le temps qu'elle jase pour vrai (sa bulle « … »).
const TABLE_TALK := [
	# Papa et Charlotte
	{"sur": [], "lines": [["papa", "Sais-tu pourquoi les poissons vivent dans l'eau salée ?"], ["charlotte", "Non, pourquoi ?"],
		["papa", "Parce que le poivre les fait éternuer !"], ["charlotte", "Papaaa…"]]},
	{"sur": [], "lines": [["charlotte", "Papa, Blanche me fait des yeux piteux."],
		["papa", "C'est une actrice. Donne-lui rien."], ["charlotte", "Elle mérite un Oscar."]]},
	{"sur": [], "lines": [["papa", "Qu'est-ce que t'as appris à l'école ?"], ["charlotte", "Que les escargots dorment trois ans !"],
		["papa", "Chanceux. Moi, je dors trois minutes."]]},
	{"sur": [], "lines": [["charlotte", "Papa, c'est quoi ton superpouvoir ?"], ["papa", "Trouver la télécommande."],
		["charlotte", "Maman dit que c'est pas vrai."]]},
	{"sur": [], "lines": [["papa", "Veux-tu entendre ma blague de banane ?"], ["charlotte", "Non !"],
		["papa", "Tant pis, elle était pas mûre."]]},
	{"sur": [], "lines": [["charlotte", "Alyzée dit que son chat parle."], ["papa", "Ah oui ? Qu'est-ce qu'il dit ?"],
		["charlotte", "Miaou. Mais avec un accent."]]},
	{"sur": [], "lines": [["papa", "Devine qui a fait 30 km de vélo à matin !"], ["charlotte", "Le facteur ?"],
		["papa", "…Oui. Moi, j'en ai fait trois."]]},
	{"sur": [], "lines": [["charlotte", "Blanche peut-tu avoir un petit bout ?"],
		["papa", "Non. Pis arrête de me faire les mêmes yeux qu'elle."]]},
	{"sur": ["pate_chinois"], "lines": [["papa", "Charlotte, mange ton blé d'Inde."], ["charlotte", "C'est un légume, ça ?"],
		["papa", "Euh… Demande à ta mère."]]},
	{"sur": ["hot_dogs", "fete"], "lines": [["papa", "Bonne fête, ma grande !"], ["charlotte", "Je peux avoir deux gâteaux ?"],
		["papa", "Deux pointes, peut-être. Deux gâteaux, non."]]},
	{"sur": ["hot_dogs", "fete"], "lines": [["charlotte", "Papa, tu vas chanter ?"], ["papa", "Je chante juste dans le char."],
		["charlotte", "Faux ! Tu chantes faux dans le char."]]},
	{"sur": ["hot_dogs", "fete"], "lines": [["papa", "Qui veut de la moutarde ?"], ["charlotte", "Moi ! Pis Blanche aussi !"],
		["papa", "Pas de moutarde pour le chien."]]},
	{"sur": ["cafe"], "lines": [["papa", "Écoute ça : un chat élu maire en Alaska !"], ["charlotte", "On peut-tu voter pour Blanche ?"],
		["papa", "Elle promettrait des saucisses à tout le monde."]]},
	{"sur": ["cafe"], "lines": [["charlotte", "Papa, pourquoi tu lis le journal ?"], ["papa", "Pour savoir ce qui se passe."],
		["charlotte", "Il se passe que Blanche te regarde."]]},
	# avec Maman, quand elle est assise
	{"sur": [], "lines": [["charlotte", "Maman, pourquoi Papa est dans la lune ?"], ["maman", "Il pense à son vélo."],
		["papa", "Hein ? Quoi ? Mon vélo ?"]]},
	{"sur": [], "lines": [["papa", "Bon appétit, la famille !"], ["charlotte", "Bon appétit, Blanche !"],
		["maman", "Non. Pas Blanche."]]},
	{"sur": [], "lines": [["maman", "Charlotte, les coudes…"], ["charlotte", "Papa aussi a les coudes sur la table !"],
		["papa", "Moi, c'est mes coudes de fin de semaine."]]},
	{"sur": ["cafe"], "lines": [["maman", "Qui veut encore des œufs ?"], ["papa", "Moi ! Pis du bacon. Pis des rôties."],
		["maman", "Ta diète, elle ?"], ["papa", "Lundi. C'est toujours lundi."]]},
	{"sur": ["cafe"], "lines": [["maman", "Qui a mis du ketchup dans le café ?"], ["papa", "C'était une expérience."],
		["charlotte", "Elle a pas marché."]]},
	{"sur": ["pate_chinois"], "lines": [["papa", "Ton pâté chinois bat celui de ma mère."], ["maman", "Je vais lui dire."],
		["papa", "Non non non ! Dis-lui pas !"]]},
	{"sur": ["pate_chinois"], "lines": [["charlotte", "Pourquoi ça s'appelle pâté chinois ?"], ["maman", "Bonne question…"],
		["papa", "Parce que \"pâté québécois\", c'était déjà pris ?"]]},
	# avec la visite, au souper des invités
	{"sur": ["lasagne"], "lines": [["papa", "Pis, mon oncle, ton char ?"], ["oncle", "Il fait un bruit. Juste quand il roule."],
		["papa", "Ah ben, c'est pas grave, d'abord."]]},
	{"sur": ["lasagne"], "lines": [["oncle", "J'ai pogné un brochet gros de même !"],
		["papa", "La semaine passée, il était gros de même."], ["oncle", "Il a grandi depuis !"]]},
	{"sur": ["lasagne"], "lines": [["papa", "Ma tante, encore un peu de lasagne ?"], ["tante", "Une petite pointe… ben, une moyenne."],
		["papa", "Je te mets une grosse, d'abord."]]},
	{"sur": ["lasagne"], "lines": [["tante", "C'est quoi le secret de ta lasagne ?"], ["papa", "Une recette de famille. Secrète."],
		["tante", "Ben, je suis de la famille !"]]},
	{"sur": ["lasagne"], "lines": [["papa", "Avez-vous vu la game, hier ?"], ["oncle", "Oui ! L'arbitre a besoin de lunettes."],
		["papa", "Des grosses lunettes !"]]},
	{"sur": ["lasagne"], "lines": [["oncle", "Votre chienne me fixe depuis tantôt."], ["papa", "Elle fait ça. Mange vite."],
		["oncle", "J'ai un peu peur, là."]]},
	{"sur": ["lasagne"], "lines": [["papa", "Qu'est-ce qui est jaune et qui attend ?"], ["tante", "Je sais pas, moi."],
		["papa", "Jonathan ! Jaune… attend… Hein ?"]]},
	{"sur": ["lasagne"], "lines": [["oncle", "Passe-moi le pain à l'ail, toi."], ["papa", "Y en reste pus. Le chien, peut-être…"],
		["oncle", "Ben voyons donc !"]]},
	{"sur": ["lasagne"], "lines": [["tante", "Pis, Charlotte, elle aime l'école ?"], ["papa", "Elle aime la récré. C'est un début."]]},
	{"sur": ["lasagne"], "lines": [["tante", "Ton oncle ronfle comme une souffleuse."], ["oncle", "C'est même pas vrai !"],
		["tante", "Les voisins ont appelé la Ville."]]},
	{"sur": ["lasagne"], "lines": [["oncle", "Le vin est bon. C'est quoi ?"], ["papa", "Du rouge."], ["oncle", "Un connaisseur !"]]},
	{"sur": ["lasagne"], "lines": [["papa", "Mon oncle, t'as de la sauce dans la moustache."],
		["oncle", "Je la garde pour plus tard."]]},
	{"sur": ["lasagne"], "lines": [["oncle", "Moi, je suis au régime."], ["tante", "Depuis quand ?"],
		["oncle", "Depuis la deuxième assiette."]]},
	{"sur": ["lasagne"], "lines": [["tante", "Tu me donnerais la recette ?"], ["papa", "Bien sûr. Étape un : demander à ma blonde."]]},
	# au party des Fêtes
	{"sur": ["noel"], "lines": [["papa", "Joyeux Noël, la gang !"], ["oncle", "Joyeux Noël ! Y a-tu du jambon ?"],
		["papa", "Le jambon, c'est pour tantôt. Patience."]]},
	{"sur": ["noel"], "lines": [["tante", "Ton sapin est ben beau cette année !"],
		["papa", "Merci ! Blanche a mangé juste une boule."]]},
	{"sur": ["noel"], "lines": [["oncle", "Je fais mon tour de magie tantôt."], ["papa", "Pas celui où le dessert disparaît ?"],
		["oncle", "C'est mon meilleur !"]]},
	{"sur": ["noel"], "lines": [["tante", "Pis, tu fais du vélo l'hiver ?"], ["papa", "Oui ! Dans le salon. Stationnaire."]]},
	{"sur": ["noel"], "lines": [["papa", "Qui veut chanter « Petit papa Noël » ?"], ["tante", "Moi ! Juste le refrain."],
		["oncle", "Pis moi, juste le silence."]]},
	# à la soirée pyjama, Charlotte et Alyzée
	{"sur": ["pyjama"], "lines": [["alyzee", "Ta chienne nous regarde encore…"], ["charlotte", "Elle fait sa face de chiot piteux."],
		["alyzee", "Ça marche sur moi, là."]]},
	{"sur": ["pyjama"], "lines": [["charlotte", "Mes oursons préférés, c'est les rouges."], ["alyzee", "Moi, les verts !"],
		["charlotte", "Parfait : on se chicanera jamais."]]},
	{"sur": ["pyjama"], "lines": [["alyzee", "As-tu vu le coton ouaté que j'ai ?"], ["charlotte", "Avec les petits oursons ? Trop beau !"],
		["alyzee", "Ma mère dit que c'est mon pyjama de jour."]]},
	{"sur": ["pyjama"], "lines": [["charlotte", "On reste debout jusqu'à minuit ?"], ["alyzee", "Au moins ! Peut-être neuf heures."]]},
	{"sur": ["pyjama"], "lines": [["alyzee", "Ton hamster, il dort toujours ?"], ["charlotte", "Le jour, oui. La nuit, il fait la fête."],
		["alyzee", "Comme nous !"]]},
	{"sur": ["pyjama"], "lines": [["charlotte", "Le méchant du film a l'air d'un raton."], ["alyzee", "Un raton méchant ? Ça existe pas !"],
		["charlotte", "Demande à mes poubelles."]]},
	{"sur": ["pyjama"], "lines": [["alyzee", "Les bubly au pamplemousse, c'est les meilleurs."], ["charlotte", "Ça pique le nez !"],
		["alyzee", "C'est ça qui est bon."]]},
	{"sur": ["pyjama"], "lines": [["charlotte", "Tantôt, on fait des histoires de peur ?"], ["alyzee", "Pas trop peur, OK ?"],
		["charlotte", "Juste un petit peu peur."]]},
	{"sur": ["pyjama"], "lines": [["alyzee", "Ta chambre est tellement belle avec les lumières."],
		["charlotte", "Le cœur rose, c'est ma veilleuse."], ["alyzee", "Je veux le même !"]]},
	{"sur": ["pyjama"], "lines": [["charlotte", "Quand je serai grande, j'aurai dix chiens."], ["alyzee", "Dix Blanche ?"],
		["charlotte", "Euh… peut-être juste une, finalement."]]},
	# pendant le film, tout bas
	{"sur": ["film"], "lines": [["charlotte", "Psst… Papa, c'est-tu lui, le méchant ?"], ["papa", "Chut… Je pense que oui."],
		["charlotte", "Il a l'air gentil, pourtant."]]},
	{"sur": ["film"], "lines": [["papa", "Psst… passe-moi le pop-corn."], ["charlotte", "Y en reste pus."],
		["papa", "Quoi ? Qui l'a mangé ?"]]},
	{"sur": ["film"], "lines": [["charlotte", "Papa, tu dors ?"], ["papa", "Non, non… je repose mes yeux."]]},
	{"sur": ["film"], "lines": [["papa", "Je gage qu'il se fait manger, lui."], ["maman", "Chut ! Pas de divulgâcheur !"]]},
]
## Ce qu'on dit tout seul, entre deux conversations. Clé "" : à table, à tous les repas ; sinon le moment ou le plat
## de la mission.
const TABLE_SOLO := {
	"papa": {
		"": ["Mmm, c'est ben bon !", "Qui a fait ça ? C'est un chef !", "Blanche, arrête de me fixer.",
			"Je pourrais manger ça tous les jours.", "J'ai un petit creux. Un gros, en fait.",
			"Ça, c'est de la bouffe !", "Je reprendrais ben une petite pointe…", "Mes compliments au chef !"],
		"cafe": ["Ah, le brunch du dimanche…", "Il va faire beau toute la semaine !", "Les Canadiens ont gagné ! C'est écrit !",
			"Qui a fini le café ?", "Encore une rôtie, ça se refuse pas."],
		"lasagne": ["Cette lasagne-là mérite une médaille.", "Encore un peu de pain à l'ail ?", "Un autre petit verre ?"],
		"pate_chinois": ["Steak, blé d'Inde, patates : la base !", "Le pâté chinois, c'est le roi des soupers."],
		"hot_dogs": ["Bonne fête, Charlotte !", "Un hot-dog moutarde-relish : un classique."],
		"noel": ["Joyeux Noël, tout le monde !", "Qui a caché les tourtières ?", "Encore un petit verre de lait de poule ?"],
		"film": ["Chut… ça devient bon.", "Oh ! Je l'avais pas vu venir, celle-là."],
	},
	"charlotte": {
		"": ["Blanche, t'es la plus belle chienne du monde.", "J'ai fini ! Y a-tu du dessert ?", "Miam !",
			"Je mange même mes croûtes !"],
		"fete": ["C'est ma fête ! C'est ma fête !", "Je veux des bougies qui se rallument !"],
		"film": ["J'ai un peu peur…", "Oh ! Il est trop mignon !"],
		"pyjama": ["Meilleure soirée pyjama de l'univers !", "Encore un ourson…", "Chut… c'est la meilleure partie !"],
		"noel": ["Le père Noël va-tu passer ?", "J'ai hâte d'ouvrir mes cadeaux !", "Joyeux Noël, Blanche !"],
	},
	"maman": {"": ["Mangez pendant que c'est chaud !", "Ah, enfin assise !", "C'est bon, hein ?"],
		"noel": ["Joyeux Noël, tout le monde !", "Qui veut du sucre à la crème ?", "Ah, que c'est beau, un sapin !"]},
	"alyzee": {"pyjama": ["Trop bon, ce pop-corn !", "Oh ! Le chat a retrouvé sa maison !", "Hi hi hi !",
		"J'ai les doigts tout collants."]},
	"tante": {"": ["C'est ben bon !", "Ça fait donc ben longtemps !", "Charlotte a grandi !", "J'aime ta nouvelle déco !"]},
	"oncle": {"": ["Passe-moi le sel.", "Hé, que c'est bon !", "Pis, la job ?", "Y a-tu encore du vin ?"]},
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
