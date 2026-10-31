class_name Wind
extends Node2D
## Gusts every so often: trees bend harder and a flurry of leaves (petals, snow) blows across the screen.

const GUST := 4.5

var materials: Array[ShaderMaterial] = []
var strength := 0.0
var _next := 5.0
var _gust_t := -1.0
var _flurry: CPUParticles2D


func _ready() -> void:
	_flurry = CPUParticles2D.new()
	_flurry.texture = Season.falling_texture()
	_flurry.emitting = false
	_flurry.amount = 46
	_flurry.lifetime = 3.6
	_flurry.local_coords = false
	_flurry.position = Vector2(-700, -40)
	_flurry.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_flurry.emission_rect_extents = Vector2(30, 300)
	_flurry.direction = Vector2(1, -0.05)
	_flurry.spread = 12.0
	_flurry.gravity = Vector2(0, 45)
	_flurry.initial_velocity_min = 380.0
	_flurry.initial_velocity_max = 600.0
	_flurry.angular_velocity_min = -540.0
	_flurry.angular_velocity_max = 540.0
	_flurry.angle_max = 360.0
	_flurry.scale_amount_min = 0.55
	_flurry.scale_amount_max = 1.1
	_flurry.color_initial_ramp = PropArt.leaf_colors()
	add_child(_flurry)


func _process(delta: float) -> void:
	_next -= delta
	if _next <= 0.0:
		_gust_t = 0.0
		_next = randf_range(10.0, 20.0)
	if _gust_t >= 0.0:
		_gust_t += delta
		strength = sin(clampf(_gust_t / GUST, 0.0, 1.0) * PI)
		if _gust_t > GUST:
			_gust_t = -1.0
			strength = 0.0
	_flurry.emitting = strength > 0.35
	var cam := get_viewport().get_camera_2d()
	position = cam.get_screen_center_position() if cam else Vector2(640, 360)
	for m in materials:
		m.set_shader_parameter("gust", strength)
