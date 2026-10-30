class_name Skyline
extends RefCounted
## Distant parallax layers: hazy city with the Olympic Stadium, back-street rooftops, backyard trees.

const HAZE := Color("#BCD0E4")
const AUTUMN := ["#C0392B", "#E67E22", "#F1C40F", "#D35400", "#9BAE4A"]


static func build(parent: Node, street_width: float, view_width: float) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	_clouds(parent, street_width, view_width, rng)
	_far_city(_layer(parent, 0.1), _span(0.1, street_width, view_width), rng)
	_rooftops(_layer(parent, 0.3), _span(0.3, street_width, view_width), rng)
	_backyard_trees(_layer(parent, 0.55), _span(0.55, street_width, view_width), rng)


static func _span(scroll: float, street_width: float, view_width: float) -> float:
	return view_width + scroll * (street_width - view_width) + 300.0


static func _layer(parent: Node, scroll: float) -> Parallax2D:
	var layer := Parallax2D.new()
	layer.scroll_scale = Vector2(scroll, 1.0)
	parent.add_child(layer)
	return layer


static func _clouds(parent: Node, street_width: float, view_width: float, rng: RandomNumberGenerator) -> void:
	var layer := _layer(parent, 0.04)
	var span := _span(0.04, street_width, view_width)
	for i in 7:
		var cloud := Cloud.new()
		cloud.position = Vector2(rng.randf_range(-200, span), rng.randf_range(60, 210))
		cloud.scale = Vector2.ONE * rng.randf_range(0.7, 1.3)
		cloud.speed = rng.randf_range(5.0, 12.0)
		cloud.span = Vector2(-300, span + 200)
		layer.add_child(cloud)


static func _poly(layer: Node, points: Array, color: Color) -> Polygon2D:
	var poly := Polygon2D.new()
	poly.polygon = PackedVector2Array(points)
	poly.color = color
	layer.add_child(poly)
	return poly


static func _far_city(layer: Parallax2D, span: float, rng: RandomNumberGenerator) -> void:
	var col := Color("#A9BBD2")
	var x := -200.0
	while x < span:
		var w := rng.randf_range(60, 160)
		var top := rng.randf_range(170, 240)
		_poly(layer, [Vector2(x, top), Vector2(x + w, top), Vector2(x + w, 560), Vector2(x, 560)], col.lerp(HAZE, rng.randf_range(0.0, 0.3)))
		x += w + rng.randf_range(-10, 30)
	_stadium(layer, 1250.0, col.darkened(0.06))
	_steeple(layer, 520.0, col.darkened(0.04))
	_steeple(layer, 1900.0, col.darkened(0.03))


# Olympic Stadium seen from Rosemont: low shell and the leaning mast with its cables.
static func _stadium(layer: Node, x: float, col: Color) -> void:
	_poly(layer, [Vector2(x - 40, 240), Vector2(x - 10, 214), Vector2(x + 80, 198), Vector2(x + 200, 196),
		Vector2(x + 300, 206), Vector2(x + 340, 226), Vector2(x + 350, 560), Vector2(x - 40, 560)], col)
	_poly(layer, [Vector2(x + 30, 224), Vector2(x + 82, 224), Vector2(x + 202, 64), Vector2(x + 178, 56)], col.darkened(0.08))
	_poly(layer, [Vector2(x + 168, 50), Vector2(x + 214, 58), Vector2(x + 208, 78), Vector2(x + 162, 70)], col.darkened(0.15))
	for i in 7:
		var line := Line2D.new()
		line.points = PackedVector2Array([Vector2(x + 120 + i * 9, 140 - i * 10), Vector2(x + 140 + i * 26, 200)])
		line.width = 1.2
		line.default_color = col.darkened(0.1)
		layer.add_child(line)


static func _steeple(layer: Node, x: float, col: Color) -> void:
	_poly(layer, [Vector2(x, 150), Vector2(x + 34, 150), Vector2(x + 34, 560), Vector2(x, 560)], col)
	_poly(layer, [Vector2(x - 2, 150), Vector2(x + 17, 70), Vector2(x + 36, 150)], col.darkened(0.06))
	_poly(layer, [Vector2(x + 15.5, 52), Vector2(x + 18.5, 52), Vector2(x + 18.5, 72), Vector2(x + 15.5, 72)], col.darkened(0.06))
	_poly(layer, [Vector2(x + 10, 58), Vector2(x + 24, 58), Vector2(x + 24, 61), Vector2(x + 10, 61)], col.darkened(0.06))


static func _rooftops(layer: Parallax2D, span: float, rng: RandomNumberGenerator) -> void:
	var x := -200.0
	while x < span:
		var w := rng.randf_range(120, 220)
		var top := rng.randf_range(185, 235)
		var col := Color("#8E9FB4").lerp(Color("#A88F86"), rng.randf_range(0.0, 0.5))
		_poly(layer, [Vector2(x, top), Vector2(x + w, top), Vector2(x + w, 560), Vector2(x, 560)], col)
		_poly(layer, [Vector2(x - 3, top - 6), Vector2(x + w + 3, top - 6), Vector2(x + w + 3, top), Vector2(x - 3, top)], col.darkened(0.12))
		if rng.randf() < 0.6:
			var cx := x + rng.randf_range(20, w - 30)
			_poly(layer, [Vector2(cx, top - 26), Vector2(cx + 14, top - 26), Vector2(cx + 14, top), Vector2(cx, top)], col.darkened(0.08))
		for wx in range(int(x) + 20, int(x + w) - 20, 44):
			_poly(layer, [Vector2(wx, top + 22), Vector2(wx + 18, top + 22), Vector2(wx + 18, top + 50), Vector2(wx, top + 50)], col.lerp(Color("#FFE2B0"), 0.25 if rng.randf() < 0.2 else 0.0).darkened(0.05))
		x += w


static func _backyard_trees(layer: Parallax2D, span: float, rng: RandomNumberGenerator) -> void:
	var x := -100.0
	while x < span:
		var base := Color(AUTUMN[rng.randi_range(0, AUTUMN.size() - 1)]).lerp(HAZE, 0.45)
		var cy := rng.randf_range(200, 250)
		for i in 6:
			var c := Vector2(x + rng.randf_range(-50, 50), cy + rng.randf_range(-40, 30))
			var r := rng.randf_range(30, 55)
			_circle(layer, c + Vector2(-6, 8), r, base.darkened(0.15))
			_circle(layer, c, r, base)
		x += rng.randf_range(160, 380)


static func _circle(layer: Node, c: Vector2, r: float, col: Color) -> void:
	var pts := []
	for i in 20:
		var a := TAU * i / 20.0
		pts.append(c + Vector2(cos(a), sin(a)) * r)
	_poly(layer, pts, col)
