class_name BraceletStudio
extends CanvasLayer
## Knotting a friendship bracelet at her desk (Julien: "les bracelets d'amitié avec ses amis"). The threads are pinned to her knee
## with a safety pin, as kids do, and she goes step by step:
##   1. Les fils: two to six colours of embroidery thread;
##   2. Le motif: chevrons, stripes, diamonds or checks (`BraceletArt.PATTERNS`), shown on a sample;
##   3. Les nœuds: each click ties a row of knots (or she holds the button down), `BraceletArt.ROWS` rows to the end;
##   4. Les breloques: letter beads for a word (a friend's name, quick buttons for each) and a charm at the end;
##   5. Pour qui ?: a friend she has met, or herself.
## `closed` gives {data, for} (the friend's id or "moi"), or {} if she stopped.

signal closed(result: Dictionary)

const BLUE := Color("#1D4F91")
const YELLOW := Color("#FFD23F")
const CREAM := Color("#F6EFE4")
const STEPS := [["fils", "Les fils"], ["motif", "Le motif"], ["noeuds", "Les nœuds"], ["breloques", "Les breloques"], ["qui", "Pour qui ?"]]
const STAGE_POS := Vector2(24, 96)
const STAGE_SIZE := Vector2(560, 540)
const TOP := Vector2(280, 92)
const MAX_COLORS := 6
const TIE_EVERY := 0.13

var _root: Control
var _panel: Panel
var _stage: _Stage
var _side: VBoxContainer
var _chips: HBoxContainer
var _next: Button
var _back: Button
var _step := "fils"
var _data := {"colors": ["#E04F5F", "#FFD23F", "#4FA3E0"], "pattern": "chevrons", "word": "", "charm": ""}
var _rows := 0
var _pop := 1.0
var _holding := false
var _tie_timer := 0.0
var _word_edit: LineEdit
var _counter: Label
var _time := 0.0


func _init() -> void:
	layer = 60


