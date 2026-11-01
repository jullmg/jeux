class_name Cyclist
extends Node2D
## Someone riding by on a bicycle in the street's traffic lane: spinning spoked wheels, the chain and cranks turning,
## and the rider, a Character like everyone else (Character.riding: leaning on the bars, legs pedalling with the
## cranks). City bikes (step-through frame, fenders, rack, sometimes a basket with the groceries) or hybrids; often a
## helmet. Rides `speed` px/s in `direction` and frees itself once past `until_x`. Drawn facing right in its own units
## (wheels on y = 0); the whole node is mirrored for leftward riders. The bike is drawn between the rider's legs (the
## far leg behind the frame, the near one in front); the far pedal behind everything.

const WHEEL_R := 34.0
const BASE := 92.0
const CRANK := Vector2(-4.0, -WHEEL_R + 2.0)
const PEDAL_R := 14.0
const SADDLES := ["#2B2B2B", "#2B2B2B", "#6B4428"]
const HELMETS := ["#2B2B2B", "#F4F4F4", "#D23B3B", "#2E86C1", "#7FB800", "#F2B632", "#5A5F66"]

var direction := 1.0
var speed := 250.0
var until_x := 0.0
var frame_color := Color("#2E86C1")
var look: CharacterLook
## "city" (step-through, upright) or "hybrid" (diamond frame).
var kind := "city"
var fenders := true
var rack := false
## "" (none), "baguette", "flowers" or "greens".
var basket := ""
var saddle_color := Color("#2B2B2B")
var _rider: Character
var _bike: Node2D
var _turn := 0.0
# The saddle and the handlebar stem, fitted to the rider's legs in _ready.
var _seat := Vector2(-14.0, -WHEEL_R - 46.0)
var _stem := Vector2(BASE / 2.0 - 10.0, -WHEEL_R - 42.0)


static func random(rng: RandomNumberGenerator) -> Cyclist:
	var c := Cyclist.new()
	c.frame_color = Color(PropArt._pick(rng, PropArt.BIKE_COLORS))
	c.look = CharacterLook.random(rng, "adult" if rng.randf() < 0.7 else "teen")
	Season.dress_for_weather(c.look)
	c.speed = rng.randf_range(220.0, 300.0)
	c.kind = "city" if rng.randf() < 0.55 else "hybrid"
	c.fenders = c.kind == "city" or rng.randf() < 0.4
	c.rack = rng.randf() < (0.6 if c.kind == "city" else 0.25)
	if c.kind == "city" and rng.randf() < 0.45:
		c.basket = PropArt._pick(rng, ["", "baguette", "flowers", "greens"])
		if c.basket == "":
			c.basket = "empty"
	c.saddle_color = Color(PropArt._pick(rng, SADDLES))
	if rng.randf() < 0.55:
		c.look.hat = "helmet"
		c.look.hat_color = Color(PropArt._pick(rng, HELMETS))
	return c


func _ready() -> void:
	scale.x = absf(scale.x) * direction
	_rider = Character.new()
	_rider.look = look
	_rider.riding = true
	# Hips on the saddle: the puppet's origin is its feet, its hips a leg's length above.
	_rider.scale = Vector2.ONE * StreetScene.CHAR_SCALE / absf(scale.y)
	add_child(_rider)
	# The saddle up the seat tube so that the legs reach the far pedal with the knee still a little bent; the hips on
	# it (the body leans forward round its feet, so allow for that).
	var leg: float = _rider._rig.leg_len
	var reach := (leg - 6.0) * _rider.scale.y
	_seat = CRANK + Vector2(-0.2, -0.98).normalized() * (reach * 0.78 - PEDAL_R * 0.3)
	_stem = Vector2(BASE / 2.0 - 10.0, _seat.y + 4.0)
	var hip := Vector2(0, -leg).rotated(deg_to_rad(Character.RIDE_LEAN)) * _rider.scale.y
	_rider.position = _seat + Vector2(0, -3.0) - hip
	_bike = Node2D.new()
	_bike.draw.connect(_draw_bike)
	_rider.add_between_legs(_bike)
	_update_rider()


# Tells the rider where the pedals and the grip are this frame.
func _update_rider() -> void:
	var a := _turn * 0.5
	_rider.pedal = a
	_rider.pedal_feet = [to_global(_pedal(a + PI)), to_global(_pedal(a))]
	_rider.bar_grip = to_global(_grip())


