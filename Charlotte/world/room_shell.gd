class_name RoomShell
extends Node2D
## The fixed part of an interior seen side-on: ceiling, walls (plaster, crown moulding, corner shading,
## baseboards) and a glossy strip-hardwood floor that mirrors the room's lights. Everything is data, so
## any interior can reuse it: fill `rooms` and the optional trims, then add it before the furniture.

const CEILING := 34.0
const WALL_BASE := 600.0
const BOTTOM := 720.0
const FLOOR_TONES := [Color("#D39A58"), Color("#C98C4C"), Color("#DDA968"), Color("#BF8042"), Color("#D6A060"), Color("#C48748")]

## Each room: {"from": x, "to": x, "wall": Color, "base": Color (baseboard)}, and optionally the wall's look:
## "pattern": "stars" | "dots" | "stripes" | "diamonds" (a wallpaper in `pattern_color`, `pattern_alpha`), "wainscot": Color
## (painted panels on the lower wall under a white rail, `wainscot_height` tall). Reusable for any house interior.
var rooms: Array = []
## Wooden chair rails along a wall: {"from": x, "to": x, "y": y}.
var chair_rails: Array = []
## Painted corner posts where a room opens onto the next one (x).
var posts: Array = []
## Door casings: {"x": left of the door, "w": door width, "top": y, "color": Color}.
var casings: Array = []
## x of windows and lamps whose light gleams on the glossy floor.
var gleams: Array = []
## "wood" (narrow honey strips) or "tiles" (a shop's checkered linoleum).
var floor_style := "wood"
## "moulding" (a home's crown moulding) or "drop" (a shop's suspended ceiling: tiles in a metal grid).
var ceiling_style := "moulding"
const TILES := [Color("#ECE8DE"), Color("#9AA092")]
## The two colours of the checkered floor (a shop sets its own).
var tile_colors: Array[Color] = [Color("#ECE8DE"), Color("#9AA092")]
var seed_value := 77


func _draw() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	for r in rooms:
		_room(r.from, r.to, r.wall, r.base, rng)
		_wallpaper(r, rng)
	for rail in chair_rails:
		draw_rect(Rect2(rail.from, rail.y, rail.to - rail.from, 12), Color("#B07A44"))
		draw_rect(Rect2(rail.from, rail.y, rail.to - rail.from, 3), Color("#C99560"))
		draw_rect(Rect2(rail.from, rail.y + 10, rail.to - rail.from, 3), Color("#7A4A26"))
		draw_rect(Rect2(rail.from, rail.y + 13, rail.to - rail.from, 8), Color(0.2, 0.1, 0.04, 0.1))
	for x: float in posts:
		draw_rect(Rect2(x - 12, CEILING, 24, WALL_BASE - CEILING), Color("#F4F1EA"))
		draw_line(Vector2(x - 12, CEILING), Vector2(x - 12, WALL_BASE), Color("#C9C2B4"), 2.0)
		draw_line(Vector2(x + 12, CEILING), Vector2(x + 12, WALL_BASE), Color("#C9C2B4"), 2.0)
		draw_rect(Rect2(x + 12, CEILING, 14, WALL_BASE - CEILING), Color(0.2, 0.1, 0.04, 0.08))
	for c in casings:
		var col: Color = c.color
		var x: float = c.x
		var w: float = c.w
		draw_rect(Rect2(x - 18, c.top - 18, w + 36, WALL_BASE - c.top + 18), col.darkened(0.25))
		draw_rect(Rect2(x - 12, c.top - 12, w + 24, WALL_BASE - c.top + 12), col)
		draw_rect(Rect2(x - 12, c.top - 12, w + 24, 4), col.lightened(0.2))
		draw_rect(Rect2(x + w + 18, c.top - 10, 10, WALL_BASE - c.top + 10), Color(0.2, 0.1, 0.04, 0.1))


