class_name PersonView
extends Node3D
## Maman, Papa ou Charlotte à l'écran. `pose` dit le geste en cours.

## Les matières dont la couleur vient des sommets du modèle (tools/blender/heads.py).
const PAINTED := ["peau_visage", "cheveux_ombre", "tissu_haut", "tissu_bas"]

## "idle", "walk", "brasser", "couper", "laver", "frigo", "telephone", "four", "ilot", "surprise", "charlotte",
## "hint", "feint", "round", "look", "point", "laugh", "wave", "carry", "snitch", "cheer", "chicane", "argue"
var pose := "idle"
var speed := 0.0
## "Sourire", "Neutre", "Ouverte", "Fachee"
var mouth := "Sourire"
var talking := 0.0
## Direction du regard, en degrés autour de la verticale (relative au corps).
var head_yaw := 0.0
## La façon de chicaner : 0 doigt pointé, 1 doigt qui secoue et poing sur la hanche, 2 les bras au ciel puis le doigt.
var scold_style := 0
var _scold_time := 0.0

var rig: Rig
var model: Node3D
var _mouths: Dictionary = {}
var _time := 0.0
var _phase := 0.0
var _props: Dictionary = {}         # nom → objet déjà fabriqué
var _prop_kind := ""
## Les matières des objets restent en mémoire : les recréer ferait recompiler leur shader en pleine partie.
static var _materials: Dictionary = {}
var who: String


func _init(who_: String) -> void:
	who = who_
	_time = absf(float(who_.hash() % 100)) * 0.1


func _ready() -> void:
	model = (load("res://art/models/%s.glb" % who) as PackedScene).instantiate()
	add_child(model)
	rig = Rig.new(model)
	_paint_by_vertex()
	for mesh: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
		mesh.layers = 1 | Ambiance.RIM_LAYER
	for mesh: MeshInstance3D in model.find_children("Bouche*", "MeshInstance3D", true, false):
		_mouths[mesh.name.trim_prefix("Bouche")] = mesh
	_set_mouth("Sourire")


## Les visages et les chevelures sont peints aux sommets (joues roses, barbe, cheveux foncés à la racine).
func _paint_by_vertex() -> void:
	for mesh: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
		for s in mesh.mesh.get_surface_count():
			var base := mesh.mesh.surface_get_material(s) as BaseMaterial3D
			if base and base.resource_name in PAINTED:
				var m: BaseMaterial3D = base.duplicate()
				m.vertex_color_use_as_albedo = true
				# Ces couleurs sont enregistrées en sRGB (tools/blender/heads.py) : seul le moteur mobile les prend telles quelles.
				m.vertex_color_is_srgb = RenderingServer.get_current_rendering_method() != "gl_compatibility"
				m.albedo_color = Color.WHITE
				mesh.set_surface_override_material(s, m)


## Les poings sur les hanches : coudes écartés, mains ramenées vers la taille.
func _fists_on_hips() -> void:
	_fist_on_hip("L")
	_fist_on_hip("R")


func _fist_on_hip(s: String) -> void:
	var side := 1.0 if s == "L" else -1.0
	rig.add("arm" + s, Vector3(14, 0, 36 * side))
	rig.add("forearm" + s, Vector3(-18, 0, -88 * side))


func say(seconds: float) -> void:
	talking = seconds


func head_position() -> Vector3:
	return rig.skeleton.global_transform * rig.position_of("head")


func _set_mouth(kind: String) -> void:
	for key: String in _mouths:
		_mouths[key].visible = key == kind


func _arm(side: String, forward: float, out: float, bend: float, twist := 0.0) -> void:
	var s := 1.0 if side == "L" else -1.0
	rig.add("arm" + side, Vector3(-forward, twist * s, out * s))
	rig.add("forearm" + side, Vector3(-bend, 0, 0))