func _ready() -> void:
	add_to_group("modal")
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_root)
	var dim := ColorRect.new()
	dim.color = Color(0.08, 0.05, 0.12, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(dim)
	_panel = Panel.new()
	_panel.position = Vector2(20, 12)
	_panel.size = Vector2(1240, 696)
	_panel.add_theme_stylebox_override("panel", _box(CREAM, BLUE, 6, 26))
	_root.add_child(_panel)
	var title := _label("Un bracelet d'amitié", 32, BLUE)
	title.position = Vector2(0, 10)
	title.size = Vector2(1240, 44)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_panel.add_child(title)
	_chips = HBoxContainer.new()
	_chips.position = Vector2(24, 58)
	_chips.add_theme_constant_override("separation", 6)
	_panel.add_child(_chips)
	var frame := Panel.new()
	frame.position = STAGE_POS - Vector2(6, 6)
	frame.size = STAGE_SIZE + Vector2(12, 12)
	frame.add_theme_stylebox_override("panel", _box(Color("#E9DFCB"), Color("#C8A27A"), 5, 12))
	_panel.add_child(frame)
	_stage = _Stage.new()
	_stage.studio = self
	_stage.position = STAGE_POS
	_stage.size = STAGE_SIZE
	_stage.clip_contents = true
	_stage.mouse_filter = Control.MOUSE_FILTER_STOP
	_panel.add_child(_stage)
	_side = VBoxContainer.new()
	_side.position = Vector2(612, 96)
	_side.size = Vector2(604, 530)
	_side.add_theme_constant_override("separation", 12)
	_panel.add_child(_side)
	var stop := _button("Arrêter", 19, _quit, Vector2(110, 44))
	stop.position = Vector2(612, 642)
	_panel.add_child(stop)
	_back = _button("←  Retour", 19, _go_back, Vector2(130, 44))
	_back.position = Vector2(734, 642)
	_panel.add_child(_back)
	_next = _button("Suivant  →", 22, _go_next, Vector2(200, 46))
	_next.position = Vector2(1016, 640)
	_next.add_theme_stylebox_override("normal", _box(YELLOW, BLUE, 3, 16))
	_panel.add_child(_next)
	_set_step("fils")


func _process(delta: float) -> void:
	_time += delta
	if _holding and _step == "noeuds":
		_tie_timer -= delta
		if _tie_timer <= 0.0:
			_tie()
			_tie_timer = TIE_EVERY
	_stage.queue_redraw()


# ── Steps ───────────────────────────────────────────────────────

func _set_step(id: String) -> void:
	_step = id
	_holding = false
	for c in _chips.get_children():
		c.queue_free()
	var reached := true
	for st: Array in STEPS:
		var on: bool = st[0] == id
		var chip := _label(("✓ " if reached and not on else "") + str(st[1]), 17, BLUE if on else Color(BLUE, 0.5))
		chip.add_theme_stylebox_override("normal", _box(YELLOW if on else Color.WHITE, Color(BLUE, 0.6 if on else 0.25), 2, 12))
		_chips.add_child(chip)
		if on:
			reached = false
	for c in _side.get_children():
		_side.remove_child(c)
		c.queue_free()
	_word_edit = null
	_counter = null
	match id:
		"fils":
			_fils_side()
		"motif":
			_motif_side()
		"noeuds":
			_noeuds_side()
		"breloques":
			_breloques_side()
		"qui":
			_qui_side()
	_update_buttons()


func _update_buttons() -> void:
	_back.visible = _step != "fils"
	_next.visible = _step != "qui"
	match _step:
		"fils":
			_next.disabled = (_data.colors as Array).size() < 2
		"noeuds":
			_next.disabled = _rows < BraceletArt.ROWS
		_:
			_next.disabled = false


func _go_next() -> void:
	var order := STEPS.map(func(s: Array) -> String: return s[0])
	var i := order.find(_step)
	if i < order.size() - 1:
		Sfx.play("click")
		_set_step(order[i + 1])


func _go_back() -> void:
	var order := STEPS.map(func(s: Array) -> String: return s[0])
	var i := order.find(_step)
	if i > 0:
		Sfx.play("click")
		_set_step(order[i - 1])


func _fils_side() -> void:
	_heading("Choisis tes fils")
	_text("Clique sur les couleurs de fil à broder que tu veux : de 2 à 6. Clique encore pour en enlever une.")
	var grid := GridContainer.new()
	grid.columns = 6
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	_side.add_child(grid)
	var chosen: Array = _data.colors
	for hex: String in BraceletArt.PALETTE:
		var col := Color(hex)
		var on := hex in chosen
		var b := Button.new()
		b.custom_minimum_size = Vector2(82, 56)
		b.text = str(chosen.find(hex) + 1) if on else ""
		b.add_theme_font_size_override("font_size", 22)
		var ink := Color.WHITE if col.get_luminance() < 0.6 else BLUE
		for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
			b.add_theme_color_override(c, ink)
		b.add_theme_stylebox_override("normal", _box(col, YELLOW if on else col.darkened(0.3), 6 if on else 2, 14))
		b.add_theme_stylebox_override("hover", _box(col.lightened(0.1), BLUE, 3, 14))
		b.add_theme_stylebox_override("focus", _box(col, YELLOW if on else col.darkened(0.3), 6 if on else 2, 14))
		b.pressed.connect(func() -> void:
			if hex in chosen:
				chosen.erase(hex)
			elif chosen.size() < MAX_COLORS:
				chosen.append(hex)
			else:
				return
			Sfx.play("pop")
			_rows = 0
			_set_step("fils"))
		grid.add_child(b)
	_text("%d fil%s choisi%s." % [chosen.size(), "s" if chosen.size() > 1 else "", "s" if chosen.size() > 1 else ""])


func _motif_side() -> void:
	_heading("Le motif")
	_text("Comment tes fils vont se croiser ? Regarde l'exemple à gauche.")
	var row := HFlowContainer.new()
	row.add_theme_constant_override("h_separation", 10)
	row.add_theme_constant_override("v_separation", 10)
	_side.add_child(row)
	for p: Array in BraceletArt.PATTERNS:
		row.add_child(_toggle(str(p[1]), p[0] == _data.pattern, func() -> void:
			_data.pattern = str(p[0])
			_rows = 0
			_set_step("motif"), Vector2(170, 56), 21))


func _noeuds_side() -> void:
	_heading("Les nœuds")
	_text("Clique sur ton bracelet pour faire une rangée de nœuds. Garde le bouton enfoncé pour aller plus vite !")
	_counter = _label("", 26, BLUE)
	_side.add_child(_counter)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	_side.add_child(row)
	row.add_child(_button("Faire un nœud", 21, _tie, Vector2(220, 56)))
	row.add_child(_button("Défaire", 19, func() -> void:
		if _rows > 0:
			_rows -= 1
			Sfx.play("swoosh")
			_update_counter(), Vector2(140, 56)))
	_update_counter()


func _update_counter() -> void:
	if _counter:
		_counter.text = "%d rangées sur %d" % [_rows, BraceletArt.ROWS] if _rows < BraceletArt.ROWS else "Ton bracelet est tressé !"
	_update_buttons()


func _tie() -> void:
	if _rows >= BraceletArt.ROWS:
		_holding = false
		return
	_rows += 1
	_pop = 0.4
	var tw := create_tween()
	tw.tween_property(self, "_pop", 1.0, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	Sfx.play("pop", Vector2.INF, -10.0, 1.2 + 0.4 * randf())
	if _rows == BraceletArt.ROWS:
		Sfx.play("chime")
	_update_counter()


func _breloques_side() -> void:
	_heading("Les breloques")
	_text("Des perles avec des lettres : écris un nom ou un petit mot (8 lettres au plus).")
	_word_edit = LineEdit.new()
	_word_edit.max_length = 8
	_word_edit.text = _data.word
	_word_edit.placeholder_text = "AMIES"
	_word_edit.custom_minimum_size = Vector2(300, 52)
	_word_edit.add_theme_font_size_override("font_size", 26)
	_word_edit.add_theme_color_override("font_color", BLUE)
	_word_edit.add_theme_color_override("font_placeholder_color", Color(BLUE, 0.35))
	_word_edit.add_theme_stylebox_override("normal", _box(Color.WHITE, BLUE, 3, 12))
	_word_edit.add_theme_stylebox_override("focus", _box(Color("#FFFBE8"), Color("#E86BB0"), 3, 12))
	_word_edit.text_changed.connect(func(t: String) -> void:
		_data.word = _letters(t))
	_side.add_child(_word_edit)
	var names := HFlowContainer.new()
	names.add_theme_constant_override("h_separation", 8)
	names.add_theme_constant_override("v_separation", 8)
	_side.add_child(names)
	var quick: Array = ["AMIES", "BFF", "♥"]
	for f: Array in FriendBracelet.friends():
		quick.append(str(f[1]))
	for q: String in quick:
		names.add_child(_button(q, 17, func() -> void:
			_data.word = _letters(q)
			_word_edit.text = _data.word
			Sfx.play("pop"), Vector2(0, 40)))
	_side.add_child(_label("Une breloque au bout ?", 21, BLUE))
	var charms := HFlowContainer.new()
	charms.add_theme_constant_override("h_separation", 8)
	charms.add_theme_constant_override("v_separation", 8)
	_side.add_child(charms)
	for c: Array in BraceletArt.CHARMS:
		charms.add_child(_toggle(str(c[1]), c[0] == _data.charm, func() -> void:
			_data.charm = str(c[0])
			_set_step("breloques"), Vector2(110, 44), 18))


# Capitals without accents (the beads have no accents), and the heart as a letter of its own.
func _letters(t: String) -> String:
	var out := ""
	var plain := {"É": "E", "È": "E", "Ê": "E", "À": "A", "Â": "A", "Ç": "C", "Î": "I", "Ô": "O", "Û": "U", "Ù": "U", "Ë": "E", "Ï": "I"}
	for ch in t.to_upper():
		ch = plain.get(ch, ch)
		if (ch >= "A" and ch <= "Z") or ch == "♥":
			out += ch
	return out.substr(0, 8)


func _qui_side() -> void:
	_heading("Pour qui ?")
	_text("À qui veux-tu le donner ? Tu le lui donneras la prochaine fois que tu la vois. Ou garde-le pour toi !")
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	_side.add_child(grid)
	for f: Array in FriendBracelet.friends():
		var note := " (a déjà le tien)" if not FriendBracelet.given(str(f[0])).is_empty() else ""
		var b := _button(str(f[1]) + note, 21, _finish.bind(str(f[0])), Vector2(290, 60))
		b.add_theme_stylebox_override("normal", _box(Color("#FFE9F2"), Color("#E86BB0"), 3, 16))
		grid.add_child(b)
	var me := _button("Pour moi !", 21, _finish.bind("moi"), Vector2(290, 60))
	me.add_theme_stylebox_override("normal", _box(YELLOW, BLUE, 3, 16))
	grid.add_child(me)


func _finish(who: String) -> void:
	Sfx.play("chime")
	closed.emit({"data": _data.duplicate(true), "for": who})
	queue_free()


func _quit() -> void:
	closed.emit({})
	queue_free()


# ── The stage ───────────────────────────────────────────────────

func stage_input(event: InputEvent) -> void:
	if _step != "noeuds":
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_holding = event.pressed
		if event.pressed:
			_tie()
			_tie_timer = TIE_EVERY * 2.5


func paint_stage(ci: Control) -> void:
	# Her knee in jeans: denim with its twill and a seam.
	ci.draw_rect(Rect2(Vector2.ZERO, STAGE_SIZE), Color("#4F78B0"))
	for k in 90:
		var x := -STAGE_SIZE.y + k * 12.0
		ci.draw_line(Vector2(x, STAGE_SIZE.y), Vector2(x + STAGE_SIZE.y, 0), Color(1, 1, 1, 0.05), 2.0)
	ci.draw_line(Vector2(70, 0), Vector2(46, STAGE_SIZE.y), Color("#3B5E8E"), 6.0)
	for k in 30:
		ci.draw_line(Vector2(76 - k * 0.8, k * 18.0 + 4.0), Vector2(75 - k * 0.8, k * 18.0 + 12.0), Color("#E8B04A"), 2.0)
	ci.draw_circle(Vector2(STAGE_SIZE.x / 2.0 + 20.0, 300), 210.0, Color(1, 1, 1, 0.05))
	var top := TOP
	if _step == "fils" or _step == "motif":
		# The threads alone, then a sample of the pattern beside them.
		BraceletArt.draw_strip(ci, top, _data, 0, 1.0, 380.0)
		if _step == "motif":
			_paint_sample(ci)
	elif _step == "qui":
		BraceletArt.draw_loop(ci, Vector2(STAGE_SIZE.x / 2.0, 250), _data, 1.5)
	else:
		var hang := 420.0 - _rows * BraceletArt.PITCH
		BraceletArt.draw_strip(ci, top, _data, _rows, 1.0, maxf(40.0, hang), _pop)
		if _step == "breloques" and _rows > 0:
			BraceletArt.draw_beads(ci, top, str(_data.word), 1.0, 10)
			BraceletArt.draw_charm(ci, top + Vector2(0, _rows * BraceletArt.PITCH + 34.0), str(_data.charm), 30.0)
	_paint_pin(ci, top + Vector2(0, -26))
	if _step == "noeuds" and _rows < BraceletArt.ROWS:
		# Where the next row goes.
		var y := top.y + _rows * BraceletArt.PITCH
		var wobble := 3.0 * sin(_time * 6.0)
		ci.draw_string(ThemeDB.fallback_font, Vector2(top.x + 62.0 + wobble, y + 8.0), "← clique !", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, YELLOW)


# A sample of the pattern on the right of the threads.
func _paint_sample(ci: Control) -> void:
	var at := Vector2(STAGE_SIZE.x - 110.0, 110.0)
	ci.draw_rect(Rect2(at - Vector2(64, 40), Vector2(128, 330)), Color(1, 1, 1, 0.85))
	ci.draw_rect(Rect2(at - Vector2(64, 40), Vector2(128, 330)), BLUE, false, 2.0)
	ci.draw_string(ThemeDB.fallback_font, at + Vector2(-50, -16), "Exemple", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, BLUE)
	BraceletArt.draw_strip(ci, at + Vector2(0, 6), _data, 24, 0.9, 0.0)


# The safety pin holding the threads to her knee, and the knot that ties them together.
func _paint_pin(ci: Control, at: Vector2) -> void:
	ci.draw_circle(at + Vector2(0, 14), 11.0, Color("#E8D9B5"))
	ci.draw_circle(at + Vector2(0, 14), 11.0, Color(0.3, 0.2, 0.1, 0.2))
	var steel := Color("#C9CED6")
	var dark := Color("#7D838C")
	ci.draw_line(at + Vector2(-80, 0), at + Vector2(70, 0), dark, 6.0, true)
	ci.draw_line(at + Vector2(-80, 0), at + Vector2(70, 0), steel, 3.5, true)
	ci.draw_line(at + Vector2(-80, 10), at + Vector2(64, 4), dark, 6.0, true)
	ci.draw_line(at + Vector2(-80, 10), at + Vector2(64, 4), steel, 3.5, true)
	ci.draw_arc(at + Vector2(-80, 5), 5.0, PI / 2.0, PI * 1.5, 10, steel, 3.5, true)
	ci.draw_rect(Rect2(at + Vector2(62, -7), Vector2(18, 14)), dark)
	ci.draw_rect(Rect2(at + Vector2(63, -6), Vector2(16, 12)), steel)
	ci.draw_line(at + Vector2(-60, -1), at + Vector2(40, -1), Color(1, 1, 1, 0.7), 1.2)


# ── Little builders ─────────────────────────────────────────────

func _heading(text: String) -> void:
	_side.add_child(_label(text, 30, BLUE))


func _text(text: String) -> void:
	var l := _label(text, 19, Color(BLUE, 0.85))
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(590, 0)
	_side.add_child(l)


func _toggle(text: String, on: bool, press: Callable, size: Vector2, font := 17) -> Button:
	var b := _button(text, font, func() -> void:
		Sfx.play("click")
		press.call(), size)
	if on:
		b.add_theme_stylebox_override("normal", _box(YELLOW, BLUE, 3, 14))
		b.add_theme_stylebox_override("focus", _box(YELLOW, BLUE, 3, 14))
	return b


func _label(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


func _button(text: String, size: int, on_press: Callable, min_size := Vector2(120, 46)) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = min_size
	b.add_theme_font_size_override("font_size", size)
	b.add_theme_color_override("font_color", BLUE)
	b.add_theme_color_override("font_disabled_color", Color(BLUE, 0.35))
	b.add_theme_stylebox_override("normal", _box(Color.WHITE, BLUE, 2, 14))
	b.add_theme_stylebox_override("hover", _box(Color("#FFF4C2"), BLUE, 2, 14))
	b.add_theme_stylebox_override("disabled", _box(Color(1, 1, 1, 0.5), Color(BLUE, 0.3), 2, 14))
	b.pressed.connect(on_press)
	return b


func _box(bg: Color, border: Color, width: int, radius: int) -> StyleBoxFlat:
	var b := StyleBoxFlat.new()
	b.bg_color = bg
	b.border_color = border
	b.set_border_width_all(width)
	b.set_corner_radius_all(radius)
	b.content_margin_left = 12
	b.content_margin_right = 12
	return b


class _Stage:
	extends Control

	var studio: BraceletStudio

	func _draw() -> void:
		studio.paint_stage(self)

	func _gui_input(event: InputEvent) -> void:
		studio.stage_input(event)
