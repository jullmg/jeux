class_name LeafKick
extends CPUParticles2D
## Fallen leaves kicked up behind someone's feet while they walk.

var walker: Character


func _ready() -> void:
	texture = PropArt.leaf()
	amount = 10
	lifetime = 0.8
	local_coords = false
	emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	emission_rect_extents = Vector2(10, 2)
	spread = 25.0
	gravity = Vector2(0, 320)
	initial_velocity_min = 60.0
	initial_velocity_max = 130.0
	angular_velocity_min = -400.0
	angular_velocity_max = 400.0
	angle_max = 360.0
	scale_amount_min = 0.35
	scale_amount_max = 0.6
	color_initial_ramp = PropArt.leaf_colors()


func _process(_delta: float) -> void:
	position = walker.position + Vector2(0, -2)
	emitting = walker.is_walking
	direction = Vector2(-walker.facing, -1.6)
