extends Node2D
# Every Halloween costume, to judge them: Godot --path . --screen 1 res://tools/costumes.tscn -- --screenshot=/tmp/c.png [--page=0]

const PER_PAGE := 11

func _ready() -> void:
	RenderingServer.set_default_clear_color(Color("#F4F1EA"))
	var page := int(_arg("--page=", "0"))
	var ids: Array = CostumeArt.ORDER.slice(page * PER_PAGE, (page + 1) * PER_PAGE)
	var font := ThemeDB.fallback_font
	for i in ids.size():
		var id: String = ids[i]
		var look := CharacterLook.usual()
		look.costume = id
		var c := Character.new()
		c.look = look
		c.scale = Vector2.ONE * 0.62
		c.position = Vector2(110 + (i % 6) * 210, 330 + int(i / 6) * 330)
		c.animate = false
		add_child(c)
		var label := Label.new()
		label.text = CostumeArt.name_of(id)
		label.add_theme_font_size_override("font_size", 20)
		label.add_theme_color_override("font_color", Color("#1D4F91"))
		label.position = c.position + Vector2(-100, 14)
		label.size = Vector2(200, 30)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		add_child(label)
	var shot := _arg("--screenshot=", "")
	if shot != "":
		await RenderingServer.frame_post_draw
		for i in 4:
			await get_tree().process_frame
		get_viewport().get_texture().get_image().save_png(shot)
		get_tree().quit()


func _arg(prefix: String, fallback: String) -> String:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with(prefix):
			return arg.trim_prefix(prefix)
	return fallback
