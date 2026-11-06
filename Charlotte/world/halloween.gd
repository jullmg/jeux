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
const BAG := "candy_bag"
## What the neighbours hand out.
const KINDS := ["wrapped", "lollipop", "chocolate", "gum", "chips"]
const KIND_NAMES := {"wrapped": "Bonbons", "lollipop": "Suçons", "chocolate": "Chocolats", "gum": "Gommes", "chips": "Petits sacs de chips"}
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


## Adds `n` sweets to her bag, each of a kind picked at the door.
static func add_candy(n: int) -> void:
	GameState.flags[CANDY] = candy() + n
	var bag: Array = GameState.flags.get(BAG, [])
	for i in n:
		bag.append(KINDS[randi() % KINDS.size()])
	GameState.flags[BAG] = bag


## How many of each kind she has, for the counting on the kitchen table.
static func counted() -> Dictionary:
	var counts := {}
	for kind: String in GameState.flags.get(BAG, []):
		counts[kind] = int(counts.get(kind, 0)) + 1
	# An old save (or the debug menu) may have a total without the bag: spread it over the kinds.
	var listed := 0
	for k in counts:
		listed += int(counts[k])
	if listed < candy():
		counts[KINDS[0]] = int(counts.get(KINDS[0], 0)) + candy() - listed
	return counts


## Everything of the evening is put away (the morning after).
static func pack_away() -> void:
	for key in [STEP, CANDY, BAG, "halloween_doors"]:
		GameState.flags.erase(key)


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
