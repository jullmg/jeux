class_name SantaFlight
extends Control
## Santa's sleigh crossing the night while Charlotte sleeps on Christmas Eve (Julien: "really, really better"). A little film of
## about nine seconds drawn by hand over the darkened bedroom: a deep blue sky with a big moon and twinkling stars, drifting
## clouds, a shooting star, the roofs of her neighbourhood in two layers (brick duplexes under snow, lit windows, outdoor stairs,
## no chimneys), a few streetlamps, falling snow; and across it Santa's sleigh behind nine reindeer at a gallop (Rudolph in front, his
## nose glowing), harness bells, a sack of presents, Santa waving, a glittering trail, and sleigh bells and a « Ho ! Ho ! Ho ! ».
## Put it in a CanvasLayer; it fades itself in and out and frees itself. `DURATION` is its length.

const DURATION := 9.6
const VIEW := Vector2(1280, 720)
const MOON := Vector2(640, 250)
const GOLD := Color("#F6D26B")
const RED := Color("#C8283A")

var _t := 0.0
var _stars: Array = []
var _clouds: Array = []
var _far: Array = []
var _near: Array = []
var _flakes: Array = []
var _sparks: Array = []
var _rng := RandomNumberGenerator.new()
var _bell_in := 0.0
var _hoho := false
var _puff: GradientTexture2D
## The frame the whole team is drawn in (its place, tilt and size); parts turn inside it with `_local`.
var _frame := Transform2D.IDENTITY


func _init() -> void:
	size = VIEW
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rng.seed = 24
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.45, 1.0])
	g.colors = PackedColorArray([Color(1, 1, 1, 0.5), Color(1, 1, 1, 0.24), Color(1, 1, 1, 0.0)])
	_puff = GradientTexture2D.new()
	_puff.gradient = g
	_puff.width = 128
	_puff.height = 128
	_puff.fill = GradientTexture2D.FILL_RADIAL
	_puff.fill_from = Vector2(0.5, 0.5)
	_puff.fill_to = Vector2(1.0, 0.5)
	for i in 190:
		_stars.append([_rng.randf_range(0, VIEW.x), _rng.randf_range(0, 430), _rng.randf_range(0.6, 2.4), _rng.randf() * TAU, _rng.randf_range(1.0, 3.2)])
	for i in 9:
		_clouds.append([_rng.randf_range(-100, VIEW.x), _rng.randf_range(60, 470), _rng.randf_range(0.8, 1.9), _rng.randf_range(4.0, 12.0), _rng.randi() % 2])
	for i in 70:
		_flakes.append([_rng.randf_range(0, VIEW.x), _rng.randf_range(0, VIEW.y), _rng.randf_range(1.0, 2.6), _rng.randf_range(18.0, 46.0)])
	var x := -20.0
	while x < VIEW.x + 40.0:
		var w := _rng.randf_range(70.0, 130.0)
		_far.append([x, w, _rng.randf_range(34.0, 80.0)])
		x += w - 4.0
	x = -40.0
	while x < VIEW.x + 60.0:
		var w := _rng.randf_range(150.0, 210.0)
		_near.append([x, w, _rng.randf_range(100.0, 150.0), _rng.randi() % 3, _rng.randi()])
		x += w + _rng.randf_range(4.0, 22.0)


func _ready() -> void:
	modulate.a = 0.0


