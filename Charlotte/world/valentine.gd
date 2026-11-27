class_name Valentine
extends RefCounted
## Saint-Valentin (quest "valentin", winter, after the sledding with Papa; Julien: "une dernière mission, une mission
## Saint-Valentin. Et après la mission, Charlotte va se coucher et après c'est le printemps"), step by step (`flags.valentin_step`):
##   1. Maman tells her it is Valentine's Day tomorrow: at her desk she makes a valentine, a paper heart on a lace doily, in the
##      craft studio (`CraftArt` base "valentin", `who` "amis"); it is copied for each friend and for Maman and Papa
##      (`valentin.png` in the slot);
##   2. she gives one to each friend she has met (`give`, called first thing when she clicks them, like the bracelets), who
##      thank her and slip her a candy heart in return (to her stash); `flags.valentin_donnes` lists who has had one;
##   3. at home, one to Maman and one to Papa (`house.gd _valentine_to`): a hug each, then they give her a heart of chocolates;
##   4. bedtime: "Bonne nuit… pis bonne Saint-Valentin !", then "Quelques semaines plus tard… c'est le printemps !": the quest
##      is done and the season turns to spring (`house.gd _go_to_sleep`).

const QUEST := "valentin"
const STEP := "valentin_step"
const GIVEN := "valentin_donnes"
const HEADING := "💌  La Saint-Valentin"
## What each friend says getting hers, and where she finds them (for the notebook).
const THANKS := {
	"alphee": ["Un valentin ! Il est trop beau, Chachoue !\nTiens, un bonbon en cœur pour toi.", "dans la ruelle"],
	"constance": ["Oh, c'est toi qui l'as fait ? Je l'adore !\nBonne Saint-Valentin !", "dans la ruelle"],
	"billie": ["Wow, un valentin juste pour moi !\nTiens, j'ai un bonbon pour toi.", "dans la ruelle"],
	"auguste": ["Un cœur ! Euh… merci, Chachoue.\nT'es ma meilleure amie… après Billie.", "dans la ruelle"],
	"alyzee": ["Un valentin ! Je vais le coller\ndans mon pupitre. Merci, Chachoue !", "à l'école"],
	"emilia": ["¡Feliz día del amor y la amistad!\nC'est comme ça qu'on dit chez nous.", "à l'école"],
}


static func step() -> int:
	return int(GameState.flags.get(STEP, 1)) if Quests.active(QUEST) else 0


static func set_step(n: int) -> void:
	GameState.flags[STEP] = n


## Maman can tell her: winter, the quest free.
static func can_start() -> bool:
	return Season.is_winter() and Quests.available(QUEST)


static func card_path() -> String:
	return GameState.slot_dir() + "/valentin.png"


static func card() -> Texture2D:
	if not FileAccess.file_exists(card_path()):
		return null
	var img := Image.load_from_file(card_path())
	if img == null:
		return null
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


## The friends she has met: each gets a valentine.
static func friends() -> Array:
	return FriendBracelet.friends().map(func(f: Array) -> String: return str(f[0]))


static func given() -> Array:
	return GameState.flags.get(GIVEN, [])


static func friends_left() -> Array:
	return friends().filter(func(id: String) -> bool: return id not in given())


static func parents_left() -> Array:
	return ["maman", "papa"].filter(func(id: String) -> bool: return id not in given())


static func mark(id: String) -> void:
	var g: Array = given().duplicate()
	if id not in g:
		g.append(id)
	GameState.flags[GIVEN] = g


## Hands `friend` (the character `id`) a valentine, if she has one for them today. `say` makes them speak.
static func give(friend: Character, id: String, say: Callable) -> bool:
	if step() != 2 or id not in friends() or id in given() or friend == null:
		return false
	mark(id)
	friend.express("happy", 3.0)
	Sfx.play("chime")
	say.call(str(THANKS.get(id, ["Merci, Chachoue !"])[0]))
	Stash.add("wrapped")
	if friends_left().is_empty():
		set_step(3)
		Notebook.announce("step", "Tous tes amis ont leur valentin ! Rentre en donner à Maman pis à Papa.", HEADING)
	else:
		Notebook.announce("step", "Valentin donné à %s ! (%d sur %d)" % [FriendBracelet.name_of(id), given().size(), friends().size()], HEADING)
	return true


static func clear() -> void:
	GameState.flags.erase(STEP)
	GameState.flags.erase(GIVEN)
	if FileAccess.file_exists(card_path()):
		DirAccess.remove_absolute(card_path())


static func hint() -> String:
	match step():
		1:
			return "Fabrique ton valentin à ton bureau, dans ta chambre : il y en aura un pour chacun de tes amis !"
		2:
			var who: Array = friends_left().map(func(id: String) -> String: return "%s (%s)" % [FriendBracelet.name_of(id), THANKS.get(id, ["", "?"])[1]])
			return "Donne un valentin à chacun de tes amis : %s." % ", ".join(who)
		3:
			return "Rentre à la maison donner tes valentins à %s." % " pis à ".join(parents_left().map(func(id: String) -> String: return "Maman" if id == "maman" else "Papa"))
		4:
			return "Quelle belle Saint-Valentin ! Va te coucher dans ton lit, ma chouette."
	return str(Quests.ALL[QUEST].hint)
