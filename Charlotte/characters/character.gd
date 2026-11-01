class_name Character
extends Node2D
## Paper-cutout puppet assembled from CharacterArt parts: walk/run cycle, blinking, hair follow-through.

const BACK_TINT := Color(0.82, 0.82, 0.86)
const ARM_REST := deg_to_rad(6.0)
## Running speed, as a multiple of walk_speed.
const RUN_SPEED := 1.9

var look: CharacterLook
var walk_speed := 200.0
var is_walking := false
## While walking, blends into a run (faster, longer strides, leaning forward).
var running := false
## Footstep sound (a Sfx name) played at each step; empty = silent (passersby).
var step_sound := ""
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
var _pet_time := 0.0
var _pet := 0.0
var _pet_low := 1.0
var _run := 0.0
var _held: Node2D
var _hold := 0.0


func _ready() -> void:
	if look == null:
		look = CharacterLook.charlotte()
	_blink_in = randf_range(1.0, 4.0)
	_build()


## Dresses the puppet in a new look: rebuilds every body part.
func set_look(new_look: CharacterLook) -> void:
	look = new_look
	if _body:
		remove_child(_body)
		_body.queue_free()
	_build()
	queue_redraw()


func _build() -> void:
	var art := CharacterArt.build(look)
	_rig = art.rig
	var tex: Dictionary = art.tex
	var leg: float = _rig.leg_len
	var neck := Vector2(0, _rig.neck_y)
	_body = Node2D.new()
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


# Contact shadow, plus a longer soft one thrown to the right by the low sun on the left.
func _draw() -> void:
	var w := 50.0 * float(_rig.get("sx", 1.0))
	draw_set_transform(Vector2(w * 0.9, 3), 0.0, Vector2(1.9, 0.2))
	draw_circle(Vector2.ZERO, w, Color(0.15, 0.08, 0.05, 0.12))
	draw_set_transform(Vector2(6, 2), 0.0, Vector2(1.0, 0.22))
	draw_circle(Vector2.ZERO, w * 1.15, Color(0.15, 0.08, 0.05, 0.16))
	draw_circle(Vector2.ZERO, w * 0.75, Color(0.15, 0.08, 0.05, 0.22))
	draw_circle(Vector2.ZERO, w * 0.4, Color(0.15, 0.08, 0.05, 0.18))


## Strokes whatever is in front of her for `duration` seconds. `low` 1 = deep lunge (cats, small dogs),
## 0 = standing with the arm held out (big dogs).
func pet(duration: float, low := 1.0) -> void:
	_pet_time = duration
	_pet_low = low
	is_walking = false


func is_petting() -> bool:
	return _pet_time > 0.0


func hand_position() -> Vector2:
	return _arm_front.to_global(Vector2(0, _rig.arm_len))


## Current ground speed, easing between walking and running.
## Carries `thing` in her arms (a cat): both arms come round it and it rides on her body, between her arms.
## carry(null) puts it down (frees it).
func carry(thing: Node2D) -> void:
	if _held and is_instance_valid(_held):
		_held.queue_free()
	_held = thing
	if thing:
		thing.position = Vector2((_rig.arm_len as float) * 0.62, (_rig.shoulder_y as float) + (_rig.arm_len as float) * 0.62)
		_body.add_child(thing)
		_body.move_child(thing, _arm_front.get_index())


func is_holding() -> bool:
	return _held != null and is_instance_valid(_held)


func speed() -> float:
	return walk_speed * lerpf(1.0, RUN_SPEED, _run)


func _process(delta: float) -> void:
	if not animate:
		_apply_pose()
		return
	_time += delta
	_pet_time = maxf(_pet_time - delta, 0.0)
	_pet = move_toward(_pet, 1.0 if _pet_time > 0.0 else 0.0, delta * 4.0)
	_run = move_toward(_run, 1.0 if running and is_walking else 0.0, delta * 3.0)
	_hold = move_toward(_hold, 1.0 if is_holding() else 0.0, delta * 4.0)
	if is_walking:
		# Longer legs take longer strides, so they swing more slowly for the same speed.
		# A run is a faster cadence plus longer strides (wider swing), which together make up RUN_SPEED.
		var before := walk_phase
		walk_phase = fmod(walk_phase + delta * 1.6 * lerpf(1.0, 1.35, _run) * (walk_speed / 200.0) * (110.0 / (_rig.leg_len as float)), 1.0)
		# A footstep each time a foot lands (twice a cycle).
		if step_sound != "" and floori(before * 2.0) != floori(walk_phase * 2.0):
			Sfx.play(step_sound, global_position, -8.0)
	_blink_in -= delta
	if _blink_in <= 0.0:
		_lids.visible = not _lids.visible
		_blink_in = 0.12 if _lids.visible else randf_range(1.8, 5.0)
	var target := lerpf(0.09, 0.2, _run) if is_walking else 0.0
	_hair_vel += ((target - _hair_angle) * 60.0 - _hair_vel * 7.0) * delta
	_hair_angle += _hair_vel * delta
	_apply_pose()


func _apply_pose() -> void:
	var swing := sin(walk_phase * TAU) if is_walking else 0.0
	# Petting: lunge down to the animal's height (deep for cats), lean in and stroke with the front hand.
	var lunge := deg_to_rad(lerpf(8.0, 55.0, _pet_low)) * _pet
	var stride := deg_to_rad(lerpf(26.0, 38.0, _run))
	_leg_front.rotation = stride * swing - lunge
	_leg_back.rotation = -stride * swing + lunge
	var arm_swing := deg_to_rad(lerpf(22.0, 48.0, _run)) * swing
	var stroke := deg_to_rad(lerpf(-82.0, -62.0, _pet_low)) + sin(_time * 6.0) * deg_to_rad(12.0)
	_arm_front.rotation = lerpf(lerpf(ARM_REST - arm_swing, stroke, _pet), deg_to_rad(-58.0), _hold)
	_arm_back.rotation = lerpf(-ARM_REST + arm_swing, deg_to_rad(-72.0), _hold)
	var bounce := sin(walk_phase * TAU * 2.0)
	# Running: a little hop at each push-off instead of the walk's dip.
	_body.position.y = (1.0 - cos(_leg_front.rotation)) * (_rig.leg_len as float) * (1.0 - _run) - absf(bounce) * 6.0 * _run
	_body.rotation = ((_rig.lean as float) + deg_to_rad(10.0) * _pet + deg_to_rad(9.0) * _run) * facing
	var tilt := bounce if is_walking else sin(_time * 2.2) * 0.6
	_head.rotation = deg_to_rad(2.0) * tilt + deg_to_rad(10.0) * _pet - deg_to_rad(4.0) * _run
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
