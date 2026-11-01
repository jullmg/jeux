class_name JumpRopeKid
extends Node2D
## A neighbourhood child skipping rope on the sidewalk: the rope swings round from hand to hand (behind her, over her
## head, then in front and under her feet as she hops). Click her and she says something.

const LINES := ["Salut ! Je saute à la corde !", "Tu sais compter jusqu'à cent ?", "Un, deux, trois, quatre…", "Viens jouer tantôt !"]

var look: CharacterLook
var _kid: Character
var _behind: Node2D
var _front: Node2D
var _phase := 0.0
var _line := 0


func _ready() -> void:
	_behind = _Rope.new()
	_behind.kid = self
	_behind.front = false
	add_child(_behind)
	_kid = Character.new()
	_kid.look = look
	add_child(_kid)
	_front = _Rope.new()
	_front.kid = self
	_front.front = true
	add_child(_front)
	add_to_group("interactable")


func _process(delta: float) -> void:
	_phase = fmod(_phase + delta * TAU * 1.1, TAU)
	# She hops as the rope comes under her feet (phase near 0).
	var low := maxf(cos(_phase), 0.0)
	_kid.position.y = -pow(low, 3.0) * 34.0
	_behind.queue_redraw()
	_front.queue_redraw()


func rope_points() -> Array:
	var hand := to_local(_kid.hand_position())
	var left := Vector2(-absf(hand.x) - 18.0, hand.y)
	var right := Vector2(absf(hand.x) + 18.0, hand.y)
	# The middle of the rope swings round a circle seen edge-on: down at phase 0, up at PI.
	var mid := (left + right) / 2.0 + Vector2(0, cos(_phase) * 260.0 - 60.0)
	return [left, mid, right]


func can_interact() -> bool:
	return true


func hit_test(p: Vector2) -> bool:
	return Rect2(global_position + Vector2(-40, -170) * scale, Vector2(80, 170) * scale).has_point(p)


func approach_x(from_x: float) -> float:
	return global_position.x + (60.0 if from_x > global_position.x else -60.0)


func reserve() -> void:
	pass


func release() -> void:
	pass


func interact(_who: Character) -> void:
	Bubble.say(get_parent(), global_position + Vector2(0, -200), LINES[_line % LINES.size()], 2.6)
	_line += 1


class _Rope:
	extends Node2D
	var kid: JumpRopeKid
	var front := false

	func _draw() -> void:
		var in_front := cos(kid._phase) > 0.0
		if in_front != front:
			return
		var pts: Array = kid.rope_points()
		var line := PackedVector2Array()
		for k in 17:
			var t := k / 16.0
			line.append(pts[0].lerp(pts[1], t).lerp(pts[1].lerp(pts[2], t), t))
		draw_polyline(line, Color("#E85FA0"), 9.0, true)
		for p in [pts[0], pts[2]]:
			draw_rect(Rect2(p - Vector2(8, 18), Vector2(16, 36)), Color("#F2C230"))
