class_name TvShows
extends RefCounted
## The TV channels: tiny animated shows drawn in code on a SIZE screen, all original. The movie nights' films (not channels)
## carry the real films' titles Julien chose, but their pictures are little scenes of our own that only call the story to
## mind (a sleigh and a growing heart, a plane over a house, a rat chef in Paris, an ice palace): no character of theirs. Any TvScreen (in any
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
	# Not a channel of ALL: the film of the movie night (Cinema), put on by the house.
	"film": {"name": "Le petit renard des neiges", "glow": Color(0.55, 0.65, 1.0)},
	# The films she can pick on a movie night she asked for (Cinema.FILMS).
	"grinch": {"name": "Le Grinch", "glow": Color(0.6, 1.0, 0.6)},
	"maison": {"name": "Maman, j'ai raté l'avion", "glow": Color(1.0, 0.75, 0.5)},
	"ratatouille": {"name": "Ratatouille", "glow": Color(1.0, 0.85, 0.6)},
	"reine": {"name": "La Reine des neiges", "glow": Color(0.6, 0.85, 1.0)},
}
## How long the film lasts (title card, story, "FIN"), in seconds.
const FILM_LENGTH := 24.0
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
		"film": _film(c, t, on_for)
		"grinch": _grinch(c, t, on_for)
		"maison": _maison(c, t, on_for)
		"ratatouille": _ratatouille(c, t, on_for)
		"reine": _reine(c, t, on_for)


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


# The Canadiens (red jerseys with a white and blue stripe, the CH at centre ice) against a team in white.
static func _hockey(c: CanvasItem, t: float, on_for: float) -> void:
	c.draw_rect(Rect2(Vector2.ZERO, SIZE), Color("#EEF4F8"))
	c.draw_rect(Rect2(0, 0, SIZE.x, 16), Color("#3A3F48"))
	for i in 6:
		c.draw_rect(Rect2(4 + i * 32, 4, 28, 8), [Color("#C8202A"), Color("#1D4F91"), Color("#FFFFFF")][i % 3])
	c.draw_rect(Rect2(0, 16, SIZE.x, 3), Color("#F4F1EA"))
	c.draw_rect(Rect2(97, 19, 3, 89), Color("#C8202A", 0.8))
	c.draw_rect(Rect2(60, 19, 3, 89), Color("#1D4F91", 0.7))
	c.draw_rect(Rect2(134, 19, 3, 89), Color("#1D4F91", 0.7))
	c.draw_arc(Vector2(98, 64), 16, 0, TAU, 24, Color("#1D4F91", 0.6), 1.5)
	# The CH on the ice: a red C round a red H.
	c.draw_arc(Vector2(98, 64), 8.0, 0.55, TAU - 0.55, 20, Color("#C8202A", 0.85), 3.2)
	c.draw_line(Vector2(95, 59), Vector2(95, 69), Color("#C8202A", 0.85), 1.8)
	c.draw_line(Vector2(101, 59), Vector2(101, 69), Color("#C8202A", 0.85), 1.8)
	c.draw_line(Vector2(95, 64), Vector2(101, 64), Color("#C8202A", 0.85), 1.8)
	var puck := Vector2(98 + sin(t * 1.3) * 70.0, 64 + sin(t * 2.1) * 26.0)
	for i in 6:
		var home := i < 3
		var chase := puck + Vector2(cos(t * 1.7 + i * 1.3) * (14 + i * 4), sin(t * 2.3 + i) * 12.0)
		c.draw_circle(chase + Vector2(0, -8), 3.0, Color("#2B2B2B"))
		c.draw_rect(Rect2(chase.x - 4, chase.y - 5, 8, 9), Color("#C8202A") if home else Color("#F4F1EA"))
		# The Canadiens' white and blue stripe round the red jersey; the visitors' blue one.
		c.draw_rect(Rect2(chase.x - 4, chase.y - 1, 8, 1.5), Color("#F4F1EA") if home else Color("#1D4F91"))
		c.draw_rect(Rect2(chase.x - 4, chase.y + 0.5, 8, 1.5), Color("#1D4F91"))
		c.draw_line(chase + Vector2(3, 3), chase + Vector2(9, 8), Color("#8D6E63"), 1.5)
	c.draw_circle(puck, 2.2, Color.BLACK)
	c.draw_rect(Rect2(4, 92, 128, 13), Color("#2E3440"))
	_text(c, "CANADIENS 2  VISITEURS 1", Vector2(8, 102), 9, Color.WHITE)


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


