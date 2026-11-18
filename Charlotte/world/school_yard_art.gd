class_name SchoolYardArt
extends RefCounted
## The schoolyard of école Saint-Jean-de-Brébeuf, drawn as SVG at runtime (scenes/cour_ecole.gd): the school's back wall seen
## from the yard (the same red-brown brick, grey parged base, stone water table and maroon windows as its side on 6e, `ecole_6e`),
## the chain-link fences at both ends with the street beyond, the climbing frame and its slide, the basketball hoop, the bench
## and, in winter, the yard's snow hill. Each texture is in world pixels (raster 1), light from the upper left, the season's
## snow on its ledges. Words (the door's plate) are labels in the scene: SVG text doesn't render in these textures.

const BRICK := "#9A4A35"
const BRICK_DARK := "#7E3A2A"
const MORTAR := "#B88E7A"
const STONE := "#D9D2C2"
const PARGE := "#B5AFA5"
const FRAME := "#6E2A2A"
const SNOW := "#F4F8FC"
const SNOW_SHADE := "#C9D6E6"

## The back wall: its height and where its storeys and its door are (in the texture, whose foot is the yard).
const WALL_H := 470.0
const COPING := 16.0
const BASE_H := 80.0
const FLOOR_H := 122.0
const BAY := 212.0
const DOOR_W := 116.0
const DOOR_H := 132.0


static func _svg(w: float, h: float, body: String) -> String:
	return '<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" viewBox="0 0 %d %d">%s</svg>' % [w, h, w, h, body]


static func _rect(x: float, y: float, w: float, h: float, fill: String, extra := "") -> String:
	return '<rect x="%.1f" y="%.1f" width="%.1f" height="%.1f" fill="%s" %s/>' % [x, y, w, h, fill, extra]


# ── The school's back wall ──────────────────────────────────────

