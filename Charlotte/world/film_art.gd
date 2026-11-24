class_name FilmArt
extends RefCounted
## The films of the movie nights (Cinema.FILMS): each one a little animated picture book of four scenes drawn in code on
## the TV's SIZE canvas, about 96 s long (a title card, four scenes that melt into one another, "FIN"). The titles are
## the real films' that Julien chose; every picture is a scene of our own that only calls the story to mind (no character
## of theirs). `FilmArt.draw(id, canvas, t, on_for)` is called by `TvShows.draw`.
##
## What makes them pretty: skies and seas as vertex-coloured gradients, soft glows (layered discs), hills that roll in
## layers, light from one side, a letterbox, a vignette and a breath of grain over everything.
## A new film = an entry in `FILMS` (+ `TvShows.INFO` and the lines in house.gd `MOVIE_LINES`) and one `_<id>` function
## with a `match s` over its four scenes.

const SIZE := Vector2(196, 108)
## The whole film, the title card (CARD s) and the "FIN" card (CARD s) included.
const LENGTH := 96.0
const CARD := 4.0
const BAR := 6.0

## id -> title, subtitle, card background, card ink.
const FILMS := {
	"film": {"title": "LE PETIT RENARD", "sub": "des neiges", "bg": Color("#16224A"), "ink": Color("#FFD23F")},
	"grinch": {"title": "LE GRINCH", "sub": "", "bg": Color("#0F2A1E"), "ink": Color("#7BE07B")},
	"maison": {"title": "MAMAN, J'AI RATÉ", "sub": "l'avion", "bg": Color("#3A1414"), "ink": Color("#FFD23F")},
	"ratatouille": {"title": "RATATOUILLE", "sub": "", "bg": Color("#2A1A3A"), "ink": Color("#FFD23F")},
	"reine": {"title": "LA REINE", "sub": "des neiges", "bg": Color("#14284E"), "ink": Color("#9FD8FF")},
	"lion": {"title": "LE ROI LION", "sub": "", "bg": Color("#4A1E0A"), "ink": Color("#FFC940")},
	"nemo": {"title": "LE MONDE DE NEMO", "sub": "", "bg": Color("#06305A"), "ink": Color("#FFB347")},
	"up": {"title": "LÀ-HAUT", "sub": "", "bg": Color("#2A5E8E"), "ink": Color("#FFE27A")},
	"totoro": {"title": "MON VOISIN TOTORO", "sub": "", "bg": Color("#1E3A2A"), "ink": Color("#F4E6B0")},
}
const IDS: Array[String] = ["film", "grinch", "maison", "ratatouille", "reine", "lion", "nemo", "up", "totoro"]


static func has(id: String) -> bool:
	return FILMS.has(id)


## Paints film `id` at time `t`, `on_for` seconds after it started.
static func draw(id: String, c: CanvasItem, t: float, on_for: float) -> void:
	var info: Dictionary = FILMS[id]
	if on_for < CARD or on_for > LENGTH - CARD:
		_card(c, info, t, on_for)
		return
	var story := on_for - CARD
	var span := LENGTH - 2.0 * CARD
	var s := clampi(int(story / (span / 4.0)), 0, 3)
	var local := story - s * span / 4.0
	var u := local / (span / 4.0)
	match id:
		"film": _film(c, t, s, u, local)
		"grinch": _grinch(c, t, s, u, local)
		"maison": _maison(c, t, s, u, local)
		"ratatouille": _ratatouille(c, t, s, u, local)
		"reine": _reine(c, t, s, u, local)
		"lion": _lion(c, t, s, u, local)
		"nemo": _nemo(c, t, s, u, local)
		"up": _up(c, t, s, u, local)
		"totoro": _totoro(c, t, s, u, local)
	# The scenes melt through black.
	var edge := minf(local, span / 4.0 - local)
	if edge < 0.8:
		c.draw_rect(Rect2(Vector2.ZERO, SIZE), Color(0, 0, 0, 1.0 - edge / 0.8))
	_finish(c, t)


# ── Cards, letterbox, vignette ────────────────────────────────

static func _card(c: CanvasItem, info: Dictionary, t: float, on_for: float) -> void:
	var first := on_for < CARD
	var k := on_for if first else LENGTH - on_for
	var fade := clampf(minf(k, CARD - k) * 1.2, 0.0, 1.0)
	var bg: Color = info.bg
	_grad(c, Rect2(Vector2.ZERO, SIZE), bg.lightened(0.12), bg.darkened(0.35))
	var ink: Color = info.ink
	_glow(c, Vector2(98, 54), 70.0, Color(ink, 0.10 * fade))
	for i in 22:
		var p := Vector2(fmod(_r(i) * 311.0, SIZE.x), fmod(_r(i + 40) * 211.0, SIZE.y))
		var tw := 0.5 + 0.5 * sin(t * 2.4 + i * 1.7)
		c.draw_circle(p, 0.5 + tw * 0.8, Color(1, 1, 0.9, (0.25 + tw * 0.5) * fade))
	if first:
		var sub := str(info.sub)
		TvShows._text(c, str(info.title), Vector2(0, 50 if sub == "" else 46), 17, Color(ink, fade), SIZE.x, HORIZONTAL_ALIGNMENT_CENTER)
		if sub != "":
			TvShows._text(c, sub, Vector2(0, 68), 12, Color(1, 1, 1, fade), SIZE.x, HORIZONTAL_ALIGNMENT_CENTER)
		c.draw_line(Vector2(58, 77), Vector2(138, 77), Color(ink, 0.6 * fade), 0.8)
	else:
		TvShows._text(c, "FIN", Vector2(0, 62), 30, Color(ink, fade), SIZE.x, HORIZONTAL_ALIGNMENT_CENTER)
	_finish(c, t)


static func _finish(c: CanvasItem, t: float) -> void:
	c.draw_rect(Rect2(0, 0, SIZE.x, BAR), Color.BLACK)
	c.draw_rect(Rect2(0, SIZE.y - BAR, SIZE.x, BAR), Color.BLACK)
	# The vignette: four soft bands darkening the edges.
	var dark := Color(0, 0, 0, 0.34)
	var none := Color(0, 0, 0, 0)
	c.draw_polygon(PackedVector2Array([Vector2(0, BAR), Vector2(26, BAR), Vector2(26, SIZE.y - BAR), Vector2(0, SIZE.y - BAR)]), PackedColorArray([dark, none, none, dark]))
	c.draw_polygon(PackedVector2Array([Vector2(SIZE.x - 26, BAR), Vector2(SIZE.x, BAR), Vector2(SIZE.x, SIZE.y - BAR), Vector2(SIZE.x - 26, SIZE.y - BAR)]), PackedColorArray([none, dark, dark, none]))
	c.draw_polygon(PackedVector2Array([Vector2(0, BAR), Vector2(SIZE.x, BAR), Vector2(SIZE.x, BAR + 16), Vector2(0, BAR + 16)]), PackedColorArray([dark, dark, none, none]))
	c.draw_polygon(PackedVector2Array([Vector2(0, SIZE.y - BAR - 16), Vector2(SIZE.x, SIZE.y - BAR - 16), Vector2(SIZE.x, SIZE.y - BAR), Vector2(0, SIZE.y - BAR)]), PackedColorArray([none, none, dark, dark]))
	# A breath of grain, different every frame.
	var seed_i := int(t * 24.0)
	for i in 14:
		c.draw_rect(Rect2(fmod(_r(i + seed_i * 7) * 977.0, SIZE.x), fmod(_r(i + seed_i * 13 + 5) * 631.0, SIZE.y), 1.2, 0.8), Color(1, 1, 1, 0.07))


# ── Shared drawing helpers ─────────────────────────────────────

static func _r(i: int) -> float:
	return fposmod(sin(float(i) * 12.9898 + 4.1414) * 43758.5453, 1.0)


static func _grad(c: CanvasItem, r: Rect2, top: Color, bottom: Color) -> void:
	c.draw_polygon(PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]), PackedColorArray([top, top, bottom, bottom]))


## A sky in three bands (top, middle, horizon) down to `horizon`.
static func _sky(c: CanvasItem, top: Color, mid: Color, low: Color, horizon := 78.0) -> void:
	c.draw_rect(Rect2(0, horizon - 1.0, SIZE.x, SIZE.y - horizon + 1.0), low)
	_grad(c, Rect2(0, 0, SIZE.x, horizon * 0.55), top, mid)
	_grad(c, Rect2(0, horizon * 0.55 - 0.3, SIZE.x, horizon * 0.45 + 0.3), mid, low)


static func _glow(c: CanvasItem, p: Vector2, r: float, col: Color) -> void:
	for i in 6:
		var k := float(i + 1) / 6.0
		c.draw_circle(p, r * (1.0 - k * 0.8), Color(col, col.a * 0.55))


## Rolling hills: a sine ridge at `y`, `amp` high, down to the bottom edge.
static func _hills(c: CanvasItem, y: float, amp: float, freq: float, phase: float, col: Color, col2: Color = Color(0, 0, 0, 0)) -> void:
	var pts := PackedVector2Array()
	var bottom := col2 if col2.a > 0.0 else col.darkened(0.2)
	for i in 29:
		var x := SIZE.x * i / 28.0
		pts.append(Vector2(x, y + sin(x * freq + phase) * amp + sin(x * freq * 2.3 + phase * 1.7) * amp * 0.35))
	# Drawn as vertical strips so the ridge may be any shape.
	for i in 28:
		c.draw_polygon(PackedVector2Array([pts[i], pts[i + 1], Vector2(pts[i + 1].x, SIZE.y), Vector2(pts[i].x, SIZE.y)]),
			PackedColorArray([col, col, bottom, bottom]))


static func _stars(c: CanvasItem, t: float, n: int, top: float, fade := 1.0) -> void:
	for i in n:
		var p := Vector2(fmod(_r(i) * 400.0, SIZE.x), fmod(_r(i + 99) * 200.0, top) + BAR)
		var tw := 0.5 + 0.5 * sin(t * (1.5 + _r(i + 7) * 2.5) + i)
		c.draw_circle(p, 0.45 + _r(i + 3) * 0.5 + tw * 0.3, Color(1, 1, 0.88, (0.35 + tw * 0.6) * fade))


static func _snow(c: CanvasItem, t: float, n: int, wind := 5.0) -> void:
	for i in n:
		var x := fposmod(_r(i) * SIZE.x * 3.0 + sin(t * 0.8 + i) * 7.0 + t * wind * (0.4 + _r(i + 5)), SIZE.x)
		var y := fposmod(_r(i + 30) * SIZE.y * 3.0 + t * (9.0 + _r(i + 9) * 14.0), SIZE.y)
		var r := 0.5 + _r(i + 17) * 1.0
		c.draw_circle(Vector2(x, y), r * 1.9, Color(1, 1, 1, 0.12))
		c.draw_circle(Vector2(x, y), r, Color(1, 1, 1, 0.9))


static func _pine(c: CanvasItem, p: Vector2, s: float, col: Color, snowy := true) -> void:
	c.draw_rect(Rect2(p + Vector2(-1, -2) * s, Vector2(2, 4) * s), Color("#3A2A22"))
	for i in 3:
		var w := (9.0 - i * 2.2) * s
		var y := p.y - (2.0 + i * 5.0) * s
		c.draw_colored_polygon(PackedVector2Array([Vector2(p.x - w, y), Vector2(p.x + w, y), Vector2(p.x, y - 8.5 * s)]), col.lightened(i * 0.04))
		c.draw_colored_polygon(PackedVector2Array([Vector2(p.x - w * 0.5, y - 3.6 * s), Vector2(p.x + w * 0.5, y - 3.6 * s), Vector2(p.x, y - 8.5 * s)]), Color(0.93, 0.97, 1.0) if snowy else col.lightened(0.15))
	# The light on the left side.
	c.draw_line(Vector2(p.x - 1.0 * s, p.y - 17.0 * s), Vector2(p.x - 6.0 * s, p.y - 3.0 * s), Color(1, 1, 1, 0.12), 1.0)


static func _snowman(c: CanvasItem, p: Vector2, s: float, t: float, wave := true) -> void:
	c.draw_circle(p + Vector2(1.2, 0.8) * s, 8.5 * s, Color(0, 0, 0, 0.18))
	c.draw_circle(p, 8.0 * s, Color("#EAF1FA"))
	c.draw_circle(p + Vector2(-2.5, -2.5) * s, 5.0 * s, Color(1, 1, 1, 0.8))
	c.draw_circle(p + Vector2(0, -10.5) * s, 5.6 * s, Color("#EEF4FC"))
	c.draw_circle(p + Vector2(-1.6, -12.2) * s, 3.0 * s, Color(1, 1, 1, 0.8))
	c.draw_circle(p + Vector2(-2.0, -11.5) * s, 0.8 * s, Color("#1A1A24"))
	c.draw_circle(p + Vector2(2.0, -11.5) * s, 0.8 * s, Color("#1A1A24"))
	c.draw_colored_polygon(PackedVector2Array([p + Vector2(0, -10.2) * s, p + Vector2(0, -8.6) * s, p + Vector2(5.5, -9.2) * s]), Color("#FF8A3D"))
	for i in 3:
		c.draw_circle(p + Vector2(0, -3.0 + i * 3.0) * s, 0.8 * s, Color("#2A2A36"))
	c.draw_rect(Rect2(p + Vector2(-4.2, -17.5) * s, Vector2(8.4, 5.0) * s), Color("#2A2A3A"))
	c.draw_rect(Rect2(p + Vector2(-6.2, -13.2) * s, Vector2(12.4, 1.4) * s), Color("#2A2A3A"))
	c.draw_line(p + Vector2(-7, -3) * s, p + Vector2(-13, -8) * s, Color("#6E4424"), 1.2 * s)
	var wv := sin(t * 6.0) * 3.0 if wave else 0.0
	c.draw_line(p + Vector2(7, -3) * s, p + Vector2(13, -9 + wv) * s, Color("#6E4424"), 1.2 * s)
	c.draw_line(p + Vector2(-5, -6.5) * s, p + Vector2(5, -6.5) * s, Color("#D8352E"), 1.8 * s)


