class_name FreshArt
extends RefCounted
## Fraîchement Bon on Rue Masson, a neighbourhood fruiterie and fine grocery, drawn as SVG at runtime: warm wood and deep green,
## tiered stands of crates heaped with fruit and vegetables under chalk price cards, the misted wall rack of greens, the cheese
## and charcuterie counter, shelves of jars, oils and pasta, bulk bins of nuts, the bread basket. Light from the upper left;
## own random numbers so a stand is always the same stand.

const GREEN := "#1E4A32"
const WOOD := "#A87A4E"
const WOOD_DARK := "#6E4A2A"


static func tex(w: float, h: float, body: String) -> ImageTexture:
	return InteriorArt.tex(w, h, body)


static func _r(x: float, y: float, w: float, h: float, fill: String, extra := "") -> String:
	return '<rect x="%.1f" y="%.1f" width="%.1f" height="%.1f" fill="%s" %s/>' % [x, y, w, h, fill, extra]


static func _c(x: float, y: float, r: float, fill: String, extra := "") -> String:
	return '<circle cx="%.1f" cy="%.1f" r="%.1f" fill="%s" %s/>' % [x, y, r, fill, extra]


static func _e(x: float, y: float, rx: float, ry: float, fill: String, extra := "") -> String:
	return '<ellipse cx="%.1f" cy="%.1f" rx="%.1f" ry="%.1f" fill="%s" %s/>' % [x, y, rx, ry, fill, extra]


static func _p(d: String, fill: String, extra := "") -> String:
	return '<path d="%s" fill="%s" %s/>' % [d, fill, extra]


## The produce of the season (the same draws in every season, only what is heaped changes).
static func produce() -> Array:
	var all := ["apple", "green_apple", "orange", "lemon", "banana", "grapes", "tomato", "pepper", "lettuce", "carrot", "broccoli", "eggplant"]
	match Season.current:
		"autumn":
			all += ["pumpkin", "squash", "apple"]
		"winter":
			all += ["clementine", "clementine", "orange"]
		"spring":
			all += ["strawberry", "asparagus", "radish"]
		"summer":
			all += ["strawberry", "corn", "watermelon"]
	return all