func _room(x0: float, x1: float, wall: Color, base: Color, rng: RandomNumberGenerator) -> void:
	var w := x1 - x0
	_vgrad(x0, x1, 0.0, CEILING, Color("#F7F5F0"), Color("#E4DFD5"))
	_vgrad(x0, x1, CEILING, WALL_BASE, wall.lightened(0.05), wall.darkened(0.08))
	if ceiling_style == "drop":
		# Suspended ceiling: square tiles in a thin metal grid, an angle trim where it meets the wall.
		draw_rect(Rect2(x0, 0, w, CEILING), Color("#F2F2EE"))
		var gx := x0
		while gx < x1:
			draw_line(Vector2(gx, 0), Vector2(gx, CEILING), Color("#C9CBC6"), 2.0)
			gx += 120.0
		draw_line(Vector2(x0, CEILING * 0.5), Vector2(x1, CEILING * 0.5), Color("#C9CBC6"), 2.0)
		draw_rect(Rect2(x0, CEILING, w, 6), Color("#D6D8D4"))
		draw_rect(Rect2(x0, CEILING + 6, w, 2), Color("#A9ABA6"))
	else:
		# Crown moulding: cove, fillet and bead, with a soft shadow on the wall below.
		draw_rect(Rect2(x0, CEILING, w, 10), Color("#FBFAF6"))
		draw_rect(Rect2(x0, CEILING + 10, w, 6), Color("#E3DDD2"))
		draw_rect(Rect2(x0, CEILING + 16, w, 5), Color("#F7F5F0"))
		draw_line(Vector2(x0, CEILING + 21), Vector2(x1, CEILING + 21), Color("#CFC8BA"), 1.5)
	_vgrad(x0, x1, CEILING + 22, CEILING + 70, Color(0.2, 0.1, 0.04, 0.12), Color(0.2, 0.1, 0.04, 0.0))
	# Plaster: faint vertical variation so the wall isn't a flat sheet.
	var px := x0
	while px < x1:
		var pw := rng.randf_range(60.0, 160.0)
		draw_rect(Rect2(px, CEILING + 22, minf(pw, x1 - px), WALL_BASE - CEILING - 50), Color(1, 1, 1, rng.randf_range(0.0, 0.03)))
		px += pw
	# Corners darken, and the wall darkens a little just above the baseboard.
	for edge in [[x0, 1.0], [x1, -1.0]]:
		var ex: float = edge[0]
		var d: float = edge[1]
		var shade := Color(0.2, 0.1, 0.04, 0.16)
		draw_polygon(PackedVector2Array([Vector2(ex, CEILING), Vector2(ex + d * 70.0, CEILING), Vector2(ex + d * 70.0, WALL_BASE), Vector2(ex, WALL_BASE)]),
			PackedColorArray([shade, Color(shade, 0.0), Color(shade, 0.0), shade]))
	_vgrad(x0, x1, WALL_BASE - 90.0, WALL_BASE - 28.0, Color(0.2, 0.1, 0.04, 0.0), Color(0.2, 0.1, 0.04, 0.07))
	# Baseboard: a tall board with a bead on top and its shadow on the floor.
	draw_rect(Rect2(x0, WALL_BASE - 28, w, 28), base)
	draw_rect(Rect2(x0, WALL_BASE - 28, w, 4), base.lightened(0.25))
	draw_rect(Rect2(x0, WALL_BASE - 24, w, 2), base.darkened(0.15))
	if floor_style == "tiles":
		_tiles(x0, x1)
	else:
		_floor(x0, x1, rng)


