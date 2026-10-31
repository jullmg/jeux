class_name StrayCat
extends Node2D
## Procedural street cat: random coat, wanders the sidewalk, sits, loafs, and purrs when Charlotte pets it.
## Clickable: Main walks Charlotte over and calls interact(). With `wander = false` it just sits (window cats).

const COATS := [
	{"base": "#E8954A", "dark": "#B8622A", "light": "#F8DDB8", "pattern": "tabby", "eyes": "#9BC53D"},
	{"base": "#2A282E", "dark": "#141317", "light": "#4A4652", "pattern": "solid", "eyes": "#F5D04A"},
	{"base": "#8E8E96", "dark": "#5C5C66", "light": "#D9D9DE", "pattern": "tabby", "eyes": "#9BC53D"},
	{"base": "#F5F2EC", "dark": "#CFC6B8", "light": "#FFFFFF", "pattern": "solid", "eyes": "#6FA8DC"},
	{"base": "#F5F2EC", "dark": "#CFC6B8", "light": "#FFFFFF", "pattern": "calico", "eyes": "#E8B33A"},
	{"base": "#2A282E", "dark": "#141317", "light": "#F5F2EC", "pattern": "tuxedo", "eyes": "#9BC53D"},
	{"base": "#EFE4D0", "dark": "#5A4232", "light": "#FBF5EA", "pattern": "points", "eyes": "#5B9BD5"},
	{"base": "#9C7656", "dark": "#5E4230", "light": "#E3CDB4", "pattern": "tabby", "eyes": "#C9A43A"},
]
const CALICO := ["#E8954A", "#2A282E", "#E8954A"]
const PINK := Color("#E89AA8")
const HEART := Color("#FF6F91")
const PET_TIME := 2.8

var coat: Dictionary = COATS[0]
var size := 0.7
var facing := 1
var wander := true
var bounds := Vector2(0, 1000)
var charlotte: Character

var _state := "sit"
var _timer := 2.0
var _target := 0.0
var _speed := 50.0
var _t := 0.0
var _step := 0.0
var _blink := 2.0
var _life := 60.0
var _reserved := false
var _heart_in := 0.0
var _hearts: Array[Vector3] = []
var _patches: Array[Vector3] = []
var _line: Color


static func random(rng: RandomNumberGenerator) -> StrayCat:
	var cat := StrayCat.new()
	cat.coat = COATS[rng.randi_range(0, COATS.size() - 1)]
	cat.size = rng.randf_range(0.62, 0.76)
	cat.facing = 1 if rng.randf() < 0.5 else -1
	cat._life = rng.randf_range(40.0, 90.0)
	if cat.coat.pattern == "calico":
		for i in 4:
			cat._patches.append(Vector3(rng.randf_range(-0.6, 0.6), rng.randf_range(-0.5, 0.3), rng.randf_range(0.25, 0.4)))
	return cat


func _ready() -> void:
	_line = Color(coat.base).darkened(0.62)
	_blink = randf_range(1.0, 4.0)
	_t = randf_range(0.0, 10.0)
	add_to_group("interactable")
	_apply_facing()


# ── Behaviour ────────────────────────────────────────────────

func walk_to(x: float, speed := 50.0) -> void:
	_target = clampf(x, bounds.x, bounds.y)
	_speed = speed
	_state = "walk"
	if absf(_target - position.x) > 1.0:
		facing = 1 if _target > position.x else -1


func _process(delta: float) -> void:
	_t += delta
	_blink -= delta
	if _blink < -0.15:
		_blink = randf_range(1.5, 5.0)
	_update_hearts(delta)
	if wander:
		_behave(delta)
	_apply_facing()
	queue_redraw()


