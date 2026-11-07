extends Node2D
## The design sheet of every Halloween decoration (`HalloweenArt.PIECES`), on the night's own dark blue, so their
## drawing can be judged: `Godot --path . --screen 1 res://tools/halloween_props.tscn -- --screenshot=/path/p.png`.

const COLS := 7
const CELL := Vector2(176.0, 172.0)


func _ready() -> void:
	var back := ColorRect.new()
	back.color = Color(0.08, 0.09, 0.17)
	back.size = Vector2(1280, 720)
	add_child(back)
	var i := 0
	for kind: String in HalloweenArt.PIECES:
		var piece: Dictionary = HalloweenArt.PIECES[kind]
		var cell := Vector2(22.0 + (i % COLS) * CELL.x, 70.0 + float(i / COLS) * CELL.y)
		var sprite := Sprite2D.new()
		sprite.texture = HalloweenArt.texture(kind)
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		sprite.centered = false
		var size: Vector2 = piece.size
		var k: float = minf(1.0, minf((CELL.x - 26.0) / size.x, (CELL.y - 44.0) / size.y))
		sprite.scale = Vector2.ONE * k
		sprite.position = cell + Vector2((CELL.x - size.x * k) * 0.5, CELL.y - 34.0 - size.y * k)
		add_child(sprite)
		var label := Label.new()
		label.text = kind
		label.position = cell + Vector2(0.0, CELL.y - 28.0)
		label.size = Vector2(CELL.x, 24.0)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_color_override("font_color", Color("#FFD23F"))
		label.add_theme_font_size_override("font_size", 16)
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
