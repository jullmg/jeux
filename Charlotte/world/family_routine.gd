class_name FamilyRoutine
extends Node
## A parent's day at home: they walk from chore to chore on their own and do each one for a while (stir a pot, wash up, look
## in the fridge, read, type on the laptop, drink a coffee, check the phone, do their exercises, watch the TV), saying a
## word now and then. Each chore is {x, facing, task (a Character.task), prop, secs, say, and optionally: sit (seat height; `floor` the
## floor under the seat), work ([front hand, back hand] points, x from where they stand, y in the world; + is to the right),
## prop_at (a prop that stays put, same kind of point), jog (runs on the spot), done_say (what they say when it ends)}. Click them and they stop to talk
## (`pause`). The routine also moves the click area and the "!" with them.

const WALK_SPEED := 105.0
## What they hold is drawn a good deal bigger than the little pictures below, so it reads at their size.
const HELD_SCALE := 1.9

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
		who.running = false
		who.task = ""
		who.sitting = false
		who.work = []
		_drop_prop()
		if not is_nan(_face_x):
			who.facing = 1 if _face_x > who.position.x else -1
		if _pause <= 0.0:
			_pick()
		return
	match _state:
		"walk":
			# Still getting up from the seat: wait.
			if who.is_seated():
				who.sitting = false
				who.is_walking = false
				return
			var x: float = _current.x
			var d := x - who.position.x
			if absf(d) <= WALK_SPEED * delta:
				who.position.x = x
				who.is_walking = false
				who.facing = int(_current.get("facing", who.facing))
				who.task = str(_current.get("task", ""))
				if _current.has("sit"):
					who.seat_h = float(_current.sit)
					who.seat_floor = float(_current.get("floor", NAN))
					who.sitting = true
				if who.task == "jog":
					who.is_walking = true
					who.running = true
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
			_set_work()
			_follow_hand()
			if _time <= 0.0:
				_finish()
				_pick()
		_:
			_time -= delta
			if _time <= 0.0:
				_pick()


## Stops what they are doing to talk to Charlotte (turning toward `toward_x`) for `seconds`.
func pause(seconds: float, toward_x: float) -> void:
	_pause = seconds
	_face_x = toward_x


# Puts the chore down: the props, the seat, the running on the spot, and a last word when the chore has one.
func _finish() -> void:
	who.task = ""
	who.sitting = false
	who.work = []
	if who.running:
		who.running = false
		who.is_walking = false
	_drop_prop()
	var words: Array = _current.get("done_say", [])
	if not words.is_empty():
		Bubble.say(who.get_parent(), who.position + Vector2(0, -310), str(words[randi() % words.size()]), 2.8)


func _pick() -> void:
	if tasks.is_empty():
		return
	var i := randi() % tasks.size()
	if tasks.size() > 1 and i == _last:
		i = (i + 1) % tasks.size()
	_last = i
	_current = tasks[i]
	_state = "walk"


# The points where their hands work this frame: the chore's offsets from where they stand, mirrored when they face left.
func _set_work() -> void:
	var pts: Array = _current.get("work", [])
	if pts.is_empty():
		return
	var out: Array[Vector2] = []
	for p: Vector2 in pts:
		out.append(Vector2(who.position.x + p.x, p.y))
	who.work = out


func _take_prop() -> void:
	_drop_prop()
	var kind := str(_current.get("prop", ""))
	if kind == "":
		return
	_prop = _Prop.new()
	_prop.kind = kind
	who.get_parent().add_child(_prop)
	_prop.z_index = 2
	_prop.scale = Vector2.ONE * HELD_SCALE
	_follow_hand()


func _drop_prop() -> void:
	if is_instance_valid(_prop):
		_prop.queue_free()
	_prop = null


func _follow_hand() -> void:
	if not is_instance_valid(_prop):
		return
	var at: Variant = _current.get("prop_at", null)
	if _prop.kind == "moon":
		# In front of his blank gaze, a little above it, drifting.
		var eyes: Vector2 = who.get_parent().to_local(who._head.global_position)
		_prop.position = eyes + Vector2(who.facing * 105.0, -22.0)
		_prop.scale = Vector2(float(who.facing), 1.0) * 2.1
	elif _prop.kind == "sweat":
		var head: Vector2 = who.get_parent().to_local(who._head.global_position)
		_prop.position = head + Vector2(-who.facing * 30.0, -50.0)
		_prop.scale = Vector2(float(who.facing), 1.0) * 1.6
	elif at is Vector2:
		# Stays where the work is (the clay on the wheel, the notes over the piano, the bowl on the table).
		_prop.position = Vector2(who.position.x + at.x, at.y)
		_prop.scale = Vector2(float(who.facing), 1.0) * (1.5 if _prop.kind == "bike" else 1.0 if _prop.kind in ["notes", "clay"] else HELD_SCALE)
	else:
		_prop.position = who.hand_position()
		_prop.scale = Vector2(float(who.facing), 1.0) * HELD_SCALE
		if _prop.kind == "mug":
			# The cup tips toward the lips as they drink (the rotation is in the parent's space, so it is turned by hand).
			_prop.sip = who.sip_amount()
			_prop.rotation = _prop.sip * 0.5 * who.facing


