class_name Ambiance
extends Node3D
## La lumière de la cuisine : un appoint doux venu du plafond, le soleil qui entre par la fenêtre, un contre-jour frais,
## les lumières sous les armoires, et le rendu (ombres de contact, halo, couleurs). Chaque mission a son moment.

## La couche des personnages : un contre-jour qui n'éclaire qu'eux détache leur silhouette.
const RIM_LAYER := 2
## Les moments : couleurs et forces des lumières, couleur de la vue par la fenêtre.
const MOMENTS := {
	"matin": {
		"ambient": [Color(0.78, 0.75, 0.76), 0.56], "key": [Color(1.0, 0.95, 0.89), 0.68],
		"window": [Color(1.0, 0.86, 0.62), 5.5], "fill": [Color(0.86, 0.90, 1.0), 0.14], "lamps": 0.30,
		"sky": Color(1.0, 1.0, 1.0), "exposure": 1.10, "saturation": 1.10,
	},
	"midi": {
		"ambient": [Color(0.80, 0.78, 0.76), 0.58], "key": [Color(1.0, 0.97, 0.93), 0.76],
		"window": [Color(1.0, 0.94, 0.82), 4.0], "fill": [Color(0.88, 0.92, 1.0), 0.14], "lamps": 0.22,
		"sky": Color(1.0, 1.0, 1.0), "exposure": 1.06, "saturation": 1.08,
	},
	"soir": {
		"ambient": [Color(0.66, 0.56, 0.60), 0.50], "key": [Color(1.0, 0.85, 0.68), 0.60],
		"window": [Color(1.0, 0.55, 0.30), 4.2], "fill": [Color(0.76, 0.70, 0.92), 0.11], "lamps": 0.62,
		"sky": Color(1.0, 0.58, 0.44), "exposure": 1.08, "saturation": 1.08,
	},
	"noel": {
		"ambient": [Color(0.64, 0.52, 0.56), 0.46], "key": [Color(1.0, 0.82, 0.62), 0.56],
		"window": [Color(0.45, 0.60, 1.0), 2.2], "fill": [Color(0.55, 0.62, 1.0), 0.09], "lamps": 0.85,
		"sky": Color(0.16, 0.24, 0.52), "exposure": 1.10, "saturation": 1.12,
	},
}

var moment := ""
var _env: Environment
var _key: DirectionalLight3D
var _fill: DirectionalLight3D
var _window: SpotLight3D
var _lamps: Array[OmniLight3D] = []
var _probe: ReflectionProbe


func _ready() -> void:
	_env = Environment.new()
	_env.background_mode = Environment.BG_COLOR
	_env.background_color = Color(0.105, 0.070, 0.062)
	_env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	_env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	_env.tonemap_white = 3.0
	# Les ombres de contact assoient les meubles, la nourriture et les pattes.
	_env.ssao_enabled = true
	_env.ssao_radius = 0.32
	_env.ssao_intensity = 2.6
	_env.ssao_power = 1.6
	_env.glow_enabled = true
	_env.glow_intensity = 0.45
	_env.glow_bloom = 0.02
	_env.glow_hdr_threshold = 1.05
	_env.adjustment_enabled = true
	_env.adjustment_contrast = 1.05
	var world := WorldEnvironment.new()
	world.environment = _env
	add_child(world)

	_key = _sun(Vector3(-62, -24, 0), true)
	_key.shadow_blur = 1.6
	_fill = _sun(Vector3(-24, 138, 0), false)

	var rim := _sun(Vector3(-28, 168, 0), false)
	rim.light_color = Color(1.0, 0.93, 0.84)
	rim.light_energy = 0.9
	rim.light_cull_mask = RIM_LAYER

	_window = SpotLight3D.new()
	_window.position = Vector3(3.5, 2.75, -0.95)
	_window.spot_range = 8.0
	_window.spot_angle = 26.0
	_window.spot_attenuation = 0.4
	_window.shadow_enabled = true
	_window.shadow_blur = 2.0
	add_child(_window)
	_window.look_at(Vector3(0.1, 0.0, 0.15))

	# Sous les armoires, puis un halo près de la porte.
	for at: Vector3 in [Vector3(-0.39, 1.36, -1.78), Vector3(1.0, 1.24, -1.74), Vector3(1.78, 1.36, 0.45),
			Vector3(1.78, 1.36, -1.45), Vector3(1.2, 2.2, 1.35)]:
		var lamp := OmniLight3D.new()
		lamp.position = at
		lamp.light_color = Color(1.0, 0.80, 0.54)
		lamp.omni_range = 3.0 if at.y > 2.0 else 1.25
		add_child(lamp)
		_lamps.append(lamp)

	set_moment("matin")


func _sun(degrees: Vector3, shadows: bool) -> DirectionalLight3D:
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = degrees
	sun.shadow_enabled = shadows
	sun.directional_shadow_max_distance = 12.0
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	sun.shadow_bias = 0.025
	add_child(sun)
	return sun


## « matin », « midi », « soir » ou « noel ». Les reflets sont refaits à chaque changement.
func set_moment(name_: String) -> void:
	if name_ == moment or not MOMENTS.has(name_):
		return
	moment = name_
	var m: Dictionary = MOMENTS[name_]
	_env.ambient_light_color = m.ambient[0]
	_env.ambient_light_energy = m.ambient[1]
	_env.tonemap_exposure = m.exposure
	_env.adjustment_saturation = m.saturation
	_key.light_color = m.key[0]
	_key.light_energy = m.key[1]
	_window.light_color = m.window[0]
	_window.light_energy = m.window[1]
	_fill.light_color = m.fill[0]
	_fill.light_energy = m.fill[1]
	for lamp in _lamps:
		lamp.light_energy = m.lamps * (1.0 if lamp.omni_range < 2.0 else 0.7)
	_capture_reflections()


## Avant de quitter : la sonde rend ses images, sinon le moteur les signale comme oubliées.
func release() -> void:
	if _probe:
		_probe.queue_free()
		_probe = null


## La teinte à donner à la vue par la fenêtre.
func sky_tint() -> Color:
	return MOMENTS[moment].sky


## Une sonde photographie la pièce une fois : c'est elle que reflètent l'inox, le comptoir et le plancher verni.
## La déplacer d'un cheveu lui fait reprendre sa photo.
func _capture_reflections() -> void:
	if _probe == null:
		_probe = ReflectionProbe.new()
		_probe.position = Vector3(0.0, 1.35, 0.35)
		_probe.size = Vector3(4.3, 3.0, 5.6)
		_probe.interior = true
		_probe.box_projection = true
		_probe.ambient_mode = ReflectionProbe.AMBIENT_DISABLED
		_probe.update_mode = ReflectionProbe.UPDATE_ONCE
		_probe.intensity = 0.8
		add_child(_probe)
	else:
		_probe.position.y = 1.35 if _probe.position.y > 1.3505 else 1.351