func _pedal(a: float) -> Vector2:
	return CRANK + Vector2.from_angle(a) * PEDAL_R


func _grip() -> Vector2:
	return _stem + Vector2(8.0, -14.0)


func _process(delta: float) -> void:
	position.x += direction * speed * delta
	_turn += delta * speed / (TAU * WHEEL_R * scale.y) * TAU
	if _rider:
		_update_rider()
	if (direction > 0.0 and position.x > until_x) or (direction < 0.0 and position.x < until_x):
		queue_free()
	queue_redraw()
	if _bike:
		_bike.queue_redraw()


# Behind the rider: the shadow on the asphalt and the far crank and pedal.
func _draw() -> void:
	draw_set_transform(Vector2(0, 2), 0.0, Vector2(1.9, 0.16))
	draw_circle(Vector2.ZERO, 50.0, Color(0, 0, 0, 0.16))
	draw_circle(Vector2.ZERO, 34.0, Color(0, 0, 0, 0.1))
	draw_set_transform(Vector2.ZERO)
	_crank(self, _turn * 0.5 + PI, true)


# ── The bike (between the rider's legs) ─────────────────────

func _draw_bike() -> void:
	var c := _bike
	var back := Vector2(-BASE / 2.0, -WHEEL_R)
	var front := Vector2(BASE / 2.0, -WHEEL_R)
	var seat_top := _seat + Vector2(2, 7)
	var head_top := _stem + Vector2(0, 2)
	var head_bot := _stem.lerp(front, 0.22)
	for hub in [back, front]:
		_wheel(c, hub)
	# Chain and rear sprocket, then the frame over them.
	c.draw_circle(back, 5.0, Color("#4A4E54"))
	for sgn in [-1.0, 1.0]:
		c.draw_line(CRANK + Vector2(0, 9.0 * sgn), back + Vector2(0, 5.0 * sgn), Color("#3A3D42"), 1.6, true)
	if fenders:
		var fc := frame_color if kind == "city" else Color("#2B2B2B")
		c.draw_arc(back, WHEEL_R + 3.0, PI * 0.92, PI * 1.74, 18, fc.darkened(0.3), 4.5, true)
		c.draw_arc(back, WHEEL_R + 3.0, PI * 0.92, PI * 1.74, 18, fc, 3.0, true)
		c.draw_arc(front, WHEEL_R + 3.0, PI * 1.2, PI * 2.06, 18, fc.darkened(0.3), 4.5, true)
		c.draw_arc(front, WHEEL_R + 3.0, PI * 1.2, PI * 2.06, 18, fc, 3.0, true)
		c.draw_line(back, back + Vector2.from_angle(PI * 0.95) * (WHEEL_R + 3.0), Color("#9AA0A7"), 1.0, true)
		c.draw_line(front, front + Vector2.from_angle(PI * 2.04) * (WHEEL_R + 3.0), Color("#9AA0A7"), 1.0, true)
	if rack:
		var deck := back.y - WHEEL_R - 8.0
		var r0 := Vector2(back.x - 12.0, deck)
		var r1 := Vector2(back.x + 16.0, deck)
		c.draw_line(back, r0 + Vector2(2, 0), Color("#3A3D42"), 1.6, true)
		c.draw_line(back, r1 + Vector2(-6, 0), Color("#3A3D42"), 1.6, true)
		c.draw_line(r1, seat_top.lerp(back, 0.35), Color("#3A3D42"), 1.6, true)
		c.draw_line(r0, r1, Color("#2B2B2B"), 2.6, true)
		c.draw_rect(Rect2(r0 + Vector2(-2, 1), Vector2(4, 3)), Color("#D23030"))
	# The frame: chain and seat stays, seat tube, then top and down tubes (one low curve on a step-through).
	_tube(c, back, CRANK, 3.2)
	_tube(c, back, seat_top + Vector2(-1, 2), 3.0)
	_tube(c, CRANK, seat_top, 5.0)
	if kind == "city":
		var from := head_top.lerp(head_bot, 0.55)
		var to := CRANK.lerp(seat_top, 0.12)
		var ctrl := Vector2(lerpf(to.x, from.x, 0.45), to.y + 2.0)
		var pts := PackedVector2Array()
		for k in 13:
			var t := k / 12.0
			pts.append(from.lerp(ctrl, t).lerp(ctrl.lerp(to, t), t))
		_tube_curve(c, pts, 5.5)
	else:
		_tube(c, seat_top + Vector2(0, 3), head_top + Vector2(0, 2), 4.5)
		_tube(c, CRANK, head_bot, 5.5)
	# Fork (raked forward at the bottom) and head tube.
	var fork := PackedVector2Array()
	for k in 9:
		var t := k / 8.0
		fork.append(head_bot.lerp(front, t) + Vector2(sin(t * PI) * -2.0 + t * t * 3.0, 0))
	_tube_curve(c, fork, 3.6)
	_tube(c, head_top + Vector2(-0.5, -3), head_bot, 6.5)
	# The front light on the head tube.
	c.draw_rect(Rect2(head_top + Vector2(3, 2), Vector2(6, 4)), Color("#2B2B2B"))
	c.draw_circle(head_top + Vector2(9, 4), 2.0, Color("#FFF6D0"))
	# Seat post and saddle.
	c.draw_line(seat_top, _seat + Vector2(0, 1), Color("#5E636A"), 3.6, true)
	c.draw_line(seat_top, _seat + Vector2(0, 1), Color("#B9BEC6"), 2.0, true)
	var saddle := PackedVector2Array([_seat + Vector2(-11, -2), _seat + Vector2(-6, -4.5), _seat + Vector2(3, -3.5),
		_seat + Vector2(12, -1.5), _seat + Vector2(11, 0.5), _seat + Vector2(1, 2), _seat + Vector2(-10, 3)])
	c.draw_colored_polygon(saddle, saddle_color)
	saddle.append(saddle[0])
	c.draw_polyline(saddle, saddle_color.darkened(0.4), 1.2, true)
	c.draw_line(_seat + Vector2(-8, -3), _seat + Vector2(2, -3), Color(1, 1, 1, 0.22), 1.2, true)
	# Stem, bars swept to the grips, brake lever and bell.
	var clamp := _stem + Vector2(1, -9)
	c.draw_line(head_top + Vector2(-0.5, -3), clamp, Color("#9AA0A7"), 3.0, true)
	var bar := PackedVector2Array([clamp, _stem + Vector2(5, -12.5), _stem + Vector2(12, -14.5)])
	c.draw_polyline(bar, Color("#3A3D42"), 3.4, true)
	c.draw_polyline(bar, Color("#B9BEC6"), 1.8, true)
	c.draw_line(_stem + Vector2(6, -13.5), _stem + Vector2(13, -14.8), Color("#1E1E1E"), 4.6, true)
	c.draw_line(_stem + Vector2(7, -12.5), _stem + Vector2(13, -9.5), Color("#9AA0A7"), 1.3, true)
	c.draw_circle(_stem + Vector2(3, -12.5), 2.4, Color("#C9CED4"))
	if basket != "":
		_basket(c, _stem + Vector2(10, -12))
	# The chainring, then the near crank and pedal (the near foot will cover it).
	c.draw_circle(CRANK, 10.0, Color("#3A3D42"))
	c.draw_circle(CRANK, 8.6, Color("#9AA0A7"))
	c.draw_circle(CRANK, 6.0, Color("#6E747B"))
	for k in 5:
		var a := _turn * 0.5 + TAU * k / 5.0
		c.draw_line(CRANK, CRANK + Vector2.from_angle(a) * 7.0, Color("#B9BEC6"), 1.4, true)
	if kind == "city":
		c.draw_line(CRANK + Vector2(4, -11), back + Vector2(4, -7), Color("#1E1E1E"), 4.0, true)
	_crank(c, _turn * 0.5, false)