## One fruit or vegetable at (x, y), its size `s`.
static func _one(kind: String, x: float, y: float, s: float, rng: RandomNumberGenerator) -> String:
	var t := ""
	match kind:
		"apple":
			t = _c(x, y, 7 * s, ["#C8202A", "#B5182A", "#D9342B"][rng.randi_range(0, 2)]) + _r(x - 0.5, y - 9 * s, 1.5, 3 * s, "#5E3A1E")
		"green_apple":
			t = _c(x, y, 7 * s, "#8CC63E") + _r(x - 0.5, y - 9 * s, 1.5, 3 * s, "#5E3A1E")
		"orange", "clementine":
			t = _c(x, y, (7.5 if kind == "orange" else 6.0) * s, "#F28C28") + _c(x - 1, y - 6 * s, 1.2, "#3E6A2A")
		"lemon":
			t = _e(x, y, 7.5 * s, 5.5 * s, "#F7D63A")
		"banana":
			t = _p("M%.1f %.1f q%.1f %.1f %.1f 0 q%.1f %.1f %.1f 0 z" % [x - 9 * s, y, 9 * s, 8 * s, 18 * s, -9 * s, 4 * s, -18 * s], "#F2D13A", 'stroke="#C9A21E" stroke-width="0.8"')
		"grapes":
			for i in 6:
				t += _c(x + (i % 3 - 1) * 4 * s, y + floorf(i / 3.0) * 4 * s, 2.6 * s, "#6A2A5A" if rng.randf() < 0.6 else "#9ACB4A")
		"tomato":
			t = _c(x, y, 7 * s, "#E0352A") + _p("M%.1f %.1f l3 -2 l3 2 l-3 1 z" % [x - 3, y - 7 * s], "#3E7A2A")
		"pepper":
			t = _p("M%.1f %.1f q%.1f %.1f %.1f 0 q0 %.1f %.1f %.1f q%.1f 0 %.1f %.1f z" % [x - 7 * s, y - 4 * s, 7 * s, -5 * s, 14 * s, 9 * s, -7 * s, 4 * s, -7 * s, -7 * s, -4 * s], ["#E0352A", "#F2C230", "#3E9A3A"][rng.randi_range(0, 2)])
		"lettuce":
			t = _c(x, y, 9 * s, "#7CC24A") + _c(x - 3 * s, y - 2 * s, 5 * s, "#A6D86A") + _c(x + 3 * s, y + 1 * s, 4 * s, "#5EA03A")
		"carrot":
			t = _p("M%.1f %.1f l%.1f %.1f l%.1f %.1f z" % [x - 3 * s, y - 6 * s, 16 * s, 4 * s, -16 * s, 4 * s], "#F28C28") + _p("M%.1f %.1f l-5 -4 m5 4 l-5 2" % [x - 3 * s, y - 4 * s], "none", 'stroke="#4E9A2A" stroke-width="1.5"')
		"broccoli":
			t = _r(x - 1.5 * s, y, 3 * s, 7 * s, "#8CC63E") + _c(x - 3 * s, y - 1 * s, 4 * s, "#2E7A2E") + _c(x + 3 * s, y - 1 * s, 4 * s, "#3A8A36") + _c(x, y - 4 * s, 4 * s, "#2E7A2E")
		"eggplant":
			t = _e(x, y, 9 * s, 5 * s, "#4A2A5A") + _p("M%.1f %.1f l-4 -3 l1 5 z" % [x - 8 * s, y], "#3E6A2A")
		"pumpkin":
			t = _e(x, y - 2, 11 * s, 9 * s, "#F28C28") + _p("M%.1f %.1f q0 -5 3 -6" % [x, y - 10 * s], "none", 'stroke="#4E3A1E" stroke-width="2"') + _p("M%.1f %.1f q0 8 0 18" % [x - 4 * s, y - 10 * s], "none", 'stroke="#D9701E" stroke-width="1"')
		"squash":
			t = _e(x, y, 10 * s, 6 * s, "#E8B54A") + _e(x + 4 * s, y, 5 * s, 4 * s, "#D9A23A")
		"strawberry":
			t = _p("M%.1f %.1f q%.1f %.1f %.1f %.1f q%.1f %.1f %.1f %.1f z" % [x - 5 * s, y - 3 * s, 5 * s, 12 * s, 10 * s, 0, -5 * s, -4 * s, -10 * s, 0], "#D9242A") + _r(x - 3 * s, y - 5 * s, 6 * s, 2 * s, "#3E8A2A")
		"asparagus":
			for i in 4:
				t += _r(x - 6 * s + i * 4 * s, y - 10 * s, 2.5 * s, 14 * s, "#6EA83A")
		"radish":
			t = _c(x, y, 5 * s, "#D9306A") + _p("M%.1f %.1f l-2 -7 m2 7 l3 -6" % [x, y - 5 * s], "none", 'stroke="#4E9A2A" stroke-width="1.5"')
		"corn":
			t = _e(x, y, 4 * s, 10 * s, "#F2C230") + _p("M%.1f %.1f q-6 -6 -2 -14 m2 14 q6 -6 2 -14" % [x, y + 8 * s], "none", 'stroke="#7CB24A" stroke-width="2"')
		"watermelon":
			t = _e(x, y, 13 * s, 9 * s, "#2E7A36") + _p("M%.1f %.1f q%.1f %.1f %.1f 0" % [x - 10 * s, y, 10 * s, -6 * s, 20 * s], "none", 'stroke="#7CC24A" stroke-width="1.5"')
	return t + _c(x - 2 * s, y - 3 * s, 1.6 * s, "#FFFFFF", 'opacity="0.35"')