## The little fox on his red sled at `at` (the sled's middle), `k` its size, `tilt` radians, scarf flapping.
static func _fox(c: CanvasItem, at: Vector2, k: float, t: float, tilt := 0.0, on_sled := true) -> void:
	c.draw_set_transform(at, tilt, Vector2(k, k))
	var orange := Color("#E8762C")
	if on_sled:
		c.draw_rect(Rect2(-15, 2.5, 30, 3.4), Color("#D8352E"))
		c.draw_rect(Rect2(-15, 2.5, 30, 1.0), Color("#F0605A"))
		c.draw_line(Vector2(-17, 8.4), Vector2(15, 8.4), Color("#5A3A22"), 1.2)
		c.draw_line(Vector2(-12, 6), Vector2(-12, 8.4), Color("#5A3A22"), 1.0)
		c.draw_line(Vector2(10, 6), Vector2(10, 8.4), Color("#5A3A22"), 1.0)
		c.draw_arc(Vector2(15, 5.6), 2.8, -PI / 2.0, PI / 2.0, 6, Color("#5A3A22"), 1.2)
	# The tail curls up behind him, white-tipped.
	c.draw_circle(Vector2(-12, -2), 5.0, orange)
	c.draw_circle(Vector2(-12, -2), 5.0 * 0.6, orange.lightened(0.18))
	c.draw_circle(Vector2(-16, -6), 2.9, Color("#FFF8EE"))
	# Body, belly, legs.
	c.draw_circle(Vector2(-1, -2.5), 7.4, orange)
	c.draw_circle(Vector2(-3, -4.5), 4.0, orange.lightened(0.18))
	c.draw_circle(Vector2(2.0, 0.0), 4.2, Color("#FFF1E0"))
	c.draw_line(Vector2(3, 1), Vector2(7, 3.4), Color("#7A3A18"), 1.8)
	# The head, ears, white muzzle, nose, eye.
	var head := Vector2(7, -11)
	c.draw_circle(head, 5.8, orange)
	c.draw_circle(head + Vector2(-1.5, -1.6), 3.4, orange.lightened(0.14))
	for e in [Vector2(-3.4, -3.8), Vector2(2.8, -4.6)]:
		c.draw_colored_polygon(PackedVector2Array([head + e + Vector2(-2.4, 1.4), head + e + Vector2(2.4, 1.4), head + e + Vector2(0, -5.6)]), orange)
		c.draw_colored_polygon(PackedVector2Array([head + e + Vector2(-1.2, 1.2), head + e + Vector2(1.2, 1.2), head + e + Vector2(0, -3.0)]), Color("#3A1A10"))
	c.draw_colored_polygon(PackedVector2Array([head + Vector2(1.6, -0.2), head + Vector2(9.2, 2.0), head + Vector2(1.6, 4.6)]), Color("#FFF1E0"))
	c.draw_circle(head + Vector2(9.2, 2.0), 1.1, Color("#1A1010"))
	c.draw_circle(head + Vector2(2.0, -1.6), 1.0, Color("#1A1010"))
	c.draw_circle(head + Vector2(1.7, -1.9), 0.35, Color.WHITE)
	# The blue scarf, its end flying.
	c.draw_line(head + Vector2(-4, 5), head + Vector2(3, 5.4), Color("#4FA3E0"), 2.4)
	c.draw_line(head + Vector2(-4, 5), head + Vector2(-13, 3 + sin(t * 13.0) * 2.2), Color("#4FA3E0"), 1.9)
	c.draw_line(head + Vector2(-4, 4.4), head + Vector2(-12, 2.4 + sin(t * 13.0) * 2.2), Color("#8CC8F0"), 0.7)
	c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## A little house: warm walls, a snowy roof, glowing windows. `lit` 0..1.
static func _cottage(c: CanvasItem, at: Vector2, w: float, wall: Color, lit: float, t: float, bulbs := true) -> void:
	var h := w * 0.72
	c.draw_rect(Rect2(at.x - w / 2.0, at.y - h, w, h), wall.darkened(0.12))
	c.draw_rect(Rect2(at.x - w / 2.0, at.y - h, w * 0.4, h), wall)
	c.draw_colored_polygon(PackedVector2Array([at + Vector2(-w * 0.62, -h), at + Vector2(w * 0.62, -h), at + Vector2(0, -h - w * 0.46)]), Color("#3A2A3E"))
	c.draw_colored_polygon(PackedVector2Array([at + Vector2(-w * 0.22, -h - w * 0.3), at + Vector2(w * 0.22, -h - w * 0.3), at + Vector2(0, -h - w * 0.46)]), Color(0.95, 0.97, 1.0))
	var glow := Color("#FFD27A").lerp(Color("#2A2F4A"), 1.0 - lit)
	for dx in [-0.3, 0.12]:
		c.draw_rect(Rect2(at.x + w * dx, at.y - h * 0.74, w * 0.2, w * 0.22), glow)
		c.draw_line(Vector2(at.x + w * (dx + 0.1), at.y - h * 0.74), Vector2(at.x + w * (dx + 0.1), at.y - h * 0.74 + w * 0.22), wall.darkened(0.5), 0.5)
		if lit > 0.5:
			_glow(c, Vector2(at.x + w * (dx + 0.1), at.y - h * 0.6), w * 0.55, Color(1.0, 0.8, 0.4, 0.12 * lit))
	c.draw_rect(Rect2(at.x - w * 0.07, at.y - h * 0.42, w * 0.14, h * 0.42), Color("#5A3A28"))
	if bulbs:
		var cols := [Color("#FF4D4D"), Color("#FFD23F"), Color("#4DD26B"), Color("#4FA3E0")]
		for i in 6:
			var on := lit > 0.5 and int(t * 3.0 + i) % 3 != 0
			c.draw_circle(at + Vector2(-w * 0.5 + i * w * 0.2, -h + 1.0), 1.0, cols[i % 4] if on else Color("#444455"))


static func _cloud(c: CanvasItem, p: Vector2, s: float, col: Color) -> void:
	for d: Vector3 in [Vector3(-7, 1, 5), Vector3(0, -2, 7), Vector3(7, 1, 5.5), Vector3(-2, 2.5, 6), Vector3(3, 2, 5)]:
		c.draw_circle(p + Vector2(d.x, d.y) * s, d.z * s, col)
	c.draw_circle(p + Vector2(-2, -3) * s, 4.0 * s, col.lightened(0.25))


static func _bubble(c: CanvasItem, p: Vector2, r: float) -> void:
	c.draw_circle(p, r, Color(0.8, 0.95, 1.0, 0.12))
	c.draw_arc(p, r, 0, TAU, 12, Color(1, 1, 1, 0.55), 0.5)
	c.draw_circle(p + Vector2(-r * 0.35, -r * 0.35), r * 0.25, Color(1, 1, 1, 0.8))


# ══════════════════════════════════════════════════════════════
#  Le petit renard des neiges
# ══════════════════════════════════════════════════════════════

static func _film(c: CanvasItem, t: float, s: int, u: float, ls: float) -> void:
	match s:
		0:
			# A winter night: the moon over soft hills, the fox arriving at the top of the slope with his sled.
			_sky(c, Color("#0B1236"), Color("#1E2F6A"), Color("#4E6AA8"), 70.0)
			_stars(c, t, 40, 50.0)
			_glow(c, Vector2(150, 28), 30.0, Color(0.9, 0.95, 1.0, 0.16))
			c.draw_circle(Vector2(150, 28), 11.0, Color("#FFF6D6"))
			c.draw_circle(Vector2(146, 25), 2.6, Color("#EEE2B8"))
			c.draw_circle(Vector2(153, 32), 1.7, Color("#EEE2B8"))
			_hills(c, 66.0, 5.0, 0.04, 1.0, Color("#B6C6E6"), Color("#E6EEFA"))
			_hills(c, 78.0, 6.0, 0.05, 3.0, Color("#DCE6F6"), Color("#F4F8FF"))
			for p in [Vector2(20, 72), Vector2(34, 76), Vector2(170, 70), Vector2(184, 74), Vector2(160, 76)]:
				_pine(c, p, 0.9, Color("#244A3C"))
			var x := lerpf(-20.0, 62.0, ease(u, 0.4))
			_fox(c, Vector2(x, 82.0 - x * 0.05), 1.0, t, 0.0, true)
			_snow(c, t, 26)
		1:
			# The slide: down the long slope, snow flying behind the sled, trees whizzing by.
			_sky(c, Color("#0F1A48"), Color("#2A3F86"), Color("#7C94CC"), 60.0)
			_stars(c, t, 26, 36.0)
			c.draw_circle(Vector2(40, 22), 9.0, Color("#FFF6D6"))
			_hills(c, 52.0, 6.0, 0.05, 0.5 + u * 1.5, Color("#9FB2DA"), Color("#D8E4F6"))
			var sc := u * 220.0
			for i in 5:
				var tx := fposmod(220.0 - i * 60.0 - sc * 1.6, 260.0) - 30.0
				_pine(c, Vector2(tx, 62.0 + i * 3.0), 0.7 + i * 0.12, Color("#1F4034"))
			# The slope itself: a pale ramp from top left to bottom right.
			c.draw_polygon(PackedVector2Array([Vector2(0, 56), Vector2(SIZE.x, 86), Vector2(SIZE.x, SIZE.y), Vector2(0, SIZE.y)]), PackedColorArray([Color("#E6EEFA"), Color("#F8FBFF"), Color("#C8D6EE"), Color("#C8D6EE")]))
			var fx := lerpf(20.0, 170.0, ease(u, 0.2))
			var fy := lerpf(60.0, 80.0, (fx - 20.0) / 150.0) + sin(ls * 5.0) * 1.2 - 4.0
			for i in 6:
				c.draw_circle(Vector2(fx - 14.0 - i * 5.0, fy + 9.0 - i * 0.5 + sin(ls * 9.0 + i) * 1.2), 2.8 - i * 0.35, Color(1, 1, 1, 0.75 - i * 0.1))
			_fox(c, Vector2(fx, fy), 1.15, t, 0.19, true)
			_snow(c, t, 30, 24.0)
		2:
			# A snowman by the path waves; the fox stops and gives him his scarf (it flaps off him).
			_sky(c, Color("#10204E"), Color("#2C4486"), Color("#8AA2D8"), 66.0)
			_stars(c, t, 30, 40.0)
			_glow(c, Vector2(100, 40), 46.0, Color(1.0, 0.9, 0.6, 0.06))
			_hills(c, 66.0, 4.0, 0.06, 2.0, Color("#CBD8EE"), Color("#EDF3FC"))
			_hills(c, 82.0, 3.0, 0.07, 0.0, Color("#EEF4FC"), Color("#FFFFFF"))
			_pine(c, Vector2(24, 76), 1.15, Color("#22463A"))
			_pine(c, Vector2(172, 74), 1.0, Color("#22463A"))
			var fx := lerpf(-10.0, 68.0, ease(minf(u * 2.2, 1.0), 0.5))
			_snowman(c, Vector2(128, 86), 1.25, t)
			if u > 0.55:
				# The scarf passes to the snowman: a little arc of blue and a few hearts.
				var k := clampf((u - 0.55) * 3.0, 0.0, 1.0)
				c.draw_line(Vector2(128 - 5.5, 78.0), Vector2(128 + 5.5, 78.0), Color(0.31, 0.64, 0.88, k), 2.2)
				for i in 3:
					var hp := Vector2(118.0 + i * 10.0, 62.0 - fposmod(ls * 6.0 + i * 5.0, 14.0))
					c.draw_circle(hp + Vector2(-1, 0), 1.3, Color(1, 0.4, 0.55, k))
					c.draw_circle(hp + Vector2(1, 0), 1.3, Color(1, 0.4, 0.55, k))
					c.draw_colored_polygon(PackedVector2Array([hp + Vector2(-2.3, 0.5), hp + Vector2(2.3, 0.5), hp + Vector2(0, 3.2)]), Color(1, 0.4, 0.55, k))
			_fox(c, Vector2(fx, 88.0), 1.15, t, 0.0, false)
			_snow(c, t, 22, 3.0)
		_:
			# Home: a snug burrow under the old pine, its window lit, the northern lights and a shooting star.
			_sky(c, Color("#08102E"), Color("#1A2C66"), Color("#3E5C9E"), 70.0)
			for i in 3:
				var band := PackedVector2Array()
				var band2 := PackedVector2Array()
				for k in 21:
					var x := k * SIZE.x / 20.0
					var y := 22.0 + i * 8.0 + sin(x * 0.045 + t * 0.7 + i * 1.3) * 6.0
					band.append(Vector2(x, y))
					band2.append(Vector2(x, y + 16.0))
				for k in 20:
					c.draw_polygon(PackedVector2Array([band[k], band[k + 1], band2[k + 1], band2[k]]), PackedColorArray([Color(0.3, 1.0, 0.7, 0.28), Color(0.3, 1.0, 0.7, 0.28), Color(0.3, 0.7, 1.0, 0.0), Color(0.3, 0.7, 1.0, 0.0)]))
			_stars(c, t, 44, 48.0)
			var sp := fposmod(ls * 0.28, 1.0)
			if sp < 0.4:
				var q := Vector2(30 + sp * 280.0, 14 + sp * 90.0)
				c.draw_line(q, q - Vector2(14, 8), Color(1, 1, 0.85, 0.7), 1.0)
				c.draw_circle(q, 1.2, Color.WHITE)
			_hills(c, 72.0, 4.0, 0.05, 1.0, Color("#B8C8E6"), Color("#EDF3FC"))
			_pine(c, Vector2(66, 82), 2.4, Color("#1E4034"))
			# The burrow's door and window, warm light spilling on the snow.
			c.draw_circle(Vector2(104, 86), 9.5, Color("#7A5238"))
			c.draw_circle(Vector2(104, 87), 7.0, Color("#FFC25C"))
			_glow(c, Vector2(104, 90), 26.0, Color(1.0, 0.75, 0.35, 0.22))
			c.draw_polygon(PackedVector2Array([Vector2(98, 94), Vector2(110, 94), Vector2(124, 106), Vector2(86, 106)]), PackedColorArray([Color(1, 0.8, 0.4, 0.5), Color(1, 0.8, 0.4, 0.5), Color(1, 0.8, 0.4, 0.0), Color(1, 0.8, 0.4, 0.0)]))
			_fox(c, Vector2(104, 93), 0.9, t, 0.0, false)
			_snow(c, t, 22, 2.0)


# ══════════════════════════════════════════════════════════════
#  Le Grinch
# ══════════════════════════════════════════════════════════════

static func _village(c: CanvasItem, t: float, dark_k: float, from_i: float) -> void:
	var walls := [Color("#E8A0B4"), Color("#A0C8E8"), Color("#F0D080"), Color("#B8E0A0"), Color("#D8A0E0")]
	for i in 5:
		var is_dark := dark_k > 0.0 and float(i) * 1.0 < from_i
		var lit := 1.0 - (dark_k if is_dark else 0.0)
		_cottage(c, Vector2(92 + i * 22, 94 + (i % 2) * 2), 17.0 + (i % 3) * 2.0, walls[i], lit, t)


