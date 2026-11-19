class_name PartyArt
extends RefCounted
## Alyzée's birthday party (Party, scenes/fete_alyzee.gd) and its presents at the Jean Coutu, drawn as SVG at runtime. Each
## canvas has its foot on the bottom edge (or hangs from its top), light from the upper left. Words are labels in the scenes.

const INK := "#3A3A48"


static func _svg(w: float, h: float, body: String) -> ImageTexture:
	return PropArt.tex('<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" viewBox="0 0 %d %d">%s</svg>' % [w, h, w, h, body])


static func _rect(x: float, y: float, w: float, h: float, fill: String, extra := "") -> String:
	return '<rect x="%.1f" y="%.1f" width="%.1f" height="%.1f" fill="%s" %s/>' % [x, y, w, h, fill, extra]


static func _star(cx: float, cy: float, r: float, fill: String) -> String:
	var pts := ""
	for k in 10:
		var rr := r if k % 2 == 0 else r * 0.45
		var a := -PI / 2.0 + k * PI / 5.0
		pts += "%.1f,%.1f " % [cx + cos(a) * rr, cy + sin(a) * rr]
	return '<polygon points="%s" fill="%s"/>' % [pts, fill]


# ── The invitation and the presents ─────────────────────────────

## The invitation card (120 × 84): pink, balloons, a cake, confetti. Its words are a label in the scene.
static func invitation() -> ImageTexture:
	var s := _rect(2, 2, 116, 80, "#FFD3E2", 'rx="8" stroke="#E86A9A" stroke-width="3"')
	for c: Array in [[18, 26, "#4FA3E0"], [32, 18, "#FFD23F"], [100, 22, "#7CCB5A"]]:
		s += '<ellipse cx="%d" cy="%d" rx="8" ry="10" fill="%s"/>' % c
		s += '<path d="M%d %d q3 12 -2 24" stroke="#8A6A8A" stroke-width="1" fill="none"/>' % [c[0], c[1] + 10]
	s += _rect(46, 50, 30, 18, "#FFFFFF", 'rx="3"') + _rect(46, 50, 30, 5, "#E86A9A", 'rx="2"')
	for k in 3:
		s += _rect(52 + k * 8, 42, 2.5, 8, "#4FA3E0") + '<ellipse cx="%.1f" cy="40" rx="1.8" ry="3" fill="#FFB020"/>' % (53.2 + k * 8)
	for i in 14:
		var colors := ["#E04F5F", "#4FA3E0", "#FFD23F", "#7CCB5A", "#7E57C2"]
		s += _rect(8 + fmod(i * 37.0, 104.0), 8 + fmod(i * 23.0, 68.0), 3, 3, colors[i % 5], 'transform="rotate(%d %.1f %.1f)"' % [i * 27, 9.5 + fmod(i * 37.0, 104.0), 9.5 + fmod(i * 23.0, 68.0)])
	return _svg(120, 84, s)


