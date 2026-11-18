class_name Transition
extends RefCounted
## Fades to black and back for doors and scene changes, and remembers where Charlotte should appear.

## Street x to put Charlotte at when the street scene loads (NAN = default spot).
static var street_x := NAN
## Which corner Charlotte comes round when a street loads (e.g. "dandurand_from_6e"; "" = none).
static var arrive := ""
## Set (to the same key as `arrive`) when she comes round that corner in order to CROSS the street she was on: the
## street that loads walks her over its gap for that street as soon as she arrives (`StreetScene._add_corner`).
static var crossing := ""
## Interior x to put Charlotte at when an interior reloads (NAN = its default spot).
static var inside_x := NAN


static func fade_in(parent: Node, time := 0.45) -> void:
	var rect := _overlay(parent, 1.0)
	# The black left over from the scene change (kept on the root through it) can go now that this one covers.
	for old in parent.get_tree().get_nodes_in_group("scene_change_black"):
		old.queue_free()
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


## Fades to black and loads `path`. The black is kept on the tree's root, so it stays up through the change (no
## frame of empty screen) until the new scene's fade_in takes over.
static func change_scene(parent: Node, path: String, time := 0.35) -> void:
	var rect := _overlay(parent, 0.0)
	var layer := rect.get_parent()
	layer.add_to_group("scene_change_black")
	layer.reparent(parent.get_tree().root)
	var tween := rect.create_tween()
	tween.tween_property(rect, "color:a", 1.0, time)
	tween.tween_callback(func(): rect.get_tree().change_scene_to_file(path))
	# Never leave it up if the new scene has no fade_in of its own.
	tween.tween_interval(3.0)
	tween.tween_callback(layer.queue_free)


## Like change_scene, with a line of words on the black for a moment before the new scene loads ("Maman t'accompagne à
## l'école…"): time passes, or she goes somewhere she couldn't walk to by herself.
static func change_scene_saying(parent: Node, path: String, words: String, hold := 2.2) -> void:
	var rect := _overlay(parent, 0.0)
	var layer := rect.get_parent()
	layer.add_to_group("scene_change_black")
	layer.reparent(parent.get_tree().root)
	var label := Label.new()
	label.text = words
	label.add_theme_font_size_override("font_size", 40)
	label.add_theme_color_override("font_color", Color("#FFF3C4"))
	label.size = Vector2(1280, 720)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.modulate.a = 0.0
	layer.add_child(label)
	var tween := rect.create_tween()
	tween.tween_property(rect, "color:a", 1.0, 0.5)
	tween.tween_property(label, "modulate:a", 1.0, 0.4)
	tween.tween_interval(hold)
	tween.tween_property(label, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func(): rect.get_tree().change_scene_to_file(path))
	tween.tween_interval(3.0)
	tween.tween_callback(layer.queue_free)


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