static func _grinch(c: CanvasItem, t: float, s: int, u: float, ls: float) -> void:
	match s:
		0:
			# Whoville asleep under its snowy mountain, a thin path of light on the snow.
			_sky(c, Color("#0C1A3C"), Color("#1E3A6E"), Color("#5A7AAE"), 72.0)
			_stars(c, t, 30, 42.0)
			c.draw_circle(Vector2(170, 24), 8.0, Color("#FFF6D6"))
			_glow(c, Vector2(170, 24), 22.0, Color(1, 1, 0.9, 0.12))
			c.draw_colored_polygon(PackedVector2Array([Vector2(-14, 92), Vector2(38, 12), Vector2(100, 92)]), Color("#8DA4CC"))
			c.draw_colored_polygon(PackedVector2Array([Vector2(38, 12), Vector2(100, 92), Vector2(56, 92)]), Color("#6E86B0"))
			c.draw_colored_polygon(PackedVector2Array([Vector2(24, 34), Vector2(38, 12), Vector2(52, 36), Vector2(44, 32), Vector2(38, 38), Vector2(32, 31)]), Color.WHITE)
			c.draw_circle(Vector2(41, 46), 4.4, Color("#12121E"))
			_glow(c, Vector2(41, 46), 12.0, Color(0.5, 1.0, 0.5, 0.05 + 0.04 * sin(t * 2.0)))
			c.draw_rect(Rect2(0, 90, SIZE.x, 18), Color("#EEF4FC"))
			_village(c, t, 0.0, 0.0)
			for i in 3:
				_pine(c, Vector2(8 + i * 18, 94), 0.8, Color("#1E4A3A"))
			_snow(c, t, 24, 3.0)
		1:
			# Down the mountain, a sleigh with a big sack and a little dog with antlers on its head.
			_sky(c, Color("#0C1A3C"), Color("#1E3A6E"), Color("#5A7AAE"), 72.0)
			_stars(c, t, 26, 42.0)
			c.draw_colored_polygon(PackedVector2Array([Vector2(-14, 92), Vector2(38, 12), Vector2(100, 92)]), Color("#8DA4CC"))
			c.draw_rect(Rect2(0, 90, SIZE.x, 18), Color("#EEF4FC"))
			_village(c, t, 0.0, 0.0)
			var q := ease(u, 0.3)
			var at := Vector2(lerpf(46, 200, q), lerpf(30, 84, minf(q * 1.6, 1.0)) + sin(ls * 4.0) * 0.6)
			c.draw_set_transform(at, 0.45 * (1.0 - minf(q * 1.6, 1.0)), Vector2.ONE)
			c.draw_rect(Rect2(-11, -3, 22, 5), Color("#B5302E"))
			c.draw_line(Vector2(-12, 3), Vector2(12, 3), Color("#5A3A22"), 1.2)
			c.draw_circle(Vector2(-2, -9), 7.0, Color("#D9C9A8"))
			c.draw_circle(Vector2(-4, -11), 3.2, Color("#EBDDBE"))
			c.draw_line(Vector2(-2, -16), Vector2(-1, -19), Color("#8A6A3A"), 1.4)
			c.draw_circle(Vector2(12, -5), 3.0, Color("#8A6A4A"))
			c.draw_line(Vector2(12, -8), Vector2(10, -11), Color("#5A3A22"), 0.8)
			c.draw_line(Vector2(12, -8), Vector2(14, -11), Color("#5A3A22"), 0.8)
			c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			for i in 5:
				c.draw_circle(at + Vector2(-14.0 - i * 4.0, 4.0 - i * 0.7), 2.4 - i * 0.35, Color(1, 1, 1, 0.65 - i * 0.1))
			_snow(c, t, 24, 12.0)
		2:
			# Roof to roof the lights go out one by one; the sleigh slips along the rooftops.
			_sky(c, Color("#060C24"), Color("#12214A"), Color("#2E4478"), 72.0)
			_stars(c, t, 36, 42.0)
			c.draw_rect(Rect2(0, 90, SIZE.x, 18), Color("#E6EEFA"))
			var off := clampf(u * 1.1, 0.0, 1.0) * 5.0
			_village(c, t, 1.0, off)
			var x := lerpf(-10.0, 200.0, u)
			var y := 66.0 + sin(u * TAU * 2.0) * 2.0
			c.draw_rect(Rect2(x - 11, y - 3, 22, 5), Color("#B5302E"))
			c.draw_line(Vector2(x - 12, y + 3), Vector2(x + 12, y + 3), Color("#5A3A22"), 1.2)
			c.draw_circle(Vector2(x - 2, y - 9), 7.0, Color("#D9C9A8"))
			c.draw_line(Vector2(x - 2, y - 16), Vector2(x - 1, y - 19), Color("#8A6A3A"), 1.4)
			_snow(c, t, 26, 6.0)
		_:
			# Morning: the sun rises, the bells ring, every window comes back on and a red heart grows over the village.
			var k := clampf(u * 1.6, 0.0, 1.0)
			_sky(c, Color("#3A5E9E").lerp(Color("#6EB4F0"), k), Color("#F0A070").lerp(Color("#B8DCF8"), k), Color("#FFD890").lerp(Color("#FFF2D0"), k), 72.0)
			_glow(c, Vector2(98, 78 - k * 20.0), 70.0, Color(1.0, 0.85, 0.5, 0.2))
			c.draw_circle(Vector2(98, 78 - k * 20.0), 11.0, Color("#FFF2C0"))
			c.draw_colored_polygon(PackedVector2Array([Vector2(-14, 92), Vector2(38, 18), Vector2(100, 92)]), Color("#B8CCEE"))
			c.draw_colored_polygon(PackedVector2Array([Vector2(26, 38), Vector2(38, 18), Vector2(50, 38)]), Color.WHITE)
			c.draw_rect(Rect2(0, 90, SIZE.x, 18), Color("#F4F8FF"))
			_village(c, t, 0.0, 0.0)
			var grow := clampf((u - 0.15) / 0.7, 0.0, 1.0)
			var beat := 1.0 + 0.06 * sin(t * 8.0)
			var r := lerpf(2.0, 17.0, ease(grow, 0.5)) * beat
			var hc := Vector2(120, 44)
			_glow(c, hc, r * 3.0, Color(1.0, 0.3, 0.35, 0.18 * grow))
			c.draw_circle(hc + Vector2(-r * 0.5, 0), r * 0.58, Color("#E0303A"))
			c.draw_circle(hc + Vector2(r * 0.5, 0), r * 0.58, Color("#E0303A"))
			c.draw_colored_polygon(PackedVector2Array([hc + Vector2(-r * 1.06, r * 0.18), hc + Vector2(r * 1.06, r * 0.18), hc + Vector2(0, r * 1.25)]), Color("#E0303A"))
			c.draw_circle(hc + Vector2(-r * 0.6, -r * 0.2), r * 0.2, Color(1, 1, 1, 0.5))
			for i in 8:
				var a := TAU * i / 8.0 + t
				c.draw_circle(hc + Vector2(cos(a), sin(a)) * (r * 1.7 + 4.0), 1.0, Color("#FFD23F"))
			_snow(c, t, 14, 2.0)


# ══════════════════════════════════════════════════════════════
#  Maman, j'ai raté l'avion
# ══════════════════════════════════════════════════════════════

static func _big_house(c: CanvasItem, t: float, lit := true) -> void:
	var house := Rect2(46, 40, 104, 56)
	c.draw_rect(house, Color("#9A3A2E"))
	c.draw_rect(Rect2(house.position, Vector2(house.size.x * 0.35, house.size.y)), Color("#B04A3A"))
	for row in 7:
		c.draw_line(Vector2(house.position.x, house.position.y + 5 + row * 8), Vector2(house.end.x, house.position.y + 5 + row * 8), Color("#7E2E24"), 0.5)
	c.draw_colored_polygon(PackedVector2Array([Vector2(40, 40), Vector2(156, 40), Vector2(98, 16)]), Color("#2E2A3A"))
	c.draw_colored_polygon(PackedVector2Array([Vector2(40, 40), Vector2(156, 40), Vector2(150, 36), Vector2(98, 14), Vector2(46, 36)]), Color(0.94, 0.96, 1.0, 0.85))
	for wx in [58.0, 82.0, 114.0, 138.0]:
		for wy in [47.0, 68.0]:
			if wy == 68.0 and (wx == 82.0 or wx == 114.0):
				continue
			c.draw_rect(Rect2(wx - 6, wy, 12, 13), Color("#FFD27A") if lit else Color("#2A2F4A"))
			c.draw_line(Vector2(wx, wy), Vector2(wx, wy + 13), Color("#6E2A20"), 0.7)
			c.draw_line(Vector2(wx - 6, wy + 6.5), Vector2(wx + 6, wy + 6.5), Color("#6E2A20"), 0.7)
			if lit:
				_glow(c, Vector2(wx, wy + 6), 14.0, Color(1.0, 0.8, 0.4, 0.12))
	c.draw_rect(Rect2(90, 72, 16, 24), Color("#F4F1EA"))
	c.draw_circle(Vector2(98, 82), 4.6, Color("#2E8A44"))
	c.draw_circle(Vector2(98, 82), 3.0, Color("#F4F1EA"))
	c.draw_circle(Vector2(98, 78.4), 1.0, Color("#E0303A"))
	var cols := [Color("#FF4D4D"), Color("#FFD23F"), Color("#4DD26B"), Color("#4FA3E0")]
	for i in 18:
		var p := Vector2(40, 40).lerp(Vector2(98, 16), i / 9.0) if i < 9 else Vector2(98, 16).lerp(Vector2(156, 40), (i - 9) / 9.0)
		c.draw_circle(p, 1.2, cols[(i + int(t * 3.0)) % 4])
		c.draw_circle(p, 2.6, Color(cols[(i + int(t * 3.0)) % 4], 0.18))


static func _maison(c: CanvasItem, t: float, s: int, u: float, ls: float) -> void:
	match s:
		0:
			# A snowy suburb at dusk: the big brick house decked in lights, a plane crossing the sky without one of them.
			_sky(c, Color("#14204E"), Color("#3A3A78"), Color("#E09A6E"), 76.0)
			_stars(c, t, 20, 30.0, 0.7)
			c.draw_rect(Rect2(0, 94, SIZE.x, 14), Color("#EEF4FC"))
			_big_house(c, t)
			_pine(c, Vector2(20, 94), 1.5, Color("#1E4034"))
			_pine(c, Vector2(176, 94), 1.3, Color("#1E4034"))
			var px := lerpf(-24.0, 224.0, u)
			var pa := Vector2(px, 20.0 - u * 6.0)
			c.draw_colored_polygon(PackedVector2Array([pa + Vector2(-13, 0), pa + Vector2(13, -1.2), pa + Vector2(16, 1), pa + Vector2(-13, 2.2)]), Color("#E4E8F0"))
			c.draw_colored_polygon(PackedVector2Array([pa + Vector2(-2, 0.5), pa + Vector2(5, 0.5), pa + Vector2(-5, 8)]), Color("#B8BEC9"))
			c.draw_colored_polygon(PackedVector2Array([pa + Vector2(-13, 0), pa + Vector2(-9, 0), pa + Vector2(-14, -6)]), Color("#B8BEC9"))
			c.draw_line(pa + Vector2(-14, 1.4), pa + Vector2(-60, 1.4), Color(1, 1, 1, 0.22), 1.6)
			if int(t * 3.0) % 2 == 0:
				c.draw_circle(pa + Vector2(14, 0.4), 1.0, Color("#FF4D4D"))
			_snow(c, t, 18, 3.0)
		1:
			# Inside, the boy at the window of his room: curtains, a lamp, the snow outside.
			_grad(c, Rect2(0, 0, SIZE.x, SIZE.y), Color("#7A3A2E"), Color("#4A1E1E"))
			for i in 8:
				c.draw_line(Vector2(i * 26.0, 0), Vector2(i * 26.0, SIZE.y), Color(0, 0, 0, 0.07), 6.0)
			c.draw_rect(Rect2(62, 20, 72, 62), Color("#3A2418"))
			_grad(c, Rect2(66, 24, 64, 54), Color("#1A2A5A"), Color("#4A5E9A"))
			_stars(c, t, 10, 20.0)
			_snow(c, t, 14, 2.0)
			c.draw_line(Vector2(98, 24), Vector2(98, 78), Color("#3A2418"), 2.0)
			c.draw_line(Vector2(66, 51), Vector2(130, 51), Color("#3A2418"), 2.0)
			for sx in [0, 1]:
				var cx := 62.0 if sx == 0 else 134.0
				var dir := 1.0 if sx == 0 else -1.0
				c.draw_polygon(PackedVector2Array([Vector2(cx, 18), Vector2(cx + dir * 20.0, 18), Vector2(cx + dir * 14.0, 86), Vector2(cx, 86)]), PackedColorArray([Color("#D8A04A"), Color("#B8802A"), Color("#B8802A"), Color("#D8A04A")]))
			c.draw_rect(Rect2(0, 82, SIZE.x, 26), Color("#4A3020"))
			# The boy from behind, jumping up and down a little, hands on the sill.
			var hop := absf(sin(ls * 3.0)) * 3.0
			c.draw_circle(Vector2(98, 66 - hop), 7.0, Color("#E8B88A"))
			c.draw_circle(Vector2(98, 62 - hop), 7.2, Color("#8A5A2E"))
			c.draw_rect(Rect2(90, 72 - hop, 16, 20), Color("#3A7AC8"))
			c.draw_line(Vector2(92, 74 - hop), Vector2(86, 62 - hop), Color("#E8B88A"), 2.2)
			c.draw_line(Vector2(104, 74 - hop), Vector2(110, 62 - hop), Color("#E8B88A"), 2.2)
			# The lamp.
			c.draw_rect(Rect2(148, 62, 3, 22), Color("#2A1A10"))
			c.draw_colored_polygon(PackedVector2Array([Vector2(140, 62), Vector2(160, 62), Vector2(154, 50), Vector2(146, 50)]), Color("#FFE0A0"))
			_glow(c, Vector2(150, 58), 30.0, Color(1, 0.8, 0.4, 0.2))
		2:
			# The side door at night: the paint can swings down its rope and a burglar's hat flies off. BONG !
			_sky(c, Color("#0A1030"), Color("#1A2850"), Color("#2E3E68"), 70.0)
			_stars(c, t, 16, 28.0, 0.8)
			c.draw_rect(Rect2(0, 92, SIZE.x, 16), Color("#DCE6F4"))
			c.draw_rect(Rect2(20, 30, 156, 64), Color("#8A3428"))
			for row in 8:
				c.draw_line(Vector2(20, 36 + row * 8), Vector2(176, 36 + row * 8), Color("#6E2820"), 0.5)
			c.draw_rect(Rect2(116, 54, 24, 40), Color("#E8E4DC"))
			c.draw_circle(Vector2(134, 74), 1.2, Color("#B89A4A"))
			c.draw_rect(Rect2(40, 46, 28, 22), Color("#FFD27A"))
			_glow(c, Vector2(54, 58), 28.0, Color(1, 0.8, 0.4, 0.14))
			c.draw_line(Vector2(54, 46), Vector2(54, 68), Color("#6E2820"), 0.8)
			var k := fmod(ls, 7.0)
			var pivot := Vector2(176, 8)
			var swing := 0.0
			if k < 1.4:
				swing = lerpf(-1.3, 0.35, ease(k / 1.4, 2.0))
			else:
				swing = 0.35 * cos((k - 1.4) * 3.2) * exp(-(k - 1.4) * 0.7)
			var can := pivot + Vector2(sin(swing), cos(swing)) * 74.0
			c.draw_line(pivot, can, Color("#D8D8D8"), 0.7)
			c.draw_rect(Rect2(can + Vector2(-4, 0), Vector2(8, 9)), Color("#C9CED6"))
			c.draw_rect(Rect2(can + Vector2(-4, 2.5), Vector2(8, 2.8)), Color("#4FA3E0"))
			c.draw_circle(can + Vector2(0, -0.6), 4.0, Color("#E8EDF5"))
			if k > 1.4 and k < 4.4:
				var f := (k - 1.4) / 3.0
				var hat := Vector2(134, 56) + Vector2(f * 38.0, -sin(f * PI) * 30.0)
				c.draw_set_transform(hat, f * 9.0, Vector2.ONE)
				c.draw_rect(Rect2(-5, -2, 10, 3), Color("#2A2A2A"))
				c.draw_rect(Rect2(-3, -6, 6, 4), Color("#2A2A2A"))
				c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
				TvShows._text(c, "BONG !", Vector2(120, 48), 11, Color("#FFD23F", 1.0 - f))
				for i in 6:
					var a := TAU * i / 6.0
					c.draw_line(Vector2(134, 60) + Vector2(cos(a), sin(a)) * 8.0, Vector2(134, 60) + Vector2(cos(a), sin(a)) * (12.0 + f * 6.0), Color(1, 0.9, 0.4, 1.0 - f), 1.0)
			_snow(c, t, 14, 2.0)
		_:
			# The family comes home: headlights in the snow, the door opens warm and a big hug on the doorstep.
			_sky(c, Color("#0E1A44"), Color("#2A3A70"), Color("#6A7EB0"), 76.0)
			_stars(c, t, 20, 30.0)
			c.draw_rect(Rect2(0, 94, SIZE.x, 14), Color("#EEF4FC"))
			_big_house(c, t)
			var cx := lerpf(-30.0, 40.0, ease(minf(u * 2.0, 1.0), 0.4))
			if u < 0.55:
				c.draw_rect(Rect2(cx - 16, 92, 32, 9), Color("#3A5A8A"))
				c.draw_colored_polygon(PackedVector2Array([Vector2(cx - 8, 92), Vector2(cx - 5, 86), Vector2(cx + 7, 86), Vector2(cx + 10, 92)]), Color("#2E4A74"))
				c.draw_polygon(PackedVector2Array([Vector2(cx + 15, 95), Vector2(cx + 60, 88), Vector2(cx + 60, 106), Vector2(cx + 15, 99)]), PackedColorArray([Color(1, 1, 0.8, 0.5), Color(1, 1, 0.8, 0.0), Color(1, 1, 0.8, 0.0), Color(1, 1, 0.8, 0.5)]))
			if u > 0.4:
				var open := clampf((u - 0.4) * 4.0, 0.0, 1.0)
				c.draw_polygon(PackedVector2Array([Vector2(90, 72), Vector2(106, 72), Vector2(106 + 12 * open, 106), Vector2(90 - 12 * open, 106)]), PackedColorArray([Color(1, 0.85, 0.5, 0.55 * open), Color(1, 0.85, 0.5, 0.55 * open), Color(1, 0.85, 0.5, 0.0), Color(1, 0.85, 0.5, 0.0)]))
				var hug := clampf((u - 0.6) * 3.0, 0.0, 1.0)
				c.draw_circle(Vector2(94.0 + hug * 3.0, 84), 3.6, Color("#E8B88A"))
				c.draw_rect(Rect2(90.0 + hug * 3.0, 87, 8, 10), Color("#C8403A"))
				c.draw_circle(Vector2(104.0 - hug * 3.0, 86), 3.0, Color("#E8B88A"))
				c.draw_rect(Rect2(100.5 - hug * 3.0, 88.5, 7, 8), Color("#3A7AC8"))
				if hug > 0.6:
					for i in 3:
						c.draw_circle(Vector2(99.0 + i * 4.0 - 4.0, 68.0 - fposmod(ls * 7.0 + i * 4.0, 12.0)), 1.4, Color(1, 0.45, 0.55, 0.9))
			_snow(c, t, 22, 3.0)


