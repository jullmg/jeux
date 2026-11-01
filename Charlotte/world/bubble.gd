class_name Bubble
extends RefCounted
## A speech bubble that pops up over someone's head for a moment, outdoors or indoors.


## Shows `text` in a bubble whose bottom centre is at `at` (world position), under `parent`, for `seconds`.
## A new line from the same speaker replaces their bubble; other people's bubbles stay, and the new one is lifted
## above any it would overlap.
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
	var others: Array[Rect2] = []
	for old in parent.get_children():
		if not old.is_in_group("bubble") or old.is_queued_for_deletion():
			continue
		if (old.get_meta("anchor") as Vector2).distance_to(at) < 40.0:
			old.remove_from_group("bubble")
			old.queue_free()
		else:
			others.append(old.get_rect())
	bubble.add_to_group("bubble")
	bubble.set_meta("anchor", at)
	parent.add_child(bubble)
	bubble.reset_size()
	bubble.position = at - Vector2(bubble.size.x / 2.0, bubble.size.y)
	for i in others.size():
		var moved := false
		for other in others:
			if bubble.get_rect().grow(4.0).intersects(other):
				bubble.position.y = other.position.y - bubble.size.y - 8.0
				moved = true
		if not moved:
			break
	bubble.modulate.a = 0.0
	var tween := bubble.create_tween()
	tween.tween_property(bubble, "modulate:a", 1.0, 0.2)
	tween.tween_interval(seconds)
	tween.tween_property(bubble, "modulate:a", 0.0, 0.3)
	tween.tween_callback(bubble.queue_free)