func _process(delta: float) -> void:
	_t += delta
	modulate.a = clampf(minf(_t / 0.9, (DURATION - _t) / 0.9), 0.0, 1.0)
	if _t >= DURATION:
		queue_free()
		return
	# The bells ring with the gallop, loudest when it passes over.
	_bell_in -= delta
	if _bell_in <= 0.0 and _t > 0.8 and _t < DURATION - 1.2:
		_bell_in = 0.42
		var near := 1.0 - absf(_u() - 0.5) * 1.6
		Sfx.play("bell", Vector2.INF, lerpf(-16.0, -4.0, clampf(near, 0.0, 1.0)), 1.0 + sin(_t * 3.0) * 0.12)
	if not _hoho and _t > 4.6:
		_hoho = true
		var at := _sleigh_at()
		Bubble.say(self, at + Vector2(-20, -150), "Ho ! Ho ! Ho !", 2.2)
	# Glitter let go behind the sleigh.
	if _t > 0.5 and _t < DURATION - 0.8:
		var tail := _sleigh_at() + Vector2(90.0, -10.0)
		for i in 4:
			_sparks.append([tail + Vector2(_rng.randf_range(-6, 6), _rng.randf_range(-16, 24)), Vector2(_rng.randf_range(20, 90), _rng.randf_range(-24, 30)), 0.0, _rng.randf_range(1.0, 1.9), _rng.randi() % 3, _rng.randf_range(2.0, 5.0)])
	for s: Array in _sparks:
		s[0] += s[1] * delta
		s[1] += Vector2(0, 26.0) * delta
		s[2] += delta
	_sparks = _sparks.filter(func(s: Array) -> bool: return s[2] < s[3])
	queue_redraw()


# How far along its flight (0 at the right edge, 1 gone at the left).
func _u() -> float:
	return clampf((_t - 0.4) / (DURATION - 1.4), 0.0, 1.0)


func _sleigh_at(u := -1.0) -> Vector2:
	if u < 0.0:
		u = _u()
	return Vector2(lerpf(1640.0, -520.0, u), 300.0 - sin(u * PI) * 70.0 + sin(u * PI * 3.0) * 16.0)


func _draw() -> void:
	_sky()
	_stars_and_moon()
	_cloud_layer(0)
	_shooting_star()
	_skyline()
	_cloud_layer(1)
	_trail()
	_santa_team()
	_snow()


# ── The sky ─────────────────────────────────────────────────

func _sky() -> void:
	var top := Color("#050A22")
	var mid := Color("#14265A")
	var low := Color("#2B4A86")
	draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(VIEW.x, 0), Vector2(VIEW.x, 380), Vector2(0, 380)]), PackedColorArray([top, top, mid, mid]))
	draw_polygon(PackedVector2Array([Vector2(0, 380), Vector2(VIEW.x, 380), Vector2(VIEW.x, VIEW.y), Vector2(0, VIEW.y)]), PackedColorArray([mid, mid, low, low]))


func _stars_and_moon() -> void:
	for s: Array in _stars:
		var tw := 0.55 + 0.45 * sin(_t * float(s[4]) + float(s[3]))
		var p := Vector2(s[0], s[1])
		var r: float = s[2]
		draw_circle(p, r, Color(1, 1, 0.92, 0.35 + 0.6 * tw))
		if r > 1.9:
			draw_line(p - Vector2(r * 3.0 * tw, 0), p + Vector2(r * 3.0 * tw, 0), Color(1, 1, 0.9, 0.35 * tw), 1.0)
			draw_line(p - Vector2(0, r * 3.0 * tw), p + Vector2(0, r * 3.0 * tw), Color(1, 1, 0.9, 0.35 * tw), 1.0)
	# The moon, big, in its halo.
	for k in 14:
		draw_circle(MOON, 190.0 - k * 9.0, Color(0.75, 0.85, 1.0, 0.012 + k * 0.0035))
	draw_circle(MOON, 112.0, Color("#EEF0E2"))
	draw_circle(MOON + Vector2(-14, -10), 104.0, Color("#FAFBEF"))
	for c in [[Vector2(-30, -20), 22.0], [Vector2(34, 18), 18.0], [Vector2(-8, 48), 13.0], [Vector2(48, -34), 12.0], [Vector2(-52, 30), 9.0]]:
		draw_circle(MOON + (c[0] as Vector2), float(c[1]), Color(0.78, 0.8, 0.72, 0.45))
		draw_circle(MOON + (c[0] as Vector2) + Vector2(-2, -2), float(c[1]) * 0.8, Color(0.86, 0.88, 0.8, 0.4))


