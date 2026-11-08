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
		pic.custom_minimum_size = Vector2(78, 78)
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


# One candy, drawn as a real little object and not as flat shapes: lit from the upper left, its own outline, a
# highlight where the light lands, a darker edge underneath and a soft shadow so it sits on the page.
class _Candy:
	extends Control
	var kind := "wrapped"

	# An oval (or a circle), turned by `turn` radians, as a polygon.
	func _oval(c: Vector2, r: Vector2, turn := 0.0, steps := 30) -> PackedVector2Array:
		var pts := PackedVector2Array()
		for i in steps:
			var a := TAU * float(i) / float(steps)
			pts.append(c + Vector2(cos(a) * r.x, sin(a) * r.y).rotated(turn))
		return pts

	# A shape with the light on it: the flat colour, a shade along the lower right, an outline, and the highlight.
	func _lit(pts: PackedVector2Array, fill: Color, line := 2.2) -> void:
		draw_colored_polygon(pts, fill)
		var loop := pts.duplicate()
		loop.append(pts[0])
		draw_polyline(loop, fill.darkened(0.42), line)

	# The soft shadow it casts on the paper.
	func _shadow(c: Vector2, rx: float) -> void:
		draw_colored_polygon(_oval(c, Vector2(rx, rx * 0.26)), Color(0.2, 0.14, 0.08, 0.16))

	func _draw() -> void:
		var c := size / 2.0
		match kind:
			"wrapped":
				# A sweet in its twisted wrapper: the two crimped ends, the golden body and its red stripe.
				_shadow(c + Vector2(0, 20), 24.0)
				for side in 2:
					var d := -1.0 if side == 0 else 1.0
					var tip := c + Vector2(d * 32.0, 0)
					var neck := c + Vector2(d * 15.0, 0)
					_lit(PackedVector2Array([neck + Vector2(0, -12), tip + Vector2(0, -13),
						tip + Vector2(-d * 3.0, 0), tip + Vector2(0, 13), neck + Vector2(0, 12)]), Color("#E8542F"))
					for k in 2:
						var y := -5.0 + k * 10.0
						draw_line(neck + Vector2(0, y), tip + Vector2(-d * 2.0, y * 1.1), Color("#B23A1C"), 1.4)
				_lit(_oval(c, Vector2(19, 16)), Color("#F2C230"))
				# The stripe wound round it, and the shine on the shoulder.
				draw_colored_polygon(_oval(c + Vector2(2, 1), Vector2(17, 4.4), -0.32), Color("#E8542F"))
				draw_colored_polygon(_oval(c + Vector2(-6, -6), Vector2(7, 4), -0.5), Color(1, 1, 1, 0.62))
			"lollipop":
				# A swirl lollipop on its paper stick, with the cellophane twisted at the top.
				_shadow(c + Vector2(0, 26), 16.0)
				draw_line(c + Vector2(0, 4), c + Vector2(0, 30), Color("#D8D2C4"), 7.0)
				draw_line(c + Vector2(-1, 4), c + Vector2(-1, 30), Color("#FBF7EC"), 3.5)
				var head := c + Vector2(0, -5)
				_lit(_oval(head, Vector2(19, 19)), Color("#FBF4E6"))
				# The spiral, wound out from the middle.
				var spiral := PackedVector2Array()
				var turns := 44
				for i in turns + 1:
					var tt := float(i) / float(turns)
					spiral.append(head + Vector2.from_angle(tt * TAU * 2.6 - 1.2) * (2.0 + tt * 15.0))
				draw_polyline(spiral, Color("#F0608A"), 5.0)
				draw_polyline(spiral, Color("#FF8FAE"), 2.0)
				draw_arc(head, 19.0, 0, TAU, 28, Color("#C45077"), 2.2)
				draw_arc(head, 14.0, deg_to_rad(185), deg_to_rad(255), 12, Color(1, 1, 1, 0.65), 3.4)
			"chocolate":
				# A bar of chocolate half out of its wrapper: the squares in relief, the foil along the torn edge.
				_shadow(c + Vector2(0, 20), 26.0)
				# The grooves between the squares are the dark base showing through; each square is raised on it.
				_lit(PackedVector2Array([c + Vector2(-26, -15), c + Vector2(26, -17),
					c + Vector2(26, 16), c + Vector2(-26, 18)]), Color("#4A2A14"))
				for row in 2:
					for col in 3:
						var at := c + Vector2(-23.0 + col * 16.0, -12.0 + row * 15.0)
						draw_colored_polygon(PackedVector2Array([at, at + Vector2(13, -0.5),
							at + Vector2(13, 11.5), at + Vector2(0, 12)]), Color("#8A5630"))
						draw_polyline(PackedVector2Array([at + Vector2(0, 11.6), at + Vector2(13, 11.1),
							at + Vector2(13, -0.4)]), Color("#5E3618"), 1.6)
						draw_polyline(PackedVector2Array([at + Vector2(0.8, 11.0), at + Vector2(0.8, 0.8),
							at + Vector2(12.2, 0.3)]), Color("#A87044"), 1.6)
				# The red wrapper over its left end, with its gold band and the torn foil showing.
				_lit(PackedVector2Array([c + Vector2(-27, -16), c + Vector2(-6, -17),
					c + Vector2(-6, 17), c + Vector2(-27, 19)]), Color("#C8202A"))
				draw_line(c + Vector2(-26, -2), c + Vector2(-7, -3), Color("#F2C230"), 4.0)
				draw_line(c + Vector2(-6, -17), c + Vector2(-6, 17), Color("#E8E2D0"), 2.6)
				draw_colored_polygon(_oval(c + Vector2(-18, -10), Vector2(7, 3), -0.3), Color(1, 1, 1, 0.3))
			"gum":
				# A stick of gum sliding out of its paper: the sleeve, its band, and the pink gum showing.
				_shadow(c + Vector2(0, 18), 22.0)
				# The gum itself, a thinner slab with a rounded end, sliding out to the right…
				draw_colored_polygon(_oval(c + Vector2(20, 0), Vector2(5, 9)), Color("#F3A9BC"))
				draw_arc(c + Vector2(20, 0), 9.0, deg_to_rad(-80), deg_to_rad(80), 14, Color("#C9788C"), 2.0)
				_lit(PackedVector2Array([c + Vector2(-2, -9), c + Vector2(20, -9),
					c + Vector2(20, 9), c + Vector2(-2, 9)]), Color("#F3A9BC"))
				draw_line(c + Vector2(4, -6), c + Vector2(19, -6), Color(1, 1, 1, 0.55), 2.4)
				# …and the paper sleeve it came out of, a little taller than the gum so the slide reads.
				_lit(PackedVector2Array([c + Vector2(-25, -13), c + Vector2(2, -12),
					c + Vector2(2, 12), c + Vector2(-25, 13)]), Color("#FBF7EC"))
				draw_colored_polygon(PackedVector2Array([c + Vector2(-25, -4), c + Vector2(2, -3),
					c + Vector2(2, 6), c + Vector2(-25, 5)]), Color("#3E86C9"))
				draw_line(c + Vector2(-25, -2), c + Vector2(2, -1), Color("#6FB4EC"), 2.0)
				# The torn edge of the paper where she pulled it open.
				draw_polyline(PackedVector2Array([c + Vector2(2, -12), c + Vector2(-1, -7), c + Vector2(2, -2),
					c + Vector2(-1, 4), c + Vector2(2, 9), c + Vector2(0, 12)]), Color("#CFC8B8"), 2.0)
				draw_colored_polygon(_oval(c + Vector2(-16, -9), Vector2(7, 2.6), -0.1), Color(1, 1, 1, 0.55))
			"chips":
				# A little bag of chips: crimped top and bottom, the crinkle catching the light, its oval label.
				_shadow(c + Vector2(0, 24), 20.0)
				var body := PackedVector2Array([c + Vector2(-18, -18), c + Vector2(18, -19),
					c + Vector2(15, 20), c + Vector2(-15, 21)])
				_lit(body, Color("#E8812E"))
				for k in 3:
					var x := -11.0 + k * 11.0
					draw_line(c + Vector2(x - 3, -14), c + Vector2(x + 1, 17), Color(1, 1, 1, 0.16), 4.0)
				for edge: float in [-18.0, 20.0]:
					var crimp := PackedVector2Array()
					var w := 18.0 if edge < 0.0 else 15.0
					for i in 9:
						crimp.append(c + Vector2(-w + i * (w * 2.0 / 8.0), edge + (2.5 if i % 2 == 0 else -2.5)))
					draw_polyline(crimp, Color("#B85A16"), 2.4)
				draw_colored_polygon(_oval(c + Vector2(0, 1), Vector2(13, 9)), Color("#FBF4E6"))
				draw_arc(c + Vector2(0, 1), 1.0, 0, TAU, 4, Color("#C9962E"), 1.0)
				for p: Array in [[-5.0, -1.0], [4.0, -3.0], [0.0, 4.0]]:
					draw_colored_polygon(_oval(c + Vector2(p[0], p[1] + 1.0), Vector2(4.4, 3.2), float(p[0])),
						Color("#F2C230"))
					draw_arc(c + Vector2(p[0], p[1] + 1.0), 3.8, 0, TAU, 12, Color("#C9962E"), 1.0)