## Canvas w × WALL_H. `door_x` is the middle of the pupils' door, from the left end of the wall.
static func back_wall(w: float, door_x: float, rng: RandomNumberGenerator) -> ImageTexture:
	var h := WALL_H
	var brick_top := COPING
	var table_y := h - BASE_H - 10.0
	var s := '<defs>'
	s += '<linearGradient id="sun" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#FFE7C2" stop-opacity="0.16"/>'
	s += '<stop offset="0.5" stop-color="#FFE7C2" stop-opacity="0"/><stop offset="1" stop-color="#2A1A20" stop-opacity="0.14"/></linearGradient>'
	s += '<linearGradient id="glass" x1="0" y1="0" x2="0.4" y2="1"><stop offset="0" stop-color="#CFE2EE"/><stop offset="0.45" stop-color="#7FA0B8"/>'
	s += '<stop offset="1" stop-color="#3E5466"/></linearGradient>'
	s += '<linearGradient id="drop" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#000" stop-opacity="0.22"/>'
	s += '<stop offset="1" stop-color="#000" stop-opacity="0"/></linearGradient>'
	s += '</defs>'
	# The brick, its courses and a few bricks fired darker or paler.
	s += _rect(0, brick_top, w, table_y - brick_top, BRICK)
	var y := brick_top + 7.0
	while y < table_y:
		s += '<line x1="0" y1="%.1f" x2="%.1f" y2="%.1f" stroke="%s" stroke-width="1" stroke-opacity="0.45"/>' % [y, w, y, MORTAR]
		y += 7.0
	for i in int(w / 6.0):
		var bx := rng.randf_range(0.0, w - 16.0)
		var by := brick_top + float(rng.randi_range(0, int((table_y - brick_top) / 7.0) - 1)) * 7.0 + 1.0
		var tone := BRICK_DARK if rng.randf() < 0.6 else "#B0614A"
		s += _rect(bx, by, 15.0, 5.5, tone, 'fill-opacity="0.55"')
	# The stone coping, its shade on the brick under it, the water table and the parged base.
	s += _rect(0, 0, w, COPING, STONE)
	s += _rect(0, COPING - 3.0, w, 3.0, "#A79E8C")
	s += _rect(0, COPING, w, 14.0, "url(#drop)")
	s += _rect(0, table_y, w, 10.0, STONE)
	s += _rect(0, table_y + 8.0, w, 2.0, "#9C9484")
	s += _rect(0, table_y + 10.0, w, BASE_H, PARGE)
	for i in int(w / 40.0):
		s += _rect(rng.randf_range(0.0, w - 60.0), table_y + rng.randf_range(16.0, BASE_H - 10.0), rng.randf_range(20.0, 70.0), 1.2, "#9E978C", 'fill-opacity="0.5"')
	# The windows: three storeys of them in pairs, one bay after another, the pupils' door in its own bay.
	var bays := int(floor(w / BAY))
	var margin := (w - bays * BAY) / 2.0
	var ground_floor := ""
	for b in bays:
		var cx := margin + BAY * (b + 0.5)
		var at_door := absf(cx - door_x) < BAY * 0.6
		for f in 3:
			if at_door and f == 2:
				continue
			var top := brick_top + 22.0 + f * FLOOR_H
			for k in [-1.0, 1.0]:
				var x0: float = cx + k * 36.0 - 29.0
				s += _window(x0, top, 58.0, 84.0)
				if f == 2:
					ground_floor += _cutouts(x0, top, 58.0, 84.0, rng)
		# A small basement window under each pair, red as on the 5e side.
		if not at_door:
			s += _rect(cx - 30.0, table_y + 26.0, 60.0, 30.0, "#7A2C24")
			s += _rect(cx - 26.0, table_y + 30.0, 52.0, 22.0, "url(#glass)", 'fill-opacity="0.75"')
			s += '<line x1="%.1f" y1="%.1f" x2="%.1f" y2="%.1f" stroke="#7A2C24" stroke-width="3"/>' % [cx, table_y + 30.0, cx, table_y + 52.0]
	s += ground_floor
	s += _door(door_x, h)
	# The yard's electric bell beside the door, and a downpipe at each end.
	s += _bell(door_x - DOOR_W / 2.0 - 46.0, h - BASE_H - 70.0)
	for px in [26.0, w - 30.0]:
		s += _rect(px, COPING, 9.0, h - COPING - 4.0, "#7D7F82")
		s += _rect(px, COPING, 3.0, h - COPING - 4.0, "#A9ABAE")
		for k in 5:
			s += _rect(px - 3.0, COPING + 40.0 + k * 90.0, 15.0, 5.0, "#5F6164")
		s += _rect(px - 6.0, h - 12.0, 21.0, 8.0, "#5F6164")
	s += _rect(0, 0, w, h, "url(#sun)")
	if Season.is_winter():
		s += _snow_line(0.0, w, 0.0, 6.0, rng)
		s += _snow_line(0.0, w, table_y, 4.0, rng)
	return PropArt.tex(_svg(w, h, s))


# A double-hung window in a maroon frame under a flat arch of bricks on end, its stone sill and the shade it throws.
static func _window(x: float, y: float, w: float, h: float) -> String:
	var s := _rect(x - 4.0, y - 10.0, w + 8.0, 10.0, BRICK_DARK)
	for i in 8:
		s += '<line x1="%.1f" y1="%.1f" x2="%.1f" y2="%.1f" stroke="%s" stroke-width="1" stroke-opacity="0.5"/>' % [x - 4.0 + (w + 8.0) * i / 8.0, y - 10.0, x - 4.0 + (w + 8.0) * i / 8.0, y, MORTAR]
	s += _rect(x, y, w, h, FRAME)
	s += _rect(x + 5.0, y + 5.0, w - 10.0, h / 2.0 - 7.0, "url(#glass)")
	s += _rect(x + 5.0, y + h / 2.0 + 2.0, w - 10.0, h / 2.0 - 7.0, "url(#glass)")
	s += _rect(x + 5.0, y + 5.0, 6.0, h - 10.0, "#000", 'fill-opacity="0.12"')
	# A blind half down in the upper sash.
	s += _rect(x + 5.0, y + 5.0, w - 10.0, 12.0, "#E9E2D0", 'fill-opacity="0.9"')
	s += '<polygon points="%.1f,%.1f %.1f,%.1f %.1f,%.1f" fill="#FFFFFF" fill-opacity="0.22"/>' % [x + 8.0, y + 20.0, x + 26.0, y + 20.0, x + 8.0, y + 44.0]
	s += _rect(x - 5.0, y + h, w + 10.0, 7.0, STONE)
	s += _rect(x - 5.0, y + h + 7.0, w + 10.0, 8.0, "url(#drop)")
	if Season.is_winter():
		s += '<path d="M%.1f %.1f q%.1f -6 %.1f 0 z" fill="%s"/>' % [x - 5.0, y + h, (w + 10.0) / 2.0, w + 10.0, SNOW]
	return s


