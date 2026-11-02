class_name CuteArt
extends RefCounted
## Little drawings for the UI, drawn on any CanvasItem: a cat's, a dog's and a hamster's head, flowers, hearts, stars,
## a smiling sun, a house, Charlotte's self-portrait. Two styles: clean (outlined, for the menu) or `crayon` (a
## child's wax-crayon drawing for her notebook: hatched fill that stays inside the shape, a wobbly outline gone over
## twice). Sizes in px; `rng` makes the crayon wobble repeatable.

const LINE := Color("#3A3A48")
const PINK := Color("#F2A7B4")
## The notebook paper: the little gaps the wax leaves on its grain are this colour.
const PAPER := Color("#FBF6EA")


static func cat_head(ci: CanvasItem, c: Vector2, r: float, fur: Color, crayon := false, rng: RandomNumberGenerator = null) -> void:
	for side in [-1.0, 1.0]:
		var ear := [c + Vector2(side * 0.85, -0.35) * r, c + Vector2(side * 0.7, -1.15) * r, c + Vector2(side * 0.2, -0.75) * r]
		_shape(ci, ear, fur, crayon, rng)
		_shape(ci, [c + Vector2(side * 0.72, -0.48) * r, c + Vector2(side * 0.66, -0.95) * r, c + Vector2(side * 0.36, -0.7) * r], PINK, crayon, rng, false)
	_shape(ci, _oval(c, Vector2(r, r * 0.86)), fur, crayon, rng)
	_face(ci, c, r, crayon, rng)
	_nose(ci, c + Vector2(0, 0.12) * r, r * 0.12)
	for side in [-1.0, 1.0]:
		for k in 3:
			var a := c + Vector2(side * 0.35, 0.22 + k * 0.08) * r
			_stroke(ci, [a, a + Vector2(side * 0.55, -0.1 + k * 0.1) * r], LINE, maxf(1.0, r * 0.04), crayon, rng)


static func dog_head(ci: CanvasItem, c: Vector2, r: float, fur: Color, ear: Color, crayon := false, rng: RandomNumberGenerator = null) -> void:
	for side in [-1.0, 1.0]:
		var e := []
		for k in 13:
			var a := TAU * k / 12.0
			e.append(c + Vector2(side * 0.88, 0.05) * r + Vector2(cos(a) * 0.3, sin(a) * 0.62).rotated(side * -0.35) * r)
		_shape(ci, e, ear, crayon, rng)
	_shape(ci, _oval(c, Vector2(r * 0.86, r * 0.84)), fur, crayon, rng)
	_shape(ci, _oval(c + Vector2(0, 0.38) * r, Vector2(r * 0.46, r * 0.32)), fur.lightened(0.45), crayon, rng)
	_face(ci, c + Vector2(0, -0.08) * r, r, crayon, rng)
	_shape(ci, _oval(c + Vector2(0, 0.24) * r, Vector2(r * 0.17, r * 0.12)), Color("#2B2B33"), crayon, rng)
	_shape(ci, _oval(c + Vector2(0.06, 0.6) * r, Vector2(r * 0.11, r * 0.14)), Color("#E8778A"), crayon, rng)


static func hamster_head(ci: CanvasItem, c: Vector2, r: float, crayon := false, rng: RandomNumberGenerator = null) -> void:
	var fur := Color("#E8A65A")
	for side in [-1.0, 1.0]:
		_shape(ci, _oval(c + Vector2(side * 0.62, -0.72) * r, Vector2(r * 0.26, r * 0.26)), fur, crayon, rng)
		_shape(ci, _oval(c + Vector2(side * 0.62, -0.72) * r, Vector2(r * 0.14, r * 0.14)), PINK, crayon, rng, false)
	_shape(ci, _oval(c, Vector2(r * 1.05, r * 0.92)), fur, crayon, rng)
	# The white muzzle and stuffed cheeks.
	_shape(ci, _oval(c + Vector2(0, 0.3) * r, Vector2(r * 0.75, r * 0.5)), Color("#FBF1E2"), crayon, rng, false)
	_face(ci, c + Vector2(0, -0.12) * r, r * 0.9, crayon, rng)
	_nose(ci, c + Vector2(0, 0.1) * r, r * 0.1)
	ci.draw_rect(Rect2(c + Vector2(-0.08, 0.26) * r, Vector2(0.16, 0.16) * r), Color.WHITE)


