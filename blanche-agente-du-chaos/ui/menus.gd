class_name Menus
extends Control
## Tous les écrans hors du jeu. Chaque écran est reconstruit à la demande et se parcourt au clavier,
## à la manette, à la souris ou au doigt.

signal play(level: int)
signal brief(level: int)
signal resume
signal restart
signal to_title
signal quit_asked
signal options_changed

var save: SaveData
## Nom de l'écran affiché ("" : aucun).
var screen := ""
var _back := Callable()
## Juste après la fin d'une partie, « valider » est ignoré : on ne saute pas les résultats en martelant le bouton.
var _quiet_until := 0
var _holder: Control


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	theme = UiStyle.theme()
	process_mode = Node.PROCESS_MODE_ALWAYS


func close() -> void:
	if _holder:
		_holder.queue_free()
		_holder = null
	screen = ""
	_back = Callable()
	_quiet_until = 0


func _input(event: InputEvent) -> void:
	if Time.get_ticks_msec() < _quiet_until and (event.is_action("ui_accept") or event is InputEventMouseButton):
		get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	if screen != "" and event.is_action_pressed("ui_cancel") and _back.is_valid():
		get_viewport().set_input_as_handled()
		Sound.play("clic", -4.0, 0.8)
		_back.call()


func _begin(name_: String, shade := 0.62) -> Control:
	close()
	screen = name_
	_holder = Control.new()
	_holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_holder)
	if shade > 0.0:
		var veil := ColorRect.new()
		veil.color = Color(UiStyle.SHADE, shade)
		veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_holder.add_child(veil)
	return _holder


## Un carton au centre, et la colonne où y mettre les choses.
func _card(holder: Control, width := 900.0, spacing := 18) -> VBoxContainer:
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(width, 0)
	center.add_child(panel)
	var column := UiStyle.column(spacing)
	panel.add_child(column)
	return column


func _wrapped(text: String, width: float, size := 32, color := UiStyle.INK) -> Label:
	var l := UiStyle.label(text, size, color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(width, 0)
	return l


func _center_button(column: VBoxContainer, text: String, action: Callable, width := 420.0) -> Button:
	var b := UiStyle.button(text, action, 40, width)
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.add_child(b)
	return b


static func _focus(b: Control) -> void:
	b.grab_focus.call_deferred()


func _stars_control(count: int, radius: float, animate := false) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(radius * 7.2, radius * 2.4)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	c.set_meta("shown", 0 if animate else 3)
	c.draw.connect(func() -> void:
		for i in 3:
			var lift := -radius * 0.18 if i == 1 else 0.0
			var filled := i < count and i < int(c.get_meta("shown"))
			Icons.star(c, Vector2(c.size.x / 2.0 + (i - 1) * radius * 2.35, c.size.y / 2.0 + lift), radius, filled))
	if animate and count > 0:
		# L'animation appartient au contrôle : elle disparaît avec lui.
		c.ready.connect(func() -> void:
			var tween := c.create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_ignore_time_scale(true)
			for i in count:
				tween.tween_interval(0.45 if i == 0 else 0.4)
				tween.tween_callback(_light_star.bind(c, i)))
	return c


func _light_star(c: Control, i: int) -> void:
	c.set_meta("shown", i + 1)
	c.queue_redraw()
	Sound.play("etoile", 0.0, 1.0 + i * 0.12)


# ------------------------------------------------------------------ écrans

func show_title() -> void:
	var holder := _begin("titre", 0.0)
	# Un voile sombre à gauche pour que le titre se lise sur la cuisine.
	var fade := Gradient.new()
	fade.set_color(0, Color(UiStyle.SHADE, 0.86))
	fade.set_color(1, Color(UiStyle.SHADE, 0.0))
	fade.add_point(0.55, Color(UiStyle.SHADE, 0.62))
	var veil_texture := GradientTexture2D.new()
	veil_texture.gradient = fade
	veil_texture.width = 256
	veil_texture.height = 4
	var veil := TextureRect.new()
	veil.texture = veil_texture
	veil.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	veil.set_anchors_and_offsets_preset(Control.PRESET_LEFT_WIDE)
	veil.offset_right = 1250
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(veil)
	var box := UiStyle.column(16)
	box.set_anchors_and_offsets_preset(Control.PRESET_LEFT_WIDE)
	box.offset_left = 90
	box.offset_right = 900
	holder.add_child(box)
	var name_label := UiStyle.label(Texts.TITLE, 104, UiStyle.CREAM)
	var sub := UiStyle.label(Texts.SUBTITLE, 74, UiStyle.GOLD)
	for l: Label in [name_label, sub]:
		l.add_theme_color_override("font_outline_color", UiStyle.INK)
		l.add_theme_constant_override("outline_size", 24)
		box.add_child(l)
	sub.add_theme_constant_override("line_spacing", -10)
	var tag := UiStyle.label(Texts.TAGLINE, 30, UiStyle.CREAM)
	tag.add_theme_color_override("font_outline_color", UiStyle.INK)
	tag.add_theme_constant_override("outline_size", 10)
	box.add_child(tag)
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 26)
	box.add_child(spacer)
	var started := save.total_stars() > 0 or save.unlocked > 1
	var first := _center_button(box, Texts.CONTINUE if started else Texts.PLAY,
		func() -> void: brief.emit(save.unlocked))
	_center_button(box, Texts.LEVELS, show_select)
	_center_button(box, Texts.OPTIONS, show_options.bind(show_title))
	_center_button(box, Texts.CREDITS, show_credits)
	_center_button(box, Texts.QUIT, func() -> void: quit_asked.emit())
	_focus(first)


