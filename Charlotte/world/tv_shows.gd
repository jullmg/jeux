class_name TvShows
extends RefCounted
## The TV channels: tiny animated shows drawn in code on a SIZE screen, all original. Any TvScreen (in any
## house) picks the channels it gets from ALL by id; draw() paints one at time t, `on_for` seconds after
## the viewer switched to it (for title cards).

const SIZE := Vector2(196, 108)
const ALL: Array[String] = ["news", "animals", "cartoon", "hockey", "weather", "ratons", "cooking", "space", "music", "game"]
const INFO := {
	"news": {"name": "Nouvelles", "glow": Color(0.45, 0.6, 1.0)},
	"animals": {"name": "Animaux", "glow": Color(1.0, 0.8, 0.4)},
	"cartoon": {"name": "Dessins animés", "glow": Color(1.0, 0.6, 0.85)},
	"hockey": {"name": "Hockey", "glow": Color(0.85, 0.92, 1.0)},
	"weather": {"name": "Météo", "glow": Color(0.5, 0.85, 0.7)},
	"ratons": {"name": "Les Ratons", "glow": Color(0.75, 0.95, 0.7)},
	"cooking": {"name": "Cuisine", "glow": Color(1.0, 0.85, 0.6)},
	"space": {"name": "Espace", "glow": Color(0.5, 0.5, 1.0)},
	"music": {"name": "Musique", "glow": Color(1.0, 0.4, 0.9)},
	"game": {"name": "Jeu télévisé", "glow": Color(1.0, 0.85, 0.3)},
}
const TICKER := "Il fera beau à Montréal aujourd'hui  •  Les écureuils de la 6e Avenue font leurs provisions pour l'hiver  •  Des bonbons d'Halloween au dépanneur Xin-Xin  •  La ruelle verte est pleine de feuilles  •  "


static func draw(id: String, c: CanvasItem, t: float, on_for: float) -> void:
	match id:
		"news": _news(c, t, on_for)
		"animals": _animals(c, t, on_for)
		"cartoon": _cartoon(c, t, on_for)
		"hockey": _hockey(c, t, on_for)
		"weather": _weather(c, t, on_for)
		"ratons": _ratons(c, t, on_for)
		"cooking": _cooking(c, t, on_for)
		"space": _space(c, t, on_for)
		"music": _music(c, t, on_for)
		"game": _game(c, t, on_for)


static func _font() -> Font:
	return ThemeDB.fallback_font


static func _text(c: CanvasItem, s: String, at: Vector2, font_size: int, col: Color, width := -1.0, align := HORIZONTAL_ALIGNMENT_LEFT) -> void:
	c.draw_string(_font(), at, s, align, width, font_size, col)