# The movie night's film, an original little cartoon: a fox in a blue scarf sledding down snowy hills at night under the
# moon, past the pines and a snowman who waves. A title card first, "FIN" at the end.
static func _film(c: CanvasItem, t: float, on_for: float) -> void:
	var night := Color("#16224A")
	c.draw_rect(Rect2(Vector2.ZERO, SIZE), night)
	c.draw_rect(Rect2(0, 36, SIZE.x, 40), Color("#24386E"))
	for i in 18:
		var star := Vector2(fmod(i * 47.0, SIZE.x), fmod(i * 23.0, 44.0) + 4.0)
		var tw := 0.5 + 0.5 * sin(t * 3.0 + i)
		c.draw_circle(star, 0.8 + tw * 0.6, Color(1, 1, 0.85, 0.5 + tw * 0.5))
	if on_for < 3.0 or on_for > FILM_LENGTH - 3.0:
		var title := on_for < 3.0
		var fade := clampf(minf(on_for, 3.0 - on_for) * 2.0, 0.0, 1.0) if title else clampf((on_for - FILM_LENGTH + 3.0) * 2.0, 0.0, 1.0)
		var ink := Color("#FFD23F", fade)
		if title:
			_text(c, "LE PETIT RENARD", Vector2(0, 46), 17, ink, SIZE.x, HORIZONTAL_ALIGNMENT_CENTER)
			_text(c, "des neiges", Vector2(0, 66), 13, Color(1, 1, 1, fade), SIZE.x, HORIZONTAL_ALIGNMENT_CENTER)
			_fox(c, Vector2(98, 90), 0.9, t, Color(1, 1, 1, fade))
		else:
			_text(c, "FIN", Vector2(0, 62), 30, ink, SIZE.x, HORIZONTAL_ALIGNMENT_CENTER)
		return
	# The moon and the hills.
	c.draw_circle(Vector2(160, 22), 11, Color("#FFF6D0"))
	c.draw_circle(Vector2(156, 19), 2.5, Color("#EDE2B4"))
	c.draw_circle(Vector2(30, 150), 85, Color("#DDE8F6"))
	c.draw_circle(Vector2(180, 168), 95, Color("#EEF4FC"))
	for p in [Vector2(24, 64), Vector2(40, 70), Vector2(170, 72), Vector2(186, 76)]:
		c.draw_colored_polygon(PackedVector2Array([p + Vector2(-7, 14), p + Vector2(7, 14), p + Vector2(0, -8)]), Color("#2E5A44"))
		c.draw_colored_polygon(PackedVector2Array([p + Vector2(-3, -2), p + Vector2(3, -2), p + Vector2(0, -8)]), Color.WHITE)
	# The snowman, waving his stick arm as the fox goes by.
	var sm := Vector2(140, 80)
	c.draw_circle(sm, 8, Color.WHITE)
	c.draw_circle(sm + Vector2(0, -11), 5.5, Color.WHITE)
	c.draw_circle(sm + Vector2(-2, -12), 0.9, Color.BLACK)
	c.draw_circle(sm + Vector2(2, -12), 0.9, Color.BLACK)
	c.draw_colored_polygon(PackedVector2Array([sm + Vector2(0, -10.5), sm + Vector2(0, -9), sm + Vector2(5, -9.5)]), Color("#FF8A3D"))
	c.draw_line(sm + Vector2(6, -3), sm + Vector2(13, -9 + sin(t * 6.0) * 3.0), Color("#6E4424"), 1.2)
	# The fox on its red sled, down the slope from the left, again and again.
	var run := fmod((on_for - 3.0) * 26.0, SIZE.x + 70.0) - 35.0
	var at := Vector2(run, 52.0 + run * 0.22 + sin(run * 0.08) * 3.0)
	_fox(c, at, 1.0, t, Color.WHITE)
	# A puff of snow behind the sled.
	for i in 4:
		c.draw_circle(at + Vector2(-16 - i * 5, 6 - i), 2.2 - i * 0.4, Color(1, 1, 1, 0.7 - i * 0.15))
	# Snow falling.
	for i in 28:
		var x := fmod(i * 37.0 + sin(t + i) * 6.0, SIZE.x)
		var y := fmod(i * 19.0 + t * (10.0 + i % 5 * 3.0), SIZE.y)
		c.draw_circle(Vector2(x, y), 0.9 + (i % 3) * 0.4, Color(1, 1, 1, 0.85))