# ══════════════════════════════════════════════════════════════
#  Ratatouille
# ══════════════════════════════════════════════════════════════

static func _paris(c: CanvasItem, t: float, base_x: float, k: float) -> void:
	var base := Vector2(base_x, 92.0)
	var iron := Color("#4A4262")
	c.draw_colored_polygon(PackedVector2Array([base + Vector2(-24, 0) * k, base + Vector2(-4.5, -66) * k, base + Vector2(4.5, -66) * k, base + Vector2(24, 0) * k, base + Vector2(15, 0) * k, base + Vector2(0, -32) * k, base + Vector2(-15, 0) * k]), iron)
	c.draw_line(base + Vector2(0, -66) * k, base + Vector2(0, -82) * k, iron, 1.4 * k)
	c.draw_line(base + Vector2(-13, -32) * k, base + Vector2(13, -32) * k, iron, 2.4 * k)
	c.draw_line(base + Vector2(-7, -50) * k, base + Vector2(7, -50) * k, iron, 1.8 * k)
	for i in 10:
		var tw := 0.5 + 0.5 * sin(t * 6.0 + i * 1.9)
		c.draw_circle(base + Vector2(sin(i * 3.1) * (3.0 + (9 - i) * 1.0), -8.0 - i * 6.2) * k, 0.8 * k + tw * 0.4, Color("#FFD27A", 0.5 + 0.5 * tw))
	_glow(c, base + Vector2(0, -34) * k, 40.0 * k, Color(1.0, 0.8, 0.4, 0.1))


static func _ratatouille(c: CanvasItem, t: float, s: int, u: float, ls: float) -> void:
	match s:
		0:
			# Paris at nightfall: the tower sparkling over the roofs, the river shining below.
			_sky(c, Color("#1A1E54"), Color("#5A3A7A"), Color("#F0A070"), 72.0)
			_stars(c, t, 18, 28.0, 0.6)
			_glow(c, Vector2(40, 66), 34.0, Color(1.0, 0.7, 0.4, 0.14))
			_paris(c, t, 134.0, 1.0)
			for i in 7:
				var x := i * 32.0 - 8.0 - u * 6.0
				var h := 20.0 + _r(i) * 10.0
				c.draw_rect(Rect2(x, 90 - h, 30, h + 10), Color("#4A4060").darkened(0.1 * (i % 2)))
				c.draw_colored_polygon(PackedVector2Array([Vector2(x - 2, 90 - h), Vector2(x + 32, 90 - h), Vector2(x + 26, 90 - h - 8), Vector2(x + 4, 90 - h - 8)]), Color("#6A7090"))
				for w in 3:
					c.draw_rect(Rect2(x + 5 + w * 9.0, 90 - h + 6, 5, 6), Color("#FFD27A") if (i + w) % 2 == 0 else Color("#2A2F4A"))
			_grad(c, Rect2(0, 92, SIZE.x, 16), Color("#3A3A78"), Color("#1A1E48"))
			for i in 12:
				c.draw_line(Vector2(fposmod(i * 17.0 + t * 4.0, SIZE.x), 94 + i % 5 * 2.6), Vector2(fposmod(i * 17.0 + t * 4.0, SIZE.x) + 7, 94 + i % 5 * 2.6), Color(1, 0.85, 0.5, 0.3), 0.8)
		1:
			# On a roof: a skylight glows; a small grey nose and two ears peek out, then the whole rat.
			_sky(c, Color("#10163E"), Color("#2A2A62"), Color("#4A4A80"), 80.0)
			_stars(c, t, 26, 40.0)
			c.draw_circle(Vector2(160, 22), 8.0, Color("#FFF6D6"))
			_glow(c, Vector2(160, 22), 24.0, Color(1, 1, 0.9, 0.1))
			c.draw_polygon(PackedVector2Array([Vector2(0, 80), Vector2(SIZE.x, 70), Vector2(SIZE.x, SIZE.y), Vector2(0, SIZE.y)]), PackedColorArray([Color("#5A6280"), Color("#4A5270"), Color("#2E3450"), Color("#2E3450")]))
			for i in 8:
				c.draw_line(Vector2(i * 28.0, 80 - i * 1.0), Vector2(i * 28.0 - 14, SIZE.y), Color("#3A4260"), 0.8)
			c.draw_polygon(PackedVector2Array([Vector2(70, 88), Vector2(126, 86), Vector2(122, 100), Vector2(66, 102)]), PackedColorArray([Color("#FFD890"), Color("#FFD890"), Color("#C88A40"), Color("#C88A40")]))
			c.draw_rect(Rect2(66, 74, 4, 28), Color("#3A4260"))
			_glow(c, Vector2(96, 80), 40.0, Color(1.0, 0.8, 0.4, 0.18))
			var rise := ease(clampf(u * 1.4, 0.0, 1.0), 0.5)
			var rat := Vector2(98, 88 - rise * 16.0)
			c.draw_circle(rat, 9.0, Color("#8A8E96"))
			c.draw_circle(rat + Vector2(-2.5, -3), 5.0, Color("#9EA2AA"))
			for ex in [-7.5, 7.5]:
				c.draw_circle(rat + Vector2(ex, -6), 4.2, Color("#9A9EA6"))
				c.draw_circle(rat + Vector2(ex, -6), 2.4, Color("#F2A0B0"))
			c.draw_circle(rat + Vector2(-3.4, -1), 1.3, Color("#14141C"))
			c.draw_circle(rat + Vector2(3.4, -1), 1.3, Color("#14141C"))
			c.draw_circle(rat + Vector2(-3.8, -1.4), 0.4, Color.WHITE)
			c.draw_circle(rat + Vector2(3.0, -1.4), 0.4, Color.WHITE)
			c.draw_circle(rat + Vector2(0, 3.6), 1.7, Color("#F2A0B0"))
			for sd in [-1, 1]:
				c.draw_line(rat + Vector2(sd * 2.0, 4.0), rat + Vector2(sd * 11.0, 2.0 + sin(t * 5.0)), Color(1, 1, 1, 0.5), 0.5)
				c.draw_line(rat + Vector2(sd * 2.0, 4.6), rat + Vector2(sd * 11.0, 6.0), Color(1, 1, 1, 0.5), 0.5)
			if u > 0.5:
				for i in 3:
					c.draw_circle(rat + Vector2(-12.0 + i * 12.0, -16.0 - fposmod(ls * 4.0 + i * 3.0, 8.0)), 1.1, Color(1.0, 0.9, 0.5, 0.7))
		2:
			# The kitchen: tiles, a gleaming stove, the pot steaming, the little chef in his tall white hat stirring.
			_grad(c, Rect2(0, 0, SIZE.x, 64), Color("#F6ECD6"), Color("#E4D4B6"))
			for i in 12:
				c.draw_line(Vector2(i * 18.0, 0), Vector2(i * 18.0, 64), Color("#D8C8A8"), 0.6)
			for j in 4:
				c.draw_line(Vector2(0, j * 16.0), Vector2(SIZE.x, j * 16.0), Color("#D8C8A8"), 0.6)
			for i in 5:
				c.draw_line(Vector2(20 + i * 8.0, 12), Vector2(20 + i * 8.0, 20), Color("#8A8E96"), 1.0)
				c.draw_circle(Vector2(20 + i * 8.0, 24), 2.4 + (i % 2), Color("#B0B4BC"))
			_grad(c, Rect2(0, 64, SIZE.x, 44), Color("#9AA8B4"), Color("#5E6A78"))
			c.draw_rect(Rect2(0, 64, SIZE.x, 3), Color("#D0DAE2"))
			var pot := Vector2(78, 64)
			c.draw_rect(Rect2(pot + Vector2(-24, -24), Vector2(48, 24)), Color("#4E525A"))
			c.draw_rect(Rect2(pot + Vector2(-24, -24), Vector2(10, 24)), Color("#6A6E78"))
			c.draw_rect(Rect2(pot + Vector2(-27, -27), Vector2(54, 4)), Color("#80848E"))
			c.draw_rect(Rect2(pot + Vector2(-22, -26), Vector2(44, 2)), Color("#C85A28"))
			for i in 4:
				var sp := fposmod(t * 0.7 + i * 0.25, 1.0)
				c.draw_circle(pot + Vector2(-12.0 + i * 8.0 + sin(t * 2.0 + i) * 3.0, -32.0 - sp * 26.0), 3.0 + sp * 4.0, Color(1, 1, 1, 0.5 * (1.0 - sp)))
			for i in 3:
				var fl := 2.0 + sin(t * 12.0 + i * 2.0) * 0.8
				c.draw_colored_polygon(PackedVector2Array([Vector2(60 + i * 18.0, 64), Vector2(66 + i * 18.0, 64), Vector2(63 + i * 18.0, 64 - fl)]), Color("#4FA8FF"))
			var rat := Vector2(132, 62)
			c.draw_circle(rat + Vector2(1.5, 1.5), 9.0, Color(0, 0, 0, 0.2))
			c.draw_circle(rat, 9.0, Color("#8A8E96"))
			c.draw_circle(rat + Vector2(-3, -2), 5.5, Color("#9EA2AA"))
			c.draw_circle(rat + Vector2(-7, -10), 6.0, Color("#9A9EA6"))
			c.draw_circle(rat + Vector2(-4, -15.5), 2.8, Color("#9A9EA6"))
			c.draw_circle(rat + Vector2(-4, -15.5), 1.5, Color("#F2A0B0"))
			c.draw_circle(rat + Vector2(-12.6, -9), 1.3, Color("#F2A0B0"))
			c.draw_circle(rat + Vector2(-8.4, -11), 1.0, Color("#14141C"))
			c.draw_rect(Rect2(rat + Vector2(-11, -26), Vector2(9, 10)), Color("#FDFDFD"))
			c.draw_circle(rat + Vector2(-6.5, -27.5), 5.4, Color.WHITE)
			c.draw_circle(rat + Vector2(-9.0, -26.0), 3.4, Color("#EEF0F4"))
			c.draw_arc(rat + Vector2(10, 3), 8.0, -0.6, 1.7, 8, Color("#8A8E96"), 1.5)
			var hand := pot + Vector2(10.0 + cos(t * 4.0) * 9.0, -28.0 + sin(t * 4.0) * 2.5)
			c.draw_line(rat + Vector2(-8, -2), hand, Color("#B88A5A"), 1.8)
			c.draw_line(hand, hand + Vector2(-5, 9), Color("#8A5A32"), 1.2)
			if u > 0.5:
				for i in 4:
					var a := fposmod(ls * 3.0 + i * 1.3, 4.0)
					c.draw_circle(Vector2(104.0 + i * 10.0, 40.0 - a * 3.0), 1.2, Color("#FFD23F", 1.0 - a / 4.0))
		_:
			# The dish: a spiral of vegetable slices on a white plate, a candle and little stars over a restaurant table.
			_grad(c, Rect2(0, 0, SIZE.x, SIZE.y), Color("#2A1A2E"), Color("#5A2A2A"))
			_glow(c, Vector2(98, 56), 80.0, Color(1.0, 0.7, 0.4, 0.12))
			c.draw_polygon(PackedVector2Array([Vector2(0, 74), Vector2(SIZE.x, 74), Vector2(SIZE.x, SIZE.y), Vector2(0, SIZE.y)]), PackedColorArray([Color("#E8DCC4"), Color("#E8DCC4"), Color("#B8A888"), Color("#B8A888")]))
			c.draw_set_transform(Vector2(98, 66), 0.0, Vector2(1.0, 0.72))
			c.draw_circle(Vector2(2, 4), 38.0, Color(0, 0, 0, 0.2))
			c.draw_circle(Vector2.ZERO, 38.0, Color("#FFFFFF"))
			c.draw_circle(Vector2.ZERO, 31.0, Color("#F2EEE6"))
			var slices := [Color("#C8303A"), Color("#E8B020"), Color("#5A2A60"), Color("#3E8E3A")]
			var show := int(clampf(u * 1.8, 0.0, 1.0) * 30.0)
			for i in show:
				var a := i * 0.62
				var r := 4.0 + i * 0.86
				c.draw_circle(Vector2(cos(a), sin(a)) * r, 3.8, slices[i % 4].darkened(0.25))
				c.draw_circle(Vector2(cos(a), sin(a)) * r + Vector2(-0.4, -0.4), 3.2, slices[i % 4])
			c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			c.draw_rect(Rect2(163, 48, 5, 26), Color("#F4E8D0"))
			c.draw_colored_polygon(PackedVector2Array([Vector2(165.5, 38.0 + sin(t * 9.0)), Vector2(168, 48), Vector2(163, 48)]), Color("#FFB030"))
			_glow(c, Vector2(165.5, 44), 18.0, Color(1.0, 0.8, 0.4, 0.3))
			for i in 7:
				var a := TAU * i / 7.0 + t * 0.5
				var sp := Vector2(98, 40) + Vector2(cos(a) * 52.0, sin(a) * 22.0)
				var tw := 0.5 + 0.5 * sin(t * 5.0 + i)
				c.draw_line(sp - Vector2(2, 0) * tw, sp + Vector2(2, 0) * tw, Color("#FFD23F"), 0.9)
				c.draw_line(sp - Vector2(0, 2) * tw, sp + Vector2(0, 2) * tw, Color("#FFD23F"), 0.9)


