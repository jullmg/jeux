class_name Icons
extends RefCounted
## Petits dessins faits à la main sur n'importe quel CanvasItem. `c` : centre, `r` : demi-taille.


static func star(on: CanvasItem, c: Vector2, r: float, filled: bool) -> void:
	var pts := PackedVector2Array()
	for i in 10:
		var a := -PI / 2.0 + i * PI / 5.0
		pts.append(c + Vector2(cos(a), sin(a)) * (r if i % 2 == 0 else r * 0.47))
	on.draw_colored_polygon(pts, UiStyle.GOLD if filled else Color(0.55, 0.45, 0.38, 0.45))
	pts.append(pts[0])
	on.draw_polyline(pts, UiStyle.INK, maxf(2.0, r * 0.1), true)


static func paw(on: CanvasItem, c: Vector2, r: float, color: Color) -> void:
	on.draw_circle(c + Vector2(0, r * 0.32), r * 0.48, color, true, -1.0, true)
	for p: Vector2 in [Vector2(-0.68, -0.18), Vector2(-0.26, -0.62), Vector2(0.26, -0.62), Vector2(0.68, -0.18)]:
		on.draw_circle(c + p * r, r * 0.23, color, true, -1.0, true)


static func eye(on: CanvasItem, c: Vector2, r: float, open: bool, ink := UiStyle.INK) -> void:
	var top := PackedVector2Array()
	var bottom := PackedVector2Array()
	for i in 21:
		var u := i / 20.0
		var x := lerpf(-r, r, u)
		var y := sin(u * PI) * r * 0.62
		top.append(c + Vector2(x, -y))
		bottom.append(c + Vector2(x, y))
	if open:
		var shape := top.duplicate()
		for i in range(19, 0, -1):
			shape.append(bottom[i])
		on.draw_colored_polygon(shape, Color.WHITE)
		on.draw_circle(c, r * 0.36, ink, true, -1.0, true)
		on.draw_circle(c + Vector2(-r * 0.1, -r * 0.12), r * 0.1, Color.WHITE, true, -1.0, true)
		on.draw_polyline(top, ink, r * 0.13, true)
		on.draw_polyline(bottom, ink, r * 0.13, true)
	else:
		on.draw_polyline(bottom, ink, r * 0.15, true)
		for k: float in [0.2, 0.5, 0.8]:
			var p := bottom[int(k * 20)]
			on.draw_line(p, p + Vector2((k - 0.5) * r * 0.5, r * 0.3), ink, r * 0.1, true)


static func warning(on: CanvasItem, c: Vector2, r: float, color: Color) -> void:
	var pts := PackedVector2Array([c + Vector2(0, -r), c + Vector2(r * 1.08, r * 0.8), c + Vector2(-r * 1.08, r * 0.8)])
	on.draw_colored_polygon(pts, color)
	pts.append(pts[0])
	on.draw_polyline(pts, Color.WHITE, r * 0.14, true)
	on.draw_line(c + Vector2(0, -r * 0.42), c + Vector2(0, r * 0.24), Color.WHITE, r * 0.2, true)
	on.draw_circle(c + Vector2(0, r * 0.53), r * 0.12, Color.WHITE, true, -1.0, true)


static func question(on: CanvasItem, c: Vector2, r: float) -> void:
	on.draw_circle(c, r, Color(0.5, 0.5, 0.55, 0.92), true, -1.0, true)
	on.draw_arc(c, r, 0, TAU, 40, Color.WHITE, r * 0.1, true)
	on.draw_arc(c + Vector2(0, -r * 0.2), r * 0.3, PI, PI * 2.5, 18, Color.WHITE, r * 0.17, true)
	on.draw_line(c + Vector2(0, r * 0.1), c + Vector2(0, r * 0.28), Color.WHITE, r * 0.17, true)
	on.draw_circle(c + Vector2(0, r * 0.55), r * 0.11, Color.WHITE, true, -1.0, true)


