class_name Character
extends Node2D
## Paper-cutout puppet assembled from CharacterArt parts: walk/run cycle, blinking, hair follow-through.

const BACK_TINT := Color(0.82, 0.82, 0.86)
const ARM_REST := deg_to_rad(6.0)
## How far a rider leans forward over the bars (degrees).
const RIDE_LEAN := 16.0
## Running speed, as a multiple of walk_speed.
const RUN_SPEED := 1.9
## Expressions: [eyes, brows, mouth] (the kinds in CharacterArt.EYE_KINDS / BROW_KINDS / MOUTH_KINDS; "talk" cycles the talking mouths).
const EXPRESSIONS := {
	"normal": ["normal", "normal", "smile"], "happy": ["happy", "raised_small", "grin"], "grin": ["normal", "raised_small", "grin"],
	"yum": ["happy", "normal", "yum"], "laugh": ["happy", "raised", "laugh"], "focus": ["squint", "low", "flat"],
	"effort": ["squint", "furrow", "grin"], "surprised": ["wide", "raised", "open"], "wonder": ["wide", "raised_small", "pursed"],
	"sad": ["sad", "sad", "sad"], "worry": ["normal", "sad", "worry"], "sleep": ["closed", "normal", "sleep"],
	"yawn": ["closed", "raised_small", "yawn"], "talk": ["normal", "normal", "talk"], "sip": ["normal", "normal", "pursed"],
	"blank": ["normal", "normal", "flat"],
}
const SIT_THIGH := -88.0
## Half the thickness of a thigh, the bit of her that is below the hip when she sits.
const SIT_THICK := 7.0
## What the face does while a chore goes on.
const TASK_FACES := {"piano": "happy", "pottery": "focus", "bike": "focus", "jog": "effort", "stir": "happy", "read": "focus", "phone": "talk", "type": "focus", "wash": "focus", "drink": "normal", "fridge": "wonder",
	"exercise": "effort", "watch": "happy", "daydream": "blank"}

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
## The legs, back one first: thigh (a Sprite2D at the hip; `_leg_front` / `_leg_back`, its `rotation` is the hip angle) and shin with
## its shoe (child, at the knee; its `rotation` is the knee's flex, the lower leg folding back).
var _leg_front: Sprite2D
var _leg_back: Sprite2D
var _shin_front: Sprite2D
var _shin_back: Sprite2D
## The arms, back one first: upper arm (a Sprite2D at the shoulder), forearm (its child, at the elbow) and hand (the forearm's
## child, at the wrist). `_arm_front` / `_arm_back` are the upper arms; the shoulder angle is their `rotation`, the elbow's flex
## is `_elbow` (radians, the forearm folding forward and up), and the hand's picture is chosen by `_hand_goal`.
var _arms: Array[Sprite2D] = []
var _fores: Array[Sprite2D] = []
var _hands: Array[Sprite2D] = []
var _arm_front: Sprite2D
var _arm_back: Sprite2D
var _hand_tex := {}
var _elbow := [0.14, 0.14]
var _elbow_goal := [0.14, 0.14]
var _hand_goal := ["relaxed", "relaxed"]
var _snap := [false, false]
var _dt := 0.016
var _hair_angle := 0.0
var _hair_vel := 0.0
var _blink_in := 2.0
var _pet_time := 0.0
var _pet := 0.0
var _pet_low := 1.0
var _run := 0.0
var _held: Node2D
var _hold := 0.0
## 0..1: lifts what she carries up in front of her, her hands on its `carry_grip` (to pour the watering can).
var carry_lift := 0.0
## Where her hands hold what she carries, in its own space (a handle); used while lifting.
var carry_grip := Vector2.ZERO
var _held_base := Vector2.ZERO
## Sitting on a bicycle: leaning forward, hands on the bars, legs turning with `pedal` (the crank's angle).
var riding := false
var pedal := 0.0
## Riding: where the two pedals are (global, back leg's first) and the handlebar grip, set by the bike each frame.
var pedal_feet: Array[Vector2] = []
var bar_grip := Vector2.INF
## Little idle gestures when she stands still a while (Charlotte, her parents): a wave, a hop, a stretch, a look round.
var fidgets := false
## The front hand's shape when it has nothing special to do ("grip" for a passerby holding a leash, say); "" = relaxed.
var hand_mode := ""
## A chore she is doing in place (a family member's routine): "stir", "read", "phone", "type", "wash", "drink", "fridge",
## "exercise", "watch" or "daydream" (Dad gazing at nothing); "" = none. Poses the arms and head; the routine adds the prop in her hand.
var task := ""
## Where the hands work, in world coordinates (front hand first, back hand second): the bowl on the table, the keys, the clay. Set by
## a family routine; a task with no points uses the old fixed arm angles.
var work: Array[Vector2] = []
## Sitting down (a sofa, a bench, a stool): the thighs go forward, the lower legs hang, the hips rest `seat_h` world px above the floor
## (0 = the feet stay on the floor, a chair her size; a taller seat leaves her feet dangling). Eased in and out through `_sit`.
var sitting := false
var seat_h := 0.0
var _sit := 0.0
## The floor under the seat (world y), when the seat is further back than where she walks: she steps back to it as she sits.
var seat_floor := NAN
var _stand_y := NAN
## Which idle gestures she may do (a shopkeeper just looks round and stretches).
var fidget_moves: Array[String] = ["wave", "hop", "stretch", "look", "look"]
## The face: `expression` forces one ("" = whatever she is doing, see `_auto_expression`); `express(name, seconds)` shows one for a moment
## (talking, a treat, an oops). Each is an eyes + brows + mouth picture (`EXPRESSIONS`), swapped on the face layers.
var expression := ""
var _express_name := ""
var _express_left := 0.0
var _art: CharacterArt
var _eyes_spr: Sprite2D
var _brows_spr: Sprite2D
var _mouth_spr: Sprite2D
var _face_now := ["", "", ""]
var _shade: ShaderMaterial
var _idle := 0.0
var _gesture := ""
var _gesture_t := 0.0
var _gesture_len := 1.0
var _next_gesture := 6.0


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
	_art = art.art
	_rig = art.rig
	_shade = ShaderMaterial.new()
	_shade.shader = preload("res://shaders/character_shade.gdshader")
	var tex: Dictionary = art.tex
	var leg: float = _rig.leg_len
	var neck := Vector2(0, _rig.neck_y)
	_body = Node2D.new()
	add_child(_body)
	# Children are drawn back to front.
	_hair_back = _part(_body, tex.hair_back, _rig.head_pivot, neck)
	_hair_back.scale = Vector2.ONE * (_rig.head_scale as float)
	_leg_back = _part(_body, tex.thigh, _rig.leg_pivot, Vector2(_rig.leg_x, -leg), BACK_TINT)
	_shin_back = _part(_leg_back, tex.shin, _rig.shin_pivot, Vector2(0, (_rig.knee_y as float) - (_rig.leg_pivot.y as float)))
	_hand_tex = {"relaxed": tex.hand_relaxed, "open": tex.hand_open, "flat": tex.hand_flat, "grip": tex.hand_grip}
	_arms = []
	_fores = []
	_hands = []
	_arm_back = _make_arm(tex, Vector2(_rig.arm_x, _rig.shoulder_y), BACK_TINT)
	if tex.has("backpack"):
		_part(_body, tex.backpack, _rig.pack_pivot, Vector2(-30.0 * (_rig.sx as float), _rig.shoulder_y + 4.0))
	_leg_front = _part(_body, tex.thigh, _rig.leg_pivot, Vector2(-(_rig.leg_x as float), -leg))
	_shin_front = _part(_leg_front, tex.shin, _rig.shin_pivot, Vector2(0, (_rig.knee_y as float) - (_rig.leg_pivot.y as float)))
	_torso = _part(_body, tex.torso, _rig.torso_pivot, Vector2(0, _rig.torso_top))
	_head = Node2D.new()
	_head.position = neck
	_head.scale = Vector2.ONE * (_rig.head_scale as float)
	_body.add_child(_head)
	_part(_head, tex.head, _rig.head_pivot, Vector2.ZERO)
	_eyes_spr = _face_part("eyes", "normal")
	if look.glasses != "":
		_face_part("glasses", "")
	_lids = _part(_head, tex.lids, _rig.head_pivot, Vector2.ZERO)
	_lids.visible = false
	_brows_spr = _face_part("brows", "normal")
	_mouth_spr = _face_part("mouth", "smile")
	_face_now = ["normal", "normal", "smile"]
	_part(_head, tex.hair_front, _rig.head_pivot, Vector2.ZERO)
	_arm_front = _make_arm(tex, Vector2(-(_rig.arm_x as float), _rig.shoulder_y), Color.WHITE)
	_apply_pose()


