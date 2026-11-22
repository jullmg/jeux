class_name CookieArt
extends RefCounted
## What the cookie studio (`ui/cookie_studio.gd`) draws: the ingredients on the counter, the cookie cutters and their shapes, a
## cookie (dough, doneness, icing, candies, sprinkles) and the plate it goes on for Santa. Everything is drawn on any
## CanvasItem; a cookie lives in its own units (about 100 wide, centred on 0) and is scaled when drawn. Light from the upper left.
## **A new cutter = its id in `SHAPES` + a case in `_make_shape` (+ `RADIUS`); a new candy = its id in `CANDIES` + a case in
## `candy`; a new sprinkle = its id in `SPRINKLES` + a case in `_bit`.**

const BROWN := Color("#7A4A24")

## Ingredients, in the order of the counter: id, name, what Maman says as it goes in.
const INGREDIENTS := [
	["farine", "Farine", "De la farine : trois tasses !"],
	["cassonade", "Cassonade", "Un peu de cassonade, pour que ce soit sucré."],
	["beurre", "Beurre", "Du beurre mou : ça rend les biscuits tendres."],
	["oeuf", "Un œuf", "Crac ! Attention aux coquilles."],
	["melasse", "Mélasse", "La mélasse, c'est le secret des biscuits de Noël."],
	["gingembre", "Gingembre", "Du gingembre : ça pique juste un peu."],
	["cannelle", "Cannelle", "Pis la cannelle : ça sent déjà Noël !"],
]

## The cutters: id, name.
const SHAPES := [["bonhomme", "Bonhomme"], ["etoile", "Étoile"], ["sapin", "Sapin"], ["coeur", "Cœur"], ["cloche", "Cloche"],
	["botte", "Bas de Noël"], ["flocon", "Flocon"], ["boule", "Boule"]]
## A circle (in cookie units) that holds each shape, for keeping the cuts apart.
const RADIUS := {"bonhomme": 52.0, "etoile": 50.0, "sapin": 51.0, "coeur": 47.0, "cloche": 46.0, "botte": 48.0, "flocon": 50.0, "boule": 46.0}

## The things that are laid one at a time: id, name.
const CANDIES := [["smarties", "Bonbons"], ["cannelle", "Cannelle"], ["gomme", "Gommes"], ["pepite", "Pépites"],
	["guimauve", "Guimauves"], ["yeux", "Yeux en sucre"], ["bouton", "Boutons"], ["coeur", "Cœurs roses"], ["etoile", "Étoiles dorées"],
	["baton", "Bâtonnets"], ["dragee", "Dragées"]]
## What she shakes on: id, name.
const SPRINKLES := [["arcenciel", "Arc-en-ciel"], ["noel", "Rouge et vert"], ["argent", "Billes d'argent"], ["or", "Billes d'or"],
	["etoiles", "Petites étoiles"], ["sucre", "Sucre cristal"], ["glace", "Sucre glace"]]
const CANDY_COLORS := ["#E5383B", "#2F9E55", "#FFD23F", "#3B8BE0", "#FF8A2E", "#FF7BB0", "#8E5BD0"]
## The icing and the melted chocolate: id, colour.
const ICINGS := [["blanc", "#FFFFFF"], ["rouge", "#D8283A"], ["vert", "#2F9E55"], ["bleu", "#3B8BE0"], ["jaune", "#FFD23F"],
	["rose", "#FF8AB8"], ["orange", "#FF8A2E"], ["chocolat", "#5A301A"]]

## How the plates and the glasses are called: id, name.
const PLATES := [["blanche", "Assiette blanche"], ["noel", "Assiette de Noël"], ["bleue", "Assiette bleue"]]
const DRINKS := [["lait", "Lait"], ["chocolat", "Lait au chocolat"], ["chaud", "Chocolat chaud"]]

static var _shapes := {}
static var _insets := {}


# ── Cookie shapes ───────────────────────────────────────────

static func shape(id: String) -> PackedVector2Array:
	if not _shapes.has(id):
		_shapes[id] = _make_shape(id)
	return _shapes[id]


## The shape pulled in by `d` units (cached); a negative `d` grows it.
static func inset(id: String, d: float) -> PackedVector2Array:
	var key := "%s:%.1f" % [id, d]
	if not _insets.has(key):
		var out := Geometry2D.offset_polygon(shape(id), -d, Geometry2D.JOIN_ROUND)
		_insets[key] = _biggest(out) if not out.is_empty() else PackedVector2Array()
	return _insets[key]