func _wheel(c: CanvasItem, hub: Vector2) -> void:
	# Spokes crossing (alternately leading and trailing), the rim, the tyre with a sheen on the sunny side, the hub.
	for k in 18:
		var lead := 1.0 if k % 2 == 0 else -1.0
		var a := _turn + TAU * k / 18.0
		c.draw_line(hub + Vector2.from_angle(a + PI / 2.0 * lead) * 2.6, hub + Vector2.from_angle(a + 0.3 * lead) * (WHEEL_R - 6.0),
			Color("#D5D9DE", 0.7), 0.7, true)
	c.draw_arc(hub, WHEEL_R - 5.2, 0, TAU, 40, Color("#7A8088"), 1.0, true)
	c.draw_arc(hub, WHEEL_R - 4.0, 0, TAU, 40, Color("#C3C8CE"), 2.0, true)
	c.draw_arc(hub, WHEEL_R - 1.0, 0, TAU, 44, Color("#1C1C1E"), 5.0, true)
	c.draw_arc(hub, WHEEL_R + 0.6, PI * 1.08, PI * 1.42, 10, Color(1, 1, 1, 0.16), 1.2, true)
	c.draw_line(hub + Vector2.from_angle(_turn) * (WHEEL_R - 6.0), hub + Vector2.from_angle(_turn) * (WHEEL_R - 9.0), Color("#5E636A"), 1.4)
	c.draw_circle(hub, 4.2, Color("#5E636A"))
	c.draw_circle(hub, 3.0, Color("#A5ABB2"))
	c.draw_circle(hub + Vector2(-0.8, -0.8), 1.0, Color(1, 1, 1, 0.7))


