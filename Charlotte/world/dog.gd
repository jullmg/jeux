class_name Dog
extends Node2D
## Procedural dog on a leash: trots ahead of its walker, sniffs around when they stop, wags.
## Clickable: Charlotte walks over and pets it while the walker waits (same API as StrayCat). To be petted
## it steps toward the camera, in front of Charlotte, so her hand lands on its head like with the cats.
## Breed sizes are in local units at scale 1: body half-length/half-height, leg, head radius, snout length.

const BREEDS := {
	"labrador": {"len": 26.0, "h": 11.0, "leg": 20.0, "head": 10.0, "snout": 9.0, "ear": "floppy", "tail": "otter",
		"coats": [["#E8C27A"], ["#2B2724"], ["#6B4430"]]},
	"dachshund": {"len": 25.0, "h": 8.0, "leg": 7.0, "head": 8.5, "snout": 10.0, "ear": "long", "tail": "thin",
		"coats": [["#8A4A26"], ["#2B2420", "", "#B8743A"]]},
	"corgi": {"len": 20.0, "h": 10.0, "leg": 8.0, "head": 9.5, "snout": 7.0, "ear": "big", "tail": "stub",
		"coats": [["#E39A4A", "", "#FFFFFF"]]},
	"poodle": {"len": 16.0, "h": 10.0, "leg": 18.0, "head": 8.5, "snout": 8.0, "ear": "fluffy", "tail": "pompom", "fluffy": true,
		"coats": [["#F4EFE6"], ["#E8B98A"], ["#2B2B2E"]]},
	"husky": {"len": 24.0, "h": 11.0, "leg": 18.0, "head": 10.0, "snout": 8.0, "ear": "pointy", "tail": "curl",
		"coats": [["#7D8590", "#4E555E", "#F4F4F2"]], "eyes": "#6FB7E8"},
	"beagle": {"len": 19.0, "h": 9.5, "leg": 12.0, "head": 9.0, "snout": 7.0, "ear": "floppy", "tail": "up",
		"coats": [["#C8843E", "#2B2724", "#FFFFFF"]]},
	"pug": {"len": 15.0, "h": 9.5, "leg": 10.0, "head": 10.0, "snout": 2.5, "ear": "fold", "tail": "curl",
		"coats": [["#E3C08E", "", "", "#2B2724"]]},
	"dalmatian": {"len": 24.0, "h": 10.0, "leg": 21.0, "head": 9.0, "snout": 9.0, "ear": "floppy", "tail": "thin",
		"coats": [["#FAF8F4"]], "spots": true},
	"chihuahua": {"len": 11.0, "h": 6.5, "leg": 9.0, "head": 8.0, "snout": 4.0, "ear": "big", "tail": "thin",
		"coats": [["#E9C79A"], ["#3A2E28", "", "#E9D5B8"]]},
}
const LEASHES := ["#E04F5F", "#1D4F91", "#3E8E5A", "#FF8A3D", "#7E57C2", "#FFB3C7"]
const COLLARS := ["#E04F5F", "#1D4F91", "#FFD23F", "#3E8E5A", "#C2185B"]
const PET_TIME := 2.8
const HEAD_SCALE := 1.15
const GREET_STEP := 32.0

var owner_walker: Character
var breed := "labrador"
var size := 1.15
var facing := 1

var _b: Dictionary
var _base: Color
var _saddle: Color
var _white: Color
var _mask: Color
var _line: Color
var _leash: Color
var _collar_col: Color
var _spots: Array[Vector3] = []
var _lead := 60.0
var _t := 0.0
var _step := 0.0
var _moving := false
var _held := false
var _pet_time := 0.0
var _heart_in := 0.0
var _hearts: Array[Vector3] = []
var _greet := 0.0


static func random(rng: RandomNumberGenerator, walker: Character) -> Dog:
	var dog := Dog.new()
	dog.owner_walker = walker
	dog.breed = BREEDS.keys()[rng.randi_range(0, BREEDS.size() - 1)]
	dog._b = BREEDS[dog.breed]
	var coat: Array = dog._b.coats[rng.randi_range(0, dog._b.coats.size() - 1)]
	dog._base = Color(coat[0])
	dog._saddle = Color(coat[1]) if coat.size() > 1 and coat[1] != "" else Color.TRANSPARENT
	dog._white = Color(coat[2]) if coat.size() > 2 and coat[2] != "" else Color.TRANSPARENT
	dog._mask = Color(coat[3]) if coat.size() > 3 else Color.TRANSPARENT
	dog._leash = Color(LEASHES[rng.randi_range(0, LEASHES.size() - 1)])
	dog._collar_col = Color(COLLARS[rng.randi_range(0, COLLARS.size() - 1)])
	dog._lead = rng.randf_range(45.0, 75.0)
	if dog._b.get("spots", false):
		for i in 9:
			var sp := Vector2(rng.randf_range(-0.65, 0.65), rng.randf_range(-0.55, 0.45)).limit_length(0.68)
			dog._spots.append(Vector3(sp.x, sp.y, rng.randf_range(1.5, 2.5)))
	return dog


