class_name BallKid
extends Node2D
## A neighbourhood child playing with a ball in the lane: bouncing it in front of her, slapping it back down with her
## hand at the top of each bounce. Click her and she says something.

const LINES := ["Tu veux jouer au ballon ?", "Attrape !", "J'ai compté jusqu'à cinquante !", "On joue à la tague tantôt ?"]

var look: CharacterLook
var ball_color := Color("#E74C3C")
var _kid: Character
var _ball: Node2D
var _t := 0.0
var _line := 0


func _ready() -> void:
	_kid = Character.new()
	_kid.look = look
	add_child(_kid)
	_ball = _Ball.new()
	_ball.kid = self
	add_child(_ball)
	add_to_group("interactable")


func _process(delta: float) -> void:
	_t += delta
	# Bouncing: the hand pats the ball down near the top of each bounce.
	if absf(sin(_t * 3.2)) > 0.85:
		_kid.pet(0.1, 0.0)
	_ball.queue_redraw()


func ball_position() -> Vector2:
	return Vector2(70.0, -30.0 - absf(sin(_t * 3.2)) * 190.0)


func can_interact() -> bool:
	return true


func hit_test(p: Vector2) -> bool:
	return Rect2(global_position + Vector2(-40, -170) * scale, Vector2(130, 170) * scale).has_point(p)


func approach_x(from_x: float) -> float:
	return global_position.x + (90.0 if from_x > global_position.x else -60.0)


func reserve() -> void:
	pass


func release() -> void:
	pass


func interact(_who: Character) -> void:
	Bubble.say(get_parent(), global_position + Vector2(0, -200), LINES[_line % LINES.size()], 2.6)
	_line += 1


class _Ball:
	extends Node2D
	var kid: BallKid

	func _draw() -> void:
		var p := kid.ball_position()
		var h := -p.y
		draw_set_transform(Vector2(70, 2), 0.0, Vector2(1.0, 0.25))
		draw_circle(Vector2.ZERO, 26.0 - h * 0.05, Color(0, 0, 0, 0.18))
		draw_set_transform(Vector2.ZERO)
		draw_circle(p, 26.0, kid.ball_color)
		draw_arc(p, 26.0, 0, TAU, 24, kid.ball_color.darkened(0.35), 3.0, true)
		draw_arc(p + Vector2(-26, 0), 30.0, -0.9, 0.9, 10, Color(1, 1, 1, 0.8), 3.0, true)
		draw_circle(p + Vector2(-9, -10), 6.0, Color(1, 1, 1, 0.45))
