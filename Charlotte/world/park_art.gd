class_name ParkArt
extends RefCounted
## Everything in the Parc du Pélican (`scenes/parc_pelican.gd`), drawn on any CanvasItem, feet on y = 0 unless said otherwise.
## The park is the city's real one (2590 rue Masson, between 1re Avenue and rue Molson, montreal.ca/lieux/parc-du-pelican): a
## chalet near Masson, a wading pool for the under-tens, a big outdoor swimming pool, playgrounds, a dog park, a basketball
## court and ping-pong tables, a sliding hill and, in winter, a hockey rink and a free-skating rink. Ground features (pools,
## rinks, courts, the safety surface) lie FLAT on the ground, drawn squashed by the view like the schoolyard's hopscotch
## (`flat`), so Charlotte walks in front of them; tall ones (the chalet, the slide, the lifeguard's chair) stand on their feet.
## Light from the upper left, like the rest of the game. **A new piece = one more static function here and a line in
## `ParkScene._build_pieces`.**

const IRON := Color("#2B2F33")
const LINE := Color("#3A3A48")
const FLAT := 0.22

# ── The season ──────────────────────────────────────────────────

static func winter() -> bool:
	return Season.is_winter()


static func lawn() -> Color:
	return {"winter": Color("#EEF3F8"), "spring": Color("#86B561"), "summer": Color("#5E9A44")}.get(Season.current, Color("#98A55A"))


static func lawn_dark() -> Color:
	return lawn().darkened(0.12)


## Snow on a flat top: a white cap `w` wide, `thick` tall, on the line y.
static func snow_cap(ci: CanvasItem, x: float, y: float, w: float, thick: float) -> void:
	if not winter():
		return
	ci.draw_rect(Rect2(x, y - thick, w, thick), Color("#F6F9FC"))
	ci.draw_rect(Rect2(x, y - thick, w, 2.0), Color.WHITE)


## An ellipse on the ground plane (a pool, a rink): `c` its middle, `r` its half width.
static func flat(ci: CanvasItem, c: Vector2, r: float, col: Color) -> void:
	ci.draw_set_transform(c, 0.0, Vector2(1.0, FLAT))
	ci.draw_circle(Vector2.ZERO, r, col)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


static func flat_rect(ci: CanvasItem, r: Rect2, col: Color, depth := 0.0) -> void:
	# A rectangle on the ground plane: `r.size.y` is its depth in ground units, squashed by the view.
	var h := r.size.y * FLAT
	ci.draw_rect(Rect2(r.position, Vector2(r.size.x, h)), col)
	if depth > 0.0:
		ci.draw_rect(Rect2(r.position + Vector2(0, h), Vector2(r.size.x, depth)), col.darkened(0.25))


# ── Fences, benches, signs ──────────────────────────────────────

## A chain-link fence from x0 to x1, its foot on y, `h` tall, with a gap for a gate (`gate_at`, `gate_w`; gate_w 0 = none).
static func chain_fence(ci: CanvasItem, x0: float, x1: float, y: float, h: float, gate_at := -1.0, gate_w := 0.0, alpha := 0.5) -> void:
	var mesh := Color(0.55, 0.6, 0.65, alpha)
	var x := x0
	while x < x1:
		var gap := gate_w > 0.0 and x >= gate_at and x < gate_at + gate_w
		if not gap:
			var xe := minf(x + 26.0, x1)
			var k := 0.0
			while k < xe - x:
				ci.draw_line(Vector2(x + k, y - h), Vector2(x + k + 13.0, y), mesh, 1.0)
				ci.draw_line(Vector2(x + k + 13.0, y - h), Vector2(x + k, y), mesh, 1.0)
				k += 13.0
		x += 26.0
	ci.draw_line(Vector2(x0, y - h), Vector2(gate_at if gate_w > 0.0 else x1, y - h), IRON, 3.0)
	if gate_w > 0.0:
		ci.draw_line(Vector2(gate_at + gate_w, y - h), Vector2(x1, y - h), IRON, 3.0)
		for gx: float in [gate_at, gate_at + gate_w]:
			ci.draw_rect(Rect2(gx - 3.0, y - h - 6.0, 6.0, h + 6.0), IRON)
	var px := x0
	while px <= x1:
		if not (gate_w > 0.0 and px > gate_at and px < gate_at + gate_w):
			ci.draw_rect(Rect2(px - 2.0, y - h - 2.0, 4.0, h + 2.0), IRON)
		px += 130.0
	snow_cap(ci, x0, y - h, (x1 - x0), 4.0)


## A low iron fence, bars and a rail (the front of the park, the pools' decks).
static func iron_fence(ci: CanvasItem, x0: float, x1: float, y: float, h: float) -> void:
	var x := x0
	while x <= x1:
		ci.draw_rect(Rect2(x - 1.5, y - h, 3.0, h), IRON)
		x += 18.0
	ci.draw_rect(Rect2(x0, y - h, x1 - x0, 4.0), IRON)
	ci.draw_rect(Rect2(x0, y - h * 0.4, x1 - x0, 3.0), IRON)
	snow_cap(ci, x0, y - h, x1 - x0, 4.0)


## A park bench: wooden slats on cast-iron ends.
static func bench(ci: CanvasItem, x: float, y: float, w := 110.0) -> void:
	for lx: float in [x + 8.0, x + w - 14.0]:
		ci.draw_rect(Rect2(lx, y - 52.0, 6.0, 52.0), IRON)
	ci.draw_rect(Rect2(x, y - 38.0, w, 8.0), Color("#8A5A32"))
	ci.draw_rect(Rect2(x, y - 38.0, w, 2.5), Color("#B07A48"))
	ci.draw_rect(Rect2(x, y - 66.0, w, 7.0), Color("#8A5A32"))
	ci.draw_rect(Rect2(x, y - 54.0, w, 7.0), Color("#8A5A32"))
	snow_cap(ci, x, y - 66.0, w, 5.0)


