class_name Cyclist
extends Node2D
## Someone riding by on a bicycle in the street's traffic lane: spinning spoked wheels, the cranks turning, and the
## rider, a Character like everyone else (Character.riding: leaning on the bars, legs pedalling with the cranks). Rides
## `speed` px/s in `direction` and frees itself once past `until_x`. Drawn facing right in its own units (wheels on
## y = 0); the whole node is mirrored for leftward riders.

const WHEEL_R := 34.0
const BASE := 92.0

var direction := 1.0
var speed := 250.0
var until_x := 0.0
var frame_color := Color("#2E86C1")
var look: CharacterLook
var _rider: Character
var _turn := 0.0


static func random(rng: RandomNumberGenerator) -> Cyclist:
	var c := Cyclist.new()
	c.frame_color = Color(PropArt._pick(rng, PropArt.BIKE_COLORS))
	c.look = CharacterLook.random(rng, "adult" if rng.randf() < 0.7 else "teen")
	Season.dress_for_weather(c.look)
	c.speed = rng.randf_range(220.0, 300.0)
	return c


func _ready() -> void:
	scale.x = absf(scale.x) * direction
	_rider = Character.new()
	_rider.look = look
	_rider.riding = true
	# Hips on the saddle: the puppet's origin is its feet, its hips a leg's length above.
	_rider.scale = Vector2.ONE * StreetScene.CHAR_SCALE / absf(scale.y)
	add_child(_rider)
	_rider.position = Vector2(-12.0, -WHEEL_R - 50.0) + Vector2(0, float(_rider._rig.leg_len) * _rider.scale.y)


func _process(delta: float) -> void:
	position.x += direction * speed * delta
	_turn += delta * speed / (TAU * WHEEL_R * scale.y) * TAU
	if _rider:
		_rider.pedal = _turn * 0.5
	if (direction > 0.0 and position.x > until_x) or (direction < 0.0 and position.x < until_x):
		queue_free()
	queue_redraw()


func _draw() -> void:
	var line := Color("#1F1F1F")
	var back := Vector2(-BASE / 2.0, -WHEEL_R)
	var front := Vector2(BASE / 2.0, -WHEEL_R)
	# Shadow on the asphalt.
	draw_set_transform(Vector2(0, 2), 0.0, Vector2(1.6, 0.18))
	draw_circle(Vector2.ZERO, 50.0, Color(0, 0, 0, 0.2))
	draw_set_transform(Vector2.ZERO)
	for hub in [back, front]:
		draw_arc(hub, WHEEL_R, 0, TAU, 28, line, 4.0, true)
		draw_arc(hub, WHEEL_R - 3.0, 0, TAU, 28, Color("#8E9399"), 1.5, true)
		for k in 6:
			var a := _turn + TAU * k / 6.0
			draw_line(hub, hub + Vector2.from_angle(a) * (WHEEL_R - 3.0), Color("#B9BEC6"), 1.0)
		draw_circle(hub, 3.0, Color("#8E9399"))
	# The frame: chain stay, seat tube, top tube, down tube, fork; saddle and handlebars.
	var crank := Vector2(-4, -WHEEL_R + 2.0)
	var seat := Vector2(-14, -WHEEL_R - 46.0)
	var head := Vector2(BASE / 2.0 - 10.0, -WHEEL_R - 42.0)
	for seg in [[back, crank], [back, seat + Vector2(2, 6)], [crank, seat + Vector2(2, 6)], [seat + Vector2(4, 6), head], [crank, head], [head, front]]:
		draw_line(seg[0], seg[1], frame_color, 5.0, true)
	draw_line(seat + Vector2(-8, 0), seat + Vector2(10, 0), line, 5.0, true)
	draw_line(head, head + Vector2(-4, -12), line, 4.0, true)
	draw_line(head + Vector2(-4, -12), head + Vector2(8, -14), line, 4.0, true)
	# The chain ring and the pedals going round.
	draw_arc(crank, 9.0, 0, TAU, 14, Color("#5E6268"), 2.5, true)
	for k in 2:
		var p := crank + Vector2.from_angle(_turn * 0.5 + k * PI) * 14.0
		draw_line(crank, p, Color("#5E6268"), 3.0, true)
		draw_line(p + Vector2(-5, 0), p + Vector2(5, 0), Color("#2B2B2B"), 4.0, true)