## A present, unwrapped (80 × 80): "licorne", "bricolage", "casse_tete" or "vernis".
static func gift(kind: String) -> ImageTexture:
	var s := ""
	match kind:
		"licorne":
			# A mauve plush unicorn sitting, a gold horn, a rainbow mane, round black eyes.
			s += '<ellipse cx="40" cy="60" rx="22" ry="16" fill="#C7A6E0"/>'
			s += '<ellipse cx="26" cy="72" rx="7" ry="5" fill="#B48ED3"/><ellipse cx="54" cy="72" rx="7" ry="5" fill="#B48ED3"/>'
			s += '<circle cx="42" cy="34" r="16" fill="#D7BCEB"/>'
			s += '<ellipse cx="52" cy="40" rx="8" ry="6" fill="#F2D8F2"/>'
			s += '<polygon points="38,22 44,2 48,22" fill="#FFD23F" stroke="#E0A526" stroke-width="1.2"/>'
			for k in 4:
				var col: String = ["#FF7BA3", "#FFD23F", "#7CCB5A", "#4FA3E0"][k]
				s += '<ellipse cx="%d" cy="%d" rx="5" ry="8" fill="%s"/>' % [28 - k, 26 + k * 7, col]
			s += '<circle cx="44" cy="32" r="2.6" fill="#2B2B33"/><circle cx="45" cy="31" r="0.9" fill="#FFF"/>'
			s += '<circle cx="50" cy="40" r="1.2" fill="#9A6AB0"/>'
			s += '<ellipse cx="36" cy="40" rx="3" ry="2" fill="#FF9FC0" opacity="0.7"/>'
		"bricolage":
			# A clear-lidded box of glitter tubes, pompoms and a glue stick.
			s += _rect(8, 22, 64, 50, "#4FA3E0", 'rx="5"') + _rect(12, 26, 56, 42, "#E8F4FF", 'rx="3"')
			for k in 5:
				var col: String = ["#E04F5F", "#FFD23F", "#7CCB5A", "#FF7BA3", "#7E57C2"][k]
				s += _rect(16 + k * 8, 30, 5, 18, col, 'rx="2"')
			for c: Array in [[24, 58, "#FF7BA3"], [34, 60, "#FFD23F"], [44, 57, "#7CCB5A"], [54, 60, "#E04F5F"]]:
				s += '<circle cx="%d" cy="%d" r="5" fill="%s"/>' % c
			s += _rect(58, 30, 7, 22, "#FFFFFF", 'rx="2" stroke="#AAB" stroke-width="1"') + _rect(58, 30, 7, 6, "#7E57C2", 'rx="2"')
			s += _rect(8, 14, 64, 10, "#2E6FC0", 'rx="4"')
		"casse_tete":
			# A puzzle box with two kittens on its lid, a loose piece in front.
			s += _rect(6, 20, 68, 50, "#FFB34D", 'rx="4"') + _rect(10, 24, 60, 38, "#BFE3F7", 'rx="2"')
			for c: Array in [[28, 46, "#8D6E63"], [52, 46, "#F2A65A"]]:
				s += '<circle cx="%d" cy="%d" r="10" fill="%s"/>' % c
				s += '<polygon points="%d,%d %d,%d %d,%d" fill="%s"/>' % [c[0] - 9, c[1] - 4, c[0] - 6, c[1] - 14, c[0] - 2, c[1] - 8, c[2]]
				s += '<polygon points="%d,%d %d,%d %d,%d" fill="%s"/>' % [c[0] + 9, c[1] - 4, c[0] + 6, c[1] - 14, c[0] + 2, c[1] - 8, c[2]]
				s += '<circle cx="%d" cy="%d" r="1.5" fill="#222"/><circle cx="%d" cy="%d" r="1.5" fill="#222"/>' % [c[0] - 4, c[1] - 1, c[0] + 4, c[1] - 1]
			s += '<path d="M60 70 h8 v-4 a3 3 0 1 1 4 0 v4 h4 v10 h-16 z" fill="#7CCB5A" stroke="#4E9A38" stroke-width="1"/>'
		"vernis":
			# Three little bottles of sparkly polish in a card.
			s += _rect(6, 24, 68, 52, "#FCE4EF", 'rx="6" stroke="#E86A9A" stroke-width="2"')
			for k in 3:
				var col: String = ["#E86A9A", "#9C6ADE", "#4FC3E0"][k]
				var x := 14.0 + k * 20.0
				s += _rect(x, 44, 14, 24, col, 'rx="4"') + _rect(x + 4, 32, 6, 13, "#2B2B33", 'rx="1.5"')
				s += _rect(x + 2, 48, 3, 14, "#FFFFFF", 'opacity="0.45"')
				for d in 3:
					s += '<circle cx="%.1f" cy="%.1f" r="0.9" fill="#FFF"/>' % [x + 5 + d * 3, 56 + (d % 2) * 5]
	return _svg(80, 80, s)


## The present once wrapped by the cashier (70 × 70): pink paper with stars, a gold ribbon and its bow.
static func wrapped() -> ImageTexture:
	var s := _rect(6, 22, 58, 46, "#FF8FB8", 'rx="4"')
	for i in 6:
		s += _star(14 + fmod(i * 21.0, 50.0), 30 + fmod(i * 13.0, 32.0), 4.0, "#FFFFFF")
	s += _rect(31, 22, 8, 46, "#FFD23F") + _rect(6, 40, 58, 8, "#FFD23F")
	s += '<path d="M35 22 C20 6 10 20 35 22 C60 20 50 6 35 22 Z" fill="#FFD23F" stroke="#E0A526" stroke-width="1.5"/>'
	s += _rect(6, 22, 58, 4, "#FFFFFF", 'opacity="0.25"')
	return _svg(70, 70, s)


