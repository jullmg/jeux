class_name FairyLights
extends Node2D
## Warm fairy lights strung along a crown moulding, each bulb twinkling at its own pace.

var from_x := 0.0
var count := 40
var spacing := 40.0
var y := 64.0

var _t := 0.0


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var wire := PackedVector2Array()
	for i in count:
		wire.append(_bulb(i) + Vector2(0, -4))
	draw_polyline(wire, Color("#8A8478"), 1.2, true)
	for i in count:
		var p := _bulb(i)
		var tw := 0.65 + 0.35 * sin(_t * (1.3 + (i * 7) % 5 * 0.3) + i * 1.7)
		draw_circle(p, 11.0, Color(1.0, 0.82, 0.45, 0.14 * tw))
		draw_circle(p, 6.0, Color(1.0, 0.86, 0.5, 0.22 * tw))
		draw_circle(p, 3.2, Color(1.0, 0.93, 0.7).lerp(Color("#FFF8E6"), tw))


func _bulb(i: int) -> Vector2:
	return Vector2(from_x + i * spacing, y + sin(i * 0.9) * 6.0)
