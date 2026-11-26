class_name Ambiance
extends Node3D
## La lumière de la cuisine : un appoint doux venu du plafond, le soleil qui entre par la fenêtre, un contre-jour frais,
## les lumières sous les armoires, et le rendu (ombres de contact, halo, couleurs). Chaque mission a son moment.

## La sonde de reflets de la cuisine (centre, taille), aussi celle d'une pièce qui n'en dit rien.
const DEFAULT_PROBE := [Vector3(0.0, 1.35, 0.35), Vector3(4.3, 3.0, 5.6)]
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
		"ambient": [Color(0.72, 0.62, 0.55), 0.48], "key": [Color(1.0, 0.86, 0.70), 0.60],
		"window": [Color(1.0, 0.55, 0.30), 4.2], "fill": [Color(0.88, 0.80, 0.80), 0.09], "lamps": 0.62,
		"sky": Color(1.0, 0.58, 0.44), "exposure": 1.08, "saturation": 1.06,
	},
	"brunch": {
		"ambient": [Color(0.80, 0.77, 0.76), 0.60], "key": [Color(1.0, 0.95, 0.88), 0.72],
		"window": [Color(1.0, 0.86, 0.62), 6.0], "fill": [Color(0.86, 0.90, 1.0), 0.16], "lamps": 0.32,
		"sky": Color(1.0, 1.0, 1.0), "exposure": 1.10, "saturation": 1.10,
	},
	"fete": {
		"ambient": [Color(0.82, 0.78, 0.76), 0.58], "key": [Color(1.0, 0.96, 0.90), 0.72],
		"window": [Color(1.0, 0.90, 0.74), 4.6], "fill": [Color(0.90, 0.88, 1.0), 0.14], "lamps": 0.4,
		"sky": Color(1.0, 0.96, 0.9), "exposure": 1.08, "saturation": 1.12,
	},
	# Le soir de hockey : dehors il fait nuit, la lampe sur pied et la télé éclairent le salon.
	"hockey": {
		"ambient": [Color(0.70, 0.56, 0.50), 0.30], "key": [Color(1.0, 0.80, 0.60), 0.22],
		"window": [Color(0.45, 0.55, 0.95), 1.2], "fill": [Color(0.80, 0.80, 0.95), 0.05], "lamps": 1.4,
		"sky": Color(0.18, 0.24, 0.48), "exposure": 1.16, "saturation": 1.08,
	},
	# Le film : les lumières éteintes ; seule la télé éclaire la pièce, par éclats (la même valeur que les règles).
	"film": {
		"ambient": [Color(0.46, 0.50, 0.68), 0.20], "key": [Color(0.62, 0.68, 0.95), 0.10],
		"window": [Color(0.40, 0.50, 0.90), 0.9], "fill": [Color(0.70, 0.74, 0.95), 0.05], "lamps": 0.0,
		"sky": Color(0.10, 0.14, 0.30), "exposure": 1.18, "saturation": 1.0,
	},
	"noel": {
		"ambient": [Color(0.68, 0.55, 0.50), 0.44], "key": [Color(1.0, 0.82, 0.62), 0.56],
		"window": [Color(0.45, 0.60, 1.0), 2.2], "fill": [Color(0.72, 0.72, 0.92), 0.07], "lamps": 0.85,
		"sky": Color(0.16, 0.24, 0.52), "exposure": 1.10, "saturation": 1.08,
	},
}

var moment := ""
## Le modèle éclairé : "cuisine" ou "double_salon".
var room := "cuisine"
var _env: Environment
var _key: DirectionalLight3D
var _fill: DirectionalLight3D
var _window: SpotLight3D
var _lamps: Array[OmniLight3D] = []
var _probe: ReflectionProbe
## Les lumières propres à chaque pièce : modèle → [fenêtre, lampes].
var _rigs: Dictionary = {}
## La boîte de la sonde de reflets pour la pièce montrée.
var _probe_box := DEFAULT_PROBE


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

	# La cuisine : le soleil par la fenêtre de l'est, les réglettes sous les armoires, un halo près de la porte.
	_rig("cuisine", [Vector3(3.5, 2.75, -0.95), Vector3(0.1, 0.0, 0.15), 8.0], [[Vector3(-0.39, 1.36, -1.78), 1.25],
		[Vector3(1.0, 1.24, -1.74), 1.25], [Vector3(1.78, 1.36, 0.45), 1.25], [Vector3(1.78, 1.36, -1.45), 1.25],
		[Vector3(1.2, 2.2, 1.35), 3.0]])
	# Le double salon : le jour par la fenêtre du salon (au sud), la suspension de la salle à manger, la lampe sur pied,
	# le plafonnier du salon et un peu de lumière dans le corridor.
	# Des portées courtes : chaque lampe n'éclaire que son coin (moins de lumières à calculer par point).
	_rig("double_salon", [Vector3(0.65, 2.75, 6.2), Vector3(0.1, 0.0, 1.2), 9.0], [[Vector3(0.15, 1.78, -1.8), 2.2],
		[Vector3(1.23, 1.45, 0.0), 2.2], [Vector3(0.0, 2.6, 1.9), 2.6], [Vector3(-2.3, 2.3, -0.4), 2.6]])
	set_room("cuisine")
	set_moment("matin")


## Les lumières d'une pièce : la fenêtre [position, cible, portée] et les lampes [position, portée].
func _rig(model: String, window: Array, lamps: Array) -> void:
	var spot := SpotLight3D.new()
	spot.position = window[0]
	spot.spot_range = window[2]
	spot.spot_angle = 26.0
	spot.spot_attenuation = 0.4
	spot.shadow_enabled = true
	spot.shadow_blur = 2.0
	add_child(spot)
	spot.look_at(window[1])
	var list: Array[OmniLight3D] = []
	for spec: Array in lamps:
		var lamp := OmniLight3D.new()
		lamp.position = spec[0]
		lamp.light_color = Color(1.0, 0.80, 0.54)
		lamp.omni_range = spec[1]
		add_child(lamp)
		list.append(lamp)
	_rigs[model] = {"window": spot, "lamps": list}


## Montre les lumières d'une pièce (et cache celles de l'autre). `probe` : [centre, taille] de la sonde de reflets.
func set_room(model: String, probe: Array = []) -> void:
	room = model
	for name_: String in _rigs:
		var on: bool = name_ == model
		_rigs[name_].window.visible = on
		for lamp: OmniLight3D in _rigs[name_].lamps:
			lamp.visible = on
	_window = _rigs[model].window
	_lamps = _rigs[model].lamps
	_probe_box = probe if not probe.is_empty() else DEFAULT_PROBE
	# Le prochain set_moment() s'applique en entier (et photographie les reflets une seule fois).
	moment = ""


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
		# Éteinte (le film), une lampe ne coûte plus rien à l'écran.
		lamp.visible = m.lamps > 0.0
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
		_probe.position = _probe_box[0]
		_probe.size = _probe_box[1]
		_probe.interior = true
		_probe.box_projection = true
		_probe.ambient_mode = ReflectionProbe.AMBIENT_DISABLED
		_probe.update_mode = ReflectionProbe.UPDATE_ONCE
		_probe.intensity = 0.8
		add_child(_probe)
	else:
		_probe.size = _probe_box[1]
		var at: Vector3 = _probe_box[0]
		_probe.position = at if _probe.position.distance_to(at) > 0.0004 else at + Vector3(0, 0.001, 0)