static func _news(c: CanvasItem, t: float, on_for: float) -> void:
	c.draw_rect(Rect2(Vector2.ZERO, SIZE), Color("#1D3F7A"))
	c.draw_rect(Rect2(0, 0, SIZE.x, 50), Color("#2A5598"))
	# Picture box: a maple leaf.
	c.draw_rect(Rect2(118, 10, 66, 44), Color("#F4F1EA"))
	c.draw_rect(Rect2(121, 13, 60, 38), Color("#C8202A"))
	var leaf := PackedVector2Array()
	for i in 22:
		var a := TAU * i / 22.0 - PI / 2.0
		var r := 13.0 if i % 2 == 0 else 7.0
		leaf.append(Vector2(151, 33) + Vector2.from_angle(a) * r)
	c.draw_colored_polygon(leaf, Color.WHITE)
	# The anchor at the desk, talking.
	c.draw_rect(Rect2(28, 56, 56, 40), Color("#2E3440"))
	c.draw_colored_polygon(PackedVector2Array([Vector2(48, 56), Vector2(56, 70), Vector2(64, 56)]), Color.WHITE)
	c.draw_circle(Vector2(56, 40), 15, Color("#3A2618"))
	c.draw_circle(Vector2(56, 44), 12, Color("#E8B892"))
	c.draw_circle(Vector2(51, 42), 1.6, Color.BLACK)
	c.draw_circle(Vector2(61, 42), 1.6, Color.BLACK)
	var talk := absf(sin(t * 11.0)) * 2.5
	c.draw_rect(Rect2(53, 49, 6, 1.0 + talk), Color("#8E2A37"))
	c.draw_rect(Rect2(10, 76, 110, 14), Color("#5A3A22"))
	# Lower third and the ticker.
	c.draw_rect(Rect2(0, 80, SIZE.x, 14), Color("#C8202A"))
	_text(c, "NOUVELLES", Vector2(6, 91), 10, Color.WHITE)
	c.draw_rect(Rect2(0, 94, SIZE.x, 14), Color("#F4F1EA"))
	var w := _font().get_string_size(TICKER, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x
	var x := -fmod(t * 40.0, w)
	_text(c, TICKER + TICKER, Vector2(x, 105), 10, Color("#1D3F7A"))


static func _animals(c: CanvasItem, t: float, on_for: float) -> void:
	c.draw_rect(Rect2(Vector2.ZERO, SIZE), Color("#F6C77A"))
	c.draw_rect(Rect2(0, 0, SIZE.x, 30), Color("#F8DDA0"))
	c.draw_circle(Vector2(150, 30), 14, Color("#FFF1B8"))
	c.draw_rect(Rect2(0, 70, SIZE.x, 38), Color("#C9A24A"))
	# Acacia.
	c.draw_line(Vector2(40, 72), Vector2(44, 40), Color("#5E4A3C"), 3.0)
	c.draw_colored_polygon(PackedVector2Array([Vector2(16, 42), Vector2(70, 36), Vector2(64, 30), Vector2(24, 32)]), Color("#5E7A2E"))
	# A giraffe ambling across.
	var gx := fmod(t * 18.0, SIZE.x + 80.0) - 40.0
	var step := sin(t * 5.0) * 4.0
	var spot := Color("#A8642A")
	for leg in [[-10, step], [-4, -step], [10, -step], [16, step]]:
		c.draw_line(Vector2(gx + leg[0], 62), Vector2(gx + leg[0] + leg[1], 84), Color("#E8B04A"), 3.0)
	c.draw_set_transform(Vector2(gx + 3, 60), 0.0, Vector2(1.0, 0.55))
	c.draw_circle(Vector2.ZERO, 16, Color("#E8B04A"))
	c.draw_set_transform(Vector2.ZERO)
	for s in [Vector2(-6, -2), Vector2(4, 0), Vector2(10, -4)]:
		c.draw_circle(Vector2(gx, 60) + s, 2.5, spot)
	var nod := sin(t * 2.5) * 2.0
	c.draw_line(Vector2(gx + 14, 56), Vector2(gx + 24, 26 + nod), Color("#E8B04A"), 6.0)
	c.draw_circle(Vector2(gx + 28, 26 + nod), 5.0, Color("#E8B04A"))
	c.draw_circle(Vector2(gx + 29, 24 + nod), 1.2, Color.BLACK)
	c.draw_line(Vector2(gx + 25, 21 + nod), Vector2(gx + 24, 16 + nod), Color("#A8642A"), 2.0)
	_text(c, "ANIMAUX", Vector2(6, 102), 10, Color("#5E3A12"))


# An original cartoon: a bouncy bunny chasing a hopping carrot over the hills.
static func _cartoon(c: CanvasItem, t: float, on_for: float) -> void:
	c.draw_rect(Rect2(Vector2.ZERO, SIZE), Color("#BDE6FF"))
	for puff in [Vector2(30, 20), Vector2(130, 14)]:
		var drift := Vector2(fmod(t * 6.0, 40.0), 0)
		c.draw_circle(puff + drift, 9, Color.WHITE)
		c.draw_circle(puff + drift + Vector2(9, 2), 7, Color.WHITE)
	c.draw_circle(Vector2(40, 150), 90, Color("#7CCB5A"))
	c.draw_circle(Vector2(170, 160), 90, Color("#62B548"))
	var run := fmod(t * 35.0, SIZE.x + 90.0) - 60.0
	var carrot := Vector2(run + 50, 62 - absf(sin(t * 8.0)) * 14.0)
	c.draw_colored_polygon(PackedVector2Array([carrot + Vector2(-4, -6), carrot + Vector2(4, -6), carrot + Vector2(0, 10)]), Color("#FF8A3D"))
	c.draw_line(carrot + Vector2(0, -6), carrot + Vector2(-3, -12), Color("#3E8E5A"), 2.0)
	c.draw_line(carrot + Vector2(0, -6), carrot + Vector2(3, -12), Color("#3E8E5A"), 2.0)
	var bunny := Vector2(run, 66 - absf(sin(t * 6.0)) * 18.0)
	c.draw_circle(bunny, 10, Color.WHITE)
	c.draw_circle(bunny + Vector2(9, -8), 7, Color.WHITE)
	for e in [Vector2(6, -22), Vector2(12, -22)]:
		c.draw_set_transform(bunny + e, 0.25, Vector2(0.4, 1.0))
		c.draw_circle(Vector2.ZERO, 7, Color.WHITE)
		c.draw_circle(Vector2.ZERO, 4, Color("#FFB3C7"))
		c.draw_set_transform(Vector2.ZERO)
	c.draw_circle(bunny + Vector2(12, -9), 1.4, Color.BLACK)
	c.draw_circle(bunny + Vector2(15, -6), 1.4, Color("#FF5D8F"))
	c.draw_circle(bunny + Vector2(-10, 2), 4, Color.WHITE)
	if fmod(t, 1.2) < 0.6:
		for i in 3:
			var st := bunny + Vector2(-16 - i * 8, -14 + i * 6)
			c.draw_circle(st, 1.6, Color("#FFD23F"))
	_text(c, "DESSINS ANIMÉS", Vector2(6, 102), 10, Color("#1D4F91"))


static func _hockey(c: CanvasItem, t: float, on_for: float) -> void:
	c.draw_rect(Rect2(Vector2.ZERO, SIZE), Color("#EEF4F8"))
	c.draw_rect(Rect2(0, 0, SIZE.x, 16), Color("#3A3F48"))
	for i in 6:
		c.draw_rect(Rect2(4 + i * 32, 4, 28, 8), [Color("#C8202A"), Color("#1D4F91"), Color("#FFD23F")][i % 3])
	c.draw_rect(Rect2(0, 16, SIZE.x, 3), Color("#F4F1EA"))
	c.draw_rect(Rect2(97, 19, 3, 89), Color("#C8202A", 0.8))
	c.draw_rect(Rect2(60, 19, 3, 89), Color("#1D4F91", 0.7))
	c.draw_rect(Rect2(134, 19, 3, 89), Color("#1D4F91", 0.7))
	c.draw_arc(Vector2(98, 64), 16, 0, TAU, 24, Color("#1D4F91", 0.6), 1.5)
	var puck := Vector2(98 + sin(t * 1.3) * 70.0, 64 + sin(t * 2.1) * 26.0)
	for i in 6:
		var team := Color("#C8202A") if i < 3 else Color("#1D4F91")
		var chase := puck + Vector2(cos(t * 1.7 + i * 1.3) * (14 + i * 4), sin(t * 2.3 + i) * 12.0)
		c.draw_circle(chase + Vector2(0, -8), 3.0, Color("#2B2B2B"))
		c.draw_rect(Rect2(chase.x - 4, chase.y - 5, 8, 9), team)
		c.draw_line(chase + Vector2(3, 3), chase + Vector2(9, 8), Color("#8D6E63"), 1.5)
	c.draw_circle(puck, 2.2, Color.BLACK)
	c.draw_rect(Rect2(4, 92, 96, 13), Color("#2E3440"))
	_text(c, "ROUGES 2  BLEUS 1", Vector2(8, 102), 9, Color.WHITE)


static func _weather(c: CanvasItem, t: float, on_for: float) -> void:
	c.draw_rect(Rect2(Vector2.ZERO, SIZE), Color("#3D7FD0"))
	var land := PackedVector2Array([Vector2(0, 30), Vector2(60, 18), Vector2(110, 26), Vector2(150, 12), Vector2(196, 20),
		Vector2(196, 108), Vector2(0, 108)])
	c.draw_colored_polygon(land, Color("#7CBF6A"))
	c.draw_polyline(PackedVector2Array([Vector2(0, 86), Vector2(60, 70), Vector2(120, 64), Vector2(196, 44)]), Color("#3D7FD0"), 5.0)
	var city := Vector2(92, 66)
	c.draw_circle(city, 3, Color("#C8202A"))
	_text(c, "Montréal", city + Vector2(-26, 14), 9, Color("#1E1E1E"))
	var sun := city + Vector2(-6, -24)
	for i in 8:
		var a := TAU * i / 8.0 + t
		c.draw_line(sun + Vector2.from_angle(a) * 9, sun + Vector2.from_angle(a) * 13, Color("#FFD23F"), 2.0)
	c.draw_circle(sun, 7, Color("#FFD23F"))
	_text(c, "12°", sun + Vector2(12, 5), 13, Color.WHITE)
	var cloud := Vector2(fmod(t * 12.0, SIZE.x + 40) - 20, 40)
	for puff in [Vector2(0, 0), Vector2(8, -4), Vector2(16, 0)]:
		c.draw_circle(cloud + puff, 7, Color(1, 1, 1, 0.9))
	c.draw_rect(Rect2(0, 92, SIZE.x, 16), Color("#1D3F7A"))
	_text(c, "MÉTÉO  •  Ensoleillé, 12°", Vector2(6, 103), 10, Color.WHITE)


# "Les Ratons", an original family sitcom: a raccoon family in their kitchen. Dad reads the paper, Mom
# stirs the soup, the kid juggles apples, the baby bounces in the high chair; a title card opens it.
static func _ratons(c: CanvasItem, t: float, on_for: float) -> void:
	c.draw_rect(Rect2(Vector2.ZERO, SIZE), Color("#CFE3B8"))
	for x in range(0, int(SIZE.x), 12):
		c.draw_rect(Rect2(x, 78, 6, 30), Color("#F4EFE2"))
		c.draw_rect(Rect2(x + 6, 78, 6, 30), Color("#E06A5A"))
	c.draw_rect(Rect2(126, 12, 50, 36), Color("#8FC6E8"))
	c.draw_rect(Rect2(126, 12, 50, 36), Color("#F4EFE2"), false, 3.0)
	c.draw_rect(Rect2(150, 12, 2, 36), Color("#F4EFE2"))
	# Stove with Mom stirring the pot.
	c.draw_rect(Rect2(150, 54, 40, 30), Color("#F4F1EA"))
	c.draw_rect(Rect2(156, 46, 22, 10), Color("#5A6B7A"))
	var stir := sin(t * 5.0) * 4.0
	_raccoon(c, Vector2(140, 62), 0.9, Color("#E04F5F"), false)
	c.draw_line(Vector2(150, 58), Vector2(166 + stir, 46), Color("#8D6E63"), 2.0)
	if fmod(t, 1.0) < 0.6:
		c.draw_circle(Vector2(162, 40 - fmod(t, 1.0) * 10.0), 3, Color(1, 1, 1, 0.6))
	# Table, Dad behind his newspaper.
	c.draw_rect(Rect2(40, 66, 70, 6), Color("#A0703E"))
	c.draw_rect(Rect2(46, 72, 4, 14), Color("#7A5230"))
	c.draw_rect(Rect2(100, 72, 4, 14), Color("#7A5230"))
	_raccoon(c, Vector2(58, 58), 1.0, Color("#4A6FA5"), false)
	var rustle := sin(t * 9.0) * 0.6 if fmod(t, 3.0) < 0.5 else 0.0
	c.draw_rect(Rect2(62 + rustle, 40, 24, 28), Color("#F2F0EA"))
	for i in 4:
		c.draw_rect(Rect2(65 + rustle, 44 + i * 5, 18, 2), Color("#9A968E"))
	# The kid juggling three apples.
	var kid := Vector2(100, 60)
	_raccoon(c, kid, 0.75, Color("#FFD23F"), true)
	for i in 3:
		var a := t * 4.0 + i * TAU / 3.0
		c.draw_circle(kid + Vector2(cos(a) * 9.0, -24.0 + sin(a) * 7.0 - absf(sin(a)) * 6.0), 3.0, Color("#D9302A"))
	# The baby bouncing in the high chair.
	c.draw_rect(Rect2(14, 62, 18, 4), Color("#F4F1EA"))
	c.draw_line(Vector2(16, 66), Vector2(14, 86), Color("#F4F1EA"), 2.0)
	c.draw_line(Vector2(30, 66), Vector2(32, 86), Color("#F4F1EA"), 2.0)
	_raccoon(c, Vector2(23, 60 - absf(sin(t * 6.0)) * 3.0), 0.55, Color("#FFB3C7"), false)
	# Title card for the first moments, then a little laugh now and then.
	if on_for < 1.2:
		c.draw_rect(Rect2(36, 26, 124, 44), Color("#7A5230"))
		c.draw_rect(Rect2(40, 30, 116, 36), Color("#F2C230"))
		_text(c, "Les Ratons", Vector2(40, 54), 18, Color("#5A3A22"), 116, HORIZONTAL_ALIGNMENT_CENTER)
	elif fmod(t, 6.0) > 5.0:
		_text(c, "ha ha ha !", Vector2(6, 16), 10, Color("#5A3A22"))


# A cartoon raccoon sitting at `at` (head centre), wearing a shirt of `shirt` colour.
static func _raccoon(c: CanvasItem, at: Vector2, k: float, shirt: Color, tail_up: bool) -> void:
	var grey := Color("#8E9096")
	var dark := Color("#3A3A40")
	# Striped tail.
	var tail := at + Vector2(-12, 18) * k
	for i in 4:
		var p := tail + Vector2(-4 * i, (-5 if tail_up else 2) * i) * k
		c.draw_circle(p, 4.5 * k, dark if i % 2 == 0 else grey)
	c.draw_rect(Rect2(at.x - 9 * k, at.y + 6 * k, 18 * k, 16 * k), shirt)
	for e in [-1.0, 1.0]:
		c.draw_colored_polygon(PackedVector2Array([at + Vector2(e * 5, -8) * k, at + Vector2(e * 11, -15) * k, at + Vector2(e * 11, -5) * k]), grey)
	c.draw_circle(at, 10 * k, grey)
	c.draw_rect(Rect2(at.x - 10 * k, at.y - 3 * k, 20 * k, 6 * k), dark)
	c.draw_circle(at + Vector2(-4, 0) * k, 1.8 * k, Color.WHITE)
	c.draw_circle(at + Vector2(4, 0) * k, 1.8 * k, Color.WHITE)
	c.draw_circle(at + Vector2(-4, 0) * k, 0.9 * k, Color.BLACK)
	c.draw_circle(at + Vector2(4, 0) * k, 0.9 * k, Color.BLACK)
	c.draw_circle(at + Vector2(0, 5) * k, 4 * k, Color("#F1EEE8"))
	c.draw_circle(at + Vector2(0, 3.5) * k, 1.4 * k, Color.BLACK)


# "Cuisine": a chef flipping a crêpe over the stove, steam rising.
static func _cooking(c: CanvasItem, t: float, _on_for: float) -> void:
	c.draw_rect(Rect2(Vector2.ZERO, SIZE), Color("#F6E6C8"))
	for x in range(0, int(SIZE.x), 14):
		for y in range(0, 60, 14):
			c.draw_rect(Rect2(x + 1, y + 1, 12, 12), Color("#FFFFFF", 0.5))
	c.draw_rect(Rect2(0, 74, SIZE.x, 34), Color("#9A6A3E"))
	c.draw_rect(Rect2(0, 72, SIZE.x, 4), Color("#C8955E"))
	# The chef: toque, white jacket, red scarf, arm with the pan.
	var chef := Vector2(70, 50)
	c.draw_rect(Rect2(chef.x - 14, chef.y + 6, 28, 22), Color.WHITE)
	c.draw_circle(chef, 11, Color("#E8B892"))
	c.draw_circle(chef + Vector2(-4, -2), 1.4, Color.BLACK)
	c.draw_circle(chef + Vector2(4, -2), 1.4, Color.BLACK)
	c.draw_arc(chef + Vector2(0, 3), 4, 0.3, PI - 0.3, 8, Color("#8E2A37"), 1.5)
	c.draw_rect(Rect2(chef.x - 10, chef.y - 20, 20, 10), Color.WHITE)
	c.draw_circle(chef + Vector2(-6, -22), 6, Color.WHITE)
	c.draw_circle(chef + Vector2(6, -22), 6, Color.WHITE)
	c.draw_circle(chef + Vector2(0, -26), 7, Color.WHITE)
	c.draw_rect(Rect2(chef.x - 6, chef.y + 6, 12, 4), Color("#E04F5F"))
	var pan := chef + Vector2(30, 14)
	var lift := maxf(0.0, sin(t * 3.0)) * 4.0
	c.draw_line(chef + Vector2(12, 12), pan + Vector2(-10, -lift), Color("#E8B892"), 4.0)
	c.draw_line(pan + Vector2(-12, -lift), pan + Vector2(-2, -lift), Color("#3A3A3A"), 3.0)
	c.draw_rect(Rect2(pan.x - 2, pan.y - 3 - lift, 22, 5), Color("#2E2E2E"))
	# The crêpe arcs up and flips over.
	var phase := fmod(t * 0.6, 1.0)
	var crepe := pan + Vector2(9, -6 - lift - sin(phase * PI) * 40.0)
	c.draw_set_transform(crepe, phase * TAU, Vector2(1.0, 0.35))
	c.draw_circle(Vector2.ZERO, 9, Color("#F2C26A"))
	c.draw_circle(Vector2(3, 0), 3, Color("#D9A04A"))
	c.draw_set_transform(Vector2.ZERO)
	for i in 3:
		var y := 70.0 - fmod(t * 14.0 + i * 9.0, 30.0)
		c.draw_circle(Vector2(150 + sin(t * 2.0 + i) * 4.0, y), 4, Color(1, 1, 1, 0.35))
	c.draw_rect(Rect2(136, 66, 30, 8), Color("#5A5A60"))
	c.draw_rect(Rect2(0, 94, SIZE.x, 14), Color("#C8202A"))
	_text(c, "CUISINE  •  Les crêpes du dimanche", Vector2(6, 105), 10, Color.WHITE)


# "Espace": a rocket climbing past the stars, a ringed planet and its moon.
static func _space(c: CanvasItem, t: float, _on_for: float) -> void:
	c.draw_rect(Rect2(Vector2.ZERO, SIZE), Color("#0E1430"))
	for i in 40:
		var star := Vector2(fmod(i * 47.3, SIZE.x), fmod(i * 29.7 + t * (6.0 + i % 3 * 4.0), SIZE.y))
		var tw := 0.5 + 0.5 * sin(t * 3.0 + i)
		c.draw_circle(star, 0.8 + (i % 3) * 0.4, Color(1, 1, 1, 0.4 + 0.6 * tw))
	var planet := Vector2(150, 34)
	c.draw_circle(planet, 18, Color("#E3A35A"))
	c.draw_circle(planet + Vector2(-5, -5), 10, Color("#F2C68A"))
	c.draw_set_transform(planet, -0.3, Vector2(1.0, 0.25))
	c.draw_arc(Vector2.ZERO, 30, 0, TAU, 32, Color("#F4E3B0"), 3.0)
	c.draw_set_transform(Vector2.ZERO)
	var moon := planet + Vector2.from_angle(t * 0.8) * Vector2(38, 14)
	c.draw_circle(moon, 4, Color("#C9CED6"))
	# Rocket wobbling upward, flame flickering.
	var rocket := Vector2(60 + sin(t * 1.5) * 6.0, 60 + sin(t * 3.0) * 3.0)
	c.draw_colored_polygon(PackedVector2Array([rocket + Vector2(0, -22), rocket + Vector2(8, -6), rocket + Vector2(8, 12), rocket + Vector2(-8, 12), rocket + Vector2(-8, -6)]), Color("#ECEFF4"))
	c.draw_circle(rocket + Vector2(0, -4), 4, Color("#5DA8FF"))
	c.draw_colored_polygon(PackedVector2Array([rocket + Vector2(-8, 4), rocket + Vector2(-14, 16), rocket + Vector2(-8, 12)]), Color("#E04F5F"))
	c.draw_colored_polygon(PackedVector2Array([rocket + Vector2(8, 4), rocket + Vector2(14, 16), rocket + Vector2(8, 12)]), Color("#E04F5F"))
	var flame := 10.0 + sin(t * 30.0) * 3.0
	c.draw_colored_polygon(PackedVector2Array([rocket + Vector2(-6, 12), rocket + Vector2(6, 12), rocket + Vector2(0, 12 + flame)]), Color("#FFB347"))
	c.draw_colored_polygon(PackedVector2Array([rocket + Vector2(-3, 12), rocket + Vector2(3, 12), rocket + Vector2(0, 12 + flame * 0.6)]), Color("#FFF3B0"))
	_text(c, "ESPACE", Vector2(6, 102), 10, Color("#9DB4FF"))


# "Musique": dancers in silhouette in front of a pulsing equalizer, notes floating up.
static func _music(c: CanvasItem, t: float, _on_for: float) -> void:
	var hue := fmod(t * 0.1, 1.0)
	c.draw_rect(Rect2(Vector2.ZERO, SIZE), Color.from_hsv(hue, 0.6, 0.45))
	for i in 14:
		var h := (0.3 + 0.7 * absf(sin(t * (3.0 + i * 0.37) + i))) * 60.0
		c.draw_rect(Rect2(6 + i * 13.5, 90 - h, 10, h), Color.from_hsv(fmod(hue + i * 0.05, 1.0), 0.7, 1.0, 0.8))
	for i in 3:
		var x := 50.0 + i * 50.0
		var bounce := absf(sin(t * 4.0 + i)) * 5.0
		var p := Vector2(x, 70 - bounce)
		var sway := sin(t * 4.0 + i) * 0.5
		c.draw_circle(p + Vector2(0, -22), 6, Color("#1A1020"))
		c.draw_line(p + Vector2(0, -16), p + Vector2(0, 4), Color("#1A1020"), 6.0)
		c.draw_line(p + Vector2(0, -12), p + Vector2.from_angle(-PI / 2 - 0.8 + sway) * 16 + Vector2(0, -12), Color("#1A1020"), 3.0)
		c.draw_line(p + Vector2(0, -12), p + Vector2.from_angle(-PI / 2 + 0.8 + sway) * 16 + Vector2(0, -12), Color("#1A1020"), 3.0)
		c.draw_line(p + Vector2(0, 4), p + Vector2(-6 - sway * 4, 20), Color("#1A1020"), 3.0)
		c.draw_line(p + Vector2(0, 4), p + Vector2(6 - sway * 4, 20), Color("#1A1020"), 3.0)
	for i in 4:
		var n := Vector2(fmod(30.0 + i * 47.0 + t * 8.0, SIZE.x), 70.0 - fmod(t * 18.0 + i * 20.0, 60.0))
		c.draw_circle(n, 3, Color(1, 1, 1, 0.85))
		c.draw_line(n + Vector2(2.5, 0), n + Vector2(2.5, -10), Color(1, 1, 1, 0.85), 1.5)
	c.draw_rect(Rect2(0, 92, SIZE.x, 16), Color(0, 0, 0, 0.5))
	_text(c, "MUSIQUE  •  Le palmarès", Vector2(6, 104), 10, Color.WHITE)


# "Jeu télévisé": a big prize wheel spinning, bulbs chasing round the set.
static func _game(c: CanvasItem, t: float, _on_for: float) -> void:
	c.draw_rect(Rect2(Vector2.ZERO, SIZE), Color("#3A1A5E"))
	for i in 24:
		var on := (i + int(t * 8.0)) % 4 == 0
		var p := Vector2(4 + i * 8.2, 4) if i < 24 else Vector2.ZERO
		c.draw_circle(p, 2.2, Color("#FFF3B0") if on else Color("#8A6A30"))
		c.draw_circle(Vector2(4 + i * 8.2, 104), 2.2, Color("#FFF3B0") if (i + int(t * 8.0)) % 4 == 2 else Color("#8A6A30"))
	var wheel := Vector2(98, 56)
	var spin := t * 2.5 + sin(t * 0.7) * 2.0
	var colors := [Color("#E04F5F"), Color("#FFD23F"), Color("#3E8E5A"), Color("#4A6FA5"), Color("#FF8A3D"), Color("#7E57C2")]
	for i in 12:
		var a0 := spin + TAU * i / 12.0
		var a1 := spin + TAU * (i + 1) / 12.0
		c.draw_colored_polygon(PackedVector2Array([wheel, wheel + Vector2.from_angle(a0) * 34.0, wheel + Vector2.from_angle((a0 + a1) / 2.0) * 35.0, wheel + Vector2.from_angle(a1) * 34.0]), colors[i % colors.size()])
	c.draw_arc(wheel, 35, 0, TAU, 40, Color("#F4E3B0"), 3.0)
	c.draw_circle(wheel, 6, Color("#F4E3B0"))
	c.draw_colored_polygon(PackedVector2Array([wheel + Vector2(-6, -44), wheel + Vector2(6, -44), wheel + Vector2(0, -32)]), Color.WHITE)
	# The host, waving.
	var host := Vector2(162, 64)
	c.draw_rect(Rect2(host.x - 8, host.y, 16, 24), Color("#C8202A"))
	c.draw_circle(host + Vector2(0, -7), 7, Color("#D29A6E"))
	c.draw_line(host + Vector2(-8, 4), host + Vector2(-16, -8 + sin(t * 8.0) * 4.0), Color("#D29A6E"), 3.0)
	_text(c, "JEU TÉLÉVISÉ", Vector2(6, 96), 10, Color("#FFD23F"))