func show_select() -> void:
	var holder := _begin("missions")
	var column := _card(holder, 1560, 22)
	column.add_child(UiStyle.label(Texts.LEVELS, 60))
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 22)
	grid.add_theme_constant_override("v_separation", 22)
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.add_child(grid)
	var focus: Button
	for id in range(1, Levels.COUNT + 1):
		var level := Levels.load_level(id)
		var open := id <= save.unlocked
		var b := UiStyle.button("", func() -> void: brief.emit(id), 30, 340)
		b.custom_minimum_size = Vector2(340, 270)
		b.disabled = not open
		b.focus_mode = Control.FOCUS_ALL if open else Control.FOCUS_NONE
		var inside := UiStyle.column(6)
		inside.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		inside.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(inside)
		inside.add_child(UiStyle.label(Texts.MISSION % id, 26, UiStyle.CREAM))
		var meal := _wrapped(str(level.meal), 300, 34, Color.WHITE)
		meal.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		inside.add_child(meal)
		if open:
			inside.add_child(UiStyle.label(str(level.novelty), 24, UiStyle.CREAM))
			inside.add_child(_stars_control(save.stars_of(id), 22))
			inside.add_child(UiStyle.label(Texts.BEST % save.best_of(id), 22, UiStyle.CREAM))
		else:
			var lock := Control.new()
			lock.custom_minimum_size = Vector2(0, 90)
			lock.draw.connect(func() -> void: Icons.lock(lock, lock.size / 2.0, 36, Color("fff3df")))
			inside.add_child(lock)
			inside.add_child(UiStyle.label(Texts.LOCKED, 24, UiStyle.CREAM))
		grid.add_child(b)
		if id == save.unlocked:
			focus = b
	var back := _center_button(column, Texts.BACK, func() -> void: to_title.emit(), 320)
	_back = func() -> void: to_title.emit()
	_focus(focus if focus else back)


