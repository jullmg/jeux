class_name LaneArt
extends RefCounted
## The back lane's pieces as SVG (from the photos in reference/ruelle): the backs of the plexes with their wooden
## galleries and zigzag stairs, and in front, along the lane, what closes each yard: weathered board fences, cedar
## slats, pickets, green chain-link, old corrugated-metal garages, painted sheds, planter boxes; Virginia creeper
## (red in autumn) over all of it, blue recycling bins. Each canvas is the lot's width by 600, the lane's edge at
## y 600, in world pixels.

const H := 600.0
const BRICKS := ["#A8473A", "#8A4A3A", "#B5603F", "#7E4436", "#C8A27A", "#9C5A44"]
const SIDINGS := ["#E8E6DF", "#D9D4C7", "#C9D3D1", "#E9DDC4", "#BFC5C9", "#F2EEE4"]
const WOODS := ["#9C9488", "#7A4A2E", "#3E6B48", "#EDEBE4", "#5E6B73", "#A0522D", "#8E8A80"]
const BOARDS := ["#9A958C", "#A8A296", "#8C877E", "#B5AFA3", "#7E7A72"]
const TOLE := ["#B8BCC0", "#A9AEB3", "#C4C7CA"]
const PAINTED_TOLE := ["#9E3B2E", "#4E7A52", "#6B7F8E", "#B5893A"]


# ── Small SVG helpers ───────────────────────────────────────

static func _rect(x: float, y: float, w: float, h: float, fill: String, extra := "") -> String:
	return '<rect x="%.1f" y="%.1f" width="%.1f" height="%.1f" fill="%s" %s/>' % [x, y, w, h, fill, extra]


static func _line(a: Vector2, b: Vector2, color: String, width: float, extra := "") -> String:
	return '<path d="M%.1f %.1f L%.1f %.1f" stroke="%s" stroke-width="%.1f" fill="none" stroke-linecap="round" %s/>' % [a.x, a.y, b.x, b.y, color, width, extra]


static func _poly(points: Array, fill: String, extra := "") -> String:
	var d := PackedStringArray()
	for i in points.size():
		d.append("%s%.1f %.1f" % ["M" if i == 0 else "L", points[i].x, points[i].y])
	return '<path d="%s Z" fill="%s" %s/>' % [" ".join(d), fill, extra]


static func _dark(c: String, by := 0.25) -> String:
	return "#" + Color(c).darkened(by).to_html(false)


static func _light(c: String, by := 0.2) -> String:
	return "#" + Color(c).lightened(by).to_html(false)


static func _tex(w: float, body: String) -> ImageTexture:
	return PropArt.tex(PropArt._svg(w, H, body))


## This season's colours for the creeper on fences and garages (empty in winter: bare twigs).
static func vine_colors() -> Array:
	match Season.current:
		"spring":
			return ["#7FB85A", "#9BCB6A", "#5E9A40", "#B5D97A"]
		"summer":
			return ["#3E7A30", "#4F8E3A", "#2F6A2A", "#5DA040"]
		"winter":
			return []
	return ["#B5302A", "#D9482B", "#8E2A2A", "#E0782E", "#C9562E"]


# ── The backs of the plexes ─────────────────────────────────

