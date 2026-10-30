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
	for i in randi_range(3, 6):
		_birds.append(Vector3(i * 26.0 + randf_range(-6, 6), absf(i - 2) * 9.0 + randf_range(-5, 5), randf_range(0, TAU)))


func _process(delta: float) -> void:
	position.x -= _speed * delta
	var cam := get_viewport().get_camera_2d()
	if cam and position.x < cam.get_screen_center_position().x - 900.0:
		_respawn()
	queue_redraw()


func _draw() -> void:
	var t := Time.get_ticks_msec() / 1000.0
	for b in _birds:
		var flap := sin(t * 9.0 + b.z) * 5.0
		var c := Vector2(b.x, b.y)
		draw_polyline(PackedVector2Array([c + Vector2(-9, -flap), c + Vector2(-3, -1), c, c + Vector2(3, -1), c + Vector2(9, -flap)]),
			Color("#3A3A44"), 2.2, true)
