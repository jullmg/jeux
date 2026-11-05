class_name FamilyRoutine
extends Node
## A parent's day at home: they walk from chore to chore on their own and do each one for a while (stir a pot, wash up, look
## in the fridge, read, type on the laptop, drink a coffee, check the phone, do their exercises, watch the TV), saying a
## word now and then. Each chore is {x, facing, task (a Character.task), prop, secs, say}. Click them and they stop to talk
## (`pause`). The routine also moves the click area and the "!" with them.

const WALK_SPEED := 105.0

var who: Character
var tasks: Array = []
var spot: DoorSpot
var mark: Node2D
var mark_offset := Vector2(0, -350)

var _current := {}
var _state := "wait"
var _time := 2.0
var _pause := 0.0
var _face_x := NAN
var _prop: Node2D
var _last := -1


func _ready() -> void:
	_pick()


func _process(delta: float) -> void:
	if who == null:
		return
	_step(delta)
	# The click area and the "!" go where they are now.
	if spot:
		spot.rect = Rect2(who.position.x - 55.0, 330, 110, 340)
		spot.stand_x = who.position.x - 90.0
		spot.position = Vector2(spot.stand_x, spot.rect.end.y)
	if mark:
		mark.position = who.position + mark_offset


func _step(delta: float) -> void:
	if _pause > 0.0:
		_pause -= delta
		who.is_walking = false
		who.task = ""
		_drop_prop()
		if not is_nan(_face_x):
			who.facing = 1 if _face_x > who.position.x else -1
		if _pause <= 0.0:
			_pick()
		return
	match _state:
		"walk":
			var x: float = _current.x
			var d := x - who.position.x
			if absf(d) <= WALK_SPEED * delta:
				who.position.x = x
				who.is_walking = false
				who.facing = int(_current.get("facing", who.facing))
				who.task = str(_current.get("task", ""))
				_time = float(_current.get("secs", 8.0)) * randf_range(0.8, 1.3)
				_take_prop()
				_state = "do"
				var words: Array = _current.get("say", [])
				if not words.is_empty() and randf() < 0.55:
					Bubble.say(who.get_parent(), who.position + Vector2(0, -310), str(words[randi() % words.size()]), 2.6)
			else:
				who.is_walking = true
				who.facing = 1 if d > 0.0 else -1
				who.position.x += signf(d) * WALK_SPEED * delta
		"do":
			_time -= delta
			_follow_hand()
			if _time <= 0.0:
				who.task = ""
				_drop_prop()
				_pick()
		_:
			_time -= delta
			if _time <= 0.0:
				_pick()


## Stops what they are doing to talk to Charlotte (turning toward `toward_x`) for `seconds`.
func pause(seconds: float, toward_x: float) -> void:
	_pause = seconds
	_face_x = toward_x


func _pick() -> void:
	if tasks.is_empty():
		return
	var i := randi() % tasks.size()
	if tasks.size() > 1 and i == _last:
		i = (i + 1) % tasks.size()
	_last = i
	_current = tasks[i]
	_state = "walk"


func _take_prop() -> void:
	_drop_prop()
	var kind := str(_current.get("prop", ""))
	if kind == "":
		return
	_prop = _Prop.new()
	_prop.kind = kind
	who.get_parent().add_child(_prop)
	_prop.z_index = 2
	_follow_hand()


func _drop_prop() -> void:
	if is_instance_valid(_prop):
		_prop.queue_free()
	_prop = null


func _follow_hand() -> void:
	if not is_instance_valid(_prop):
		return
	if _prop.kind == "moon":
		# In front of his blank gaze, a little above it, drifting.
		var eyes: Vector2 = who.get_parent().to_local(who._head.global_position)
		_prop.position = eyes + Vector2(who.facing * 105.0, -22.0)
		_prop.scale = Vector2(float(who.facing), 1.0) * 2.1
	elif _prop.kind == "laptop":
		_prop.position = Vector2(who.hand_position().x, 482.0)
		_prop.scale.x = float(who.facing)
	else:
		_prop.position = who.hand_position()
		_prop.scale.x = float(who.facing)