## The back of a plex: brick or siding, windows, back doors onto stacked wooden galleries with a roof on the top
## one, posts down to the yard, zigzag stairs. Returns [texture, pulley] where pulley is the clothesline pulley on
## the top gallery's post (canvas coordinates).
static func back(rng: RandomNumberGenerator, w: float, own := false) -> Array:
	var floors := 2 if own else (3 if rng.randf() < 0.55 else 2)
	var fh := 118.0
	var ground := H - 30.0
	var top := ground - floors * fh - 16.0
	var siding := not own and rng.randf() < 0.4
	var wall: String = "#8A4A3A" if own else (PropArt._pick(rng, SIDINGS) if siding else PropArt._pick(rng, BRICKS))
	var wood: String = "#3E6B48" if own else PropArt._pick(rng, WOODS)
	var s := _rect(0, top, w, H - top, wall)
	var y := top + 14.0
	while y < H:
		s += _line(Vector2(0, y), Vector2(w, y), _dark(wall, 0.12) if siding else _light(wall, 0.25), 1.0, 'opacity="0.5"')
		y += 9.0 if siding else 7.0
	# Sunlit left edge, shaded right edge, the roof's flashing.
	s += _rect(0, top, 10, H - top, "#FFFFFF", 'opacity="0.12"')
	s += _rect(w - 14, top, 14, H - top, "#000000", 'opacity="0.12"')
	s += _rect(-2, top - 8, w + 4, 12, "#55585C")
	s += _rect(-2, top + 4, w + 4, 3, "#000000", 'opacity="0.2"')
	if rng.randf() < 0.35:
		s += _rect(w * rng.randf_range(0.2, 0.6), top - 30, 46, 22, "#C9CDD2", 'stroke="#8E9399" stroke-width="2"')
	# The gallery side: the back doors are on it.
	var left := rng.randf() < 0.5
	var g0 := 6.0 if left else w * 0.4
	var g1 := w * 0.6 if left else w - 6.0
	var door_x := g0 + 30.0 if left else g1 - 70.0
	for f in floors:
		var fy := ground - f * fh
		s += _rect(door_x, fy - 92, 40, 90, _dark(wall, 0.35), 'stroke="%s" stroke-width="3"' % _light(wood, 0.2))
		s += _rect(door_x + 7, fy - 84, 26, 34, "#8FA7B8", 'opacity="0.8"')
		var wx := g1 + 24.0 if left else 22.0
		for k in 2:
			var x := wx + k * 62.0
			if x + 46.0 > (w - 10.0 if left else g0 - 6.0) and k > 0:
				break
			s += _rect(x - 3, fy - 98, 52, 76, "#F2F0EA")
			s += _rect(x, fy - 95, 46, 70, "#7F97A8")
			s += _poly([Vector2(x, fy - 95), Vector2(x + 20, fy - 95), Vector2(x, fy - 60)], "#FFFFFF", 'opacity="0.25"')
			if rng.randf() < 0.5:
				s += _rect(x + 2, fy - 93, 14, 66, PropArt._pick(rng, ["#F4E3B0", "#E8B4B8", "#FFFFFF", "#B8D4E8"]), 'opacity="0.85"')
			s += _line(Vector2(x + 23, fy - 95), Vector2(x + 23, fy - 25), "#F2F0EA", 3.0)
	# Galleries on every floor (the ground one is a deck), with railings of balusters.
	var pulley := Vector2(g1 - 4.0 if left else g0 + 4.0, 0)
	for f in floors:
		var py := ground - f * fh + 2.0
		s += _rect(g0, py - 2, g1 - g0, 8, _dark(wood, 0.2))
		var rail := py - 36.0
		s += _rect(g0, rail, g1 - g0, 5, wood)
		var x := g0 + 4.0
		while x < g1 - 2.0:
			s += _rect(x, rail + 5, 3, 31, wood)
			x += 8.0
		if rng.randf() < 0.3 and f > 0:
			s += '<ellipse cx="%.1f" cy="%.1f" rx="11" ry="9" fill="%s"/>' % [g0 + (g1 - g0) * 0.7, rail - 4, PropArt._pick(rng, ["#C0392B", "#E3A33A", "#3E7A30"])]
		if f == floors - 1:
			# The top gallery's little roof, and the clothesline pulley on its outer post.
			s += _rect(g0 - 6, py - fh + 10, g1 - g0 + 12, 8, "#55585C")
			pulley.y = py - fh + 30.0
			s += '<circle cx="%.1f" cy="%.1f" r="5" fill="#D9D9D9" stroke="#55585C" stroke-width="2"/>' % [pulley.x, pulley.y]
	for px in [g0 + 2.0, g1 - 8.0]:
		s += _rect(px, ground - (floors - 1) * fh - fh + 10, 7, (floors - 1) * fh + fh - 10 + 30, _dark(wood, 0.1))
	# Zigzag stairs from the top gallery down to the yard.
	for f in range(floors - 1, 0, -1):
		var hi := ground - f * fh + 2.0
		var lo := ground - (f - 1) * fh + 2.0
		var go_left := (f % 2 == 0) == left
		var sx := g1 - 12.0 if go_left else g0 + 12.0
		var ex := sx + (-90.0 if go_left else 90.0)
		s += _poly([Vector2(sx, hi), Vector2(sx, hi + 7), Vector2(ex, lo + 7), Vector2(ex, lo)], _dark(wood, 0.15))
		for k in 9:
			var t := (k + 0.5) / 9.0
			var p := Vector2(lerpf(sx, ex, t), lerpf(hi, lo, t))
			s += _rect(p.x - 7, p.y - 2, 14, 3, _light(wood, 0.1))
		s += _line(Vector2(sx, hi - 34), Vector2(ex, lo - 34), wood, 3.0)
	return [_tex(w, s), pulley]


