class_name Cloud
extends Node2D
## Soft cumulus lit from the low sun: warm undersides, slow drift.

var speed := 8.0
var span := Vector2(-400, 3000)
var _puffs := []


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(position)
	var n := rng.randi_range(5, 9)
	for i in n:
		var t := float(i) / (n - 1)
		var r := rng.randf_range(22.0, 44.0) * (1.0 - absf(t - 0.5))  + 14.0
		_puffs.append(Vector3(lerpf(-90, 90, t) + rng.randf_range(-12, 12), -r * 0.55 + rng.randf_range(-8, 4), r))


func _process(delta: float) -> void:
	position.x += speed * delta
	if position.x > span.y:
		position.x = span.x


func _draw() -> void:
	for p in _puffs:
		draw_circle(Vector2(p.x + 4, p.y + 6), p.z, Color("#F2C9B8"))
	for p in _puffs:
		draw_circle(Vector2(p.x, p.y), p.z, Color("#FFF6EE"))
	for p in _puffs:
		draw_circle(Vector2(p.x - p.z * 0.25, p.y - p.z * 0.3), p.z * 0.55, Color(1, 1, 1, 0.8))