# ══════════════════════════════════════════════════════════════
#  La Reine des neiges
# ══════════════════════════════════════════════════════════════

static func _palace(c: CanvasItem, foot: Vector2, grow: float, t: float) -> void:
	var ice := Color(0.72, 0.9, 1.0, 0.95)
	var spires := [Vector3(0, 56, 10), Vector3(-17, 38, 8), Vector3(17, 38, 8), Vector3(-30, 25, 6), Vector3(30, 25, 6), Vector3(-9, 44, 5), Vector3(9, 44, 5)]
	for sp: Vector3 in spires:
		var h := sp.y * ease(grow, 0.6)
		var x := foot.x + sp.x
		c.draw_polygon(PackedVector2Array([Vector2(x - sp.z / 2.0, foot.y), Vector2(x + sp.z / 2.0, foot.y), Vector2(x + sp.z / 2.0, foot.y - h * 0.7), Vector2(x - sp.z / 2.0, foot.y - h * 0.7)]),
			PackedColorArray([Color(0.55, 0.78, 0.95), Color(0.55, 0.78, 0.95), Color(0.9, 0.98, 1.0), Color(0.9, 0.98, 1.0)]))
		c.draw_colored_polygon(PackedVector2Array([Vector2(x - sp.z / 2.0 - 1.0, foot.y - h * 0.7), Vector2(x + sp.z / 2.0 + 1.0, foot.y - h * 0.7), Vector2(x, foot.y - h)]), Color(0.9, 0.98, 1.0))
		c.draw_line(Vector2(x - sp.z * 0.25, foot.y - h * 0.65), Vector2(x - sp.z * 0.25, foot.y), Color(1, 1, 1, 0.5), 0.8)
		if grow > 0.8:
			c.draw_rect(Rect2(x - 1.0, foot.y - h * 0.45, 2.0, 3.4), Color("#FFE9A0"))
	c.draw_rect(Rect2(foot.x - 34, foot.y - 12, 68, 12), ice)
	c.draw_rect(Rect2(foot.x - 5, foot.y - 12, 10, 12), Color("#7AB0D8"))
	for i in 10:
		var sp2 := foot + Vector2(sin(i * 2.3) * 34.0, -fmod(i * 11.0, 56.0) * grow)
		var tw := 0.5 + 0.5 * sin(t * 6.0 + i)
		c.draw_line(sp2 - Vector2(2.4, 0) * tw, sp2 + Vector2(2.4, 0) * tw, Color.WHITE, 0.8)
		c.draw_line(sp2 - Vector2(0, 2.4) * tw, sp2 + Vector2(0, 2.4) * tw, Color.WHITE, 0.8)


static func _reine(c: CanvasItem, t: float, s: int, u: float, ls: float) -> void:
	match s:
		0:
			# Mountains under the northern lights and a wide field of untouched snow; the wind starts to swirl.
			_sky(c, Color("#0A1238"), Color("#1C2E6A"), Color("#4E6AAA"), 66.0)
			for i in 3:
				for k in 20:
					var x0 := k * SIZE.x / 20.0
					var x1 := (k + 1) * SIZE.x / 20.0
					var y0 := 22.0 + i * 7.0 + sin(x0 * 0.05 + t * 0.8 + i) * 6.0
					var y1 := 22.0 + i * 7.0 + sin(x1 * 0.05 + t * 0.8 + i) * 6.0
					c.draw_polygon(PackedVector2Array([Vector2(x0, y0), Vector2(x1, y1), Vector2(x1, y1 + 18), Vector2(x0, y0 + 18)]), PackedColorArray([Color(0.4, 1.0, 0.75, 0.3), Color(0.4, 1.0, 0.75, 0.3), Color(0.4, 0.7, 1.0, 0.0), Color(0.4, 0.7, 1.0, 0.0)]))
			_stars(c, t, 40, 40.0)
			c.draw_colored_polygon(PackedVector2Array([Vector2(-10, 84), Vector2(38, 38), Vector2(92, 84)]), Color("#8EA6D2"))
			c.draw_colored_polygon(PackedVector2Array([Vector2(38, 38), Vector2(92, 84), Vector2(60, 84)]), Color("#6E88B6"))
			c.draw_colored_polygon(PackedVector2Array([Vector2(110, 84), Vector2(162, 30), Vector2(214, 84)]), Color("#9AB2DA"))
			c.draw_colored_polygon(PackedVector2Array([Vector2(162, 30), Vector2(214, 84), Vector2(184, 84)]), Color("#7A94C4"))
			c.draw_colored_polygon(PackedVector2Array([Vector2(28, 50), Vector2(38, 38), Vector2(48, 50), Vector2(42, 47), Vector2(38, 52), Vector2(33, 47)]), Color.WHITE)
			_hills(c, 84.0, 3.0, 0.07, 1.0, Color("#E4ECF8"), Color("#FFFFFF"))
			for i in 30:
				var a := t * (1.2 + u * 1.5) + i * 0.52
				var r := 4.0 + fposmod(i * 7.0, 46.0) * (0.4 + u)
				c.draw_circle(Vector2(98, 78) + Vector2(cos(a) * r, sin(a) * r * 0.32), 1.0, Color(1, 1, 1, 0.8 * clampf(u * 3.0, 0.0, 1.0)))
			_snow(c, t, 14, 8.0)
		1:
			# A staircase of ice builds itself, step after step, across a frozen gap, each one sparkling.
			_sky(c, Color("#0E1A48"), Color("#2A3E86"), Color("#7A92CE"), 70.0)
			_stars(c, t, 30, 40.0)
			_hills(c, 76.0, 3.0, 0.06, 0.0, Color("#B8CCEA"), Color("#EAF2FC"))
			c.draw_polygon(PackedVector2Array([Vector2(0, 80), Vector2(70, 80), Vector2(70, SIZE.y), Vector2(0, SIZE.y)]), PackedColorArray([Color("#EEF4FC"), Color("#EEF4FC"), Color("#C8D6EE"), Color("#C8D6EE")]))
			c.draw_polygon(PackedVector2Array([Vector2(126, 52), Vector2(SIZE.x, 52), Vector2(SIZE.x, SIZE.y), Vector2(126, SIZE.y)]), PackedColorArray([Color("#EEF4FC"), Color("#EEF4FC"), Color("#C8D6EE"), Color("#C8D6EE")]))
			var n := int(clampf(u * 1.3, 0.0, 1.0) * 12.0)
			for i in n:
				var x := 70.0 + i * 4.7
				var y := 80.0 - i * 2.35
				c.draw_rect(Rect2(x, y, 5.4, 4.0), Color(0.78, 0.93, 1.0, 0.95))
				c.draw_rect(Rect2(x, y, 5.4, 1.2), Color(1, 1, 1, 0.9))
				var tw := 0.5 + 0.5 * sin(t * 8.0 + i * 1.7)
				c.draw_circle(Vector2(x + 2.7, y - 1.5), 0.9 * tw, Color.WHITE)
			if n > 0:
				var sx := 70.0 + n * 4.7
				for i in 8:
					var a := t * 3.0 + i
					c.draw_circle(Vector2(sx, 80.0 - n * 2.35) + Vector2(cos(a), sin(a)) * (4.0 + i * 0.7), 0.8, Color(0.8, 0.95, 1.0, 0.8))
			_snow(c, t, 18, 5.0)
		2:
			# The palace rises from the snow, spire after spire, under the swirling snow.
			_sky(c, Color("#0E1A48"), Color("#2E4488"), Color("#8CA4DA"), 72.0)
			_stars(c, t, 30, 40.0)
			c.draw_colored_polygon(PackedVector2Array([Vector2(-10, 90), Vector2(40, 44), Vector2(92, 90)]), Color("#8EA6D2"))
			c.draw_colored_polygon(PackedVector2Array([Vector2(110, 90), Vector2(164, 38), Vector2(214, 90)]), Color("#9AB2DA"))
			_hills(c, 90.0, 2.0, 0.08, 0.0, Color("#EEF4FC"), Color("#FFFFFF"))
			var grow := clampf(u * 1.3, 0.0, 1.0)
			_glow(c, Vector2(98, 70), 64.0 * grow, Color(0.6, 0.9, 1.0, 0.16))
			_palace(c, Vector2(98, 96), grow, t)
			for i in 28:
				var a := t * 2.0 + i * 0.5
				var r := 6.0 + fmod(i * 7.0, 46.0)
				c.draw_circle(Vector2(98, 80) + Vector2(cos(a) * r, sin(a) * r * 0.3), 1.0, Color(1, 1, 1, 0.75 * (1.0 - u * 0.6)))
			_snow(c, t, 14, 4.0)
		_:
			# Dawn on the finished palace: pink and gold on its ice, a snowman hopping with joy.
			_sky(c, Color("#4A5E9E"), Color("#E89AB0"), Color("#FFD8A0"), 72.0)
			_glow(c, Vector2(150, 62), 56.0, Color(1.0, 0.85, 0.55, 0.22))
			c.draw_circle(Vector2(150, 62), 9.0, Color("#FFF2C0"))
			c.draw_colored_polygon(PackedVector2Array([Vector2(-10, 90), Vector2(40, 40), Vector2(92, 90)]), Color("#B8B8E0"))
			c.draw_colored_polygon(PackedVector2Array([Vector2(110, 90), Vector2(170, 44), Vector2(214, 90)]), Color("#C8B8E0"))
			_hills(c, 90.0, 2.0, 0.08, 0.0, Color("#FCEFF4"), Color("#FFFFFF"))
			_palace(c, Vector2(98, 96), 1.0, t)
			c.draw_polygon(PackedVector2Array([Vector2(60, 40), Vector2(136, 40), Vector2(136, 96), Vector2(60, 96)]), PackedColorArray([Color(1, 0.8, 0.6, 0.12), Color(1, 0.8, 0.6, 0.0), Color(1, 0.8, 0.6, 0.0), Color(1, 0.8, 0.6, 0.12)]))
			var hop := absf(sin(t * 3.5)) * 3.5
			_snowman(c, Vector2(40, 98 - hop), 1.1, t)
			_snow(c, t, 16, 3.0)


# ══════════════════════════════════════════════════════════════
#  Le Roi Lion
# ══════════════════════════════════════════════════════════════

static func _acacia(c: CanvasItem, p: Vector2, s: float, col: Color) -> void:
	c.draw_line(p, p + Vector2(1.0, -14.0) * s, col, 1.8 * s)
	c.draw_line(p + Vector2(1.0, -9.0) * s, p + Vector2(-7.0, -15.0) * s, col, 1.2 * s)
	c.draw_line(p + Vector2(1.0, -11.0) * s, p + Vector2(8.0, -16.0) * s, col, 1.2 * s)
	c.draw_set_transform(p + Vector2(1.0, -17.0) * s, 0.0, Vector2(1.0, 0.32))
	c.draw_circle(Vector2.ZERO, 15.0 * s, col)
	c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


