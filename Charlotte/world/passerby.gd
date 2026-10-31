class_name Passerby
extends Character
## A neighbour strolling along the sidewalk, stopping now and then.

var bounds := Vector2(0, 1000)
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
		if position.x < bounds.x:
			facing = 1
		elif position.x > bounds.y:
			facing = -1
		elif randf() < delta * 0.06:
			_pause = randf_range(1.5, 4.0)
			if randf() < 0.4:
				facing = -facing
	super._process(delta)
