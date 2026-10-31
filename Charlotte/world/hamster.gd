class_name Hamster
extends Node2D
## Charlotte's hamster in the terrarium on her dresser: scurries over the bedding, washes its face, runs in
## its wheel, naps curled up, and stands up with hearts when clicked. The node sits at the terrarium's
## top-left with the terrarium's scale, so everything here is in InteriorArt.terrarium() canvas units.

const FLOOR := 152.0
const ROAM := Vector2(28.0, 296.0)
const WHEEL := Vector2(128.0, 114.0)
const WHEEL_R := 36.0
const HIDEOUT_X := 222.0
const FUR := Color("#E8A65A")
const BELLY := Color("#FBF1E2")
const PINK := Color("#F2A7B4")
const SIZE := 1.25
## The food bowl, on the bedding between the wheel and the hideout (the photo frames hide the left).
const BOWL_X := 168.0

var _x := 160.0
var _state := "sit"
var _timer := 2.0
var _target := 0.0
var _facing := 1
var _t := 0.0
var _step := 0.0
var _spin := 0.0
var _blink := 2.0
var _hearts: Array[Vector3] = []
var _line := FUR.darkened(0.55)
# Seeds falling into the bowl (x, y, speed), seeds in the bowl, and whether it's heading there to eat.
var _falling: Array[Vector3] = []
var _bowl := 0
var _hungry := false


func _ready() -> void:
	add_to_group("interactable")


func _process(delta: float) -> void:
	_t += delta
	_blink -= delta
	if _blink < -0.15:
		_blink = randf_range(1.5, 4.0)
	_timer -= delta
	_drop_seeds(delta)
	match _state:
		"walk":
			var step := signf(_target - _x) * (110.0 if _hungry else 70.0) * delta
			if absf(_target - _x) <= absf(step):
				_x = _target
				if _hungry and is_equal_approx(_x, BOWL_X + 22.0):
					_facing = -1
					_settle("eat", 0.7)
				elif is_equal_approx(_x, WHEEL.x) and randf() < 0.8:
					_settle("wheel", randf_range(5.0, 10.0))
				elif is_equal_approx(_x, HIDEOUT_X) and randf() < 0.6:
					_settle("sleep", randf_range(6.0, 12.0))
				else:
					_settle(["sit", "groom", "sniff"][randi() % 3], randf_range(1.5, 4.0))
			else:
				_x += step
				_step = fmod(_step + delta * 9.0, 1.0)
		"eat":
			# One seed every 0.7 s, then a happy little dance of hearts.
			if _timer <= 0.0:
				if _bowl > 0:
					_bowl -= 1
					_timer = 0.7
				elif _falling.is_empty():
					_hungry = false
					_settle("up", 2.0)
					for i in 3:
						_hearts.append(Vector3(randf_range(-8.0, 8.0), -i * 0.35, randf_range(0.6, 0.9)))
				else:
					_timer = 0.2
		"wheel":
			_spin += delta * 9.0
			_step = fmod(_step + delta * 12.0, 1.0)
			if _timer <= 0.0:
				_walk_to(randf_range(ROAM.x, ROAM.y))
		_:
			if _timer <= 0.0 and _hungry:
				_walk_to(BOWL_X + 22.0)
			elif _timer <= 0.0:
				var roll := randf()
				if roll < 0.3:
					_walk_to(WHEEL.x)
				elif roll < 0.42:
					_walk_to(HIDEOUT_X)
				else:
					_walk_to(randf_range(ROAM.x, ROAM.y))
	for i in range(_hearts.size() - 1, -1, -1):
		_hearts[i].y += delta
		if _hearts[i].y > 1.6:
			_hearts.remove_at(i)
	queue_redraw()


func _walk_to(x: float) -> void:
	_target = clampf(x, ROAM.x, ROAM.y)
	_state = "walk"
	if absf(_target - _x) > 0.5:
		_facing = 1 if _target > _x else -1


func _settle(state: String, time: float) -> void:
	_state = state
	_timer = time


func _drop_seeds(delta: float) -> void:
	for i in range(_falling.size() - 1, -1, -1):
		var sd := _falling[i]
		sd.z += 320.0 * delta
		sd.y += sd.z * delta
		if sd.y >= FLOOR - 6.0:
			_falling.remove_at(i)
			_bowl += 1
		else:
			_falling[i] = sd


# ── Interaction: click it with an empty bowl and Charlotte feeds it; otherwise it stands up to say hi ──