func _shooting_star() -> void:
	var k := (_t - 2.3) / 0.9
	if k < 0.0 or k > 1.0:
		return
	var head := Vector2(lerpf(1000.0, 560.0, k), lerpf(70.0, 210.0, k))
	for i in 14:
		var tail := head + Vector2(i * 11.0, -i * 5.6)
		draw_circle(tail, 3.0 - i * 0.2, Color(1, 1, 0.9, (1.0 - k * 0.6) * (1.0 - i / 14.0) * 0.8))
	draw_circle(head, 3.5, Color(1, 1, 1, 1.0 - k * 0.5))


# A drifting bank of soft clouds (overlapping round puffs with feathered edges); `layer` 0 behind the sleigh (moonlit, pale),
# 1 in front of its trail (dark).
func _cloud_layer(layer: int) -> void:
	for c: Array in _clouds:
		if int(c[4]) != layer:
			continue
		var x := fposmod(float(c[0]) - _t * float(c[3]) * (1.0 + layer), VIEW.x + 500.0) - 250.0
		var s: float = c[2]
		var base := Vector2(x, c[1])
		var shade := Color(0.5, 0.62, 0.95, 0.9) if layer == 0 else Color(0.03, 0.06, 0.2, 0.95)
		var lit := Color(0.8, 0.88, 1.0, 0.8) if layer == 0 else Color(0.14, 0.22, 0.5, 0.7)
		for b in [[-60.0, 8.0, 74.0], [-18.0, -6.0, 96.0], [32.0, 0.0, 88.0], [80.0, 10.0, 66.0], [10.0, 16.0, 110.0], [-96.0, 14.0, 56.0]]:
			var d := float(b[2]) * s * 1.7
			draw_texture_rect(_puff, Rect2(base + Vector2(float(b[0]), float(b[1])) * s - Vector2(d, d) / 2.0, Vector2(d, d)), false, shade)
		for b in [[-20.0, -22.0, 60.0], [34.0, -14.0, 50.0]]:
			var d := float(b[2]) * s * 1.6
			draw_texture_rect(_puff, Rect2(base + Vector2(float(b[0]), float(b[1])) * s - Vector2(d, d) / 2.0, Vector2(d, d)), false, lit)


# ── The roofs ───────────────────────────────────────────────