# One face layer (eyes, brows, mouth, glasses) as a child of the head, in its place on the face.
func _face_part(layer: String, kind: String) -> Sprite2D:
	return _part(_head, _art.face_texture(layer, kind), Vector2.ZERO, CharacterArt.face_offset(layer))


## Shows `name` (a key of EXPRESSIONS) on her face for `seconds`: "talk" while she says something, "yum" for a treat, "worry" for an oops.
func express(name: String, seconds := 2.0) -> void:
	if EXPRESSIONS.has(name):
		_express_name = name
		_express_left = seconds


# What her face says by itself, from what she is doing.
func _auto_expression() -> String:
	if _express_left > 0.0:
		return _express_name
	if expression != "":
		return expression
	if task != "":
		if task == "drink" and fmod(_time, 5.0) > 0.8 and fmod(_time, 5.0) < 1.9:
			return "sip"
		return TASK_FACES.get(task, "normal")
	if _gesture == "wave" or _gesture == "hop":
		return "happy"
	if _gesture == "stretch":
		return "yawn"
	if _pet > 0.5:
		return "happy"
	if carry_lift > 0.5:
		return "focus"
	if is_holding():
		return str(_held.get_meta("face", "normal"))
	if _run > 0.5:
		return "grin"
	return "normal"


# Puts the face for this moment on the eyes, brows and mouth layers (swapping a picture only when it changes).
func _update_face() -> void:
	var parts: Array = EXPRESSIONS[_auto_expression()]
	var mouth: String = parts[2]
	if mouth == "talk":
		mouth = ["talk_b", "talk_a", "talk_c", "talk_a"][int(_time * 8.0) % 4]
	var want := [parts[0], parts[1], mouth]
	var layers := [[_eyes_spr, "eyes"], [_brows_spr, "brows"], [_mouth_spr, "mouth"]]
	for i in 3:
		if _face_now[i] != want[i]:
			_face_now[i] = want[i]
			(layers[i][0] as Sprite2D).texture = _art.face_texture(layers[i][1], want[i])
	# Eyes that are shut or smiling shut stay that way: no blink on top.
	if want[0] == "closed" or want[0] == "happy":
		_lids.visible = false


