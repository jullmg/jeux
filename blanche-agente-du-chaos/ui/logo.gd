class_name Logo
extends Control
## Le lettrage du titre : de grosses lettres qui dansent un peu, et « agente du Chaos » sur son ruban, avec une trace
## de patte. Tout est dessiné.

const NAME_SIZE := 118
const SUB_SIZE := 70

var reduced_motion := false
var _time := 0.0
var _font: FontVariation


func _init() -> void:
	custom_minimum_size = Vector2(860, 330)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_font = FontVariation.new()
	_font.base_font = load("res://art/fonts/Fredoka.ttf")
	_font.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): 700}


func _process(delta: float) -> void:
	if not reduced_motion and is_visible_in_tree():
		_time += delta
		queue_redraw()


func _draw() -> void:
	_title(Texts.TITLE, Vector2(size.x / 2.0, 108))
	_ribbon(Texts.SUBTITLE, Vector2(size.x / 2.0, 248))
	Icons.paw(self, Vector2(size.x / 2.0 + 350, 246), 30.0, UiStyle.PINK)
	Icons.paw(self, Vector2(size.x / 2.0 + 396, 202), 20.0, UiStyle.PINK)


## Une lettre à la fois : chacune a son penchant et son petit saut.
func _title(text: String, center: Vector2) -> void:
	var widths: Array[float] = []
	var total := 0.0
	for i in text.length():
		var w := _font.get_string_size(text[i], HORIZONTAL_ALIGNMENT_LEFT, -1, NAME_SIZE).x
		widths.append(w)
		total += w
	var scale_ := minf(1.0, (size.x - 70.0) / total)
	var places: Array[Transform2D] = []
	var x := center.x - total * scale_ / 2.0
	for i in text.length():
		var half := widths[i] * scale_ / 2.0
		var from_middle := (x + half - center.x) / (total * scale_ / 2.0)
		var hop := sin(_time * 2.4 - i * 0.45) * 3.5
		var tilt := from_middle * 0.07 + sin(i * 2.7) * 0.045
		var at := Vector2(x + half, center.y + from_middle * from_middle * 22.0 + hop)
		places.append(Transform2D(tilt, Vector2.ONE * scale_, 0.0, at))
		x += widths[i] * scale_
	# L'ombre de tout le mot, puis son contour, puis les lettres : les contours ne mordent pas sur les voisines.
	for layer: Array in [[Vector2(0, 11), 30, Color(0, 0, 0, 0.35)], [Vector2.ZERO, 30, UiStyle.INK],
			[Vector2.ZERO, 8, Color("b0603a")], [Vector2.ZERO, 0, UiStyle.CREAM]]:
		for i in text.length():
			var t := places[i]
			t.origin += layer[0]
			draw_set_transform_matrix(t)
			var at := Vector2(-widths[i] / 2.0, NAME_SIZE * 0.33)
			if layer[1] > 0:
				draw_char_outline(_font, at, text[i], NAME_SIZE, layer[1], layer[2])
			else:
				draw_char(_font, at, text[i], NAME_SIZE, layer[2])
	draw_set_transform_matrix(Transform2D.IDENTITY)


func _ribbon(text: String, center: Vector2) -> void:
	var w := _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, SUB_SIZE).x
	var half := w / 2.0 + 46.0
	draw_set_transform(center, -0.045)
	for tail: float in [-1.0, 1.0]:
		var end := PackedVector2Array([Vector2(tail * (half - 26), -26), Vector2(tail * (half + 64), -20),
			Vector2(tail * (half + 38), 14), Vector2(tail * (half + 66), 52), Vector2(tail * (half - 26), 46)])
		draw_colored_polygon(end, UiStyle.PINK_DARK.darkened(0.2))
	var body := Rect2(-half, -48, half * 2.0, 92)
	draw_style_box(UiStyle.box(Color(0, 0, 0, 0.3), 22, Color.TRANSPARENT, 0, 0), Rect2(body.position + Vector2(0, 9), body.size))
	draw_style_box(UiStyle.box(UiStyle.PINK, 22, UiStyle.INK, 6, 0), body)
	draw_style_box(UiStyle.box(Color(1, 1, 1, 0.16), 16, Color.TRANSPARENT, 0, 0),
		Rect2(body.position + Vector2(12, 10), Vector2(body.size.x - 24, 30)))
	var at := Vector2(-w / 2.0, 22)
	draw_string_outline(_font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, SUB_SIZE, 18, UiStyle.INK)
	draw_string(_font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, SUB_SIZE, UiStyle.GOLD)
	draw_set_transform_matrix(Transform2D.IDENTITY)