static func _make_shape(id: String) -> PackedVector2Array:
	match id:
		"bonhomme":
			return _soft(_union([_circle(Vector2(0, -33), 16.5), _capsule(Vector2(0, -10), Vector2(0, 12), 15.0),
				_capsule(Vector2(-8, -8), Vector2(-39, -16), 8.5), _capsule(Vector2(8, -8), Vector2(39, -16), 8.5),
				_capsule(Vector2(-6, 12), Vector2(-20, 40), 9.5), _capsule(Vector2(6, 12), Vector2(20, 40), 9.5)]), 2.0)
		"etoile":
			var pts := PackedVector2Array()
			for i in 10:
				var a := -PI / 2.0 + i * PI / 5.0
				var r := 50.0 if i % 2 == 0 else 23.0
				pts.append(Vector2(cos(a), sin(a)) * r + Vector2(0, 3))
			return _soft(pts, 3.5)
		"sapin":
			var tiers := [PackedVector2Array([Vector2(0, -50), Vector2(-24, -17), Vector2(24, -17)]),
				PackedVector2Array([Vector2(0, -33), Vector2(-34, 8), Vector2(34, 8)]),
				PackedVector2Array([Vector2(0, -12), Vector2(-45, 32), Vector2(45, 32)]),
				PackedVector2Array([Vector2(-9, 28), Vector2(9, 28), Vector2(9, 50), Vector2(-9, 50)])]
			return _soft(_union(tiers), 2.5)
		"coeur":
			var pts := PackedVector2Array()
			for i in 48:
				var t := TAU * i / 48.0
				pts.append(Vector2(16.0 * pow(sin(t), 3.0), -(13.0 * cos(t) - 5.0 * cos(2.0 * t) - 2.0 * cos(3.0 * t) - cos(4.0 * t))) * 2.9 + Vector2(0, -2))
			return pts
		"cloche":
			var flare := PackedVector2Array([Vector2(-20, -4), Vector2(20, -4), Vector2(41, 26), Vector2(-41, 26)])
			return _soft(_union([_ellipse(Vector2(0, -12), 25.0, 28.0), flare, _capsule(Vector2(-38, 31), Vector2(38, 31), 6.5),
				_circle(Vector2(0, 44), 7.5), _circle(Vector2(0, -41), 6.5)]), 2.0)
		"botte":
			return _soft(_union([_capsule(Vector2(8, -34), Vector2(8, 8), 17.0), _capsule(Vector2(8, 14), Vector2(-27, 24), 14.5),
				_capsule(Vector2(-2, -42), Vector2(18, -42), 8.0)]), 2.0)
		"flocon":
			var parts: Array = []
			for k in 3:
				var d := Vector2.from_angle(k * PI / 3.0)
				parts.append(_capsule(-d * 46.0, d * 46.0, 5.0))
			for k in 6:
				var d := Vector2.from_angle(k * PI / 3.0)
				for sgn in [-1.0, 1.0]:
					parts.append(_capsule(d * 28.0, d * 28.0 + d.rotated(sgn * 0.85) * 15.0, 4.0))
			parts.append(_circle(Vector2.ZERO, 9.0, 18))
			return _soft(_union(parts), 1.5)
		"boule":
			return _soft(_union([_circle(Vector2(0, 6), 38.0, 36), _capsule(Vector2(0, -36), Vector2(0, -30), 8.5)]), 2.0)
	return _circle(Vector2.ZERO, 40.0)


static func _circle(c: Vector2, r: float, n := 28) -> PackedVector2Array:
	return _ellipse(c, r, r, n)


static func _ellipse(c: Vector2, rx: float, ry: float, n := 28) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n:
		var a := TAU * i / n
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	return pts


## A stadium: a thick line from a to b with round ends.
static func _capsule(a: Vector2, b: Vector2, r: float) -> PackedVector2Array:
	var dir := (b - a).normalized()
	var base := dir.angle()
	var pts := PackedVector2Array()
	for i in 9:
		pts.append(b + Vector2.from_angle(base - PI / 2.0 + PI * i / 8.0) * r)
	for i in 9:
		pts.append(a + Vector2.from_angle(base + PI / 2.0 + PI * i / 8.0) * r)
	return pts


static func _union(parts: Array) -> PackedVector2Array:
	var acc: PackedVector2Array = parts[0]
	for i in range(1, parts.size()):
		var merged := Geometry2D.merge_polygons(acc, parts[i])
		if not merged.is_empty():
			acc = _biggest(merged)
	return acc


static func _biggest(polys: Array) -> PackedVector2Array:
	var best := PackedVector2Array()
	var best_area := -1.0
	for p: PackedVector2Array in polys:
		var a := absf(_area(p))
		if a > best_area:
			best_area = a
			best = p
	return best


static func _area(p: PackedVector2Array) -> float:
	var s := 0.0
	for i in p.size():
		var q := p[(i + 1) % p.size()]
		s += p[i].x * q.y - q.x * p[i].y
	return s / 2.0


## Rounds a polygon's convex corners (pulled in, then pushed out again).
static func _soft(p: PackedVector2Array, r: float) -> PackedVector2Array:
	var inner := Geometry2D.offset_polygon(p, -r, Geometry2D.JOIN_ROUND)
	if inner.is_empty():
		return p
	var out := Geometry2D.offset_polygon(_biggest(inner), r, Geometry2D.JOIN_ROUND)
	return _biggest(out) if not out.is_empty() else p


# ── The cookie ──────────────────────────────────────────────

## The dough's colour for a doneness (0 raw, 0.5 golden, 1 dark, above: burnt).
static func dough_color(doneness: float) -> Color:
	var stops := [Color("#E7C38D"), Color("#D49A55"), Color("#B9773A"), Color("#8E5224"), Color("#4B2A14"), Color("#22130A")]
	var f := clampf(doneness, 0.0, 1.0) * (stops.size() - 1)
	var i := mini(int(f), stops.size() - 2)
	return (stops[i] as Color).lerp(stops[i + 1], f - i)


## One cookie {shape, doneness, seed, rot, ops}: drawn at `at`, scaled `s`, turned by `rot`.
static func draw_cookie(ci: CanvasItem, ck: Dictionary, at: Vector2, s: float, rot := 0.0, shadow := true) -> void:
	var id: String = ck.shape
	var base := dough_color(float(ck.get("doneness", 0.5)))
	ci.draw_set_transform(at, rot, Vector2.ONE * s)
	_frame = Transform2D(rot, at).scaled_local(Vector2.ONE * s)
	var full := shape(id)
	if shadow:
		ci.draw_colored_polygon(_shifted(full, Vector2(2.2, 4.0)), Color(0.15, 0.08, 0.02, 0.28))
	ci.draw_colored_polygon(full, base.darkened(0.3))
	var top := inset(id, 2.4)
	if top.size() > 2:
		ci.draw_colored_polygon(top, base)
	var puff := inset(id, 7.0)
	if puff.size() > 2:
		ci.draw_colored_polygon(_shifted(puff, Vector2(-1.2, -1.4)), base.lightened(0.1))
	# Flecks of spice, always the same ones for this cookie.
	var rng := RandomNumberGenerator.new()
	rng.seed = int(ck.get("seed", 1))
	var specks := inset(id, 5.0)
	for i in 26:
		var p := Vector2(rng.randf_range(-48, 48), rng.randf_range(-48, 48))
		if specks.size() > 2 and Geometry2D.is_point_in_polygon(p, specks):
			ci.draw_circle(p, rng.randf_range(0.5, 1.2), Color(base.darkened(0.4), 0.45))
	for op: Dictionary in ck.get("ops", []):
		_draw_op(ci, op, id)
	ci.draw_polyline(_closed(full), base.darkened(0.45), 1.0, true)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	_frame = Transform2D.IDENTITY


