class_name PersonView
extends Node3D
## Maman, Papa ou Charlotte à l'écran. `pose` dit le geste en cours.

## Les matières dont la couleur vient des sommets du modèle (tools/blender/heads.py).
const PAINTED := ["peau_visage", "cheveux_ombre", "tissu_haut", "tissu_bas"]
const STAND_IN := {"tante": "maman", "oncle": "papa"}
## Les objets qu'on peut avoir en main.
const PROPS := ["cuillere", "couteau", "assiette", "telephone", "panier", "plat", "fourchette", "verre", "cafetiere",
	"verre_vin", "verre_jus", "verre_lait", "journal", "plat_tenu"]
## Le plat qu'on sert ou qu'on rapporte de la cuisine (le « plat » de la mission) → son modèle dans nourriture.glb.
const DISHES := {"lasagne": "lasagne", "pate_chinois": "pate_chinois", "hot_dogs": "plateau_hot_dogs",
	"tourtiere": "tourtiere"}
## Le plat tenu à deux mains, à sa taille sur la table.
const DISH_SCALE := 1.05
## L'espace entre le dessus du siège et l'os des hanches.
const SEAT_GAP := 0.07

## "idle", "walk", "brasser", "couper", "laver", "frigo", "telephone", "four", "ilot", "surprise", "charlotte",
## "hint", "feint", "round", "look", "point", "laugh", "wave", "carry", "snitch", "cheer", "chicane", "argue",
## et dans la salle à manger et le salon : "servir", "buffet", "disque", "carry_plate", "manger", "jaser", "hockey",
## "film", "remote", "seated", "seated_chat", "snitch_seated", "slip", "argue_seated", "chat".
var pose := "idle"
## Assis : la hauteur du siège (0 : debout). Les jambes se plient, le reste suit la pose.
var seat_y := 0.0
## Tourné vers quelque chose en restant assis (degrés autour de la verticale, relatifs au corps).
var twist := 0.0
var speed := 0.0
## "Sourire", "Neutre", "Ouverte", "Fachee"
var mouth := "Sourire"
var talking := 0.0
## Direction du regard, en degrés autour de la verticale (relative au corps).
var head_yaw := 0.0
## Le plat du repas ("lasagne", "pate_chinois", "hot_dogs", "tourtiere", ou "cafe" au brunch : elle verse le café).
var dish := ""
## La façon de chicaner : 0 doigt pointé, 1 doigt qui secoue et poing sur la hanche, 2 les bras au ciel puis le doigt.
var scold_style := 0
var _scold_time := 0.0

var rig: Rig
var model: Node3D
## La hauteur des hanches debout (pour s'asseoir à la bonne hauteur).
var _hip_y := 0.9
var _mouths: Dictionary = {}
var _time := 0.0
var _phase := 0.0
var _props: Dictionary = {}         # nom → objet déjà fabriqué
var _prop_kind := ""
## Le vrai plat du repas, tenu à deux mains (son modèle est donné par la scène, `hold_dish`).
var _dish: MeshInstance3D
## Les matières des objets restent en mémoire : les recréer ferait recompiler leur shader en pleine partie.
static var _materials: Dictionary = {}
var who: String


func _init(who_: String) -> void:
	who = who_
	_time = absf(float(who_.hash() % 100)) * 0.1