func can_interact() -> bool:
	return true


func hit_test(p: Vector2) -> bool:
	return Rect2(_x - 30.0, FLOOR - 50.0, 60.0, 56.0).has_point(to_local(p))


func approach_x(_from_x: float) -> float:
	return focus_x()


func focus_x() -> float:
	return to_global(Vector2(_x, FLOOR)).x


func reserve() -> void:
	pass


func release() -> void:
	pass


func interact(_who: Character) -> void:
	if _state == "wheel" or _state == "walk":
		_x = clampf(_x, ROAM.x, ROAM.y)
	if _bowl == 0 and _falling.is_empty() and not _hungry:
		# A pinch of sunflower seeds sprinkled into the bowl; it scurries over to eat.
		for i in 7:
			_falling.append(Vector3(BOWL_X + randf_range(-9.0, 9.0), 24.0 - i * 6.0, 0.0))
		_hungry = true
		_walk_to(BOWL_X + 22.0)
		return
	_settle("up", 2.4)
	for i in 3:
		_hearts.append(Vector3(randf_range(-8.0, 8.0), -i * 0.35, randf_range(0.6, 0.9)))


# ── Drawing ──────────────────────────────────────────────────

func _draw() -> void:
	_draw_wheel(false)
	_draw_bowl()
	var running := _state == "wheel"
	var at := Vector2(WHEEL.x, WHEEL.y + WHEEL_R - 3.0) if running else Vector2(_x, FLOOR)
	if not running:
		CritterDraw.ground_shadow(self, at + Vector2(1, 1), 14.0 * SIZE)
	draw_set_transform(at, 0.0, Vector2(_facing, 1.0) * SIZE)
	match _state:
		"walk", "wheel":
			_draw_scurry()
		"sleep":
			_draw_sleep()
		"up":
			_draw_upright(true)
		"eat":
			_draw_eating()
		_:
			_draw_upright(false)
	draw_set_transform(Vector2.ZERO)
	_draw_wheel(true)
	CritterDraw.hearts(self, _hearts.filter(func(h): return h.y >= 0.0), Vector2(_x, FLOOR - 50.0 * SIZE))


# The wheel's stand, rim and spokes behind the hamster; just the near rim in front of it.
func _draw_wheel(front: bool) -> void:
	var rim := Color("#8FB5D5")
	if front:
		draw_arc(WHEEL, WHEEL_R, PI * 0.15, PI * 0.85, 16, Color(rim, 0.8), 2.5, true)
		return
	draw_line(WHEEL, WHEEL + Vector2(-18, 38), Color("#6E8EAE"), 4.0, true)
	draw_line(WHEEL, WHEEL + Vector2(18, 38), Color("#6E8EAE"), 4.0, true)
	draw_circle(WHEEL, WHEEL_R, Color(0.85, 0.92, 0.97, 0.35))
	for i in 8:
		var a := _spin + TAU * i / 8.0
		draw_line(WHEEL, WHEEL + Vector2(cos(a), sin(a)) * WHEEL_R, Color(rim, 0.7), 1.5, true)
	draw_arc(WHEEL, WHEEL_R, 0.0, TAU, 40, rim, 3.0, true)
	draw_arc(WHEEL, WHEEL_R - 4.0, 0.0, TAU, 40, Color(rim, 0.5), 1.5, true)
	draw_circle(WHEEL, 4.0, Color("#6E8EAE"))


# On all fours: a fluffy oval with a round head, legs blurring as it runs.
func _draw_scurry() -> void:
	var cyc := _step * TAU
	var bob := absf(sin(cyc)) * 1.2
	for i in 2:
		var ph := cyc + PI * i
		draw_circle(Vector2(-7 + i * 13 + sin(ph) * 3.0, -1.5), 2.6, PINK.darkened(0.1))
	CritterDraw.body(self, Vector2(0, -9 - bob), Vector2(15, 9.5), FUR, BELLY, _line)
	_head(Vector2(12, -12 - bob), false)


