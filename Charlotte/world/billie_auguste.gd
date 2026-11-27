class_name BillieAuguste
extends Node2D
## Billie (7) and Auguste (5), sister and brother, two little neighbours, smaller than Charlotte (reference/personnages/billie_et_auguste.jpg).
## They live in the lane, a few houses toward Dandurand, and are there once Mom's "amies" quest has started (like the twins).
## The first click is the meeting (`flags.met_billie_auguste`); after that the one clicked says a line. Quests go in `interact`.
## Their first one is the snowman (`Snowman`, winter): they roll its balls beside them and Charlotte brings the rest.

## Where each stands (Billie, Auguste), in their units: well apart, not shoulder to shoulder. Auguste plays with his ball.
const XS := [-170.0, 190.0]
const SPREAD := 190.0
## The top of each one's head, in their own units (Billie, Auguste).
const HEADS := [-322.0, -278.0]
const FLAG := "met_billie_auguste"
const MEETING := [
	[0, "Allô ! T'es la fille du 5672 !"],
	[-1, "Oui ! Moi, c'est Charlotte. Et vous ?"],
	[0, "Moi, c'est Billie, j'ai sept ans. Lui, c'est mon petit frère Auguste."],
	[1, "Moi, j'ai CINQ ans ! Pis chu grand, hein ?"],
	[-1, "Mes amis m'appellent Chachoue."],
	[1, "Cha-choue ! Cha-choue !"],
	[0, "On est amis, maintenant ! Reviens nous voir !"],
]
const LINE_SECONDS := 2.3
## Where their snowman stands, in their units (right of Auguste).
const SNOWMAN_X := 500.0
const SNOWMAN_ASK := [
	[0, "Chachoue ! As-tu vu toute la neige ?"],
	[1, "On fait un bonhomme de neige ! Un GROS !"],
	[-1, "Oh oui ! Je vous aide !"],
	[0, "On roule les boules, nous autres. Regarde !"],
]
const SNOWMAN_LACKS := [
	[1, "Y'a pas de nez ! Pis pas de boutons !"],
	[0, "Pis y va avoir frette aux oreilles : y faut une tuque."],
	[-1, "Je vais chercher ça chez nous ! Une carotte dans le frigo…"],
	[-1, "…des boutons à Maman pis une tuque à Papa !"],
]
## What each says as the part goes on: [who puts it on, their line, Charlotte's answer].
const SNOWMAN_PUT := {
	"carotte": [1, "C'est moi qui mets le nez ! Pouic !", "Il a l'air d'un vrai, maintenant !"],
	"boutons": [0, "Un, deux, trois boutons ! Y est ben chic !", "Rouge, bleu, jaune !"],
	"tuque": [1, "La tuque du Canadien ! Go Habs go !", "Y aura pas frette aux oreilles !"],
}
const SNOWMAN_DONE := [
	[0, "Y est fini ! C'est le plus beau bonhomme de la ruelle !"],
	[1, "On l'appelle Monsieur Carotte !"],
	[-1, "Bonjour, Monsieur Carotte !"],
	[0, "Merci, Chachoue ! T'es très gentille."],
]
const SNOWMAN_LINES := [
	["Monsieur Carotte a pas fondu ! Y fait trop frette !", "Demain, on y fait une blonde !"],
	["Y me regarde, Monsieur Carotte !", "Chu plus grand que lui ? Non ? Pas encore !"],
]
const LINES := [
	["Salut, Chachoue !", "J'ai mangé une crème glacée, c'était très bon !", "Mon p'tit frère court plus vite que moi, mais pas longtemps !"],
	["Regarde mon chandail ! C'est un vrai !", "Je suis capable de compter jusqu'à vingt !", "Ma sœur est ben fine, mais a me gosse des fois !"],
]

## The scene's PlayerControl: Charlotte stays put during the meeting.
var control: PlayerControl
var _kids: Array[Character] = []
var _charlotte: Character
var _clicked := 0
var _line := [0, 0]
var _talking := false
var _snowman: Snowman
var _ball: _Ball
var _t := 0.0


