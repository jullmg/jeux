extends CanvasLayer
## Autoload "GameMenu": the ☰ button in the top-left corner (or Escape) opens the game menu, which pauses the game:
## Reprendre, Options (music and effects volume, full screen), Écran titre, Quitter le jeu (both save first).
## The options are remembered in user://settings.cfg, next to the mute button's setting.

const SETTINGS := "user://settings.cfg"
const BLUE := Color("#1D4F91")
const YELLOW := Color("#FFD23F")
const CREAM := Color("#FBF6EA")
const INK := Color("#3A3A48")
const PAPER_EDGE := Color("#D8CDB6")
const CRAYONS := [Color("#E85FA0"), Color("#3D8BD9"), Color("#F2C230"), Color("#4FA34A"), Color("#E8812E"), Color("#8E5FC4")]

var _button: Button
var _page: Control
var _card: PanelContainer
var _main: VBoxContainer
var _options: VBoxContainer
var _to_title: Button
var _open := false
var _t := 0.0
var _under: Control
var _doodles: Control
var _info: Label


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


func _process(delta: float) -> void:
	var scene := get_tree().current_scene
	_button.visible = scene != null and not scene.scene_file_path.contains("/tools/")
	if _open:
		# The pets on the card and the doodles round it bob a little.
		_t += delta
		_card.queue_redraw()
		_doodles.queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		var notebook := get_node_or_null("/root/Notebook")
		if notebook and notebook._open:
			return
		var town_map := get_node_or_null("/root/TownMap")
		if town_map and town_map._open:
			return
		get_viewport().set_input_as_handled()
		toggle()


