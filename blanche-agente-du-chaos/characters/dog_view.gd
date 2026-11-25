class_name DogView
extends Node3D
## Blanche à l'écran. `pose` dit ce qu'elle fait ; le reste (queue, oreilles, paupières) vit tout seul.

const MODEL := "res://art/models/blanche.glb"
const FEET := ["pawL", "pawR", "hpawL", "hpawR"]
const HIND_FEET := ["hpawL", "hpawR"]

## "stand", "walk", "sit", "reach", "sulk", "crouch", "happy", "surprised"
var pose := "sit"
var reach_progress := 0.0
var chewing := false
var carrying := false
var speed := 0.0
var look_up := 0.0
## Les yeux piteux : après un « AU COIN ! ».
var sad := false
## De quel côté elle penche la tête quand elle a l'air piteuse.
var tilt := 1.0

var rig: Rig
var model: Node3D
var mouth_anchor: Node3D
var _time := 0.0
var _phase := 0.0
var _blink := 2.0
var _ground := 0.0
var _held: Node3D
## Surfaces du poil : [maillage, surface, matière normale, matière avec silhouette].
var _fur: Array[Array] = []
var _xray := false


func _ready() -> void:
	model = (load(MODEL) as PackedScene).instantiate()
	add_child(model)
	rig = Rig.new(model)
	_dress()
	rig.skeleton.set_bone_pose_scale(rig.bones.head, Vector3.ONE * 1.12)
	var attach := BoneAttachment3D.new()
	attach.bone_name = "jaw"
	rig.skeleton.add_child(attach)
	mouth_anchor = Node3D.new()
	attach.add_child(mouth_anchor)


## Matières : poil peint aux sommets, liseré de lumière pour lire la silhouette noire, et silhouette à travers les meubles.
func _dress() -> void:
	for mesh: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
		for s in mesh.mesh.get_surface_count():
			var base := mesh.mesh.surface_get_material(s) as BaseMaterial3D
			if base == null:
				continue
			var m: BaseMaterial3D = base.duplicate()
			var name := base.resource_name
			if name.begins_with("poil"):
				m.rim_enabled = true
				m.rim = 0.35
				m.rim_tint = 0.25
				if name == "poil":
					m.vertex_color_use_as_albedo = true
					m.albedo_color = Color.WHITE
				var through: BaseMaterial3D = m.duplicate()
				through.stencil_mode = BaseMaterial3D.STENCIL_MODE_XRAY
				through.stencil_color = Color(1.0, 0.72, 0.82, 0.7)
				_fur.append([mesh, s, m, through])
			mesh.set_surface_override_material(s, m)
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON


## La silhouette à travers les meubles, pour ne jamais perdre Blanche de vue.
func set_see_through(on: bool) -> void:
	if on == _xray:
		return
	_xray = on
	for f in _fur:
		f[0].set_surface_override_material(f[1], f[3] if on else f[2])


func hold(item: Node3D) -> void:
	drop_held()
	_held = item
	if item:
		mouth_anchor.add_child(item)
		# Repère du modèle au repos : devant la gueule, un peu sous le museau.
		var attach := mouth_anchor.get_parent() as BoneAttachment3D
		var rest := rig.skeleton.get_bone_global_rest(rig.bones[attach.bone_name])
		var world := Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * 0.7), Vector3(0, 0.612, 0.575))
		item.transform = rest.affine_inverse() * world


func drop_held() -> void:
	if is_instance_valid(_held):
		_held.queue_free()
	_held = null


## Où est le museau, dans le monde.
func nose_position() -> Vector3:
	return rig.skeleton.global_transform * rig.skeleton.get_bone_global_pose(rig.bones.jaw).origin


func head_position() -> Vector3:
	return rig.skeleton.global_transform * rig.position_of("head")