static func flower(ci: CanvasItem, c: Vector2, r: float, petal: Color, crayon := false, rng: RandomNumberGenerator = null) -> void:
	for k in 5:
		var p := c + Vector2.from_angle(TAU * k / 5.0 - PI / 2.0) * r * 0.62
		_shape(ci, _oval(p, Vector2(r * 0.42, r * 0.42)), petal, crayon, rng)
	_shape(ci, _oval(c, Vector2(r * 0.36, r * 0.36)), Color("#F2C230"), crayon, rng)


static func heart(ci: CanvasItem, c: Vector2, r: float, color: Color, crayon := false, rng: RandomNumberGenerator = null) -> void:
	var pts := []
	for k in 24:
		var t := TAU * k / 24.0
		pts.append(c + Vector2(16 * pow(sin(t), 3), -(13 * cos(t) - 5 * cos(2 * t) - 2 * cos(3 * t) - cos(4 * t))) * r / 16.0)
	_shape(ci, pts, color, crayon, rng)


static func star(ci: CanvasItem, c: Vector2, r: float, color: Color, crayon := false, rng: RandomNumberGenerator = null) -> void:
	var pts := []
	for k in 10:
		pts.append(c + Vector2.from_angle(-PI / 2.0 + TAU * k / 10.0) * (r if k % 2 == 0 else r * 0.45))
	_shape(ci, pts, color, crayon, rng)


static func sun(ci: CanvasItem, c: Vector2, r: float, crayon := false, rng: RandomNumberGenerator = null) -> void:
	for k in 10:
		var d := Vector2.from_angle(TAU * k / 10.0 + 0.15)
		_shape(ci, [c + d.rotated(0.16) * r * 1.15, c + d * r * 1.7, c + d.rotated(-0.16) * r * 1.15], Color("#F29B30"), crayon, rng)
	_shape(ci, _oval(c, Vector2(r, r)), Color("#FFD23F"), crayon, rng)
	_face(ci, c, r * 0.9, crayon, rng)


# A child's house: walls, a pointed roof, a door and a window with a cross.
static func house(ci: CanvasItem, c: Vector2, r: float, crayon := false, rng: RandomNumberGenerator = null) -> void:
	_shape(ci, [c + Vector2(-0.8, -0.1) * r, c + Vector2(0.8, -0.1) * r, c + Vector2(0.8, 0.9) * r, c + Vector2(-0.8, 0.9) * r], Color("#E8812E"), crayon, rng)
	_shape(ci, [c + Vector2(-1.0, -0.1) * r, c + Vector2(0, -0.95) * r, c + Vector2(1.0, -0.1) * r], Color("#D9342B"), crayon, rng)
	_shape(ci, [c + Vector2(-0.18, 0.4) * r, c + Vector2(0.18, 0.4) * r, c + Vector2(0.18, 0.9) * r, c + Vector2(-0.18, 0.9) * r], Color("#3D8BD9"), crayon, rng)
	var w := c + Vector2(0.48, 0.25) * r
	_shape(ci, [w + Vector2(-0.18, -0.16) * r, w + Vector2(0.18, -0.16) * r, w + Vector2(0.18, 0.16) * r, w + Vector2(-0.18, 0.16) * r], Color("#BFE3F7"), crayon, rng)
	_stroke(ci, [w + Vector2(0, -0.16) * r, w + Vector2(0, 0.16) * r], LINE, 1.5, crayon, rng)
	_stroke(ci, [w + Vector2(-0.18, 0) * r, w + Vector2(0.18, 0) * r], LINE, 1.5, crayon, rng)