static func lamp(ci: CanvasItem, x: float, y: float) -> void:
	ci.draw_rect(Rect2(x - 3.0, y - 250.0, 6.0, 250.0), Color("#3A4A42"))
	ci.draw_rect(Rect2(x - 7.0, y - 12.0, 14.0, 12.0), Color("#3A4A42"))
	ci.draw_line(Vector2(x, y - 248.0), Vector2(x + 34.0, y - 258.0), Color("#3A4A42"), 5.0)
	ci.draw_colored_polygon(PackedVector2Array([Vector2(x + 22.0, y - 264.0), Vector2(x + 52.0, y - 264.0), Vector2(x + 46.0, y - 250.0), Vector2(x + 28.0, y - 250.0)]), Color("#2E3A34"))
	ci.draw_circle(Vector2(x + 37.0, y - 247.0), 5.0, Color("#FFF3C2"))


static func trash_bin(ci: CanvasItem, x: float, y: float) -> void:
	ci.draw_rect(Rect2(x - 14.0, y - 50.0, 28.0, 50.0), Color("#3E6A4E"))
	ci.draw_rect(Rect2(x - 16.0, y - 54.0, 32.0, 6.0), Color("#2A4A36"))
	for k in 4:
		ci.draw_line(Vector2(x - 12.0 + k * 8.0, y - 44.0), Vector2(x - 12.0 + k * 8.0, y - 6.0), Color(0, 0, 0, 0.25), 1.5)
	snow_cap(ci, x - 16.0, y - 54.0, 32.0, 4.0)


static func drinking_fountain(ci: CanvasItem, x: float, y: float) -> void:
	ci.draw_rect(Rect2(x - 7.0, y - 56.0, 14.0, 56.0), Color("#8C9096"))
	ci.draw_rect(Rect2(x - 16.0, y - 62.0, 32.0, 10.0), Color("#A9ADB3"))
	ci.draw_rect(Rect2(x - 4.0, y - 68.0, 8.0, 8.0), Color("#6E7278"))
	ci.draw_rect(Rect2(x - 14.0, y - 4.0, 28.0, 4.0), Color("#6E7278"))
	snow_cap(ci, x - 16.0, y - 62.0, 32.0, 3.0)


## A green park sign on two posts (the words go on as a label over it).
static func sign_board(ci: CanvasItem, x: float, y: float, w: float, h: float) -> void:
	for px: float in [x + 10.0, x + w - 14.0]:
		ci.draw_rect(Rect2(px, y - h - 40.0, 5.0, h + 40.0), Color("#4A4A4A"))
	ci.draw_rect(Rect2(x, y - h - 40.0, w, h), Color("#2E6B4C"))
	ci.draw_rect(Rect2(x + 4.0, y - h - 36.0, w - 8.0, h - 8.0), Color("#2E6B4C"), false, 2.0)
	ci.draw_rect(Rect2(x + 5.0, y - h - 35.0, w - 10.0, 4.0), Color(1, 1, 1, 0.18))
	snow_cap(ci, x, y - h - 40.0, w, 6.0)


# ── The chalet ──────────────────────────────────────────────────

## The chalet by Masson, long and low: pale grey stone block, a flat dark roof with its overhang, green doors, small high windows.
static func chalet(ci: CanvasItem, x: float, y: float, w: float) -> void:
	var h := 150.0
	ci.draw_rect(Rect2(x + 8.0, y - 4.0, w, 10.0), Color(0, 0, 0, 0.18))
	ci.draw_rect(Rect2(x, y - h, w, h), Color("#B3AFA6"))
	# Courses of block, faint.
	var by := y - h + 18.0
	while by < y - 4.0:
		ci.draw_line(Vector2(x, by), Vector2(x + w, by), Color(0, 0, 0, 0.1), 1.0)
		by += 18.0
	ci.draw_rect(Rect2(x, y - 16.0, w, 16.0), Color("#8E8B84"))
	ci.draw_rect(Rect2(x, y - h, w, 8.0), Color(1, 1, 1, 0.12))
	# The roof's overhang, dark, with its green fascia.
	ci.draw_rect(Rect2(x - 22.0, y - h - 20.0, w + 44.0, 20.0), Color("#3A4A42"))
	ci.draw_rect(Rect2(x - 22.0, y - h - 20.0, w + 44.0, 5.0), Color("#56695F"))
	snow_cap(ci, x - 22.0, y - h - 20.0, w + 44.0, 14.0)
	# Three green doors and, between them, a notice board and high windows.
	var gap := w / 4.0
	for k in 3:
		var dx := x + gap * (k + 0.5) + 10.0
		ci.draw_rect(Rect2(dx - 24.0, y - 104.0, 48.0, 104.0), Color("#2F6B4F"))
		ci.draw_rect(Rect2(dx - 24.0, y - 104.0, 48.0, 104.0), Color("#1F4A36"), false, 2.5)
		ci.draw_rect(Rect2(dx - 14.0, y - 92.0, 28.0, 30.0), Color("#8FB8C8", 0.8))
		ci.draw_rect(Rect2(dx + 12.0, y - 52.0, 5.0, 12.0), Color("#C9C9C9"))
		ci.draw_rect(Rect2(dx - 28.0, y - 118.0, 56.0, 8.0), Color(0, 0, 0, 0.12))
	for k in 2:
		var wx := x + gap * (k + 1.0) + 10.0
		ci.draw_rect(Rect2(wx - 26.0, y - 124.0, 52.0, 22.0), Color("#7E9AA8"))
		for g in 4:
			ci.draw_line(Vector2(wx - 26.0 + g * 13.0, y - 124.0), Vector2(wx - 26.0 + g * 13.0, y - 102.0), Color("#3A3A48", 0.6), 1.5)
		ci.draw_rect(Rect2(wx - 26.0, y - 124.0, 52.0, 22.0), Color("#3A3A48"), false, 2.0)
	# A wall lantern by each end door.
	for lx: float in [x + 18.0, x + w - 18.0]:
		ci.draw_rect(Rect2(lx - 4.0, y - 108.0, 8.0, 14.0), Color("#2B2F33"))
		ci.draw_circle(Vector2(lx, y - 101.0), 3.0, Color("#FFE9A8"))


