class_name UtilityPoles
extends Node2D
## The wooden utility poles along a street (or the lane) and the wires strung between them: weathered, tapering
## shafts with their grain, a crossarm of glass insulators (two on some), a transformer now and then, step bolts,
## an aluminium tag, staples and torn bits of old posters at eye level, a dark creosote foot; four line wires
## sagging pole to pole, a thicker cable lower down with its splice boxes, and service drops to the houses.
## One node draws them all (cheap: no transforms). Set `xs` (pole x, left to right) and `foot` before adding it.

const TOP := 70.0
const ARM_Y := 96.0
const CABLE_Y := 214.0
const WOOD := Color("#6E5B4A")

var xs: Array[float] = []
## y of the poles' feet.
var foot := 612.0
## Wires carry on this far past the first and last poles.
var width := 4000.0
## y where the service drops reach the houses (the roofline-ish), NAN for none (the lane).
var drop_y := 300.0
var seed_value := 1


func _draw() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var spans: Array[float] = [xs[0] - 760.0]
	spans.append_array(xs)
	spans.append(xs[-1] + 760.0)
	# Wires first, so the poles' tops sit over them.
	for w in 4:
		var y := ARM_Y - 4.0 + (w % 2) * 2.0
		var dx: float = [-38.0, -14.0, 14.0, 38.0][w]
		for i in spans.size() - 1:
			_wire(Vector2(spans[i] + dx, y), Vector2(spans[i + 1] + dx, y), 22.0 + w * 2.0, Color(0.1, 0.1, 0.12, 0.85), 1.4)
	for i in spans.size() - 1:
		var a := Vector2(spans[i] + 9.0, CABLE_Y)
		var b := Vector2(spans[i + 1] + 9.0, CABLE_Y)
		_wire(a, b, 30.0, Color(0.08, 0.08, 0.09, 0.95), 3.0)
		if rng.randf() < 0.5:
			var t := rng.randf_range(0.25, 0.75)
			var at := a.lerp(b, t) + Vector2(0, sin(t * PI) * 30.0)
			draw_rect(Rect2(at.x - 9, at.y - 2, 18, 9), Color("#3A3C40"))
			draw_rect(Rect2(at.x - 9, at.y - 2, 18, 3), Color("#55585C"))
	for x in xs:
		_pole(x, rng)


func _wire(a: Vector2, b: Vector2, sag: float, color: Color, w: float) -> void:
	var pts := PackedVector2Array()
	for k in 13:
		var t := k / 12.0
		pts.append(a.lerp(b, t) + Vector2(0, sin(t * PI) * sag))
	draw_polyline(pts, color, w, true)