# Charlotte drawing herself: long auburn hair, a big smile, her yellow dress, stick arms and legs.
static func me(ci: CanvasItem, c: Vector2, r: float, crayon := false, rng: RandomNumberGenerator = null) -> void:
	var hair := Color("#B5602E")
	_shape(ci, [c + Vector2(-0.55, -0.4) * r, c + Vector2(0.55, -0.4) * r, c + Vector2(0.62, 0.45) * r, c + Vector2(-0.62, 0.45) * r], hair, crayon, rng)
	_shape(ci, _oval(c + Vector2(0, -0.3) * r, Vector2(r * 0.45, r * 0.45)), Color("#F6D2B8"), crayon, rng)
	_shape(ci, _oval(c + Vector2(0, -0.7) * r, Vector2(r * 0.5, r * 0.2)), hair, crayon, rng, false)
	_face(ci, c + Vector2(0, -0.32) * r, r * 0.42, crayon, rng)
	_shape(ci, [c + Vector2(-0.18, 0.15) * r, c + Vector2(0.18, 0.15) * r, c + Vector2(0.5, 1.0) * r, c + Vector2(-0.5, 1.0) * r], Color("#FFD23F"), crayon, rng)
	for side in [-1.0, 1.0]:
		_stroke(ci, [c + Vector2(side * 0.2, 0.3) * r, c + Vector2(side * 0.6, 0.55) * r], LINE, 2.0, crayon, rng)
		_stroke(ci, [c + Vector2(side * 0.2, 1.0) * r, c + Vector2(side * 0.22, 1.35) * r], LINE, 2.0, crayon, rng)


# ── Pieces ──────────────────────────────────────────────────

# Eyes with a shine, rosy cheeks and a smile.
static func _face(ci: CanvasItem, c: Vector2, r: float, crayon: bool, rng: RandomNumberGenerator) -> void:
	for side in [-1.0, 1.0]:
		var e := c + Vector2(side * 0.36, -0.05) * r
		ci.draw_circle(e, r * 0.13, Color("#2B2B33"))
		ci.draw_circle(e + Vector2(-0.04, -0.05) * r, r * 0.05, Color.WHITE)
		ci.draw_circle(c + Vector2(side * 0.58, 0.25) * r, r * 0.13, Color(PINK, 0.7))
	var smile := []
	for k in 9:
		smile.append(c + Vector2.from_angle(lerpf(0.5, PI - 0.5, k / 8.0)) * r * 0.22 + Vector2(0, 0.14) * r)
	_stroke(ci, smile, LINE, maxf(1.5, r * 0.06), crayon, rng)


static func _nose(ci: CanvasItem, c: Vector2, r: float) -> void:
	ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-r, -r * 0.5), c + Vector2(r, -r * 0.5), c + Vector2(0, r * 0.6)]), Color("#E8778A"))


static func _oval(c: Vector2, radii: Vector2) -> Array:
	var pts := []
	for k in 24:
		var a := TAU * k / 24.0
		pts.append(c + Vector2(cos(a) * radii.x, sin(a) * radii.y))
	return pts


# A filled, outlined shape. Crayon: a light wash, a back-and-forth scribble that strays a little over the edge like a
# 7-year-old's colouring, and a wobbly outline pressed harder in places, that overshoots where it closes.
static func _shape(ci: CanvasItem, pts: Array, fill: Color, crayon: bool, rng: RandomNumberGenerator, outline := true) -> void:
	var poly := PackedVector2Array(pts)
	if not crayon:
		ci.draw_colored_polygon(poly, fill)
		if outline:
			var ring := poly.duplicate()
			ring.append(poly[0])
			ci.draw_polyline(ring, LINE, 2.0, true)
		return
	ci.draw_colored_polygon(poly, Color(fill, 0.3))
	_scribble_fill(ci, poly, fill, rng)
	if outline:
		var ring := pts.duplicate()
		ring.append(pts[0])
		# The pen comes back past where it started.
		var along: Vector2 = (pts[1] - pts[0]).normalized()
		ring.append(pts[0] + along * rng.randf_range(2.0, 4.5))
		_crayon_line(ci, ring, fill.darkened(0.42), 2.1, rng)