func _ready() -> void:
	var looks := [CharacterLook.billie(), CharacterLook.auguste()]
	for i in 2:
		Season.dress_for_weather(looks[i])
		var kid := Character.new()
		kid.look = looks[i]
		# Auguste bounces his ball instead of fidgeting.
		kid.fidgets = i == 0
		kid.position.x = XS[i]
		kid.facing = 1 if i == 0 else -1
		add_child(kid)
		_kids.append(kid)
	_ball = _Ball.new()
	_ball.owner_kid = self
	add_child(_ball)
	if Snowman.standing():
		_build_snowman()
	add_to_group("interactable")


func _process(delta: float) -> void:
	_t += delta
	# Auguste bounces the ball: his hand goes down to it each time it comes back up.
	if absf(sin(_t * 3.4)) > 0.88 and not _kids[1].is_petting():
		_kids[1].pet(0.1, 0.0)
	if OnScreen.near(self, 400.0):
		_ball.queue_redraw()


## Where the ball is, in their units: beside Auguste, on the side he faces, bouncing up from the ground.
func ball_position() -> Vector2:
	var side := float(_kids[1].facing)
	return Vector2(_kids[1].position.x + side * 62.0, -24.0 - absf(sin(_t * 3.4)) * 105.0)


static func met() -> bool:
	return GameState.flags.get(FLAG, false)


## They have something to say and aren't saying it yet (the "!" over them): the meeting, the snowman to ask for, or
## something for it in her arms.
func waiting() -> bool:
	if _talking:
		return false
	return not met() or FriendBracelet.has_pending(["billie", "auguste"]) or Snowman.can_start() or Quests.active(Snowman.QUEST) and Carry.has("bonhomme")


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
	if not met():
		_meet()
	elif FriendBracelet.give(_kids[_clicked], ["billie", "auguste"][_clicked], _say_as(_clicked), who):
		pass
	elif Snowman.can_start():
		_ask_for_snowman()
	elif Quests.active(Snowman.QUEST) and Carry.has("bonhomme"):
		_put_on_snowman(Carry.id())
	elif Quests.active(Snowman.QUEST) and Snowman.missing().is_empty():
		_snowman_done()
	elif Quests.active(Snowman.QUEST):
		_say(_clicked, "Y manque encore %s !" % ", ".join(Snowman.missing().map(func(p: String) -> String: return Snowman.NAMES[p])))
	else:
		var lines: Array = SNOWMAN_LINES[_clicked] if Snowman.standing() and _line[_clicked] % 2 == 1 else LINES[_clicked]
		_say(_clicked, lines[_line[_clicked] % lines.size()])
		_line[_clicked] += 1


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
		Notebook.new_friend(FLAG)
		_talking = false
		if control:
			control.hands_off = false
		for kid in _kids:
			kid.express("happy", 2.0)
		_charlotte.express("happy", 2.0))


# ── The snowman ─────────────────────────────────────────────

func _build_snowman() -> void:
	_snowman = Snowman.new()
	_snowman.position = Vector2(SNOWMAN_X, 0)
	add_child(_snowman)
	move_child(_snowman, 0)


