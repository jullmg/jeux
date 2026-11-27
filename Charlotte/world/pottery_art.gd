class_name PotteryArt
extends RefCounted
## What the pottery studio (`ui/pottery_studio.gd`) draws: a pot turned on the wheel, seen a little from above, as a lathe
## body (`radius(pot, t)`, ten rings from the foot to the lip, eased between them) lit from the upper left; the wheel, her
## hands on the clay, the kiln. A pot is a plain Dictionary (`new_pot`) so the studio can copy it for "Oups !":
##   kind, h (height), r (ten radii), open (the hole is made), handle ("", "anse", "oreilles"), rim ("droit", "ondule",
##   "bec"), carve ("", "lignes", "vagues", "pois", "zigzag"), out / in (glaze ids, "" = none), dip (how far down the
##   outside glaze goes, 0..1 from the lip), bands [[t0, t1, glaze]], marks [[stamp, side, a|u, t|v, glaze, size]],
##   strokes [[glaze, width, side, [a|u, t|v, …]]], drips (glaze id or "").
## `stage` says how far along it is: "wet" on the wheel, "green" drying (leather hard), "raw" glazed before the kiln
## (glazes are pale and chalky then: `GLAZES` gives both colours, and copper red really is grey-green before firing),
## "fired" glossy. Outside marks are placed by their angle round the pot (`a`, 0 facing us), inside ones in the opening.
## **A new shape = an entry in `KINDS` / `KIND_INFO`; a new glaze = a line in `GLAZES`; a new stamp = `STAMPS` + a case in
## `stamp`.**

const TILT := 0.24
const WALL := 10.0
const CLAY_WET := Color("#A8735A")
const CLAY_GREEN := Color("#C59B7B")
const CLAY_BISQUE := Color("#EFDDCB")
const CLAY_FIRED := Color("#D4A680")
const SKIN := Color("#F3CBA8")
const LINE := Color("#4A3428")

const KINDS := ["bol", "tasse", "vase", "pot", "assiette"]
## Name, what it is for, the height and the ten radii Maman's help shapes it to.
const KIND_INFO := {
	"bol": ["Un bol", "Pour tes céréales le matin.", 112.0, [52, 72, 90, 104, 114, 122, 128, 132, 135, 137]],
	"tasse": ["Une tasse", "Pour le chocolat chaud, avec une anse.", 150.0, [54, 60, 62, 63, 64, 64, 65, 65, 66, 67]],
	"vase": ["Un vase", "Pour les fleurs de Maman.", 250.0, [52, 72, 86, 88, 80, 62, 42, 35, 39, 50]],
	"pot": ["Un pot à fleurs", "Pour une plante dans ta chambre.", 160.0, [58, 64, 70, 75, 80, 85, 90, 94, 98, 104]],
	"assiette": ["Une assiette", "Une belle assiette à dessin.", 34.0, [72, 122, 142, 152, 158, 162, 165, 167, 168, 170]],
}
## The ball of clay thrown on the wheel, then once she has opened it.
const LUMP_H := 96.0
const LUMP := [96.0, 98.0, 98.0, 96.0, 92.0, 86.0, 77.0, 65.0, 50.0, 30.0]
const OPENED_H := 92.0
const OPENED := [94.0, 94.0, 93.0, 92.0, 91.0, 90.0, 89.0, 88.0, 87.0, 86.0]
## id, name, fired colour, raw colour (as it looks in the bucket and on the pot before the kiln).
const GLAZES := [
	["cobalt", "Bleu cobalt", "#2456A6", "#A9B8C8"],
	["turquoise", "Turquoise", "#1FA5A8", "#B2D3CF"],
	["celadon", "Céladon", "#8DC2A0", "#CDD0C8"],
	["rouge", "Rouge cuivre", "#B3261E", "#A3B3A0"],
	["miel", "Jaune miel", "#DE9A2A", "#E9D7B4"],
	["rose", "Rose bonbon", "#F07AA5", "#EED0D8"],
	["lavande", "Lavande", "#9A82D0", "#D6D0E2"],
	["foret", "Vert forêt", "#2F7A43", "#B8C6B4"],
	["orange", "Orange", "#F07A2A", "#EECDAE"],
	["blanc", "Blanc lait", "#F8F4EB", "#F3EFE8"],
	["noir", "Noir brillant", "#26232A", "#96929A"],
	["mouchete", "Moucheté", "#EFE5D0", "#EAE2D4"],
]
const STAMPS := [["point", "Points"], ["coeur", "Cœurs"], ["etoile", "Étoiles"], ["fleur", "Fleurs"], ["feuille", "Feuilles"], ["spirale", "Spirales"]]


static func new_pot(kind: String) -> Dictionary:
	return {"kind": kind, "h": LUMP_H, "r": LUMP.duplicate(), "open": false, "handle": "", "rim": "droit", "carve": "",
		"out": "", "in": "", "dip": 1.0, "bands": [], "marks": [], "strokes": [], "drips": ""}


## The finished shape of a kind (what "Maman m'aide" eases to), keeping what the pot already has.
static func shaped(pot: Dictionary, kind: String) -> Dictionary:
	var p := pot.duplicate(true)
	var info: Array = KIND_INFO[kind]
	p.h = float(info[2])
	p.r = (info[3] as Array).map(func(v: int) -> float: return float(v))
	p.open = true
	if kind == "tasse" and p.handle == "":
		p.handle = "anse"
	return p


