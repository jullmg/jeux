class_name Street
extends Node2D
## Sidewalk, curb, gutter full of fallen leaves and asphalt (patches, cracks, manholes, puddles), drawn once.

const TOP := 590.0
const CURB := 662.0
const ROAD := 670.0
const BOTTOM := 720.0
const LEAVES := [Color("#D9682B"), Color("#B5442E"), Color("#E3A33A"), Color("#C9562E"), Color("#8E3A24"), Color("#E8C04A")]

var width := 2000.0


func _draw() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 99
	draw_rect(Rect2(0, TOP, width, CURB - TOP), Color("#D3CEC5"))
	var x := 0.0
	var i := 0
	while x < width:
		var tone := Color("#D7D2C9") if i % 2 == 0 else Color("#CFCAC0")
		draw_colored_polygon(PackedVector2Array([Vector2(x, TOP), Vector2(x + 96, TOP), Vector2(x + 82, CURB), Vector2(x - 14, CURB)]), tone)
		draw_line(Vector2(x, TOP), Vector2(x - 14, CURB), Color("#B9B3A9"), 2.0)
		x += 96.0
		i += 1
	draw_line(Vector2(0, 627), Vector2(width, 627), Color("#BDB7AD", 0.6), 1.5)
	var ao := PackedColorArray([Color(0.2, 0.12, 0.08, 0.28), Color(0.2, 0.12, 0.08, 0.28), Color(0.2, 0.12, 0.08, 0.0), Color(0.2, 0.12, 0.08, 0.0)])
	draw_polygon(PackedVector2Array([Vector2(0, TOP), Vector2(width, TOP), Vector2(width, TOP + 18), Vector2(0, TOP + 18)]), ao)
	draw_rect(Rect2(0, CURB, width, ROAD - CURB), Color("#BDB6AB"))
	draw_line(Vector2(0, CURB), Vector2(width, CURB), Color("#E2DDD4"), 2.0)
	var asphalt := PackedColorArray([Color("#555452"), Color("#555452"), Color("#64635F"), Color("#64635F")])
	draw_polygon(PackedVector2Array([Vector2(0, ROAD), Vector2(width, ROAD), Vector2(width, BOTTOM), Vector2(0, BOTTOM)]), asphalt)
	draw_rect(Rect2(0, ROAD, width, 6), Color("#4A4947"))
	_road_details(rng)
	for n in int(width / 3.0):
		draw_rect(Rect2(rng.randf_range(0, width), rng.randf_range(ROAD + 6, BOTTOM), 2, 2), Color("#6E6D6A") if rng.randf() < 0.5 else Color("#4F4E4C"))
	for gx in range(400, int(width), 900):
		draw_rect(Rect2(gx, ROAD + 1, 46, 9), Color("#3A3938"))
		for k in 6:
			draw_line(Vector2(gx + 4 + k * 7, ROAD + 2), Vector2(gx + 4 + k * 7, ROAD + 9), Color("#6E6D6A"), 1.5)
	_leaves(rng, width / 9.0, TOP + 4, CURB - 2)
	_leaves(rng, width / 4.0, ROAD - 2, ROAD + 12)
	# Drifts the wind piled against the curb.
	for n in int(width / 420.0):
		var x0 := rng.randf_range(0, width)
		for k in 26:
			var p := Vector2(x0 + rng.randf_range(-30, 30), ROAD + 4 + absf(rng.randfn(0.0, 3.0)))
			draw_set_transform(p, rng.randf_range(0, PI), Vector2(1.0, 0.5))
			var c: Color = LEAVES[rng.randi_range(0, LEAVES.size() - 1)]
			draw_circle(Vector2.ZERO, rng.randf_range(3.5, 6.0), c)
		draw_set_transform(Vector2.ZERO)


func _leaves(rng: RandomNumberGenerator, count: float, y0: float, y1: float) -> void:
	for n in int(count):
		var p := Vector2(rng.randf_range(0, width), rng.randf_range(y0, y1))
		draw_set_transform(p, rng.randf_range(0, PI), Vector2(1.0, 0.5))
		var c: Color = LEAVES[rng.randi_range(0, LEAVES.size() - 1)]
		draw_circle(Vector2.ZERO, rng.randf_range(3.0, 5.5), c)
		draw_line(Vector2(-4, 0), Vector2(4, 0), c.darkened(0.3), 0.8)
	draw_set_transform(Vector2.ZERO)


func _road_details(rng: RandomNumberGenerator) -> void:
	# Repair patches and cracks.
	var x := rng.randf_range(100, 400)
	while x < width:
		var w := rng.randf_range(90, 220)
		var y := rng.randf_range(ROAD + 10, BOTTOM - 14)
		draw_rect(Rect2(x, y, w, rng.randf_range(14, 30)), Color("#4C4B49", 0.7))
		var crack := PackedVector2Array()
		var c := Vector2(x + w + rng.randf_range(60, 200), rng.randf_range(ROAD + 8, BOTTOM - 4))
		for k in 6:
			crack.append(c)
			c += Vector2(rng.randf_range(10, 22), rng.randf_range(-4, 4))
		draw_polyline(crack, Color("#3E3D3B"), 1.2, true)
		x += rng.randf_range(450, 800)
	# Worn painted line along the parking lane.
	var lx := 0.0
	while lx < width:
		var seg := rng.randf_range(40, 160)
		draw_line(Vector2(lx, 703), Vector2(lx + seg, 703), Color("#E8E4D8", rng.randf_range(0.25, 0.55)), 3.0)
		lx += seg + rng.randf_range(0, 14)
	# Manhole covers and puddles reflecting the sky.
	var mx := rng.randf_range(300, 700)
	while mx < width:
		draw_set_transform(Vector2(mx, 692), 0.0, Vector2(1.0, 0.3))
		draw_circle(Vector2.ZERO, 24, Color("#3A3938"))
		draw_circle(Vector2.ZERO, 21, Color("#5A5753"))
		for r in [7.0, 14.0]:
			draw_arc(Vector2.ZERO, r, 0, TAU, 24, Color("#3E3C39"), 2.0)
		draw_set_transform(Vector2.ZERO)
		mx += rng.randf_range(900, 1500)
	var px := rng.randf_range(500, 900)
	while px < width:
		var p := Vector2(px, rng.randf_range(ROAD + 14, BOTTOM - 10))
		var r := rng.randf_range(26, 46)
		draw_set_transform(p, 0.0, Vector2(1.0, 0.22))
		draw_circle(Vector2.ZERO, r + 3, Color("#4A4947"))
		draw_circle(Vector2.ZERO, r, Color("#7E9FC2"))
		draw_circle(Vector2(-r * 0.25, -r * 0.3), r * 0.55, Color("#B9D0E6", 0.7))
		draw_circle(Vector2(r * 0.3, r * 0.1), r * 0.3, Color("#F4D9B8", 0.45))
		draw_set_transform(Vector2.ZERO)
		px += rng.randf_range(700, 1300)
