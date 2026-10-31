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
	_stadium(layer, 1180.0, col.darkened(0.06))
	_steeple(layer, 520.0, col.darkened(0.04))
	_steeple(layer, 1900.0, col.darkened(0.03))


# Olympic Stadium seen from Rosemont: the ribbed oval bowl under its roof, and the inclined tower curving
# up over it, crowned by the observatory, with the roof cables fanning down. Lit from the low sun on the left.
static func _stadium(layer: Node, x: float, col: Color) -> void:
	var lit := col.lightened(0.12)
	var shade := col.darkened(0.12)
	# Bowl: a low oval whose top bulges up in the middle, with the concrete consoles as ribs.
	var bowl := [Vector2(x + 20, 560)]
	for i in 25:
		var t := i / 24.0
		bowl.append(Vector2(x + 20 + t * 420.0, 236.0 - sin(t * PI) * 34.0))
	bowl.append(Vector2(x + 440, 560))
	_poly(layer, bowl, col)
	for i in 15:
		var t := (i + 0.5) / 15.0
		var top := Vector2(x + 20 + t * 420.0, 236.0 - sin(t * PI) * 34.0)
		var lean := (t - 0.5) * 18.0
		_poly(layer, [top + Vector2(-5, 2), top + Vector2(5, 2), top + Vector2(5 + lean, 60), top + Vector2(-5 + lean, 60)], lit if t < 0.5 else shade)
	# Roof membrane: a flatter, slightly darker oval sitting inside the rim.
	var roof := []
	for i in 21:
		var t := i / 20.0
		roof.append(Vector2(x + 60 + t * 340.0, 214.0 - sin(t * PI) * 30.0))
	for i in 21:
		var t := 1.0 - i / 20.0
		roof.append(Vector2(x + 60 + t * 340.0, 214.0 - sin(t * PI) * 22.0 + 6.0))
	_poly(layer, roof, col.darkened(0.06))
	# Tower: a wedge rising from the left end of the bowl, wide at the base, tapering as it curves over.
	var back := []
	var front := []
	for i in 17:
		var t := i / 16.0
		back.append(_bezier(Vector2(x - 60, 260), Vector2(x - 14, 116), Vector2(x + 140, 58), t))
		front.append(_bezier(Vector2(x + 80, 260), Vector2(x + 84, 160), Vector2(x + 180, 96), t))
	# Sunlit back face (the left third) and the funicular track along it.
	var spine := []
	for i in 17:
		spine.append(back[i].lerp(front[i], 0.35))
	var body := back.duplicate()
	var underside := front.duplicate()
	underside.reverse()
	_poly(layer, body + underside, col.darkened(0.03))
	var face := back.duplicate()
	var inner := spine.duplicate()
	inner.reverse()
	_poly(layer, face + inner, lit)
	var track := Line2D.new()
	track.points = PackedVector2Array(spine)
	track.width = 1.5
	track.default_color = shade
	layer.add_child(track)
	# Observatory at the top: a wider block with a band of windows.
	_poly(layer, [Vector2(x + 140, 56), Vector2(x + 196, 70), Vector2(x + 190, 102), Vector2(x + 168, 104), Vector2(x + 136, 80)], col.darkened(0.1))
	_poly(layer, [Vector2(x + 146, 64), Vector2(x + 192, 76), Vector2(x + 190, 84), Vector2(x + 144, 72)], col.lightened(0.3))
	_poly(layer, [Vector2(x + 140, 56), Vector2(x + 196, 70), Vector2(x + 194, 74), Vector2(x + 139, 60)], lit)
	# Roof cables fanning from the tower's underside down to the rim.
	for i in 9:
		var from: Vector2 = front[3 + i]
		var line := Line2D.new()
		line.points = PackedVector2Array([from, Vector2(x + 110 + i * 34.0, 206.0 - sin((0.15 + i * 0.09) * PI) * 22.0)])
		line.width = 1.0
		line.default_color = Color(shade, 0.8)
		layer.add_child(line)


static func _bezier(a: Vector2, b: Vector2, c: Vector2, t: float) -> Vector2:
	return a.lerp(b, t).lerp(b.lerp(c, t), t)


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