# What the children stuck in the ground-floor windows: snowflakes in winter, leaves in autumn, tulips in spring, suns in summer.
static func _cutouts(x: float, y: float, w: float, h: float, rng: RandomNumberGenerator) -> String:
	var s := ""
	var n := rng.randi_range(1, 3)
	for i in n:
		var cx := x + rng.randf_range(14.0, w - 14.0)
		var cy := y + rng.randf_range(26.0, h - 14.0)
		var r := rng.randf_range(6.0, 9.0)
		var hue: String = ["#FF8A3D", "#FFD23F", "#E04F5F", "#7BC86C", "#5DB6E8"][rng.randi_range(0, 4)]
		match Season.current:
			"winter":
				for k in 3:
					var a := k * PI / 3.0
					s += '<line x1="%.1f" y1="%.1f" x2="%.1f" y2="%.1f" stroke="#FFFFFF" stroke-width="2"/>' % [cx - cos(a) * r, cy - sin(a) * r, cx + cos(a) * r, cy + sin(a) * r]
			"autumn":
				s += '<ellipse cx="%.1f" cy="%.1f" rx="%.1f" ry="%.1f" fill="%s" transform="rotate(%d %.1f %.1f)"/>' % [cx, cy, r, r * 0.55, ["#E2662A", "#D9A21E", "#B8402A"][i % 3], rng.randi_range(-40, 40), cx, cy]
			"spring":
				s += '<path d="M%.1f %.1f l%.1f -%.1f l%.1f %.1f l%.1f -%.1f l%.1f %.1f z" fill="%s"/>' % [cx - r, cy, r * 0.5, r, r * 0.5, r * 0.6, r * 0.5, r * 0.6, r * 0.5, r, hue]
				s += '<line x1="%.1f" y1="%.1f" x2="%.1f" y2="%.1f" stroke="#4E9A44" stroke-width="2"/>' % [cx, cy, cx, cy + r * 1.4]
			_:
				s += '<circle cx="%.1f" cy="%.1f" r="%.1f" fill="#FFD23F"/>' % [cx, cy, r * 0.7]
				for k in 8:
					var a := k * TAU / 8.0
					s += '<line x1="%.1f" y1="%.1f" x2="%.1f" y2="%.1f" stroke="#FFB42E" stroke-width="2"/>' % [cx + cos(a) * r * 0.9, cy + sin(a) * r * 0.9, cx + cos(a) * r * 1.35, cy + sin(a) * r * 1.35]
	return s