## The hedge in front of the chalet (red in autumn, as on the photographs), a row of clipped shrubs.
static func hedge(ci: CanvasItem, x: float, y: float, w: float) -> void:
	var col: Color = {"winter": Color("#8A7A6A"), "spring": Color("#5E9A4A"), "summer": Color("#3E7A3A")}.get(Season.current, Color("#A8442E"))
	var rng := RandomNumberGenerator.new()
	rng.seed = int(x)
	var px := x
	while px < x + w:
		var r := rng.randf_range(13.0, 19.0)
		ci.draw_circle(Vector2(px, y - r * 0.8), r, col.darkened(0.15))
		ci.draw_circle(Vector2(px - 5.0, y - r), r * 0.7, col)
		ci.draw_circle(Vector2(px - 8.0, y - r * 1.15), r * 0.35, col.lightened(0.2))
		px += 26.0
	snow_cap(ci, x - 20.0, y - 30.0, w + 40.0, 7.0)


# ── The wading pool, the swimming pool, the rink ────────────────

## The wading pool (pataugeoire): a round shallow pool on the ground, a mushroom of water in the middle in summer. Closed out of
## season: a tarp in autumn, a puddled empty basin in spring, snow in winter. `t` runs the water.
static func wading_pool(ci: CanvasItem, c: Vector2, r: float, t: float) -> void:
	flat(ci, c + Vector2(0, 4.0), r + 40.0, Color("#CFCBC2"))
	flat(ci, c, r + 24.0, Color("#B9B5AC"))
	flat(ci, c, r + 12.0, Color("#E6E2D8"))
	var inner := r
	if winter():
		flat(ci, c, inner, Color("#F6F9FC"))
		flat(ci, c + Vector2(-r * 0.2, -2.0), inner * 0.7, Color("#FFFFFF"))
		return
	match Season.current:
		"summer":
			flat(ci, c, inner, Color("#5FC4DE"))
			flat(ci, c + Vector2(-r * 0.12, -3.0), inner * 0.82, Color("#7DD6EA"))
			flat(ci, c + Vector2(-r * 0.2, -5.0), inner * 0.5, Color("#A8E6F2"))
			for k in 9:
				var a := TAU * k / 9.0 + t * 0.4
				var p := c + Vector2(cos(a) * inner * 0.7, sin(a) * inner * 0.7 * FLAT)
				ci.draw_arc(p, 7.0 + 3.0 * sin(t * 2.0 + k), PI * 1.1, PI * 1.9, 8, Color(1, 1, 1, 0.5), 1.6, true)
		"autumn":
			flat(ci, c, inner, Color("#5E7184"))
			flat(ci, c + Vector2(-r * 0.2, -3.0), inner * 0.6, Color("#70859A"))
			for k in 14:
				var a := float(k) * 2.4
				ci.draw_circle(c + Vector2(cos(a) * inner * 0.8, sin(a) * inner * 0.8 * FLAT), 3.0, [Color("#D9682B"), Color("#E3A33A"), Color("#B5442E")][k % 3])
		_:
			flat(ci, c, inner, Color("#C9D3DA"))
			flat(ci, c + Vector2(r * 0.15, 2.0), inner * 0.35, Color("#9EB8C9"))
	ci.draw_set_transform(c, 0.0, Vector2(1.0, FLAT))
	ci.draw_arc(Vector2.ZERO, r + 12.0, 0.0, TAU, 48, Color(1, 1, 1, 0.45), 3.0, true)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## The water mushroom standing in the wading pool, its drops falling off the cap (summer only).
static func water_mushroom(ci: CanvasItem, x: float, y: float, t: float) -> void:
	ci.draw_rect(Rect2(x - 7.0, y - 96.0, 14.0, 96.0), Color("#D9534F"))
	ci.draw_rect(Rect2(x - 7.0, y - 96.0, 5.0, 96.0), Color(1, 1, 1, 0.25))
	var cap := PackedVector2Array()
	for k in 21:
		var a := PI + PI * k / 20.0
		cap.append(Vector2(x + cos(a) * 54.0, y - 96.0 + sin(a) * 28.0))
	ci.draw_colored_polygon(cap, Color("#FFC21A"))
	ci.draw_polyline(cap, Color("#C98A00"), 2.0, true)
	ci.draw_circle(Vector2(x - 20.0, y - 112.0), 7.0, Color(1, 1, 1, 0.45))
	if winter() or Season.current != "summer":
		return
	for k in 18:
		var phase := fmod(t * 0.9 + k * 0.17, 1.0)
		var side := -1.0 if k % 2 == 0 else 1.0
		var spread := 22.0 + float(k % 5) * 9.0
		var px := x + side * (50.0 + spread * phase)
		var py := y - 96.0 + 28.0 * phase * phase * 3.4 - 4.0
		if py < y - 2.0:
			ci.draw_circle(Vector2(px, py), 2.4, Color(0.7, 0.9, 1.0, 0.85 * (1.0 - phase * 0.6)))