func _process(delta: float) -> void:
	_time += delta
	rig.begin()
	var quick := {}
	var wag_speed := 5.0
	var wag := 14.0
	var lids := 0.0
	var brows := 0.0
	var ears := 0.0
	var jaw := 0.0
	var breathe := sin(_time * 3.2)
	match pose:
		"sit":
			rig.add("hips", Vector3(-36, 0, 0))
			for s: String in ["L", "R"]:
				rig.add("thigh" + s, Vector3(-24, 0, 0))
				rig.add("knee" + s, Vector3(100, 0, 0))
				rig.add("hock" + s, Vector3(-106, 0, 0))
				rig.add("hpaw" + s, Vector3(66, 0, 0))
				rig.add("shoulder" + s, Vector3(34, 0, 0))
				rig.add("paw" + s, Vector3(2, 0, 0))
			rig.add("neck", Vector3(20, 0, 0))
			rig.add("head", Vector3(14 - look_up * 22, sin(_time * 0.55) * 14, sin(_time * 0.31) * 7))
			rig.add("tail1", Vector3(40, 0, 0))
			wag = 20.0
			wag_speed = 4.0
		"stand":
			rig.add("neck", Vector3(-look_up * 20, 0, 0))
			rig.add("head", Vector3(-look_up * 14 + 3, sin(_time * 0.8) * 8, 0))
		"walk", "sulk":
			var sulk := pose == "sulk"
			_phase += delta * speed / 0.42 * TAU
			var amp := clampf(speed / 1.4, 0.45, 1.0)
			for s: String in ["L", "R"]:
				var f := _phase + (0.0 if s == "L" else PI)
				quick["shoulder" + s] = Vector3(sin(f) * 28 * amp, 0, 0)
				quick["elbow" + s] = Vector3(maxf(0.0, -cos(f)) * -6 * amp, 0, 0)
				quick["paw" + s] = Vector3(maxf(0.0, -cos(f)) * 46 * amp, 0, 0)
				var b := f + PI
				quick["thigh" + s] = Vector3(sin(b) * 24 * amp, 0, 0)
				quick["knee" + s] = Vector3(maxf(0.0, -cos(b)) * 22 * amp, 0, 0)
				quick["hock" + s] = Vector3(maxf(0.0, -cos(b)) * -30 * amp, 0, 0)
			quick["spine"] = Vector3(0, sin(_phase) * 3, 0)
			quick["head"] = Vector3(sin(_phase * 2) * 3, 0, 0)
			ears = 8.0 + sin(_phase * 2) * 10 * amp
			if sulk:
				rig.add("neck", Vector3(34, 0, 0))
				rig.add("head", Vector3(18, 0, 0))
				rig.add("tail1", Vector3(-52, 0, 0))
				rig.add("tail2", Vector3(-18, 0, 0))
				lids = 30.0
				brows = 22.0
				ears = -4.0
				wag = 3.0
			else:
				rig.add("neck", Vector3(8, 0, 0))
				rig.add("tail1", Vector3(20, 0, 0))
				wag = 18.0
				wag_speed = 9.0
		"reach":
			var p := reach_progress
			rig.add("hips", Vector3(-44 - p * 6, 0, 0))
			for s: String in ["L", "R"]:
				rig.add("thigh" + s, Vector3(42, 0, 0))
				rig.add("knee" + s, Vector3(8, 0, 0))
				rig.add("hock" + s, Vector3(-4, 0, 0))
				rig.add("shoulder" + s, Vector3(-40, 0, 0))
				rig.add("elbow" + s, Vector3(-8, 0, 0))
				rig.add("paw" + s, Vector3(52, 0, 0))
			rig.add("neck", Vector3(28 + p * 20, 0, 0))
			rig.add("head", Vector3(24 - p * 14, 0, 0))
			rig.add("tail1", Vector3(8, 0, 0))
			quick["head"] = Vector3(0, sin(_time * 17) * 2.5 * p, 0)
			jaw = 6.0 + p * 20.0
			wag = 26.0
			wag_speed = 6.0 + p * 12.0
			ears = 10.0
		"crouch":
			for s: String in ["L", "R"]:
				rig.add("shoulder" + s, Vector3(-52, 0, 0))
				rig.add("elbow" + s, Vector3(-30, 0, 0))
				rig.add("paw" + s, Vector3(70, 0, 0))
				rig.add("thigh" + s, Vector3(-40, 0, 0))
				rig.add("knee" + s, Vector3(78, 0, 0))
				rig.add("hock" + s, Vector3(-72, 0, 0))
				rig.add("hpaw" + s, Vector3(36, 0, 0))
			rig.add("neck", Vector3(14, 0, 0))
			rig.add("head", Vector3(4, 0, 0))
			rig.add("tail1", Vector3(-10, 0, 0))
			wag = 8.0
			brows = 6.0
		"happy":
			var hop := absf(sin(_time * 9.0))
			position.y = hop * 0.09
			rig.add("neck", Vector3(-12, 0, 0))
			rig.add("head", Vector3(-8, 0, sin(_time * 9.0) * 12))
			rig.add("tail1", Vector3(35, 0, 0))
			for s: String in ["L", "R"]:
				rig.add("shoulder" + s, Vector3(-18 * hop, 0, 0))
				rig.add("paw" + s, Vector3(34 * hop, 0, 0))
			jaw = 22.0
			wag = 38.0
			wag_speed = 18.0
			ears = 22.0 * hop
		"surprised":
			rig.add("neck", Vector3(-8, 0, 0))
			rig.add("head", Vector3(-6, 0, 0))
			rig.add("tail1", Vector3(-30, 0, 0))
			jaw = 12.0
			brows = 26.0
			ears = 18.0
			wag = 0.0
	if sad and pose != "sulk":
		lids = 30.0
		brows = 24.0
		ears = -4.0
		wag *= 0.2
		rig.add("neck", Vector3(10, 0, 0))
		rig.add("head", Vector3(8, 0, 13 * tilt))
	if pose != "happy":
		position.y = 0.0
	if carrying and pose != "reach":
		jaw = 16.0
	if chewing:
		jaw = 8.0 + absf(sin(_time * 13.0)) * 20.0
		quick["head"] = quick.get("head", Vector3.ZERO) + Vector3(sin(_time * 13.0) * 3, 0, 0)
	rig.add("chest", Vector3(breathe * 0.8, 0, 0))
	quick["jaw"] = Vector3(jaw, 0, 0)
	quick["tail1"] = Vector3(0, sin(_time * wag_speed) * wag, 0)
	quick["tail2"] = Vector3(0, sin(_time * wag_speed - 0.9) * wag * 0.9, 0)
	quick["tail3"] = Vector3(0, sin(_time * wag_speed - 1.8) * wag * 0.8, 0)
	_blink -= delta
	if _blink < 0.0:
		_blink = randf_range(1.8, 5.0)
	var lid := 78.0 if _blink < 0.12 else lids
	for s: String in ["L", "R"]:
		var side := 1.0 if s == "L" else -1.0
		quick["lid" + s] = Vector3(lid, 0, 0)
		rig.add("brow" + s, Vector3(0, 0, -brows * side))
		rig.add("ear" + s, Vector3(0, 0, (ears + sin(_time * 1.3 + side) * 2.0) * side))
	rig.apply(delta, 13.0, quick)
	_plant_feet(delta)


## Pose les pattes au sol quelle que soit la posture.
func _plant_feet(delta: float) -> void:
	var feet: Array = HIND_FEET if pose == "reach" else FEET
	var low := INF
	for f: String in feet:
		low = minf(low, rig.position_of(f).y - rig.rest_position_of(f).y)
	_ground = lerpf(_ground, -low, 1.0 - exp(-delta * 30.0))
	model.position.y = _ground
	# Dressée, elle s'avance pour poser les pattes sur le meuble.
	model.position.z = lerpf(model.position.z, 0.06 if pose == "reach" else 0.0, 1.0 - exp(-delta * 10.0))