# A tube with a dark edge and a highlight on its upper (sunny) side.
func _tube(c: CanvasItem, a: Vector2, b: Vector2, w: float) -> void:
	var n := (b - a).normalized().orthogonal()
	if n.y > 0.0:
		n = -n
	c.draw_line(a, b, frame_color.darkened(0.35), w + 1.6, true)
	c.draw_line(a, b, frame_color, w, true)
	c.draw_line(a + n * w * 0.22, b + n * w * 0.22, frame_color.lightened(0.4), maxf(w * 0.22, 0.9), true)


func _tube_curve(c: CanvasItem, pts: PackedVector2Array, w: float) -> void:
	c.draw_polyline(pts, frame_color.darkened(0.35), w + 1.6, true)
	c.draw_polyline(pts, frame_color, w, true)
	var hi := PackedVector2Array()
	for p in pts:
		hi.append(p + Vector2(-0.4, -w * 0.22))
	c.draw_polyline(hi, frame_color.lightened(0.4), maxf(w * 0.22, 0.9), true)


func _crank(c: CanvasItem, a: float, far: bool) -> void:
	var p := _pedal(a)
	var arm := Color("#7A8088") if far else Color("#B9BEC6")
	c.draw_line(CRANK, p, Color("#3A3D42"), 4.2, true)
	c.draw_line(CRANK, p, arm, 2.6, true)
	c.draw_line(p + Vector2(-5.5, 0), p + Vector2(5.5, 0), Color("#1E1E1E"), 4.0, true)
	if not far:
		c.draw_circle(CRANK, 2.2, Color("#5E636A"))
		c.draw_rect(Rect2(p + Vector2(-1.5, -1), Vector2(3, 2)), Color("#F2A33A"))


# A wicker basket over the front wheel, with what they bought sticking out.
func _basket(c: CanvasItem, at: Vector2) -> void:
	var r := Rect2(at, Vector2(22, 15))
	match basket:
		"baguette":
			var a := r.position + Vector2(3, 8)
			var b := r.position + Vector2(18, -12)
			c.draw_line(a, b, Color("#9A6A30"), 7.0, true)
			c.draw_line(a, b, Color("#D9A75A"), 5.4, true)
			for k in 3:
				var m := a.lerp(b, 0.55 + k * 0.14)
				c.draw_line(m + Vector2(-2, 0), m + Vector2(1, -2), Color("#F2D9A0"), 1.2, true)
		"flowers":
			for k in 5:
				var top := r.position + Vector2(4 + k * 3.6, -6.0 - (k % 2) * 4.0)
				c.draw_line(top, top + Vector2(0, 10), Color("#4F8E3A"), 1.2, true)
				c.draw_circle(top, 2.6, Color(["#E8505B", "#F2C230", "#F4F4F4", "#C97AB8", "#FF8A3D"][k]))
		"greens":
			for k in 4:
				c.draw_circle(r.position + Vector2(5 + k * 4.5, -1 - (k % 2) * 2), 4.2, Color("#5E9E44").darkened(0.08 * k))
	c.draw_rect(r, Color("#B88850"))
	for k in 4:
		c.draw_line(r.position + Vector2(0, 3 + k * 3.5), r.position + Vector2(22, 3 + k * 3.5), Color("#8E6434"), 1.0)
	for k in 6:
		c.draw_line(r.position + Vector2(2 + k * 3.8, 0), r.position + Vector2(2 + k * 3.8, 15), Color("#D6AC70"), 0.8)
	c.draw_line(r.position, r.position + Vector2(22, 0), Color("#7A5428"), 2.2, true)
	c.draw_rect(r, Color("#7A5428"), false, 1.0)
	c.draw_line(r.position + Vector2(22, 15), Vector2(BASE / 2.0, -WHEEL_R), Color("#3A3D42"), 1.2, true)