## The big outdoor pool (piscine extérieure), a rectangle on the ground: blue with lane ropes in summer, a tarp in autumn, drained
## in spring, and in winter a flooded free-skating rink under the same fence. `t` runs the light on the water.
static func swim_pool(ci: CanvasItem, x: float, y: float, w: float, d: float, t: float) -> void:
	var h := d * FLAT
	flat_rect(ci, Rect2(x - 40.0, y - 14.0, w + 80.0, d + 40.0), Color("#D6D2C8"), 6.0)
	var basin := Rect2(x, y, w, h)
	ci.draw_rect(Rect2(basin.position - Vector2(10, 6), basin.size + Vector2(20, 12)), Color("#EEEAE0"))
	if winter():
		ci.draw_rect(basin, Color("#E4F0F8"))
		ci.draw_rect(Rect2(basin.position, Vector2(basin.size.x, basin.size.y * 0.45)), Color(1, 1, 1, 0.55))
		var rng := RandomNumberGenerator.new()
		rng.seed = 41
		for k in 26:
			var sx := x + rng.randf_range(20.0, w - 90.0)
			var sy := y + rng.randf_range(4.0, h - 4.0)
			ci.draw_line(Vector2(sx, sy), Vector2(sx + rng.randf_range(40.0, 110.0), sy + rng.randf_range(-3.0, 3.0)), Color(0.55, 0.68, 0.8, 0.45), 1.2)
		# Low boards round the ice, snow on them.
		ci.draw_rect(Rect2(x - 10.0, y - 12.0, w + 20.0, 6.0), Color("#FFFFFF"))
		ci.draw_rect(Rect2(x - 10.0, y + h + 4.0, w + 20.0, 10.0), Color("#F4F8FC"))
		ci.draw_rect(Rect2(x - 10.0, y + h + 4.0, w + 20.0, 3.0), Color("#C7D5E6"))
		return
	match Season.current:
		"summer":
			ci.draw_rect(basin, Color("#4FB6D6"))
			ci.draw_rect(Rect2(basin.position, Vector2(w, h * 0.5)), Color("#6CCBE4"))
			for k in 14:
				var rx := x + fposmod(k * 83.0 + t * 12.0, w - 30.0) + 10.0
				var ry := y + 4.0 + float((k * 37) % int(maxf(h - 8.0, 1.0)))
				ci.draw_line(Vector2(rx, ry), Vector2(rx + 22.0, ry), Color(1, 1, 1, 0.45 + 0.25 * sin(t * 2.0 + k)), 1.5)
			for l in 3:
				var ly := y + h * (l + 1.0) / 4.0
				ci.draw_line(Vector2(x + 8.0, ly), Vector2(x + w - 8.0, ly), Color(1, 1, 1, 0.5), 1.0)
				var dash := 0
				while dash < int(w / 34.0):
					ci.draw_circle(Vector2(x + dash * 34.0 + 12.0, ly), 3.2, Color("#E04F5F") if dash % 2 == 0 else Color("#FFFFFF"))
					dash += 1
			ci.draw_rect(Rect2(x, y + h - 4.0, w, 4.0), Color(0, 0.2, 0.4, 0.25))
		"autumn":
			ci.draw_rect(basin, Color("#5E7184"))
			ci.draw_rect(Rect2(basin.position, Vector2(w, h * 0.5)), Color("#71869B"))
			for k in 6:
				ci.draw_line(Vector2(x + k * w / 6.0, y), Vector2(x + k * w / 6.0 + 20.0, y + h), Color(0, 0, 0, 0.12), 2.0)
		_:
			ci.draw_rect(basin, Color("#BFD0DA"))
			ci.draw_rect(Rect2(x + w * 0.2, y + h * 0.3, w * 0.25, h * 0.4), Color("#9EB8C9"))
	ci.draw_rect(Rect2(x - 10.0, y - 12.0, w + 20.0, 6.0), Color("#F4F0E6"))
	ci.draw_rect(Rect2(x - 10.0, y + h + 4.0, w + 20.0, 8.0), Color("#C9C5BA"))


## A pool ladder: two steel rails and rungs, standing at the edge.
static func pool_ladder(ci: CanvasItem, x: float, y: float) -> void:
	for dx: float in [-8.0, 8.0]:
		ci.draw_arc(Vector2(x + dx, y - 40.0), 16.0, PI, TAU, 10, Color("#C9D3DC"), 3.0, true)
		ci.draw_line(Vector2(x + dx - 16.0, y - 40.0), Vector2(x + dx - 16.0, y), Color("#C9D3DC"), 3.0)
	for k in 3:
		ci.draw_line(Vector2(x - 24.0, y - 10.0 - k * 12.0), Vector2(x - 8.0, y - 10.0 - k * 12.0), Color("#C9D3DC"), 2.0)


static func lifeguard_chair(ci: CanvasItem, x: float, y: float) -> void:
	ci.draw_colored_polygon(PackedVector2Array([Vector2(x - 28.0, y), Vector2(x - 22.0, y), Vector2(x - 6.0, y - 150.0), Vector2(x - 12.0, y - 150.0)]), Color("#F4F4F4"))
	ci.draw_colored_polygon(PackedVector2Array([Vector2(x + 28.0, y), Vector2(x + 22.0, y), Vector2(x + 6.0, y - 150.0), Vector2(x + 12.0, y - 150.0)]), Color("#F4F4F4"))
	for k in 4:
		var ry := y - 30.0 - k * 30.0
		ci.draw_line(Vector2(x - 22.0 + k * 3.0, ry), Vector2(x + 22.0 - k * 3.0, ry), Color("#E04F5F"), 3.0)
	ci.draw_rect(Rect2(x - 22.0, y - 158.0, 44.0, 10.0), Color("#E04F5F"))
	ci.draw_rect(Rect2(x - 22.0, y - 210.0, 8.0, 54.0), Color("#F4F4F4"))
	ci.draw_rect(Rect2(x - 28.0, y - 222.0, 56.0, 10.0), Color("#E04F5F"))
	ci.draw_rect(Rect2(x - 28.0, y - 222.0, 56.0, 3.0), Color(1, 1, 1, 0.3))
	snow_cap(ci, x - 28.0, y - 222.0, 56.0, 6.0)


