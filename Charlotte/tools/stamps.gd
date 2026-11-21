extends Node2D
## The design sheet of every drawing-pad stamp (`StampArt.CATEGORIES`), to judge their drawing:
## `Godot --path . --screen 1 res://tools/stamps.tscn -- --screenshot=/path/p.png [--color=#E04F5F]`.

const COLS := 10
const CELL := Vector2(124.0, 112.0)


class _Cell:
	extends Node2D
	var id := ""
	var color := Color("#E04F5F")

	func _draw() -> void:
		StampArt.draw(self, id, Vector2(0, 0), 40.0, color)


func _ready() -> void:
	var back := ColorRect.new()
	back.color = Color("#FFFDF7")
	back.size = Vector2(1280, 720)
	add_child(back)
	var i := 0
	for id: String in StampArt.all_ids():
		var cell := _Cell.new()
		cell.id = id
		cell.position = Vector2(20.0 + (i % COLS) * CELL.x + CELL.x * 0.5, 60.0 + float(i / COLS) * CELL.y + 46.0)
		add_child(cell)
		var label := Label.new()
		label.text = id
		label.position = cell.position + Vector2(-CELL.x * 0.5, 52.0)
		label.size = Vector2(CELL.x, 20.0)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_color_override("font_color", Color("#1D4F91"))
		label.add_theme_font_size_override("font_size", 15)
		add_child(label)
		i += 1
	_shoot()


func _shoot() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--screenshot="):
			await RenderingServer.frame_post_draw
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png(arg.trim_prefix("--screenshot="))
			get_tree().quit()