func _ready() -> void:
	var file := "res://art/models/%s.glb" % who
	if not ResourceLoader.exists(file):
		# La visite emprunte un corps de la famille tant qu'elle n'a pas le sien.
		file = "res://art/models/%s.glb" % STAND_IN.get(who, "maman")
	model = (load(file) as PackedScene).instantiate()
	add_child(model)
	rig = Rig.new(model)
	_hip_y = rig.rest_position_of("hips").y
	_paint_by_vertex()
	for mesh: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
		mesh.layers = 1 | Ambiance.RIM_LAYER
	for mesh: MeshInstance3D in model.find_children("Bouche*", "MeshInstance3D", true, false):
		_mouths[mesh.name.trim_prefix("Bouche")] = mesh
	_set_mouth("Sourire")
	# Les objets en main sont fabriqués d'avance : en pleine partie, une nouvelle matière ferait un à-coup.
	for kind: String in PROPS:
		_show_prop(kind)
	_show_prop("")


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
		"servir":
			if _holds_dish():
				# Le plat à deux mains au-dessus de la table : elle l'avance pour servir chacun.
				var dip := maxf(0.0, sin(t * 1.3))
				for s: String in ["L", "R"]:
					_arm(s, 44 + dip * 14, -2, 62 - dip * 16)
				rig.add("spine", Vector3(14 + dip * 9, 0, 0))
				rig.add("head", Vector3(16 + dip * 6, 0, 0))
				prop = "plat_tenu"
			else:
				# Elle verse le café, puis pose une assiette.
				var pour := sin(t * 1.6)
				_arm("R", 42 + pour * 8, 6, 40)
				_arm("L", 30, 4, 54)
				quick["forearmR"] = Vector3(0, 0, maxf(0.0, pour) * 28)
				rig.add("spine", Vector3(16, 0, 0))
				rig.add("head", Vector3(18, 0, 0))
				prop = "cafetiere"
		"buffet", "disque":
			var slow := sin(t * (1.3 if pose == "disque" else 2.6))
			_arm("R", 40 + slow * 10, 2, 46)
			_arm("L", 34 - slow * 8, 4, 40)
			rig.add("spine", Vector3(12, 0, 0))
			rig.add("head", Vector3(16, sin(t * 0.8) * 10, 0))
			if pose == "disque":
				quick["handR"] = Vector3(0, sin(t * 4.0) * 12, 0)
		"carry_plate":
			_phase += delta * speed / 1.1 * TAU
			var amp := clampf(speed, 0.5, 1.2)
			for s: String in ["L", "R"]:
				var f := _phase + (0.0 if s == "L" else PI)
				quick["thigh" + s] = Vector3(sin(f) * 27 * amp, 0, 0)
				quick["shin" + s] = Vector3(maxf(0.0, -cos(f)) * 44 * amp, 0, 0)
				_arm(s, 40, -2, 66)
			sink = absf(sin(_phase)) * 0.018
			prop = "plat_tenu" if _holds_dish() else "plat"
		"manger":
			prop = _eat(t, quick)
			if prop == "":
				shown = "Ouverte" if fmod(t, 0.42) < 0.2 else "Sourire"
			elif prop == "fourchette" and _bite(t) > 0.55:
				shown = "Ouverte"
		"journal":
			# Il lit le journal, le baisse pour jaser, puis s'y replonge.
			var down := 1.0 if talking > 0.0 or fmod(t, 9.0) > 7.2 else 0.0
			for s: String in ["L", "R"]:
				_arm(s, 46 - down * 16, 14, 78 - down * 30)
			rig.add("head", Vector3(14 - down * 12, head_yaw * down, 0))
			rig.add("spine", Vector3(6, 0, 0))
			prop = "journal"
		"jaser", "seated_chat":
			var talk := sin(t * 3.1)
			_arm("R", 30 + talk * 18, 14, 70 + talk * 20)
			_arm("L", 26, 6, 68)
			rig.add("head", Vector3(-2, sin(t * 0.9) * 18, sin(t * 2.0) * 5))
			shown = "Ouverte" if fmod(t, 0.42) < 0.2 else "Sourire"
			prop = "verre" if pose == "jaser" else ""
		"hockey", "film":
			# Au divan, les yeux sur la télé ; au hockey, il se penche et serre les poings.
			var tense := 1.0 if pose == "hockey" else 0.0
			_arm("R", 30 + tense * 8, 10, 40 + tense * 14)
			_arm("L", 30 + tense * 8, 10, 40 + tense * 14)
			rig.add("spine", Vector3(-6 + tense * 14, 0, 0))
			rig.add("head", Vector3(4 + tense * 6, sin(t * 0.5) * 4, 0))
			if pose == "film" and fmod(t, 6.0) < 0.6:
				_arm("R", 50, 6, 120)
		"remote":
			# Il cherche la télécommande : penché de côté, il tâte les coussins.
			_arm("R", -4, 34 + sin(t * 6.0) * 8, 16)
			_arm("L", 24, 6, 40)
			rig.add("spine", Vector3(10, 0, -16))
			rig.add("head", Vector3(14, -20, 0))
			shown = "Neutre"
		"seated":
			_arm("R", 30, 8, 44)
			_arm("L", 30, 8, 44)
			rig.add("head", Vector3(0, sin(t * 0.6) * 22, 0))
		"snitch_seated":
			_arm("R", 70, 6, 8)
			_arm("L", 28, 6, 64)
			rig.add("head", Vector3(0, head_yaw, 0))
			shown = "Ouverte"
		"slip":
			# En cachette, la main descend sous la table ; l'œil guette Maman.
			_arm("R", -6, 22, 10)
			_arm("L", 30, 6, 66)
			rig.add("spine", Vector3(4, 0, 8))
			rig.add("head", Vector3(6, head_yaw, -6))
			shown = "Sourire"
		"argue_seated":
			_arm("R", 30 + sin(t * 5.0) * 16, 14, 80)
			_arm("L", 22, 8, 70)
			rig.add("head", Vector3(12, sin(t * 6.0) * 10, 0))
			shown = "Neutre"
		"chat":
			var nod := sin(t * 2.4)
			_arm("R", 34, 4, 70)
			_arm("L", 8 + nod * 10, 8, 30)
			rig.add("head", Vector3(nod * 4, sin(t * 0.7) * 14, 0))
			shown = "Ouverte" if fmod(t, 0.5) < 0.2 else "Sourire"
			prop = "verre"
		_:
			for s: String in ["L", "R"]:
				_arm(s, sin(t * 1.3) * 2, 3, 12)
			rig.add("head", Vector3(0, head_yaw + sin(t * 0.7) * 7, 0))
	if seat_y > 0.0:
		# Assis : les cuisses à plat, les jambes qui pendent (et se balancent un peu chez Charlotte).
		var swing := sin(t * 2.2) * 8.0 if who == "charlotte" else 0.0
		for s: String in ["L", "R"]:
			rig.target["thigh" + s] = Vector3(-86, 0, 0)
			rig.target["shin" + s] = Vector3(80 + (swing if s == "L" else -swing), 0, 0)
			rig.target["foot" + s] = Vector3(-4, 0, 0)
			quick.erase("thigh" + s)
			quick.erase("shin" + s)
		rig.add("chest", Vector3(0, twist * 0.45, 0))
		rig.add("spine", Vector3(0, twist * 0.35, 0))
		sink = seat_y + SEAT_GAP - _hip_y
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
	if _prop_kind == "plat_tenu":
		# Le plat reste à plat, quoi que fasse le dos : rien ne doit glisser.
		_dish.global_basis = Basis(Vector3.UP, global_rotation.y).scaled(Vector3.ONE * DISH_SCALE)


