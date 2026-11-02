class_name ShopCustomer
extends Character
## Someone shopping in a corner store: they stand in front of a shelf looking round, now and then walk on to another one
## (`stops`: x of the places they browse), at a stroll. Behind Charlotte, never in her way; not clickable.

var stops: Array[float] = []
var _target := NAN
var _wait := 0.0


func _ready() -> void:
	fidgets = true
	fidget_moves = ["look", "look", "stretch"]
	walk_speed = randf_range(70.0, 100.0)
	_wait = randf_range(1.0, 6.0)
	super._ready()


func _process(delta: float) -> void:
	if is_nan(_target):
		is_walking = false
		_wait -= delta
		if _wait <= 0.0 and stops.size() > 1:
			var options := stops.filter(func(x: float) -> bool: return absf(x - position.x) > 160.0)
			if not options.is_empty():
				_target = options[randi() % options.size()]
	else:
		is_walking = true
		facing = 1 if _target > position.x else -1
		position.x += facing * walk_speed * delta
		if absf(_target - position.x) < 6.0:
			_target = NAN
			is_walking = false
			_wait = randf_range(6.0, 14.0)
			facing = 1 if randf() < 0.5 else -1
	super._process(delta)
