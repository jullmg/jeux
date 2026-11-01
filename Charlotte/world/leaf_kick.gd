class_name LeafKick
extends CPUParticles2D
## Fallen leaves (petals in spring, powder snow in winter) kicked up behind someone's feet while they walk.

var walker: Character


func _ready() -> void:
	texture = Season.falling_texture()
	# A few leaves now and then, not a cloud: a light scuff.
	amount = 3
	lifetime = 0.7
	explosiveness = 0.0
	randomness = 0.8
	local_coords = false
	emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	emission_rect_extents = Vector2(10, 2)
	spread = 25.0
	gravity = Vector2(0, 320)
	initial_velocity_min = 40.0
	initial_velocity_max = 90.0
	angular_velocity_min = -400.0
	angular_velocity_max = 400.0
	angle_max = 360.0
	scale_amount_min = 0.35
	scale_amount_max = 0.6
	color_initial_ramp = PropArt.leaf_colors()


func _process(_delta: float) -> void:
	position = walker.position + Vector2(0, -2)
	emitting = walker.is_walking and (Season.litter_amount() > 0.1 or Season.is_winter())
	direction = Vector2(-walker.facing, -1.6)