## A heap of one kind in a crate (crate `w` wide at (x, y) its rim).
static func _crate(kind: String, x: float, y: float, w: float, rng: RandomNumberGenerator) -> String:
	var t := _r(x, y, w, 26, WOOD, 'stroke="%s"' % WOOD_DARK) + _r(x, y + 12, w, 2, WOOD_DARK, 'opacity="0.5"')
	var n := int(w / 12.0)
	for row in 3:
		for i in n - row:
			var px := x + 8.0 + i * (w - 16.0) / maxf(1.0, n - 1) + row * 5.0 + rng.randf_range(-1.5, 1.5)
			t += _one(kind, px, y + 2.0 - row * 9.0, 1.0, rng)
	return t


## A chalk price card on a stick: green slate, white figures.
static func _card(x: float, y: float, price: String) -> String:
	# The figures in chalk, as strokes (an SVG <text> doesn't render here); `price` only sets how long the line is.
	var t := _r(x - 1, y, 2, 16, WOOD_DARK) + _r(x - 22, y - 26, 44, 26, "#2B302C", 'stroke="%s" stroke-width="2"' % WOOD)
	var n := clampi(price.length() / 2, 2, 5)
	for i in n:
		t += _r(x - 16 + i * 7, y - 18, 5, 9, "#F4F1EA", 'opacity="0.9"')
	return t


## A tiered stand of crates (420 × 300): three tiers stepping back, each with three crates of the season's produce, chalk
## price cards, a skirt of green-painted boards.
static func produce_stand(seed_value: int) -> ImageTexture:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var kinds := produce()
	var s := ""
	var prices := ["0,99 $/lb", "1,49 $", "2,99 $", "0,79 $", "3,49 $", "1,99 $/lb"]
	# The back tier first, so each tier in front heaps its produce over the one behind.
	for tier: int in [2, 1, 0]:
		var y := 220.0 - tier * 70.0
		var x0 := 20.0 + tier * 14.0
		var cw := (380.0 - tier * 28.0) / 3.0
		for c in 3:
			s += _crate(kinds[rng.randi_range(0, kinds.size() - 1)], x0 + c * cw + 2, y, cw - 4, rng)
		s += _r(x0, y + 26, 380 - tier * 28.0, 44, "#2E5A3E") + _r(x0, y + 26, 380 - tier * 28.0, 3, "#FFFFFF", 'opacity="0.2"')
	s += _r(20, 246, 380, 54, GREEN) + _r(20, 246, 380, 4, "#FFFFFF", 'opacity="0.2"')
	for i in 3:
		s += _card(90 + i * 120, 196 - i * 6, prices[rng.randi_range(0, prices.size() - 1)])
	return tex(420, 300, s)


## The misted wall rack of greens and vegetables (900 × 420): sloping green bins under a mirror and a strip of lights.
static func wall_rack(seed_value: int) -> ImageTexture:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var greens := ["lettuce", "broccoli", "carrot", "pepper", "eggplant", "lettuce", "radish", "asparagus", "tomato"]
	var s := _r(0, 0, 900, 420, "#2E4A3A") + _r(20, 20, 860, 110, "#9EB8B0", 'opacity="0.6"') + _r(20, 20, 860, 8, "#FFF8DC", 'opacity="0.9"')
	for row in 3:
		var y := 170.0 + row * 80.0
		var x := 30.0
		while x < 860.0:
			var w := rng.randf_range(90.0, 130.0)
			var kind: String = greens[rng.randi_range(0, greens.size() - 1)]
			s += _p("M%.1f %.1f L%.1f %.1f L%.1f %.1f L%.1f %.1f Z" % [x, y, x + w, y, x + w, y + 40, x, y + 40], "#3E6A4E")
			for i in int(w / 13.0):
				for k in 2:
					s += _one(kind, x + 8 + i * 13, y + 26 - k * 10, 1.0, rng)
			s += _r(x, y + 40, w, 10, "#F4F1EA") + _r(x + w / 2 - 12, y + 43, 24, 4, GREEN, 'opacity="0.8"')
			x += w + 6.0
	return tex(900, 420, s)