# The little fox on his sled at `at` (the sled's middle), `k` its size, his blue scarf flapping. `tint` fades him in.
static func _fox(c: CanvasItem, at: Vector2, k: float, t: float, tint: Color) -> void:
	var orange := Color("#E8762C") * tint
	c.draw_rect(Rect2(at + Vector2(-14, 2) * k, Vector2(28, 4) * k), Color("#D8352E") * tint)
	c.draw_line(at + Vector2(-16, 8) * k, at + Vector2(14, 8) * k, Color("#5A3A22") * tint, 1.2)
	c.draw_arc(at + Vector2(14, 5) * k, 3.0 * k, -PI / 2.0, PI / 2.0, 6, Color("#5A3A22") * tint, 1.2)
	# Tail curling up behind, white tip.
	c.draw_circle(at + Vector2(-12, -3) * k, 4.5 * k, orange)
	c.draw_circle(at + Vector2(-15, -6) * k, 2.6 * k, Color.WHITE * tint)
	c.draw_circle(at + Vector2(-1, -3) * k, 7.0 * k, orange)
	c.draw_circle(at + Vector2(1, 0) * k, 4.0 * k, Color("#FFF1E0") * tint)
	var head := at + Vector2(7, -11) * k
	c.draw_circle(head, 5.5 * k, orange)
	for e in [Vector2(-3, -4), Vector2(2.5, -5)]:
		c.draw_colored_polygon(PackedVector2Array([head + (e + Vector2(-2, 1)) * k, head + (e + Vector2(2, 1)) * k, head + (e + Vector2(0, -5)) * k]), orange)
	c.draw_colored_polygon(PackedVector2Array([head + Vector2(2, 0) * k, head + Vector2(9, 2) * k, head + Vector2(2, 4) * k]), Color("#FFF1E0") * tint)
	c.draw_circle(head + Vector2(9, 2) * k, 1.0 * k, Color.BLACK * tint)
	c.draw_circle(head + Vector2(1.5, -1) * k, 0.9 * k, Color.BLACK * tint)
	# The scarf, its end flying out behind him.
	c.draw_line(head + Vector2(-4, 5) * k, head + Vector2(3, 5) * k, Color("#4FA3E0") * tint, 2.2 * k)
	c.draw_line(head + Vector2(-4, 5) * k, head + Vector2(-12, 3 + sin(t * 14.0) * 2.0) * k, Color("#4FA3E0") * tint, 1.8 * k)


# ── The films she can choose on a movie night ───────────────────

## The title card for the first 3 s and "FIN" for the last 3, over `bg`; true while one of them is up (nothing else to draw).
static func _film_cards(c: CanvasItem, on_for: float, title: String, sub: String, bg: Color, ink: Color) -> bool:
	if on_for >= 3.0 and on_for <= FILM_LENGTH - 3.0:
		return false
	c.draw_rect(Rect2(Vector2.ZERO, SIZE), bg)
	var first := on_for < 3.0
	var fade := clampf(minf(on_for, 3.0 - on_for) * 2.0, 0.0, 1.0) if first else clampf((on_for - FILM_LENGTH + 3.0) * 2.0, 0.0, 1.0)
	if first:
		_text(c, title, Vector2(0, 52 if sub == "" else 46), 17, Color(ink, fade), SIZE.x, HORIZONTAL_ALIGNMENT_CENTER)
		if sub != "":
			_text(c, sub, Vector2(0, 68), 12, Color(1, 1, 1, fade), SIZE.x, HORIZONTAL_ALIGNMENT_CENTER)
	else:
		_text(c, "FIN", Vector2(0, 62), 30, Color(ink, fade), SIZE.x, HORIZONTAL_ALIGNMENT_CENTER)
	return true