# Contact shadow, plus a longer soft one thrown to the right by the low sun on the left.
func _draw() -> void:
	# On a bike the feet are off the ground; the bike throws the shadow.
	if riding:
		return
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
	return _hands[1].to_global(Vector2(0, _rig.hand_center))


# An arm chain in the body: the upper arm at the shoulder, the forearm at its elbow, the hand at the wrist. Returns the upper arm.
func _make_arm(tex: Dictionary, shoulder: Vector2, tint: Color) -> Sprite2D:
	var upper := _part(_body, tex.upper, _rig.arm_pivot, shoulder, tint)
	var fore := _part(upper, tex.fore, _rig.arm_pivot, Vector2(0, _rig.upper_len))
	var hand := _part(fore, tex.hand_relaxed, _rig.hand_pivot, Vector2(0, _rig.fore_len))
	_arms.append(upper)
	_fores.append(fore)
	_hands.append(hand)
	return upper


## Current ground speed, easing between walking and running.
## Carries `thing` in her arms (a cat): both arms come round it and it rides on her body, between her arms.
## carry(null) puts it down (frees it).
func carry(thing: Node2D) -> void:
	# One thing in her arms at a time: whoever hands her something checks `Carry.busy()` first. If one forgets, the new thing
	# is dropped (and reported) rather than silently replacing what she holds.
	if thing and is_holding() and thing != _held:
		push_warning("Character.carry: her arms are already full (%s); ask Carry.busy() before giving her something." % _held.name)
		thing.queue_free()
		return
	if _held and is_instance_valid(_held):
		_held.queue_free()
	_held = thing
	if thing:
		thing.position = Vector2((_rig.arm_len as float) * 0.62, (_rig.shoulder_y as float) + (_rig.arm_len as float) * 0.62)
		_held_base = thing.position
		_body.add_child(thing)
		_body.move_child(thing, _arm_front.get_index())


## What she holds in her arms, or null.
func held() -> Node2D:
	return _held if is_holding() else null


func is_holding() -> bool:
	return _held != null and is_instance_valid(_held)


## Puts `node` into the puppet between its far and near legs (a bike's frame), in the puppet's parent's space. The
## riding pose is fixed, so the node's transform is set once.
func add_between_legs(node: Node2D) -> void:
	_body.add_child(node)
	_body.move_child(node, _leg_front.get_index())
	node.transform = (transform * _body.transform).affine_inverse()