static func _closed(p: PackedVector2Array) -> PackedVector2Array:
	var c := p.duplicate()
	if p.size() > 0:
		c.append(p[0])
	return c


static func _shifted(p: PackedVector2Array, d: Vector2) -> PackedVector2Array:
	var out := PackedVector2Array()
	for v in p:
		out.append(v + d)
	return out


static func _draw_op(ci: CanvasItem, op: Dictionary, id: String) -> void:
	match op.t:
		"flood":
			var c: Color = op.c
			var edge := inset(id, 2.4)
			if edge.size() > 2:
				ci.draw_colored_polygon(edge, c.darkened(0.2))
			var body := inset(id, 3.8)
			if body.size() > 2:
				ci.draw_colored_polygon(body, c)
				var shine := inset(id, 9.0)
				if shine.size() > 2:
					ci.draw_colored_polygon(_shifted(shine, Vector2(-1.5, -1.8)), c.lightened(0.14))
				ci.draw_polyline(_closed(_shifted(inset(id, 6.0), Vector2(-0.8, -0.9))), Color(1, 1, 1, 0.28), 1.2, true)
		"line":
			var pts: PackedVector2Array = op.pts
			var w: float = op.w
			var c: Color = op.c
			if pts.size() == 1:
				ci.draw_circle(pts[0], w * 0.5, c)
				ci.draw_circle(pts[0] + Vector2(-w * 0.12, -w * 0.15), w * 0.16, Color(1, 1, 1, 0.45))
			elif pts.size() > 1:
				ci.draw_polyline(pts, c.darkened(0.18), w + 0.8, true)
				ci.draw_circle(pts[0], w * 0.5 + 0.4, c.darkened(0.18))
				ci.draw_circle(pts[pts.size() - 1], w * 0.5 + 0.4, c.darkened(0.18))
				ci.draw_polyline(pts, c, w, true)
				ci.draw_circle(pts[0], w * 0.5, c)
				ci.draw_circle(pts[pts.size() - 1], w * 0.5, c)
				var hi := PackedVector2Array()
				for p in pts:
					hi.append(p + Vector2(-w * 0.18, -w * 0.2))
				ci.draw_polyline(hi, Color(1, 1, 1, 0.38), maxf(0.6, w * 0.25), true)
		"candy":
			candy(ci, op.id, op.p, float(op.rot), op.c)
		"bits":
			for b: Dictionary in op.bits:
				draw_bit(ci, op.kind, b)


# ── Candies and sprinkles ───────────────────────────────────

## One candy at `p` in cookie units, turned by `rot`, of colour `c` (some have a colour of their own).
static func candy(ci: CanvasItem, id: String, p: Vector2, rot: float, c: Color) -> void:
	_with(ci, Transform2D(rot, p), func() -> void: _candy_local(ci, id, c))


## Draws `body` in a frame moved by `xf` inside the current cookie frame (the cookie frame is kept by `_frame`).
static var _frame := Transform2D.IDENTITY


static func _with(ci: CanvasItem, xf: Transform2D, body: Callable) -> void:
	var saved := _frame
	ci.draw_set_transform_matrix(saved * xf)
	body.call()
	ci.draw_set_transform_matrix(saved)


