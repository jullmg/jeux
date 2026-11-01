extends CanvasLayer
## Autoload "Notebook": Charlotte's little quest notebook. A button next to the mute button (or the N key) opens
## it: the quests she's on with a hint of where to go, the ones she's done with a yellow star, and a clue for
## each one still to discover; her age and pocket money at the top. It also pops up a note when a quest starts
## ("Nouvelle quête") or is done ("Quête réussie !"). Hidden on the title screen.

const BLUE := Color("#1D4F91")
const YELLOW := Color("#FFD23F")
const CREAM := Color("#FBF6EA")
const INK := Color("#3A3A48")
const PAGE := Vector2(760, 600)

var _button: Button
var _open := false
var _page: Control
var _list: VBoxContainer
var _header: Label
var _toasts: Array[Array] = []
var _toasting := false
var _wiggle := 0.0


func _ready() -> void:
	layer = 75
	process_mode = Node.PROCESS_MODE_ALWAYS
	_button = Button.new()
	_button.custom_minimum_size = Vector2(52, 52)
	_button.position = Vector2(1280 - 52 - 14 - 64, 14)
	_button.focus_mode = Control.FOCUS_NONE
	_button.tooltip_text = "Mon carnet (N)"
	for state in ["normal", "hover", "pressed"]:
		var box := StyleBoxFlat.new()
		box.bg_color = Color(1, 1, 1, 0.85 if state == "normal" else 1.0)
		box.border_color = BLUE
		box.set_border_width_all(3 if state != "normal" else 2)
		box.set_corner_radius_all(26)
		_button.add_theme_stylebox_override(state, box)
	_button.pressed.connect(toggle)
	_button.draw.connect(_draw_icon)
	add_child(_button)
	_build_page()


func _process(delta: float) -> void:
	var scene := get_tree().current_scene
	var shown := scene != null and not scene.scene_file_path.ends_with("intro.tscn") and not scene.scene_file_path.contains("/tools/")
	_button.visible = shown
	if not shown and _open:
		toggle()
	if _wiggle > 0.0:
		_wiggle = maxf(_wiggle - delta, 0.0)
		_button.pivot_offset = _button.size / 2.0
		_button.rotation = sin(_wiggle * 24.0) * 0.25 * _wiggle
		_button.queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	if event.keycode == KEY_N and _button.visible or event.keycode == KEY_ESCAPE and _open:
		get_viewport().set_input_as_handled()
		toggle()


func toggle() -> void:
	_open = not _open
	if _open:
		_fill()
	_page.visible = _open
	get_tree().paused = _open
	Sfx.play("page")


## Called by Quests when one starts ("start") or is done ("done"): a note slides down from the top.
func announce(what: String, id: String) -> void:
	_toasts.append([what, id])
	_wiggle = 1.2
	if not _toasting:
		_next_toast()


# ── The open notebook ───────────────────────────────────────

func _build_page() -> void:
	_page = Control.new()
	_page.size = Vector2(1280, 720)
	_page.visible = false
	add_child(_page)
	var dim := ColorRect.new()
	dim.color = Color(0.05, 0.08, 0.2, 0.45)
	dim.size = _page.size
	dim.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed:
			toggle())
	_page.add_child(dim)
	var paper := _Paper.new()
	paper.position = (_page.size - PAGE) / 2.0 + Vector2(0, 14)
	paper.size = PAGE
	_page.add_child(paper)
	var title := _label("Mon carnet", 38, BLUE)
	title.position = Vector2(92, 34)
	paper.add_child(title)
	_header = _label("", 19, INK)
	_header.position = Vector2(380, 40)
	_header.size = Vector2(PAGE.x - 380 - 40, 60)
	_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	paper.add_child(_header)
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(92, 108)
	scroll.size = Vector2(PAGE.x - 92 - 40, PAGE.y - 108 - 50)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	paper.add_child(scroll)
	_list = VBoxContainer.new()
	_list.custom_minimum_size.x = scroll.size.x - 14
	_list.add_theme_constant_override("separation", 10)
	scroll.add_child(_list)
	var close := _label("N ou clique à côté pour fermer", 14, Color(INK, 0.55))
	close.position = Vector2(92, PAGE.y - 40)
	paper.add_child(close)


func _fill() -> void:
	_header.text = "Charlotte, %d ans\nArgent de poche : %s" % [GameState.age, Quests.money_text(GameState.money)]
	for child in _list.get_children():
		child.queue_free()
	var on := Quests.ORDER.filter(func(id: String) -> bool: return Quests.active(id))
	var done := Quests.ORDER.filter(func(id: String) -> bool: return Quests.done(id))
	var next := Quests.ORDER.filter(func(id: String) -> bool: return Quests.available(id))
	var later := Quests.ORDER.size() - on.size() - done.size() - next.size()
	_section("En cours", on, "active", "title", "hint")
	_section("Réussies  ★ %d" % done.size(), done, "done", "title", "")
	_section("À découvrir", next, "unknown", "find", "")
	if later > 0:
		_list.add_child(_label("… et d'autres quand tu seras plus grande !", 17, Color(INK, 0.6)))
	if on.is_empty() and done.is_empty() and next.is_empty():
		_list.add_child(_label("Rien pour l'instant. Va jouer dehors !", 20, INK))


