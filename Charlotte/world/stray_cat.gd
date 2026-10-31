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
	Sfx.play("meow", global_position)
	Sfx.play("purr", global_position, -4.0)
	who.pet(PET_TIME)


func _update_hearts(delta: float) -> void:
	for i in range(_hearts.size() - 1, -1, -1):
		_hearts[i].y += delta
		if _hearts[i].y > 1.6:
			_hearts.remove_at(i)


# ── Drawing (facing right, feet on y = 0) ────────────────────

func _draw() -> void:
	CritterDraw.ground_shadow(self, Vector2(4, 0), 30.0 if _state in ["walk", "leave", "gone", "loaf"] else 22.0)
	match _state:
		"walk", "leave", "gone":
			_draw_walking()
		"loaf":
			_draw_loaf()
		_:
			_draw_sitting()
	CritterDraw.hearts(self, _hearts, Vector2(0, -62))


func _draw_walking() -> void:
	var cyc := _step * TAU
	var bob := absf(sin(cyc)) * 1.2
	var body := Vector2(0, -24 - bob)
	# Far legs first, in shade.
	_leg(Vector2(-14, -22 - bob), cyc + PI, true, true)
	_leg(Vector2(14, -22 - bob), cyc, true, false)
	var sway := sin(_t * 3.0) * 4.0
	_tail([Vector2(-21, -29 - bob), Vector2(-34, -34 + sway * 0.3), Vector2(-40, -50 + sway), Vector2(-33, -60 + sway)])
	_body(body, Vector2(24, 11.5))
	_leg(Vector2(-18, -20 - bob), cyc, false, true)
	_leg(Vector2(18, -20 - bob), cyc + PI, false, false)
	_head(Vector2(26, -38 - bob * 0.6), sin(cyc * 2.0) * 0.03)


func _draw_sitting() -> void:
	var pet := _state == "pet"
	var flick := sin(_t * (9.0 if pet else 2.0)) * (5.0 if pet else 3.0)
	if pet:
		_tail([Vector2(-13, -12), Vector2(-21, -26), Vector2(-19 + flick * 0.4, -42), Vector2(-15 + flick, -54)])
	else:
		_tail([Vector2(-13, -4), Vector2(-3, 1), Vector2(11, 0), Vector2(19, -5 + flick)])
	_body(Vector2(-5, -14), Vector2(14, 13))
	_body(Vector2(3, -27), Vector2(11, 16), 0.22)
	for x in [3.0, 10.0]:
		_limb(PackedVector2Array([Vector2(x, -20), Vector2(x, -2)]), 5.5, false)
		_paw(Vector2(x + 1, -1.5), false)
	var tilt := sin(_t * 3.0) * 0.12 if pet else sin(_t * 0.7) * 0.05
	_head(Vector2(7, -45), tilt)


func _draw_loaf() -> void:
	_tail([Vector2(-21, -5), Vector2(-9, 0), Vector2(7, 0), Vector2(17, -3 + sin(_t * 1.5) * 2.0)])
	_body(Vector2(0, -12), Vector2(23, 12))
	_paw(Vector2(18, -2.5), false)
	_paw(Vector2(12, -1.5), false)
	_head(Vector2(19, -25), 0.0)


func _body(c: Vector2, r: Vector2, rot := 0.0) -> void:
	var belly := Color(coat.light) if coat.pattern in ["tabby", "tuxedo"] else Color(coat.light, 0.5)
	CritterDraw.body(self, c, r, Color(coat.base), belly, _line, rot, func(): _pattern(c, r, rot))


func _pattern(c: Vector2, r: Vector2, rot: float) -> void:
	var inside := func(u: float, v: float) -> Vector2:
		return c + Vector2(u * r.x, v * r.y).rotated(rot)
	match coat.pattern:
		"tabby":
			for u in [-0.62, -0.32, -0.02, 0.28]:
				var top := -sqrt(1.0 - u * u)
				var pts := PackedVector2Array([inside.call(u, top + 0.06), inside.call(u - 0.07, top + 0.5), inside.call(u - 0.02, top + 0.85)])
				draw_polyline(pts, Color(coat.dark), 2.6, true)
		"calico":
			for i in _patches.size():
				var p := _patches[i]
				var room := minf(p.z, 1.0 - Vector2(p.x, p.y).length())
				if room > 0.08:
					draw_circle(inside.call(p.x, p.y), room * minf(r.x, r.y), Color(CALICO[i % CALICO.size()]))
		"tuxedo":
			CritterDraw.ellipse(self, inside.call(0.45, 0.3), Vector2(r.x * 0.42, r.y * 0.52), Color(coat.light), Color.TRANSPARENT, rot)
		"points":
			CritterDraw.band(self, c, r, -1.0, -0.4, Color(Color(coat.dark), 0.18), rot)


# A leg swinging with the walk cycle; back legs bend at the hock.
func _leg(hip: Vector2, phase: float, far: bool, back: bool) -> void:
	var swing := sin(phase) * 6.0
	var lift := maxf(0.0, cos(phase)) * 3.0
	var foot := Vector2(hip.x + swing, -lift - 1.5)
	var pts := PackedVector2Array([hip])
	if back:
		pts.append(hip.lerp(foot, 0.55) + Vector2(-3.5, 0))
	pts.append(foot)
	_limb(pts, 6.0 if back else 5.5, far)
	_paw(foot + Vector2(1, 0), far)


func _limb(pts: PackedVector2Array, w: float, far: bool) -> void:
	var col := Color(coat.base).darkened(0.2 if far else 0.0)
	CritterDraw.taper(self, pts, w, w * 0.8, col, _line)