static func parasol(ci: CanvasItem, x: float, y: float, col: Color) -> void:
	ci.draw_rect(Rect2(x - 2.0, y - 150.0, 4.0, 150.0), Color("#9A9A9A"))
	var cap := PackedVector2Array([Vector2(x, y - 178.0)])
	for k in 11:
		cap.append(Vector2(x - 70.0 + k * 14.0, y - 150.0 + 6.0 * sin(PI * k / 10.0) * -1.0))
	ci.draw_colored_polygon(cap, col)
	for k in 4:
		ci.draw_colored_polygon(PackedVector2Array([Vector2(x, y - 178.0), Vector2(x - 70.0 + k * 35.0, y - 150.0), Vector2(x - 70.0 + (k + 1) * 35.0, y - 150.0)]), Color.WHITE if k % 2 == 0 else col)
	ci.draw_polyline(PackedVector2Array([Vector2(x - 70.0, y - 150.0), Vector2(x, y - 178.0), Vector2(x + 70.0, y - 150.0)]), col.darkened(0.4), 1.6, true)
	ci.draw_rect(Rect2(x - 22.0, y - 46.0, 44.0, 4.0), Color("#7A5A3A"))
	ci.draw_rect(Rect2(x - 20.0, y - 42.0, 4.0, 42.0), Color("#6E4E2E"))
	ci.draw_rect(Rect2(x + 16.0, y - 42.0, 4.0, 42.0), Color("#6E4E2E"))


# ── The playground ──────────────────────────────────────────────

## The safety surface under the equipment: dark rubber, flat on the ground.
static func rubber_floor(ci: CanvasItem, x: float, y: float, w: float, d: float) -> void:
	var col := Color("#5A6B5A") if not winter() else Color("#E8EEF4")
	flat_rect(ci, Rect2(x, y, w, d), col, 5.0)
	if not winter():
		var rng := RandomNumberGenerator.new()
		rng.seed = int(x)
		for k in 160:
			ci.draw_rect(Rect2(x + rng.randf_range(0.0, w), y + rng.randf_range(0.0, d * FLAT), 3.0, 1.5), Color(1, 1, 1, 0.1))


## The big play structure: a tower with a roof, a slide, a ladder and a bridge to a second small tower.
static func play_structure(ci: CanvasItem, x: float, y: float) -> void:
	var red := Color("#E04F5F")
	var yellow := Color("#FFC21A")
	var blue := Color("#4FA3E0")
	# The little tower and its bridge.
	ci.draw_rect(Rect2(x + 190.0, y - 100.0, 70.0, 100.0), Color(0, 0, 0, 0.1))
	for px: float in [x + 194.0, x + 252.0]:
		ci.draw_rect(Rect2(px, y - 130.0, 8.0, 130.0), blue)
	ci.draw_rect(Rect2(x + 190.0, y - 100.0, 76.0, 8.0), Color("#C98A3A"))
	ci.draw_colored_polygon(PackedVector2Array([Vector2(x + 180.0, y - 130.0), Vector2(x + 228.0, y - 170.0), Vector2(x + 276.0, y - 130.0)]), yellow)
	ci.draw_polyline(PackedVector2Array([Vector2(x + 180.0, y - 130.0), Vector2(x + 228.0, y - 170.0), Vector2(x + 276.0, y - 130.0), Vector2(x + 180.0, y - 130.0)]), Color("#C98A00"), 2.0, true)
	# The main tower: four posts, a deck, panels, a roof.
	for px: float in [x + 10.0, x + 108.0]:
		ci.draw_rect(Rect2(px, y - 170.0, 9.0, 170.0), blue)
	ci.draw_rect(Rect2(x + 6.0, y - 110.0, 118.0, 9.0), Color("#C98A3A"))
	ci.draw_rect(Rect2(x + 19.0, y - 150.0, 90.0, 40.0), Color(0.88, 0.31, 0.37, 0.9))
	ci.draw_rect(Rect2(x + 19.0, y - 150.0, 90.0, 6.0), Color(1, 1, 1, 0.25))
	ci.draw_circle(Vector2(x + 64.0, y - 128.0), 13.0, Color("#8FD0F0"))
	ci.draw_arc(Vector2(x + 64.0, y - 128.0), 13.0, 0.0, TAU, 16, Color("#3A6A8A"), 2.0, true)
	ci.draw_colored_polygon(PackedVector2Array([Vector2(x - 6.0, y - 170.0), Vector2(x + 64.0, y - 222.0), Vector2(x + 134.0, y - 170.0)]), red)
	ci.draw_polyline(PackedVector2Array([Vector2(x - 6.0, y - 170.0), Vector2(x + 64.0, y - 222.0), Vector2(x + 134.0, y - 170.0), Vector2(x - 6.0, y - 170.0)]), Color("#A8283A"), 2.0, true)
	snow_cap(ci, x + 12.0, y - 196.0, 100.0, 4.0)
	# The bridge between them, with its rail.
	ci.draw_rect(Rect2(x + 124.0, y - 104.0, 70.0, 6.0), Color("#C98A3A"))
	ci.draw_line(Vector2(x + 124.0, y - 140.0), Vector2(x + 194.0, y - 140.0), blue, 3.0)
	for k in 6:
		ci.draw_line(Vector2(x + 128.0 + k * 12.0, y - 140.0), Vector2(x + 128.0 + k * 12.0, y - 104.0), blue, 2.0)
	# The slide, off the main tower's left side, down to the ground.
	var slide := PackedVector2Array([Vector2(x + 6.0, y - 106.0), Vector2(x - 20.0, y - 100.0), Vector2(x - 96.0, y - 8.0), Vector2(x - 104.0, y), Vector2(x - 70.0, y), Vector2(x - 6.0, y - 82.0)])
	ci.draw_colored_polygon(slide, Color("#E8EEF2") if not winter() else Color("#F4F8FC"))
	ci.draw_polyline(slide, Color("#8C96A0"), 2.5, true)
	ci.draw_line(Vector2(x - 12.0, y - 104.0), Vector2(x - 100.0, y - 4.0), Color("#FFC21A"), 4.0)
	# The ladder and a climbing wall on the little tower.
	for k in 6:
		ci.draw_line(Vector2(x + 198.0, y - 8.0 - k * 16.0), Vector2(x + 220.0, y - 8.0 - k * 16.0), Color("#C98A3A"), 3.0)
	ci.draw_line(Vector2(x + 198.0, y), Vector2(x + 198.0, y - 100.0), Color("#C98A3A"), 3.0)
	ci.draw_line(Vector2(x + 220.0, y), Vector2(x + 220.0, y - 100.0), Color("#C98A3A"), 3.0)


