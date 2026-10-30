class_name Street
extends Node2D
## Sidewalk, curb, gutter full of fallen leaves and asphalt, drawn once.

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
	draw_rect(Rect2(0, ROAD, width, BOTTOM - ROAD), Color("#5E5D5B"))
	draw_rect(Rect2(0, ROAD, width, 6), Color("#4A4947"))
	for n in int(width / 3.0):
		draw_rect(Rect2(rng.randf_range(0, width), rng.randf_range(ROAD + 6, BOTTOM), 2, 2), Color("#6E6D6A") if rng.randf() < 0.5 else Color("#4F4E4C"))
	for gx in range(400, int(width), 900):
		draw_rect(Rect2(gx, ROAD + 1, 46, 9), Color("#3A3938"))
		for k in 6:
			draw_line(Vector2(gx + 4 + k * 7, ROAD + 2), Vector2(gx + 4 + k * 7, ROAD + 9), Color("#6E6D6A"), 1.5)
	_leaves(rng, width / 9.0, TOP + 4, CURB - 2)
	_leaves(rng, width / 4.0, ROAD - 2, ROAD + 12)


func _leaves(rng: RandomNumberGenerator, count: float, y0: float, y1: float) -> void:
	for n in int(count):
		var p := Vector2(rng.randf_range(0, width), rng.randf_range(y0, y1))
		draw_set_transform(p, rng.randf_range(0, PI), Vector2(1.0, 0.5))
		var c: Color = LEAVES[rng.randi_range(0, LEAVES.size() - 1)]
		draw_circle(Vector2.ZERO, rng.randf_range(3.0, 5.5), c)
		draw_line(Vector2(-4, 0), Vector2(4, 0), c.darkened(0.3), 0.8)
	draw_set_transform(Vector2.ZERO)
