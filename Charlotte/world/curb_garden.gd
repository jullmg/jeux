class_name CurbGarden
extends Node2D
## The planted curb extension at a street corner (reference/terre_plein_01.png, 02.png): the sidewalk's curb bulges
## out into the parking lane, round toward the corner, and holds a bed of perennials the neighbours keep (hostas,
## ornamental grasses, shrubs, coneflowers), with black and white striped flexible bollards at its tips. Snowy
## stalks in winter. Its position is the curb at the bed's start; it runs `width` px toward `corner` (+1 right,
## -1 left).

const DEPTH := 44.0

var width := 260.0
var corner := 1.0
var seed_value := 1


func _draw() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var winter := Season.is_winter()
	# The outline: tapering in from the street side, full depth, a round end at the corner.
	var pts := PackedVector2Array()
	for k in 17:
		var t := k / 16.0
		var depth := DEPTH * smoothstep(0.0, 0.25, t)
		pts.append(Vector2(t * (width - DEPTH * 0.5), depth))
	for k in 9:
		var a := lerpf(PI / 2.0, -PI / 2.0, k / 8.0)
		pts.append(Vector2(width - DEPTH * 0.5, DEPTH * 0.5) + Vector2(cos(a), sin(a)) * DEPTH * 0.5)
	if corner < 0.0:
		for i in pts.size():
			pts[i].x = -pts[i].x
	var soil := PackedVector2Array(pts)
	soil.append(Vector2.ZERO)
	draw_colored_polygon(soil, Color("#5A4232") if not winter else Color("#EEF2F5"))
	draw_polyline(pts, Color("#D6D1C6"), 5.0, true)
	draw_polyline(pts, Color("#9E998E"), 1.5, true)
	# Plants back to front, so the near ones overlap.
	var span := width - DEPTH * 0.5
	for row in 2:
		var x := 14.0
		while x < span - 6.0:
			var at := Vector2(x * corner, 6.0 + row * 16.0 + rng.randf_range(-3, 3))
			if at.y < DEPTH * smoothstep(0.0, 0.25, x / span) - 4.0:
				_plant(rng, at, winter)
			x += rng.randf_range(16.0, 28.0)
	# The striped flexible bollards at the bed's tips.
	for bx in [8.0 * corner, (span + DEPTH * 0.3) * corner]:
		_bollard(Vector2(bx, DEPTH * 0.55 if absf(bx) > 20.0 else 4.0))


func _plant(rng: RandomNumberGenerator, at: Vector2, winter: bool) -> void:
	var kind: String = ["hosta", "grass", "grass", "shrub", "coneflower", "hosta"][rng.randi_range(0, 5)]
	var h := rng.randf_range(16.0, 30.0)
	if winter:
		for i in 4:
			draw_line(at, at + Vector2(rng.randf_range(-6, 6), -h * rng.randf_range(0.5, 1.0)), Color("#8E7A62"), 1.2)
		draw_colored_polygon(PackedVector2Array([at + Vector2(-9, 2), at + Vector2(0, -5), at + Vector2(9, 2)]), Color("#F7F9FB"))
		return
	var green := {"spring": Color("#7FB85A"), "summer": Color("#4F8E3A"), "autumn": Color("#8E9A4A")}[Season.current] as Color
	match kind:
		"hosta":
			var leaf := Color("#9CC48A") if rng.randf() < 0.5 else Color("#6FA06A")
			if Season.current == "autumn":
				leaf = Color("#D9C46A")
			for i in 6:
				var a := lerpf(-2.8, -0.35, i / 5.0)
				var tip := at + Vector2.from_angle(a) * h * 0.7
				var side := Vector2.from_angle(a).orthogonal() * 5.0
				draw_colored_polygon(PackedVector2Array([at, at.lerp(tip, 0.5) + side, tip, at.lerp(tip, 0.5) - side]), leaf.darkened(0.1 * (i % 2)))
				draw_line(at, tip, Color(1, 1, 1, 0.5), 1.0)
		"grass":
			var blade := Color("#C9B07A") if Season.current == "autumn" else green.lightened(0.15)
			for i in 9:
				var tip := at + Vector2(rng.randf_range(-10, 10), -h * rng.randf_range(0.7, 1.2))
				draw_line(at, tip, blade.darkened(rng.randf_range(0.0, 0.25)), 1.3, true)
		"shrub":
			var c := Color("#B5442E") if Season.current == "autumn" else green.darkened(0.1)
			for i in 5:
				draw_circle(at + Vector2(rng.randf_range(-8, 8), -rng.randf_range(4, h * 0.6)), rng.randf_range(5, 8), c.darkened(rng.randf_range(0.0, 0.2)))
		_:
			for i in 4:
				var top := at + Vector2(rng.randf_range(-7, 7), -h * rng.randf_range(0.7, 1.0))
				draw_line(at, top, green.darkened(0.2), 1.2)
				if Season.current != "autumn":
					draw_circle(top, 3.0, Color("#C97AB8"))
					draw_circle(top, 1.4, Color("#7A4A2A"))
				else:
					draw_circle(top, 2.2, Color("#4A3428"))


func _bollard(at: Vector2) -> void:
	var r := Rect2(at + Vector2(-3, -34), Vector2(6, 34))
	draw_rect(r, Color("#1E1E1E"))
	for k in 3:
		draw_rect(Rect2(r.position + Vector2(0, 4 + k * 10), Vector2(6, 4)), Color("#F4F4F4"))
	draw_circle(at + Vector2(0, -34), 3.0, Color("#1E1E1E"))