# On a bike: each foot on its pedal going round in front of and below the hip, the knee bending forward (two-bone IK on the thigh and
# the shin).
func _pedal_legs() -> void:
	var leg_len: float = _rig.leg_len
	var thigh_len := leg_len * 0.5 - 6.0
	var shin_len := leg_len * 0.5
	for k in 2:
		var thigh := _leg_back if k == 0 else _leg_front
		var shin := _shin_back if k == 0 else _shin_front
		var hip := thigh.position
		var foot: Vector2
		if pedal_feet.size() == 2:
			foot = _body.to_local(pedal_feet[k])
		else:
			foot = hip + Vector2(leg_len * 0.42, leg_len * 0.62) + Vector2.from_angle(pedal + (PI if k == 0 else 0.0)) * leg_len * 0.2
		var to_foot := foot - hip
		var d := clampf(to_foot.length(), absf(thigh_len - shin_len) + 1.0, thigh_len + shin_len - 1.0)
		var dir := to_foot.normalized()
		var along := (thigh_len * thigh_len - shin_len * shin_len + d * d) / (2.0 * d)
		var up := sqrt(maxf(thigh_len * thigh_len - along * along, 0.0))
		# Of the two ways the knee could bend, the one forward (toward +x, where she faces in body space).
		var knee_a := hip + dir * along + dir.orthogonal() * up
		var knee_b := hip + dir * along - dir.orthogonal() * up
		var knee := knee_a if knee_a.x > knee_b.x else knee_b
		var thigh_angle := atan2(-(knee - hip).x, (knee - hip).y)
		thigh.rotation = thigh_angle
		shin.rotation = atan2(-(hip + dir * d - knee).x, (hip + dir * d - knee).y) - thigh_angle


# Standing still a while, now and then: one little gesture, then back to rest.
func _fidget(delta: float) -> void:
	if _gesture != "":
		_gesture_t -= delta
		if _gesture_t <= 0.0 or is_walking or is_petting():
			_gesture = ""
		return
	if not fidgets or is_walking or is_petting() or is_holding():
		_idle = 0.0
		_next_gesture = randf_range(5.0, 9.0)
		return
	_idle += delta
	if _idle >= _next_gesture:
		_gesture = fidget_moves[randi() % fidget_moves.size()]
		_gesture_len = {"wave": 1.6, "hop": 0.9, "stretch": 1.4, "look": 2.2}[_gesture]
		_gesture_t = _gesture_len
		_next_gesture = _idle + randf_range(7.0, 14.0)


func speed() -> float:
	return walk_speed * lerpf(1.0, RUN_SPEED, _run)


func _process(delta: float) -> void:
	if not animate:
		_sit = 1.0 if sitting else 0.0
		_apply_pose()
		return
	_time += delta
	_sit = move_toward(_sit, 1.0 if sitting else 0.0, delta * 3.5)
	if sitting and is_nan(_stand_y):
		_stand_y = position.y
	if not is_nan(_stand_y) and not is_nan(seat_floor):
		position.y = lerpf(_stand_y, seat_floor, _sit)
		if _sit <= 0.0 and not sitting:
			_stand_y = NAN
	_dt = delta
	_express_left = maxf(_express_left - delta, 0.0)
	_pet_time = maxf(_pet_time - delta, 0.0)
	_pet = move_toward(_pet, 1.0 if _pet_time > 0.0 else 0.0, delta * 4.0)
	_run = move_toward(_run, 1.0 if running and is_walking else 0.0, delta * 3.0)
	_hold = move_toward(_hold, 1.0 if is_holding() else 0.0, delta * 4.0)
	_fidget(delta)
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
		_lids.visible = not _lids.visible and _face_now[0] != "closed" and _face_now[0] != "happy"
		_blink_in = 0.12 if _lids.visible else randf_range(1.8, 5.0)
	# The hair trails BEHIND her (a negative angle: a positive one swept it forward over her shoulder as she ran).
	var target := -lerpf(0.07, 0.26, _run) if is_walking else 0.0
	_hair_vel += ((target - _hair_angle) * 60.0 - _hair_vel * 7.0) * delta
	_hair_angle += _hair_vel * delta
	_apply_pose()


