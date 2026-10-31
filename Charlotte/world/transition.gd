class_name Transition
extends RefCounted
## Fades to black and back for doors and scene changes, and remembers where Charlotte should appear.

## Street x to put Charlotte at when the street scene loads (NAN = default spot).
static var street_x := NAN
## Which corner Charlotte comes round when a street loads (e.g. "dandurand_from_6e"; "" = none).
static var arrive := ""
## Interior x to put Charlotte at when an interior reloads (NAN = its default spot).
static var inside_x := NAN


static func fade_in(parent: Node, time := 0.45) -> void:
	var rect := _overlay(parent, 1.0)
	var tween := rect.create_tween()
	tween.tween_property(rect, "color:a", 0.0, time)
	tween.tween_callback(rect.get_parent().queue_free)


## Fades to black, runs `then`, and (unless it changed scene) fades back in.
static func through_black(parent: Node, then: Callable, time := 0.35) -> void:
	var rect := _overlay(parent, 0.0)
	var tween := rect.create_tween()
	tween.tween_property(rect, "color:a", 1.0, time)
	tween.tween_callback(then)
	tween.tween_property(rect, "color:a", 0.0, time)
	tween.tween_callback(rect.get_parent().queue_free)


static func change_scene(parent: Node, path: String, time := 0.35) -> void:
	var rect := _overlay(parent, 0.0)
	var tween := rect.create_tween()
	tween.tween_property(rect, "color:a", 1.0, time)
	tween.tween_callback(func(): parent.get_tree().change_scene_to_file(path))


static func _overlay(parent: Node, alpha: float) -> ColorRect:
	var layer := CanvasLayer.new()
	layer.layer = 100
	var rect := ColorRect.new()
	rect.color = Color(0.06, 0.03, 0.02, alpha)
	rect.size = Vector2(1280, 720)
	rect.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(rect)
	parent.add_child(layer)
	return rect
