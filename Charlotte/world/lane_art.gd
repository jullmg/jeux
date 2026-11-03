class_name LaneArt
extends RefCounted
## The back lane's pieces as SVG (from the photos in reference/ruelle): the backs of the plexes with their wooden
## galleries and zigzag stairs, and in front, along the lane, what closes each yard: weathered board fences, cedar
## slats, pickets, green chain-link, old corrugated-metal garages, painted sheds, planter boxes; Virginia creeper
## (red in autumn) over all of it, blue recycling bins. Each canvas is the lot's width by 600, the lane's edge at
## y 600, in world pixels.

const H := 600.0
## The near part of a T (`tee`): down to the bottom of the view.
const H_NEAR := 720.0
const NEAR_FENCE_ROOM := 20.0
## How many of the near fence's stretches are overgrown with creeper.
const NEAR_FENCE_VINES := 0.75
const TEE_PAD := 130.0
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
## one, posts down to the yard, zigzag stairs. Returns [texture, pulley, top] where pulley is the clothesline pulley on
## the top gallery's post (canvas coordinates), top the roof's height. `brick`: this building's own brick (a corner's).
static func back(rng: RandomNumberGenerator, w: float, own := false, brick := "") -> Array:
	var floors := 2 if own else (3 if rng.randf() < 0.55 else 2)
	var fh := 118.0
	var ground := H - 30.0
	var top := ground - floors * fh - 16.0
	var siding := not own and rng.randf() < 0.4
	var wall: String = "#8A4A3A" if own else (PropArt._pick(rng, SIDINGS) if siding else PropArt._pick(rng, BRICKS))
	if brick != "":
		siding = false
		wall = brick
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
			# A pot of something on the railing.
			var pot := Vector2(g0 + (g1 - g0) * 0.7, rail - 2.0)
			s += _foliage(rng, pot + Vector2(0, -12), Vector2(13, 10), shrub_colors(), 4.0, 16)
			s += _rect(pot.x - 8, pot.y - 8, 16, 10, "#B5603F")
		if f == floors - 1:
			# The top gallery's little roof, and the clothesline pulley on its outer post.
			s += _rect(g0 - 6, py - fh + 10, g1 - g0 + 12, 8, "#55585C")
			pulley.y = py - fh + 30.0
			s += '<circle cx="%.1f" cy="%.1f" r="5" fill="#D9D9D9" stroke="#55585C" stroke-width="2"/>' % [pulley.x, pulley.y]
	for px in [g0 + 2.0, g1 - 8.0]:
		s += _rect(px, ground - (floors - 1) * fh - fh + 10, 7, (floors - 1) * fh + fh - 10 + 30, _dark(wood, 0.1))
	# A metal spiral staircase from the top gallery down to the yard (only in the lanes, never on the street side),
	# or zigzag wooden stairs.
	if rng.randf() < 0.35:
		s += _spiral(g1 + 24.0 if left else g0 - 24.0, ground - (floors - 1) * fh + 2.0, ground + 30.0, floors - 1)
		return [_tex(w, s), pulley, top]
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
	return [_tex(w, s), pulley, top]


# A helix of steel treads round a central pole, one turn per floor, with its handrail.
static func _spiral(x: float, top: float, bottom: float, turns: int) -> String:
	var metal := "#2E3236"
	var s := _rect(x - 2.5, top - 40, 5, bottom - top + 40, metal)
	var r := 26.0
	var n := 16 * maxi(turns, 1)
	var rail := PackedStringArray()
	for i in n + 1:
		var a := TAU * i / 16.0
		var y := lerpf(top, bottom, float(i) / n)
		var tip := x + cos(a) * r
		var front := sin(a) > 0.0
		if i < n:
			s += _poly([Vector2(x, y - 2), Vector2(tip, y - 3), Vector2(tip, y + 1), Vector2(x, y + 2)], "#55595E" if front else "#3A3E42")
		rail.append("%s%.1f %.1f" % ["M" if i == 0 else "L", x + cos(a) * (r + 2.0), y - 34.0])
		if i % 2 == 0:
			s += _line(Vector2(tip, y - 2), Vector2(x + cos(a) * (r + 2.0), y - 34.0), metal, 1.2)
	s += '<path d="%s" stroke="%s" stroke-width="2.5" fill="none"/>' % [" ".join(rail), metal]
	return s


# ── Along the lane ──────────────────────────────────────────

## What closes one yard along the lane: "boards", "cedar", "picket", "chainlink", "tole" (old corrugated-metal
## garage), "garage" (with a roll-up door), "shed" or "garden" (planter boxes and a bench), with creeper, bins
## and, behind the low ones, a bit of the yard. `own`: Charlotte's yard (her swing).
static func front(rng: RandomNumberGenerator, w: float, kind: String, own := false) -> ImageTexture:
	var vines := vine_colors()
	var s := ""
	# A hedge or big shrub showing over the fence from the yard.
	if rng.randf() < 0.65 and not own:
		var rx := rng.randf_range(60.0, 96.0)
		s += _foliage(rng, Vector2(rng.randf_range(rx + 6.0, w - rx - 6.0), H - 190), Vector2(rx, rng.randf_range(36.0, 56.0)), shrub_colors(), 8.0, 70)
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
		var vw := rng.randf_range(60.0, 140.0)
		s += _vine(rng, rng.randf_range(10.0, w - vw - 10.0), vw, H - {"tole": 230.0, "garage": 226.0, "shed": 165.0}.get(kind, 170.0), vines)
	# What grows along the foot of the fence: a shrub spilling toward the lane, clumps of grass.
	if rng.randf() < 0.55 and kind != "garden":
		var rx := rng.randf_range(38.0, 62.0)
		s += _foliage(rng, Vector2(rng.randf_range(rx + 4.0, w - rx - 4.0), H - 30), Vector2(rx, rng.randf_range(26.0, 40.0)), shrub_colors(), 7.0, 46)
	for i in 3:
		s += _grass(rng, Vector2(rng.randf_range(14.0, w - 14.0), H - 2), rng.randf_range(20.0, 34.0))
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
	for i in 3:
		var rx := rng.randf_range(30.0, 46.0)
		s += _foliage(rng, Vector2(rng.randf_range(rx + 4.0, w - rx - 4.0), H - 84), Vector2(rx, rng.randf_range(20.0, 30.0)), shrub_colors(), 6.5, 36)
	for i in 5:
		s += _grass(rng, Vector2(rng.randf_range(10.0, w - 10.0), H - rng.randf_range(4.0, 40.0)), 16.0, 6)
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
				s += _foliage(rng, Vector2(x, H - 72), Vector2(15, 26), ["#3E7A30", "#4F8E3A", "#6DA544"] if not Season.is_winter() else [], 5.0, 22)
				if Season.current in ["summer", "autumn"]:
					s += '<circle cx="%.1f" cy="%.1f" r="3.5" fill="#D9482B"/>' % [x + 5.0, H - 66]
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
		# Leaves over the box's rim, flowers on stems above them (this season's; dry stalks in winter).
		var bloom_colors: Array = {"spring": ["#E8476A", "#F1C40F", "#FF8FB1", "#FFFFFF", "#C45BD6"], "summer": ["#F1C40F", "#E74C3C", "#9B59B6", "#FFFFFF", "#E67E22"],
			"autumn": ["#C9562E", "#E3A33A", "#8E3A5E", "#D9682B", "#F1C40F"], "winter": []}[Season.current]
		var plants := shrub_colors()
		if not plants.is_empty():
			plants = ["#4F8E3A", "#3E7A30", "#6DA544"] if Season.current != "autumn" else ["#5E7A30", "#7E8A3A", "#8E7A2E"]
		s += _foliage(rng, Vector2(x + bw / 2.0, H - 80), Vector2(bw * 0.5, 15), plants, 7.0, int(bw / 2.5))
		for i in 7:
			var fx := x + 10 + i * (bw - 20) / 6.0
			var tip := Vector2(fx + rng.randf_range(-6, 6), H - 72 - rng.randf_range(30, 58))
			var bloom := _tone(rng, bloom_colors)
			s += _line(Vector2(fx, H - 72), tip, "#4F8E3A" if bloom != "" else "#8E7A60", 2.0)
			if bloom != "":
				s += _bloom(tip, rng.randf_range(4.5, 6.5), bloom)
			else:
				rng.randf()
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
# ── Vegetation ──────────────────────────────────────────────
# As in the photos (reference/ruelle): leaves you can tell are leaves, massed over a dark shade, lighter toward the sun on the
# upper left. Everything here draws the same random numbers in every season; only what gets written changes.

## A leaf's outline, pointing up from its stalk at the origin: broad, with a point (they read as a mass, not as stars).
const LEAF_SHAPE := [Vector2(0, 0.12), Vector2(-0.46, -0.08), Vector2(-0.66, -0.42), Vector2(-0.46, -0.78), Vector2(0, -1.14), Vector2(0.46, -0.78), Vector2(0.66, -0.42), Vector2(0.46, -0.08)]
const SMALL_LEAF := [Vector2(0, 0.12), Vector2(-0.58, -0.42), Vector2(0, -1.14), Vector2(0.58, -0.42)]