func _apply_pose() -> void:
	_update_face()
	var swing := sin(walk_phase * TAU) if is_walking else 0.0
	# Petting: lunge down to the animal's height (deep for cats), lean in and stroke with the front hand.
	var lunge := deg_to_rad(lerpf(8.0, 55.0, _pet_low)) * _pet
	var stride := deg_to_rad(lerpf(26.0, 38.0, _run))
	_leg_front.rotation = stride * swing - lunge
	_leg_back.rotation = -stride * swing + lunge
	_knees(swing, lunge)
	_sit_legs()
	# Shoulders at their usual places and arms their usual length (riding moves and stretches them below).
	_arm_back.position = Vector2(_rig.arm_x, _rig.shoulder_y)
	_arm_front.position = Vector2(-(_rig.arm_x as float), _rig.shoulder_y)
	for i in 2:
		_arms[i].scale.y = 1.0
		_hands[i].scale.y = 1.0
	var arm_swing := deg_to_rad(lerpf(22.0, 48.0, _run)) * swing
	var stroke := deg_to_rad(lerpf(-82.0, -62.0, _pet_low)) + sin(_time * 6.0) * deg_to_rad(12.0)
	_arm_front.rotation = lerpf(ARM_REST - arm_swing, stroke, _pet)
	_arm_back.rotation = -ARM_REST + arm_swing
	_arms_rest(swing)
	# Stroking: the hand reaches where the straight arm used to (the arm nearly out, the forearm sweeping to and fro), flat.
	if _pet > 0.0:
		var out := Vector2(-sin(stroke), cos(stroke)) * (_rig.arm_len as float) * 0.95
		_reach_blend(1, _arm_front.position + out + Vector2(0, sin(_time * 6.0 + 1.2) * 4.0), _pet, false)
	if _pet > 0.3:
		_hand_goal[1] = "flat"
	# Carrying something in her arms: both hands reach round it.
	if _hold > 0.0 and is_holding():
		var hands: String = _held.get_meta("hands", "grip")
		_reach_blend(0, _arm_back.position + Vector2.from_angle(deg_to_rad(18.0)) * (_rig.arm_len as float) * 0.86, _hold, false)
		_reach_blend(1, _arm_front.position + Vector2.from_angle(deg_to_rad(32.0)) * (_rig.arm_len as float) * 0.86, _hold, false)
		if _hold > 0.5:
			_hand_goal[0] = hands
			_hand_goal[1] = hands
	if carry_lift > 0.0 and is_holding():
		var arm: float = _rig.arm_len
		_held.position = _held_base + Vector2(arm * 0.05, -arm * 0.7) * carry_lift
		var grip := _held.transform * carry_grip
		for i in 2:
			_reach_blend(i, grip, carry_lift, true)
		if carry_lift > 0.5:
			_hand_goal[0] = "grip"
			_hand_goal[1] = "grip"
	var bounce := sin(walk_phase * TAU * 2.0)
	# Running: a little hop at each push-off instead of the walk's dip.
	_body.position.y = _stance_drop() * (1.0 - _run) - absf(bounce) * 6.0 * _run - _sit_lift() * _sit
	_body.rotation = ((_rig.lean as float) + deg_to_rad(10.0) * _pet + deg_to_rad(9.0) * _run) * facing
	var tilt := bounce if is_walking else sin(_time * 2.2) * 0.6
	_head.rotation = deg_to_rad(2.0) * tilt + deg_to_rad(10.0) * _pet - deg_to_rad(4.0) * _run
	_torso.skew = 0.035 * swing
	_body.scale.x = facing
	# Something with writing on it (the milk carton) is not mirrored with her body when she turns to the left.
	if is_holding() and _held.has_meta("keep_upright"):
		_held.scale.x = absf(_held.scale.x) * facing
	if _shade:
		_shade.set_shader_parameter("facing", float(facing))
	if riding:
		_body.rotation = deg_to_rad(RIDE_LEAN) * facing
		_body.position.y = 0.0
		_head.rotation = deg_to_rad(-10.0)
		_pedal_legs()
		_follow_head()
		# Hands on the bars: each arm reaches the grip, elbows bent and pointing down. Seen from the side the shoulders are not ±36 px
		# apart, so a shoulder that is too far from the grip slides forward along the chest to reach it, and only if that is still not
		# enough does the arm stretch a little.
		var span := (_rig.upper_len as float) + (_rig.fore_len as float) + (_rig.hand_center as float)
		for i in 2:
			var shoulder := Vector2((_rig.arm_x as float) * (1.0 if i == 0 else -1.0), _rig.shoulder_y)
			var target := _body.to_local(bar_grip) if bar_grip != Vector2.INF else shoulder + Vector2.from_angle(deg_to_rad(38.0)) * span * 0.8
			var slide := clampf((target - shoulder).length() - span * 0.95, 0.0, (_rig.arm_x as float) * 2.0)
			shoulder.x += slide * signf(target.x - shoulder.x)
			_arms[i].position = shoulder
			var reach := _ik(_arms[i], target)
			_arms[i].rotation = reach.x
			_elbow_goal[i] = reach.y
			_snap[i] = true
			_hand_goal[i] = "grip"
			var stretch := maxf((target - shoulder).length() / span, 1.0)
			_arms[i].scale.y = stretch
			_hands[i].scale.y = 1.0 / stretch
		_finish_arms()
		return
	# Breathing while she stands, and the idle gesture on top.
	var still := 0.0 if is_walking else 1.0
	_torso.scale.y = 1.0 + 0.014 * sin(_time * 2.1) * still
	_head.position.y = float(_rig.neck_y) - 1.2 * sin(_time * 2.1) * still
	if _gesture != "":
		var t := 1.0 - _gesture_t / _gesture_len
		var w := sin(PI * clampf(t, 0.0, 1.0))
		match _gesture:
			"wave":
				# The arm up beside her head, the forearm swinging from side to side at the elbow, the hand open.
				_arm_front.rotation = lerpf(_arm_front.rotation, deg_to_rad(-172.0), w)
				_elbow_goal[1] = lerpf(_elbow_goal[1], deg_to_rad(30.0) + sin(_time * 13.0) * deg_to_rad(24.0), w)
				_hand_goal[1] = "open"
			"hop":
				_body.position.y -= absf(sin(t * TAU)) * 16.0 * w
				# Knees tucked while she is in the air.
				var tuck := absf(sin(t * TAU)) * 0.7 * w
				_shin_front.rotation += tuck
				_shin_back.rotation += tuck
			"stretch":
				_arm_front.rotation = lerpf(_arm_front.rotation, deg_to_rad(-165.0), w)
				_arm_back.rotation = lerpf(_arm_back.rotation, deg_to_rad(-160.0), w)
				_elbow_goal[0] = lerpf(_elbow_goal[0], deg_to_rad(14.0), w)
				_elbow_goal[1] = lerpf(_elbow_goal[1], deg_to_rad(14.0), w)
				_hand_goal[0] = "open"
				_hand_goal[1] = "open"
				_torso.scale.y += 0.03 * w
			"look":
				_head.rotation += sin(t * TAU) * 0.18 * w
	if task != "":
		_task_pose()
	if hand_mode != "" and _hand_goal[1] == "relaxed":
		_hand_goal[1] = hand_mode
	_follow_head()
	_finish_arms()


