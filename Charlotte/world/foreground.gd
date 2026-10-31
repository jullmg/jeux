class_name Foreground
extends RefCounted
## Out-of-focus things right in front of the camera (leaf piles, shrubs, a parking sign) that scroll
## faster than the street for depth. Rasterized small and scaled up, which blurs them.

const SCROLL := 1.35
const BLUR := 0.2
const SHADE := Color(0.62, 0.55, 0.55)
const LEAVES := ["#C0392B", "#E67E22", "#F1C40F", "#D35400", "#B5442E", "#8E3A24"]


static func build(parent: Node, street_width: float, view_width: float, seed_value := 7) -> Parallax2D:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var layer := Parallax2D.new()
	layer.scroll_scale = Vector2(SCROLL, 1.0)
	parent.add_child(layer)
	var span := view_width + SCROLL * (street_width - view_width) + 300.0
	var x := rng.randf_range(150.0, 500.0)
	while x < span:
		var roll := rng.randf()
		if roll < 0.45:
			add(layer, leaf_pile(rng), Vector2(x, 720.0 + 26.0), Vector2(300, 110))
		elif roll < 0.82:
			add(layer, shrub(rng), Vector2(x, 720.0 + 70.0), Vector2(260, 170))
		else:
			add(layer, parking_sign(), Vector2(x, 720.0 + 20.0), Vector2(90, 760))
		x += rng.randf_range(800.0, 1400.0)
	return layer


## Places a blurred element with its bottom centre at `bottom`.
static func add(layer: Node, svg_body: String, bottom: Vector2, size: Vector2) -> Sprite2D:
	var svg := '<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" viewBox="0 0 %d %d">%s</svg>' % [size.x, size.y, size.x, size.y, svg_body]
	var sprite := Sprite2D.new()
	sprite.texture = PropArt.tex(svg, BLUR)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	sprite.scale = Vector2.ONE / BLUR
	sprite.centered = false
	sprite.position = bottom - size
	sprite.modulate = SHADE
	layer.add_child(sprite)
	return sprite


static func leaf_pile(rng: RandomNumberGenerator) -> String:
	var s := '<ellipse cx="150" cy="104" rx="140" ry="40" fill="#5A2E1C"/>'
	for i in 70:
		var a := rng.randf_range(PI, TAU)
		var d := sqrt(rng.randf())
		var cx := 150.0 + cos(a) * d * 135.0
		var cy := 104.0 + sin(a) * d * 70.0
		s += '<ellipse cx="%.1f" cy="%.1f" rx="14" ry="7" fill="%s" transform="rotate(%d %.1f %.1f)"/>' % [
			cx, cy, LEAVES[rng.randi_range(0, LEAVES.size() - 1)], rng.randi_range(0, 180), cx, cy]
	return s


static func shrub(rng: RandomNumberGenerator) -> String:
	var pal: Array = [["#7A2E22", "#A63D2A", "#C4562E"], ["#5E6B2A", "#7E8F3A", "#9BAE4A"], ["#8E2A3A", "#B5442E", "#D9682B"]][rng.randi_range(0, 2)]
	var s := ""
	for layer_i in 3:
		for i in 9:
			var cx := rng.randf_range(40.0, 220.0)
			var cy := rng.randf_range(60.0, 150.0) + layer_i * 10.0
			s += '<circle cx="%.1f" cy="%.1f" r="%.1f" fill="%s"/>' % [cx, cy, rng.randf_range(30.0, 50.0), pal[layer_i]]
	return s


static func parking_sign() -> String:
	var s := '<rect x="38" y="40" width="14" height="720" fill="#3E4246"/>'
	s += '<rect x="5" y="40" width="80" height="120" rx="6" fill="#F4F4F0" stroke="#3E4246" stroke-width="4"/>'
	s += '<circle cx="45" cy="88" r="30" fill="none" stroke="#2E8B57" stroke-width="8"/>'
	s += '<path d="M36 106 V70 H48 Q60 70 60 81 Q60 92 48 92 H36" fill="none" stroke="#2E8B57" stroke-width="8" stroke-linejoin="round"/>'
	s += '<path d="M15 140 H75" stroke="#C0392B" stroke-width="8"/>'
	return s
