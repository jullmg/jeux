class_name TvScreen
extends Control
## The salon TV's picture. Click it: it turns on; click again: next channel; after the last one, off.
## Channels are tiny animated shows drawn in code (all original, including the family sitcom "Les Ratons"), a burst of static between them, and the screen's glow
## lights the room. Interactable like StrayCat (see PlayerControl).

const SIZE := Vector2(196, 108)
const SWITCH_TIME := 0.3
const CHANNELS := [
	{"name": "Nouvelles", "glow": Color(0.45, 0.6, 1.0)},
	{"name": "Animaux", "glow": Color(1.0, 0.8, 0.4)},
	{"name": "Dessins animés", "glow": Color(1.0, 0.6, 0.85)},
	{"name": "Hockey", "glow": Color(0.85, 0.92, 1.0)},
	{"name": "Météo", "glow": Color(0.5, 0.85, 0.7)},
	{"name": "Les Ratons", "glow": Color(0.75, 0.95, 0.7)},
]
const TICKER := "Il fera beau à Montréal aujourd'hui  •  Les écureuils de la 6e Avenue font leurs provisions pour l'hiver  •  Des bonbons d'Halloween au dépanneur Xin-Xin  •  La ruelle verte est pleine de feuilles  •  "

## -1 = off.
var channel := -1
## Where Charlotte stands to use it, and the room glow it drives (both set by the house).
var stand_x := 0.0
var glow: Sprite2D

var _t := 0.0
var _switching := 0.0
var _osd := 0.0
var _font: Font


func _ready() -> void:
	size = SIZE
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_font = ThemeDB.fallback_font
	add_to_group("interactable")
	_update_glow()


func _process(delta: float) -> void:
	_t += delta
	_switching = maxf(_switching - delta, 0.0)
	_osd = maxf(_osd - delta, 0.0)
	if glow and channel >= 0:
		glow.modulate.a = 0.75 + 0.15 * sin(_t * 7.0) + 0.1 * sin(_t * 17.0) if _switching == 0.0 else 0.4 + randf() * 0.4
	if channel >= 0:
		queue_redraw()


# ── Interactable ────────────────────────────────────────────────

func can_interact() -> bool:
	return true


func hit_test(p: Vector2) -> bool:
	return get_global_rect().grow(6.0).has_point(p)


func approach_x(_from_x: float) -> float:
	return stand_x


func focus_x() -> float:
	return get_global_rect().get_center().x


func reserve() -> void:
	pass


func release() -> void:
	pass


func interact(_who: Character) -> void:
	channel += 1
	if channel >= CHANNELS.size():
		channel = -1
	_switching = SWITCH_TIME if channel >= 0 else 0.0
	_osd = 2.0
	_update_glow()
	queue_redraw()


func _update_glow() -> void:
	if glow:
		glow.visible = channel >= 0
		if channel >= 0:
			glow.self_modulate = CHANNELS[channel].glow


# ── Drawing ─────────────────────────────────────────────────────

func _draw() -> void:
	if channel < 0:
		return
	if _switching > 0.0:
		_static()
		return
	match channel:
		0: _news()
		1: _animals()
		2: _cartoon()
		3: _hockey()
		4: _weather()
		5: _ratons()
	# Scanlines and a soft vignette, like an old-fashioned picture.
	for y in range(0, int(SIZE.y), 3):
		draw_rect(Rect2(0, y, SIZE.x, 1), Color(0, 0, 0, 0.06))
	if _osd > 0.0:
		var a := clampf(_osd, 0.0, 1.0)
		_text("%d" % (channel + 1), Vector2(SIZE.x - 22, 18), 16, Color(0.4, 1.0, 0.5, a), 20, HORIZONTAL_ALIGNMENT_RIGHT)


func _text(s: String, at: Vector2, font_size: int, col: Color, width := -1.0, align := HORIZONTAL_ALIGNMENT_LEFT) -> void:
	draw_string(_font, at, s, align, width, font_size, col)


