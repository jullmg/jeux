class_name Twins
extends Node2D
## Alphée and Constance Turcotte, twins, nearly identical and under a head taller than Charlotte (reference/personnages/alfée-et-constance-turcotte.jpg);
## they will be her best friends and give her quests (not decided yet; Mom's "amies" quest sends her to them and ends with the meeting). They hang out in the middle lane: the first click is the
## meeting, a little conversation (`flags.met_twins`); after that, the one clicked says one of her lines. Quests go in `interact`.
## Clicks go through `hit_test`, which remembers which of the two was clicked.

const SPREAD := 130.0
const HEAD := -420.0
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
## Their first quest, hide and seek: who speaks and what she says before Charlotte counts.
const COUNTING := [
	[0, "Chachoue, on joue à la cachette ?"],
	[-1, "Oh oui ! C'est moi qui compte ?"],
	[1, "Oui ! Ferme les yeux et compte jusqu'à dix !"],
	[-1, "Un, deux, trois, quatre…"],
]
const LINE_SECONDS := 2.3
const FOUND_FLAG := "cachette_found"
## How much of a hiding sister shows over her fence.
const PEEK := 120.0
const FOUND_LINES := ["Oh non, tu m'as trouvée ! Cherche Constance !", "Trouvée ! Il reste Alphée !"]
const LINES := [
	["Salut, Chachoue !", "Constance triche toujours à la marelle !", "Moi, c'est Alphée. Regarde : les cheveux détachés !", "On va bien trouver quelque chose à faire ensemble !"],
	["Allô, Chachoue !", "Alphée ronfle, c'est vrai !", "Moi, c'est Constance. Regarde : la queue de cheval !", "Reviens nous voir, on aura des idées !"],
]

## The scene's PlayerControl: Charlotte stays put during the meeting.
var control: PlayerControl
## Where each sister hides in the lane, from the scene: {x, top (of the fence there), front (the fence's sprite, she goes behind it)}.
var hide_spots: Array = []
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
	_show_sisters(not hiding())


## Called by the scene once it is built: those not found yet go back behind their fences (a game in progress, a reload).
func spawn_hidden() -> void:
	if not hiding():
		return
	var found: Array = GameState.flags.get(FOUND_FLAG, [])
	for i in 2:
		if not found.has(i):
			_hide(i)


static func hiding() -> bool:
	return Quests.active("cachette")


static func met() -> bool:
	return GameState.flags.get("met_twins", false)


## They have something to say and aren't saying it yet (the "!" over them).
func waiting() -> bool:
	return (not met() or Quests.available("cachette")) and not _talking


func can_interact() -> bool:
	return not _talking and not hiding()


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
	if met() and Quests.available("cachette"):
		_play_hide_and_seek()
		return
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
		Quests.complete("amies")
		_talking = false
		if control:
			control.hands_off = false
		for sister in _sisters:
			sister.express("happy", 2.0)
		_charlotte.express("happy", 2.0))


# ── Hide and seek ───────────────────────────────────────────

func _play_hide_and_seek() -> void:
	_talking = true
	if control:
		control.hands_off = true
	var steps := create_tween()
	for step: Array in COUNTING:
		steps.tween_callback(_say.bind(step[0], step[1]))
		steps.tween_interval(LINE_SECONDS)
	steps.tween_callback(func() -> void:
		_charlotte.express("sleep", 1.6)
		Transition.through_black(get_parent(), func() -> void:
			Quests.start("cachette")
			_show_sisters(false)
			spawn_hidden(), 0.7))
	steps.tween_interval(1.5)
	steps.tween_callback(_say.bind(-1, "… neuf, dix ! J'arrive !"))
	steps.tween_interval(LINE_SECONDS)
	steps.tween_callback(func() -> void:
		_talking = false
		if control:
			control.hands_off = false)


func _show_sisters(on: bool) -> void:
	for sister in _sisters:
		sister.visible = on


