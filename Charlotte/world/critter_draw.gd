class_name CritterDraw
extends RefCounted
## Shared drawing helpers for the procedural animals (StrayCat, Dog): shaded outlined bodies, tapered
## limbs and tails, glossy eyes, hearts. Light comes from the upper left, like the rest of the street.

const SHADOW := Color(0.15, 0.08, 0.05, 0.25)
const HEART := Color("#FF6F91")


static func ellipse_points(c: Vector2, r: Vector2, rot := 0.0, n := 28) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n:
		var a := TAU * i / n
		pts.append(c + Vector2(cos(a) * r.x, sin(a) * r.y).rotated(rot))
	return pts


## Filled ellipse; outlined unless `line` is transparent.
static func ellipse(ci: CanvasItem, c: Vector2, r: Vector2, fill: Color, line := Color.TRANSPARENT, rot := 0.0, width := 2.0) -> void:
	var pts := ellipse_points(c, r, rot)
	ci.draw_colored_polygon(pts, fill)
	if line.a > 0.0:
		pts.append(pts[0])
		ci.draw_polyline(pts, line, width, true)


## Horizontal slice of an ellipse between v0 and v1 (-1 top .. 1 bottom), e.g. a belly or a saddle.
static func band(ci: CanvasItem, c: Vector2, r: Vector2, v0: float, v1: float, col: Color, rot := 0.0) -> void:
	var pts := PackedVector2Array()
	for i in 13:
		var v := lerpf(v0, v1, i / 12.0)
		pts.append(c + Vector2(sqrt(maxf(0.0, 1.0 - v * v)) * r.x * 0.97, v * r.y * 0.97).rotated(rot))
	for i in 13:
		var v := lerpf(v1, v0, i / 12.0)
		pts.append(c + Vector2(-sqrt(maxf(0.0, 1.0 - v * v)) * r.x * 0.97, v * r.y * 0.97).rotated(rot))
	ci.draw_colored_polygon(pts, col)


## Body ellipse with a lighter belly, a shaded underside, a sunlit patch on the upper left, then the outline.
static func body(ci: CanvasItem, c: Vector2, r: Vector2, base: Color, belly: Color, line: Color, rot := 0.0, extra := Callable()) -> void:
	ellipse(ci, c, r, base, Color.TRANSPARENT, rot)
	if belly.a > 0.0:
		band(ci, c, r, 0.3, 1.0, belly, rot)
	if extra.is_valid():
		extra.call()
	band(ci, c, r, 0.62, 1.0, Color(0.1, 0.03, 0.0, 0.14), rot)
	ellipse(ci, c + Vector2(-r.x * 0.28, -r.y * 0.42).rotated(rot), Vector2(r.x * 0.42, r.y * 0.26), Color(1, 0.97, 0.9, 0.22), Color.TRANSPARENT, rot)
	var pts := ellipse_points(c, r, rot)
	pts.append(pts[0])
	ci.draw_polyline(pts, line, 2.0, true)


## Tapered stroke along `pts`, width w0 at the start to w1 at the end, outlined. Built from convex
## quads and round joints, so tight curls never break triangulation.
static func taper(ci: CanvasItem, pts: PackedVector2Array, w0: float, w1: float, fill: Color, line: Color) -> void:
	for pass_i in 2:
		var grow := 2.2 if pass_i == 0 else 0.0
		var col := line if pass_i == 0 else fill
		for i in pts.size():
			var w := lerpf(w0, w1, float(i) / (pts.size() - 1)) * 0.5 + grow * 0.5
			ci.draw_circle(pts[i], w, col)
			if i > 0:
				var w_prev := lerpf(w0, w1, float(i - 1) / (pts.size() - 1)) * 0.5 + grow * 0.5
				var d := (pts[i] - pts[i - 1]).normalized().orthogonal()
				ci.draw_colored_polygon(PackedVector2Array([pts[i - 1] + d * w_prev, pts[i] + d * w, pts[i] - d * w, pts[i - 1] - d * w_prev]), col)


## Quadratic/cubic Bézier sampled into a polyline.
static func curve(ctrl: Array[Vector2], n := 12) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n + 1:
		var t := float(i) / n
		var layer := ctrl.duplicate()
		while layer.size() > 1:
			var next: Array[Vector2] = []
			for k in layer.size() - 1:
				next.append(layer[k].lerp(layer[k + 1], t))
			layer = next
		pts.append(layer[0])
	return pts


## Glossy cartoon eye. `mode`: "open", "closed" (blink) or "happy" (^ arc).
static func eye(ci: CanvasItem, c: Vector2, r: float, iris: Color, line: Color, mode := "open", slit := false) -> void:
	match mode:
		"happy":
			ci.draw_arc(c + Vector2(0, r * 0.5), r * 0.95, PI * 1.15, PI * 1.85, 8, line, 1.6, true)
		"closed":
			ci.draw_line(c + Vector2(-r, r * 0.2), c + Vector2(r, r * 0.2), line, 1.4, true)
		_:
			ci.draw_circle(c, r + 0.8, line)
			ci.draw_circle(c, r, iris)
			ci.draw_circle(c + Vector2(0, r * 0.25), r * 0.7, iris.darkened(0.25))
			if slit:
				ellipse(ci, c, Vector2(r * 0.32, r * 0.8), Color("#141210"))
			else:
				ci.draw_circle(c, r * 0.55, Color("#141210"))
			ci.draw_circle(c + Vector2(-r * 0.35, -r * 0.4), r * 0.36, Color.WHITE)
			ci.draw_circle(c + Vector2(r * 0.35, r * 0.4), r * 0.16, Color(1, 1, 1, 0.8))


static func heart(ci: CanvasItem, c: Vector2, s: float, col: Color) -> void:
	ci.draw_circle(c + Vector2(-s * 0.5, 0), s * 0.6, col)
	ci.draw_circle(c + Vector2(s * 0.5, 0), s * 0.6, col)
	ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 1.08, s * 0.2), c + Vector2(s * 1.08, s * 0.2), c + Vector2(0, s * 1.4)]), col)
	ci.draw_circle(c + Vector2(-s * 0.6, -s * 0.15), s * 0.18, Color(1, 1, 1, col.a * 0.7))


## Hearts floating up from `origin`: each Vector3 is (x offset, age 0..1.6, size).
static func hearts(ci: CanvasItem, list: Array[Vector3], origin: Vector2) -> void:
	for h in list:
		heart(ci, origin + Vector2(h.x, -h.y * 34.0), 5.0 * h.z, Color(HEART, 1.0 - h.y / 1.6))


static func ground_shadow(ci: CanvasItem, c: Vector2, rx: float) -> void:
	ci.draw_set_transform(c, 0.0, Vector2(1.0, 0.22))
	ci.draw_circle(Vector2.ZERO, rx, SHADOW)
	ci.draw_circle(Vector2.ZERO, rx * 0.6, Color(SHADOW, 0.12))
	ci.draw_set_transform(Vector2.ZERO)