static func _candy_local(ci: CanvasItem, id: String, c: Color) -> void:
	match id:
		"smarties":
			ci.draw_circle(Vector2(0.4, 0.9), 4.4, Color(0, 0, 0, 0.22))
			ci.draw_circle(Vector2.ZERO, 4.4, c.darkened(0.25))
			ci.draw_circle(Vector2.ZERO, 3.7, c)
			ci.draw_arc(Vector2(-0.5, -0.5), 2.4, PI * 1.05, PI * 1.6, 8, Color(1, 1, 1, 0.55), 0.9, true)
		"cannelle":
			ci.draw_circle(Vector2(0.3, 0.7), 2.8, Color(0, 0, 0, 0.25))
			ci.draw_circle(Vector2.ZERO, 2.8, Color("#9C1620"))
			ci.draw_circle(Vector2.ZERO, 2.3, Color("#D42A32"))
			ci.draw_circle(Vector2(-0.8, -0.8), 0.8, Color(1, 1, 1, 0.6))
		"gomme":
			ci.draw_circle(Vector2(0.4, 1.0), 4.9, Color(0, 0, 0, 0.22))
			var dome := PackedVector2Array()
			for i in 13:
				var a := PI + PI * i / 12.0
				dome.append(Vector2(cos(a) * 5.0, sin(a) * 5.2 + 2.6))
			ci.draw_colored_polygon(dome, c)
			ci.draw_polyline(_closed(dome), c.darkened(0.3), 0.8, true)
			for k in 7:
				var q := Vector2(-3.4 + k * 1.15, -1.0 + sin(k * 2.3) * 2.0)
				ci.draw_circle(q, 0.45, Color(1, 1, 1, 0.85))
			ci.draw_arc(Vector2(-0.6, 0.6), 3.3, PI * 1.15, PI * 1.55, 6, Color(1, 1, 1, 0.5), 0.9, true)
		"pepite":
			var drop := PackedVector2Array([Vector2(-3.4, 2.6), Vector2(3.4, 2.6), Vector2(2.2, -0.6), Vector2(0, -3.8), Vector2(-2.2, -0.6)])
			ci.draw_colored_polygon(drop, Color("#4A2A16"))
			ci.draw_polyline(_closed(drop), Color("#2A140A"), 0.7, true)
			ci.draw_line(Vector2(-1.2, 1.2), Vector2(-0.4, -1.4), Color(1, 1, 1, 0.3), 0.8)
		"guimauve":
			ci.draw_rect(Rect2(-3.3, -3.0, 7.0, 7.0), Color(0, 0, 0, 0.18))
			ci.draw_rect(Rect2(-3.6, -3.6, 7.2, 7.2), Color("#FFF8F0"))
			ci.draw_rect(Rect2(-3.6, -3.6, 7.2, 7.2), Color("#E3D6C8"), false, 0.8)
			ci.draw_line(Vector2(-2.6, -2.6), Vector2(1.0, -2.6), Color(1, 1, 1), 1.2)
		"yeux":
			ci.draw_circle(Vector2(0.3, 0.8), 4.6, Color(0, 0, 0, 0.2))
			ci.draw_circle(Vector2.ZERO, 4.6, Color("#C9C9D2"))
			ci.draw_circle(Vector2.ZERO, 4.0, Color.WHITE)
			ci.draw_circle(Vector2(0.4, 0.5), 2.1, Color("#1E1E26"))
			ci.draw_circle(Vector2(-0.3, -0.3), 0.7, Color.WHITE)
		"bouton":
			ci.draw_circle(Vector2(0.4, 0.9), 4.8, Color(0, 0, 0, 0.2))
			ci.draw_circle(Vector2.ZERO, 4.8, c.darkened(0.25))
			ci.draw_circle(Vector2.ZERO, 4.1, c)
			ci.draw_arc(Vector2.ZERO, 2.9, 0.0, TAU, 14, c.darkened(0.18), 0.6, true)
			for d in [Vector2(-0.9, -0.9), Vector2(0.9, -0.9), Vector2(-0.9, 0.9), Vector2(0.9, 0.9)]:
				ci.draw_circle(d, 0.45, c.darkened(0.5))
		"coeur":
			var heart := PackedVector2Array()
			for i in 20:
				var t := TAU * i / 20.0
				heart.append(Vector2(16.0 * pow(sin(t), 3.0), -(13.0 * cos(t) - 5.0 * cos(2.0 * t) - 2.0 * cos(3.0 * t) - cos(4.0 * t))) * 0.31)
			ci.draw_colored_polygon(heart, Color("#FF6FA3"))
			ci.draw_polyline(_closed(heart), Color("#C23A74"), 0.7, true)
			ci.draw_circle(Vector2(-1.7, -1.3), 0.7, Color(1, 1, 1, 0.65))
		"etoile":
			var star := PackedVector2Array()
			for i in 10:
				var a := -PI / 2.0 + i * PI / 5.0
				var r := 5.4 if i % 2 == 0 else 2.4
				star.append(Vector2(cos(a), sin(a)) * r)
			ci.draw_colored_polygon(star, Color("#F6C833"))
			ci.draw_polyline(_closed(star), Color("#B88A12"), 0.7, true)
			ci.draw_circle(Vector2(-0.8, -1.0), 0.7, Color(1, 1, 1, 0.7))
		"baton":
			for k in 5:
				var col := Color("#E5383B") if k % 2 == 0 else Color.WHITE
				ci.draw_line(Vector2(-6.0 + k * 2.4, 0), Vector2(-3.6 + k * 2.4, 0), col, 2.6)
			ci.draw_rect(Rect2(-6.0, -1.3, 12.0, 2.6), Color("#B02A30"), false, 0.7)
			ci.draw_line(Vector2(-5.5, -0.7), Vector2(5.5, -0.7), Color(1, 1, 1, 0.45), 0.6)
		"dragee":
			ci.draw_circle(Vector2(0.3, 0.7), 3.0, Color(0, 0, 0, 0.22))
			ci.draw_circle(Vector2.ZERO, 3.0, c.lerp(Color("#C8A23A"), 0.7).darkened(0.2))
			ci.draw_circle(Vector2.ZERO, 2.5, c.lerp(Color("#F2D56B"), 0.7))
			ci.draw_circle(Vector2(-0.8, -0.9), 0.8, Color(1, 1, 1, 0.85))


static func draw_bit(ci: CanvasItem, kind: String, b: Dictionary) -> void:
	var p: Vector2 = b.p
	var c: Color = b.c
	var rot: float = b.rot
	match kind:
		"arcenciel", "noel":
			var d := Vector2.from_angle(rot) * 1.7
			ci.draw_line(p - d, p + d, c.darkened(0.2), 1.5)
			ci.draw_line(p - d * 0.9, p + d * 0.9, c, 1.1)
		"argent", "or":
			ci.draw_circle(p, 1.1, c.darkened(0.25))
			ci.draw_circle(p, 0.9, c)
			ci.draw_circle(p + Vector2(-0.3, -0.3), 0.3, Color(1, 1, 1, 0.9))
		"etoiles":
			var star := PackedVector2Array()
			for i in 10:
				var a := rot - PI / 2.0 + i * PI / 5.0
				star.append(p + Vector2(cos(a), sin(a)) * (1.9 if i % 2 == 0 else 0.8))
			ci.draw_colored_polygon(star, c)
		"sucre":
			ci.draw_circle(p, 0.5, Color(1, 1, 1, 0.95))
			ci.draw_circle(p + Vector2(0.35, 0.35), 0.3, Color(0.7, 0.7, 0.8, 0.5))
		"glace":
			ci.draw_circle(p, 0.55, Color(1, 1, 1, 0.5))


## A little picture of a candy for the sidebar button, centred in `rect`.
static func candy_icon(ci: CanvasItem, id: String, center: Vector2, size: float, c: Color) -> void:
	ci.draw_set_transform(center, 0.0, Vector2.ONE * size / 11.0)
	_frame = Transform2D(0.0, center).scaled_local(Vector2.ONE * size / 11.0)
	_candy_local(ci, id, c)
	_frame = Transform2D.IDENTITY
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## The colour of a sprinkle bit of this kind (the same ones every time for a given random number).
static func bit_color(kind: String, rng: RandomNumberGenerator) -> Color:
	match kind:
		"arcenciel":
			return Color(CANDY_COLORS[rng.randi() % CANDY_COLORS.size()])
		"noel":
			return Color("#D8283A") if rng.randf() < 0.5 else Color("#2F9E55")
		"argent":
			return Color("#C9CED6")
		"or", "etoiles":
			return Color("#F2C230")
	return Color.WHITE