# The wall's wallpaper and wainscot, over the plain plaster (see `rooms`).
func _wallpaper(r: Dictionary, rng: RandomNumberGenerator) -> void:
	var x0: float = r.from
	var x1: float = r.to
	var top := CEILING + 36.0
	var wain: float = r.get("wainscot_height", 190.0) if r.has("wainscot") else 0.0
	var bottom := WALL_BASE - 30.0 - wain
	var color: Color = r.get("pattern_color", Color(1, 1, 1))
	var alpha: float = r.get("pattern_alpha", 0.32)
	match str(r.get("pattern", "")):
		"stars":
			var y := top + 14.0
			var row := 0
			while y < bottom - 8.0:
				var x := x0 + 30.0 + (row % 2) * 48.0
				while x < x1 - 20.0:
					var c := Vector2(x + rng.randf_range(-6, 6), y + rng.randf_range(-5, 5))
					var rr := rng.randf_range(4.0, 7.0)
					var pts := PackedVector2Array()
					for k in 10:
						pts.append(c + Vector2.from_angle(-PI / 2.0 + TAU * k / 10.0) * (rr if k % 2 == 0 else rr * 0.45))
					draw_colored_polygon(pts, Color(color, alpha))
					x += 96.0
				y += 52.0
				row += 1
		"dots":
			var y2 := top + 10.0
			var row2 := 0
			while y2 < bottom:
				var x2 := x0 + 20.0 + (row2 % 2) * 24.0
				while x2 < x1 - 10.0:
					draw_circle(Vector2(x2, y2), 3.2, Color(color, alpha))
					x2 += 48.0
				y2 += 30.0
				row2 += 1
		"stripes":
			var x3 := x0
			var k3 := 0
			while x3 < x1:
				if k3 % 2 == 0:
					draw_rect(Rect2(x3, top - 10.0, minf(30.0, x1 - x3), bottom - top + 10.0 + wain), Color(color, alpha * 0.45))
				x3 += 30.0
				k3 += 1
		"diamonds":
			var y4 := top + 20.0
			var row4 := 0
			while y4 < bottom:
				var x4 := x0 + 24.0 + (row4 % 2) * 30.0
				while x4 < x1 - 10.0:
					draw_colored_polygon(PackedVector2Array([Vector2(x4, y4 - 8), Vector2(x4 + 6, y4), Vector2(x4, y4 + 8), Vector2(x4 - 6, y4)]), Color(color, alpha))
					x4 += 60.0
				y4 += 36.0
				row4 += 1
	if wain > 0.0:
		var wc: Color = r.wainscot
		var wy := WALL_BASE - 28.0 - wain
		draw_rect(Rect2(x0, wy, x1 - x0, wain), wc)
		draw_rect(Rect2(x0, wy, x1 - x0, 8), wc.lightened(0.55))
		draw_rect(Rect2(x0, wy + 8, x1 - x0, 3), Color(0.2, 0.1, 0.04, 0.18))
		var px := x0 + 18.0
		while px < x1 - 40.0:
			var pw := 74.0
			draw_rect(Rect2(px, wy + 26.0, pw, wain - 42.0), wc.darkened(0.06))
			draw_rect(Rect2(px, wy + 26.0, pw, 3), Color(0.2, 0.1, 0.04, 0.2))
			draw_rect(Rect2(px, wy + 26.0, 3, wain - 42.0), Color(0.2, 0.1, 0.04, 0.14))
			draw_rect(Rect2(px + pw - 3, wy + 28.0, 3, wain - 44.0), Color(1, 1, 1, 0.3))
			draw_rect(Rect2(px, wy + wain - 19.0, pw, 3), Color(1, 1, 1, 0.3))
			px += pw + 22.0


