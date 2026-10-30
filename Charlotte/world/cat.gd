class_name Cat
extends Node2D
## Black cat sitting on a porch railing: swishing tail, blinking yellow eyes.

var _t := 0.0
var _blink := 2.0


func _process(delta: float) -> void:
	_t += delta
	_blink -= delta
	if _blink < -0.15:
		_blink = randf_range(2.0, 5.0)
	queue_redraw()


func _draw() -> void:
	var fur := Color("#25232A")
	var edge := Color("#3C3946")
	var tail := PackedVector2Array()
	var sway := sin(_t * 1.6) * 0.5
	for i in 12:
		var t := i / 11.0
		tail.append(Vector2(-14 - t * 18.0 + sin(t * 3.0 + sway) * 6.0, -4 + t * 30.0 - sin(t * PI) * 4.0 + sway * t * 10.0))
	draw_polyline(tail, fur, 6.0, true)
	draw_set_transform(Vector2(-2, -16), 0.0, Vector2(1.0, 1.25))
	draw_circle(Vector2.ZERO, 15, fur)
	draw_set_transform(Vector2.ZERO)
	draw_circle(Vector2(-6, -18), 9, edge)
	draw_circle(Vector2(6, -38), 12, fur)
	draw_colored_polygon(PackedVector2Array([Vector2(-3, -44), Vector2(-1, -58), Vector2(6, -48)]), fur)
	draw_colored_polygon(PackedVector2Array([Vector2(8, -48), Vector2(15, -58), Vector2(16, -42)]), fur)
	draw_colored_polygon(PackedVector2Array([Vector2(0, -47), Vector2(0, -54), Vector2(4, -49)]), Color("#C97A8A"))
	if _blink > 0.0:
		for x in [2.0, 11.0]:
			draw_circle(Vector2(x, -39), 2.8, Color("#F5D04A"))
			draw_line(Vector2(x, -41.5), Vector2(x, -36.5), Color.BLACK, 1.2)
	else:
		for x in [2.0, 11.0]:
			draw_line(Vector2(x - 2.5, -39), Vector2(x + 2.5, -39), Color("#F5D04A"), 1.2)
	draw_circle(Vector2(16, -35), 1.3, Color("#C97A8A"))
	for w in [-1.0, 1.0]:
		draw_line(Vector2(16, -34), Vector2(26, -34 + w * 3.0), Color(1, 1, 1, 0.5), 0.8)
	draw_line(Vector2(-4, -2), Vector2(4, -2), fur, 5.0)
	draw_line(Vector2(6, -2), Vector2(12, -2), fur, 5.0)