# ── The counter ─────────────────────────────────────────────

## An ingredient standing at `at` (its foot), `s` bigger, tipped by `tilt` radians about its middle.
static func ingredient(ci: CanvasItem, id: String, at: Vector2, s := 1.0, tilt := 0.0) -> void:
	var mid := at + Vector2(0, -50.0 * s)
	ci.draw_set_transform(mid, tilt, Vector2.ONE * s)
	var o := Vector2(0, 50)   # `at` seen from the middle
	var shade := Color(0, 0, 0, 0.18)
	match id:
		"farine":
			# A paper bag of flour, its top folded over, a label with a wheat ear.
			ci.draw_colored_polygon(_rr(Vector2(-27, -46), Vector2(27, 50), 5), Color("#F4EEE2"))
			ci.draw_colored_polygon(_rr(Vector2(-27, -46), Vector2(-14, 50), 4), Color(0.8, 0.74, 0.6, 0.35))
			ci.draw_rect(Rect2(-27, -50, 54, 11), Color("#E4D8BF"))
			ci.draw_line(Vector2(-27, -39), Vector2(27, -39), Color("#BFAE88"), 1.2)
			ci.draw_rect(Rect2(-17, -26, 34, 38), Color("#C9322E"))
			ci.draw_rect(Rect2(-17, -26, 34, 38), Color("#7E1418"), false, 1.2)
			for k in 3:
				ci.draw_circle(Vector2(-4.0 + k * 4.0, -2.0 - k * 1.5), 2.0, Color("#F2C230"))
			ci.draw_line(Vector2(0, 10), Vector2(0, -8), Color("#F2C230"), 1.6)
			ci.draw_rect(Rect2(-12, 16, 24, 4), Color(1, 1, 1, 0.8))
			ci.draw_polyline(_closed(_rr(Vector2(-27, -46), Vector2(27, 50), 5)), Color("#9B8B6A"), 1.4, true)
		"cassonade":
			ci.draw_colored_polygon(_rr(Vector2(-26, -40), Vector2(26, 50), 5), Color("#C98A4B"))
			ci.draw_colored_polygon(_rr(Vector2(-26, -40), Vector2(-12, 50), 4), Color(1, 1, 1, 0.12))
			ci.draw_rect(Rect2(-26, -46, 52, 10), Color("#A86B33"))
			ci.draw_line(Vector2(-26, -36), Vector2(26, -36), Color("#7A4A24"), 1.2)
			ci.draw_rect(Rect2(-16, -22, 32, 34), Color("#FFF1D6"))
			ci.draw_rect(Rect2(-16, -22, 32, 34), Color("#7A4A24"), false, 1.2)
			for k in 6:
				ci.draw_circle(Vector2(-8.0 + (k % 3) * 8.0, -12.0 + (k / 3) * 9.0), 2.4, Color("#B07A3C"))
			ci.draw_polyline(_closed(_rr(Vector2(-26, -40), Vector2(26, 50), 5)), Color("#7A4A24"), 1.4, true)
		"beurre":
			# A block of butter half out of its wrapper, on a little dish.
			ci.draw_colored_polygon(_rr(Vector2(-34, 30), Vector2(34, 50), 6), Color("#E8EDF2"))
			ci.draw_polyline(_closed(_rr(Vector2(-34, 30), Vector2(34, 50), 6)), Color("#9FB2C6"), 1.2, true)
			ci.draw_colored_polygon(PackedVector2Array([Vector2(-28, 30), Vector2(26, 30), Vector2(30, 6), Vector2(-24, 6)]), Color("#FFE680"))
			ci.draw_colored_polygon(PackedVector2Array([Vector2(26, 30), Vector2(30, 6), Vector2(36, 12), Vector2(33, 30)]), Color("#E8C84A"))
			ci.draw_colored_polygon(PackedVector2Array([Vector2(-24, 6), Vector2(30, 6), Vector2(36, 12), Vector2(-18, 12)]), Color("#FFF2A8"))
			ci.draw_rect(Rect2(-28, 14, 56, 16), Color("#F2F2F2"))
			ci.draw_rect(Rect2(-28, 14, 56, 16), Color("#B8B8C0"), false, 1.0)
			ci.draw_rect(Rect2(-14, 18, 28, 8), Color("#2E6FD8"))
			ci.draw_line(Vector2(-22, 8), Vector2(18, 8), Color(1, 1, 1, 0.7), 1.4)
			o = Vector2(0, 50)
		"oeuf":
			var egg := PackedVector2Array()
			for i in 36:
				var t := TAU * i / 36.0
				var r := Vector2(cos(t) * 21.0, sin(t) * 28.0)
				r.x *= 1.0 - 0.14 * sin(t)
				egg.append(r + Vector2(0, 12))
			ci.draw_colored_polygon(_shifted(egg, Vector2(1.5, 3.0)), shade)
			ci.draw_colored_polygon(egg, Color("#F3E3C8"))
			ci.draw_colored_polygon(_shifted(_scaled(egg, 0.82), Vector2(-3, -3)), Color("#FFF3DF"))
			ci.draw_polyline(_closed(egg), Color("#C4A878"), 1.4, true)
			ci.draw_circle(Vector2(-8, 2), 2.2, Color(1, 1, 1, 0.8))
		"melasse":
			ci.draw_colored_polygon(_rr(Vector2(-25, -22), Vector2(25, 50), 9), Color("#3A1E0C"))
			ci.draw_colored_polygon(_rr(Vector2(-25, -22), Vector2(-14, 50), 6), Color(1, 1, 1, 0.1))
			ci.draw_rect(Rect2(-18, -8, 36, 36), Color("#F2D9A0"))
			ci.draw_rect(Rect2(-18, -8, 36, 36), Color("#7A4A24"), false, 1.2)
			ci.draw_circle(Vector2(0, 10), 8.0, Color("#3A1E0C"))
			ci.draw_circle(Vector2(0, 10), 4.5, Color("#F2D9A0"))
			ci.draw_rect(Rect2(-17, -36, 34, 16), Color("#C9322E"))
			ci.draw_rect(Rect2(-17, -36, 34, 16), Color("#7E1418"), false, 1.2)
			for k in 4:
				ci.draw_line(Vector2(-12 + k * 8, -35), Vector2(-12 + k * 8, -22), Color("#9B1C20"), 1.0)
			ci.draw_polyline(_closed(_rr(Vector2(-25, -22), Vector2(25, 50), 9)), Color("#1E0E04"), 1.4, true)
			ci.draw_line(Vector2(-19, -14), Vector2(-19, 42), Color(1, 1, 1, 0.18), 2.0)
		"gingembre", "cannelle":
			var lid := Color("#E0842A") if id == "gingembre" else Color("#B5442E")
			var dust := Color("#C98A2E") if id == "gingembre" else Color("#8A4A2A")
			ci.draw_colored_polygon(_rr(Vector2(-19, -20), Vector2(19, 50), 6), Color("#E8F0F6", 0.9))
			ci.draw_colored_polygon(PackedVector2Array([Vector2(-17, 12), Vector2(17, 12), Vector2(17, 46), Vector2(-17, 46)]), dust)
			ci.draw_polyline(_closed(_rr(Vector2(-19, -20), Vector2(19, 50), 6)), Color("#9FB2C6"), 1.3, true)
			ci.draw_line(Vector2(-15, -14), Vector2(-15, 40), Color(1, 1, 1, 0.55), 2.0)
			ci.draw_rect(Rect2(-20, -34, 40, 15), lid)
			ci.draw_rect(Rect2(-20, -34, 40, 15), lid.darkened(0.4), false, 1.2)
			ci.draw_line(Vector2(-17, -31), Vector2(17, -31), lid.lightened(0.4), 1.2)
			ci.draw_rect(Rect2(-14, -6, 28, 14), Color("#FFF8E6"))
			if id == "cannelle":
				ci.draw_line(Vector2(-8, -16), Vector2(2, -46), Color("#8A4A2A"), 3.0)
				ci.draw_line(Vector2(2, -16), Vector2(12, -44), Color("#9B5A32"), 3.0)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if o == Vector2.ZERO:
		return