## A swing set: an A-frame and three swings, which sway (`t`).
static func swing_set(ci: CanvasItem, x: float, y: float, t: float) -> void:
	var top := y - 190.0
	for ex: float in [x, x + 230.0]:
		ci.draw_line(Vector2(ex + 14.0, top), Vector2(ex - 24.0, y), Color("#3E6A9A"), 7.0)
		ci.draw_line(Vector2(ex + 14.0, top), Vector2(ex + 52.0, y), Color("#3E6A9A"), 7.0)
	ci.draw_rect(Rect2(x + 8.0, top - 5.0, 242.0, 10.0), Color("#2E5A8A"))
	snow_cap(ci, x + 8.0, top - 5.0, 242.0, 4.0)
	for k in 3:
		var hx := x + 50.0 + k * 70.0
		var ang := 0.28 * sin(t * 1.3 + k * 1.4) * (0.5 if winter() else 1.0)
		var seat := Vector2(hx, top) + Vector2(sin(ang), cos(ang)) * 132.0
		ci.draw_line(Vector2(hx - 11.0, top), seat + Vector2(-11.0, 0), Color("#6E6E6E"), 1.8)
		ci.draw_line(Vector2(hx + 11.0, top), seat + Vector2(11.0, 0), Color("#6E6E6E"), 1.8)
		ci.draw_rect(Rect2(seat.x - 15.0, seat.y - 1.0, 30.0, 7.0), Color("#222222") if k != 1 else Color("#E04F5F"))
		snow_cap(ci, seat.x - 15.0, seat.y - 1.0, 30.0, 3.0)


static func sandbox(ci: CanvasItem, x: float, y: float, w: float) -> void:
	var d := 64.0
	flat_rect(ci, Rect2(x - 10.0, y, w + 20.0, d), Color("#9A6A3A"), 10.0)
	flat_rect(ci, Rect2(x, y + 2.0, w, d - 8.0), Color("#E8D49A") if not winter() else Color("#F4F8FC"))
	if not winter():
		ci.draw_colored_polygon(PackedVector2Array([Vector2(x + w * 0.6, y + 14.0), Vector2(x + w * 0.6 + 16.0, y + 14.0), Vector2(x + w * 0.6 + 13.0, y + 3.0), Vector2(x + w * 0.6 + 3.0, y + 3.0)]), Color("#E04F5F"))
		ci.draw_circle(Vector2(x + w * 0.25, y + 12.0), 8.0, Color("#D8C078"))


## A spring rider (a seat on a big spring), in a colour.
static func spring_rider(ci: CanvasItem, x: float, y: float, col: Color, t: float) -> void:
	var lean := 0.12 * sin(t * 1.1 + x)
	for k in 5:
		ci.draw_arc(Vector2(x + lean * 40.0 * (k / 5.0), y - 8.0 - k * 7.0), 12.0, 0.0, PI, 8, Color("#8C96A0"), 3.0, true)
	ci.draw_set_transform(Vector2(x + lean * 40.0, y - 50.0), lean, Vector2.ONE)
	ci.draw_circle(Vector2(0, -20.0), 22.0, col)
	ci.draw_rect(Rect2(-6.0, -4.0, 40.0, 6.0), col)
	ci.draw_circle(Vector2(26.0, -34.0), 13.0, col.lightened(0.15))
	ci.draw_circle(Vector2(31.0, -36.0), 2.5, LINE)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


# ── Courts, the rink, ping-pong ─────────────────────────────────