## The "Idées cadeaux" stand by the Jean Coutu's checkouts (300 × 300, foot at the bottom): three white shelves on a navy
## stand with the four presents and more like them; its sign is a label.
static func gift_stand() -> ImageTexture:
	var s := '<ellipse cx="150" cy="294" rx="140" ry="6" fill="#000" fill-opacity="0.15"/>'
	s += _rect(20, 30, 260, 262, "#1B2F6B", 'rx="6"') + _rect(30, 40, 240, 244, "#F4F6FA", 'rx="3"')
	s += _rect(20, 4, 260, 34, "#E31837", 'rx="6"')
	for row in 3:
		var y := 110.0 + row * 80.0
		s += _rect(30, y, 240, 8, "#C9D1E0")
	# The presents (drawn small): unicorns, craft boxes, puzzles, polish cards.
	var rows := [["licorne", "licorne", "bricolage"], ["casse_tete", "vernis", "vernis"], ["bricolage", "casse_tete", "licorne"]]
	for row in 3:
		for k in 3:
			var x := 44.0 + k * 78.0
			var y := 44.0 + row * 80.0
			s += _mini(rows[row][k], x, y)
	return _svg(300, 300, s)


static func _mini(kind: String, x: float, y: float) -> String:
	match kind:
		"licorne":
			return '<ellipse cx="%.1f" cy="%.1f" rx="16" ry="12" fill="#C7A6E0"/><circle cx="%.1f" cy="%.1f" r="12" fill="#D7BCEB"/><polygon points="%.1f,%.1f %.1f,%.1f %.1f,%.1f" fill="#FFD23F"/>' % [
				x + 30, y + 52, x + 32, y + 32, x + 29, y + 22, x + 34, y + 6, x + 37, y + 22]
		"bricolage":
			return _rect(x + 6, y + 18, 50, 44, "#4FA3E0", 'rx="4"') + _rect(x + 10, y + 22, 42, 30, "#E8F4FF") + '<circle cx="%.1f" cy="%.1f" r="5" fill="#FF7BA3"/><circle cx="%.1f" cy="%.1f" r="5" fill="#FFD23F"/>' % [x + 22, y + 38, x + 38, y + 40]
		"casse_tete":
			return _rect(x + 4, y + 22, 54, 40, "#FFB34D", 'rx="3"') + _rect(x + 8, y + 26, 46, 28, "#BFE3F7") + '<circle cx="%.1f" cy="%.1f" r="8" fill="#8D6E63"/>' % [x + 31, y + 42]
		"vernis":
			var out := _rect(x + 6, y + 24, 50, 38, "#FCE4EF", 'rx="4"')
			for k in 3:
				out += _rect(x + 12 + k * 14, y + 36, 10, 18, ["#E86A9A", "#9C6ADE", "#4FC3E0"][k], 'rx="3"')
			return out
	return ""


# ── The party ───────────────────────────────────────────────────

## A bunch of balloons on their strings (120 × 300, the strings meeting at the bottom, tied to whatever is there).
static func balloons(seed_value: int) -> ImageTexture:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var colors := ["#E04F5F", "#4FA3E0", "#FFD23F", "#7CCB5A", "#FF7BA3", "#9C6ADE"]
	var s := ""
	var heads: Array = []
	for i in 4:
		heads.append(Vector2(22 + i * 26 + rng.randf_range(-6, 6), 34 + rng.randf_range(0, 60)))
	for h: Vector2 in heads:
		s += '<path d="M%.1f %.1f Q%.1f %.1f 60 298" stroke="#8A8A9A" stroke-width="1.2" fill="none"/>' % [h.x, h.y + 26, h.x + rng.randf_range(-10, 10), (h.y + 298) / 2.0]
	for i in heads.size():
		var h: Vector2 = heads[i]
		var col: String = colors[(i + seed_value) % colors.size()]
		s += '<ellipse cx="%.1f" cy="%.1f" rx="19" ry="24" fill="%s"/>' % [h.x, h.y, col]
		s += '<polygon points="%.1f,%.1f %.1f,%.1f %.1f,%.1f" fill="%s"/>' % [h.x - 4, h.y + 26, h.x + 4, h.y + 26, h.x, h.y + 22, col]
		s += '<ellipse cx="%.1f" cy="%.1f" rx="5" ry="8" fill="#FFFFFF" opacity="0.45" transform="rotate(-25 %.1f %.1f)"/>' % [h.x - 7, h.y - 8, h.x - 7, h.y - 8]
	return _svg(120, 300, s)


