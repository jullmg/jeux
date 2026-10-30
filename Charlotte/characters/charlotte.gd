class_name Charlotte
extends Node2D

const ART := "res://art/charlotte/"
const WALK_SPEED := 200.0
const BACK_TINT := Color(0.82, 0.82, 0.86)
const HEAD_PIVOT := Vector2(108, 196)
const NECK_POS := Vector2(0, -192)
const LEG_PIVOT := Vector2(20, 6)
const LEG_LENGTH := 110.0
const ARM_PIVOT := Vector2(15, 8)
const ARM_REST := deg_to_rad(6.0)

var is_walking := false
var walk_phase := 0.0
var facing := 1
var animate := true

var _time := 0.0
var _body: Node2D
var _head: Node2D
var _hair_back: Sprite2D
var _leg_front: Sprite2D
var _leg_back: Sprite2D
var _arm_front: Sprite2D
var _arm_back: Sprite2D


func _ready() -> void:
	_body = Node2D.new()
	add_child(_body)
	# Children are drawn back to front.
	_hair_back = _part(_body, "hair_back", HEAD_PIVOT, NECK_POS)
	_leg_back = _part(_body, "leg", LEG_PIVOT, Vector2(8, -LEG_LENGTH), BACK_TINT)
	_arm_back = _part(_body, "arm", ARM_PIVOT, Vector2(36, -182), BACK_TINT)
	_leg_front = _part(_body, "leg", LEG_PIVOT, Vector2(-8, -LEG_LENGTH))
	_part(_body, "torso", Vector2(65, 100), Vector2(0, -100))
	_head = Node2D.new()
	_head.position = NECK_POS
	_body.add_child(_head)
	_part(_head, "head", HEAD_PIVOT, Vector2.ZERO)
	_part(_head, "hair_front", HEAD_PIVOT, Vector2.ZERO)
	_arm_front = _part(_body, "arm", ARM_PIVOT, Vector2(-36, -182))
	_apply_pose()


func _process(delta: float) -> void:
	if animate:
		_time += delta
		if is_walking:
			walk_phase = fmod(walk_phase + delta * 1.6, 1.0)
	_apply_pose()


func _apply_pose() -> void:
	var swing := sin(walk_phase * TAU) if is_walking else 0.0
	_leg_front.rotation = deg_to_rad(26.0) * swing
	_leg_back.rotation = -_leg_front.rotation
	var arm_swing := deg_to_rad(22.0) * swing
	_arm_front.rotation = ARM_REST - arm_swing
	_arm_back.rotation = -ARM_REST + arm_swing
	_body.position.y = (1.0 - cos(_leg_front.rotation)) * LEG_LENGTH
	var tilt := sin(walk_phase * TAU * 2.0) if is_walking else sin(_time * 2.2) * 0.6
	_head.rotation = deg_to_rad(2.0) * tilt
	_hair_back.rotation = _head.rotation
	_body.scale.x = facing


func _part(parent: Node2D, art: String, pivot: Vector2, pos: Vector2, tint := Color.WHITE) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = load(ART + art + ".svg")
	sprite.centered = false
	sprite.offset = -pivot
	sprite.position = pos
	sprite.modulate = tint
	parent.add_child(sprite)
	return sprite
