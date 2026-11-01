class_name CrossingGuard
extends Character
## The school crossing guard at the school's crosswalk: a neon-yellow coat and cap. When a child crosses she walks
## out to the middle of the road and holds her red stop paddle out until they're across, then goes back to her curb.

var _paddle: _Paddle
var _holding := false


func _init() -> void:
	var guard := CharacterLook.new()
	guard.age = "adult"
	guard.skin = Color("#E8B892")
	guard.hair_style = "ponytail"
	guard.hair_color = Color("#5A3A22")
	guard.lashes = true
	guard.mouth = "smile"
	guard.outfit = "coat"
	guard.outfit_color = Color("#D9F23A")
	guard.accent_color = Color("#F4F4F4")
	guard.pattern = "none"
	guard.sleeve = "long"
	guard.legwear = "pants"
	guard.legwear_color = Color("#2F3E5C")
	guard.shoes = "boot"
	guard.shoe_color = Color("#2B2B2B")
	guard.hat = "cap"
	guard.hat_color = Color("#D9F23A")
	look = guard


func _ready() -> void:
	super()
	_paddle = _Paddle.new()
	_paddle.guard = self
	add_child(_paddle)


## Walks out to `to_x`, holds the paddle out for `seconds`, then walks back where she was.
func escort(to_x: float, seconds: float) -> void:
	var home := position.x
	var tween := create_tween()
	tween.tween_callback(_walk.bind(to_x))
	tween.tween_property(self, "position:x", to_x, absf(to_x - home) / walk_speed)
	tween.tween_callback(func():
		is_walking = false
		facing = 1
		_holding = true
		pet(seconds, 0.0))
	tween.tween_interval(seconds)
	tween.tween_callback(func():
		_holding = false
		_walk(home))
	tween.tween_property(self, "position:x", home, absf(to_x - home) / walk_speed)
	tween.tween_callback(func(): is_walking = false)


func _walk(to_x: float) -> void:
	is_walking = true
	facing = 1 if to_x > position.x else -1


# The red octagonal "ARRÊT" paddle on its pole, in her hand while she holds the traffic.
class _Paddle:
	extends Node2D
	var guard: CrossingGuard

	func _process(_delta: float) -> void:
		visible = guard._holding
		if visible:
			position = guard.to_local(guard.hand_position())
		queue_redraw()

	func _draw() -> void:
		draw_line(Vector2.ZERO, Vector2(0, -150), Color("#C9CED6"), 8.0)
		var c := Vector2(0, -200)
		var oct := PackedVector2Array()
		for i in 8:
			oct.append(c + Vector2.from_angle(TAU * (i + 0.5) / 8.0) * 58.0)
		draw_colored_polygon(oct, Color.WHITE)
		var inner := PackedVector2Array()
		for p in oct:
			inner.append(c + (p - c) * 0.86)
		draw_colored_polygon(inner, Color("#C8202A"))
		draw_string(ThemeDB.fallback_font, c + Vector2(-50, 9), "ARRÊT", HORIZONTAL_ALIGNMENT_CENTER, 100, 26, Color.WHITE)