## The party table (440 × 210, foot at the bottom): a long table under a polka-dot cloth, a bowl of chips, one of popcorn,
## one of jujubes, cupcakes on a stand, juice boxes, paper plates and cups. The cake goes on it as its own sprite.
static func party_table() -> ImageTexture:
	var s := '<ellipse cx="220" cy="204" rx="200" ry="6" fill="#000" fill-opacity="0.15"/>'
	for x in [40.0, 390.0]:
		s += _rect(x, 120, 10, 86, "#8A5A30")
	s += _rect(10, 96, 420, 46, "#FFFFFF", 'rx="4"')
	for i in 22:
		s += '<circle cx="%.1f" cy="%.1f" r="4" fill="%s"/>' % [22 + i * 19, 108 + (i % 2) * 18, ["#FF7BA3", "#4FA3E0", "#FFD23F"][i % 3]]
	s += '<path d="M10 142 q20 10 40 0 q20 10 40 0 q20 10 40 0 q20 10 40 0 q20 10 40 0 q20 10 40 0 q20 10 40 0 q20 10 40 0 q20 10 40 0 q20 10 40 0 q10 6 20 0" fill="#FFFFFF" stroke="#E6E6EE" stroke-width="1"/>'
	# Bowls: chips, popcorn, jujubes.
	s += '<path d="M22 96 a30 14 0 0 0 60 0 z" fill="#4FA3E0"/>'
	for i in 7:
		s += '<ellipse cx="%.1f" cy="%.1f" rx="7" ry="5" fill="#F2C14E" transform="rotate(%d %.1f %.1f)"/>' % [30 + i * 7, 90 + (i % 2) * 3, i * 30, 30 + i * 7, 90 + (i % 2) * 3]
	s += '<path d="M330 96 a30 14 0 0 0 60 0 z" fill="#E04F5F"/>'
	for i in 9:
		s += '<circle cx="%.1f" cy="%.1f" r="5" fill="#FFF8E6"/>' % [336 + fmod(i * 11.0, 48.0), 88 + (i % 3) * 3]
	s += '<path d="M268 96 a22 11 0 0 0 44 0 z" fill="#7CCB5A"/>'
	for i in 7:
		s += '<ellipse cx="%.1f" cy="%.1f" rx="3.5" ry="3" fill="%s"/>' % [274 + i * 5, 91 + (i % 2) * 2, ["#E04F5F", "#FFD23F", "#7CCB5A", "#FF8A3D"][i % 4]]
	# Cupcakes on a stand, juice boxes, cups.
	s += _rect(96, 60, 4, 36, "#C9C9D6") + _rect(76, 94, 44, 3, "#C9C9D6") + _rect(80, 58, 36, 3, "#C9C9D6")
	for c: Vector2 in [Vector2(84, 94), Vector2(104, 94), Vector2(92, 58)]:
		s += '<path d="M%.1f %.1f l3 -11 h10 l3 11 z" fill="#FFB34D"/>' % [c.x - 2, c.y]
		s += '<ellipse cx="%.1f" cy="%.1f" rx="9" ry="7" fill="#FF9FC0"/>' % [c.x + 6, c.y - 13]
		s += '<circle cx="%.1f" cy="%.1f" r="2" fill="#E04F5F"/>' % [c.x + 6, c.y - 19]
	for k in 3:
		s += _rect(226 + k * 13, 74, 11, 22, ["#7CCB5A", "#FF8A3D", "#9C6ADE"][k], 'rx="1.5"') + _rect(232 + k * 13, 68, 1.5, 8, "#FFFFFF")
	return _svg(440, 210, s)