static func _snowfall(c: CanvasItem, t: float, n: int) -> void:
	for i in n:
		var x := fmod(i * 37.0 + sin(t + i) * 6.0, SIZE.x)
		var y := fmod(i * 19.0 + t * (10.0 + i % 5 * 3.0), SIZE.y)
		c.draw_circle(Vector2(x, y), 0.9 + (i % 3) * 0.4, Color(1, 1, 1, 0.85))


static func _stars(c: CanvasItem, t: float, n: int, top: float) -> void:
	for i in n:
		var star := Vector2(fmod(i * 47.0, SIZE.x), fmod(i * 23.0, top) + 3.0)
		var tw := 0.5 + 0.5 * sin(t * 3.0 + i)
		c.draw_circle(star, 0.7 + tw * 0.5, Color(1, 1, 0.85, 0.4 + tw * 0.5))


## A little house with a roof at `at` (its foot's middle), `w` wide; `lit` its windows' light, `bulbs` Christmas lights.
static func _cottage(c: CanvasItem, at: Vector2, w: float, wall: Color, lit: float, t: float, bulbs := true) -> void:
	var h := w * 0.7
	c.draw_rect(Rect2(at.x - w / 2.0, at.y - h, w, h), wall)
	c.draw_colored_polygon(PackedVector2Array([at + Vector2(-w * 0.6, -h), at + Vector2(w * 0.6, -h), at + Vector2(0, -h - w * 0.45)]), Color("#3A2A3E"))
	c.draw_colored_polygon(PackedVector2Array([at + Vector2(-w * 0.6, -h), at + Vector2(w * 0.6, -h), at + Vector2(w * 0.45, -h - w * 0.1), at + Vector2(-w * 0.45, -h - w * 0.1)]), Color.WHITE)
	var glow := Color("#FFD27A").lerp(Color("#2A2F4A"), 1.0 - lit)
	c.draw_rect(Rect2(at.x - w * 0.32, at.y - h * 0.72, w * 0.22, w * 0.2), glow)
	c.draw_rect(Rect2(at.x + w * 0.1, at.y - h * 0.72, w * 0.22, w * 0.2), glow)
	if bulbs:
		var colors := [Color("#FF4D4D"), Color("#FFD23F"), Color("#4DD26B"), Color("#4FA3E0")]
		for i in 6:
			var on := lit > 0.5 and int(t * 3.0 + i) % 3 != 0
			c.draw_circle(at + Vector2(-w * 0.5 + i * w * 0.2, -h + 1.0), 1.1, colors[i % 4] if on else Color("#444455"))


