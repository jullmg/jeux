extends CanvasLayer
## Autoload "GameMenu": the ☰ button in the top-left corner (or Escape) opens the game menu, which pauses the game:
## Reprendre, Options (music and effects volume, full screen), Écran titre, Quitter le jeu (both save first).
## The options are remembered in user://settings.cfg, next to the mute button's setting.

const SETTINGS := "user://settings.cfg"
const BLUE := Color("#1D4F91")
const YELLOW := Color("#FFD23F")
const CREAM := Color("#FBF6EA")
const INK := Color("#3A3A48")

var _button: Button
var _page: Control
var _card: PanelContainer
var _main: VBoxContainer
var _options: VBoxContainer
var _to_title: Button
var _open := false


func _ready() -> void:
	layer = 78
	process_mode = Node.PROCESS_MODE_ALWAYS
	_button = Button.new()
	_button.custom_minimum_size = Vector2(52, 52)
	_button.position = Vector2(14, 14)
	_button.focus_mode = Control.FOCUS_NONE
	_button.tooltip_text = "Menu (Échap)"
	for state in ["normal", "hover", "pressed"]:
		var box := StyleBoxFlat.new()
		box.bg_color = Color(1, 1, 1, 0.85 if state == "normal" else 1.0)
		box.border_color = BLUE
		box.set_border_width_all(3 if state != "normal" else 2)
		box.set_corner_radius_all(26)
		_button.add_theme_stylebox_override(state, box)
	_button.pressed.connect(toggle)
	_button.draw.connect(func():
		for i in 3:
			_button.draw_rect(Rect2(15, 16 + i * 8, 22, 4), BLUE))
	add_child(_button)
	_build_page()
	_apply_settings()


func _process(_delta: float) -> void:
	var scene := get_tree().current_scene
	_button.visible = scene != null and not scene.scene_file_path.contains("/tools/")


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		var notebook := get_node_or_null("/root/Notebook")
		if notebook and notebook._open:
			return
		get_viewport().set_input_as_handled()
		toggle()


func toggle() -> void:
	_open = not _open
	_page.visible = _open
	_show(_main)
	var scene := get_tree().current_scene
	_to_title.visible = scene != null and not scene.scene_file_path.ends_with("intro.tscn")
	get_tree().paused = _open
	Sfx.play("click")


# ── The page ────────────────────────────────────────────────

func _build_page() -> void:
	_page = Control.new()
	_page.size = Vector2(1280, 720)
	_page.visible = false
	add_child(_page)
	var dim := ColorRect.new()
	dim.color = Color(0.05, 0.08, 0.2, 0.5)
	dim.size = _page.size
	dim.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed:
			toggle())
	_page.add_child(dim)
	_card = PanelContainer.new()
	_card.draw.connect(_decorate)
	var style := StyleBoxFlat.new()
	style.bg_color = CREAM
	style.border_color = BLUE
	style.set_border_width_all(4)
	style.set_corner_radius_all(18)
	style.set_content_margin_all(28)
	style.content_margin_top = 40
	style.shadow_color = Color(0, 0, 0, 0.3)
	style.shadow_size = 10
	_card.add_theme_stylebox_override("panel", style)
	_page.add_child(_card)
	var both := VBoxContainer.new()
	_card.add_child(both)
	_main = VBoxContainer.new()
	_main.add_theme_constant_override("separation", 12)
	both.add_child(_main)
	_main.add_child(_title("Menu"))
	_main.add_child(_big_button("Reprendre", toggle))
	_main.add_child(_big_button("Options", func(): _show(_options)))
	_to_title = _big_button("Écran titre", _go_to_title)
	_main.add_child(_to_title)
	_main.add_child(_big_button("Quitter le jeu", _quit))
	_options = VBoxContainer.new()
	_options.add_theme_constant_override("separation", 14)
	both.add_child(_options)
	_options.add_child(_title("Options"))
	_options.add_child(_slider("Musique", "music", Sfx.BUS_MUSIC))
	_options.add_child(_slider("Effets sonores", "effects", Sfx.BUS_SFX))
	var full := CheckButton.new()
	full.text = "Plein écran"
	full.focus_mode = Control.FOCUS_NONE
	full.add_theme_font_size_override("font_size", 22)
	full.add_theme_color_override("font_color", INK)
	full.add_theme_color_override("font_hover_color", INK)
	full.add_theme_color_override("font_pressed_color", INK)
	full.button_pressed = _setting("fullscreen", false)
	full.toggled.connect(func(on: bool):
		_store("fullscreen", on)
		_apply_settings())
	_options.add_child(full)
	_options.add_child(_big_button("Retour", func(): _show(_main)))
	_show(_main)