## The birthday cake (130 × 120, foot at the bottom): two layers of chocolate under pink icing, sprinkles, eight candles,
## lit or blown out (their flames; the scene adds the glow).
static func cake(lit: bool) -> ImageTexture:
	var s := '<ellipse cx="65" cy="114" rx="60" ry="6" fill="#E6E6EE"/>'
	s += _rect(15, 70, 100, 42, "#6B3E26", 'rx="6"') + _rect(25, 46, 80, 28, "#7A4A2E", 'rx="6"')
	s += '<path d="M15 76 q8 8 14 0 q8 8 14 0 q8 8 14 0 q8 8 14 0 q8 8 14 0 q8 8 14 0 q8 8 16 0 v-8 h-100 z" fill="#FF9FC0"/>'
	s += '<path d="M25 52 q7 7 13 0 q7 7 13 0 q7 7 13 0 q7 7 13 0 q7 7 13 0 q7 7 15 0 v-8 h-80 z" fill="#FF9FC0"/>'
	for i in 16:
		s += _rect(22 + fmod(i * 23.0, 90.0), 86 + fmod(i * 7.0, 20.0), 4, 1.6, ["#FFD23F", "#4FA3E0", "#7CCB5A", "#FFFFFF"][i % 4], 'transform="rotate(%d %.1f %.1f)"' % [i * 40, 24 + fmod(i * 23.0, 90.0), 87 + fmod(i * 7.0, 20.0)])
	for k in 8:
		var x := 31.0 + k * 9.7
		s += _rect(x, 28, 3.5, 18, ["#4FA3E0", "#FFD23F", "#7CCB5A", "#FF7BA3"][k % 4])
		if lit:
			s += '<ellipse cx="%.1f" cy="23" rx="2.6" ry="4.6" fill="#FFB020"/><ellipse cx="%.1f" cy="24" rx="1.2" ry="2.4" fill="#FFF3B0"/>' % [x + 1.75, x + 1.75]
		else:
			s += '<path d="M%.1f 26 q-3 -6 1 -12" stroke="#B8B8C8" stroke-width="1.2" fill="none" opacity="0.7"/>' % (x + 1.75)
	return _svg(130, 120, s)


## A slice of the cake on a paper plate (64 × 64), for her treat.
static func cake_slice() -> ImageTexture:
	var s := '<ellipse cx="32" cy="52" rx="28" ry="9" fill="#FFFFFF" stroke="#DDD" stroke-width="1"/>'
	s += '<polygon points="10,48 54,48 54,26 10,36" fill="#6B3E26"/><polygon points="10,36 54,26 54,30 10,40" fill="#FF9FC0"/>'
	s += '<polygon points="10,36 54,26 54,18 10,30" fill="#FF9FC0"/>'
	s += '<circle cx="40" cy="20" r="3" fill="#E04F5F"/>'
	return _svg(64, 64, s)


## A thing from the party table (64 × 64): "chips", "popcorn", "jujubes", "cupcake", "jus".
static func snack(kind: String) -> ImageTexture:
	var s := ""
	match kind:
		"chips":
			s += '<path d="M8 30 a24 12 0 0 0 48 0 z" fill="#4FA3E0"/>'
			for i in 5:
				s += '<ellipse cx="%.1f" cy="%.1f" rx="8" ry="6" fill="#F2C14E" transform="rotate(%d %.1f %.1f)"/>' % [16 + i * 8, 26 - (i % 2) * 4, i * 35, 16 + i * 8, 26 - (i % 2) * 4]
		"popcorn":
			s += '<polygon points="16,24 48,24 44,60 20,60" fill="#FFFFFF"/>'
			for k in 3:
				s += _rect(20 + k * 9, 24, 4, 36, "#E04F5F")
			for i in 9:
				s += '<circle cx="%.1f" cy="%.1f" r="6" fill="#FFF8E6" stroke="#F2E2B6" stroke-width="1"/>' % [18 + fmod(i * 11.0, 30.0), 14 + (i % 3) * 5]
		"jujubes":
			for i in 8:
				s += '<ellipse cx="%.1f" cy="%.1f" rx="7" ry="6" fill="%s"/>' % [16 + fmod(i * 13.0, 34.0), 26 + (i % 3) * 9, ["#E04F5F", "#FFD23F", "#7CCB5A", "#FF8A3D"][i % 4]]
		"cupcake":
			s += '<path d="M18 58 l4 -20 h20 l4 20 z" fill="#FFB34D"/><ellipse cx="32" cy="32" rx="16" ry="12" fill="#FF9FC0"/><circle cx="32" cy="20" r="4" fill="#E04F5F"/>'
		"jus":
			s += _rect(20, 18, 24, 40, "#FF8A3D", 'rx="2"') + _rect(24, 26, 16, 14, "#FFF3E0") + _rect(36, 6, 2.5, 14, "#FFFFFF")
	return _svg(64, 64, s)