# They ask her, roll the three balls (the snowman grows out of the snow, ball by ball), and say what it lacks.
func _ask_for_snowman() -> void:
	_talk_through(SNOWMAN_ASK, func() -> void:
		Quests.start(Snowman.QUEST)
		_build_snowman()
		_snowman.scale = Vector2(0.2, 0.05)
		_talking = true
		if control:
			control.hands_off = true
		var grow := create_tween()
		for k in 3:
			grow.tween_callback(Sfx.play.bind("pop", to_global(_snowman.position)))
			grow.tween_property(_snowman, "scale", Vector2.ONE * (0.45 + k * 0.275), 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			grow.tween_interval(0.35)
		grow.tween_callback(func() -> void:
			_talking = false
			for kid in _kids:
				kid.express("grin", 1.6)
			_talk_through(SNOWMAN_LACKS, func() -> void:
				Notebook.announce("step", "Trouve une carotte, des boutons pis une tuque pour le bonhomme !", Snowman.HEADING))))


# She hands them what she brought: it goes on the snowman, and with the last one it is finished.
func _put_on_snowman(part: String) -> void:
	var put: Array = SNOWMAN_PUT.get(part, [0, "Merci !", "Voilà !"])
	Carry.put_down(_charlotte)
	_charlotte.pet(0.8, 0.0)
	Snowman.add_part(part)
	if _snowman:
		_snowman.refresh()
		var bump := create_tween()
		bump.tween_property(_snowman, "scale", Vector2(1.06, 0.95), 0.12)
		bump.tween_property(_snowman, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	Sfx.play("pop", to_global(_snowman.position) if _snowman else global_position)
	_kids[put[0]].express("grin", 2.0)
	var lines := [[put[0], put[1]], [-1, put[2]]]
	_talk_through(lines, func() -> void:
		if Snowman.missing().is_empty():
			_snowman_done()
		else:
			Notebook.announce("step", "Il manque encore %s." % ", ".join(Snowman.missing().map(func(p: String) -> String: return Snowman.NAMES[p])), Snowman.HEADING))


func _snowman_done() -> void:
	Sfx.play("chime", global_position)
	_talk_through(SNOWMAN_DONE, func() -> void:
		for kid in _kids:
			kid.express("laugh", 2.0)
		_charlotte.express("happy", 2.0)
		Quests.complete(Snowman.QUEST))


func _talk_through(lines: Array, after: Callable) -> void:
	_talking = true
	if control:
		control.hands_off = true
	var steps := create_tween()
	for step: Array in lines:
		steps.tween_callback(_say.bind(step[0], step[1]))
		steps.tween_interval(LINE_SECONDS)
	steps.tween_callback(func() -> void:
		_talking = false
		if control:
			control.hands_off = false
		after.call())


func _say(speaker: int, text: String) -> void:
	if speaker < 0:
		Bubble.say(get_parent(), _charlotte.position + Vector2(0, -190), text, LINE_SECONDS)
		return
	var kid := _kids[speaker]
	kid.express("talk", LINE_SECONDS * 0.8)
	Bubble.say(get_parent(), to_global(kid.position) + Vector2(0, HEADS[speaker]) * scale - Vector2(0, 12), text, LINE_SECONDS)


# Auguste's rubber ball, orange with its seams, and the small shadow on the ground that shrinks as it rises.
class _Ball:
	extends Node2D
	var owner_kid: BillieAuguste
	var color := Color("#E8662A")

	func _draw() -> void:
		var p := owner_kid.ball_position()
		var h := -p.y - 24.0
		draw_set_transform(Vector2(p.x, 2), 0.0, Vector2(1.0, 0.25))
		draw_circle(Vector2.ZERO, 20.0 - h * 0.05, Color(0, 0, 0, 0.18))
		draw_set_transform(Vector2.ZERO)
		draw_circle(p, 20.0, color)
		draw_arc(p, 20.0, 0, TAU, 24, color.darkened(0.35), 2.6, true)
		draw_line(p + Vector2(-20, 0), p + Vector2(20, 0), color.darkened(0.4), 1.8, true)
		draw_arc(p + Vector2(-26, 0), 20.0, -0.9, 0.9, 10, color.darkened(0.4), 1.8, true)
		draw_arc(p + Vector2(26, 0), 20.0, PI - 0.9, PI + 0.9, 10, color.darkened(0.4), 1.8, true)
		draw_circle(p + Vector2(-7, -8), 4.5, Color(1, 1, 1, 0.35))


# A line from kid `i` (kept for a line said later, whoever is clicked by then).
func _say_as(i: int) -> Callable:
	return func(t: String) -> void: _say(i, t)