## This season's shrubs (empty in winter: bare twigs).
static func shrub_colors() -> Array:
	match Season.current:
		"spring":
			return ["#6FA048", "#8FBF5A", "#B5D97A", "#5E8F3C", "#A6D07A"]
		"summer":
			return ["#2F6E2C", "#3E8E3A", "#55A048", "#2C5E2A", "#6DB05A"]
		"winter":
			return []
	return ["#8E8A2E", "#B5892E", "#C9562E", "#A8442A", "#6E7A2E", "#D9A02E"]


## Grass and weeds, whatever the season (straw under the snow).
static func grass_colors() -> Array:
	match Season.current:
		"spring":
			return ["#6DA544", "#8FBF5A", "#5A9A3C"]
		"summer":
			return ["#4F8E3A", "#3E7A30", "#6DA544"]
		"winter":
			return ["#A89A7A", "#8E8268", "#BDB29A"]
	return ["#7E8A3A", "#9A9A4A", "#A8863A"]


static func _leaf(p: Vector2, size: float, angle: float, color: String) -> String:
	var shape: Array = SMALL_LEAF if size < 4.0 else LEAF_SHAPE
	var c := cos(angle) * size
	var n := sin(angle) * size
	var d := ""
	for i in shape.size():
		var q: Vector2 = shape[i]
		d += "%s%.1f %.1f" % ["M" if i == 0 else "L", p.x + q.x * c - q.y * n, p.y + q.x * n + q.y * c]
	return '<path d="%sZ" fill="%s"/>' % [d, color]


# One of `colors` from one random number (nothing if there are none).
static func _tone(rng: RandomNumberGenerator, colors: Array) -> String:
	var t := rng.randf()
	return "" if colors.is_empty() else colors[mini(int(t * colors.size()), colors.size() - 1)]


## A mass of leaves round `c`, radii `r`: dark shade behind, each leaf turned outward, lit from the upper left. Bare twigs
## from its foot when there are no `colors`.
static func _foliage(rng: RandomNumberGenerator, c: Vector2, r: Vector2, colors: Array, leaf: float, count: int) -> String:
	var bare := colors.is_empty()
	var twig_seed := rng.randi()
	var s := _twigs(twig_seed, Vector2(c.x, c.y + r.y), r) if bare else ""
	for k in 6:
		var b := c + Vector2(rng.randf_range(-0.6, 0.6) * r.x, rng.randf_range(-0.5, 0.5) * r.y)
		var k_r := rng.randf_range(0.45, 0.7)
		if not bare:
			s += '<ellipse cx="%.1f" cy="%.1f" rx="%.1f" ry="%.1f" fill="%s"/>' % [b.x, b.y, r.x * k_r, r.y * k_r, _dark(colors[k % colors.size()], 0.42)]
	# Enough leaves to cover it, whatever its size.
	for i in maxi(count, mini(int(PI * r.x * r.y / (leaf * leaf) * 1.1), 240)):
		var a := rng.randf() * TAU
		var d := sqrt(rng.randf())
		var p := c + Vector2(cos(a) * d * r.x, sin(a) * d * r.y)
		var size := leaf * rng.randf_range(0.75, 1.25)
		var turn := a + PI / 2.0 + rng.randf_range(-0.7, 0.7)
		var tone := _tone(rng, colors)
		if bare:
			continue
		var lit := (-(p.x - c.x) / maxf(r.x, 1.0) - (p.y - c.y) / maxf(r.y, 1.0)) * 0.5
		s += _leaf(p, size, turn, _light(tone, lit * 0.25) if lit > 0.0 else _dark(tone, -lit * 0.34))
	return s


## A tree seen from afar, not a ball on a stick: the trunk forks into limbs that each carry a clump of leaves, the clumps fanned out
## wider than tall with sky between them, the ones on the upper left in the light and those on the lower right in the shade.
## `size`: the crown's half-width round `crown`. Bare limbs (and `_foliage`'s twigs) when there are no `colors`.
static func _distant_tree(rng: RandomNumberGenerator, foot: Vector2, crown: Vector2, size: float, colors: Array, bark: String) -> String:
	var thick := maxf(size * 0.1, 1.2)
	var s := _line(foot, foot.lerp(crown, 0.5), bark, thick)
	s += _line(foot.lerp(crown, 0.5), foot.lerp(crown, 0.88), bark, thick * 0.6)
	var count := clampi(int(size / 16.0) + 3, 3, 8)
	var clumps := []
	for k in count:
		var a := lerpf(-PI - 0.15, 0.15, (k + rng.randf_range(0.2, 0.8)) / count)
		var reach := rng.randf_range(0.5, 0.92)
		clumps.append([crown + Vector2(cos(a) * reach * size, sin(a) * reach * size * 0.68 + size * 0.1), size * rng.randf_range(0.3, 0.46)])
	clumps.append([crown + Vector2(rng.randf_range(-0.2, 0.2) * size, -0.1 * size), size * 0.4])
	# Each limb leaves the trunk at its own height, goes out and then up.
	for clump: Array in clumps:
		var c: Vector2 = clump[0]
		var from := foot.lerp(crown, rng.randf_range(0.42, 0.86))
		var bend := Vector2(lerpf(from.x, c.x, 0.72), lerpf(from.y, c.y, 0.28))
		s += '<path d="M%.1f %.1f Q%.1f %.1f %.1f %.1f" stroke="%s" stroke-width="%.1f" fill="none" stroke-linecap="round"/>' % [from.x, from.y, bend.x, bend.y, c.x, c.y, bark, maxf(thick * 0.42, 0.8)]
	# Shaded clumps first, so the lit ones lie over them.
	var light := func(clump: Array) -> float:
		return -((clump[0] as Vector2).x - crown.x) - ((clump[0] as Vector2).y - crown.y)
	clumps.sort_custom(func(p, q): return light.call(p) < light.call(q))
	var leaf := clampf(size * 0.085, 2.2, 8.0)
	for clump: Array in clumps:
		var lit: float = clampf(light.call(clump) / size, -1.0, 1.0)
		var tones := []
		for tone: String in colors:
			tones.append(_light(tone, lit * 0.16) if lit > 0.0 else _dark(tone, -lit * 0.2))
		var r: float = clump[1]
		s += _foliage(rng, clump[0], Vector2(r * 1.08, r * 0.82), tones, leaf, 24)
	return s


## Bare branches rising from `foot`: stems forking twice, a few red berries (from their own random numbers).
static func _twigs(seed_value: int, foot: Vector2, r: Vector2) -> String:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var d := ""
	var berries := ""
	for i in rng.randi_range(5, 8):
		var a := foot + Vector2(rng.randf_range(-0.3, 0.3) * r.x, 0)
		var b := a + Vector2(rng.randf_range(-0.7, 0.7) * r.x, -rng.randf_range(0.8, 1.5) * r.y)
		d += "M%.1f %.1f L%.1f %.1f " % [a.x, a.y, b.x, b.y]
		for k in 3:
			var from := a.lerp(b, rng.randf_range(0.4, 0.9))
			var to := from + Vector2(rng.randf_range(-0.5, 0.5) * r.x, -rng.randf_range(0.2, 0.6) * r.y)
			d += "M%.1f %.1f L%.1f %.1f " % [from.x, from.y, to.x, to.y]
			if seed_value % 2 == 0:
				berries += '<circle cx="%.1f" cy="%.1f" r="%.1f" fill="#B5302A"/>' % [to.x, to.y, maxf(r.x * 0.03, 0.8)]
	return '<path d="%s" stroke="#5E4A3C" stroke-width="%.1f" fill="none" stroke-linecap="round"/>%s' % [d, maxf(r.x * 0.03, 0.8), berries]


## Virginia creeper over the top of a fence and down its face: a mass of leaves along the top, strands trailing from it with
## their leaves thinning out; only the stems in winter.
static func _vine(rng: RandomNumberGenerator, x: float, w: float, top: float, colors: Array) -> String:
	var bare := colors.is_empty()
	var s := ""
	if not bare:
		s += '<ellipse cx="%.1f" cy="%.1f" rx="%.1f" ry="7" fill="%s"/>' % [x + w / 2.0, top, w * 0.46, _dark(colors[0], 0.4)]
	var leaves := ""
	for i in int(w / 1.3):
		var p := Vector2(x + rng.randf_range(0, w), top + rng.randf_range(-12, 12))
		var size := rng.randf_range(5.5, 8.5)
		var turn := rng.randf_range(-1.2, 1.2) + PI
		var tone := _tone(rng, colors)
		if not bare:
			leaves += _leaf(p, size, turn, tone)
	for t in rng.randi_range(3, 5):
		var tx := x + rng.randf_range(0, w)
		var length := rng.randf_range(40.0, 140.0)
		var y := top
		var stem := "M%.1f %.1f" % [tx, y]
		while y < top + length:
			var f := (y - top) / length
			var sway := tx + sin(y * 0.08) * 6.0
			stem += " L%.1f %.1f" % [sway, y]
			var side := 1.0 if int(y) % 2 == 0 else -1.0
			var size := lerpf(7.5, 3.5, f) * rng.randf_range(0.85, 1.15)
			var turn := PI + side * rng.randf_range(0.5, 1.2)
			var tone := _tone(rng, colors)
			if not bare:
				leaves += _leaf(Vector2(sway + side * 2.0, y), size, turn, tone)
			y += rng.randf_range(5.0, 9.0)
		s += '<path d="%s" stroke="%s" stroke-width="1.2" fill="none"/>' % [stem, "#6A5444" if bare else _dark(colors[0], 0.5)]
	return s + leaves


