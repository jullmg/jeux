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
		_birds.append(Vector4(rank * 24.0 + randf_range(-5, 5), side * rank * 9.0 + randf_range(-4, 4), randf_range(0, TAU),
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


# One far-off bird, small as before: a "V" of two curved wings that beat (down fast, up slow, a glide now and then),
# thick at the shoulder and thinning to the tip, with a tiny body between them.
func _bird(at: Vector2, t: float, phase: float, k: float) -> void:
	var beat := sin(t * 7.0 + phase) + 0.3 * sin(t * 14.0 + phase)
	if sin(t * 0.45 + phase * 3.0) > 0.72:
		beat = 0.3
	var ink := Color("#3A3A44")
	var flap := beat * 4.5 * k
	for side in [-1.0, 1.0]:
		# Shoulder, elbow (arched up), tip (swinging).
		var pts := [Vector2(0, 0), Vector2(side * 4.0 * k, -2.0 * k - flap * 0.5), Vector2(side * 9.0 * k, -0.5 * k - flap)]
		var curve := PackedVector2Array()
		for i in 7:
			var u := i / 6.0
			var a: Vector2 = pts[0].lerp(pts[1], u)
			var b: Vector2 = pts[1].lerp(pts[2], u)
			curve.append(at + a.lerp(b, u))
		draw_polyline(curve.slice(0, 5), ink, 2.4 * k, true)
		# Thinner outer half, so the wing tapers.
		draw_polyline(curve.slice(4), ink, 1.3 * k, true)
	draw_circle(at + Vector2(0, 0.4 * k), 1.5 * k, ink)