func _skyline() -> void:
	var ground := 640.0
	# Far rooftops: dark, flat-roofed, a little snow on top.
	for b: Array in _far:
		var x: float = b[0]
		var w: float = b[1]
		var h: float = b[2]
		draw_rect(Rect2(x, ground - 60.0 - h, w, h + 60.0), Color("#0F1B3A"))
		draw_rect(Rect2(x - 2.0, ground - 64.0 - h, w + 4.0, 6.0), Color("#B9C9E6", 0.55))
		for k in 3:
			if (int(x) + k * 7) % 5 < 2:
				draw_rect(Rect2(x + 10.0 + k * (w / 3.2), ground - 40.0 - h * 0.6, 7.0, 9.0), Color("#F2C56A", 0.55))
	# Near plexes: brick, two floors, outdoor stair, lit windows, a snowy flat roof.
	for b: Array in _near:
		var x: float = b[0]
		var w: float = b[1]
		var h: float = b[2]
		var kind: int = b[3]
		var top := ground - h
		var brick: Color = [Color("#2A1F3A"), Color("#2C2540"), Color("#1F2A44")][kind]
		draw_rect(Rect2(x, top, w, h + 80.0), brick)
		draw_rect(Rect2(x, top, w, 10.0), brick.lightened(0.12))
		draw_rect(Rect2(x - 3.0, top - 9.0, w + 6.0, 10.0), Color("#DCE8FA"))
		draw_rect(Rect2(x - 3.0, top - 9.0, w + 6.0, 3.0), Color.WHITE)
		draw_rect(Rect2(x - 3.0, top + 1.0, w + 6.0, 5.0), Color("#8FA4CC", 0.7))
		# Two floors of windows.
		var cols := 3
		for r in 2:
			for c in cols:
				var wx := x + 16.0 + c * ((w - 32.0) / cols)
				var wy := top + 22.0 + r * 52.0
				var lit := ((int(b[4]) >> (r * cols + c)) & 1) == 1
				draw_rect(Rect2(wx, wy, 26.0, 34.0), Color("#FFD27A") if lit else Color("#101A33"))
				if lit:
					draw_rect(Rect2(wx - 3.0, wy - 3.0, 32.0, 40.0), Color(1.0, 0.8, 0.4, 0.14))
					draw_line(Vector2(wx + 13.0, wy), Vector2(wx + 13.0, wy + 34.0), Color("#8A5A2A", 0.7), 1.5)
				draw_rect(Rect2(wx, wy, 26.0, 34.0), Color("#0A1022"), false, 2.0)
				draw_rect(Rect2(wx - 3.0, wy + 34.0, 32.0, 4.0), Color("#C9D6EE", 0.85))
		# The outdoor stair: a diagonal with its landings, the way a Montréal plex has one.
		var sx := x + w - 20.0 if kind != 1 else x + 18.0
		var dir := -1.0 if kind != 1 else 1.0
		for s in 8:
			var p := Vector2(sx + dir * s * 7.0, top + 60.0 + s * 10.5)
			draw_rect(Rect2(p.x, p.y, 9.0, 3.0), Color("#7C89A8", 0.9))
		draw_line(Vector2(sx, top + 56.0), Vector2(sx + dir * 56.0, top + 140.0), Color("#5A6788"), 2.0)
	# Snow on the street, a few lamps with their glow.
	draw_rect(Rect2(0, ground, VIEW.x, VIEW.y - ground), Color("#C8D8F2"))
	draw_polygon(PackedVector2Array([Vector2(0, ground), Vector2(VIEW.x, ground), Vector2(VIEW.x, ground + 26.0), Vector2(0, ground + 26.0)]),
		PackedColorArray([Color("#A9BCE0"), Color("#A9BCE0"), Color("#C8D8F2"), Color("#C8D8F2")]))
	draw_rect(Rect2(0, ground + 70.0, VIEW.x, VIEW.y), Color("#8FA4CC", 0.5))
	for lx in [150.0, 520.0, 930.0, 1210.0]:
		draw_line(Vector2(lx, ground + 6.0), Vector2(lx, ground - 70.0), Color("#1A2240"), 4.0)
		for k in 7:
			draw_circle(Vector2(lx, ground - 72.0), 70.0 - k * 9.0, Color(1.0, 0.85, 0.5, 0.025 + k * 0.014))
		draw_circle(Vector2(lx, ground - 72.0), 6.0, Color("#FFF1C8"))


func _snow() -> void:
	for f: Array in _flakes:
		var y := fposmod(float(f[1]) + _t * float(f[3]), VIEW.y)
		var x := float(f[0]) + sin(_t * 0.9 + float(f[1])) * 14.0
		draw_circle(Vector2(x, y), float(f[2]), Color(1, 1, 1, 0.55))


# ── The sleigh ──────────────────────────────────────────────

func _trail() -> void:
	for s: Array in _sparks:
		var life: float = float(s[2]) / float(s[3])
		var a := (1.0 - life) * (0.55 + 0.45 * sin(_t * 18.0 + float(s[5]) * 7.0))
		var col := [Color(1.0, 0.9, 0.5), Color(1, 1, 1), Color(1.0, 0.72, 0.88)][int(s[4])] as Color
		var p: Vector2 = s[0]
		var r: float = float(s[5]) * (1.0 - life * 0.5)
		draw_circle(p, r, Color(col, a * 0.8))
		if r > 2.6:
			draw_line(p - Vector2(r * 2.2, 0), p + Vector2(r * 2.2, 0), Color(col, a * 0.7), 1.2)
			draw_line(p - Vector2(0, r * 2.2), p + Vector2(0, r * 2.2), Color(col, a * 0.7), 1.2)


