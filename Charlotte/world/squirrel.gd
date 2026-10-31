class_name Squirrel
extends Node2D
## Montreal squirrel: sits and flicks its tail, scurries around, bolts away when someone comes close,
## often up the nearest tree, where it hides in the canopy and now and then pokes its head out.
## Squirrels are added before the trees, so a tree's canopy and trunk hide them naturally.

const SCARE := 170.0
const SCARE_RUNNING := 280.0
const CLIMB_SPEED := 150.0
## Tree texture layout (PropArt.tree): trunk base at (190, 780), canopy centred on (190, 250).
const TRUNK_X := 190.0
const CANOPY := Vector2(190, 250)
const CANOPY_BOTTOM := 470.0
const HIDE_AT := 330.0

var threat: Node2D
var bounds := Vector2(0, 1000)
var fur := Color("#7D7670")
## Street trees it can climb (sprites from PropArt.tree, unscaled origin top-left). May be filled later.
var trees: Array[Sprite2D] = []

var _state := "idle"
var _timer := 1.0
var _target := 0.0
var _speed := 0.0
var _t := 0.0
var _hop := 0.0
var _ground_y := 0.0
var _tree: Sprite2D
var _side := 1.0
# Peeking out of the canopy: where (texture coords), outward direction, 0..1 how far out.
var _peek_at := Vector2.ZERO
var _peek_dir := Vector2.UP
var _peek := 0.0
var _peek_timer := 0.0

static var _canopy_images := {}


func _ready() -> void:
	_ground_y = position.y
	_timer = randf_range(0.5, 3.0)
	if randf() < 0.35:
		fur = Color("#2B2826")


func _process(delta: float) -> void:
	_t += delta
	var near := _threat_near()
	match _state:
		"idle":
			if near:
				_flee()
			else:
				_timer -= delta
				if _timer <= 0.0:
					var tree := _nearest_tree(position.x, 320.0)
					if tree and randf() < 0.2:
						_run_to_tree(tree, 170.0)
					else:
						_go(position.x + randf_range(-260, 260), 170.0, "run")
		"run", "flee", "to_tree":
			if _state == "run" and near:
				_flee()
			var step := signf(_target - position.x) * _speed * delta
			if absf(_target - position.x) <= absf(step):
				position.x = _target
				if _state == "to_tree":
					_start_climb()
				else:
					_state = "idle"
					_timer = randf_range(1.5, 4.5)
			else:
				position.x += step
			_hop = fmod(_hop + delta * _speed / 38.0, 1.0)
		"up":
			position.y -= CLIMB_SPEED * delta
			_hop = fmod(_hop + delta * CLIMB_SPEED / 30.0, 1.0)
			if position.y <= _tree_y(HIDE_AT):
				_state = "hidden"
				_timer = randf_range(6.0, 14.0)
				_peek_timer = randf_range(1.0, 3.0)
		"hidden":
			_timer -= delta
			_peek_timer -= delta
			if _peek_timer <= 0.0:
				_start_peek()
			if _timer <= 0.0 and not near:
				_state = "down"
				scale.x = absf(scale.x) * _side
				rotation = PI / 2.0 * _side
		"peek":
			_peek_timer -= delta
			_peek = move_toward(_peek, 1.0 if _peek_timer > 0.0 else 0.0, delta * 3.0)
			# Look around while it's out.
			if _peek_timer > 0.0 and fmod(_t, 1.3) < delta:
				scale.x = -scale.x
			# From tucked in (hidden behind the leaves) to the head just clear of the outline.
			var edge := _tree.position + _peek_at * _tree.scale + Vector2(_sway(_peek_at.y), 0)
			position = edge + _peek_dir * lerpf(-12.0, 4.0, _peek)
			if _peek_timer <= 0.0 and _peek == 0.0:
				_state = "hidden"
				_hide_in_canopy()
				_peek_timer = randf_range(2.0, 5.0)
				_timer = maxf(_timer, 1.0)
		"down":
			if near and position.y < _ground_y - 40.0:
				_start_climb()
			else:
				position.y += CLIMB_SPEED * 0.8 * delta
				_hop = fmod(_hop + delta * CLIMB_SPEED / 30.0, 1.0)
				if position.y >= _ground_y:
					position.y = _ground_y
					rotation = 0.0
					_state = "idle"
					_timer = randf_range(1.0, 3.0)
	queue_redraw()


func _threat_near() -> bool:
	if threat == null:
		return false
	var reach := SCARE_RUNNING if threat.get("running") else SCARE
	return absf(threat.global_position.x - global_position.x) < reach


# Up the nearest tree away from the threat, or else along the sidewalk.
func _flee() -> void:
	var away := signf(global_position.x - threat.global_position.x)
	if away == 0.0:
		away = 1.0
	var best: Sprite2D
	for tree in trees:
		var tx := _trunk_x(tree)
		var d := tx - position.x
		if absf(d) < 420.0 and (signf(d) == away or absf(d) < 40.0) and absf(tx - threat.global_position.x) > 60.0:
			if best == null or absf(d) < absf(_trunk_x(best) - position.x):
				best = tree
	if best and randf() < 0.8:
		_run_to_tree(best, 340.0)
	else:
		_go(position.x + away * randf_range(320, 480), 340.0, "flee")


func _nearest_tree(x: float, within: float) -> Sprite2D:
	var best: Sprite2D
	for tree in trees:
		if absf(_trunk_x(tree) - x) < within and (best == null or absf(_trunk_x(tree) - x) < absf(_trunk_x(best) - x)):
			best = tree
	return best