# « Le Grinch »: a snowy village at night under the mountain; a sleigh with a big sack slips down from the cave and the
# houses go dark one by one; then the bells ring, the lights come back and a red heart grows big over the village.
static func _grinch(c: CanvasItem, t: float, on_for: float) -> void:
	if _film_cards(c, on_for, "LE GRINCH", "", Color("#0F2A1E"), Color("#7BE07B")):
		return
	var story := on_for - 3.0
	c.draw_rect(Rect2(Vector2.ZERO, SIZE), Color("#132046"))
	_stars(c, t, 16, 40.0)
	# The mountain and its cave, on the left.
	c.draw_colored_polygon(PackedVector2Array([Vector2(-10, 90), Vector2(40, 14), Vector2(95, 90)]), Color("#C9D6EA"))
	c.draw_colored_polygon(PackedVector2Array([Vector2(28, 32), Vector2(40, 14), Vector2(52, 32)]), Color.WHITE)
	c.draw_circle(Vector2(44, 40), 4.0, Color("#1A1A2E"))
	c.draw_rect(Rect2(0, 88, SIZE.x, 20), Color("#EEF4FC"))
	# The village: dark while the sleigh goes round (4–10 s), lit again after.
	var dark := clampf((story - 4.0) * 0.6, 0.0, 1.0) * (1.0 - clampf((story - 10.0) * 0.8, 0.0, 1.0))
	for i in 4:
		var walls := [Color("#E8A0B4"), Color("#A0C8E8"), Color("#F0D080"), Color("#B8E0A0")]
		_cottage(c, Vector2(108 + i * 24, 94), 18.0, walls[i], 1.0 - dark * (1.0 if i * 1.5 < story - 4.0 else 0.0), t)
	# The sleigh with its sack, down the mountain and along the village (2–10 s).
	if story > 1.5 and story < 10.0:
		var u := (story - 1.5) / 8.5
		var at := Vector2(lerpf(46, 190, u), lerpf(44, 86, minf(u * 2.0, 1.0)))
		c.draw_rect(Rect2(at + Vector2(-9, -4), Vector2(16, 5)), Color("#B5302E"))
		c.draw_line(at + Vector2(-10, 2), at + Vector2(9, 2), Color("#5A3A22"), 1.2)
		c.draw_circle(at + Vector2(-2, -9), 6.0, Color("#D9C9A8"))
		c.draw_line(at + Vector2(-2, -15), at + Vector2(-1, -18), Color("#8A6A3A"), 1.4)
	# The heart: it grows three sizes over the village while the bells ring (12 s on).
	if story > 11.0:
		var grow := clampf((story - 11.0) / 5.0, 0.0, 1.0)
		var beat := 1.0 + 0.06 * sin(t * 8.0)
		var r := lerpf(3.0, 15.0, ease(grow, 0.5)) * beat
		var hc := Vector2(98, 38)
		c.draw_circle(hc + Vector2(-r * 0.5, 0), r * 0.55, Color("#E0303A"))
		c.draw_circle(hc + Vector2(r * 0.5, 0), r * 0.55, Color("#E0303A"))
		c.draw_colored_polygon(PackedVector2Array([hc + Vector2(-r * 1.02, r * 0.15), hc + Vector2(r * 1.02, r * 0.15), hc + Vector2(0, r * 1.2)]), Color("#E0303A"))
		for i in 6:
			var a := TAU * i / 6.0 + t
			c.draw_circle(hc + Vector2(cos(a), sin(a)) * (r * 1.6 + 4.0), 1.0, Color("#FFD23F"))
	_snowfall(c, t, 18)