# The pupils' door: two red leaves with their wired glass under a transom, a stone surround, a little metal canopy, a step.
static func _door(cx: float, h: float) -> String:
	var x := cx - DOOR_W / 2.0
	var top := h - DOOR_H
	var s := _rect(x - 14.0, top - 40.0, DOOR_W + 28.0, DOOR_H + 40.0, STONE)
	s += _rect(x - 14.0, top - 40.0, 4.0, DOOR_H + 40.0, "#FFFFFF", 'fill-opacity="0.35"')
	s += _rect(x, top - 30.0, DOOR_W, 24.0, "#3C2420")
	s += _rect(x + 4.0, top - 27.0, DOOR_W - 8.0, 18.0, "url(#glass)")
	for k in 5:
		s += '<line x1="%.1f" y1="%.1f" x2="%.1f" y2="%.1f" stroke="#3C2420" stroke-width="2"/>' % [x + DOOR_W * (k + 1) / 6.0, top - 27.0, x + DOOR_W * (k + 1) / 6.0, top - 9.0]
	s += _rect(x, top, DOOR_W, DOOR_H - 6.0, "#3C2420")
	for k in 2:
		var lx := x + 4.0 + k * (DOOR_W / 2.0)
		s += _rect(lx, top + 4.0, DOOR_W / 2.0 - 8.0, DOOR_H - 14.0, "#B3342B")
		s += _rect(lx, top + 4.0, 5.0, DOOR_H - 14.0, "#D05A4E")
		s += _rect(lx + 10.0, top + 14.0, DOOR_W / 2.0 - 28.0, 46.0, "url(#glass)")
		# Wired glass.
		for g in 4:
			s += '<line x1="%.1f" y1="%.1f" x2="%.1f" y2="%.1f" stroke="#2E3B44" stroke-width="0.8" stroke-opacity="0.6"/>' % [lx + 10.0, top + 14.0 + g * 11.5, lx + DOOR_W / 2.0 - 18.0, top + 14.0 + g * 11.5]
		s += _rect(lx + DOOR_W / 2.0 - 22.0 if k == 0 else lx + 6.0, top + 70.0, 10.0, 4.0, "#D8D8D8")
	# The push bars.
	s += _rect(x + 10.0, top + 76.0, DOOR_W - 20.0, 5.0, "#C9CCCF")
	# The canopy over it, and its shade.
	s += '<polygon points="%.1f,%.1f %.1f,%.1f %.1f,%.1f %.1f,%.1f" fill="#4A5258"/>' % [x - 26.0, top - 48.0, x + DOOR_W + 26.0, top - 48.0, x + DOOR_W + 32.0, top - 36.0, x - 32.0, top - 36.0]
	s += _rect(x - 32.0, top - 36.0, DOOR_W + 64.0, 12.0, "url(#drop)")
	if Season.is_winter():
		s += '<path d="M%.1f %.1f q%.1f -9 %.1f 0 z" fill="%s"/>' % [x - 26.0, top - 48.0, (DOOR_W + 52.0) / 2.0, DOOR_W + 52.0, SNOW]
	s += _rect(x - 20.0, h - 8.0, DOOR_W + 40.0, 8.0, "#A8A091")
	return s


# The yard's bell: a red dome on its box, which rings for the end of recess.
static func _bell(cx: float, cy: float) -> String:
	var s := _rect(cx - 8.0, cy + 10.0, 16.0, 12.0, "#5A5E62")
	s += '<circle cx="%.1f" cy="%.1f" r="16" fill="#C8332B"/>' % [cx, cy]
	s += '<circle cx="%.1f" cy="%.1f" r="6" fill="#F07A70" fill-opacity="0.8"/>' % [cx - 6.0, cy - 6.0]
	s += '<circle cx="%.1f" cy="%.1f" r="3" fill="#3A3A3A"/>' % [cx, cy]
	return s


# Snow lying along a ledge: a soft wavy cap with its shaded underside.
static func _snow_line(x0: float, x1: float, y: float, thick: float, rng: RandomNumberGenerator) -> String:
	var d := "M%.1f %.1f" % [x0, y + 2.0]
	var x := x0
	while x < x1:
		var step := rng.randf_range(30.0, 70.0)
		d += " Q%.1f %.1f %.1f %.1f" % [x + step / 2.0, y - thick * rng.randf_range(0.6, 1.3), minf(x + step, x1), y + 1.0]
		x += step
	d += " L%.1f %.1f L%.1f %.1f Z" % [x1, y + 3.0, x0, y + 3.0]
	return '<path d="%s" fill="%s"/>' % [d, SNOW] + _rect(x0, y + 2.0, x1 - x0, 2.0, SNOW_SHADE, 'fill-opacity="0.7"')


# ── The fence at each end, and the street beyond it ─────────────

