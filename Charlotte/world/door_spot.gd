class_name DoorSpot
extends Node2D
## A clickable door (or any spot): Charlotte walks to `stand_x`, then `action` runs.
## `rect` is the clickable area in world coordinates.

var rect: Rect2
var stand_x := NAN
var action: Callable
## Optional: where to stand, worked out from where Charlotte is (from_x → x), instead of `stand_x`.
var approach := Callable()
## Optional: whether it can be clicked right now.
var condition := Callable()


static func make(area: Rect2, on_enter: Callable, stand := NAN) -> DoorSpot:
	var door := DoorSpot.new()
	door.rect = area
	door.action = on_enter
	door.stand_x = area.get_center().x if is_nan(stand) else stand
	door.position = Vector2(door.stand_x, area.end.y)
	return door


func _ready() -> void:
	add_to_group("interactable")


func can_interact() -> bool:
	return condition.call() if condition.is_valid() else true


func hit_test(p: Vector2) -> bool:
	return rect.has_point(p)


func approach_x(from_x: float) -> float:
	return approach.call(from_x) if approach.is_valid() else stand_x


func reserve() -> void:
	pass


func release() -> void:
	pass


func interact(_who: Character) -> void:
	action.call()
