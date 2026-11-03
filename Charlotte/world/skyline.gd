class_name Skyline
extends RefCounted
## Distant parallax layers: hazy city with one church steeple, back-street rooftops, backyard trees.

const HAZE := Color("#BCD0E4")
const TREE_KINDS := 4
const TREE_W := 340
const TREE_FOOT := 590
const TREE_CROWN := 210.0
## They are drawn small and scaled up: they are far off, a little soft is right.
const TREE_RASTER := 0.6

static var _trees := {}


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
	# One church, seen only toward the far end of the long streets.
	_steeple(layer, 1700.0, col.darkened(0.03))


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


# The trees of the yards behind the buildings: a few real trees, hazy with distance (limbs and clumps of leaves, bare in winter),
# their trunks hidden behind the houses. Drawn once per season, then shared by every scene.
static func _backyard_trees(layer: Parallax2D, span: float, rng: RandomNumberGenerator) -> void:
	var pictures := _tree_pictures()
	var x := -100.0
	while x < span:
		var tree := Sprite2D.new()
		tree.texture = pictures[rng.randi_range(0, pictures.size() - 1)]
		tree.centered = false
		var k := rng.randf_range(0.62, 0.85)
		var pixel := k / TREE_RASTER
		tree.scale = Vector2(pixel if rng.randf() < 0.5 else -pixel, pixel)
		# The crown just over the roofs, the trunk going down behind the houses.
		tree.position = Vector2(x + (TREE_W * k / 2.0) * (1.0 if tree.scale.x < 0.0 else -1.0), rng.randf_range(215.0, 245.0) - TREE_CROWN * k)
		layer.add_child(tree)
		x += rng.randf_range(160, 380)


static func _tree_pictures() -> Array:
	if _trees.has(Season.current):
		return _trees[Season.current]
	var rng := RandomNumberGenerator.new()
	rng.seed = 43
	var palettes := Season.tree_palettes()
	var pictures := []
	for i in TREE_KINDS:
		var colors := []
		if not palettes.is_empty():
			for c: String in palettes[i % palettes.size()]:
				colors.append("#" + Color(c).lerp(HAZE, 0.5).to_html(false))
		var bark := "#" + Color("#5E4A3C").lerp(HAZE, 0.5).to_html(false)
		var body := LaneArt._distant_tree(rng, Vector2(TREE_W / 2.0, TREE_FOOT), Vector2(TREE_W / 2.0, TREE_CROWN), rng.randf_range(105.0, 135.0), colors, bark)
		var svg := '<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" viewBox="0 0 %d %d">%s</svg>' % [TREE_W, TREE_FOOT, TREE_W, TREE_FOOT, body]
		pictures.append(PropArt.tex(svg, TREE_RASTER))
	_trees[Season.current] = pictures
	return pictures
