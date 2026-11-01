class_name Cyclist
extends Node2D
## Someone riding by on a bicycle in the street's traffic lane: spinning spoked wheels, the cranks turning, the rider
## (helmet, top, trousers) leaning on the handlebars and pedalling. Rides `speed` px/s in `direction` and frees itself
## once past `until_x`. Drawn facing right in its own units (wheels on y = 0), mirrored for leftward riders.

const WHEEL_R := 34.0
const BASE := 92.0

var direction := 1.0
var speed := 250.0
var until_x := 0.0
var frame_color := Color("#2E86C1")
var top_color := Color("#E74C3C")
var pants_color := Color("#2E2E30")
var helmet_color := Color("#F1C40F")
var skin := Color("#E8B892")
var _turn := 0.0


static func random(rng: RandomNumberGenerator) -> Cyclist:
	var c := Cyclist.new()
	c.frame_color = Color(PropArt._pick(rng, PropArt.BIKE_COLORS))
	c.top_color = Color(PropArt._pick(rng, ["#E74C3C", "#3498DB", "#2ECC71", "#F39C12", "#9B59B6", "#ECF0F1", "#34495E"]))
	c.pants_color = Color(PropArt._pick(rng, ["#2E2E30", "#34495E", "#5D6D7E", "#7E5E3A"]))
	c.helmet_color = Color(PropArt._pick(rng, ["#F1C40F", "#E74C3C", "#FFFFFF", "#2ECC71", "#1F1F1F"]))
	c.skin = Color(PropArt._pick(rng, ["#F1D0B0", "#E8B892", "#C68E64", "#8D5A3B", "#5A3A26"]))
	c.speed = rng.randf_range(220.0, 300.0)
	return c


func _process(delta: float) -> void:
	position.x += direction * speed * delta
	_turn += delta * speed / (TAU * WHEEL_R * scale.y) * TAU
	if (direction > 0.0 and position.x > until_x) or (direction < 0.0 and position.x < until_x):
		queue_free()
	queue_redraw()


func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(direction, 1.0))
	var line := Color("#1F1F1F")
	var back := Vector2(-BASE / 2.0, -WHEEL_R)
	var front := Vector2(BASE / 2.0, -WHEEL_R)
	# Shadow on the asphalt.
	draw_set_transform(Vector2(0, 2), 0.0, Vector2(direction * 1.6, 0.18))
	draw_circle(Vector2.ZERO, 50.0, Color(0, 0, 0, 0.2))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(direction, 1.0))
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
	# Pedals round the crank, the chain ring.
	draw_arc(crank, 9.0, 0, TAU, 14, Color("#5E6268"), 2.5, true)
	var pedal := []
	for k in 2:
		var p := crank + Vector2.from_angle(_turn * 0.5 + k * PI) * 14.0
		pedal.append(p)
		draw_line(crank, p, Color("#5E6268"), 3.0, true)
	# The rider: hip on the saddle, the far leg (darker) then the near one, torso leaning to the bars, head and helmet.
	var hip := seat + Vector2(0, -6)
	for k in [1, 0]:
		var foot: Vector2 = pedal[k]
		var knee := _knee(hip, foot, 30.0, 30.0)
		var col := pants_color.darkened(0.25) if k == 1 else pants_color
		draw_line(hip, knee, col, 9.0, true)
		draw_circle(knee, 4.5, col)
		draw_line(knee, foot, col, 8.0, true)
		draw_line(foot + Vector2(-4, 0), foot + Vector2(8, 0), Color("#2B2B2B"), 5.0, true)
	var shoulder := hip + Vector2(26, -36)
	draw_line(hip, shoulder, top_color, 18.0, true)
	draw_circle(hip, 9.0, pants_color)
	draw_circle(shoulder, 9.0, top_color)
	draw_line(shoulder, head + Vector2(4, -13), top_color.darkened(0.1), 7.0, true)
	draw_circle(head + Vector2(6, -13), 4.0, skin)
	var face := shoulder + Vector2(10, -16)
	draw_circle(face, 11.0, skin)
	draw_circle(face + Vector2(5, -1), 1.6, Color("#2B2B33"))
	draw_arc(face + Vector2(-1, -2), 13.0, PI * 1.05, TAU * 0.98, 12, helmet_color, 7.0, true)
	draw_set_transform(Vector2.ZERO)


# Where the knee goes between hip and foot, thigh `a` and shin `b` long, bending forward.
func _knee(hip: Vector2, foot: Vector2, a: float, b: float) -> Vector2:
	var d := clampf(hip.distance_to(foot), 1.0, a + b - 0.5)
	var along := (a * a - b * b + d * d) / (2.0 * d)
	var up := sqrt(maxf(a * a - along * along, 0.0))
	var dir := (foot - hip) / hip.distance_to(foot)
	return hip + dir * along + Vector2(dir.y, -dir.x) * -up