func _ready() -> void:
	_line = _base.darkened(0.6) if _base.get_luminance() > 0.25 else _base.lightened(0.1).darkened(0.55)
	_t = randf_range(0.0, 10.0)
	position = owner_walker.position + Vector2(owner_walker.facing * _lead, 4.0)
	add_to_group("interactable")


func _process(delta: float) -> void:
	_t += delta
	var walker := owner_walker
	_update_petting(delta)
	_greet = move_toward(_greet, 1.0 if _held or _pet_time > 0.0 else 0.0, delta * 2.5)
	position.y = walker.position.y + 4.0 + GREET_STEP * _greet
	z_index = 1 if _greet > 0.5 else 0
	if _held or _pet_time > 0.0:
		_moving = false
	else:
		var goal := walker.position.x + walker.facing * (_lead if walker.is_walking else _lead * 0.7)
		var dx := goal - position.x
		var max_speed := walker.walk_speed * 1.8
		var v := clampf(dx * 4.0, -max_speed, max_speed)
		if absf(dx) < 4.0:
			v = 0.0
		position.x += v * delta
		_moving = absf(v) > 12.0
		if _moving:
			facing = 1 if v > 0.0 else -1
			_step = fmod(_step + absf(v) * delta / (14.0 + float(_b.leg) * 1.6), 1.0)
	scale = Vector2(facing * size, size)
	queue_redraw()


func _update_petting(delta: float) -> void:
	if _pet_time > 0.0:
		_pet_time -= delta
		_heart_in -= delta
		if _heart_in <= 0.0:
			_hearts.append(Vector3(randf_range(-6, 10), 0.0, randf_range(0.8, 1.2)))
			_heart_in = 0.45
	for i in range(_hearts.size() - 1, -1, -1):
		_hearts[i].y += delta
		if _hearts[i].y > 1.6:
			_hearts.remove_at(i)


# ── Interaction (see Main._unhandled_input) ──────────────────

func can_interact() -> bool:
	return true


func hit_test(p: Vector2) -> bool:
	var top := (float(_b.leg) + 2.0 * float(_b.h) + 2.0 * float(_b.head) * HEAD_SCALE) * size
	var half := (float(_b.len) + float(_b.head) + float(_b.snout)) * size
	return Rect2(global_position + Vector2(-half, -top), Vector2(2.0 * half, top + 6.0)).has_point(p)


# Charlotte stands so her hand reaches the head (the dog turns to face her).
func approach_x(from_x: float) -> float:
	var side := signf(from_x - position.x)
	var head := (float(_b.len) * 0.8 + float(_b.head) * HEAD_SCALE * 0.35) * size
	return position.x + (side if side != 0.0 else 1.0) * (head + lerpf(28.0, 20.0, _pet_low()))


# How far Charlotte must crouch: her hand reaches ~37 px above her feet in a deep lunge, ~60 standing.
# Greeting, the dog stands 10 px in front of her, so its head top sits that much lower on screen.
func _pet_low() -> float:
	var hr := float(_b.head) * HEAD_SCALE
	var head_top := (float(_b.leg) + 2.0 * float(_b.h) + hr * 1.3) * size - 10.0
	return clampf((60.0 - head_top) / 23.0, 0.0, 1.0)


func reserve() -> void:
	_held = true
	owner_walker.hold(30.0)


func release() -> void:
	_held = false
	owner_walker.hold(0.4)


func interact(who: Character) -> void:
	_held = false
	_pet_time = PET_TIME
	_heart_in = 0.2
	facing = 1 if who.position.x > position.x else -1
	who.pet(PET_TIME, _pet_low())
	owner_walker.hold(PET_TIME + 1.2)


# ── Drawing (facing right, feet on y = 0) ────────────────────