# The knees: a little bend at rest, the leg that swings forward folds its lower leg up under it (more when running). In a lunge
# (petting) both legs stay straight and symmetrical, so both feet stay on the ground.
func _knees(swing: float, _lunge: float) -> void:
	var phase := walk_phase * TAU
	var fwd_front := maxf(-cos(phase), 0.0) if is_walking else 0.0
	var fwd_back := maxf(cos(phase), 0.0) if is_walking else 0.0
	var walk_flex := deg_to_rad(lerpf(40.0, 74.0, _run))
	var base := deg_to_rad(3.0)
	_shin_front.rotation = base + walk_flex * fwd_front
	_shin_back.rotation = base + walk_flex * fwd_back


## True while she is sitting or still getting up (she should not walk yet).
func is_seated() -> bool:
	return _sit > 0.35


## 0 standing, 1 fully settled in the seat: what is drawn in front of the seat waits for 1 so it never cuts across her on the way in.
func seated_amount() -> float:
	return _sit


# Seated: the thighs forward (horizontal), the lower legs hanging, swinging a little when the seat is high.
func _sit_legs() -> void:
	if _sit <= 0.0:
		return
	var dangle := minf(_sit_lift() / 40.0, 1.0)
	var swing := sin(_time * 2.4) * deg_to_rad(9.0) * dangle
	_leg_front.rotation = lerpf(_leg_front.rotation, deg_to_rad(SIT_THIGH), _sit)
	_leg_back.rotation = lerpf(_leg_back.rotation, deg_to_rad(SIT_THIGH + 4.0), _sit)
	_shin_front.rotation = lerpf(_shin_front.rotation, deg_to_rad(SIT_THIGH * -1.0 - 4.0) + swing, _sit)
	_shin_back.rotation = lerpf(_shin_back.rotation, deg_to_rad(SIT_THIGH * -1.0 + 2.0) - swing, _sit)


# How far (character units) the hips are held above where the feet reach the floor: the seat's height less the lower leg.
func _sit_lift() -> float:
	var shin := (_rig.leg_len as float) + 5.0 - (_rig.knee_y as float)
	return maxf(seat_h / absf(scale.y) + SIT_THICK - shin, 0.0)


# How far the hips sit below standing height so that the lower foot stays on the ground (a lunge, a bent knee).
func _stance_drop() -> float:
	var knee: float = _rig.knee_y
	var thigh := knee - (_rig.leg_pivot.y as float)
	var shin := (_rig.leg_len as float) + 5.0 - knee
	var lowest := 0.0
	for leg in [[_leg_front, _shin_front], [_leg_back, _shin_back]]:
		var a: float = (leg[0] as Sprite2D).rotation
		var f: float = (leg[1] as Sprite2D).rotation
		lowest = maxf(lowest, thigh * cos(a) + shin * cos(a + f))
	return thigh + shin - lowest


# The arms' own flex while they hang and swing: a slight bend, more as the arm swings forward, a good deal when running.
func _arms_rest(swing: float) -> void:
	var fwd_front := maxf(swing, 0.0) if is_walking else 0.0
	var fwd_back := maxf(-swing, 0.0) if is_walking else 0.0
	_elbow_goal[1] = deg_to_rad(9.0) + deg_to_rad(24.0) * fwd_front + _run * (deg_to_rad(56.0) + deg_to_rad(16.0) * fwd_front)
	_elbow_goal[0] = deg_to_rad(9.0) + deg_to_rad(24.0) * fwd_back + _run * (deg_to_rad(56.0) + deg_to_rad(16.0) * fwd_back)
	_hand_goal = ["relaxed", "relaxed"]
	_snap = [false, false]


