class_name Dog
extends Node2D
## Procedural dog on a leash: trots ahead of its walker, sniffs around when they stop, wags.
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
			dog._spots.append(Vector3(rng.randf_range(-0.75, 0.75), rng.randf_range(-0.6, 0.5), rng.randf_range(1.6, 2.8)))
	return dog


func _ready() -> void:
	_line = _base.darkened(0.55) if _base.get_luminance() > 0.3 else _base.lightened(0.15).darkened(0.6)
	_t = randf_range(0.0, 10.0)
	position = owner_walker.position + Vector2(owner_walker.facing * _lead, 4.0)


func _process(delta: float) -> void:
	_t += delta
	var walker := owner_walker
	var goal := walker.position.x + walker.facing * (_lead if walker.is_walking else _lead * 0.7)
	var dx := goal - position.x
	var max_speed := walker.walk_speed * 1.8
	var v := clampf(dx * 4.0, -max_speed, max_speed)
	if absf(dx) < 4.0:
		v = 0.0
	position.x += v * delta
	position.y = walker.position.y + 4.0
	_moving = absf(v) > 12.0
	if _moving:
		facing = 1 if v > 0.0 else -1
		_step = fmod(_step + absf(v) * delta / (14.0 + float(_b.leg) * 1.6), 1.0)
	scale = Vector2(facing * size, size)
	queue_redraw()


# ── Drawing (facing right, feet on y = 0) ────────────────────

func _draw() -> void:
	var L: float = _b.len
	var H: float = _b.h
	var leg: float = _b.leg
	var hr: float = _b.head
	var body := Vector2(0, -(leg + H))
	var sniff := not _moving and fmod(_t, 5.0) < 2.5
	draw_set_transform(Vector2(3, 0), 0.0, Vector2(1.0, 0.2))
	draw_circle(Vector2.ZERO, L * 1.2, Color(0.15, 0.08, 0.05, 0.25))
	draw_set_transform(Vector2.ZERO)
	var cyc := _step * TAU
	var lw := clampf(H * 0.6, 4.0, 7.0)
	var hips := [-L * 0.62, L * 0.58]
	for i in 2:
		var ph := cyc + (PI if i == 0 else 0.0)
		_leg(Vector2(hips[i] + 3.0, body.y + H * 0.5), ph, leg, lw, true)
	_tail(body, L, H)
	_body(body, L, H)
	for i in 2:
		var ph := cyc + (0.0 if i == 0 else PI)
		_leg(Vector2(hips[i] - 2.0, body.y + H * 0.7), ph, leg, lw, false)
	var head := body + Vector2(L * 0.85 + hr * 0.3, -H - hr * 0.35)
	if sniff:
		head += Vector2(hr * 0.5, H + hr * 0.9)
	var collar_a := body + Vector2(L * 0.72, -H * 0.55)
	var collar_b := head + Vector2(-hr * 0.25, hr * 0.75)
	_head(head, hr, _moving)
	draw_line(collar_a.lerp(collar_b, 0.55) + Vector2(-4, -2), collar_a.lerp(collar_b, 0.55) + Vector2(4, 2), _collar_col, 3.5, true)
	_draw_leash(collar_a.lerp(collar_b, 0.55))


func _draw_leash(collar: Vector2) -> void:
	var hand := to_local(owner_walker.hand_position())
	var mid := (collar + hand) / 2.0 + Vector2(0, 10.0 / size)
	var pts := PackedVector2Array()
	for i in 11:
		var t := i / 10.0
		pts.append(collar.lerp(mid, t).lerp(mid.lerp(hand, t), t))
	draw_polyline(pts, _leash, 1.8 / size, true)


func _body(c: Vector2, L: float, H: float) -> void:
	if _b.get("fluffy", false):
		for i in 12:
			var a := TAU * i / 12.0
			draw_circle(c + Vector2(cos(a) * L * 0.85, sin(a) * H * 0.8), H * 0.55, _line)
		for i in 12:
			var a := TAU * i / 12.0
			draw_circle(c + Vector2(cos(a) * L * 0.85, sin(a) * H * 0.8), H * 0.5 - 1.5, _base)
		_ellipse(c, Vector2(L * 0.85, H * 0.85), _base, false)
		return
	_ellipse(c, Vector2(L, H), _base)
	if _saddle.a > 0.0:
		_clip_ellipse(c, Vector2(L, H), -1.0, -0.05, _saddle)
	if _white.a > 0.0:
		_clip_ellipse(c, Vector2(L, H), 0.45, 1.0, _white)
	for s in _spots:
		draw_circle(c + Vector2(s.x * L, s.y * H), s.z, Color("#222222"))


