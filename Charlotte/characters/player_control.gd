class_name PlayerControl
extends Node
## Moves Charlotte with ←/→ or click/tap-to-walk (double-press or double-click/tap to run), and walks her
## to clicked interactables before calling their interact(); ↑ in front of a door (any DoorSpot) goes through it. Shared by the street and the house. Interactables join the "interactable" group and
## implement can_interact(), hit_test(point), approach_x(from_x), reserve(), release(), interact(charlotte).

var charlotte: Character
var bounds := Vector2(60, 1000)
## Clicks above this y (in world space) don't walk Charlotte, unless they hit an interactable.
var walk_top := 0.0
var enabled := true
## While true (a scripted moment like crossing the street), leaves Charlotte's walking to the script.
var hands_off := false

## Two presses (or clicks) closer than this make Charlotte run.
const DOUBLE_TIME := 0.32
## Max distance between the two clicks/taps of a double click, in screen pixels.
const DOUBLE_DIST := 48.0

var _goal_x := NAN
var _goal_target: CanvasItem
# Last arrow press (direction, time) and last click (screen position, time), to spot doubles.
var _last_key_dir := 0
var _last_key_at := -10.0
var _last_click := Vector2.ZERO
var _last_click_at := -10.0


func _init() -> void:
	# Run before the scene script so the camera follows the position set this frame.
	process_priority = -1


func _process(delta: float) -> void:
	if hands_off:
		return
	if not enabled:
		charlotte.is_walking = false
		charlotte.running = false
		return
	var speed := charlotte.speed()
	var dir := Input.get_axis("ui_left", "ui_right")
	if dir != 0.0:
		_goal_x = NAN
		_set_goal_target(null)
		if charlotte.is_petting():
			charlotte.pet(0.0)
	elif not is_nan(_goal_x):
		var dx := _goal_x - charlotte.position.x
		if absf(dx) <= speed * delta:
			charlotte.position.x = _goal_x
			_goal_x = NAN
			_arrive()
		else:
			dir = signf(dx)
	if dir == 0.0:
		charlotte.running = false
	if charlotte.is_petting() and dir == 0.0:
		charlotte.is_walking = false
	else:
		charlotte.is_walking = dir != 0.0
	if dir != 0.0:
		charlotte.facing = 1 if dir > 0.0 else -1
		charlotte.position.x = clampf(charlotte.position.x + dir * speed * delta, bounds.x, bounds.y)


## Clears any walk target (e.g. when teleporting through a door).
func stop() -> void:
	_goal_x = NAN
	_set_goal_target(null)
	charlotte.is_walking = false
	charlotte.running = false


func _unhandled_input(event: InputEvent) -> void:
	if not enabled:
		return
	var now := Time.get_ticks_msec() / 1000.0
	var key_dir := 1 if event.is_action_pressed("ui_right") else -1 if event.is_action_pressed("ui_left") else 0
	if event.is_action_pressed("ui_up"):
		# ↑ in front of a door (or any spot): go through it, as if it had been clicked.
		var door := _door_ahead()
		if door:
			_set_goal_target(door)
			_goal_x = clampf(door.approach_x(charlotte.position.x), bounds.x, bounds.y)
	elif key_dir != 0:
		# Same arrow twice in a row: run for as long as it is held.
		charlotte.running = key_dir == _last_key_dir and now - _last_key_at < DOUBLE_TIME
		_last_key_dir = key_dir
		_last_key_at = now
	elif event is InputEventMouseMotion:
		var hovering := _interactable_at(_to_world(event.position)) != null
		Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND if hovering else Input.CURSOR_ARROW)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# Timed by hand rather than event.double_click, so emulated taps on a tablet count too.
		charlotte.running = now - _last_click_at < DOUBLE_TIME and event.position.distance_to(_last_click) < DOUBLE_DIST
		_last_click = event.position
		_last_click_at = now
		var at := _to_world(event.position)
		var target := _interactable_at(at)
		_set_goal_target(target)
		if target:
			_goal_x = clampf(target.approach_x(charlotte.position.x), bounds.x, bounds.y)
		elif at.y > walk_top:
			_goal_x = clampf(at.x, bounds.x, bounds.y)


# Touches arrive as emulated mouse events, so this covers tablets too.
func _to_world(screen: Vector2) -> Vector2:
	return get_viewport().get_canvas_transform().affine_inverse() * screen


func _interactable_at(point: Vector2) -> CanvasItem:
	for node in get_tree().get_nodes_in_group("interactable"):
		if node.can_interact() and node.hit_test(point):
			return node
	return null


# The door (DoorSpot) Charlotte stands in front of: its area spans her x; the nearest if several.
func _door_ahead() -> DoorSpot:
	var best: DoorSpot = null
	var best_d := INF
	var x := charlotte.position.x
	for node in get_tree().get_nodes_in_group("interactable"):
		var door := node as DoorSpot
		if door == null or not door.can_interact() or x < door.rect.position.x - 20.0 or x > door.rect.end.x + 20.0:
			continue
		var d := absf(door.rect.get_center().x - x)
		if d < best_d:
			best = door
			best_d = d
	return best


func _set_goal_target(target: CanvasItem) -> void:
	if _goal_target and is_instance_valid(_goal_target):
		_goal_target.release()
	_goal_target = target
	if target:
		target.reserve()


func _arrive() -> void:
	var target := _goal_target
	_goal_target = null
	if target and is_instance_valid(target) and target.can_interact():
		# Interactables can name the x to look at (e.g. the hamster moving inside its terrarium).
		var look_x: float = target.focus_x() if target.has_method("focus_x") else (target as Node2D).position.x
		if absf(look_x - charlotte.position.x) > 1.0:
			charlotte.facing = 1 if look_x > charlotte.position.x else -1
		target.interact(charlotte)
