class_name TrashBag
extends Node2D
## A garbage bag left on the sidewalk. A squirrel (`Squirrel.bag`) gnaws a hole in it to get at the food: `hole` grows from
## 0 to 1 while it works, and once it is big enough scraps spill out (a chip bag, a crust, an apple core, crumbs). When
## Charlotte scares the squirrel off, the torn bag stays as it is. Origin: the middle of the bag's foot, on the ground.
## Light from the upper left, like the rest of the street.

## Which side the squirrel works on (-1: left of the bag, 1: right) and how far its middle sits from the bag's.
var side := 1.0
const SQUIRREL_GAP := 34.0
## Height of the hole above the ground.
const HOLE_Y := -17.0
## 0..1, how much of the hole is gnawed.
var hole := 0.0:
	set(value):
		hole = value
		queue_redraw()
var plastic := Color("#25262B")
var seed_value := 1

var _jag := PackedFloat32Array()
var _items: Array[int] = []


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	for i in 14:
		_jag.append(rng.randf_range(0.72, 1.28))
	# Two of the three kinds of scraps come out (chip bag, crust, apple core).
	var kinds := [0, 1, 2]
	kinds.remove_at(rng.randi() % 3)
	for k in kinds:
		_items.append(k)
	if rng.randf() < 0.3:
		plastic = Color("#26382C")


## The spot a squirrel stands at to work on the hole.
func work_x() -> float:
	return position.x + side * SQUIRREL_GAP


func _draw() -> void:
	# Contact shadow on the pavement, thrown to the right.
	draw_set_transform(Vector2(7, 1), 0.0, Vector2(1.0, 0.2))
	draw_circle(Vector2.ZERO, 34, Color(0, 0, 0, 0.22))
	draw_set_transform(Vector2.ZERO)
	var body := PackedVector2Array([
		Vector2(-23, 0), Vector2(-29, -14), Vector2(-30, -30), Vector2(-25, -46), Vector2(-15, -57), Vector2(-7, -63),
		Vector2(-4, -68), Vector2(4, -68), Vector2(7, -63), Vector2(15, -57), Vector2(26, -45), Vector2(31, -29),
		Vector2(29, -13), Vector2(23, 0)])
	var rim := body.duplicate()
	draw_colored_polygon(body, plastic.darkened(0.35))
	# The bag is a little smaller inside its outline so the edge reads darker.
	var inner := PackedVector2Array()
	for p in rim:
		inner.append(Vector2(p.x * 0.94, (p.y + 2.0) * 0.96))
	draw_colored_polygon(inner, plastic)
	# Sheen from the upper left, soft folds and a lighter belly.
	draw_colored_polygon(PackedVector2Array([
		Vector2(-22, -14), Vector2(-24, -30), Vector2(-20, -44), Vector2(-12, -53), Vector2(-9, -44), Vector2(-14, -30), Vector2(-14, -14)]),
		Color(1, 1, 1, 0.16))
	draw_colored_polygon(PackedVector2Array([
		Vector2(-18, -48), Vector2(-12, -55), Vector2(-8, -52), Vector2(-13, -44)]), Color(1, 1, 1, 0.22))
	for fold in [[Vector2(2, -63), Vector2(8, -42), Vector2(5, -20)], [Vector2(-3, -60), Vector2(-8, -38), Vector2(-4, -12)], [Vector2(12, -52), Vector2(19, -36), Vector2(17, -16)]]:
		draw_polyline(PackedVector2Array(fold), Color(0, 0, 0, 0.35), 1.6, true)
	# Shade toward the right and the base.
	draw_colored_polygon(PackedVector2Array([
		Vector2(16, -50), Vector2(26, -44), Vector2(30, -29), Vector2(28, -13), Vector2(22, -2), Vector2(18, -2), Vector2(22, -14), Vector2(23, -30)]),
		Color(0, 0, 0, 0.3))
	# The knot: the twisted neck and two floppy ears.
	draw_colored_polygon(PackedVector2Array([Vector2(-5, -65), Vector2(-3, -75), Vector2(3, -75), Vector2(5, -65)]), plastic.darkened(0.2))
	draw_colored_polygon(PackedVector2Array([Vector2(-3, -74), Vector2(-13, -82), Vector2(-16, -77), Vector2(-7, -70)]), plastic)
	draw_colored_polygon(PackedVector2Array([Vector2(3, -74), Vector2(14, -80), Vector2(15, -73), Vector2(7, -69)]), plastic)
	draw_polyline(PackedVector2Array([Vector2(-5, -68), Vector2(5, -70)]), Color(1, 1, 1, 0.3), 1.3, true)
	draw_polyline(PackedVector2Array([Vector2(-12, -81), Vector2(-5, -73)]), Color(1, 1, 1, 0.25), 1.2, true)
	_draw_spill()
	_draw_hole()