# ── Along the lane ──────────────────────────────────────────

## What closes one yard along the lane: "boards", "cedar", "picket", "chainlink", "tole" (old corrugated-metal
## garage), "garage" (with a roll-up door), "shed" or "garden" (planter boxes and a bench), with creeper, bins
## and, behind the low ones, a bit of the yard. `own`: Charlotte's yard (her swing).
static func front(rng: RandomNumberGenerator, w: float, kind: String, own := false) -> ImageTexture:
	var vines := vine_colors()
	var s := ""
	if kind in ["picket", "chainlink", "garden"]:
		s += _yard(rng, w, own)
	match kind:
		"boards":
			s += _boards(rng, 0.0, w, 175.0)
			s += _gate(rng, w * rng.randf_range(0.3, 0.6), 175.0)
		"cedar":
			s += _cedar(rng, 0.0, w, 170.0)
		"picket":
			s += _pickets(rng, 0.0, w, 92.0)
		"chainlink":
			s += _chainlink(rng, 0.0, w, 140.0)
		"tole":
			var gw := minf(w - 40.0, rng.randf_range(240.0, 290.0))
			var gx := rng.randf_range(10.0, w - gw - 10.0)
			s += _boards(rng, 0.0, gx, 170.0) + _boards(rng, gx + gw, w, 170.0)
			s += _tole(rng, gx, gw)
		"garage":
			var gw := minf(w - 40.0, 250.0)
			var gx := (w - gw) / 2.0
			s += _cedar(rng, 0.0, gx, 165.0) + _cedar(rng, gx + gw, w, 165.0)
			s += _garage(rng, gx, gw)
		"shed":
			s += _boards(rng, 0.0, w, 165.0)
			s += _shed(rng, rng.randf_range(10.0, w - 200.0))
		"garden":
			s += _pickets(rng, 0.0, w, 80.0)
			s += _planters(rng, w)
	# Creeper over the tops (fences, garages) and down their faces.
	var reach := 3 if kind in ["tole", "shed", "boards"] else 1
	for i in rng.randi_range(1, reach + 1):
		s += _vine(rng, rng.randf_range(10.0, w - 60.0), rng.randf_range(60.0, 140.0), H - (230.0 if kind == "tole" else 170.0), vines)
	# Bins against the fence: blue recycling, sometimes the brown compost bin.
	if kind != "garden" and rng.randf() < 0.45:
		var bx := rng.randf_range(20.0, w - 70.0)
		s += _bin(bx, "#2F6DB5")
		if rng.randf() < 0.5:
			s += _bin(bx + 48.0, "#6B4A2E", 0.8)
	if Season.is_winter():
		s += _rect(0, H - 6, w, 6, "#F4F6F8")
	return _tex(w, s)


static func _yard(rng: RandomNumberGenerator, w: float, own: bool) -> String:
	var grass: String = {"spring": "#8FBF5A", "summer": "#6DA544", "autumn": "#9A9A4A", "winter": "#F2F5F7"}[Season.current]
	var s := _rect(0, H - 70, w, 70, grass)
	for i in 6:
		var x := rng.randf_range(10.0, w - 30.0)
		s += '<ellipse cx="%.1f" cy="%.1f" rx="%.1f" ry="%.1f" fill="%s"/>' % [x, H - 72, rng.randf_range(18, 34), rng.randf_range(14, 24), _dark(grass, 0.2)]
	if own:
		# Her swing set: an A-frame and a yellow seat.
		var x := w * 0.62
		s += _line(Vector2(x - 60, H - 10), Vector2(x - 40, H - 150), "#C0392B", 6.0) + _line(Vector2(x - 20, H - 10), Vector2(x - 40, H - 150), "#C0392B", 6.0)
		s += _line(Vector2(x + 60, H - 10), Vector2(x + 80, H - 150), "#C0392B", 6.0) + _line(Vector2(x + 100, H - 10), Vector2(x + 80, H - 150), "#C0392B", 6.0)
		s += _line(Vector2(x - 40, H - 150), Vector2(x + 80, H - 150), "#C0392B", 7.0)
		s += _line(Vector2(x + 10, H - 148), Vector2(x + 10, H - 62), "#555555", 2.0) + _line(Vector2(x + 34, H - 148), Vector2(x + 34, H - 62), "#555555", 2.0)
		s += _rect(x + 4, H - 64, 36, 7, "#FFD23F", 'rx="3"')
	elif rng.randf() < 0.5:
		# A vegetable patch with tomato stakes, or a kid's slide.
		if rng.randf() < 0.5:
			for i in 4:
				var x := w * 0.2 + i * 34.0
				s += _line(Vector2(x, H - 20), Vector2(x, H - 110), "#8E6A44", 3.0)
				s += '<ellipse cx="%.1f" cy="%.1f" rx="14" ry="22" fill="%s"/>' % [x, H - 70, "#4F8E3A" if not Season.is_winter() else "#8E7A60"]
		else:
			var x := w * 0.55
			s += _poly([Vector2(x, H - 110), Vector2(x + 14, H - 110), Vector2(x + 90, H - 20), Vector2(x + 70, H - 20)], "#E74C3C")
			s += _line(Vector2(x + 4, H - 110), Vector2(x + 4, H - 15), "#2E86C1", 5.0)
	return s