# « Maman, j'ai raté l'avion »: a big brick house all decorated for Christmas; a plane flies off over it without one of
# them; then, at the side door, a paint can swings down on its rope and a burglar's hat goes flying.
static func _maison(c: CanvasItem, t: float, on_for: float) -> void:
	if _film_cards(c, on_for, "MAMAN, J'AI RATÉ", "l'avion", Color("#3A1414"), Color("#FFD23F")):
		return
	var story := on_for - 3.0
	c.draw_rect(Rect2(Vector2.ZERO, SIZE), Color("#1A2650"))
	_stars(c, t, 14, 30.0)
	c.draw_rect(Rect2(0, 94, SIZE.x, 14), Color("#EEF4FC"))
	# The house: two floors of red brick, a white door with a wreath, every window lit, lights along the eaves.
	var house := Rect2(52, 40, 92, 54)
	c.draw_rect(house, Color("#9A3A2E"))
	for row in 6:
		c.draw_line(Vector2(house.position.x, house.position.y + 6 + row * 8), Vector2(house.end.x, house.position.y + 6 + row * 8), Color("#7E2E24"), 0.6)
	c.draw_colored_polygon(PackedVector2Array([Vector2(46, 40), Vector2(150, 40), Vector2(98, 18)]), Color("#2E2A3A"))
	for wx in [60.0, 82.0, 108.0, 130.0]:
		for wy in [48.0, 68.0]:
			if wy == 68.0 and (wx == 82.0 or wx == 108.0):
				continue
			c.draw_rect(Rect2(wx - 5, wy, 10, 12), Color("#FFD27A"))
			c.draw_line(Vector2(wx, wy), Vector2(wx, wy + 12), Color("#6E2A20"), 0.8)
	c.draw_rect(Rect2(90, 72, 16, 22), Color("#F4F1EA"))
	c.draw_arc(Vector2(98, 80), 4.0, 0, TAU, 12, Color("#2E8A44"), 2.0)
	var colors := [Color("#FF4D4D"), Color("#FFD23F"), Color("#4DD26B"), Color("#4FA3E0")]
	for i in 14:
		var p := Vector2(46, 40).lerp(Vector2(98, 18), i / 7.0) if i < 7 else Vector2(98, 18).lerp(Vector2(150, 40), (i - 7) / 7.0)
		c.draw_circle(p, 1.2, colors[(i + int(t * 3.0)) % 4])
	# The plane, high over the house (first seconds), its lights blinking.
	if story < 7.0:
		var px := lerpf(-20.0, 220.0, story / 7.0)
		var pa := Vector2(px, 16 - story * 0.8)
		c.draw_colored_polygon(PackedVector2Array([pa + Vector2(-12, 0), pa + Vector2(12, -1), pa + Vector2(14, 1), pa + Vector2(-12, 2)]), Color("#D8DCE6"))
		c.draw_colored_polygon(PackedVector2Array([pa + Vector2(-2, 0), pa + Vector2(4, 0), pa + Vector2(-4, 7)]), Color("#B8BEC9"))
		c.draw_colored_polygon(PackedVector2Array([pa + Vector2(-12, 0), pa + Vector2(-9, 0), pa + Vector2(-13, -5)]), Color("#B8BEC9"))
		if int(t * 4.0) % 2 == 0:
			c.draw_circle(pa + Vector2(13, 0), 1.0, Color("#FF4D4D"))
	# At the side door: the paint can swings down on its rope (8–15 s), a hat flies off, then again.
	if story > 7.5:
		var k := fmod(story - 7.5, 6.0)
		var pivot := Vector2(166, 40)
		var swing := lerpf(-1.4, 0.5, clampf(k / 1.2, 0.0, 1.0)) if k < 1.2 else 0.5 * cos((k - 1.2) * 3.0) * exp(-(k - 1.2) * 0.6)
		var can := pivot + Vector2(sin(swing), cos(swing)) * 30.0
		c.draw_line(pivot, can, Color("#D8D8D8"), 0.7)
		c.draw_rect(Rect2(can + Vector2(-3, 0), Vector2(6, 7)), Color("#C9CED6"))
		c.draw_rect(Rect2(can + Vector2(-3, 2), Vector2(6, 2)), Color("#4FA3E0"))
		# The burglar's hat flying off where it hits.
		if k > 1.2 and k < 3.5:
			var f := (k - 1.2) / 2.3
			var hat := Vector2(170, 72) + Vector2(f * 26.0, -sin(f * PI) * 26.0)
			c.draw_rect(Rect2(hat + Vector2(-4, -2), Vector2(8, 3)), Color("#2A2A2A"))
			c.draw_rect(Rect2(hat + Vector2(-2.5, -5), Vector2(5, 3)), Color("#2A2A2A"))
			_text(c, "BONG !", Vector2(150, 60), 10, Color("#FFD23F", 1.0 - f))
	_snowfall(c, t, 14)