func _behave(delta: float) -> void:
	_life -= delta
	match _state:
		"pet":
			_timer -= delta
			_heart_in -= delta
			if _heart_in <= 0.0:
				_hearts.append(Vector3(randf_range(-6, 10), 0.0, randf_range(0.8, 1.2)))
				_heart_in = 0.45
			if _timer <= 0.0:
				_settle("sit", randf_range(5.0, 9.0))
				_life = maxf(_life, 25.0)
		"walk", "leave":
			if _reserved:
				_settle("sit", 1.0)
				return
			var step := signf(_target - position.x) * _speed * delta
			if absf(_target - position.x) <= absf(step):
				position.x = _target
				if _state == "leave":
					_fade_out()
				else:
					_settle("sit" if randf() < 0.6 else "loaf", randf_range(3.0, 8.0))
			else:
				position.x += step
				_step = fmod(_step + absf(step) / 34.0, 1.0)
		"sit", "loaf":
			_timer -= delta
			if _reserved or _timer > 0.0:
				return
			if _life <= 0.0:
				_leave()
			elif charlotte and not charlotte.is_walking and absf(charlotte.position.x - position.x) < 260.0 and randf() < 0.5:
				# Curious: trots over and sits next to her.
				var side := signf(position.x - charlotte.position.x)
				walk_to(charlotte.position.x + (side if side != 0.0 else 1.0) * 50.0, 70.0)
			else:
				walk_to(position.x + randf_range(-320.0, 320.0), randf_range(40.0, 60.0))


func _settle(state: String, time: float) -> void:
	_state = state
	_timer = time


func _leave() -> void:
	var cam := get_viewport().get_camera_2d()
	var cx := cam.get_screen_center_position().x if cam else 640.0
	var dir := -1.0 if position.x < cx else 1.0
	walk_to(cx + dir * 900.0, 60.0)
	_state = "leave"


func _fade_out() -> void:
	_state = "gone"
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 1.2)
	tween.tween_callback(queue_free)


func _apply_facing() -> void:
	scale = Vector2(facing * size, size)


# ── Interaction (see Main._unhandled_input) ──────────────────

func can_interact() -> bool:
	return _state != "leave" and _state != "gone"


func hit_test(p: Vector2) -> bool:
	return Rect2(global_position + Vector2(-38, -64) * size, Vector2(76, 68) * size).has_point(p)


# Where Charlotte stands to pet: on her side, close enough for her hand to reach the head.
func approach_x(from_x: float) -> float:
	var side := signf(from_x - position.x)
	return position.x + (side if side != 0.0 else 1.0) * 26.0


func reserve() -> void:
	_reserved = true


func release() -> void:
	_reserved = false


func interact(who: Character) -> void:
	_reserved = false
	facing = 1 if who.position.x > position.x else -1
	_settle("pet", PET_TIME)
	_heart_in = 0.2
	who.pet(PET_TIME)


func _update_hearts(delta: float) -> void:
	for i in range(_hearts.size() - 1, -1, -1):
		_hearts[i].y += delta
		if _hearts[i].y > 1.6:
			_hearts.remove_at(i)


# ── Drawing (facing right, feet on y = 0) ────────────────────

func _draw() -> void:
	draw_set_transform(Vector2(4, 0), 0.0, Vector2(1.0, 0.22))
	draw_circle(Vector2.ZERO, 30.0 if _state in ["walk", "leave", "loaf"] else 22.0, Color(0.15, 0.08, 0.05, 0.25))
	draw_set_transform(Vector2.ZERO)
	match _state:
		"walk", "leave", "gone":
			_draw_walking()
		"loaf":
			_draw_loaf()
		_:
			_draw_sitting()
	for h in _hearts:
		var a := 1.0 - h.y / 1.6
		_heart(Vector2(h.x, -58.0 - h.y * 34.0), 5.0 * h.z, Color(HEART, a))


func _draw_walking() -> void:
	var body := Vector2(0, -27)
	var r := Vector2(26, 12)
	var cyc := _step * TAU
	# Far legs first, darker.
	_leg(Vector2(-14, -24), Vector2(-14 + sin(cyc + PI) * 6.0, -maxf(0.0, cos(cyc + PI)) * 3.0), true)
	_leg(Vector2(15, -24), Vector2(15 + sin(cyc) * 6.0, -maxf(0.0, cos(cyc)) * 3.0), true)
	var sway := sin(_t * 3.0) * 4.0
	_tail([Vector2(-23, -31), Vector2(-33, -40 + sway * 0.3), Vector2(-38, -52 + sway), Vector2(-34, -60 + sway)])
	_body(body, r)
	_leg(Vector2(-19, -22), Vector2(-19 + sin(cyc) * 6.0, -maxf(0.0, cos(cyc)) * 3.0), false)
	_leg(Vector2(20, -22), Vector2(20 + sin(cyc + PI) * 6.0, -maxf(0.0, cos(cyc + PI)) * 3.0), false)
	_head(Vector2(28, -40), 0.0)


