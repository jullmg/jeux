class_name Emilia
extends Node2D
## Emilia, seven, of Mexican heritage (`CharacterLook.emilia()`), and the quest "emilia": a second school day, once the first one
## is done (`School`). The day runs on the school's own steps, with Emilia added to each:
##   2. in the yard she sits on the asphalt drawing a monarch butterfly in chalk, half of it done (scenes/cour_ecole.gd): the
##      first click is the meeting (`flags.met_emilia`, the notebook's friends page): "mariposa", the monarchs that fly to Mexico
##      every winter, Charlotte draws the other wing and they become friends; then the scene rings the bell (`played`);
##   3. in class she has the desk next to Alyzée's other side; Madame Nadia welcomes her, she says "¡Buenos días!", and the
##      lesson ends with the Spanish word she taught (`word_question`) (scenes/classe.gd);
##   4. at the service de garde she shares a concha, the sweet bread her mamá baked (`flags.emilia_shared`), and Papa doesn't
##      come before; she tells him about her new friend and the quest is done (scenes/service_de_garde.gd).
## After that a click on her gets one of her lines, in the yard, in class and at the garde. The node is scaled like the street's
## people; its Character is not (like `Alyzee`).

signal played

const QUEST := "emilia"
const FLAG := "met_emilia"
## She has shared her concha at the service de garde (today's last step before Papa).
const SHARED := "emilia_shared"
const HEADING := "🦋  Emilia"
## The top of her head, in the Character's own units, standing and sitting on the ground.
const HEAD := -330.0
const HEAD_SITTING := -230.0
## Where the chalk butterfly lies, in her own units: in front of her on the asphalt, laid flat.
const CHALK := Vector2(380.0, 55.0)
const MEETING := [
	[-1, "Wow ! Il est beau, ton dessin !\nC'est quoi ?"],
	[0, "C'est une mariposa ! Ça veut dire\n« papillon » en espagnol."],
	[0, "C'est un monarque. Chaque hiver, ils volent\njusqu'au Mexique, super loin !"],
	[0, "Ma abuela les voit arriver, là-bas.\nMa mamá vient de là."],
	[-1, "Moi, c'est Charlotte.\nMais tout le monde m'appelle Chachoue !"],
	[0, "Moi, c'est Emilia. ¡Mucho gusto, Chachoue !"],
	[-1, "Veux-tu que je t'aide à finir\nla deuxième aile ?"],
	[0, "¡Sí ! Prends la craie orange."],
]
const AFTER_DRAWING := [
	[0, "¡Qué bonito ! Il est complet !"],
	[-1, "On dirait qu'il va s'envoler !"],
	[0, "Chachoue… veux-tu être mon amiga ?"],
	[-1, "Oui ! Ben oui ! Amigas !"],
	[0, "¡Amigas ! Hi hi !"],
]
const LINES := ["¡Hola, Chachoue !", "Mariposa, ça veut dire papillon !", "Ma abuela m'envoie des cartes postales du Mexique.",
	"Ma mamá fait des conchas, du pain sucré. Je t'en donne une un jour !", "Chez nous, on parle français et espagnol.",
	"Gracias, ça veut dire merci !", "Demain, on dessine un soleil, OK ?"]

## The control the scene gives her: Charlotte is left to the script while they talk and draw.
var control: PlayerControl
## Where she may walk (world x).
var bounds := Vector2(0, 2600)
var kid: Character
var _charlotte: Character
var _chalk: _Chalk
var _talking := false
var _line := 0


func _ready() -> void:
	var look := CharacterLook.emilia()
	Season.dress_for_weather(look)
	kid = Character.new()
	kid.look = look
	kid.fidgets = true
	add_child(kid)
	add_to_group("interactable")
	if not met():
		# On the ground, her back to the others, drawing a butterfly in chalk with its left wing done.
		_chalk = _Chalk.new()
		_chalk.position = CHALK
		_chalk.progress = 0.5
		add_child(_chalk)
		kid.sitting = true
		kid.sit_on_ground = true
		kid.seat_h = 0.0
		kid.facing = 1
		kid.expression = "focus"


