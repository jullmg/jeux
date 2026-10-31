class_name PlayerControl
extends Node
## Moves Charlotte with ←/→ or click/tap-to-walk, and walks her to clicked interactables before calling
## their interact(). Shared by the street and the house. Interactables join the "interactable" group and
## implement can_interact(), hit_test(point), approach_x(from_x), reserve(), release(), interact(charlotte).

var charlotte: Character
var bounds := Vector2(60, 1000)
## Clicks above this y (in world space) don't walk Charlotte, unless they hit an interactable.
var walk_top := 0.0
var enabled := true

var _goal_x := NAN
var _goal_target: Node2D


func _init() -> void:
	# Run before the scene script so the camera follows the position set this frame.
	process_priority = -1


func _process(delta: float) -> void:
	if not enabled:
		charlotte.is_walking = false
		return
	var dir := Input.get_axis("ui_left", "ui_right")
	if dir != 0.0:
		_goal_x = NAN
		_set_goal_target(null)
		if charlotte.is_petting():
			charlotte.pet(0.0)
	elif not is_nan(_goal_x):
		var dx := _goal_x - charlotte.position.x
		if absf(dx) <= charlotte.walk_speed * delta:
			charlotte.position.x = _goal_x
			_goal_x = NAN
			_arrive()
		else:
			dir = signf(dx)
	if charlotte.is_petting() and dir == 0.0:
		charlotte.is_walking = false
	else:
		charlotte.is_walking = dir != 0.0
	if dir != 0.0:
		charlotte.facing = 1 if dir > 0.0 else -1
		charlotte.position.x = clampf(charlotte.position.x + dir * charlotte.walk_speed * delta, bounds.x, bounds.y)


## Clears any walk target (e.g. when teleporting through a door).
func stop() -> void:
	_goal_x = NAN
	_set_goal_target(null)
	charlotte.is_walking = false


func _unhandled_input(event: InputEvent) -> void:
	if not enabled:
		return
	if event is InputEventMouseMotion:
		var hovering := _interactable_at(_to_world(event.position)) != null
		Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND if hovering else Input.CURSOR_ARROW)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
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


func _interactable_at(point: Vector2) -> Node2D:
	for node in get_tree().get_nodes_in_group("interactable"):
		if node.can_interact() and node.hit_test(point):
			return node
	return null


func _set_goal_target(target: Node2D) -> void:
	if _goal_target and is_instance_valid(_goal_target):
		_goal_target.release()
	_goal_target = target
	if target:
		target.reserve()


func _arrive() -> void:
	var target := _goal_target
	_goal_target = null
	if target and is_instance_valid(target) and target.can_interact():
		if absf(target.position.x - charlotte.position.x) > 1.0:
			charlotte.facing = 1 if target.position.x > charlotte.position.x else -1
		target.interact(charlotte)
