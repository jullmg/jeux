class_name Halloween
extends RefCounted
## The Halloween evening, the long quest that opens once every other quest is done. It runs in three steps, kept in
## `GameState.flags.halloween_step`:
##   1. get dressed up — the drawers of her bedroom dresser open on the costumes (`CostumeArt`);
##   2. go trick-or-treating — the four streets at nightfall, candy at the doors that are lit and decorated;
##   3. come home, count what she got and go to bed. The night she wakes from is the first of winter.
## Everything about the evening is asked here: whether it is night out (`night()`), how much candy she has (`candy()`),
## which doors give (`StreetScene._build_halloween`), and what the notebook should tell her to do next (`hint()`).

const QUEST := "halloween"
const STEP := "halloween_step"
const CANDY := "candy"
## How many houses she must do before she can call it a night.
const ENOUGH := 12

const HINTS := {
	1: "Va te déguiser ! Ouvre les tiroirs de ta commode, dans ta chambre.",
	2: "Sonne aux portes allumées et décorées de la 6e, de la 5e, de Holt et de Dandurand. Les maisons éteintes dorment déjà !",
	3: "Rentre à la maison avec tes bonbons, compte-les, et va te coucher.",
}


## Which step she is on (0 = the quest has not started).
static func step() -> int:
	return int(GameState.flags.get(STEP, 0)) if Quests.status(QUEST) != "" else 0


static func set_step(n: int) -> void:
	GameState.flags[STEP] = n


## True while the evening is on: the streets are dark, the decorations lit, the other children out.
static func night() -> bool:
	return Quests.active(QUEST) and step() >= 2


static func candy() -> int:
	return int(GameState.flags.get(CANDY, 0))


static func add_candy(n: int) -> void:
	GameState.flags[CANDY] = candy() + n


## The doors she has already knocked at, so each house gives only once ("<street>:<x>").
static func knocked() -> Array:
	return GameState.flags.get("halloween_doors", [])


static func knock(key: String) -> void:
	var done: Array = knocked()
	if not done.has(key):
		done.append(key)
	GameState.flags["halloween_doors"] = done


static func enough() -> bool:
	return knocked().size() >= ENOUGH


## What her notebook tells her to do next.
static func hint() -> String:
	return str(HINTS.get(step(), HINTS[1]))


## Every other quest is done: Maman can tell her it is Halloween tonight.
static func ready() -> bool:
	for id: String in Quests.ORDER:
		if id != QUEST and not Quests.done(id):
			return false
	return true


## She is dressed up and can go out.
static func dressed(who: Character) -> bool:
	return who != null and who.look != null and who.look.costume != ""