func _static() -> void:
	draw_rect(Rect2(Vector2.ZERO, SIZE), Color(0.3, 0.3, 0.32))
	for i in 160:
		var g := randf()
		draw_rect(Rect2(randf() * SIZE.x, randf() * SIZE.y, randf_range(2, 9), 2), Color(g, g, g))


func _news() -> void:
	draw_rect(Rect2(Vector2.ZERO, SIZE), Color("#1D3F7A"))
	draw_rect(Rect2(0, 0, SIZE.x, 50), Color("#2A5598"))
	# Picture box: a maple leaf.
	draw_rect(Rect2(118, 10, 66, 44), Color("#F4F1EA"))
	draw_rect(Rect2(121, 13, 60, 38), Color("#C8202A"))
	var leaf := PackedVector2Array()
	for i in 22:
		var a := TAU * i / 22.0 - PI / 2.0
		var r := 13.0 if i % 2 == 0 else 7.0
		leaf.append(Vector2(151, 33) + Vector2.from_angle(a) * r)
	draw_colored_polygon(leaf, Color.WHITE)
	# The anchor at the desk, talking.
	draw_rect(Rect2(28, 56, 56, 40), Color("#2E3440"))
	draw_colored_polygon(PackedVector2Array([Vector2(48, 56), Vector2(56, 70), Vector2(64, 56)]), Color.WHITE)
	draw_circle(Vector2(56, 40), 15, Color("#3A2618"))
	draw_circle(Vector2(56, 44), 12, Color("#E8B892"))
	draw_circle(Vector2(51, 42), 1.6, Color.BLACK)
	draw_circle(Vector2(61, 42), 1.6, Color.BLACK)
	var talk := absf(sin(_t * 11.0)) * 2.5
	draw_rect(Rect2(53, 49, 6, 1.0 + talk), Color("#8E2A37"))
	draw_rect(Rect2(10, 76, 110, 14), Color("#5A3A22"))
	# Lower third and the ticker.
	draw_rect(Rect2(0, 80, SIZE.x, 14), Color("#C8202A"))
	_text("NOUVELLES", Vector2(6, 91), 10, Color.WHITE)
	draw_rect(Rect2(0, 94, SIZE.x, 14), Color("#F4F1EA"))
	var w := _font.get_string_size(TICKER, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x
	var x := -fmod(_t * 40.0, w)
	_text(TICKER + TICKER, Vector2(x, 105), 10, Color("#1D3F7A"))


func _animals() -> void:
	draw_rect(Rect2(Vector2.ZERO, SIZE), Color("#F6C77A"))
	draw_rect(Rect2(0, 0, SIZE.x, 30), Color("#F8DDA0"))
	draw_circle(Vector2(150, 30), 14, Color("#FFF1B8"))
	draw_rect(Rect2(0, 70, SIZE.x, 38), Color("#C9A24A"))
	# Acacia.
	draw_line(Vector2(40, 72), Vector2(44, 40), Color("#5E4A3C"), 3.0)
	draw_colored_polygon(PackedVector2Array([Vector2(16, 42), Vector2(70, 36), Vector2(64, 30), Vector2(24, 32)]), Color("#5E7A2E"))
	# A giraffe ambling across.
	var gx := fmod(_t * 18.0, SIZE.x + 80.0) - 40.0
	var step := sin(_t * 5.0) * 4.0
	var spot := Color("#A8642A")
	for leg in [[-10, step], [-4, -step], [10, -step], [16, step]]:
		draw_line(Vector2(gx + leg[0], 62), Vector2(gx + leg[0] + leg[1], 84), Color("#E8B04A"), 3.0)
	draw_set_transform(Vector2(gx + 3, 60), 0.0, Vector2(1.0, 0.55))
	draw_circle(Vector2.ZERO, 16, Color("#E8B04A"))
	draw_set_transform(Vector2.ZERO)
	for s in [Vector2(-6, -2), Vector2(4, 0), Vector2(10, -4)]:
		draw_circle(Vector2(gx, 60) + s, 2.5, spot)
	var nod := sin(_t * 2.5) * 2.0
	draw_line(Vector2(gx + 14, 56), Vector2(gx + 24, 26 + nod), Color("#E8B04A"), 6.0)
	draw_circle(Vector2(gx + 28, 26 + nod), 5.0, Color("#E8B04A"))
	draw_circle(Vector2(gx + 29, 24 + nod), 1.2, Color.BLACK)
	draw_line(Vector2(gx + 25, 21 + nod), Vector2(gx + 24, 16 + nod), Color("#A8642A"), 2.0)
	_text("ANIMAUX", Vector2(6, 102), 10, Color("#5E3A12"))


# An original cartoon: a bouncy bunny chasing a hopping carrot over the hills.
func _cartoon() -> void:
	draw_rect(Rect2(Vector2.ZERO, SIZE), Color("#BDE6FF"))
	for c in [Vector2(30, 20), Vector2(130, 14)]:
		var drift := Vector2(fmod(_t * 6.0, 40.0), 0)
		draw_circle(c + drift, 9, Color.WHITE)
		draw_circle(c + drift + Vector2(9, 2), 7, Color.WHITE)
	draw_circle(Vector2(40, 150), 90, Color("#7CCB5A"))
	draw_circle(Vector2(170, 160), 90, Color("#62B548"))
	var run := fmod(_t * 35.0, SIZE.x + 90.0) - 60.0
	var carrot := Vector2(run + 50, 62 - absf(sin(_t * 8.0)) * 14.0)
	draw_colored_polygon(PackedVector2Array([carrot + Vector2(-4, -6), carrot + Vector2(4, -6), carrot + Vector2(0, 10)]), Color("#FF8A3D"))
	draw_line(carrot + Vector2(0, -6), carrot + Vector2(-3, -12), Color("#3E8E5A"), 2.0)
	draw_line(carrot + Vector2(0, -6), carrot + Vector2(3, -12), Color("#3E8E5A"), 2.0)
	var bunny := Vector2(run, 66 - absf(sin(_t * 6.0)) * 18.0)
	draw_circle(bunny, 10, Color.WHITE)
	draw_circle(bunny + Vector2(9, -8), 7, Color.WHITE)
	for e in [Vector2(6, -22), Vector2(12, -22)]:
		draw_set_transform(bunny + e, 0.25, Vector2(0.4, 1.0))
		draw_circle(Vector2.ZERO, 7, Color.WHITE)
		draw_circle(Vector2.ZERO, 4, Color("#FFB3C7"))
		draw_set_transform(Vector2.ZERO)
	draw_circle(bunny + Vector2(12, -9), 1.4, Color.BLACK)
	draw_circle(bunny + Vector2(15, -6), 1.4, Color("#FF5D8F"))
	draw_circle(bunny + Vector2(-10, 2), 4, Color.WHITE)
	if fmod(_t, 1.2) < 0.6:
		for i in 3:
			var st := bunny + Vector2(-16 - i * 8, -14 + i * 6)
			draw_circle(st, 1.6, Color("#FFD23F"))
	_text("DESSINS ANIMÉS", Vector2(6, 102), 10, Color("#1D4F91"))


func _hockey() -> void:
	draw_rect(Rect2(Vector2.ZERO, SIZE), Color("#EEF4F8"))
	draw_rect(Rect2(0, 0, SIZE.x, 16), Color("#3A3F48"))
	for i in 6:
		draw_rect(Rect2(4 + i * 32, 4, 28, 8), [Color("#C8202A"), Color("#1D4F91"), Color("#FFD23F")][i % 3])
	draw_rect(Rect2(0, 16, SIZE.x, 3), Color("#F4F1EA"))
	draw_rect(Rect2(97, 19, 3, 89), Color("#C8202A", 0.8))
	draw_rect(Rect2(60, 19, 3, 89), Color("#1D4F91", 0.7))
	draw_rect(Rect2(134, 19, 3, 89), Color("#1D4F91", 0.7))
	draw_arc(Vector2(98, 64), 16, 0, TAU, 24, Color("#1D4F91", 0.6), 1.5)
	var puck := Vector2(98 + sin(_t * 1.3) * 70.0, 64 + sin(_t * 2.1) * 26.0)
	for i in 6:
		var team := Color("#C8202A") if i < 3 else Color("#1D4F91")
		var chase := puck + Vector2(cos(_t * 1.7 + i * 1.3) * (14 + i * 4), sin(_t * 2.3 + i) * 12.0)
		draw_circle(chase + Vector2(0, -8), 3.0, Color("#2B2B2B"))
		draw_rect(Rect2(chase.x - 4, chase.y - 5, 8, 9), team)
		draw_line(chase + Vector2(3, 3), chase + Vector2(9, 8), Color("#8D6E63"), 1.5)
	draw_circle(puck, 2.2, Color.BLACK)
	draw_rect(Rect2(4, 92, 96, 13), Color("#2E3440"))
	_text("ROUGES 2  BLEUS 1", Vector2(8, 102), 9, Color.WHITE)


func _weather() -> void:
	draw_rect(Rect2(Vector2.ZERO, SIZE), Color("#3D7FD0"))
	var land := PackedVector2Array([Vector2(0, 30), Vector2(60, 18), Vector2(110, 26), Vector2(150, 12), Vector2(196, 20),
		Vector2(196, 108), Vector2(0, 108)])
	draw_colored_polygon(land, Color("#7CBF6A"))
	draw_polyline(PackedVector2Array([Vector2(0, 86), Vector2(60, 70), Vector2(120, 64), Vector2(196, 44)]), Color("#3D7FD0"), 5.0)
	var city := Vector2(92, 66)
	draw_circle(city, 3, Color("#C8202A"))
	_text("Montréal", city + Vector2(-26, 14), 9, Color("#1E1E1E"))
	var sun := city + Vector2(-6, -24)
	for i in 8:
		var a := TAU * i / 8.0 + _t
		draw_line(sun + Vector2.from_angle(a) * 9, sun + Vector2.from_angle(a) * 13, Color("#FFD23F"), 2.0)
	draw_circle(sun, 7, Color("#FFD23F"))
	_text("12°", sun + Vector2(12, 5), 13, Color.WHITE)
	var cloud := Vector2(fmod(_t * 12.0, SIZE.x + 40) - 20, 40)
	for c in [Vector2(0, 0), Vector2(8, -4), Vector2(16, 0)]:
		draw_circle(cloud + c, 7, Color(1, 1, 1, 0.9))
	draw_rect(Rect2(0, 92, SIZE.x, 16), Color("#1D3F7A"))
	_text("MÉTÉO  •  Ensoleillé, 12°", Vector2(6, 103), 10, Color.WHITE)


# "Les Ratons", an original family sitcom: a raccoon family in their kitchen. Dad reads the paper, Mom
# stirs the soup, the kid juggles apples, the baby bounces in the high chair; a title card opens it.
func _ratons() -> void:
	draw_rect(Rect2(Vector2.ZERO, SIZE), Color("#CFE3B8"))
	for x in range(0, int(SIZE.x), 12):
		draw_rect(Rect2(x, 78, 6, 30), Color("#F4EFE2"))
		draw_rect(Rect2(x + 6, 78, 6, 30), Color("#E06A5A"))
	draw_rect(Rect2(126, 12, 50, 36), Color("#8FC6E8"))
	draw_rect(Rect2(126, 12, 50, 36), Color("#F4EFE2"), false, 3.0)
	draw_rect(Rect2(150, 12, 2, 36), Color("#F4EFE2"))
	# Stove with Mom stirring the pot.
	draw_rect(Rect2(150, 54, 40, 30), Color("#F4F1EA"))
	draw_rect(Rect2(156, 46, 22, 10), Color("#5A6B7A"))
	var stir := sin(_t * 5.0) * 4.0
	_raccoon(Vector2(140, 62), 0.9, Color("#E04F5F"), false)
	draw_line(Vector2(150, 58), Vector2(166 + stir, 46), Color("#8D6E63"), 2.0)
	if fmod(_t, 1.0) < 0.6:
		draw_circle(Vector2(162, 40 - fmod(_t, 1.0) * 10.0), 3, Color(1, 1, 1, 0.6))
	# Table, Dad behind his newspaper.
	draw_rect(Rect2(40, 66, 70, 6), Color("#A0703E"))
	draw_rect(Rect2(46, 72, 4, 14), Color("#7A5230"))
	draw_rect(Rect2(100, 72, 4, 14), Color("#7A5230"))
	_raccoon(Vector2(58, 58), 1.0, Color("#4A6FA5"), false)
	var rustle := sin(_t * 9.0) * 0.6 if fmod(_t, 3.0) < 0.5 else 0.0
	draw_rect(Rect2(62 + rustle, 40, 24, 28), Color("#F2F0EA"))
	for i in 4:
		draw_rect(Rect2(65 + rustle, 44 + i * 5, 18, 2), Color("#9A968E"))
	# The kid juggling three apples.
	var kid := Vector2(100, 60)
	_raccoon(kid, 0.75, Color("#FFD23F"), true)
	for i in 3:
		var a := _t * 4.0 + i * TAU / 3.0
		draw_circle(kid + Vector2(cos(a) * 9.0, -24.0 + sin(a) * 7.0 - absf(sin(a)) * 6.0), 3.0, Color("#D9302A"))
	# The baby bouncing in the high chair.
	draw_rect(Rect2(14, 62, 18, 4), Color("#F4F1EA"))
	draw_line(Vector2(16, 66), Vector2(14, 86), Color("#F4F1EA"), 2.0)
	draw_line(Vector2(30, 66), Vector2(32, 86), Color("#F4F1EA"), 2.0)
	_raccoon(Vector2(23, 60 - absf(sin(_t * 6.0)) * 3.0), 0.55, Color("#FFB3C7"), false)
	# Title card for the first moments, then a little laugh now and then.
	if _osd > 0.8:
		draw_rect(Rect2(36, 26, 124, 44), Color("#7A5230"))
		draw_rect(Rect2(40, 30, 116, 36), Color("#F2C230"))
		_text("Les Ratons", Vector2(40, 54), 18, Color("#5A3A22"), 116, HORIZONTAL_ALIGNMENT_CENTER)
	elif fmod(_t, 6.0) > 5.0:
		_text("ha ha ha !", Vector2(6, 16), 10, Color("#5A3A22"))


# A cartoon raccoon sitting at `at` (head centre), wearing a shirt of `shirt` colour.
func _raccoon(at: Vector2, k: float, shirt: Color, tail_up: bool) -> void:
	var grey := Color("#8E9096")
	var dark := Color("#3A3A40")
	# Striped tail.
	var tail := at + Vector2(-12, 18) * k
	for i in 4:
		var p := tail + Vector2(-4 * i, (-5 if tail_up else 2) * i) * k
		draw_circle(p, 4.5 * k, dark if i % 2 == 0 else grey)
	draw_rect(Rect2(at.x - 9 * k, at.y + 6 * k, 18 * k, 16 * k), shirt)
	for e in [-1.0, 1.0]:
		draw_colored_polygon(PackedVector2Array([at + Vector2(e * 5, -8) * k, at + Vector2(e * 11, -15) * k, at + Vector2(e * 11, -5) * k]), grey)
	draw_circle(at, 10 * k, grey)
	draw_rect(Rect2(at.x - 10 * k, at.y - 3 * k, 20 * k, 6 * k), dark)
	draw_circle(at + Vector2(-4, 0) * k, 1.8 * k, Color.WHITE)
	draw_circle(at + Vector2(4, 0) * k, 1.8 * k, Color.WHITE)
	draw_circle(at + Vector2(-4, 0) * k, 0.9 * k, Color.BLACK)
	draw_circle(at + Vector2(4, 0) * k, 0.9 * k, Color.BLACK)
	draw_circle(at + Vector2(0, 5) * k, 4 * k, Color("#F1EEE8"))
	draw_circle(at + Vector2(0, 3.5) * k, 1.4 * k, Color.BLACK)
