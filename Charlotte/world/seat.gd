class_name Seat
extends Node2D
## A place to sit (a sofa, a bench, a stool): click it and Charlotte walks over and sits where she arrives (inside `span`, the x range
## of the seat), her feet dangling if it is high (`height`, world px above the floor). Click it again, press an arrow or click
## somewhere else and she gets up (`PlayerControl`). Anything with a `Character` can sit the same way: `sit(who)`.

var rect: Rect2
## Where along the seat she may sit (world x).
var span := Vector2.ZERO
var height := 90.0
## Which way she faces while she sits (1 right, -1 left).
var facing := 1
## The floor under the seat (world y): she steps back to it as she sits, onto the sofa rather than before it.
var floor_y := NAN
var condition := Callable()
var who: Character


static func make(area: Rect2, x_span: Vector2, seat_height: float, face := 1) -> Seat:
	var seat := Seat.new()
	seat.rect = area
	seat.span = x_span
	seat.height = seat_height
	seat.facing = face
	return seat


func _ready() -> void:
	add_to_group("interactable")


func can_interact() -> bool:
	return condition.call() if condition.is_valid() else true


func hit_test(p: Vector2) -> bool:
	return rect.has_point(p)


func approach_x(from_x: float) -> float:
	return clampf(from_x, span.x, span.y)


func reserve() -> void:
	pass


func release() -> void:
	pass


func interact(charlotte: Character) -> void:
	if charlotte.sitting:
		charlotte.sitting = false
		who = null
		return
	sit(charlotte)


func sit(person: Character) -> void:
	who = person
	person.facing = facing
	person.seat_h = height
	person.seat_floor = floor_y
	person.sitting = true
	person.is_walking = false