## Une flèche en cercle : elle fait le tour de l'îlot.
static func around(on: CanvasItem, c: Vector2, r: float, color: Color) -> void:
	on.draw_arc(c, r, -0.35 * PI, 1.45 * PI, 40, Color.WHITE, r * 0.26, true)
	on.draw_arc(c, r, -0.35 * PI, 1.45 * PI, 40, color, r * 0.13, true)
	var tip := c + Vector2.from_angle(1.45 * PI) * r
	var dir := Vector2.from_angle(1.45 * PI + PI / 2.0)
	var side := dir.orthogonal()
	var head := PackedVector2Array([tip + dir * r * 0.4, tip + side * r * 0.3, tip - side * r * 0.3])
	on.draw_colored_polygon(head, color)


static func bell(on: CanvasItem, c: Vector2, r: float) -> void:
	on.draw_circle(c, r, Color(0.14, 0.09, 0.07, 0.75), true, -1.0, true)
	var gold := UiStyle.GOLD
	var pts := PackedVector2Array()
	for i in 13:
		var a := PI + i * PI / 12.0
		pts.append(c + Vector2(cos(a) * r * 0.4, sin(a) * r * 0.45 - r * 0.05))
	pts.append(c + Vector2(r * 0.58, r * 0.34))
	pts.append(c + Vector2(-r * 0.58, r * 0.34))
	on.draw_colored_polygon(pts, gold)
	on.draw_circle(c + Vector2(0, r * 0.5), r * 0.14, gold, true, -1.0, true)
	on.draw_circle(c + Vector2(0, -r * 0.54), r * 0.1, gold, true, -1.0, true)


static func lock(on: CanvasItem, c: Vector2, r: float, color: Color) -> void:
	on.draw_arc(c + Vector2(0, -r * 0.2), r * 0.42, PI, TAU, 24, color, r * 0.2, true)
	on.draw_style_box(UiStyle.box(color, int(r * 0.2), Color.TRANSPARENT, 0, 0), Rect2(c + Vector2(-r * 0.65, -r * 0.2), Vector2(r * 1.3, r)))
	on.draw_circle(c + Vector2(0, r * 0.28), r * 0.14, UiStyle.CREAM, true, -1.0, true)


static func pause(on: CanvasItem, c: Vector2, r: float, color: Color) -> void:
	for s: float in [-1.0, 1.0]:
		on.draw_line(c + Vector2(s * r * 0.35, -r * 0.55), c + Vector2(s * r * 0.35, r * 0.55), color, r * 0.28, true)


static func heart(on: CanvasItem, c: Vector2, r: float, color: Color) -> void:
	var pts := PackedVector2Array()
	for i in 32:
		var a := TAU * i / 32.0
		# La courbe du cœur, la pointe en bas.
		var x := 16.0 * pow(sin(a), 3)
		var y := -(13.0 * cos(a) - 5.0 * cos(2.0 * a) - 2.0 * cos(3.0 * a) - cos(4.0 * a))
		pts.append(c + Vector2(x, y) * r / 17.0)
	on.draw_colored_polygon(pts, color)
	pts.append(pts[0])
	on.draw_polyline(pts, Color.WHITE, maxf(2.0, r * 0.12), true)


## Une porte entrouverte, avec la flèche de quelqu'un qui arrive.
static func door(on: CanvasItem, c: Vector2, r: float, color: Color) -> void:
	on.draw_rect(Rect2(c + Vector2(-r * 0.55, -r), Vector2(r * 1.1, r * 2.0)), Color.WHITE, true)
	on.draw_colored_polygon(PackedVector2Array([c + Vector2(-r * 0.45, -r * 0.9), c + Vector2(r * 0.25, -r * 0.7),
		c + Vector2(r * 0.25, r * 0.95), c + Vector2(-r * 0.45, r * 0.9)]), color)
	on.draw_circle(c + Vector2(r * 0.1, r * 0.1), r * 0.09, Color.WHITE, true, -1.0, true)
