extends CanvasLayer
## Autoload. `--season=<spring|summer|autumn|winter>` (or printemps/été/automne/hiver) picks the season at
## start. In debug builds, F1 opens a small menu to switch seasons while playing, and to reset or start any quest
## (to test it again): the scene reloads with a fade and Charlotte reappears where she was.

const ALIASES := {"printemps": "spring", "ete": "summer", "été": "summer", "automne": "autumn", "hiver": "winter"}
## The story flags each quest leaves behind, cleared with it.
const QUEST_FLAGS := {"milk": ["has_milk"], "hamster": ["hamster_fed"], "menage": ["tidied"], "plants": ["watered", "has_can"]}

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
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 28)
	_panel.add_child(columns)
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 8)
	columns.add_child(list)
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
	_quest_list(columns)


# One row per quest: its state, "Effacer" (back to not started, its flags cleared) and "Activer" (in the notebook now,
# whatever it waits for).
func _quest_list(parent: Control) -> void:
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 6)
	parent.add_child(list)
	var title := Label.new()
	title.text = "Quêtes"
	title.add_theme_color_override("font_color", Color("#FFD23F"))
	title.add_theme_font_size_override("font_size", 20)
	list.add_child(title)
	for id: String in Quests.ORDER:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		list.add_child(row)
		var label := Label.new()
		var state := Quests.status(id)
		label.text = "%s  %s" % [{"": "·", "active": "▶", "done": "★"}[state], id]
		label.custom_minimum_size = Vector2(120, 0)
		label.add_theme_font_size_override("font_size", 17)
		row.add_child(label)
		for action in [["Effacer", ""], ["Activer", "active"]]:
			var b := Button.new()
			b.text = action[0]
			b.add_theme_font_size_override("font_size", 15)
			b.disabled = state == action[1]
			b.pressed.connect(_set_quest.bind(id, action[1]))
			row.add_child(b)
	var all := Button.new()
	all.text = "Tout effacer"
	all.add_theme_font_size_override("font_size", 15)
	all.pressed.connect(func():
		for id: String in Quests.ORDER:
			_clear_quest(id)
		_close()
		_reload())
	list.add_child(all)


func _set_quest(id: String, state: String) -> void:
	_clear_quest(id)
	if state != "":
		GameState.quests[id] = state
	_close()
	_reload()


func _clear_quest(id: String) -> void:
	GameState.quests.erase(id)
	for flag: String in QUEST_FLAGS.get(id, []):
		GameState.flags.erase(flag)
	if LostCats.carrying() == id:
		GameState.flags.erase("carrying")


func _close() -> void:
	_panel.queue_free()
	_panel = null


func _switch(to: String) -> void:
	_close()
	if to == Season.current:
		return
	Season.current = to
	_reload()


# Reloads the scene (the world rebuilds from the season and the quests), Charlotte where she was.
func _reload() -> void:
	var scene := get_tree().current_scene
	var charlotte = scene.get("_charlotte")
	if charlotte is Character:
		if scene.scene_file_path.ends_with("main.tscn"):
			Transition.street_x = charlotte.position.x
		else:
			Transition.inside_x = charlotte.position.x
	Transition.change_scene(scene, scene.scene_file_path)
