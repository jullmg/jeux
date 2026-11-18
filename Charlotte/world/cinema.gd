class_name Cinema
extends RefCounted
## The movie night with the twins (quest "cinema", in winter after Halloween), step by step:
##   1. the twins asked her in the lane (`Twins._ask_for_movie`): she asks Maman for pocket money;
##   2. Maman gave her 5 $ (`house.gd _talk_to_mom`): she buys a bag of chips and some candy at a dépanneur (`Shop._buy_chips`,
##      `_buy_candy`), which go in a paper bag in her arms (`Carry` "snacks");
##   3. she has both: the twins wait for her at home, in front of the hallway TV (`house.gd _build_movie_night`), and the
##      film plays (`TvShows` "film") with the three of them on the cushions.
## The step is `GameState.flags.cinema_step`, what she has bought `flags.cinema_snacks`.

const QUEST := "cinema"
const STEP := "cinema_step"
const SNACKS := "cinema_snacks"
## What she must buy for the evening.
const NEEDS := ["chips", "candy"]
## Maman's pocket money for it.
const MONEY := 5.0


## 0 = not started (or done), else the step she is on (1 for a quest switched on by the debug menu).
static func step() -> int:
	return int(GameState.flags.get(STEP, 1)) if Quests.active(QUEST) else 0


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
			return "Tu as les grignotines ! Rentre à la maison : Alphée et Constance t'attendent devant la télé du corridor."
	return str(Quests.ALL[QUEST].hint)
