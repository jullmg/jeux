class_name StashBox
extends CanvasLayer
## The shoebox of junk food Charlotte keeps under her bed, opened: every kind she has hidden, how many of each, and
## a "Miam !" to eat one. `scenes/house.gd` opens it when she pulls the box out; `world/stash.gd` holds what is in it.

## The kind she chose to eat, or "" when she just closed the lid again.
signal closed(eaten: String)

const BLUE := Color("#1D4F91")
const YELLOW := Color("#FFD23F")
const CREAM := Color("#FBF6EA")
const INK := Color("#3A3A48")
const CARDBOARD := Color("#C9A06A")

var _eaten := ""


func _init() -> void:
	layer = 64


func _ready() -> void:
	add_to_group("modal")
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	var dim := ColorRect.new()
	dim.color = Color(0.05, 0.03, 0.12, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(dim)
	var panel := PanelContainer.new()
	panel.position = Vector2(290, 90)
	panel.size = Vector2(700, 540)
	var style := StyleBoxFlat.new()
	style.bg_color = CREAM
	style.border_color = CARDBOARD
	style.set_border_width_all(6)
	style.set_corner_radius_all(26)
	style.set_content_margin_all(22)
	style.shadow_color = Color(0, 0, 0, 0.3)
	style.shadow_size = 10
	panel.add_theme_stylebox_override("panel", style)
	root.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	panel.add_child(column)
	column.add_child(_label("Ma cachette à cochonneries", 34, BLUE))
	var box := Stash.all()
	if box.is_empty():
		column.add_child(_label("Il reste plus rien là-dedans…", 24, INK))
	else:
		column.add_child(_label("Chut ! Personne le sait.", 20, Color("#7E7668")))
		for kind: String in Halloween.KINDS:
			var n: int = int(box.get(kind, 0))
			if n == 0:
				continue
			column.add_child(_row(kind, n))
	var bar := HBoxContainer.new()
	bar.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_child(bar)
	bar.add_child(_button("Refermer la boîte", Color("#E8DDD0"), _close))
	root.modulate.a = 0.0
	create_tween().tween_property(root, "modulate:a", 1.0, 0.25)
	Sfx.play("pop")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_close()


# One kind in the box: its drawing, how many are left, and the button to eat one.
func _row(kind: String, n: int) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	var pic := CandyIcon.new()
	pic.kind = kind
	pic.custom_minimum_size = Vector2(72, 72)
	row.add_child(pic)
	var words := _label("%s  ×  %d" % [Halloween.KIND_NAMES[kind], n], 26, INK)
	words.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	words.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	words.custom_minimum_size = Vector2(330, 0)
	row.add_child(words)
	row.add_child(_button("Miam !", YELLOW, func() -> void:
		if Stash.take(kind):
			_eaten = kind
		_close(), Vector2(150, 52)))
	return row


func _button(text: String, colour: Color, on_press: Callable, least := Vector2(260, 56)) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = least
	button.add_theme_font_size_override("font_size", 22)
	for state in ["normal", "hover", "pressed"]:
		var skin := StyleBoxFlat.new()
		skin.bg_color = colour if state == "normal" else colour.lightened(0.18)
		skin.border_color = BLUE
		skin.set_border_width_all(4)
		skin.set_corner_radius_all(16)
		skin.set_content_margin_all(8)
		button.add_theme_stylebox_override(state, skin)
	button.add_theme_color_override("font_color", BLUE)
	button.pressed.connect(on_press)
	return button


func _close() -> void:
	Sfx.play("click")
	closed.emit(_eaten)
	queue_free()


func _label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label