# Fills the band of the ellipse between v0 and v1 (in -1..1 from top to bottom), like a coat saddle or belly.
func _clip_ellipse(c: Vector2, r: Vector2, v0: float, v1: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 13:
		var v := lerpf(v0, v1, i / 12.0)
		pts.append(c + Vector2(sqrt(maxf(0.0, 1.0 - v * v)) * r.x * 0.96, v * r.y * 0.96))
	for i in 13:
		var v := lerpf(v1, v0, i / 12.0)
		pts.append(c + Vector2(-sqrt(maxf(0.0, 1.0 - v * v)) * r.x * 0.96, v * r.y * 0.96))
	draw_colored_polygon(pts, col)


func _leg(top: Vector2, ph: float, leg: float, w: float, far: bool) -> void:
	var swing := sin(ph) * (leg * 0.35 + 2.0) if _moving else 0.0
	var lift := maxf(0.0, cos(ph)) * 3.0 if _moving else 0.0
	var foot := Vector2(top.x + swing, -lift)
	var col := _base.darkened(0.2 if far else 0.0)
	draw_line(top, foot, _line, w + 2.5, true)
	draw_line(top, foot, col, w, true)
	var paw := _white if _white.a > 0.0 else col
	if _b.get("fluffy", false):
		draw_circle(foot + Vector2(0, -3), w * 0.9, _line)
		draw_circle(foot + Vector2(0, -3), w * 0.9 - 1.2, paw.darkened(0.2 if far else 0.0))
	else:
		draw_circle(foot + Vector2(1.5, -1), w * 0.55, paw.darkened(0.2 if far else 0.0))


func _tail(body: Vector2, L: float, H: float) -> void:
	var root := body + Vector2(-L * 0.9, -H * 0.4)
	var wag := sin(_t * (14.0 if _moving else 9.0)) * 0.35
	var col := _saddle if _saddle.a > 0.0 and _b.tail != "up" else _base
	match _b.tail:
		"stub":
			draw_circle(root + Vector2(-2, -1), 4.0, _line)
			draw_circle(root + Vector2(-2, -1), 3.0, col)
		"curl":
			var pts := PackedVector2Array()
			for i in 10:
				var a := PI * 0.6 + i / 9.0 * PI * 1.3 + wag * 0.3
				pts.append(root + Vector2(4, -7) + Vector2(cos(a), sin(a)) * 7.0)
			draw_polyline(pts, _line, 6.5, true)
			draw_polyline(pts, col, 4.0, true)
		_:
			var dir := Vector2(-1, -0.5) if _b.tail != "up" else Vector2(-0.35, -1)
			if _b.tail == "otter" or _b.tail == "thin":
				dir = Vector2(-1, -0.15)
			var tip := root + dir.rotated(wag).normalized() * (L * 0.75)
			var mid := root.lerp(tip, 0.5) + Vector2(0, -3)
			var pts := PackedVector2Array()
			for i in 8:
				var t := i / 7.0
				pts.append(root.lerp(mid, t).lerp(mid.lerp(tip, t), t))
			var w := 6.0 if _b.tail == "otter" else 3.5
			draw_polyline(pts, _line, w + 2.5, true)
			draw_polyline(pts, col, w, true)
			if _b.tail == "up" and _white.a > 0.0:
				draw_circle(tip, 2.5, _white)
			if _b.tail == "pompom":
				draw_circle(tip, 5.5, _line)
				draw_circle(tip, 4.5, _base)


func _head(c: Vector2, r: float, panting: bool) -> void:
	var ear_col := _mask if _mask.a > 0.0 else (_saddle if _saddle.a > 0.0 and _b.ear != "pointy" else _base.darkened(0.12))
	var snout_len: float = _b.snout
	# Back ear, then head, then front ear so floppy ears hang over the cheek.
	match _b.ear:
		"pointy", "big":
			var s := 1.35 if _b.ear == "big" else 1.0
			for e in [[Vector2(-r * 0.75, -r * 0.3), Vector2(-r * 0.35, -r * 1.55 * s), Vector2(r * 0.05, -r * 0.6)],
					[Vector2(-r * 0.2, -r * 0.65), Vector2(r * 0.25, -r * 1.6 * s), Vector2(r * 0.55, -r * 0.45)]]:
				var tri := PackedVector2Array(e)
				draw_colored_polygon(tri, _base)
				tri.append(e[0])
				draw_polyline(tri, _line, 2.0, true)
				draw_colored_polygon(PackedVector2Array([e[0].lerp(e[2], 0.3), e[1].lerp(e[0].lerp(e[2], 0.5), 0.35), e[2].lerp(e[0], 0.3)]), Color("#E89AA8"))
	if _b.get("fluffy", false):
		for i in 5:
			var a := PI + i / 4.0 * PI
			draw_circle(c + Vector2(cos(a) * r * 0.7, sin(a) * r * 0.8 - 2.0), r * 0.5, _line)
			draw_circle(c + Vector2(cos(a) * r * 0.7, sin(a) * r * 0.8 - 2.0), r * 0.5 - 1.2, _base)
	_ellipse(c, Vector2(r, r * 0.92), _base)
	if _white.a > 0.0 and _b.ear != "floppy":
		_ellipse(c + Vector2(r * 0.35, r * 0.35), Vector2(r * 0.5, r * 0.45), _white, false)
	if _white.a > 0.0 and _b.ear == "floppy":
		draw_line(c + Vector2(r * 0.1, -r * 0.9), c + Vector2(r * 0.45, r * 0.2), _white, 3.0, true)
	var snout_c := c + Vector2(r * 0.75 + snout_len * 0.35, r * 0.3)
	if snout_len > 4.0:
		var muzzle := _white if _white.a > 0.0 else (_mask if _mask.a > 0.0 else _base.lightened(0.08))
		_ellipse(snout_c, Vector2(snout_len * 0.6 + 2.0, r * 0.42), muzzle)
		draw_circle(snout_c + Vector2(snout_len * 0.6 + 1.0, -r * 0.2), 2.6, Color("#1E1A18"))
		if panting:
			_ellipse(snout_c + Vector2(snout_len * 0.1, r * 0.45), Vector2(2.2, 3.2), Color("#F07A8A"), false)
	else:
		if _mask.a > 0.0:
			_ellipse(c + Vector2(r * 0.55, r * 0.25), Vector2(r * 0.5, r * 0.45), _mask, false)
		draw_circle(c + Vector2(r * 0.9, r * 0.05), 2.4, Color("#1E1A18"))
		if panting:
			_ellipse(c + Vector2(r * 0.7, r * 0.6), Vector2(2.0, 3.0), Color("#F07A8A"), false)
	var eye := c + Vector2(r * 0.35, -r * 0.2)
	draw_circle(eye, 2.2, Color(_b.get("eyes", "#2A1E18")))
	draw_circle(eye + Vector2(0.7, -0.8), 0.7, Color.WHITE)
	match _b.ear:
		"floppy", "long":
			var long := 1.5 if _b.ear == "long" else 1.0
			_ellipse(c + Vector2(-r * 0.35, r * 0.15 * long), Vector2(r * 0.38, r * 0.62 * long), ear_col, true, 0.25)
		"fold":
			var tri := PackedVector2Array([c + Vector2(-r * 0.6, -r * 0.65), c + Vector2(-r * 0.05, -r * 0.95), c + Vector2(-r * 0.15, -r * 0.3)])
			draw_colored_polygon(tri, ear_col)
		"fluffy":
			for i in 4:
				draw_circle(c + Vector2(-r * 0.4, r * (0.0 + i * 0.35)), r * 0.38, _line)
				draw_circle(c + Vector2(-r * 0.4, r * (0.0 + i * 0.35)), r * 0.38 - 1.2, _base.darkened(0.05))


func _ellipse(c: Vector2, r: Vector2, col: Color, outline := true, rot := 0.0) -> void:
	var pts := PackedVector2Array()
	for i in 24:
		var a := TAU * i / 24.0
		pts.append(c + Vector2(cos(a) * r.x, sin(a) * r.y).rotated(rot))
	draw_colored_polygon(pts, col)
	if outline:
		pts.append(pts[0])
		draw_polyline(pts, _line, 2.0, true)