# The shoulder angle and elbow flex (as x, y) that bring the middle of the palm to `target` (body space) from `arm`'s shoulder, the
# elbow bending down and back; out of reach the arm just stretches straight at it.
func _ik(arm: Sprite2D, target: Vector2) -> Vector2:
	var u: float = _rig.upper_len
	var f: float = (_rig.fore_len as float) + (_rig.hand_center as float)
	var v := target - arm.position
	var base := atan2(-v.x, v.y)
	var d := clampf(v.length(), absf(u - f) + 0.5, u + f - 0.01)
	var a := acos(clampf((u * u + d * d - f * f) / (2.0 * u * d), -1.0, 1.0))
	var c := acos(clampf((f * f + d * d - u * u) / (2.0 * f * d), -1.0, 1.0))
	return Vector2(base + a, a + c)


# Arm `i` (0 back, 1 front) moves `amount` of the way from whatever pose it has to reaching `target`.
func _reach_blend(i: int, target: Vector2, amount: float, snap: bool) -> void:
	var reach := _ik(_arms[i], target)
	_arms[i].rotation = lerp_angle(_arms[i].rotation, reach.x, amount)
	_elbow_goal[i] = lerpf(_elbow_goal[i], reach.y, amount)
	if snap and amount > 0.99:
		_snap[i] = true


# Puts the forearms and hands where this frame's goals say: the elbow eases toward its flex (at once for a static pose or a reach).
func _finish_arms() -> void:
	for i in 2:
		if animate and not _snap[i]:
			_elbow[i] = lerpf(_elbow[i], _elbow_goal[i], 1.0 - exp(-_dt * 16.0))
		else:
			_elbow[i] = _elbow_goal[i]
		_fores[i].rotation = -(_elbow[i] as float)
		# The wrist folds forward a little as the elbow bends.
		_hands[i].rotation = -0.1 * clampf(_elbow[i] as float, 0.0, 1.6)
		var tex: Texture2D = _hand_tex[_hand_goal[i]]
		if _hands[i].texture != tex:
			_hands[i].texture = tex


# Arm `i` reaching a point of the world (`work`), plus `wobble` body units of motion; out of reach it just stretches at it.
func _reach_to(i: int, point: Vector2, wobble := Vector2.ZERO) -> void:
	var r := _ik(_arms[i], _body.to_local(point) + wobble)
	_arms[i].rotation = r.x
	_elbow_goal[i] = r.y
	_snap[i] = true


func _has_work(n := 1) -> bool:
	return work.size() >= n


# Arm `i` (0 back, 1 front) reaching where a straight arm at `degrees` (the old way of aiming it) would, `reach` of the way out, so
# the elbow is bent a little (the less reach, the more), plus `wobble` px for the motion of the work. The elbow follows at once.
func _aim(i: int, degrees: float, reach := 0.93, wobble := Vector2.ZERO) -> void:
	var theta := deg_to_rad(degrees)
	var target := _arms[i].position + Vector2(-sin(theta), cos(theta)) * (_rig.arm_len as float) * reach + wobble
	var r := _ik(_arms[i], target)
	_arms[i].rotation = r.x
	_elbow_goal[i] = r.y
	_snap[i] = true


