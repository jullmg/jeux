class_name Confetti
extends Control
## Une pluie de confettis pour les victoires, dessinée par-dessus tout.

const COLORS := [Color("d9719a"), Color("ffc83d"), Color("5da845"), Color("3f6fd8"), Color("e0453a"), Color("fff3df")]

var _bits: Array[Dictionary] = []
var _time := 0.0


func _init(count := 160) -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	process_mode = Node.PROCESS_MODE_ALWAYS
	var rng := RandomNumberGenerator.new()
	rng.seed = 12
	for i in count:
		_bits.append({"x": rng.randf(), "wait": rng.randf() * 1.6, "speed": rng.randf_range(260.0, 520.0),
			"drift": rng.randf_range(20.0, 90.0), "spin": rng.randf_range(3.0, 11.0), "phase": rng.randf() * TAU,
			"size": rng.randf_range(10.0, 20.0), "color": COLORS[i % COLORS.size()]})


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()
	if _time > 8.0:
		queue_free()


func _draw() -> void:
	for b in _bits:
		var t: float = _time - b.wait
		if t < 0.0:
			continue
		var y: float = -30.0 + t * b.speed
		if y > size.y + 30.0:
			continue
		var x: float = b.x * size.x + sin(t * 2.3 + b.phase) * b.drift
		# Le confetti tourne sur lui-même : sa largeur change.
		var flip: float = cos(t * b.spin + b.phase)
		draw_set_transform(Vector2(x, y), sin(t * 3.0 + b.phase) * 0.8, Vector2(maxf(0.15, absf(flip)), 1.0))
		var s: float = b.size
		draw_rect(Rect2(-s / 2.0, -s * 0.3, s, s * 0.6), b.color if flip > 0.0 else (b.color as Color).darkened(0.25))
	draw_set_transform_matrix(Transform2D.IDENTITY)