static func _lion(c: CanvasItem, t: float, s: int, u: float, ls: float) -> void:
	match s:
		0:
			# Sunrise on the savanna: a huge sun, acacias, a herd walking across in silhouette.
			var k := clampf(u * 1.5, 0.0, 1.0)
			_sky(c, Color("#6A2A5A").lerp(Color("#3A7AC0"), k * 0.6), Color("#F08A3A"), Color("#FFD060"), 70.0)
			var sy := lerpf(76.0, 54.0, ease(k, 0.5))
			_glow(c, Vector2(98, sy), 80.0, Color(1.0, 0.8, 0.3, 0.2))
			c.draw_circle(Vector2(98, sy), 17.0, Color("#FFE890"))
			c.draw_circle(Vector2(98, sy), 14.0, Color("#FFF6C8"))
			for i in 14:
				var a := PI + (i + 0.5) / 14.0 * PI
				c.draw_line(Vector2(98, sy) + Vector2(cos(a), sin(a)) * 20.0, Vector2(98, sy) + Vector2(cos(a), sin(a)) * (34.0 + (i % 2) * 8.0), Color(1, 0.9, 0.5, 0.25), 1.6)
			_hills(c, 76.0, 3.0, 0.05, 1.0, Color("#B4601E"), Color("#7A3A12"))
			_acacia(c, Vector2(30, 80), 1.2, Color("#3A2A16"))
			_acacia(c, Vector2(170, 78), 1.0, Color("#3A2A16"))
			_hills(c, 86.0, 2.0, 0.06, 2.0, Color("#2E1E10"), Color("#1A1008"))
			var dark := Color("#1E1208")
			for i in 4:
				var x := fposmod(-20.0 + i * 38.0 + u * 160.0, 230.0) - 20.0
				var step := sin(ls * 3.0 + i) * 1.2
				if i % 2 == 0:
					# An elephant: round body, big ear, trunk, four legs.
					c.draw_set_transform(Vector2(x, 70.0), 0.0, Vector2(1.35, 1.0))
					c.draw_circle(Vector2.ZERO, 7.0, dark)
					c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
					c.draw_circle(Vector2(x + 9.0, 66.0), 4.4, dark)
					c.draw_circle(Vector2(x + 6.0, 66.5), 3.6, dark)
					c.draw_line(Vector2(x + 12.0, 67.0), Vector2(x + 14.0 + step * 0.5, 75.0), dark, 1.6)
					for lx in [-6.0, -2.0, 3.0, 7.0]:
						c.draw_line(Vector2(x + lx, 74.0), Vector2(x + lx + (step if lx < 0.0 else -step) * 0.6, 79.0), dark, 2.2)
					c.draw_line(Vector2(x - 11.0, 68.0), Vector2(x - 13.0, 74.0), dark, 0.8)
				else:
					# A giraffe: a slim body, a long neck, a small head, long legs.
					c.draw_set_transform(Vector2(x, 69.0), 0.0, Vector2(1.5, 0.8))
					c.draw_circle(Vector2.ZERO, 5.0, dark)
					c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
					c.draw_line(Vector2(x + 5.0, 66.0), Vector2(x + 9.0, 52.0), dark, 2.2)
					c.draw_circle(Vector2(x + 10.0, 51.0), 2.2, dark)
					c.draw_line(Vector2(x + 11.0, 49.0), Vector2(x + 11.5, 47.0), dark, 0.8)
					for lx in [-5.0, -2.0, 3.0, 6.0]:
						c.draw_line(Vector2(x + lx, 71.0), Vector2(x + lx + (step if lx < 0.0 else -step) * 0.5, 80.0), dark, 1.1)
			for i in 6:
				var bx := fposmod(_r(i) * 300.0 + t * (8.0 + i), 220.0) - 12.0
				c.draw_line(Vector2(bx, 24 + _r(i + 4) * 14.0), Vector2(bx + 3, 22 + _r(i + 4) * 14.0 + sin(t * 8.0 + i) * 1.5), Color("#2A1A10"), 0.8)
		1:
			# On the high rock, the little cub held up to the sun while the crowd below looks up.
			_sky(c, Color("#3A7AC0"), Color("#F0A860"), Color("#FFE090"), 70.0)
			_glow(c, Vector2(98, 40), 70.0, Color(1.0, 0.9, 0.5, 0.25))
			c.draw_circle(Vector2(98, 40), 14.0, Color("#FFF2B8"))
			for i in 16:
				var a := TAU * i / 16.0 + t * 0.1
				c.draw_line(Vector2(98, 40) + Vector2(cos(a), sin(a)) * 18.0, Vector2(98, 40) + Vector2(cos(a), sin(a)) * 60.0, Color(1, 0.95, 0.6, 0.12), 2.4)
			_hills(c, 90.0, 2.0, 0.05, 0.5, Color("#6A3A16"), Color("#3A1E0A"))
			c.draw_colored_polygon(PackedVector2Array([Vector2(50, 100), Vector2(66, 66), Vector2(112, 58), Vector2(150, 70), Vector2(160, 100)]), Color("#7A4A28"))
			c.draw_colored_polygon(PackedVector2Array([Vector2(50, 100), Vector2(66, 66), Vector2(86, 64), Vector2(84, 100)]), Color("#9A6638"))
			c.draw_colored_polygon(PackedVector2Array([Vector2(66, 66), Vector2(112, 58), Vector2(100, 70), Vector2(78, 72)]), Color("#B08048"))
			var up := ease(clampf(u * 2.0, 0.0, 1.0), 0.5)
			var cub := Vector2(104, 56 - up * 9.0)
			c.draw_line(Vector2(96, 60), cub + Vector2(-2, 3), Color("#4A2A16"), 2.0)
			c.draw_line(Vector2(112, 60), cub + Vector2(2, 3), Color("#4A2A16"), 2.0)
			c.draw_circle(cub, 4.6, Color("#E8A850"))
			c.draw_circle(cub + Vector2(0, 3.8), 3.4, Color("#E8A850"))
			c.draw_circle(cub + Vector2(-3.4, -3.4), 1.6, Color("#E8A850"))
			c.draw_circle(cub + Vector2(3.4, -3.4), 1.6, Color("#E8A850"))
			c.draw_circle(cub + Vector2(-1.6, -0.4), 0.7, Color("#1A1008"))
			c.draw_circle(cub + Vector2(1.6, -0.4), 0.7, Color("#1A1008"))
			c.draw_circle(cub + Vector2(0, 1.4), 0.9, Color("#8A3A28"))
			c.draw_circle(cub + Vector2(0, -4.6), 2.4, Color("#B8581E"))
			for i in 18:
				var x := 8.0 + i * 10.5
				var h := 4.0 + _r(i) * 4.0
				c.draw_circle(Vector2(x, 94 + (i % 3) * 3.0), h * 0.5, Color("#1E1208"))
				if u > 0.3:
					c.draw_line(Vector2(x, 94 + (i % 3) * 3.0 - 1.0), Vector2(x + 0.5, 86.0 + (i % 3) * 3.0 - sin(t * 3.0 + i) * 1.0), Color("#1E1208"), 0.9)
			for i in 12:
				var bx := fposmod(_r(i) * 250.0 + t * 7.0, 215.0) - 10.0
				c.draw_circle(Vector2(bx, 20.0 + _r(i + 2) * 30.0), 0.9, Color(1, 0.95, 0.7, 0.7))
		2:
			# Green jungle by a waterfall: the cub and two friends stroll under hanging vines, butterflies everywhere.
			_grad(c, Rect2(0, 0, SIZE.x, SIZE.y), Color("#BEE8A0"), Color("#2E7A3A"))
			_glow(c, Vector2(60, 10), 60.0, Color(1, 1, 0.7, 0.2))
			for i in 7:
				var x := 14.0 + i * 30.0
				c.draw_polygon(PackedVector2Array([Vector2(x - 4, 0), Vector2(x + 4, 0), Vector2(x + 3, 80), Vector2(x - 3, 80)]), PackedColorArray([Color("#3A5A2A"), Color("#3A5A2A"), Color("#2A3E1A"), Color("#2A3E1A")]))
				c.draw_circle(Vector2(x, 8), 14.0, Color("#2E7A3A", 0.9))
				c.draw_line(Vector2(x + 4, 14), Vector2(x + 7 + sin(t + i) * 2.0, 44), Color("#3E8A3A"), 1.0)
			# The waterfall and its pool.
			c.draw_polygon(PackedVector2Array([Vector2(128, 0), Vector2(150, 0), Vector2(152, 70), Vector2(126, 70)]), PackedColorArray([Color("#E8FAFF"), Color("#E8FAFF"), Color("#9AD8F0"), Color("#9AD8F0")]))
			for i in 8:
				var y := fposmod(t * 40.0 + i * 11.0, 70.0)
				c.draw_line(Vector2(131 + i * 2.2, y), Vector2(131 + i * 2.2, y + 6.0), Color(1, 1, 1, 0.8), 0.8)
			c.draw_set_transform(Vector2(140, 72), 0.0, Vector2(1.0, 0.3))
			c.draw_circle(Vector2.ZERO, 26.0, Color("#6AC4E0"))
			c.draw_circle(Vector2.ZERO, 18.0, Color("#9AE0F0"))
			c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			c.draw_rect(Rect2(0, 82, SIZE.x, 26), Color("#3E7A34"))
			c.draw_polygon(PackedVector2Array([Vector2(0, 84), Vector2(SIZE.x, 84), Vector2(SIZE.x, SIZE.y), Vector2(0, SIZE.y)]), PackedColorArray([Color("#58A044"), Color("#58A044"), Color("#2E6428"), Color("#2E6428")]))
			var wx := lerpf(-20.0, 120.0, u)
			for i in 3:
				var fx := wx - i * 22.0
				var by := 92.0 + sin(ls * 6.0 + i) * 1.0
				var tint: Color = [Color("#E8A850"), Color("#B8784A"), Color("#8A8A8A")][i]
				c.draw_circle(Vector2(fx, by - 4.0), 5.5 - i * 0.6, tint)
				c.draw_circle(Vector2(fx + 5.0, by - 7.0), 3.6 - i * 0.3, tint)
				c.draw_circle(Vector2(fx + 6.0, by - 7.6), 0.7, Color("#1A1008"))
				c.draw_line(Vector2(fx - 4, by - 2), Vector2(fx - 4 + sin(ls * 6.0) * 2.0, by + 3), tint.darkened(0.3), 1.4)
				c.draw_line(Vector2(fx + 2, by - 2), Vector2(fx + 2 - sin(ls * 6.0) * 2.0, by + 3), tint.darkened(0.3), 1.4)
			for i in 6:
				var bp := Vector2(40.0 + i * 24.0 + sin(t * 1.3 + i) * 12.0, 56.0 + cos(t * 1.7 + i * 2.0) * 10.0)
				var fl := absf(sin(t * 12.0 + i)) * 2.4 + 0.4
				var col: Color = [Color("#FFB030"), Color("#FF6A90"), Color("#8AD0FF")][i % 3]
				c.draw_colored_polygon(PackedVector2Array([bp, bp + Vector2(-fl * 1.6, -2.4), bp + Vector2(-fl, 1.6)]), col)
				c.draw_colored_polygon(PackedVector2Array([bp, bp + Vector2(fl * 1.6, -2.4), bp + Vector2(fl, 1.6)]), col)
		_:
			# Night on the plain: the grown lion on the high rock under the moon, a river of stars above him.
			_sky(c, Color("#06082A"), Color("#1A1E5A"), Color("#4A3A8A"), 76.0)
			_stars(c, t, 60, 56.0)
			for i in 30:
				var a := 0.2 + i * 0.07
				c.draw_circle(Vector2(20.0 + i * 5.6, 54.0 - sin(a * 3.0) * 20.0 - i * 0.6), 0.5, Color(0.9, 0.9, 1.0, 0.5))
			c.draw_circle(Vector2(162, 26), 12.0, Color("#FFF6D6"))
			c.draw_circle(Vector2(158, 22), 3.0, Color("#EEE2B8"))
			_glow(c, Vector2(162, 26), 34.0, Color(0.9, 0.95, 1.0, 0.14))
			_hills(c, 88.0, 2.0, 0.05, 1.0, Color("#12102E"), Color("#080818"))
			c.draw_colored_polygon(PackedVector2Array([Vector2(60, 100), Vector2(76, 68), Vector2(120, 62), Vector2(146, 74), Vector2(156, 100)]), Color("#1A1636"))
			c.draw_colored_polygon(PackedVector2Array([Vector2(76, 68), Vector2(120, 62), Vector2(108, 72), Vector2(88, 74)]), Color("#2E2850"))
			var li := Vector2(104, 60)
			c.draw_circle(li + Vector2(0, -6), 7.4, Color("#0E0C22"))
			c.draw_circle(li + Vector2(0, -6), 5.2, Color("#241E44"))
			c.draw_rect(Rect2(li + Vector2(-4, -3), Vector2(8, 10)), Color("#0E0C22"))
			c.draw_circle(li + Vector2(1.4, -6.2), 0.6, Color(1.0, 0.85, 0.4, 0.9))
			c.draw_circle(li + Vector2(-1.4, -6.2), 0.6, Color(1.0, 0.85, 0.4, 0.9))
			c.draw_arc(li + Vector2(-5, 4), 6.0, PI * 0.6, PI * 1.6, 8, Color("#0E0C22"), 1.6)
			c.draw_circle(li + Vector2(-9, 0.4), 1.8, Color("#0E0C22"))


# ══════════════════════════════════════════════════════════════
#  Le monde de Nemo
# ══════════════════════════════════════════════════════════════

static func _water(c: CanvasItem, t: float, top: Color, bottom: Color, rays := 0.12) -> void:
	_grad(c, Rect2(0, 0, SIZE.x, SIZE.y), top, bottom)
	for i in 6:
		var x := 20.0 + i * 36.0 + sin(t * 0.4 + i) * 6.0
		c.draw_polygon(PackedVector2Array([Vector2(x - 3, 0), Vector2(x + 3, 0), Vector2(x + 20, SIZE.y), Vector2(x - 12, SIZE.y)]), PackedColorArray([Color(1, 1, 0.9, rays), Color(1, 1, 0.9, rays), Color(1, 1, 0.9, 0.0), Color(1, 1, 0.9, 0.0)]))


static func _clownfish(c: CanvasItem, p: Vector2, s: float, t: float, dir := 1.0) -> void:
	var flap := sin(t * 9.0) * 1.2
	c.draw_set_transform(p, 0.0, Vector2(dir * s, s))
	c.draw_colored_polygon(PackedVector2Array([Vector2(-6, 0), Vector2(-12, -4 + flap), Vector2(-12, 4 - flap)]), Color("#FF7A20"))
	c.draw_circle(Vector2(0, 0), 6.0, Color("#FF7A20"))
	c.draw_set_transform(p, 0.0, Vector2(dir * s * 1.0, s * 0.82))
	c.draw_circle(Vector2(2, -1), 3.0, Color("#FFA050"))
	c.draw_set_transform(p, 0.0, Vector2(dir * s, s))
	for x in [-2.0, 3.6]:
		c.draw_rect(Rect2(x, -5.2, 1.8, 10.4), Color.WHITE)
		c.draw_rect(Rect2(x - 0.4, -5.2, 0.4, 10.4), Color("#2A1A10"))
		c.draw_rect(Rect2(x + 1.8, -5.2, 0.4, 10.4), Color("#2A1A10"))
	c.draw_circle(Vector2(4.4, -1.2), 1.1, Color.WHITE)
	c.draw_circle(Vector2(4.7, -1.2), 0.6, Color("#101010"))
	c.draw_colored_polygon(PackedVector2Array([Vector2(-1, -5), Vector2(3, -8 - flap * 0.4), Vector2(5, -4.6)]), Color("#FF7A20"))
	c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


static func _anemone(c: CanvasItem, p: Vector2, s: float, t: float) -> void:
	for i in 14:
		var a := -PI * (0.1 + i / 14.0 * 0.8)
		var sw := sin(t * 1.6 + i) * 3.0
		var tip := p + Vector2(cos(a) * 14.0 * s + sw, sin(a) * 18.0 * s)
		c.draw_line(p, tip, Color("#E83A8A") if i % 2 == 0 else Color("#FF6AB0"), 2.2 * s)
		c.draw_circle(tip, 1.4 * s, Color("#FFC0E0"))
	c.draw_circle(p, 5.0 * s, Color("#B8286A"))


static func _coral(c: CanvasItem, p: Vector2, s: float, col: Color, kind: int) -> void:
	if kind == 0:
		for i in 5:
			var a := -PI / 2.0 + (i - 2) * 0.4
			var tip := p + Vector2(cos(a), sin(a)) * 18.0 * s
			c.draw_line(p, tip, col, 3.0 * s)
			c.draw_circle(tip, 2.0 * s, col.lightened(0.2))
	else:
		c.draw_set_transform(p, 0.0, Vector2(1.0, 0.7))
		c.draw_circle(Vector2.ZERO, 11.0 * s, col)
		c.draw_circle(Vector2(-3, -3) * s, 6.0 * s, col.lightened(0.18))
		c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


