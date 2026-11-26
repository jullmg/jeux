class_name Cinema
extends RefCounted
## The movie night with the twins (quest "cinema", in winter after Halloween), step by step:
##   1. the twins asked her in the lane (`Twins._ask_for_movie`): she asks Maman for pocket money;
##   2. Maman gave her 5 $ (`house.gd _talk_to_mom`): she buys a bag of chips and some candy at a dépanneur (`Shop._buy_chips`,
##      `_buy_candy`), which go in a paper bag in her arms (`Carry` "snacks");
##   3. she has both: the twins wait for her at home, in front of the hallway TV (`house.gd _build_movie_night`), and the
##      film plays (`TvShows` "film") with the three of them on the cushions.
## The step is `GameState.flags.cinema_step`, what she has bought `flags.cinema_snacks`.
## Once the quest is done she can ask Maman for another one whenever she likes (Julien): `start_again` (flag
## `cinema_again`) runs the same evening from step 2 (Maman's 5 $), and in front of the TV she picks the film (`FILMS`).

const QUEST := "cinema"
const STEP := "cinema_step"
const SNACKS := "cinema_snacks"
## What she must buy for the evening.
const NEEDS := ["chips", "candy"]
## What the notes of its steps are headed with (Notebook.announce).
const HEADING := "🍿  Soirée cinéma"
## Maman's pocket money for it.
const MONEY := 5.0
const AGAIN := "cinema_again"
## The films she can choose from on any movie night (TvShows ids), the first one included.
## Who she can invite (Julien, 2026-11-23: any of her friends, ticked one by one): [look id, name, the flag of having met them].
## The first night is always with the twins who suggested it; later she ticks up to `MAX_GUESTS` (`choose_guests`).
const FRIENDS := [
	["alphee", "Alphée", "met_twins"],
	["constance", "Constance", "met_twins"],
	["billie", "Billie", "met_billie_auguste"],
	["auguste", "Auguste", "met_billie_auguste"],
	["alyzee", "Alyzée", "met_alyzee"],
	["emilia", "Emilia", "met_emilia"],
]
## How many friends fit on the blanket: all six of them (Julien, 2026-11-25), seven on the cushions with her.
const MAX_GUESTS := 6
const GUESTS := "cinema_guests"
const TWINS: Array = ["alphee", "constance"]


## The friends she has met, among those who can come: [id, name].
static func friends() -> Array:
	var out: Array = []
	for f: Array in FRIENDS:
		if bool(GameState.flags.get(f[2], false)):
			out.append([f[0], f[1]])
	if out.is_empty():
		out = [[FRIENDS[0][0], FRIENDS[0][1]], [FRIENDS[1][0], FRIENDS[1][1]]]
	return out


## Who is coming tonight: the look ids she ticked (the twins by default).
static func guests() -> Array:
	var ids: Array = GameState.flags.get(GUESTS, [])
	return ids if not ids.is_empty() else TWINS


static func choose_guests(ids: Array) -> void:
	GameState.flags[GUESTS] = ids.slice(0, MAX_GUESTS)


static func _name_of(id: String) -> String:
	for f: Array in FRIENDS:
		if f[0] == id:
			return str(f[1])
	return id


## "Alphée et Constance", "Billie, Constance et Alyzée"…
static func names() -> String:
	var list: Array = []
	for id in guests():
		list.append(_name_of(str(id)))
	if list.size() == 1:
		return str(list[0])
	return ", ".join(list.slice(0, list.size() - 1)) + " et " + str(list[list.size() - 1])


static func plural() -> bool:
	return guests().size() > 1


static func look(id: String) -> CharacterLook:
	match id:
		"alphee":
			return CharacterLook.alphee()
		"constance":
			return CharacterLook.constance()
		"billie":
			return CharacterLook.billie()
		"auguste":
			return CharacterLook.auguste()
		"emilia":
			return CharacterLook.emilia()
	return CharacterLook.alyzee()


const FILMS: Array[String] = ["film", "grinch", "maison", "ratatouille", "reine", "lion", "nemo", "up", "totoro"]


## 0 = not started (or done), else the step she is on (1 for a quest switched on by the debug menu).
static func step() -> int:
	return int(GameState.flags.get(STEP, 1)) if Quests.active(QUEST) or again() else 0


## A movie night she asked Maman for, after the quest.
static func again() -> bool:
	return bool(GameState.flags.get(AGAIN, false))


## Maman may organise one: the quest is done and no evening is on.
static func can_ask() -> bool:
	return Quests.done(QUEST) and step() == 0


## Another movie night: Maman gives the pocket money, the friends she chose are invited (step 2).
static func start_again() -> void:
	GameState.flags[AGAIN] = true
	GameState.flags.erase(SNACKS)
	set_step(2)


static func set_step(n: int) -> void:
	GameState.flags[STEP] = n


## She still has to buy `kind` ("chips" or "candy") for the evening.
static func needs(kind: String) -> bool:
	return step() == 2 and not (GameState.flags.get(SNACKS, []) as Array).has(kind)


## She bought `kind`; true once she has everything (and the step moves on).
static func bought(kind: String) -> bool:
	var got: Array = GameState.flags.get(SNACKS, [])
	if not got.has(kind):
		got.append(kind)
	GameState.flags[SNACKS] = got
	for need: String in NEEDS:
		if not got.has(need):
			return false
	set_step(3)
	return true


## The evening is over: forget the steps.
static func clear() -> void:
	GameState.flags.erase(STEP)
	GameState.flags.erase(SNACKS)
	GameState.flags.erase(AGAIN)
	GameState.flags.erase(GUESTS)


## What the notebook says to do next.
static func hint() -> String:
	match step():
		1:
			return "Pour les grignotines, il faut des sous : va en demander à Maman, dans la cuisine."
		2:
			var left: Array = NEEDS.filter(func(k: String) -> bool: return needs(k))
			var words := {"chips": "un sac de chips", "candy": "des bonbons"}
			return "Achète %s au dépanneur (Xin-Xin, sur Dandurand, ou Oh Bon!, sur Holt)." % " et ".join(left.map(func(k: String) -> String: return words[k]))
		3:
			return "Tu as les grignotines ! Rentre à la maison : %s %s devant la télé du corridor." % [names(), "t'attendent" if plural() else "t'attend"]
	return str(Quests.ALL[QUEST].hint)