static func met() -> bool:
	return GameState.flags.get(FLAG, false)


## The school day of the quest is on (she is at school and the quest is active).
static func day() -> bool:
	return Quests.active(QUEST) and School.step() > 0


static func shared() -> bool:
	return GameState.flags.get(SHARED, false)


## She has something to say and isn't saying it yet (the "!" over her).
func waiting() -> bool:
	return not met() and not _talking


## The Spanish word of the lesson (scenes/classe.gd adds it at the end of the questions): school's question format.
static func word_question() -> Dictionary:
	return School._question("Comment dit-on « papillon » en espagnol ?", "Comment dit-on papillon en espagnol ?",
		"papillon = ?", "", ["mariposa", "gato", "casa"])


## What the notebook says to do next.
static func hint() -> String:
	match School.step():
		2:
			return "Dans la cour, quelqu'un dessine à la craie, tout seul. Va voir !" if not met() \
				else "Quand la cloche sonne, entre dans l'école par la porte des élèves."
		3:
			return "Assieds-toi à ton pupitre, pis écoute bien Emilia et Madame Nadia."
		4:
			return "Au service de garde, va voir Emilia : elle a quelque chose à partager." if not shared() \
				else "Fais ton dessin pour tes parents, pis raconte ta journée à Papa quand il arrive !"
	return str(Quests.ALL[QUEST].hint)


func head() -> Vector2:
	return global_position + Vector2(0, HEAD_SITTING if kid.sitting else HEAD) * scale


func can_interact() -> bool:
	return not _talking


func hit_test(p: Vector2) -> bool:
	var top := HEAD_SITTING if kid.sitting else HEAD
	return Rect2(global_position + Vector2(-70, top) * scale, Vector2(140, -top) * scale).has_point(p)


## She sits with her back to the others and the chalk on her right: Charlotte comes up on the left.
func approach_x(_from_x: float) -> float:
	return global_position.x - 190.0 * scale.x


func focus_x() -> float:
	return global_position.x


func reserve() -> void:
	pass


func release() -> void:
	pass


func interact(who: Character) -> void:
	_charlotte = who
	if met():
		kid.facing = 1 if who.position.x > global_position.x else -1
		_say(0, LINES[_line % LINES.size()])
		_line += 1
		return
	_meet()


func _meet() -> void:
	_talking = true
	if control:
		control.hands_off = true
	kid.expression = ""
	kid.express("happy", 1.5)
	var steps := create_tween()
	for step: Array in MEETING:
		var text: String = step[1]
		steps.tween_callback(_say.bind(step[0], text))
		steps.tween_interval(Bubble.reading_time(text, 2.0) + 0.2)
	_draw_together(steps)
	for step: Array in AFTER_DRAWING:
		var text: String = step[1]
		steps.tween_callback(_say.bind(step[0], text))
		steps.tween_interval(Bubble.reading_time(text, 2.0) + 0.2)
	steps.tween_callback(func() -> void:
		GameState.flags[FLAG] = true
		Notebook.new_friend(FLAG)
		kid.express("happy", 2.4)
		_charlotte.express("happy", 2.4)
		Sfx.play("chime", global_position))
	steps.tween_interval(1.6)
	# She gets up, and the game is over: the scene rings the bell.
	steps.tween_callback(func() -> void:
		kid.sit_on_ground = false
		kid.sitting = false
		_talking = false
		played.emit())


# Charlotte walks over the chalk to its far side, turns back, crouches and draws the right wing while the butterfly fills in.
func _draw_together(steps: Tween) -> void:
	var chalk_x := global_position.x + CHALK.x * scale.x
	steps.tween_callback(func() -> void:
		_charlotte.is_walking = true
		_charlotte.facing = 1)
	steps.tween_property(_charlotte, "position:x", chalk_x + 75.0, 1.1)
	steps.tween_callback(func() -> void:
		_charlotte.is_walking = false
		_charlotte.facing = -1
		_charlotte.pet(3.2, 1.0))
	steps.tween_method(func(u: float) -> void:
		if _chalk:
			_chalk.progress = u, 0.5, 1.0, 3.0)
	steps.tween_interval(0.4)


