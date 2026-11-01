class_name WireBirds
extends Node2D
## Pigeons and sparrows perched along the thick cable between the utility poles (UtilityPoles' sagging cable). They
## bob their heads; when Charlotte comes close (or runs by) they take off, flapping away into the sky, and now and
## then a bird flies back in to land somewhere along the wire.

const SAG := 30.0
const FLEE := 130.0

var poles: Array[float] = []
var charlotte: Character
var seed_value := 1
var _birds: Array[Dictionary] = []
var _rng := RandomNumberGenerator.new()
var _t := 0.0
var _land_in := 12.0


func _ready() -> void:
	_rng.seed = seed_value
	for i in poles.size() - 1:
		for k in _rng.randi_range(0, 3):
			_birds.append(_perched(i, _rng.randf_range(0.2, 0.8)))


# A bird sitting on the cable between poles i and i+1, a fraction t of the way along.
func _perched(i: int, t: float) -> Dictionary:
	var a := Vector2(poles[i] + 9.0, UtilityPoles.CABLE_Y)
	var b := Vector2(poles[i + 1] + 9.0, UtilityPoles.CABLE_Y)
	var at := a.lerp(b, t) + Vector2(0, sin(t * PI) * SAG)
	return {"pos": at, "perch": at, "state": "perch", "vel": Vector2.ZERO, "phase": _rng.randf_range(0.0, TAU),
		"pigeon": _rng.randf() < 0.5, "facing": 1.0 if _rng.randf() < 0.5 else -1.0}


func _process(delta: float) -> void:
	_t += delta
	var near := charlotte != null
	for b in _birds:
		match b.state:
			"perch":
				if near:
					var dx := absf(charlotte.position.x - b.pos.x)
					if dx < FLEE or (charlotte.running and dx < FLEE * 2.0):
						b.state = "fly"
						b.vel = Vector2(_rng.randf_range(60.0, 140.0) * (1.0 if b.pos.x > charlotte.position.x else -1.0), _rng.randf_range(-160.0, -110.0))
						b.facing = signf(b.vel.x)
						Sfx.play("swoosh", b.pos, -14.0, 1.6)
			"fly":
				b.pos += b.vel * delta
				b.vel.y -= 20.0 * delta
			"land":
				b.pos = b.pos.move_toward(b.perch, 120.0 * delta)
				if b.pos.distance_to(b.perch) < 1.0:
					b.state = "perch"
	_birds = _birds.filter(func(b): return b.pos.y > -60.0)
	# Every so often one comes back and lands on the wire, out of Charlotte's way.
	_land_in -= delta
	if _land_in <= 0.0 and poles.size() > 1:
		_land_in = _rng.randf_range(10.0, 25.0)
		var b := _perched(_rng.randi_range(0, poles.size() - 2), _rng.randf_range(0.2, 0.8))
		if not near or absf(charlotte.position.x - b.perch.x) > FLEE * 2.0:
			b.state = "land"
			b.pos = b.perch + Vector2(-b.facing * 220.0, -180.0)
			_birds.append(b)
	queue_redraw()


func _draw() -> void:
	for b in _birds:
		var body := Color("#6E7480") if b.pigeon else Color("#8A6A4A")
		var p: Vector2 = b.pos
		var f: float = b.facing
		if b.state == "perch":
			var bob := sin(_t * 3.0 + b.phase)
			draw_set_transform(p, 0.0, Vector2(f, 1.0))
			draw_colored_polygon(PackedVector2Array([Vector2(-9, -4), Vector2(-15, -2), Vector2(-9, -1)]), body.darkened(0.3))
			draw_circle(Vector2(-2, -5), 6.0, body)
			draw_circle(Vector2(4, -10 + maxf(bob, 0.0) * 1.5), 3.6, body.lightened(0.1))
			draw_circle(Vector2(5.5, -10.5 + maxf(bob, 0.0) * 1.5), 0.9, Color("#1A1A1A"))
			draw_colored_polygon(PackedVector2Array([Vector2(7.5, -10), Vector2(10, -9), Vector2(7.5, -8.5)]), Color("#C9A24A"))
			if b.pigeon:
				draw_circle(Vector2(1, -7), 2.4, Color("#5E8A7A"))
			draw_line(Vector2(-1, 0), Vector2(-1, 2), Color("#C97A6A"), 1.0)
			draw_set_transform(Vector2.ZERO)
		else:
			# Flapping: wings up and down.
			var flap := sin(_t * 22.0 + b.phase) * 7.0
			draw_circle(p, 4.5, body)
			draw_line(p, p + Vector2(-9, -flap), body.darkened(0.2), 2.5)
			draw_line(p, p + Vector2(9, -flap), body.darkened(0.2), 2.5)
