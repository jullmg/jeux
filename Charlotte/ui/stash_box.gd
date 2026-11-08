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
	panel.position = Vector2(240, 35)
	panel.size = Vector2(800, 650)
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
	column.add_theme_constant_override("separation", 12)
	panel.add_child(column)
	column.add_child(_label("Ma cachette à cochonneries", 34, BLUE))
	var box := Stash.all()
	if box.is_empty():
		column.add_child(_label("Il reste plus rien là-dedans…", 24, INK))
	else:
		column.add_child(_label("Chut ! Personne le sait.", 20, Color("#7E7668")))
		# Two to a row (like the haul screen's cards), or five full-width rows with their own buttons would run
		# off the bottom of the window.
		var grid := GridContainer.new()
		grid.columns = 2
		grid.add_theme_constant_override("h_separation", 18)
		grid.add_theme_constant_override("v_separation", 14)
		column.add_child(grid)
		for kind: String in Halloween.KINDS:
			var n: int = int(box.get(kind, 0))
			if n == 0:
				continue
			grid.add_child(_row(kind, n))
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


# One kind in the box, on its own little card: its drawing (set down with a bit of a tilt, like the haul screen's),
# how many are left, and the button to eat one underneath.
func _row(kind: String, n: int) -> Control:
	var card := PanelContainer.new()
	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color("#FFF8E8")
	card_style.border_color = Color(CARDBOARD, 0.5)
	card_style.set_border_width_all(2)
	card_style.set_corner_radius_all(16)
	card_style.set_content_margin_all(10)
	card.add_theme_stylebox_override("panel", card_style)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	card.add_child(column)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 12)
	column.add_child(top)
	var icon_box := Control.new()
	icon_box.custom_minimum_size = Vector2(76, 76)
	var pic := CandyIcon.new()
	pic.kind = kind
	pic.size = Vector2(68, 68)
	pic.position = (icon_box.custom_minimum_size - pic.size) / 2.0
	pic.scale_factor = 1.12
	pic.tilt = (float(hash(kind) % 100) / 100.0 - 0.5) * 0.3
	icon_box.add_child(pic)
	top.add_child(icon_box)
	var words := _label("%s\n×  %d" % [Halloween.KIND_NAMES[kind], n], 20, INK)
	words.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	words.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	words.custom_minimum_size = Vector2(190, 0)
	top.add_child(words)
	var eat := _button("Miam !", YELLOW, func() -> void:
		if Stash.take(kind):
			_eaten = kind
		_close(), Vector2(0, 44))
	eat.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_child(eat)
	return card


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