## Creeper covering a stretch of wall, as on the photos: a sheet of leaves from the ground up, its top and sides uneven, thinner
## toward the top with a few runners ahead of it; only the stems in winter.
static func _climber(rng: RandomNumberGenerator, x: float, w: float, top: float, bottom: float, colors: Array) -> String:
	var bare := colors.is_empty()
	var h := bottom - top
	var outline := []
	# The shade behind the leaves stops well short of their edge, so only leaves show at the top and sides.
	for k in 9:
		outline.append(Vector2(x + 8.0 + rng.randf_range(-4.0, 4.0), lerpf(bottom, top + h * 0.26, k / 8.0)))
	for k in 7:
		outline.append(Vector2(lerpf(x + 8.0, x + w - 8.0, k / 6.0), top + h * 0.2 + rng.randf_range(-4.0, 4.0)))
	for k in 9:
		outline.append(Vector2(x + w - 8.0 + rng.randf_range(-4.0, 4.0), lerpf(top + h * 0.26, bottom, k / 8.0)))
	var s := ""
	if bare:
		var stems := ""
		for k in 7:
			var sx := x + w * k / 6.0
			stems += "M%.1f %.1f Q%.1f %.1f %.1f %.1f " % [sx, bottom, sx + 14.0 * sin(k * 2.1), top + h * 0.5, sx + 18.0 * cos(k * 1.7), top + h * (0.05 + 0.08 * (k % 3))]
		s += '<path d="%s" stroke="#6A5444" stroke-width="1.4" fill="none"/>' % stems
	else:
		s += _poly(outline, _dark(colors[0], 0.42))
	for i in mini(int(w * h / 38.0), 460):
		var p := Vector2(x + rng.randf_range(-6.0, w + 6.0), bottom - pow(rng.randf(), 0.95) * h)
		var size := rng.randf_range(5.5, 8.5)
		var turn := PI + rng.randf_range(-0.9, 0.9)
		var tone := _tone(rng, colors)
		if not bare:
			s += _leaf(p, size, turn, _light(tone, 0.14) if p.x < x + w * 0.35 else _dark(tone, 0.1))
	# Runners feeling their way up the bricks above it.
	for k in 3:
		var rx := x + rng.randf_range(0.1, 0.9) * w
		var ry := top + rng.randf_range(0.0, h * 0.1)
		var run := rng.randf_range(30.0, 60.0)
		for n in 5:
			var q := Vector2(rx + sin(n * 1.3) * 5.0, ry - n / 4.0 * run)
			var tone := _tone(rng, colors)
			if not bare:
				s += _leaf(q, 4.5, PI + (0.8 if n % 2 == 0 else -0.8), tone)
	return s


## A clump of arching grass blades rooted at `p`.
static func _grass(rng: RandomNumberGenerator, p: Vector2, h: float, blades := 10) -> String:
	var colors := grass_colors()
	var s := ""
	for i in blades:
		var lean := rng.randf_range(-0.9, 0.9) * h
		var tall := h * rng.randf_range(0.6, 1.0)
		var root := p + Vector2(rng.randf_range(-h * 0.15, h * 0.15), 0)
		s += '<path d="M%.1f %.1f Q%.1f %.1f %.1f %.1f" stroke="%s" stroke-width="%.1f" fill="none" stroke-linecap="round"/>' % [root.x, root.y, root.x + lean * 0.2, root.y - tall, root.x + lean, root.y - tall * 0.65, _tone(rng, colors), maxf(h * 0.05, 0.7)]
	return s


## A flower with six petals.
static func _bloom(p: Vector2, r: float, color: String) -> String:
	var s := ""
	for i in 6:
		var a := TAU * i / 6.0
		s += '<circle cx="%.1f" cy="%.1f" r="%.1f" fill="%s"/>' % [p.x + cos(a) * r * 0.62, p.y + sin(a) * r * 0.62, r * 0.52, color]
	return s + '<circle cx="%.1f" cy="%.1f" r="%.1f" fill="#E8B32E"/>' % [p.x, p.y, r * 0.38]


## A croque-livre (a little free library): a painted wooden box with a pitched roof on a post, books behind its
## glass door, a hand-lettered sign. Canvas 100x200, the post's foot at (50, 200).
static func croque_livre(rng: RandomNumberGenerator) -> ImageTexture:
	var paint: String = PropArt._pick(rng, ["#F2C230", "#4FA3A0", "#D9482B", "#5E8FD0", "#7FB85A"])
	var s := _rect(45, 110, 10, 90, "#6E5A48") + _rect(45, 110, 3, 90, "#8C7664")
	s += _rect(30, 192, 40, 8, "#5A4A3A", 'rx="2"')
	s += _rect(10, 40, 80, 74, paint, 'stroke="%s" stroke-width="3"' % _dark(paint, 0.4))
	s += _poly([Vector2(2, 44), Vector2(50, 8), Vector2(98, 44)], "#5E6B73", 'stroke="#3F4A50" stroke-width="2"')
	if Season.is_winter():
		s += _poly([Vector2(4, 40), Vector2(50, 6), Vector2(96, 40), Vector2(50, 14)], "#F4F6F8")
	# The glass door and the books inside, two shelves of spines.
	s += _rect(18, 48, 64, 58, "#3A3A40")
	for shelf in 2:
		var x := 21.0
		var y := 50.0 + shelf * 28.0
		while x < 78.0:
			var bw := rng.randf_range(4.0, 8.0)
			var bh := rng.randf_range(16.0, 24.0)
			s += _rect(x, y + 26.0 - bh, bw, bh, PropArt._pick(rng, ["#E74C3C", "#3498DB", "#F1C40F", "#2ECC71", "#9B59B6", "#ECF0F1", "#E67E22"]))
			x += bw + 1.0
		s += _rect(18, y + 26, 64, 2, "#2A2A2E")
	s += _rect(18, 48, 64, 58, "#BFD8E6", 'opacity="0.25" stroke="%s" stroke-width="3"' % _light(paint, 0.2))
	s += _poly([Vector2(22, 52), Vector2(40, 52), Vector2(22, 80)], "#FFFFFF", 'opacity="0.3"')
	s += '<circle cx="76" cy="78" r="2.5" fill="#E3C26A"/>'
	# The hand-lettered sign on the post.
	s += _rect(20, 122, 60, 18, "#F4F1EA", 'stroke="#55524C" stroke-width="1.5" transform="rotate(-4 50 131)"')
	s += '<text x="50" y="135" font-size="9" font-family="sans-serif" text-anchor="middle" fill="%s" transform="rotate(-4 50 131)">croque-livre</text>' % _dark(paint, 0.3)
	return PropArt.tex(PropArt._svg(100, 200, s))


# ── Where the lane meets the avenues and the other lanes ────