func _santa_team() -> void:
	var u := _u()
	var at := _sleigh_at(u)
	var ahead := _sleigh_at(minf(1.0, u + 0.02)) - at
	var tilt := clampf(atan2(ahead.y, -ahead.x), -0.5, 0.5)
	var k := lerpf(0.78, 1.18, sin(u * PI))
	var gallop := _t * 7.5
	# The whole outfit is drawn in its own frame, nose to the left: the sleigh at the right, Rudolph at the far left.
	_frame = Transform2D(-tilt * 0.6, at).scaled_local(Vector2.ONE * k)
	draw_set_transform_matrix(_frame)
	# Rudolph's nose lights the air.
	var nose_at := Vector2(-720.0, 8.0)
	for i in 8:
		draw_circle(nose_at, 70.0 - i * 8.0, Color(1.0, 0.15, 0.15, 0.02 + i * 0.012))
	# Nine reindeer: a pair at a time, the second one a little lower and nearer, and Rudolph alone in front.
	var team: Array = []
	for pair in 4:
		var x := -90.0 - pair * 150.0
		team.append([Vector2(x, -6.0), 0.9, gallop + pair * 0.9, false])
		team.append([Vector2(x + 34.0, 22.0), 1.0, gallop + pair * 0.9 + 1.7, false])
	team.append([Vector2(-720.0, 8.0), 1.0, gallop + 3.9, true])
	# The reins: from the sleigh to the front, through each pair's harness.
	var rein := PackedVector2Array()
	for i in 22:
		var f := i / 21.0
		rein.append(Vector2(lerpf(-60.0, -700.0, f), 4.0 + sin(f * PI) * 5.0 + sin(_t * 6.0 + f * 9.0) * 1.2))
	draw_polyline(rein, Color(GOLD, 0.8), 2.0, true)
	var rein2 := PackedVector2Array()
	for i in 22:
		var f := i / 21.0
		rein2.append(Vector2(lerpf(-60.0, -690.0, f), 24.0 + sin(f * PI) * 4.0 + sin(_t * 6.0 + f * 9.0 + 1.0) * 1.2))
	draw_polyline(rein2, Color(GOLD, 0.65), 1.6, true)
	team.sort_custom(func(a: Array, b: Array) -> bool: return (a[0] as Vector2).y < (b[0] as Vector2).y)
	for r: Array in team:
		_reindeer(r[0], float(r[1]), float(r[2]), bool(r[3]))
	_sleigh(Vector2(60.0, 0.0), gallop)
	draw_set_transform_matrix(Transform2D.IDENTITY)


