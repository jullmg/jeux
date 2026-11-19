class_name Party
extends RefCounted
## Alyzée's birthday party (quest "fete", after "ecole"; Julien), step by step:
##   1. Maman found the invitation in her school bag (`house.gd _invitation`): she waits at the front door to take her to
##      Rue Masson, since at seven Charlotte may not go there alone;
##   2. the Jean Coutu (`jean_coutu.gd`, Maman with her): she picks a present at the "Idées cadeaux" stand (`GIFTS`), Maman
##      pays at the till, the cashier wraps it (`Carry` "gift"), and Maman takes her straight to Alyzée's;
##   3. the party (`scenes/fete_alyzee.gd`): she gives her present, pins the unicorn's horn blindfolded, breaks the piñata,
##      sings over the cake, nibbles at the table, watches a film on the sofa; then Maman comes for her with a goody bag.
## The step is `GameState.flags.fete_step`, the present she chose `flags.fete_gift`.

const QUEST := "fete"
const STEP := "fete_step"
const GIFT := "fete_gift"
const HEADING := "🎂  La fête d'Alyzée"
const COUTU := "res://scenes/jean_coutu.tscn"
const PARTY := "res://scenes/fete_alyzee.tscn"
const HOME := "res://scenes/house.tscn"
## Where the Jean Coutu's door is on Masson (the shop's way out after the party isn't through it: Maman drives them).
const COUTU_X := 300.0
## The presents at the stand: id, what the card says, a little line under it, and what Alyzée says opening it.
const GIFTS := [
	["licorne", "Une licorne en peluche", "toute douce, mauve", "Une licorne ! Elle est mauve comme ma robe !\nJe vais dormir avec à soir !"],
	["bricolage", "Une trousse de bricolage", "des brillants, des pompons pis de la colle", "Wow ! Des brillants ! On va bricoler ensemble\nau service de garde, OK ?"],
	["casse_tete", "Un casse-tête de minous", "cent morceaux", "Des minous ! Chu folle des chats !\nJe vais le faire avec mon papa."],
	["vernis", "Du vernis à ongles", "trois couleurs qui brillent", "Des brillants pour les ongles !\nOn se les fait tout de suite ?"],
]


## 0 = not started (or done), else the step she is on (1 for a quest switched on by the debug menu).
static func step() -> int:
	return int(GameState.flags.get(STEP, 1)) if Quests.active(QUEST) else 0


static func set_step(n: int) -> void:
	GameState.flags[STEP] = n


static func gift() -> Array:
	var id: String = GameState.flags.get(GIFT, "")
	for g: Array in GIFTS:
		if g[0] == id:
			return g
	return GIFTS[0]


static func clear() -> void:
	GameState.flags.erase(STEP)
	GameState.flags.erase(GIFT)


## What the notebook says to do next.
static func hint() -> String:
	match step():
		1:
			return "Maman t'attend à la porte d'en avant, dans le vestibule : vous allez acheter un cadeau pour Alyzée au Jean Coutu, sur la rue Masson."
		2:
			if Carry.has("gift"):
				return "Le cadeau est emballé ! Maman t'amène chez Alyzée."
			if GameState.flags.has(GIFT):
				return "Va payer à la caisse avec Maman."
			return "Choisis un cadeau pour Alyzée au présentoir « Idées cadeaux », à côté des caisses du Jean Coutu."
		3:
			return "C'est la fête chez Alyzée ! Donne-lui ton cadeau, joue avec les amis, mange du gâteau… pis il y a un film !"
	return str(Quests.ALL[QUEST].hint)