func _run_to_tree(tree: Sprite2D, speed: float) -> void:
	_tree = tree
	# Climb on the side it comes from, clinging to the edge of the trunk.
	_side = -1.0 if position.x < _trunk_x(tree) else 1.0
	_speed = speed
	_state = "to_tree"
	_target = _trunk_x(tree) + _side * 9.0
	if _target != position.x:
		scale.x = absf(scale.x) * signf(_target - position.x)


# Head up, belly against the trunk.
func _start_climb() -> void:
	_state = "up"
	scale.x = absf(scale.x) * -_side
	rotation = -PI / 2.0 * -_side
	position.x = _trunk_x(_tree) + _side * 9.0


func _start_peek() -> void:
	var edge := _canopy_edge(_tree, randf_range(-PI * 0.92, -PI * 0.08))
	if edge.is_empty():
		_peek_timer = 1.0
		return
	_peek_at = edge[0]
	_peek_dir = edge[1]
	_peek = 0.0
	_peek_timer = randf_range(1.5, 3.5)
	_state = "peek"
	# Lean out along the canopy's outline.
	rotation = (_peek_dir.angle() + PI / 2.0) * 0.6
	scale.x = absf(scale.x) * (1.0 if randf() < 0.5 else -1.0)


func _hide_in_canopy() -> void:
	position = Vector2(_trunk_x(_tree) + _side * 9.0, _tree_y(HIDE_AT))
	rotation = -PI / 2.0 * -_side
	scale.x = absf(scale.x) * -_side


func _trunk_x(tree: Sprite2D) -> float:
	return tree.position.x + TRUNK_X * tree.scale.x


func _tree_y(texture_y: float) -> float:
	return _tree.position.y + texture_y * _tree.scale.y


# Horizontal offset of the tree's sway shader at this texture height, so a peeking head moves with the leaves.
func _sway(texture_y: float) -> float:
	var mat := _tree.material as ShaderMaterial
	if mat == null:
		return 0.0
	var time := Time.get_ticks_msec() / 1000.0
	var speed: float = mat.get_shader_parameter("speed") if mat.get_shader_parameter("speed") != null else 1.1
	var phase: float = mat.get_shader_parameter("phase")
	var gust: float = mat.get_shader_parameter("gust") if mat.get_shader_parameter("gust") != null else 0.0
	var top := 1.0 - texture_y / float(_tree.texture.get_height())
	var breeze := sin(time * speed + phase) + 0.35 * sin(time * speed * 2.7 + phase * 1.7)
	var push := gust * (2.6 + 0.5 * sin(time * 6.0 + phase))
	return (breeze + push) * float(mat.get_shader_parameter("strength")) * top * top * _tree.scale.x


# Where the canopy's leaves end in direction `angle` from its centre: [point, outward dir] in texture coords.
func _canopy_edge(tree: Sprite2D, angle: float) -> Array:
	var tex := tree.texture
	if not _canopy_images.has(tex):
		_canopy_images[tex] = tex.get_image()
	var img: Image = _canopy_images[tex]
	var dir := Vector2.from_angle(angle)
	var clear := 0
	var r := 40.0
	while r < 240.0:
		var p := CANOPY + dir * r
		if p.x < 0 or p.y < 0 or p.x >= img.get_width() or p.y >= img.get_height() or img.get_pixelv(Vector2i(p)).a < 0.3:
			clear += 1
			# A real gap, not the space between two scattered leaves.
			if clear >= 6:
				return [CANOPY + dir * (r - 10.0), dir]
		else:
			clear = 0
		r += 2.0
	return []


func _go(x: float, speed: float, state: String) -> void:
	_target = clampf(x, bounds.x, bounds.y)
	_speed = speed
	_state = state
	if _target != position.x:
		scale.x = absf(scale.x) * signf(_target - position.x)


func _draw() -> void:
	if _state == "hidden":
		return
	var dark := fur.darkened(0.3)
	if _state == "peek":
		_draw_peek(dark)
		return
	var climbing := _state == "up" or _state == "down"
	var moving := _state != "idle"
	var lift := -absf(sin(_hop * PI)) * 10.0 if moving and not climbing else 0.0
	var belly := fur.lightened(0.35)
	if not climbing:
		draw_set_transform(Vector2(0, 1), 0.0, Vector2(1, 0.22))
		draw_circle(Vector2.ZERO, 16, Color(0, 0, 0, 0.2))
	draw_set_transform(Vector2(0, lift))
	var flick := sin(_t * 12.0) * 3.0 if not moving and fmod(_t, 3.0) < 0.5 else 0.0
	var tail: Array[Vector3] = []
	if climbing:
		tail = [Vector3(-10, -8, 5), Vector3(-18, -10, 7), Vector3(-27, -10, 8.5), Vector3(-35, -7, 9), Vector3(-42, -2, 8), Vector3(-47, 4, 6)]
	elif moving:
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
	_face(Vector2(14, -14) if moving else Vector2(6, -28), dark)


# Just the head and front paws, poking out of the leaves (the canopy, drawn on top, hides the rest).
func _draw_peek(dark: Color) -> void:
	# A bit larger than life so the little head reads from the street.
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE * 1.3)
	draw_circle(Vector2(-4, 4), 2.6, dark)
	draw_circle(Vector2(5, 4), 2.6, dark)
	draw_circle(Vector2(0, 2), 8.2, dark)
	draw_circle(Vector2(0, 2), 7.5, fur)
	draw_circle(Vector2(3, 4), 3.5, fur.lightened(0.3))
	_face(Vector2(0, 2), dark)


func _face(head: Vector2, dark: Color) -> void:
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