## The cheese and charcuterie counter (700 × 300): a curved glass case, wheels and wedges of cheese, sausages and hams on
## the slate inside, the wooden front.
static func cheese_counter(seed_value: int) -> ImageTexture:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var s := _r(0, 140, 700, 160, WOOD, 'stroke="%s" stroke-width="2"' % WOOD_DARK)
	var px := 20.0
	while px < 690.0:
		s += _r(px, 160, 60, 120, "none", 'stroke="%s" stroke-width="2" opacity="0.6"' % WOOD_DARK)
		px += 76.0
	s += _r(0, 120, 700, 22, "#3A3A3A")
	for i in 14:
		var x := 30.0 + i * 47.0
		match i % 4:
			0:
				s += _e(x, 112, 20, 9, "#F2D37A", 'stroke="#C9A23A"') + _r(x - 20, 103, 40, 9, "#F2D37A")
			1:
				s += _p("M%.1f 116 L%.1f 96 L%.1f 116 Z" % [x - 16, x + 14, x + 16], "#F7E7B0", 'stroke="#D9C17A"') + _c(x, 110, 2, "#E8D08A")
			2:
				s += _e(x, 110, 18, 6, "#8E2A2A") + _e(x + 6, 108, 10, 4, "#B5443A")
			_:
				s += _e(x, 112, 16, 8, "#F4F1EA", 'stroke="#D8D2C6"') + _c(x - 4, 110, 3, "#9EB86A")
	s += _p("M0 120 Q0 30 80 30 L700 30 L700 120 Z", "#DDEFF5", 'opacity="0.35" stroke="#B9D8E0"')
	s += _p("M20 110 Q20 46 90 46", "none", 'stroke="#FFFFFF" stroke-width="5" opacity="0.6"')
	return tex(700, 300, s)


## Wooden shelves of the fine grocery (600 × 470): jams, olive oils, pasta, sauces, tins, chocolate, each row its own.
static func fine_shelves(seed_value: int) -> ImageTexture:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var s := _r(0, 0, 600, 470, "#5E3E26") + _r(10, 10, 580, 450, "#7A5236")
	for row in 5:
		var y := 100.0 + row * 82.0
		var x := 22.0
		var kind := row % 5
		while x < 570.0:
			match kind:
				0:  # jams: jars with gingham lids
					var c: String = ["#9A1E3A", "#D9701E", "#5A1E5A", "#C8202A"][rng.randi_range(0, 3)]
					s += _r(x, y - 34, 24, 34, c, 'rx="3"') + _r(x - 1, y - 40, 26, 7, "#F4F1EA") + _r(x + 4, y - 24, 16, 12, "#F4F1EA", 'opacity="0.85"')
					x += 30.0
				1:  # olive oils: tall bottles
					s += _r(x + 5, y - 58, 14, 58, ["#6E8A2A", "#3E5A1E", "#A8B83A"][rng.randi_range(0, 2)], 'rx="3"') + _r(x + 9, y - 70, 6, 12, "#2A2A2A") + _r(x + 6, y - 36, 12, 14, "#F2E6C8")
					x += 26.0
				2:  # pasta: tall packs
					s += _r(x, y - 52, 28, 52, ["#1D4F91", "#F2C230", "#C8202A"][rng.randi_range(0, 2)]) + _r(x + 4, y - 40, 20, 18, "#F4E3B0")
					x += 32.0
				3:  # sauces and tins
					s += _r(x, y - 30, 22, 30, ["#C8202A", "#E8B54A", "#3E7A3A"][rng.randi_range(0, 2)], 'rx="2"') + _r(x, y - 22, 22, 10, "#F4F1EA", 'opacity="0.85"')
					x += 26.0
				_:  # fine chocolate bars, stood up
					s += _r(x, y - 40, 18, 40, ["#5E3A22", "#2A1A12", "#8E2A3A", "#1E4A32"][rng.randi_range(0, 3)]) + _r(x + 2, y - 30, 14, 6, "#C9A23A")
					x += 22.0
		s += _r(10, y, 580, 10, WOOD, 'stroke="%s"' % WOOD_DARK) + _r(10, y, 580, 2, "#FFFFFF", 'opacity="0.2"')
	s += _r(0, 0, 600, 40, GREEN) 
	return tex(600, 470, s)


