class_name QuestMark
extends Node2D
## A little bobbing yellow "!" over someone or something that has a quest for Charlotte, or is waiting for
## one she's doing. It shows while `when` returns true.

var when: Callable
var size := 1.0
var _t := 0.0


static func make(at: Vector2, condition: Callable, scale_by := 1.0) -> QuestMark:
	var mark := QuestMark.new()
	mark.position = at
	mark.when = condition
	mark.size = scale_by
	mark.z_index = 5
	return mark


func _process(delta: float) -> void:
	_t += delta
	visible = when.is_valid() and when.call()
	if visible:
		queue_redraw()


func _draw() -> void:
	var y := sin(_t * 3.2) * 5.0 * size
	var c := Vector2(0, y)
	var r := 17.0 * size
	draw_circle(c + Vector2(2, 3) * size, r, Color(0, 0, 0, 0.18))
	draw_circle(c, r, Color("#FFD23F"))
	draw_arc(c, r, 0, TAU, 32, Color("#1D4F91"), 2.5 * size, true)
	draw_circle(c + Vector2(-5, -6) * size, 4.0 * size, Color(1, 1, 1, 0.55))
	draw_line(c + Vector2(0, -9) * size, c + Vector2(0, 3) * size, Color("#1D4F91"), 4.5 * size, true)
	draw_circle(c + Vector2(0, 9) * size, 2.6 * size, Color("#1D4F91"))