static func _rr(a: Vector2, b: Vector2, r_in: float) -> PackedVector2Array:
	var r := minf(r_in, minf(absf(b.x - a.x), absf(b.y - a.y)) / 2.0 - 0.05)
	var pts := PackedVector2Array()
	var corners := [[Vector2(b.x - r, a.y + r), -PI / 2.0], [Vector2(b.x - r, b.y - r), 0.0], [Vector2(a.x + r, b.y - r), PI / 2.0], [Vector2(a.x + r, a.y + r), PI]]
	for cc in corners:
		for i in 5:
			pts.append((cc[0] as Vector2) + Vector2.from_angle(float(cc[1]) + PI / 2.0 * i / 4.0) * r)
	return pts


static func _scaled(p: PackedVector2Array, k: float) -> PackedVector2Array:
	var mid := Vector2.ZERO
	for v in p:
		mid += v
	mid /= maxf(1.0, p.size())
	var out := PackedVector2Array()
	for v in p:
		out.append(mid + (v - mid) * k)
	return out


## A big mixing bowl seen from above and a little in front, centred at `c`, `rx` wide: the rim, the inside, the shine.
static func bowl(ci: CanvasItem, c: Vector2, rx: float) -> void:
	var ry := rx * 0.55
	ci.draw_colored_polygon(_ell(c + Vector2(10, 150), rx * 0.74, ry * 0.3), Color(0, 0, 0, 0.2))
	# The side: from the rim's lower half down to a smaller base.
	var side := PackedVector2Array()
	for i in 21:
		var a := PI * i / 20.0
		side.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	for i in 21:
		var a := PI - PI * i / 20.0
		side.append(c + Vector2(cos(a) * rx * 0.62, 92.0 + sin(a) * ry * 0.62))
	side = Geometry2D.convex_hull(side)
	ci.draw_colored_polygon(side, Color("#3E7BC4"))
	ci.draw_colored_polygon(_shifted(_scaled(side, 0.96), Vector2(-10, -2)), Color("#5C95D8", 0.55))
	ci.draw_polyline(_closed(side), Color("#2A5A98"), 2.0, true)
	var gloss := PackedVector2Array()
	for i in 15:
		var a := 0.5 + (PI - 1.0) * i / 14.0
		gloss.append(c + Vector2(cos(a) * rx * 0.86, 22.0 + sin(a) * ry * 0.7))
	ci.draw_polyline(gloss, Color(1, 1, 1, 0.25), 4.0, true)
	ci.draw_colored_polygon(_ell(c, rx, ry), Color("#F4F8FB"))
	ci.draw_colored_polygon(_ell(c + Vector2(0, 3), rx * 0.92, ry * 0.9), Color("#E6D9BE"))
	ci.draw_polyline(_closed(_ell(c, rx, ry)), Color("#9FB2C6"), 2.0, true)
	var shine := PackedVector2Array()
	for i in 13:
		var a := PI * 1.08 + PI * 0.4 * i / 12.0
		shine.append(c + Vector2(cos(a) * rx * 0.96, sin(a) * ry * 0.96))
	ci.draw_polyline(shine, Color(1, 1, 1, 0.9), 3.0, true)


static func _ell(c: Vector2, rx: float, ry: float, n := 40) -> PackedVector2Array:
	return _ellipse(c, rx, ry, n)