## Bulk bins of nuts and dried fruit (360 × 260) with their scoops.
static func bulk_bins(seed_value: int) -> ImageTexture:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var s := _r(0, 120, 360, 140, WOOD, 'stroke="%s" stroke-width="2"' % WOOD_DARK)
	var fills := ["#C9955A", "#8E5A2E", "#E8C58A", "#6A2A1E", "#D9B36A", "#A8C26A"]
	for i in 6:
		var x := 10.0 + (i % 3) * 116.0
		var y := 20.0 + floorf(i / 3.0) * 60.0
		s += _r(x, y, 106, 54, "#DDEFF5", 'opacity="0.55" stroke="#9EC3D0"')
		var f: String = fills[i]
		for k in 30:
			s += _c(x + 8 + rng.randf() * 90, y + 28 + rng.randf() * 22, 3.2, f)
		s += _r(x + 30, y + 44, 46, 10, "#F4F1EA")
	return tex(360, 260, s)


## The bread basket (300 × 220): baguettes standing in a wicker basket, round loaves before it.
static func bread(seed_value: int) -> ImageTexture:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var s := ""
	for i in 7:
		var x := 60.0 + i * 26.0
		s += '<rect x="%.1f" y="%.1f" width="16" height="140" rx="8" fill="#D9A25A" stroke="#A8743A" transform="rotate(%.1f %.1f 180)"/>' % [x, 30.0 + rng.randf() * 20.0, rng.randf_range(-12.0, 12.0), x + 8]
	s += _p("M30 140 L270 140 L250 220 L50 220 Z", "#B58A4E", 'stroke="#7E5A2E" stroke-width="2"')
	for i in 6:
		s += _p("M%.1f 150 l20 70" % [50.0 + i * 36.0], "none", 'stroke="#8E6A3A" stroke-width="2" opacity="0.6"')
	for i in 3:
		s += _e(80.0 + i * 70.0, 205, 30, 18, "#C98A4A", 'stroke="#9A6A2E"') + _p("M%.1f 200 l20 -6 m-10 10 l20 -6" % [64.0 + i * 70.0], "none", 'stroke="#E8C58A" stroke-width="2"')
	return tex(300, 220, s)


## What she buys (96 × 96): one thing, big.
static func item(kind: String) -> ImageTexture:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(kind)
	var s := '<g transform="translate(48 52) scale(4)">' + _one(kind, 0, 0, 1.0, rng) + '</g>'
	if kind == "baguette":
		s = '<rect x="10" y="40" width="76" height="18" rx="9" fill="#D9A25A" stroke="#A8743A" transform="rotate(-20 48 48)"/>'
	elif kind == "cheese":
		s = _p("M14 70 L80 40 L84 70 Z", "#F7E7B0", 'stroke="#D9C17A" stroke-width="2"') + _c(50, 62, 4, "#E8D08A") + _c(66, 56, 3, "#E8D08A")
	elif kind == "chocolate":
		s = _r(20, 22, 56, 56, "#5E3A22", 'rx="3"') + _r(24, 40, 48, 14, "#C9A23A")
	elif kind == "nuts":
		s = _p("M22 30 L74 30 L70 84 L26 84 Z", "#DDEFF5", 'stroke="#9EC3D0" stroke-width="2"')
		for i in 14:
			s += _c(32 + (i % 5) * 9, 50 + floorf(i / 5.0) * 10, 4, "#C9955A")
	return tex(96, 96, s)