## The side of the plex at a cross lane's corner, square to the lane and facing us (its facade runs away from us down the
## avenue, CrossStreet's first wall): exposed brick up to the coping, the cornice's return at the corner, a stone
## foundation, a few small windows, a downspout, the meters, patched mortar. `top` and `color` are that facade's;
## `front_left`: the avenue is on the left of this wall.
static func side_wall(rng: RandomNumberGenerator, w: float, top: float, color: Color, front_left: bool) -> ImageTexture:
	var brick := "#" + color.to_html(false)
	var front := 0.0 if front_left else w
	var inward := 1.0 if front_left else -1.0
	var s := _rect(0, top, w, H - top, brick)
	# Courses, and the staggered joints between the bricks.
	var courses := ""
	var joints := ""
	var row := 0
	var y := top + 6.0
	while y < H - 44.0:
		courses += "M0 %.1f H%.1f " % [y, w]
		var x := 7.0 if row % 2 == 0 else 18.0
		while x < w:
			joints += "M%.1f %.1f V%.1f " % [x, y, y + 7.0]
			x += 22.0
		y += 7.0
		row += 1
	s += '<path d="%s" stroke="%s" stroke-width="1" fill="none" opacity="0.55"/>' % [courses, _light(brick, 0.28)]
	s += '<path d="%s" stroke="%s" stroke-width="1" fill="none" opacity="0.4"/>' % [joints, _dark(brick, 0.3)]
	# Patches of newer mortar and brick.
	for i in 5:
		var pw := rng.randf_range(40.0, 110.0)
		var ph := rng.randf_range(28.0, 70.0)
		s += _rect(rng.randf_range(10.0, w - pw - 10.0), rng.randf_range(top + 20.0, H - ph - 60.0), pw, ph, _dark(brick, 0.16) if i % 2 == 0 else _light(brick, 0.12), 'opacity="0.3"')
	# Small windows on each floor, stone sill and lintel, away from the corner.
	var floors := int(round((H - top - 40.0) / 118.0))
	var columns: Array[float] = [w * 0.36, w * 0.66]
	for f in floors:
		var base := H - 62.0 - f * 118.0
		for cx in columns:
			var wx: float = (front + inward * cx) - 18.0
			if rng.randf() < 0.25:
				continue
			s += _rect(wx - 4, base - 74, 44, 7, "#C9C2B2")
			s += _rect(wx - 2, base - 67, 40, 62, "#EDE9DF")
			s += _rect(wx + 2, base - 63, 32, 54, "#7F97A8")
			s += _poly([Vector2(wx + 2, base - 63), Vector2(wx + 18, base - 63), Vector2(wx + 2, base - 34)], "#FFFFFF", 'opacity="0.25"')
			if rng.randf() < 0.5:
				s += _rect(wx + 2, base - 63, 32, rng.randf_range(12.0, 30.0), PropArt._pick(rng, ["#F2EEE4", "#E8D9B8", "#C9D3D1"]), 'opacity="0.9"')
			s += _rect(wx - 5, base - 5, 46, 6, "#C9C2B2")
			s += _rect(wx - 5, base + 1, 46, 2, "#000000", 'opacity="0.2"')
	# Stone foundation with a low basement window.
	s += _rect(0, H - 44, w, 44, "#9A968C")
	s += _rect(0, H - 46, w, 3, "#C2BDB1")
	s += _rect(0, H - 22, w, 1.5, "#7E7A72", 'opacity="0.7"')
	var low := front + inward * w * 0.5 - 26.0
	s += _rect(low, H - 38, 52, 22, "#55524C") + _rect(low + 3, H - 35, 46, 16, "#6E8290")
	# Sunlit left, shaded right, darker low down where the rain splashes.
	s += _rect(0, top, 12, H - top, "#FFFFFF", 'opacity="0.1"')
	s += _rect(w - 16, top, 16, H - top, "#000000", 'opacity="0.14"')
	s += _rect(0, H - 90, w, 90, "#000000", 'opacity="0.07"')
	# Coping along the top, the facade's cornice coming round the corner.
	s += _rect(-2, top - 8, w + 4, 12, "#55585C")
	s += _rect(-2, top + 4, w + 4, 3, "#000000", 'opacity="0.22"')
	var cornice := front if front_left else front - 26.0
	s += _rect(cornice, top - 16, 26, 26, "#6A6E72") + _rect(cornice, top - 18, 26, 4, "#8E9399")
	s += _rect(cornice, top + 10, 26, 3, "#000000", 'opacity="0.25"')
	# The downspout at the far end, the hydro and gas meters near the corner with their conduits.
	var spout := front + inward * (w - 26.0)
	s += _line(Vector2(spout, top + 2), Vector2(spout, H - 6), "#7E8388", 5.0)
	s += _line(Vector2(spout - 2, top + 2), Vector2(spout - 2, H - 6), "#A9AEB3", 1.2)
	for k in floors:
		s += _rect(spout - 5, H - 90.0 - k * 118.0, 10, 4, "#55585C")
	var mx := front + inward * 46.0 - 10.0
	s += _line(Vector2(mx + 10, top + 30), Vector2(mx + 10, H - 150), "#55585C", 2.5)
	s += _rect(mx, H - 150, 20, 30, "#8E9399", 'stroke="#55585C" stroke-width="1.5"')
	s += '<circle cx="%.1f" cy="%.1f" r="6" fill="#DDE3E6" stroke="#55585C" stroke-width="1"/>' % [mx + 10, H - 135]
	s += _rect(mx + 2, H - 88, 16, 26, "#D9B13A", 'stroke="#8E7420" stroke-width="1.2"')
	s += _line(Vector2(mx + 10, H - 62), Vector2(mx + 10, H - 44), "#8E7420", 3.0)
	# A tag low on the bricks, now and then.
	if rng.randf() < 0.5:
		var tx := front + inward * w * rng.randf_range(0.55, 0.75) - 40.0
		s += '<path d="M%.1f %.1f q10 -22 18 -2 t16 -6 q6 -14 14 0 t18 -4" stroke="%s" stroke-width="3.5" fill="none" stroke-linecap="round"/>' % [tx, H - 62.0, PropArt._pick(rng, ["#2B2F6B", "#1F1F1F", "#7A1F5C"])]
	# Creeper climbing its far end, a bin at its foot.
	var climb := front + inward * (w - 60.0) - 50.0
	s += _climber(rng, climb, 110.0, H - rng.randf_range(210.0, 300.0), H - 2.0, vine_colors())
	s += _grass(rng, Vector2(front + inward * 90.0, H - 2.0), 26.0)
	s += _bin(front + inward * (w - 170.0) - 22.0, "#2F6DB5")
	if Season.is_winter():
		s += _rect(-2, top - 13, w + 4, 6, "#F4F6F8")
		s += _rect(cornice, top - 23, 26, 6, "#F4F6F8")
		s += _rect(0, H - 6, w, 6, "#F4F6F8")
	return _tex(w, s)


## SVG body, `w` by `h`: the fence along the near side of a cross lane, right in front of the camera, only its upper part in
## view: wide weathered boards, stretch by stretch between posts, a rail, knots and nails, creeper hanging over it by season,
## snow along the top in winter. For Foreground.add. The top NEAR_FENCE_ROOM of `h` is left for the creeper above the boards.
static func near_fence(rng: RandomNumberGenerator, w: float, h: float) -> String:
	var s := ""
	var vines := vine_colors()
	var fence_h := h - NEAR_FENCE_ROOM
	var x := 0.0
	while x < w:
		var stretch := minf(rng.randf_range(300.0, 460.0), w - x)
		var family: String = PropArt._pick(rng, BOARDS)
		var tint: String = PropArt._pick(rng, ["#6E5A44", "#7A4A2E", family, family])
		var top := 8.0 + rng.randf_range(0.0, 6.0)
		var bx := x
		while bx < x + stretch:
			var bw := minf(rng.randf_range(30.0, 40.0), x + stretch - bx)
			var by := top + rng.randf_range(-3.0, 3.0)
			var c := _dark(tint, rng.randf_range(0.0, 0.18))
			s += _rect(bx, by, bw, fence_h - by, c)
			s += _rect(bx, by, 3, fence_h - by, _light(c, 0.25), 'opacity="0.6"')
			s += _line(Vector2(bx + bw, by), Vector2(bx + bw, fence_h), _dark(c, 0.45), 2.0)
			if rng.randf() < 0.3:
				s += '<ellipse cx="%.1f" cy="%.1f" rx="4" ry="6" fill="%s"/>' % [bx + bw * 0.5, by + rng.randf_range(20.0, 60.0), _dark(c, 0.3)]
			s += '<circle cx="%.1f" cy="%.1f" r="1.6" fill="#3A3A3A"/>' % [bx + bw * 0.5, top + 26.0]
			bx += bw
		# The rail across the boards.
		s += _rect(x, top + 20.0, stretch, 7, _dark(tint, 0.3), 'opacity="0.5"')
		if vines.is_empty():
			s += _rect(x, top - 5.0, stretch, 7, "#F4F6F8")
		# The post at the end of the stretch, standing a little proud.
		s += _rect(x + stretch - 13.0, 2, 26, fence_h - 2, _dark(tint, 0.25))
		s += _rect(x + stretch - 13.0, 2, 5, fence_h - 2, _light(tint, 0.1), 'opacity="0.6"')
		s += _rect(x + stretch - 15.0, 0, 30, 5, _dark(tint, 0.4))
		# Most stretches have creeper growing over the top and trailing down, this season's colours; bare stems in winter.
		var overgrown := rng.randf() < NEAR_FENCE_VINES
		for k in rng.randi_range(2, 3):
			var vw := rng.randf_range(90.0, 170.0)
			var vine := _vine(rng, x + rng.randf_range(0.0, maxf(stretch - vw, 1.0)), vw, top, vines)
			if overgrown:
				s += vine
		x += stretch
	# First post, at the avenue's end.
	s += _rect(0, 2, 22, fence_h - 2, _dark(PropArt._pick(rng, BOARDS), 0.3))
	s += _rect(0, 0, 24, 5, "#55524C")
	return '<g transform="translate(0 %.1f)">%s</g>' % [NEAR_FENCE_ROOM, s]


## The lane carrying on past an avenue, from depth `start` to the vanishing point: its yards, then the next avenue and the next
## block's lane entrance, far to near, hazier with distance. `at`: (u, y, depth) -> where it is in the view. Own random numbers.
static func _lanes_beyond(at: Callable, half: float, start: float) -> String:
	const BLOCK := 3.6
	const AVENUE := 0.9
	const BLOCKS := 3
	const CORNER := 0.6
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	var winter := Season.is_winter()
	var palettes := Season.tree_palettes()
	var hazed := func(c: String, amount: float) -> String: return "#" + Color(c).lerp(Color("#CFD6DC"), clampf(amount, 0.0, 0.8)).to_html(false)
	var plane := func(u: float, top: float, d0: float, d1: float, fill: String) -> String:
		return _poly([at.call(u, top, d0), at.call(u, top, d1), at.call(u, H, d1), at.call(u, H, d0)], fill)
	var facing := func(u0: float, u1: float, top: float, bottom: float, d: float, fill: String) -> String:
		return _poly([at.call(u0, top, d), at.call(u1, top, d), at.call(u1, bottom, d), at.call(u0, bottom, d)], fill)
	var ground := func(u0: float, u1: float, d0: float, d1: float, fill: String) -> String:
		return _poly([at.call(u0, H, d0), at.call(u1, H, d0), at.call(u1, H, d1), at.call(u0, H, d1)], fill)
	var concrete := "#E9EDF0" if winter else "#A9A59D"
	var s: String = ground.call(-half, half, start + BLOCKS * (BLOCK + AVENUE) - AVENUE, 900.0, hazed.call(concrete, 0.7))
	for b in range(BLOCKS - 1, -1, -1):
		var d0 := start + b * (BLOCK + AVENUE)
		var d1 := d0 + BLOCK
		var mist := 0.12 + b * 0.2
		if b < BLOCKS - 1:
			s += ground.call(-1800.0, 1800.0, d1, d1 + AVENUE, hazed.call("#F0F2F4" if winter else "#BDB7AC", mist))
			s += ground.call(-1800.0, 1800.0, d1 + 0.14, d1 + AVENUE - 0.14, hazed.call("#D5DADF" if winter else "#4F5054", mist))
		s += ground.call(-half, half, d0, d1, hazed.call(concrete, mist))
		for u: float in [-half, half]:
			var brick: String = hazed.call(PropArt._pick(rng, BRICKS), mist)
			s += plane.call(u * 2.4, 300.0, d0 + CORNER, d1, brick)
			for n in 3:
				var d := lerpf(d1, d0 + CORNER, (n + 0.5) / 3.0)
				var pick := rng.randi()
				var pal: Array = [] if palettes.is_empty() else palettes[pick % palettes.size()]
				s += _distant_tree(rng, at.call(u * 1.5, H, d), at.call(u * 1.5, 200.0, d), 210.0 / (1.0 + d), pal, "#5E4A3C")
			s += plane.call(u, H - 175.0, d0 + CORNER, d1, hazed.call(BOARDS[0], mist))
			var top := rng.randf_range(255.0, 295.0)
			s += plane.call(u, top, d0, d0 + CORNER, brick)
			if b > 0:
				var out := u * 7.0
				s += facing.call(u, out, top, H, d0, brick)
				for row in 2:
					for col in 7:
						var cx := lerpf(u, out, (col + 0.5) / 7.0)
						var wy := H - 110.0 - row * 118.0
						s += facing.call(cx - 26.0, cx + 26.0, wy - 60.0, wy, d0, hazed.call("#9FB2BE", mist))
	return s


