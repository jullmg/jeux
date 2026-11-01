class_name Quests
extends RefCounted
## The quest catalogue and the rules around it. Several quests can be on at once; a quest can wait for another
## (`after`) and for Charlotte to be old enough (`age`). Their state lives in GameState.quests (saved):
## not there = still to discover, "active" = in her notebook, "done" = a star. The Notebook autoload shows
## them, and announces each new and finished one.

const ORDER := ["milk", "hamster", "menage", "plants", "cat", "cat2", "cat3"]
const ALL := {
	"milk": {
		"title": "Maman a besoin de lait : va au dépanneur",
		"hint": "Le dépanneur Xin-Xin est au coin de Dandurand. Rapporte le lait à Maman.",
		"find": "Maman a peut-être besoin de quelque chose…",
		"age": 7, "reward": 1.0,
	},
	"hamster": {
		"title": "Nourris le hamster avant le dodo",
		"hint": "Sa gamelle est dans le terrarium, sur la commode de ta chambre.",
		"find": "Papa a quelque chose à te rappeler…",
		"age": 7, "reward": 0.5,
	},
	"menage": {
		"title": "Range ta chambre",
		"hint": "Ramasse les jouets et les vêtements qui traînent par terre dans ta chambre.",
		"find": "Maman trouve que ta chambre est un peu en désordre…",
		"age": 7, "reward": 1.0,
	},
	"plants": {
		"title": "Arrose les plantes",
		"hint": "L'arrosoir est dans la cuisine. Une plante au salon, une dans le corridor, une dans ta chambre.",
		"find": "Les plantes de la maison ont l'air d'avoir soif…",
		"age": 7, "reward": 1.0,
	},
	"cat": {
		"title": "Retrouve le chat perdu du voisin",
		"hint": "Pistache, un chat gris tigré au collier bleu, a été vu sur la rue Dandurand. Ramène-le au 5684, 6e Avenue (Mme Gagnon).",
		"find": "Une affiche est collée sur un poteau de la 6e Avenue…",
		"age": 7, "reward": 1.0,
	},
	"cat2": {
		"title": "Retrouve Caramel, le chat de M. Tremblay",
		"hint": "Un chat roux au collier rouge. Il se cache peut-être dans la ruelle. Ramène-le au 5679, 5e Avenue.",
		"find": "Une autre affiche, sur la 5e Avenue…",
		"age": 7, "after": "cat", "reward": 1.0,
	},
	"cat3": {
		"title": "Retrouve Bijou, la chatte de Mme Nguyen",
		"hint": "Une chatte calico au collier rose, vue près de la ruelle verte. Ramène-la au 2655, rue Holt.",
		"find": "Encore une affiche, sur la rue Holt…",
		"age": 7, "after": "cat2", "reward": 1.5,
	},
}


## "" (not started), "active" or "done".
static func status(id: String) -> String:
	return str(GameState.quests.get(id, ""))


static func active(id: String) -> bool:
	return status(id) == "active"


static func done(id: String) -> bool:
	return status(id) == "done"


## Not started yet, but Charlotte is old enough and what it waits for is done: someone can give it to her.
static func available(id: String) -> bool:
	var quest: Dictionary = ALL[id]
	return status(id) == "" and GameState.age >= int(quest.age) and (not quest.has("after") or done(quest.after))


## Puts the quest in her notebook. Returns false if it can't start (already started, or not available).
static func start(id: String) -> bool:
	if not available(id):
		return false
	GameState.quests[id] = "active"
	_announce("start", id)
	return true


## Gives her the star and the reward. Returns false if the quest wasn't active.
static func complete(id: String) -> bool:
	if not active(id):
		return false
	GameState.quests[id] = "done"
	GameState.money += float(ALL[id].reward)
	_announce("done", id)
	return true


static func stars() -> int:
	return ORDER.filter(func(id: String) -> bool: return done(id)).size()


## "1,50 $": money the Québec way.
static func money_text(amount: float) -> String:
	return ("%.2f $" % amount).replace(".", ",")


# The Notebook autoload, found by name so this class also works where autoloads aren't loaded (test scripts).
static func _announce(what: String, id: String) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	var notebook := tree.root.get_node_or_null("Notebook") if tree else null
	if notebook:
		notebook.announce(what, id)