func _process(delta: float) -> void:
	# Papa et Charlotte attendent hors champ : rien à animer.
	if not is_visible_in_tree():
		return
	_time += delta
	rig.begin()
	var quick := {}
	var t := _time
	var shown := mouth
	var prop := ""
	var sink := 0.0
	rig.add("chest", Vector3(sin(t * 1.9) * 1.0, 0, 0))
	match pose:
		"walk", "carry":
			_phase += delta * speed / 1.1 * TAU
			var amp := clampf(speed, 0.5, 1.2)
			for s: String in ["L", "R"]:
				var f := _phase + (0.0 if s == "L" else PI)
				quick["thigh" + s] = Vector3(sin(f) * 27 * amp, 0, 0)
				quick["shin" + s] = Vector3(maxf(0.0, -cos(f)) * 44 * amp, 0, 0)
				if pose == "walk":
					quick["arm" + s] = Vector3(-sin(f) * 20 * amp, 0, 0)
					_arm(s, 0, 2, 16)
			if pose == "carry":
				for s: String in ["L", "R"]:
					_arm(s, 34, -4, 62)
				prop = "panier"
			sink = absf(sin(_phase)) * 0.018
		"brasser", "surprise":
			var rate := 4.0 if pose == "brasser" else 9.0
			_arm("R", 38, -2, 52)
			_arm("L", 22, 8, 40)
			quick["armR"] = Vector3(sin(t * rate) * 7, 0, cos(t * rate) * 7)
			quick["forearmR"] = Vector3(cos(t * rate) * 8, 0, 0)
			rig.add("spine", Vector3(7, 0, 0))
			rig.add("head", Vector3(14, sin(t * 0.6) * 5, 0))
			prop = "cuillere"
		"couper":
			_arm("R", 30, 4, 62)
			_arm("L", 30, 2, 58)
			quick["forearmR"] = Vector3(-maxf(0.0, sin(t * 11.0)) * 22, 0, 0)
			rig.add("spine", Vector3(10, 0, 0))
			rig.add("head", Vector3(20, 0, 0))
			prop = "couteau"
		"laver":
			_arm("R", 34, -2, 44)
			_arm("L", 34, -2, 44)
			quick["forearmR"] = Vector3(sin(t * 7.0) * 9, 0, cos(t * 7.0) * 9)
			quick["forearmL"] = Vector3(cos(t * 5.0) * 7, 0, 0)
			rig.add("spine", Vector3(15, 0, 0))
			rig.add("head", Vector3(12, 0, sin(t * 1.4) * 4))
			prop = "assiette"
		"frigo":
			_arm("R", 62 + sin(t * 1.7) * 16, 6, 24)
			_arm("L", 40, 22, 20)
			rig.add("spine", Vector3(24 + sin(t * 0.9) * 5, 0, 0))
			rig.add("chest", Vector3(8, 0, 0))
			rig.add("head", Vector3(-8, sin(t * 1.3) * 20, 0))
		"telephone":
			_arm("R", 38, 20, 138, -30)
			_arm("L", 14 + sin(t * 2.3) * 14, 16, 50 + sin(t * 3.1) * 20)
			rig.add("head", Vector3(0, 8, -10 + sin(t * 1.1) * 4))
			rig.add("spine", Vector3(0, sin(t * 0.7) * 6, 0))
			prop = "telephone"
			shown = "Ouverte" if fmod(t, 0.5) < 0.2 and fmod(t, 3.0) < 1.8 else "Sourire"
		"four":
			rig.add("spine", Vector3(36, 0, 0))
			rig.add("chest", Vector3(14, 0, 0))
			rig.add("head", Vector3(-16, 0, 0))
			for s: String in ["L", "R"]:
				_arm(s, 50, 3, 20)
				rig.add("thigh" + s, Vector3(-30, 0, 0))
				rig.add("shin" + s, Vector3(44, 0, 0))
				rig.add("foot" + s, Vector3(-14, 0, 0))
			sink = -0.09
		"ilot":
			var push := sin(t * 5.0)
			for s: String in ["L", "R"]:
				_arm(s, 34 + push * 8, -5, 36 - push * 12)
			rig.add("spine", Vector3(14 + push * 4, 0, 0))
			rig.add("head", Vector3(24, 0, 0))
		"charlotte":
			_arm("R", 10, 6, 30)
			_arm("L", 10, 6, 30)
			rig.add("head", Vector3(18 + sin(t * 4.0) * 5, 0, 0))
			rig.add("spine", Vector3(12, 0, 0))
		"hint":
			rig.add("head", Vector3(-12, 32, 0))
			rig.add("chest", Vector3(0, 24, 0))
			rig.add("spine", Vector3(0, 14, 0))
			_arm("R", 12, 14, 50)
			_arm("L", 6, 6, 20)
			shown = "Ouverte"
		"feint":
			rig.add("head", Vector3(-8, 0, 15))
			_arm("R", 36, 10, 140)
			_arm("L", 20, 6, 40)
			shown = "Neutre"
		"round":
			rig.add("head", Vector3(-6, sin(t * 5.0) * 34, 0))
			_fists_on_hips()
			shown = "Neutre"
		"look":
			_fists_on_hips()
			rig.add("head", Vector3(-8, head_yaw + sin(t * 2.2) * 8, 0))
			shown = "Neutre"
		"point":
			if scold_style == 2 and _scold_time < 0.55:
				for s: String in ["L", "R"]:
					_arm(s, 24, 118, 42)
				rig.add("head", Vector3(-18, head_yaw, 0))
			else:
				_arm("R", 82, 14, 4)
				_fist_on_hip("L")
				var shake := 14.0 if scold_style == 1 else 4.0
				quick["armR"] = Vector3(sin(t * 14.0) * 4, sin(t * 11.0) * shake, 0)
				rig.add("spine", Vector3(14 if scold_style != 1 else 6, 0, 0))
				rig.add("head", Vector3(0, head_yaw, sin(t * 9.0) * 8 if scold_style == 1 else 0.0))
			shown = "Fachee" if talking <= 0.0 else "Ouverte"
		"laugh":
			for s: String in ["L", "R"]:
				_arm(s, 20, 14, 70)
			quick["chest"] = Vector3(sin(t * 15.0) * 3, 0, 0)
			rig.add("head", Vector3(-12, 0, 6))
			shown = "Ouverte" if fmod(t, 0.3) < 0.18 else "Sourire"
		"wave":
			_arm("R", 20, 130, 30)
			quick["forearmR"] = Vector3(0, 0, sin(t * 9.0) * 24)
			_arm("L", 0, 6, 12)
			rig.add("head", Vector3(-8, 0, sin(t * 2.0) * 8))
		"chicane":
			# Un poing sur la hanche, l'autre main qui s'agite, la tête qui dit « non, là ».
			_fist_on_hip("L")
			_arm("R", 52 + sin(t * 7.0) * 24, 16, 55 + sin(t * 7.0 + 1.2) * 30)
			rig.add("spine", Vector3(9, 0, 0))
			rig.add("head", Vector3(0, sin(t * 8.0) * 9, sin(t * 2.7) * 6))
			shown = "Fachee"
		"argue":
			# Les bras pleins, il hausse les épaules et se défend de la tête.
			for s: String in ["L", "R"]:
				_arm(s, 34, -4 + maxf(0.0, sin(t * 3.4)) * 9, 62)
			rig.add("spine", Vector3(-5, 0, 0))
			rig.add("head", Vector3(-6, sin(t * 5.0) * 15, sin(t * 2.2) * 11))
			prop = "panier"
			shown = "Neutre"
		"snitch":
			_arm("R", 78, 4, 6)
			_arm("L", 40, 4, 125)
			rig.add("head", Vector3(0, head_yaw, 0))
			shown = "Ouverte"
		"cheer":
			for s: String in ["L", "R"]:
				_arm(s, 10, 140, 16)
			sink = absf(sin(t * 7.0)) * 0.08
		_:
			for s: String in ["L", "R"]:
				_arm(s, sin(t * 1.3) * 2, 3, 12)
			rig.add("head", Vector3(0, head_yaw + sin(t * 0.7) * 7, 0))
	_scold_time = _scold_time + delta if pose == "point" else 0.0
	if talking > 0.0:
		talking -= delta
		if pose != "point":
			var closed := "Fachee" if pose == "chicane" else ("Neutre" if pose == "argue" else "Sourire")
			shown = "Ouverte" if fmod(t, 0.24) < 0.12 else closed
	_set_mouth(shown)
	_show_prop(prop)
	rig.apply(delta, 10.0, quick)
	model.position.y = lerpf(model.position.y, sink, 1.0 - exp(-delta * 18.0))