static func _boards(rng: RandomNumberGenerator, x0: float, x1: float, h: float) -> String:
	var s := ""
	var x := x0
	while x < x1:
		var bw := minf(rng.randf_range(11.0, 14.0), x1 - x)
		var top := H - h + rng.randf_range(-4.0, 4.0)
		var c: String = PropArt._pick(rng, BOARDS)
		s += _rect(x, top, bw, H - top, c)
		s += _line(Vector2(x + bw, top), Vector2(x + bw, H), _dark(c, 0.35), 1.2)
		if rng.randf() < 0.3:
			s += _line(Vector2(x + bw * 0.5, top + rng.randf_range(10, 60)), Vector2(x + bw * 0.5, top + rng.randf_range(70, 150)), _dark(c, 0.2), 1.0)
		x += bw
	# The rail's nail line, and the weathered bottom.
	s += _rect(x0, H - h + 26, x1 - x0, 2, "#000000", 'opacity="0.15"')
	s += _rect(x0, H - 30, x1 - x0, 30, "#3A3020", 'opacity="0.18"')
	return s


static func _gate(rng: RandomNumberGenerator, x: float, h: float) -> String:
	var s := _line(Vector2(x, H - h + 6), Vector2(x, H - 4), "#4A443C", 2.0) + _line(Vector2(x + 90, H - h + 6), Vector2(x + 90, H - 4), "#4A443C", 2.0)
	s += _line(Vector2(x + 4, H - h + 40), Vector2(x + 86, H - 30), "#6E685E", 5.0)
	s += '<circle cx="%.1f" cy="%.1f" r="3.5" fill="#2B2B2B"/>' % [x + 80, H - h * 0.5]
	if rng.randf() < 0.3:
		s += _rect(x + 30, H - h + 50, 30, 16, "#F4F1EA") + '<text x="%.1f" y="%.1f" font-size="11" font-family="sans-serif" text-anchor="middle" fill="#2B2B2B">%d</text>' % [x + 45, H - h + 62, rng.randi_range(5600, 5700)]
	return s


static func _cedar(rng: RandomNumberGenerator, x0: float, x1: float, h: float) -> String:
	var c: String = PropArt._pick(rng, ["#B07A4E", "#C48B5A", "#A86E44", "#8E6A50"])
	if Season.current == "winter":
		c = _dark(c, 0.1)
	var s := _rect(x0, H - h, x1 - x0, h, _dark(c, 0.45))
	var y := H - h
	while y < H - 4:
		s += _rect(x0, y, x1 - x0, 13, _light(c, rng.randf_range(-0.08, 0.1)))
		y += 15.0
	var x := x0 + 4.0
	while x < x1:
		s += _rect(x, H - h - 6, 10, h + 6, _dark(c, 0.15))
		x += 120.0
	return s


static func _pickets(rng: RandomNumberGenerator, x0: float, x1: float, h: float) -> String:
	var c: String = PropArt._pick(rng, ["#F2EFE8", "#D9B98A", "#E8E2D4"])
	var s := _rect(x0, H - h + 18, x1 - x0, 7, _dark(c, 0.15)) + _rect(x0, H - 30, x1 - x0, 7, _dark(c, 0.15))
	var x := x0 + 3.0
	while x < x1 - 8.0:
		s += _poly([Vector2(x, H), Vector2(x, H - h + 8), Vector2(x + 5, H - h), Vector2(x + 10, H - h + 8), Vector2(x + 10, H)], c, 'stroke="%s" stroke-width="1"' % _dark(c, 0.3))
		x += 17.0
	return s