# « Ratatouille »: Paris at night, the tower and the rooftops; then in a restaurant's kitchen a little grey rat in a white
# chef's hat stirs a big pot; last, the plate of ratatouille in its spiral of slices, under little stars.
static func _ratatouille(c: CanvasItem, t: float, on_for: float) -> void:
	if _film_cards(c, on_for, "RATATOUILLE", "", Color("#2A1A3A"), Color("#FFD23F")):
		return
	var story := on_for - 3.0
	if story < 7.0:
		# Paris: the sky, the tower and the roofs with their little windows.
		c.draw_rect(Rect2(Vector2.ZERO, SIZE), Color("#24305E"))
		_stars(c, t, 14, 40.0)
		c.draw_circle(Vector2(30, 20), 8.0, Color("#FFF6D0"))
		var base := Vector2(130, 92)
		c.draw_colored_polygon(PackedVector2Array([base + Vector2(-22, 0), base + Vector2(-4, -60), base + Vector2(4, -60), base + Vector2(22, 0), base + Vector2(14, 0), base + Vector2(0, -30), base + Vector2(-14, 0)]), Color("#3A3550"))
		c.draw_line(base + Vector2(0, -60), base + Vector2(0, -74), Color("#3A3550"), 1.5)
		c.draw_line(base + Vector2(-12, -30), base + Vector2(12, -30), Color("#3A3550"), 2.0)
		for i in 8:
			c.draw_circle(base + Vector2(0, -12 - i * 7), 0.9, Color("#FFD27A", 0.5 + 0.5 * sin(t * 5.0 + i)))
		for i in 6:
			var x := i * 34.0
			c.draw_rect(Rect2(x, 78, 32, 30), Color("#4A4060"))
			c.draw_colored_polygon(PackedVector2Array([Vector2(x - 2, 78), Vector2(x + 34, 78), Vector2(x + 28, 70), Vector2(x + 4, 70)]), Color("#5E6680"))
			c.draw_rect(Rect2(x + 6, 84, 6, 7), Color("#FFD27A"))
			c.draw_rect(Rect2(x + 20, 84, 6, 7), Color("#FFD27A") if i % 2 == 0 else Color("#2A2F4A"))
		return
	# The kitchen: tiles, the stove, the pot steaming, the little chef on the counter stirring it.
	c.draw_rect(Rect2(Vector2.ZERO, SIZE), Color("#F2E6D0"))
	for i in 12:
		c.draw_line(Vector2(i * 18.0, 0), Vector2(i * 18.0, 64), Color("#E0D2B8"), 0.6)
	c.draw_rect(Rect2(0, 64, SIZE.x, 44), Color("#8A9AA8"))
	c.draw_rect(Rect2(0, 64, SIZE.x, 4), Color("#B8C4CE"))
	if story < 15.0:
		var pot := Vector2(80, 64)
		c.draw_rect(Rect2(pot + Vector2(-22, -22), Vector2(44, 22)), Color("#5A5E66"))
		c.draw_rect(Rect2(pot + Vector2(-24, -24), Vector2(48, 4)), Color("#787C84"))
		for i in 3:
			var s := fmod(t * 0.8 + i * 0.33, 1.0)
			c.draw_circle(pot + Vector2(-10 + i * 10 + sin(t * 2.0 + i) * 3.0, -28 - s * 22.0), 3.0 + s * 3.0, Color(1, 1, 1, 0.5 * (1.0 - s)))
		# The rat: grey, round, a pink ear and nose, the tall white hat; the spoon going round in the pot.
		var rat := Vector2(126, 62)
		c.draw_circle(rat, 8.0, Color("#8A8E96"))
		c.draw_circle(rat + Vector2(-6, -9), 5.5, Color("#9A9EA6"))
		c.draw_circle(rat + Vector2(-3, -14), 2.6, Color("#9A9EA6"))
		c.draw_circle(rat + Vector2(-3, -14), 1.4, Color("#F2A0B0"))
		c.draw_circle(rat + Vector2(-11.5, -8), 1.1, Color("#F2A0B0"))
		c.draw_circle(rat + Vector2(-7.5, -10), 0.9, Color.BLACK)
		c.draw_rect(Rect2(rat + Vector2(-10, -24), Vector2(8, 9)), Color.WHITE)
		c.draw_circle(rat + Vector2(-6, -25), 5.0, Color.WHITE)
		c.draw_arc(rat + Vector2(9, 2), 7.0, -0.5, 1.6, 8, Color("#8A8E96"), 1.4)
		var hand := pot + Vector2(10 + cos(t * 4.0) * 8.0, -26 + sin(t * 4.0) * 2.0)
		c.draw_line(rat + Vector2(-8, -2), hand, Color("#B88A5A"), 1.6)
		return
	# The dish: the spiral of slices on a white plate, little stars round it.
	c.draw_circle(Vector2(98, 58), 30.0, Color.WHITE)
	c.draw_circle(Vector2(98, 58), 25.0, Color("#F4F1EA"))
	var slices := [Color("#C8303A"), Color("#E8B020"), Color("#5A2A60"), Color("#3E8E3A")]
	for i in 22:
		var a := i * 0.6
		var r := 4.0 + i * 0.85
		c.draw_circle(Vector2(98, 58) + Vector2(cos(a), sin(a) * 0.8) * r, 3.2, slices[i % 4])
	for i in 5:
		var a := TAU * i / 5.0 + t * 0.5
		c.draw_circle(Vector2(98, 58) + Vector2(cos(a), sin(a)) * 40.0, 1.3, Color("#FFD23F"))