func toggle() -> void:
	_open = not _open
	_page.visible = _open
	if _open:
		var seasons := {"autumn": "Automne", "winter": "Hiver", "spring": "Printemps", "summer": "Été"}
		_info.text = "Charlotte, %d ans  ·  %s  ·  %s" % [GameState.age, Quests.money_text(GameState.money), seasons.get(Season.current, "")]
	_show(_main)
	if _open:
		# The card pops up, a little bouncy.
		_card.scale = Vector2.ONE * 0.9
		_card.modulate.a = 0.0
		_under.scale = Vector2.ONE * 0.9
		_under.modulate.a = 0.0
		var pop := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_parallel()
		pop.tween_property(_card, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		pop.tween_property(_card, "modulate:a", 1.0, 0.12)
		pop.tween_property(_under, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		pop.tween_property(_under, "modulate:a", 1.0, 0.18)
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
	_doodles = _Doodles.new()
	_doodles.size = _page.size
	_doodles.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_doodles.menu = self
	_page.add_child(_doodles)
	# The pages underneath, a little crooked, like a notebook's.
	_under = _Pages.new()
	_under.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_page.add_child(_under)
	_card = PanelContainer.new()
	_card.draw.connect(_decorate)
	_card.custom_minimum_size.x = 460
	var style := StyleBoxFlat.new()
	style.bg_color = CREAM
	style.border_color = PAPER_EDGE
	style.set_border_width_all(3)
	style.set_corner_radius_all(14)
	style.set_content_margin_all(28)
	style.content_margin_top = 34
	style.content_margin_bottom = 40
	style.shadow_color = Color(0, 0, 0, 0.35)
	style.shadow_size = 12
	style.shadow_offset = Vector2(5, 8)
	_card.add_theme_stylebox_override("panel", style)
	_page.add_child(_card)
	var both := VBoxContainer.new()
	_card.add_child(both)
	_main = VBoxContainer.new()
	_main.add_theme_constant_override("separation", 14)
	both.add_child(_main)
	_main.add_child(_title("Menu"))
	_info = Label.new()
	_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_info.add_theme_font_size_override("font_size", 17)
	_info.add_theme_color_override("font_color", Color(INK, 0.7))
	_main.add_child(_info)
	_main.add_child(_big_button("Reprendre", toggle, Color("#9ADB7E"), "star"))
	_main.add_child(_big_button("Options", func(): _show(_options), Color("#8FCBF2"), "flower"))
	_to_title = _big_button("Écran titre", _go_to_title, Color("#FFD866"), "house")
	_main.add_child(_to_title)
	_main.add_child(_big_button("Quitter le jeu", _quit, Color("#F7A3B5"), "heart"))
	var hint := Label.new()
	hint.text = "Échap pour reprendre"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 14)
	hint.add_theme_color_override("font_color", Color(INK, 0.45))
	_main.add_child(hint)
	_options = VBoxContainer.new()
	_options.add_theme_constant_override("separation", 16)
	both.add_child(_options)
	_options.add_child(_title("Options"))
	_options.add_child(_slider("Musique", "music", Sfx.BUS_MUSIC, CRAYONS[0], "note"))
	_options.add_child(_slider("Effets sonores", "effects", Sfx.BUS_SFX, CRAYONS[1], "star"))
	var full := CheckBox.new()
	full.text = "Plein écran"
	full.focus_mode = Control.FOCUS_NONE
	full.add_theme_font_size_override("font_size", 22)
	full.add_theme_constant_override("h_separation", 14)
	for color_name in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color"]:
		full.add_theme_color_override(color_name, INK)
	for state in ["normal", "hover", "pressed", "hover_pressed", "focus"]:
		full.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	full.add_theme_icon_override("unchecked", _box_icon(false))
	full.add_theme_icon_override("checked", _box_icon(true))
	full.button_pressed = _setting("fullscreen", false)
	full.toggled.connect(func(on: bool):
		_store("fullscreen", on)
		_apply_settings()
		Sfx.play("click"))
	_options.add_child(full)
	_options.add_child(_big_button("Retour", func(): _show(_main), Color("#FFD866"), "arrow"))
	_show(_main)


# Over the paper: its grain and faint ruled lines, then over the card's edges a cat, a dog and a hamster peeking, flowers in the
# corners, paw prints and a strip of washi tape.
func _decorate() -> void:
	var w := _card.size.x
	var h := _card.size.y
	var rng := RandomNumberGenerator.new()
	rng.seed = 12
	for i in 160:
		_card.draw_circle(Vector2(rng.randf_range(6, w - 6), rng.randf_range(6, h - 6)), rng.randf_range(0.6, 1.0), Color(0.55, 0.45, 0.3, 0.1))
	var y := 78.0
	while y < h - 18.0:
		_card.draw_line(Vector2(10, y), Vector2(w - 10, y), Color("#BFD3EA", 0.55), 1.5)
		y += 30.0
	_card.draw_line(Vector2(34, 8), Vector2(34, h - 8), Color("#E59A9A", 0.45), 1.5)
	var bob := func(phase: float, amount: float) -> float: return sin(_t * 2.0 + phase) * amount
	CuteArt.cat_head(_card, Vector2(54, 0 + bob.call(0.0, 2.5)), 26, Color("#E8954A"))
	CuteArt.dog_head(_card, Vector2(w - 56, 2 + bob.call(1.7, 2.5)), 26, Color("#C9A27A"), Color("#7A5232"))
	CuteArt.hamster_head(_card, Vector2(w / 2.0 + 110.0, h + 3 + bob.call(3.1, 3.0)), 20)
	CuteArt.capybara_head(_card, Vector2(w / 2.0 - 100.0, h + 5 + bob.call(4.4, 3.0)), 24)
	for f in [[Vector2(8, h - 8), Color("#F2A7C9")], [Vector2(26, h + 4), Color("#FFFFFF")], [Vector2(w - 10, h - 6), Color("#9B59B6")],
			[Vector2(w - 30, h + 6), Color("#F7C6D9")], [Vector2(-6, 60), Color("#FFD23F")], [Vector2(w + 6, 70), Color("#F2A7C9")]]:
		CuteArt.flower(_card, f[0], 12, f[1])
	for p in [Vector2(60, h - 24), Vector2(80, h - 38)]:
		_paw(p)
	# Washi tape holding the top edge, between the cat and the dog.
	var tape := PackedVector2Array([Vector2(w / 2.0 - 46, -10), Vector2(w / 2.0 + 44, -16), Vector2(w / 2.0 + 48, 8), Vector2(w / 2.0 - 42, 14)])
	_card.draw_colored_polygon(tape, Color("#BFE3F7", 0.85))
	for k in 6:
		var a := tape[0].lerp(tape[1], (k + 0.5) / 6.0)
		var b := tape[3].lerp(tape[2], (k + 0.5) / 6.0)
		_card.draw_line(a.lerp(b, 0.2), a.lerp(b, 0.8), Color(1, 1, 1, 0.5), 2.0)


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
	_card.pivot_offset = _card.size / 2.0
	_under.position = _card.position
	_under.size = _card.size
	_under.pivot_offset = _card.size / 2.0
	_under.queue_redraw()


func _title(text: String) -> Control:
	var title := _CrayonTitle.new()
	title.text = text
	title.custom_minimum_size = Vector2(0, 64)
	return title


# A big sticker-like button: its colour, a little drawing at its left, a thick lower edge that squashes when pressed.
func _big_button(text: String, action: Callable, color: Color, icon: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(360, 56)
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 24)
	for state in ["normal", "hover", "pressed"]:
		var box := StyleBoxFlat.new()
		box.bg_color = color.lightened(0.18) if state == "hover" else color
		box.border_color = color.darkened(0.55)
		box.set_border_width_all(3)
		box.border_width_bottom = 3 if state == "pressed" else 7
		box.content_margin_top = 4 if state == "pressed" else 0
		box.set_corner_radius_all(16)
		button.add_theme_stylebox_override(state, box)
		button.add_theme_color_override("font_%scolor" % ("" if state == "normal" else state + "_"), BLUE)
	button.pressed.connect(func():
		Sfx.play("click")
		action.call())
	button.resized.connect(func() -> void: button.pivot_offset = button.size / 2.0)
	for hover in [[true, 1.04], [false, 1.0]]:
		button.connect("mouse_entered" if hover[0] else "mouse_exited", func() -> void:
			create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).tween_property(button, "scale", Vector2.ONE * hover[1], 0.1))
	button.draw.connect(func() -> void:
		# A soft shine along the top edge, then the little drawing.
		button.draw_line(Vector2(20, 8), Vector2(button.size.x - 20, 8), Color(1, 1, 1, 0.4), 4.0, true)
		_button_icon(button, icon))
	return button


