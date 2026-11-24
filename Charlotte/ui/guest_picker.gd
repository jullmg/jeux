class_name GuestPicker
extends CanvasLayer
## The friends she invites to an evening (the movie night): one card with a tick box per friend she has met, up to `max_guests`.
##   GuestPicker.ask(self, "Qui veux-tu inviter ?", [["alphee", "Alphée"], …], 4)
## then `picked(ids)` (an empty array when she closes it). In the "modal" group like `ChoiceCard`.

signal picked(ids: Array)

const BLUE := Color("#1D4F91")
const YELLOW := Color("#FFD23F")
const CREAM := Color("#FBF6EA")
const TINTS := [Color("#8FCBF2"), Color("#FFD866"), Color("#B8E986"), Color("#F7A9C4"), Color("#C9B8F2"), Color("#FFB98A")]

var question := ""
var friends: Array = []
var max_guests := 4
var _ticked: Array[bool] = []
var _buttons: Array[Button] = []
var _go: Button
var _count: Label


static func ask(parent: Node, question_text: String, who: Array, limit := 4) -> GuestPicker:
	var picker := GuestPicker.new()
	picker.question = question_text
	picker.friends = who
	picker.max_guests = limit
	parent.add_child(picker)
	return picker


func _init() -> void:
	layer = 62


func _ready() -> void:
	add_to_group("modal")
	var dim := ColorRect.new()
	dim.color = Color(0.05, 0.08, 0.2, 0.45)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed:
			_close([]))
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", _box(CREAM, BLUE, 5, 24, 26))
	center.add_child(card)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	card.add_child(box)
	var title := Label.new()
	title.text = question
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", BLUE)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	_count = Label.new()
	_count.add_theme_font_size_override("font_size", 18)
	_count.add_theme_color_override("font_color", Color("#6A6A78"))
	_count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_count)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 10)
	box.add_child(grid)
	for i in friends.size():
		_ticked.append(false)
		var b := Button.new()
		b.custom_minimum_size = Vector2(250, 60)
		b.focus_mode = Control.FOCUS_NONE
		b.add_theme_font_size_override("font_size", 24)
		b.add_theme_color_override("font_color", BLUE)
		b.add_theme_color_override("font_hover_color", BLUE)
		b.add_theme_color_override("font_pressed_color", BLUE)
		b.pressed.connect(_toggle.bind(i))
		grid.add_child(b)
		_buttons.append(b)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 14)
	box.add_child(row)
	var later := Button.new()
	later.text = "Plus tard"
	later.custom_minimum_size = Vector2(160, 56)
	later.focus_mode = Control.FOCUS_NONE
	later.add_theme_font_size_override("font_size", 22)
	later.add_theme_stylebox_override("normal", _box(Color("#DDE6F0"), BLUE, 3, 18, 8))
	later.add_theme_stylebox_override("hover", _box(Color("#EAF0F8"), BLUE, 3, 18, 8))
	later.add_theme_color_override("font_color", BLUE)
	later.pressed.connect(func() -> void: _close([]))
	row.add_child(later)
	_go = Button.new()
	_go.text = "On les invite !"
	_go.custom_minimum_size = Vector2(240, 56)
	_go.focus_mode = Control.FOCUS_NONE
	_go.add_theme_font_size_override("font_size", 24)
	_go.add_theme_color_override("font_color", BLUE)
	_go.add_theme_color_override("font_disabled_color", Color("#9AA4B0"))
	_go.add_theme_stylebox_override("normal", _box(YELLOW, BLUE, 3, 18, 8))
	_go.add_theme_stylebox_override("hover", _box(Color("#FFE27A"), BLUE, 3, 18, 8))
	_go.add_theme_stylebox_override("disabled", _box(Color("#EDEFF2"), Color("#9AA4B0"), 3, 18, 8))
	_go.pressed.connect(func() -> void:
		var ids: Array = []
		for i in friends.size():
			if _ticked[i]:
				ids.append(friends[i][0])
		_close(ids))
	row.add_child(_go)
	_refresh()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_close([])


func _toggle(i: int) -> void:
	if not _ticked[i] and _ticked.count(true) >= max_guests:
		Sfx.play("squeak")
		return
	_ticked[i] = not _ticked[i]
	Sfx.play("click")
	_refresh()


func _refresh() -> void:
	var n := _ticked.count(true)
	_count.text = "Coche tes amis (jusqu'à %d) : %d choisi%s" % [max_guests, n, "s" if n > 1 else ""]
	_go.disabled = n == 0
	for i in _buttons.size():
		var on := _ticked[i]
		var tint: Color = TINTS[i % TINTS.size()]
		_buttons[i].text = ("☑  " if on else "☐  ") + str(friends[i][1])
		_buttons[i].add_theme_stylebox_override("normal", _box(tint if on else Color.WHITE, BLUE, 4 if on else 3, 16, 8))
		_buttons[i].add_theme_stylebox_override("hover", _box(tint.lightened(0.2), BLUE, 4, 16, 8))
		_buttons[i].add_theme_stylebox_override("pressed", _box(tint, BLUE, 4, 16, 8))


func _close(ids: Array) -> void:
	if is_queued_for_deletion():
		return
	picked.emit(ids)
	queue_free()


func _box(fill: Color, border: Color, width: int, radius: int, margin: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = fill
	s.border_color = border
	s.set_border_width_all(width)
	s.set_corner_radius_all(radius)
	s.set_content_margin_all(margin)
	return s