func _reindeer(at: Vector2, s: float, phase: float, rudolph: bool) -> void:
	var bob := sin(phase * 2.0) * 5.0
	var base := at + Vector2(0, bob)
	var coat := Color("#8A5A33")
	var dark := Color("#5E3A1E")
	var belly := Color("#D2A777")
	var outline := Color("#2E1A0C")
	_local(base, sin(phase * 2.0 + 0.6) * 0.06, Vector2(s, s))
	# The far legs first (darker), then the body, then the near legs.
	for leg in [[-22.0, 0.0, true], [26.0, PI, true], [-12.0, 0.6, false], [34.0, PI + 0.6, false]]:
		if bool(leg[2]):
			_leg(Vector2(float(leg[0]), 10.0), phase + float(leg[1]), dark, outline, leg[0] < 0.0)
	# Body.
	var body := PackedVector2Array()
	for i in 28:
		var a := TAU * i / 28.0
		body.append(Vector2(cos(a) * 40.0, sin(a) * 19.0))
	draw_colored_polygon(body, coat)
	var under := PackedVector2Array()
	for i in 15:
		var a := PI * i / 14.0
		under.append(Vector2(cos(a) * 36.0, 4.0 + sin(a) * 13.0))
	draw_colored_polygon(under, belly)
	draw_polyline(_close(body), outline, 1.6, true)
	draw_arc(Vector2(-6, -8), 30.0, PI * 1.15, PI * 1.8, 12, Color(1, 0.9, 0.7, 0.35), 3.0, true)
	# Neck, head, ears, antlers, eye, nose.
	draw_colored_polygon(PackedVector2Array([Vector2(-26, -10), Vector2(-40, -34), Vector2(-52, -26), Vector2(-34, 8)]), coat)
	draw_colored_polygon(PackedVector2Array([Vector2(-30, -2), Vector2(-46, -22), Vector2(-52, -26), Vector2(-34, 8)]), belly)
	draw_colored_polygon(_oval(Vector2(-54, -34), 15.0, 10.0, -0.3), coat)
	draw_colored_polygon(_oval(Vector2(-65, -30), 8.0, 6.0, -0.3), belly)
	draw_polyline(_close(_oval(Vector2(-54, -34), 15.0, 10.0, -0.3)), outline, 1.4, true)
	draw_colored_polygon(PackedVector2Array([Vector2(-48, -42), Vector2(-40, -54), Vector2(-42, -40)]), dark)
	draw_circle(Vector2(-57, -37), 2.4, Color.WHITE)
	draw_circle(Vector2(-57.6, -37.2), 1.4, Color("#1A0E06"))
	if rudolph:
		draw_circle(Vector2(-71, -29), 9.0, Color(1, 0.2, 0.2, 0.28))
		draw_circle(Vector2(-71, -29), 6.2, Color("#E8262A"))
		draw_circle(Vector2(-72.5, -30.5), 2.0, Color(1, 1, 1, 0.85))
	else:
		draw_circle(Vector2(-71, -29), 3.0, Color("#2A1A10"))
	for side in [0, 1]:
		var o := Vector2(-44.0 + side * 8.0, -42.0)
		var col := Color("#C8B089") if side == 0 else Color("#A68E66")
		draw_polyline(PackedVector2Array([o, o + Vector2(-6, -16), o + Vector2(-2, -30), o + Vector2(-10, -46)]), col, 3.0, true)
		draw_polyline(PackedVector2Array([o + Vector2(-6, -16), o + Vector2(-18, -22)]), col, 2.4, true)
		draw_polyline(PackedVector2Array([o + Vector2(-2, -30), o + Vector2(8, -38)]), col, 2.4, true)
		draw_polyline(PackedVector2Array([o + Vector2(-9, -42), o + Vector2(-20, -44)]), col, 2.0, true)
	# Harness: a red collar and strap round the chest, a gold bell that swings.
	draw_polyline(PackedVector2Array([Vector2(-32, -2), Vector2(-18, 8), Vector2(-14, -16)]), RED, 3.4, true)
	draw_arc(Vector2(-38, -14), 8.0, PI * 0.2, PI * 1.1, 8, RED, 3.0, true)
	var swing := sin(phase * 2.0) * 3.0
	draw_circle(Vector2(-31.0 + swing, 4.0), 5.0, GOLD)
	draw_circle(Vector2(-32.0 + swing, 3.0), 1.8, Color(1, 1, 1, 0.8))
	# Tail and the near legs.
	draw_circle(Vector2(41, -6), 6.0, Color("#F6F2EA"))
	for leg in [[-12.0, 0.6, false], [34.0, PI + 0.6, false]]:
		_leg(Vector2(float(leg[0]), 10.0), phase + float(leg[1]), coat, outline, leg[0] < 0.0)
	# A puff of breath.
	var br := fposmod(_t * 1.3 + phase, 1.0)
	draw_circle(Vector2(-76.0 - br * 24.0, -34.0 - br * 10.0), 3.0 + br * 6.0, Color(1, 1, 1, 0.45 * (1.0 - br)))
	_reset()


func _leg(hip: Vector2, ph: float, col: Color, outline: Color, front: bool) -> void:
	# A gallop: the legs reach forward (left), tuck, and push back.
	var sw := sin(ph)
	var lift := maxf(0.0, cos(ph))
	var reach := -sw * (16.0 if front else 12.0)
	var knee := hip + Vector2(reach * 0.55 - 2.0, 13.0 - lift * 6.0)
	var hoof := knee + Vector2(reach * 0.5 - lift * (10.0 if front else -6.0), 14.0 - lift * 9.0)
	draw_line(hip, knee, outline, 6.0, true)
	draw_line(knee, hoof, outline, 5.0, true)
	draw_line(hip, knee, col, 4.2, true)
	draw_line(knee, hoof, col, 3.4, true)
	draw_circle(hoof, 3.2, Color("#1E1208"))