# What is in their hand (or on the table), drawn small: a wooden spoon, a book, a mug with steam, a phone, a laptop, a plate.
class _Prop:
	extends Node2D
	var kind := ""
	## For the mug: 0 down by their side, 1 at their lips.
	var sip := 0.0
	var _t := 0.0

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		match kind:
			"bowl":
				# A mixing bowl on the table, centred on its origin, a wooden spoon going round in it.
				draw_arc(Vector2(0, -12), 12.0, 0, PI, 14, Color("#E8E4DA"), 5.0)
				draw_line(Vector2(-13, -12), Vector2(13, -12), Color("#C9C2B4"), 2.0)
				draw_circle(Vector2(0, -11), 8.0, Color("#F2D9A0"))
				draw_line(Vector2(cos(_t * 5.0) * 4.0, -11), Vector2(8 + sin(_t * 5.0) * 3.0, -30), Color("#A8743E"), 2.6, true)
			"rag":
				var wob := sin(_t * 7.0) * 2.0
				draw_colored_polygon(PackedVector2Array([Vector2(-7, -8 + wob), Vector2(8, -10), Vector2(9, 2), Vector2(-6, 4 - wob)]), Color("#7FB4D9"))
				draw_polyline(PackedVector2Array([Vector2(-7, -8 + wob), Vector2(8, -10), Vector2(9, 2), Vector2(-6, 4 - wob), Vector2(-7, -8 + wob)]), Color("#4F83AC"), 1.2)
			"clay":
				_draw_clay()
			"notes":
				_draw_notes()
			"bike":
				_draw_bike()
			"sweat":
				for k in 3:
					var p := fmod(_t * 0.9 + k / 3.0, 1.0)
					var at := Vector2(-12.0 + k * 12.0, -4.0 + p * 40.0)
					draw_circle(at, 3.2 * (1.0 - p * 0.4), Color(0.6, 0.85, 1.0, 1.0 - p))
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
				_draw_mug()
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

	# A mug held in the hand: the HANDLE is where the fingers are (the prop's origin is the hand), the cup sits just
	# inward of it, and the coffee inside keeps its surface level however far the cup is tipped.
	func _draw_mug() -> void:
		var cream := Color("#F4F2EC")
		var edge := Color("#C2BAAC")
		var cx := -8.5
		# The handle: a C standing where the fingers are, so the hand really goes through it.
		draw_arc(Vector2(cx + 7.4, -0.5), 5.8, -PI / 2.0, PI / 2.0, 14, edge, 5.2)
		draw_arc(Vector2(cx + 7.4, -0.5), 5.8, -PI / 2.0, PI / 2.0, 14, cream, 3.0)
		var body := PackedVector2Array([Vector2(cx - 7.6, -10), Vector2(cx + 7.6, -10), Vector2(cx + 6.2, 9), Vector2(cx - 6.2, 9)])
		draw_colored_polygon(body, cream)
		draw_polyline(body + PackedVector2Array([body[0]]), edge, 1.3, true)
		# The rim and the shadowed inside of the cup.
		draw_colored_polygon(CritterDraw.ellipse_points(Vector2(cx, -10.0), Vector2(7.6, 2.4), 0.0, 18), Color("#EDE8DE"))
		draw_colored_polygon(CritterDraw.ellipse_points(Vector2(cx, -9.6), Vector2(6.2, 1.8), 0.0, 18), Color("#4A2B14"))
		# The coffee, always INSIDE the rim (it used to bulge out over it): a little disc of it deep in the cup,
		# rising and spreading to the mouth of the cup as they tip it up to drink.
		var fill := Vector2(1.6 + sip * 4.4, 0.5 + sip * 1.2)
		draw_colored_polygon(CritterDraw.ellipse_points(Vector2(cx, -9.5), fill, 0.0, 18), Color("#6B3F22"))
		draw_colored_polygon(CritterDraw.ellipse_points(Vector2(cx - fill.x * 0.25, -9.7), fill * 0.4, 0.0, 14), Color("#90603A"))
		# A shine down the cup and its gold band.
		draw_line(Vector2(cx - 4.4, -6.0), Vector2(cx - 4.8, 6.0), Color(1, 1, 1, 0.7), 2.0)
		draw_rect(Rect2(cx - 6.8, 2.0, 13.4, 2.2), Color("#D9A23A"))
		# The steam goes straight up, whatever the cup is doing.
		draw_set_transform(Vector2(cx, -11.0), -rotation, Vector2.ONE)
		for k in 2:
			var ph := _t * 1.6 + k * 1.7
			var fade: float = (1.0 - sip) * 0.45
			draw_line(Vector2(-2.5 + k * 5.0, 0.0), Vector2(-2.5 + k * 5.0 + sin(ph) * 2.0, -10.0 - fmod(ph, 1.0) * 5.0), Color(1, 1, 1, fade), 1.6)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


	# Papa's bike, leaning on its kickstand beside him: two spoked wheels, a frame, handlebars and a saddle, with a shine on
	# the tubes that slides as he polishes.
	func _draw_bike() -> void:
		var dark := Color("#2B2B2B")
		var frame := Color("#1D4F91")
		for wx in [-58.0, 46.0]:
			draw_arc(Vector2(wx, -26), 26.0, 0, TAU, 28, dark, 4.0)
			draw_arc(Vector2(wx, -26), 22.0, 0, TAU, 24, Color("#B0B4B8"), 1.5)
			for i in 8:
				var a := TAU * i / 8.0 + _t * 0.2
				draw_line(Vector2(wx, -26), Vector2(wx, -26) + Vector2.from_angle(a) * 22.0, Color("#D5D9DC"), 1.0)
			draw_circle(Vector2(wx, -26), 4.0, Color("#6E7276"))
		var pts := [Vector2(-58, -26), Vector2(-16, -26), Vector2(-4, -62), Vector2(-40, -62), Vector2(-16, -26), Vector2(46, -26), Vector2(-4, -62)]
		for i in range(0, pts.size() - 1):
			draw_line(pts[i], pts[i + 1], frame, 5.0, true)
		draw_line(Vector2(46, -26), Vector2(30, -70), frame, 5.0, true)
		draw_line(Vector2(18, -72), Vector2(42, -68), dark, 4.0, true)
		draw_colored_polygon(PackedVector2Array([Vector2(-46, -66), Vector2(-20, -70), Vector2(-14, -62), Vector2(-42, -60)]), dark)
		draw_circle(Vector2(-16, -26), 7.0, Color("#6E7276"))
		var shine := -30.0 + fmod(_t * 26.0, 60.0)
		draw_line(Vector2(shine, -34), Vector2(shine + 10, -52), Color(1, 1, 1, 0.45), 2.5, true)

	# The pot rising on the wheel: a belly that swells and narrows, lit on the left, the throwing rings sliding up it as the wheel turns.
	func _draw_clay() -> void:
		var pts := PackedVector2Array()
		var h := 30.0 + 6.0 * sin(_t * 0.8)
		for i in 13:
			var y := -h * i / 12.0
			pts.append(Vector2(-(13.0 + 5.0 * sin(PI * i / 12.0 * 0.9) - i * 0.5), y))
		for i in range(12, -1, -1):
			var y := -h * i / 12.0
			pts.append(Vector2(13.0 + 5.0 * sin(PI * i / 12.0 * 0.9) - i * 0.5, y))
		draw_colored_polygon(pts, Color("#BC7449"))
		draw_polyline(pts + PackedVector2Array([pts[0]]), Color("#7A4527"), 1.6, true)
		draw_rect(Rect2(-12, -h * 0.9, 5, h * 0.8), Color(1, 1, 1, 0.14))
		for k in 4:
			var y := -fmod(k * 8.0 + _t * 9.0, h)
			var w := 12.0 + 4.0 * sin(PI * (-y / h) * 0.9)
			draw_line(Vector2(-w, y), Vector2(w, y), Color(0.45, 0.25, 0.12, 0.35), 1.4)

	# Music notes rising from the piano, wobbling as they go, fading away.
	func _draw_notes() -> void:
		for k in 3:
			var p := fmod(_t * 0.45 + k / 3.0, 1.0)
			var at := Vector2(-40.0 + k * 40.0 + sin(p * 7.0 + k) * 9.0, -p * 80.0)
			var c := Color(0.17, 0.17, 0.22, 1.0 - p * p)
			draw_circle(at, 5.0, c)
			draw_line(at + Vector2(4.5, 0), at + Vector2(4.5, -20), c, 2.0)
			if k != 1:
				draw_line(at + Vector2(4.5, -20), at + Vector2(12, -13), c, 2.2)

	# A little crescent moon that pops up, bobs, glows softly, with two stars twinkling by it (`DreamMoon`, shared
	# with Charlotte's own daydream).
	func _draw_moon() -> void:
		DreamMoon.paint(self, _t)