## Canvas w × 300: across the street beyond the fence, the plexes facing the school, hazy, their windows and balconies; the
## street's sidewalk at their foot. Drawn behind the fence.
static func beyond(w: float, rng: RandomNumberGenerator) -> ImageTexture:
	var h := 300.0
	var sky: PackedColorArray = Season.sky()
	var haze := Color(sky[sky.size() - 1]) if sky.size() > 0 else Color("#DCE6EE")
	var s := ""
	var x := -rng.randf_range(0.0, 60.0)
	var bricks := [Color("#A0553F"), Color("#8E5A44"), Color("#B26A4C"), Color("#7F4A3A"), Color("#C9B8A0")]
	while x < w:
		var bw := rng.randf_range(150.0, 210.0)
		var top := rng.randf_range(40.0, 90.0)
		var c: Color = (bricks[rng.randi_range(0, bricks.size() - 1)] as Color).lerp(haze, 0.45)
		s += _rect(x, top, bw - 4.0, h - top, "#" + c.to_html(false))
		s += _rect(x - 3.0, top - 6.0, bw + 2.0, 8.0, "#" + c.darkened(0.25).to_html(false))
		for f in 2:
			var wy := top + 26.0 + f * 92.0
			for k in 3:
				var wx := x + 18.0 + k * (bw - 40.0) / 3.0
				s += _rect(wx, wy, 30.0, 46.0, "#" + Color("#5C7488").lerp(haze, 0.35).to_html(false))
				s += _rect(wx - 2.0, wy + 46.0, 34.0, 4.0, "#" + c.lightened(0.3).to_html(false))
			if f == 1:
				s += _rect(x + 6.0, wy - 14.0, bw - 16.0, 5.0, "#" + Color("#3A3A3A").lerp(haze, 0.4).to_html(false))
				for k in int((bw - 16.0) / 8.0):
					s += _rect(x + 8.0 + k * 8.0, wy - 34.0, 1.6, 20.0, "#" + Color("#3A3A3A").lerp(haze, 0.45).to_html(false))
		x += bw
	s += _rect(0, h - 26.0, w, 26.0, "#" + Color("#A9A9A6").lerp(haze, 0.3).to_html(false))
	if Season.is_winter():
		s += _rect(0, h - 30.0, w, 8.0, SNOW)
	return PropArt.tex(_svg(w, h, s))


## Canvas w × 230: a run of chain-link fence (posts every ~110 px, top rail, the diamond mesh). `gate_at` ≥ 0 leaves an open
## gate there (its leaf swung back against the fence).
static func fence(w: float, gate_at := -1.0) -> ImageTexture:
	var h := 230.0
	var top := 26.0
	var gate_w := 96.0
	var s := ""
	var mesh := ""
	var d := 14.0
	var k := -h
	while k < w + h:
		mesh += "M%.1f %.1f L%.1f %.1f " % [k, top, k + (h - top), h]
		mesh += "M%.1f %.1f L%.1f %.1f " % [k + (h - top), top, k, h]
		k += d
	var clip := '<clipPath id="m"><rect x="0" y="%.1f" width="%.1f" height="%.1f"/></clipPath>' % [top, w, h - top]
	if gate_at >= 0.0:
		clip = '<clipPath id="m"><rect x="0" y="%.1f" width="%.1f" height="%.1f"/><rect x="%.1f" y="%.1f" width="%.1f" height="%.1f"/></clipPath>' % [
			top, gate_at - gate_w / 2.0, h - top, gate_at + gate_w / 2.0, top, w - gate_at - gate_w / 2.0, h - top]
	s += '<defs>%s</defs>' % clip
	s += '<path d="%s" stroke="#8E979C" stroke-width="1.3" fill="none" clip-path="url(#m)"/>' % mesh
	var posts: Array[float] = []
	var n := maxi(int(w / 110.0), 1)
	for i in n + 1:
		posts.append(w * i / n)
	if gate_at >= 0.0:
		posts.append(gate_at - gate_w / 2.0)
		posts.append(gate_at + gate_w / 2.0)
	for px in posts:
		var x := clampf(px, 4.0, w - 4.0)
		s += _rect(x - 4.0, top - 6.0, 8.0, h - top + 6.0, "#6E777C")
		s += _rect(x - 4.0, top - 6.0, 3.0, h - top + 6.0, "#A9B1B5")
		s += '<circle cx="%.1f" cy="%.1f" r="6" fill="#6E777C"/>' % [x, top - 6.0]
	if gate_at >= 0.0:
		s += _rect(0, top, gate_at - gate_w / 2.0, 5.0, "#7E878C")
		s += _rect(gate_at + gate_w / 2.0, top, w - gate_at - gate_w / 2.0, 5.0, "#7E878C")
		# The open leaf, swung back toward us against the fence: narrower, a frame round its mesh.
		var gx := gate_at + gate_w / 2.0 + 4.0
		s += '<rect x="%.1f" y="%.1f" width="36" height="%.1f" fill="none" stroke="#6E777C" stroke-width="5"/>' % [gx, top + 8.0, h - top - 14.0]
		s += '<line x1="%.1f" y1="%.1f" x2="%.1f" y2="%.1f" stroke="#8E979C" stroke-width="1.2"/>' % [gx, top + 8.0, gx + 36.0, h - 6.0]
	else:
		s += _rect(0, top, w, 5.0, "#7E878C")
	if Season.is_winter():
		s += _rect(0, h - 22.0, w, 22.0, SNOW)
		s += '<path d="M0 %.1f Q%.1f %.1f %.1f %.1f L%.1f %.1f L0 %.1f Z" fill="%s"/>' % [h - 22.0, w / 2.0, h - 44.0, w, h - 22.0, w, h, h, SNOW]
	return PropArt.tex(_svg(w, h, s))