func _sleigh(at: Vector2, gallop: float) -> void:
	var bob := sin(gallop * 2.0 + 0.8) * 2.0
	var o := at + Vector2(0, bob)
	# Runners: two curled gold blades.
	for dy in [0.0, 12.0]:
		var runner := PackedVector2Array()
		for i in 18:
			var f := i / 17.0
			var p := Vector2(lerpf(-70.0, 130.0, f), 58.0 + dy)
			if f < 0.12:
				p.y -= (0.12 - f) * 170.0
			runner.append(o + p)
		draw_polyline(runner, GOLD.darkened(0.15), 4.5, true)
	draw_line(o + Vector2(-34, 58), o + Vector2(-32, 30), Color("#A8801A"), 3.0, true)
	draw_line(o + Vector2(100, 58), o + Vector2(98, 30), Color("#A8801A"), 3.0, true)
	# The body: a deep red tub with a curled front and a high back, gold trim and a scroll.
	var tub := PackedVector2Array([o + Vector2(-70, 6), o + Vector2(-58, 28), o + Vector2(-20, 44), o + Vector2(70, 46), o + Vector2(118, 36), o + Vector2(132, -18), o + Vector2(112, -24), o + Vector2(104, 6), o + Vector2(-20, 8), o + Vector2(-56, -2)])
	draw_colored_polygon(tub, RED)
	draw_colored_polygon(PackedVector2Array([o + Vector2(-58, 28), o + Vector2(-20, 44), o + Vector2(70, 46), o + Vector2(118, 36), o + Vector2(114, 26), o + Vector2(70, 34), o + Vector2(-20, 32), o + Vector2(-52, 18)]), RED.darkened(0.25))
	draw_polyline(_close(tub), Color("#6E1220"), 2.0, true)
	draw_polyline(PackedVector2Array([o + Vector2(-62, 10), o + Vector2(-20, 14), o + Vector2(104, 12)]), GOLD, 3.0, true)
	draw_arc(o + Vector2(-74, 4), 9.0, PI * 0.6, PI * 2.2, 12, GOLD, 3.0, true)
	draw_arc(o + Vector2(126, -22), 10.0, PI * 1.0, PI * 2.4, 12, GOLD, 3.0, true)
	for i in 5:
		draw_arc(o + Vector2(-6.0 + i * 22.0, 26), 8.0, 0.2, PI - 0.2, 8, Color(GOLD, 0.8), 2.0, true)
	# The sack of presents, big on the back seat, a few boxes sticking out of it.
	var sack := PackedVector2Array()
	for i in 24:
		var a := PI + PI * i / 23.0
		sack.append(o + Vector2(98.0 + cos(a) * 44.0, 10.0 + sin(a) * 58.0 * (0.9 + 0.1 * sin(i))))
	sack.append(o + Vector2(54, 10))
	draw_colored_polygon(sack, Color("#9C6A38"))
	draw_colored_polygon(_shift(sack, Vector2(-5, -4), 0.9, o + Vector2(98, -20)), Color("#B98550"))
	draw_polyline(_close(sack), Color("#4E2E14"), 2.0, true)
	draw_line(o + Vector2(62, -24), o + Vector2(136, -26), Color("#4E2E14"), 3.0, true)
	var boxes := [[Vector2(78, -50), Color("#3A78C9"), 0.2], [Vector2(104, -58), Color("#2F9E55"), -0.15], [Vector2(124, -46), Color("#F2C230"), 0.3]]
	for b: Array in boxes:
		var bp: Vector2 = o + (b[0] as Vector2)
		_local(bp, float(b[2]))
		draw_rect(Rect2(-12, -10, 24, 20), b[1])
		draw_rect(Rect2(-2, -10, 4, 20), Color("#FFFFFF"))
		draw_rect(Rect2(-12, -2, 24, 4), Color("#FFFFFF"))
		_reset()
	draw_circle(o + Vector2(98, -76), 4.0, Color(GOLD, 0.9))
	# Santa, seated, leaning forward.
	var sp := o + Vector2(28, -8)
	draw_colored_polygon(_oval(sp + Vector2(10, -14), 30.0, 34.0, 0.15), RED.lightened(0.05))
	draw_polyline(_close(_oval(sp + Vector2(10, -14), 30.0, 34.0, 0.15)), Color("#6E1220"), 2.0, true)
	draw_line(sp + Vector2(-16, -10), sp + Vector2(38, -6), Color("#2A1A10"), 7.0, true)
	draw_rect(Rect2(sp + Vector2(6, -14), Vector2(12, 12)), GOLD)
	draw_rect(Rect2(sp + Vector2(9, -11), Vector2(6, 6)), Color("#2A1A10"))
	# Fur trim down his coat, his mitten holding the reins and the other waving.
	draw_line(sp + Vector2(-18, -24), sp + Vector2(-20, 4), Color.WHITE, 6.0, true)
	var wave := sin(_t * 9.0) * 0.5
	_local(sp + Vector2(16, -34), 1.2 + wave)
	draw_line(Vector2.ZERO, Vector2(0, -30), RED, 11.0, true)
	draw_circle(Vector2(0, -34), 8.0, Color("#F8F8F8"))
	_reset()
	draw_line(sp + Vector2(-8, -20), sp + Vector2(-48, 2), RED, 11.0, true)
	draw_circle(sp + Vector2(-50, 4), 7.0, Color("#F8F8F8"))
	# The head: rosy face, a huge white beard, white moustache, a red hat with a bobbing pompom.
	var head := sp + Vector2(-2, -66)
	draw_circle(head, 20.0, Color("#F2B99A"))
	draw_colored_polygon(_oval(head + Vector2(-6, 14), 26.0, 22.0, 0.1), Color.WHITE)
	draw_polyline(_close(_oval(head + Vector2(-6, 14), 26.0, 22.0, 0.1)), Color("#D6DDE8"), 1.6, true)
	for i in 5:
		draw_arc(head + Vector2(-20.0 + i * 8.0, 26.0), 7.0, 0.3, PI - 0.3, 8, Color("#E4EAF2"), 1.4, true)
	draw_circle(head + Vector2(-10, -1), 2.4, Color("#2A1A10"))
	draw_circle(head + Vector2(6, -1), 2.4, Color("#2A1A10"))
	draw_line(head + Vector2(-16, -7), head + Vector2(-6, -9), Color.WHITE, 3.0, true)
	draw_line(head + Vector2(2, -9), head + Vector2(12, -7), Color.WHITE, 3.0, true)
	draw_circle(head + Vector2(-2, 4), 4.0, Color("#E89A8A"))
	draw_colored_polygon(_oval(head + Vector2(-4, 8), 14.0, 5.0, 0.0), Color.WHITE)
	draw_circle(head + Vector2(-16, 6), 4.0, Color(1, 0.55, 0.55, 0.5))
	var hat := PackedVector2Array([head + Vector2(-24, -8), head + Vector2(22, -12), head + Vector2(14, -34), head + Vector2(-12, -46), head + Vector2(-44, -34), head + Vector2(-52, -18)])
	draw_colored_polygon(hat, RED)
	draw_polyline(_close(hat), Color("#6E1220"), 1.8, true)
	draw_colored_polygon(_oval(head + Vector2(-2, -10), 28.0, 7.0, -0.06), Color.WHITE)
	draw_circle(head + Vector2(-54.0 + sin(_t * 8.0) * 4.0, -16.0 + cos(_t * 8.0) * 3.0), 8.0, Color.WHITE)


func _local(pos: Vector2, rot: float, scale := Vector2.ONE) -> void:
	draw_set_transform_matrix(_frame * Transform2D(rot, pos).scaled_local(scale))


func _reset() -> void:
	draw_set_transform_matrix(_frame)


func _oval(c: Vector2, rx: float, ry: float, rot: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in 24:
		var a := TAU * i / 24.0
		out.append(c + Vector2(cos(a) * rx, sin(a) * ry).rotated(rot))
	return out


func _close(p: PackedVector2Array) -> PackedVector2Array:
	var c := p.duplicate()
	c.append(p[0])
	return c


func _shift(p: PackedVector2Array, d: Vector2, k: float, about: Vector2) -> PackedVector2Array:
	var out := PackedVector2Array()
	for v in p:
		out.append(about + (v - about) * k + d)
	return out