# « La Reine des neiges »: mountains under the northern lights; the snow begins to swirl, and an ice palace grows out of
# it, spire after spire, sparkling; a snowman watches from the snow.
static func _reine(c: CanvasItem, t: float, on_for: float) -> void:
	if _film_cards(c, on_for, "LA REINE", "des neiges", Color("#14284E"), Color("#9FD8FF")):
		return
	var story := on_for - 3.0
	c.draw_rect(Rect2(Vector2.ZERO, SIZE), Color("#16224A"))
	# Northern lights, waving.
	for i in 3:
		var band := PackedVector2Array()
		for k in 21:
			var x := k * SIZE.x / 20.0
			band.append(Vector2(x, 18 + i * 7 + sin(x * 0.05 + t * 0.8 + i) * 5.0))
		c.draw_polyline(band, Color(0.4, 1.0, 0.75, 0.25), 5.0)
	_stars(c, t, 14, 30.0)
	c.draw_colored_polygon(PackedVector2Array([Vector2(-10, 100), Vector2(40, 40), Vector2(90, 100)]), Color("#B8CDE6"))
	c.draw_colored_polygon(PackedVector2Array([Vector2(110, 100), Vector2(165, 36), Vector2(215, 100)]), Color("#A8C0DE"))
	c.draw_rect(Rect2(0, 94, SIZE.x, 14), Color("#EEF4FC"))
	# The palace grows from the snow (4–12 s): a tall spire and its shorter ones, pale blue with sparkles.
	var grow := clampf((story - 4.0) / 8.0, 0.0, 1.0)
	if grow > 0.0:
		var foot := Vector2(100, 96)
		var ice := Color(0.72, 0.9, 1.0, 0.9)
		for spire: Vector3 in [Vector3(0, 52, 9), Vector3(-15, 36, 7), Vector3(15, 36, 7), Vector3(-27, 24, 5), Vector3(27, 24, 5)]:
			var h := spire.y * ease(grow, 0.6)
			var x := foot.x + spire.x
			c.draw_rect(Rect2(x - spire.z / 2.0, foot.y - h * 0.7, spire.z, h * 0.7), ice)
			c.draw_colored_polygon(PackedVector2Array([Vector2(x - spire.z / 2.0 - 1, foot.y - h * 0.7), Vector2(x + spire.z / 2.0 + 1, foot.y - h * 0.7), Vector2(x, foot.y - h)]), Color(0.85, 0.96, 1.0))
		for i in 8:
			var sp := foot + Vector2(sin(i * 2.3) * 26.0, -fmod(i * 13.0, 50.0) * grow)
			var tw := 0.5 + 0.5 * sin(t * 6.0 + i)
			c.draw_line(sp - Vector2(2, 0) * tw, sp + Vector2(2, 0) * tw, Color.WHITE, 0.8)
			c.draw_line(sp - Vector2(0, 2) * tw, sp + Vector2(0, 2) * tw, Color.WHITE, 0.8)
	# The swirl of snow round where the palace rises (2–12 s).
	if story > 2.0 and story < 13.0:
		var strength := clampf(minf(story - 2.0, 13.0 - story), 0.0, 1.0)
		for i in 24:
			var a := t * 2.0 + i * 0.5
			var r := 6.0 + fmod(i * 7.0, 40.0)
			c.draw_circle(Vector2(100, 70) + Vector2(cos(a), sin(a) * 0.5) * r, 1.1, Color(1, 1, 1, 0.8 * strength))
	# A snowman in the snow on the left, hopping a little.
	var sm := Vector2(34, 92 - absf(sin(t * 3.0)) * 2.0)
	c.draw_circle(sm, 7, Color.WHITE)
	c.draw_circle(sm + Vector2(0, -10), 5, Color.WHITE)
	c.draw_circle(sm + Vector2(-1.8, -11), 0.8, Color.BLACK)
	c.draw_circle(sm + Vector2(1.8, -11), 0.8, Color.BLACK)
	c.draw_colored_polygon(PackedVector2Array([sm + Vector2(0, -9.5), sm + Vector2(0, -8), sm + Vector2(4.5, -8.6)]), Color("#FF8A3D"))
	_snowfall(c, t, 16)