static func _chainlink(rng: RandomNumberGenerator, x0: float, x1: float, h: float) -> String:
	var c := "#3F6B47"
	var s := _rect(x0, H - h, x1 - x0, 4, c)
	var x := x0
	while x < x1 + h:
		s += _line(Vector2(x, H - h), Vector2(x - h, H), c, 1.2, 'opacity="0.8"')
		s += _line(Vector2(x - h, H - h), Vector2(x, H), c, 1.2, 'opacity="0.8"')
		x += 12.0
	x = x0 + 6.0
	while x < x1:
		s += _rect(x - 3, H - h - 4, 6, h + 4, "#4A5A4C")
		x += rng.randf_range(150.0, 190.0)
	return s


# The old corrugated-metal garage ("garage en tôle"): galvanized or faded paint, rust streaks, swing doors.
static func _tole(rng: RandomNumberGenerator, x: float, w: float) -> String:
	var h := 236.0
	var c: String = PropArt._pick(rng, PAINTED_TOLE) if rng.randf() < 0.4 else PropArt._pick(rng, TOLE)
	var top := H - h
	var s := _rect(x, top, w, h, c)
	var cx := x
	var dark := true
	while cx < x + w:
		s += _rect(cx, top, 4, h, _dark(c, 0.22) if dark else _light(c, 0.18), 'opacity="0.7"')
		cx += 4.0
		dark = not dark
	for i in rng.randi_range(2, 4):
		var rx := rng.randf_range(x + 10.0, x + w - 20.0)
		s += _poly([Vector2(rx, top + rng.randf_range(10, 80)), Vector2(rx + 10, top + 20), Vector2(rx + 6, H), Vector2(rx - 4, H)], "#8E5A3A", 'opacity="0.35"')
	# The flat roof's edge, a little window high up, the double doors.
	s += _rect(x - 8, top - 10, w + 16, 14, _dark(c, 0.4))
	if Season.is_winter():
		s += _rect(x - 8, top - 18, w + 16, 9, "#F4F6F8", 'rx="4"')
	var dw := minf(w - 30.0, 190.0)
	var dx := x + (w - dw) / 2.0
	s += _rect(dx, top + 50, dw, h - 50, "none", 'stroke="%s" stroke-width="3"' % _dark(c, 0.45))
	s += _line(Vector2(dx + dw / 2.0, top + 50), Vector2(dx + dw / 2.0, H), _dark(c, 0.45), 3.0)
	for hy in [top + 80, H - 40]:
		s += _rect(dx - 4, hy, 22, 6, "#3A3A3A") + _rect(dx + dw - 18, hy, 22, 6, "#3A3A3A")
	s += _rect(dx + dw / 2.0 - 14, top + 130, 10, 22, "#2B2B2B") + _rect(dx + dw / 2.0 + 4, top + 130, 10, 22, "#2B2B2B")
	if rng.randf() < 0.6:
		s += _rect(x + 14, top + 14, 34, 26, "#5A6670", 'stroke="#2E3438" stroke-width="3"')
	if rng.randf() < 0.3:
		# A basketball hoop above the doors.
		s += _rect(dx + dw / 2.0 - 32, top - 70, 64, 46, "#F4F4F4", 'stroke="#C0392B" stroke-width="3"')
		s += '<ellipse cx="%.1f" cy="%.1f" rx="18" ry="4" fill="none" stroke="#E67E22" stroke-width="3"/>' % [dx + dw / 2.0, top - 22]
	return s


static func _garage(rng: RandomNumberGenerator, x: float, w: float) -> String:
	var h := 220.0
	var top := H - h
	var wall: String = PropArt._pick(rng, BRICKS)
	var s := _rect(x, top, w, h, wall) + _rect(x - 6, top - 8, w + 12, 12, "#55585C")
	var y := top + 6.0
	while y < H:
		s += _line(Vector2(x, y), Vector2(x + w, y), _light(wall, 0.25), 1.0, 'opacity="0.5"')
		y += 7.0
	var dx := x + 22.0
	var dw := w - 44.0
	s += _rect(dx, top + 40, dw, h - 40, "#F0EEE8", 'stroke="#B9B2A5" stroke-width="3"')
	for k in 6:
		s += _line(Vector2(dx, top + 40 + (k + 1) * (h - 40) / 7.0), Vector2(dx + dw, top + 40 + (k + 1) * (h - 40) / 7.0), "#C9C3B8", 2.0)
	return s