# ------------------------------------------------------------------ objets en main

func _show_prop(kind: String) -> void:
	if kind == _prop_kind:
		return
	if _props.has(_prop_kind):
		_props[_prop_kind].visible = false
	_prop_kind = kind
	if kind == "":
		return
	if _props.has(kind):
		_props[kind].visible = true
		return
	var bone := "handR"
	var node := Node3D.new()
	match kind:
		"cuillere":
			_part(node, _cylinder(0.011, 0.26), Color("b88350"), Vector3(0, -0.07, 0.05), Vector3(50, 0, 0))
			_part(node, _sphere(0.028), Color("b88350"), Vector3(0, -0.155, 0.15))
		"couteau":
			_part(node, _box(Vector3(0.014, 0.03, 0.09)), Color("252428"), Vector3(0, -0.02, 0.03))
			_part(node, _box(Vector3(0.004, 0.045, 0.17)), Color("cfd3d8"), Vector3(0, -0.03, 0.16))
		"assiette":
			_part(node, _cylinder(0.11, 0.015), Color("f2efe8"), Vector3(0.05, -0.04, 0.09), Vector3(60, 0, 0))
		"telephone":
			_part(node, _box(Vector3(0.018, 0.14, 0.07)), Color("26262c"), Vector3(0.01, -0.03, 0.02))
		"panier":
			bone = "chest"
			# Un panier d'osier tressé, plein de linge plié.
			_part(node, _box(Vector3(0.42, 0.19, 0.25)), Color("a9803f"), Vector3(0, -0.095, 0.4))
			for i in 4:
				_part(node, _box(Vector3(0.445, 0.016, 0.275)), Color("c59a55"), Vector3(0, -0.17 + i * 0.047, 0.4))
			for i in 7:
				_part(node, _box(Vector3(0.014, 0.19, 0.28)), Color("8f6a32"), Vector3(-0.18 + i * 0.06, -0.095, 0.4))
			_part(node, _box(Vector3(0.47, 0.028, 0.3)), Color("d6ac66"), Vector3(0, 0.005, 0.4))
			# des serviettes roulées qui dépassent du panier
			for roll: Array in [["7fa8cf", -0.1, 0.02, 0.37, 0.05, 6.0], ["e8e3d8", 0.09, 0.025, 0.43, 0.052, -10.0],
					["d67b6a", 0.03, 0.06, 0.37, 0.043, 20.0], ["f2c95c", -0.07, 0.055, 0.45, 0.036, -24.0]]:
				_part(node, _cylinder(roll[4], 0.19), Color(roll[0]), Vector3(roll[1], roll[2], roll[3]),
					Vector3(0, roll[5], 90))
	var attach := BoneAttachment3D.new()
	attach.bone_name = bone
	rig.skeleton.add_child(attach)
	attach.add_child(node)
	# Les positions ci-dessus sont dans les axes du modèle, à partir de l'os au repos.
	var rest := rig.skeleton.get_bone_global_rest(rig.bones[bone])
	node.transform = rest.affine_inverse() * Transform3D(Basis.IDENTITY, rest.origin)
	_props[kind] = attach


func _part(parent: Node3D, mesh: Mesh, color: Color, at: Vector3, degrees := Vector3.ZERO) -> void:
	var m := MeshInstance3D.new()
	m.mesh = mesh
	if not _materials.has(color):
		var mat := StandardMaterial3D.new()
		mat.albedo_color = color
		mat.roughness = 0.5
		_materials[color] = mat
	m.material_override = _materials[color]
	m.position = at
	m.rotation_degrees = degrees
	parent.add_child(m)


static func _box(size: Vector3) -> BoxMesh:
	var m := BoxMesh.new()
	m.size = size
	return m


static func _sphere(radius: float) -> SphereMesh:
	var m := SphereMesh.new()
	m.radius = radius
	m.height = radius * 2.0
	m.radial_segments = 16
	m.rings = 8
	return m


static func _cylinder(radius: float, height: float) -> CylinderMesh:
	var m := CylinderMesh.new()
	m.top_radius = radius
	m.bottom_radius = radius
	m.height = height
	m.radial_segments = 20
	return m
