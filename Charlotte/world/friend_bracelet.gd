class_name FriendBracelet
extends RefCounted
## Friendship bracelets (Julien, 2026-11-27): she knots one at her desk (`BraceletStudio`) for a friend she has met, keeps it in
## her pocket (`flags.bracelets_a_donner`: {friend: bracelet}) and gives it the next time she clicks that friend (`give`, called
## first thing by `Twins`, `BillieAuguste`, `Alyzee`, `Emilia` and the service de garde). From then on the friend wears it on
## the wrist (`flags.bracelets`, `dress` in each friend's `CharacterLook` constructor: `look.bracelet`). The first friend to get
## one gives her one back (`flags.bracelet_a_moi`), and Charlotte wears it too (`dress_mine`, in `CharacterLook.charlotte()`).
## **A new friend = a line in `FRIENDS`, their `dress` call, their `give` call in their click.**

const PENDING := "bracelets_a_donner"
const GIVEN := "bracelets"
const MINE := "bracelet_a_moi"
const HEADING := "🧵  Bracelet d'amitié"
## id, name, the flag that says she has met them, the line receiving it, the line giving one back, the one they give back.
const FRIENDS := [
	["alphee", "Alphée", "met_twins", "Un bracelet d'amitié ? Pour moi ?\nIl est tellement beau, Chachoue !", "Attends… j'en ai fait un pour toi aussi !\nOn est des amies pour la vie, astheure.", ["#2FB7B0", "#FFFFFF", "#FF7BA3"]],
	["constance", "Constance", "met_twins", "Oh ! Je le mets tout de suite.\nMerci, Chachoue !", "Tiens, c'est moi qui l'ai tressé :\nil est pour toi !", ["#E8C99A", "#7E57C2", "#FFFFFF"]],
	["billie", "Billie", "met_billie_auguste", "Wow ! C'est-tu pour vrai pour moi ?\nMerci ben gros !", "Moi aussi j'en fais, tsé !\nTiens, prends le mien.", ["#BFE3F7", "#FF7BA3", "#FFD23F"]],
	["auguste", "Auguste", "met_billie_auguste", "Un bracelet ! Je vais le garder\nmême pour jouer au ballon !", "J'en ai un pour toi aussi…\nc'est Billie qui m'a aidé.", ["#E04F5F", "#FFFFFF", "#1D4F91"]],
	["alyzee", "Alyzée", "met_alyzee", "Un bracelet d'amitié !\nTu es ma meilleure amie, Chachoue.", "J'en ai fait un pour toi\nà la maison. Tiens !", ["#7E57C2", "#C77DFF", "#2B2B2B"]],
	["emilia", "Emilia", "met_emilia", "¡Qué bonito! Une pulsera de la amistad !\nMerci, amiga !", "Ma abuela m'a montré à en faire.\nTiens, c'est pour toi !", ["#2FB7B0", "#FF8A3D", "#E04F5F", "#FFD23F"]],
]


static func entry(id: String) -> Array:
	for f: Array in FRIENDS:
		if f[0] == id:
			return f
	return []


static func name_of(id: String) -> String:
	var e := entry(id)
	return str(e[1]) if not e.is_empty() else id


## The friends she has met, to make one for.
static func friends() -> Array:
	return FRIENDS.filter(func(f: Array) -> bool: return GameState.flags.get(f[2], false))


static func pending(id: String) -> Dictionary:
	return GameState.flags.get(PENDING, {}).get(id, {})


static func has_pending(ids: Array) -> bool:
	for id: String in ids:
		if not pending(id).is_empty():
			return true
	return false


static func given(id: String) -> Dictionary:
	return GameState.flags.get(GIVEN, {}).get(id, {})


## The bracelet she made is in her pocket, waiting for `id`.
static func make(id: String, data: Dictionary) -> void:
	var p: Dictionary = GameState.flags.get(PENDING, {}).duplicate(true)
	p[id] = data
	GameState.flags[PENDING] = p


## She keeps it herself.
static func keep(data: Dictionary) -> void:
	GameState.flags[MINE] = data.duplicate(true)


## What a friend wears (in their `CharacterLook` constructor).
static func dress(look: CharacterLook, id: String) -> CharacterLook:
	var data := given(id)
	if not data.is_empty():
		look.bracelet = BraceletArt.wrist(data)
	return look


static func dress_mine(look: CharacterLook) -> CharacterLook:
	var data: Dictionary = GameState.flags.get(MINE, {})
	if not data.is_empty():
		look.bracelet = BraceletArt.wrist(data)
	return look


## She gives `friend` (the character `id`) the bracelet she has for them, if any: they put it on, thank her, and the first
## time ever, they give her one back. `say` makes the friend speak a line. Returns false when she has none for them.
static func give(friend: Character, id: String, say: Callable, charlotte: Character) -> bool:
	var data := pending(id)
	if data.is_empty() or friend == null:
		return false
	var p: Dictionary = GameState.flags.get(PENDING, {}).duplicate(true)
	p.erase(id)
	GameState.flags[PENDING] = p
	var g: Dictionary = GameState.flags.get(GIVEN, {}).duplicate(true)
	g[id] = data
	GameState.flags[GIVEN] = g
	friend.look.bracelet = BraceletArt.wrist(data)
	friend.set_look(friend.look)
	friend.express("happy", 3.0)
	Sfx.play("chime")
	var e := entry(id)
	say.call(str(e[3]))
	if GameState.flags.has(MINE):
		return true
	var later := friend.create_tween()
	later.tween_interval(Bubble.reading_time(str(e[3]), 2.0) + 0.4)
	later.tween_callback(func() -> void:
		say.call(str(e[4]))
		GameState.flags[MINE] = {"colors": e[5], "pattern": "rayures", "word": "", "charm": "", "from": id}
		if is_instance_valid(charlotte):
			charlotte.look.bracelet = ",".join(e[5])
			charlotte.set_look(charlotte.look)
			charlotte.express("grin", 2.4)
		Notebook.announce("step", "%s t'a donné un bracelet aussi !" % e[1], HEADING))
	return true


static func clear() -> void:
	for key in [PENDING, GIVEN, MINE]:
		GameState.flags.erase(key)