func _draw() -> void:
	var L: float = _b.len
	var H: float = _b.h
	var leg: float = _b.leg
	var hr: float = float(_b.head) * HEAD_SCALE
	var petted := _pet_time > 0.0
	var cyc := _step * TAU
	var bob := absf(sin(cyc)) * 1.5 if _moving else 0.0
	var body := Vector2(0, -(leg + H) - bob)
	var sniff := not _moving and not petted and not _held and fmod(_t, 5.0) < 2.5
	CritterDraw.ground_shadow(self, Vector2(3, 0), L * 1.25)
	var lw := clampf(H * 0.7, 4.5, 8.0)
	var hips := [-L * 0.6, L * 0.55]
	_leg(Vector2(hips[0] + 3.0, body.y + H * 0.45), cyc + PI, leg, lw, true, true)
	_leg(Vector2(hips[1] + 3.0, body.y + H * 0.45), cyc, leg, lw, true, false)
	_tail(body, L, H, petted)
	_body(body, L, H)
	_leg(Vector2(hips[0] - 2.0, body.y + H * 0.6), cyc, leg, lw, false, true)
	_leg(Vector2(hips[1] - 2.0, body.y + H * 0.6), cyc + PI, leg, lw, false, false)
	var head := body + Vector2(L * 0.8 + hr * 0.35, -H - hr * 0.45)
	if sniff:
		head += Vector2(hr * 0.5, H + hr * 0.9)
	var tilt := sin(_t * 3.0) * 0.1 if petted else (sin(cyc * 2.0) * 0.04 if _moving else 0.0)
	var collar := body.lerp(head, 0.55) + Vector2(-2, 2)
	draw_line(collar + Vector2(-hr * 0.35, -hr * 0.3), collar + Vector2(hr * 0.35, hr * 0.3), _line, 5.5, true)
	draw_line(collar + Vector2(-hr * 0.35, -hr * 0.3), collar + Vector2(hr * 0.35, hr * 0.3), _collar_col, 3.5, true)
	draw_circle(collar + Vector2(hr * 0.1, hr * 0.45), 1.8, Color("#F2C94C"))
	_head(head, hr, tilt, petted)
	_draw_leash(collar)
	CritterDraw.hearts(self, _hearts, head + Vector2(0, -hr - 8.0))


func _draw_leash(collar: Vector2) -> void:
	var hand := to_local(owner_walker.hand_position())
	var mid := (collar + hand) / 2.0 + Vector2(0, 10.0 / size)
	var pts := CritterDraw.curve([collar, mid, hand], 10)
	draw_polyline(pts, _leash.darkened(0.3), 2.6 / size, true)
	draw_polyline(pts, _leash, 1.6 / size, true)


func _body(c: Vector2, L: float, H: float) -> void:
	if _b.get("fluffy", false):
		for pass_i in 2:
			for i in 12:
				var a := TAU * i / 12.0
				var p := c + Vector2(cos(a) * L * 0.85, sin(a) * H * 0.8)
				draw_circle(p, H * 0.55 if pass_i == 0 else H * 0.55 - 1.6, _line if pass_i == 0 else _base)
		CritterDraw.ellipse(self, c, Vector2(L * 0.85, H * 0.85), _base)
		CritterDraw.ellipse(self, c + Vector2(-L * 0.25, -H * 0.4), Vector2(L * 0.4, H * 0.3), Color(1, 1, 1, 0.25))
		return
	var belly := _white if _white.a > 0.0 else _base.lightened(0.18)
	CritterDraw.body(self, c, Vector2(L, H), _base, belly, _line, 0.0, func():
		if _saddle.a > 0.0:
			CritterDraw.band(self, c, Vector2(L, H), -1.0, -0.05, _saddle)
		for sp in _spots:
			draw_circle(c + Vector2(sp.x * L, sp.y * H), sp.z, Color("#222222")))
	# Thigh and shoulder lines give the body some shape.
	draw_arc(c + Vector2(-L * 0.55, H * 0.15), H * 0.75, -PI * 0.6, PI * 0.25, 8, Color(_line, 0.45), 1.4, true)
	draw_arc(c + Vector2(L * 0.5, H * 0.1), H * 0.6, PI * 0.75, PI * 1.5, 8, Color(_line, 0.35), 1.2, true)