func show_brief(id: int) -> void:
	var level := Levels.load_level(id)
	var holder := _begin("consignes", 0.45)
	var column := _card(holder, 1040)
	column.add_child(UiStyle.label(Texts.MISSION % id, 30, UiStyle.INK_SOFT))
	column.add_child(UiStyle.label(str(level.meal), 62))
	column.add_child(UiStyle.label(Texts.NEW % level.novelty, 38, UiStyle.PINK_DARK))
	for line: String in level.intro:
		var row := UiStyle.row(16)
		var dot := Control.new()
		dot.custom_minimum_size = Vector2(44, 44)
		dot.draw.connect(func() -> void: Icons.paw(dot, Vector2(22, 22), 20, UiStyle.PINK))
		row.add_child(dot)
		var l := _wrapped(line, 860, 31)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		row.add_child(l)
		column.add_child(row)
	var goal := UiStyle.row(40)
	for i in 3:
		var item := UiStyle.row(8)
		var s := Control.new()
		s.custom_minimum_size = Vector2(44, 44)
		s.draw.connect(func() -> void: Icons.star(s, Vector2(22, 22), 19, true))
		item.add_child(s)
		item.add_child(UiStyle.label(str(int(level.stars[i])), 32))
		goal.add_child(item)
	column.add_child(goal)
	var buttons := UiStyle.row(24)
	column.add_child(buttons)
	buttons.add_child(UiStyle.button(Texts.BACK, show_select, 40, 300))
	var go := UiStyle.button(Texts.START, func() -> void: play.emit(id), 40, 440)
	buttons.add_child(go)
	_back = show_select
	_focus(go)


func show_pause() -> void:
	var holder := _begin("pause")
	var column := _card(holder, 640)
	column.add_child(UiStyle.label(Texts.PAUSE, 64))
	var first := _center_button(column, Texts.RESUME, func() -> void: resume.emit())
	_center_button(column, Texts.RETRY, func() -> void: restart.emit())
	_center_button(column, Texts.OPTIONS, show_options.bind(show_pause))
	_center_button(column, Texts.MENU, func() -> void: to_title.emit())
	_back = func() -> void: resume.emit()
	_focus(first)


## `result` : {level, score, stars, eaten, caught, new_best, target}
func show_results(result: Dictionary) -> void:
	var holder := _begin("resultats", 0.5)
	_quiet_until = Time.get_ticks_msec() + 1100
	var column := _card(holder, 1040)
	var won: bool = result.stars > 0
	var id: int = result.level
	column.add_child(UiStyle.label(Texts.WON if won else Texts.LOST, 64, UiStyle.PINK_DARK if won else UiStyle.INK))
	column.add_child(_stars_control(result.stars, 64, true))
	column.add_child(UiStyle.label(str(result.score), 96))
	if result.new_best:
		column.add_child(UiStyle.label(Texts.NEW_RECORD, 34, UiStyle.GREEN.darkened(0.2)))
	if not won:
		column.add_child(UiStyle.label(Texts.LOST_TEXT % (result.target - result.score), 32))
	var e: Array = result.eaten
	column.add_child(UiStyle.label(Texts.STATS % [e[0], e[1], e[2], e[3], result.caught], 28, UiStyle.INK_SOFT))
	var buttons := UiStyle.row(20)
	column.add_child(buttons)
	var focus: Button
	buttons.add_child(UiStyle.button(Texts.MENU, func() -> void: to_title.emit(), 36, 300))
	var retry := UiStyle.button(Texts.RETRY, func() -> void: restart.emit(), 36, 300)
	buttons.add_child(retry)
	focus = retry
	if won:
		var last := id >= Levels.COUNT
		var next := UiStyle.button(Texts.CONTINUE if last else Texts.NEXT, func() -> void:
			if last:
				show_end()
			else:
				brief.emit(id + 1), 36, 360)
		buttons.add_child(next)
		focus = next
	_back = func() -> void: to_title.emit()
	_focus(focus)


func show_end() -> void:
	save.finished_seen = true
	save.save_file()
	var holder := _begin("fin", 0.55)
	_quiet_until = Time.get_ticks_msec() + 1100
	var column := _card(holder, 1100, 26)
	column.add_child(UiStyle.label(Texts.END_TITLE, 54, UiStyle.PINK_DARK))
	var paws := Control.new()
	paws.custom_minimum_size = Vector2(0, 110)
	paws.draw.connect(func() -> void:
		for i in 7:
			Icons.paw(paws, Vector2(paws.size.x / 2.0 + (i - 3) * 110, 55 + (18 if i % 2 else -18)), 34, UiStyle.PINK))
	column.add_child(paws)
	column.add_child(_wrapped(Texts.END_TEXT % [save.total_stars(), Levels.COUNT * 3], 1000, 38))
	var first := _center_button(column, Texts.MENU, func() -> void: to_title.emit())
	_back = func() -> void: to_title.emit()
	Sound.play("victoire")
	_focus(first)