## She gets up and walks to `x` (the school's door) at Charlotte's pace.
func walk_to(x: float, secs: float) -> Tween:
	var t := create_tween()
	t.tween_callback(func() -> void:
		kid.sit_on_ground = false
		kid.sitting = false
		kid.is_walking = true
		kid.facing = 1 if x > global_position.x else -1)
	t.tween_property(self, "position:x", x, secs)
	t.tween_callback(func() -> void: kid.is_walking = false)
	return t


func say(text: String, seconds := 2.4) -> void:
	kid.express("talk", Bubble.reading_time(text, seconds) * 0.8)
	Bubble.say(get_parent(), head() - Vector2(0, 12), text, seconds)


func _say(speaker: int, text: String) -> void:
	if speaker < 0:
		Bubble.say(get_parent(), _charlotte.position + Vector2(0, -190), text, 2.0)
		return
	say(text, 2.0)


# ── The butterfly in chalk ──────────────────────────────────────

## A monarch butterfly laid flat on the asphalt (the world is seen from the side, so it is squashed): orange wings veined and
## edged in black with white dots. `progress` 0 to 0.5 draws the left wings, 0.5 to 1 the right ones.
class _Chalk:
	extends Node2D

	var progress := 1.0:
		set(v):
			progress = v
			queue_redraw()

	const W := 190.0
	const H := 84.0

	func _draw() -> void:
		var left := clampf(progress / 0.5, 0.0, 1.0)
		var right := clampf((progress - 0.5) / 0.5, 0.0, 1.0)
		_wings(-1.0, left)
		_wings(1.0, right)
		# The body and the two feelers, in white chalk, once the first wing is there.
		if left > 0.0:
			draw_line(Vector2(0, -H * 0.55), Vector2(0, H * 0.6), Color(0.96, 0.95, 0.92, 0.9), 7.0, true)
			draw_line(Vector2(0, -H * 0.55), Vector2(-16, -H * 0.9), Color(0.96, 0.95, 0.92, 0.8), 2.5, true)
			draw_line(Vector2(0, -H * 0.55), Vector2(16, -H * 0.9), Color(0.96, 0.95, 0.92, 0.8), 2.5, true)

	# One side: a big upper wing and a smaller lower one, rounded, grown from the body out as `amount` goes 0 to 1.
	func _wings(side: float, amount: float) -> void:
		if amount <= 0.0:
			return
		var orange := Color("#F29A2E", 0.92 * amount)
		var black := Color(0.1, 0.09, 0.09, 0.92 * amount)
		var upper := _blob(Vector2(W * 0.5, -H * 0.38), W * 0.52, H * 0.5, deg_to_rad(-18.0), side, amount)
		var lower := _blob(Vector2(W * 0.38, H * 0.42), W * 0.36, H * 0.4, deg_to_rad(14.0), side, amount)
		for shape: PackedVector2Array in [upper, lower]:
			draw_colored_polygon(shape, orange)
			var closed := shape.duplicate()
			closed.append(shape[0])
			draw_polyline(closed, black, 4.0, true)
			# The veins, from the body to the edge.
			for k in 4:
				draw_line(Vector2.ZERO, shape[(3 + k * 5) % shape.size()], Color(black, black.a * 0.55), 2.0, true)
			# White dots along the black edge.
			for k in 5:
				var p: Vector2 = shape[(k * 4 + 2) % shape.size()] * 0.9
				draw_circle(p, 3.2, Color(1, 1, 1, 0.9 * amount))

	# An ellipse of 24 points about `centre`, tilted by `tilt`, mirrored for the left side and shrunk toward the body by `amount`.
	func _blob(centre: Vector2, rx: float, ry: float, tilt: float, side: float, amount: float) -> PackedVector2Array:
		var pts := PackedVector2Array()
		for k in 24:
			var a := TAU * k / 24.0
			var p := Vector2(cos(a) * rx, sin(a) * ry).rotated(tilt) + centre
			# Keep the inner edge on the body's line.
			p.x = maxf(p.x, 0.0)
			pts.append(Vector2(p.x * side, p.y) * amount)
		return pts