## Le vrai plat du repas à tenir (la scène le donne au début de la mission ; rien : on n'en tient pas).
func hold_dish(mesh: Mesh) -> void:
	_dish.mesh = mesh


func _holds_dish() -> bool:
	return _dish != null and _dish.mesh != null


## La bouchée : 0 la fourchette dans l'assiette, 1 à la bouche.
static func _bite(t: float) -> float:
	return clampf(sin(t * 2.2) * 1.8 - 0.5, 0.0, 1.0)


## Un repas à table, vu de partout : des bouchées, couper sa viande, une gorgée de vin, se tourner pour jaser
## (vers `head_yaw`). Le cycle dure 15 s, décalé d'une personne à l'autre. Rend l'objet en main ("" : les mains vides).
func _eat(t: float, quick: Dictionary) -> String:
	var c := fmod(t, 15.0)
	if talking > 0.0:
		c = 12.0
	if c < 6.0:
		var bite := _bite(t)
		_arm("R", 40 + bite * 32, 8, 62 + bite * 70)
		_arm("L", 34, 4, 70)
		rig.add("spine", Vector3(10 + bite * 3, 0, 0))
		rig.add("head", Vector3(12 - bite * 10, 0, 0))
		if bite < 0.2 and fmod(t, 0.5) < 0.25:
			quick["head"] = Vector3(2, 0, 0)
		return "fourchette"
	if c < 8.5:
		_arm("R", 40, 4, 66)
		_arm("L", 40, 2, 66)
		quick["forearmR"] = Vector3(sin(t * 12.0) * 9, 0, 0)
		rig.add("spine", Vector3(15, 0, 0))
		rig.add("head", Vector3(20, 0, 0))
		return "couteau"
	if c < 10.5:
		var sip := clampf(sin((c - 8.5) / 2.0 * PI) * 1.6, 0.0, 1.0)
		_arm("R", 32 + sip * 40, 12, 56 + sip * 74)
		_arm("L", 30, 4, 66)
		rig.add("head", Vector3(4 - sip * 16, 0, 0))
		if who == "charlotte":
			return "verre_lait"
		return "verre_jus" if dish == "cafe" else "verre_vin"
	# se tourner vers les autres et jaser, la main qui parle
	var turn := sin(clampf((c - 10.5) / 4.5, 0.0, 1.0) * PI)
	if talking > 0.0:
		turn = 1.0
	var toward := head_yaw if absf(head_yaw) > 4.0 else 26.0 * (1.0 if fmod(floor(t / 15.0), 2.0) == 0.0 else -1.0)
	rig.add("chest", Vector3(0, toward * 0.45 * turn, 0))
	rig.add("head", Vector3(-2, toward * 0.6 * turn, sin(t * 2.0) * 4))
	_arm("R", 26 + sin(t * 3.1) * 16 * turn, 14, 70 + sin(t * 3.1) * 18 * turn)
	_arm("L", 30, 6, 68)
	return ""


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
		"plat":
			bone = "chest"
			# Un plat de service fumant, tenu à deux mains devant elle.
			_part(node, _cylinder(0.17, 0.025), Color("f3efe6"), Vector3(0, -0.2, 0.36))
			_part(node, _cylinder(0.13, 0.05), Color("c87a3a"), Vector3(0, -0.17, 0.36))
		"fourchette":
			_part(node, _box(Vector3(0.012, 0.012, 0.16)), Color("d5d8dc"), Vector3(0, -0.03, 0.08))
		"verre":
			_part(node, _cylinder(0.03, 0.11), Color("e9d5a8"), Vector3(0, -0.02, 0.05))
		"cafetiere":
			# La cafetière de verre : le café, le col, le couvercle et la poignée noirs.
			_part(node, _cylinder(0.062, 0.13, 0.05), Color(0.86, 0.92, 0.95, 0.3), Vector3(0, -0.1, 0.1))
			_part(node, _cylinder(0.057, 0.08, 0.047), Color("3b1f12"), Vector3(0, -0.125, 0.1))
			_part(node, _cylinder(0.045, 0.035), Color("1d1d21"), Vector3(0, -0.02, 0.1))
			_part(node, _cylinder(0.05, 0.012), Color("1d1d21"), Vector3(0, -0.0, 0.1))
			_part(node, _box(Vector3(0.02, 0.1, 0.025)), Color("1d1d21"), Vector3(0, -0.07, 0.03))
			_part(node, _box(Vector3(0.016, 0.016, 0.045)), Color(0.86, 0.92, 0.95, 0.35), Vector3(0, -0.035, 0.165),
				Vector3(-25, 0, 0))
		"verre_vin":
			_part(node, _cylinder(0.026, 0.004), Color(0.88, 0.93, 0.95, 0.35), Vector3(0, -0.075, 0.05))
			_part(node, _cylinder(0.004, 0.07), Color(0.88, 0.93, 0.95, 0.35), Vector3(0, -0.04, 0.05))
			_part(node, _cylinder(0.034, 0.075, 0.028), Color(0.88, 0.93, 0.95, 0.3), Vector3(0, 0.03, 0.05))
			_part(node, _cylinder(0.03, 0.03, 0.026), Color("5e0f1c"), Vector3(0, 0.012, 0.05))
		"verre_jus", "verre_lait":
			# un verre droit de jus d'orange (au brunch) ou de lait (Charlotte)
			_part(node, _cylinder(0.033, 0.1, 0.029), Color(0.88, 0.93, 0.95, 0.3), Vector3(0, -0.02, 0.05))
			_part(node, _cylinder(0.03, 0.075, 0.027), Color("f4a227") if kind == "verre_jus" else Color("f6f4ee"),
				Vector3(0, -0.032, 0.05))
		"plat_tenu":
			bone = "chest"
			_dish = MeshInstance3D.new()
			_dish.position = Vector3(0, -0.24, 0.34)
			_dish.scale = Vector3.ONE * DISH_SCALE
			node.add_child(_dish)
		"journal":
			bone = "chest"
			# Le journal ouvert à deux mains devant lui : papier crème, gros titre, colonnes et une photo.
			var paper := Node3D.new()
			paper.position = Vector3(0, -0.02, 0.36)
			paper.rotation_degrees = Vector3(-14, 0, 0)
			node.add_child(paper)
			for side: float in [-1.0, 1.0]:
				_part(paper, _box(Vector3(0.27, 0.36, 0.004)), Color("ece6d6"), Vector3(side * 0.135, 0, 0),
					Vector3(0, side * 9.0, 0))
				_part(paper, _box(Vector3(0.21, 0.035, 0.002)), Color("26262b"), Vector3(side * 0.135, 0.13, 0.004),
					Vector3(0, side * 9.0, 0))
				for k in 6:
					_part(paper, _box(Vector3(0.2, 0.008, 0.002)), Color("8d8a84"),
						Vector3(side * 0.135, 0.08 - k * 0.028, 0.004), Vector3(0, side * 9.0, 0))
			_part(paper, _box(Vector3(0.09, 0.07, 0.002)), Color("6f8fae"), Vector3(0.18, -0.1, 0.02), Vector3(0, 9, 0))
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
		mat.roughness = 0.5 if color.a >= 1.0 else 0.08
		if color.a < 1.0:
			# le verre : transparent et luisant
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mat.metallic_specular = 0.9
		_materials[color] = mat
	m.material_override = _materials[color]
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if color.a >= 1.0 else \
		GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	m.position = at
	m.rotation_degrees = degrees
	parent.add_child(m)


static func _box(size: Vector3) -> BoxMesh:
	var m := BoxMesh.new()
	m.size = size
	return m


static func _sphere(radius: float, flat := 1.0) -> SphereMesh:
	var m := SphereMesh.new()
	m.radius = radius
	m.height = radius * 2.0 * flat
	m.radial_segments = 16
	m.rings = 8
	return m


static func _cylinder(radius: float, height: float, bottom := -1.0) -> CylinderMesh:
	var m := CylinderMesh.new()
	m.top_radius = radius
	m.bottom_radius = radius if bottom < 0.0 else bottom
	m.height = height
	m.radial_segments = 20
	return m
