class_name Passerby
extends Character
## A neighbour walking along the sidewalk, always the same way, as people do: off one end of the street and, a while
## later, someone else's turn, back in from the other end. Only stops while Charlotte pets their dog.

## Where they walk off the street (past either end, out of sight) and come back in at the other end.
var bounds := Vector2(-140, 1000)
var _pause := 0.0


## Stops walking for `seconds` (e.g. while Charlotte pets their dog).
func hold(seconds: float) -> void:
	_pause = seconds


func _process(delta: float) -> void:
	if _pause > 0.0:
		_pause -= delta
		is_walking = false
	else:
		is_walking = true
		position.x += facing * walk_speed * delta
		if facing > 0 and position.x > bounds.y:
			position.x = bounds.x
		elif facing < 0 and position.x < bounds.x:
			position.x = bounds.y
	super._process(delta)
