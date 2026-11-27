class_name Alyzee
extends Node2D
## Alyzée, seven, new at Charlotte's school (`CharacterLook.alyzee()`): at recess she sits alone on the bench in the schoolyard
## (scenes/cour_ecole.gd), her eyes on her boots. The first click is the meeting (`flags.met_alyzee`, the notebook's friends
## page): they talk, then she jumps up and they play tag across the yard, and when the game is over the scene rings the bell
## (`played`). After that a click gets one of her lines. The node is scaled like the street's people; its Character is not.

signal played

const FLAG := "met_alyzee"
## The top of her head, in the Character's own units, standing and sitting.
const HEAD := -330.0
const HEAD_SITTING := -270.0
## The bench's seat above the yard, in the Character's own units (her hips rest there, her feet on the ground).
const SEAT_H := 68.0
const MEETING := [
	[-1, "Allô ! Pourquoi t'es toute seule ?"],
	[0, "Chu nouvelle… Je connais personne encore."],
	[-1, "Moi, c'est Charlotte.\nMais tout le monde m'appelle Chachoue !"],
	[0, "Moi, c'est Alyzée. Avec un y et un z !"],
	[-1, "Veux-tu jouer avec moi ?"],
	[0, "Oui ! Ben oui !"],
]
const LINES := ["Salut, Chachoue !", "On vient d'arriver dans le quartier.", "T'es ma première amie dans le quartier, tsé !", "Demain, on joue encore à la tague ?",
	"J'ai un chat qui s'appelle Biscotte !", "Ma maîtresse est très gentille !"]

## The scene's PlayerControl: Charlotte is left to the script while they talk and play.
var control: PlayerControl
## Where she may run while they play tag (world x).
var bounds := Vector2(0, 2600)
var kid: Character
var _charlotte: Character
var _talking := false
var _line := 0


func _ready() -> void:
	var look := CharacterLook.alyzee()
	Season.dress_for_weather(look)
	kid = Character.new()
	kid.look = look
	kid.fidgets = true
	add_child(kid)
	add_to_group("interactable")
	if not met():
		# Alone on the bench, a little sad.
		kid.seat_h = SEAT_H
		kid.sitting = true
		kid.facing = -1
		kid.expression = "sad"


static func met() -> bool:
	return GameState.flags.get(FLAG, false)


## She has something to say and isn't saying it yet (the "!" over her).
func waiting() -> bool:
	return (not met() or FriendBracelet.has_pending(["alyzee"]) or Valentine.step() == 2 and "alyzee" in Valentine.friends_left()) and not _talking


func head() -> Vector2:
	return global_position + Vector2(0, HEAD_SITTING if kid.sitting else HEAD) * scale


func can_interact() -> bool:
	return not _talking


func hit_test(p: Vector2) -> bool:
	var top := HEAD_SITTING if kid.sitting else HEAD
	return Rect2(global_position + Vector2(-70, top) * scale, Vector2(140, -top) * scale).has_point(p)


func approach_x(from_x: float) -> float:
	var side := 1.0 if from_x > global_position.x else -1.0
	return global_position.x + side * 190.0 * scale.x


func focus_x() -> float:
	return global_position.x


func reserve() -> void:
	pass


func release() -> void:
	pass


func interact(who: Character) -> void:
	_charlotte = who
	kid.facing = 1 if who.position.x > global_position.x else -1
	if met() and FriendBracelet.give(kid, "alyzee", func(t: String) -> void: _say(0, t), who):
		return
	if met() and Valentine.give(kid, "alyzee", func(t: String) -> void: _say(0, t)):
		return
	if met():
		_say(0, LINES[_line % LINES.size()])
		_line += 1
		return
	_meet()


func _meet() -> void:
	_talking = true
	if control:
		control.hands_off = true
	kid.expression = ""
	var steps := create_tween()
	for step: Array in MEETING:
		var text: String = step[1]
		steps.tween_callback(_say.bind(step[0], text))
		steps.tween_interval(Bubble.reading_time(text, 2.0) + 0.2)
	steps.tween_callback(func() -> void:
		GameState.flags[FLAG] = true
		Notebook.new_friend(FLAG)
		kid.express("happy", 2.0)
		_charlotte.express("happy", 2.0))
	_play_tag(steps)


# They play tag: she jumps off the bench, "Tague !", and runs off; Charlotte runs after her, catches her, and it is Alyzée's
# turn to chase her back. Then they stop, out of breath and laughing, and the scene rings the bell.
func _play_tag(steps: Tween) -> void:
	var x0 := global_position.x
	var far := clampf(x0 + 440.0, bounds.x, bounds.y)
	var back := clampf(x0 - 260.0, bounds.x, bounds.y)
	steps.tween_callback(func() -> void: kid.sitting = false)
	steps.tween_interval(0.7)
	steps.tween_callback(_say.bind(0, "Tague ! C'est toi qui l'as !"))
	steps.tween_interval(0.5)
	_dash(steps, far, far - 70.0, 1.6)
	steps.tween_callback(_say.bind(-1, "Tague ! C'est toi !"))
	steps.tween_interval(0.9)
	steps.tween_callback(_say.bind(0, "Ah non ! Je t'attrape !"))
	_dash(steps, back + 60.0, back, 1.9)
	steps.tween_callback(func() -> void:
		kid.facing = -1
		_charlotte.facing = 1
		kid.express("laugh", 2.2)
		_charlotte.express("laugh", 2.2))
	steps.tween_callback(_say.bind(0, "Tague ! Hi hi hi !"))
	steps.tween_interval(2.4)
	steps.tween_callback(func() -> void:
		_talking = false
		played.emit())


# Both run: she to `to_x`, Charlotte after her to `charlotte_x`, a little behind.
func _dash(steps: Tween, to_x: float, charlotte_x: float, secs: float) -> void:
	steps.tween_callback(func() -> void:
		for who: Character in [kid, _charlotte]:
			who.is_walking = true
			who.running = true
		kid.facing = 1 if to_x > global_position.x else -1
		_charlotte.facing = 1 if charlotte_x > _charlotte.position.x else -1)
	steps.tween_property(self, "position:x", to_x, secs).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	steps.parallel().tween_property(_charlotte, "position:x", charlotte_x, secs + 0.15).set_delay(0.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	steps.tween_callback(func() -> void:
		for who: Character in [kid, _charlotte]:
			who.is_walking = false
			who.running = false)


## She walks to `x` (the school's door) at Charlotte's pace.
func walk_to(x: float, secs: float) -> Tween:
	var t := create_tween()
	t.tween_callback(func() -> void:
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
