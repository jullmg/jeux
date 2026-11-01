class_name WindowNeighbour
extends Node2D
## A grumpy old man sitting in his armchair, watching the street through his ground-floor window: white tufts round
## a bald head, glasses, a cardigan, a mug. He doesn't smile and doesn't wave; he blinks and follows Charlotte with
## a stern look. Click him and he grumbles. Drawn over the facade inside the window's big upper pane (`size`, from the
## node's position), with the glass's sheen on top.

const GRUMBLES := ["Hmpf.", "…", "Pas de ballon dans mes fleurs !", "Hmm."]

var size := Vector2(35, 48)
var charlotte: Node2D
var _t := 0.0
var _blink := 2.0
var _look := 0.0
var _grumble := 0


func _ready() -> void:
	add_to_group("interactable")


func _process(delta: float) -> void:
	_t += delta
	_blink -= delta
	if _blink < -0.15:
		_blink = randf_range(2.0, 5.0)
	var target := 0.0
	if charlotte:
		var dx := charlotte.global_position.x - (global_position.x + size.x / 2.0)
		target = clampf(dx / 300.0, -1.0, 1.0) if absf(dx) < 500.0 else sin(_t * 0.3) * 0.3
	_look = move_toward(_look, target, delta * 1.5)
	queue_redraw()


func _draw() -> void:
	var w := size.x
	var h := size.y
	# The room behind: warm and dim, the armchair's wing back.
	draw_rect(Rect2(Vector2.ZERO, size), Color("#4A3A30"))
	draw_rect(Rect2(Vector2(0, h * 0.62), Vector2(w, h * 0.38)), Color("#3A2C24"))
	var chair := Rect2(Vector2(w * 0.12, h * 0.34), Vector2(w * 0.76, h * 0.66))
	draw_rect(chair, Color("#6E3A3A"))
	draw_circle(Vector2(w * 0.12, h * 0.46), w * 0.1, Color("#5E3030"))
	draw_circle(Vector2(w * 0.88, h * 0.46), w * 0.1, Color("#5E3030"))
	# Shoulders in a brown cardigan, a white collar.
	var body := Vector2(w * 0.5, h * 0.98)
	draw_colored_polygon(PackedVector2Array([body + Vector2(-w * 0.34, 0), body + Vector2(-w * 0.28, -h * 0.3),
		body + Vector2(w * 0.28, -h * 0.3), body + Vector2(w * 0.34, 0)]), Color("#8A6A4A"))
	draw_colored_polygon(PackedVector2Array([body + Vector2(-w * 0.08, -h * 0.3), body + Vector2(0, -h * 0.2), body + Vector2(w * 0.08, -h * 0.3)]), Color("#F2EFE8"))
	# The head, turned a little toward Charlotte.
	var head := Vector2(w * 0.5 + _look * w * 0.06, h * 0.46)
	var r := w * 0.23
	draw_circle(head, r, Color("#EBC4A8"))
	for side in [-1.0, 1.0]:
		draw_circle(head + Vector2(side * r * 0.95, r * 0.05), r * 0.38, Color("#EDEDED"))
		draw_circle(head + Vector2(side * r * 1.0, r * 0.15), r * 0.22, Color("#EBC4A8"))
	var eye_shift := Vector2(_look * r * 0.25, 0)
	for side in [-1.0, 1.0]:
		var e := head + Vector2(side * r * 0.38, -r * 0.05) + eye_shift
		draw_arc(e, r * 0.28, 0, TAU, 12, Color("#3A3A48"), 1.0, true)
		if _blink > 0.0:
			draw_circle(e, r * 0.1, Color("#2B2B33"))
		else:
			draw_line(e - Vector2(r * 0.12, 0), e + Vector2(r * 0.12, 0), Color("#2B2B33"), 1.0)
	draw_line(head + Vector2(-r * 0.1, -r * 0.05) + eye_shift, head + Vector2(r * 0.1, -r * 0.05) + eye_shift, Color("#3A3A48"), 1.0)
	# Bushy frowning brows, a flat, turned-down mouth, a white moustache.
	for side in [-1.0, 1.0]:
		var b := head + Vector2(side * r * 0.38, -r * 0.4) + eye_shift
		draw_line(b + Vector2(-side * r * 0.22, -r * 0.08), b + Vector2(side * r * 0.2, r * 0.04), Color("#E6E6E6"), 2.0)
	draw_line(head + Vector2(-r * 0.32, r * 0.2) + eye_shift, head + Vector2(r * 0.32, r * 0.2) + eye_shift, Color("#F2F2F2"), 2.0)
	draw_arc(head + Vector2(0, r * 0.62) + eye_shift, r * 0.22, -PI + 0.6, -0.6, 6, Color("#8E5A4A"), 1.2, true)
	# His mug on the armrest.
	draw_rect(Rect2(Vector2(w * 0.68, h * 0.8), Vector2(w * 0.1, h * 0.1)), Color("#F2EFE8"))
	draw_arc(Vector2(w * 0.8, h * 0.85), w * 0.03, -PI / 2.0, PI / 2.0, 6, Color("#F2EFE8"), 1.0)
	# The glass over him: a cool sheen and a diagonal glint.
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.75, 0.88, 0.95, 0.18))
	draw_colored_polygon(PackedVector2Array([Vector2(w * 0.55, 0), Vector2(w * 0.75, 0), Vector2(w * 0.2, h * 0.6), Vector2(0, h * 0.6)]), Color(1, 1, 1, 0.12))


# ── Interactable ────────────────────────────────────────────

func can_interact() -> bool:
	return true


func hit_test(p: Vector2) -> bool:
	return Rect2(global_position, size).has_point(p)


func approach_x(_from_x: float) -> float:
	return global_position.x + size.x / 2.0


func reserve() -> void:
	pass


func release() -> void:
	pass


func interact(_who: Character) -> void:
	Bubble.say(get_parent(), global_position + Vector2(size.x / 2.0, -6.0), GRUMBLES[_grumble % GRUMBLES.size()], 2.4)
	_grumble += 1
