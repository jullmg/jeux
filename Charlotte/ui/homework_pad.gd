class_name HomeworkPad
extends CanvasLayer
## Her homework book, opened from the desk in her bedroom: the week's exercises one at a time on a page of lined
## paper (`Homework`). The question is written AND read out loud (`Voice`, the computer's own Québec voice), and
## she answers on a big number pad, on the keyboard, or by picking one of the answers. A star lights up for each
## one she gets, and the finished week puts `Homework.REWARD` in her pocket.

signal closed()

const PAD := Vector2(1000, 676)
const BLUE := Color("#1D4F91")
const YELLOW := Color("#FFD23F")
const CREAM := Color("#FBF6EA")
const INK := Color("#3A3A48")
const GREEN := Color("#2E7D32")
const RED := Color("#E04F5F")
const PRAISE := ["Bravo Chachoue !", "C'est en plein ça !", "Wow, t'es bonne !", "Oui ! Tu l'as !"]
const AGAIN := ["Oups ! Essaie encore.", "Pas tout à fait. Réessaie !", "Non… essaie encore une fois."]

var _root: Control
var _panel: Panel
var _card: Panel
var _part: Label
var _stars: HBoxContainer
var _question: Label
var _hint: Label
var _zone: Control
var _feedback: Label
var _listen: Button
var _typed := ""
var _typed_label: Label
var _field: LineEdit
var _index := -1
var _locked := false
var _rng := RandomNumberGenerator.new()


func _init() -> void:
	layer = 62