# Sitting up: grooming (paws scrubbing the face), sniffing, or standing tall when clicked.
func _draw_upright(standing: bool) -> void:
	var tall := 5.0 if standing else 0.0
	CritterDraw.body(self, Vector2(-1, -12 - tall), Vector2(11, 12 + tall * 0.5), FUR, BELLY, _line)
	CritterDraw.ellipse(self, Vector2(1, -9 - tall), Vector2(6.5, 8), BELLY)
	for x in [-5.0, 5.0]:
		CritterDraw.ellipse(self, Vector2(x, -1), Vector2(3.5, 2), PINK, _line, 0.0, 1.2)
	var head := Vector2(3, -26 - tall * 1.6)
	if _state == "sniff":
		head += Vector2(2.0 + sin(_t * 10.0), 0)
	_head(head, false)
	var scrub := sin(_t * 14.0) * 3.0 if _state == "groom" else 0.0
	var paw_y := -20.0 - tall * 1.4 + (scrub if _state == "groom" else 4.0)
	for x in [3.0, 9.0]:
		CritterDraw.ellipse(self, Vector2(x, paw_y), Vector2(2.6, 2.2), PINK, _line, 0.0, 1.2)


# Sitting up at the bowl, a seed in its paws, cheeks stuffed and nose twitching.
func _draw_eating() -> void:
	_draw_upright(false)
	var munch := absf(sin(_t * 16.0)) * 1.2
	for x in [-3.0, 9.0]:
		CritterDraw.ellipse(self, Vector2(x, -22 + munch * 0.3), Vector2(4.5 + munch, 3.8 + munch * 0.5), FUR, _line, 0.0, 1.2)
	CritterDraw.ellipse(self, Vector2(8, -18), Vector2(2.4, 1.4), Color("#4A4038"), Color.TRANSPARENT, 0.4)
	draw_line(Vector2(7.3, -18.5), Vector2(8.7, -17.5), Color("#E8E2D6"), 0.6)


func _draw_bowl() -> void:
	var b := Vector2(BOWL_X, FLOOR)
	CritterDraw.ellipse(self, b + Vector2(0, -3), Vector2(14, 5), Color("#7FB5D9"), Color("#4E7FA0"), 0.0, 1.5)
	CritterDraw.ellipse(self, b + Vector2(0, -6), Vector2(11, 2.6), Color("#5A8FB5"))
	for i in mini(_bowl, 9):
		CritterDraw.ellipse(self, b + Vector2(-8 + (i * 5) % 16, -7 - (i / 4) * 1.5), Vector2(2.2, 1.2), Color("#4A4038"), Color.TRANSPARENT, 0.5)
	for sd in _falling:
		CritterDraw.ellipse(self, Vector2(sd.x, sd.y), Vector2(2.2, 1.2), Color("#4A4038"), Color.TRANSPARENT, sd.y * 0.1)


# Curled up asleep in a ball, with a little "z" floating up.
func _draw_sleep() -> void:
	var breathe := sin(_t * 2.0) * 0.6
	CritterDraw.body(self, Vector2(0, -8), Vector2(14, 8 + breathe), FUR, BELLY, _line)
	_head(Vector2(9, -9), true)
	var z := fmod(_t * 0.6, 1.0)
	var zp := Vector2(10 + z * 8.0, -22 - z * 16.0)
	var zc := Color(_line, 1.0 - z)
	draw_polyline(PackedVector2Array([zp, zp + Vector2(5, 0), zp + Vector2(0, 5), zp + Vector2(5, 5)]), zc, 1.2, true)


func _head(c: Vector2, asleep: bool) -> void:
	for e in [Vector2(-4, -7), Vector2(2, -8)]:
		CritterDraw.ellipse(self, c + e, Vector2(3.4, 3.8), FUR, _line, 0.0, 1.5)
		CritterDraw.ellipse(self, c + e + Vector2(0, 0.5), Vector2(1.8, 2.2), PINK)
	CritterDraw.ellipse(self, c, Vector2(8.5, 7.5), FUR, _line, 0.0, 1.8)
	CritterDraw.ellipse(self, c + Vector2(3, 3), Vector2(5, 3.6), BELLY)
	if asleep or _blink <= 0.0:
		draw_arc(c + Vector2(3, -1), 1.8, 0.2, PI - 0.2, 5, _line, 1.2, true)
	else:
		draw_circle(c + Vector2(3, -1.5), 1.9, Color("#1A1412"))
		draw_circle(c + Vector2(2.4, -2.2), 0.7, Color.WHITE)
	draw_circle(c + Vector2(8.4, 1), 1.5, Color("#E07F92"))
	draw_circle(c + Vector2(-1, 3), 1.8, Color(PINK, 0.6))
	for w in [-1.0, 1.0]:
		draw_line(c + Vector2(8, 2), c + Vector2(14, 1.0 + w * 2.0), Color(1, 1, 1, 0.7), 0.6, true)
