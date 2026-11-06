class_name CandyCount
extends CanvasLayer
## The haul, counted on the kitchen table at the end of Halloween night: every kind of candy she picked up, how many of
## each, and the total. `scenes/house.gd` opens it when Maman asks to see the bag; closing it sends her to bed.

signal closed

const BLUE := Color("#1D4F91")
const YELLOW := Color("#FFD23F")
const CREAM := Color("#FBF6EA")
const INK := Color("#3A3A48")
const ORANGE := Color("#E8812E")


func _init() -> void:
	layer = 64


func _ready() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	var dim := ColorRect.new()
	dim.color = Color(0.05, 0.03, 0.12, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(dim)
	var panel := PanelContainer.new()
	panel.position = Vector2(230, 70)
	panel.size = Vector2(820, 580)
	var style := StyleBoxFlat.new()
	style.bg_color = CREAM
	style.border_color = ORANGE
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
	column.add_child(_label("Ma récolte d'Halloween", 36, BLUE))
	var counts := Halloween.counted()
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 40)
	grid.add_theme_constant_override("v_separation", 10)
	column.add_child(grid)
	for kind: String in Halloween.KINDS:
		var n: int = counts.get(kind, 0)
		if n == 0:
			continue
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 14)
		var pic := _Candy.new()
		pic.kind = kind
		pic.custom_minimum_size = Vector2(62, 62)
		row.add_child(pic)
		var words := _label("%s  ×  %d" % [Halloween.KIND_NAMES[kind], n], 26, INK)
		words.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row.add_child(words)
		grid.add_child(row)
	var total := Halloween.candy()
	column.add_child(_label("%d bonbons en tout !" % total, 34, Color("#2E7D32")))
	column.add_child(_label(_verdict(total), 22, INK))
	var bar := HBoxContainer.new()
	bar.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_child(bar)
	var sleep := Button.new()
	sleep.text = "Aller me coucher !"
	sleep.custom_minimum_size = Vector2(300, 60)
	sleep.add_theme_font_size_override("font_size", 24)
	for state in ["normal", "hover", "pressed"]:
		var box := StyleBoxFlat.new()
		box.bg_color = YELLOW if state == "normal" else Color("#FFDF72")
		box.border_color = BLUE
		box.set_border_width_all(4)
		box.set_corner_radius_all(18)
		box.set_content_margin_all(10)
		sleep.add_theme_stylebox_override(state, box)
	sleep.add_theme_color_override("font_color", BLUE)
	sleep.pressed.connect(_close)
	bar.add_child(sleep)
	root.modulate.a = 0.0
	create_tween().tween_property(root, "modulate:a", 1.0, 0.25)
	Sfx.play("chime")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_close()


func _verdict(total: int) -> String:
	if total >= 30:
		return "Wow ! Y'en a pour tout l'hiver !"
	if total >= 20:
		return "Une belle soirée, han ?"
	return "C'est déjà pas mal pour ce soir !"


func _close() -> void:
	Sfx.play("pop")
	closed.emit()
	queue_free()


func _label(text: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label


# One candy, drawn: a wrapped sweet, a lollipop, a chocolate bar, gum, or a little bag of chips.
class _Candy:
	extends Control
	var kind := "wrapped"

	func _draw() -> void:
		var c := size / 2.0
		match kind:
			"wrapped":
				draw_colored_polygon(PackedVector2Array([c + Vector2(-26, -4), c + Vector2(-14, -12), c + Vector2(-14, 12)]), Color("#E8542F"))
				draw_colored_polygon(PackedVector2Array([c + Vector2(26, -4), c + Vector2(14, -12), c + Vector2(14, 12)]), Color("#E8542F"))
				draw_circle(c, 15.0, Color("#F2C230"))
				draw_arc(c, 15.0, 0, TAU, 20, Color("#C9962E"), 2.0)
				draw_circle(c + Vector2(-5, -5), 5.0, Color(1, 1, 1, 0.6))
			"lollipop":
				draw_line(c + Vector2(0, 6), c + Vector2(0, 28), Color("#F4F1EA"), 5.0)
				draw_circle(c + Vector2(0, -4), 17.0, Color("#F7A8C4"))
				for i in 10:
					var a := TAU * i / 10.0
					draw_line(c + Vector2(0, -4), c + Vector2(0, -4) + Vector2.from_angle(a) * 17.0, Color("#FFFFFF", 0.7), 2.5)
				draw_arc(c + Vector2(0, -4), 17.0, 0, TAU, 24, Color("#C97A99"), 2.0)
			"chocolate":
				draw_rect(Rect2(c + Vector2(-24, -16), Vector2(48, 32)), Color("#6B3F22"))
				draw_rect(Rect2(c + Vector2(-24, -16), Vector2(48, 32)), Color("#4A2A14"), false, 2.0)
				for i in 3:
					draw_line(c + Vector2(-24 + (i + 1) * 12, -16), c + Vector2(-24 + (i + 1) * 12, 16), Color("#4A2A14"), 1.6)
				draw_line(c + Vector2(-24, 0), c + Vector2(24, 0), Color("#4A2A14"), 1.6)
				draw_rect(Rect2(c + Vector2(-24, -16), Vector2(20, 32)), Color("#C8202A"))
			"gum":
				draw_rect(Rect2(c + Vector2(-20, -12), Vector2(40, 24)), Color("#F4F1EA"))
				draw_rect(Rect2(c + Vector2(-20, -12), Vector2(40, 24)), Color("#B9B4AA"), false, 2.0)
				draw_rect(Rect2(c + Vector2(-20, -5), Vector2(40, 10)), Color("#4FA3E0"))
			"chips":
				draw_colored_polygon(PackedVector2Array([c + Vector2(-18, -18), c + Vector2(18, -18), c + Vector2(14, 18), c + Vector2(-14, 18)]), Color("#F2C230"))
				draw_rect(Rect2(c + Vector2(-18, -18), Vector2(36, 6)), Color("#C9962E"))
				draw_circle(c + Vector2(0, 2), 8.0, Color("#E8812E"))
