class_name Bubble
extends RefCounted
## A speech bubble that pops up over someone's head for a moment, outdoors or indoors.


## Shows `text` in a bubble whose bottom centre is at `at` (world position), under `parent`, for `seconds`.
static func say(parent: Node, at: Vector2, text: String, seconds := 2.4) -> void:
	var bubble := Label.new()
	bubble.text = text
	bubble.add_theme_font_size_override("font_size", 20)
	bubble.add_theme_color_override("font_color", Color("#1D4F91"))
	var box := StyleBoxFlat.new()
	box.bg_color = Color.WHITE
	box.border_color = Color("#1D4F91")
	box.set_border_width_all(2)
	box.set_corner_radius_all(12)
	box.set_content_margin_all(8)
	bubble.add_theme_stylebox_override("normal", box)
	bubble.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	parent.add_child(bubble)
	bubble.reset_size()
	bubble.position = at - Vector2(bubble.size.x / 2.0, bubble.size.y)
	bubble.modulate.a = 0.0
	var tween := bubble.create_tween()
	tween.tween_property(bubble, "modulate:a", 1.0, 0.2)
	tween.tween_interval(seconds)
	tween.tween_property(bubble, "modulate:a", 0.0, 0.3)
	tween.tween_callback(bubble.queue_free)