## A wooden spoon, its tip at `tip`, leaning toward the upper right.
static func spoon(ci: CanvasItem, tip: Vector2, angle := -1.0) -> void:
	ci.draw_set_transform(tip, angle, Vector2.ONE)
	ci.draw_colored_polygon(_ellipse(Vector2(3, 5), 14.0, 9.0), Color(0, 0, 0, 0.16))
	ci.draw_colored_polygon(_ellipse(Vector2(0, 0), 16.0, 11.0), Color("#C98F52"))
	ci.draw_colored_polygon(_ellipse(Vector2(-2, -2), 11.0, 7.0), Color("#DDA86C"))
	ci.draw_colored_polygon(PackedVector2Array([Vector2(8, -5), Vector2(150, -4), Vector2(150, 4), Vector2(8, 5)]), Color("#B9803F"))
	ci.draw_line(Vector2(10, -2), Vector2(150, -2), Color("#DDA86C"), 2.0)
	ci.draw_polyline(_closed(_ellipse(Vector2.ZERO, 16.0, 11.0)), Color("#7A4A24"), 1.4, true)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## A rolling pin lying across the view at `c`, `len` long.
static func rolling_pin(ci: CanvasItem, c: Vector2, len := 330.0) -> void:
	var h := 21.0
	ci.draw_colored_polygon(_rr(c + Vector2(-len * 0.5 + 4, h * 0.6), c + Vector2(len * 0.5 + 4, h * 1.5), 8), Color(0, 0, 0, 0.14))
	ci.draw_rect(Rect2(c.x - len * 0.5 - 38, c.y - 6, 40, 12), Color("#B07A3E"))
	ci.draw_rect(Rect2(c.x + len * 0.5 - 2, c.y - 6, 40, 12), Color("#B07A3E"))
	ci.draw_colored_polygon(_rr(c + Vector2(-len * 0.5, -h), c + Vector2(len * 0.5, h), 10), Color("#D9A768"))
	ci.draw_colored_polygon(_rr(c + Vector2(-len * 0.5 + 4, -h + 3), c + Vector2(len * 0.5 - 4, -h + 11), 3), Color("#EBC28A"))
	ci.draw_colored_polygon(_rr(c + Vector2(-len * 0.5, h - 9), c + Vector2(len * 0.5, h), 8), Color("#A87636", 0.6))
	ci.draw_polyline(_closed(_rr(c + Vector2(-len * 0.5, -h), c + Vector2(len * 0.5, h), 10)), Color("#7A4A24"), 1.6, true)
	for k in 3:
		ci.draw_line(c + Vector2(-len * 0.5 + 20 + k * 90, -h + 2), c + Vector2(-len * 0.5 + 70 + k * 90, -h + 2), Color(1, 1, 1, 0.22), 1.5)


## A cookie cutter's outline (metal, with its rolled rim) for the shape `id` at `at`, scaled `s`, turned `rot`.
static func cutter(ci: CanvasItem, id: String, at: Vector2, s: float, rot: float, lifted := 0.0) -> void:
	ci.draw_set_transform(at - Vector2(0, lifted), rot, Vector2.ONE * s)
	var p := shape(id)
	ci.draw_polyline(_closed(_shifted(p, Vector2(0, 5))), Color(0, 0, 0, 0.18), 5.0, true)
	ci.draw_polyline(_closed(p), Color("#9AA3AD"), 5.0, true)
	ci.draw_polyline(_closed(p), Color("#D7DEE6"), 3.0, true)
	var hi := _shifted(p, Vector2(-0.7, -0.7))
	ci.draw_polyline(_closed(hi), Color(1, 1, 1, 0.8), 1.0, true)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


# ── The plate ───────────────────────────────────────────────

## Where cookie `i` of `n` stands on the plate: x in -1..1 across it, row 0 (front) .. 1 (back), a small lean in radians.
static func plate_slot(i: int, n: int) -> Vector3:
	var rows := 1 if n <= 4 else (2 if n <= 8 else 3)
	var per := int(ceil(float(n) / rows))
	var row := i / per
	var col := i % per
	var in_row := mini(per, n - row * per)
	var step := 1.6 / maxf(1.0, per - 0.5)
	var shift := 0.25 if row % 2 == 1 else -0.25
	var x := (col - (in_row - 1) / 2.0 + (shift if rows > 1 else 0.0)) * step
	var lean := sin(i * 2.7) * 0.2
	return Vector3(x, float(row) / maxf(1.0, rows - 1.0) if rows > 1 else 0.0, lean)


## Her cookies standing on a plate, leaning on each other, in `rect` (plate-scene units, feet on its bottom edge), the whole
## scene drawn `k` times bigger from `origin`.
static func plate_cookies(ci: CanvasItem, cookies: Array, rect: Rect2, origin: Vector2, k: float) -> void:
	var n := cookies.size()
	if n == 0:
		return
	var rows := 1 if n <= 4 else (2 if n <= 8 else 3)
	var per := int(ceil(float(n) / rows))
	var sc := minf(rect.size.x / (per * 62.0 + 24.0), rect.size.y / (100.0 + (rows - 1) * 46.0))
	var order: Array = []
	for i in n:
		order.append(i)
	order.sort_custom(func(a: int, b: int) -> bool: return plate_slot(a, n).y > plate_slot(b, n).y)
	for i: int in order:
		var slot := plate_slot(i, n)
		var x := rect.get_center().x + slot.x * (rect.size.x * 0.5 - 50.0 * sc)
		var y := rect.end.y - 50.0 * sc - slot.y * (rows - 1) * 46.0 * sc
		draw_cookie(ci, cookies[i], origin + Vector2(x, y) * k, sc * k, slot.z, true)