# Front legs straight, back legs bent at the hock; tapered with a rounded paw.
func _leg(top: Vector2, ph: float, leg: float, w: float, far: bool, back: bool) -> void:
	var swing := sin(ph) * (leg * 0.35 + 2.0) if _moving else 0.0
	var lift := maxf(0.0, cos(ph)) * 3.0 if _moving else 0.0
	var foot := Vector2(top.x + swing, -lift - w * 0.35)
	var pts := PackedVector2Array([top])
	if back and leg > 10.0:
		pts.append(top.lerp(foot, 0.55) + Vector2(-leg * 0.15, 0))
	pts.append(foot)
	var col := _base.darkened(0.2 if far else 0.0)
	CritterDraw.taper(self, pts, w, w * 0.75, col, _line)
	var paw := (_white if _white.a > 0.0 else col).darkened(0.2 if far else 0.0)
	if _b.get("fluffy", false):
		var puff := _base.darkened(0.08 if far else 0.0)
		for k in 3:
			draw_circle(foot + Vector2(-2.0 + k * 2.0, -2.5 - (k % 2) * 1.5), w * 0.5 + 0.8, _line)
		for k in 3:
			draw_circle(foot + Vector2(-2.0 + k * 2.0, -2.5 - (k % 2) * 1.5), w * 0.5 - 0.4, puff)
	else:
		CritterDraw.ellipse(self, foot + Vector2(1.5, 0), Vector2(w * 0.6 + 1.0, w * 0.4), paw, _line, 0.0, 1.5)


func _tail(body: Vector2, L: float, H: float, happy: bool) -> void:
	var root := body + Vector2(-L * 0.9, -H * 0.35)
	var wag := sin(_t * (18.0 if happy else (14.0 if _moving else 8.0))) * (0.5 if happy else 0.35)
	var col := _saddle if _saddle.a > 0.0 and _b.tail != "up" else _base
	match _b.tail:
		"stub":
			CritterDraw.ellipse(self, root + Vector2(-2, -1), Vector2(4.0, 3.5), col, _line)
		"curl":
			var pts := PackedVector2Array()
			for i in 12:
				var a := PI * 0.6 + i / 11.0 * PI * 1.35 + wag * 0.3
				pts.append(root + Vector2(4, -7) + Vector2(cos(a), sin(a)) * 7.0)
			CritterDraw.taper(self, pts, 6.0, 3.5, col, _line)
		_:
			var dir := Vector2(-0.35, -1) if _b.tail == "up" else Vector2(-1, -0.25)
			var tip := root + dir.rotated(wag).normalized() * (L * 0.75)
			var pts := CritterDraw.curve([root, root.lerp(tip, 0.5) + Vector2(0, -4), tip], 8)
			var w := 7.0 if _b.tail == "otter" else 4.5
			CritterDraw.taper(self, pts, w, w * 0.45, col, _line)
			if _b.tail == "up" and _white.a > 0.0:
				draw_circle(tip, 2.4, _white)
			if _b.tail == "pompom":
				CritterDraw.ellipse(self, tip, Vector2(5.5, 5.0), _base, _line)