func _hide(i: int) -> void:
	var spot: Dictionary = hide_spots[i]
	var look := CharacterLook.alphee() if i == 0 else CharacterLook.constance()
	Season.dress_for_weather(look)
	var hider := _Hider.new()
	hider.look = look
	hider.scale = scale
	hider.which = i
	hider.twins = self
	hider.peek_y = float(spot.top) - PEEK * scale.y - HEAD * scale.y
	hider.position = Vector2(spot.x, hider.peek_y)
	var scene := get_parent()
	scene.add_child(hider)
	# Behind the fence: only the top of her head shows over it.
	scene.move_child(hider, (spot.front as Node).get_index())


# One found: she says so, and when both are, the quest is done and they are back where they play.
func _found(i: int, at: Vector2) -> void:
	var found: Array = GameState.flags.get(FOUND_FLAG, [])
	if not found.has(i):
		found.append(i)
	GameState.flags[FOUND_FLAG] = found
	var both := found.size() >= 2
	var line: String = "Toutes les deux ! Bravo, Chachoue !" if both else FOUND_LINES[i]
	Bubble.say(get_parent(), at, line, LINE_SECONDS)
	Sfx.play("chime", at)
	if both:
		GameState.flags.erase(FOUND_FLAG)
		Quests.complete("cachette")
		_show_sisters(true)


func _say(speaker: int, text: String) -> void:
	if speaker < 0:
		Bubble.say(get_parent(), _charlotte.position + Vector2(0, -190), text, LINE_SECONDS)
		return
	var sister := _sisters[speaker]
	sister.express("talk", LINE_SECONDS * 0.8)
	Bubble.say(get_parent(), to_global(sister.position) + Vector2(0, HEAD) * scale - Vector2(0, 12), text, LINE_SECONDS)


# A sister behind a fence: her head comes up and ducks down, she giggles when Charlotte comes close, and a click finds her.
class _Hider:
	extends Character

	const GIGGLE_RANGE := 420.0
	const HEAD_BOX := Vector2(110.0, 95.0)
	var which := 0
	var twins: Twins
	var peek_y := 0.0
	var _clock := 0.0
	var _giggle := 2.0
	var _found_her := false

	func _ready() -> void:
		super._ready()
		fidgets = false
		facing = 1 if which == 0 else -1
		_clock = which * 1.3
		add_to_group("interactable")

	func _process(delta: float) -> void:
		super._process(delta)
		if _found_her:
			return
		_clock += delta
		# Up for a while, then down behind the boards.
		position.y = peek_y + (1.0 - smoothstep(-0.3, 0.3, sin(_clock * 1.1))) * 26.0
		var who: Variant = get_parent().get("_charlotte")
		if who is Node2D and absf((who as Node2D).position.x - position.x) < GIGGLE_RANGE:
			_giggle -= delta
			if _giggle <= 0.0:
				_giggle = randf_range(4.0, 7.0)
				express("laugh", 1.0)
				Bubble.say(get_parent(), Vector2(position.x, peek_y + Twins.HEAD * scale.y - 16.0), "Hi hi !", 1.2)

	func can_interact() -> bool:
		return not _found_her

	func hit_test(p: Vector2) -> bool:
		return Rect2(Vector2(position.x - HEAD_BOX.x / 2.0, peek_y + Twins.HEAD * scale.y - 10.0), HEAD_BOX).has_point(p)

	func approach_x(from_x: float) -> float:
		return position.x + (70.0 if from_x > position.x else -70.0)

	func focus_x() -> float:
		return position.x

	func reserve() -> void:
		pass

	func release() -> void:
		pass

	func interact(who: Character) -> void:
		_found_her = true
		remove_from_group("interactable")
		who.express("laugh", 2.0)
		expression = "laugh"
		twins._found(which, Vector2(position.x, peek_y + Twins.HEAD * scale.y - 30.0))
		var out := create_tween()
		out.tween_property(self, "position:y", peek_y - 22.0, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		out.tween_interval(1.6)
		out.tween_property(self, "modulate:a", 0.0, 0.4)
		out.tween_callback(queue_free)