func _ready() -> void:
	add_to_group("modal")
	_rng.randomize()
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_root)
	var dim := ColorRect.new()
	dim.color = Color(0.06, 0.07, 0.16, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.add_child(dim)
	_panel = Panel.new()
	_panel.position = (Vector2(1280, 720) - PAD) / 2.0
	_panel.size = PAD
	_panel.add_theme_stylebox_override("panel", _box(CREAM, BLUE, 6, 26))
	_root.add_child(_panel)
	var lines := _Lines.new()
	lines.size = PAD
	lines.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(lines)
	var title := _text("Mes devoirs de la semaine", 34, BLUE, Vector2(0, 16), PAD.x)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var week := _text("%s · %s" % [Homework.title(), Homework.week_text()], 19, Color(INK, 0.75),
		Vector2(0, 58), PAD.x)
	week.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_part = _text("", 18, Color("#3D8BD9"), Vector2(0, 88), PAD.x)
	_part.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stars = HBoxContainer.new()
	_stars.position = Vector2(0, 114)
	_stars.size = Vector2(PAD.x, 34)
	_stars.alignment = BoxContainer.ALIGNMENT_CENTER
	_stars.add_theme_constant_override("separation", 6)
	_panel.add_child(_stars)
	# The question, on a card of its own, with the loudspeaker that says it again.
	_card = Panel.new()
	_card.position = Vector2(56, 152)
	_card.size = Vector2(PAD.x - 112, 136)
	_card.add_theme_stylebox_override("panel", _box(Color("#FFFDF7"), Color("#C8A27A"), 3, 18))
	_panel.add_child(_card)
	var card := _card
	_question = _text("", 28, INK, Vector2(26, 16), card.size.x - 130, card)
	_question.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_question.size.y = 76
	_hint = _text("", 18, Color(INK, 0.6), Vector2(26, 96), card.size.x - 130, card)
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_listen = Button.new()
	_listen.position = Vector2(card.size.x - 94, 32)
	_listen.size = Vector2(72, 72)
	_listen.custom_minimum_size = _listen.size
	_listen.focus_mode = Control.FOCUS_NONE
	_listen.tooltip_text = "Écoute encore"
	for state in ["normal", "hover", "pressed"]:
		_listen.add_theme_stylebox_override(state, _box(YELLOW if state == "normal" else Color("#FFE481"), BLUE, 3, 36))
	_listen.draw.connect(_draw_speaker)
	_listen.pressed.connect(_read_out)
	card.add_child(_listen)
	_zone = Control.new()
	_zone.position = Vector2(0, 292)
	_zone.size = Vector2(PAD.x, 290)
	_panel.add_child(_zone)
	_feedback = _text("", 25, GREEN, Vector2(0, 584), PAD.x)
	_feedback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var bar := HBoxContainer.new()
	bar.position = Vector2(40, 616)
	bar.size = Vector2(PAD.x - 80, 52)
	bar.add_theme_constant_override("separation", 14)
	_panel.add_child(bar)
	_action(bar, "Fermer le cahier", func() -> void: _close())
	_show_next()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_close()
		return
	if _locked or _index < 0 or not event is InputEventKey or not event.pressed or event.echo:
		return
	var exercise: Dictionary = Homework.exercises()[_index]
	if str(exercise.kind) != "nombre":
		return
	var key := event as InputEventKey
	var typed := String.chr(key.unicode) if key.unicode > 0 else ""
	if typed.length() == 1 and typed >= "0" and typed <= "9":
		_tap(typed)
	elif key.keycode == KEY_BACKSPACE:
		_tap("←")
	elif key.keycode == KEY_ENTER or key.keycode == KEY_KP_ENTER:
		_tap("ok")


# ── One exercise after another ──────────────────────────────────

func _show_next() -> void:
	_index = Homework.next_one()
	_feedback.text = ""
	_typed = ""
	_field = null
	_typed_label = null
	_refresh_stars()
	for child in _zone.get_children():
		child.queue_free()
	_feedback.add_theme_color_override("font_color", GREEN)
	if _index < 0:
		_show_finished()
		return
	var exercise: Dictionary = Homework.exercises()[_index]
	# With no voice on this computer, a dictée would say nothing at all: the page writes the sentence instead.
	var written := str(exercise.get("show", exercise.get("say", "")))
	if not Voice.available() and exercise.has("say"):
		written = str(exercise.say)
	_question.text = "%d.  %s" % [_index + 1, written]
	_hint.text = str(exercise.get("hint", ""))
	_part.text = "%s  —  question %d sur %d" % [str(exercise.get("part", Homework.title())),
		_index + 1, Homework.exercises().size()]
	_listen.visible = Voice.available()
	match str(exercise.kind):
		"nombre": _build_keypad()
		"choix": _build_choices(exercise.get("options", []) as Array)
		_: _build_field()
	_read_out()


func _read_out() -> void:
	if _index < 0:
		return
	var exercise: Dictionary = Homework.exercises()[_index]
	Voice.say(str(exercise.get("say", exercise.get("show", ""))))


func _show_finished() -> void:
	# The page of congratulations: confetti, her own drawings, and the whole week in stars.
	_card.visible = false
	_part.text = ""
	_listen.visible = false
	var party := _Party.new()
	party.position = Vector2(0, -140)
	party.size = Vector2(PAD.x, 420)
	party.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_zone.add_child(party)
	var bravo := _text("Bravo Chachoue !", 58, BLUE, Vector2(0, -126), PAD.x, _zone)
	bravo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bravo.pivot_offset = Vector2(PAD.x / 2.0, 34.0)
	bravo.scale = Vector2(0.7, 0.7)
	bravo.create_tween().tween_property(bravo, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var line := _text("Tes devoirs de la semaine sont tous faits !", 28, INK, Vector2(0, -52), PAD.x, _zone)
	line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var count := Homework.exercises().size()
	var score := _text("%d bonnes réponses sur %d  ★" % [count, count], 24, GREEN, Vector2(0, -14), PAD.x, _zone)
	score.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var paid := Homework.pay()
	if paid > 0.0:
		_feedback.text = "+ %s dans ta poche !" % Quests.money_text(paid)
		var notebook := get_node_or_null("/root/Notebook")
		if notebook:
			notebook.announce("devoirs", "Tes devoirs de la semaine sont faits !")
	else:
		_feedback.text = "Tu peux aller jouer dehors !"
	Sfx.play("chime")
	Voice.say("Bravo Chachoue ! Tes devoirs de la semaine sont tous faits. Tu peux aller jouer dehors !")
	var again := HBoxContainer.new()
	again.position = Vector2(0, 230)
	again.size = Vector2(PAD.x, 56)
	again.alignment = BoxContainer.ALIGNMENT_CENTER
	_zone.add_child(again)
	_action(again, "Les refaire pour pratiquer", func() -> void:
		_card.visible = true
		Homework.forget()
		_show_next())


# ── Her answer ──────────────────────────────────────────────────

func _verify(given: String) -> void:
	if _locked or _index < 0 or given.strip_edges().is_empty():
		return
	var exercise: Dictionary = Homework.exercises()[_index]
	var how := Homework.check(exercise, given)
	if how == "non":
		_feedback.add_theme_color_override("font_color", RED)
		_feedback.text = AGAIN[_rng.randi() % AGAIN.size()]
		Sfx.play("squeak")
		Voice.say(_feedback.text)
		_typed = ""
		if _typed_label:
			_typed_label.text = ""
		if _field:
			_field.text = ""
		var shake := _zone.create_tween()
		for dx in [12.0, -10.0, 7.0, -4.0, 0.0]:
			shake.tween_property(_zone, "position:x", dx, 0.05)
		return
	_locked = true
	_feedback.add_theme_color_override("font_color", GREEN)
	if how == "presque":
		_feedback.text = "Presque ! Ça s'écrit : %s" % Homework.answer_text(exercise)
		Voice.say("Presque ! N'oublie pas les accents.")
	else:
		_feedback.text = PRAISE[_rng.randi() % PRAISE.size()]
		Voice.say(_feedback.text)
	Sfx.play("chime")
	Homework.mark_done(_index)
	_refresh_stars()
	if _field:
		_field.editable = false
	var wait := get_tree().create_timer(2.2 if how == "presque" else 1.5)
	wait.timeout.connect(func() -> void:
		_locked = false
		_show_next())


# A digit, the rubber, or the OK of the number pad.
func _tap(key: String) -> void:
	if _locked:
		return
	if key == "ok":
		_verify(_typed)
		return
	if key == "←":
		_typed = _typed.substr(0, maxi(0, _typed.length() - 1))
	elif _typed.length() < 6:
		_typed += key
	Sfx.play("click")
	if _typed_label:
		_typed_label.text = _typed


# ── The three ways of answering ─────────────────────────────────

func _build_keypad() -> void:
	_typed_label = _slate()
	var pad := GridContainer.new()
	pad.columns = 3
	pad.add_theme_constant_override("h_separation", 10)
	pad.add_theme_constant_override("v_separation", 8)
	pad.position = Vector2(PAD.x / 2.0 - 160.0, 70)
	_zone.add_child(pad)
	for key in ["1", "2", "3", "4", "5", "6", "7", "8", "9", "←", "0", "ok"]:
		var button := Button.new()
		button.text = "OK" if key == "ok" else key
		button.custom_minimum_size = Vector2(100, 48)
		button.focus_mode = Control.FOCUS_NONE
		button.add_theme_font_size_override("font_size", 28)
		var color := YELLOW if key == "ok" else (Color("#FFDCE4") if key == "←" else Color.WHITE)
		for state in ["normal", "hover", "pressed"]:
			button.add_theme_stylebox_override(state, _box(color if state == "normal" else color.darkened(0.06), BLUE, 2, 14))
		button.add_theme_color_override("font_color", BLUE)
		button.pressed.connect(func() -> void: _tap(key))
		pad.add_child(button)


func _build_field() -> void:
	_field = LineEdit.new()
	_field.position = Vector2(PAD.x / 2.0 - 230.0, 6)
	_field.size = Vector2(460, 64)
	_field.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_field.add_theme_font_size_override("font_size", 32)
	_field.add_theme_color_override("font_color", BLUE)
	_field.add_theme_stylebox_override("normal", _box(Color.WHITE, Color("#C8A27A"), 3, 16))
	_field.add_theme_stylebox_override("focus", _box(Color.WHITE, BLUE, 3, 16))
	_field.placeholder_text = "Écris ici"
	_field.text_submitted.connect(func(text: String) -> void: _verify(text))
	_zone.add_child(_field)
	_field.grab_focus()
	var ok := HBoxContainer.new()
	ok.position = Vector2(0, 86)
	ok.size = Vector2(PAD.x, 56)
	ok.alignment = BoxContainer.ALIGNMENT_CENTER
	_zone.add_child(ok)
	var button := _action(ok, "C'est ma réponse", func() -> void: _verify(_field.text))
	button.add_theme_stylebox_override("normal", _box(YELLOW, BLUE, 3, 16))


func _build_choices(options: Array) -> void:
	var list := VBoxContainer.new()
	list.position = Vector2(PAD.x / 2.0 - 230.0, 4)
	list.size = Vector2(460, 0)
	list.add_theme_constant_override("separation", 12)
	_zone.add_child(list)
	for option in options:
		var button := Button.new()
		button.text = str(option)
		button.custom_minimum_size = Vector2(460, 60)
		button.focus_mode = Control.FOCUS_NONE
		button.add_theme_font_size_override("font_size", 28)
		for state in ["normal", "hover", "pressed"]:
			button.add_theme_stylebox_override(state, _box(Color.WHITE if state == "normal" else Color("#FFF4C2"), BLUE, 2, 16))
		button.add_theme_color_override("font_color", BLUE)
		button.pressed.connect(func() -> void: _verify(str(option)))
		list.add_child(button)


# The white slate above the number pad, where the digits she taps show up.
func _slate() -> Label:
	var frame := Panel.new()
	frame.position = Vector2(PAD.x / 2.0 - 120.0, 4)
	frame.size = Vector2(240, 58)
	frame.add_theme_stylebox_override("panel", _box(Color.WHITE, Color("#C8A27A"), 3, 16))
	_zone.add_child(frame)
	var label := _text("", 34, BLUE, Vector2(0, 8), 240, frame)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label


# ── Odds and ends ───────────────────────────────────────────────

func _refresh_stars() -> void:
	for child in _stars.get_children():
		child.queue_free()
	var count := Homework.exercises().size()
	# Eight stars or thirty-five: they shrink so the whole week always fits across the page.
	var side := clampf((PAD.x - 160.0) / maxi(count, 1) - 4.0, 12.0, 34.0)
	_stars.add_theme_constant_override("separation", 4 if side < 30.0 else 6)
	for i in count:
		var star := _Star.new()
		star.kind = "done" if Homework.is_done(i) else ("now" if i == _index else "todo")
		star.custom_minimum_size = Vector2(side, side)
		_stars.add_child(star)


func _close() -> void:
	Voice.stop()
	remove_from_group("modal")
	Sfx.play("page")
	closed.emit()
	queue_free()


func _text(words: String, font_size: int, color: Color, at: Vector2, width: float, parent: Node = null) -> Label:
	var label := Label.new()
	label.text = words
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.position = at
	label.size = Vector2(width, font_size + 10)
	(parent if parent else _panel).add_child(label)
	return label


func _action(bar: BoxContainer, words: String, on_press: Callable) -> Button:
	var button := Button.new()
	button.text = words
	button.custom_minimum_size = Vector2(240, 52)
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 22)
	button.add_theme_color_override("font_color", BLUE)
	button.add_theme_stylebox_override("normal", _box(Color.WHITE, BLUE, 2, 16))
	button.add_theme_stylebox_override("hover", _box(Color("#FFF4C2"), BLUE, 2, 16))
	button.pressed.connect(on_press)
	bar.add_child(button)
	return button


func _box(bg: Color, border: Color, width: int, radius: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = bg
	box.border_color = border
	box.set_border_width_all(width)
	box.set_corner_radius_all(radius)
	box.content_margin_left = 12
	box.content_margin_right = 12
	return box


# A little loudspeaker on the yellow button.
func _draw_speaker() -> void:
	var c := Vector2(36, 36)
	_listen.draw_colored_polygon(PackedVector2Array([c + Vector2(-15, -6), c + Vector2(-8, -6), c + Vector2(1, -15),
		c + Vector2(1, 15), c + Vector2(-8, 6), c + Vector2(-15, 6)]), BLUE)
	_listen.draw_arc(c + Vector2(2, 0), 9, -0.9, 0.9, 10, BLUE, 3.0, true)
	_listen.draw_arc(c + Vector2(2, 0), 15, -0.9, 0.9, 12, BLUE, 3.0, true)


# ── The page and its stars ──────────────────────────────────────

# The ruled lines of a school exercise book, and the red margin down the left.
class _Lines:
	extends Control

	func _draw() -> void:
		var y := 136.0
		while y < size.y - 46.0:
			draw_line(Vector2(34, y), Vector2(size.x - 34, y), Color("#9FC0DE", 0.35), 1.5)
			y += 36.0
		draw_line(Vector2(76, 30), Vector2(76, size.y - 30), Color("#E58BA0", 0.5), 2.0)


# One star for each exercise: filled when she has it, hollow when it is still to do, ringed for the one she is on.
class _Star:
	extends Control

	var kind := "todo"

	func _draw() -> void:
		var c := size / 2.0
		var r: float = minf(size.x, size.y) * (0.46 if kind != "big" else 0.5)
		var points := PackedVector2Array()
		for i in 10:
			points.append(c + Vector2.from_angle(-PI / 2.0 + TAU * i / 10.0) * (r if i % 2 == 0 else r * 0.46))
		if kind == "now":
			draw_circle(c, r * 1.18, Color("#1D4F91", 0.12))
		var filled := kind == "done" or kind == "big"
		draw_colored_polygon(points, Color("#FFD23F") if filled else Color("#FFFDF7"))
		points.append(points[0])
		draw_polyline(points, Color("#1D4F91", 0.85 if filled else 0.45), 2.5 if kind != "big" else 4.0, true)


# Confetti falling over the finished page, with her own little drawings bobbing along the bottom.
class _Party:
	extends Control

	var _t := 0.0
	var _bits: Array[Dictionary] = []
	var _rng := RandomNumberGenerator.new()

	func _ready() -> void:
		_rng.seed = 7
		var colors := ["#FFD23F", "#E04F5F", "#4FA3E0", "#7CCB5A", "#F7A9C4", "#B388EB"]
		for i in 80:
			_bits.append({
				"x": _rng.randf_range(10.0, 990.0), "y": _rng.randf_range(0.0, 420.0),
				"fall": _rng.randf_range(34.0, 96.0), "sway": _rng.randf_range(0.6, 1.8),
				"spin": _rng.randf_range(-3.0, 3.0), "r": _rng.randf_range(4.0, 8.0),
				"color": Color(colors[i % colors.size()]),
			})

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		for bit: Dictionary in _bits:
			var y: float = fmod(float(bit.y) + _t * float(bit.fall), size.y)
			var x: float = float(bit.x) + sin(_t * float(bit.sway) + float(bit.x)) * 12.0
			var a := float(bit.spin) * _t
			var r: float = bit.r
			var square := PackedVector2Array()
			for k in 4:
				square.append(Vector2(x, y) + Vector2.from_angle(a + PI / 4.0 + TAU * k / 4.0) * r)
			draw_colored_polygon(square, bit.color)
		# Her own drawings, bobbing: a star, her self-portrait, hearts, the sun and the capybara. The same seed
		# every frame, so the wax crayon's wobble stays where it was drawn instead of shivering.
		# They keep out of the middle of the page, where the words are.
		_rng.seed = 11
		var bob := sin(_t * 2.0) * 5.0
		CuteArt.star(self, Vector2(112.0, 58.0 + bob), 44.0, Color("#FFD23F"), true, _rng)
		CuteArt.star(self, Vector2(888.0, 58.0 - bob), 44.0, Color("#FFD23F"), true, _rng)
		CuteArt.sun(self, Vector2(884.0, 196.0 + bob), 34.0, true, _rng)
		CuteArt.flower(self, Vector2(112.0, 198.0 - bob), 30.0, Color("#F7A9C4"), true, _rng)
		CuteArt.me(self, Vector2(158.0, 322.0 - bob), 52.0, true, _rng)
		CuteArt.capybara(self, Vector2(846.0, 330.0 + bob), 46.0, true, _rng)
		CuteArt.heart(self, Vector2(282.0, 248.0 + bob * 1.4), 20.0, Color("#E04F5F"), true, _rng)
		CuteArt.heart(self, Vector2(718.0, 244.0 - bob * 1.4), 20.0, Color("#E04F5F"), true, _rng)
