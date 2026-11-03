class_name GrowthMarks
extends Node2D
## How tall she was each birthday, in pencil straight on the wall by her door: a wobbly line and the age, from 3 years old up to
## GameState.age (a birthday adds a line the next time the room opens). Origin: the wall's base, at the left end of the lines.
## Heights are real ones (HEIGHTS, cm, at PX_PER_CM): the top line is about level with the top of her head when she stands there.

const PX_PER_CM := 1.42
## A girl's height at each age, from 3.
const HEIGHTS := [95.0, 102.0, 109.0, 115.0, 122.0, 128.0, 133.0, 139.0, 145.0, 152.0, 158.0, 161.0]
const WIDTH := 46.0
const GRAPHITE := Color("#55545E", 0.82)


func _draw() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 37
	var font := ThemeDB.fallback_font
	for age in range(3, GameState.age + 1):
		var y: float = -HEIGHTS[mini(age - 3, HEIGHTS.size() - 1)] * PX_PER_CM
		var line := PackedVector2Array()
		var tilt := rng.randf_range(-1.6, 1.6)
		for k in 7:
			var t := k / 6.0
			line.append(Vector2(WIDTH * t, y + tilt * t + rng.randf_range(-0.6, 0.6)))
		draw_polyline(line, GRAPHITE, 1.5, true)
		# Gone over twice, as a pencil does.
		draw_polyline(PackedVector2Array([line[0] + Vector2(1, 1), line[3] + Vector2(0, 1), line[6] + Vector2(-2, 0)]), Color(GRAPHITE, 0.4), 1.0, true)
		draw_set_transform(Vector2(-4.0, y + 4.0), rng.randf_range(-0.06, 0.04))
		draw_string(font, Vector2(-38.0, 0.0), "%d ans" % age, HORIZONTAL_ALIGNMENT_RIGHT, 38.0, 10, GRAPHITE)
		draw_set_transform(Vector2.ZERO)
