extends CanvasLayer
## Autoload. `--season=<spring|summer|autumn|winter>` (or printemps/été/automne/hiver) picks the season at
## start. In debug builds, F1 opens a small menu to switch seasons while playing: the scene reloads with a
## fade and Charlotte reappears where she was.

const ALIASES := {"printemps": "spring", "ete": "summer", "été": "summer", "automne": "autumn", "hiver": "winter"}

var _panel: PanelContainer


func _ready() -> void:
	layer = 90
	process_mode = Node.PROCESS_MODE_ALWAYS
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--season="):
			var s := arg.trim_prefix("--season=").to_lower()
			s = ALIASES.get(s, s)
			if s in Season.ALL:
				Season.current = s


func _unhandled_input(event: InputEvent) -> void:
	if not OS.is_debug_build():
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F1:
		get_viewport().set_input_as_handled()
		if _panel:
			_close()
		else:
			_open()


func _open() -> void:
	_panel = PanelContainer.new()
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.1, 0.12, 0.18, 0.92)
	box.border_color = Color("#FFD23F")
	box.set_border_width_all(3)
	box.set_corner_radius_all(14)
	box.set_content_margin_all(16)
	_panel.add_theme_stylebox_override("panel", box)
	_panel.position = Vector2(20, 20)
	add_child(_panel)
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 8)
	_panel.add_child(list)
	var title := Label.new()
	title.text = "Saisons (debug, F1)"
	title.add_theme_color_override("font_color", Color("#FFD23F"))
	title.add_theme_font_size_override("font_size", 20)
	list.add_child(title)
	for s in Season.ALL:
		var b := Button.new()
		b.text = ("▶ " if s == Season.current else "") + Season.NAMES[s]
		b.custom_minimum_size = Vector2(220, 40)
		b.add_theme_font_size_override("font_size", 18)
		b.pressed.connect(_switch.bind(s))
		list.add_child(b)


func _close() -> void:
	_panel.queue_free()
	_panel = null


func _switch(to: String) -> void:
	_close()
	if to == Season.current:
		return
	Season.current = to
	var scene := get_tree().current_scene
	var charlotte = scene.get("_charlotte")
	if charlotte is Character:
		if scene.scene_file_path.ends_with("main.tscn"):
			Transition.street_x = charlotte.position.x
		else:
			Transition.inside_x = charlotte.position.x
	Transition.change_scene(scene, scene.scene_file_path)