## Where a long lane ends on a cross lane, a T, for a sprite of its own either side of the ground. We stand in the long lane looking
## toward the avenue; the cross lane comes past us and runs away, one-point perspective on CrossStreet's horizon at x `vx`, `half`
## either side of it at the fence line (depth 0). `s` is the side the long lane leaves on (1: to the right). u > 0 is that side:
## `ours`, the plex whose back is the long lane's first lot, then its yard fence; u < 0 the far side: the yards of the buildings
## behind, seen along their backs, and `theirs` at the avenue. Close by is the avenue itself: the sidewalk, the road, the plexes
## across. Returns [far part, for under the ground; near part, H_NEAR tall, over it: the far side's fence going off past us]: both
## TEE_PAD wider than `w`, on the long lane's side (slabs and wires run on over its first lot).
static func tee(rng: RandomNumberGenerator, w: float, vx: float, s: float, half: float, ours: Dictionary, theirs: Dictionary, lush: bool) -> Array:
	const YARD := 0.55
	const CURB := 1.2
	const ROAD := 1.34
	const FAR_ROAD := 1.95
	const FACADES := 2.09
	const NEAREST := -0.72
	const FENCE := 175.0
	var at := func(u: float, y: float, d: float) -> Vector2:
		return Vector2(vx + s * u / (1.0 + d), CrossStreet.HORIZON_Y + (y - CrossStreet.HORIZON_Y) / (1.0 + d))
	var plane := func(u: float, top: float, bottom: float, d0: float, d1: float, fill: String, extra := "") -> String:
		return _poly([at.call(u, top, d0), at.call(u, top, d1), at.call(u, bottom, d1), at.call(u, bottom, d0)], fill, extra)
	var facing := func(u0: float, u1: float, top: float, bottom: float, d: float, fill: String, extra := "") -> String:
		return _poly([at.call(u0, top, d), at.call(u1, top, d), at.call(u1, bottom, d), at.call(u0, bottom, d)], fill, extra)
	var flat := func(d0: float, d1: float, fill: String) -> String:
		return _poly([at.call(-900.0, H, d0), at.call(900.0, H, d0), at.call(900.0, H, d1), at.call(-900.0, H, d1)], fill)
	# Light from the upper left: what faces right, on the left of the view, is in the shade.
	var shade := func(u: float, top: float, bottom: float, d0: float, d1: float) -> String:
		return plane.call(u, top, bottom, d0, d1, "#000000", 'opacity="0.16"') if s * u < 0.0 else ""
	var winter := Season.is_winter()
	var concrete := "#E9EDF0" if winter else "#A9A59D"
	var palettes := Season.tree_palettes()
	var vines := vine_colors()
	var shrubs := shrub_colors()
	var street_tree := func(u: float, d: float, size: float) -> String:
		var foot: Vector2 = at.call(u, H, d)
		var crown: Vector2 = at.call(u, 210.0, d)
		var pick := rng.randi()
		var pal: Array = [] if palettes.is_empty() else palettes[pick % palettes.size()]
		return _distant_tree(rng, foot, crown, size / (1.0 + d), pal, "#5E4A3C")
	# The sky over the avenue, hiding the distant city from the T's side, fading in from above and out over the long lane.
	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.35, 0.62, 0.82, 1.0])
	grad.colors = Season.sky()
	var stops := ""
	for k in 5:
		var sky_y := lerpf(150.0, 520.0, k / 4.0)
		stops += '<stop offset="%.2f" stop-color="#%s" stop-opacity="%.2f"/>' % [k / 4.0, grad.sample(sky_y / 720.0).to_html(false), clampf((sky_y - 150.0) / 180.0, 0.0, 1.0)]
	var far := '<defs><linearGradient id="teesky" x1="0" y1="0" x2="0" y2="1">%s</linearGradient></defs>' % stops
	var strip := 0.0
	while strip < w:
		var past: float = (strip - vx - half) if s > 0.0 else (vx - half - strip)
		far += '<rect x="%.1f" y="150" width="12" height="370" fill="url(#teesky)" opacity="%.2f"/>' % [strip, clampf(1.0 - (past + 130.0) / 130.0, 0.0, 1.0)]
		strip += 12.0
	# The lanes of all the blocks are in line: over the avenue this one carries on, and so on to the vanishing point.
	far += _lanes_beyond(at, half, FACADES)
	# Across the avenue: its plexes either side of that lane's entrance, then the sidewalks and the road, far to near.
	var tops: Array[float] = [268.0, 300.0, 250.0, 284.0, 262.0, 296.0]
	var bricks: Array[String] = ["#8E3A2F", "#B4513F", "#9C6B4E", "#A8473A", "#7E4436", "#B5603F"]
	for n in 6:
		var u0: float = half + (n / 2) * 300.0 if n % 2 == 0 else -half - (n / 2 + 1) * 300.0
		var u1 := u0 + 300.0
		var top: float = tops[n % tops.size()]
		var brick: String = bricks[n % bricks.size()]
		far += facing.call(u0, u1, top, H, FACADES, brick)
		far += facing.call(u0 - 4.0, u1 + 4.0, top - 12.0, top + 6.0, FACADES, "#55585C")
		for floor_i in 2:
			var fy := H - 70.0 - floor_i * 118.0
			for col in 3:
				var cx := lerpf(u0 + 56.0, u1 - 56.0, col / 2.0)
				if floor_i == 0 and col == 1:
					far += facing.call(cx - 22.0, cx + 22.0, fy - 34.0, H - 30.0, FACADES, "#5E3B26")
					far += facing.call(cx - 30.0, cx + 30.0, H - 30.0, H, FACADES, "#B9B2A4")
					continue
				far += facing.call(cx - 26.0, cx + 26.0, fy - 62.0, fy + 8.0, FACADES, "#EDE9DF")
				far += facing.call(cx - 20.0, cx + 20.0, fy - 56.0, fy + 2.0, FACADES, "#7F97A8")
		far += facing.call(u0 + 10.0, u1 - 10.0, H - 136.0, H - 124.0, FACADES, "#2A2622")
	far += flat.call(FAR_ROAD, FACADES, "#F0F2F4" if winter else "#BDB7AC")
	far += flat.call(ROAD, FAR_ROAD, "#D5DADF" if winter else "#4F5054")
	far += flat.call(CURB, ROAD, "#F0F2F4" if winter else "#BDB7AC")
	far += flat.call(ROAD, ROAD + 0.012, "#8E8A80")
	var dash := -420.0
	while dash < 420.0:
		far += _poly([at.call(dash, H, 1.62), at.call(dash + 60.0, H, 1.62), at.call(dash + 60.0, H, 1.66), at.call(dash, H, 1.66)], "#F2C230")
		dash += 130.0
	far += street_tree.call(-half * 1.5, FAR_ROAD + 0.03, 150.0)
	far += street_tree.call(half * 1.6, FAR_ROAD + 0.03, 130.0)
	# The far side's yards: the backs of its buildings seen along them, with their galleries.
	var back_u := -half - 170.0
	var d := NEAREST
	while d < YARD:
		var d1 := minf(d + rng.randf_range(0.38, 0.6), YARD)
		var top := H - rng.randf_range(250.0, 340.0)
		var siding := rng.randf() < 0.35
		var wall: String = PropArt._pick(rng, SIDINGS) if siding else PropArt._pick(rng, BRICKS)
		var wood: String = PropArt._pick(rng, WOODS)
		far += plane.call(back_u, top, H, d, d1, wall)
		far += shade.call(back_u, top, H, d, d1)
		far += plane.call(back_u, top - 8.0, top + 4.0, d, d1, "#55585C")
		for floor_y: float in [top + 30.0, top + 148.0]:
			var wd := d + 0.04
			while wd + 0.09 < d1:
				far += plane.call(back_u, floor_y - 3.0, floor_y + 73.0, wd - 0.006, wd + 0.096, "#F2F0EA")
				far += plane.call(back_u, floor_y, floor_y + 70.0, wd, wd + 0.09, "#7F97A8")
				wd += 0.2
		for rail: float in [top + 104.0, top + 222.0]:
			far += _line(at.call(back_u + 34.0, rail, d), at.call(back_u + 34.0, rail, d1), wood, maxf(6.0 / (1.0 + d), 1.0))
			far += _line(at.call(back_u + 34.0, rail + 34.0, d), at.call(back_u + 34.0, rail + 34.0, d1), wood, maxf(6.0 / (1.0 + d), 1.0))
		var post := d
		while post < d1:
			far += _line(at.call(back_u + 34.0, top + 70.0, post), at.call(back_u + 34.0, H, post), wood, maxf(5.0 / (1.0 + post), 1.0))
			post += (d1 - d) / 3.0
		d = d1
	# The back of the building on the avenue, over its yard, then the two side walls down to the sidewalk.
	var theirs_brick: String = "#" + (theirs.color as Color).to_html(false)
	var ours_brick: String = "#" + (ours.color as Color).to_html(false)
	far += facing.call(back_u, -half, float(theirs.top), H, YARD, theirs_brick)
	far += facing.call(back_u, -half, float(theirs.top), H, YARD, "#000000", 'opacity="0.1"')
	far += facing.call(back_u, -half, float(theirs.top) - 8.0, float(theirs.top) + 4.0, YARD, "#55585C")
	var side := func(u: float, top: float, d0: float, d1: float, brick: String, windows: bool) -> String:
		var out: String = plane.call(u, top, H, d0, d1, brick)
		var course := top + 12.0
		while course < H:
			out += _line(at.call(u, course, d0), at.call(u, course, d1), _light(brick, 0.22), maxf(1.1 / (1.0 + d0), 0.4), 'opacity="0.45"')
			course += 14.0
		out += plane.call(u, top - 8.0, top + 4.0, d0, d1, "#55585C")
		if windows:
			for f in int(round((H - top - 40.0) / 118.0)):
				var base := H - 62.0 - f * 118.0
				var wd := d0 + 0.14
				while wd + 0.1 < d1:
					out += plane.call(u, base - 74.0, base - 67.0, wd - 0.012, wd + 0.112, "#C9C2B2")
					out += plane.call(u, base - 67.0, base - 5.0, wd, wd + 0.1, "#EDE9DF")
					out += plane.call(u, base - 62.0, base - 10.0, wd + 0.012, wd + 0.088, "#7F97A8")
					out += plane.call(u, base - 5.0, base + 1.0, wd - 0.012, wd + 0.112, "#C9C2B2")
					wd += 0.26
		return out + shade.call(u, top, H, d0, d1)
	far += side.call(-half, float(theirs.top), YARD, CURB, theirs_brick, theirs.kind != "garage")
	far += side.call(half, float(ours.top), 0.0, CURB, ours_brick, ours.kind != "garage")
	# A yard tree on the far side, over the fence.
	far += street_tree.call(-half - 85.0, 0.08, 135.0)
	# The concrete up to the sidewalk, the slab joints across it, the crack and its weeds down the middle.
	far += _poly([at.call(-half, H, 0.0), at.call(half, H, 0.0), at.call(half, H, CURB), at.call(-half, H, CURB)], concrete)
	var joint := 0.16
	while joint < CURB:
		far += _line(at.call(-half, H, joint), at.call(half, H, joint), _dark(concrete, 0.2), maxf(1.6 / (1.0 + joint), 0.5))
		joint += 0.18 * (1.0 + joint)
	far += _line(at.call(0.0, H, 0.0), at.call(0.0, H, CURB), _dark(concrete, 0.45), 1.6)
	var weedy := func(d0: float, d1: float) -> String:
		var out := ""
		var at_d := d0
		while at_d < d1:
			var p: Vector2 = at.call(rng.randf_range(-12.0, 12.0), H, at_d)
			var tuft := _grass(rng, p, rng.randf_range(10.0, 18.0) / (1.0 + at_d), 7)
			if not winter:
				out += tuft
			at_d += 0.06 * (1.0 + at_d)
		return out
	far += weedy.call(0.0, CURB)
	# Board fences along both yards, plank by plank; the far side's carries on past us, in the near part.
	var planks := func(u: float, d0: float, d1: float) -> String:
		var out := ""
		var at_d := d0
		var top := H - FENCE
		var i := 0
		while at_d < d1:
			var next := minf(at_d + 0.042 * (1.0 + at_d), d1)
			var tone: String = BOARDS[(i * 3 + int(absf(u))) % BOARDS.size()]
			out += plane.call(u, top - (4.0 if i % 2 == 0 else 0.0), H, at_d, next, tone)
			out += _line(at.call(u, top, next), at.call(u, H, next), _dark(tone, 0.34), maxf(1.4 / (1.0 + next), 0.5))
			at_d = next
			i += 1
		out += plane.call(u, top + 18.0, top + 30.0, d0, d1, _dark(BOARDS[1], 0.18))
		out += plane.call(u, H - 44.0, H - 32.0, d0, d1, _dark(BOARDS[1], 0.18))
		out += plane.call(u, H - 22.0, H, d0, d1, "#2A2418", 'opacity="0.2"')
		if winter:
			out += plane.call(u, top - 5.0, top + 2.0, d0, d1, "#F4F6F8")
		return out + shade.call(u, top - 4.0, H, d0, d1)
	# Creeper along the top of a fence, in runs, and grass at its foot (close by, nothing bigger: a shrub there would fill the view).
	var creeper := func(u: float, d0: float, d1: float, chance: float) -> String:
		var out := ""
		var md := d0
		while md < d1:
			var k := 1.0 + md
			var patch := _foliage(rng, at.call(u, H - FENCE + 4.0, md), Vector2(34.0, 15.0) / k, vines, clampf(7.0 / k, 2.2, 12.0), 22)
			var tall := _grass(rng, at.call(u - signf(u) * rng.randf_range(4.0, 24.0), H, md), 26.0 / k, 8)
			if rng.randf() < chance:
				out += patch
			if rng.randf() < 0.5:
				out += tall
			md += 0.05 * k
		return out
	# Shrubs at the foot of a fence (a green lane has more of them), between depths d0 and d1.
	var shrubbery := func(u: float, d0: float, d1: float, count: int) -> String:
		var out := ""
		for k in count:
			var md := lerpf(d0, d1, (k + rng.randf()) / count)
			var r := Vector2(rng.randf_range(40.0, 60.0), rng.randf_range(40.0, 64.0)) / (1.0 + md)
			var foot: Vector2 = at.call(u - signf(u) * rng.randf_range(6.0, 26.0), H, md)
			out += _foliage(rng, foot - Vector2(0, r.y * 0.8), r, shrubs, maxf(8.0 / (1.0 + md), 2.4), 80)
		return out
	far += planks.call(-half, 0.0, YARD)
	far += planks.call(half, 0.0, YARD)
	far += creeper.call(-half, 0.0, YARD, 0.7 if lush else 0.45)
	far += creeper.call(half, 0.0, YARD, 0.7 if lush else 0.45)
	far += shrubbery.call(-half, 0.14, YARD, 3 if lush else 1)
	far += shrubbery.call(half, 0.14, YARD, 3 if lush else 1)
	# The neighbours' bins against the far fence.
	for bin: Array in [[0.3, "#2F6DB5", 8.0], [0.2, "#5B4A3A", 8.0]]:
		far += facing.call(-half + bin[2], -half + bin[2] + 52.0, H - 82.0, H, bin[0], bin[1])
		far += facing.call(-half + bin[2] - 3.0, -half + bin[2] + 55.0, H - 88.0, H - 78.0, bin[0], _dark(bin[1], 0.25))
		far += facing.call(-half + bin[2], -half + bin[2] + 52.0, H - 16.0, H, bin[0], "#000000", 'opacity="0.2"')
	# A pole at the lane's end on the far side, its wires going off over the corner.
	var pole_top: Vector2 = at.call(-half + 10.0, 70.0, 0.9)
	far += _line(at.call(-half + 10.0, H, 0.9), pole_top, "#6E5A48", 6.0)
	far += _line(pole_top + Vector2(-18, 5), pole_top + Vector2(18, 5), "#5E4A3C", 3.0)
	for off: float in [-15.0, 0.0, 15.0]:
		var a := pole_top + Vector2(off, 4.0)
		var b := Vector2(vx + s * (half + 24.0) + off, 100.0)
		far += '<path d="M%.1f %.1f Q%.1f %.1f %.1f %.1f" stroke="#2A2622" stroke-width="1.3" fill="none"/>' % [a.x, a.y, (a.x + b.x) / 2.0, (a.y + b.y) / 2.0 + 10.0, b.x, b.y]
	# The near part: the slabs and the weeds coming toward us, then the far side's fence going off past us, bins against it.
	var near := ""
	for jd: float in [-0.09, -0.2, -0.31, -0.41]:
		near += _line(at.call(-half, H, jd), at.call(half, H, jd), _dark(concrete, 0.16), 2.0)
	near += _line(at.call(half, H, 0.0), at.call(half, H, -0.46), _dark(concrete, 0.2), 2.0)
	near += _line(at.call(0.0, H, 0.0), at.call(0.0, H, -0.46), _dark(concrete, 0.45), 2.0)
	near += weedy.call(-0.46, 0.0)
	var litter := Season.litter()
	for i in 70:
		var ld := rng.randf_range(-0.5, 0.0)
		var p: Vector2 = at.call(-half + rng.randf_range(2.0, 34.0), H, ld)
		var size := rng.randf_range(5.0, 8.0) / (1.0 + ld)
		var turn := rng.randf() * TAU
		var pick := rng.randf()
		if float(i % 10) / 10.0 < Season.litter_amount() and not litter.is_empty():
			near += _leaf(p, size, turn, "#" + litter[mini(int(pick * litter.size()), litter.size() - 1)].to_html(false))
	near += planks.call(-half, NEAREST, 0.0)
	near += creeper.call(-half, -0.55, 0.0, 0.7 if lush else 0.4)
	var pad := "" if s > 0.0 else '<g transform="translate(%.1f 0)">' % TEE_PAD
	var end := "" if s > 0.0 else "</g>"
	return [_tex(w + TEE_PAD, pad + far + end), PropArt.tex(PropArt._svg(w + TEE_PAD, H_NEAR, pad + near + end))]


