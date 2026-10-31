class_name WindowCats
extends Node2D
## House cats that now and then hop up behind a window pane near the camera, watch the street, then hop down.
## Panes come from art/decor/windows.json (written by tools/generate_houses.gd).

const RISE := 0.7
const SLOTS := 1

var charlotte: Node2D
var _panes: Array[Dictionary] = []
var _busy := {}
var _rng := RandomNumberGenerator.new()


## `houses`: [{"art": name, "origin": Vector2, "scale": float}] in the parent's coordinates.
func setup(houses: Array) -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://art/decor/windows.json"))
	for h in houses:
		for w in data.get(h.art, []):
			if w.flower_box:
				continue
			var p: Array = w.pane
			var s: float = h.scale
			var rect := Rect2(h.origin + Vector2(p[0], p[1]) * s, Vector2(p[2], p[3]) * s)
			_panes.append({"rect": rect, "bar_y": h.origin.y + float(w.bar_y) * s, "trim": Color(w.trim), "scale": s})


func _ready() -> void:
	_rng.randomize()
	for i in SLOTS:
		_schedule(_rng.randf_range(2.0, 12.0) + i * 8.0)


func _schedule(wait: float) -> void:
	get_tree().create_timer(wait).timeout.connect(_appear)


func _appear() -> void:
	var cam := get_viewport().get_camera_2d()
	var view := Rect2(Vector2(cam.get_screen_center_position().x - 640.0, 0) if cam else Vector2.ZERO, Vector2(1280, 720))
	var choices := _panes.filter(func(p): return view.grow(-60.0).encloses(p.rect) and not _busy.has(p.rect))
	if choices.is_empty():
		_schedule(_rng.randf_range(3.0, 6.0))
		return
	var pane: Dictionary = choices[_rng.randi_range(0, choices.size() - 1)]
	_busy[pane.rect] = true
	var r: Rect2 = pane.rect
	var clip := Control.new()
	clip.clip_contents = true
	clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip.position = r.position
	clip.size = r.size
	add_child(clip)
	var cat := StrayCat.random(_rng)
	cat.wander = false
	cat.size = 0.55 * pane.scale / 0.57
	var right := _rng.randf() < 0.5
	cat.position = Vector2(r.size.x * (0.74 if right else 0.26), r.size.y + 64.0 * cat.size)
	cat.modulate = Color(0.86, 0.88, 0.94)
	if charlotte:
		cat.facing = 1 if charlotte.global_position.x > r.get_center().x else -1
	clip.add_child(cat)
	cat.remove_from_group("interactable")
	var glass := _Glass.new()
	glass.size = r.size
	glass.bar_y = pane.bar_y - r.position.y
	glass.trim = pane.trim
	glass.px = pane.scale
	glass.mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip.add_child(glass)
	var stay := _rng.randf_range(10.0, 22.0)
	var tween := create_tween()
	tween.tween_property(cat, "position:y", r.size.y - 2.0, RISE).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_interval(stay * 0.5)
	tween.tween_callback(func(): cat.facing = -cat.facing)
	tween.tween_interval(stay * 0.5)
	tween.tween_property(cat, "position:y", r.size.y + 64.0 * cat.size, RISE).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_callback(func():
		_busy.erase(pane.rect)
		clip.queue_free()
		_schedule(_rng.randf_range(16.0, 60.0)))


# Mullion and glare redrawn over the cat so it sits behind the glass.
class _Glass:
	extends Control
	var bar_y := 0.0
	var trim := Color.WHITE
	var px := 1.0

	func _draw() -> void:
		var s := px
		draw_rect(Rect2(-4.0 * s, bar_y - 3.0 * s, size.x + 8.0 * s, 6.0 * s), trim)
		draw_rect(Rect2(size.x / 2.0 - 3.0 * s, bar_y, 6.0 * s, size.y), trim)
		draw_colored_polygon(PackedVector2Array([Vector2(size.x * 0.55, 0), Vector2(size.x * 0.55 + 16.0 * s, 0),
			Vector2(16.0 * s, size.y * 0.55), Vector2(0, size.y * 0.55)]), Color(1, 1, 1, 0.1))