func _draw_sitting() -> void:
	var pet := _state == "pet"
	var flick := sin(_t * (9.0 if pet else 2.0)) * (5.0 if pet else 3.0)
	if pet:
		_tail([Vector2(-14, -12), Vector2(-20, -26), Vector2(-19 + flick * 0.4, -40), Vector2(-16 + flick, -52)])
	else:
		_tail([Vector2(-14, -4), Vector2(-4, 0), Vector2(10, 0), Vector2(18, -4 + flick)])
	_body(Vector2(-5, -15), Vector2(14, 13))
	_body(Vector2(3, -28), Vector2(11, 16), 0.25)
	for x in [3.0, 10.0]:
		_leg(Vector2(x, -18), Vector2(x, 0), false)
	var tilt := sin(_t * 3.0) * 0.12 if pet else sin(_t * 0.7) * 0.05
	_head(Vector2(7, -46), tilt)


func _draw_loaf() -> void:
	_tail([Vector2(-22, -5), Vector2(-10, -1), Vector2(6, -1), Vector2(16, -3 + sin(_t * 1.5) * 2.0)])
	_body(Vector2(0, -12), Vector2(24, 12))
	_ellipse(Vector2(18, -3), Vector2(5, 3), _paw_color())
	_head(Vector2(20, -25), 0.0)


func _body(c: Vector2, r: Vector2, rot := 0.0) -> void:
	_ellipse(c, r, Color(coat.base), rot)
	var inside := func(u: float, v: float) -> Vector2:
		return c + Vector2(u * r.x, v * r.y).rotated(rot)
	match coat.pattern:
		"tabby":
			for u in [-0.6, -0.3, 0.0, 0.3]:
				var top := -sqrt(1.0 - u * u)
				draw_line(inside.call(u, top + 0.08), inside.call(u - 0.08, top + 0.85), Color(coat.dark), 3.0, true)
		"calico":
			for i in _patches.size():
				var p := _patches[i]
				var room := minf(p.z, 1.0 - Vector2(p.x, p.y).length())
				if room > 0.08:
					draw_circle(inside.call(p.x, p.y), room * minf(r.x, r.y), Color(CALICO[i % CALICO.size()]))
		"tuxedo":
			_ellipse(inside.call(0.45, 0.35), Vector2(r.x * 0.42, r.y * 0.5), Color(coat.light), rot, false)
		"points":
			_ellipse(c, r, Color(Color(coat.dark), 0.12), rot, false)


func _leg(top: Vector2, foot: Vector2, far: bool) -> void:
	var col := Color(coat.base).darkened(0.18 if far else 0.0)
	draw_line(top, foot, _line, 7.5, true)
	draw_line(top, foot, col, 5.0, true)
	draw_circle(foot + Vector2(1, -1), 3.0, _paw_color().darkened(0.18 if far else 0.0))


func _paw_color() -> Color:
	match coat.pattern:
		"tuxedo":
			return Color(coat.light)
		"points":
			return Color(coat.dark)
	return Color(coat.base)


func _tail(pts: Array[Vector2]) -> void:
	var curve := PackedVector2Array()
	for i in 13:
		var t := i / 12.0
		var a := pts[0].lerp(pts[1], t)
		var b := pts[1].lerp(pts[2], t)
		var c := pts[2].lerp(pts[3], t)
		curve.append(a.lerp(b, t).lerp(b.lerp(c, t), t))
	draw_polyline(curve, _line, 7.5, true)
	var col := Color(coat.dark) if coat.pattern == "points" else Color(coat.base)
	draw_polyline(curve, col, 5.0, true)
	if coat.pattern == "tabby":
		for i in [4, 7, 10]:
			draw_circle(curve[i], 2.6, Color(coat.dark))


