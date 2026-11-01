class_name TreePit
extends Node2D
## The little square of earth at the foot of a street tree, cut into the sidewalk by the curb: plain grass, or a
## garden the neighbours planted (hostas, daisies, black-eyed Susans, lavender; tulips in spring, mums in autumn),
## or mulch with a few plants; a granite edging, sometimes a low fence of iron hoops. Snow in winter.
## Its position is the trunk's foot on the curb line; set `seed_value` for its own look.

const W := 124.0
const DEPTH := 20.0

var seed_value := 1


func _draw() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var kind: String = ["grass", "garden", "garden", "mulch"][rng.randi_range(0, 3)]
	var winter := Season.is_winter()
	var top := -DEPTH - 2.0
	var bottom := -2.0
	var pit := PackedVector2Array([Vector2(-W / 2.0 + 6.0, top), Vector2(W / 2.0 - 6.0, top), Vector2(W / 2.0, bottom), Vector2(-W / 2.0, bottom)])
	# Granite edging, then the earth.
	var edge := PackedVector2Array([Vector2(-W / 2.0 + 2.0, top - 3.0), Vector2(W / 2.0 - 2.0, top - 3.0), Vector2(W / 2.0 + 4.0, bottom + 2.0), Vector2(-W / 2.0 - 4.0, bottom + 2.0)])
	draw_colored_polygon(edge, Color("#B9B4AA"))
	var soil := Color("#5A4232") if kind != "mulch" else Color("#7A5236")
	draw_colored_polygon(pit, soil)
	if winter:
		draw_colored_polygon(PackedVector2Array([pit[0] + Vector2(0, -3), pit[1] + Vector2(0, -3), pit[2], pit[3]]), Color("#F4F6F8"))
		for i in 6:
			var x := rng.randf_range(-W / 2.0 + 10.0, W / 2.0 - 10.0)
			draw_line(Vector2(x, bottom - 6.0), Vector2(x + rng.randf_range(-4, 4), bottom - rng.randf_range(16, 30)), Color("#7A6A58"), 1.2)
		_hoops(rng, top, bottom)
		return
	match kind:
		"grass":
			var green: Color = {"spring": Color("#7FB85A"), "summer": Color("#5E9E3E"), "autumn": Color("#8A9A48")}[Season.current]
			draw_colored_polygon(pit, green)
			for i in 40:
				var x := rng.randf_range(-W / 2.0 + 4.0, W / 2.0 - 4.0)
				var y := rng.randf_range(top + 2.0, bottom)
				draw_line(Vector2(x, y), Vector2(x + rng.randf_range(-2, 2), y - rng.randf_range(3, 7)), green.darkened(rng.randf_range(0.0, 0.3)), 1.4)
		"mulch":
			for i in 30:
				var p := Vector2(rng.randf_range(-W / 2.0 + 6.0, W / 2.0 - 6.0), rng.randf_range(top + 2.0, bottom - 1.0))
				draw_line(p, p + Vector2(rng.randf_range(2, 5), rng.randf_range(-1, 1)), soil.lightened(rng.randf_range(0.1, 0.3)), 1.5)
			for i in rng.randi_range(2, 3):
				_plant(rng, Vector2(rng.randf_range(-W / 2.0 + 16.0, W / 2.0 - 16.0), bottom - 4.0))
		_:
			var x := -W / 2.0 + 12.0
			while x < W / 2.0 - 10.0:
				_plant(rng, Vector2(x + rng.randf_range(-3, 3), rng.randf_range(top + 8.0, bottom - 2.0)))
				x += rng.randf_range(14.0, 22.0)
	_hoops(rng, top, bottom)


# Sometimes a low fence of iron hoops round the edge, put in by whoever looks after it.
func _hoops(rng: RandomNumberGenerator, top: float, bottom: float) -> void:
	if rng.randf() > 0.4:
		return
	var color := Color("#2B3A2E") if rng.randf() < 0.5 else Color("#1F1F1F")
	var x := -W / 2.0
	while x < W / 2.0 - 4.0:
		draw_arc(Vector2(x + 8.0, bottom + 1.0), 8.0, PI, TAU, 8, color, 1.6, true)
		x += 12.0
	draw_line(Vector2(-W / 2.0, bottom + 1.0), Vector2(W / 2.0, bottom + 1.0), color, 1.2)


# One clump: a hosta, daisies, black-eyed Susans, lavender, or the season's own (tulips, mums).
func _plant(rng: RandomNumberGenerator, at: Vector2) -> void:
	var kinds := ["hosta", "daisy", "susan", "lavender"]
	if Season.current == "spring":
		kinds.append_array(["tulip", "tulip"])
	elif Season.current == "autumn":
		kinds.append_array(["mum", "mum"])
	var kind: String = kinds[rng.randi_range(0, kinds.size() - 1)]
	var leaf := Color("#4F8E3A") if Season.current != "autumn" else Color("#7A8A3A")
	match kind:
		"hosta":
			for i in 5:
				var a := lerpf(-2.6, -0.5, i / 4.0)
				var tip := at + Vector2.from_angle(a) * rng.randf_range(10.0, 14.0)
				draw_colored_polygon(PackedVector2Array([at, at.lerp(tip, 0.5) + Vector2.from_angle(a + 1.2) * 4.0, tip, at.lerp(tip, 0.5) + Vector2.from_angle(a - 1.2) * 4.0]),
					Color("#5E9A6A").lightened(0.1 * (i % 2)))
		"lavender":
			for i in 6:
				var top := at + Vector2(rng.randf_range(-6, 6), -rng.randf_range(12, 20))
				draw_line(at, top, leaf.darkened(0.2), 1.0)
				draw_line(top, top + Vector2(0, 5), Color("#8E6FC4"), 2.5)
		"tulip":
			for i in 3:
				var top := at + Vector2(rng.randf_range(-6, 6), -rng.randf_range(12, 18))
				draw_line(at, top, leaf, 1.4)
				draw_circle(top, 3.0, [Color("#E74C3C"), Color("#F1C40F"), Color("#F7A8C8")][rng.randi_range(0, 2)])
		"mum":
			for i in 7:
				draw_circle(at + Vector2(rng.randf_range(-7, 7), -rng.randf_range(3, 11)), 3.2, [Color("#E0782E"), Color("#8E2A3A"), Color("#F2B632")][i % 3])
		_:
			var petal := Color.WHITE if kind == "daisy" else Color("#F2B632")
			var heart := Color("#F2C230") if kind == "daisy" else Color("#4A2A18")
			for i in 4:
				var top := at + Vector2(rng.randf_range(-7, 7), -rng.randf_range(9, 17))
				draw_line(at, top, leaf, 1.0)
				draw_circle(top, 3.0, petal)
				draw_circle(top, 1.2, heart)