func show_options(from: Callable) -> void:
	var holder := _begin("options")
	var column := _card(holder, 1180, 14)
	column.add_child(UiStyle.label(Texts.OPTIONS, 56))
	var first: Control
	for spec: Array in [[Texts.MUSIC_VOLUME, "music"], [Texts.SFX_VOLUME, "sfx"]]:
		var row := UiStyle.row(30)
		var name_label := UiStyle.label(spec[0], 34, UiStyle.INK, HORIZONTAL_ALIGNMENT_LEFT)
		name_label.custom_minimum_size = Vector2(340, 0)
		row.add_child(name_label)
		var slider := HSlider.new()
		slider.min_value = 0.0
		slider.max_value = 1.0
		slider.step = 0.05
		slider.value = save.options[spec[1]]
		slider.custom_minimum_size = Vector2(460, 44)
		slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var key: String = spec[1]
		var value := UiStyle.label("%d %%" % int(slider.value * 100), 30)
		value.custom_minimum_size = Vector2(120, 0)
		slider.value_changed.connect(func(v: float) -> void:
			save.options[key] = v
			value.text = "%d %%" % int(round(v * 100))
			options_changed.emit()
			if key == "sfx":
				Sound.play("prise"))
		row.add_child(slider)
		row.add_child(value)
		column.add_child(row)
		if first == null:
			first = slider
	for spec: Array in [[Texts.FULLSCREEN, "fullscreen"], [Texts.REDUCED_MOTION, "reduced_motion"],
			[Texts.LONG_HINTS, "long_hints"]]:
		var row := UiStyle.row(30)
		var name_label := UiStyle.label(spec[0], 34, UiStyle.INK, HORIZONTAL_ALIGNMENT_LEFT)
		name_label.custom_minimum_size = Vector2(610, 0)
		row.add_child(name_label)
		var key: String = spec[1]
		var b := UiStyle.button(Texts.ON if save.options[key] else Texts.OFF, func() -> void: pass, 30, 340)
		b.pressed.connect(func() -> void:
			save.options[key] = not save.options[key]
			b.text = Texts.ON if save.options[key] else Texts.OFF
			options_changed.emit())
		b.name = key
		row.add_child(b)
		column.add_child(row)
	column.add_child(_wrapped(Texts.CONTROLS_TEXT, 1100, 24, UiStyle.INK_SOFT))
	var buttons := UiStyle.row(24)
	column.add_child(buttons)
	var leave := func() -> void:
		save.save_file()
		from.call()
	if from == show_title:
		var erase := UiStyle.button(Texts.ERASE, show_erase.bind(from), 30, 440)
		buttons.add_child(erase)
	buttons.add_child(UiStyle.button(Texts.BACK, leave, 36, 340))
	_back = leave
	_focus(first)


func show_erase(from: Callable) -> void:
	var holder := _begin("effacer", 0.75)
	var column := _card(holder, 760)
	column.add_child(UiStyle.label(Texts.ERASE_CONFIRM, 48))
	var no := _center_button(column, Texts.NO, show_options.bind(from))
	_center_button(column, Texts.YES, func() -> void:
		save.erase_progress()
		to_title.emit())
	_back = show_options.bind(from)
	_focus(no)


func show_credits() -> void:
	var holder := _begin("credits")
	var column := _card(holder, 1100)
	column.add_child(_wrapped(Texts.CREDITS_TEXT, 1020, 32))
	if save.finished_seen:
		_center_button(column, Texts.SEE_END, show_end, 360)
	var back := _center_button(column, Texts.BACK, show_title, 320)
	_back = show_title
	_focus(back)