## The goody bag she takes home (64 × 64): a striped paper bag, candy peeking out.
static func loot_bag() -> ImageTexture:
	var s := '<polygon points="14,22 50,22 54,60 10,60" fill="#9C6ADE"/>'
	for k in 4:
		s += _rect(16 + k * 10, 22, 4, 38, "#B58CF0")
	s += '<circle cx="24" cy="18" r="6" fill="#E04F5F"/><circle cx="36" cy="16" r="6" fill="#FFD23F"/><rect x="42" y="4" width="2" height="16" fill="#FFF"/><circle cx="43" cy="5" r="5" fill="#7CCB5A"/>'
	return _svg(64, 64, s)


## The game on the wall (260 × 220): a white unicorn without its horn on a sky-blue sheet, a dot on her forehead where
## the horn goes. The scene pins the horns.
static func unicorn_poster() -> ImageTexture:
	var s := _rect(0, 0, 260, 220, "#CDEBFA", 'rx="6" stroke="#FFFFFF" stroke-width="6"')
	s += '<path d="M10 200 q60 -30 120 -10 q60 20 120 -6 v26 h-240 z" fill="#B8E3A0"/>'
	s += '<ellipse cx="150" cy="150" rx="60" ry="38" fill="#FFFFFF" stroke="#C9C9E0" stroke-width="2"/>'
	for x in [110.0, 135.0, 165.0, 190.0]:
		s += _rect(x, 172, 12, 32, "#FFFFFF", 'stroke="#C9C9E0" stroke-width="2"')
	s += '<path d="M95 130 q-10 -40 10 -70 l30 10 q-10 30 0 60 z" fill="#FFFFFF" stroke="#C9C9E0" stroke-width="2"/>'
	s += '<ellipse cx="96" cy="66" rx="30" ry="22" fill="#FFFFFF" stroke="#C9C9E0" stroke-width="2"/>'
	s += '<ellipse cx="72" cy="74" rx="12" ry="9" fill="#FFE3EE"/>'
	s += '<polygon points="104,44 112,30 116,48" fill="#FFFFFF" stroke="#C9C9E0" stroke-width="2"/>'
	s += '<circle cx="90" cy="60" r="3.5" fill="#2B2B33"/>'
	for k in 5:
		s += '<ellipse cx="%d" cy="%d" rx="9" ry="14" fill="%s"/>' % [122 + k * 4, 52 + k * 15, ["#FF7BA3", "#FFD23F", "#7CCB5A", "#4FA3E0", "#9C6ADE"][k]]
	s += '<path d="M206 140 q30 10 26 50" stroke="#FF7BA3" stroke-width="10" fill="none" stroke-linecap="round"/>'
	s += '<circle cx="%d" cy="%d" r="4" fill="#FF7BA3" opacity="0.6"/>' % [int(HORN_SPOT.x), int(HORN_SPOT.y)]
	return _svg(260, 220, s)


## Where the horn belongs on the poster (its own canvas units).
const HORN_SPOT := Vector2(100, 46)


## A paper horn to pin (24 × 40), its point up.
static func horn() -> ImageTexture:
	var s := '<polygon points="12,2 22,38 2,38" fill="#FFD23F" stroke="#E0A526" stroke-width="1.5"/>'
	for k in 3:
		s += '<path d="M%d %d l%d 4" stroke="#E0A526" stroke-width="1.2"/>' % [6 + k * 2, 30 - k * 9, 12 - k * 4]
	return _svg(24, 40, s)