# Narrow honey-coloured strips running along the room, rows growing toward the camera, staggered butt
# joints, a dark edge under the baseboard, an overall sheen, and the lights mirrored in the varnish.
func _floor(x0: float, x1: float, rng: RandomNumberGenerator) -> void:
	draw_rect(Rect2(x0, WALL_BASE, x1 - x0, BOTTOM - WALL_BASE), Color("#C98C4C"))
	var y := WALL_BASE
	var row := 0
	while y < BOTTOM:
		var h := 5.0 + row * 1.7
		var x := x0 - rng.randf_range(0.0, 140.0)
		while x < x1:
			var strip := rng.randf_range(70.0, 210.0)
			var a := maxf(x, x0)
			var b := minf(x + strip, x1)
			var tone: Color = FLOOR_TONES[rng.randi_range(0, FLOOR_TONES.size() - 1)]
			draw_rect(Rect2(a, y, b - a, h), tone)
			# Grain: a darker streak along some strips.
			if rng.randf() < 0.35 and b - a > 30.0:
				draw_rect(Rect2(a + rng.randf_range(4.0, 20.0), y + h * rng.randf_range(0.3, 0.6), (b - a) * rng.randf_range(0.3, 0.7), 1.0), tone.darkened(0.12))
			draw_line(Vector2(b, y), Vector2(b, y + h), Color("#8E5A2C"), 1.0)
			x += strip
		draw_line(Vector2(x0, y), Vector2(x1, y), Color(0.45, 0.25, 0.1, 0.55), 1.0)
		y += h
		row += 1
	_vgrad(x0, x1, WALL_BASE, WALL_BASE + 14, Color(0.25, 0.12, 0.04, 0.32), Color(0.25, 0.12, 0.04, 0.0))
	_vgrad(x0, x1, WALL_BASE + 14, BOTTOM, Color(1, 0.95, 0.85, 0.0), Color(1, 0.95, 0.85, 0.08))
	# Reflections of windows and lamps: soft bright streaks straight down the varnish.
	for g: float in gleams:
		if g < x0 or g > x1:
			continue
		var half := 46.0
		for i in 3:
			var k := 1.0 - i * 0.3
			draw_polygon(PackedVector2Array([Vector2(g - half * k, WALL_BASE + 6), Vector2(g + half * k, WALL_BASE + 6), Vector2(g + half * k * 1.3, BOTTOM), Vector2(g - half * k * 1.3, BOTTOM)]),
				PackedColorArray([Color(1, 0.97, 0.88, 0.1), Color(1, 0.97, 0.88, 0.1), Color(1, 0.97, 0.88, 0.0), Color(1, 0.97, 0.88, 0.0)]))


# Checkered tiles in rows that widen toward the camera, fanning out from the room's middle, with a soft sheen.
func _tiles(x0: float, x1: float) -> void:
	var mid := (x0 + x1) / 2.0
	var y := WALL_BASE
	var row := 0
	while y < BOTTOM:
		var h := 10.0 + row * 4.0
		var w := 46.0 + row * 7.0
		var k := -ceili((mid - x0) / w) - 1
		while mid + k * w < x1:
			var a := maxf(mid + k * w, x0)
			var b := minf(mid + (k + 1) * w, x1)
			if b > a:
				draw_rect(Rect2(a, y, b - a, h), tile_colors[(k + row) & 1])
			k += 1
		draw_line(Vector2(x0, y), Vector2(x1, y), Color(0, 0, 0, 0.08), 1.0)
		y += h
		row += 1
	_vgrad(x0, x1, WALL_BASE, WALL_BASE + 14, Color(0.1, 0.1, 0.1, 0.25), Color(0.1, 0.1, 0.1, 0.0))
	for g: float in gleams:
		if g >= x0 and g <= x1:
			draw_polygon(PackedVector2Array([Vector2(g - 50, WALL_BASE + 6), Vector2(g + 50, WALL_BASE + 6), Vector2(g + 70, BOTTOM), Vector2(g - 70, BOTTOM)]),
				PackedColorArray([Color(1, 1, 1, 0.14), Color(1, 1, 1, 0.14), Color(1, 1, 1, 0.0), Color(1, 1, 1, 0.0)]))


func _vgrad(x0: float, x1: float, y0: float, y1: float, top: Color, bottom: Color) -> void:
	draw_polygon(PackedVector2Array([Vector2(x0, y0), Vector2(x1, y0), Vector2(x1, y1), Vector2(x0, y1)]),
		PackedColorArray([top, top, bottom, bottom]))