## The basketball court painted on the ground (green and dark), or in winter the hockey rink: white ice, red and blue lines, boards.
static func court(ci: CanvasItem, x: float, y: float, w: float, d: float) -> void:
	var h := d * FLAT
	if winter():
		ci.draw_rect(Rect2(x, y, w, h), Color("#E8F2F8"))
		ci.draw_rect(Rect2(x, y, w, h * 0.4), Color(1, 1, 1, 0.5))
		ci.draw_line(Vector2(x + w * 0.5, y), Vector2(x + w * 0.5, y + h), Color("#D9534F"), 3.0)
		for lx: float in [x + w * 0.33, x + w * 0.67]:
			ci.draw_line(Vector2(lx, y), Vector2(lx, y + h), Color("#4F7FD9"), 3.0)
		ci.draw_arc(Vector2(x + w * 0.5, y + h * 0.5), h * 0.45, 0.0, TAU, 20, Color("#4F7FD9", 0.7), 2.0, true)
		ci.draw_rect(Rect2(x - 8.0, y - 4.0, w + 16.0, 6.0), Color("#F4F8FC"))
		return
	ci.draw_rect(Rect2(x, y, w, h), Color("#4E7E5E"))
	ci.draw_rect(Rect2(x + 10.0, y + 3.0, w - 20.0, h - 6.0), Color("#3E6E9A"))
	ci.draw_rect(Rect2(x + 10.0, y + 3.0, w - 20.0, h - 6.0), Color(1, 1, 1, 0.75), false, 2.5)
	ci.draw_line(Vector2(x + w * 0.5, y + 3.0), Vector2(x + w * 0.5, y + h - 3.0), Color(1, 1, 1, 0.75), 2.5)
	ci.draw_arc(Vector2(x + w * 0.5, y + h * 0.5), h * 0.3, 0.0, TAU, 20, Color(1, 1, 1, 0.75), 2.5, true)
	for hx: float in [x + 10.0, x + w - 10.0]:
		var dir := 1.0 if hx < x + w * 0.5 else -1.0
		ci.draw_rect(Rect2(minf(hx, hx + dir * 52.0), y + h * 0.28, 52.0, h * 0.44), Color(1, 1, 1, 0.75), false, 2.5)


static func basketball_hoop(ci: CanvasItem, x: float, y: float, facing: float) -> void:
	ci.draw_rect(Rect2(x - 4.0, y - 270.0, 8.0, 270.0), Color("#4A5058"))
	ci.draw_rect(Rect2(x + facing * 2.0 - 4.0 + (0.0 if facing > 0.0 else -4.0), y - 288.0, 8.0, 40.0), Color("#4A5058"))
	var bx := x + facing * 30.0
	ci.draw_rect(Rect2(bx - 3.0, y - 296.0, 6.0, 54.0), Color(0.9, 0.95, 1.0, 0.85))
	ci.draw_rect(Rect2(bx - 3.0, y - 296.0, 6.0, 54.0), Color("#8C96A0"), false, 2.0)
	ci.draw_line(Vector2(bx, y - 258.0), Vector2(bx + facing * 26.0, y - 258.0), Color("#E04F5F"), 3.5)
	for k in 5:
		ci.draw_line(Vector2(bx + facing * (3.0 + k * 5.0), y - 257.0), Vector2(bx + facing * (7.0 + k * 3.5), y - 236.0), Color(1, 1, 1, 0.7), 1.2)
	ci.draw_line(Vector2(x, y - 266.0), Vector2(bx, y - 266.0), Color("#4A5058"), 5.0)


## The hockey boards seen from the side, white with a plexiglass top (winter).
static func boards(ci: CanvasItem, x0: float, x1: float, y: float) -> void:
	ci.draw_rect(Rect2(x0, y - 46.0, x1 - x0, 46.0), Color("#F2F4F6"))
	ci.draw_rect(Rect2(x0, y - 46.0, x1 - x0, 5.0), Color("#C7CDD4"))
	ci.draw_rect(Rect2(x0, y - 8.0, x1 - x0, 8.0), Color("#D9534F"))
	ci.draw_rect(Rect2(x0, y - 100.0, x1 - x0, 54.0), Color(0.8, 0.92, 1.0, 0.18))
	var px := x0
	while px <= x1:
		ci.draw_rect(Rect2(px - 1.5, y - 100.0, 3.0, 54.0), Color("#8C96A0"))
		px += 120.0
	ci.draw_rect(Rect2(x0, y - 102.0, x1 - x0, 4.0), Color("#8C96A0"))
	snow_cap(ci, x0, y - 102.0, x1 - x0, 4.0)


static func hockey_net(ci: CanvasItem, x: float, y: float, facing: float) -> void:
	ci.draw_rect(Rect2(x, y - 50.0, 5.0, 50.0), Color("#D9534F"))
	ci.draw_rect(Rect2(x + facing * 40.0, y - 50.0, 5.0, 50.0), Color("#D9534F"))
	ci.draw_rect(Rect2(x, y - 52.0, 45.0, 5.0), Color("#D9534F"))
	for k in 6:
		ci.draw_line(Vector2(x + k * 8.0, y - 48.0), Vector2(x + k * 8.0 + facing * 4.0, y - 4.0), Color(1, 1, 1, 0.5), 1.0)


## A concrete ping-pong table with its steel net, on the pavement.
static func ping_pong(ci: CanvasItem, x: float, y: float) -> void:
	ci.draw_rect(Rect2(x, y - 62.0, 120.0, 10.0), Color("#8E96A0"))
	ci.draw_rect(Rect2(x, y - 62.0, 120.0, 3.0), Color("#B9C0C8"))
	for lx: float in [x + 10.0, x + 100.0]:
		ci.draw_rect(Rect2(lx, y - 52.0, 10.0, 52.0), Color("#7E868F"))
	ci.draw_rect(Rect2(x + 59.0, y - 92.0, 3.0, 32.0), Color("#4A5058"))
	ci.draw_rect(Rect2(x + 59.0, y - 92.0, 3.0, 32.0), Color("#4A5058"))
	ci.draw_line(Vector2(x + 36.0, y - 82.0), Vector2(x + 84.0, y - 82.0), Color("#4A5058"), 2.0)
	snow_cap(ci, x, y - 62.0, 120.0, 5.0)


# ── The hill ────────────────────────────────────────────────────

## How high the sliding hill (butte de glissade) is at `u` from 0 (its foot at the left) to 1 (its foot at the right): a smooth
## mound, steeper on the left where they climb, longer on the right where they slide.
static func hill_height(u: float) -> float:
	if u <= 0.0 or u >= 1.0:
		return 0.0
	var peak := 0.32
	var s := u / peak if u < peak else (1.0 - u) / (1.0 - peak)
	return smoothstep(0.0, 1.0, s) * (1.0 - 0.1 * s) * 250.0