# Over the card's edges: a cat, a dog and a hamster peeking over the top, flowers in the corners, paw prints.
func _decorate() -> void:
	var w := _card.size.x
	var h := _card.size.y
	CuteArt.cat_head(_card, Vector2(54, 0), 26, Color("#E8954A"))
	CuteArt.dog_head(_card, Vector2(w - 56, 2), 26, Color("#C9A27A"), Color("#7A5232"))
	CuteArt.hamster_head(_card, Vector2(w / 2.0 + 110.0, h), 20)
	for f in [[Vector2(8, h - 8), Color("#F2A7C9")], [Vector2(26, h + 4), Color("#FFFFFF")], [Vector2(w - 10, h - 6), Color("#9B59B6")],
			[Vector2(w - 30, h + 6), Color("#F7C6D9")], [Vector2(-6, 60), Color("#FFD23F")], [Vector2(w + 6, 70), Color("#F2A7C9")]]:
		CuteArt.flower(_card, f[0], 12, f[1])
	for p in [Vector2(30, h - 40), Vector2(48, h - 58), Vector2(30, h - 76)]:
		_paw(p)


func _paw(c: Vector2) -> void:
	var col := Color(BLUE, 0.25)
	_card.draw_circle(c, 5.0, col)
	for k in 4:
		_card.draw_circle(c + Vector2.from_angle(-PI / 2.0 + (k - 1.5) * 0.55) * 8.0, 2.4, col)


func _show(which: VBoxContainer) -> void:
	_main.visible = which == _main
	_options.visible = which == _options
	_card.reset_size()
	_card.position = (Vector2(1280, 720) - _card.size) / 2.0


func _title(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 36)
	label.add_theme_color_override("font_color", BLUE)
	return label


func _big_button(text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(320, 54)
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 24)
	for state in ["normal", "hover", "pressed"]:
		var box := StyleBoxFlat.new()
		box.bg_color = YELLOW if state != "normal" else Color("#FFE58A")
		box.border_color = BLUE
		box.set_border_width_all(3)
		box.set_corner_radius_all(14)
		button.add_theme_stylebox_override(state, box)
		button.add_theme_color_override("font_%scolor" % ("" if state == "normal" else state + "_"), BLUE)
	button.pressed.connect(action)
	return button


func _slider(text: String, key: String, bus: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	var label := Label.new()
	label.text = text
	label.custom_minimum_size.x = 170
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", INK)
	row.add_child(label)
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.custom_minimum_size = Vector2(220, 32)
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slider.focus_mode = Control.FOCUS_NONE
	slider.value = _setting(key, 0.8)
	slider.value_changed.connect(func(v: float):
		_store(key, v)
		_apply_settings()
		if bus == Sfx.BUS_SFX:
			Sfx.play("pop"))
	row.add_child(slider)
	return row


# ── Settings and leaving ────────────────────────────────────

func _setting(key: String, default: Variant) -> Variant:
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS)
	return cfg.get_value("options", key, default)


func _store(key: String, value: Variant) -> void:
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS)
	cfg.set_value("options", key, value)
	cfg.save(SETTINGS)


func _apply_settings() -> void:
	for pair in [["music", Sfx.BUS_MUSIC], ["effects", Sfx.BUS_SFX]]:
		var bus := AudioServer.get_bus_index(pair[1])
		var v: float = _setting(pair[0], 0.8)
		AudioServer.set_bus_volume_db(bus, linear_to_db(maxf(v, 0.0001)))
		AudioServer.set_bus_mute(bus, v <= 0.001)
	var full: bool = _setting("fullscreen", false)
	var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if full else DisplayServer.WINDOW_MODE_WINDOWED
	if DisplayServer.window_get_mode() != mode and DisplayServer.get_name() != "headless":
		DisplayServer.window_set_mode(mode)


# Saves where Charlotte is (the scene's Saver) before leaving the scene or the game.
func _save_now() -> void:
	var scene := get_tree().current_scene
	if scene:
		for node in scene.get_children():
			if node is Saver:
				node.save()


func _go_to_title() -> void:
	_save_now()
	toggle()
	Transition.change_scene(get_tree().current_scene, "res://scenes/intro.tscn")


func _quit() -> void:
	_save_now()
	get_tree().quit()
