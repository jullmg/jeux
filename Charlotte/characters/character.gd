class_name Character
extends Node2D
## Paper-cutout puppet assembled from CharacterArt parts: walk cycle, blinking, hair follow-through.

const BACK_TINT := Color(0.82, 0.82, 0.86)
const ARM_REST := deg_to_rad(6.0)

var look: CharacterLook
var walk_speed := 200.0
var is_walking := false
var walk_phase := 0.0
var facing := 1
var animate := true

var _rig: Dictionary
var _time := 0.0
var _body: Node2D
var _head: Node2D
var _torso: Sprite2D
var _lids: Sprite2D
var _hair_back: Sprite2D
var _leg_front: Sprite2D
var _leg_back: Sprite2D
var _arm_front: Sprite2D
var _arm_back: Sprite2D
var _hair_angle := 0.0
var _hair_vel := 0.0
var _blink_in := 2.0


func _ready() -> void:
	if look == null:
		look = CharacterLook.charlotte()
	var art := CharacterArt.build(look)
	_rig = art.rig
	var tex: Dictionary = art.tex
	var leg: float = _rig.leg_len
	var neck := Vector2(0, _rig.neck_y)
	_blink_in = randf_range(1.0, 4.0)
	_body = Node2D.new()
	_body.rotation = _rig.lean
	add_child(_body)
	# Children are drawn back to front.
	_hair_back = _part(_body, tex.hair_back, _rig.head_pivot, neck)
	_hair_back.scale = Vector2.ONE * (_rig.head_scale as float)
	_leg_back = _part(_body, tex.leg, _rig.leg_pivot, Vector2(_rig.leg_x, -leg), BACK_TINT)
	_arm_back = _part(_body, tex.arm, _rig.arm_pivot, Vector2(_rig.arm_x, _rig.shoulder_y), BACK_TINT)
	if tex.has("backpack"):
		_part(_body, tex.backpack, _rig.pack_pivot, Vector2(-30.0 * (_rig.sx as float), _rig.shoulder_y + 4.0))
	_leg_front = _part(_body, tex.leg, _rig.leg_pivot, Vector2(-(_rig.leg_x as float), -leg))
	_torso = _part(_body, tex.torso, _rig.torso_pivot, Vector2(0, _rig.torso_top))
	_head = Node2D.new()
	_head.position = neck
	_head.scale = Vector2.ONE * (_rig.head_scale as float)
	_body.add_child(_head)
	_part(_head, tex.head, _rig.head_pivot, Vector2.ZERO)
	_lids = _part(_head, tex.lids, _rig.head_pivot, Vector2.ZERO)
	_lids.visible = false
	_part(_head, tex.hair_front, _rig.head_pivot, Vector2.ZERO)
	_arm_front = _part(_body, tex.arm, _rig.arm_pivot, Vector2(-(_rig.arm_x as float), _rig.shoulder_y))
	_apply_pose()


func _draw() -> void:
	var w := 46.0 * float(_rig.get("sx", 1.0))
	draw_set_transform(Vector2(6, 2), 0.0, Vector2(1.0, 0.22))
	draw_circle(Vector2.ZERO, w, Color(0.15, 0.08, 0.05, 0.22))
	draw_circle(Vector2.ZERO, w * 0.6, Color(0.15, 0.08, 0.05, 0.12))


func _process(delta: float) -> void:
	if not animate:
		_apply_pose()
		return
	_time += delta
	if is_walking:
		# Longer legs take longer strides, so they swing more slowly for the same speed.
		walk_phase = fmod(walk_phase + delta * 1.6 * (walk_speed / 200.0) * (110.0 / (_rig.leg_len as float)), 1.0)
	_blink_in -= delta
	if _blink_in <= 0.0:
		_lids.visible = not _lids.visible
		_blink_in = 0.12 if _lids.visible else randf_range(1.8, 5.0)
	var target := 0.09 if is_walking else 0.0
	_hair_vel += ((target - _hair_angle) * 60.0 - _hair_vel * 7.0) * delta
	_hair_angle += _hair_vel * delta
	_apply_pose()


func _apply_pose() -> void:
	var swing := sin(walk_phase * TAU) if is_walking else 0.0
	_leg_front.rotation = deg_to_rad(26.0) * swing
	_leg_back.rotation = -_leg_front.rotation
	var arm_swing := deg_to_rad(22.0) * swing
	_arm_front.rotation = ARM_REST - arm_swing
	_arm_back.rotation = -ARM_REST + arm_swing
	_body.position.y = (1.0 - cos(_leg_front.rotation)) * (_rig.leg_len as float)
	var bounce := sin(walk_phase * TAU * 2.0)
	var tilt := bounce if is_walking else sin(_time * 2.2) * 0.6
	_head.rotation = deg_to_rad(2.0) * tilt
	_hair_back.rotation = _head.rotation + _hair_angle + (0.025 * bounce if is_walking else 0.0)
	_torso.skew = 0.035 * swing
	_body.scale.x = facing


func _part(parent: Node2D, tex: Texture2D, pivot: Vector2, pos: Vector2, tint := Color.WHITE) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = tex
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	sprite.centered = false
	sprite.offset = -pivot
	sprite.position = pos
	sprite.modulate = tint
	parent.add_child(sprite)
	return sprite
