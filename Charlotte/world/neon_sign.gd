class_name NeonSign
extends Node2D
## Neon lettering in a shop window: each line drawn as a glowing tube (a wide soft halo, the coloured tube, a pale
## hot core), with a little flicker now and then. `lines` stack downward from the node's position (their centre).

var lines: Array[String] = []
var color := Color("#FF2A2A")
var font_size := 20
## Rotated a little, as signs hang.
var tilt := -0.06
var vertical := false
var _t := 0.0
var _flicker := 0.0
var _next := 3.0


func _process(delta: float) -> void:
	_t += delta
	_next -= delta
	if _next <= 0.0:
		_flicker = 0.25
		_next = randf_range(4.0, 11.0)
	_flicker = maxf(_flicker - delta, 0.0)
	queue_redraw()


func _draw() -> void:
	var font := ThemeDB.fallback_font
	var on := 0.35 if _flicker > 0.0 and int(_t * 30.0) % 3 == 0 else 1.0
	draw_set_transform(Vector2.ZERO, tilt)
	var glyphs: Array = []
	if vertical:
		for ch in lines[0]:
			glyphs.append(ch)
	else:
		glyphs = lines
	for i in glyphs.size():
		var text: String = glyphs[i]
		var y := (i - (glyphs.size() - 1) / 2.0) * font_size * (0.95 if vertical else 1.05) + font_size * 0.35
		var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		var at := Vector2(-width / 2.0, y)
		for glow in [[10, 0.12], [6, 0.22], [3, 0.4]]:
			draw_string_outline(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, glow[0], Color(color, glow[1] * on))
		draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(color.lightened(0.15), on))
		draw_string_outline(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 1, Color(1, 0.85, 0.85, 0.7 * on))
	draw_set_transform(Vector2.ZERO)