func _pole(x: float, rng: RandomNumberGenerator) -> void:
	var winter := Season.is_winter()
	# Service drops from the cable down to the houses behind.
	if not is_nan(drop_y):
		for k in rng.randi_range(1, 2):
			var to := Vector2(x + rng.randf_range(70.0, 170.0) * (1.0 if rng.randf() < 0.5 else -1.0), drop_y + rng.randf_range(-20.0, 30.0))
			_wire(Vector2(x, CABLE_Y + 6.0), to, 10.0, Color(0.1, 0.1, 0.12, 0.8), 1.1)
	# The shaft: tapering, lit from the left, with its grain.
	var shaft := PackedVector2Array([Vector2(x - 5.5, TOP), Vector2(x + 5.5, TOP), Vector2(x + 8.0, foot), Vector2(x - 8.0, foot)])
	draw_colored_polygon(shaft, WOOD)
	draw_colored_polygon(PackedVector2Array([Vector2(x - 5.5, TOP), Vector2(x - 2.5, TOP), Vector2(x - 4.0, foot), Vector2(x - 8.0, foot)]), WOOD.lightened(0.18))
	draw_colored_polygon(PackedVector2Array([Vector2(x + 2.5, TOP), Vector2(x + 5.5, TOP), Vector2(x + 8.0, foot), Vector2(x + 4.0, foot)]), WOOD.darkened(0.25))
	for g in 5:
		var gx := rng.randf_range(-3.0, 3.0)
		var y0 := rng.randf_range(TOP + 20.0, foot - 200.0)
		draw_line(Vector2(x + gx, y0), Vector2(x + gx * 1.3, y0 + rng.randf_range(60.0, 180.0)), WOOD.darkened(0.35), 1.0)
	draw_colored_polygon(PackedVector2Array([Vector2(x - 7.6, foot - 50.0), Vector2(x + 7.6, foot - 50.0), Vector2(x + 8.0, foot), Vector2(x - 8.0, foot)]), Color("#3E3228"))
	draw_circle(Vector2(x, TOP), 5.5, WOOD.darkened(0.15))
	# Crossarms with their braces and insulators.
	var arms := [ARM_Y] if rng.randf() < 0.6 else [ARM_Y, ARM_Y + 34.0]
	for ay in arms:
		var half := 46.0 if ay == ARM_Y else 30.0
		draw_rect(Rect2(x - half, ay, half * 2.0, 7), Color("#5A4636"))
		draw_rect(Rect2(x - half, ay, half * 2.0, 2), Color("#7A6450"))
		draw_line(Vector2(x - 26, ay + 7), Vector2(x - 3, ay + 30), Color("#4A4A4E"), 2.0)
		draw_line(Vector2(x + 26, ay + 7), Vector2(x + 3, ay + 30), Color("#4A4A4E"), 2.0)
		var ins := [-38.0, -14.0, 14.0, 38.0] if ay == ARM_Y else [-22.0, 22.0]
		for ix in ins:
			var p := Vector2(x + ix, ay)
			draw_rect(Rect2(p.x - 1, p.y - 5, 2, 5), Color("#55585C"))
			draw_colored_polygon(PackedVector2Array([p + Vector2(-4, -5), p + Vector2(4, -5), p + Vector2(3, -11), p + Vector2(-3, -11)]), Color("#7FA9A0"))
			draw_circle(p + Vector2(0, -11), 3.0, Color("#9CC4BA"))
		if winter:
			draw_rect(Rect2(x - half, ay - 4, half * 2.0, 4), Color("#F4F6F8"))
	# A transformer, now and then, with its drop wires.
	if rng.randf() < 0.35:
		var t := Rect2(x + 7.0, ARM_Y + 46.0, 26, 46)
		draw_rect(t, Color("#7E8790"))
		draw_rect(Rect2(t.position.x, t.position.y, 7, t.size.y), Color("#98A1AA"))
		draw_rect(Rect2(t.position.x - 2, t.position.y - 5, 30, 6), Color("#5E6670"))
		for bx in [6.0, 18.0]:
			draw_line(Vector2(t.position.x + bx, t.position.y - 5), Vector2(t.position.x + bx - 10.0, ARM_Y + 2.0), Color(0.1, 0.1, 0.12, 0.9), 1.2)
		if winter:
			draw_rect(Rect2(t.position.x - 2, t.position.y - 9, 30, 4), Color("#F4F6F8"))
	# Step bolts, the aluminium tag, and what's left of years of stapled posters.
	var y := CABLE_Y + 40.0
	var side := 1.0
	while y < foot - 220.0:
		draw_rect(Rect2(x + side * 6.0 - (8.0 if side < 0.0 else 0.0), y, 8, 3), Color("#3A3A3A"))
		y += 34.0
		side = -side
	draw_rect(Rect2(x - 7, foot - 150, 14, 9), Color("#C9CDD2"))
	draw_rect(Rect2(x - 7, foot - 150, 14, 9), Color("#8E9399"), false, 1.0)
	for s in rng.randi_range(6, 14):
		var p := Vector2(x + rng.randf_range(-6.0, 6.0), rng.randf_range(foot - 140.0, foot - 60.0))
		draw_line(p, p + Vector2(3, 0), Color("#B9BEC6"), 1.0)
	for s in rng.randi_range(1, 3):
		var p := Vector2(x + rng.randf_range(-7.0, 1.0), rng.randf_range(foot - 135.0, foot - 75.0))
		var c: Color = [Color("#F4F1EA"), Color("#F2E39A"), Color("#F7C6D9"), Color("#BFE3F7")][rng.randi_range(0, 3)]
		draw_colored_polygon(PackedVector2Array([p, p + Vector2(rng.randf_range(5, 9), rng.randf_range(-2, 2)),
			p + Vector2(rng.randf_range(4, 8), rng.randf_range(5, 12)), p + Vector2(rng.randf_range(-1, 2), rng.randf_range(4, 9))]), Color(c, 0.85))