## Another lane running away from us between the yards, as in the photos: one-point perspective on CrossStreet's horizon.
## Far to near: sky down the gap, the far lane's fences that close it, under its trees, the backs of the plexes either side with their galleries, trees arching over, the cracked concrete with its strip
## of weeds down the middle and leaves drifted along the edges, then fences, sheds and garages one after another, poles
## and wires, shrubs spilling onto the concrete and creeper over the fences.
static func junction(rng: RandomNumberGenerator, w: float) -> ImageTexture:
	const FAR_D := 14.0
	var vp := Vector2(w / 2.0, CrossStreet.HORIZON_Y)
	var at := func(p: Vector2, d: float) -> Vector2: return vp + (p - vp) / (1.0 + d)
	var hazed := func(c: String, d: float) -> String: return "#" + Color(c).lerp(Color("#CFD6DC"), clampf(d / FAR_D, 0.0, 0.6)).to_html(false)
	var hazy_all := func(colors: Array, d: float) -> Array:
		var out := []
		for c in colors:
			out.append(hazed.call(c, d))
		return out
	var quad := func(x: float, top: float, bottom: float, d0: float, d1: float, fill: String, extra := "") -> String:
		return _poly([at.call(Vector2(x, top), d0), at.call(Vector2(x, top), d1), at.call(Vector2(x, bottom), d1), at.call(Vector2(x, bottom), d0)], fill, extra)
	var winter := Season.is_winter()
	# The sky down the gap, hiding the distant city behind it, fading in from above.
	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.35, 0.62, 0.82, 1.0])
	grad.colors = Season.sky()
	var stops := ""
	for k in 5:
		var y := lerpf(120.0, 470.0, k / 4.0)
		var c := grad.sample(y / 720.0)
		stops += '<stop offset="%.2f" stop-color="#%s" stop-opacity="%.2f"/>' % [k / 4.0, c.to_html(false), clampf((y - 120.0) / 160.0, 0.0, 1.0)]
	var s := '<defs><linearGradient id="gapsky" x1="0" y1="0" x2="0" y2="1">%s</linearGradient></defs>' % stops
	var strip := 0.0
	while strip < w:
		s += '<rect x="%.1f" y="120" width="12" height="350" fill="url(#gapsky)" opacity="%.2f"/>' % [strip, clampf(minf(strip, w - strip) / 80.0, 0.0, 1.0)]
		strip += 12.0
	# What closes the far end: the far lane's fences.
	var f0: Vector2 = at.call(Vector2(-120.0, H - 175.0), FAR_D)
	var f1: Vector2 = at.call(Vector2(w + 120.0, H), FAR_D)
	s += _rect(f0.x, f0.y, f1.x - f0.x, f1.y - f0.y, hazed.call(BOARDS[0], FAR_D))
	# The backs of the plexes along the yards, either side, far to near.
	var rows := []
	for side: float in [-1.0, 1.0]:
		var d := 1.0
		while d < FAR_D:
			var d1 := (1.0 + d) * rng.randf_range(1.32, 1.6) - 1.0
			var x := w / 2.0 + side * 320.0
			var top := H - rng.randf_range(240.0, 340.0)
			var brick: String = hazed.call(PropArt._pick(rng, SIDINGS if rng.randf() < 0.35 else BRICKS), d)
			var row: String = quad.call(x, top, H - 60.0, d, d1, brick)
			row += quad.call(x, top, H - 60.0, d, d1, "#000000", 'opacity="0.14"')
			row += quad.call(x, top - 6.0, top + 4.0, d, d1, hazed.call("#55585C", d))
			if d < 6.0:
				for k in 2:
					var wd := lerpf(d, d1, 0.25 + 0.5 * k)
					var we := wd + (d1 - d) * 0.14
					for floor_y: float in [top + 30.0, top + 130.0]:
						row += quad.call(x, floor_y, floor_y + 60.0, wd, we, hazed.call("#7F97A8", d))
				var wood: String = hazed.call(PropArt._pick(rng, WOODS), d)
				for rail: float in [top + 96.0, top + 196.0]:
					row += _line(at.call(Vector2(x, rail), d), at.call(Vector2(x, rail), d1), wood, maxf(8.0 / (1.0 + d), 1.0))
				var post := d
				while post < d1:
					row += _line(at.call(Vector2(x, top + 70.0), post), at.call(Vector2(x, H - 60.0), post), wood, maxf(5.0 / (1.0 + post), 0.8))
					post += (d1 - d) / 3.0
			rows.append([d, row])
			d = d1
	rows.sort_custom(func(p, q): return p[0] > q[0])
	for row in rows:
		s += row[1]
	# Trees in the yards arching toward the middle, far to near.
	var palettes := Season.tree_palettes()
	var trees := []
	for side: float in [-1.0, 1.0]:
		for base_d: float in [1.4, 2.9, 5.6, 10.0]:
			var d := base_d * rng.randf_range(0.9, 1.15)
			var x := w / 2.0 + side * rng.randf_range(190.0, 250.0)
			var foot: Vector2 = at.call(Vector2(x, H - 60.0), d)
			var crown: Vector2 = at.call(Vector2(x - side * rng.randf_range(30.0, 70.0), rng.randf_range(170.0, 250.0)), d)
			var size := rng.randf_range(120.0, 170.0) / (1.0 + d)
			var pal_i := rng.randi()
			var pal: Array = [] if palettes.is_empty() else hazy_all.call(palettes[pal_i % palettes.size()], d)
			var tree := _distant_tree(rng, foot, crown, size, pal, hazed.call("#5E4A3C", d))
			trees.append([d, tree])
	trees.sort_custom(func(p, q): return p[0] > q[0])
	for tree in trees:
		s += tree[1]
	# The concrete, lighter with distance, sun patches and slab joints.
	var concrete := "#E9EDF0" if winter else "#A9A59D"
	s += _poly([Vector2(8, H), Vector2(w - 8, H), at.call(Vector2(w - 8, H), FAR_D), at.call(Vector2(8, H), FAR_D)], concrete)
	s += _poly([at.call(Vector2(8, H), 1.5), at.call(Vector2(w - 8, H), 1.5), at.call(Vector2(w - 8, H), FAR_D), at.call(Vector2(8, H), FAR_D)], "#E8DCC4", 'opacity="0.35"')
	var joint := 0.18
	while joint < FAR_D:
		s += _line(at.call(Vector2(8, H), joint), at.call(Vector2(w - 8, H), joint), _dark(concrete, 0.2), maxf(1.6 / (1.0 + joint), 0.5))
		joint += 0.3 * (1.0 + joint)
	for k in 3:
		var from := rng.randf_range(0.05, 1.5)
		var cx := w / 2.0 + rng.randf_range(-90.0, 90.0)
		var crack := "M%.1f %.1f" % [at.call(Vector2(cx, H), from).x, at.call(Vector2(cx, H), from).y]
		for n in 6:
			var q: Vector2 = at.call(Vector2(cx + rng.randf_range(-14.0, 14.0), H), from + n * 0.12)
			crack += " L%.1f %.1f" % [q.x, q.y]
		s += '<path d="%s" stroke="%s" stroke-width="1.1" fill="none"/>' % [crack, _dark(concrete, 0.4)]
	# Down the middle: the crack and its strip of weeds.
	s += _line(Vector2(w / 2.0, H), vp, _dark(concrete, 0.45), 1.6)
	var weeds := grass_colors()
	var weed := 0.0
	while weed < FAR_D * 0.7:
		var p: Vector2 = at.call(Vector2(w / 2.0 + rng.randf_range(-9.0, 9.0), H), weed)
		for k in 8:
			var size := rng.randf_range(8.0, 14.0) / (1.0 + weed)
			var turn := rng.randf_range(-1.4, 1.4)
			var tone := _tone(rng, weeds)
			if not winter:
				s += _leaf(p, maxf(size, 1.4), turn, tone)
		weed += 0.09 * (1.0 + weed)
	# Leaves drifted along the edges, and a few strewn over the concrete.
	var litter := Season.litter()
	for i in 90:
		var edge := i < 66
		var d := pow(rng.randf(), 2.2) * FAR_D * 0.6
		var x: float = (8.0 + rng.randf_range(0.0, 34.0) if i % 2 == 0 else w - 8.0 - rng.randf_range(0.0, 34.0)) if edge else rng.randf_range(20.0, w - 20.0)
		var p: Vector2 = at.call(Vector2(x, H), d)
		var size := rng.randf_range(5.0, 8.0) / (1.0 + d)
		var turn := rng.randf() * TAU
		var pick := rng.randf()
		if float(i % 10) / 10.0 < Season.litter_amount() and not litter.is_empty():
			s += _leaf(p, maxf(size, 1.2), turn, "#" + litter[mini(int(pick * litter.size()), litter.size() - 1)].to_html(false))
	# Then, far to near on both sides: fences, sheds and garages, poles, shrubs, creeper, grass.
	var near := []
	var vines := vine_colors()
	var shrubs := shrub_colors()
	var pole_side := -1.0 if rng.randf() < 0.5 else 1.0
	for side: float in [-1.0, 1.0]:
		var x := 0.0 if side < 0.0 else w
		var d := 0.0
		var first := true
		while d < FAR_D:
			var d1 := (1.0 + d) * rng.randf_range(1.35, 1.75) - 1.0
			var kind: String = "boards" if first else PropArt._pick(rng, ["boards", "chainlink", "picket", "tole", "shed", "boards"])
			first = false
			var height: float = {"boards": 175.0, "chainlink": 150.0, "picket": 108.0, "tole": 225.0, "shed": 240.0}[kind]
			var top := H - height
			var seg := ""
			match kind:
				"boards":
					var c: String = hazed.call(PropArt._pick(rng, BOARDS), d)
					seg += quad.call(x, top, H, d, d1, c)
					var fd := d
					while fd < d1:
						seg += _line(at.call(Vector2(x, top), fd), at.call(Vector2(x, H), fd), _dark(c, 0.32), maxf(1.2 / (1.0 + fd), 0.4))
						fd += 0.05 * (1.0 + fd)
				"chainlink":
					var c: String = hazed.call("#2F5E3E", d)
					seg += quad.call(x, top, H, d, d1, c)
					for rail: float in [0.25, 0.5, 0.75]:
						seg += _line(at.call(Vector2(x, lerpf(top, H, rail)), d), at.call(Vector2(x, lerpf(top, H, rail)), d1), _light(c, 0.18), maxf(1.6 / (1.0 + d), 0.4))
					var fd := d
					while fd < d1:
						seg += _line(at.call(Vector2(x, top - 4.0), fd), at.call(Vector2(x, H), fd), _dark(c, 0.3), maxf(3.5 / (1.0 + fd), 0.6))
						fd += 0.22 * (1.0 + fd)
				"picket":
					var c: String = hazed.call("#C9A877", d)
					seg += quad.call(x, top + 22.0, top + 30.0, d, d1, _dark(c, 0.2))
					seg += quad.call(x, H - 34.0, H - 26.0, d, d1, _dark(c, 0.2))
					var fd := d
					while fd < d1:
						var fe := fd + 0.018 * (1.0 + fd)
						seg += quad.call(x, top, H, fd, fe, c)
						fd += 0.04 * (1.0 + fd)
				"tole":
					var c: String = hazed.call(PropArt._pick(rng, TOLE + PAINTED_TOLE), d)
					seg += quad.call(x, top, H, d, d1, c)
					seg += quad.call(x, top - 8.0, top + 2.0, d, d1, hazed.call("#55585C", d))
					for n in 7:
						var y := lerpf(top + 12.0, H, n / 7.0)
						seg += _line(at.call(Vector2(x, y), d), at.call(Vector2(x, y), d1), _dark(c, 0.2), maxf(1.0 / (1.0 + d), 0.4))
				"shed":
					var c: String = hazed.call(PropArt._pick(rng, ["#E9E6DF", "#4FA3A0", "#C9D3D1", "#B5893A"]), d)
					seg += quad.call(x, top, H, d, d1, c)
					seg += quad.call(x, top - 10.0, top + 2.0, d, d1, hazed.call("#55585C", d))
					var fd := d
					while fd < d1:
						seg += _line(at.call(Vector2(x, top), fd), at.call(Vector2(x, H), fd), _dark(c, 0.18), maxf(1.0 / (1.0 + fd), 0.4))
						fd += 0.1 * (1.0 + fd)
					var wd := lerpf(d, d1, 0.3)
					var we := lerpf(d, d1, 0.55)
					seg += quad.call(x, top + 40.0, top + 100.0, wd, we, hazed.call("#7F97A8", d), 'stroke="#F2F0EA" stroke-width="%.1f"' % maxf(3.0 / (1.0 + d), 0.5))
			# Shade on the fences away from the sun, a dark foot, snow along the top.
			if side > 0.0:
				seg += quad.call(x, top, H, d, d1, "#000000", 'opacity="0.1"')
			seg += quad.call(x, H - 22.0, H, d, d1, "#2A2418", 'opacity="0.18"')
			if winter:
				seg += quad.call(x, top - 4.0, top + 2.0, d, d1, "#F4F6F8")
			near.append([d1, seg])
			# Creeper over this stretch, a shed or tôle garage all but swallowed by it now and then.
			var md := lerpf(d, d1, rng.randf_range(0.25, 0.75))
			var creeper := _foliage(rng, at.call(Vector2(x, top + 8.0), md), Vector2(46.0, 22.0) / (1.0 + md), hazy_all.call(vines, md), maxf(9.0 / (1.0 + md), 2.2), int(clampf(50.0 / (1.0 + md), 12.0, 40.0)))
			if rng.randf() < 0.7:
				near.append([md - 0.01, creeper])
			if kind in ["shed", "tole"]:
				var sheet := _foliage(rng, at.call(Vector2(x, top + height * 0.5), md), Vector2(70.0, height * 0.5) / (1.0 + md), hazy_all.call(vines, md), maxf(9.0 / (1.0 + md), 2.2), int(clampf(120.0 / (1.0 + md), 20.0, 80.0)))
				if rng.randf() < 0.5:
					near.append([md - 0.01, sheet])
			d = d1
		# Shrubs spilling onto the concrete, big near us, and ornamental grass.
		for base_d: float in [0.35, 0.8, 1.6, 2.8, 4.6, 7.5]:
			var bd := base_d * rng.randf_range(0.85, 1.2)
			var bx := x - side * rng.randf_range(6.0, 30.0)
			var r := Vector2(rng.randf_range(44.0, 70.0), rng.randf_range(48.0, 78.0)) / (1.0 + bd)
			var foot: Vector2 = at.call(Vector2(bx, H), bd)
			var bush := _foliage(rng, foot - Vector2(0, r.y * 0.8), r, hazy_all.call(shrubs, bd), maxf(10.0 / (1.0 + bd), 2.2), int(clampf(110.0 / (1.0 + bd), 20.0, 70.0)))
			var grass := _grass(rng, at.call(Vector2(x - side * rng.randf_range(10.0, 40.0), H), bd + 0.1), maxf(34.0 / (1.0 + bd), 3.0), 9)
			if rng.randf() < 0.75:
				near.append([bd, bush])
			if rng.randf() < 0.7:
				near.append([bd + 0.1, grass])
	# A blue bin near us.
	var bin_d := rng.randf_range(0.5, 0.9)
	var bin_x := 16.0 if rng.randf() < 0.5 else w - 62.0
	var b0: Vector2 = at.call(Vector2(bin_x, H - 74.0), bin_d)
	var b1: Vector2 = at.call(Vector2(bin_x + 46.0, H), bin_d)
	near.append([bin_d, _rect(b0.x, b0.y, b1.x - b0.x, b1.y - b0.y, "#2F6DB5") + _rect(b0.x - 1.0, b0.y - 2.0, b1.x - b0.x + 2.0, 4.0, "#26588F")])
	# Poles down one side, wires from one to the next and across.
	var tops: Array[Vector2] = []
	for base_d: float in [8.5, 3.6, 1.2]:
		var pd := base_d * rng.randf_range(0.9, 1.1)
		var px := (10.0 if pole_side < 0.0 else w - 10.0)
		var ptop: Vector2 = at.call(Vector2(px, 70.0), pd)
		var pfoot: Vector2 = at.call(Vector2(px, H), pd)
		var thick := maxf(11.0 / (1.0 + pd), 1.2)
		var pole := _line(pfoot, ptop, hazed.call("#6E5A48", pd), thick)
		pole += _line(ptop + Vector2(-34.0, 8.0) / (1.0 + pd), ptop + Vector2(34.0, 8.0) / (1.0 + pd), hazed.call("#5E4A3C", pd), maxf(5.0 / (1.0 + pd), 0.8))
		if not tops.is_empty():
			var wires := ""
			for off: float in [-28.0, 0.0, 28.0]:
				var a: Vector2 = tops[-1] + Vector2(off / (1.0 + base_d * 2.0), 2.0)
				var b := ptop + Vector2(off / (1.0 + pd), 8.0 / (1.0 + pd))
				wires += '<path d="M%.1f %.1f Q%.1f %.1f %.1f %.1f" stroke="#2A2622" stroke-width="%.1f" fill="none"/>' % [a.x, a.y, (a.x + b.x) / 2.0, (a.y + b.y) / 2.0 + 8.0 / (1.0 + pd), b.x, b.y, maxf(1.6 / (1.0 + pd), 0.5)]
			pole = wires + pole
		tops.append(ptop)
		near.append([pd, pole])
	near.sort_custom(func(p, q): return p[0] > q[0])
	for item in near:
		s += item[1]
	return _tex(w, s)
