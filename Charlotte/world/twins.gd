class_name Twins
extends Node2D
## Alphée and Constance Turcotte, twins, nearly identical and about a head taller than Charlotte (reference/alfée-et-constance-turcotte.jpg);
## they will be her best friends and give her quests (not decided yet). They hang out in the middle lane: the first click is the
## meeting, a little conversation (`flags.met_twins`); after that, the one clicked says one of her lines. Quests go in `interact`.
## Clicks go through `hit_test`, which remembers which of the two was clicked.

const SPREAD := 130.0
const HEAD := -470.0
## The meeting: who speaks (0 Alphée, 1 Constance, -1 Charlotte) and what she says.
const MEETING := [
	[0, "Allô ! On ne t'a jamais vue dans la ruelle !"],
	[-1, "Salut ! Moi, c'est Charlotte. J'habite juste là."],
	[0, "Moi, c'est Alphée Turcotte."],
	[1, "Et moi, Constance Turcotte. On est jumelles !"],
	[-1, "Wow, vous vous ressemblez tellement !"],
	[1, "Tout le monde nous mélange, tu vas voir !"],
	[-1, "Mes amis m'appellent Chachoue."],
	[0, "Salut, Chachoue ! Tu viens jouer avec nous ?"],
	[-1, "Oh oui !"],
]
const LINE_SECONDS := 2.3
const LINES := [
	["Salut, Chachoue !", "Constance triche toujours à la marelle !", "Moi, c'est Alphée. Regarde : les cheveux détachés !", "On va bien trouver quelque chose à faire ensemble !"],
	["Allô, Chachoue !", "Alphée ronfle, c'est vrai !", "Moi, c'est Constance. Regarde : la queue de cheval !", "Reviens nous voir, on aura des idées !"],
]

## The scene's PlayerControl: Charlotte stays put during the meeting.
var control: PlayerControl
var _sisters: Array[Character] = []
var _charlotte: Character
var _clicked := 0
var _line := [0, 0]
var _talking := false


func _ready() -> void:
	var looks := [CharacterLook.alphee(), CharacterLook.constance()]
	for i in 2:
		Season.dress_for_weather(looks[i])
		var sister := Character.new()
		sister.look = looks[i]
		sister.fidgets = true
		sister.position.x = SPREAD * (-1.0 if i == 0 else 1.0)
		sister.facing = 1 if i == 0 else -1
		add_child(sister)
		_sisters.append(sister)
	add_to_group("interactable")


static func met() -> bool:
	return GameState.flags.get("met_twins", false)


## They have something to say and aren't saying it yet (the "!" over them).
func waiting() -> bool:
	return not met() and not _talking


func can_interact() -> bool:
	return not _talking


func hit_test(p: Vector2) -> bool:
	for i in 2:
		var at := to_global(_sisters[i].position)
		if Rect2(at + Vector2(-70, HEAD) * scale, Vector2(140, -HEAD) * scale).has_point(p):
			_clicked = i
			return true
	return false


func approach_x(from_x: float) -> float:
	var side := 1.0 if from_x > global_position.x else -1.0
	return global_position.x + side * (SPREAD + 170.0) * scale.x


func focus_x() -> float:
	return global_position.x


func reserve() -> void:
	pass


func release() -> void:
	pass


func interact(who: Character) -> void:
	_charlotte = who
	for sister in _sisters:
		sister.facing = 1 if who.position.x > sister.global_position.x else -1
	if met():
		_say(_clicked, LINES[_clicked][_line[_clicked] % LINES[_clicked].size()])
		_line[_clicked] += 1
		return
	_meet()


func _meet() -> void:
	_talking = true
	if control:
		control.hands_off = true
	var steps := create_tween()
	for step: Array in MEETING:
		steps.tween_callback(_say.bind(step[0], step[1]))
		steps.tween_interval(LINE_SECONDS)
	steps.tween_callback(func() -> void:
		GameState.flags["met_twins"] = true
		_talking = false
		if control:
			control.hands_off = false
		for sister in _sisters:
			sister.express("happy", 2.0)
		_charlotte.express("happy", 2.0))


func _say(speaker: int, text: String) -> void:
	if speaker < 0:
		Bubble.say(get_parent(), _charlotte.position + Vector2(0, -190), text, LINE_SECONDS)
		return
	var sister := _sisters[speaker]
	sister.express("talk", LINE_SECONDS * 0.8)
	Bubble.say(get_parent(), to_global(sister.position) + Vector2(0, HEAD) * scale - Vector2(0, 12), text, LINE_SECONDS)