static func hill(ci: CanvasItem, x: float, y: float, w: float) -> void:
	var top := PackedVector2Array()
	var n := 60
	for i in n + 1:
		top.append(Vector2(x + w * i / n, y - hill_height(float(i) / n)))
	var body := top.duplicate()
	body.append(Vector2(x + w, y + 6.0))
	body.append(Vector2(x, y + 6.0))
	var base := Color("#F2F6FA") if winter() else lawn().darkened(0.05)
	ci.draw_colored_polygon(body, base)
	# Light from the left: the long right slope is in shade, fading in over several bands so there is no hard edge.
	for step in 8:
		var from_i := int(n * (0.30 + 0.025 * step))
		var shade := PackedVector2Array()
		for i in range(from_i, n + 1):
			shade.append(top[i])
		shade.append(Vector2(x + w, y + 6.0))
		shade.append(Vector2(x + w * float(from_i) / n, y + 6.0))
		ci.draw_colored_polygon(shade, Color(0.35, 0.45, 0.65, 0.028) if winter() else Color(0, 0.1, 0, 0.026))
	ci.draw_polyline(top, Color.WHITE if winter() else lawn().lightened(0.2), 3.0, true)
	if winter():
		# The worn tracks of the sleds, down the long slope.
		for k in 4:
			var pts := PackedVector2Array()
			for i in range(int(n * 0.34), n):
				var u := float(i) / n
				pts.append(Vector2(x + w * u + k * 7.0 - 12.0, y - hill_height(u) + 5.0 + k * 3.0))
			ci.draw_polyline(pts, Color(0.62, 0.72, 0.85, 0.55), 2.2, true)
	else:
		# The path up the hill and a few tufts.
		var rng := RandomNumberGenerator.new()
		rng.seed = 77
		for k in 40:
			var u := rng.randf_range(0.03, 0.97)
			ci.draw_line(Vector2(x + w * u, y - hill_height(u) + rng.randf_range(6.0, 60.0)), Vector2(x + w * u + 3.0, y - hill_height(u) + rng.randf_range(0.0, 50.0)), lawn().lightened(0.12), 2.0)


## A dog (the dog park): side view, tail wagging with `t`.
static func dog(ci: CanvasItem, p: Vector2, facing: float, t: float, fur: Color) -> void:
	ci.draw_set_transform(p, 0.0, Vector2(facing, 1.0))
	var run := sin(t * 6.0)
	ci.draw_circle(Vector2(0, -26.0), 14.0, fur)
	ci.draw_circle(Vector2(-14.0, -25.0), 12.0, fur)
	ci.draw_circle(Vector2(14.0, -27.0), 13.0, fur)
	for lx: float in [-14.0, 14.0]:
		ci.draw_rect(Rect2(lx - 3.0 + run * 3.0, -18.0, 6.0, 18.0), fur.darkened(0.15))
	ci.draw_circle(Vector2(30.0, -40.0), 11.0, fur)
	ci.draw_colored_polygon(PackedVector2Array([Vector2(36.0, -38.0), Vector2(48.0, -34.0), Vector2(36.0, -30.0)]), fur.lightened(0.1))
	ci.draw_circle(Vector2(47.0, -35.0), 2.5, LINE)
	ci.draw_circle(Vector2(32.0, -43.0), 2.0, LINE)
	ci.draw_colored_polygon(PackedVector2Array([Vector2(26.0, -48.0), Vector2(32.0, -58.0), Vector2(36.0, -46.0)]), fur.darkened(0.25))
	ci.draw_line(Vector2(-24.0, -32.0), Vector2(-40.0, -44.0 + 8.0 * sin(t * 9.0)), fur.darkened(0.1), 5.0)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## The park's gate on Masson: two stone pillars with lamps on them and the iron gate swung open against the fence.
static func gate(ci: CanvasItem, x: float, y: float) -> void:
	for px: float in [x - 80.0, x + 80.0]:
		ci.draw_rect(Rect2(px - 17.0, y - 128.0, 34.0, 128.0), Color("#9C978E"))
		ci.draw_rect(Rect2(px - 17.0, y - 128.0, 8.0, 128.0), Color(1, 1, 1, 0.18))
		for k in 5:
			ci.draw_line(Vector2(px - 17.0, y - 20.0 - k * 22.0), Vector2(px + 17.0, y - 20.0 - k * 22.0), Color(0, 0, 0, 0.12), 1.0)
		ci.draw_rect(Rect2(px - 22.0, y - 138.0, 44.0, 12.0), Color("#7E7A72"))
		ci.draw_rect(Rect2(px - 11.0, y - 164.0, 22.0, 26.0), Color("#FFF1B8", 0.85))
		ci.draw_rect(Rect2(px - 11.0, y - 164.0, 22.0, 26.0), IRON, false, 2.0)
		ci.draw_colored_polygon(PackedVector2Array([Vector2(px - 14.0, y - 164.0), Vector2(px, y - 178.0), Vector2(px + 14.0, y - 164.0)]), IRON)
		snow_cap(ci, px - 22.0, y - 138.0, 44.0, 5.0)
	# The two gate leaves, open: seen edge-on, bars slanting toward us.
	for side in [-1.0, 1.0]:
		var hx: float = x + side * 63.0
		ci.draw_line(Vector2(hx, y - 6.0), Vector2(hx + side * 30.0, y + 8.0), IRON, 4.0)
		ci.draw_line(Vector2(hx, y - 96.0), Vector2(hx + side * 30.0, y - 84.0), IRON, 4.0)
		for k in 5:
			ci.draw_line(Vector2(hx + side * k * 6.0, y - 6.0 + k * 2.8), Vector2(hx + side * k * 6.0, y - 96.0 + k * 2.4), IRON, 2.0)