static func _nemo(c: CanvasItem, t: float, s: int, u: float, ls: float) -> void:
	match s:
		0:
			# The reef in sunlit water: coral, an anemone, the little clownfish peeking out and swimming round.
			_water(c, t, Color("#46C8E8"), Color("#0A5A9A"))
			c.draw_rect(Rect2(0, 88, SIZE.x, 20), Color("#D8C890"))
			_hills(c, 90.0, 2.0, 0.08, 0.0, Color("#E8D8A0"), Color("#B8A870"))
			for i in 6:
				_coral(c, Vector2(14.0 + i * 34.0, 92.0), 1.1 + (i % 2) * 0.3, [Color("#F06A4A"), Color("#B85AD8"), Color("#FFB030")][i % 3], i % 2)
			_anemone(c, Vector2(98, 92), 1.5, t)
			var fx := 98.0 + sin(t * 0.9) * 26.0
			_clownfish(c, Vector2(fx, 76.0 + sin(t * 1.4) * 3.0), 1.4, t, 1.0 if cos(t * 0.9) > 0 else -1.0)
			_clownfish(c, Vector2(40.0 + sin(t * 0.7 + 2.0) * 16.0, 56.0), 0.8, t, 1.0 if cos(t * 0.7 + 2.0) > 0 else -1.0)
			for i in 10:
				_bubble(c, Vector2(20.0 + _r(i) * 160.0, fposmod(100.0 - t * (7.0 + i) + _r(i + 3) * 90.0, 100.0) + 4.0), 0.8 + _r(i + 5) * 1.2)
		1:
			# The open blue: jellyfish drift up, a shoal of tiny silver fish turns together.
			_water(c, t, Color("#2AA0D8"), Color("#04204A"), 0.1)
			for i in 4:
				var jp := Vector2(30.0 + i * 48.0 + sin(t * 0.5 + i) * 6.0, fposmod(120.0 - t * (5.0 + i) - i * 24.0, 130.0) - 10.0)
				var pulse := 1.0 + sin(t * 3.0 + i) * 0.08
				c.draw_set_transform(jp, 0.0, Vector2(1.0, 0.8 * pulse))
				c.draw_circle(Vector2.ZERO, 9.0, Color(1.0, 0.5, 0.8, 0.35))
				c.draw_circle(Vector2.ZERO, 7.0, Color(1.0, 0.7, 0.9, 0.45))
				c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
				for k in 5:
					var tx := jp.x - 6.0 + k * 3.0
					c.draw_line(Vector2(tx, jp.y + 4.0), Vector2(tx + sin(t * 2.0 + k + i) * 2.0, jp.y + 14.0), Color(1.0, 0.7, 0.9, 0.5), 0.8)
			var sx := fposmod(t * 14.0, 280.0) - 40.0
			for i in 26:
				var a := _r(i) * TAU
				var rr := 14.0 + _r(i + 9) * 16.0
				var p := Vector2(sx + cos(a + t * 0.8) * rr * 1.8, 56.0 + sin(a * 2.0 + t * 0.8) * rr * 0.5)
				c.draw_colored_polygon(PackedVector2Array([p, p + Vector2(-4, -1.2), p + Vector2(-4, 1.2)]), Color(0.85, 0.95, 1.0, 0.85))
				c.draw_circle(p + Vector2(0.3, 0), 0.7, Color.WHITE)
			_clownfish(c, Vector2(60.0 + u * 70.0, 82.0 + sin(ls * 2.0) * 4.0), 1.2, t, 1.0)
			for i in 8:
				_bubble(c, Vector2(20.0 + _r(i + 20) * 160.0, fposmod(110.0 - t * (6.0 + i) + _r(i) * 80.0, 110.0)), 0.7 + _r(i + 5))
		2:
			# Riding the current beside a big green sea turtle, the water streaming past.
			_water(c, t, Color("#38B8E0"), Color("#0A4A8A"), 0.14)
			for i in 14:
				var x := fposmod(_r(i) * 300.0 - t * (30.0 + i * 3.0), 230.0) - 20.0
				c.draw_line(Vector2(x, 14.0 + _r(i + 4) * 80.0), Vector2(x + 18.0, 14.0 + _r(i + 4) * 80.0), Color(1, 1, 1, 0.25), 0.8)
			var tp := Vector2(104, 54 + sin(t * 1.4) * 3.0)
			c.draw_set_transform(tp, 0.0, Vector2(1.0, 0.72))
			c.draw_circle(Vector2(2, 4), 26.0, Color(0, 0, 0, 0.12))
			c.draw_circle(Vector2.ZERO, 24.0, Color("#5A8A3A"))
			c.draw_circle(Vector2(-3, -3), 19.0, Color("#7AA84A"))
			c.draw_set_transform(tp, 0.0, Vector2.ONE)
			for hx in [-10.0, 0.0, 10.0]:
				c.draw_line(Vector2(hx, -12), Vector2(hx, 12), Color("#4A7030"), 1.0)
			c.draw_line(Vector2(-14, -2), Vector2(14, -2), Color("#4A7030"), 1.0)
			var fl := sin(t * 2.4) * 8.0
			c.draw_colored_polygon(PackedVector2Array([tp + Vector2(10, 8), tp + Vector2(28, 14 + fl), tp + Vector2(18, 4)]), Color("#6A9A44"))
			c.draw_colored_polygon(PackedVector2Array([tp + Vector2(-10, 8), tp + Vector2(-28, 14 - fl), tp + Vector2(-16, 4)]), Color("#6A9A44"))
			c.draw_circle(tp + Vector2(26, -2), 7.0, Color("#8AB45A"))
			c.draw_circle(tp + Vector2(28.4, -3.6), 1.4, Color.WHITE)
			c.draw_circle(tp + Vector2(28.8, -3.6), 0.8, Color("#101010"))
			c.draw_arc(tp + Vector2(27, 0), 3.0, 0.2, PI * 0.8, 6, Color("#3A5A28"), 0.8)
			c.draw_colored_polygon(PackedVector2Array([tp + Vector2(-22, 0), tp + Vector2(-32, 2), tp + Vector2(-22, 5)]), Color("#6A9A44"))
			_clownfish(c, tp + Vector2(-6, -24 + sin(t * 2.0)), 1.1, t, 1.0)
			for i in 8:
				_bubble(c, Vector2(fposmod(30.0 + i * 24.0 - t * 22.0, 220.0), 20.0 + _r(i) * 70.0), 0.8 + _r(i + 3))
		_:
			# A great whale glides by in the deep; the little fish are home again in their anemone, safe and sound.
			_water(c, t, Color("#1E88C0"), Color("#031632"), 0.1)
			var wx := lerpf(-70.0, 120.0, u)
			c.draw_set_transform(Vector2(wx, 40), 0.0, Vector2(1.0, 1.0))
			c.draw_colored_polygon(PackedVector2Array([Vector2(-40, 0), Vector2(-20, -12), Vector2(20, -12), Vector2(48, -2), Vector2(52, 6), Vector2(20, 14), Vector2(-20, 14), Vector2(-52, 6), Vector2(-62, -10 + sin(t * 1.5) * 4.0), Vector2(-44, -2)]), Color("#34588A"))
			c.draw_colored_polygon(PackedVector2Array([Vector2(-20, 6), Vector2(20, 6), Vector2(40, 8), Vector2(20, 14), Vector2(-20, 14)]), Color("#B8CCE0"))
			c.draw_circle(Vector2(36, 0), 1.6, Color("#0A1A30"))
			c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			_hills(c, 94.0, 2.0, 0.08, 1.0, Color("#0E3A5A"), Color("#031632"))
			_coral(c, Vector2(40, 96), 1.0, Color("#C8402A"), 0)
			_coral(c, Vector2(160, 96), 1.2, Color("#8A3AB0"), 1)
			_anemone(c, Vector2(104, 98), 1.4, t)
			_clownfish(c, Vector2(104 + sin(t * 1.5) * 7.0, 84.0), 1.3, t, 1.0 if cos(t * 1.5) > 0 else -1.0)
			_clownfish(c, Vector2(86 + sin(t * 1.5 + 1.5) * 7.0, 88.0), 0.9, t, 1.0 if cos(t * 1.5 + 1.5) > 0 else -1.0)
			for i in 10:
				_bubble(c, Vector2(30.0 + _r(i) * 140.0, fposmod(110.0 - t * (6.0 + i) + _r(i + 3) * 80.0, 110.0)), 0.7 + _r(i + 5))


# ══════════════════════════════════════════════════════════════
#  Là-haut
# ══════════════════════════════════════════════════════════════

static func _balloons(c: CanvasItem, anchor: Vector2, t: float, spread: float, count: int) -> void:
	var cols := [Color("#E8403A"), Color("#FFB030"), Color("#4FA8E8"), Color("#58C060"), Color("#B85AD8"), Color("#FF7AB0"), Color("#F0E050")]
	for i in count:
		var a := -PI / 2.0 + (_r(i) - 0.5) * 2.0 * spread
		var d := 24.0 + _r(i + 11) * 22.0
		var sway := sin(t * 1.3 + i) * 1.6
		var top := anchor + Vector2(cos(a) * d * 0.9 + sway, sin(a) * d - 6.0)
		c.draw_line(anchor, top + Vector2(0, 5.2), Color(0.3, 0.3, 0.35, 0.7), 0.4)
		var col: Color = cols[i % cols.size()]
		c.draw_set_transform(top, 0.0, Vector2(0.86, 1.0))
		c.draw_circle(Vector2.ZERO, 5.4, col.darkened(0.15))
		c.draw_circle(Vector2(-0.8, -0.8), 4.4, col)
		c.draw_circle(Vector2(-1.8, -2.2), 1.3, Color(1, 1, 1, 0.55))
		c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		c.draw_colored_polygon(PackedVector2Array([top + Vector2(-0.8, 5.2), top + Vector2(0.8, 5.2), top + Vector2(0, 6.4)]), col.darkened(0.3))


static func _little_house(c: CanvasItem, p: Vector2, s: float) -> void:
	c.draw_rect(Rect2(p + Vector2(-13, -16) * s, Vector2(26, 16) * s), Color("#E8B060"))
	c.draw_rect(Rect2(p + Vector2(-13, -16) * s, Vector2(8, 16) * s), Color("#F2C47A"))
	c.draw_colored_polygon(PackedVector2Array([p + Vector2(-16, -16) * s, p + Vector2(16, -16) * s, p + Vector2(0, -30) * s]), Color("#B8403A"))
	c.draw_colored_polygon(PackedVector2Array([p + Vector2(-16, -16) * s, p + Vector2(0, -16) * s, p + Vector2(0, -30) * s]), Color("#D0584A"))
	c.draw_rect(Rect2(p + Vector2(-3, -10) * s, Vector2(6, 10) * s), Color("#4A7AB8"))
	c.draw_rect(Rect2(p + Vector2(-11, -12) * s, Vector2(6, 6) * s), Color("#FFF0B8"))
	c.draw_rect(Rect2(p + Vector2(5, -12) * s, Vector2(6, 6) * s), Color("#FFF0B8"))
	c.draw_rect(Rect2(p + Vector2(-13, -2) * s, Vector2(26, 2) * s), Color("#8A5A3A"))


static func _up(c: CanvasItem, t: float, s: int, u: float, ls: float) -> void:
	match s:
		0:
			# A little house on a green lawn in the morning, a grey city behind it; balloons begin to pour out of it.
			_sky(c, Color("#5AA8E8"), Color("#9AD0F4"), Color("#F4F0D8"), 70.0)
			_cloud(c, Vector2(40.0 + t * 1.2, 22), 1.1, Color(1, 1, 1, 0.95))
			_cloud(c, Vector2(150.0 + t * 0.8, 34), 0.9, Color(1, 1, 1, 0.9))
			for i in 9:
				var h := 18.0 + _r(i) * 22.0
				c.draw_rect(Rect2(i * 24.0 - 6.0, 78 - h, 22, h), Color("#9AA8C0").lerp(Color("#C8D4E4"), 0.4))
				for w in 3:
					c.draw_rect(Rect2(i * 24.0 - 2.0 + w * 6.0, 82 - h, 3, 3), Color("#E8F0FA"))
			_hills(c, 78.0, 4.0, 0.05, 1.0, Color("#7AC060"), Color("#3E8E3A"))
			for i in 12:
				c.draw_line(Vector2(10.0 + i * 16.0, 94), Vector2(10.0 + i * 16.0 + sin(t * 2.0 + i) * 1.2, 90), Color("#9AD870"), 0.8)
			_little_house(c, Vector2(98, 92), 1.6)
			var n := int(clampf(u * 1.4, 0.0, 1.0) * 40.0)
			_balloons(c, Vector2(98, 62), t, 1.0, n)
		1:
			# The house floats up through the clouds under a thousand balloons.
			var lift := u * 40.0
			_sky(c, Color("#3A86D8"), Color("#8AC4F0"), Color("#E8F4FC"), 80.0)
			for i in 7:
				var cy := fposmod(10.0 + i * 24.0 + lift, 130.0) - 14.0
				_cloud(c, Vector2(fposmod(_r(i) * 260.0 + t * (1.0 + i * 0.2), 240.0) - 20.0, cy), 1.0 + (i % 3) * 0.3, Color(1, 1, 1, 0.92))
			var hp := Vector2(98, 90 - sin(t * 1.0) * 1.6)
			_balloons(c, hp + Vector2(0, -28), t, 1.0, 80)
			_little_house(c, hp, 1.4)
			c.draw_circle(hp + Vector2(0, -2), 1.0, Color(0, 0, 0, 0))
		2:
			# Over a canyon: red cliffs, a flat-topped mountain with a waterfall falling from its edge into mist.
			_sky(c, Color("#4A96E0"), Color("#9AD0F4"), Color("#FCEBC8"), 72.0)
			_cloud(c, Vector2(30.0 + t * 1.0, 24), 1.0, Color(1, 1, 1, 0.9))
			c.draw_polygon(PackedVector2Array([Vector2(110, 80), Vector2(114, 30), Vector2(176, 30), Vector2(184, 80)]), PackedColorArray([Color("#C8683A"), Color("#C8683A"), Color("#9A4A2A"), Color("#9A4A2A")]))
			c.draw_rect(Rect2(114, 26, 62, 6), Color("#58A044"))
			c.draw_polygon(PackedVector2Array([Vector2(140, 32), Vector2(150, 32), Vector2(152, 80), Vector2(138, 80)]), PackedColorArray([Color("#F4FCFF"), Color("#F4FCFF"), Color("#B8E4F4"), Color("#B8E4F4")]))
			for i in 7:
				var y := fposmod(t * 30.0 + i * 8.0, 48.0)
				c.draw_line(Vector2(143.0 + (i % 3) * 2.4, 32.0 + y), Vector2(143.0 + (i % 3) * 2.4, 36.0 + y), Color.WHITE, 0.8)
			c.draw_polygon(PackedVector2Array([Vector2(0, 54), Vector2(46, 62), Vector2(60, SIZE.y), Vector2(0, SIZE.y)]), PackedColorArray([Color("#B85A32"), Color("#A04A2A"), Color("#6A2E1A"), Color("#8A3E22")]))
			for i in 5:
				_cloud(c, Vector2(110.0 + i * 20.0, 86.0 + (i % 2) * 4.0), 1.3, Color(1, 1, 1, 0.8))
			var hp := Vector2(lerpf(40.0, 100.0, u), 54.0 - sin(t * 1.0) * 1.8 - u * 6.0)
			_balloons(c, hp + Vector2(0, -22), t, 1.0, 60)
			_little_house(c, hp, 1.1)
		_:
			# Evening at the foot of the falls: the house has landed, two chairs on the porch, the balloons going up one by one.
			var k := clampf(u * 1.3, 0.0, 1.0)
			_sky(c, Color("#4A4A9A"), Color("#E87A6A"), Color("#FFC878"), 70.0)
			_glow(c, Vector2(40, 70), 56.0, Color(1.0, 0.7, 0.4, 0.25))
			c.draw_circle(Vector2(40, 70), 10.0, Color("#FFE0A0"))
			c.draw_polygon(PackedVector2Array([Vector2(130, 0), Vector2(150, 0), Vector2(154, 76), Vector2(126, 76)]), PackedColorArray([Color("#FFEACF"), Color("#FFEACF"), Color("#F8B898"), Color("#F8B898")]))
			for i in 8:
				var y := fposmod(t * 36.0 + i * 11.0, 76.0)
				c.draw_line(Vector2(133.0 + i * 2.2, y), Vector2(133.0 + i * 2.2, y + 6.0), Color(1, 1, 1, 0.7), 0.8)
			_cloud(c, Vector2(140, 80), 2.0, Color(1, 0.9, 0.9, 0.7))
			_hills(c, 84.0, 3.0, 0.06, 2.0, Color("#4E8A40"), Color("#2A5A28"))
			_little_house(c, Vector2(80, 98), 1.7)
			for cx in [58.0, 70.0]:
				c.draw_rect(Rect2(cx, 90, 7, 2), Color("#5A3A28"))
				c.draw_rect(Rect2(cx, 84, 2, 6), Color("#5A3A28"))
			var left := int((1.0 - k) * 14.0)
			for i in left:
				var rise := fposmod(ls * 3.0 + i * 5.0, 60.0)
				_balloons(c, Vector2(80, 70), t, 1.2, 1)
				c.draw_circle(Vector2(30.0 + i * 11.0, 60.0 - rise), 3.6, [Color("#E8403A"), Color("#FFB030"), Color("#4FA8E8")][i % 3])
			for i in 14:
				var a := t * 0.4 + i * 1.7
				c.draw_circle(Vector2(fposmod(_r(i) * 220.0 + a * 4.0, 200.0), 12.0 + _r(i + 3) * 40.0), 0.6, Color(1, 1, 0.9, 0.5 + 0.4 * sin(t * 3.0 + i)))