# A row: a little drawing, the name, a coloured slider with a round handle, the percentage.


func _button_icon(button: Button, icon: String) -> void:
	var c := Vector2(36, button.size.y / 2.0 - 2.0)
	if icon == "star":
		CuteArt.star(button, c, 13, Color("#FFD23F"))
	elif icon == "flower":
		CuteArt.flower(button, c, 12, Color("#F7C6D9"))
	elif icon == "house":
		CuteArt.house(button, c, 13)
	elif icon == "heart":
		CuteArt.heart(button, c, 12, Color("#E04F5F"))
	elif icon == "arrow":
		button.draw_line(c + Vector2(10, 0), c + Vector2(-10, 0), BLUE, 4.0, true)
		button.draw_polyline(PackedVector2Array([c + Vector2(-2, -9), c + Vector2(-11, 0), c + Vector2(-2, 9)]), BLUE, 4.0, true)


func _slider(text: String, key: String, bus: String, color: Color, icon: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	var mark := Control.new()
	mark.custom_minimum_size = Vector2(34, 34)
	mark.draw.connect(func():
		var c := Vector2(17, 17)
		if icon == "note":
			mark.draw_circle(c + Vector2(-4, 8), 6.0, color)
			mark.draw_line(c + Vector2(1, 8), c + Vector2(1, -12), color.darkened(0.3), 3.0)
			mark.draw_line(c + Vector2(1, -12), c + Vector2(10, -6), color.darkened(0.3), 3.0)
		else:
			CuteArt.star(mark, c, 13, Color("#FFD23F")))
	row.add_child(mark)
	var label := Label.new()
	label.text = text
	label.custom_minimum_size.x = 130
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", INK)
	row.add_child(label)
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.custom_minimum_size = Vector2(190, 32)
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slider.focus_mode = Control.FOCUS_NONE
	var track := StyleBoxFlat.new()
	track.bg_color = Color("#E3D9C4")
	track.border_color = PAPER_EDGE.darkened(0.15)
	track.set_border_width_all(2)
	track.set_corner_radius_all(8)
	track.content_margin_top = 7
	track.content_margin_bottom = 7
	slider.add_theme_stylebox_override("slider", track)
	var fill := track.duplicate() as StyleBoxFlat
	fill.bg_color = color
	fill.border_color = color.darkened(0.45)
	slider.add_theme_stylebox_override("grabber_area", fill)
	slider.add_theme_stylebox_override("grabber_area_highlight", fill)
	slider.add_theme_icon_override("grabber", _handle_icon(color))
	slider.add_theme_icon_override("grabber_highlight", _handle_icon(color.lightened(0.25)))
	var percent := Label.new()
	percent.custom_minimum_size.x = 56
	percent.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	percent.add_theme_font_size_override("font_size", 18)
	percent.add_theme_color_override("font_color", Color(INK, 0.7))
	slider.value = _setting(key, 0.8)
	percent.text = "%d %%" % roundi(slider.value * 100.0)
	slider.value_changed.connect(func(v: float):
		_store(key, v)
		_apply_settings()
		percent.text = "%d %%" % roundi(v * 100.0)
		if bus == Sfx.BUS_SFX:
			Sfx.play("pop"))
	row.add_child(slider)
	row.add_child(percent)
	return row


# The slider's round handle: a coloured disc with a dark rim and a light spot.
func _handle_icon(color: Color) -> ImageTexture:
	const N := 34
	var img := Image.create(N, N, false, Image.FORMAT_RGBA8)
	for y in N:
		for x in N:
			var d := Vector2(x + 0.5, y + 0.5).distance_to(Vector2(N / 2.0, N / 2.0))
			var a := clampf(N / 2.0 - 1.0 - d, 0.0, 1.0)
			var c := color.darkened(0.5) if d > N / 2.0 - 4.5 else color
			if Vector2(x + 0.5, y + 0.5).distance_to(Vector2(N / 2.0 - 4.0, N / 2.0 - 4.5)) < 3.2:
				c = c.lightened(0.55)
			img.set_pixel(x, y, Color(c, a))
	return ImageTexture.create_from_image(img)


# The check box: a rounded square, yellow with a blue tick when it is on.
func _box_icon(on: bool) -> ImageTexture:
	const N := 36
	var img := Image.create(N, N, false, Image.FORMAT_RGBA8)
	var tick := [Vector2(9, 19), Vector2(15, 25), Vector2(27, 11)]
	for y in N:
		for x in N:
			var p := Vector2(x + 0.5, y + 0.5)
			var q := (p - Vector2(N / 2.0, N / 2.0)).abs() - Vector2(N / 2.0 - 8.0, N / 2.0 - 8.0)
			var d := Vector2(maxf(q.x, 0.0), maxf(q.y, 0.0)).length() + minf(maxf(q.x, q.y), 0.0) - 6.0
			var a := clampf(1.0 - d, 0.0, 1.0)
			var c := BLUE if d > -2.6 else (YELLOW if on else Color.WHITE)
			if on:
				for k in 2:
					var s0: Vector2 = tick[k]
					var s1: Vector2 = tick[k + 1]
					var t := clampf((p - s0).dot(s1 - s0) / (s1 - s0).length_squared(), 0.0, 1.0)
					if p.distance_to(s0.lerp(s1, t)) < 2.2:
						c = BLUE
			img.set_pixel(x, y, Color(c, a))
	return ImageTexture.create_from_image(img)


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


# The page's title, in crayon: each letter in its own colour, a little off and gone over twice, like on the map.
class _CrayonTitle:
	extends Control
	var text := ""

	func _draw() -> void:
		var rng := RandomNumberGenerator.new()
		rng.seed = hash(text)
		var font := ThemeDB.fallback_font
		var total := 0.0
		for ch in text:
			total += font.get_char_size(ch.unicode_at(0), 46).x + 1.0
		var x := (size.x - total) / 2.0
		for i in text.length():
			var ch := text[i]
			var col: Color = CRAYONS[i % CRAYONS.size()]
			var w := font.get_char_size(ch.unicode_at(0), 46).x
			var jitter := Vector2(0, rng.randf_range(-3.0, 3.0))
			var turn := rng.randf_range(-0.1, 0.1)
			for pass_i in 2:
				draw_set_transform(Vector2(x, size.y * 0.76) + jitter + Vector2(1.0, 0.8) * pass_i, turn, Vector2.ONE)
				draw_string(font, Vector2.ZERO, ch, HORIZONTAL_ALIGNMENT_LEFT, -1, 46, Color(col, 1.0 if pass_i == 0 else 0.55))
			x += w + 1.0
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


# Sheets of paper under the card, a little crooked.
class _Pages:
	extends Control

	func _draw() -> void:
		for k in [[2, -0.028, Vector2(-8, 10)], [1, 0.02, Vector2(6, 6)]]:
			var tint := CREAM.darkened(0.05 * k[0])
			draw_set_transform(size / 2.0 + k[2], k[1], Vector2.ONE)
			var r := Rect2(-size / 2.0, size)
			draw_rect(Rect2(r.position + Vector2(4, 6), r.size), Color(0, 0, 0, 0.18))
			draw_rect(r, tint)
			draw_rect(r, PAPER_EDGE, false, 2.0)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


# Crayon drawings scattered round the card: a sun, clouds, hearts, stars, flowers, drifting a little.
class _Doodles:
	extends Control
	var menu

	func _draw() -> void:
		var rng := RandomNumberGenerator.new()
		rng.seed = 5
		var t: float = menu._t
		var items := [
			["sun", Vector2(170, 130), 30.0, 0.0], ["heart", Vector2(300, 520), 17.0, 1.1], ["star", Vector2(215, 330), 16.0, 2.0],
			["flower", Vector2(120, 560), 18.0, 0.6], ["star", Vector2(1010, 150), 15.0, 1.5], ["heart", Vector2(1120, 360), 19.0, 2.6],
			["flower", Vector2(1040, 560), 18.0, 3.2], ["star", Vector2(930, 640), 14.0, 0.3], ["heart", Vector2(240, 90), 12.0, 2.2],
			["flower", Vector2(1150, 120), 14.0, 1.9],
			["capy", Vector2(160, 430), 34.0, 0.9], ["capy", Vector2(1110, 560), 30.0, 2.4], ["capy", Vector2(1120, 230), 20.0, 3.7]]
		for it in items:
			var c: Vector2 = it[1] + Vector2(sin(t * 0.9 + it[3]) * 4.0, sin(t * 1.3 + it[3] * 1.7) * 6.0)
			var r: float = it[2]
			match it[0]:
				"sun":
					CuteArt.sun(self, c, r, true, rng)
				"heart":
					CuteArt.heart(self, c, r, CRAYONS[0], true, rng)
				"star":
					CuteArt.star(self, c, r, CRAYONS[2], true, rng)
				"capy":
					CuteArt.capybara(self, c, r, true, rng)
				_:
					CuteArt.flower(self, c, r, CRAYONS[5], true, rng)
