class_name BillieAuguste
extends Node2D
## Billie (7) and Auguste (5), two little neighbours, smaller than Charlotte (reference/personnages/billie_et_auguste.jpg).
## They live in the lane, a few houses toward Dandurand, and are there once Mom's "amies" quest has started (like the twins).
## The first click is the meeting (`flags.met_billie_auguste`); after that the one clicked says a line. Quests go in `interact`.

const SPREAD := 74.0
## The top of each one's head, in their own units (Billie, Auguste).
const HEADS := [-322.0, -278.0]
const FLAG := "met_billie_auguste"
const MEETING := [
	[0, "Allô ! T'es la fille du 5672 !"],
	[-1, "Oui ! Moi, c'est Charlotte. Et vous ?"],
	[0, "Moi, c'est Billie, j'ai sept ans. Lui, c'est Auguste."],
	[1, "Moi, j'ai CINQ ans ! Pis je suis grand !"],
	[-1, "Mes amis m'appellent Chachoue."],
	[1, "Cha-choue ! Cha-choue !"],
	[0, "On est amis, astheure ! Reviens nous voir !"],
]
const LINE_SECONDS := 2.3
const LINES := [
	["Salut, Chachoue !", "J'ai mangé une crème glacée au dépanneur !", "Auguste court plus vite que moi, mais pas longtemps !"],
	["Regarde mon chandail ! C'est un vrai !", "Je peux compter jusqu'à vingt !", "Chachoue ! Chachoue !"],
]

## The scene's PlayerControl: Charlotte stays put during the meeting.
var control: PlayerControl
var _kids: Array[Character] = []
var _charlotte: Character
var _clicked := 0
var _line := [0, 0]
var _talking := false


func _ready() -> void:
	var looks := [CharacterLook.billie(), CharacterLook.auguste()]
	for i in 2:
		Season.dress_for_weather(looks[i])
		var kid := Character.new()
		kid.look = looks[i]
		kid.fidgets = true
		kid.position.x = SPREAD * (-1.0 if i == 0 else 1.0)
		kid.facing = 1 if i == 0 else -1
		add_child(kid)
		_kids.append(kid)
	add_to_group("interactable")


static func met() -> bool:
	return GameState.flags.get(FLAG, false)


## They have something to say and aren't saying it yet (the "!" over them).
func waiting() -> bool:
	return not met() and not _talking


func can_interact() -> bool:
	return not _talking


func hit_test(p: Vector2) -> bool:
	for i in 2:
		var at := to_global(_kids[i].position)
		if Rect2(at + Vector2(-60, HEADS[i]) * scale, Vector2(120, -HEADS[i]) * scale).has_point(p):
			_clicked = i
			return true
	return false


func approach_x(from_x: float) -> float:
	var side := 1.0 if from_x > global_position.x else -1.0
	return global_position.x + side * (SPREAD + 130.0) * scale.x


func focus_x() -> float:
	return global_position.x


func reserve() -> void:
	pass


func release() -> void:
	pass


func interact(who: Character) -> void:
	_charlotte = who
	for kid in _kids:
		kid.facing = 1 if who.position.x > kid.global_position.x else -1
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
		GameState.flags[FLAG] = true
		_talking = false
		if control:
			control.hands_off = false
		for kid in _kids:
			kid.express("happy", 2.0)
		_charlotte.express("happy", 2.0))


func _say(speaker: int, text: String) -> void:
	if speaker < 0:
		Bubble.say(get_parent(), _charlotte.position + Vector2(0, -190), text, LINE_SECONDS)
		return
	var kid := _kids[speaker]
	kid.express("talk", LINE_SECONDS * 0.8)
	Bubble.say(get_parent(), to_global(kid.position) + Vector2(0, HEADS[speaker]) * scale - Vector2(0, 12), text, LINE_SECONDS)
