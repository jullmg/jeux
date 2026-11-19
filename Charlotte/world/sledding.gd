class_name Sledding
extends RefCounted
## Sliding down the snow hill in the schoolyard (quest "glissade", winter, after the first school day; Julien: the sled is
## lent by the service de garde). On a school day, at the service de garde:
##   1. before the drawing, Jade says the garde is going out to slide and lends her a sled (`Carry` "traineau"); the garde's
##      door leads out to the schoolyard ("Le service de garde sort glisser…");
##   2. the yard (`scenes/cour_ecole.gd` in its "garde" mode: no bell, Jade by the door): she clicks the snow hill, climbs it,
##      sits on the sled and slides down, `RUNS` times; then Jade takes the sled back, the quest is done, and they go back in
##      ("On rentre se réchauffer !") to the garde, where the day goes on (the drawing, Papa).
## The step is `GameState.flags.glissade_step`, the slides done `flags.glissade_count`.

const QUEST := "glissade"
const STEP := "glissade_step"
const COUNT := "glissade_count"
const HEADING := "🛷  La glissade"
## How many times down the hill.
const RUNS := 3
const YARD := "res://scenes/cour_ecole.tscn"
const GARDE := "res://scenes/service_de_garde.tscn"
## Where she comes out in the yard: by the pupils' door (cour_ecole.gd DOOR_X).
const YARD_START := 1580.0
## Back in the garde after the sliding (Jade then asks for the drawing): set by the yard, read once by the garde.
static var just_back := false


## 0 = not on (or done), else the step.
static func step() -> int:
	return int(GameState.flags.get(STEP, 1)) if Quests.active(QUEST) else 0


static func set_step(n: int) -> void:
	GameState.flags[STEP] = n


static func runs() -> int:
	return int(GameState.flags.get(COUNT, 0))


static func add_run() -> void:
	GameState.flags[COUNT] = runs() + 1


## Jade can offer it: winter, the quest free, and a school day at the garde (she is only met there).
static func can_start() -> bool:
	return Season.is_winter() and Quests.available(QUEST)


## The schoolyard is the garde's, out sliding (not recess).
static func in_yard() -> bool:
	return step() == 2


static func clear() -> void:
	GameState.flags.erase(STEP)
	GameState.flags.erase(COUNT)


static func hint() -> String:
	match step():
		1:
			return "Jade t'a prêté un traîneau ! Sors dans la cour par la porte du service de garde."
		2:
			return "Glisse sur la butte de neige de la cour (%d fois sur %d)." % [runs(), RUNS]
	return str(Quests.ALL[QUEST].hint)


## Canvas 150 x 60: a red plastic sled seen from the side, its front curled up on the right, the yellow pull rope; its
## bottom on the bottom edge.
static func sled() -> ImageTexture:
	var s := '<defs><linearGradient id="sl" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#F0504A"/><stop offset="1" stop-color="#A91F24"/></linearGradient></defs>'
	# The tray: a long shallow tub, the front swept up and round.
	s += '<path d="M8 30 L104 30 Q132 30 138 8 Q146 6 146 14 Q140 54 104 56 L18 56 Q6 56 6 44 Z" fill="url(#sl)" stroke="#7E1418" stroke-width="2.5" stroke-linejoin="round"/>'
	s += '<path d="M10 33 L104 33 Q128 33 136 14" stroke="#FF8A80" stroke-width="2.5" fill="none" stroke-linecap="round"/>'
	# Its runners moulded into the bottom, and the handholds.
	s += '<path d="M20 52 H100" stroke="#7E1418" stroke-width="2" opacity="0.6"/>'
	for x in [34.0, 76.0]:
		s += '<rect x="%s" y="38" width="16" height="7" rx="3.5" fill="#7E1418" opacity="0.75"/>' % x
	# The rope, looped from the front.
	s += '<path d="M140 12 Q150 30 134 40 Q118 46 122 34" stroke="#F2C230" stroke-width="3" fill="none" stroke-linecap="round"/>'
	return InteriorArt.tex(150, 60, s)