func _paw(c: Vector2, far: bool) -> void:
	CritterDraw.ellipse(self, c, Vector2(3.6, 2.5), _paw_color().darkened(0.2 if far else 0.0), _line, 0.0, 1.5)


func _paw_color() -> Color:
	match coat.pattern:
		"tuxedo":
			return Color(coat.light)
		"points":
			return Color(coat.dark)
	return Color(coat.base)


func _tail(ctrl: Array[Vector2]) -> void:
	var pts := CritterDraw.curve(ctrl, 14)
	var col := Color(coat.dark) if coat.pattern == "points" else Color(coat.base)
	CritterDraw.taper(self, pts, 6.5, 4.5, col, _line)
	if coat.pattern == "tabby":
		for i in [5, 8, 11, 14]:
			var d := (pts[i] - pts[i - 1]).normalized().orthogonal()
			draw_line(pts[i] - d * 2.4, pts[i] + d * 2.4, Color(coat.dark), 2.2, true)


# Big round head with cheek fluff, rounded ears and glossy eyes (three-quarter view, looking right).
func _head(c: Vector2, tilt: float) -> void:
	draw_set_transform(c, tilt)
	var base := Color(coat.base)
	var ear_col := Color(coat.dark) if coat.pattern == "points" else base
	for ear in [[Vector2(-12, -3), Vector2(-9, -19), Vector2(-1, -11)], [Vector2(3, -12), Vector2(11, -19), Vector2(13, -2)]]:
		var tri := CritterDraw.curve([ear[0], ear[1] + Vector2(-1, -2), ear[1] + Vector2(2, -1), ear[2]], 8)
		draw_colored_polygon(tri, ear_col)
		tri.append(tri[0])
		draw_polyline(tri, _line, 2.0, true)
		var inner := PackedVector2Array([ear[0].lerp(ear[2], 0.28), ear[1].lerp(ear[0].lerp(ear[2], 0.5), 0.3), ear[2].lerp(ear[0], 0.28)])
		draw_colored_polygon(inner, Color("#F2A7B4"))
		draw_line(inner[0].lerp(inner[2], 0.5), inner[1].lerp(inner[0].lerp(inner[2], 0.5), 0.4), Color(1, 1, 1, 0.6), 1.0, true)
	# Head outline with fluffy cheeks.
	var head := PackedVector2Array()
	for i in 36:
		var a := TAU * i / 36.0
		var r := Vector2(15.0, 13.0)
		var cheek := (a > 0.35 and a < 1.25) or (a > 1.9 and a < 2.8)
		var k := 1.0 + (0.1 if cheek and i % 2 == 0 else 0.0)
		head.append(Vector2(cos(a) * r.x, sin(a) * r.y + 1.0) * k)
	draw_colored_polygon(head, base)
	match coat.pattern:
		"tabby":
			for x in [-3.5, 0.5, 4.5]:
				draw_line(Vector2(x, -12), Vector2(x * 0.8, -7.5), Color(coat.dark), 1.8, true)
			draw_line(Vector2(-14, 2), Vector2(-9, 3), Color(coat.dark), 1.5, true)
		"tuxedo":
			CritterDraw.ellipse(self, Vector2(7, 6), Vector2(7.5, 6.0), Color(coat.light))
			draw_colored_polygon(PackedVector2Array([Vector2(4, 2), Vector2(7, -9), Vector2(10, 2)]), Color(coat.light))
		"points":
			CritterDraw.ellipse(self, Vector2(6, 4), Vector2(8.5, 7.0), Color(Color(coat.dark), 0.75))
		"calico":
			draw_circle(Vector2(-7, -5), 6.0, Color(CALICO[0]))
			draw_circle(Vector2(9, -7), 4.0, Color(CALICO[1]))
	CritterDraw.ellipse(self, Vector2(-5, -6), Vector2(6, 3.5), Color(1, 0.97, 0.9, 0.18))
	head.append(head[0])
	draw_polyline(head, _line, 2.0, true)
	var mode := "happy" if _state == "pet" else ("open" if _blink > 0.0 else "closed")
	CritterDraw.eye(self, Vector2(-2.5, 0), 3.2, Color(coat.eyes), _line, mode, true)
	CritterDraw.eye(self, Vector2(7.5, 0), 3.6, Color(coat.eyes), _line, mode, true)
	draw_circle(Vector2(-6, 6), 2.6, Color("#F2A7B4", 0.5))
	draw_circle(Vector2(13, 6), 2.2, Color("#F2A7B4", 0.5))
	# Muzzle puffs, nose, mouth and whiskers.
	var muzzle := Color(coat.light) if coat.pattern != "points" else Color(coat.dark).lightened(0.15)
	draw_circle(Vector2(10.5, 6.5), 3.0, muzzle)
	draw_circle(Vector2(14.5, 6.5), 2.6, muzzle)
	draw_colored_polygon(PackedVector2Array([Vector2(11, 3.5), Vector2(14.5, 3.5), Vector2(12.8, 5.6)]), Color("#E07F92"))
	draw_arc(Vector2(11.6, 6.4), 1.4, 0.2, PI - 0.2, 5, _line, 1.0, true)
	draw_arc(Vector2(14.0, 6.4), 1.4, 0.2, PI - 0.2, 5, _line, 1.0, true)
	for w in [-1.0, 0.0, 1.0]:
		draw_line(Vector2(15, 5.5 + w), Vector2(24, 4.0 + w * 3.0), Color(1, 1, 1, 0.65), 0.7, true)
	draw_set_transform(Vector2.ZERO)
