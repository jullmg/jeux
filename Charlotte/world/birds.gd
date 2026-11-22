class_name Birds
extends Node2D
## A small flock crossing the sky now and then.

var _birds := []
var _speed := 70.0


func _ready() -> void:
	_respawn(true)


func _respawn(first := false) -> void:
	var cam := get_viewport().get_camera_2d()
	var cx := cam.get_screen_center_position().x if cam else 640.0
	position = Vector2(cx + (300.0 if first else randf_range(900, 2200)), randf_range(90, 190))
	_speed = randf_range(55, 85)
	_birds.clear()
	# A loose V behind a leader, each bird a little different in size and in the beat of its wings.
	for i in randi_range(3, 7):
		var rank := (i + 1) / 2
		var side := 1.0 if i % 2 == 0 else -1.0
		_birds.append(Vector4(rank * 30.0 + randf_range(-5, 5), side * rank * 11.0 + randf_range(-4, 4), randf_range(0, TAU),
			randf_range(0.8, 1.15)))


func _process(delta: float) -> void:
	position.x -= _speed * delta
	var cam := get_viewport().get_camera_2d()
	if cam and position.x < cam.get_screen_center_position().x - 900.0:
		_respawn()
	if OnScreen.near(self, 900.0):
		queue_redraw()


func _draw() -> void:
	var t := Time.get_ticks_msec() / 1000.0
	for b in _birds:
		_bird(Vector2(b.x, b.y), t, b.z, b.w)


# One bird seen from the side, flying to the left: a plump body, a small head with a beak, a tail, and two wings
# that beat in a cycle (down fast, up slow) with now and then a glide. Soft dark grey, lighter belly.
func _bird(at: Vector2, t: float, phase: float, k: float) -> void:
	var cycle := t * 6.0 + phase
	var beat := sin(cycle) + 0.35 * sin(cycle * 2.0)
	# Every few seconds the wings stay out and the bird glides.
	if sin(t * 0.45 + phase * 3.0) > 0.72:
		beat = 0.25
	var ink := Color("#38384A")
	var belly := Color("#6A6A7C")
	var body := PackedVector2Array([Vector2(-8, -1), Vector2(-5, -3.2), Vector2(2, -3.4), Vector2(9, -1.2), Vector2(15, 0.4),
		Vector2(8, 1.8), Vector2(0, 3.2), Vector2(-5, 2.4)])
	for i in body.size():
		body[i] = at + body[i] * k
	draw_colored_polygon(body, ink)
	draw_colored_polygon(PackedVector2Array([at + Vector2(-5, 0.6) * k, at + Vector2(1, 0.8) * k, at + Vector2(0, 3.0) * k,
		at + Vector2(-4, 2.3) * k]), belly)
	# Head and beak.
	draw_circle(at + Vector2(-8.5, -1.6) * k, 2.6 * k, ink)
	draw_colored_polygon(PackedVector2Array([at + Vector2(-10.6, -2.0) * k, at + Vector2(-13.4, -1.2) * k, at + Vector2(-10.6, -0.6) * k]),
		Color("#C9A24A"))
	# Wings: a shoulder, a bend and a tip that swings from high to low.
	var tip_y := -beat * 12.0 - 1.0
	var bend_y := -beat * 6.0 - 2.0
	for far in [true, false]:
		var sh := Vector2(0.5, -2.8) if not far else Vector2(2.5, -2.4)
		var tip := Vector2(6.0 + beat * 2.5 + (2.5 if far else 0.0), tip_y * (0.9 if far else 1.0)) + Vector2(0, -3.0)
		var bend := Vector2(2.5, bend_y - 3.0)
		var col := ink.lightened(0.18) if far else ink
		# Three triangles, never one polygon: a wing folded at the bend can cross itself and fail to triangulate.
		var sh_f := at + (sh + Vector2(-6, 0)) * k
		var sh_b := at + (sh + Vector2(7, 0)) * k
		var b_f := at + (bend + Vector2(-5, -0.5)) * k
		var b_b := at + (bend + Vector2(6, 1.0)) * k
		var tp := at + tip * k
		for tri: Array in [[sh_f, b_f, b_b], [sh_f, b_b, sh_b], [b_f, tp, b_b]]:
			var area := absf((tri[1] - tri[0]).cross(tri[2] - tri[0]))
			if area > 0.05:
				draw_colored_polygon(PackedVector2Array(tri), col)
	# Tail.
	draw_colored_polygon(PackedVector2Array([at + Vector2(12, 0) * k, at + Vector2(19, -1.6 + beat * 0.6) * k,
		at + Vector2(19, 1.8 + beat * 0.6) * k]), ink)