func _section(heading: String, ids: Array, kind: String, line: String, hint: String) -> void:
	if ids.is_empty():
		return
	var head := _label(heading, 22, BLUE)
	_list.add_child(head)
	for id in ids:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		var star := _Star.new()
		star.kind = kind
		star.custom_minimum_size = Vector2(34, 34)
		star.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		row.add_child(star)
		var words := VBoxContainer.new()
		words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		words.add_theme_constant_override("separation", 0)
		var text := _label(Quests.ALL[id][line], 20, INK if kind != "unknown" else Color(INK, 0.7))
		text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		words.add_child(text)
		if not hint.is_empty():
			var small := _label(Quests.ALL[id][hint], 16, Color(INK, 0.65))
			small.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			words.add_child(small)
		row.add_child(words)
		_list.add_child(row)


func _label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


# ── Notes: "Nouvelle quête" / "Quête réussie !" ─────────────

func _next_toast() -> void:
	if _toasts.is_empty():
		_toasting = false
		return
	_toasting = true
	var item: Array = _toasts.pop_front()
	var done: bool = item[0] == "done"
	var quest: Dictionary = Quests.ALL[item[1]]
	var box := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = CREAM
	style.border_color = YELLOW if done else BLUE
	style.set_border_width_all(4)
	style.set_corner_radius_all(14)
	style.set_content_margin_all(12)
	style.shadow_color = Color(0, 0, 0, 0.25)
	style.shadow_size = 6
	box.add_theme_stylebox_override("panel", style)
	var words := VBoxContainer.new()
	words.add_theme_constant_override("separation", 2)
	var head := _label("★  Quête réussie !" if done else "Nouvelle quête dans ton carnet", 22, BLUE)
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	words.add_child(head)
	var title := _label(quest.title, 18, INK)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	words.add_child(title)
	if done:
		var reward := _label("+ %s dans ta poche" % Quests.money_text(float(quest.reward)), 16, Color("#2E7D32"))
		reward.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		words.add_child(reward)
	box.add_child(words)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(box)
	box.reset_size()
	box.position = Vector2((1280 - box.size.x) / 2.0, -box.size.y - 10)
	Sfx.play("chime" if done else "page")
	var tween := box.create_tween()
	tween.tween_property(box, "position:y", 18.0, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_interval(3.2)
	tween.tween_property(box, "modulate:a", 0.0, 0.4)
	tween.tween_callback(func():
		box.queue_free()
		_next_toast())


# A little blue notebook with its spiral and a yellow star; the number of stars she has in the corner.
func _draw_icon() -> void:
	var c := Vector2(26, 26)
	_button.draw_rect(Rect2(c + Vector2(-11, -14), Vector2(22, 28)), BLUE)
	_button.draw_rect(Rect2(c + Vector2(-7, -11), Vector2(16, 22)), Color("#2C66B0"))
	for i in 4:
		_button.draw_circle(c + Vector2(-11, -9 + i * 6), 2.2, Color("#C9CED6"))
	_button.draw_colored_polygon(_Star.points(c + Vector2(1, 0), 7.5), YELLOW)
	var stars := Quests.stars()
	if stars > 0:
		var at := Vector2(44, 44)
		_button.draw_circle(at, 10, YELLOW)
		_button.draw_arc(at, 10, 0, TAU, 20, BLUE, 1.5, true)
		_button.draw_string(ThemeDB.fallback_font, at + Vector2(-10, 5), str(stars), HORIZONTAL_ALIGNMENT_CENTER, 20, 13, BLUE)


# The notebook's page: cream paper, blue rules, a red margin, spiral rings along the top.
class _Paper:
	extends Control

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		draw_rect(Rect2(r.position + Vector2(6, 8), r.size), Color(0, 0, 0, 0.22))
		draw_rect(r, CREAM)
		for y in range(104, int(size.y) - 30, 30):
			draw_line(Vector2(14, y), Vector2(size.x - 14, y), Color("#BFD3EA"), 1.5)
		draw_line(Vector2(74, 0), Vector2(74, size.y), Color("#E59A9A"), 2.0)
		for x in range(40, int(size.x) - 20, 36):
			draw_circle(Vector2(x, 2), 8, Color("#2B2B33"))
			draw_arc(Vector2(x, -8), 11, 0.3, PI - 0.3, 12, Color("#B9BEC6"), 4.0, true)
		draw_rect(r, Color("#D8CDB6"), false, 2.0)


# A star: yellow and filled when the quest is done, an outline while she's on it, a dotted "?" to discover.
class _Star:
	extends Control
	var kind := "active"

	static func points(c: Vector2, r: float) -> PackedVector2Array:
		var pts := PackedVector2Array()
		for i in 10:
			pts.append(c + Vector2.from_angle(-PI / 2.0 + TAU * i / 10.0) * (r if i % 2 == 0 else r * 0.45))
		return pts

	func _draw() -> void:
		var c := size / 2.0
		var pts := points(c, 16.0)
		var outline := pts.duplicate()
		outline.append(pts[0])
		match kind:
			"done":
				draw_colored_polygon(pts, YELLOW)
				draw_polyline(outline, Color("#C99A12"), 2.0, true)
			"active":
				draw_polyline(outline, BLUE, 2.5, true)
			_:
				draw_polyline(outline, Color(INK, 0.35), 1.5, true)
				draw_string(ThemeDB.fallback_font, c + Vector2(-8, 6), "?", HORIZONTAL_ALIGNMENT_CENTER, 16, 16, Color(INK, 0.5))