# Arms and head for the chore in `task`: standing at the work, the front arm doing it, the back one helping. Each arm aims where
# its hand belongs (`_aim`); the hands take the shape the work needs.
func _task_pose() -> void:
	var t := _time
	var f := float(facing)
	match task:
		"stir":
			_body.rotation += 0.05 * f
			_head.rotation += 0.1 * f
			if _has_work(2):
				_reach_to(1, work[0], Vector2(cos(t * 5.0), sin(t * 5.0)) * 7.0)
				_reach_to(0, work[1])
			else:
				_aim(1, -62.0, 0.9, Vector2(cos(t * 5.0), sin(t * 5.0)) * 7.0)
				_aim(0, -52.0, 0.9)
			_hand_goal = ["grip", "grip"]
		"piano":
			# Sitting up straight, swaying with the music, the hands sliding along the keys and pressing them one after the other.
			var beat := sin(t * 3.1)
			_body.rotation += 0.03 * beat * f
			_head.rotation += (0.05 + 0.05 * beat) * f
			if _has_work(2):
				_reach_to(1, work[0] + Vector2(sin(t * 1.7) * 20.0, 0.0), Vector2(0.0, -maxf(sin(t * 9.0), 0.0) * 4.0))
				_reach_to(0, work[1] + Vector2(sin(t * 1.3 + 1.0) * 16.0, 0.0), Vector2(0.0, -maxf(sin(t * 7.0 + 2.0), 0.0) * 4.0))
			_hand_goal = ["flat", "flat"]
		"pottery":
			# Bent over the wheel, both hands cupped round the spinning clay.
			_body.rotation += 0.08 * f
			_head.rotation += 0.16 * f
			if _has_work(2):
				_reach_to(1, work[0], Vector2(0.0, sin(t * 1.6) * 3.0))
				_reach_to(0, work[1], Vector2(0.0, -sin(t * 1.6) * 3.0))
			_hand_goal = ["open", "open"]
		"bike":
			# Polishing the frame with a rag: the front hand rubbing to and fro, the other steadying the bike.
			_body.rotation += 0.04 * f
			_head.rotation += 0.12 * f - 0.1
			if _has_work(2):
				_reach_to(1, work[0], Vector2(sin(t * 7.0) * 12.0, sin(t * 3.5) * 3.0))
				_reach_to(0, work[1])
			_hand_goal = ["flat", "grip"]
		"read":
			_aim(1, -64.0, 0.88)
			_aim(0, -70.0, 0.88)
			_hand_goal = ["flat", "grip"]
			_head.rotation += 0.14 * f + sin(t * 0.6) * 0.02
		"phone":
			_aim(1, -74.0, 0.78, Vector2(0, sin(t * 1.4) * 1.5))
			_aim(0, -12.0, 0.97)
			_hand_goal = ["relaxed", "grip"]
			_head.rotation += 0.15 * f
		"type":
			_aim(1, -70.0, 0.9, Vector2(0, sin(t * 15.0) * 2.5))
			_aim(0, -74.0, 0.9, Vector2(0, sin(t * 13.0 + 1.0) * 2.5))
			_hand_goal = ["flat", "flat"]
			_body.rotation += 0.05 * f
			_head.rotation += 0.12 * f
		"wash":
			_aim(1, -62.0, 0.88, Vector2(sin(t * 6.0) * 7.0, 0))
			_aim(0, -60.0, 0.88, Vector2(-sin(t * 6.0) * 7.0, 0))
			_hand_goal = ["open", "open"]
			_body.rotation += 0.06 * f
			_head.rotation += 0.12 * f
		"drink":
			var up := smoothstep(0.0, 0.5, fmod(t, 5.0)) * (1.0 - smoothstep(1.6, 2.1, fmod(t, 5.0)))
			_aim(1, lerpf(-58.0, -130.0, up), lerpf(0.92, 0.62, up))
			_aim(0, -14.0, 0.97)
			_hand_goal = ["relaxed", "grip"]
			_head.rotation += 0.08 * f * up
		"fridge":
			_aim(1, -76.0, 0.9, Vector2(0, sin(t * 1.5) * 2.0))
			_aim(0, -24.0, 0.96)
			_hand_goal = ["relaxed", "grip"]
			_body.rotation += 0.05 * f
		"exercise":
			var s := sin(t * 4.0)
			_aim(1, -95.0 - s * 58.0, 0.94)
			_aim(0, -95.0 + s * 58.0, 0.94)
			_hand_goal = ["grip", "grip"]
			_body.position.y -= absf(s) * 7.0
			_shin_front.rotation += absf(s) * 0.5
			_shin_back.rotation += absf(s) * 0.5
		"jog":
			# Jogging on the spot: the arms pumping at the elbows, fists closed (the legs are the run cycle).
			_elbow_goal[1] = deg_to_rad(76.0)
			_elbow_goal[0] = deg_to_rad(76.0)
			_hand_goal = ["grip", "grip"]
		"watch":
			_aim(1, -10.0, 0.96)
			_aim(0, -10.0, 0.96)
			_head.rotation -= 0.05 * f
		"daydream":
			# Somewhere else: arms hanging a little loose, the head up and drifting, the eyes on nothing.
			_aim(1, -5.0 + sin(t * 0.7) * 3.0, 0.97)
			_aim(0, -4.0 - sin(t * 0.7 + 1.0) * 3.0, 0.97)
			_head.rotation += (-0.07 + sin(t * 0.5) * 0.025) * f


## The hair behind the head moves with it: wherever the head is this frame (breathing, a gesture, petting, riding), and tilted
## the same, a little more as it trails in the wind of her walk.
func _follow_head() -> void:
	_hair_back.position = _head.position
	_hair_back.rotation = _head.rotation + _hair_angle + (0.025 * sin(walk_phase * TAU * 2.0) if is_walking else 0.0)


func _part(parent: Node2D, tex: Texture2D, pivot: Vector2, pos: Vector2, tint := Color.WHITE) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = tex
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	sprite.centered = false
	sprite.offset = -pivot
	sprite.position = pos
	sprite.modulate = tint
	sprite.material = _shade
	parent.add_child(sprite)
	return sprite