static func _shed(rng: RandomNumberGenerator, x: float) -> String:
	var c: String = PropArt._pick(rng, ["#5FA8A0", "#7A9A8A", "#C9A24A", "#B5603F"])
	var w := 180.0
	var h := 190.0
	var top := H - h
	var s := _poly([Vector2(x - 8, top), Vector2(x + w / 2.0, top - 50), Vector2(x + w + 8, top)], "#5E6B73", 'stroke="#3F4A50" stroke-width="2"')
	s += _rect(x, top, w, h, c)
	var bx := x + 8.0
	while bx < x + w:
		s += _line(Vector2(bx, top), Vector2(bx, H), _dark(c, 0.2), 1.5)
		bx += 14.0
	s += _rect(x + 60, top + 40, 60, h - 40, _dark(c, 0.12), 'stroke="%s" stroke-width="3"' % _dark(c, 0.4))
	s += _rect(x + 20, top + 30, 28, 24, "#5A6670", 'stroke="#F2F0EA" stroke-width="3"')
	return s


# A ruelle verte corner: planter boxes of stacked boards, flowers or squash, and a bench of concrete blocks.
static func _planters(rng: RandomNumberGenerator, w: float) -> String:
	var s := ""
	var x := 14.0
	while x < w - 140.0:
		var bw := rng.randf_range(110.0, 150.0)
		var c := "#9C7A55"
		for k in 4:
			s += _rect(x, H - 72 + k * 17, bw, 16, _light(c, rng.randf_range(-0.1, 0.1)), 'stroke="%s" stroke-width="1"' % _dark(c, 0.3))
		if not Season.is_winter():
			for i in 7:
				var fx := x + 10 + i * (bw - 20) / 6.0
				s += _line(Vector2(fx, H - 72), Vector2(fx + rng.randf_range(-6, 6), H - 72 - rng.randf_range(20, 50)), "#4F8E3A", 3.0)
				s += '<circle cx="%.1f" cy="%.1f" r="6" fill="%s"/>' % [fx, H - 72 - rng.randf_range(30, 55), PropArt._pick(rng, ["#F1C40F", "#E74C3C", "#9B59B6", "#FFFFFF", "#E67E22"])]
		x += bw + 30.0
	# The bench: two concrete blocks and a plank.
	var bx := w - 120.0
	s += _rect(bx, H - 40, 26, 40, "#C9C6BE") + _rect(bx + 74, H - 40, 26, 40, "#C9C6BE")
	s += _rect(bx - 8, H - 50, 116, 12, "#D9C8A4", 'stroke="#A89878" stroke-width="1.5"')
	return s


static func _bin(x: float, color: String, size := 1.0) -> String:
	var w := 44.0 * size
	var h := 64.0 * size
	var s := _poly([Vector2(x, H - h), Vector2(x + w, H - h), Vector2(x + w - 4, H), Vector2(x + 4, H)], color, 'stroke="%s" stroke-width="2"' % _dark(color, 0.4))
	s += _rect(x - 3, H - h - 6, w + 6, 9, _dark(color, 0.2), 'rx="3"')
	if color == "#2F6DB5":
		s += '<path d="M%.1f %.1f l6 -9 l6 9 z" fill="none" stroke="#FFFFFF" stroke-width="2"/>' % [x + w / 2.0 - 6, H - h * 0.45]
	return s


# Virginia creeper: a mat over a fence top, tendrils hanging down, leaves in this season's colours.
static func _vine(rng: RandomNumberGenerator, x: float, w: float, top: float, colors: Array) -> String:
	var s := ""
	if colors.is_empty():
		for i in 8:
			var a := Vector2(x + rng.randf_range(0, w), top + rng.randf_range(-6, 10))
			s += _line(a, a + Vector2(rng.randf_range(-20, 20), rng.randf_range(20, 90)), "#6A5444", 1.5)
		return s
	for i in int(w / 4.0):
		var p := Vector2(x + rng.randf_range(0, w), top + rng.randf_range(-14, 12))
		s += '<ellipse cx="%.1f" cy="%.1f" rx="%.1f" ry="%.1f" fill="%s"/>' % [p.x, p.y, rng.randf_range(4, 8), rng.randf_range(3, 6), PropArt._pick(rng, colors)]
	for t in rng.randi_range(2, 5):
		var tx := x + rng.randf_range(0, w)
		var length := rng.randf_range(40.0, 140.0)
		var y := top
		while y < top + length:
			s += '<ellipse cx="%.1f" cy="%.1f" rx="%.1f" ry="%.1f" fill="%s"/>' % [tx + sin(y * 0.08) * 6.0 + rng.randf_range(-4, 4), y, rng.randf_range(4, 7), rng.randf_range(3, 5), PropArt._pick(rng, colors)]
			y += rng.randf_range(5.0, 9.0)
	return s