# ── The yard's furniture ────────────────────────────────────────

## Canvas 340 × 260 (foot on the bottom edge): the climbing frame: two blue towers with their deck, a red roof, a yellow slide
## down to the right, a ladder and a climbing wall with its coloured holds on the left.
static func climbing_frame() -> ImageTexture:
	var w := 340.0
	var h := 260.0
	var deck := 150.0
	var s := '<defs><linearGradient id="slide" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#FFE066"/><stop offset="1" stop-color="#E8A90F"/></linearGradient></defs>'
	s += '<ellipse cx="170" cy="%.1f" rx="160" ry="9" fill="#000" fill-opacity="0.18"/>' % [h - 4.0]
	# Posts and the deck.
	for px in [70.0, 190.0]:
		s += _rect(px - 6.0, 38.0, 12.0, h - 38.0, "#2F6FB5")
		s += _rect(px - 6.0, 38.0, 4.0, h - 38.0, "#5E97D6")
	s += _rect(60.0, deck, 140.0, 12.0, "#6B4A32")
	s += _rect(60.0, deck, 140.0, 3.0, "#8E6A4C")
	# The rail round the deck and the roof over it.
	for k in 7:
		s += _rect(72.0 + k * 19.0, deck - 34.0, 3.0, 34.0, "#2F6FB5")
	s += _rect(64.0, deck - 36.0, 132.0, 5.0, "#2F6FB5")
	s += '<polygon points="52,44 130,6 208,44" fill="#D9342B"/><polygon points="52,44 130,6 130,44" fill="#E8574E"/>'
	# The slide, curving down to the right.
	s += '<path d="M196 %.1f C250 %.1f 260 %.1f 330 %.1f L330 %.1f C258 %.1f 246 %.1f 196 %.1f Z" fill="url(#slide)" stroke="#C78B0B" stroke-width="2"/>' % [
		deck - 6.0, deck, h - 40.0, h - 22.0, h - 8.0, h - 26.0, deck + 16.0, deck + 14.0]
	# The ladder on the left, and the climbing wall under the deck.
	s += _rect(12.0, deck - 30.0, 6.0, h - deck + 30.0, "#2F6FB5")
	s += _rect(46.0, deck - 30.0, 6.0, h - deck + 30.0, "#2F6FB5")
	for k in 5:
		s += _rect(12.0, deck + k * 22.0 - 16.0, 40.0, 4.0, "#5E97D6")
	s += _rect(88.0, deck + 14.0, 84.0, h - deck - 18.0, "#3FA36B")
	var holds := ["#FFD23F", "#E04F5F", "#7E57C2", "#FF8A3D"]
	for k in 9:
		s += '<circle cx="%.1f" cy="%.1f" r="4.5" fill="%s"/>' % [100.0 + (k * 37) % 64, deck + 26.0 + (k * 23) % 70, holds[k % 4]]
	if Season.is_winter():
		s += '<path d="M52 44 L130 6 L208 44 L200 40 L130 12 L60 40 Z" fill="%s"/>' % SNOW
		s += _rect(60.0, deck - 5.0, 140.0, 6.0, SNOW)
	return PropArt.tex(_svg(w, h, s))


