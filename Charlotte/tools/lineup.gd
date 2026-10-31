extends Node2D
# Character design sheet: Godot --path . res://tools/lineup.tscn -- --screenshot=/tmp/lineup.png [--seed=1]

func _ready() -> void:
	RenderingServer.set_default_clear_color(Color("#F4F1EA"))
	var rng := RandomNumberGenerator.new()
	rng.seed = int(_arg("--seed=", "1"))
	var looks: Array[CharacterLook] = [CharacterLook.usual()]
	for age in ["child", "child", "teen", "adult", "adult", "senior", "child", "adult", "teen"]:
		looks.append(CharacterLook.random(rng, age))
	for i in looks.size():
		var c := Character.new()
		c.look = looks[i]
		c.scale = Vector2.ONE * 0.5
		c.position = Vector2(80 + i * 125, 640)
		c.walk_phase = 0.25 if i % 3 == 1 else 0.0
		c.is_walking = i % 3 == 1
		c.animate = false
		add_child(c)
	var shot := _arg("--screenshot=", "")
	if shot != "":
		for i in 5:
			await get_tree().process_frame
		get_viewport().get_texture().get_image().save_png(shot)
		get_tree().quit()


func _arg(prefix: String, fallback: String) -> String:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with(prefix):
			return arg.trim_prefix(prefix)
	return fallback