# ── Where the lane meets its cross lanes ────────────────────

## The cross lane running away toward 6e Avenue between two yards: concrete narrowing to a bright slice of
## the avenue (the houses across it), board fences and a garage along it, creeper, a pole.
static func junction(rng: RandomNumberGenerator, w: float) -> ImageTexture:
	var vp := Vector2(w / 2.0, 430.0)
	var far := 0.82
	var at := func(p: Vector2) -> Vector2: return vp + (p - vp) * (1.0 - far)
	var s := ""
	# The avenue's houses at the far end, in the light.
	var a0: Vector2 = at.call(Vector2(-40, 300))
	var a1: Vector2 = at.call(Vector2(w + 40, H))
	s += _rect(a0.x - 30, a0.y - 20, a1.x - a0.x + 60, a1.y - a0.y + 20, "#C8A27A", 'opacity="0.85"')
	for i in 4:
		s += _rect(a0.x - 22 + i * 18, a0.y - 8, 7, 9, "#E8EEF2", 'opacity="0.9"')
	s += _rect(a0.x - 30, a1.y - 6, a1.x - a0.x + 60, 6, "#9A9890")
	var ground_l := Vector2(10, H)
	var ground_r := Vector2(w - 10, H)
	s += _poly([ground_l, ground_r, at.call(ground_r), at.call(ground_l)], "#A9A59D")
	s += _line(Vector2(w / 2.0, H), at.call(Vector2(w / 2.0, H)), "#6E8A4A", 3.0)
	# Fences receding on both sides, boards converging.
	for side in [[Vector2(0, H - 175), Vector2(0, H)], [Vector2(w, H - 175), Vector2(w, H)]]:
		var t0: Vector2 = side[0]
		var b0: Vector2 = side[1]
		var c: String = PropArt._pick(rng, BOARDS)
		s += _poly([t0, at.call(t0), at.call(b0), b0], c)
		for k in 14:
			var f := k / 14.0
			var top := t0.lerp(at.call(t0), pow(f, 0.6))
			var bottom := b0.lerp(at.call(b0), pow(f, 0.6))
			s += _line(top, bottom, _dark(c, 0.3), 1.0)
	# A garage on the right, part way down.
	var g0 := Vector2(w, H - 240).lerp(at.call(Vector2(w, H - 240)), 0.35)
	var g1 := Vector2(w, H - 240).lerp(at.call(Vector2(w, H - 240)), 0.6)
	var b0 := Vector2(w, H).lerp(at.call(Vector2(w, H)), 0.35)
	var b1 := Vector2(w, H).lerp(at.call(Vector2(w, H)), 0.6)
	s += _poly([g0, g1, b1, b0], "#B8BCC0")
	s += _vine(rng, 0.0, 50.0, H - 175.0, vine_colors())
	s += _vine(rng, w - 60.0, 50.0, H - 175.0, vine_colors())
	return _tex(w, s)


## A wooden utility pole: canvas 80 wide, top at y 20, foot at y 600; crossarm with insulators.
static func pole(transformer := false) -> ImageTexture:
	var s := _rect(36, 20, 9, H - 20, "#6B5844") + _rect(36, 20, 3, H - 20, "#8C7664")
	s += _rect(6, 52, 68, 7, "#5A4A3A")
	for x in [10.0, 30.0, 50.0, 68.0]:
		s += _rect(x - 2, 42, 5, 10, "#8FA9B8")
	for y in range(160, 520, 34):
		s += _rect(44, y, 6, 3, "#3A3A3A")
	if transformer:
		s += _rect(46, 90, 26, 46, "#7E8790", 'rx="6"') + _rect(48, 86, 22, 6, "#5E6670")
	return PropArt.tex(PropArt._svg(80, H, s))