func _head(c: Vector2, tilt: float) -> void:
	draw_set_transform(c, tilt)
	var base := Color(coat.base)
	var ear_col := Color(coat.dark) if coat.pattern == "points" else base
	for ear in [[Vector2(-10, -4), Vector2(-7, -18), Vector2(0, -9)], [Vector2(2, -10), Vector2(9, -18), Vector2(11, -3)]]:
		var tri := PackedVector2Array(ear)
		draw_colored_polygon(tri, ear_col)
		tri.append(ear[0])
		draw_polyline(tri, _line, 2.0, true)
		draw_colored_polygon(PackedVector2Array([ear[0].lerp(ear[2], 0.25), ear[1].lerp(ear[0].lerp(ear[2], 0.5), 0.3), ear[2].lerp(ear[0], 0.25)]), PINK)
	_ellipse(Vector2.ZERO, Vector2(13, 11.5), base)
	match coat.pattern:
		"tabby":
			for x in [-3.0, 0.5, 4.0]:
				draw_line(Vector2(x, -11), Vector2(x, -7), Color(coat.dark), 1.8, true)
		"tuxedo":
			_ellipse(Vector2(7, 5), Vector2(6.5, 5), Color(coat.light), 0.0, false)
		"points":
			_ellipse(Vector2(6, 3), Vector2(7.5, 6.5), Color(Color(coat.dark), 0.8), 0.0, false)
		"calico":
			draw_circle(Vector2(-6, -5), 5.0, Color(CALICO[0]))
	var eyes := Color(coat.eyes)
	for x in [-1.0, 7.5]:
		var e := Vector2(x, -1)
		if _state == "pet":
			draw_arc(e + Vector2(0, 1.5), 2.6, PI * 1.15, PI * 1.85, 6, _line, 1.4, true)
		elif _blink > 0.0:
			draw_circle(e, 2.9, eyes)
			draw_line(e + Vector2(0, -2.2), e + Vector2(0, 2.2), Color.BLACK, 1.3)
			draw_circle(e + Vector2(0.9, -1.0), 0.8, Color.WHITE)
		else:
			draw_line(e + Vector2(-2.5, 0.5), e + Vector2(2.5, 0.5), _line, 1.3, true)
	draw_circle(Vector2(-4, 4), 2.4, Color(PINK, 0.45))
	draw_circle(Vector2(11, 4), 2.0, Color(PINK, 0.45))
	draw_colored_polygon(PackedVector2Array([Vector2(10.5, 2.5), Vector2(13.5, 2.5), Vector2(12, 4.5)]), PINK.darkened(0.15))
	draw_arc(Vector2(11, 5.5), 1.6, 0.2, PI - 0.2, 5, _line, 1.0, true)
	draw_arc(Vector2(14, 5.5), 1.6, 0.2, PI - 0.2, 5, _line, 1.0, true)
	for w in [-1.0, 1.0]:
		draw_line(Vector2(13, 4.5), Vector2(22, 3.0 + w * 3.0), Color(1, 1, 1, 0.6), 0.7, true)
	draw_set_transform(Vector2.ZERO)


func _ellipse(c: Vector2, r: Vector2, col: Color, rot := 0.0, outline := true) -> void:
	var pts := PackedVector2Array()
	for i in 28:
		var a := TAU * i / 28.0
		pts.append(c + Vector2(cos(a) * r.x, sin(a) * r.y).rotated(rot))
	draw_colored_polygon(pts, col)
	if outline:
		pts.append(pts[0])
		draw_polyline(pts, _line, 2.0, true)


func _heart(c: Vector2, s: float, col: Color) -> void:
	draw_circle(c + Vector2(-s * 0.5, 0), s * 0.6, col)
	draw_circle(c + Vector2(s * 0.5, 0), s * 0.6, col)
	draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 1.08, s * 0.2), c + Vector2(s * 1.08, s * 0.2), c + Vector2(0, s * 1.4)]), col)