# What is in their hand (or on the table), drawn small: a wooden spoon, a book, a mug with steam, a phone, a laptop, a plate.
class _Prop:
	extends Node2D
	var kind := ""
	var _t := 0.0

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		match kind:
			"bowl":
				draw_arc(Vector2(14, -14), 12.0, 0, PI, 12, Color("#E8E4DA"), 5.0)
				draw_line(Vector2(2, -14), Vector2(26, -14), Color("#C9C2B4"), 2.0)
				draw_line(Vector2(14, -14), Vector2(26 + sin(_t * 5.0) * 4.0, -28), Color("#A8743E"), 2.6, true)
			"spoon":
				draw_line(Vector2(0, 0), Vector2(16, -18), Color("#A8743E"), 3.0, true)
				draw_circle(Vector2(17, -20), 4.5, Color("#C99560"))
			"book":
				draw_rect(Rect2(-2, -26, 24, 18), Color("#3D7FD0"))
				draw_rect(Rect2(0, -24, 20, 14), Color("#F7F3EA"))
				draw_line(Vector2(10, -24), Vector2(10, -10), Color("#9A968E"), 1.2)
				draw_line(Vector2(3, -19), Vector2(8, -19), Color("#7A7A7A"), 1.0)
				draw_line(Vector2(12, -19), Vector2(17, -19), Color("#7A7A7A"), 1.0)
			"mug":
				draw_rect(Rect2(-5, -16, 11, 12), Color("#F4F2EC"))
				draw_rect(Rect2(-5, -16, 11, 3), Color("#7A4A2A"))
				draw_arc(Vector2(6, -10), 4.0, -PI / 2.0, PI / 2.0, 8, Color("#F4F2EC"), 2.0)
				for k in 2:
					var ph := _t * 1.6 + k * 1.7
					draw_line(Vector2(-2 + k * 5, -20), Vector2(-2 + k * 5 + sin(ph) * 2.0, -30 - fmod(ph, 1.0) * 5.0), Color(1, 1, 1, 0.35), 1.6)
			"phone":
				draw_rect(Rect2(-4, -22, 9, 15), Color("#2B2B33"))
				draw_rect(Rect2(-3, -21, 7, 12), Color("#9FE0F5"))
			"plate":
				draw_circle(Vector2(0, -8), 8.0, Color("#FFFFFF"))
				draw_arc(Vector2(0, -8), 8.0, 0, TAU, 14, Color("#C9C2B4"), 1.2)
				draw_circle(Vector2(1, -9), 3.0, Color("#E8A62A"))
			"moon":
				_draw_moon()
			"laptop":
				draw_rect(Rect2(-16, -20, 30, 20), Color("#2E343C"))
				draw_rect(Rect2(-14, -18, 26, 16), Color("#9FE0F5") if fmod(_t, 6.0) < 5.5 else Color("#E8F6C8"))
				draw_rect(Rect2(-20, 0, 38, 3), Color("#B9BEC6"))

	# A little crescent moon that pops up, bobs, glows softly, with two stars twinkling by it.
	func _draw_moon() -> void:
		var grow := smoothstep(0.0, 0.7, _t)
		var bob := Vector2(sin(_t * 1.3) * 3.0, sin(_t * 2.1) * 4.0)
		draw_set_transform(bob, sin(_t * 0.9) * 0.12, Vector2.ONE * (grow * (1.0 + 0.12 * sin(_t * 6.0) * (1.0 - grow))))
		draw_circle(Vector2.ZERO, 24.0, Color(1.0, 0.95, 0.7, 0.16))
		draw_circle(Vector2.ZERO, 17.0, Color(1.0, 0.95, 0.7, 0.2))
		var outer := PackedVector2Array()
		var inner := PackedVector2Array()
		for i in 36:
			var a := TAU * i / 36.0
			outer.append(Vector2.from_angle(a) * 13.0)
			inner.append(Vector2(7.0, -3.0) + Vector2.from_angle(a) * 11.0)
		for piece: PackedVector2Array in Geometry2D.clip_polygons(outer, inner):
			draw_colored_polygon(piece, Color("#FFD84D"))
			draw_polyline(piece + PackedVector2Array([piece[0]]), Color("#B8892A"), 2.2, true)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		for k in 2:
			var tw := 0.5 + 0.5 * sin(_t * 3.0 + k * 2.4)
			var at := bob + (Vector2(22.0, -14.0) if k == 0 else Vector2(-16.0, 15.0)) * grow
			draw_line(at - Vector2(3.5, 0) * tw, at + Vector2(3.5, 0) * tw, Color("#FFF3C4"), 1.4)
			draw_line(at - Vector2(0, 3.5) * tw, at + Vector2(0, 3.5) * tw, Color("#FFF3C4"), 1.4)