## Canvas 170 × 330 (foot on the bottom edge, the pole at x 40): the basketball hoop: a grey pole bent forward, the white
## backboard with its red square, the orange rim and its net.
static func hoop() -> ImageTexture:
	var w := 170.0
	var h := 330.0
	var s := '<ellipse cx="40" cy="%.1f" rx="26" ry="5" fill="#000" fill-opacity="0.2"/>' % [h - 3.0]
	s += _rect(34.0, 70.0, 12.0, h - 72.0, "#6E777C")
	s += _rect(34.0, 70.0, 4.0, h - 72.0, "#A9B1B5")
	s += '<path d="M40 76 Q40 40 80 40 L96 40" stroke="#6E777C" stroke-width="10" fill="none"/>'
	s += _rect(86.0, 8.0, 80.0, 60.0, "#F4F4F0", 'stroke="#9AA0A4" stroke-width="2"')
	s += _rect(112.0, 30.0, 28.0, 22.0, "none", 'stroke="#D9342B" stroke-width="3"')
	s += '<ellipse cx="126" cy="60" rx="22" ry="5" fill="none" stroke="#E8662A" stroke-width="4"/>'
	for k in 5:
		var x := 106.0 + k * 10.0
		s += '<line x1="%.1f" y1="62" x2="%.1f" y2="92" stroke="#F4F4F0" stroke-width="1.5"/>' % [x, 116.0 + k * 5.0]
	s += '<path d="M108 74 Q126 80 144 74 M112 86 Q126 90 140 86" stroke="#F4F4F0" stroke-width="1.5" fill="none"/>'
	if Season.is_winter():
		s += _rect(86.0, 4.0, 80.0, 6.0, SNOW)
	return PropArt.tex(_svg(w, h, s))


## Canvas 200 × 70 (foot on the bottom edge): a green park bench, its slats and cast-iron legs. Its seat is 26 px up.
static func bench() -> ImageTexture:
	var w := 200.0
	var h := 70.0
	var s := '<ellipse cx="100" cy="%.1f" rx="94" ry="5" fill="#000" fill-opacity="0.2"/>' % [h - 3.0]
	for k in 3:
		s += _rect(10.0, 6.0 + k * 9.0, 180.0, 6.0, "#3E7A4E")
		s += _rect(10.0, 6.0 + k * 9.0, 180.0, 2.0, "#5E9C6C")
	s += _rect(6.0, 38.0, 188.0, 7.0, "#3E7A4E")
	s += _rect(6.0, 38.0, 188.0, 2.5, "#68A878")
	for lx in [22.0, 168.0]:
		s += '<path d="M%.1f 4 L%.1f %.1f M%.1f 45 L%.1f %.1f" stroke="#2B2B2B" stroke-width="6" fill="none"/>' % [lx, lx, h - 6.0, lx - 8.0, lx + 6.0, h - 4.0]
	if Season.is_winter():
		s += _rect(6.0, 34.0, 188.0, 5.0, SNOW)
	return PropArt.tex(_svg(w, h, s))


## Canvas 420 × 170 (foot on the bottom edge): the yard's snow hill, pushed up by the plough all winter: lit from the upper
## left, a blue shade on its right, the track the sleds and the snow pants have worn down its right side.
static func snow_hill() -> ImageTexture:
	var w := 420.0
	var h := 170.0
	var s := '<defs><linearGradient id="hill" x1="0" y1="0" x2="1" y2="0.3"><stop offset="0" stop-color="#FFFFFF"/>'
	s += '<stop offset="0.55" stop-color="#EAF1F8"/><stop offset="1" stop-color="#BFD0E2"/></linearGradient></defs>'
	s += '<path d="M0 %.1f C60 %.1f 120 20 190 14 C250 10 300 40 340 90 C370 126 400 150 420 %.1f Z" fill="url(#hill)"/>' % [h, h - 30.0, h]
	s += '<path d="M200 18 C260 30 300 70 330 104 C356 132 380 150 404 %.1f" stroke="#B4C6DA" stroke-width="16" fill="none" stroke-linecap="round" stroke-opacity="0.8"/>' % [h - 6.0]
	s += '<path d="M70 %.1f C90 120 120 70 150 40" stroke="#D5E1EE" stroke-width="5" fill="none" stroke-dasharray="6 8"/>' % [h - 20.0]
	return PropArt.tex(_svg(w, h, s))
