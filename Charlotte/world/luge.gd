class_name Luge
extends RefCounted
## Sledding with Papa on the small mountain of the Parc du Pélican (quest "luge", winter, after her birthday; Julien):
##   1. Papa asks her (his click, once the quest is open): "on va glisser au parc du Pélican, j'ai le traîneau" and waits at the
##      front door, which takes them there ("Papa t'amène au parc du Pélican…": across Masson, which she may not cross alone at seven);
##   2. the park (`scenes/parc_pelican.gd`, the sliding hill): Papa hands her the sled, and she slides `RUNS` times: first alone
##      with Papa watching, then both on one sled, then a race on two sleds (she wins: she is the lighter); a "!" over the hill;
##      the park's gate stays shut ("Papa m'attend pour glisser !");
##   3. Papa takes her home for a hot chocolate ("Papa te ramène à la maison…"), the quest is done.
## The step is `GameState.flags.luge_step`, the slides done `flags.luge_count`.

const QUEST := "luge"
const STEP := "luge_step"
const COUNT := "luge_count"
const HEADING := "🛷  La luge avec Papa"
const RUNS := 3
const PARK := "res://scenes/parc_pelican.tscn"
## Where she comes out in the park: at the foot of the hill (parc_pelican.gd HILL_X + 90).
const PARK_START_X := 6850.0


## 0 = not on (or done), else the step.
static func step() -> int:
	return int(GameState.flags.get(STEP, 1)) if Quests.active(QUEST) else 0


static func set_step(n: int) -> void:
	GameState.flags[STEP] = n


static func runs() -> int:
	return int(GameState.flags.get(COUNT, 0))


static func add_run() -> void:
	GameState.flags[COUNT] = runs() + 1


## Papa can ask: winter, the quest free (after her birthday).
static func can_start() -> bool:
	return Season.is_winter() and Quests.available(QUEST)


static func clear() -> void:
	GameState.flags.erase(STEP)
	GameState.flags.erase(COUNT)


static func hint() -> String:
	match step():
		1:
			return "Papa t'attend à la porte d'en avant : il t'emmène glisser au parc du Pélican, avec le traîneau !"
		2:
			return "Glisse sur la butte du parc avec Papa (%d fois sur %d) : seule, à deux, pis en course !" % [runs(), RUNS]
	return str(Quests.ALL[QUEST].hint)
