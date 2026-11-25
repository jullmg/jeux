class_name Rig
extends RefCounted
## Anime un squelette par code : des rotations exprimées dans les axes du modèle, lissées d'une image à l'autre.
## x : pencher (positif = le museau ou le haut va vers l'avant-bas), y : tourner, z : rouler. Angles en degrés.

var skeleton: Skeleton3D
var bones: Dictionary = {}          # nom → indice
var _rest_rot: Dictionary = {}      # rotation de repos locale
var _axes: Dictionary = {}          # base de repos dans l'espace du modèle
var current: Dictionary = {}        # nom → Vector3 lissé
var target: Dictionary = {}


func _init(model: Node3D) -> void:
	var found := model.find_children("*", "Skeleton3D", true, false)
	assert(not found.is_empty(), "modèle sans squelette")
	skeleton = found[0]
	var to_model := Basis.IDENTITY
	var n: Node = skeleton
	while n != model and n is Node3D:
		to_model = (n as Node3D).transform.basis * to_model
		n = n.get_parent()
	for i in skeleton.get_bone_count():
		var name := skeleton.get_bone_name(i)
		bones[name] = i
		_rest_rot[name] = skeleton.get_bone_rest(i).basis.get_rotation_quaternion()
		_axes[name] = (to_model * skeleton.get_bone_global_rest(i).basis).orthonormalized()
		current[name] = Vector3.ZERO


## Repart d'une pose neutre ; les poses s'additionnent ensuite avec add().
func begin() -> void:
	target = {}


func add(bone: String, degrees: Vector3) -> void:
	target[bone] = target.get(bone, Vector3.ZERO) + degrees


## `quick` : os qui suivent sans lissage (cycles de marche, mâchouillage).
func apply(delta: float, speed := 12.0, quick: Dictionary = {}) -> void:
	var f := 1.0 - exp(-delta * speed)
	for name: String in bones:
		var goal: Vector3 = target.get(name, Vector3.ZERO)
		var now: Vector3 = current[name].lerp(goal, f)
		current[name] = now
		var shown: Vector3 = now + quick.get(name, Vector3.ZERO)
		var turn := Basis.from_euler(Vector3(deg_to_rad(shown.x), deg_to_rad(shown.y), deg_to_rad(shown.z)))
		var axes: Basis = _axes[name]
		var local := axes.inverse() * turn * axes
		skeleton.set_bone_pose_rotation(bones[name], _rest_rot[name] * local.get_rotation_quaternion())


## Position actuelle d'un os, dans l'espace du squelette.
func position_of(bone: String) -> Vector3:
	return skeleton.get_bone_global_pose(bones[bone]).origin


func rest_position_of(bone: String) -> Vector3:
	return skeleton.get_bone_global_rest(bones[bone]).origin