# ══════════════════════════════════════════════════════════════
#  Mon voisin Totoro
# ══════════════════════════════════════════════════════════════

static func _umbrella(c: CanvasItem, p: Vector2, s: float, col: Color) -> void:
	c.draw_line(p, p + Vector2(0, 22) * s, Color("#4A3A2A"), 1.2 * s)
	c.draw_colored_polygon(PackedVector2Array([p + Vector2(-16, 0) * s, p + Vector2(-12, -8) * s, p + Vector2(0, -12) * s, p + Vector2(12, -8) * s, p + Vector2(16, 0) * s, p + Vector2(8, -2) * s, p + Vector2(0, 0) * s, p + Vector2(-8, -2) * s]), col)
	c.draw_colored_polygon(PackedVector2Array([p + Vector2(-16, 0) * s, p + Vector2(-12, -8) * s, p + Vector2(0, -12) * s, p + Vector2(-2, -3) * s]), col.lightened(0.15))


static func _forest_spirit(c: CanvasItem, p: Vector2, s: float, t: float) -> void:
	# A big round grey-blue creature, a pale belly with chevrons, tall ears, whiskers, a wide smile.
	c.draw_circle(p + Vector2(2, 4) * s, 22.0 * s, Color(0, 0, 0, 0.18))
	c.draw_circle(p, 21.0 * s, Color("#7A8AA0"))
	c.draw_circle(p + Vector2(-5, -6) * s, 14.0 * s, Color("#8E9EB4"))
	c.draw_circle(p + Vector2(0, 5) * s, 14.0 * s, Color("#E8E4D4"))
	for i in 3:
		c.draw_arc(p + Vector2(-5.0 + i * 5.0, 6) * s, 2.2 * s, PI * 1.1, PI * 1.9, 6, Color("#7A8AA0"), 0.8 * s)
	for ex in [-8.0, 8.0]:
		c.draw_colored_polygon(PackedVector2Array([p + Vector2(ex - 3.4, -17) * s, p + Vector2(ex + 3.4, -17) * s, p + Vector2(ex * 0.9, -30) * s]), Color("#6E7E94"))
	for ex in [-9.0, 9.0]:
		c.draw_circle(p + Vector2(ex, -8) * s, 2.8 * s, Color.WHITE)
		c.draw_circle(p + Vector2(ex * 0.88, -8) * s, 1.1 * s, Color("#14141C"))
	c.draw_colored_polygon(PackedVector2Array([p + Vector2(-2, -6) * s, p + Vector2(2, -6) * s, p + Vector2(0, -4) * s]), Color("#2A2A34"))
	c.draw_arc(p + Vector2(0, -6) * s, 11.0 * s, 0.2, PI - 0.2, 10, Color("#2A2A34"), 1.0 * s)
	for sd in [-1.0, 1.0]:
		for k in 3:
			c.draw_line(p + Vector2(sd * 11.0, -4.0 + k * 1.6) * s, p + Vector2(sd * (22.0 + k), -6.0 + k * 3.0 + sin(t * 2.0) * 0.4) * s, Color(1, 1, 1, 0.6), 0.5 * s)


static func _totoro(c: CanvasItem, t: float, s: int, u: float, ls: float) -> void:
	match s:
		0:
			# A rainy dusk at a country bus stop: a girl with a yellow umbrella waits; the big furry spirit appears beside her.
			_sky(c, Color("#2A3A4E"), Color("#4A5E70"), Color("#8A9AA0"), 76.0)
			for i in 3:
				_pine(c, Vector2(20.0 + i * 70.0, 82), 1.6, Color("#1E3A2E"), false)
			_hills(c, 82.0, 2.0, 0.05, 0.0, Color("#3E5A3A"), Color("#243A24"))
			c.draw_polygon(PackedVector2Array([Vector2(0, 90), Vector2(SIZE.x, 90), Vector2(SIZE.x, SIZE.y), Vector2(0, SIZE.y)]), PackedColorArray([Color("#5A5A50"), Color("#5A5A50"), Color("#3A3A34"), Color("#3A3A34")]))
			c.draw_rect(Rect2(150, 54, 2, 40), Color("#6A5A4A"))
			c.draw_rect(Rect2(142, 52, 18, 9), Color("#C84A3A"))
			c.draw_rect(Rect2(144, 54, 14, 3), Color("#F4E6B0"))
			c.draw_circle(Vector2(150, 40), 0.1, Color(0, 0, 0, 0))
			_glow(c, Vector2(151, 50), 22.0, Color(1.0, 0.85, 0.5, 0.18))
			var gx := 100.0
			c.draw_rect(Rect2(gx - 3, 74, 6, 16), Color("#C84A5A"))
			c.draw_circle(Vector2(gx, 70), 4.0, Color("#E8B88A"))
			c.draw_circle(Vector2(gx, 67), 4.4, Color("#3A2418"))
			c.draw_line(Vector2(gx - 2, 90), Vector2(gx - 2, 96), Color("#E8B88A"), 1.4)
			c.draw_line(Vector2(gx + 2, 90), Vector2(gx + 2, 96), Color("#E8B88A"), 1.4)
			_umbrella(c, Vector2(gx, 66), 1.1, Color("#F0C030"))
			var pop := ease(clampf((u - 0.3) * 2.0, 0.0, 1.0), 0.5)
			if pop > 0.0:
				_forest_spirit(c, Vector2(122, 100 - pop * 18.0), 1.1 * pop, t)
			for i in 44:
				var x := fposmod(_r(i) * 300.0 + t * 8.0, 220.0) - 12.0
				var y := fposmod(_r(i + 7) * 200.0 + t * 90.0, 118.0) - 4.0
				c.draw_line(Vector2(x, y), Vector2(x - 1.6, y + 4.4), Color(0.85, 0.92, 1.0, 0.5), 0.6)
		1:
			# Deep in the woods: a giant camphor tree, a hollow of dark leaves, sunbeams, dust, little round soot-spirits.
			_grad(c, Rect2(0, 0, SIZE.x, SIZE.y), Color("#7AB070"), Color("#183A22"))
			for i in 5:
				var x := 20.0 + i * 38.0
				c.draw_polygon(PackedVector2Array([Vector2(x - 6, 0), Vector2(x + 6, 0), Vector2(x + 10, 60), Vector2(x - 10, 60)]), PackedColorArray([Color("#2E4A2A"), Color("#2E4A2A"), Color("#1A3020"), Color("#1A3020")]))
			c.draw_polygon(PackedVector2Array([Vector2(70, 108), Vector2(84, 44), Vector2(112, 44), Vector2(126, 108)]), PackedColorArray([Color("#5A4030"), Color("#4A3426"), Color("#3A281C"), Color("#3A281C")]))
			c.draw_circle(Vector2(98, 20), 40.0, Color("#2E6E3A"))
			c.draw_circle(Vector2(78, 14), 28.0, Color("#3E8E48"))
			c.draw_circle(Vector2(122, 18), 26.0, Color("#3A8A46"))
			c.draw_circle(Vector2(96, 4), 20.0, Color("#58AA58"))
			c.draw_circle(Vector2(98, 78), 11.0, Color("#0E1A12"))
			for i in 4:
				var x := 40.0 + i * 36.0
				c.draw_polygon(PackedVector2Array([Vector2(x, 0), Vector2(x + 8, 0), Vector2(x + 34, SIZE.y), Vector2(x + 6, SIZE.y)]), PackedColorArray([Color(1, 1, 0.8, 0.22), Color(1, 1, 0.8, 0.22), Color(1, 1, 0.8, 0.0), Color(1, 1, 0.8, 0.0)]))
			for i in 18:
				var p := Vector2(fposmod(_r(i) * 220.0 + sin(t * 0.5 + i) * 10.0, 200.0), fposmod(_r(i + 5) * 120.0 - t * 4.0, 108.0))
				c.draw_circle(p, 0.7, Color(1, 1, 0.8, 0.6))
			var cx := lerpf(-10.0, 120.0, u)
			for i in 5:
				var sp := Vector2(cx - i * 9.0, 98.0 + sin(t * 8.0 + i) * 1.2)
				c.draw_circle(sp, 3.0, Color("#14141C"))
				c.draw_circle(sp + Vector2(-1, -0.6), 0.9, Color.WHITE)
				c.draw_circle(sp + Vector2(1, -0.6), 0.9, Color.WHITE)
			_grad(c, Rect2(0, 100, SIZE.x, 8), Color(0.1, 0.2, 0.1, 0.0), Color(0.05, 0.12, 0.06, 0.6))
		2:
			# A moonlit night over the fields: the big spirit spins like a top on the grass, the little ones whirling; the trees lean in the wind.
			_sky(c, Color("#0A1438"), Color("#1E3A6A"), Color("#4A6A9A"), 70.0)
			_stars(c, t, 44, 44.0)
			c.draw_circle(Vector2(150, 26), 14.0, Color("#FFF6D6"))
			_glow(c, Vector2(150, 26), 40.0, Color(0.9, 0.95, 1.0, 0.16))
			_hills(c, 76.0, 4.0, 0.05, 1.0, Color("#244A3A"), Color("#122A22"))
			_hills(c, 88.0, 3.0, 0.08, 3.0, Color("#2E6040"), Color("#163A28"))
			for i in 24:
				var y := 90.0 + (i % 3) * 5.0
				var x := fposmod(i * 9.0 - t * 14.0, 215.0) - 10.0
				c.draw_line(Vector2(x, y), Vector2(x + 2.0, y - 4.0 + sin(t * 3.0 + i) * 1.0), Color("#8AD070"), 0.8)
			var sp := Vector2(100, 70 - sin(t * 1.5) * 4.0)
			c.draw_circle(sp, 24.0, Color(0.9, 1.0, 1.0, 0.07))
			_forest_spirit(c, sp, 0.9, t)
			c.draw_line(sp + Vector2(0, -30), sp + Vector2(0, -42), Color("#4A3A2A"), 1.0)
			_umbrella(c, sp + Vector2(0, -34), 0.9, Color("#3E7A4A"))
			for i in 8:
				var a := t * 1.4 + i * 0.8
				var q := sp + Vector2(cos(a) * 44.0, sin(a) * 12.0 + 14.0)
				c.draw_circle(q, 2.4, Color(1.0, 0.95, 0.7, 0.9))
				c.draw_circle(q, 5.0, Color(1.0, 0.95, 0.7, 0.2))
		_:
			# Morning: seedlings have sprouted in the garden, a big grin of sun, the girl and her umbrella-leaf, the great tree behind.
			_sky(c, Color("#5AA8E8"), Color("#B8E0F4"), Color("#FFF2C8"), 70.0)
			_glow(c, Vector2(40, 22), 50.0, Color(1.0, 0.95, 0.6, 0.3))
			c.draw_circle(Vector2(40, 22), 9.0, Color("#FFF2B0"))
			_cloud(c, Vector2(120.0 + t * 1.0, 24), 1.2, Color(1, 1, 1, 0.95))
			c.draw_circle(Vector2(162, 52), 26.0, Color("#3E8E48"))
			c.draw_circle(Vector2(150, 44), 16.0, Color("#58AA58"))
			c.draw_polygon(PackedVector2Array([Vector2(154, 96), Vector2(158, 62), Vector2(168, 62), Vector2(172, 96)]), PackedColorArray([Color("#5A4030"), Color("#4A3426"), Color("#3A281C"), Color("#3A281C")]))
			_hills(c, 84.0, 3.0, 0.05, 0.5, Color("#7AC060"), Color("#3E8E3A"))
			var grow := ease(clampf(u * 1.4, 0.0, 1.0), 0.5)
			for i in 7:
				var x := 20.0 + i * 16.0
				var h := (6.0 + (i % 3) * 3.0) * grow
				c.draw_line(Vector2(x, 100), Vector2(x, 100 - h), Color("#4E9A3A"), 1.2)
				c.draw_colored_polygon(PackedVector2Array([Vector2(x, 100 - h), Vector2(x - 3.4, 100 - h - 2.0), Vector2(x - 1.0, 100 - h + 1.4)]), Color("#7AD060"))
				c.draw_colored_polygon(PackedVector2Array([Vector2(x, 100 - h), Vector2(x + 3.4, 100 - h - 2.0), Vector2(x + 1.0, 100 - h + 1.4)]), Color("#7AD060"))
			var gx := 100.0
			c.draw_rect(Rect2(gx - 3, 78, 6, 14), Color("#C84A5A"))
			c.draw_circle(Vector2(gx, 74), 4.0, Color("#E8B88A"))
			c.draw_circle(Vector2(gx, 71), 4.4, Color("#3A2418"))
			c.draw_line(Vector2(gx - 2, 92), Vector2(gx - 2, 98), Color("#E8B88A"), 1.4)
			c.draw_line(Vector2(gx + 2, 92), Vector2(gx + 2, 98), Color("#E8B88A"), 1.4)
			c.draw_line(Vector2(gx + 3, 80), Vector2(gx + 9, 74 + sin(t * 3.0) * 2.0), Color("#E8B88A"), 1.4)
			if u > 0.5:
				for i in 5:
					var a := ls * 2.0 + i * 1.3
					c.draw_circle(Vector2(gx + 18.0 + sin(a) * 10.0, 60.0 - fposmod(ls * 6.0 + i * 5.0, 22.0)), 1.1, Color(1, 0.45, 0.55, 0.9))