## The whole picture on a 110 × 80 canvas (Charlotte's plate for Santa), `k` times bigger from `origin`: the plate, her cookies
## and the drink; `eaten`: crumbs, an empty glass and Santa's folded note.
static func plate_scene(ci: CanvasItem, origin: Vector2, k: float, cookies: Array, plate: String, drink: String, eaten: bool) -> void:
	ci.draw_set_transform(origin, 0.0, Vector2.ONE * k)
	var rim := Color.WHITE
	var inner := Color("#EEF3F8")
	var edge := Color("#B8C4D0")
	match plate:
		"noel":
			inner = Color("#F8F2E6")
		"bleue":
			rim = Color("#5B8FD8")
			inner = Color("#E6F0FA")
			edge = Color("#2E5FA8")
	ci.draw_colored_polygon(_ellipse(Vector2(48, 66), 44.0, 11.5), Color(0, 0, 0, 0.18))
	ci.draw_colored_polygon(_ellipse(Vector2(46, 64), 42.0, 11.0), rim)
	ci.draw_polyline(_closed(_ellipse(Vector2(46, 64), 42.0, 11.0)), edge, 1.0, true)
	ci.draw_colored_polygon(_ellipse(Vector2(46, 62.5), 32.0, 7.5), inner)
	ci.draw_polyline(_closed(_ellipse(Vector2(46, 62.5), 32.0, 7.5)), edge.lightened(0.3), 0.6, true)
	if plate == "noel":
		ci.draw_polyline(_closed(_ellipse(Vector2(46, 64), 38.5, 9.6)), Color("#C8283A"), 1.4, true)
		for j in 12:
			var a := TAU * j / 12.0
			var q := Vector2(46, 64) + Vector2(cos(a) * 40.5, sin(a) * 10.4)
			ci.draw_circle(q, 1.0, Color("#2F7A45") if j % 2 == 0 else Color("#C8283A"))
	elif plate == "bleue":
		for j in 10:
			var a := TAU * j / 10.0
			ci.draw_circle(Vector2(46, 64) + Vector2(cos(a) * 38.0, sin(a) * 9.6), 1.0, Color.WHITE)
	if eaten:
		for pcs in [[30, 62], [40, 60], [52, 64], [60, 61], [45, 65], [36, 64], [56, 59]]:
			ci.draw_circle(Vector2(pcs[0], pcs[1]), 1.5, Color("#B5793F"))
			ci.draw_circle(Vector2(pcs[0] + 0.5, pcs[1] - 0.4), 0.6, Color("#D9A066"))
		ci.draw_set_transform(origin + Vector2(27, 50) * k, -0.14, Vector2.ONE * k)
		ci.draw_rect(Rect2(-13, -9, 26, 18), Color("#FFFDF5"))
		ci.draw_rect(Rect2(-13, -9, 26, 18), Color("#C9BBA0"), false, 1.0)
		ci.draw_line(Vector2(-9, -3), Vector2(7, -3), Color("#D42A3A"), 1.2)
		ci.draw_line(Vector2(-9, 2), Vector2(3, 2), Color("#D42A3A"), 1.2)
	else:
		plate_cookies(ci, cookies, Rect2(8, 4, 78, 58), origin, k)
	ci.draw_set_transform(origin, 0.0, Vector2.ONE * k)
	glass(ci, Vector2(93, 70), 1.0, drink, eaten)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## A glass of milk (or chocolate milk), or a mug of hot chocolate with marshmallows, standing at `at` (its foot).
static func glass(ci: CanvasItem, at: Vector2, s: float, drink: String, empty: bool) -> void:
	if drink == "chaud":
		var body := _rr(at + Vector2(-11, -26) * s, at + Vector2(11, 0) * s, 4.0 * s)
		ci.draw_colored_polygon(body, Color("#C8283A"))
		ci.draw_polyline(_closed(body), Color("#7E1418"), 1.0, true)
		ci.draw_arc(at + Vector2(13, -14) * s, 6.0 * s, -PI / 2.0, PI / 2.0, 10, Color("#C8283A"), 3.0 * s, true)
		ci.draw_rect(Rect2(at + Vector2(-11, -19) * s, Vector2(22, 3) * s), Color.WHITE)
		ci.draw_line(at + Vector2(-8, -23) * s, at + Vector2(-8, -4) * s, Color(1, 1, 1, 0.4), 1.4 * s)
		if not empty:
			ci.draw_colored_polygon(_ellipse(at + Vector2(0, -25) * s, 10.0 * s, 2.4 * s), Color("#5A301A"))
			for m in [[-5.0, -26.5], [1.0, -27.0], [6.0, -25.5]]:
				ci.draw_rect(Rect2(at + Vector2(m[0] - 2.2, m[1] - 2.0) * s, Vector2(4.4, 4.0) * s), Color("#FFF8F0"))
			for j in 2:
				ci.draw_arc(at + Vector2(-3 + j * 6, -32) * s, 3.0 * s, PI, PI * 2.0, 6, Color(1, 1, 1, 0.5), 1.0 * s, true)
		return
	var glassy := PackedVector2Array([at + Vector2(-11, -46) * s, at + Vector2(11, -46) * s, at + Vector2(8, 0) * s, at + Vector2(-8, 0) * s])
	ci.draw_colored_polygon(glassy, Color("#E6F0FA"))
	if not empty:
		var liq := Color.WHITE if drink == "lait" else Color("#9A6240")
		ci.draw_colored_polygon(PackedVector2Array([at + Vector2(-10.4, -38) * s, at + Vector2(10.4, -38) * s, at + Vector2(7.8, -1) * s, at + Vector2(-7.8, -1) * s]), liq)
		ci.draw_line(at + Vector2(-10, -38) * s, at + Vector2(10, -38) * s, liq.lightened(0.2) if drink != "lait" else Color("#F0F4F8"), 1.2 * s)
	else:
		ci.draw_colored_polygon(PackedVector2Array([at + Vector2(-8.0, -5) * s, at + Vector2(8.0, -5) * s, at + Vector2(7.8, -1) * s, at + Vector2(-7.8, -1) * s]), Color(1, 1, 1, 0.75) if drink == "lait" else Color("#9A6240", 0.6))
	ci.draw_polyline(_closed(glassy), Color("#9FB2C6"), 1.0, true)
	ci.draw_line(at + Vector2(-8, -42) * s, at + Vector2(-6, -6) * s, Color(1, 1, 1, 0.7), 1.6 * s)