## A ready-made pot for the first card's pictures.
static func sample(kind: String) -> Dictionary:
	var p := shaped(new_pot(kind), kind)
	var looks := {"bol": ["turquoise", "blanc", 0.8], "tasse": ["rose", "blanc", 1.0], "vase": ["cobalt", "cobalt", 1.0],
		"pot": ["miel", "miel", 0.7], "assiette": ["celadon", "blanc", 1.0]}
	var l: Array = looks[kind]
	p.out = l[0]
	p["in"] = l[1]
	p.dip = l[2]
	if kind == "vase":
		p.marks = [["fleur", "o", -0.3, 0.55, "blanc", 26.0], ["point", "o", 0.25, 0.4, "blanc", 16.0]]
	if kind == "bol":
		p.bands = [[0.62, 0.7, "cobalt"]]
	if kind == "assiette":
		p.marks = [["coeur", "i", 0.0, 0.0, "rose", 40.0]]
	return p


# ── The shape ───────────────────────────────────────────────────

## Half the width of the pot at `t` (0 the foot, 1 the lip), in its own px.
static func radius(pot: Dictionary, t: float) -> float:
	var r: Array = pot.r
	var n := r.size() - 1
	var x := clampf(t, 0.0, 1.0) * n
	var i := mini(int(x), n - 1)
	var f := x - i
	var p0: float = r[maxi(i - 1, 0)]
	var p1: float = r[i]
	var p2: float = r[i + 1]
	var p3: float = r[mini(i + 2, n)]
	return maxf(4.0, 0.5 * (2.0 * p1 + (-p0 + p2) * f + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * f * f + (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * f * f * f))


static func max_radius(pot: Dictionary) -> float:
	var m := 0.0
	for k in 21:
		m = maxf(m, radius(pot, k / 20.0))
	return m


# The wavy lip lifts and dips round the top.
static func _wave(pot: Dictionary, a: float, t: float) -> float:
	if pot.rim != "ondule":
		return 0.0
	return 5.0 * sin(a * 9.0) * smoothstep(0.86, 1.0, t)


## Where the point at angle `a` (0 facing us) and height `t` lies on screen, the pot's foot centred at `base`.
static func point(base: Vector2, pot: Dictionary, a: float, t: float, s := 1.0) -> Vector2:
	var r := radius(pot, t) * s
	return Vector2(base.x + r * sin(a), base.y - t * float(pot.h) * s + TILT * r * cos(a) + _wave(pot, a, t) * s)


## Where a click lands: {side "o", a, t} on the outside, {side "i", u, v} in the opening, or {} off the pot.
static func surface_at(base: Vector2, pot: Dictionary, p: Vector2, s := 1.0) -> Dictionary:
	if pot.open:
		var top := Vector2(base.x, base.y - float(pot.h) * s)
		var rx := maxf(radius(pot, 1.0) * s - WALL * s, 2.0)
		var ry := rx * TILT
		var d := Vector2((p.x - top.x) / rx, (p.y - top.y) / ry)
		if d.length() <= 1.0 and p.y < point(base, pot, asin(clampf((p.x - base.x) / maxf(radius(pot, 1.0) * s, 1.0), -1.0, 1.0)), 1.0, s).y - 1.0:
			return {"side": "i", "u": d.x, "v": d.y}
	var best := {}
	var best_d := 9999.0
	for k in 121:
		var t := k / 120.0
		var r := radius(pot, t) * s
		var sx := (p.x - base.x) / r
		if absf(sx) > 1.0:
			continue
		var a := asin(sx)
		var y := point(base, pot, a, t, s).y
		var dy := absf(y - p.y)
		if dy < best_d:
			best_d = dy
			best = {"side": "o", "a": a, "t": t}
	return best if best_d < 6.0 * s + 2.0 else {}


# ── Colours ─────────────────────────────────────────────────────

static func glaze_entry(id: String) -> Array:
	for g: Array in GLAZES:
		if g[0] == id:
			return g
	return GLAZES[0]


static func glaze(id: String, stage: String) -> Color:
	var g := glaze_entry(id)
	return Color(g[2] if stage == "fired" else g[3])


static func _bare(stage: String) -> Color:
	match stage:
		"wet":
			return CLAY_WET
		"green":
			return CLAY_GREEN
		"raw":
			return CLAY_BISQUE
	return CLAY_FIRED


## The colour of the outside at height `t`, before light and shade.
static func surface_color(pot: Dictionary, t: float, stage: String) -> Color:
	var c := _bare(stage)
	if stage != "raw" and stage != "fired":
		return c
	if pot.out != "" and t >= 1.0 - float(pot.dip) - 0.0001:
		c = glaze(pot.out, stage)
	for b: Array in pot.bands:
		if t >= float(b[0]) and t <= float(b[1]):
			c = glaze(str(b[2]), stage)
	return c


static func inside_color(pot: Dictionary, stage: String) -> Color:
	if stage == "raw" or stage == "fired":
		if pot["in"] != "":
			return glaze(pot["in"], stage)
		if pot.out != "":
			return glaze(pot.out, stage)
	return _bare(stage)


# Light from the upper left, a little toward us: the left flank lit, the right in shade.
static func _light(a: float) -> float:
	return 0.52 + 0.56 * maxf(0.0, -0.55 * sin(a) + 0.83 * cos(a))


static func _gloss(a: float, stage: String) -> float:
	var g := exp(-pow((a + 0.62) / 0.13, 2.0)) + 0.35 * exp(-pow((a + 0.25) / 0.06, 2.0))
	match stage:
		"fired":
			return 0.6 * g
		"wet":
			return 0.28 * g
	return 0.0


# ── Drawing the pot ─────────────────────────────────────────────

## The whole pot, its foot centred at `base`. `spin` turns the clay's grain on the wheel (wet only).
static func draw_pot(ci: CanvasItem, base: Vector2, pot: Dictionary, stage: String, spin := 0.0, s := 1.0) -> void:
	# Its shadow on the wheel.
	_ellipse(ci, base + Vector2(10.0 * s, TILT * radius(pot, 0.0) * s + 3.0 * s), Vector2(radius(pot, 0.0) * 1.12 * s, radius(pot, 0.0) * TILT * 1.1 * s), Color(0, 0, 0, 0.22))
	if pot.handle != "":
		_handle(ci, base, pot, stage, s, true)
	_top(ci, base, pot, stage, s)
	_body(ci, base, pot, stage, s)
	if stage == "wet":
		_grain(ci, base, pot, spin, s)
	_carving(ci, base, pot, stage, s)
	if stage == "raw" or stage == "fired":
		_speckles(ci, base, pot, stage, s)
		for st: Array in pot.strokes:
			_stroke(ci, base, pot, st, stage, s)
		for m: Array in pot.marks:
			_mark(ci, base, pot, m, stage, s)
		if pot.drips != "":
			_drips(ci, base, pot, stage, s)
	if pot.handle != "":
		_handle(ci, base, pot, stage, s, false)
	_lip(ci, base, pot, stage, s)
	if pot.rim == "bec" and pot.open:
		_spout(ci, base, pot, stage, s)
	if stage == "raw":
		# A powdery dust: raw glaze is matte.
		var rng := RandomNumberGenerator.new()
		rng.seed = 77
		for k in 90:
			var a := rng.randf_range(-1.4, 1.4)
			var t := rng.randf_range(0.02, 0.98)
			ci.draw_circle(point(base, pot, a, t, s), 0.9 * s, Color(1, 1, 1, 0.35))


# The body as a mesh of rings and columns, one colour per vertex; extra rows at each colour edge keep the edges crisp.
static func _body(ci: CanvasItem, base: Vector2, pot: Dictionary, stage: String, s: float) -> void:
	var ts: Array = []
	for k in 49:
		ts.append(k / 48.0)
	var edges: Array = []
	if stage == "raw" or stage == "fired":
		if pot.out != "" and float(pot.dip) < 1.0:
			edges.append(1.0 - float(pot.dip))
		for b: Array in pot.bands:
			edges.append(float(b[0]))
			edges.append(float(b[1]))
	for e: float in edges:
		ts.append(clampf(e - 0.002, 0.0, 1.0))
		ts.append(clampf(e + 0.002, 0.0, 1.0))
	ts.sort()
	var cols := 26
	var pts := PackedVector2Array()
	var colors := PackedColorArray()
	for t: float in ts:
		var c := surface_color(pot, t, stage)
		for j in cols + 1:
			var a := -PI / 2.0 + PI * j / cols
			pts.append(point(base, pot, a, t, s))
			var lit := c * _light(a)
			lit.a = 1.0
			var g := _gloss(a, stage) * (0.4 + 0.6 * smoothstep(0.0, 0.25, t)) * (1.0 - 0.6 * smoothstep(0.85, 1.0, t))
			colors.append(lit.lerp(Color.WHITE, clampf(g, 0.0, 1.0)))
	var idx := PackedInt32Array()
	for i in ts.size() - 1:
		for j in cols:
			var a0 := i * (cols + 1) + j
			var b0 := a0 + cols + 1
			idx.append_array([a0, a0 + 1, b0, a0 + 1, b0 + 1, b0])
	RenderingServer.canvas_item_add_triangle_array(ci.get_canvas_item(), idx, pts, colors)
	# The outline, left, right and the foot.
	var left := PackedVector2Array()
	var right := PackedVector2Array()
	for k in 41:
		var t := k / 40.0
		left.append(point(base, pot, -PI / 2.0, t, s))
		right.append(point(base, pot, PI / 2.0, t, s))
	var foot := PackedVector2Array()
	for j in 27:
		foot.append(point(base, pot, -PI / 2.0 + PI * j / 26.0, 0.0, s))
	var ink := Color(LINE, 0.55)
	ci.draw_polyline(left, ink, 1.6 * s, true)
	ci.draw_polyline(right, ink, 1.6 * s, true)
	ci.draw_polyline(foot, ink, 1.6 * s, true)


# The opening (or the domed top of the closed ball of clay).
static func _top(ci: CanvasItem, base: Vector2, pot: Dictionary, stage: String, s: float) -> void:
	var top := Vector2(base.x, base.y - float(pot.h) * s)
	var r1 := radius(pot, 1.0) * s
	var outer := _ring(base, pot, 1.0, s, 0.0)
	var lip := surface_color(pot, 1.0, stage)
	if not pot.open:
		var cap := lip.lightened(0.12)
		ci.draw_colored_polygon(outer, cap)
		_ellipse(ci, top + Vector2(-r1 * 0.25, -r1 * TILT * 0.25), Vector2(r1 * 0.45, r1 * TILT * 0.4), Color(1, 1, 1, 0.12))
		return
	ci.draw_colored_polygon(outer, lip.lightened(0.1))
	var rx := maxf(r1 - WALL * s, 2.0)
	var inside := inside_color(pot, stage)
	var inner := _ring(base, pot, 1.0, s, WALL * s)
	ci.draw_colored_polygon(inner, inside.darkened(0.26))
	# The floor of the pot shows in a wide, shallow one.
	var f := clampf(1.0 - float(pot.h) / (radius(pot, 1.0) * 1.5), 0.0, 1.0)
	if f > 0.0:
		var fr := Vector2(rx * (0.3 + 0.62 * f), rx * TILT * (0.3 + 0.62 * f))
		var fc := top + Vector2(-rx * 0.04, rx * TILT * (0.5 - 0.42 * f))
		_ellipse(ci, fc, fr, inside.darkened(0.04))
	# The back wall inside catches the light on the right.
	var crescent := PackedVector2Array()
	for k in 17:
		var a := -0.2 + 1.5 * k / 16.0
		crescent.append(top + Vector2(sin(a) * rx * 0.96, -cos(a) * rx * TILT * 0.96))
	for k in 17:
		var a := 1.3 - 1.5 * k / 16.0
		crescent.append(top + Vector2(sin(a) * rx * 0.8, -cos(a) * rx * TILT * 0.55))
	ci.draw_colored_polygon(crescent, Color(inside.lightened(0.2), 0.45))
	for m: Array in pot.marks:
		if m[1] == "i":
			_mark(ci, base, pot, m, stage, s)
	for st: Array in pot.strokes:
		if st[2] == "i":
			_stroke(ci, base, pot, st, stage, s)
	if stage == "fired":
		var shine := PackedVector2Array()
		for k in 9:
			var a := -2.2 + 0.9 * k / 8.0
			shine.append(top + Vector2(sin(a) * rx * 0.8, -cos(a) * rx * TILT * 0.8))
		ci.draw_polyline(shine, Color(1, 1, 1, 0.45), 3.0 * s, true)


# The front of the lip over the body: a lighter rim with its edge.
static func _lip(ci: CanvasItem, base: Vector2, pot: Dictionary, stage: String, s: float) -> void:
	var lip := surface_color(pot, 1.0, stage).lightened(0.15)
	var front := PackedVector2Array()
	for j in 41:
		front.append(point(base, pot, -PI / 2.0 + PI * j / 40.0, 1.0, s))
	if pot.open:
		ci.draw_polyline(front, lip, 3.4 * s, true)
		var back := _ring(base, pot, 1.0, s, 0.0)
		back.append(back[0])
		ci.draw_polyline(back, Color(LINE, 0.5), 1.4 * s, true)
		var inner := _ring(base, pot, 1.0, s, WALL * s)
		inner.append(inner[0])
		ci.draw_polyline(inner, Color(LINE, 0.35), 1.2 * s, true)
	else:
		ci.draw_polyline(front, Color(LINE, 0.45), 1.4 * s, true)


# The ellipse round the top at `inset` px in from the outside.
static func _ring(base: Vector2, pot: Dictionary, t: float, s: float, inset: float) -> PackedVector2Array:
	var top := Vector2(base.x, base.y - t * float(pot.h) * s)
	var r := maxf(radius(pot, t) * s - inset, 2.0)
	var pts := PackedVector2Array()
	for k in 64:
		var a := TAU * k / 64.0
		pts.append(top + Vector2(r * sin(a), TILT * r * cos(a) + _wave(pot, a, t) * s * (r / maxf(radius(pot, t) * s, 1.0))))
	return pts


# Little specks of grog going round with the wheel.
static func _grain(ci: CanvasItem, base: Vector2, pot: Dictionary, spin: float, s: float) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	for k in 70:
		var a := wrapf(rng.randf_range(0.0, TAU) + spin, -PI, PI)
		var t := rng.randf_range(0.03, 0.97)
		var size := rng.randf_range(0.8, 1.8)
		if cos(a) < 0.1:
			continue
		ci.draw_circle(point(base, pot, a, t, s), size * s, Color(0.35, 0.2, 0.12, 0.35 * cos(a)))
	# The throwing rings her fingers leave.
	for k in 6:
		var t := 0.12 + k * 0.15
		var ring := PackedVector2Array()
		for j in 25:
			ring.append(point(base, pot, -1.45 + 2.9 * j / 24.0, t, s))
		ci.draw_polyline(ring, Color(0.35, 0.2, 0.12, 0.18), 1.6 * s, true)


static func _carving(ci: CanvasItem, base: Vector2, pot: Dictionary, stage: String, s: float) -> void:
	if pot.carve == "" or stage == "wet":
		return
	var dark := Color(0.25, 0.14, 0.08, 0.45)
	var light := Color(1, 1, 1, 0.3)
	match pot.carve:
		"lignes":
			for t: float in [0.3, 0.45, 0.6, 0.75]:
				_around(ci, base, pot, func(a: float) -> float: return t, dark, light, s)
		"vagues":
			for t: float in [0.38, 0.62]:
				_around(ci, base, pot, func(a: float) -> float: return t + 0.035 * sin(a * 10.0), dark, light, s)
		"zigzag":
			_around(ci, base, pot, func(a: float) -> float: return 0.5 + 0.05 * (absf(fposmod(a * 3.0, 2.0) - 1.0) * 2.0 - 1.0), dark, light, s)
		"pois":
			for row in 3:
				var t := 0.35 + row * 0.15
				for k in 30:
					var a := _shown(pot, -PI + TAU * k / 30.0 + (0.1 if row % 2 else 0.0))
					if cos(a) < 0.15:
						continue
					var c := point(base, pot, a, t, s)
					_ellipse(ci, c, Vector2(3.2 * s * cos(a) + 0.6, 2.6 * s), dark)
					_ellipse(ci, c + Vector2(0, 1.2 * s), Vector2(2.2 * s * cos(a) + 0.4, 1.2 * s), light)


static func _around(ci: CanvasItem, base: Vector2, pot: Dictionary, t_of: Callable, dark: Color, light: Color, s: float) -> void:
	var line := PackedVector2Array()
	var below := PackedVector2Array()
	for j in 61:
		var a := -1.5 + 3.0 * j / 60.0
		var p := point(base, pot, a, float(t_of.call(a - _turn(pot))), s)
		line.append(p)
		below.append(p + Vector2(0, 1.6 * s))
	ci.draw_polyline(below, light, 1.6 * s, true)
	ci.draw_polyline(line, dark, 2.2 * s, true)


static func _speckles(ci: CanvasItem, base: Vector2, pot: Dictionary, stage: String, s: float) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	for k in 260:
		var a := _shown(pot, rng.randf_range(-PI, PI))
		var t := rng.randf_range(0.0, 1.0)
		var size := rng.randf_range(0.6, 1.7)
		var glazed: bool = pot.out == "mouchete" and t >= 1.0 - float(pot.dip)
		for b: Array in pot.bands:
			if t >= float(b[0]) and t <= float(b[1]):
				glazed = b[2] == "mouchete"
		if glazed and cos(a) > 0.05:
			ci.draw_circle(point(base, pot, a, t, s), size * s, Color(0.42, 0.26, 0.16, 0.75 if stage == "fired" else 0.3))


## How far the pot has turned on the wheel (`pot.turn`): what she painted turns with it.
static func _turn(pot: Dictionary) -> float:
	return float(pot.get("turn", 0.0))


## Where something painted at angle `a` of the pot (pot's own angle) shows now, wrapped to -PI..PI.
static func _shown(pot: Dictionary, a: float) -> float:
	return wrapf(a + _turn(pot), -PI, PI)


## The inside of the opening turns too: (u, v) as an angle round the middle.
static func _turned_in(pot: Dictionary, u: float, v: float) -> Vector2:
	var t := _turn(pot)
	if t == 0.0:
		return Vector2(u, v)
	var r := Vector2(u, v).length()
	var th := atan2(u, v) + t
	return Vector2(sin(th) * r, cos(th) * r)


## From what she clicked (screen angle / screen inside point) to the pot's own place, so it turns with it.
static func to_pot(pot: Dictionary, hit: Dictionary) -> Dictionary:
	var h := hit.duplicate()
	if hit.side == "o":
		h.a = wrapf(float(hit.a) - _turn(pot), -PI, PI)
	else:
		var r := Vector2(float(hit.u), float(hit.v)).length()
		var th := atan2(float(hit.u), float(hit.v)) - _turn(pot)
		h.u = sin(th) * r
		h.v = cos(th) * r
	return h


# A painted outside point is only seen on the front half.
static func _seen(m_side: String, a: float) -> bool:
	return m_side == "i" or cos(a) > 0.08


static func _mark_pos(base: Vector2, pot: Dictionary, side: String, x: float, y: float, s: float) -> Vector2:
	if side == "i":
		var top := Vector2(base.x, base.y - float(pot.h) * s)
		var rx := maxf(radius(pot, 1.0) * s - WALL * s, 2.0)
		return top + Vector2(x * rx * 0.86, y * rx * TILT * 0.86)
	return point(base, pot, x, y, s)


static func _mark(ci: CanvasItem, base: Vector2, pot: Dictionary, m: Array, stage: String, s: float) -> void:
	var side: String = m[1]
	var x := _shown(pot, float(m[2])) if side == "o" else _turned_in(pot, float(m[2]), float(m[3])).x
	var y := float(m[3]) if side == "o" else _turned_in(pot, float(m[2]), float(m[3])).y
	if side == "o" and (not _seen(side, x)):
		return
	var c := _mark_pos(base, pot, side, x, y, s)
	var sq := Vector2(cos(x), 1.0) if side == "o" else Vector2(1.0, 0.55)
	var col := glaze(str(m[4]), stage)
	if side == "o":
		col = col * _light(x)
		col.a = 1.0
	stamp(ci, str(m[0]), c, float(m[5]) * s, col, sq)
	if stage == "fired":
		ci.draw_circle(c + Vector2(-float(m[5]) * 0.16, -float(m[5]) * 0.16) * s * sq, float(m[5]) * 0.07 * s, Color(1, 1, 1, 0.55))


static func _stroke(ci: CanvasItem, base: Vector2, pot: Dictionary, st: Array, stage: String, s: float) -> void:
	var side: String = st[2]
	var raw: Array = st[3]
	var col := glaze(str(st[0]), stage)
	var line := PackedVector2Array()
	var k := 0
	while k + 1 < raw.size():
		var x: float = _shown(pot, float(raw[k])) if side == "o" else _turned_in(pot, float(raw[k]), float(raw[k + 1])).x
		var y: float = float(raw[k + 1]) if side == "o" else _turned_in(pot, float(raw[k]), float(raw[k + 1])).y
		if side == "o" and not _seen(side, x):
			if line.size() > 1:
				ci.draw_polyline(line, col, float(st[1]) * s, true)
			line = PackedVector2Array()
		else:
			# A stroke that went round the back jumps: start again on this side.
			var p := _mark_pos(base, pot, side, x, y, s)
			if line.size() > 0 and line[line.size() - 1].distance_to(p) > 60.0 * s:
				if line.size() > 1:
					ci.draw_polyline(line, col, float(st[1]) * s, true)
				line = PackedVector2Array()
			line.append(p)
		k += 2
	if line.size() > 1:
		ci.draw_polyline(line, col, float(st[1]) * s, true)
		for p: Vector2 in [line[0], line[line.size() - 1]]:
			ci.draw_circle(p, float(st[1]) * s * 0.5, col)
	elif line.size() == 1:
		ci.draw_circle(line[0], float(st[1]) * s * 0.5, col)


# Glaze run down from the lip in drops.
static func _drips(ci: CanvasItem, base: Vector2, pot: Dictionary, stage: String, s: float) -> void:
	var col := glaze(pot.drips, stage)
	var rng := RandomNumberGenerator.new()
	rng.seed = 31
	# A band of it round the top, as a mesh (a polygon would cross itself on a wavy lip).
	var pts := PackedVector2Array()
	var colors := PackedColorArray()
	var idx := PackedInt32Array()
	for j in 41:
		var a := -PI / 2.0 + PI * j / 40.0
		var shade := col * _light(a)
		shade.a = 1.0
		pts.append(point(base, pot, a, 0.99, s))
		pts.append(point(base, pot, a, 0.92, s))
		colors.append(shade)
		colors.append(shade)
		if j < 40:
			var i := j * 2
			idx.append_array([i, i + 2, i + 1, i + 2, i + 3, i + 1])
	RenderingServer.canvas_item_add_triangle_array(ci.get_canvas_item(), idx, pts, colors)
	for k in 22:
		var a := _shown(pot, -PI + TAU * k / 22.0 + rng.randf_range(-0.08, 0.08))
		if cos(a) < 0.2:
			rng.randf_range(0.1, 0.32)
			rng.randf_range(5.0, 9.0)
			continue
		var length := rng.randf_range(0.1, 0.32) * clampf(120.0 / float(pot.h), 0.4, 1.4)
		var w := rng.randf_range(5.0, 9.0) * s * cos(a)
		var line := PackedVector2Array()
		for j in 8:
			line.append(point(base, pot, a, 0.95 - length * j / 7.0, s))
		var shade := col * _light(a)
		shade.a = 1.0
		ci.draw_polyline(line, shade, w, true)
		ci.draw_circle(line[line.size() - 1] + Vector2(0, w * 0.15), w * 0.62, shade)
		if stage == "fired":
			ci.draw_circle(line[line.size() - 1] + Vector2(-w * 0.2, -w * 0.05), w * 0.2, Color(1, 1, 1, 0.5))


# The handle on the right (or two little ears): `back` draws the part behind the pot.
static func _handle(ci: CanvasItem, base: Vector2, pot: Dictionary, stage: String, s: float, back: bool) -> void:
	var sides: Array = [1] if pot.handle == "anse" else [-1, 1]
	var t0 := 0.8 if pot.handle == "anse" else 0.74
	var t1 := 0.3 if pot.handle == "anse" else 0.56
	var reach := 46.0 if pot.handle == "anse" else 22.0
	var thick := 13.0 if pot.handle == "anse" else 9.0
	for side: int in sides:
		# It turns with the pot: behind it when it is round the back, narrower when it faces us.
		var phi := _shown(pot, side * PI / 2.0)
		if (cos(phi) < 0.0) != back:
			continue
		var dir := sin(phi)
		var a0 := point(base, pot, phi, t0, s) + Vector2(-dir * 3.0 * s, 0)
		var a1 := point(base, pot, phi, t1, s) + Vector2(-dir * 3.0 * s, 0)
		var out := Vector2(dir * reach * s, cos(phi) * 6.0 * s)
		var pts := PackedVector2Array()
		for k in 21:
			var f := k / 20.0
			var u := 1.0 - f
			pts.append(a0 * u * u * u + (a0 + out + Vector2(0, -8.0 * s)) * 3.0 * u * u * f + (a1 + out * 1.05 + Vector2(0, 6.0 * s)) * 3.0 * u * f * f + a1 * f * f * f)
		var t_mid := (t0 + t1) / 2.0
		var c := surface_color(pot, t_mid, stage) * (_light(phi) if not back else 0.6)
		c.a = 1.0
		ci.draw_polyline(pts, Color(LINE, 0.6), thick * s + 3.0 * s, true)
		ci.draw_polyline(pts, c, thick * s, true)
		if back:
			continue
		var hi := PackedVector2Array()
		for k in range(2, 14):
			hi.append(pts[k] + Vector2(-signf(dir) * 2.0 * s, -2.5 * s))
		ci.draw_polyline(hi, Color(1, 1, 1, 0.45 if stage == "fired" else 0.18), 2.4 * s, true)


static func _spout(ci: CanvasItem, base: Vector2, pot: Dictionary, stage: String, s: float) -> void:
	var phi := _shown(pot, -PI / 2.0)
	if cos(phi) < -0.3:
		return
	var tip := point(base, pot, phi, 1.0, s)
	var c := surface_color(pot, 1.0, stage) * _light(-1.2)
	c.a = 1.0
	var pts := PackedVector2Array([tip + Vector2(10.0 * s, -2.0 * s), tip + Vector2(-16.0 * s, -10.0 * s), tip + Vector2(-12.0 * s, -4.0 * s), tip + Vector2(6.0 * s, 9.0 * s)])
	ci.draw_colored_polygon(pts, c)
	pts.append(pts[0])
	ci.draw_polyline(pts, Color(LINE, 0.55), 1.4 * s, true)


# ── Stamps and little shapes ────────────────────────────────────

## A stamp `size` px across at `c`, squeezed by `sq` (a stamp round the side of a pot is narrower).
static func stamp(ci: CanvasItem, id: String, c: Vector2, size: float, col: Color, sq := Vector2.ONE) -> void:
	var r := size * 0.5
	if r * minf(sq.x, sq.y) < 1.0:
		return
	var pts := PackedVector2Array()
	match id:
		"point":
			_ellipse(ci, c, Vector2(r * 0.6, r * 0.6) * sq, col)
			return
		"coeur":
			for k in 40:
				var a := TAU * k / 40.0
				var x := 16.0 * pow(sin(a), 3.0)
				var y := -(13.0 * cos(a) - 5.0 * cos(2.0 * a) - 2.0 * cos(3.0 * a) - cos(4.0 * a))
				pts.append(Vector2(x, y) / 17.0 * r)
		"etoile":
			for k in 10:
				var a := -PI / 2.0 + TAU * k / 10.0
				pts.append(Vector2.from_angle(a) * (r if k % 2 == 0 else r * 0.45))
		"fleur":
			for k in 5:
				var a := -PI / 2.0 + TAU * k / 5.0
				_ellipse(ci, c + Vector2.from_angle(a) * r * 0.5 * sq, Vector2(r * 0.42, r * 0.42) * sq, col)
			_ellipse(ci, c, Vector2(r * 0.3, r * 0.3) * sq, col.lightened(0.55))
			return
		"feuille":
			for k in 21:
				var f := k / 20.0
				pts.append(Vector2(lerpf(-r, r, f), -sin(f * PI) * r * 0.45))
			for k in range(19, 0, -1):
				var f := k / 20.0
				pts.append(Vector2(lerpf(-r, r, f), sin(f * PI) * r * 0.45))
		"spirale":
			var line := PackedVector2Array()
			for k in 40:
				var a := k * 0.42
				line.append(c + (Vector2.from_angle(a) * r * (0.1 + 0.9 * k / 39.0)) * sq)
			ci.draw_polyline(line, col, maxf(1.5, r * 0.18), true)
			return
	var placed := PackedVector2Array()
	for p: Vector2 in pts:
		placed.append(c + p * sq)
	if placed.size() >= 3:
		ci.draw_colored_polygon(placed, col)
		if id == "feuille":
			ci.draw_line(c + Vector2(-r * 0.8, 0) * sq, c + Vector2(r * 0.8, 0) * sq, col.darkened(0.3), maxf(1.0, r * 0.08), true)


static func _ellipse(ci: CanvasItem, c: Vector2, rad: Vector2, col: Color) -> void:
	if rad.x <= 0.2 or rad.y <= 0.2:
		return
	var pts := PackedVector2Array()
	for k in 36:
		pts.append(c + Vector2(cos(TAU * k / 36.0) * rad.x, sin(TAU * k / 36.0) * rad.y))
	ci.draw_colored_polygon(pts, col)


# ── The wheel, her hands, the kiln ──────────────────────────────

## The wheel head (its top at `base`) and the splash pan round it; `spin` turns the marks on the head.
static func draw_wheel(ci: CanvasItem, base: Vector2, spin: float, s := 1.0) -> void:
	_ellipse(ci, base + Vector2(0, 34.0 * s), Vector2(270.0, 66.0) * s, Color("#8F8A80"))
	_ellipse(ci, base + Vector2(0, 28.0 * s), Vector2(258.0, 58.0) * s, Color("#C9C2B2"))
	_ellipse(ci, base + Vector2(0, 30.0 * s), Vector2(236.0, 50.0) * s, Color("#B3A68F"))
	# Slip splashed on the pan.
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	for k in 18:
		var a := rng.randf_range(0.0, TAU)
		var d := rng.randf_range(0.75, 0.97)
		_ellipse(ci, base + Vector2(cos(a) * 236.0 * d, 30.0 + sin(a) * 50.0 * d) * s, Vector2(rng.randf_range(4, 12), rng.randf_range(2, 4)) * s, Color("#9E7A5E", 0.5))
	_ellipse(ci, base + Vector2(0, 12.0 * s), Vector2(205.0, 46.0) * s, Color("#5E626A"))
	_ellipse(ci, base, Vector2(205.0, 46.0) * s, Color("#A9ADB5"))
	_ellipse(ci, base + Vector2(-30, -8) * s, Vector2(120.0, 22.0) * s, Color(1, 1, 1, 0.16))
	for k in 8:
		var a := spin + TAU * k / 8.0
		var p := base + Vector2(cos(a) * 170.0, sin(a) * 38.0) * s
		if sin(a) > -0.2:
			ci.draw_line(p, base + Vector2(cos(a) * 190.0, sin(a) * 42.0) * s, Color(0.3, 0.32, 0.36, 0.7), 2.0 * s)
	for r in [60.0, 120.0]:
		var ring := PackedVector2Array()
		for k in 49:
			ring.append(base + Vector2(cos(TAU * k / 48.0) * r, sin(TAU * k / 48.0) * r * 0.225) * s)
		ci.draw_polyline(ring, Color(0.3, 0.32, 0.36, 0.25), 1.4 * s, true)


## One of her hands on the clay: `side` -1 on the left of the pot (fingers pointing right), 1 on the right. `wet` gleams.
static func draw_hand(ci: CanvasItem, at: Vector2, side: int, wet: bool, s := 1.0) -> void:
	var dir := float(-side)
	var palm := at + Vector2(-dir * 26.0, 0) * s
	var outline := Color("#B5785A")
	for k in 4:
		var y := (-15.0 + k * 10.0) * s
		var tip := at + Vector2(dir * (4.0 - absf(k - 1.5) * 3.0) * s, y)
		var root := palm + Vector2(dir * 6.0 * s, y * 0.8)
		ci.draw_line(root, tip, outline, 9.5 * s, true)
		ci.draw_line(root, tip, SKIN, 7.0 * s, true)
		ci.draw_circle(tip, 3.5 * s, SKIN)
	_ellipse(ci, palm, Vector2(19.0, 23.0) * s, outline)
	_ellipse(ci, palm, Vector2(17.5, 21.5) * s, SKIN)
	# The thumb on top.
	ci.draw_line(palm + Vector2(0, -16.0) * s, palm + Vector2(dir * 18.0, -26.0) * s, outline, 9.0 * s, true)
	ci.draw_line(palm + Vector2(0, -16.0) * s, palm + Vector2(dir * 18.0, -26.0) * s, SKIN, 6.5 * s, true)
	# Clay on the fingers.
	_ellipse(ci, at + Vector2(dir * -2.0, 4.0) * s, Vector2(6.0, 9.0) * s, Color(CLAY_WET, 0.55))
	if wet:
		ci.draw_circle(palm + Vector2(-6.0, -8.0) * s, 3.0 * s, Color(1, 1, 1, 0.5))


## The kiln, its feet at `base`: `door` 0 shut .. 1 wide open, `heat` 0 cold .. 1 white hot, `t` for the flicker.
## `contents` draws what is inside (the pot on its shelf), between the chamber and the door.
static func draw_kiln(ci: CanvasItem, base: Vector2, door: float, heat: float, t: float, s := 1.0, contents := Callable()) -> void:
	var w := 300.0 * s
	var h := 330.0 * s
	var left := base.x - w / 2.0
	var top := base.y - h
	# Its legs and shadow.
	_ellipse(ci, base + Vector2(14, 4) * s, Vector2(180, 18) * s, Color(0, 0, 0, 0.2))
	for x: float in [left + 20.0 * s, left + w - 34.0 * s]:
		ci.draw_rect(Rect2(x, base.y - 28.0 * s, 14.0 * s, 28.0 * s), Color("#3E4148"))
	# The steel body, a dome on top, the bands.
	var body := Rect2(left, top + 30.0 * s, w, h - 58.0 * s)
	ci.draw_rect(body, Color("#B8BCC4"))
	ci.draw_rect(Rect2(left, top + 30.0 * s, w * 0.22, h - 58.0 * s), Color(1, 1, 1, 0.18))
	ci.draw_rect(Rect2(left + w * 0.82, top + 30.0 * s, w * 0.18, h - 58.0 * s), Color(0, 0, 0, 0.12))
	var dome := PackedVector2Array()
	for k in 25:
		var a := PI + PI * k / 24.0
		dome.append(Vector2(base.x + cos(a) * w / 2.0, top + 30.0 * s + sin(a) * 34.0 * s))
	ci.draw_colored_polygon(dome, Color("#A8ACB4"))
	ci.draw_rect(body, Color("#5E626A"), false, 3.0 * s)
	for y: float in [top + 60.0 * s, base.y - 52.0 * s]:
		ci.draw_rect(Rect2(left - 4.0 * s, y, w + 8.0 * s, 9.0 * s), Color("#6E727A"))
	# The chamber: firebrick, glowing with the heat.
	var room := Rect2(left + 34.0 * s, top + 80.0 * s, w - 68.0 * s, h - 150.0 * s)
	var glow := Color("#3A2A22").lerp(Color("#FF7A22"), clampf(heat * 1.2, 0.0, 1.0)).lerp(Color("#FFE9A0"), clampf(heat * 2.0 - 1.0, 0.0, 1.0))
	ci.draw_rect(room, glow)
	for row in 7:
		for col in 5:
			var bx := room.position.x + col * room.size.x / 5.0 + (room.size.x / 10.0 if row % 2 else 0.0)
			var brick := Rect2(bx, room.position.y + row * room.size.y / 7.0, room.size.x / 5.0 - 2.0 * s, room.size.y / 7.0 - 2.0 * s).intersection(room)
			ci.draw_rect(brick, Color(1, 1, 1, 0.08 + 0.05 * ((row + col) % 2)) if heat < 0.3 else Color(1, 0.9, 0.6, 0.12))
	ci.draw_rect(Rect2(room.position.x, room.end.y - 16.0 * s, room.size.x, 16.0 * s), Color("#77706A") if heat < 0.3 else Color("#FFC870", 0.8))
	if contents.is_valid():
		contents.call()
		# The heat bathes it all in orange.
		if heat > 0.05:
			ci.draw_rect(room, Color(1.0, 0.55, 0.15, 0.55 * heat))
	# The door swings open on its hinge at the left.
	var dw := (w - 52.0 * s) * (1.0 - 0.86 * door)
	var dl := left + 26.0 * s
	var dr := Rect2(dl, top + 72.0 * s, dw, h - 134.0 * s)
	if door < 0.98:
		ci.draw_rect(dr, Color("#9EA2AA"))
		ci.draw_rect(Rect2(dl, dr.position.y, dw * 0.3, dr.size.y), Color(1, 1, 1, 0.14))
		ci.draw_rect(dr, Color("#4E525A"), false, 3.0 * s)
		# The spy hole and the latch.
		var hole := Vector2(dl + dw * 0.5, dr.position.y + 60.0 * s)
		ci.draw_circle(hole, 15.0 * s * (1.0 - door * 0.5), Color("#2A2A30"))
		var flicker := 0.75 + 0.25 * sin(t * 13.0) * sin(t * 7.3)
		ci.draw_circle(hole, 11.0 * s * (1.0 - door * 0.5), Color(glow, clampf(heat * 1.4, 0.0, 1.0) * flicker))
		ci.draw_rect(Rect2(dl + dw - 26.0 * s, dr.position.y + dr.size.y * 0.5 - 8.0 * s, 20.0 * s, 16.0 * s), Color("#3E4148"))
	# The dial: the needle climbs with the heat.
	var dial := Vector2(base.x, top + 46.0 * s)
	ci.draw_circle(dial, 15.0 * s, Color("#F4F1EA"))
	ci.draw_arc(dial, 15.0 * s, 0.0, TAU, 24, Color("#3E4148"), 2.0 * s, true)
	var ang := PI * 0.8 + heat * PI * 1.4
	ci.draw_line(dial, dial + Vector2.from_angle(ang) * 11.0 * s, Color("#E04F5F"), 2.4 * s, true)
	# Heat shimmering above the vent.
	if heat > 0.2:
		for k in 3:
			var line := PackedVector2Array()
			for j in 9:
				var y := top - 6.0 * s - j * 7.0 * s
				line.append(Vector2(base.x - 20.0 * s + k * 20.0 * s + sin(t * 5.0 + j * 0.9 + k) * 4.0 * s, y))
			ci.draw_polyline(line, Color(1, 0.8, 0.5, 0.35 * heat), 2.0 * s, true)


## Where the pot stands inside the kiln (its foot), for a kiln standing at `base`.
static func kiln_shelf(base: Vector2, s := 1.0) -> Vector2:
	return Vector2(base.x, base.y - 86.0 * s)