## Colours a polygon with one continuous back-and-forth scribble at a slant, spacing and pressure changing a little, the
## ends of the strokes straying a few pixels past the outline.
static func _scribble_fill(ci: CanvasItem, poly: PackedVector2Array, fill: Color, rng: RandomNumberGenerator) -> void:
	var box := Rect2(poly[0], Vector2.ZERO)
	for p in poly:
		box = box.expand(p)
	var grown := Geometry2D.offset_polygon(poly, 1.4)
	var area: PackedVector2Array = grown[0] if not grown.is_empty() else poly
	var dir := Vector2.from_angle(-0.95 + rng.randf_range(-0.12, 0.12))
	var across := dir.orthogonal()
	var reach := box.size.length() * 0.75
	var centre := box.get_center()
	var t := -reach
	var flip := false
	var last := Vector2.INF
	while t < reach:
		var a := centre + across * t - dir * reach
		var b := centre + across * t + dir * reach
		for piece in Geometry2D.intersect_polyline_with_polygon(PackedVector2Array([a, b]), area):
			if piece.size() < 2:
				continue
			var from: Vector2 = piece[0]
			var to: Vector2 = piece[piece.size() - 1]
			if flip:
				var swap := from
				from = to
				to = swap
			var d := (to - from).normalized()
			from -= d * rng.randf_range(0.0, 2.6)
			to += d * rng.randf_range(0.0, 2.6)
			if last != Vector2.INF:
				ci.draw_line(last, from, Color(fill, 0.55), 2.2, true)
			ci.draw_line(from, to, Color(fill, rng.randf_range(0.6, 0.9)), rng.randf_range(2.4, 3.4), true)
			last = to
		flip = not flip
		t += rng.randf_range(3.0, 4.4)


# A stroke (a line that isn't a closed shape): the same crayon hand.
static func _stroke(ci: CanvasItem, pts: Array, color: Color, width: float, crayon: bool, rng: RandomNumberGenerator) -> void:
	if not crayon:
		ci.draw_polyline(PackedVector2Array(pts), color, width, true)
		return
	_crayon_line(ci, pts, color, width * 1.15, rng)


## A line drawn with wax crayon: it wobbles slowly, presses harder and lighter along its length, is gone over a second time a
## hair to the side, and the paper's grain shows through in small gaps.
static func _crayon_line(ci: CanvasItem, pts: Array, color: Color, width: float, rng: RandomNumberGenerator, passes := 2) -> void:
	var line := _resample(pts, 4.0)
	if line.size() < 2:
		return
	for pass_i in passes:
		var phase := rng.randf() * TAU
		var shift := Vector2(rng.randf_range(-0.8, 0.8), rng.randf_range(-0.8, 0.8)) * pass_i
		var prev := Vector2.ZERO
		for i in line.size():
			var p: Vector2 = line[i] + shift + Vector2(sin(i * 0.5 + phase), cos(i * 0.43 + phase * 1.3)) * 0.9
			if i > 0:
				var press := 0.8 + 0.35 * sin(i * 0.27 + phase * 2.0)
				var alpha := (0.92 if pass_i == 0 else 0.5) * (0.88 + 0.12 * sin(i * 1.9 + phase))
				ci.draw_line(prev, p, Color(color, alpha), width * press, true)
			prev = p
	for i in line.size():
		if rng.randf() < 0.4:
			ci.draw_circle(line[i] + Vector2(rng.randf_range(-0.5, 0.5), rng.randf_range(-0.5, 0.5)) * width, rng.randf_range(0.4, 0.8), Color(PAPER, 0.55))


# The polyline through `pts` with a point about every `step` px.
static func _resample(pts: Array, step: float) -> Array:
	var out := []
	for i in pts.size() - 1:
		var a: Vector2 = pts[i]
		var b: Vector2 = pts[i + 1]
		var n := maxi(1, int(a.distance_to(b) / step))
		for k in n:
			out.append(a.lerp(b, float(k) / n))
	out.append(pts[pts.size() - 1])
	return out
