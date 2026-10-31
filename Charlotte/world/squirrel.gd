class_name Squirrel
extends Node2D
## Montreal squirrel: sits and flicks its tail, scurries around, bolts away when someone comes close.

var threat: Node2D
var bounds := Vector2(0, 1000)
var fur := Color("#7D7670")

var _state := "idle"
var _timer := 1.0
var _target := 0.0
var _speed := 0.0
var _t := 0.0
var _hop := 0.0


func _ready() -> void:
	_timer = randf_range(0.5, 3.0)
	if randf() < 0.35:
		fur = Color("#2B2826")


func _process(delta: float) -> void:
	_t += delta
	if threat and _state != "flee" and absf(threat.global_position.x - global_position.x) < 120.0:
		var away := signf(global_position.x - threat.global_position.x)
		_go(position.x + (away if away != 0.0 else 1.0) * randf_range(320, 480), 340.0, "flee")
	match _state:
		"idle":
			_timer -= delta
			if _timer <= 0.0:
				_go(position.x + randf_range(-260, 260), 170.0, "run")
		_:
			var step := signf(_target - position.x) * _speed * delta
			if absf(_target - position.x) <= absf(step):
				position.x = _target
				_state = "idle"
				_timer = randf_range(1.5, 4.5)
			else:
				position.x += step
			_hop = fmod(_hop + delta * _speed / 38.0, 1.0)
	queue_redraw()


func _go(x: float, speed: float, state: String) -> void:
	_target = clampf(x, bounds.x, bounds.y)
	_speed = speed
	_state = state
	if _target != position.x:
		scale.x = absf(scale.x) * signf(_target - position.x)


func _draw() -> void:
	var moving := _state != "idle"
	var lift := -absf(sin(_hop * PI)) * 10.0 if moving else 0.0
	var dark := fur.darkened(0.3)
	var belly := fur.lightened(0.35)
	draw_set_transform(Vector2(0, 1), 0.0, Vector2(1, 0.22))
	draw_circle(Vector2.ZERO, 16, Color(0, 0, 0, 0.2))
	draw_set_transform(Vector2(0, lift))
	var flick := sin(_t * 12.0) * 3.0 if not moving and fmod(_t, 3.0) < 0.5 else 0.0
	var tail: Array[Vector3] = []
	if moving:
		tail = [Vector3(-10, -10, 5), Vector3(-18, -15, 7), Vector3(-27, -19, 8.5), Vector3(-36, -20, 9), Vector3(-44, -17, 8), Vector3(-50, -12, 6)]
	else:
		tail = [Vector3(-8, -6, 5), Vector3(-15, -14, 7), Vector3(-19, -25, 8.5), Vector3(-17, -37, 9.5), Vector3(-10, -45, 8.5), Vector3(-3, -45, 6)]
	var spine: Array[Vector3] = []
	for i in tail.size():
		spine.append(Vector3(tail[i].x + flick * i / 5.0, tail[i].y, tail[i].z))
	_bushy_tail(spine, dark)
	if moving:
		draw_set_transform(Vector2(0, lift), 0.0, Vector2(1.3, 0.75))
		draw_circle(Vector2(0, -12), 10, dark)
		draw_circle(Vector2(0, -13), 9, fur)
		draw_set_transform(Vector2(0, lift))
		draw_circle(Vector2(14, -14), 7, fur)
		var legs := sin(_hop * TAU) * 4.0
		draw_line(Vector2(-7, -5), Vector2(-9 - legs, 0), dark, 3.0)
		draw_line(Vector2(7, -5), Vector2(9 + legs, 0), dark, 3.0)
	else:
		draw_set_transform(Vector2(0, lift), 0.0, Vector2(0.85, 1.15))
		draw_circle(Vector2(0, -11), 11, dark)
		draw_circle(Vector2(0.5, -12), 10, fur)
		draw_circle(Vector2(4, -10), 5.5, belly)
		draw_set_transform(Vector2(0, lift))
		draw_circle(Vector2(6, -28), 7.5, fur)
		draw_circle(Vector2(9, -20), 2.6, dark)
		draw_line(Vector2(-6, -1), Vector2(6, -1), dark, 3.0)
	var head := Vector2(14, -14) if moving else Vector2(6, -28)
	draw_colored_polygon(PackedVector2Array([head + Vector2(-4, -4), head + Vector2(-2, -12), head + Vector2(2, -5)]), dark)
	draw_circle(head + Vector2(3, -1), 1.7, Color.BLACK)
	draw_circle(head + Vector2(3.5, -1.6), 0.6, Color.WHITE)
	draw_circle(head + Vector2(7, 1), 1.3, Color("#3A2A2A"))


# One tapered plume along the control points (x, y, half-width): softly tufted outline, shaded
# underside and a lighter core, instead of a chain of circles.
func _bushy_tail(ctrl: Array[Vector3], dark: Color) -> void:
	var n := 22
	var spine := PackedVector2Array()
	var widths := PackedFloat32Array()
	for i in n:
		var f := float(i) / (n - 1) * (ctrl.size() - 1)
		var k := mini(int(f), ctrl.size() - 2)
		var t := f - k
		var p0 := ctrl[maxi(k - 1, 0)]
		var p1 := ctrl[k]
		var p2 := ctrl[k + 1]
		var p3 := ctrl[mini(k + 2, ctrl.size() - 1)]
		# Catmull-Rom through the control points.
		var p := 0.5 * (2.0 * p1 + (p2 - p0) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t * t + (3.0 * p1 - p0 - 3.0 * p2 + p3) * t * t * t)
		spine.append(Vector2(p.x, p.y))
		# Thin at the root, fullest past the middle, rounded off at the tip.
		var u := float(i) / (n - 1)
		widths.append(p.z * (0.45 + 0.7 * sin(minf(u * 1.2, 1.0) * PI * 0.5)) * (1.0 if u < 0.8 else 1.0 - (u - 0.8) * 2.5))
	draw_colored_polygon(_plume(spine, widths, 1.6, 1.0), dark)
	draw_colored_polygon(_plume(spine, widths, 0.0, 1.0), fur)
	draw_colored_polygon(_plume(spine, widths, 0.0, -0.1, true), fur.darkened(0.14))
	var core := PackedVector2Array()
	for i in range(1, n - 2):
		core.append(spine[i] + _normal(spine, i) * widths[i] * 0.25)
	draw_polyline(core, fur.lightened(0.2), 2.0, true)


# Outline of the plume grown by `grow` px. With `half`, only the underside strip from the spine
# (offset `side` widths) down to the lower edge.
func _plume(spine: PackedVector2Array, widths: PackedFloat32Array, grow: float, side: float, half := false) -> PackedVector2Array:
	var top := PackedVector2Array()
	var bottom := PackedVector2Array()
	for i in spine.size():
		var nrm := _normal(spine, i)
		var tuft := 1.0 + 0.07 * sin(i * 2.3) + 0.04 * sin(i * 5.1)
		var w := widths[i] * tuft + grow
		top.append(spine[i] + nrm * (w if not half else widths[i] * side))
		bottom.append(spine[i] - nrm * w)
	var last := spine.size() - 1
	if not half:
		top.append(spine[last] + (spine[last] - spine[last - 1]).normalized() * (widths[last] * 0.6 + grow))
	bottom.reverse()
	top.append_array(bottom)
	return top


func _normal(spine: PackedVector2Array, i: int) -> Vector2:
	var a := spine[maxi(i - 1, 0)]
	var b := spine[mini(i + 1, spine.size() - 1)]
	return (b - a).normalized().orthogonal()
