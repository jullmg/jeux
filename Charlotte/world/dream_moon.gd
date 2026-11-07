class_name DreamMoon
extends Node2D
## The little crescent moon that floats in front of someone whose mind has wandered off: it pops up, bobs, glows
## softly and two stars twinkle beside it. Papa gets one when he is "dans la lune" during his chores
## (`FamilyRoutine`), and so does Charlotte when she has been standing still for a while (`Character`, the
## "daydream" idle gesture).

var _t := 0.0


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	paint(self, _t)


## Draws the moon on any canvas, at its origin, `t` seconds after it appeared.
static func paint(canvas: CanvasItem, t: float) -> void:
	var grow := smoothstep(0.0, 0.7, t)
	var bob := Vector2(sin(t * 1.3) * 3.0, sin(t * 2.1) * 4.0)
	canvas.draw_set_transform(bob, sin(t * 0.9) * 0.12, Vector2.ONE * (grow * (1.0 + 0.12 * sin(t * 6.0) * (1.0 - grow))))
	canvas.draw_circle(Vector2.ZERO, 24.0, Color(1.0, 0.95, 0.7, 0.16))
	canvas.draw_circle(Vector2.ZERO, 17.0, Color(1.0, 0.95, 0.7, 0.2))
	var outer := PackedVector2Array()
	var inner := PackedVector2Array()
	for i in 36:
		var a := TAU * i / 36.0
		outer.append(Vector2.from_angle(a) * 13.0)
		inner.append(Vector2(7.0, -3.0) + Vector2.from_angle(a) * 11.0)
	for piece: PackedVector2Array in Geometry2D.clip_polygons(outer, inner):
		canvas.draw_colored_polygon(piece, Color("#FFD84D"))
		canvas.draw_polyline(piece + PackedVector2Array([piece[0]]), Color("#B8892A"), 2.2, true)
	canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	for k in 2:
		var tw := 0.5 + 0.5 * sin(t * 3.0 + k * 2.4)
		var at := bob + (Vector2(22.0, -14.0) if k == 0 else Vector2(-16.0, 15.0)) * grow
		canvas.draw_line(at - Vector2(3.5, 0) * tw, at + Vector2(3.5, 0) * tw, Color("#FFF3C4"), 1.4)
		canvas.draw_line(at - Vector2(0, 3.5) * tw, at + Vector2(0, 3.5) * tw, Color("#FFF3C4"), 1.4)