# The ragged hole in the side the squirrel works on (a slit first, then a gap with torn, paler lips).
func _draw_hole() -> void:
	if hole <= 0.02:
		return
	var rx := 2.5 + 9.0 * hole
	var ry := 1.8 + 8.5 * hole
	var c := Vector2(side * (26.0 - 5.0 * hole), HOLE_Y)
	var lip := PackedVector2Array()
	var inside := PackedVector2Array()
	for i in _jag.size():
		var a := TAU * i / _jag.size()
		var j := _jag[i]
		lip.append(c + Vector2(cos(a) * rx * j * 1.22, sin(a) * ry * j * 1.22))
		inside.append(c + Vector2(cos(a) * rx * j, sin(a) * ry * j))
	draw_colored_polygon(lip, plastic.lightened(0.28))
	draw_colored_polygon(inside, Color("#08080A"))
	# A few threads of plastic hanging in it.
	if hole > 0.4:
		draw_line(c + Vector2(-rx * 0.5, -ry * 0.6), c + Vector2(-rx * 0.1, ry * 0.2), plastic.lightened(0.4), 1.1)
		draw_line(c + Vector2(rx * 0.4, -ry * 0.7), c + Vector2(rx * 0.7, ry * 0.1), plastic.lightened(0.4), 1.1)


# What came out of the hole: only once it is big enough, spread on the ground on that side.
func _draw_spill() -> void:
	if hole < 0.35:
		return
	var out := clampf((hole - 0.35) / 0.65, 0.0, 1.0)
	var x0 := side * 30.0
	var item_at := [x0 + side * 9.0, x0 + side * 22.0, x0 + side * 34.0]
	for n in _items.size():
		if out * 2.2 < n * 0.6 + 0.3:
			continue
		var x: float = item_at[n] * (0.7 + 0.3 * minf(out * 2.0, 1.0))
		match _items[n]:
			0:
				# A crumpled chip bag, red with a yellow band.
				draw_colored_polygon(PackedVector2Array([Vector2(x - 8, 0), Vector2(x - 9, -6), Vector2(x - 5, -9), Vector2(x, -7), Vector2(x + 5, -9), Vector2(x + 9, -5), Vector2(x + 8, 0)]), Color("#C8352B"))
				draw_colored_polygon(PackedVector2Array([Vector2(x - 8, -3), Vector2(x - 6, -6), Vector2(x + 5, -6), Vector2(x + 8, -3)]), Color("#F2C230"))
				draw_polyline(PackedVector2Array([Vector2(x - 7, -8), Vector2(x - 3, -4), Vector2(x + 1, -8)]), Color(1, 1, 1, 0.35), 1.0)
			1:
				# A bread crust.
				draw_colored_polygon(PackedVector2Array([Vector2(x - 8, 0), Vector2(x - 9, -4), Vector2(x - 4, -7), Vector2(x + 5, -7), Vector2(x + 9, -3), Vector2(x + 8, 0)]), Color("#B9803F"))
				draw_colored_polygon(PackedVector2Array([Vector2(x - 6, -1), Vector2(x - 5, -4), Vector2(x + 4, -5), Vector2(x + 6, -1)]), Color("#E8CF9B"))
			_:
				# An apple core, gnawed.
				draw_colored_polygon(PackedVector2Array([Vector2(x - 4, 0), Vector2(x - 6, -4), Vector2(x - 3, -6), Vector2(x - 1, -4), Vector2(x + 1, -6), Vector2(x + 5, -4), Vector2(x + 4, 0)]), Color("#EDE3B5"))
				draw_polyline(PackedVector2Array([Vector2(x - 6, -4), Vector2(x - 4, -1)]), Color("#C9453A"), 1.6)
				draw_line(Vector2(x, -4), Vector2(x + 1, -9), Color("#5B3A22"), 1.2)
	# Crumbs.
	for k in 6:
		var cx := side * (26.0 + float(k) * 6.5 + 4.0 * _jag[k])
		draw_circle(Vector2(cx * (0.7 + 0.3 * minf(out * 2.0, 1.0)), -0.8), 1.1, Color("#D8B67A"))