func _head(c: Vector2, r: float, tilt: float, happy: bool) -> void:
	draw_set_transform(c, tilt)
	var ear_col := _mask if _mask.a > 0.0 else (_saddle if _saddle.a > 0.0 and _b.ear != "pointy" else _base.darkened(0.15))
	var snout_len: float = _b.snout
	var flop := sin(_t * 9.0) * 0.12 if _moving else sin(_t * 1.3) * 0.04
	match _b.ear:
		"pointy", "big":
			var s := 1.35 if _b.ear == "big" else 1.0
			for e in [[Vector2(-r * 0.75, -r * 0.3), Vector2(-r * 0.4, -r * 1.5 * s), Vector2(r * 0.0, -r * 0.65)],
					[Vector2(-r * 0.2, -r * 0.7), Vector2(r * 0.25, -r * 1.55 * s), Vector2(r * 0.6, -r * 0.45)]]:
				var tri := CritterDraw.curve([e[0], e[1] + Vector2(-1, -1), e[1] + Vector2(2, 0), e[2]], 8)
				draw_colored_polygon(tri, _base)
				tri.append(tri[0])
				draw_polyline(tri, _line, 2.0, true)
				draw_colored_polygon(PackedVector2Array([e[0].lerp(e[2], 0.3), e[1].lerp(e[0].lerp(e[2], 0.5), 0.35), e[2].lerp(e[0], 0.3)]), Color("#F2A7B4"))
	if _b.get("fluffy", false):
		for pass_i in 2:
			for i in 5:
				var a := PI + i / 4.0 * PI
				var p := Vector2(cos(a) * r * 0.7, sin(a) * r * 0.8 - 2.0)
				draw_circle(p, r * 0.5 if pass_i == 0 else r * 0.5 - 1.4, _line if pass_i == 0 else _base)
	CritterDraw.body(self, Vector2.ZERO, Vector2(r, r * 0.92), _base, Color.TRANSPARENT, _line, 0.0, func():
		if _white.a > 0.0 and _b.ear == "floppy":
			draw_colored_polygon(PackedVector2Array([Vector2(r * 0.05, -r * 0.95), Vector2(r * 0.3, -r * 0.95), Vector2(r * 0.55, r * 0.3), Vector2(r * 0.15, r * 0.3)]), _white)
		if _white.a > 0.0 and _b.ear != "floppy":
			CritterDraw.ellipse(self, Vector2(r * 0.4, r * 0.4), Vector2(r * 0.5, r * 0.42), _white)
		if _mask.a > 0.0:
			CritterDraw.ellipse(self, Vector2(r * 0.55, r * 0.25), Vector2(r * 0.5, r * 0.48), _mask))
	var mode := "happy" if happy else "open"
	CritterDraw.eye(self, Vector2(r * 0.32, -r * 0.18), r * 0.26, Color(_b.get("eyes", "#3A2618")), _line, mode)
	draw_circle(Vector2(r * 0.05, r * 0.35), r * 0.2, Color("#F2A7B4", 0.45))
	var panting := _moving or happy
	if snout_len > 4.0:
		var snout_c := Vector2(r * 0.72 + snout_len * 0.35, r * 0.3)
		var muzzle := _white if _white.a > 0.0 else (_mask if _mask.a > 0.0 else _base.lightened(0.1))
		if panting:
			_tongue(snout_c + Vector2(snout_len * 0.05, r * 0.42))
		CritterDraw.ellipse(self, snout_c, Vector2(snout_len * 0.6 + 2.5, r * 0.42), muzzle, _line)
		draw_arc(snout_c + Vector2(snout_len * 0.1, r * 0.05), r * 0.3, 0.3, PI * 0.7, 6, _line, 1.2, true)
		_nose(snout_c + Vector2(snout_len * 0.6 + 1.5, -r * 0.22))
	else:
		if panting:
			_tongue(Vector2(r * 0.65, r * 0.65))
		_nose(Vector2(r * 0.88, r * 0.08))
		draw_arc(Vector2(r * 0.7, r * 0.3), r * 0.2, 0.2, PI * 0.8, 6, _line, 1.2, true)
		if breed == "pug":
			draw_arc(Vector2(r * 0.55, -r * 0.45), r * 0.25, PI * 1.1, PI * 1.9, 6, Color(_line, 0.6), 1.0, true)
	match _b.ear:
		"floppy", "long":
			var long := 1.5 if _b.ear == "long" else 1.0
			var pivot := Vector2(-r * 0.3, -r * 0.45)
			var ear_c := pivot + Vector2(0, r * 0.6 * long).rotated(0.25 + flop)
			CritterDraw.ellipse(self, ear_c, Vector2(r * 0.36, r * 0.62 * long), ear_col, _line, 0.25 + flop)
			CritterDraw.ellipse(self, ear_c + Vector2(-r * 0.08, -r * 0.2 * long), Vector2(r * 0.15, r * 0.25 * long), Color(1, 1, 1, 0.12), Color.TRANSPARENT, 0.25 + flop)
		"fold":
			var tri := PackedVector2Array([Vector2(-r * 0.6, -r * 0.62), Vector2(-r * 0.05, -r * 0.98), Vector2(-r * 0.15, -r * 0.3)])
			draw_colored_polygon(tri, ear_col)
			tri.append(tri[0])
			draw_polyline(tri, _line, 1.5, true)
		"fluffy":
			for pass_i in 2:
				for i in 4:
					var p := Vector2(-r * 0.4, r * (0.0 + i * 0.35)).rotated(flop)
					draw_circle(p, r * 0.38 if pass_i == 0 else r * 0.38 - 1.3, _line if pass_i == 0 else _base.darkened(0.06))
	draw_set_transform(Vector2.ZERO)


func _nose(c: Vector2) -> void:
	CritterDraw.ellipse(self, c, Vector2(3.0, 2.4), Color("#1E1A18"))
	draw_circle(c + Vector2(-0.9, -0.8), 0.9, Color(1, 1, 1, 0.7))


func _tongue(c: Vector2) -> void:
	CritterDraw.ellipse(self, c, Vector2(2.6, 3.6), Color("#F07A8A"), Color("#B5475A"), 0.0, 1.0)
	draw_line(c + Vector2(0, -2.5), c + Vector2(0, 1.5), Color("#C9566A"), 0.8)
