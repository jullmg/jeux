class_name Effects
extends Node3D
## Les petits effets : miettes quand Blanche mange, étincelles des gros morceaux, cœurs de la victoire, poussière sous
## les pattes. Tout est fabriqué une fois, au début : rien ne se compile en pleine partie.

var reduced_motion := false

var _crumbs: CPUParticles3D
var _stars: CPUParticles3D
var _hearts: CPUParticles3D
var _dust: CPUParticles3D


func _ready() -> void:
	var cube := BoxMesh.new()
	cube.size = Vector3.ONE * 0.014
	var crumb := StandardMaterial3D.new()
	crumb.albedo_color = Color("d9a35a")
	crumb.roughness = 0.9
	cube.material = crumb
	_crumbs = _burst(cube, 14, 0.7)
	_crumbs.direction = Vector3(0, 1, 0)
	_crumbs.spread = 70.0
	_crumbs.initial_velocity_min = 0.4
	_crumbs.initial_velocity_max = 1.0
	_crumbs.gravity = Vector3(0, -3.2, 0)
	_crumbs.angle_max = 360.0
	_crumbs.color_ramp = _fade(Color.WHITE, 0.75)

	_stars = _burst(_sprite(_star_image(), 0.085, true), 16, 0.9)
	_stars.direction = Vector3(0, 1, 0)
	_stars.spread = 80.0
	_stars.initial_velocity_min = 0.5
	_stars.initial_velocity_max = 1.1
	_stars.gravity = Vector3(0, -1.2, 0)
	_stars.color_ramp = _fade(Color(1.0, 0.82, 0.25), 0.6)

	_hearts = _burst(_sprite(_heart_image(), 0.11, false), 18, 2.2)
	_hearts.explosiveness = 0.25
	_hearts.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	_hearts.emission_sphere_radius = 0.18
	_hearts.direction = Vector3(0, 1, 0)
	_hearts.spread = 25.0
	_hearts.initial_velocity_min = 0.25
	_hearts.initial_velocity_max = 0.55
	_hearts.gravity = Vector3(0, 0.1, 0)
	_hearts.color_ramp = _fade(Color(1.0, 0.42, 0.58), 0.7)

	_dust = _burst(_sprite(_dot_image(), 0.09, false), 5, 0.45)
	_dust.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	_dust.emission_sphere_radius = 0.07
	_dust.direction = Vector3(0, 1, 0)
	_dust.spread = 80.0
	_dust.initial_velocity_min = 0.08
	_dust.initial_velocity_max = 0.2
	_dust.gravity = Vector3.ZERO
	_dust.color_ramp = _fade(Color(0.86, 0.74, 0.58, 0.55), 0.2)


func crumbs(at: Vector3) -> void:
	_fire(_crumbs, at)


func stars(at: Vector3) -> void:
	if not reduced_motion:
		_fire(_stars, at)


func hearts(at: Vector3) -> void:
	_fire(_hearts, at)


func dust(at: Vector3) -> void:
	if not reduced_motion:
		_fire(_dust, at)


func clear() -> void:
	for p: CPUParticles3D in [_crumbs, _stars, _hearts, _dust]:
		p.emitting = false


func _fire(p: CPUParticles3D, at: Vector3) -> void:
	p.position = at
	p.restart()
	p.emitting = true


func _burst(mesh: Mesh, amount: int, life: float) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.mesh = mesh
	p.amount = amount
	p.lifetime = life
	p.one_shot = true
	p.explosiveness = 0.92
	p.local_coords = false
	p.scale_amount_min = 0.6
	p.scale_amount_max = 1.2
	p.emitting = false
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(p)
	return p


func _sprite(image: Image, size: float, bright: bool) -> QuadMesh:
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE * size
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.vertex_color_use_as_albedo = true
	m.albedo_texture = ImageTexture.create_from_image(image)
	m.no_depth_test = bright
	if bright:
		m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	quad.material = m
	return quad


func _fade(color: Color, hold: float) -> Gradient:
	var g := Gradient.new()
	g.set_color(0, color)
	g.set_color(1, Color(color, 0.0))
	g.add_point(hold, color)
	return g


## Une forme blanche dessinée par le calcul : `inside` dit si un point (de -1 à 1, y vers le haut) en fait partie.
static func _shape(inside: Callable) -> Image:
	var size := 64
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	for y in size:
		for x in size:
			var hits := 0
			for sub in 4:
				var p := Vector2((x + 0.25 + 0.5 * (sub % 2)) / size, (y + 0.25 + 0.5 * (sub / 2)) / size) * 2.0 - Vector2.ONE
				if inside.call(Vector2(p.x, -p.y)):
					hits += 1
			image.set_pixel(x, y, Color(1, 1, 1, hits / 4.0))
	return image


static func _heart_image() -> Image:
	return _shape(func(p: Vector2) -> bool:
		var q := Vector2(p.x * 1.2, p.y * 1.2 + 0.1)
		return pow(q.x * q.x + q.y * q.y - 0.62, 3.0) - q.x * q.x * q.y * q.y * q.y < 0.0)


static func _star_image() -> Image:
	return _shape(func(p: Vector2) -> bool:
		# une étincelle à quatre branches
		return pow(absf(p.x), 0.55) + pow(absf(p.y), 0.55) < 0.95)


static func _dot_image() -> Image:
	var image := _shape(func(_p: Vector2) -> bool: return true)
	for y in 64:
		for x in 64:
			var d := Vector2(x - 31.5, y - 31.5).length() / 31.5
			image.set_pixel(x, y, Color(1, 1, 1, clampf(1.0 - d, 0.0, 1.0)))
	return image
