class_name Bubble
extends RefCounted
## A speech bubble that pops up over someone's head for a moment, outdoors or indoors.


## How long a bubble stays: `seconds` at the very least, but always long enough for a child who is still learning
## to read to get to the end of it (about twelve letters a second, plus a moment to start and to stop).
static func reading_time(text: String, seconds: float) -> float:
	return clampf(maxf(seconds, 1.8 + text.length() / 12.0), 1.8, 10.0)


## Shows `text` in a bubble whose bottom centre is at `at` (world position), under `parent`. It stays `seconds` at
## the least, longer for a longer line (`reading_time`).
## A new line from the same speaker replaces their bubble; other people's bubbles stay, and the new one is lifted
## above any it would overlap.
static func say(parent: Node, at: Vector2, text: String, seconds := 2.4) -> void:
	seconds = reading_time(text, seconds)
	# Whoever stands under the bubble is the one talking: her mouth moves for as long as it stays.
	for who in parent.get_children():
		if who is Character and absf(who.position.x - at.x) < 90.0 and who.position.y > at.y:
			who.express("talk", minf(seconds, 4.5) * 0.85)
			break
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
	# Above everything in the scene (washing on a line, decorations, the night): speech is never hidden.
	bubble.z_index = 20
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
